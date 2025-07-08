/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Generic Pane for Displaying Explorer List.
Class %CSP.UI.System.ExpListPane Extends %CSP.Util.TablePane [ System = 4 ]
{

Parameter HIDEFILTERWHENEMPTY = 0;

/// Return (localized) text message displayed near top of page.
/// Ignore value in CSP file
Method GetDescriptiveText()
{
	Set tType = ..GetPageType()
	Set tNS = $namespace

	If ($E(tNS)="^") {
		// implied namespace: get database name
		Set tDirectory = $P(tNS,"^",3,$L(tNS,"^"))
		Set tServer = $P(tNS,"^",2)

		// Get db name
		Set ok = $$DatasetsByDirectory^%SYS.CONFIG(tServer,tDirectory,.dblist)
		If (ok && $LL(dblist)) {
			Set tDB = $LG(dblist,1)
		}
		Else {
			// some error, show verbose form
			Set tDB = tDirectory
		}

		If (tServer = "") {
			Set msg = $$$FormatText($$$Text("%1 in database %2:"),tType,tDB)
		}
		Else {
			Set msg = $$$FormatText($$$Text("%1 in database %2 on server %3:"),tType,tDB,tServer)
		}
	}
	Else {
		Set msg = $$$FormatText($$$Text("%1 in namespace %2:"),tType,tNS)
	}
	
	Quit msg
}

/// This callback draws the search mask within the filter box.
Method OnDrawFilter(pInstance As %CSP.Util.PageInstance) As %Status
{
	Set tSC = $$$OK

	Do {
		Merge tID = pInstance.IDValues

		Set cmdGlobal = ..GetPageType()
		Set cmdSearch = $ZCVT($$$Text("Go"),"O","HTML")
		Set cmdSysItems = $ZCVT($$$Text("System"),"O","HTML")
		Set hlpSysItems = $ZCVT($$$Text("Include system items in search."),"O","HTML")
		Set hlpSearch = $ZCVT($$$Text("Reload page using current search pattern."),"O","HTML")
		Set hlpMask = $ZCVT($$$Text("Enter a search pattern. This can include * as a wildcard."),"O","HTML")
		#;YSD1759
		Set SEARCHMASK = ##class(%CSP.Util.ExpPane).GetSearchMask()
		Set tMask = $G(tID(1)) If tMask = "" Set tMask=SEARCHMASK
		Set tSystem = +$G(tID(2))
		&html<<span title="#(hlpMask)#" class="FilterLabel">#(cmdGlobal)#:</span>
			<input type="text" size="20" id="searchMask" name="searchMask" style="color:blue;" value="#($zconvert(tMask,"O","HTML"))#" onkeypress="return doSearch(event);"><input type="button" style="font-size:0.8em;" title="#(hlpSearch)#" value="#(cmdSearch)#" onclick="doSearch(null);">
			&nbsp;<input type="checkbox" id="showSystemItems" name="showSystemItems" #($Case(tSystem,1:"checked",:""))# title="#(hlpSysItems)#" onclick="doSearch(null);"><span class="FilterLabel" >#(cmdSysItems)#</span>
			>		
		&html<
			&nbsp;
<script language="javascript">
// execute search
function doSearch(evt)
{
	if (evt && evt.keyCode != 13) {
		return true;
	}
	
	var maskctrl = self.document.getElementById("searchMask");
	var sysctrl = self.document.getElementById("showSystemItems");
	if (maskctrl) {
		var mask = maskctrl.value;
		var sys = '';
		if (sysctrl && sysctrl.checked) {
			sys = '&$ID2=1';
		}
		self.document.location = '#(%request.PageName)#?$NAMESPACE=' + cspEncodeUTF8('#($ZCVT($G(%request.Data("$NAMESPACE",1)),"O","JS"))#') + '&$ID1=' + cspEncodeUTF8(mask) + sys;
	}
	return true;
}
/// User clicked a routine extention link. Set the selected value into search mask and submit.
/// Similar function exists in %CSP.Util.ExpPane for Export/Delete/Find.
function loadMask(mask,type)
{
	self.document.getElementById("searchMask").value = mask;
	doSearch();
}
</script>
			>
	
	} While (0)

	Quit tSC
}

/// Get Explorer Parameters Saved
ClassMethod GetExpParameters(ByRef Type As %String, ByRef MaxResults As %Integer, ByRef Spec As %String, ByRef OrderBy As %Integer, ByRef Dir As %Integer)
{
	// no cookies!
	Set SEARCHMASK = ##class(%CSP.Util.ExpPane).GetSearchMask()
	#;YSD1759 Set Spec = $G(%request.Data("$ID1",1),..TypeDefault(Type))
	Set Spec = $G(%request.Data("$ID1",1)) If Spec = "" Set Spec = SEARCHMASK
	Set MaxResults = +$G(%request.Data("$ID2",1),100)
	Set OrderBy = +$G(%request.Data("$ID3",1),1)
	Set Dir = +$G(%request.Data("$ID4",1),1)
}

/// This method returns the page type based on PageName
Method GetPageType() As %String
{
	Set PageName = %request.PageName
	If PageName [ "Routine" Quit $$$Text("Routines")
	If PageName [ "Class" Quit $$$Text("Classes")
	If PageName [ "Global" Quit $$$Text("Globals")
	Quit "Files"
}

/// Return pattern default for each type 
ClassMethod TypeDefault() As %String
{
	Set PageName = %request.PageName	
	If PageName [ "Class" Quit "*.cls"
	If PageName [ "Routine" Quit "*.mac"
	If PageName [ "File" Quit "*.csp"
	If PageName [ "Global" Quit "*"
	Quit "*"
}

/// This method performs the actual execution of the ResultSet
/// This can be overridden by subclasses
Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Set tType = $S(%request.PageName["Routine":"Routines",%request.PageName["Class":"Classes",%request.PageName["Global":"Globals",1:"Files")
	Do ..GetExpParameters(.tType,.tMaxResults,.tSpec,.tOrderBy,.tDir)
	Set tShowSys = +$G(pID(2))
	If (tType = "Routines") {
		// routines YSD2067 - if ";" exists then execute it as is with ";*"
		If tSpec [ ";" Set tNewSpec = $P(tSpec,";",1) _ ";*"
		// spec As %String, dir As %Integer, type As %Integer
		#;YSD1759 If (tShowSys) {
			// make % routines show up in search
		#;	If (tSpec = "") {
		#;		Set tSpec = "*"
		#;	}
		#;	Set tSpec = "%" _ tSpec _ "," _ tSpec
		#;}
		#; Set tSC = pRS.Execute(tSpec,tDir,1)
		If tSpec '[ ";" Set tNewSpec = ##class(%CSP.Util.ExpPane).GetMask(tSpec)
		Set tSC = pRS.Execute(tNewSpec,,,tShowSys,1,1)
	}
	ElseIf (tType = "Classes") {
		// classes:
		// set default spec
		Set tNewSpec = ""
		For p = 1:1:$L(tSpec,",") {
			Set p1 = $P(tSpec,",",p)
			If $E(p1,$L(p1)-3,$L(p1))'=".cls" Set p1 = p1 _".cls"
			Set tNewSpec = tNewSpec _ $S(tNewSpec="":"",1:",") _ p1
		}
		Set tSC = pRS.Execute(tNewSpec,,,tShowSys,1,1)  //flat is set to 1,NotStudio is set to 1
	}
Done	
	Quit tSC
	
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
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
		Set Query = "%RoutineMgr:StudioOpenDialog"
		If %request.PageName [ "Routine" {
			Set SEARCHMASK = $G(%request.Data("$ID1",1))
			#;YSD1759 If SEARCHMASK '[ ";" Set Query = "%Routine:RoutineList"
		} Else {
			If %request.PageName [ "Global" Set Query = "%SYS.GlobalQuery:NameSpaceList"
		}
		Set pRS = ##class(%ResultSet).%New(Query)
		If ('pRS.QueryIsValid()) {
			Quit $$$ERROR($$$GeneralError,"Invalid Query: " _ Query)
		}
	}
	Quit tSC
}

/// Draw the BODY of the detail pane
/// The only difference is the comment at the end for legacy backup routines.
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
		If (..AutoRefresh) Do ..DrawLastUpdate()
				
		If (..ShowFilter) {
			Set tShowFilter = "id=""FilterTable"""
		}
		Else {
			Set tShowFilter = "style=""display: none;"""
		}
		Set ItemsPerPage = ..GetItemsPerPage()
		Set ..ItemsPerPage = $S(+ItemsPerPage>9:ItemsPerPage,1:10)

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
		If %request.PageName [ "Routine" {
			&html<<tr><td>>
			Do ##class(%CSP.Util.ExpPane).DrawRoutineLinks("List")
			&html<</td></tr>>
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
		#; YSD2204:
		Write "<script language='JavaScript'>",!
		Write " var CSPPage = self;",!
		Write "function callServerMax(maxsize)",!
		Write "{",!
		Write ##class(%CSP.Page).HyperEventCall($classname()_".MaxRowsUpdate","maxsize",0)
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

		Set lblMaxRows = $$$TextHTML("Maximum number of rows to load:","%Utility")
		Do GetPortalSettings^%SYS.cspServer2(%session.Username,.PortalSettings)
		Set tMaxRows = $G(PortalSettings("MAXROWS"),1000)
		&html<<form name="pForm">
			<div style="font-size:0.9em;" >#(lblMaxRows)# 
			<input type="text" name="MaxRows" id="MaxRows" size="5" value="#(tMaxRows)#" onchange="callServerMax(this.value);">
			</div>
			</form>>
	
		// start auto-refresh
		If (..AutoRefresh) {
			&html<<script language="javascript">
			startTimer();
			</script>>
		}
		Do ##class(%CSP.Util.ExpPane).WriteBackupMsg($G(%request.Data("$ID1",1)))

	} While(0)

	// check if we need to purge temp data
	Do ..PurgeTempData()

	Quit $$$OK
}

/// Called from client to update MaxRows
ClassMethod MaxRowsUpdate(MaxRows As %Integer)
{
	If +MaxRows < 0 Set MaxRows = 100
	If +MaxRows > 10000 Set MaxRows = 10000	
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"MAXROWS") = MaxRows
}

}
