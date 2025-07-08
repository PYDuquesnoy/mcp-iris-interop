/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %quoter

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Library.Query">Defining and Using Class Queries</a>.</p>
/// The <b>%Query</b> class defines the basic interface used by class queries.
/// 
/// <p>Use the <b>%Query</b> class as a type for a class query if you wish to implement 
/// the query using custom-written <i>ObjectScript</i>.
Class %Library.Query [ System = 2 ]
{

Parameter EXTENT As STRING;

Parameter CONTAINID As INTEGER = 0;

Parameter SQLFUNCTION As INTEGER = 0;

Parameter ROWSPEC As ROWSPEC [ Flags = LIST ];

/// The SELECTMODE parameter allows the query author to declare the format of the values returned by the query.
/// It is the responsibility of the query implementation to properly format the values according to the SELECTMODE
/// value. If SELECTMODE is RUNTIME then the query implementation has to examine the current runtime setting and react
/// accordingly. The current runtime SELECTMODE value can be retrieved by calling $system.SQL.GetSelectMode(). The default value
/// of SELECTMODE is LOGICAL to preserve compatibility with older implementations.
/// REMEMBER - it is only a declaration and the implementation of the query is responsible for properly formatting the column
/// values in a manner consistent with the SELECTMODE setting.
Parameter SELECTMODE = "LOGICAL";

/// Close the query. <var>qHandle</var> is user-defined data.
ClassMethod Close(qHandle As %Binary) As %Status [ ServerOnly = 1 ]
{
	Quit $$$ERROR($$$MethodNotImplemented,"%Query::Close")
}

/// Func is a method that is used to invoke the query as a function, returning an instance of %SQL.StatementResult.
ClassMethod Func() As %SQL.StatementResult [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		// don't generate any code if it not for a query
	if %mode="method" quit $$$OK
		// %mode is "propertymethod" for a valid query. We don't have any way currently to detect a misuse of a query class
	if '$$$comMemberDefined(%class,$$$cCLASSquery,%property) quit $$$OK
		// Reset the formal list to the query declaration:
	$$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed)
	$$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSquery,%property,$$$cQUERYformalspecparsed)
	$$$comSubMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed,formal_qformal)
	set tExecuteArgs = ""
	if $listlength(qformal) {
		for tPtr = 1:1:$listlength(qformal) {
			set tArgumentName = $list($list(qformal,tPtr))
			set tExecuteArgs = tExecuteArgs_","_ $Select($Extract(tArgumentName,*-2,*)'="...":"."_tArgumentName,1:tArgumentName)
		}
	}
	set sc=$$SetOneQueryMeth^%occQuery(%class,%property,%method) quit:$$$ISERR(sc) sc
	$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSquery,%property,$$$cXXXXorigin)
	$$$comMemberKeyGetLvar(query,%class,$$$cCLASSquery,%property,$$$cQUERYsqlquery)
	$$$GENERATE($Char(9)_"try {")
	set tSelectMode = $Case($$$ucase(%parameter("SELECTMODE")), "RUNTIME": "", "ODBC": 1, "DISPLAY": 2, "LOGICAL": 0, : "")
	$$$GENERATE($Char(9,9)_"set tSC = .."_$$$QN(%property_"Execute")_"(.qHandle"_tExecuteArgs_")")
	$$$GENERATE($Char(9,9)_"if $$$ISERR(tSC) { throw ##class(%Exception.StatusException).CreateFromStatus(tSC) }")
	$$$GENERATE($Char(9,9)_"set tResult = ##class(%SQL.ClassQueryResultSet).%New($classname(),"_$zu(144,1,%property)_",.qHandle)")
	$$$GENERATE($Char(9)_"}")
	$$$GENERATE($Char(9)_"catch tException { if '$Isobject($Get(tResult)) { set tResult = ##class(%SQL.StatementResult).%New() } set tResult.%SQLCODE=tException.AsSQLCODE(),tResult.%Message=tException.AsSQLMessage() }")
	$$$GENERATE($Char(9)_"Quit tResult")
	QUIT $$$OK
}

