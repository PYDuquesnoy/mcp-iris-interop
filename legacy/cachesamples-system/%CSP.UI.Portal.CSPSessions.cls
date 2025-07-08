/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - Web Sessions 
Class %CSP.UI.Portal.CSPSessions Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.CSPSessions.zen";

Parameter HELPADDRESS = "Home,Web Sessions";

/// Displayed name of this page.
Parameter PAGENAME = "Web Sessions";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property msgEndSession As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to end the selected sessions?")} ];

Property msgDoneSession As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("If yes, then click [OK] and the selected sessions will be set to end and the Web license will be released in a few seconds.")} ];

Property FreespacePage As %String;

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
/* style used by Process Id link */
.linkStyle {
	color: #3b84bc;
	text-decoration: underline;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<tableNavBar showPageSize="true" tablePaneId="table" showMaxRows="true"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
queryClass="%CSP.Session"
queryName="SessionInfo"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="true"
showValueInTooltip="false"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
>
<column colName="ID" header="ID"/>
<column colName="Username" header="Username"/>
<column colName="Preserve" header="Preserve" style="text-align:left;"/>
<column colName="Application" header="Application"/>
<column colName="Timeout" header="Timeout (UTC)"/>
<column colName="LicenseId" header="License Id"/>
<column id="SesProcessId" colName="SesProcessId" header="Process Id" OnDrawCell="DrawProcessID"/>
<column colName="AllowEndSession" hidden="true"/>
<!-- if the following condition is met then checkbox will not be built so user cannot end session for that app -->
<condition colName="AllowEndSession" predicate="EQ" value="0" targetCol="checkbox" cellStyle="disabled"/> 

 </tablePane>
</pane>
}

Method DrawProcessID(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tProcessId = %query(pName)
	Set tHint = $$$TextHTML("Click to view process details")
	If (tProcessId '= "") {
		Write ("<span class=""linkStyle"" ")
		Write (" onclick=""zenPage.gotoPage('%25CSP.UI.Portal.ProcessDetails.zen?PID="_$ZCVT(tProcessId,"O","URL")_"&DISPLAYID="_$ZCVT(tProcessId,"O","URL")_"');"" ")
		Write (" title='"_tHint_"'>")
		Write (tProcessId_"</span>")
	} Else {
		Write ("&nbsp;")	
	}
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of the current Web sessions:")
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

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnEndSession",$$$Text("End Session"),$$$Text("End selected sessions"),"zenPage.doEndSession();")
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ##class(%CSP.UI.Portal.Utils).DrawAutoRefresh("CSPSessions")
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Web Sessions")
}

/// Disable checkboxes for applications that should not allow to be terminated.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
    // check if we should start auto-refresh
	if (this.enableAutoRefresh) {
		this.startRefresh();
	}
}

/// Based on user's choice, start or stop the timer.
ClientMethod startRefresh() [ Language = javascript ]
{
	var rfOn = self.document.getElementById('refreshOn');
	this.refreshMode = rfOn.checked;
	if (this.refreshMode) {
		var refreshRate = zenTrim(self.document.getElementById('refreshRate').value);
		// now convert it to milliseconds
		refreshRate = parseInt(refreshRate*1000);
		zen('refreshTimer').setProperty('timeout',refreshRate);
		zen('refreshTimer').startTimer();
	}
	else {
		zen('refreshTimer').clearTimer();
	}
}

/// Turn auto-refresh mode on and off.
ClientMethod setRefreshMode(newMode, notImmediate) [ Language = javascript ]
{
	var oldMode = this.refreshMode;
	this.refreshMode = newMode;
	var rfOn = self.document.getElementById('refreshOn');
	var rfOff = self.document.getElementById('refreshOff');
	rfOn.checked = newMode;
	rfOff.checked = !newMode;
	this.startRefresh();
	this.UpdateAutoRefreshState((newMode==true) ? 1 : 0);
	return oldMode;
}

/// User changed refresh rate. Check the value and save to server.
ClientMethod setRefreshRate(newRate) [ Language = javascript ]
{
	var refreshRate = zenTrim(newRate);
	if ((refreshRate == "") || (isNaN(refreshRate)==true) || (refreshRate < 5)) {
		// default to 10 seconds refresh interval if user enters invalid value
		refreshRate = 10;
		self.document.getElementById('refreshRate').value = refreshRate;
	} else {
		// save this rate to server
		this.UpdateAutoRefreshRate(refreshRate);	
	}
}

/// Table auto-refresh timer handler.
ClientMethod refreshHandler() [ Language = javascript ]
{
	if (this.enableAutoRefresh) {
		document.getElementById('id_refresh').style.backgroundColor = '#D0F8D0';
		this.updateView(true);
		zen('refreshTimer').startTimer();
		document.getElementById('id_refresh').style.backgroundColor = '';
	}
}

/// Update table.
ClientMethod updateView() [ Language = javascript ]
{
	window.location.reload();
}

ClientMethod doEndSession() [ Language = javascript ]
{
	var table = zen("table");
	var selectedRows = table.getProperty("selectedRows");
	var selected = "";
	var count = 0;
	var rows = selectedRows.split(",");
	for (var i=0; i<rows.length; i++) {
		if (rows[i]!="") {
			selected = selected + rows[i] + ",";	
			count++;
		}
	}
	if (selected == "") {
		alert($$$Text("No sessions selected.")+"\n\n"+$$$Text("(Sessions without checkboxes are not allowed to be ended.)"));
		return;
	} else {
		var msg = this.msgEndSession + "\n\n" + this.msgDoneSession;
		if (confirm(msg) == false) {
			return;
		}
	}
	var ok = this.EndSession(selected);
	if (ok != "") {
		alert(ok);
		return;	
	} else {
		this.updateView();
	}
}

/// Delete selected classes now.
ClassMethod EndSession(selectedRows) As %String [ ZenMethod ]
{
	Set tmsg = ""
	Set TotalSelected = 0
	Set tTotal = $L(selectedRows,",")
	For tItem = 1:1:tTotal {
		Set Pid = $P(selectedRows,",",tItem)
		If Pid '= "" {
			Set TotalSelected = TotalSelected + 1
			s tSC=$$DeleteSession^%SYS.cspServer(Pid)
			If $$$ISERR(tSC) {
				Set tmsg = tmsg _ $System.Status.GetErrorText(tSC)_"\n"
			} 
		}
	}
	If TotalSelected = 0 Quit $$$Text("No sessions selected.")
	Quit tmsg
}

/// Save auto refresh rate to server.
ClassMethod UpdateAutoRefreshRate(refreshrate As %Integer) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,"CSPSessions","AutoRefreshRate") = refreshrate
}

/// Save auto refresh state to server.
ClassMethod UpdateAutoRefreshState(refreshstate) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,"CSPSessions","AutoRefreshState") = refreshstate
}

}
