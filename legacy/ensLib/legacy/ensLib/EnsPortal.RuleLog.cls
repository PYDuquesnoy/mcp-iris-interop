/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUtil)

/// This is the RuleLog page of the ZEN application.
Class EnsPortal.RuleLog Extends (EnsPortal.Template.viewerPage, EnsPortal.Util.PageLinks) [ System = 4 ]
{

/// User needs USE permissions on the %Ens_RuleLog resource to view this page.
Parameter RESOURCE = "%Ens_RuleLog:USE";

/// User needs USE permissions on the %Ens_Purge resource to start a purge from this page.
Parameter EDITRESOURCE = "%Ens_Purge:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Rule Log";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES = "ensemble/Ensemble_Utils.js";

/// Indicate if can cancel search. This defines whether tempPortalNode is set.
Parameter CANCANCELSEARCH As BOOLEAN = 1;

/// Indicate if ought to create tempPortalNode when page created. Used by Cancel feature for example.
Parameter SETUPTEMPPORTALNODE As BOOLEAN = 1;

Property resultsTableId As %ZEN.Datatype.id [ InitialExpression = "table" ];

Property pageSizeId As %ZEN.Datatype.id [ InitialExpression = "MaxRows" ];

Property pageNumberId As %ZEN.Datatype.id [ InitialExpression = "pageTotal" ];

Property detailsWidth As %ZEN.Datatype.integer(MAXVAL = 80, MINVAL = 5) [ InitialExpression = 29 ];

Property canViewRules As %ZEN.Datatype.boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList("%Ens_Code:READ,%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ")} ];

Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageTrace","USE")} ];

