/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Sharding.Dialog.Enable Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Sharding.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Enable.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ShardingEnable";

Parameter RESOURCE = "%Admin_Secure";

Property ShardingLicense As %Boolean;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property PageMessage As %String;

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
<label id="Text1" value="" containerStyle="padding:10px;"/>
<label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>

<group id="form" cellStyle="padding:2px;" hidden="true" enclosingClass="EditForm" enclosingStyle="margin-left:4px;padding-top:2px;" labelPosition="left">
<text id="MaxConn" label="Maximum number of ECP connections" size="3" value="64"/>
 </group>
 </form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.ShardingLicense) {
		zen('form').setHidden(false);
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set ..ShardingLicense = $$Sharding^%SYS.LICENSE()
	Set ..%GetComponentById("Text1").value = $S(..ShardingLicense=1:$$$TextHTML("Enable this InterSystems IRIS instance for use in a sharded cluster. You must restart the instance after clicking OK."),1:$$$TextHTML("Sharding is unavailable for current license."))
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Enable Sharding")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
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
		var ok = 1;
		// if no Sharding license, exit now
		if (!this.ShardingLicense) {
			zenPage.dialogCancel();
			return true;
		}
		var EnableAsShardServer = 1;  //zen('EnableAsShardServer').getValue();
		var MaxConn = zen('MaxConn').getValue();
		if (!(MaxConn.match(/\d/)) || (isNaN(MaxConn))) {
			if (confirm($$$Text("You entered an invalid entry for Maximum number of ECP connections. Use system default 64 and proceed?"))) {
				MaxConn = 64;
				zen('MaxConn').setValue(MaxConn);
			} else {
				zen('MaxConn').focus();
				ok = 0;
				return;	
			}
		}
		var proxy = this.StartEnable(MaxConn, EnableAsShardServer);
		if (proxy.error != '') {
			this.showMsg(proxy.error,1);
			ok = 0;
		} else {
			alert($$$Text("Please restart this IRIS instance to activate Sharding."));
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

/// Start background job to cleanup a selected directory
ClassMethod StartEnable(pMaxConn, pEnableAsShardServer) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set tSC = $System.Sharding.EnableSharding(pMaxConn, pEnableAsShardServer)
		Set %session.Data("Sharding","StartEnable") = tSC
		If $$$ISERR(tSC) {
			Set tProxy.error = ..EscapeHTML($System.Status.GetErrorText(tSC))
		}
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = ..EscapeHTML($System.Status.GetErrorText(tSC))	
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in StartEnable: "_$ZE
	Quit tProxy
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
