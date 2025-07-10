/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is the Event Log page of the ZEN application.
Class EnsPortal.EventLog Extends EnsPortal.Template.viewerPage [ System = 4 ]
{

/// User needs USE permissions on the %Ens_EventLog resource to view this page.
Parameter RESOURCE = "%Ens_EventLog:USE";

/// Flag to indicate whether a user may purge Event log entries.
Property canPurge As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_Purge","USE")} ];

Property logCount As %ZEN.Datatype.integer [ InitialExpression = {..GetCount()} ];

/// Displayed name of this page.
Parameter PAGENAME = "Event Log";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES = "ensemble/Ensemble_Utils.js";

/// Indicate if can cancel search.
Parameter CANCANCELSEARCH As BOOLEAN = 1;

/// Indicate if ought to create tempPortalNode when page created. Used by Cancel feature for example.
Parameter SETUPTEMPPORTALNODE As BOOLEAN = 1;

Property resultsTableId As %ZEN.Datatype.id [ InitialExpression = "table" ];

Property pageSizeId As %ZEN.Datatype.id [ InitialExpression = "MaxRows" ];

Property pageNumberId As %ZEN.Datatype.id [ InitialExpression = "pageTotal" ];

Property detailsWidth As %ZEN.Datatype.integer(MAXVAL = 80, MINVAL = 5) [ InitialExpression = 30 ];

Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageTrace","USE")} ];

Property sessionLinkTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Click to view a visual trace of the session")} ];

Property tracePage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.VisualTrace.zen" ];

Property matchSource As %ZEN.Datatype.string(ZENURL = "SOURCE");

Property startId As %ZEN.Datatype.string(ZENURL = "StartId");

Property endId As %ZEN.Datatype.string(ZENURL = "EndId");

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* div around results table */
#resultsTable {
	height: 610px;
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
	background: white;
}

/* details pane style */
#detailsGroup {
	overflow: scroll;
}

/* style for search panel */
.menuPanel {
	width: 300px;
	background: #edece4;
	overflow: hidden;
	overflow-y: auto;
}

/* slight adjustments to tpTable */
table.tpTable, table.eventInfoTable {
	padding-top: 5px;
	border: none;
}

.sessionLink {
	cursor: pointer;
	color: #3B84BC;
	text-decoration: none;
}
tr.tpSelected a.sessionLink {
	color: white;
	text-decoration: underline;
}
</style>
}

/// This pane displays event log activity table. User may click on a row and details are displayed to the side.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<vgroup valign="top">
<!--<spacer height="5"/>-->
<tablePane id="table"
	cellSpacing="2"
	dataSource="columns"
	tableName="Ens_Util.Log"
	useSnapshot="false"
	showZebra="true"
	valueColumn="ID"
	maxRows="1000"
	useKeys="true"
	showQuery="false"
	onselectrow="zenPage.selectItem(zenThis);"
	nowrap="true"
	onmouseoverClass="tpMouseOver"
	enableToggleSelect="true"
	onupdate="setTimeout('zenPage.onAfterSearch();',50);"
	initialExecute="false"
	OnCreateResultSet="CheckConditions"
	unlockSession="true"
	multiSelect="true"
	permitClientSQL="true"
	>
<!-- provide header values for all columns so they can be localized -->
<column header="Type" colName="Type" style="text-align:left;" width="65" OnDrawCell="DrawLocalType"
        title="Alert, Assert, Error, Info, Trace, or Warning"/>
<column header="ID" colName="ID" style="text-align:left;" width="90"
		title="Log Event ID"/>
<column header="Time Logged" colName="TimeLogged999" id="idTimeLogged999" width="180" colExpression="{fn RIGHT(%EXTERNAL(TimeLogged),999)}"
		title="Time the event was noted in the log" hidden="true" />
<column header="Time Logged" colName="TimeLogged12" id="idTimeLogged12" width="180" colExpression="{fn RIGHT(%EXTERNAL(TimeLogged),12)}"
		title="Time the event was noted in the log" />
<column header="Session" colName="SessionId" width="90"
       title="Identifier for the session in which the event occurred"
       link=" "
        OnDrawCell="DrawSessionCell" />
<column header="Job" colName="Job" width="90"
        title="System job in which the event occurred"
        OnDrawCell="DrawMethodCell" />
<column header="Source" colName="ConfigName" width="200"
        title="Configuration name of the item that triggered the event"
        OnDrawCell="DrawMethodCell" />
<column header="Text" colName="Text" width="1200"
        title="Descriptive text logged with the event"
        OnDrawCell="DrawTextCell" />
<column colName="TraceCat" hidden="true"/>
<column colName="SourceClass" hidden="true"/>
<column colName="SourceMethod" hidden="true"/>
<!-- we will not be switching colors by user preference; we will always use zebra plus 1-column color coding -->
<condition id="condAlert" colName="Type" predicate="EQ" value="Alert" targetCol="Type" cellStyle="background: yellow; color: darkred; font-weight: bold;" />
<condition id="condError" colName="Type" predicate="EQ" value="Error" targetCol="Type" cellStyle="background: pink; color: darkred; font-weight: bold;" />
<condition id="condWarning" colName="Type" predicate="EQ" value="Warning" targetCol="Type" cellStyle="background: orange; color: darkred; font-weight: bold;" />
<condition id="condAssert" colName="Type" predicate="EQ" value="Assert" targetCol="Type" cellStyle="background: silver; color: darkred; font-weight: bold;" />
<condition id="condTrace" colName="Type" predicate="EQ" value="Trace" targetCol="Type" cellStyle="background: lightblue; color: darkblue; font-weight: bold;" />
<!-- it does not work to have a condition Type EQ Info and also have Method EQ Start/StopProduction so no condition on Type EQ Info -->
<condition id="condStart" colName="SourceMethod" predicate="EQ" value="StartProduction" targetCol="Type" cellStyle="background: lightgreen; color: darkgreen; font-weight: bold;" />
<condition id="condStop" colName="SourceMethod" predicate="EQ" value="StopProduction" targetCol="Type" cellStyle="background: lightgreen; color: darkgreen; font-weight: bold;" />
</tablePane>
<!-- set default auto refresh to "None" -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</vgroup>
</pane>
}

/// This pane displays the search criteria. We provide defaults and user can change them.
/// User's values are saved and used as future defaults for this user.
/// Clicking a drop down list item will refresh the table immediately.
/// Text fields you are required to click [Enter] or the "Search" button.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
<vgroup id="mainPanel" enclosingClass="menuPanel"  valign="top">
<form name="searchForm" id="searchForm" layout="vertical" cellStyle="padding: 2px 10px; font-size:0.8em;">
<expando name="expQuick" id="expQuick" caption="Quick Search" expanded="true"
	    childIndent="16px" containerStyle="padding:10px 10px 0px 10px;"  >
<hgroup valign="top">
<vgroup>
<select label="Auto-Refresh" name="chkRefresh" id="chkRefresh" hidden="true"
	   displayList="None,30 Seconds,60 Seconds,2 Minutes,5 Minutes" valueList="None,30000,60000,120000,300000" value="None" showEmpty="false"
		onclick="zenPage.changeRefresh();"/>
<select label="Sort Order" name="SortOrder" id="SortOrder"
	   displayList="Newest First,Oldest First" valueList="Newest First,Oldest First" value="Newest First" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
<select label="Time Format" name="TimeFormat" id="TimeFormat"
		displayList="Complete,Time Only" valueList="999,12" value="999" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
<spacer width="10" />
</vgroup>
<spacer width="10" />
<vgroup valign="top">
<label name="pageTotal" id="pageTotal" label="Page" value="#(%page.currentPage)#" enclosingStyle="font-size:0.8em;padding-bottom:5px;padding-top:2px;"
	  title="Current page of the display table, based on Page Size and the current search criteria."/>
<select label="Page Size" name="MaxRows" id="MaxRows"
		displayList="10,20,30,50,100,200,500,1000,2000"	valueList="10,20,30,50,100,200,500,1000,2000" value="#(%page.pageSize)#" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
</vgroup>
</hgroup>
</expando>
<expando name="expInclude" id="expInclude" caption="Event Types" expanded="true"
	    childIndent="16px" containerStyle="padding:10px 10px 0px 10px;" >
<hgroup>
<vgroup cellStyle="font-size:0.8em">
<checkbox name="Error" id="Error" caption="Error" value="1" onclick="zenPage.doSearch();"/>
<checkbox name="Alert" id="Alert" caption="Alert" value="1" onclick="zenPage.doSearch();"/>
<checkbox name="Info" id="Info" caption="Info" value="1" onclick="zenPage.doSearch();"/>
</vgroup>
<spacer width="10" />
<vgroup cellStyle="font-size:0.8em">
<checkbox name="Warning" id="Warning" caption="Warning" value="1" onclick="zenPage.doSearch();"/>
<checkbox name="Trace" id="Trace" caption="Trace" value="1" onclick="zenPage.doSearch();"/>
<checkbox name="Assert" id="Assert" caption="Assert" value="1" onclick="zenPage.doSearch();" />
</vgroup>
</hgroup>
</expando>
<expando name="expDetails" id="expDetails" caption="Search Events By..." expanded="true"
		childIndent="16px" containerStyle="padding:10px 10px 0px 10px;" >
