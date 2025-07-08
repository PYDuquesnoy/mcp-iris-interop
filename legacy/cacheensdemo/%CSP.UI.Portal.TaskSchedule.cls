/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// System Management Portal - System Operations - Task Schedule 
Class %CSP.UI.Portal.TaskSchedule Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.TaskSchedule.zen";

Parameter HELPADDRESS = "Home,Task Manager,View Task Schedule";

/// Displayed name of this page.
Parameter PAGENAME = "Task Schedule";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property AppContextPathProp As %ZEN.Datatype.string [ InitialExpression = "%CSP.UI.Portal" ];

Property CurrentColumn As %ZEN.Datatype.string [ InitialExpression = "ID" ];

Property Filter As %ZEN.Datatype.string;

Property Status As %ZEN.Datatype.integer;

/// Store translated targetCol linkCaption for <condition>
Property colRun As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Run")} ];

XData Style
{
<style type="text/css">
/* additional style for table pane */
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<hgroup>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<spacer width="40" />
<button id="Button1" onclick="zenPage.doSuspend();" caption="Suspend"  controlClass="commandButton"/>
</hgroup>
<label id="Text2" value="" containerStyle="padding-bottom:4px;"/>
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a string to filter the list"
/>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="%SYS.Task"
queryName="TaskListFilter"
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
<column colName="Task Name" header="Task Name" link="#(%page.AppContextPathProp)#.TaskInfo.zen?$ID1=#(%query.ID)#" 
title="View details of this task"/>
<column colName="Task Type" header="Task Type"/>
<column colName="Namespace" header="Namespace"/>
<column colName="Description" header="Description"/>
<column colName="ID"/>
<column colName="Suspended" header="Suspended"/>
<column colName="Last Finished" header="Last Finished"/>
<column colName="Next Scheduled" header="Next Scheduled"/>

<column linkCaption="History" link="#(%page.AppContextPathProp)#.TaskHistoryId.zen?$ID1=#(%query.ID)#" 
style="text-align:center;" title="View history of this task"/>

<column linkCaption="Run" id="LinkRun" link="UtilSysTaskAction.csp?Type=Run&amp;$ID1=#(%query.ID)#" 
style="text-align:center;" title="Run this task"/>

<condition colName="Suspended" predicate="NEQ" value="NULL" rowStyle="background: #FFB6C1;" cellStyle="disabled" targetCol="#(%page.colRun)#"/> 
<parameter value="#(%page.Filter)#"/>
 </tablePane>
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

	Set ..Status=##class(%SYS.Task).TASKMGRStatus()
	Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("Task Manager is currently %1","%Utility"),$case(..Status,0:$$$Text("not running","%Utility"),1:$$$Text("running","%Utility"),:$$$Text("suspended","%Utility")))
	Set ..%GetComponentById("Button1").caption=$case(..Status,0:$$$Text("Start"),1:$$$Text("Suspend"),2:$$$Text("Resume"))
	Set ..%GetComponentById("Text2").value = $$$Text("The following is a list of tasks scheduled for execution:")
		
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
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Task Manager")
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
	Quit $$$Text("Task Schedule")
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

/// Handle Suspend/Resume click
ClientMethod doSuspend() [ Language = javascript ]
{
	
	var msg;
	switch(this.Status) {
		case 0:
			msg = $$$Text('Are you sure you want to Start the Task Manager?');
			break;
		case 1:
			msg = $$$Text('Are you sure you want to Suspend the Task Manager?');
			break;
		default:
			msg = $$$Text('Are you sure you want to Resume the Task Manager?');	
	}
	if (confirm(msg)) {
		msg = this.Suspend();
		if (msg != "") alert(msg);
	}
	return;
}

Method Suspend() As %String [ ZenMethod ]
{
	Set status=##class(%SYS.Task).TASKMGRStatus(),errmsg=""
	If ..Status = 0 {
		If status '= 0 {
			Set errmsg = $$$Text("Task Manager is already running","%Utility")
		} Else {
			Do ##class(%SYS.Task).StartTASKMGR()
		}
	} ElseIf ..Status = 1 {
		If status '= 1 {
			Set errmsg = $$$Text("Task Manager is already Suspended","%Utility")
		} Else {
			Do ##class(%SYS.Task).SuspendSet(1)
		}
	} Else {
		If status '= 2 {
			Set errmsg = $$$Text("Task Manager not Suspended","%Utility")
		} Else {
			Do ##class(%SYS.Task).SuspendSet(0)
		}
	}
	If errmsg = "" Hang 1
	Set ..Status=##class(%SYS.Task).TASKMGRStatus()
	Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("Task Manager is currently %1","%Utility"),$case(..Status,0:$$$Text("not running","%Utility"),1:$$$Text("running","%Utility"),:$$$Text("suspended","%Utility")))
	Set ..%GetComponentById("Button1").caption=$case(..Status,0:$$$Text("Start"),1:$$$Text("Suspend"),2:$$$Text("Resume"))
	Quit errmsg
}

}
