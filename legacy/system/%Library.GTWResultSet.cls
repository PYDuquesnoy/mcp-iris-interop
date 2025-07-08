/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.GTWResultSet Extends (%Library.IResultSet, %IProcedureContext) [ Inheritance = right, System = 4 ]
{

Property gwc As %SQLGatewayConnection;

Property hstmt As %String;

Property firsttime As %Integer;

Property columns [ MultiDimensional ];

Property Data [ MultiDimensional ];

Property colindex [ MultiDimensional ];

Property bRClose As %Boolean;

Method CreateStaticRS(ByRef sqcon As %Library.ObjectHandle) As %Library.Status
{
	while(..NextResult()) {
			if (..columns>0) {s rs=##class(%ResultSet.Static).%New($this)
 			d sqcon.AddResultSet(rs)
		}
	} 
	s ..bRClose=1  //statement should be closed explicitly
	

	quit $$$OK
}

Method NextResult() As %Library.RegisteredObject
{
	if '..firsttime {
		s ..firsttime=1
		quit $this
	}
	
	s rc=..gwc.MoreResults(..hstmt)
	s ..%SQLCODE=..gwc.sqlcode
	if ..%SQLCODE=0 
	{
		d ..InitMetadata()
		//d ..%Next()
		quit $this 
	}
	Quit $$$NULLOREF
}

Method %Get(colname As %String = "") As %Library.String
{
	if colname="" quit ""
	s ii=$g(..colindex(colname))
	if 'ii quit ""
	quit ..%GetData(ii)
}

Method %CloseCursor() As %Status
{
	s sc=$$$OK
	if '..bRClose s sc=..gwc.DropStatement(..hstmt)
	quit sc
}

Method %Print() As %Status
{
	 w !
	 for ii=1:1:..columns w $g(..Data(ii))," "
	quit $$$OK
}

Method %Next(ByRef sc As %Library.Status) As %Library.Integer
{
	s sc=..gwc.Fetch(..hstmt)
	s ..%SQLCODE=..gwc.sqlcode
	if ..%SQLCODE quit 0
	for ii=1:1:..columns {
		if ((..columns(ii,"SqlType")=-1) || (..columns(ii,"SqlType")=-1)){
			s val=$$createTempStream^%apiGTW(..hstmt,ii,"",$s(..columns(ii,"SqlType")=-1:0,1:1),%SQLGateway("-uv"))
		}

		if %SQLGateway("-uv")  {
			s sc=..gwc.GetDataW(..hstmt, ii, -8, .val)
		}
		else  {
		s sc=..gwc.GetData(..hstmt, ii, 1, .val)
	}
	
	//s ..%SQLCODE=rs.sqlcode
	k ..Data(ii)
	if sc {
		set ..Data(ii)=val
	}

	}
	
	quit 1
}

Method %GetData(colnbr As %Integer) As %Library.String
{
	
	quit $g(..Data(colnbr))
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// it expects $lb(dllHandle,ConnectionHandle,StatementHandle)
Method InitMetadata() As %Status [ Private, ProcedureBlock = 1 ]
{
	s sc = ..gwc.DescribeColumns(..hstmt, .clist)
	if 'sc quit sc
	k ..columns,..colindex
	s ..columns=$ll(clist)-1
	Set metadata = $lb(..columns)

	for ii=2:1:$ll(clist) {
		s ..colindex($li($li(clist,ii),1))=ii-1
		s ..columns(ii-1,"Name")=$li($li(clist,ii),1)
		s ..columns(ii-1,"SqlType")=$li($li(clist,ii),2)
		s ..columns(ii-1,"Precision")=$li($li(clist,ii),3)
		s ..columns(ii-1,"Scale")=$li($li(clist,ii),4)
		s ..columns(ii-1,"Nullable")=$li($li(clist,ii),5)
		s ..columns(ii-1,"Datatype")=$li($li(clist,ii),6)
		s ..columns(ii-1,"DisplaySize")=$li($li(clist,ii),7)
		s ..columns(ii-1,"IsMoney")=$li($li(clist,ii),8)
		s bstr=$Char(0,0,0,0,0,0,0,0,0,0,0)
		Set metadata = metadata _ $lb(..columns(ii-1,"Name"),..columns(ii-1,"SqlType"),..columns(ii-1,"Precision"),..columns(ii-1,"Scale"),..columns(ii-1,"Nullable"),..columns(ii-1,"Name"),"","","",bstr)
	}
	s ..%Metadata=metadata
	s ..%NextColumn=0
	quit $$$OK
}

/// it expects $lb(dllHandle,ConnectionHandle,StatementHandle)
Method %OnNew(conninfo As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	s ..gwc=##class(%SQLGatewayConnection).%New()
	s ..gwc.DLLHandle=$li(conninfo,1)
	s ..gwc.ConnectionHandle=$li(conninfo,2)
	s ..hstmt=$li(conninfo,3)
	d ..InitMetadata()
	//if ..columns>0 d ..%Next()
	quit $$$OK
}

Method %SendODBC() As %Integer
{
	if ..%SQLCODE quit 100
	s ..%NextColumn=..%NextColumn+1
	if ..%NextColumn>..columns {
			s ..%NextColumn=1
			if '..%Next() s ..%SQLCODE=100  
	}
	//if ..%NextColumn=0 {
	//		s ..%NextColumn=1
	//		if '..%Next()  s ..%SQLCODE=100 quit ..%SQLCODE
	//	}
	while (('..%SQLCODE) && ('$zobjexport(..Data(..%NextColumn),7))) {
		s ..%NextColumn=..%NextColumn+1
		
		if ..%NextColumn>..columns {
			s ..%NextColumn=1
			if '..%Next() s ..%SQLCODE=100 break 
		}
		
		
		
	}
	quit ..%SQLCODE
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	d ..%CloseCursor()
	Quit $$$OK
}

}
