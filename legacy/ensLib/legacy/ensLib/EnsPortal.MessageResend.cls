/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUtil)

/// This is the page shown to confirm the actions of the Message Resend page of the ZEN application.
Class EnsPortal.MessageResend Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Message Resend";

/// User needs USE permissions on the %Ens_MessageResend resource to view this page.
Parameter RESOURCE = "%Ens_MessageResend:USE";

/// User needs USE permissions on the %Ens_MessageEditResend resource to edit and resend messages.
Parameter EDITRESOURCE = "%Ens_MessageEditResend:USE";

/// Maximum number of rows to display.
Parameter MAXDISPLAYROWS = 500;

/// Number of columns drawn in the result table.
/// This is used by some of the helper functions to add messages to the table.
Parameter TABLECOLUMNS = 7;

/// Name of the Assistant class to use for filtered results.
Parameter AssistantClass = "EnsPortal.MsgFilter.Assistant";

/// Numeric column of the resultset which contains the ID column.
Parameter IDColumn As INTEGER = 1;

/// Type of header messages.
Parameter MessageClass = "Ens.MessageHeader";

/// Name of the Filter class used for filtered results.
Property filterClass As %ZEN.Datatype.className [ InitialExpression = "EnsPortal.MsgFilter.Filter", ReadOnly ];

/// Index of ^IRIS.Temp.ResendIDs in use for this resend
Property Key As %ZEN.Datatype.string(ZENURL = "KEY");

/// Whether to use the current Filter to fetch more results.
Property UseFilter As %ZEN.Datatype.string(ZENURL = "FILTER");

Property VirtualKey As %ZEN.Datatype.integer [ InitialExpression = 0, Internal ];

/// Order in which to iterate over the messages.
Property SortOrder As %ZEN.Datatype.string(ZENURL = "SORT");

