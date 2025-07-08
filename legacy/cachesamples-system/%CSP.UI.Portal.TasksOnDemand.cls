/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Task on demand 
Class %CSP.UI.Portal.TasksOnDemand Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.TasksOnDemand.zen";

Parameter HELPADDRESS = "Home,Task Manager,Run Task On Demand";

/// Displayed name of this page.
Parameter PAGENAME = "On Demand Tasks";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property RunTaskPage As %String [ InitialExpression = {..Link("UtilSysTaskAction.csp",,1)} ];

XData Style
{
<style type="text/css">
/* additional style for table pane */
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

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<vgroup valign="top">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a string to filter the list"
/>
<tablePane id="table"
queryClass="%SYS.Task"
queryName="OnDemandTasksFilter"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
>
<column colName="ID" hidden="true"/>
<column colName="Task Name" header="Task Name"/>
<column colName="Description" header="Description"/>
<column id="LinkRun" linkCaption="Run" link="javascript:zenPage.doRun('#(%query.ID)#');" 
 style="text-align:center;"/>
<parameter value="#(%page.Filter)#"/>
 </tablePane>
 </vgroup>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value, tableID) [ Language = javascript ]
{
	var table = zen(tableID);
	if (value=="*") value="";
	table.parameters[0].value = value;
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	this.updateTime();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of tasks that can be run on demand:")

	#; Check if user has security for "Run" schedule.
	If '$System.Security.Check("%Admin_Task","USE") {
		Set ..%GetComponentById("LinkRun").hidden = 1
	}
	// The default filter in the page we inherit from is initially set to "*". This screws up the new filtering system.
	i ..Filter="*" s ..Filter=""

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Task Manager","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"))
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("On-demand Tasks")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

ClientMethod doRun(PID) [ Language = javascript ]
{
	var viewlink = this.RunTaskPage + "Type=Run&$ID1=" + encodeURIComponent(PID);
	document.location = viewlink;
}

}
