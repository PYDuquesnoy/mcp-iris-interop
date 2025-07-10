/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsConstants, Ensemble)

/// This is the Queues page of the ZEN application.
Class EnsPortal.Queues Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Queues";

/// User needs READ permissions on the %Ens_Queues resource to access this page.
Parameter RESOURCE = "%Ens_Queues:READ";

/// User needs WRITE permissions on either the %Ens_Queues or the %Ens_Jobs resource
/// or USE permissions on %Ens_MessageSuspend to make changes to this page.
Parameter EDITRESOURCE = "%Ens_Queues:WRITE,%Ens_Jobs:WRITE,%Ens_MessageSuspend:USE";

Parameter ABORTRESOURCE = "%Ens_Queues:WRITE";

Parameter JOBSRESOURCE = "%Ens_Jobs:WRITE";

Parameter SUSPENDRESOURCE = "%Ens_MessageSuspend:USE";

/// Zen proxy object to help determine what actions a user may take on the page.
Property securityHelper As %ZEN.proxyObject;

Property Queue As %String(ZENURL = "QUEUE");

Property detailsHidden As %Boolean [ InitialExpression = 1 ];

Property MsgID As %String(ZENURL = "MSGID");

Property msgViewTrace As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("View Full Trace")} ];

Property queueCount As array Of %Integer;

Property selectedTable As %String;

Property selectedMessages As %String;

Property selectedActiveMessages As %String;

Property refreshRate As %Integer [ InitialExpression = 0, Internal ];

/// This Style block contains page-specific CSS style definitions.
/// yellow background:F3E9A2
XData Style
{
<style type="text/css">

#messagesTable {
	overflow: auto;
}

#activeMessageTable {
	overflow: auto;
}

#queueTable {
	overflow: auto;
}

#messagesGroup {
	overflow: auto;
}

/* styles for message details */
messagesTable.AutoFormTable {
	color: #606060;
	background: white;
	border: 1px solid black;
	padding: 0px;
	font-size: 12px;
}

messagesTable td.AutoFormTableCaption {
	font-weight: bold;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

messagesTable td.AutoFormTableValue {
	border-bottom: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

/* details pane style */
#detailsGroup {
	background-color: #EDECE4;
	padding: 10px;
	overflow-x: visible;
	overflow-y: auto;
	border-right: 1px solid gray;
}

#queueGroup {
	background-color: #EDECE4;
	padding: 10px;
	border-right: 1px solid gray;
}

#messagesGroup {
	background-color: white;
	padding: 10px;
	border-right: 1px solid gray;
}

#bodyContents {
	background-color: white;
}

.panelLabel {
	font-weight: bold;
	font-size: 16px;
	color: black;
}

</style>
}

/// Contents of the Queue page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup cellVAlign="top">
<hgroup id="queueGroup" valign="top">
<pane id="queuePanel" paneName="queuePane"/>
</hgroup>
<hgroup id="messagesGroup" hidden="true" valign="top">
<spacer width="20"/>
<pane id="messagesPanel" paneName="messagesPane" />
<spacer width="20"/>
</hgroup>
<hgroup id="detailsGroup" valign="top" hidden="true">
<pane id="detailsPanel" paneName="detailsPane" />
</hgroup>
</hgroup>
<timer id="refreshQueuesTimer" ontimeout="zenPage.refreshQueuesTimeout(zenThis);" timeout="0"/>
<timer id="refreshContentsTimer" ontimeout="zenPage.refreshContentsTimeout(zenThis);" timeout="0"/>
</pane>
}

/// This XML block defines the contents of the table pane.
XData queuePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup valign="top">
<spacer width="20" />
<vgroup valign="top">
<hgroup width="100%">
<label label="Filter:" labelStyle="font-weight:bold"/>
<text id="queueFilter" onchange="zenPage.filterChanged();" value="" size="20"/>
<spacer width="10"/>
<label label="Results:" labelStyle="font-weight:bold"/>
<label id="queueResults" labelStyle="font-weight:bold" label="0"/>
</hgroup>
<spacer height="3"/>
<tablePane id="queueTable" 
    cellSpacing="2"
	dataSource="columns"
	queryClass="EnsPortal.Queues"
	queryName="EnumerateQueues"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	sortOrder="desc"
	currColumn="Count"
	valueColumn="Name"
	onupdate="zenPage.updateQueuesTable();"
	width="auto"
	maxRows="0"
	onselectrow="zenPage.selectQueue(zenThis);">
	<parameter value=""/>
<column header="Name" colName="Name" style="text-align:left;"/>
<column header="Count" colName="Count" style="text-align:left;" OnDrawCell="DrawCountCell"/>
<column header="Active" colName="Active" title="Active Message Count" style="text-align:left;"/>
<column header="Creation Time" colName="Created" style="text-align:left;"/>
</tablePane>
</vgroup>
<spacer width="20"/>
</hgroup>
</pane>
}

/// This XML block defines the contents of the table pane.
XData messagesPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<vgroup cellAlign="center" align="center" id="allMessagesGroup" >
<group id="activeMessageGroup">
<hgroup width="100%">
<label label="Active Messages" controlStyle="nowrap" align="left" labelClass="panelLabel"/>
<group id="activeMessageOptions" hidden="true" align="right">
<hgroup>
<spacer width="15"/>
<button id="btnAbortActive" caption="Abort" controlClass="commandButton" title="Abort the selected message" onclick="zenPage.jobAbortMsg();"/>
<spacer width="15"/>
<button id="btnSuspend" caption="Suspend" controlClass="commandButton" title="Suspend the selected message" onclick="zenPage.jobSuspendMsg();"/>
</hgroup>
</group>
</hgroup>
<spacer height="5"/>
<hgroup id="activeMessageNavigator" align="center">
<tableNavigatorBar tablePaneId="activeMessageTable"/>
</hgroup>
<spacer height="2"/>
<tablePane id="activeMessageTable"
	cellSpacing="2"
	dataSource="columns"
	queryClass="EnsPortal.Queues"
	queryName="EnumerateActiveMessage"
	useSnapshot="true"
	multiSelect="true"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="ActiveMessage"
	pageSize="4"
	maxRows="0"
	onupdate="zenPage.updateActiveMessageTable(zenThis);"
	onselectrow="zenPage.selectItem(zenThis,'activeMessages');"
	onunselectrow="zenPage.hideItem();"
	onmouseoverClass="tpMouseOver">
	<parameter id="jobsTableHost" name="pHostName" value="#(..Queue)#" />
	<column colName="Job" header="Job" hidden="false" />
	<column colName="Status" header="Status" hidden="false" />
	<column colName="AdapterState" header="Adapter" hidden="false" />
	<column colName="Retry" header="Retry" hidden="false" />
	<column colName="ActiveMessage" header="Message" hidden="false"/>
</tablePane>
<spacer height="25" />
</group>

