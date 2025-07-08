/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// System Management Portal - System Operations - Top 5 Transactions and ECPTransactions
Class %CSP.UI.Portal.Transactions Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Transactions.zen";

Parameter HELPADDRESS = "Home,Transactions";

/// Displayed name of this page.
Parameter PAGENAME = "Transactions";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property CurrentColumn As %ZEN.Datatype.string [ InitialExpression = "Pid" ];

Property DashboardPage As %ZEN.Datatype.caption [ InitialExpression = {..Link("UtilDashboard.csp")} ];

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
<html id="htmlTable" OnDrawContent="DrawHTML"/>
</pane>
}

ClientMethod doDashboard() [ Language = javascript ]
{
	document.location = this.DashboardPage;
}

/// Update / Reload table. This overrides the one in Portal.Utils.
ClientMethod updateView() [ Language = javascript ]
{
	try {
		var html = zen("htmlTable");
		html.refreshContents();
		this.updateTime();
	} catch (ex) {
		alert("Error: " + ex);
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	$$$SetRefreshTimer
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
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$zconvert(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	
	Set pCommands(1) = $LB("btnDashboard",$$$Text("System Dashboard"),$$$Text("Return to System Dashboard"),"zenPage.doDashboard();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Transactions")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

Method DrawHTML(pSeed As %String) As %Status
{
	Set tProc = $$$TextHTML("Process ID")
	Set tSecs = $$$TextHTML("Seconds")
	#; add link to PID so we can jump to look at the process details.
	Set tProcLink = ..Link("%25CSP.UI.Portal.ProcessDetails.zen",,1)_"PID="
	Set tHelp = $$$Text("click to view process details.")
	
	#; check if System monitor is running
	Set tSysMon = (##class(SYS.Metrics).SystemMonitorStatus() = "OK")
	#; Display table for Local Transactions
	If 'tSysMon {
		Set tStatus = $$$Text("Current local transaction status: Unknown")
		&html<<h3>#(tStatus)#</h3>>
		Set tMsg = $$$TextHTML("Transaction data not available because System Monitor is not running.")
		&html<<h5 style="color:red;" >#(tMsg)#</h5>>
	} 
	Else {
		Set tTran = $Case($G(^IRIS.Temp.SysMetrics("Transactions")),"OK":$$$TextHTML("Normal"),"Warning":$$$TextHTML("Warning"),:$$$TextHTML("Troubled"))
		Set tStatus = $$$FormatText($$$Text("Current local transaction status: %1"),tTran)
		Set tRow = $O(^IRIS.Temp.SysMetrics("Transactions",""))
		Set tTitle = $S(tRow'="":$$$TextHTML("The following table will show up to five top local transactions:"),1:$$$TextHTML("There are no open local transactions."))
		&html<<h3>#(tStatus)#</h3>>
		&html<<div class="zendiv" id="Text1" style="padding-bottom:4px;">
		<span class="labelText" >#(tTitle)#</span></div>>
		If tRow '= "" {
			&html<<table class="tpTable"><tr><th>#(tProc)#</th><th>#(tSecs)#</th></tr>>
			While tRow '= "" {
				Set tPid = $G(^IRIS.Temp.SysMetrics("Transactions",tRow,"pid"),"&nbsp;")
				Set tSec = $G(^IRIS.Temp.SysMetrics("Transactions",tRow,"secs"),"&nbsp;")
				Set tLinkPid = $S(tPid'="&nbsp;":$zconvert(tPid,"O","URL"),1:tPid)
				Set tLink = tProcLink_tPid_"&DISPLAYID="_tLinkPid_"&$ID1="_tLinkPid
				&html<<tr><td><a href="#(tLink)#" title="#(tHelp)#">#($S(tPid'="&nbsp;":$zconvert(tPid,"O","HTML"),1:tPid))#</a></td><td>#(tSec)#</td></tr>>
				Set tRow = $O(^IRIS.Temp.SysMetrics("Transactions",tRow))
			}
			&html<</table>>
		}
	}
	#; Display table for Remote Transactions
	If 'tSysMon {
		Set tStatus = $$$Text("Current remote transaction status: Unknown")
		&html<<h3>#(tStatus)#</h3>>
		Set tMsg = $$$TextHTML("Transaction data not available because System Monitor is not running.")
		&html<<h5 style="color:red;" >#(tMsg)#</h5>>
	} 
	Else {
		Set tTran = $Case($G(^IRIS.Temp.SysMetrics("ECPTransactions")),"OK":$$$TextHTML("Normal"),"Warning":$$$TextHTML("Warning"),:$$$TextHTML("Troubled"))
		Set tStatus = $$$FormatText($$$Text("Current remote transaction status: %1"),tTran)
		Set tRow = $O(^IRIS.Temp.SysMetrics("ECPTransactions",""))
		Set tTitle = $S(tRow'="":$$$TextHTML("The following table will show up to five top remote transactions:"),1:$$$TextHTML("There are no open remote transactions."))
		&html<<h3>#(tStatus)#</h3>>
		&html<<div class="zendiv" id="Text1" style="padding-bottom:4px;">
		<span class="labelText" >#(tTitle)#</span></div>>
		If tRow '= "" {
			&html<<table class="tpTable"><tr><th>#(tProc)#</th><th>#(tSecs)#</th></tr>>
			While tRow '= "" {
				Set tPid = $G(^IRIS.Temp.SysMetrics("ECPTransactions",tRow,"pid"))
				Set tSec = $G(^IRIS.Temp.SysMetrics("ECPTransactions",tRow,"secs"),"&nbsp;")
				&html<<tr><td nowrap>#($S(tPid'="":..EscapeHTML(tPid),1:"&nbsp;"))#</td><td>#(tSec)#</td></tr>>
				Set tRow = $O(^IRIS.Temp.SysMetrics("ECPTransactions",tRow))
			}
			&html<</table>>
		}
	}
	Quit 1
}

}
