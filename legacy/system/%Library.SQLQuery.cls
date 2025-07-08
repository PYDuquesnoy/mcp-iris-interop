/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Library.SQLQuery">Defining and Using Class Queries</a>.</p>
/// The <b>%SQLQuery</b> class is used for defining class queries based on SQL definitions.
Class %Library.SQLQuery Extends %Query [ Not ProcedureBlock, System = 2 ]
{

/// COMPILEMODE parameter deprecated. No longer used.
Parameter COMPILEMODE As STRING [ Constraint = "IMMEDIATE,DYNAMIC", Deprecated, Flags = ENUM ] = "IMMEDIATE";

Parameter SQLQUERY;

Parameter SELECTMODE = "RUNTIME";

/// 	Close the query associated with the handle
ClassMethod Close(%qHandle As %Binary) As %Status [ ProcedureBlock = 1, PublicList = SQLCODE, ServerOnly = 1 ]
{
	New SQLCODE
	Do:$isobject($get(%qHandle)) %qHandle.%Destruct() Kill %qHandle
	If $get(SQLCODE) { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%Message=$g(%msg) Set sc=$$$ERROR($$$SQLCode,SQLCODE,$get(%msg)) } Else { Set sc=$$$OK }
	RETURN sc
}

/// Func is a method that is used to invoke the query as a function, returning an instance of %SQL.StatementResult.
ClassMethod Func() As %SQL.StatementResult [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	quit $$GenerateFunc^%occQuery()
}

/// 	Execute is passed parameters for Query
/// 	Returns handle for subsequent operations
ClassMethod Execute(ByRef %qHandle As %Binary) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
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
	set sc=$$SetOneQueryMeth^%occQuery(%class,%property,%method) quit:$$$ISERR(sc) sc

		#; If the query has a Requires keyword, the Query's Execute method "inherits" it
	$$$comMemberKeyGetLvar(requires,%class,$$$cCLASSquery,%property,$$$cQUERYrequires)
	if requires'="" {
		for i=1:1:$length(requires,",") {
			set data=$zstrip($piece(requires,",",i),"<>W")
			set (origtype,type)=$zstrip($zconvert($piece(data,":",2),"U"),"<>W")
			if type=""  { RETURN $$$ERROR($$$RequiresInvalidTypeQuery,%property,data) }
			If $case(type,"R":0,"W":0,"U":0,"READ":0,"WRITE":0,"USE":0,:1) {
					#; See if this is multi-type type permission (RW, WR, READWRITE, WRITEREAD, etc.)
				for str="READ","WRITE","USE","R","W","U" {
					if type[str { set type=$replace(type,str,"") quit:type="" }
				}
				if type'="" { RETURN $$$ERROR($$$RequiresInvalidTypeQuery,%property,origtype) }
			}
		}
		$$$comSubMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHrequires,requires)
	}
	
	$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSquery,%property,$$$cXXXXorigin)
	$$$comMemberKeyGetLvar(query,%class,$$$cCLASSquery,%property,$$$cQUERYsqlquery)
	if origin'="" {
		set package=$$$ClassPackageName(origin)
		$$$GENERATE("#import "_package)
	}	
	$$$GENERATE("	#sqlcompile select="_%parameter("SELECTMODE"))
	set cursor = $get($$$tCURSORID(%class,$$$cCLASSquery,%property)) if 'cursor { set cursor = $increment($$$tCURSOR(%class)), $$$tCURSORID(%class,$$$cCLASSquery,%property)=cursor } set cursor = "Q"_cursor
	$$$GENERATE("#EXECUTE s %msqlvar=""%qHandle""")
	$$$GENERATE($c(9)_"&sql(DECLARE "_cursor_" CURSOR FOR")
	set qline=0
	for i=1:1:$length(query,$$$NL) set line=$piece(query,$$$NL,i) if line'="" set qline=qline+1,qline(qline)=line
	for i=1:1:qline-1 $$$GENERATE($char(9,9)_qline(i))
	if qline {
		$$$GENERATE($char(9,9)_qline(qline))
		$$$GENERATE($char(9,9)_")")
	}

	#; Open cursor
	$$$GENERATE("	&sql(OPEN "_cursor_")")
	$$$GENERATE("	If SQLCODE { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%Message=$g(%msg) Set sc=$$$ERROR($$$QueryCannotInstantiate,""SQLCODE = ""_SQLCODE_"" %msg = ""_$g(%msg)) } Else { Set sc=$$$OK }")
	$$$GENERATE("	Quit sc")
	QUIT $$$OK
}

