/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to implement the server-side query construction and execution for the Message Viewer.
/// Users may wish to extend this class to provide enhanced query generation for their particular application. 
/// If extended functionality is required, the name of the subclass should be specified in ^EnsPortal.Settings("MessageViewer","AssistantClass").
/// Users can override any of the methods in this class if they so choose, but specific APIs have been created to simplify functional changes.
/// The <method>addBasicConstraints</method>() can be overridden to specify particular handling for certain combinations of top-level Filter properties.
/// The <method>OnFinalizeSQL</method>()should be overridden is users only which to specify alternative JOIN orders in the FROM clause.
/// (For an example of such syntax, see <class>Ens.Enterprise.Portal.MsgFilter.Assistant</class>.)
/// Note: InterSystems is not responsible for user extensions to these classes.
Class EnsPortal.MsgFilter.Assistant Extends (EnsPortal.MsgFilter.AbstractAssistant, Ens.Util.FunctionSet) [ CompileAfter = EnsPortal.MsgFilter.Filter, System = 4 ]
{

/// Name of ID Column
Parameter IDCOL = "ID";

/// Number to use in SELECT TOP, if any. Use this to affect the SQL query optimizer.
/// Set it substantially larger than MAXROWS if FilterRS() might invalidate some of the rows returned from SQL.
Parameter TOPCOUNT = 10000000;

Parameter DOMAIN = "Ensemble";

/// Control whether range conditions (i.e. <, <=, >, >=) on the Header TimeCreated field should be
/// converted to range conditions on the Header ID field instead.
Parameter CONVERTTIMERANGES = 1;

Parameter SESSIONSUBSCRIPT = "MessageViewer";

/// Parse tree of filter criteria terms
/// Top level nodes are OR'ed groups of terms; 2nd level nodes are AND'ed terms; 3d level are OR'ed conditions, 4th level are AND'ed conditions
Property Tree [ Internal, MultiDimensional ];

/// Array to hold the encountered body classes.
Property BodyClasses [ MultiDimensional ];

/// Array to hold encountered SearchTables.
Property SearchTables [ MultiDimensional ];

/// Array to hold the number of SearchTable conditions.
Property NumSearchTabConds As %Integer [ MultiDimensional ];

/// Flag to indicate whether an IN clause should be used when constructing
/// SearchTable queries. The only situation where this should be False is when there is a single
/// SearchTable equality condition -- in that case an IN clause is not required.
Property UseSTIN As %Boolean [ Transient ];

/// Array of hidden tables and properties. Use the <method>addHiddenColumn</method>() 
/// and <method>isHidden</method>() methods to manipulate and detect hidden columns.
Property Hidden [ MultiDimensional, Private ];

/// tree of flags for which nodes have published a value, so we can go back and fill in those that didn't
Property ValNodes [ Internal, MultiDimensional ];

/// Used to determine if any extended criterion is being applied to the filter.
/// A disabled one does not count.
Method IsUsingTerms(filter As EnsPortal.MsgFilter.Filter) As %Boolean
{
	For i=1:1:filter.Terms.Count() {
		Set term = filter.Terms.GetAt(i)
		Return:($IsObject(term) && ('term.Disabled)) 1
	}

	Return 0
}

/// Callback to create the <class>Filter</class> class for this Assistant.
/// The paging logic is implemented in this method based on the nextPageStartId
/// and nextPageEndId properties of the supplied proxyObject.
ClassMethod CreateFilter(pSearchCriteria As %ZEN.proxyObject, Output pFilter As EnsPortal.MsgFilter.Filter, pExcludeSequenceManager As %Boolean = 1, pVirtualKey As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = ##super(pSearchCriteria,.pFilter,pExcludeSequenceManager, pVirtualKey)
		If $$$ISERR(tStatus) Quit
		
		// The auto added Start / End IDs are not intended for Enterprise Message Bank
		Quit:(..#CONVERTTIMERANGES=2)

		If pSearchCriteria.nextPageStartId && ((pSearchCriteria.nextPageStartId >= pFilter.StartId) || ('pFilter.StartId)) {
			Set pFilter.StartId = pSearchCriteria.nextPageStartId
		}
		If pSearchCriteria.nextPageEndId && ((pSearchCriteria.nextPageEndId <= pFilter.EndId) || ('pFilter.EndId)) {
			Set pFilter.EndId = pSearchCriteria.nextPageEndId
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Set pFilter = ""
	}
	Quit tStatus
}

/// Helper method to return a valid ResultSet for the supplied <class>Filter</class> object.
/// The result set construction itself is wrapped by the <query>Enumerate</query> query.
/// The main goal is to branch the Sequence Manager the logic in this method, but
/// subclasses can implement any logic they see fit to create a result set object.
ClassMethod GetResultSet(pFilter As EnsPortal.MsgFilter.Filter, Output pResultSet As %ResultSet, pExecute As %Boolean = 1) As %Status
{
	Set tStatus = $$$OK
	Set pResultSet = ##class(%ResultSet).%New()
	If pFilter.SequenceManagerSearch '= "" {
		Set pResultSet.ClassName = "EnsPortal.MsgFilter.SMAssistant"
		Set pResultSet.QueryName = "Enumerate" _ pFilter.SequenceManagerSearch 
	}
	Else {
		Set pResultSet.ClassName = $classname($this)
		Set pResultSet.QueryName = "Enumerate"
	}

	If pExecute {
		Set tStatus = pResultSet.Execute(pFilter)
	}
	Quit tStatus
}

/// List the messages matching the conditions in the supplied Filter.
/// The actual logic for this query is implemented in the <method>EnumerateExecute</method>,
/// <method>EnumerateFetch</method>, <method>EnumerateClose</method> and <method>EnumerateGetInfo</method>
/// methods.
Query Enumerate(Filter As EnsPortal.MsgFilter.Filter) As %Query(ROWSPEC = "ID,TimeCreated,Session,Status,Error,Source,Target")
{
}

/// Initial method which parses the Filter into SQL terms and post-SQL terms. It then constructs an inner result set
/// based on the SQL terms and calls the execute method of this inner result set.
ClassMethod EnumerateExecute(ByRef qHandle As %Binary, Filter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set qHandle = 0
	Set qHandle("Filter") = Filter
	Set qHandle("EndTime") = $select(Filter.Timeout: ($zh + Filter.Timeout), 1: "")

	Set tAssistant = ..%New()
	Set tStatus = tAssistant.parseTerms(Filter)
	If $$$ISERR(tStatus) Quit tStatus

	Set dateLen = 999
	If Filter.TimeFormat '= "" {
		Set dateLen = Filter.TimeFormat
	}
	
	#; Special case for situations where we have SortOrder = "Newest First" and exact equality constraints on 
	#; SourceConfigName and TargetConfigName joined by an OR or an AND.
	#; If any other criteria are supplied, except for StartId and/or EndId, fall through to the standard query logic.
	#; The special case is needed as the SQL engine doesn't optimise this particular search well at this stage.
	If (Filter.SortOrder = Filter.SortOrderDisplayToLogical("Newest First")) && (Filter.StartTime = "") && (Filter.EndTime = "") && (Filter.Status = "") && (Filter.Type = Filter.TypeDisplayToLogical("All")) {
		Set tSource = ""
		Set tTarget = ""
		Set tJoin = "OR"
		// Handle case where Source and Target are set with no extended criteria - always an AND
		If (Filter.Terms.Count() = 0) && (Filter.Source '= "") && (Filter.Target '= "") {
			Set tSource = Filter.Source
			Set tTarget = Filter.Target
			Set tJoin = "AND"
		}
		ElseIf (Filter.Terms.Count() = 1) && ('Filter.Terms.GetAt(1).Disabled) {
			Set tTerm = Filter.Terms.GetAt(1)
			// Handle case where one condition is SourceConfigName or TargetConfigName - always an AND
			If (tTerm.Conditions.Count() = 1) {
				Set tCondition = tTerm.Conditions.GetAt(1)
				If ('tCondition.DisplayOnly) && (tCondition.Op = "=") && ($case(tCondition.Prop, "SourceConfigName": 1, "TargetConfigName": 1, : 0)) {
					Set tJoin = "AND"
					If (tCondition.Prop = "SourceConfigName") {
						If (Filter.Source = "") || (Filter.Source = tCondition.OpVal) {
							Set tSource = tCondition.OpVal
						}
						Set tTarget = Filter.Target
					}
					ElseIf (tCondition.Prop = "TargetConfigName") {
						If (Filter.Target = "") || (Filter.Target = tCondition.OpVal) {
							Set tTarget = tCondition.OpVal
						}
						Set tSource = Filter.Source
					}
				}
			}
			// Handle case where the two conditions are for SourceConfigName and TargetConfigName - join depends on second condition
			ElseIf tTerm.Conditions.Count() = 2 {
				Set tCond1 = tTerm.Conditions.GetAt(1)
				Set tCond2 = tTerm.Conditions.GetAt(2)
				If ('tCond1.DisplayOnly) && ('tCond2.DisplayOnly) && (tCond1.Op = "=") && (tCond2.Op = "=") && 
					(((tCond1.Prop = "SourceConfigName") && (tCond2.Prop = "TargetConfigName")) || ((tCond2.Prop = "SourceConfigName") && (tCond1.Prop = "TargetConfigName")))
				{
					If (tCond1.Prop = "SourceConfigName") {
						If (Filter.Source = "") || (Filter.Source = tCond1.OpVal) {
							Set tSource = tCond1.OpVal
						}
						If (Filter.Target = "") || (Filter.Target = tCond2.OpVal) {
							Set tTarget = tCond2.OpVal
						}
					}
					Else {
						If (Filter.Source = "") || (Filter.Source = tCond2.OpVal) {
							Set tSource = tCond2.OpVal
						}
						If (Filter.Target = "") || (Filter.Target = tCond1.OpVal) {
							Set tTarget = tCond1.OpVal
						}
					}
					Set tJoin = $select(tCond2.JoinOp = "OR": "OR", 1: "AND")
				}
			}
		}
		// Only use the class query if both source and target are specified
		If (tSource '= "") && (tTarget '= "") {
			Set tRS = ##class(%Library.ResultSet).%New($classname($this)_":SourceAndTargetEnumerate")
			Set tSQL = $classname($this)_":SourceAndTargetEnumerate Class Query for Source='"_tSource_"' "_tJoin_" Target='"_tTarget_"'"
			Set Filter.GeneratedSQL = tSQL
			Do ..LogQuery(tSQL,.tLogCounter)
			Set qHandle("LogCounter") = tLogCounter
			Set tStatus = tRS.Execute(tSource,tTarget,tJoin,dateLen,Filter.StartId,Filter.EndId)
			If $$$ISERR(tStatus) Quit tStatus
			If tLogCounter {
				Do ..UpdateQuery(tLogCounter,"execute")
			}
			Set qHandle("RS") = tRS
			Set qHandle("baseCols") = 7
			Set qHandle("Assistant") = tAssistant
			Set qHandle("Metadata") = tRS.%GetMetadata()
			Set qHandle("Next") = 1
			Set qHandle("RowCount") = 0

			Quit tStatus
		}
	}

	#; Only use TOP for Session-Start queries with a simple equality or no SearchTable condition
	Set Filter.TopCount = $select( ..#TOPCOUNT && ((0 = Filter.Type) && '(tAssistant.NumSearchTabConds && tAssistant.UseSTIN)): ..#TOPCOUNT, 1: "")
	Set select = "SELECT "_$select(Filter.TopCount: "TOP "_Filter.TopCount, 1:"")_" head.ID As ID"
	Set from = " FROM Ens.MessageHeader head"
	Set aFrom = 0
	Set where = ""

	Set aSelect=1
	Set aSelect(1) = "head.ID"
	Set tNoCols = $listbuild("ID","TimeCreated","SessionId","Status")
	For asName = "%ID", "ID", "TimeCreated", "SessionId", "Status", "SourceConfigName", "BodyClassname", "TargetConfigName" {
		Do tAssistant.addHiddenColumn("Ens", "MessageHeader", asName)
	}

	Do ..addTerm(.aSelect,"{fn RIGHT(%EXTERNAL(head.TimeCreated),"_dateLen_" )} As TimeCreated")
	Do ..addTerm(.aSelect,"head.SessionId As Session")
	Do ..addTerm(.aSelect,"head.Status As Status")
	Do ..addTerm(.aSelect,"CASE head.IsError WHEN 1 THEN '"_$$$Text("Error")_"' ELSE '"_$$$Text("OK")_"' END As Error")
	Do ..addTerm(.aSelect,"head.SourceConfigName As Source")
	Do ..addTerm(.aSelect,"head.TargetConfigName As Target")
	
	Set tBitmapIndex = (Filter.Source '= "") || (Filter.Target '= "") || (Filter.Status '= "")
	Do tAssistant.addSQLTerms(.aSelect,.aFrom,.xWhere,,,,tBitmapIndex)

	Set aSelect("head.ID") = 1
	If $data(aSelect("head.MessageBodyClassName As BodyClassname")) {
		Do tAssistant.addHiddenColumn("Ens", "MessageHeader", "MessageBodyClassName")
	}
 	If $data(aSelect("head.MessageBodyId As BodyId")) {
	 	Do tAssistant.addHiddenColumn("Ens", "MessageHeader", "MessageBodyId")
	 	Do tAssistant.addHiddenColumn("Ens", "MessageHeader", "BodyId")
 	}

	Set tFilterType = ##class(EnsPortal.MsgFilter.Filter).TypeLogicalToDisplay(Filter.Type)
	If (tFilterType = "Session Start") {
		Set where = where_" AND head.SessionId = head.%ID"
	} ElseIf $Case(tFilterType, "Request": 1, "Response": 1, :0) {
		Set where = where_" AND head.Type = '"_tFilterType_"'"
	}

	Set tStatus = tAssistant.addBasicConstraints(Filter, .where, .tTimeQuery)
	If $$$ISERR(tStatus) Quit tStatus
	
	Set order = " ORDER BY "
	Set tSortOrder = $select(Filter.SortOrder = Filter.SortOrderDisplayToLogical("Newest First"): " Desc", 1: "")
	Set tOrderColumn = "head.ID"
	// Add special handling when doing Session Start searches where there are no Terms and no Time-dominated conditions
	If (tFilterType = "Session Start") {
		If (0 = Filter.Terms.Count()) && (0 >= tTimeQuery) {
			// Order by SessionID in very limited cases
			If 'tBitmapIndex {
				Set tOrderColumn = "head.SessionId"
			}
			// Intentionally avoid SessionID index when using another index is likely to produce more rows of interest
			Else {
				Set from = " FROM %IGNOREINDEX Ens.MessageHeader.SessionId Ens.MessageHeader head"
			}
		}
		ElseIf '$get(^Ens.Debug("UtilEnsMessages","useSessionIndex")) {
			Set from = " FROM %IGNOREINDEX Ens.MessageHeader.SessionId Ens.MessageHeader head"
		}
	}
	If (tTimeQuery > 0) {
		Set order = order _ "head.TimeCreated" _ tSortOrder _ ","
	}
	Set order = order _ tOrderColumn _ tSortOrder

	If xWhere '= "" {
		Set where = where _ " AND "_xWhere
	}
	If (where '= "") {
		Set where = " WHERE "_$extract(where,$length("AND ")+1,*)
	}
 	
 	Set tStatus = tAssistant.OnFinalizeSQL(Filter,.select,.from,.where,.order,.aSelect,.aFrom)
	If $$$ISERR(tStatus) Quit tStatus
 	
 	Set tStatement = ##class(%SQL.Statement).%New()
 	Set tStatement.%SelectMode = 2
 	Set tSQL = select_from_where_order
 	Set Filter.GeneratedSQL = tSQL
 	Set tStatus = ..LogQuery(tSQL,.tLogCounter)
 	If $$$ISERR(tStatus) Quit tStatus
 	Set qHandle("LogCounter") = tLogCounter
 	Set tStatus = tStatement.%Prepare(tSQL)
 	If $$$ISERR(tStatus) Quit tStatus
 	
 	Set tRS = tStatement.%Execute()
 	If tLogCounter {
	 	Do ..UpdateQuery(tLogCounter,"execute")
 	}

	If tRS.%SQLCODE && (tRS.%SQLCODE '= 100) {
		Quit $$$ERROR($$$SQLCode, tRS.%SQLCODE, tRS.%Message)
	}
	Set qHandle("baseCols") = 7
	Set qHandle("RS") = tRS
	Set qHandle("Assistant") = tAssistant
	Set qHandle("Metadata") = tRS.%GetMetadata()
	Set qHandle("Next") = 1
	Set qHandle("RowCount") = 0
	Quit tStatus
}

/// Callback to get metadata about the results from the inner resultset created in the 
/// <method>EnumerateExecute</method> method. The metadata is created dynamically to reflect
/// the columns present in the result set.
ClassMethod EnumerateGetInfo(colinfo As %List, parminfo As %List, idinfo As %List, qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status
{
	Set clientinfo = $$$comMemberKeyGet($classname($this),$$$cCLASSquery,"Enumerate",$$$cQUERYclientinfo)
	If clientinfo '= "" {
		#dim tRS As %SQL.StatementResult
		#dim tMetadata as %SQL.StatementMetadata
		#dim tColumn As %SQL.StatementColumn
		
		Set colinfo = $listget(clientinfo,1)
		Set parminfo = $listget(clientinfo,2)
		Set idinfo = $listget(clientinfo,3)
		Set extent = $listget(clientinfo,4)
		Set tListLen = $listlength(colinfo)
		Set tRS = $get(qHandle("RS"))
		Set tColCount = $select($IsObject(tRS): tRS.%ResultColumnCount, 1: 0)
		$$$ASSERT($get(qHandle("baseCols"),tListLen) = tListLen)
		Set tAssistant = $get(qHandle("Assistant"))
		If $IsObject(tAssistant) {
			Set tMetadata = tRS.%GetMetadata()
			If $IsObject(tMetadata) {
				For i=tListLen+1:1:tColCount {
					Set tColumn = tMetadata.columns.GetAt(i)
					If $IsObject(tColumn) && (tColumn.colName '= "") && 'tAssistant.isHidden(tColumn.schemaName, tColumn.tableName, tColumn.colName) {
						Set colinfo = colinfo _ $lb($lb(tColumn.colName, 10, tColumn.colName))
					}
				}
			}
		}
		If $get(extinfo) {
			Set extinfo = $$$comMemberKeyGet($classname($this),"q","Enumerate",$$$cQUERYextendedinfo)
		}
		Quit $$$OK
	}
	Quit $$GetInfo^%SYS.DynamicQuery($classname($this),"Enumerate",.colinfo,.parminfo,.idinfo,.qHandle,extoption,.extinfo)
}

/// Method which actually implements fetching of data. Note that the <method>postSQLFilter</method>()
/// method of the Assistant is called to allow for any virtual document filters to be applied
/// to the result set.
ClassMethod EnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Set Row = ""
	Try {
		If ('$get(qHandle("Next"))) || $get(qHandle("Done")) {
			Set AtEnd = 1
			Quit
		}

		Set tFilter = qHandle("Filter")
		Set tAssistant = qHandle("Assistant")
		Set tRS = qHandle("RS")
		If tFilter.MaxRows && ($get(qHandle("RowCount")) >= tFilter.MaxRows) {
			Set AtEnd = 1
			Quit
		}
		Set tMetadata = qHandle("Metadata")
		Set AtEnd = 0, tCancel=0
		While 1 {
			If (tFilter.Timeout > 0) && ($zh > qHandle("EndTime")) {
				Set qHandle("Done") = 1
				Set Row = $listbuild("Timed out")
				For i=2:1:tRS.%ResultColumnCount {
					Set Row = Row _ $listbuild("")
				}
				Quit
			}
			Try { Set tCancel=$G(@%page.tempPortalNode@(%page.pageId,"SearchJob",$Job,"Stop"),0)} Catch {}
			If tCancel  {
				Set AtEnd = 1, Row = $listbuild("Search Cancelled By User")
				Try { Set @%page.tempPortalNode@(%page.pageId,"SearchJob",$Job,"Stop")=0} Catch {}
				For i=2:1:tRS.%ResultColumnCount {
					Set Row = Row _ $listbuild("")
				}
				Quit	
			}	
			Set qHandle("Next") = tRS.%Next()
			If 'qHandle("Next") {
				Set AtEnd = 1
				Quit
			}
			Kill tPropVals
			If 'tAssistant.postSQLFilter(tFilter, tRS, .tPropVals) { // no match
				Continue
			}

			Set Row = ""
			For i=1:1:tRS.%ResultColumnCount {
				Set tColumn = tMetadata.columns.GetAt(i)
				If (i > qHandle("baseCols")) && tAssistant.isHidden(tColumn.schemaName, tColumn.tableName, tColumn.colName) {
					Continue
				}
				If '$data(tPropVals(tColumn.colName), tValue) {
					Set tValue = tRS.%Get(tColumn.colName)
				}
				Set Row=Row_$listbuild(tValue)
			}
			Set qHandle("RowCount") = $get(qHandle("RowCount"),0) + 1
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Method to close off any references held by the query.
ClassMethod EnumerateClose(ByRef qHandle As %Binary) As %Status
{
	If $get(qHandle("LogCounter")) {
		Do ..UpdateQuery(qHandle("LogCounter"),"close")
	}
	Kill qHandle
 	Quit $$$OK
}

/// Custom query to retrieve data from the MessageHeader table when the results need to be displayed in Newest First sequence and the
/// only other criteria are equality matches on the SourceConfigName and TargetConfigName fields where these two conditions can be
/// combined using either an AND or and OR condition.
/// The code implementing the query is in the <method>SourceAndTargetEnumerateExecute</method>, <method>SourceAndTargetEnumerateFetch</method>
/// and <method>SourceAndTargetEnumerateClose</method> methods.
Query SourceAndTargetEnumerate(Source As %String, Target As %String, Join As %String = "OR", TimeLen As %Integer = 999, StartId As %Integer = 0, EndId As %Integer = 0, GetBodyDetails As %Boolean = 0) As %Query(ROWSPEC = "ID,TimeCreated,Session,Status,Error,SourceConfigName,TargetConfigName")
{
}

/// Method to initialise the retrieval of the data and create the query to retrieve information
/// for a specific Message Header.
ClassMethod SourceAndTargetEnumerateExecute(ByRef qHandle As %Binary, Source As %String, Target As %String, Join As %String = "OR", TimeLen As %Integer = 999, StartId As %Integer = 0, EndId As %Integer = 0) As %Status
{
	If $get(TimeLen) = "" Set TimeLen = 999
	If $get(Join) = "" Set Join = "OR"
	If StartId && EndId && (EndId < StartId) Set tmp = StartId, StartId = EndId, EndId = tmp
	
	Set tSourceStatement = ##class(%SQL.Statement).%New()
	Set tSourceSQL = "SELECT ID FROM Ens.MessageHeader WHERE SourceConfigName = ? " _ 
						$select(StartId: "AND ID >= " _ StartId _ " ", 1: "") _
						$select(EndId: "AND ID <= " _ EndId _ " ", 1: "") _
						"ORDER BY ID DESC"
	Set tStatus = tSourceStatement.%Prepare(tSourceSQL)
	If $$$ISERR(tStatus) Quit tStatus
	Set tSourceRS = tSourceStatement.%Execute(Source)
	
	Set tTargetStatement = ##class(%SQL.Statement).%New()
	Set tTargetSQL = "SELECT ID FROM Ens.MessageHeader WHERE TargetConfigName = ? " _ 
						$select(StartId: "AND ID >= " _ StartId _ " ", 1: "") _
						$select(EndId: "AND ID <= " _ EndId _ " ", 1: "") _
						"ORDER BY ID DESC"
	Set tStatus = tTargetStatement.%Prepare(tTargetSQL)
	If $$$ISERR(tStatus) Quit tStatus
	Set tTargetRS = tTargetStatement.%Execute(Target)
	
	Set tMainStatement = ##class(%SQL.Statement).%New()
	Set tMainStatement.%SelectMode = 2
	Set tMainSQL = "SELECT ID, {fn RIGHT(%EXTERNAL(TimeCreated),"_TimeLen_")} As TimeCreated, SessionId As Session, Status, " _ 
					"CASE IsError WHEN 1 THEN '"_$$$Text("Error")_"' ELSE '"_$$$Text("OK")_"' END As Error, " _
					"SourceConfigName As Source, TargetConfigName As Target " _
					"FROM Ens.MessageHeader WHERE ID = ?"
	Set tStatus = tMainStatement.%Prepare(tMainSQL)
	If $$$ISERR(tStatus) Quit tStatus
	
	Set Join = $zconvert(Join,"U")
	Set qHandle("Join") = Join
	Set qHandle("Statement") = tMainStatement
	Set qHandle("SourceRS") = tSourceRS
	Set qHandle("TargetRS") = tTargetRS
	If Join = "OR" {
		Set qHandle("Done") = $lb(0,0)
		Set qHandle("DoNext") = $lb(1,1)
	}
	Quit $$$OK
}

/// Method which implements the retrieval for the query. The main goal here is to
/// use the built-in SQL ability to order over the SourceConfigName and TargetConfigName
/// bitmap indices in the reverse direction and then impose the AND or OR condition on the
/// resulting ID values. The code may perform poorly for very large row counts, but given
/// that this is for the UI, this should not be a problem.
ClassMethod SourceAndTargetEnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Set Row = ""
	Try {
		Set tNextId = 0
		
		If qHandle("Join") = "OR" {
			Set tDone = qHandle("Done")
			Set tDoNext = qHandle("DoNext")
			Set tSourceNext = $select($lg(tDone,1): 0, $lg(tDoNext,1): qHandle("SourceRS").%Next(), 1: 1)
			Set tTargetNext = $select($lg(tDone,2): 0, $lg(tDoNext,2): qHandle("TargetRS").%Next(), 1: 1)
			If ('tSourceNext) && ('tTargetNext) {
				Set AtEnd = 1
				Quit
			}
			Set qHandle("Done") = $lb('tSourceNext,'tTargetNext)
			
			If 'tSourceNext {
				Set tNextId = qHandle("TargetRS").ID
				Set tDoNext = $lb(0,1)
			}
			ElseIf 'tTargetNext {
				Set tNextId = qHandle("SourceRS").ID
				Set tDoNext = $lb(1,0)
			}
			Else {
				Set tNextTarg = qHandle("TargetRS").ID
				Set tNextSrc = qHandle("SourceRS").ID
				If tNextTarg = tNextSrc {
					Set tNextId = tNextTarg
					Set tDoNext = $lb(1,1)
				}
				ElseIf tNextTarg < tNextSrc {
					Set tNextId = tNextSrc
					Set tDoNext = $lb(1,0)
				}
				Else {
					Set tNextId = tNextTarg
					Set tDoNext = $lb(0,1)
				}
			}
			Set qHandle("DoNext") = tDoNext
		}
		ElseIf qHandle("Join") = "AND" {
			Set tTargNext = qHandle("TargetRS").%Next()
			Set tSourceNext = qHandle("SourceRS").%Next()
			If tTargNext && tSourceNext {
				Set tNextTarg = qHandle("TargetRS").ID
				Set tNextSrc = qHandle("SourceRS").ID
				While tTargNext && tSourceNext && (tNextId = 0) {
					If (tNextTarg > tNextSrc) {
						Set tTargNext = qHandle("TargetRS").%Next()
						If tTargNext Set tNextTarg = qHandle("TargetRS").ID
					}
					ElseIf tNextSrc > tNextTarg {
						Set tSourceNext = qHandle("SourceRS").%Next()
						If tSourceNext Set tNextSrc = qHandle("SourceRS").ID
					}
					Else { // Equality
						Set tNextId = tNextTarg
					}
				}
			}
		}
		If tNextId = 0 {
			Set AtEnd = 1
			Quit
		}
		Set tRS = qHandle("Statement").%Execute(tNextId)
		Set tNext = tRS.%Next()
		Set Row=$lb(tRS.ID, tRS.TimeCreated, tRS.Session, tRS.Status, tRS.Error, tRS.Source, tRS.Target)
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Method to release the references held by the query.
ClassMethod SourceAndTargetEnumerateClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// Method to finalize the generated SQL query. Any modifications to JOIN order or the
/// FROM clause should be implemented in this callback.
/// The <var>pSelect</var>, <var>pFrom</var>, <var>pWhere</var> and <var>pOrder</var> arguments
/// represent the SELECT, FROM, WHERE and ORDER BY clauses of the query thus far.
/// The <var>pSelectTerms</var> and <var>pFromTerms</var> arguments are arrays that contain further
/// values and tables which have yet to be added to the respective clauses. The contents of these arrays
/// in combination with the state of the current Assistant can be used to determine what (if any)
/// modifications should be made to the query as constructed by the parser.
Method OnFinalizeSQL(Filter As EnsPortal.MsgFilter.Filter, ByRef pSelect As %String, ByRef pFrom As %String, ByRef pWhere As %String, ByRef pOrder As %String, ByRef pSelectTerms, ByRef pFromTerms) As %Status
{
	If '$D(..Tree) || ((..Tree(1,"sqldone")=2) && '(+$g(..SearchTables("selective")) && ((Filter.StartId'="")||(Filter.StartTime'="")||(Filter.EndId'="")||(Filter.EndTime'="")))) {
		Set tMaxRows = Filter.MaxRows
		Set:tMaxRows'="" pSelect = 	"SELECT TOP "_tMaxRows_" head.ID As ID"
	}
	#dim tSuperSessionManipulation = (pWhere [ "%SQLUPPER(""SuperSession""")
	If 'tSuperSessionManipulation || '..onFinalizeSQLForSuperSession(Filter, .pSelect, .pFrom, .pWhere, .pOrder, .pSelectTerms, .pFromTerms) {

		For i=1:1:pSelectTerms { 
			If '..isTermComplete(.pSelectTerms,pSelectTerms(i)) { 
				Set pSelect=pSelect_", "_pSelectTerms(i)
				Do ..updateTerm(.pSelectTerms,pSelectTerms(i),1)
			}
		}
		For i=1:1:pFromTerms { 
			If '..isTermComplete(.pFromTerms,pFromTerms(i)) {
				Set pFrom=pFrom_", "_pFromTerms(i)
				Do ..updateTerm(.pFromTerms,pFromTerms(i),1)
			}
		}

	}

	Do ..rewriteUsingAliasesIfNeeded(.pSelect, .pFrom, .pWhere, .pOrder, .pFromTerms)

	#; If using more than one table in the From (in addition to the Ens.MessageHeader)
	If ($Get(pFromTerms) > 1) && (..BodyClasses > 1) Set pWhere = pWhere_" GROUP BY head.ID "

	Quit $$$OK
}

