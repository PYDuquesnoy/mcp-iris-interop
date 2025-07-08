/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - External Language Servers
Class %CSP.UI.Portal.ExternalLanguageServers Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ExternalLanguageServers.zen";

/// Displayed name of this page.
Parameter PAGENAME = "External Language Servers";

Parameter HELPADDRESS = "System Administration, Configuration, Connectivity, External Language Servers";

/// Security requirement
Parameter RESOURCE = {$$$AdminExternalLanguageServerEditResourceName};

/// $J of the background job number. Used to check whether the backjob is finished. When it is finished we stop the javascript timer.
Property JobNumber As %Integer;

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
	border-bottom: 1px solid #F1F0E7;
}
.inact { color: #909090; }
.dot {
	height: 2px;
	width: 2px;
	background-color: #bbb;
	border-radius: 50%;
	display: inline-block;
	padding: 2px;
}
.greendot {
  background-color: green;
}
.blackdot {
  background-color: #404040;
}
.reddot {
  background-color: red;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<timer id="checkStatusTimer" timeout="200" ontimeout="zenPage.checkStatus();" />

<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>

<vgroup valign="top">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
saveSizeMax="true" 
onPageSizeChange="zenPage.navPageSizeChanged(value);"
onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
title="Enter a string to filter the list"
/>
<tablePane id="table"
queryClass="Config.Gateways"
queryName="ListShort"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
useSnapshot="true"
>
<column colName="Name" id="NameCol" OnDrawCell="DrawName"/>
<column colName="Type" />
<column colName="Port" />
<column linkCaption="Activity Log" link="javascript:zenPage.doActivities('#(%query.Name)#');" />
<column linkCaption="Start" OnDrawCell="DrawStart"/>
<column linkCaption="Stop" OnDrawCell="DrawStop"/>
<column linkCaption="Status" OnDrawCell="DrawDots"/>
<column linkCaption="Delete" OnDrawCell="DrawDelete"/>

<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<parameter value=""/>
<parameter value="0"/>
 </tablePane>
 </vgroup>
 <label id="idRespond" controlClass="greennote" value=""/>
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
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("List of currently defined External Language Server definitions")_":"
	// The default filter in the page we inherit from is initially set to "*". This screws up the new filtering system.
	Set:..Filter="*" ..Filter=""
	// Start the background job that checks for each server status
	Quit ..UpdateServerStatuses()
}

Method UpdateServerStatuses() As %Status [ ZenMethod ]
{
	// Start the background job that checks for each server status
	Set tParms("Username") = $Username
	Set tParms("Filter") = ..Filter
	Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("ExternalLangServers",$namespace,.tParms,.tItems,.tJob)
	If $$$ISERR(tSC) Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(tSC))
	Set (..JobNumber,$$$TempMgtPortalTask("ExternalLangServers",$Username)) = tJob
	Quit $$$OK
}

/// Update / Reload table. Subclass may override this method. Do not modify this method unless you are going to take care of all pages that use it.
ClientMethod updateView() [ Language = javascript ]
{
	zen('table').executeQuery();
	var x = zenPage.UpdateServerStatuses();
	zen('checkStatusTimer').startTimer();
	this.updateTime();
}

Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	
	// commands: $LB(id,caption,help,onclick)
	Set caption = $$$Text("Create New External Language Server")
	Set pCommands(1) = $LB("btnNew",$$$Text("Create External Language Server"),$$$Text("Create a new External Language Server"),"zenPage.doNew();")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("External Language Servers")
}

/// User clicked Start link. Goto to Start page.
ClientMethod doNew() [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.ExternalLanguageServer.zen';
	zenPage.gotoPage(url);
}

/// User clicked the "Edit" link.
ClientMethod doEdit(Name, editable) [ Language = javascript ]
{
	this.endTimer();
	var url='%25CSP.UI.Portal.ExternalLanguageServer.zen?PID='+Name+"&IsEditForm="+editable;
	zenPage.gotoPage(url);
}

/// User clicked Activities link. Goto to Activities page.
ClientMethod doActivities(PID) [ Language = javascript ]
{
	this.gotoPage("%25CSP.UI.Portal.ExternalLanguageServerActivities.zen?PID="+encodeURIComponent(PID));
}

/// User clicked Start link. Goto to Start page.
ClientMethod doStart(PID) [ Language = javascript ]
{
	this.endTimer();
	this.gotoPage("%25CSP.UI.Portal.ExternalLanguageServerStart.zen?PID="+PID);
}

