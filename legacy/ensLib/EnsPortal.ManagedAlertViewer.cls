/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %ZEN.Utils)

/// Viewer page to look at Managed Alerts present on the system.
Class EnsPortal.ManagedAlertViewer Extends EnsPortal.Template.viewerPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Managed Alert Viewer";

/// User needs READ permissions on the %Ens_Alerts resource to view this page.
Parameter RESOURCE = "%Ens_Alerts:READ";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES = "ensemble/Ensemble_Utils.js";

Property resultsTableId As %ZEN.Datatype.id [ InitialExpression = "table" ];

Property pageSizeId As %ZEN.Datatype.id [ InitialExpression = "PageSize" ];

Property pageNumberId As %ZEN.Datatype.id [ InitialExpression = "pageTotal" ];

Property detailsWidth As %ZEN.Datatype.integer(MAXVAL = 80, MINVAL = 5) [ InitialExpression = 30 ];

Property source As %ZEN.Datatype.string(ZENURL = "SOURCE");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* div around results table */
#resultsTable {
	height: 610px;
	overflow-y: scroll;
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
.detailContents {
	padding: 10px;
}
.detailTitle {
	font-weight: bold;
}
.detailTable {
	background-color: white;
	padding: 2px;
	font-size: 0.75em;
}
.detailTable, .detailCollTable, .detailCollHistoryTable {
	border-collapse: collapse;
}
.detailCollHistoryTable {
	padding: 3px;
}
table.detailTable td.detailTableHeader {
	font-weight: bold;
	padding-left: 4px;
}
table.detailTable td.detailCollTableHeader {
	font-weight: bold;
	padding-left: 8px;
}
.detailTableCollHeader {
	background-color: #DDDDDD;
    font-size: 1.05em;
    font-weight: bold;
    text-align: center;
}
table.detailTable td.detailTableCollTitle {
	background-color: #DDDDDD;
	cursor: pointer;
	font-weight: bold;
	font-size: 1em;
	padding-left: 4px;
}
.detailCollHistoryTableHeader {
	background-color: #EEE;
}
table.detailTable th, table.detailTable td {
	border: 1px solid gray;
	padding-left: 2px;
	padding-right: 2px;
}
table.detailCollHistoryTable td, table.detailCollHistoryTable th {
	border: none;
}
table.detailCollHistoryTable td.detailCollHistoryTableOldValue,
table.detailCollHistoryTable th.detailCollHistoryTableOldValue {
	border-left: 1px solid gray;
	border-right: 1px solid gray;
}
/* style for search panel */
.menuPanel {
	width: 300px;
	background: #EDECE4;
	overflow: hidden;
	overflow-y: auto;
}

/* slight adjustments to tpTable */
table.tpTable {
	padding-top: 5px;
	border: none;
}
</style>
}

/// This pane displays event log activity table. User may click on a row and details are displayed to the side.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<vgroup valign="top">
<tablePane id="table" 
	cellSpacing="2"
	dataSource="columns"
	tableName="Ens_Alerting.ManagedAlert"
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
	unlockSession="true"
	permitClientSQL="true"
	>
<!--
Displayed:
 * ID
 * AlertTime
 * SourceConfigName
 * AlertText
 * CurrentOwner
 * EscalationLevel
 * IsOpen
 * LastActionTime
Not Displayed:
 * Production
 * AlertGroups
 * Actions
 * NextActionTime
-->
<!-- columns -->
<column header="ID" colName="ID" style="text-align:left;" title="Managed Alert ID"/>
<column header="Alert Time" colName="AlertTime" title="Time of the original Alert" OnDrawCell="DrawTimeCell" />
<column header="Is Open" colName="IsOpen" title="Flag to indicate that the Alert is still open" OnDrawCell="DrawOpenCell" />
<column header="Escalated" colName="EscalationLevel" title="Current escalation level of the alert" style="text-align: center;" />
<column header="Current Owner" colName="CurrentOwner" OnDrawCell="DrawCurrentOwner" />
<column header="Last Action Time" colName="LastActionTime" OnDrawCell="DrawTimeCell" />
<column header="Source" colName="SourceConfigName" title="Configuration name of the item that triggered the alert" />
<column	header="Alert Text" colName="AlertText" title="Text of the original alert" OnDrawCell="DrawTextCell" />
<!-- conditions -->
<condition colName="IsOpen" predicate="EQ" value="0" cellStyle="background-color: #CCC;" />
<condition colName="EscalationLevel" predicate="GT" value="2" cellStyle="background-color: red;" />
<condition colName="EscalationLevel" predicate="EQ" value="2" cellStyle="background-color: orange;" />
<condition colName="EscalationLevel" predicate="EQ" value="1" cellStyle="background-color: yellow; color: black;" />
</tablePane>
<!-- set default auto refresh to "None" -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</vgroup>
</pane>
}

/// This pane displays the search criteria. We provide defaults and user can change them.
/// The user's values are saved and used as future defaults for this user.
/// Changing an item in the Quick Search expando will refresh the table immediately. 
/// Text fields you are required to click [Enter] or the "Search" button.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
<vgroup id="mainPanel" enclosingClass="menuPanel"  valign="top">
<form name="searchForm" id="searchForm" layout="vertical" cellStyle="padding: 2px 10px; font-size:0.8em;">
<expando name="expQuick" id="expQuick" caption="Quick Search" expanded="true"
	    childIndent="16px" containerStyle="padding:10px 10px 0px 10px;"  >
<hgroup valign="top">
<vgroup containerStyle="vertical-align: top;">
<select label="Auto-Refresh" name="chkRefresh" id="chkRefresh" value="None" showEmpty="false" hidden="true"
	displayList="None,30 Seconds,60 Seconds,2 Minutes,5 Minutes" valueList="None,30000,60000,120000,300000" 
	onclick="zenPage.changeRefresh();"/>
<select label="Sort Order" name="SortOrder" id="SortOrder" displayList="Newest First,Oldest First,Most Escalated First,Least Escalated First" valueList="0,1,2,3" value="0"
	showEmpty="false" onchange="zenPage.doSearch();"/>
<select label="Time Format" name="TimeFormat" id="TimeFormat" displayList="Complete,Time Only" valueList="0,1" value="0" showEmpty="false"
	onchange="zenPage.doSearch();"/>
</vgroup>
<spacer width="10" />
<vgroup valign="top">
<label name="pageTotal" id="pageTotal" label="Page" value="" enclosingStyle="font-size:0.8em;padding-bottom:5px;padding-top:2px;"
	title="Current page of the display table, based on Page Size and the current search criteria."/>
<select label="Page Size" name="PageSize" id="PageSize" valueList="10,20,30,50,100,200,500,1000,2000" showEmpty="false"
	onchange="zenPage.doSearch();"/>
<select name="IsOpen" id="IsOpen" label="Open State" value="" valueList=",1,0" displayList="All,Open,Closed" onchange="zenPage.doSearch();" showEmpty="false" />
</vgroup>
</hgroup>
<select label="Owner" name="CurrentOwner" id="CurrentOwner" displayList="Unassigned or Me,Unassigned,Me,All" valueList="3,2,1," value="3" 
	showEmpty="false" onchange="zenPage.doSearch();" />
</expando>
<expando name="expDetails" id="expDetails" caption="Search Managed Alerts By..." expanded="false"
		childIndent="16px" containerStyle="padding:10px 10px 0px 10px;" >
