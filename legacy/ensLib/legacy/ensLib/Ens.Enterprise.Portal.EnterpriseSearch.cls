/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.EnterpriseSearch Extends (EnsPortal.Template.filteredViewer, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

Parameter PAGENAME = "Enterprise Message Viewer";

/// User needs USE permissions on the %Ens_MsgBank_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageHeader:USE";

/// Comma separated list of subscripts to use in the %session object for saved searches.
Parameter SessionSubscripts = "Enterprise,SavedSearch";

/// Indicate if can cancel search. This defines whether tempPortalNode is set.
Parameter CANCANCELSEARCH As BOOLEAN = 1;

/// Indicate if ought to create tempPortalNode when page created. Used by Cancel feature for example.
Parameter SETUPTEMPPORTALNODE As BOOLEAN = 1;

/// Name of the Assistant class to use.
Property assistantClass As %String [ InitialExpression = {..GetAssistantClass()}, ReadOnly ];

/// Name of Filter class to use for filtering searches.
Property filterClass As %String [ InitialExpression = "Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter", ReadOnly ];

/// Name of SavedSearch class to use for saving searches.
Property savedSearchClass As %String [ InitialExpression = "Ens.Enterprise.Portal.MsgFilter.SavedEnterpriseSearch", ReadOnly ];

Property %Clients As array Of Ens.Enterprise.MonitorClient;

XData Style
{
<style type="text/css">
.systemLink {
	cursor: pointer;
	/*color: #3B84BC;*/
	text-decoration: underline;
	font-weight: bold;
}
tr.tpSelected a.sessionLink {
	color: white;
	text-decoration: underline;
}
#warningWrapper {
	padding: 2px 0px 0px 2px;
	background-color: #FF9900;
	font-size: 0.9em;
}
span.warningMain {
	font-weight: bold;
	padding: 2px;
}
div.warningDiv {
	margin-left: 10px;
	padding: 2px;
	padding-left: 5px;
	border-top: 1px solid gray;
	border-left: 1px solid gray;
}
div.warningDiv.firstWarning {
	margin-top: 2px;
	border-top-left-radius: 3px;
}
span.warningClientTitle {
	font-weight: bold;
}
span.basicInfoWarning {
	font-weight: bold;
	font-size: 0.9em;
}
</style>
}

XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tabGroup id="detailsTabGroup" showTabBar="true" remember="true" onshowTab="zenPage.onTabChange();" >
<tab id="enterpriseDetails" caption="Header" title="Message Properties">
<html id="detailsContent" />
</tab>
</tabGroup>
</pane>
}

XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<html id="warningsDiv" OnDrawContent="DrawWarnings" onupdate="zenPage.onWarningsUpdate();" />
<tablePane id="resultsTable"
    cellSpacing="2"
	OnCreateResultSet="CreateResultSet"
	useSnapshot="false"
	showZebra="true"
	multiSelect="false"
	valueColumn="ID"
	maxRows="100"
	useKeys="true"
	showQuery="false"
	onselectrow="zenPage.selectItem(zenThis);"
	nowrap="true"
	onmouseoverClass="tpMouseOver"
	enableToggleSelect="true"
	onupdate="setTimeout('zenPage.onAfterSearch();',50);"
	onheaderClick="zenThis.currColumn = ''; return false;"
	unlockSession="true"
	showRowNumbers="true"
>
<column	header="System" colName="System" OnDrawCell="DrawSystemCell" />
<column header="ID" colName="ID" title="Message ID" />
<column header="Time Created" colName="TimeCreated" OnDrawCell="DrawTimeCreated" id="idTimeCreated" title="Date and time the message was created" />
<column header="Session" colName="Session" title="Session in which the message was sent" link=" " OnDrawCell="DrawSessionCell" />
<condition colName="Session" predicate="EQ" value="{ID}" cellStyle="background-color: lightgreen;" />
<column header="Status" colName="Status" title="Last message status" />
<column header="Error" colName="Error" title="Indicates whether an error occurred" />
<column header="Source" colName="Source" title="Configuration item that sent the message" />
<column header="Target" colName="Target" title="Configuration item that the message was sent to" />
</tablePane>
</pane>
}

XData jsonPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<jsonProvider id="searchFilter" OnGetTargetObject="LoadFilter"
	OnSubmitContent="SubmitFilter" targetClass="Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter">
