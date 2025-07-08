/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%DynamicSQLQuery</b> class is used for defining class queries based on runtime SQL statements.
Class %Library.DynamicSQLQuery Extends %Query [ Not ProcedureBlock, System = 2 ]
{

/// 	Close the query associated with the handle
ClassMethod Close(qHandle As %Binary) As %Status [ ServerOnly = 1 ]
{
 If ($isobject($get(qHandle(1)))'=1) Quit $$$ERROR($$$QueryNotPrepared)
 Quit qHandle(1).Close()
}

/// 	Execute is passed parameters for Query. Returns handle for subsequent operations.
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
	$$$GENERATE(" If ($isobject($get(qHandle(1)))'=1) RETURN $$$ERROR($$$QueryNotPrepared)")
	$$$GENERATE(" RETURN qHandle(1).Execute()")
	RETURN $$$OK
}

ClassMethod FetchRows(ByRef qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ ServerOnly = 1 ]
{
 If ($isobject($get(qHandle(1)))'=1) Quit $$$ERROR($$$QueryNotPrepared)
 Quit qHandle(1).FetchRows()
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
ClassMethod Fetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ ServerOnly = 1 ]
{
 If ($isobject($get(qHandle(1)))'=1) Quit $$$ERROR($$$QueryNotPrepared)
 Quit qHandle(1).Fetch()
}

ClassMethod GetInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef idinfo As %List, ByRef qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status [ ServerOnly = 1 ]
{
 New ptr,qhparms,sc,temp
 If ($isobject($get(qHandle(1)))'=1) Quit $$$ERROR($$$QueryNotPrepared)
 Set sc=qHandle(1).GetInfo() q:$$$ISERR(sc) sc
 Set qhparms=$lg(qHandle,4)
 If $ll(qhparms)=$ll(parminfo) Quit $$$OK
 Set temp="" For ptr = 1:1:$ll(qhparms) Set temp=temp_$lb($lg(parminfo,$li(qhparms,ptr)))
 Set parminfo=temp
 Quit $$$OK
}

ClassMethod GetODBCInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef qHandle As %Binary) As %Status [ ProcedureBlock = 0, ServerOnly = 1 ]
{
	If ($isobject($get(qHandle(1)))'=1) Quit $$$ERROR($$$QueryNotPrepared)
	Quit qHandle(1).GetODBCInfo()
}

ClassMethod Prepare(ByRef qHandle As %Binary, sqltext As %String = "", containid As %Integer = 0, selectmode As %String = "RUNTIME") As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
 s %code=0
 i %mode="method" QUIT $$$OK
 n formallist,qformal

 $$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSquery,%property,$$$cQUERYformalspecparsed)
 s formallist=""
 i qformal'="" s formallist=$$formallist^%occName(qformal,"") s formallist=$e(formallist,2,*-1)
 $$$GENERATE(" Quit $$Prepare^%SYS.DynamicQuery(.qHandle,.sqltext,containid,selectmode,"""_formallist_""")")
 Quit $$$OK
}

}
