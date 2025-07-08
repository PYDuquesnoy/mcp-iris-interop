/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// Informix SQL Settings
Class %CSP.UI.Portal.SQL.Configure.ISQL Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Informix SQL Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.SQL.Configure.ISQL.zen";

Parameter HELPADDRESS = "Home,Configuration,ISQL Compatibility Settings";

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
 <checkbox id="DELIMIDENT" label="Support Delimited Identifiers" value="0" onchange="zenPage.doModified();"/> 
 <checkbox id="TRACE" label="Generate Trace Code" value="0" onchange="zenPage.doModified();"/>  
 <checkbox id="FUNCTIONRETURNSSET" label="Return Result of Stored Procedure Call as Resultset" value="1" onchange="zenPage.doModified();"/> 
 <text id="RESERVEDWORDPREFIX" label="Reserved Word Prefix" hint="Prefix entered here will be added to column names that are reserved words." onchange="zenPage.doModified();"/>
 <spacer height="2"/>
 </group>
 </form>
</pane>
}

/// User clicked Save. Save and return to parent page.
ClientMethod doSave() [ Language = javascript ]
{
	var DELIMIDENT = zen("DELIMIDENT").getValue() ? 1 : 0;
	var TRACE = zen("TRACE").getValue() ? 1 : 0;
	var FUNCTIONRETURNSSET = zen("FUNCTIONRETURNSSET").getValue() ? 1 : 0;
	var RESERVEDWORDPREFIX = zen("RESERVEDWORDPREFIX").getValue();
	var result = this.SaveData(DELIMIDENT,TRACE,FUNCTIONRETURNSSET,RESERVEDWORDPREFIX);
	this.afterSave(result);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("DELIMIDENT").focus();
}

/// Save file into global.
ClassMethod SaveData(DELIMIDENT, TRACE, FUNCTIONRETURNSSET, RESERVEDWORDPREFIX) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set ^%SYS("xsql","informix","DELIMIDENT") = DELIMIDENT
	Set ^%SYS("xsql","informix","TRACE") = TRACE
	Set ^%SYS("xsql","informix","FUNCTIONRETURNSSET") = FUNCTIONRETURNSSET
	Set ^%SYS("xsql","informix","RESERVEDWORDPREFIX") = RESERVEDWORDPREFIX
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

	Set ..lblTitle = $$$Text("Use the form below to view or edit the settings that define the behavior of InterSystems ISQL compatibility features:")
	For tProperty="DELIMIDENT","RESERVEDWORDPREFIX","TRACE","FUNCTIONRETURNSSET" {
		If $G(^%SYS("xsql","informix",tProperty)) '= "" Set ..%GetComponentById(tProperty).value = ^(tProperty)
	}
				
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Informix SQL Settings")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
