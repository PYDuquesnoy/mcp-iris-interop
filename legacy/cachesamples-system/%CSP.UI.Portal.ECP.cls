/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Configuration - ECP
Class %CSP.UI.Portal.ECP Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "ECP Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ECP.zen";

Parameter HELPADDRESS = "Home,Configuration,ECP Settings";

Parameter EMSSERVICE = "Namespace";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Property ConfigIsManaged As %Boolean [ InitialExpression = {##class(%SYS.EMS).IsReadOnly("Config.config")} ];
Property ConfigIsManaged As %Boolean [ InitialExpression = 0 ];

Property DialogLink As %String [ InitialExpression = {..Link("/csp/sys/sec/%CSP.UI.Portal.Dialog.Service.zen",,1)} ];

Property SSLLinkCli As %ZEN.Datatype.string;

Property SSLLinkSvr As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
.fieldHint {
    color: gray;
    font-size: 12px;
    padding-left: 5px;
    vertical-align: super;
}
.successNote {
	background: #F2F1EC;
	border: 1px solid #4D3926;
	border-radius: 5px;
	color: #52B012;
	font-size: 12px;
	font-weight: bold;
	padding: 10px;
	text-align: left;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<hgroup>
<fieldSet labelPosition="left" label="This System as an ECP Application Server" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<text id="MaxServers" label="Maximum number of data servers" size="5" hint="(0 - 254)" onchange="zenPage.doModified();"/>
<text id="ClientReconnectDuration" label="Time to wait for recovery" size="5" hint="(10 - 65535 seconds)" title="How long a client should keep trying to re-establish a connection before giving up." onchange="zenPage.doModified();"/>
<text id="ClientReconnectInterval" label="Time between reconnections" size="5" hint="(1 - 60 seconds)" title="When a server is not available, how long to wait between each reconnection attempt." onchange="zenPage.doModified();"/>
<link id="linkSSLCli" onclick="zenPage.openSSL(1);return false;" href="#" enclosingClass="smpLink"/>
</fieldSet>
<fieldSet labelPosition="left" label="This System as an ECP Data Server" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<link id="ServiceStatus" caption="" href="#" onclick="zenPage.doService();return false;" enclosingStyle="margin-bottom:16px;" enclosingClass="smpLink"/>
<text id="MaxServerConn" label="Maximum number of application servers" size="5" hint="(0 - 254)" title="If modified, this field requires an InterSystems IRIS restart." onchange="zenPage.doModified();"/>
<text id="ServerTroubleDuration" label="Time interval for Troubled state" size="5" hint="(20 - 65535 seconds)" title="Once this period of time has elapsed, the server will declare the connection dead." onchange="zenPage.doModified();"/>
<radioSet id="SSLECP" label="ECP SSL/TLS support" valueList="0,1,2" displayList="Disabled,Enabled,Required" layout="vertical" onchange="zenPage.SSLChanged(zenThis.getValue());"/>
<link id="linkSSLSvr" onclick="zenPage.openSSL(0);return false;" href="#" enclosingClass="smpLink"/>
</fieldSet>
</hgroup>
<group id="SSLwarning" cellStyle="padding:4px;" hidden="true">
<label label="Warning: You must define an SSL/TLS server configuration named '%ECPServer' before you can configure the ECP data server to use SSL/TLS." labelClass="rednote"/>
</group>
<group id="SSLwarning2" cellStyle="padding:4px;" hidden="true">
<label label="Warning: You must enable the SSL/TLS server configuration named '%ECPServer' before you can configure the ECP data server to use SSL/TLS." labelClass="rednote"/>
</group>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	// overriding so that config elements can be edited if not config-managed
	if (this.IsEMSReadOnly && this.ConfigIsManaged) {
		this.disableCommandButton('btnSave');
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == 'ok') {
		if (popupName == 'Service') zenPage.DrawServiceStatus();
		if (popupName == 'SSL') {
			zenPage.DrawSSLStatus();
			this.resetMsg();
	}
	}
}

ClientMethod doAppServers() [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.ECPAppServers.zen';
	this.gotoPage(url);
}

ClientMethod doDataServers() [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.ECPDataServers.zen';
	this.gotoPage(url);
}

ClientMethod doService() [ Language = javascript ]
{
	var url = zenLink(this.DialogLink+'PID='+encodeURIComponent('%Service_ECP')+'&from=ECP');
	zenLaunchPopupWindow(url,'Service','status,scrollbars,resizable=yes,width=600,height=600');
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('MaxServers'),pass,"N",true,0,254)) pass = false;
		if (!this.validateRequired(zen('ClientReconnectDuration'),pass,"N",true,10,65535)) pass = false;
		if (!this.validateRequired(zen('ClientReconnectInterval'),pass,"N",true,1,60)) pass = false;
		if (!this.validateRequired(zen('MaxServerConn'),pass,"N",true,0,254)) pass = false;
		if (!this.validateRequired(zen('ServerTroubleDuration'),pass,"N",true,20,65535)) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	
	var ok = this.validate();
	if (!ok) {
		this.afterValidate();
		return;
	}
	var ssl = this.CheckECPSSL();
	if ((zen("SSLECP").getValue() > 0) && (ssl != 1)) {
		if (ssl != 0) {
			this.showMsg($$$Text('SSL/TLS server configuration named "%ECPServer" does not exist'),1);
		} else {
			this.showMsg($$$Text('SSL/TLS server configuration named "%ECPServer" is not enabled'),1);
		}
		return;
	}
	
	var proxy = new zenProxy();
	proxy.MaxServers = zen("MaxServers").getValue();
	proxy.ClientReconnectDuration = zen("ClientReconnectDuration").getValue();
	proxy.ClientReconnectInterval = zen("ClientReconnectInterval").getValue();
	proxy.MaxServerConn = zen("MaxServerConn").getValue();
	proxy.ServerTroubleDuration = zen("ServerTroubleDuration").getValue();
	proxy.SSLECP = zen("SSLECP").getValue();
	proxy.ConfigIsManaged = this.ConfigIsManaged;
	proxy.IsEMSReadOnly = this.IsEMSReadOnly;
	
	var result = this.SaveData(proxy);

	if (result.ok == 1) {
		this.showMsg(result.msg,2);
		this.setModified(false);
	} else {
		this.showMsg(result.ErrorMessage,1);
	}
}