/// Number of messages to resend.
Property Number As %ZEN.Datatype.string(ZENURL = "NUM") [ InitialExpression = {..#MAXDISPLAYROWS} ];

Property NewTarget As %ZEN.Datatype.string;

/// Flag to indicate whether messages should be resent as the head of the queue.
Property HeadOfQueue As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property Messages As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Flag to indicate whether the user may view Trace messages.
Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageTrace","USE")} ];

/// Flag to indicate whether the user may view Header data.
Property canViewHeaders As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageHeader","USE")} ];

/// Flag to indicate whether the user may view message contents.
Property canViewContents As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageContent","USE")} ];

/// Flag to indicate whether the user may view Queue information.
Property canViewQueues As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_Queues","READ")} ];

/// Page to use for displaying message content.
Property messageDisplayPage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.Dialog.MessageBodyDisplay.zen" ];

/// Page to use for displaying the results of the resend.
Property resendResultPage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.MessageResendAfter.zen" ];

/// Page for displaying the visual trace.
Property messageTracePage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.VisualTrace.zen" ];

/// Page for editing and resending messages.
Property editResendPage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.MessageResendEdit.zen" ];

Property viewerPage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.MessageViewer.zen" ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for table */
#table {
	overflow: auto;
}

/* slight adjustments to tpTable */
table.tpTable {
	padding-top: 5px;
	border: none;
}

table.tpTable tr.tpSelected td {
	font-weight: bold;
}

/* styles for message details */
table.AutoFormTable {
	color: #606060;
	background: white;
	border: 1px solid black;
	padding: 0px;
	font-size: 12px;	
}

table td.AutoFormTableCaption {
	font-weight: bold;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

table td.AutoFormTableValue {
	border-bottom: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

a {
	text-decoration: none;
	color: #3b84bc;
}
#errorMessages, #warningMessages {
	padding-left: 20px;
}
#warningMessages {
	padding-top: 20px;
}
.errorMessage {
	color: darkred;
	font-weight: bold;
}
.warningMessage {
	font-weight: bold;
}
.ribbonText {
	font-size: 0.8em;
	color:#404040;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" valign="top">
<spacer height="10" />
<html id="errorMessages" hidden="true" />
<html id="resendTable" OnDrawContent="DrawHTMLFields" valign="top"/>
<html id="warningMessages" hidden="true" />
</pane>
}

/// Update the details for a selected message.
ClientMethod showHeader(messageId) [ Language = javascript ]
{
	if (!this.canViewHeaders) {
		alert(this.msgNotPermitted);
		return false;
	}
	var url = this.messageDisplayPage + "?SHOW=header&ID=" + messageId;
	zenLaunchPopupWindow(zenLink(url),'','status,scrollbars,resizable=yes,width=600,height=600');
}

/// Update the details for a selected message.
ClientMethod showBody(messageId) [ Language = javascript ]
{
	if (!this.canViewContents) {
		alert(this.msgNotPermitted);
		return false;
	}
	var url = this.messageDisplayPage + "?SHOW=body&ID=" + messageId;
	zenLaunchPopupWindow(zenLink(url),'','status,scrollbars,resizable=yes,width=600,height=600');
}

/// Write out contents of details panel.
/// <var>pID</var> is the message id.
Method DrawDetailsContent(pID As %String) As %Status
{
	If ""=pID { 
		Quit $$$OK
	}
	Else {
		Quit ##class(EnsPortal.Utils).DrawItemDetails(pID,..#MessageClass)
	}
}

/// Write out contents of body details panel.
/// <var>pHeaderID</var> is the message id.
Method DrawBodyInfo(pHeaderID As %String) As %Status
{
	If ""=pHeaderID { 
		Quit $$$OK
	}
	Else {
		Quit ##class(EnsPortal.Utils).DrawBodyInfo(pHeaderID,..#MessageClass)
	}
}

/// Provide HTML for selected messages.
Method DrawHTMLFields(tSessionId As %String) As %Status
{
	If '..Messages Quit $$$OK

	Set tBelow = $$$Text("The following is a list of messages that will be resent when you click Resend on this page.")
	Set tH1 = $$$TextHTML("Session")
	Set tH2 = $$$TextHTML("Header")
	Set tH3 = $$$TextHTML("Body")
	Set tH4 = $$$TextHTML("Created")
	Set tH5 = $$$TextHTML("Source")
	Set tH6 = $$$TextHTML("Original Target") 
	Set tH7 = $$$TextHTML("Resend Target") 
	&html<
		<div style="margin-left: 20px;margin-top:10px;margin-bottom:10px;">#(tBelow)#</div>
		<div style="margin-left: 20px;">
		<table class="tpTable" style="border: 1px solid lightgray" border=1 cellpadding=4 cellspacing=0>
		<tr><th>#(tH1)#</th><th>#(tH2)#</th><th>#(tH3)#</th><th>#(tH4)#</th><th>#(tH5)#</th><th>#(tH6)#</th><th>#(tH7)#</th></tr>
	>
	
	Set tBadTargs = 0
	Set tBadHdrs = 0
	Set tResendCount = +$get(^IRIS.Temp.ResendIDs(..Key))
	Set msgNoTarget = $ZCVT($$$LocalizeText("Ensemble","msgNoTarget","Target Not Running"),"O","HTML")
	Set tSQL = "SELECT SessionId, MessageBodyId, MessageBodyClassname, SourceConfigName, TargetConfigName, TimeCreated "
	Set tSQL = tSQL _ "FROM Ens.MessageHeader WHERE ID = ?"
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tStatus = tStatement.%Prepare(tSQL)
	If $$$ISERR(tStatus) Quit tStatus
	Set tNewestFirst = $classmethod(..filterClass,"SortOrderDisplayToLogical","Newest First")
	Set msgid=""
	For i=1:1 { 
		Set msgid = $order(^IRIS.Temp.ResendIDs(..Key, msgid),$select(..SortOrder = tNewestFirst: -1, 1: 1))
		Quit:(msgid = "")

		Set tRS = tStatement.%Execute(msgid)
		Do tRS.%Next()
		Set tOddEven = $select(i#2: "tpOdd", 1: "tpEven")
		If tRS.%SQLCODE {
			If 'tBadHdrs {
				Set tBadHdrs("msgid")=""
				Set tBadHdrs("SQLCODE")=tRS.%SQLCODE
			}
			Set tBadHdrs=tBadHdrs+1
			If i<=..#MAXDISPLAYROWS {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Message header "_msgid_" not found; SQLCODE="_tRS.%SQLCODE)
				Set tErrorText=$system.Status.GetErrorText(tSC)
				Do ..WriteInlineMessage(tErrorText,,tOddEven)
			}
		} 
		Else {
			Set tBodyId=$S(""=tRS.MessageBodyId:"&nbsp;",1:$ZCVT(tRS.MessageBodyId,"O","HTML"))
			Set tTarget = tRS.TargetConfigName
			Set tQName=$G($$$ConfigQueueName(tTarget))
			If tQName="" {
				Set:'tBadTargs tBadTargs("msgid")=msgid
				Set tBadTargs("targ",tTarget)="",  tBadTargs=tBadTargs+1, tQLink=""
				Set:i<=..#MAXDISPLAYROWS tTarget="<span class=""errorMessage"">"_msgNoTarget_" ("_tTarget_")</span>"
			} 
			Else {
				Set:i<=..#MAXDISPLAYROWS tQLink=" href=""#"" onclick=""zenPage.launchQueue('"_$zconvert(tQName,"O","JS")_"'); return false;"""
				
			}
			If i<=..#MAXDISPLAYROWS {
				&html<
					<tr class="#(tOddEven)#">
					<td><a target="_blank" href="#" onclick="zenPage.showTrace(#(tRS.SessionId)#); return false;">#(tRS.SessionId)#</a></td>
					<td><a target="_blank" href="#" onclick="zenPage.showHeader(#(msgid)#); return false;">#(msgid)#</a></td>
					<td><a target="_blank" href="#" onclick="zenPage.showBody(#(msgid)#); return false;">#(tBodyId)#</a></td>
					<td>#($P($classmethod(..#MessageClass,"TimeCreatedLogicalToDisplay",tRS.TimeCreated),"."))#</td>
					<td>#(tRS.SourceConfigName)#</td>
					<td id='targ_#(i)#'><a target="_blank" #(tQLink)#>#(tTarget)#</a></td>
					<td id='narg_#(i)#'><b><a target="_blank" #(tQLink)#>#(tTarget)#</a></b></td>
					</tr>
				>
			}
		}
	}
	
	Set tMessageRow = i
	If i > ..#MAXDISPLAYROWS {
		Set tMaxDisplay = $$$FormatText($$$Text("Cannot display more than %1 rows, but all %2 matching messages will be resent"),..#MAXDISPLAYROWS,tResendCount)
		Do ..WriteInlineMessage(tMaxDisplay,"warning")
	}
	If tBadHdrs {
		Set tOddEven = $select(tMessageRow#2: "tpOdd", 1: "tpEven")
		Set tMessageRow = tMessageRow + 1
		Set msgBadHeaders = $$$FormatText($$$Text("%1 message headers could not be found, starting with Header #%2; SQLCODE=%3","Ensemble"),tBadHdrs,tBadHdrs("msgid"),tBadHdrs("SQLCODE"))
		Do ..WriteInlineMessage(msgBadHeaders)
	}
	If tBadTargs {
		Set (tBadTargsList,kbt)="" 
		For {
			Set kbt=$O(tBadTargs("targ",kbt))
			Quit:""=kbt
			Set tBadTargsList=tBadTargsList_","_kbt 
		}
		Set tBadTargsList=$E(tBadTargsList,2,*)
		Set msgBadTargets = $$$FormatText($$$Text("%1 messages had non-running targets (%2), starting with Header #%3.","Ensemble"),tBadTargs,tBadTargsList,tBadTargs("msgid"))
		Do ..WriteInlineMessage(msgBadTargets)
	}
	&html<</table>
		</div>>
	
	Quit $$$OK
}

