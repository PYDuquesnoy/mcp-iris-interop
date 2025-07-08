/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A work list class that displays details on the alert that invoked a User portal page.
Class %DeepSee.UserPortal.AlertInfo Extends %DeepSee.UserPortal.WorkList [ System = 4 ]
{

/// Icon (16x16) to display for this work list.
Parameter ICON = "deepsee/ds2_note_44.png";

/// Return the localized display name for this work list.
ClassMethod %GetName() As %String
{
	Quit $$$Text("Alert Details","%DeepSee")
}

/// Return the localized title for this work list.
ClassMethod %GetTitle() As %String
{
	Quit $$$Text("Alert Details","%DeepSee")
}

/// Return an optional tool tip to display.
ClassMethod %GetToolTip() As %String
{
	Quit $$$Text("Show details on who sent this dashboard","%DeepSee")
}

/// Draw the contents of the worklist.<br/>
/// <var>pPanelNo</var> is the worklist panel number.
ClassMethod %DrawWorkList(pPanelNo As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		Set msgFrom = $$$Text("From","%DeepSee")
		Set msgSubject = $$$Text("Subject","%DeepSee")
		Set msgDate = $$$Text("Date","%DeepSee")
		Set msgComments = $$$Text("Comments","%DeepSee")
		Set msgNoAlert = $$$Text("No information available","%DeepSee")

		&html<<div id="worklist#(pPanelNo)#" class="worklist">>
		&html<<div>>

		Set tAlertId = %page.alertId
		Set tAlert = ##class(%DeepSee.UserPortal.Data.Alert).%OpenId(tAlertId)
		If '$IsObject(tAlert) {
			&html<<div>#($ZCVT(msgNoAlert,"O","HTML"))#</div>>
		}
		Else {
			// lookup up sender name
			Set tFrom = tAlert.senderId
			Set tUser = ##class(%DeepSee.UserPortal.Data.User).%OpenId(tAlert.senderId)
			If $IsObject(tUser) {
				Set tFrom = tUser.fullName
			}

			Set tDate = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tAlert.createDate)

			Set styleLabel = "padding-left:4px; font-size: 8pt; color:#606060;"
			Set styleValue = "font-weight:bold;padding-left:4px; padding-right:4px; padding-bottom:4px; font-size: 10pt; color:#404040;"
			
			&html<<div style="#(styleLabel)#">#($ZCVT(msgFrom,"O","HTML"))#</div>>
			&html<<div style="#(styleValue)#">#($ZCVT(tFrom,"O","HTML"))#</div>>

			&html<<div style="#(styleLabel)#">#($ZCVT(msgDate,"O","HTML"))#</div>>
			&html<<div style="#(styleValue)#">#($ZCVT(tDate,"O","HTML"))#</div>>

			If (tAlert.subject'="") {
				&html<<div style="#(styleLabel)#">#($ZCVT(msgSubject,"O","HTML"))#</div>>
				&html<<div style="#(styleValue)#">#($ZCVT(tAlert.subject,"O","HTML"))#</div>>
			}

			If (tAlert.comments'="") {
				&html<<div style="#(styleLabel)#">#($ZCVT(msgComments,"O","HTML"))#</div>>
				&html<<div style="#(styleValue)#">#($ZCVT(tAlert.comments,"O","HTML"))#</div>>
			}
		}

		&html<</div>>
		&html<</div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
