/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMirror

Class %CSP.UI.Portal.Mirror.Dialog.RemoveLocalConfig Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.RemoveLocalConfig.zen";

/// Displayed name of this page.
Parameter PAGENAME = "RemoveLocalConfig";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsNotInitialized As %Boolean [ InitialExpression = {$SYSTEM.Mirror.GetInfo()["NOTINIT"} ];

Property IsPrimary As %Boolean [ InitialExpression = {$SYSTEM.Mirror.GetInfo()[$$$Primary} ];

Property DescText1 As %String [ InitialExpression = {$$$Text("Delete the mirror config from the local configuration but we do not remove this system from the mirror")} ];

Property DescText2 As %String;

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
<button id="btnFinish" controlClass="commandButton" caption="Remove Mirror from Local Config" onclick="zenPage.dialogFinish();"/>
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
</group>
<group id="isNotPrimaryGroup" hidden="true">
<html>
<div id="failureMessage">
</div>
</html>
<group labelPosition="left" enclosingStyle="margin:10px 0 10px 25px;">
<select id="DeleteDBs" label="Remove mirror attribute?" valueList="0,1" displayList="No,Yes" showEmpty="false"/>
<select id="DeleteJournals" label="Remove both the local and mirror journal logs?" valueList="0,1" displayList="No,Yes" showEmpty="false" value="1" hidden="true"/>
</group>
</group>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (!this.IsPrimary && !this.IsNotInitialized) {
		var msg = "<p>" + $$$Text("This instance is a copy of an active mirror member. ");
		var button = "<strong>" + $$$Text("Remove Mirror from Local Config") + "</strong>";
		msg += $$$FormatText($$$Text("When you select %1 only the local mirror configuration is removed; the active mirror members, including the one this is a copy of, are not affected."), button) + "</p>";
			msg += "<p>" + $$$Text("In addition, you may also remove the mirror attribute from the mirrored databases (the databases themselves are not deleted).");
		var failMessage = document.getElementById("failMessage");
			failureMessage.innerHTML = msg;
		zen("DeleteDBs").focus();
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var st = this.doRemove();
		return st;
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
	return "cleared";
}

ClientMethod doRemove() [ Language = javascript ]
{
	var DeleteDBs = zen("DeleteDBs").getValue();
	var DeleteJournals = zen("DeleteJournals").getValue();
	var msg = $$$Text("Are you sure you want to delete the local mirror configuration?") + '\n\n';
	if (parseInt(DeleteDBs) === 1) {
		msg += $$$Text("The mirrored database attribute will be removed.");
	} else {
		msg += $$$Text("The mirrored database attribute will not be removed.");
	}
	if (!confirm(msg)) {
		return false;
	}

	var proxy = new zenProxy();
	proxy.DeleteDBs = parseInt(DeleteDBs);
	proxy.DeleteJournals = parseInt(DeleteJournals);
	var result = this.SaveData(proxy);
	if (result.ok == 1) {
		return true;
	} else {
		// if save returned an error, display it and then still trigger the refresh of the loading page because things could be changed during save.
		alert(result.ErrorMessage);
		return true;
	}
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set tProxy.ErrorMessage = ""
	Try {
		Set tSC = ##class(%CSP.UI.Portal.Mirror.Utils).DeleteLocalConfig(pProxy.DeleteDBs, pProxy.DeleteJournals)
		If $$$ISERR(tSC) {
			Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
			Set tProxy.ok = 0
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
	Quit $$$Text("Remove Local Mirror Configuration")
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
	} Else {
		Set ..%GetComponentById("isNotPrimaryGroup").hidden = 0
	}
	Quit $$$OK
}

}