<parameter id="resetSearch" paramName="Reset" value="" />
<parameter id="namedSearch" paramName="SavedSearch" value="" />
<parameter id="afterSearchParm" paramName="AfterSearch" value="" />
</jsonProvider>	
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Enterprise Message Viewer")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Enterprise Message Viewer")
}

/// Show/hide the toggle buttons
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tBasicExpando = ..%GetComponentById("simpleCriteria")
	If $IsObject(tBasicExpando) {
		Set tMaxRows = ##class(%ZEN.Component.text).%New()
		Set tMaxRows.id = "maxRows"
		Set tMaxRows.name = "MaxRows"
		Set tMaxRows.clientType = "integer"
		Set tMaxRows.label = $$$Text("Max Rows")
		Set tMaxRows.title = $$$Text("Maximum number of rows to retrieve from each system")
		Set tMaxRows.onchange = "zenPage.updateSearchState();"
		Set tSC = tBasicExpando.%AddChild(tMaxRows)
		If $$$ISERR(tSC) Quit tSC

		Set tQueryTimeout = ##class(%ZEN.Component.text).%New()
		Set tQueryTimeout.id = "queryTimeout"
		Set tQueryTimeout.name = "Timeout"
		Set tQueryTimeout.clientType = "float"
		Set tQueryTimeout.label = $$$Text("Query Timeout")
		Set tQueryTimeout.title = $$$Text("Number of seconds to wait for results on the target systems")
		Set tQueryTimeout.onchange = "zenPage.updateSearchState();"
		Set tSC = tBasicExpando.%AddChild(tQueryTimeout)
		If $$$ISERR(tSC) Quit tSC
		
		Set tTempNode = ##class(%ZEN.Component.hidden).%New()
		Set tTempNode.id = "tempNode"
		Set tTempNode.name = "TempNode"
		Set tSC = tBasicExpando.%AddChild(tTempNode)
		If $$$ISERR(tSC) Quit tSC
	}
	#; Don't offer local options for Source and Target
	Set ..%GetComponentById("Source").context = ""
	Set ..%GetComponentById("Target").context = ""

	Set tClientExpando = ##class(%ZEN.Component.expando).%New()
	Set tClientExpando.id = "clientExpando"
	Set tClientExpando.animate = 1
	Set tClientExpando.expanded = 1
	Set tClientExpando.caption = $$$Text("Enterprise Clients")
	
	Set tClientField = ##class(%ZEN.Portal.selector).%New()
	Set tClientField.id = "clientList"
	Set tClientField.name = "clientList"
	Set tClientField.multiSelect = 1
	Set tClientField.context = "Ens.ContextSearch/EnterpriseClients"
	Set tClientField.onchange = "zenPage.updateSearchState();"
	
	Set tSC = tClientExpando.%AddChild(tClientField)
	If $$$ISERR(tSC) Quit tSC
	
	Set tSearchForm = ..%GetComponentById("searchForm")
	Set tExtendedCriteria = ..%GetComponentById("extendedCriteria")
	Quit tSearchForm.%AddChildBefore(tClientExpando,tExtendedCriteria)
}

