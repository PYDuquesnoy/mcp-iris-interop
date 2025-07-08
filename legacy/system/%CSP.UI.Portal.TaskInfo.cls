/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - Task Details 
Class %CSP.UI.Portal.TaskInfo Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.TaskInfo.zen";

Parameter HELPADDRESS = "Home,Task Manager,View Task Schedule,Task Details";

Parameter PARENTPAGE = "/csp/sys/op/%CSP.UI.Portal.TaskSchedule.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Operation TaskInfo";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Parameter AppContextPath As STRING = "%25CSP.UI.Portal";

/// internal task ID
Property PID As %String(ZENURL = "$ID1");

Property CanBeEdited As %ZEN.Datatype.boolean [ InitialExpression = "1" ];

Property CanBeSuspended As %ZEN.Datatype.boolean [ InitialExpression = "1" ];

Property CanBeDeleted As %ZEN.Datatype.boolean [ InitialExpression = "1" ];

Property ActionPage As %String [ InitialExpression = {..Link("UtilSysTaskAction.csp",,1)} ];

Property EditPage As %String [ InitialExpression = {..Link("UtilSysTaskOption.csp",,1)} ];

Property HistoryPage As %String [ InitialExpression = {..Link(..#AppContextPath _ ".TaskHistoryId.zen",,1)} ];

/// parent page link
Property TaskSchedulePage As %String;

/// this page's link with PID and DISPLAYID
Property TaskDetailsPage As %String;

/// Server-side reference to the pane object so that the head and body sections can be added to the page correctly.
Property %Pane As %CSP.Util.Pane [ ServerOnly = 1 ];

/// Flag to indicate whether <property>%Pane</property>'s OnDrawHEAD() method has been executed.
Property paneDone As %Boolean;

XData Style
{
<style type="text/css">

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>

<group id="page_1" width="100%">
<html id="detailBlock" OnDrawContent="DrawDetails"/>
</group>

</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	#; Find out if the task is currently running. If it is, then we will not be able to open the object thus we need to disable the action buttons.
	Set TaskName = ..GetTaskName(..PID, .tmsg, .IsRunning)
		
	#; Now disable buttons when appropriate
	Set ..CanBeEdited = ('IsRunning && ##class(%CSP.Portal.Utils).%CheckTaskResource())
	Set tPOBJ = ##class(%SYS.Task).%OpenId(..PID,0)
	If $IsObject(tPOBJ) {
		If '##class(%SYS.Task.Definition).CheckPermission(tPOBJ.TaskClass, tPOBJ.NameSpace) {
			Set ..CanBeEdited = 0
			Set ..CanBeSuspended = 0
			Set ..CanBeDeleted = 0
			Set tmsg = $$$FormatText($$$Text("You do not have permission to edit task: %1"), TaskName)
		} Else {
			Set ..CanBeSuspended = (tPOBJ.Suspended = 0)
			Set ..CanBeDeleted = (tPOBJ.Type '= 0)
		}
	}
	If tmsg '= "" Set ..%GetComponentById("Text1").value = tmsg

	$$$SetRefreshTimer

	Set tPage = ##class(%CSP.Util.PageInstance).%New()
	Set ..%Pane=..GetDetailPane(tPage)

	Set ..LocatorHeader = $$$FormatText($$$Text("Task %1"),..PID)

	Quit $$$OK
}

/// Given a Task Id, return the Task Name. This method is used by other task pages.
/// As the returned values is being set into Zen component, it needs no extra escaping as the Zen component will escape it.
ClassMethod GetTaskName(pTaskId, Output pMessage = "", Output pIsRunning = 0) As %String
{
	Set pMessage = ""
	If pTaskId = "" {
		Set pMessage = $$$Text("Task ID does not exist.")
		Quit ""
	} Else {
		If '##class(%SYS.Task).%ExistsId(pTaskId) {
			Set pMessage = $$$FormatText($$$Text("Task Id %1 no longer exists."),pTaskId)
			Quit ""
		}
	}	
	Set tPOBJ = ##class(%SYS.Task).%OpenId(pTaskId,0,.status)
	If $$$ISERR(status) Set pMessage = $System.Status.GetErrorText(status) Quit ""
	Set TaskName = tPOBJ.Name
	If tPOBJ.Status = -1 {
		Set pMessage = $$$FormatText($$$Text("Task %1, %2, is currently running. Some actions will not be allowed during this time."),pTaskId,TaskName)
		Set pIsRunning = 1
	}
	Quit TaskName
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
	Set ..TaskSchedulePage = tURL

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set tURL = ..Link($ZCVT($className(),"O","URL")_".zen?$ID1="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE)))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	Set ..TaskDetailsPage = tURL

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnEdit",$$$Text("Edit"),$$$Text("Edit this task if privilege allows."),"zenPage.doAction('Edit');")
	Set pCommands(2) = $LB("btnHistory",$$$Text("History"),$$$Text("View history of this task."),"zenPage.doAction('History');")
	Set pCommands(3) = $LB("btnResume",$$$Text("Resume"),$$$Text("Resume this task if it is suspended."),"zenPage.doAction('Resume');")
	Set pCommands(4) = $LB("btnSuspend",$$$Text("Suspend"),$$$Text("Suspend this task if privilege allows."),"zenPage.doAction('Suspend');")
	Set pCommands(5) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete this task if privilege allows."),"zenPage.doAction('Delete');")
	Set pCommands(6) = $LB("btnExport",$$$Text("Export"),$$$Text("Export this task if privilege allows."),"zenPage.doAction('Export');")
	Set pCommands(7) = $LB("btnRun",$$$Text("Run"),$$$Text("Run this task."),"zenPage.doAction('Run');")
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Task Details")
}

/// This is called when the template is first displayed;
/// This provides a chance to load the last filetype, etc.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.CanBeSuspended) {
		this.disableCommandButton("btnResume");	
	} else {
		this.disableCommandButton("btnSuspend");
	}
	if (!this.CanBeDeleted) {
		this.disableCommandButton("btnDelete");
	}
	if (this.CanBeEdited == 0) {
		this.disableCommandButton("btnEdit");
		this.disableCommandButton("btnDelete");
		this.disableCommandButton("btnResume");	
		this.disableCommandButton("btnSuspend");
		this.disableCommandButton("btnExport");
	}
	if ((this.CanBeEdited == 0) || (!this.CanBeSuspended)) {
		this.disableCommandButton("btnRun");
	}
}