<hgroup width="100%">
<label label="Queue Contents" controlStyle="nowrap" align="left" labelClass="panelLabel"/>
<group id="messageOptions" hidden="true" align="right">
<hgroup>
<spacer width="15"/>
<button id="btnAbort" caption="Abort" controlClass="commandButton" title="Abort the selected messages" onclick="zenPage.doAbort();"/>
<spacer width="15"/>
<button id="btnAll" caption="Abort All" controlClass="commandButton" title="Abort all messages in this queue" onclick="zenPage.doAbortAll();"/>
</hgroup>
</group>
</hgroup>
<spacer height="5"/>
<hgroup id="messagesNavigator" align="center">
<tableNavigatorBar tablePaneId="messagesTable"/>
</hgroup>
<spacer height="2"/>
<tablePane id="messagesTable" 
    cellSpacing="2"
	dataSource="columns"
	queryClass="EnsPortal.Queues"
	queryName="EnumerateQueueContents"
	useSnapshot="true"
	multiSelect="true"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="MessageId"
	pageSize="40"
	onupdate="zenPage.updateQueuedMessageTable(zenThis);"
	maxRows="1000" 
	width="auto"
	onselectrow="zenPage.selectItem(zenThis,'queuedMessages');"
	onunselectrow="zenPage.hideItem();"
	onmouseoverClass="tpMouseOver">
	<parameter value="#(..Queue)#" />
	<parameter value="" />
<column header="Index" colName="Index" style="text-align:left;" />
<column header="Priority" colName="Priority" style="text-align:left;" />
<column header="Message ID" colName="MessageId" style="text-align:left;"/>
</tablePane>
</vgroup>
</pane>
}

/// This XML block defines the contents of the table pane.
XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<spacer height="10"/>
<hgroup valign="top">
<spacer width="20" />
<tabGroup id="detailsTabGroup" showTabBar="true" remember="false" onshowTab="zenPage.onTabChange();" >
<tab id="detailsContent" caption="Header" title="Message Header Details">
<spacer height="10" />
<hgroup valign="top">
<spacer width="10"/>
<html id="detailsContentHTML" OnDrawContent="DrawDetailsContent"/>
</hgroup>
<spacer height="10" />
</tab>
<tab id="bodyInfo" caption="Body" title="Message Body Details">
<spacer height="10" />
<hgroup valign="top">
<spacer width="10"/>
<html id="bodyInfoHTML" OnDrawContent="DrawBodyInfo" />
</hgroup>
<spacer height="10" />
</tab>
<tab id="bodyContents" caption="Contents" title="Message Body Contents">
<html id="fullContent" enclosingStyle="padding-top: 5px; padding-bottom: 5px;" OnDrawContent="DrawFullContentLinks" />
<spacer height="10" />
<hgroup valign="top">
<iframe id="contentFrame" frameBorder="false"/>
</hgroup>
</tab>
<tab id="traceContent" caption="Trace" title="Message Trace">
<html id="traceLink" enclosingStyle="padding: 5px;" >
<a class="ribbonSortOption" style="font-size:10pt" href="#" onclick="zenPage.showTrace(zenPage.selectedId); return false;">#(%page.msgViewTrace)#</a>
</html>
<svgFrame id="svgTrace" svgPage="EnsPortal.SVG.VisualTrace" width="200" height="300">
<parameter id="svgPAGE" paramName="PAGE" value="1" />
<parameter id="svgSESSIONID" paramName="SESSIONID" value=""/>
<parameter id="svgMSGPERPAGE" paramName="MSGPERPAGE" value="10" />
<parameter id="svgINCLUDEEVENTS" paramName="INCLUDEEVENTS" value="0" />
<parameter id="svgINCLUDEIOLOG" paramName="INCLUDEIOLOG" value="0" />
</svgFrame>
</tab>
</tabGroup>
<spacer width="5"/>
</hgroup>
</pane>
}

Method DrawCountCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	set style = "color:black"
	set title = ""
	If $get(%query("Name"))'="" {
		#;Need to escape since this array is written as part of the page.
		#dim tEscapedName = $ZCVT(%query("Name"),"O","HTML")
		if (($get(%query("Count"))'="") && ($get(%query("Count"))'="0")) {
			if (..queueCount.GetAt(tEscapedName)'="") {
				if $get(%query("Count")) > ..queueCount.GetAt(tEscapedName) {
					set style="color:red;font-weight:bold"
					set title="This count increased last time it was refreshed"
				}
				elseif $get(%query("Count")) < ..queueCount.GetAt(tEscapedName) {
					set style="color:blue"
					set title="This count decreased last time it was refreshed"
				}
				else {
					set style="color:rgb(233,87,4)"
					set title="This count did not change on the last refresh"
				}
			}
			else {
				set style="color:rgb(233,87,4)"
			}
		}
		do ..queueCount.SetAt($get(%query("Count")),tEscapedName)
	}
	&html<<div style="#(style)#" title="#(title)#">#($ZCVT($get(%query("Count")),"O","HTML"))#</div>>
	Quit $$$OK
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged() [ Language = javascript ]
{
	var value = zen('queueFilter').getValue();
	var table = zen("queueTable");
	table.setProperty('parameters',1,value);
	table.executeQuery();
}

ClientMethod updateQueuesTable() [ Language = javascript ]
{
	var table = zen("queueTable");
	zenPage.setResultsCount();
	if (table.getProperty('selectedIndex') == -1) {
		var content = zen('messagesGroup');
		content.setProperty('hidden',true);
		zenPage.hideItem();
		table.selectRow(-1);
		zenPage.MsgID = -1;
		zenPage.Queue = "";
	}
}

ClientMethod setResultsCount() [ Language = javascript ]
{
	var results = zen("queueResults");
	var table = zen("queueTable");
	var count = table.getProperty('rowCount');
	results.setProperty('label',count);
}

ClientMethod updateActiveMessageTable(active) [ Language = javascript ]
{
	if (zenPage.selectedActiveMessages != '') {zenPage.reselectActiveMessages();}
	if (active.getProperty('rowCount') == 0){
		zen('activeMessageGroup').setProperty('hidden',true);
	}
	else if (1 == active.getPageCount()) {
		zen('activeMessageGroup').setProperty('hidden',false);
		zen('activeMessageOptions').setProperty('hidden',false);
		zen('activeMessageNavigator').setProperty('hidden',true);
	}
	else {
		zen('activeMessageGroup').setProperty('hidden',false);
		zen('activeMessageOptions').setProperty('hidden',false);
		zen('activeMessageNavigator').setProperty('hidden',false);
	}
	if (active.getProperty('selectedIndex') == -1) {
		active.selectRow(-1);
		var queued = zen('messagesTable');
		if ((queued.getProperty('selectedIndex') == -1) && (!zenPage.start)) {
			zenPage.hideItem();
			zenPage.MsgID = -1;
			zenPage.selectedTable = '';
		}
	}
	zenPage.layoutMessagesGroup();
}