/// Callback to set up the resultset/query for paging
ClientMethod onChangeResultsPage(next, pageSize, currentPage) [ Language = javascript ]
{
	if (!this.searchCriteria) {
		var searchForm = this.getSearchForm();
		this.searchCriteria = searchForm.getValuesAsObject();
	}
	
	this.searchCriteria['%pageChange'] = true;
	if (next) {
		var currPageData = this._idIndex[currentPage];
		this.searchCriteria.currPageLastSystem = currPageData.lastSystem;
		if (this.searchCriteria.SortOrder == '2') {
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
		this.searchCriteria.currPageLastSystem = prevPageData.firstSystem;
		if (this.searchCriteria.SortOrder == '2') {
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

/// Helper method to record the first and last ID values for the current page.
ClientMethod updatePageData() [ Language = javascript ]
{
	if (!this._idIndex) this._idIndex = {};

	var currPageData = { "lastId": "", "lastTime": "", "lastSystem": "", "firstId": "", "firstTime": "", "firstSystem": "" };
	this._idIndex[this.currentPage] = currPageData;
	
	var table = this.getResultsTable();
	var lastRowIndex = (table.rowCount != '' ? parseInt(table.rowCount,10) - 1 : -1);

	currPageData.lastTime = this.getFullTimeCreated(lastRowIndex);
	currPageData.firstTime = this.getFullTimeCreated(0);

	var firstRowData = table.getRenderedRowData(0);
	if (firstRowData) {
		currPageData.firstId = firstRowData.ID;
		var firstSystem = (firstRowData.System != null ? firstRowData.System.toString().replace(/^\s*|\s*$/g,'') : '');
		if (firstSystem != '') currPageData.firstSystem = firstSystem;
	}
	if (lastRowIndex >= 0) {
		var lastRowData = table.getRenderedRowData(lastRowIndex);
		if (lastRowData) {
			currPageData.lastId = lastRowData.ID;
			var lastSystem = (lastRowData.System != null ? lastRowData.System.toString().replace(/^\s*|\s*$/g,'') : '');
			if (lastSystem != '') currPageData.lastSystem = lastSystem;
		}
	}
}

/// Helper method to extract the full value for TimeCreated from the <var>timecreated</var> element in the HTML row data.
/// <var>rowIndex</var> is the index of the row according to the main table's <var>selectedIndex</var> property.
ClientMethod getFullTimeCreated(rowIndex) [ Language = javascript ]
{
	var timeCreated = '';
	if (rowIndex >= 0) {
		var tableDiv = this.getResultsTable().getEnclosingDiv();
		var rows = tableDiv.getElementsByTagName('tr');
		var row = rows[rowIndex + 1];
		if (row) {
			var rowTimes = row.getElementsByTagName('timecreated');
			if (rowTimes && (rowTimes.length > 0)) {
				var timeElement = rowTimes[0];
				if (timeElement) timeCreated = timeElement.getAttribute('fullTime');
			}
		}
	}
	return timeCreated;
}

/// Update the current Filter based on the form's contents. Extended criteria are saved separately.
ClientMethod updateFilterFromForm(updateSearchCriteria) [ Language = javascript ]
{
	var changed = this.invokeSuper('updateFilterFromForm',arguments);
	var filter = this.getFilter();
	if (filter && zenPage.searchCriteria) {
		if (filter.ClientIDs.join(',') != zenPage.searchCriteria.clientList) {
			filter.ClientIDs = zenPage.searchCriteria.clientList.toString().split(',');
			changed = true;
		}
	}
	
	return changed;
}

/// Update the form on the page based on an updated Filter object.
ClientMethod updateFormFromFilter() [ Language = javascript ]
{
	this.invokeSuper('updateFormFromFilter',arguments);
	var filter = this.getFilter();
	var clientList = zen('clientList');
	var newValue = '';
	if (filter && filter.ClientIDs) newValue = filter.ClientIDs.join(',');
	clientList.setValue(newValue);
}

ClientMethod drawDetails(messageId) [ Language = javascript ]
{
	var detailsDiv = zen('detailsContent').getEnclosingDiv();
	var newContent = [];
	var table = this.getResultsTable();
	var selectedRow = table.selectedIndex;
	if (selectedRow < 0) {
		newContent.push('<div class="detailContents">' + $$$Text('Details for selected item') + '</div>');
	}
	else {
		if (!this._propNameIndex) {
			this._propNameIndex = { 
									"ID": $$$Text('ID'),
									"System": $$$Text('System'),
									"TimeCreated": $$$Text('TimeCreated'),
									"Session": $$$Text('SessionId'),
									"Status": $$$Text('Status'),
									"Error": $$$Text('ErrorStatus'),
									"Source": $$$Text('SourceConfigName'),
									"Target": $$$Text('TargetConfigName')
			}
		}
		var rowData = table.getRenderedRowData(selectedRow);
		if (rowData) {
			newContent.push('<div class="detailContents">');
			newContent.push('<span class="basicInfoWarning">' + $$$Text('Only basic information included') + '</span>');
			
			newContent.push('<table class="AutoFormTable" cellspacing="0" cellpadding="0" border="0">');
			newContent.push('<tbody>');
			for (var prop in rowData) {
				var value = '';
				if (prop == 'TimeCreated') {
					value = this.getFullTimeCreated(selectedRow);
				}
				if (value == '') {
					value = (rowData[prop] ? rowData[prop].toString().replace(/^\s*|\s*$/g,'') : '');
				}
				var displayName = (this._propNameIndex[prop] ? this._propNameIndex[prop] : prop);
				newContent.push('<tr class="AutoFormTableRow">');
				newContent.push('<td class="AutoFormTableExpandor">&nbsp;</td>');
				newContent.push('<td class="AutoFormTableCaption">' + displayName + '</td>');
				newContent.push('<td class="AutoFormTableValue">' + value + '</td>');
				newContent.push('</tr>');
			}
			newContent.push('</tbody>');
			newContent.push('</table>');
			newContent.push('</div>');
		}
	}
	detailsDiv.innerHTML = newContent.join('');
}

/// Don't allow resend.
ClientMethod doResend() [ Language = javascript ]
{
}

/// Check for errors that occurred while the table was first being populated.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen('warningsDiv').onRefreshContents = zenPage.onWarningsUpdate;
	this.checkForSearchErrors();
}

/// Adjust for the possibility of the warning div being populated.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	// Ensure we don't call onlayoutHandler() reentrantly
	if (this._layoutInProgress) return;
	this._layoutInProgress = true;
	this.invokeSuper('onlayoutHandler',arguments);
	this._layoutInProgress = false;
	
	var totalResultHeight = this.getContentAreaHeight();
	var tableDiv = zenPage.getResultsTable().getEnclosingDiv();
	var warningsDiv = zen('warningsDiv').getEnclosingDiv();
	tableDiv.style.height = (totalResultHeight - warningsDiv.offsetHeight) + 'px';
}

/// Make sure we check for errors that occurred during the search.
ClientMethod onAfterSearch() [ Language = javascript ]
{
	var afterSearchParm = zen('afterSearchParm');
	afterSearchParm.value = 1;
	this.invokeSuper('onAfterSearch',arguments);
	afterSearchParm.value = '';
	this.checkForSearchErrors();
}

/// Method that gets the current TempNode from the filter and triggers a refresh of the Warnings panel.
ClientMethod checkForSearchErrors() [ Language = javascript ]
{
	var filter = this.getFilter();
	if (filter) {
		var tempNode = filter.TempNode;
		if (tempNode == null) tempNode = '';
		var warningDiv = zen('warningsDiv');
		warningDiv.seed = tempNode;
		warningDiv.refreshContents();
	}
}

ClientMethod onWarningsUpdate() [ Language = javascript ]
{
	zenPage.onlayoutHandler();
	var warningsDiv = zen('warningsDiv');
	var realDiv = warningsDiv.getEnclosingDiv();
	if (realDiv && (realDiv.innerHTML != '')) realDiv.focus();
}

ClientMethod showTrace(session, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (evt.stopPropagation) evt.stopPropagation();
	}
	if (session && (session.length == 2)) {
		var traceLink = session[0];
		if (traceLink == '') {
			alert($$$Text('Unable to determine location for Trace Diagram'));
			return;
		}
		var sessionID = session[1];
		window.open(traceLink + '?SESSIONID=' + encodeURIComponent(sessionID));
	}
}

ClientMethod showOtherSystemHome(link, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (evt.stopPropagation) evt.stopPropagation();
	}
	if (link != '') {
		window.open(link);
	}
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Set n = 0
	// commands: $LB(id,caption,help,onclick)
	Set pCommands($I(n)) = $LB("searchButton",$$$Text("Search"),$$$Text("Search the client systems using the current criteria"),"zenPage.doSearch(); return false;")
	Set:..#CANCANCELSEARCH pCommands($I(n)) = $LB("cancelButton",$$$Text("Cancel"),$$$Text("Cancel current search"),"zenPage.cancelSearch(); return false;")
	Set pCommands($I(n)) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the search criteria to their default values"),"zenPage.loadSearch('',true); return false;")
	Set pCommands($I(n)) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false); return false;")
	Set pCommands($I(n)) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true); return false;")
	/* Don't display the Show Query button in this case, as the execution is left up to the client systems.
	If $get(^Ens.Debug("UtilEnsMessages","sql")) {
		Set pCommands($I(n)) = $LB("showQueryButton",$$$Text("Show Query"),$$$Text("Show the current query text"),"zenPage.showQuery(); return false;")
	}
	*/
	Quit $$$OK
}

