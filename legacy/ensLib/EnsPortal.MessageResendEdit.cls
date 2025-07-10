/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUtil)

/// This is the Message Resend page of the ZEN application.
/// We always do a "resend" from the message viewer page but a "resubmit" from the suspended messages page.
Class EnsPortal.MessageResendEdit Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Message Edit and Resend";

/// User needs USE permissions on the %Ens_MessageEditResend resource to view this page.
Parameter RESOURCE = "%Ens_MessageEditResend:USE";

Parameter HEADERCLASS = "Ens.MessageHeader";

/// If true, this is the second time through this page and we are definitely resending the message. Otherwise it is the first time through.
Property Send As %ZEN.Datatype.boolean(ZENURL = "SEND") [ InitialExpression = 0 ];

/// Identifies in which global to find the message header identifier
Property Key As %ZEN.Datatype.string(ZENURL = "KEY");

/// The actual message header identifier
Property Header As %ZEN.Datatype.string(ZENURL = "HDR");

/// If supplied and true, this tells us that the parent page is the suspended messages page rather than the message viewer page.
/// We always do a "resend" from the message viewer page but a "resubmit" from the suspended messages page.
/// Resend - clone a new header for the message and send with the new header.
/// Resubmit - do not clone a new header for the message, instead resubmit using the old header.
Property Suspended As %ZEN.Datatype.boolean(ZENURL = "SUSP") [ InitialExpression = 0 ];

/// If supplied, this is the new target to which to send the message
Property NewTarget As %ZEN.Datatype.string(ZENURL = "TARGET");

/// If supplied and true, this means to put this message at the head of its queue
Property HeadOfQueue As %ZEN.Datatype.boolean(ZENURL = "HEAD") [ InitialExpression = 0 ];

Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageTrace","USE")} ];

Property canViewHeaders As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageHeader","USE")} ];

Property canViewContents As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageContent","USE")} ];

/// Page to use for displaying message content.
Property messageDisplayPage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.Dialog.MessageBodyDisplay.zen" ];

/// Page to use for displaying the results of the resend.
Property resendResultPage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.MessageResendAfter.zen" ];

/// Page for displaying the visual trace.
Property messageTracePage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.VisualTrace.zen" ];

/// Page for displaying messages.
Property viewerPage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.MessageViewer.zen" ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
a {
	text-decoration: none;
	color: #3b84bc;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" valign="top">
<spacer height="10" />
<html OnDrawContent="DrawHTMLFields" valign="top"/>
</pane>
}

/// Update the details for a selected message.
ClientMethod showHeader(messageId) [ Language = javascript ]
{
	if (!this.canViewHeaders) {
		alert(this.msgNotPermitted);
		return false;
	}
	var url = this.messageDisplayPage + "?SHOW=header&ID=" + encodeURIComponent(messageId);
	zenLaunchPopupWindow(zenLink(url),'','status,scrollbars,resizable=yes,width=600,height=600');
}

/// Update the details for a selected message.
ClientMethod showBody(messageId) [ Language = javascript ]
{
	if (!this.canViewContents) {
		alert(this.msgNotPermitted);
		return false;
	}
	var url = this.messageDisplayPage + "?SHOW=body&ID=" + encodeURIComponent(messageId);
	zenLaunchPopupWindow(zenLink(url),'','status,scrollbars,resizable=yes,width=600,height=600');
}

