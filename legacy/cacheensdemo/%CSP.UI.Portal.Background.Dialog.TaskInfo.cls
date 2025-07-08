/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Displays Background Task Info dialog for Management Portal.
Class %CSP.UI.Portal.Background.Dialog.TaskInfo Extends (%CSP.UI.Portal.Dialog.WizardTemplate, %ZEN.Portal.Utils, %CSP.UI.Portal.Background.Utils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/%CSP.UI.Portal.Background.Dialog.TaskInfo.zen";

/// Displayed name of this page.
Parameter PAGENAME = "BackgroundTaskInfo";

Parameter RESOURCE = "%Admin_Operate:USE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

/// ID for Systems background task id 
Property SysBGTaskId As %String(ZENURL = "SysBGTaskId");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	overflow: auto;
}
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
<jsonProvider id="jsonJobInfo" OnGetTargetObject="GetJobInfo">
<parameter paramName="parmSysBGTaskId" value="#(%page.SysBGTaskId)#"/>
 </jsonProvider>
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>

<pane paneName="dialogBody" id="body" hidden="true"/>

<hgroup id="footer" width="100%" cellAlign="even">
<hgroup cellAlign="left">
<button id="btnAbort" controlClass="commandButtonDisabled" caption="Cancel Task" hidden="true" onclick="zenPage.doAction('Cancel');" title="Cancel this task" />
<button id="btnPause" controlClass="commandButtonDisabled" caption="Pause" hidden="true" onclick="zenPage.doAction('Pause');" title="Pause this task"/>
<button id="btnResume" controlClass="commandButtonDisabled" caption="Resume" hidden="true" onclick="zenPage.doAction('Resume');" title="Resume this task"/>
</hgroup>
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnClose" controlClass="commandButton" caption="Close" onclick="zenPage.dialogCancel();" />
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="result" controlClass="redText" value="" containerStyle="padding-left:10px;"/>
<iframe id="output"/>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
	// show body after the resize is done
	zen('body').setHidden(false);
	var json = zen('jsonJobInfo').getContentObject();
	if (json.error && json.error != '') {
		zen('result').setValue(json.error);
		return;	
	}
	this.drawData();
	this.updateButtons(json);

	if (!json.HasEnded) {
		var timer = zen('timer');
		timer.setProperty('timeout',2000);
		timer.startTimer();
	}
}

/// This method allows user to cancel the task that is currently in progress
ClientMethod doAction(action) [ Language = javascript ]
{
	var SysBGTaskId = this.SysBGTaskId;
	var actionText = "";
	switch(action) {
		case 'Cancel':
			actionText = $$$Text("Cancel");
			break;
		case 'Pause':
			actionText = $$$Text("Pause");
			break;
		case 'Resume':
			actionText = $$$Text("Resume");
			break;
	}
	var msg = $$$Text("Are you sure you want to %1 this background task?");
	var ok = confirm(msg.replace("%1",actionText));
	if (ok) {
		var proxy = this.ActionProcess(action, SysBGTaskId);
		if (proxy.error) {
			zen('result').setValue(proxy.error);
			return;
		} else {
			// refresh dialog
			window.location.reload();	
		}
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// This callback, if defined, is called when the user presses the Close button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	try {
		this.firePopupAction('ViewDetails',1,false);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("output");
	var wd = zenGetWindowWidth() - 20;
	var ht = zenGetWindowHeight() - 140;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Background Task Info")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

Method GetJobInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..GetTaskInfo(.pParms, .pObject)

	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method invokes method to Cancel/Pause/Resume a background job
ClassMethod ActionProcess(pAction As %String, pSysBGTaskId As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tObj = ##class(%SYS.BackgroundTask).%OpenId(pSysBGTaskId)
		If $IsObject(tObj) {
			If pAction = "Cancel" {
				Set tSC = tObj.Cancel()
			} ElseIf pAction = "Pause" {
				Set tSC = tObj.Pause()
			} ElseIf pAction = "Resume" {
				Set tSC = tObj.Resume()
			}
			Kill tObj
		} Else {
			Set tProxy.error = $$$TextHTML("Task is no longer available.")
		}
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $System.Status.GetErrorText(tSC)
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error = "Error occurred for "_pAction_": "_$ZE
	Quit tProxy
}

}