ClientMethod doAction(action) [ Language = javascript ]
{
	var url = "";
	if (action != "History" && !this.CanBeEdited) {
		return;	
	}
	switch (action) {
		case 'Edit':
			url = this.EditPage + "Type=Edit";
			break;
		case 'History':
			url = this.HistoryPage + "$ID1=" + encodeURIComponent(this.PID);
			break;
		case 'Resume':
			if (!this.CanBeSuspended) url = this.ActionPage + "Type=Resume";
			break;
		case 'Suspend':
			if (this.CanBeSuspended) url = this.ActionPage + "Type=Suspend";
			break;
		case 'Delete':
			if (confirm($$$Text("Are you sure you want to delete this task?")) == true) {
				url = this.ActionPage + "Type=Delete";
			}
			break;
		case 'Export':
			url = this.ActionPage + "Type=Export";
			break;
		case 'Run':
			url = this.ActionPage + "Type=Run";
			break;		
	}
	if (url != "") {
		if (action != "History") url = url + "&$ID1=" + encodeURIComponent(this.PID);
		document.location = url;
	}
}

/// For auto-refresh on this page.
ClientMethod updateView() [ Language = javascript ]
{
	document.location = this.TaskDetailsPage;
}

/// Draw the contents of the diagram header, in the HTMLDashboard style.
Method DrawDetails(pSeed As %String) As %Status
{
	Set tPage = ##class(%CSP.Util.PageInstance).%New()
	If '$IsObject(..%Pane) Set ..%Pane=..GetDetailPane(tPage)
	If '..paneDone {
		Do ..%Pane.DrawHEAD(tPage)
		Set ..paneDone = 1
	}
	Set tSC = ..%Pane.DrawBODY(tPage)
	Quit tSC
}

/// Add the HEAD section for <property>%Pane</property> and override some CSS styles if HTML5 is enabled.
/// Without these overrides, the font size is calculated to be 0.8px and padding is calculated to be 0 for the header cells..
Method %OnDrawHTMLHead() As %Status
{
	If $IsObject(..%Pane) {
		Set tPage = ##class(%CSP.Util.PageInstance).%New()
		Do ..%Pane.DrawHEAD(tPage)
		Set ..paneDone = 1
	}
	If ..cssLevel >= 3 {
		&html<<style type="text/css">
.HTMLMeterLabel, .HTMLMeterLabelSELECTED, .ValueMeterValue, .BarOn {
	font-size: 12.8px;
}
table.group td.ValueMeterValue {
	padding-right:5px;
}
table.group td.HTMLGroupLabel {
	padding: 2px 2px 2px 20px;
}
</style>>
	}
	Quit $$$OK
}