ClientMethod updateQueuedMessageTable(tbl) [ Language = javascript ]
{
	if (zenPage.selectedMessages != '') { zenPage.reselectMessages(); }
	if (tbl.getProperty('rowCount') == 0) {
		zen('messageOptions').setProperty('hidden',true);
		zen('messagesNavigator').setProperty('hidden',true);
	}
	else {
		zen('messageOptions').setProperty('hidden',false);
		zen('messagesNavigator').setProperty('hidden',false);
	}
	if ((tbl.getProperty('selectedIndex') == -1) && (!zenPage.start)) {
		tbl.selectRow(-1);
		var active = zen('activeMessageTable');
		if (active.getProperty('selectedIndex') == -1) {
			zenPage.hideItem();
			zenPage.MsgID = -1;
			zenPage.selectedTable = '';
		}
	}
	zenPage.layoutMessagesGroup();
}

/// Returns job status for a specific host
Query EnumerateActiveMessage(pHostName As %String) As %Query(ROWSPEC = "Name:%String,Job:%String,Status:%String,AdapterState:%String,LastActivity:%TimeStamp,Count:%Integer,Method:%String,Retry:%Integer,ActiveMessage:%String") [ SqlProc ]
{
}

ClassMethod EnumerateActiveMessageExecute(ByRef qHandle As %Binary, pHostName As %String = "") As %Status [ CodeMode = expression ]
{
##class(Ens.Util.Statistics).EnumerateJobStatusExecute(.qHandle,pHostName)
}

ClassMethod EnumerateActiveMessageFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateActiveMessageExecute ]
{
	Do {
		Set tSC = ##class(Ens.Util.Statistics).EnumerateJobStatusFetch(.qHandle,.Row,.AtEnd)
		If 'AtEnd {
			If $LG(Row,9) = "" {
				Set Row = ""
			}
		}
	}
	While (('AtEnd) && (Row=""))
	Quit tSC
}

ClassMethod EnumerateActiveMessageClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateActiveMessageExecute ]
{
##class(Ens.Util.Statistics).EnumerateJobStatusClose(.qHandle)
}

/// PriorKey is a concatenated string that consists of the Priority, "|", and the Index.
Query EnumerateQueueContents(QueueName As %String, PriorKey As %String = "") As %Query(ROWSPEC = "Priority:%String,Index:%Integer,MessageId:%String") [ SqlProc ]
{
}

ClassMethod EnumerateQueueContentsExecute(ByRef qHandle As %Binary, pQueueName As %String, pPriorKey As %String = "") As %Status [ CodeMode = expression ]
{
##class(Ens.Queue).EnumerateItemExecute(.qHandle,pQueueName,pPriorKey)
}

ClassMethod EnumerateQueueContentsClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateQueueContentsExecute ]
{
##class(Ens.Queue).EnumerateItemClose(.qHandle)
}

ClassMethod EnumerateQueueContentsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateQueueContentsExecute ]
{
	Set tSC = ##class(Ens.Queue).EnumerateItemFetch(.qHandle,.Row,.AtEnd)
	Set:'AtEnd $List(Row) = ..MessagePriorityToText($LG(Row))
	Quit tSC
}

/// List the known queues and their current counters
Query EnumerateQueues(Filter As %String = "") As %Query(ROWSPEC = "Name:%String,Count:%Integer,Created:%String,Active:%String") [ SqlProc ]
{
}

ClassMethod EnumerateQueuesExecute(ByRef qHandle As %Binary, pFilter As %String = "") As %Status
{
	Set tSC = ##class(Ens.Queue).EnumerateExecute(.qHandle)
	Set qHandle("Filter") = pFilter
	Quit tSC
}

ClassMethod EnumerateQueuesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateQueuesExecute ]
{
##class(Ens.Queue).EnumerateClose(.qHandle)
}

ClassMethod EnumerateQueuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateQueuesExecute ]
{
	Set Filter = qHandle("Filter")
	Do {	
		Set tSC = ##class(Ens.Queue).EnumerateFetch(.qHandle,.Row,.AtEnd)
		If 'AtEnd {
			If Filter'="" {
	 			Set StringRow = $listtostring(Row,$C(13))
	 			If $zcvt(StringRow,"L")'[$zcvt(Filter,"L") {
		 			Set Row = ""
	 			}
			}
		}
	}
	While(('AtEnd) && (Row=""))
	If 'AtEnd {
		If $$$queueIsNotSyncQueue($LG(Row)) {
			Set tHost = $LG(Row)
			Set job = ""
			Set Active = 0
			For {
				Set job=$$$OrderHostMonitor(tHost,$$$eMonitorJob,job)
				Quit:job=""
				Set:$g($$$EnsActiveMessage(job))'="" Active = $I(Active)
			}
			Set $List(Row,4) = Active
		}
		Else {
			Set $List(Row,4) = "-"
		}

	 }
	Quit tSC
}

/// API to convert the numeric message priority value in <var>pPriority</var> into the corresponding text string.
ClassMethod MessagePriorityToText(pPriority As %Integer = "") As %String
{
	Quit $case(pPriority
		,$$$eMessagePriorityHighSync:			$$$Text("HighSync","Ensemble","en")
		,$$$eMessagePrioritySync:			$$$Text("Sync","Ensemble","en")
		,$$$eMessagePrioritySimSync:			$$$Text("SimSync","Ensemble","en")
		,$$$eMessagePriorityAsync :			$$$Text("Async","Ensemble","en")
		,	:$$$FormatText($$$Text("%1","Ensemble","en"),pPriority))
}

/// If auto-refresh is still on, refresh queues table and restart the timer
ClientMethod refreshQueuesTimeout(timer) [ Language = javascript ]
{
	var val = 'None';
	if (zenPage.enableAutoRefresh) {
		var refreshQueueEl = document.getElementById('chkRefreshQueues');
		if (refreshQueueEl) {
			val = refreshQueueEl.value;
		}
	}
	if (val!="None") { // There is a non-zero timer value
		// synchronous mode should hopefully prevent the page from reselecting the old row when user selects a new row at same time as the auto-refresh
		var old = zenSynchronousMode;
		zenSynchronousMode = true;
		zen('queueTable').executeQuery();
		zenSynchronousMode = old;
		timer.startTimer(); // restart timer
	}
}

/// If auto-refresh is still on, refresh active messages and queue contents tables and restart the timer
ClientMethod refreshContentsTimeout(timer) [ Language = javascript ]
{
	var val = 'None';
	if (zenPage.enableAutoRefresh) {
		var refreshContentsEl = document.getElementById('chkRefreshContents');
		if (refreshContentsEl) {
			val = refreshContentsEl.value;
		}
	}
	if (val!="None") { // There is a non-zero timer value
		if (!zen('messagesGroup').getProperty('hidden')) {
			zenPage.selectedMessages = zen('messagesTable').selectedRows;
			// synchronous mode should hopefully prevent the page from reselecting the old row when user selects a new row at same time as the auto-refresh
			var old = zenSynchronousMode;
			zenSynchronousMode = true;
			zen('messagesTable').executeQuery(true);
			zenSynchronousMode = old;
			zenPage.selectedActiveMessages = zen('activeMessageTable').selectedRows;
			// synchronous mode again
			zenSynchronousMode = true;
			zen('activeMessageTable').executeQuery(true);
			zenSynchronousMode = old;
		}
		timer.startTimer(); // restart timer
	}
}

