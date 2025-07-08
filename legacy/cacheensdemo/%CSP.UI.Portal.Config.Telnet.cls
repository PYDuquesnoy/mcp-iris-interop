/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for Telnet Settings
Class %CSP.UI.Portal.Config.Telnet Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.Advanced) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.Telnet.zen";

Parameter HELPADDRESS = "Home,Configuration,Device Settings,Telnet Settings";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "Telnet Settings";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// Subject name for the setting page. 
Property Subject As %String [ InitialExpression = "Telnet" ];

Property isWINDOWS As %Boolean [ InitialExpression = {$$$isWINDOWS} ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<select id="DNSLookup" label="DNS Lookup" valueList="ON,OFF" displayList="ON,OFF"
hintClass="helpText" showEmpty="false" 
 onchange="zenPage.doModified();"/>
<text id="Port" label="Telnet Port Number" size="5" 
hint="Required. " 
 onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (!this.isWINDOWS) {
		zen("fld").setProperty("disabled",true);
		this.disableCommandButton("btnSave");
	}
}

/// If any required field failed, the hint for the field will be turned to red. 
/// The first one failed should have focus.
ClientMethod validate() As %Boolean [ Language = javascript ]
{
	try {
		var pass = true;
		if (!this.validateRequired(zen("Port"),pass,"S")) pass = false;
		return pass;
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Subclass can override.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("Use the form below to edit the telnet settings for the system: (these settings are for Windows operating system only)")
	
	Set tSC = ..PopulateFields()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Telnet Settings")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
