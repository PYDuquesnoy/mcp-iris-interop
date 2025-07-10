/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the Message Trace page of the ZEN application.
Class EnsPortal.VisualTrace Extends (EnsPortal.Dialog.standardDialog, EnsPortal.Util.PageLinks) [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MessageTrace:USE";

Parameter RESENDRESOURCE = "%Ens_MessageResend:USE";

Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter OKBUTTON As BOOLEAN = 0;

Parameter CANCELBUTTON As BOOLEAN = 0;

/// Name of this page.
Parameter PAGENAME = "Visual Trace";

Parameter SVGTraceClass = "EnsPortal.SVG.VisualTrace";

/// Comma-separated list of additional JS include files for the page - for Event Log popup.
Parameter JSINCLUDES = "ensemble/Ensemble_Utils.js";

/// Session (or message within session) to trace
Property sessionId As %String(ZENURL = "SESSIONID");

/// Flag indicating if this is the regular screen version or printer-friendly version
Property printable As %Boolean(ZENURL = "PRINTABLE");

/// Curr page of trace
Property currPage As %String(ZENURL = "PAGE") [ InitialExpression = 1 ];

/// Number of items to display on each page of the trace
Property itemsPerPage As %Integer [ InitialExpression = {..GetItemsPerPage()} ];

/// Flag to indicate whether internal items should be shown.
Property showInternalItems As %Boolean [ InitialExpression = {..GetShowInternalItems()} ];

/// Flag to indicate whether Events should be included in the trace.
Property showEvents As %Boolean [ InitialExpression = {..GetShowEvents()} ];

/// Flag to indicate whether content pane should be shown. The property is "sticky" for the session.
Property showContent As %ZEN.Datatype.boolean [ InitialExpression = {..GetShowContents()} ];

/// Flag to indicate whether trace should be shown.
Property showTrace As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Flag to indicate whether the user may view the contents of messages.
Property canViewContents As %ZEN.Datatype.boolean;

/// Server-side ID of currently selected item
Property currentId As %ZEN.Datatype.string;

/// HTML ID of currently selected item
Property currentSVGId As %ZEN.Datatype.string;

/// Type of currently selected item
Property currentType As %ZEN.Datatype.string;

/// If applicable, the server-side class of the currently selected item.
Property currentClass As %ZEN.Datatype.string;

/// The HTML ID of the currently selected line object, if any.
Property currentLine As %ZEN.Datatype.string;

/// Diagram width
Property svgWidth As %ZEN.Datatype.integer;

/// Diagram height
Property svgHeight As %ZEN.Datatype.integer;

/// Total number of items in the trace
Property svgItemCount As %ZEN.Datatype.integer;

Property headerClass As %ZEN.Datatype.className [ InitialExpression = "Ens.MessageHeader" ];

Property eventLogClass As %ZEN.Datatype.className [ InitialExpression = "Ens.Util.Log" ];

Property ruleLogClass As %ZEN.Datatype.className [ InitialExpression = "Ens.Rule.Log" ];

Property showRelated As %ZEN.Datatype.string;

Property svgFilterText As %ZEN.Datatype.string;

Property canViewRules As %ZEN.Datatype.boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList("%Ens_Code:READ,%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ")} ];

/// Flag to indicate whether a user may resend messages.
Property canResend As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check($Piece(..#RESENDRESOURCE,":",1),$Piece(..#RESENDRESOURCE,":",2))} ];

/// URL of resend page.
Property resendPage As %String [ InitialExpression = "EnsPortal.MessageResend.zen" ];

/// Link color: #3b84bc;
XData Style
{
<style type="text/css">

body {
	margin: 0;
	padding: 0;
	background: white;
}

.pane {
	background-color: #ECECEC;
	padding: 3px;
	border: 1px solid gray;
}

.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: darkblue;
	text-decoration: none;
}

.hdrLinkDisabled {
	font-size: 10pt;
	font-weight: normal;
	color: gray;
	text-decoration: none;
}

.hdrLink:hover {
	color: orange;
}

.ribbonLabel {
	color: black;
	font-weight: bold;
	font-size: 11pt;
	white-space: nowrap;
}

.ribbonAction {
	font-size: 10pt;
}
.ribbonAction a {
	color: #3b84bc;
	font-weight: normal;
	text-decoration: none;
}

.ribbonAction a:hover {
	color: darkred;
	cursor: pointer;
}

.ribbonLink {
	cursor: pointer;
}
img.ribbonDisabled {
	opacity:0.5;
}
span.ribbonDisabled {
	color: gray;
}

.ribbonSortOption {
	color: #3B84BC;
	text-decoration: none;
}

.ribbonSortOption:hover {
	color: darkred;
}

.portalTitleLink {
	color: #3b84bc;
	text-decoration: none;
}
.portalTitleLink:hover {
	color: #98923a;
}
.detailContents {
	padding: 8px;
}

.detailContentsError {
	color: red;
}

/* styles for item Header */
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
.helpCommand {
	text-decoration: none;
	color: white;
	font-size: 9pt;
}

.helpCommand:hover {
	text-decoration: none;
	color: darkred;
}
.helpArrow {
	font-size:18pt;
	color:white;
	padding-left: 4px;
	padding-right: 4px;
	background: rgb(53,107,141);
}
.expander.left {
	margin-right: 5px;
}
.expander.right {
	margin-left: 5px;
}
.tabGroupBody {
	/* Override definition in tabGroup */
	min-height: 0;
}
#bodyContents {
	background-color: white;
}
.eventInfoTable {
	padding: 5px;
	background-color: white;
}
/* styles for detailed debugging table */
.ruleDebugWrapper {
	background-color: white;
	padding: 5px;
	border-top: 1px solid #CCC;
	margin-top: 5px;
}
.ruleDebugHeader {
	font-weight: bold;
	width: 100%;
	text-align: center;
	font-size: 0.9em;
	padding-top: 5px;
	padding-bottom: 5px;
}
table.ruleDebugData {
	font-size: 10pt;
	border-collapse: collapse;
	padding: 5px;
	border: 1px solid #CCC;
}
table.ruleDebugData tr th {
	text-align: left;
}
table.ruleDebugData tr td {
	padding-left: 2px;
	padding-right: 2px;
	padding-top: 2px;
	padding-bottom: 2px;
	color: #333;
}
table.ruleDebugData tr:nth-child(even) {
	background-color: #EEE;
}
table.ruleDebugData tr:first-child {
	border-bottom: 1px solid #CCC;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup cellVAlign="top">
<spacer id="leftSpacer" width="15"/>
<vgroup id="svgGroup">
<html id="theTraceTop" OnDrawContent="DrawTraceTop" />
<hgroup id="contentGroup" cellVAlign="top">
<hgroup id="svgPane" enclosingClass="pane" cellVAlign="top">
<pane id="svgTracePane" paneName="svgTracePane" />
<html id="traceExpander">
<div>
<a id="traceExpanderLink" class="helpCommand expander right" href="#" onclick="zenPage.toggleContents(true); return false;"> 
<span id="traceExpanderArrow" class="helpArrow">&#171;</span>
</a>
</div>
</html>
</hgroup>
<spacer id="midSpacer" width="10" />
<pane id="contentsPanel" paneName="contentPane" />
</hgroup>
</vgroup>
<pane id="filterPanel" paneName="filterPane" hidden="true" />
</hgroup>
</pane>
}

XData svgTracePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<svgFrame id="SVGTrace" svgPage="EnsPortal.SVG.VisualTrace" width="300" height="200" svgAutoSize="true">
<parameter id="svgPAGE" paramName="PAGE" value="1" />
<parameter id="svgSESSIONID" paramName="SESSIONID" value="#(%page.sessionId)#"/>
<parameter id="printable" paramName="PRINTABLE" value="#(%page.printable)#" />
<parameter id="svgMsgPerPage" paramName="MSGPERPAGE" />
<parameter id="svgShowInternalItems" paramName="SHOWINTERNAL" />
<parameter id="svgShowEvents" paramName="INCLUDEEVENTS" />
<parameter id="svgShowRelated" paramName="SHOWRELATED"/>
<parameter id="svgRelatedItem" paramName="RELATEDITEM"/>
</svgFrame>
</pane>
}