/// User chose a new Auto-Refresh value for queues table; set a new timeout value and start the timer
ClientMethod changeRefreshQueues() [ Language = javascript ]
{
	var val = document.getElementById('chkRefreshQueues').value;
	if (zenPage.enableAutoRefresh) {
		var contents = document.getElementById('chkRefreshContents').value;
		if (contents == "None") { contents = 0; }

		if (val == "None") { // Don't start the timer and it will just sit there
			zenPage.refreshRate = contents/1000;
		} else { // There is a non-zero timer value
			var timer = zen('refreshQueuesTimer'); //get timer
			timer.setProperty('timeout',val); //set timeout
			timer.startTimer(); //restart timer

 			if (contents == 0) {
				zenPage.refreshRate = val/1000;
			} else {
				zenPage.refreshRate = Math.min(val,contents)/1000;
			}
		}
	}
}

/// User chose a new Auto-Refresh value for active messages and queue contents tables; set a new timeout value and start the timer
ClientMethod changeRefreshContents() [ Language = javascript ]
{
	var val = document.getElementById('chkRefreshContents').value;
	if (zenPage.enableAutoRefresh) {
		var queues = document.getElementById('chkRefreshQueues').value;
		if (queues == "None") { queues = 0; }

		if (val == "None") { // Don't start the timer and it will just sit there
			zenPage.refreshRate = queues/1000;
		} else  { // There is a non-zero timer value
			var timer = zen('refreshContentsTimer'); //get timer
			timer.setProperty('timeout',val); //set timeout
			timer.startTimer(); //restart timer

			if (queues == 0) {
				zenPage.refreshRate = val/1000;
			} else {
				zenPage.refreshRate = Math.min(val,queues)/1000;
			}
		}
	}
}

ClientMethod refreshMessages() [ Language = javascript ]
{
	zenPage.selectedMessages = zen('messagesTable').selectedRows;
	zen('messagesTable').executeQuery(true);
	zenPage.selectedActiveMessages = zen('activeMessageTable').selectedRows;
	zen('activeMessageTable').executeQuery(true);
	document.getElementById('refreshAll').style.backgroundColor = ''; // in case the diagram was reloading, clear the background
}

/// show contentTable for a selected queue
ClientMethod selectQueue(row) [ Language = javascript ]
{
	if ((typeof row == 'object') && (zenPage.Queue!=row.getValue())) { // got passed the tablePane object
		zenPage.Queue = row.getValue();
		zenPage.MsgID = -1;
		zen('messagesTable').selectRow(-1);
		zen('activeMessageTable').selectRow(-1);
		zenPage.hideItem();
		zenPage.showContentTables();
	}
}

/// called from selectQueue and %onAfterCreatePage
ClientMethod showContentTables() [ Language = javascript ]
{
	zen('messagesGroup').setProperty('hidden',false);
	var tab = zen('messagesTable');
	var active = zen('activeMessageTable');
	zen('jobsTableHost').value = zenPage.Queue;
	tab.setProperty('parameters',1,zenPage.Queue);
	zenPage.selectedActiveMessages = active.getProperty('selectedRows');
	active.executeQuery();
	zenPage.selectedMessages = tab.getProperty('selectedRows');
	tab.executeQuery();
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Queues","Ensemble")
}

/// Adjust sizes of components on the page.
/// The primary purposes of this function are to ensure that the details pane
/// is sized correctly based on whether the tab group is hidden, and to
/// correctly update the expander text and the contents of the tab group.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		var queuesPanel = zen('queueGroup');
		var queuesDiv = queuesPanel.getEnclosingDiv();
		var contentsPanel = zen('messagesGroup');
		var contentsDiv = contentsPanel.getEnclosingDiv();
		var detailsPanel = zen('detailsGroup');
		var detailsDiv = detailsPanel.getEnclosingDiv();
		var queuesTable = zen('queueTable').getEnclosingDiv();
		var messagesTable = zen('messagesTable').getEnclosingDiv();
		var messagesPane = zen('allMessagesGroup').getEnclosingDiv();
		
		var winHeight = zenGetWindowHeight();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 20;
		
		if (!(((zenBody.scrollWidth) == (zenBody.offsetWidth)) && (zenBody.scrollLeft == 0))) {
			hgt = hgt - 15 - 3*(zenIsIE||zenIsGecko);
		}
		
		queuesDiv.style.height = hgt + 'px';
		contentsDiv.style.height = hgt + 'px';
		detailsDiv.style.height = hgt + 'px';
		
		queuesTable.style.height = (hgt - 25) + 'px';
		if (!(((queuesTable.scrollHeight) == (queuesTable.offsetHeight)) && (queuesTable.scrollTop == 0))) {
			queuesDiv.style.width = (document.getElementById('queueTable').offsetWidth + 10*(!zenIsGecko) + 40) + 'px';	
		}
			
		this.layoutMessagesGroup();
		
		messagesPane.style.height = (hgt + (7*zenIsGecko)) + 'px';
		if ((zenIsGecko) && (!(((messagesPane.scrollHeight) == (messagesPane.offsetHeight)) && (messagesPane.scrollTop == 0)))) {
			var msgWidth = (document.getElementById('messagesTable').offsetWidth > document.getElementById('activeMessageTable').offsetWidth)?document.getElementById('messagesTable').offsetWidth: document.getElementById('activeMessageTable').offsetWidth;
			contentsDiv.style.width = (msgWidth + 50) + 'px';
		}
		this.layoutTabGroup();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

