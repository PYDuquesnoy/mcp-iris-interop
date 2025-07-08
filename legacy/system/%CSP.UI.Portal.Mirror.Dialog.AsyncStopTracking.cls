/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMirror

/// Zen page for System Management Portal - Create Mirror
Class %CSP.UI.Portal.Mirror.Dialog.AsyncStopTracking Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.AsyncStopTracking.zen";

/// Displayed name of this page.
Parameter PAGENAME = "StopTracking";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property ErrorMsg As %String;

Property MirrorName As %ZEN.Datatype.string(ZENURL = "MirrorName");

Property DescText1 As %String [ InitialExpression = {$$$TextHTML("Remove this async member from the selected mirror")} ];

Property DescText2 As %String [ InitialExpression = {$$$TextHTML("Delete the mirror journal log and all journal files (except files in journal.log) for the mirror on this member")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
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
<html OnDrawContent="DrawPageTitle" seed=""/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="fld" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding:3px;">
<label label="This action will:"/>
<html>
<ul>
<li class="zenLabel">#(%page.DescText1)#</li>
<li class="zenLabel">#(%page.DescText2)#</li>
</ul>
</html>
<label label="In addition to the above, you may also remove the mirror attribute from mirrored databases (the databases themselves will not be deleted)"/>
<label label="and mirror journal files in journal.log"/>
<group labelPosition="left" enclosingStyle="margin:10px 0 0 25px;">
<select id="DeleteDBs" label="Remove mirror attribute?" valueList="0,1" displayList="No,Yes" value="0" showEmpty="false"/>
<select id="DeleteJrn" label="Remove mirror journal files?" valueList="0,1" displayList="No,Yes" value="0" showEmpty="false"/>
</group>
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
	zen("DeleteDBs").focus();
}

ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	proxy.MirrorName = zenPage.MirrorName;
	proxy.DeleteDBs = zen("DeleteDBs").getValue();
	proxy.DeleteJrn = zen("DeleteJrn").getValue();
	
	var result = this.SaveData(proxy);

	if (result.ok == 1) {
		return true;
	} else {
		this.showMsg(result.ErrorMessage);
		return false;
	}
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
		Set tSC = ##class(SYS.MirrorConfiguration).RemoveOneMirrorSet(pProxy.MirrorName,pProxy.DeleteDBs,$s(pProxy.DeleteJrn:2,1:1))
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
	
	If $SYSTEM.Mirror.GetInfo()[$$$Primary {
		Set tSC = $$$ERROR($$$OperationNotAllowedInPrimary)
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}

	Quit 1
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Remove Async Member from Mirror %1"),..EscapeHTML(%page.MirrorName))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
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
	Quit $$$Text("Remove Async Member from Mirror")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
