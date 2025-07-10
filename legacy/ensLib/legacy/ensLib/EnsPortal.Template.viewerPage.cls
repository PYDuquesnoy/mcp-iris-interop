/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for viewer-style pages.
/// <p>
/// These are pages that let the user view a list (such as messages
/// or contents of queues) and select search criteria.
/// Subclasses must override and provide items as follows.
/// See the EnsPortal.EventLog class for an example; there are also others.
/// <p>
/// Subclasses must provide a searchPane, resultsPane, and detailsPane.
/// The resultsPane should contain a <tablePane> and the detailsPane should contain an <html> with a callback.
/// Subclass must not provide a contentPane.
/// <p>
/// Note the parameters that identify the id values for the results table, page size counter,
/// and page number counter field. These string values must match the corresponding actual id values
/// for these components in the searchPane and resultsPane. You can set new values for the ids in your subclass if you like.
/// Be sure to set a detailsWidth value, which will interplay with the width of the HTML contents of the detailsPane.
/// It is a good idea to put static widths on the HTML contents of the detailsPane and have them scroll in x and y.
/// See the EnsPortal.EventLog class for an example; there are also others. 
/// <p>
/// The detailsWidth and the width of the HTML contents of the detailsPane will interact with
/// what width you give to the menuPane style which affects the searchPane width.
/// <p>
/// In the resultsPane, there must be a <tablePane>. 
/// The <tablePane> must provide onselectrow="zenPage.selectItem(zenThis)" and onmouseoverClass="tpMouseOver".
/// The <tablePane> should also provide a tableName, even if that doesn't happen until %OnAfterCreatePage, as in EnsPortal.BPInstances.
/// <p>
/// The subclass must provide an onSelectItem() method. onSelectItem() gets called automatically by
/// the superclass method selectItem().
/// <p>
/// Subclasses should use getResultsTable() to get the handle of the results table object with no row selection made.
/// <p>
/// The main <form> inside the searchPane must have the id value "searchForm".
/// <p>
/// The search method that gets invoked upon user actions must be called doSearch(). The doSearch() method itself
/// is provided in the superclass.
/// <p>
/// Subclass should implement an onAfterPageChange() method that does any actions that the page should do
/// each time the display changes (that is, after each search).
/// For example, a subclass might want to force certain expandos to remain open
/// to permit easy access to the fields found there. There is no need to worry about updating the page number, however.
/// That happens automatically.
/// <p>
/// Subclass should implement an onSearchHandler() method that doSearch() will invoke automatically.
/// Its purpose is to get all the criteria for the search from the form fields.
/// See the EnsPortal.EventLog class for an example; there are also others.
/// <p>
/// Subclass should implement a GetColumnsAndFrom(timeFormat) method to insert the table name
/// and correctly formatted time string, as well as all desired columns. See examples.
/// <p>
/// The page size field should have value="#(%page.pageSize)#". The page number field should have value="#(%page.currentPage)#". 
Class EnsPortal.Template.viewerPage Extends EnsPortal.Template.standardPage [ Abstract, System = 4 ]
{

/// Name of this page.
Parameter PAGENAME = "Viewer Page";

/// Set this to the correct domain.
Parameter DOMAIN = "Ensemble";

/// Number of column in query that supplies ID values.
/// This can be overridden by subclasses.
Parameter VALUECOLUMNNO As INTEGER = 1;

/// Indicate whether value column should be displayed.
/// This can be overridden by subclasses.
Parameter SHOWVALUECOLUMN As BOOLEAN = 1;

/// Indicate whether toggle button for details pane should be displayed.
Parameter SHOWDETAILSTOGGLE As BOOLEAN = 1;

/// Indicate whether toggle button for search pane should be displayed.
Parameter SHOWSEARCHTOGGLE As BOOLEAN = 1;

/// Indicate if can cancel search.
Parameter CANCANCELSEARCH As BOOLEAN = 0;

/// Indicate if ought to create tempPortalNode when page created. Used by Cancel feature for example.
Parameter SETUPTEMPPORTALNODE As BOOLEAN = 0;

/// Id of selected item in results table.
Property selectedId As %ZEN.Datatype.string;

/// Diagnostic property. This contains the most recent query.
Property searchQuery As %ZEN.Datatype.string;

/// Number of the current page being viewed
Property currentPage As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// Row value indicating start of current "page" of results
Property currentPageStart As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// Flag to indicate whether the query has no more rows
Property queryAtEnd As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Flag to indicate whether the tablePane uses the 'sql' attribute to construct queries
/// during normal query execution. This flag determines whether the value of the 'sql' property
/// should be set to '' (empty string) on the client after changing between pages.
/// Initialize (or set) this property to 1 (on the server) or true (on the client) to avoid having
/// the value reset on the client. Under normal operation the property is cleared after each page change occurs.
Property tablePaneUsesSQLAttrib As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Id of the results tablePane
Property resultsTableId As %ZEN.Datatype.id [ InitialExpression = "resultsTable" ];

/// Id of the page size field
Property pageSizeId As %ZEN.Datatype.id [ InitialExpression = "pageSize" ];

/// Id of the page number field
Property pageNumberId As %ZEN.Datatype.id [ InitialExpression = "pageNumber" ];

/// Flag to indicate whether the detailsPanel is currently hidden.
Property detailsHidden As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Value to indicate the percentage of the horizontal screen which should be devoted to the
/// details panel (if it is visible). This is exposed as a client-side property for the layout
/// code to use the value.
Property detailsWidth As %ZEN.Datatype.integer(MAXVAL = 80, MINVAL = 5) [ InitialExpression = 30 ];

/// Search criteria from the client.<br/>
/// This is a proxy object whose contents are filled in from the search form
/// by the <method>doSearch</method> method. It is expected that the search
/// query will use this information to determine what results to display.
Property searchCriteria As %ZEN.proxyObject;

/// This is the $Job of the process running the search. 
/// It is used by the Cancel search process. 
/// If it is -1 then it indicates a Cancel has been issued. It is reset to '' when Search finishes.
Property searchJob As %ZEN.Datatype.string;

/// Flag to indicate whether this is the first page of results. The flag is updated on
/// the client after searches have completed.
Property isFirstPage As %ZEN.Datatype.boolean;

/// Flag to indicate whether this is the last page of results. The flag is updated on
/// the client after searches have completed.
Property isLastPage As %ZEN.Datatype.boolean;

/// Page identifier used with temp global for cancelling search
Property pageId As %ZEN.Datatype.string;

/// This is the temp global used for cancelling search
Property tempPortalNode As %ZEN.Datatype.string;

Property msgCloseDetail As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Close this detail box.")} ];

Property lblDetails As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Details")} ];

/// Hovertext used for detailsExpander Arrow
Property showDetailsMsg As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Show Details")} ];

/// Hovertext used for detailsExpander Arrow
Property hideDetailsMsg As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Hide Details")} ];

/// Hovertext used for searchExpander Arrow
Property showSearchMsg As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Show Search")} ];

/// Hovertext used for searchExpander Arrow
Property hideSearchMsg As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Hide Search")} ];

XData Style
{
<style type="text/css">

/* div around results table */
#resultsTable {
	width: 0px;
	background: white;
	overflow: scroll;
}

#searchPanel {
	/*width: 300px;*/
	padding-left: 5px;
	padding-right: 5px;
	background: #edece4;
	overflow: hidden;
	overflow-y: auto;
}