Method GetSubmitURL() As %String [ CodeMode = expression ]
{
..Link($classname()_".zen",,1) _ "SEND=1" _ $select(..Key: "&KEY=" _ ..Key, ..Header: "&HDR=" _ ..Header, 1: "") _ $select(..HeadOfQueue: "&HEAD=" _ ..HeadOfQueue, 1: "") _ $select(..NewTarget '= "": "&TARGET=" _ ..NewTarget, 1: "") _ $select(..Suspended: "&SUSP=" _ ..Suspended, 1: "")
}

/// Provide HTML for editing the selected message. Most code extracted from old CSP page.
Method DrawHTMLFields(tSessionId As %String) As %Status
{
	If (""'=..Key) { // Get the first value; there is only one
		Set tHdrId = $O(^IRIS.Temp.ResendIDs(..Key,""))
		#; Detect cleanup of ResendIDs
		If (tHdrId="")&&(..Send=1) {
			&html<<div align="left" style="padding-left:20px;padding-top:20px;">>
			Write $ZCVT($$$Text("Page automatically refreshed. Message not resent again"),"O","HTML")
			&html<</div>>
			Quit $$$OK
		}
	}
	ElseIf (""'=..Header) { // We got the message id from the caller
		Set tHdrId = ..Header 
	}
	Else { // we don't know which message to open
		&html<<div align="left" style="padding-left:20px;padding-top:20px;">>
		Write $ZCVT($$$Text("Unable to open message header"),"O","HTML")
		&html<</div>>
		Quit $$$OK
	}
	Set tHeader = $classmethod(..#HEADERCLASS,"%OpenId",tHdrId)
	If ('$IsObject(tHeader)) {
		&html<<div align="left" style="padding-left:20px;padding-top:20px;">>
		Write $ZCVT($$$FormatText($$$Text("Unable to open message header %1"),tHdrId),"O","HTML")
		&html<</div>>
		Quit $$$OK
	}
	Set tOldBody = ""
	Set:""'=tHeader.MessageBodyClassName tOldBody = $classmethod(tHeader.MessageBodyClassName,"%OpenId",tHeader.MessageBodyId)
	If ('$IsObject(tOldBody)) {
		&html<<div align="left" style="padding-left:20px;padding-top:20px;">>
		Write $ZCVT($$$FormatText($$$Text("Unable to open message body %1 "),tHeader.MessageBodyClassName_" "_tHeader.MessageBodyId),"O","HTML")
		&html<</div>>
		Quit $$$OK
	}

	If '..Send { // first time through the page, SEND=0; allow edit
		&html<<div align="left" style="padding-left:20px;padding-top:20px;">>
		If ('..Suspended) { // Resend from the Message Viewer page
			Write $ZCVT($$$FormatText($$$Text("Edit the body of message %1 and press the Resend button to resend a new copy of the message"),tHdrId),"O","HTML")
		} Else { // Resubmit from the Suspended Messages page
			Write $ZCVT($$$FormatText($$$Text("Edit the body of message %1 and press the Resubmit button to resubmit the message with a new message body"),tHdrId),"O","HTML")
		}
		&html<</div><hr><div align="center" class="Text">>
		
		// set up arguments for the methods we are calling: buttons (tButtons), URL (tURL), and query parameters (tID)
		Set n = 1
		Set tButtons(n) = ##class(%CSP.Util.FormButton).%New()
		Set tButtons(n).Name = "$AUTOFORM_SAVE"
		If ('..Suspended) { // Resend
			Set tButtons(n).Caption = $$$LocalizeText("Ensemble","Resend","Resend") 
		}
		Else { // Resubmit
			Set tButtons(n).Caption = $$$LocalizeText("Ensemble","Resubmit","Resubmit") 
		}
		Set tButtons(n).OnClick = "zenPage.saveEdit();"
		Set n = n + 1
		Set tButtons(n) = ##class(%CSP.Util.FormButton).%New()
		Set tButtons(n).Name = "$AUTOFORM_CANCEL"
		Set tButtons(n).Caption = $$$LocalizeText("Ensemble","btnCancel","Cancel")
		If (..Suspended) { // Go back to Suspended Messages
			Set tButtons(n).OnClick = "self.document.location='EnsPortal.SuspendedMsg.zen';" 
		}
		Else { // Go back to Message Viewer
			Set tButtons(n).OnClick = "self.document.location='"_..viewerPage_"';" 
		}
		Set tURL = ..GetSubmitURL()
		Set tID(1) = tHdrId

		// call the appropriate method to write out an HTML form based on the type of message body
		If tOldBody.%Extends("Ens.Util.MessageBodyMethods") {
			Do tOldBody.%DrawHTMLForm(tOldBody, .tID, tURL, .tButtons)
		} Else {
			Do ##class(%CSP.Util.AutoFormDynamic).DrawHTMLForm(tOldBody, .tID, tURL, .tButtons)
		}
		
		If ('..Suspended) { // Resend
			Write $ZCVT($$$FormatText($$$Text("Resend a new copy of message header %1 containing this new message body"),tHdrId),"O","HTML")
		} 
		Else { // Resubmit
			Write $ZCVT($$$FormatText($$$Text("Resubmit message header %1 with this new body replacing its old body contents"),tHdrId),"O","HTML")
		}
	} 
	Else { // second time through the page, SEND=1; do (Re)Submit & report results
		Set tError = $$$Text("An error has occurred")

		#; get results of submit - note IRIS %ProcessSubmit methods do their own clone
		If tOldBody.%Extends("Ens.Util.MessageBodyMethods") {
			Set tID(1)=tHeader.MessageBodyId
			Set tObj = tOldBody.%ProcessSubmit(%request, .tID, .tErrMsg)
		} 
		Else {
			#; construct body clone and get an id for it
			Set tOldBody=tOldBody.%ConstructClone()
			If tOldBody.%IsA("%Library.Persistent") Set tSC=tOldBody.%Save()  Quit:$$$ISERR(tSC) tSC
			Set tSC=tOldBody.%GetSwizzleObject(0,.tOID)  Quit:$$$ISERR(tSC) tSC
			Set tID(1)=$$$oidPrimary(tOID)

			Set tObj = ##class(%CSP.Util.AutoFormDynamic).ProcessSubmit(%request, .tID, .tErrMsg, 0)
		}
		If '$IsObject(tObj) {
			&html<<div align="left" style="padding-left:20px;padding-top:20px;">>
			Write $$$Text("Unable to create new body object ")_tErrMsg,!
			&html<</div>>
			Quit $$$OK
		}
		Set tSC = tObj.%ValidateObject()  Quit:$$$ISERR(tSC) tSC

		Set tSC = ..PerformResend(tHeader,tObj,.tResentHeaderId,.tDescription)

		#; Prevent further resends on page reloading since SEND=1
		Do ..CleanUpIDs()

		If $$$ISERR(tSC) Quit tSC

		If $get(tResentHeaderId) {
			&html<
				<div align="center" style="padding-top:20px;">
					#(tDescription)#<hr/><br/><div style="cursor: pointer;" onclick="zenPage.showTrace(#(tResentHeaderId)#); return false;"><a>Trace</a></div>
				</div>
			>
		}
	}
	
	Quit $$$OK
}