/// Pane to contain tabGroup for content display
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup id="contents" enclosingClass="pane">
<html id="contentExpander" valign="top">
<div>
<a id="contentExpanderLink" class="helpCommand expander left" href="#" onclick="zenPage.toggleContents(false); return false;"> 
<span id="contentExpanderArrow" class="helpArrow">&#187;</span>
</a>
</div>
</html>
<pane id="allTabs" paneName="allTabs" />
</hgroup>
</pane>
}

XData allTabs [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tabGroup id="contentTabs" showTabBar="true" remember="true" onshowTab="zenPage.updateTabs(true);">
<tab id="headerDetails" caption="Header" title="Message Header Properties">
<html id="detailsContent" OnDrawContent="DrawDetailsContent" />
</tab>
<tab id="bodyDetails" caption="Body" title="Message Body Properties">
<html id="bodyInfo" OnDrawContent="DrawBodyInfo" />
</tab>
<tab id="bodyContents" caption="Contents" title="Message Body Contents">
<html id="fullContent" containerStyle="padding-top: 5px; padding-bottom: 5px;" OnDrawContent="DrawFullContentLinks" />
<iframe id="contentFrame" frameBorder="false" width="100%"/>
</tab>
</tabGroup>
</pane>
}

/// Update the tab display to match the currently selected items.
ClientMethod updateTabs(selected) [ Language = javascript ]
{
	if (!zenPage.showContent) {
		return;
	}
	if (zenPage._noTabUpdate) {
		return;
	}
	if (zenPage.currentType == 'host') {
		return;
	}
	
	var tabGroup = zen('contentTabs');
	var currTab = tabGroup.getCurrTabNo();
	if (selected) {
		zenPage._intendedTab = currTab;
	}
	if ((zenPage.currentId != '') && (zenPage.currentId != null)) {
		if (!zenPage._tabDisplay) {
			zenPage._tabDisplay = new Object();
		}
		if (!zenPage._contentIndex) {
			zenPage._contentIndex = {
				'message': this.headerClass,
				'event': this.eventLogClass,
				'ioLog': 'Ens.Util.IOLog',
				'rule': this.ruleLogClass
			};
		}
		zenPage._contentIndex['ack'] = zenPage.currentClass;
		
		if (!zenPage.canViewContents) {
			if (currTab != 1) {
				return;
			}
		}
		else {
			// enable viewable tabs
			var tabs = { 	'headerDetails': true,
							'bodyDetails': true,
							'bodyContents': true	};
			for (var tabName in tabs) {
				var tab = zen(tabName);
				if (tab) {
					var sync = tab.setProperty('disabled', !tabs[tabName]);
				}
			}
			if (!zenPage._tabMap) {
				zenPage._tabMap = { 
					'message': [ 1, 2, 3 ],
					'event':  [ 1, 1, 1 ],
					'ioLog': [ 1, 1, 3 ],
					'ack': [ 1, 1, 3],
					'rule':  [ 1, 1, 1 ]
				};
			}
			var intended = zenPage._intendedTab - 1;
			var map = zenPage._tabMap[zenPage.currentType];
			var selectTab = map[intended];
			if (selectTab && (selectTab != currTab)) {
				zenPage._noTabUpdate = true;
				tabGroup.showTab(selectTab);
				currTab = selectTab;
				zenPage._noTabUpdate = false;
			}
		
			if (!zenPage._tabsDisabled) {
				zenPage._tabsDisabled = {
					'message': {},
					'event': { 'bodyDetails': true, 'bodyContents': true },
					'ioLog': { 'bodyDetails': true },
					'ack': { 'bodyDetails': true }
				};
			}
			
			// correctly disable non-viewable tabs
			var disableTabs = zenPage._tabsDisabled[zenPage.currentType];
			for (var tabName in disableTabs) {
				var tab = zen(tabName);
				if (tab) {
					tab.setProperty('disabled', true);
				}
			}
		}	
		
		switch (currTab) {
			case 1:
				if ((this._tabDisplay['DetailsType'] != this.currentType) || (this._tabDisplay['Details'] != this.currentId)) {
					var headerClass = this._contentIndex[this.currentType];
					this.drawDetails(this.currentId, headerClass);
					this._tabDisplay['DetailsType'] = this.currentType;
					this._tabDisplay['Details'] = this.currentId;
				}
				break;
			case 2:
				var headerId = '';
				this._tabDisplay['BodyType'] = '';
				this._tabDisplay['Body'] = '';
				if (this.currentType == 'message') {
					this._tabDisplay['BodyType'] = 'message';
					this._tabDisplay['Body'] = this.currentId;
					headerId = this.currentId;
				}
				this.drawBody(headerId);
				break;
			case 3:
				if ((this._tabDisplay['ContentType'] != this.currentType) || (this._tabDisplay['Contents'] != this.currentId)) {
					var frame = zen('contentFrame');
					if ((this.currentType == 'host') || (this.currentId == -1) || (this.currentId == null)) {
						frame.setProperty('src', '');
					}
					else {
						var headerClass = this._contentIndex[this.currentType];
						frame.setProperty('src', zenLink('EnsPortal.MessageContents.zen?HeaderClass='+headerClass+'&HeaderId='+this.currentId+'&LIMITSIZE=20000'));
					}
					this._tabDisplay['Contents'] = this.currentId;
					this._tabDisplay['ContentType'] = this.currentType;
				}
				break;
			default:
				break;
		}
	}
}