/// Server-side method to write out the content for the SessionId cells.
/// The main purpose is to include a link to the trace on the
/// client system when the session ID is known.
Method DrawSessionCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Set tDisplaySession = ..EscapeHTML($get(%query("Session")))
	Set tSessionId = $ZCVT($ZCVT($get(%query(..#SessionTraceColumn)),"O","JS"),"O","HTML")

	If tDisplaySession = "" {
		&html<&nbsp;>
	}
	Else {
		Set tSystemId = $get(%query("System"))
		Set tTraceLink = ""
		If (tSystemId '= "") {
			Set tClient = ""
			If ..%Clients.IsDefined(tSystemId) {
				Set tClient = ..%Clients.GetAt(tSystemId)
			}
			ElseIf ##class(Ens.Enterprise.MonitorClient).%ExistsId(tSystemId) {
				Set tClient = ##class(Ens.Enterprise.MonitorClient).%OpenId(tSystemId)
				If $IsObject(tClient) Do ..%Clients.SetAt(tClient,tSystemId)
			}
			If $IsObject(tClient) {
				Set tTraceLink = $ZCVT($ZCVT(tClient.GetURLPath() _"EnsPortal.VisualTrace.zen","O","JS"),"O","HTML")
			}
		}
		&html<<a class="sessionLink" title="#(..EscapeHTML(..sessionLinkTitle))#" onclick="zenPage.showTrace(['#(tTraceLink)#','#(tSessionId)#'],event); return false;">#(tDisplaySession)#</a>>
	}
	Quit $$$OK
}

/// Draw the name of the client system, and include a link to the Message Viewer page on the current client.
Method DrawSystemCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Set tSystemID = $get(%query("System"))
	Set tClient = ""
	If tSystemID '= "" {
		If ..%Clients.IsDefined(tSystemID) {
			Set tClient = ..%Clients.GetAt(tSystemID)
		}
		ElseIf ##class(Ens.Enterprise.MonitorClient).%ExistsId(tSystemID) {
			Set tClient = ##class(Ens.Enterprise.MonitorClient).%OpenId(tSystemID)
			If $IsObject(tClient) Do ..%Clients.SetAt(tClient,tSystemID)
		}
	}
	If '$IsObject(tClient) {
		&html<&nbsp;>
	}
	Else {
		Set tViewerLink = $ZCVT($ZCVT(tClient.GetURLPath() _ "EnsPortal.MessageViewer.zen","O","JS"),"O","HTML")
		Set tGoToSystem = $$$TextHTML("Go to source system's Message Viewer")
		&html<<a class="systemLink" title="#(tGoToSystem)#" onclick="zenPage.showOtherSystemHome('#(tViewerLink)#',event);">#(..EscapeHTML(tSystemID))#</a>>
	}
	Quit $$$OK
}

