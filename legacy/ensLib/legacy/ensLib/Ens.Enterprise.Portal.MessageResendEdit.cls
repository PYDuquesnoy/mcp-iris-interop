/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUtil)

/// This is the Resend and Edit page for the Message Bank.
Class Ens.Enterprise.Portal.MessageResendEdit Extends (EnsPortal.MessageResendEdit, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Message Bank Edit and Resend";

/// User needs USE permissions on the %Ens_MsgBank_MessageEditResend resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageEditResend:USE";

Parameter HEADERCLASS = "Ens.Enterprise.MsgBank.MessageHeader";

/// Ignored in the Message Bank.
Property Suspended As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property newTargetClient As %ZEN.Datatype.string(ZENURL = "TARGETCLIENT");

/// If supplied, this is the new target configuration item to which to send the message.
Property newTargetItem As %ZEN.Datatype.string(ZENURL = "TARGETITEM");

/// If supplied, this is the new target to which to send the message
Property NewTarget As %ZEN.Datatype.string;

Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageTrace","USE")} ];

Property canViewHeaders As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageHeader","USE")} ];

Property canViewContents As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageContent","USE")} ];

/// Page to use for displaying message content.
Property messageDisplayPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.Dialog.MessageBodyDisplay.zen" ];

/// Page to use for displaying the results of the resend.
Property resendResultPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.MessageResendAfter.zen" ];

/// Page for displaying the visual trace.
Property messageTracePage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.VisualTrace.zen" ];

/// Page for displaying messages.
Property viewerPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.MsgBankViewer.zen" ];

/// Ensure we don't draw anything for Suspended messages.
Method DrawHTMLFields(tSessionId As %String) As %Status
{
	Set ..Suspended = 0
	Quit ##super(.tSessionId)
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Message Bank Edit and Resend")
}

Method NewTargetGet() As %String [ CodeMode = expression ]
{
$select((..newTargetClient '= "") || (..newTargetItem '= ""): ..newTargetClient_"|"_..newTargetItem, 1: "")
}

Method NewTargetSet(pVal = "") As %Status
{
	Set i%NewTarget = pVal
	Set ..newTargetClient = $piece(pVal,"|",1)
	Set ..newTargetItem = $piece(pVal,"|",2)
	Quit $$$OK
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

Method GetSubmitURL() As %String [ CodeMode = expression ]
{
..Link($classname()_".zen",,1) _ "SEND=1&KEY=" _ ..Key _ "&HEAD=" _ ..HeadOfQueue _ "&TARGETCLIENT=" _ ..newTargetClient _ "&TARGETITEM="_..newTargetItem
}

Method PerformResend(pHeader As Ens.MessageHeaderBase, pNewBody As %RegisteredObject, Output pNewHeaderId As %String, Output pText) As %Status
{
	Set tNewTarget = ..NewTargetGet()
	Set tSC = ##class(Ens.Enterprise.MsgBank.MessageHeader).ResendDuplicatedMessage(.tWSClientObjs,pHeader.%Id(),.pNewHeaderId,tNewTarget,pNewBody)
	If $$$ISERR(tSC) Quit tSC
	Set tNodeId = $extract(pNewHeaderId,1,3)
	Set tClientHeaderId = $extract(pNewHeaderId,4,*)
	Set tHeaderDisplay = "["_$select(tNodeId = -99: "?", 1: tNodeId)_"]"_tClientHeaderId
	Set tTargetDisplay = $select(..newTargetClient = "": ##class(Ens.Enterprise.MsgBank.Node).GetNodeName(tNodeId), 1: ..newTargetClient) _ "|" _ $select(..newTargetItem = "": pHeader.TargetConfigName, 1: ..newTargetItem)
	Set pText = $ZCVT($$$FormatText($$$Text("Copy of message %1 resent as message %2 to %3 with new edited body '%4'"),pHeader.%Id(),tHeaderDisplay,tTargetDisplay,pNewBody.%Id()),"O","HTML")
	Quit $$$OK
}

}
