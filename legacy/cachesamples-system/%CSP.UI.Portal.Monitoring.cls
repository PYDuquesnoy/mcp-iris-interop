/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Monitoring Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Monitor Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Monitoring.zen";

Parameter HELPADDRESS = "Home,Configuration,Monitor Settings";

Parameter EMSSERVICE = "Config";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property DialogLink As %String [ InitialExpression = {..Link("/csp/sys/sec/%CSP.UI.Portal.Dialog.Service.zen",,1)} ];

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<link id="ServiceStatus" caption="" href="#" onclick="zenPage.doService();return false;" enclosingClass="smpLink"/>
<checkbox id="SNMPEnabled" label="Start SNMP Agent at System Startup" onchange="zenPage.doModified();"/>
<checkbox id="OTELMetrics" label="Enable OTel Metrics" onchange="zenPage.doModified();"/>
<checkbox id="OTELLogs" label="Enable OTel Logs" onchange="zenPage.doModified();"/>
<text id="OTELInterval" label="OTel Exporter Interval" size="8" hint="Export interval in seconds" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<combobox id="OTELLogLevel" label="OTel Log Level" size="8" editable="true" unrestricted="true" displayList="DEBUG2,DEBUG,INFO,WARN,SEVERE,FATAL" valueList="DEBUG2,DEBUG,INFO,WARN,SEVERE,FATAL" title="Minimum level for log messages." onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == 'ok') zenPage.DrawServiceStatus();
}

ClientMethod doService() [ Language = javascript ]
{
	var url = zenLink(this.DialogLink+'PID='+encodeURIComponent('%Service_Monitor')+'&from=Monitor');
	zenLaunchPopupWindow(url,'Service','status,scrollbars,resizable=yes,width=600,height=600');
}

/// Save current item.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		var proxy = new zenProxy();
		
		proxy.SNMPEnabled = zen('SNMPEnabled').getValue();
		proxy.OTELMetrics = zen('OTELMetrics').getValue();
		proxy.OTELLogs = zen('OTELLogs').getValue();
		proxy.OTELInterval = zen('OTELInterval').getValue();
		proxy.OTELLogLevel = zen('OTELLogLevel').getValue();

		var result = this.SaveData(proxy);
		this.afterSave(result);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##Class(Config.Monitor).Get(.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set Properties("SNMPEnabled") = pProxy.SNMPEnabled
		Set Properties("OTELMetrics") = pProxy.OTELMetrics
		Set Properties("OTELLogs") = pProxy.OTELLogs
		Set Properties("OTELInterval") = pProxy.OTELInterval
		Set Properties("OTELLogLevel") = pProxy.OTELLogLevel
		
		Set tSC = ##Class(Config.Monitor).Modify(.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Do ..DrawServiceStatus()
	
	Set ..lblTitle = $$$Text("SNMP and Remote Monitor Settings:")
	
	Set tSC = ##Class(Config.Monitor).Get(.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
		Quit $$$OK
	}
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Monitor Settings")
}

Method DrawServiceStatus() As %Status [ ZenMethod ]
{
	Set tSC = ##class(Security.Services).Get("%Service_Monitor",.Properties)
	If $$$ISOK(tSC) {
		Set statusComp = ..%GetComponentById("ServiceStatus")
		Set statusComp.label = $S(Properties("Enabled")=1:$$$TextHTML("The Monitor service is Enabled"),1:$$$TextHTML("The Monitor service is Disabled"))
		;If ('$SYSTEM.Security.Check($$$AdminSecureResourceName,"USE") || ##class(%SYS.EMS).IsReadOnly("Security.Services")) {
		If ('$SYSTEM.Security.Check($$$AdminSecureResourceName,"USE")) {
			Set statusComp.disabled = 1
			Set statusComp.caption = ""
		} Else {
			Set statusComp.caption = $S(Properties("Enabled")=1:$$$TextHTML("Disable"),1:$$$TextHTML("Enable"))
		}
	}
	Quit tSC
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
