/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Show recent activity for an External Language Server
Class %CSP.UI.Portal.ExternalLanguageServerActivities Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "External Language Server Activities";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ExternalLanguageServerActivities.zen";

Parameter HELPADDRESS = "Home,Configuration,External Language Servers,External Language Server Activity";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ExternalLanguageServers.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = {$$$AdminExternalLanguageServerEditResourceName};

/// ID for edit. DBName for this page.
Property PID As %String(ZENURL = "PID");

XData Style
{
<style type="text/css">
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<tableNavBar showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
queryClass="%Net.Remote.ActivityLog"
queryName="ByName"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
rowSelect="false"
>
<column colName="ID" header="ID"/>
<column colName="DateTime" header="Date Time"/>
<column colName="RecordType" header="Record Type"/>
<column colName="Job" header="Job"/>
<column colName="Text" header="Text"/>
<parameter value="#(%page.PID)#"/>
 </tablePane>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()

	Set ..lblTitle = $$$FormatText($$$Text("The log of recent activity on External Language Server %1 is shown below:"),%page.PID)

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("External Language Server Activity")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("External Language Servers","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

}
