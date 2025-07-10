/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.MessageResend Extends (EnsPortal.MessageResend, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Message Bank Resend";

/// User needs USE permissions on the %Ens_MsgBank_MessageResend resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageResend:USE";

/// User needs USE permissions on the %Ens_MsgBank_MessageEditResend resource to edit and resend messages.
Parameter EDITRESOURCE = "%Ens_MsgBank_MessageEditResend:USE";

/// Number of columns drawn in the result table.
/// This is used by some of the helper functions to add messages to the table.
Parameter TABLECOLUMNS = 9;

/// Name of the Assistant class to use for filtered results.
Parameter AssistantClass = "Ens.Enterprise.Portal.MsgFilter.Assistant";

/// Numeric column of the resultset which contains the ID column.
Parameter IDColumn As INTEGER = 2;

/// Type of header messages.
Parameter MessageClass = "Ens.Enterprise.MsgBank.MessageHeader";

/// Flag to indicate whether the user may view Trace messages.
Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageTrace","USE")} ];

/// Flag to indicate whether the user may view Header data.
Property canViewHeaders As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageHeader","USE")} ];

/// Flag to indicate whether the user may view message contents.
Property canViewContents As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageContent","USE")} ];

/// Flag to indicate whether the user may view Queue information. There are no queues in the Message Bank archive.
Property canViewQueues As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Page to use for displaying message content.
Property messageDisplayPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.Dialog.MessageBodyDisplay.zen" ];

/// Page to use for displaying the results of the resend.
Property resendResultPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.MessageResendAfter.zen" ];

/// Page for displaying the visual trace.
Property messageTracePage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.VisualTrace.zen" ];

/// Page for editing and resending messages.
Property editResendPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.MessageResendEdit.zen" ];

Property viewerPage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.MsgBankViewer.zen" ];

/// All available Clients listed by client name.
Property clients As array Of %ZEN.proxyObject;

/// Index of node ID to client name.
Property nodeIndex As array Of %String;

/// Multidimensional array used to cache known targets while drawing the contents of the table.
Property %Targets As %String [ MultiDimensional, ServerOnly = 1 ];

/// Flag to indicate whether Individual Targeting is in use.
Property doIndividual As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Flag to indicate whether Collective Targeting is in use.
Property doCollective As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Name of the Targeting class to use.
Property targetingClass As %ZEN.Datatype.className;

/// Name of the new config item to resend messages to.
/// <property>NewTarget</property> is overriden to refer to the target client.
Property newTargetConfig As %ZEN.Datatype.string;

/// Name of the Filter class used for filtered results.
Property filterClass As %ZEN.Datatype.className [ InitialExpression = "Ens.Enterprise.Portal.MsgFilter.Filter", ReadOnly ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.errorMessage.topWarning {
	color: black;
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
<jsonProvider id="clientData" OnRenderJSON="RenderClientData" />
</pane>
}

ClientMethod showNodeHomePage(nodeName) [ Language = javascript ]
{
	var opened = false;
	if (nodeName) {
		var client = this.getClient(nodeName);
		if (client && client.link && (client.link != '')) {
			opened = window.open(link);
		}
	}
	if (!opened) {
		alert($$$FormatText($$$Text("Unable to open portal for node '%1'"),nodeName));
	}
}

/// Get the named client data.
ClientMethod getClient(nodeName) [ Language = javascript ]
{
	var clientData = zen('clientData');
	return (clientData && clientData.content) ? clientData.content[nodeName] : null;
}

/// Represent the client array using JSON.
Method RenderClientData(ByRef pParameters As %String) As %Status
{
	Write "{"
	Set tCount = 0
	Set tKey = ""
	For {
		Set tClientData = ..clients.GetNext(.tKey)
		Quit:(tKey = "")
		Set tCount = tCount + 1
		Write !,$select(tCount>1: ",", 1:"")_""""_tKey_""": {""link"": '"_tClientData.link_"', ""productionName"": '"_tClientData.productionName_"', ""namespace"": '"_tClientData.namespace_"', ""webAddress"": '"_tClientData.webAddress_"' }"
	}
	Write !,"}"
	Quit $$$OK
}

/// Build the list of available clients and nodes.
Method BuildClientData() As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..clients.Clear()
		Do ..nodeIndex.Clear()
		
		Set tCounter = 0
		Set tLinkState = ##class(%SQL.Statement).%New()
		Set tSC = tLinkState.%Prepare("SELECT SOAPCredentials, SSLConfig FROM Ens_Enterprise.MonitorClient WHERE Name = ?")
		If $$$ISERR(tSC) Quit
		
		Set tModelRS = ##class(%Library.ResultSet).%New("Ens.Enterprise.Portal.MonitorModel:getMatrix")
		Set tSC = tModelRS.Execute()
		If $$$ISERR(tSC) Quit
		
		Set tRunning = $ZCVT(##class(EnsPortal.Utils).resolveProductionStateName($$$eProductionStateRunning),"L")
		Set tRunningLen = $length(tRunning)
		// Columns: Color,ClientName,QueueCount,Status,ProductionName,SystemSpecs,StartTime,UpdateReason,WebIPAddress,Namespace,HomePage,HomePath,Version,QueueThreshold
		While tModelRS.Next() {
			If $case($zconvert($extract(tModelRS.Get("Status"),1,tRunningLen),"L"), tRunning: 1, : 0) {
				Set tClientName = tModelRS.Get("ClientName")
				Set tWebAddress = tModelRS.Get("WebIPAddress")
				Set tNamespace = tModelRS.Get("Namespace")
				Set tHomePath = tModelRS.Get("HomePath")
				If tHomePath = "" {
					Set tHomePath = "/csp/"_$zconvert(tNamespace,"L")_"/"
				}
				Set tHomePage = tModelRS.Get("HomePage")
				If tHomePage = "" {
					Set tHomePage = "UtilEnsHome.csp"
				}
				Set tLink = ""
				Set tLinkRS = tLinkState.%Execute(tClientName)
				If tLinkRS.%Next() {
					Set tLink = "http"_$select(tLinkRS.SSLConfig '= "": "s", 1:"")_"://"_tWebAddress_tHomePath_tHomePage
				}
				Set tProxy = ##class(%ZEN.proxyObject).%New()
				Set tProxy.link = tLink
				Set tProxy.productionName = tModelRS.Get("ProductionName")
				Set tProxy.namespace = tNamespace
				Set tProxy.webAddress = tWebAddress
				Do ..clients.SetAt(tProxy,tClientName)
			}
		}
		Kill tModelRS,tLinkRS
		
		// Find the NodeId(s) for each running server
		Set tClientRS = ##class(%Library.ResultSet).%New("Ens.Enterprise.MonitorClient:EnumerateClients")
		Set tSC = tClientRS.Execute()
		If $$$ISERR(tSC) Quit
		// Columns: ID,IsNode,Name,NodeId,WebIPAddress,Namespace,SOAPCredentials,SSLConfig
		While tClientRS.Next() {
			If ..clients.IsDefined(tClientRS.Get("Name")) {
				Set tNodeIds = tClientRS.Get("NodeId")
				For iNode=1:1:$L(tNodeIds,",") {
					Set tNodeId = $P(tNodeIds,",",iNode)
					Continue:("" = tNodeId)
					Do ..nodeIndex.SetAt(tClientRS.Get("Name"), tNodeId)
				}
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Build the list of available config items for a given client.
/// <var>pUpdateClient</var> indicates whether the update should be sent to the client
/// using Javascript or whether data should be stored in the multidimensional <property>%Targets</property>
/// property while displaying the table on the server.
Method BuildItemData(pClientName As %String, pUpdateClient As %Boolean = 0) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tOpened = 0
	Try {
		If pUpdateClient {
			&js<if (!zenPage._configItems) zenPage._configItems = {};>
		}
		If $get(pClientName) '= "" {
			Set tRS = ##class(%Library.ResultSet).%New("Ens.Enterprise.Portal.MonitorModel:getMatrixDetails")
			Set tSC = tRS.Execute(pClientName)
			If $$$ISERR(tSC) Quit
			Set tServiceType = ##class(EnsPortal.Utils).resolveHostType($$$eHostTypeService)
			If pUpdateClient {
				Write "zenPage._configItems['",$zcvt(pClientName,"O","JS"),"'] = {",!
				Set tOpened = 1
				Set tFirst = 1
			}
			While tRS.Next() {
				If tRS.Get("HostType") '= tServiceType { ; exclude services
					Set tName = tRS.Get("Name")
					If pUpdateClient {
						If tName '= "" Write $select(tFirst: "", 1:",")," """,$zcvt(tName,"O","JS"),""": ''"
						Set tFirst = 0
					}
					Else {
						Set ..%Targets(pClientName,tName) = ""
					}
				}
			}
			If 'pUpdateClient Set ..%Targets(pClientName) = ""
		}
	}
	Catch ex {
		Set tSC = $$$EnsSystemError
	}
	If tOpened Write "};",!
	If $$$ISERR(tSC) {
		Quit $system.Status.GetErrorText(tSC)
	}
	Quit ""
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = ..BuildClientData()
	If $$$ISERR(tSC) Quit tSC
	
	Set tCallbackClass = ""
	Set tIndividual = 0
	Set tCollective = 0
	Set tTargetSC = ##class(Ens.Enterprise.MsgBank.Targeting).GetCurrentConfig(.tCallBackClass,.tIndividual,.tCollective,.tIsValid)
	If $$$ISERR(tTargetSC) {
		Set tErrorText = $$$FormatText($$$Text("Error loading Targeting configuration: '%1'"),$system.Status.GetErrorText(tTargetSC))
		Do ..AddMessage(tErrorText,,0)
	}
	Else {
		Set ..targetingClass = tCallBackClass
		Set ..doCollective = tCollective
		Set ..doIndividual = tIndividual
	
		If $$$ISERR($get(tIsValid,$$$OK)) {
			Set tValidText = $$$FormatText($$$Text("Targeting configuration is not completely valid: %1"),$system.Status.GetErrorText(tIsValid))
			Do ..AddMessage(tValidText,,0,"topWarning")
		}
		
		If (..targetingClass '= "") {
			If (..doCollective || ..doIndividual) {
				Set tInUseMsg = $$$FormatText($$$Text("Targeting class '%1' is in use:"),..targetingClass)
				Do ..AddMessage(tInUseMsg,,0,"topWarning")
				If ..doIndividual {
					Set tIndivMsg = $$$Text("Messages will be targeted individually.")
					Do ..AddMessage(tIndivMsg,,0,"topWarning")
				}
				If ..doCollective {
					Set tCollectiveMsg = $$$Text("Messages will be targeted collectively.")
					Do ..AddMessage(tCollectiveMsg,,0,"topWarning")
				}
			}
			Else {
				Set tNoTargeting = $$$Text("Targeting is not configured for messages.")_" "_$$$Text("Targeting will not be used.")
				Do ..AddMessage(tNoTargeting,,0)
			}
		}
	}

	Quit tSC
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
	Set tH5 = $$$TextHTML("Original Client")
	Set tH6 = $$$TextHTML("Source")
	Set tH7 = $$$TextHTML("Original Target")
	Set tH8 = $$$TextHTML("New Target") 
	Set tH9 = $$$TextHTML("New Client")
	&html<
		<div style="margin-left: 20px;margin-top:10px;margin-bottom:10px;">#(tBelow)#</div>
		<div style="margin-left: 20px;">
		<table class="tpTable" style="border: 1px solid lightgray" border=1 cellpadding=4 cellspacing=0>
		<tr><th>#(tH1)#</th><th>#(tH2)#</th><th>#(tH3)#</th><th>#(tH4)#</th><th>#(tH5)#</th><th>#(tH6)#</th><th>#(tH7)#</th><th class="newTargCol">#(tH8)#</th><th class="newCliCol">#(tH9)#</th></tr>
	>
	
	Set tBadTargs = 0
	Set tBadHdrs = 0
	Set tResendCount = +$get(^IRIS.Temp.ResendIDs(..Key))
	Set msgNoTarget = $$$TextHTML("Target Not Running")
	Set tSQL = "SELECT NodeId, (SELECT Name FROM Ens_Enterprise_MsgBank.Node Where ID = NodeId) As Node, ClientSessionId, "
	Set tSQL = tSQL _ "SessionId, MessageBodyId, MessageBodyClassname, SourceConfigName, TargetConfigName, TimeCreated "
	Set tSQL = tSQL _ "FROM Ens_Enterprise_MsgBank.MessageHeader WHERE ID = ?"
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tStatus = tStatement.%Prepare(tSQL)
	If $$$ISERR(tStatus) Quit tStatus
	Set tExpectedTarget = 0
	Set tOnlyOneTarget = 1
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
				Set tBadHdrs("msgid")=msgid
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
			Set tBodyId = $select(""=tRS.MessageBodyId: "&nbsp;", 1: $ZCVT(tRS.MessageBodyId,"O","HTML"))
			Set tOrigNodeId = tRS.%Get("NodeId")
			Set tOrigNode = $select(tOrigNodeId: $get(^Ens.MsgBankSvr("nodemap",tOrigNodeId)), 1: "")
			Set tOrigNodeContent = $select(""'=tOrigNode:"<b>"_tOrigNode_"</b><br/>(<i>+"_tOrigNodeId_":"_tRS.%Get("Node")_"</i>)", 1:"+"_tOrigNodeId_":"_tRS.%Get("Node"))
			Set tOrigTargetItem = tRS.TargetConfigName
			Set tTargetItem = tOrigTargetItem
			// Check whether we know where similar messages were sent
			Set tTargetNode = $get(tTargetQNode(tOrigNodeId,tOrigTargetItem))
			If ..doIndividual {
				Set tSC = $classmethod(..targetingClass,"IndividualMessage",msgid,.tNewTargNode,.tNewTargItem)
				If $$$ISERR(tSC) {
					Set tErrorText = $$$FormatText($$$Text("Error in '%1' callback for Targeting class '%2': %3"),"IndividualMessage",..targetingClass,$system.Status.GetErrorText(tSC))
					Do ..WriteInlineMessage(tErrorText,,tOddEven)
					Continue   ; next message
				}
				If ($g(tNewTargNode)'="")&&(tNewTargNode'=tTargetNode) Set tTargetNode = tNewTargNode
				If ($g(tNewTargItem)'="")&&(tNewTargItem'=tOrigTargetItem) Set tTargetItem = tNewTargItem
			}
			If ""=tTargetNode {
				Set tTargetNode = ..FindTargetNode(tOrigNodeId,tTargetItem)
			}
			ElseIf tTargetNode = +tTargetNode { // Only call FindTargetNode if tTargetNode is still a node ID
				Set tTargetNode = ..FindTargetNode(tTargetNode,tTargetItem)
			}
			Set tTargetQNode(tOrigNodeId,tOrigTargetItem) = tTargetNode
			If (tTargetNode '= "") && (tTargetNode '= tOrigNode) && (tTargetNode '= 0) {
				Set ^IRIS.Temp.ResendIDs(..Key,msgid,"newnode") = tTargetNode_"|"
			}
			If tTargetItem '= "" {
				Set $P(^IRIS.Temp.ResendIDs(..Key,msgid,"newnode"),"|",2) = tTargetItem
			}
			
			Set tUnknownNode = 0
			If tTargetNode=0 {
				If 'tBadTargs Set tBadTargs("msgid")=msgid
				Set tBadTargs("targ","+"_tOrigNodeId_":"_tTargetItem)="", tBadTargs=tBadTargs+1
				If i <= ..#MAXDISPLAYROWS {
					Set tUnknownNode = 1
					Set tTargetItem=""
					Set tTargetNode="<span class=""errorMessage"">"_msgNoTarget_"</span>"
				}
			}
			If tOnlyOneTarget && (tTargetItem'=$g(tExpectedTarget("item"))) {
				If tExpectedTarget > 0 {
					Set tOnlyOneTarget = 0
					Kill tExpectedTarget("item")
				}
				Else {
					Set tExpectedTarget = tExpectedTarget+1
					Set tExpectedTarget("item")=tTargetItem
				}
			}
			If i <= ..#MAXDISPLAYROWS {
				&html<<tr class="#(tOddEven)#">
					<td><a target="_blank" href="#" onclick="zenPage.showTrace(#(tRS.SessionId)#); return false;">#(tRS.SessionId)#</a></td>
					<td><a target="_blank" href="#" onclick="zenPage.showHeader(#(msgid)#); return false;">#(msgid)#</a></td>
					<td><a target="_blank" href="#" onclick="zenPage.showBody(#(msgid)#); return false;">#(tBodyId)#</a></td>
					<td>#($P($classmethod(..#MessageClass,"TimeCreatedLogicalToDisplay",tRS.TimeCreated),"."))#</td>
					<td>#(tOrigNodeContent)#</td>
					<td>#(tRS.SourceConfigName)#</td>
					<td>#(tRS.TargetConfigName)#</td>
					<td id="item_#(i)#">#(tTargetItem)#</td>
					<td id="node_#(i)#">#($select('tUnknownNode: "<a href=""#"" onclick=""zenPage.showNodeHomePage('"_tTargetNode_"'); return false;"">"_tTargetNode_"</a>", 1: tTargetNode))#</td>
					</tr>>
			}
		}
 	}
 	If $$$ISERR(tStatus) Quit tStatus
	If i > ..#MAXDISPLAYROWS {
		Set tMaxDisplay = $$$FormatText($$$Text("Cannot display more than %1 rows, but all %2 matching messages will be resent"),..#MAXDISPLAYROWS,tResendCount)
		Do ..WriteInlineMessage(tMaxDisplay,"warning")
	}
	If tBadHdrs {
		Set msgBadHeaders = $$$FormatText($$$Text("%1 message headers could not be found, starting with Header #%2;SQLCODE=%3","Ensemble"),tBadHdrs,tBadHdrs("msgid"),tBadHdrs("SQLCODE"))
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
	If ..doCollective {
		Set tSC = $classmethod(..targetingClass,"AllMessages",..Key,.tNewNode,.tNewItem)
		If $$$ISERR(tSC) {
			Set tErrorMsg = $$$FormatText($$$Text("Error in '%1' callback for Targeting class '%2': %3"),"AllMessages",..targetingClass,$system.Status.GetErrorText(tSC))
			Do ..WriteInlineMessage(tErrorMsg)
		}
		Else {
			Set tNewNode = $get(tNewNode)
			Set tNewItem = $get(tNewItem)
			Set tMessage = ""
			If (tNewNode '= "") && (tNewItem '= "") {
				Set tMessage = $$$FormatText($$$Text("Collective Targeting has specified a new target configuration item of '%1' on node '%2'"),tNewItem,tNewNode)
			}
			ElseIf tNewNode '= "" {
				Set tMessage = $$$FormatText($$$Text("Collective Targeting has specified a new node: '%1'"),tNewNode)
			}
			ElseIf tNewItem '= "" {
				Set tMessage = $$$FormatText($$$Text("Collective Targeting has specified a new target configuration item: '%1'"),tNewItem)
			}
			If tMessage '= "" {
				Do ..AddMessage(tMessage,"warning",0)
			}
		}
	}
	&html<</table>
		</div>>
	Quit $$$OK
}