/// Executes the query; This method is called with the query input parameters.
/// <var>qHandle</var> is user-defined data used to communicate amongst the various Query 
/// methods.
ClassMethod Execute(ByRef qHandle As %Binary) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a query
	If %mode="method" { RETURN $$$OK }
	
	#; Reset the formal list to the query declaration:
	$$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed)
	$$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSquery,%property,$$$cQUERYformalspecparsed)
	$$$comSubMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed,formal_qformal)
	set sc=$$SetOneQueryMeth^%occQuery(%class,%property,%method) RETURN:$$$ISERR(sc) sc

		#; If the query has a Requires keyword, the Query's Execute method "inherits" it
	$$$comMemberKeyGetLvar(requires,%class,$$$cCLASSquery,%property,$$$cQUERYrequires)
	if requires'="" {
		$$$comSubMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHrequires,requires)
	}

	$$$GENERATE("	RETURN $$$ERROR($$$MethodNotImplemented,""%Query::Execute"")")
	
	RETURN $$$OK
}

/// Fetch the next row of data from the query.
/// <p><var>qHandle</var> is query-defined data and is typically updated by <b>Fetch</b>.
/// <p>The <b>Fetch</b> method should set <var>Row</var> to be a $List of 
/// values corresponding to the columns of the query.  If we are past the end of the data
/// and no row is returned, <var>Row</var> should be set to null string ("").
/// If the non-empty row being returned is the last one, <var>AtEnd</var> could be
/// optionally set to 1, indicating that an additional call to <b>Fetch</b> may be avoided.
/// <p>
/// <var>Row</var> may also be subscripted. If any of the columns in the row are stream orefs
/// then the oref type information is lost in the <var>Row</var> $list encoded value. To retain
/// the oref type, place the oref into <var>Row(0,columnNumber)</var>. %Library.ResultSet recognizes
/// this form and will extract the column value as the subscripted value. 
ClassMethod Fetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ ServerOnly = 1 ]
{
	Quit $$$ERROR($$$MethodNotImplemented,"%Query::Fetch")
}

/// Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
ClassMethod SendODBC(ByRef qHandle As %Binary, ByRef array As %String, qacn As %Integer, ByRef %qrc As %Integer, ByRef piece As %Boolean, ColumnCount As %Integer) [ CodeMode = generator, GenerateAfter = (FetchODBC, Fetch), ServerOnly = 1 ]
{
	Set %code=0
	If %mode="method" QUIT $$$OK
	If $$$comSubMemberDefined(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"FetchODBC")&&($$$comSubMemberKeyGet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"FetchODBC",$$$cXXXXorigin)'="%Library.Query")||($$$comMemberDefined(%class,$$$cCLASSmethod,$$$nameMemberMethodName(%property,"FetchODBC"))) {
		$$$GENERATE("SPInnerLoop	Set rc=.."_$$$QN(%property_"FetchODBC")_"(.qHandle,.array,qacn,,.%qrc)")
		$$$GENERATE("	If $$$ISERR(rc) { Do ProcessError^%ourProcedure(rc,$get(%sqlcontext),.%qrc,.%msg) Do Logerr^%SYS.SQLSRV(%qrc,"""",""SP"",.%msg) }")
		$$$GENERATE("	If %qrc Set piece=0 Quit")
		$$$GENERATE("	For piece=1:1:ColumnCount { Goto:$zobjexport(array(qacn,piece),50) SPDone }")
		$$$GENERATE("	Goto SPInnerLoop")
		$$$GENERATE("SPDone	Set piece=piece+1 Quit")
	} 
	ElseIf ($$$comMemberDefined(%class,$$$cCLASSmethod,$$$nameMemberMethodName(%property,"Fetch"))||$$$comSubMemberDefined(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"Fetch")) {
		$$$GENERATE($c(9)_"kill row set %qrc=0,row=""""")
		$$$GENERATE($c(9)_"for {")
		$$$GENERATE($c(9,9)_"set rc=.."_$$$QN(%property_"Fetch")_"(.qHandle,.row,.atend)")
		$$$GENERATE($c(9,9)_"if $$$ISERR(rc) { set %qrc=-400 set:$isobject($get(%sqlcontext)) %sqlcontext.SQLCode=-400,%sqlcontext.Message=$g(%msg) do ProcessError^%ourProcedure(rc,$get(%sqlcontext),.%qrc,.%msg),Logerr^%SYS.SQLSRV(%qrc,"""",""SP"",.%msg) RETURN  }")
		$$$GENERATE($c(9,9)_"if row="""" { set %qrc=100 set:$isobject($get(%sqlcontext)) %sqlcontext.SQLCode=100 RETURN  }")
		$$$GENERATE($c(9,9)_"RETURN:$zobjexport(row,60)")
		$$$GENERATE($c(9)_"}")
		$$$GENERATE($c(9)_"RETURN")
	}
	
	RETURN $$$OK
}

