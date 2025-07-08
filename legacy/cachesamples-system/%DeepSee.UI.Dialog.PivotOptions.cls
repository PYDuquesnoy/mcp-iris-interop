/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user change the properties of a DeepSee pivot table.
Class %DeepSee.UI.Dialog.PivotOptions Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 1;

Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property listing As %ZEN.Datatype.string(ZENURL = "LISTING");

Property listingRows As %ZEN.Datatype.integer(ZENURL = "LISTINGROWS");

Property rowTotals As %ZEN.Datatype.boolean(ZENURL = "ROWTOTALS");

Property columnTotals As %ZEN.Datatype.boolean(ZENURL = "COLUMNTOTALS");

Property rowTotalAgg As %ZEN.Datatype.string(ZENURL = "ROWTOTALAGG");

Property columnTotalAgg As %ZEN.Datatype.string(ZENURL = "COLUMNTOTALAGG");

Property rowTotalSource As %ZEN.Datatype.string(ZENURL = "ROWTOTALSOURCE");

Property rowLabelSpan As %ZEN.Datatype.boolean(ZENURL = "ROWSPAN");

Property columnLabelSpan As %ZEN.Datatype.boolean(ZENURL = "COLUMNSPAN");

Property showEmptyRows As %ZEN.Datatype.boolean(ZENURL = "ROWEMPTY");

Property showEmptyColumns As %ZEN.Datatype.boolean(ZENURL = "COLUMNEMPTY");

Property rowHeaderStyle As %ZEN.Datatype.string(ZENURL = "ROWSTYLE");

Property columnHeaderStyle As %ZEN.Datatype.string(ZENURL = "COLUMNSTYLE");

Property dataCellStyle As %ZEN.Datatype.string(ZENURL = "CELLSTYLE");

Property cellWidth As %ZEN.Datatype.string(ZENURL = "CELLWIDTH");

Property cellHeight As %ZEN.Datatype.string(ZENURL = "CELLHEIGHT");

Property showZebra As %ZEN.Datatype.boolean(ZENURL = "ZEBRA");

Property showRowCaption As %ZEN.Datatype.boolean(ZENURL = "ROWCAPTION");

Property sqlRestriction As %ZEN.Datatype.string(ZENURL = "SQLRESTRICT");

XData Style
{
<style type="text/css">

#body {
	visibility: hidden;
}

.zenLabel {
	color: #404040;
	font-size: 11px;
}

select {
	color: #404040;
	font-size: 11px;
}

.checkboxCaption {
	color: #404040;
	font-size: 11px;
}

#preview {
	overflow: auto;
	box-shadow: 2px 2px 2px #808080;
}

table.previewTable {
	border: 1px solid #404040;
	font-family: arial;
	font-size: 8pt;
	color: #404040;
	background: #808080;
}

