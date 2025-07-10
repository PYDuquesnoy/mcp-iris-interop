/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// This is the Message Bank Viewer page of the ZEN application.
Class Ens.Enterprise.Portal.MsgBankViewer Extends (EnsPortal.Template.filteredViewer, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

/// User needs USE permissions on the %Ens_MsgBank_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageHeader:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Message Bank Viewer";

/// Comma separated list of subscripts to use in the %session object for saved searches.
Parameter SessionSubscripts = "MsgBank,SavedSearch";

/// Indicate if can cancel search. This defines whether tempPortalNode is set.
Parameter CANCANCELSEARCH As BOOLEAN = 1;

/// Indicate if ought to create tempPortalNode when page created. Used by Cancel feature for example.
Parameter SETUPTEMPPORTALNODE As BOOLEAN = 1;

/// URL of dialog window to use for editing Search Criteria.
Property criteriaDialog As %String [ InitialExpression = "Ens.Enterprise.Portal.SearchCriteria.zen", ReadOnly ];

/// Name of the Assistant class to use.
Property assistantClass As %String [ InitialExpression = {..GetAssistantClass()}, ReadOnly ];

/// Name of Filter class to use for filtering searches.
Property filterClass As %String [ InitialExpression = "Ens.Enterprise.Portal.MsgFilter.Filter", ReadOnly ];

/// Name of SavedSearch class to use for saving searches.
Property savedSearchClass As %String [ InitialExpression = "Ens.Enterprise.Portal.MsgFilter.SavedSearch", ReadOnly ];

/// Header class to use for queries and display.
Property headerClass As %String [ InitialExpression = "Ens.Enterprise.MsgBank.MessageHeader", ReadOnly ];

/// URL of resend page.
Property resendPage As %String [ InitialExpression = "Ens.Enterprise.Portal.MessageResend.zen" ];

/// Flag to indicate whether a user may resend messages.
Property canResend As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageResend","USE")} ];

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
	width: 350px;
	height: 570px;
	background: white;
	overflow-x: scroll;
	overflow-y: scroll;
}

/* style for search panel */
.menuPanel {
	width: 300px;
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

/* styles for detail table */
.AutoFormCaption {
	font-weight: bold;
}

.AutoFormControl {
	font-weight: normal;
}
</style>
}

/// This pane displays event log activity table. User may click on a row and details are displayed to the side.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tablePane id="resultsTable" 
	OnCreateResultSet="CreateResultSet"
	useSnapshot="false"
	showZebra="true"
	maxRows="100"
	useKeys="true"
	showQuery="false"
	onselectrow="zenPage.selectItem(zenThis);"
	nowrap="true" 
	onmouseoverClass="tpMouseOver"
	multiSelect="true"
	valueColumn="ID"
	enableToggleSelect="true"
	onupdate="setTimeout('zenPage.onAfterSearch();',50);"
	onheaderClick="zenThis.currColumn = ''; return false;"
	unlockSession="true"
	showRowNumbers="true"
	>
	<!-- TimeCreated,ID,Client,Session,SessionId,Status,Error,Source -->
<column header="Time Created" colName="TimeCreated" OnDrawCell="DrawTimeCreated" id="idTimeCreated" width="135" title="Date and time the message was created" />
<column header="ID" colName="ID" width="90" hidden="false" title="Message ID" />
<column header="Client" colName="Client" title="Client System Name" />
<column header="Client Session" colName="Session" OnDrawCell="DrawSessionCell" title="Session in which the message was sent" />
<column header="Session" colName="SessionId" title="Message Bank Session ID" />
<column header="Status" colName="Status" width="90" title="Last message status" />
<column header="Error" colName="Error" title="Indicates whether an error occurred" />
<column header="Source" colName="Source" width="200" hidden="false" title="Configuration item that sent the message" />
<column header="Target" colName="Target" title="Configuration item that the message was sent to" />
<condition colName="SessionId" targetCol="Session" predicate="EQ" value="{ID}" cellStyle="background-color: lightgreen;" />
</tablePane>
</pane>
}

