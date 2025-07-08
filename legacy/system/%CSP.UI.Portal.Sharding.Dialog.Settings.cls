/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The id for each field on this page should be the same name used as the property name in $SYSTEM.Sharding and each defined in the OPTIONS property on this page.
Class %CSP.UI.Portal.Sharding.Dialog.Settings Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Sharding.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Settings.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ShardingSettings";

Parameter RESOURCE = "%Admin_Manage";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property MASTERNAMESPACE As %String(ZENURL = "MASTERNAMESPACE");

/// Option property names that will be shown on this page
Property OPTIONS As %String [ InitialExpression = "AutoVerify,DropIgnoreError,MasterIPAddress,ConnectTimeout,MirrorConnectAttempts" ];

/// Current Maximum ECP connection number. If this is modified, then the instance will need to be restarted for the new value to take effect.
Property MaxConn As %Integer;

Property PageMessage As %String;

/// Where this dialog got opened from
Property ClusterLevel As %String(ZENURL = "CLUSTERLEVEL") [ InitialExpression = "NAMESPACE" ];

XData Style
{
<style type="text/css">
.normal {
	padding-top:6px;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<form>
<label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>

<group id="form" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">
<titleBox title="Cluster-wide settings" />
<vgroup labelPosition="left" cellStyle="padding:2px;" >
<checkbox id="AutoVerify" label="Automatically verify shards on assignment" value="0"/>
<text id="ConnectTimeout" label="Shard connection timeout (seconds)" hint="" size="3" value="60"/>
<text id="MasterIPAddress" label="IP address of shard master data server" hint="Use this address instead of hostname." size="40" value=""/>
<text id="MirrorConnectAttempts" label="Mirrored shard retries" hint="Number of retries when connecting to a mirrored shard." size="3" value=""/>
<checkbox id="DropIgnoreError" label="Ignore errors during DROP TABLE" value="0"/>
</vgroup>

<spacer height="20" />

<titleBox title="Instance-level settings" />
<vgroup labelPosition="left" cellStyle="padding:2px;" >
<text id="MaxConn" label="Maximum number of ECP connections" size="3" value="64" hint="(0 - 254) Total nodes in cluster cannot exceed this setting on any node. After changing, restart the instance to activate the new value."/>
</vgroup>
 </group>
 </form>
 <html id="idError" OnDrawContent="DrawAbortError" hidden="true"/>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('MaxConn'),pass,"N",true,0,254)) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set options = ..OPTIONS
	For i = 1:1:$L(options,",") {
		Set id = $P(options,",",i)
		Set value = ""
		Set tSC = $SYSTEM.Sharding.GetOption(..MASTERNAMESPACE, id, .value)
		If $$$ISOK(tSC) {
			Set ..%GetComponentById(id).value = value
		}
	}
	// Get Maximum number of ECP connection value
	Set tCurrentNamespace = $Namespace
	If tCurrentNamespace '= "%SYS" {
		Set $Namespace = "%SYS"	
	}
	Kill Properites
	Set tSC = ##class(Config.config).Get(.Properties)
	If $G(Properties("MaxServerConn")) {
		Set ..%GetComponentById("MaxConn").value = Properties("MaxServerConn")
		Set ..MaxConn = Properties("MaxServerConn")
	}
	If ..MASTERNAMESPACE '= "" {
		Set $Namespace = ..MASTERNAMESPACE	
	} Else {
		Set $Namespace = tCurrentNamespace
	}
	
	if ..ClusterLevel'="NAMESPACE" {
		set ..%GetComponentById("MasterIPAddress").label = $$$Text("IP address of data node 1")
	}
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Advanced Settings")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ..EscapeHTML(..MASTERNAMESPACE)
}

Method DrawAbortError(seed As %String) As %Status
{
	If seed '= "" {
		&html<<div class="ErrorBox"><pre>#(..EscapeHTML(seed))#</pre></div>>
	}
	Quit $$$OK
}

Method DrawResult(seed As %String) As %Status
{
	If seed '= "" {
		&html<<pre>#(..EscapeHTML(seed))#</pre>>
	}
	Quit $$$OK
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
		var MaxConn = zen("MaxConn").getValue();
		var ok = this.validate();
		if (!ok) {
			this.showMsg(this.ValidationErrorMsg,1);
			return;
		}
		var ok = 1;
		var array = this.OPTIONS.split(',');
		var option = new Array(array.length);
		var name;
		var value;
		for (i=0; i<array.length; i++) {
			name = array[i];
			value = zen(name).getValue();
			if (zen(name).controlClass == 'checkbox') {
				value = value ? 1 : 0;
			}
			option[i] = value;
		}
		var proxy = this.SaveData(this.MASTERNAMESPACE, this.OPTIONS, option[0], option[1], option[2], option[3], option[4], this.MaxConn, MaxConn);
		if (proxy.error != '') {
			this.showMsg(proxy.error,1);
		} else {
			if (proxy.message != "") alert(proxy.message);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	if (ok == 1) {
		return true;
	}
	return false;
}

/// Save option values to server.
ClassMethod SaveData(pMasterNamespace, pOPTIONS, pAutoVerify, pDropIgnoreError, pConnectTimeout, pMasterIPAddress, pMirrorConnectAttempts, pOldMaxConn, pNewMaxConn) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set values = $lb(pAutoVerify, pDropIgnoreError, pConnectTimeout, pMasterIPAddress, pMirrorConnectAttempts)
		For i = 1:1:$L(pOPTIONS,",") {
			Set id = $P(pOPTIONS,",",i)
			Set value = $lg(values,i)
			Set tSC = $SYSTEM.Sharding.SetOption(pMasterNamespace, id, value)
			If $$$ISERR(tSC) {
				Set tProxy.error = tProxy.error _ $System.Status.GetErrorText(tSC) _ " "
			}
		}
		If pOldMaxConn '= pNewMaxConn {
			Set Properties("MaxServerConn") = pNewMaxConn
			Set Properties("MaxServers") = pNewMaxConn
			Set tCurrentNamespace = $Namespace
			If tCurrentNamespace '= "%SYS" {
				Set $Namespace = "%SYS"	
			}
			Set tSC = ##class(Config.config).Modify(.Properties)
			Kill Properties
			If $$$ISERR(tSC) {
				Set tProxy.error = $System.Error.GetErrorText(tSC)	
			} Else {	
				Set tProxy.message = $$$Text("You must restart for the new 'Maximum number of ECP connections' to take effect.")
			}
			Set $Namespace = tCurrentNamespace
		}

	} While (0)
Done
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in SaveData: "_$ZE
	Quit tProxy
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
