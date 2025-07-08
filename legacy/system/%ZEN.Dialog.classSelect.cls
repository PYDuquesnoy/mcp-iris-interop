/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility dialog window displays and lets the user select from 
/// a set of class definitions.<br>
/// The user must have Use privileges for the %Development resource 
/// in order to use this page.
Class %ZEN.Dialog.classSelect Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter AUTONS = 1;

/// No Apply button.
Parameter APPLYBUTTON = 0;

/// User must hold Development to use this dialog.
Parameter RESOURCE = "%Development";

/// What type of item to select. Passed in via URL.
Property mode As %ZEN.Datatype.string(VALUELIST = ",class", ZENURL = "mode");

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup labelPosition="left" cellStyle="padding:2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<dataCombo label="Package:"
		id="ctrlPackage"
		name="Package"
		required="true"
		title="Package name"
		editable="true"
		unrestricted="true"
		searchKeyLen="0"
		maxRows="500"
		dropdownWidth="20.0em"
		size="40"
		OnCreateResultSet="CreatePackageRS"
		onchange="zenPage.changePackage();"
/>

<dataListBox label="Classes:" 
	id="ctrlList"
	name="List"
	listHeight="400px;"
	title="Class name" 
	OnCreateResultSet="CreateClassRS"
	OnExecuteResultSet="ExecuteClassRS"
	OnDrawItem="DrawClassItem"
	onchange="zenPage.changeClass();"
	ondblclick="zenPage.dialogFinish();"
>
<parameter id="listP1" value=""/>
</dataListBox>
</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$FormatText($$$TextHTML("Select a class within namespace %1:"),$namespace)
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If (..mode = "table") {
		Quit $$$TextHTML("Table Selection Dialog")
	}
	Quit $$$TextHTML("Class Selection Dialog")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select an item from the list below.")
}

/// Create the result set used by the Package dataCombo.
Method CreatePackageRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%ZEN.Utils"
	Set tRS.QueryName = "EnumeratePackages"
	Quit tRS
}

/// Create the result set used by the Class listbox.
Method CreateClassRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%Library.RoutineMgr"
	Set tRS.QueryName = "StudioOpenDialog"
	Quit tRS
}

/// Execute the class listbox result set.
Method ExecuteClassRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSpec = $G(pInfo.parms(1))
	If (tSpec = "") {
		Set tSpec = "*"
	}
	Else {
		Set tSpec = tSpec _ ".*"
	}
	Set tShowSys = 0
	Set:$E(tSpec,$L(tSpec)-3,$L(tSpec))'=".cls" tSpec = tSpec_".cls"
	Set tSC = pRS.Execute(tSpec,,,tShowSys,1,1)  //flat is set to 1,NotStudio is set to 1
	Quit 1
}

/// Callback for class list box.
Method DrawClassItem(pRS As %ResultSet, pValue As %String, pText As %String) As %String
{
	Set tClass = $G(pRS.Data("Name"))
	Set tClass = $P(tClass,".",1,$L(tClass,".")-1)
	Quit tClass
}

/// Return the value that should be returned by this dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var val = this.getComponentById('ctrlList').getValue();
	val = encodeURIComponent(val);
	
	// strip off .cls
	return (''==val) ? val : val.substr(0,val.length-4);
}

/// User has selected a new package name.
ClientMethod changePackage() [ Language = javascript ]
{
	var pkg = this.getComponentById('ctrlPackage');
	var list = this.getComponentById('ctrlList');
	var p1 = this.getComponentById('listP1');
	
	p1.setProperty('value',pkg.getValue());
	list.executeQuery();
}

/// User has selected a new class name.
ClientMethod changeClass() [ Language = javascript ]
{
	return;
}

}