/// Draw the TimeCreated HTML using an embedded <timecreated> tag to ensure that the full timestamp
/// is always available to the client code for paging purposes.
Method DrawTimeCreated(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tTime = %query(pName)
	Set tFormat = $select($IsObject(..searchCriteria): ..searchCriteria.TimeFormat, 1: 12)
	Write ..EscapeHTML($extract(tTime,*-tFormat+1,*)),"<timecreated style=""display: none;"" fullTime=""",..EscapeHTML(tTime),"""/>"
	Quit $$$OK
}

/// Method to draw the contents of warningsDiv in the output for a supplied temp node.
/// If the temp node doesn't exist, or there are no errors, nothing is drawn.
Method DrawWarnings(pTempNode As %String) As %Status
{
	If $get(pTempNode) = "" Quit $$$OK
	New %ref
	Set tStatus = $$$OK
	Try {
		Set %ref = ##class(Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter).GetReference(pTempNode,..VirtualKey)
		Set tErrors = 0
		// Try to wait for all return values to be present before we return errors
		Set tClientCount = $get(@%ref@("clientCount"))
		Set tEnd = $zh + 1
		While (tClientCount > $get(@%ref@("resultCount"))) && ($zh < tEnd) {
			Hang 0.1
		}
		If (tClientCount > $get(@%ref@("resultCount"))) {
			Set tClient = ""
			For {
				Set tClient = $order(@%ref@("clients",tClient))
				Quit:(tClient = "")
				If '$data(@%ref@("result",tClient)) {
					// Mark client as timed out so we don't try to fetch a non-existent status
					Set tTimedOut(tClient) = 1
					Set tErrors = tErrors + 1
					Set tErrors(tErrors) = $lb(tClient,$system.Status.GetErrorText($$$ERROR($$$EnsErrGeneral,"Client '"_tClient_"' timed out")))
				}
			}
		}
		
		Set tClient = ""
		For {
			Set tClient = $order(@%ref@("result",tClient),1,tClientStatus)
			Quit:(tClient = "")
			// If a client has been marked as incomplete, assume status was set above
			If $get(tTimedOut(tClient)) Continue
			If (tClientStatus '= "") && $$$ISERR(tClientStatus) {
				Set tErrors = tErrors + 1
				Set tErrors(tErrors) = $lb(tClient,$system.Status.GetErrorText(tClientStatus))
			}
		}
		If tErrors {
			&html<<div id="warningWrapper">>
			&html<<span class="warningMain">#($$$TextHTML("Errors were encountered during the search"))#:</span>>
			For i=1:1:tErrors {
				Set tClass = "warningDiv" _ $select(i=1: " firstWarning", 1: "")
				&html<<div class="#(tClass)#">>
				&html<<span class="warningClientTitle">#($zconvert($listget(tErrors(i),1),"O","HTML"))#:</span>>
				&html<<span class="warningClientMessage">#($zconvert($listget(tErrors(i),2),"O","HTML"))#</span>>
				&html<</div>>
			}
			&html<</div>>
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Create and execute the result set used to drive the results table.
/// Note that <property>ignoreSearchWarnings</property> controls whether
/// the warnings in <property>searchWarnings</property> should be displayed
/// to the user or ignored.
Method CreateResultSet(Output pSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	// If reloading previous search from session, do not execute search until user clicks the button
	Quit:(..inFirstLoad && '..isDefaultFilter) $$$NULLOREF
	Do:..#CANCANCELSEARCH ..PrepareCancel()
	Set pSC = $$$OK
	Set tRS = ""

	Try {
		Do ..searchWarnings.Clear()
		
		Set pSC = $classmethod(..assistantClass,"CreateFilter",..searchCriteria, .tFilter,,..VirtualKey)
		If $$$ISERR(pSC) Quit
		
		Set tIgnoreSearchWarnings = ..ignoreSearchWarnings
		Set ..ignoreSearchWarnings = 0
		Set pSC = $classmethod(..assistantClass,"CheckFilter",tFilter,.tWarnings)
		If $$$ISERR(pSC) Quit
		If 'tIgnoreSearchWarnings && $IsObject(tWarnings) && tWarnings.Count() {
			Set ..searchWarnings = tWarnings
			
			// Send back empty result set to UI
			Set tRS = ##class(%SQL.StatementResult).%New()
			Set pInfo.queryExecuted = 1
			Set ..searchQuery = ""
			Quit
		}

		Set pSC = $classmethod(..assistantClass,"GetResultSet",tFilter, .tRS)
		// Ensure the query text is updated, even if an error occurs
		Set ..searchQuery = tFilter.GeneratedSQL
		If $$$ISERR(pSC) Quit
		If tFilter.TempNode Set ..searchCriteria.TempNode = tFilter.TempNode
		
		Set pInfo.queryExecuted = 1
		Set pInfo.queryText = tFilter.GeneratedSQL
	}
	Catch(ex) {
		Set pSC = $$$SystemError
		Set tRS = ""
	}
	Quit tRS
}

/// Load Filter object from the session, or from a saved search if requested.
Method LoadFilter(ByRef pParms, Output pObject As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter) As %Status
{
	Set tTempNode = ""
	If $get(pParms("AfterSearch")) && ($get(pParms("SavedSearch")) '= "") && '$get(pParms("Reset")) {
		Set tTempNode = ##class(Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter).GetVirtualSessionTempNode(..VirtualKey)
		If tTempNode {
			// If we are in onAfterSearch() and we have saved search with a temp node, we simply need to reload
			// the object from the session so we don't overwrite any of the data in the temp node
			Quit ##class(Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter).LoadFromVirtualSession(..VirtualKey,.pObject)
		}
	}
	Quit ##super(.pParms,.pObject)
}

ClassMethod GetAssistantClass() As %String [ CodeMode = expression ]
{
$get(^EnsPortal.Settings("EnterpriseMessageViewer","AssistantClass"),"Ens.Enterprise.Portal.MsgFilter.EnterpriseAssistant")
}

}