Method FindTargetNode(pNodeId As %Integer, pTargetItem As %String) As %String [ Private ]
{
	Set tClientName = ..nodeIndex.GetAt(pNodeId)
	If (tClientName = "")||(pTargetItem = "") Quit 0
	If '$data(..%Targets(tClientName)) {
		Do ..BuildItemData(tClientName,0)
	}
	If '$data(..%Targets(tClientName,pTargetItem)) Quit 0
	Quit tClientName
}

/// Add Resend options to the toolbar.
Method OnDrawRibbon() As %Status
{
	If '(..doCollective || ..doIndividual) {
		Set tClientNodeTitle = $$$TextHTML("Target Client")
		Set tTargetConfigTitle = $$$TextHTML("Target configuration item")
		&html<<td style="white-space: nowrap; padding-left: 50px;">
		<div style="white-space: nowrap;">
		<span class="ribbonText">#(tClientNodeTitle)#:&nbsp;</span>
		<select id="clientSelect" title="#(tClientNodeTitle)#" onchange="zenPage.chooseTarget();">
			<option value="">&nbsp;&nbsp;</option>>
		Set tKey = ""
		For {
			Set tNext = ..clients.GetNext(.tKey)
			Quit:(tKey = "")
			Set tOutVal = $zcvt(tKey,"O","HTML")
			&html<<option value="#(tOutVal)#">#(tOutVal)#</option>>
		}
		&html<</select>
		<span class="ribbonText">#(tTargetConfigTitle)#:&nbsp;</span>
		<select id="clientItemSelect" title="#(tTargetConfigTitle)#" onchange="zenPage.chooseTargetItem(this.value);">
			<option value="" selected></option>
		</select>
		<span class="ribbonText" style="padding-left:20px;">#($$$Text("Resubmit at head of queue:"))#</span>
		<input type="checkbox" id="HeadOfQueue" onchange="zenPage.HeadOfQueue = this.value;"/>
		</div>
		</td>>
	}
	
	Quit $$$OK
}

