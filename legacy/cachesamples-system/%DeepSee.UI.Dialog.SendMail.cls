/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user send a dashboard via email.
Class %DeepSee.UI.Dialog.SendMail Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Dashboard title.
Property dashboardTitle As %ZEN.Datatype.string(ZENURL = "TITLE");

/// Dashboard URL
Property dashboardURL As %ZEN.Datatype.string(ZENURL = "URL");

XData Style
{
<style type="text/css">

.link {
	color: #404040;
	font-size: 9pt;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<html id="help" OnDrawContent="DrawHelp"/>
<form id="sendForm">
<combobox id="sendTo" editable="true" unrestricted="true" hint="Required" label="Send to" size="70" required="true"/>

<hgroup cellVAlign="middle">
<text id="subject" label="Subject" hint="Required" size="50" required="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>
<textarea id="comments" label="Comments" rows="8" cols="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
</form>
<link caption="Clear History" title="Clear the list of sendTo addresses" onclick="zenPage.ClearHistory();"/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Email Dashboard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Email this dashboard.")
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
		var form = zen('sendForm');
		if (!form.validate()) {
			return false;
		}

		var sendTo = zen('sendTo').getValue();
		var subject = zen('subject').getValue();
		var comments = zen('comments').getValue();
		var ok = this.SendMailViaSMTP(sendTo,subject,comments,this.dashboardURL);
		if (''!==ok) {
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
	try {
		zen('subject').focus();
		zen('subject').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSubject = ..%GetComponentById("subject")
		Set tSubject.value = ..dashboardTitle

		// build list of recent email sendtos
		Set tValueList = ""
		Set tAddr = $O(^DeepSee.User.SendTo($UserName,""))
		While (tAddr'="") {
			Set tValueList = tValueList _ $S(tValueList'="":",",1:"") _ $Replace(tAddr,",","\,")
			Set tAddr = $O(^DeepSee.User.SendTo($UserName,tAddr))
		}

		Set tSendTo = ..%GetComponentById("sendTo")
		Set tSendTo.valueList = tValueList
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod DrawHelp(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Write $$$TextHTML("Email a link to this dashboard.")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Send an email message using the system-defined SMTP server.
ClassMethod SendMailViaSMTP(pSendTo As %String, pSubject As %String, pComments As %String, pURL As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// Remember list of recent sendTo values
		Do ..%RegisterSendTo(pSendTo)

		// clean up URL
		// replace "localhost" to keep email client happy
		Set tURL = $Replace(pURL,"localhost","127.0.0.1")
		
		// use _ instead of % to avoid escape issues with email clients
		Set tURL = $Replace(tURL,"%25DeepSee","_DeepSee")

		Set tInstructions = $$$Text("To view this information click on the following link:","%DeepSee")

		Set tBody = pComments_$C(13,10)_tInstructions_$C(13,10)_$C(13,10)_tURL

		// Use task manager to send the email
		Set tSC = ##class(%SYS.TaskSuper).SendMail(pSendTo,pSubject,tBody)
		If $$$ISERR(tSC) Quit

		&js<alert('Message sent to #($ZCVT(pSendTo,"O","JS"))#.');>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Remember this sendTo address in local list.
ClassMethod %RegisterSendTo(pSendTo As %String) As %Status
{
	If ((pSendTo'="")&&$L(pSendTo<128)) {
		Set ^DeepSee.User.SendTo($UserName,pSendTo) = ""
	}
	Quit $$$OK
}

/// Clear the sendTo history for the current user.
ClassMethod ClearHistory() [ ZenMethod ]
{
	Kill ^DeepSee.User.SendTo($UserName)
	&js<zen('sendTo').setProperty('valueList','');>
}

}
