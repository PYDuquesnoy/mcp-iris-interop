/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility dialog window displays and lets the user select from 
/// a set of routines.<br>
/// The user must have Use privileges for the %Development resource 
/// in order to use this page.
/// If Namespace is passed in then switch to that namespace to run the query
Class %ZEN.Dialog.routineSelect Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter AUTONS = 0;

/// No Apply button.
Parameter APPLYBUTTON = 0;

/// User must hold Development to use this dialog.
Parameter RESOURCE = "%Development";

/// Which namespace to search. Passed in via URL.
Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "NAMESPACE");

/// User may pass in a partial or full search mask.
Property MASK As %ZEN.Datatype.string(ZENURL = "MASK");

XData Style
{
<style type="text/css">
table.tpTable {
	border: 1px solid #F1F0E7;
	font-size: 12px;
}
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}
table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
</style>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup labelPosition="left" cellStyle="padding:2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>

<text hidden="true" name="NAMESPACE" id="NAMESPACE" value="#(%page.NAMESPACE)#"/>

<hgroup labelPosition="left">
<text name="Mask" id="Mask" label="Enter Search Mask:" value="#(%page.MASK)#" size="40"/>
<button name="btnSearch" id="btnSearch" caption="Search" onclick="zenPage.changeMask();"/>
</hgroup>
<html id="idMaskLinks" OnDrawContent="LoadMaskLinks">
</html>
<tableNavigatorBar showFilter="false" showPageSize="true" tablePaneId="ctrlList"/>
<tablePane id="ctrlList" name="List"
label="Routines:" 
queryClass="%RoutineMgr"
queryName="StudioOpenDialog"
dataSource="columns"
fixedHeaders="false"
multiSelect="false"
maxRows="10000"
pageSize="100"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
OnCreateResultSet="CreateRS"
OnExecuteResultSet="ExecuteRS"
ondblclick="zenPage.dialogFinish();"
>
<column colName="Name" header="Name" title="Routine name"/>
<column colName="Date" header="Date" title="Date/Time last modified"/>
<column colName="Size" header="Size" title="Routine size"/>
<parameter id="tspec" value="#(%page.MASK)#"/>
<parameter id="tdir" value="1"/>
<parameter id="torderby" value="1"/>
<parameter id="tshowsys" value="0"/>
<parameter id="tflat" value="1"/>
<parameter id="tnotstudio" value="1"/>
<parameter id="tshowgen" value="0"/>
<parameter id="tfilter" />
<parameter id="troundtime" value="1"/>
</tablePane>
</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $ZCVT($$$FormatText($$$Text("Select a routine within namespace %1:"),..NAMESPACE),"O","HTML")
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Routine Selection Dialog")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select an item from the list below.")
}

/// Create the result set used by the routine listbox.
Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK
	#; If user needs to search from a particular NAMESPACE, switch to that namespace now.
	If ..NAMESPACE '= "",..NAMESPACE '= $namespace Set $Namespace = ..NAMESPACE
	Set tRS = ##class(%ResultSet).%New()
	#;YSD1759 Set tRS.ClassName = "%Routine"
	#;YSD1759 Set tRS.QueryName = "RoutineList"
	Set tRS.ClassName = "%RoutineMgr"
	Set tRS.QueryName = "StudioOpenDialog"
	Quit tRS
}

/// Execute the routine listbox result set.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	#; Get the user defined mask and pass to query
	Set tSpec = $G(pInfo.parms(1))
	If (tSpec = "") {
		Set tSpec = ..MASK
	}
	#;YSD1759 Set tSC = pRS.Execute(tSpec,1,1)
	Set tNewSpec = ##class(%CSP.Util.ExpPane).GetMask(tSpec)
	#;YSD2861 - now using tablePane, add the flag to not show milliseconds.
	Set tSC = pRS.Execute(tNewSpec,1,1,0,1,1,,,1)

	Quit 1
}

/// Return the value that should be returned by this dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var val = this.getComponentById('ctrlList').getValue();
	return encodeURIComponent(val);
}

/// User has clicked the Search button.
ClientMethod changeMask() [ Language = javascript ]
{
	var mask = this.getComponentById('Mask');
	var p1 = this.getComponentById('tspec');
	p1.setProperty('value',mask.getValue());
	this.MASK = mask.getValue();
	var list = this.getComponentById('ctrlList');
	list.executeQuery(0);
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	#; If NAMESPACE is not passed in, then initialize it to be the current namespace
	If ..NAMESPACE = "" {
		Set ..NAMESPACE = $namespace
	}
	#; If MASK is not passed in, then initialize it to *.mac
	If ..MASK = "" Set ..MASK = "*.mac"
	
	Quit $$$OK
}

/// Build short cut Mask links.
Method LoadMaskLinks(pSeed As %String) As %Status
{
	Set titleText = $$$TextJS("click to search this mask")
	Set links = "*.mac,*.int,*.inc,*.bas,*.mvb,*.mvi"
	For i = 1:1:$L(links) Set mask = $P(links,",",i) &html<<a href="javascript:zenPage.loadMask('#(mask)#')" title='#(titleText)#'>#(mask)#</a>&nbsp;>

	Quit $$$OK
}

/// User has clicked a mask link. Put the selected mask into the Mask field then refresh list control.
ClientMethod loadMask(flag) [ Language = javascript ]
{
	var mask = this.getComponentById('Mask');
	mask.setValue(flag);
	this.changeMask();
}

ClientMethod onkeydownHandler(evt) [ Language = javascript ]
{
	if (13 == evt.keyCode) {
		this.changeMask();	
	}
	return true;
}

}
