/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsConstants, EnsUtil)

/// This is the BPInstances page of the ZEN application.
Class EnsPortal.BPInstances Extends EnsPortal.Template.viewerPage [ System = 4 ]
{

/// User must have READ permissions on the "%Ens_Jobs" resource to view this page.
Parameter RESOURCE = "%Ens_Jobs:READ";

/// User must have USE permissions on %Ens_Purge to run the purge action on this page.
Parameter EDITRESOURCE = "%Ens_Purge:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Business Process Instances";

Property resultsTableId As %ZEN.Datatype.id [ InitialExpression = "table" ];

Property pageSizeId As %ZEN.Datatype.id [ InitialExpression = "MaxRows" ];

Property pageNumberId As %ZEN.Datatype.id [ InitialExpression = "pageTotal" ];

Property detailsWidth As %ZEN.Datatype.integer(MAXVAL = 80, MINVAL = 5) [ InitialExpression = 30 ];

/// The business process whose instances are of interest.
/// The URL may supply this business process class name or it defaults to "" (empty string) for all business processes.
Property BusinessProcess As %String(ZENURL = "BP");

/// The name of the SQL table that stores information about the business process whose instances are of interest.
/// If this is a BPL business process, the value is Ens.BusinessProcessBPL; otherwise, it is Ens.BusinessProcess.
/// This property is encrypted and only modifiable on the server
Property BusinessTable As %String(ZENENCRYPT = 1);

/// True if the business process whose instances are of interest is a BPL business process.
/// If so it has a context that is stored in an SQL table. Default is false.
Property HasContext As %Boolean [ InitialExpression = 0 ];

Property linkHelper As %ZEN.proxyObject;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* div around results table */
#resultsTable {
	height: 380px;
	overflow-y: scroll;
}

/* style for intro words *//* not currently used */
#intro {
	padding:30px;
}

/* style for table */
#table {
	overflow: auto;
}

/* div around details table */
#dynaGrid {
	/*
	width: 350px;
	height: 570px;
	*/
	background: white;
	/*
	overflow-x: scroll;
	overflow-y: scroll;
	*/
}

/* details pane style */
#detailsGroup {
	background: #EDECE4;
	color: #606060;
	padding-left: 5px;
	padding-right: 5px;
	overflow: scroll;
	border-left: 1px solid gray;
}

/* style for search panel, like #searchPanel in EnsPortal.Template.viewerPage */
.menuPanel {
	width: 300px; /* fill the whole width of the vgroup that contains it */
	padding-left: 5px;
	padding-right: 5px;
	background: #edece4;
	overflow: hidden;
	overflow-y: auto;
}

/* slight adjustments to tpTable */
table.tpTable {
	padding-top: 5px;
	border: none;
}

table.tpTable tr.tpSelected td {
	font-weight: bold;
}

/* styles for detail table */
.AutoFormCaption {
	font-weight: bold;
}

.AutoFormControl {
	font-weight: normal;
}
#bpInstanceDetailsTable tr td.bpInstanceDetailsHeader {
	background: rgb(53,107,141);
	color: white;
	font-size: 0.8em;
	padding:2px 0px 2px 2px;
}
a.bpDetailsLink {
	font-size: 9pt;
	padding-right: 10%;
	cursor: pointer;
}
</style>
}

/// This XML block defines the contents of the table pane.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<!-- we build the query for this tablePane programmatically -->
<tablePane  id="table" 
    cellSpacing="2"
	dataSource="query"
	useSnapshot="false"
	showZebra="true"
	valueColumn="ID"
	maxRows="500"
	useKeys="true"
	showQuery="false"
	onselectrow="zenPage.selectItem(zenThis);"
	nowrap="true" 
	onmouseoverClass="tpMouseOver"
	onupdate="setTimeout('zenPage.onAfterSearch();',50);"
	unlockSession="true"
	permitClientSQL="true"
	> 
<!-- provide header values for all columns so they can be localized -->
<column header="ID" colName="ID" width="80" style="text-align:left;"  
        title="Unique identifier for this business process instance" />
<column header="Time Created" colName="%TimeCreatedFull" id="idTimeCreatedFull" width="180" colExpression="%EXTERNAL(%TimeCreated)"
		title="Time the business process instance began executing" />
<column header="Time Created" colName="%TimeCreatedTimeOnly" id="idTimeCreatedTimeOnly" width="180" colExpression="{fn RIGHT(%EXTERNAL(%TimeCreated),12)}"
		title="Time the business process instance began executing" hidden="true" />
