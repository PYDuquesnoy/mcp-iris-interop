/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user create or edit an XSLT parameter within a Business Process.
Class EnsPortal.Dialog.BusinessProcessXSLTParm Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User must have READ permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_BPL:READ";

/// User must have WRITE permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_BPL:WRITE";

Parameter APPLYBUTTON = 0;

/// Index (original name of parm), "" for new.
Property parmIndex As %ZEN.Datatype.string(ZENURL = "INDEX");

/// Name of parm.
Property parmName As %ZEN.Datatype.string(ZENURL = "NAME");

/// Value of parm.
Property parmValue As %ZEN.Datatype.string(ZENURL = "VALUE");

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<text id="bpName" size="40" label="Name" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<text id="bpValue" size="40" label="Value" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Business Process XSLT Parameter")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	If (..parmIndex="") {
		Quit $$$TextHTML("Add a new XSLT parameter.")
	}
	Quit $$$TextHTML("Edit an XSLT parameter.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.checkEdit()) {
			var main = this.getOpener();

			var bpName = zen('bpName').getValue();
			var bpValue = zen('bpValue').getValue();

			// test for missing name
			if ('' == zenTrim(bpName)) {
				alert($$$Text('Please enter a name for this parameter.'));
				return false;
			}

			// add to main page
			if (main && main.zenPage && main.zenPage.setXSLTParm) {
				main.zenPage.setXSLTParm(this.parmIndex,zenTrim(bpName),bpValue);
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		zen('bpName').focus();
		zen('bpName').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		Set ..%GetComponentById("bpName").value = ..parmName
		Set ..%GetComponentById("bpValue").value = ..parmValue
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	}
}

/// Key handler for value edit control.
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

}
