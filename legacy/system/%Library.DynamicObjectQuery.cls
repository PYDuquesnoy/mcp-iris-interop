/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%DynamicObjectQuery</b> class is used for defining class queries based on runtime Object/Bitmap statements.
Class %Library.DynamicObjectQuery Extends %DynamicSQLQuery [ Not ProcedureBlock, System = 2 ]
{

ClassMethod Execute(ByRef qHandle As %Binary) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		 #; don't generate any code if it not for a query
	if %mode="method" { RETURN $$$OK }

	new %sc,formal,i,line,qformal,qline,query

		#; Reset the formal list to the query declaration:
	$$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed)
	$$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSquery,%property,$$$cQUERYformalspecparsed)
	$$$comSubMemberKeySet(%class,$$$cCLASSquery,%property,$$$cQUERYmethod,%method,$$$cMETHformalspecparsed,formal_qformal)
	set %sc=$$SetOneQueryMeth^%occQuery(%class,%property,%method) RETURN:$$$ISERR(%sc) %sc

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
	$$$GENERATE(" new %qref,id,rtn Set %qref=$lg(qHandle,1),rtn=$lg(qHandle,2)") set id=""
	$$$GENERATE(" RETURN:%qref=""""||(rtn="""") $$$ERROR($$$QueryNotPrepared)")
	$$$GENERATE(" RETURN $$Execute^@rtn")
	RETURN $$$OK
}

ClassMethod FetchRows(ByRef qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ ServerOnly = 1 ]
{
 n %qref,id,rtn Set %qref=$lg(qHandle,1),rtn=$lg(qHandle,2),id=$lg(qHandle,3)
 Quit:%qref=""!(rtn="") $$$ERROR($$$QueryNotPrepared)
 QUIT $$FetchRows^@rtn
}

ClassMethod Fetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ ServerOnly = 1 ]
{
 n %qref,id,rtn Set %qref=$lg(qHandle,1),rtn=$lg(qHandle,2),id=$lg(qHandle,3)
 Quit:%qref=""!(rtn="") $$$ERROR($$$QueryNotPrepared)
 QUIT $$Fetch^@rtn
}

ClassMethod Prepare(ByRef qHandle As %Binary, query As %String, containid As %Integer = 0, selectmode As %String = "LOGICAL") As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
 s %code=0
 i %mode="method" QUIT $$$OK
 n formallist,qformal,parmarray,ptr,var
#if 0 ; DLP827+
 s qformal=$$$QUERYformalspec($$$gMGINFO,%class,%property)
 i $e(qformal)="(",$e(qformal,$l(qformal))=")"
 i  s qformal=$e(qformal,2,$l(qformal)-1)
#else ; DLP827=
 $$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSquery,%property,$$$cQUERYformalspecparsed)
#endif ; DLP827-
 s formallist=""
 i qformal'="" s formallist=$$formallist^%occName(qformal,"") s formallist=$e(formallist,2,$l(formallist)-1)
 $$$GENERATE(" Quit 0  // DPV2528= %ourQueryBM has not existed for some time!  $$Prepare^%ourQueryBM(.qHandle,query,containid,selectmode,"""_formallist_""")")
 Quit $$$OK
}

}
