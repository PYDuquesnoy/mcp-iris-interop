/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

/// Monitor page for the Interoperability Management Portal.
Class %CSP.UI.Portal.EnsembleMonitor Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Name of this page.
Parameter PAGENAME = "System Monitor";

/// If true, register visits to this page in the recent list.
Parameter RECENT = 1;

/// If true, auto-switch namespace to whatever $NAMESPACE is passed in.
Parameter AUTONS As BOOLEAN = 0;

/// User needs USE permissions on the %Ens_Dashboard resource to access this page.
Parameter RESOURCE = "%Ens_Dashboard:USE";

/// The help address that links to the "Help" (next to the "Logout" link) documentation
Property HelpAddress As %ZEN.Datatype.string [ InitialExpression = {$$$PRODUCT2_", "_..#PAGENAME} ];

/// Server-side reference to the pane object so that the head and body sections can be added to the page correctly.
Property %Pane As %CSP.Util.Pane [ ServerOnly = 1 ];

/// Flag to indicate whether <property>%Pane</property>'s OnDrawHEAD() method has been executed.
Property paneDone As %Boolean;

XData Style
{
<style type="text/css">
sysHeader {
	color: #606060;
	font-weight: bold;
	font-size: 10pt;
	padding-top: 10px;
}

sysInfo {
	color: #404040;
	font-size: 10pt;
}

sysAlert {
	color: #F04040;
	font-size: 10pt;
	font-weight: bold;
}

sysRunning {
	color: #40A040;
	font-size: 10pt;
	font-weight: bold;
}

A.LastUpdate {
	font-size: 0.7em;
	color: #333695;
	padding: 2px;
	background: white;
	border: 1px black solid;
}

A.LastUpdate:hover
{
	color: #00A09A;
}

TABLE.LayoutMain {
	margin: 0px;
	padding: 0px;
}

TABLE.LayoutMain TR {
	vertical-align: top;
}

TABLE.LayoutMain TD.LayoutMenuCol {
	background: white;
	border-right: 1px solid gray;
	vertical-align: top;
}

TABLE.LayoutMain TD.LayoutContentCol {
	padding-left: 20px;
	vertical-align: top;
}

DIV.TitleText {
	background: rgb(52,108,141);
	font-size: 20px;
	font-weight: bold;
	color: white;
	width: 80%;
}

DIV.text1:first-letter	{font-size: 1.4em;  }

TD.text1:first-letter	{font-size: 1.4em;  }

#MessageHTML a {
	color: #333695;
	padding: 2px;
	background: white;
	text-decoration: none;
	display: block;
}

table.htmldashboarddetail td {
	padding-left:10px;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="homePane" hidden="false">
<timer id="timer" timeout="0" ontimeout="zenPage.updateStats(zenThis);"/>
<spacer height="5" />
<hgroup id="topGroup">
<spacer width="25"/>
<vgroup cellVAlign="top" cellStyle="padding-top:6px;">
<html  id="statsBlock" OnDrawContent="DrawStats" />
<hgroup id="prodsPane" hidden="false" >
</hgroup>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $$$FormatText($$$Text("%1 System Monitor"), $$$PRODUCT2)
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$TextHTML("System Monitor")
}

/// Draw the contents of the diagram header.
Method DrawStats(pSeed As %String) As %Status
{
	Set tPage = ##class(%CSP.Util.PageInstance).%New()
	If '$IsObject(..%Pane) Set ..%Pane=..GetDetailPane(tPage)
	If '..paneDone {
		Do ..%Pane.DrawHEAD(tPage)
		Set ..paneDone = 1
	}
	Quit ..%Pane.DrawBODY(tPage)
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	var detail = document.getElementById("DetailHTML");
	if (detail) {
		var tr=detail.parentNode;
		var sect=tr.parentNode;
		var table=sect.parentNode;
		var td=table.parentNode;
		td.width="100%";
	}
}

ClientMethod updateStats(timer) [ Language = javascript ]
{
	var statsPanel = zen('stats');
	if (statsPanel) {
		statsPanel.refreshContents();
		if (zenPage.enableAutoRefresh) {
			timer.startTimer();
		}
	}
}

/// Instantiate <property>%Pane</property>.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..enableAutoRefresh {
		Set ..%GetComponentById("timer").timeout = 10000
	}
	
	Set tPage=##class(%CSP.Util.PageInstance).%New()
	Set ..%Pane=..GetDetailPane(tPage)
	Quit $$$OK
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
	&html<<style type="text/css">
