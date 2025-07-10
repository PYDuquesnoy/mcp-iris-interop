/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Page focused on allowing users to interact with Managed Alerts that pertain to them, broken down by when action should be taken.
Class EnsPortal.ManagedAlerts Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Managed Alerts";

/// User needs READ permissions on the %Ens_Alerts resource to view this page.
Parameter RESOURCE = "%Ens_Alerts:READ";

/// User needs WRITE permissions on the %Ens_Alerts resource to make changes to Managed Alerts.
Parameter EDITRESOURCE = "%Ens_Alerts:WRITE";

Property msgAlertDetails As %String [ InitialExpression = {$$$TextHTML("Alert Details")} ];

Property canViewAllAlerts As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_AlertAdministration","USE")} ];

Property refreshRate As %Integer [ InitialExpression = 0, Internal ];

XData Style
{
<style type="text/css">
#myAlerts,
#unassignedAlerts,
#alertDetailsWrapper {
	overflow-y: auto;
}
table.alertTable {
	font-size: 12px;
}
table.alertTable td,
table.alertTable th {
	padding: 2px;
	cursor: default;
}
table.alertTable th {
	color: #3b84bc;
	text-align: left;
}
table.alertTable tr {
	line-height: 19px;
}
table.alertTable tr.oddRow {
	background-color: #F1F0E7;
}
table.alertTable tr:hover {
	background-color: #FFEEAA;
}
table.alertTable tr:hover {
	background-color: #FFEEAA;
}
table.alertTable tr.headerRow:hover {
	background: none;
}
table.alertTable tr.selectedRow {
	background-color: #2F6280;
	color: white;
	font-weight: bold;
}
table.alertTable th.sortHeader {
	cursor: pointer;
}
.sessionCell {
	background-color: lightgreen;
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
#alertDetailsWrapper {
	background-color: #E0E0D0;
	border-bottom: 1px solid gray;
	border-left: 1px solid gray;
}
#detailsTitle {
	font-weight: bold;
	vertical-align: bottom;
	line-height: 26px;
	padding-top: 5px;
	padding-left: 10px;
	border-bottom: 1px solid black;
}

.noAlertsMsg {
	font-size: 12px;
	padding: 10px;
}

.NextAction-overdue {
	background-color: orange;
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
	margin-top: 5px;
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
.inlineBlockDiv {
	display: inline-block;
}
.menuDiv {
	vertical-align: top;
	font-size: 14px;
}
.menuItem,
.bucketItem {
	border-bottom: 1px solid gray;
	background-color: #EEEEEE;
	cursor: pointer;
	line-height: 24px;
	padding: 3px;
	padding-left: 5px;
	padding-right: 5px;
}
.menuItem.menuSelected,
.bucketItem.bucketSelected {
	background-color: #C0D9F8;
}

#alertMenu {
	border-right: 1px solid gray;
}
#dataDiv {
	overflow-y: auto;
	border-left: 1px solid gray;
}
#content {
	font-size: 12px;
	border-bottom: 1px solid gray;
}
.escalationCell {
	text-align: center;
}
.escalationOne {
	background-color: yellow;
	color: black;
}
.escalationTwo {
	background-color: orange;
}
.escalationThreePlus {
	background-color: red;
}
</style>
}

/// Contents of this page:
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane name="contentPane" xmlns="http://www.intersystems.com/zen">
<jsonProvider id="alertProvider" OnGetTargetObject="GetAlertData" />
<hgroup>
<html id="content">
<div id="menuDiv" class="menuDiv inlineBlockDiv">
<div id="alertMenu" class="menuDiv inlineBlockDiv"> </div>
<div id="bucketMenu" class="menuDiv inlineBlockDiv"> </div>
</div>
<div id="dataDiv" class="inlineBlockDiv"> </div>
</html>
<html id="alertDetailsWrapper" OnDrawContent="DrawDetailHTML" valign="top">
</html>
</hgroup>
</pane>
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	if (load) {
		if (!Array.prototype.indexOf) {
			Array.prototype.indexOf = function(item,start) {
				var pos = -1;
				var startPos = (typeof start == 'number' ? parseInt(start,10) : 0);
				for (var i = startPos; i < this.length; i++) {
					if (this[i] === item) {
						pos = i;
						break;
					}
				}
				return pos;
			}
		};
		this.initTableData();
		this.buildNextActionIndex();
		this.renderMain();
		if (this.enableAutoRefresh) {
			this.startAutoRefresh();
		}
	}
	this.adjustSizes();
}

/// Set up timer to refresh the contents of the page.
/// Currently hard-coded to 20 seconds.
ClientMethod startAutoRefresh(interval) [ Language = javascript ]
{
	this.stopAutoRefresh();
	if (this.enableAutoRefresh) {
		if (typeof interval != 'number') interval = 20000;
		interval = parseInt(interval,10);
		this.refreshRate = interval/1000;
		this._autoRefresh = setInterval(function() { zenPage.refreshScreen(); },interval);
	}
}