<vgroup valign="top">
<hgroup valign="top">
<dateText name="StartTime" id="StartTime" label="Start Time" size="18" showTime="true" defaultTime="00:00:00" containerStyle="padding:0px 3px 0px 0px;"
          title="Entering a date/time value in this field will restrict the search results to times after or equal to the given value" />
<spacer width="10" />
<text name="StartId" id="StartId" label="Start ID" size="9"
          title="Entering an ID value in this field will restrict the search results to Event Log IDs greater than or equal to the given value" />
</hgroup>
<hgroup valign="top">
<dateText name="EndTime" id="EndTime" label="End Time" size="18" showTime="true" defaultTime="23:59:59" containerStyle="padding:0px 3px 0px 0px;"
          title="Entering a date/time value in this field will restrict the search results to times before or equal to the given value" />
<spacer width="10" />
<text name="EndId" id="EndId" label="End ID" size="9"
          title="Entering an ID value in this field will restrict the search results to Event Log IDs less than or equal to the given value" />
</hgroup>
<hgroup valign="top">
<pane paneName="configNameControl" />
<spacer width="10" />
</hgroup>
<hgroup valign="top">
<text name="SourceClass" id="SourceClass" label="Source Class" size="21"
          title="Entering a class name in this field will restrict the search results to log events generated in the given class.  The SQL wildcard '%' may be used." />
<spacer width="10" />
<text name="SessionId" id="SessionId" label="Session ID" size="9"
          title="Entering an ID value in this field will restrict the search results to log events generated in the given session" />
</hgroup>
<hgroup valign="top">
<text name="SourceMethod" id="SourceMethod" label="Source Method" size="21"
           title="Entering a method name in this field will restrict the search results to log events generated in the given method.  The SQL wildcard '%' may be used." />
<spacer width="10" />
<text name="Job" id="Job" label="Job" size="9"
          title="Entering a Job ID value in this field will restrict the search results to log events generated in the given job or process" />
</hgroup>
</vgroup>
<text name="Text" id="Text" label="Text" size="37" maxlength="50"
          title="Entering a text string value in this field will restrict the search results to log events whose text content contains the given string" />
</expando>
<expando name="expPurge" id="expPurge" caption="Purge Event Log" expanded="false"
	    childIndent="16px" containerStyle="padding:10px 10px 0px 10px;" >
<hgroup valign="top">
<vgroup>
<label name="logTotal" id="logTotal" label="Current Count" value="#(%page.logCount)#" ondblclick="zenPage.countReset();" enclosingStyle="font-size:0.8em;padding-bottom:3px;"
	  title="Total number of Event Log entries. To update, double-click the field."	 />
<label label="Do Not Purge Most Recent" labelStyle="white-space:normal;"
	  title="Set a value to avoid purging the most recent Event Log entries."/>
<hgroup>
<text name="keepDays" id="keepDays" size="3" maxlength="4" value="7"/>
<spacer width="4px" />
<label label="Days"/>
</hgroup>
<spacer height="5px" />
<button id="startPurgeButton" controlClass="commandButton" caption="Purge" onclick="zenPage.startPurge();"
	    title="Start purging Event Log entries." />
</vgroup>
</hgroup>
</expando>
</form>
</vgroup>
</pane>
}

/// Control for ConfigName
XData configNameControl [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<dataCombo name="ConfigName" id="ConfigName" label="Source Config Item"
		editable="true" unrestricted="true"	size="18" containerStyle="padding:0px 3px 0px 0px;"
		title="Entering a config item name in this field will restrict the search results to log events generated in the config item.  The SQL wildcard '%' may be used."
		choiceColumn="1" maxRows="2000" dropdownWidth="400px"
		queryClass="Ens.Config.Production" queryName="EnumerateConfigItems" displayColumns="1"
		/>
</pane>
}

/// This pane shows details of a given entry when that row is clicked in the table.
XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
<vgroup valign="top">
<html id="dynaGrid" OnDrawContent="DrawEventDetails" hidden="true" />
</vgroup>
</pane>
}

/// We are not using this at present.
XData introPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
<vgroup valign="top">
<html>
<p>Enter search criteria and click Search.</p>
<p>By default, the most recent events will be shown.</p>
</html>
</vgroup>
</pane>
}

/// User clicked a link for Trace. Display the Visual Trace page in a popup,
/// so user can click the arrows to go from session to session without losing his/her place in the Event Log.
ClientMethod showTrace(session, stopEvent, evt) [ Language = javascript ]
{
	if (stopEvent) {
		if (zenIsIE) {
			if (!evt) {
				evt = window.event;
			}
			if (evt) {
				evt.cancelBubble = true;
			}
		}
		else if (evt) {
			evt.stopPropagation();
		}
	}
	if (session != '') {
		if (!this.canViewTrace) {
			alert(this.msgNotPermitted);
			return false;
		}
		var URI = zenLink(this.tracePage +'?SESSIONID='+encodeURIComponent(session));
		window.open(URI);
	}
}

/// Server-side callback to provide localized string introducing the details table
Method GiveAdviceString(pSeed As %String) As %Status
{
	Write $$$Text("Click on a table row to show event details")
	Quit $$$OK
}

