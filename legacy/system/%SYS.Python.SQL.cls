/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %occErrors)

/// 
/// Implementation of SQL support
/// 
Class %SYS.Python.SQL Extends %RegisteredObject [ System = 4 ]
{

/// 
/// Execute an SQL statement
/// 
ClassMethod exec(sql As %String, args...) As %SQL.StatementResult
{
	Set rs = ##class(%SQL.Statement).%ExecDirect(,sql,args...)

	Throw:'$IsObject(rs) ..raiseError($$$ERROR($$$SQLError,$G(SQLCODE),$G(%msg)), sql)
	Throw:rs.%SQLCODE'=0 ..raiseError($$$ERROR($$$SQLError,rs.%SQLCODE,rs.%Message), sql)

	Set wrapper = ##class(SQLResultSet).%New(rs)

	Quit wrapper
}

ClassMethod prepare(sql As %String) As %SQL.Statement
{
	Set stmt = ##class(%SQL.Statement).%New()
	Set sc = stmt.%Prepare(sql)
	If $$$ISERR(sc) {
		Throw ..raiseError(sc, sql)
	}

	Set wrapper = ##class(SQLStatement).%New(stmt)

	Quit wrapper
}

/// 
/// Helper method to raise SQL errors
/// 
ClassMethod raiseError(status As %Status, stmt As %String = "") [ Internal ]
{
	// Check for SQL errors
	If $CASE(+$system.Status.GetErrorCodes(status),$$$SQLError:1,$$$SQLCode:1,:0) {
		Do $system.Status.DecomposeStatus(status, .info)
		Set ib = $system.Python.Import("irisbuiltins")
		Set sqlcode = $G(info(1,"param",1))
		Set msg = $G(info(1,"param",2))

		RETURN ib.SQLError(sqlcode, msg, $S(stmt'="":stmt,1:$system.Python.None()))
	} Else {
		RETURN $system.Python.Builtins().RuntimeError($system.Status.GetErrorText(status))
	}
}

}