table.tpTable tr.tpEven {
	background: white;
}

table.tpTable tr.tpOdd {
	background: #F1F0E7;
}

table.tpTable tr.tpSelected {
	background: rgb(47,98,128);
	color: white;
}

table.tpTable tr.tpSelected td {
	font-weight: bold;
}

table.tpTable td {
	padding-right:10px;
}

table.tpTable {
	width: auto;
}

.searchPanelText {
	color: #404040;
	font-size: 10pt;
	text-align: center;
	padding: 3px;
	padding-top: 20px;
	padding-bottom: 20px;
}

.titlePane {
	color: #606060;
	font-family: Arial, Helvetica, sans-serif;	
	font-weight: bold;
	background: none;
	width: 100%;
	padding: 0px;
	border-bottom: 1px solid silver;
	font-size: 12pt;
	text-align: center;
}

.zenLabel {
	color: #404040;
	font-size: 10pt;
}

a.radioSetCaption {
	vertical-align: top;
	text-decoration: none;
	color: #404040;
	font-size: 10pt;
}

.formLabel {
	color: #404040;
	font-size: 10pt;
	font-weight: bold;
}

a.resultsAction {
	font-size: 11px;
	color: #3b84bc;
	text-decoration: none;
}

a.resultsAction:hover {
	color: darkred;
}

td.resultsRowNo {
	color: #808080;
	text-align: left;
}

.resultsRowSelected a.resultsAction {
	color: white;
}

.resultsRowSelected a.resultsAction:hover {
	color: orange;
}

.resultsRowMouseover, .tpMouseOver {
	background: #FFEEAA;
}

/* expanded details within table */
table td.detailsBox {
	padding: 0px;
	height: 200px;
	background: white;
	border: 1px solid black;
}

table.detailsTable {
	width: 100%;
}
/* selected row after "Details" is clicked */
table tr.detailsTableHeader {
	background: rgb(47,98,128);
	color: white;
	font-size: 12px;
}