ClassMethod WriteInlineMessage(pText As %String = "", pType As %String = "error", pRowClass As %String = "", pCols As %Integer = {..#TABLECOLUMNS}) [ Private ]
{
	&html<<tr#($select(pRowClass'="": " class="""_pRowClass_"""", 1:""))#><td colspan="#(pCols)#"><span class="#(pType)#Message">#($zcvt(pText,"O","HTML"))#</span></td></tr>>
	Quit
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

/// User clicked a link for a Config item. Show the queues page sorted for that queue.
ClientMethod launchQueue(name) [ Language = javascript ]
{
	if (!this.canViewQueues) {
		alert(this.msgNotPermitted);
		return false;
	}
	parms = {
		QUEUE:encodeURIComponent(name)
	}
	zenLaunchPopupWindow(zenLink("EnsPortal.Queues.zen"),'','status,scrollbars,resizable=yes,width=900,height=900',parms);
}

/// Resend the messages and then display the Confirm Resend page.
ClientMethod resendMessages() [ Language = javascript ]
{
	if (zenPage.Key != "") {
		var ret = zenPage.ReallyResend();
		if (ret != "") alert(ret);
		var url = this.resendResultPage + "?KEY=" + zenPage.Key + "&NUM=" + zenPage.Number;
		if (zenPage.HeadOfQueue) url = url + "&HEAD=1"; 
		else url = url + "&HEAD=0"; 
		zenPage._keepTempKey = true;
		zenPage.gotoPage(zenLink(url));
	}
}

Method ReallyResend() As %String [ ZenMethod ]
{
	Set error = 0
	Set tDirection = $select(..HeadOfQueue: -1, 1: 1)
	Set tMsgId = ""
	For {
		Set tMsgId = $order(^IRIS.Temp.ResendIDs(..Key,tMsgId),tDirection)
		Quit:(tMsgId = "")
		// When NewTarget is blank the old target is used
		Set tSC=##class(Ens.MessageHeader).ResendDuplicatedMessage(tMsgId,.tNewHeaderId,..NewTarget,,,..HeadOfQueue)
		If ($$$ISERR(tSC)) {
			Set errText = $System.Status.GetErrorText(tSC)
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"sc") = errText
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"new") = ""
			If (errText [ "ErrProductionNotRunning") { Set error = 1 }
			Else { If (error '= 1) { Set error = 2 } }
		}
		Else {
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"sc") = "OK"
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"new") = tNewHeaderId
		}
	}
	If (error = 1) { Quit $$$Text("Could not resend messages because no production is running.") }
	ElseIf (error = 2) { Quit $$$Text("Could not resend all messages; check Resend Status on the next page for results.") }
	Else { Quit "" }
}

/// Set the NewTarget property of the page based on the value in the "New target" drop-down list.
ClientMethod chooseTarget() [ Language = javascript ]
{
	// this <select> is HTML, in the ribbon bar, so get it via the document object
	sel = self.document.getElementById('targetChoice'); 
	if (sel.value != "") {
		zenPage.NewTarget = sel.value; // use the new value
		for (var i = 1; i <= zenPage.Number; i++) { // make the new target column
			targ = self.document.getElementById('targ_' + i);
			narg = self.document.getElementById('narg_' + i);
			if (targ && narg) { 
				narg.innerHTML = '<b><a target="blank" href="#" onclick="zenPage.launchQueue(\'' + zenPage.NewTarget + '\'); return false;">' + zenPage.NewTarget + '</a></b>';
			}
		}
	}
	else { // reset the target properties of the page
		alert($$$Text("Messages will be sent to their original targets."));
		sel.value = ""; // reset in case user cancelled out
		zenPage.NewTarget = ""; // reset for every case
		for (var i = 1; i <= zenPage.Number; i++) { // make the new target column
			targ = self.document.getElementById('targ_' + i);
			narg = self.document.getElementById('narg_' + i);
			if (targ && narg && targ.innerHTML) {
				narg.innerHTML = '<b>' + targ.innerHTML + '</b>';
			}
		}
	}
}

/// Set the HeadOfQueue property of the page based on the value in the "Resubmit at head of queue" checkbox.
ClientMethod chooseHead() [ Language = javascript ]
{
	// this <input> is HTML, in the ribbon bar, so get it via the document object
	zenPage.HeadOfQueue = document.getElementById('HeadOfQueue').checked;
	if (zenPage.HeadOfQueue == true) alert($$$Text("Resent messages will be placed at the head of the queue."));
	else alert($$$Text("Resent messages will be placed at the end of the queue."));
}

ClientMethod cancelPage() [ Language = javascript ]
{
	zenPage.gotoPage(zenLink(this.viewerPage));
}

ClientMethod editResend() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	if (parseInt(zenPage.Number) != 1) {
		if (confirm($$$Text('You must select only one item to edit before resending. Do you wish to return to the message viewer page to choose a message now?'))) {
			zenPage.gotoPage(zenLink(this.viewerPage));
		}
	}
	else { // go to the message edit and resend page for the first time through (SEND not defined)
		var url = this.getEditURL();
		zenPage._keepTempKey = true;
		zenPage.gotoPage(url);
	}
}

ClientMethod getEditURL() [ Language = javascript ]
{
	var url = this.editResendPage + '?KEY=' + this.Key;
	if (this.NewTarget.length > 0) {
		url += '&TARGET=' + this.NewTarget;
	}
	url += '&HEAD=' + (this.HeadOfQueue ? 1 : 0);
	return url;
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Resend Messages","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cancelButton",$$$Text("Cancel"),$$$Text("Cancel and do not resend these messages"),"zenPage.cancelPage();")
	Set pCommands(2) = $LB("okButton",$$$Text("Resend"),$$$Text("Resend the messages represented in this display"),"zenPage.resendMessages();")
	Set pCommands(3) = $LB("editButton",$$$Text("Edit and Resend"),$$$Text("For a single message, you may edit before resending"),"zenPage.editResend();")
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Set tProduction = $G($$$EnsRuntime("Name"))
	If ""'=tProduction {
		&html<
		<td nowrap="1" style="padding-left:50px;">
		<div nowrap="1">
			<span class="ribbonText">#($$$Text("New target:"))#</span>
			<select id="targetChoice" type="select" name="targetChoice" onchange="zenPage.chooseTarget();">
				<option value="" ></option>
			>
		// List all config items that are not business services
		Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateConfigItems")
		Do tRS.Execute(tProduction,-$$$eHostTypeService,0)
		While (tRS && tRS.Next()) {
			Set tConfigName = $G(tRS.Data("ConfigName"))
			&html<
				<option value="#(tConfigName)#" >#(tConfigName)#</option>
			>
		}
		&html<
			</select>
			<span class="ribbonText" style="padding-left:20px;">#($$$Text("Resubmit at head of queue:"))#</span>
			<input type="checkbox" id="HeadOfQueue" name="HeadOfQueue" onclick="zenPage.chooseHead();"/>
		</div></td>
		>
	}
	Quit $$$OK
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set pLink(2)=$LB(..%OnGetPageName(),"#")
	Quit $$$OK
}

