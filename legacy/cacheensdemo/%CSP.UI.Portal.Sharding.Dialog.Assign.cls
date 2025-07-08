/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Assign new shard
Class %CSP.UI.Portal.Sharding.Dialog.Assign Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Sharding.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Assign.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ShardAssign";

Parameter RESOURCE = "%Admin_Manage";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// ID for edit. DBName for this page.
Property SHARD As %String(ZENURL = "SHARD");

Property MASTERNAMESPACE As %String(ZENURL = "MASTERNAMESPACE");

Property ROLE As %String(ZENURL = "ROLE");

Property SHARDDATABASE As %String(ZENURL = "SHARD_DATABASE");

Property MIRRORNAME As %String(ZENURL = "MIRROR_NAME");

Property MIRRORDATABASE As %String(ZENURL = "MIRROR_DATABASE");

Property VIP As %String(ZENURL = "VIP");

XData Style
{
<style type="text/css">
.zzenLabel {
	font-weight: normal;
}
.fieldSet {
	border-radius:5px;
	padding: 10px;
}
/* command button styles in WizardTemplate */
.commandButtonDisabled {
	background: white;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.dialogFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<form>
<label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>

<group id="form" cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">

<label label="(* indicates required field)" labelStyle="font-size:12px;" labelClass="lblNormal" align="center"/>

<combobox id="MasterNamespace" label="Master namespace *" editable="true" unrestricted="true" size="30"
dropdownWidth="300px" valign="middle"
 />
 
<text id="ShardHost" label="Shard host *" />
<text id="ShardPort" label="Shard Superserver port *" size="10" hintClass="helpText"/>
<text id="ShardNamespace" label="Shard namespace *" size="20" hintClass="helpText"/>
<select id="Role" label="Role" showEmpty="false"
displayList="Data shard,Query shard"
valueList="Data,Query"
value="Data"
originalValue="Data"
onchange="zenPage.setRole(zenThis.value);"
hint="" hintClass="helpText"/>
<checkbox id="Mirrored" caption="Mirrored" captionClass="zenLabel" value="0" onclick="zenPage.setMirror(zenThis.value);"/>
<fieldSet id="mirrorGroup" hidden="true" containerStyle="font-size:0.8em;padding-left:4px;padding-right:4px;" labelPosition="left" cellStyle="padding:4px;">
<text id="MirrorName" label="Mirror name * " labelClass="zzenLabel"/>
<text id="MirrorHost" label="Shard backup host * " labelClass="zzenLabel"/>
<text id="MirrorPort" label="Shard backup port * " labelClass="zzenLabel"/>
<text id="MirrorVIP" label="Shard VIP" labelClass="zzenLabel"/>
</fieldSet>

<fieldSet id="queueGroup" hidden="true" containerStyle="font-size:0.8em;padding-left:4px;padding-right:4px;" labelPosition="top">
<select id="DataShardNumber" label="Assign this query shard to the selected data shard" labelClass="zzenLabel" valueList="" showEmpty="false"/>
</fieldSet>

 </group>
 </form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);	
	if (!this.SHARD) {
		zen('MasterNamespace').focus();
	} else {
		zen('MasterNamespace').setDisabled(true);
		zen('ShardHost').setDisabled(true);
		zen('ShardPort').setDisabled(true);
		zen('ShardNamespace').setDisabled(true);
		zen('Role').setDisabled(true);
		if (this.MIRRORNAME != '') {
			zenPage.setMirror(1);
		}	
	}
}

ClientMethod setMirror(value) [ Language = javascript ]
{
	zen("mirrorGroup").setHidden(!value);
}