<!-- instances disappear from this list when they are completed -->
<column header="Completed?" colName="%IsCompleted" width="80" OnDrawCell="DrawYesNo" style="text-align:left;" 
	    title="Yes if the instance has completed execution, otherwise No" />
<column header="Configuration Name" colName="%ConfigName" width="300"
		title="Configuration name for the business process" />
<column header="Session" colName="%SessionId" id="idSessionId" style="text-align:left;cursor:pointer;" width="80" 
       onclick="zenPage.showTrace('#(%query.%SessionId)#');" 
       title="Identifier for the session in which the business process instance is executing"
        cellTitle="Click to view a visual trace of the session"  />
<column header="Primary Request" colName="%PrimaryRequestHeader" id="idPrimaryRequest" style="text-align:left;cursor:pointer;"
	onclick="zenPage.showTrace('#(%query.%PrimaryRequestHeader)#');"
	title="Identifier for the primary request message associated with this business process" 
	cellTitle="Click to view a visual trace of the primary request message" />
<!-- Context column is added, or not added, dynamically depending on the type of business process for the main results table -->
</tablePane>
<!-- set default auto refresh to "None" -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</pane>
}

XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup enclosingClass="menuPanel" valign="top">
<form name="searchForm" id="searchForm" width="100%" layout="vertical" cellStyle="padding: 2px 10px; font-size:0.8em;">
<expando name="expQuick" id="expQuick" caption="Quick Search" expanded="true" 
	    childIndent="16px" containerStyle="padding:20px 10px 0px 10px;" >
<hgroup valign="top">
<vgroup>
<select label="Sort Order" name="SortOrder" id="SortOrder" enclosingStyle="padding-bottom:2px;"
	   displayList="Newest First,Oldest First" valueList="Newest First,Oldest First" value="Newest First" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
<select label="Time Format" name="TimeFormat" id="TimeFormat" 
		displayList="Complete,Time Only" valueList="999,12" value="999" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
</vgroup>
<spacer width="10" />
<vgroup containerStyle="vertical-align: top;">
<select label="Page Size" name="MaxRows" id="MaxRows" enclosingStyle="padding-bottom:2px;"
		displayList="10,20,30,50,100,200,500,1000,2000"	valueList="10,20,30,50,100,200,500,1000,2000" value="#(%page.pageSize)#" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
<select label="Auto-Refresh" name="chkRefresh" id="chkRefresh" hidden="true"
	   displayList="None,30 Seconds,60 Seconds,2 Minutes,5 Minutes" valueList="None,30000,60000,120000,300000" value="None" showEmpty="false"
		onclick="zenPage.changeRefresh();"/>
</vgroup>
<spacer width="10" />
<vgroup valign="top">
<text name="pageTotal" id="pageTotal" label="Page" size="2" readOnly="true" value="#(%page.currentPage)#"
	  title="Current page of the display table, based on Page Size and the current search criteria."/>
</vgroup>
</hgroup>
</expando>
<expando name="expDetails" id="expDetails" caption="Search Instances By..." expanded="true" 
		childIndent="16px" containerStyle="padding:10px 10px 0px 10px;" >
<hgroup>
<dateText name="StartTime" id="StartTime" label="Time Created: Start" size="15" showTime="true" />
<spacer width="10" />
<text name="SessionId" id="SessionId" label="Session Id" size="13" />
</hgroup>
<hgroup>
<dateText name="EndTime" id="EndTime" label="Time Created: End" size="15" showTime="true" />
<spacer width="10" />
<text name="PrimaryRequest" id="PrimaryRequest" label="Primary Request" size="13" />
</hgroup>
<hgroup>
<!-- the comboboxes are completed in OnAfterCreatePage -->
<!-- TAP requests text controls here
<combobox name="ConfigName" id="ConfigName" label="Configuration Name"
		editable="true" unrestricted="true"	size="20" 	 
          title="Choose and enter values in these fields, then click the Search button." /> -->
<text name="ConfigName" id="ConfigName" label="Configuration Name" size="38" 	 
          title="Choose and enter values in these fields, then click the Search button." />
</hgroup>
</expando>
<expando name="expPurge" id="expPurge" caption="Purge Business Process Log" expanded="false" 
	    childIndent="18px" containerStyle="padding:10px 10px 0px 10px;" onexpand="zenPage.countReset();"  >
