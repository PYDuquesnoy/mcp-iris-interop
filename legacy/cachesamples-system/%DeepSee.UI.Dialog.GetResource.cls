/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets user select a resource.<br/>
/// If an existing resource is passed in it is set to be selected from the table.<br/>
/// 
Class %DeepSee.UI.Dialog.GetResource Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter CSSINCLUDES = "/csp/sys/intersystems.css";

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property ELEMENT As %ZEN.Datatype.string(ZENURL = "ELEMENT");

Property CurrentResource As %ZEN.Datatype.string(ZENURL = "VALUE");

Property WHAT As %ZEN.Datatype.string(ZENURL = "WHAT");

Property numRows As %ZEN.Datatype.integer [ InitialExpression = "0" ];

XData Style
{
<style type="text/css">
table.DetailTable th {
	padding:2px;
} 
table.DetailTable td {
	padding:2px;
} 
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<vgroup labelPosition="left" valign="bottom">
<label id="cubeName" label="Cube name:" enclosingClass="zenLabel"/>
<label id="ELEMENT" label="Element name:" enclosingClass="zenLabel"/>
</vgroup>

<label id="titleText" label="Select a Resource from the table below." enclosingStyle="padding:2px;"/>

<html id="table" OnDrawContent="DrawTable" seed="#(%page.CurrentResource)#"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set value = $$$TextHTML("Unknown")
	If ..WHAT = "CubeResource" Set value = $$$TextHTML("Cube Resource")
	Else  If ..WHAT [ "ListingResource" Set value = $$$TextHTML("Listing Resource")
	Else  If ..WHAT [ "SubResource" Set value = $$$TextHTML("Subject Area Resource")
	Else  If ..WHAT [ "KPIResource" Set value = $$$TextHTML("KPI Resource")
	Quit value
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Set value = $$$TextHTML("Select Resource for Architect.")
	If ..WHAT [ "KPIResource" Set value = $$$TextHTML("Select Resource for KPI Wizard.")
	Quit value
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var cbValues = this.getCBValues();
	return encodeURIComponent(cbValues);
}

/// Currently this only returns one selection (radio button)
ClientMethod getCBValues() [ Language = javascript ]
{
	var state = '';
	var cb;
	var numRows = this.numRows;

	for (var i = 1; i <= numRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		if (cb && cb.checked && !cb.disabled) {
			//if (state.length > 0) state += ",";
			state += cb.value;
			break;
		}
	}
	
	return state;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
		Set ..%GetComponentById("ELEMENT").value = ..ELEMENT
		If ..WHAT [ "KPIResource" {
			Set ..%GetComponentById("cubeName").hidden = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Start action and server method will pump out result.
Method DrawTable(seed As %String) As %Status
{
	For n = 1:1:$L(seed,",") Set curr = $P(seed,",",n) If curr '= "" Set Current(curr) = 1
	Set ltoggle = $$$TextJS("Click this checkbox to select/unselect all")
	&html<<form name="form">>
	&html<<table class="DetailTable" border="0" cellpadding="5" cellspacing="2">
	<tr>
	>
	//Resources(Name)=$lb(Description,PublicPermissions,Type,ResourceType)
	Set tSC = $$ResourceList^%SYS.SECURITY("*",-1,-1,.tItems)
	If $$$ISERR(tSC) {
		&html<<th>#($$$TextHTML("Error Loading Resource List."))#</th></tr>>
		&html<<tr><td>#($System.Status.GetErrorText(tSC))#</td></tr>>
		Quit 1
	}
	&html<<th>&nbsp;</th>
	<th nowrap>#($$$TextHTML("Name"))#</th><th nowrap>#($$$TextHTML("Description"))#</th><th nowrap>#($$$TextHTML("Public Permission"))#</th></tr>>
	Set tRow = "",tTotal = 0
	Set tRow = $O(tItems(tRow))
	While tRow '= "" {
		Set tTotal = tTotal + 1
		Set tId = "cb_"_tTotal
		Set tName = tRow
		If $G(Current(tName)) = "" Set tClass = "OddRow",tChecked=""
		Else  Set tClass = "EvenRow",tChecked="checked"
		&html<<tr class="#(tClass)#"><td><input type="radio" name="radResource" id="#(tId)#" value="#(tName)#" #(tChecked)#></td><td nowrap>#(tName)#</td>>
		For i = 1:1:2 &html<<td>#($lg(tItems(tRow),i))#</td>>
		&html<</tr>>
		Set tRow = $O(tItems(tRow))
	}
	&html<<tr><td colspan="10">#($$$TextHTML("Total Resources"))#: #(tTotal)#</td>>
	Set %page.numRows = tTotal
	&html<</table></form>>
	Quit 1
}

}