/// 	FetchRows returns the next FetchCount rows in the query
/// 	Updates handle for subsequent operations
/// 	Returns $list for row or  "" if no more rows
ClassMethod FetchRows(ByRef %qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ CodeMode = generator, GenerateAfter = Fetch, PlaceAfter = Execute, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode(%property_"FetchRows")
 QUIT $$$OK
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
/// the oref type, place the oref into <var>Row(columnNumber)</var>. %Library.ResultSet recognizes
/// this form and will extract the column value as the subscripted value. 
ClassMethod Fetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = generator, PlaceAfter = Execute, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a query
	if %mode="method" QUIT $$$OK
		// Generate the code for IMMEDIATE mode.
	set rowspec=%parameter("ROWSPEC")
	set cursor = $get($$$tCURSORID(%class,$$$cCLASSquery,%property)) if 'cursor { set cursor = $increment($$$tCURSOR(%class)), $$$tCURSORID(%class,$$$cCLASSquery,%property)=cursor } set cursor = "Q"_cursor
	if rowspec '= "" {
		do parseRowSpec^%occQueryCompiler(%class,%property,rowspec,.degree)
		if 'degree set fcode=1,fcode(1)=" Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=-400,%sqlcontext.%Message=""No columns selected"" QUIT $$$ERROR($$$QueryNothingSelected,"""_%property_""")" $$$GENERATE(fcode(1)) merge $$$tEXTcode(%property_"FetchRows")=fcode quit $$$OK
		#; generate fetch
		set into=":Row(0,1)",rowexpr="$lb(Row(0,1)"
		for i=2:1:degree set into=into_",:Row(0,"_i_")",rowexpr=rowexpr_",Row(0,"_i_")"
		set rowexpr = rowexpr _ ")"
	} else {
		Set into="$$$SQLQueryInto("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_")",rowexpr="$$$SQLQueryExpr("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_")"
	}
 #; Generate the code for Fetch, FetchODBC, and FetchRows


	$$$GENERATE($Char(9)_"kill Row Set Row="""",AtEnd=0")
	$$$GENERATE($Char(9)_"&sql(FETCH "_cursor_" INTO "_into_")")
	$$$GENERATE($Char(9)_"If 'SQLCODE { Set sc=$$$OK,Row="_rowexpr_" }")
	$$$GENERATE($Char(9)_"ElseIf SQLCODE=100 { Set AtEnd=1,sc=$$$OK Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%ROWCOUNT=$g(%ROWCOUNT) }")
	$$$GENERATE($Char(9)_"Else { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.Message=$g(%msg) Set AtEnd=1,sc=$$$ERROR($$$SQLCode,SQLCODE,$get(%msg)) }")
	$$$GENERATE($Char(9)_"QUIT sc")
		#; Generate FetchRows
	set fcode=0
	set fcode=fcode+1,fcode(fcode)="	Set RowSet="""",ReturnCount=0,AtEnd=0"
	set fcode=fcode+1,fcode(fcode)="	For {"
	set fcode=fcode+1,fcode(fcode)="		Set sc=.."_$$$QN(%property_"Fetch")_"(.%qHandle,.Row,.AtEnd)"
	set fcode=fcode+1,fcode(fcode)="		If $$$ISOK(sc) { Set RowSet=RowSet_Row,ReturnCount=ReturnCount+1 Quit:(ReturnCount=FetchCount)||(($l(RowSet)+($l(RowSet)\ReturnCount))>30000)||(AtEnd) } Else { Set AtEnd=1 Quit }"
	set fcode=fcode+1,fcode(fcode)="	}"
	set fcode=fcode+1,fcode(fcode)="	Quit sc"
	merge $$$tEXTcode(%property_"FetchRows")=fcode
 QUIT $$$OK
}

