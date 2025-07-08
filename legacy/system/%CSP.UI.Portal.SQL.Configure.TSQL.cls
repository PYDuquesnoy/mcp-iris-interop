/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// TSQL Settings
Class %CSP.UI.Portal.SQL.Configure.TSQL Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "TSQL Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.SQL.Configure.TSQL.zen";

Parameter HELPADDRESS = "System,Configuration,TSQL Compatibility Settings";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:6px;" labelPosition="left">
<spacer height="2"/>
 <select id="DIALECT" label="DIALECT" valueList="MSSQL,Sybase" showEmpty="false" hint="Select the Transact-SQL dialect" onchange="zenPage.doModified();"/> 
 <select id="ANSI_NULLS" label="ANSI_NULLS" valueList="OFF,ON" showEmpty="false" hint="Specifies whether comparisons to a null value return true or false" onchange="zenPage.doModified();"/> 
 <select id="CASEINSCOMPARE" label="CASEINSCOMPARE" valueList="OFF,ON" showEmpty="false" hint="Specifies non-case-sensitive equality comparisons" onchange="zenPage.doModified();"/> 
 <select id="QUOTED_IDENTIFIER" label="QUOTED_IDENTIFIER" valueList="OFF,ON" showEmpty="false" hint="Select whether quoted identifiers are supported" onchange="zenPage.doModified();"/> 
<spacer height="2"/>
</group>
 </form>
</pane>
}

/// User clicked Save. Save and return to parent page.
ClientMethod doSave() [ Language = javascript ]
{
	var DIALECT = zen("DIALECT").getValue()
	var ANSINULLS = zen("ANSI_NULLS").getValue();
	var CASEINSCOMPARE = zen("CASEINSCOMPARE").getValue();
	var QUOTEDIDENTIFIER = zen("QUOTED_IDENTIFIER").getValue();	
	var result = this.SaveData(DIALECT,ANSINULLS,CASEINSCOMPARE,QUOTEDIDENTIFIER);
	this.afterSave(result);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("DIALECT").focus();
}

/// Save file into global.
ClassMethod SaveData(DIALECT, ANSINULLS, CASEINSCOMPARE, QUOTEDIDENTIFIER) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set ^%SYS("tsql","DIALECT") = DIALECT
	Set ^%SYS("tsql","SET","ANSI_NULLS") = ANSINULLS
	Set ^%SYS("tsql","SET","CASEINSCOMPARE") = CASEINSCOMPARE
	Set ^%SYS("tsql","SET","QUOTED_IDENTIFIER") = QUOTEDIDENTIFIER
	Set tProxy.ok = 1
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("Use the form below to view or edit the settings that define the behavior of InterSystems TSQL compatibility features:")
		
	Set ..%GetComponentById("DIALECT").value = $S($G(^%SYS("tsql","DIALECT"))'="":^("DIALECT"),1:"Sybase")
	Set ..%GetComponentById("ANSI_NULLS").value = $S($G(^%SYS("tsql","SET","ANSI_NULLS"))'="":^("ANSI_NULLS"),1:"OFF")
	Set ..%GetComponentById("CASEINSCOMPARE").value = $S($G(^%SYS("tsql","SET","CASEINSCOMPARE"))'="":^("CASEINSCOMPARE"),1:"OFF")
	Set ..%GetComponentById("QUOTED_IDENTIFIER").value = $S($G(^%SYS("tsql","SET","QUOTED_IDENTIFIER"))'="":^("QUOTED_IDENTIFIER"),1:"OFF")
	Quit 1
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save settings"),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return to Home page without save"),"zenPage.doCancel();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("TSQL Settings")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