/// Callback to add constraints to the main query based on the top level conditions
/// in the supplied <class>Filter</class> object. This method can be overridden in subclasses to
/// apply more specific logic if needed.
/// The last parameter xParams is a multi-dimentional array and is used to pass in any extended parameters.
Method addBasicConstraints(Filter As EnsPortal.MsgFilter.Filter, ByRef where As %String = "", Output pTimeQuery As %Integer, ByRef xParams As %String = "") As %Status
{
	Do:(..#CONVERTTIMERANGES=2) Filter.FillClientId()

	If (Filter.Status '= "") {
		Set where = where_" AND head.Status = '"_$replace(Filter.StatusLogicalToDisplay(Filter.Status),"'","''")_"'"
	}
	
	For config="Source","Target" {
		Set configFilter = $PROPERTY(Filter, config)
		Continue:(configFilter="")
		Set column = config _ "ConfigName"
		Set operator = $SELECT(configFilter [ "%" : "LIKE", 1 : "=")
		Set where = where_" AND head." _ column _ " " _ operator _ " '"_$replace(configFilter,"'","''")_"'"
	}
	
	If (Filter.IsError '= "") {
		Set where = where_" AND head.IsError = '"_$replace(Filter.IsError,"'","''")_"'"
	}
	Set tStartTime = Filter.StartTime
	Set tEndTime = Filter.EndTime
	If (tEndTime '= "") && ($P(tEndTime,".",2) = "") Set $P(tEndTime,".",2) = "999"
	If (tEndTime '= "") && ($$$timeCmp(tStartTime, tEndTime) > 0) {
		Set tStartTime = Filter.EndTime
		Set tEndTime = Filter.StartTime
	}

	Set tStartId = Filter.StartId
	Set tEndId = Filter.EndId
	If (tStartId > tEndId) && (tEndId '= "") {
		Set tStartId = Filter.EndId
		Set tEndId = Filter.StartId
	}

	Set pTimeQuery = 0
	// Special case where Start ID and End ID are the same
	// Query is more performant using the unique key
	Set uniqueId = 0
	If (tStartId '= "") && (tStartId = tEndId) {
		Set where = where_" AND head.%ID = '"_$replace(tStartId,"'","''")_"'"
		Set pTimeQuery = pTimeQuery - 2
		Set uniqueId = 1
	} Else {
		If (tStartId '= "") {
			Set where = where_" AND head.%ID >= '"_$replace(tStartId,"'","''")_"'"
			Set pTimeQuery = pTimeQuery - 1
		}
		If (tEndId '= "") {
			Set where = where_" AND head.%ID <= '"_$replace(tEndId,"'","''")_"'"
			Set pTimeQuery = pTimeQuery - 1
		}
	}

	If (tStartTime '= "") {
		Set tDone = 0
		If (..#CONVERTTIMERANGES=1) {
			Set tSQL = "SELECT TOP 1 %ID As ID FROM " _ $$$ClassSQLTable(Filter.#HEADERCLASS) _ " WHERE TimeCreated >= ? ORDER BY TimeCreated ASC, %ID ASC"
			Set tStartUTC = $$$timeLocaltoUTC(tStartTime)
			Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,tStartUTC)
			If tRS.%Next() && tRS.ID {
				Set where = where _ " AND head.%ID >= " _ tRS.ID
				Set tDone = 1
			}
		} ElseIf (..#CONVERTTIMERANGES=2) {
			Set tSQL = "SELECT TOP 1 %ID As ID FROM " _ $$$ClassSQLTable(Filter.#HEADERCLASS) _ " WHERE TimeCreated >= ? AND NodeId=? order by TimeCreated ASC, Id ASC"
			Set tStartUTC = $$$timeLocaltoUTC(tStartTime)
			Set tSC = $$$OK
			If Filter.ClientIDs.Count() {
				For tC=1:1:Filter.ClientIDs.Count() {Set tResults(tC)=Filter.ClientIDs.GetAt(tC)}
			} Else {
				Set tSC = ##class(Ens.ContextSearch).MessageBankNodes(,,.tResults)
			}
			If tSC {
				Set tNodeNum=$O(tResults(""),1,tNodeIdFull)
				While tNodeNum'="" {
					Set tNodeId=##class(Ens.Enterprise.MsgBank.Node).DisplayNameToId(tNodeIdFull)
					If (tNodeId'="") {
						Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,tStartUTC,tNodeId)
						If tRS.%Next() && tRS.ID {
							Set tNodeIDRange(tNodeId,0)=tRS.ID
							Set tDone = 1
						}
					}				
					Set tNodeNum=$O(tResults(tNodeNum),1,tNodeIdFull)
				}
			}
		}
		If 'tDone {
			If ((..#CONVERTTIMERANGES=2)&&(Filter.ClientIDs.Count()>0)) {
				#;Didn't find any when converting the date time ranges to IDs so make the query return nothing
				Set where = where_" AND 0=1"
			} Else {
				Set where = where_" AND head.TimeCreated >= '"_$replace(tStartTime,"'","''")_"'"
				Set pTimeQuery = pTimeQuery + 1
			}
		}
	}
	If (tEndTime '= "") {
		Set tDone = 0
		If (..#CONVERTTIMERANGES=1) {
			Set tSQL = "SELECT TOP 1 %ID As ID FROM " _ $$$ClassSQLTable(Filter.#HEADERCLASS) _ " WHERE TimeCreated <= ? ORDER BY TimeCreated DESC, %ID DESC"
			Set tEndUTC = $$$timeLocaltoUTC(tEndTime)
			Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,tEndUTC)
			If tRS.%Next() && tRS.ID {
				Set where = where _ " AND head.%ID <= " _ tRS.ID
				Set tDone = 1
			}
		} ElseIf (..#CONVERTTIMERANGES=2) {
			Set tSQL = "SELECT TOP 1 %ID As ID FROM " _ $$$ClassSQLTable(Filter.#HEADERCLASS) _ " WHERE TimeCreated <= ? AND NodeId=? order by TimeCreated DESC, Id DESC"
			Set tEndUTC = $$$timeLocaltoUTC(tEndTime)
			Set tSC = $$$OK
			If '$D(tResults) {
				If Filter.ClientIDs.Count() {
					For tC=1:1:Filter.ClientIDs.Count() {Set tResults(tC)=Filter.ClientIDs.GetAt(tC)}
				} Else {
					Set tSC = ##class(Ens.ContextSearch).MessageBankNodes(,,.tResults)
				}
			}
			If tSC {
				Kill tNodeIdFull
				Set tNodeNum=$O(tResults(""),1,tNodeIdFull)
				While tNodeNum'="" {
					Set tNodeId=##class(Ens.Enterprise.MsgBank.Node).DisplayNameToId(tNodeIdFull)
					If (tNodeId'="") {
						Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,tEndUTC,tNodeId)
						If tRS.%Next() && tRS.ID {
							Set tNodeIDRange(tNodeId,1)=tRS.ID
							Set tDone = 1
						}
					}				
					Set tNodeNum=$O(tResults(tNodeNum),1,tNodeIdFull)
				}
			}
		}
		If 'tDone {
			If ((..#CONVERTTIMERANGES=2)&&(Filter.ClientIDs.Count()>0)) {
				#;Didn't find any when converting the date time ranges to IDs so make the query return nothing
				Set where = where_" AND 0=1"
			} Else {
				Set where = where_" AND head.TimeCreated <= '"_$replace(tEndTime,"'","''")_"'"
				Set pTimeQuery = pTimeQuery + 1
			}
		}
	}

	#; Add the ID constraints for every node
	Set nodeRanges = 0, rangeNodeId = ""
	If $D(tNodeIDRange) {
		Set where = where_" AND ("
		Set tNodeId="", tVal0="", tVal1="", tFirst=1, tNoData = 0
		Set tNodeId=$O(tNodeIDRange(tNodeId))
		While tNodeId'="" {
			Set tIncludeCondition = 1
			Set tVal0=$G(tNodeIDRange(tNodeId,0))
			Set tVal1=$G(tNodeIDRange(tNodeId,1))
			If ((tStartTime'="")&&(tEndTime'="")) {
				If ((tVal0="")||(tVal1="")) {
					Set tNoData = 1,tIncludeCondition=0
				} ElseIf (+tVal1<+tVal0) {
					Set tNoData = 1,tIncludeCondition=0
				}
			}
			If tIncludeCondition {
				If tFirst {
					Set tFirst=0
					Set where = where_"("
				} Else {
					Set where = where_" OR ("
				}
				Set where = where _ "(head.NodeId="_tNodeId_")"
				If (tVal0'="") {
					Set where = where _ " AND (head.%ID >= " _ tVal0_")"
				}
				If (tVal1'="") {
					Set where = where _ " AND (head.%ID <= " _ tVal1_")"
				}
				#; Avoid previous page bottom message to appear a second time
				If $GET(xParams("PrevPageLastId", tNodeId)) {
					Set operator = $CASE(Filter.SortOrder, 1:">", :"<")
					Set where = where _ " AND (head.%ID" _ operator _ xParams("PrevPageLastId", tNodeId) _ ")"
				}
				Set where = where_")"

				Do $INCREMENT(nodeRanges)
				Set rangeNodeId = $CASE(nodeRanges, 1:tNodeId, :"")
			}
			Set tNodeId=$O(tNodeIDRange(tNodeId))
		}
		#; Only need to record 0=1 if first to ensure at least one condition.
		If tFirst&&tNoData { 
			Set where = where_"("
			Set where = where _ "(0=1)"
			Set where = where_")"
		} 	
		Set where = where_")"
	}

	Quit:(..#CONVERTTIMERANGES'=2) $$$OK

	#; add in node restriction for all of query if MsgBank.

	Do:(rangeNodeId'="") Filter.FillClientId(rangeNodeId)
	Set tSC = $$$OK
	Kill tResults
	If Filter.ClientIDs.Count() {
		For tC=1:1:Filter.ClientIDs.Count() {Set tResults(tC)=Filter.ClientIDs.GetAt(tC)}
	} ElseIf (uniqueId = 0) { // No need to add the NodeId criterion if a unique key is provided
		Set tSC = ##class(Ens.ContextSearch).MessageBankNodes(,,.tResults)
	}
	If tSC && $D(tResults) {
		Set where = where_" AND ("
		Set tNodeNum=$O(tResults(""),1,tNodeIdFull)
		While tNodeNum'="" {
			Set tNodeId=##class(Ens.Enterprise.MsgBank.Node).DisplayNameToId(tNodeIdFull)
			If (tNodeId'="") {
				Set where = where_$S(tNodeNum=1:"",1:" OR ")_"NodeId="_tNodeId
			}				
			Set tNodeNum=$O(tResults(tNodeNum),1,tNodeIdFull)
		}
		Set where = where_")"
	}

	Quit $$$OK
}

