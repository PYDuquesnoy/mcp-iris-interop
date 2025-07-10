/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUtil)

/// This is the Message Resend page of the ZEN application.
Class EnsPortal.MessageResendAfter Extends EnsPortal.MessageResend [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Message Resend Confirmation";

/// User needs USE permissions on the %Ens_MessageResend resource to view this page.
Parameter RESOURCE = "%Ens_MessageResend:USE";

/// Number of columns drawn in the result table.
/// This is used by some of the helper functions to add messages to the table.
Parameter TABLECOLUMNS = 8;

Property UseFilter As %ZEN.Datatype.string [ InitialExpression = 0 ];

Property SortOrder As %ZEN.Datatype.string;

Property Number As %ZEN.Datatype.string(ZENURL = "NUM");

Property HeadOfQueue As %ZEN.Datatype.boolean(ZENURL = "HEAD") [ InitialExpression = 0 ];

Property Messages As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
.warningMessage.infoMessage {
	font-weight: normal;
}
</style>
}

/// Provide HTML for selected messages.
Method DrawHTMLFields(tSessionId As %String) As %Status
{
	If '..Messages Quit $$$OK

	Set hasMore = 0
	Set (countNA, countErr, countNew) = 0

	Set tBelow = $$$Text("The following is a list of messages that you tried to resend, with the status of each resend operation.")
	Set tH1 = $$$TextHTML("Resend Status")
	Set tH2 = $$$TextHTML("Session")
	Set tH3 = $$$TextHTML("New Header")
	Set tH5 = $$$TextHTML("Body")
	Set tH6 = $$$TextHTML("Created")
	Set tH7 = $$$TextHTML("Source")
	Set tH8 = $$$TextHTML("Target")
	&html<
	<div style="margin-left: 20px;margin-top:10px;margin-bottom:10px;">#(tBelow)#</div>
	<div style="margin-left: 20px;">
	<table class="tpTable" style="border: 1px solid lightgray;" cellpadding="4" cellspacing="0">
		<tr>
			<th width="150px">#(tH1)#</th>
			<th>#(tH2)#</th>
			<th>#(tH3)#</th>
			<th>#(tH5)#</th>
			<th>#(tH6)#</th>
			<th>#(tH7)#</th>
			<th>#(tH8)#</th>
		</tr>
	>

	Set msgid=""
	For i=1:1 {
		Set msgid=$O(^IRIS.Temp.ResendIDs(..Key,msgid),1,newid) Quit:""=msgid
		If (i > ..Number) {
			Set hasMore = 1
			#; We want to keep counting but not display
		}

		&sql(SELECT SessionId,MessageBodyId,MessageBodyClassname,SourceConfigName,TargetConfigName,TimeCreated
			 INTO :tSession,:tBodyId,:tBodyClass,:tSource,:tTarget,:tTimeCreated
			 FROM Ens.MessageHeader WHERE ID = :msgid)
		If SQLCODE {
			Set tSC=$$$ERROR($$$EnsErrGeneral,"Message header "_msgid_" not found; SQLCODE="_SQLCODE)
		}
		Else {
			Set tBodyId=$S(""=tBodyId:"&nbsp;",1:$ZCVT(tBodyId,"O","HTML"))
		}
		Set tStatus = ^IRIS.Temp.ResendIDs(..Key,msgid,"sc")
		If (tStatus = "OK") {
			Set tErr = 0
		}
		Else {
			Set tStatus = $P(tStatus,":",2)
			Set tErr = 1
		}
		If 'hasMore {
			Set tStyle = $S(i#2:"tpOdd",1:"tpEven")
			&html<
				<tr class="#(tStyle)#">
					<td class="statusCell">#(tStatus)#</td>
			>
		}
		If SQLCODE {
			Set countNA = countNA + 1
			If 'hasMore {
				Set msgNA="N/A"
				&html<
					<td>#(msgNA)#</td>
					<td>#(msgNA)#</td>
					<td>#(msgNA)#</td>
					<td>#(msgNA)#</td>
					<td>#(msgNA)#</td>
					<td>#(msgNA)#</td>
				</tr>
				>
			}
		}
		ElseIf tErr {
			Set countErr = countErr + 1
			If 'hasMore {
				Set tOld = $$$TextHTML("Old")
				&html<
					<td><a target="_blank" href="#" onclick="zenPage.showTrace(#(tSession)#); return false;">#(tSession)#</a></td>
					<td><a target="_blank" href="#" onclick="zenPage.showHeader(#(msgid)#); return false;"><i><b>#(tOld)#:</b>#(msgid)#</i></a></td>
					<td><a target="_blank" href="#" onclick="zenPage.showBody(#(msgid)#); return false;">#(tBodyId)#</a></td>
					<td><i><b>#(tOld)#:</b> #($P($classmethod(..#MessageClass,"TimeCreatedLogicalToDisplay",tTimeCreated),"."))#</i></td>
					<td><i><b>#(tOld)#:</b> #(tSource)#</i></td>
					<td><i><b>#(tOld)#:</b> #(tTarget)#</i></td>
				</tr>
				>
			}
		}
		Else {
			Set newid = ^IRIS.Temp.ResendIDs(..Key,msgid,"new")
			&sql(SELECT SessionId,MessageBodyId,MessageBodyClassname,SourceConfigName,TargetConfigName,TimeCreated
				 INTO :tSession,:tBodyId,:tBodyClass,:tSource,:tTarget,:tTimeCreated
				 FROM Ens.MessageHeader WHERE ID = :newid)
			If SQLCODE {
				Set:'tErr tSC=$$$ERROR($$$EnsErrGeneral,"Message header "_newid_" not found; SQLCODE="_SQLCODE)
				Set countNA = countNA + 1
				If 'hasMore {
					Set msgNA="N/A"
					&html<
						<td>#(msgNA)#</td>
						<td>#(msgNA)#</td>
						<td>#(msgNA)#</td>
						<td>#(msgNA)#</td>
						<td>#(msgNA)#</td>
						<td>#(msgNA)#</td>
					</tr>
					>
				}
			}
			Else {
				Set tBodyId=$S(""=tBodyId:"&nbsp;",1:$ZCVT(tBodyId,"O","HTML"))
				Set countNew = countNew + 1
				If 'hasMore {
					&html<
						<td><a target="_blank" href="#" onclick="zenPage.showTrace(#(tSession)#); return false;">#(tSession)#</a></td>
						<td><a target="_blank" href="#" onclick="zenPage.showHeader(#(newid)#); return false;">#(newid)#</a></td>
						<td><a target="_blank" href="#" onclick="zenPage.showBody(#(newid)#); return false;">#(tBodyId)#</a></td>
						<td><i>#($P($classmethod(..#MessageClass,"TimeCreatedLogicalToDisplay",tTimeCreated),"."))#</i></td>
						<td><i>#(tSource)#</i></td>
						<td><i>#(tTarget)#</i></td>
					</tr>
					>
				}
			}
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
	ElseIf (countNA > 1) { Set tDisplayNA = $ZCVT($$$FormatText($$$Text("%1 matching message records could not be retrieved"),countNA),"O","HTML") }
	Do:""'=$G(tDisplayNA) ..AddMessage(tDisplayNA,"warning",0,"infoMessage")

	If (countErr = 1) { Set tDisplayErr = $ZCVT($$$FormatText($$$Text("%1 matching message was retrieved but could not be resent"),countErr),"O","HTML") }
	ElseIf (countErr > 1) { Set tDisplayErr = $ZCVT($$$FormatText($$$Text("%1 matching messages were retrieved but could not be resent"),countErr),"O","HTML") }
	Do:""'=$G(tDisplayErr) ..AddMessage(tDisplayErr,"warning",0,"infoMessage")

	Quit $$$OK
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Resend Confirmation")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cancelButton",$$$Text("Message Viewer"),$$$Text("Return to the Message Viewer page"),"zenPage.loadViewerPage();")
	Quit $$$OK
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (zenPage.Messages) {
		zenPage.CleanUpIDs();
	}
	return true;
}

ClientMethod loadViewerPage() [ Language = javascript ]
{
	this.gotoPage(zenLink(this.viewerPage));
}

Method PrepareResults() As %String [ ZenMethod ]
{
	Set ..Messages = 0
	If (""=..Key) || '$get(^IRIS.Temp.ResendIDs(..Key)) {
		Set msgCantResend = $$$LocalizeText("Ensemble","msgCantResend2","Cannot redisplay your message list - data is available via the Message Viewer.")
		Do ..AddMessage(msgCantResend,,0)
	}
	Else {
		Set ..Messages = 1
	}
	Quit ""
}

/// Override method from EnsPortal.MessageResend.
Method OnDrawRibbon() As %Status
{
	Quit $$$OK
}

}