/// User clicked Stop link. Goto to Stop page.
/// 
/// PID         : the name of the external language server
/// softTimeout : optional soft shutdown timeout in seconds
ClientMethod doStop(PID, softTimeout) [ Language = javascript ]
{
	this.endTimer();
	var optTimeout = (softTimeout!=0 ? "&soft="+encodeURIComponent(softTimeout) : "")
	this.gotoPage("%25CSP.UI.Portal.ExternalLanguageServerStop.zen?PID="+PID+optTimeout);
}

/// Delete existing gateway connection.
ClientMethod doDelete(Name) [ Language = javascript ]
{
	try {
		this.endTimer();
		var ok = this.DeleteItem(decodeURIComponent(Name));
		if (ok == 1) {
			var table = zenPage.getComponentById('table');
			table.setProperty("selectedIndex",-1);
			table.executeQuery();
		} else {
			alert(ok);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod endTimer() [ Language = javascript ]
{
	zen('checkStatusTimer').clearTimer();
	this.JobNumber = "";
}

/// Call server delete method.
ClassMethod DeleteItem(Name) As %String [ ZenMethod ]
{
	Set $ZT="Error"
	Set tSC = ##class(Config.Gateways).Delete(Name)
	If $$$ISERR(tSC) {
		Set ok = $System.Status.GetErrorText(tSC)
	} Else {
		Set ok = 1
	}
	Quit ok
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","JS")
}

Method DrawName(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If $G(%query("Name")) '= "" {
		Set tJob = 1
		If $G($$$TempMgtPortalTask("ExternalLangServers",$Username)) '= "" Set tJob = $$$TempMgtPortalTask("ExternalLangServers",$Username)
		Set tStatus = $G($$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name")))
		Set editable = (tStatus '= 1) || (%query("Type") = "Remote")
		// doEdit() needs to URL encode the value anyway; we encode it here so that the value doesn't get mangled in the link. 
		// use "URI" encoding instead of "URL" because "URI" will also encode quotes. 
		Set urlName = $zconvert(%query("Name"),"O","URI")
		Set htmlName = $$$HTMLENCODE(%query("Name"))
		&html<<a style="white-space:nowrap;" href="#" onclick="javascript:zenPage.doEdit('#(urlName)#',#(editable)#);">#(htmlName)#</a>>
	}
	Quit $$$OK
}

/// Check to see if the server is running. Show link if it is not.
Method DrawStart(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If $G(%query("Name")) '= "" {
		Set tJob = 1
		If $G($$$TempMgtPortalTask("ExternalLangServers",$Username)) '= "" Set tJob = $$$TempMgtPortalTask("ExternalLangServers",$Username)
		Set txtStart = ..EscapeHTML("Start")
		Set sc = ##class(%Net.Remote.Service).OpenGateway(%query("Name"), .pGateway)
		Quit:$$$ISERR(sc) sc
		If pGateway.Type="ML", '##class(%Net.Remote.Service).IntegratedMLJARInstalled() {
			&html<<span class="inact" title="Cannot start because IntegratedML is not installed">#(txtStart)#</span>>
		} ElseIf $G($$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name"))) '= 1 {	
			Set txtMsg = $$$HTMLENCODE($$$FormatTextJS("Are you sure you want to start Server '%1'?", %query("Name")))
			Set txtName = $zconvert(%query("Name"),"O","URI")
			If %query("Type") '= "Remote" {
				&html<<a style="white-space:nowrap;" href="#" title='#(txtStart)#' onclick="zen('table').launchConfirmDialog('%ZEN.Dialog.confirmationDialog.cls','confirmationDialog','resizable,width=540,height=200',{Msg1:'#(txtMsg)#',Title:'#(txtStart)#',Link:'zenPage.doStart(\&#39;#(txtName)#\&#39;);'}); return false;">#(txtStart)#</a></td>>
			} Else {
				&html<<span class="inact">#(txtStart)#</span>>
			}	
		} Else {
			&html<<span class="inact">#(txtStart)#</span>>	
		}
	}
	Quit $$$OK
}

/// Check to see if the server is running. Show link if it is not.
Method DrawStop(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If $G(%query("Name")) '= "" {
		Set tJob = 1
		If $G($$$TempMgtPortalTask("ExternalLangServers",$Username)) '= "" Set tJob = $$$TempMgtPortalTask("ExternalLangServers",$Username)
		Set tStatus = $G($$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name")))
		Set txtStop = ..EscapeHTML("Stop")
		If (tStatus = 1) || (tStatus = ""){
			Set txtMsg = $$$HTMLENCODE($$$FormatTextJS("Are you sure you want to stop Server '%1'?", %query("Name")))
			Set txtName = $zconvert(%query("Name"),"O","URI")
			&html<<a style="white-space:nowrap;" href="#" title='#(txtStop)#' onclick="zen('table').launchConfirmDialog('%CSP.UI.Portal.Dialog.ExternalLanguageServerStopDialog.cls','confirmationDialog','resizable,width=540,height=200',{Msg1:'#(txtMsg)#',Title:'#(txtStop)#',Link:'zenPage.doStop(\&#39;#(txtName)#\&#39;,0);'}); return false;">#(txtStop)#</a></td>>
		} Else {
			&html<<span class="inact">#(..EscapeHTML("Stop"))#</span>>
		}
	}
	Quit $$$OK
}

/// Check to see if the server is running. Show link if it is not.
Method DrawDelete(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If $G(%query("Name")) '= "" {
		Set tJob = 1
		If $G($$$TempMgtPortalTask("ExternalLangServers",$Username)) '= "" Set tJob = $$$TempMgtPortalTask("ExternalLangServers",$Username)
		Set tStatus = $G($$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name")))
		Set txtDelete = ..EscapeHTML("Delete")
		If (tStatus '= 1) || (%query("Type") = "Remote") {
			Set txtMsg = $$$HTMLENCODE($$$FormatTextJS("Are you sure you want to delete Server '%1'?", %query("Name")))
			Set txtName = $zconvert(%query("Name"),"O","URI")
			&html<<a style="white-space:nowrap;" href="#" title='#(txtDelete)#' onclick="zen('table').launchConfirmDialog('%ZEN.Dialog.confirmationDialog.cls','confirmationDialog','resizable,width=540,height=200',{Msg1:'#(txtMsg)#',Title:'#(txtDelete)#',Link:'zenPage.doDelete(\&#39;#(txtName)#\&#39;);'}); return false;">#(txtDelete)#</a></td>>
		} Else {
			&html<<span class="inact">#(txtDelete)#</span>>	
		}
	}
	Quit $$$OK
}

/// During the time a server's status is being checked, we draw gray and green dots with the green dot moving from left to right and repeat.
/// When the server is inactive, we draw all black dots.
/// When the server is active, we draw all green dots.
/// When unexpected error occure to the background job, we draw a red dot at the end.
/// During any other times, for example when the page is loading before the background job is started all dots are gray.
Method DrawDots(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If $G(%query("Name")) '= "" {
		Set tJob = 1
		If $G($$$TempMgtPortalTask("ExternalLangServers",$Username)) '= "" Set tJob = $$$TempMgtPortalTask("ExternalLangServers",$Username)
		Set tStatus = $G($$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name")))
		Set tGreen = "<span class='dot greendot'></span>&nbsp;"
		Set tGray = "<span class='dot'></span>&nbsp;"
		If $G($$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name"),"Checking")) '= "" {
			Set tCnt = $$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name"),"Checking")
			Set $$$TempMgtPortalTask("ExternalLangServers",tJob,%query("Name"),"Checking") = tCnt + 1
			// When checking server status is running, display moving green dot
			If tCnt#3 = 1 Write tGreen,tGray,tGray
			If tCnt#3 = 2 Write tGray,tGreen,tGray
			If tCnt#3 = 0 Write tGray,tGray,tGreen
		} ElseIf (tStatus = 1) {
			// If server is active, display green dots
			For i=1:1:3 Write tGreen
		} ElseIf tStatus = "" {
			// Before each server's status is checked, display gray dots
			For i=1:1:3 Write tGray
			
		} Else {
			// If server is not active, display black dots
			For i=1:1:3 Write "<span class='dot blackdot'></span>&nbsp;"
		}
		
	}
	// If the background job encounted error for any reason, display a reddot. Check Operations/Background Tasks to see details
	If $G($$$TempMgtPortalTask(tJob,"Status")) = $$$Text("ERROR") {
		Write "<span class='dot reddot'></span>&nbsp;"
	}
	Quit $$$OK
}

/// Timeout Method used by the checkStatusTimer
ClientMethod checkStatus() [ Language = javascript ]
{
	if (zen('checkStatusTimer').timer == 0) {
		return;	
	}
	var string = "";
	var status = zenPage.CheckServerStatus(this.JobNumber);
	if (status == 2) {
		//Error occurred - a red dot will appear
		zen('checkStatusTimer').clearTimer();
	} else if (status == 0) {
		zen('checkStatusTimer').startTimer();	
	} else {
		zen('checkStatusTimer').clearTimer();
	}
	var table = zen("table");
	table.refreshTable();
}

/// Return whether the background job of status checking is done.
Method CheckServerStatus(pJob) As %Boolean [ ZenMethod ]
{
	Set tStatus = $G($$$TempMgtPortalTask(pJob,"Status"))
	If tStatus = $$$Text("Done") Quit 1
	If tStatus = $$$Text("ERROR") Quit 2
	Quit 0
}

}
