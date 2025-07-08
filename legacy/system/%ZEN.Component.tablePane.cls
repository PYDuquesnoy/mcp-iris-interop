/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  This component draws an HTML table based on the contents
///  of a query.<br>
///  The data for the table can come from a pre-built class query,
///  an SQL statement, or the tablePane can create an SQL query automatically.<br>
///  The properties of the <class>tablePane</class>, as well as the auxiliary classes,
///  <class>%ZEN.Auxiliary.column</class>, <class>%ZEN.Auxiliary.condition</class>, and
///  <class>%ZEN.Auxiliary.parameter</class>, let you control the behavior and
///  appearance of the <class>tablePane</class>.<br>
///  Many of the characteristics of the tablePane are inherited from its
///  superclass, <class>%ZEN.Component.simpleTablePane</class>. Refer to it
///  for more details.
Class %ZEN.Component.tablePane Extends simpleTablePane [ Deprecated, System = 3 ]
{

Parameter SYSMODULE = "table";

Parameter DOMAIN = "%ZEN";

///  List of column information objects.<br>
///  Each object specifies additional details about a column 
///  in the table.<br>
Property columns As list Of %ZEN.Auxiliary.column(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE");

///  User-defined list of parameters. These values are passed on
///  to the user callback function that provides the query for this table.
Property parameters As list Of %ZEN.Auxiliary.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT", XMLREF = 1);

///  A list of conditions. These are special expression objects that
///  are evaluated to add data-dependent styles to the table.
Property conditions As list Of %ZEN.Auxiliary.condition(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE");

///  Caption displayed for this table using the HTML caption element.<br>
///  This is a localized value.
Property caption As %ZEN.Datatype.caption;

///  If true, then the tooltip (HTML title attribute) displayed
///  for cells within the table will display the current value of the cell.
Property showValueInTooltip As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If a browser does not support CSS nowrap correctly, this flag provides
///  a way to control whether table cells allow word wrapping or not.<br>
Property nowrap As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  Width used for extra columns, such as row number, row selector, etc.
Property extraColumnWidth As %ZEN.Datatype.length [ InitialExpression = 30 ];

///  If true, display column filters (if any).
Property showFilters As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  This property controls how to display the table header when
///  column filters are used.
///  <ul>
///  <li>"filtersOnTop" - (the default) Display column filters above column headers.</li>
///  <li>"headersOnTop" - Display column headers above filters.</li>
///  </ul>
Property headerLayout As %ZEN.Datatype.string(VALUELIST = ",filtersOnTop,headersOnTop") [ InitialExpression = "filtersOnTop" ];

///  If true, disable column filters (if any).
Property filtersDisabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If true (the default), automatically re-execute the query for this
///  table when the user changes the value of a column filter.<br>
///  If false, the query will only be re-executed when the
///  <method>executeQuery</method> is called.
Property autoExecute As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  If defined, this is the name of the data column that provides
///  a logical value for a selected row.
Property valueColumn As %ZEN.Datatype.string;

///  Specifies where the data columns of the table come from.<br>
///  "query" (the default)- columns are displayed for each column in the 
///  data source query.<br>
///  "columns" - only columns explicitly defined in the <property>columns</property>
///  list are displayed.
Property dataSource As %ZEN.Datatype.string(VALUELIST = ",query,columns") [ InitialExpression = "query" ];

///  If true, create a temporary snapshot of the query results.
///  This allows for paging and sorting without re-executing the query.
Property useSnapshot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If true, then the header of the table will stay in position when the body
///  of the table is scrolled. 
Property fixedHeaders As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If present, this specifies the height
///  of the body section of the table.
Property bodyHeight As %ZEN.Datatype.length;

///  Amount of spacing around cells in the table. The default is 0 (no extra space around table cells).
///  For a slight but noticeable separation, a useful value is 2.
Property cellSpacing As %ZEN.Datatype.integer [ InitialExpression = 0 ];

///  If present, this is the number of rows returned by the current
///  query. This is calculated by the built-in query or the
///  automatic query.<br>
///  Note: this is a string as it could be set to "" or "100+".
Property rowCount As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

///  This is the number of items to display on
///  a single "page" of the table.
///  0, the default, means show all data on first page.
///  This can only be set to a non-zero value when the table
///  is in snapshot mode.
Property pageSize As %ZEN.Datatype.integer [ InitialExpression = 0 ];

///  For snapshot mode, this is the number (1-based) of the current "page" within the snapshot
///  that is displayed.
Property currPage As %ZEN.Datatype.integer [ InitialExpression = 1 ];

///  This is the logical name of the most recently selected column
///  header. Typically this is used for sorting.
Property currColumn As %ZEN.Datatype.string(ZENEXPRESSION = 1);

///  onheaderClick event handler:
///  This event is fired when the user clicks on a column header.
///  The name of the column will be in the <property>currColumn</property> property.
Property onheaderClick As %ZEN.Datatype.eventHandler;

///  For sortable tables, this is the order to sort values within the
///  current column. Values can be "", "asc" (ascending), or "desc" (descending).
Property sortOrder As %ZEN.Datatype.string(VALUELIST = ",asc,desc", ZENEXPRESSION = 1);

///  Internal property used to track last changed filter.
Property lastFilter As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

///  Internal property used to track the result set snapshot number.
Property snapshotId As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

///  Client-side, run-time flag that is set when client wants to force
///  re-execution of the table query when the table is in "snapshot" mode.
Property clearSnapshot As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

///  Time, in ODBC timestamp format, that the query for this table
///  was last executed. This is set on the server whenever the query is
///  for the tablePane is executed.
Property lastUpdate As %ZEN.Datatype.string(XMLPROJECTION = "none");

///  Server-side diagnostic flag. If true, display the query used
///  to get data for this table.<br/>
///  This is an encrypted value and cannot be set on the client.
Property showQuery As %ZEN.Datatype.boolean(ZENENCRYPT = 1, ZENEXPRESSION = 1) [ InitialExpression = 0 ];

///  Internal method.<br>
///  Applications should use the <method>executeQuery</method> of the
///  <class>tablePane</class> class.<br>
///  Call to the server and update the contents of the tablePane.
///  This is a wrapper around the <method>refreshContents</method> method.
ClientMethod refreshTable() [ Internal, Language = javascript ]
{
	// do not refresh if we are already refreshing
	if (null == this.progressBarTimerId) {
		this.refreshContents();
	
		// display progress bar, if needed
		this.startProgressBar();
	}
}

///  Localized "invalid date" message displayed by control.
Property invalidMessage As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Invalid Date","%ZEN")} ];

///  If true, then the tablePane will capture user keystrokes and use them
///  for simple table navigation.
Property useKeys As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  This property should be set to 1 by server-side methods that want to force
///  the query associate with the tablePane to be re-executed.
Property refreshRequired As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

/// Flag to control whether session is unlocked during updates to the table.
Property unlockSession As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  onkeypress event handler:
///  If <property>useKeys</property> is true, then this event handler
///  code is run when the user presses a key within the tablePane.
Property onkeypress As %ZEN.Datatype.eventHandler;

Property msgNoResult As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("No Results","%ZEN")} ];

/// Flag for backwards compatibility.
/// If <property>permitClientSQL</property> is set to true, query parameters
/// may be set programatically through javascript on the client, depending on
/// site and application settings this may constitute a security risk. If set
/// to false (the default), the parameters may only be set on the server.  This 
/// property is encrypted and any attempt to modify it on the client will result
/// in an <ILLEGAL VALUE> error.
Property permitClientSQL As %ZEN.Datatype.boolean(ZENENCRYPT = 1, ZENEXPRESSION = 1) [ InitialExpression = 0 ];

/// Flag for less intrusive remedial action when Client-side SQL modification is forbidden.
/// If <property>permitClientSQL</property> is set to false (the default), this flag controls
/// the rendering of the table if client side modification of the query parameters is detected.
/// By default, a Zen Exception will be raised, warning of the security risk.  If this flag is set
/// to true, however, the exception will be suppressed and the table will re-render using the last
/// known (server-side) values for the query parameters.  In this case the client-side modifications
/// are simply ignored.  The default value is "false" indicating that the exception should be raised.
Property suppressExceptionOnClientSQL As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This method is used (server-side only) to set the refreshRequired 
/// property when changing the underlying query from ObjectScript at 
/// run time.  Client-side code should <b>not</b> "wrap" and call this 
/// function.  Instead, JavaScript code should make use of the 
/// refreshTable() method.
Method %ResetQuery() As %Status
{
	Set idxStr = ""_..%page_"@"_..id_..index

	Kill ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr)
	Set ..refreshRequired = 1
	Quit $$$OK
}

Method %OnAddToPageAfter() As %Status
{
	Set idxStr = ""_..%page_"@"_..id_..index
	Kill ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr)

	Quit $$$OK
}

