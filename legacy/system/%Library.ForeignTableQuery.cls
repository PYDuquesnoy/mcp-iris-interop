/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.ForeignTableQuery Extends %Query [ Deprecated, System = 3 ]
{

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
	$$$GENERATE($Char(9)_"}")
	$$$GENERATE($Char(9)_"catch tException { if '$Isobject($Get(qHandle)) { set qHandle = ##class(%SQL.StatementResult).%New() } set qHandle.%SQLCODE=tException.AsSQLCODE(),qHandle.%Message=tException.AsSQLMessage() }")
	// qHandle will be the FDW, which are now children of %SQL.StatementResult
	// Not how this is typically done, but we use this to subvert the query Fetch() and save on time calling
	// the result set %Next -> TVF Fetch -> FDW Fetch when we can just put the %Next() right into the FDW and call it direct
	$$$GENERATE($Char(9)_"Quit qHandle")

	QUIT $$$OK
}

/// Close the connection assoicated with the foreign data wrapper object <var>%qHandle</var>
ClassMethod Close(%qHandle As %Binary) As %Status [ PublicList = SQLCODE, ServerOnly = 1 ]
{
	try {
		set tSC = %qHandle.Close()
	} catch ex {
		set tSC = ex.AsStatus()
	}
	set:'$$$ISOK(tSC) tSC = $$$ERROR($$$SQLCode,-232,"Foreign Tables - "_$SYSTEM.Status.GetErrorText(tSC))
	k %qHandle
	quit tSC
}

/// <p> <b>Execute</b> takes optional <var>whereClause</var> and <var>parameters</var> parameters
/// for predicate pushdown. This method creates an object of the relevant foreign data wrapper class
/// (%SQL.FDW.*) and returns it by reference in %qHandle. 
ClassMethod Execute(ByRef %qHandle As %Binary, query As %String = "", parameters As %List = "") As %Status [ CodeMode = objectgenerator, PlaceAfter = GetQuery, ServerOnly = 1 ]
{
	// don't generate any code if it not for a query
	if %mode="method" { RETURN $$$OK }
	// %mode is "propertymethod" for a valid query. We don't have any way currently to detect a misuse of a query class
	if '$$$comMemberDefined(%class.Name,$$$cCLASSquery,%property) { RETURN $$$OK }
	set sc=$$SetOneQueryMeth^%occQuery(%class.Name,%property,%compiledmethod.Name) RETURN:$$$ISERR(sc) sc

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
	if origin'="" {
		set package=$$$ClassPackageName(origin)
		do %code.WriteLine("#import "_package)
	}	
	
	do %code.WriteLine("	try {")
	do %code.WriteLine("		set %qHandle = $classmethod($parameter(..#SERVER,""FDWNAME""),""%New"")")
	do %code.WriteLine("		set tSC = %qHandle.Prepare(..#SERVER,$CLASSNAME(),query)")
	do %code.WriteLine("		quit:'$$$ISOK(tSC)")
	do %code.WriteLine("		set tSC = %qHandle.Execute(parameters)")
	do %code.WriteLine("		quit:'$$$ISOK(tSC)")
	do %code.WriteLine("	} catch ex {")
	do %code.WriteLine("		set tSC = ex.AsStatus()")
	do %code.WriteLine("	}")
	do %code.WriteLine("	set:'$$$ISOK(tSC) tSC = $$$ERROR($$$SQLCode,-230,""Foreign Tables - ""_$SYSTEM.Status.GetErrorText(tSC))")
	do %code.WriteLine("	RETURN tSC")
	
	RETURN $$$OK
}

/// Fetch the next row of data from the external source.
/// <p><var>qHandle</var> is a foreign data wrapper object.
/// <p>The <b>Fetch</b> method sets <var>Row</var> to be a $List of 
/// values corresponding to the columns of the query by passing the row by reference to
/// the Fetch method of the foreign data wrapper. If we are past the end of the data
/// and no row is returned, <var>Row</var> should be set to null string ("").
/// If the non-empty row being returned is the last one, <var>AtEnd</var> is 
/// set to 1, indicating that an additional call to <b>Fetch</b> may be avoided.
ClassMethod Fetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = objectgenerator, PlaceAfter = Execute, ServerOnly = 1 ]
{
	#; don't generate any code if it not for a query
	if %mode="method" QUIT $$$OK
	
	d %code.WriteLine("	set tSC = %qHandle.Fetch(.Row,.AtEnd)")
	d %code.WriteLine("	set:'$$$ISOK(tSC) tSC = $$$ERROR($$$SQLCode,-231,""Foreign Tables - ""_$SYSTEM.Status.GetErrorText(tSC))") // reset status to FT error
	d %code.WriteLine("	RETURN tSC")
}

}
