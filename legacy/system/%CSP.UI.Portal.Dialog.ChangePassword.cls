/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Change password dialog for Management Portal
Class %CSP.UI.Portal.Dialog.ChangePassword Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "ChangePassword";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property UserName As %ZEN.Datatype.string(MAXLEN = 160) [ InitialExpression = {$Username} ];

Property msgPassword As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("The two new passwords are not the same. Please type them again.")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="result" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<group cellStyle="padding:10px;">
<hgroup>
<vgroup cellStyle="padding:4px;">
<label label="Name"/>
</vgroup>
<vgroup cellStyle="padding:4px;">
<label id="lblUsername" value="#(%page.UserName)#" controlClass="normal"/>
</vgroup>
</hgroup>
<label labelClass="formTitle" label="You may modify your password here" />
<vgroup labelPosition="left" cellStyle="padding:5px;padding-right:10px;">
<text inputtype="password" id="txtExistingPassword" autocomplete="false" label="Enter Current Password"/>
<text inputtype="password" id="txtNewPassword" autocomplete="false" label="Enter New Password"/>
<text inputtype="password" id="txtNewPassword1" autocomplete="false" label="Confirm New Password"/>
<spacer height="20"/>
</vgroup>

</group>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Current User Information")
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
	zen("txtExistingPassword").focus();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (zen("fld") && zen("fld").getProperty("hidden") == true) return true;
		var oldpw = zen("txtExistingPassword").getValue()
		var newpw = zen("txtNewPassword").getValue();
		var newpw1 = zen("txtNewPassword1").getValue();

		if (newpw != newpw1) {
			zen("result").setValue(this.msgPassword)
			zen("txtNewPassword").setValue("");
			zen("txtNewPassword1").setValue("");
			zen("txtNewPassword").focus();
			return false;
		}
		ok = this.SaveData(newpw,oldpw);
		if (ok != 1) {
			zen("result").setValue(ok);
			zen("txtExistingPassword").setValue("");
			zen("txtNewPassword").setValue("");
			zen("txtNewPassword1").setValue("");
			zen("txtExistingPassword").focus();
			return false;
		} else {
			return true;	
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

ClassMethod SaveData(password, oldpassword) As %String [ ZenMethod ]
{
	Set $ZT = "Error"
	Do $System.Security.ChangePassword($Username,password,oldpassword,.tSC)
	If $$$ISERR(tSC) Set tSC = $System.Status.GetErrorText(tSC)
	Quit tSC
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
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
	
	Set tSC = $$UserCanChangePassword^%SYS.SECURITY($Username,.AllowEdit)
	If AllowEdit = 0 Set ..%GetComponentById("fld").hidden = 1
	Quit $$$OK
}

}