/* details pane style */
#detailsGroup {
	background: #EDECE4;
	color: #606060;
	padding-left: 5px;
	padding-right: 5px;
	overflow: auto;
	border-left: 1px solid gray;
}
#searchGroup {
	background: #EDECE4;
	padding-left: 5px;
	padding-right: 5px;
	border-right: 1px solid gray;
}

/* styles for message details */
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

#detailExpanderLink {
	margin-right: 5px;
}
.helpArrow {
	border-radius: 3px;
}
.expanderDiv {
	padding-top: 1px;
}
</style>
}

/// Contents of Viewer page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup cellVAlign="top">
<hgroup id="searchGroup" valign="top">
<pane id="searchPanel" paneName="searchPane"/>
<html id="searchExpander" valign="top">
<div class="expanderDiv">
<a id="searchExpanderLink" class="helpCommand" href="#" onclick="zenPage.toggleSearch(); return false;">
<span id="searchExpanderArrow" class="helpArrow">&#171;</span>
</a>
</div>
</html>
</hgroup>
<pane id="resultsPanel" paneName="resultsPane" width="60%" />
<hgroup id="detailsGroup">
<html id="detailExpander" valign="top">
<div class="expanderDiv">
<a id="detailExpanderLink" class="helpCommand" href="#" onclick="zenPage.toggleDetails(); return false;"> 
<span id="detailExpanderArrow" class="helpArrow">&#187;</span>
</a></div>
</html>
<pane id="detailsPanel" paneName="detailsPane"/>
</hgroup>
</hgroup>
</pane>
}

/// Contents of Search panel.
/// This should be overridden in subclasses.
/// The search pane should contain a form with id="searchForm" and
/// invoke the <method>doSearch</method> method when a search is requested.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<titlePane title="Example Search Pane" labelClass="searchTitle" />
<form id="searchForm" labelPosition="top" cellStyle="padding:3px;">
<button controlClass="commandButton" caption="Search" onclick="zenPage.doSearch();"/>

<radioSet id="zoom" name="zoom" label="Zoom"
	displayList="Days,Hours,Minutes,Details"
	valueList="days,hours,minutes,details" value="days" onchange="zenPage.doSearch();"/>

<text label="Name" name="className"/>
<selector label="Class" name="XYZ" id="clsName" context="/Classes?super=%25Persistent"/>
<selector label="Property" name="XYZ2" context="/Properties?class=@clsName"/>

</form>
</pane>
}

XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<html id="detailsContent" OnDrawContent="DrawDetailsContent" />
</pane>
}

XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<html id="resultsTable" OnDrawContent="DrawResultsTable" />
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Viewer")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ""
	Quit $$$OK
}

/// Invoke a search using values from the search form.
ClientMethod doSearch() [ Language = javascript ]
{
	try {
		if (this._inSearch) return;
		this.toggleSearchState(true,true);
		this.selectItem(-1);
		try { // Reset any selected for those with multiselect true
			var table = this.getResultsTable();
			if (table.selectedRows != '') {
				table.selectedRows = '';
				table.updateRowSelectBoxes();
			}
		} catch(ex) {}

		var form = this.getSearchForm();

		// place form contents into searchCriteria property
		zenPage.searchCriteria = form.getValuesAsObject();
		this.currentPage = 1;
		this.currentPageStart = 0;
		this.queryAtEnd = 0;
		this._idIndex = new Object();

		this.updatePageSize();

		// Let subclass add to criteria
		this.onSearchHandler();

		this.executeSearch();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in doSearch().');
	}
}

/// Actually request the search on the server.
ClientMethod executeSearch() [ Language = javascript ]
{
	// refresh table
	var table = zenPage.getResultsTable();
	var loading = $$$Text('loading...');
	table.getEnclosingDiv().innerHTML = '<div style="padding:10px; font-style:italic; color:#606080;">' + loading + '</div>';
	// Used to show correct row numbers for the page.
	var sizeControl = zen(this.pageSizeId);
	if (sizeControl) {
		table.pageSize= parseInt(sizeControl.getValue(),10);
		table.currPage=this.currentPage;
	}
	table.refreshContents();
}

/// Notify subclass that a search is being executed.
ClientMethod onSearchHandler() [ Language = javascript ]
{
}

ClientMethod toggleSearchState(inSearch, canCallServer) [ Language = javascript ]
{
	this._inSearch = !!inSearch;
	var button = document.getElementById('command_searchButton');
	if (button) {
		button.className = 'commandButton' + (this._inSearch ? 'Disabled' : '');
	}
	// Keep Cancel button if it exists in synch with Search button
	if (typeof canCallServer == 'undefined') {canCallServer = true}; 
	zenPage.toggleCancelState(!!inSearch,canCallServer);
}