ClientMethod SSLChanged(newvalue) [ Language = javascript ]
{
	this.doModified();
	if (newvalue > 0) {
		var ssl = this.CheckECPSSL();
		if (ssl != 1) {
			if (ssl != 0) {
				zen('SSLwarning').setHidden(false);
				zen('SSLwarning2').setHidden(true);
			} else {
				zen('SSLwarning').setHidden(true);
				zen('SSLwarning2').setHidden(false);
			}
			return;
		} 
	}
	zen('SSLwarning').setHidden(true);
	zen('SSLwarning2').setHidden(true);
}

ClientMethod openSSL(isClient) [ Language = javascript ]
{
	if (isClient == 1) {
		zenLaunchPopupWindow(zenPage.SSLLinkCli,'SSL','resizable,width=1000,height=700');
	} else {
		zenLaunchPopupWindow(zenPage.SSLLinkSvr,'SSL','resizable,width=1000,height=700');
	}
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..lblTitle = $$$Text("Use the form below to specify how this system operates as an ECP Data Server or ECP Application Server")_":"
	
	If ((##Class(%SYSTEM.License).MaxECPServers() = 0) || (##Class(%SYSTEM.License).KeyServer() = "Single")) {
		Set ..%GetComponentById("errmsg").value = $$$Text("The InterSystems IRIS license does not support ECP.")
		Set ..%GetComponentById("errmsg").hidden = 0
	}
	Do ..DrawServiceStatus()
	
	Set tSC = ##Class(Config.config).Get(.Properties)
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..ConfigIsManaged {
				Set Component.disabled = 1
				If '..IsEMSReadOnly {
					Set Component.hint = $$$Text("This property is managed by the Enterprise Manager Configuration service.")
					Set Component.title = ""
				}
			}
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	Kill Properties

	Set tSC = ##Class(Config.ECP).Get(.Properties)
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
	
	#;SML2649+ ; Setup SSL stuff.
	Do ..DrawSSLStatus()
	if '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Set ..%GetComponentById("SSLECP").value = 0
		Set ..%GetComponentById("SSLECP").disabled = 1
		Set ..%GetComponentById("linkSSLCli").disabled = 1
		Set ..%GetComponentById("linkSSLSvr").disabled = 1
	} else {
		Set ..%GetComponentById("SSLECP").disabled = 0
		Set ..%GetComponentById("linkSSLCli").disabled = 0
		Set ..%GetComponentById("linkSSLSvr").disabled = 0
		Set tSC = ##Class(Security.System).Get($$$SystemSecurityName,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("SSLECP").value = 0
			Set ..%GetComponentById("SSLwarning").value = ..EvalResult(tSC)
			Set ..%GetComponentById("SSLwarning").hidden = 0
			Set ..%GetComponentById("SSLECP").disabled = 1
			Set ..%GetComponentById("linkSSLCli").disabled = 1
			Set ..%GetComponentById("linkSSLSvr").disabled = 1
		} else {
			Set ..%GetComponentById("SSLECP").value = Properties("SSLECPServer")
			If (Properties("SSLECPServer") > 0) {
				Set chkssl = ..CheckECPSSL()
				Set:chkssl<0 ..%GetComponentById("SSLwarning").hidden = 0
				Set:'chkssl ..%GetComponentById("SSLwarning2").hidden = 0
			}
		}
	}
	#;SML2649-
	Quit $$$OK
}

