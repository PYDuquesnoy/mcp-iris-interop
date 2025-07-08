/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %systemInclude

/// This class is used to implement the system-provided "Extent" query that 
/// every persistent class contains. This class is not for application use.
Class %Library.ExtentSQLQuery Extends %SQLQuery [ Not ProcedureBlock, System = 2 ]
{

/// Close the query associated with the handle. This is also an opportunity to clean up.
ClassMethod Close(%qHandle As %Binary) As %Status [ CodeMode = generator, ProcedureBlock = 1, PublicList = SQLCODE, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a query
	if %mode="method" quit $$$OK
		#; If this isn't a persistent class, has no extent or if an MVINDEX class, quit...
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) || ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault)) quit $$$OK
	if '($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SQLENABLED",$$$cPARAMdefault)) set %code="$$$ERROR($$$MethodNotImplemented,""%ExtentSQLQuery:Close"")",%codemode=$$$cMETHCODEMODEEXPRESSION quit $$$OK
		#; Close cursor
	$$$GENERATE("	New SQLCODE Set SQLCODE=0")
	$$$GENERATE("	Do:$isobject($get(%qHandle)) %qHandle.%Destruct() Kill %qHandle")
	$$$GENERATE("	If SQLCODE { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%Message=$g(%msg) Set sc=$$$ERROR($$$SQLCode,SQLCODE,$get(%msg)) } Else { Set sc=$$$OK }")
	$$$GENERATE("	Quit sc")
	QUIT $$$OK
}

/// Execute is passed parameters for Query
/// 	Returns handle for subsequent operations
ClassMethod Execute(ByRef %qHandle As %Binary) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a query
	if %mode="method" quit $$$OK
		#; If this isn't a persistent class, has no extent or if an MVINDEX class, quit...
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) || ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault)) quit $$$OK
	if '($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SQLENABLED",$$$cPARAMdefault)) set %code="$$$ERROR($$$MethodNotImplemented,""%ExtentSQLQuery:Execute"")",%codemode=$$$cMETHCODEMODEEXPRESSION quit $$$OK
	set sc=$$$OK
		#; Reset the formal list to the query declaration:
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

	$$$comClassKeyGetLvar(schematable,%class,$$$cCLASSsqlqualifiednameQ)
	$$$comMemberKeyGetLvar(extentspec,%class,$$$cCLASSparameter,"EXTENTQUERYSPEC",$$$cPARAMdefault)
	set idcolumns=$get($$$EXTSQLrowidcolumnlist($$$pEXT,%class))
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)="" do
	. $$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy)
	. $$$comMemberKeyGetLvar(rowidprop,%class,$$$cCLASSstorage,sdef,$$$cSDEFsqlrowidproperty)
	. set rowidcolumn=$get($$$EXTPROPsqlcolumnname($$$pEXT,%class,rowidprop))
	. set idcolumns=$select(rowidcolumn'="":$listbuild(rowidcolumn),1:"")
	if extentspec="",idcolumns=""  set %code="$$$ERROR($$$MethodNotImplemented,""%ExtentSQLQuery:Execute"")",%codemode=$$$cMETHCODEMODEEXPRESSION quit $$$OK
	set select=$$quoter2^%apiSQL($list(idcolumns))
	for ptr=2:1:$listlength(idcolumns) set select=select_","_$$quoter2^%apiSQL($list(idcolumns,ptr))
	set extentlist=$$CSVtoList^%occLibrary(extentspec)
	for ptr=1:1:$listlength(extentlist) set column=$listget(extentlist,ptr) if column'="" do  quit:$$$ISERR(sc)
	. set columnname=$get($$$EXTPROPsqlcolumnname($$$pEXT,%class,column))
	. if columnname="" set sc=$$$ERROR($$$ExtentSpecAttributeInvalid,column) quit
	. set select=select_","_$$quoter2^%apiSQL(columnname)
	quit:$$$ISERR(sc) sc
		#; If no id columns are present then select starts with a comma - remove it
	if idcolumns="" set $extract(select,1)=""
	set sqltext =" SELECT "_select_" FROM %NOPARALLEL "_schematable
	$$$GENERATE("	#sqlcompile select="_%parameter("SELECTMODE"))
	$$$GENERATE("	Set sc=$$$OK")
		// define cursor
	 s cursor="Q"_$translate(%property,"%","x")
	$$$GENERATE("#EXECUTE s %msqlvar=""%qHandle""")
	$$$GENERATE("	&sql(DECLARE "_cursor_" CURSOR FOR")
	$$$comMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYsqlquery,sqltext)
	$$$GENERATE("		"_sqltext_")")
	#; Open cursor
	$$$GENERATE("	&sql(OPEN "_cursor_")")
	$$$GENERATE("	If SQLCODE { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%Message=$g(%msg) Set sc=$$$ERROR($$$QueryCannotInstantiate,""SQLCODE = ""_SQLCODE_"" %msg = ""_$g(%msg)) } Else { Set sc=$$$OK }")
	$$$GENERATE("	Quit sc")
	QUIT $$$OK
}

