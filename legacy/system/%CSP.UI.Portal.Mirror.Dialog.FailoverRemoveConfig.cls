/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMirror

Class %CSP.UI.Portal.Mirror.Dialog.FailoverRemoveConfig Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.FailoverRemoveConfig.zen";

/// Displayed name of this page.
Parameter PAGENAME = "RemoveConfig";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsNotInitialized As %Boolean [ InitialExpression = {$SYSTEM.Mirror.GetInfo()["NOTINIT"} ];

Property IsPrimary As %Boolean [ InitialExpression = {$SYSTEM.Mirror.GetInfo()[$$$Primary} ];

Property DescText1 As %String [ InitialExpression = {$$$Text("Delete the mirror journal files except files in journal.log")} ];

Property DescText2 As %String [ InitialExpression = {$$$Text("Delete the mirror configuration information")} ];

Property RestartRequired As %Boolean [ InitialExpression = 0 ];

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();"/>
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Remove" onclick="zenPage.dialogFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="fld" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding:3px;">
<group id="isPrimaryGroup" hidden="true">
<label label="This is the active primary node so you can't remove the mirror configuration."/>
<spacer height="5px"/>
<label label="You need to first clear JoinMirror in the CPF file or disable the %Service_Mirror service so that this node does not activate the configuration at startup."/>
<spacer height="5px"/>
<label label="Then restart InterSystems IRIS and then run this option again."/>
<spacer height="5px"/>
<label id="joined" label="The JoinMirror flag has been cleared. Restart InterSystems IRIS to continue removing this mirror member." hidden="true"/>
</group>
<group id="isNotPrimaryGroup" hidden="true">
<label label="This action will:"/>
<html>
<ul>
<li class="zenLabel">#(%page.DescText1)#</li>
<li class="zenLabel">#(%page.DescText2)#</li>
</ul>
</html>
<label label="In addition to the above, you may also remove the mirror attribute from mirrored databases (the databases themselves will not be deleted)"/>
<label label="and mirror journal files in journal.log"/>
<group labelPosition="left" enclosingStyle="margin:10px 0 10px 25px;">
<select id="DeleteDBs" label="Remove mirror attribute?" valueList="0,1" displayList="No,Yes" value="0" showEmpty="false"/>
<select id="DeleteJrn" label="Remove mirror journal files?" valueList="0,1" displayList="No,Yes" value="0" showEmpty="false"/>
</group>
</group>
<label id="restartMsg" label="InterSystems IRIS needs to be restarted to complete this operation." hidden="true"/>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (!this.IsPrimary && !this.IsNotInitialized) {
		zen("DeleteDBs").focus();
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.IsPrimary) {
			var st = this.doClearFlag();
		} else {
			var st = this.doRemove();
		}
		if (st==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	if (this.IsPrimary) return "cleared";
	if (this.RestartRequired) return "restart";
	return true;
}

ClientMethod doClearFlag() [ Language = javascript ]
{
	var result = this.ClearFlag();
	if (result.ok == 1) {
		return true;
	} else {
		this.showMsg(result.ErrorMessage);
		return false;
	}
}

ClientMethod doRemove() [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	proxy.DeleteDBs = zen("DeleteDBs").getValue();
	proxy.DeleteJrn = zen("DeleteJrn").getValue();
	
	var result = this.SaveData(proxy);

	if (result.ok == 1) {
		if (result.Message == "restart required") {
			this.RestartRequired = true;
		}
		return true;
	} else {
		this.showMsg(result.ErrorMessage);
		return false;
	}
}

ClassMethod ClearFlag() As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1

	Try {
		Set mm = ##class(Config.MirrorMember).Open(,,.tSC)
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		If mm.JoinMirror {
			Set mm.JoinMirror = 0
			Set tSC = mm.%Save()
			If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set tProxy.Message = ""

	Try {
		Set tSC = ##class(SYS.MirrorConfiguration).RemoveMirrorConfiguration(pProxy.DeleteDBs,$s(pProxy.DeleteJrn:2,1:1))
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If $SYSTEM.Mirror.GetInfo()'["NOTINIT" {
			Set tProxy.Message = "restart required"
		}
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Remove Mirror Configuration")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method %OnAfterCreatePage() As %Status
{
	If ..IsPrimary {
		Set ..%GetComponentById("isPrimaryGroup").hidden = 0
		Set ..%GetComponentById("btnFinish").caption = $$$Text("Clear JoinMirror Flag")
		Set mm = ##class(Config.MirrorMember).Open(,,.tSC)
		If 'mm.JoinMirror {
			Set ..%GetComponentById("btnFinish").hidden = 1
			Set ..%GetComponentById("btnCancel").caption = $$$Text("OK")
			Set ..%GetComponentById("joined").hidden = 0
		}
	} Else {
		If ..IsNotInitialized {
			Set ..%GetComponentById("isNotPrimaryGroup").hidden = 0
		} Else {
			Set ..%GetComponentById("restartMsg").hidden = 0
		}
	}
	Quit $$$OK
}

}