/// Set properties for HTMLDashboardPane to draw details.
ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	
	Set tPane = ##class(%CSP.Util.HTMLDashboardPane).%New()
	Set tPane.Text = "" 
	Set tPane.MetricClass = "SYS.Metrics"
	Set tPane.MetricMethod = "GetTaskMetrics"
	Set tPane.Orientation = "horizontal"
	Set tPane.ShowLegend = 1
	Set tPane.ShowIcons = 1
	#; Must set RefreshRate here otherwise the select row does not work. Though we do not intend use the built-in auto-refresh feature on this page (we have our own refresh control), thus the big number.
	Set tPane.RefreshRate = "6000000"
 
	#; First Group on the left containing "General Information"
	Set tGroup1 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tPane.Meters.Insert(tGroup1)
	Set tGroup1.Dashboard = tPane
	Set tGroup1.Orientation = "horizontal"
	Set tGroup1.Width = 450
	Set tGroup1.Height = 20

	#; Group 11: "General Information"
	Set tGroup11 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tGroup1.InsertMeter(tGroup11)
	Set tGroup11.Label=$$$Text("General Information")
	Set tGroup11.Orientation = "vertical"
	Set tGroup11.Width = 450
	Set tGroup11.Style="Standard"

	// Add horizontal spacer in between two column groups
	Set tSpacer = ##class(%CSP.Util.HTMLSpacer).%New()
 	Do tGroup1.Meters.Insert(tSpacer)
	Set tSpacer.Width = 20

	#; Second Group on right containing "Execution Details"
	Set tGroup2 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tGroup1.InsertMeter(tGroup2)
	Set tGroup2.Dashboard = tPane
	Set tGroup2.Orientation = "vertical"
	Set tGroup2.Width = 450
	Set tGroup2.Height = 20

	#; Group 21: "Execution Details"
	Set tGroup21 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tGroup2.InsertMeter(tGroup21)
	Set tGroup21.Label=$$$Text("Execution Details")
	Set tGroup21.Orientation = "vertical"
	Set tGroup21.Width = 450
	Set tGroup21.Style="Standard"

	// Add vertical spacer in between two groups
	Set tSpacer = ##class(%CSP.Util.HTMLSpacer).%New()
	Do tGroup2.Meters.Insert(tSpacer)
	Set tSpacer.Height = 20

	#; *************** LOAD DETAILS TO GROUPS ************************ ;#
 
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Task Name"),"Name",450,"",$$$Text("Name of this task.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Description"),"Description",450,"",$$$Text("Description of this task.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Namespace"),"NameSpace",450,"",$$$Text("Namespace that this task will be run.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Task Class"),"TaskClass",450,"",$$$Text("Task class used for this task.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Task Priority"),"Priority",450,"",$$$Text("Priority level of this task.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Is Batch Mode"),"IsBatch",450,"",$$$Text("Whether this task is in a batch mode.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Type"),"Type",450,"",$$$Text("Task type.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Suspended"),"Suspended",450,"",$$$Text("Whether this task is suspended. Three possibilities: (1) Not suspended. (2) Suspend Leave - Suspend the task, but leave it in task queue. (3) Suspend Reschedule - Suspend the task, remove from task queue, and reschedule for next time.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Last Status"),"DisplayStatus",450,"",$$$Text("The Status of the last run.")))

	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Run by User"),"RunAsUser",450,"",$$$Text("This task will be run by this user.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("How often this task is run"),"DisplayRun",450,"",$$$Text("Indicates how often this task is set up to run.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Last Schedule"),"LastSchedule",450,"",$$$Text("The last scheduled starting time.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Last Started"),"LastStarted",450,"",$$$Text("The last starting time.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Last Finished"),"LastFinished",450,"",$$$Text("The last finishing time.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Next scheduled time"),"DisplayNextScheduled",450,"",$$$Text("The next scheduled time to run.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Interval between runs"),"DisplayInterval",450,"",$$$Text("Interval between each run.")))

 Quit tPane
}

}
