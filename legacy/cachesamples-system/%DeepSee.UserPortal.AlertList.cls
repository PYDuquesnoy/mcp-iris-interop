/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A work list class that provides a list of user alerts within a User portal page.
Class %DeepSee.UserPortal.AlertList Extends %DeepSee.UserPortal.WorkList [ System = 4 ]
{

/// Icon (16x16) to display for this work list.
Parameter ICON = "deepsee/ds2_envelope_44.png";

/// Return the localized display name for this work list.
ClassMethod %GetName() As %String
{
	Quit $$$Text("Alert List","%DeepSee")
}

/// Return an optional header message to display.
ClassMethod %GetHeaderMessage() As %String
{
	// figure out new alert count
	Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetAlertsForUser(.tAlerts,.tNewCount,25)
	If $$$ISERR(tSC) Quit
	Set msgItems = $$$FormatText($$$Text("%1 new item(s)"),tNewCount)
	Quit msgItems
}

/// Return the localized title for this work list.
ClassMethod %GetTitle() As %String
{
	Quit $$$Text("Alerts","%DeepSee")
}

/// Return an optional tool tip to display.
ClassMethod %GetToolTip() As %String
{
	Quit $$$Text("Show list of alerts","%DeepSee")
}

/// Draw the contents of the worklist.<br/>
/// <var>pPanelNo</var> is the worklist panel number.
ClassMethod %DrawWorkList(pPanelNo As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetAlertsForUser(.tAlerts,.tNewCount,25)
		If $$$ISERR(tSC) Quit

		Set msgFrom = $$$Text("From","%DeepSee")
		Set msgSubject = $$$Text("Subject","%DeepSee")
		Set msgDate = $$$Text("Date","%DeepSee")
		Set tTruncLen = 50

		Set hlpRemove = $$$Text("Delete this alert","%DeepSee")
		Set tRemoveIcon = "deepsee/ds2_x_44.png"
	
		&html<<div id="worklist#(pPanelNo)#" class="worklist">>
		// JMD: show message if no alerts
		If '$D(tAlerts) {
			&html<<div style="color:#808080;padding:10px;">>
			Write $$$Text("You have no alerts.")
			&html<</div>>
		}
		Else {
			&html<<table class="worklistTable" width="100%" cellspacing="0" border="0" cellpadding="0">>
			&html<<tr class="worklistHeader">
			<td>&nbsp;</td>
			<th class="worklistSmall">#(msgFrom)#</th>
			<th class="worklistSmall">#(msgSubject)#</th>
			<th class="worklistSmall">#(msgDate)#</th>
			<td>&nbsp;</td>
			</tr>>
			Set r = 0
			Set n = $O(tAlerts(""))
			While (n'="") {
				Set r = r + 1
				// $LB(from,subject,date,url,priority,icon,iconTip)
				Set tAlertId = $LG(tAlerts(n),1)
				Set tFrom = $LG(tAlerts(n),2)
				Set tSubject = $LG(tAlerts(n),3)
				Set tDate = $LG(tAlerts(n),4)
				Set tURL = $LG(tAlerts(n),5)
				Set tPriority = $LG(tAlerts(n),6)
				Set tIcon = $LG(tAlerts(n),7)
				Set tIconTip = $LG(tAlerts(n),8)
				Set tTip = tSubject
				Set tSubject = $S($L(tSubject)>tTruncLen:$E(tSubject,1,tTruncLen)_"...",1:tSubject)
				Set tDate = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tDate)
			
				Set tStyle = ""
				If (tPriority = "high") {
					Set tStyle = "color: red;"
				}
				ElseIf (tPriority = "low") {
					Set tStyle = "color: gray;"
				}

				Set tCls = $S(r#2:"worklistRowOdd",1:"worklistRowEven")
				&html<<tr class="#(tCls)#" title="#($ZCVT(tTip,"O","HTML"))#" style="#(tStyle)#" onmouseover="this.className='worklistRowHover';" onmouseout="this.className='#(tCls)#';">>
					If (tIcon = "") {
						&html<<td onclick="zenPage.gotoAlert('#($ZCVT(tURL,"O","JS"))#');" >&nbsp;</td>>
					}
					Else {
						&html<<td onclick="zenPage.gotoAlert('#($ZCVT(tURL,"O","JS"))#');" ><image src="#(tIcon)#" style="height:12px;width:12px;padding:2px;" alt="" title="#($ZCVT(tIconTip,"O","HTML"))#"/></td>>
					}
			
				&html<
					<td class="worklistSmall" onclick="zenPage.gotoAlert('#($ZCVT(tURL,"O","JS"))#');" >#($ZCVT(tFrom,"O","HTML"))#</td>
					<td class="worklistSmall" onclick="zenPage.gotoAlert('#($ZCVT(tURL,"O","JS"))#');" >#($ZCVT(tSubject,"O","HTML"))#</td>
					<td class="worklistSmall" onclick="zenPage.gotoAlert('#($ZCVT(tURL,"O","JS"))#');" >#($ZCVT(tDate,"O","HTML"))#</td>
					<td><image style="height:12px;width:12px;padding:2px;" title="#(hlpRemove)#" src="#(tRemoveIcon)#" onclick="zenPage.removeFromAlerts('#($ZCVT(tAlertId,"O","JS"))#');"/></td>
					</tr>>
				Set n = $O(tAlerts(n))
			}
			&html<</table>>
		}
		&html<</div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
