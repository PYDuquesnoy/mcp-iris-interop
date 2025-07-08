/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.JGWResultSet Extends (%Library.IResultSet, %IProcedureContext) [ Inheritance = right, System = 4 ]
{

Property gwc As %SQLGatewayConnection;

Property hstmt As %String;

Property firsttime As %Integer;

Property sentODBC As %Integer;

Property Data [ MultiDimensional ];

Property colindex [ MultiDimensional ];

Property columns [ MultiDimensional ];

Method NextResult() As %Library.RegisteredObject
{
	s ..%ROWCOUNT=0
	if '..firsttime {
		s ..firsttime=1
		quit $this
	}
	while(1) {
		s rc=1,rcr=""
		s rc=%JDBCGateway.getMoreResults(..hstmt)

		s updCount = %JDBCGateway.getUpdateCount(..hstmt)
		if (updCount = -1) {
			s rcr=%JDBCGateway.getResultSet(..hstmt)
			quit
		}
		
	}
	
	s ..%SQLCODE=0
	if rc =0 s ..%SQLCODE=100
	if rc =-1 s ..%SQLCODE=-400
	
	if ..%SQLCODE=0 
	{
		//s rc=%JDBCGateway.getResultSet(..hstmt)
		if rcr=-1 Quit $$$NULLOREF
		d ..InitMetadata()
		s ..sentODBC=0
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
	if '$d(%JDBCGateway) quit $$$OK
	s err=%JDBCGateway.removeStatement(..hstmt)
	quit $$$OK
}

Method %Print() As %Status
{
	 w !
	 for ii=1:1:..columns w $g(..Data(ii))," "
	quit $$$OK
}

Method CreateStaticRS(ByRef sqcon As %Library.ObjectHandle) As %Library.Status
{
	while(..NextResult()) {
		s rs=##class(%ResultSet.Static).%New($this)
 		d sqcon.AddResultSet(rs)
	} 

	quit $$$OK
}

Method %Next(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer
{
	s rc=%JDBCGateway.next(..hstmt)
	s ..%SQLCODE=0
	if 'rc {s ..%SQLCODE=100}
	if %JDBCGateway.wasError() s ..%SQLCODE=-400
	if ..%SQLCODE quit 0
	s ..%ROWCOUNT=..%ROWCOUNT+1
	for ii=1:1:..columns {
		if ((..columns(ii,"SqlType")=-1) || (..columns(ii,"SqlType")=-1)){
			s val=$$createTempStreamJ^%apiGTW(..hstmt,ii,"",$s(..columns(ii,"SqlType")=-1:0,1:1),$zbitget($zversion(0),1))
		}
		else {s val=%JDBCGateway.getString(..hstmt,ii)}
		s sc='(%JDBCGateway.wasError())
			k ..Data(ii)
		if sc {
			set ..Data(ii)=val
		}

	}
	
	
	//s ..%SQLCODE=rs.sqlcode

	
	
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
	s ..columns = %JDBCGateway.columnCount(..hstmt)
	if ..columns=-1 quit $$$ERROR($$$GatewayFailed," columnCount")
	k ..colindex
	Set metadata = $lb(..columns)

	for ii=1:1:..columns {
		s ..columns(ii,"Name")=%JDBCGateway.getColumnName(..hstmt,ii)
		s ..colindex( ..columns(ii,"Name"))=ii
		s ..columns(ii,"SqlType")=%JDBCGateway.getColumnType(..hstmt,ii)
		s ..columns(ii,"Precision")=%JDBCGateway.getPrecision(..hstmt,ii)
		s ..columns(ii,"Scale")=%JDBCGateway.getScale(..hstmt,ii)
		s ..columns(ii,"Nullable")=%JDBCGateway.isNullable(..hstmt,ii)
		s ..columns(ii,"Datatype")=%JDBCGateway.getColumnTypeName(..hstmt,ii)
		s ..columns(ii,"DisplaySize")=%JDBCGateway.getColumnDisplaySize(..hstmt,ii)
		s ..columns(ii,"IsMoney")=%JDBCGateway.isCurrency(..hstmt,ii)
		s bstr=$Char(0,0,0,0,0,0,0,0,0,0,0)
		Set metadata = metadata _ $lb(..columns(ii,"Name"),..columns(ii,"SqlType"),..columns(ii,"Precision"),..columns(ii,"Scale"),..columns(ii,"Nullable"),..columns(ii,"Name"),"","","",bstr)
	}
	s ..%Metadata=metadata
	s ..%NextColumn=0
	quit $$$OK
}

/// it expects $lb(dllHandle,ConnectionHandle,StatementHandle)
Method %OnNew(conninfo As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	s ..hstmt=$li(conninfo,1)
	d ..InitMetadata()
	//d ..%Next()
	quit $$$OK
}

Method %SendODBC() As %Integer
{
	if '..sentODBC{ s ..sentODBC=1 d ..%Next()}
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
