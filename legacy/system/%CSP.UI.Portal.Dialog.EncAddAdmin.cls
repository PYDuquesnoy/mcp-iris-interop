/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Add new administrator to encryption key file
Class %CSP.UI.Portal.Dialog.EncAddAdmin Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.EncAddAdmin.zen";

Parameter RESOURCE = "%Admin_Secure:USE";

/// Displayed name of this page.
Parameter PAGENAME = "EncryptionAddAdmin";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property KEYFILE As %ZEN.Datatype.string(ZENURL = "FILE");

/// flag to indicate what to add: admin or key
Property WHAT As %ZEN.Datatype.string(ZENURL = "WHAT");

Property msgPassword As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("The two New Administrator Passwords are not the same. Please type them again.")} ];

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
<label id="idRespond" enclosingClass="errorNote" hidden="true" containerStyle="padding-bottom:2px;"/>
<vgroup id="Prop" cellStyle="padding-bottom:8px;" containerStyle="padding:4px;" labelPosition="left" valign="top">
<text id="txtExistingName" label="Existing Administrator Name" size="30" maxlength="50" hint="Required." hintClass="helpText"/>
<text inputtype="password" id="txtExistingPassword" label="Existing Administrator Password" hint="Required." hintClass="helpText"/>
<text id="txtNewName" label="New Administrator Name" size="30" maxlength="50" hint="Required." hintClass="helpText"/>
<text inputtype="password" id="txtNewPassword" label="New Administrator Password" hint="Required." hintClass="helpText"/>
<text inputtype="password" id="txtNewPassword1" label="Confirm New Administrator Password" hint="Required." hintClass="helpText"/>
<select id="selCipher" label="Cipher Security Level" hint="Required." valueList="16,24,32" displayList="128-bit,192-bit,256-bit" showEmpty="false" originalValue="16"/> 
<textarea id="txtDescription" label="Description" cols="40" rows="5"/>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If %page.WHAT = "adm" Quit $$$TextHTML("Add a New Administrator")
	Quit $$$TextHTML("Add a New Encryption Key")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$FormatText($$$Text("Key File %1"),..EscapeHTML(%page.KEYFILE))
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("txtExistingName").focus();
	if (this.WHAT == "key") {
		zen("txtNewName").setHidden(true);
		zen("txtNewPassword").setHidden(true);
		zen("txtNewPassword1").setHidden(true);
	} else {
		zen("selCipher").setHidden(true)
		zen("txtDescription").setHidden(true);
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var pass = true;
		if (!this.validateRequired(zen("txtExistingName"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("txtExistingPassword"),pass,"S")) pass = false;
		if (this.WHAT == "adm") {
			if (!this.validateRequired(zen("txtNewName"),pass,"S")) pass = false;
			if (!this.validateRequired(zen("txtNewPassword"),pass,"S")) pass = false;
			if (!this.validateRequired(zen("txtNewPassword1"),pass,"S")) pass = false;
		}
		if (!pass) {
			// display standard error message on top
			this.showMsg(this.ValidationErrorMsg,1);
			var field = this.FirstFailed;
			zen(field).focus();
			return false;
		}
		if (this.WHAT == "adm" && zen("txtNewPassword1").getValue() != zen("txtNewPassword").getValue()) {
			this.showMsg(this.msgPassword,1);
			zen("txtNewPassword1").focus();
			return false;
		}
		var ok = this.SaveData(this.WHAT,this.KEYFILE,zen("txtExistingName").getValue(),zen("txtExistingPassword").getValue(),zen("txtNewName").getValue(),zen("txtNewPassword").getValue(),zen("txtDescription").getValue(),zen("selCipher").getValue());
		if (ok != 1) {
			this.showMsg(ok,1);
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
	return zen('txtExistingName').getValue() + "," + zen('txtExistingPassword').getValue() + "," + zen('txtNewName').getValue() + "," + zen('txtNewPassword').getValue() + "," + zen("txtNewPassword1").getValue();
}

ClassMethod SaveData(What, File, Username1, Password1, Username2, Password2, Description, KeyLen) As %String [ ZenMethod ]
{
	Set $ZT = "Error"
	Set tSC = $$$OK
	If What = "adm" Set tSC  = $$AdminAdd^EncryptionKey(File, Username1, Password1, Username2, Password2)
	Else  Set tSC  = $$KeyAdd^EncryptionKey(File, Username1, Password1, Description, KeyLen)
	If $$$ISERR(tSC) Set tSC = $System.Status.GetErrorText(tSC)
	Quit tSC
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
}

}
