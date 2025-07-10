/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Confirmation dialog that can be used as a replacement for JS alert and confirm boxes.
/// It displays a message and presents one or two buttons with configurable captions and titles.
/// See the parameters and properties that control its behavior and their default values.
/// Button1 takes the role of the OK button and button 2 takes the role of the Apply button except that it also closes the popup.
/// The dialog can have a Cancel button which closes the dialog without notifying the caller page.
/// Examples:
/// <code>zenLaunchPopupWindow('EnsPortal.Dialog.Confirmation.cls?MESSAGE=' + msg,'confirmationDialog','resizable,width=400,height=200');</code>
/// where msg is a JS variable containing the message to be displayed in the dialog (use \n to include line-breaks in it).
/// <p>Note: This class is for internal use of the Management Portal.</p>
Class EnsPortal.Dialog.Confirmation Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter APPLYBUTTON = 1;

Parameter CANCELBUTTON = 1;

Property ActionButtons As %ZEN.Datatype.integer(ZENURL = "ACTIONBUTTONS") [ InitialExpression = 2 ];

Property CancelButton As %ZEN.Datatype.integer(ZENURL = "CANCELBUTTON") [ InitialExpression = 0 ];

Property Message As %ZEN.Datatype.string(ZENURL = "MESSAGE") [ InitialExpression = {$$$Text("Confirmation")} ];

Property Button1Caption As %ZEN.Datatype.string(ZENURL = "CAPTION1") [ InitialExpression = {$$$TextJS("OK")} ];

Property Button2Caption As %ZEN.Datatype.string(ZENURL = "CAPTION2") [ InitialExpression = {$$$TextJS("Apply")} ];

Property Button1Title As %ZEN.Datatype.string(ZENURL = "TITLE1") [ InitialExpression = {$$$TextJS("Confirm and close")} ];

Property Button2Title As %ZEN.Datatype.string(ZENURL = "TITLE2") [ InitialExpression = {$$$TextJS("Apply and close")} ];

Property Icon As %ZEN.Datatype.string(ZENURL = "ICON") [ InitialExpression = "portal/warning_64.png" ];

XData Style
{
<style type="text/css">
body {
	background: lightyellow;	
}
#icon {
	padding-left: 10px;
	padding-right: 20px;
}
#lblMessage {
	font-size: 16px;
	white-space: pre-line;
	padding-right: 10px;
}
.modalGroupCloseButton, .modalGroupCloseButtonHover {
	cursor: default;
}
</style>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<group cellAlign="center" cellVAlign="middle">
<spacer height="10px" />
<hgroup cellVAlign="middle">
<image id="icon" name="icon" valign="middle" src="#(%page.Icon)#" />
<label id="lblMessage" name="lblMessage" valign="middle" value="#(%page.Message)#" />
</hgroup>
</group>
</pane>
}

/// Set message and buttons according to parameters.
Method %OnAfterCreatePage() As %Status
{
	Set ..%GetComponentById("btnOK").caption = ..Button1Caption
	Set ..%GetComponentById("btnOK").title = ..Button1Title
	If ..ActionButtons>1 {
		Set ..%GetComponentById("btnApply").caption = ..Button2Caption
		Set ..%GetComponentById("btnApply").title = ..Button2Title
		//Set ..%GetComponentById("btnApply").onclick = "zenPage.dialogFinish();"
	}
	Else {
		Set ..%GetComponentById("btnApply").hidden = 1
	}
	If ..CancelButton {
		Set ..%GetComponentById("btnCancel").caption = $$$Text("Cancel")
		Set ..%GetComponentById("btnCancel").title = $$$Text("Cancel and close")
	}
	Else {
		Set ..%GetComponentById("btnCancel").hidden = 1
	}
	Set msg = ..Message //..EscapeHTML(..Message)
	Set ..%GetComponentById("lblMessage").value = msg
	Set icon = ..Icon
	If icon="CHECKMARK" {
		Set icon = "deepsee/ds2_todo_44.png"
	}
	Set ..%GetComponentById("icon").src = icon
	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	Quit "" //$ZCVT(..ShortTitle,"O","HTML")
}

/// Invoked when user clicks button 2 which is a dialog 'Apply' button.
/// Overriden in order to close the dialog.
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
			// tell our parent window that Apply was pressed and close the window
			this.disableButtons(true);
			this._callingParent = true;
			this.firePopupAction('apply',this.getDialogValue());
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

/// This is called when the user presses one of the buttons and after ondialogFinish.
ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

Method %DrawTitle(pSeed As %String) As %Status
{
	Quit $$$OK
}

}
