/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsPortal.Template.filteredViewer Extends EnsPortal.Template.viewerPage [ Abstract, System = 4 ]
{

/// Comma separated list of subscripts to use in the %session object for saved searches.
Parameter SessionSubscripts = "SavedSearch";

/// Name of column to use for Session ID in links.
/// This is primarily for the MessageBank, which displays the client session but links to the banked session.
Parameter SessionTraceColumn = "ID";

/// Name of the Assistant class to use.
Property assistantClass As %String [ InitialExpression = {..GetAssistantClass()}, ReadOnly ];

/// Name of Filter class to use for filtering searches.
Property filterClass As %String [ InitialExpression = "EnsPortal.MsgFilter.Filter", ReadOnly ];

/// Name of SavedSearch class to use for saving searches.
Property savedSearchClass As %String [ InitialExpression = "EnsPortal.MsgFilter.SavedSearch", ReadOnly ];

/// URL of dialog window to use for editing Search Criteria.
Property criteriaDialog As %String [ InitialExpression = "EnsPortal.Dialog.SearchCriteria.zen", ReadOnly ];

/// Header class to use for queries and display.
Property headerClass As %String [ InitialExpression = "Ens.MessageHeader", ReadOnly ];

/// URL of resend page.
Property resendPage As %String [ InitialExpression = "EnsPortal.MessageResend.zen" ];

/// Name of the current saved search. Should be empty if no saved search is selected.
/// Users can bookmark saved searches by using making use of the SAVEDSEARCH parameter in the URL.
Property currentSearch As %ZEN.Datatype.string(ZENURL = "SAVEDSEARCH");

/// Flag to indicate whether the server should check for search warnings.
/// This is set to 1 to avoid issues when first loading the query as part of the page load,
/// and should then be set to 0 for most subsequent searches. It should only be set to 1
/// when users have read a warning and have chosen to execute a possibly problematic query.
Property ignoreSearchWarnings As %Boolean [ InitialExpression = 1 ];

/// List of warnings regarding the user's current search criteria.
Property searchWarnings As list Of %String;

Property sessionLinkTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Click to view a visual trace of the session")} ];

Property tipAddCriterion As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Add Criterion")} ];

Property tipAddCriterionTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Add a new criterion")} ];

Property tipAddOR As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Add OR")} ];

Property tipAddORTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Add an OR condition")} ];

Property tipDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

Property tipSave As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save")} ];

Property tipSaveAs As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save As")} ];

Property msgViewTrace As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("View Full Trace")} ];

Property msgViewTraceHover As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("View Full Trace including Events and message contents")} ];

/// Flag to indicate whether onLoadHandler has been called yet.
/// This is set to 1 initially, and is set to 0 once onLoadHandler is executed.
/// This is checked before the query is executed to ensure that long running queries are not automatically re-run without user approval. 
Property inFirstLoad As %Boolean [ InitialExpression = 1, Internal ];

/// Flag to indicate whether the filter values match the defaults.
/// This is set to 0 initially, and calculated in InitSearchCriteria.
/// This determines whether the filter loaded from the session should run automatically, or if we should wait for the user to click 'Search' 
Property isDefaultFilter As %Boolean [ InitialExpression = 0, Internal ];

/// Flag to indicate whether a user may resend messages. Sub classes to implement based on resource required.
Property canResend As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property VirtualKey As %Integer [ InitialExpression = 0, Internal ];

XData Style
{
<style type="text/css">
.detailContents {
	padding: 8px;
}
.detailContentsError {
	color: red;
}
#bodyContents {
	background-color: white;
}
#detailsTabGroup .tabGroupBar {
	padding-top: 2px;
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
.criterion {
	border: 1px solid grey;
	padding: 5px;
	margin-top: 3px;
}
#extendedCriteriaTable {
	border-collapse: separate;
	border-spacing: 0;
}
#extendedCriteriaTable td {
	font-size: 12px;
	font-weight: bold;
	background-color: white;
	padding: 3px;
}
#extendedCriteriaTable th {
	font-size: 13px;
	padding: 2px;
}
#extendedCriteriaTable td.criterionDisabled {
	background-color: #EDECE4;
}
.criterionStart {
	border-top: 1px solid gray;
}
.criterionLeft {
	border-left: 1px solid gray;
}
.criterionRight {
	border-right: 1px solid gray;
}
.criterionEnd, .criterionTitle {
	border-bottom: 1px solid gray;
}
.criterionLeft.criterionStart {
	border-top-left-radius: 6px;
}
.criterionRight.criterionStart {
	border-top-right-radius: 6px;
}
.criterionRight.criterionEnd {
	border-bottom-right-radius: 6px;
}
.criterionLeft.criterionEnd {
	border-bottom-left-radius: 6px;
}
.criterionOR {
	text-align: center;
	font-weight: bold;
}
.conditionProp {
	text-align: center;
}
.critLink {
	cursor: pointer;
}
.critLink.wrapper {
	border: 1px solid gray;
	padding: 1px 5px 1px 1px;
	border-radius: 5px;
	background-color: white;
	white-space: nowrap;
}
.linkText {
	font-size: 12px;
	font-weight: bold;
}
.joinCell {
	text-align: center;
	vertical-align: middle;
	font-weight: bold;
	border-left: 1px solid gray;
	border-right: 1px solid gray;
}
</style>
}

/// Contents of Search panel.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<pane id="jsonPane" paneName="jsonPane" hidden="true" />
<jsonProvider id="queryHistory" OnGetArray="GetQueryHistory" />

<!--
These controls define the search criteria.
The values of these controls are placed in the searchCriteria object (using the
control *name* as the property name) when a search is executed.
-->

<form id="searchForm" labelPosition="top" cellStyle="padding:3px;">

<hgroup>
<vgroup cellStyle="padding:3px;">
<select label="Sort Order" id="SortOrder" name="SortOrder" displayList="Newest First,Oldest First" valueList="2,1" value="2" showEmpty="false" onchange="zenPage.updateSearchState(); return true;"/>
<select id="TimeFormat" label="Time Format" name="TimeFormat" showEmpty="false" value="999" valueList="999,12" displayList="Complete,Time Only" onchange="zenPage.updateSearchState(); return true;"/>
</vgroup>
<vgroup cellStyle="padding:3px;">
<combobox label="Page Size" id="pageSize" name="pageSize" onchange="zenPage.searchIfValidPageSize(zenThis.value);" editable="true" 
	unrestricted="true" size="4" title="Select Page Size in rows or enter a number" valueList="1,5,10,20,30,50,100,200,500,1000" value="100"/>
<text label="Page" id="pageNumber" name="pageNumber" readOnly="true" size="4" />
</vgroup>
</hgroup>


<expando id="simpleCriteria" caption="Basic Criteria" animate="true">

<hgroup cellStyle="padding:3px;">
<select label="Status" name="Status" displayList="All,Completed,Error,Created,Queued,Delivered,Discarded,Suspended,Deferred,Aborted" 
	valueList=",9,8,1,2,3,4,5,6,7" value="" showEmpty="false" onchange="zenPage.updateSearchState(); return true;"/>
