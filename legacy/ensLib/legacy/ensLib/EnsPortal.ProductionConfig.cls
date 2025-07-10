/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Production configuration page.
/// notify if settings modified, notify if settings externally modified, disable form update while modified	
Class EnsPortal.ProductionConfig Extends (EnsPortal.Template.prodConfigSCPage, EnsPortal.Util.PageLinks) [ System = 4 ]
{

/// JavaScript debug library
/// Usage: ZLM.dumpObj(object);
Parameter JSINCLUDES = "zenCSLM.js,EnsPortal_Component.js,zenMenusSMPEns.js";

// ZHJ037: add zenMenusSMPEns.js to override the Menu style

/// Displayed name of this page.
Parameter PAGENAME = "Production Configuration";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "list";

/// User needs READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to make changes 
/// to the Production configuration. Other actions require alternate privileges.
Parameter EDITRESOURCE = "%Ens_ProductionConfig:WRITE";

/// ID of Production passed in the URL.
Property productionIdURL As %String(ZENURL = "PRODUCTION");

/// Name of selected host passed in the URL to be initially selected on the diagram
Property selectedHost As %String(ZENURL = "HOST");

/// visual aid
Property visualAid As %String(ZENURL = "VISUALAID");

/// ID of Production to display.
Property productionId As %String [ InitialExpression = {..GetCurrentProduction()} ];

/// Index number of current selected item.
Property currItem As %Integer [ InitialExpression = -1 ];

Property multiItems As array Of %Integer;

/// Current selected Category.
Property currCategory As %String;

/// Current tab (used when moving to a different tab to return later to the same tab it was before).
Property currTabNo As %Integer [ InitialExpression = 0 ];

/// Current refresh mode.
Property refreshMode As %Boolean [ InitialExpression = 0 ];

Property refreshRate As %Integer [ InitialExpression = 0, Internal ];

/// Specifies what property is used to draw the bus diagram.
Property busProperty As %ZEN.Datatype.string [ InitialExpression = "busPartner" ];

/// Indicates if system is Windows 64-bits (used to show property Exec64 when applicable).
Property isWin64 As %ZEN.Datatype.boolean [ InitialExpression = {$$$isWINDOWS && $system.Version.Is64Bits()} ];

/// OS platform ("Windows", "UNIX" or "VMS")
Property OS As %String [ InitialExpression = {$system.Version.GetBuildOS()} ];

/// Zen proxy object to help determine what actions a user may take on the page.
Property securityHelper As %ZEN.proxyObject;

Property msgLoading As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Loading...")} ];

Property msgGoToQueues As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Go To Queues")} ];

Property msgGoToEventLog As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Go To Event Log")} ];

Property msgGoToMessageViewer As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Go To Message Viewer")} ];

Property msgGoToJobs As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Go To Jobs")} ];

Property msgSDSOverridden As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This core setting is currently specified using a System Default Setting. Modify or delete the appropriate System Default Setting to change this setting.")} ];

Property msgSDSEnabledOverridden As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("The production definition Enabled setting for this item is currently specified using a System Default Setting. Either use the temporary Stop,Start Actions buttons or modify the appropriate System Default Setting.")} ];

Property tabFontSizeForGerman As %String [ InitialExpression = {$S(%session.Language="de":"td.tabGroupButtonOn, td.tabGroupButtonOff, td.tabGroupButtonDisabled { font-size: 12px; }", 1:"")} ];

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

/// Is the user permitted to view Process Details
Property canViewProcessDetails As %Boolean [ InitialExpression = {$system.Security.Check("%Admin_Operate","USE")} ];

/// Is the user permitted to view Message Trace
Property canViewMessageTrace As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageTrace","USE")} ];

/// Name of existing deployment export file (on server).
Property deploymentFile As %ZEN.Datatype.string;

/// Array of queue counts to keep track of queue growth across refreshes
Property queueCount As array Of %Integer;

/// Flag to indicate whether the user has WRITE permissions on the Databases used by this production
Property canEditDB As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Flag to indicate if the default db is mounted R/O
Property dbIsRO As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Message to inform user they don't have WRITE permissions on the DB required to perform an action
Property msgNoDBPermissions As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This action writes to a database that you do not have WRITE permissions on.")} ];

/// Index number of current item that is being restarted.
/// -1 is used to restart using disable and then enable - hence modifies the production
/// -2 is used to restart using the temporary stop and start apis and does not modify the production.
Property currRestartItem As %Integer [ InitialExpression = -1 ];

/// Used to validate that when restarting the item after a disable the item number has not changed.
Property currRestartName As %String;

/// Flag to indicate whether the settingsPanel is currently hidden.
Property settingsHidden As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.zenLabel {
	font-size: 10pt;
	padding-right: 5px;
}

.ribbonSortOption {
	color: #3B84BC;
}

.settingLabel {
	padding-left: 3px;
	padding-top: 3px;
	cursor: help;
}

.labelText {
	color: #404080;
	font-size: 10pt;
	display: block;
	background: #F0F0F0;
	border: 1px solid gray;
	padding: 2px;
	margin-bottom: 3px;
}

a.radioSetCaption {
	vertical-align: top;
	text-decoration: none;
	color: #404040;
}

#propertyPane {
	position: relative;
	background: rgb(156,154,140);
	height: 500px;
	width: 396px;
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
}

#(%page.tabFontSizeForGerman)#

#tabClass {
	overflow: auto;
	height: 100%;
	width: 100%;
}

#propertyCommands {
	color: white;
}

.msgLoading {
	left: 5px;
	position: relative;
	font-size: 10pt;
}

.msgLoading2 {
	top: 50px;
	left: 100px;
	position: relative;
	font-size: 11pt;
	padding-left: 8px;
	padding-right: 8px;
	background: #8080F0;
	color: white;
}

table.queueHeader,
table.logHeader {
	margin-left: 10px;
	margin-right: 10px;
	width: 370px;
}

table.queueHeader td,
table.logHeader td {
	padding-top: 20px;
	padding: 2px;
	color: #404040;
}

div.queueTableWrapper {
	left: 0px;
	right: 0px;
	margin-left: 0px;
	margin-right: 0px;
	height: 100%;
}

div.logTableWrapper {
	left: 0px;
	right: 0px;
	margin-left: 0px;
	margin-right: 0px;
	height: 100%;
	overflow-y: auto;
	overflow-x: hidden;
}

table.queueTable {
	width: 370px;
	background: white;
	font-size: 10px;
	margin: 5px;
	height: 100px;
	overflow-y: auto;
}

table.logTable {
	width: 370px;
	background: white;
	font-size: 10px;
	margin: 5px;
}

table.queueTable th,
table.logTable th {
	padding: 2px;
	background: white;
	font-size: 10pt;
	font-weight: bold;
	color: #5BA4DC;
	text-align: left;
}

table.queueTable td,
table.logTable td {
	padding: 2px;
	padding-right:10px;
	font-size: 10pt;
	color: #404040;
}

table.tpTable td {
	padding-right:10px;
}

table tr.rowEven {
	background: #F0F0F0;
}

table tr.rowOdd {
	background: white;
}

table tr.queueRowHighlighted {
	background: yellow;
}

table tr.queueRowSelected {
	background: #CCAA00;
}

.infoLabel {
	color: rgb(71,72,67);
	font-size: 10pt;
}

/* diagram header */
#diagramHeader {
	position: relative;
	vertical-align: bottom;
	background: #404040;
	background-image: url(images/grad-gray-10x500.png);
	background-repeat: repeat-x;
	border-right: 1px solid black;
	display: none;
}
.dgmProductionRunning {
	background: #40A040;
	color: white;
	font-size: 11px;
	font-weight: bold;
	margin-bottom: 0px;
	padding: 2px;
	height: 17px;
	border: 1px solid #406040;
	border-radius: 2px;
}
.dgmProductionStopped {
	background: gray;
	color: white;
	font-size: 11px;
	font-weight: bold;
	margin-bottom: 0px;
	padding: 2px;
	height: 17px;
	border: 1px solid #406040;
	border-radius: 2px;
}
.dgmProductionSuspended {
	background: #F0F0A0;
	color: black;
	font-size: 11px;
	font-weight: bold;
	margin-bottom: 0px;
	padding: 2px;
	height: 17px;
	border: 1px solid #406040;
	border-radius: 2px;
}
.dgmProductionTroubled {
	background: #A04040;
	color: white;
	font-size: 11px;
	font-weight: bold;
	margin-bottom: 0px;
	padding: 2px;
	height: 17px;
	border: 1px solid #406040;
	border-radius: 2px;
}
.dgmProductionNetworkStopped {
	background: red;
	color: white;
	font-size: 11px;
	font-weight: bold;
	margin-bottom: 0px;
	padding: 2px;
	height: 17px;
	border: 1px solid #406040;
	border-radius: 2px;
}
.dgmProductionUnknown {
	background: black;
	color: white;
	font-size: 11px;
	font-weight: bold;
	margin-bottom: 0px;
	padding: 2px;
	height: 17px;
	border: 1px solid #406040;
	border-radius: 2px;
}
.dgmHeader {
	position: absolute;
	bottom: 0px;
	left: 0px;
	overflow: hidden;
}
.dgmHeaderLabel {
	font-weight: bold;
	font-size: 12pt;
	color: #404040;
}
.dgmHeaderCmd {
	text-decoration: none;
	font-size: 10pt;
	color: #98923A;
}
.dgmHeaderCmd:hover {
	text-decoration: none;
	color: darkred;
}
.dgmHostBar {
	margin-bottom: 0px;
	padding: 2px;
	height: 17px;
}
.dgmAction {
	color: #3B84BC;
	font-size: 10pt;
	text-decoration: none;
}
.dgmAction:hover {
	color: darkred;
	text-decoration: none;
}
.dgmActionChoose {
	color: white;
	background: blue;
	font-size: 10pt;
	text-decoration: none;
}
.dgmActionChoose:hover {
	color: darkred;
	text-decoration: none;
}
.dgmSelect {
	font-size: 0.9em;
	width: 120px;
}

#propertyTitle {
	width: 396px;
}

#componentName {
	color: white;
	font-size: 14pt;
	padding: 3px;
	overflow: hidden;
}

.icon {
}

.iconHover {
	background: #FFEEAA;
}

.selectorModalBox {
	width: 300px;
	overflow-x: auto;
}

.sessionLink {
	cursor: pointer;
	color: #3B84BC;
	text-decoration: none;
}
/* override gray used by input[disabled] */
.selectorInput:disabled {
	background-color: #FFFFFF;
}
</style>
}

/// Styles used by SVG config diagram.
XData SVGStyle
{
<style type="text/css">

/* page-defined styles */

#svgDiagram {
	/* prevent Chrome/Safari from selecting text during drag */
	-webkit-user-select: none;
	/* prevent Firefox from selecting text during drag */
	-moz-user-select: none;
}

.hostLabel {
	pointer-events: none;
	font-size: 10pt;
	fill: black;
	stroke: none;
	font-family: arial;
}

.messageText {
	pointer-events: none;
	font-size: 11pt;
	fill: black;
	stroke: none;
	font-family: arial;
}

.messageTextError {
	pointer-events: none;
	font-size: 11pt;
	fill: red;
	font-family: arial;
	font-weight: bold;
}

.laneTitle {
	pointer-events: none;
	font-size: 14pt;
	fill: black;
	stroke: none;
	font-family: arial;
}

.itemNormal {
	stroke: gray;
	stroke-width: 1;
	opacity: 1.0;
}

.itemNormalStart {
	stroke: #404080;
	stroke-width: 2;
	opacity: 1.0;
}

.itemPartner {
	fill: url(#glow-silver);
	stroke: black;
	stroke-width: 1;
}

.msgBox {
	fill: #7070FF;
	stroke: white;
	stroke-width: 1;
	opacity: 0.85;
}

.msgBoxText {
	pointer-events: none;
	font-size: 11pt;
	fill: #F0F0F0;
	stroke: none;
	font-family: arial;
}

.busStrip {
	fill: url(#glow-silverDiag);
	stroke: black;
	stroke-width: 1;
	opacity: 1.0;
}

.itemHover {
	stroke: #AAEEFF;
	stroke-width: 4;
	stroke-opacity: 0.8;
}

/* hover during connect */
.itemHoverAccept {
	stroke: #FFAAAA;
	stroke-width: 4;
	stroke-opacity: 0.8;
}

.itemRect {
	fill: white;
	fill-opacity: 0.75;
	stroke: none;
	stroke-width: 0.25;
}

.itemRectHover {
	fill: #FFEEAA;
	fill-opacity: 0.50;
	stroke: none;
	stroke-width: 0.25;
}

.itemRectSelect {
	fill: #FFEEAA;
	fill-opacity: 1.0;
	stroke: #808080;
	stroke-width: 2.5;
	stroke-opacity: 0.5;
}

.itemRectSelectHover {
	fill: #FFEEAA;
	fill-opacity: 1.0;
	stroke: #808080;
	stroke-width: 2.5;
	stroke-opacity: 1.0;
}

.itemRectRed {
	fill: red;
	fill-opacity: 0.75;
	stroke: none;
	stroke-width: 0.25;
}

.itemRectRedHover {
	fill: #FF6633;
	fill-opacity: 0.75;
	stroke: none;
	stroke-width: 0.25;
}

.itemRectRedSelect {
	fill: red;
	fill-opacity: 0.75;
	stroke: #808080;
	stroke-width: 2.5;
	stroke-opacity: 0.5;
}

.itemRectRedSelectHover {
	fill: #FF6633;
	fill-opacity: 0.75;
	stroke: #808080;
	stroke-width: 2.5;
	stroke-opacity: 1.0;
}

.listingConnectorLine {
	stroke: #606080;
	stroke-width: 2;
	opacity: 0.5;
}

.connectorLine {
	stroke: #606080;
	stroke-width: 2;
}

.duplBoxRect {
	fill: #0000A8;
	fill-opacity: 0.6;
	stroke: none;
}

.duplBoxLabel{
	pointer-events: none;
	font-size: 7pt;
	fill: white;
	stroke: none;
	font-family: arial;	
}

/* tooltip */
.overlay {
	fill: #FFEEAA;
	fill-opacity: 0.9;
	stroke: #404040;
	stroke-width: 4;
	stroke-opacity: 0.25;
}

.RubberBand {
	fill: none;
	stroke: #404040;
	stroke-width: 2;
	stroke-linecap: round;
}

.tooltipLabel {
	pointer-events: none;
	font-size: 8pt;
	fill: #606060;
	stroke: none;
	font-family: arial;
}

.tooltipValue {
	pointer-events: none;
	font-size: 11pt;
	fill: #404040;
	stroke: none;
	font-family: arial;
}

.queueRowHighlighted {
	background: yellow;
}

.queueRowSelected {
	background: yellow;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>

<timer id="statusTimer" timeout="0" ontimeout="zenPage.refreshStatusHandler();"/>

<!-- Provide Production information in JSON format -->
<jsonProvider id="productionInfo"
	 OnGetArray="GetProductionArray"
/>

<!-- Provide json callbacks for SC -->
<jsonProvider id="scProduction"
	OnGetTargetObject="SCLoadProduction"
	OnSubmitContent="SCSubmitProduction"
/>

<!-- Provide connection information by name in JSON format -->
<jsonProvider id="connectionInfo"
	 OnGetArray="GetConnectionArray"
>
<parameter id="ciHostName" paramName="hostName"/>
<parameter paramName="productionName" value="#(%page.productionId)#"/>
</jsonProvider>

<!-- Provide connection information by id in JSON format -->
<jsonProvider id="connectionInfoById"
	 OnGetArray="GetConnectionArrayById"
>
<parameter id="ciHostId" paramName="hostId"/>
<parameter paramName="productionName" value="#(%page.productionId)#"/>
<parameter id="ciCat" paramName="cat"/>
</jsonProvider>

<!-- Provide settings information by name in JSON format -->
<jsonProvider id="settingsInfo"
	 OnGetArray="GetSettingsArray"
>
<parameter id="siHostName" paramName="hostName"/>
<parameter paramName="productionName" value="#(%page.productionId)#"/>
</jsonProvider>

<!-- Provide settings information by id in JSON format - siiHostName for use when class compiled-->
<jsonProvider id="settingsInfoById"
	 OnGetArray="GetSettingsArrayById"
>
<parameter id="siHostId" paramName="hostId"/>
<parameter id="siiHostName" paramName="hostName"/>
<parameter paramName="productionName" value="#(%page.productionId)#"/>
</jsonProvider>

<!-- Provide queue information in JSON format -->
<jsonProvider id="queueInfo"
	 OnGetArray="GetQueueArray"
>
<parameter id="qiHostName" paramName="hostName"/>
<parameter paramName="productionName" value="#(%page.productionId)#"/>
</jsonProvider>

<!-- Provide log information in JSON format -->
<jsonProvider id="logInfo"
	 OnGetArray="GetLogArray"
>
<parameter id="liHostName" paramName="hostName"/>
<parameter paramName="productionName" value="#(%page.productionId)#"/>
</jsonProvider>

<!-- Provide jobs information in JSON format -->
<jsonProvider id="jobsInfo"
	 OnGetArray="GetJobsArray"
>
<parameter id="jiHostName" paramName="hostName"/>
<parameter paramName="productionName" value="#(%page.productionId)#"/>
</jsonProvider>

<!-- options along top of page -->
<hgroup id="mainGroup" cellVAlign="top">
<vgroup id="diagramPane">
<html id="diagramHeader" OnDrawContent="DrawDiagramHeader"/>
<svgFrame id="svg" width="0" height="400">
<ownerDraw id="svgDiagram" height="500" width="800" onrender="zenPage.drawDiagram(zenThis);"/>
</svgFrame>
</vgroup>
<vgroup id="propertyPane" hidden="false">
<html id="propertyTitle">
<div id="componentName"><br/></div>
</html>
<tabGroup id="propertyTabs" showTabBar="true">
<tab id="tabSettings" caption="Settings" labelPosition="left">
<vgroup>
<spacer height="5" />
<hgroup id="grpSettingsScroll" aux="%" cellVAlign="middle" labelPosition="left" cellStyle="padding:0px;" hidden="true">
<spacer width="5" />
<button id="btnApply" caption="Apply" controlClass="commandButton" onclick="zenPage.applyChanges();" />
<spacer width="8" />
<image id="btnExpandAll" src="images/arrow1D.gif" title="Expand all" onclick="zenPage.expandAll(zenPage.settingsExpanded);" hidden="false"/>
<spacer width="8" />
<image id="btnItemDefaults" src="images/goto.png" title="Select settings defaults" onclick="zenPage.selectSettingsDefaults();" hidden="false"/>
<spacer width="10" />
<text size="20" id="ctrlSearch" label="Search:" labelClass="zenLabel settingLabel" title="Show all settings whose display name, property name or value contains the search text" enclosingStyle="padding-left:0px; padding-bottom: 3px;" onchange = "zenPage.searchChanged();" onkeyup = "zenPage.searchChanged();" />
<image id="btnClearSearch" src="images/MacCloseB.png" title="Clear Search Text" onclick="zenPage.clearSearch();" />
</hgroup>
<html id="settingsLoading" hidden="true">
<span class="msgLoading"> #(%page.msgLoading)# </span>
</html>
<form id="settingsForm" labelPosition="top" onrefresh="zenPage.renderHelpText();" enclosingStyle="overflow:auto; height:500px;">
</form>
</vgroup>
</tab>
<tab id="tabQueue" caption="Queue">
<spacer height="5" />
<hgroup id="queueTblScroll">
<spacer width="5" />
<label id="lblQCount" controlClass="zenLabel" value="items"/>
<spacer width="25" />
<button id="btnAbortMsgs" caption="Abort All" title="Abort all messages in this queue" controlClass="commandButton" onclick="zenPage.queueAbortMsgs();"/>
<spacer width="50" />
<html id="divQueue">
<a id="queueLink" class="ribbonSortOption" style="font-size:10pt" title="Go to the Queues page to view details" href="#" onClick="zenPage.visitQueuesPage();return false;">#(%page.msgGoToQueues)#</a>
<span>  </span><img src="images/bullet-ul-excdev.gif" style="cursor:pointer;" title="Go to the Queues page to view all queues" onClick="window.open(zenLink('EnsPortal.Queues.zen'),'queues');return false;"/>
</html>
</hgroup>
<form id="queueForm" labelPosition="top" enclosingStyle="overflow:auto; height:500px;">
<vgroup id="grpQueue">
<label controlClass="zenLabel" value="Select an item to view the current content of its queues"/>
</vgroup>
</form>
</tab>
<tab id="tabEventLog" caption="Log">
<spacer height="5" />
<html id="divLog">
<div class="zenLabel" valign="middle">Select an item to view its associated event log entries</div>
<a class="ribbonSortOption" style="font-size:10pt" href="#" title="View these entries in the Event Log page" onClick="window.open(zenLink('EnsPortal.EventLog.zen'),'eventlog');return false;">#(%page.msgGoToEventLog)#</a>
<span>  </span><a class="dgmHeaderCmd" title="View all entries in the Event Log page" href="#" onClick="window.open(zenLink('EnsPortal.EventLog.zen'),'eventlog');return false;"><img src="images/bullet-ul-excdev.gif"/></a>
</html>
</tab>
<tab id="tabMessages" caption="Messages">
<spacer height="5" />
<hgroup>
<spacer width="10em" />
<html id="divMessages">
<a class="ribbonSortOption" align="right" style="font-size:10pt" title="View these messages in the Message Viewer page" href="#" onClick="zenPage.gotoMessageViewer();return false;">#(%page.msgGoToMessageViewer)#</a>
<span>  </span><a class="dgmHeaderCmd" title="View all messages in the Message Viewer page" href="#" onClick="window.open(zenLink('EnsPortal.MessageViewer.zen'),'messages');return false;"><img src="images/bullet-ul-excdev.gif"/></a>
</html>
</hgroup>
<spacer height="5" />
<hgroup>
<spacer width="5" />
<tablePane id="tblMessagesProduction" hidden="false"
	rowSelect="false"
	cellSpacing="2" 
	maxRows="100"
	pageSize="100"
	showZebra="true"
	initialExecute="false"
	sql="SELECT TOP 100 ID, SessionId, TimeCreated, Status, SourceConfigName, TargetConfigName
	FROM Ens.MessageHeader
	WHERE ID=SessionId
	ORDER BY SessionId DESC"
	>
<column colName="ID" hidden="true" />
<column colName="SessionId" header="Session" OnDrawCell="DrawMsgTraceCell"/>
<column colName="TimeCreated" header="Date/Time" OnDrawCell="FormatDateTime" />
<column colName="Status" header="Status" />
<column colName="SourceConfigName" header="Source" />
<column colName="TargetConfigName" header="Target" />
</tablePane>
<tablePane id="tblMessagesItem" hidden="true"
	rowSelect="false"
    cellSpacing="2" 
	maxRows="100"
	pageSize="100"
	showZebra="true"
	initialExecute="false"
	sql="SELECT TOP 100 ID, TimeCreated, Status, SourceConfigName, TargetConfigName, MessageBodyClassName, MessageBodyId
    FROM Ens.MessageHeader
    WHERE ID IN (
            SELECT TOP 100 ID
            FROM Ens.MessageHeader
            WHERE SourceConfigName = ?
            ORDER BY ID DESC
        UNION
            SELECT TOP 100 ID
            FROM Ens.MessageHeader
            WHERE TargetConfigName = ?
            ORDER BY ID DESC
    )
    ORDER BY ID DESC">
<parameter id="msgTableSource" name="SourceHost" value="" />
<parameter id="msgTableTarget" name="TargetHost" value="" />
<column colName="ID" header="Header" OnDrawCell="DrawMsgTraceCell"/>
<column colName="TimeCreated" header="Date/Time" OnDrawCell="FormatDateTime" />
<column colName="Status" header="Status" />
<column colName="SourceConfigName" header="Source" />
<column colName="TargetConfigName" header="Target" />
<column colName="MessageBodyClassName" header="Body" />
<column colName="MessageBodyId" header="ID" />
</tablePane>
</hgroup>
</tab>
<tab id="tabJobs" caption="Jobs">
<spacer height="5" />
<hgroup>
<spacer width="10em" />
<html>
<a class="ribbonSortOption" style="font-size:10pt" title="Go to the Jobs page to view all jobs" href="#" onClick="window.open(zenLink('EnsPortal.Jobs.zen'),'jobs');return false;">#(%page.msgGoToJobs)#</a>
<span>  </span><a class="dgmHeaderCmd" align="right" title="Go to the Jobs page to view all jobs" href="#" onClick="window.open(zenLink('EnsPortal.Jobs.zen'),'jobs');return false;"><img src="images/bullet-ul-excdev.gif"/></a>
</html>
</hgroup>
<spacer height="5" />
<hgroup>
<spacer width="5" />
<button id="btnAbort" caption="Abort" title="Abort the current message being retried for the selected job" controlClass="commandButton" onclick="zenPage.jobAbortMsg();"/>
<spacer width="5" />
<button id="btnSupend" caption="Suspend" title="Suspend the current message being retried for the selected job" controlClass="commandButton" onclick="zenPage.jobSuspendMsg();"/>
<spacer width="5" />
<button id="btnStop" caption="Stop" title="Stop the selected job" controlClass="commandButton" onclick="zenPage.jobStop();"/>
<spacer width="5" />
</hgroup>
<spacer height="5" />
<hgroup>
<spacer width="5" />
<tablePane id="tblJobsProduction" hidden="false"
    cellSpacing="2"
	useSnapshot="false"
	valueColumn="Job"
	maxRows="100"
	pageSize="100"
 	queryClass="Ens.Job"
	queryName="Enumerate"
	showZebra="true"
	initialExecute="false"
	dataSource="columns"
	showValueInTooltip="false"
	width="auto"
	extraColumnWidth="10px"
	>
<column colName="Job" header="Job" hidden="false" OnDrawCell="DrawProcessdetails"/>
<column colName="Status" header="Status" hidden="false" />
<column colName="ConfigName" header="Configuration Name" hidden="false" />
<condition colName="Status" predicate="EQ" value="Error" rowStyle="background: pink;"/>
<condition colName="Status" predicate="EQ" value="Retry" rowStyle="background: orange;"/>
<condition colName="Status" predicate="EQ" value="Inactive" rowStyle="background: yellow;"/>
<condition colName="Status" predicate="EQ" value="Dead" rowStyle="background: red;"/>
<condition colName="Status" predicate="EQ" value="Starting" rowStyle="background: lightblue;"/>
 </tablePane>
<tablePane id="tblJobsItem" hidden="true"
    cellSpacing="2"
	useSnapshot="false"
	valueColumn="Job"
	maxRows="100"
	pageSize="100"
	queryClass="Ens.Util.Statistics"
	queryName="EnumerateJobStatus"
	showZebra="true"
	initialExecute="false"
	dataSource="columns"
	showValueInTooltip="false"
	width="auto"
	extraColumnWidth="10px"
	>
<parameter id="jobsTableHost" name="pHostName" value="" />
<column colName="Job" header="Job" hidden="false" OnDrawCell="DrawProcessdetails"/>
<column colName="Status" header="Status" hidden="false" />
<column colName="AdapterState" header="Adapter" hidden="false" />
<column colName="Retry" header="Retry" hidden="false" />
<column colName="ActiveMessage" header="Message" hidden="false" OnDrawCell="DrawMsgTraceCell"/>
<condition colName="Status" predicate="EQ" value="Error" rowStyle="background: pink;"/>
<condition colName="Status" predicate="EQ" value="Retry" rowStyle="background: orange;"/>
<condition colName="Status" predicate="EQ" value="Inactive" rowStyle="background: yellow;"/>
<condition colName="Status" predicate="EQ" value="Dead" rowStyle="background: red;"/>
<condition colName="Status" predicate="EQ" value="Starting" rowStyle="background: lightblue;"/>
 </tablePane>
 </hgroup>
</tab>
<tab id="tabActions" caption="Actions">
<vgroup width="80%">
<spacer height="15" />
<hgroup id="grpTest" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/our_process_a_48.gif"/>
<vgroup>
<button id="btnTest" caption="Test" controlClass="commandButton" title="Send a test message to this item" onclick="zenPage.testItem();"/>
<label controlClass="zenLabel" label="Test this item"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpTempStart" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/flag_square_48.gif"/>
<vgroup>
<button id="btnTempStart" caption="Start" controlClass="commandButton" title="Start this item that has been stopped temporarily (the production class will remain unchanged)" onclick="zenPage.tempStartItem();"/>
<label controlClass="zenLabel" label="Start this item if temporarily stopped"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpTempStop" cellStyle="padding: 10px;" cellVAlign="top">
<image src="deepsee/ds2_circle_stop_44.png" height="48px" width="48px"/>
<vgroup>
<button id="btnTempStop" caption="Stop" controlClass="commandButton" title="Stop this item temporarily (the production class will remain unchanged)" onclick="zenPage.tempStopItem();"/>
<label controlClass="zenLabel" label="Stop this item temporarily"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpRestartOne" cellStyle="padding: 10px;" cellVAlign="top">
<image src="deepsee/ds2_refresh_44.png" height="48px" width="48px"/>
<vgroup>
<button id="btnRestartOne" caption="Restart" controlClass="commandButton" title="Restart the selected item (the production class will remain unchanged)" onclick="zenPage.tempRestartItem();"/>
<label controlClass="zenLabel" label="Restart this item"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpEnable" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/flag_square_48.gif"/>
<vgroup>
<button id="btnEnable" caption="Enable" controlClass="commandButton" title="Enable the selected items" onclick="zenPage.enableMultiItems();"/>
<label controlClass="zenLabel" label="Enable these items"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpDisable" cellStyle="padding: 10px;" cellVAlign="top">
<image src="deepsee/ds2_circle_stop_44.png" height="48px" width="48px"/>
<vgroup>
<button id="btnDisable" caption="Disable" controlClass="commandButton" title="Disable the selected items" onclick="zenPage.disableMultiItems();"/>
<label controlClass="zenLabel" label="Disable these items"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpRestart" cellStyle="padding: 10px;" cellVAlign="top">
<image src="deepsee/ds2_refresh_44.png" height="48px" width="48px"/>
<vgroup>
<button id="btnRestart" caption="Restart" controlClass="commandButton" title="Restart the selected items (the production class will remain unchanged)" onclick="zenPage.restartMultiItems();"/>
<label controlClass="zenLabel" label="Restart these items"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpDelete" cellStyle="padding: 10px;" cellVAlign="top">
<image src="deepsee/cancel_48.png"/>
<vgroup>
<button id="btnDelete" caption="Delete" controlClass="commandButton" title="Delete this item from the Production configuration" onclick="zenPage.deleteItem();"/>
<label controlClass="zenLabel" label="Delete this item from the Production"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpCopy" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/mini_sites_48.gif"/>
<vgroup>
<button id="btnCopy" caption="Copy" controlClass="commandButton" title="Add a duplicate copy of this item to the Production under a new name" onclick="zenPage.copyItem();"/>
<label controlClass="zenLabel" label="Create a duplicate copy of this item"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpChangeClass" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/table_properties_48.gif"/>
<vgroup>
<button id="btnChangeClass" caption="Change Class" controlClass="commandButton" title="Select another class to associate with this item" onclick="zenPage.changeClass();"/>
<label controlClass="zenLabel" label="Change the class name for this item"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpDocument" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/report_48.gif"/>
<vgroup>
<button id="btnDocument" caption="Document" controlClass="commandButton" title="Generate or view documentation for this Production" onclick="zenPage.documentProduction();"/>
<label controlClass="zenLabel" label="Production documentation"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpExport" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/software_development_48.gif"/>
<vgroup>
<button id="btnExport" caption="Export" controlClass="commandButton" title="Construct and export a package for deployment into another Production from this item and the components directly connected to it" onclick="zenPage.exportItem();"/>
<label controlClass="zenLabel" label="Export for deployment"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpAmendExport" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/software_development_48.gif"/>
<vgroup>
<button id="btnAmendExport" caption="Re-Export" controlClass="commandButton" title="Open and change an existing exported deployment package for deployment" onclick="zenPage.reexportItem();"/>
<label controlClass="zenLabel" label="Amend existing deployment package"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpNew" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/write_48.gif"/>
<vgroup>
<button id="btnNew" caption="New" controlClass="commandButton" title="Leave this Production and build a new Production" onclick="zenPage.newProduction();"/>
<label controlClass="zenLabel" label="Build a new Production"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpOpen" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/folder_48.gif"/>
<vgroup>
<button id="btnOpen" caption="Open" controlClass="commandButton" title="Leave this Production and open a different Production" onclick="zenPage.loadProduction();"/>
<label controlClass="zenLabel" label="Open a different Production"/>
<spacer height="10" />
</vgroup>
</hgroup>
</vgroup>
</tab>
</tabGroup>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set tProd = ..GetCurrentProduction()
	If tProd'="" {
		If ""=##class(EnsPortal.Utils).GetCurrentProductionName() {
			try {
				If ..canEditDB { Set ^EnsPortal.Settings($Username,"LastProduction")=tProd }
				Else { Set ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","LastProduction")=tProd }
			} Catch {}
		}
		Quit tProd
	}
	Else {
		try {
			Kill:..canEditDB ^EnsPortal.Settings($Username,"LastProduction")
			Kill ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","LastProduction")
		} catch {}
		Quit $$$Text("Production Configuration")
	}
}

Method GetTitle() As %String [ ZenMethod ]
{
	Quit ..GetCurrentProduction()
}

ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return zenPage.GetTitle();
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Production Configuration")

	// Set pViewIcons(2) = $LB("productions",$$$Text("Show Production view"),"portal/view_box4.png")
	Set pViewIcons(1) = $LB("list",$$$Text("Show listing view"),"portal/view_box_list.png")
	Set pViewIcons(2) = $LB("monitor",$$$Text("Show monitor view"),"portal/view_box_grid.png")
	Set pViewIcons(3) = $LB("bus",$$$Text("Show bus view"),"portal/view_bus.png")

	// command buttons
	Set iCmd=0
	// $LB(id,caption,help,onclick,hidden)
	If ""=..productionId {
		If ..canEdit {
			Set pCommands($I(iCmd)) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new Production definition"),"zenPage.newProduction();")
		}
		Set pCommands($I(iCmd)) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Open a Production definition"),"zenPage.loadProduction();")
	} Else {
		If $system.Security.Check("%Ens_ProductionRun","USE") {
			Set pCommands($I(iCmd)) = $LB("cmdStart",$$$Text("Start"),$$$Text("Start this Production"),"zenPage.startProduction();")
			Set pCommands($I(iCmd)) = $LB("cmdStop",$$$Text("Stop"),$$$Text("Stop this Production"),"zenPage.stopProduction();")
			Set pCommands($I(iCmd)) = $LB("cmdUpdate",$$$Text("Update"),$$$Text("Update Production"),"zenPage.updateProduction('update');",1)
			Set pCommands($I(iCmd)) = $LB("cmdRecover",$$$Text("Recover"),$$$Text("Recover Production from a crash"),"zenPage.recoverProduction();",1)
		}
	}
	// sort options
	Set pSortOptions(1) = $LB("name",$$$Text("Name"),$$$Text("Sort items by name"))
	Set pSortOptions(2) = $LB("status",$$$Text("Status"),$$$Text("Sort items by current status"))
	Set pSortOptions(3) = $LB("ordinal",$$$Text("Number"),$$$Text("Sort items by ordinal position"))
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production Configuration")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	#dim tSC = $$$OK
	// Refresh
	Set tRefresh = $$$TextHTML("Refresh the diagram")
	&html<
	<td nowrap style="padding-left:50px;">
	<image src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.reloadDiagram();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
	</td>
	<td nowrap style="padding-left:5px;padding-right:50px;">>
	If ..enableAutoRefresh {
		Set tProd = ..GetCurrentProduction()
		If tProd'="" {
			Set tState = $G(^IRIS.Temp.EnsPortal($Username,"ProductionConfig","AutoRefresh",tProd),0)
		} Else {
			Set tState = 0
		}
		&html<
		<div nowrap>
			<span id="id_refresh" style="font-size:10pt;color:#606060;font-weight:bold;">#($$$Text("Refresh:"))#</span>
			<input id="refreshOn" type="radio" name="refresh" #($S(tState=1:"checked",1:""))# onclick="zenPage.setRefreshMode(true);"/><span onclick="zenPage.setRefreshMode(true);">#($$$Text("on"))#</span>
			<input id="refreshOff" type="radio" name="refresh" #($S(tState=0:"checked",1:""))# onclick="zenPage.setRefreshMode(false);"/><span onclick="zenPage.setRefreshMode(false);">#($$$Text("off"))#</span>
		</div></td>>
	}

	#; This method will be a no-op if source control not enabled.
	Set tSC = ..%DrawSourceControlCommands()

	Quit tSC
}