/// Layout the Message Panel so that the contents table has a scrollbar if necessary, until the page is so small
/// that it makes more sense for the entire panel to have a scroll bar.  Then get rid of the scrollbar on the
/// contents table in order to avoid double scrollbars. 
ClientMethod layoutMessagesGroup() [ Language = javascript ]
{
	try {
		var contentsPanel = zen('messagesGroup');
		var contentsDiv = contentsPanel.getEnclosingDiv();		
		if (document.getElementById('messagesTable').offsetWidth < 309) {
			contentsDiv.style.width = 355 + 10*(!zenIsGecko) + 'px';
		}

		var winHeight = zenGetWindowHeight();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 25 - 5*zenIsIE;
		
		if (!(((zenBody.scrollWidth) == (zenBody.offsetWidth)) && (zenBody.scrollLeft == 0))) {
			hgt = hgt - 15;
		}

		var messagesTable = zen('messagesTable').getEnclosingDiv();
		var msgHgt = hgt - 50 + (12*zenIsIE);
		switch (zen('activeMessageTable').getProperty('rowCount')) {
			case '0': break;
			case '1': msgHgt -= 125; break;
			case '2': msgHgt -= (150 + 2*zenIsIE); break;
			case '3': msgHgt -= 175; break;
			case '4': msgHgt -= (200 + 5*zenIsIE); break;
			default : msgHgt -= 222; break;
		}
		
		if ((msgHgt < 138) && (parseInt(zen('messagesTable').getProperty('rowCount'),10) != 0)) {
			var rows = Math.min(((parseInt(zen('messagesTable').getProperty('rowCount'),10))-(zen('messagesTable').getProperty('pageSize')*(zen('messagesTable').getProperty('currPage')-1))),zen('messagesTable').getProperty('pageSize'));
			msgHgt =  40 + (4*!zenIsGecko) + ((26.2-(.5*!zenIsGecko)) * rows);
		}
		else if (msgHgt < 138) {
			msgHgt = 65;
		}
				 
		messagesTable.style.height = msgHgt + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

/// Handle the client-side rendering the of the right hand pane.
ClientMethod layoutTabGroup() [ Language = javascript ]
{
/// This is primarily due to IE as it shrinks the contents div without this intervention.
/// The function only adjusts the size of the tab group is not hidden.
	if (!this.detailsHidden) {
		var detailsTabGroup = zen('detailsTabGroup');
		var tabsDiv = detailsTabGroup.getEnclosingDiv();
		var contentLinkDiv = zen('fullContent').getEnclosingDiv();
		var frame = zen('contentFrame');
		var svgTrace = zen('svgTrace');
	
		var winHeight = zenGetWindowHeight();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 25 - 5*zenIsIE;
		
		if (!(((zenBody.scrollWidth) == (zenBody.offsetWidth)) && (zenBody.scrollLeft == 0))) {
			hgt = hgt - 15;
		}

		tabsDiv.style.height = hgt + 'px';
		var tabBar = detailsTabGroup.getTabBarElement();
		hgt = hgt - tabBar.offsetHeight;
		var bodyHeight = hgt - 10 - 8*((!zenIsGecko) && (!zenIsIE)) ;
		frame.setProperty('height',(bodyHeight-15 - contentLinkDiv.offsetHeight) + 'px');
		tabsDiv.style.height = hgt + 'px';
		
		// prevent IE resize logic
		detailsTabGroup.ieResizeBody = function() { return; };
		
		var tabsWidth = 650; // there is no containing pane, so set the width as desired
		if (zenIsIE) { // ensure that the entire group is kept wide enough
			var groupDiv = zen('detailsGroup').getEnclosingDiv();
			if (groupDiv) {
				groupDiv.style.width = (tabsWidth+15) + 'px';
				tabsWidth -= 10;
			}
		}
		detailsTabGroup.setBodySize(bodyHeight, tabsWidth);
		tabsDiv.style.width = tabsWidth + 'px';
		
		var frameWidth = (tabsWidth - 5) - (!zenIsGecko * 5) - (zenIsHTML5 * 15); // IE and Chrome introduce scrollbars with the extra 5px
		frame.setProperty('width', frameWidth+ 'px');
		
		var traceLinkDiv = zen('traceLink').getEnclosingDiv();
		var svgHeight = bodyHeight - 5 - traceLinkDiv.offsetHeight;
		var svgWidth = tabsWidth - 25;
		// IE doesn't load the SVG fast enough, so the size can only be adjusted 
		// after the SVG is loaded, so this is triggered via onTraceSVGLoad()-->scaleSVGTrace()
		if (zenIsIE != 1) {
			svgTrace.setProperty('width', svgWidth + 'px');
			svgTrace.setProperty('height',svgHeight + 'px');
		}
		else {
			zenPage._traceSVGHeight = svgHeight;
			zenPage._traceSVGWidth = svgWidth;
		}
	}
}

/// Callback from the Trace SVG onSVGLoad() callback.
/// The callback is used to ensure that we have the loaded SVG diagram available 
/// before we attempt to resize the diagram or highlight the currently selected message.
ClientMethod onTraceSVGLoad() [ Language = javascript ]
{
	zenPage.scaleSVGTrace();
	
	if (zenPage.selectedTable == "queuedMessages") selectedId = zen('messagesTable').getValue();
	else if (zenPage.selectedTable == "activeMessages") selectedId = zen('activeMessageTable').getValue();
	else return;
	if (selectedId.toString().indexOf('_') != -1) selectedId = selectedId.split('_').pop();
	if (selectedId > 0) {
		var svgTrace = zen('svgTrace');
		if (svgTrace && svgTrace.svgWindow && svgTrace.svgWindow.svgPage && svgTrace.svgWindow.svgPage.selectItem) {
			var svgDoc = svgTrace.getSVGDocument();
			if (svgDoc) {
				var svgObj = svgDoc.getElementById(selectedId);
				var lineId = '';
				var rectId = '';
				if (svgObj) {
					lineId = svgObj.getAttribute('lineId');
					rectId = svgObj.getAttribute('rectId');
				}
				svgTrace.svgWindow.svgPage.selectItem(null,'message',rectId,selectedId,'',lineId);
			}
		}
	}
}

/// Correctly resize the SVG trace diagram to fit into the current SVG frame size.
ClientMethod scaleSVGTrace() [ Language = javascript ]
{
	var svgTrace = zen('svgTrace');
	// If we are on IE, we have to resize the frame once we know it's already loaded
	if (zenPage._traceSVGWidth) {
		svgTrace.setProperty('width', zenPage._traceSVGWidth + 'px');
	}
	if (zenPage._traceSVGHeight) {
		svgTrace.setProperty('height', zenPage._traceSVGHeight + 'px');
	}

	var svgDoc = svgTrace.getSVGDocument();
	if (svgDoc) {
		var svgCanvas = svgDoc.getElementById('traceCanvas');
		if (svgCanvas) {
			var svgHeight = svgCanvas.getAttribute('height');
			var svgWidth = svgCanvas.getAttribute('width');
			if ((svgHeight > svgTrace.height) || (svgWidth > svgTrace.width)) {
				var sync = svgTrace.svgRoot.setAttribute('viewBox', '0 0 '+ svgWidth + ' ' + svgHeight);
				sync = svgTrace.svgRoot.setAttribute('preserveAspectRatio', 'xMinYMin meet');
			}
		}
	}
	return true;
}

/// User clicked a link for Trace. Display the Visual Trace page.
ClientMethod showTrace(row) [ Language = javascript ]
{
	if (row != -1) {
		var URI = zenLink('EnsPortal.VisualTrace.zen?SESSIONID='+row);
		window.open(URI);
	}
}

/// Show the full content of the current message in a new window or tab.
ClientMethod showFullContent(showRaw, showJSON) [ Language = javascript ]
{
	if (this.selectedId != -1) {
		window.open(zenLink('EnsPortal.MessageContents.zen?HeaderClass=Ens.MessageHeader&HeaderId='+this.selectedId+(showJSON ? '&FORMAT=JSON' :(showRaw ? '&RAW=1' : ''))));
	}
}

/// User clicked on a tab, or selected a new item, so we need to fetch the 
/// required content from the server.
ClientMethod onTabChange() [ Language = javascript ]
{
	// Don't get data from server if data isn't visible
	// It will be retrieved when the tabs are redisplayed
	if (!this.detailsHidden) {
		this.layoutTabGroup();
		if (zenPage.selectedTable == "queuedMessages") this.selectedId = zen('messagesTable').getValue();
		else if (zenPage.selectedTable == "activeMessages") this.selectedId = zen('activeMessageTable').getValue();
		else return;
		if (this.selectedId.toString().indexOf('_') != -1) this.selectedId = this.selectedId.split('_').pop();
		if (this.selectedId != '') {
			var tabGroup = zen('detailsTabGroup');
			var currTab = tabGroup.getCurrTabNo();
			if (!this._tabDisplay) {
				this._tabDisplay = new Object();
			}
			switch (currTab) {
				case 1:
					if (this._tabDisplay['Header'] != this.selectedId) {
						this.drawDetails(this.selectedId);
						this._tabDisplay['Header'] = this.selectedId;
					}
					break;
				case 2:
					if (this._tabDisplay['Body'] != this.selectedId) {
						var bodyInfo = zen('bodyInfoHTML');
						bodyInfo.seed = (this.selectedId == -1 ? '' : this.selectedId);
						bodyInfo.refreshContents();
						this._tabDisplay['Body'] = this.selectedId;
					}
					break;
				case 3:
					if (this._tabDisplay['Contents'] != this.selectedId) {
						var frame = zen('contentFrame');
						if (this.selectedId == -1) {
							frame.setProperty('src', '');
						}
						else {
							frame.setProperty('src', zenLink('EnsPortal.MessageContents.zen?HeaderClass=Ens.MessageHeader&HeaderId='+this.selectedId));
						}
						this._tabDisplay['Contents'] = this.selectedId;
					}
					break;
				case 4:
					if (this._tabDisplay['Trace'] != this.selectedId) {
						var svgTrace = zen('svgTrace');
						var svgSession = zen('svgSESSIONID');
						svgSession.value = this.selectedId;
						var sync = svgTrace.refreshContents(true);
					}
					break;
				default:
					break;
			}
		}
	}
}

/// Update the details for a selected message.
ClientMethod drawDetails(messageId) [ Language = javascript ]
{
	var details = zen('detailsContentHTML');
	if ((messageId == -1) || (messageId == null)) {
		details.seed = '';
	}
	else {
		details.seed = messageId;
	}
	details.refreshContents(true);
}

/// Write out contents of details panel.
/// <var>pID</var> is the message id.
Method DrawDetailsContent(pID As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawItemDetails(pID)
}

/// Write out contents of body details panel.
/// <var>pHeaderID</var> is the message id.
Method DrawBodyInfo(pHeaderID As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawBodyInfo(pHeaderID)
}

/// Write out the links to show the full contents of a message.
ClassMethod DrawFullContentLinks(pSeed As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawFullContentLinks()
}

/// Update the details for the selected message
ClientMethod showItem(msgId) [ Language = javascript ]
{
	var frame = zen('detailsGroup');
	frame.setHidden(0);
	zenPage.detailsHidden = false;
	this.onTabChange();
	zenPage.onlayoutHandler();
	zenPage.MsgID = msgId;
}

/// clear selected row from other message table & show detailTable for a selected task
ClientMethod selectItem(row, table) [ Language = javascript ]
{
	if ((row.getValue()) && (typeof row == 'object')) { // got passed the tablePane object
		if (!((zenPage.MsgID==row.getValue()) && (zenPage.selectedTable == table))) {
			if (table=='activeMessages') zen("messagesTable").setProperty('selectedIndex',-1);
			else if (table=='queuedMessages') zen("activeMessageTable").setProperty('selectedIndex',-1);
			zenPage.selectedTable = table;
			zenPage.showItem(row.getValue());
		}
	}
}

/// hide detailTable
ClientMethod hideItem() [ Language = javascript ]
{
	var frame = zen('detailsGroup');
	frame.setHidden(1);
	zenPage.detailsHidden = true;
	zenPage.onlayoutHandler();
	zenPage.MsgID = -1;
	zenPage.selectedTable = '';
}

/// reselected messages that were selected prior to the table being refreshed
ClientMethod reselectActiveMessages() [ Language = javascript ]
{
	var tab = zen('activeMessageTable');
	var len = tab.getProperty('pageSize');
	var sel = zenPage.selectedActiveMessages;
	for (i=0; i<len; i++) {
		if ((typeof(document.getElementById('activeMessageTable').firstChild.rows[i+1]) != "undefined") && (typeof(document.getElementById('activeMessageTable').firstChild.rows[i+1].cells[4]) != "undefined")) {
			var v = document.getElementById('activeMessageTable').firstChild.rows[i+1].cells[6].innerHTML;
			v = v.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
			v = v.replace(/<.*>/g,""); // for IE compatibility, remove <span> inside cell
			var index = sel.indexOf(v);
			if (index != -1) {
				if (sel.substring(index-1,index+v.length+1).replace(/,/g,"") == v) {
					tab.selectMultiRow(i,true);
				}
			}
		}
		else break;
	}
}

/// reselected messages that were selected prior to the table being refreshed
ClientMethod reselectMessages() [ Language = javascript ]
{
	var tab = zen('messagesTable');
	var len = tab.getProperty('pageSize');
	var sel = zenPage.selectedMessages;
	for (i=0; i<len; i++) {
		if ((typeof(document.getElementById('messagesTable').firstChild.rows[i+1]) != "undefined") && (typeof(document.getElementById('messagesTable').firstChild.rows[i+1].cells[4]) != "undefined")) {
			var v = document.getElementById('messagesTable').firstChild.rows[i+1].cells[4].innerHTML;
			v = v.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
			v = v.replace(/<.*>/g,""); // for IE compatibility, remove <span> inside cell
			var index = sel.indexOf(v);
			if (index != -1) {
				if (sel.substring(index-1,index+v.length+1).replace(/,/g,"") == v) {
					tab.selectMultiRow(i,true);
				}
			}
		}
		else break;
	}
}

ClientMethod jobAbortMsg() [ Language = javascript ]
{
	if (!this.checkHelper('AbortJobMsg')) {
		return false;
	}

	zenPage.hideItem();	
	var tab = zen('activeMessageTable');
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	var row = 0;
	tab.selectAllMultiRows(false);
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) {
				val += ',';
			}
			// switch to the page that the message is on and identify its row number, so that we get the correct job value
			// use synchronous mode temporarily because it doesn't switch pages fast enough to get the correct job value otherwise
			var old = zenSynchronousMode;
			zenSynchronousMode = true;
			var page = ((i-(i%tab.getProperty('pageSize')))/tab.getProperty('pageSize')) + 1;
			if (page != tab.getProperty('currPage')) {
				tab.setProperty('currPage', page);
				tab.selectAllMultiRows(false);
			}
			row = i%tab.getProperty('pageSize') + 1;
			zenSynchronousMode = old;
			// get the job value from the table contents; our <table> is the first child inside a <div> called 'table', +1 for the header row
			var v = document.getElementById('activeMessageTable').firstChild.rows[row].cells[2].innerHTML; 
			v = v.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
			v = v.replace(/<.*>/g,""); // for IE compatibility, remove <span> inside cell
			val += v;
			
			// note that we found one
			found++;
		}
	}
			
	if (found == 0) alert($$$Text('No active messages selected'));
	else {
		if (confirm($$$Text("Are you sure you wish to abort the selected active messages?"))) {
			var msg = "";
			jobs = val.split(',');
			for (i=0; i<found; i++)
			{
				var tMsg = zenPage.AbortJobMsg(jobs[i]);
				if (tMsg!='') {
					msg= msg + '\n' + tMsg;
				}
			}
			if ('' == msg) {
				if (found ==1) {
					alert($$$Text("The selected active message has been aborted"));
				}
				else {
					alert($$$Text("The selected active messages have been aborted"));
				}
			} else {
				alert($$$FormatText($$$Text("Error aborting active messages: %1"),msg));
			}
			// update the table
			tab.selectRow(-1);
			zenPage.MsgID = -1;
			zenPage.selectedTable='';
			zenPage.selectedActiveMessages = '';
			tab.executeQuery();

		}
	}
}