/// The user has chosen a target configuration item.
ClientMethod chooseTargetItem(itemName) [ Language = javascript ]
{
	var itemName = (itemName == null ? '' : itemName);
	this.newTargetConfig = itemName;
	this.updateTargets();
	this.reportResendMessage();
}

/// Inform the user about the current targeting state.
ClientMethod reportResendMessage() [ Language = javascript ]
{
	if (this.newTargetConfig == '') {
		if (this.NewTarget == '') {
			alert($$$Text("Messages will be resent to their original configuration items on their original client systems."));
		}
		else {
			alert($$$FormatText($$$Text("Messages will be resent to their original configuration items on client '%1'."),this.NewTarget));
		}
	}
	else {
		if (this.NewTarget == '') {
			alert($$$FormatText($$$Text("Messages will be resent to configuration item '%1' on their original client systems."),this.newTargetConfig));
		}
		else {
			alert($$$FormatText($$$Text("Messages will be resent to configuration item '%1' on client '%2'."),this.newTargetConfig,this.NewTarget));
		}
	}
}

ClientMethod updateTargets() [ Language = javascript ]
{
	var i = 0;
	var done = false;
	var targetNode;
	var targetItem;
	var saveTargets = false;
	if (!this._originalTargets) {
		this._originalTargets = [];
		saveTargets = true;
	}
	var nodeHTML = '<a href="#" onclick="zenPage.showNodeHomePage(\''+this.NewTarget+'\'); return false;">'+this.NewTarget+'</a>';
	var itemHTML = this.newTargetConfig;
	while (!done) {
		i++;
		targetNode = document.getElementById('node_'+i);
		targetItem = document.getElementById('item_'+i);
		if ((!targetNode) || (!targetItem)) {
			done = true;
		}
		else {
			if (saveTargets) this._originalTargets[i] = targetNode.innerHTML;
			if (this.NewTarget == '') {
				targetNode.innerHTML = (this._originalTargets[i] ? this._originalTargets[i] : '');
			}
			else {
				targetNode.innerHTML = nodeHTML;
			}
			targetItem.innerHTML = itemHTML;
		}
	}
}

