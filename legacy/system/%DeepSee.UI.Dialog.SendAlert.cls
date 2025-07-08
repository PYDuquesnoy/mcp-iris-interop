/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user send a DeepSee dashboard alert.
Class %DeepSee.UI.Dialog.SendAlert Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Dashboard title.
Property dashboardTitle As %ZEN.Datatype.string(ZENURL = "TITLE");

XData Style
{
<style type="text/css">

#sendToList {
	background: white;
	border: 1px solid gray;
	height: 100px;
	overflow: auto;
}

.noUserMsg {
	padding: 4px;
	color: #804040;
}

table tr.rowOdd {
	background: #F0F0FF;
}

table tr.rowEven {
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<html id="help" OnDrawContent="DrawHelp"/>
<html id="sendToList" label="Send to" OnDrawContent="DrawUserList"/>
<hgroup cellVAlign="middle">
<text id="subject" label="Subject" size="70" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<spacer width="10"/>
<select id="priority" label="Priority" showEmpty="false" valueList="low,,high" displayList="Low,Normal,High" value=""/>
</hgroup>
<textarea id="comments" label="Comments" rows="8" cols="60" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Send Alert")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Send an alert to another Analytics user")
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
		// get selected users
		var targetList = '';
		var users = new Array();
		for (var n=1;;n++) {
			var cb = self.document.getElementById('cb_'+n);
			if (cb) {
				if (cb.checked) {
					users[users.length] = cb.value;
				}
			}
			else {
				break;
			}
		}
		targetList = users.join(',');
		var priority = zen('priority').getValue();
		var comments = zen('comments').getValue();
		var subject = zen('subject').getValue();
		if (''==targetList) {
			alert('Please select someone to send the alert to.');
			return false;
		}

		var ok = this.SendAlert(targetList,this.dashboardName,priority,subject,comments);
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
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Send the alert.<br/>
/// <var>pTargetList</var> is csv list of user ids.<br/>
ClassMethod SendAlert(pTargetList As %String, pDashboardName As %String, pPriority As %String, pSubject As %String, pComments As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// Send alert to each item in the target list
		For n = 1:1:$L(pTargetList,",") {
			Set tUserId = $P(pTargetList,",",n)
			Set tAlert = ##class(%DeepSee.UserPortal.Data.Alert).%New()
			Set tAlert.senderId = $UserName
			Set tAlert.userId = tUserId
			Set tAlert.subject = pSubject
			Set tAlert.comments = pComments
			Set tAlert.priority = pPriority
			Set tAlert.dataId = pDashboardName
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%SendAlert(tAlert)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

ClassMethod DrawHelp(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Write $$$TextHTML("Send a link to this dashboard to one or more users.")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod DrawUserList(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// get list of users with alerts enabled
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetUserList(.tList,,1)
		If $$$ISERR(tSC) Quit

		&html<<table width="100%">>
		Set r = 0
		Set n = $O(tList(""))
		While (n'="") {
			Set r = r + 1
			Set tUserId = $LG(tList(n),1)
			Set tName = $LG(tList(n),2)
			&html<<tr class="#($S(r#2:"rowEven",1:"rowOdd"))#">
			<td><input type="checkbox" id="cb_#(r)#" value="#($ZCVT(tUserId,"O","HTML"))#"/></td>
			<td width="99%">#($ZCVT(tName,"O","HTML"))#</td>
			</tr>>
			Set n = $O(tList(n))
		}
		&html<</table>>

		If (r=0) {
			&html<<div class="noUserMsg">#($$$Text("No one is currently registered to receive alerts."))#</div>>
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