.HTMLMeterLabel, .HTMLMeterLabelSELECTED, .ValueMeterValue, .BarOn {
	font-size: 12.8px;
}
table.group td.HTMLGroupLabel {
	padding: 2px 2px 2px 20px;
}
</style>>
	Quit $$$OK
}

ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
 Set tPane = ##class(%CSP.Util.HTMLDashboardPane).%New()
 Set tPane.Text = $$$Text("This dashboard displays real-time status of key production performance indicators for all productions running on this system:")
 Set tPane.MetricClass = "%SYS.Ensemble"
 Set tPane.MetricMethod = "GetEnsMetrics"
 Set tPane.Orientation = "vertical"
 Set tPane.ShowLegend = 1
 Set tPane.ShowIcons = 1
 Set tPane.RefreshRate = 60000
 
 // %CSP.Util.HTMLGroup - top
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tPane.Meters.Insert(tMeter)
 Set tMeter.Dashboard = tPane
 Set tGroup1 = tMeter
 Set tGroup1.Orientation = "horizontal"
 Set tGroup1.Width = 100
 Set tGroup1.Height = 20
 
 // %CSP.Util.HTMLGroup - col 1
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup1.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup1.Dashboard
 Set tGroup2 = tMeter
 Set tGroup2.Orientation = "vertical"
 Set tGroup2.Width = 100
 Set tGroup2.Height = 20
 
 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label = $$$Text("Production Throughput")
 Set tGroup3.Orientation = "vertical"
 Set tGroup3.Width = 100
 Set tGroup3.Height = 20
 Set tGroup3.Style = "Standard"
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Namespace")
 Set tMeter.Property = "EnsNamespace"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Productions running in namespaces on this system.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Productions Running")
 Set tMeter.Property = "EnsProductionsRunning"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Number of productions running on this system.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Productions Suspended or Troubled")
 Set tMeter.Property = "EnsProductionsTroubled"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Number of suspended or troubled productions on this system.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Incoming Messages in Last 30 Seconds")
 Set tMeter.Property = "EnsIncomingRequests"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("If the production is running, this number shows the sum count of all messages sent through business services during the last 3 complete 10-second intervals, ignoring the most recent fraction of a 10-second interval. This gives an indication of the current level of incoming activity in the production.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Last Incoming Message")
 Set tMeter.Property = "EnsLastIncomingRequest"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("If the production is running, this shows the time of the most recent incoming message processed by any business service in the production.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Outgoing Messages in Last 30 Seconds")
 Set tMeter.Property = "EnsOutgoingRequests"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("If the production is running, this number shows the sum count of all messages sent through business operations during the last 3 complete 10-second intervals, ignoring the most recent fraction of a 10-second interval. This gives an indication of the current level of outgoing activity in the production.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Last Outgoing Message")
 Set tMeter.Property = "EnsLastOutgoingRequest"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("If the production is running, this shows the time of the most recent outgoing message processed by any business operation in the production.")
 
 // %CSP.Util.HTMLSpacer
 Set tMeter = ##class(%CSP.Util.HTMLSpacer).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tMeter.Width = 100
 Set tMeter.Height = 15
 Set tMeter.ScaleFactor = 1

 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label=$$$Text("Production Jobs")
 Set tGroup3.Orientation = "vertical"
 Set tGroup3.Width = 100
 Set tGroup3.Height = 20
 Set tGroup3.Style = "Standard"
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Total System Processes")
 Set tMeter.Property = "Processes"
 Set tMeter.Width = "100%"
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/%25CSP.UI.Portal.Processes.zen"
 Set tMeter.Detail = $$$Text("Number of system processes currently active.")_" "_$$$Text("Click on the details link to view statistics for all processes on the system.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Active Production Jobs")
 Set tMeter.Property = "EnsJobs"
 Set tMeter.Width = "100%"
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Number of production jobs currently active.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Visiting Production Jobs")
 Set tMeter.Property = "EnsVisitingJobs"
 Set tMeter.Width = "100%"
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Number of jobs temporarily invoking production code.")
 
 // %CSP.Util.HTMLTableMeter
 Set tMeter = ##class(%CSP.Util.HTMLTableMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Rows = 7
 Set tMeter.ColumnNames=$$$Text("Namespace")_","_$$$Text("ConfigName")_","_$$$Text("PID")_","_$$$Text("Commands")
 Set tMeter.Label = $$$Text("Most Active Processes")
 Set tMeter.Property = "EnsBusyProcesses"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/%25CSP.UI.Portal.Processes.zen"
 Set tMeter.Detail = $$$Text("Jobs with the largest number of recently executed commands.")_" "_$$$Text("Click on the details link to view statistics for all processes on the system.")

 // %CSP.Util.HTMLSpacer - col 2
 Set tMeter = ##class(%CSP.Util.HTMLSpacer).%New()
 Do tGroup1.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup1.Dashboard
 Set tMeter.Width = 20
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 
 // %CSP.Util.HTMLGroup - col 2
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup1.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup1.Dashboard
 Set tGroup2 = tMeter
 Set tGroup2.Orientation = "vertical"
 Set tGroup2.Width=100
 Set tGroup2.Height=20
 
 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label=$$$Text("System Time")
 Set tGroup3.Orientation = "vertical"
 Set tGroup3.Width=100
 Set tGroup3.Height=20
 Set tGroup3.Style="Standard"
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align="right"
 Set tMeter.Label = $$$Text("System Up Time")
 Set tMeter.Property = "UpTime"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "/csp/sys/op/UtilDashboard.csp"
 Set tMeter.Detail = $$$Text("Elapsed time since this system was started.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Last Backup")
 Set tMeter.Property = "LastBackup"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/UtilSysBackups.csp"
 Set tMeter.Detail = $$$Text("Date and time of last system backup.")
 
 // %CSP.Util.HTMLSpacer
 Set tMeter = ##class(%CSP.Util.HTMLSpacer).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tMeter.Width = 100
 Set tMeter.Height = 15
 Set tMeter.ScaleFactor = 1
 
 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label=$$$Text("System Usage")
 Set tGroup3.Orientation="vertical"
 Set tGroup3.Width = 100
 Set tGroup3.Height = 20
 Set tGroup3.Style = "Standard"
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Database Space")
 Set tMeter.Property = "DatabaseSpace"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/_CSP.UI.Portal.OpDatabases.zen?FreespacesOn=1"
 Set tMeter.Detail = $$$Text("Indicates whether there is a reasonable amount of diskspace available for database files.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align="right"
 Set tMeter.Label = $$$Text("Database Journal")
 Set tMeter.Property = "DatabaseJournal"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/UtilSysJournals.csp"
 Set tMeter.Detail = $$$Text("Indicates the current status of the database journal.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Journal Space")
 Set tMeter.Property = "JournalSpace"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/UtilSysJournals.csp"
 Set tMeter.Detail = $$$Text("Indicates whether there is a reasonable amount of diskspace available for journal files.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Journal Entries")
 Set tMeter.Property = "JournalEntries"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/UtilSysJournals.csp"
 Set tMeter.Detail = $$$Text("Number of entries written to the system journal.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Lock Table")
 Set tMeter.Property = "LockTable"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/%25CSP.UI.Portal.Locks.zen"
 Set tMeter.Detail = $$$Text("Indicates the current status of the system Lock Table.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Write Daemon")
 Set tMeter.Property = "WriteDaemon"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Detail = $$$Text("Indicates the current status of the system Write Daemon.")

 // %CSP.Util.HTMLSpacer
 Set tMeter = ##class(%CSP.Util.HTMLSpacer).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tMeter.Width = 100
 Set tMeter.Height = 15
 Set tMeter.ScaleFactor = 1
 
 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label=$$$Text("Production Queues")
 Set tGroup3.Orientation = "vertical"
 Set tGroup3.Width = 100
 Set tGroup3.Height = 20
 Set tGroup3.Style = "Standard"
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align="right"
 Set tMeter.Label = $$$Text("Active Queues")
 Set tMeter.Property = "EnsActiveQueues"
 Set tMeter.Width = "100%"
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Number of queues currently active.")
 
 // %CSP.Util.HTMLTableMeter
 Set tMeter = ##class(%CSP.Util.HTMLTableMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Rows = 7
 Set tMeter.ColumnNames = $$$Text("Namespace,Queue,Messages")
 Set tMeter.Label = $$$Text("Most Active Queues")
 Set tMeter.Property = "EnsBusyQueues"
 Set tMeter.Width = 350
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Queues with largest number of unprocessed messages.")

 // %CSP.Util.HTMLSpacer - col 3
 Set tMeter = ##class(%CSP.Util.HTMLSpacer).%New()
 Do tGroup1.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup1.Dashboard
 Set tMeter.Width = 20
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 
 // %CSP.Util.HTMLGroup - col 3
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup1.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup1.Dashboard
 Set tGroup2 = tMeter
 Set tGroup2.Orientation = "vertical"
 Set tGroup2.Width = 100
 Set tGroup2.Height = 20
 
 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label = $$$Text("Errors and Alerts")
 Set tGroup3.Orientation = "vertical"
 Set tGroup3.Width = 100
 Set tGroup3.Height = 20
 Set tGroup3.Style = "Standard"
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Serious System Alerts")
 Set tMeter.Property = "SeriousAlerts"
 Set tMeter.Width = 300
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/UtilSysConsoleLog.csp"
 Set tMeter.Detail = $$$Text("Number of serious system-level alerts that have been raised.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Production Alerts")
 Set tMeter.Property = "EnsAlerts"
 Set tMeter.Width = 300
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Number of serious production alerts that have been raised.")
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("Production Errors")
 Set tMeter.Property = "EnsErrors"
 Set tMeter.Width = 300
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = ""
 Set tMeter.Detail = $$$Text("Number of application errors that have been logged.")
 
 // %CSP.Util.HTMLSpacer
 Set tMeter = ##class(%CSP.Util.HTMLSpacer).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tMeter.Width = 100
 Set tMeter.Height = 15
 Set tMeter.ScaleFactor = 1
 
 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label=$$$Text("Licensing")
 Set tGroup3.Orientation = "vertical"
 Set tGroup3.Width = 100
 Set tGroup3.Height = 20
 Set tGroup3.Style = "Standard"
 
 // %CSP.Util.HTMLValueMeter
 Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Align = "right"
 Set tMeter.Label = $$$Text("License Limit")
 Set tMeter.Property = "LicenseLimit"
 Set tMeter.Width = 300
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/%25CSP.UI.Portal.LicenseUsage.zen"
 Set tMeter.Detail = $$$Text("Maximum allowed license units for this system.")
 
 // %CSP.Util.HTMLBarMeter
 Set tMeter = ##class(%CSP.Util.HTMLBarMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Label = $$$Text("Current License Use")
 Set tMeter.Property = "LicenseUse"
 Set tMeter.Width = 300
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/%25CSP.UI.Portal.LicenseUsage.zen"
 Set tMeter.Detail = $$$Text("License usage as a percentage of available license units.")
 
 // %CSP.Util.HTMLBarMeter
 Set tMeter = ##class(%CSP.Util.HTMLBarMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Label = $$$Text("Highest License Use")
 Set tMeter.Property = "LicenseUseHigh"
 Set tMeter.Width = 300
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/%25CSP.UI.Portal.LicenseUsage.zen"
 Set tMeter.Detail = $$$Text("Highest license usage as a percentage of available license units.")
 
 // %CSP.Util.HTMLSpacer
 Set tMeter = ##class(%CSP.Util.HTMLSpacer).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tMeter.Width = 100
 Set tMeter.Height = 15
 Set tMeter.ScaleFactor = 1
 
 // %CSP.Util.HTMLGroup
 Set tMeter = ##class(%CSP.Util.HTMLGroup).%New()
 Do tGroup2.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup2.Dashboard
 Set tGroup3 = tMeter
 Set tGroup3.Label=$$$Text("Task Manager")
 Set tGroup3.Orientation = "vertical"
 Set tGroup3.Width = 100
 Set tGroup3.Height = 20
 Set tGroup3.Style = "Standard"
 
 // %CSP.Util.HTMLTableMeter
 Set tMeter = ##class(%CSP.Util.HTMLTableMeter).%New()
 Do tGroup3.InsertMeter(tMeter)
 Set tMeter.Dashboard = tGroup3.Dashboard
 Set tMeter.Rows = 10
 Set tMeter.ColumnNames = $$$Text("Task,Time,Status")
 Set tMeter.Label = $$$Text("Upcoming Tasks")
 Set tMeter.Property = "UpcomingTasks"
 Set tMeter.Width = 300
 Set tMeter.Height = 20
 Set tMeter.ScaleFactor = 1
 Set tMeter.Link = "op/%25CSP.UI.Portal.TasksUpcoming.zen"
 Set tMeter.Detail = $$$FormatText($$$Text("These are the next %1 tasks scheduled to run."),10)
 
 Quit tPane
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
/// Overridden to show Interoperability->Monitor->ProductionMonitor.
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$PRODUCT2
	Set tURL = ..Link($ZCVT("%CSP.Portal.Home","O","URL")_".zen?$NAMESPACE="_$G(%session.Data("$NAMESPACE")))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Monitor")
	Set tURL = ..Link($ZCVT("%CSP.Portal.Home","O","URL")_".zen?$NAMESPACE="_$G(%session.Data("$NAMESPACE")))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".cls?$NAMESPACE="_$G(%session.Data("$NAMESPACE"))))
	Quit $$$OK
}

/// Custom handler for hyperEvent handlers to be (optionally) less 
/// intrusive if the cause of the error was an auto-refresh timer
/// losing commectivity with the host.
/// Modified from %ZEN.Portal.standardPage because auto-refresh is hard-coded
ClientMethod onServerMethodError(err, errObject) [ Language = javascript ]
{
	var doAlert = true;
	if (errObject) {
		var code = errObject.code;
		var serverCode = errObject.serverCode;
		if ((code == 401) && ((serverCode == 864) || (serverCode == 5918))) {
			self.document.location.reload();
			doAlert = false;
		}
		else if ((zenPage.enableAutoRefresh) && (zenPage.limitPopups)&&(code<401)) { // refresh timer related
			zenPage.setConnectivityStatusMsg(err);
			window.setTimeout('zenPage.setConnectivityStatusMsg("Re-trying");',10000);
			window.setTimeout('zenPage.testConnectivity();',10000);
			doAlert = false;
		}
	}
	if (doAlert) {
		alert(err);
	}
	return true;
}

}
