/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays a worksheet.
Class %DeepSee.Component.Widget.worksheet Extends %DeepSee.Component.Widget.widget [ System = 4 ]
{

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon)
	Set pInfo = $LB(..%ClassName(0),$$$Text("Worksheet","%DeepSee"),..%ClassName(1),"deepsee/spreadsheet_48.gif")
	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List) As %Status
{
	Kill pInfo

	// available to all
	Set pInfo($I(pInfo)) = $LB("print",0,"%Boolean",$$$Text("Print","%DeepSee"),$$$Text("Enable printing for this widget","%DeepSee"))		// DTB236
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		// DTB565 - required by excel/PDF export
		Set ..sessionCookie = %session.CSPSessionCookie
		
		// json provider for data
		Set tProvider = ##class(%ZEN.Auxiliary.jsonProvider).%New()
		Set tProvider.id = ..%MakeWidgetId("json")
		Set tProvider.composite = $this
		Set tProvider.OnGetTargetObject = "GetWorksheetContent"

		Set tParm = ##class(%ZEN.Auxiliary.parameter).%New()
		Set tParm.value = ..dataSource
		Do tProvider.parameters.SetAt(tParm,"worksheet")
		Do %page.%AddComponent(tParm)

		Set tSC = pGroup.%AddChild(tProvider)
		If $$$ISERR(tSC) Quit

		// add dataGrid to the widget
		Set tGrid = ##class(%ZEN.Component.dataGrid).%New()
		Set tGrid.id = ..%MakeWidgetId("grid")
		Set tGrid.columnWidth = 150
		Set tGrid.showRowLabels = 1
		Set tGrid.multiSelect = 1
		Set tGrid.readOnly = 1
		Set tGrid.selectMode = "cells" 
		Set tGrid.ongetcontroller = "return zenPage.getComponent("_..index_");"
		Set tGrid.ondrawcell = "return zenPage.getComponent("_..index_").getCellOverride(row,col);"

		Set tSC = pGroup.%AddChild(tGrid)
		If $$$ISERR(tSC) Quit
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback is called just before controls are added to the top of the widget.
/// <var>pGroup</var> is the header in which new Zen control can be added.
Method %OnCreateControls(pGroup As %ZEN.Component.group) As %Status
{
	// get default values for widget properties
	Do ..%GetWidgetPropertyInfo(..subtype,.tList)
	Set n = $O(tList(""))
	While (n'="") {
		Set tName = $LG(tList(n),1)
		Set tPValue(tName) = ..%definition.properties.GetAt(tName)
		Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
		Set n = $O(tList(n))
	}

	// pdf export
	If (+$G(tPValue("print"))) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.src = "deepsee/ds2_printer_22.png"
		Set tButton.title = $$$Text("Create PDF from this pivot","%DeepSee")
		If (..previewMode) {
			Set tButton.disabled = 1
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").exportPDF();"
		}
		Do pGroup.%AddChild(tButton)
	}
	
	Quit $$$OK
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var grid = this.findComponent('grid');
	if (grid) {
		grid.setSize(width - 10,height);
		if (load) {
			this.applyModelToGrid();
		}
	}
}

/// Apply the given filter to this widget.
ClientMethod applyFilter(name, value) [ Language = javascript ]
{
}

/// Export to pdf.
ClientMethod exportPDF() [ Language = javascript ]
{
	if ('' != this.dataSource) {
		var url = '_DeepSee.UI.WorksheetPDF.zen?WORKSHEET=' + encodeURIComponent(this.dataSource);
		window.open(url,"_blank");
	}
}

