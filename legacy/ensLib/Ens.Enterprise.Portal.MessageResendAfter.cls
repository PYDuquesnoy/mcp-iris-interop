/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.MessageResendAfter Extends (EnsPortal.MessageResendAfter, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Message Bank Resend Confirmation";

/// User needs USE permissions on the %Ens_MsgBank_MessageResend resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageResend:USE";

/// Override EDITRESOURCE inherited from EnsPortal.MessageResendAfter.
Parameter EDITRESOURCE;

/// Number of columns drawn in the result table.
/// This is used by some of the helper functions to add messages to the table.
Parameter TABLECOLUMNS = 9;

/// Type of header messages.
Parameter MessageClass = "Ens.Enterprise.MsgBank.MessageHeader";

/// Page to use for displaying message content.
Property messageDisplayPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.Dialog.MessageBodyDisplay.zen" ];

/// Page for displaying the visual trace.
Property messageTracePage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.VisualTrace.zen" ];

/// Page for editing and resending messages.
Property editResendPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.MessageResendEdit.zen" ];

Property viewerPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.MsgBankViewer.zen" ];

XData Style
{
<style type="text/css">
.statusCell.errorStatus {
	color: #CC0000;
}
</style>
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Message Bank Resend Confirmation")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cancelButton",$$$Text("Message Bank Viewer"),$$$Text("Return to the Message Bank Viewer"),"zenPage.gotoPage(zenLink('Ens.Enterprise.Portal.MsgBankViewer.zen'));")
	Quit $$$OK
}

