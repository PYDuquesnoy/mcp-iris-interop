/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.MsgFilter.Assistant Extends EnsPortal.MsgFilter.Assistant [ CompileAfter = Ens.Enterprise.Portal.MsgFilter.Filter, System = 4 ]
{

/// The Message Bank Header table must be sorted by time and not ID, but
/// we can convert time ranges to ID ranges for each NodeId.
Parameter CONVERTTIMERANGES = 2;

Parameter SESSIONSUBSCRIPT = "MsgBankViewer";

/// Name of <class>Filter</class> to use for searches.
Parameter FilterClass = "Ens.Enterprise.Portal.MsgFilter.Filter";

/// Flag to indicate whether the only restrictions on the query are time-related
Property TimeOnly As %Integer;

/// Callback to create the <class>Filter</class> class for this Assistant.
/// The paging logic is implemented in this method based on the nextPageStartTime
/// and nextPageEndTime properties of the supplied proxyObject, as the ID values are not sequential.
ClassMethod CreateFilter(pSearchCriteria As %ZEN.proxyObject, Output pFilter As Ens.Enterprise.Portal.MsgFilter.Filter, pExcludeSequenceManager As %Boolean = 1) As %Status
{
	Set tStatus = ##super(pSearchCriteria, .pFilter, 1)
	If $$$ISERR(tStatus) Quit tStatus
	If (pSearchCriteria.nextPageStartTime '= "") && ((pSearchCriteria.nextPageStartTime >= pFilter.StartTime) || (pFilter.StartTime = "")) {
		Set pFilter.StartTime = pSearchCriteria.nextPageStartTime
	}
	If pSearchCriteria.nextPageEndTime && ((pSearchCriteria.nextPageEndTime <= pFilter.EndTime) || (pFilter.EndTime = "")) {
		Set pFilter.EndTime = pSearchCriteria.nextPageEndTime
	}
	Quit $$$OK
}

/// Callback to create a Zen proxyObject from a supplied <class>Filter</class>.
/// Sequence manager searches are always excluded.
ClassMethod CreateProxy(pFilter As Ens.Enterprise.Portal.MsgFilter.Filter, Output pSearchCriteria As %ZEN.proxyObject, pExcludeSequenceManager As %Boolean = 1) As %Status
{
	Quit ##super(pFilter, .pSearchCriteria, 1)
}

/// Helper method to return a valid ResultSet for the supplied <class>Filter</class> object.
/// The result set construction itself is wrapped by the <query>Enumerate</query> query.
ClassMethod GetResultSet(pFilter As Ens.Enterprise.Portal.MsgFilter.Filter, Output pResultSet As %ResultSet, pExecute As %Boolean = 1) As %Status
{
	Set tStatus = $$$OK
	Set pResultSet = ##class(%ResultSet).%New()

	Set pResultSet.ClassName = $classname($this)
	Set pResultSet.QueryName = "Enumerate"
	
	If pExecute {
		Set tStatus = pResultSet.Execute(pFilter)
	}
	Quit tStatus
}

/// List the messages matching the conditions in the supplied Filter.
/// The actual logic for this query is implemented in the <method>EnumerateExecute</method>,
/// <method>EnumerateFetch</method>, <method>EnumerateClose</method> and <method>EnumerateGetInfo</method>
/// methods.
Query Enumerate(Filter As Ens.Enterprise.Portal.MsgFilter.Filter) As %Query(ROWSPEC = "TimeCreated,ID,Client,Session,SessionId,Status,Error,Source,Target")
{
}

/// Initial method which parses the Filter into SQL terms and post-SQL terms. In the specific case where no
/// terms have actually been specified, the custom <query>BasicEnumerate</query> query is used to
/// create a result set. If the user does specify any terms, then this method constructs an inner result set
/// based on the SQL terms and calls the execute method of this inner result set.
ClassMethod EnumerateExecute(ByRef qHandle As %Binary, Filter As Ens.Enterprise.Portal.MsgFilter.Filter) As %Status
{
	Set qHandle = 0
	Set qHandle("Filter") = Filter
	Set qHandle("EndTime") = $select(Filter.Timeout: ($zh + Filter.Timeout), 1: "")
	Set qHandle("baseCols") = 9
	
	Set tAssistant = ..%New()
	Set tStatus = tAssistant.parseTerms(Filter)
	If $$$ISERR(tStatus) Quit tStatus
	Set qHandle("Assistant") = tAssistant
	
	Set dateLen = 999
	/* Always return full timestamp and truncate on client to allow for paging.
	If Filter.TimeFormat '= "" {
		Set dateLen = Filter.TimeFormat
	}
	*/
	
	Set tAssistant.TimeOnly = 1
	For tProp = "Source","StartId","EndId","Status","Target" {
		If $property(Filter, tProp) '= "" {
			Set tAssistant.TimeOnly = 0
			Quit
		}
	}
	If (Filter.StartTime '= "") && (Filter.EndTime '= "") {
		Set tAssistant.TimeOnly = 2
	}

	Set usingTerms = tAssistant.IsUsingTerms(Filter)
	// Use custom BasicEnumerate query if no restrictions other than SessionId or All.
	If (tAssistant.TimeOnly = 1) && ((Filter.Type = 0) || (Filter.Type = 3)) && (tAssistant.NumSearchTabConds = 0) && ('usingTerms) {
		Set tSQL = $classname($this)_":BasicEnumerate Class Query"
		Do ..LogQuery(tSQL,.tLogCounter)
		Set qHandle("LogCounter") = tLogCounter
		Set tRS = ##class(%Library.ResultSet).%New($classname($this)_":BasicEnumerate")
		Set tStatus = tRS.Execute(Filter)
		If $$$ISERR(tStatus) Quit tStatus
		If tLogCounter {
			Do ..UpdateQuery(tLogCounter,"execute")
		}
		
		Set qHandle("RS") = tRS
		Set qHandle("Metadata") = tRS.%GetMetadata()
		Set qHandle("Next") = 1
		Set qHandle("RowCount") = 0
		
		Quit tStatus
	}
	#; ^ with id inserted in paging onChangeResultsPage()
	Set prevPageLastId = "", basicParams = ""
	If ($L(Filter.EndTime,"^") > 1) {
		If ($P(Filter.EndTime,"^",2)'="") {
			Set prevPageLastId = $P(Filter.EndTime,"^",2)
		}
		Set Filter.EndTime = $P(Filter.EndTime,"^",1)
	} ElseIf ($L(Filter.StartTime,"^") > 1) {
		If ($P(Filter.StartTime,"^",2)'="") {
			Set prevPageLastId = $P(Filter.StartTime,"^",2)
		}
		Set Filter.StartTime = $P(Filter.StartTime,"^",1)
	}
	Set:(prevPageLastId'="") basicParams("PrevPageLastId", $E(prevPageLastId, 1, 3)) = prevPageLastId

	#; Add date/time restriction if not restricting to Ids. Need to do this after checking if basic query if not using search table.
	If (tAssistant.NumSearchTabConds = 0) && ('usingTerms) {
		If (Filter.StartTime="") && (Filter.StartId="") {Set Filter.StartTime="1970-01-02 00:00:00"}
		If (Filter.EndTime="") && (Filter.EndId="") {Set Filter.EndTime="2038-01-07 23:59:59"}
		#; Recheck to set TimeOnly = 2 inorder to use top count 
		If (Filter.StartTime '= "") && (Filter.EndTime '= "") {
			Set tAssistant.TimeOnly = 2
		}
	}
	
	#; Only use TOP for Session-Start queries which have either a restriction on Time or no other restrictions
	Set Filter.TopCount = $select(..#TOPCOUNT && ((0 = Filter.Type) && tAssistant.TimeOnly && ((tAssistant.TimeOnly = 2) || ((tAssistant.NumSearchTabConds = 0) && tAssistant.UseSTIN = 0))): ..#TOPCOUNT, 1: "")
	Set select = "SELECT "_$select(Filter.TopCount: "TOP "_Filter.TopCount, 1: "")_" "
	
	Set from = " FROM Ens_Enterprise_MsgBank.MessageHeader head"
	Set aFrom = 0
	Set where = ""
	
	//Set tNoCols = $listbuild("ID","TimeCreated","SessionId","Status")
	For asName = "TimeCreated", "ClientSessionId", "SessionId", "Status", "SourceConfigName", "BodyClassname", "ClientBodyClassname", "TargetConfigName" {
		Do tAssistant.addHiddenColumn("Ens_Enterprise_MsgBank", "MessageHeader", asName)
	}

	Set aSelect=0
	Do ..addTerm(.aSelect,"{fn RIGHT(%EXTERNAL(head.TimeCreated),"_dateLen_" )} As TimeCreated")
	Do ..addTerm(.aSelect,"head.Id As ID")
	Do ..addTerm(.aSelect,"(SELECT Name FROM Ens_Enterprise_MsgBank.Node WHERE ID = head.NodeId) As Client")
	Do ..addTerm(.aSelect,"head.ClientSessionId As Session")
	Do ..addTerm(.aSelect,"head.SessionId As SessionId")
	Do ..addTerm(.aSelect,"head.Status As Status")
	Do ..addTerm(.aSelect,"CASE head.IsError WHEN 1 THEN '"_$$$Text("Error")_"' ELSE '"_$$$Text("OK")_"' END As Error")
	Do ..addTerm(.aSelect,"head.SourceConfigName As Source")
	Do ..addTerm(.aSelect,"head.TargetConfigName As Target")

	Set tBitmapIndex = (Filter.Source '= "") || (Filter.Target '= "") || (Filter.Status '= "")
	Do tAssistant.addSQLTerms(.aSelect,.aFrom,.xWhere,,,,tBitmapIndex)

	Set aSelect("head.ID") = 1
 	If $data(aSelect("head.MessageBodyClassName As BodyClassname")) {
	 	Do tAssistant.addHiddenColumn("Ens_Enterprise_MsgBank", "MessageHeader", "MessageBodyClassName")
 	}
 	If $data(aSelect("head.MessageBodyId As BodyId")) {
	 	Do tAssistant.addHiddenColumn("Ens_Enterprise_MsgBank", "MessageHeader", "MessageBodyId")
 	}
 	
	If (Filter.Type = 0) { // Session Start
		Set where = where_" AND head.SessionId = head.%ID"
	} ElseIf $Case(Filter.Type, 1:1, 2:1, :0) {
		Set tFilterType = Filter.TypeLogicalToDisplay(Filter.Type)
		If (Filter.Type = $$$eMessageTypeRequest) {
			Set tTerminateType = ##class(Ens.Enterprise.MsgBank.MessageHeader).TypeLogicalToDisplay($$$eMessageTypeTerminate)
			Set where = where_" AND head.Type IN ('"_tFilterType_"','"_tTerminateType_"')"
		} Else {
			Set where = where_" AND head.Type = '"_tFilterType_"'"
		}
	}
	
	Set tStatus = tAssistant.addBasicConstraints(Filter, .where,,.basicParams)
	If $$$ISERR(tStatus) Quit tStatus

	Set tNodeCount = 0
	If (Filter.ClientIDs.Count()=0) {
		Set tSC1 = ##class(Ens.ContextSearch).MessageBankNodes(,,.tNodeResults)
		Set tNodeCount = $S($$$ISERR(tSC1):0,'$D(tNodeResults):0,1:$O(tNodeResults(""),-1))
	}
	
	Set sortOrder = $S(Filter.SortOrder=2:" Desc", 1:"")
	If ((where'["TimeCreated") && ((Filter.ClientIDs.Count()>0)||(tNodeCount=1))) {
		Set order = " ORDER BY head.ID" _ sortOrder
	} Else {
		Set order = " ORDER BY head.TimeCreated" _ sortOrder _ ",head.ID" _ sortOrder
	}

	If xWhere '= "" {
		Set where = where _ " AND " _ xWhere
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
	
	Set qHandle("RS") = tRS
	Set qHandle("Metadata") = tRS.%GetMetadata()
	Set qHandle("Next") = 1
	Set qHandle("RowCount") = 0
	Quit tStatus
}

/// Method to finalize the generated SQL query. Any modifications to JOIN order or the
/// FROM clause should be implemented in this callback.
/// The <var>pSelect</var>, <var>pFrom</var>, <var>pWhere</var> and <var>pOrder</var> arguments
/// represent the SELECT, FROM, WHERE and ORDER BY clauses of the query thus far.
/// The <var>pSelectTerms</var> and <var>pFromTerms</var> arguments are arrays that contain further
/// values and tables which have yet to be added to the respective clauses. The contents of these arrays
/// in combination with the state of the current Assistant can be used to determine what (if any)
/// modifications should be made to the query as constructed by the parser.
/// In the specific case of a single SearchTable condition, the Message Bank code makes use
/// of the %STARTTABLE keyword to ensure that we use the SearchTable condition first.
Method OnFinalizeSQL(pFilter As EnsPortal.MsgFilter.Filter, ByRef pSelect As %String, ByRef pFrom As %String, ByRef pWhere As %String, ByRef pOrder As %String, ByRef pSelectTerms, ByRef pFromTerms) As %Status
{
	// If '$D(..Tree) or ..Tree(1,"sqldone")=2, then the postSQLFilter won't be removing any rows and it is therefore safe to limit the number of rows returned by the SQL statement itself
	If '$D(..Tree) || ((..Tree(1,"sqldone")=2) && '(+$g(..SearchTables("selective")) && ((pFilter.StartId'="")||(pFilter.StartTime'="")||(pFilter.EndId'="")||(pFilter.EndTime'="")))) {
		Set tMaxRows = pFilter.MaxRows
		Set:tMaxRows'="" pSelect = 	"SELECT TOP "_tMaxRows_" "
	}
	For i=1:1:pSelectTerms {
		If '..isTermComplete(.pSelectTerms,pSelectTerms(i)) { 
			Set pSelect=pSelect_pSelectTerms(i)_", "
			Do ..updateTerm(.pSelectTerms,pSelectTerms(i),1)
		}
	}
	Set pSelect = $extract(pSelect,1,*-2)
	
	If (..NumSearchTabConds = 1) && (..UseSTIN = 0) && $data(pFromTerms(1)) && ($length(pFromTerms(1),",") = 1) && (+$get(..SearchTables(pFromTerms(1))) || +$g(..SearchTables("selective"))) {
		Set pFrom = " FROM"

		// Ignore less selective indexes in favour of the composite index MessageBodyNode
		If $SYSTEM.SQL.Util.GetMapSelectability("Ens_Enterprise_MsgBank.MessageHeader", "MessageBodyNode") {
			Set pFrom  = pFrom _ " %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.NodeId"
			Set pFrom  = pFrom _ " %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.MessageBodyClassName"
			Set pFrom  = pFrom _ " %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.NSrc %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.SrcN"
			Set pFrom  = pFrom _ " %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.NTrg %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.TrgN"
			Set pFrom  = pFrom _ " %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.SourceConfigName %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.TargetConfigName"
			Set pFrom  = pFrom _ " %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.NodeSourceTime %IGNOREINDEX Ens_Enterprise_MsgBank.MessageHeader.NodeTargetTime"
		}

		// Use %STARTTABLE to join from SearchTable index back to main criteria
		Set pFrom = pFrom _ " %STARTTABLE "_pFromTerms(1)_", Ens_Enterprise_MsgBank.MessageHeader head"
	} Else {
		For i=1:1:pFromTerms { 
			If '..isTermComplete(.pFromTerms,pFromTerms(i)) {
				Set pFrom=pFrom_", "_pFromTerms(i)
				Do ..updateTerm(.pFromTerms,pFromTerms(i),1)
			}
		}
	}
	Quit $$$OK
}

/// Custom query to retrieve data from the Message Bank Message Header table when no query criteria have been specified.
/// The code implementing the query is in the <method>BasicEnumerateExecute</method>, <method>BasicEnumerateFetch</method> and
/// <method>BasicEnumerateClose</method> methods.
Query BasicEnumerate(Filter As Ens.Enterprise.Portal.MsgFilter.Filter) As %Query(ROWSPEC = "TimeCreated,ID,Client,Session,SessionId,Status,Error,Source,Target") [ SqlProc ]
{
}

ClassMethod BasicEnumeratePrepare(ByRef qHandle As %Binary, Filter As %String, p2 As %Integer, p3 As %String) As %Status
{
	Quit $$$OK
}

/// Method to initialise the retrieval of the data and create the query to retrieve information
/// for a specific Message Header.
ClassMethod BasicEnumerateExecute(ByRef qHandle As %Binary, Filter As Ens.Enterprise.Portal.MsgFilter.Filter) As %Status
{
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tTimeLen = 999
	/*
	If tTimeLen = "" {
		Set tTimeLen = 12
	}
	*/
	Set tSQL = "SELECT {fn RIGHT(%EXTERNAL(head.TimeCreated),"_tTimeLen_")} As TimeCreated, head.Id As ID, " _
		"(SELECT Name FROM Ens_Enterprise_MsgBank.Node WHERE ID = head.NodeId) As Client, " _
		"head.ClientSessionId As ClientSession, head.SessionId As Session, head.Status As Status, " _
		"CASE head.IsError WHEN 1 THEN 'Error' ELSE 'OK' END As Error, "_
		"head.SourceConfigName As Source, head.TargetConfigName As Target FROM Ens_Enterprise_MsgBank.MessageHeader head " _
		"WHERE head.ID = ?"
	
	Set tStatement.%SelectMode = 2
	
	
	Set tStatus = tStatement.%Prepare(tSQL)
	If $$$ISERR(tStatus) Quit tStatus
	Set qHandle("Statement") = tStatement
	Set qHandle("Descending") = (Filter.SortOrder = 2)
	Set qHandle("SessionStart") = (Filter.Type = 0)
	#; ^inserted in paging
	If ($L(Filter.EndTime,"^") > 1) {
		Set qHandle("PagingDontIncludeID") = $P(Filter.EndTime,"^",2)
		Set Filter.EndTime = $P(Filter.EndTime,"^",1)
	} ElseIf ($L(Filter.StartTime,"^") > 1) {
		Set qHandle("PagingDontIncludeID") = $P(Filter.StartTime,"^",2)
		If (qHandle("PagingDontIncludeID")="") Kill qHandle("PagingDontIncludeID")
		Set Filter.StartTime = $P(Filter.StartTime,"^",1)
	} Else {
		#;Need to remember if a StartTime (EndTime for oldest first) to know when to stop.
		If qHandle("Descending") {
			Set qHandle("StopOrderingTime") = ##class(Ens.DataType.UTC).DisplayToLogical(Filter.StartTime)
		} Else {
			Set qHandle("StopOrderingTime") = ##class(Ens.DataType.UTC).DisplayToLogical(Filter.EndTime)
		}
	}
	If qHandle("Descending") {
		Set qHandle("Time") = ##class(Ens.DataType.UTC).DisplayToLogical(Filter.EndTime)
	} Else {
		Set qHandle("Time") = ##class(Ens.DataType.UTC).DisplayToLogical(Filter.StartTime)
	}
	Set qHandle("ID") = ""
	Set qHandle("NodeId")=$S(Filter.ClientIDs.Count():$P($P(Filter.ClientIDs.GetAt(1),":"),"+",2),1:"")
	Set Filter.GeneratedSQL = $classname($this)_":BasicEnumerate Class Query"
	/* Need to initialize time to one before the one we want so initialize using opposite direction for fetch	*/
	Set qHandle("TimePassedToExecute")=qHandle("Time")
	If qHandle("Time")'="" {
		Set tDir = $select(qHandle("Descending"): 1, 1: -1)
		If (qHandle("NodeId")'="") && $SYSTEM.SQL.GetMapSelectability("Ens_Enterprise_MsgBank.MessageHeader","NodeIdTime") {
			Set qHandle("Time") = $order(^Ens.EntMsgBank.MessageHeaderI("NodeIdTime",qHandle("NodeId"),qHandle("Time")),tDir)
		} Else {
			Set qHandle("Time") = $order(^Ens.EntMsgBank.MessageHeaderI("TimeCreated",qHandle("Time")),tDir)
		}	
	}
	Quit $$$OK
}

/// Method which implements the custom fetch code which iterates over the TimeCreated index of the Message Header
/// to retrieve candidate headers before checking the SessionStart condition on the message.
ClassMethod BasicEnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tDir = $select(qHandle("Descending"): -1, 1: 1)
	Set Row = ""
	While 1 {
		If 'qHandle("ID") {
			If '$get(qHandle("NoOrder")) {
				If (qHandle("NodeId")'="") && $SYSTEM.SQL.GetMapSelectability("Ens_Enterprise_MsgBank.MessageHeader","NodeIdTime") {
					Set qHandle("Time") = $order(^Ens.EntMsgBank.MessageHeaderI("NodeIdTime",qHandle("NodeId"),qHandle("Time")),tDir)
				} Else {
					Set qHandle("Time") = $order(^Ens.EntMsgBank.MessageHeaderI("TimeCreated",qHandle("Time")),tDir)
				}
			}
			Else {
				Kill qHandle("NoOrder")
			}
			#;Use the StartTime to handle the cutoff for display. Need to account for order.
			If $D(qHandle("StopOrderingTime")) {
				Set tDiff = ($SYSTEM.SQL.DATEDIFF("ms",qHandle("Time"),qHandle("StopOrderingTime"))*$S((tDir>0):-1,1:1))
				If tDiff > 0 {	
					Set qHandle("Time") = ""
				}
			}
			
			If (qHandle("Time") = "") {
				Set AtEnd = 1
				Quit
			}
		}
	
		Set tHaveId = 0
		While 1 {
			If (qHandle("NodeId")'="") && $SYSTEM.SQL.GetMapSelectability("Ens_Enterprise_MsgBank.MessageHeader","NodeIdTime") {
				Set qHandle("ID") = $order(^Ens.EntMsgBank.MessageHeaderI("NodeIdTime",qHandle("NodeId"),qHandle("Time"),qHandle("ID")),tDir)
			} Else {
				Set qHandle("ID") = $order(^Ens.EntMsgBank.MessageHeaderI("TimeCreated",qHandle("Time"),qHandle("ID")),tDir)
			}
			If qHandle("ID") = "" Quit  // want next Time slot
		
			If qHandle("SessionStart")&&('$data(^Ens.EntMsgBank.MessageHeaderI("SessionId",qHandle("ID"),qHandle("ID")))) Continue  // not a session start message
			/* Continue if we do not want this id of the ones that would have been listed before it for the same time. */
			If $D(qHandle("PagingDontIncludeID")) { 
				If qHandle("TimePassedToExecute")'=qHandle("Time") {
					Kill qHandle("PagingDontIncludeID")
					Set tHaveId = 1
				} Else {
					If qHandle("PagingDontIncludeID")=qHandle("ID") Kill qHandle("PagingDontIncludeID")
				}
			} Else {
				Set tHaveId = 1
			}
			Quit
		}
		If 'tHaveId Continue
		
		// We have a valid ID
		Quit
	}
	If AtEnd Quit $$$OK
	Set tStatement = qHandle("Statement")
	Set tRS = tStatement.%Execute(qHandle("ID"))
	Do tRS.%Next() 
	Set Row = $lb(tRS.%Get("TimeCreated"), tRS.%Get("ID"), tRS.%Get("Client"), tRS.%Get("ClientSession"), tRS.%Get("Session"), tRS.%Get("Status"), tRS.%Get("Error"), tRS.%Get("Source"), tRS.%Get("Target"))
	Quit $$$OK
}

/// Method to release the references held by the query.
ClassMethod BasicEnumerateClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

}
