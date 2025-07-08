/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syConfig

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Template for Mappings popup dialogs Management Portal
Class %CSP.UI.Portal.Mappings.Template Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 1;

Parameter EMSSERVICE = "Namespace";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property CPFMapFile As %String;

Property CPFMapName As %String;

Property Namespace As %String(ZENURL = "$ID1");

Property MappingName As %String(ZENURL = "$ID2");

Property IsNew As %Boolean [ InitialExpression = {$G(%request.Data("$ID2",1),"") = ""} ];

Property disabledStyle As %ZEN.Datatype.style [ InitialExpression = "background:darkgray;color:#545454;" ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.link {
	font-size: 0.8em;
	color: #3B84BC;
}
</style>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.checkFields();
	if (!this.IsNew) {
		var btnApply = zen('btnApply');
		if (btnApply) {
			btnApply.setHidden(true);
		}
	}
}

/// Override in subclasses
ClientMethod checkFields() [ Language = javascript ]
{
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.validate()==false) return false;
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Apply the value for this dialog and keep it open.
/// Overriding so that we can disable the ok and apply buttons after.
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
				this.toggleButtons(true);
				this._callingParent = false;
			}
			catch (closedEx) {}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return 1;
}

ClientMethod toggleButtons(flag) [ Language = javascript ]
{
	var btnApply = zen('btnApply');
	var btnOK = zen('btnOK');
	if (btnApply) {
		btnApply.setProperty('disabled',flag);
		btnApply.setProperty('controlStyle',flag?this.disabledStyle:'');
	}
	if (btnOK) {
		btnOK.setProperty('disabled',flag);
		btnOK.setProperty('controlStyle',flag?this.disabledStyle:'');
	}
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