ClassMethod AbortJobMsg(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).AbortOperation(pJob)	
	Quit:$$$ISERR(tSC) "Message abort failed for job "_pJob_": "_$$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod jobSuspendMsg() [ Language = javascript ]
{
	if (!this.checkHelper('SuspendJobMsg')) {
		return false;
	}

	zenPage.hideItem();
	
	var tab = zen('activeMessageTable');
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	var row = 0;
	tab.selectAllMultiRows(false);
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) {
				val += ',';
			}
			// switch to the page that the message is on and identify its row number, so that we get the correct job value
			// use synchronous mode temporarily because it doesn't switch pages fast enough to get the correct job value otherwise
			var old = zenSynchronousMode;
			zenSynchronousMode = true;
			var page = ((i-(i%tab.getProperty('pageSize')))/tab.getProperty('pageSize')) + 1;
			if (page != tab.getProperty('currPage')) {
				tab.setProperty('currPage', page);
				tab.selectAllMultiRows(false);
			}
			row = i%tab.getProperty('pageSize') + 1;
			zenSynchronousMode = old;
			// get the job value from the table contents; our <table> is the first child inside a <div> called 'table', +1 for the header row
			var v = document.getElementById('activeMessageTable').firstChild.rows[row].cells[2].innerHTML; 
			v = v.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
			v = v.replace(/<.*>/g,""); // for IE compatibility, remove <span> inside cell
			val += v;
			
			// note that we found one
			found++;
		}
	}
			
	if (found == 0) alert($$$Text('No active messages selected'));
	else {
		if (confirm($$$Text("Are you sure you wish to suspend the selected active messages?"))) {
			var msg = "";
			jobs = val.split(',');
			for (i=0; i<found; i++)
			{
				var tMsg = zenPage.SuspendJobMsg(jobs[i]);
				if (tMsg!=''){
					msg= msg + '\n'+ tMsg;
				}
			}
			if ('' == msg) {
				if (found ==1) {
					alert($$$Text("The selected active message has been suspended"));
				}
				else {
					alert($$$Text("The selected active messages have been suspended"));
				}
			} else {
				alert($$$FormatText($$$Text("Error suspending active messages: %1"),msg));
			}
			// update the table
			tab.selectRow(-1);
			zenPage.MsgID = -1;
			zenPage.selectedTable='';
			zenPage.selectedActiveMessages = '';
			tab.executeQuery();
		}
	}
}

