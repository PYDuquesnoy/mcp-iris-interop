/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

/// This base class provides a standard template for the dialog pages
/// provided by Zen. The various dialog pages are implemented as subclasses
/// of this class.<br>
/// To create a new dialog based on this class:
/// <ol>
/// <li>Create a subclass of this class.</li>
/// <li>Define an XData block named dialogBody.</li>
/// <li>Within this XData block define the contents of the dialog using a pane component as the container.</li>
/// <li>Override the <method>%OnGetTitle</method> to provide the dialog title.</li>
/// <li>Override the <method>%OnGetSubtitle</method> to provide the dialog subtitle.</li>
/// <li>Override the <method>getDialogValue</method> to supply the return value for the dialog.</li>
/// <li>Override the <parameter>APPLYBUTTON</parameter> if the dialog has an apply button.</li>
/// </ol>
Class %ZEN.Dialog.standardDialog Extends %ZEN.Component.page [ Abstract, Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// SMP favorite icon.
Parameter FAVORITEICON As COSEXPRESSION = "$$$ISCFAVORITEICON";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// If true, then this dialog displays a Cancel button.
Parameter CANCELBUTTON = 1;

/// Provide a title for the dialog window. The value is supplied
/// by the <method>%OnGetTitle</method> method.
Property dialogTitle As %ZEN.Datatype.string [ ReadOnly ];

/// This is used to indicate whether this dialog has an apply button.
Property hideApplyButton As %ZEN.Datatype.boolean [ Final, InitialExpression = {'+..#APPLYBUTTON} ];

/// This is used to indicate whether this dialog has a cancel button.
Property hideCancelButton As %ZEN.Datatype.boolean [ InitialExpression = {'+..#CANCELBUTTON} ];

/// Style applied to buttons when automatically disabled.
Property disabledStyle As %ZEN.Datatype.style [ InitialExpression = "background-image:none;background:#D0D0D0;" ];

XData Style
{
<style type="text/css">

body {
	background: #E0E0E0;
	font-family: arial, sans-serif;
}

/* Default style for labels. */
.zenLabel {
	color: #404040;
	font-size: 0.8em;
	font-weight: bold;
}

.zenRequired {
	color: darkblue;
	font-size: 0.8em;
	font-weight: bold;
}

.zenLabelDisabled {
	color: gray;
	font-size: 0.8em;
	font-weight: normal;
}

.zenHint {
	color: #808080;
}

#header {
	position: relative;
}

/* the size of the body will be adjusted on the client */
#body {
	background: none;
	padding: 5px;
	overflow: auto;
}

/* this must have 0 padding or sizing logic will fail */
#footer {
	position: absolute;
	bottom: 0;

	color: #404040;
	background: rgb(232,231,226);
	background-image: none;
	width: 100%;
	padding: 0px;
	border-top: 1px solid gray;
}

/* nested group lets us define some padding */
#buttonHolder {
	padding: 5px;
	margin: 0px;
}

/* assume there is a decsription block with this id */
#desc {
	line-height: 1.2;
	color: darkblue;
	padding-top: 1.0em;
	padding-bottom: 1.0em;
}

.stdTitle {
	color: white;
	background: rgb(53,107,141);
	background-image: none;
	border-bottom: 1px solid gray;
	padding: 0px;
	font-size: 1.4em;
	font-family: arial;
	white-space: nowrap;
}

/* UserName etc. */
.stdTitleInfo {
	color: black;
	background: #C5D6D6;
	width: 100%;
	padding: 0px;
	font-family: arial;
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo td {
	color: black;
	padding-left: 5px;
	padding-right: 10px;
	font-size: 8pt;
	font-weight: bold;
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo th {
	color: darkblue;
	padding: 0px;
	font-size: 8pt;
	font-weight: normal;
	text-align: right;
	white-space: nowrap;
}

/* buttons in footer */
#btnApply input,
#btnOK input,
#btnCancel input {
	width: 6.0em;
	cursor: pointer;
}
/* command button styles */
#btnOK input,
#btnApply input,
#btnCancel input,
.commandButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonRemove {
	background: rgb(141,53,53);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonDisabled {
	background: darkgray;
	color: #545454;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
	border-top: 1px solid lightgray;
	border-left: 1px solid lightgray;
	border-right: 2px solid gray;
	border-bottom: 2px solid gray;
}

#btnOK input:hover,
#btnApply input:hover,
#btnCancel input:hover,
.commandButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}

.commandButtonRemove:hover {
	background: rgb(141,53,53);
	color: white;
	background-image: url(portal/button_red_hover.png);
	background-repeat: repeat-x;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />
<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnApply" hidden="#(%page.hideApplyButton)#" caption="Apply" onclick="zenPage.dialogApply();" />
<spacer width="5" />
<button id="btnCancel" hidden="#(%page.hideCancelButton)#" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnOK" caption=" OK " onclick="zenPage.dialogFinish();" />
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// Provide HTML for html title box.<br>
/// Default implementation displays the standard Zen title bar.
Method %DrawTitle(pSeed As %String) As %Status
{
	#; draw html title box
	Set tTitle = ..%OnGetTitle()
	Set tProp = ..%OnGetSubtitle()

	&html<<table class="stdTitle" border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td align="left" width="58"><img width="58" height="58" src="#(..Link("portal/icon_sysexplore.png"))#"/></td>
		<td align="left" width="90%" style="padding-left:20px;">
		<div style="font-size: 0.8em;">#(tTitle)#</div>
		<div style="font-size: 0.6em; font-style: italic;">#(tProp)#</div></td>
		<td>&nbsp;</td></tr></table>>

	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit "Title"
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit "Subtitle"
}

/// Get value for dialogTitle property.
Method dialogTitleGet() As %ZEN.Datatype.string
{
	Quit ..%OnGetTitle()
}

/// Use soft modals for dialogs.
ClassMethod %OnUseSoftModals() As %Boolean [ CodeMode = expression ]
{
1
}

/// Apply the value for this dialog and keep it open.
/// Do not overide, instead implement the ondialogFinish method.
ClientMethod dialogApply() [ Language = javascript ]
{
	try {
		// we are already processing a request
		if (this._callingParent) return;
		
		// check for callback
		var ok = true;
		if (this.ondialogFinish) {
			ok = this.ondialogFinish('apply');
		}
	
		if (ok) {
			// tell our parent window that OK was pressed.
			// do not close this window.
			this._callingParent = true;
			this.disableButtons(true);
			this.firePopupAction('apply',this.getDialogValue(),false);
			try {
				this.disableButtons(false);
				this._callingParent = false;
			}
			catch (closedEx) {}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Apply the value for this dialog and close it.
/// Do not overide, instead implement the ondialogFinish method.
ClientMethod dialogFinish() [ Language = javascript ]
{
	try {
		// we are already processing a request
		if (this._callingParent) return;

		// check for callback
		var ok = true;
		if (this.ondialogFinish) {
			ok = this.ondialogFinish('ok');
		}
	 
		if (ok) {
			// tell our parent window that OK was pressed.
			this.disableButtons(true);
			this._callingParent = true;
			this.firePopupAction('ok',this.getDialogValue());
			try {
				this.disableButtons(false);
				this._callingParent = false;
			}
			catch (closedEx) {}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Close this dialog without applying its value.
/// Do not overide, instead implement the ondialogCancel method.
ClientMethod dialogCancel() [ Language = javascript ]
{
	try {
		// check for callback
		var ok = true;
		if (this.ondialogCancel) {
			ok = this.ondialogCancel();
		}
	
		if (ok) {
			this.disableButtons(true);
			zenPage.cancelPopup();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// This method is no longer supported by standardDialog so
/// make sure it does not get used.
ClientMethod btnOK() [ Final, Language = javascript ]
{
}

/// This method is no longer supported by standardDialog so
/// make sure it does not get used.
ClientMethod btnApply() [ Final, Language = javascript ]
{
}

/// Get the value that will be applied when the user presses the OK button.
/// This is implemented by subclasses.
ClientMethod getDialogValue() [ Language = javascript ]
{
	alert('getDialogValue method is unimplemented');
	return '';
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Abstract, Language = javascript ]
{
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Abstract, Language = javascript ]
{
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Abstract, Language = javascript ]
{
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Final, Language = javascript ]
{
	if (load && this.ondialogStart) {
		this.ondialogStart();
	}
	this.adjustSize();
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	var header = zenPage.getComponentById('header');
	var body = zenPage.getComponentById('body');
	var footer = zenPage.getComponentById('footer');

	if (header && body && footer) {
		var divHeader = header.getEnclosingDiv();
		var divBody = body.getEnclosingDiv();
		var divFooter = footer.getEnclosingDiv();
		var root = document.getElementById("zenBody");
		var winHeight = 0;
		var winWidth = 0;

		if (root) {
			winHeight = root.offsetHeight;
			winWidth = root.offsetWidth;
		}
		else {	
			winHeight = zenGetWindowHeight();
			winWidth = zenGetWindowWidth();
		}		
		
		var hgt = winHeight - (parseInt(divHeader.offsetHeight) + parseInt(divFooter.offsetHeight));

		// adjust for scroll bars in dialogs
		// var adj = (!zenIsIE || zenIsHTML5) ? 20 : 0;
		var adj = 10;
		hgt = hgt < 10 ? 10 : (hgt - adj);
		var wid = winWidth - adj;
		divBody.style.height = hgt + "px";
		//divBody.style.width = wid + "px";
	}
}

/// Key handler used by many controls in dialogs. Defined here for convenience.<br/>
/// To use, add an onkeydown handler to controls in your dialog:<br/>
/// <example>
/// &lttext label="Name" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/&gt
/// </example>
/// If the user presses ESCAPE within this control, the dialog is cancelled. If the user
/// presses ENTER, then the dialog is completed (same as pressing OK).
/// If <var>escOnly</var> is true, then only the ESC key is processed. This is useful for
/// controls where the ENTER key is needed (such as a textarea).
ClientMethod ctrlKeyDown(evt, escOnly) [ Language = javascript ]
{
	switch(evt.keyCode) {
	case zenENTER:
		if (!escOnly) {
			this.dialogFinish();
		}
		break;
	case zenESC:
		this.dialogCancel();
		break;
	}
	return true;
}

/// Disable or enable the apply,cancel, and ok buttons for this dialog.
ClientMethod disableButtons(flag) [ Language = javascript ]
{
	var btnApply = zen('btnApply');
	var btnOK = zen('btnOK');
	var btnCancel = zen('btnCancel');
	if (btnApply) {
		btnApply.setProperty('disabled',flag);
		btnApply.setProperty('controlStyle',flag?this.disabledStyle:'');
	}
	if (btnOK) {
		btnOK.setProperty('disabled',flag);
		btnOK.setProperty('controlStyle',flag?this.disabledStyle:'');
	}
	if (btnCancel) {
		btnCancel.setProperty('disabled',flag);
		btnCancel.setProperty('controlStyle',flag?this.disabledStyle:'');
	}
}

}
