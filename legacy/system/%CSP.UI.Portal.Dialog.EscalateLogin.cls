/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Login Escalation dialog for Management Portal
Class %CSP.UI.Portal.Dialog.EscalateLogin Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "EscalateLogin";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property UserName As %ZEN.Datatype.string(MAXLEN = 160) [ InitialExpression = {$Username} ];

Property AvailableRoles As %ZEN.Datatype.csv(MAXLEN = "");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.helpText, .zenHint {
	display:none;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="result" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<group cellStyle="padding:10px;">
<form ondefault="zenPage.dialogFinish();">
<select id="selRole" showEmpty="false" label="Role" hint="Required." onchange="zenPage.doModified(zenThis);"/>
<vgroup labelPosition="left" cellStyle="padding:5px;padding-right:10px;">
<label id="lblUsername" value="#(%page.UserName)#" label="User"/>
<text inputtype="password" id="txtPassword" autocomplete="false" label="Password" hint="Required." onchange="zenPage.doModified(zenThis);"/>
<spacer height="20"/>
</vgroup>
</form>
</group>
</pane>
}

ClientMethod doModified(control) [ Language = javascript ]
{
	control.setProperty('hintClass','helpText');
	control.setProperty('controlClass','');
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Select Escalation Role")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("txtPassword").focus();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		let pw = zen('txtPassword');
		let role = zen('selRole');
		let pass = true;
		
		pass = this.validateRequired(pw, pass, 'S');
		pass = this.validateRequired(role, pass, 'S') && pass;

		if (!pass) {
			zen('result').setValue(zenPage.ValidationErrorMsg);
			return false;
		}

		let ok = this.SaveData(role.getValue(),pw.getValue());
		if (ok != 1) {
			zen('result').setValue(ok);
			zen('txtPassword').setValue('');
			return false;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

ClassMethod SaveData(escalationRole, password) As %String [ ZenMethod ]
{
	Set msg = 1
	Try {
		$$$ThrowOnError(%session.EscalateLogin(escalationRole,password))
	} Catch ex {
		Set msg = ex.DisplayString()	
	}
	Return msg
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
	
	set roles = $$GetEscalationRoles^%SYS.SECURITY()
	Set select = %page.%GetComponentById("selRole")
	Set select.valueList = $listtostring(roles)
	If $listlength(roles)=1 {
		Set select.size = 2 // don't display as a dropdown
		Set select.value = $listget(roles,1)
	} Else {
		Set select.size = $listlength(roles)
	}
	
	Quit $$$OK
}

}