/// Apply additional Filter criteria to determine whether to display the current row returned by the ResultSet.
/// Return value 1 means display the current row.
/// <var>pPropVals</var> is an array of calculated property values to extend the display list if the filter passes.
/// The primary purpose of this filter is to allow for retrieval and matching of Virtual Document properties which
/// are not indexed using SearchTables.
Method postSQLFilter(pFilter As EnsPortal.MsgFilter.Filter, pRS As %SQL.StatementResult, ByRef pPropVals, pLevel = 1, pNode = "1", pInOR = 0) As %Boolean
{
	If pLevel = 1 {
		Kill ..ValNodes
		New %EnsCustomSTCache
	}
	
	If ('$data(..Tree)) {
		Quit 1
	}
	If (pNode '= "") && (2 = $get(@("..Tree("_pNode_",""sqldone"")"))) && 'pInOR {
		Quit 1
	}
	
	Set tType = @("..Tree("_pNode_",""type"")")
	If $Case(tType, "AND": 1, "OR": 1, :0) {
		Set tVal = 1
		Set tOR = (tType = "OR")
		Set k = ""
		For {
			Set k = $order(@("..Tree("_pNode_","""_k_""")"))
			Quit:(k = "")
			Continue:(k '= +k)
			Continue:('pInOR)&&('tOR)&&(2 = $get(@("..Tree("_pNode_","_k_",""sqldone"")")))
			Set tVal = ..postSQLFilter(pFilter, pRS, .pPropVals, pLevel+1, pNode_","_k, pInOR||tOR)
			#; skip evaluation of further peer nodes if the outcome for this level is now foreordained
			If ('tOR&&'tVal)||(tOR&&tVal) {
				Set @("..ValNodes("_pNode_","_k_")") = 1
				Quit
			}
		}
		If (pLevel = 1) && tVal && $data(..ValNodes) {
			Do finishVals()
		}
		Quit tVal
	}
	#; It's a leaf node - evaluate it as Object if not already done in SQL
	Set tDisplayOnly = $get(@("..Tree("_pNode_",""display"")"))
	Set tClass = @("..Tree("_pNode_",""class"")")
	Set tProp = $get(@("..Tree("_pNode_",""prop"")"))
	If (tProp '= "") {
		Set tValue = @("..Tree("_pNode_",""val"")")
	}
	
	If (tType = "Header") {
		If tDisplayOnly Quit 1
		Set tPropVal = $property(pRS, tProp)
		If tPropVal = $char(0) { ; don't distinguish Null from Empty
			Set tPropVal = ""
		}
	} ElseIf (tType = "Body") {
		If tDisplayOnly Quit 1
		Set asName = @("..Tree("_pNode_",""asname"")")
		If (tProp = "") {
			Set tMetadata = pRS.%GetMetadata()
			Set tBodyClassnameCol = $lg(tMetadata.columnIndex("BODYCLASSNAME"),1)
			Set tBodyIdCol = $lg(tMetadata.columnIndex("BODYID"),1)
			Quit (pRS.%GetData(tBodyClassnameCol) = tClass) && (pRS.%GetData(tBodyIdCol) = $property(pRS, asName))
		} Else {
			Set tPropVal = $property(pRS, asName)
			If tPropVal = $char(0) { ; don't distinguish Null from Empty
				Set tPropVal = ""
			}
		}
	} ElseIf (tType = "SearchTable") {
		Set tDocClass = @("..Tree("_pNode_",""docclass"")")
		If (tProp = "") {
			Set tMetadata = pRS.%GetMetadata()
			Set tBodyClassnameCol = $lg(tMetadata.columnIndex("BODYCLASSNAME"),1)
			Quit $classmethod(pRS.%GetData(tBodyClassnameCol),"%IsA",tDocClass)
		} Else {
			Set tIsCustom = $select(tClass="": 0, 1: +$get(..SearchTables(tClass)))
			If tIsCustom {
				If '$data(%EnsCustomSTCache(tClass,tProp))#2 {
					Set tMetadata = pRS.%GetMetadata()
					Set tBodyClassnameCol = $lg(tMetadata.columnIndex("BODYCLASSNAME"),1)
					Set tBodyIdCol = $lg(tMetadata.columnIndex("BODYID"),1)
					Do $classmethod(tClass,"GetPropertyList",.tPropsIndexed,.tPropList)
					Set tSTProps = ""
					Set tSTVProps = ""
					Set tKey = ""
					For {
						Set tKey = $order(..SearchTables(tClass,"prop",tKey))
						Quit:(tKey = "")
						If $listfind(tPropsIndexed,tKey) || $listfind(tPropList,tKey) {
							Set tSTProps = tSTProps _ $lb(tKey)
						}
						Else {
							Set tSTVProps = tSTVProps _ $lb(tKey)
						}
					}
					Set tBodyClass = pRS.%GetData(tBodyClassnameCol)
					If (tBodyClass '= "") && $classmethod(tBodyClass,"%IsA",tDocClass) {
						Set tDocId = pRS.%GetData(tBodyIdCol)
						Set %EnsCustomSTCache(tClass,"DocId") = tDocId
						If tDocId '= "" {
							If $listlength(tSTVProps) {
								Set tSC = $classmethod(tClass,"GetVirtualProperties",tDocId,tSTVProps,.tSTVirtVals)
								If $$$ISOK(tSC) {
									For i=1:1:$listlength(tSTVProps) {
										Set %EnsCustomSTCache(tClass,$listget(tSTVProps,i)) = $listget(tSTVirtVals,i)
									}
								}
							}
							If $listlength(tSTProps) {
								Try {
									Set tST = $classmethod(tClass,"DocIDOpen",tDocId)
									If $IsObject(tST) {
										For i=1:1:$listlength(tSTProps) {
											Try {
												Set %EnsCustomSTCache(tClass,$listget(tSTProps,i)) = $property(tST,$listget(tSTProps,i))
											}
											Catch {}
										}
									}
								}
								Catch {}
							}
						}
					}
				}
				Set tPropVal = $get(%EnsCustomSTCache(tClass,tProp))
				Set asName = $get(@("..Tree("_pNode_",""asname"")"))
				If asName '= "" Set pPropVals(asName) = tPropVal
			}
			Else {
				// !!! The following code doesn't take into account the UseSTIN logic, where asName2 is not defined !!!
				Set tPropId = @("..Tree("_pNode_",""propid"")")
				Set asName2 = @("..Tree("_pNode_",""asname2"")")
				If (tPropId '= $property(pRS, asName2)) {  ; no PropId, i.e no SearchTable entry for this record
					Quit 0
				}
				Set asName = @("..Tree("_pNode_",""asname"")")
				Set tPropVal = $property(pRS, asName)
				If tPropVal = $char(0) { ; don't distinguish Null from Empty
					Set tPropVal = ""
				}
				Set tPropType = @("..Tree("_pNode_",""proptype"")")
			}
		}
	} ElseIf $Case(tType, "VDocPath": 1, "VDocSegment": 1, :0) {
		Set asName = @("..Tree("_pNode_",""asname"")")
		If (tProp = "") {
			Set tMetadata = pRS.%GetMetadata()
			Set tBodyClassnameCol = $lg(tMetadata.columnIndex("BODYCLASSNAME"),1)
			Set tBodyIdCol = $lg(tMetadata.columnIndex("BODYID"),1)
			Quit (pRS.%GetData(tBodyClassnameCol) = tClass) && (pRS.%GetData(tBodyIdCol) = $property(pRS, asName))
		}
		
		Set f = $find(tProp, ":{")
		If ('f) && (tType = "VDocSegment") {
			Set f = $find(tProp, ":[")
		}
		If f {
			Set tDocType = $extract(tProp, 1, f-3)
			Set tPropPath = $extract(tProp, f-1, *)
		} ElseIf ":" = $extract(tProp, *) {
			Set tDocType = $extract(tProp, *-1)
			Set tPropPath = ""
		} Else {
			If ($extract(tProp) = ":") {
				Set $extract(tProp) = ""
			}
			Set tPropPath = tProp
			Set tDocType = ""
		}
		Set cMatch = $Case($extract(tPropPath), "[": "]", "{": "}", :"")
		If (cMatch '= "") {
			Set $extract(tPropPath) = ""
			Set tLast = $extract(tPropPath,$length(tPropPath))
			If (cMatch = tLast) {
				Set $extract(tPropPath, $length(tPropPath)) = ""
			}
		}
		If (tPropPath = "") {
			Quit 1
		}

		Set tObj = $classmethod(tClass,"%OpenId", pRS.BodyId)
		If '$IsObject(tObj) {
			Quit 0
		}
		Set tSC = $$$OK
		If (tType = "VDocPath") {
			If (tObj.DocType '= "") {
				Do tObj.GetValuesArray(tPropPath,, .tArray, .tSC, .tLongArray)
			}
			If (tDocType '= "") && (tDocType '= tObj.DocType) && '$data(tArray) {
				Set tObj.DocType = tDocType ; try again with query's DocType value
				Do tObj.GetValuesArray(tPropPath,, .tArray, .tSC, .tLongArray)
			}
		} Else {
			Do tObj.FindSegmentValuesArray(tPropPath,,.tArray,.tSC,tDocType,.tLongArray)
		}
		If $$$ISOK(tSC) {
			Set tPropVal = ""
		} Else { 
			If '$data(tArray) {
				Set tArray = 0
			}
			Set tPropVal = $system.Status.GetErrorText(tSC)
		}
		If '$data(tArray)&&'$data(tLongArray) {
			Quit $$match("")
		}
		Set (tMatch, neg) = $$isNegativeOp()
		Set (k,n)=""
		For {
			Set k = $order(tArray(k))
			Quit:(k = "")
			If (tMatch = neg) {
				Set tMatch = $$match(k)
			}
			If (tMatch '= neg) && neg {
				Quit
			}
			
			Set n = n + 1
			Set tNewLen = $length(tPropVal) + $length(k) + 2
			If tNewLen > 400 {
				If $length(tPropVal) < 400 {
					Set tPropVal = tPropVal _ "<" _ $extract(k,1, 400 - $length(tPropVal) - 8) _"...>..."
				}
			}
			Else {
				Set tPropVal = tPropVal _ "<" _ k _ ">"
			}
		}
		If ((tMatch = neg) || ('neg)) && $data(tLongArray) { // If not found and data in LongArray
			For k=1:1:tLongArray {
				If (tMatch = neg) {
					Set tMatch = $$match(tLongArray(k))
				}
				If (tMatch '= neg) && neg {
					Quit
				}
			}
		}
		If n = 1 {
			Set tPropVal = $extract(tPropVal, 2, *-1)
		}
		Set pPropVals(asName) = tPropVal
		Quit $S(tDisplayOnly:1,1:''tMatch)
	}
	If tDisplayOnly Quit 1
	Quit $$match(tPropVal)
match(propVal)
		Quit $Case(@("..Tree("_pNode_",""op"")")
				, "=": (propVal = tValue), "!=": (propVal '= tValue)
				, ">": (propVal > tValue), ">=": (propVal >= tValue)
				, "<": (propVal < tValue), "<=": (propVal <= tValue)
				, "Contains": ..Contains(propVal,tValue), "DoesNotContain": ..DoesNotContain(propVal,tValue)
				, "Matches": ..Matches(propVal,tValue), "DoesNotMatch": ..DoesNotMatch(propVal,tValue)
				, "In": ..In(propVal,tValue), "NotIn": ..NotIn(propVal,tValue)
				, "StartsWith": ..StartsWith(propVal,tValue), "DoesNotStartWith": ..DoesNotStartWith(propVal,tValue)
				, "Like": ..Like(propVal,tValue), "NotLike": ..NotLike(propVal,tValue)
				, "InFile": ..InFile(propVal,tValue), "NotInFile": ..NotInFile(propVal,tValue)
				, :1) ; default- if filter not supported, don't exclude
isNegativeOp()
		Quit $Case(@("..Tree("_pNode_",""op"")")
				, "=": 0, "!=": 1
				, ">": 0, ">=": 0
				, "<": 0, "<=": (tPropVal <= 0)
				, "Contains": 0, "DoesNotContain": 1
				, "Matches": 0, "DoesNotMatch": 1
				, "In": 0, "NotIn": 1
				, "StartsWith": 0, "DoesNotStartWith": 1
				, "Like": 0, "NotLike": 1
				, "InFile": 0,"NotInFile": 1
				, :0)
finishVals()
	Set gref0 = $Name(@("..ValNodes"))
	Set gref = gref0
	For {
		Set gref = $Query(@gref)
		Quit:(gref = "")
		Set tNode = $extract(gref, $length(gref0)+1,*-1)
		Quit:(tNode = "")
		Set k = $piece(tNode,",",$length(tNode,","))
		Set tNode = $extract(tNode, 1, *-$length(k)-1)
		If $extract(tNode) = "(" Set tNode = $extract(tNode,2,*)
		Do finishNode(tNode,k)
	}
	Quit
finishNode(pNode,k)
	For {
		Set k = $order(@("..Tree("_pNode_","""_k_""")"))
		Quit:(k = "")
		Continue:(k '= +k)
		Set node = pNode_","_k
		Set tType = @("..Tree("_node_",""type"")")
		If $Case(tType, "AND": 1, "OR": 1, :0) {
			Do finishNode(node,"")
		} Else {
			#; It's a leaf node - evaluate it as Object if not already done in SQL
			Set tClass = @("..Tree("_node_",""class"")")
			Set tProp = $get(@("..Tree("_node_",""prop"")"))
			If (tProp '= "") {
				Set tValue = @("..Tree("_node_",""val"")")
			}
			If $Case(tType,"VDocPath": 1, "VDocSegment": 1, :0) {
				Set asName = @("..Tree("_node_",""asname"")")
				If (tProp = "") || ($get(pPropVals(asName)) '= "") {
					Continue
				}
				
				Set f = $find(tProp,":{")
				If ('f) && (tType="VDocSegment") {
					Set f = $find(tProp, ":[")
				}
				If f {
					Set tDocType = $extract(tProp,1,f-3)
					Set tPropPath = $extract(tProp,f-1,*)
				} ElseIf ":" = $extract(tProp,*) {
					Set tDocType = $extract(tProp,*-1)
					Set tPropPath = ""
				} Else {
					If ":" = $extract(tProp) {
						Set $extract(tProp) = ""
					}
					Set tPropPath = tProp
					Set tDocType = ""
				}
				Set cMatch = $Case($extract(tPropPath), "[": "]", "{": "}", :"")
				If (cMatch '= "") {
					Set $extract(tPropPath) = ""
					If (cMatch = $extract(tPropPath, *)) {
						Set $extract(tPropPath, $length(tPropPath)) = ""
					}
				}
				If (tPropPath = "") {
					Continue
				}
		
				Set tObj = $classmethod(tClass,"%OpenId",pRS.BodyId)
				If '$IsObject(tObj) {
					Continue
				}
			
				If (tType = "VDocPath") {
					Do tObj.GetValuesArray(tPropPath,,.tArray,.tSC)
					If (tDocType'="") && (tDocType '= tObj.DocType) && '$data(tArray) {
						Set tObj.DocType = tDocType ; try again with query's DocType value
						Do tObj.GetValuesArray(tPropPath,,.tArray,.tSC)
					}
				} Else {
					Do tObj.FindSegmentValuesArray(tPropPath,,.tArray,.tSC,tDocType)
				}
				If $$$ISOK(tSC) {
					Set tPropVal = ""
				} Else {
					If '$data(tArray) {
						Set tArray = 0
					}
					Set tPropVal = $system.Status.GetErrorText(tSC)
				}
				If '$data(tArray) {
					Continue
				}
				Set (k2, n) = ""
				For {
					Set k2 = $order(tArray(k2))
					Quit:(k2 = "")
					Set tPropVal = tPropVal_"<"_k2_">"
					Set n = n + 1
				} 
				If (n = 1) {
					Set tPropVal = $extract(tPropVal, 2, *-1)
				}
				Set pPropVals(asName) = tPropVal
			}
		}
	}
	Quit
}

/// Helper method to hide the specified column when displaying the results of the generated SQL.
/// <var>pSchema</var> specifies the schema name, <var>pTable</var> specifies the table name, and 
/// <var>pColumnName</var> specifies the name of the column to hide.
Method addHiddenColumn(pSchema As %String, pTable As %String, pColumnName As %String) As %Status
{
	Set tUSchema = $zconvert(pSchema, "U")
	Set tUTable = $zconvert(pTable, "U")
	Set tUColumnName = $zconvert(pColumnName, "U")
	Set ..Hidden(tUSchema, tUTable, tUColumnName) = ""
	Quit $$$OK
}

/// Helper method to determine whether a specific column in the SQL results should be displayed.
/// <var>pSchema</var> specifies the schema name, <var>pTable</var> specifies the table name, and 
/// <var>pColumnName</var> specifies the name of the column to hide.
Method isHidden(pSchema As %String, pTable As %String, pColumnName As %String) As %Boolean
{
	Set tUSchema = $zconvert(pSchema, "U")
	Set tUTable = $zconvert(pTable, "U")
	Set tUColumnName = $zconvert(pColumnName, "U")
	Set tHidden = 0
	Try {
		Set tHidden = ''$data(..Hidden(tUSchema, tUTable, tUColumnName))
	}
	Catch { }
	Quit tHidden
}

/// Parse the list of filter terms and conditions into a local tree
Method parseTerms(pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Kill ..Tree
	New %tree
	Set tSubClassRS = ##class(%Library.ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set ..NumSearchTabConds=0
	Set tNode = "1,1", tLevel = 2, %tree(1,"type") = "", ..BodyClasses = 0, ..SearchTables = 0
	For i=1:0 {
		Set tTerm = pFilter.NextTerm(.i)
		Quit:'$IsObject(tTerm)
		If tTerm.Type = "OR" {
			Set tParentType=$$parentNodeType()
			If tParentType = "OR" {
				Do openNode()
			} ElseIf tParentType = "AND" {
				Do insertGrandparent("OR")
			} Else {
				Do insertParent("OR")
			}
		} ElseIf ("AND" = $$parentNodeType()) || $$nodeIsOpen() {
			Do addTerm()
		} Else {
			Do insertParent("AND")
			Do addTerm()
		}
	}
	Kill %tree(1,"type")
	Merge ..Tree = %tree(1)
	Do ..reduceTree()
	#; IN is needed in all cases except simple equality condition to generate correct boolean combinations
	Set ..UseSTIN = ((..NumSearchTabConds > 1) || (..NumSearchTabConds = 1 && (("=" '= $extract(..NumSearchTabConds(1))) || ("" = $extract(..NumSearchTabConds(1),2,*)))))
	Quit $$$OK

addTerm()
	Set bkLevel = tLevel
	If tTerm.Type = "Header" { ; Make sure we handle things for display conditions
		If "" = $$parentNodeType() {
			Do insertParent("AND")
		}
	}
	Else {
		If "AND" '= $$parentNodeType() {
			Do insertParent("AND")
		} Else {
			Do openNode()
		}
		Set @("%tree("_tNode_",""type"")") = tTerm.Type
		Set @("%tree("_tNode_",""class"")") = tTerm.SourceClass
		If (tTerm.Type = "SearchTable") {
			If ('$data(..SearchTables(tTerm.SourceClass))) {
				Set tIsCustom = 0
				Try { Set tIsCustom = $classmethod(tTerm.SourceClass,"%Extends","Ens.CustomSearchTable") }
				Catch {}
				Set ..SearchTables(tTerm.SourceClass) = tIsCustom
				Set ..SearchTables = ..SearchTables + 1
				Set tDocClass = ""
				Try {
					Set tDocClass = $parameter(tTerm.SourceClass,"DOCCLASS")
				}
				Catch {}
				If (tDocClass '= "") && $$$ISOK(tSubClassRS.Execute(tDocClass)) {
					Set tSubClasses = $LB(tDocClass)
					While tSubClassRS.Next() {
						Set tSubClass = tSubClassRS.Get("Name")
						If (tSubClass '= "") {
							Set tSubClasses = tSubClasses _ $LB(tSubClass)
						}
					}
					Set ..SearchTables(tTerm.SourceClass,"docClassList") = tSubClasses
				}
			}
		} ElseIf '$data(..BodyClasses(tTerm.SourceClass)) {
			Set ..BodyClasses(tTerm.SourceClass) = ""
			Set ..BodyClasses = ..BodyClasses + 1
		}
	}
	#; Process display values in front of first IF condition to prevent them from being subject to boolean logic
	Set tRealTerms = 0
	For j=1:1:tTerm.Conditions.Count() { 
		Set tCond = tTerm.Conditions.GetAt(j)
		Continue:('$IsObject(tCond) || (tCond.Prop = ""))
		If tCond.DisplayOnly {
			Do addCond()
		}
		Else {
			Set tRealTerms = tRealTerms + 1
			Set tRealTerms(tRealTerms) = tCond
		}
	}
	For j=1:1:tRealTerms {
		Set tCond = tRealTerms(j)
		If $Case(tCond.JoinOp, "IF": 1, "": 1, $$parentNodeType(): 1, :0) {
			Do addCond()
		} Else {
			Do insertParent(tCond.JoinOp)
			Do addCond()
		}
	}
	Set tNode = $piece(tNode,",",1,bkLevel)
	Set tLevel = bkLevel
	Quit
addCond()
	Do openNode()
	Set tProperty = tCond.Prop
	Set tPropVal = tCond.OpVal
	Set tOperator = tCond.Op
	If ..#CONVERTTIMERANGES && (tTerm.Type = "Header") && (tProperty = "TimeCreated") && $case(tOperator, "<": 1, "<=": 1, ">": 1, ">=": 1, :0) {
		Set tOrderSeq = $case(tOperator, ">": "ASC", ">=": "ASC", : "DESC")
		Set tSQL = "SELECT TOP 1 %ID As ID FROM " _ $$$ClassSQLTable(tTerm.SourceClass) _ " WHERE TimeCreated " _ tOperator _ " ? ORDER BY TimeCreated " _ tOrderSeq _ ", %ID " _ tOrderSeq
		Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,tPropVal)
		If tRS.%Next() && tRS.ID {
			#; Since we found the first matching ID, the converted range must be inclusive
			Set tOperator = $case(tOperator, "<": "<=", ">": ">=", : tOperator)
			Set tProperty = "%ID"
			Set tPropVal = tRS.ID
		}
	}
	Set @("%tree("_tNode_",""type"")") = tTerm.Type
	Set @("%tree("_tNode_",""class"")") = tTerm.SourceClass
	Set @("%tree("_tNode_",""prop"")") = tProperty
	Set @("%tree("_tNode_",""op"")") = tOperator
	Set @("%tree("_tNode_",""val"")") = tPropVal
	Set @("%tree("_tNode_",""display"")") = tCond.DisplayOnly
	If (tTerm.Type = "SearchTable") && 'tTerm.Disabled {
		Set ..NumSearchTabConds = ..NumSearchTabConds+1
		Set ..NumSearchTabConds(..NumSearchTabConds) = tCond.Op_tCond.OpVal
		If (tCond.Op="=")&&'+$get(..SearchTables("selective")) {
			Do ##class(Ens.VDoc.SearchTableGenerator).getPropId(tTerm.SourceClass,tProperty,,,.tUnselective)
			Set ..SearchTables("selective") = 'tUnselective
		}
		If (tTerm.SourceClass '= "") && $get(..SearchTables(tTerm.SourceClass)) {
			Set ..SearchTables(tTerm.SourceClass,"prop",tCond.Prop) = ""
		}
	}
	Quit
parentNodeType()
	Quit @("%tree("_$piece(tNode,",",1,tLevel-1)_",""type"")")
nodeIsOpen()
	Quit '$data(@("%tree("_tNode_")"))
openNode()
	If '$$nodeIsOpen() {
		Set $piece(tNode,",",tLevel) = $piece(tNode,",",tLevel) + 1
	}
	Quit
insertParent(type)
	Set tNewNode = tNode_",1"
	Merge tSub = @("%tree("_tNode_")")
	Kill @("%tree("_tNode_")")
	Merge @("%tree("_tNewNode_")") = tSub
	Kill tSub
	Set @("%tree("_tNode_",""type"")") = type
	Set tNode = tNode_",1"
	Set tLevel = tLevel + 1
	Do openNode()
	Quit
insertGrandparent(type)
	Set tLevel = tLevel - 1
	Set tNode = $piece(tNode,",",1,tLevel)
	Do insertParent(type)
	Quit
}

/// Reduce Terms tree if possible by eliminating common terms
Method reduceTree()
{
}

/// Take from Terms tree whatever is best added to the SQL statement
/// Return 0 means no SQL for node, 1 means node was partly done in SQL, 2 means node was completely accounted for in SQL
/// <var>pAllowEmptyWhere</var> indicates that we are dealing with a display value, or a tree of display values.
Method addSQLTerms(ByRef aSelect, ByRef aFrom, Output xWhere, level = 1, tNode = "1", Output pAllowEmptyWhere As %Boolean, pBitmapIndexUsed As %Boolean = 0) As %Integer
{
	Set xWhere = ""
	Set pAllowEmptyWhere = 0
	If '$data(..Tree) Quit 2
	Set tType = @("..Tree("_tNode_",""type"")")
	If $Case(tType, "AND": 1, "OR": 1, :0) {
		Set (tSqlEmpty, tSqlSure) = 1
		Set (tWhere, k, tGiveUp) = ""
		For {
			Set k = $order(@("..Tree("_tNode_","""_k_""")"))
			Quit:(k = "")
			Continue:(k '= +k)
			Set tSql = ..addSQLTerms(.aSelect, .aFrom, .tWhere, level+1, tNode_","_k,.tAllowEmptyWhere,pBitmapIndexUsed)
			Continue:tGiveUp
			If (tSql < 2) Set tSqlSure=0
			If (tType = "AND") {
				If (tWhere '= "") {
					Set xWhere = xWhere_$select(tSqlEmpty: "(", 1:" AND ")_tWhere
					Set tSqlEmpty = 0
				}
			} ElseIf (tWhere '= "") {
				Set xWhere = xWhere_$select(tSqlEmpty: "(", 1:" OR ")_tWhere
				Set tSqlEmpty = 0
			} ElseIf 'tAllowEmptyWhere {
				//w:'tSql !,"Assert: GOT SQL 0 in OR for empty Where"
				Set xWhere = ""
				#; give up - no point in testing other OR conditions if this one is 1, but still traverse tree to identify all fields
				Set (tSqlEmpty, tGiveUp) = 1  
			}
		}
		#; Permit an empty where clause if no nodes produced SQL and tGiveUp hasn't been set
		If tSqlEmpty && 'tGiveUp Set pAllowEmptyWhere = 1
		If 'tSqlEmpty Set xWhere = xWhere_")"
		Set tSql = $select(tSqlEmpty && 'pAllowEmptyWhere: 0, 1: 1 + tSqlSure)
		If tSql Set @("..Tree("_tNode_",""sqldone"")") = tSql
		Quit tSql
	}
	#; It's a leaf node - do it in SQL if possible
	Set tClass = @("..Tree("_tNode_",""class"")")
	Set tProp = $get(@("..Tree("_tNode_",""prop"")"))
	Set tSql = 0
	Set tOp = $get(@("..Tree("_tNode_",""op"")"))
	Set tDisplayOnly = +$get(@("..Tree("_tNode_",""display"")"))
	Set pAllowEmptyWhere = tDisplayOnly
	Set tFullTable = $$$ClassSQLTable(tClass)
	Set tSchema = $piece(tFullTable, ".", 1)
	Set tTable = $piece(tFullTable, ".", 2)
	#; Try to hint if searching on super session
	#dim tSuperSessionIndexHint = 0
	If tType = "Header" {
		If 'tDisplayOnly {
			If (tProp="SuperSession") && '((tOp="=") && (@("..Tree("_tNode_",""val"")")="")) {
				#; need to handle %SQLUPPER(250) on the index
				#dim tSuperSessionProp = "SuperSession"
				#dim tSuperSessionValue = @("..Tree("_tNode_",""val"")")
				If ",=,!=,>,<,Contains,StartsWith,"[ (","_tOp_",") {
					If $Length(tSuperSessionValue) < 251 {
						Set tSuperSessionIndexHint = 1
					}
				}
				If tSuperSessionIndexHint {
					Set tSuperSessionProp = "%SQLUPPER(""SuperSession"",250)"
					Set tSuperSessionValue = "%SQLUPPER('"_tSuperSessionValue_"',250)"
				}
				Set xWhere = "head.ID IN (SELECT MessageHeader FROM Ens.SuperSessionIndex WHERE "_..GetSQLCondition(tOp, tSuperSessionProp, tSuperSessionValue, 0)_")"
				If tSuperSessionIndexHint {
					#dim tSuperSessionValueToReplace = "'"_$Replace(tSuperSessionValue,"'","''")_"'"
					#dim tModifiedxWhere = $Replace(xWhere,tSuperSessionValueToReplace,tSuperSessionValue)
					If tModifiedxWhere '= xWhere {
						Set xWhere = tModifiedxWhere
					} Else {
						#; fall back to not trying hint
						Set xWhere = "head.ID IN (SELECT MessageHeader FROM Ens.SuperSessionIndex WHERE "_..GetSQLCondition(tOp, "SuperSession", @("..Tree("_tNode_",""val"")"), 0)_")"
					}
				}
			} Else { 
				Set xWhere = ..GetSQLCondition(tOp,"head."_tProp, @("..Tree("_tNode_",""val"")"), 1)
			}
		}
		Set tSql = $select(tDisplayOnly: 2, xWhere = "": 1, 1: 2)
		Do ..addTerm(.aSelect,"head."_tProp,":"_tNode)
	} ElseIf tType = "Body" {
		Set asName = $select(..BodyClasses = 1: "Body", 1:$TR(tClass,".%","__"))_"_"_$select(tProp = "": "ID", 1:$Replace($TR(tProp,".%()","____"),"->","_"))
		/* If user quoted the property name since it is a reserved SQL name remove the quotes
		 	Look for _" to account for criteria with multiple body classes e.g.
				When asName = Body_"UserEnteredWithQuotes"
				then set asName = Body_UserEnteredWithQuotes
				or
				asName = PackagePart_PackagePart_Class_"UserEnteredWithQuotes"
				then set asName = PackagePart_PackagePart_Class_UserEnteredWithQuotes
			Strings PackagePart,Class & UserEnteredWithQuotes ought not to contain quotes
		*/
		If $Find(asName,$Char(95,34)) Set asName = $Replace(asName,$Char(34),"")
		Set @("..Tree("_tNode_",""asname"")") = asName
		If tProp = "" {
			Set tSql = 2
			Do ..addTerm(.aFrom,tFullTable,":"_tNode)
			Set xWhere = "head.MessageBodyClassName='"_tClass_"' AND head.MessageBodyId="_tFullTable_".%ID"
			Do ..addTerm(.aSelect,"head.MessageBodyClassName As BodyClassname",":"_tNode)
			Do ..addTerm(.aSelect,"head.MessageBodyId As BodyId",":"_tNode)
			If '..isHidden(tSchema, tTable, asName) {
				Do ..addHiddenColumn(tSchema, tTable, asName)
			}
			#; Since column is hidden do not need to check for multiple classes and use CASE
			Do ..addTerm(.aSelect,tFullTable_".%ID As "_asName,":"_tNode)
		} Else {
			Set tDone = 1
			Set tPropString = ""
			Set tClassKey = tClass
			For k=1:1:$length(tProp, ".") {
				Set tPropName = $piece(tProp, ".", k)
				Set tPropDef = ##class(%Dictionary.CompiledProperty).IDKEYOpen(tClassKey, tPropName, 0)
				If '$IsObject(tPropDef) {
					Set tDone = 0
					Quit
				}
				Set tPropType = $$$comClassKeyGet(tPropDef.Type,$$$cCLASSclasstype)
				#; Use the SqlFieldName if there is one instead of the property name
				Set tPropRef = $$$comMemberKeyGet(tClassKey,$$$cCLASSproperty,tPropName,$$$cPROPsqlfieldname)
				Set tPropString = tPropString _ $select(tPropRef'="":tPropRef,1:tPropName) _ $select(tPropType = "serial": "_", 1: "->")
				#; Reset tClassKey for use in the next iteration of this loop
				Set tClassKey = tPropDef.Type
			}
			If tDone {
				If $get(tPropType)'="" {
					Set tPropString = $extract(tPropString, 1, *-$select(tPropType="serial": 1, 1: 2))
				}
				If 'tDisplayOnly {
					Set xWhere = ..GetSQLCondition(tOp,tFullTable_"."_tPropString,@("..Tree("_tNode_",""val"")"),1)
				}
				Set tSql = $select(tDisplayOnly: 2, xWhere = "": 1, 1: 2)
				If (..BodyClasses > 1) {
					#; Only want to show the value if the body class is the class pointed to by the header
					Do ..addTerm(.aSelect,"CASE head.MessageBodyClassName WHEN '"_tClass_"' THEN "_tFullTable_"."_tPropString_" ELSE '' END  As "_asName,":"_tNode)
				} Else {
					Do ..addTerm(.aSelect,tFullTable_"."_tPropString_" As "_asName,":"_tNode)
				}
			}
			Else { // Assume -> syntax
				If 'tDisplayOnly {
					Set xWhere = ..GetSQLCondition(tOp,tFullTable_"."_$Replace(tProp,".","->"),@("..Tree("_tNode_",""val"")"),1)
				}
				Set tSql = $select(tDisplayOnly: 2, xWhere = "": 1, 1: 2)
				If (..BodyClasses > 1) {
					#; Only want to show the value if the body class is the class pointed to by the header
					Do ..addTerm(.aSelect,"CASE head.MessageBodyClassName WHEN '"_tClass_"' THEN "_tFullTable_"."_$Replace(tProp,".","->")_" ELSE '' END  As "_asName,":"_tNode)
				} Else {
					Do ..addTerm(.aSelect,tFullTable_"."_$Replace(tProp,".","->")_" As "_asName,":"_tNode)
				}
			}
		}
	} ElseIf tType="SearchTable" {
		Set tDocClass = $parameter(tClass,"DOCCLASS")
		Set @("..Tree("_tNode_",""docclass"")") = tDocClass
		Set tExtentClass = ##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(tClass)
		Set tSearchTableSupertable = $$$ClassSQLTable(tExtentClass)
		Set tIsCustomST = $select(tClass="": 0, 1: +$get(..SearchTables(tClass)))
		Set tValue = $get(@("..Tree("_tNode_",""val"")"))
		Set tInitSelect = ""
		Set tInitFrom = ""
		Set tInitWhere = ""
		Set tTableInFrom = 0
		set tHasTopParent=$$$comMemberDefined(tExtentClass,$$$cCLASSproperty,"TopParentId")
		If tProp = "" {
			Set tInitSelect = "head.MessageBodyClassName As BodyClassname"
			Set tSql = 2
			Set tDocClassList = $get(..SearchTables(tClass,"docClassList"))
			Set tDocClassCount = $listlength(tDocClassList)
			#; If we have better criteria to base the search on, then use literal substitution on the MessageBodyClassName value
			Set tDblParens = 0
			If (..#CONVERTTIMERANGES=2) || pBitmapIndexUsed || (..NumSearchTabConds > 1) || +$g(..SearchTables("selective")) {
				Set tDblParens = 1
			} Elseif 'tIsCustomST && ($E(..NumSearchTabConds(1))'="=") {
				Set tNext = $order(@("..Tree("_tNode_")"))
				If tNext'="" {
					#; If the Search Table value is either unselective or is just a display value, we don't want to use literal substitution on the MessageBodyClassName value 
					If '+$G(@("..Tree("_$P(tNode,",",1,*-1)_","_tNext_",""display"")")) {
						Set tNextProp = $G(@("..Tree("_$P(tNode,",",1,*-1)_","_tNext_",""prop"")"))
						Do ##class(Ens.VDoc.SearchTableGenerator).getPropId(tClass,tNextProp,,,.tNextIsUnselective)
						Set tDblParens = 'tNextIsUnselective
					}
				}
			}
			#; If we have a list of subclasses, use = or IN() to allow use of MessageBodyClassName index
			If (tDocClassCount) {
				If tDblParens {
					Set tInitWhere = "head.MessageBodyClassName"_$select(tDocClassCount = 1: "=(('"_$LG(tDocClassList,1)_"'))", 1: " IN ((('"_$LTS(tDocClassList,"')),(('")_"')))")
				} Else {
					Set tInitWhere = "head.MessageBodyClassName"_$select(tDocClassCount = 1: "='"_$LG(tDocClassList,1)_"'", 1: " IN ('"_$LTS(tDocClassList,"','")_"')")
				}
			}
			Else {
				Set tInitWhere = "0<>Ens.IsASub(head.MessageBodyClassName,"_$select(tDblParens:"(('"_tDocClass_"')))",1:"'"_tDocClass_"')")
			}
			If '..UseSTIN {
				Set tInitFrom = tSearchTableSupertable
				Set tTableInFrom = 1
				// Optionally include ParentId for Batch Document
				Set tInitWhere = tInitWhere _ " AND (head.MessageBodyId = "_tSearchTableSupertable_".DocId"_$S(tHasTopParent:" OR head.MessageBodyId=TopParentId",1:"")_")"
			}
			If tIsCustomST {
				Set tSqlFetch = 1
				Set tProcessTuples = $classmethod(tClass,"ProcessTuples")
				If tProcessTuples {
					Set tSelectPrefix = $select(..SearchTables = 1: "SchTbl", 1: $TR(tDocClass,".%","__"))
					Do ..processTuple(tNode,tClass,tSearchTableSupertable,tTableInFrom,tSelectPrefix,.tInitSelect,.tInitFrom,.tInitWhere,.tSqlFetch)
				}
				Else {
					Do $classmethod(tClass,"OnProcessCondition",tProp,tOp,tValue,tSearchTableSupertable,tTableInFrom,"",tDisplayOnly,.tInitSelect,.tInitFrom,.tInitWhere,.tSqlFetch)
				}
				Set tSql = $select(tSqlFetch: 2, 1: 1)
			}
			If tInitFrom '= "" {
				Do ..addTerm(.aFrom,tInitFrom,":"_tNode)
			}
			If tInitWhere '= "" {
				Set xWhere = tInitWhere
			}
			If tInitSelect '= "" {
				Do ..addTerm(.aSelect,tInitSelect,":"_tNode)
			}
		} Else {
			If 'tIsCustomST {
				Set tPropId = ##class(Ens.VDoc.SearchTableGenerator).getPropId(tClass,tProp,.tPropType,.tStoreNulls,.tUnselective)
				Set @("..Tree("_tNode_",""propid"")") = tPropId
				Set @("..Tree("_tNode_",""proptype"")") = tPropType
				Set @("..Tree("_tNode_",""storenulls"")") = tStoreNulls
				Set @("..Tree("_tNode_",""unselective"")") = tUnselective
				Set tValue = $Case(tPropType
							,"Boolean": $Case($ZCVT(tValue,"L"), "true": 1, "yes": 1, "on": 1, :''tValue)
							,"Integer": +tValue\1
							,"Numeric": +tValue
							,"String:CaseInsensitive": $ZCVT(tValue,"L")
							,:tValue)
			}
			Set @("..Tree("_tNode_",""val"")") = tValue
			Set asName = $select(..SearchTables = 1: "SchTbl", 1: $TR(tDocClass,".%","__"))_"_"_$TR(tProp,".%:-","____")
			Set @("..Tree("_tNode_",""asname"")") = asName
			If tIsCustomST {
				#; Check if already processed as part of a Tuple
				Set tPrevSql = $get(@("..Tree("_tNode_",""sqldone"")"))
				If tPrevSql Quit tPrevSql
				Set tSqlFetch = 1
				If ..UseSTIN { // Add this to make sure we have it
					Set tInitWhere = "head.MessageBodyId = "_tSearchTableSupertable_".DocID"
				}
				If $classmethod(tClass,"IsVirtualProperty",tProp) {
					Set tSqlFetch = 0
					Set tPropRef = "NULL"
				}
				Else {
					Set tPropRef = tSearchTableSupertable _ "." _ $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tProp,$$$cPROPsqlfieldname)
					Set tInitFrom = tSearchTableSupertable
					Set tTableInFrom = 1
					If 'tDisplayOnly {
						Set xSubWhere = ..GetSQLCondition(tOp,tPropRef,tValue,0)
						Set tInitWhere = $select(tInitWhere = "": xSubWhere, 1: tInitWhere _ $select(xSubWhere = "": "", 1: " AND "_xSubWhere))
					}
				}
				Set tInitSelect = tPropRef _ " As " _ asName
				Set tSC = $classmethod(tClass,"OnProcessCondition",tProp,tOp,tValue,tSearchTableSupertable,tTableInFrom,asName,tDisplayOnly,.tInitSelect,.tInitFrom,.tInitWhere,.tSqlFetch)
				If $$$ISOK(tSC) {
					If 'tSqlFetch { // Ensure BodyId is in the SELECT clause - we need it available so we have the Body ID for post-SQL filtering
						Do ..addTerm(.aSelect,"head.MessageBodyId As BodyId",":"_tNode)
					}
					Set tSql = $select(tSqlFetch: 2, 1: 1)
					If tInitFrom '= "" {
						Do ..addTerm(.aFrom,tInitFrom,":"_tNode)
					}
					If tInitWhere '= "" {
						Set xWhere = tInitWhere
					}
					If tInitSelect '= "" {
						Do ..addTerm(.aSelect,tInitSelect,":"_tNode)
					}
				}
			}
			Else {
				// Try Including TopParent
				Do ..addTerm(.aSelect,"(SELECT LIST(PropValue) FROM "_tSearchTableSupertable_" WHERE (head.MessageBodyId = DocId"_$S(tHasTopParent:" OR head.MessageBodyId=TopParentId",1:"")_") And PropId="_$S(""=tPropId:0,1:tPropId)_") As "_asName,":"_tNode)
				If tDisplayOnly {
					Set tSql = 2
				}
				Else {
					If ..UseSTIN {
						#; For negative ops, use NOT IN of the corresponding positive op. This allows exclusion of rows with multiple values where one value matches the negative op
						Set tInv = $$getInverseOp(tOp)
						If (tInv '= "") {
							Set tOp = tInv
						}
			
						If tOp '= "=" || $length(tValue) {
							Set xSubWhere = ..GetSQLCondition(tOp,"SchTbl.PropValue",tValue,0,tUnselective)
							Set xWhere = "("
							Set xWhere = xWhere_"head.MessageBodyId"_$select(tOp = tInv: " NOT", 1: "")_" IN (SELECT SchTbl.DocID FROM "_tSearchTableSupertable_" SchTbl WHERE "_
								"SchTbl.PropId = "_tPropId_$select(xSubWhere = "": "", 1: " AND "_xSubWhere)_")"
							if tHasTopParent {
								Set xWhere=xWhere_" OR (head.MessageBodyId"_$select(tOp = tInv: " NOT", 1: "")_" IN (SELECT SchTbl.TopParentId FROM "_tSearchTableSupertable_" SchTbl WHERE "_
								"SchTbl.PropId = "_tPropId_$select(xSubWhere = "": "", 1: " AND "_xSubWhere)_"))"
							}
							Set xWhere = xWhere_")"
						} Else {
							#; For =/!= on empty value, use a COUNT subquery to include or exclude rows where no SearchTable property exists. This allows exclusion of these from inverse op queries if desired, by ANDing prop!="" with the negative op condition
							Set xSubWhere = ..GetSQLCondition("!=","SchTbl.PropValue",tValue,0,tUnselective)
							// Add TopParent check
		  					Set xWhere = "0"_$select(tOp=tInv: "<>", 1: "=")_"(SELECT COUNT(*) FROM "_tSearchTableSupertable_" SchTbl WHERE (SchTbl.DocID = head.MessageBodyId"_$S(tHasTopParent:" OR head.MessageBodyId=TopParentId",1:"")_") AND "_
								"SchTbl.PropId = "_tPropId_$select(xSubWhere = "": "", 1: " AND "_xSubWhere)_")"
						}
						Set tSql = $select(xSubWhere = "": 1, 1: 2)
					} Else {
						Set asName2 = $select(..SearchTables=1: "SchTbl", 1: $TR(tDocClass,".%","__"))_"_PropId"
						Set @("..Tree("_tNode_",""asname2"")") = asName2
						Set xSubWhere = ..GetSQLCondition(tOp,tSearchTableSupertable_".PropValue",tValue,0,tUnselective)
						Set xWhere = tSearchTableSupertable_".PropId = "_tPropId
						If (xSubWhere '= "") {
							Set xWhere = xWhere_" AND "_xSubWhere
						}
						Set tSql = $select(xSubWhere = "": 1, 1: 2)
						If '..isHidden($piece(tSearchTableSupertable, "."), $piece(tSearchTableSupertable, ".", 2), asName2) {
							Do ..addHiddenColumn($piece(tSearchTableSupertable, "."), $piece(tSearchTableSupertable, ".", 2), asName2)
						}
						Do ..addTerm(.aSelect,tSearchTableSupertable_".PropId As "_asName2,":"_tNode)
					}
				}
			}
		}
	} ElseIf $Case(tType, "VDocPath": 1, "VDocSegment": 1, :0) {
		If (tProp = "") {
			Set tSql = 2
			Do ..addTerm(.aFrom,tFullTable,":"_tNode)
			Set xWhere = "head.MessageBodyClassName='"_tClass_"' AND head.MessageBodyId="_tFullTable_".%ID"
			Do ..addTerm(.aSelect,"head.MessageBodyClassName As BodyClassname",":"_tNode)
			Do ..addTerm(.aSelect,"head.MessageBodyId As BodyId",":"_tNode)
			Set asName = $select(..BodyClasses=1: "Body", 1: $TR(tClass,".%","__"))_"_ID"
			Set @("..Tree("_tNode_",""asname"")") = asName
			If '..isHidden(tSchema, tTable, asName) {
				Do ..addHiddenColumn(tSchema, tTable, asName)
			}
			Do ..addTerm(.aSelect,tFullTable_".%ID As "_asName,":"_tNode)
		} Else {
			Set tSql = 1
			Set f = $find(tProp,":{") 
			If ('f) && (tType = "VDocSegment") {
				Set f = $find(tProp, ":[")
			} 
			If f {
				Set tPropPath = $extract(tProp,f-1,*)
			} ElseIf ":" = $extract(tProp,*) {
				Set tPropPath = ""
			} Else {
				If ":" = $extract(tProp) {
					Set $extract(tProp) = ""
				}
				Set tPropPath = tProp
			}
			Set cMatch = $Case($extract(tPropPath),"[": "]", "{": "}", :"")
			If cMatch '= "" {
				Set $extract(tPropPath) = ""
				If cMatch = $extract(tPropPath,*) {
					Set $extract(tPropPath, $length(tPropPath)) = ""
				}
			}
			Set tProp = tPropPath
			#; don't put docType or {} or [] in asName for column; also do some translation for XML VDoc special syntax
			Set asName = $select(tProp = "": "ID", tClass="EnsLib.EDI.XML.Document": $replace($replace($replace($replace(tProp,"$","node"),"*","LastPos"),"-]","Last]"),"()",""), 1: tProp)
			If (asName '= "ID") {
				Set asName = $replace($TR(asName,".%:-(){}/[]@","____________"),"__","_")
				If $extract(asName) = "_" Set asName = $extract(asName,2,*)
				If $extract(asName,*) = "_" Set asName = $extract(asName,1,*-1)
			}
			Set asName = $select(..BodyClasses=1: "Body", 1: $TR(tClass,".%","__"))_"_"_asName
			Set @("..Tree("_tNode_",""asname"")") = asName
			Do ..addTerm(.aSelect,"null As "_asName,":"_tNode)
		}
	}
	If tSql Set @("..Tree("_tNode_",""sqldone"")") = tSql
	Quit tSql

getInverseOp(oper)
		Quit $Case(oper
				, "!=": "="
				, "DoesNotContain": "Contains"
				, "DoesNotMatch": "Matches"
				, "NotIn": "In"
				, "DoesNotStartWith": "StartsWith"
				, "NotLike": "Like"
				, "NotInFile": "InFile"
				, : "")
}

/// Helper method to create a tuple tree that can be passed in to the OnProcessTuple() method
/// of a CustomSearchTable class. The method first iterates over the parse tree to create the
/// an abstraction that is then passed to OnProcessTuple(). This method is also responsible for
/// processing the tree returned from OnProcessTuple() and pushing any updates back into the main parse tree.
Method processTuple(pNode As %String, pSearchTableClass As %String, pSQLTable As %String, pTableInFrom As %Boolean = 0, pSelectPrefix As %String = "SchTbl", ByRef pInitSelect As %String = "", ByRef pInitFrom As %String = "", ByRef pInitWhere As %String = "", ByRef pSqlFetch As %Boolean = 1)
{
	New %EnsCondTree
	Set tTopNode = $piece(pNode,",",1,$length(pNode,",")-1)
	Set tBaseKey = $piece(pNode,",",$length(pNode,","))
	Set tJoin = $get(@("..Tree("_tTopNode_",""type"")"))
	
	Set %EnsCondTree("join") = tJoin
	Set tKey = tBaseKey
	For {
		Set tKey = $order(@("..Tree("_tTopNode_","""_tKey_""")"))
		Quit:(tKey '= +tKey)
		Set tType = $get(@("..Tree("_tTopNode_","_tKey_",""type"")"))
		If tType = "SearchTable" {
			Set tCondition = ..getNodeCondition(tTopNode_","_tKey)
			Set %EnsCondTree($i(%EnsCondTree)) = tCondition
			Set %EnsCondTree(%EnsCondTree,"path") = tTopNode_","_tKey
			Set %EnsCondTree(%EnsCondTree,"sqlFetch") = '$classmethod(pSearchTableClass,"IsVirtualProperty",tCondition.Prop)
		}
		Else {
			Set tSubTree("join") = tType
			Do ..addTupleNodes(pSearchTableClass,tTopNode_","_tKey,.tSubTree)
			Merge %EnsCondTree($i(%EnsCondTree)) = tSubTree
			Set %EnsCondTree(%EnsCondTree,"path") = tTopNode_","_tKey
		}
	}
	Do $classmethod(pSearchTableClass,"OnProcessTuple",.%EnsCondTree,pSQLTable,pTableInFrom,pSelectPrefix,.pInitSelect,.pInitFrom,.pInitWhere,.pSqlFetch)
	Set tRef = $query(%EnsCondTree)
	For {
		Set tRef = $query(@(tRef))
		Quit:(tRef = "")
		Continue:(tRef '[ ",""path"")")
		Set tNodeRef = $piece(tRef,",""path"")",1)
		Set tDone = $get(@(tNodeRef_",""done"")"),0)
		If tDone {
			Set tSqlFetch = $get(@(tNodeRef_",""sqlFetch"")"),1)
			Set tPath = $get(@(tRef))
			Set @("..Tree("_tPath_",""sqldone"")") = $select(tSqlFetch: 2, 1: 1)
		}
	}
}

/// Iterate over subnodes of the parse tree and add them to the tuple to be passed
/// to the CustomSearchTable.
Method addTupleNodes(pSearchTableClass As %String, pTopNode As %String, ByRef pCondTree As %String)
{
	Set tKey = ""
	For {
		Set tKey = $order(@("..Tree("_pTopNode_","""_tKey_""")"))
		Quit:(tKey '= +tKey)
		Set tType = $get(@("..Tree("_pTopNode_","_tKey_",""type"")"))
		If tType = "SearchTable" {
			Set tCondition = ..getNodeCondition(pTopNode_","_tKey)
			Set pCondTree($i(pCondTree)) = tCondition
			Set pCondTree(pCondTree,"path") = pTopNode_","_tKey
			Set pCondTree(pCondTree,"sqlFetch") = '$classmethod(pSearchTableClass,"IsVirtualProperty",tCondition.Prop)
		}
		Else {
			Set tSubTree("join") = tType
			Do ..addTupleNodes(pSearchTableClass,pTopNode_","_tKey,.tSubTree)
			Merge pCondTree($i(pCondTree)) = tSubTree
			Set pCondTree(pCondTree,"path") = pTopNode_","_tKey
		}
	}
}

/// Single method to get the values from the parse tree into a Condition object.
Method getNodeCondition(pNode) As EnsPortal.MsgFilter.Condition
{
	Set tCondition = ##class(EnsPortal.MsgFilter.Condition).%New()
	Set tCondition.OpVal = $get(@("..Tree("_pNode_",""val"")"))
	Set tCondition.Prop = $get(@("..Tree("_pNode_",""prop"")"))
	Set tCondition.Op = $get(@("..Tree("_pNode_",""op"")"))
	Set tCondition.DisplayOnly = $get(@("..Tree("_pNode_",""display"")"))
	Quit tCondition
}

ClassMethod addTerm(ByRef pArray, pTerm As %String = "", pNodeValue As %String = "")
{
	If pTerm = "" Quit
	Set pArray = $get(pArray) + 1
	Set pArray(pArray) = pTerm
	Set tSubscript = $select($length(pTerm)<=230: pTerm, 1: $extract(pTerm,1,220)_".x"_$$$NUM($ZHex($ZCRC($extract(pTerm,221,*),7)),8))
	Set pArray(tSubscript) = pNodeValue
}

ClassMethod isTermComplete(ByRef pArray, pTerm As %String = "") As %Boolean
{
	If pTerm = "" Quit 0
	Set tSubscript = $select($length(pTerm)<=230: pTerm, 1: $extract(pTerm,1,220)_".x"_$$$NUM($ZHex($ZCRC($extract(pTerm,221,*),7)),8))
	Quit +$get(pArray(tSubscript))
}

ClassMethod updateTerm(ByRef pArray, pTerm As %String = "", pNodeValue As %String = "")
{
	If pTerm = "" Quit
	Set tSubscript = $select($length(pTerm)<=230: pTerm, 1: $extract(pTerm,1,220)_".x"_$$$NUM($ZHex($ZCRC($extract(pTerm,221,*),7)),8))
	Set pArray(tSubscript) = pNodeValue
}

/// Helper method to return a valid WHERE subclause condition for a supplied property
/// reference (<var>pProp</var>), operator (<var>pOperator</var>) and value (<var>pValue</var>).
/// The <var>pDisplay</var> flag controls whether the external display value is used for the value
/// comparison. This is generally needed for properties of standard objects, as the display value may
/// differ from the logical value.
ClassMethod GetSQLCondition(pOperator As %String, pProp As %String, pValue As %String, pDisplay As %Boolean = 0, pNoIndex As %Boolean = 0) As %String
{
	If (pValue = "") {
		Set pOperator = $case(pOperator
				, "=": $Select(pNoIndex:"(%NOINDEX @p = (('')) OR %NOINDEX @p Is Null)",1:"(@p = '' OR @p Is Null)")
				, "!=": $Select(pNoIndex:"(%NOINDEX @p <> (('')) AND %NOINDEX @p IS NOT Null)",1:"(@p <> '' AND @p IS NOT Null)")
				, ">": pOperator, ">=": pOperator
				, "<": pOperator, "<=": pOperator
				, "Contains": "[", "DoesNotContain": "NOT ["
				, "Matches": "0<>Ens_Util.Matches(,)", "DoesNotMatch": "0<>Ens_Util.DoesNotMatch(,)"
				, "In": "IN", "NotIn": "NOT IN"
				, "StartsWith": "%startswith", "DoesNotStartWith": "NOT %startswith"
				, "Like": "LIKE", "NotLike": "NOT LIKE"
				, "InFile": "0<>Ens_Util.InFile(,)", "NotInFile": "0<>Ens_Util.NotInFile(,)"
				, :"")
	}
	Else {
		Set pOperator = $case(pOperator
				, "=": pOperator
				,"!=": $Select(pNoIndex:"(%NOINDEX @p <> ((@v)) OR %NOINDEX @p Is Null)",1:"(@p <> @v OR @p Is Null)")
				, ">": pOperator, ">=": pOperator
				, "<": pOperator, "<=": pOperator
				, "Contains": "*[", "DoesNotContain": "*NOT ["
				, "Matches": "*0<>Ens_Util.Matches(,)", "DoesNotMatch": "*0<>Ens_Util.DoesNotMatch(,)"
				, "In": "IN", "NotIn": "NOT IN"
				, "StartsWith": "*%startswith", "DoesNotStartWith": "*NOT %startswith"
				, "Like": "*LIKE", "NotLike": "*NOT LIKE"
				, "InFile": "*0<>Ens_Util.InFile(,)", "NotInFile": "*0<>Ens_Util.NotInFile(,)"
				, :"")
	}
	If (pOperator = "") Quit ""
	
	If "*" = $extract(pOperator) {
		Set $extract(pOperator) = ""
	}
	Else {
		Set pDisplay = 0
	}
	If "LIKE" = $extract(pOperator,*-3,*) && ("%%" = $extract(pValue,*-2,*-1)) {
		Set pValue = "'"_$extract(pValue,1,*-3)_"' ESCAPE '"_$extract(pValue,*)_"'"
	}
	ElseIf "IN" = $extract(pOperator,*-1,*) {
		If ",," = $extract(pValue,*-2,*-1) {
			Set sep = $extract(pValue,*)
			Set pValue = $extract(pValue,1,*-3)
		} 
		Else {
			Set sep = ","
		}
		Set nval=""
		For in=1:1:$length(pValue,sep) {
			Set inp = $piece(pValue,sep,in)
			Set nval = nval_",'"_$replace(inp,"'","''")_"'"
		}
		Set pValue = "("_$extract(nval,2,*)_")"
	}
	Else { Set pValue = "'"_$replace(pValue,"'","''")_"'" }
	If pDisplay Set pProp = "%EXTERNAL("_pProp_")"
	If (pOperator [ "@p") {
		Quit $$replace^EnsUtil(pOperator,"@p",pProp,"@v",pValue)
	}
	ElseIf "NOT " = $extract(pOperator,1,4) {
		Quit:pNoIndex "NOT %NOINDEX "_pProp_" "_$extract(pOperator,5,*)_" (("_pValue_"))"
		Quit "NOT "_pProp_" "_$extract(pOperator,5,*)_" "_pValue
	}
	ElseIf "(,)" = $extract(pOperator,*-2,*) {
		Quit $Select(pNoIndex:"%NOINDEX ",1:"")_$piece(pOperator,",")_pProp_","_pValue_")"
	}
	Else {
		Quit:pNoIndex "%NOINDEX "_pProp_" "_pOperator_" (("_pValue_"))"
		Quit pProp_" "_pOperator_" "_pValue
	}
}

Method onFinalizeSQLForSuperSession(Filter As EnsPortal.MsgFilter.Filter, ByRef pSelect As %String, ByRef pFrom As %String, ByRef pWhere As %String, ByRef pOrder As %String, ByRef pSelectTerms, ByRef pFromTerms) As %Boolean [ Internal ]
{
	/*
		Modify based on SuperSession but if error preparing SQL fall back to standard OnFinalizeSQL.
		Example parameters:
			pSelect="SELECT TOP 10000000 head.ID As ID"
			pFrom=" FROM Ens.MessageHeader head"
			pWhere=" WHERE  head.SessionId = head.%ID AND (head.ID IN (SELECT MessageHeader FROM Ens.SuperSessionIndex WHERE %SQLUPPER(""SuperSession"",250) [ %SQLUPPER('SuperSession8292013118',250)))"
			pOrder=" ORDER BY head.ID"
			pSelectTerms=8
			pSelectTerms="head.ID"
			pSelectTerms="{fn RIGHT(%EXTERNAL(head.TimeCreated),999 )} As TimeCreated"
			pSelectTerms="head.SessionId As Session"
			pSelectTerms="head.Status As Status"
			pSelectTerms="CASE head.IsError WHEN 1 THEN 'Error' ELSE 'OK' END As Error"
			pSelectTerms="head.SourceConfigName As Source"
			pSelectTerms="head.TargetConfigName As Target"
			pSelectTerms="head.SuperSession"
			pSelectTerms","CASE head.IsError WHEN 1 THEN 'Error' ELSE 'OK' END As Error")=""
			pSelectTerms","head.ID")=1
			pSelectTerms","head.SessionId As Session")=""
			pSelectTerms","head.SourceConfigName As Source")=""
			pSelectTerms","head.Status As Status")=""
			pSelectTerms","head.SuperSession")=":1,1"
			pSelectTerms","head.TargetConfigName As Target")=""
			pSelectTerms","{fn RIGHT(%EXTERNAL(head.TimeCreated),999 )} As TimeCreated")=""
			pFromTerms=0

		Modifications:
			Select:
				head. to head.MessageHeader->
			From:
				Ens.MessageHeader to Ens.SuperSessionIndex
			Where: 
				(head.ID IN (SELECT MessageHeader FROM Ens.SuperSessionIndex WHERE %SQLUPPER(""SuperSession"",250) = %SQLUPPER('SuperSession82920131189',250)))
				to
				%SQLUPPER(""SuperSession"",250) = %SQLUPPER('SuperSession82920131189',250)
				head. to head.MessageHeader->
			Order: 
				Can leave head.ID in pOrder since ought to be the same order as Ens.SuperSessionIndex ordering
			All select terms: 
				head. to head.MessageHeader->
	*/

	#; initilize to not modified
	#dim tModified = 0

	#; Do not modify if pFromTerms
	If $Get(pFromTerms) Return tModified

	#; store parameters as passed in in case need to reset.
	#dim tParamsAtCallIn
	Merge tParamsAtCallIn("Select") = pSelect
	Merge tParamsAtCallIn("From") = pFrom
	Merge tParamsAtCallIn("Where") = pWhere
	Merge tParamsAtCallIn("Order") = pOrder
	Merge tParamsAtCallIn("SelectTerms") = pSelectTerms
	Merge tParamsAtCallIn("FromTerms") = pFromTerms

	Set pSelect = $Replace(pSelect, "head.", "head.MessageHeader->")

	Set pFrom = $Replace(pFrom, "Ens.MessageHeader", "Ens.SuperSessionIndex")

	Set pWhere = $Replace(pWhere, "(head.ID IN (SELECT MessageHeader FROM Ens.SuperSessionIndex WHERE ","(")
	#; remove last ) provided we did just make a change
	If ((pWhere '= tParamsAtCallIn("Where")) && ($Extract(pWhere,*-1,*) = "))")) Set pWhere = $Extract(pWhere,1,*-1)

	Set pWhere = $Replace(pWhere, "head.", "head.MessageHeader->")

	Try {
		#; Modify Select Terms
		#dim i
		#dim tTermToReplace, tTermToReplaceValue
		For i=1:1:pSelectTerms {
			Set tTermToReplace = pSelectTerms(i)
			Set tTermToReplaceValue = $Get(pSelectTerms(tTermToReplace))
			Set pSelectTerms(i) = $Replace(tTermToReplace, "head.", "head.MessageHeader->")
			Kill pSelectTerms(tTermToReplace)
			Set pSelectTerms(pSelectTerms(i)) = tTermToReplaceValue
		}
		#; Now use same code as OnFinalizeSQL
		For i=1:1:pSelectTerms { 
			If '..isTermComplete(.pSelectTerms,pSelectTerms(i)) { 
				Set pSelect=pSelect_", "_pSelectTerms(i)
				Do ..updateTerm(.pSelectTerms,pSelectTerms(i),1)
			}
		}

		#; Validate that will generate a valid SQL statement
		#dim tSQL = pSelect_pFrom_pWhere_pOrder
		If $IsObject($SYSTEM.SQL.Prepare(tSQL,2)) Set tModified = 1

	} Catch {/* $system.SQL.Prepare will throw an error if cannot prepare. Protect against errors from rewriting Select Terms */}

	If 'tModified Do ..resetForFinalizeSQL(.tParamsAtCallIn, .pSelect, .pFrom, .pWhere, .pOrder, .pSelectTerms, .pFromTerms)
	Return tModified
}

Method resetForFinalizeSQL(ByRef pParamsToResetTo, ByRef pSelect As %String, ByRef pFrom As %String, ByRef pWhere As %String, ByRef pOrder As %String, ByRef pSelectTerms, ByRef pFromTerms) [ Internal, Private ]
{
	Kill pSelect
	Kill pFrom
	Kill pWhere
	Kill pOrder
	Kill pSelectTerms
	Kill pFromTerms

	Merge pSelect = pParamsToResetTo("Select")
	Merge pFrom = pParamsToResetTo("From")
	Merge pWhere = pParamsToResetTo("Where")
	Merge pOrder = pParamsToResetTo("Order")
	Merge pSelectTerms = pParamsToResetTo("SelectTerms")
	Merge pFromTerms = pParamsToResetTo("FromTerms")
}

Method rewriteUsingAliasesIfNeeded(ByRef pSelect As %String, ByRef pFrom As %String, ByRef pWhere As %String, ByRef pOrder As %String, ByRef pFromTerms) [ Internal, Private ]
{
	/*	Look to see if need to rewrite with aliases
			1. If only one class involved then no need
			2. If no unqualified table name clashes then no need
		The Alias used is  the unqualified name with a number
	*/

	If ($Get(pFromTerms) < 2) || (..BodyClasses < 2) Return

	#dim tNeedToUseAliases = 0

	#dim tTableNum, tTable, tUnqualifiedTable, tUnqualifiedNumber
	#dim tTableSeenArray, tAliasArray, tUnqualifiedArray

	For tTableNum=1:1:pFromTerms {

		Set tTable = pFromTerms(tTableNum)
		Set tUnqualifiedTable = $Piece(tTable,".",*)

		If (tUnqualifiedTable '= "") && ('$Data(tTableSeenArray(tTable))#2){
			Set tTableSeenArray(tTable) = ""
			Set tUnqualifiedNumber = $Increment(tUnqualifiedArray(tUnqualifiedTable))
			Set tAliasArray = $Increment(tAliasArray)
			Set tAliasArray(tAliasArray)=$LB(tUnqualifiedTable, tTable, tUnqualifiedNumber)
			If 'tNeedToUseAliases && (tUnqualifiedNumber>1) Set tNeedToUseAliases = 1
		}

	}

	If tNeedToUseAliases {

		#dim tAliasNumber
		#dim tFromPartToModify, tFromPartModified
		#dim tColumnPartToModify, tColumnPartModified

		For tAliasNumber=1:1:tAliasArray {

			Set tUnqualifiedTable = $LG(tAliasArray(tAliasNumber),1)
			#; need to replace where unqualified more than 1
			If tUnqualifiedArray(tUnqualifiedTable) > 1 {

				Set tTable = $LG(tAliasArray(tAliasNumber),2)
				Set tUnqualifiedNumber = $LG(tAliasArray(tAliasNumber),3)

				Set tColumnPartToModify = tTable_"."
				Set tColumnPartModified = tUnqualifiedTable_tUnqualifiedNumber_"."
				Set pSelect = $Replace(pSelect,tColumnPartToModify,tColumnPartModified)
				Set pWhere = $Replace(pWhere,tColumnPartToModify,tColumnPartModified)
				Set pOrder = $Replace(pOrder,tColumnPartToModify,tColumnPartModified)

				Set tFromPartToModify = ", "_tTable
				Set tFromPartModified = ", "_tTable_" AS "_tUnqualifiedTable_tUnqualifiedNumber
				Set pFrom = $Replace(pFrom,tFromPartToModify,tFromPartModified)

			}

		}

	}

	Return
}

}