/// Returns information about the query. It is used by the various <b>ResultSet</b> objects.
ClassMethod GetInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef idinfo As %List, ByRef %qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If %mode="method" Quit $$$OK
	$$$GENERATE("	$$$SQLQuerySQLInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",1,""colinfo"")")
	$$$GENERATE("	$$$SQLQuerySQLInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",2,""parminfo"")")
	$$$GENERATE("	$$$SQLQuerySQLInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",3,""idinfo"")")
	$$$GENERATE("	If extoption {")
	$$$GENERATE("		$$$SQLQuerySQLInfoItem("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",4,""extinfo"")")
	$$$GENERATE("	}")
	$$$GENERATE("	Quit $$$OK")
	Quit $$$OK
}

/// Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
ClassMethod SendODBC(ByRef %qHandle As %Binary, ByRef array As %String, qacn As %Integer, ByRef %qrc As %Integer, ByRef piece As %Boolean, ColumnCount As %Integer) [ CodeMode = generator, GenerateAfter = (FetchODBC, Fetch), PlaceAfter = Execute, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set %code=0
	If %mode="method" QUIT $$$OK
		// Generate the code for IMMEDIATE mode.
	If $$$comSubMemberDefined(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"FetchODBC")&&($$$comSubMemberKeyGet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"FetchODBC",$$$cXXXXorigin)'="%Library.Query")||($$$comMemberDefined(%class,$$$cCLASSmethod,$$$nameMemberMethodName(%property,"FetchODBC"))) {
		$$$GENERATE("SPInnerLoop	Set rc=.."_$$$QN(%property_"FetchODBC")_"(.%qHandle,.array,qacn,,.%qrc)")
		$$$GENERATE("	If $$$ISERR(rc) { Do ProcessError^%ourProcedure(rc,$get(%sqlcontext),.%qrc,.%msg) Do Logerr^%SYS.SQLSRV(%qrc,"""",""SP"",.%msg) }")
		$$$GENERATE("	If %qrc Set piece=0 Quit")
		$$$GENERATE("	For piece=1:1:ColumnCount { Goto:$zobjexport(array(qacn,piece),50) SPDone }")
		$$$GENERATE("	Goto SPInnerLoop")
		$$$GENERATE("SPDone	Set piece=piece+1 Quit")
	} 
	ElseIf ($$$comMemberDefined(%class,$$$cCLASSmethod,$$$nameMemberMethodName(%property,"Fetch"))||$$$comSubMemberDefined(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"Fetch")) {
		
			// If the Fetch method originates in %Library.SQLQuery, we can optimize some things...
		if ($$$comSubMemberKeyGet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"Fetch",$$$cXXXXorigin)="%Library.SQLQuery") {
			set cursor = $get($$$tCURSORID(%class,$$$cCLASSquery,%property)) if 'cursor { set cursor = $increment($$$tCURSOR(%class)), $$$tCURSORID(%class,$$$cCLASSquery,%property)=cursor } set cursor = "Q"_cursor
			set rowspec=%parameter("ROWSPEC")
			if rowspec '= "" {
				do parseRowSpec^%occQueryCompiler(%class,%property,rowspec,.degree)
				set into=":d1"
				for i=2:1:degree set into=into_",:d"_i
				set varlist=$tr(into,":")
			}
			else {
				set into="$$$SQLQueryIntoSendODBC("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",1)"
				set varlist="$$$SQLQueryIntoSendODBC("_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",0)"
			}
			$$$GENERATE($c(9)_"set %qrc=0,piece=0")
			// Not needed as method is procedureblock $$$GENERATE($c(9)_"new "_varlist)
			$$$GENERATE($c(9)_"for {")
			$$$GENERATE($c(9,9)_"&sql(fetch "_cursor_" into "_into_" )")
			$$$GENERATE($c(9,9)_"if SQLCODE<0 { set %qrc=SQLCODE set:$isobject($g(%sqlcontext)) %sqlcontext.SQLCode=SQLCODE,%sqlcontext.Message=$g(%msg) do Logerr^%SYS.SQLSRV(%qrc,"""",""SP"",.%msg) RETURN  }")		// error
			$$$GENERATE($c(9,9)_"if SQLCODE { set %qrc=100 set:$isobject($get(%sqlcontext)) %sqlcontext.SQLCode=100 RETURN  }")												// no [mode] data
			$$$GENERATE($c(9,9)_"RETURN:$zobjexport($lb("_varlist_"),60)")																// successful fetch
			$$$GENERATE($c(9)_"}")		// for loop
			$$$GENERATE($c(9)_"RETURN")
		}
		elseif ($$$comSubMemberKeyGet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,"Fetch",$$$cXXXXorigin)="%Library.ExtentSQLQuery") {
			$$$GENERATE($c(9)_"set %qrc=0,piece=0")
			$$$GENERATE($c(9)_"for {")
			$$$GENERATE($c(9,9)_"set rc=.."_$$$QN(%property_"Fetch")_"(.%qHandle,.row,.atend)")
			$$$GENERATE($c(9,9)_"if $$$ISERR(rc) { set %qrc=-400 set:$isobject($get(%sqlcontext)) %sqlcontext.SQLCode=-400,%sqlcontext.Message=$g(%msg) do ProcessError^%ourProcedure(rc,$get(%sqlcontext),.%qrc,.%msg),Logerr^%SYS.SQLSRV(%qrc,"""",""SP"",.%msg) RETURN  }")
			$$$GENERATE($c(9,9)_"if row="""" { set %qrc=100 set:$isobject($get(%sqlcontext)) %sqlcontext.SQLCode=100 RETURN  }")
			$$$GENERATE($c(9,9)_"RETURN:$zobjexport(row,60)")
			$$$GENERATE($c(9)_"}")
			$$$GENERATE($c(9)_"RETURN")
		}
		else {	// Fetch not originating in %Library.SQLQuery or %Library.ExtentSQLQuery, use old logic that does not include $zobjexport(...,60)
			$$$GENERATE($c(9)_"Kill array(qacn) Set %qrc=0")
			$$$GENERATE("SPInnerLoop"_$c(9)_"Set rc=.."_$$$QN(%property_"Fetch")_"(.%qHandle,.row,.atend)")
			$$$GENERATE($c(9)_"If $$$ISERR(rc) { Set %qrc=-400 Set:$isobject($get(%sqlcontext)) %sqlcontext.SQLCode=-400,%sqlcontext.Message=$g(%msg) Do ProcessError^%ourProcedure(rc,$get(%sqlcontext),.%qrc,.%msg) Do Logerr^%SYS.SQLSRV(%qrc,"""",""SP"",.%msg) Set piece=0 Quit }")
			$$$GENERATE($c(9)_"If row="""" Set %qrc=100,piece=0 Set:$isobject($get(%sqlcontext)) %sqlcontext.SQLCode=100 Quit $$$OK")
			$$$GENERATE($c(9)_"For piece=1:1:ColumnCount { Goto:$zobjexport($listget(row,piece),50) SPDone }")
			$$$GENERATE($c(9)_"Goto SPInnerLoop")
				#; As caller expects items to be in a local array fix up remaining entries
			$$$GENERATE("SPDone"_$c(9)_"Set piece=piece+1 For i=piece:1:ColumnCount { Set array(qacn,i)=$listget(row,i) }")
			$$$GENERATE($c(9)_"Quit")
		}
	}
	Quit $$$OK
}

}
