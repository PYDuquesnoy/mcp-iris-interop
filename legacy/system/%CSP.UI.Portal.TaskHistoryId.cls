/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// System Management Portal - System Operations - Task Hisotry
/// If $ID1 is passed in then show task history for that ID only. 
Class %CSP.UI.Portal.TaskHistoryId Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.TaskHistoryId.zen";

Parameter AppContextPath = "%25CSP.UI.Portal";

Parameter HELPADDRESS = "Home,Task Manager,Task Schedule,Task History";

Parameter PARENTPAGE = "/csp/sys/op/%CSP.UI.Portal.TaskSchedule.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Task History";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property DetailsPage As %String [ InitialExpression = {..Link(..#AppContextPath _ ".TaskInfo.zen",,1)} ];

Property CurrentColumn As %ZEN.Datatype.string [ InitialExpression = "Last Start" ];

/// internal task ID
Property PID As %String(ZENURL = "$ID1");

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
<pane containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>

<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<tableNavBar showFilter="false" showPageSize="true" tablePaneId="table" showMaxRows="true" 
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="%SYS.Task.History"
queryName="DescendingTaskHistoryForTask"
dataSource="columns"
fixedHeaders="false"
pageSize="0" 
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Pid"
useSnapshot="true"
>
<column colName="Last Start" header="Last Start"/>
<column colName="Completed" header="Completed"/>
<column colName="Status" header="Status"/>
<column colName="Result" header="Result"/>
<column colName="NameSpace" header="Namespace"/>
<column colName="Routine" header="Routine"/>
<column colName="Pid" header="PID"/>
<column colName="%ER Date" header="%ER Date"/>
<column colName="%ER Error #" header="%ER Error #"/>
<column colName="Task Name" hidden="true"/>
<column colName="Username" header="User"/>
<column colName="LogDate" header="Log Date"/>
<column colName="LogTime" header="Log Time"/>
<condition colName="Status" predicate="NEQ" value="1" rowStyle="background: #FFB6C1;"/> 
<parameter value="#(%page.PID)#"/>
 </tablePane>

</pane>
}

/// User clicked the Details button. Go to the Details page.
ClientMethod doDetails() [ Language = javascript ]
{
	var url = this.DetailsPage + "$ID1=" + encodeURIComponent(this.PID);
	document.location = url;
}

/// Update / Reload table. This overrides the one in Portal.Utils.
ClientMethod updateView() [ Language = javascript ]
{
	this.updateTime();
	this.refreshContents();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set TaskName = ##class(%CSP.UI.Portal.TaskInfo).GetTaskName(..PID, .tmsg, .IsRunning)
	If 'IsRunning,tmsg '= "" Set ..%GetComponentById("Text1").value = tmsg Quit $$$OK

	Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("History for Task %1 - %2:"),..PID,TaskName)
	
	Set ..LocatorHeader = $$$FormatText($$$Text("Task %1"),..PID)

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
	
	Set tPageName = $$$Text("Task Manager")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Task Schedule")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?$ID1="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Task History")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	
	Set pCommands(1) = $LB("btnDetails",$$$Text("Details"),$$$Text("View details of this task."),"zenPage.doDetails();")

	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

}
