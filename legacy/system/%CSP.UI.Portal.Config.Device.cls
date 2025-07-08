/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Configure Devices
Class %CSP.UI.Portal.Config.Device Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.AdvancedEdit) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.Device.zen";

Parameter HELPADDRESS = "Home,Configuration,Device Settings,Devices";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "Device";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Config.Devices.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// ID for edit. Null if adding new device.
Property PID As %String(ZENURL = "PID");

Property Subject As %String [ InitialExpression = "Device" ];

XData Style
{
<style type="text/css">
.EditForm { width:600px; }
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<vgroup id="idDevice" labelPosition="left" cellStyle="padding:4px;" >
<text id="Name" label="Name" size="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="PhysicalDevice" label="Physical Device Name" size="50" hint="Required." onchange="zenPage.doModified();"/>
<select id="Type" label="Type" 
displayList="Terminal,Spooling device,Magnetic tape drive,Cartridge tape drive,Interprocess Communication,Other" 
valueList="TRM,SPL,MT,BT,IPC,OTH" hint="Required." showEmpty="false"
 onchange="zenPage.doModified();" value="OTH" originalValue="OTH"/>
<select id="SubType" label="Sub-Type" hint="Required." valueList="" originalValue="P-DEC" value="P-DEC" showEmpty="false" onchange="zenPage.doModified();"/>
<text id="OpenParameters" label="Open Parameters" size="50" onchange="zenPage.doModified();"/>
<text id="Description" label="Description" size="50" onchange="zenPage.doModified();"/>
<text id="Alias" label="Alias" size="50" onchange="zenPage.doModified();"/>
<text id="AlternateDevice" label="Alternate Device" size="50" onchange="zenPage.doModified();"/>
<radioSet id="Prompt" label="Prompt" width="30" 
displayList="Show device prompt,Auto-use this device if it is the current device,Auto-use this device with predefined settings" 
valueList=",1,2"
 onchange="zenPage.doModified();"/>
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
		if (!this.validateRequired(zen("PhysicalDevice"),pass,"S")) pass = false;
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
		proxy.PhysicalDevice = zen('PhysicalDevice').getValue();
		proxy.Type = zen('Type').getValue();
		proxy.SubType = zen('SubType').getValue();
		proxy.OpenParameters = zen('OpenParameters').getValue();
		proxy.Description = zen('Description').getValue();
		proxy.Alias = zen('Alias').getValue();
		proxy.AlternateDevice = zen('AlternateDevice').getValue();
		proxy.Prompt = zen('Prompt').getValue();
		return proxy;
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod GetPropertyArray(pProxy As %ZEN.proxyObject, Output Properties) As %Status
{
	Set Properties("PhysicalDevice") = pProxy.PhysicalDevice
	Set Properties("Type") = pProxy.Type
	Set Properties("SubType") = pProxy.SubType
	Set Properties("OpenParameters") = pProxy.OpenParameters
	Set Properties("Description") = pProxy.Description
	Set Properties("Alias") = pProxy.Alias
	Set Properties("AlternateDevice") = pProxy.AlternateDevice
	Set Properties("Prompt") = pProxy.Prompt
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..PID '= "" {
		Set ..lblTitle = $$$Text("Use the form below to edit a device definition:")
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to create a new device definition:")
	}

	If ..PID '= "" {
		Set tSC = ..PopulateFields()
		If $$$ISERR(tSC) Quit tSC
	}
	
	Set tRS = ##class(%ResultSet).%New("Config.DeviceSubTypes:List")
	Do tRS.Execute("*","",0,0)
	Set tValueList = ""
	For  Quit:'tRS.Next()  Set tValueList = tValueList_tRS.GetData(1)_","
	Set ..%GetComponentById("SubType").valueList = $E(tValueList,1,$L(tValueList)-1)

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..PID '= "" {
		Quit $$$Text("Edit Device")
	} Else {
		Quit $$$Text("New Device")
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

	Set tPageName = $$$Text("Devices")
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