/// Draw the contents of the diagram header.
Method DrawDiagramHeader(pSeed As %String) As %Status
{
	Set tProd = %page.productionId
	Set tSC = ##class(Ens.Director).GetProductionStatus(.tCurrentProduction,.tState)
	If (tState'=$$$eProductionStateShardWorkerProhibited)&&($G(tCurrentProduction)'=tProd) Set tState=$$$eProductionStateStopped
	Do ..LocalizeProductionStatus($G(tState), .tProductionStateMessage, .tProductionCSS)
	If $$$ISERR(tSC) Set tProductionStateMessage = $$$StatusDisplayString(tSC)
	&html<
	<div style="margin-left:20px;margin-right:20px">
	<table border="0" width="100%" valign="bottom" cellspacing="0" cellpadding="0">
	<tr><td nowrap width="15%"><span class="#(tProductionCSS)#" id="statusMsg">&nbsp; #(tProductionStateMessage)# &nbsp;</span>&nbsp;</td>
	>
	If ..currViewMode '= "bus" {
		If tProd '= "" {
			&html<<td nowrap width="*">&nbsp;&nbsp;&nbsp;</td>> // spacer
			// Item selection in case of multiple items with the same name; initially hidden
			&html<<td nowrap width="15%" id="id_spanChoose" align="center" class="dgmAction" style="cursor:default;visibility:hidden;" title='#($ZCVT($$$Text("Choose which item to edit, among several that have the same config name"),"O","HTML"))#'>
				#($$$TextHTML("Item:"))#
				<select id="id_Choose" onchange="zenPage.switchDuplItem();" class="dgmSelect">
				</select>&nbsp;&nbsp;&nbsp;</td>>
			// Category selection
			Set c = %page.currCategory
			Set msgAll = $$$TextHTML("All")
			&html<<td nowrap width="15%" align="center" class="dgmAction" style="cursor:default" title='#($ZCVT($$$Text("Select a category to filter items shown on the diagram"),"O","HTML"))#'>
				#($$$TextHTML("Category:"))#
				<select id="id_Category" onchange="zenPage.selectCategory(this.value);" class="dgmSelect">>
				Write "<option " Write:c="" "selected=""true""" Write "value="""" title=""",msgAll,""">",msgAll,"</option>"
				Try {
					Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateCategories")
					Set tSC = tRS.Prepare()
					If $$$ISOK(tSC) {
						Set tSC = tRS.Execute(tProd)
						If $$$ISOK(tSC) {
							While (tRS.Next()) {
								Set cat = $ZCVT(tRS.Get("Category"),"O","HTML")
								Write "<option " Write:c=cat "selected=""true""" Write "value=""",cat,""" title=""",cat,""">",cat,"</option>"
							}
						}
					}
				}
				Catch {
				}
				&html<</select>&nbsp;&nbsp;&nbsp;</td>>
			// Legend
			&html<<td nowrap width="12%" align="center"><a title='#($ZCVT($$$Text("Show legend for shapes and colors"),"O","HTML"))#' class="dgmAction" href="#" onclick="zenPage.showLegend(); return false;">
				#($ZCVT($$$Text("Legend"),"O","HTML"))#</a>&nbsp;&nbsp;&nbsp;</td>>
			// Production settings
			&html<<td nowrap width="12%" align="center"><a title='#($ZCVT($$$Text("Display general settings for the Production"),"O","HTML"))#' class="dgmAction" href="#" onclick="zenPage.selectItem(-1); return false;">
				#($ZCVT($$$Text("Production Settings"),"O","HTML"))#</a>&nbsp;&nbsp;&nbsp;</td>>
			// Arrow to hide/show setting tab
			&html<
			<td align="right">
				<div class="zendiv" id="detailExpander">
					<div class="expanderDiv">
						<a style="horizontal-align:right;" id="detailExpanderLink" class="helpCommand" href="#" onclick="zenPage.toggleSettings(); return false;" title='#($ZCVT($$$Text("Hide Settings Tabs"),"O","HTML"))#'> 
							<span id="detailExpanderArrow" class="helpArrow">&#187;</span>
						</a>
					</div>
				</div>
			</td>
			>
		}
	} else {
		&html<<td nowrap width="5%">&nbsp;</td>
		<td style="padding:10px; color:#404040;font-size:9pt;"><b>#($$$TextHTML("Service Bus View"))#</b>>
	}
	&html<
	</tr></table>
	>
	If (..currViewMode '= "bus") {
		&html<
		<table border="0" width="100%" cellspacing="0" class="dgmHostBar">
		<tr>
		>
		Set tHeader(1) = $LB("service",$$$Text("Services"),$$$Text("Services process incoming data"))
		Set tHeader(2) = $LB("process",$$$Text("Processes"),$$$Text("Processes orchestrate the flow of data"))
		Set tHeader(3) = $LB("operation",$$$Text("Operations"),$$$Text("Operations send data to external applications"))
		Set msgAdd = $$$Text("Add")
		Set hlpAdd = $$$Text("Add a new item to this column")

		Set margin = 20
		Set wid = 180
		Set x = 0
		For n = 1:1:3 {
			Set tType = $LG(tHeader(n),1)
			Set tName = $LG(tHeader(n),2)
			Set tTitle = $LG(tHeader(n),3)
			&html<
			<td class="dgmHeaderLabel" valign="bottom">
				<div id="dgmHdr_#(n)#" title="#(tTitle)#" class="dgmHeader" style="left:#(x+margin)#px;width:#(wid)#px">
				<nobr>#(tName)#&nbsp;<a title="#(hlpAdd)#" class="dgmHeaderCmd" href="#" onclick="zenPage.addItem('#(tType)#');return false;"><img border="0" alt="#(msgAdd)#" valign="bottom" src="deepsee/ds_plus_16.gif"/></a></nobr>
				</div></td>
			<td width="80%">&nbsp;</td>
			>
			Set x = x + (margin + wid)
		}
		&html<
		</tr></table>
		>
	}
	&html<
	</div>
	>
	Quit $$$OK
}

/// Update ribbon buttons based on current Production status.
ClientMethod refreshDiagramHeaderStates(redocats) [ Language = javascript ]
{
	/* 0:Unknown, 1:Running, 2: Stopped, 3: Suspended, 4: Troubled, 5: NetworkStopped, 6: RemoteShardWorkerProhibited, negative: mirror backup */
	var states = new zenProxy();
	states.productionId = zenPage.productionId;
	states.autoRefresh = (zenPage.enableAutoRefresh ? false : zenPage.refreshMode);
	states.statusSame = 0;
	var statusNum = ((zenPage.productionId == '') ? 0 : zenPage.UpdateProductionStatus(states));
	if (states.needsUpdateReason == '-1') {return;}
	zenPage.productionState = (!statusNum ? 0 : statusNum);

	var running = (statusNum == '1');
	var stopped = ((statusNum >= 2)&&(statusNum <= 4));
	var update = (states.needsUpdate != '0') && (states.needsUpdate != 'undefined');
	var troubled = (statusNum == '4');
	var disableStartButton = (running || ((statusNum == '6')||(statusNum < 0)));
	var disableStopButtton = (stopped || ((statusNum == '6')||(statusNum < 0)));
	var btn = document.getElementById('command_cmdStart'); if (btn) { btn.className = (disableStartButton ? 'commandButtonDisabled' : 'commandButton'); }
	var btn = document.getElementById('command_cmdStop'); if (btn) { btn.className = (disableStopButtton ? 'commandButtonDisabled' : 'commandButton'); }
	zenPage.showUpdateButton(update,states);
	zenPage.showRecoverButton(troubled);

	var prodMsg = "";
	var prodMsgClass = "";
	if (zenPage.productionId !== "" && states.productionState !== "") {
		prodMsg = states.productionStateMessage;
		prodMsgClass = states.productionCSS;
	}
	var span=document.getElementById('statusMsg');
	span.innerHTML = '&nbsp;' + prodMsg + '&nbsp;';
	span.attributes['class'].value = prodMsgClass;
	
	// Rebuild category select control (no id_Category if no production)
	if ((redocats) && (zenPage.productionId !== "")) {
		try {
			var ctl = document.getElementById('id_Category');
			ctl.options.length=1; // Leave only option "All" which is the first one
			var curr = zenPage.currCategory;
			var found = false;
			var iSel = 0;
			var cats = new Array();
			cats = zenPage.GetCategories(zenPage.productionId);
			for (var i = 0; i < cats.length; i++) {
				if (cats[i] == curr) {
					found = true;
					iSel = i+1;
				}
				ctl.options[ctl.length] = new Option(cats[i], cats[i]);
			}
			ctl.selectedIndex = iSel;
			if ((curr != '') && (!found)) {
				// The currently selected category is no longer valid for the Production; flag to revert to category 'All' and 'Production Settings', and redraw
				zenPage.currCategory = '';
				zenPage.SavePreferredCategoryForProduction('',zenPage.productionId, this.canEditDB);
			}
		} catch (err) {}
	}
}

/// Visit queues page
ClientMethod visitQueuesPage() [ Language = javascript ]
{
	var host = this.getHost();
	if (host.id < 0) {
		window.open(zenLink('EnsPortal.Queues.zen'),'queues');
	}
	else {
		if (zenPage._queueTableState.row > 0) {
			window.open(zenLink('EnsPortal.Queues.cls?QUEUE=' + host.name + '&MSGID=' + zenPage._queueTableState.msgId),'queues');
		} else {
			window.open(zenLink('EnsPortal.Queues.cls?QUEUE=' + host.name),'queues');
		}
	}
	return false;
}

/// Update diagram.
ClientMethod updateView(skipSettings) [ Language = javascript ]
{
	zenPage.refreshDiagramHeaderStates(true);

	var scroll = 0;
	var svg = zenPage.getComponentById('svgDiagram');
	if (svg) {
		svg.render();
		setTimeout(function() {
			if (zenPage.selectedHost != '') {
				// Look for item whose ID was passed in URL parameter HOST, and set property currItem if item is found
				var select = zenPage.selectedHost;
				for (var lane = 0; lane < 3; lane++) {
					if (hostObj[lane]) {
						for (var item = 0; item < hostObj[lane].length; item++) {
							if (hostObj[lane][item].id == select) {
								zenPage.currItem = hostObj[lane][item]._index;
								scroll = item;
								lane = 3;
								break;
							}
						}
					}
				}
				zenPage.selectedHost = ''; // This only needs to be done once
			}
			if ((typeof zenPage.multiItems == 'undefined') || !(zenPage.multiItems instanceof Array) || (zenPage.multiItems.length < 1)) {
				zenPage.selectItem(zenPage.currItem,true,skipSettings);
			} else {
				// reselect all previously selected items
				var temp = zenPage.multiItems.slice(0,zenPage.multiItems.length);
				zenPage.multiItems = [];
				zenPage.selectItem(temp[0],true,skipSettings);
				for (var i=1; i<temp.length; i++) {
					zenPage.ctrlSelectItem(temp[i]);
				}
			}
			if (scroll > 0) {
				zenPage.scrollDiagram(scroll);
			}
		}, 200) // end setTimeout function
	}

	var refreshElement = document.getElementById('id_refresh');
	if (refreshElement) {
		refreshElement.style.backgroundColor = ''; // in case the diagram was reloading, clear the background
	}

	/* this.canEdit will be 0 if source control read only */
	if (!this.canEdit || !this.canEditDB) zenPage.disableComponents();
}

/// If needed, scroll diagram so that it shows the selected row
ClientMethod scrollDiagram(row) [ Language = javascript ]
{
	var svgDiv = document.getElementById('svg');
	var svgDivNodes = svgDiv.childNodes;
	for (i = 0; i < svgDivNodes.length; i++) {
		var name = svgDivNodes[i].nodeName;
		if (name == 'DIV') {
			var divElement = svgDivNodes[i];
			var dy = (row+1)*20;
			if (dy > divElement.clientHeight) {
				divElement.scrollTop = dy-55;
			}
			break;
		}
	}
}

/// Remember the state of auto refresh for the given Production in the current namespace
/// (we only expect this to be called when auto refresh is turned off because otherwise the state is updated with each refresh)
ClassMethod UpdateAutoRefreshStateProd(pIsAutoRefreshActive As %Boolean = 0, pProduction As %String = "") As %String [ ZenMethod ]
{
	Set:""=pProduction pProduction=##class(EnsPortal.Utils).GetCurrentProductionName()
	Quit:""=pProduction "Can only update AutoRefresh state if a current Production is given"
	Set tAutoRefreshEnabled = ##class(%CSP.Portal.Utils).%IsAutoRefreshEnabled()
	Set ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","AutoRefresh",pProduction) = tAutoRefreshEnabled && $select(pIsAutoRefreshActive="true":1,1:''pIsAutoRefreshActive)
	Quit ""
}

ClassMethod UpdateProductionStatus(ByRef pStates As %ZEN.proxyObject) As %Integer [ ZenMethod ]
{
	If 'pStates.statusSame && pStates.pStates.productionId {
		Set tAutoRefreshEnabled = ##class(%CSP.Portal.Utils).%IsAutoRefreshEnabled()
		If ""=pStates.autoRefresh {
			Set pStates.autoRefresh = tAutoRefreshEnabled && $get(^IRIS.Temp.EnsPortal($Username,"ProductionConfig","AutoRefresh",pStates.productionId))
		} Else {
			Set ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","AutoRefresh",pStates.productionId) = tAutoRefreshEnabled && pStates.autoRefresh
		}
	}
	Set tSC = ##class(Ens.Director).GetProductionStatus(.tCurrentProduction,.tState,,1)
	Set tCurrentProduction = $G(tCurrentProduction)
	Set tState = $G(tState)
	If ((tState'=$$$eProductionStateShardWorkerProhibited)&&(tCurrentProduction'=pStates.productionId)) Set tState=$$$eProductionStateStopped
	Set pStates.productionState = tState
	Do ..LocalizeProductionStatus(tState, .tStateText, .tStateClass)
	If $$$ISOK(tSC) {
		Set pStates.productionStateMessage = tStateText
	} Else {
		Set pStates.productionStateMessage = $$$StatusDisplayString(tSC)
	}
	Set pStates.productionCSS = tStateClass
	If ($$$eProductionStateRunning = tState) {
		Set pStates.needsUpdate = ##class(Ens.Director).ProductionNeedsUpdate(.tNeedsUpdateReason,1)
		Set pStates.needsUpdateReason = tNeedsUpdateReason
	} Else {
		Set pStates.needsUpdate = 0
		Set pStates.needsUpdateReason = ""
	}
	Quit tState
}

ClassMethod LocalizeProductionStatus(pState As %String = "", Output pLocalizedState As %String, Output pStyle As %String)
{
	If pState=$$$eProductionStateStopped {
		Set pLocalizedState = $$$Text("Production Stopped")
		Set pStyle = "dgmProductionStopped"
	}
	ElseIf pState=$$$eProductionStateRunning {
		Set pLocalizedState = $$$Text("Production Running")
		Set pStyle = "dgmProductionRunning"
	}
	ElseIf pState=$$$eProductionStateSuspended {
		Set pLocalizedState = $$$Text("Production Suspended")
		Set pStyle = "dgmProductionSuspended"
	}
	ElseIf pState=$$$eProductionStateTroubled {
		Set pLocalizedState = $$$Text("Production Troubled")
		Set pStyle = "dgmProductionTroubled"
	}
	ElseIf pState=$$$eProductionStateNetworkStopped {
		Set pLocalizedState = $$$Text("Production Network Stopped")
		Set pStyle = "dgmProductionNetworkStopped"
	}
	ElseIf pState=$$$eProductionStateShardWorkerProhibited {
		Set pLocalizedState = $$$Text("Production cannot be run on this node")
		Set pStyle = "dgmProductionNetworkStopped"
	}
	Else {
		Set pLocalizedState = $$$Text("Production State Unknown")
		Set pStyle = "dgmProductionUnknown"
	}
}

/// User has pressed add item command - show corresponding add host wizard dialog.
ClientMethod addItem(type) [ Language = javascript ]
{
	if (!this.checkEdit()||!this.checkEditDB()) {
		return false;
	}
	var ret = false;

	if (zenPage.productionId != '') {
		var parms = {
			PRODUCTION: zenPage.productionId
			};
		switch (type) {
		case 'service':
			ret = zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionAddService.zen'),this.addPopupSuffix('NewServiceWizard'),'status,scrollbars,resizable=yes,width=900,height=615',parms);
			break;
		case 'process':
			ret = zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionAddProcess.zen'),this.addPopupSuffix('NewProcessWizard'),'status,scrollbars,resizable=yes,width=900,height=615',parms);
			break;
		case 'operation':
			ret = zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionAddOperation.zen'),this.addPopupSuffix('NewOperationWizard'),'status,scrollbars,resizable=yes,width=900,height=615',parms);
			break;
		}
	}
	return ret;
}

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode, oldmode) [ Language = javascript ]
{
	var oldCat = zenPage.currCategory;
	if ((mode == 'bus') && (oldCat != '')) {
		zenPage.currCategory = '';
	}

	if (mode != oldmode) {
		zen('diagramHeader').refreshContents(true);
		auxVarHeight=0;
	}
	if (!this.adjustSizes()) this.refreshDiagram();

	if ((mode == 'bus') && (oldCat != '')) {
		zenPage.currCategory = oldCat;
	}
}

/// Change the current sort mode.
ClientMethod setSortModeHandler(mode) [ Language = javascript ]
{
	this.updateView();
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			if (!this.canEditDB) zenPage.grayOutNewButton();
			var t = zen('propertyTabs');
			t.ieResizeBody = function() { return }; // Workaround for IE (HCR188)
			this._isIE10 = false;
			if (zenIsHTML5 && zenIsIE) {
				var userAgent = navigator.userAgent.toString();
				this._isIE10 = (6 <= parseInt(userAgent.substring(userAgent.toUpperCase().indexOf('TRIDENT/') + 'Trident/'.length),10));
			}
			
			this.initSecurity();

			var svgFrame = zen('svg');
			var svgWindow = (svgFrame ? svgFrame.svgWindow : null);		
			if ((!svgWindow) && !(!!document.createElementNS && !! document.createElementNS(SVGNS, "svg").createSVGRect)) {
				alert($$$Text('Unable to load SVG diagram. Please ensure your browser is supported for portal access.'));
				return;
			}

			// Keep track of row selection in Queue tab
			this._queueTableState = {row :  -1, msgId : -1};
		}
		this.adjustSizes(true);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes(doSettings, adjustEvenIfSameSize) [ Language = javascript ]
{
	// Prevent any adjustments if the window height and width did not actually change and we are not hiding/showing settings tab
	var pageWidth = (zenIsIE ? document.body.scrollWidth : document.body.clientWidth); 
	var pageHeight = document.body.offsetHeight;
	if ((!adjustEvenIfSameSize) && (auxVarHeight == pageHeight) && (auxVarWidth == pageWidth)) {
		// No need to adjust sizes, so simply return
		return;
	}
	auxVarHeight = pageHeight;
	auxVarWidth = pageWidth;

	var updated = false;
	try {
		var propertyTabsFixedWidth = 380;
		var minDisplay = 1336;

		var toolRibbonClassDiv = document.querySelector(".toolRibbon");
		var toolRibbonClassDivWidth = (toolRibbonClassDiv ? toolRibbonClassDiv.offsetWidth : 0);

		// If window shrunk too much we go to scroll bars using fact that tool Ribbon can be wider
		var minDiagWidthBeforeForcingScrollbars = ((toolRibbonClassDivWidth > minDisplay) ? (toolRibbonClassDivWidth-propertyTabsFixedWidth) : (minDisplay-propertyTabsFixedWidth));

		/* Begin indent to help show structure */
		var ribbonDiv = zen('toolRibbon').getEnclosingDiv();
		var dgmDiv = zen('diagramPane').getEnclosingDiv();
			var dgmhdrDiv = zen('diagramHeader').getEnclosingDiv();
			var svg = zen('svg');
			var svgDiv = svg.getEnclosingDiv();
			var svgDiagram = zen('svgDiagram');
		var propDiv = zen('propertyPane').getEnclosingDiv();
			var proptitleDiv = zen('propertyTitle').getEnclosingDiv();
			var proptabsDiv = zen('propertyTabs').getEnclosingDiv();
				var formDiv = zen('settingsForm').getEnclosingDiv();
				var queueDiv = zen('queueForm').getEnclosingDiv();
		/* End Indent */

		propDiv.style.display = 'block';
		dgmhdrDiv.style.display = 'block';

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		/*	Set a minimum so that property/settings tabs do not hide diagram
			This might introduce scroll bars
		*/
		if ((winWidth-propertyTabsFixedWidth) < minDiagWidthBeforeForcingScrollbars) {
			winWidth = minDiagWidthBeforeForcingScrollbars+propertyTabsFixedWidth;
		}

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 25;
		var svgHgt = hgt - dgmhdrDiv.offsetHeight - 1;
		var svgWid = winWidth - propDiv.offsetWidth - 25;
		hgt = (hgt < 1 ? 1 : hgt);
		svgHgt = (svgHgt < 1 ? 1 : svgHgt);
		svgWid = (svgWid < 1 ? 1 : svgWid);

		if (svgWid < 100) {
			dgmDiv.style.display = 'none';
		}
		else {
			dgmDiv.style.display = 'block';
			zenPage.pageLoaded = true;
		}

		// Deal with IE box model
		var hdrWid = (svgWid - (zenIsIE * 40));
		hdrWid = (hdrWid < 1 ? 1 : hdrWid);
		dgmhdrDiv.style.width = hdrWid + 'px';
		// Check the width calculated by the browser (esp. IE)
		var hdrOffset = dgmhdrDiv.offsetWidth;
		if (svgWid < hdrOffset) {
			svgWid = hdrOffset;
		}
		dgmDiv.style.width = svgWid + 'px';
		ribbonDiv.style.width = (winWidth-25) + 'px';

		propDiv.style.height = hgt - 1 + 'px';

		var tabBodyHgt = (hgt - proptitleDiv.offsetHeight - 31);
		tabBodyHgt = (tabBodyHgt < 1 ? 1 : tabBodyHgt);
		zen('propertyTabs').setBodySize(tabBodyHgt,395);
		formDiv.style.width=propertyTabsFixedWidth+"px";
		var grpHgt=zen('grpSettingsScroll').getEnclosingDiv().offsetHeight+40;
		var formDivHgt = ((tabBodyHgt-grpHgt) < 1 ? 1 : tabBodyHgt-grpHgt);
		formDiv.style.height=formDivHgt+'px';

		queueDiv.style.width=propertyTabsFixedWidth+"px";
		var queueDivHgt = ((tabBodyHgt-grpHgt) < 1 ? 1 : tabBodyHgt-grpHgt);
		queueDiv.style.height=queueDivHgt+'px';

		// columns widths in diagram
		var gutter = 20;
		var colWid = (svgWid - gutter) / 3 - gutter;
		colWid = (colWid < 1 ? 1 : colWid);

		for (var n = 0; n < 3; n++) {
			var col = self.document.getElementById('dgmHdr_'+(n+1));
			if (col) {
				col.style.width = colWid + 'px';
				col.style.left = gutter + (n * (colWid + gutter)) + 'px';
			}
		}

		if (null == this._percent) {
			svg.setProperty('height',svgHgt);
			svg.setProperty('width',svgWid);
			svgDiagram.setProperty('width',svgWid);
			this.updateView(!doSettings);
			updated = true;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
	return updated;
}

/// Return the Production model object.
ClientMethod getProductionModel(update) [ Language = javascript ]
{
	var json = this.getComponentById('productionInfo');
	if (update) {
		json.reloadContents();
	}
	var data = json.getContentObject();
	return data;
}

/// Return/find the host object given the item number.
ClientMethod getHost(itemNo) [ Language = javascript ]
{
	if (typeof(itemNo) == 'undefined') itemNo = zenPage.currItem;
	if (itemNo < 0) {
		host = new Object();
		host.name = '$Production||' + zenPage.productionId;
		host.id = -1;
		return host;
	}
	else {
		for (var lane = 0; lane < 3; lane++) {
			for (var n = 0; n < hostObj[lane].length; n++) {
				if (hostObj[lane][n]._index == itemNo) return hostObj[lane][n]; // found the item
			}
		}
	}
	return null; // should never get here
}

/// Find the hostObj[][] indices for a given item position.
ClientMethod findHostObj(itemNo) [ Language = javascript ]
{
	if (itemNo < 0) return 0;
	var ret = 0;
	for (var lane = 0; lane < 3; lane++) {
		for (var n = 0; n < hostObj[lane].length; n++) {
			if (hostObj[lane][n]._index == itemNo) { ret = n*10 + lane; lane = 3; break; }
		}
	}
	return ret;
}

/// User selected a category for the diagram.
ClientMethod selectCategory(cat) [ Language = javascript ]
{
	if (zenPage.selectItem(-1)) {
		zenPage.currCategory = cat;
		zenPage.SavePreferredCategoryForProduction(cat,zenPage.productionId,this.canEditDB);
		zenPage.refreshDiagram();
	}
}

/// Save the selected category as the preferred category for the Production.
ClassMethod SavePreferredCategoryForProduction(pCategory As %String = "", pProduction As %String = "", pCanEditDB As %Boolean = 1) [ ZenMethod ]
{
	If pProduction'="" {
		If pCanEditDB { Set ^EnsPortal.Settings($Username,"PreferredCategory",pProduction) = pCategory }
		Else { Set ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","PreferredCategory",pProduction) = pCategory }
	}
}

/// Retrieve the preferred category for the Production.
ClassMethod GetPreferredCategoryForProduction(pProduction As %String = "", pCanEditDB As %Boolean = 1) As %String [ ZenMethod ]
{
	Set tCat = ""
	If pProduction'="" {
		Set tCat = $G(^EnsPortal.Settings($Username,"PreferredCategory",pProduction))
		Set:tCat="" tCat = $G(^IRIS.Temp.EnsPortal($Username,"ProductionConfig","PreferredCategory",pProduction))
		If tCat'="" {
			// Ensure it is still a valid category for the Production, otherwise delete the global node
			Set tFound = 0
			Try {
				Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateCategories")
				Set tSC = tRS.Prepare()
				If $$$ISOK(tSC) {
					Set tSC = tRS.Execute(pProduction)
					If $$$ISOK(tSC) {
						While (tRS.Next()) {
							Set cat = tRS.Get("Category")
							If tCat=cat Set tFound = 1 Quit
						}
					}
				}
			}
			Catch {
			}
			If 'tFound {
				Kill:pCanEditDB ^EnsPortal.Settings($Username,"PreferredCategory",pProduction)
				Kill ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","PreferredCategory",pProduction)
				Set tCat = ""
			}

		}
	}
	Quit tCat
}

/// Refresh the SVG diagram.
ClientMethod refreshDiagram() [ Language = javascript ]
{
	var svg = zen('svgDiagram');
	zenPage.drawDiagram(svg);
}

/// Render the svg diagram.
ClientMethod drawDiagram(svg) [ Language = javascript ]
{
	if (!this.pageLoaded) {
		return;
	}

	zenPage.stopTimers();

	if (!svg) {
		return;
	}

	// clear contents of ownerDraw component
	svg.unrender();

	// clear contents of hostObj
	hostObj = new Array();

	if (zenPage.productionId != '') {	
		var config = this.getProductionModel(true);
		if (!config) return;

		if (this.currViewMode == 'bus') {
			// Show tab "Actions", disable all other tabs, display Production Settings
			zen('propertyTabs').showTab(6);
			zenSetProp('tabSettings','disabled',true);
			zenSetProp('tabQueue','disabled',true);
			zenSetProp('tabEventLog','disabled',true);
			zenSetProp('tabMessages','disabled',true);
			zenSetProp('tabJobs','disabled',true);
			zenPage.selectItem(-1, true, true);
		}
		else {
			// Enable tabs that may be disabled
			zenSetProp('tabSettings','disabled',false);
			zenSetProp('tabQueue','disabled',false);
			zenSetProp('tabEventLog','disabled',false);
			zenSetProp('tabMessages','disabled',false);
			zenSetProp('tabJobs','disabled',false);
		}

		// organize hosts by type
		hostObj = new Array(3);
		for (var n = 0; n < 3; n++) {
			hostObj[n] = new Array();
		}

		// Filter by category and split into groups
		var cat = zenPage.currCategory + '';
		var k = 0;
		for (var n = 0; n < config.children.length; n++) {
			var host = config.children[n];
			if (cat != '') {
				var match = false;
				var c = host.category + '';
				var cl = c.split(',');
				for (var i in cl) {
					if (cl[i].replace(/^\s+|\s+$/g,"") == cat) {
						match = true;
						break;
					}
				}
				if (!match) {
					continue; // this item will not be included in the diagram as the category does not match
				}
			}
			host._index = k++;	// index
			switch (host.hostType) {
			case 'service':
			default:
				hostObj[0][hostObj[0].length] = host;
				break;
			case 'process':
				hostObj[1][hostObj[1].length] = host;
				break;
			case 'operation':
				hostObj[2][hostObj[2].length] = host;
				break;
			}
		}

		// sort each group
		for (var n = 0; n < 3; n++) {
			switch (this.currSortMode) {
			case 'name':
			default:
				hostObj[n].sort( function(a,b) {
					var nameA = a.name.toString().toLowerCase();
					var nameB = b.name.toString().toLowerCase();
					if (nameA < nameB) return -1;
					if (nameA > nameB) return 1;
					return 0;
				} )
				break;
			case 'status':
				hostObj[n].sort( function(a,b) {
					if (a.status < b.status) return -1;
					if (a.status > b.status) return 1;
					return 0;
				} )
				break;
			case 'ordinal':
				hostObj[n].sort( function(a,b) {
					return a.id - b.id;
				} );
				break;
			}
		}

		switch (this.currViewMode) {
		case 'monitor':
			this.drawOverview(svg);
			zenPage.startTimers();
			break;
		case 'bus':
			this.drawBus(svg);
			break;
		case 'list':
		case 'listing':
		default:
			this.drawListing(svg);
			zenPage.startTimers();
			break;
		}
	}
	else {
		// Disable tabs
		zenSetProp('tabSettings','disabled',true);
		zenSetProp('tabQueue','disabled',true);
		zenSetProp('tabEventLog','disabled',true);
		zenSetProp('tabMessages','disabled',true);
		zenSetProp('tabJobs','disabled',true);
		zenSetProp('tabActions','disabled',true);

		// Clear "Loading..." messages
		var grp = zen('settingsLoading'); grp.setHidden(true);

		// Display a hint message
		var label = svg.document.createElementNS(SVGNS,'text');
		label.setAttribute('class','messageText');
		label.setAttribute('x',50);
		label.setAttribute('y',50);
		var textNode = svg.document.createTextNode($$$Text("Open a Production to display its configuration."));
		label.appendChild(textNode);
		svg.svgGroup.appendChild(label);

		// Display name of Production if one was passed in the URL
		if (zenPage.productionIdURL != '') {
			var label = svg.document.createElementNS(SVGNS,'text');
			label.setAttribute('class','messageTextError');
			label.setAttribute('x',50);
			label.setAttribute('y',90);
			var textNode = svg.document.createTextNode($$$Text("An invalid Production was selected:") + " " + zenPage.productionIdURL);
			label.appendChild(textNode);
			svg.svgGroup.appendChild(label);
		}
	}
}

/// Show or hide message box.
ClientMethod showMsgBox(pShow) [ Language = javascript ]
{
	var svg = zen('svg');

	if (this._msgBox) {
		svg.svgGroup.removeChild(this._msgBox);
		delete this._msgBox;
	}
	
	if (!pShow) return;
	
	// Find out diagram's top scroll position
	var topY = 0;
	var svgDiv = document.getElementById('svg');
	var svgDivNodes = svgDiv.childNodes;
	for (i = 0; i < svgDivNodes.length; i++) {
		var name = svgDivNodes[i].nodeName;
		if (name=='DIV') {
			topY = svgDivNodes[i].scrollTop;
			break;
		}
	}

	// message box with text "computing connections..."
	var group = svg.document.createElementNS(SVGNS,'g');
	this._msgBox = group;
	group.setAttribute('id','computingConnections');
	svg.svgGroup.appendChild(group);
	var msg = $$$Text('computing connections...');
	var svgWidth = parseInt(svg.width);
	var w = 200;
	var h = 32;
	var box = svg.document.createElementNS(SVGNS,'rect');
	box.setAttribute('id','computingConnectionsBox');
	box.setAttribute('x',svgWidth/2 - w/2);
	box.setAttribute('y',topY + 10);
	box.setAttribute('width',w);
	box.setAttribute('height',h);
	box.setAttribute('rx',2);
	box.setAttribute('class','msgBox');
	group.appendChild(box);
	var label = svg.document.createElementNS(SVGNS,'text');
	label.setAttribute('class','msgBoxText');
	label.setAttribute('x',svgWidth/2 - w/2 + 7);
	label.setAttribute('y',topY + 31);
	var textNode = svg.document.createTextNode(msg);
	label.appendChild(textNode);
	group.appendChild(label);
	var tw = label.getComputedTextLength() + 15;
	box.setAttribute('width',tw);
}

/// Render config diagram in bus mode.
ClientMethod drawBus(svg) [ Language = javascript ]
{
	var svgWidth = parseInt(svg.width);
	var svgHeight = parseInt(svg.height);

	var centerX = svgWidth / 2;

	var bus = svg.document.createElementNS(SVGNS,'rect');
	bus.setAttribute('x',centerX - 10);
	bus.setAttribute('width',20);
	bus.setAttribute('y',2);
	bus.setAttribute('rx',8);
	bus.setAttribute('class','busStrip');
	svg.svgGroup.appendChild(bus);

	// organize hosts by business partner

	// property used to show groupings
	var propId = this.busProperty;
	var propName = this.busProperty;

	var otherName = $$$Text('Other');

	var partnerCount = 0;
	var partnerList = new Object();
	var partnerItemCount = new Object();

	for (var lane = 0; lane < 3; lane++) {
		for (var n = 0; n < hostObj[lane].length; n++) {
			var host = hostObj[lane][n];
			var pid =  (null != host[propId] && '' != host[propId]) ? host[propId] : otherName;
			if (!partnerList[pid]) {
				partnerCount++;
				partnerList[pid] = (null != host[propId] && '' != host[propId]) ? host[propName] : otherName;
			}
			partnerItemCount[pid] = (partnerItemCount[pid]?parseInt(partnerItemCount[pid]):0) + 1;
		}
	}
	
	var dy = 35;
	var y = 30;

	if (partnerCount <= 0) {
		// name
		var label = svg.document.createElementNS(SVGNS,'text');
		label.setAttribute('class','hostLabel');

		if (layoutRight) {
			label.setAttribute('x',centerX + 35);
		}
		else {
			label.setAttribute('x',centerX - 35);
			label.setAttribute('text-anchor','end');
		}
		label.setAttribute('y',y);

		var textNode = svg.document.createTextNode($$$Text('Nothing to display'));
		label.appendChild(textNode);
		svg.svgGroup.appendChild(label);
		return;
	}

	// display partners
	var count = 0;
	for (var n in partnerList) {
		var partnerName = partnerList[n] + ' (' + partnerItemCount[n] + ')';
		count++;

		var layoutRight = count%2;

		// connector
		var line = svg.document.createElementNS(SVGNS,'line');
		line.setAttribute('class','connectorLine');

		if (layoutRight) {
			line.setAttribute('x1',centerX + 30);
		}
		else {
			line.setAttribute('x1',centerX - 30);
		}
		line.setAttribute('x2',centerX);
		line.setAttribute('y1',y - 3);
		line.setAttribute('y2',y - 3);
		svg.svgGroup.appendChild(line);

		var dot = svg.document.createElementNS(SVGNS,'circle');
		dot.setAttribute('cx',centerX);
		dot.setAttribute('cy',y - 3);
		dot.setAttribute('r',5);
		dot.setAttribute('class','itemNormal');
		dot.setAttribute('style','fill: #F0F0FF; stroke: black;');
		svg.svgGroup.appendChild(dot);

		var box = svg.document.createElementNS(SVGNS,'rect');
		if (layoutRight) {
			box.setAttribute('x',centerX + 30);
		}
		else {
			box.setAttribute('x',20);
		}
		box.setAttribute('y',y-20);
		box.setAttribute('width',centerX - 50);
		box.setAttribute('height',dy - 5);
		box.setAttribute('rx',4);
		box.setAttribute('class','itemPartner');
		svg.svgGroup.appendChild(box);

		if (propId == 'busPartner' && partnerList[n]!=otherName) {
			box.addEventListener('click',new Function('evt','zenPage.busPartnerClick("'+partnerList[n]+'");'),false);
		}

		// name
		var label = svg.document.createElementNS(SVGNS,'text');
		label.setAttribute('class','hostLabel');

		if (layoutRight) {
			label.setAttribute('x',centerX + 35);
		}
		else {
			label.setAttribute('x',centerX - 35);
			label.setAttribute('text-anchor','end');
		}
		label.setAttribute('y',y);

		var textNode = svg.document.createTextNode(partnerName);
		label.appendChild(textNode);
		svg.svgGroup.appendChild(label);

		// next
		y += dy;
	}

	// adjust canvas height
	svg.setProperty('height',y);
	bus.setAttribute('height',y-4);
}

/// Render config diagram in listing mode.
ClientMethod drawListing(svg) [ Language = javascript ]
{
	// set up background mouse handler for drag/drop
	if (!this._mmHandler) {
		this._mmHandler = new Function('evt','return zenPage.backgroundMouseMoveHandler(evt);');
	}
	if (!this._muHandler) {
		this._muHandler = new Function('evt','return zenPage.backgroundMouseUpHandler(evt);');
	}

	// find which lane has most items
	var maxItems = 0;
	for (var lane = 0; lane < 3; lane++) {
		maxItems = (hostObj[lane].length > maxItems) ? hostObj[lane].length : maxItems;
	}

	// within each lane, list items
	var dy = 20;
	var svgWidth = parseInt(svg.width);
	var svgHeight = (dy*maxItems) + dy/2;
	if (svgHeight < 100) svgHeight = 100;
	svg.setProperty('height',svgHeight);

	// compute sizes
	var gutter = 20;
	var laneWidth = ((svgWidth-gutter) / 3) - gutter;
	var r = dy/2 - 3;
	var leftAlign = false;
	
	// getComputedTextLength efficiencies when DOM large
	var tw;
	var useGetComputed = true;
	var loopStartTime;
	var compatEx;
	try {
		loopStartTime = Date.now();
	} catch (compatEx) {
		loopStartTime = 0;
		useGetComputed = false;
	}

	for (var lane = 0; lane < 3; lane++) {
		var startX = (lane * (laneWidth+gutter)) + gutter;
		var startY = 20;
		var x = startX;
		var y = startY;

		// place sheet under names to clip values from previous column
		var rect = svg.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('x',startX - r - 3);
		rect.setAttribute('y',0);
		rect.setAttribute('width',laneWidth);
		rect.setAttribute('height',svgHeight);
		rect.setAttribute('style','fill:white;');
		rect.setAttribute('onclick','zenPage.showConnectors(false);');
		svg.svgGroup.appendChild(rect);

		var col = 0;
		for (var n = 0; n < hostObj[lane].length; n++) {
			var host = hostObj[lane][n];

			// item
			// place rect under item to catch mouse events
			// and also to indicate errors and selections
			var rect = svg.document.createElementNS(SVGNS,'rect');
			var tip = '';
			if (this.show=='portNo') {
				var name = host.portNo;
			}
			else {
				var name = host.name;
				rect.setAttribute('title',name + tip);
			}
			var isMC = (host.isMissingClass > 0);
			var rclass = 'itemRect';
			var rclasss = 'itemRectSelect';
			var rclassh = 'itemRectHover';
			var rclasshs = 'itemRectSelectHover';
			if (isMC) {
				tip = ' - ' + $$$Text("ERROR! Class does not exist or is not successfully compiled: ") + host.classname;
				 rclass = 'itemRectRed';
				 var rclasss = 'itemRectRedSelect';
				 var rclassh = 'itemRectRedHover';
				 var rclasshs = 'itemRectRedSelectHover';			
			}
			rect.setAttribute('id','item_' + host._index);
			rect.setAttribute('x',x + 9);
			rect.setAttribute('rx',2);
			rect.setAttribute('y',y - dy + 5);
			rect.setAttribute('width',laneWidth);
			rect.setAttribute('height',dy-1);
			rect.setAttribute('class',rclass);
			if (this._isIE10) { // add click and double-click handlers for IE10 to work around a bug where evt.detail is incorrect
				rect.addEventListener('click',new Function('evt','zenPage.itemClick(evt,'+host._index+');'),false);
				rect.addEventListener('dblclick',new Function('evt','zenPage.itemDblClick(evt,'+host._index+');'),false);
			}
			else {
				rect.addEventListener('mouseup',new Function('evt','zenPage.itemClick(evt,'+host._index+');'),false);
			}
			rect.addEventListener('mouseover',new Function('evt','zenPage.rectMouseOver(evt,'+host._index+',"'+rclassh+'","'+rclasshs+'");'),false);
			rect.addEventListener('mouseout',new Function('evt','zenPage.rectMouseOut(evt,'+host._index+',"'+rclass+'","'+rclasss+'");'),false);

			svg.svgGroup.appendChild(rect);

			// item label
			var label = svg.document.createElementNS(SVGNS,'text');
			label.setAttribute('class','hostLabel');

			if (leftAlign) {
				label.setAttribute('x',x + laneWidth - 19);
				label.setAttribute('y',y - 1);
				label.setAttribute('text-anchor','end');
			}
			else {
				label.setAttribute('x',x + 12);
				label.setAttribute('y',y - 1);
			}

			var textNode = svg.document.createTextNode(name);
			label.appendChild(textNode);
			svg.svgGroup.appendChild(label);

			if (useGetComputed) {
				tw = label.getComputedTextLength() + 6;
				if ((Date.now()-loopStartTime)>500) {useGetComputed = false;}
			} else {
				tw = label.childNodes[0].length*8;
			}

			var posFinal = laneWidth;
			if (tw < laneWidth) {
				rect.setAttribute('width',tw);
				posFinal = tw;
			} else {
				// use title element for tooltip if textNode with name might be truncated
				var tooltipForname = document.createElementNS(SVGNS,"title")
				tooltipForname.textContent = name;
				rect.appendChild(tooltipForname);
			}
			if (posFinal > (laneWidth - 20)) {
				posFinal = laneWidth - 20;
			}

			// dot
			var dot = svg.document.createElementNS(SVGNS,'ellipse');
			if (leftAlign) {
				dot.setAttribute('cx',x + laneWidth - 10);
			}
			else {
				dot.setAttribute('cx',x);
			}
			// can this host start a connection?
			var canConnect = 'service'==host.hostType;

			// can this host accept a connection?
			var canAccept = 'service'!=host.hostType;

			dot.setAttribute('cy',y - r/2 - 2);
			dot.setAttribute('rx',r);
			dot.setAttribute('ry',r);
			dot.setAttribute('class','itemNormal');

			// remember position(s)
			host._cx1 = parseInt(dot.getAttribute('cx'));
			host._cy1 = parseInt(dot.getAttribute('cy'));
			host._cx2 = host._cx1 + posFinal + (r*3) - 2;
			host._cy2 = host._cy1;
			host._r = r;

			host._label = label;
			host._rect = rect;
			host._dot = dot;

			// event handlers
			if (!isMC) {
				dot.addEventListener('mouseover',new Function('evt','return zenPage?zenPage.itemDotMouseOver(evt,'+host._index+','+(canAccept?'true':'false')+'):true;'),false);
				dot.addEventListener('mouseout',new Function('evt','return zenPage?zenPage.itemDotMouseOut(evt,'+host._index+'):true;'),false);
				dot.addEventListener('mousedown',new Function('evt','return zenPage?zenPage.itemDotMouseDown(evt,'+host._index+','+(canConnect?'true':'false')+','+host._cx1+','+host._cy1+'):true;'),false);
			}

			zenPage.updateDotColor(dot,host);
			svg.svgGroup.appendChild(dot);
			y += dy;
		}
	}

	// group to hold connectors
	var group = svg.document.createElementNS(SVGNS,'g');
	group.setAttribute('id','connectorGroup');
	svg.svgGroup.appendChild(group);
}

/// Render config diagram in monitor/overview mode.
ClientMethod drawOverview(svg) [ Language = javascript ]
{
	// find which lane has most items
	var maxItems = 0;
	for (var lane = 0; lane < 3; lane++) {
		maxItems = (hostObj[lane].length > maxItems) ? hostObj[lane].length : maxItems;
	}

	// within each lane, create dot for each item
	var svgWidth = parseInt(svg.width);

	var frame = zen('svg');
	var svgHeight = parseInt(frame.height);
	svg.setProperty('height',svgHeight);

	// compute sizes
	var gutter = 20;
	var laneWidth = ((svgWidth-gutter) / 3) - gutter;
	var laneHeight = svgHeight - 50;
	var unitsAcross = 1 + Math.ceil(Math.sqrt(maxItems/(laneHeight/laneWidth)));
	var dx = laneWidth / unitsAcross;
	var dy = dx;
	var r = (dx/2) * 0.8;

	for (var lane = 0; lane < 3; lane++) {
		var startX = (lane * (laneWidth+gutter)) + gutter;
		var startY = 20;
		var x = startX;
		var y = startY;
		var itemsPerRow = Math.floor(laneWidth / dx);

		var col = 0;
		for (var n = 0; n < hostObj[lane].length; n++) {

			var host = hostObj[lane][n];
			var dot = svg.document.createElementNS(SVGNS,'circle');
			dot.setAttribute('cx',x + dx/2);
			dot.setAttribute('cy',y + dy/2);
			dot.setAttribute('r',r);
			dot.setAttribute('class','itemNormal');
			dot.addEventListener('mouseover',new Function('evt','zenPage.itemMouseOver(evt,'+host._index+');'),false);
			dot.addEventListener('mouseout',new Function('evt','zenPage.itemMouseOut(evt,'+host._index+');'),false);
			dot.addEventListener('click',new Function('evt','zenPage.itemClick(evt,'+host._index+');'),false);
			if (this._isIE10) { // add explicit double-click handler for IE10 due to evt.detail counter bug.
				dot.addEventListener('dblclick',new Function('evt','zenPage.itemDblClick(evt,'+host._index+');'),false);
			}
			zenPage.updateDotColor(dot,host);
			svg.svgGroup.appendChild(dot);
			col++;
			if (col < itemsPerRow) {
				x += dx;
			}
			else {
				// next row
				col = 0;
				x = startX;
				y += dy;
			}
			host._dot = dot;
		}
	}
}

/// Update status indicator color for an item on the diagram (listing view or monitor view).
ClientMethod updateDotColor(dot, host) [ Language = javascript ]
{
	if (!dot) return;
	if (!host) return;
	var rx=dot.getAttribute('rx'); 
	switch(host.status) {
	case 'error':
		dot.setAttribute('style','fill: red;');
		if (zenPage.visualAid==1) {dot.setAttribute('ry',rx-2);}
		break;
	case 'retry':
		dot.setAttribute('style','fill: #9900CC;');
		if (zenPage.visualAid==1) { dot.setAttribute('ry',rx-2);}
		break;
	case 'inactive':
		dot.setAttribute('style','fill: yellow;'); 
		if (zenPage.visualAid==1) {dot.setAttribute('ry',rx-1);}
		break;
	case 'stopped':
		dot.setAttribute('style','fill: #DEFFBC;');
		if (zenPage.visualAid==1) { dot.setAttribute('ry',rx);}
		break; 
	case 'disabled':
		dot.setAttribute('style','fill: #D0D0D0;');
		if (zenPage.visualAid==1) { dot.setAttribute('ry',rx);}
		break;
	default:
		dot.setAttribute('style','fill: #20C020;');
		dot.setAttribute('ry',rx);
		break;
	}
}

/// Set the sort mode for the diagram.
ClientMethod setDisplaySort(sort) [ Language = javascript ]
{
	if (this.displaySort != sort) {
		this.displaySort = sort;
		this.updateView();
	}
}

/// Set the sort mode for the diagram.
ClientMethod setShowBy(which) [ Language = javascript ]
{
	if (this.show != which) {
		this.show = which;
		this.updateView();
	}
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (this.pageModified) {
		if (this.currItem < 0) { var msg = $$$Text("Changes made to Production settings will be lost if you leave this page."); }
		else { var msg = $$$FormatText($$$Text("Changes made to item '%1' settings will be lost if you leave this page."),this.getHost().name); }
		return msg;
	}
}

/// To display a custom message, override logout() and do the unload check ourselves.
ClientMethod logout() [ Language = javascript ]
{
	if (this.pageModified) {
		if (this.currItem < 0) { var msg = $$$Text("Changes made to Production settings will be lost.\n\nDo you want to log out and lose these changes?"); }
		else { var msg = $$$FormatText($$$Text("Changes made to item '%1' settings will be lost.\n\nDo you want to log out and lose these changes?"),this.getHost().name); }
		if (!confirm(msg)) return false;
	}
	this.pageModified = false; // make sure super doesn't ask again & no need to trigger Apply button style change
	this.invokeSuper('logout',null);
	return false;
}

/// Prompt if unsaved settings.  Return false if there are unchanged settings and user elected not to continue.  Return true otherwise.
ClientMethod checkLostSettings(itemNo) [ Language = javascript ]
{
	if (this.pageModified && this.currItem != itemNo) {
		var oldHost = this.getHost();
		if (this.currItem < 0) { var conf = $$$Text("Changes made to Production settings will be lost. Proceed?") }
		else { var conf = $$$FormatText($$$Text("Changes made to item '%1' settings will be lost. Proceed?"),oldHost.name) }
		if (!confirm(conf)) {
			// user chose to keep changes
			return false;
		}
		// clear changed flags after ok to abandon changes
		var form = zen('settingsForm');
		if (form) form.changedSetting = {};
		this.pageModified = false; // no need to trigger Apply button style change as it will be greyed out for next selected item
		this.stopTimers();
		this.KillModifiedSettings();
		zenPage.startTimers(0);
	}
	return true;
}

/// Select the item with the given id.
ClientMethod selectItem(itemNo, force, skipSettings) [ Language = javascript ]
{
	zenPage.unselectAll();
	if (!skipSettings && (this.currItem != itemNo) || force) {
		// prompt if unsaved settings
		if (!zenPage.checkLostSettings(itemNo)) {
			var ctl = document.getElementById('id_Category');
			if (ctl.value != zenPage.currCategory) {
				// category was being changed; revert
				try {
					var options = ctl.options;
					var c = zenPage.currCategory;
					for (i = 0; i < options.length; i++) {
						if (options[i].value == c) {
							options[i].selected = true;
							break;
						}
					}
				}
				catch(ex) {
				}
			}
			// do not continue
			return false;
		}
		if (zenPage.productionId == '') {
			return false;
		}

		var host = zenPage.getHost(itemNo);

		if (!skipSettings) {
			// hide previous contents of tabs and show "Loading..." message
			var grp = zen('settingsForm'); grp.setHidden(true);
			var grp = zen('grpSettingsScroll'); grp.setHidden(true);
			var grp = zen('settingsLoading'); grp.setHidden(false);
		}

		// unhighlight old
		var frame = zen('svg');
		var rect = frame.getSVGDocument().getElementById('item_' + this.currItem);
		if (rect) {
			var oldClass = rect.getAttribute('class');
			var newClass = oldClass.replace('Select','');
			rect.setAttribute('class',newClass);
			try {
				var rectDupl = frame.getSVGDocument().getElementById('id_duplBox');
				if (rectDupl) rectDupl.parentNode.removeChild(rectDupl);
			} catch(ex) { }
			document.getElementById('id_spanChoose').style.visibility = "hidden";
			// Reset Abort button in Queue tab
			var abortBtn = zen('btnAbortMsgs');
			abortBtn.setProperty('caption', $$$Text("Abort All"));
			abortBtn.setProperty('title', $$$Text("Abort all messages in this queue"));
			// Reset Selected Message in Queue tab
			this._queueTableState = {row :  -1, msgId : -1};
		}

		this.currItem = itemNo;

		zenPage.stopTimers();
		zenPage.KillModifiedSettings();

		if (host.isMissingClass && host.isMissingClass > 0) {
			if (!this.canEdit) {
				alert($$$Text("Cannot retrieve all information for this item because its associated class does not exist or is not successfully compiled:") + ' ' + host.classname);
				this.currHostId = '';
			}
			else {
				var propTabs = zen('propertyTabs');
				zenPage.currTabNo = propTabs.getCurrTabNo();
				zenPage.updateActions(host);
				propTabs.showTab(6);
				zenSetProp('tabSettings','disabled',true);
				zenSetProp('tabQueue','disabled',true);
				zenSetProp('tabEventLog','disabled',true);
				zenSetProp('tabMessages','disabled',true);
				zenSetProp('tabJobs','disabled',true);
				var rect = frame.getSVGDocument().getElementById('item_' + this.currItem);
				if (rect) rect.setAttribute('class','itemRectRedSelect');
				this.currHostId = host.id;
				var div = self.document.getElementById('componentName');
				div.innerHTML = zenEscapeHTML(host.name);
				div.title = zenEscapeHTML(host.name);
			}
			return false;
		}

		// highlight new
		if (zenPage.currTabNo > 0) {
			zenSetProp('tabSettings','disabled',false);
			zenSetProp('tabQueue','disabled',false);
			zenSetProp('tabEventLog','disabled',false);
			zenSetProp('tabMessages','disabled',false);
			zenSetProp('tabJobs','disabled',false);
			zen('propertyTabs').showTab(zenPage.currTabNo);
			zenPage.currTabNo = 0;
		}
		if (host && this.currItem > -1) {
			var rect = frame.getSVGDocument().getElementById('item_' + this.currItem);
			if (rect) rect.setAttribute('class','itemRectSelect');
			this.currHostId = host.id;
			if (this.currViewMode == 'list') {
				if (!host.hasDups) {
					// check if this host has duplicates
					zenPage.updateHasDups(host);
				}
				if (host.hasDups.length > 1) {
					// there is one or more duplicates, show count indicator and select control
					zenPage.drawDuplBox(itemNo,host.hasDups.length);
					zenPage.redrawItemDuplControl(host);
					// to do: onclick an option: name order just update the host; status or number order, reload the diagram, look for the item to select it (HCR)
				}
			}
		} else {
			this.currHostId = '';
		}

		// update property sheet for new item (delay is needed for IE to catch up)
		setTimeout(function() {
			var done = zenPage.updatePropertySheet(host,skipSettings);
			zenPage.startTimers(0);	
		}, 100);
	}

	return true;
}

/// Select the item with the given id.
ClientMethod ctrlSelectItem(itemNo) [ Language = javascript ]
{
	if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length < 2)) {
		// prompt if unsaved settings
		if (!zenPage.checkLostSettings(itemNo)) {
			return false;
		}
		if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length == 0)) {
			this.multiItems = [];
			if ((typeof this.currItem != 'undefined') && (this.currItem > -1)) {
				this.multiItems.push(this.currItem);
			}
			this.currHostId = '';
			this.currItem = -2;
			// clear tab group header
			var div = self.document.getElementById('componentName');
			div.innerHTML = '&nbsp;';
			div.title = '';
			
			// show multi-select actions and hide all others
			zenPage.updateActions(-2);
			// disable all tabs except Actions tab and switch to Actions tab
			zenPage.currTabNo = 6;
			zen('propertyTabs').showTab(zenPage.currTabNo);
			zenSetProp('tabSettings','disabled',true);
			zenSetProp('tabQueue','disabled',true);
			zenSetProp('tabEventLog','disabled',true);
			zenSetProp('tabMessages','disabled',true);
			zenSetProp('tabJobs','disabled',true);
		}
	}
	
	if (zenPage.productionId == '') {
		return false;
	}

	var host = zenPage.getHost(itemNo);

	zenPage.stopTimers();

	if (host) {
		this.multiItems.push(itemNo);
		
		// highlight newly selected item
		var frame = zen('svg');
		var rect = frame.getSVGDocument().getElementById('item_' + itemNo);
		if (rect) rect.setAttribute('class','itemRectSelect');
		if (this.currViewMode == 'list') {
			if (!host.hasDups) {
				// check if this host has duplicates
				zenPage.updateHasDups(host);
			}
			if (host.hasDups.length > 1) {
				// there is one or more duplicates, show count indicator and select control
				zenPage.redrawItemDuplControl(host);
			} else {
				var span=document.getElementById('id_spanChoose');
				span.style.visibility = 'hidden';
			}
		}
	}

	return true;
}

/// Select the item with the given id
ClientMethod shiftSelectItem(itemNo, ctrlToo) [ Language = javascript ]
{
	if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length < 2)) {
		// prompt if unsaved settings
		if (!zenPage.checkLostSettings(itemNo)) {
			return true;
		}
	}

	var hostPos = zenPage.findHostObj(itemNo);
	var lane = hostPos%10;  // lane 0 is Services, 1 is Processes, 2 is Operations
	
	// find last clicked item
	if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0)) {
		var lastNo = this.multiItems[this.multiItems.length-1];
	} else {
		var lastNo = this.currItem;
	}
	var lastPos = zenPage.findHostObj(lastNo);
		
	if ((lane == (lastPos%10)) && (lastNo != itemNo)) {
		// if same lane, then select everything between last selected and this one, inclusive
		var frame = zen('svg');
		
		if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length == 0)) {
			this.multiItems = [];
			if ((typeof this.currItem != 'undefined') && (this.currItem > -1)) {
				this.multiItems.push(this.currItem);
			}
			this.currHostId = '';
			this.currItem = -2;
			// clear tab group header
			var div = self.document.getElementById('componentName');
			div.innerHTML = '&nbsp;';
			div.title = '';
			
			// show multi-select actions and hide all others
			zenPage.updateActions(-2);
			// disable all tabs except Actions tab and switch to Actions tab
			zenPage.currTabNo = 6;
			zen('propertyTabs').showTab(zenPage.currTabNo);
			zenSetProp('tabSettings','disabled',true);
			zenSetProp('tabQueue','disabled',true);
			zenSetProp('tabEventLog','disabled',true);
			zenSetProp('tabMessages','disabled',true);
			zenSetProp('tabJobs','disabled',true);

		} else if (!ctrlToo) {
			zenPage.unselectAll();
			this.multiItems.push(lastNo);
		
			// re-highlight last selected item
			var rect = frame.getSVGDocument().getElementById('item_' + lastNo);
			if (rect) rect.setAttribute('class','itemRectSelect');
		}
		
		var vertPos = Math.floor(hostPos/10);
		var lastVertPos = Math.floor(lastPos/10);
		var start = Math.min(vertPos,lastVertPos) + (lastVertPos < vertPos);
		var end = Math.max(vertPos,lastVertPos) + (lastVertPos < vertPos);
		for (var i = start; i <end; i++) {
			var item = hostObj[lane][i]
			// only add if hadn't already selected (this is only relevant if using ctrl)
			if (this.multiItems.indexOf(item._index) == -1) {
				this.multiItems.push(item._index);
				item._rect.setAttribute('class','itemRectSelect');
			}
		}
		
		if (this.currViewMode == 'list') {
			var host = zenPage.getHost(itemNo);
			if (!host.hasDups) {
				// check if this host has duplicates
				zenPage.updateHasDups(host);
			}
			if (host.hasDups.length > 1) {
				// there is one or more duplicates, show count indicator and select control
				zenPage.redrawItemDuplControl(host);
			} else {
				var span=document.getElementById('id_spanChoose');
				span.style.visibility = 'hidden';
			}
		}

		
		return true;
	} else {
		// if not same lane, then no different from if select key weren't pressed
		return false;
	}
}

/// unselect the item with the given id.
ClientMethod unselectItem(itemNo) [ Language = javascript ]
{
	if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0) && (this.multiItems.indexOf(itemNo) > -1)) {
		if (zenPage.productionId == '') {
			return false;
		}
		
		// remove item from multiSelect list
		this.multiItems.splice(this.multiItems.indexOf(itemNo),1);

		// unhighlight item
		var frame = zen('svg');
		var rect = frame.getSVGDocument().getElementById('item_' + itemNo);
		if (rect) {
			var oldClass = rect.getAttribute('class');
			var newClass = oldClass.replace('Select','');
			rect.setAttribute('class',newClass);
			try {
				var rectDupl = frame.getSVGDocument().getElementById('id_duplBox');
				if (rectDupl) rectDupl.parentNode.removeChild(rectDupl);
			} catch(ex) { }
			document.getElementById('id_spanChoose').style.visibility = "hidden";
		}
		
		if (this.multiItems.length == 1) {
			var item = this.multiItems[0];
			this.multiItems = [];
			zenPage.currTabNo = 1;
			zenPage.selectItem(item);
		}
	} else if (this.currItem == itemNo) {
		zenPage.currTabNo = 1;
		zenPage.selectItem(-1);
	}

	return true;
}

ClientMethod unselectAll() [ Language = javascript ]
{
	if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0)) {
		while (this.multiItems.length > 0) {
			var item = this.multiItems[0];
			// remove item from multiSelect list
			this.multiItems.splice(0,1);
			// unhighlight item
			var frame = zen('svg');
			var rect = frame.getSVGDocument().getElementById('item_' + item);
			if (rect) {
				var oldClass = rect.getAttribute('class');
				var newClass = oldClass.replace('Select','');
				rect.setAttribute('class',newClass);
				try {
					var rectDupl = frame.getSVGDocument().getElementById('id_duplBox');
					if (rectDupl) rectDupl.parentNode.removeChild(rectDupl);
				} catch(ex) { }
				document.getElementById('id_spanChoose').style.visibility = "hidden";
			}
		}
		zenPage.currTabNo = 1;
	} else {
		// don't actually switch tabs if multi-select hadn't been in use
		zenPage.currTabNo = 0;
	}
}

/// User clicked on an item.
ClientMethod itemClick(evt, itemNo) [ Language = javascript ]
{
	if (!evt) {
		evt = window.event;
	}
	if ((!this._isIE10) && (evt.detail == 2)) {
		// two consecutive clicks = double-click: enable/disable item
		zenPage.itemDblClick(evt, itemNo);
		return;
	}
	
	var usedShift = false;
	if (evt.shiftKey && (this.currItem != -1)) {
		usedShift = zenPage.shiftSelectItem(itemNo,evt.ctrlKey);
	}
	if (!usedShift && evt.ctrlKey && (this.currItem != -1)) {
		if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0) && (this.multiItems.indexOf(itemNo) > -1)) {
			// unselect this item
			zenPage.unselectItem(itemNo);
		} else if (itemNo == this.currItem) {
			zenPage.unselectItem(itemNo);
		} else {
			// add item to selected
			zenPage.ctrlSelectItem(itemNo);
		}
	} else if (!usedShift) {
		// single-click: select item
		try {
			if (this.currItem == itemNo) {
				// item is already selected, nothing to do
				return;
			}
		}
		catch (ex) {
		}

		this._currEl = evt.target;
		this.selectItem(itemNo);
	}
	this.showConnectors(false);
}

/// User double-clicked on an item.
ClientMethod itemDblClick(evt, itemNo) [ Language = javascript ]
{
	// Check if it is too early to get information about the item
	var host = this.getHost(itemNo);
	if (host && host._index != itemNo) {
		return;
	}
	if (!zen('settingsLoading').hidden) {
		setTimeout(function() {
			zenPage.itemDblClick(evt,itemNo); // try again later
		}, 300);
		return;
	}

	if (this.pageModified && this.currItem == itemNo) { // if this.currItem != itemNo it ought to have been picked up earlier
		var conf = $$$FormatText($$$Text("Changes made to this item (%1) will be lost. Proceed?"),host.name)
			if (!confirm(conf)) {
				return false;
			}
		// clear changed flags after ok to abandon changes
		var form = zen('settingsForm');
		if (form) form.changedSetting = {};
		this.pageModified = false; // no need to trigger Apply button style change
		this.stopTimers();
		this.KillModifiedSettings();
		zenPage.updateSettings(host);
		zenPage.startTimers(0);
	}

	var settEn = zenPage.getComponentById('settCoreEnabled');
	if (!host || !settEn) return;
	if (settEn?.readOnly) {
		alert(zenPage.msgSDSEnabledOverridden);
		return;
	}
	var isEnabled = settEn.getValue();
	var itemStatus = host.status;
	var msg = $$$Text("The current status of this item is:") + ' ';
	switch(itemStatus) {
		case 'ok':
			msg = msg + $$$Text("OK");
			break;
		case 'stopped':
			msg = msg + $$$Text("Stopped");
			break;
		case 'disabled':
			msg = msg + $$$Text("Disabled");
			break;
		case 'error':
			msg = msg + $$$Text("Error");
			break;
		case 'inactive':
			msg = msg + $$$Text("Inactive");
			break;
		case 'retry':
			msg = msg + $$$Text("Retry");
			break;
		case 'starting':
			msg = msg + $$$Text("Starting");
			break;
		default:
			msg = msg + itemStatus;
			break;
	}
	if (this.checkHelper('RunItem',true) && !this.scReadOnly && this.canEditDB) {
		msg = msg + ".\n\n";
		if (isEnabled) {
			if (host.hostType == 'process') {
				try {
					if (zenPage.getComponentById('settCorePoolSize').getValue() == 0) {
						var msgPoolDisable1 = $$$Text("WARNING: The Business Process has a 'PoolSize' of 0.");
						var msgPoolDisable2 = $$$Text("It is not possible to restart or disable since the Ens.Actor is a shared actor queue.");
						var msgPoolDisable3 = $$$Text("You can still disable this Business Process, but first set 'PoolSize' > 0 so that this Business Process uses its own dedicated queue. Then you can safely disable it.");
						var msgPoolDisable4 = $$$Text("If you want to disable the shared actor queue set the Production Actor Pool Size to 0.");
						alert(msgPoolDisable1 + "\n" + msgPoolDisable2  + "\n" + msgPoolDisable3  + "\n\n" + msgPoolDisable4);
						return;
					}
				} catch (errP) {/* Continue */};
			} 
			if (zenPage.productionState != 1) {
				var actionButtons = 1;
				msg = msg + $$$FormatText($$$Text("Do you want to disable item %1?"),host.name)
			} else {
				msg = msg + $$$FormatText($$$Text("Do you want to Restart or Disable item %1 ?"),host.name)
				var actionButtons = 2;
			}
			var c1 = $$$Text("Disable");
			var t1 = $$$Text("Disable the item");
			var c2 = $$$Text("Restart");
			var t2 = $$$Text("Restart the item");
			var c3 = $$$Text("Cancel");
			var t3 = $$$Text("Cancel and leave Enabled");
			var parms = {
				MESSAGE:	msg,
				CAPTION1:	c1,
				TITLE1:		t1,
				CAPTION2:	c2,
				TITLE2:		t2,
				CAPTION3:	c3,
				TITLE3:		t3,
				ICON:		'',
				ACTIONBUTTONS:	actionButtons	
			};
			zenPage.launchPopupWindow(zenLink('EnsPortal.Dialog.Choice.zen'),this.addPopupSuffix('RestartOrDisable'),'resizable=yes,width=380,height=190',parms);
			zenPage.startTimers(2000);
		} else {
			msg = msg + $$$FormatText($$$Text("Do you want to enable item %1?"),host.name)
			var c1 = $$$Text("Enable");
			var t1 = $$$Text("Enable the item");
			var c3 = $$$Text("Cancel");
			var t3 = $$$Text("Cancel and leave Disabled");
			var parms = {
				MESSAGE:	msg,
				CAPTION1:	c1,
				TITLE1:		t1,
				CAPTION3:	c3,
				TITLE3:		t3,
				ICON:		'',
				ACTIONBUTTONS:	1
			};
			zenPage.launchPopupWindow(zenLink('EnsPortal.Dialog.Choice.zen'),this.addPopupSuffix('EnableItem'),'resizable=yes,width=380,height=190',parms);
			zenPage.startTimers(2000);
		}
	}
	else {
		msg += ".\n\n"
		if (!this.checkHelper('RunItem',true)) {
			msg += $$$Text("You do not have permissions to change the status of this item.");
		} else if (!this.canEditDB) {
			msg += zenPage.msgNoDBPermissions;
		} else if (this.scReadOnly) {
			msg += zenPage.msgSCReadOnly;
		}
		alert(msg);
	}
}

/// Mouse over in "dots" view mode.
ClientMethod itemMouseOver(evt, itemNo) [ Language = javascript ]
{
	this._currEl = evt.target;
	this.startActionTimer(500,'listingTip',itemNo);
	evt.target.setAttribute("class","itemHover");
}

ClientMethod itemMouseOut(evt, itemNo) [ Language = javascript ]
{
	evt.target.setAttribute("class","itemNormal");

	var config = this.getProductionModel();
	if (!config) return;

	this.clearActionTimer();
	this.showListingTip(-2); // clear
}

ClientMethod rectMouseOver(evt, itemNo, rclassh, rclasshs) [ Language = javascript ]
{
	if ((itemNo != this.currItem) && ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.indexOf(itemNo) == -1))) {
		var cls = rclassh;
	} else {
		var cls = rclasshs;
	}
	evt.target.setAttribute("class",cls);
}

ClientMethod rectMouseOut(evt, itemNo, rclass, rclasss) [ Language = javascript ]
{
	if ((itemNo != this.currItem) && ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.indexOf(itemNo) == -1))) {
		var cls = rclass;
	} else {
		var cls = rclasss;
	}
	evt.target.setAttribute("class",cls);
}

ClientMethod startActionTimer(timeout, code, index) [ Language = javascript ]
{
	this.clearActionTimer();
	this._actionTimer = window.setTimeout('zenPage.fireTimerAction("'+code+'",'+index+');',timeout);
}

ClientMethod clearActionTimer() [ Language = javascript ]
{
	if (this._actionTimer) {
		window.clearTimeout(this._actionTimer);
		this._actionTimer = null;
	}
}

ClientMethod fireTimerAction(code, index) [ Language = javascript ]
{
	switch(code) {
	case 'listingTip':
		this.showListingTip(index);
		break;
	}
}

/// Update the settings form for the given host item.<br/>
ClientMethod expandoStatesString(form) [ Language = javascript ]
{
	var statesString = '';
	for (var e = 0; e < form.children.length; e++) {
		var child = form.children[e];
		if ('expando' == child._type) {
			statesString = statesString + ',' + child.id + '=' + child.expanded
		}
	}
	return statesString.substring(1,statesString.length);
}

/// Update the settings form for the given host item.<br/>
ClientMethod updateExpandoStates(form, states) [ Language = javascript ]
{
	// construct string from form expandos
	// send string to server and get new host expandos string back
	var statesString = this.expandoStatesString(form);
	statesString=zenPage.StoreExpandoStates(form.hostname,statesString,states.hostname);
	if (!statesString) { alert('Failed to retrieve states from server');  return; }

	// parse string to output array
	var names=statesString.split(',');
	for (var p = 0; p < names.length; p++) {
		var pair = names[p].split('=');
		var id = pair[0];
		var value = pair[1];
		value = !(!value || value == 0 || value == '0' || value == 'false')
		states[id] = value;
	}
}

/// Update the settings form for the given host item.<br/>
ClientMethod updateSettings(host, searchStr) [ Language = javascript ]
{
	if ((!host) || ('' == host.id) || (zenPage.productionId == '')) {
		this.getComponentById('btnClearSearch').getEnclosingDiv().children[0].style.visibility="hidden";
		return;
	}
	if (!zenPage.settingsSearchStr) zenPage.settingsSearchStr = '';
	if (!searchStr) searchStr = zenPage.settingsSearchStr;
	searchStr = searchStr.toLowerCase();
	try {
		/* update list of settings information by refreshing JSON component - fetch by id
			But allow fallback to try by name in case class recompiled
		*/
		var parm = zen('siHostId');
		parm.value = host.id;
		var parmName = zen('siiHostName');
		parmName.value = host.name;

		// create controls in the settings form based on the items in the list
		var form = zen('settingsForm');
		if (!form.changedSetting) form.changedSetting = {};

		// get expando states from old form children
		var expandoStates = new Object();
		if ('' != searchStr) {
			this.getComponentById('btnClearSearch').getEnclosingDiv().children[0].style.visibility="visible";
			this.getComponentById('btnExpandAll').getEnclosingDiv().children[0].style.visibility="hidden";
			expandoStates['expSearch'] = true;
		} else {
			this.getComponentById('btnClearSearch').getEnclosingDiv().children[0].style.visibility="hidden";
			this.getComponentById('btnExpandAll').getEnclosingDiv().children[0].style.visibility="visible";
			expandoStates.hostname = host.name;
			this.updateExpandoStates(form,expandoStates);
		}
		// remove old children
		form.children = new Array();
		zenPage.composites = null;
		form.hostname = host.name;

		var json = this.getComponentById('settingsInfoById');
		json.reloadContents();
		var settings = json.getContentObject();
		if (!settings) {
			var ctrllb = zenPage.createComponent('label');
			ctrllb.controlClass = 'infoLabel';
			ctrllb.value = $$$FormatText($$$Text('Failed to retrieve settings for host %1.'),(host.id > -1 ? host.id : 'Production'));
			form.addChild(ctrllb);
			return;
		}
		this._settingsInfo = settings; // To be used when editing settings' defaults

		var button=zen('btnApply');
		if (host.id < 0) {
			// Production settings
			/* this.canEdit will be 0 if source control read only */
			if (this.canEdit && this.canEditDB) {
				button.setProperty('title', $$$Text('No changes to apply'));
				button.setProperty('controlClass','commandButtonDisabled');
			}
			else {
				button.setProperty('controlClass','commandButtonDisabled');
				button.setProperty('title',this.canEdit ? this.msgNoDBPermissions : this.msgNotPermitted);
			}
		}
		else {
			// Item settings
			/*	this.canEdit will be 0 if source control read only
				need to account for a user not being able to edit but able to disable/enable an item */
			if ((this.canEdit || (this.checkHelper('RunItem',true)&&(!this.scReadOnly))) && this.canEditDB) {
				button.setProperty('title',$$$Text('No changes to apply'));
				button.setProperty('controlClass','commandButtonDisabled');
			}
			else {
				button.setProperty('controlClass','commandButtonDisabled');
				button.setProperty('title',(this.canEdit||this.checkHelper('RunItem',true)) ? this.msgNoDBPermissions : this.msgNotPermitted);
			}
		}
		var grp = zen('grpSettingsScroll'); grp.setHidden(false);

		// get list of categories, add expandos
		var expandos = new Object();
		if ('' != searchStr) {
			expandos['Search']=this.newExpando(form,'Search',$$$Text("Searched Settings"),$$$Text("Settings whose name, type, category, or value contains the search value"),expandoStates)
			var lastSettingSection = '';
			var settingSection;
		} else {
			expandos['Info']=this.newExpando(form,'Info',$$$Text("Informational Settings"),$$$Text("Information values for this item, its class and its adapter class"),expandoStates)
			expandos['Basic']=this.newExpando(form,'Basic',$$$Text("Basic Settings"),$$$Text("Commonly needed settings for this item class and its adapter"),expandoStates)
			expandos['Additional']=this.newExpando(null,'Additional',$$$Text("Additional Settings"),$$$Text("Additional settings for this item class and its adapter"),expandoStates)
			expandos['Alerting']=this.newExpando(null,'Alerting',$$$Text("Alerting Control"),$$$Text("Settings to control alerts from this item"),expandoStates)
			expandos['Dev']=this.newExpando(null,'Dev',$$$Text("Development and Debugging"),$$$Text("Settings for this item related to testing, debugging and development"),expandoStates)
		}
		this._toDoList = []; // will use this for hover-text help later on, in the onrefresh callback

		// add controls to expandos
		for (var n = 0; n < settings.children.length; n++) {
			var ctrlDef = settings.children[n];
			var dataType = ctrlDef.DataType.substring((ctrlDef.DataType.indexOf('%Library.') < 0) ? 1 : 9);

			// ctrlDef contains:
			// $LB("IsAdapter","Name","Value","ValueSource","DefaultValue","DefaultSource","Description","DataType","MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST","IsRequired","LocalizedName","Category","LocalizedCategory","EditorContext")
			var ctrlId = "sett" + ctrlDef.IsAdapter + ctrlDef.Name;
			if (ctrlId=='settHostExec64' && zenPage.isWin64==0) continue;
			var oldCtrl = form.changedSetting[ctrlId];
			var ctrl;
			if (oldCtrl) {
				ctrl = oldCtrl;
			} else {
				// create control based on setting properties
				// if there is an EditorContext use a selector
				// otherwise use an appropriate control
				if (ctrlDef.EditorContext && (ctrlDef.EditorContext!=="") && (4!==ctrlDef.ValueSource)) {
					ctrl = this.createEditorComponent(ctrlDef.EditorContext,ctrlId,form);
				}
				else {
					switch(dataType) {
					case 'Numeric':
					case 'Integer':
						if ((0==ctrlDef.ValueSource)||(4==ctrlDef.ValueSource)) {
							ctrl = zenPage.createComponent('label');
						} else if ('' != ctrlDef.VALUELIST) {
							ctrl = zenPage.createComponent('combobox');
							ctrl.valueList = zenPage.getComboboxList(ctrlDef.VALUELIST,ctrlDef.IsRequired);
							if ('' != ctrlDef.DISPLAYLIST) {
								ctrl.displayList = zenPage.getComboboxList(ctrlDef.DISPLAYLIST,ctrlDef.IsRequired);
							}
							ctrl.editable = false;
						} else {
							ctrl = zenPage.createComponent('text');
							ctrl.size = 8;
						}
						break;
					case 'Boolean':
						ctrl = zenPage.createComponent('checkbox');
						if ((0==ctrlDef.ValueSource)||(4==ctrlDef.ValueSource)) {
							ctrl.disabled = true;
						}
						break;
					case 'String':
					default:
						if ((0==ctrlDef.ValueSource)||(4==ctrlDef.ValueSource)) {
							ctrl = zenPage.createComponent('label');
						} else if ('' != ctrlDef.VALUELIST) {
							ctrl = zenPage.createComponent('combobox');
							ctrl.valueList = zenPage.getComboboxList(ctrlDef.VALUELIST,ctrlDef.IsRequired);
							if ('' != ctrlDef.DISPLAYLIST) {
								ctrl.displayList = zenPage.getComboboxList(ctrlDef.DISPLAYLIST,ctrlDef.IsRequired);
							}
							ctrl.editable = false;
						} else if ((ctrlDef.MAXLEN > 1000) || (ctrlDef.MAXLEN == '')) {
							ctrl = zenPage.createComponent('textarea');
							ctrl.cols = 40;
							ctrl.rows = 4;
						}
						else {
							ctrl = zenPage.createComponent('text');
							ctrl.size = 40;
						}
						break;
					}
					ctrl.setProperty('id',ctrlId);
				}
				ctrl.dataType = dataType;
				ctrl.aux = ctrlDef.Category;
				ctrl.label = $$$Text(ctrlDef.LocalizedName);
				if ((0 != ctrlDef.ValueSource)&&(4 != ctrlDef.ValueSource)) {
					ctrl.onchange = "zenPage.settingChanged('"+escape(ctrl.index)+"','"+escape(form.index)+"');"
					ctrl.onkeyup = "zenPage.settingChanged('"+escape(ctrl.index)+"','"+escape(form.index)+"');"
					ctrl.changed = false;
				}
				// set up title and popup help text
				var title = zenPage.htmlToTooltip(ctrlDef.Description.substring(0,127));
				if (ctrlDef.Description.length > 128) title = title + "...";
				ctrl.title = title + " [" + $$$Text("Click for Popup") + "]";
				var locName = encodeURIComponent(ctrlDef.LocalizedName);
				locName = locName.replace(/'/g, "\\\'");
				var help = "zenPage.HTMLPopup('" + escape(ctrlDef.Name) + "',' " + locName + "',' " + escape(ctrlDef.Description) + "');"
			
				// save info for an onrender callback that will set onclick values for the label of the control
				this._toDoList.push({"idx":ctrl.index,"onclick":help}); 

				// continue setting up properties of the control
				ctrl.enclosingStyle = 'padding-left:3px; padding-bottom: 3px;';
				ctrl.targetType = ctrlDef.IsAdapter;
				var val = ctrlDef.Value;
				if (dataType == 'Boolean') val = !(!val || val == 0 || val == '0' || val == 'false')
				ctrl.lastValue = val;
				ctrl.originalValue = val;
				ctrl.setValue(('' == val && ctrl._type == 'label') ? '\u00a0' : val);

				// Initial label colorization is based on the setting source.
				// When user modifies a setting value, the new label color will be seen when the
				// settings are applied and repainted.
				var ls = 'color:black;font-weight:normal;';
				if (ctrlDef.IsAdapter != 'Core') {
					if (ctrlDef.ValueSource == 3) {
						ls = 'color:darkgreen;font-weight:bold;'; // Class definition
					}
					else if (ctrlDef.ValueSource == 2) {
						ls = 'color:blue;font-weight:bold;'; // System default
					}
					else if (ctrlDef.ValueSource == 4) {
						ls = 'color:brown;font-weight:bold;'; // Registry
						ctrl.setProperty('readOnly', true);
					}
				} else {
					if (ctrlDef.ValueSource == 2) {
						ls = 'color:blue;font-weight:bold;'; // System default override needs to be read only
						ctrl.setProperty('readOnly', true);
						ctrl.onmousedown="alert(zenPage.msgSDSOverridden);";
						// If composite component need to add intercepts to the grand children
						if (ctrlDef.EditorContext && (ctrlDef.EditorContext!=="") && ctrl.childrenCreated && ctrl.children && ctrl.children.length) {
							for (var childNum = 0; childNum < ctrl.children.length; childNum++) {
								var child = ctrl.children[childNum];
								if (child && child.children && child.children.length) {
									for (var grandchildNum = 0; grandchildNum < child.children.length; grandchildNum++) {
										var grandchild = child.children[grandchildNum];
										grandchild.setProperty('readOnly', true);
										grandchild.onmousedown="alert(zenPage.msgSDSOverridden);";
									}
								}
							}
						}
					}
				}
				ctrl.setProperty('labelClass','zenLabel settingLabel');
				ctrl.labelStyle = ls; // Production definition or 'core' setting
			}

			// add the control to the form
			var expandoCat = '';
			if ('' == searchStr) {
				if ('' != ctrlDef.Category && !expandos[ctrlDef.Category]) {
					switch (ctrlDef.Category) {
					case 'Connection':
						var catLocName = $$$Text('Connection Settings');
						break;
					case 'Proxy':
						var catLocName = $$$Text('Proxy Settings');
						break;
					default:
						if ('' != ctrlDef.LocalizedCategory) {
							var catLocName = ctrlDef.LocalizedCategory;
						} else {
							var catLocName = ctrlDef.Category;
						}
						break;
					}
					expandos[ctrlDef.Category]=this.newExpando(form,ctrlDef.Category,catLocName,'',expandoStates)
				}
				expandoCat = (('' == ctrlDef.Category) ? 'Additional' : ctrlDef.Category);
			} else if ((ctrlDef.LocalizedName.toLowerCase().indexOf(searchStr) >= 0) || (ctrlDef.Name.toLowerCase().indexOf(searchStr) >= 0) || (ctrlDef.Value.toString().toLowerCase().indexOf(searchStr) >= 0)) {
				expandoCat = 'Search';
				settingSection = (('' == ctrlDef.Category) ? 'Additional' : ctrlDef.Category);
				if (lastSettingSection != settingSection) {
					var ctrllb = zenPage.createComponent('label');
					ctrllb.controlClass = 'infoLabel';
					ctrllb.value = '['+$$$Text('Found under ')+settingSection + ']';
					lastSettingSection = settingSection
					expandos[expandoCat].addChild(ctrllb);
				}
			}
			if ('' != expandoCat) expandos[expandoCat].addChild(ctrl);
			if (ctrl.isComposite) {
				if (!zenPage.composites) zenPage.composites = new Array();
				zenPage.composites[ctrl.id] = ctrl;
			}
			/*
				scReadOnly will be 0 if source control read only
				user might not have edit but have runtime edit privs so need to check for scReadOnly
			*/
			if ( (!this.canEdit && (ctrlId !="settCoreEnabled" || !this.checkHelper('RunItem',true))) || !this.canEditDB || this.scReadOnly){
				ctrl.setProperty('readOnly', true);
			}
		}
		// add on the expandos we saved for last if they're not empty.
		if (expandos['Additional'] && expandos['Additional'].children.length > 0) form.addChild(expandos['Additional'])
		if (expandos['Alerting'] && expandos['Alerting'].children.length > 0) form.addChild(expandos['Alerting'])
		if (expandos['Dev'] && expandos['Dev'].children.length > 0) form.addChild(expandos['Dev'])

		var spacer = zenPage.createComponent('spacer');
		spacer.aux = '%';
		spacer.height = '15';
		form.addChild(spacer);
		if (host.id < 0) {
			var ctrllb = zenPage.createComponent('label');
			ctrllb.controlClass = 'infoLabel';
			ctrllb.value = $$$Text("These are the Production settings.");
			ctrllb.enclosingStyle = 'margin-left:10px;';
			form.addChild(ctrllb);
			var ctrllb = zenPage.createComponent('label');
			ctrllb.controlClass = 'infoLabel';
			ctrllb.value = $$$Text("To view item settings, click on a configuration item.");
			ctrllb.enclosingStyle = 'margin-left:10px;';
			form.addChild(ctrllb);
		} else {
			var ctrllb = zenPage.createComponent('label');
			ctrllb.controlClass = 'infoLabel';
			ctrllb.value = $$$Text("To view the Production Settings, click on the Production Settings link in the title area of the configuration diagram.");
			ctrllb.enclosingStyle = 'margin-left:10px;';
			form.addChild(ctrllb);
		}
		form.refreshContents();
		var grp = zen('grpSettingsScroll'); grp.setHidden(false);
		var grp = zen('settingsForm'); grp.setHidden(false);
		var grp = zen('settingsLoading'); grp.setHidden(true);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateSettings');
	}
}

/// Convert a VALUELIST or DISPLAYLIST as used in ObjectScript properties to the format needed for combobox
ClientMethod getComboboxList(list, isRequired) As %String [ Language = javascript ]
{
	var delim = list.charAt(0); // check in case delimiter used was not comma
	var newList = list.substring(1); // remove the delimiter
	if ("," != delim) {
		newList = newList.replace(",","\\,"); // need to escape any commas appearing in the list
		newList = newList.replace(delim,","); // now switch out the delimiter because combobox uses comma-delimited
	}
	if (!isRequired) {
		newList = ","+newList; // add in null option if not a required property
	}
	return newList;
}

/// Bridge to popup that allows changing the class associated to an item.
ClientMethod changeClass() [ Language = javascript ]
{
	if (!this.checkEdit()||!this.checkEditDB()) {
		return false;
	}
	zenPage.getNewClass(hostHelper.name,hostHelper.id,hostHelper.classname,hostHelper.hostType);
}

ClientMethod getNewClass(hostName, hostId, oldClassName, hostType) [ Language = javascript ]
{
	if (confirm($$$Text("Do you wish to change the class associated with this item?") + "\n" + $$$Text("Note that your values for any settings not available in the new class will be lost."))) {
		var parms = {
			HOSTNAME: hostName,
			HOSTID: hostId,
			OLDCLASS: oldClassName,
			HOSTTYPE: hostType
		};
		zenPage.stopTimers();
		zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ChangeClass.zen'),this.addPopupSuffix('ProdChangeClass'),'status,scrollbars,resizable=yes,left=100,top=100,width=520,height=350',parms);
		zenPage.startTimers(2000);	
	}
}

/// Create a new expando for the given category
ClientMethod newExpando(parentForm, category, caption, description, states) [ Language = javascript ]
{
	var expando = zenPage.createComponent('expando');
	expando.setProperty('id','exp'+category);
	expando.name = category;
	expando.caption = caption;
	expando.title=('' != description) ? description : expando.caption;
	expando.childIndent='16px';
	expando.containerStyle='padding:10px 10px 0px 10px;';
	expando.animate = false; // true made the scrollbars mess up
	expando.expanded = ((states[expando.id] == null) ? false : states[expando.id]);
	if (parentForm) parentForm.addChild(expando);
	return expando;
}

/// Helper method to set up popup for each setting's online help
ClientMethod HTMLPopup(title, locName, text) [ Language = javascript ]
{
	zenPage._helpText = text; // store in a property for future use by the popup dialog EnsPortal.Dialog.TooltipPopup
	var url=zenLink('EnsPortal.Dialog.TooltipPopup.zen?KEY=' + title + '&LOCALIZEDNAME=' + locName);

	var width = 500;
	var height = zenPage.calculateHeight(text.length, width);
	if (height > 700) height = 700;
	var features = "scrollbars,resizable,width=" + width + ",height=" + height;

	//zenLaunchPopupWindow(url, '', features); // modal window
	window.open(url, '', features); // non-modal window
}

/// Helper method to calculate appropriate height for online help window
ClientMethod calculateHeight(length, width) [ Language = javascript ]
{
	// It's about 7 pixels per character (width), 20 pixels per character (height), plus some vertical clearance (150)
	var charsPerLine = width / 7;
	var numLines = length / charsPerLine;
	return parseInt((numLines * 20) + 150);
}

/// Helper method to add stuff to dynamically created controls after they are fully materialized
ClientMethod renderHelpText() [ Language = javascript ]
{
	if (this._toDoList) {
		var len = this._toDoList.length;
		for (i=0; i < len; i++) {
			var item = this._toDoList[i];
			ctrl = zenPage.getComponent(item.idx); // get the control that we created
			if (!ctrl) { alert('no ctrl found for index:'+item.id); continue; }
			// set up an onclick value for the label of each setting control
			var div = ctrl.getLabelElement(); // we want to set an onclick for the label of the control
			if (!div) { // this happens on first load for Production settings
				// alert('no div for ctrl index:'+item.id+' ctrl.id:'+ctrl.id+' ctrl._type:'+ctrl._type);
				continue;
			}
			ZLM.setLocalAttribute(div,"onclick",item.onclick); // browser-independent setting of the attribute
		}
	}
}

/// Helper method to interpret HTML setting descriptions for display as tooltips
ClientMethod htmlToTooltip(input) [ Language = javascript ]
{
	input = input.replace(/'/g,'\'');
	input = input.replace(/\n/g,' ');
	input = input.replace(/\r/g,' ');

	input = input.replace(/<p>/g,'\r\n\r\n');
	input = input.replace(/<p\/>/g,'\r\n\r\n');
	input = input.replace(/<br>/g,'\r\n');
	input = input.replace(/<br\/>/g,'\r\n');
	input = input.replace(/<li>/g,' - ');

	input = input.replace(/<.*>/g,'');

	input = input.replace(/&lt;/g,'<');
	input = input.replace(/&gt;/g,'>');
	input = input.replace(/&apos;/g,'\'');
	input = input.replace(/"/g,'\'');
	input = input.replace(/&quot;/g,'\'');
	input = input.replace(/&amp;/g,'&');
	input = input.replace(/&nbsp;/g,' ');
	input = input.replace(/  +/g,' ');
	// strip leading \r\n sequences
	while ('\r\n' == input.substring(0,2)) {
		input = input.substring(2);
	}
	return input;
}

ClientMethod queueItemClick(row) [ Language = javascript ]
{
	var tbl = document.getElementById('queueListTbl');
	var abortBtn = zen('btnAbortMsgs');
	var oldRow = zenPage._queueTableState.row;
	if (oldRow > 0) {
		// Some row is already selected ...
		tbl.rows[oldRow].className = 
		//	table.rows[zenPage._queueTableState.row].className.replace(( /(?:^|\s)queueRowSelected(?!\S)/g , '' ));
			oldRow%2?'rowOdd':'rowEven';	
		if (oldRow == row) {
			// Selected row clicked, so toggle it to un-selected
			zenPage._queueTableState.row = -1;
			zenPage._queueTableState.msgId = -1;
			abortBtn.setProperty('caption', $$$Text("Abort All"));
			abortBtn.setProperty('title',$$$Text("Abort all messages in this queue"));
		} else {
			// Different row clicked, so un-select current and select new
			zenPage._queueTableState.row = row;
			zenPage._queueTableState.msgId = tbl.rows[row].cells[1].innerHTML;
			tbl.rows[row].className = 'queueRowSelected';
			abortBtn.setProperty('caption', $$$Text("Abort Selected"));
			abortBtn.setProperty('title',$$$Text("Abort the selected message"));
		}
	} else {
		// Nothing previously selected, so select this row
		zenPage._queueTableState.row = row;
		zenPage._queueTableState.msgId = tbl.rows[row].cells[1].innerHTML;
		tbl.rows[row].className = 'queueRowSelected';
		abortBtn.setProperty('caption', $$$Text("Abort Selected"));
		abortBtn.setProperty('title',$$$Text("Abort the selected message"));
	}
}

/// Helper method to create the component specified in <var>editorComponent</var> with the
/// context specified in the <var>editorContext</var> string.
ClientMethod createEditorComponent(editorContext, ctrlid, form) [ Language = javascript ]
{
	var component = null, componentType = '', paramData = '';
	var firstQMark = editorContext.indexOf('?');
	if (firstQMark > 0) {
		componentType = editorContext.substring(0,firstQMark);
		paramData = editorContext.substring(firstQMark+1);
	} else if (editorContext.indexOf('=') < 0) {
		componentType = editorContext;
		paramData = '';
	} else {
		componentType = 'selector';
		paramData = editorContext;
	}
	component = this.createComponent(componentType);
	if (!component) {
		alert("createEditorComponent('"+componentType+"','"+ctrlid+"') returned "+component);
	} else {
		component.setProperty('id',ctrlid);
		if (typeof(component.childrenCreated) != "undefined" && !component.childrenCreated) {
			component.isComposite=true;
			var ok = component.createChildren(form);
		}
		var done = false;
		var depth = 0;
		while (!done) {
			var nextOpen = paramData.indexOf('={');
			var nextAmp = paramData.indexOf('&');
			if ((nextOpen == -1)&&(nextAmp == -1)) {
				if (paramData.indexOf('=') != -1) { // no joins
					var pair = paramData.split('=');
					var name = pair[0];
					var value = null;
					if (pair.length > 1) {
						value = pair[1];
					}
					if ((name != '') && (value != null)) {
						component[name] = value;
					}
				} else {
					var openPos = paramData.indexOf('{');
					if (openPos > -1) {
						var context = paramData.substring(openPos+1);
						var closePos = context.indexOf('}');
						if (closePos > 0) {
							context = context.substring(0,closePos);
						}
						component.context = context;
					}
				}
				done = true;
			}
			else if ((nextOpen > -1)&&((nextOpen < nextAmp) || (nextAmp == -1))) {
				// nested
				depth++;
				var name = paramData.substring(0,nextOpen);
				var nextClose = paramData.indexOf('}',nextOpen);
				if (nextClose > -1) {
					depth--;
					var value = paramData.substring(nextOpen+2, nextClose);
					value = this.parseParamExpression(value);
					if ((value != '') && (name != '')) {
						component[name] = value;
					}
					paramData = paramData.substring(nextClose+1);
				}
				else {
					done = true;
					alert('Invalid expression supplied from server');
				}
			}
			else if ((nextAmp > -1) && ((nextAmp < nextOpen) || (nextOpen == -1))) {
				// join
				var pair = paramData.substring(0,nextAmp).split('=');
				var name = pair[0];
				var value = null;
				if (pair.length > 1) {
					value = pair[1];
				}
				if ((name != '') && (value != null)) {
					value = this.parseParamExpression(value);
					component[name] = value;
				}
				paramData = paramData.substring(nextAmp+1);
			}
		}
		if ((componentType == 'selector') && (component.size == '')) component.size = 38;
	}
	return component;
}

/// Helper method to parse URL parameter expressions for specialised components.
/// The format of the parameters should follow a straightforward key1=value1&key2=value2&...
/// structure, with the additional option of using expressions as part of the values in the
/// key/value pairs supplied from the server.<br/>
/// The supported expressions at present include:
/// <ul><li>$someFunction(args...) - the '$' indicates that zenPage.someFunction(args...) should
/// be executed on the client to get the required value</li>
/// <li>@someVar - the '@' indicates that the value of zenPage.someVar should be used on the client</li></ul>
/// Note that it is possible to use both replacements in one expression, but the parser does not support more
/// than one such replacement of each type per value expression.
ClientMethod parseParamExpression(paramString) [ Language = javascript ]
{
	var queryArray = paramString.split('?');
	var context = queryArray[0];
	var parameters = null;
	var parametersOut = new Array();
	if (queryArray.length > 1) {
		parameters = queryArray[1].split('&');
	}
	if (parameters) {
		for (var i = 0; i < parameters.length; i++) {
			var currentPiece = parameters[i].split('=');
			var key = currentPiece[0];
			var expression = '';
			if (currentPiece.length > 1) {
				expression = currentPiece[1];
			}
			if ((key != '') && (expression != '')) {
				var hasFunction = false;
				var hasRef = false;
				var funcExp = /[$].[\w$]+[(]/;
				var funcStart = funcExp.exec(expression);
				if (funcStart) {
					hasFunction = true;
					funcStartPos = expression.indexOf(funcStart[0]);
					expression = 'zenPage.'+expression.substring(funcStartPos+1);
				}
				var refExp = /([^\\][@].|^[@].)/;
				var endRefExp = /[\W]+[\w\W]*$/;
				var refStart = refExp.exec(expression);
				var currPiece = expression;
				while (refStart) {
					hasExpression = true;
					var refStartPos = 0;
					if (typeof(refStart) == 'object') {
						refStartPos = currPiece.indexOf(refStart[0]);
						var offSet = refStart[0].indexOf('@');
						if (offSet > 0) {
							refStartPos = refStartPos + offSet;
						}
					}
					var expressionEnd = currPiece.substring(refStartPos+1);
					var endRef = endRefExp.exec(expressionEnd);
					var refVal = '';
					var trailing = '';
					if (endRef) { // end found
						var endRefPos = currPiece.indexOf(endRef[0]);
						refVal = expressionEnd.substring(0,endRefPos);
						trailing = expressionEnd.substring(endRefPos);
					}
					else {
						refVal = expressionEnd;
					}
					refVal = zenPage[refVal];
					if (!refVal) alert('can\'t find zenPage variable referenced in expression "' + parameters[i] + '"');
					if ('string' == typeof(refVal)) refVal.replace(refExp,'\\@');
					if (hasFunction) {
						expression = expression.substring(0,refStartPos) + "'" + refVal + "'" + trailing;
					}
					else {
						expression = expression.substring(0,refStartPos) + refVal + trailing;
					}
					refStart = refExp.exec(expression);
				}
				expression = expression.replace(/\\@/g,'@');
				if (hasFunction) {
					expression = eval(expression);
				}
				parametersOut[parametersOut.length] = key + '=' + expression;
			}
		}
		return context + '?' + parametersOut.join('&');
	}
	return context;
}

/// Return current server time in format HH:MM:SS
ClassMethod CurrentTime() As %String [ CodeMode = expression, ZenMethod ]
{
$ZT($P($H,",",2))
}

/// Update the queue table for the current context (Production or item).<br/>
ClientMethod updateQueue(host) [ Language = javascript ]
{
	try {
		var html = new Array();
		var table = zen('grpQueue');
		var btn = zen('btnAbortMsgs');
		var lbl = zen('lblQCount');
		var lnk = document.getElementById('queueLink');

		var tLinkTitle=$$$Text("Click to view a visual trace for the message");

		// update information by refreshing JSON component
		var parm = zen('qiHostName');
		if (host.id < 0) {
			parm.value = '';
		}
		else {			
			parm.value = host.name;
		}
		var json = this.getComponentById('queueInfo');
		json.reloadContents();

		var rowCount = 0;
		var hasMore = false;
		var items = json.getContentObject();
		if (items && items.children && items.children.length >0) {
			rowCount = items.children.length;
			if ((items.children[rowCount - 1].QId == 'more...') ||
				(items.children[rowCount - 1].Queue == 'more...')) {
				rowCount = rowCount - 1;
				hasMore = true;
			}
		}
		// show count in text label
		if (host.id < 0) {
			lbl.setProperty('value',(rowCount + (hasMore ? '+' : '')+ '&nbsp;' + (rowCount == 1 ? $$$Text('queue') : $$$Text('queues'))));
			btn.setHidden(true);
			lnk.title = $$$Text("Go to the Queues page to view all queues");
		}
		else {
			// if queue count greater than rowCount, get actual queue count
			if (hasMore) var higherRowCount = zenPage.GetQueueCount(host.name); 		
			lbl.setProperty('value', (hasMore?((higherRowCount!='')?higherRowCount:rowCount+'+'):rowCount)+ '&nbsp;' + (rowCount == 1 ? $$$Text('item') : $$$Text('items')));
			btn.setHidden(rowCount<1);
			lnk.title = $$$Text("Go to the Queues page to view details");
		}
		// header
		html[html.length] = '<table width="100%" border="0" cellspacing="2" class="queueHeader">';
		html[html.length] = '<tr><td nowrap class="infoLabel">' + '</td></tr>';
		html[html.length] = '</table>';

		// queue table
		html[html.length] = '<div class="queueTableWrapper">';
		html[html.length] = '<table id="queueListTbl"  border="0" cellspacing="2" class="queueTable">';

		html[html.length] = '<tr>';
		if (host.id < 0) {
			html[html.length] = '<th>&nbsp;' + $$$Text("Queue") + '</th>';
			html[html.length] = '<th>' + $$$Text("Count") + '</th>';
			html[html.length] = '<th>' + $$$Text("Created") + '</th>';
		}
		else {
			html[html.length] = '<th>&nbsp;' + $$$Text("Source") + '</th>';
			html[html.length] = '<th>' + $$$Text("ID") + '</th>';
			html[html.length] = '<th>' + $$$Text("Type") + '</th>';
			html[html.length] = '<th>' + $$$Text("Created") + '</th>';
			html[html.length] = '<th style="display: none;">' + $$$Text("Priority") + '</th>';
			html[html.length] = '<th style="display: none;">' + $$$Text("Index") + '</th>';
		}
		html[html.length] = '</tr>';

		if (rowCount > 0) {
			if (items && items.children) {
				for (var n = 0; n < items.children.length; n++) {
				//for (var n = 0; n < rowCount; n++) {
					var r = n+1;
					var item = items.children[n];
					if (host.id < 0) {
						html[html.length] = '<tr class="'+(n%2?'rowEven':'rowOdd')+'">';
						if (item.Queue != 'more...') {
							html[html.length] = '<td>&nbsp;' + zenEscapeHTML(item.Queue) + '</td>';

							//determine color and title for queue count
							var style = "color:black";
							var title = "";
							if (item.Queue!="") {
								if ((item.Count!="") && (item.Count!="0")) {
									if (typeof zenPage.queueCount[item.Queue] != 'undefined') {
										if (item.Count > zenPage.queueCount[item.Queue]) {
											style="color:red;font-weight:bold";
											title="This count increased last time it was refreshed";
										}
										else if (item.Count < zenPage.queueCount[item.Queue]) {
											style="color:blue";
											title="This count decreased last time it was refreshed";
										}
										else {
											style="color:rgb(233,87,4)";
											title="This count did not change on the last refresh";
										}
									}
									else {
										style="color:rgb(233,87,4)";
									}
								}
								zenPage.queueCount[item.Queue] = item.Count
							}

							html[html.length] = '<td style="'+style+'" title="'+title+'">' + item.Count + '</td>';
							html[html.length] = '<td>' + item.Created + '</td>';
						} else {
							html[html.length] = '<td>&nbsp;' + zenEscapeHTML($$$Text('more...')) + '</td>';
						}
					}
					else {
						html[html.length] = '<tr class="'+(n%2?'rowEven':'rowOdd')+'" onclick="zenPage.queueItemClick(' + r +');">';
						if (item.QId != 'more...') {
							html[html.length] = '<td>&nbsp;' + zenEscapeHTML(item.Source) + '</td>';
							if (!zenPage.canViewMessageTrace) {
								html[html.length] = '<td>' + zenEscapeHTML(item.HeaderId) + '</td>';
							} else {
								html[html.length] = '<td><a class="sessionLink" title="' + tLinkTitle + '" onclick="zenPage.showTrace('+item.HeaderId+',event); return false;">' + zenEscapeHTML(item.HeaderId) + '</a></td>';
							}
							html[html.length] = '<td>' + zenEscapeHTML(item.BodyClass) + '</td>';
							html[html.length] = '<td nowrap>' + item.TimeCreated + '</td>';
							html[html.length] = '<td style="display: none;">' + zenEscapeHTML(item.Priority) + '</td>';
							html[html.length] = '<td style="display: none;">' + zenEscapeHTML(item.Index) + '</td>';
						} else {
							html[html.length] = '<td>' + zenEscapeHTML($$$Text('more...')) + '</td>';
						}
					}
					html[html.length] = '</tr>';
				}
			}
			html[html.length] = '</table>';
			html[html.length] = '</div>';
		}
		else {
			html[html.length] = '<table width="100%" border="0" cellspacing="2" class="queueHeader">';
			html[html.length] = '<tr><td nowrap class="infoLabel"><i>' + $$$Text('No results') + '</i></td>';
			html[html.length] = '</tr></table>';
		}

		// update
		var tableDiv = table.getEnclosingDiv();
		tableDiv.innerHTML = html.join('');

	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateQueue');
	}
}

/// Get Queue Count for Business Hosts with Queue Count larger than rowCount
ClassMethod GetQueueCount(pQueueName As %String) As %Integer [ ZenMethod ]
{
	Quit:pQueueName="" ""
	Quit ##class(Ens.Queue).GetCount(pQueueName)
}

ClientMethod refreshQueueTab() [ Language = javascript ]
{
	var host = zenPage.getHost();
	zenPage.updateQueue(host);
}

/// Update the event log table for the given host item.<br/>
ClientMethod updateLog(host) [ Language = javascript ]
{
	try {
		var html = new Array();
		var table = zen('divLog');
		var rowCount = 0;
		var hasMore = false;

		// update information by refreshing JSON component
		var parm = zen('liHostName');
		if (host.id < 0) {
			parm.value = '';
		}
		else {			
			parm.value = host.name;
		}

		var json = this.getComponentById('logInfo');
		json.reloadContents();

		var items = json.getContentObject();

		if (items && items.children && items.children.length >0) {
			rowCount = items.children.length;
			if (items.children[rowCount - 1].Id == 'more...') {
				rowCount = rowCount - 1;
				hasMore = true;
			}
		}
	
		// link to log page
		var msgView = zenEscapeHTML($$$Text("View these entries in the Event Log page"));
		var msgViewAll = zenEscapeHTML($$$Text("View all entries in the Event Log page"));
		var urlAll = zenLink('EnsPortal.EventLog.zen');
		if (host.name.toString().substring(0,13) == "$Production||") { 
			var url = urlAll; 
		}
		else { 
			var url = zenLink('EnsPortal.EventLog.zen?SOURCE=' + encodeURIComponent(host.name));
		}

		// header
		html[html.length] = '<table width="100%" border="0" cellspacing="2" class="logHeader">';
		html[html.length] = '<tr><td nowrap class="infoLabel">' + rowCount + (hasMore ? '+' : '')+ '&nbsp;' + zenEscapeHTML($$$Text('row(s)')) + '</td>';
		html[html.length] = '<td nowrap class="infoLabel">' + zenPage.CurrentTime() + '<a href="#" onClick="zenPage.refreshLogTab();return false;"><img src="images/reload.png" title="' + zenEscapeHTML($$$Text("Refresh")) + '"</a>' + '</td>';
		html[html.length] = '<td nowrap align="right" valign="middle"><a class="ribbonSortOption" style="font-size:10pt" title="' + msgView + '" href="#" onClick="window.open(\'' + url + '\',\'eventlog\');return false;">' + zenEscapeHTML($$$Text('Go To Event Log')) + '</a>';
		html[html.length] = '<span>  </span><a class="dgmHeaderCmd" title="' + msgViewAll + '" href="#" onClick="window.open(\'' + urlAll + '\',\'eventlog\');return false;"><img src="images/bullet-ul-excdev.gif"/>&nbsp;&nbsp;</a></td>';
		//html[html.length] = '</tr><tr><td nowrap colspan="2" class="infoLabel"><form><input type="checkbox" id="logErrors">' + $$$Text('Show Only Errors, Warnings and Alerts') + '</input></form></td>';
		html[html.length] = '</tr></table>';

		if (rowCount > 0) {
			// event log table
			html[html.length] = '<div class="logTableWrapper">';
			html[html.length] = '<table border="0" cellspacing="2" class="logTable">';

			html[html.length] = '<tr>';
			html[html.length] = '<th>' + $$$Text("Type") + '</th>';
			html[html.length] = '<th>' + $$$Text("Time") + '</th>';
			html[html.length] = '<th>' + $$$Text("Text") + '</th>';
			html[html.length] = '<th>&nbsp;' + $$$Text("ID") + '</th>';
			html[html.length] = '</tr>';

			if (items && items.children) {
				var cellStyle;
				for (var n = 0; n < rowCount; n++) {
					var item = items.children[n];
					switch(item.Type) {
						case "Alert": cellStyle="background: yellow; color: darkred; font-weight: bold;"; break;
						case "Error": cellStyle="background: pink; color: darkred; font-weight: bold;"; break;
						case "Warning": cellStyle="background: orange; color: darkred; font-weight: bold;"; break;
						case "Assert": cellStyle="background: silver; color: darkred; font-weight: bold;"; break;
						case "Trace": cellStyle="background: lightblue; color: darkblue; font-weight: bold;"; break;
						case "Info": 
							if (item.Method.match("StartProduction") == "StartProduction") 
								cellStyle="background: lightgreen; color: darkgreen; font-weight: bold;";
							else if (item.Method.match("StopProduction") == "StopProduction") 
								cellStyle="background: lightgreen; color: darkgreen; font-weight: bold;";
							else 
								cellStyle="";
							break;
						default:
							cellStyle="";
							break;
					}
					html[html.length] = '<tr class="'+(n%2?'rowOdd':'rowEven')+'">';
					html[html.length] = '<td title="'+zenEscapeHTML(item.Method)+'" style="'+cellStyle+'">' + zenEscapeHTML(item.Type) + '</td>';
					html[html.length] = '<td>' + item.TimeLogged + '</td>';
					html[html.length] = '<td title="'+zenEscapeHTML(item.Text)+'">' + zenEscapeHTML(item.Text) + '</td>';
					html[html.length] = '<td>&nbsp;' + item.Id + '</td>';
					html[html.length] = '</tr>';
				}
			}
			html[html.length] = '</table>';
			html[html.length] = '</div>';
		}

		// update
		var tableDiv = table.getEnclosingDiv();
		tableDiv.innerHTML = html.join('');
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateLog');
	}
}

ClientMethod refreshLogTab() [ Language = javascript ]
{
	var host = zenPage.getHost();
	zenPage.updateLog(host);
}

/// Update the messages table for the given host item.<br/>
ClientMethod updateMessages(host) [ Language = javascript ]
{
	try {
		if (host.id < 0) {
			zen('tblMessagesItem').setHidden(true);
			zen('tblMessagesProduction').setHidden(false);
			var tbl = zen('tblMessagesProduction');
		}
		else {
			zen('tblMessagesProduction').setHidden(true);
			zen('tblMessagesItem').setHidden(false);
			var tbl = zen('tblMessagesItem');
			zen('msgTableSource').value = host.name;
			zen('msgTableTarget').value = host.name;
		}
		tbl.msgNoResult = $$$Text('No results','%ZEN');
		tbl.executeQuery();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateMessages');
	}
}

/// Method to get the Date or Time piece from the TimeCreated field.
Method FormatDateTime(table As %ZEN.Component.tablePane, dt As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
 	Set val = %query(dt)
 	Set today = $ZD(+$H,3)
 	If $P(val," ",1)=today {
	 	Write ..EscapeHTML($P($P(val," ",2),".",1))
 	}
 	Else {
	 	Write ..EscapeHTML($P(val," ",1))
 	}
	Quit $$$OK
}

Method DrawMsgTraceCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status [ Internal ]
{
	#dim tDisplayMsgTraceField = $zconvert($get(%query(name)),"O","HTML")

	If (tDisplayMsgTraceField = "") {
		&html<&nbsp;>
	} ElseIf '..canViewMessageTrace {
		&html<#(tDisplayMsgTraceField)#>
	} Else {
		#dim tLinkTitle=$$$Text("Click to view a visual trace for the message")
		&html<<a class="sessionLink" title="#(tLinkTitle)#" onclick="zenPage.showTrace('#(tDisplayMsgTraceField)#',event); return false;">#(tDisplayMsgTraceField)#</a>>
	}
	Quit $$$OK
}

/// User clicked a link for Trace. Display the Visual Trace page.
ClientMethod showTrace(sessionId, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (evt.stopPropagation) evt.stopPropagation();
	}
	if (sessionId != -1) {
		var URI = zenLink('EnsPortal.VisualTrace.zen?SESSIONID='+sessionId);
		window.open(URI);
	}
}

Method DrawProcessdetails(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status [ Internal ]
{
	#dim tDisplayJobID = $zconvert($get(%query(name)),"O","HTML")

	If (tDisplayJobID = "") {
		&html<&nbsp;>
	} ElseIf '..canViewProcessDetails {
		&html<#(tDisplayJobID)#>
	} Else {
		#dim tLinkTitle=$$$Text("Click to view Process Details")
		&html<<a class="sessionLink" title="#(tLinkTitle)#" onclick="zenPage.showProcessDetails('#(tDisplayJobID)#',event); return false;">#(tDisplayJobID)#</a>>
	}
	Quit $$$OK
}

/// User clicked a link for Process Details Page.
ClientMethod showProcessDetails(jobID, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (evt.stopPropagation) evt.stopPropagation();
	}
	if (jobID != -1) {
		var URI = zenLink('/csp/sys/op/%25CSP.UI.Portal.ProcessDetails.zen?PID='+jobID+'&DISPLAYID='+jobID+'&$ID1='+jobID);
		window.open(URI);
	}
}

/// Update the instance jobs/processes table for the given host item.<br/>
ClientMethod updateJobs(host) [ Language = javascript ]
{
	try {
		if (host.id < 0) {
			zen('tblJobsItem').setHidden(true);
			var tbl = zen('tblJobsProduction');
			tbl.setHidden(false);
			tbl.setProperty('value','');
			tbl.msgNoResult = $$$Text('No results','%ZEN');
			tbl.executeQuery();
		}
		else {
			zen('tblJobsProduction').setHidden(true);
			var tbl = zen('tblJobsItem');
			tbl.setHidden(false);
			tbl.setProperty('value','');
			tbl.msgNoResult = $$$Text('No results','%ZEN');
			var currJobHost = zen('jobsTableHost');
			currJobHost.value = host.name;
			tbl.executeQuery();
			tbl.selectRow(-1);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateJobs');
	}
}

ClientMethod updateActions(host) [ Language = javascript ]
{
	try {
		if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0)) {
			// show multi-select actions and hide all others
						
			// Show Enable, Disable, Restart, but disable buttons if edit no permissions
			zenSetProp('grpEnable','hidden',false);
			zenSetProp('grpDisable','hidden',false);
			zenSetProp('grpRestart','hidden',false);
			
			var canEdit = ((this.canEdit || this.checkHelper('RunItem', true))&&(this.canEditDB));
			if (canEdit && (!this.scReadOnly)) {
				zenSetProp('btnDisable','controlClass','commandButton');
				zenSetProp('btnEnable','controlClass','commandButton');
				zenSetProp('btnDisable','title','Disable the selected items');
				zenSetProp('btnEnable','title','Enable the selected items');
			} else {
				zenSetProp('btnDisable','controlClass','commandButtonDisabled');
				zenSetProp('btnEnable','controlClass','commandButtonDisabled');
				var title = !this.canEditDB ? this.msgNoDBPermissions : (!canEdit ? this.msgNotPermitted : this.msgSCReadOnly);
				zenSetProp('btnDisable','title',title);
				zenSetProp('btnEnable','title',title);
			}
			// restart still available if read only because of source control, but not if production not running
			if (canEdit && (zenPage.productionState == 1)) {
				zenSetProp('btnRestart','controlClass','commandButton');
				zenSetProp('btnRestart','title','Restart the selected items (the production class will remain unchanged)');
			} else {
				zenSetProp('btnRestart','controlClass','commandButtonDisabled');
				var title = !this.canEditDB ? this.msgNoDBPermissions : (!canEdit ? this.msgNotPermitted : $$$Text("Items can only be restarted when the production is running."));
				zenSetProp('btnRestart','title',title);
			}
						
			// Hide all others
			var otherActions = ['grpTest','grpTempStart','grpTempStop','grpRestartOne','grpExport','grpAmendExport','grpDocument','grpOpen','grpNew','grpCopy','grpDelete','grpChangeClass'];
			for (var i=0; i<otherActions.length; i++) {
				zen(otherActions[i]).setHidden(true);
			}

		} else if (host.id < 0) {
			// Production actions

			// "Test" does not apply
			var grp = zen('grpTest');
			grp.setHidden(true);

			// "Start" a temporarily stopped item does not apply
			var grp = zen('grpTempStart');
			grp.setHidden(true);

			// "Stop" Temporarily does not apply
			var grp = zen('grpTempStop');
			grp.setHidden(true);

			// "Restart" using temp method does not apply
			var grp = zen('grpRestartOne');
			grp.setHidden(true);

			// Multi-select actions do not apply
			var multiSelectActions = ['grpEnable','grpDisable','grpRestart'];
			for (var i=0; i<multiSelectActions.length; i++) {
				zen(multiSelectActions[i]).setHidden(true);
			}

			// "Export"
			if (this.checkHelper('Export', true)) {
				// "Export" is greyed if no Production is open
				zenSetProp('btnExport','controlClass',(zenPage.productionId == '') ? 'commandButtonDisabled' : 'commandButton');
				zenSetProp('btnExport','title',$$$Text('Construct and export a deployment package containing the definition of this Production and associated components'));
				zenSetProp('btnAmendExport','controlClass',(zenPage.productionId == '') ? 'commandButtonDisabled' : 'commandButton');
				zenSetProp('btnAmendExport','title',$$$Text('Open and change an existing exported deployment package for deployment'));
			}
			else {
				zenSetProp('btnExport','controlClass','commandButtonDisabled');
				zenSetProp('btnExport','title', this.msgNotPermitted);
				zenSetProp('btnAmendExport','controlClass','commandButtonDisabled');
				zenSetProp('btnAmendExport','title', this.msgNotPermitted);
			}
			var grp = zen('grpExport');
			grp.setHidden(false);
			var grp = zen('grpAmendExport');
			grp.setHidden(false);

			// "Document"
			if (this.checkHelper('Document', true)) {
				// "Document" is greyed if no Production is open or if platform is VMS
				zenSetProp('btnDocument','controlClass',(zenPage.productionId == '' || zenPage.OS == 'VMS') ? 'commandButtonDisabled' : 'commandButton');
				zenSetProp('btnDocument','title',$$$Text('Generate or view documentation for this Production'));
			}
			else {
				zenSetProp('btnDocument','controlClass','commandButtonDisabled');
				zenSetProp('btnDocument','title', this.msgNotPermitted);
			}
			var grp = zen('grpDocument');
			grp.setHidden(false);

			// "New" - allow if user has edit resource and db is mounted RW
			var grp = zen('grpNew');
			grp.setHidden(false);

			var btn = zen('btnNew');
			var hasEditResource = this.checkHelper('EditResource', true);
			if (hasEditResource && (this.canEditDB)) {
				btn.setProperty('controlClass', 'commandButton');
				btn.setProperty('title', $$$Text('Leave this Production and build a new Production'));
			}
			else {
				btn.setProperty('controlClass', 'commandButtonDisabled');
				btn.setProperty('title', (hasEditResource ? this.msgNoDBPermissions : this.msgNotPermitted));
			}

			// "Open"
			var grp = zen('grpOpen');
			grp.setHidden(false);

			// "Delete" does not apply
			var grp = zen('grpDelete');
			grp.setHidden(true);

			// "Copy" does not apply
			var grp = zen('grpCopy');
			grp.setHidden(true);

			// "Change Class" does not apply
			var grp = zen('grpChangeClass');
			grp.setHidden(true);
		}
		else {
			// Item actions
			
			// Multi-select actions do not apply
			var multiSelectActions = ['grpEnable','grpDisable','grpRestart'];
			for (var i=0; i<multiSelectActions.length; i++) {
				zen(multiSelectActions[i]).setHidden(true);
			}

			if (!host.isMissingClass) {
				if (this.checkHelper('Test', true)) {
					// "Test" is greyed if the Production is not running, or is not enabled for testing, or the item is stopped, or the item is a Business Service
					zenSetProp('btnTest','controlClass',((host.hostType == 'service') || (!zenPage.isTestingEnabled(zenPage.productionId)) || (zenPage.productionState != 1) || (host.status == 'disabled') || (host.status == 'stopped')) ? 'commandButtonDisabled' : 'commandButton');
					zenSetProp('btnTest','title',$$$Text('Send a test message to this item'));
				}
				else {
					zenSetProp('btnTest','controlClass','commandButtonDisabled');
					zenSetProp('btnTest','title', this.msgNotPermitted);
				}
				var grp = zen('grpTest'); grp.setHidden(false);

				/*
					Start
					Check if user can stop/start an item
					Check if the item is enabled and temporarily stopped
				*/
				if (this.checkHelper('RunItem', true)) {
					// "Start" is greyed if the Production is not running or the item is not stopped (ie disabled or running)
					zenSetProp('btnTempStart','controlClass',((zenPage.productionState != 1) || (host.status != 'stopped')) ? 'commandButtonDisabled' : 'commandButton');
					zenSetProp('btnTempStart','title',$$$Text('Start this item that has been stopped temporarily (the production class will remain unchanged)'));
				}
				else {
					zenSetProp('btnTempStart','controlClass','commandButtonDisabled');
					zenSetProp('btnTempStart','title', this.msgNotPermitted);
				}
				grp = zen('grpTempStart'); grp.setHidden(false);

				/*
					Stop & Restart one item
					Check if user can stop/start an item
					Check if the item is enabled and running
				*/

				if (this.checkHelper('RunItem', true)) {
					// "Stop"  & "Restart" are  greyed if the Production is not running or the item is disabled or not running or poolSize = 0
					var cannotStop = ((zenPage.productionState != 1) || (host.status == 'disabled') || (host.status == 'stopped') || (zenPage.getComponentById('settCorePoolSize').getValue() == 0));
					var tempControlClass = cannotStop ? 'commandButtonDisabled' : 'commandButton';
					zenSetProp('btnTempStop','controlClass',tempControlClass);
					zenSetProp('btnTempStop','title',$$$Text('Stop this item temporarily (the production class will remain unchanged)'));
					zenSetProp('btnRestartOne','controlClass',tempControlClass);
					zenSetProp('btnRestartOne','title',$$$Text('Restart the selected item (the production class will remain unchanged)'));
				}
				else {
					zenSetProp('btnTempStop','controlClass','commandButtonDisabled');
					zenSetProp('btnTempStop','title', this.msgNotPermitted);
					zenSetProp('btnRestartOne','controlClass','commandButtonDisabled');
					zenSetProp('btnRestartOne','title', this.msgNotPermitted);
				}
				grp = zen('grpTempStop'); grp.setHidden(false);
				grp = zen('grpRestartOne'); grp.setHidden(false);

				// "Export"
				if (this.checkHelper('Export', true)) {
					zenSetProp('btnExport','controlClass','commandButton');
					zenSetProp('btnExport','title',$$$Text('Construct and export a package containing the definition of this item and associated components for deployment into another Production'));
					zenSetProp('btnAmendExport','controlClass','commandButton');
					zenSetProp('btnAmendExport','title',$$$Text('Open and change an existing exported deployment package for deployment into another Production'))
				}
				else {
					zenSetProp('btnExport','controlClass','commandButtonDisabled');
					zenSetProp('btnExport','title', this.msgNotPermitted);
					zenSetProp('btnAmendExport','controlClass','commandButtonDisabled');
					zenSetProp('btnAmendExport','title', this.msgNotPermitted);
				}
				var grp = zen('grpExport'); grp.setHidden(false);
				var grp = zen('grpAmendExport'); grp.setHidden(false);

				// "Copy"
				var grp = zen('grpCopy'); grp.setHidden(!this.canEdit);
				if (!this.canEditDB) {
					var btn = zen('btnCopy');
					btn.setProperty('controlClass','commandButtonDisabled');
					btn.setProperty('title',this.msgNoDBPermissions);
				} else if (this.scReadOnly) {
					var btn = zen('btnCopy');
					btn.setProperty('controlClass','commandButtonDisabled');
					btn.setProperty('title',this.msgSCReadOnly);
				} else if (zenPage.canEdit) {
					var btn = zen('btnCopy');
					btn.setProperty('controlClass', 'commandButton');
					btn.setProperty('title', $$$Text('Add a duplicate copy of this item to the Production under a new name'));
				}
			}
			else {
				// "Test" does not apply if class is missing
				var grp = zen('grpTest'); grp.setHidden(true);

				// "Export" does not apply if class is missing
				var grp = zen('grpExport'); grp.setHidden(true);
				var grp = zen('grpAmendExport'); grp.setHidden(true);

				// "Copy"
				var grp = zen('grpCopy'); grp.setHidden(true);
			}

			// "Document" does not apply
			var grp = zen('grpDocument'); grp.setHidden(true);

			// "New" is not available in this context
			var grp = zen('grpNew'); grp.setHidden(true);

			// "Open" is not available in this context
			var grp = zen('grpOpen'); grp.setHidden(true);

			// "Delete"
			var grp = zen('grpDelete'); grp.setHidden(!this.canEdit);
			if (!this.canEditDB) {
				var btn = zen('btnDelete');
				btn.setProperty('controlClass','commandButtonDisabled');
				btn.setProperty('title',this.msgNoDBPermissions);
			} else if (this.scReadOnly) {
				var btn = zen('btnDelete');
				btn.setProperty('controlClass','commandButtonDisabled');
				btn.setProperty('title',this.msgSCReadOnly);
			} else if (zenPage.canEdit) {
				var btn = zen('btnDelete');
				btn.setProperty('controlClass', 'commandButton');
				btn.setProperty('title', $$$Text('Delete this item from the Production configuration'));
			}

			// "Change Class"
			var grp = zen('grpChangeClass'); grp.setHidden(!this.canEdit);
			if (!this.canEditDB) {
				var btn = zen('btnChangeClass');
				btn.setProperty('controlClass','commandButtonDisabled');
				btn.setProperty('title',this.msgNoDBPermissions);
			} else if (this.scReadOnly) {
				var btn = zen('btnChangeClass');
				btn.setProperty('controlClass','commandButtonDisabled');
				btn.setProperty('title',this.msgSCReadOnly);
			} else if (zenPage.canEdit) {
				var btn = zen('btnChangeClass');
				btn.setProperty('controlClass', 'commandButton');
				btn.setProperty('title', $$$Text('Select another class to associate with this item'));
			}

			hostHelper = new Object();
			hostHelper.name = host.name;
			hostHelper.id = host.id;
			hostHelper.classname = host.classname;
			hostHelper.hostType = host.hostType;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateActions');
	}
}

ClientMethod queueAbortMsgs() [ Language = javascript ]
{
	if (!this.checkHelper('JobsEdit')) { // TODO: Modify resource when action is clearer.
		return false;
	}
	var host = this.getHost();
	if (!host || host.id < 0) return false;
	if (zenPage._queueTableState.row < 0) {
		// Nothing selected, so abort all messages
		if (confirm($$$FormatText($$$Text("Do you wish to abort all messages from queue '%1'?"),host.name))) {
			var msg=zenPage.AbortQueue(host.name);
			if ('' == msg) {
				zenPage.updateQueue(host);
				alert($$$Text("Messages aborted"));
			} else {
				alert($$$Text("Error aborting messages from queue: ") + msg);
			}
			return true;
		}
	} else {
		// Message selected to abort just that one
		var tbl = document.getElementById('queueListTbl');
		var msgId = tbl.rows[zenPage._queueTableState.row].cells[1].innerHTML;
		msgId = msgId.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
		msgId = msgId.replace(/<.*>/g,""); // for IE compatibility, remove tags inside cell

		var msgIndex = tbl.rows[zenPage._queueTableState.row].cells[5].innerHTML;
		msgIndex = msgIndex.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
		msgIndex = msgIndex.replace(/<.*>/g,""); // for IE compatibility, remove tags inside cell

		var pri = tbl.rows[zenPage._queueTableState.row].cells[4].innerHTML
		pri = pri.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
		pri = pri.replace(/<.*>/g,""); // for IE compatibility, remove tags inside cell

		var ret = "";
		if (confirm($$$FormatText($$$Text("Do you wish to abort message '%1' from queue '%2'?"), msgId, host.name))) {
			ret = zenPage.AbortMessage(msgIndex,pri,host.name);
			if (ret != "") {
				alert(ret);
			} else {
				confirm($$$FormatText($$$Text("Message '%1' aborted from queue '%2'."), msgId, host.name))
			}
			zenPage.updateQueue(host);
		}
	}
	return false;
}

Method AbortMessage(pHeaderId As %String, pPriority As %Integer, pQueueName As %String) As %String [ ZenMethod ]
{
	/* If $E(pHeaderId)="*" then this means Ens.Actor and it is the message id */
	If $E(pHeaderId)="*" {
		Set tHeaderId=pHeaderId
		Set pQueueName = "Ens.Actor"
		Set tMsgHdrId=$E(pHeaderId,2,*), pHeaderId = ""
		Set tQRef=$S($D($$$EnsQueue):$name($$$EnsQueue), 1:$name($$$EnsSuspended($$$SystemName,"Ens.Queue")))
		/* Need to look for the Queue index. Could take time */
		Set tIndex="" For  {
			Set tIndex=$O(@tQRef@(pQueueName,pPriority,tIndex),1,tItemHdr) Quit:tIndex=""
			If (tItemHdr = tMsgHdrId) { Set pHeaderId = tIndex  Quit }
		}
		If pHeaderId = "" Return $$$LocalizeText("Ensemble","AbortFailed","Abort message failed for Ens.Actor queue item") _ $C(13,10)		
	} Else {
		/* Need to check if this uses the Ens.Actor Queue */
		If ($$$getConfigQueueName(pQueueName,"")="Ens.Actor") Set pQueueName = "Ens.Actor"	
	}
	
	Set tSC = ##class(Ens.Queue).AbortItem(pQueueName,pPriority,pHeaderId)
	If $$$ISOK(tSC) {
		Set tMsg = ""
	} Else {
		Do $system.Status.DecomposeStatus(tSC,.err)
		Set tMsg = $$$LocalizeText("Ensemble","AbortFailed","Abort message ID '%1' failed: %2",pHeaderId,$G(err(1))) _ $C(13,10)
	}
	Quit tMsg
}

ClassMethod AbortQueue(pQueueName As %String) As %String [ ZenMethod ]
{
	Set tSC=##class(Ens.Queue).AbortQueue(pQueueName)
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod jobAbortMsg() [ Language = javascript ]
{
	if (!this.checkHelper('JobsEdit')) { // TODO: Modify resource when action is clearer.
		return false;
	}
	var host = this.getHost();
	if (!host) return false;

	if (host.id < 0) {
		var tblJobs = zenPage.getComponentById('tblJobsProduction');
	} else {
		var tblJobs = zenPage.getComponentById('tblJobsItem');
	}
	if (tblJobs.rowCount == 1) {
		tblJobs.selectRow(0,false);
	}
	var job = tblJobs.getProperty('value');
	if (!job || ''==job) { alert($$$Text('No job selected')); return false; }

	if (confirm($$$FormatText($$$Text("Do you wish to abort the active message being retried in job '%1' ?"),job))) {
		var msg=zenPage.AbortJobMsg(job);
		if ('' == msg) {
			zenPage.updateJobs(host);
			alert($$$FormatText($$$Text("Active message aborted for job '%1'"),job));
		} else {
			alert($$$FormatText($$$Text("Error aborting message for job '%1': %2"),job,msg));
		}
		return true;
	}
	return false;
}

ClassMethod AbortJobMsg(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).AbortOperation(pJob)	
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod jobSuspendMsg() [ Language = javascript ]
{
	if (!this.checkHelper('SuspendMessage')) {
		return false;
	}
	var host = this.getHost();
	if (!host) return false;

	if (host.id < 0) {
		var tblJobs = zenPage.getComponentById('tblJobsProduction');
	} else {
		var tblJobs = zenPage.getComponentById('tblJobsItem');
	}
	if (tblJobs.rowCount == 1) {
		tblJobs.selectRow(0,false);
	}
	var job = tblJobs.getProperty('value');
	if (!job || ''==job) { alert($$$Text("No job selected")); return false; }

	if (confirm($$$FormatText($$$Text("Do you wish to suspend the active message being retried for job '%1' ?"),job))) {
		var msg=zenPage.SuspendJobMsg(job);
		if ('' == msg) {
			zenPage.updateJobs(host);
			alert($$$FormatText($$$Text("Active message suspended for job '%1'"),job));
		} else {
			alert($$$FormatText($$$Text("Error suspending message for job '%1': %2"),job,msg));
		}
		return true;
	}
	return false;
}

ClassMethod SuspendJobMsg(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).SuspendOperation(pJob)
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod jobStop() [ Language = javascript ]
{
	if (!this.checkHelper('JobsEdit')) {
		return false;
	}
	var host = this.getHost();
	if (!host) return false;

	if (host.id < 0) {
		var tblJobs = zenPage.getComponentById('tblJobsProduction');
	} else {
		var tblJobs = zenPage.getComponentById('tblJobsItem');
	}
	if (tblJobs.rowCount == 1) {
		tblJobs.selectRow(0,false);
	}
	var job = tblJobs.getProperty('value');
	if (!job || ''==job) { alert($$$Text("No job selected")); return false; }

	if (confirm($$$FormatText($$$Text("Are you sure you want to stop instance job '%1'? It will be forcibly stopped if it fails to respond within the Update Timeout. Updating the Production subsequently may start a fresh instance job for this item."),job))) {
		var msg=zenPage.StopJob(job);
		if ('' == msg) {
			tblJobs.setProperty('value','');
			tblJobs.executeQuery();
			tblJobs.selectRow(-1);
			zen('jobsTableHost').setProperty('value','');
			alert($$$FormatText($$$Text("Job '%1' stopped"),job));
			zenPage.refreshDiagramHeaderStates(false)
		} else {
			alert($$$FormatText($$$Text("Error stopping job '%1': %2"),job,msg));
		}
		return true;
	}
	return false;
}

ClassMethod StopJob(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).Stop(pJob,$G($$$ConfigProdSetting("UpdateTimeout"),10),1)
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

/// User has pressed Test item button.
ClientMethod testItem() [ Language = javascript ]
{
	if (!this.checkHelper('Test')) {
		return false;
	}
	var host = this.getHost();
	if (!host) {
		alert($$$Text('Error in testItem'));
		return false;
	}

	var tType = '';
	if (host.hostType == 'process') {
		tType = 'P';
	}
	else if (host.hostType == 'operation') {
		tType = 'O';
	}
	else {
		alert($$$Text('Only applicable for Business Processes and Business Operations.'));
		return false;
	}

	if (zenPage.productionState != 1) {
		alert($$$Text('Not available unless the Production is running'));
		return false;
	}

	if ((host.status == 'disabled') || (host.status == 'stopped')) {
		alert($$$Text('Not available for items that are stopped'));
		return false;
	}

	zenPage.stopTimers();

	if (!zenPage.isTestingEnabled(zenPage.productionId)) {
		zenPage.startTimers(50);
		alert($$$Text('Not available unless the Production is configured with Testing Enabled'));
		return false;
	}

	var parms = {
		PRODUCTION: zenPage.productionId,
		HOSTTYPE: tType,
		HOSTNAME: host.name
			};
	var url = this.GetTestingServiceURL();
	zenLaunchPopupWindow(url,'','status,scrollbars,resizable=yes,left=100,top=100,width=1000,height=800',parms);
	zenPage.startTimers(2000);

	return true;
}

Method GetTestingServiceURL() As %String [ ZenMethod ]
{
	Quit ..Link("EnsPortal.Dialog.TestingService.cls")
}

/// Auxiliary method to identify if the Production is configured with TestingEnabled=true.
ClassMethod isTestingEnabled(pProduction) As %Boolean [ ZenMethod ]
{
	Quit ##class(EnsPortal.TestingService).GetIsTestingEnabled(pProduction)
}

ClientMethod selectDirectory(controlIndex) [ Language = javascript ]
{
	if (!this.checkEdit()) return;
	if (!this.canViewFileSystem) return;
	var control = zenIndex(controlIndex);
	if (!control) return;
	this._selectDirectoryControl = controlIndex;
	var parms = {
		"Dir": control.getValue(),
		"showdirectoryonly": 1
	};
	zenLaunchPopupWindow(zenLink('_ZEN.Dialog.fileSelect.zen'),this.addPopupSuffix('SelectDirectory'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
}

ClientMethod selectFile(controlIndex) [ Language = javascript ]
{
	if (!this.checkEdit()) return;
	if (!this.canViewFileSystem) return;
	var control = zenIndex(controlIndex);
	if (!control) return;
	this._selectFileControl = controlIndex;
	var parms = {
		"Dir": control.getValue(),
		"wildcard": control.getProperty('wildcard')
	};
	zenLaunchPopupWindow(zenLink('_ZEN.Dialog.fileSelect.zen'),this.addPopupSuffix('SelectFile'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
}

ClientMethod selectParam(controlIndex, parms) [ Language = javascript ]
{
	if (!this.checkEdit()) return;
	var control = zenIndex(controlIndex);
	if (!control) return;
	this._selectParamControl = controlIndex;
	var url = zenLink('EnsPortal.Dialog.SQLParamSelection.zen');
	zenLaunchPopupWindow(url,zenPage.addPopupSuffix('SQLParamAction'),'status,scrollbars,resizable=yes,width=400,height=600',parms);
}

/// User has pressed Export item button.
ClientMethod exportItem() [ Language = javascript ]
{
	if (!this.checkHelper('Export')) {
		return false;
	}
	if (this.productionId == '') {
		alert($$$Text('Not available now, please open a Production configuration first.'));
		return false;
	}
	else {
		var host = this.getHost();
		var parms = {
				PRODUCTION: this.productionId,
				HOSTID:     (!host ? '' : host.id),
				HOSTNAME:   (!host ? '' : host.name)
				};
		zenPage.stopTimers();
		zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ExportFromItem.zen'),'','status,scrollbars,resizable=yes,width=900,height=600',parms);
		zenPage.startTimers(2000);
		return true;
	}
}

/// User has pressed Re-Export item button.
ClientMethod reexportItem() [ Language = javascript ]
{
	if (!this.checkHelper('Export')) {
		return false;
	}
	if (this.productionId == '') {
		alert($$$Text('Not available now, please open a Production configuration first.'));
		return false;
	}
	else {
		if (!this.canViewFileSystem) {
			alert(this.msgNotPermitted);
			return false;
		}
		var wild = "*.xml"
		var str = this.deploymentFile
		var len = str.length;
		if (len > 0) {
			if (str.charAt(len-4) == ".") {
				var wild = "*" + str.substring(len-4);
			}
		}
		var parms = {
			Dir:this.deploymentFile,
			wildcard:wild
		};	
		zenPage.stopTimers();
		zenPage.launchPopupWindow('%ZEN.Dialog.fileSelect.cls',this.addPopupSuffix('SelectDeploymentFile'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
		zenPage.startTimers(2000);
		return true;
	}
}

/// User has pressed Document button.
ClientMethod documentProduction() [ Language = javascript ]
{
	if (!this.checkHelper('Document')) {
		return false;
	}
	if (this.productionId == '') {
		alert($$$Text('Not available now, please open a Production configuration first.'));
		return false;
	}
	else if (this.OS == 'VMS') {
		alert($$$Text('Not available on VMS.'));
		return false;
	}
	else {
		var parms = {
				PRODUCTION: this.productionId
				};
		zenPage.stopTimers();
		zenLaunchPopupWindow(zenLink('EnsPortal.ProductionDocument.zen'),'','status,scrollbars,resizable=yes,width=1000,height=600',parms);
		zenPage.startTimers(2000);
		return true;
	}
}

/// Get the information needed to display connectors for the given item.<br/>
/// <var>itemNo</var> is the index number of the item.<br/>
/// <var>inputList</var> is an array of index numbers of items that connect to the input.<br/>
/// <var>outputList</var> is an array of index numbers of items that connect to the output.<br/>
ClientMethod getConnectorInfo(itemNo, inputList, outputList) [ Language = javascript ]
{
	// to do: optimize by means of a class connection cache and local client cache - HCR

	if (!hostObj || !hostObj.length) return;

	var host = zenPage.getHost(itemNo);
	if (host && '' !== host.id) {
		// update list of connection information by
		// refreshing JSON component
		var parm = zen('ciHostId');
		parm.value = host.id;
		var parm = zen('ciCat');
		parm.value = zenPage.currCategory;

		var json = this.getComponentById('connectionInfoById');
		json.reloadContents();

		var list = json.getContentObject();

		if (list) {
			// list is of the form:
			// list[n] = {itemName,isTarget}

			// transform to input/output
			var t = 0;
			for (var n = 0; n < list.children.length; n++) {
				var conn = list.children[n];
				t = conn.isTarget;

				// find host item number with name of source/target connection child
				var hostNo = -2;
				for (var lane = 0; lane < 3; lane++) {
					for (var i = 0; i < hostObj[lane].length; i++) {
						if (hostObj[lane][i].name == conn.itemName) {
							hostNo = hostObj[lane][i]._index;
							if ((t==1 && conn.itemName==hostNo) || (t==0 && conn.itemId==hostNo)) { break; }
						}
					}
				}

				// if found by name put it in the appropriate list
				if (hostNo != -2) {
					if (t==1) {
						outputList[outputList.length] = hostNo;
					}
					else {
						inputList[inputList.length] = hostNo;
					}
				}
			}
		}
	}
}

/// Show connectors for the given listing item.
ClientMethod showConnectors(display, itemNo) [ Language = javascript ]
{
	var config = this.getProductionModel();
	if (!config) return;

	var frame = zen('svg');
	var group = frame.getSVGDocument().getElementById('connectorGroup');
	zenPage.clearConnectors(config,frame,group);

	if (!display) {
		// start timers
		zenPage.startTimers();
		return;
	}

	// stop timers
	zenPage.stopTimers();

	// show waiting message
	this.showMsgBox(true);

	// continued... (delay is needed for browsers to catch up and update display)
	var delay = (zenIsIE ? 300 : 0);
	setTimeout(function() {
		zenPage.showConnectorsContd(itemNo, config, frame, group);
	}, delay + 200);
}

/// Clear connectors for the given item.
ClientMethod clearConnectors(config, frame, group) [ Language = javascript ]
{
	// remove connectors from diagram
	if (group) {
		while (group.firstChild) {
			group.removeChild(group.firstChild);
		}
	}

	// unaccent connected items
	for (var n = 0; n < config.children.length; n++) {
		var item = config.children[n];
		if (item._label && item._rect && item._dot) {
			item._dot.setAttribute('r',item._r);
			item._label.setAttribute('style','');

			switch(item.status) {
			// add red background to items that have isMissingClass, not those whose status is 'error'
			case 'error':
				item._dot.setAttribute('style','fill: red;');
				break;
			}
		}
	}

	return;
}

ClientMethod showConnectorsContd(itemNo, config, frame, group) [ Language = javascript ]
{
	// get lists of connections
	var inputList = new Array();
	var outputList = new Array();

	this.getConnectorInfo(itemNo,inputList,outputList);

	// create new connectors
	// track items that are connected
	var hlist = new Object();

	var host = zenPage.getHost(itemNo);
	if (host) {
		hlist[itemNo] = true;
		// inputs
		for (var n = 0; n < inputList.length; n++) {
			var otherNo = inputList[n];
			var otherHost = zenPage.getHost(otherNo);
			hlist[otherNo] = true;

			var line = frame.getSVGDocument().createElementNS(SVGNS,'line');
			line.setAttribute('class','listingConnectorLine');
			line.setAttribute('x1',host._cx1);
			line.setAttribute('y1',host._cy1);
			line.setAttribute('x2',otherHost._cx2);
			line.setAttribute('y2',otherHost._cy2);
			group.appendChild(line);

			// ouput dot for other
			var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
			dot.setAttribute('cx',otherHost._cx2);
			dot.setAttribute('cy',otherHost._cy2);
			dot.setAttribute('r',otherHost._r);
			dot.setAttribute('class','itemNormal');
			dot.setAttribute('style','fill: white;');
			dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
			group.appendChild(dot);

			var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
			dot.setAttribute('cx',otherHost._cx2);
			dot.setAttribute('cy',otherHost._cy2);
			dot.setAttribute('r',otherHost._r/2);
			dot.setAttribute('class','itemNormal');
			dot.setAttribute('style','fill: orange;');
			dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
			group.appendChild(dot);
		}

		// outputs
		for (var n = 0; n < outputList.length; n++) {
			var otherNo = outputList[n];
			var otherHost = zenPage.getHost(otherNo);
			hlist[otherNo] = true;

			var line = frame.getSVGDocument().createElementNS(SVGNS,'line');
			line.setAttribute('class','listingConnectorLine');
			line.setAttribute('x1',host._cx2);
			line.setAttribute('y1',host._cy2);
			line.setAttribute('x2',otherHost._cx1);
			line.setAttribute('y2',otherHost._cy1);
			group.appendChild(line);

			// input dot for other
			var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
			dot.setAttribute('cx',otherHost._cx1);
			dot.setAttribute('cy',otherHost._cy1);
			dot.setAttribute('r',otherHost._r);
			dot.setAttribute('class','itemNormal');
			dot.setAttribute('style','fill: white;');
			dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
			group.appendChild(dot);

			var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
			dot.setAttribute('cx',otherHost._cx1);
			dot.setAttribute('cy',otherHost._cy1);
			dot.setAttribute('r',otherHost._r/2);
			dot.setAttribute('class','itemNormal');
			dot.setAttribute('style','fill: orange;');
			dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
			group.appendChild(dot);
		}

		// input dot for this host
		var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
		dot.setAttribute('cx',host._cx1);
		dot.setAttribute('cy',host._cy1);
		dot.setAttribute('r',host._r);
		dot.setAttribute('class','itemNormal');
		dot.setAttribute('style','fill: white');
		dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
		group.appendChild(dot);

		var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
		dot.setAttribute('cx',host._cx1);
		dot.setAttribute('cy',host._cy1);
		dot.setAttribute('r',host._r/2);
		dot.setAttribute('class','itemNormal');
		dot.setAttribute('style','fill: blue');
		dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
		group.appendChild(dot);

		// ouput dot for this host
		var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
		dot.setAttribute('cx',host._cx2);
		dot.setAttribute('cy',host._cy2);
		dot.setAttribute('r',host._r);
		dot.setAttribute('class','itemNormal');
		dot.setAttribute('style','fill: white;');
		dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
		group.appendChild(dot);

		var dot = frame.getSVGDocument().createElementNS(SVGNS,'circle');
		dot.setAttribute('cx',host._cx2);
		dot.setAttribute('cy',host._cy2);
		dot.setAttribute('r',host._r/2);
		dot.setAttribute('class','itemNormal');
		dot.setAttribute('style','fill: blue');
		dot.setAttribute('onmousedown','zenPage.showConnectors(false);');
		group.appendChild(dot);

		// unaccent non-connected items
		for (var n = 0; n < config.children.length; n++) {
			var item = config.children[n];
			if (item._label && item._rect && item._dot) {
				if (!hlist[item._index]) {
					item._dot.setAttribute('r',host._r/2);
					item._label.setAttribute('style','fill: #D0D0D0;');

					switch(item.status) {
					case 'error':
						item._dot.setAttribute('style','fill: red;');
						//item._rect.setAttribute('style','fill: #FFA0A0; stroke: gray;');
						//item._label.setAttribute('style','fill: white;');
						break;
					}
				}
			}
		}
	}

	this.showMsgBox(false);
}

/// Show mouse tip for given listing item.
ClientMethod showListingTip(itemNo) [ Language = javascript ]
{
	if (this._overlay && this._overlay.parentNode) {
		this._overlay.parentNode.removeChild(this._overlay);
	}
	delete this._overlay;

	if (itemNo==-2 || itemNo==-1 || !hostObj) return;

	var host = zenPage.getHost(itemNo);

	if (host) {
		//sheet.setContent(host.name);

		if (this._currEl) {
			// create overlay
			var svg = zenPage.getComponentById('svgDiagram');

			var el = this._currEl;
			var wid = 200;
			var hgt = 150;

			if ('monitor' == this.currViewMode) {
				wid = 150;
				hgt = 30;
			}
			var x = parseInt(el.getAttribute('cx')) - wid/2;
			var y = parseInt(el.getAttribute('cy')) + parseInt(el.getAttribute('r'));

			var overlay = svg.document.createElementNS(SVGNS,'svg');
			svg.svgGroup.appendChild(overlay);
			this._overlay = overlay;

			var rect = svg.document.createElementNS(SVGNS,'rect');
			overlay.appendChild(rect);

			var group = svg.document.createElementNS(SVGNS,'g');
			overlay.appendChild(group);

			var size = { width:0,height:0, x:0, y:0 };
			
			var status = host.status;
			switch (host.status) {
			case 'ok':
				status = $$$Text('OK');
				break;
			case 'inactive':
				status = $$$Text('Inactive');
				break;
			case 'stopped':
				status = $$$Text('Stopped');
				break;
			case 'disabled':
				status = $$$Text('Disabled');
				break;
			case 'error':
				status = $$$Text('Error');
				break;
			}

			var desc = host.commentOrClassname;
			if (desc.toString().length > 50) {
				// truncate
				desc = desc.substring(0,50) + "...";
			}
			
			// place items in tooltip box
			this.createListingText(svg,group,$$$Text('Name'),host.name,size);
			this.createListingText(svg,group,$$$Text('Status'),status,size);
			this.createListingText(svg,group,$$$Text('Description'),desc,size);

			x = (x+size.width+5 > svg.width) ? svg.width - size.width-5 : x;
			x = (x < 0) ? 0 : x;
			y = (y+size.height+8 > svg.height) ? y - size.height - 18 : y + 8;
			y = (y < 0) ? 0 : y;

			group.setAttribute('transform','translate('+x+','+y+')');
			rect.setAttribute('x',x);
			rect.setAttribute('y',y);
			rect.setAttribute('width',size.width+ 4);
			rect.setAttribute('height',size.height + 4);
			rect.setAttribute('rx',4);
			rect.setAttribute('class','overlay');
		}
	}
}

/// Create a text item on the listing tooltip.
/// Size returns its width and height; 
ClientMethod createListingText(svg, group, caption, value, size) [ Language = javascript ]
{
	var label = svg.document.createElementNS(SVGNS,'text');
	label.setAttribute('class','tooltipLabel');

	var textNode = svg.document.createTextNode(caption);
	label.appendChild(textNode);
	group.appendChild(label);

	var	tw = label.getComputedTextLength() + 6;
	size.width = (size.width>tw) ? size.width : tw;

	var th = zenGetBBox(label).height + 2;
	size.height = size.height + th;
	size.y = size.height - 1;

	label.setAttribute('x',3);
	label.setAttribute('y',size.y);

	var label = svg.document.createElementNS(SVGNS,'text');
	label.setAttribute('class','tooltipValue');

	var textNode = svg.document.createTextNode(value);
	label.appendChild(textNode);
	group.appendChild(label);

	var	tw = label.getComputedTextLength() + 6;
	size.width = (size.width>tw) ? size.width : tw;

	var th = zenGetBBox(label).height + 2;
	size.height = size.height + th;
	size.y = size.height - 3;

	label.setAttribute('x',3);
	label.setAttribute('y',size.y);
}

/// Provide the config data (as an array) that will drive the diagram.
Method GetProductionArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		If (..productionId'="") {
			Set tSC = ##class(EnsPortal.Utils).ProductionItems(..productionId, .pData, .pMetaData)
			If $$$ISERR(tSC) Quit
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Provide the data (as an array) that will drive the display of connection lines, by name.
ClassMethod GetConnectionArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProductionName = $G(pParameters("productionName"))
		Set tHostName = $G(pParameters("hostName"))
		If ((tProductionName'="")&&(tHostName'="")) {
			Set tSC = ##class(EnsPortal.Utils).ItemLineConnections(tProductionName_"||"_tHostName, .pData, .pMetaData)
			If $$$ISERR(tSC) Quit
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Provide the data (as an array) that will drive the display of connection lines, by id.
ClassMethod GetConnectionArrayById(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProductionName = $G(pParameters("productionName"))
		Set tHostId = $G(pParameters("hostId"))
		If ((tProductionName'="")&&(tHostId'="")) {
			Set tSC = ##class(EnsPortal.Utils).ItemLineConnectionsById(tHostId, tProductionName, $G(pParameters("cat")), .pData, .pMetaData)
			If $$$ISERR(tSC) Quit
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Provide the data (as an array) for the settings of the current item, by name.
ClassMethod GetSettingsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProductionName = $G(pParameters("productionName"))
		Set tHostName = $G(pParameters("hostName"))
		If ((tProductionName'="")) {
			If tHostName = "" Set tHostName = "$Production"
			Set tSC = ##class(EnsPortal.Utils).ItemSettings(tProductionName_"||"_tHostName, .pData, .pMetaData)
			If $$$ISERR(tSC) Quit
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Provide the data (as an array) for the settings of the current item, by id.
ClassMethod GetSettingsArrayById(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProductionName = $G(pParameters("productionName"))
		Set tHostId = $G(pParameters("hostId"))
		If (tProductionName'="") && (tHostId'="") {
			//If tHostId = "" Set tHostId = "$Production"
			Set tSC = ##class(EnsPortal.Utils).ItemSettingsById(tHostId, tProductionName, .pData, .pMetaData)
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	#; Check if the item has acquired a new ID due to changes by another user or application
	If $$$ISERR(tSC) && $$$StatusEquals(tSC,$$$LoadObjectNotFound) {
		If $Get(pParameters("hostName"))'="" {
			Set tSC = ##class(EnsPortal.Utils).ItemSettings((tProductionName_"||"_pParameters("hostName")), .pData, .pMetaData)
		}
	}
	Quit tSC
}

/// Provide the data (as an array) for the queue entries of the current item.
ClassMethod GetQueueArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProductionName = $G(pParameters("productionName"))
		Set tHostName = $G(pParameters("hostName"))

		If tProductionName'="" {
			// $LB("QId","QCount","HeaderId","IsRequest","TimeCreated","Source","Target","Status","Error","BPId","BodyClass")
			Set tSC = ##class(EnsPortal.Utils).ItemQueueList(tProductionName_"||"_tHostName, .pData, .pMetaData, , , , , .pMsg,-2 /* limit retrieval to 2 seconds */ , 1 /* continue on msghdr error retrieval */)
			If $$$ISERR(tSC) Quit
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Provide the data (as an array) for the event log entries of the current item.
ClassMethod GetLogArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProductionName = $G(pParameters("productionName"))
		Set tHostName = $G(pParameters("hostName"))

		If (tProductionName'="") {
			// Set pColNames=$LB("Id","Seq","TimeLogged","TraceCat","Type","Job","Session","Source","Method","Stack","MessageId")
			If (tHostName="") {
				// Get the entire event log
				Set tSC = ##class(EnsPortal.Utils).ItemEventLog("", .pData, .pMetaData, 0, 50)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tSC = ##class(EnsPortal.Utils).ItemEventLog(tHostName, .pData, .pMetaData, 0, 50)
				If $$$ISERR(tSC) Quit
			}
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Provide the data (as an array) for the job instances of the current item.
ClassMethod GetJobsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProductionName = $G(pParameters("productionName"))
		Set tHostName = $G(pParameters("hostName"))

		If ((tProductionName'="")&&(tHostName'="")) {
			// Set pColNames=$LB("Job","Name","Status","AdapterState","LastActivity","Count","Method","Retry","ActiveMessage")
			Set tSC = ##class(EnsPortal.Utils).ItemJobs(tProductionName_"||"_tHostName, .pData, .pMetaData)
			If $$$ISERR(tSC) Quit
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Launch the open Production dialog.
ClientMethod loadProduction() [ Language = javascript ]
{
	zenPage.stopTimers();
	//zenLaunchPopupWindow(zenLink('_ZEN.Dialog.finderDialog.zen?SUPER=Ens.Production'),this.addPopupSuffix('ProductionOpen'),'status,scrollbars,resizable=yes,width=800,height=600');
	zenLaunchPopupWindow(zenLink('_ZEN.Dialog.finderDialog.zen?MODE=production'),this.addPopupSuffix('ProductionOpen'),'status,scrollbars,resizable=yes,width=800,height=600');
	zenPage.startTimers(2000);
}

/// This is called when a new item is selected.
/// It should update the various property sheets.
ClientMethod updatePropertySheet(host, skipSettings) [ Language = javascript ]
{
	if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0)) {
		return;
	}
	
	// Update property pane's name caption
	var div = self.document.getElementById('componentName');
	if (div) {
		if (zenPage.productionId == '') {
			div.innerHTML = '&nbsp;';
		} else {
			div.innerHTML = (host.id != -1) ? zenEscapeHTML(host.name) : '<i>' + $$$Text('Production Settings') + '</i>';
			div.title = (host.id != -1) ? zenEscapeHTML(host.name) : zenEscapeHTML(host.name.toString().split('||')[1]);
		}
	}

	// Update tabs (delay is needed for IE to catch up and display new property name before updating the tabs)
	setTimeout(function() {
		return zenPage.updatePropertySheetTabs(host,skipSettings);
	}, 50);
}

/// Update contents of the tabs
ClientMethod updatePropertySheetTabs(host, skipSettings) [ Language = javascript ]
{
	if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0)) {
		this.updateActions(host);
		return true;
	}
	
	if (!skipSettings) this.updateSettings(host);
	this.updateQueue(host);
	this.updateLog(host);
	this.updateMessages(host);
	this.updateJobs(host);
	this.updateActions(host);
	return true;
}

/// Disable setting components when canEdit is false
ClientMethod disableComponents() [ Language = javascript ]
{
	/* this.canEdit will be 0 if source control read only */
	if (!this.canEdit || !this.canEditDB) {
		var form = zen('settingsForm');
		var controls = form.getControlList('id');
		for (var id in zenPage.composites) { controls[id] = zenPage.composites[id]; } // merge in composites that can't be form children because they're not 'control's
		for (var id in controls) {
			if (id!='settCoreEnabled' || !this.canEditDB  || !this.checkHelper('RunItem',true) || this.scReadOnly) {
				controls[id].setProperty('readOnly',true);
				controls[id].setProperty('disabled','true');
			}
		}
	}
	return;
}

/// Apply changes to current item.
ClientMethod applyChanges(noUpdate, noConfirmation) [ Language = javascript ]
{
	// used by drag and drop!
	noUpdate = ('undefined' == typeof noUpdate ? false : noUpdate);

	if (this.scReadOnly) {
		// Do not give a message of this.msgSCReadOnly
		return;
	}

	var host = this.getHost();
	if (host.id < 0) { // Production settings
		if (!this.checkEdit()) return;
	}
	else {
		if (!this.pageModified) {
			alert($$$Text('No changes to apply'));
			return;
		}
		if ((!this.canEdit) && (!this.checkHelper('RunItem',true))) {
			alert(this.msgNotPermitted);
			return;
		}
	}
	if (!this.checkEditDB()) return;

	if (zenPage.settingsSearchStr != '') {
		zenPage.clearSearch();
	}

	// turn off refresh
	// work out whether we need to redraw connectors afterward
	var connGroup = zen('svg').getSVGDocument().getElementById('connectorGroup');
	var showConnectors = false;
	if ((connGroup)&&(connGroup.firstChild)) {
		showConnectors = true;
	}
	// work out whether we were on a specific tab to start with
	var currentTab = null;
	var propTabs = zen('propertyTabs');
	if (propTabs) {
		currentTab = propTabs.getCurrTabNo();
	}
	// get set of items from form
	var form = zen('settingsForm');
	var controls = form.getControlList('id');
	for (var id in zenPage.composites) { controls[id] = zenPage.composites[id]; } // merge in composites that can't be form children because they're not 'control's
	var settings = new zenProxy();
	var switched = new Array();
	var oldValues = new zenProxy();
	var propName;
	for (var id in controls) {
		if (id.indexOf('.')>-1) continue; // ignore sub-controls of composites
		if ('label' == controls[id]._type) continue; // ignore read-only controls
		controls[id].invalid = false;
		var settingType = controls[id].targetType;
		if ('' == settingType) { settingType = 'Host'; } // for Production settings
		if (!settings[settingType]) {
			settings[settingType] = new zenProxy();
		}
		if (!oldValues[settingType]) {
			oldValues[settingType] = new zenProxy();
		}
		var ctrlval = controls[id].getValue();
		if ('Boolean' == controls[id].dataType) ctrlval = (ctrlval == true || ctrlval == 'true' || ctrlval == 1 || ctrlval == '1') ? 1 : 0;
		if (controls[id].originalValue != ctrlval) {
			propName = id.substring(4+controls[id].targetType.length);
			settings[settingType][propName] = ctrlval;
			switched[switched.length] = id;
			oldValues[settingType][propName]= controls[id].originalValue;
		}
	}
	// check that only Enabled has been changed if user can only change that flag
	if ((host.id != -1) && (!this.canEdit)) {
		var other = false;
		for (var i = 0; i < switched.length; i++) {
			if (switched[i] != 'settCoreEnabled') {
				other = true;
				var ctrl = zen(switched[i]);
				if (ctrl) {
					ctrl.setValue(ctrl.originalValue);
				}
			}
		}
		if (other) {
			alert($$$Text("You are only permitted to modify the 'Enabled' flag for items. No changes have taken effect."));
			this.pageModified = false;
			this.notifypageModifiedSet(this.pageModified,host.id);
			return;
		}
	}
	// Check if actor pool is being entirely disabled or pool size being set to 0 from a non zero
	if (host.hostType == 'process' && controls['settCorePoolSize'].value == 0) {
		if (controls['settCoreEnabled'].value == 0) {
			var msgPoolDisable1 = $$$Text("WARNING: 'Enabled' is not checked and 'PoolSize' is 0.");
			var msgPoolDisable2 = $$$Text("It is not possible to do this since the Ens.Actor is a shared actor queue.");
			var msgPoolDisable3 = $$$Text("You can still disable this Business Process, but first set 'PoolSize' > 0 so that this Business Process uses its own dedicated queue. Then you can safely disable it.");
			var msgPoolDisable4 = $$$Text("If you want to disable the shared actor queue set the Production Actor Pool Size to 0.");
			alert(msgPoolDisable1 + "\n" + msgPoolDisable2  + "\n" + msgPoolDisable3  + "\n\n" + msgPoolDisable4);
			return;
		}
		// Check if previous value was not zero and also look to see if any other settings changed
		var other = false;
		var originalPool = -1;
		for (var i = 0; i < switched.length; i++) {
			if (switched[i] == 'settCorePoolSize') {
				var ctrl = zen(switched[i]);
				if (ctrl) {
					originalPool = ctrl.originalValue;
				}
			} else {
				var ctrl = zen(switched[i]);
				if (ctrl) {
					if (ctrl.getValue != ctrl.originalValue) {other = true;}
				}
			}
		}
		if (originalPool > 0) {
			var msgPoolDisable1 = $$$Text("WARNING: 'PoolSize' has been changed to 0. It is not recommended to move a Business Process from having its own dedicated pool to using the public queue.");
			var msgPoolDisable2 = $$$Text("If you do this the business process will handle new requests but outstanding requests on the dedicated queue and pending responses will be left on the dedicated queue.");
			var msgPoolDisable3 = $$$Text("Any messages on the dedicated queue will need to be moved to the public queue using the support API.");
			var msgPoolDisable4 = $$$Text("Are you sure you want to move this Business Process to the public actor pool?");
			if (!confirm(msgPoolDisable1 + "\n" + msgPoolDisable2  + "\n" + msgPoolDisable3 + "\n\n" + msgPoolDisable4)) {
				return;
			}
		}
	}
	// Check if Category has been modified
	var modCat = false;
	var selProdSett = false;
	if (host.id != -1) {
		for (var i = 0; i < switched.length; i++) {
			if (switched[i] == 'settCoreCategory') {
				modCat = true;
				var newCat = '';
				var ctrl = zen(switched[i]);
				if (ctrl) {
					newCat = ctrl.getValue();
				}
				break;
			}
		}
	}
	var messages = new zenProxy();
	messages.name = host.name;
	messages.enabled = host.enabled;
	messages.commentOrClassname = host.commentOrClassname;

	zenPage.stopTimers();
	var err = this.SaveSettingsToServer(this.productionId,host.id,settings['Core'],settings['Host'],settings['Adapter'],messages,this.expandoStatesString(form),oldValues['Core'],oldValues['Host'],oldValues['Adapter']);
	if (err!="") {
		if (messages && messages.error) {
			var controlDiv = controls[messages.error].getEnclosingDiv();
			if (controlDiv) {
				controlDiv.parentNode.style.border = '2px solid red';
				controlDiv.parentNode.title = err;
				controlDiv.children[0].title = err;
			}
			controls[messages.error].focus();
		}
		alert(err);
	} else {
		if (messages && messages.message) alert(messages.message);

		// clear changed flags after successful save
		form.changedSetting = {};
		this.pageModified = false;
		this.notifypageModifiedSet(this.pageModified,host.id);
		var id;
		for (var i = 0; i < switched.length; i++) {
			id = switched[i];
			controls[id].originalValue = controls[id].getValue();
		}
		if (modCat) {
			// Rebuild category select control
			var ctl = document.getElementById('id_Category');
			ctl.options.length=1; // Leave only option "All" which is the first one
			var curr = zenPage.currCategory;
			var found = false;
			var iSel = 0;
			var cats = new Array();
			cats = zenPage.GetCategories(zenPage.productionId);
			for (var i = 0; i < cats.length; i++) {
				if (cats[i] == curr) {
					found = true;
					iSel = i+1;
				}
				ctl.options[ctl.length] = new Option(cats[i], cats[i]);
			}
			ctl.selectedIndex = iSel;
			if (curr != '') {
				if (!found) {
					// The currently selected category is no longer valid for the Production; flag to revert to category 'All' and 'Production Settings', and redraw
					zenPage.currCategory = '';
					zenPage.SavePreferredCategoryForProduction('',zenPage.productionId, this.canEditDB);
					selProdSett = true;
				}
				else {
					if (curr!='') {
						// Check if item still has the currently selected category, if not flag to revert to 'Production Settings' and redraw keeping the same selected category
						var match = false;
						var cl = newCat.split(',');
						for (var i in cl) {
							if (cl[i].replace(/^\s+|\s+$/g,"") == curr) {
								match = true;
								break;
							}
						}
						if (!match) {
							selProdSett = true;
						}
					}
				}
			}
		}

		// Invoked after the redraw to ensure that we keep the values of the
		// frame for output messages from enabling/disabling a specific item.
		// See updateProduction() to see whether the frame is currently in use.
		if (messages && (messages.doUpdate == 1) && !noUpdate) {
			// jmd-- prevent dialog from appearing after drag and drop!
			this.updateProduction('update');
		} else {
			if (!noConfirmation) alert($$$Text('Settings applied'));
		}

		zenPage.KillModifiedSettings();

		if (selProdSett) {
			zenPage.selectItem(-1);
			zenPage.refreshDiagram();					
		}
		else {
			zenPage.updateSettings(host);
			// If there are duplicate hosts, update info to make sure Item drop-down remains accurate after applying changes
			if ((host.hasDups)&&(host.hasDups.length > 1)) {
				zenPage.updateHasDups(host)
				zenPage.redrawItemDuplControl(host);
			}
		}
	}
	zenPage.startTimers(1000);
}

ClientMethod enableMultiItems() [ Language = javascript ]
{
	if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length < 1)) {
		// should never be calling this method if this is the case
		alert($$$Text('No changes to apply'));
		return;
	}
	
	if (!this.checkEditDB()) return;
	
	if ((!this.canEdit) && (!this.checkHelper('RunItem',true))) {
		alert(this.msgNotPermitted);
		return;
	}

	if (this.scReadOnly) {
		alert(this.msgSCReadOnly);
		return;
	}
		
	zenPage.stopTimers();
	var count = 0;
	var err = "";
	zenPage.ClearUpdateErrorLog();
	for (var i = 0; i < this.multiItems.length; i++) {
		var host = zenPage.getHost(this.multiItems[i]);
		if (parseInt(host.enabled)==1) {
			continue;
		}
		var name = host.name;
		var cls = host.commentOrClassname;
		var production = zenPage.productionId;
		var fullname = (production+'||'+name+'|'+cls);
		var ret = zenPage.DoEnableOneItem(fullname,true);
		if (ret!="") {
			err = (err!="") ? err + "\n\n"+ret : ret;
		} else {
			host.enabled = 1;
			count ++;
		}
	}
	if (count == 0) {
		if (err == "") {
			alert($$$Text("All selected items were already enabled.") + " " + $$$Text("No items enabled."));
		} else {
			alert(err + "\n\n" + $$$Text("No items enabled."));
		}
		zenPage.ClearUpdateErrorLog();
	} else {
		if (zenPage.productionState == 1) {
			zenPage.updateProduction('update');
		} else {
			var msg = (err!="") ? err + "\n\n" : "";
			if (count == 1) {
				msg = msg + $$$Text("Enabled 1 configuration item");
			} else {
				msg = msg + $$$FormatText($$$Text("Enabled %1 configuration items"),count);
			}
			alert(msg);
			zenPage.ClearUpdateErrorLog();
		}
	}
	zenPage.startTimers(1000);
}

ClientMethod disableMultiItems() [ Language = javascript ]
{
	if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length < 1)) {
		// should never be calling this method if this is the case
		alert($$$Text('No changes to apply'));
		return;
	}

	if (!this.checkEditDB()) return;

	// canEdit might be false if source control 
	if ((!this.canEdit) && (!this.checkHelper('RunItem',true))) {
		alert(this.msgNotPermitted);
		return;
	}

	if (this.scReadOnly) {
		alert(this.msgSCReadOnly);
		return;
	}

	zenPage.stopTimers();
	var count = 0;
	var err = "";
	zenPage.ClearUpdateErrorLog();
	for (var i = 0; i < this.multiItems.length; i++) {
		var host = zenPage.getHost(this.multiItems[i]);
		if (parseInt(host.enabled)==0) {
			continue;
		}
		var name = host.name;
		var cls = host.commentOrClassname;
		var production = zenPage.productionId;
		var fullname = (production+'||'+name+'|'+cls);
		var ret = zenPage.DoEnableOneItem(fullname,false);
		if (ret!="") {
			err = (err!="") ? err + "\n\n"+ret : ret;
		} else {
			host.enabled = 0;
			count ++;
		}
	}

	if (count == 0) {
		if (err=="") {
			alert($$$Text("All selected items were already disabled.") + " " + $$$Text("No items disabled."));
		} else {
			alert(err + "\n\n" + $$$Text("No items disabled."));
		}
		zenPage.ClearUpdateErrorLog();
	} else {
		if (zenPage.productionState == 1) {
			zenPage.updateProduction('update');
		} else {
			var msg = (err!="") ? err + "\n\n" : "";
			if (count == 1) {
				msg = msg + $$$Text("Disabled 1 configuration item");
			} else {
				msg = msg + $$$FormatText($$$Text("Disabled %1 configuration items"),count);
			}
			alert(msg);
			zenPage.ClearUpdateErrorLog();
		}
	}
	zenPage.startTimers(1000);
}

ClientMethod restartMultiItems() [ Language = javascript ]
{
	if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length < 1)) {
		// should never be calling this method if this is the case
		alert($$$Text('No changes to apply'));
		return;
	}
	/* User does not need edit permissions (!this.canEdit)) since not updating production definition */
	if (!this.checkHelper('RunItem',true)) {
		alert(this.msgNotPermitted);
		return;
	}
		
	if (!this.checkEditDB()) return;
	
	if (zenPage.productionState != 1) {
		alert($$$Text("Cannot restart items while the production is not running."));
		return;
	}
	
	zenPage.stopTimers();
	var count = 0;
	var err = "";
	zenPage.ClearUpdateErrorLog();
	for (var i = 0; i < this.multiItems.length; i++) {
		var host = zenPage.getHost(this.multiItems[i]);
		if (parseInt(host.enabled)==0) {
			continue;
		}
		var name = host.name;
		var cls = host.commentOrClassname;
		var production = zenPage.productionId;
		var fullname = (production+'||'+name+'|'+cls);
		var ret = zenPage.DoTempStopOneItem(fullname,true);
		if (ret!="") {
			err = (err!="") ? err + "\n\n"+ret : ret;
		} else {
			count ++;
		}
	}
	if (count == 0) {
		if (err == "") {
			alert($$$Text("All selected items were disabled.") + " " + $$$Text("No items restarted."));
		} else {
			alert(err + '\n\n' + $$$Text("No items restarted."));
		}
		zenPage.ClearUpdateErrorLog();
	} else {
		zenPage.currRestartItem = -2;
		zenPage.updateProduction('update');
	}
}

ClientMethod restartMultiItemsPart2() [ Language = javascript ]
{
	if ((typeof this.multiItems == 'undefined') || !(this.multiItems instanceof Array) || (this.multiItems.length < 1)) {
		// should never be calling this method if this is the case
		alert($$$Text('No changes to apply'));
		return;
	}
	/* User does not need edit permissions (!this.canEdit)) since not updating production definition */
	if (!this.checkHelper('RunItem',true)) {
		alert(this.msgNotPermitted);
		return;
	}
		
	if (!this.checkEditDB()) return;
	
	zenPage.stopTimers();
	var count = 0;
	var err = "";
	zenPage.ClearUpdateErrorLog();
	for (var i = 0; i < this.multiItems.length; i++) {
		var host = zenPage.getHost(this.multiItems[i]);
		var name = host.name;
		var cls = host.commentOrClassname;
		var production = zenPage.productionId;
		var fullname = (production+'||'+name+'|'+cls);
		var ret = zenPage.DoTempStopOneItem(fullname,false);
		if (ret!="") {
			err = (err!="") ? err + "\n\n"+ret : ret;
		} else {
			count ++;
		}
	}
	if (err!="") {
		alert(err);
		zenPage.ClearUpdateErrorLog();
	}
	
	if (count > 0) {
		zenPage.updateProduction('update');
	}
	/* if using multi restart for one item then clear our temporary use of multiItems */
	if (this.multiItems.length === 1) {this.multiItems = [];};
	zenPage.startTimers(1000);
}

Method DoEnableOneItem(pConfigName As %String, pStart As %Boolean) As %String [ Internal, ZenMethod ]
{
	#dim tSC As %Status = $$$OK
	#dim tErrMsg As %String = ""
	
	// These checks are performed in enableMultiItems() and disableMultiItems(), included here just in case malicious user tried calling directly
	If '##class(EnsPortal.Utils).CheckResourceList(..#EDITRESOURCE)&&'##class(EnsPortal.Utils).CheckResourceList("%Ens_ConfigItemRun:USE") {
		Quit ..msgNotPermitted
	}
	If '..canEditDB {
		Quit ..msgNoDBPermissions
	}
	If ..IsProductionSCReadOnly() {
		Quit ..msgSCReadOnly
	}
	
	Set tSC = ##class(Ens.Director).EnableConfigItem(pConfigName,pStart,0)
	If $$$ISERR(tSC) {
		Set tErrMsg = $System.Status.GetOneStatusText(tSC,1)
		Do ..AddMsgToUpdateErrorLog(tErrMsg, "Ens.Director","EnableConfigItem")
	}
	Quit tErrMsg
}

Method DoTempStopOneItem(pConfigName As %String, pStop As %Boolean) As %String [ Internal, ZenMethod ]
{
	#dim tSC As %Status = $$$OK
	#dim tErrMsg As %String = ""
	
	// These checks are performed in restartMultiItems() and restartMultiItemsPart2(), included here just in case malicious user tried calling directly
	// User does not need ..#EDITRESOURCE
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_ConfigItemRun:USE") {
		Quit ..msgNotPermitted
	}
	If '..canEditDB {
		Quit ..msgNoDBPermissions
	}
	
	Set tSC = ##class(Ens.Director).TempStopConfigItem(pConfigName,pStop,0)
	If $$$ISERR(tSC) {
		Set tErrMsg = $System.Status.GetOneStatusText(tSC,1)
		Do ..AddMsgToUpdateErrorLog(tErrMsg,"Ens.Director","TempStopConfigItem")
	}
	Quit tErrMsg
}

Method ClearUpdateErrorLog() [ Internal, ZenMethod ]
{
	Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings")
}

Method AddMsgToUpdateErrorLog(pMsg As %String = "", pClass As %String = "", pMethod As %String = "")
{
	Quit:pMsg=""
	If $D(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings")) {
		Set tIndex = +$O(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings",""),-1)
	} Else {
		Set tIndex = 0
	}
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings",tIndex+1) = $lb(pClass,pMethod,$zcvt(pMsg,"O","HTML"))
}

/// Return an array indexed categories.
ClassMethod GetCategories(pProd As %String = "") As %ListOfDataTypes [ ZenMethod ]
{
	Set ret = ##class(%ListOfDataTypes).%New()
	Try {
		Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateCategories")
		Set tSC = tRS.Prepare()
		If $$$ISOK(tSC) {
			Set tSC = tRS.Execute(pProd)
			If $$$ISOK(tSC) {
				While (tRS.Next()) {
					Do ret.Insert(tRS.Get("Category"))
				}
			}
		}
	}
	Catch {
	}
	Quit ret
}

/// Start the Production.
ClientMethod startProduction() [ Language = javascript ]
{
	var btn = document.getElementById('command_cmdStart');
	if (btn) {btn.blur()};
	if (zenPage.productionState == 1) {
		alert($$$Text('Production is already running'));
	} else {
		if (!this.checkHelper('RunProd')||!this.checkEditDB()) {
			return false;
		}
		zenPage.stopTimers();
		if (confirm($$$Text('Do you wish to start this Production?'))) {
			zenPage.updateProduction('start');
		}
	}
}

/// Stop the Production.
ClientMethod stopProduction() [ Language = javascript ]
{
	var btn = document.getElementById('command_cmdStop');
	if (btn) {btn.blur()};
	if (zenPage.productionState != 1) {
		alert($$$Text("Production is not running"));
	} else {
		if (!this.checkHelper('RunProd')||!this.checkEditDB()) {
			return false;
		}
		zenPage.stopTimers();
		if (confirm($$$Text("Do you wish to stop this Production?"))) {
			zenPage.updateProduction('stop');
		}
	}
}

/// recover the Production after a crash
ClientMethod recoverProduction() [ Language = javascript ]
{
	var btn = document.getElementById('command_cmdRecover');
	if (btn) {btn.blur()};
	if (zenPage.productionState != 4) {
		alert($$$Text("Production is not troubled"));
	} else {
		if (!this.checkHelper('RunProd')||!this.checkEditDB()) {
			return false;
		}
		if (confirm($$$Text("Do you wish to perform recovery on this troubled Production?"))) {
			zenPage.updateProduction('recover');
		}
	}
}

/// This client method handles start / stop / update / recover Production.
/// A popup is displayed containing progress messages.
ClientMethod updateProduction(action) [ Language = javascript ]
{
	var doUpdate = false;
	switch (action) {
		case 'start':
		case 'stop':
		case 'recover':
			doUpdate = this.checkHelper('RunProd', true);
			break;
		case 'update':
			var btn = document.getElementById('command_cmdUpdate');
			if (btn) {btn.blur()};
			doUpdate = (this.checkHelper('RunProd',true) || this.checkHelper('RunItem', true));
			break;
	}
	if (!doUpdate || !this.canEditDB) {
		var msg = !doUpdate ? this.msgNotPermitted : this.msgNoDBPermissions;
		if (action=='update') {
			msg = $$$Text('Cannot update running production. Changes will not take effect until the production is updated.')+'\n\n'+$$$FormatText($$$Text('Error: %1'),msg);
		}
		alert(msg);
		return false;
	}

	zenPage.stopTimers();
	var parms = {
		PRODUCTION: this.productionId,
		ACTION: action,
		ITEMRESTART: (zenPage.currRestartItem != -1)
	};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.UpdateProduction.zen'),this.addPopupSuffix('UpdateProduction'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
	zenPage.startTimers(5000);
	return true;
}

/// Delete current item.
ClientMethod deleteItem() [ Language = javascript ]
{
	if (!this.checkEdit()||!this.checkEditDB()) {
		return false;
	}
	if (confirm($$$Text("Do you wish to delete this item from the Production?"))) {
		var host = this.getHost();
		if (!host || host.id < 0) return false;

		zenPage.stopTimers();
		var ok = this.DeleteConfigItem(this.productionId, host.id);
		zenPage.startTimers(50);
		if (ok != '') {
			alert(ok);
		}
		else {
			this.selectItem(-1,true);
			if (zenPage.productionState != 1 || !this.updateProduction('update')) {
				this.updateView();
			}
		}
		return true;
	}
	return false;
}

ClassMethod DeleteConfigItem(pProduction As %String, pConfigId As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set pProduction = $get(pProduction)
	Set pConfigId = $get(pConfigId)
	
	Set tProduction = ##class(Ens.Config.Production).%OpenId(pProduction)
	Set tItem = ##class(Ens.Config.Item).%OpenId(pConfigId)
	If $IsObject(tProduction) && $IsObject(tItem) && (tItem.Production = tProduction) {

		Set tSC = ..CallProductionUpdateAndSaveToClass(tProduction,tItem,"RemoveItem")

		If $$$ISOK(tSC) {
			Kill %session.Data("ProdConf_Status",$NAMESPACE,tItem.Name)
			Set tSC = $$$AuditModifyProductionConfig(tProduction.Name,tItem.Name,$$$Text("Item deleted from production using Management Portal"))
		}
	}
	Quit:$$$ISERR(tSC) $ZCVT($$$StatusDisplayString(tSC),"O","JS")
	Quit ""
}

/// Copy current item.
ClientMethod copyItem() [ Language = javascript ]
{
	if (!this.checkEdit()||!this.checkEditDB()) {
		return false;
	}
	var host = this.getHost();
	if (!host || host.id < 0) return false;
	var form = zen('settingsForm');
	var controls = form.getControlList('id');
	if (host.hostType == 'process' && controls['settCorePoolSize'].value == 0) {
		var msgPoolDisable1 = $$$Text("'PoolSize' is 0 for the Business Process to be copied.");
		var msgPoolDisable2 = $$$Text("New items are created disabled after a copy.");
		var msgPoolDisable3 = $$$Text("To prevent disabling the general actor pool the new item will be created with a 'PoolSize' = 1.");
		var msgPoolDisable4 = $$$Text("The copied item can be changed to have a pool size of 0 later when it is enabled and the production is stopped.");
		var msgPoolDisable5 = $$$Text("Would you like to continue?");
		if (controls['settCoreEnabled'].value == 0) {
			msgPoolDisable5 = $$$Text("WARNING: The Business Process to be copied is itself disabled but will not be changed after the copy.") + "\n\n" + msgPoolDisable5
		}
		if (!confirm(msgPoolDisable1 + "\n" + msgPoolDisable2  + "\n" + msgPoolDisable3 + "\n" + msgPoolDisable4 + "\n\n" + msgPoolDisable5)) return;
	}
	var name = prompt($$$Text("Please enter a name for the new item:") + ' ' + host.name + '2');
	if (name) {
		zenPage.stopTimers();
		var ok = '';
		if (name !== name.replace(/^\s+|\s+$/g,'')) {
			ok = ($$$FormatText($$$Text("Item name '%1' has leading or trailing spaces. Please enter again."),name) + '\n');
		} else {
			ok = this.CopyConfigItem(this.productionId, host.id, name);
		}
		zenPage.startTimers(50);
		if (ok != '') {
			alert(ok);
		}
		else if (zenPage.productionState != 1 || !this.updateProduction('update')) {
			this.updateView();
		}
	}
	return true;
}

ClassMethod CopyConfigItem(pProduction As %String, pConfigId As %String, pNewName As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set pProduction = $get(pProduction)
	Set pConfigId = $get(pConfigId)

	Set tProduction = ##class(Ens.Config.Production).%OpenId(pProduction)
	Set tItem = ##class(Ens.Config.Item).%OpenId(pConfigId)

	If $IsObject(tProduction) && $IsObject(tItem) && (tItem.Production = tProduction) {
		// fail if the new name already exists
		For i=1:1:tProduction.Items.Count() { 
			Set tOldItem=tProduction.Items.GetAt(i)
			If (tOldItem.Name=pNewName) && (tOldItem.CommentOrClassname=tItem.CommentOrClassname) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"An item with the name '"_pNewName_"' and comment or class name '" _ tItem.CommentOrClassname _ "' already exists in this Production")
				Quit
			}
		}
		// make a copy of the item
		If $$$ISOK(tSC) {
			Kill %objlasterror
			Set tCopy = tItem.%ConstructClone(1)
			If $IsObject(tCopy) {
				Set tCopy.Name = pNewName
				#;By default, new one is off. Change pool size to 1 if BP and source of copy has PoolSize=0
				Set tCopy.Enabled = 0
				If (tCopy.BusinessType() = $$$eHostTypeProcess) && (tCopy.PoolSize = 0) Set tCopy.PoolSize = 1

				Set tSC = ..CallProductionUpdateAndSaveToClass(tProduction,tCopy,"InsertItem")
				If $$$ISOK(tSC) Set tSC = $$$AuditModifyProductionConfig(tProduction.Name,tCopy.Name,$$$Text("Item added to production via copy using Management Portal"))

			} Else {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to clone item '"_tItem.Name_"':"_$$$StatusDisplayString($G(%objlasterror,$$$OK)))
			}
		}
	}
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

/// Save settings for the given configuration item or general Production.
ClassMethod SaveSettingsToServer(pProductionId As %String, pHostId As %String, pCoreSettings As %ZEN.proxyObject, pHostSettings As %ZEN.proxyObject, pAdapterSettings As %ZEN.proxyObject, pMessages As %ZEN.proxyObject, pExpandoStates As %String, pOldValuesCore As %ZEN.proxyObject, pOldValuesHost As %ZEN.proxyObject, pOldValuesAdapter As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	New $$$EnsProdSettings
	Set tSC = $$$OK, tMsg = ""
	Try {

		/*	Get exclusive update access.
			Some target info needed for the GetDeploymentToken recording but not used later here.
			When goes out of scope on leaving this method the update lock will be automatically released.
		*/
		Set tSC = ##class(Ens.Deployment.Deploy).GetTargetInfo(.tTargetInfo)
		Set:$$$ISOK(tSC) tDeployToken = ##class(Ens.Deployment.Deploy).GetDeploymentToken(,.tTargetInfo,.tSC)
		If $$$ISERR(tSC)||'$IsObject(tDeployToken) {
			Return $$$FormatText("Failed to obtain exclusive update token to update production. %1 ",$$$StatusDisplayString(tSC))
		}

		$$$EnsProdSettingsSetModified(0)
		Set name = pMessages.name
		Set enabled = pMessages.enabled
		Set pMessages.message = ""
		Set pMessages.doUpdate = 0
		Set pMessages.newId = ""

		Do:$IsObject(pCoreSettings) pCoreSettings.%CopyToArray(.tCoreValues)
		Do:$IsObject(pHostSettings) pHostSettings.%CopyToArray(.tHostValues)
		Do:$IsObject(pAdapterSettings) pAdapterSettings.%CopyToArray(.tAdapterValues)
		Do:$IsObject(pOldValuesCore) pOldValuesCore.%CopyToArray(.tOldValuesCore)
		Do:$IsObject(pOldValuesHost) pOldValuesHost.%CopyToArray(.tOldValuesHost)
		Do:$IsObject(pOldValuesAdapter) pOldValuesAdapter.%CopyToArray(.tOldValuesAdapter)

		If ""=pHostId {
			Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to apply settings because configuration item not identified")
			Quit
		} ElseIf -1=pHostId {
			#; Do Production settings
			Set tAuditName = ""
			Merge tSettInfo = %session.Data("ProdConf_Settings") // v(Name) = $LB(Target, Value, ValueSource, DefaultValue, DefaultSource)
			Merge tSettReset = %session.Data("ProdConf_Settings_Reset",1) // Settings that were selected to be reset

			Set tProd = ##class(Ens.Config.Production).%OpenId(pProductionId,,.tSC)
			If '$IsObject(tProd) || $$$ISERR(tSC) {
				Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to apply settings because configuration for Production '"_pProductionId_"' could not be opened:"_$$$StatusDisplayString(tSC))
				Quit
			}
			Set $$$EnsProdSettingsProperty("prod") = tProd
			#; First apply Production Core properties
			Set tProp=""  For { Set tProp = $O(tCoreValues(tProp),1,tValue)  Quit:(tProp = "")
				Try { // Not all values are actual properties
					If tValue'="" { // don't validate empty-string values
						Set tSC = $classmethod("Ens.Config.Production", tProp_"IsValid", tValue)
						If $$$ISERR(tSC) {
							Set pMessages.error = "settCore"_tProp, tTarget="Core"
							Quit
						}
					}
					If ($property(tProd, tProp) '= tValue) {
						Set $property(tProd, tProp) = tValue
						$$$EnsProdSettingsSetModified(1)
					}
				} Catch {
					Set tSC = $$$SystemError
				}
				Set tActions(tProp)=$G(tOldValuesCore(tProp))_">>"_tValue_$S($$$ISERR(tSC):"(ERROR)",1:"")
				Quit:$$$ISERR(tSC)
			} Quit:$$$ISERR(tSC)

			#; Now apply the dynamic setting values.
			$$$ASSERT(pProductionId=tProd.Name)
			Set tName=""  For { Set tName = $O(tHostValues(tName),1,tValue)  Quit:(tName = "")
				If pProductionId'="" && (tValue'="") { // don't validate empty-string values
					Set tSC = $classmethod(pProductionId, tName_"IsValid", tValue)
					If $$$ISERR(tSC) {
						Set pMessages.error = "sett"_tName, tTarget = ""
						Quit
					}
				}
				If $D(tSettReset(tName)) && (tValue=$LG(tSettInfo(tName),4)) {
					Set isReset = 1 // User selected to reset to default and current value still matches the default
				} Else {
					Set isReset = 0
				}
				Kill tSettReset(tName)
				Set tSetting = tProd.FindSettingByName(tName) 
				If $IsObject(tSetting) {
					If 'isReset {
						If (tSetting.Value '= tValue) {
							Set tSetting.Value = tValue
							$$$EnsProdSettingsSetModified(1)
						}
					} Else {
						// Remove this setting because it is being reset, will acquire the default
						Set tSC = ..RemoveSettingByName(tProd, tName, "")
					}
				} Else {
					If 'isReset {
						Set tSetting = ##class(Ens.Config.Setting).%New()
						Set tSetting.Name = tName
						Set tSetting.Value = tValue
						Do tProd.Settings.Insert(tSetting)
						$$$EnsProdSettingsSetModified(1)
					}
				}
				Set tActions(tName) = $G(tOldValuesHost(tName))_">>"_tValue_$S(isReset:"(RESET)",1:"")_$S($$$ISERR(tSC):"(ERROR)",1:"")
			}
			Quit:$$$ISERR(tSC)
			Set tName=""  For { Set tName = $O(tSettReset(tName))  Quit:tName=""
				Set tSC = ..RemoveSettingByName(tProd, tName, "")
				Set tActions(tName_" RESET") = ""
				Quit:$$$ISERR(tSC)
			} Quit:$$$ISERR(tSC)
			Set tSC = ..CallProductionUpdateAndSaveToClass(tProd,"","SaveProduction")  Quit:$$$ISERR(tSC)

		} Else {
			#; Do Item settings
			Set tAuditName = name
			Merge tSettings("Host") = tHostValues
			Merge tSettings("Adapter") = tAdapterValues
			Merge tSettInfo = %session.Data("ProdConf_Settings") // v(Name) = $LB(Target, Value, ValueSource, DefaultValue, DefaultSource)
			Merge tSettReset = %session.Data("ProdConf_Settings_Reset",1) // Settings that were selected to be reset
			Kill tHostValues, tAdapterValues

			If '$system.Security.Check("%Ens_ProductionConfig","WRITE") {
				// Check only enabled/disabled has been changed
				If $data(tSettings) {
					Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
					Quit
				}
				Set k="" For { Set k = $O(tCoreValues(k))  Quit:""=k
					Continue:k="Enabled"
					// Other setting has been changed
					Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
					Quit
				}
				Quit:$$$ISERR(tSC)
			}
			Set tItem = ##class(Ens.Config.Item).%OpenId(pHostId,,.tSC)
			If '$IsObject(tItem) || $$$ISERR(tSC) {
				// Check if the item has acquired a new ID due to changes by another user or application
				Set tFullName=pProductionId_"||"_name_"|"_pMessages.commentOrClassname
				Set tItem=##class(Ens.Config.Production).OpenItemByConfigName(tFullName,.tSC2)
				Set:$$$ISERR(tSC2)||'$IsObject(tItem) tSC2 = $$$ERROR($$$EnsErrGeneral,"Also unable to open item by name '"_tFullName_"' :"_$$$StatusDisplayString(tSC2))
				If $$$ISOK(tSC2) {
					Set tSC = $$$OK
				} Else {
					Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to apply settings because configuration item id '"_pHostId_"' could not be opened: "_$$$StatusDisplayString(tSC))
					Set tSC = $$$ADDSC(tSC,tSC2)
					Quit
				}
				Set:pHostId'=tItem.%Id() pMessages.newId = tItem.%Id()
			}
			Set tProd = tItem.Production
			Set $$$EnsProdSettingsProperty("prod") = tProd

			#; First apply item Core properties
			Set tWasEnabled = tItem.Enabled
			Set tProp=""  For { Set tProp = $O(tCoreValues(tProp),1,tValue)  Quit:(tProp = "")
				Try { // Not all values are actual properties
					If tValue'="" { // don't validate empty-string values
						Set tSC = $classmethod("Ens.Config.Item", tProp_"IsValid", tValue)
						If $$$ISERR(tSC) {
							Set pMessages.error = "settCore"_tProp, tTarget="Core"
							Quit
						}
					}
					If $property(tItem, tProp) '= tValue {
						Set $property(tItem, tProp) = tValue
						$$$EnsProdSettingsSetModified(1)
						Set $$$EnsProdSettingsOref(tItem) = 1
					}
					Set:"Enabled"=tProp&&'tValue pMessages.doUpdate = 1 ; special case for disabling
				} Catch {
					Set tSC = $$$SystemError
				}
				Set tActions(tProp)=$G(tOldValuesCore(tProp))_">>"_tValue_$S($$$ISERR(tSC):"(ERROR)",1:"")
				Quit:$$$ISERR(tSC)
			} Quit:$$$ISERR(tSC)

			#; Now apply the dynamic setting values. 
			For tTarget = "Host","Adapter" {
				Set tSrcClass = $select(tTarget = "Host" : tItem.ClassName, tTarget = "Adapter" : tItem.AdapterClassName(), 1:"")
				Set tName=""  For { Set tName = $O(tSettings(tTarget,tName),1,tValue)  Quit:(tName = "")
					If tSrcClass'="" && (tValue'="") { // don't validate empty-string values
						Set tSC = $classmethod(tSrcClass, tName_"IsValid", tValue)
						If $$$ISERR(tSC) {
							Set pMessages.error = "sett"_tTarget_tName
							Quit
						}
					}
					If $D(tSettReset(tName)) && (tValue=$LG(tSettInfo(tName),4)) {
						Set isReset = 1 // User selected to reset to default and current value still matches the default
					} Else {
						Set isReset = 0
					}
					Kill tSettReset(tName)
					Set tSetting = tItem.FindSettingByName(tName, tTarget)
					If $IsObject(tSetting) {
						If 'isReset {
							If (tSetting.Value '= tValue) {
								Set tSetting.Value = tValue
								$$$EnsProdSettingsSetModified(1)
								Set $$$EnsProdSettingsOref(tSetting) = 1
							}
						} Else {
							// Remove this setting because it is being reset, will acquire the default
							Set tSC = ..RemoveSettingByName(tItem, tName, tTarget)
						}
					} Else {
						If 'isReset {
							Set tSetting = ##class(Ens.Config.Setting).%New()
							Set tSetting.Name = tName
							Set tSetting.Target = tTarget
							Set tSetting.Value = tValue
							Do tItem.Settings.Insert(tSetting)
							$$$EnsProdSettingsSetModified(1)
							Set $$$EnsProdSettingsOref(tSetting) = 1
						}
					}
					Set tActions(tName) = $S(tTarget="Adapter":$G(tOldValuesAdapter(tName)),1:$G(tOldValuesHost(tName)))_">>"_tValue_$S(isReset:"(RESET)",1:"")_$S($$$ISERR(tSC):"(ERROR)",1:"")
				}
				Quit:$$$ISERR(tSC)
			} Quit:$$$ISERR(tSC)

			#; Remove settings from the item if they are in the Reset list
			Set tName=""  For { Set tName = $O(tSettReset(tName))  Quit:tName=""
				Set tSC = ..RemoveSettingByName(tItem, tName, "")
				Set tActions(tName_" RESET") = ""
				Quit:$$$ISERR(tSC)
			} Quit:$$$ISERR(tSC)

			#; Save the item
			Set tSC = ..CallProductionUpdateAndSaveToClass(tProd,tItem,"SaveItem")  Quit:$$$ISERR(tSC)

			#; If we enabled this one, disable any same-name peers
			If tItem.Enabled && 'tWasEnabled {
				#; Scan list of all matching enabled production items, and select the first we find that's a perfect match
				Set pMessages.commentOrClassname = $S(tItem.Comment'="":tItem.Comment, 1:tItem.ClassName) // Update this property as it may have just been changed
				Set tFoundItem=tProd.findItemByName(name,pMessages.commentOrClassname,.tSC,.tEnabledItems)  Quit:$$$ISERR(tSC)
				$$$ASSERT((tFoundItem=tItem) && (tFoundItem.Enabled=1))
				For i=1:1:tEnabledItems {
					If tEnabledItems(i)'=tFoundItem {
						Set tEnabledItems(i).Enabled=0
						Set tSC = ..CallProductionUpdateAndSaveToClass(tProd,tEnabledItems(i),"SaveItem")
						Set tSC3 = $$$AuditModifyProductionConfig(pProductionId,name,$$$Text("Item disabled because another item with the same name was enabled using Management Portal"))
						Quit:$$$ISERR(tSC)
					}
				}
				Quit:$$$ISERR(tSC)
			}
			#; Clear a possible TemporarilyStopped flag
			Kill:(tWasEnabled && 'tItem.Enabled) $$$ConfigTempStop(tItem.Name)
		}
		If $$$EnsProdSettingsModified Do ##class(Ens.Config.Production).SetModified(tProd.Name)
		Set tSC = ##class(Ens.Director).GetProductionStatus(.tCurrentProduction, .tCurrentStatus)
		If $$$ISERR(tSC) {
			$$$LOGSTATUS(tSC)
			Quit
		}
		If (tCurrentProduction = tProd.Name) && (tCurrentStatus = $$$eProductionStateRunning) && $S(-1=pHostId:1,1:tItem.Enabled) {
			Set pMessages.doUpdate = 1
		} ElseIf tCurrentStatus'=$$$eProductionStateRunning {
			Set pMessages.doUpdate = 0
		}
		Do ..StoreExpandoStates($S(-1=pHostId:"$Production",1:tItem.Name),pExpandoStates)
	} Catch {
		Set tSC = $$$SystemError
	}
	If $$$ISOK(tSC) {
		Do ..KillModifiedSettings()
	} Else {
		If $IsObject($get(pMessages)) && (pMessages.error '= "") {
			Set tMsg = $$$FormatText($$$Text("Invalid value for %1 setting '%2'"),tTarget,$E(pMessages.error,4+$L(tTarget)+1,*))_$c(13,10)
		}
		Set tMsg = tMsg _ $$$StatusDisplayString(tSC)
	}

	Set tSC2 = $$$AuditModifyProductionConfig(pProductionId,tAuditName,.tActions)

	Quit tMsg
}

ClassMethod KillModifiedSettings() [ ZenMethod ]
{
	Kill %session.Data("ProdConf_Settings")
	Kill %session.Data("ProdConf_Settings_Reset")
	Quit
}

/// Remove the first setting with a given name.
/// If the user reverts a setting to its default, we remove it from the Production definition.
ClassMethod RemoveSettingByName(pItem As Ens.Config.Item, pName As %String, pTarget As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFound = $$$NULLOREF
		For i=1:1:pItem.Settings.Count() {
			Set tSetting = pItem.Settings.GetAt(i)
			Set tTarget = tSetting.Target
			If tTarget'="Host",tTarget'="Adapter" Continue
		
			// Match the name, and target (if specified)
			If $S(tSetting.Name'=pName:0,pTarget="":1,1:tTarget=pTarget) {
				Set tFound = tSetting
				Quit
			}
		}
		If $IsObject(tFound) {
			Do pItem.Settings.RemoveAt(i)
			If $data($$$EnsProdSettings) $$$EnsProdSettingsSetModified(1)
		}
		Else {
			Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to remove setting '"_pName_"'")
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Remember the expando states of the settings of the old item, return the expando string for the new item.
ClassMethod StoreExpandoStates(pHostname As %String, pStatesString As %String, pNewHostname As %String) As %String [ ZenMethod ]
{
	Set tSC=$$$OK, tNewString=""
	Try {
		For i=1:1:$L(pStatesString,",") { Set tState=$P(pStatesString,",",i)  Continue:""=tState
			Set tName=$P(tState,"="), tVal=$P(tState,"=",2)
			Set ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","SettingsExpandos",tName)=$S(tVal="true":1,1:''tVal)
		}
		#; Set default for Basic=1
		Set:'$D(^IRIS.Temp.EnsPortal($Username,"ProductionConfig","SettingsExpandos","expBasic")) ^IRIS.Temp.EnsPortal($Username,"ProductionConfig","SettingsExpandos","expBasic")=1
		Set tName="" For { Set tName=$O(^IRIS.Temp.EnsPortal($Username,"ProductionConfig","SettingsExpandos",tName),1,tVal)  Quit:""=tName
			Set tNewString = tNewString_","_tName_"="_tVal
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit $E(tNewString,2,*)
}

/// Choose which Production to start with.
ClassMethod GetCurrentProduction() As %String
{
	If $D(%page),$IsObject(%page),%page.productionId'="" { Set tProd = %page.productionId }
	ElseIf $G(%request.Data("PRODUCTION",1))'="" { Set tProd =  %request.Data("PRODUCTION",1) }
	Else  { Set tProd = ##class(EnsPortal.Utils).GetCurrentProductionName() }
	Set:tProd="" tProd = $G(^EnsPortal.Settings($Username,"LastProduction"))
	Set:tProd="" tProd = $G(^IRIS.Temp.EnsPortal($Username,"ProductionConfig","LastProduction"))

	// Must be a valid production name
	If '$ZNAME(tProd,1) || '##class(Ens.Config.Production).%ExistsId(tProd) { Set tProd = "" }

	Quit tProd
}

/// Create a new Production.
ClientMethod newProduction() [ Language = javascript ]
{
	/* 
		need a new check to see if user has resource priv to make new production
		Does not depend on current production canEdit status - might be due to Source Control
	*/
	if (!this.checkHelper('EditResource',false) || !this.checkEditDB()) {
		return false;
	}
	// Show Wizard dialog.
	var parms = {
			};
	zenPage.stopTimers();
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionWizard.zen'),this.addPopupSuffix('NewProductionWizard'),'status,scrollbars,resizable=yes,width=900,height=600',parms);
	zenPage.startTimers(2000);
}

/// Display the dialog popup to allow selection of settings' defaults.
ClientMethod selectSettingsDefaults() [ Language = javascript ]
{
	if (!this.checkEditDB()) {
		return false;
	}

	var itemNo = this.currItem;
	if (itemNo == -1) {
		var hostName = -1;
	}
	else {
		var host = this.getHost(this.currItem);
		var hostName = host.name;
	}

	// Create arrays with the info needed to edit settings' defaults
	var nRows = this._settingsInfo.children.length;
	var aName = new Array();
	var aTarget = new Array();
	var aValue = new Array();
	var aValueSource = new Array();
	var aDefaultValue = new Array();
	var aDefaultSource = new Array();
	var aCurValue = new Array();

	var nActual = 0;
	for (var n = 0; n < nRows; n++) {
		var def = this._settingsInfo.children[n];
		// def contains: $LB("IsAdapter","Name","Value","ValueSource","DefaultValue","DefaultSource","Description","DataType","MAXLEN",etc.
		var origin = def.IsAdapter;
		// Only pass to the dialog core overridable settings for info purposes - not to be reset
		if ((origin != 'Core') || (def.ValueSource == 2)) {
			aName[nActual] = def.Name;
			aTarget[nActual] = origin;
			aValue[nActual] = def.Value;
			aValueSource[nActual] = def.ValueSource;
			aDefaultValue[nActual] = def.DefaultValue;
			aDefaultSource[nActual] = def.DefaultSource;
			nActual++;
		}
	}

	// ... and save them on the server as session data
	zenPage.SaveArraysOfSettings(nActual,aName,aTarget,aValue,aValueSource,aDefaultValue,aDefaultSource,aCurValue);

	// Save current values if they have been modified
	var form = zen('settingsForm');
	var controls = form.getControlList('id');
	for (var id in zenPage.composites) { controls[id] = zenPage.composites[id]; } // merge in composites that can't be form children because they're not 'control's
	var settings = new zenProxy();
	var switched = new Array();
	var k = 0;
	for (var id in controls) {
		if (id.indexOf('.')>-1) continue; // ignore sub-controls of composites
		if ('label' == controls[id]._type) continue; // ignore read-only controls
		if (controls[id]?.readOnly) continue; // make sure to skip the core overridable settings since only passed for info
		var ctrlval = controls[id].getValue();
		if ('Boolean' == controls[id].dataType) ctrlval = (ctrlval == true || ctrlval == 'true' || ctrlval == 1 || ctrlval == '1') ? 1 : 0;
		if (controls[id].originalValue != ctrlval) {
			zenPage.SaveModifiedSetting(controls[id].label,ctrlval);
		}
	}

	// Launch the popup dialog
	var parms = {
		PRODUCTION: zenPage.productionId,
		ITEMNAME: hostName
			};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionItemSettings.zen'),this.addPopupSuffix('EditItemDefaults'),'status,scrollbars,resizable=yes,width=900,height=720',parms);
}

/// Upon return from select defaults window, update any settings that were reset to default by the user.
/// Returns true is any of the settings was actually reset by the user, otherwise returns false.
ClientMethod updateModifiedSettings() [ Language = javascript ]
{
	// To do (hcr):
	// Index temp data by name & target to prevent clashes.
	// Check fields of type boolean, displaylist/valuelist, etc., in case this is needed.
	// Draw a yellow background for modified items, here and when first drawing the settings.

	var ret = false;

	try {
		// Iterate over all returned modified settings
		var name = '';
		do {
			var info = new Array();
			try {
				info = zenPage.GetNextModifiedSetting(name);
				if (info.length == 0) return; // end loop
				var name = info[0];
				var settName = 'sett' + info[1] + name;
				var ctrl = zen(settName);
				ctrl.setValue(info[2]);
				/*	settingChanged() will update changedSetting[],pageModified
					and call notifypageModifiedSet as well as changedSetting[] */
				var form = ctrl.getForm();
			 	this.settingChanged(ctrl.index,(form ? form.index : ''));
				ret = true;
				if (info[3] == 3) {
					ctrl.setProperty('labelStyle','color:darkgreen;font-weight:bold');
				}
				else if (info[3] == 2) {
					ctrl.setProperty('labelStyle','color:blue;font-weight:bold');
				}
			} catch(ex) {
				// A particular setting may be skipped if there is an error
			}
		} while (name != '')
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateModifiedSettings');
	}

	return ret;
}

ClassMethod GetNextModifiedSetting(pName) As %ListOfDataTypes [ ZenMethod ]
{
	Set ret = ##class(%ListOfDataTypes).%New()
	Set pName = $O(%session.Data("ProdConf_Settings_Reset",1,pName))
	If (pName'="") {
		Set info = %session.Data("ProdConf_Settings",pName)
		Do ret.Insert(pName) // [0] name
		Do ret.Insert($LG(info,1)) // [1] target
		Do ret.Insert($LG(info,4)) // [2] default value
		Do ret.Insert($LG(info,5)) // [3] default source
	}
	Quit ret
}

/// Save session data with information about the settings.
ClassMethod SaveArraysOfSettings(pCount As %Integer, ByRef aName As %ListOfDataTypes, ByRef aTarget As %ListOfDataTypes, ByRef aValue As %ListOfDataTypes, ByRef aValueSource As %ListOfDataTypes, ByRef aDefaultValue As %ListOfDataTypes, ByRef aDefaultSource As %ListOfDataTypes) As %String [ ZenMethod ]
{
	//Do ..KillModifiedSettings()
	For i = 1:1:pCount {
		Set %session.Data("ProdConf_Settings",aName.GetAt(i)) = $LB(aTarget.GetAt(i),aValue.GetAt(i),aValueSource.GetAt(i),aDefaultValue.GetAt(i),aDefaultSource.GetAt(i))
	}
	Quit "Done"
}

/// Save session data with information about settings that have been modified by the user.
ClassMethod SaveModifiedSetting(pName As %String, pValue As %String) As %String [ ZenMethod ]
{
	Set %session.Data("ProdConf_Settings_Reset",0,pName) = pValue
	Quit "Done"
}

/// Build an array with the name of all settings that were reset to default.
ClassMethod GetModifiedSettings(ByRef pMod As %ListOfDataTypes) As %Integer [ ZenMethod ]
{
	Set tCount = 0
	Set tName=""  For { Set tName = $O(%session.Data("ProdConf_Settings_Reset",1,tName))  Quit:tName=""
		If $D(%session.Data("ProdConf_Settings_Reset",1,tName)) {
			Set tCount = tCount + 1
			Set pMod(tCount) = tName
		}
	}	
	Quit tCount
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	popupName = this.removePopupSuffix(popupName);
	if (popupName!=='SQLParamAction') {
		if (((action != 'ok')&&(popupName !='RestartOrDisable'))||((action != 'apply')&&(action != 'ok'))) return false;
	}

	switch(popupName) {

	case 'NewProductionWizard':
		// Stop timers
		zenPage.stopTimers();
		// Load the newly created Production with a delay to avoid IE timing issue
		setTimeout(function() {
			self.document.location = zenLink('EnsPortal.ProductionConfig.zen?PRODUCTION=' + encodeURIComponent(value));
		}, 300);
		break;

	case 'ProductionOpen':
		// Stop timers
		zenPage.stopTimers();
		// strip off .cls extension
		var t = value.toString().split('.');
		t.length = t.length - 1;
		var name = t.join('.');
		// Get preferred category, if any
		var cat = zenPage.GetPreferredCategoryForProduction(name, zenPage.canEditDB);
		zenPage.currCategory = cat;
		// Load the selected Production with a delay to avoid IE timing issue
		setTimeout(function() {
			self.document.location = zenLink('EnsPortal.ProductionConfig.zen?PRODUCTION=' + encodeURIComponent(name));
		}, 300);
		break;

	case 'NewServiceWizard':
	case 'NewProcessWizard':
	case 'NewOperationWizard':
		if (value) {
			if (zenPage.productionState == '1') {
				setTimeout(function() {
					if (!zenPage.updateProduction('update')) {
						zenPage.updateView();
					}
				}, 50);
			} else {
				setTimeout(function() {
					zenPage.reloadDiagram();
				}, 50);
			}
		}
		this.updateView();
		break;

	case 'UpdateProduction':
		if (zenPage.currRestartItem > -1) {
			setTimeout(function() {
				try {
					var host = zenPage.getHost(zenPage.currRestartItem);
					if (host.name != zenPage.currRestartName) {
						host = null;
						alert($$$Text('Production has changed while item was being disabled. Please re-enable manually.'));
					}
					zenPage.currRestartItem = -1;
					zenPage.currRestartName = '';
					var settEn = zenPage.getComponentById('settCoreEnabled');
					if (!host || !settEn || settEn.getValue()) {
						/* failed to disable at start of restart procedure */
						setTimeout(function() {
							zenPage.reloadDiagram();
						}, 50);
						return;
					}
					settEn.setValue(true);
					var form = zen('settingsForm');
					form.changedSetting['settCoreEnabled'] = settEn;
					zenPage.pageModified = true; // no need to trigger Apply button style change as Settings will be redrawn by applyChanges()
					zenPage.applyChanges(false,true);
				} catch (err) {}
				}, 50);
		} else if (zenPage.currRestartItem == -2) {
			setTimeout(function() {
				try {
					zenPage.currRestartItem = -1;
					zenPage.currRestartName = '';
					zenPage.restartMultiItemsPart2();
				} catch (err) {}
			}, 50);
		} else {
			setTimeout(function() {
				zenPage.reloadDiagram();
			}, 50);
		}
		break;

	case 'TestItem':
		setTimeout(function() {
			zenPage.reloadDiagram();
		}, 50);
		break;

	case 'SelectDeploymentFile':
		if (value) {
			this.deploymentFile = value;
			var exists = zenPage.CheckFileExists(value);
			if (!exists) {
				alert($$$Text('File does not exist:')+' '+value);
			} else {
				zenPage.stopTimers();
				var extfile = value;
				setTimeout(function() {
						zenPage.importFiletoExportDialog(extfile);
					}, 50);
				zenPage.startTimers(2000);
			}
		}
		break;

	case 'EditItemDefaults':
		if (this.checkEdit()) {setTimeout(function() {
			var mod = zenPage.updateModifiedSettings(value);
		}, 50);}
		break;

	case 'switchNamespace':
		zenPage.changeURLNamespace(value);
		break;

	case 'ScheduleDetails':
		switch(action) {
			case 'ok':
				/* account for some browsers still showing
					schedule details dialog if readOnly
				*/
				var scheduleCtl = zen("settCoreSchedule");
				if (scheduleCtl) {
					var scheduleSelector = zen("settCoreSchedule.selSchedule");
					if (scheduleSelector) {
						if (!scheduleSelector.readOnly) {
							scheduleCtl.setValue(value); 
							scheduleSelector.onchangeHandler();
						}
					}
				}
				break;
			case 'cancel':
				break;
			default:
				break;
		}
		break;

	case 'SelectDirectory':
		if (action == 'ok') {
			var control = zenIndex(this._selectDirectoryControl);
			if (control) {
				control.setValue(value);
				var form = control.getForm();
			 	this.settingChanged(control.index,(form ? form.index : ''));
			}
		}
		delete this._selectDirectoryControl;
		break;
		
	case 'SelectFile':
		if (action == 'ok') {
			var control = zenIndex(this._selectFileControl);
			if (control) {
				control.setValue(value);
				var form = control.getForm();
			 	this.settingChanged(control.index,(form ? form.index : ''));
			}
		}
		delete this._selectFileControl;
		break;

	case 'SQLParamAction':
		var control = zenIndex(this._selectParamControl);
		if (action == 'ok') {
			if ((control)&&(control.getValue()!==value)) {
				control.setValue(value);
				var form = control.getForm();
			 	this.settingChanged(control.index,(form ? form.index : ''));
			}
		}
		if (control) control.switchCurrParam(0);
		delete this._selectParamControl;
		break;

	case 'ProdChangeClass':
		var val = value.split(":");
		var err = zenPage.HostChangeClass(val[0],val[1],zenPage.productionId);
		if (err == '') {
			setTimeout(function() {
				zenPage.updateView();
				zenPage.currTabNo = 1;
				zen('propertyTabs').showTab(1);
			}, 50);
		}
		else {
			setTimeout(function() {
				zenPage.errChangeClass(err);
				err = null;
			}, 50);
		}
		break;
	case 'RestartOrDisable':
		/* 	'ok' means disable - button 1, 'apply' means restart - button 2 */
		setTimeout(function() {
			var host = zenPage.getHost(zenPage.currItem);
			var settEn = zenPage.getComponentById('settCoreEnabled');
			if (!host || !settEn) return;
			settEn.setValue(false);
			var form = zen('settingsForm');
			form.changedSetting['settCoreEnabled'] = settEn;
			zenPage.pageModified = true; // no need to trigger Apply button style change
			if (action == 'apply') {
				zenPage.currRestartItem = zenPage.currItem;
				zenPage.currRestartName = host.name;
			} else {
				zenPage.currRestartItem = -1;
				zenPage.currRestartName = '';	
			}
			zenPage.applyChanges(false,true);
		}, 50);
		
		break;
	case 'EnableItem':
		setTimeout(function() {
				var host = zenPage.getHost(zenPage.currItem);
				var settEn = zenPage.getComponentById('settCoreEnabled');
				if (!host || !settEn) return;
				settEn.setValue(true);
				var form = zen('settingsForm');
				form.changedSetting['settCoreEnabled'] = settEn;
				zenPage.pageModified = true; // no need to trigger Apply button style change
				zenPage.applyChanges(false,true);
		}, 50);
		break;
	}

	return true;
}

/// Helper method to display return error (if any) from the ChangeClass popup callback.
ClientMethod errChangeClass(msg) [ Language = javascript ]
{
	alert($$$Text("Error while saving the new class name:") + "\n" + msg);
}

/// Change value of bus property.
ClientMethod changeBusProperty(value) [ Language = javascript ]
{
	this.busProperty = value;
	this.updateView();
}

ClientMethod settingChanged(ctrlIndex, formIndex) [ Language = javascript ]
{
	var ctrl = zenPage.getComponent(ctrlIndex);
	var val = ctrl.getValue();
	if (ctrl.lastValue == val) return;
	ctrl.lastValue = val;
	ctrl.changed = (ctrl.originalValue != val);
	var form = zenPage.getComponent(formIndex);
	form.changedSetting[ctrl.id] = (ctrl.changed ? ctrl : null);
	ctrl = null;
	for (var ctrlId in form.changedSetting) { ctrl = form.changedSetting[ctrlId];
		if (ctrl) break;
	}
	zenPage.pageModified = !!ctrl;
	var hostid = -1;
	try { hostid = zenPage.getHost(zenPage.currItem).id } catch (e) { hostid = -1 }
	this.notifypageModifiedSet(zenPage.pageModified,hostid);
}

/// Value of Settings search expression has changed
ClientMethod searchChanged() [ Language = javascript ]
{
	var ctrlSearch = this.getComponentById('ctrlSearch');
	var str = ctrlSearch.getValue();
	if (str != this.settingsSearchStr) {
		this.settingsSearchStr = str;
		this.updateSettings(this.getHost(),str);
	}
}

/// Clear value of Settings search expression
ClientMethod clearSearch() [ Language = javascript ]
{
	this.getComponentById('ctrlSearch').setValue('');
	this.searchChanged();
}

/// Clear value of Settings search expression
ClientMethod expandAll(doExpand) [ Language = javascript ]
{
	// toggle state
	zenPage.settingsExpanded = (!doExpand ? true : false);
	var img = this.getComponentById('btnExpandAll');
	img.setProperty('src',(zenPage.settingsExpanded ? "images/arrow1D.gif" : "images/arrow1R.gif"));
	img.setProperty('title',(zenPage.settingsExpanded ? "Contract all" : "Expand all"));
	var form = zen('settingsForm');
	for (var e = 0; e < form.children.length; e++) {
		var child = form.children[e];
		if ('expando' == child._type) {
			child.expanded = zenPage.settingsExpanded;
		}
	}
	this.updateSettings(this.getHost());
}

/// Beginning of drag-drop connection.
ClientMethod startRubberBand(x, y) [ Language = javascript ]
{
	var svg = zen('svg');

	if (this._currRubberBand) {
		// delete the rubber band
		svg.svgGroup.removeChild(this._currRubberBand);
	}
	this._currRubberBand = null;

	// remember start positions
	var zoom = svg.zoom;
	this._rubberX = x * 100/zoom;
	this._rubberY = y * 100/zoom;

	var path = svg.document.createElementNS(SVGNS,'path');
	path.setAttribute("class",'RubberBand');
	path.setAttribute("d",this.getPolyPath(x,y,x,y));

	svg.svgGroup.appendChild(path);
	this._currRubberBand = path	;
}

/// Move edge of drag-drop connection.
ClientMethod moveRubberBand(x, y) [ Language = javascript ]
{
	if (this._currRubberBand) {
		var svg = zen('svg');
		var zoom = svg.zoom;
		this._currRubberBand.setAttribute("d", this.getPolyPath(this._rubberX,this._rubberY,x*100/zoom,y*100/zoom));
	}
}

/// End of drag-drop connection.
ClientMethod endRubberBand() [ Language = javascript ]
{
	// delete the rubber band
	if (this._currRubberBand) {
		var svg = zen('svg');
		svg.svgGroup.removeChild(this._currRubberBand);
	}
	this._currRubberBand = null;
}

/// Return a path string that best goes from p1 to p2.
ClientMethod getPolyPath(x1, y1, x2, y2) [ Language = javascript ]
{
	return 'M ' + x1 + ' ' + y1 + ' L ' + x2 + ' ' + y2;
}

/// Mouse down on the status dot for an item.
ClientMethod itemDotMouseDown(evt, itemNo, canConnect, cx, cy) [ Language = javascript ]
{
	this.selectItem(itemNo);
	this.endRubberBand();

	// remember info on start of mouse operation
	this._cx = cx;
	this._cy = cy;
	this._downX = evt.clientX;
	this._downY = evt.clientY;
	this._itemNo = itemNo;
	this._canConnect = canConnect;
	this._connectTargetNo = null;
	this._connectTarget = null;
	this._startTarget = evt.target;

	// turn on mouse move handlers
	var svg = zen('svg');
	svg.svgGroup.addEventListener('mousemove',this._mmHandler,false);
	svg.svgGroup.addEventListener('mouseup',this._muHandler,false);
}

/// Mouse over on the status dot for an item.
ClientMethod itemDotMouseOver(evt, itemNo, acceptConnect) [ Language = javascript ]
{
	// evt.stopPropagation();
	if (this._currRubberBand) {
		if (acceptConnect) {
			evt.target.setAttribute("class","itemHoverAccept");
			this._connectTarget = evt.target;
			this._connectTargetNo = itemNo;
		}
	}
	else {
		evt.target.setAttribute("class","itemHover");
	}
}

/// Mouse out on the status dot for an item.
ClientMethod itemDotMouseOut(evt, itemNo) [ Language = javascript ]
{
	//evt.stopPropagation();
	if (evt.target.getAttribute("class")!='itemNormalStart') {
		evt.target.setAttribute("class","itemNormal");
	}
	//this._connectTarget = null;
	//this._connectTargetNo = null;
}

/// Mouse move handler.
ClientMethod backgroundMouseMoveHandler(evt) [ Language = javascript ]
{
	//evt.stopPropagation();
	var svg = zen('svg');

	if (this._canConnect) {
		// check for start of rubber band
		if (!this._currRubberBand) {
			var dx = evt.clientX - this._downX;
			var dy = evt.clientY - this._downY;
			if ((dx*dx + dy*dy)>2) {
				this.startRubberBand(this._cx,this._cy);
				if (this._startTarget) {
					this._startTarget.setAttribute("class","itemNormalStart");
				}
			}
		}
		else {
			this.moveRubberBand(evt.clientX,evt.clientY);
		}
	}
}

/// Mouse up handler.
ClientMethod backgroundMouseUpHandler(evt) [ Language = javascript ]
{
	//evt.stopPropagation();
	var svg = zen('svg');

	if (this._currRubberBand) {
		this.endRubberBand();
		if (this._startTarget) {
			this._startTarget.setAttribute("class","itemNormal");
		}
		if (this._connectTarget) {
			this._connectTarget.setAttribute("class","itemNormal");
		}
		if (null !== this._connectTargetNo && null !== this._itemNo) {
			this.connectItems(this._itemNo,this._connectTargetNo);
		}
	}

	// turn off mouse events
	svg.svgGroup.removeEventListener('mousemove',this._mmHandler,false);
	svg.svgGroup.removeEventListener('mouseup',this._muHandler,false);

	if ((null!==this._itemNo) && this._downX == evt.clientX) {
		this.showConnectors(true,this._itemNo);
	}

	this._downX = null;
	this._downY = null;
	this._itemNo = null;
	this._canConnect = false;
	this._connectTarget = null;
	this._connectTargetNo = null;
	this._startTarget = null;
}

/// Try to make a connection from start item to end item. 
/// This works by modifying TargetConfigNames list in the start element.
ClientMethod connectItems(startNo, endNo) [ Language = javascript ]
{
	if (!this.checkEdit()) {
		return false;
	}

	var start = this.getHost(startNo);
	var end = this.getHost(endNo);

	if ((start)&&(end)) {
		// find TargetConfigNames in start element and add to it! 
		var form = zen('settingsForm');
		for (var n = 0; n < form.children.length; n++) {
			// controls are within groups
			var group = form.children[n];
			if (group.children) {
				for (var k = 0; k < group.children.length; k++) {
					var ctrl = group.children[k];
					if ('settHostTargetConfigNames' == ctrl.id || 'settHostTargetConfigName' == ctrl.id) {
						var configNames = ctrl.getValue();
						var alreadyThere = false;
						
						if ('' !== configNames) {
							// make sure we are not already connected
							var t = configNames.toString().split(',');
							for (var p = 0; p < t.length; p++) {
								if (t[p] == end.name) {
									alreadyThere = true;
									alert($$$Text('Items are already connected'));
									break;
								}
							}
						}
						if (!alreadyThere) {
							var msg = $$$FormatText($$$Text("Do you want to set '%1' as a target of '%2' ?"),end.name,start.name);
							if (!confirm(msg)) return false;
							if ('' == configNames) {
								ctrl.setValue(end.name);
							} else {
								t[t.length] = end.name;
								ctrl.setValue(t.join(','));
							}
							zenPage.pageModified = true; // no need to trigger Apply button style change
							zenPage.applyChanges(true);
							zenPage.showConnectors(true,startNo);
						}
					}
				}
			}
		}
	}
}

ClientMethod updateHasDups(host) [ Language = javascript ]
{
	// first update dups info in the host
	var dups = new Array();
	dups = zenPage.GetDuplicateItems(zenPage.productionId,host.name);
	host.hasDups = new Array();
	var k = 0;
	for (var i in dups) {
		host.hasDups[k] = new Array();
		host.hasDups[k][0] = i;
		host.hasDups[k][1] = dups[i];
		k++;
	}
	// save in hostObj for future selections
	var loc = zenPage.findHostObj(host._index); var n = Math.floor(loc/10); var ln = loc % 10;
	hostObj[ln][n].hasDups = host.hasDups.slice(0);
}

ClientMethod drawDuplBox(itemNo, count) [ Language = javascript ]
{
	try {
		var svg = zen('svgDiagram');
		var itemRect = svg.document.getElementById('item_' + itemNo);
		var ix = +itemRect.getAttribute('x');
		var iy = +itemRect.getAttribute('y');
		var posx = ix - 3;
		var posy = iy - 5;
		var rect = svg.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('id','id_duplBox');
		rect.setAttribute('x',posx);
		rect.setAttribute('rx',2);
		rect.setAttribute('y',posy);
		rect.setAttribute('width',11);
		rect.setAttribute('height',12);
		rect.setAttribute('class','duplBoxRect');
		svg.svgGroup.appendChild(rect);
		var label = svg.document.createElementNS(SVGNS,'text');
		label.setAttribute('class','duplBoxLabel');
		label.setAttribute('x',posx + 3);
		label.setAttribute('y',posy + 9);
		var textNode = svg.document.createTextNode(count + '');
		label.appendChild(textNode);
		svg.svgGroup.appendChild(label);
		var tw = label.getComputedTextLength() + 6;
		if (tw > 11) {
			rect.setAttribute('width',tw);
		}
	} catch(ex) {
	}
}

/// Show select control on diagram header offering choice of the duplicate item(s).
ClientMethod redrawItemDuplControl(host) [ Language = javascript ]
{
	var ctl = document.getElementById('id_Choose');
	ctl.options.length = 0;
	var curr = zenPage.currCategory;
	var isSel = false;
	var selIndex = 0;
	for (var i = 0; i < host.hasDups.length; i++) {
		if (host.hasDups[i][0] == host.id) {
			isSel = true;
			selIndex = i;
		}
		else {
			isSel = false;
		}
		ctl.options[ctl.length] = new Option(host.hasDups[i][1], host.hasDups[i][0], isSel);
	}
	for (var i = 0; i < ctl.options.length; i++) {
		ctl.options[i].title = ctl.options[i].text;
	}
	var span=document.getElementById('id_spanChoose');
	span.style.visibility = 'visible';
	span.title = $$$FormatText($$$Text('Choose which instance of item \'%1\' to edit'),host.name);
	ctl.selectedIndex = selIndex; // for IE
}

/// In case of duplicate names, handle the switch to a different item.
ClientMethod switchDuplItem() [ Language = javascript ]
{
	try {
		var ctl = document.getElementById('id_Choose');
		var sel = ctl.selectedIndex;
		var newId = ctl.options[sel].value;
		
		if (this.multiItems && (this.multiItems instanceof Array) && (this.multiItems.length > 0)) {
			var itemNo = this.multiItems[this.multiItems.length - 1];  // last item in the array was the previously selected host by this name
		} else {
			var itemNo = zenPage.currItem;
		}

		var host = zenPage.getHost(itemNo);
		var newInfo = new Array();
		newInfo = zenPage.GetDuplicateInfo(newId,zenPage.productionId);

		// update host and hostObj
		var loc = zenPage.findHostObj(itemNo); var n = Math.floor(loc/10); var ln = loc % 10;
		host.hostType = newInfo[1]; hostObj[ln][n].hostType = newInfo[1];
		host.enabled = parseInt(newInfo[2]); hostObj[ln][n].enabled = parseInt(newInfo[2]);
		host.status = newInfo[4]; hostObj[ln][n].status = newInfo[4]; // status may change!
		host.connectStatus = newInfo[5]; hostObj[ln][n].connectStatus = newInfo[5]; // connectStatus may change!
		host.id = parseInt(newId); hostObj[ln][n].id = parseInt(newId);
		host.commentOrClassname = newInfo[7]; hostObj[ln][n].commentOrClassname = newInfo[7];
		host.classname = newInfo[8]; hostObj[ln][n].classname = newInfo[8];
		host.busPartner = newInfo[9]; hostObj[ln][n].busPartner = newInfo[9];
		host.category = newInfo[10]; hostObj[ln][n].category = newInfo[10]; // category may change!
		host.isMissingClass = newInfo[11]; hostObj[ln][n].isMissingClass = newInfo[11]; // isMissingClass may change!

		if (!this.multiItems || !(this.multiItems instanceof Array) || (this.multiItems.length < 1)) {
			var config = this.getProductionModel();
			var frame = zen('svg');
			var group = frame.getSVGDocument().getElementById('connectorGroup');
			zenPage.clearConnectors(config,frame,group);

			// display tabs for the newly selected item
			zenPage.selectItem(itemNo,true,false);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Unable to switch item - Error in switchDuplItem');
	}
}

/// See if there are multiple copies with the same name as the given item within the Production.
ClassMethod GetDuplicateItems(pProd As %String, pName As %String) As %ArrayOfDataTypes [ ZenMethod ]
{
	Set Dups = ##class(%ArrayOfDataTypes).%New()
	Set tRS = ##class(%ResultSet.SQL).%Prepare("SELECT ID,ClassName,Comment,Enabled FROM Ens_Config.Item WHERE Production=? AND Name=?",,,pProd,pName)
	If $IsObject(tRS) {
		For {
			Quit:'tRS.%Next()
			Set tOp = tRS.%Get("Comment")
			Set:$ZStrip(tOp,"<>","W")="" tOp = tRS.%Get("ClassName")
			Set:tRS.%Get("Enabled") tOp = tOp_" *"
			Do Dups.SetAt(tOp,tRS.%Get("ID"))
		}
	}
	Quit Dups
}

/// Get host information for the newly selected item id.
ClassMethod GetDuplicateInfo(pId As %String, pProd As %String) As %ListOfDataTypes [ ZenMethod ]
{
	// $LB("name"(0),"hostType"(1),"enabled"(2),"position"(3),"status"(4),"connectStatus"(5),"id"(6),"commentOrClassname"(7),"classname"(8),"busPartner"(9),"category"(10),"isMissingClass"(11)) - ignore "position"

	Set v = ##class(%ListOfDataTypes).%New()
	Set tIsRunning = ($G($$$EnsRuntime("Name")) = pProd)
	Set tItem = ##class(Ens.Config.Item).%OpenId(pId)
	If '$IsObject(tItem) Quit
	Set tSC = ##class(EnsPortal.Utils).ProductionOneItem(tItem, tIsRunning, "", .tEntry)
	If $$$ISOK(tSC) && ($G(tEntry)'="") {
		For i = 1:1:$LL(tEntry) {
			Do v.Insert($LG(tEntry,i))
		}
	}
	Quit v
}

/// Turn auto-refresh mode on and off.
ClientMethod setRefreshMode(newMode, notImmediate) [ Language = javascript ]
{
	if (!this.enableAutoRefresh) {
		return;
	}
	var oldMode = this.refreshMode;
	this.refreshMode = newMode;
	var rfOn = self.document.getElementById('refreshOn');
	var rfOff = self.document.getElementById('refreshOff');
	rfOn.checked = newMode;
	rfOff.checked = !newMode;
	if (!notImmediate) this.updateView();
	if (zenPage.refreshMode) {
		zenPage.restartRefreshTimer();
	}
	else {
		zen('refreshTimer').clearTimer();
	}
	if (zenPage.UpdateAutoRefreshStateProd) { zenPage.UpdateAutoRefreshStateProd(newMode, this.productionId); }
	return oldMode;
}

/// Stop timers.
ClientMethod stopTimers() [ Language = javascript ]
{
	zen('statusTimer').clearTimer(); // stop status timer
	zen('refreshTimer').clearTimer(); // stop reload/refresh timer
	zenPage.refreshRate = 0;
}

/// Start timers.
/// The delay is in milliseconds and should be an integer, eg. 2000 for 2000 ms (2 s).
ClientMethod startTimers(delay) [ Language = javascript ]
{
	if (!zenPage.enableAutoRefresh) {
		return;
	}
	if (typeof(delay)=='undefined') var delay = 0;
	if (delay<50) delay = 50;
	
	zenPage.refreshRate = delay/1000;

	setTimeout(function() {
		zen('statusTimer').setProperty('timeout',delay);
		zen('statusTimer').startTimer(); // start status timer
		zenPage.restartRefreshTimer(); // restart status timer if set to on
	}, delay);
}

/// Start refresh timer if Refresh=On.
ClientMethod restartRefreshTimer() [ Language = javascript ]
{
	if (zenPage.enableAutoRefresh && zenPage.refreshMode) {
		zen('refreshTimer').setProperty('timeout',60000); // 60 seconds refresh interval
		zen('refreshTimer').startTimer();

		if (zenPage.refreshRate > 60) {
			zenPage.refreshRate = 60;
		}
	}
}

/// Diagram auto-refresh timer handler.
ClientMethod refreshHandler() [ Language = javascript ]
{
	if (!zenPage || (zenPage.productionId=='') || (!zenPage.enableAutoRefresh)) {
		return;
	}

	zenPage.stopTimers();
	zenPage.reloadDiagram();
}

/// Reload diagram with a fresh copy.
ClientMethod reloadDiagram() [ Language = javascript ]
{
	var refreshElement = document.getElementById('id_refresh');
	if (refreshElement) {
		refreshElement.style.backgroundColor = '#D0F8D0';
	}
	setTimeout(function() {
		zenPage.updateView(true);
	}, 50);
}

/// Status indicators auto-refresh timer handler.
ClientMethod refreshStatusHandler() [ Language = javascript ]
{
	if (!zenPage || (zenPage.productionId=='') || (!zenPage.enableAutoRefresh)) {
		return;
	}

	var allChanges = zenPage.GetChangedStatuses(zenPage.productionId);
	if (allChanges) {
		if (allChanges == "@") {
			alert($$$Text("Reloading page due to recompilation of Production.\nAny unsaved settings changes have been lost."));
			location.reload(false);
			return;
		}

		/* look to see if default db changed from RO to RW */
		if (this.dbIsRO&&!zenPage.defaultMountedReadOnly()) {
			alert($$$Text("Reloading page due to Read/Write status change for default database."));
			location.reload(false);
			return;
		}

		/* look to see if production source control status changed */
		if ((this.sourceControlEnabled)&&(this.scReadOnly!=zenPage.IsProductionSCReadOnly())) {
			alert($$$Text("Reloading page due to Source control status changing for production."));
			location.reload(false);
			return;
		}

		var whatChanged = allChanges.split("#");

		if (whatChanged[0]=='1') {
			// Production status has changed, redraw the diagram header and tabs (except the settings tab)
			zenPage.refreshDiagramHeaderStates(false);
			var host = zenPage.getHost();
			zenPage.updatePropertySheetTabs(host, false);
		}

		var changed = whatChanged[1]; // list of item status changes
		if (changed != '') {
			var toUpdate = changed.split(";")
			for (var i=0; i < toUpdate.length; i++) {
				// update hostObj and diagram status indicator
				var done = false;
				var s = toUpdate[i].split(",");
				for (var lane = 0; lane < 3; lane++) {
					for (var n = 0; n < hostObj[lane].length; n++) {
						if (hostObj[lane][n].id == s[0]) {
							hostObj[lane][n].status = s[1];
							hostObj[lane][n].connectStatus = s[2];
							if (hostObj[lane][n]._dot) {
								zenPage.updateDotColor(hostObj[lane][n]._dot,hostObj[lane][n]);
							}
							done = true;
							// If item whose status changed is the currently selected item, redraw tabs (except setting tab)
							var chgNo = hostObj[lane][n]._index;
							if (zenPage.currItem == chgNo) {
								var host = hostObj[lane][n];
								zenPage.updatePropertySheetTabs(host, false);
							}
							break;
						}
					}
					if (done) break;
				}
			}
		}
	}
	zen('statusTimer').setProperty('timeout',5100); // 5.1 seconds status refresh interval
	zen('statusTimer').startTimer(); // set next check
	zenPage.refreshRate = 5.1;
}

/// Server-side method that checks if the Production status has changed and which item statuses have changed.
/// Returns ProductionStatusHasChanged#ItemId,Lane,ItemStatus,AdapterStatus;..." (max. ~32K). Only items whose status has changed are in the list of items.
ClassMethod GetChangedStatuses(ByRef pProd As %String) As %String [ ZenMethod ]
{
	Quit ##class(EnsPortal.Utils).CheckForProductionStatusChange(pProd)
}

/// Change the underlying class of a production item to the specified class 
ClassMethod HostChangeClass(pHostId As %String, pClassName As %String, pProductionId As %String) As %String [ ZenMethod ]
{
	Set msg = ""
	Try {
		// Open item configuration object
		Set item = ##class(Ens.Config.Item).%OpenId(pHostId, .tSC)
		Quit:$$$ISERR(tSC)
		If ('$IsObject(item)) || ('$IsObject(item.Production)) || (item.Production.%Id()'=pProductionId) {
			Set msg = $$$Text("Unexpected error while opening the configuration item - Unable to save") Quit
		}
		Set production = item.Production

		// Set the new classname and remember prior for audit entry
		Set tPriorClassName = item.ClassName
		Set item.ClassName = pClassName

		// Remove settings that do not belong in the new class/adapter
		Set settings = item.Settings
		Set modified = 0
		Do $ClassMethod(pClassName,"GetSettings",.tClassSettings)
		Try { 
			If (item.AdapterClassName()'="") Do $ClassMethod(item.AdapterClassName(),"GetSettings",.tAdapterSettings)
		} Catch {}
		For i = 1:1 {
			Quit:i>settings.Count()
			Set sett = settings.GetAt(i)
			Set type = sett.Target
			Set name = sett.Name
			Set val = sett.Value
			Set remove = 1
			Try {
				If type="Host" {
					Set tSC = $ClassMethod(pClassName, name_"IsValid", val)
					Set remove = $S($$$ISERR(tSC):1,1:'$D(tClassSettings(":",name)))
				}
				ElseIf type="Adapter" {
					Set tSC = $ClassMethod(item.AdapterClassName(), name_"IsValid", val)
					Set remove = $S($$$ISERR(tSC):1,1:'$D(tAdapterSettings(":",name)))
				}
			}
			Catch {
			}
			If remove {
				Do settings.RemoveAt(i)
				Set i = i-1
				Set modified = 1
			}
		}
		If modified {
			Set item.Settings = settings
		}

		// Save and update the Production's XData block
		Set tSC = ..CallProductionUpdateAndSaveToClass(production,item,"SaveItem")
		If $$$ISOK(tSC) Set tSC = $$$AuditModifyProductionConfig(production.Name,item.Name,$$$FormatText($$$Text("Item class changed in production using Management Portal from %1 to %2"),tPriorClassName,pClassName))

	} Catch {
		Set tSC = $$$SystemError
	}
	If $$$ISERR(tSC) {
		Set msg = $system.Status.GetErrorText(tSC)
	}
	Quit msg
}

/// Click on business partner box.
ClientMethod busPartnerClick(partnerName) [ Language = javascript ]
{
	// show details
	var parms = {
		NAME:partnerName
	};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessPartnerDetails.zen'),'','status,scrollbars,resizable=yes,width=700,height=800',parms);
}

/// Show or hide "Update" button and set its own color.
/// <var>show</var>=true indicates the button is to be shown, and false to be hidden.
ClientMethod showUpdateButton(show, states) [ Language = javascript ]
{
	var btn = document.getElementById('command_cmdUpdate');
	if (btn) {
		if (show) {
			btn.style.backgroundColor = 'red'; // was '#F08080'
			btn.style.color = 'yellow';
			btn.style.visibility = 'visible';
			btn.title = ((states.needsUpdateReason == '') ? $$$Text('Update Production') : (states.needsUpdateReason));
		} else {
			btn.style.visibility = 'hidden';
		}
	}
}

/// Show or hide "Recover" button and set its own color.
/// <var>show</var>=true indicates the button is to be shown, and false to be hidden.
ClientMethod showRecoverButton(show) [ Language = javascript ]
{
	var btn = document.getElementById('command_cmdRecover');
	if (btn) {
		if (show) {
			btn.style.backgroundColor = 'red'; // was '#F06060';
			btn.style.color = 'white';
			btn.style.visibility = 'visible';
		} else {
			btn.style.visibility = 'hidden';
		}
	}
}

ClientMethod showLegend() [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionConfigurationLegend.zen'),'','status=no,scrollbars=no,resizable=no,width=700,height=600,left=400');
}

ClientMethod gotoMessageViewer() [ Language = javascript ]
{
	var parms = '';
	if (zenPage.currItem != -1) {
		parms = '?SOURCEORTARGET=' + encodeURIComponent(zenPage.getHost().name);
	}
	window.open(zenLink('EnsPortal.MessageViewer.zen' + parms));
}

ClientMethod initSecurity() [ Language = javascript ]
{
	var ok = this.updateSecurityHelper();

	if (!this.securityHelper) {
		return;
	}

	// tabSettings and tabActions should always be accessible
	var checkTabs = {'tabQueue'   : 'Queues',
					 'tabEventLog': 'EventLog',
					 'tabMessages': 'Headers',
					 'tabJobs'    : 'Jobs'
					};
	for (var tabName in checkTabs) {
		var prop = checkTabs[tabName];
		if ((this.securityHelper[prop] != null) && (parseInt(this.securityHelper[prop],10) != 1)) {
			var tab = zen(tabName);
			if (tab) {
				tab.setProperty('disabled', true);
				tab.setProperty('title', $$$Text('You do not have sufficient privileges to view this tab'));
			}
		}
	}
}

ClientMethod checkHelper(toCheck, noAlert) [ Language = javascript ]
{
	if ((toCheck == null) || (!this.securityHelper) || (this.securityHelper[toCheck] == null)) {
		return true;
	}
	if (parseInt(this.securityHelper[toCheck],10) != 1) {
		if (!noAlert) {
			alert(this.msgNotPermitted);
		}
		return false;
	}
	return true;
}

ClientMethod updateSecurityHelper() [ Language = javascript ]
{
	var newHelper = zenPage.GetSecurityHelper();
	if (newHelper) {
		zenPage.securityHelper = newHelper;
	}
	return true;
}

ClassMethod GetSecurityHelper() As %ZEN.proxyObject [ ZenMethod ]
{
	Set tSecurityHelper = ##class(%ZEN.proxyObject).%New()
	
	// List of checked values for the user: propertyName, resource, permission
	Set tChecks = $lb(	$lb("RunProd", "%Ens_ProductionRun", "USE"),
						$lb("RunItem", "%Ens_ConfigItemRun","USE"),
						$lb("EventLog", "%Ens_EventLog", "USE"),
						$lb("Queues", "%Ens_Queues", "READ"),
						$lb("Headers", "%Ens_MessageHeader", "USE"),
						$lb("Jobs", "%Ens_Jobs", "READ"),
						$lb("JobsEdit", "%Ens_Jobs", "WRITE"),
						$lb("SuspendMessage", "%Ens_MessageSuspend", "USE"),
						$lb("Test", "%Ens_TestingService", "USE"),
						$lb("Document", "%Ens_ProductionDocumentation", "USE"),
						$lb("Export", "%Ens_Deploy", "USE"),
						$lb("EditResource", $Piece(..#EDITRESOURCE,":"),$Piece(..#EDITRESOURCE,":",2))
						)
	
	For i=1:1:$ll(tChecks) {
		Set tCheck = $lg(tChecks, i)
		Set tArray($lg(tCheck, 1)) = $system.Security.Check($lg(tCheck, 2), $lg(tCheck, 3))
	}
	
	Do tSecurityHelper.%CopyFromArray(.tArray)
	Quit tSecurityHelper
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"DeleteConfigItem": ..#EDITRESOURCE,
				"CopyConfigItem": ..#EDITRESOURCE,
				"SaveSettingsToServer": "%Ens_ProductionConfig:WRITE,%Ens_ConfigItemRun:USE",
				"HostChangeClass": ..#EDITRESOURCE,
				: "")
}

ClassMethod %OnBeforeCreatePage() As %Status
{
	Kill %session.Data("ProdConf_Status",$NAMESPACE)
	Do ..KillModifiedSettings()
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ..hasDBPermissions(.DBPermissions, .DB)
	If $$$ISOK(tSC) {
		Set ..canEditDB = DBPermissions
		Set:DB'="" ..msgNoDBPermissions=$$$FormatText($$$Text("This action requires write privilege for the %1 database resource."),DB)
		If ..canEditDB {
			Set IsReadOnly = ..defaultMountedReadOnly(.tSC)
			If $$$ISOK(tSC) {
				If IsReadOnly {
					Set ..msgNoDBPermissions=$$$TextJS("The default database is mounted Read Only.")
					Set ..canEditDB = 0
					Set ..dbIsRO = 1
				} ElseIf ##class(Ens.Director).IsUnSupportedRemoteWorkerNamespace(.tSCSupported) {
					#; Set to Read Only to protect
					If $$$ISOK(tSCSupported) {
						Set ..msgNoDBPermissions=$$$TextJS("The production runtime data is on a remote Data node")
						Set ..canEditDB = 0
					}
				}
			}
		}
	}

	// Retrieve the preferred category
	If ..productionId'="" {
		Set ..currCategory = ..GetPreferredCategoryForProduction(..productionId, ..canEditDB)
	}

	#;Allow URL parameter to override
	If $G(^EnsPortal.Settings("All","ProductionConfig","VisualAid"))&&(..visualAid="") Set ..visualAid = ^EnsPortal.Settings("All","ProductionConfig","VisualAid")


	#; Set various source control flags
	Do ..setSourceControlFlags()

	Quit ##super()
}

/// Gray out "New" button
ClientMethod grayOutNewButton() As %Boolean [ Language = javascript ]
{
	var btn = document.getElementById('command_cmdNew');
	if (btn) {
		btn.className = 'commandButtonDisabled';
		btn.title = this.msgNoDBPermissions;
	}
	return true;
}

Method %OnDrawHTMLHead() As %Status
{
	Do %session.Unlock()
	&html<<script language="javascript">
	var hostObj = new Array(); // array of host objects - available to all client methods in the page
	var auxVarHeight = 0;
	var auxVarWidth = 0;
	</script>>
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	If ..sourceControlEnabled Set tSC = ..%DrawSourceControlHead()
	Quit tSC
}

Method CheckFileExists(pFile) As %Boolean [ ZenMethod ]
{
	Quit ##class(%File).Exists(pFile)
}

ClientMethod importFiletoExportDialog(extfile) [ Language = javascript ]
{
	var exists = zenPage.CheckFileExists(extfile);
	if (!exists) {
		alert($$$Text('File does not exist:')+' '+extfile);
	} else {
		var parms = {
			EXTFILE: extfile
		};
		zenPage.launchPopupWindow('EnsPortal.Dialog.ExportFromItem.zen',this.addPopupSuffix('ReExportItem'),'status,scrollbars,resizable=yes,width=900,height=600',parms);
	}
}

ClientMethod checkEditDB() [ Language = javascript ]
{
	if (!this.canEditDB) {
		alert(this.msgNoDBPermissions);
	}
	return this.canEditDB;
}

ClassMethod hasDBPermissions(ByRef tOK, ByRef DB As %String = "") As %Status [ ZenMethod ]
{
	Set tOK = 1, tSC = $$$OK
	// Check whether user has WRITE permissions on ^Ens.ConfigItemD and ^Ens.Config.ProductionD
	Set tRS = ##class(%Library.ResultSet).%New("%SYS.GlobalQuery:NameSpaceList")
	Set tSC = tRS.Execute($namespace,"Ens.Config.ProductionD,Ens.Config.ItemD")
	Quit:$$$ISERR(tSC) tSC
	While tRS.%Next(.tSC) {
		Quit:$$$ISERR(tSC)
		Set resource = tRS.Data("ResourceName")
		If '$system.Security.Check(resource,"WRITE") Set tOK=0, DB=resource Quit
	}
	Quit tSC
}

ClassMethod defaultMountedReadOnly(ByRef pSC As %Status) As %Boolean [ Internal, ZenMethod ]
{
	#dim tIsRO As %Integer = 0
	#dim e As %Exception.SystemException
	#dim tInfo As %String
	Set pSC = $$$OK
	Try {
		Do ##class(%SYS.Namespace).GetNSInfo($namespace,.tInfo)
		Set tIsRO = $G(tInfo("ReadOnly"),0)
		Set pSC = $G(tInfo("Status"),1)
	} Catch e {Set pSC = e.AsStatus()}
	Quit tIsRO
}

/// Used in selector component to check if can link to the page.
ClassMethod hasPermissionForLink(pResource, pPermission) As %Boolean [ Internal, ZenMethod ]
{
	Quit ''$System.Security.Check(pResource,pPermission)
}

ClientMethod tempStopItem() [ Language = javascript ]
{
	if (zenPage.productionState != 1) {
		alert($$$Text("The Production is not running."));
		return;
	}

	if (!this.checkEditDB()) return;

	/* User does not need edit permissions (!this.canEdit)) since not updating production definition */
	if (!this.checkHelper('RunItem',true)) {
		alert(this.msgNotPermitted);
		return;
	}

	var host = this.getHost();
	if (!host || host.id < 0) return false;
	if (parseInt(host.enabled)==0) {
		alert($$$Text("Selected item is disabled."));
		return;
	}
	if (host.status == 'stopped') {
		alert($$$Text("Item is already stopped."));
		return;
	}
	zenPage.stopTimers();
	zenPage.ClearUpdateErrorLog();

	var name = host.name;
	var cls = host.commentOrClassname;
	var production = zenPage.productionId;
	var fullname = (production+'||'+name+'|'+cls);
	var err = zenPage.DoTempStopOneItem(fullname,true);
	zenPage.updateProduction('update');
	if (err!="") {
		alert(err);
		zenPage.ClearUpdateErrorLog();
	}
	zenPage.startTimers(1000);
}

ClientMethod tempStartItem() [ Language = javascript ]
{
	if (zenPage.productionState != 1) {
		alert($$$Text("The Production is not running."));
		return;
	}

	if (!this.checkEditDB()) return;

	/* User does not need edit permissions (!this.canEdit)) since not updating production definition */
	if (!this.checkHelper('RunItem',true)) {
		alert(this.msgNotPermitted);
		return;
	}

	var host = this.getHost();
	if (!host || host.id < 0) return false;
	if (parseInt(host.enabled)==0) {
		alert($$$Text("Selected item is disabled."));
		return;
	}
	if (host.status != 'stopped') {
		alert($$$Text("Selected item is not stopped."));
		return;
	}
	zenPage.stopTimers();
	zenPage.ClearUpdateErrorLog();

	var name = host.name;
	var cls = host.commentOrClassname;
	var production = zenPage.productionId;
	var fullname = (production+'||'+name+'|'+cls);
	var err = zenPage.DoTempStopOneItem(fullname,false);

	zenPage.updateProduction('update');
	if (err!="") {
		alert(err);
		zenPage.ClearUpdateErrorLog();
	}
	zenPage.startTimers(1000);
}

ClientMethod tempRestartItem() [ Language = javascript ]
{

	if (!this.checkEditDB()) return;

	/* User does not need edit permissions (!this.canEdit)) since not updating production definition */
	if (!this.checkHelper('RunItem',true)) {
		alert(this.msgNotPermitted);
		return;
	}
	if ((typeof this.currItem != 'undefined') && (this.currItem > -1)) {
		this.multiItems = [];
		this.multiItems.push(this.currItem);
		zenPage.restartMultiItems();
	}
}

/// Expands and contracts the settings pane, and ensures that
/// the diagram pane is expanded to fill in the space.
ClientMethod toggleSettings() [ Language = javascript ]
{
	var propertyPanel = zen('propertyPane');
	var arrow = document.getElementById('detailExpanderArrow');
	if (this.settingsHidden) {
		arrow.innerHTML = '&#187;';
		this.settingsHidden = false;
		propertyPanel.setHidden(false);
		try {document.getElementById('detailExpanderLink').title=$$$Text("Hide Settings Tabs")} catch (ex) {}
	}
	else {
		arrow.innerHTML = '&#171;';
		this.settingsHidden = true;
		propertyPanel.setHidden(true);
		try {document.getElementById('detailExpanderLink').title=$$$Text("Show Settings Tabs")} catch (ex) {}
	}
	this.adjustSizes(true,true);
}

/// Add event to handle changing Apply button style
ClientMethod onloadHandler() [ Language = javascript ]
{
	window.addEventListener('pageModifiedSet', this.changeApplyStyle);
	return this.invokeSuper('onloadHandler');
}

/// Assumes parameter is a CustomEvent with detail properties of hostid and unappliedChanges
ClientMethod changeApplyStyle(event) [ Language = javascript ]
{
	if (!zenPage) return;
	if ((event)&&(event.detail)) {
		var button=zen('btnApply');
		if (button) {
			if (event.detail.hostid < 0) {
				if ((!zenPage.canEdit)||(!zenPage.canEditDB)) return;
				var applyText = $$$Text('Apply changes to the Production')
			} else {
				if (!((zenPage.canEdit||(zenPage.checkHelper('RunItem',true)&&(!zenPage.scReadOnly)))&&zenPage.canEditDB)) return;
				var applyText = $$$Text('Apply changes to the selected configuration item')
			}
			if (event.detail.unappliedChanges) {
				button.setProperty('title', applyText);
				button.setProperty('controlClass','commandButton');
			} else {
				button.setProperty('title',$$$Text('No changes to apply'));
				button.setProperty('controlClass','commandButtonDisabled');
			}
		}
	}
}

/// Send event that settings has applied or unapplied changes in order to modify Apply button style
ClientMethod notifypageModifiedSet(isModified, hostid) [ Language = javascript ]
{
	var event = new CustomEvent('pageModifiedSet', {'detail': {
													unappliedChanges : isModified,
													hostid: hostid
												}});
	window.dispatchEvent(event);
}

}