/// <b>FetchRows</b> returns the next <var>FetchCount</var> rows in the query and updates handle for subsequent operations.
/// 	<var>FetchCount</var> is the number of rows to fetch. If <var>FetchCount</var> is zero then up to 24k of row data is
/// returned. <var>ReturnCount</var> contains the number of rows returned and <var>AtEnd</var> is true if there are no more
/// rows to be fetched. This method does not preserve swizzled streams.
ClassMethod FetchRows(ByRef qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a query
	If %mode="method" QUIT $$$OK
	
	$$$GENERATE("	Set RowSet="""",ReturnCount=0,AtEnd=0,sc=$$$OK")
	$$$GENERATE("	For {")
	$$$GENERATE("		Set sc=.."_$$$QN(%property_"Fetch")_"(.qHandle,.Row,.AtEnd)")
	#; If Fetch() returns a NULL row then we are done!!!
	#; We rely on Fetch() setting Row to NULL when AtEnd is TRUE.
	#; We don't need to check or set AtEnd - it will return to the user
	#; as set in Fetch()
	$$$GENERATE("		If Row'="""",$$$ISOK(sc) Set RowSet=RowSet_Row,ReturnCount=ReturnCount+1 If (ReturnCount=FetchCount)||(($l(RowSet)+($l(RowSet)\ReturnCount))>30000)||$get(AtEnd) Quit")
	$$$GENERATE("		If $$$ISERR(sc) { Set:$isobject($g(%sqlcontext)) %sqlcontext.SQLCode=$g(SQLCODE,-400),%sqlcontext.Message=$g(%msg) Quit }")
	$$$GENERATE("		If Row="""" Set AtEnd=1 Quit")
	$$$GENERATE("	}")
	$$$GENERATE("	Quit sc")
	QUIT $$$OK
}

/// Returns information about the query. It is used by the various <b>ResultSet</b> objects.<p>
/// Returns information about columns in the query result, parameters in the query formal list, and whether or not the result
/// 	contains enough information to form an ID value.<p>
/// 	This information is return in three pass-by-reference parmeters:<ul>
/// 	<li>colinfo - contains one list element for each column declared in ROWSPEC. The form is name:exttype:caption</li>
/// 	<li>parminfo - contains one list element for each formal paramter of the query in the form name:exttype</li>
/// 	<li>idinfo -  contains a list, the first element indicating the position of the ID, zero if not included
///     and the second element is the extent of these ID value.</li>
/// 	<li>qHandle - <Optional> query handle, used for dynamic queries</li></ul>
ClassMethod GetInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef idinfo As %List, ByRef qHandle As %Binary, extoption As %Integer = 0, ByRef extinfo As %List) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	If %mode="method" Quit $$$OK
	$$$GENERATE("	$$$SQLQueryInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",1,""colinfo"")")
	$$$GENERATE("	$$$SQLQueryInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",2,""parminfo"")")
	$$$GENERATE("	$$$SQLQueryInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",3,""idinfo"")")
	$$$GENERATE("	If extoption {")
	$$$GENERATE("		$$$SQLQueryInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",4,""extinfo"")")
	$$$GENERATE("	}")
	$$$GENERATE("	Quit $$$OK")
	Quit $$$OK
}

ClassMethod GetODBCInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef qHandle As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
	quit $$GenerateGetODBCInfo^%occQuery()
}

/// Prepare the query for execution. For static queries, this method probably just
/// returns $$$OK. For dynamic queries this method will set up the information
/// returned by <b>GetInfo</b>. It is used by the various <b>ResultSet</b> objects.
ClassMethod Prepare(ByRef qHandle As %Binary, statement As %String, containid As %Integer = 0, optional As %String) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
$$$OK
}

}