/// show or hide fields based on role = Data or Query
ClientMethod setRole(value) [ Language = javascript ]
{
	switch (value) {
		case 'Data':
			var Mirrored = zen('Mirrored').getValue();
			zen('Mirrored').setHidden(false);
			zen('mirrorGroup').setHidden(!Mirrored);
			zen('queueGroup').setHidden(true);
			if (Mirrored) {
				zen('MirrorName').focus();
			}
			break;
		case 'Query':
			zen('Mirrored').setHidden(true);
			zen('mirrorGroup').setHidden(true);
			zen('queueGroup').setHidden(false);
			zen('DataShardNumber').focus();
			break;
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If ..MASTERNAMESPACE '= "" {
		Set $Namespace = ..MASTERNAMESPACE	
	}	
	If ..SHARD '= "" {
		Set ..%GetComponentById("MasterNamespace").value = ..MASTERNAMESPACE
		Set ..%GetComponentById("ShardHost").value = ..EscapeHTML($P(..SHARDDATABASE,":",1))
		Set ..%GetComponentById("ShardPort").value = ..EscapeHTML($P(..SHARDDATABASE,":",2))
		Set ..%GetComponentById("ShardNamespace").value = ..EscapeHTML($P(..SHARDDATABASE,":",3))
		Set ..%GetComponentById("Role").value = ..EscapeHTML(..ROLE)
		If ..MIRRORNAME '= "" {
			Set ..%GetComponentById("Mirrored").value = 1
		}
		Set ..%GetComponentById("MirrorName").value = ..EscapeHTML(..MIRRORNAME)
		Set ..%GetComponentById("MirrorHost").value = ..EscapeHTML($P(..MIRRORDATABASE,":",1))
		Set ..%GetComponentById("MirrorPort").value = ..EscapeHTML($P(..MIRRORDATABASE,":",2))
		Set ..%GetComponentById("MirrorVIP").value = ..EscapeHTML(..VIP)
		
	} Else {
		Do ..GetNamespaceLists(.valueList, .displayList, .defaultDM)
		Set tCombo = ..%GetComponentById("MasterNamespace")
		Set tCombo.valueList = valueList
		Set tCombo.displayList = displayList
		If ..MASTERNAMESPACE '= "",$$isMaster^%SYS.SHARDSRV(..MASTERNAMESPACE,0) {
			Set defaultDM = ..MASTERNAMESPACE
		}
		Set tCombo.value = $S(defaultDM'="":defaultDM,1:$Namespace)
	}
	Do ..GetShardList(.valueList, .displayList)
	Set ..%GetComponentById("DataShardNumber").valueList = valueList
	Set ..%GetComponentById("DataShardNumber").displayList = displayList
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If ..SHARDDATABASE '= "" {
		Quit $$$TextHTML("Edit Shard")
	}
	Quit $$$TextHTML("Assign Shard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	If ..SHARDDATABASE '= "" {
		Quit "#"_..EscapeHTML(..SHARD)_" "_..EscapeHTML(..SHARDDATABASE)
	}
	Quit ""
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var ok = 1;
		this.resetMsg();
		var proxy = new zenProxy();
		proxy.SHARD = this.SHARD;
		proxy.masterNamespace = zen("MasterNamespace").getValue();
		proxy.shardHost = zen("ShardHost").getValue();
		proxy.shardPort = zen("ShardPort").getValue();
		proxy.shardNamespace = zen("ShardNamespace").getValue();
		proxy.role = zen('Role').getValue();
		proxy.dataShardNumber = '';
		if (proxy.role == 'Query') {
			proxy.dataShardNumber = zen('DataShardNumber').getValue();
		}
		proxy.mirrored = zen('Mirrored').getValue();
		if (proxy.mirrored) {
			proxy.mirrorName = zen('MirrorName').getValue();
			proxy.mirrorHost = zen('MirrorHost').getValue();
			proxy.mirrorPort = zen('MirrorPort').getValue();
			proxy.mirrorVIP = zen('MirrorVIP').getValue();
		} else {
			proxy.mirrorName = '';
			proxy.mirrorHost = '';
			proxy.mirrorPort = '';
			proxy.mirrorVIP = '';
		}
		if (!this.validate(proxy)) {
			this.showMsg($$$Text("Please enter values for required fields."),1);
			if (this.FirstFailed && zen(this.FirstFailed)) {
				zen(this.FirstFailed).focus();
			}
			return false;
		}
		delete this._jobNumber;
		var proxy = this.StartAssign(proxy);
		this._proxy = proxy;
		if (proxy.jobNumber) {
			zen('btnFinish').setProperty('disabled',true);
			zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
			// start timer to check status
			// if background process is finished, display result
			this.msgWait = proxy.msg;
			this._jobNumber = proxy.jobNumber;
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
			ok = 0;
		} else {
			if (proxy.error) {
				this.showMsg(proxy.error, 1);
				ok = 0;
			}	
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
		ok = 0;
	}
	if (ok == 1) {
		return true;
	}
	return false;
}

