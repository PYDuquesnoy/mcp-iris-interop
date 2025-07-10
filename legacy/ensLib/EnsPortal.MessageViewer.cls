/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Message viewer page for portal.
Class EnsPortal.MessageViewer Extends EnsPortal.Template.filteredViewer [ System = 4 ]
{

/// Name of this page.
Parameter PAGENAME = "Message Viewer";

/// User needs USE permissions on the %Ens_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MessageHeader:USE";

/// Name of column in query that supplies ID values.
Parameter VALUECOLUMN = "ID";

/// Indicate if can cancel search. This defines whether tempPortalNode is set.
Parameter CANCANCELSEARCH As BOOLEAN = 1;

/// Indicate if ought to create tempPortalNode when page created. Used by Cancel feature for example.
Parameter SETUPTEMPPORTALNODE As BOOLEAN = 1;

/// Flag to indicate whether the user is permitted to view the message trace tab.
Property canViewTrace As %ZEN.Datatype.boolean;

/// Flag to indicate whether the user is permitted to view body contents.
Property canViewContents As %ZEN.Datatype.boolean;

Property matchSourceOrTarget As %ZEN.Datatype.string(ZENURL = "SOURCEORTARGET");

Property msgViewTraceHover As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("View Full Trace including Events, ACKs, IO entries and message contents")} ];

/// Flag to indicate whether a user may resend messages.
Property canResend As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageResend","USE")} ];

/// Flag to indicate whether the user is permitted to export body contents.
Property canExportContents As %ZEN.Datatype.boolean;

XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tablePane id="resultsTable"
    cellSpacing="2"
	OnCreateResultSet="CreateResultSet"
	useSnapshot="false"
	showZebra="true"
	multiSelect="true"
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
<column header="ID" colName="ID" 
	   title="Message ID" />
<column header="Time Created" colName="TimeCreated" 
	   title="Date and time the message was created" />
<column header="Session" colName="Session" 
	   title="Session in which the message was sent"
	   link=" "
    	OnDrawCell="DrawSessionCell" />
<condition colName="Session" predicate="EQ" value="{ID}" cellStyle="background-color: lightgreen;" />
<column header="Status" colName="Status" 
	   title="Last message status"
	    OnDrawCell="DrawStatusCell" />
<column header="Error" colName="Error" 
	   title="Indicates whether an error occurred" />
<column header="Source" colName="Source" 
	   title="Configuration item that sent the message" />
<column header="Target" colName="Target" 
	   title="Configuration item that the message was sent to" />
</tablePane>
</pane>
}

/// Server-side method to write out localized content for the Status column
Method DrawStatusCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Write $Case(%query(name),
		"Completed": $$$Text("Completed"),
		"Error": $$$Text("Error"),
		"Created": $$$Text("Created"),
		"Queued": $$$Text("Queued"),
		"Delivered": $$$Text("Delivered"),
		"Discarded": $$$Text("Discarded"),
		"Suspended": $$$Text("Suspended"),
		"Deferred": $$$Text("Deferred"),
		"Aborted": $$$Text("Aborted"),
		: ""
		)
	Quit $$$OK
}

XData jsonPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<jsonProvider id="searchFilter" OnGetTargetObject="LoadFilter"
	OnSubmitContent="SubmitFilter" targetClass="EnsPortal.MsgFilter.Filter">
<parameter id="resetSearch" paramName="Reset" value="" />
<parameter id="namedSearch" paramName="SavedSearch" value="" />
</jsonProvider>	
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Message Viewer")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Message Viewer","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set n = 0
	Set pCommands($I(n)) = $LB("searchButton",$$$Text("Search"),$$$Text("Search for messages using the current criteria"),"zenPage.doSearch(); return false;")
	Set:..#CANCANCELSEARCH pCommands($I(n)) = $LB("cancelButton",$$$Text("Cancel"),$$$Text("Cancel current search"),"zenPage.cancelSearch(); return false;")
	Set pCommands($I(n)) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the search criteria to their default values"),"zenPage.loadSearch('',true);")
	Set pCommands($I(n)) = $LB("btnResend",$$$Text("Resend"),$$$Text("Resend all selected messages"),"zenPage.doResend(); return false;")
	Set pCommands($I(n)) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false); return false;")
	Set pCommands($I(n)) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true); return false;")
	Set pCommands($I(n)) = $LB("btnExport",$$$Text("Export"),$$$Text("Export all selected messages to browser"),"zenPage.doExport(); return false;")
	If $get(^Ens.Debug("UtilEnsMessages","sql")) {
		Set pCommands($I(n)) = $LB("showQueryButton",$$$Text("Show Query"),$$$Text("Show the current query text"),"zenPage.showQuery(); return false;")
	}
	If $get(^Ens.Config("EnsMsgFilterForm","ShowDupsGapsLates")) {
		Set pCommands($I(n)) = $LB("btnDups",$$$Text("Show Dups"),$$$Text("Show Duplicate ControlID messages"),"zenPage.sequenceSearch('Dups'); return false;")
		Set pCommands($I(n)) = $LB("btnGaps",$$$Text("Show Gaps"),$$$Text("Show messages before and after a message gap"),"zenPage.sequenceSearch('Gaps'); return false;")
		Set pCommands($I(n)) = $LB("btnLates",$$$Text("Show Lates"),$$$Text("Show messages that arrived out of sequence too late"),"zenPage.sequenceSearch('Lates'); return false;")
	}

	Quit $$$OK
}

