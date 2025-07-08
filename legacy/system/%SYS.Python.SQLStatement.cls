/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %occErrors)

/// 
/// Implementation of SQL support
/// 
Class %SYS.Python.SQLStatement Extends %RegisteredObject [ System = 4 ]
{

/// 
/// Wrapped statement
/// 
Property Statement As %SQL.Statement;

/// 
/// Implement %OnNew handler
/// 
Method %OnNew(stmt As %SQL.StatementResult) As %Status
{
    Set ..Statement = stmt
    Quit $$$OK
}

/// 
/// Execute an SQL statement
/// 
Method execute(args...) As SQLResultSet
{
    Set rs = ..Statement.%Execute(args...)

    Throw:'$IsObject(rs) ##class(SQL).raiseError($$$ERROR($$$SQLError,$G(SQLCODE),$G(%msg)))
    Throw:rs.%SQLCODE'=0 ##class(SQL).raiseError($$$ERROR($$$SQLError,rs.%SQLCODE,rs.%Message))

    Set wrapper = ##class(SQLResultSet).%New(rs)

    Quit wrapper
}

}
