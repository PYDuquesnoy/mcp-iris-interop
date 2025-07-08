/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - Process Details page 
Class %CSP.UI.Portal.ProcessDetails Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "zenCSLM.js";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.ProcessDetails.zen";

Parameter HELPADDRESS = "Home,Processes";

/// Displayed name of this page.
Parameter PAGENAME = "Process Details";

Parameter PARENTPAGE = "/csp/sys/op/%CSP.UI.Portal.Processes.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

/// internal process ID
Property PID As %String(ZENURL = "PID");

Property PrevPID As %String [ InitialExpression = "PrevPID" ];

/// display process ID
Property DISPLAYID As %String(ZENURL = "DISPLAYID");

/// current tab number
Property currTab As %String(ZENURL = "tab");

/// Whether to display SQL operator details
Property SQL As %Boolean(ZENURL = "SQL");

Property CanBeTerminated As %ZEN.Datatype.boolean [ InitialExpression = "1" ];

Property CanBeSuspended As %ZEN.Datatype.boolean [ InitialExpression = "1" ];

/// parent page link
Property ProcessesPage As %String;

/// this page's link with PID and DISPLAYID
Property ProcessDetailsPage As %String;

/// Server-side reference to the pane object so that the head and body sections can be added to the page correctly.
Property %Pane As %CSP.Util.Pane [ ServerOnly = 1 ];

/// Flag to indicate whether <property>%Pane</property>'s OnDrawHEAD() method has been executed.
Property paneDone As %Boolean;

XData Style
{
<style type="text/css">

</style>
}

XData SVGStyle
{
<style type="text/css">
.tabBarBackground { fill:white; stroke:white; }	
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">

<group cellStyle="font-size: 12px" enclosingClass="EditForm" enclosingStyle="padding: 3px;" >
<label label="Show:" />
<checkbox caption="SQL table &amp; statement info" value="#(%page.SQL)#" onchange="zenPage.toggleSQL(zenThis.value);"/>
</group>
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<vgroup cellVAlign="top">
<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white; stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":Details:Variables"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>
<group width="100%" >
<group id="page_1" width="100%">
<spacer height="10"/>
<html id="detailBlock" OnDrawContent="DrawDetails"/>
</group>
<group id="page_2" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="true" showPageSize="true" showMaxRows="true" tablePaneId="table"
title="Enter a partial variable name and hit [Tab] to narrow the list down. Up to 10000 variables can be retrieved."
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" onheaderClick="zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="SYS.Process"
queryName="VariableByPid"
dataSource="columns"
fixedHeaders="false"
multiSelect="false"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
initialExecute="false"
pageSize="100"
>
<column colName="Name" header="Name"/>
<column colName="Value" header="Value"/>
<parameter id="Pid" value=""/>
<parameter id="VariableName" value=""/>
<parameter id="Format" value="0"/>
<parameter id="MaxRows" value="1000"/>
<parameter id="Filter" value="#(%page.Filter)#"/>
</tablePane>
</group>
</group>
</vgroup>
</pane>
}