<vgroup valign="top">
<hgroup valign="top">
<dateText name="StartTime" id="StartTime" label="Start Time" size="18" showTime="true" containerStyle="padding:0px 3px 0px 0px;"
          title="Entering a date/time value in this field will restrict the search results to times after or equal to the given value" />
<spacer width="10" />
<text name="StartId" id="StartId" label="Start ID" size="9" 
          title="Entering an ID value in this field will restrict the search results to Managed Alert IDs greater than or equal to the given value" />
</hgroup>
<hgroup valign="top">
<dateText name="EndTime" id="EndTime" label="End Time" size="18" showTime="true" containerStyle="padding:0px 3px 0px 0px;"
          title="Entering a date/time value in this field will restrict the search results to times before or equal to the given value" />
<spacer width="10" />
<text name="EndId" id="EndId" label="End ID" size="9"   
          title="Entering an ID value in this field will restrict the search results to Managed Alert IDs less than or equal to the given value" />
</hgroup>
<text label="Minimum Escalation Level" name="MinEscalationLevel" id="MinEscalationLevel" />
<text label="Maximum Escalation Level" name="MaxEscalationLevel" id="MaxEscalationLevel" />
<selector id="Source" name="Source" label="Source Config Item" size="18" containerStyle="padding:0px 3px 0px 0px;"
		title="Entering a config item name in this field will restrict the search results to alerts generated by the config item."
		context="Ens.ContextSearch/ManagedAlertSources" />
<selector id="AlertGroup" name="AlertGroup" label="Alert Group" size="18" containerStyle="padding:0px 3px 0px 0px;"
	title="Entering an alert group name in this field will restrict the search results to alerts in that alert group."
	context="Ens.ContextSearch/ManagedAlertGroups" />
</vgroup>
</expando>
</form>
</vgroup>
</pane>
}

/// This pane shows details of a given entry when that row is clicked in the table.
XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
<jsonProvider id="alertFields" OnRenderJSON="GetUpdateData">
<parameter id="alertID" name="alertID" paramName="alertID" />
</jsonProvider>
<tabGroup id="alertTabGroup" showTabBar="true">
<tab id="tabDetails" caption="Details">
<html id="tabDetailContents" OnDrawContent="DrawDetailHTML" />
</tab>
<!--
<tab id="tabUpdate" caption="Update">
<html id="updateNoAlertHTML">
<div id="updateNoAlertHTML_div" class="no_data_message detailContents"></div>
</html>
<form id="updateAlertForm" labelPosition="left" hidden="true">
<hidden name="%ID" />
<checkbox name="IsOpen" label="Open" />
<selector name="CurrentOwner" label="Current Owner" context="Ens.ContextSearch/ListEnsembleUsers" size="35" />
<text name="EscalationLevel" label="Escalation Level" size="5" />
<textarea name="Reason" label="Reason" cols="30" rows="5" />
</form>
</tab>-->
</tabGroup>
<vgroup valign="top">
<html id="dynaGrid" hidden="true" />
</vgroup>
</pane>
}

Method GetUpdateData(ByRef pParms) As %Status
{
	Set tAlert = ""
	Set tAlertID = $get(pParms("alertID"))
	If (tAlertID '= "") {
		Set tAlert = ##class(Ens.Alerting.ManagedAlert).%OpenId(tAlertID)
	}
	If '$IsObject(tAlert) {
		Write "null"
		Quit $$$OK
	}
	Set tStatus = tAlert.GetProperties(.tProps,.tCollProps)
	If $$$ISERR(tStatus) Quit tStatus
	Set tPropSequence = $get(tProps)
	Write !, "{ " _ $$$ZENJSPAIR("alertID",tAlertID) _ ","
	Write $$$ZENJSPROP("propSequence") _ ": [ "
	Set tEditCount = 0
	Set tEditProps = ""
	For i=1:1:$listlength(tPropSequence) {
		Set tPropName = $listget(tPropSequence,i)
		If (tPropName '= "") && ($data(tProps(tPropName),tPropData)#2) {
			If $listget(tPropData,2) {
				Set tEditCount = tEditCount + 1
				Set tEditProps = tEditProps _ $listbuild(tPropName)
				Write $select(tEditCount = 1: "", 1: ", ") _ $$$ZENJSVALUE(tPropName)
			}
		}
	}
	Write " ],"
	Write !, $$$ZENJSPROP("props") _ ": { "
	For i=1:1:$listlength(tEditProps) {
		Set tPropName = $listget(tEditProps,i)
		Set tPropData = $get(tProps(tPropName))
		Write $select(i>1: ",", 1: "")
		Write !, $$$ZENJSPROP(tPropName) _ ": { "
		Write $$$ZENJSPAIR("headerText",$listget(tPropData,1)) _ ", "
		Write $$$ZENJSPAIR("actionValue",$listget(tPropData,3)) _ ", "
		Set tValue = ""
		Try {
			Set tValue = $property(tAlert,tPropName)
		}
		Catch {}
		If $listget(tPropData,6) {
			Set tValue = ..GetDisplayValue(tValue, $listget(tPropData,4))
		}
		Write $$$ZENJSPAIR("value",tValue)
		Write " }" // end tPropName data
	}
	Write !, "}" // end props
	Write !, "}" // end object
	Quit $$$OK
}