<select label="Type" id="Type" name="Type" displayList="Session Start,Request,Response,All" valueList="0,1,2,3" value="0" showEmpty="false" onchange="zenPage.updateSearchState(); return true;"/>
</hgroup>

<hgroup cellStyle="padding:3px;">
<dateText label="Start Time" name="StartTime" size="18" showTime="true" defaultTime="00:00:00" onchange="zenPage.updateSearchState(); return true;"/>
<text label="Start ID" name="StartId" size="9" onchange="zenPage.updateSearchState(); return true;"/>
</hgroup>

<hgroup cellStyle="padding:3px;">
<dateText label="End Time" name="EndTime" size="18" showTime="true" defaultTime="23:59:59" onchange="zenPage.updateSearchState(); return true;"/>
<text label="End ID" name="EndId" size="9" onchange="zenPage.updateSearchState(); return true;"/>
</hgroup>

<selector id="Source" label="Source" name="Source" size="33" context="Ens/MsgSource" onchange="zenPage.updateSearchState(); return true;"/>

<selector id="Target" label="Target" name="Target" size="33" context="Ens/MsgTarget" onchange="zenPage.updateSearchState(); return true;"/>
<text id="SequenceManagerSearch" name="SequenceManagerSearch" hidden="true" />
</expando>

<expando id="extendedCriteria" caption="Extended Criteria" expanded="false" animate="true">
<hgroup>
<spacer width="5" />
<html>
<div id="addCriterion" class="critLink wrapper" title="#(%page.tipAddCriterionTitle)#" onclick="zenPage.addCriterion(); return false;">
<img id="addCriterionBtn"  src="portal/add_24.gif" style="vertical-align: middle;" ></img>
<span id="addCriterionTxt" class="linkText">#(%page.tipAddCriterion)#</span>
</div>
</html>
<spacer width="15" />
<html>
<div id="addOR" class="critLink wrapper" title="#(%page.tipAddORTitle)#" onclick="zenPage.addOR(); return false;">
<img id="addORBtn" src="portal/views_add_48.gif" width="24px" height="24px" style="vertical-align: middle;" ></img>
<span id="addORTxt" class="linkText">#(%page.tipAddOR)#</span>
</div>
</html>
</hgroup>
<spacer height="5"/>
<html id="criteria">
</html>
</expando>

<expando id="savedSearches" caption="Saved Searches" expanded="false" animate="true">
<hgroup>
<html>
<div id="saveSearch" class="critLink wrapper" title="#(%page.tipSave)#" onclick="zenPage.saveSearch();">
<img id="saveSearchBtn" src="deepsee/insert_table_48.png" width="24px" height="24px" style="vertical-align: middle;" ></img>
<span id="saveSearchTxt" class="linkText">#(%page.tipSave)#</span>
</div>
</html>
<spacer width="10" />
<html>
<div id="saveSearchAs" class="critLink wrapper" title="#(%page.tipSaveAs)#" onclick="zenPage.toggleSaveAs(true);">
<img id="saveSearchAsBtn" src="deepsee/insert_table_fav_48.png" width="24px" height="24px" style="vertical-align: middle;" ></img>
<span id="saveSearchAsTxt" class="linkText">#(%page.tipSaveAs)#</span>
</div>
</html>
<spacer width="10" />
<html>
<div id="searchDelete" class="critLink wrapper" title="#(%page.tipDelete)#" onclick="zenPage.deleteSearch(zen('savedList').getValue());">
<img id="searchDeleteBtn" src="deepsee/close_a_24.png" width="24px" height="24px" style="vertical-align: middle;" ></img>
<span id="searchDeleteTxt" class="linkText">#(%page.tipDelete)#</span>
</div>
</html>
</hgroup>
<spacer height="10" />
<hgroup id="searchSaveGroup">
<select id="savedList" showEmpty="true" title="Choose a saved search" queryClass="EnsPortal.MsgFilter.SavedSearch" queryName="ListPermanent" controlStyle="width: 200px;" onchange="zenPage.loadSearch(zenThis.getValue(), false);" />
</hgroup>
<hgroup id="searchSaveAsGroup" hidden="true" cellVAlign="top">
<text id="saveAsName" hint="Enter a name for the search" />
<spacer width="5" />
<image id="saveAsGo" title="Save this search" onclick="zenPage.saveSearch(zen('saveAsName').getValue(),true);" controlClass="critLink" src="deepsee/ok_24.png" />
<spacer width="5" />
<image id="saveAsExit" title="Don't save search" onclick="zenPage.toggleSaveAs(false);" controlClass="critLink" src="deepsee/close_a_24.png" />
</hgroup>
</expando>
</form>
</pane>
}

XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tabGroup id="detailsTabGroup" showTabBar="true" remember="true" onshowTab="zenPage.onTabChange();" >
<tab id="headerDetails" caption="Header" title="Message Header Properties">
<html id="detailsContent" OnDrawContent="DrawDetailsContent" />
</tab>
<tab id="bodyDetails" caption="Body" title="Message Body Properties">
<html id="bodyInfo" OnDrawContent="DrawBodyInfo" />
</tab>
<tab id="bodyContents" caption="Contents" title="Message Body Contents">
<html id="fullContent" containerStyle="padding-top: 5px; padding-bottom: 5px;" OnDrawContent="DrawFullContentLinks" />
<iframe id="contentFrame" frameBorder="false"/>
</tab>
<tab id="traceContent" caption="Trace" title="Message Trace">
<html id="traceLink" enclosingStyle="padding: 5px;" >
<a class="ribbonSortOption fullMessage" href="#" onclick="zenPage.showTrace(zenPage.selectedId); return false;" title="#(%page.msgViewTraceHover)#">#(%page.msgViewTrace)#</a>
<span id="traceTruncated" class="fullMessage" style="padding-left:10px; font-weight: bold;"></span>
</html>
<pane id="svgTracePane" paneName="svgTracePane" />
</tab>
</tabGroup>
</pane>
}