/// Get the contents of the link menu in the table.<br>
Method %OnGetTableLinkMenu(Output pMenu)
{
	Set cmd(1) = $$$TextHTML("Trace")
	Set title(1) = $$$TextHTML("Go to the Visual Trace page for this session")
	Set pMenu(1) = $LB(cmd(1),title(1),"zenPage.showTrace")
	Quit
}

/// Get the contents of the Details' link menu.<br>
Method %OnGetDetailsLinkMenu(Output pMenu2)
{
	// $LB(caption,title,script)
	Set cmd(1) = $$$TextHTML("Contents")
	Set title(1) = $$$TextHTML("Show contents for this message, if available")
	Set pMenu2(1) = $LB(cmd(1),title(1),"zenPage.showContents")
	Set cmd(2) = $$$TextHTML("Trace")
	Set title(2) = $$$TextHTML("Go to the Visual Trace page for this session")
	Set pMenu(2) = $LB(cmd(2),title(2),"zenPage.showTrace")
	Quit
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

XData svgTracePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<svgFrame id="svgTrace" svgPage="EnsPortal.SVG.VisualTrace" width="200" height="300">
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
			this.searchCriteria.nextPageEndId = (currPageData.lastId - 1);
			this.searchCriteria.nextPageStartId = '';
		}
		else {
			this.searchCriteria.nextPageStartId = parseInt(currPageData.lastId,10) + 1;
			this.searchCriteria.nextPageEndId = '';
		}
	}
	else {
		var prevPageData = this._idIndex[currentPage - 1];
		if (this.searchCriteria.SortOrder == '2') {
			this.searchCriteria.nextPageStartId = prevPageData.lastId;
			this.searchCriteria.nextPageEndId = prevPageData.firstId;
		}
		else {
			this.searchCriteria.nextPageStartId = prevPageData.firstId;
			this.searchCriteria.nextPageEndId = prevPageData.lastId;
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

/// Show/hide the toggle buttons
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..canViewTrace = $system.Security.Check("%Ens_MessageTrace","USE")
	Set ..canViewContents = $system.Security.Check("%Ens_MessageContent","USE")
	Set ..canExportContents = $system.Security.Check("%Ens_MessageExport","USE")

	If '..canViewTrace {
		Set tTraceTab = ..%GetComponentById("traceContent")
		If $IsObject(tTraceTab) {
			Set tTraceTab.disabled = 1
			Set tTraceTab.title = $$$Text("You are not permitted to access this content.")_$$$Text("Contact your system administrator for access.")
		}
	}
	If '..canViewContents {
		Set tBodyTab = ..%GetComponentById("bodyDetails")
		If $IsObject(tBodyTab) {
			Set tBodyTab.disabled = 1
			Set tBodyTab.title = $$$Text("You are not permitted to access this content.")_$$$Text("Contact your system administrator for access.")
		}
		Set tContentsTab = ..%GetComponentById("bodyContents")
		If $IsObject(tContentsTab) {
			Set tContentsTab.disabled = 1
			Set tContentsTab.title = $$$Text("You are not permitted to access this content.")_$$$Text("Contact your system administrator for access.")
		}
	}
	Quit tSC
}

Method SetSearchCriteria() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tStatusText = ##super()
	If ("" '= tStatusText) {
		Quit tStatusText
	}

	If (..matchSourceOrTarget '= "") {
		Set ..currentSearch = ""
		Set tSC = ..NewSourceOrTargetFilter(..matchSourceOrTarget,.tFilter)
		If $IsObject(tFilter) {
			Set tCriteriaExpando = ..%GetComponentById("extendedCriteria")
			Set tCriteriaExpando.expanded = 1
			Set tKey = ..VirtualKey
			Do tFilter.SaveToVirtualSession(.tKey)
			Set ..VirtualKey = tKey
			If $IsObject(..searchCriteria) {
				Do ..searchCriteria.%Clear()
			}
			Set tSC = ..InitSearchCriteria()
			If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
		}
	}
	Quit $S($$$ISERR(tSC):$System.Status.GetErrorText(tSC),1:"")
}