Property msgDays As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Days")} ];

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
	width: 215px;
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
table.tpTable td.tpAction a {
	cursor: pointer;
	color: #3B84BC;
	text-decoration: none;
}
tr.tpSelected td.tpAction a {
	color: white;
	text-decoration: underline;
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

/// This XML block defines the contents of the table pane.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<tablePane id="table" 
    cellSpacing="2"
	dataSource="columns"
	tableName="Ens_Rule.Log"
	useSnapshot="false"
	showZebra="true"
	valueColumn="ExecutionID"
	maxRows="500"
	useKeys="true"
	showQuery="false"
	onselectrow="zenPage.selectItem(zenThis);"
	nowrap="true" 
	onmouseoverClass="tpMouseOver"
	OnCreateResultSet="CreateResultSet"
	onupdate="setTimeout('zenPage.onAfterSearch();',50);"
	unlockSession="true"
	showValueInTooltip="true"
	> 
<!-- provide header values for all columns so they can be localized -->
<!-- a unique number (the actual ID is unsuitable for sorting) -->
<column header="Execution" colName="ExecutionID" width="90" style="text-align:left;" 
        title="Order in which rules fired, called the Execution ID"/>
<!-- needed for the Trace link -->
<column header="Session" colName="SessionId" style="text-align:left;" width="90" 
       onclick="zenPage.showTrace('#(%query.SessionId)#',event); return false;" 
       title="Identifier for the session in which the rule fired"
        cellTitle="Click to view a visual trace of the session" />
<column header="Time Executed" colName="TimeExecutedStr" id="idTimeLogged" width="180" OnDrawCell="DrawTimeExecuted"
		title="Time the rule fired" />
<column header="Rule Name" colName="RuleName" width="320"
      onclick="zenPage.showRule('#(%query.RuleName)#',event); return false;"
	  title="Configured name of the rule"
        cellTitle="Click to view the definition of the rule that fired" />
<column header="Error?" colName="IsError" width="55" OnDrawCell="DrawYesNo" style="text-align:left;" 
	    title="Yes if the result was a rule error, otherwise No" />
<column header="Return Value" colName="ReturnValue" width="300" style="text-align:left;" 
	    title="Value returned by the rules engine for this rule" />
<condition id="condError" colName="IsError" predicate="EQ" value="1" cellStyle="background: pink; color: darkred; font-weight: bold;" targetCol="IsError"/>
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
<vgroup valign="top">
<select label="Sort Order" name="SortOrder" id="SortOrder" 
	   displayList="Newest First,Oldest First" valueList="Newest First,Oldest First" value="Newest First" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
<select label="Auto-Refresh" name="chkRefresh" id="chkRefresh" hidden="true"
	   displayList="None,30 Seconds,60 Seconds,2 Minutes,5 Minutes" valueList="None,30000,60000,120000,300000" 
	   value="None" showEmpty="false"
		onclick="zenPage.changeRefresh();"/>
<select label="Time Format" name="TimeFormat" id="TimeFormat" 
		displayList="Complete,Time Only" valueList="999,12" value="999" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
</vgroup>
<spacer width="5" />
<vgroup valign="top">
<select label="Page Size" name="MaxRows" id="MaxRows" 
		displayList="10,20,30,50,100,200,500,1000,2000"	valueList="10,20,30,50,100,200,500,1000,2000" 
		value="#(%page.pageSize)#" showEmpty="false"
 		 onchange="zenPage.doSearch();"/>
<text name="pageTotal" id="pageTotal" label="Page" size="2" readOnly="true" value="#(%page.currentPage)#"
	  title="Current page of the display table, based on Page Size and the current search criteria."/>
<checkbox name="Error" id="Error" caption="Errors" value="0" 
	onclick="zenPage.doSearch();" enclosingStyle="color:#404040;font-size:0.8em;padding-top:12px;"
	  title="If checked, find only rules that caused an error state" />
</vgroup>
</hgroup>
</expando>
<expando name="expDetails" id="expDetails" caption="Search Rules By..." expanded="true" 
		childIndent="16px" containerStyle="padding:10px 10px 0px 10px;" >
<dateText name="StartTime" id="StartTime" label="Start Time" size="18" showTime="true" />
<dateText name="EndTime" id="EndTime" label="End Time" size="18" showTime="true" />
<!-- the comboboxes are completed in OnAfterCreatePage -->
<combobox name="RuleName" id="RuleName" label="Rule Name" dropdownWidth="350px"
		editable="true" unrestricted="true"	size="18" hzScroll="true"
          title="Choose and enter values in these fields, then click the Search button." 	/>
<text name="SessionId" id="SessionId" label="Session Id" size="9" />
</expando>
<expando name="expPurge" id="expPurge" caption="Purge Rule Log" expanded="false" 
	    childIndent="18px" containerStyle="padding:10px 10px 0px 10px;" onexpand="zenPage.countReset();" >
<!--<spacer height="5"/>-->
<vgroup  containerStyle="padding-top:5px;">
<text name="logTotal" id="logTotal" label="Current Count" size="7" readOnly="true" value="" ondblclick="zenPage.countReset();"
	  title="Total number of Rule Log entries. To update, double-click the field."	 />
<spacer height="10"/>
<text name="keepDays" id="keepDays" label="Do Not Purge Most Recent" size="7" value="7" 
	  title="Set a value to avoid purging the most recent Rule Log entries."/>
<html containerStyle="font-size:0.8em;color:#404040;">#(%page.msgDays)#</html>
<spacer height="10"/>
<button controlClass="commandButton" caption="Purge" onclick="zenPage.startPurge();"
	    title="Start purging Rule Log entries."/>
</vgroup>
</expando>
</form>
</vgroup>
</pane>
}

/// This XML block defines the contents of the details pane.
XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
<vgroup valign="top">
<html id="dynaGrid" OnDrawContent="CreateDataSet" hidden="true" />
</vgroup>
</pane>
}

/// Server-side callback to provide localized string introducing the details table
Method GiveAdviceString(pSeed As %String) As %Status
{
	Write $$$Text("Click on a table row to show rule details")
	Quit $$$OK
}