Method GetAlertFields(ByRef pParms) As %Status
{
	Set tAlert = ""
	Set tAlertID = $get(pParms("alertID"))
	If (tAlertID '= "") {
		Set tAlert = ##class(Ens.Alerting.ManagedAlert).%OpenId(tAlertID)
	}
	If '$IsObject(tAlert) {
		Write "null"
		Quit $$$OK
	}
	
	Set tStatus = tAlert.GetProperties(.tProps,.tCollProps)
	If $$$ISERR(tStatus) Quit tStatus
	Set tPropSequence = $get(tProps)
	Write !, "{ " _$$$ZENJSPROP("fieldSequence") _ ": [ "
	For i=1:1:$listlength(tPropSequence) {
		Write $select(i=1: "", 1: ", ") _ $$$ZENJSVALUE($listget(tPropSequence,i))
	}
	Write " ],"
	Set tCollSequence = $get(tCollProps)
	Write !, $$$ZENJSPROP("collSequence") _ ": [ "
	For i=1:1:$listlength(tCollSequence) {
		Write $select(i=1: "", 1: ", ") _ $$$ZENJSVALUE($listget(tCollSequence,i))
	}
	Write " ],"
	
	Write !, $$$ZENJSPROP("fieldIndex") _ ": { "
	Set tFirst = 1
	Set tPropName = ""
	For { // (HeaderText,editable,actionValue, datatype)
		Set tPropName = $order(tProps(tPropName),1,tPropData)
		Quit:(tPropName = "")
		If ('tFirst) Write ","
		Set tFirst = 0
		
		Write !, $$$ZENJSPROP(tPropName) _ ": { "
		Write $$$ZENJSPAIR("header",$listget(tPropData,1))
		Write ", " _ $$$ZENJSPROP("editable") _ ": " _ $select($listget(tPropData,2): "true", 1: "false")
		Write ", " _ $$$ZENJSPAIR("action",$listget(tPropData,3))
		Write ", " _ $$$ZENJSPAIR("datatype",$listget(tPropData,4))
		Set tValue = ""
		Try {
			Set tValue = $select(tPropName = "ID": tAlertID, 1: $property(tAlert,tPropName))
		}
		Catch {}
		Write ", " _ $$$ZENJSPAIR("value", tValue)
		Write " }"
	}
	Write " },"
	
	Write !, $$$ZENJSPROP("collIndex") _ ": { "
	Set tFirst = 1
	Set tCollName = ""
	For { // HeaderText,editable,actionValue,ItemHeader,$lb(list of sub-properties to display))
		Set tCollName = $order(tCollProps(tCollName),1,tCollData)
		Quit:(tCollName = "")
		If ('tFirst) Write ","
		Set tFirst = 0
		
		Write $$$ZENJSPROP(tCollName) _ ": { "
		Write !, $$$ZENJSPAIR("header",$listget(tCollData,1))
		Write ", " _ $$$ZENJSPROP("editable") _ ": " _ $select($listget(tCollData,2): "true", 1: "false")
		Write ", " _ $$$ZENJSPAIR("action",$listget(tCollData,3))
		Write ", " _ $$$ZENJSPAIR("itemHeader",$listget(tCollData,4))
		Write ",",!, $$$ZENJSPROP("sequence") _ ": [ "
		Set tCollSequence = $listget(tCollData,5)
		For i=1:1:$listlength(tCollSequence) {
			Write $select(i=1: "", 1: ", ") _ $$$ZENJSVALUE($listget(tCollSequence,i))
		}
		Write " ],"
		
		Write !, $$$ZENJSPROP("index") _ ": { "
		
		Set tFirstProp = 1
		Set tPropName = ""
		For {
			Set tPropName = $order(tCollProps(tCollName,tPropName),1,tCollPropData)
			Quit:(tPropName = "")
			If ('tFirstProp) Write ","
			Set tFirstProp = 0
			
			Write !, $$$ZENJSPROP(tPropName) _ ": { "
			Write $$$ZENJSPAIR("header",$listget(tCollPropData,1))
			Write ", " _ $$$ZENJSPROP("editable") _ ": " _ $select($listget(tCollPropData,2): "true", 1: "false")
			Write ", " _ $$$ZENJSPAIR("action",$listget(tCollPropData,3))
			Write ", " _ $$$ZENJSPAIR("datatype",$listget(tCollPropData,4))
			Write " }"
		}
		Write " }" // end index
		Write " }" // end tCollName
	}
	Write !, "}," // end collIndex
	Write !, $$$ZENJSPROP("collValues") _ ": { "
	Set tFirst = 1
	Set tCollName = ""
	For {
		Set tCollName = $order(tCollProps(tCollName),1,tCollData)
		Quit:(tCollName = "")
		If ('tFirst) Write ","
		Set tFirst = 0
		Write !, $$$ZENJSPROP(tCollName) _ ": [ "
		Set tColl = $property(tAlert,tCollName)
		For i=1:1:tColl.Count() {
			Write $select(i=1: "", 1: ", ")
			Set tObj = tColl.GetAt(i)
			Do ##class(%ZEN.Auxiliary.jsonProvider).%ObjectToJSON(tObj,,,0,0)
		}
		Write " ]"
	}
	Write !," }" // end collValues
	Write !, "}" // end object
	Quit $$$OK
}

/// Server-side callback to provide localized string introducing the details table
Method GiveAdviceString(pSeed As %String) As %Status
{
	Write $$$Text("Click on a table row to show details")
	Quit $$$OK
}

Method DrawTimeCell(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tTime = %query(pName)
	Set tFormat = $select($IsObject(..searchCriteria): ..searchCriteria.TimeFormat, 1: 0)
	Set tValue = ..EscapeHTML($select(tFormat: $extract(tTime,*-11,*), 1: tTime))
	Write tValue,"<timecreated style=""display: none;"" fullTime=""",..EscapeHTML(tTime),"""/>"
	Quit $$$OK
}

Method DrawOpenCell(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write $select(%query(pName): $$$Text("Yes"), 1: $$$Text("No"))
	Quit $$$OK
}

Method DrawCurrentOwner(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write $select(%query(pName) '= "": ..EscapeHTML(%query(pName)), 1: "(" _ $$$Text("Unassigned") _ ")")
	Quit $$$OK
}

/// Server-side method to write out the event text both as content and in the hover-text title.
Method DrawTextCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Set tText = $zconvert(%query(name),"O","HTML")
	Write "<span title=""" _ tText _""" >" _ tText _ "</span>",!
	Quit $$$OK
}

/// If auto-refresh is still on, refresh table and restart the timer
ClientMethod timeout(timer) [ Language = javascript ]
{
	var val = zen('chkRefresh').getValue(); // check auto-refresh
	if (zenPage.enableAutoRefresh && !val.match("None")) { // There is a non-zero timer value
		zenPage.doSearch(); // refresh table
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

/// User clicked the Search button, user changed a Quick Search or Event Type criterion, 
/// or we have completed a non-zero Purge.
ClientMethod onSearchHandler() [ Language = javascript ]
{
	var table = this.getResultsTable();
	var where = '';

	// whereClause, orderByClause, and groupByClause
	// call server method to build the where clause
	var where = zenPage.GetWhereClause();
	table.whereClause = where;
	var orderBy = '%ID DESC';
	
	if (this.searchCriteria) {
		switch (this.searchCriteria.SortOrder.toString()) {
			case '3':
				orderBy = 'EscalationLevel ASC, %ID DESC';
				break
			case '2':
				orderBy = 'EscalationLevel DESC, %ID DESC';
				break
			case '1':
				orderBy = '%ID ASC';
				break
			case '0':
			default:
				orderBy = '%ID DESC';
				break;
		}
	}
	table.setProperty('orderByClause', orderBy);

	// Save last selections to global as default for page
	zenPage.SaveSearchCriteria();
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
	Set ..source = "" ; clear initial criterion
	Quit $$$OK
}

Method SaveSearchCriteria() As %String [ ZenMethod ]
{
	Set tStatus = $$$OK
	Try {
		If $IsObject(..searchCriteria) {
			Set tStatus = ##class(EnsPortal.Util.ManagedAlertCriteria).CreateFromProxyObject(..searchCriteria,.tSearchCriteria)
			If $$$ISERR(tStatus) Quit
			Set tStatus = tSearchCriteria.Save()
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) Quit $system.Status.GetErrorText(tStatus)
	Quit ""
}

/// Method called from <method>%OnAfterCreatePage</method> to get defaults and build up the initial display
Method GetAndUseDefaults() As %String
{
	If ..source '= "" {
		Set tCriteria = ##class(EnsPortal.Util.ManagedAlertCriteria).%New()
		Set tCriteria.Source = ..source
	}
	Else {
		Do ##class(EnsPortal.Util.ManagedAlertCriteria).Load(.tCriteria,1)
	}

	Set tQuickExpanded = 0
	Set tDetailsExpanded = 0
	Set tDefaultCriteria = ##class(EnsPortal.Util.ManagedAlertCriteria).%New()

	For tProp = "SortOrder", "TimeFormat", "PageSize", "Source", "StartId", "EndId", "StartTime", "EndTime", "IsOpen", "MinEscalationLevel", "MaxEscalationLevel" {
		Set tComp = ..%GetComponentById(tProp)
		Set tVal = $property(tCriteria,tProp)
		Set tComp.value = tVal
		If (tVal '= $property(tDefaultCriteria,tProp)) {
			If (tComp.onchange '= "") {
				Set tQuickExpanded = 1
			}
			Else {
				Set tDetailsExpanded = 1
			}
		}
	}
	
	Set ..%GetComponentById("expQuick").expanded = tQuickExpanded
	Set ..%GetComponentById("expDetails").expanded = tDetailsExpanded

	#; set up the table
	Set table = ..%GetComponentById("table")

	#; Page Size
	Set tPageSize = tCriteria.PageSize
	If (tPageSize > 10000) { Set tPageSize = 10000 }
	ElseIf (tPageSize < 0) { Set tPageSize = 1 }
	Set table.maxRows = tPageSize
}

/// Called from <method>onSearchHandler</method> and 
/// <method>%OnAfterCreatePage</method> to build the where clause.
Method GetWhereClause() As %String [ ZenMethod ]
{
	Set tWhere = ""
	If $IsObject(..searchCriteria) {
		Set tConditions = 0
		If (..searchCriteria.IsOpen '= "") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "IsOpen = " _ ''..searchCriteria.IsOpen
		}
		If (..searchCriteria.CurrentOwner '= "") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = $case(..searchCriteria.CurrentOwner,
				1: "CurrentOwner = '" _ $replace($username,"'","''") _ "'",
				2: "CurrentOwner IS NULL",
				3: "( CurrentOwner IS NULL OR CurrentOwner = '" _ $replace($username,"'","''") _ "' )",
				: "CurrentOwner = '" _ $replace(..searchCriteria.CurrentOwner,"'","''") _ "'")
		}
		If (..searchCriteria.MinEscalationLevel '= "") && (..searchCriteria.MinEscalationLevel = (""_(+..searchCriteria.MinEscalationLevel))) {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "EscalationLevel >= " _ ..searchCriteria.MinEscalationLevel
		}
		If (..searchCriteria.MaxEscalationLevel '= "") && (..searchCriteria.MaxEscalationLevel = (""_(+..searchCriteria.MaxEscalationLevel))) {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "EscalationLevel <= " _ ..searchCriteria.MaxEscalationLevel
		}
		If (..searchCriteria.AlertGroup '= "") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "FOR SOME %ELEMENT(AlertGroups) (%EXACT(%VALUE) = '" _ $replace(..searchCriteria.AlertGroup,"'","''") _ "')"
		}
		If (..searchCriteria.Source '="") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "SourceConfigName = '"_$replace(..searchCriteria.Source,"'","''")_"'"
		}
		Set tStartId = ""
		Set tEndId = ""
		If (..searchCriteria.StartId '= "") && (..searchCriteria.StartId = +..searchCriteria.StartId) {
			Set tStartId = +..searchCriteria.StartId
		}
		If (..searchCriteria.EndId '= "") && (..searchCriteria.EndId = +..searchCriteria.EndId) {
			Set tEndId = +..searchCriteria.EndId
		}
		If (tStartId '= "") && (tEndId '= "") && (tStartId > tEndId) {
			Set tStartId = tEndId
			Set tEndId = +..searchCriteria.StartId
		}
		If (tStartId '= "") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "%ID >= " _ tStartId
		}
		If (tEndId '= "") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "%ID <= " _ tEndId
		}
		Set tStartTime = ..searchCriteria.StartTime
		Set tEndTime = ..searchCriteria.EndTime
		If (tStartTime '= "") && (tEndTime '= "") && ($$$timeCmp(tEndTime,tStartTime) < 0) {
			Set tStartTime = tEndTime
			Set tEndTime = ..searchCriteria.StartTime
		}
		If (tStartTime '= "") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "AlertTime >= '" _ $replace(tStartTime,"'","''") _ "'"
		}
		If (tEndTime '= "") {
			Set tConditions = tConditions + 1
			Set tConditions(tConditions) = "AlertTime <= '" _ $replace(tEndTime,"'","''") _ "'"
		}

		If tConditions {
			Set tWhere = tConditions(1)
			For i = 2:1:tConditions {
				Set tWhere = tWhere _ " AND " _ tConditions(i)
			}
		}
	}
	Quit tWhere
}

Method GetColumnsAndFrom(timeFormat As %String) As %String
{
	If $get(timeFormat) = "" Set timeFormat = 999
	Quit "* FROM (SELECT TOP ALL ID,AlertTime,IsOpen,EscalationLevel,CurrentOwner,LastActionTime,SourceConfigName,AlertText FROM Ens_Alerting.ManagedAlert "
}

/// Reset the "Search Events By..." form fields to blank, reset other fields to defaults
ClientMethod formReset() [ Language = javascript ]
{
	var conftext = $$$Text("Reset to default values?")
	if (confirm(conftext)) {
		var table = zenPage.getResultsTable(); 
	
		// empty out the fields in the form
		zen("searchForm").reset(); 
		zen("pageTotal").setValue(1); 
	
		// refresh the display
		zenPage.doSearch();
	}
	return true;
}

ClientMethod onAfterPageChange() [ Language = javascript ]
{
	// make it easy to navigate
	zenSetProp("expQuick","expanded",true);
	return true;
}

/// Callback to set up the resultset/query for paging.
ClientMethod onChangeResultsPage(next, pageSize, currentPage) [ Language = javascript ]
{
	var table = this.getResultsTable();
	
	if (!this.searchCriteria) {
		var searchForm = this.getSearchForm();
		this.searchCriteria = searchForm.getValuesAsObject();
	}
	var timeFormat = this.searchCriteria.TimeFormat;
	var desc = true;
	switch (this.searchCriteria.SortOrder) {
		case '1':
		case '3':
			desc = false;
			break;
		case '0':
		case '2':
		default:
			desc = true;
			break;
	}
	var operator = (desc ? '<' : '>');
	var lastRowData = table.getRenderedRowData(pageSize - 1);
	var posData = null;

	if (next) {
		if (this.currentPage == 2) { // we are moving off the first page
			this._posIndex = []; // establish _posIndex array to remember positional data
			var firstRowData = table.getRenderedRowData(0);
			this._posIndex[1] = { "ID": firstRowData['ID'], "EscalationLevel": firstRowData['EscalationLevel'] };
		}
		posData = { "ID": lastRowData['ID'], "EscalationLevel": lastRowData['EscalationLevel'] };
		this._posIndex[this.currentPage] = posData;
	}
	else {
		posData = this._posIndex[this.currentPage];
		// for the first page we need to use <= or >=
		if (this.currentPage == 1) operator += '=';
	}
	
	var colValues = '';
	if (posData) {
		colValues = posData.ID + '|' + posData.EscalationLevel;
	}
	// recalculate the table (our new query temporarily overrides whereClause etc.)
	var ret = zenPage.ResetQuery(next,pageSize,timeFormat,operator,colValues,'');
}

/// Helper method to construct a <tablePane> query on the server when paging.
/// This method should be invoked from <method>onChangeResultsPage</method>()
/// for tablePanes which use the whereClause, orderbyClause and columns properties
/// to construct queries. <var>next</var> is true for Next, false for Previous;
/// <var>pageSize</var> is the page size; <var>wherePlus</var> gives the ID < or ID > string;
/// <var>idVal</var> gives the id value to compare with ID,
/// <var>outer</var> is either ASC or DESC depending on the current display order.
Method ResetQuery(next As %Boolean, pageSize As %String, timeFormat As %String, whereOperator As %String, colValues As %String, orderCols As %String) As %String [ ZenMethod ]
{
	Set table = ..%GetComponentById(..resultsTableId)
	Set whereNew = ""
	
	If (colValues '= "") {
		Set tCols = $case(..searchCriteria.SortOrder,
								0: $lb("%ID"),
								1: $lb("%ID"),
								2: $lb("EscalationLevel", "%ID"),
								3: $lb("EscalationLevel", "%ID"),
								: "")
		/*
		Set tDesc = '(..searchCriteria.SortOrder # 2)
		For i=1:1:$listlength(tCols) {
			Set col = $listget(tCols,i)
			Set tOperator = $select(tDesc: "<", 1: ">") _ $select(i < $listlength(tCols): "=", ..currentPage = 1: "=", 1: "")
			Set tValPos = $case(col, "%ID": 1, "EscalationLevel": 2, : 0)
			If (tValPos > 0)
				Set tVal = +$piece(colValues,"|",tValPos)
				Set whereNew = whereNew _ $select(whereNew = "": "", 1: " AND ") _ col _ " " _ tOperator _ " " _ tVal
			
		}
		*/
	}
	If (table.whereClause = "") && (whereNew '= "") {
		Set whereNew = "WHERE " _ whereNew
	}
	ElseIf (table.whereClause '= "") { // current where clause is not blank
		Set whereNew = " WHERE " _ table.whereClause _ $select(whereNew '= "" : " AND " _ whereNew, 1: "")
	}
	
	Set columns = ..GetColumnsAndFrom(timeFormat)
	Set sql = "SELECT TOP " _ pageSize _ " "_ columns _" "
	
	Set sql = sql _ whereNew
	Set sql = sql  _ " ORDER BY " _ table.orderByClause
	Set sql = sql _ ") WHERE %vid > " _ ((..currentPage - 1) * pageSize)
	
	// set the sql attribute so that our new query overrides whereClause etc. 
	// Resetting the sql attribute must be done on the server side, so it's done here.
	Set table.sql = sql
	
	// return a value to ensure this is synchronous on client and server
	Quit ""
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Managed Alert Viewer")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("searchButton",$$$Text("Search"),$$$Text("Search the Event Log using the current criteria"),"zenPage.doSearch();")
	Set pCommands(2) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the Event Log search criteria to their default values"),"zenPage.formReset();")
	Set pCommands(3) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false);")
	Set pCommands(4) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true);")
	Quit $$$OK
}

/// toggle detailTable for a selected row.
ClientMethod onSelectItem() [ Language = javascript ]
{
	var clientRender = false;
	if (clientRender) {
		var json = zen('alertFields');
		var alertID = zen('alertID');
		var detailDiv = zen('tabDetailContents').getEnclosingDiv();
		var updateDiv = zen('tabUpdateContents').getEnclosingDiv();
		alertID.value = this.selectedId;
		json.reloadContents();
		var fieldData = json.getContentObject();
		var detailHTML = [];
		var updateHTML = [];
		if (fieldData) {
			this.getDetailHTML(detailHTML);
		}
		else {
			// TODO: add nice message
			var msg = '<div class="no_data_message">' + $$$Text('No alert selected') + '</div>';
			detailHTML.push(msg);
			updateHTML.push(msg);
		}
		detailDiv.innerHTML = detailHTML.join('');
		updateDiv.innerHTML = updateHTML.join('');
	}
	else {
		var detailContent = zen('tabDetailContents');
		detailContent.seed = this.selectedId;
		detailContent.refreshContents();
		var json = zen('alertFields');
		var alertID = zen('alertID');
		alertID.value = this.selectedId;
		json.reloadContents();
		var fieldData = json.getContentObject();
		var updateForm = zen('updateAlertForm');
		var noAlertHTML = zen('updateNoAlertHTML');
		var showUpdateForm = false;
		if (fieldData && (fieldData.alertID = this.selectedId) && (fieldData.props)) {
			var values = { "%ID": fieldData.alertID };
			for (var propName in fieldData.props) {
				if (fieldData.props[propName]) {
					values[propName] = fieldData.props[propName].value;
				}
			}
			showUpdateForm = true;
			if (updateForm) updateForm.setValuesByName(values);
		}
		if (updateForm) updateForm.setHidden(!showUpdateForm);
		if (noAlertHTML) noAlertHTML.setHidden(showUpdateForm);
	}
}

ClientMethod getDetailHTML(detailHTML) [ Language = javascript ]
{
	if (!detailHTML) detailHTML = [];
	var fieldData = zen('alertFields').getContentObject();
	if (!fieldData) {
		var msg = '<div class="no_data_message">' + $$$Text('No alert selected') + '</div>';
		detailHTML.push(msg);
	}
	else {
		detailHTML.push('<div><table class="detailTable">');
		if (fieldData.fieldSequence && (fieldData.fieldSequence.length > 0) && fieldData.fieldIndex) {
			for (var i = 0; i < fieldData.fieldSequence.length; i++) {
				var fieldName = fieldData.fieldSequence[i];
				var data = fieldData.fieldIndex[fieldName];
				if (data) {
					detailHTML.push('<tr class="detailTableRow">');
					detailHTML.push('<td class="detailTableHeader">');
					detailHTML.push( ( data.header ? data.header : fieldName ) );
					detailHTML.push('</td>');
					detailHTML.push('<td class="detailTableData">');
					detailHTML.push( data.value );
					detailHTML.push('</td>');
					detailHTML.push('</tr>');
				}
			}
		}
		if (fieldData.collSequence && (fieldData.collSequence.length > 0) && fieldData.collIndex && fieldData.collValues) {
			for (var i = 0; i < fieldData.collSequence.length; i++) {
				var collName = fieldData.collSequence[i];
				var collMeta = fieldData.collIndex[collName];
				var collValues = fieldData.collValues[collName];
				if (collMeta && collValues && collMeta.sequence && (collMeta.sequence.length > 0)) {
					detailHTML.push('<tr class="detailTableRow detailTableCollRow">');
					detailHTML.push('<td colspan="2" class="detailTableCollData">');
					detailHTML.push('<span class="detailTableCollHeader">' + ( collMeta.header ? collMeta.header : collName ) + '</span>');
					for (var j = 0; j < collValues.length; j++) {
						detailHTML.push('<div class="detailTableCollDiv">');
						detailHTML.push('<div class="detailTableCollTitle">');
						detailHTML.push( (collMeta.itemHeader ? collMeta.itemHeader : collName ).toString().replace(/%1/g,j+1) );
						detailHTML.push('</div>');
						var data = collValues[j];
						detailHTML.push('<table class="detailCollTable">');
						for (var k = 0; k < collMeta.sequence.length; k++) {
							var fieldName = collMeta.sequence[k];
							detailHTML.push('<tr class="detailCollTableRow">');
							if ((collName == 'Actions') && (fieldName == 'OldValues') && (collMeta.sequence[k+1] == 'NewValues')) {
								k++;
								detailHTML.push('<td colspan="2" class="detailCollValueHistory">');
								detailHTML.push('<table class="detailCollHistoryTable">');
								detailHTML.push('<tr class="detailCollHistoryTableRow">');
								detailHTML.push('<th class="detailCollHistoryTableHeader">' + $$$Text('Property') + '</th>');
								detailHTML.push('<th class="detailCollHistoryTableHeader">' + $$$Text('Old Value') + '</th>');
								detailHTML.push('<th class="detailCollHistoryTableHeader">' + $$$Text('New Value') + '</th>');
								detailHTML.push('</tr>');
								for (var propName in data.OldValues) {
									detailHTML.push('<tr class="detailCollHistoryTableRow">');
									detailHTML.push('<td class="detailCollHistoryTableProp">' + propName + '</td>');
									detailHTML.push('<td class="detailCollHistoryTableValue">' + data.OldValues[propName] + '</td>');
									detailHTML.push('<td class="detailCollHistoryTableValue">' + data.NewValues[propName] + '</td>');
									detailHTML.push('</tr>');
								}
								detailHTML.push('</table>');
								detailHTML.push('</td>');
							}
							else {
								var fieldMeta = collMeta.index[fieldName];
								if (fieldMeta) {
									detailHTML.push('<td class="detailCollTableHeader">' + (fieldMeta.header ? fieldMeta.header : fieldName) + '</td>');
									detailHTML.push('<td class="detailCollTableData">' + data[fieldName] + '</td>');
								}
							}
							detailHTML.push('</tr>');
						}
						detailHTML.push('</table>');
						detailHTML.push('</div>');
					}
					detailHTML.push('</td>');
					detailHTML.push('</tr>');
				}
			}
		}
		detailHTML.push('</table></div>');
	}
}

/// Render the HTML for the Details tab
ClassMethod DrawDetailHTML(pID As %String) As %Status
{
	Set tID = $piece($get(pID),"::",1)
	Set tIsEditable = (+$piece($get(pID),"::",2)) && $system.Security.Check("%Ens_Alerts","WRITE")
	Set tAlert = ##class(Ens.Alerting.ManagedAlert).%OpenId(tID)
	If '$IsObject(tAlert) {
		&html<<div class="no_data_message detailContents">#($$$TextHTML("No alert selected."))#</div>>
	}
	Else {
		If tIsEditable && (tAlert.CurrentOwner '= "") && (tAlert.CurrentOwner '= $username) {
			Set tIsEditable = $system.Security.Check("%Ens_AlertAdministration","USE")
		}
		Set tStatus = tAlert.GetProperties(.tProps,.tCollProps)
		If $$$ISERR(tStatus) Quit tStatus
		
		Set tTableId = "AlertDetailTable"
		&html<<div class="detailTitle detailContents">#($$$TextHTML("Managed Alert Details"))#</div>
		<div class="detailContents">>
		If tIsEditable {
			Set tUpdateCaption = $$$TextHTML("Update Alert")
			Set tReasonPlaceHolder = $$$TextHTML("Please enter a reason for updating the alert.")
			Set tControlOnChange = "this._changed = true; if (this.form) { this.form._changed = true; if (this.form.Reason) { this.form.Reason.style.display = ''; }  }"
			&html<<div id="updateButtonDiv">
				<input type="button" class="commandButton" value="#(tUpdateCaption)#" onclick="zenPage.updateAlert('#(tID)#');" />
			</div>
			<form id="alertUpdateForm" onchange="this._changed = true;">
			<input type="hidden" name="Alert_ID" value="#(+tID)#" />
			<textarea name="Reason" placeholder="#(tReasonPlaceHolder)#" cols="40" rows="5" style="display: none;" required="1"></textarea>>
		}
		&html<<table id="#(tTableId)#" class="detailTable">>
		
		Set tPropSequence = $get(tProps)
		If $listvalid(tPropSequence) {
			For i=1:1:$listlength(tPropSequence) {
				Set tPropName = $listget(tPropSequence,i)
				If (tPropName '= "") && ($data(tProps(tPropName),tPropData)#2) {
					Set tValue = ""
					Try {
						Set tValue = $select(tPropName = "%ID": tID, 1: $property(tAlert, tPropName))
					} Catch {}
					Set tDisplayValue = tValue
					If (tValue = "") && ($listget(tPropData,5) '= "") {
						Set tDisplayValue = $listget(tPropData,5)
					}
					ElseIf (tValue '= "") && $listget(tPropData,6) {
						Try {
							Set tDisplayValue = ..GetDisplayValue(tValue,$listget(tPropData,4))
						} Catch {}
					}
					&html<<tr class="detailTableRow">
						<td class="detailTableHeader">#($zconvert($select($listget(tPropData,1) '= "": $listget(tPropData,1), 1: tPropName),"O","HTML"))#</td>
						<td class="detailTableData" colspan="2">>
						Set tValueHTML = $zconvert(tValue,"O","HTML")
						Set tDisplayHTML = $zconvert(tDisplayValue,"O","HTML")
						If tIsEditable && $case(tPropName, "CurrentOwner": 1, "IsOpen": 1, "EscalationLevel": 1, "NextActionTime": 1, :0) {
							If (tPropName = "CurrentOwner") {
								&html<<select name="CurrentOwner" origValue="#(tValueHTML)#" onchange="#(tControlOnChange)#" value="#(tValueHTML)#">>
								If (tValue = "") {
									Set tUserSelected = "selected=""1"""
									Set tUnassignHTML = $$$Text("Unassigned","Ensemble")
								}
								Else {
									Set tUserSelected = ""
									Set tUnassignHTML = $$$Text("Unassign","Ensemble")
								}
								&html<<option value="" #(tUserSelected)#>#(tUnassignHTML)#</option>>
								
								Set tUsernameHTML = $zconvert($username,"O","HTML")
								Set tMeHTML = $$$TextHTML("Me")
								Set tUserSelected = $select(tValue = $username: "selected=""1""", 1: "")
								&html<<option value="#(tUsernameHTML)#" #(tUserSelected)#>#(tMeHTML)#</option>>

								Kill tAlertUsers
								// Ignore errors
								Do ##class(%SYS.Ensemble).ListAlertingUsers(.tAlertUsers, $namespace)
								#; Add current owner to list if not already there
								If (tValue '= "") && '$data(tAlertUsers(tValue)) {
									Set tAlertUsers(tValue) = ""
								}
								Set tUserKey = ""
								For {
									Set tUserKey = $order(tAlertUsers(tUserKey))
									Quit:(tUserKey = "")
									// The current user has already been handled
									Continue:(tUserKey = $username)
									Set tUserHTML = $zconvert(tUserKey,"O","HTML")
									Set tUserSelected = $select(tValue = tUserKey: "selected=""1""", 1: "")
									&html<<option value="#(tUserHTML)#" #(tUserSelected)#>#(tUserHTML)#</option>>
								}
								&html<</select>>
							}
							ElseIf (tPropName = "IsOpen") {
								&html<<input type="checkbox" origValue="#(tValueHTML)#" onchange="#(tControlOnChange)#" name="IsOpen" #($select(tValue: "checked", 1: ""))# />>
							}
							ElseIf (tPropName = "EscalationLevel") {
								&html<<select name="EscalationLevel" origValue="#(tValueHTML)#" onchange="#(tControlOnChange)#" value="#(+tValue)#">>
								If (tValue > 0) {
									Set tDeEscalate = $$$TextHTML("De-escalate")
									&html<<option value="#(tValue-1)#">#(tDeEscalate)#</option>>
								}
								Set tEscalate = $$$TextHTML("Escalate")
								&html<<option value="#(+tValue)#" selected="1">#(+tValue)#</option>
								<option value="#(tValue+1)#">#(tEscalate)#</option>
								</select>>
							}
							ElseIf (tPropName = "NextActionTime") {
								Set tMinus(30) = $$$TextHTML("Thirty minutes earlier")
								Set tMinus(60) = $$$TextHTML("One hour earlier")
								Set tPlus(30) = $$$TextHTML("Thirty minutes later")
								Set tPlus(60) = $$$TextHTML("One hour later")
								Set tPlus(120) = $$$TextHTML("Two hours later")
								Set tPlus(240) = $$$TextHTML("Four hours later")
								Set tPlus(360) = $$$TextHTML("Six hours later")
								Set tPlus(720) = $$$TextHTML("Twelve hours later")
								Set tPlus(1440) = $$$TextHTML("One day later")
								Set tPlus(2880) = $$$TextHTML("Two days later")
								Set tPlus(4320) = $$$TextHTML("Three days later")
								;Set tPlus(5760) = $$$TextHTML("Four days later")
								Set tPlus(10080) = $$$TextHTML("One week later")
								Set tPlus(20160) = $$$TextHTML("Two weeks later")
								Set tNowPlus(30) = $$$TextHTML("Thirty minutes from now")
								Set tNowPlus(60) = $$$TextHTML("One hour from now")
								Set tNowPlus(120) = $$$TextHTML("Two hours from now")
								Set tNowPlus(240) = $$$TextHTML("Four hours from now")
								Set tNowPlus(360) = $$$TextHTML("Six hours from now")
								Set tNowPlus(720) = $$$TextHTML("Twelve hours from now")
								Set tNowPlus(1440) = $$$TextHTML("One day from now")
								Set tNowPlus(2880) = $$$TextHTML("Two days from now")
								Set tNowPlus(4320) = $$$TextHTML("Three days from now")
								;Set tNowPlus(5760) = $$$TextHTML("Four days from now")
								Set tNowPlus(10080) = $$$TextHTML("One week from now")
								Set tNowPlus(20160) = $$$TextHTML("Two weeks from now")
								
								&html<<select name="NextActionTime" origValue="#(tValueHTML)#" onchange="#(tControlOnChange)#" value="#(tValueHTML)#">>
								Set tMins = ""
								For {
									Set tMins = $order(tMinus(tMins),-1,tCaption)
									Quit:(tMins = "")
									Set tNewTS = $zconvert($system.SQL.DATEADD("mi",-tMins,tValue),"O","HTML")
									&html<<option value="#(tNewTS)#">#(tCaption)#</option>>
								}
								&html<<option value="#(tValueHTML)#" selected="1">#(tDisplayHTML)#</option>>
								Set tMins = ""
								For {
									Set tMins = $order(tPlus(tMins),1,tCaption)
									Quit:(tMins = "")
									Set tNewTS = $zconvert($system.SQL.DATEADD("mi",tMins,tValue),"O","HTML")
									&html<<option value="#(tNewTS)#">#(tCaption)#</option>>
								}
								Set tNow = ##class(Ens.DataType.UTC).timeUTC()
								Set tMins = ""
								For {
									Set tMins = $order(tNowPlus(tMins),1,tCaption)
									Quit:(tMins = "")
									&html<<option value="NOW+#(tMins)#">#(tCaption)#</option>>
								}
								&html<</select>>
							}
						}
						Else {
							Write tDisplayHTML
						}
						&html<</td>
					</tr>>
				}
			}
		}
		Set tCollSequence = $get(tCollProps)
		If $listvalid(tCollSequence) {
			Set tContractAll = $$$TextHTML("Contract all")
			Set tExpandAll = $$$TextHTML("Expand all")
			Set tContractItem = $$$TextHTML("Contract this item")
			Set tExpandItem = $$$TextHTML("Expand this item")
			For i=1:1:$listlength(tCollSequence) {
				Set tCollName = $listget(tCollSequence, i)
				If (tCollName '= "") && ($data(tCollProps(tCollName),tCollData)#2) {
					Set tCollRef = ""
					Set tCollCount = 0
					Try {
						Set tCollRef = $property(tAlert, tCollName)
						Set tCollCount = tCollRef.Count()
					}
					Catch {}
					Set tPropSequence = $listget(tCollData,5)
					If $IsObject(tCollRef) && tCollCount && $listvalid(tPropSequence) && $listlength(tPropSequence) {
						Set tCollNameHTML = $zconvert(tCollName,"O","HTML")
						&html<<tr class="detailTableRow detailTableCollRow">
							<td colspan="3" class="detailTableCollData detailTableCollHeader">
								<span onclick="zenPage.toggleAllCollections('#(tTableId)#','detail_#(tCollNameHTML)#',#(tCollCount)#,false);" style="cursor: pointer;" title="#(tContractAll)#">&nbsp;[-]&nbsp;&nbsp;</span>
								#($zconvert($select($listget(tCollData,1) '= "": $listget(tCollData,1), 1: tCollName),"O","HTML"))#
								<span onclick="zenPage.toggleAllCollections('#(tTableId)#','detail_#(tCollNameHTML)#',#(tCollCount)#,true);" style="cursor: pointer;" title="#(tExpandAll)#">&nbsp;&nbsp;[+]&nbsp;</span>
							</td>
						</tr>>
						
						Set tItemTitle = $select($listget(tCollData,4) '= "": $listget(tCollData,4), 1: tCollName _ " %1")
						For j=1:1:tCollCount {
							Set tCollObject = tCollRef.GetAt(j)
							If '$IsObject(tCollObject) Continue
							Set tItemExpanded = (j = tCollCount)
							Set tFormattedTitle = $$$FormatTextHTML(tItemTitle,j)
							&html<<tr id="detail_#(tCollNameHTML)#_#(j)#" class="detailTableRow detailTableCollRow detailTableToggleRow" currVisible="#(j = tCollCount)#">
								<td colspan="3" class="detailTableCollTitle" onclick="zenPage.toggleCollectionDisplay('#(tTableId)#','detail_#(tCollNameHTML)#_#(j)#');" title="#($select(j=tCollCount: tContractItem, 1: tExpandItem))#">
									<img id="detail_#(tCollNameHTML)#_#(j)#_toggle" src="images/disclosure-#($select(tItemExpanded: "expanded", 1: "contracted"))#.gif" />
									&nbsp;#(tFormattedTitle)#
								</td>
							</tr>>
							Set tStyle = $select(tItemExpanded: "", 1: "style=""display: none;""")
							For k=1:1:$listlength(tPropSequence) {
								Set tPropName = $listget(tPropSequence,k)
								If (tPropName '= "") && ($data(tCollProps(tCollName,tPropName),tPropData)#2) {
									If (tCollName = "Actions") && (tPropName = "OldValues") && ($listget(tPropSequence,k+1) = "NewValues") && $IsObject(tCollObject.OldValues) && $IsObject(tCollObject.NewValues){
										Set k = k + 1
										#; Only write out values if there are some
										If (tCollObject.OldValues.Next("") '= "") { 
											&html<<tr class="detailCollHistoryTableRow detail_#(tCollNameHTML)#_#(j)#_row" #(tStyle)#>
												<th class="detailCollHistoryTableHeader detailCollHistoryTableProperty">#($$$TextHTML("Property"))#</th>
												<th class="detailCollHistoryTableHeader detailCollHistoryTableOldValue">#($$$TextHTML("Old Value"))#</th>
												<th class="detailCollHistoryTableHeader detailCollHistoryTableNewValue">#($$$TextHTML("New Value"))#</th>
											</tr>>
											Set tKey = ""
											For {
												Set tOldValue = tCollObject.OldValues.GetNext(.tKey)
												Quit:(tKey = "")
												Set tNewValue = tCollObject.NewValues.GetAt(tKey)
												Set tPropName = tKey
												If $data(tCollProps(tCollName,tPropName,tKey),tValueData)#2 {
													Set tOldValue = ..GetDisplayValue(tOldValue,$listget(tValueData,4))
													Set tNewValue = ..GetDisplayValue(tNewValue,$listget(tValueData,4))
													If ($listget(tValueData,1) '= "") {
														Set tPropName = $listget(tValueData,1)
													}
												}
												&html<<tr class="detailCollHistoryTableRow detail_#(tCollNameHTML)#_#(j)#_row" #(tStyle)#>
													<td class="detailCollHistoryTableProperty">#($zconvert(tPropName,"O","HTML"))#</td>
													<td class="detailCollHistoryTableValue detailCollHistoryTableOldValue">#($zconvert(tOldValue,"O","HTML"))#</td>
													<td class="detailCollHistoryTableValue detailCollHistoryTableNewValue">#($zconvert(tNewValue,"O","HTML"))#</td>
												</tr>>
											}
										}
									}
									Else {
										Set tValue = ""
										Try {
											Set tValue = $property(tCollObject,tPropName)
											Set tValue = ..GetDisplayValue(tValue,$listget(tPropData,4))
										} Catch {}
										&html<<tr class="detailCollTableRow detail_#(tCollNameHTML)#_#(j)#_row" #(tStyle)#>
											<td class="detailCollTableHeader">#($zconvert($select($listget(tPropData,1) '= "": $listget(tPropData,1), 1: tPropName),"O","HTML"))#</td>
											<td class="detailCollTableData" colspan="2">#($zconvert(tValue,"O","HTML"))#</td>
										</tr>>
										
									}
								}
							}
						}
					}
				}
			}
		}
		&html<</table>>
		If tIsEditable {
			&html<</form>>
		}
		&html<</div>>
	}
	Quit $$$OK
}