ClientMethod showFullContent(showRaw, showJSON) [ Language = javascript ]
{
	if (this.currentType == 'host') {
		return;
	}
	if (this._contentIndex) {
		var headerClass = this._contentIndex[this.currentType];
		if ((this.headerClass.length > 0) && (this.currentId.length > 0))
	 		window.open(zenLink('EnsPortal.MessageContents.zen?HeaderClass='+headerClass+'&HeaderId='+this.currentId+(showJSON ? '&FORMAT=JSON' :(showRaw ? '&RAW=1' : ''))));
	}
}

/// Update the details for a selected item.
ClientMethod drawDetails(messageId, messageClass) [ Language = javascript ]
{
	var details = zen('detailsContent');
	
	if ((messageId == -1) || (messageId == null)) {
		details.seed = '';
	}
	else {
		// get contents from server
		details.seed = messageId + '\x00\x00'+messageClass;
	}
	details.refreshContents(true);
}

/// Update the body information for a given message header.
ClientMethod drawBody(headerId) [ Language = javascript ]
{
	var body = zen('bodyInfo');
	if ((headerId == -1) || (headerId == null)) {
		body.seed = '';
	}
	else {
		body.seed = headerId;
	}
	body.refreshContents(true);
}

ClientMethod toggleContents(isTrace, noAdjust) [ Language = javascript ]
{
	if (isTrace) {
		this.showTrace = !this.showTrace;
		var svg = zen('SVGTrace');
		var sync = svg.setHidden(!this.showTrace);
		if (!this.showTrace) {
			this.hideSVGCell();
		}
	}
	else {
		this.showContent = !this.showContent;
		var tabGroup = zen('contentTabs');
		tabGroup.setHidden(!this.showContent);
		this.SetShowContents(this.showContent);
	}
	if (!this.showTrace && !this.showContent) { // can't hide both
		this.toggleContents(!isTrace, true);
	}
	this.toggleArrow(isTrace);
	
	if (!noAdjust) {
		this.adjustSize();
	}
}

ClientMethod toggleArrow(isTrace) [ Language = javascript ]
{
	var arrow = document.getElementById((isTrace ? 'trace' : 'content') + 'ExpanderArrow');
	if (isTrace) {
		arrow.innerHTML = (this.showTrace ? '&#171;' : '&#187;');
	}
	else {
		arrow.innerHTML = (this.showContent ? '&#187;' : '&#171;');
	}
}

/// Write out the links to view the full content for the message.
ClassMethod DrawFullContentLinks(pSeed As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawFullContentLinks()
}