Method DrawCQLink(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	#; Do not need to check ..SQL; the column is added only if ..SQL '= 0
	if %query("Value")["sqlcq", $SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		set namespace=$zu(61,6,$zu(67,3,+..PID))
		if $data(^[namespace]rINDEX(%query("Value")_".1","INT")) {
			set url = $$cspLink^%SYS.cspServer("/csp/sys/exp/%25CSP.UI.System.ViewCode.cls",,1)_"$NAMESPACE="_namespace_"&$TYPE=rtn&FILENAME=" _%query("Value")_".1.int"
			&html<<a href=#(url)# target='_blank' rel='noopener noreferrer'>View #(%query("Value")_".1.int")#</a>>
		}
	}
	return $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set tmsg = ""
	If ..PID = "" {
		Set tmsg = $$$Text("Process ID does not exist.")
	} Else {
		If '##class(SYS.Process).%ExistsId(..PID) {
			Set tmsg = $$$Text("Process no longer exists.")
		}
	}
	If tmsg '= "" Set ..%GetComponentById("Text1").value = tmsg Quit $$$OK
		
	#; Now disable buttons when appropriate
	Set tPOBJ = ..GetPIDOBJ(..PID)
	If '$IsObject(tPOBJ) Quit tPOBJ
	i %page.PID'=$G($$$IRISTempMgt($Username,..%GetPageName(),"PrevPID")) {
		s CRLF=$c(13,10)
		Set EventDesc = $$$EventDescription
		Set EventData="Examine the following process:"_CRLF
		Set EventData = EventData_"Pid:           "_tPOBJ.PidExternal_CRLF
		Set EventData = EventData_"Namespace:     "_tPOBJ.NameSpace_CRLF
		Set EventData = EventData_"Routine:       "_tPOBJ.Routine_CRLF
		Set EventData = EventData_"Username:      "_tPOBJ.UserName_CRLF
		Set EventData = EventData_"CurrentDevice: "_tPOBJ.CurrentDevice_CRLF
		Set $$$IRISTempMgt($Username,..%GetPageName(),"PrevPID")=%page.PID
		$$$SMPAuditView
	}
	Set ..CanBeTerminated = tPOBJ.CanBeTerminated
	Set ..CanBeSuspended = tPOBJ.CanBeSuspended

	Set tPage = ##class(%CSP.Util.PageInstance).%New()
	Set ..%Pane=..GetDetailPane(tPage)
	
	Set ..LocatorHeader = $$$FormatText($$$Text("Process %1"),..PID)
	
	if (..SQL) {
		Set tbl = %page.%GetComponentById("table")
		Set col = ##class(%ZEN.Auxiliary.column).%New()
		Set col.OnDrawCell="DrawCQLink"
		Do tbl.columns.Insert(col)
		Do %page.%AddComponent(col)
	}

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Processes")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	Set ..ProcessesPage = tURL

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set tURL = ..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_"&DISPLAYID="_..EscapeURL(..DISPLAYID)_"&$ID1="_..EscapeURL(..PID))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	Set ..ProcessDetailsPage = tURL
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnResume",$$$Text("Resume"),$$$Text("Resume this process if it has been suspended."),"zenPage.doResume();")
	Set pCommands(2) = $LB("btnSuspend",$$$Text("Suspend"),$$$Text("Suspend this process if the process can be suspended."),"zenPage.doSuspend();")
	Set pCommands(3) = $LB("btnTerminate",$$$Text("Terminate"),$$$Text("Terminate this process if the process can be terminated."),"zenPage.doTerminate();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Process Details")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
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

/// This is called when the template is first displayed;
/// This provides a chance to load the last filetype, etc.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
	// check if we should start auto-refresh
	if (this.CanBeTerminated == 0) {
		this.disableCommandButton("btnTerminate");
	}
	if (this.CanBeSuspended == 0) {
		this.disableCommandButton("btnSuspend")
	} else {
		this.disableCommandButton("btnResume")
	}
	if (this.CanBeTerminated == 0) {
		this.disableCommandButton("btnTerminate")
		//if cannot be terminated and cannot be suspended then disable resume as well
		if (this.CanBeSuspended == 0) this.disableCommandButton("btnResume");
	}
	/// load variable table
	var table = zen("table");
	table.parameters[0].value = this.PID;
	table.executeQuery();
	/// show variable tab if refresh happend while using is viewing tab 2.
	if (this.currTab == 2) {
		this.tabChanged(1);
		zen("tabBar").setProperty("selectedIndex",1);
	}
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	// these are the largest sizes for the iframe to be without triggering IE/FF/Chrome to create the browser's scroll bars.
	// do not change without testing on all three browsers.
	var wd = zenGetWindowWidth() - ((zenIsIE)?60:65);
	var ht = zenGetWindowHeight() - ((zenIsIE)?250:190);
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	zen("svgTabArea").setProperty("width",wd);
	zen("tabBar").setProperty("width",wd);
}

