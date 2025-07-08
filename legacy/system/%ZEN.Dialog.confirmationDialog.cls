/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the confirmation dialog page.
/// It displays confirmation message and a prompt which user can answer Yes or No.
/// To use this class:
/// <ol>
/// <li>Set the following before calling this dialog:</li>
/// <li>%session.Data("Confirmation","Messages",1) - Message title such as "DELETE?". </li>
/// <li>%session.Data("Confirmation","Messages",2) - Message line. </li>
/// <li>%session.Data("Confirmation","Messages",3) - Prompt such as "Proceed?"</li>
/// <li>%session.Data("Confirmation","btnOk",1) - Caption for the OK button such as "Yes". </li>
/// <li>%session.Data("Confirmation","btnCancel",1) - Caption for the CANCEL button such as "No". </li>
/// </ol>
/// <p>Example calling this dialog:<br>
/// zenLaunchPopupWindow('%ZEN.Dialog.confirmationDialog.cls','confirmationDialog','resizable,width=380,height=180');
/// </p>
Class %ZEN.Dialog.confirmationDialog Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter AUTONS = 0;

Property link As %ZEN.Datatype.string;

Parameter dialogTitle = "confirmationDialog";

XData Style
{
<style type="text/css">
body {
	background: #eeeeee;	
}
.listBox {
	font-family: monospace,Helvetica;
	font-size: 0.8em;	
}
</style>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<group cellAlign="center" cellStyle="padding-top:35px; padding-left:20px;">
<html OnDrawContent="DrawHTML"/>
</group>
<hidden id="confirmedlink"/>
</pane>
}

/// Load error message prompts set by the calling class
Method %OnAfterCreatePage() As %Status
{
	Set tOkCaption = $ZCVT($S($G(%request.Data("btnOk",1))'="":$G(%request.Data("btnOk",1)),1:$G(%session.Data("Confirmation","btnOk",1))),"O","HTML")
	Set tCancelCaption = $ZCVT($S($G(%request.Data("btnCancel",1))'="":$G(%request.Data("btnCancel",1)),1:$G(%session.Data("Confirmation","btnCancel",1))),"O","HTML")
	Set:tOkCaption'="" ..%GetComponentById("btnOK").caption = tOkCaption
	Set:tCancelCaption'="" ..%GetComponentById("btnCancel").caption = tCancelCaption
	//Link is used for tablePane confirmLinks; not documented as it's tp-specific and relies on onPopupAction handling it		
	Set ..%GetComponentById("confirmedlink").value = $G(%request.Data("Link",1))
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set tTitle=$ZCVT($G(%request.Data("Title",1)),"O","HTML")		
	Quit $S(tTitle'="":tTitle,1:$ZCVT($G(%session.Data("Confirmation","Messages",1)),"O","HTML"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method DrawHTML(pSeed) As %Status
{
	
	s rMsg1=$S($G(%request.Data("Msg1",1))'="":$G(%request.Data("Msg1",1)),1:$G(%session.Data("Confirmation","Messages",2)))
	s rMsg2=$S($G(%request.Data("Msg2",1))'="":$G(%request.Data("Msg2",1)),1:$G(%session.Data("Confirmation","Messages",3)))		
	Set tMsg1 = $ZCVT($ZCVT(rMsg1,"I","JS"),"O","HTML")	
	Set tMsg2 = $ZCVT($ZCVT(rMsg2,"I","JS"),"O","HTML")		
	&html<<table border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td align="left" width="58"><img width="32" height="36" src="#(..Link("deepsee/ds2_check_44.png"))#" border="0"/></td>
		<td align="left" width="90%" style="padding-left:20px;">
		<div>#(tMsg1)#</div>
		>
	If tMsg2 '= "" {
		&html<<br/><div>#(tMsg2)#</div>>
	}
	&html<</td><td>&nbsp;</td></tr></table>>
	Quit $$$OK
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	return 'ok';
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return encodeURIComponent(zen('confirmedlink').value);
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	zen("btnOK").focus();
}

Method %DrawTitle(pSeed As %String) As %Status
{
	Quit $$$OK
}

}
