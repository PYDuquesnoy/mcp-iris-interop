/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used to implement the 'complete row' SQL query that 
/// can be used to return the entire persistent state of an object.
/// This class is not for application use.
Class %Library.RowSQLQuery Extends %SQLQuery [ Not ProcedureBlock, System = 2 ]
{

ClassMethod Close(%qHandle As %Binary) As %Status [ CodeMode = generator, ProcedureBlock = 1, PublicList = SQLCODE ]
{
 s %code=0
 #; don't generate any code if it not for a query
 i %mode="method" QUIT $$$OK
 i $$$comClassKeyGet(%class,$$$cCLASSclasstype)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
 #; Close cursor
 $$$GENERATE("	New SQLCODE Set SQLCODE=0")
 $$$GENERATE("	Do:$isobject($get(%qHandle)) %qHandle.%Destruct() Kill %qHandle")
 $$$GENERATE("	Quit $select('SQLCODE:$$$OK,1:$$$ERROR($$$SQLError,SQLCODE,$get(%msg)))")
 QUIT $$$OK
}

ClassMethod Execute(ByRef %qHandle As %Binary, id As %String) As %Status [ CodeMode = generator, ProcedureBlock = 1 ]
{
 s %code=0
 #; don't generate any code if it not for a query
 i %mode="method" QUIT $$$OK
 #; If this isn't a persistent class, quit...
 i $$$comClassKeyGet(%class,$$$cCLASSclasstype)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	If '$Data(^oddEXTR(%class)) s %code="$$$ERROR($$$MethodNotImplemented,""%RowSQLQuery:Execute"")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
 s sc=$$$OK
 #; Reset the formal list to the query declaration:
 $$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed)
 $$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSquery,%property,$$$cQUERYformalspecparsed)
 $$$comSubMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed,formal_qformal)
 s sc=$$SetOneQueryMeth^%occQuery(%class,%property,%method) q:$$$ISERR(sc) sc

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

 $$$comClassKeyGetLvar(tablename,%class,$$$cCLASSsqlqualifiednameQ)

 s idcolumns=$g($$$EXTSQLrowidcolumnlist($$$pEXT,%class))
 i $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)="" d
 . $$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy)
 . $$$comMemberKeyGetLvar(rowidprop,%class,$$$cCLASSstorage,sdef,$$$cSDEFsqlrowidproperty)
 . s rowidcolumn=$g($$$EXTPROPsqlcolumnname($$$pEXT,%class,rowidprop))
 . s idcolumns=$s(rowidcolumn'="":$lb(rowidcolumn),1:"")
 i idcolumns=""  s %code="$$$ERROR($$$MethodNotImplemented,""%RowSQLQuery:Execute"")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK

 Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,""), select = 1, select(1) = "", degree = 0
 While prop '= "" {
	Set transient = '($$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPstorable))
		#; We aren't supporting collections with this query yet - issues with subnode storage, etc.
	Set collection = $$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
	If (collection = "" ) && ('transient || ($$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPsqlcomputed))) {
		#; Set relationship = $$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)
		#; Set cardinality = $$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPcardinality)
		$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
		$$$comMemberKeyGetLvar(sqlname,%class,$$$cCLASSproperty,prop,$$$cPROPsqlfieldname)
		Set classtype = $$$getClassType(type)
			#; Now check to see if any stream locations need to be set up. NOTE: If any stream properties are generated during extent
			#; compiliation then the corresponding STREAM entry will have to be set up.
		#; Set classinoid = +$$$comMemberArrayGet(%class,$$$cCLASSproperty,prop,$$$cPROPparameter,"CLASSNAME")
		Set columnname = $$quoter2^%apiSQL(sqlname)
		If classtype = $$$cCLASSCLASSTYPEPERSISTENT set persistent(prop)=""
		If ($Length(select(select)) + $Length(columnname)) > 255 { Set select = select + 1, select(select) = "" }
		Set select(select) = select(select) _ columnname _ ",", degree = degree + 1
	}
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
 }
 If select {
	Set $Extract(select(select),$Length(select(select))) = ""
	Set sqlquery = " SELECT " _ select(1)
	For line = 2:1:select { Set sqlquery = sqlquery _ $$$NL _ " " _ select(line) }
	Set sqlquery = sqlquery _ $$$NL _ " FROM " _ tablename _ " WHERE %ID = :id"
		#; If no id columns are present then select starts with a comma - remove it
	i idcolumns="" s $e(select,1)=""
	$$$GENERATE("	#sqlcompile select="_%parameter("SELECTMODE"))
	$$$GENERATE("	Set sc=$$$OK")
		#; define cursor
	s cursor="Q"_$translate(%property,"%","x")
	$$$GENERATE("#EXECUTE s %msqlvar=""%qHandle""")
	$$$GENERATE("	&sql(DECLARE "_cursor_" CURSOR FOR")
	$$$GENERATE("		" _ sqlquery_")")
	$$$comMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYsqlquery,sqlquery)
		#; Open cursor
	$$$GENERATE("	&sql(OPEN "_cursor_")")
	$$$GENERATE("	If SQLCODE Set sc=$$$ERROR($$$QueryCannotInstantiate,""SQLCODE = ""_SQLCODE_"" %msg = ""_$g(%msg))")
	$$$GENERATE("	Quit sc")
 }
 Else { s %code="$$$ERROR($$$MethodNotImplemented,""%RowSQLQuery:Execute"")",%codemode=$$$cMETHCODEMODEEXPRESSION }


 #; Generate the various fetch methods...
 i 'degree s fcode=1,fcode(1)=" QUIT $$$ERROR($$$QueryNothingSelected,"""_%property_""")" m $$$tEXTcode(%property_"Fetch")=fcode QUIT $$$OK
 #; generate fetch
 s into=":x1",rowexpr="$lb(x1)"
 f i=2:1:degree s into=into_",:x"_i,rowexpr=rowexpr_"_$lb(x"_i_")"
 s fcode=0
 s fcode=fcode+1,fcode(fcode)="	Set Row="""",AtEnd=0"
 s fcode=fcode+1,fcode(fcode)="	&sql(FETCH "_cursor_" INTO "_into_")"
 s fcode=fcode+1,fcode(fcode)="	If 'SQLCODE { Set Row="_rowexpr_" } Else { Set AtEnd=1 }"
 s fcode=fcode+1,fcode(fcode)="	Quit $select('SQLCODE:$$$OK,SQLCODE=100:$$$OK,1:$$$ERROR($$$SQLError,SQLCODE,$get(%msg)))"
 m $$$tEXTcode(%property_"Fetch")=fcode
 #; Generate FetchRows
 k fcode s fcode=0
 s fcode=fcode+1,fcode(fcode)="	Set RowSet="""",ReturnCount=0,AtEnd=0"
 s fcode=fcode+1,fcode(fcode)="	For {"
 s fcode=fcode+1,fcode(fcode)="		&sql(FETCH "_cursor_" INTO "_into_")"
 s fcode=fcode+1,fcode(fcode)="		If 'SQLCODE { Set RowSet=RowSet_"_rowexpr_",ReturnCount=ReturnCount+1 Quit:(ReturnCount=FetchCount)||(($l(RowSet)+($l(RowSet)\ReturnCount))>30000) } Else { Set AtEnd=1 Quit }"
 s fcode=fcode+1,fcode(fcode)="	}"
 s fcode=fcode+1,fcode(fcode)="	Quit $select('SQLCODE:$$$OK,SQLCODE=100:$$$OK,1:$$$ERROR($$$SQLError,SQLCODE,$get(%msg)))"
 m $$$tEXTcode(%property_"FetchRows")=fcode
 QUIT $$$OK
}

ClassMethod Fetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = generator, GenerateAfter = Execute, PlaceAfter = Execute, ProcedureBlock = 1, PublicList = mtc ]
{
 s %code=0
 m %code=$$$tEXTcode(%property_"Fetch")
 QUIT $$$OK
}

}