/// Provide HTML for selected messages.
Method DrawHTMLFields(tSessionId As %String) As %Status
{
	If '..Messages Quit $$$OK
	
	Set hasMore = 0
	Set (countNA, countErr, countNew) = 0
	
	Set tBelow = $$$Text("The following is a list of messages that you tried to resend, with the status of each resend operation.")
	Set tH1 = $$$TextHTML("Resend Status")
	Set tH2 = $$$TextHTML("Original Session")
	Set tH3 = $$$TextHTML("Original Header")
	Set tH4 = $$$TextHTML("Original Body")
	Set tH5 = $$$TextHTML("New Session")
	Set tH6 = $$$TextHTML("Created")
	Set tH7 = $$$TextHTML("Source")
	Set tH8 = $$$TextHTML("Target Client")
	Set tH9 = $$$TextHTML("Target")
	&html<
	<div style="margin-left: 20px;margin-top:10px;margin-bottom:10px;">#(tBelow)#</div>
	<div style="margin-left: 20px;">
	<table class="tpTable" style="border: 1px solid lightgray;" cellpadding="4" cellspacing="0">
		<tr>
			<th>#(tH1)#</th>
			<th>#(tH2)#</th>
			<th>#(tH3)#</th>
			<th>#(tH4)#</th>
			<th>#(tH5)#</th>
			<th>#(tH6)#</th>
			<th>#(tH7)#</th>
			<th>#(tH8)#</th>
			<th>#(tH9)#</th>
		</tr>>
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tSQL = "SELECT SessionId,MessageBodyId,MessageBodyClassname,SourceConfigName,TargetConfigName,TimeCreated,NodeId FROM Ens_Enterprise_MsgBank.MessageHeader WHERE %ID = ?"
	Set tSC = tStatement.%Prepare(tSQL)
	If $$$ISERR(tSC) Quit tSC

	Set tMsgId=""
	For i=1:1 {
		Set tMsgId = $O(^IRIS.Temp.ResendIDs(..Key,tMsgId))
		Quit:("" = tMsgId)
		If (i > ..Number) {
			Set hasMore = 1
			#; We want to keep counting but not display
		}
		Set tRowClass = $select(i#2: "tpOdd", 1: "tpEven")
		Set tRS = tStatement.%Execute(tMsgId)
		If 'tRS.%Next() {
			Set countNA = countNA + 1
			Set tError = $system.Status.GetErrorText($$$ERROR($$$EnsErrGeneral,"Original Message header "_tMsgId_" not found; SQLCODE="_tRS.%SQLCODE))
			Do ..WriteInlineMessage(tError,,tRowClass)
			Continue
		}
		Set tStatus = $get(^IRIS.Temp.ResendIDs(..Key,tMsgId,"sc"),$$$OK)
		Set tErr = $$$ISERR(tStatus)
		Set tTargetItem = ""
		Set tTargetClient = ""
		If tErr {
			Set countErr = countErr + 1
		}
		Else {
			Set countNew = countNew + 1
			If 'hasMore {
				Set tNewId = $get(^IRIS.Temp.ResendIDs(..Key,tMsgId,"new"))
				Set tNewTarget = $get(^IRIS.Temp.ResendIDs(..Key,tMsgId,"newnode"))
				If (tNewTarget '= "") {
					Set tResendClient = $piece(tNewTarget,"|",1,$length(tNewTarget,"|")-1)
					If tResendClient '= "" {
						Set tTargetClient = tResendClient
					}
					Set tResendTarget = $piece(tNewTarget,"|",$length(tNewTarget,"|"))
					If tResendTarget '= "" {
						Set tTargetItem = tResendTarget
					}
				}
				If tTargetItem = "" {
					Set tTargetItem = tRS.TargetConfigName
				}
				If tTargetClient = "" {
					Set tTargetClient = ##class(Ens.Enterprise.MonitorClient).getNodeClient(tRS.NodeId)
				}
			}
		}
		If 'hasMore {
			If tErr || (tNewId = "") {
				Set tNewSession = "N/A"
			}
			ElseIf (tNewId < 0) { // Node Id is -99 (i.e. unknown node)
				Set tNewSession = $extract(tNewId,4,"*")
			}
			ElseIf ##class(Ens.Enterprise.MsgBank.MessageHeader).%ExistsId(tNewId) { // If it has been banked
				Set tNewSession = "<a target=""_blank"" href=""#"" onclick=""zenPage.showTrace('"_tNewId_"'); return false;"">"_tNewId_"</a>"
			}
			Else {
				Set tNewSession = tNewId
			}
			Set tTargetClient = $select(tTargetClient = "": "N/A", 1: tTargetClient)
			Set tTargetItem = $select(tTargetItem = "": "N/A", 1: tTargetItem)
			Set tBodyId = $select(tRS.MessageBodyId = "": "&nbsp;", 1: $zcvt(tRS.MessageBodyId,"O","HTML"))
			Set tStatus = $zconvert($select(tErr: $system.Status.GetErrorText(tStatus), 1: $$$Text("OK")),"O","HTML")
			
			&html<<tr class="#(tRowClass)#">
				<td class="statusCell#($select(tErr: " errorStatus", 1:""))#">#(tStatus)#</td>
				<td><a target="_blank" href="#" onclick="zenPage.showTrace('#(tRS.SessionId)#'); return false;">#(tRS.SessionId)#</a></td>
				<td><a target="_blank" href="#" onclick="zenPage.showHeader('#(tMsgId)#'); return false;">#(tMsgId)#</a></td>
				<td><a target="_blank" href="#" onclick="zenPage.showBody('#(tMsgId)#'); return false;">#(tBodyId)#</a></td>
				<td>#(tNewSession)#</td>
				<td>#($piece($classmethod(..#MessageClass,"TimeCreatedLogicalToDisplay",tRS.TimeCreated),".",1))#</td>
				<td>#(tRS.SourceConfigName)#</td>
				<td>#(tTargetClient)#</td>
				<td>#(tTargetItem)#</td>
			</tr>>
		}
	} 
	If hasMore {
		Set tMoreMessage = $$$FormatText($$$Text("There is more data, but only the first %1 records are shown."),..Number)
		Do ..WriteInlineMessage(tMoreMessage,"warning")
	}
	&html<</table></div>>
	
	If (countNew = 1) { Set tDisplayNew = $ZCVT($$$FormatText($$$Text("%1 matching message has been resent"),countNew),"O","HTML") }
	Else { Set tDisplayNew = $ZCVT($$$FormatText($$$Text("%1 matching messages have been resent"),countNew),"O","HTML") }
	Do ..AddMessage(tDisplayNew,"warning",0,"infoMessage")
	
	If (countNA = 1) { Set tDisplayNA = $ZCVT($$$FormatText($$$Text("%1 matching message record could not be retrieved"),countNA),"O","HTML") }
	Else { Set tDisplayNA = $ZCVT($$$FormatText($$$Text("%1 matching message records could not be retrieved"),countNA),"O","HTML") }
	Do ..AddMessage(tDisplayNA,"warning",0,"infoMessage")
	
	If (countErr = 1) { Set tDisplayErr = $ZCVT($$$FormatText($$$Text("%1 matching message was found but could not be resent"),countErr),"O","HTML") }
	Else { Set tDisplayErr = $ZCVT($$$FormatText($$$Text("%1 matching messages were found but could not be resent"),countErr),"O","HTML") }
	Do ..AddMessage(tDisplayErr,"warning",0,"infoMessage")
	
	Quit $$$OK
}

}
