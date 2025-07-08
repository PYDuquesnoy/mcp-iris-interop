/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Helper dialog to display the server-side output from Source Control classes.
/// This class should only be opened from a class which extends <class>%CSP.Portal.SourceControl.Base</class>.
/// Note that any changes to this class should also be propagated to EnsPortal.Dialog.SourceControlOutput.
Class %CSP.Portal.SourceControl.Dialog.ServerOutput Extends %ZEN.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter CANCELBUTTON = 0;

/// Flag to avoid certain Zen behaviours regarding the closing of the popup.
Property isNotZenPopup As %ZEN.Datatype.string(ZENURL = "NOTZENPOPUP");

XData Style
{
<style type="text/css">
#sourceControlOutput {
	background-color: white;
	padding: 3px;
}
</style>
}

XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="vertical">
<html id="buttons" OnDrawContent="DrawButtons" />
<html id="sourceControlOutput" OnDrawContent="DrawOutput"></html>
</pane>
}

/// Refresh the output based on the data supplied in array or from the server.
/// This method also hides the new output indicator on the source page.
/// Note that this method is copied in the Interoperability subclass, so any changes
/// also need to be implemented there as well.
ClientMethod refreshOutput(array) [ Language = javascript ]
{
	if (array) {
		if (!zenPage._outputDiv) {
			zenPage._outputDiv = document.getElementById('sourceControlOutput');
		}
		var output = array.join('');
		zenPage._outputDiv.innerHTML = (output == '' ? '&nbsp;' : output);
	}
	else {
		zen('sourceControlOutput').refreshContents();
	}
	var opener = this.getOpener();
	if (opener && opener.zenPage && opener.zenPage.updateSCIndicator) {
		opener.zenPage.updateSCIndicator(false);
	}
}

/// clear output from the session and update the display.
/// Note that this method is copied in the Interoperability subclass, so any changes
/// also need to be implemented there as well.
ClientMethod clearOutput() [ Language = javascript ]
{
	var ok = zenPage.ClearSCOutput();
	zenPage.refreshOutput();
}

/// Remove the output data from the session.
ClassMethod ClearSCOutput() As %Integer [ ZenMethod ]
{
	Quit ##class(%CSP.Portal.SourceControl.Base).ClearSourceControlOutput()
}

/// Draw the clear and refresh buttons.
Method DrawButtons(pSeed As %String) As %Status
{
	&html<<table><tr>>
	
	Set tClearTitle = $$$TextHTML("Clear source control output for session","%Utility")
	Set tClearContent = $$$TextHTML("Clear Output","%Utility")
	&html<<td><a title="#(tClearTitle)#" onclick="zenPage.clearOutput();return false;" href="#" class="commandButton" style="line-height: 48px;"><nobr>#(tClearContent)#</nobr></a></td>>
	
	Set tRefreshTitle = $$$TextHTML("Refresh source control output for session","%Utility")
	Set tRefreshContent = $$$TextHTML("Refresh","%Utility")
	&html<<td><a title="#(tRefreshTitle)#" onclick="zenPage.refreshOutput();return false;" href="#" class="commandButton" style="line-height: 48px;"><nobr>#(tRefreshContent)#</nobr></a></td>>
	
	&html<</tr></table>>
	Quit $$$OK
}

/// Write out the contents of the current session's output.
/// If there is no data, write out a non-breaking space for display purposes.
Method DrawOutput(pSeed As %String) As %Status
{
	Set tHasData = 0
	If $IsObject($get(%session)) {
		Set tKey = ""
		For {
			Set tData = ""
			Set tKey = $order(%session.Data("%ISC","Portal","SourceControl",$namespace,"Output",tKey),1,tData)
			Quit:(tKey = "")
			If tData '= "" Set tHasData = 1
			Write tData,!
		}
	}
	If 'tHasData Write "&nbsp;"
	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	Quit $$$Text("Source Control Output","%Utility")
}

Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This dialog doesn't return a value.
ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// Override the handling of <method>firePopupAction</method> for the
/// default case where the popup has not been launched using zenLaunchPopupWindow().
ClientMethod dialogFinish() [ Language = javascript ]
{
	try {
		// check for callback
		var ok = true;
		if (this.ondialogFinish) {
			ok = this.ondialogFinish('ok');
		}
	 
	 	// Don't call back to parent if not zen
		if (ok  && (zenPage.isNotZenPopup == '')) {
			// tell our parent window that OK was pressed.
			this.firePopupAction('ok',this.getDialogValue());
		}
		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Close the window and update the parent when the user is finished with the page.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var opener = this.getOpener();
	if (opener && opener.zenPage) {
		opener.zenPage._sourceControlWindow = null;
	}
	if (this.isSoftModal) {
		if (window.top && window.top.zenPage) window.top.zenPage.endModal();
	}
	else {
		window.close();
	}
}

/// Ensure that we refresh the output (and thus update the parent flag)
/// whenever the user comes back to the popup.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (!zenIsIE) {
		window.onfocus = function() { zenPage.refreshOutput();};
	}
	zenPage.refreshOutput();
}

/// Ensure that the parent page knows when this page gets closed.
ClientMethod onunloadHandler() [ Language = javascript ]
{
	var opener = this.getOpener();
	if (opener && opener.zenPage && (opener.zenPage._sourceControlWindow === window)) {
		opener.zenPage._sourceControlWindow = null;
	}
}

}