/// Write out the formatted TimeExecuted value along with the unformatted value inside
/// a custom "timeexecuted" tag.
Method DrawTimeExecuted(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tTime = %query(pName)
	Set tFormat = $select($IsObject(..searchCriteria): ..searchCriteria.TimeFormat, 1: 999)
	Write ..EscapeHTML($extract(tTime,*-tFormat+1,*)),"<timeexecuted style=""display: none;"" fullTime=""",..EscapeHTML(tTime),"""/>"
	Quit $$$OK
}

/// Callback used to construct the query for the current page based on the values in <property>searchCriteria</property>.
/// The custom resultset creation is required to ensure that optimised queries are used to retrieve results.
Method CreateResultSet(Output pSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Do:..#CANCANCELSEARCH ..PrepareCancel()
	Set pSC = $$$OK
	Set tRS = ##class(%Library.ResultSet).%New()
	Set tRS.RuntimeMode = 2
	If 0 = +..searchCriteria.MaxRows Set ..searchCriteria.MaxRows = 500
	Set tSortOrder = $select(..searchCriteria.SortOrder = "Newest First": "DESC", 1: "ASC")
	Set tTop = "TOP "_ (..searchCriteria.MaxRows + 1)
	Set tWhere = ""
	Set tOrderBy = "%ID " _ tSortOrder
	Set tIDCol = "%ID As ExecutionID"
	
	If ..searchCriteria.RuleName '= "" {
		Set tWhere = tWhere _ $select(tWhere '= "": " AND", 1:"") _ " RuleName = '" _ $replace(..searchCriteria.RuleName,"'","''") _ "'"
	}
	If ..searchCriteria.SessionId '= "" {
		Set tWhere = tWhere _ $select(tWhere '= "": " AND", 1: "") _ " SessionId = '" _ $replace(..searchCriteria.SessionId,"'","''") _ "'"
	}
	
	#; Handle Time conditions; use page values only if the criteria include the time.
	If (..searchCriteria.StartTime '= "") || (..searchCriteria.EndTime '= "") {
		If (..searchCriteria.nextPageStartTime '= "") && (..searchCriteria.nextPageStartTime ]] ..searchCriteria.StartTime) {
			Set tChanged("StartTime") = ..searchCriteria.StartTime
			Set ..searchCriteria.StartTime = ..searchCriteria.nextPageStartTime
		}
		If (..searchCriteria.nextPageEndTime '= "") && ((..searchCriteria.EndTime ]] ..searchCriteria.nextPageEndTime) || (..searchCriteria.EndTime = "")) {
			Set tChanged("EndTime") = ..searchCriteria.EndTime
			Set ..searchCriteria.EndTime = ..searchCriteria.nextPageEndTime
		}
	}
	
	Set tTimeQuery = 0
	Set tStartTime = ..searchCriteria.StartTime
	Set tEndTime = ..searchCriteria.EndTime
	If (tEndTime '= "") && ($$$timeCmp(tStartTime, tEndTime) > 0) {
		Set tStartTime = ..searchCriteria.EndTime
		Set tEndTime = ..searchCriteria.StartTime
	}
	If (tStartTime '= "") {
		Set tTimeQuery = tTimeQuery+1
		Set tWhere = tWhere _ $select(tWhere '= "": " AND", 1:"") _ " TimeExecuted >= '" _ $replace(tStartTime,"'","''") _ "'"
	}
	If (tEndTime '= "") {
		Set tTimeQuery = tTimeQuery+1
		Set tWhere = tWhere _ $select(tWhere '= "": " AND", 1:"") _ " TimeExecuted <= '" _ $replace(tEndTime,"'","''") _ "'"
	}
	
	If tTimeQuery && (..searchCriteria.SessionId = "") {
		Set tOrderBy = "TimeExecuted " _ tSortOrder _ ", " _ tOrderBy
	}
	
	#; Handle ID conditions (these should only occur during paging
	If ..searchCriteria.nextPageStartId && ((..searchCriteria.nextPageStartId >= ..searchCriteria.StartId) || ('..searchCriteria.StartId)) {
		Set tChanged("StartId") = ..searchCriteria.StartId
		Set ..searchCriteria.StartId = ..searchCriteria.nextPageStartId
	}
	If ..searchCriteria.nextPageEndId && ((..searchCriteria.nextPageEndId <= ..searchCriteria.EndId) || ('..searchCriteria.EndId)) {
		Set tChanged("EndId") = ..searchCriteria.EndId
		Set ..searchCriteria.EndId = ..searchCriteria.nextPageEndId
	}
	
	Set tStartId = ..searchCriteria.StartId
	Set tEndId = ..searchCriteria.EndId
	If (tStartId > tEndId) && (tEndId '= "") {
		Set tStartId = ..searchCriteria.EndId
		Set tEndId = ..searchCriteria.StartId
	}
	If (tStartId '= "") {
		Set tWhere = tWhere _ $select(tWhere '= "": " AND", 1:"") _ " %ID >= " _ +tStartId
	}
	If (tEndId '= "") {
		Set tWhere = tWhere _ $select(tWhere '= "": " AND", 1:"") _ " %ID <= " _ +tEndId
	}
	
	// Make sure client version of ..searchCriteria doesn't change
	Set tProp = ""
	For {
		Set tProp = $order(tChanged(tProp),1,tValue)
		Quit:(tProp = "")
		Set $property(..searchCriteria,tProp) = tValue
	}
	
	Set tSQL = "SELECT " _ tTop _ " " _ tIDCol _ ", SessionId, RuleName, IsError, ReturnValue, ''||%EXTERNAL(TimeExecuted) As TimeExecutedStr"
			_ " FROM Ens_Rule.Log"
			_ $select(tWhere = "": "", 1: " WHERE " _ tWhere)
			_ " ORDER BY " _ tOrderBy
	
	Set pInfo.queryText = tSQL
	Set pSC = tRS.Prepare(tSQL)
	If $$$ISERR(pSC) Quit ""
	Quit tRS
}

/// Server-side callback to provide data for the details table
Method CreateDataSet(pSeed As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawRuleInfo(pSeed, 1, 1)
}

/// Strategically insert spaces or carriage return line feed as needed to keep the return text inside the boundaries of the display.
ClassMethod BreakUpText(pText As %String) As %String [ ZenMethod ]
{
	Set len = $LENGTH(pText)
	Set pattern = pText
	Set text = ""
	Set curr = ""
	set count = 0
	While (len > 0) {
	  	Set curr = $E(pattern,1,1) // extract the character
	 	If (curr = ":") { // new line
  			Set text = text _ curr _ "<br/>" 
  			Set count = 0
	 	}
	 	ElseIf (curr = ".") {
		 	If (count > 15) {
	  			Set text = text _ curr _ "<br/>" 
	  			Set count = 0
		 	}
		 	Else {
		  		Set text = text _ curr 
		  		Set count = count + 1
		 	}
	 	}
	 	Else { // next character
	  		Set text = text _ curr 
	  		Set count = count + 1
	 	}
	    Set pattern = $E(pattern,2,len) // get the next character 
	    Set len = len - 1
	} 
	Quit text
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
		evt.cancelBubble = true;
		if (evt.stopPropagation) {
			evt.stopPropagation();
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

/// User clicked a link for Trace. Display the Visual Trace page in a popup,
/// so user can click the arrows to go from session to session without losing his/her place in the Rule Log.
ClientMethod showTrace(session, evt) [ Language = javascript ]
{
	if (!this.canViewTrace) {
		alert(this.msgNotPermitted);
		return false;
	}
	if (evt) {
		evt.cancelBubble = true;
		if (evt.stopPropagation) {
			evt.stopPropagation();
		}
	}
	if (session != '') {
		window.open(zenLink('EnsPortal.VisualTrace.zen?SESSIONID=' + session));
	}
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

/// toggle detailTable for a selected row.
ClientMethod onSelectItem() [ Language = javascript ]
{
	if (this.selectedId != -1) {
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

/// Use with certain <text> fields so user can hit Enter to indicate that an entry in the field is done and ready to use
ClientMethod enterKey() [ Language = javascript ]
{
     if (zenEvent.keyCode == zenENTER) zenPage.doSearch();
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

/// User clicked the Purge button
ClientMethod startPurge() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var conf = $$$Text("Are you sure you want to purge the Rule Log now?");
	var nan = $$$Text("Value entered for number of days is not a number.");
	var npos = $$$Text("Value entered for number of days is not a positive number.");
	var count = $$$Text("Number of records purged:");
	var fail = $$$Text("Rule Log purge did not succeed:");

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

/// User clicked the Search button, user changed a Quick Search criterion, 
/// or we have completed a non-zero Purge.
ClientMethod onSearchHandler() [ Language = javascript ]
{
	var table = this.getResultsTable();
	var where = "";
	
	this.searchCriteria.SortOrder = zen("SortOrder").getValue();
	this.searchCriteria.TimeFormat = zen('TimeFormat').getValue();
	
	// whereClause, orderByClause, and groupByClause
	var propVals = [];
	var propNames = [ 'Error', 'StartTime', 'EndTime', 'SessionId', 'RuleName' ];
	for (var i = 0; i < propNames.length; i++) {
		var propName = propNames[i];
		propVals.push(zen(propName).getValue());
	}
	var Error = zen("Error").value; // true or false	
	var StartTime = zen("StartTime").value;
	var EndTime = zen("EndTime").value;
	var SessionId = zen("SessionId").value;
	var RuleName = zen("RuleName").value;

	var Defaults = propVals.join(',');
	
	var rows = zen('MaxRows');
	var MaxRows = parseInt(rows.getValue());
	if (MaxRows > 10000) MaxRows = 100;
	if (MaxRows < 0) MaxRows = 1;
	this.searchCriteria.MaxRows = MaxRows;
	
	// Get the current expando state and save it
	var States = zenPage.expandoState();
	
	// Get the Auto-Refresh choice and save it
	var auto = zen("chkRefresh");
	var AutoRefresh = auto.getValue();
	
	// Save last selections to global as default for page
	zenPage.SaveDefaults(this.searchCriteria.SortOrder,this.searchCriteria.TimeFormat,Defaults,MaxRows,States,AutoRefresh);
}

ClientMethod onAfterPageChange() [ Language = javascript ]
{
	// make it easy to navigate
	zenSetProp("expQuick","expanded",true);

	return true;
}

/// Save user's last search criteria into global for page default
ClassMethod SaveDefaults(SortOrder, TimeFormat, Defaults, MaxRows, States, AutoRefresh) [ ZenMethod ]
{
	For p = 1:1:$L(Defaults,",") Set pv=$P(Defaults,",",p),$P(Defaults,",",p) = $S(pv="true":1,pv="false":0,1:pv)
	For p = 1:1:$L(States,",") Set pv=$P(States,",",p),$P(States,",",p) = $S(pv="true":1,pv="false":0,1:pv)
	Set AutoRefresh = $S(AutoRefresh="true":1,AutoRefresh="false":0,1:AutoRefresh)
	Set ^IRIS.Temp.EnsPortal($Username,"RuleLog","SearchCriteria") = SortOrder_"^"_TimeFormat_"^"_Defaults_"^"_MaxRows_"^"_States_"^"_AutoRefresh
}

/// Get the class name (in case what's been selected is an alias, which is invalid as a class name).
/// If the id is already a class name, that class name will be returned as the return value.
ClassMethod GetClassName(id As %String) As %String [ ZenMethod ]
{
	Quit ##class(Ens.Projection.Rule).ResolveRuleAlias(id)
}

/// Reset the "Search Rules By..." form fields to blank, reset other fields to defaults
ClientMethod formReset() [ Language = javascript ]
{
	var conftext = $$$Text("Reset to default values?")
	if (confirm(conftext)) {
		this.getResultsTable(); 
	
		// empty out the fields in the form
		zen("searchForm").reset(); 
	
		// Restore default values to fields outside the "Search Rules By..." area
		zen("SortOrder").setValue("Newest First");  
		zen("TimeFormat").setValue("999");  
		zen("chkRefresh").setValue("None"); 
		zen("MaxRows").setValue(500);
		zen("Error").setValue(0);
		zen("keepDays").setValue(7);
		zen("pageTotal").setValue(1); 

		// set current count
		zenPage.countReset();

		// refresh the display; we will update count upon searching
		zenPage.doSearch();
	}
	return true;
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
	Quit ##class(Ens.Purge).RuleLogCount()
}

/// Perform the purge operation and if there is an error, return the message
/// to JavaScript by prepending the message with a '-'. If no error then 
/// return the zero or positive number of entries deleted, as a string.
ClassMethod DoPurge(keep As %Integer) As %String [ ZenMethod ]
{
	Set LogsDeleted = 0
	Set status = ##class(Ens.Purge).PurgeRuleLogsByDate(keep,.LogsDeleted)
	If ($$$ISERR(status)) { 
		Quit "-" _ $ZCVT($System.Status.GetErrorText(status),"O","JS") 
		}
	Else { 
		Quit LogsDeleted 
	}
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..enableAutoRefresh {
		Set ..%GetComponentById("chkRefresh").hidden = 0
	}
	
	// build up drop-down menus for the search criteria panel
	Do ..GetDropDownMenus()
	
	// get defaults and build up the initial display
	Do ..GetAndUseDefaults()
	
	Do ..%SetValueById("logTotal",..GetCount())
	
	Quit $$$OK
}

/// Method called from %OnAfterCreatePage to get defaults and build up the initial display
Method GetAndUseDefaults() As %String
{
	#; Get the last saved default values and use them as defaults.
	Set SearchCriteria = $G(^IRIS.Temp.EnsPortal($Username,"RuleLog","SearchCriteria"),"Newest First^999^0,,,,,,^500^0,0,0,0^None")
	If '$IsObject(..searchCriteria) Set ..searchCriteria = ##class(%ZEN.proxyObject).%New()
	
	Set ..searchCriteria.SortOrder = $P(SearchCriteria,"^",1)
	Set ..searchCriteria.TimeFormat = $P(SearchCriteria,"^",2)
	Set Defaults = $P(SearchCriteria,"^",3)
	Set ..searchCriteria.MaxRows = $P(SearchCriteria,"^",4)
	Set expandoState = $P(SearchCriteria,"^",5)
	Set ..searchCriteria.AutoRefresh = $P(SearchCriteria,"^",6)
	Set ..searchCriteria.Error = $P(Defaults,",",1)
	Set ..searchCriteria.StartTime = $P(Defaults,",",2)
	Set ..searchCriteria.EndTime = $P(Defaults,",",3)
	Set ..searchCriteria.SessionId = $P(Defaults,",",4)
	Set ..searchCriteria.RuleName = $P(Defaults,",",5)
	
	If '..enableAutoRefresh {
		Set ..searchCriteria.AutoRefresh = "None"
	}
	
	#; Load defaults for Details
	For tProp = "SortOrder","TimeFormat","MaxRows","Error","StartTime","EndTime","SessionId","RuleName" {
		Set ..%GetComponentById(tProp).value = $property(..searchCriteria,tProp)
	}
	
	#; Load Expando states
	Set ..%GetComponentById("expQuick").expanded = $P(expandoState,",",1)
	Set ..%GetComponentById("expDetails").expanded = $P(expandoState,",",2)
	Set ..%GetComponentById("expPurge").expanded = $P(expandoState,",",3)

	#; Load auto-refresh setting
	Set ..%GetComponentById("chkRefresh").value = ..searchCriteria.AutoRefresh

	#; set up the table
	Set table = ..%GetComponentById("table")
	
	#; Max Rows (Page Size)
	If (..searchCriteria.MaxRows > 10000) { Set ..searchCriteria.MaxRows = 100 }
	If (..searchCriteria.MaxRows < 0) { Set ..searchCriteria.MaxRows = 1 }
	Set table.maxRows = ..searchCriteria.MaxRows
}

/// Method called from %OnAfterCreatePage to build up drop-down menus for the search criteria panel
Method GetDropDownMenus() As %String
{
	// Set up RuleName drop-down 
	Set tCombo = ..%GetComponentById("RuleName")
	// create the empty option at the top
	Set tOption = ##class(%ZEN.Auxiliary.option).%New()
	Do tCombo.options.Insert(tOption)
	Do ..%AddComponent(tOption)
	Set tOption.text = ""
	Set tOption.value = ""

	Set tSC = ##class(Ens.Projection.Rule).GetRuleNameList(.list)  
	If $$$ISERR(tSC) Quit ""
	Set tName = ""
	For {
		Set tName = $order(list(tName))
		Quit:(tName = "")
		 
		// create the option for this class name
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = tName
		Set tOption.value = tName
	}
	Quit ""
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
	Quit $$$Text("Rule Log","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set n = 0
	Set pCommands($I(n)) = $LB("searchButton",$$$Text("Search"),$$$Text("Search the Rule Log using the current criteria"),"zenPage.doSearch();")
	Set:..#CANCANCELSEARCH pCommands($I(n)) = $LB("cancelButton",$$$Text("Cancel"),$$$Text("Cancel current search"),"zenPage.cancelSearch(); return false;")
	Set pCommands($I(n)) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the Rule Log search criteria to their default values"),"zenPage.formReset();")
	Set pCommands($I(n)) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false);")
	Set pCommands($I(n)) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true);")
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "DoPurge": ..#EDITRESOURCE, : "")
}

/// Callback to set up the resultset/query for paging.
ClientMethod onChangeResultsPage(next, pageSize, currentPage) [ Language = javascript ]
{
	if (!this.searchCriteria) {
		var searchForm = this.getSearchForm();
		this.searchCriteria = searchForm.getValuesAsObject();
	}
	
	if (next) {
		var currPageData = this._idIndex[currentPage];
		if (this.searchCriteria.SortOrder == 'Newest First') {
			this.searchCriteria.nextPageEndId = (currPageData.lastId - 1);
			this.searchCriteria.nextPageStartId = '';
			this.searchCriteria.nextPageEndTime = currPageData.lastTime;
			this.searchCriteria.nextPageStartTime = '';
		}
		else {
			this.searchCriteria.nextPageStartId = parseInt(currPageData.lastId,10) + 1;
			this.searchCriteria.nextPageEndId = '';
			this.searchCriteria.nextPageStartTime = currPageData.lastTime;
			this.searchCriteria.nextPageEndTime = '';
		}
	}
	else {
		var prevPageData = this._idIndex[currentPage - 1];
		if (this.searchCriteria.SortOrder == 'Newest First') {
			this.searchCriteria.nextPageStartId = prevPageData.lastId;
			this.searchCriteria.nextPageEndId = prevPageData.firstId;
			this.searchCriteria.nextPageStartTime = prevPageData.lastTime;
			this.searchCriteria.nextPageEndTime = prevPageData.firstTime;
		}
		else {
			this.searchCriteria.nextPageStartId = prevPageData.firstId;
			this.searchCriteria.nextPageEndId = prevPageData.lastId;
			this.searchCriteria.nextPageStartTime = prevPageData.firstTime;
			this.searchCriteria.nextPageEndTime = prevPageData.lastTime;
		}
	}
}

/// Helper method to record the ExecutionID and TimeExecuted values for first and last rows on the current page.
ClientMethod updatePageData() [ Language = javascript ]
{
	if (!this._idIndex) {
		this._idIndex = {};
	}
	this._idIndex[this.currentPage] = {};
	var currPageData = this._idIndex[this.currentPage];
	
	var table = this.getResultsTable();
	var tableDiv = table.getEnclosingDiv();
	var rows = tableDiv.getElementsByTagName('tr');
	
	var lastRow = rows[rows.length - 2];
	currPageData.lastId = lastRow.getAttribute('zenvalue');
	
	var firstRow = rows[1];
	currPageData.firstId = firstRow.getAttribute('zenvalue');
	
	var times = tableDiv.getElementsByTagName('timeexecuted');

	if (times.length > 0) {
		var lastTime = times[times.length - 1];
		currPageData.lastTime = lastTime.getAttribute('fullTime');
		
		var firstTime = times[0];
		currPageData.firstTime = firstTime.getAttribute('fullTime');
	}
}

/// This callback is called at the end of the HTML HEAD section of the page.<br/>
/// (default implementation is a simple expression).
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Quit ##class(EnsPortal.Utils).DrawEventInfoStyle()
}

}