/// FetchRows returns the next FetchCount rows in the query
/// Updates handle for subsequent operations
/// Returns $list for row or  "" if no more rows
ClassMethod FetchRows(ByRef %qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ CodeMode = generator, PlaceAfter = Execute, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode(%property_"FetchRows")
	quit $$$OK
}

ClassMethod Fetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = generator, PlaceAfter = Execute, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
		// don't generate any code if it not for a query
	if %mode="method" quit $$$OK
		// If this isn't a persistent class, has no extent or if an MVINDEX class, quit...
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) || ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault)) quit $$$OK
	if '($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SQLENABLED",$$$cPARAMdefault)) set %code="$$$ERROR($$$MethodNotImplemented,""%ExtentSQLQuery:Fetch"")",%codemode=$$$cMETHCODEMODEEXPRESSION quit $$$OK
	$$$comMemberKeyGetLvar(extentspec,%class,$$$cCLASSparameter,"EXTENTQUERYSPEC",$$$cPARAMdefault)
	set idcolumns=$get($$$EXTSQLrowidcolumnlist($$$pEXT,%class))
	if ($$$PARAMdefault($$$gMGINFO,%class,"CONNECTION"))="" {
		$$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy)
		$$$comMemberKeyGetLvar(rowidprop,%class,$$$cCLASSstorage,sdef,$$$cSDEFsqlrowidproperty)
		set rowidcolumn=$get($$$EXTPROPsqlcolumnname($$$pEXT,%class,rowidprop))
		set idcolumns=$select(rowidcolumn'="":$listbuild(rowidcolumn),1:"")
	}
	set idcolumncnt=$listlength(idcolumns)
	if idcolumncnt {
		set into = ":c1", idexpr = "c1", degree = 1
		for ptr = 2:1:$listlength(idcolumns) {
			set column=$list(idcolumns,ptr)
			if column'="" { set into = into_",:c"_ptr, idexpr = idexpr_"_""||""_c"_ptr, degree = degree + 1 }
		}
		set rowexpr="$lb("_idexpr_")"
		if degree > 1 { set idinto = into } else { set idinto = ":array(%qacn,1)" }
		set idDegree = degree
	}
	else { set into = "", idinto = ":array(%qacn,1)", rowexpr = "", idexpr = "", degree = 0, idDegree = 1 }
	set extentlist=$$CSVtoList^%occLibrary(extentspec)
	for ptr=1:1:$listlength(extentlist) {
		set column=$listget(extentlist,ptr)
		if column'="" {
			set into=into_",:c"_(ptr+idcolumncnt),rowexpr=rowexpr_"_$lb(c"_(ptr+idcolumncnt)_")",degree=degree+1
		}
	}
		// if no idcolumns then each of the following start with ',' or '_' so get rid of it...
	if idcolumns="" set $extract(into,1)="",$extract(rowexpr,1)=""
		// Generate the code for IMMEDIATE mode.
	set cursor="Q"_$translate(%property,"%","x")
		// Generate the code for Fetch, FetchODBC, and FetchRows
		// 		generate fetch
	$$$GENERATE("	Set Row="""",AtEnd=0")
	$$$GENERATE("	&sql(FETCH "_cursor_" INTO "_into_")")
	$$$GENERATE("	If 'SQLCODE { Set Row="_rowexpr_" Set sc=$$$OK }")
	$$$GENERATE("	ElseIf SQLCODE=100 { Set AtEnd=1,sc=$$$OK Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%ROWCOUNT=$g(%ROWCOUNT) }")
	$$$GENERATE("	Else { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.Message=$g(%msg) Set AtEnd=1,sc=$$$ERROR($$$SQLCode,SQLCODE,$get(%msg)) }")
	$$$GENERATE($Char(9)_"QUIT sc")
		#; Generate FetchRows
	set fcode=0
	set fcode=fcode+1,fcode(fcode)="	Set RowSet="""",ReturnCount=0,AtEnd=0"
	set fcode=fcode+1,fcode(fcode)="	For {"
	set fcode=fcode+1,fcode(fcode)="		&sql(FETCH "_cursor_" INTO "_into_")"
	set fcode=fcode+1,fcode(fcode)="		If 'SQLCODE { Set RowSet=RowSet_"_rowexpr_",ReturnCount=ReturnCount+1 Quit:(ReturnCount=FetchCount)||(($l(RowSet)+($l(RowSet)\ReturnCount))>30000) } Else { Set AtEnd=1 Quit }"
	set fcode=fcode+1,fcode(fcode)="	}"
	set fcode=fcode+1,fcode(fcode)="	If 'SQLCODE { Set sc=$$$OK } ElseIf SQLCODE=100 { Set sc=$$$OK Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%ROWCOUNT=$g(%ROWCOUNT) } Else { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.Message=$g(%msg) Set sc=$$$ERROR($$$SQLCode,SQLCODE,$get(%msg)) }"
	set fcode=fcode+1,fcode(fcode)="	Quit sc"
	merge $$$tEXTcode(%property_"FetchRows")=fcode
	QUIT $$$OK
}