/// Server-side method to write out the content for the event Type column
/// Draw localized event type name
Method DrawLocalType(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
 	Set txt = %query(name)
	If (txt [ "Alert") {
		Write $$$Text("Alert")
	}
	ElseIf (txt [ "Assert") {
		Write $$$Text("Assert")
	}
	ElseIf (txt [ "Error") {
		Write $$$Text("Error")
	}
	ElseIf (txt [ "Info") {
		Write $$$Text("Info")
	}
	ElseIf (txt [ "Trace") {
		Write $$$Text("Trace") _ $Case(%query("TraceCat"),"":"",$C(0):"",:"&nbsp;("_..EscapeHTML(%query("TraceCat"))_")")
	}
	ElseIf (txt [ "Warning") {
		Write $$$Text("Warning")
	}
	Quit $$$OK
}

/// Server-side method to write out the content for the SessionId column.
/// The main purpose is to ensure that links to the Visual Trace diagram are only included
/// for events which occurred as part of a session.
Method DrawSessionCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Set tSessionId = $get(%query("SessionId"))

	If tSessionId = "" {
		&html<&nbsp;>
	} Else {
		&html<<a class="sessionLink" title="#(..EscapeHTML(..sessionLinkTitle))#" onclick="zenPage.showTrace('#($ZCVT($ZCVT(tSessionId,"O","JS"),"O","HTML"))#',true,event); return false;">#(..EscapeHTML(tSessionId))#</a>>
	}
	Quit $$$OK
}

/// Server-side method to write out the content and SourceClass:SourceMethod() in the hover-text title.
Method DrawMethodCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	&html<<span title="#(..EscapeHTML(%query("SourceClass")_":"_%query("SourceMethod")_"()"))#" >#(..EscapeHTML(%query($S("Job"=name:name,1:"ConfigName"))))#</span>>
	Quit $$$OK
}

/// Server-side method to write out the event text both as content and in the hover-text title.
Method DrawTextCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Set tTxt=..EscapeHTML(%query("Text"))
	&html<<span title="#(tTxt)#" >#(tTxt)#</span>>
	Quit $$$OK
}

/// Server-side callback to provide data for the details table
ClassMethod DrawEventDetails(pSeed As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawEventInfo(pSeed,1,1)
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

/// User clicked the Purge button
ClientMethod startPurge() [ Language = javascript ]
{
	if (!this.canPurge) {
		alert(this.msgNotPermitted);
		return false;
	}
	var conf = $$$Text("Are you sure you want to purge the Event Log now?");
	var nan = $$$Text("Value entered for number of days is not a number.");
	var npos = $$$Text("Value entered for number of days is not a positive number.");
	var count = $$$Text("Number of records purged:");
	var fail = $$$Text("Event Log purge did not succeed:");

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
		if (ret === undefined || ret === null){ return true }; // Might not have permission if not called via startPurge
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

/// User clicked the Search button, user changed a Quick Search or Event Type criterion,
/// or we have completed a non-zero Purge.
ClientMethod onSearchHandler() [ Language = javascript ]
{
	zen("pageTotal").setValue(1);

	var table = this.getResultsTable();
	var where = "";

	var SortOrder = zen("SortOrder").getValue();

	// modify Select TimeExecuted based on Time Format
	var TimeFormat = zen('TimeFormat').getValue();
	zen('idTimeLogged12').setProperty('hidden',TimeFormat == '999');
	zen('idTimeLogged999').setProperty('hidden',TimeFormat == '12');

	// whereClause, orderByClause, and groupByClause
	var ConfigName = zen("ConfigName").value;
	var SourceClass = zen("SourceClass").value;
	var SourceMethod = zen("SourceMethod").value;
	var Text = zen("Text").value;
	var Job = zen("Job").value;

	var StartId = zen("StartId").value;
	var EndId = zen("EndId").value;
	var StartTime = zen("StartTime").value;
	var EndTime = zen("EndTime").value;
	var SessionId = zen("SessionId").value;

	var Assert = zen("Assert").value;
	var Error = zen("Error").value;
	var Warning = zen("Warning").value;
	var Info = zen("Info").value;
	var Trace = zen("Trace").value;
	var Alert = zen("Alert").value;

	var Defaults = ConfigName+","+SourceClass+","+SourceMethod+","+Text+","+Job+","+StartId+","+EndId+","+StartTime+","+EndTime+","+SessionId;
	var EventType = Assert+","+Error+","+Warning+","+Info+","+Trace+","+Alert;

	// call server method to build the where clause
	var where = zenPage.GetWhereClause(Defaults,EventType);
	table.whereClause = where;
	table.orderByClause = "%ID";

	if (SortOrder == "Newest First") table.orderByClause = "%ID desc";

	rows = zen('MaxRows');
	var MaxRows = parseInt(rows.value);
	if (MaxRows > 10000) MaxRows = 100;
	if (MaxRows < 0) MaxRows = 1;

	// Get the current expando state and save it
	var States = zenPage.expandoState();

	// Get the Auto-Refresh choice and save it
	var AutoRefresh = 'None';
	if (zenPage.enableAutoRefresh) {
		AutoRefresh = zen("chkRefresh").getValue();
	}

	// Save last selections to global as default for page
	zenPage.SaveDefaults(SortOrder,TimeFormat,Defaults,EventType,MaxRows,States,AutoRefresh);
}

/// Use with certain <text> fields so user can hit Enter to indicate that an entry in the field is done and ready to use
ClientMethod enterKey() [ Language = javascript ]
{
     if (zenEvent.keyCode == zenENTER) zenPage.doSearch();
}

/// Fill search criteria defaults
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If ..enableAutoRefresh {
		Set ..%GetComponentById("chkRefresh").hidden = 0
	}
	// get defaults and build up the initial display
	Do ..GetAndUseDefaults()
	Set ..matchSource="" ; clear initial criterion
	Quit $$$OK
}

Method GetSearchCriteria() As %String [ CodeMode = expression, Private ]
{
$get(^IRIS.Temp.EnsPortal($Username,"EventLog","SearchCriteria"),"Newest First^999^^1,1,1,1,1,1^500^0,0,0,0,0^1")
}

/// Method called from <method>%OnAfterCreatePage</method> to get defaults and build up the initial display
Method GetAndUseDefaults() As %String
{
	If ..matchSource '= "" {
		Do ..SetDefaultString("")
	}
	#; Get the last saved default values and use them as defaults.
	Set SearchCriteria = ..GetSearchCriteria()
	Set SortOrder = $P(SearchCriteria,"^",1)
	Set TimeFormat = $P(SearchCriteria,"^",2)
	Set TimeFormat = $case(TimeFormat, 999: 999, : 12)
	Set Defaults = $P(SearchCriteria,"^",3)
	Set EventType = $P(SearchCriteria,"^",4)
	Set MaxRows = $P(SearchCriteria,"^",5)
	Set expandoState = $P(SearchCriteria,"^",6)
	Set AutoRefresh = $P(SearchCriteria,"^",7)
	If '..enableAutoRefresh {
		Set AutoRefresh = "None"
	}

	#; Load defaults for Details
	Set ..%GetComponentById("SortOrder").value = SortOrder
	Set ..%GetComponentById("TimeFormat").value = TimeFormat
	Set ..%GetComponentById("MaxRows").value = MaxRows
	Set ..%GetComponentById("ConfigName").value = $S(""'=..matchSource:..matchSource, 1:$P(Defaults,",",1))
	Set ..%GetComponentById("SourceClass").value = $P(Defaults,",",2)
	Set ..%GetComponentById("SourceMethod").value = $P(Defaults,",",3)
	Set ..%GetComponentById("Text").value = $P(Defaults,",",4)
	Set ..%GetComponentById("Job").value = $P(Defaults,",",5)
	Set ..%GetComponentById("StartId").value = ..startId // the default is blank
	Set ..%GetComponentById("EndId").value = ..endId // the default is blank
	Set ..%GetComponentById("StartTime").value = $P(Defaults,",",8)
	Set ..%GetComponentById("EndTime").value = $P(Defaults,",",9)
	Set ..%GetComponentById("SessionId").value = $P(Defaults,",",10)

	#; Load defaults for Event Type
	Set ..%GetComponentById("Assert").value = $P(EventType,",",1)
	Set ..%GetComponentById("Error").value = $P(EventType,",",2)
	Set ..%GetComponentById("Warning").value = $P(EventType,",",3)
	Set ..%GetComponentById("Info").value = $P(EventType,",",4)
	Set ..%GetComponentById("Trace").value = $P(EventType,",",5)
	Set ..%GetComponentById("Alert").value = $P(EventType,",",6)

	#; Load Expando states
	Set ..%GetComponentById("expQuick").expanded = $P(expandoState,",",1)
	Set ..%GetComponentById("expInclude").expanded = $P(expandoState,",",2)
	Set ..%GetComponentById("expDetails").expanded = $P(expandoState,",",3) || (""=$P(Defaults,",",1) && (""'=..matchSource))
	Set ..%GetComponentById("expPurge").expanded = $P(expandoState,",",4)

	#; Load auto-refresh setting
	Set ..%GetComponentById("chkRefresh").value = AutoRefresh

	#; set up the table
	Set table = ..%GetComponentById("table")

	#; Where clause
	Set table.whereClause = ..GetWhereClause(Defaults,EventType)

	#; Order by clause
	Set table.orderByClause = "%ID"
	If SortOrder = "Newest First" {
		Set table.orderByClause = "%ID desc"
	}

	#; Load time preference
	Set ..%GetComponentById("idTimeLogged12").hidden = (TimeFormat = 999)
	Set ..%GetComponentById("idTimeLogged999").hidden = (TimeFormat = 12)

	#; Max Rows (Page Size)
	If (MaxRows > 10000) { Set MaxRows = 500 }
	If (MaxRows < 0) { Set MaxRows = 1 }
	Set table.maxRows = MaxRows
}

/// Called from <method>onSearchHandler</method> and
/// <method>%OnAfterCreatePage</method> to build the where clause.
Method GetWhereClause(Defaults, EventType) As %String [ ZenMethod ]
{
	Set where = ""
	Set tTypes = 0
	For p = 1:1:$L(EventType,",") {
		Set tInclude = $P(EventType,",",p)
		Set tInclude = $S(tInclude="true":1,tInclude="false":0,1:+tInclude)
		Set tTypes(p) = tInclude
		If tInclude { Set tTypes = tTypes + 1 }
	}
	#; Only include types if 1-5 types have been requested, as the Type index may be used to fulfil this part of the
	#; query when there are multiple conditions, and that is unnecessary when there is no filter on Type.
	If tTypes && (tTypes < 6) {
		#; Use TOP if there are conditions on any other indexed properties
		Set tEventNames = $lb("Assert","Error","Warning","Info","Trace","Alert")
		Set where = "TYPE " _ $select(tTypes = 1: "= ", 1: "IN (")
		Set tInList = ""
		For i=1:1:6 {
			If $get(tTypes(i)) { Set tInList = tInList _ $select(tInList = "": "", 1: ",")_"'"_$lg(tEventNames,i)_"'" }
		}
		Set where = where _ tInList _ $select(tTypes = 1: "", 1: ")")
	}

	Set ConfigName = $replace($S(""'=..matchSource:..matchSource, 1:$P(Defaults,",",1)),"'","''")
	Set SourceClass = $replace($P(Defaults,",",2),"'","''")
	Set SourceMethod = $replace($P(Defaults,",",3),"'","''")
	Set Text = $replace($P(Defaults,",",4),"'", "''")
	Set Job = $replace($P(Defaults,",",5),"'","''")
	Set StartId = $replace($P(Defaults,",",6),"'","''")
	Set EndId = $replace($P(Defaults,",",7),"'","''")
	Set StartTime = $replace($P(Defaults,",",8),"'","''")
	Set EndTime = $replace($P(Defaults,",",9),"'","''")
	Set SessionId = $replace($P(Defaults,",",10),"'","''")

	If ((StartId '= "") && (EndId '= "") && (EndId < StartId)) {
		Set temp = StartId
		Set StartId = EndId
		Set EndId = temp
	}
	If (StartId '= "") Set where = where _ $S(where'="":" AND ",1:"") _ "%ID >= '" _ StartId _ "'"
	If (EndId '= "") Set where = where _ $S(where'="":" AND ",1:"") _ "%ID <= '" _ EndId _ "'"
	If ((StartTime '= "") && (EndTime '= "") && ($$$timeCmp(EndTime,StartTime) < 0)) {
		Set temp = StartTime
		Set StartTime = EndTime
		Set EndTime = temp
	}
	If (StartTime '= "") Set where = where _ $S(where'="":" AND ",1:"") _ "TimeLogged >= '" _ StartTime _ "'"
	If (EndTime '= "") && (EndTime '[ ".999") Set EndTime = EndTime_".999"
	If (EndTime '= "") Set where = where _ $S(where'="":" AND ",1:"") _ "TimeLogged <= '" _ EndTime _ "'"
	If (SessionId '= "") Set where = where _ $S(where'="":" AND ",1:"") _ "SessionId = '" _ SessionId _ "'"
	If (ConfigName [ "%") {
		Set where = where _ $S(where'="":" AND ",1:"") _ "ConfigName LIKE '" _ ConfigName _ "'"
	} ElseIf (ConfigName '= "") {
		Set where = where _ $S(where'="":" AND ",1:"") _ "ConfigName = '" _ ConfigName _ "'"
	}
	If (SourceClass [ "%") {
		Set where = where _ $S(where'="":" AND ",1:"") _ "SourceClass LIKE '" _ SourceClass _ "'"
	} ElseIf (SourceClass '= "") {
		Set where = where _ $S(where'="":" AND ",1:"") _ "SourceClass = '" _ SourceClass _ "'"
	}
	If (SourceMethod [ "%") {
		Set where = where _ $S(where'="":" AND ",1:"") _ "SourceMethod LIKE '" _ SourceMethod _ "'"
	} ElseIf (SourceMethod '= "") {
		Set where = where _ $S(where'="":" AND ",1:"") _ "SourceMethod = '" _ SourceMethod _ "'"
	}
	If (Job'= "") Set where = where _ $S(where'="":" AND ",1:"") _ "Job = '" _ Job _ "'"
	If (Text'= "") Set where = where _ $S(where'="":" AND ",1:"") _ "Text [ '" _ Text _ "'"
	Quit where
}

/// Callback that is executed when creating the resultset for the main table.
/// The method's main purpose is to determine whether the <query>MultiType</query> class query
/// should be used in cases where we have the following:
/// <ul><li>more than one Type selected,</li>
/// <li>not all Types selected, and</li>
/// <li>no conditions on other indexed fields</li></ul>
/// When all of these conditions are met, we hand off responsibility for the data retrieval to the class query.
Method CheckConditions(Output pSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Do:..#CANCANCELSEARCH ..PrepareCancel()
	Set pSC = $$$OK
	Set tRS = ""
	Set tIndexCount = 0

	Set tSearchCriteria = ..GetSearchCriteria()
	Set tDefaults = $P(tSearchCriteria,"^",3)
	Set tConfigName = $S(""'=..matchSource:..matchSource, 1:$P(tDefaults,",",1))
	If (tConfigName '= "") {
		Set tIndexCount = tIndexCount + 1
	}

	Set tStartTime = $P(tDefaults,",",8)
	Set tEndTime = $P(tDefaults,",",9)
	If (tStartTime '= "") || (tEndTime '= "") {
		Set tIndexCount = tIndexCount + 1
	}

	Set tEventTypes = $P(tSearchCriteria,"^",4)
	Set tTypeCount = 0
	If tIndexCount = 0 {
		Set tEventNames = $lb("Assert","Error","Warning","Info","Trace","Alert")
		Set tTypes = ""
	}
	For i=1:1:6 {
		Set tInclude = $P(tEventTypes,",",i)
		If $S(tInclude="true":1,tInclude="false":0,1:tInclude) {
			Set tTypeCount = tTypeCount + 1
			If tIndexCount = 0 Set tTypes = tTypes _ $listbuild($listget(tEventNames,i))
		}
	}
	If tTypeCount && (tTypeCount < 6) {
		Set tIndexCount = tIndexCount + 1
		If (tTypeCount > 1) && (tIndexCount = 1) {
			Set tRS = ##class(%Library.ResultSet).%New("EnsPortal.EventLog:MultiType")
			#; Get inclusive StartID and EndID values
			Set tStartID = $piece(tSearchCriteria,",",6)
			Set tEndID = $piece(tSearchCriteria,",",7)
			If (tStartID && tEndID) && (tEndID < tStartID) {
				Set tTempID = tStartID
				Set tStartID = tEndID
				Set tEndID = tTempID
			}
			Set tMinID = $select(tStartID: tStartID-1, 1: "")
			Set tMaxID = $select(tEndID: tEndID+1, 1: "")
			#; Ensure that we check the table's sql to see whether there is any paging based on a condition on "ID"
			#; This is OK (for now) because the main StartID and EndID restrictions use conditions on "%ID"
			Set tTable = ..%GetComponentById("table")
			If $IsObject(tTable) && (tTable.sql '= "") {
				Set tModifiers = $piece(tTable.sql," FROM Ens_Util.Log",2)
				If (tModifiers '= "") && (tModifiers [ " WHERE ") {
					Set tWhere = $piece($piece(tModifiers," ORDER BY ID",1),"WHERE ",2)
					If (tWhere '= "") {
						For i=1:1:$length(tWhere," AND ") {
							#; remove trailing whitespace so the value is at end
							Set tCondition = $zstrip($piece(tWhere," AND ",i),">W")
							Set tProp = $piece(tCondition," ",1)
							If (tProp = "ID") {
								Set tOp = $piece($piece(tCondition,tProp_" ",2)," ",1)
								Set tVal = $piece(tCondition," ",*)
								If (tOp = "<") {
									Set tMaxID = $select(tVal = "": tMaxID, tMaxID = "": tVal, tMaxID < tVal: tMaxID, 1: tVal)
								}
								ElseIf (tOp = ">") {
									Set tMinID = $select(tVal = "": tMinID, tMinID = "": tVal, tMinID > tVal: tMinID, 1: tVal)
								}
							}
						}
					}
				}
			}
			Set tConditions = ##class(%ZEN.proxyObject).%New()
			Set tDisplayConditions = ""
			If (tMinID) {
				Set tConditions.MinID = tMinID
				Set tDisplayConditions = tDisplayConditions _ $LB("ID > "_tMinID)
			}
			If (tMaxID) {
				Set tConditions.MaxID = tMaxID
				Set tDisplayConditions = tDisplayConditions _ $LB("ID < "_tMaxID)
			}
			Set tDisplayConditions = tDisplayConditions _ $LB("Type IN ('"_$LTS(tTypes,"','")_"')")
			// Pick up any other restrictions
			Set tConditions.SourceClass = $piece(tDefaults,",",2)
			If (tConditions.SourceClass '= "") {
				Set tDisplayConditions = tDisplayConditions _ $LB("SourceClass LIKE '"_tConditions.SourceClass_"'")
			}
			Set tConditions.SourceMethod = $piece(tDefaults,",",3)
			If (tConditions.SourceMethod '= "") {
				Set tDisplayConditions = tDisplayConditions _ $LB("SourceMethod LIKE '"_tConditions.SourceMethod_"'")
			}
			Set tConditions.Text = $piece(tDefaults,",",4)
			If (tConditions.Text '= "") {
				Set tDisplayConditions = tDisplayConditions _ $LB("Text [ '"_tConditions.Text_"'")
			}
			Set tConditions.Job = $piece(tDefaults,",",5)
			If (tConditions.Job '= "") {
				Set tDisplayConditions = tDisplayConditions _ $LB("Job = '"_tConditions.Job_"'")
			}
			Set tConditions.SessionID = $piece(tDefaults,",",10)
			If (tConditions.SessionID '= "") {
				Set tDisplayConditions = tDisplayConditions _ $LB("SessionID = '"_tConditions.SessionID_"'")
			}
			Set tDescending = $select($piece(tSearchCriteria,"^",1) = "Newest First": 1, 1: 0)
			Set tDisplayConditions = tDisplayConditions _ $LB($select(tDescending: "DESC", 1: "ASC"))
			Set pSC = tRS.Execute($listtostring(tTypes),tDescending,,tConditions)
			If $$$ISERR(pSC) Quit ""
			Set pInfo.queryText = "EnsPortal.EventLog:MultiType class query; " _ $LTS(tDisplayConditions,"; ")
			Set pInfo.queryExecuted = 1
			Quit tRS
		}
	}

	Set tMaxRows = 0
	If (tIndexCount > 1) {
		Set tMaxRows = $P(tSearchCriteria,"^",5)
		If (tMaxRows = "") Set tMaxRows = 500
	}
	Set pInfo.rows = tMaxRows

	Quit tRS
}

Method GetColumnsAndFrom(timeFormat As %String) As %String
{
	Quit "ID,{fn RIGHT(%EXTERNAL(TimeLogged),999)} TimeLogged999,{fn RIGHT(%EXTERNAL(TimeLogged),12)} TimeLogged12,Type,SessionId,Job,ConfigName,Text,TraceCat,SourceClass,SourceMethod FROM Ens_Util.Log "
}

/// Reset the "Search Events By..." form fields to blank, reset other fields to defaults
ClientMethod formReset() [ Language = javascript ]
{
	var conftext = $$$Text("Reset to default values?")
	if (confirm(conftext)) {
		var table = zenPage.getResultsTable();

		// empty out the fields in the form
		zen("searchForm").reset();

		// Restore default values to fields outside the "Search Events By..." area
		zen("SortOrder").setValue("Newest First");
		zen("TimeFormat").setValue("999");
		zen("MaxRows").setValue(500)
		zen("chkRefresh").setValue("None");
		zen("keepDays").setValue(7);
		zen("pageTotal").setValue(1);

		// set current count
		zenPage.countReset();

		// refresh the display
		zenPage.doSearch();
	}
	return true;
}

/// Reset the current count of Event Log entries
ClientMethod countReset() [ Language = javascript ]
{
	zen("logTotal").setValue(zenPage.GetCount());
}

ClientMethod onAfterPageChange() [ Language = javascript ]
{
	// make it easy to navigate
	zenSetProp("expQuick","expanded",true);

	return true;
}

ClassMethod GetCount() As %Integer [ ZenMethod ]
{
	Quit ##class(Ens.Purge).EventLogCount()
}

/// Perform the purge operation and if there is an error, return the message
/// to JavaScript by prepending the message with a '-'. If no error then
/// return the zero or positive number of entries deleted, as a string.
ClassMethod DoPurge(keep As %Integer) As %String [ ZenMethod ]
{
	Set LogsDeleted = 0
	Set status = ##class(Ens.Purge).PurgeEventLogsByDate(keep,.LogsDeleted)
	If ($$$ISERR(status)) {
		Quit "-" _ $ZCVT($System.Status.GetErrorText(status),"O","JS")
		}
	Else {
		Quit LogsDeleted
	}
}

/// Build the current expando state into a string concatenated with commas
ClientMethod expandoState() [ Language = javascript ]
{
	var expandoState = zen("expQuick").getProperty("expanded");
	expandoState = expandoState + "," + zen("expInclude").getProperty("expanded");
	expandoState = expandoState + "," + zen("expDetails").getProperty("expanded");
	expandoState = expandoState + "," + zen("expPurge").getProperty("expanded");
	return expandoState;
}

/// Save user's last search criteria into global for page default
ClassMethod SaveDefaults(SortOrder, TimeFormat, Defaults, EventType, MaxRows, States, AutoRefresh) [ ZenMethod ]
{
	For p = 1:1:$L(EventType,",") Set pv=$P(EventType,",",p),$P(EventType,",",p) = $S(pv="true":1,pv="false":0,1:pv)
	For p = 1:1:$L(States,",") Set pv=$P(States,",",p),$P(States,",",p) = $S(pv="true":1,pv="false":0,1:pv)
	Set AutoRefresh = $S(AutoRefresh="true":1,AutoRefresh="false":0,1:AutoRefresh)
	Do ..SetDefaultString(SortOrder_"^"_TimeFormat_"^"_Defaults_"^"_EventType_"^"_MaxRows_"^"_States_"^"_AutoRefresh)
}

ClassMethod SetDefaultString(pDefaults As %String = "") [ Private ]
{
	If pDefaults = "" {
		Kill ^IRIS.Temp.EnsPortal($username,"EventLog","SearchCriteria")
	}
	Else {
		Set ^IRIS.Temp.EnsPortal($username,"EventLog","SearchCriteria") = pDefaults
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
	Quit $$$Text("Event Log")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set n = 0
	Set pCommands($I(n)) = $LB("searchButton",$$$Text("Search"),$$$Text("Search the Event Log using the current criteria"),"zenPage.doSearch();")
	Set:..#CANCANCELSEARCH pCommands($I(n)) = $LB("cancelButton",$$$Text("Cancel"),$$$Text("Cancel current search"),"zenPage.cancelSearch(); return false;")
	Set pCommands($I(n)) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the Event Log search criteria to their default values"),"zenPage.formReset();")
	Set pCommands($I(n)) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false);")
	Set pCommands($I(n)) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true);")
	Set pCommands($I(n)) = $LB("exportButton",$$$Text("Export"),$$$Text("Export selected entries to a file with extension .csv (tab delimited) or .xml or .txt or .html. Limited to 50000 entries"),"zenPage.exportToFile();")
	Quit $$$OK
}

/// Add export refresh icon
Method OnDrawRibbon() As %Status
{
	// allow for manual refresh
	If '..enableAutoRefresh {
		Set tRefresh = $$$TextHTML("Get Event log Export Status")
		&html<
		<td nowrap style="padding-left:50px;">
		<image hidden="true" id="refreshExport" src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.doExportStatus();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
		</td>
		<td nowrap style="padding-left:5px;padding-right:50px;"></td>>
	}
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
		} else { // get new content from server
			detail.setContent(""); // clear out any lingering content from before
			detail.seed = this.selectedId;
			detail.refreshContents(true);
			this._oldRows[this.selectedId] = detail.getEnclosingDiv().innerHTML;
		}
		detail.setHidden(false);
	}
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
	// always execute search here, as initialExecute is false for the table,
	// and we need to ensure that the rest of the page can be loaded
	zenPage.doSearch();
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"DoPurge": "%Ens_Purge:USE",
				: "")
}

/// This callback is called at the end of the HTML HEAD section of the page.<br/>
/// (default implementation is a simple expression).
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Quit ##class(EnsPortal.Utils).DrawEventInfoStyle()
}

/// Adjust sizes of components on the page.
/// Do this differently for Event Log than for other children of EnsPortal.Template.viewerPage (hence the override).
/// In this case the details pane does NOT get large when the search pane is minimized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		var searchPanel = zen('searchGroup');
		var results = zenPage.getResultsTable();
		var detailsPanel = zen('detailsPanel');
		var divSearchPanel = searchPanel.getEnclosingDiv();
		var divResults = results.getEnclosingDiv();
		var divDetailsPanel = detailsPanel.getEnclosingDiv();
		var divDetailsGroup = zen('detailsGroup').getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 15;

		divResults.style.height = hgt + 'px';
		divSearchPanel.style.height = hgt + 'px';
		divDetailsPanel.style.height = (hgt - 30) + 'px';
		divDetailsGroup.style.height = hgt + 'px';

		var searchWidth = divSearchPanel.offsetWidth;
		var detailExpanderWidth = 0;
		var detailExpander = zen('detailExpander');
		if (detailExpander) {
			detailExpanderWidth = detailExpander.getEnclosingDiv().offsetWidth + 10 + (zenIsIE * 12);
		}
		if (!this.detailsHidden) {
			var detailsWidth = parseInt(this.detailsWidth / 100 * winWidth, 10);
			divDetailsGroup.style.width = detailsWidth + 'px';
			divDetailsPanel.style.width = detailsWidth - detailExpanderWidth - 15 - (zenIsIE * 5) + 'px';
		}
		else {
			divDetailsGroup.style.width = detailExpanderWidth + 'px';
		}
		var innerSearchWidth = searchWidth;
		if (divSearchPanel.children && (divSearchPanel.children.length == 1)) {
			var searchPanelContentTable = divSearchPanel.children.item(0);
			if (searchPanelContentTable) {
				innerSearchWidth = searchPanelContentTable.offsetWidth;
			}
		}
		divSearchPanel.style.width = innerSearchWidth + 'px';

		var resultsWidth = winWidth - divSearchPanel.offsetWidth - divDetailsGroup.offsetWidth;
		resultsWidth = (resultsWidth <= 0 ? 1 : resultsWidth);
		var extraResults = 0;
		divResults.style.width = resultsWidth + extraResults + 'px';

		this.updatePageNumber();
		this.adjustExpanderText();

		if (load) { // ensure we update the navigation buttons after first load
			this.updateNavigationButtons();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

Query MultiType(pTypes As %String = "", pDescending As %Boolean = 0, pSelectMode As %Integer = 2, pConditions As %ZEN.proxyObject = "") As %Query(CONTAINID = 2, ROWSPEC = "Type:Ens.DataType.LogType,ID:%String,TimeLogged:%String,SessionId:%String,Job:%String,ConfigName:%String,Text:%String,TraceCat:%String,SourceClass:%String,SourceMethod:%String,TimeLogged999:%String,TimeLogged12:%String")
{
}

ClassMethod MultiTypeExecute(ByRef qHandle As %Binary, pTypes As %String = "", pDescending As %Boolean = 1, pSelectMode As %Integer = 2, pConditions As %ZEN.proxyObject = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tOrder = $select(pDescending: "DESC", 1: "ASC")
		Set qHandle("dir") = $select(pDescending: -1, 1: 1)
		Set tInStatement = ##class(%SQL.Statement).%New()
		Set tInStatement.%SelectMode = 0
		Set tInSQL = "SELECT ID FROM Ens_Util.Log WHERE Type = ? "
		Set tArgs = 0
		If $IsObject(pConditions) {
			If (pConditions.MinID '= "") {
				Set tInSQL = tInSQL _ "AND ID > ? "
				Set tArgs = tArgs + 1
				Set tArgs(tArgs) = pConditions.MinID
			}
			If (pConditions.MaxID '= "") {
				Set tInSQL = tInSQL _ "AND ID < ? "
				Set tArgs = tArgs + 1
				Set tArgs(tArgs) = pConditions.MaxID
			}
		}
		Set tInSQL = tInSQL _ "ORDER BY ID "_tOrder
		Set tStatus = tInStatement.%Prepare(tInSQL)
		If $$$ISERR(tStatus) Quit
		Set tMainStatement = ##class(%SQL.Statement).%New()
		Set tMainStatement.%SelectMode = pSelectMode
		Set tMainSQL = "SELECT Type,ID,TimeLogged,SessionId,Job,ConfigName,Text,TraceCat,SourceClass,SourceMethod FROM Ens_Util.Log WHERE ID = ?"
		Set qHandle("mainArgs") = 0
		Set tSpecialConditions = ""
		If $IsObject(pConditions) {
			If (pConditions.Job '= "") {
				Set tSpecialConditions = tSpecialConditions _ $LB("Job = ?")
				Set qHandle("mainArgs") = qHandle("mainArgs") + 1
				Set qHandle("mainArgs",qHandle("mainArgs")) = pConditions.Job
			}
			If (pConditions.SessionID '= "") {
				Set tSpecialConditions = tSpecialConditions _ $LB("SessionId = ?")
				Set qHandle("mainArgs") = qHandle("mainArgs") + 1
				Set qHandle("mainArgs",qHandle("mainArgs")) = pConditions.SessionID
			}
			If (pConditions.SourceClass '= "") {
				Set tSpecialConditions = tSpecialConditions _ $LB("SourceClass LIKE ?")
				Set qHandle("mainArgs") = qHandle("mainArgs") + 1
				Set qHandle("mainArgs",qHandle("mainArgs")) = pConditions.SourceClass
			}
			If (pConditions.SourceMethod '= "") {
				Set tSpecialConditions = tSpecialConditions _ $LB("SourceMethod LIKE ?")
				Set qHandle("mainArgs") = qHandle("mainArgs") + 1
				Set qHandle("mainArgs",qHandle("mainArgs")) = pConditions.SourceMethod
			}
			If (pConditions.Text '= "") {
				Set tSpecialConditions = tSpecialConditions _ $LB("Text [ ?")
				Set qHandle("mainArgs") = qHandle("mainArgs") + 1
				Set qHandle("mainArgs",qHandle("mainArgs")) = pConditions.Text
			}
		}
		If $LL(tSpecialConditions) {
			Set tMainSQL = tMainSQL _ " AND " _ $LTS(tSpecialConditions," AND ")
		}
		Set tStatus = tMainStatement.%Prepare(tMainSQL)
		If $$$ISERR(tStatus) Quit
		Set qHandle("mainStmt") = tMainStatement
		Set tTypeCount = $length(pTypes,",")
		Set qHandle = 0
		For i=1:1:tTypeCount {
			Set tType = $piece(pTypes,",",i)
			If (tType '= "") && '##class(Ens.DataType.LogType).IsValid(tType) {
				Set tType = ##class(Ens.DataType.LogType).DisplayToLogical(tType)
			}
			If (tType '= "") && ##class(Ens.DataType.LogType).IsValid(tType) {
				Set tRS = tInStatement.%Execute(tType,tArgs...)
				If tRS.%Next() {
					Set qHandle = qHandle + 1
					Set qHandle("rs",qHandle) = tRS
					Set qHandle("next",tRS.ID) = qHandle
				}
			}
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

ClassMethod MultiTypeClose(ByRef qHandle As %Binary) As %Status
{
	Quit $$$OK
}

ClassMethod MultiTypeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set Row = ""
		While (Row = "") {
			Set tNextID = $order(qHandle("next",""),qHandle("dir"),tRSPos)
			If tNextID = "" {
				Set AtEnd = 1
				Quit
			}
			Kill qHandle("next",tNextID)
			Merge tMainArgs = qHandle("mainArgs")
			Set tDataRS = qHandle("mainStmt").%Execute(tNextID,tMainArgs...)
			If tDataRS.%Next() {
				Set Row = $lb(tDataRS.Type,tDataRS.ID,tDataRS.TimeLogged,tDataRS.SessionId,tDataRS.Job,tDataRS.ConfigName,tDataRS.Text,tDataRS.TraceCat,tDataRS.SourceClass,tDataRS.SourceMethod,tDataRS.TimeLogged,$piece(tDataRS.TimeLogged," ",2))
			}
			Set tCurrRS = qHandle("rs",tRSPos)
			If tCurrRS.%Next() {
				Set qHandle("next",tCurrRS.ID) = tRSPos
			}
			Else {
				Kill qHandle("rs",tRSPos)
			}
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

ClientMethod exportToFile() [ Language = javascript ]
{
	/* Check if any selected for export */
	var table = zen('table'); //this.getResultsTable();
	var sel = table.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			found++;
			break;
		}
	}
	if (found == 0) {
		alert($$$Text('Please select one or more log entries to export.'));
		return false;
	}

	var parms = {
		SRVDIR:zenPage.GetDefaultDir(),
		SRVWILD:'*.csv,*.txt',
		LCLDEFAULT:'eventlog.csv',
		SHOWCHARSET:false,
		EXPINFO:$$$Text('Select the location and name for the export file that contains the event logs.')+' '+$$$Text('File extension specifies the format: csv, txt, xml or html.')
		};
	var url = zenLink('EnsPortal.Dialog.fileSelect.zen',this.studioMode);
	zenPage.launchPopupWindow(url,this.addPopupSuffix('exportToFile'),'status,scrollbars,resizable,width=660,height=700',parms);
}

/// This client event, if present, is fired when a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'exportToFile':
			if (action == 'ok') {
				var valueArray=value.split('\0');
				if (valueArray[0]=='SERVER') {
					//fileSelect dialog ought to have prevented this.
					if (!this.canViewFileSystem) {
						alert(this.msgNotPermitted);
						return;
					}
					var fileExists = zenPage.FileExists(valueArray[1]);
					if (fileExists != 0) {
						var ok = confirm($$$FormatText($$$Text("Are you sure you want to overwrite %1?"),valueArray[1]));
						if (!ok) {
							return;
						}
					}
					if (valueArray[1]!='') zenPage.SetDefaultDir(valueArray[1]);
				}
			}
			var status = zenPage.doExportToFile(value);
			break;
		case 'switchNamespace': // change namespace but keep the same page
			zenPage.changeURLNamespace(value);
			break;
	}
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "EventExportDir"),$$$FileNormalizeDirectory(##class(%Stream.FileBinary).DefaultStreamDir(1)))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "EventExportDir") = ##class(%File).GetDirectory(pPathname, 1)
}

Method FileExists(pFilename) As %Boolean [ ZenMethod ]
{
	Quit (##class(%File).Exists(pFilename)&&'##class(%File).DirectoryExists(pFilename))
}

Method GetDirectory(pFilename) As %String [ ZenMethod ]
{
	Quit ##class(%File).GetDirectory(pFilename,1)
}

Method GetFilename(pFilename) As %String [ ZenMethod ]
{
	Quit ##class(%File).GetFilename(pFilename)
}

ClientMethod doExportToFile(value) [ Language = javascript ]
{
	// Get the values and find out how many
	try {
		var table = this.getResultsTable();
		var sel = table.selectedRows.split(',');
		var len = sel.length;
		var found = 0;
		var val = "";
		var Defaults = "";
		var EventType = "";
		for (i=0; i<len; i++) {
			if (sel[i] != "") {
				if (found > 0) val += ',';
				val += sel[i];
				found++;

			}
		}
		var exportSQL = "";
		if // Ask about exporting more than are shown on the page
		   ((found == table.maxRows) &&
			(table.rowCount.indexOf('+') > 0) &&
			(confirm($$$Text('More event log entries match your search criteria than appear here. ') + '\n' +
							$$$Text('If you want to export all the log entries that match your criteria, including those not shown on this page, click OK.') + '\n' +
							$$$Text('To export only your selected log entries on this page, click Cancel.')))) {

					// whereClause, orderByClause, and groupByClause
					var ConfigName = zen("ConfigName").value;
					var SourceClass = zen("SourceClass").value;
					var SourceMethod = zen("SourceMethod").value;
					var Text = zen("Text").value;
					var Job = zen("Job").value;

					var StartId = zen("StartId").value;
					var EndId = zen("EndId").value;
					var StartTime = zen("StartTime").value;
					var EndTime = zen("EndTime").value;
					var SessionId = zen("SessionId").value;

					var Assert = zen("Assert").value;
					var Error = zen("Error").value;
					var Warning = zen("Warning").value;
					var Info = zen("Info").value;
					var Trace = zen("Trace").value;
					var Alert = zen("Alert").value;

					Defaults = ConfigName+","+SourceClass+","+SourceMethod+","+Text+","+Job+","+StartId+","+EndId+","+StartTime+","+EndTime+","+SessionId;
					EventType = Assert+","+Error+","+Warning+","+Info+","+Trace+","+Alert;
					val = "";
		}

		var SortOrder = zen("SortOrder").getValue();

		valueArray = value.split('\0');

		this._exportLocation=valueArray[0];


		if (this._exportLocation=='BROWSER') {
			streamFilenameForExport = '\0'+valueArray[1];
		} else {
			streamFilenameForExport = valueArray[1];
		}
		this._serverFile=streamFilenameForExport;

		// run the background task
		var ret = this.DoExportInBackground(streamFilenameForExport,SortOrder,val,Defaults,EventType);
		if (ret != 1) {
			// report the error
			alert(ret);
		}
		if (!zenPage.enableAutoRefresh) {
			var refreshIcon = self.document.getElementById('refreshExport');
			if (refreshIcon) {
				refreshIcon.hidden=false;
			}
			zenPage.doExportStatus();
		}
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in doExportToFile');
	}
}

/// Save ID values for Resend.
ClassMethod DoExportInBackground(filename As %String = "", sortOrder As %String = "", val As %String = "", Defaults As %String = "", EventType As %String = "") As %String [ ZenMethod ]
{
	#; Don't allow export if not allowed to view file System of server - protect against filename change.
	If '$system.Security.Check("%Ens_ViewFileSystem","USE") && ($E(filename)'=$C(0)) {
		Quit $System.Status.Error($$$GeneralError,"Not permitted to create export file on server.")
	}
	#dim tSC As %Status = $$$OK
	#dim tSQLGenerators = $LB(sortOrder,val,Defaults,EventType,"","")
	Set tSC = ..%RunBackgroundMethod("DoExport",filename,tSQLGenerators)
	If $$$ISERR(tSC) {
		Quit $$$StatusDisplayString(tSC)
	}
	Else {
		Quit 1
	}
}

ClassMethod DoExport(pFilename As %String, pSQLGenerators As %String = "") As %String [ Internal ]
{
	#dim tSC As %Status = $$$OK
	if pSQLGenerators = "" Quit tSC

	#dim tStatement As %SQL.Statement
	#dim tResult As %SQL.StatementResult
	#dim tExtension As %String = ""
	#dim tFormat AS %String = -1
	#dim tFormatToUse As %String = 100
	#dim e As %Exception.AbstractException
	#dim tMsg As %String = ""
	#dim tSelect, tCountSQL As %String = ""
	#dim tCount As %Integer
	#dim tLimit As %Integer = 50000
	#dim tMessages As %SQL.Manager.Messages
	#dim tFilesUsed As %String

	#dim tGeneratedTempName As %Boolean = 0
	If $E(pFilename)=$C(0) {
		Set tGeneratedTempName = 1
		#dim tBrowserFilename = $E(pFilename,2,*)
		Set pFilename = ..GetTempFileName(pFilename)
	}
	Try {
		/* Test if valid directory for writing and valid file name - note actual filename may be slightly different*/
		If '##class(%File).Writeable(##class(%File).GetDirectory(pFilename,1)) {
			Set tSC = $System.Status.Error($$$GeneralError,"Export Directory is not writeable")
			Quit
		}
		If (pFilename'="")&&'##class(%File).Exists(pFilename) {
			Try {
				Open pFilename:"wns":1
				If '$Test {
					Set tSC = $System.Status.Error($$$GeneralError,"Unable to create export file. Check if filename valid.")
					Quit
				}
				Close pFilename
				Do ##class(%File).Delete(pFilename)
			} Catch {
					Set tSC = $System.Status.Error($$$GeneralError,"Unable to create export file.")
			}
		}
		If $$$ISERR(tSC) Quit
		/* End of valid filename test */
		Set tFormat("XML")=0,tFormat("HTML")=1,tFormat("TXT")=99,tFormat("CSV")=100

		/* Construct SQL */

		#dim tParameters
		#dim tSelectColumnsAndFrom = "SELECT TOP 50000 ID, TYPE, TIMELOGGED, SESSIONID AS SESSION, JOB, CONFIGNAME AS SOURCE, TEXT, SOURCECLASS AS CLASS, SOURCEMETHOD AS METHOD, $LISTTOSTRING(STACK) AS STACK FROM ENS_UTIL.LOG"

		#dim tFullParameterizedSQL = ..getParameterizedSQL(pSQLGenerators,tSelectColumnsAndFrom,.tParameters)

		Set tSelect = $P(tFullParameterizedSQL," FROM")
		Set tCountSQL = $REPLACE(tFullParameterizedSQL,tSelect,"SELECT COUNT(*) AS TOTAL")
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode = 2
		Set tSC = tStatement.%Prepare(tCountSQL)
		If $$$ISERR(tSC) Quit
		Set tResult = tStatement.%Execute(tParameters...)
		If tResult.%SQLCODE {
			Set tSC = $$$ERROR($$$SQLError,tResult.%SQLCODE,tResult.%Message)
			Quit
		}
		If tResult.%Next() Set tCount = tResult.TOTAL
		If tCount > tLimit Set tCount = tLimit
		Set tMsg = $$$FormatTextJS("Exporting %1 Event log entries",tCount)
		Do ..%SetBackgroundMethodStatus(tMsg)

		Set tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode = 2
		Set tSC = tStatement.%Prepare(tFullParameterizedSQL)
		If $$$ISERR(tSC) Quit
		Set tResult = tStatement.%Execute(tParameters...)
		If tResult.%SQLCODE {
			Set tSC = $$$ERROR($$$SQLError,tResult.%SQLCODE,tResult.%Message)
		} Else {
			Set tExtension = $ZCVT($P(pFilename,".",*),"U")
			If tExtension = "" {
				Set tFormatToUse = 100
				Set pFilename=""
			} Else {
				Set tFormatToUse = $G(tFormat(tExtension),tFormat)
				If tFormatToUse = -1 {
					Set tFormatToUse = 100
				} Else {
					Set pFilename = $P(pFilename,".",1,*-1)
				}
			}
			Do tResult.%DisplayFormatted(tFormatToUse,pFilename,.tMessages,.tFilesUsed)

			If tMessages.%Next() {
				If tMessages.Message[" row(s) affected." {
					Set tMsg = $$$FormatTextJS("Exported %1 Event log entries to file %2 ",tCount,$G(tFilesUsed(1)))
					If tGeneratedTempName {
						Set ^IRIS.Temp.EnsPortal.Data($NAMESPACE,$JOB,"EventLog","Export","TempFilename") = $Get(tFilesUsed(1))
						Set ^IRIS.Temp.EnsPortal.Data($NAMESPACE,$JOB,"EventLog","Export","BrowserFilename") = $Get(tBrowserFilename)
					}
				} Else {
					Set tMsg = $$$FormatTextJS("Export to file encountered error %1 ",tMessages.Message)
					If tMessages.%Next() {Set tMsg = tMsg _ $ZCVT("\n "_tMessages.Message,"O","JS")}
					Set ^IRIS.Temp.EnsPortal.Data($NAMESPACE,$JOB,"EventLog","Export","Errored")=""
				}
				Set ^IRIS.Temp.EnsPortal.Data($NAMESPACE,$JOB,"EventLog","Export")=tMsg
			}
		}
	} Catch e {Set tSC = e.AsStatus()}

	If $$$ISERR(tSC) {
		Set tMsg = $$$TextJS("Event Export error: ")_$ZCVT($system.Status.GetErrorText(tSC),"O","JS")
		Set ^IRIS.Temp.EnsPortal.Data($NAMESPACE,$JOB,"EventLog","Export")=tMsg
		Set ^IRIS.Temp.EnsPortal.Data($NAMESPACE,$JOB,"EventLog","Export","Errored")=""
	}

	Do ..%EndBackgroundMethod()
	Quit tSC
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	#dim tStatus As %String = ""
	Try {
		Set tStatus = $G(^IRIS.Temp.EnsPortal.Data($NAMESPACE,pTaskID,"EventLog","Export"))


		#; If Errored then do not want to try browser download.
		If $Data(^IRIS.Temp.EnsPortal.Data($NAMESPACE,$JOB,"EventLog","Export","Errored"))#2 {
			&js<
				alert('#(tStatus)#');
			>
		} Else {
			#dim tExportTempFilename = $Get(^IRIS.Temp.EnsPortal.Data($NAMESPACE,pTaskID,"EventLog","Export","TempFilename"))
			#dim tExportUserFilename = $Get(^IRIS.Temp.EnsPortal.Data($NAMESPACE,pTaskID,"EventLog","Export","BrowserFilename"))
			If tExportTempFilename '= "" {
				Set tStatus = ..DownloadStream(tExportTempFilename,tExportUserFilename)
			}
			If tStatus '= "" {
				&js<
					alert('#(tStatus)#');
				>
			}
		}

		Kill ^IRIS.Temp.EnsPortal.Data($NAMESPACE,pTaskID,"EventLog","Export")
		&js<
			if (!zenPage.enableAutoRefresh) {
				var refreshIcon = self.document.getElementById('refreshExport');
				if (refreshIcon) {
					refreshIcon.hidden=true;
				}
			}
		>
	} Catch {}
}

ClassMethod %OnMonitorBackgroundTask(pTaskID As %String, pStatus As %String, pPercentComplete As %Float)
{
	#dim tStatusWithRefresh = pStatus_" "_ $$$TextJS("Portal Auto Refresh is disabled. Click the Refresh icon to check export status.")
	&js<
		if (!zenPage.enableAutoRefresh) {
			alert('#(tStatusWithRefresh)#');
		} else {
			alert('#(pStatus)#');
		}
	>
}

/// Internal classMethod to generate a parameterized SQL query
ClassMethod getParameterizedSQL(pSQLGenerators As %ZEN.proxyObject = "", pSelectColumnsAndFrom As %String = "", Output pParameters) As %String [ Internal ]
{
	If pSQLGenerators = "" Quit ""
	If pSelectColumnsAndFrom = "" Quit ""

	// pParameters will be array of the data to pass to the ?
	#dim tCurrentParameterNumber As %Integer = 0
	#dim tParameterizedSQL = ""

	#dim tWhereClause = ""

	#dim tOrderByClause = "%ID asc"
	If ($LG(pSQLGenerators,1) = "Newest First") Set tOrderByClause = "%ID desc"

	#dim val = $LG(pSQLGenerators,2)
	If val '= "" {

		Set tParameterizedSQL = "%ID %INLIST ($LISTFROMSTRING(?))"
		Set pParameters = $Increment(pParameters)
		Set pParameters(pParameters)=val

	} Else {

		#dim Defaults = $LG(pSQLGenerators,3)
		#dim EventType = $LG(pSQLGenerators,4)
		#dim tMinID = $LG(pSQLGenerators,5)
		#dim tMaxID = $LG(pSQLGenerators,6)

		#dim tTypes = 0
		#dim i
		#dim tInclude
		#dim tInList

		For i = 1:1:$L(EventType,",") {
			Set tInclude = $P(EventType,",",i)
			Set tInclude = $S(tInclude="true":1,tInclude="false":0,1:+tInclude)
			Set tTypes(i) = tInclude
			If tInclude { Set tTypes = tTypes + 1 }
		}
		#; Only include types if 1-5 types have been requested, as the Type index may be used to fulfil this part of the
		#; query when there are multiple conditions, and that is unnecessary when there is no filter on Type.
		If tTypes && (tTypes < 6) {
			Set tParameterizedSQL = "TYPE %INLIST ($LISTFROMSTRING("
			Set tInList = ""
			/*
			1 = "Assert"
			2 = "Error"
			3 = "Warning"
			4 = "Info"
			5 = "Trace"
	`		6 = "Alert"
			*/
			For i=1:1:6 {
				If $get(tTypes(i)) { Set tInList = tInList _ $select(tInList = "": "", 1: ",")_i }
			}
			Set tParameterizedSQL = tParameterizedSQL _"'"_tInList_"'))"
		}

		#dim ConfigName = $P(Defaults,",",1)
		#dim SourceClass = $P(Defaults,",",2)
		#dim SourceMethod = $P(Defaults,",",3)
		#dim Text = $P(Defaults,",",4)
		#dim Job = $P(Defaults,",",5)

		#dim StartId = $P(Defaults,",",6)
		If tMinID '= "" Set StartId = tMinID
		#dim EndId = $P(Defaults,",",7)
		If tMaxID '= "" Set EndId = tMaxID

		#dim StartTime = $P(Defaults,",",8)
		#dim EndTime = $P(Defaults,",",9)
		#dim SessionId = $P(Defaults,",",10)

		If ((StartId '= "") && (EndId '= "") && (EndId < StartId)) {
			#dim temp = StartId
			Set StartId = EndId
			Set EndId = temp
		}
		If (StartId '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "%ID >= ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = StartId
		}
		If (EndId '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "%ID <= ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters)= EndId
		}
		If ((StartTime '= "") && (EndTime '= "") && ($$$timeCmp(EndTime,StartTime) < 0)) {
			Set temp = StartTime
			Set StartTime = EndTime
			Set EndTime = temp
		}
		If (StartTime '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "TimeLogged >= ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = StartTime
		}
		If (EndTime '= "") && (EndTime '[ ".999") Set EndTime = EndTime_".999"
		If (EndTime '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "TimeLogged <= ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = EndTime
		}
		If (SessionId '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "SessionId = ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = SessionId
		}
		If (ConfigName [ "%") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "ConfigName LIKE ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = ConfigName
		} ElseIf (ConfigName '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "ConfigName = ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = ConfigName
		}
		If (SourceClass [ "%") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "SourceClass LIKE ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = SourceClass
		} ElseIf (SourceClass '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "SourceClass = ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = SourceClass _ "'"
		}
		If (SourceMethod [ "%") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "SourceMethod LIKE ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = SourceMethod
		} ElseIf (SourceMethod '= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "SourceMethod = ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = SourceMethod _ "'"
		}
		If (Job'= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "Job = ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters)= Job
		}
		If (Text'= "") {
			Set tParameterizedSQL = tParameterizedSQL _ $S(tParameterizedSQL'="":" AND ",1:"") _ "Text [ ?"
			Set pParameters = $Increment(pParameters)
			Set pParameters(pParameters) = Text
		}
	}
	If tParameterizedSQL '= "" Set tWhereClause = "WHERE "_tParameterizedSQL

	Set tParameterizedSQL = pSelectColumnsAndFrom_" "_tWhereClause_" ORDER BY "_tOrderByClause

	Quit tParameterizedSQL
}

ClassMethod GetTempFileName(pDocName As %String = "") As %String [ ZenMethod ]
{
	Set ext = $P(pDocName,".",*)
	Quit ##class(%Library.File).TempFilename(ext)
}

ClassMethod DownloadStream(pExportTempFilename As %String = "", pDocName) As %String
{
	#dim tMsg = ""
	#dim tFilename
	#dim tSC = $$$OK
	Try {
		If (pExportTempFilename = "")||('##class(%Library.File).Exists(pExportTempFilename)) {
			Set tMsg = $$$FormatTextJS("Unable to download export via browser.")
			Quit
		}
		#; Check that the directory where the temporary file is as expected
		#dim tTestFilename = ..GetTempFileName()
		#dim tExpectedDirectory = ##class(%File).GetDirectory(tTestFilename)
		If ##class(%File).Exists(tTestFilename) Do ##class(%File).Delete(tTestFilename)
		If ##class(%File).GetDirectory(pExportTempFilename) '= tExpectedDirectory {
			Set tMsg = $$$FormatTextJS("Unable to download export via browser.")
			Quit
		}
		Set tStream = ##class(%FileBinaryStream).%New()
		Set tSC = tStream.LinkToFile(pExportTempFilename)
		If $$$ISERR(tSC) {
			Set tMsg = $$$FormatTextJS("Unable to link to temporary export file.")
			Quit
		}
		Do tStream.SetAttribute("ContentDisposition","attachment; filename="_pDocName)
		Set tSC = tStream.%Save()
		If $$$ISERR(tSC) {
			Set tMsg = $$$FormatTextJS("Unable to create download link.")
			Quit
		}
		#dim Oid = tStream.%Oid()
		&js<window.location="#url(%25CSP.StreamServer.cls?STREAMOID=#(..Encrypt(Oid))#)#";>
	} Catch {
		Set tMsg = $$$FormatTextJS("Unexpected error attempting download of export.")
	}

	Quit tMsg
}

/// This method calls server method to get current background event log export job status and update the UI
/// Used if auto refresh off
ClientMethod doExportStatus() [ Language = javascript ]
{
	if (this._bgTaskID) {
		zenPage.MonitorBackgroundTask(this._bgTaskID);
	}
	return;
}

}