/// This method is used to calculate the SVG canvas dimensions and create a svgFrame component with these dimensions.
Method %OnAfterCreatePage() As %Status
{
	Set items = $classmethod(..#SVGTraceClass,"BuildTraceInfo",..sessionId)
	Set ..svgWidth = $P(items,"#",4)
	Set ..svgHeight = $P(items,"#",5)
	Set ..svgItemCount = $P(items,"#",1)

	Set svg = ..%GetComponentById("SVGTrace")
	Set svg.width = ..svgWidth
	Set svg.height = ..svgHeight
	
	Set svgPage = ..%GetComponentById("svgPAGE")
	Set svgPage.value = ..currPage
	
	Set svgMsgPerPage = ..%GetComponentById("svgMsgPerPage")
	Set svgMsgPerPage.value = ..itemsPerPage
	
	Set svgShowInternalItems = ..%GetComponentById("svgShowInternalItems")
	Set svgShowInternalItems.value = ..showInternalItems
	
	Set svgShowEvents = ..%GetComponentById("svgShowEvents")
	Set svgShowEvents.value = ..showEvents
	
	Set ..canViewContents = ..CheckViewContents()
	
	If '..canViewContents {
		Set tBodyTab = ..%GetComponentById("bodyDetails")
		If $IsObject(tBodyTab) {
			Set tBodyTab.disabled = 1
			Set tBodyTab.title = $$$Text("You are not permitted to access this content.")_$$$Text("Contact your system administrator for access.")
		}
		Set tContentsTab = ..%GetComponentById("bodyContents")
		If $IsObject(tContentsTab) {
			Set tContentsTab.disabled = 1
			Set tContentsTab.title = $$$Text("You are not permitted to access this content.")_$$$Text("Contact your system administrator for access.")
		}
	}
	
	If '..showContent {
		Set tTabGroup = ..%GetComponentById("contentTabs")
		Set tTabGroup.hidden = 1
	}
	// Hide contents if the window was opened for printing
	If ..printable {
		Set details = ..%GetComponentById("contentsPanel")
		If $IsObject(details) {
			Set details.hidden = 1
		}
	}

	Quit $$$OK
}

Method CheckViewContents() As %Boolean [ CodeMode = expression ]
{
$system.Security.Check("%Ens_MessageContent","USE")
}

ClassMethod GetShowContents() As %Boolean [ CodeMode = expression ]
{
$select($IsObject($get(%session)): $get(%session.Data("EnsPortal","VisualTrace","ShowContents"),1), 1: 1)
}

ClassMethod SetShowContents(pValue As %Boolean = 1) As %String [ ZenMethod ]
{
	If $IsObject($get(%session)) {
		Set %session.Data("EnsPortal","VisualTrace","ShowContents") = pValue
	}
	Quit ""
}

/// Get next session Id; pDirection should be 1 or -1
ClassMethod NextSession(pSessionId = "", pDirection As %Integer = 1) As %Integer [ CodeMode = expression, Internal, Private ]
{
+$O(^Ens.MessageHeaderI("SessionId",pSessionId),pDirection)
}