ClassMethod SuspendJobMsg(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).SuspendOperation(pJob)
	Quit:$$$ISERR(tSC) "Message suspend failed for job "_pJob_": "_$$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod doAbort() [ Language = javascript ]
{
	if (!this.checkHelper('AbortMessage')) {
		return false;
	}

	zenPage.hideItem();
		
	// Get the values and find out how many
	var tab = zen('messagesTable');
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	var row = 0;
	var priority = "";
	tab.selectAllMultiRows(false);
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) {
				val += ',';
				priority += ',';
			}
			// switch to the page that the message is on and identify its row number, so that we get the correct index and priority values
			// use synchronous mode temporarily because it doesn't switch pages fast enough to get the correct index and priority values otherwise
			var old = zenSynchronousMode;
			zenSynchronousMode = true;
			var page = ((i-(i%tab.getProperty('pageSize')))/tab.getProperty('pageSize')) + 1;
			if (page != tab.getProperty('currPage')) {
				tab.setProperty('currPage', page);
				// deselect all rows on the current page
				tab.selectAllMultiRows(false);
			}
			row = i%tab.getProperty('pageSize') + 1;
			zenSynchronousMode = old;
			
			// get the index value from the table contents; our <table> is the first child inside a <div> called 'table', +1 for the header row
			var v = document.getElementById('messagesTable').firstChild.rows[row].cells[2].innerHTML; 
			v = v.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
			v = v.replace(/<.*>/g,""); // for IE compatibility, remove <span> inside cell
			val += v;
			// get the priority value from the table contents; our <table> is the first child inside a <div> called 'table', +1 for the header row
			var pri = document.getElementById('messagesTable').firstChild.rows[row].cells[3].innerHTML; 
			pri = pri.replace(/<\/[Ss][Pp][Aa][Nn]>/g,""); // for IE compatibility, remove </span> inside cell
			pri = pri.replace(/<.*>/g,""); // for IE compatibility, remove <span> inside cell
			priority += pri;
			// note that we found one
			found++;
		}
	}
	// Use the values
	if (found == 0) alert($$$Text('Please select one or more messages to abort.'));
	else {
		if (confirm($$$Text('Are you sure you want to abort the selected messages?'))) {
			var ret = "";
			pri = priority.split(',');
			sel = val.split(',');
			for (i=0; i<found; i++) {
				var tMsg = zenPage.AbortMessage(sel[i],pri[i],zenPage.Queue);
				if (tMsg!='') {
					ret = ret + '\n' + tMsg;
				}
			}
			if (ret == "") {
				if (found == 1) alert($$$Text('The selected message has been aborted.'));
				else if (found > 1) alert($$$Text('The selected messages have been aborted.'));
			}
			else {
				alert($$$FormatText($$$Text("Error aborting messages: %1"),ret));
			}
			
			// update the table
			tab.selectRow(-1);
			zenPage.MsgID = -1;
			zenPage.selectedTable='';
			zenPage.selectedMessages = '';
			zenPage.refreshAll();

		}
	}
	zenPage.hideItem();
}

Method AbortMessage(pIndex As %String, pPriority As %Integer, pQueueName As %String) As %String [ ZenMethod ]
{
	Set pPriority = $case(pPriority
		,"HighSync" : $$$eMessagePriorityHighSync
		,"Sync" : $$$eMessagePrioritySync
		,"SimSync" : $$$eMessagePrioritySimSync
		,"Async" : $$$eMessagePriorityAsync
		, : pPriority )
	Set tSC = ##class(Ens.Queue).AbortItem(pQueueName,pPriority,pIndex)
	If $$$ISOK(tSC) {
		Set tMsg = ""
	} Else {
		Set tMsg = "Abort failed for message with index "_pIndex_": "_$$$StatusDisplayString(tSC)
	}
	Quit tMsg
}