/// GetInfo() returns information about columns in the query result,
///   parameters in the query formal list, and whether or not the result
///   contains enough information to form an ID value.
///   This information is return in three pass-by-reference parmeters:
///   colinfo - contains one list element for each column declared
///             in ROWSPEC. The form is name:exttype:caption
///   parminfo - contains one list element for each formal paramter
///             of the query in the form name:exttype
///   idinfo -  Integer indicating the posistion of the ID value, zero if
///             not included.
///   The information is not constructed until the first invocation of
///   GetInfo(). Once the information is compiled the first time, it is
///   stored in the ^oddMAC global and is retrieved on subsequent calls
///   to GetInfo()
ClassMethod GetInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef idinfo As %List, ByRef %qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 #; don't generate any code if it's not for a query
 i %mode="method" QUIT $$$OK
 #; If this isn't a persistent class, has no extent or if an MVINDEX class, quit...
 i ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) || ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault)) QUIT $$$OK
	If '($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SQLENABLED",$$$cPARAMdefault)) s %code="$$$ERROR($$$MethodNotImplemented,""%ExtentSQLQuery:GetInfo"")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
 $$$comMemberKeyGetLvar(extentspec,%class,$$$cCLASSparameter,"EXTENTQUERYSPEC",$$$cPARAMdefault)
 set extentlist=$$CSVtoList^%occLibrary(extentspec)
 $$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy)
 $$$comMemberKeyGetLvar(rowid,%class,$$$cCLASSstorage,sdef,$$$cSDEFsqlrowidproperty)
 i extentspec="",rowid=""  s %code="$$$ERROR($$$MethodNotImplemented,""%ExtentSQLQuery:GetInfo"")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
 s sc=$$$OK,flag=1
 #; parmvars are the formal parameters of the query...
 s executename=$$$normalize("Execute")
 d ProcessSubMethodFormalspec^%occName(%class,$$$cCLASSquery,%property,executename,,.parmvars)
 i $l(parmvars,",")'>1 $$$GENERATE(" s parminfo=""""")
 #; Process the MAC nodes
 #; Generate code to check to see if the GetInfo data has already been compiled...
 $$$GENERATE("	$$$comMemberKeyGetLvar(clientinfo,$classname(),$$$cCLASSquery,"""_%property_""",$$$cQUERYclientinfo)")
	$$$GENERATE("	Set:extoption extinfo=$$$comMemberKeyGet($classname(),$$$cCLASSquery,"""_%property_""",$$$cQUERYextendedinfo)")
 #; ...if it has, then split it into the components and return...
 $$$GENERATE("	If clientinfo'="""" Set colinfo=$listget(clientinfo,1),parminfo=$listget(clientinfo,2),idinfo=$listget(clientinfo,3) Quit $$$OK")
 #; ...still here? Okay, compile the GetInfo stuff...
 $$$GENERATE("	Set colinfo="""",parminfo="""",idinfo=$listbuild(0)")
 #; Generate the colinfo stuff...
 s colcaptions="",colcount=0,colnames="",coltypes="",passbyref=""
 #; Automatically include the ROWID in the EXTENTQUERYSPEC...
 s extentlist=$listbuild(rowid)_extentlist
	set rowidType = $g($$$EXTPROPtype($$$pEXT,%class,$$$normalize(rowid))) s:rowidType="" rowidType=$$DefaultDataTypeName^%occName()
		#; pull out the column info for each column in EXTENTQUERYSPEC...
 set extendedinfo = "", rowspec = $Select(rowid="%%ID":"ID",rowid="%%ROWID":"ID",1:rowid) _ ":" _ rowidType
 f i=1:1:$listlength(extentlist) s ele=$listget(extentlist,i) i ele'="" DO  q:$$$ISERR(sc)
	. s attrib=$p(ele,":",1)
	. s colcount=colcount+1
	. s caption=$p(ele,":",3)
	. s attribname=$s(attrib="%%ID":"ID",attrib="%%ROWID":"ID",1:attrib)
	. If $Data($$$EXTPROPtype($$$pEXT,%class,$$$normalize(attrib))) { Set extendedinfo=extendedinfo_$ListBuild($ListBuild(%class,$$$normalize(attrib))) } Else { Set extendedinfo=extendedinfo_$ListBuild($ListBuild("","")) }
	. s type=$g($$$EXTPROPtype($$$pEXT,%class,$$$normalize(attrib))) s:type="" type=$$DefaultDataTypeName^%occName()
		#; Construct the comma lists for passing to %apiOLE...
	. s colnames=colnames_$lb(attribname),coltypes=coltypes_type_",",passbyref=passbyref_"0"
		#; Col caption will default to the colname:
	. s colcaptions=colcaptions_$lb($s(caption'="":caption,1:attribname))
	. set:i>1 rowspec = rowspec _ "," _ attribname _ $Select(caption'="":"::"_caption,1:"")
 QUIT:$$$ISERR(sc) sc
	$$$comSubMemberSet(%class,$$$cCLASSquery,%property,$$$cQUERYparameter,"ROWSPEC",rowspec)
 s $e(coltypes,$l(coltypes))=""
 $$$comMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYcolnames,colnames)
 $$$comMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYcolcaptions,colcaptions)
	$$$comMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYextendedinfo,$ListBuild(1,extendedinfo))
 #; Get the external types and passbyref flags...
 $$$GENERATE("	Set sc=$$externaltype^%apiOLE("""_coltypes_""",.exttypes,"""_passbyref_""")")
 $$$GENERATE("	Quit:$$$ISERR(sc) sc")
 $$$GENERATE("	$$$comMemberKeyGetLvar(names,$classname(),$$$cCLASSquery,"""_%property_""",$$$cQUERYcolnames)")
 $$$GENERATE("	$$$comMemberKeyGetLvar(captions,$classname(),$$$cCLASSquery,"""_%property_""",$$$cQUERYcolcaptions)")
 #; ...and package up a colinfo node for each column as $lb(name,exttype,caption)
 $$$GENERATE("	For i=1:1:"_colcount_" Set colinfo=colinfo_$listbuild($listbuild($listget(names,i),$piece(exttypes,"","",i),$listget(captions,i)))")
 #; Now generate the parminfo
 i $l(parmvars,",")>1 DO
 . $$$comSubMemberKeyGetLvar(parmtypes,%class,$$$cCLASSquery,%property,$$$cQUERYmethod,executename,$$$cMETHuseractualtype)
 . d ProcessSubMethodFormalspec^%occName(%class,$$$cCLASSproperty,%property,executename,.passbyref)
 . s parmcount=$l(parmvars,",")
 #; strip off the %qHandle parameter
 . s parmtypes=$p(parmtypes,",",2,parmcount),passbyref=$e(passbyref,2,$l(passbyref))
 . s parmnames=""
 . f i=2:1:$l(parmvars,",") s parmnames=parmnames_$lb($p(parmvars,",",i))
 . $$$comMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYparmnames,parmnames)
 . $$$GENERATE("	Set sc=$$externaltype^%apiOLE("""_parmtypes_""",.exttypes,"""_passbyref_""")")
 . $$$GENERATE("	If $$$ISERR(sc) { Set:$isobject($g(%sqlcontext)) %sqlcontext.SQLCode=-400,%sqlcontext.Message=""Error computing external types"" Quit sc }")
 . $$$GENERATE("	$$$comMemberKeyGetLvar(names,$classname(),$$$cCLASSquery,"""_%property_""",$$$cQUERYparmnames)")
 . $$$GENERATE("	For i=1:1:"_$ll(parmnames)_" Set parminfo=parminfo_$listbuild($listbuild($listget(names,i),$piece(exttypes,"","",i)))")
 #; Set the value of idinfo to CONTAINID...
 $$$GENERATE("	Set idinfo=$listbuild("_+%parameter("CONTAINID")_",$classname())")
 #; ...and save the compiled info...
 $$$GENERATE("	$$$comMemberKeySet($classname(),$$$cCLASSquery,"""_%property_""",$$$cQUERYclientinfo,$listbuild(colinfo,parminfo,idinfo))")
 $$$GENERATE("	Quit $$$OK")
 QUIT sc
}

/// Func is a method that is used to invoke the query as a function, returning an instance of %SQL.StatementResult.
ClassMethod Func() As %SQL.StatementResult [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
		#; If this isn't a persistent class, has no extent or if an MVINDEX class, quit...
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) || ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault)) QUIT $$$OK
	quit $$GenerateFunc^%occQuery()
}

ClassMethod GetODBCInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef qHandle As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		#; If this isn't a persistent class, has no extent or if an MVINDEX class, quit...
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) || ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault)) QUIT $$$OK
	quit $$GenerateGetODBCInfo^%occQuery()
}

}