/// This callback is invoked by the %ZENDeserialize method.
Method %OnZENDeserialize() As %Status
{
	If (..permitClientSQL=0) {
		Set idxStr = ""_..%page_"@"_..id_..index
		If $D(^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr)) {
 			Set tLastQuery = ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr)
			Set tObj = ##class(%DynamicAbstractObject).%FromJSON(tLastQuery)
			If ($IsObject(tObj)) {
				If (..whereClause '= tObj.whereClause) ||
					(..queryClass '= tObj.queryClass) ||
					(..tableName '= tObj.tableName) ||
					(..queryName '= tObj.queryName) ||
					(..sql '= tObj.sql) ||
					(..columnName '= tObj.columnName) ||
					(..orderByClause '= tObj.orderByClause) ||
					(..groupByClause '= tObj.groupByClause) {		

					Set tObj.useCached=..index	
					Set tCacheStr = tObj.%ToJSON()
						Kill ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr)
 					Set ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr) = tCacheStr
				}
			}
		}
	}
	Quit $$$OK
}

Method ValidateQueryIntegrity() As %Status [ Internal ]
{
 	Set idxStr = ""_..%page_"@"_..id_..index	
 	Set tSC = $$$OK
	Set tUseCached = -1
	
	If $D(^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr)) {
		Set tLastQuery = ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",idxStr)
		Set tObj = ##class(%DynamicAbstractObject).%FromJSON(tLastQuery)
		If ($IsObject(tObj)) {
			Set tUseCached=tObj.useCached
			If (tUseCached= ..index) {
				Set protected = ""
				If (..whereClause'="")&&(..whereClause '= tObj.whereClause) {
					Set protected = protected_" whereClause"
					Set ..whereClause = tObj.whereClause
				}
				If (..queryClass'="")&&(..queryClass '= tObj.queryClass) {
					Set protected = protected_" queryClass"
					Set ..queryClass = tObj.queryClass
				}
				If (..queryName'="")&&(..queryName '= tObj.queryName) {
					Set protected = protected_" queryName"
					Set ..queryName = tObj.queryName
				}
				If (..tableName'="")&&(..tableName '= tObj.tableName) {
					Set protected = protected_" tableName"
					Set ..tableName = tObj.tableName
				}
				If (..sql'="")&&(..sql '= tObj.sql) {
					Set protected = protected_" sql"
					Set ..sql = tObj.sql
				}
				If (..columnName'="")&&(..columnName '= tObj.columnName) {
					Set protected = protected_" columnName"
					Set ..columnName = tObj.columnName
				}
				If (..orderByClause'="")&&(..orderByClause '= tObj.orderByClause) {
					Set protected = protected_" orderByClause"
					Set ..orderByClause = tObj.orderByClause
				}
				If (..groupByClause'="")&&(..groupByClause '= tObj.groupByClause) {
					Set protected = protected_" groupByClause"
					Set ..groupByClause = tObj.groupByClause
				}
				If ((..suppressExceptionOnClientSQL'=1)&&(protected'="")) {
					Set tSC = $$$ERROR($$$GeneralError,"Client modification of protected property ("_protected_") disallowed for security reasons.")
				}
			}
		}
	}
	If (tUseCached= -1) {
		Set tObj = {"useCached": -1,
			"queryClass":($$$ZENVAL(..queryClass)),
			"queryName":($$$ZENVAL(..queryName)),
			"tableName":($$$ZENVAL(..tableName)),
			"sql":($$$ZENVAL(..sql)),
			"columnName":($$$ZENVAL(..columnName)),
			"whereClause":($$$ZENVAL(..whereClause)),
			"orderByClause":($$$ZENVAL(..orderByClause)),
			"groupByClause":($$$ZENVAL(..groupByClause))
		}
		Set tStr = tObj.%ToJSON()
		Kill ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",..index)
		Set ^IRIS.Temp.zenData(%session.SessionId,"tpQueryInfo",..index) = tStr
	}
	Quit tSC
}

///  Draw innerHTML for this component (without enclosing div).
Method %DrawHTML()
{
	Set tSC = $$$OK
	If (..permitClientSQL'=1) {
		Set tSC = ..ValidateQueryIntegrity() 
		If $$$ISERR(tSC) {
			Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
			Quit
		}
	}
	
	#; check for invalid property combinations
	If ('..useSnapshot && (+..pageSize>0)) {
		Set tSC = $$$ERROR($$$GeneralError,"Page size should only be specified in snapshot mode")
	}
	If ..unlockSession && (..lastUpdate '= "") {
		Do %session.Unlock()
	}

	If (..useKeys) {
		#; insert invisible input to catch key events
		Set keyevt = "onkeydown=""zenPage.getComponent("_..index_").tpKeyDownHandler(event);"" onkeypress=""zenPage.getComponent("_..index_").tpKeyPressHandler(event);"""
		&html<<input type="text" id="#(..%MakeId("invisible"))#" style="top:0px;left:0px;position:absolute;border: 0px solid green;width:1px;height:1px; margin:0px;padding:0px;opacity:0.01;" #(keyevt)# />>
	}

	Set tInfo = ""
	Set tRS = ""
	Set tRunQuery = 1
	If ('..clearSnapshot && (%zenContext'="page") && ..useSnapshot && (..snapshotId '= "")) {
		#; test if snapshot exists
		If $D(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index)) {
			Set tRunQuery = 0
		}
		Else {
			#; go back to page 1
			Set ..currPage = 1
		}
	}

	If (tRunQuery) {
		If ((..clearSnapshot || '..useSnapshot) && (..snapshotId'="")) {
			#; kill old snapshot
			Kill ^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index)
			Set ..snapshotId=""
		}

		#; create QueryInfo object to hold query info
		Set tInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()
		#; convert parameters to array
		For n = 1:1:..parameters.Count() {
			Set value = ..parameters.GetAt(n).value
			Set tInfo.parms(n) = $$$ZENVAL(value)
		}

		#; additional query parms
		Set tInfo.sortColumn = $$$ZENVAL(..currColumn)
		Set tInfo.sortOrder = $$$ZENVAL(..sortOrder)
		Set tInfo.tableName = $$$ZENVAL(..tableName)
		Set tInfo.columnName = $$$ZENVAL(..columnName)
		Set tInfo.whereClause = $$$ZENVAL(..whereClause)
		Set tInfo.orderByClause = $$$ZENVAL(..orderByClause)
		Set tInfo.groupByClause = $$$ZENVAL(..groupByClause)
		
		#; # of rows to fetch
		If (..useSnapshot) {
			Set tInfo.rows = 0 // fetch all
		}

		#; look at column object to find filters and column info.
		#; these will be passed on to the CreateResultSet callback
		#; so that it can apply filtering etc.
		Set tCount = ..columns.Count()
		For n=1:1:tCount {
			Set tColumn = ..columns.GetAt(n)
			Set tColName = $$$ZENVAL(tColumn.colName)
			If (tColName'="") {
				#; make sure client has resolved client name
				Set:tColName'=tColumn.colName tColumn.actualColName = tColName

				#; column info
	 			Set tInfo.columns(n) = tColName
	 			Set tInfo.columnExpression(tColName) = $$$ZENVAL(tColumn.colExpression)
 				
				#; filter info				
				#; see if the filtervalue contains an expression
				Set evaluatedFilter=$S(tColumn.filterValue["#(":$$$ZENVAL(tColumn.filterValue),1:tColumn.filterValue)									
				Set tInfo.filters(tColName) = $S(tColumn.filterValue=$C(0):"",1:evaluatedFilter)
				Set tInfo.filterOps(tColName) = $S(tColumn.filterOp=$C(0):"",1:tColumn.filterOp)
				Set tInfo.filterTypes(tColName) = $S(tColumn.filterType=$C(0):"",1:tColumn.filterType)
			}
		}

		#; create and execute result set
		Set ..lastUpdate = ""
		Set ..rowCount = "" // clear
		Set tRS = ..%CreateResultSet(.tSC,tInfo,..initialExecute)
		If $$$ISERR(tSC) {
			#; don't show error if no initialExecute
			If (..initialExecute) {
				Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
			}
		}

		If $$$ISOK(tSC)&&$IsObject(tRS) {
			#; set lastUpdate time: timestamp plus ms
			Set ..lastUpdate = $ZDT($ZU(188),3,,3)
	
			If (..useSnapshot) {
				#; build the snapshot
				#; create snapshot ID
				Set ..snapshotId = ($ZH*100)\1
				Set tSC = ..%CreateSnapshot(..snapshotId, tRS)
				If $$$ISERR(tSC) {
					Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
				}
			}
		}
	}

	#; diagnostic display
	If ($$$ZENVAL(..showQuery)) {
		If $IsObject(tInfo) {
			Set tQueryText = tInfo.queryText
		}
		Else {
			Set tQueryText = "snapshot: (" _ ..snapshotId _ ")"
		}
		&html<<div style="border: 1px solid darkblue; padding:2px; background: white;">#($ZCVT(tQueryText,"O","HTML"))#</div>>
	}

	#; draw the table
	If $$$ISOK(tSC) {
		Set tSC = ..%DrawTable(tRS)
		If $$$ISERR(tSC) {
			Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
		}
		Set tRS = ""
	}
	
	#; reset execute flag
	Set ..initialExecute = 1
}

///  Draw the table.
Method %DrawTable(pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	#; we are forced to be IE-specific for fixed header
	Set tIE = (($$$ZENISIE)&&(%page.cssLevel<3))


	#; build array containing column information
	#; first get columns from actual query or snapshot
	#; and place them, by name, into tColNames
	#; and by number, into tColNums
	#; we assume there are no duplicate column names

	#; get columns
	Set tColsFromQuery = (..dataSource="query")
	Set tColNums = 0
	If (..useSnapshot && (..snapshotId'="")) {
		#; use snapshot
		Set c = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"info",""))
		While (c '= "") {
			Set tName = $G(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"info",c))
			Set tHeader = $G(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"info",c,"th"),tName)
			Set tType = $G(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"info",c,"type"),10)
			Set:$D(tColNames(tName)) tName = "(duplicate) " _ tName // duplicate column name
			Set tColNames(tName) = c
			If (tColsFromQuery) {
				#; add column
				Set tColNums = tColNums + 1
				Set tColNums(c) = tName
				Set:tHeader'=tName tColNums(c,"th") = tHeader
				Set tColTypeByNum(c) = tType
			}
			Else {
				Set tColTypes(tName) = tType
				Set tColTypeByNum(c) = tType
			}
			Set c = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"info",c))
		}
		
		#; if a sort is specified, build an index (unless it exists)
		If ((..currColumn '= "") && $D(tColNames(..currColumn)) && (..snapshotId'="")) {
			Set cn = tColNames(..currColumn)

			If ('$D(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"index",..currColumn))) {
				Set tKey = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"data",""),1,tSnapData)
				While (tKey '= "") {
					#; collate
					set tCollated = 0
					Set tType = $G(tColTypeByNum(cn),10)
					If (..%IsTypeNumeric(tType)) {
						Set tValue = $LG(tSnapData,cn)
						Set tValue = $S(tValue="":1E-14,1:+tValue)
					}
					elseif tType = 2 {
							// DATE - we assume that if the date is numeric (val=+val) that the form is $h
						Set tRawValue = $LG(tSnapData,cn)
						try {
								// if numeric then just take it
							if tRawValue = +tRawValue { set tValue = tRawValue }
								// Try to convert it using the current locale setting
							else { set tValue = $zdth(tRawValue) }
						}
						catch tException {
								// <ILLEGAL VALUE> means this is some other format than the current locale
								// Odd but it could be ODBC format (type = 3)
							if tException.Name = "<ILLEGAL VALUE>" {
								try { set tValue = $zdth(tRawValue,3) }
									// Note that overridden LogicalToDisplay/LogicalToODBC methods can make this formatting fail
								catch tException2 { set tValue = tRawValue }
							}
						}
					}
					Else {
							// DLP: truncate the value to some arbitrary length to avoid a <SUBSCRIPT> error.
						Set tValue = " "_$ZCVT($Extract($LG(tSnapData,cn),1,250),"U")
			//			Set tValue = " "_$ZCVT($LG(tSnapData,cn),"U")
						set tCollated = 1
					}
					if tValue="" {
						set tValue=$$$nulindex
					}
					try {
						Set ^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"index",..currColumn,tValue,tKey)=""
					}
					catch tException {
							// If this is a subscript error on a collated value then the value is too long. Truncate it.
						if (tException.Name = "<SUBSCRIPT>") && (tCollated) {
							set tFiled = 0
								// First try simple truncation to the arbitrary first truncation limit = 250
							set tStart = $Select($Length(tValue)<250:$Length(tValue)-1,1:250)
							for tTruncation = tStart:-1:1 {
								try {
									set ^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"index",..currColumn,$Extract(tValue,1,tTruncation),tKey)=""
									set tFiled = 1
								}
								catch tInnerException {
									if tException.Name '= "<SUBSCRIPT>" {
											// Re-throw the original exception
										throw tException
									}
								}
								quit:tFiled
							}
							if 'tFiled { throw tException }
						}
						else {
							throw tException
						}
					}
					Set tKey = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"data",tKey),1,tSnapData)
				}
			}
		}
	}
	ElseIf $IsObject(pRS) {
		#; get columns from result set
		Set tRSCols = pRS.%ResultColumnCount
		if (pRS.%IsA("%Library.ResultSet")) {
			For c = 1:1:tRSCols {
				Set tName = pRS.GetColumnName(c)
				Set:$D(tColNames(tName)) tName = "(duplicate) " _ tName // duplicate column name
				Set tColNames(tName) = c
				If (tColsFromQuery) {
					Set tColNums = tColNums + 1
					#; add column
					Set tColNums(c) = tName
					Set tColNums(c,"th") = pRS.GetColumnHeader(c)
					#; type--> 3:float,5:integer,10:string,12:binstream,13:charstream
					Set:pRS.GetColumnType(c)'=10 tColTypeByNum(c) = pRS.GetColumnType(c)
				}
				Else {
					#; pick up column type
					Set:pRS.GetColumnType(c)'=10 tColTypes(tName) = pRS.GetColumnType(c)
				}
			}
		}
		else {
			For c = 1:1:tRSCols {
					#dim tColumn as %SQL.StatementColumn
				set tRSMD = pRS.%GetMetadata()
				set tColumn = tRSMD.columns.GetAt(c)
				Set tName = tColumn.colName
				Set:$D(tColNames(tName)) tName = "(duplicate) " _ tName // duplicate column name
				Set tColNames(tName) = c
				If (tColsFromQuery) {
					Set tColNums = tColNums + 1
					#; add column
					Set tColNums(c) = tName
					Set tColNums(c,"th") = tColumn.label
					#; type--> 3:float,5:integer,10:string,12:binstream,13:charstream
					Set:tColumn.clientType'=10 tColTypeByNum(c) = tColumn.clientType
				}
				Else {
					#; pick up column type
					Set:tColumn.clientType'=10 tColTypes(tName) = tColumn.clientType
				}
			}
		}
	}

	#; styles for specialty columns
	Set tRowNumberStyle = ""
	Set tRowSelectorStyle = ""
	Set tRowCheckboxStyle = ""

	#; now walk over set of column spec objects 
	Set tCount = ..columns.Count()
	Set tHiddenCols = 0
	Set tNamedCols = ""
	For n=1:1:tCount {
		Set tColumn = ..columns.GetAt(n)
		Set tColId = tColumn.name
		If (tColumn.colName'="") Set tColId = tColumn.colName
		If (tColId'="") {
			Set tNamedCols(tColId) = n 
		}
		Set tHidden = +$$$ZENVAL(tColumn.hidden)
		Set:(tColumn.hidden'="")&&(tColumn.hidden'=tHidden) tColumn.hidden = tHidden // send resolved value to client
		Set tColName = $$$ZENVAL(tColumn.colName)
		Set tOrigName = tColName
		If ((..OnCreateResultSet="") && (..sql="") && (..queryClass="")) {
			#; for -> references we need to get the final piece of the name
			Set:tColName[">" tColName = $P(tColName,">",$L(tColName,">"))
			Set:tColName[" " tColName = $P(tColName," ",$L(tColName," "))
		}
		If (tColName = "$selector") {
			Set tRowSelectorStyle = tColumn.style
		}
		ElseIf (tColName = "$checkbox") {
			Set tRowCheckboxStyle = tColumn.style
		}
		ElseIf (tColName = "$rownumber") {
			Set tRowNumberStyle = tColumn.style
		}
		ElseIf (tColName '= "") {
			#; find corresponding column in query
			If ($D(tColNames(tColName))) {
				Set c = tColNames(tColName)
				If (tHidden) {
					#; remove/skip column, add to hidden list
					Set tHiddenCols = tHiddenCols + 1
					Set tHiddenCols(tHiddenCols) = tColName
					Kill:tColsFromQuery tColNums(c)
				}
				Else {
					If ('tColsFromQuery) {
						#; add column
						Set tColNums = tColNums + 1
						Set tColNums(tColNums) = tColName
						Set:$D(tColTypes(tColName)) tColTypeByNum(tColNums) = tColTypes(tColName)
						#; add spec to column
						Set tColNums(tColNums,"spec") = tColumn
						Set:tOrigName'=tColName tColNums(tColNums,"orig") = tOrigName
					}
					Else {
						#; add spec to column
						Set tColNums(c,"spec") = tColumn
						Set:tOrigName'=tColName tColNums(c,"orig") = tOrigName
					}
				}
			}
			ElseIf ('tColsFromQuery) {
				#; this is a named column with no data
				Set tColNums = tColNums + 1
				Set tColNums(tColNums) = tColName
				Set tColNums(tColNums,"spec") = tColumn
			}
		}
		Else {
			If ('tHidden) {
				#; this is an unnamed column
				Set tColNums = tColNums + 1
				Set tColNums(tColNums,"spec") = tColumn
			}
		}
	}

	#; now build the list of columns to display
	#; this is held in tColInfo
	#; tColInfo(n)=type  (action,data,dataAction,selector,rownum)
	#; tColInfo(n,"th")=header

	Set tHasFilters = 0
	Set tColCount = 0
	If (..showRowSelector && ..rowSelect) {
		Set tColCount = tColCount + 1
		Set tColInfo(tColCount) = "selector"
	}
	If (..multiSelect) {
		Set tColCount = tColCount + 1
		Set tColInfo(tColCount) = "checkbox"
	}
	If (..showRowNumbers) {
		Set tColCount = tColCount + 1
		Set tColInfo(tColCount) = "rownum"
	}

	#; if no column has width set, then use auto layout for table
	Set tAutoWidth = 1
	Set n = $O(tColNums(""))
	While (n '= "") {
		Set tColCount = tColCount + 1
		Set tColumn = $G(tColNums(n,"spec"))

		If ($G(tColNums(n)) '= "") {
			#; there is data for this column
			If $IsObject(tColumn) {
				If (tColumn.link="") {
					Set tColInfo(tColCount,"cls") = $S(..%IsTypeNumeric($G(tColTypeByNum(n))):"tpNum",1:"tpStr")
					Set tColInfo(tColCount) = "data"
				}
				Else {
					Set tColInfo(tColCount,"cls") = "tpAction"
					Set tColInfo(tColCount) = "dataAction"
					Set tColInfo(tColCount,"link") = tColumn.link
					Set:tColumn.linkConfirm'="" tColInfo(tColCount,"confirm") = tColumn.linkConfirm
					If (tColumn.linkImage'=""){
						Set tColInfo(tColCount,"linkImage")=tColumn.linkImage						
					}
				}

				If (tColumn.onclick'="") {
					Set tColInfo(tColCount,"cls") = "tpAction"
					Set tColInfo(tColCount) = "dataAction"
				}

				Set tHeader = $$$ZENVAL(tColumn.header)
				Set tWidth = $$$ZENVALHTML(tColumn.width)
				Set tStyle = $$$ZENVALHTML(tColumn.style)
				Set:tWidth'="" tAutoWidth = 0

				Set th = $S(tHeader'="":tHeader,1:$G(tColNums(n,"th"),tColNums(n)))
				Set:tStyle'="" tColInfo(tColCount,"style") = tStyle
				Set:tWidth'="" tColInfo(tColCount,"wid") = tWidth

				Set:tColumn.title'="" tColInfo(tColCount,"title") = tColumn.title
				Set:tColumn.cellTitle'="" tColInfo(tColCount,"cellTitle") = tColumn.cellTitle
				Set:tColumn.OnDrawCell'="" tColInfo(tColCount,"method") = tColumn.OnDrawCell
				Set:tColumn.seed'="" tColInfo(tColCount,"seed") = tColumn.seed
				Set:tColumn.onclick'="" tColInfo(tColCount,"onclick") = tColumn.onclick

				#; test for filter
				If (tColumn.filterType '= "") {
					Set tHasFilters = 1
					Set tColInfo(tColCount,"filter") = tColumn
				}
			}
			Else {
				#; use different style for numeric columns
				Set tColInfo(tColCount,"cls") = $S(..%IsTypeNumeric($G(tColTypeByNum(n))):"tpNum",1:"tpStr")
				Set tColInfo(tColCount) = "data"
				Set th = tColNums(n)
			}
			Set tColInfo(tColCount,"th") = th
			Set tColInfo(tColCount,"src") = tColNums(n)
			Set:$D(tColNums(n,"orig")) tColInfo(tColCount,"orig") = tColNums(n,"orig")
		}
		Else {
			#; no data for this column; must be an action
			Set tColInfo(tColCount) = "action"
			Set tColInfo(tColCount,"cls") = "tpAction"
			If $IsObject(tColumn) {
				Set tHeader = $$$ZENVAL(tColumn.header)
				Set tWidth = $$$ZENVALHTML(tColumn.width)
				Set tStyle = $$$ZENVALHTML(tColumn.style)

				Set:tHeader'="" tColInfo(tColCount,"th") = tHeader
				Set:tWidth'="" tColInfo(tColCount,"wid") = tWidth
				Set:tStyle'="" tColInfo(tColCount,"style") = tStyle

				Set:tColumn.linkCaption'="" tColInfo(tColCount,"caption") = tColumn.linkCaption
				Set:tColumn.title'="" tColInfo(tColCount,"title") = tColumn.title
				Set:tColumn.link'="" tColInfo(tColCount,"link") = tColumn.link
				Set:tColumn.linkImage'="" tColInfo(tColCount,"linkImage")=tColumn.linkImage				
				Set:tColumn.cellTitle'="" tColInfo(tColCount,"cellTitle") = tColumn.cellTitle
				Set:tColumn.linkConfirm'="" tColInfo(tColCount,"confirm") = tColumn.linkConfirm
				Set:tColumn.OnDrawCell'="" tColInfo(tColCount,"method") = tColumn.OnDrawCell
				Set:tColumn.seed'="" tColInfo(tColCount,"seed") = tColumn.seed
				Set:tColumn.onclick'="" tColInfo(tColCount,"onclick") = tColumn.onclick
			}
		}

		#; further preprocess some of the data
		If $D(tColInfo(tColCount,"link")) {
			#; Make sure we have tConfirmStrings populated for use in cleaning things up for the confirmation dialog
			If ($D(tColInfo(tColCount,"confirm")) && '$data(tConfirmStrings)) {
				Set tConfirmStrings("href") = " href="""
				Set tConfirmStrings("hrefLen") = $length(tConfirmStrings("href"))
				Set tConfirmStrings("js") = "javascript:"
				Set tConfirmStrings("jsLen") = $length(tConfirmStrings("js"))
				Set tConfirmStrings("titleTrail") = """ title="""
				Set tConfirmStrings("titleTrailLen") = $length(tConfirmStrings("titleTrail"))
			}
			#; see if link contains an expression
			If (tColInfo(tColCount,"link")["#(") {
				#; what type of escape to use?
				Set tExpr = tColInfo(tColCount,"link")
				Set tHasJS = $E(tExpr,1,11)="javascript:"
				Set tEsc = $S(tHasJS:"JS",1:"URL")

				Set tColInfo(tColCount,"Xlink") = "S %out="_##class(%ZEN.Utils).%ParseExpr(tExpr,tEsc,2)
				#; JMD1254: note that we still need more escapes
				If (tHasJS) {
					Set tColInfo(tColCount,"js") = 1
				}
				#; if we have a title we need to propagate it further down
				If $D(tColInfo(tColCount,"title")) {
					Set tColInfo(tColCount,"Xlink","title") = tColInfo(tColCount,"title")
				}
				Kill tColInfo(tColCount,"link")
			}
			Else {
				Set tColInfo(tColCount,"link") = " href="""_$ZCVT(tColInfo(tColCount,"link"),"O","HTML")_""""
				If $D(tColInfo(tColCount,"title")) {
					Set tColInfo(tColCount,"link") = tColInfo(tColCount,"link")_" title="""_$ZCVT(tColInfo(tColCount,"title"),"O","HTML")_""""
				}
			}
		}
		If $D(tColInfo(tColCount,"linkImage")) {
			#; see if linkImage contains an expression
			If (tColInfo(tColCount,"linkImage")["#(") {
				#; Only URL expression escaping is allowed for this
				Set tEsc = "URL"
				Set tColInfo(tColCount,"XlinkImage") = "S %out="_##class(%ZEN.Utils).%ParseExpr(tColInfo(tColCount,"linkImage"),tEsc,2)
				Kill tColInfo(tColCount,"linkImage")
			}
			Else {
				Set tColInfo(tColCount,"linkImage") = $ZCVT(tColInfo(tColCount,"linkImage"),"O","HTML")
			}
		}

		If $D(tColInfo(tColCount,"onclick")) {
			If (tColInfo(tColCount,"onclick")["#(") {
				Set tColInfo(tColCount,"Xonclick") = "S %out="_##class(%ZEN.Utils).%ParseExpr(tColInfo(tColCount,"onclick"),"JS",2)
				Kill tColInfo(tColCount,"onclick")
			}
			Else {
				Set tColInfo(tColCount,"onclick") = " onclick="""_$ZCVT(tColInfo(tColCount,"onclick"),"O","HTML")_""""
			}
		}
		
		If $D(tColInfo(tColCount,"cellTitle")) {
			Set tColInfo(tColCount,"cellTitle") = " title="""_$ZCVT(tColInfo(tColCount,"cellTitle"),"O","HTML")_""""
		}

		Set n = $O(tColNums(n))
	}

	#; build list of conditions for the table
	#; organized by column name
	For i=1:1:..conditions.Count() {
		Set tCondition = ..conditions.GetAt(i)
		If $IsObject(tCondition) {
			Set tTargetCol = $$$ZENVAL(tCondition.targetCol)
			Set tLocalName = tTargetCol
 			If (tTargetCol'="") {
				Set tTargetIdx = $G(tNamedCols(tTargetCol))
				If (tTargetIdx'="") {
					Set tLocalName = ..columns.GetAt(tTargetIdx).linkCaption
					If (tLocalName="") Set tLocalName = tTargetCol
				}
 			}
			Set tColName = $$$ZENVAL(tCondition.colName)
			If (tColName '="") {
				Set tCellStyle = $$$ZENVALHTML(tCondition.cellStyle)
				Set tRowStyle = $$$ZENVALHTML(tCondition.rowStyle)
				If (tCellStyle '= "") {
					#; cell condition
					Set tTargetCol = tLocalName
					Set tTarg = $S(tTargetCol'="":tTargetCol,1:tColName)
					Set idx = 1 + $G(tCellCondition(tTarg))
					Set tCellCondition(tTarg) = idx
					Set tCellCondition(tTarg,idx) = tCondition
				}
				If (tRowStyle '= "") {
					#; row condition
					Set idx = 1 + $G(tRowCondition)
					Set tRowCondition = idx
					Set tRowCondition(idx) = tCondition
				}
			}
		}
	}

	#; now draw the table
	Set ts = $S(tAutoWidth:" style=""table-layout:auto;""",1:"")
	&html<<table class="tpTable" border="1" cellspacing="#(..cellSpacing)#" cellpadding="0"#(ts)#>>
	If (..caption'="") { &html<<caption>#($ZCVT(..caption,"O","HTML"))#</caption>> }
	&html<<thead id="#(..%MakeId("tpHead"))#" class="tpHead">>

	#; width of special columns (rownum, etc.)
	Set xWid = ..extraColumnWidth

	#; draw headers based on layout
	If (..headerLayout = "headersOnTop") {
		Do DrawHeaders
		Do DrawFilters
	}
	Else {
		Do DrawFilters
		Do DrawHeaders
	}

	Goto DrawBody	

DrawFilters
	#; draw filters
	If (tHasFilters) {
		&html<<tr valign="bottom" id="#(..%MakeId("filterRow"))#" class="tpFilterRow" #($S(..showFilters:"",1:"style=""display: none;"""))#>>
		For n=1:1:tColCount {
			Set tFilter = $G(tColInfo(n,"filter"))
			Set src = $G(tColInfo(n,"orig"),$G(tColInfo(n,"src")))

			If ($IsObject(tFilter) && (src'="")) {
				#; see if the filter value comes from an expression
				Set evaluatedFilter=$S(tFilter.filterValue["#(":$$$ZENVAL(tFilter.filterValue),1:tFilter.filterValue)

				Set thw = $S($G(tColInfo(n,"wid"))="":"",1:" width="""_$G(tColInfo(n,"wid"))_"""")
				&html<<th valign="bottom" nowrap="1"#(thw)#>>
				If (tFilter.filterType = "custom") {
					#; invoke callback to draw filter
					Do ..%DrawFilter(tFilter.OnDrawFilter,src,tFilter)
				}
				Else { // built-in
					Set dis = $S(..filtersDisabled:"disabled",1:"")
					&html<<table class="tpFilterLayout" border="0" cellspacing="#(..cellSpacing)#" width="100%"><tr>>
					If ((tFilter.filterType = "date")||(tFilter.filterType = "datetime")) {
						If (tFilter.filterOp '= "BETWEEN") {
							#; single date box
							If (tFilter.filterLabel'="") {
								&html<<td class="tpFilterLabel" width="5%">#($ZCVT(tFilter.filterLabel,"O","HTML"))#</td>>
							}
							&html<<td nowrap="1"><input #(dis)# type="text" size="12" id="#(..%MakeId("filter1_"_src))#" #(..%Attr("title",tFilter.filterTitle))# class="tpFilterDate" value="#($ZCVT(evaluatedFilter,"O","HTML"))#" onkeypress="zenPage.getComponent(#(..index)#).filterKeyPressed(event,'#(src)#','date',1);" onchange="zenPage.getComponent(#(..index)#).filterChanged('#(src)#',true,'date',1);"/><input type="button" onclick="zenPage.getComponent(#(..index)#).showDateSelector('#(src)#',1,'#(tFilter.filterType)#','#(tFilter.minDate)#','#(tFilter.maxDate)#');" class="tpFilterButton" value="..."/></td>>
						}
						Else {							
							#; show 2 boxes to allow range entry
							Set t1 = $P(evaluatedFilter,",",1)
							Set t2 = $P(evaluatedFilter,",",2)
							Set c1 = $ZCVT($P(tFilter.filterLabel,",",1),"O","HTML")
							Set c2 = $ZCVT($P(tFilter.filterLabel,",",2),"O","HTML")
							If (c1'="") {
								&html<<td class="tpFilterLabel" width="5%">#(c1)#</td>>
							}
							&html<<td nowrap="1"><input #(dis)# type="text" size="12" id="#(..%MakeId("filter1_"_src))#" #(..%Attr("title",tFilter.filterTitle))# class="tpFilterDate" value="#($ZCVT(t1,"O","HTML"))#" onkeypress="zenPage.getComponent(#(..index)#).filterKeyPressed(event,'#(src)#','date',1);" onchange="zenPage.getComponent(#(..index)#).filterChanged('#(src)#',true,'date',1);"/><input type="button" onclick="zenPage.getComponent(#(..index)#).showDateSelector('#(src)#',1,'#(tFilter.filterType)#','#(tFilter.minDate)#','#(tFilter.maxDate)#');" class="tpFilterButton" value="..."/></td>>
							&html<</tr><tr>>
							If (c2'="") {
								&html<<td class="tpFilterLabel" width="5%">#(c2)#</td>>
							}
							&html<<td nowrap="1"><input #(dis)# type="text" size="12" id="#(..%MakeId("filter2_"_src))#" #(..%Attr("title",tFilter.filterTitle))# class="tpFilterDate" value="#($ZCVT(t2,"O","HTML"))#" onkeypress="zenPage.getComponent(#(..index)#).filterKeyPressed(event,'#(src)#','date',2);" onchange="zenPage.getComponent(#(..index)#).filterChanged('#(src)#',true,'date',2);"/><input type="button" onclick="zenPage.getComponent(#(..index)#).showDateSelector('#(src)#',2,'#(tFilter.filterType)#','#(tFilter.minDate)#','#(tFilter.maxDate)#');" class="tpFilterButton" value="..."/></td>>
						}
					}
					ElseIf (tFilter.filterType = "enum") {
						If (tFilter.filterLabel'="") {
							&html<<td class="tpFilterLabel" width="5%">#($ZCVT(tFilter.filterLabel,"O","HTML"))#</td>>
						}
						&html<<td nowrap="1"><select #(dis)# id="#(..%MakeId("filter1_"_src))#" #(..%Attr("title",tFilter.filterTitle))# class="tpFilter" onchange="zenPage.getComponent(#(..index)#).filterChanged('#(src)#',true);">>
						&html<<option value=""></option>>
						For p=1:1:$L(tFilter.filterEnum,",") {
							Set ev = $P(tFilter.filterEnum,",",p)
							Set ed = $S(tFilter.filterEnumDisplay="":ev,1:$P(tFilter.filterEnumDisplay,",",p))
							&html<<option #($S(evaluatedFilter=ev:"selected",1:""))# value="#($ZCVT(ev,"O","HTML"))#">#($ZCVT(ed,"O","HTML"))#</option>>
						}
						&html<</select></td>>
					}
					ElseIf (tFilter.filterType = "query") {
						If (tFilter.filterLabel'="") {
							&html<<td class="tpFilterLabel" width="5%">#($ZCVT(tFilter.filterLabel,"O","HTML"))#</td>>
						}
						#; execute the filter query
						#; (do this as part of snapshot)
						Set tError = ""
						Set tFqValCol = 1
						Set tFqDispCol = 1
						If (tFilter.filterQuery = "") {
							Set tError = "No query specified for filter"
						}
						Else {
							Set tSC = $$$OK
							Do {
								Set tRS = ##class(%ResultSet).%New()
								Set tSC = tRS.Prepare(tFilter.filterQuery)
								If $$$ISERR(tSC) Quit

								Set tSC = tRS.%Execute()
								If $$$ISERR(tSC) Quit

								If tRS.%ResultColumnCount > 1 {
									Set tFqDispCol = 2
								}
								
							} While(0)
							
							If $$$ISERR(tSC) {
								Do $System.Status.DecomposeStatus(tSC,.err)
								Set tError = $G(err(1))
							}
						}
						
						If (tError = "") {
							&html<<td nowrap="1"><select #(dis)# id="#(..%MakeId("filter1_"_src))#" #(..%Attr("title",tFilter.filterTitle))# class="tpFilter" onchange="zenPage.getComponent(#(..index)#).filterChanged('#(src)#',true);">>
							&html<<option value=""></option>>
							While (tRS.%Next(.tSC)) {
								If $$$ISERR(tSC) {
									Do $System.Status.DecomposeStatus(tSC,.err)
									Set tError = $G(err(1))
									Quit
								}
								Set ev = tRS.%GetData(tFqValCol)
								&html<<option #($S(evaluatedFilter=ev:"selected",1:""))# value="#($ZCVT(ev,"O","HTML"))#">#($ZCVT(tRS.%GetData(tFqDispCol),"O","HTML"))#</option>>
							}
							&html<</select></td>>
						}
						Set tRS = ""

						If (tError '= "") {
							&html<<td style="color:red;">#(tError)#</td>>
						}
					}
					Else {
						If (tFilter.filterLabel'="") {
							&html<<td class="tpFilterLabel" width="5%">#($ZCVT(tFilter.filterLabel,"O","HTML"))#</td>>
						}					
						&html<<td nowrap="1"><input #(dis)# type="text" id="#(..%MakeId("filter1_"_src))#" #(..%Attr("title",tFilter.filterTitle))# class="tpFilter" value="#($ZCVT(evaluatedFilter,"O","HTML"))#" onkeypress="zenPage.getComponent(#(..index)#).filterKeyPressed(event,'#(src)#');" onchange="zenPage.getComponent(#(..index)#).filterChanged('#(src)#',true);"/></td>>
					}
					&html<</tr></table>>
				}
				&html<</th>>
			}
			Else {
				Set wid = $Case(tColInfo(n),"checkbox":xWid,"rownum":xWid,"selector":xWid,:$G(tColInfo(n,"wid")))
				Set thw = $S(wid="":"",1:" width="""_wid_"""")
				&html<<th#(thw)#>&nbsp;</th>>
			}
		}
		#; add extra column for scrollbar
		If (..fixedHeaders) { &html<<th width="#($S(tIE:"10px",1:"7px"))#">&nbsp;</th>> }
	}
	Quit
DrawHeaders
	#; draw headers
	Set tUserColCount = 0

	&html<<tr>>
	For n=1:1:tColCount {
		Set type = tColInfo(n)
		Set thw = $S(xWid="":"",1:" width="""_xWid_"""")
		If (type = "selector") {
			&html<<th#(thw)# onclick="zenPage.getComponent(#(..index)#).headerClick('');">&nbsp;&nbsp;&nbsp;</th>>
		}
		ElseIf (type = "action") {
			Set title = $S($G(tColInfo(n,"title"))="":"",1:" title="""_$ZCVT(tColInfo(n,"title"),"O","HTML")_"""")
			Set thw = $S($G(tColInfo(n,"wid"))="":"",1:" width="""_$G(tColInfo(n,"wid"))_"""")
			&html<<th#(title)##(thw)# onclick="zenPage.getComponent(#(..index)#).headerClick('');">&nbsp;#($ZCVT($G(tColInfo(n,"th")),"O","HTML"))#&nbsp;</th>>
			Set tUserColCount = tUserColCount + 1
		}
		ElseIf (type = "checkbox") {
			&html<<th#(thw)#><input type="checkbox" id="chkAll" onclick="zenPage.getComponent(#(..index)#).cbHeaderClick(this);"/></th>>
		}
		ElseIf (type = "rownum") {
			&html<<th#(thw)# onclick="zenPage.getComponent(#(..index)#).headerClick('');">&nbsp;#</th>>
		}
		Else {
			Set tUserColCount = tUserColCount + 1
			Set tName = $G(tColInfo(n,"src"))
			Set cls = $S(..currColumn=tName:"class=""tpHdrSelected""",1:"")
			Set srt = $S(..currColumn=tName:$S(..sortOrder="asc":"&raquo;",..sortOrder="desc":"&laquo;",1:""),1:"")
			Set title = $S($G(tColInfo(n,"title"))="":"",1:" title="""_$ZCVT(tColInfo(n,"title"),"O","HTML")_"""")
			Set thw = $S($G(tColInfo(n,"wid"))="":"",1:" width="""_$G(tColInfo(n,"wid"))_"""")
			&html<<th#(title)# #(cls)##(thw)# id="#(..%MakeId("th_"_tName))#" onclick="zenPage.getComponent(#(..index)#).headerClick('#($ZCVT(tName,"O","JS"))#');">#($ZCVT($G(tColInfo(n,"th")),"O","HTML"))#&nbsp;#(srt)#</th>>
		}
	}
	#; add extra column for scrollbar
	If (..fixedHeaders) { &html<<th width="#($S(tIE:"10px",1:"7px"))#">&nbsp;</th>> }
	&html<</tr></thead>>
	Quit

DrawBody
	Set tBodyHeight = ..bodyHeight
	Set tBodyHeight = $S(tBodyHeight="":"20.0em",1:tBodyHeight)

	If (tIE && ..fixedHeaders) {
		#; for ie, we use 2 tables for fixed header
		&html<</table><div id="#(..%MakeId("tpBody"))#" class="tpBodyFixed" style="height: #(tBodyHeight)#;"><table class="tpTable" border="0" cellspacing="#(..cellSpacing)#" cellpadding="0"><tbody>>
	}
	Else {
		If (..fixedHeaders) {
			Set tBodyStyle = "height: "_tBodyHeight_";"
			If ((%request.UserAgent [ "MSIE")||(%request.UserAgent [ "Trident")) {
				#; Even in HTML5 mode IE has rendering bugs, can't handle cssHeight on tBody
				Set tBodyStyle = ""
			}			
			&html<<tbody id="#(..%MakeId("tpBody"))#" class="tpBodyFixed" style="#(tBodyStyle)#" >>
		}
		Else {
			Set tBodyHeight = $S(..bodyHeight="":"",1:"style=""height:"_..bodyHeight_"""")
			&html<<tbody class="tpBody" id="#(..%MakeId("tpBody"))#" #(tBodyHeight)#>>
		}
	}

	#; draw rows
	New %query,%out
	Set tRow = 0 // row within page
	Set tStartRow = (..currPage-1) * ..pageSize // starting query row for this page
	Set tKey = ""
	Set tVal = ""
	Set tMaxRows = $S(..pageSize=0:..maxRows,1:..pageSize)
	Set tSortOrder = $Case(..sortOrder,"asc":1,"desc":-1,:0)
	If (..useSnapshot && tSortOrder && (..currColumn'="") && (..snapshotId'="")) {
		#; find initial sort value
		Set tVal = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"index",..currColumn,""),tSortOrder)
	}
	
	#; get logical value of table
	Set tLogicalVal = $$$ZENVAL(..value)

	Set tMore = 1
	While ((tMaxRows=0)||(tRow<tMaxRows)) {
		#; get next row
		If (..useSnapshot && (..snapshotId'="")) {
			If (tSortOrder && (..currColumn'="") ) {
				#; use sort index
				Set tBeforeStart = (tRow=0)&&(tStartRow>0)
				Set tqRow = 0 // row in query
				If (tVal'="") {
					Do {
						Set tKey = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"index",..currColumn,tVal,tKey),tSortOrder)
						If (tKey = "") {
							#; try next value
							Set tVal = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"index",..currColumn,tVal),tSortOrder)
							Set:tVal'="" tKey = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"index",..currColumn,tVal,""),tSortOrder)
						}
						Set tqRow = tqRow + 1 
					} While (tBeforeStart && (tqRow <= tStartRow)) // loop until we get to first displayed row
				}

				Quit:tKey=""
				Set tSnapData = $G(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"data",tKey))
			}
			Else {
				#; use main temp file
				Set:(tRow=0)&&(tStartRow>0) tKey=(tStartRow)
				Set tKey = $O(^IRIS.Temp.zenData(%session.SessionId,..snapshotId,..index,"data",tKey),1,tSnapData)
				Quit:tKey=""
			}
		}
		ElseIf $IsObject(pRS) {
			If 'pRS.%Next(.tSC) {
				Set tMore = 0
				Quit
			}
			Quit:$$$ISERR(tSC)
		}
		Else {
			Quit
		}
		Set tRow = tRow + 1

		#; copy data for this row into %query
		Kill %query
		For n=1:1:tColCount {
			#; get col value
			Set tName = $G(tColInfo(n,"src"))
			If (tName'="") {
				If (..useSnapshot) {
					Set c = tColNames(tName)
					Set %query(tName) = $LG(tSnapData,c)
				}
				Else {
					Set %query(tName) = pRS.%Get(tName)
					Set:(%query(tName)=$c(0)) %query(tName) = ""
				}
			}
		}

		#; get data values for hidden columns
		For n=1:1:tHiddenCols {
			#; get col value
			Set tName = $G(tHiddenCols(n))
			If (tName'="") { 
				If (..useSnapshot) {
					Set c = tColNames(tName)
					Set %query(tName) = $LG(tSnapData,c)
				}
				Else {
					Set %query(tName) = pRS.%Get(tName)
					Set:(%query(tName)=$c(0)) %query(tName) = ""
				}
			}
		}

		Set tStatus = ""

		If (..showZebra) {
			Set tStatus = $S(tRow#2=0:"tpEven",1:"tpOdd")
		}
		Else {
			Set tStatus = "tpRow"
		}

		If (tStatus '= "") {
			Set tRowCls = "class="""_tStatus_""""
		}
		Else {
			Set tRowCls = ""
		}

		Set tRowStyle = ""

		#; see if there are any row conditions
		Set tName = $O(tRowCondition(""))
		While (tName '= "") {
			#; evaluate condition
			Set tCondition = tRowCondition(tName)
			Set tEval = tCondition.Eval(.%query)
			If (tEval) {
				Set tRowStyle = "style=""" _ $$$ZENVALHTML(tCondition.rowStyle) _ """"
				Quit
			}
			Set tName = $O(tRowCondition(tName))
		}

		#; if there is a valueColumn, get it
		Set tDataVal = ""
		If (..valueColumn'="") {
			Set v = $G(%query(..valueColumn))
			If (v = tLogicalVal) {
				#; this row matches the current value of the table
				#; select it
				Set ..selectedIndex = tRow - 1
			}
			Set tDataVal = "zenValue="""_$ZCVT(v,"O","HTML")_""""
		}
		
		// check onmouseover/onmouseout behaviour
		If (..onmouseoverClass '= "") {
			Set tMouseover = "onmouseover=""zenPage.getComponent('"_..index_"').onmouseHandler('"_(tRow-1)_"',true);"" onmouseout=""zenPage.getComponent('"_..index_"').onmouseHandler('"_(tRow-1)_"',false);"""
		}
		Else {
			Set tMouseover = ""
		}
		&html<<tr #(tDataVal)# #(tRowCls)# #(tRowStyle)# id="#(..%MakeId("tr_"_(tRow-1)))#" onclick="zenPage.getComponent(#(..index)#).clickHandler(#(tRow-1)#);" ondblclick="zenPage.getComponent(#(..index)#).dblclickHandler();" #(tMouseover)#>>
		Set tdwid = $S(tRow=1:" width="""_..extraColumnWidth_"""",1:"")
	
		#; loop over columns
		For n=1:1:tColCount {
			Set type = tColInfo(n)
			If (type = "selector") {
				&html<<td class="tpSel" style="#(tRowSelectorStyle)#" id="#(..%MakeId("selector_"_(tRow-1)))#"#(tdwid)#>&nbsp;</td>>
			}
			ElseIf (type = "checkbox") {
				Set sel = $S($P(..selectedRows,",",tRow+tStartRow)'="":"checked=""1""",1:"")
				&html<<td class="tpCB"#(tdwid)# style="#(tRowCheckboxStyle)#">>
				#; Check if user has condition for checkbox:
				Set tCheckCondition = +$G(tCellCondition("checkbox"))
				If tCheckCondition '= 0 {
					#; If condition is set, check it now
					Set tCondition = $G(tCellCondition("checkbox",tCheckCondition))
					#; If condition met, then checkbox will not be built
					Set tCheckCondition = tCondition.Eval(.%query)		
				}
				#; Build checkbox if no condition for checkbox, or if condition failed:
				If 'tCheckCondition {
					&html<<input type="checkbox" #(sel)# id="#(..%MakeId("cb_"_(tRow-1)))#" onclick="zenPage.getComponent(#(..index)#).cbClick(this,#(tRow-1)#);"/>>
				}
				&html<</td>>
			}
			ElseIf (type = "rownum") {
				&html<<td class="tpRNum" style="#(tRowNumberStyle)#" align="right"#(tdwid)#>#(tRow+tStartRow)#</td>>
			}
			Else {
				Set tADisabled = ""
				Set tHREF = ""
				Set tCellClass = $G(tColInfo(n,"cls"))
				Set tCellStyle = $G(tColInfo(n,"style"))

				#; see if there are cell conditions for this column
				#;YSD2262 - allow to disable/hide action link
				#;YSD2262 If ((type = "data")||(type = "dataAction")) {
				If ((type = "data")||(type = "dataAction")||(type="action")) {
					Set sub = $S(type'="action":"src",1:"caption")
					If $G(tColInfo(n,sub)) '= "" {
					Set idx = $O(tCellCondition(tColInfo(n,sub),""))
					While (idx '= "") {
						#; evaluate condition
						Set tCondition = tCellCondition(tColInfo(n,sub), idx)
						Set tEval = tCondition.Eval(.%query)
						If (tEval) {
							Set tCellStyle = tCellStyle _ $$$ZENVALHTML(tCondition.cellStyle)
							If (tCondition.cellStyle [ "disabled") {
								Set tADisabled = "disabled"
							}
							Quit
						}
						Set idx = $O(tCellCondition(tColInfo(n,sub),idx))
					}
					}
				}
				If (..nowrap) {
					Set tCellStyle = tCellStyle _ "white-space:nowrap;"
				}
				
				#; IE does not recognize white-space: nowrap;
				#; so we have special code for it
				#; YSD2825 - removed this to make html5 validation pass. "nowrap" is an attribute and should not be inside style anyway.
				#; If (..nowrap) {
				#;	Set tCellStyle = tCellStyle _ " nowrap"
				#;}
				Set:tCellStyle'="" tCellStyle=" style="""_tCellStyle_""" "
				
				If ((type = "data")||(type = "dataAction")) {
					Set ttl = $S(..showValueInTooltip:" title="""_$ZCVT(%query(tColInfo(n,"src")),"O","HTML")_"""",1:$G(tColInfo(n,"cellTitle")))
				}
				Else {
					Set ttl = $G(tColInfo(n,"cellTitle"))
				}

				#; don't use &html in inner loop to make sure HTML is tight and CR/LF free
				#; add width information for first row (if not "")
				Write "<td",$S(tCellClass="":"",1:" class="""_tCellClass_""""),tCellStyle,ttl,$S((tRow=1)&&($G(tColInfo(n,"wid"))'=""):" width="""_$G(tColInfo(n,"wid"))_"""",1:""),">"
				If (tIE && ..nowrap) {
					Write "<span style='white-space:nowrap;overflow:hidden;'>"
				}
				If ($G(tColInfo(n,"method"))'="") {
					Do ..%DrawCell($G(tColInfo(n,"method")),$G(tColInfo(n,"src")),$G(tColInfo(n,"seed")))
				}
				Else {
					If ((type = "action")||(type = "dataAction")) {					
						#; get link: see if we have to evaluate expr
						Set tCLICK = ""
						Set tRawOut = ""
						If ($D(tColInfo(n,"Xlink"))) {
							#; result is in %out
							X tColInfo(n,"Xlink")
							Set tRawOut = $get(%out)

							// JMD1254: apply additional encoding:
							If (+$G(tColInfo(n,"js"))) {
								// first split off "javascript:"
								Set %out = $P(%out,"javascript:",2,9999)
								Set %out = $ZCVT(%out,"O","UTF8")
								Set %out = $ZCVT(%out,"O","URL")
								Set %out = $ZCVT(%out,"O","HTML")
								Set tHREF = " href=""javascript:"_%out_""""
							}
							Else {
								Set tHREF = " href="""_$ZCVT(%page.%Link(%out),"O","HTML")_""""
							}
							#; check if we need a title for the link
							If ($D(tColInfo(n,"Xlink","title"))) {
								Set tHREF = tHREF_" title="""_$ZCVT(tColInfo(n,"Xlink","title"),"O","HTML")_""""
							}
						}
						Else {
							Set tHREF = %page.%Link($G(tColInfo(n,"link")))
						}
	
						#; get onclick: see if we have to evaluate expr
						If ($D(tColInfo(n,"Xonclick"))) {
							#; result is in %out
							X tColInfo(n,"Xonclick")
							Set tCLICK = " onclick="""_$ZCVT(%out,"O","HTML")_""""
						}
						Else {
							Set tCLICK = %page.%Link($G(tColInfo(n,"onclick")))
						}

						#; test for confirm message; note that tRawOut is set in "Xlink" (if at all)
						If ($D(tColInfo(n,"confirm")) && (tCLICK="")) {
							Set tConfirmText = tColInfo(n,"confirm")
							If (tConfirmText["%1") && (tRawOut'="") {
								Set tConfirmName = $P($P(tRawOut,"'",2),"'",1)
								Set tConfirmText = $$$FormatText(tConfirmText,tConfirmName)
							}
							//Set tCLICK = "onclick=""return confirm('" _ $ZCVT($ZCVT(tConfirmText,"O","HTML"),"O","JS") _ "');"""
							If ($D(tColInfo(n,"Xlink"))) {
								#; result is in %out
								X tColInfo(n,"Xlink")
								Set cLink = %page.%Link(%out)
							}
							Else {
								Set cLink = %page.%Link($G(tColInfo(n,"link")))
							}
							Set tTitle=$S($G(tColInfo(n,"Xlink","title"))'="": tColInfo(n,"Xlink","title"),$G(tColInfo(n,"title"))'="":$G(tColInfo(n,"title")),$G(tColInfo(n,"caption"))'="":$G(tColInfo(n,"caption")),1:"")
							Set tWidth = $L(tConfirmText)*10
							Set tWidth = $S(tWidth<320:320,tWidth>800:800,1:tWidth)
							Set tHeight = 200+(($L(tConfirmText)\80)*19)
							Set tHREF = " href=""#"""
							If (tTitle '= "") {
								Set tHREF = tHREF _ " title=""" _ $zconvert(tTitle,"O","HTML") _ """"
							}
							If cLink [ "&#" Set cLink = $zconvert(cLink,"I","HTML")
							#; strip trailing ' title="..."'
							Set tConfirmTitlePos = $find(cLink,tConfirmStrings("titleTrail"))
							If tConfirmTitlePos {
								Set cLink = $extract(cLink,1,tConfirmTitlePos-1-tConfirmStrings("titleTrailLen"))
							}
							#; strip leading ' href="' prefix and trailing '"'
							If $extract(cLink,1,tConfirmStrings("hrefLen")) = tConfirmStrings("href") {
								Set cLink = $extract(cLink,tConfirmStrings("hrefLen")+1,*)
								If ($extract(cLink,*) = """") {
									Set cLink = $extract(cLink,1,*-1)
								}
							}
							#; strip leading "javascript:"
							If $extract(cLink,1,tConfirmStrings("jsLen")) = tConfirmStrings("js") {
								Set cLink = $extract(cLink,tConfirmStrings("jsLen")+1,*)
							}
							#; Convert "[URL]" to document.location = '[URL]'
							ElseIf cLink '= "" {
								Set cLink = "document.location = '" _ $zconvert(cLink,"O","JS")_"';"
							}
							Set tConfirmParms = "{Msg1:'"_$zconvert($zconvert(tConfirmText,"O","JS"),"O","HTML")_"',Title:'"_$zconvert($zconvert(tTitle,"O","JS"),"O","HTML")_"',Link:'"_$zconvert($zconvert(cLink,"O","JS"),"O","HTML")_"'}"
							Set tCLICK = " onclick=""zen('"_$this.id_"').launchConfirmDialog(zenLink('%ZEN.Dialog.confirmationDialog.cls'),'confirmationDialog','resizable,width="_tWidth_",height="_tHeight_"',"_tConfirmParms_"); return false;"""
						}
						#;YSD2262 Write "<a",tHREF,$G(tColInfo(n,"cellTitle")),tADisabled,tCLICK,">"
						If tADisabled = "" {
							Write "<a",tCellStyle,tHREF,$G(tColInfo(n,"cellTitle")),tCLICK,">"
						} Else {
							If type = "dataAction" Write $G(tColInfo(n,"cellTitle"))
						}
					}

					If ((type = "data")||(type = "dataAction")) {
						#; data value
						Set tDataVal = %query(tColInfo(n,"src"))
						Write $S((tDataVal="")||(tDataVal=$C(0)):"&nbsp;",1:$ZCVT(tDataVal,"O","HTML"))
					}
					Else {
						#; check if we have an image:
						if ($D(tColInfo(n,"XlinkImage"))){
							#; result is in %out
							X tColInfo(n,"XlinkImage")
							Write "<img src="""_$ZCVT(%page.%Link(%out),"O","HTML")_"""/>"
						} elseif ($D(tColInfo(n,"linkImage"))) {
							Set tCaption = $G(tColInfo(n,"caption"),$S($G(tHREF)="":"",1:"link"))
							Write "<img src="""_$ZCVT(tColInfo(n,"linkImage"),"O","HTML")_""""_$S(tCaption'="":" alt="""_tCaption_"""",1:"")_"/>"
						} else {
						#; action caption (if we have a link and no caption, show "link")
						Set tCaption = $G(tColInfo(n,"caption"),$S($G(tHREF)="":"",1:"link"))
						#;YSD2262 Write $S(tCaption="":"&nbsp;",1:$ZCVT(tCaption,"O","HTML"))
						 Write $S(tCaption="":"&nbsp;",tADisabled=""!(type="dataAction"):$ZCVT(tCaption,"O","HTML"),1:"-")
					}
					}
	
					If ((type = "action")||(type = "dataAction")) {
						#;YSD2262 Write "</a>"
						If tADisabled = "" Write "</a>"
					}
				}
				If (tIE && ..nowrap) { Write "</span>" }
				&html<</td>>
			}
		}
		&html<</tr>>
	}

	If ((tRow = 0)&&(..initialExecute)) {
		#; draw indicator of no results (unless deferred executed)
		Set msgNoResults = $S(..msgNoResult'="":..msgNoResult,1:$$$Text("No Results","%ZEN"))
		If ($Data(tColInfo)) {
			Set type = tColInfo(1)
			If ((type '= "data")&&(type '= "dataAction")) {
				&html<<td colspan="#(tColCount-tUserColCount)#" width="1%">&nbsp;</td>>
			}
		}
		&html<<td colspan="#(tUserColCount)#" width="99%" class="tpNoResults">&nbsp;#(msgNoResults)#</td>>
	}

	#; if not in snapshot mode, update rowCount
	If ('..useSnapshot) {
		Set ..rowCount = tRow _ $S(tMore:"+",1:"")
	}

	&html<<tr><td style="border:none;height:99%" colspan="#(tColCount)#" class="tpPadRow"></td></tr></tbody></table>>
	If (tIE && ..fixedHeaders) { &html<</div>> }

	Kill %query
	Quit tSC
}

///  Invoke user method to provide contents for a cell
Method %DrawCell(pMethod As %String, pName As %String, pSeed As %String) As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	#; invoke method
	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (pMethod '= "")) {
		Set tSC = $zobjmethod(tHost,pMethod,##this,pName,pSeed)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Write $ZCVT($ZE,"O","HTML")
	Goto Done
}

///  Invoke user method to provide contents for a column filter.
Method %DrawFilter(pMethod As %String, pName As %String, pColInfo As %ZEN.Auxiliary.column) As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	#; invoke method
	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (pMethod '= "")) {
		Set tSC = $zobjmethod(tHost,pMethod,##this,pName,pColInfo)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Write $ZCVT($ZE,"O","HTML")
	Goto Done
}

///  Create a temporary snapshot file from a result set.
///  Assumes that result set has been created and executed.
///  Users should not call this method.
Method %CreateSnapshot(pTempID As %String, pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK

	#; clear out temp file
	Kill ^IRIS.Temp.zenData(%session.SessionId,pTempID,..index)

	Do {
		If ('$IsObject(pRS)) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid result set object")
			Quit
		}
		if (pRS.%IsA("%Library.ResultSet")) {
			#; get column metadata
			Set cols = pRS.GetColumnCount()
			For c = 1:1:cols {
				Set tCols(c) = pRS.GetColumnName(c)
				Set th = pRS.GetColumnHeader(c)
				Set:tCols(c)'=th tCols(c,"th") = th

				#; note: 10 is string and is the default
				Set:pRS.GetColumnType(c)'=10 tCols(c,"type") = pRS.GetColumnType(c)
			}
		}
		else {
			#; get column metadata
			#dim tColumn as %SQL.StatementColumn
			Set cols = pRS.%ResultColumnCount
			set tRSMD = pRS.%GetMetadata()
			For c = 1:1:cols {
				set tColumn = tRSMD.columns.GetAt(c)
				Set tCols(c) = tColumn.colName
				Set th = tColumn.label
				Set:tCols(c)'=th tCols(c,"th") = th

				#; note: 10 is string and is the default
				Set:tColumn.clientType'=10 tCols(c,"type") = tColumn.clientType
			}
		}

		#; remember column info
		Merge ^IRIS.Temp.zenData(%session.SessionId,pTempID,..index,"info") = tCols

		#; do not fetch more than maxRows rows
		Set tMaxRows = ..maxRows		
		Set row = 0
		Set tMore = 0
		While (pRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If ((tMaxRows>0)&&(row>=tMaxRows)) {
				Set tMore = 1
				Quit
			}
			Set row = row + 1
			Set tValList = ""
			For c = 1:1:cols {
				#; fill in temp file
				#; 3:float,5:integer,10:string,12:binstream,13:charstream
				Set tColType = $G(tCols(c,"type"),10)
				If (tColType=12) {
					Set tVal = "[BinaryStream]"		// BINARYSTREAM
				}
				ElseIf (tColType = 13) {			// CHARACTERSTREAM
					Set tVal = "[CharacterStream]"	
				}
				Else {
					Set tVal = pRS.%Get(tCols(c))
				}
				Set $List(tValList,c) = tVal
			}
			Set ^IRIS.Temp.zenData(%session.SessionId,pTempID,..index,"data",row) = tValList
		}
		Set ..rowCount = row _ $S(tMore:"+",1:"")
	} While (0)

	Quit tSC
}

///  Add a new column definition to this tablePane.
///  If <var>pColumn</var> is not provided, this method will create
///  a new column object.
Method %AddColumn(pColumn As %ZEN.Auxiliary.column = "") As %ZEN.Auxiliary.column
{
	If '$IsObject(pColumn) {
		Set pColumn = ##class(%ZEN.Auxiliary.column).%New()
	}
 	Do ..columns.Insert(pColumn)
	Do:$IsObject(%page) %page.%AddComponent(pColumn)
	Quit pColumn
}

///  Add a new parameter definition to this tablePane.
///  If <var>pParm</var> is not provided, this method will create
///  a new parameter object.
Method %AddParameter(pParm As %ZEN.Auxiliary.parameter = "") As %ZEN.Auxiliary.parameter
{
	If '$IsObject(pParm) {
		Set pParm = ##class(%ZEN.Auxiliary.parameter).%New()
	}
 	Do ..parameters.Insert(pParm)
	Do:$IsObject(%page) %page.%AddComponent(pParm)
	Quit pParm
}

///  User has clicked on a column header.
ClientMethod headerClick(name) [ Language = javascript ]
{
	// JMD: test if this column can sort
	var colInfo = null;
	for (var c = 0; c < this.columns.length; c++) {
		colInfo = this.columns[c];
		if (colInfo && colInfo.colName==name) {
			break;
		}
		colInfo = null;
	}

	if (colInfo && colInfo.disableSort) {
		// no sort, but invoke callback anyway
		if ('' != this.onheaderClick) {
			zenInvokeCallbackMethod(this.onheaderClick,this,'onheaderClick');
		}
		return;
	}

	if (this.currColumn == name) {
		// change sort order
		switch (this.sortOrder) {
		case 'asc':
			this.sortOrder = 'desc';
			break;
		case 'desc':
			// end sort; unselect column
			var th = this.findElement('th_'+this.currColumn);
			if (th) {
				th.className = '';
			}
			this.sortOrder = '';
			this.currColumn = '';
			break;
		default:
			this.sortOrder = 'asc';
			break;			
		}
	}
	else {
		// new column
		if ('' != this.currColumn) {
			var th = this.findElement('th_'+this.currColumn);
			if (th) {
				th.className = '';
			}
		}

		this.currColumn = name;
		if ('' != this.currColumn) {
			var th = this.findElement('th_'+this.currColumn);
			if (th) {
				th.className = 'tpHdrSelected';
			}
			this.sortOrder = 'asc';
		}
		else {
			this.sortOrder = '';
		}
	}

	// invoke user callback
	var go = this.useSnapshot;
	if ('' != this.onheaderClick) {
		go = zenInvokeCallbackMethod(this.onheaderClick,this,'onheaderClick');
	}

	if (go) {
		// execute sort logic
		this.currPage = 1; // go back to first page
		this.selectAllMultiRows(false);
		this.refreshTable();
	}

	return true;
}

///  User has pressed a key within a filter.
ClientMethod filterKeyPressed(evt, filterName, type, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	// trap keys
	switch(evt.keyCode) {
	case zenENTER:
		this.filterChanged(filterName,true,type,index);
		return false;
	}
	
	return true;
}

///  User has changed the value of a filter.
///  <var>filterName</var> is the name of the filter.<br>
///  <var>refresh</var> indicates if the query should be re-executed.<br>
///  <var>type</var> (optional) is type of filter.<br>
///  <var>index</var> (optional) is control index for filters with multiple controls.<br>
ClientMethod filterChanged(filterName, refresh, type, index) [ Language = javascript ]
{
	// find column associated with filter
	for (var n in this.columns) {
		var column = this.columns[n];
		if (filterName == column.getColName() && '' != column.filterType) {
			var ctrl = this.findElement("filter1_" + filterName);
			if (ctrl){
				if ('date'==type && 1==index) {
					// parse user entry
					ctrl.value = zenParseDate(ctrl.value);
					if (-1 == ctrl.value) {
						ctrl.value = this.invalidMessage;
						refresh = false;
					}
				}
				column.filterValue = ctrl.value;
				this.lastFilter = filterName;
			}
			// test for 2nd filter for range filter
			var ctrl2 = this.findElement("filter2_" + filterName);
			if (ctrl2){
				if ('date'==type && 2==index) {
					// parse user entry
					ctrl2.value = zenParseDate(ctrl2.value);
					if (-1 == ctrl2.value) {
						ctrl2.value = this.invalidMessage;
						refresh = false;
					}
				}
				column.filterValue = column.filterValue + "," + ctrl2.value;
			}
			break;
		}
	}

	if (refresh) {
		this.applyFilters();
		var ctrl = this.findElement((index==2) ? "filter2_" : "filter1_" + filterName);
		if (ctrl){
			ctrl.focus();
		}
	}
}

///  If we are in autoExecute mode, then re-execute the query
///  for this table using the current value of any column filters.
///  If we are not in autoExecute mode, then do nothing. 
ClientMethod applyFilters() [ Language = javascript ]
{
	if (this.autoExecute && !this.filtersDisabled) {
		this.executeQuery();
		return true;
	}
	return false;
}

///  Reset the values of the column filters (if there are any).
ClientMethod resetColumnFilters() [ Language = javascript ]
{
	for (var n in this.columns) {
		var column = this.columns[n];
		if ('' != column.getColName() && '' != column.filterType) {
			column.filterValue = '';
			var ctrl = this.findElement("filter1_" + column.getColName());
			if (ctrl) {
				ctrl.value = '';
			}
			var ctrl2 = this.findElement("filter2_" + column.getColName());
			if (ctrl2) {
				ctrl2.value = '';
			}
		}
	}
}

///  Disable (or enable) the column filters for this table.
ClientMethod disableColumnFilters(flag) [ Language = javascript ]
{
	this.filtersDisabled = flag;

	for (var n in this.columns) {
		var column = this.columns[n];
		if ('' != column.getColName() && '' != column.filterType) {
			// loop over control (there may be multiples)
			var n = 1;
			while((ctrl = this.findElement("filter"+n+"_" + column.getColName())) != null) {
				ctrl.disabled = flag;
				n++;
			}
		}
	}
}

///  Get current value of column filter associated with column <var>cname</var>.
ClientMethod getFilterValue(cname) [ Language = javascript ]
{
	var value = '';

	// find column with name cname
	for (var n in this.columns) {
		var column = this.columns[n];
		if (cname == column.getColName()) {
			value = column.filterValue;
			break;
		}
	}

	return value;
}

///  Set the value of column filter associated with column <var>cname</var>.
ClientMethod setFilterValue(cname, value) [ Language = javascript ]
{
	// find column with name cname
	for (var n in this.columns) {
		var column = this.columns[n];
		if (cname == column.getColName()) {
			column.filterValue = value;

			// apply value to control
			if ('' != column.filterType) {
				// test for multiple controls
				var multi = this.findElement("filter2_" + column.getColName());
				var s = value.split(',');

				// loop over control (there may be multiples)
				var n = 1;
				while((ctrl = this.findElement("filter"+n+"_" + column.getColName())) != null) {
					ctrl.value = !multi ? value : (s[n-1] ? s[n-1] : '');
					n++;
				}
			}

			break;
		}
	}
}

///  Get column filters (if there are any).
///  Returns an associative array containing the current
///  values of the filter controls indexed by column name.
ClientMethod getColumnFilters() [ Language = javascript ]
{
	var out = new Object();
	for (var n in this.columns) {
		var column = this.columns[n];
		if ('' != column.getColName() && '' != column.filterType) {
			out[column.getColName()] = column.filterValue;
		}
	}
	
	return out;
}

///  Set the value of all column filters (if there are any).
///  <var>state</var> is an associative array containing the current
///  values of the filter controls indexed by column name (as
///  returned by <method>getColumnFilters</method>.
ClientMethod setColumnFilters(state) [ Language = javascript ]
{
	for (var n in state) {
		this.setFilterValue(n,state[n]);
	}
}

///  Show or hide columns filters (if there are any).
///  Users should use setProperty('showFilters',true) instead.
ClientMethod showColumnFilters(flag) [ Language = javascript ]
{
	this.showFilters = flag;

	// find filterRows
	var tr = this.findElement('filterRow');
	if (tr) {
		tr.style.display = flag ? '' : 'none';
	}
}

///  Display date selector for a date filter box.
ClientMethod showDateSelector(cname, index, type, minDate, maxDate) [ Language = javascript ]
{
	if (this.filtersDisabled) return false;

	// get control value
	var ctrl = this.findElement("filter"+index+"_" + cname);
	zenASSERT(ctrl,'Unable to find filter element',arguments);
	var value = ctrl.value;

	// find position of control
	var top,left;
	var top = zenGetTop(ctrl) + ctrl.offsetHeight - zenGetTopScroll(ctrl);
	var left = zenGetLeft(ctrl) - zenGetLeftScroll(ctrl);

	// adjust for window scroll bars
	top += zenGetPageScrollTop();
	left += zenGetPageScrollLeft();

	var group = zenPage.createComponent('modalGroup');
	group.setProperty('seed',cname+":"+index);
	group.setProperty('onaction','zenPage.getComponent('+this.index+').setDateFilter(group);');
	if ('datetime' == type) {
		var calParms = new Object();
		
		if ('' != minDate) {
			var minD = zenParseDate(minDate);
			if (-1 != minD) {
				var year = parseInt(minD.substr(0,4),10);
				calParms['minDate'] =minDate;
				calParms['startYear'] = year;
			}
		}
		if ('' != maxDate) {
			var maxD = zenParseDate(maxDate);
			if (-1 != maxD) {
				var year = parseInt(maxD.substr(0,4),10);
				calParms['maxDate'] = maxDate;
				calParms['endYear'] = year;
			}
		}
		calParms['showTime'] = true;
		group.show('','calendar',value,top,left,null,null,calParms);
	}
	else {
		group.show('','calendar',value,top,left);
	}
}

///  Set value of date filter box. index is 0 or 1 to indicate
///  which date box to set.
ClientMethod setDateFilter(group) [ Language = javascript ]
{
	var value = group.getValue();
	var seed = group.seed.split(':');
	var cname = seed[0];
	var index = seed[1];

	// update control
	var ctrl = this.findElement("filter"+index+"_" + cname);
	if (ctrl) {
		ctrl.value = value;
		this.filterChanged(cname,true);
	}
}

///  For multi-page display, calculate the number of pages.
ClientMethod getPageCount() [ Language = javascript ]
{
	var rc = parseInt(this.rowCount,10);
	if (!isNaN(rc) && rc > 0 && this.pageSize > 0) {
		return Math.floor(rc / this.pageSize) + ((rc % this.pageSize) ? 1 : 0);
	}
	return 1;
}

///  For multi-page display, go to previous page, if possible.
///  If <var>giveFocus</var> is true, then give focus back to
///  the  hidden control.
ClientMethod previousPage(giveFocus) [ Language = javascript ]
{
	if (this.currPage > 1) {
		//this.selectAllMultiRows(false);
		this.selectRow(-1);
		this.currPage--;
		this.hasFocus = (giveFocus) ? true : false;
		this.refreshTable();
	}
}

///  For multi-page display, go to next page, if possible.
ClientMethod nextPage(giveFocus) [ Language = javascript ]
{
	if (this.currPage < this.getPageCount()) {
		//this.selectAllMultiRows(false);
		this.selectRow(-1);
		this.currPage++;
		this.hasFocus = (giveFocus) ? true : false;
		this.refreshTable();
	}
}

///  For multi-page display, go to the first page.
ClientMethod firstPage() [ Language = javascript ]
{
	if (1 != this.currPage) {
		//this.selectAllMultiRows(false);
		this.selectRow(-1);
		this.currPage = 1;
		this.refreshTable();
	}
}

///  For multi-page display, go to the last page.
ClientMethod lastPage() [ Language = javascript ]
{
	if (this.getPageCount() != this.currPage) {
		//this.selectAllMultiRows(false);
		this.selectRow(-1);
		this.currPage = this.getPageCount();
		this.refreshTable();
	}
}

///  For multi-page display, go to specified page (1 is first page), if possible.
ClientMethod gotoPage(page) [ Language = javascript ]
{
	if (page >= 1 && page != this.currPage && page <= this.getPageCount()) {
		//this.selectAllMultiRows(false);
		this.selectRow(-1);
		this.currPage = page;
		this.refreshTable();
	}
}

///  Associate a navigator component with this tablePane.
///  This is called by the navigator component.
ClientMethod addNavigator(nav) [ Language = javascript ]
{
	this.navigator = nav;
}

///  Remove the navigator component with this tablePane.
///  This is called by the navigator component.
ClientMethod removeNavigator() [ Language = javascript ]
{
	this.navigator = null;
}

///  Force query for this table to be executed on the server.
///  If the table is in snapshot mode, then a new snapshot will
///  be created.<br>
///  If <var>remember</var> is true, then the table will
///  stay on the same page after the new results are displayed.
///  If <var>sync</var> is defined and is true, the refresh will be executed
/// synchronously (unless we are in deferred mode).
ClientMethod executeQuery(remember, sync) [ Language = javascript ]
{
	if (!remember) {
		this.currPage = 1; // go back to first page
	}
	this.selectAllMultiRows(false);
	if (this.useSnapshot) {
		this.clearSnapshot = true; // force query execution
		this.refreshTable(sync);
		this.clearSnapshot = false;
	}
	else {
		this.refreshTable(sync);
	}
}

///  For tables in snapshot mode only.<br>
///  Go to the server and fetch the data for the specified row
///  (0-based) from the table snapshot data. This data is packaged
///  into a JavaScript object whose properties correspond to the 
///  names of the columns in the snapshot table.<br>
///  For non-snapshot tables or out of range row numbers, returns null.
ClientMethod getRowData(row) [ Language = javascript ]
{
	if (row < 0) return null;
	this._rowData = null;
	if (this.useSnapshot) {
		// fetch data from the server (synchronously)
		row = parseInt(row,10) + (parseInt(this.currPage,10)-1)*parseInt(this.pageSize,10);
		var fetch = this.FetchRowFromSnapshot(this.index,this.snapshotId,row+1,this.currColumn,this.sortOrder);
	}
	var data = this._rowData;
	delete this._rowData;
	return data;
}

///  Explore the DOM and extract the data for the specified phyiscal table row
///  (0-based) from the rendered table data (not to be confused with 
///  the logical row number of the data itself in a multi-page table).<br> 
///  This data is packaged into a JavaScript object whose properties
///  correspond to the names of the columns in the table.  If 
///  showRowNumbers is true the object will also contain a property 
///  called rowNum and will be contain the logical, enumerated row 
///  of the result set record <br>
///  This is a client-side only call and can query only the values of
///  the current page of the current table.  The full, logical contents
///  of the table (in snapshot mode) resides at the server and logical
///  rows may be accessed using getRowData() <br>
///  If there are not data columns to report or if the requested row is 
///  greater than the page size for the table, this function returns null.<br>
/// 
ClientMethod getRenderedRowData(row) [ Language = javascript ]
{
	var rowId = "tr_"+row;
	var rowDiv = this.findElement(rowId);
	if (!rowDiv) return(null);
	var len = this.columns.length;
	if (len==0) return(null);
	var rowObj = {};
	var colIdx=0;
	for (var k=rowDiv.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1) {
			if (k.textContent) var value=k.textContent;
			else var value=k.innerText;
			if (value) value=value.replace(/^[ \t\u00A0]+|[ \t\u00A0]+$/,"");
			if (k.className=='tpSel' || k.className=='tpCB') {}
			else if (k.className=='tpRNum') {
				rowObj["rowNum"]=value;
			}
			else {
				if (colIdx>=len) {
					return(rowObj);
				}
				var c = this.columns[colIdx];
				while (c && (c.colName=='' || c.hidden)) {
					colIdx++;
					c = this.columns[colIdx];
				}
				if (colIdx<len) {
					rowObj[c.colName]=value;
					colIdx++;
				}
			}			
		}
	}
	return(rowObj);
}

///  Internal method.<br>
///  Fetch data from snapshot global and package up as a client object.
///  <var>pIndex</var> is index of client component.<br>
///  <var>pID</var> is internal ID of snapshot global.<br>
///  <var>pRow</var> is row number to fetch.<br>
ClassMethod FetchRowFromSnapshot(pIndex As %Integer, pID As %String, pRow As %Integer, pCurrColumn As %String = "", pSortOrder As %String = "") As %Boolean [ ZenMethod ]
{
	#; if table is sorted, find actual row ID # first
	If (pCurrColumn = "") {
		Set tRow = pRow
	}
	Else {
		#; find n-th element in index (as there is no cross-index)
		Set tSortOrder = $Case(pSortOrder,"asc":1,"desc":-1,:1)
		Set tRow = ""
		Set n = 0
		Set tVal = $O(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"index",pCurrColumn,""),tSortOrder)
		While (tVal '= "") {
			Set tKey = $O(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"index",pCurrColumn,tVal,""),tSortOrder)
			While (tKey '= "") {
				Set n = n + 1
				If (n = pRow) {
					Set tRow = tKey
					Quit
				}
				Quit:(n=pRow)
				Set tKey = $O(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"index",pCurrColumn,tVal,tKey),tSortOrder)
			}
			Quit:(tRow'="")
			Set tVal = $O(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"index",pCurrColumn,tVal),tSortOrder)
		}
	}

	#; get data row from snapshot
	Set tData = ""
	Set:tRow'="" tData = $G(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"data",tRow))

	If (tData="") {
		#; no data
		&js<zenPage.getComponent(#(pIndex)#)._rowData = null;>
		Quit 0
	}
	&js<var rowData = new Object();>

	#; get column info from snapshot
	Set c = $O(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"info",""))
	While (c '= "") {
		Set tName = $G(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"info",c))
		If (tName '= "") {
			Set tVal = $LG(tData,c)
			Set tType = $G(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"info",c,"type"))
			If (..%IsTypeNumeric(tType)&&$IsValidNum(tVal)) {
				&js<rowData['#($ZCVT(tName,"O","JS"))#'] = zenConvertType('NUMERIC',#($ZCVT(tVal,"O","JS"))#);>
			}
			ElseIf ((tVal'="")&&(tType=16)) { // boolean
				&js<rowData['#($ZCVT(tName,"O","JS"))#'] = zenConvertType('BOOLEAN',#($ZCVT(tVal,"O","JS"))#);>
			}
			Else {
				&js<rowData['#($ZCVT(tName,"O","JS"))#'] = '#($ZCVT(tVal,"O","JS"))#';>
			}
		}
		Set c = $O(^IRIS.Temp.zenData(%session.SessionId,pID,pIndex,"info",c))
	}
	&js<zenPage.getComponent(#(pIndex)#)._rowData = rowData;>
	Quit 1
}

///  Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'parameters':
		// set value of parameter: note that value will
		// be 1-based, so we have to convert it.
		// changing parameter always forces a query execution,
		// even in snapshot mode.
		if ('' != value) {
			value = value - 1;
			if (this.parameters[value]) {
				if (this.parameters[value].value != value2) {
					this.parameters[value].value = value2;
					this.executeQuery();
				}
			}
		}
		break;

	case 'currPage':
		// alternate API for going to a page (within this table)
		this.gotoPage(value);
		break;

	case 'pageSize':
		if (value != this.pageSize) {
			this.currPage = 1; // go back to start
			this.pageSize = value;
			this.refreshTable();
		}
		break;

	case 'nowrap':
	case 'showValueInTooltip':
		value = value ? true : false;
		if (value != this[property]) {
			this[property] = value;
			this.refreshTable();
		}
		break;

	case 'headerLayout':
	case 'fixedHeaders':
	case 'bodyHeight':
	case 'extraColumnWidth':
	case 'caption':
	case 'useKeys':
		if (value != this[property]) {
			this[property] = value;
			this.refreshTable();
		}
		break;
	case 'showFilters':
		this.showColumnFilters(value ? true : false);
		break;
	case 'filtersDisabled':
		this.disableColumnFilters(value ? true : false);
		break;
	case 'useSnapshot':
		value = value ? true : false;
		if (value != this.useSnapshot) {
			this.useSnapshot = value;
			this.pageSize = this.useSnapshot ? this.pageSize : 0;
			this.refreshTable();
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
		break;
	}

	return true;
}

///  Process key down event within the table's invisible edit control.
ClientMethod tpKeyDownHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	var row = this.selectedIndex;
	var rows = (''!=this.rowCount) ? parseInt(this.rowCount.split(' ')[0]) : '';

	var rowcount = ((''!=rows)&&('' == this.pageSize || 0 == this.pageSize)) ? rows : this.pageSize;
	if ((''!=rows)&&(rowcount > rows)) {
		rowcount = rows;
	}

	if ('' != this.onkeypress) {
		ret = zenInvokeCallbackMethod(this.onkeypress,this,'onkeypress','evt',evt);
	}

	if (!ret) {
		return false;
	}

	// trap keys
	switch(evt.keyCode) {
	case zenENTER:
		break;

	case zenPAGEUP:
		this.previousPage(true);
		break;
	case zenPAGEDN:
		this.nextPage(true);
		break;

	case zenEND:
		if (evt.ctrlKey) {
			this.lastPage();
		}
		else {
			this.selectRow(rowcount-1,true,'keypress');
		}
		break;

	case zenHOME:
		ret = false;
		if (evt.ctrlKey) {
			this.firstPage();
		}
		else {
			this.selectRow(0,true,'keypress');
		}
		break;

	case zenUP:
		ret = false;
		if (row > 0) {
			this.selectRow(row-1,true,'keypress');
		}
		break;
	case zenDOWN:
		ret = false;
		if (row < rowcount-1) {
			this.selectRow(row+1,true,'keypress');
		}
		break;
	case zenDELETE:
		break;
	case zenTAB:
		break;

	default:
		break;
	}

	if (!ret) {
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		evt.cancelBubble = true;
	}

	return ret;
}

///  Process key press event within the table's invisible edit control.
ClientMethod tpKeyPressHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	if ('' != this.onkeypress) {
		ret = zenInvokeCallbackMethod(this.onkeypress,this,'onkeypress','evt',evt);
	}

	return ret;
}

///  Client-side method to input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	// give focus to invisible control
	var inv = this.findElement('invisible');
	if (inv) {
		if (this.selectedIndex >= 0) {
			var tr = this.findElement("tr_" + this.selectedIndex);
			if (tr) {
				var offsetTop = tr.offsetTop;
				inv.style.top = offsetTop+"px";
				if (zenIsIE) inv.style.width="0px";
			}
		}
		inv.focus();
	}
}

///  Appends new column object to this table with the given
///  column name. Returns the new column object.<br/>
///  Call the <method>executeQuery</method> method after calling this
///  to update the table.
ClientMethod appendColumn(colName) [ Language = javascript ]
{
	var column = zenPage.createComponent('column');
	column.colName = colName ? colName : '';
	this.columns[this.columns.length] = column;
	return column;
}

///  Tests if a column type is a numeric type.
/// 	Zen uses the CLIENTDATATYPE value, not ODBCTYPE. Client types are defined as:
/// Returns the type of column <var>n</var> in the result set where type is an integer associated with
/// the client datatype. If the type cannot be determined, 0 (zero) is returned.
/// <table>
/// <tr><td>1<td><td>BINARY</td></tr>
/// 	<tr><td>2<td><td>DATE</td></tr>
/// 	<tr><td>3<td><td>DOUBLE</td></tr>
/// 	<tr><td>4<td><td>HANDLE</td></tr>
/// 	<tr><td>5<td><td>INTEGER</td></tr>
/// 	<tr><td>6<td><td>LIST</td></tr>
/// 	<tr><td>7<td><td>LONGVARCHAR</td></tr>
/// 	<tr><td>8<td><td>TIME</td></tr>
/// 	<tr><td>9<td><td>TIMESTAMP</td></tr>
/// 	<tr><td>10<td><td>VARCHAR</td></tr>
/// 	<tr><td>11<td><td>STATUS</td></tr>
/// 	<tr><td>12<td><td>BINARYSTREAM</td></tr>
/// 	<tr><td>13<td><td>CHARACTERSTREAM</td></tr>
/// 	<tr><td>14<td><td>NUMERIC</td></tr>
/// 	<tr><td>15<td><td>CURRENCY</td></tr>
/// 	<tr><td>16<td><td>BOOLEAN</td></tr>
/// 	<tr><td>17<td><td>OID</td></tr>
/// 	<tr><td>18<td><td>BIGINT</td></tr>
/// 	<tr><td>19<td><td>FDATE</td></tr>
/// 	<tr><td>20<td><td>FTIMESTAMP</td></tr>
/// </table>
ClassMethod %IsTypeNumeric(pType As %Integer) As %Boolean [ CodeMode = expression ]
{
$Case(pType,3:1,5:1,14:1,16:1,18:1,:0)
}

///  Explore the DOM structure and return the first child of the given node
///  that matches the given class name
ClientMethod findChildByClass(node, className) [ Internal, Language = javascript ]
{
	for (var tNode=node.firstChild;tNode!=null; tNode=tNode.nextSibling) {
		if (tNode.nodeType==1 && tNode.className==className) return(tNode);
	}
	return(null);
}

///  Explore the DOM structure and return the first child of the given node
///  that matches the HTML tag type
ClientMethod findChildByTag(node, tagName) [ Internal, Language = javascript ]
{
	for (var tNode=node.firstChild;tNode!=null; tNode=tNode.nextSibling) {
		if (tNode.nodeType==1 && tNode.tagName==tagName) return(tNode);
	}
	return(null);
}

///  Explore the DOM in a depth first recursive search to find the first
///  descendant of the given node of of the given class
ClientMethod findDescendantByClass(node, className) [ Internal, Language = javascript ]
{
	for (var tNode=node.firstChild;tNode!=null; tNode=tNode.nextSibling) {
		if (tNode.nodeType==1) {
			if (tNode.className==className) return(tNode);
			var tRecurse = this.findDescendantByClass(tNode,className);
			if (tRecurse!=null) return(tRecurse);
		}
	}
	return(null);
}

ClientMethod resizeHeaders() [ Language = javascript ]
{
///  Under IE with fixedHeaders set to true, the table headers and the body
///  columns may become misaligned.  This routine checks for alignment issues
///  in the rendered table and, if needed, reformats the header to accound for
///  the space taken up by a vertical scrollbar in the body of the table.
	if (!zenIsIE) return;
	if (navigator.userAgent.indexOf("Trident/4.")>=0) {
		var tDiv = this.getEnclosingDiv();
		var revertedAuto=0;
		if (tDiv.forcedWidth==tDiv.currentStyle.width) {
			 tDiv.style.width="auto";
			 revertedAuto = 1;
		}
		if (tDiv.currentStyle.width=="auto" || revertedAuto) {
			var tHeadDiv = this.findChildByClass(tDiv,"tpTable");
			var tHead=this.findChildByClass(tHeadDiv,"tpHead");
			var tRow=this.findChildByTag(tHead,"TR");
			var zeroWidth=0;
			var percentWidth=0;
			if (tRow && tRow.firstChild) {
				var cWidth=[];
				for (var k=tRow.firstChild;k!=null;k=k.nextSibling) {
					if (k.nodeType==1 && k.tagName=="TH") {
						var o = {}
						o.node = k;
						if (!revertedAuto) o.ow = this.getInsideWidth(k);
						o.sw = k.currentStyle.width;
						o.txt = k.innerText;
						if (o.ow<=0 && !revertedAuto) zeroWidth++;
						if (o.sw && (o.sw.indexOf('%')>0 || o.sw=='auto')) percentWidth++;						
						cWidth.push(o);
					}
				}
			}
			if (zeroWidth>=percentWidth) { // Dealing with columncollapse situation
				var wideGroup = tDiv.parentNode;
				var sparePixels = 0;
				var baseWidth = tDiv.offsetWidth;
				while (wideGroup!=document.body && wideGroup.parentNode && sparePixels==0) {
					if (wideGroup.offsetWidth>baseWidth) {
						var totalUsed = 0;
						for (var k=wideGroup.firstChild;k!=null;k=k.nextSibling) {
							if (k.nodeType==1) totalUsed+=k.offsetWidth;
						}
						sparePixels = wideGroup.offsetWidth-totalUsed;
					}
					if (sparePixels==0) wideGroup = wideGroup.parentNode;

				}
				if (sparePixels>0) {
					var newWidth = tDiv.offsetWidth+sparePixels+"px";
					tDiv.style.width=newWidth;
					tDiv.forcedWidth=newWidth;
				}
			}
		}
	}

	if (navigator.userAgent.indexOf("Trident/4.")>=0 || navigator.userAgent.indexOf("MSIE 7")>=0) {
		// needs width vs min-width fix
		var tDiv=this.getEnclosingDiv();
		var tHeadDiv = this.findChildByClass(tDiv,"tpTable");
		var tBodyDiv = this.findChildByClass(tDiv,"tpBodyFixed");
		if (tHeadDiv==null || tBodyDiv==null) return;
		var tEmpty = this.findDescendantByClass(tBodyDiv,"tpNoResults");
		if (!tEmpty) {
			var tBody=this.findChildByTag(this.findChildByClass(tBodyDiv,"tpTable"),"TBODY");
			var tRow=this.findChildByTag(tBody,"TR");
			if (tRow) {
				var kid = [];
				for (var k=tRow.firstChild;k!=null;k=k.nextSibling) {
					if (k.nodeType==1 && k.tagName=="TD") {
						var o = {};
						var csw = k.currentStyle.width;
						var ow = k.offsetWidth;
						o.csw = csw;
						o.ow = ow;
						o.k = k;
						o.p=false;
						k.minWidth=csw;
						if (ow>0) k.width=ow+"px";
						kid.push(o);
					}
				}
			}
		}
	}
	if (zenIsIE && this.fixedHeaders && (!zenIsHTML5)) {		
		var tDiv=this.getEnclosingDiv();
		var tHeadDiv = this.findChildByClass(tDiv,"tpTable");
		var tBodyDiv = this.findChildByClass(tDiv,"tpBodyFixed");
		if (tHeadDiv==null || tBodyDiv==null) return;

		tHeadDiv.style.tableLayout="fixed";
		tHeadDiv.style.width="";

		var tEmpty = this.findDescendantByClass(tBodyDiv,"tpNoResults");

		var tOdds = this.findDescendantByClass(tBodyDiv,"tpOdd");
		if (!tOdds) {
			var tRows = this.findDescendantByClass(tBodyDiv,"tpRow");
			if (!tRows) {
				var tEvens = this.findDescendantByClass(tBodyDiv,"tpEven");
				if (!tEvens) {
					var tSelects = this.findDescendantByClass(tBodyDiv,"tpSelected");
					if (!tSelects) {
						tEmpty = true;
					}
				}
			}
		}
		if (tEmpty) {
			var tmp=tBodyDiv.clientWidth; 
			tHeadDiv.style.width=tmp +"px";
			return;
		}
		var tHead=this.findChildByClass(tHeadDiv,"tpHead");
		var tBody=this.findChildByTag(this.findChildByClass(tBodyDiv,"tpTable"),"TBODY");
		var tRow=this.findChildByTag(tBody,"TR");
		if (tRow==null) return; //PL 64254
		//only under IE would this make sense...
		tHeadDiv.style.width="0";
		var tmp=tHeadDiv.currentStyle.width; 
		
		var scrolledBody=false;
		var gap = tBodyDiv.offsetWidth-tBodyDiv.clientWidth;
		if (tBodyDiv.clientWidth>0 && gap>10) scrolledBody=true;

		var cWidth=[];
		for (var k=tRow.firstChild;k!=null;k=k.nextSibling) {
			if (k.nodeType==1 && k.tagName=="TD") {
				cWidth.push(this.getInsideWidth(k));
				if (k.offsetWidth<0) return; //PL 64254C
				if (k.className=="tpNoResults") return; //PL 64254B
			}
		}
		// for each row of the heading, force the columns to align with the
		// widths of the pixel values in the body
		for (k=tHead.firstChild;k!=null;k=k.nextSibling) {
			if (k.nodeType==1 && k.tagName=="TR") {
				var idx=0;
				for (var n=k.firstChild;n!=null;n=n.nextSibling) {
					if (n.nodeType==1 && n.tagName=="TH") {
						if (idx<cWidth.length) {
							var w=cWidth[idx++];
							if (w<=0) {
								n.style.display="none";
							}
							else {
								n.style.display="block";
								n.style.width = w+"px";
								n.width=n.style.width;
								n.minWidth=n.style.width;
							}
						}
						else {
							if (scrolledBody) {
								var pad = n.offsetWidth-n.clientWidth;
								n.style.width=(gap + pad - 2)+"px";
								n.style.display="block";
							}
							else {
								n.style.display="none";
							}
						}
						n.style.overflow='hidden';
					}
				}
			}
		}
	}
}

ClientMethod getInsideWidth(element) [ Language = javascript ]
{
	var baseW = element.offsetWidth;
	return(baseW);
}

ClientMethod setOffsetWidth(element, width) [ Language = javascript ]
{
	element.style.width=width+"px";
	var delta = element.offsetWidth-width;
	var newSize = width-delta;
	if (newSize<1) newSize=1;
	element.style.width= newSize+"px";
}

ClientMethod packRowsIE() [ Language = javascript ]
{
	// Yet again, IE is so far removed from the standards recommendation that we
	// need to reimplement everything (PL73250)
	var eDiv=this.getEnclosingDiv();
	var tDiv=eDiv.firstChild;
	var tHead=this.findElement("tpHead");
	var tBody=this.findElement("tpBody");

	if (!this.bodyHeight && tBody.currentStyle.height=="auto") {
		// Provide early out for IE 8 use case
		// user didn't ask for any special height handling so given 'em what they want
		eDiv.forcedHeight=false;
		return;
	}

	var pseudoShow = false;
	var parentNode = eDiv.parentNode;
	var insPt = eDiv.nextSibling;
	
	if (tBody.offsetHeight<1 && tBody.offsetWidth<1 && eDiv.currentStyle.display!="none") { // obscured for some reason
		pseudoShow = true;
		document.body.appendChild(eDiv);
	}

	eDiv.style.backgroundColor=tBody.currentStyle.backgroundColor;
	eDiv.style.display='inline-block';

	var oldBodyH=tBody.offsetHeight;
	if (!eDiv.forcedHeight) eDiv.baseHeight=eDiv.style.height;
	eDiv.style.height=eDiv.clientHeight+"px";
	if (!this.fixedHeaders) tBody.style.height="";
	if (this.bodyHeight) {
		eDiv.style.height=this.bodyHeight;
		eDiv.style.overflow="auto";
		eDiv.style.height=eDiv.offsetHeight+tBody.offsetTop+tHead.offsetTop+"px";
		
	}
	eDiv.forcedHeight=true;
	if (tBody.offsetHeight>=oldBodyH) { // no correction needed, revert settings
		var h="20.0em";
		if (this.bodyHeight) {
			if (this.fixedHeaders) {
				h=this.bodyHeight;
				if (zenPage.cssLevel<3) tBody.style.height=h;
				eDiv.style.height=eDiv.baseHeight;
			}
		}
		eDiv.forcedHeight=false;
	}

	if (pseudoShow) { // obscured for some reason
		parentNode.insertBefore(eDiv,insPt);
	}
}

ClientMethod packRows() [ Language = javascript ]
{
// The CSS 2.1 standard is poorly worded with respect to what a table should do if
// sum of the height of the rows adds up to less than the specified table body height.
// Officially, the question of what to do with the excess space allocated for the table
// is "undefined"  In practice, some broswers leave it blank while others make all the
// rows taller to absorb the excess room on the vertical.  The packRows method is 
// designed to compensate for this variation and impose a more consistant rendering 
// across platforms (PL 68773)
	if (this.hidden) return;
	if (zenIsIE) {	
		this.packRowsIE();
		return;
	}
	if (!(this.bodyHeight || this.fixedHeaders)) return; // If it wasn't set, this isn't an issue
	if (!navigator) return; // Should never be true in a runtime situation
	var isWebkit=(navigator.userAgent.indexOf("WebKit")>=0);
	var isFF3=(navigator.userAgent.indexOf("Firefox")>=0);
	if (!(isFF3 || isWebkit)) return; // Either early Firefox or unsupported platform
	var eDiv=this.getEnclosingDiv();
	if (eDiv.offsetWidth==0 || eDiv.offsetHeight==0) return; // Not yet visible

	var tDiv=this.findElement("tpTable"); // used to be eDiv.firstChild;
	var tHead=this.findElement("tpHead");
	var tBody=this.findElement("tpBody");
	if (isFF3) { // Wants to spread rows
		var oldBodyH=tBody.offsetHeight;
		if (!eDiv.forcedHeight) eDiv.baseHeight=eDiv.style.height;
		eDiv.style.height=eDiv.clientHeight+"px";
		tBody.style.height="";
		eDiv.forcedHeight=true;
		if (tBody.offsetHeight>oldBodyH) { // no correction needed, revert settings
			var h="20.0em";
			if (this.bodyHeight) h=this.bodyHeight;
			tBody.style.height=h;
			eDiv.style.height=eDiv.baseHeight;
			eDiv.forcedHeight=false;
		}
	}
	else { // Webkit shortens the table height to match the rows
		if (!eDiv.targetBodyHeight) {
			var h="20.0em";
			if (this.bodyHeight) h=this.bodyHeight;
			var tmp=document.createElement("DIV");
			tmp.style.position="absolute";
			tmp.style.height=h;
			tmp.style.display="block";
			document.body.appendChild(tmp);
			eDiv.targetBodyHeight=tmp.clientHeight;
			document.body.removeChild(tmp);
		}
		if (tBody.clientHeight<eDiv.targetBodyHeight) {
			if (!eDiv.forcedHeight) { 
				eDiv.baseHeight=eDiv.style.height;
				eDiv.forcedHeight=true;
				var h=eDiv.clientHeight+eDiv.targetBodyHeight-tBody.clientHeight;
				eDiv.style.height=h+"px";
			}
		}
		else if (eDiv.forcedHeight) { 
			// there's a bug in Webkit that allows tables to grow with visible
			// overflow and no scrolling despite CSS settings.  Not a lot we can do
			// about this except write it up.
			eDiv.style.height=eDiv.baseHeight;
			eDiv.forcedHeight=false;
		}
	}
}

///  if the position of the enclosing div for table has not been explicitly set 
///  to some desired value, force its positioning to relative with an offset of 0,0
///  such a that any absolutely positioned child elements will have a known, local
///  offset parent. 
ClientMethod anchorDiv() [ Internal, Language = javascript ]
{
	//PL84286
	if (!this.useKeys) return;
	var node = this.getEnclosingDiv();
	var position = null;
	if (node.currentStyle) // IE Style
		position = node.currentStyle.position;
else if (window.getComputedStyle) {
  var styleObj = window.getComputedStyle(node,null);
  if (styleObj) position = styleObj.position;
}
	if (!(position=="absolute" || position=="relative")) {
		node.style.position = "relative";
		node.style.top = "0px";
		node.style.left = "0px";
	}
}

ClientMethod launchConfirmDialog(url, pageName, features, parms) [ Internal, Language = javascript ]
{
	
	zenLaunchPopupWindow(url, pageName, features, parms,this)
}

///  Called after refreshContents when table is actually visible.
///  Call the resizeHeaders routine to see if any alignment issue need to be 
///  addressed.
ClientMethod onDisplayHandler() [ Internal, Language = javascript ]
{
	this.anchorDiv();
	if (this.findElement("tpBody")) {
		this.packRows(); // PL 68773
		this.resizeHeaders();
	}
}

///  When the page is loaded, check for alignment issues between the table header
///  and the table body.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.anchorDiv();
	if (this.findElement("tpBody")) {
		this.resizeHeaders();
		this.packRows(); // PL 68773
	}
	// make sure current row is selected: JMD695
	var index = this.selectedIndex;
	this.selectedIndex = -1;
	this.selectRow(index,false);
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action=="ok"){
		if (value!=""){
			if (!zenPage.useSoftModals) { // Ensure the window is closed before running the code
				setTimeout(value,50);
			}
			else {
				eval(value);
			}
		}
	}
}

}