ClientMethod doAbortAll() [ Language = javascript ]
{
	if (!this.checkHelper('AbortAllMessages')) {
		return false;
	}

	zenPage.hideItem();

	var tab = zen('messagesTable')
	var confirmQuestion = $$$FormatText($$$Text("Are you sure you want to abort all %1 messages in queue %2?"),zenPage.GetQueueCount(zenPage.Queue),zenPage.Queue)
	if (zenPage.GetQueueCount(zenPage.Queue) > 1000) {
		confirmQuestion=confirmQuestion+". "+$$$Text("Due to the size of the queue the abort process could take longer than the page timeout.")
	}
	if (confirm(confirmQuestion)) {
		var ret = zenPage.AbortAllMessages(zenPage.Queue);
		if (ret == "") {
			alert($$$Text('The contents of this queue have been aborted.'));
		}
		else {
			alert($$$FormatText($$$Text("Abort of queue %1 failed: %2"),zenPage.Queue,ret));
		}
		// update table
		tab.selectRow(-1);
		zenPage.MsgID = -1;
		zenPage.selectedTable = "";
		zenPage.selectedMessages = '';
		zenPage.refreshAll();

	}
	zenPage.hideItem();
}

Method AbortAllMessages(pQueueName As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Queue).AbortQueue(pQueueName)
	If $$$ISOK(tSC) {
		Set tMsg = ""
	} Else {
		Set tMsg = $$$StatusDisplayString(tSC)
	}
	Quit tMsg
}

/// Get Queue Count for Business Hosts with Queue Count larger than rowCount
ClassMethod GetQueueCount(pQueueName As %String) As %Integer [ ZenMethod ]
{
	Quit:pQueueName="" ""
	Quit ##class(Ens.Queue).GetCount(pQueueName)
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set pLink(2)=$LB($$$Text("Queues","Ensemble"),"#") 
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = ..%OnGetPageName()
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	&html<
	<td style="padding-left:20px;width:80px;">
	<span id="refreshAll" style="font-size:14px;font-weight:bold;color:#404040">#($$$TextHTML("Refresh:"))#</span>
	</td>
	<td style="padding-left:6px;width:30px;">
	<image src="deepsee/loop_24.gif" style="position:relative;top:4px" class="icon" title="Refresh All Tables" onclick="zenPage.refreshAll();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
	</td>>
	if ..enableAutoRefresh {
		&html<
		<td nowrap style="padding-left:40px;width:137px;"><span style="font-size:14px;font-weight:bold;color:#404040">#($$$TextHTML("Auto-Refresh:"))#</span></td>
		<td style="padding-left:20px;width:120px;">
		<div>
			<span nowrap style="font-size:12px;font-weight:bold;color:#404040">#($$$TextHTML("Queues Table"))#</span>
			<select name="Auto-Refresh Queues" id="chkRefreshQueues" label="Queues Table" onchange="zenPage.changeRefreshQueues();" title="Frequency with which to auto-refresh the queues table">
				<option value="None">None</option>
				<option value="1000">1 Second</option>
				<option value="5000">5 Seconds</option>
				<option value="10000">10 Seconds</option>
				<option value="30000">30 Seconds</option>
				<option value="60000">60 Seconds</option>
				<option value="120000">2 Minutes</option>
				<option value="300000">5 Minutes</option>
			</select>
		</div>
		</td>
		<td style="padding-left:20px;width:120px;">
		<div>
			<span nowrap style="font-size:12px;font-weight:bold;color:#404040">#($$$TextHTML("Contents Tables"))#</span>
			<select name="Auto-Refresh Contents" id="chkRefreshContents" onchange="zenPage.changeRefreshContents();" title="Frequency with which to auto-refresh the active messages and queue contents tables">
				<option value="None">None</option>
				<option value="1000">1 Second</option>
				<option value="5000">5 Seconds</option>
				<option value="10000">10 Seconds</option>
				<option value="30000">30 Seconds</option>
				<option value="60000">60 Seconds</option>
				<option value="120000">2 Minutes</option>
				<option value="300000">5 Minutes</option>
			</select>
		</div>
		</td>
		<td style="padding-left:20px;"></td>
		>
	}
	Else {
		// ensure we have padding to cover the space occupied by the refresh controls
		&html<
		<td style="width: 300px;">&nbsp;</td>
		>
	}
	Quit $$$OK
}

/// Reload diagram with a fresh copy.
ClientMethod refreshAll() [ Language = javascript ]
{
	document.getElementById('refreshAll').style.backgroundColor = '#D0F8D0';
	setTimeout(function() {
		zen('queueTable').executeQuery();
		zenPage.refreshMessages();
	}, 50);
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
	Set tChecks = $lb(	$lb("AbortMessage", $p(..#ABORTRESOURCE,":",1), $p(..#ABORTRESOURCE,":",2)),
						$lb("AbortAllMessages", $p(..#ABORTRESOURCE,":",1), $p(..#ABORTRESOURCE,":",2)),
						$lb("SuspendJobMsg", $p(..#SUSPENDRESOURCE,":",1),$p(..#SUSPENDRESOURCE,":",2)),
						$lb("AbortJobMsg", $p(..#JOBSRESOURCE,":",1),$p(..#JOBSRESOURCE,":",2)))	
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
				"AbortMessage": ..#ABORTRESOURCE,
				"AbortAllMessages": ..#ABORTRESOURCE,
				"SuspendJobMsg": ..#SUSPENDRESOURCE,
				"AbortJobMsg": ..#JOBSRESOURCE,
				: "")
}

/// Show/hide the toggle buttons
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set canViewTrace = $system.Security.Check("%Ens_MessageTrace","USE")
	If 'canViewTrace {
		Set tTraceTab = ..%GetComponentById("traceContent")
		If $IsObject(tTraceTab) {
			Set tTraceTab.disabled = 1
			Set tTraceTab.title = $$$Text("You are not permitted to access this content.")_$c(10)_$$$Text("Contact your system administrator for access.")
		}
	}
	
	Set canViewContents = $system.Security.Check("%Ens_MessageContent","USE")
	If 'canViewContents {
		Set tBodyTab = ..%GetComponentById("bodyInfo")
		If $IsObject(tBodyTab) {
			Set tBodyTab.disabled = 1
			Set tBodyTab.title = $$$Text("You are not permitted to access this content.")_$c(10)_$$$Text("Contact your system administrator for access.")
		}
		Set tContentsTab = ..%GetComponentById("bodyContents")
		If $IsObject(tContentsTab) {
			Set tContentsTab.disabled = 1
			Set tContentsTab.title = $$$Text("You are not permitted to access this content.")_$c(10)_$$$Text("Contact your system administrator for access.")
		}
	}
	if (..Queue '=""){
		Set ..%GetComponentById("queueTable").value = ..Queue
	}
	If ..enableAutoRefresh {
		Set ..%GetComponentById("refreshQueuesTimer").timeout = 5000
		Set ..%GetComponentById("refreshContentsTimer").timeout = 5000
	}
	Quit tSC
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var ok = this.updateSecurityHelper();	zenPage.setResultsCount();
	zenPage.start = 1;
	if (zen('queueTable').selectedIndex != -1) {
		if (zenPage.MsgID > 0) {
			var mTable = zen('messagesTable').value = zenPage.MsgID;
			zenPage.selectedTable = '';
		}
		zenPage.showContentTables();
	}
	zenPage.start = 0;
}

}