Method CleanUpIDs() [ ZenMethod ]
{
	If ..Key '= "" {
		Kill ^IRIS.Temp.ResendIDs(..Key)
	}
}

/// Ensure that tab behaviour is initialised correctly.
ClientMethod onloadHandler() [ Language = javascript ]
{
	var virtID = window.sessionStorage.getItem('EnsVirtualSessionKey');
	this.VirtualKey = (virtID && (""!=virtID) && !isNaN(virtID) && (parseInt(Number(virtID),10)==virtID)) ? virtID : 0;
	var statusText = this.PrepareResults();
	if (statusText != '') {
		alert(statusText);
		return false;
	}
	
	var table = zen('resendTable');
	if (table) {
		table.refreshContents();
	}
	
	return this.invokeSuper('onloadHandler',[]);
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if ((zenPage.Messages) && (!zenPage._keepTempKey)) zenPage.CleanUpIDs();
	return true;
}

Method AddMessage(pNewMessage As %String = "", pType As %String = "error", pClearOldMessage As %Boolean = 1, pClass As %String = "") As %String [ ZenMethod ]
{
	Set tContentDiv = ..%GetComponentById(pType_"Messages")
	If $IsObject(tContentDiv) {
		If pNewMessage = "" {
			Set tContentDiv.content = ""
			Set tContentDiv.hidden = 1
		}
		Else {
			Set tNewContent = "<div class="""_$select(pClass = "": "", 1: pClass_" ")_pType_"Message"">" _ $zcvt(pNewMessage,"O","HTML")_"</div>"
			Set tContentDiv.content = $select(pClearOldMessage: "", 1: tContentDiv.content) _ tNewContent
			Set tContentDiv.hidden = 0
		}
	}
	Quit ""
}

