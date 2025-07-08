/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %occODBC)

/// Utilities used by Management Portal SQL.
Class %CSP.UI.Portal.SQL.Utils Extends %RegisteredObject [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// Method to return SQL statement object and class name. Called by multiple SQL UI pages.
/// When %caller is passed in as "SMP" then the system will prevent the DDL API from checking the DDLAllowed flag for the class (used by modifying view)
ClassMethod SQLExecuteQuery(pText As %String(MAXLEN=""), ByRef pClassName As %String, pRuntimeMode As %Integer = 2, pDialect As %String = "Cache", pObjectSelectMode As %Boolean = 0, %caller As %String = "", ByRef tDiskRead, ByRef StatementType As %Integer = 0, ByRef AccStat, ByRef pSessionData, pQueryID As %Integer, ByRef pRuntimeClassName As %String) As %SQL.StatementResult
{
#dim tException as %Exception.AbstractException
#define ResponseTimeout Set responseTimeout = %request.GatewayTimeout - 5 If responseTimeout < 15 Set responseTimeout = 15
	New %tStatement,%tResult
	
	if '$d(pSessionData) && $isobject($g(%session)) {
		merge pSessionData = %session.Data($username,"SQL")
	}
	
	Set %tStatement = ##class(%SQL.Statement).%New()
	Set %tStatement.%SelectMode = pRuntimeMode
	Set %tStatement.%Dialect = pDialect
	Set %tStatement.%ObjectSelectMode = pObjectSelectMode
	Set tDiskRead = 0
	#;if SQLExecuteQuery is not called from DrawHTML, to make EndCollectStats happy, we just init. 
	if $d(AccStat)=0 do ..InitCollectStats(.AccStat)
	If $get(^%SYS("Compiler","EnableDiskReadTiming"),1) Do ##class(%SYSTEM.Process).EnableDiskReadTiming()
	try {
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
		//$$$ResponseTimeout
		//Do $System.Alarm.Set(responseTimeout)
		/*If $IsObject(pText) {
			Kill pText
			Merge pText = pSessionData("QueryText")	
		}*/
		Do ..StartCollectStats(.tCurStat)
		Do %tStatement.prepare(.pText)
		Set tParameterCount = %tStatement.%Metadata.parameters.Count()
		Do ..EndCollectStats(.tCurStat,.AccStat)
		
		If tParameterCount > 0 {
			Set tExecute = "Set %tResult = %tStatement.%Execute("
			#; check if it is the same query!
			If tParameterCount = $P(pSessionData("QueryParam"),"^",1) {
				Set tPromptCount = $P(pSessionData("QueryParam"),"^",2)
				Set tParm = $O(pSessionData("QueryParam",""))
				While tParm '= "" {
					Set tParmExpr = "%tValue"_tParm
					Set tParamColumnType = pSessionData("QueryParam",tParm)
					If (tParamColumnType = 1) || (tParamColumnType = 2) {
						Set tParmVal = pSessionData("QueryParam",tParm,"Value")
						Set tParmExpr = "%tValue"_tParm
						Set @("%tValue"_tParm) = tParmVal
						Set tExecute = tExecute _ tParmExpr _ ","
					} 				
					ElseIf tParamColumnType > 3 {
						// Output only (4) or Return value (5)
						Set tExecute = tExecute _ ","
					}
					Set tParm = $O(pSessionData("QueryParam",tParm))
				}
			}
			Set tExecute = $Select($Extract(tExecute,*)'="(":$Extract(tExecute,1,*-1)_")",1:tExecute _ ")")
			Set tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds
			Do ..StartCollectStats(.tCurStat)
			xecute tExecute
			Do ..EndCollectStats(.tCurStat,.AccStat)
		} Else {
			Set tDiskRead=$zu(67,41,$J)+$system.Context.WorkMgr().DiskReadMilliseconds
			Do ..StartCollectStats(.tCurStat)
			Set %tResult = %tStatement.%Execute()
			Do ..EndCollectStats(.tCurStat,.AccStat)
		}
		Do $System.Alarm.Clear()
		Set tSC = %tStatement.%GetImplementationDetails(.pClassName,.%tStatement,.tArgument,.StatementType,.pRuntimeClassName)
	}
	catch tException {
		Set %tResult = ##class(%SQL.StatementResult).%New()
		Do $System.Alarm.Clear()
		If ($ZE["<ALARM>") {
			$$$ResponseTimeout
			Set %tResult.%Message = $$$FormatTextHTML("Query did not compile or execute within %1 seconds.", responseTimeout)
		} Else {	
			Set %tResult.%SQLCODE = tException.AsSQLCODE()
			Set %tResult.%Message = tException.AsSQLMessage()
		}
	}
	Quit %tResult
}

/// Method to return number of parameters that user needs to provide for input in order to execute the query.
/// Return number of Parameters within query text. 0 means none. 
ClassMethod GetQueryParameters(pText As %String(MAXLEN=""), pRuntimeMode As %Integer = 2, pDialect As %String = "Cache", pObjectSelectMode As %Boolean = 0, ByRef tPromptCount As %Integer) As %String
{
#dim tException as %Exception.AbstractException
#define ResponseTimeout Set responseTimeout = %request.GatewayTimeout - 5 If responseTimeout < 15 Set responseTimeout = 15
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tStatement.%SelectMode = pRuntimeMode
	Set tStatement.%Dialect = pDialect
	Set tStatement.%ObjectSelectMode = pObjectSelectMode
	Set tResult = ##class(%SQL.StatementResult).%New()
	Set tResult.%Message = ""
	#; tPromptCount is the total number of input that we will need to prompt the user to enter (param type is 1 or 2 only)
	#; tParameterCount is the total parameters
	try {
		$$$ResponseTimeout
		Do $System.Alarm.Set(responseTimeout)
		If $IsObject(pText) {
			Kill pText
			Merge pText = %session.Data($Username,"SQL","QueryText")
		}
		Do tStatement.prepare(.pText)
		Set tParameterCount = tStatement.%Metadata.parameters.Count()
		Kill %session.Data($Username,"SQL","QueryParam")
		If tParameterCount > 0 {
			For tParm = 1:1:tParameterCount {
				Set tParameter = tStatement.%Metadata.parameters.GetAt(tParm)
				Set tParamColumnType = tParameter.columnType
				Set %session.Data($Username,"SQL","QueryParam",tParm) = tParamColumnType
				If (tParamColumnType = 1) || (tParamColumnType = 2) {
					Set tPromptCount = tPromptCount + 1
				}
			}
		}
		Set %session.Data($Username,"SQL","QueryParam") = tParameterCount_"^"_tPromptCount
		Do $System.Alarm.Clear()
	}
	catch tException {
		Do $System.Alarm.Clear()
		If ($ZE["<ALARM>") {
			$$$ResponseTimeout
			Set tResult.%Message = $$$FormatTextHTML("Statement did not finish prepare within %1 seconds.", responseTimeout)
		} Else {	
			Set tResult.%SQLCODE = tException.AsSQLCODE()
			Set tResult.%Message = tException.AsSQLMessage()
		}
	}
	Quit tResult
}

/// GetError will return the HTML for an invalid SQLCODE.
ClassMethod GetError(pResult As %SQL.StatementResult, ByRef pMessages As %String(MAXLEN=""))
{
	set pMessages = +$G(pMessages) + 1, pMessages(pMessages) = $$$HTMLENCODE("[SQLCODE: <"_pResult.%SQLCODE_">:<"_$system.SQL.SQLCODE(pResult.%SQLCODE) _ ">]")
	set pMessages = pMessages + 1, pMessages(pMessages) = $$$HTMLENCODE("[%msg: <"_pResult.%Message_">]")
}

/// Given schema name and view name, return view info
ClassMethod GetViewInfo2(Schema As %String, ViewName As %String, Output Owner As %String, Output ReadOnly As %Boolean, Output CheckOption As %String) As %Status
{
	Set $ZT="Trap"
	Set currentNS = $namespace
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewInfo2")
	Do tRS.Execute(Schema, ViewName)
	If tRS.Next() {
		Set Owner = tRS.Data("OWNER")
		Set ReadOnly = tRS.Data("DEFINED_AS_READ_ONLY")
		Set CheckOption = tRS.Data("CHECK_OPTION")
	}
	Quit $$$OK
Trap
	Set $ZT="" Quit 0
}

ClassMethod InitCollectStats(ByRef AccStat) As %Status [ Internal ]
{
	s AccStat("commands") = 0
	s AccStat("gloref") = 0
}

ClassMethod StartCollectStats(ByRef CurStat) [ Internal ]
{
	#;This routine should be as simple as possible, no any error checking, to avoid this helpers interfere the performace metrics
	s CurStat("gloref") = $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences
	s CurStat("commands") = $zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted
}

ClassMethod EndCollectStats(ByRef CurStat, ByRef CurAcc) [ Internal ]
{
	#;This routine should be as simple as possible, no any error checking, to avoid this helpers interfere the performace metrics 
	s CurAcc("commands") = CurAcc("commands") + $zu(67,8,$J)+$system.Context.WorkMgr().CommandsExecuted - CurStat("commands")
	s CurAcc("gloref") = CurAcc("gloref") + $$$GlobalRefs+$system.Context.WorkMgr().GlobalReferences - CurStat("gloref")
}

/// ***** The following methods are used to draw query results. Multiple resultsets and call statements are handled. *****
/// ***** The caller should have already obtained a SQL statement result using SQLExecuteQuery in this class.        *****
/// ***** See method DrawHTML in %CSP.UI.Portal.SQL.Home and %CSP.UI.Portal.SQL.PrintQuery                               *****
/// 
/// DrawResult will draw all of the result information returned in the statement result object.
ClassMethod DrawResult(pResult As %SQL.StatementResult, pDrawTab As %Boolean = 0, pShowRowNum As %Boolean, ByRef AccStat, pMaxRows As %Integer = 1000, pQueryID As %Integer = -1)
{
#define dump(%c) if $g(%inBackground) { set ^IRIS.Temp.ExecuteQuery($username,pQueryID,"data",$i(^IRIS.Temp.ExecuteQuery($username,pQueryID,"data"))) = %c } else { write !,%c }
#dim tResult as %SQL.StatementResult
#dim tResultSet as %SQL.IResultSet
#dim tRSMD as %SQL.StatementMetadata
	Set tMessages = 0, tOutputValues = 0, tResultSet = 0
	Set ^IRIS.Temp.ExecuteQuery($Username,pQueryID,"ResultCount") = ""
	Set ^IRIS.Temp.ExecuteQuery($Username,pQueryID,"%SQLCODE") = pResult.%SQLCODE
	If 'pDrawTab $$$dump("<link rel=""stylesheet"" type=""text/css"" href='/csp/sys/intersystems.css'>")
	If pResult.%SQLCODE '< 0 {
		Set tOutputValues = pResult.%OutputColumnCount > 0
		If pResult.%ResultColumnCount {
			#; %CurrentResult will be bound as a result of checking %ResultColumnCount. Grab it now and then loop over
			#; the remaining result sets and place them in the tResultSet array
			Set tResultSet = 1, tResultSet(1) = pResult.%CurrentResult
			do ..StartCollectStats(.CurStat)
			Set tTemp = pResult.%NextResult() While $Isobject(tTemp) { Set tResultSet = tResultSet + 1, tResultSet(tResultSet) = tTemp, tTemp = pResult.%NextResult() }
			do ..EndCollectStats(.CurStat,.AccStat)
			#; Draw tabs
			Do:pDrawTab ..DrawTabs(tResultSet,tOutputValues,pQueryID)
			#; And now draw the result sets
			For tPtr = 1:1:tResultSet { Do ..DrawResultSet(tPtr,tResultSet(tPtr),pDrawTab,pShowRowNum,.tMessages,.AccStat,pMaxRows,pQueryID) }
		}
		Else {
			$$$dump("<p>&nbsp;&nbsp;"_$$$FormatText($$$Text("%1 row(s) affected"),pResult.%ROWCOUNT)_"</p>")
			Set ^IRIS.Temp.ExecuteQuery($Username,pQueryID,"ResultCount") = $S($G(^IRIS.Temp.ExecuteQuery($Username,pQueryID,"ResultCount"))'="":^IRIS.Temp.ExecuteQuery($Username,"ResultCount")_" / ",1:"")_pResult.%ROWCOUNT
		}
		If tOutputValues {
			Do ..DrawOutputColumns(tResultSet + 1, pResult, pDrawTab, .tMessages, pQueryID)
		}
	}
	Else { 
		Do ..GetError(pResult,.tMessages)
		Do ..DrawMessages("",pDrawTab,.tMessages,pQueryID)
	}
}

/// Draw html for one resultset.
ClassMethod DrawResultSet(pPtr As %Integer, pResult As %SQL.StatementResult, pDrawTab As %Boolean, pShowRowNum As %Boolean, ByRef pMessages As %String(MAXLEN=""), ByRef AccStat, pMaxRows As %Integer = 1000, pQueryID As %Integer = -1)
{
#define dump(%c) if $g(%inBackground) { set ^IRIS.Temp.ExecuteQuery($username,pQueryID,"data",$i(^IRIS.Temp.ExecuteQuery($username,pQueryID,"data"))) = %c } else { write !,%c }
	do ..StartCollectStats(.CurStat)
	Set tRSMD = pResult.%GetMetadata()
	do ..EndCollectStats(.CurStat,.AccStat)
	
	Set divid = "div"_pPtr
	Set state = $S(pPtr=1||'pDrawTab:"block",1:"none")
	Set maxrows = pMaxRows
	$$$dump("<br/><div id="_divid_" class=""groupResult"" style=""display:"_state_""">")
	If 'pDrawTab $$$dump("<h3>"_$$$Text("Result #")_pPtr_"</h3>")
	$$$dump("<table class='ExecuteTable' cellpadding='1' cellspacing='1'><tr>")
	If pShowRowNum = 1 {
		$$$dump("<th>#</th>")
	}
	Set tColumns = tRSMD.columnCount
	For tColPtr = 1:1:tColumns {
		$$$dump("<th>"_$$$HTMLENCODE(tRSMD.columns.GetAt(tColPtr).colName)_"</th>")
	}
	$$$dump("</tr>")
	Set (tRow,tTotal) = 0
	Set tEmpty = $$$TextHTML("<empty>")
	
	do ..StartCollectStats(.CurStat)
	Set tMetadata = pResult.%GetMetadata()
	do ..EndCollectStats(.CurStat,.AccStat)
	
	For{
		
		do ..StartCollectStats(.CurStat)
		Set leave = pResult.%Next(.sc)
		do ..EndCollectStats(.CurStat,.AccStat)
		if $$$ISERR(sc) { set pResult.%SQLCODE=$system.Status.StatusToSQLCODE(sc,.msg) set:$g(msg)'="" pResult.%Message=msg quit }
		
		if 'leave QUIT
		if tTotal >= maxrows QUIT
		
		Set tRow = 'tRow
		Set tTotal = tTotal + 1
		Set tClass = $S(tRow:"EvenRow",1:"OddRow")
		$$$dump("<tr class="""_tClass_""">")
		If pShowRowNum = 1 $$$dump("<td>"_tTotal_"</td>")
		For tColPtr = 1:1:tColumns {
			do ..StartCollectStats(.CurStat)
			Set val = pResult.%GetData(tColPtr)
			do ..EndCollectStats(.CurStat,.AccStat)
			
			Set column = tMetadata.columns.GetAt(tColPtr)
			If val '= "" {
				If (column.ODBCType = $$$ODBCTYPElongvarchar) { 
					Set tStream = ##class(%Stream.Object).%Open(val)
					If $IsObject(tStream) {
						Set val = tStream.Read(110)
						Set:$L(val)>100 val=$E(val,1,100)_"..."
					}
					Else {
						Set val = "<stream>"
					}
					Set tStream = ""
				}
				ElseIf (column.ODBCType = $$$ODBCTYPElongvarbinary) {
					Set val = "<binary>"
				}
			}
			Set tAlign = $Case(column.ODBCType,$$$ODBCTYPEinteger:"right",$$$ODBCTYPEfloat:"right",:"left")			
			Set tNb = $S($a(val)=0:tEmpty,val="":"&nbsp;",1:"")
			$$$dump("<td class='DetailValue' align='"_tAlign_"'>"_$$$HTMLENCODE(val)_tNb_"</td>")
		}
		$$$dump("</tr>")
		
		do:$g(%inBackground)&&'(tTotal#100) ##class(%CSP.UI.Portal.SQL.Home).%SetBackgroundMethodStatus($$$Text("Fetching query result")_"... ("_tTotal_" "_$$$Text("rows")_")")
	}
	//pResult.%ROWCOUNT
	$$$dump("</table>")
	$$$dump("<p>"_$$$FormatText($$$Text("%1 row(s) affected"),tTotal)_"</p>")
	Set ^IRIS.Temp.ExecuteQuery($Username,pQueryID,"ResultCount") = $S($G(^IRIS.Temp.ExecuteQuery($Username,pQueryID,"ResultCount"))'="":^IRIS.Temp.ExecuteQuery($Username,pQueryID,"ResultCount")_" / ",1:"")_tTotal
	If pResult.%SQLCODE < 0 {
		Do ..GetError(pResult,.tMessages)	
		Do ..DrawMessages("",pDrawTab,.tMessages,pQueryID)
	}
	$$$dump("</div>")
}

ClassMethod DrawOutputColumns(pPtr As %Integer = 0, pResult As %SQL.StatementResult, pDrawTab As %Boolean, ByRef pMessages As %String(MAXLEN=""), pQueryID As %Integer = -1)
{
#define dump(%c) if $g(%inBackground) { set ^IRIS.Temp.ExecuteQuery($username,pQueryID,"data",$i(^IRIS.Temp.ExecuteQuery($username,pQueryID,"data"))) = %c } else { write !,%c }
	Set tRSMD = pResult.%GetMetadata()
	Set divid = "div"_pPtr
	Set state = $S(pPtr=1||'pDrawTab:"block",1:"none")
	$$$dump("<div id="""_divid_""" style=""display:"_state_""">")
	If 'pDrawTab $$$dump("<h3>"_$$$Text("Output Columns")_pPtr_"</h3>")
	$$$dump("<table class='DetailTable'><tr>")
	$$$dump("<th>"_$$$TextHTML("Parameter")_"</th>")
	$$$dump("<th>"_$$$TextHTML("Value")_"</th>")
	$$$dump("</tr>")
	Set tRow = 0
	Set tPosition = ""
	Set tValue = pResult.%NextOutputValue(.tPosition)
	While tPosition '= "" {
		Set tRow = 'tRow
		Set tClass = $S(tRow:"DarkRow",1:"LiteRow")
		$$$dump("<tr class="""_tClass_""">")
		$$$dump("<td>"_$$$HTMLENCODE(tPosition)_"</td>")
		$$$dump("<td>"_$$$HTMLENCODE(tValue)_"</td>")
		$$$dump("</tr>")
		Set tValue = pResult.%NextOutputValue(.tPosition)
	}
	$$$dump("</table>")
	$$$dump("</div>")
}

/// Messages passed in should already been HTML escaped.
ClassMethod DrawMessages(pPtr As %Integer = 1, pDrawTab As %Boolean, ByRef pMessages As %String(MAXLEN=""), pQueryID As %Integer = -1)
{
#define dump(%c) if $g(%inBackground) { set ^IRIS.Temp.ExecuteQuery($username,pQueryID,"data",$i(^IRIS.Temp.ExecuteQuery($username,pQueryID,"data"))) = %c } else { write !,%c }
	If pDrawTab = 0 $$$dump("<h3>"_$$$TextHTML("Messages")_"</h3>")
	$$$dump("<div id=""idMessages"" class=""ErrorBox"">")
	For tMsgPtr = 1:1:$Get(pMessages) { $$$dump("<p>&nbsp;&nbsp;"_pMessages(tMsgPtr)_"<p>") }
	$$$dump("</div>")
}

/// Control method to draw tab group. This is only used on the SQL Home page for Execute Query tab. 
ClassMethod DrawTabs(totalResultsets, pOutputValues As %Integer = 0, pQueryID As %Integer = -1)
{
#define dump(%c) if $g(%inBackground) { set ^IRIS.Temp.ExecuteQuery($username,pQueryID,"data",$i(^IRIS.Temp.ExecuteQuery($username,pQueryID,"data"))) = %c } else { write !,%c }
	#; If single resultset and no output values, then no need to draw tabs.
	If totalResultsets = 1,'pOutputValues Quit
	$$$dump("<table class=""tabGroupBar"" border=""0"" cellspacing=""0"" cellpadding=""0"">")
	$$$dump("<tr><td width=""20"">&nbsp;</td>")
	Set totalTabs = totalResultsets + 1 + pOutputValues
	For t = 1:1:totalResultsets {
		Set tCaption = $$$TextHTML("Result #")_t
		Set tTabclass = "tabGroupButton"_$S(t=1:"On",1:"Off")
		Do ..DrawTabBox(tTabclass,tCaption,t,totalTabs,pQueryID)
	}
	If pOutputValues { 
		Set tCaption = $$$TextHTML("Output Values")
		Do ..DrawTabBox("tabGroupButtonOff",tCaption,t+1,totalTabs,pQueryID) 
	}
	//Set tCaption = $$$TextHTML("Messages")	
	//Do ..DrawTabBox("tabGroupButtonOff",tCaption,t+1+pOutputValues,totalTabs)
	
	$$$dump("<td width=""25%"" class=""tabGroupExtra"">&nbsp;</td>")
	$$$dump("</tr></table>")
}

/// Draws each tab in tab group button
ClassMethod DrawTabBox(tabClass As %String, tabCaption As %String, tabIndex As %Integer, totalTabs As %Integer, pQueryID As %Integer = -1)
{
#define dump(%c) if $g(%inBackground) { set ^IRIS.Temp.ExecuteQuery($username,pQueryID,"data",$i(^IRIS.Temp.ExecuteQuery($username,pQueryID,"data"))) = %c } else { write !,%c }
	Set title = $$$TextHTML("Click to change to or refresh this tab")
	Set tText = "<a href='#'>&nbsp;"_$$$HTMLENCODE(tabCaption)_"&nbsp;</a>"
	Set tId = "extab"_tabIndex
	Set tClick = "onclick=""return zenPage.tabChanged("_tabIndex_","_totalTabs_");"""
	$$$dump("<td nowrap=""1"" id="""_tId_""" class="""_tabClass_""" "_tClick_">"_tText_"</td><td class=""tabGroupGapTd""><div class=""tabGroupGap""> </div></td>")
}

/// *****                 End of Group Methods for DrawResult                  *****
/// List schemas based on cache gateway connection - you must have a DSN (configuration name) passed in.
/// This method is Jobbed from the wizard page.
ClassMethod LoadSchemas(pWizard, pDSN, pTableType, pSchemaFilter) As %String
{
	Set $ze="",$zt="errSchema"
	
	Set ^IRIS.Temp.LinkWizardLoad(+$J) = $H
	Set cnt = 0,pfx=""
	Do getFlags^%apiGTW(pDSN,.f,.isJ)

	If isJ set pfx="J"

	If pWizard = "LinkProcedure" Set QUERYNAME = "%GTWCatalog:SQLProcedures"_pfx
	Else  set QUERYNAME = "%GTWCatalog:SQLTables"_pfx
	
	Set rs = ##class(%ResultSet).%New(QUERYNAME)
	Set tname = ""
	If isJ, pWizard '="LinkProcedure" Set tname = "%"

	If isJ, pWizard = "LinkProcedure" Set tSC = rs.Execute(pDSN,"",pSchemaFilter)
	If isJ, pWizard '= "LinkProcedure" Set tSC = rs.Execute(pDSN,tname,pTableType,pSchemaFilter)
	If 'isJ {
		If pWizard '= "LinkProcedure" Set tSC = rs.Execute(pDSN,tname,pTableType,pSchemaFilter)
		Else  Set tSC = rs.Execute(pDSN,"",pSchemaFilter)
	}
	If $$$ISERR(tSC) {
		Set ^IRIS.Temp.LinkWizardLoad(+$J) = "ERROR" _ $System.Status.GetErrorText(tSC)
		Quit 1
	}

	Set msg = $$$Text("retrieved")
	Set n = 0
	While rs.Next() {
		Set n = n + 1
	  Set schemaname = rs.Data("SCHEMA_NAME") 
	  If schemaname="" set schemaname="[null schema]"
	  If schemaname'="",$a(schemaname) = 0 set schemaname="[empty schema]"
	  Set ^IRIS.Temp.LinkWizardLoad(+$J) = n_" " _ msg
	  Set sche(schemaname) = 1
	  
	}
	// YSD1234 - if the only schema is [empty schema] then change it to [null schema]
	Set schemaname=$o(sche(""))
	If schemaname = "[empty schema]",$o(sche(schemaname))="" Set sche("[null schema]") = 1 kill sche("[empty schema]")
	Set (rs,s) = ""
	Merge ^IRIS.Temp.LinkWizardLoad(+$J) = sche
	Set ^IRIS.Temp.LinkWizardLoad(+$J) = "Done"
	/// Drop SQLGateway connections
	Do DropAll^%apiGTW
	Quit 1
errSchema
	Set ^IRIS.Temp.LinkWizardLoad(+$J) = "ERROR" _ $$$HTMLENCODE($ZE)
	Set $ZE = ""
	Quit 0
}

ClassMethod LoadTables(pWizard, pDSN, pSchema, pTableType, pFilter) As %String
{
	Set $ze="",$zt="errTable"
	Set ^IRIS.Temp.LinkWizardLoad(+$J)=$H

	Set cnt = 0,pfx=""
	Do getFlags^%apiGTW(pDSN,.f,.isJ)
	If isJ set pfx="J"

	Set tschema = ..ReverseSchema(pSchema)
	If pWizard = "LinkTable"!(pWizard = "DataMigration") {
		Set rs = ##class(%ResultSet).%New("%GTWCatalog:SQLTables"_pfx)
		
		//If isJ do rs.Execute(pDSN,pFilter,pTableType,tschema)
		//If 'isJ do rs.Execute(pDSN,pFilter,pTableType,tschema)
		Set tSC = rs.Execute(pDSN,pFilter,pTableType,tschema)
		Set NAME = "TABLE_NAME"
		Set TYPE = "TABLE_TYPE"
	} else {
		Set rs = ##class(%ResultSet).%New("%GTWCatalog:SQLProcedures"_pfx)
		Set tSC = rs.Execute(pDSN,pFilter,tschema)
		Set NAME = "PROC_NAME"
		Set TYPE = "PROC_TYPE"
	}
	If $$$ISERR(tSC) {
		Set ^IRIS.Temp.LinkWizardLoad(+$J) = "ERROR" _ $System.Status.GetErrorText(tSC)
		Quit 1
	}

	While rs.Next() {
	  	Set tablename = rs.Data(NAME)
	  	If tablename'="" Set ^IRIS.Temp.LinkWizardLoad(+$J,tablename) = rs.Data(TYPE)
	}
	Set rs = ""
	Set ^IRIS.Temp.LinkWizardLoad(+$J) = "Done"
	/// Drop SQLGateway connections
	Do DropAll^%apiGTW
	Quit 1
errTable
	Set ^IRIS.Temp.LinkWizardLoad(+$J) = "ERROR" _ $$$HTMLENCODE($ZE)
	Set $ze = ""
	Quit 0
}

ClassMethod ReverseSchema(schema) As %String
{
	if schema = "[null schema]" quit ""
	if schema = "[empty schema]" quit $c(0)
	if schema = "[no schema]" quit ""
	quit schema
}

/// Method for UI to get SQL Configuration Settings. Return Properties array.
ClassMethod GetConfigSQLProperties(ByRef Properties As %String) As %Status
{
	Set tSC = ##class(Config.SQL).Get(.Properties)
	If $$$ISERR(tSC) Quit tSC
	#; Reverse ON/OFF for the UI
	For item = "FastDistinct","AdaptiveMode","AutoParallel","IdKey" {
		Set Properties(item) = 'Properties(item) 
	}
	
	#; For SQL Shell settings
	Set Properties("SelectMode") = $case($g(^%SYS("sql","shell","SelectMode"),0),1:"ODBC",2:"Display",:"Logical")
	Set Properties("Dialect") = $g(^%SYS("sql","shell","Dialect"))
	Set Properties("Path") = $g(^%SYS("sql","shell","Path"))
	Set Properties("ColAlign") = $case($g(^%SYS("sql","shell","ColAlign"),0),1:"Header",2:"Data",:"Delimter")
	Set Properties("CommandPrefix") = $g(^%SYS("sql","shell","CommandPrefix"))
	Set Properties("DisplayMode") = $case($g(^%SYS("sql","shell","DisplayMode"),-1),0:"XML",1:"HTML",2:"PDF",99:"Text",100:"CSV",:"Current Device")
	Set Properties("DisplayPath") = $g(^%SYS("sql","shell","DisplayPath"))
	Set Properties("DisplayFile") = $g(^%SYS("sql","shell","DisplayFile"))
	Set Properties("DisplayTranslateTable") = $g(^%SYS("sql","shell","DisplayTranslateTable"))
	Set Properties("EchoMode") = $select($g(^%SYS("sql","shell","EchoMode"),1)=1:"On",1:"Off")
	Set Properties("ExecuteMode") = $select($g(^%SYS("sql","shell","ExecuteMode"),1)=1:"Immediate",1:"Deferred")
	Set Properties("MessagesMode") = $select($g(^%SYS("sql","shell","MessagesMode"),1)=1:"On",1:"Off")
	Set Properties("EscapeCondition") = $g(^%SYS("sql","shell","EscapeCondition"),1)

	Quit tSC
}

/// Method for UI to save SQL configuration settings. ZEN proxy object is passed in with user selected values.
ClassMethod SaveConfigSQLProperties(proxy As %ZEN.proxyObject) As %ZEN.proxyObject
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.ok = 0
	Try {
		Set cqChange = 0
		
		If 'proxy.IsReadOnly {
			Set tSC = ##class(Config.SQL).Get(.Properties)
			If $$$ISERR(tSC) {
				Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
				Quit
			}

			#; Reverse ON/OFF for the UI
			Set proxy.FastDistinct = 'proxy.FastDistinct
			Set proxy.AdaptiveMode = 'proxy.AdaptiveMode
			Set proxy.AutoParallel = 'proxy.AutoParallel
			Set proxy.IdKey = 'proxy.IdKey
							
			#; Check if any of the fields that changed should trigger clearing of CQs
			If Properties("DefaultSchema") '= proxy.DefaultSchema Set cqChange = 1
			If Properties("AdaptiveMode") '= proxy.AdaptiveMode Set cqChange = 1
			If Properties("FastDistinct") '= proxy.FastDistinct Set cqChange = 1
			If Properties("AutoParallel") '=proxy.AutoParallel Set cqChange = 1
			If Properties("ODBCVarcharMaxlen") '= proxy.ODBCVarcharMaxlen Set cqChange = 1
			If Properties("ParameterSampling") '=proxy.ParameterSampling Set cqChange = 1
			Set Properties("IdKey") = proxy.IdKey
			
			Set IgnoreRedundant = proxy.IgnoreRedundant
			Set Properties("DDLNo30") = IgnoreRedundant
			Set Properties("DDLNo201") = IgnoreRedundant
			Set Properties("DDLNo307") = IgnoreRedundant
			Set Properties("DDLNo315") = IgnoreRedundant
			Set Properties("DDLNo324") = IgnoreRedundant
			Set Properties("DDLNo333") = IgnoreRedundant
			Set Properties("DDLNo311") = IgnoreRedundant
			
			Set Properties("LockTimeout") = proxy.LockTimeout
			Set Properties("LockThreshold") = proxy.LockThreshold
			Set Properties("TODATEDefaultFormat") = proxy.TODATEDefaultFormat
			Set Properties("ODBCVarcharMaxlen") = proxy.ODBCVarcharMaxlen
			Set Properties("Comment") = proxy.Comment
			Set Properties("FastDistinct") = proxy.FastDistinct
			Set Properties("SaveMAC") = proxy.SaveMAC
			Set Properties("DefaultSchema") = proxy.DefaultSchema
			Set Properties("AdaptiveMode") = proxy.AdaptiveMode
			Set Properties("ParameterSampling") = proxy.ParameterSampling
			Set Properties("ClientMaxIdleTime") = proxy.ClientMaxIdleTime
			Set Properties("AutoParallel") = proxy.AutoParallel
			Set Properties("TimePrecision") = proxy.TimePrecision
			Set Properties("TCPKeepAlive") = proxy.TCPKeepAlive
			Set Properties("AutoParallel") = proxy.AutoParallel
			
			Set tSC = ##class(Config.SQL).Modify(.Properties)
			If $$$ISERR(tSC) {
				Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
				Quit
			}
			Set ^%SYS("sql","shell","SelectMode") = $case(proxy.SelectMode,"ODBC":1,"Display":2,:0)
			Set ^%SYS("sql","shell","Dialect") = proxy.Dialect
			Set ^%SYS("sql","shell","Path") = proxy.Path
			Set ^%SYS("sql","shell","ColAlign") = $case(proxy.ColAlign,"Header":1,"Data":2,:0)
			Set ^%SYS("sql","shell","CommandPrefix") = proxy.CommandPrefix
			Set ^%SYS("sql","shell","DisplayMode") = $case(proxy.DisplayMode,"XML":0,"HTML":1,"PDF":2,"TXT":99,"CSV":100,:-1)
			Set ^%SYS("sql","shell","DisplayPath") = proxy.DisplayPath
			Set ^%SYS("sql","shell","DisplayFile") = proxy.DisplayFile
			Set ^%SYS("sql","shell","DisplayTranslateTable") = proxy.DisplayTranslateTable
			Set ^%SYS("sql","shell","EchoMode") = $select(proxy.EchoMode="Off":0,1:1)
			Set ^%SYS("sql","shell","ExecuteMode") = $select(proxy.ExecuteMode="Deferred":0,1:1)
			Set ^%SYS("sql","shell","MessagesMode") = $select(proxy.MessagesMode="Off":0,1:1)
			Set ^%SYS("sql","shell","EscapeCondition") = proxy.EscapeCondition
			If cqChange > 0 {
				Set tParms("Reason") = $$$TextHTML("Reason: SQL Configuration change")
				Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("PurgeAllCachedQueries",$namespace,.tParms,,.tJob)
				If $$$ISERR(tSC) {
					Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
					Quit
				}			
				Set tmsg = $$$TextHTML("SQL settings saved.")_"&nbsp;&nbsp;"_$$$TextHTML("Cached Queries will be purged for all namespaces.")
				Set tProxy.Message = tmsg
			}
			Set tProxy.ok = 1
		}
	} Catch Error {
		Set tProxy.ErrorMessage = $$$HTMLENCODE($System.Status.GetErrorText(Error.AsStatus()))
	}
	Quit tProxy
}

}
