/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for IO Settings
Class %CSP.UI.Portal.Config.IO Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.Advanced) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.IO.zen";

Parameter HELPADDRESS = "Home,Configuration,Device Settings,IO Settings";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "IO Settings";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// Subject name for the setting page. 
Property Subject As %String [ InitialExpression = "IO" ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<text id="File" label="File" size="50" 
 hint="Required. Routine to use in WRITE commands for sequential files." 
  onchange="zenPage.doModified();"/>
<text id="MagTape" label="MagTape" size="50" 
 hint="Required. Routine to use in WRITE commands for magnetic tapes." 
  onchange="zenPage.doModified();"/>
<text id="Other" label="Other" size="50" 
 hint="Required. Routine to use in WRITE commands for other devices." 
  onchange="zenPage.doModified();"/>
<text id="Terminal" label="Terminal" size="50" 
hint="Required. Routine to use in WRITE commands for terminals." 
 onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

/// If any required field failed, the hint for the field will be turned to red. 
/// The first one failed should have focus.
ClientMethod validate() As %Boolean [ Language = javascript ]
{
	try {
		var pass = true;
		if (!this.validateRequired(zen("File"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("MagTape"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("Other"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("Terminal"),pass,"S")) pass = false;			
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
	
	Set ..lblTitle = $$$Text("Use the form below to edit IO settings for the system:")
	
	Set tSC = ..PopulateFields()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("IO Settings")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