<!--<spacer height="5"/>-->
<hgroup>
<vgroup labelPosition="left" containerStyle="padding-top:5px;">
<text name="logTotal" id="logTotal" label="Current Count" size="7" readOnly="true" value="" ondblclick="zenPage.countReset();"
	  title="Total number of Business Process Log entries. To update, double-click the field."	 />
<text name="keepDays" id="keepDays" label="Do Not Purge Most Recent" size="7" value="7" 
	  title="Set a value to avoid purging the most recent Business Process Log entries."/>
</vgroup>
<!-- this completes the keepDays text, so it must appear on the same line as "Do Not Purge" but after the text box -->
<html containerStyle="padding: 23px 7px 0px 2px;font-size:0.8em;color:#404040;">Days</html>
</hgroup>
<hgroup>
<button controlClass="commandButton" caption="Purge" onclick="zenPage.startPurge();"
	    title="Start purging Business Process Log entries."/>
</hgroup>
</expando>
</form>
</vgroup>
</pane>
}

/// This XML block defines the contents of the details pane.
XData detailsPane
{
<pane xmlns="http://www.intersystems.com/zen" >
<vgroup valign="top">
<html id="dynaGrid" OnDrawContent="CreateDataSet" hidden="true" />
</vgroup>
</pane>
}

/// Draw Yes or No in place of 1 or 0
Method DrawYesNo(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
 
	If %query(pName) { 
		Write $$$Text("Yes")
	} 
	Else { 
		Write $$$Text("No") 
	} 
	Quit $$$OK
}

/// User clicked a link for Trace. Display the Visual Trace page in a popup,
/// so user can click the arrows to go from session to session without losing his/her place in the BP Log.
ClientMethod showTrace(session) [ Language = javascript ]
{
	if ((session != '') && this.checkLink('VisualTrace')){
		window.open(zenLink('EnsPortal.VisualTrace.zen?SESSIONID=' + encodeURIComponent(session)));
	}
}

/// User clicked a link for Jobs. Display the Jobs page in a popup,
/// so user can view queued messages without losing his/her place in the BP Log.
ClientMethod showJobs(session) [ Language = javascript ]
{
	window.open(zenLink('EnsPortal.Jobs.zen'));
}

/// User clicked a link for Queues. Display the Queues page in a popup,
/// so user can view queued messages without losing his/her place in the BP Log.
ClientMethod showQueues(session) [ Language = javascript ]
{
	window.open(zenLink('EnsPortal.Queues.zen'));
}

ClientMethod showMessage(context) [ Language = javascript ]
{
	if ((context != '') && this.checkLink('MessageContents')) {
		window.open(zenLink('EnsPortal.MessageContents.cls?HeaderClass=Ens.BP.Context&HeaderId=' + encodeURIComponent(context)));
	}
}

/// Server-side callback to provide localized string introducing the details table
Method GiveAdviceString(pSeed As %String) As %Status
{
	Write $$$Text("Click on a table row to show details")
	Quit $$$OK
}

/// toggle detailTable for a selected row.
ClientMethod onSelectItem() [ Language = javascript ]
{
	if (this.selectedId > 0) {
		var detail = zen("dynaGrid"); // get the detail display
		if (!this._oldRows) { // if needed, establish oldRows array to remember content
			this._oldRows = new Object();
		}
		if (this._oldRows[this.selectedId]) { // reuse the content for this row
			detail.setContent(this._oldRows[this.selectedId]);
		} 
		else { // get new content from server
			detail.setContent(""); // clear out any lingering content from before
			detail.seed = this.selectedId; 
			detail.refreshContents(true); 
			this._oldRows[this.selectedId] = detail.getEnclosingDiv().innerHTML;
		}
		detail.setHidden(false);
	}
}