/// User clicked a column header to sort. Save that so we can come back to it when page is refreshed.
ClientMethod columnSort(currColumn, sortOrder) [ Language = javascript ]
{
	this.CurrentColumn = currColumn;
	this.CurrentSort = sortOrder;
	this.UpdateTableState(currColumn,sortOrder);
	var table = zen("table");
	table.currColumn = currColumn
	table.sortOrder = sortOrder
	table.parameters[0].value = this.PID;
	table.executeQuery();
}

ClientMethod doResume() [ Language = javascript ]
{
	if (this.CanBeSuspended == 1 || this.CanBeTerminated == 0) return;
	var ok = this.StartResume(this.PID);
	if (ok != 1) alert(ok);
	else this.updateView();
}

ClientMethod doSuspend() [ Language = javascript ]
{
	if (this.CanBeSuspended == 0) return;
	if (confirm($$$Text("Are you sure you want to suspend this process?"))==true) {
		var ok = this.StartSuspend(this.PID, this.DISPLAYID);
		if (ok != 1) alert(ok);
		else this.updateView();
	}
}

ClientMethod doTerminate() [ Language = javascript ]
{
	if (this.CanBeTerminated == 0) return;
	var parms = {
			PID:this.PID,
			DISPLAYID:this.DISPLAYID
	};	
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ProcessTerminate.zen','TerminateProc','status,scrollbars,resizable=yes,width=610,height=500',parms);
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	table.parameters[4].value = value;
	table.executeQuery();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	var option;
	for ( var i=0; i<2; i++ ) {
		option = i + 1;
		if ( i == index ) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}				
	}
}

/// On auto-refresh, or after Resume or Suspend, reload page with the current tab selected.
ClientMethod updateView() [ Language = javascript ]
{
	var tab = 1;
	for ( var i=1 ; i<3 ; i++ ) {
		if ( zen("page_"+i).getProperty("hidden") == false ) {
			tab = i;
			break;
		} 
	}
	var url = this.ProcessDetailsPage + "&tab=" + tab + "&SQL=" + (this.SQL ? 1 : 0);
	document.location = url;
}

/// When "SQL Operator Mode" is toggled, reload page
ClientMethod toggleSQL(value) [ Language = javascript ]
{
	this.SQL = (value ? 1 : 0);
	this.updateView();
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'TerminateProc':
		try {
			if (action == "ok") {
				document.location = this.ProcessesPage;	
			}
			break;
		} catch (ex) {
			alert("Error: " + ex);
		}
		break;
	}

	return true;
}

ClassMethod GetPIDOBJ(PID) As %String [ ZenMethod ]
{
	If '##class(SYS.Process).%ExistsId(PID) Quit $$$Text("Process no longer exists.")
	Set tPOBJ = ##class(SYS.Process).%OpenId(PID)
	Quit tPOBJ
}

ClassMethod StartResume(PID) As %String [ ZenMethod ]
{
	Set tPOBJ = ..GetPIDOBJ(PID)
	If '$IsObject(tPOBJ) Quit tPOBJ
	Set tSC = tPOBJ.Resume()
	If tSC '= 1 Quit $System.Status.GetErrorText(tSC)
	Quit 1
}

