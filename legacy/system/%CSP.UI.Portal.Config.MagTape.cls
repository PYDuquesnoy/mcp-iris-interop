/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Configure Devices
Class %CSP.UI.Portal.Config.MagTape Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.AdvancedEdit) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.MagTape.zen";

Parameter HELPADDRESS = "Home,Configuration,Device Settings,MagTapes,MagTape";

/// Displayed name of this page.
Parameter PAGENAME = "Magnetic Tape Device";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Config.MagTapes.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// ID for edit. Null if adding new device.
Property PID As %String(ZENURL = "PID");

Property Subject As %String [ InitialExpression = "MagTape" ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<vgroup id="idMagTape" labelPosition="left" cellStyle="padding:4px;" >
 <text id="Name" label="Name" size="50" hint="Required." onchange="zenPage.doModified();"/>
 <text id="SystemDevice" label="System Device" size="50" hint="Required. Physical tape device name." onchange="zenPage.doModified();"/>
 </vgroup>
</group>
</form>
</pane>
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	try {
		var pass = true;
		if (!this.validateRequired(zen("Name"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("SystemDevice"),pass,"S")) pass = false;
		return pass;
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod getProxy() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.Name = zen('Name').getValue();
		proxy.SystemDevice = zen('SystemDevice').getValue();
		return proxy;
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod GetPropertyArray(pProxy As %ZEN.proxyObject, Output Properties) As %Status
{
	Set Properties("SystemDevice") = pProxy.SystemDevice

	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..PID '= "" {
		Set ..lblTitle = $$$Text("Use the form below to edit a mag tape definition:")
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to create a new mag tape definition:")
	}

	If ..PID '= "" {
		Set tSC = ..PopulateFields()
		If $$$ISERR(tSC) Quit tSC
	}

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..PID '= "" {
		Quit $$$Text("Edit Mag Tape")
	} Else {
		Quit $$$Text("New Mag Tape")
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Magnetic Tape Devices")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list with parameters
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