/// Write out contents of details tab.
/// <var>pID</var> is the item ID concatenated with $c(0,0) and then the message class.
ClassMethod DrawDetailsContent(pID As %String) As %Status
{
	Set tClassname = $piece(pID, $c(0,0), 2)
	Set tID = $piece(pID, $c(0,0), 1)
	If (tClassname = "Ens.Util.Log") || (tClassname = "Ens.Enterprise.MsgBank.Log") {
		Set tIsEnterprise = (tClassname = "Ens.Enterprise.MsgBank.Log")
		Quit ##class(EnsPortal.Utils).DrawEventInfo(tID,,,tIsEnterprise)
	} ElseIf (tClassname = "Ens.Rule.Log") {
		Quit ##class(EnsPortal.Utils).DrawRuleInfo(tID)	
	}
	Set tSC = ##class(EnsPortal.Utils).DrawItemDetails(tID, tClassname)

	If $$$ISOK(tSC) && (tClassname="Ens.MessageHeader") {
		Try {
			// Mark Resend button as 'disabled'
			Set tCanResend = $system.Security.Check($Piece(..#RESENDRESOURCE,":",1),$Piece(..#RESENDRESOURCE,":",2))
			If tCanResend {
				Set tButtonClass = "commandButton"
				Set tToolTip = $$$Text("Resend this message")
			} Else {
				Set tButtonClass = "commandButtonDisabled"
				Set tToolTip = $$$Text("You are not permitted to Resend")
			}
			&html<
				<div style='float: right;' title='Resend this message'>
				<a id="command_btnResend" style="line-height:27px;" class=#(tButtonClass)# href="#" onclick="zenPage.doResend('#(tID)#'); return false;return false;" title='#(tToolTip)#'><nobr>Resend</nobr></a>
				&nbsp;
				</div>
			>
		} Catch { /* suppress unexpected error so as not to prevent rendering of the Header table */}
	}

	Return tSC
}

/// Write out contents of body details panel.
/// <var>pHeaderID</var> is the message id.
Method DrawBodyInfo(pHeaderID As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawBodyInfo(pHeaderID,..headerClass)
}

Method DrawTraceTop(pSeed As %String) As %Status
{
	Set actualSessionId = ..GetActualSessionId(..sessionId)
	&html<<table border="0" cellspacing="#($select(..printable: 5, 1: 12))#"><tr>>
	&html<<td class="ribbonLabel">#($$$FormatText($$$Text("Session ID: %1"),..EscapeHTML(actualSessionId)))#</td>>

	If '..printable {
		// Legend
		Do ..DrawMenuItem($$$Text("Legend"), "images/datetext.gif", 0, "javascript:zenPage.showLegend();")

		// Printable Version
		Do ..DrawMenuItem($$$Text("Printable Version"), "images/node.gif", 0, "javascript:zenPage.showPrintableVersion();")

		&html<<td class="ribbonAction"><span>#($$$Text("Go to items"))#&nbsp;</span><select onchange="zenPage.openPage(this.value);">>
		Set tPageCount = (..svgItemCount \ ..itemsPerPage) + ((..svgItemCount # ..itemsPerPage) > 0)
		For i=1:1:tPageCount {
			&html<<option value="#(i)#" #($select(..currPage = i: "selected", 1: ""))#>#(((i-1) * ..itemsPerPage) + 1)#&nbsp;-&nbsp;#($select(i=tPageCount: ..svgItemCount,1: i * ..itemsPerPage))#</option>>
		}
		If tPageCount = 0 {
			&html<<option value="1">&nbsp;&nbsp;</option>>
		}
		&html<</select></td>>

		&html<<td class="ribbonAction"><span>#($$$Text("Items per page"))#&nbsp;</span><select onchange="zenPage.openPage(1,this.value);">>
		Set tOptions = $listbuild(10,20,30,40,50,75,100,200)
		For i=1:1:$listlength(tOptions) {
			Set tCurrOption = $listget(tOptions,i)
			&html<<option value="#(tCurrOption)#" #($select(tCurrOption = ..itemsPerPage: "selected", 1: ""))#>#(tCurrOption)#</option>>
		}
		&html<</select></td>>

		&html<<td class="ribbonAction"><span>#($$$TextHTML("Show events"))#</span><input id="showEventsCheckBox" type="checkbox" onchange="zenPage.openPage(1,null,null,this.checked);" #($select(..showEvents: "checked=""checked""", 1:""))#></input></td>>
		&html<<td class="ribbonAction"><span>#($$$TextHTML("Show internal items"))#</span><input id="showInternalItemsCheckBox" type="checkbox" onchange="zenPage.openPage(1,null,this.checked);" #($select(..showInternalItems: "checked=""checked""", 1:""))#></input></td>>
		
		&html<<td class="ribbonAction">>
		
		If (..showRelated = "")||(..showRelated = "None") {
			&html<<span style="visibility:visible" id="lblApplyFilter" >#($$$TextHTML("Apply Filter"))#&nbsp;</span>>
		} Else {
			&html<<a id="lblReApplyFilter" style="visibility:visible" href="javascript:zenPage.openPage(1,null,null,null,null);">#($$$TextHTML("Reapply Filter"))#&nbsp;</a>>
		}
		
		&html<<select id="selectFilter" onchange="zenPage.openPage(1,null,null,null,this.value);">>
		Set tOptionsDisplay = $listbuild($$$TextHTML("None"),$$$TextHTML("Host"),$$$TextHTML("Corresponding"))
		#; in EnsPortal.SVG.VisualTrace we use these. Removed MessageBody/SameBody
		Set tOptions = $listbuild("None","SameHost","Corresponding")
		For i=1:1:$listlength(tOptions) {
			Set tCurrOption = $listget(tOptions,i)
			Set tCurrOptionDisplay = $listget(tOptionsDisplay,i)
			&html<<option value="#(tCurrOption)#" #($select(tCurrOption = ..showRelated: "selected", 1: ""))#>#(tCurrOptionDisplay)#</option>>
		}
		&html<</select></td>>
		
		// Previous Page
		Do ..DrawMenuItem($$$Text("Previous Page"), "images/arrow1L.gif", (..currPage = 1), "javascript:zenPage.openPage("_(..currPage-1)_");")

		// Next Page
		Do ..DrawMenuItem($$$Text("Next Page"), "images/arrow1R.gif", (..svgItemCount <= (..currPage * ..itemsPerPage)), "javascript:zenPage.openPage("_(..currPage+1)_");")

		Set nextId = ..NextSession(..sessionId, 1)
		Set previousId = ..NextSession(..sessionId, -1)

		&html<<td class="ribbonLabel">||</td>>

		// Previous Session
		Do ..DrawMenuItem($$$Text("Previous Session"), "images/arrow1L.gif", 'previousId, "javascript:zenPage.goToSession("_previousId_");")

		// Next Session
		Do ..DrawMenuItem($$$Text("Next Session"), "images/arrow1R.gif", 'nextId, "javascript:zenPage.goToSession("_nextId_");")
	} Else {
		Do ..DrawMenuItem($$$Text("Print"), "images/print.png", 0, "javascript:window.print();")
	}

	&html<</tr></table>>
	If ..svgFilterText'="" &html<<table><tr><td class="ribbonLabel">#(..svgFilterText)#</td></tr></table>>
    Quit $$$OK
}

/// Helper method to obtain the session id given the SESSIONID URL parameter which may be a session id or a message id
ClassMethod GetActualSessionId(pId As %String = "") As %String
{
	&sql(SELECT SessionId INTO :session FROM Ens.MessageHeader WHERE %ID = :pId)
	Quit $G(session,pId)
}

ClassMethod DrawMenuItem(pText As %String, pImage As %String, pDisabled As %Boolean = 0, pOnClick As %String) [ Internal, Private ]
{
	Set tOnClick = $select(pDisabled: "", 1: pOnClick)
	Set tClass = $select(pDisabled: "ribbonDisabled", 1: "ribbonLink")
	&html<<td><table><tr>
	<td><img class="#(tClass)#" src="#(pImage)#" onclick="#(tOnClick)#" /></td>
	<td class="ribbonAction">>
	If pDisabled {
		&html<<span class="#(tClass)#">#(pText)#</span>>
	}
	Else {
		&html<<a href="#(tOnClick)#">#(pText)#</a>>
	}
	&html<</td></tr></table></td>>
}

/// Go to the Trace page for the previous or next session.
ClientMethod goToSession(id) [ Language = javascript ]
{
	this.gotoPage('EnsPortal.VisualTrace.zen?SESSIONID=' + id);
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize', arguments);
	
	var svg = zen('SVGTrace');
	var svgDiv = svg.getEnclosingDiv();
	
	if (zenPage.printable) {
		var svgExpander = zen('traceExpander');
		svgExpander.setHidden(true);
		var footer = zen('footer');
		footer.setHidden(true);
		var body = zen('body');
		var bodyDiv = body.getEnclosingDiv();
		bodyDiv.style.height = '';
		bodyDiv.style.padding = '0';
		if (zenPage.svgWidth > 0) {
			bodyDiv.style.width = (svgDiv.offsetWidth + 15) + 'px';
		}
		zen('leftSpacer').setProperty('width',5);
		zen('midSpacer').setHidden(true);
		return;
	}
	
	var rightDiv = zen('contents').getEnclosingDiv();
	var tabGroup = zen('contentTabs');
	var tabDiv = tabGroup.getEnclosingDiv();
	var tabBar = tabGroup.getTabBarElement();
	var frame = zen('contentFrame');
	var fullContentDiv = zen('fullContent').getEnclosingDiv();;
	
	var svgWidth = parseInt(zenPage.svgWidth,10);
	var svgHeight = parseInt(zenPage.svgHeight,10);
	var svgDivHeight = parseInt(svgDiv.offsetHeight,10);
	
	var traceTopDiv = zen('theTraceTop').getEnclosingDiv();
	var svgPaneDiv = zen('svgPane').getEnclosingDiv();
	var bodyDiv = zen('body').getEnclosingDiv();
	
	var height = bodyDiv.offsetHeight - traceTopDiv.offsetHeight - 20;
	svgPaneDiv.style.height = height + 'px';
	
	var rightHeight = height;
	rightDiv.style.height = rightHeight+'px';
	rightHeight = rightHeight - tabBar.offsetHeight;
	tabDiv.style.height = rightHeight +'px';
	// handle case where trace tab hasn't been selected
	var fullContentHeight = fullContentDiv.offsetHeight ? fullContentDiv.offsetHeight : 20;
	var frameHeight = rightHeight - 12 - fullContentHeight - (zenIsHTML5 * 2);
	frame.setProperty('height', frameHeight +'px'); 
	
	svg.setProperty('svgHeight', svgHeight);
	svg.setProperty('height', height);
	svgDiv.style.height = height + 'px';
	
	var width = zenGetWindowWidth() - 150;
	var svgDivWidth = 0;
	var rightWidth = 0;
	if (zenPage.showContent) {
		if (zenPage.showTrace) {
			svgDivWidth = Math.round((width * 0.7));
		}
		var extraWidth = ((svgHeight>height) ? 25 : 10);
		if (svgDivWidth > (svgWidth+extraWidth)) {
			svgDivWidth = (svgWidth+extraWidth);
			rightWidth = width - svgDivWidth;
		}
		else if (svgDivWidth == 0) {
			rightWidth = width;
		}
		else {
			rightWidth = Math.round((width * 0.3));
		}
		if (rightWidth < 250) {
			svgDivWidth = svgDivWidth - (250 - rightWidth);
			rightWidth = 250;
		}
		if (zenPage.showTrace && (svgDivWidth < 400)) {
			if (rightWidth > 250) {
				rightWidth = rightWidth - (400 - svgDivWidth);
			}
			svgDivWidth = 400;
		}
		
		// prevent IE resize logic
		tabGroup.ieResizeBody = function() { return; };
		
		// set widths
		tabGroup.setBodySize(rightHeight, rightWidth);
		var frameWidth = rightWidth - (zenIsIE * 5) - (zenIsHTML5 * 15) - (zenIsGecko * 10) -2;
		frame.setProperty('width', frameWidth + 'px');
		tabDiv.style.width = rightWidth + 'px';
	}
	else {
		svgDivWidth = width;
	}
	
	svg.setProperty('svgWidth', svgWidth);
	svg.setProperty('width', svgDivWidth);
	svgDiv.style.width = svgDivWidth + 'px';
	this.hideSVGCell();
}

/// Callback from the Trace SVG onSVGLoad() callback.
/// The callback is used to ensure that we have the loaded SVG diagram available 
/// before we attempt to resize the diagram or highlight the currently selected message.
ClientMethod onTraceSVGLoad() [ Language = javascript ]
{
	if (this._onTraceSVGLoadCalled) return;
	
	var trace = zen('SVGTrace');
	var height = null;
	if (trace && trace.svgWindow && trace.svgWindow.svgPage) {
		var svgPage = trace.svgWindow.svgPage;
		if (svgPage.getCurrentHeight) {
			var height = svgPage.getCurrentHeight();
			if (height) {
				zenPage.svgHeight = height;
				if (trace.svgAutoSize) {
					trace.setProperty('svgAutoSize',false);
				}
			}
		}
		if (svgPage.getCurrentWidth) {
			var width = svgPage.getCurrentWidth();
			if (width) {
				zenPage.svgWidth = width;
				if (trace.svgAutoSize) {
					trace.setProperty('svgAutoSize',false);
				}
			}
		}
		if (svgPage.selectItem) {
			var svgDoc = trace.getSVGDocument();
			if (svgDoc) {
				try {
					var svgBuildInfo = zenPage.findNumberInSVG(svgDoc);
					var msgId = (svgBuildInfo[1]=0 ? this.sessionId : svgBuildInfo[1]) ;
					if (svgBuildInfo[0]!=0) {zenPage.svgItemCount = svgBuildInfo[0]};
					zenPage.svgFilterText = svgBuildInfo[2];
				} catch (ex) {msgId = this.sessionId;}
			}
			if ((zenPage.showRelated == 'SameHost')||(zenPage.showRelated == 'Corresponding')) {
				// need to select the item selected when the filter was applied
				try {
					svgPage.selectItem(null,zenPage.currentType,zenPage.currentSVGId,zenPage.currentId,zenPage.currentClass,zenPage.currentLine);
				} catch (err) {}
			} else { 
				if (svgDoc) {
					var svgObj = svgDoc.getElementById(this.sessionId);
					var lineId = '';
					var rectId = '';
					if (svgObj) {
						lineId = svgObj.getAttribute('lineId');
						rectId = svgObj.getAttribute('rectId');
					}
					svgPage.selectItem(null,'message',rectId,this.sessionId,'',lineId);
				}
			}
		}
		this._onTraceSVGLoadCalled = true;
	}
	zenPage.adjustSize();
	
	var traceTop = zen('theTraceTop');		
	traceTop.refreshContents(true);
}

/// Show the legend as a popup.
ClientMethod showLegend() [ Language = javascript ]
{
	zenPage.launchPopupWindow(zenLink('EnsPortal.VisualTraceLegend.zen'),'','status=no,scrollbars=no,resizable=no,width=817,height=690,left=400');
}

/// Show the printable trace in its own tab/window.
ClientMethod showPrintableVersion() [ Language = javascript ]
{
	var currentPage = (zenPage.currPage >0 ? zenPage.currPage : 1);
	window.open(zenLink('EnsPortal.VisualTrace.zen?SESSIONID=' + zenPage.sessionId + '&PRINTABLE=1&PAGE='+currentPage));
}

ClientMethod openPage(pageNum, msgPerPage, showInternal, showEvents, showRelated) [ Language = javascript ]
{
	var svgPage = zen('svgPAGE');
	if (svgPage) {
		var svg = zen('SVGTrace');
		var traceTop = zen('theTraceTop');
		
		svgPage.value = parseInt(pageNum,10);
		zenPage.currPage = svgPage.value;
		
		if (msgPerPage) {
			var svgMsgPerPage = zen('svgMsgPerPage');
			if (svgMsgPerPage) {
				svgMsgPerPage.value = parseInt(msgPerPage,10);
				zenPage.itemsPerPage = svgMsgPerPage.value;
				zenPage.SetItemsPerPage(zenPage.itemsPerPage);
			}
		}
		else if (showInternal != null) {
			var svgShowInternalItems = zen('svgShowInternalItems');
			if (svgShowInternalItems) {
				showInternal = !!showInternal;
				svgShowInternalItems.value = (showInternal ? 1 : 0);
				zenPage.showInternalItems = showInternal;
				zenPage.SetShowInternalItems(showInternal);
			}
		}
		else if (showEvents != null) {
			var svgShowEvents = zen('svgShowEvents');
			if (svgShowEvents) {
				showEvents = !!showEvents;
				svgShowEvents.value = (showEvents ? 1 : 0);
				zenPage.showEvents = showEvents;
				zenPage.SetShowEvents(showEvents);
			}
		}
		
		/* Begin Handle Filter */
		var traceTopDiv=traceTop.getEnclosingDiv();
		if (traceTopDiv) {
			var allSelects = traceTopDiv.getElementsByTagNameNS('*','select');
			var selectFilterIndx = null;
			if ((allSelects)&&(!showRelated)) {
				for (var i=0; i<allSelects.length; i++) {
 					if (allSelects[i].getAttribute('id')=='selectFilter') {
	 					showRelated=allSelects[i].value;
	 					selectFilterIndx = i;
	 					break;
	 				}
				}
			}
		}
		if (showRelated) {
			if ((showRelated != 'None')&&(zenPage.currentType == 'canvas')) {
				alert($$$Text('Nothing selected to filter on.'));
				if (allSelects) {
					if (selectFilterIndx == null) {
						for (var i=0; i<allSelects.length; i++) {
 							if (allSelects[i].getAttribute('id')=='selectFilter') {
	 							allSelects[i].selectedIndex = 0;
	 							break;
 							}
						}
					} else {
						allSelects[selectFilterIndx].selectedIndex = 0;
					}
				}
				return;
			}
			var svgShowRelated = zen('svgShowRelated');
			if (svgShowRelated) {
				svgShowRelated.value = showRelated;
				zenPage.showRelated = showRelated;
			}
			var svgRelatedItem = zen('svgRelatedItem');
			if (svgRelatedItem) {
				if ((showRelated == 'None')||(!showRelated)) {
					svgRelatedItem.value = '';
				} else {
					svgRelatedItem.value = zenPage.currentId+"~"+zenPage.currentSVGId+"~"+zenPage.currentType+"~"+zenPage.currentClass+"~"+zenPage.currentLine;
				}
			}
		}
		/* End Handle Filter */
		
		this._onTraceSVGLoadCalled = false;
		svg.refreshContents(true);
		
		//this.adjustSize() is now called in onRefreshContents() so that it does not trigger errors in IE
	}
}

/// Invoke a search using values from the search form.
ClientMethod doSearch() [ Language = javascript ]
{
	//try {
		var form = this.getSearchForm();

		// apply form contents to SVG frame parameters
		//var data = form.getValuesAsObject();
		var sessionId = '#(%request.Get("SESSIONID",1))#';
		zen('svgSESSIONID').value = sessionId;

		// fill in additional properties as needed

		// calculate trace diagram size
		//var svgHeight = zenPage.CalculateHeight(sessionId);
		//svgPage.svgHeight = svgHeight;

		// refresh diagram
		var svg = zen('resultsTable');
		svg.refreshContents();
	// }
	//catch(ex) {
	//	zenExceptionHandler(ex,arguments,'Error in search.');
	// }
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
		Quit $$$Text("Visual Trace")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Visual Trace","Ensemble")
}

/// Add the style information for the Event Log information.
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Quit ##class(EnsPortal.Utils).DrawEventInfoStyle()
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 0 // Do not display
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Visual Trace")
	Quit $$$OK
}

/// Draw the contents of the tool ribbon.
Method DrawRibbon(pSeed As %String) As %Status
{
	Quit $$$OK
}

/// Get localized messages for the message contents pane.
ClassMethod GetContentMessages(messages As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Quit ##class(EnsPortal.MessageContents).GetMessages(messages)
}

ClassMethod SetItemsPerPage(items As %Integer) As %String [ ZenMethod ]
{
	Set items = $get(items, $parameter(..#SVGTraceClass,"MSGPERPAGE"))
	Set ^EnsPortal.Settings($username,"VisualTrace","ItemsPerPage") = items
	Quit 1
}

ClassMethod GetItemsPerPage() As %Integer [ ZenMethod ]
{
	Quit $get(^EnsPortal.Settings($username,"VisualTrace","ItemsPerPage"), $parameter(..#SVGTraceClass,"MSGPERPAGE"))
}

ClassMethod SetShowInternalItems(flag As %Boolean = 0) As %String [ ZenMethod ]
{
	Set show = $get(flag, $parameter(..#SVGTraceClass,"SHOWINTERNALITEMS"))
	Set ^EnsPortal.Settings($username,"VisualTrace","ShowInternalItems") = show
	Quit 1
}

ClassMethod GetShowInternalItems() As %Boolean [ ZenMethod ]
{
	Quit $get(^EnsPortal.Settings($username,"VisualTrace","ShowInternalItems"), $parameter(..#SVGTraceClass,"SHOWINTERNALITEMS"))
}

ClassMethod SetShowEvents(flag As %Boolean = 0) As %String [ ZenMethod ]
{
	Set show = $get(flag, $parameter(..#SVGTraceClass,"INCLUDEEVENTS"))
	Set ^EnsPortal.Settings($username,"VisualTrace","ShowEvents") = show
	Quit 1
}

ClassMethod GetShowEvents() As %Boolean [ ZenMethod ]
{
	Quit $get(^EnsPortal.Settings($username,"VisualTrace","ShowEvents"), $parameter(..#SVGTraceClass,"INCLUDEEVENTS"))
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return null;
}

ClientMethod hideSVGCell() [ Language = javascript ]
{
	var svg = zen('SVGTrace');
	if (svg) {
		var div = svg.getEnclosingDiv();
		if (div && div.parentNode && (div.parentNode.getAttribute('width') > 0)) {
			div.parentNode.setAttribute('width', 1);
		}
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.hideSVGCell();
	this.toggleArrow(false);
	this.toggleArrow(true);
	
	var svgTrace = zen('SVGTrace');
	if (svgTrace && svgTrace.svgWindow && svgTrace.svgWindow.svgPage && svgTrace.svgWindow.svgPage.selectItem) {
		this.onTraceSVGLoad(true);
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onRefreshContents() [ Language = javascript ]
{
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		if (child.onRefreshContents) child.onRefreshContents();
		zenInvokeCallbackMethod(child.onrefresh,child,'onrefresh');
	}
	this.adjustSize(); // Call adjustSize() here to prevent errors in IE
}

ClientMethod findNumberInSVG(svgDoc) [ Language = javascript ]
{
	/* returns itemCount#firstMsgId as an array*/
	
	var svgBuildInfo = 0;
	
	if (!svgDoc) {
		var trace = zen('SVGTrace');
		if (trace) {
			var svgDoc = trace.getSVGDocument();		
		}
	}
	if (svgDoc) {
		var annotation = svgDoc.getElementById('buildinfo');
		if (annotation) svgBuildInfo = annotation.getAttribute('data');
	}
	
	if (!svgBuildInfo) {svgBuildInfo='0~0~'}
	
	return svgBuildInfo.split('~');
}

/// User clicked a link for Definition. Display the Rule View page.
/// Display the rule definition in a popup, so the user doesn't lose the current page in the rule list.
ClientMethod showRule(rule, evt, ruleSet, path) [ Language = javascript ]
{
	if (!this.canViewRules) {
		alert(this.msgNotPermitted);
		return false;
	}
	if (evt) {
		if (evt.stopPropagation) {
			evt.stopPropagation();
		} else {
			evt.cancelBubble = true;
		}
	}
	var args = [];
	if (ruleSet) {
		args.push('RULESET=' + encodeURIComponent(ruleSet));
	}
	if (path) {
		args.push('PATH=' + encodeURIComponent(path));
	}
	
	var newName = zenPage.GetClassName(rule);
	var ruleLink = zenPage.ruleEditorBaseURL+'&rule='+encodeURIComponent(newName) + '&' + args.join('&');
	window.open(zenLink(ruleLink));
}

/// Get the class name (in case what's been selected is an alias, which is invalid as a class name).
/// If the id is already a class name, that class name will be returned as the return value.
ClassMethod GetClassName(id As %String) As %String [ ZenMethod ]
{
	Quit ##class(Ens.Projection.Rule).ResolveRuleAlias(id)
}

/// Following resend associated methods based on
/// EnsPortal.Template.filteredViewer methods 
ClientMethod doResend(hdrId) [ Language = javascript ]
{
	if (!this.canResend) {
		alert(this.msgNotPermitted);
		return false;
	}
	var searchKey = zenPage.SaveResendID(hdrId);
	url = zenPage.getResendURL(searchKey);
	/*	Replace window with resend. 
		Will return to start of session after resend
		if user selects SessionId link. */
	if (url) zenPage.gotoPage(url); 
	return;
}

/// Save ID values for Resend.
ClassMethod SaveResendID(hdrId As %String) As %String [ ZenMethod ]
{
	// Move ID into IRIS.Temp
	Set ctKey=$I(^IRIS.Temp.ResendIDs) 
	Set ^IRIS.Temp.ResendIDs(ctKey, hdrId) = ""
	Set ^IRIS.Temp.ResendIDs(ctKey) = 1
	Quit ctKey
}

/// Use current values of the search criteria and/or selected values to create a URL for the message resend page.
ClientMethod getResendURL(key, useFilter) As %String [ Language = javascript ]
{
	var url = '';
	// we are only resending one specific IDs which was previoulsy stored in the database under a key
	if (key.length > 0) {
		url = this.resendPage + '?';
		url += 'KEY=' + key;
	}
	return url;
}

ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Set tResourceRequired = ##super(pMethod)
	If tResourceRequired = "" {
		Set tResourceRequired = $case(pMethod, 
			"SaveResendID"		: ..#RESENDRESOURCE,
								: ""
			)
	}
	Return tResourceRequired
}

}