Method DrawUpdateHTML(pID As %String) As %Status
{
	Set tAlert = ##class(Ens.Alerting.ManagedAlert).%OpenId($get(pID))
	If '$IsObject(tAlert) {
		&html<<div class="no_data_message detailContents">#($$$TextHTML("No alert selected."))#</div>>
	}
	Else {
		Set tStatus = tAlert.GetProperties(.tProps,.tCollProps)
		If $$$ISERR(tStatus) Quit tStatus

		#; For now, ignore any collections - data should be stored in simple properties.
		Set tTableId = "AlertUpdateTable"
		&html<<div class="detailTitle detailContents">#($$$TextHTML("Update Managed Alert"))#</div>
		<div class="detailContents">
			<table id="#(tTableId)#" class="detailTable">>
		
		Set tPropSequence = $get(tProps)
		If $listvalid(tPropSequence) {
			For i=1:1:$listlength(tPropSequence) {
				Set tPropName = $listget(tPropSequence,i)
				If (tPropName '= "") && ($data(tProps(tPropName),tPropData)#2) {
					Set tValue = ""
					Try {
						Set tValue = $select(tPropName = "%ID": pID, 1: $property(tAlert, tPropName))
					} Catch {}
					If (tValue = "") && ($listget(tPropData,5) '= "") {
						Set tValue = $listget(tPropData,5)
					}
					ElseIf (tValue '= "") && $listget(tPropData,6) {
						Try {
							Set tValue = ..GetDisplayValue(tValue,$listget(tPropData,4))
						} Catch {}
					}
					&html<<tr class="detailTableRow">
						<td class="detailTableHeader">#($zconvert($select($listget(tPropData,1) '= "": $listget(tPropData,1), 1: tPropName),"O","HTML"))#</td>
						<td class="detailTableData" colspan="2">#($zconvert(tValue,"O","HTML"))#</td>
					</tr>>
				}
			}
		}
	}
}