Method DrawServiceStatus() As %Status [ ZenMethod ]
{
	Set tSC = ##class(Security.Services).Get("%Service_ECP",.Properties)
	If $$$ISOK(tSC) {
		Set statusComp = ..%GetComponentById("ServiceStatus")
		Set statusComp.label = $S(Properties("Enabled")=1:$$$TextHTML("The ECP service is Enabled"),1:$$$TextHTML("The ECP service is Disabled"))
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

Method DrawSSLStatus() As %Status [ ZenMethod ]
{
	s SSLExistCli=##class(Security.SSLConfigs).Exists("%ECPClient",.cliobj)
	Set ..%GetComponentById("linkSSLCli").caption = $s(SSLExistCli:$s(cliobj.Enabled:$$$Text("Edit SSL/TLS '%ECPClient'"),1:$$$Text("Enable SSL/TLS '%ECPClient'")),1:$$$Text("Set up SSL/TLS '%ECPClient'"))
	Set ..SSLLinkCli = ..Link("/csp/sys/sec/%CSP.UI.Portal.Mirror.Dialog.SSL.zen",,1)_"isNew="_'+SSLExistCli_"&isECP=1&isClient=1&needEnable="_(SSLExistCli&&'cliobj.Enabled)
	s SSLExistSvr=##class(Security.SSLConfigs).Exists("%ECPServer",.svrobj)
	Set ..%GetComponentById("linkSSLSvr").caption = $s(SSLExistSvr:$s(svrobj.Enabled:$$$Text("Edit SSL/TLS '%ECPServer'"),1:$$$Text("Enable SSL/TLS '%ECPServer'")),1:$$$Text("Set up SSL/TLS '%ECPServer'"))
	Set ..SSLLinkSvr = ..Link("/csp/sys/sec/%CSP.UI.Portal.Mirror.Dialog.SSL.zen",,1)_"isNew="_'+SSLExistSvr_"&isECP=1&isClient=0&needEnable="_(SSLExistSvr&&'svrobj.Enabled)
	If (..%GetComponentById("SSLECP").value > 0) && ('SSLExistSvr || 'svrobj.Enabled) {
		if ('SSLExistSvr) {
			Set ..%GetComponentById("SSLwarning").hidden = 0
			Set ..%GetComponentById("SSLwarning2").hidden = 1
		} else {
			Set ..%GetComponentById("SSLwarning").hidden = 1
			Set ..%GetComponentById("SSLwarning2").hidden = 0
		}
	} else {
		Set ..%GetComponentById("SSLwarning").hidden = 1
		Set ..%GetComponentById("SSLwarning2").hidden = 1
	}
	Quit $$$OK
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to SMP home.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set (Restart,SaveConfig) = 0
		
		// Only save these properties if Config is not EMS-managed
		If 'pProxy.ConfigIsManaged {
			Set tSC = ##class(Config.config).Get(.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

			If pProxy.MaxServerConn '= Properties("MaxServerConn") {
				Set Properties("MaxServerConn") = pProxy.MaxServerConn
				Set Restart = 1
				Set SaveConfig = 1
			}
			If pProxy.MaxServers '= Properties("MaxServers") {
				Set Properties("MaxServers") = pProxy.MaxServers
				Set SaveConfig = 1
			}
			If SaveConfig {
				Set tSC = ##class(Config.config).Modify(.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
			Kill Properties
		}
		
		// Only save these properties if Namespaces is not EMS-managed
		If 'pProxy.IsEMSReadOnly {
			Set tSC = ##class(Config.ECP).Get(.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
			Set Properties("ServerTroubleDuration") = pProxy.ServerTroubleDuration
			Set Properties("ClientReconnectDuration") = pProxy.ClientReconnectDuration
			Set Properties("ClientReconnectInterval") = pProxy.ClientReconnectInterval
		
			Set tSC = ##class(Config.ECP).Modify(.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		
		#;SML2649+ ; Update SSLECPServer setting.
		kill Properties
		Set Properties("SSLECPServer") = pProxy.SSLECP
		Set tSC = ##Class(Security.System).Modify($$$SystemSecurityName,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		#;SML2649-
		
		Set tProxy.ok = 1
		Set tProxy.msg = $$$Text("Settings have been saved.")
		If Restart = 1 {
			Set tProxy.msg = tProxy.msg_" "_$$$Text("You must restart for the new values to take effect.")
		}
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("ECP Settings")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick,hidden)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")
	Set pCommands(3) = $LB("btnData",$$$Text("Data Servers"),$$$Text("View ECP data servers this system may connect to"),"zenPage.doDataServers();")
	Set pCommands(4) = $LB("btnApp",$$$Text("Application Servers"),$$$Text("View ECP application servers connected to this system."),"zenPage.doAppServers();")

	Quit $$$OK
}

/// Return -1: not exist, 0: disabled, 1: exist and enabled.
ClassMethod CheckECPSSL() As %Integer [ ZenMethod ]
{
	if '##class(Security.SSLConfigs).Exists("%ECPServer",.obj) quit -1
	Quit obj.Enabled
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