table.previewTable td.nub {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	text-align: left;
	vertical-align: middle;
	background: #C0C0C0;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

table.previewTable td.columnHeader {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	text-align: left;
	vertical-align: middle;
	background: #C0C0C0;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

table.previewTable td.rowHeader {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	text-align: left;
	vertical-align: middle;
	background: #C0C0C0;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

table.previewTable td.cell {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	background: white;
	text-align: right;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	vertical-align: middle;
}

table.previewTable td.cellTotal {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	background: #F0F0F0;
	text-align: right;
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	vertical-align: middle;
}

/* zebra styles */
table.previewTable td.nubZebra {
	text-align: left;
	vertical-align: middle;
	background: #F0F0F4;
}

table.previewTable td.columnHeaderZebra {
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	text-align: right;
	vertical-align: middle;
	background: #F0F0F4;
}

table.previewTable td.rowHeaderOdd {
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	text-align: left;
	vertical-align: middle;
	background: white;
}

table.previewTable td.rowHeaderEven {
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	text-align: left;
	vertical-align: middle;
	background: #F0F0F4;
}

table.previewTable td.cellEven {
	background: #F0F0F4;
	text-align: right;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	vertical-align: middle;
}

table.previewTable td.cellOdd {
	background: white;
	text-align: right;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	vertical-align: middle;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">
<hgroup cellVAlign="top" labelPosition="top" label="Preview">
<html id="preview"/>
<spacer width="10"/>
<vgroup labelPosition="top">
<hgroup cellVAlign="top" labelPosition="top">
<checkbox id="showZebra" label="Zebra Striping" onchange="zenPage.updatePreview();" title="Show zebra striping in the pivot table"/>
<spacer width="40"/>
<checkbox id="showRowCaption" label="Row Caption" onchange="zenPage.updatePreview();" title="Show caption above row labels"/>
</hgroup>
<hgroup cellVAlign="top" labelPosition="top">
<select id="listing" label="Listing" title="Select which listing to use when showing a detail listing"/>
<spacer width="20"/>
<select id="listingRows" label="Maximum Listing Rows" hint="Limit is 1000 for external tables" title="Maximum number of rows to display for a detail listing" valueList="100,500,1000,5000,10000,20000"/>
</hgroup>
</vgroup>
</hgroup>

<hgroup cellVAlign="top">
<vgroup cellStyle="padding:2px;">
<label label="Row Options"/>
<deepsee:styleEdit id="rowStyle" onchange="zenPage.updatePreview();"/>

<hgroup cellVAlign="top" label="Summary">
<checkbox id="rowTotals" onchange="zenPage.updatePreview();"/>
<select id="rowTotalAgg" showEmpty="false" valueList="sum,count,min,max,avg,pct" displayList="Sum,Count,Min,Max,Average,% of Total" onchange="zenPage.rowAggChange();"/>
<spacer width="20"/>
<select id="rowTotalSource" showEmpty="false" valueList="page,all" displayList="Current Page, All Rows" onchange="zenPage.updatePreview();"/>
</hgroup>

<hgroup cellVAlign="top">
<checkbox id="rowEmpty" caption="Show Empty" onchange="zenPage.updatePreview();"/>
<spacer width="10"/>
<checkbox id="rowSpan" caption="Span Labels" onchange="zenPage.updatePreview();"/>
</hgroup>

</vgroup>
<spacer width="20"/>
<vgroup cellStyle="padding:2px;">
<label label="Column Options"/>
<deepsee:styleEdit id="colStyle" onchange="zenPage.updatePreview();"/>

<hgroup cellVAlign="top" label="Summary">
<checkbox id="colTotals" onchange="zenPage.updatePreview();"/>
<select id="colTotalAgg" showEmpty="false" valueList="sum,count,min,max,avg,pct" displayList="Sum,Count,Min,Max,Average,% of Total" onchange="zenPage.colAggChange();"/>
</hgroup>
<hgroup cellVAlign="top">
<checkbox id="colEmpty" caption="Show Empty" onchange="zenPage.updatePreview();"/>
<spacer width="10"/>
<checkbox id="colSpan" caption="Span Labels" onchange="zenPage.updatePreview();"/>
</hgroup>
</vgroup>
</hgroup>
<vgroup cellStyle="padding:2px;">
<label label="Cell Options"/>
<deepsee:styleEdit id="cellStyle" onchange="zenPage.updatePreview();"/>

<hgroup cellVAlign="top" label="Cell size (px)">
<text id="cellWidth" size="3" label="Width" onchange="zenPage.updatePreview();" onkeypress="zenPage.keyPress();"/>
<spacer width="10"/>
<text id="cellHeight" size="3" label="Height" onchange="zenPage.updatePreview();" onkeypress="zenPage.keyPress();"/>
</hgroup>
</vgroup>
<vgroup id="sqlRestrictGroup" cellStyle="padding:2px;" hidden="true">
<label id="sqlRestrictLabel" label="SQL Restriction" />
<textarea id="sqlRestriction" cols="80"/>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Pivot Options")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Change options for a Pivot Table.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();
		var pivot = main.zenPage.getPivot();
		pivot.rowHeaderStyle = this.rowHeaderStyle;
		pivot.columnHeaderStyle = this.columnHeaderStyle;
		pivot.cellStyle = this.dataCellStyle;

		pivot.showEmptyRows = zen('rowEmpty').getValue();
		pivot.showEmptyColumns = zen('colEmpty').getValue();
		pivot.rowLabelSpan = zen('rowSpan').getValue();
		pivot.columnLabelSpan = zen('colSpan').getValue();
		pivot.rowTotals = zen('rowTotals').getValue();
		pivot.columnTotals = zen('colTotals').getValue();
		pivot.rowTotalAgg = zen('rowTotalAgg').getValue();
		pivot.columnTotalAgg = zen('colTotalAgg').getValue();
		pivot.rowTotalSource = zen('rowTotalSource').getValue();
		pivot.cellWidth = zen('cellWidth').getValue();
		pivot.cellHeight = zen('cellHeight').getValue();
		pivot.listing = zen('listing').getValue();
		pivot.listingRows = zen('listingRows').getValue();
		pivot.showZebra = zen('showZebra').getValue();
		pivot.showRowCaption = zen('showRowCaption').getValue();
		pivot.sqlRestriction = zen('sqlRestriction').getValue();		// DTB723
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	// apply values
	zen('rowSpan').setValue(this.rowLabelSpan);
	zen('rowEmpty').setValue(this.showEmptyRows);
	zen('rowTotals').setValue(this.rowTotals);
	zen('showZebra').setValue(this.showZebra);
	zen('showRowCaption').setValue(this.showRowCaption);
	zen('rowTotalSource').setValue(this.rowTotalSource);
	zen('rowTotalAgg').setValue(this.rowTotalAgg);

	zen('colSpan').setValue(this.columnLabelSpan);
	zen('colEmpty').setValue(this.showEmptyColumns);
	zen('colTotals').setValue(this.columnTotals);
	zen('colTotalAgg').setValue(this.columnTotalAgg);

	zen('cellWidth').setValue(this.cellWidth);
	zen('cellHeight').setValue(this.cellHeight);

	zen('rowStyle').setValue(this.rowHeaderStyle);
	zen('colStyle').setValue(this.columnHeaderStyle);
	zen('cellStyle').setValue(this.dataCellStyle);
	
	zen('sqlRestriction').setValue(this.sqlRestriction);		// DTB723

	this.updatePreview();

	// make dialog appear
	zen('body').getEnclosingDiv().style.visibility = 'visible';

	try {
		zen('listingRows').focus();
		zen('listingRows').select();
	}
	catch(ex) {
	}
}

/// Reset styles for this pivot.
ClientMethod clearStyles() [ Language = javascript ]
{
	zen('rowSpan').setValue(true);
	zen('rowEmpty').setValue(false);
	zen('rowTotals').setValue(false);
	zen('showZebra').setValue(false);
	zen('showRowCaption').setValue(true);

	zen('colSpan').setValue(true);
	zen('colEmpty').setValue(false);
	zen('colTotals').setValue(false);

	zen('cellWidth').setValue(120);
	zen('cellHeight').setValue(22);

	zen('rowStyle').setValue('');
	zen('colStyle').setValue('');
	zen('cellStyle').setValue('');

	this.updatePreview();
}

ClientMethod keyPress() [ Language = javascript ]
{
/// Key press handler (ie workaround).
	/*
	if (event && event.keyCode == zenENTER) {
		this.updatePreview();
	}
	*/
}

/// Change to row agg.
ClientMethod rowAggChange() [ Language = javascript ]
{
	zen('rowTotals').setValue(true);
	this.updatePreview();
}

/// Change to col agg.
ClientMethod colAggChange() [ Language = javascript ]
{
	zen('colTotals').setValue(true);
	this.updatePreview();
}

/// Draw contents of preview component.
ClientMethod updatePreview() [ Language = javascript ]
{
	var html = new Array();

	var nubRows = 2;
	var nubCols = 2;
	var colLabelSpan = zen('colSpan').getValue();
	var rowLabelSpan = zen('rowSpan').getValue();
	var colEmpty = zen('colEmpty').getValue();
	var rowEmpty = zen('rowEmpty').getValue();
	var rowTotals2 = zen('rowTotals').getValue();
	var colTotals2 = zen('colTotals').getValue();
	var rowTotalAgg = zen('rowTotalAgg').getValue();
	var colTotalAgg = zen('colTotalAgg').getValue();
	var rowTotalSource = zen('rowTotalSource').getValue();
	var showZebra = zen('showZebra').getValue();
	var showRowCaption = zen('showRowCaption').getValue();
	var cellWidth = zen('cellWidth').getValue();
	cellWidth = parseInt(cellWidth,10);
	cellWidth = (isNaN(cellWidth)||cellWidth<=0) ? 120 : cellWidth;

	var cellHeight = zen('cellHeight').getValue();
	cellHeight = parseInt(cellHeight,10);
	cellHeight = (isNaN(cellHeight)||cellHeight<=0) ? 20 : cellHeight;

	this.rowHeaderStyle = zen('rowStyle').getValue();
	this.columnHeaderStyle = zen('colStyle').getValue();

	this.dataCellStyle = zen('cellStyle').getValue();
	var colHeaderStyle = this.columnHeaderStyle;

	var cellStyle = this.dataCellStyle;

	var val = [1234.56,1234.56,1234.56,1234.56];
	var year = 2010;
	var month1 = $$$Text("January");
	var month2 = $$$Text("February");
	var month3 = $$$Text("March");

	var colSpan = colEmpty ? 3 : 2;
	var rowSpan = rowEmpty ? 3 : 2;

	var nubClass = showZebra ? 'nubZebra' : 'nub';
	var colHeaderClass = showZebra ? 'columnHeaderZebra' : 'columnHeader';
	var rowHeaderClassEven = showZebra ? 'rowHeaderEven' : 'rowHeader';
	var rowHeaderClassOdd = showZebra ? 'rowHeaderOdd' : 'rowHeader';
	var cellClassEven = showZebra ? 'cellEven' : 'cell';
	var cellClassOdd = showZebra ? 'cellOdd' : 'cell';
	var cellTotalEven = showZebra ? 'cellEven' : 'cellTotal';
	var cellTotalOdd = showZebra ? 'cellOdd' : 'cellTotal';
	
	var zwhite = showZebra ? 'background:white;' : '';

	cellStyle = cellStyle + 'width:'+cellWidth+'px;'+'height:'+cellHeight+'px;';

	html[html.length] = '<table class="previewTable" border="0" cellspacing="0">';

	// column headers
	html[html.length] = '<tr>';

	// nub
	var rowCaption = showRowCaption ? $$$Text('Country') : '&nbsp;';
	html[html.length] = '<td class="'+nubClass+'" style="'+colHeaderStyle+'" rowspan="'+nubRows+'" colspan="'+nubCols+'"><br/>'+rowCaption+'</td>';

	if (!colLabelSpan) {
		html[html.length] = '<td class="'+colHeaderClass+'" style="'+colHeaderStyle+'">'+year+'</td>';
		html[html.length] = '<td class="'+colHeaderClass+'" style="'+colHeaderStyle+'" >'+year+'</td>';
		if (colEmpty) {
			html[html.length] = '<td class="'+colHeaderClass+'" style="'+colHeaderStyle+'" >'+year+'</td>';
		}
	}
	else {
		html[html.length] = '<td class="'+colHeaderClass+'" style="'+colHeaderStyle+'" colspan="'+colSpan+'">'+year+'</td>';
	}
	if (colTotals2) {
		var colTotalLabel = $$$Text('Total');
		switch(colTotalAgg) {
		case 'avg':
			var colTotalLabel = $$$Text('Average');
			break;
		case 'count':
			var colTotalLabel = $$$Text('Count');
			break;
		case 'min':
			var colTotalLabel = $$$Text('Min');
			break;
		case 'max':
			var colTotalLabel = $$$Text('Max');
			break;
		case 'pct':
			var colTotalLabel = $$$Text('% of Total');
			break;
		}
		html[html.length] = '<td rowspan="2" class="'+colHeaderClass+'" style="'+colHeaderStyle+'">'+colTotalLabel+'</td>';
	}

	html[html.length] = '</tr>';

	html[html.length] = '<tr>';
	html[html.length] = '<td class="'+colHeaderClass+'" style="'+colHeaderStyle+'">'+month1+'</td>';
	html[html.length] = '<td class="'+colHeaderClass+'" style="'+colHeaderStyle+'">'+month2+'</td>';
	if (colEmpty) {
		html[html.length] = '<td class="'+colHeaderClass+'" style="'+colHeaderStyle+'">'+month3+'</td>';
	}
	html[html.length] = '</tr>';

	// rows and cells
	html[html.length] = '<tr>';
	if (!rowLabelSpan) {
		html[html.length] = '<td class="'+rowHeaderClassOdd+'" nowrap="1" style="'+this.rowHeaderStyle+zwhite+'">'+'USA'+'</td>';
	}
	else {
		html[html.length] = '<td rowspan="'+rowSpan+'" class="'+rowHeaderClassOdd+'" nowrap="1" style="'+this.rowHeaderStyle+zwhite+'">'+'USA'+'</td>';
	}
	html[html.length] = '<td class="'+rowHeaderClassOdd+'" nowrap="1" style="'+this.rowHeaderStyle+zwhite+'">'+'Boston'+'</td>';

	html[html.length] = '<td class="'+cellClassOdd+'" style="'+cellStyle+zwhite+'">'+val[0]+'</td>';
	html[html.length] = '<td class="'+cellClassOdd+'" style="'+cellStyle+zwhite+'">'+val[1]+'</td>';
	if (colEmpty) {
		html[html.length] = '<td class="'+cellClassOdd+'" style="'+cellStyle+zwhite+'">'+'&nbsp;'+'</td>';
	}
	if (colTotals2) {
		html[html.length] = '<td class="'+cellTotalOdd+'" style="'+cellStyle+zwhite+'">'+(val[0]+val[1])+'</td>';
	}
	html[html.length] = '</tr>';

	html[html.length] = '<tr>';
	if (!rowLabelSpan) {
		html[html.length] = '<td class="'+rowHeaderClassEven+'" nowrap="1" style="'+this.rowHeaderStyle+'">'+'USA'+'</td>';
	}
	html[html.length] = '<td class="'+rowHeaderClassEven+'" nowrap="1" style="'+this.rowHeaderStyle+'">'+'New York'+'</td>';

	html[html.length] = '<td class="'+cellClassEven+'" style="'+cellStyle+'">'+val[2]+'</td>';
	html[html.length] = '<td class="'+cellClassEven+'" style="'+cellStyle+'">'+val[3]+'</td>';
	if (colEmpty) {
		html[html.length] = '<td class="'+cellClassEven+'" style="'+cellStyle+'">'+'&nbsp;'+'</td>';
	}
	if (colTotals2) {
		html[html.length] = '<td class="'+cellTotalEven+'" style="'+cellStyle+'">'+(val[2]+val[3])+'</td>';
	}
	html[html.length] = '</tr>';

	if (rowEmpty) {
		html[html.length] = '<tr>';
		if (!rowLabelSpan) {
			html[html.length] = '<td class="'+rowHeaderClassOdd+'" nowrap="1" style="'+this.rowHeaderStyle+zwhite+'">'+'USA'+'</td>';
		}
		html[html.length] = '<td class="'+rowHeaderClassOdd+'" nowrap="1" style="'+this.rowHeaderStyle+zwhite+'">'+'Sheridan'+'</td>';

		html[html.length] = '<td class="'+cellClassOdd+'" style="'+cellStyle+zwhite+'">'+'&nbsp;'+'</td>';
		html[html.length] = '<td class="'+cellClassOdd+'" style="'+cellStyle+zwhite+'">'+'&nbsp;'+'</td>';
		if (colEmpty) {
			html[html.length] = '<td class="'+cellClassOdd+'" style="'+cellStyle+zwhite+'">'+'&nbsp;'+'</td>';
		}
		if (colTotals2) {
			html[html.length] = '<td class="'+cellTotalOdd+'" style="'+cellStyle+zwhite+'">'+'&nbsp;'+'</td>';
		}
		html[html.length] = '</tr>';
	}

	if (rowTotals2) {
		var rowTotalLabel = $$$Text('Total');
		switch(rowTotalAgg) {
		case 'avg':
			var rowTotalLabel = $$$Text('Average');
			break;
		case 'count':
			var rowTotalLabel = $$$Text('Count');
			break;
		case 'min':
			var rowTotalLabel = $$$Text('Min');
			break;
		case 'max':
			var rowTotalLabel = $$$Text('Max');
			break;
		case 'pct':
			var rowTotalLabel = $$$Text('% of Total');
			break;
		case 'sum':
			if (rowTotalSource=='all') {
				var rowTotalLabel = $$$Text('Grand Total');
			}
			break;
		}

		html[html.length] = '<tr>';
		html[html.length] = '<td colspan="2" class="'+(!rowEmpty?rowHeaderClassOdd:rowHeaderClassEven)+'" nowrap="1" style="'+this.rowHeaderStyle+(!rowEmpty?zwhite:'')+'">'+rowTotalLabel+'</td>';
		html[html.length] = '<td class="'+(!rowEmpty?cellTotalOdd:cellTotalEven)+'" style="'+cellStyle+(!rowEmpty?zwhite:'')+'">'+(val[0]+val[2])+'</td>';
		html[html.length] = '<td class="'+(!rowEmpty?cellTotalOdd:cellTotalEven)+'" style="'+cellStyle+(!rowEmpty?zwhite:'')+'">'+(val[1]+val[3])+'</td>';
		if (colEmpty) {
			html[html.length] = '<td class="'+(!rowEmpty?cellTotalOdd:cellTotalEven)+'" style="'+cellStyle+(!rowEmpty?zwhite:'')+'">'+'&nbsp;'+'</td>';
		}
		if (colTotals2) {
			html[html.length] = '<td class="'+(!rowEmpty?cellTotalOdd:cellTotalEven)+'" style="'+cellStyle+(!rowEmpty?zwhite:'')+'">'+(val[0]+val[1]+val[2]+val[3])+'</td>';
		}
		html[html.length] = '</tr>';
	}

	html[html.length] = '</table>';

	zen('preview').setContent(html.join(''));
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(..cubeName,.tListings)
	If $$$ISERR(tSC) Quit tSC

	Set tValueList = ""
	Set tDisplayList = ""
	Set k = $O(tListings(""))
	// + WAL263 -- Escape commas with $Replace. Note taken from %ZEN.Component.listControl:
	//				If your data include commas, escape them with "\,"
	While (k'="") {
		Set tDisplayList = tDisplayList _ $S(tValueList="":"",1:",") _ $Replace($LG(tListings(k),1),",","\,")
		Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $Replace(k,",","\,")
		Set k = $O(tListings(k))
	}
	// - WAL263
	Set tSelect = ..%GetComponentById("listing")
	Set tSelect.valueList = tValueList
	Set tSelect.displayList = tDisplayList
	Set tSelect.value = ..listing

	Set tCtrl = ..%GetComponentById("listingRows")
	Set tCtrl.value = ..listingRows

	// add clear button to dialog buttons
	Set tGroup = ..%GetComponentById("buttonHolder")
	Set tApply = ..%GetComponentById("btnApply")
	If ($IsObject(tGroup)&&$IsObject(tApply)) {
		Set tButton = ##class(%ZEN.Component.button).%New()
		Set tButton.caption = $$$Text("Clear","%DeepSee")
		Set tButton.title = $$$Text("Reset styles","%DeepSee")
		Set tButton.controlClass="commandButton"
		Set tButton.onclick="zenPage.clearStyles();"
		Do tGroup.%AddChildBefore(tButton,tApply)

		Set tSpacer = ##class(%ZEN.Component.spacer).%New()
		Set tSpacer.width = 20
		Do tGroup.%AddChildBefore(tSpacer,tApply)
	}
	
	If $D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cubeName),"mbr#","-1")) {
		// DTB723 - Check for the cube's %SQLRESTRICT support. Show the SQL Restriction text area if the cube can use it in queries.
		Set ..%GetComponentById("sqlRestrictGroup").hidden = 0
		
		// +DTB728 - Set the tooltip to communicate basic instructions for using %SQLRESTRICT
		Set tSourceTable = ##class(%DeepSee.Utils).%GetSQLTableName(##class(%DeepSee.Utils).%GetSourceClass(..cubeName))
		Set ..%GetComponentById("sqlRestrictLabel").title = "Specify either:" _ $C(10) _
													"SQL SELECT query that returns one column of IDs that represent IDs of the source class." _ $C(10) _
													"SQL WHERE clause that will be added to query 'SELECT %ID from " _ tSourceTable _ "'." _ $C(10,10) _
													"The MDX result will be restricted to the facts built from the specified source IDs, then additional MDX filters will be applied."
		// -DTB728
	}

	Quit $$$OK
}

}
