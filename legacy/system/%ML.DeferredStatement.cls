/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// Deferred version of a %SQL.Statement.  This class is a facade for
/// %SQL.Statement and as such implements the %SQL.Statement interface
/// 
Class %ML.DeferredStatement Extends %RegisteredObject [ System = 4 ]
{

/// SQL statement
Property SQL As %String [ MultiDimensional ];

/// SQL statement to count result set rows
Property SQLCOUNT As %String [ MultiDimensional ];

/// Any query args
Property Args As %String [ MultiDimensional ];

/// <p>
/// %SQLCODE indicates whether or not the statement was executed successfully. If %SQLCODE is not negative (greater than or equal to zero)
/// then the statement was successfully executed. Otherwise, the value of %SQLCODE contains the error code and
/// the %Message property might contain more information about the error.
/// </p>
Property %SQLCODE As %Library.Integer [ InitialExpression = 0 ];

/// %Message contains additional information about an error reported as a negative value in <property>%SQLCODE</property>. Additional information is
/// not always available.
Property %Message As %Library.String(MAXLEN = 256);

/// 
/// Facade for %SQL.Statement:%Prepare()
/// 
Method %Prepare(ByRef %statement As %String) As %Status
{
	Merge ..SQL = %statement
	RETURN $$$OK
}

/// 
/// Facade for %SQL.Statement:%Execute
/// 
/// Note, returns $THIS as it's not a real resultset, but it'll get passed into the ML provider.
/// 
Method %Execute(%parm...) As %SQL.StatementResult
{
	Merge ..Args = %parm
	RETURN $THIS
}

/// 
/// Facade for %SQL.Statement:%ExecDirect
/// 
/// Note, returns $THIS as it's not a real resultset, but it'll get passed into the ML provider.
/// 
ClassMethod %ExecDirect(ByRef StmtHandle As %SQL.Statement = {$$$NULLOREF}, ByRef %statement As %RawString = "", ByRef %statementcount As %RawString = "", %parm...) As %SQL.StatementResult
{
	if '$isobject(StmtHandle) { set StmtHandle = ..%New() }
	Merge StmtHandle.SQL = %statement
	Merge StmtHandle.SQLCOUNT = %statementcount
	Merge StmtHandle.Args = %parm
	RETURN StmtHandle
}

/// 
/// No-op implementation of this
/// 
Method %Next(ByRef sc As %Status) As %Integer
{
	Set sc = $$$ERROR($$$NotImplemented)
	RETURN 0
}

}
