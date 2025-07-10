/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Helper dialog to display the server-side output from Source Control classes.
/// This class should only be opened from a class which extends <class>EnsPortal.Template.devPage</class>.
Class EnsPortal.Dialog.SourceControlOutput Extends (EnsPortal.Dialog.standardDialog, %CSP.Portal.SourceControl.Dialog.ServerOutput) [ System = 4 ]
{

/// User needs READ permissions on one of the following resources to view this page:
/// %Ens_ProductionConfig:READ, %Ens_Code, %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules, %Ens_BPL, %Ens_DTL or %Ens_RecordMap
Parameter RESOURCE = "%Ens_ProductionConfig:READ,%Ens_Code:READ,%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ,%Ens_BPL:READ,%Ens_DTL:READ,%Ens_RecordMap:READ";

Parameter APPLYBUTTON = 0;

Parameter CANCELBUTTON = 0;

XData Style
{
<style type="text/css">
#sourceControlOutput {
	background-color: white;
	padding: 3px;
}
</style>
}

/// Refresh the output based on the data supplied in array or from the server.
/// This method also hides the new output indicator on the source page.
/// Overridden from <class>%CSP.Portal.SourceControl.Dialog.ServerOutput</class> as it wasn't
/// being picked up by the Zen inheritance mechanisms.
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

/// Clear output from the session and update the display.
/// Overridden from <class>%CSP.Portal.SourceControl.Dialog.ServerOutput</class> as it wasn't
/// being picked up by the Zen inheritance mechanisms.
ClientMethod clearOutput() [ Language = javascript ]
{
	var ok = zenPage.ClearSCOutput();
	zenPage.refreshOutput();
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