ClientMethod toggleAllCollections(tableId, rowBase, maxRow, show) [ Language = javascript ]
{
	if (maxRow && (typeof maxRow == 'number')) {
		show = !!show;
		for (var i = 1; i <= maxRow; i++) {
			this.toggleCollectionDisplay(tableId,rowBase + '_' + i,show);
		}
	}
}

ClientMethod toggleCollectionDisplay(tableId, rowId, forceVal) [ Language = javascript ]
{
	var table = document.getElementById(tableId);
	if ((!table) || (typeof table.getElementsByClassName != 'function')) return;

	var rowEl = document.getElementById(rowId);
	if (!rowEl) return;
	var currVisible = parseInt(rowEl.getAttribute('currVisible'),10);
	currVisible = (currVisible == 1 ? true : false);
	if (typeof forceVal != 'undefined') {
		currVisible = !!forceVal;
	}
	else {
		currVisible = !currVisible;
	}
	var newDisplay = currVisible ? '' : 'none';
	
	var rows = table.getElementsByClassName(rowId + '_row');
	if (rows && rows.length) {
		for (var i = 0; i < rows.length; i++) {
			var row = rows[i];
			if (row && row.style) row.style.display = newDisplay;
		}
	}
	var toggle = document.getElementById(rowId + '_toggle');
	if (toggle) {
		toggle.src = 'images/disclosure-' + (currVisible ? 'expanded' : 'contracted') + '.gif';
	}
	var rowCell = rowEl.firstElementChild;
	if (rowCell && (rowCell.nodeName.toString().toUpperCase() == 'TD')) {
		rowCell.title = currVisible ? $$$Text('Contract this item') : $$$Text('Expand this item');
	}
	rowEl.setAttribute('currVisible',(currVisible ? '1' : '0'));
}

