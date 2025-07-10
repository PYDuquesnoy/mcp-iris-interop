/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for Ensemble dialog pages.
Class EnsPortal.Dialog.standardDialog Extends (%CSP.Portal.standardDialog, EnsPortal.Template.base) [ Abstract, System = 4 ]
{

/// Enable styles that are common to all pages and dialogs for the EnsPortal application.
Parameter APPLICATION = "EnsPortal.Application";

Parameter DOMAIN = "Ensemble";

Parameter APPLYBUTTON = 1;

Parameter OKBUTTON = 1;

/// Allow popup to close as if clicking button "Cancel" or "X" when user presses the ESC key. <br>
/// If this parameter has value 0, the popup will not close when user presses ESC. <br>
/// If this parameter has value 1, the popup will be dismissed (canceled) when user presses ESC. <br>
/// If this parameter has value 2, and the popup has button "OK", the popup will close as if clicking "OK".
Parameter CLOSEONESC = 1;

/// Allow popup to close as if clicking button "OK" when user presses the ENTER key.
/// Usually this parameter would be set to 1 if the dialog does not contain input fields.
Parameter CLOSEONENTER = 0;

/// Resource for subclasses to indicate whether further resources are needed to perform actions on pages.
Parameter EDITRESOURCE;

/// This is used to indicate whether this dialog has an OK button.
Property hideOKButton As %ZEN.Datatype.boolean [ Final, InitialExpression = {'+..#OKBUTTON} ];

/// This is used to indicate whether this dialog has any buttons at all.
Property hasButtons As %ZEN.Datatype.boolean [ Final, InitialExpression = {..#APPLYBUTTON || ..#OKBUTTON || ..#CANCELBUTTON} ];

/// Allow the window to be closed by pressing ESC instead of clicking the Cancel button or the "X" icon.</Description>
Property closeOnEsc As %ZEN.Datatype.integer [ Final, InitialExpression = {+..#CLOSEONESC} ];

Property closeOnEnter As %ZEN.Datatype.boolean [ Final, InitialExpression = {+..#CLOSEONENTER} ];

/// Flag to indicate whether the user is permitted to make any changes on a given page.
Property canEdit As %ZEN.Datatype.boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(..#EDITRESOURCE)} ];

/// Message to inform the user they may not perform a given action.
Property msgNotPermitted As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("You are not permitted to perform this action")} ];

/// Flag to indicate that the dialog is running in Studio.
Property studioMode As %ZEN.Datatype.boolean(ZENURL = "STUDIO") [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
/* styles for tabs */
td.tabGroupButtonOff:hover {
	color: #FFEEAA;
	background: #C0C0C0;
}

.tabGroupBody {
	background: #E0E0D0;
	width: 399px;
	min-height: 100px;
}

td.tabGroupButtonOn {
	height: 30px;
	color: #404040;
	background: #E0E0D0;
	font-size: 10pt;
}

td.tabGroupButtonOn:not([ie]) {
background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
background: -webkit-linear-gradient(top, #F8F8FF, #E0E0D0);
	background: linear-gradient(top, #F8F8FF, #E0E0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	height: 30px;
	color: #404040;
	background: #C0C0C0;
	font-size: 10pt;
	background-image: none;
	background-repeat: repeat-x;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-linear-gradient(top, #B0B0B0, #D0D0D0);
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-linear-gradient(top, #B0B0B0, #D0D0D0);
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

.tabGroupGap {
	width: 0px;
}
</style>
}

/// Contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />
<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right" hidden="#('%page.hasButtons)#">
<button id="btnApply" hidden="#(%page.hideApplyButton)#" caption="Apply" onclick="zenPage.dialogApply();" />
<spacer width="5" />
<button id="btnCancel" hidden="#(%page.hideCancelButton)#" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnOK" hidden="#(%page.hideOKButton)#" caption=" OK " onclick="zenPage.dialogFinish();" />
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// Handle keypress of ESC and ENTER.
ClientMethod onkeydownHandler() [ Language = javascript ]
{
	if (evt.keyCode == zenESC && this.closeOnEsc == 1) {
		if (this.isPopup) {
			this.dialogCancel();
		}
		else {
			window.close();
		}
	}
	else if ((evt.keyCode == zenENTER || (evt.keyCode == zenESC && this.closeOnEsc == 2)) && this.closeOnEnter && !zenPage.hideOKButton) {
		this.dialogFinish();
	}
}

/// Ensure that the user has USE permissions on %Ens_Portal before
/// creating the application object
ClassMethod %OnCreateApplication(Output pStatus As %Status, pApplicationName As %String) As %ZEN.application
{
	If pApplicationName = ..#APPLICATION {
		If '$system.Security.Check("%Ens_Portal","USE") {
			Set pStatus = $$$ERROR($$$AccessDenied)
		}
	}
	Quit ""
}

/// Add the EnsException error handling on the client.
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	If ..studioMode {
		Set tSC = ..%AddCSPShareHyperevents()
		If $$$ISERR(tSC) Quit tSC
	}
	Quit ..%AddEnsExceptionHandler(1)
}

ClientMethod checkEdit() [ Language = javascript ]
{
	if (!this.canEdit) {
		alert(this.msgNotPermitted);
	}
	return this.canEdit;
}

/// Invoke the base OnPreHyperEvent() method, and then check whether the user
/// is permitted to invoke the specified method by checking the resource returned
/// by the <method>GetHyperEventResources</method> callback.
/// Also avoid sending back the session cookie if we are invoked in a Studio session.
ClassMethod OnPreHyperEvent(class As %String, method As %String) As %Status [ ServerOnly = 1 ]
{
	If $get(%session.Data("Ensemble","StudioSession",$namespace)) Set %response.OutputSessionToken = 0
	Set tSC = ##super(.class,.method)
	If $$$ISERR(tSC) Quit tSC
	
	Set tClass = class
	Set tMethod = method
	If (tClass = "%ZEN.Controller") {
		Set tContext = $get(%request.Data("WARG_1",1))
		If (tMethod = "InvokeInstanceMethod") && (tContext = 1) {
			Set tMethod = $get(%request.Data("WARG_2",1))
		}	
		ElseIf (tMethod = "InvokeClassMethod") && (tContext = $classname()) {
			Set tMethod = $get(%request.Data("WARG_2",1))
		}
		If tMethod = "" Set tMethod = method
	}
	Set tResourceList = ..GetHyperEventResources(.tMethod)
	If tResourceList = "" Quit $$$OK
	If '##class(EnsPortal.Utils).CheckResourceList(tResourceList) {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit ""
}

/// Trigger keepAlive behaviour for the page.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	this.startKeepAlive();
	this.initPopupSuffix();
	if (this.studioMode && window.cspIntHttpServerMethod && window.studioIntHttpServerMethod && !this._forceHypereventShare) {
		window.cspIntHttpServerMethod = window.studioIntHttpServerMethod;
		this._forceHypereventShare = true;
	}
}

/// Avoid writing out the session cookie if we are in a Studio session.
Method %OnAfterCreatePage() As %Status
{
	If $get(%session.Data("Ensemble","StudioSession",$namespace)) Set %response.OutputSessionToken = 0
	Quit $$$OK
}

Method %OnDetermineCSSLevel() As %Integer
{
	/// Force HTML5 mode when the client has a version of Internet Explorer that supports HTML5.
	Set tLevel = ##super()
	If tLevel = "" {
		Set tUserAgentUpper = $$$UPPER(%request.UserAgent)
		If ($extract(tUserAgentUpper,1,8) = "MOZILLA/") && (tUserAgentUpper [ "; MSIE ") && (tUserAgentUpper [ "; TRIDENT/") {
			Set tTridentVersion = +$piece($piece(tUserAgentUpper,"; TRIDENT/",2),";",1)
			If (tTridentVersion >= 5) Set tLevel = 3
		}
	}
	Quit tLevel
}

Method %OnDrawHTMLMeta() As %Status
{
/// Ensure that we force Internet Explorer to use its most recent rendering engine.
	If $$$ZENISIE &html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	Quit $$$OK
}

}
