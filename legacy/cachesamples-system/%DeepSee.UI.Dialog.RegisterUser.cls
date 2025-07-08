/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user register themselves in order to receive DeepSee alerts.
Class %DeepSee.UI.Dialog.RegisterUser Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<text id="userId" label="User Id" readOnly="true"/>
<text id="userName" label="Full name" size="40" hint="Name used for alerts you send"/>
<!--
<text id="email" label="email Address" size="60" hint="Provide if you wish to receive email notification of alerts"/>
-->
<checkbox id="enabled" caption="Alerts enabled" hint="If true, then others can send alerts to you"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Alert Registration")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Register for dashboard alerts")
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
		var ok = this.RegisterUser(zen('userId').getValue(),zen('userName').getValue(),'',zen('enabled').getValue()?1:0);
		if ('' != ok) {
			alert(ok);
			return false;
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
	zen('userName').focus();
	zen('userName').select();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tUser = ##class(%DeepSee.UserPortal.Data.User).%OpenId($UserName)
		If '$IsObject(tUser) {
			Set tUser = ##class(%DeepSee.UserPortal.Data.User).%New()
			Set tUser.userId = $UserName
			Set tUser.alertsEnabled = 1
		}

		Set tCtrlUserId = ..%GetComponentById("userId")
		Set tCtrlUserId.value = tUser.userId

		Set tCtrlUserName = ..%GetComponentById("userName")
		Set tCtrlUserName.value = tUser.fullName

		//Set tCtrlEMail = ..%GetComponentById("email")
		//Set tCtrlEMail.value = tUser.email

		Set tCtrlEnabled = ..%GetComponentById("enabled")
		Set tCtrlEnabled.value = tUser.alertsEnabled
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Register the user.
ClassMethod RegisterUser(pUserId As %String, pUserName As %String, pEMail As %String, pEnabled As %Boolean) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%RegisterUser(pUserId,pUserName,pEMail,pEnabled)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

}