/// Refresh the list of available configuration items based on the currently selected client system.
ClientMethod updateTargetItemList() [ Language = javascript ]
{
	var clientSelect = document.getElementById('clientSelect');
	var itemSelect = document.getElementById('clientItemSelect');
	var clientName = (clientSelect ? clientSelect.value : '');
	var itemList = {};
	if ((clientName != null) && (clientName != '')) {
		itemList = this._configItems[clientName];
		if (!itemList) {
			var ok = this.BuildItemData(clientName,true);
			if (ok != '') {
				alert(ok);
				return;
			}
			itemList = this._configItems[clientName];
		}
	}
	
	var configSeen = false;
	// remove all options
	itemSelect.options.length = 0;
	
	var options = [];
	options.push(new Option(' ',''));
	for (var configName in itemList) {
		options.push(new Option(configName, configName));
		if (configName == this.newTargetConfig) {
			configSeen = true;
		}
	}
	for (var i = 0; i< options.length; i++) {
		if (zenIsIE) { itemSelect.add(options[i]); }
		else { itemSelect.add(options[i],null); }
	}
	if ((this.newTargetConfig != '') && !configSeen) {
		alert($$$FormatText($$$Text("Config item '%1' does not exist on client '%2'."),this.newTargetConfig,clientName));
		this.newTargetConfig = '';
	}
	itemSelect.value = this.newTargetConfig;
}