/// Construct a special search with filter terms
Method NewSourceOrTargetFilter(pConfigItem As %String, pFilter As EnsPortal.MsgFilter.Filter) As %Status [ Internal ]
{
	#; Clear out all other criteria
	Set tFilter = $classmethod(..filterClass,"%New")
	Set tTerm=##class(EnsPortal.MsgFilter.Term).%New() ;tFilter.TermsNewInstance()
	Set tTerm.Type="Header", tTerm.SourceClass="Ens.MessageHeader"
	Set tCondition=##class(EnsPortal.MsgFilter.Condition).%New() ;tTerm.ConditionsNewInstance()
	Set tCondition.Prop="SourceConfigName", tCondition.Op="=", tCondition.OpVal=pConfigItem
	Set tSC = tTerm.Conditions.Insert(tCondition)  Quit:$$$ISERR(tSC) tSC
	Set tCondition=##class(EnsPortal.MsgFilter.Condition).%New() ;tTerm.ConditionsNewInstance()
	Set tCondition.Prop="TargetConfigName", tCondition.Op="=", tCondition.OpVal=pConfigItem, tCondition.JoinOp="OR"
	Set tSC = tTerm.Conditions.Insert(tCondition)  Quit:$$$ISERR(tSC) tSC
	Set tSC=tFilter.Terms.Insert(tTerm)  Quit:$$$ISERR(tSC) tSC
	Set tFilter.Type=tFilter.TypeDisplayToLogical("All") ; force All
	Set pFilter=tFilter
	#; Force the search to run automatically
	Set ..isDefaultFilter = 1
	Quit $$$OK
}

/// Helper method to trigger Sequence Manager searches.
ClientMethod sequenceSearch(searchType) [ Language = javascript ]
{
	var doSearch = false;
	switch (searchType) {
		case 'Dups':
		case 'Gaps':
		case 'Lates':
			doSearch = true;
		break;
	}
	if (doSearch) {
		var sequenceSearch = zen('SequenceManagerSearch');
		if (sequenceSearch) {
			sequenceSearch.setValue(searchType);
			zenPage.doSearch();
		}
	}
}

/// Get localized messages for the message contents pane.
ClassMethod GetContentMessages(messages As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Quit ##class(EnsPortal.MessageContents).GetMessages(messages)
}

ClientMethod doExport() [ Language = javascript ]
{
	if (!this.canExportContents) {
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
	if (found == 0) {
		alert($$$Text('Please select one or more messages to export.'));
	} else {
		var url = '';
		var searchKey = '';
		var parms = {};
		var moreThanOnePage = ((found == tab.maxRows) && (tab.rowCount.indexOf('+') > 0));
		var limitToOnePage = (moreThanOnePage && !zenPage.productionIsRunning());
		if (limitToOnePage && (!confirm($$$Text('More messages match your search criteria than appear here. ') + '\n\n' +
							$$$Text('Since the production is not running only the messages on this page can be exported now.') + '\n\n\n' +
							$$$Text('Press OK to continue export of messages from only this page.')))) return;
		if // Ask about exporting more than are shown on the page
			(moreThanOnePage && 
			(!limitToOnePage) &&
			(confirm($$$Text('More messages match your search criteria than appear here. ') + '\n\n' +
							$$$Text('The export will be generated and available for download from your Workflow Inbox.') + '\n\n\n' +
							$$$Text('Press Cancel to Export only the messages on this page now.')))) {
								
				/*	Save the search to a unique name that will be removed later
				 	either by canceling in the ExportMessages pop up 
				 	or after creation of the export file.

				 	Can do just the page of selected.

				 */
				var exportSavedSearch = "z_QueuedForExport_"+(Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15));
				/* Need to create a new one to ensure export to be created is as the user currently sees
				 	Note it is possible that more data might be available when the export is done
				 */
				var ok = this.DoSearchSave(exportSavedSearch, 1);
				if (ok == '-1') {
					/* search exists */
					alert($$$Text("Export save file name already exists. Please retry"));
					return;
				}
				else if (ok != '') {
					/* failed to save the search. Need to report */
					alert(ok);
					return;
				}
				 
				 parms = {
					SAVEDSEARCH: exportSavedSearch,
					QUANTITY: found
				};
			} else {
				/* Export selected messages only */
				searchKey = zenPage.SaveResendIDs(val); // there are not more so we'll set up all of them now
				parms = {
					KEY: searchKey,
					QUANTITY: found
				};
			}

		var uri = this.GetLink();
		zenLaunchPopupWindow(uri,this.addPopupSuffix('Export'),'status,scrollbars,resizable=yes,width=610,height=700',parms);

	}
}

Method productionIsRunning() As %Boolean [ ZenMethod ]
{
	Quit ##class(Ens.Director).IsProductionRunning()
}

Method GetLink() As %String [ ZenMethod ]
{
	Quit ..Link("EnsPortal.Dialog.ExportMessages.zen")
}

}