/// If creating a new view, make sure that the view name is not empty.
ClientMethod validate(proxy) [ Language = javascript ]
{
	var pass = true;
	if (!this.validateRequired(zen('MasterNamespace'),pass,"S")) pass = false;
	if (!this.validateRequired(zen('ShardHost'),pass,"S")) pass = false;
	if (!this.validateRequired(zen('ShardPort'),pass,"N")) pass = false;
	if (!this.validateRequired(zen('ShardNamespace'),pass,"S")) pass = false;
	if (proxy.mirrored) {
		if (!this.validateRequired(zen('MirrorName'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('MirrorHost'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('MirrorPort'),pass,"N")) pass = false;
	}
	return pass;
}

ClientMethod timeout() [ Language = javascript ]
{
	if (!this._jobNumber) {
		return;	
	}
	var proxy = this.CheckJobStatus(this._jobNumber);
	switch (proxy.status) {
		case 'running':
		case 'suspended':
			if (this._proxy) {
				if (proxy.msg != '') {
					var msg = proxy.msg;
				} else {
					this.msgWait = this.msgWait + '.';
					var msg = this.msgWait;
				}
				this.showMsg(msg,0);
			}
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
			break;
		case 'done':
			if (this._proxy) {
				delete this._jobNumber;
				var opener = this.getOpener();
				if (opener) {
					opener.location.reload();
				}
				this.dialogCancel();
			}
			break;
		case 'error':
		case 'terminated':
			if (this._proxy) {
				this.showMsg(proxy.msg,1);
				delete this._jobNumber;
				// enable Finish again so user may correct values and Finish again.
				zen('btnFinish').setProperty('disabled',false);
				zen('btnFinish').setProperty('controlClass','commandButton');
			} else {
				alert('cannot find this_proxy -- unable to continue.');
			}
			break;
	}
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	try {
		if (this._proxy) {
			var opener = this.getOpener();
			if (opener) {
				opener.location.reload();
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Start background job to cleanup a selected directory
ClassMethod StartAssign(proxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set tParms("SHARD") = proxy.SHARD
	Set tParms("masterNamespace") = proxy.masterNamespace
	Set tParms("shardHost") = proxy.shardHost
	Set tParms("shardPort") = proxy.shardPort
	Set tParms("shardNamespace") = proxy.shardNamespace
	Set tParms("dataShardNumber") = proxy.dataShardNumber
	Set tParms("mirrorName") = proxy.mirrorName
	Set tParms("mirrorHost") = proxy.mirrorHost
	Set tParms("mirrorVIP") = proxy.mirrorVIP
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("ShardAssign",$zu(5),.tParms,.tItems,.tJob)
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	If $$$ISERR(status) {
		Set tError = $System.Status.GetErrorText(status)
		Set tProxy.status = 0
		Set tProxy.error = tError
	} Else {
		Set tProxy.status = 1
		Set tProxy.jobNumber = tJob
		Set tProxy.msg = $$$TextHTML("Assign shard in progress. Please wait...")
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in StartAssign: "_$ZE
	Quit tProxy
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