/// Perform any processing based on the incoming request.
Method PrepareResults() As %String [ ZenMethod ]
{
	Set tProduction = $G($$$EnsRuntime("Name"))
	If ""=tProduction {
		Set ..Messages = 0
		Set msgCantResend = $$$LocalizeText("Ensemble","msgCantResend","Cannot resend - Production not running.")
		Do ..AddMessage(msgCantResend,"error",1)
		Do ..CleanUpIDs()
		Quit ""
	} 
	
	Set tSC = $$$OK
	Try {
		Set tResendCount = 0
		If (..UseFilter = 1) && (..Key = "") {
			Set tSC = $classmethod(..filterClass,"LoadFromVirtualSession",..VirtualKey, .tFilter)
			If $$$ISERR(tSC) Quit
		
			Set tSC = $classmethod(..#AssistantClass,"GetResultSet", tFilter, .tRS)
			If $$$ISERR(tSC) Quit
		
			Set ..Key = $increment(^IRIS.Temp.ResendIDs)
			While tRS.Next() {
				Set tID = tRS.GetData(..#IDColumn)
				Set tTimeCreated = tRS.Get("TimeCreated")
				If tTimeCreated = "" Continue
				Set ^IRIS.Temp.ResendIDs(..Key, tID) = ""
				Set tResendCount = tResendCount + 1
			}
			Set ^IRIS.Temp.ResendIDs(..Key) = tResendCount
			If tFilter.TopCount && (tResendCount = tFilter.TopCount) {
				Set tTopReached = $$$FormatText($$$Text("Reached TOP limit of %1"),tFilter.TopCount)
				Do ..AddMessage(tTopReached,"warning",0)
			}
		}
	
		If (..Key = "") || (..Key <= 0) || ('$data(^IRIS.Temp.ResendIDs)) || ('$data(^IRIS.Temp.ResendIDs(..Key))) {
			Set ..Messages = 0
			Set tNoMessages = $$$Text("Cannot redisplay your message list - click Cancel to return to the Message Viewer.")
			Do ..AddMessage(tNoMessages,"error",0)
			Quit
		}
		
		If (tResendCount = 0) {
			Set tResendCount = +$get(^IRIS.Temp.ResendIDs(..Key))
		}
		
		Set ..Messages = (tResendCount > 0)

		If tResendCount < ..#MAXDISPLAYROWS {
			Set ..Number = tResendCount
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do ..CleanUpIDs()
		Set ..Messages = 0
		Do ..AddMessage($system.Status.GetErrorText(tSC),"error",0)
	}
	Quit $S($$$ISERR(tSC):$System.Status.GetErrorText(tSC),1:"")
}

}
