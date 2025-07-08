/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Configure Devices
Class %CSP.UI.Portal.Config.SubType Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.AdvancedEdit) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.SubType.zen";

Parameter HELPADDRESS = "Home,Configuration,Device Settings,SubTypes,SubType";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "Device";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Config.SubTypes.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// ID for edit. Null if adding new device.
Property PID As %String(ZENURL = "PID");

Property Subject As %String [ InitialExpression = "SubType" ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<vgroup id="idSubType" labelPosition="left"  cellStyle="padding:4px;" >
 <text id="Name" label="Name" size="50" hint="Required." onchange="zenPage.doModified();"/>
 <text id="ScreenLength" label="Screen Length" size="5" value="0" hint="Required. Enter the number of lines that comprise one screen or page for the device." onchange="zenPage.doModified();"/>
 <text id="RightMargin" label="Right Margin" size="5" value="80" onchange="zenPage.doModified();"/>
 <text id="Backspace" label="Backspace" size="50" onchange="zenPage.doModified();"/>
 <text id="CursorControl" label="Cursor Control" size="50" onchange="zenPage.doModified();"/>
 <text id="EraseEOF" label="EraseEOF" size="50" onchange="zenPage.doModified();"/>
 <text id="EraseEOL" label="EraseEOL" size="50" onchange="zenPage.doModified();"/>
 <text id="FormFeed" label="FormFeed" size="50" onchange="zenPage.doModified();"/>
 <text id="ZU22Backspace" label="ZU22Backspace" size="50" onchange="zenPage.doModified();"/>
 <text id="ZU22FormFeed" label="ZU22FormFeed" size="50" onchange="zenPage.doModified();"/>
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
		if (!this.validateRequired(zen("ScreenLength"),pass,"N")) pass = false;
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
		proxy.ScreenLength = zen('ScreenLength').getValue();
		proxy.RightMargin = zen('RightMargin').getValue();
		proxy.Backspace = zen('Backspace').getValue();
		proxy.CursorControl = zen('CursorControl').getValue();
		proxy.EraseEOF = zen('EraseEOF').getValue();
		proxy.EraseEOL = zen('EraseEOL').getValue();
		proxy.FormFeed = zen('FormFeed').getValue();
		proxy.ZU22Backspace = zen('ZU22Backspace').getValue();
		proxy.ZU22FormFeed = zen('ZU22FormFeed').getValue();
		return proxy;
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod GetPropertyArray(pProxy As %ZEN.proxyObject, Output Properties) As %Status
{
	Set Properties("ScreenLength") = pProxy.ScreenLength
	Set Properties("RightMargin") = pProxy.RightMargin
	Set Properties("Backspace") = pProxy.Backspace
	Set Properties("CursorControl") = pProxy.CursorControl
	Set Properties("EraseEOF") = pProxy.EraseEOF
	Set Properties("EraseEOL") = pProxy.EraseEOL
	Set Properties("FormFeed") = pProxy.FormFeed
	Set Properties("ZU22Backspace") = pProxy.ZU22Backspace
	Set Properties("ZU22FormFeed") = pProxy.ZU22FormFeed
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..PID '= "" {
		Set ..lblTitle = $$$Text("Use the form below to edit a sub type definition:")
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to create a new sub type definition:")
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
		Quit $$$Text("Edit Sub Type")
	} Else {
		Quit $$$Text("New Sub Type")
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

	Set tPageName = $$$Text("Device Subtypes")
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
