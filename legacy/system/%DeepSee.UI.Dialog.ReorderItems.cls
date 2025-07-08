/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user reorder Dimensions or Measures.<br>
/// The cube's javascript DOM is passed in.
Class %DeepSee.UI.Dialog.ReorderItems Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBENAME");

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<vgroup labelPosition="left">
<label id="cubeName" label="Cube name:" enclosingClass="zenLabel"/>
</vgroup>
<radioSet id="radType" label="What would you like to reorder?" valueList="Measures,Dimensions" value="Dimensions" onchange="zenPage.changeType(zenThis.getValue());"/>

<hgroup cellStyle="padding:4px;" cellVAlign="top">
<vgroup>
<listBox id="lstDimension" label="Select a field from the list, and then click an arrow to move." listWidth="500px" listHeight="310px"
/>
<listBox id="lstMeasure" label="Select a field from the list, and then click an arrow to move." listWidth="500px" listHeight="310px" hidden="true"
/>
<button id="btnSort" caption="Alphabetize" title="Reorder alphabetically" disabled="true" onclick="zenPage.doSort();"/>
</vgroup>
<vgroup id="idGroupButtons">
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/up_24.png" title="Move the selected field up" onclick="zenPage.moveItem('up');"/>
<image src="deepsee/down_24.png" title="Move the selected field down" onclick="zenPage.moveItem('dn');"/>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Reorder Elements")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$FormatText($$$Text("for cube %1"),..EscapeHTML(%page.cubeName))
}

/// When we get here, we want to get the cube object from Architect as a native javaScript object
/// "opener" is a pointer to Architect
/// "opener.zenPage" is _Architect's_ DOM
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.dataCube = null;
	var opener = this.getOpener();
	if (opener) {
		var cube = opener.zenPage.fetchCube && opener.zenPage.fetchCube();
		if (!cube) return;
		this.dataCube = cube;
		/// Load existing dimensions and measures into list boxes
		var list = zen("lstDimension");
		var dim;
		var len = cube.dimensions.length;
		for (var d = 0; d < len; d++) {
			dim = cube.dimensions[d];
			list.appendOption(dim.name,dim.name);
		}
		if (len > 0) zen("btnSort").setDisabled(false);
		var list = zen("lstMeasure");
		var mea;
		for (var d = 0; d < cube.measures.length; d++) {
			mea = cube.measures[d];
			list.appendOption(mea.name,mea.name);
		}		
	} else {
		alert("PAGE NOT LAUNCHED AS A CHILD WINDOW, UNABLE TO ACCESS CUBE DATA");
	}
}

/// User changed type to reorder. Show/hide associated list box.
ClientMethod changeType(type) [ Language = javascript ]
{
	zen("lstDimension").setHidden(type=="Measures");
	zen("lstMeasure").setHidden(type=="Dimensions");
}

/// Return updated dataCube object to Architect.
ClientMethod getDialogValue() [ Language = javascript ]
{
	try {
		if (!this.dataCube) return null;
		return this.dataCube;
		}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return '';
}

/// User clicked the Move Up/Down image. Move the field up or down one level in the List box. <br>
/// Switch data in dataCube as well. dir = "up" or "dn".
ClientMethod moveItem(dir) [ Language = javascript ]
{
	var type = zen('radType').getValue();
	var fieldObj = (type == "Dimensions") ? zen('lstDimension') : zen('lstMeasure');
	var len = fieldObj.getOptionCount();
	if (len == 0) return;
	var idx = fieldObj.getProperty("selectedIndex");
	if (idx < 0) {
		alert($$$Text("Please select the field you want to move and try again."));
		return;
	}
	var cube = this.dataCube;
	var row = idx;
	if (dir == "up") {
		row--;
		if (row >= 0) {
			switch(type) {
				case 'Dimensions':
				var id = idx-1;
					if (cube.dimensions[idx-1]) {
						last = cube.dimensions[idx-1];
						cube.dimensions[idx-1] = cube.dimensions[idx];
						cube.dimensions[idx] = last;
					}
					break;
				case 'Measures':
					if (cube.measures[idx-1]) {
						last = cube.measures[idx-1];
						cube.measures[idx-1] = cube.measures[idx];
						cube.measures[idx] = last;
					}
					break;
			}
		}
	} else {
		row++;
		if (row > 0) {
			switch(type) {
				case 'Dimensions':
					if (cube.dimensions[idx+1]) {
						last = cube.dimensions[idx+1];
						cube.dimensions[idx+1] = cube.dimensions[idx];
						cube.dimensions[idx] = last;
					}
					break;
				case 'Measures':
					if (cube.measures[idx+1]) {
						last = cube.measures[idx+1];
						cube.measures[idx+1] = cube.measures[idx];
						cube.measures[idx] = last;
					}
					break;
			}
		}
	}
	if (row >= 0) fieldObj.moveOption(idx,row);
}

/// Sort list box alphabetically.
ClientMethod doSort(dir) [ Language = javascript ]
{
	if (!this.dataCube) return;	
	var cube = this.dataCube;
	var type = zen('radType').getValue();
	var list = (type == "Dimensions") ? zen('lstDimension') : zen('lstMeasure');
	/// clear old list box
	list.resetOptions();
	var sortarr = new Array();
	var sortname = new Array();
	if (type == "Dimensions") {
		for (var d = 0; d < cube.dimensions.length; d++) {
			sortname[d] = cube.dimensions[d].name;
			sortarr[d] = cube.dimensions[d];
		}		
		sortname.sort();
		for (var d = 0; d < sortname.length; d++) {
			/// set new order into list box
			name = sortname[d];
			list.appendOption(name,name);
			/// find old object by name
			for (var n = 0; n < sortarr.length; n++) {
				if (sortarr[n].name == name) break;	
			}
			/// set cube.dimensions with new order
			cube.dimensions[d] = sortarr[n];
		}
	} else {
		for (var d = 0; d < cube.measures.length; d++) {
			sortname[d] = cube.measures[d].name;
			sortarr[d] = cube.measures[d];
		}		
		sortname.sort();
		for (var d = 0; d < sortname.length; d++) {
			/// set new order into list box
			name = sortname[d];
			list.appendOption(name,name);
			/// find old object by name
			for (var n = 0; n < sortarr.length; n++) {
				if (sortarr[n].name == name) break;	
			}
			/// set cube.measures with new order 
			cube.measures[d] = sortarr[n];
		}
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