/// Stop the timer that triggers automatic refreshes of the data on the page.
ClientMethod stopAutoRefresh() [ Language = javascript ]
{
	if (this._autoRefresh) {
		clearInterval(zenPage._autoRefresh);
	}
}

/// Reload the JSON data from the server and redraw the page.
ClientMethod refreshScreen() [ Language = javascript ]
{
	var currentMenu = this._tableData.selectedMenu;
	var currentAlert = this._tableData.selectedAlert;
	zen('alertProvider').reloadContents();
	this.buildNextActionIndex();
	this.renderMain();
	this._tableData.selectedRow = null;
	this._tableData.selectedAlert = null;
	var rowID = currentMenu + 'Alerts_row_' + currentAlert;
	var row = document.getElementById(rowID);
	if (row) {
		this.rowClick(row,currentMenu,currentAlert);
	}
	else {
		this.selectAlert(null,currentAlert);
	}
	this.adjustSizes();
}

/// Get the HTML content for the right hand tab.
/// Note that we check for WRITE permissions on the %Ens_Alerts resource in <class>EnsPortal.ManagedAlertViewer</class>.
ClassMethod DrawDetailHTML(pID As %String) As %Status
{
	Quit ##class(EnsPortal.ManagedAlertViewer).DrawDetailHTML(pID _ "::1")
}

/// Get the data from the form and submit to the server.
ClientMethod updateAlert(alertId) [ Language = javascript ]
{
	var alertForm = document.getElementById('alertUpdateForm');
	if (!alertForm) return;
	if (!alertForm._changed) {
		alert($$$Text('No changes have been made to this alert. No changes will be saved.'));
		return;
	}
	if (!alertForm['Alert_ID']) return;
	if (!alertForm.Reason) return;
	if (alertForm.Reason.value === '') {
		alert($$$Text('You must supply a reason when updating an alert.'));
		alertForm.Reason.focus();
		return;
	}
	var updateData = new zenProxy();
	var alertID = alertForm['Alert_ID'].value;
	updateData.ID = alertID;
	updateData.Reason = alertForm.Reason.value;
	var properties = [ 'EscalationLevel', 'CurrentOwner', 'IsOpen', 'NextActionTime' ];
	for (var i=0; i < properties.length; i++) {
		var controlName = properties[i];
		if (alertForm[controlName] && alertForm[controlName]._changed) {
			if (controlName == 'IsOpen') {
				var currValue = (alertForm[controlName].checked ? '1' : '0');
				if (currValue != alertForm[controlName].getAttribute('origValue')) {
					updateData[controlName] = currValue;
				}
			}
			else if ((alertForm[controlName].value != alertForm[controlName].getAttribute('origValue'))) {
				updateData[controlName] = alertForm[controlName].value;
			}
		}
	}
	var err = this.DoUpdateAlert(updateData);
	if (err != '') {
		alert(err);
	}
	else {
		alertForm._changed = false;
		alert($$$Text('Alert updated successfully.'));
		this.refreshScreen();
	}
}

/// Actually update the alert on the server.
ClassMethod DoUpdateAlert(pFormData As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Do pFormData.%CopyToArray(.tChanges)
	Set tAlertId = $get(tChanges("ID"))
	Set tReason = $get(tChanges("Reason"))
	Kill tChanges("ID"), tChanges("Reason")

	Set tActions = 0
	Set tBits("CurrentOwner") = $$$eAlertActionAssign
	Set tBits("IsOpen") = $$$eAlertActionOpenChange
	Set tBits("EscalationLevel") = $$$eAlertActionEscalationChange
	Set tBits("NextActionTime") = $$$eAlertActionNextActionChange
	Set tProp = ""
	For {
		Set tProp = $order(tBits(tProp),1,tBit)
		Quit:(tProp = "")
		If $data(tChanges(tProp))#2 {
			Set tActions = $$$OR(tActions,tBit)
		}
	}
	If tActions {
		If $$$AND(tActions,$$$eAlertActionNextActionChange) && ($extract(tChanges("NextActionTime"),1,4)="NOW+") {
			Set tMins = +$extract(tChanges("NextActionTime"),5,*)
			If ('tMins) || (tMins < 0) {
				Set tStatus = $$$ERROR($$$EnsErrGeneral,"Invalid NextActionTime")
				Quit
			}
			Set tChanges("NextActionTime") = $system.SQL.DATEADD("mi",tMins,$$$timeUTC)
		}
		Set tStatus = ##class(Ens.Alerting.ManagedAlert).UpdateManagedAlert(tAlertId,tActions,.tChanges,tReason)
		If $$$ISERR(tStatus) {
			Quit $system.Status.GetErrorText(tStatus)
		}
		Quit ""
	}
	Quit ""
}