Method PerformResend(pHeader As Ens.MessageHeaderBase, pNewBody As %RegisteredObject, Output pNewHeaderId As %String, Output pText) As %Status
{
	Set pText = ""
	If ('..Suspended) { // Resend - clone a new header for the message and send with the new header
		Set tSC = ##class(Ens.MessageHeader).ResendDuplicatedMessage(pHeader.%Id(),.pNewHeaderId,..NewTarget,.pNewBody,,..HeadOfQueue) 
		If $$$ISERR(tSC) Quit tSC
		Set tNewBodyId = $select($isobject($get(pNewBody)) : pNewBody.%Id(), $get(pNewBody): pNewBody, $get(pNewHeaderId): ##class(Ens.MessageHeader).MessageBodyIdGetStored(pNewHeaderId), 1: "")
		Set pText = $ZCVT($$$FormatText($$$Text("Copy of message %1 resent as message %2 to %3 with new edited body '%4'"),pHeader.%Id(),pNewHeaderId,$S(""'=..NewTarget:..NewTarget,1:pHeader.TargetConfigName),tNewBodyId),"O","HTML")
	}
	Else { // Resubmit - do not clone a new header for the message, resubmit the old header
		Set tSC = ##class(Ens.MessageHeader).ResubmitMessage(pHeader.%Id(),..NewTarget,pNewBody,..HeadOfQueue)
		If $$$ISERR(tSC) Quit tSC
		Set tNewBodyId = $select($isobject($get(pNewBody)) : pNewBody.%Id(), $get(pNewBody): pNewBody, 1: ##class(Ens.MessageHeader).MessageBodyIdGetStored(pHeader.%Id()))
		Set pText = $ZCVT($$$FormatText($$$Text("Message %1 resubmitted to %2 with new edited body '%3'"),pHeader.%Id(),pHeader.TargetConfigName,tNewBodyId),"O","HTML")
		Set pNewHeaderId = pHeader.%Id()
	}
	Quit $$$OK
}

/// This method is invoked when the user clicks OK on the automatically generated HTML form
/// from DrawHTMLFields(). It references fields on the form and submits the form.
/// Then it displays the URL provided when the form was created in DrawHTMLFields().
ClientMethod saveEdit() [ Language = javascript ]
{
/// Modified from the earlier CSP version of this page, which was IE-specific.
	// The input controls don't specify the id attribute, so we need to rely
	// on getElementsByName() to find the controls.
	var theForm = self.document.theForm;
	var contentCtrlList = self.document.getElementsByName('%XCONT');
	if (contentCtrlList && (contentCtrlList.length == 1)) {
		var contentCtrl = contentCtrlList[0];
		if (contentCtrl) {
			var formCtrlList = self.document.getElementsByName('$IDXCONT');
			if (formCtrlList && (formCtrlList.length > 0)) {
				for (var i=0; i < formCtrlList.length; i++) {
					var formCtrl = formCtrlList[i];
					if (formCtrl && (formCtrl.form == theForm)) {
						formCtrl.value = contentCtrl.value;
						break;
					}
				}
			}
		}
	}
	theForm.submit();
}

/// User clicked a link for Trace. Display the Visual Trace page in a popup,
/// so user can click the arrows to go from session to session without losing his/her place in the display.
ClientMethod showTrace(session) [ Language = javascript ]
{
	if (!this.canViewTrace) {
		alert(this.msgNotPermitted);
		return false;
	}
	if (session != '') {
		window.open(zenLink(this.messageTracePage + '?SESSIONID=' + encodeURIComponent(session)));
	}
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Message Edit and Resend","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	If ('..Suspended) { // Resend from Message Viewer
		Set pCommands(1) = $LB("cancelButton",$$$Text("Message Viewer"),$$$Text("Return to the Message Viewer page"),"zenPage.gotoPage(zenLink('EnsPortal.MessageViewer.zen'));")
	}
	Else { // Resubmit from Suspended Messages
		Set pCommands(1) = $LB("cancelButton",$$$Text("Suspended Messages"),$$$Text("Return to the Suspended Messages page"),"zenPage.gotoPage(zenLink('EnsPortal.SuspendedMsg.zen'));")
	}
	Quit $$$OK
}

/// Get rid of the global that has been storing the information about our chosen messages.
/// This happens only if we are truly done with this page.
Method CleanUpIDs() [ ZenMethod ]
{
	If (..Send = 1) && (..Key '= "") { // the second time through this page, Send=1 and we're ready to discard the key
		Kill ^IRIS.Temp.ResendIDs(..Key)
	}
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	zenPage.CleanUpIDs();
	return true;
}

}