/// Server-side callback to provide data for the details table
Method CreateDataSet(pSeed As %String) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode = 2

		// Get relevant properties to use in the detailed display
		Set qSQL = "SELECT *,$Piece(x__ClassName,'~',$Length(x__ClassName,'~')-1) As ClassName FROM Ens.BusinessProcess WHERE %ID = ?"
		Set tStatus = tStatement.%Prepare(qSQL)
		If $$$ISERR(tStatus) Quit

		#dim tRS As %SQL.StatementResult
		Set tRS = tStatement.%Execute(pSeed)

		Set tHeaders(1) = $$$TextHTML("Basic Information")
		Set tHeaders(2) = $$$TextHTML("Message Information")
		Set tHeaders(3) = $$$TextHTML("Configuration Information")

	  	If (tRS.%Next(.tStatus)) {
			// test for context
			Set tContextId = ##class(Ens.BusinessProcessBPL).%ContextGetStored(pSeed)

		  	If (tContextId) {
				// display the context id as a link
			  	Set tContextContent = "<span title=""" _ $$$TextHTML("Click to view the business process context for this instance") _ """ style=""font-weight:bold;color:#5ba4dc;cursor:pointer;"" onclick=""zenPage.showMessage(" _ $zconvert($zconvert(tContextId,"O","JS"),"O","HTML") _ ");"">" _ $zconvert(tContextId,"O","HTML") _ "</span>"
		  	}
		  	Set tHaveContext = (tContextId '= "")

		  	// build lists
		  	Set SessionId = tRS.%SessionId
		  	// Format is $LB(value, title, Yes/No, HTML-escaped, RepliedStatus)
		  	Set tData(1) = $LB(
		  		$LB(tRS.ID, $$$Text("ID")),
		  		$select(tHaveContext: $LB(tContextContent, $$$Text("Business Process Context"), 0, 1), 1: ""),
		  		$LB(tRS.%TimeCreated, $$$Text("Time Created")),
		  		$LB(tRS.%IsCompleted, $$$Text("Completed?"), 1),
				$LB(tRS.%IsTerminated, $$$Text("Terminated?"), 1),
				$LB(tRS.%IsTimerInterrupted, $$$Text("Timer Interrupted?"), 1),
				$LB(tRS.%QuitTask, $$$Text("Quit Task?"), 1),
				$LB(tRS.%TimeCompleted, $$$Text("Time Completed")),
				$LB(tRS.%ConfigName, $$$Text("Configuration Name")),
				$LB(tRS.ClassName, $$$Text("Class Name")),
				$LB(tRS.%ConfigQueueName, $$$Text("Queue Name"))
			)
			Set tData(2) = $LB(
				$LB(SessionId, $$$Text("Session ID")),
				$LB(tRS.%PrimaryRequestHeader, $$$Text("Primary Request Header")),
	  			$LB(tRS.%RepliedStatus, $$$Text("Replied Status"), 0, 0, 1),
	  			$LB(tRS.%StatusCode, $$$Text("Status Code")),
	  			$LB(tRS.%PrimaryResponseHeader, $$$Text("Primary Response Header")),
	  			$LB(tRS.%responseClassName, $$$Text("Response Class Name")),
	  			$LB(tRS.%responseId, $$$Text("Response ID"))
	  		)
			Set tData(3) = $LB(
				$LB(tRS.Adapter, $$$Text("Adapter")),
				$LB(tRS.AlertOnError, $$$Text("Alert On Error?"), 1),
				$LB(tRS.AlertRetryGracePeriod, $$$Text("Alert Retry Grace Period")),
				$LB(tRS.FailureTimeout, $$$Text("Failure Timeout")),
				$LB(tRS.InactivityTimeout, $$$Text("Inactivity Timeout")),
				$LB(tRS.QueueCountAlert, $$$Text("Queue Count Alert")),
				$LB(tRS.QueueWaitAlert, $$$Text("Queue Wait Alert")),
				$LB(tRS.ReplyCodeActions, $$$Text("Reply Code Actions")),
				$LB(tRS.Retry, $$$Text("Retry?"), 1),
				$LB(tRS.RetryInterval, $$$Text("Retry Interval")),
				$LB(tRS.SuspendMessage, $$$Text("Suspend Message?"), 1)
			)
			Set tJobsTitle = $$$TextHTML("Show currently active jobs")
			Set tQueuesTitle = $$$TextHTML("Show current queues")
			
			&html<
			<!-- action links -->
			<div class="tpAction" style="padding: 2px 0px; text-align: center;">
				<a class="bpDetailsLink" title="#(tJobsTitle)#" onclick="zenPage.showJobs();">#($$$TextHTML("Jobs"))#</a>
				<a class="bpDetailsLink" title="#(tQueuesTitle)#" onclick="zenPage.showQueues();">#($$$TextHTML("Queues"))#</a>
			>
			If (SessionId '= "") {
				Set tTraceTitle = $$$TextHTML("Show Visual Trace for the session")
				&html<<a class="bpDetailsLink" title="#(tTraceTitle)#" onclick="zenPage.showTrace(#($zconvert($zconvert(SessionId,"O","JS"),"O","HTML"))#);">
					#($$$TextHTML("Trace"))#
				</a>>
			}
			&html<
			</div>
			<!-- display table -->
			<table border="0" cellpadding="0" cellspacing="0">
			<tr valign="top">
				<td>
					<table id="bpInstanceDetailsTable">
			>
			Set tNoneText = $$$Text("(none)")
			Set tYesText = $$$Text("Yes")
			Set tNoText = $$$Text("No")
			For n=1:1:3 {
				&html<
					<tr>
						<td colspan="2" class="bpInstanceDetailsHeader" style="">#(tHeaders(n))#</td>
					</tr>
					<tr valign="top">
						<td>
							<table class="tpTable" border="0" cellpadding="0" cellspacing="0">
				>
				Set tListLen = $LL(tData(n))
				For i=1:1:tListLen {
					Set tCurrentItem = $LG(tData(n),i)
					If (tCurrentItem = "") {
						// skip missing context
						Continue
					}
					Set tTitle = $LG(tCurrentItem,2)
					Set tValue = $LG(tCurrentItem,1)
					If (tValue = "") {
						Set tValue = tNoneText
					}
					If $LG(tCurrentItem,3) {
						Set tValue = $select(tValue: tYesText, 1: tNoText)
					}
					ElseIf $LG(tCurrentItem,5) {
						Set tValue = $case(tValue,
							$$$eRepliedStatusNotCalled:		$$$Text("Not called"),
							$$$eRepliedStatusConstructed:	$$$Text("Constructed"),
							$$$eRepliedStatusSent:			$$$Text("Sent"),
												:			tNoneText)
					}
					If '$LG(tCurrentItem,4) {
						// HTML-escape if not already escaped
						Set tValue = $zconvert(tValue,"O","HTML")
					}
					&html<
						<tr valign="top">
							<td class="AutoFormCaption" width="170px">#($zconvert(tTitle,"O","HTML"))#:</td>
							<td class="AutoFormControl">#(tValue)#</td>
						</tr>
					>
				}
				&html<
					</table></td></tr>
				>
			}
			&html<
				</table></td></tr></table>
			>
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// If auto-refresh is still on, refresh table and restart the timer
ClientMethod timeout(timer) [ Language = javascript ]
{
	var val = zen('chkRefresh').getValue(); // check auto-refresh
	if (zenPage.enableAutoRefresh && !val.match("None")) { // There is a non-zero timer value
		zenPage.doSearch(); // refresh table
		zenPage.countReset(); // update count
		timer.startTimer(); // restart timer
	}
}

/// User chose a new Auto-Refresh value; set a new timeout value and start the timer
ClientMethod changeRefresh() [ Language = javascript ]
{
	var val = zen('chkRefresh').getValue(); // check auto-refresh
	if (zenPage.enableAutoRefresh && !val.match("None")) { // There is a non-zero timer value
		var timer = zen('timer'); // get timer
		timer.timeout = val; // set timeout
		timer.startTimer(); // restart timer
	}
	// Otherwise don't start the timer and it will just sit there
}

/// Build the current expando state into a string concatenated with commas
ClientMethod expandoState() [ Language = javascript ]
{
	var expandoState = zen("expQuick").getProperty("expanded");
	expandoState = expandoState + "," + zen("expDetails").getProperty("expanded");
	expandoState = expandoState + "," + zen("expPurge").getProperty("expanded");
	return expandoState;
}

/// Reset the current count of Rule Log entries
ClientMethod countReset() [ Language = javascript ]
{
	zen("logTotal").setValue(zenPage.GetCount());
}

ClassMethod GetCount() As %Integer [ ZenMethod ]
{
	Quit ##class(Ens.Purge).BusinessProcessCount()
}

/// User clicked the Purge button
ClientMethod startPurge() [ Language = javascript ]
{
	if (!zenPage.checkEdit()) { return; }
	var conf = $$$Text("Are you sure you want to purge the Business Process Log now?");
	var nan = $$$Text("Value entered for number of days is not a number.");
	var npos = $$$Text("Value entered for number of days is not a positive number.");
	var count = $$$Text("Number of records purged:");
	var fail = $$$Text("Business Process Log purge did not succeed:");

	zenPage.countReset(); // update current count
	if (confirm(conf)) {
		// find out how many days back to purge
		var num = zen('keepDays').getValue();
		if (isNaN(num)) {
			alert(nan);
			return false;
		}
		else if (num < 0) {
			alert(npos);
			return false;
		}
		
		// do the purge and process the results
		var ret = zenPage.DoPurge(num);
		if (ret[0] == '-') { // our failure code
			alert(fail + ' ' + ret.substring(1));
		}
		else {
			if (parseInt(ret) > 0) {
				zenPage.doSearch(); // refresh the display
				zenPage.countReset(); // update current count
			}
			alert(count + " " + ret); // confirm purge
		}
	}
	return true;
}

/// Perform the purge operation and if there is an error, return the message
/// to JavaScript by prepending the message with a '-'. If no error then 
/// return the zero or positive number of entries deleted, as a string.
ClassMethod DoPurge(keep As %Integer) As %String [ ZenMethod ]
{
	Set LogsDeleted = 0
	Set status = ##class(Ens.Purge).PurgeBusinessProcessesByDate(keep,.LogsDeleted)
	If ($$$ISERR(status)) { 
		Quit "-" _ $ZCVT($System.Status.GetErrorText(status),"O","JS") 
		}
	Else { 
		Quit LogsDeleted 
	}
}

/// User clicked the Search button, user changed a Quick Search criterion, 
/// or we have completed a non-zero Purge.
ClientMethod onSearchHandler() [ Language = javascript ]
{
	var table = this.getResultsTable();
	var where = "";

	var SortOrder = zen("SortOrder").getValue();

	// modify Select TimeCreated based on Time Format
	var TimeFormat = zen('TimeFormat').getValue();
	zen('idTimeCreatedFull').setProperty('hidden',TimeFormat == 12);
	zen('idTimeCreatedTimeOnly').setProperty('hidden',TimeFormat != 12);

	// whereClause, orderByClause, and groupByClause
	var StartTime = zen("StartTime").getValue();
	var EndTime = zen("EndTime").getValue();
	var SessionId = zen("SessionId").getValue();
	var PrimaryRequest = zen("PrimaryRequest").getValue();
	var ConfigName = zen("ConfigName").getValue();

	var Defaults = StartTime+","+EndTime+","+SessionId+","+PrimaryRequest+","+ConfigName;

	// call server method to build the where clause
	var where = zenPage.GetWhereClause(Defaults);
	table.whereClause = where;
	table.orderByClause = "%ID" + (SortOrder == "Newest First" ? " desc" : "");

	var rows = zen('MaxRows');
	var MaxRows = parseInt(rows.value);
	if (MaxRows > 10000) MaxRows = 100;
	if (MaxRows < 0) MaxRows = 1;

	// Get the current expando state and save it
	var States = zenPage.expandoState();

	// Get the Auto-Refresh choice and save it
	var auto = zen("chkRefresh");
	var AutoRefresh = auto.getValue();

	// Save last selections to global as default for page
	zenPage.SaveDefaults(SortOrder,TimeFormat,Defaults,MaxRows,States,AutoRefresh);
}

ClientMethod onAfterPageChange() [ Language = javascript ]
{
	// make it easy to navigate
	zenSetProp("expQuick","expanded",true);

	return true;
}

/// Get the first part of the SQL statement.
Method GetColumnsAndFrom(timeFormat As %String) As %String
{
	Set columns = "%ID, %IsCompleted, %ConfigName," _
		"%SessionId,"_
		"%PrimaryRequestHeader,"_
		"%EXTERNAL(%TimeCreated) As %TimeCreatedFull,"_
		"{fn RIGHT(%EXTERNAL(%TimeCreated),12)} As %TimeCreatedTimeOnly,"_
		"%EXTERNAL(%TimeCompleted) As %TimeCompletedFull,"_
		"{fn RIGHT(%EXTERNAL(%TimeCompleted),12)} As %TimeCompletedTimeOnly"
	If (..HasContext) {
		Set columns = columns _ ", %Context"
	}
	Quit columns _ " FROM " _ ..BusinessTable
}

/// Method called from doSearch and %OnAfterCreatePage to build the where clause
Method GetWhereClause(Defaults) As %String [ ZenMethod ]
{
	Set where = ""
	If (..BusinessProcess '= "") && ((..BusinessTable = "Ens.BusinessProcess") || (..BusinessTable = "Ens.BusinessProcessBPL")) {
		Set where = where _ $LB("($Piece(x__ClassName,'~',$Length(x__ClassName,'~')-1)) = '" _ $replace(..BusinessProcess,"'","''") _ "'")
	}

	Set StartTime = $replace($P(Defaults,",",1),"'","''")
	Set EndTime = $replace($P(Defaults,",",2),"'","''")
	Set SessionId = $replace($P(Defaults,",",3),"'","''")
	Set PrimaryRequest = $replace($P(Defaults,",",4),"'","''")
	Set ConfigName = $replace($P(Defaults,",",5),"'","''")
	
	If ((StartTime '= "") && (EndTime '= "") && ($$$timeCmp(EndTime,StartTime) < 0)) {
		Set temp = StartTime
		Set StartTime = EndTime
		Set EndTime = temp
	}
	If (StartTime '= "") Set where = where _ $LB("%TimeCreated >= '" _ StartTime _ "'")
	If (EndTime '= "") Set where = where _ $LB("%TimeCreated <= '" _ EndTime _ "'")
	If (SessionId '= "") Set where = where _ $LB("%SessionId = '" _ SessionId _ "'")
	If (PrimaryRequest '= "") Set where = where _ $LB("%PrimaryRequestHeader = '" _ PrimaryRequest _ "'")
	If (ConfigName '= "") Set where = where _ $LB("%ConfigName = '" _ ConfigName _ "'")

	Quit $LTS(where," AND ")
}

/// Save user's last search criteria into global for page default
ClassMethod SaveDefaults(SortOrder, TimeFormat, Defaults, MaxRows, States, AutoRefresh) [ ZenMethod ]
{
	For p = 1:1:$L(Defaults,",") Set pv=$P(Defaults,",",p),$P(Defaults,",",p) = $S(pv="true":1,pv="false":0,1:pv)
	For p = 1:1:$L(States,",") Set pv=$P(States,",",p),$P(States,",",p) = $S(pv="true":1,pv="false":0,1:pv)
	Set AutoRefresh = $S(AutoRefresh="true":1,AutoRefresh="false":0,1:AutoRefresh)
	Set ^IRIS.Temp.EnsPortal($Username,"BPInstances","SearchCriteria") = SortOrder_"^"_TimeFormat_"^"_Defaults_"^"_MaxRows_"^"_States_"^"_AutoRefresh
}

/// Reset the "Search By..." form fields to blank, reset other fields to defaults
ClientMethod formReset() [ Language = javascript ]
{
	var conftext = $$$Text("Reset to default values?")
	if (confirm(conftext)) {
		var table = this.getResultsTable();
	
		// empty out the fields in the form
		zen("searchForm").reset(); 
	
		// Restore default values to fields outside the "Search Rules By..." area
		zen("SortOrder").setValue("Newest First");  
		zen("TimeFormat").setValue("999");  
		zen("chkRefresh").setValue("None"); 
		zen("MaxRows").setValue(500);
		zen("keepDays").setValue(7);
	
		// set current count
		zenPage.countReset();
	
		// refresh the display; we will update count upon searching
		zenPage.doSearch();
	}
	return true;
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tStatus = ##super()
	If $$$ISERR(tStatus) Quit tStatus

	// get business process information
	Do ..GetBusinessProcess()

	// get defaults and build up the initial display
	Do ..GetAndUseDefaults()
	
	If ..enableAutoRefresh {
		Set ..%GetComponentById("chkRefresh").hidden = 0
	}

	Set ..linkHelper = ##class(%ZEN.proxyObject).%New()
	Set ..linkHelper.VisualTrace = $system.Security.Check("%Ens_MessageTrace","USE")
	Set ..linkHelper.MessageContents = $system.Security.Check("%Ens_MessageContent","USE") 

	Quit $$$OK
}

ClientMethod checkLink(pageName) [ Language = javascript ]
{
	if ((pageName == null) || (!this.linkHelper)) {
		return true;
	}
	if (this.linkHelper[pageName] == null) {
		return true;
	}
	var perm = this.linkHelper[pageName];
	perm = (perm == 1 ? true : false);
	if (!perm) {
		alert(this.msgNotPermitted);
	}
	return perm;
}

/// Method called from %OnAfterCreatePage to get business process information
Method GetBusinessProcess() As %String
{
	// BP must be a business process class name; it cannot be the configuration name of a business process.
	// If BP is blank, do all business processes.

	// test for context and which table to use
	Set tIsBPL = (("" '= ..BusinessProcess) && $classmethod(..BusinessProcess,"%IsA","Ens.BusinessProcessBPL"))
	Set ..HasContext = tIsBPL

	Set tTableName = $select(..BusinessProcess = "": "", 1: $$$comClassKeyGet(..BusinessProcess,$$$cCLASSsqlqualifiednameQ))
	If (tTableName '= "") && $system.SQL.CheckPriv($username,"1,"_tTableName,"s") {
		Set ..BusinessTable = tTableName
	}
	Else {
		Set ..BusinessTable = "Ens.BusinessProcess" _ $select(tIsBPL: "BPL", 1: "")
	}

	// set SQL table name
	Set tab = ..%GetComponentById("table")
	Set tab.tableName = ..BusinessTable
	
	// business process context column
	Set col = ..%GetComponentById("contextColumn")
	If (..HasContext) {
		If ('$IsObject(col)) {
			Set col = ##class(%ZEN.Auxiliary.column).%New()
			Do tab.columns.Insert(col)
			Do ..%AddComponent(col)
		}
		Set col.id="contextColumn"
		Set col.header = $$$Text("Context") 
		Set col.colName="%Context" 
		Set col.style="text-align:left;cursor:pointer;" 
		Set col.onclick="zenPage.showMessage('#(%query.%Context)#');" 
		Set col.title = $$$Text("Identifier for the business process context for this instance")
		Set col.cellTitle = $$$Text("Click to view the contents of the business process context")
		Set sess = ..%GetComponentById("idSessionId")
		Set sess.width="70"
		Set prim = ..%GetComponentById("idPrimaryRequest")
		Set prim.width="70"
	}
	Else {
		If $IsObject(col) { 
			Do ..%RemoveComponent(col)
		}
	}
}

/// Method called from %OnAfterCreatePage to get defaults and build up the initial display
Method GetAndUseDefaults() As %String
{
	#; Get the last saved default values and use them as defaults.
	Set SearchCriteria = $G(^IRIS.Temp.EnsPortal($Username,"BPInstances","SearchCriteria"),"Newest First^999^,,,,^500^0,0,0,0^None")
	Set SortOrder = $P(SearchCriteria,"^",1)
	Set TimeFormat = $P(SearchCriteria,"^",2)
	Set Defaults = $P(SearchCriteria,"^",3)
	Set MaxRows = $P(SearchCriteria,"^",4)
	Set States = $P(SearchCriteria,"^",5)
	Set AutoRefresh = $P(SearchCriteria,"^",6)
	
	If '..enableAutoRefresh {
		Set AutoRefresh = "None"
	}
	
	#; Load defaults for Details
	Set ..%GetComponentById("SortOrder").value = SortOrder
	Set ..%GetComponentById("TimeFormat").value = TimeFormat
	Set ..%GetComponentById("MaxRows").value = MaxRows
	Set ..%GetComponentById("StartTime").value = $P(Defaults,",",1)
	Set ..%GetComponentById("EndTime").value = $P(Defaults,",",2)
	Set ..%GetComponentById("SessionId").value = $P(Defaults,",",3)
	Set ..%GetComponentById("PrimaryRequest").value = $P(Defaults,",",4)
	Set ..%GetComponentById("ConfigName").value = $P(Defaults,",",5)
	
	#; Load Expando states
	Set ..%GetComponentById("expQuick").expanded = $P(States,",",1)
	Set ..%GetComponentById("expDetails").expanded = $P(States,",",2)
	Set ..%GetComponentById("expPurge").expanded = $P(States,",",3)

	#; Load auto-refresh setting
	Set ..%GetComponentById("chkRefresh").value = AutoRefresh

	#; set up the table
	Set table = ..%GetComponentById("table")
	Set table.whereClause = ..GetWhereClause(Defaults)
	Set table.orderByClause = "%ID" _ $select(SortOrder = "Newest First": " desc", 1: "")
	Set table.maxRows = MaxRows

	Set ..%GetComponentById("idTimeCreatedTimeOnly").hidden = (TimeFormat '= 12)
	Set ..%GetComponentById("idTimeCreatedFull").hidden = (TimeFormat = 12)
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	if (zenIsIE) { // avoid IE resize bug
		var results = zen('table');
		if (results) {
			results.packRowsIE = function() { return null; };
		}
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
	Quit $$$Text("Business Process Instances","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("searchButton",$$$Text("Search"),$$$Text("Search the Business Process Log using the current criteria"),"zenPage.doSearch();")
	Set pCommands(2) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the Business Process Log search criteria to their default values"),"zenPage.formReset();")
	Set pCommands(3) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false);")
	Set pCommands(4) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true);")
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Set tResList = $case(pMethod,
							"DoPurge": ..#EDITRESOURCE,
							: "")
	Quit tResList
}

}
