/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the error dialog page.
/// It displays an error message and a prompt which user can answer Yes or No.
/// If error details are available in %session.Data("Errors","Details") then they are displayed in a listbox.<br>
/// To use this class:
/// <ol>
/// <li>Set the following before calling this dialog:</li>
/// <li>%session.Data("Errors","Messages",1) - Message title such as "WARNING". </li>
/// <li>%session.Data("Errors","Messages",2) - Message line. </li>
/// <li>%session.Data("Errors","Messages",3) - Prompt such as "Proceed?"</li>
/// </ol>
/// <p>Example calling this dialog:<br>
/// zenLaunchPopupWindow('%ZEN.Dialog.errorDialog.cls','errorDialog','resizable,width=780,height=280');
/// </p>
Class %ZEN.Dialog.errorDialog Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter AUTONS = 0;

Parameter dialogTitle = "errorDialog";

XData Style
{
<style type="text/css">
.listBox {
	font-family: monospace,Helvetica;
	font-size: 0.8em;	
}
/* Indent the buttons from the messages */
#buttonHolder {
	padding: 5px;
	padding-left: 30px;
	margin: 0px;
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
</page>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<form id="fld" cellStyle="padding-left:5px;">
<label id="message2"/>
<label id="message3"/>
<hgroup id="buttonHolder" cellAlign="left">
<button id="btnOK" caption="Yes" onclick="zenPage.dialogFinish();" />
<spacer width="5" />
<button id="btnCancel" caption="No" onclick="zenPage.dialogCancel();" />
<spacer width="10" />
</hgroup>
<vgroup id="idErrorDetails">
<listBox id="cmbDetails" label="Error Details">
</listBox>
</vgroup>
</form>
</pane>
}

/// Load error message prompts set by the calling class.
/// Load error details. Hide list box if nothing.
Method %OnAfterCreatePage() As %Status
{
	Set ..%GetComponentById("message2").value = $ZCVT($G(%session.Data("Errors","Messages",2)),"O","HTML")
	Set ..%GetComponentById("message3").value = $ZCVT($G(%session.Data("Errors","Messages",3)),"O","HTML")
	Set tCombo = ..%GetComponentById("cmbDetails")
	Set (tErr,tHasErr) = $O(%session.Data("Errors","Details",""))
	While tErr '= "" {
		Set tErrMsg = %session.Data("Errors","Details",tErr)
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = tErrMsg
		Set tOption.value = tErr		
		Set tErr = $O(%session.Data("Errors","Details",tErr))		
	}
	If tHasErr = "" Set tCombo.hidden = 1
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $ZCVT($G(%session.Data("Errors","Messages",1)),"O","HTML")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	return;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	return 'ok';
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
