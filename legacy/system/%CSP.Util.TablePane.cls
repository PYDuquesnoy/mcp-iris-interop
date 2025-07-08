/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>An AutoPage pane that displays a table based on a class query.
Class %CSP.Util.TablePane Extends (Pane, %ZEN.Portal.abstractRefreshable) [ ServerOnly = 1, System = 4 ]
{

/// Default localization domain used for column headers
Parameter COLUMNDOMAIN = "%UtilityColumns";

/// Default localization domain used for column headers help messages
Parameter COLUMNHELPDOMAIN = "%UtilityColumnHelp";

/// Default refresh rate (in milliseconds)
Parameter RefreshRate = 11000;

/// Default wrap limit
Parameter WrapLimit = 40;

/// Should this page display timing stats
Parameter SHOWSTATISTICS = 0;

/// Should this page display SQL Info
Parameter SHOWSQLINFO = 0;

/// Do not display filter box when there are no results
Parameter HIDEFILTERWHENEMPTY = 1;

/// Show advanced search form
Parameter SHOWSEARCHFORM = 0;

/// Name of the class query that provides info for the Table.<br>
/// This is a full name: e.g., "Package.Class:QueryName"
Property Query As %String(MAXLEN = 128);

/// Optional SQL query for this table.<br>
/// If present, supercedes the value in Query.
Property SQLQuery As %String(MAXLEN = 512);

/// An array of actions, indexed by column name in the query.
/// These are associated with columns in a table.<br>
/// If the subscript name starts with a $, then the
/// action is displayed as an additional column in the table.
Property Actions As array Of %CSP.Util.Action(XMLKEYNAME = "name");

/// If true, then display the Filter box.
Property ShowFilter As %Boolean [ InitialExpression = 1 ];

/// If true, then rows are displayed using zebra styling.
Property ShowZebra As %Boolean [ InitialExpression = 0 ];

/// If true, then rows numbers are displayed.
Property ShowRowNumbers As %Boolean [ InitialExpression = 0 ];

/// If true, then checkboxes are displayed with each row.
Property ShowCheckboxes As %Boolean [ InitialExpression = 0 ];

/// If set, name of column that provides unique id values for checkboxes.
Property CheckboxId As %String(MAXLEN = 128);

/// If true, then rows in the table can be sorted.
Property Sortable As %Boolean [ InitialExpression = 1 ];

/// If true, then this table is automatically updated.
Property AutoRefresh As %Boolean [ InitialExpression = 0 ];

/// Max number of columns to show. (deprecated)
Property MaxColumns As %Integer [ Deprecated ];

/// Comma-separated list of columns that should <em>not</em> be displayed.
Property HiddenColumns As %String(MAXLEN = 500);

/// Max number of results to find.
Property MaxResults As %Integer [ InitialExpression = 10000 ];

/// Number of items to show per page.
Property ItemsPerPage As %Integer [ InitialExpression = 20 ];

/// A list of conditions; these are expressions that
/// are evaluated to add custom colors to the table
Property Conditions As list Of %CSP.Util.Condition;

/// Border of table (default is 0)
Property border As %Integer;

/// Cellspacing (default is 0)
Property cellspacing As %Integer;

/// Cellpadding (default is 0)
Property cellpadding As %Integer;

/// Table background color
Property bgcolor As %String(MAXLEN = 50);

/// Show Last Update box (if set to 0 then do not show last update box)
Property ShowLastUpdate As %Boolean [ InitialExpression = 1 ];

/// Show Advanced search page (deprecated)
Property ShowSearchPage As %Boolean [ Deprecated ];

Method DrawHEAD(pInstance As PageInstance) As %Status
{
	Merge tID = pInstance.IDValues

	Set msgLoading = $$$Text("Loading")
	Set msgReloading = $$$Text("Reloading")
	Set msgSearching = $$$Text("Searching")
	Set msgSorting = $$$Text("Sorting")
	
	// establish time slot for temp data
	// use % variable in order to share this value
	Set %timeslot = $ZH\300

	// Use ZCRC of the request and its parameters as temp id
	Set %tempid = $ZCRC($namespace _ "/" _ %request.PageName _ "/" _ $G(%request.Data("$FRAME",1)) _ "/" _ $G(%request.Data("$ID1",1)) _ "/" _ $G(%request.Data("$ID2",1)) ,7)

	// write out methods that perform the hyper-calls
	Write "<script language=""javascript"">",!

	// server-side filter function
	Write "function callServerFilter(page,timeslot,tempid,sort,direction,filter,pagecls,frame,cbstate,id1,id2,ns)",!
	Write "{",!
	Write ##class(%CSP.Page).HyperEventCall(..%ClassName(1)_".FilterTable","page,timeslot,tempid,sort,direction,filter,pagecls,frame,cbstate,id1,id2,ns",0)
 	Write ";",!
	Write "}",!

	// server-side refresh function
	Write "function callServerRefresh(page,timeslot,tempid,sort,direction,filter,auto,pagecls,frame,cbstate,id1,id2,ns)",!
	Write "{",!
	Write ##class(%CSP.Page).HyperEventCall(..%ClassName(1)_".RefreshTable","page,timeslot,tempid,sort,direction,filter,auto,pagecls,frame,cbstate,id1,id2,ns,autoRefreshRate",0)
 	Write ";",!
	Write "}",!

	// server-side page size update function
	// This function needs to be called via #server rather than #call so that
	// the latest pagesize can be picked up by the next reload. (YSD880)
	Write "function callServerPageSize(pagesize)",!
	Write "{",!
	Write ##class(%CSP.Page).HyperEventCall(..%ClassName(1)_".ItemsPerPageUpdate","pagesize",0)
 	Write ";",!
	Write "}",!

	Write "</script>",!
	
	Set rate = $G(%session.Data("RefreshRate"),..#RefreshRate)

	&html<<script language="JavaScript">
	
// timer used for refresh
var refreshTimerId = null;

var autoRefreshPermitted = #($select(..enableAutoRefresh: "true", 1: "false"))#;

var autoRefreshFlag = #($select(..enableAutoRefresh && ..AutoRefresh:"true",1:"false"))#;

var autoRefreshRate = #(rate)#;

// call this to dynamically refresh the table
function refreshTable()
{
	if (refreshTimerId) {
		self.clearTimeout(refreshTimerId);
		refreshTimerId = null;
	}

	var filter = self.document.getElementById("filter");
	var fvalue = filter ? filter.value : "";
	var found = self.document.getElementById("found");
	if (found) {
		found.innerHTML = '<i>#($ZCVT($ZCVT(msgReloading,"O","HTML"),"O","JS"))#...</i>';
	}
	callServerRefresh(currPageNo,#(%timeslot)#,'#(%tempid)#',sortColumn,sortDirection,fvalue,autoRefreshFlag,'#(pInstance.PageClass)#',"#($ZCVT($ZCVT(..Name,"O","JS"),"O","HTML"))#",getCBValues(),"#($ZCVT($ZCVT($G(tID(1)),"O","JS"),"O","HTML"))#","#($ZCVT($ZCVT($G(tID(2)),"O","JS"),"O","HTML"))#","#($ZCVT($namespace,"O","JS"))#");
}

function startTimer()
{
	if (autoRefreshPermitted && autoRefreshFlag) {
		refreshTimerId = setTimeout("refreshTable()",autoRefreshRate);
	}
}

function cspToggleCheckbox(id)
{
	var cb = self.document.getElementById(id);
	if (cb) {
		cb.checked = !cb.checked;
	}
}

function setAutoRefresh(flag)
{
	flag = (autoRefreshPermitted && flag);
	if (flag != autoRefreshFlag) {
		autoRefreshFlag = flag;
		if (refreshTimerId) {
			self.clearTimeout(refreshTimerId);
			refreshTimerId = null;
		}
		if (flag) {
			// start refresh
			startTimer();
		}
	}

}

// filter variables
var oldFilter = '';
var filterTimerId = null;
var sortColumn = '#($G(%request.Data("SORTBY",1)))#';
var sortDirection = 1;
var currPageNo = 1;

function filterChange()
{
	var filter = self.document.getElementById("filter");
	var fvalue = filter ? filter.value : "";

	if (fvalue != oldFilter) {
		oldFilter = fvalue;

		// set timer to update filter
		if (filterTimerId) {
			self.clearTimeout(filterTimerId);
		}
		filterTimerId = self.setTimeout("onFilterTimer()",250);
	}
}

function onFilterTimer()
{
	if (filterTimerId) {
		self.clearTimeout(filterTimerId);
		filterTimerId = null;
	}

	currPageNo = 1;
	filterUpdate("<i>#($ZCVT($ZCVT(msgSearching,"O","HTML"),"O","JS"))#...</i>");
}

// actual update method called on timeout
function filterUpdate(msg)
{
	var filter = self.document.getElementById("filter");
	var fvalue = filter ? filter.value : "";

	var found = self.document.getElementById("found");
	if (found) {
		found.innerHTML = msg;
	}

	callServerFilter(currPageNo,#(%timeslot)#,'#(%tempid)#',sortColumn,sortDirection,fvalue,'#(pInstance.PageClass)#',"#($ZCVT($ZCVT(..Name,"O","JS"),"O","HTML"))#",getCBValues(),"#($ZCVT($ZCVT($G(tID(1)),"O","JS"),"O","HTML"))#","#($ZCVT($ZCVT($G(tID(2)),"O","JS"),"O","HTML"))#","#($ZCVT($namespace,"O","JS"))#");
}

function setSortColumn(name,direction)
{
	sortColumn = name;
	sortDirection = direction;
	currPageNo = 1;
	filterUpdate("<i>#($ZCVT($ZCVT(msgSorting,"O","HTML"),"O","JS"))#...</i>");
}

function gotoPage(page)
{
	currPageNo = page;
	filterUpdate("<i>#($ZCVT($ZCVT(msgLoading,"O","HTML"),"O","JS"))#...</i>");
}

// when ItemsPerPage (Page size) is changed, 
// set current page to 1 and refresh table
// 
function itemsperpageUpdate()
{
	gotoPage(1);
}

var numRows = 0;
var cbState = true;
var cbEnabled = #($S(..ShowCheckboxes:"true",1:"false"))#;

// flip the state of all the checkboxes
function toggleCheckboxes()
{
	if (cbEnabled) {
		var cb;
		cbState = document.getElementById("ctlCheck").checked;
		for (var i = 1; i <= numRows; i++) {
			cb = self.document.getElementById("cb_"+i);
			if (cb) {
				cb.checked = cbState;
			}
		}
	
		//YSD1043 cbState = !cbState;
	}
}

//  submit state of check boxes
function submitCBValues(url,type)
{
	var form = self.document.cbForm;
	if (form) {
		form.action = encodeURIComponent(url);
		form.cbState.value = getCBValues();
		form.cbAction.value = type;
		form.submit();
	}
}

// Returns a csv list of values for selected checkboxes
// (with leading and trailing comma)
function getCBValues()
{
	var state = '';
	var cb;

	if (cbEnabled) {
		for (var i = 1; i <= numRows; i++) {
			cb = self.document.getElementById("cb_"+i);
			if (cb && cb.checked) {
				state += "," + cb.value;
			}
		}
	}
	
	if (state != '') {
		state += ',';
	}

	return state;
}

// Set state of checkboxes using csv list of values
function setCBValues(state)
{
	var cb;
	if (cbEnabled) {
		for (var i = 1; i <= numRows; i++) {
			cb = self.document.getElementById("cb_"+i);
			if (cb) {
				cb.checked = (state.indexOf(',' + cb.value + ',') != -1);
			}
		}
	}
}

	</script>>

	// callback for subclasses
	Quit ..OnDrawHEADTablePane(pInstance)
}

Method OnDrawHEADTablePane(pInstance As %CSP.Util.PageInstance) As %Status
{
	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As %CSP.Util.PageInstance) As %Status
{
	Set tSC = $$$OK

	// get page ID values
	Merge tID = pInstance.IDValues
	Set tFileID = %timeslot
	Set tTempID = %tempid

	Set msgLoading = $ZCVT($$$Text("Loading"),"O","HTML")
	Set msgStatistics = $ZCVT($$$Text("Statistics"),"O","HTML")
	Set msgSeconds = $ZCVT($$$Text("seconds"),"O","HTML")
	Set msgGloRefs = $ZCVT($$$Text("global references"),"O","HTML")
	Set hlpStatistics = $ZCVT($$$Text("These statistics show the rough cost of executing this query. These values include some cost for displaying the query results."),"O","HTML")

	Set cmdSQLCODE = $ZCVT($$$Text("SQLCODE"),"O","HTML")
	Set cmdRowCount = $ZCVT($$$Text("Row count"),"O","HTML")

	Set hlpSQLINFO = $ZCVT($$$Text("SQLCODE is the SQL error code value returned by this query. Row count is the number of rows processed by this query. For SELECT statements, these values are only set when all rows are loaded."),"O","HTML")

	Set cmdFilter = $ZCVT($$$Text("Filter"),"O","HTML")
	Set hlpFilter = $ZCVT($$$Text("Filter the search results. This searches for a given string within the current displayed results."),"O","HTML")
	Set cmdPageSize = $ZCVT($$$Text("Page size"),"O","HTML")

	Do {
		Do ..DrawCommands(pInstance)
		Do ..DrawLastUpdate()
				
		If (..ShowFilter) {
			Set tShowFilter = "id=""FilterTable"""
		}
		Else {
			Set tShowFilter = "style=""display: none;"""
		}
		Set ItemsPerPage = ..GetItemsPerPage()
		Set ..ItemsPerPage = $S(+ItemsPerPage>9:ItemsPerPage,1:10)

		&html<
		<table #(tShowFilter)# class="FilterTable" border="0" cellpadding="3" cellspacing="0"><tr valign="center">
		<td align="left" nowrap>
		>
		
		Do ..OnDrawFilter(pInstance)
		
		&html<<a title="#(hlpFilter)#">
		<span class="FilterLabel">#(cmdFilter)#:</span>
		<input class="FilterInput" size="20" type="text" id="filter" onkeydown="filterChange();" onkeyup="filterChange();">&#032;
		</a>
		<span class="FilterLabel">&#032;#(cmdPageSize)#:</span>
		<select name="ItemsPerPage" id="ItemsPerPage" onchange="callServerPageSize(this.value);itemsperpageUpdate();" style="font-size: 0.6em;">>
		For cnt = 10,20,30,40,50,60,70,80,90,100  Set selected = $S(ItemsPerPage=cnt:"selected",1:"") &html<<option value="#(cnt)#" #(selected)#>#(cnt)#</option>>
		&html<</select>&#032;&#032;<span class="FilterMsg" style="width:150px;" id="found"><i>#(msgLoading)#...</i></span></td>
		<td align="left" valign="center" nowrap>&#032;
		<span id="PagingSpan" style="display:none;">
		<span class="PagingButtons" id="PagingButtons">&#032;</span>
		</td>>
		If (..#SHOWSTATISTICS) {
			&html<<td align="left" valign="center"><span title="#(hlpStatistics)#" class="FilterLabel" id="statistics">&#032;</span></td>>
		}
		&html<
		<td align="right" width="5%">&#032;</td>
		</tr></table>
		>

		If (..ShowCheckboxes) {
			// form for submit of checkboxes
			&html<<form name="cbForm" target="autoPopupWindow" method="post">
			<input type="hidden" name="cbState" value="">
			<input type="hidden" name="cbAction" value="">
			<input type="hidden" name="cbSpace" value="">
			<input type="hidden" name="$ID1" value="#($ZCVT($G(tID(1)),"O","HTML"))#">
			<input type="hidden" name="$ID2" value="#($ZCVT($G(tID(2)),"O","HTML"))#">
			<input type="hidden" name="$ID3" value="#($ZCVT($G(tID(3)),"O","HTML"))#">			
			<input type="hidden" name="$NAMESPACE" value="#($ZCVT($G(%request.Data("$NAMESPACE",1)),"O","HTML"))#">
			</form>>
		}
								
		// if there is a command form, then draw it
		If ($IsObject(..CommandFormObject)) {
			&html<<div style="padding-top:4px;padding-bottom:4px;">>
			Do ..DrawCommandForm(pInstance)
			&html<</div>>
		}

		// give browser a chance to draw the page
		Do %response.Flush()
		Hang 0.05

		// execute query / build temp file
		If (..#SHOWSQLINFO) {
			Set %sqlcontext = ##class(%ProcedureContext).%New()
			Set %sqlcontext.SQLCode = $$$Text("N/A")
			Set %sqlcontext.RowCount = $$$Text("N/A")
		}
		Set tGlobals = $$$GlobalRefs
		Set tStart = $ZH
		Set tSC = ..CreateDataSet(.tID, tFileID, tTempID)
		Set tTime = $ZH - tStart
		Set tGlobals = $$$GlobalRefs - tGlobals

		If (..#SHOWSQLINFO) {
			&html<<div title="#(hlpSQLINFO)#" style="color: #3b84bc; font-size: 12px; line-height: 150%; margin-left: 20px;" nowrap>
			#(cmdSQLCODE)#: <b><a href="javascript:launchPopupWindow('/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_sqlerrors');">#(%sqlcontext.SQLCode)#</a></b>&#032;&#032;#(cmdRowCount)#: <b>#(%sqlcontext.RowCount)#</b>
			</div>>
			Kill %sqlcontext
		}

		If ($$$ISERR(tSC)) {
			Do ..DrawStatusError(tSC)
		}
		Set tSC = $$$OK

		// if SEARCHFORM is defined, include it here
		If (..#SHOWSEARCHFORM) {
			Do ..DrawSearch(pInstance)
		}

		// place holder for table
		&html<<div id="tablediv">>
		&html<</div><br>>

		Write "<script language='JavaScript'>",!
		Write " var CSPPage = self;",!
		
		// write statistics
		If (..#SHOWSTATISTICS) {
			Set tStats = msgStatistics _": <b>"_$FN(tTime,"",3) _ "</b> "_msgSeconds_"&#032;&#032;<b>" _ tGlobals _ "</b> " _ msgGloRefs
			&js<if (self.document.getElementById("statistics")) { self.document.getElementById("statistics").innerHTML = '#(tStats)#'; }>
		}
		Set tSC = ..DrawTable(pInstance,.tID,tFileID,tTempID,1,$G(%request.Data("SORTBY",1)),1,,,.tFound)
		If ($$$ISERR(tSC)) {
			Do ..DrawStatusError(tSC)
		}
		Set tSC = $$$OK
	
		&js<if (self.document.getElementById("found")) { self.document.getElementById("found").innerHTML = '#(tFound)#'; }>
		Write "</script>",!
	
		// start auto-refresh
		If (..enableAutoRefresh && ..AutoRefresh) {
			&html<<script language="javascript">
			startTimer();
			</script>>
		}
	} While(0)

	// check if we need to purge temp data
	Do ..PurgeTempData()

	Quit $$$OK
}

/// Runs the query and builds a temp file
Method CreateDataSet(ByRef pID As %String, pFileID As %String, pTempID As %String) As %Status
{
	Set tSC = $$$OK
	
	Do {
		// execute query
		Set tRS = ""
		Set tSC = ..CreateResultSet(.pID,.tRS)
		If ($$$ISERR(tSC)) Quit
		
		// copy results into temp file
		Set tSC = ..CreateTempFile(pFileID, pTempID, .pID, tRS)
		If ($$$ISERR(tSC)) Quit
	} While(0)
	
	Quit tSC
}

/// Execute a result set and create a temp file
Method CreateTempFile(pFileID As %String, pTempID As %String, ByRef pID As %String, pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	Do GetPortalSettings^%SYS.cspServer2(%session.Username,.PortalSettings)	
	Set ..MaxResults = $G(PortalSettings("MAXROWS"),1000)
	Set tMax = ..MaxResults
	If $G(%request.Data("$MAXROWS",1))'="" Set tMax=%request.Data("$MAXROWS",1)

	// clear out temp file
	Kill ^IRIS.Temp.TablePaneI(pFileID,pTempID) // indices
	Kill ^IRIS.Temp.TablePaneD(pFileID,pTempID)	// data
	Kill ^IRIS.Temp.TablePaneC(pFileID,pTempID) // columninfo

	Do {
		If ('$IsObject(pRS)) Quit
		Set pRS.RuntimeMode = 2
		Set tSC = ..ExecuteResultSet(pRS,.pID)
		If ($$$ISERR(tSC)) Quit

		Set cols = pRS.GetColumnCount()
		For c = 1:1:cols {
			#;YSD1532 Set tCols(c) = pRS.GetColumnHeader(c)
			Set tCols(c) = pRS.GetColumnName(c)
			Set tCols(c,"type") = pRS.GetColumnType(c)
		}
		#; remember column info
		Merge ^IRIS.Temp.TablePaneC(pFileID,pTempID) = tCols

		Set row = 1
		While (pRS.Next() && ((row <= tMax) || (tMax = 0))) {
			For c = 1:1:cols {
				#; fill in temp file
				#; 3:float,5:integer,10:string,12:binstream,13:charstream
				Set tColType = tCols(c,"type")
				If (tColType=12) {
					Set tVal = "[BinaryStream]"		// BINARYSTREAM
				}
				ElseIf (tColType = 13) {			// CHARACTERSTREAM
					// !!!
					Set tVal = "[CharacterStream]"	
				}
				Else {
					Set tVal = $G(pRS.Data(tCols(c)))
					#;If tVal [ $c(18), tVal [ "Stream" Set tVal = "[Stream]"
				}
				Set ^IRIS.Temp.TablePaneD(pFileID,pTempID,row,c) = tVal
			}
			Set row = row + 1
		}

	} While (0)

	Quit tSC
}

/// This method performs the actual execution of the ResultSet
/// This can be overridden by subclasses
Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Set tParms = pRS.GetParamCount()
	If (tParms = 0) {
		Set tSC = pRS.Execute()
	}
	ElseIf (tParms = 1) {
		Set tSC = pRS.Execute($G(pID(1)))
	}
	ElseIf (tParms = 2) {
		Set tSC = pRS.Execute($G(pID(1)),$G(pID(2)))
	}
	Else {
		Set tSC = pRS.Execute($G(pID(1)),$G(pID(2)),$G(pID(3)))
	}

Done	Quit tSC
Trap
	Set $ZT = ""
	#;YSD2202
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Generate JavaScript to draw the table
/// Also updates paging buttons
Method DrawTable(pInstance As PageInstance, ByRef pID As %String, pFileID As %String, pTempID As %String, pPageNo As %Integer = 1, pSort As %String = "", pDirection As %Integer = 1, pFilter As %String = "", pCBState As %String = "", ByRef pFound As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Set tTableDone = 1
	Set pFound = ""
	Do {
		// build constant translation
		Set lFound = $ZCVT($$$Text("No items found."),"O","HTML")
		Set ltoggle = $ZCVT($$$Text("Check/Un-check all checkboxes"),"O","HTML")
		Set IsSafari = %request.UserAgent["Safari"   // Empty cell in table needs a different treatment 

		If ('$D(^IRIS.Temp.TablePaneD(pFileID,pTempID))) {
			// no temp file
			&js<CSPPage.document.getElementById("PagingSpan").style.display = 'none';>
			&js<CSPPage.document.getElementById("tablediv").innerHTML = '<br><span style="font-size: 12px; color: #3b84bc; font-style: italic;">#($ZCVT(lFound,"O","JS"))#</span>';>
			&js<numRows = 0;>

			If (..#HIDEFILTERWHENEMPTY) {
				// hide filter box
				&js<if(CSPPage.document.getElementById("FilterTable")) {CSPPage.document.getElementById("FilterTable").style.display = 'none';} >
			}
			Quit
		}

		// show filter box
		&js<if(CSPPage.document.getElementById("FilterTable")) {CSPPage.document.getElementById("FilterTable").style.display = '';} >
		
		// get column info
		Merge tCols = ^IRIS.Temp.TablePaneC(pFileID,pTempID)
		
		// build list of actions for the table
		Set tActionCols = 0
		Set tKey=""
		Set tAction = ..Actions.GetNext(.tKey)
		While (tKey'="") {
			// check for any $ actions (which are displayed as an additional column)
			If ($E(tKey,1,1) = "$") {
				Set tActionCols = tActionCols + 1
				Set tActionCols(tActionCols) = $LB(tKey,tAction.Caption)
			}
			
			Set tAction(tKey,"HREF") = tAction.HREF
			Set tAction(tKey,"Confirm") = tAction.Confirm
			Set tAction(tKey,"Type") = tAction.Type
			Set tAction(tKey,"Encrypted") = tAction.Encrypted
			Set tAction(tKey,"Target") = $S(tAction.TargetFrame="":"_top",1:tAction.TargetFrame)
	
			Kill ids
			Do tAction.GetIDValues(.ids)
			Merge tAction(tKey,"ID") = ids
			//YSD727
			If $G(ids(1)) = "",$G(pID(1)) '= "" Set tAction(tKey,"ID",1) = pID(1)
			If $G(ids(2)) = "",$G(pID(2)) '= "" Set tAction(tKey,"ID",2) = pID(2)
			Set tAction(tKey,"Popup") = tAction.Popup
			Set tAction = ..Actions.GetNext(.tKey)
		}
		
		// build list of conditions for the table
		// organized by column name
		For i=1:1:..Conditions.Count() {
			Set tCondition = ..Conditions.GetAt(i)
			If (tCondition.ColumnName '= "") {
				If (tCondition.CellStyle '= "") {
					Set tTarg = $S(tCondition.TargetColumn'="":tCondition.TargetColumn,1:tCondition.ColumnName)
					Set idx = 1 + $G(tCellCondition(tTarg))
					Set tCellCondition(tTarg) = idx
					Set tCellCondition(tTarg,idx) = tCondition
				}
				If (tCondition.RowStyle '= "") {
					Set idx = 1 + $G(tRowCondition)
					Set tRowCondition = idx
					Set tRowCondition(idx) = tCondition
				}
			}
		}
		
		// build array of "hidden" columns
		For n = 1:1:$L(..HiddenColumns,",") {
			Set t = $P(..HiddenColumns,",",n)
			If (t '= "") {
				Set tHiddenCols(t) = ""
			}
		}
		
		// Test for sort by
		If (pSort '= "") {
			// Find the column number
			Set tColNumber = 0
			For  Set tColNumber = $O(^IRIS.Temp.TablePaneC(pFileID,pTempID,tColNumber)) Quit:tColNumber=""  If ^(tColNumber) = pSort Quit

			// do we need to build a sort file?
			If ('$D(^IRIS.Temp.TablePaneI(pFileID,pTempID,pSort))) {
				
				Set id = $O(^IRIS.Temp.TablePaneD(pFileID,pTempID,""))
				While (id '= "") {
					// get value, collate
					Set val = $G(^IRIS.Temp.TablePaneD(pFileID,pTempID,id,tColNumber))
					#;YSD2437 If (val '= +val) {
					If '$IsValidNum(val) {
						Set val = " " _ $ZCVT(val,"U")
					}
					Set ^IRIS.Temp.TablePaneI(pFileID,pTempID,pSort,val,id) = ""
					Set id = $O(^IRIS.Temp.TablePaneD(pFileID,pTempID,id))
				}
			}
		}
		
		Set pFound = $$$TextHTML("No items found.")
		Set tTableDone = 0
		Set bgcolor = $S(..bgcolor'="":"bgcolor="""_..bgcolor_"""",1:"")
		&js<var html = '<table class="DetailTable" border="#(+..border)#" cellpadding="#(+..cellpadding)#" cellspacing="#(+..cellspacing)#" #(bgcolor)#>\n'>
		Set thMsg = $ZCVT($ZCVT($$$Text("Click to sort by this column."),"O","HTML"),"O","JS")
		Set tColCount = 0
		
		// headers
		&js< + '<tr>'>
	
		If (..ShowCheckboxes) {
			&js< + '<th onclick="toggleCheckboxes();" align="center" style="cursor:pointer;"><a title="#($ZCVT(ltoggle,"O","JS"))#"><input type="checkbox" name="ctlCheck" id="ctlCheck"></a></th>'>
			Set tColCount = tColCount + 1
		}

		If (..ShowRowNumbers) {
			&js< + '<th>#("#")#</th>'>
			Set tColCount = tColCount + 1
		}
	
		//If ($G(%session.Data("ItemsPerPage",1)) > 1) {
		//	If %session.Data("ItemsPerPage",1) '= ..ItemsPerPage Set ..ItemsPerPage = %session.Data("ItemsPerPage",1)
		//}
		Set ..ItemsPerPage = ..GetItemsPerPage()

		Set col = $O(tCols(""))
		While (col '= "") {
			Set cname = $ZCVT(tCols(col),"O","JS")
			Set dir = 1

			// index of col name to # (including hidden cols)
			Set tColIndex(tCols(col)) = col

			If ('$D(tHiddenCols(tCols(col)))) {
				If (tCols(col)=pSort) {
					Set class = "SortCol"
					Set ind = $S(pDirection=1:"&rsaquo;&rsaquo;&#032;",1:"&lsaquo;&lsaquo;&#032;")
					Set sort = $S(pDirection=1:cname,1:"")
					Set dir = $S(pDirection=1:-1,1:1)
				}
				Else {
					Set class = ""
					Set ind = ""
					Set sort = cname
				}
		
				If (tCols(col) '[ " ") {
					// don't let single word headers wrap
					Set tWrap = "nowrap"
				}
				Else {
					Set tWrap = "nowrap"  // jmd-never let header wrap!
				}
	
				// get localized column header
				Set lcname = ..LocalizeColumnName(tCols(col),.tHelpMsg)
				Set lcname = $ZCVT($ZCVT(lcname,"O","HTML"),"O","JS")
				Set tHelpMsg = $ZCVT($ZCVT(tHelpMsg,"O","HTML"),"O","JS")

				Set tColCount = tColCount + 1
				Set:class'="" class = "class=""" _ class _ """"
				If (..Sortable) {			
					&js< + '<th #(tWrap)# #(class)# align="left" style="text-align:left;cursor:pointer;" onclick="setSortColumn(\'#(sort)#\',#(dir)#);"><a title="#(tHelpMsg)# #(thMsg)#">#(lcname)#&#032;#(ind)#</a></th>'>
				}
				Else {
					&js< + '<th #(tWrap)# #(class)# align="left" style="text-align:left;cursor:pointer;" title="#(tHelpMsg)#">#(lcname)#&#032;</th>'>
				}
			}
			Set col = $O(tCols(col))
		}
	
		// action columns
		For c = 1:1:tActionCols {
			&js< + '<th>#($S('IsSafari:"&nbsp;",1:"&#032;"))#</th>'>
		}
	
		&js< + '</tr>'>
		
		// rows

		Set row = 0
		Set startRow = (..ItemsPerPage * (pPageNo-1)) + 1
		Set endRow = startRow + ..ItemsPerPage - 1
		
		// get first row
		If (pSort '= "") {
			// use index
			Set id = ""
			Set val = $O(^IRIS.Temp.TablePaneI(pFileID,pTempID,pSort,""),pDirection)
			Set:val'="" id = $O(^IRIS.Temp.TablePaneI(pFileID,pTempID,pSort,val,""),pDirection)
		}
		Else {
			// use master file
			Set id = $O(^IRIS.Temp.TablePaneD(pFileID,pTempID,""),pDirection)
			Set val = id
		}
		
		// what type of match:
		// [:contains,<:startswith,>:endswith,=:equals
		If (($E(pFilter,1,1)="""") && ($E(pFilter,$L(pFilter),$L(pFilter))="""")) {
			Set pFilter = $E(pFilter,2,$L(pFilter)-1)
			Set tMatchType = "="
		}
		ElseIf ($E(pFilter,1,1)="""") {
			Set pFilter = $E(pFilter,2,$L(pFilter))
			Set tMatchType = "<"
		}
		ElseIf ($E(pFilter,$L(pFilter),$L(pFilter))="""") {
			Set pFilter = $E(pFilter,1,$L(pFilter)-1)
			Set tMatchType = ">"
		}
		Else {
			Set tMatchType = "["
		}
	
		While ((val '= "") && (id '= "")) {
			// test if row matches filter
			Set tMatch = $S(pFilter="":1,1:0)
			Set tMatchCol = ""
			Kill tValue
			Set col = $O(tCols(""))
			While (col '= "") {
				// get col value
				Set tValue(col) = ^IRIS.Temp.TablePaneD(pFileID,pTempID,id,col)

				// do not test hidden columns
				If ('$D(tHiddenCols(tCols(col)))) {
					// test for match
					If ('tMatch) {
						// See if there is a match
						If (tMatchType = "[") {
							Set tMatch = ($ZCVT(tValue(col),"U") [ $ZCVT(pFilter,"U"))
						}
						ElseIf (tMatchType = "<") {
							Set tMatch = ($ZCVT($E(tValue(col),1,$L(pFilter)),"U") = $ZCVT(pFilter,"U"))
						}
						ElseIf (tMatchType = ">") {
							Set tMatch = ($ZCVT($E(tValue(col),$L(tValue(col))-$L(pFilter)+1,*),"U") = $ZCVT(pFilter,"U"))
						}
						Else {
							Set tMatch = ($ZCVT(tValue(col),"U") = $ZCVT(pFilter,"U"))
						}
	
						If (tMatch) {
							Set tMatchCol = col
						}
					}
				}
				Set col = $O(tCols(col))
			}

			If (tMatch) {
				Set row = row + 1
				If ((row >= startRow) && (row <= endRow)) {
					Set tStatus = ""
					If (..ShowZebra) {
						Set tStatus = $S(row#2=0:"EvenRow",1:"OddRow")
					}

					Set tRowStyle = ""
					// see if there are any row conditions
					Set idx = $O(tRowCondition(""))
					While (idx '= "") {
						// evaluate condition
						Set tCondition = tRowCondition(idx)
						
						Set tEval = tCondition.Eval2(.tColIndex,.tValue)
						If (tEval) {
							Set tRowStyle = "style=""" _ tCondition.RowStyle _ """"
							Quit
						}
						Set idx = $O(tRowCondition(idx))
					}

					// show this row
					Set:tStatus'="" tStatus = "class=""" _ tStatus _ """"
					&js< + '<tr #(tStatus)# #(tRowStyle)# >'>
	
					If (..ShowCheckboxes) {
						If (..CheckboxId = "") {
							Set cbValue = id
						}
						Else {
							Set cbValue = $G(tValue($G(tColIndex(..CheckboxId),-1)))
						}
						Set tChecked = $S(cbValue="":"",pCBState[(","_cbValue_","):"checked",1:"")
						&js< + '<td class="DetailRowNo"><input value="#(cbValue)#" id="cb_#(row)#" #(tChecked)# type="checkbox"></td>'>
					}

					If (..ShowRowNumbers) {
						&js< + '<td class="DetailRowNo">#(row)#</td>'>
					}
					Set col = $O(tCols(""))
					While (col '= "") {
						If ('$D(tHiddenCols(tCols(col)))) {
							// do not wrap long strings unless they start with %
							Set tNoWrap = $S(($E(tValue(col))'="%")&&($L(tValue(col))>..#WrapLimit):"",1:"nowrap")
							Set tStyle = $S(tMatchCol=col:"font-weight:bold;",1:"")
							Set tCellStyle = ""
							Set tADisabled = ""
							Set tHasAction = 0

							// test for numeric columns and right-align:
							Set:(tCols(col,"type")=3)||(tCols(col,"type")=5) tStyle=tStyle_"text-align:right;"
				
							// see if there are cell conditions for this column
							Kill c
							Set idx = $O(tCellCondition(tCols(col),""))
							While (idx '= "") {
								// evaluate condition
								Set tCondition = tCellCondition(tCols(col), idx)
								Set tEval = tCondition.Eval2(.tColIndex,.tValue)
								If (tEval) {
									Set tCellStyle = tCondition.CellStyle
									If (tCondition.CellStyle [ "disabled") {
										Set tADisabled = "disabled"
									}
									Quit
								}
								Set idx = $O(tCellCondition(tCols(col),idx))
							}
							// see if there is an action for this column
							If ($D(tAction(tCols(col))) && (tValue(col)'="")) {
								Set tHasAction = 1
								Set tNoWrap = "nowrap"
	
								// get id values
								Kill tRowID
								Set n = $O(tAction(tCols(col),"ID",""))
								While (n '= "") {
									Set actid = $G(tAction(tCols(col),"ID",n))
									If (actid [ "{") {
										// column name (remove {})
										Set actid = $P($P(actid,"{",2),"}",1)
										If (actid = "") {
											Set tRowID(n) = ""
										}
										Else {
											// find data by col name
											Set tRowID(n) = $G(tValue($G(tColIndex(actid),-1)))
										}
									}
									ElseIf (($E(actid,1,4) = "$ID(") && (+$E(actid,5,*) > 0) )  {
										// value in pID
										Set tRowID(n) = $G(pID(+$E(actid,5,*)))
									}
									Else {
										Set tRowID(n) = actid
									}
									// encrypt the value if Encrypted is true for this Action
									If $G(tAction(tCols(col),"Encrypted"),0) {
										Set tRowID(n) = ##class(%CSP.Page).Encrypt(tRowID(n))
									}
			
									Set n = $O(tAction(tCols(col),"ID",n))
								}

								If ($G(tAction(tCols(col),"Type")) = "popup") {
									Set tC = ""
									For  Set tC = $O(tRowID(tC)) Quit:tC=""  If tRowID(tC)["%" Set tRowID(tC) = ##class(%CSP.Page).EscapeURL(tRowID(tC))
									Set tURL = pInstance.MakePopupLink($G(tAction(tCols(col),"HREF")),.tRowID)
								}
								ElseIf ($G(tAction(tCols(col),"Type")) = "help") {
									Set tURL = ##class(%CSP.Util.Librarian).FindDocBookLink(.tRowID)
								}
								Else {
									// link
									Set tURL = pInstance.MakeLink($G(tAction(tCols(col),"HREF")),.tRowID)
								}
			
								If ($G(tAction(tCols(col),"Confirm")) '= "") {
									Set tConfirm = " onclick=""return confirm('" _ $ZCVT($ZCVT(tAction(tCols(col),"Confirm"),"O","HTML"),"O","JS") _ "');"""
								}
								Else {
									Set tConfirm = ""
								}
	
	
							} // action
							
							Set tCellStyle = tCellStyle _ tStyle
							If (tHasAction) {
								If (tADisabled '= "") {
									Set tHREF = ""
									Set tCellStyle = tCellStyle _ "color: gray;"
								}
								Else { 
									Set tHREF = "href=""" _ $ZCVT(tURL,"O","JS") _ """"
								}
							}
							Set:tCellStyle'="" tCellStyle = "style=""" _ tCellStyle _ """"
	
							&js< + '<td class="DetailValue" #(tCellStyle)# #(tNoWrap)#>'>
							
							If (tHasAction) {
								&js< + '<div width="100%"><a #(tADisabled)# #(tHREF)# onmouseover="this.oldcolor=this.style.color; this.style.color=\'red\';" onmouseout="this.style.color=this.oldcolor;" target="#($G(tAction(tCols(col),"Target")))#" #(tConfirm)# title="#($S(tADisabled="":$ZCVT(tAction(tCols(col),"Popup"),"O","JS"),1:""))#" >'>
							}
							Set tValue(col) = $TR(tValue(col),$C(0),"?") // JMD190!!!
							
							&js< + '#($ZCVT($ZCVT(tValue(col),"O","HTML"),"O","JS"))##($S(tValue(col)'="":"",'IsSafari:"&nbsp;",1:"&#032;"))#'>

							If (tHasAction) {
								&js< + '</a></div>'>
							}
							&js< + '</td>'>
						}

						Set col = $O(tCols(col))
					} // while
					// additional action columns
					For c = 1:1:tActionCols {
						Set k = $LG(tActionCols(c),1)
						Set tVal = $LG(tActionCols(c),2)
						Set tCellStyle = ""
						Set tADisabled = ""
						Set tNoWrap = "nowrap"
						// get id values
						Kill tRowID
						Set n = $O(tAction(k,"ID",""))
						While (n '= "") {
							Set actid = $G(tAction(k,"ID",n))
							If (actid [ "{") {
								// column name (remove {})
								Set actid = $P($P(actid,"{",2),"}",1)
								If (actid = "") {
									Set tRowID(n) = ""
								}
								Else {
									// find data by col name
									Set tRowID(n) = tValue(tColIndex(actid))
								}
							}
							ElseIf (($E(actid,1,4) = "$ID(") && (+$E(actid,5,*) > 0) )  {
								// value in pID
								Set tRowID(n) = $G(pID(+$E(actid,5,*)))
							}
							Else {
								Set tRowID(n) = actid
							}
							// encrypt the value if Encrypted is true for this Action
							If $G(tAction(k,"Encrypted"),0) {
								Set tRowID(n) = ##class(%CSP.Page).Encrypt(tRowID(n))
							}
							
							Set n = $O(tAction(k,"ID",n))
						}
						
						If ($G(tAction(k,"Type")) = "popup") {
							Set tURL = pInstance.MakePopupLink($G(tAction(k,"HREF")),.tRowID)
						}
						ElseIf ($G(tAction(k,"Type")) = "help") {
							Set tURL = ##class(%CSP.Util.Librarian).FindDocBookLink(.tRowID)
						}
						Else {
							// link
							Set tURL = pInstance.MakeLink($G(tAction(k,"HREF")),.tRowID)
						}
		
						If ($G(tAction(k,"Confirm")) '= "") {
							Set tConfirm = " onclick=""return confirm('" _ $ZCVT(tAction(k,"Confirm"),"O","JS") _ "');"""
						}
						Else {
							Set tConfirm = ""
						}
						
						// see if there are cell conditions for this column
						Set idx = $O(tCellCondition(k,""))
						While (idx '= "") {
							// evaluate condition
							Set tCondition = tCellCondition(k, idx)
							Set tEval = tCondition.Eval2(.tColIndex,.tValue)
							If (tEval) {
								Set tCellStyle = tCondition.CellStyle
								If (tCondition.CellStyle [ "disabled") {
									Set tADisabled = "disabled"
								}
								Quit
							}
							Set idx = $O(tCellCondition(k,idx))
						}
		
						Set tTitle = tAction(k,"Popup")
						Set tTarget = $G(tAction(k,"Target"))

						If (tADisabled '= "") {
							Set tHREF = ""
							Set tCellStyle = tCellStyle _ "color: gray;"
						}
						Else { 
							Set tHREF = "href=""" _ $ZCVT(tURL,"O","JS") _ """"
						}

						Set:tCellStyle'="" tCellStyle = "style=""" _ tCellStyle _ """"

						If (tADisabled'="disabled") {
							&js< + '<td class="DetailValue" #(tNoWrap)# #(tCellStyle)#>'>
							&js< + '<a #(tADisabled)# #(tHREF)# #($ZCVT(tConfirm,"O","JS"))# target="#(tTarget)#" title="#($ZCVT($ZCVT(tTitle,"O","HTML"),"O","JS"))#">#($ZCVT(tVal,"O","HTML"))#</a>'>
						} Else {
							&js< + '<td class="DetailValue" align="center" #(tCellStyle)#>'>
							&js< + '-'>
						}
						&js< + '</td>'>
					}
					// end of action columns

					&js< + '</tr>\n'>
				}
			}
	
			// get next row
			If (pSort '= "") {
				// use index
				Set id = $O(^IRIS.Temp.TablePaneI(pFileID,pTempID,pSort,val,id),pDirection)
				If (id = "") {
					Set val = $O(^IRIS.Temp.TablePaneI(pFileID,pTempID,pSort,val),pDirection)
					Set:val'="" id = $O(^IRIS.Temp.TablePaneI(pFileID,pTempID,pSort,val,""),pDirection)
				}
			}
			Else {
				// master file
				Set id = $O(^IRIS.Temp.TablePaneD(pFileID,pTempID,id),pDirection)
			}
		}

		Set lItemsfound = $ZCVT($$$Text("Items found:"),"O","HTML")

		// build items found message
		If (row = ..MaxResults) {
			Set pFound = lItemsfound _ " &gt; " _ row
		}
		Else {
			Set pFound = lItemsfound _ " " _ row
		}
	
		// build client HTML for paging buttons
		Set maxButtons = 6
		Set tPaging = ""
		Set pages = 0
		
		Set popNext = $ZCVT($$$Text("Next page"),"O","HTML")
		Set popPrev = $ZCVT($$$Text("Previous page"),"O","HTML")
		Set popFirst = $ZCVT($$$Text("First page"),"O","HTML")
		Set popLast = $ZCVT($$$Text("Last page"),"O","HTML")

		If (row > 0) {
			Set pages = ((row-1)\..ItemsPerPage) + 1
			Set startPage = ((pPageNo-1)\maxButtons) * maxButtons + 1
			Set endPage = startPage + (maxButtons - 1)
			Set:endPage>pages endPage = pages
			
			Set tPaging = "&#032;"_$ZCVT($$$Text("Page"),"O","HTML")
		
			If (pPageNo > 1) {
				Set tPaging = tPaging _ "<a title='"_$ZCVT($ZCVT($$$Text("First page"),"O","HTML"),"O","JS")_"' class='PageLink' style='cursor:pointer;' onclick='gotoPage(1);'><b>|&lsaquo;</b></a>"
				Set tPaging = tPaging _ "<a title='"_$ZCVT($ZCVT($$$Text("Previous page"),"O","HTML"),"O","JS")_"' class='PageLink' style='cursor:pointer;' onclick='gotoPage(currPageNo-1);'><b>&lsaquo;&lsaquo;</b></a>"
			}
			Else {
				Set tPaging = tPaging _ "<a class='PageLinkDisabled' >|&lsaquo;</a>"
				Set tPaging = tPaging _ "<a class='PageLinkDisabled' >&lsaquo;&lsaquo;</a>"
			}
		
			For pg=startPage:1:endPage {
				Set cls = $S(pg=pPageNo:"PageLinkCurr",1:"PageLink")
				Set tPaging = tPaging _ "<a class='" _ cls _ "' style='cursor:pointer;' onclick='gotoPage("_pg_");'>" _ pg _ "</a>"
			}
			If (pPageNo < pages) {
				Set tPaging = tPaging _ "<a title='"_$ZCVT($ZCVT($$$Text("Next page"),"O","HTML"),"O","JS")_"' class='PageLink' style='cursor:pointer;' onclick='gotoPage(currPageNo+1);'><b>&rsaquo;&rsaquo;</b></a>"
				Set tPaging = tPaging _ "<a title='"_$ZCVT($ZCVT($$$Text("Last page"),"O","HTML"),"O","JS")_"' class='PageLink' style='cursor:pointer;' onclick='gotoPage("_pages_");'><b>&rsaquo;|</b></a>"
			}
			Else {
				Set tPaging = tPaging _ "<a class='PageLinkDisabled'>&rsaquo;&rsaquo;</a>"
				Set tPaging = tPaging _ "<a class='PageLinkDisabled'>&rsaquo;|</a>"
			}
		}
		// finish display of table
		Set tTotalCols = tColCount + tActionCols
		If (pages > 1) {
			&js< + '<tr><td colspan="#(tTotalCols)#"><table width="100%"><tr class="FilterInput"><td align="left">'>
			If (pPageNo > 1) {
				&js< + '<span nowrap style="cursor:pointer;">&#032;<i><a onclick="gotoPage(currPageNo-1);" style="color:#3b84bc;">[#($ZCVT(popPrev,"O","JS"))#]</a></i></span>'>
			} Else {
				&js< + '<span nowrap style="color:white;">&#032;<i>[#($ZCVT(popPrev,"O","JS"))#]</i></span>'>
			}

			If (pPageNo < pages) {
				&js< + '&#032;&#032;<span nowrap style="cursor:pointer;">&#032;<i><a onclick="gotoPage(currPageNo+1);" style="color:#3b84bc;">[#($ZCVT(popNext,"O","JS"))#]</a></i></span>'>
			} Else {
				&js< + '&#032;&#032;<span nowrap style="color:white;">&#032;<i>[#($ZCVT(popNext,"O","JS"))#]</i></span>'>
			}

			&js< + '</td></tr></table></td></tr>'>
		}
		
		&js< + '</table>';>
		Set tTableDone = 1

		&js<CSPPage.document.getElementById("tablediv").innerHTML = html;>
		&js<numRows = #(row)#;>

		// display paging buttons
		If (pages < 2) {
			&js<CSPPage.document.getElementById("PagingSpan").style.display = 'none';>
		}
		Else {
			Set lof = $$$Text("of")
			Set tPaging = tPaging _ "&#032;" _ lof_"&#032;" _ pages _ "&#032;"
			&js<CSPPage.document.getElementById("PagingSpan").style.display = '';>
			&js<CSPPage.document.getElementById("PagingButtons").innerHTML = '#($ZCVT(tPaging,"O","JS"))#';>
		}
	} While(0)

Done	
	Quit tSC
	
Trap
	Set $ZT = ""
	If ('tTableDone) {
		&js< + '</table>';>
	}
	&js<alert('DrawTable Error: #($ZE)#');>
	Goto Done
}

Method OnGenerateCode() As %String
{
	Set code = ""
	If (..Query '= "") {
		Set code = code _ " Set tPane.Query = " _ ..QuoteCOS(..Query) _ $$$EOL
	}
	If (..SQLQuery '= "") {
		Set code = code _ " Set tPane.SQLQuery = " _ ..QuoteCOS(..SQLQuery) _ $$$EOL
	}
	If (..HiddenColumns '= "") {
		Set code = code _ " Set tPane.HiddenColumns = " _ ..QuoteCOS(..HiddenColumns) _ $$$EOL
	}
	If (..Sortable '= "") {
		Set code = code _ " Set tPane.Sortable = " _ +..Sortable _ $$$EOL
	}
	If (..MaxColumns '= "") {
		Set code = code _ " Set tPane.MaxColumns = " _ +..MaxColumns _ $$$EOL
	}
	If (..ShowFilter '= "") {
		Set code = code _ " Set tPane.ShowFilter = " _ +..ShowFilter _ $$$EOL
	}
	If (..ShowZebra '= "") {
		Set code = code _ " Set tPane.ShowZebra = " _ +..ShowZebra _ $$$EOL
	}
	If (..AutoRefresh '= "") {
		Set code = code _ " Set tPane.AutoRefresh = " _ +..AutoRefresh _ $$$EOL
	}
	If (..ShowRowNumbers '= "") {
		Set code = code _ " Set tPane.ShowRowNumbers = " _ +..ShowRowNumbers _ $$$EOL
	}
	If (..ShowCheckboxes '= "") {
		Set code = code _ " Set tPane.ShowCheckboxes = " _ +..ShowCheckboxes _ $$$EOL
	}
	If (..CheckboxId '= "") {
		Set code = code _ " Set tPane.CheckboxId = " _ ..QuoteCOS(..CheckboxId) _ $$$EOL
	}
	If (..MaxResults '= "") {
		Set code = code _ " Set tPane.MaxResults = " _ +..MaxResults _ $$$EOL
	}
	If (..ItemsPerPage '= "") {
		Set code = code _ " Set tPane.ItemsPerPage = " _ +..ItemsPerPage _ $$$EOL
	}
	If (..border '= "") {
		Set code = code _ " Set tPane.border = " _ +..border _ $$$EOL
	}
	If (..cellpadding '= "") {
		Set code = code _ " Set tPane.cellpadding = " _ +..cellpadding _ $$$EOL
	}
	If (..cellspacing '= "") {
		Set code = code _ " Set tPane.cellspacing = " _ +..cellspacing _ $$$EOL
	}
	If (..bgcolor '= "") {
		Set code = code _ " Set tPane.bgcolor = " _ ..bgcolor _ $$$EOL
	}
	If (..ShowLastUpdate '= "") {
		Set code = code _ " Set tPane.ShowLastUpdate = " _ +..ShowLastUpdate _ $$$EOL
	}
	If (..ShowSearchPage '= "") {
		Set code = code _ " Set tPane.ShowSearchPage = "_ +..ShowSearchPage _$$$EOL
	}

	// actions
	Set code = code _ $$$EOL
	If (..Actions.Count() > 0) {
		Set code = code _ " // actions" _ $$$EOL
	}

	Set tKey=""
	Set tAction = ..Actions.GetNext(.tKey)
	While (tKey '= "") {
		Set code = code _ tAction.GenerateCode()
		Set code = code _ " Do tPane.Actions.SetAt(tAction, "_..QuoteCOS(tKey)_")" _ $$$EOL
		Set code = code _ $$$EOL
		Set tAction = ..Actions.GetNext(.tKey)
	}

	// conditions
	Set code = code _ $$$EOL
	If (..Conditions.Count() > 0) {
		Set code = code _ " // conditions" _ $$$EOL
	}

	For i=1:1:..Conditions.Count() {
		Set tCondition = ..Conditions.GetAt(i)
		Set code = code _ tCondition.GenerateCode()
		Set code = code _ " Do tPane.Conditions.Insert(tCondition)" _ $$$EOL
		Set code = code _ $$$EOL
	}

	Quit code
}

/// This method creates the %ResultSet object
/// that is used for the table pane.<br>
/// A subclass can override this to customize the 
/// table displayed by this pane.<br>
/// <var>pID</var> is array of page variables...
Method CreateResultSet(ByRef pID As %String, ByRef pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	
	/// default version: use associated class query
	If (..SQLQuery '= "") {
		Set pRS = ##class(%ResultSet).%New()
		Set tSC = pRS.Prepare(..SQLQuery)
	}
	Else {
		Set pRS = ##class(%ResultSet).%New(..Query)
		If ('pRS.QueryIsValid()) {
			Quit $$$ERROR($$$GeneralError,"Invalid Query: " _ ..Query)
		}
	}

	Quit tSC
}

/// Called from client to refresh the table
ClassMethod RefreshTable(pPageNo As %Integer, pTimeSlot As %Integer, pTempID As %String, pSort As %String, pDirection As %String, pFilter As %String, pAuto As %Boolean, pPageClass As %String, pFrame As %String, pCBState As %String, pID1 As %String, pID2 As %String, pNS As %String, pRate As %Integer)
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	
	If (pFrame = "") {
		Set pFrame = "Detail"
	}
	Set tFileID = pTimeSlot
	
	// create page instance object
	Set tInstance = ##class(%CSP.Util.PageInstance).%New()

	// now get parms from page class
	Set tPane = $classmethod(pPageClass,"Get" _ pFrame _ "Pane", tInstance)

	Do tInstance.Panes.SetAt(tPane,pFrame)
	
	// make sure we are in the right namespace
	If (pNS '= "%SYS") {
		ZN pNS
		// make sure context is correct for any links we create
		Set %response.Context("$NAMESPACE") = pNS
	}

	// get page parms
	Set tID(1) = pID1
	Set tID(2) = pID2

	// js preamble
	&js<html = '';>

	// create new dataset
	Set tSC = tPane.CreateDataSet(.tID, tFileID, pTempID)
	
	// draw the table
	Set tSC = tPane.DrawTable(tInstance,.tID,tFileID,pTempID,pPageNo,pSort,pDirection,pFilter,pCBState,.tFound)

	If ($$$ISERR(tSC)) {
		&js<alert('Error refreshing table.');>
	}
	Else {
		&js<if (CSPPage.document.getElementById("found")) { CSPPage.document.getElementById("found").innerHTML = '#(tFound)#'; }>

		// js postscript
		&js<span = CSPPage.document.getElementById("lastupdate");>
		&js<if (span) { span.innerHTML = '#($ZDT($ZU(188),3,,3))#'; }>

		// refresh rate
		If ((pAuto = 1) || (pAuto = "true")) && ##class(%CSP.Portal.Utils).%IsAutoRefreshEnabled() {
			&js<CSPPage.startTimer();>
		}
	}

Done	
	Quit
	
Trap
	Set $ZT = ""
	&js<alert("RefreshTable Error: #($ZE)#");>
	Goto Done
}

/// Called from client to refilter the table
ClassMethod FilterTable(pPageNo As %Integer, pTimeSlot As %Integer, pTempID As %String, pSort As %String, pDirection As %String, pFilter As %String, pPageClass As %String, pFrame As %String, pCBState As %String, pID1, pID2, pNS As %String)
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	If (pFrame = "") {
		Set pFrame = "Detail"
	}
	
	Set tFileID = pTimeSlot

	// create page instance object
	Set tInstance = ##class(%CSP.Util.PageInstance).%New()

	// now get parms from page class
	Set tPane = $classmethod(pPageClass,"Get" _ pFrame _ "Pane", tInstance)

	Do tInstance.Panes.SetAt(tPane,pFrame)

	// make sure we are in the right namespace
	If (pNS '= "%SYS") {
		// hack for @ in implied name!
		Set:$E(pNS)="@" pNS = "^^"_$E(pNS,2,$L(pNS))		
		
		ZN pNS
		// make sure context is correct for any links we create
		Set %response.Context("$NAMESPACE") = pNS
	}

	// get page parms
	Set tID(1) = pID1
	Set tID(2) = pID2
	// strip off trailing whitespace
	Set pFilter = $ZSTRIP(pFilter,">W")

	// js preamble
	&js<html = '';>

	// draw the table
	Set tSC = tPane.DrawTable(tInstance,.tID,tFileID,pTempID,pPageNo,pSort,pDirection,pFilter,pCBState,.tFound)

	If ($$$ISERR(tSC)) {
		&js<alert('Error refreshing table.');>
	}
	Else {
		// js postscript
		&js<if (CSPPage.document.getElementById("found")) { CSPPage.document.getElementById("found").innerHTML = '#(tFound)#';}>
	}

Done	
	Quit
	
Trap
	Set $ZT = ""
	&js<if (CSPPage.document.getElementById("found")) { CSPPage.document.getElementById("found").innerHTML = '<b>Error</b>'; }>
	&js<alert("RefreshTable Error: #($ZE)#");>
	Goto Done
}

/// Called from client to update ItemsPerPage
ClassMethod ItemsPerPageUpdate(pPageSize As %Integer)
{
	//Set %session.Data("ItemsPerPage",1) = pPageSize
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"ItemsPerPage") = pPageSize
}

/// Returns default items per page value.
Method GetItemsPerPage() As %Integer
{
	Quit +$G(^IRIS.Temp.MgtPortalSettings($UserName,"ItemsPerPage"),..ItemsPerPage)
}

/// Purge all out-of-date temp data used by TablePane
ClassMethod PurgeTempData()
{
	/// Find all temp data older than 10 minutes and kill it
	Set tStart = ($ZH\300)-2
	Set tSlot = $O(^IRIS.Temp.TablePaneC(tStart),-1)
	While (tSlot '= "") {
		Kill ^IRIS.Temp.TablePaneC(tSlot) // columninfo
		Kill ^IRIS.Temp.TablePaneI(tSlot) // indices
		Kill ^IRIS.Temp.TablePaneD(tSlot) // data
		Set tSlot = $O(^IRIS.Temp.TablePaneC(tSlot),-1)
	}
}

/// Return (localized) text message displayed near top of page.
/// Subclasses may override this.
Method GetDescriptiveText()
{
	Quit ..LocalizeText(..Text)
}

/// Show Last Update box
Method DrawLastUpdate()
{
	// Get text line for page; subclass can customize this behavior
	Set tText = ..GetDescriptiveText()

	Set msgUpdate = $$$Text("Last update: ")
	Set msgAuto = $$$Text("Auto")
	Set hlpUpdate = $$$Text("Click here to refresh this table.")
	Set hlpTime = $$$Text("Time when the contents of this page were last refreshed.")
	Set hlpAuto = $$$Text("If checked, then contents of this page will automatically refresh.")

	// show descriptive text
	&html<<table border="0" cols="2" cellpadding="3" width="80%"><tr>
		<td align="left" class="Text1">#($ZCVT(tText,"O","HTML"))#</td>
		<td align="left" class="Text" nowrap width="30%" style='cursor:pointer;' valign="bottom">>

	If ..ShowLastUpdate {
		&html<<div align="left" width="100%">
		<span style="vertical-align: middle;">
		<a class="LastUpdate" title="#($ZCVT(hlpUpdate,"O","HTML"))#" onclick="refreshTable();">&#032;#($ZCVT(msgUpdate,"O","HTML"))#
		<span id="lastupdate" title="#($ZCVT(hlpTime,"O","HTML"))#" style="font-weight: bold;">#($ZDT($ZU(188),3,,3))#</span></a>
		>
		If ..enableAutoRefresh {
			&html<&#032;
				<input id="cbAuto" title="#($ZCVT(hlpAuto,"O","HTML"))#" style="vertical-align: middle; font-size: 0.5em;" type="checkbox" #($Case(..AutoRefresh,1:"checked",:""))# onclick="setAutoRefresh(this.checked);">
				<span title="#($ZCVT(hlpAuto,"O","HTML"))#" onclick="cspToggleCheckbox('cbAuto');">#($ZCVT(msgAuto,"O","HTML"))#&#032;</span>
				>
		}
		&html<
		</span>
		</div>>
	}
	&html<
		</td>
		</tr>
		</table>>
}

/// This callback is invoked when specific or advanced search criteria is being drawn to
/// allow insert of additional UI elements at the end of table
Method DrawSearch(pInstance As %CSP.Util.PageInstance) As %Status
{
}

/// Generic method to draw error message for object status code.
ClassMethod DrawStatusError(tSC As %String)
{
	Kill err
	Do $System.Status.DecomposeStatus(tSC,.err)
	&html<<div style="color:red; margin-left: 20px;" align="left" ><br>>
	Set ecnt = ""
	For  Set ecnt = $O(err(ecnt)) Quit:ecnt=""  &html<<b>#($ZCVT(err(ecnt),"O","HTML"))#</b><br>>
	&html<</div>>
}

/// This callback is invoked when the table filter is being drawn to
/// allow insert of additional UI elements
Method OnDrawFilter(pInstance As %CSP.Util.PageInstance) As %Status
{
	Quit $$$OK
}

/// Lookup a column name in the localization global and return localized
/// version if present
ClassMethod LocalizeColumnName(pName As %String, Output pHelpMsg) As %String
{
	// get key, lookup in localization global
	Set tKey = $ZCVT(pName,"L")

	// assume % domain for now!
	// look up help message
	Set pHelpMsg = $$$GetSysMessage($$$SessionLanguage,..#COLUMNHELPDOMAIN,tKey,"")

	Quit $$$GetSysMessage($$$SessionLanguage,..#COLUMNDOMAIN,tKey,pName_"*")
}

}