/// Show text of most recent query.
ClientMethod showQuery() [ Language = javascript ]
{
	if ((this.searchQuery != null) && (this.searchQuery != '')) {
		this._helpText = this.searchQuery;
		var link = zenLink('EnsPortal.Dialog.TooltipPopup.zen');
		var parms = {
			"LOCALIZEDNAME": $$$Text('Query Text'),
			"KEY": $$$Text('The most recently executed query text')
		};
		zenLaunchPopupWindow(link,'','scrollbars,resizable',parms);
	}
	else {
		alert($$$Text('Query not available'));
	}
}

/// Return the search form object.
ClientMethod getSearchForm() [ Language = javascript ]
{
	return zen('searchForm');
}

/// Return the search results object.
ClientMethod getResultsTable() [ Language = javascript ]
{
	return zen(this.resultsTableId);
}

/// Bring the maxRows property of the tablePane into line
/// with the current page size.
ClientMethod updatePageSize() [ Language = javascript ]
{
	var sizeControl = zen(this.pageSizeId);
	var table = this.getResultsTable();
	if (sizeControl && table) {
		var size = parseInt(sizeControl.getValue(),10);
		table.setProperty('maxRows', size);
	}
}

/// Select the given item (row in table) and let the subclass take any
/// necessary actions like updating the details pane.
ClientMethod selectItem(row) [ Language = javascript ]
{
	if (row && (typeof row == 'object')) { // got passed the tablePane object
		this.selectedId = row.getValue();
	}
	else {
		this.selectedId = -1;
	}
	this.onSelectItem();
}

/// Notify subclass that row was selected.
ClientMethod onSelectItem() [ Language = javascript ]
{
}

/// Expands and contracts the details pane, and ensures that
/// the results pane is expanded to fill in the space.
ClientMethod toggleDetails() [ Language = javascript ]
{
	var detailsPanel = zen('detailsPanel');
	var arrow = document.getElementById('detailExpanderArrow');
	if (this.detailsHidden) {
		arrow.innerHTML = '&#187;';
		this.detailsHidden = false;
		detailsPanel.setHidden(false);
	}
	else {
		arrow.innerHTML = '&#171;';
		this.detailsHidden = true;
		detailsPanel.setHidden(true);
	}
	this.onToggleDetails();
	this.onlayoutHandler();
}

/// Expands and contracts the search pane, and ensures that
/// the results pane is expanded to fill in the space.
ClientMethod toggleSearch() [ Language = javascript ]
{
	var searchPanel = zen('searchPanel');
	var arrow = document.getElementById('searchExpanderArrow');
	if (this.searchHidden) {
		arrow.innerHTML = '&#171;';
		this.searchHidden = false;
		this._searchWidth = 0;
		searchPanel.setHidden(false);
	}
	else {
		arrow.innerHTML = '&#187;';
		this.searchHidden = true;
		var wrapperDiv = searchPanel.getEnclosingDiv();
		this._searchWidth = wrapperDiv.offsetWidth;
		searchPanel.setHidden(true);
	}
	this.onToggleSearch();
	this.onlayoutHandler();
}

/// Callback for subclasses to take action when the details pane is
/// toggled. The <property>detailsHidden</property> property should be 
/// used to determine whether the details pane is currently hidden.
ClientMethod onToggleDetails() [ Language = javascript ]
{
}

/// Callback for subclasses to take action when the search pane is
/// toggled. The <property>searchHidden</property> property should be 
/// used to determine whether the search pane is currently hidden.
ClientMethod onToggleSearch() [ Language = javascript ]
{
}