ClassMethod GetDisplayValue(pValue As %String = "", pDataType As %String = "") As %String
{
	If (pValue = "") || (pDataType = "") Quit ""
	Quit $case(pDataType,
		"Ens.DataType.UTC": $$$timeUTCtoLocal(pValue),
		"Ens.DataType.ManagedAlertAction": ##class(Ens.DataType.ManagedAlertAction).GetText(pValue),
		: pValue
	)
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
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
				: "")
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
		var detailsTabGroup = zen('alertTabGroup');

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 15;

		divResults.style.height = hgt + 'px';
		divSearchPanel.style.height = hgt + 'px';
		divDetailsPanel.style.height = (hgt - 30) + 'px';
		divDetailsGroup.style.height = hgt + 'px';
		detailsTabGroup.setBodySize(hgt - 30 - detailsTabGroup.getTabBarElement().offsetHeight, null);
		
		var searchWidth = divSearchPanel.offsetWidth;
		var detailExpanderWidth = 0;
		var detailExpander = zen('detailExpander');
		if (detailExpander) {
			detailExpanderWidth = detailExpander.getEnclosingDiv().offsetWidth + 10 + (zenIsIE * 12);
		}
		if (!this.detailsHidden) {
			var detailsWidth = parseInt(this.detailsWidth / 100 * winWidth, 10);
			divDetailsGroup.style.width = detailsWidth + 'px';
			var detailPanelWidth = detailsWidth - detailExpanderWidth - 15 - (zenIsIE * 5);
			divDetailsPanel.style.width = detailPanelWidth + 'px';
			detailsTabGroup.setBodySize(null,detailPanelWidth - 10);
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
			var noAlertDiv = document.getElementById('updateNoAlertHTML_div');
			if (noAlertDiv) noAlertDiv.innerHTML = $$$Text('No alert selected.');
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

}
