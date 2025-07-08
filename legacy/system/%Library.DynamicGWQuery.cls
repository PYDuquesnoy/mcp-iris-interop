/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.DynamicGWQuery Extends %Query [ Not ProcedureBlock, System = 2 ]
{

ClassMethod Close(qHandle As %Binary) As %Status
{
 n connection,hstmt Set connection=$g(qHandle(1)),hstmt=$g(qHandle(2))
 Quit:connection=""!(hstmt="") $$$ERROR($$$QueryNotPrepared)
 Quit connection.DropStatement(hstmt)
}

ClassMethod Execute(ByRef qHandle As %Binary) As %Status [ CodeMode = generator ]
{
	set %code=0
		#; don't generate any code if it not for a query
	if %mode="method" { RETURN $$$OK }
	new %sc,formal,i,line,qformal,qline,query,requires
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
	$$$GENERATE(" n connection,fp,hstmt,qformal,parmmt,pptr Set connection=$g(qHandle(1)),hstmt=$g(qHandle(2)),parmmt=$g(qHandle(4))")
	$$$GENERATE(" RETURN:connection=""""||(hstmt="""") $$$ERROR($$$QueryNotPrepared)")
	$$$GENERATE(" i $l(parmmt)>0 Do  RETURN:$$$ISERR(sc) sc")
	$$$GENERATE(" . s sc=$$$OK,qformal="""_qformal_"""")
	$$$GENERATE(" . f pptr=1:1:$l(parmmt) s fp=""s fp=""_$s($e(parmmt,pptr):""+"",1:"""")_""$g(""_$lg($lg(qformal,pptr),1)_"")"" x fp s sc=connection.SetParameter(hstmt,$lb(fp),pptr) Quit:$$$ISERR(sc)")
	$$$GENERATE(" d .."_%property_"GetInfo(,,,.qHandle)")
	$$$GENERATE(" RETURN connection.Execute(hstmt)")
	RETURN $$$OK
}

ClassMethod Fetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	new connection,hstmt,rlist,sc,ii,val
	set connection=$g(qHandle(1)),hstmt=$g(qHandle(2)) 
	QUIT:connection=""||(hstmt="") $$$ERROR($$$QueryNotPrepared)
		//s sc=connection.FetchRows(hstmt,.rlist,1) i $$$ISERR(sc) QUIT sc
	set sc=connection.Fetch(hstmt)
	QUIT:$$$ISERR(sc) sc
	set Row=""
	if connection.sqlcode=100 { set AtEnd=1 QUIT $$$OK }
	for ii=1:1:qHandle("colcount") {
		if '($g(%SQLGateway("-uv"))&&$zbitget($zversion(0),1)) { set sc=connection.GetData(hstmt, ii, 1, .val) }
		else { set sc=connection.GetDataW(hstmt, ii, -8, .val) }
		RETURN:$$$ISERR(sc) sc
		set Row=Row_$lb(val)
	}
	set AtEnd=0 
	QUIT $$$OK
}

ClassMethod Prepare(ByRef qHandle As %Binary, sqltext As %String, containid As %Integer = 0, connection As %String) As %Status
{
 QUIT:$g(connection)="" $$$ERROR($$$GatewayConnection)
 n hstmt,mtype,plist,sc
 s mtype=""
 s sc=connection.AllocateStatement(.hstmt) QUIT:$$$ISERR(sc)!(hstmt="") $$$ERROR($$$GatewayAllocate)
  if '$g(%SQLGateway("-uv")) {
	  	s sc=connection.Prepare(hstmt,sqltext) QUIT:$$$ISERR(sc) sc
	  }
	  else{
	  	s sc=connection.PrepareW(hstmt,sqltext) QUIT:$$$ISERR(sc) sc
	  }
 s sc=connection.DescribeParameters(hstmt,.plist) QUIT:$$$ISERR(sc) sc
 i $ll(plist)>1 Do  Quit:$$$ISERR(sc) sc
 . n cdef,datatype,pdesc,pptr,precision,ptype,scale,type
 . s ptype="",precision="",datatype="",scale="",cdef=""
 . f pptr=2:1:$ll(plist) s pdesc=$li(plist,pptr) s type=$li(pdesc,1) s ptype=ptype_$lb(1),datatype=datatype_$lb(type),precision=precision_$lb($li(pdesc,2)),scale=scale_$lb($li(pdesc,3)),cdef=cdef_$lb($li(pdesc,2)) s mtype=mtype_$s(type>1&(type<9):1,1:0)
 . s sc=connection.BindParameters(hstmt,ptype,datatype,precision,scale,cdef) QUIT:$$$ISERR(sc)
 s qHandle(1)=connection,qHandle(2)=hstmt,qHandle(3)=containid,qHandle(4)=mtype
 Quit $$$OK
}

/// Returns information about the query. It is used by the various <b>ResultSet</b> objects.
ClassMethod GetInfo(ByRef colinfo As %List, ByRef parminfo As %List, ByRef idinfo As %List, ByRef qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status
{
 n colcount,column,connection,hstmt,i,info,odbctype,sc,type,uv,clist
 Set connection=$g(qHandle(1)),hstmt=$g(qHandle(2))
 Quit:connection=""!(hstmt="") $$$ERROR($$$QueryNotPrepared)

 s idinfo=$lb($g(qHandle(3)))

 s sc=connection.DescribeColumns(hstmt,.clist) Quit:$$$ISERR(sc) sc
 s colcount=$lg($lg(clist))
 s qHandle("colcount")=colcount
 s colinfo=""
 f i=1:1:colcount s info=$li(clist,i+1) Do
 . Set column=$li(info),odbctype=$li(info,2)+5
 . Set type=+$Piece("12|0|1|7|0|0|14|0|5|5|0|0|3|2|8|9|10","|",odbctype)
 . Set colinfo=colinfo_$Listbuild($Listbuild(column,type,column))

 s sc=connection.DescribeParameters(hstmt,.clist) Quit:$$$ISERR(sc) sc
 s colcount=$lg($lg(clist))
 s sc=connection.GetUV(.uv)
 s qHandle("uv")=uv&&$zbitget($zversion(0),1)
 s parminfo=""
 f i=1:1:colcount s info=$li(clist,i+1) Do
 . Set odbctype=$li(info,1)+5
 . Set type=+$Piece("12|0|1|7|0|0|14|0|5|5|0|0|3|2|8|9|10","|",odbctype)
 . Set parminfo=parminfo_$Listbuild($Listbuild(i,type))
	If extoption Set extinfo = ""
 QUIT $$$OK
}

}
