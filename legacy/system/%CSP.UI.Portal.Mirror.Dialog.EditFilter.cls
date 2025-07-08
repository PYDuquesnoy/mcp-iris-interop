/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMirror

/// Zen page for System Management Port - Edit Dejournal Filter.
Class %CSP.UI.Portal.Mirror.Dialog.EditFilter Extends %CSP.UI.Portal.Dialog.WizardTemplate
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.EditFilter.zen";

/// Displayed name of this page.
Parameter PAGENAME = "EditFilter";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property ErrorMsg As %String;

Property MirrorName As %ZEN.Datatype.string(ZENURL = "MirrorName");

Property NodeName As %ZEN.Datatype.string(ZENURL = "NodeName");

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
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="fld" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding:3px;">
<fieldSet label="Dejournal Filter Class Name">
<text id="DejournalFilter" size="32"/>
</fieldSet>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.ErrorMsg !== "") {
		var msg = this.ErrorMsg;
		this.showMsg(msg);
		zen("btnFinish").setDisabled(true);
		zen("btnFinish").setProperty("controlClass","commandButtonDisabled");
		zen("fld").setHidden(true);
		return;
	}
	zen("DejournalFilter").focus();
}

ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	proxy.MirrorName = zenPage.MirrorName;
	proxy.NodeName = zenPage.NodeName;
	
	proxy.DejournalFilter = zen("DejournalFilter").getValue();
	
	var ok = this.validateSave(proxy);
	if (!ok) {
		return false;
	}
	
	var result = this.SaveData(proxy);

	if (result.ok == 1) {
		return true;
	} else {
		this.showMsg(result.ErrorMessage);
		return false;
	}
}

ClientMethod validateSave(proxy) [ Language = javascript ]
{
	this.resetMsg('');
	zen("idRespond").setProperty("controlClass","redText");
	
	var result = this.validateClass(proxy);
	if (result.ok == 1) return true;
	if (result.ok == 2) {
		text = $$$Text("The specified class does not exit or is not compiled.")+"\n"+$$$Text("Are you sure you want to use this specified class?")+"\n";
		if (!confirm(text)) {
			zen("DejournalFilter").focus();
			return false;
		}
		return true;
	}
	this.showMsg(result.ErrorMessage);
	zen("DejournalFilter").focus();
	return false;
}

ClassMethod validateClass(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set Filter = pProxy.DejournalFilter

	if (Filter'="") {
		s rc=##class(%Dictionary.Classname).IsValid(Filter)
		if $$$ISERR(rc) {
			Set Message = ..EscapeHTML($System.Status.GetErrorText(rc))
			Set tProxy.ok = 0
			Set tProxy.ErrorMessage = Message
		} else {
			Set fobj=##class(%Dictionary.CompiledClass).%OpenId(Filter,,.rc)
			if $$$ISERR(rc) {
				Set tProxy.ok = 2
			}
		}
	}
	Quit tProxy
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to SMP home.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1

	Try {
		Set mm = ##class(Config.MapMirrors).Open(pProxy.MirrorName,pProxy.NodeName,,,.tSC)
		if '$IsObject(mm) {
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set mm.DejournalFilter = pProxy.DejournalFilter
		Set tSC = mm.%Save()
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set mm = ##class(Config.MapMirrors).Open(%page.MirrorName,%page.NodeName,,,.tSC)
	if '$IsObject(mm) {
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}
	Set ..%GetComponentById("DejournalFilter").value = mm.DejournalFilter
	Kill mm
	
	Quit 1
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.doSave()==false) return false;
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
	return true;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Edit Dejournal Filter Class Name")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Use the form below to change the dejournal filter class name for member %1 in mirror %2"),$zconvert(%page.NodeName,"O","HTML"),$zconvert(%page.MirrorName,"O","HTML"))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