/// Select the client to resend messages to, and trigger an update of the available config items.
ClientMethod chooseTarget() [ Language = javascript ]
{
	var clientSelect = document.getElementById('clientSelect');
	this.NewTarget = clientSelect.value;
	
	// update the list of target config items
	this.updateTargetItemList();
	this.updateTargets();
	this.reportResendMessage();
}

Method ReallyResend() As %String [ ZenMethod ]
{
	Set tSomeErrors = 0
	Set tDirection = $select(..HeadOfQueue: -1, 1: 1)
	Set tMsgId = ""
	For {
		Set tMsgId = $order(^IRIS.Temp.ResendIDs(..Key,tMsgId),tDirection)
		Quit:(tMsgId = "")
		// When tNewTarget is blank the old target is used
		Set tNewTarget = $select((..NewTarget '= "")||(..newTargetConfig '= ""): ..NewTarget_"|"_..newTargetConfig, 1: $get(^IRIS.Temp.ResendIDs(..Key,tMsgId,"newnode")))
		Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"newnode") = tNewTarget
		Set tSC = ##class(Ens.Enterprise.MsgBank.MessageHeader).ResendDuplicatedMessage(.tWSClients,tMsgId,.tNewHeaderId,tNewTarget,,,..HeadOfQueue)
		If $$$ISERR(tSC) {
			Set tSomeErrors = 1
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"sc") = tSC
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"new") = ""
		}
		Else {
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"sc") = $$$OK
			Set ^IRIS.Temp.ResendIDs(..Key,tMsgId,"new") = tNewHeaderId
		}
	}
	If tSomeErrors {
		Quit $$$Text("Could not resend all messages; check Resend Status on the next page for results.")
	}
	Quit ""
}

ClientMethod getEditURL() [ Language = javascript ]
{
	var url = this.editResendPage + '?KEY=' + this.Key;
	if (this.NewTarget.length > 0) {
		url += '&TARGETCLIENT=' + this.NewTarget;
	}
	if (this.newTargetConfig.length > 0) {
		url += '&TARGETITEM=' + this.newTargetConfig;
	}
	url += '&HEAD=' + (this.HeadOfQueue ? 1 : 0);
	return url;
}

/// Initialise the _configItems object
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this._configItems = {};
	if (!this.Messages) {
		var resendButton = self.document.getElementById('command_okButton');
		if (resendButton) {
			resendButton.className = 'commandButtonDisabled';
			resendButton.style.cursor = 'default';
			resendButton.onclick = function() { return false; };
		}
		var editButton = self.document.getElementById('command_editButton');
		if (editButton) {
			editButton.className = 'commandButtonDisabled';
			editButton.style.cursor = 'default';
			editButton.onclick = function() { return false; };
		}
	}
}

}