/// Callback to expand and contract all the previous actions in the alert detail pane.
ClientMethod toggleAllCollections(tableId, rowBase, maxRow, show) [ Language = javascript ]
{
	if (maxRow && (typeof maxRow == 'number')) {
		show = !!show;
		for (var i = 1; i <= maxRow; i++) {
			this.toggleCollectionDisplay(tableId,rowBase + '_' + i,show);
		}
	}
}

/// Function to expand and contract the display of a specific action in the alert detail pane.
ClientMethod toggleCollectionDisplay(parentId, rowId, forceVal) [ Language = javascript ]
{
	var parentNode = document.getElementById(parentId);
	if ((!parentNode) || (typeof parentNode.getElementsByClassName != 'function')) return;

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
	
	var rows = parentNode.getElementsByClassName(rowId + '_row');
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

/// Adjust the size of the page to fit the tables in correctly.
ClientMethod adjustSizes() [ Language = javascript ]
{
	var winHeight = zenGetWindowHeight();
	var titleHeight = this.getTitleAreaHeight();
	var bodyHeight = winHeight - titleHeight - 10;
	
	var winWidth = zenGetWindowWidth();
	var detailsWidth = 300;
	var twentyFivePercent = Math.floor(winWidth/4);
	if (twentyFivePercent > 300) {
		detailsWidth = twentyFivePercent;
	}
	var mainWidth = winWidth - detailsWidth;
	
	var alertDetails = zen('alertDetailsWrapper').getEnclosingDiv();
	if (alertDetails) {
		// 1 for border
		alertDetails.style.width = (detailsWidth - 1) + 'px';
		alertDetails.style.height = bodyHeight + 'px';
	}
	var contentDiv = document.getElementById('content');
	if (contentDiv) {
		contentDiv.style.width = mainWidth + 'px';
		contentDiv.style.height = bodyHeight + 'px';
	}
	var menuWidth = 200;
	var menuDiv = document.getElementById('menuDiv');
	if (menuDiv) {
		menuDiv.style.height = bodyHeight + 'px';
		menuWidth = menuDiv.offsetWidth;
	}
	var alertMenuDiv = document.getElementById('alertMenu');
	if (alertMenuDiv) {
		alertMenuDiv.style.height = bodyHeight + 'px';
	}
	var dataDiv = document.getElementById('dataDiv');
	if (dataDiv) {
		dataDiv.style.height = bodyHeight + 'px';
		// 1 for border
		dataDiv.style.width = (mainWidth - menuWidth - 2) + 'px';
	}
}

/// Handle a row being clicked on by the user.
ClientMethod rowClick(row, tableName, alertId) [ Language = javascript ]
{
	if (!row) return;
	if (!this.canSelectNewRow(alertId)) return;

	var currentId = this._tableData.selectedAlert;
	var currentRow = this._tableData.selectedRow;
	if (currentRow) {
		this.removeClassFromElement(currentRow,'selectedRow');
	}
	delete this._tableData.selectedRow;
	if (alertId && (alertId != currentId)) {
		this.addClassToElement(row,'selectedRow');
		this._tableData.selectedRow = row;
		this._tableData.selectedAlert = alertId;
	}
	this.selectAlert(tableName,this._tableData.selectedAlert);
}

ClientMethod deselectAlert() [ Language = javascript ]
{
	if (!this.canSelectNewRow(null)) return false;
	delete this._tableData.selectedRow;
	delete this._tableData.selectedAlert;
	var details = zen('alertDetailsWrapper');
	details.seed = '';
	details.refreshContents(true);
	return true;
}

/// Control the update of the detail pane on the right hand side.
ClientMethod selectAlert(tableName, alertId) [ Language = javascript ]
{
	// don't do anything if alertId is null
	if (!alertId) return;

	var details = zen('alertDetailsWrapper');
	var alertForm = document.getElementById('alertUpdateForm');
	// don't refresh if we have a changed form for the same id
	if (alertId && alertForm && alertForm._changed && (details.seed == alertId)) {
		return;
	}
	var scrollTop = 0;
	var visibleRows = [];
	if (alertForm && (details.seed == alertId)) {
		var detailsDiv = details.getEnclosingDiv();
		if (detailsDiv) scrollTop = detailsDiv.scrollTop;

		var toggleRows = alertForm.getElementsByClassName('detailTableToggleRow');
		for (var i = 0; i < toggleRows.length; i++) {
			var row = toggleRows[i];
			if (parseInt(row.getAttribute('currVisible'),10) == 1) {
				visibleRows.push(row.id);
			}
		}
	}
	details.seed = alertId;
	details.refreshContents(true);
	for (var i = 0; i < visibleRows.length; i++) {
		var rowId = visibleRows[i];
		var row = document.getElementById(rowId);
		// handle case where one of the items was the last one
		var visible = (row && (parseInt(row.getAttribute('currVisible'),10) == 1));
		if (!visible) this.toggleCollectionDisplay('alertUpdateForm',rowId);
	}
	if (scrollTop != 0) {
		var detailsDiv = details.getEnclosingDiv();
		if (detailsDiv) detailsDiv.scrollTop = scrollTop;
	}
}

/// Helper method to make sure that the user doesn't unknowingly lose edits to an alert.
ClientMethod canSelectNewRow(newAlertId) [ Language = javascript ]
{
	var alertForm = document.getElementById('alertUpdateForm');
	var details = zen('alertDetailsWrapper');
	if ((!alertForm) || (!details)) return true;
	var displayedId = details.seed;
	if (alertForm._changed) {
		if (newAlertId != displayedId) {
			return confirm($$$Text('Changes made to the current alert will be discarded. Do you wish to proceed?'))
		}
	}
	return true;
}

/// Initialize the metadata for rendering the table.
ClientMethod initTableData(force) [ Language = javascript ]
{
	if (this._tableData && !force) return;
	this._tableData = {
		"currentBucket": "overdue",
		"sort": {
			"property": "NextActionTime",
			"ascending": true
		},
		"myAlerts": {
			"selected": {},
			"indexName": "my",
			"title": $$$Text('My Alerts')
		},
		"unassignedAlerts": {
			"selected": {},
			"indexName": "unassigned",
			"title": $$$Text('Unassigned Alerts')
		}
	};
	if (this.canViewAllAlerts) {
		this._tableData.allAlerts = {
			"selected": {},
			"indexName": "all",
			"title": $$$Text('All Alerts')
		};
	}
}

/// Helper method to create a "bucket" for indexing purposes.
ClientMethod createBucket() [ Language = javascript ]
{
	return {
		"overdue": [],
		"today": [],
		"tomorrow": [],
		"week": [],
		"other": []
	};
}

/// Build an index based on NextAction so that we have our time-based buckets.
ClientMethod buildNextActionIndex() [ Language = javascript ]
{
	if (!this._buckets) this._buckets = [ "overdue", "today", "tomorrow", "week", "other" ];
	if (!this._secondary) {
		this._secondary = {
			"LastActionTime": this.timeSort,
			"SourceConfigName": this.alphaSort,
			"EscalationLevel": this.alphaSort,
			"Production": this.alphaSort,
			"AlertText": this.alphaSort,
			"NextActionTime": this.timeSort,
			"CurrentOwner": this.alphaSort
		};
	}
	this._alertIndex = {};

	var baseList = [ 'my', 'unassigned', 'all' ];
	var sortData = {};
	for (var i = 0; i < baseList.length; i++) {
		this._alertIndex[baseList[i]] = {
			"list":  [],
			"buckets": {
				"NextActionTime": this.createBucket()
			}
		};
		sortData[baseList[i]] = [];
	};

	var alertData = zen('alertProvider').getContentObject();
	if (alertData) {
		var timeData = alertData.timeData;

		for (var i=0; i<baseList.length; i++) {
			var base = baseList[i];
			for (var id in alertData[base]) {
				if (id.charAt(0) != '_') {
					this._alertIndex[base].list.push(id);
					var currAlert = alertData[base][id];
					sortData[base].push( { "id": id, "value": currAlert.NextActionTime } );
				}
			}
			sortData[base].sort(zenPage.timeSort);
			var timeList = [];
			for (var j = 0; j < sortData[base].length; j++) {
				var obj = sortData[base][j];
				if (obj && obj.id) timeList.push(obj.id);
			}
			var nextActionBuckets = this._alertIndex[base].buckets.NextActionTime;
			for (var j = 0; j < timeList.length; j++) {
				var alertId = timeList[j];
				var currAlert = alertData[base][alertId];
				if (currAlert) {
					var nextAction = currAlert.NextActionTime;
					if (this.isOverdue(nextAction,timeData.yesterday,timeData.now)) {
						currAlert._nextAction = 'overdue';
					}
					else if (this.timestampLTEDate(nextAction,timeData.today)) {
						currAlert._nextAction = 'today';
					}
					else if (this.timestampLTEDate(nextAction,timeData.tomorrow)) {
						currAlert._nextAction = 'tomorrow';
					}
					else if (this.timestampLTEDate(nextAction,timeData.week)) {
						currAlert._nextAction = 'week';
					}
					else {
						currAlert._nextAction = 'other';
					}
					nextActionBuckets[currAlert._nextAction].push(alertId);
				}
			}
		}
	}
}

/// Helper method to build secondary indices for sorting on other fields defined in the runtime <code>zenPage._secondary</code>
/// object. The sorting happends within the buckets that already exist for the main page, and occurs on demand as a user
/// may not want to sort on any of these fields and there is no need to do the work unless it is explicitly requested.
ClientMethod buildSecondaryIndex(propName, base, bucket) [ Language = javascript ]
{
	if (!(propName && base && bucket && this._secondary && this._secondary[propName] && this._alertIndex[base])) return;
	if (propName == 'NextActionTime') return;
	var alertData = zen('alertProvider').getContentObject();
	if ((!alertData) || (!alertData[base])) return;
	if (!this._alertIndex[base].buckets[propName]) {
		this._alertIndex[base].buckets[propName] = this.createBucket();
	}
	if (this._alertIndex[base].buckets[propName][bucket].length > 0) return;
	var nextActionBucket = this._alertIndex[base].buckets.NextActionTime[bucket];
	if (!nextActionBucket) return;
	var sortList = [];
	for (var i = 0; i < nextActionBucket.length; i++) {
		var alertID = nextActionBucket[i];
		var currAlert = alertData[base][alertID];
		if (currAlert) {
			sortList.push( { "id": alertID, "value": currAlert[propName], "nextAction": currAlert.NextActionTime } );
		}
	}
	sortList.sort(this._secondary[propName]);
	var newList = [];
	for (var i = 0; i < sortList.length; i++) {
		var obj = sortList[i];
		if (obj && obj.id) newList.push(obj.id);
	}
	this._alertIndex[base].buckets[propName][bucket] = newList;
}

/// Helper method to modify the sort options for the table.
ClientMethod toggleSort(propName) [ Language = javascript ]
{
	if ((!this._secondary) || !this._secondary[propName]) {
		return;
	}
	if ((!this._tableData) || (!this._tableData.sort)) {
		return;
	}
	var asc = true;
	if (propName == this._tableData.sort.property) {
		asc = !this._tableData.sort.ascending;
	}
	// default EscalationLevel to largest first
	else if (propName == 'EscalationLevel') {
		asc = false;
	}
	this._tableData.sort.property = propName;
	this._tableData.sort.ascending = asc;
	this.renderData();
}

/// Helper function to determine whether <var>timestamp</var> occurred
/// on or before <var>date</var>.
ClientMethod timestampLTEDate(timestamp, date) [ Language = javascript ]
{
	if ((!timestamp) || (!date)) return false;
	var datePart = timestamp.substring(0,timestamp.indexOf(' '));
	return ((datePart == date) || (datePart < date));
}

/// Helper function to determine whether <var>timestamp</var> lies in the past.
ClientMethod isOverdue(timestamp, yesterday, now) [ Language = javascript ]
{
	if (this.timestampLTEDate(timestamp,yesterday)) return true;
	if (!this.timestampLTEDate(timestamp,now.substring(0,now.indexOf(' ')))) return false;
	// has today's date
	var timePart = timestamp.substring(timestamp.indexOf(' ')+1);
	var nowTime = now.substring(now.indexOf(' ')+1);
	return (timePart < nowTime);
}

/// Helper function used as an alphabetical array sort function.
/// Note that if the objects in the array include information about
/// the NextActionTime, the sort will take that into account for equivalent strings,
/// and will sort in ascending ID order if not.
ClientMethod alphaSort(objA, objB) [ Language = javascript ]
{
	if (objA && objB && (objA.value != null) && (objB.value != null)) {
		var valA = String(objA.value).toLowerCase();
		var valB = String(objB.value).toLowerCase();
		if (valA < valB) {
			return -1;
		}
		else if (valA > valB) {
			return 1;
		}
		if (objA.nextAction && objB.nextAction) {
			return zenPage.timeSort( { "id": objA.id, "value": objA.nextAction }, { "id": objB.id, "value": objB.nextAction } );
		}
		return (parseInt(objA.id,10) - parseInt(objB.id,10));
	}
	return 0;
}

/// Helper function used as an array sort function for timestamps.
/// Note that if the timestamps match, the values will be sorted in ascending ID order.
ClientMethod timeSort(objA, objB) [ Language = javascript ]
{
	if (objA && objB && (objA.value != null) && (objB.value != null)) {
		var valA = String(objA.value);
		var valB = String(objB.value);
		var dateA = valA.substring(0,valA.indexOf(' '));
		var dateB = valB.substring(0,valB.indexOf(' '));
		if (dateA < dateB) {
			return -1;
		}
		else if (dateB < dateA) {
			return 1;
		}
		// date is the same
		var timeA = valA.substring(valA.indexOf(' ')+1);
		var timeB = valB.substring(valB.indexOf(' ')+1);
		timeA = parseFloat(timeA.replace(/:/g,''));
		timeB = parseFloat(timeB.replace(/:/g,''));
		if ((timeA == timeB) && objA.id && objB.id) {
			return (parseInt(objA.id,10) - parseInt(objB.id,10));
		}
		return timeA-timeB;
	}
	return 0;
}

/// Handle user click on a menu.
ClientMethod selectMenu(menuName) [ Language = javascript ]
{
	if (!this._tableData[menuName + 'Alerts']) return;
	if (this._tableData.selectedMenu != menuName) {
		var newDiv = document.getElementById(menuName + 'Menu');
		if (newDiv) {
			if (!this.deselectAlert()) return;
			var oldDiv = document.getElementById(this._tableData.selectedMenu + 'Menu');
			this.removeClassFromElement(oldDiv,'menuSelected');
			this.addClassToElement(newDiv,'menuSelected');
			this._tableData.selectedMenu = menuName;
			this.renderData(true);
		}
	}
}

/// Handle user selection of a bucket.
ClientMethod selectBucket(menuName, bucketName, bucketValue) [ Language = javascript ]
{
	if ((!this._tableData[menuName + 'Alerts']) || (!this._alertIndex[menuName]) || (!this._alertIndex[menuName].buckets[bucketName]) || (!this._alertIndex[menuName].buckets[bucketName][bucketValue])) return;
	if (this._tableData.currentBucket != bucketValue) {
		var newBucket = document.getElementById('menu_' + menuName + '_bucket_' + bucketValue);
		if (newBucket) {
			if (!this.deselectAlert()) return;
			var oldBucket = document.getElementById('menu_' + menuName + '_bucket_' + this._tableData.currentBucket);
			this.removeClassFromElement(oldBucket,'bucketSelected');
			this.addClassToElement(newBucket,'bucketSelected');
			this._tableData.currentBucket = bucketValue;
			this.renderData(true);
		}
	}
}

/// Get the localised strings for the buckets we expose.
ClientMethod getBucketCaption(bucket) [ Language = javascript ]
{
	var bucketName = bucket;
	switch (bucket) {
		case 'overdue':
			bucketName = $$$Text('Overdue');
			break;
		case 'today':
			bucketName = $$$Text('Today');
			break;
		case 'tomorrow':
			bucketName = $$$Text('Tomorrow');
			break;
		case 'week':
			bucketName = $$$Text('This Week');
			break;
		case 'other':
			bucketName = $$$Text('Later');
			break;
	};
	return bucketName;
}

/// Helper function to add a class to an element.
ClientMethod addClassToElement(element, addClass) [ Language = javascript ]
{
	if ((!element) || (!addClass) || (addClass === '')) return;	
	var classes = element.className.toString().split(' ');
	if (classes.indexOf(addClass) == -1) {
		classes.push(addClass);
	}
	element.className = classes.join(' ');
}

/// Helper function to remove a class from an element.
ClientMethod removeClassFromElement(element, remClass) [ Language = javascript ]
{
	if ((!element) || (!remClass) || (remClass === '')) return;	
	var classes = element.className.toString().split(' ');
	var selPos = classes.indexOf(remClass);
	while (selPos > -1) {
		classes.splice(selPos,1);
		selPos = classes.indexOf(remClass);
	}
	element.className = classes.join(' ');
}

/// Render the menu and table for the page.
ClientMethod renderMain() [ Language = javascript ]
{
	var mainMenuDiv = document.getElementById('alertMenu');
	var count = {
		"my": this._alertIndex.my.list.length,
		"unassigned": this._alertIndex.unassigned.list.length
	};
	if (this.canViewAllAlerts) {
		count.all = this._alertIndex.all.list.length;
	}
	var indexName;
	if (this._tableData.selectedMenu) {
		indexName = this._tableData.selectedMenu;
	}
	else {
		indexName = ((count.my == 0) && (count.unassigned > 0) ? 'unassigned' : 'my');
		this._tableData.selectedMenu = indexName;
	}
	var menuHTML = [];
	menuHTML.push('<div id="myMenu" class="menuItem' + (indexName == 'my' ? ' menuSelected' : '') + '" onclick="zenPage.selectMenu(\'my\');">' + $$$Text('My Alerts') + '&nbsp;(<span id="myAlertCount">' + count.my + '</span>)</div>');
	menuHTML.push('<div id="unassignedMenu" class="menuItem' + (indexName == 'unassigned' ? ' menuSelected' : '') + '" onclick="zenPage.selectMenu(\'unassigned\');">' + $$$Text('Unassigned Alerts') + '&nbsp;(<span id="unassignedAlertCount">' + count.unassigned + '</span>)</div>');
	if (this.canViewAllAlerts) {
		menuHTML.push('<div id="allMenu" class="menuItem' + (indexName == 'all' ? ' menuSelected' : '') + '" onclick="zenPage.selectMenu(\'all\');">' + $$$Text('All Alerts') + '&nbsp;(<span id="unassignedAlertCount">' + count.all + '</span>)</div>');
	}
	mainMenuDiv.innerHTML = menuHTML.join('');
	this.renderData();
}

/// Re-render the table and inner menus for the page.
ClientMethod renderData(adjust) [ Language = javascript ]
{
	var indexName = this._tableData.selectedMenu;
	var bucketMenuDiv = document.getElementById('bucketMenu');
	var dataDiv = document.getElementById('dataDiv');
	var bucketHTML = [];
	var dataHTML = [];

	if (this._tableData && this._tableData.sort) {
		for (var i=0; i < this._buckets.length; i++) {
			var bucketName = this._buckets[i];
			var caption = this.getBucketCaption(bucketName);
			var bucketCount = this._alertIndex[indexName].buckets.NextActionTime[bucketName].length;
			bucketHTML.push('<div id="menu_' + indexName + '_bucket_' + bucketName + '" class="bucketItem' + (bucketName == this._tableData.currentBucket ? ' bucketSelected' : '') + '" onclick="zenPage.selectBucket(\'' + indexName + '\',\'NextActionTime\',\'' + bucketName + '\');">' + caption + '&nbsp;(<span id="bucket_' + bucketName + '_count">' + bucketCount + '</span>)</div>');
		}
		if ((!this._alertIndex[indexName].buckets[this._tableData.sort.property]) && this._secondary && this._secondary[this._tableData.sort.property]) {
			this.buildSecondaryIndex(this._tableData.sort.property,indexName,this._tableData.currentBucket);
		}
		dataHTML.push('<div class="dataWrapper inlineBlockDiv">');
		dataHTML.push(this.getTableHTML(indexName + 'Alerts',this._tableData.sort.property,this._tableData.currentBucket));
		dataHTML.push('</div>');
	}
	bucketMenuDiv.innerHTML = bucketHTML.join('');
	dataDiv.innerHTML = dataHTML.join('');
	if (adjust) this.adjustSizes();
}

/// Get the HTML for the table.
ClientMethod getTableHTML(rootName, bucketName, bucketValue) [ Language = javascript ]
{
	if (!this._tableData[rootName]) return;
	var html = [];
	var tableId = rootName + 'Table';
	if (bucketName) tableId += '_' + bucketName;
	html.push('<div class="tableWrapper">');
	var indexName = this._tableData[rootName].indexName;
	var hasAlerts = (this._alertIndex[indexName].buckets[bucketName] && this._alertIndex[indexName].buckets[bucketName][bucketValue] && this._alertIndex[indexName].buckets[bucketName][bucketValue].length);
	if (!hasAlerts) {
		var noAlertsMsg = ''
		if (bucketName) {
			noAlertsMsg = $$$Text("There are no alerts in this category.");
		}
		else {
			if (rootName == 'myAlerts') {
				noAlertsMsg = $$$Text('You have no alerts assigned to you.');
			}
			else if (rootName == 'unassignedAlerts') {
				noAlertsMsg = $$$Text('There are no unassigned alerts.');
			}
			else {
				noAlertsMsg = $$$Text('There are no alerts.');
			}
		}
		html.push('<div id="' + rootName + '_no_data" class="noAlertsMsg">' + noAlertsMsg + '</div>');
		html.push('</div>');
		return html.join('');
	}
	html.push('<table id="' + tableId + '" class="alertTable">');
	var props = [ 'AlertText', 'NextActionTime', 'LastActionTime', 'EscalationLevel', 'SourceConfigName', 'Production', 'SessionId' ];
	var propTitles = [ $$$Text('Alert Text'), $$$Text('Next Action Time'), $$$Text('Last Action Time'), $$$Text('Escalation Level'), $$$Text('Source'), $$$Text('Production'), $$$Text('SessionId') ];
	if (rootName == 'allAlerts') {
		props.push('CurrentOwner');
		propTitles.push($$$Text('Current Owner'));
	}
	html.push('<tr id="' + rootName + '_headerRow" class="headerRow">');
	for (var i = 0; i < propTitles.length; i++) {
		var titleAttribs = '';
		if (this._secondary[props[i]]) {
			titleAttribs = ' class="sortHeader" onclick="zenPage.toggleSort(\'' + props[i] + '\');" title="' + zenEscapeHTML($$$Text('Click to sort by this column')) + '"';
		}
		html.push('<th' + titleAttribs +'>' + propTitles[i] + '</th>');
	}
	var sourceList = this._alertIndex[indexName].buckets[bucketName][bucketValue];
	var sortAsc = this._tableData.sort.ascending;
	var jsonData = zen('alertProvider').getContentObject();
	var sourceData = jsonData[indexName];
	var count = 0;
	if (sourceData && sourceList && sourceList.length) {
		if (!sortAsc) {
			// copy the array and reverse for descending order
			sourceList = [].concat(sourceList);
			sourceList.reverse();
		}
		var rowClass;
		var sessionTitle = zenEscapeHTML($$$Text('Click to view a visual trace of the session'));
		var endIndex 
		for (var i=0; i<sourceList.length; i++) {
			var id = sourceList[i];
			var alertData = sourceData[id];
			if (id) {
				count++;
				rowClass = ((count % 2) ? ' class="oddRow"' : '');
				html.push('<tr id="' + rootName + '_row_' + id + '" value="' + id + '" onclick="zenPage.rowClick(this,\''+ rootName + '\',\'' + id + '\');"' + rowClass + '>');
				for (var j = 0; j < props.length; j++) {
					var propName = props[j];
					if (propName == 'SessionId') {
						html.push('<td class="sessionCell"><a class="sessionLink" href="#" title="'+ sessionTitle + '" onclick="zenPage.showTrace(\'' + alertData[propName] + '\',event); return false;">' + alertData[propName] + '</a></td>');
					}
					else if ((propName == 'NextActionTime') || (propName == 'LastActionTime')) {
						var ts = alertData[propName].toString();
						var dotPos = ts.indexOf('.');
						ts = (dotPos > -1 ? ts.substring(0,dotPos-3) : ts.substring(0,ts.length-3));
						var tsClass = '';
						if ((propName == 'NextActionTime') && alertData._nextAction) {
							tsClass = ' class="NextAction-' + alertData._nextAction + '"';
							if ((alertData._nextAction == 'today') || (alertData._nextAction == 'tomorrow')) {
								ts = (alertData._nextAction == 'today' ? $$$Text('Today') : $$$Text('Tomorrow')) + ' ' + ts.substring(ts.indexOf(' ')+1);
							}
						}
						html.push('<td' + tsClass + '>' + ts + '</td>');
					}
					else {
						var tdClass = '';
						var propValue = alertData[propName];
						if (propName == 'EscalationLevel') {
							tdClass = 'escalationCell';
							propValue = parseInt(propValue,10);
							if (propValue == 1) {
								tdClass += ' escalationOne';
							}
							else if (propValue == 2) {
								tdClass += ' escalationTwo';
							}
							else if (propValue > 2) {
								tdClass += ' escalationThreePlus';
							}
						}
						else if (propName == 'CurrentOwner') {
							if (propValue == '') propValue = $$$Text('Unassigned');
						}
						html.push('<td' + (tdClass == '' ? '' : ' class="' + tdClass + '"') + '>' + propValue + '</td>');
					}
				}
				html.push('</tr>');
			}
		}
	}
	html.push('</table>');
	html.push('</div>');
	return html.join('');
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

/// Fetch the Managed Alert data that is exposed via JSON.
ClassMethod GetAlertData(ByRef pParameters, Output pObject As %Library.RegisteredObject) As %Status
{
	Kill pObject
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Set pObject.my = ##class(%Library.ArrayOfObjects).%New()
	Set pObject.unassigned = ##class(%Library.ArrayOfObjects).%New()
	Set tGetAll = $system.Security.Check("%Ens_AlertAdministration","USE")
	If tGetAll {	
		Set pObject.all = ##class(%Library.ArrayOfObjects).%New()
	}
	
	Set tProps = $listbuild("AlertText","AlertTime","BusinessPartner","CurrentOwner","EscalationLevel","IsOpen","LastActionTime","NextActionTime","Production","SessionId","SourceConfigName")
	Set tUsername = $username
	Set tArgs = 0

	Set tSQL = "SELECT ID, AlertText, %EXTERNAL(AlertTime) As AlertTime, BusinessPartner, CurrentOwner, EscalationLevel, IsOpen,"
		_"%EXTERNAL(LastActionTime) As LastActionTime, %EXTERNAL(NextActionTime) As NextActionTime, Production, SessionId, SourceConfigName "
		_"FROM Ens_Alerting.ManagedAlert WHERE IsOpen = 1"
	If ('tGetAll) {
		Set tSQL = tSQL _ " AND (CurrentOwner = ? OR CurrentOwner IS NULL)"
		Set tArgs = tArgs + 1
		Set tArgs(tArgs) = tUsername
	}
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tStatus = tStatement.%Prepare(tSQL)
	If $$$ISERR(tStatus) Quit tStatus
	Set tRS = tStatement.%Execute(tArgs...)

	Set tPropCount = $listlength(tProps)

	While tRS.%Next() {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		For i=1:1:tPropCount {
			Set tPropName = $listget(tProps,i)
			Set $property(tProxy,tPropName) = tRS.%Get(tPropName)
		}
		If (tRS.CurrentOwner = $username) {
			Do pObject.my.SetAt(tProxy,tRS.ID)
		}
		ElseIf (tRS.CurrentOwner = "") {
			Do pObject.unassigned.SetAt(tProxy,tRS.ID)
		}
		If tGetAll {
			// Need to clone data to ensure both objects are exported to JSON
			Do pObject.all.SetAt(tProxy.%ConstructClone(),tRS.ID)
		}
	}
	Set pObject.timeData = ##class(%ZEN.proxyObject).%New()
	Set tNow = $$$timeLocal
	Set pObject.timeData.now = tNow
	Set pObject.timeData.today = $piece(tNow," ")
	Set pObject.timeData.yesterday = $piece($system.SQL.DATEADD("dd",-1,tNow)," ")
	Set pObject.timeData.tomorrow = $piece($system.SQL.DATEADD("dd",1,tNow)," ")
	Set pObject.timeData.week = $piece($system.SQL.DATEADD("dd",7,tNow)," ") 
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Managed Alerts")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String [ CodeMode = call ]
{
..%OnGetPageName()
}

/// Ensure that we check edits to Managed Alerts.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
			"DoUpdateAlert": ..#EDITRESOURCE,
					: "")
}

}