/// Get content object for JSON provider.
ClassMethod GetWorksheetContent(ByRef pParameters, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tWorksheetName = $G(pParameters("worksheet"))
		If (tWorksheetName="") Quit

		// remove extension
		Set tWorksheetName = $P(tWorksheetName,".",1)

		Set tSC = ##class(%DeepSee.WorksheetEngine).%LoadWorksheet(tWorksheetName,0,.pObject)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of row descriptors (or null).
ClientMethod getRowDescriptors() [ Language = javascript ]
{
	var model = this.getModel();
	if (model && model.rowHeaders) {
		return model.rowHeaders;
	}
	return null;
}

/// Return an array of column descriptors (or null).
ClientMethod getColumnDescriptors() [ Language = javascript ]
{
	var model = this.getModel();
	if (model && model.columnHeaders) {
		return model.columnHeaders;
	}
	return null;
}

/// Controller API
ClientMethod getDimSize(dim) [ Language = javascript ]
{
	var model = this.getModel();
	if (model) {
		switch (dim) {
		case 1:
			// rows
			return (model.rowHeaders && model.rowHeaders.length) ? model.rowHeaders.length : 1;
		case 2:
			// columns
			return (model.columnHeaders && model.columnHeaders.length) ? model.columnHeaders.length : 1;
		}
	}
	return '';
}

/// dataSet API
/// Get the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod getLabel(n, dim) [ Language = javascript ]
{
	var model = this.getModel();

	switch (dim) {
	case 1:
		if (model && model.rowHeaders) {
			return model.rowHeaders[n].name;
		}
		break;
	case 2:	
		if (model && model.columnHeaders) {
			return model.columnHeaders[n].name;
		}
		break;
	}
	return '';
}

/// dataSet API
/// Return the data contained in the specified location.
/// Location is 0-based;
ClientMethod getData(d1, d2, d3) [ Language = javascript ]
{
	var value = '';
	var model = this.getModel();

	if (model && model.values) {
		value = model.values[d1] ? model.values[d1][d2] : '';
	}
	return value;
}

/// dataBag API
/// Get a data value, by property name, from this dataController.
ClientMethod getDataByName(prop, series) [ Language = javascript ]
{
	var value = '';
	var model = this.getModel();

	if (model && model.values) {
		// find col # for prop
		var cols = model.values[series].length;
		var col = -1;
		for (var n = 0; n < cols; n++) {
			if (model.columnHeaders[n].name == prop) {
				col = n;
				break;
			}
		}
		if (col>=0) {
			value = model.values[series][col];
		}
	}
	return value;
}

/// Given a 0-based index, return the corresponding property name.
ClientMethod getPropertyName(n) [ Language = javascript ]
{
	var model = this.getModel();
	if (model && model.columnHeaders && model.columnHeaders[n]) {
		return model.columnHeaders[n].name;
	}
	return '';
}

/// Notification from the dataGrid.
ClientMethod notifyController(source, reason, prop, value, row) [ Language = javascript ]
{
	var model = this.getModel();

	if (model && model.values) {
		// find col # for prop
		var cols = model.values[row].length;
		var col = -1;
		for (var n = 0; n < cols; n++) {
			if (model.columnHeaders[n].name == prop) {
				col = n;
				break;
			}
		}
		if (col>=0) {
			if (model.values[row][col] != value) {
				this.setModified(true);
			}
			model.values[row][col] = value;
			this.selectCell(row+1,col+1);
		}
	}
	return value;
}

/// Get the json-supplied data model.
ClientMethod getModel() [ Language = javascript ]
{
	return zen(this.id+'/json').getContentObject();
}

/// Get the grid control.
ClientMethod getGrid() [ Language = javascript ]
{
	return zen(this.id+'/grid');
}

/// Apply saved attributes to the grid component.
ClientMethod applyModelToGrid() [ Language = javascript ]
{
	var model = this.getModel();
	var grid = this.getGrid();
	if (model) {
		grid.style = zenGet(model.style);
		grid.format = zenGet(model.format);
		grid.selectMode = zenGet(model.selectMode);

		grid.columnWidth = zenGet(model.columnWidth,150);
		grid.columnHeaderStyle = zenGet(model.columnHeaderStyle);
		grid.rowHeaderStyle = zenGet(model.rowHeaderStyle);
		grid.showZebra = zenGet(model.showZebra) ? true : false;

		grid.evenRowBackground = zenGet(model.evenRowBackground,'#F8F8F8');
		grid.evenRowColor = zenGet(model.evenRowColor);
		grid.oddRowBackground = zenGet(model.oddRowBackground);
		grid.oddRowColor = zenGet(model.oddRowColor);
		grid.currCellBackground = zenGet(model.currCellBackground,'#D0D0FF');
		grid.currCellColor = zenGet(model.currCellColor,'black');
		grid.render();
	}
}

/// Apply the current filters to this widget.
ClientMethod applyFilters(refresh) [ Internal, Language = javascript ]
{
	// reload json and update grid
	var json = zen(this.id+'/json');
	if (json) {
		json.reloadContents();
	}
	this.getGrid().render();
	this.onApplyFilters(refresh);
}

/// Get cell override.
ClientMethod getCellOverride(row, col) [ Language = javascript ]
{
	var info = null;
	// test for cell overrides
	var model = this.getModel();
	if (model && model.cells && model.cells.length) {
		for (var n = 0; n < model.cells.length; n++) {
			var cell = model.cells[n];
			if (cell && cell.row==row && cell.column == col) {
				info = {};
				if (cell.format) {
					info.format = cell.format;
				}
				if (cell.style) {
					info.style = cell.style;
				}
				break;
			}
		}
	}
	return info;
}

}
