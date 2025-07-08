/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Customized TablePane for browsing SQL tables. Added textbox to allow user to enter maximum number of rows to load for Open Table
Class %CSP.UI.SQL.BrowseTablePane Extends %CSP.Util.TablePane [ System = 4 ]
{

/// display filter box when there are no results so that user can adjust their mask for tables.
Parameter HIDEFILTERWHENEMPTY = 0;

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
<script language="javascript">
// execute search
function doSearch(evt)
{
	if (evt && evt.keyCode != 13) {	
		return true;
	}
	var schema = document.NamespaceForm.$ID1.value;
	var maskctrl = self.document.getElementById("searchMask");
	if (maskctrl) {
		var mask = maskctrl.value;
		var url = '#(%request.PageName)#?$NAMESPACE=' + cspEncodeUTF8('#($ZCVT($G(%request.Data("$NAMESPACE",1)),"O","JS"))#') + '&$ID1=' + schema + '&$ID3=' + cspEncodeUTF8(mask);
		self.document.location = url;
	}
	return true;
}
</script>
			>
		&html<
		<hr noshade size="1">
		<table #(tShowFilter)# class="FilterTable" border="0" cellpadding="3" cellspacing="0"><tr>
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
		&html<</select>&#032;&#032;<span class="FilterMsg" style="color: darkblue; font-weight: bold; width:150px;" id="found"><i>#(msgLoading)#...</i></span></td>
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
			&html<<div title="#(hlpSQLINFO)#" style="color: darkblue; font-size: 0.8em; line-height: 150%; margin-left: 20px;" nowrap>
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
		Write "function callServerOpenTableMax(maxsize)",!
		Write "{",!
		Write ##class(%CSP.Page).HyperEventCall($classname()_".OpenTableMaxRowsUpdate","maxsize",0)
 		Write ";",!
		Write "}",!
	
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

		Set lblMaxRows = $$$TextHTML("Number of rows to load when table is opened:","%Utility")
		Set tMaxRows = ..GetOpenTableMaxRows()
		&html<<form name="pForm">
			<div style="font-size:0.9em;" >#(lblMaxRows)# 
			<input type="text" name="OpenTableMaxRows" id="OpenTableMaxRows" size="5" value="#(tMaxRows)#" onchange="callServerOpenTableMax(this.value);">
			</div>
			</form>>
	
		// start auto-refresh
		If (..AutoRefresh) {
			&html<<script language="javascript">
			startTimer();
			</script>>
		}
	} While(0)

	// check if we need to purge temp data
	Do ..PurgeTempData()

	Quit $$$OK
}

/// This callback draws the search mask within the filter box.
Method OnDrawFilter(pInstance As %CSP.Util.PageInstance) As %Status
{
	Set tSC = $$$OK

	Do {
		Merge tID = pInstance.IDValues

		Set cmdTable = ..GetPageType()
		Set cmdSearch = $ZCVT($$$Text("Go"),"O","HTML")
		Set hlpSearch = $ZCVT($$$Text("Reload page using current search pattern."),"O","HTML")
		Set hlpMask = $ZCVT($$$Text("Enter a search pattern. This can include * as a wildcard."),"O","HTML")
		Set SEARCHMASK = ..GetSearchMask()
		Set tMask = $G(tID(3)) If tMask = "",$G(tID(3))="" Set tMask = SEARCHMASK
		If tMask = "" Set tMask = "*"
		&html<<span class="FilterLabel">#(cmdTable)#:</span>
			<input type="text" title="#(hlpMask)#" size="20" id="searchMask" name="searchMask" style="color:blue;" value="#($zconvert(tMask,"O","HTML"))#" onkeypress="return doSearch(event);"><input type="button" style="font-size:0.8em;" title="#(hlpSearch)#" value="#(cmdSearch)#" onclick="doSearch(null);">
			>
	
	} While (0)

	Quit tSC
}

/// This method returns the page type based on PageName
Method GetPageType() As %String
{
	Set PageName = %request.PageName
	If PageName [ "Table" Quit $$$Text("Tables")
	If PageName [ "View" Quit $$$Text("Views")
	If PageName [ "Procedure" Quit $$$Text("Procedures")
	Quit "Files"
}

/// This method performs the actual execution of the ResultSet
/// pID(3) is the searchMask from user clicking the "Go" rather than user clicking a schema which sets $ID(2).
/// If it is from Go then it is possible user removed the mask then default to "*".
/// Otherwise retain the last mask.
Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Set tSchema = $G(pID(1))
	Set tFilter = $G(pID(3)) If tFilter = "" Set tFilter = ..GetSearchMask()
	Set:tFilter="" tFilter="*"
	Set tSC = pRS.Execute(tSchema,0,tFilter)

Done	
	Quit tSC
	
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Generic Method being called from the Routine panes to return search mask.
ClassMethod GetSearchMask() As %String
{
	#; submitted from particular pane for Search
	Set SEARCHMASK = $G(%request.Data("$SEARCHMASK",1))
	If SEARCHMASK = "" Set SEARCHMASK = $G(%request.Data("$ID3",1))
	#; get from last save
	If SEARCHMASK = "" Set SEARCHMASK = $G(^IRIS.Temp.MgtPortalSettings($UserName,"SEARCHMASK",%request.PageName))
	#; set default if nothing
	If SEARCHMASK = "" Set SEARCHMASK = "*"
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"SEARCHMASK",%request.PageName) = SEARCHMASK
	Quit SEARCHMASK
}

/// Called from client to update OpenTableMaxRows
ClassMethod OpenTableMaxRowsUpdate(OpenTableMaxRows As %Integer)
{
	If +OpenTableMaxRows < 0 Set OpenTableMaxRows = 100
	If +OpenTableMaxRows > 10000 Set OpenTableMaxRows = 10000	
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"OpenTableMaxRows") = OpenTableMaxRows
}

/// Returns default OpenTableMaxRows value.
ClassMethod GetOpenTableMaxRows() As %Integer
{
	Set MaxRows = +$G(^IRIS.Temp.MgtPortalSettings($UserName,"OpenTableMaxRows"))
	If MaxRows = 0 Set MaxRows = 100
	Quit MaxRows
}

}