/// Callback for subclasses to take action when a search completes.
/// Subclasses should ensure that they either implement behaviour
/// to handle page navigation behaviour OR call invokeSuper().
/// Subclasses should also ensure that zenPage.toggleSearchState(false) is called.
/// Pass false as second parameter if calling from error handler.
ClientMethod onAfterSearch() [ Language = javascript ]
{
	this.toggleSearchState(false,true);
	this.updateNavigationButtons();
	if (this._pageChange) {
		this.updatePageNumber();
	
		if (!this.tablePaneUsesSQLAttrib) {
			// reset 'sql' property to ensure that the client-side properties aren't overridden
			var table = this.getResultsTable();
			table.setProperty('sql','');
		}
	
		this.onAfterPageChange();
	}
	this._pageChange = false;
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		var searchGroup = zen('searchGroup');
		var searchPanel = zen('searchPanel');
		var results = zenPage.getResultsTable();
		var detailsPanel = zen('detailsPanel');
		var divSearchGroup = searchGroup.getEnclosingDiv();
		var divSearchPanel = searchPanel.getEnclosingDiv();
		var divSearchExpander = zen('searchExpander').getEnclosingDiv();
		var divResults = results.getEnclosingDiv();
		var divDetailsPanel = detailsPanel.getEnclosingDiv();
		var divDetailsGroup = zen('detailsGroup').getEnclosingDiv();

		// find size of window
		var winWidth = zenGetWindowWidth();
		var hgt = this.getContentAreaHeight();

		divResults.style.height = hgt + 'px';
		divSearchGroup.style.height = hgt + 'px';
		divSearchPanel.style.height = hgt + 'px';
		divDetailsPanel.style.height = (hgt - 30) + 'px';
		divDetailsGroup.style.height = hgt + 'px';
		
		var extraDetails = 0;
		if (this.searchHidden) {
			extraDetails = this._searchWidth;
		}
		
		var detailExpanderWidth = 0;
		var detailExpander = zen('detailExpander');
		if (detailExpander) {
			detailExpanderWidth = detailExpander.getEnclosingDiv().offsetWidth + (zenIsIE * 12);
		}
		if (!this.detailsHidden) {
			var detailsWidth = parseInt(this.detailsWidth / 100 * winWidth, 10);
			divDetailsGroup.style.width = detailsWidth + extraDetails + 'px';
			// Chrome renders this *way* differently, hence the extra condition for Chrome
			divDetailsPanel.style.width = detailsWidth + extraDetails - detailExpanderWidth - 20 + 'px';
		}
		else {
			divDetailsGroup.style.width = detailExpanderWidth + 'px';
		}
		var searchGroupWidth = divSearchPanel.offsetWidth + divSearchExpander.offsetWidth;
		divSearchGroup.style.width = searchGroupWidth + 'px';
		
		var resultsWidth = winWidth - divSearchGroup.offsetWidth - divDetailsGroup.offsetWidth;
		resultsWidth = (resultsWidth <= 0 ? 1 : resultsWidth);
		divResults.style.width = resultsWidth + 'px';
		
		this.updatePageNumber();
		this.adjustExpanderText();
		
		if (load) { // ensure we update the navigation & cancel buttons after first load
			this.toggleSearchState(false,true);
			this.updateNavigationButtons();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

/// Helper method to return the height we think the content area of the viewer should have.
ClientMethod getContentAreaHeight() [ Language = javascript ]
{
	return zenGetWindowHeight() - this.getTitleAreaHeight() - 15;
}

/// Ensure that the "Next" and "Previous" buttons behave correctly
/// based on the data returned from the current search.
ClientMethod updateNavigationButtons() [ Language = javascript ]
{
	this.isFirstPage = (this.currentPage == 1) || (parseInt(this.currentPageStart,10) < 0);
	var prev = document.getElementById('command_prevButton');
	if (prev) {
		prev.className = (this.isFirstPage ? 'commandButtonDisabled' : 'commandButton');
		prev.title = (this.isFirstPage ? $$$Text('No previous page for this search.') : $$$Text('Show the previous page of results, based on the Page Size'));
		prev.onclick = (this.isFirstPage ? function() { return false; } : function() { zenPage.getNextData(false); return false; });
	}
	
	var table = this.getResultsTable();
	var rowCount = table.getProperty('rowCount');
	this.isLastPage = (rowCount.indexOf('+') == -1);
	var next = document.getElementById('command_nextButton');
	if (next) {
		next.className = (this.isLastPage ? 'commandButtonDisabled' : 'commandButton');
		next.title = (this.isLastPage ? $$$Text('No next page for this search.') : $$$Text('Show the next page of results, based on the Page Size'));
		next.onclick = (this.isLastPage ? function() { return false; } : function() { zenPage.getNextData(true); return false; });
	}
}

/// Helper method invoked during layout to ensure the correct hovertext
/// is displayed for the show/hide arrow boxes
ClientMethod adjustExpanderText(type) [ Language = javascript ]
{
	if ((type == 'details') || (type == null)) {
		var detailExpanderLink = document.getElementById('detailExpanderLink');
		if (this.detailsHidden) {
			detailExpanderLink.title = this.showDetailsMsg;
		}
		else {
			detailExpanderLink.title = this.hideDetailsMsg;
		}
	}
	if ((type == 'search') || (type == null)) {
		var searchExpanderLink = document.getElementById('searchExpanderLink');
		if (this.searchHidden) {
			searchExpanderLink.title = this.showSearchMsg;
		}
		else {
			searchExpanderLink.title = this.hideSearchMsg;
		}
	}
}

/// User clicked the Next Page or Previous Page button
ClientMethod getNextData(next) [ Language = javascript ]
{
	// provide message strings
	var noprev = $$$Text('No previous page for this search.');
	var nonext = $$$Text('No next page for this search.');

	// get current table properties
	var table = this.getResultsTable();
	var pageSize = parseInt(table.getProperty('maxRows'));
	var rowCount = table.getProperty('rowCount');
	
	this.updatePageData();
	var currentPage = zenPage.currentPage;
	
	// adjust paging values
	if (next) { // get next data
		if (this.isLastPage) { // we are on the last page
			alert(nonext);
			return false;
		}
		else {
			zenPage.currentPageStart = parseInt(zenPage.currentPageStart,10) + pageSize;
			zenPage.currentPage++;
		}
	}
	else { // get previous data
		zenPage.currentPageStart = parseInt(zenPage.currentPageStart,10) - pageSize;
		if ((parseInt(zenPage.currentPageStart,10) < 0) || this.isFirstPage) { // we are already at the beginning
			zenPage.currentPageStart = 0;
			zenPage.currentPage = 1;
			alert(noprev);
			return false;
		}
		else { // we are not at the beginning
			zenPage.currentPage--;
		}
	}
	// call page-specific code to set up the new query/resultset
	this.onChangeResultsPage(next, pageSize, currentPage);
	
	if (table.multiSelect) table.selectAllMultiRows(false);
	this._pageChange = true;
	this.updatePageSize();
	// Disable Search button and Enable Cancel button.
	this.toggleSearchState(true,true);
	this.executeSearch();
	
	return true;
}

/// Helper method to record the first and last ID values for the current page.
ClientMethod updatePageData() [ Language = javascript ]
{
	if (!this._idIndex) {
		this._idIndex = new Object();
	}
	this._idIndex[this.currentPage] = new Object();
	var currPageData = this._idIndex[this.currentPage];
	
	var table = this.getResultsTable();
	var tableDiv = table.getEnclosingDiv();
	var rows = tableDiv.getElementsByTagName('tr');
	
	var lastRow = rows[rows.length - 2];
	currPageData.lastId = lastRow.getAttribute('zenvalue');
	
	var firstRow = rows[1];
	currPageData.firstId = firstRow.getAttribute('zenvalue');
}

/// Callback to set up the resultset/query for paging.
ClientMethod onChangeResultsPage(next, pageSize, currentPage) [ Language = javascript ]
{
	var table = this.getResultsTable();
	var orderby = table.getProperty('orderByClause');
	
	if (!this.searchCriteria) {
		var searchForm = this.getSearchForm();
		this.searchCriteria = searchForm.getValuesAsObject();
	}
	var timeFormat = this.searchCriteria.timeFormat;
	
	// set up values to contribute to new query
	var wherePlus;
	var outer;
	var idCol = 'ID';
	var valueCol = table.getProperty('valueColumn');
	if (valueCol != '') {
		idCol = valueCol;
	}
	if (orderby.match('desc')) { // descending order
		outer = idCol +' DESC';
		wherePlus = idCol + ' <';
	}
	else { // ascending order
		outer = idCol + ' ASC';
		wherePlus = idCol + ' >';
	}
	
	if (next) { // at this point we know there are at least pageSize entries on the current page
		
		var idVal = null;
		if (this._idIndex[zenPage.currentPage - 1]) {
			var pageData = this._idIndex[zenPage.currentPage - 1];
			idVal = pageData.lastId;
		}
		
		var limit = pageSize;
		var tableDiv = table.getEnclosingDiv();
		var rows = tableDiv.getElementsByTagName('tr');
		var lastRow = rows[limit];
		var idVal = lastRow.getAttribute('zenvalue');
	   	if (zenPage.currentPage == 2) { // we are moving off the first page
			this._oldIds = new Array(); // establish oldIds array to remember IDs
			var firstRow = rows[1]; // row[0] is header row
			var firstId = firstRow.getAttribute('zenvalue'); // get the first idVal
	   		this._oldIds[1] = firstId; 
		}
		this._oldIds[zenPage.currentPage] = idVal;
	}
	else {
		if (this._oldIds[zenPage.currentPage]) { // reuse the content for this row
			idVal = this._oldIds[zenPage.currentPage];
			if (zenPage.currentPage == 1) wherePlus = wherePlus + '='; // for the first idVal it is <= or >=
		}
	}
	
	// recalculate the table (our new query temporarily overrides whereClause etc.)
	wherePlus = wherePlus + ' ';
	var ret = zenPage.ResetQuery(next,pageSize,timeFormat,wherePlus,idVal,outer);
}

/// Callback invoked after the next/previous page has been loaded.
ClientMethod onAfterPageChange() [ Language = javascript ]
{
	return true;
}

/// Helper method to update the component which displays the current page number
ClientMethod updatePageNumber() [ Language = javascript ]
{
	var numberControl = zen(this.pageNumberId);
	if (numberControl) {
		numberControl.setValue(this.currentPage);
	}
}

/// Show/hide the toggle buttons
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tDetailExpander = ..%GetComponentById("detailExpander")
	If $IsObject(tDetailExpander) {
		Set tDetailExpander.hidden = '..#SHOWDETAILSTOGGLE
	}
	
	Set tSearchExpander = ..%GetComponentById("searchExpander")
	If $IsObject(tSearchExpander) {
		Set tSearchExpander.hidden = '..#SHOWSEARCHTOGGLE
	}
	Set ..pageId = $SYSTEM.Encryption.Base64Encode($system.Encryption.SHA1Hash($ZTIMESTAMP))
	Set ..tempPortalNode = $S(..#SETUPTEMPPORTALNODE:##class(EnsPortal.SessionEvents).GetReference(##class(EnsPortal.SessionEvents).GetTempNode()),1:"")
	
	Quit tSC
}

/// Helper method to construct a <tablePane> query on the server when paging.
/// This method should be invoked from <method>onChangeResultsPage</method>()
/// for tablePanes which use the whereClause, orderbyClause and columns properties
/// to construct queries. <var>next</var> is true for Next, false for Previous;
/// <var>pageSize</var> is the page size; <var>wherePlus</var> gives the ID < or ID > string;
/// <var>idVal</var> gives the id value to compare with ID,
/// <var>outer</var> is either ASC or DESC depending on the current display order.
Method ResetQuery(next As %Boolean, pageSize As %String, timeFormat As %String, wherePlus As %String, idVal As %String, outer As %String) As %String [ ZenMethod ]
{
	Set table = ..%GetComponentById(..resultsTableId)
	Set whereNew = "" // possibly, we won't modify the where clause at all
	If (idVal '= "first") { // do not modify the where clause if we are on the first page
		If (table.whereClause = "") { // current where clause is blank
			If (wherePlus '= "") { // add the clause
				Set whereNew = " WHERE " _ wherePlus _ idVal
			}		
		}
		Else {	// current where clause is non-blank	
			If (wherePlus = "") { // no changes to make
				Set whereNew = " WHERE " _ table.whereClause
			}
			Else { // add the clause
				Set whereNew = " WHERE " _ table.whereClause _ " AND " _ wherePlus _ idVal
			}
		}	
	}
	
	Set columns = ..GetColumnsAndFrom(timeFormat)
	Set sql = "SELECT TOP " _ pageSize _ " "_ columns _" "
	
	Set sql = sql _ whereNew
	Set sql = sql  _ " ORDER BY " _ outer
	
	// set the sql attribute so that our new query overrides whereClause etc. 
	// Resetting the sql attribute must be done on the server side, so it's done here.
	Set table.sql = sql
	
	// return a value to ensure this is synchronous on client and server
	Quit ""
}

/// For tablePanes which require a constructed SQL query when paging, this
/// callback supplies the columns and FROM portions of the query.
Method GetColumnsAndFrom(timeFormat As %String) As %String
{
	Quit ""
}

/// Write out details for the given item.
/// This should be overridden within the subclass.
Method DrawDetailsContent(pID As %String) As %Status
{
	&html<<table>>
	&html<<tr><td>ID:</td><td>#(pID)#</td></tr>>
	&html<</table>>
	Quit $$$OK
}

/// Get the contents of the link menu in the table.<br>
/// Sub-class may override to add more links.<br>
/// If more links are added, sub-class is to provide client methods for additional links.
Method %OnGetTableLinkMenu(Output pMenu)
{
}

/// Override this method to allow us to report gateway timeouts in a user-friendly manner.
ClientMethod onServerMethodError(err, errObject) [ Language = javascript ]
{
	// If we have errored then do make sure not to call server again in order to avoid loop; 
	var canCallServer = false;
	// OK to call again if timedout
	if (errObject.code == 504) {canCallServer = true};
	this.toggleSearchState(false,canCallServer);
	if (errObject) {
		if (errObject.code == 504) {
			var timeoutText = $$$Text('Executing your search took longer than the timeout for requests.');
			timeoutText += '\n';
			timeoutText += $$$Text('Either refine your search to improve the performance, or contact your system administrator to diagnose the issue further.');
			alert(timeoutText);
			var table = zenPage.getResultsTable();
			if (table) {
				var msg = $$$Text('Timed Out');
				table.getEnclosingDiv().innerHTML= '<div style="padding:10px; font-style:italic; color:#606080;">'+msg+'</div>';
			}
			return true;
		}
	}
	return this.invokeSuper('onServerMethodError',arguments);
}

ClientMethod onEnsException() [ Language = javascript ]
{
	this.toggleSearchState(false,false);
}

/// When the Cancel button is enabled setup the cancel event.
/// When the Cancel button is disabled handle multiple pages and change table output to say Cancelled if the search was cancelled. 
ClientMethod toggleCancelState(inSearch, canCallServer) [ Language = javascript ]
{
	var cancelbutton = document.getElementById('command_cancelButton');
	if (cancelbutton) {
		cancelbutton.className = 'commandButton' + (!inSearch ? 'Disabled' : '');
		if (!inSearch ) {
			// Clean up and if searchJob = -1 then cancel was tried.
			if (this.searchJob==-1) {
				if (this._pageChange) {
					this.currentPage = 1;
					this.updateNavigationButtons();
					this._pageChange = false;
				}
			}
			// Change table output. May be here as a result of error calling server.
			if (canCallServer) {zenPage.indicateIfCancelled();} 
		}
	}
}

/// Record in temp Portal node this pid so that client can send cancel/interrupt
Method PrepareCancel() As %String [ ZenMethod ]
{
	Try { Set @%page.tempPortalNode@(%page.pageId,"SearchJob")=$Job } Catch {}
	Quit $Job
}

/// Client side method to invoke the Cancel.
ClientMethod cancelSearch() [ Language = javascript ]
{
	if (!this._inSearch) {
		alert($$$Text('No search in progress'));
		return;	
	}
	var signaled = zenPage.SignalCancel(true,true);
	if (signaled==-1) {
		alert($$$Text('No search in progress'));
		return;
	}
	if (signaled==2) {
		alert($$$Text('Cancel already requested'));
		return;
	}
	// Cannot cancel if this process is the job to be interrupted (3)
	if ((!signaled)||(signaled==3)) {
		alert($$$Text('Attempting to cancel search'));
		return;
	}
	//Record that we cancelled.
	this.searchJob='-1';
}

/// Signal query to cancel. Use Event signal first and then try Interrupt.
Method SignalCancel(pSendStop As %Boolean = 1, pSendInterrupt As %Boolean = 1) As %Integer [ ZenMethod ]
{
	Try { 
			Set tSignaled = 0,tJob=$G(@..tempPortalNode@(..pageId,"SearchJob"))
			If (tJob="") {
				Set tSignaled=-1 
				Quit // No job to signal
			}
			#;only one Job per SearchJob but using expected job subscript to add check for target job.
			If pSendStop {
				Set tRequestOutstanding = $G(@..tempPortalNode@(..pageId,"SearchJob",tJob,"Stop"),0)
				If tRequestOutstanding { 
					Set tSignaled = 2
					Quit // Already wrote Stop and waiting for remote to act on it.
				} Else {
					Set @..tempPortalNode@(..pageId,"SearchJob",tJob,"Stop")=1
					Hang 0.2
					Set tRequestOutstanding = $G(@..tempPortalNode@(..pageId,"SearchJob",tJob,"Stop"),0)
					If 'tRequestOutstanding {
						Set tSignaled = 1
						Quit // Target received stop and acted on.
					}
				}
			}
			#; Either Stop was not used or target failed to respond. Send interrupt if allowed.
			If pSendInterrupt {
				If ($J=tJob) {
					Set tSignaled = 3
					Quit // Do not send interrupt to self but also do not delete the Event. 
				}
				#;Using Default timeout of 10 seconds
				Set tSignaled=$$$ISOK($SYSTEM.SQL.CancelQuery(tJob))
			}		
	} Catch {}
	
	#;Mark cancelled.
	Set:(tSignaled=1) @..tempPortalNode@(..pageId,"SearchJob")=-1
	
	Quit tSignaled
}

/// Change table output to Cancelled if we cancelled
ClientMethod indicateIfCancelled() [ Language = javascript ]
{
	// Find remote job and also clean up remote data.
	var searchJob= zenPage.GetRemoteSearchJob(true);
	zenPage.searchJob='';					
	if ((!searchJob)||(searchJob!='-1')) { return;}
	var table = zenPage.getResultsTable();
	if (!table) {return;}
	var msg = $$$Text('Cancelled');
	table.getEnclosingDiv().innerHTML= '<div style="padding:10px; font-style:italic; color:#606080;">'+msg+'</div>';
}

Method GetRemoteSearchJob(pRemoveTempData As %Boolean = 0) As %String [ ZenMethod ]
{
	Quit:(..tempPortalNode="") ""
	Try { Set tSearchJob = @..tempPortalNode@(..pageId,"SearchJob")} Catch {Set tSearchJob=""}
	Do:pRemoveTempData ..RemoveTempData()
	Quit tSearchJob
}

/// Remove Event.
Method RemoveTempData() As %Integer [ ZenMethod ]
{
	Try {
		Kill @..tempPortalNode
	} Catch {}
	Quit $$$OK
}

}