ClassMethod StartSuspend(PID, DISPLAYID) As %String [ ZenMethod ]
{
	Set tPOBJ = ..GetPIDOBJ(PID)
	If '$IsObject(tPOBJ) Quit tPOBJ
	If tPOBJ.CanBeSuspended = 0 {
		Quit $$$FormatText($$$Text("Process, %1, can not be suspended"),DISPLAYID)
	} Else {
		Set tSC = tPOBJ.Suspend()
		If tSC '= 1 Quit $System.Status.GetErrorText(tSC)
	}
	Quit 1
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
Method GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	
	Set tPane = ##class(%CSP.Util.HTMLDashboardPane).%New()
	Set tPane.Text = "" 
	Set tPane.MetricClass = "SYS.Metrics"
	Set tPane.MetricMethod = $select(..SQL: "GetSQLProcessMetrics", 1:"GetProcessMetrics")
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

	#; Second Group on right containing "Execution Details" and "Client Application Details" and they are aligned vertically
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

	#; Group 22: on the bottom "Client Application Details"
	Set tGroup22 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tGroup2.InsertMeter(tGroup22)
	Set tGroup22.Label=$$$Text("Client Application Details")
	Set tGroup22.Orientation = "vertical"
	Set tGroup22.Width = 450
	Set tGroup22.Style="Standard"

	#; *************** LOAD DETAILS TO GROUPS ************************ ;#
 
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Process ID"),"Pid",450,"",$$$Text("Process ID number for this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("User Name"),"UserName",450,"",$$$Text("Name of user currently logged in for this process.")))
  	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Login Roles"),"LoginRoles",450,"",$$$Text("Login roles for the process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Escalated Roles"),"EscalatedRoles",450,"",$$$Text("Additional roles granted to the process. These roles plus the Login Roles is the total set of roles granted to the process.")))
	Do tGroup11.InsertMeter(..BuildMeter($$$Text("OS User Name"),"OSUserName",450,"",$$$Text("Username given to the process by the operating system when the process is created.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("NameSpace"),"NameSpace",450,"",$$$Text("Namespace where the process is executing in.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Process Priority"),"Priority",450,"",$$$Text("Priority level of this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Global References"),"GlobalReferences",450,"",$$$Text("Number of global references made by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Private Global References"),"PrivateGlobalReferences",450,"",$$$Text("Number of private global references made by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Commands Executed"),"CommandsExecuted",450,"",$$$Text("Number of program commands executed by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Memory Limit"),"MemoryAllocated",450,"",$$$Text("Amount of memory (Kbytes) allocated for use by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Memory Peak"),"MemoryPeak",450,"",$$$Text("Amount of peak memory (Kbytes) allocated for use by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Memory Used"),"MemoryUsed",450,"",$$$Text("Amount of memory (Kbytes) currently in use by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Total CPU Time"),"CPUTime",450,"",$$$Text("System+User CPU Time (ms)")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Private Global Blocks"),"PrivateGlobalBlockCount",450,"",$$$Text("Number of private global data blocks used by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Current Device"),"CurrentDevice",450,"",$$$Text("List of I/O devices currently opened by this process.")))
  	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Open Devices"),"OpenDevices",450,"",$$$Text("List of I/O devices currently opened by this process.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Lock"),"Lock",450,"%25CSP.UI.Portal.Locks.zen",$$$Text("Shows lock information for this process: Mode, Counts, and Full Reference.")))

	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Process State"),"State",700,"",$$$Text("Current execution state of this process.")))
	Do tGroup21.InsertMeter(..BuildMeter($$$Text("In Transaction"),"InTransaction",700,"",$$$Text("Indicates whether this process is currently within a transaction.")))
	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Last Global Reference"),"LastGlobalReference",700,"",$$$Text("Last global referenced by this process.")))
	Do:(..SQL) tGroup21.InsertMeter(..BuildMeter($$$Text("Last SQL Table Reference"),"LastSQLReference",700,"",$$$Text("SQL Table(s) that correspond with the last global referenced by this process relative to the process current namespace.")))
	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Routine"),"Routine",700,"",$$$Text("Name of routine this process is currently executing.")))
	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Location"),"Location",700,"",$$$Text("....")))
	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Source Location"),"CurrentLineAndRoutine",700,"",$$$Text("Last reported source location (routine name plus offset) for this process.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Source Line"),"CurrentSrcLine",700,"",$$$Text("If available, last reported line of source code executed by this process.")))

 	Do tGroup22.InsertMeter(..BuildMeter($$$Text("Client Name"),"ClientNodeName",450,"",$$$Text("Node name of the client connected to this process or initiated the connection (if any).")))
 	Do tGroup22.InsertMeter(..BuildMeter($$$Text("EXE Name"),"ClientExecutableName",450,"",$$$Text("Name of executable client application connected to this process (if any).")))
 	Do tGroup22.InsertMeter(..BuildMeter($$$Text("Client IP Address"),"ClientIPAddress",450,"",$$$Text("IP address of executable client application connected to this process (if any).")))
 	Do tGroup22.InsertMeter(..BuildMeter($$$Text("Info"),"UserInfo",450,"",$$$Text("User defined information.")))

 Quit tPane
}

}