Method DrawTimeCreated(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tFormat = $select($IsObject(..searchCriteria): ..searchCriteria.TimeFormat, 1: 12)
	Write ..EscapeHTML($extract(%query(pName),*-tFormat+1,*)),"<timecreated style=""display: none;"" fullTime=""",..EscapeHTML(%query(pName)),"""/>"
	Quit $$$OK
}

XData jsonPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<jsonProvider id="searchFilter" OnGetTargetObject="LoadFilter"
	OnSubmitContent="SubmitFilter" targetClass="Ens.Enterprise.Portal.MsgFilter.Filter">
<parameter id="resetSearch" paramName="Reset" value="" />
<parameter id="namedSearch" paramName="SavedSearch" value="" />
</jsonProvider>
</pane>
}

XData svgTracePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<svgFrame id="svgTrace" svgPage="Ens.Enterprise.Portal.SVG.VisualTrace" width="200" height="300">
<parameter id="svgPAGE" paramName="PAGE" value="1" />
<parameter id="svgSESSIONID" paramName="SESSIONID" value=""/>
<parameter id="svgMSGPERPAGE" paramName="MSGPERPAGE" value="10" />
<parameter id="svgINCLUDEEVENTS" paramName="INCLUDEEVENTS" value="0" />
<parameter id="svgINCLUDEIOLOG" paramName="INCLUDEIOLOG" value="0" />
<parameter id="svgINCLUDEACKS" paramName="INCLUDEACKS" value="0" />
<parameter id="svgNOSELECT" paramName="NOSELECT" value="1" />
<parameter id="svgMODE" paramName="MODE" value="1" />
</svgFrame>
</pane>
}

/// User clicked a link for Trace. Display the Visual Trace page in a popup,
/// so user can click the arrows to go from session to session without losing his/her place in the Message Bank Viewer.
ClientMethod showTrace(session, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (evt.stopPropagation) evt.stopPropagation();
	}
	if (session != '') {
		window.open(zenLink('Ens.Enterprise.Portal.VisualTrace.zen?SESSIONID=' + encodeURIComponent(session)));
	}
}

/// User clicked the Purge button
ClientMethod startPurge() [ Language = javascript ]
{
	var conf = $$$Text("Are you sure you want to purge the Message Bank now?");
	var nan = $$$Text("Value entered for number of days is not a number.");
	var npos = $$$Text("Value entered for number of days is not a positive number.");
	var count = $$$Text("Number of records purged:");
	var fail = $$$Text("Message Bank purge did not succeed:");

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

/// Use with certain <text> fields so user can hit Enter to indicate that an entry in the field is done and ready to use
ClientMethod enterKey() [ Language = javascript ]
{
     if (zenEvent.keyCode == zenENTER) zenPage.doSearch();
}

/// Helper method to record the first and last ID values for the current page.
ClientMethod updatePageData() [ Language = javascript ]
{
	if (!this._idIndex) {
		this._idIndex = new Object();
	}
	var currPageData = { lastId: '', lastTime: '', firstId: '', firstTime: '' };
	this._idIndex[this.currentPage] = currPageData;
	
	var table = this.getResultsTable();
	var tableDiv = table.getEnclosingDiv();
	var rows = tableDiv.getElementsByTagName('tr');
	
	var lastRow = rows[rows.length - 2];
	currPageData.lastId = lastRow.getAttribute('zenvalue');
	var firstRow = rows[1];
	currPageData.firstId = firstRow.getAttribute('zenvalue');
	
	var times = tableDiv.getElementsByTagName('timecreated');

	if (times.length > 0) {
		var lastTime = times[times.length - 1];
		currPageData.lastTime = lastTime.getAttribute('fullTime');
		
		var firstTime = times[0];
		currPageData.firstTime = firstTime.getAttribute('fullTime');
	}
}

/// Callback to set up the resultset/query for paging
ClientMethod onChangeResultsPage(next, pageSize, currentPage) [ Language = javascript ]
{
	if (!this.searchCriteria) {
		var searchForm = this.getSearchForm();
		this.searchCriteria = searchForm.getValuesAsObject();
	}
	
	if (next) {
		var currPageData = this._idIndex[currentPage];
		if (this.searchCriteria.SortOrder == '2') {
			this.searchCriteria.nextPageEndId = ''; 
			this.searchCriteria.nextPageStartId = '';
			this.searchCriteria.nextPageEndTime = currPageData.lastTime+'^'+currPageData.lastId;
			this.searchCriteria.nextPageStartTime = '';
		}
		else {
			this.searchCriteria.nextPageStartId = '';
			this.searchCriteria.nextPageEndId = '';
			this.searchCriteria.nextPageStartTime = currPageData.lastTime+'^'+currPageData.lastId;
			this.searchCriteria.nextPageEndTime = '';
		}
	}
	else {
		var prevPageData = this._idIndex[currentPage - 1];
		if (this.searchCriteria.SortOrder == '2') {
			this.searchCriteria.nextPageStartId = '';
			this.searchCriteria.nextPageEndId = '' ;
			this.searchCriteria.nextPageStartTime = '';
			this.searchCriteria.nextPageEndTime = prevPageData.firstTime;
			if (currentPage>2) {
				var prevPageData2 = this._idIndex[currentPage - 2];
				this.searchCriteria.nextPageEndTime +='^'+prevPageData2.lastId;
			}
		}
		else {
			this.searchCriteria.nextPageStartId = '';
			this.searchCriteria.nextPageEndId = '';
			this.searchCriteria.nextPageStartTime = prevPageData.firstTime+'^';
			if (currentPage>2) {
				var prevPageData2 = this._idIndex[currentPage - 2];
				this.searchCriteria.nextPageStartTime += prevPageData2.lastId;
			}
			this.searchCriteria.nextPageEndTime = '' ;
		}
	}
}

/// Ensure we don't call onlayoutHandler() reentrantly under older versions of IE8
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (!zenIsHTML5) {
			if (this._layoutInProgress) return;
			this._layoutInProgress = true;
		}	
		this.invokeSuper('onlayoutHandler',arguments);
		if (!zenIsHTML5) this._layoutInProgress = false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
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

/// Fill search criteria defaults
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tPageNum = ..%GetComponentById("pageNumber")
	If $IsObject(tPageNum) {
		Set tPageNum.value = ..currentPage
	}
	Set tSourceSelector = ..%GetComponentById("Source")
	If $IsObject(tSourceSelector) Set tSourceSelector.context = "Ens.ContextSearch/EnterpriseMessageSource"
	Set tTargetSelector = ..%GetComponentById("Target")
	If $IsObject(tTargetSelector) Set tTargetSelector.context = "Ens.ContextSearch/EnterpriseMessageTarget"
	
	Set tClientExpando = ##class(%ZEN.Component.expando).%New()
	Set tClientExpando.id = "clientExpando"
	Set tClientExpando.animate = 1
	Set tClientExpando.expanded = 1
	Set tClientExpando.caption = $$$Text("Message Bank Client")
	
	Set tClientField = ##class(%ZEN.Portal.selector).%New()
	Set tClientField.id = "clientList"
	Set tClientField.name = "clientList"
	Set tClientField.multiSelect = 0
	Set tClientField.size=33
	Set tClientField.context = "Ens.ContextSearch/MessageBankNodes"
	Set tClientField.onchange = "zenPage.updateSearchState();"
	Set tSC = tClientExpando.%AddChild(tClientField)
	If $$$ISERR(tSC) Quit tSC
	
	Set tSearchForm = ..%GetComponentById("searchForm")
	Set tExtendedCriteria = ..%GetComponentById("extendedCriteria")
	Set tSC=tSearchForm.%AddChildBefore(tClientExpando,tExtendedCriteria)
	
	Quit tSC
}

/// Reset the current count of Message Bank entries
ClientMethod countReset() [ Language = javascript ]
{
	zen("logTotal").setValue(zenPage.GetCount());
}

ClassMethod GetCount() As %Integer [ ZenMethod ]
{
	/*
	Quit ##class(Ens.Purge).EventLogCount()
	*/
	Quit 0
}

/// Perform the purge operation and if there is an error, return the message
/// to JavaScript by prepending the message with a '-'. If no error then 
/// return the zero or positive number of entries deleted, as a string.
ClassMethod DoPurge(keep As %Integer) As %String [ ZenMethod ]
{
	/*
	Set LogsDeleted = 0
	Set status = ##class(Ens.Purge).PurgeEventLogsByDate(keep,.LogsDeleted)
	If ($$$ISERR(status)) { 
		Quit "-" _ $ZCVT($System.Status.GetErrorText(status),"O","JS") 
		}
	Else { 
		Quit LogsDeleted 
	}
	*/
	Quit 0
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Message Bank Viewer","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Set n = 0
	// commands: $LB(id,caption,help,onclick)
	Set pCommands($I(n)) = $LB("searchButton",$$$Text("Search"),$$$Text("Search the Message Bank using the current criteria"),"zenPage.doSearch(); return false;")
	Set:..#CANCANCELSEARCH pCommands($I(n)) = $LB("cancelButton",$$$Text("Cancel"),$$$Text("Cancel current search"),"zenPage.cancelSearch(); return false;")
	Set pCommands($I(n)) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the Message Bank search criteria to their default values"),"zenPage.loadSearch('',true); return false;")
	Set pCommands($I(n)) = $LB("btnResend",$$$Text("Resend"),$$$Text("Resend all selected messages"),"zenPage.doResend(); return false;")
	Set pCommands($I(n)) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false); return false;")
	Set pCommands($I(n)) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true); return false;")
	Set pCommands($I(n)) = $LB("eventButton",$$$Text("Event Log"),$$$Text("Search the Message Bank Event Log"),"zenPage.gotoPage('Ens.Enterprise.Portal.MsgBankEventLog.zen');")
	If $get(^Ens.Debug("UtilEnsMessages","sql")) {
		Set pCommands($I(n)) = $LB("showQueryButton",$$$Text("Show Query"),$$$Text("Show the current query text"),"zenPage.showQuery(); return false;")
	}
	Set pCommands($I(n)) = $LB("purgeButton",$$$Text("Purge"),$$$Text("Purge messages from the Message Bank"),"zenPage.gotoPage('Ens.Enterprise.Portal.MsgBankPurgeAll.zen');")
	Quit $$$OK
}

ClassMethod GetAssistantClass() As %String [ CodeMode = expression ]
{
$get(^EnsPortal.Settings("MsgBankViewer","AssistantClass"),"Ens.Enterprise.Portal.MsgFilter.Assistant")
}

}