/// Server-side method to write out the content for the SessionId cells.
/// The main purpose is to ensure that links to the Visual Trace diagram are only included
/// for events which occurred as part of a session.
Method DrawSessionCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Set tDisplaySession = ..EscapeHTML($get(%query("Session")))
	Set tSessionId = $ZCVT($ZCVT($get(%query(..#SessionTraceColumn)),"O","JS"),"O","HTML")

	If tDisplaySession = "" {
		&html<&nbsp;>
	}
	Else {
		&html<<a class="sessionLink" title="#(..EscapeHTML(..sessionLinkTitle))#" onclick="zenPage.showTrace('#(tSessionId)#',event); return false;">#(tDisplaySession)#</a>>
	}
	Quit $$$OK
}

/// Get the current saved search
Method GetSavedSearch() As %String
{
	If '$IsObject($get(%session)) Quit ""
	Quit $get(@..GetSessionLoc())
}

Method GetSessionLoc() As %String [ Private ]
{
	Set tSub = "%session.Data(""Ensemble"""
	For i=1:1:$length(..#SessionSubscripts,",") {
		Set tSub = tSub _","""_$piece(..#SessionSubscripts,",",i)_""""
	}
	Set tSub = tSub _ ","""_$namespace_""")"
	Quit tSub
}

Method SetSavedSearch(pSearchName As %String = "") As %Status
{
	If '$IsObject($get(%session)) Quit $$$OK
	If pSearchName = "" {
		Kill @..GetSessionLoc()
	}
	Else {
		Set @..GetSessionLoc() = pSearchName
	}
	Quit $$$OK
}

/// Load Filter object from the session, or from a saved search if requested.
Method LoadFilter(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	If $get(pParms("Reset")) {
		Set tStatus = ..SetSavedSearch("")
		If $$$ISERR(tStatus) Quit tStatus
		Set tStatus = $classmethod(..filterClass,"DeleteFromVirtualSession",..VirtualKey)
		If $$$ISERR(tStatus) Quit tStatus
	}
	Else { // check for saved search
		Set tSavedSearch = ""
		If $get(pParms("SavedSearch")) '= "" {
			Set tSavedSearch = $classmethod(..savedSearchClass,"%OpenId",pParms("SavedSearch"))
		}
		
		If $IsObject(tSavedSearch) {
			Set tStatus = ..SetSavedSearch(tSavedSearch.Name)
			If $$$ISERR(tStatus) Quit tStatus
			Set ..currentSearch = tSavedSearch.Name
			Set tList = ..%GetComponentById("savedList")
			If $IsObject(tList) && (tList.value = "") {
				Set tList.value = tSavedSearch.Name
			}
			Set tVirtualKey = ..VirtualKey
			Set tStatus = tSavedSearch.Filter.SaveToVirtualSession(.tVirtualKey)
			Set ..VirtualKey = tVirtualKey
			Set pObject = tSavedSearch.Filter
			Quit tStatus
		}
		Else { // Couldn't load saved search, fall through to previous
			Set tStatus = ..SetSavedSearch("")
			If $$$ISERR(tStatus) Quit tStatus
		}
	}
	Quit $classmethod(..filterClass,"LoadFromVirtualSession",..VirtualKey,.pObject)
}

/// Initialise the search criteria for the page.
Method InitSearchCriteria() As %Status
{
	Set tStatus = $classmethod(..filterClass,"LoadFromVirtualSession",..VirtualKey,.tFilter)
	If $$$ISERR(tStatus) Quit tStatus
	
	If tFilter.SortOrder = "" {
		Set tFilter.SortOrder = tFilter.SortOrderDisplayToLogical("Newest First")
	}
	If tFilter.Type = "" {
		Set tFilter.Type = tFilter.TypeDisplayToLogical("Session Start")
	}
	
	// Determine whether the initial filter loaded from the virtual session matches the default search criteria
	// Only called if not already set to true on first pass so that criteria set after load from virtual session do not get counted
	Set:'..isDefaultFilter ..isDefaultFilter = $classmethod(..filterClass,"HasDefaultVals",tFilter)
	
	Set tStatus = $classmethod(..assistantClass,"CreateProxy",tFilter, .tSearchCriteria)
	If $$$ISERR(tStatus) Quit tStatus
	
	Set ..searchCriteria = tSearchCriteria
	Set ..%GetComponentById("SortOrder").value = ..searchCriteria.SortOrder
	Set ..%GetComponentById("Type").value = ..searchCriteria.Type
	
	Set ..searchCriteria.pageSize = 100
	Set ..%GetComponentById("pageSize").value = 100
	
	Quit $$$OK
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
		Set tNeedsLock = 1
		Try {
			Set tNeedsLock = +$parameter(..assistantClass,"NeedsSessionLock")
		}
		Catch {}
		If 'tNeedsLock {
			Set tTable = ..%GetComponentById(..resultsTableId)
			If $IsObject(tTable) && (tTable.lastUpdate '= "") {
				Do %session.Unlock()
			}
		}
		Set pSC = $classmethod(..assistantClass,"GetResultSet",tFilter, .tRS)
		// Ensure the query text is updated, even if an error occurs
		Set ..searchQuery = tFilter.GeneratedSQL
		If $$$ISERR(pSC) Quit
		
		Set pInfo.queryExecuted = 1
		Set pInfo.queryText = tFilter.GeneratedSQL
	}
	Catch(ex) {
		Set pSC = $$$SystemError
		Set tRS = ""
	}
	Quit tRS
}

Method SetSearchCriteria() As %String [ ZenMethod ]
{
	Set tSC = ..InitSearchCriteria()
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	
	Set tPageNum = ..%GetComponentById("pageNumber")
	If $IsObject(tPageNum) {
		Set tPageNum.value = ..currentPage
	}
	
	Set tSavedList = ..%GetComponentById("savedList")
	Set tSavedList.queryClass = ..savedSearchClass
	If (..currentSearch '= "") {
		If $classmethod(..savedSearchClass,"%ExistsId",..currentSearch) {
			Set tSearchExpando = ..%GetComponentById("savedSearches")
			Set tSearchExpando.expanded = 1
			Set tCurrentSearch = $classmethod(..savedSearchClass,"%OpenId",..currentSearch)
			If $IsObject(tCurrentSearch) {
				If tCurrentSearch.Filter.Terms.Count() {
					Set tCriteriaExpando = ..%GetComponentById("extendedCriteria")
					Set tCriteriaExpando.expanded = 1
				}
				Set tVirtualKey = ..VirtualKey
				Do tCurrentSearch.Filter.SaveToVirtualSession(.tVirtualKey)
				Set ..VirtualKey = tVirtualKey
			}
			Else {
				Set ..currentSearch = ""
			}
		}
		Else {
			Set ..currentSearch = ""
		}
	}
	Do ..SetSavedSearch(..currentSearch)
	Do ..%SetValueById("namedSearch",..currentSearch)
	Set tSavedList.value = ..currentSearch

	Quit ""
}

/// Update the details for a selected message.
ClientMethod drawDetails(messageId) [ Language = javascript ]
{
	var details = zen('detailsContent');
	
	if ((messageId == -1) || (messageId == null)) {
		details.seed = '';
	}
	else {
		// get contents from server
		details.seed = messageId;
	}
	details.refreshContents(true);
}

/// User clicked on a tab, or selected a new item, so we need to fetch the 
/// required content from the server.
ClientMethod onTabChange() [ Language = javascript ]
{
	// Don't get data from server if data isn't visible
	// It will be retrieved when the tabs are redisplayed
	if (!this.detailsHidden) {
		this.layoutTabGroup();
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
						var bodyInfo = zen('bodyInfo');
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
							frame.setProperty('src', zenLink('EnsPortal.MessageContents.zen?HeaderClass='+this.headerClass+'&HeaderId='+this.selectedId+'&LIMITSIZE=20000'));
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

ClientMethod showFullContent(showRaw, showJSON) [ Language = javascript ]
{
	if ((this.headerClass.length > 0) && (this.selectedId.length > 0))
 		window.open(zenLink('EnsPortal.MessageContents.zen?HeaderClass='+this.headerClass+'&HeaderId='+this.selectedId+(showJSON ? '&FORMAT=JSON' :(showRaw ? '&RAW=1' : ''))));
 	else 
 		alert($$$Text('You must select a message before you can view its contents.'));
}

/// Handle the client-side rendering the of the right hand pane.
ClientMethod layoutTabGroup() [ Language = javascript ]
{
/// This is primarily due to IE as it shrinks the contents div without this intervention.
/// The function only adjusts the size of the tab group is not hidden.
	if (!this.detailsHidden) {
		var detailsTabGroup = zen('detailsTabGroup');
		var tabsDiv = detailsTabGroup.getEnclosingDiv();
		var frame = zen('contentFrame');
		var svgTrace = zen('svgTrace');

		var hgt = this.getContentAreaHeight() - 20;

		var detailsPanel = zen('detailsPanel');
		var detailsDiv = detailsPanel.getEnclosingDiv();
		var paneWidth = detailsDiv.offsetWidth;
		var detailsStyleWidth = parseInt(detailsDiv.style.width,10);
		// if IE's rendering is stuck with a major difference between the declared style and the offset, pick the style value.
		if ((!isNaN(detailsStyleWidth)) && (Math.abs(paneWidth - detailsStyleWidth) >= 20) && zenIsIE && (!zenIsHTML5)) {
			paneWidth = detailsStyleWidth;
		}

		var tabBar = detailsTabGroup.getTabBarElement();
		hgt = hgt - tabBar.offsetHeight;
		tabsDiv.style.height = hgt + 'px';

		// prevent IE resize logic
		detailsTabGroup.ieResizeBody = function() { return; };

		var tabsWidth = paneWidth - 5;
		detailsTabGroup.setBodySize(hgt, tabsWidth);
		tabsDiv.style.width = tabsWidth + 'px';
		if (frame) {
			var frameWidth = (tabsWidth - 5) - (!zenIsGecko * 5) - (zenIsHTML5 * 15); // IE and Chrome introduce scrollbars with the extra 5px
			frame.setProperty('width', frameWidth+ 'px');
			var fullContentDiv = zen('fullContent').getEnclosingDiv();
			var frameHeight = hgt - 14 - fullContentDiv.offsetHeight;
			frame.setProperty('height', frameHeight + 'px');
		}

		if (svgTrace) {
			var traceLinkDiv = zen('traceLink').getEnclosingDiv();
			var svgHeight = hgt - 5 - traceLinkDiv.offsetHeight;
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
}

/// Callback from the Trace SVG onSVGLoad() callback.
/// The callback is used to ensure that we have the loaded SVG diagram available 
/// before we attempt to resize the diagram or highlight the currently selected message.
ClientMethod onTraceSVGLoad() [ Language = javascript ]
{
	zenPage.scaleSVGTrace();
	
	var svgTrace = zen('svgTrace');
	if (svgTrace && svgTrace.svgWindow && svgTrace.svgWindow.svgPage) {
		var svgDoc = svgTrace.getSVGDocument();
		if (svgDoc) {
			var truncateMsg = document.getElementById('traceTruncated');
			if (truncateMsg) {
				var isTruncated = svgDoc.getElementById('traceTruncated');
				if (isTruncated && (isTruncated.getAttribute('truncated')=='1')) {
					truncateMsg.innerHTML = $$$Text('Note: Trace has been truncated.');
				}
				else {
					truncateMsg.innerHTML = '';
				}
			}
			if ((zenPage.selectedId > 0) && svgTrace.svgWindow.svgPage.selectItem) {
				var svgObj = svgDoc.getElementById(zenPage.selectedId);
				var lineId = '';
				var rectId = '';
				if (svgObj) {
					lineId = svgObj.getAttribute('lineId');
					rectId = svgObj.getAttribute('rectId');
				}
				svgTrace.svgWindow.svgPage.selectItem(null,'message',rectId,zenPage.selectedId,'',lineId);
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
				var sync = svgTrace.svgRoot.setAttribute('preserveAspectRatio', 'xMinYMin meet');
				sync = svgTrace.svgRoot.setAttribute('viewBox', '0 0 '+ svgWidth + ' ' + svgHeight);
			}
		}
	}
	return true;
}

/// Make sure we check for warnings and update the filter from
/// the server after a search is executed.
ClientMethod onAfterSearch() [ Language = javascript ]
{
	this.invokeSuper('onAfterSearch',arguments);
	
	// ensure we have the correct search based on the current search
	var sync = zen('searchFilter').reloadContents();
	this.updateFormFromFilter();
	this.drawExtendedCriteria();
	var filter = this.getFilter();
	if (filter && filter.Terms) {
		var extendedExpando = zen('extendedCriteria');
		var isExpanded = extendedExpando.getExpanded();
		if ((filter.Terms.length > 0) && !isExpanded) {
			extendedExpando.setExpanded(true);
		}
		else if ((filter.Terms.length == 0) && isExpanded) {
			extendedExpando.setExpanded(false);
		}
	}
	this.checkSearchWarnings();
}

/// Check whether any warnings are present after trying to execute a search.
ClientMethod checkSearchWarnings() [ Language = javascript ]
{
	this.ignoreSearchWarnings = false;
	if (this.searchWarnings && (this.searchWarnings.length > 0)) {
		var message = $$$Text('The current search criteria may have a problem.') + '\n';
		for (var i=0; i<this.searchWarnings.length; i++) {
			message += '\n' + this.searchWarnings[i];
		}
		message += '\n\n' + $$$Text('Do you want to perform the search anyway?');
		if (confirm(message)) {
			this.ignoreSearchWarnings = true;
			this.doSearch();
		}
	}
}

/// Callback to indicate the user clicked on an item.
/// Here we simply make sure that the tab content is up to date.
ClientMethod onSelectItem() [ Language = javascript ]
{
	this.onTabChange();
}

/// Notify subclass that a search is being executed.
ClientMethod onSearchHandler() [ Language = javascript ]
{
	var changed = this.updateFilterFromForm();
	if (changed || (this.VirtualKey == 0)) {
		var sync = zenPage.submitFilterUpdate();
	}
	this.searchWarnings = [];
}

/// Load a named search from the server.
ClientMethod loadSearch(searchName, run) [ Language = javascript ]
{
	if (searchName == null) {
		return;
	}
	var resetParm = zen('resetSearch');
	var savedParm = zen('namedSearch');
	if (searchName == '') {
		resetParm.setProperty('value',true);
		savedParm.setProperty('value','');
	}
	else {
		resetParm.setProperty('value','');
		savedParm.setProperty('value',searchName);
	}
	this.currentSearch = searchName;
	zen('savedList').setValue(searchName);
	var sync = zen('searchFilter').reloadContents();
	resetParm.setProperty('value','');
	this.updateFormFromFilter();
	var filter = zenPage.getFilter();
	this.drawExtendedCriteria();
	if (filter && filter.Terms) {
		var extendedExpando = zen('extendedCriteria');
		var isExpanded = extendedExpando.getExpanded();
		if ((filter.Terms.length > 0) && !isExpanded) {
			extendedExpando.setExpanded(true);
		}
		else if ((filter.Terms.length == 0) && isExpanded) {
			extendedExpando.setExpanded(false);
		}
	}
	if (run) {
		this.doSearch();
	}
}

/// Delete an existing saved search.
ClientMethod deleteSearch(searchName) [ Language = javascript ]
{
	if ((searchName == '') || !searchName) {
		alert($$$Text('No search selected.'));
		return;
	}
	var doDelete = confirm($$$FormatText($$$Text("Are you sure you want to delete saved search '%1'?"), searchName));
	if (!doDelete) {
		return;
	}
	
	var ok = zenPage.DoSearchDelete(searchName);
	if (ok != '') {
		alert(ok);
		return;
	}
	else {
		var sync = zen('savedList').refreshContents(true);
		alert($$$Text('Search successfully deleted.'));
	}
}

/// Save the current search criteria to the server.
ClientMethod saveSearch(searchName, isNew) [ Language = javascript ]
{
	if ((!searchName) || (searchName == '')) {
		if (!zen('searchSaveAsGroup').getHidden()) {
			searchName = zen('saveAsName').getValue();
			isNew = true;
		}
		else {
			searchName = zen('savedList').getValue();
			isNew = false;
		}
		if ((!searchName) || (searchName == '')) {
			this.toggleSaveAs(true);
			return;
		}
	}
	if (searchName.length > 128) {
		alert($$$Text('Name cannot exceed 128 characters'));
		return;
	}
	isNew = !!isNew;
	var exists = false;
	var list = zen('savedList');
	var select = list.findElement('control');
	
	if (select && select.options && (select.options.length > 0)) {
		for (var i = 0; i < select.options.length; i++) {
			var opt = select.options[i];
			if (opt && opt.value && (opt.value == searchName)) {
				exists = true;
				break;
			}
		}
	}
	if (exists) {
		if (searchName == zenPage.currentSearch) {
			var text =$$$Text("Are you sure you want to update the saved search '%1'?");
		}
		else {
			var text = $$$Text("Saved Search '%1' already exists. Overwrite?");
		}
		var overwrite = confirm($$$FormatText(text, searchName));
		if (!overwrite) {
			return;
		}
		if (isNew) {
			isNew = false;
		}
	}
	var changed = this.updateFilterFromForm(true);
	if (changed) {
		var sync = this.submitFilterUpdate();
	}
	var ok = this.DoSearchSave(searchName, isNew);
	if (ok == '-1') {
		// search exists, so refresh the list from the server and try again, where we should get the overwrite prompt
		var sync = zen('savedList').refreshContents(true);
		this.saveSearch(searchName, true);
		return;
	}
	else if (ok != '') {
		alert(ok);
		return;
	}
	var sync = zen('savedList').refreshContents(true);
	zen('savedList').setValue(searchName);
	this.toggleSaveAs(false);
}

/// Toggle the display of the "Save As" controls and the list controls.
ClientMethod toggleSaveAs(show) [ Language = javascript ]
{
	var saveAsGroup = zen('searchSaveAsGroup');
	var listGroup = zen('searchSaveGroup');
	if (saveAsGroup && listGroup) {
		var saveAs = zen('saveAsName');
		saveAs.setValue('');
		
		listGroup.setHidden(show);
		saveAsGroup.setHidden(!show)
	}
}

ClientMethod doResend() [ Language = javascript ]
{
	if (!this.canResend) {
		alert(this.msgNotPermitted);
		return false;
	}
	
	// Get the values and find out how many
	var tab = this.getResultsTable();
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) val += ',';
			val += sel[i];
			found++;
		}
	}

	// Use the values
	if (found == 0) alert($$$Text('Please select one or more messages to resubmit.'));
	else {
		var url = '';
		if // Ask about sending more than are shown on the page
		   ((found == tab.maxRows) && 
			(tab.rowCount.indexOf('+') > 0) && 
			(confirm($$$Text('More messages match your search criteria than appear here. ') + '\n' +
							$$$Text('If you want to resend all the messages that match your criteria, including those not shown on this page, click OK.') + '\n' +
							$$$Text('To resend only your selected messages, click Cancel.')))) {
			url = zenPage.getResendURL("",true); // 1000 is the maximum we'll display, but there might be more to resend
		}
		else { // Resend selected messages only
			var searchKey = zenPage.SaveResendIDs(val); // there are not more so we'll set up all of them now
			url = zenPage.getResendURL(searchKey); // use specific ids
		}
		zenPage.gotoPage(url);
	}
}

/// Use current values of the search criteria and/or selected values to create a URL for the message resend page.
ClientMethod getResendURL(key, useFilter) As %String [ Language = javascript ]
{
	if (!this.searchCriteria) {
		var searchForm = this.getSearchForm();
		this.searchCriteria = searchForm.getValuesAsObject();
	}
	var url = this.resendPage + '?';
	if (key.length > 0) { // we are only resending specific IDs, which are stored in the database under a key
		url += 'KEY=' + key;
	}
	else if (useFilter) { // we are going to search for all keys that match current criteria
		url += 'FILTER=1';
	}
	if (this.searchCriteria.SortOrder.length > 0) {
		url += '&SORT=' + this.searchCriteria.SortOrder;
	}
	return url;
}

/// Save ID values for Resend.
ClassMethod SaveResendIDs(idString As %String) As %String [ ZenMethod ]
{
	// Move IDs into IRIS.Temp
	Set n = 0
	Set ctKey=$I(^IRIS.Temp.ResendIDs) 
	If $IsObject(idString) { // Handle case where idString is converted to a Stream
		Set idString.LineTerminator = ","
		While 'idString.AtEnd {
			Set msgid = idString.ReadLine(,.tStatus)
			If $$$ISERR(tStatus) Quit
			Continue:""=msgid
			Set ^IRIS.Temp.ResendIDs(ctKey, msgid) = ""
			Set n = n + 1
		}
	}
	Else {
		Set tCount = $L(idString,",")
		For i=1:1:tCount {
			Set msgid = $P(idString,",",i)
			Continue:""=msgid
			Set ^IRIS.Temp.ResendIDs(ctKey, msgid) = ""
			Set n = n + 1
		}
	}
	Set ^IRIS.Temp.ResendIDs(ctKey) = n
	Quit ctKey
}

ClientMethod doExport() [ Language = javascript ]
{
}

/// Write out contents of details panel.
/// <var>pID</var> is the message id.
Method DrawDetailsContent(pID As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawItemDetails(pID,..headerClass)
}

/// Write out contents of body details panel.
/// <var>pHeaderID</var> is the message id.
Method DrawBodyInfo(pHeaderID As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawBodyInfo(pHeaderID,..headerClass)
}

/// Write out the links to show the full contents of a message.
ClassMethod DrawFullContentLinks(pSeed As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawFullContentLinks()
}

/// Server side method to actually save a named search.
Method DoSearchSave(pSearchName As %String, pIsNew As %Boolean = 0) As %String [ ZenMethod ]
{
	Set tStatus = $$$OK
	Set tCollision = 0
	Try {
		Set tStatus = $classmethod(..filterClass,"LoadFromVirtualSession",..VirtualKey,.tFilter)
		If $$$ISERR(tStatus) Quit
		
		If pIsNew && $classmethod(..savedSearchClass,"%ExistsId",pSearchName) { // check it doesn't already exist
			Set tCollision = 1
			Quit
		}
		
		If $classmethod(..savedSearchClass,"%ExistsId",pSearchName) {
			Set tSearch = $classmethod(..savedSearchClass,"%OpenId",pSearchName)
		}
		Else {
			Set tSearch = $classmethod(..savedSearchClass,"%New")
			Set tSearch.Name = pSearchName
		}
		Set tSearch.Filter = tFilter
		Set tStatus = tSearch.%Save()
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..SetSavedSearch(pSearchName)
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Quit $zconvert($System.Status.GetErrorText(tStatus),"O","JS")
	}
	If tCollision {
		Quit -1
	}
	Quit ""
}

/// Server side method to actually delete a named search.
Method DoSearchDelete(pSearchName As %String) As %Status [ ZenMethod ]
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = $classmethod(..savedSearchClass,"%DeleteId",pSearchName)
		If $system.Status.Equals(tStatus, $$$DeleteObjectNotFound) {
			Set tStatus = $$$OK
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Quit $zconvert($system.Status.GetErrorText(tStatus),"O","HTML")
	}
	Quit ""
}

/// Send the Filter to the server.
Method SubmitFilter(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, ByRef pObject As %RegisteredObject, Output pResponse As %RegisteredObject) As %Status
{
	Set tStatus = $$$OK
	Try {
		If $IsObject(pObject) && pObject.%IsA(..filterClass) {
			Set tVirtualKey = ..VirtualKey
			Set tStatus = pObject.SaveToVirtualSession(.tVirtualKey)
			Set ..VirtualKey = tVirtualKey
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Open the SearchCriteria popup for a criterion.
ClientMethod editCriterion(index) [ Language = javascript ]
{
	if (this._inSearch) {
		alert($$$Text('Unable to change criterion during search'));
		return;
	}
	var uri = zenLink(this.criteriaDialog);
	var filter = zenPage.getFilter();
	var criterion = filter.Terms[index];
	if (criterion) {
		var parms = {
			PROPTYPE: criterion.Type,
			PROPCLASS: criterion.SourceClass,
			DISABLED: (criterion.Disabled ? 1 : 0)
		};
		filter._currentCriterion = index;
		filter._newCriterion = false;
		zenLaunchPopupWindow(uri,this.addPopupSuffix('SearchCriteria'),'status,scrollbars,resizable=yes,width=850,height=600',parms);
	}
}

/// Shift the Term at <var>index</var> one position forward or back in the array,
/// with <var>direction</var> being specified as either 'up' or 'down'.
ClientMethod shiftTerm(index, direction) [ Language = javascript ]
{
	var filter = zenPage.getFilter();
	var term = filter.Terms[index];
	if (term) {
		filter.Terms.splice(index, 1);
		if (direction == 'up') {
			filter.Terms.splice(index - 1, 0, term);
		}
		else if (direction == 'down') {
			filter.Terms.splice(index + 1, 0, term);
		}
		this.updateSearchState(true);
	}
}

/// Client accessor for the Filter current object.
ClientMethod getFilter() [ Language = javascript ]
{
	var json = zen('searchFilter');
	var filter = json.getContentObject();
	if (filter) {
		filter._zenRoot = this;
	}
	return filter;
}

ClientMethod toggleCriterion(index, enabled) [ Language = javascript ]
{
	var filter = this.getFilter();
	if (filter && filter.Terms) {
		var criterion = filter.Terms[index];
		if (criterion) {
			criterion.Disabled = !enabled;
			this.updateSearchState(true);
		}
	}
}

/// Wrapper method to ensure the client state correctly reflects the current criteria, including
/// marking the current search as NOT a saved one.
ClientMethod updateSearchState(submitUpdate) [ Language = javascript ]
{
	zen('namedSearch').setProperty('value','');
	zen('savedList').setValue('');
	if (submitUpdate) this.submitFilterUpdate();
	this.drawExtendedCriteria();
}

/// Client-side method to render the extended criteria expando.
ClientMethod drawExtendedCriteria() [ Language = javascript ]
{
	var extendedDiv = zen('criteria');
	if (extendedDiv) {
		var filter = zenPage.getFilter();
		var html = '<table id="extendedCriteriaTable" border="0" cellspacing="0">';
		for (var i = 0; i < filter.Terms.length; i++) {
			var criterion = filter.Terms[i];
			html += '<tr id="criterion_'+i+'">';
			var rowspan = '';
			if (criterion.Conditions && (criterion.Conditions.length > 1)) {
				rowspan = ' rowspan="'+((criterion.Conditions.length*2)-1)+'"';
			}
			
			var disabledClass = (criterion.Disabled ? ' criterionDisabled' : '');
			var linkHTML = '<td class="criterionStart criterionRight criterionTitle' + disabledClass + (criterion.Type == 'OR' ? ' criterionEnd' :'') + '" colspan="2"><nobr>';
			linkHTML += '&nbsp;<input type="checkbox" id="critCheck_'+i+'" title="'+ (!criterion.Disabled ? ($$$Text('Disable criterion') + '" checked="checked') : $$$Text('Enable criterion')) + '" onchange="zenPage.toggleCriterion('+i+',this.checked);" />';
			linkHTML += '&nbsp;<img class="critLink" width="16px" src="deepsee/up_16.png" title="' + $$$Text('Move this criterion up') + '" onclick="zenPage.shiftTerm('+i+',\'up\');" />';
			linkHTML += '&nbsp;<img class="critLink" width="16px" src="deepsee/down_16.png" title="' + $$$Text('Move this criterion down') + '" onclick="zenPage.shiftTerm('+i+',\'down\');" />';
			linkHTML += '&nbsp;<img class="critLink" width="16px" src="portal/table_properties_48.gif" title="' + $$$Text('Edit this criterion') + '" onclick="zenPage.editCriterion('+i+'); return false;" />';
			linkHTML += '&nbsp;<img class="critLink" width="16px" src="deepsee/close_a_16.png" title="' + $$$Text('Remove this criterion') + '" onclick="zenPage.removeCriterion('+i+'); return false;" />';
			linkHTML += '</nobr></td>';
			if (criterion.Type == 'OR') {
				rowspan = '';
				html += '<td class="criterionOR criterionStart criterionEnd criterionLeft' + disabledClass + '" colspan="2">OR</td>';
				html += linkHTML;
			}
			else {
				html += '<td class="criterionStart criterionLeft criterionTitle' + disabledClass + '" colspan="2">' + zenEscapeHTML(criterion.SourceClass) + '</td>';
				html += linkHTML;
				
				html += '</tr>';
				if (!criterion.Conditions) {
					html += '<td colspan="5">&lt;no conditions&gt;</td>';
				}
				else {
					for (var j = 0; j < criterion.Conditions.length; j++) {
						var condition = criterion.Conditions[j];
						if (j > 0) {
							var joinVal = (condition.JoinOp == 'IF' ? '&nbsp;' : (condition.DisplayOnly ? 'AND' : condition.JoinOp));
							html += '<tr class="joinRow"><td class="joinCell' + disabledClass + '" colspan="4">' + joinVal + '</td></tr>';
						}
						html += '<tr class="conditionRow' + disabledClass + '">';
						var extraClass = disabledClass;
						if (j == criterion.Conditions.length - 1) {
							extraClass += ' criterionEnd';
						}
					
						if (condition.DisplayOnly) {
							html += '<td class="criterionLeft criterionRight conditionProp'+ extraClass +'" colspan="4">[' + $$$Text('Display') + ']&nbsp;' + (condition.Prop == '' ? '&nbsp;' : zenEscapeHTML(condition.Prop)) + '</td>';
						}
						else {
							html += '<td class="criterionLeft'+ extraClass +'">&nbsp</td>';
							html += '<td class="conditionProp'+ extraClass +'">' + (condition.Prop == '' ? '&nbsp;' : zenEscapeHTML(condition.Prop)) + '</td>';
							html += '<td class="'+ extraClass +'">' + condition.Op + '</td>';
							html += '<td class="criterionRight'+ extraClass +'">' + (condition.OpVal == '' ? '\'\'' : zenEscapeHTML(condition.OpVal)) + '</td>';
						}
					}
				}
			}
			html += '</tr>';
		}
		html += '</table>';
		extendedDiv.setProperty('content',html);
	}
	zenPage.onlayoutHandler();
}

/// Add an OR criterion.
ClientMethod addOR() [ Language = javascript ]
{
	if (this._inSearch) {
		alert($$$Text('Unable to change criterion during search'));
		return;
	}
	var filter = zenPage.getFilter();
	var orTerm = new zenPage.Term('OR');
	filter.Terms.push(orTerm);
	this.updateSearchState(true);
}

/// Add a criterion and open the Search Criteria editor for the new object.
ClientMethod addCriterion() [ Language = javascript ]
{
	if (this._inSearch) {
		alert($$$Text('Unable to change criterion during search'));
		return;
	}
	var uri = zenLink(this.criteriaDialog);
	var parms = new Object();
	if (zenPage._lastCriterionType != null) {
		parms.PROPTYPE = zenPage._lastCriterionType;
	}
	var filter = zenPage.getFilter();
	filter._currentCriterion = filter.Terms.length;
	filter._newCriterion = true;
	filter.Terms[filter._currentCriterion] = new zenPage.Term('Header', this.headerClass);
	
	zenLaunchPopupWindow(uri,this.addPopupSuffix('SearchCriteria'),'status,scrollbars,resizable=yes,width=850,height=600',parms);
}

/// Remove a criterion from the page.
ClientMethod removeCriterion(index) [ Language = javascript ]
{
	if (this._inSearch) {
		alert($$$Text('Unable to change criterion during search'));
		return false;
	}
	var filter = zenPage.getFilter();
	if (filter && filter.Terms && filter.Terms[index] && confirm($$$Text('Do you wish to delete this criterion?'))) {
		var rem = filter.Terms.splice(index, 1);
		this.updateSearchState(true);
		return true;
	}
	return false;
}

/// Update the current Filter based on the form's contents. Extended criteria are saved separately.
ClientMethod updateFilterFromForm(updateSearchCriteria) [ Language = javascript ]
{
	if (updateSearchCriteria) {
		var form = this.getSearchForm();
		zenPage.searchCriteria = form.getValuesAsObject();
	}
	var changed = false;
	var filter = zenPage.getFilter();
	if (filter) {
		for (var prop in filter) {
			if ((zenPage.searchCriteria[prop] != null) && (zenPage.searchCriteria[prop] != filter[prop])) {
				changed = true;
				filter[prop] = zenPage.searchCriteria[prop];
			}
		}
	}
	return changed;
}

/// Update the form on the page based on an updated Filter object.
ClientMethod updateFormFromFilter() [ Language = javascript ]
{
	var filter = this.getFilter();
	var form = this.getSearchForm();
	if (filter && form) {
		var obj = new Object();
		for (var val in filter) {
			if ((val.substring(0,1) != '_') && (val != 'Terms')) {
				obj[val] = filter[val];
			}
		}
		form.setValuesByName(obj);
	}
}

/// Send the current Filter to the server so it can be saved.
ClientMethod submitFilterUpdate() [ Language = javascript ]
{
	var json = zen('searchFilter');
	if (json) {
		var ok = json.submitContent('submit');
		if (!ok && (json.error != '')) {
			alert(json.error);
		} 
	}
}

/// Subclass need to include the case "switchNamespace" if it is enabling "Switch" next to namespace.<br>
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'SearchCriteria':
			if (value) { // values were changed in the dialog
				this.updateSearchState(true);
			}
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
		case 'Export':
			break;
	}
	return true;
}

/// Adjust sizes of components on the page.
/// The primary purposes of this function are to ensure that the details pane
/// is sized correctly based on whether the tab group is hidden, and to
/// correctly update the expander text and the contents of the tab group.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.invokeSuper('onlayoutHandler',arguments);

		this.layoutTabGroup();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

/// Ensure that tab behaviour is initialised correctly.
ClientMethod onloadHandler() [ Language = javascript ]
{
	var key = window.sessionStorage.getItem('EnsVirtualSessionKey');
	this.VirtualKey = (key && (""!=key) && !isNaN(key) && (parseInt(Number(key),10)==key)) ? key : 0;
	var statusText = zenPage.SetSearchCriteria();
	if (statusText != '') {
		alert(statusText);
		return false;
	}
	var sync = zen('savedList').refreshContents(true);
	var sync = zen('searchFilter').reloadContents();
	this.invokeSuper('onloadHandler',[]);
	if (zenIsIE) { // avoid IE resize bug
		var results = zen('resultsTable');
		if (results) {
			results.packRowsIE = function() { return null; };
		}
	}
	// Ensure that tab content is correctly initialised
	this.selectedId = -1;
	this.onTabChange();
	
	var filter = zenPage.getFilter();
	if (!filter) {
		var json = zen('searchFilter');
		filter = new zenPage.Filter();
		json.setContentObject(filter);
	}
	if (filter.Terms.length > 0) {
		zenPage.drawExtendedCriteria();
		if (!zen('extendedCriteria').getExpanded()) {
			zen('extendedCriteria').setExpanded(true);
		}
	}
	this.updateFormFromFilter();
	if (this.inFirstLoad && !this.isDefaultFilter) {
		// If reloading previous search from session, show message
		var table = zenPage.getResultsTable();
		var msg = $$$Text('Click Search to run current filters or Reset to start over');
		table.getEnclosingDiv().innerHTML = '<div style="padding:10px; font-style:italic; color:#606080;">' + msg + '</div>';
	} else if (this.isDefaultFilter) {
		this.doSearch();
	}
	this.ignoreSearchWarnings = false;
	this.inFirstLoad = false; // make sure search does execute when users click Search button
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	window.sessionStorage.setItem("EnsVirtualSessionKey",this.VirtualKey);
	return this.invokeSuper('onunloadHandler');
}

/// Client-side constructor for EnsPortal.MsgFilter.Term object.
ClientMethod Term(type, sourceClass, conditions) [ Language = javascript ]
{
	this._class = 'EnsPortal.MsgFilter.Term';
	this.Disabled = 0;
	this.Type = (type == null ? 'Header Field' : type);
	if (sourceClass == null) {
		if (this.Type == 'Header Field') {
			this.SourceClass = this.headerClass;
		}
		else {
			this.SourceClass = '';
		}
	}
	else {
		this.SourceClass = sourceClass;
	}
	if (conditions) {
		this.Conditions = conditions;
	}
	else {
		this.Conditions = new Array();
	}
	this.addCondition = function(condition) {
		this.Conditions[this.Conditions.length] = condition;
	}
}

/// Client-side constructor for EnsPortal.MsgFilter.Condition object.
ClientMethod Condition(joinOp, prop, op, opVal, displayOnly, term) [ Language = javascript ]
{
	this._class = 'EnsPortal.MsgFilter.Condition';
	this.JoinOp = (joinOp == null ? 'AND' : joinOp);
	this.Prop = (prop == null ? '' : prop);
	this.Op = (op == null ? '=' : op);
	this.OpVal = (opVal == null ? '' : opVal);
	this.DisplayOnly = (displayOnly ? true : false);
	if (term && term.addCondition) {
		term.addCondition(this);
	}
}

/// Client-side constructor for Filter object.
ClientMethod Filter() [ Language = javascript ]
{
	this._class = this.filterClass;
	this.Terms = new Array();
	
	this._zenRoot = zenPage;
}

/// Helper method to create a new Condition object. 
ClientMethod createCondition(joinOp, prop, op, opVal, displayOnly, term) [ Language = javascript ]
{
/// This is primarily
/// required by the Advanced Search popups -- IE is unhappy about directly invoking
/// constructors on the window.opener object.
	return new this.Condition(joinOp, prop, op, opVal, displayOnly, term);
}

/// Helper method to create a new Array object.
ClientMethod createArray() [ Language = javascript ]
{
/// This is primarily
/// required by the Advanced Search popups -- IE is unhappy about directly invoking
/// constructors on the window.opener object.
	return new window.Array();
}

/// Helper method to allow Search Criteria dialog to create clones of existing 
/// Term and Condition objects.
ClientMethod clone(object) [ Language = javascript ]
{
	if (!object) {
		return null;
	}
	if (object._class == 'EnsPortal.MsgFilter.Term') {
		var clone = new this.Term(object.Type, object.SourceClass);
		for (var i = 0; i < object.Conditions.length; i++) {
			var cond = this.clone(object.Conditions[i]);
			if (cond) {
				clone.Conditions[clone.Conditions.length] = cond;
			}
		}
		return clone;
	}
	else if (object._class == 'EnsPortal.MsgFilter.Condition') {
		return new this.Condition(object.JoinOp, object.Prop, object.Op, object.OpVal, object.DisplayOnly);
	}
	return null;
}

ClientMethod showQuery() [ Language = javascript ]
{
	var qh = zen('queryHistory');
	qh.reloadContents();
	var hist = qh.getContentObject();
	var html = [];
	if (this.searchQuery && (this.searchQuery != '')) {
		html.push('<h3>' + $$$Text('Current Query') + ':</h3>');
		html.push('<p>' + this.searchQuery + '</p>');
	}
	if (hist && hist.children && (hist.children.length > 0)) {
		html.push('<style type="text/css">');
		html.push('table.queryTable { border: 1px solid gray; border-collapse: separate; border-spacing: 0; border-radius: 5px; }');
		html.push('table.queryTable td, table.queryTable th { border-left: 1px solid gray; border-top: 1px solid gray; padding: 3px; }');
		html.push('table.queryTable tr td:first-child, table.queryTable tr th:first-child { border-left-width: 0px; }');
		html.push('table.queryTable tr:first-child th { border-top-width: 0px; }');
		html.push('.dateCell { white-space: nowrap; }');
		html.push('.centre { text-align: center; }');
		html.push('</style>');
		html.push('<h3>' + $$$Text('Recently Executed Queries') + '</h3>');
		html.push('<table class="queryTable">')
		html.push('<tr>');
		html.push('<th>' + $$$Text('Date') + '</th>');
		html.push('<th>' + $$$Text('Time') + '</th>');
		html.push('<th>' + $$$Text('Time to Execute') + ' / ' + $$$Text("Global References") + '</th>');
		html.push('<th>' + $$$Text('Time to Close') + ' / ' + $$$Text("Global References") + '</th>');
		html.push('<th>' + $$$Text('Query Text') + '</th>');
		html.push('</tr>');
		for (var i = 0; i < hist.children.length; i++) {
			var query = hist.children[i];
			html.push('<tr>');
			var qDate = '&nbsp;';
			var qTime = '&nbsp;';
			if (typeof query.time == 'string') {
				var pieces = query.time.split(' ');
				qDate = pieces[0];
				if (pieces.length > 0) qTime = pieces[1];
			}
			html.push('<td class="dateCell">' + qDate + '</td>');
			html.push('<td class="centre">' + qTime + '</td>');
			html.push('<td class="centre">' + query.executeTime + ' / ' + query.executeRefs + '</td>');
			html.push('<td class="centre">' + query.closeTime + ' / ' + query.closeRefs  + '</td>');
			html.push('<td>' + query.sql + '</td>');
			html.push('</tr>');
		}
		html.push('</table>');
	}
	else {
		html.push('<p>' + $$$Text('No query history found.') + '</p>');
	}
	this._helpText = html.join('');
	var link = zenLink('EnsPortal.Dialog.TooltipPopup.zen');
	var parms = {
		"LOCALIZEDNAME": $$$Text('Query Text'),
		"KEY": $$$Text('The most recently executed query text')
	};
	zenLaunchPopupWindow(link,'','scrollbars,resizable',parms);
}

ClassMethod GetAssistantClass() As %String [ CodeMode = expression ]
{
$get(^EnsPortal.Settings("MessageViewer","AssistantClass"),"EnsPortal.MsgFilter.Assistant")
}

ClassMethod GetQueryHistory(ByRef pParms, Output pMetaData, Output pData) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set pMetaData = $listbuild("time","sql","executeTime","closeTime","executeRefs","closeRefs")
		Set tAssistantClass = ..GetAssistantClass()
		Set tStatus = $classmethod(tAssistantClass,"GetQueryHistory",.tQueries)
		If $$$ISERR(tStatus) Quit
		For i=1:1:tQueries {
			Set pData(i) = tQueries(i)
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

ClientMethod searchIfValidPageSize(pageSize) [ Language = javascript ]
{
	var pageSizeCheck=parseInt(pageSize,10);
	if (isNaN(pageSizeCheck)||(pageSizeCheck<1)) {
		alert($$$Text('Invalid Page Size')+' : ' + pageSize + '\n' + $$$Text('Resetting to 100'));
		zen(this.pageSizeId).setProperty('value','100');
	} else {
		if (pageSizeCheck!=pageSize) {zen(this.pageSizeId).setProperty('value',pageSizeCheck);}
		zenPage.doSearch(); 
	}
}

}
