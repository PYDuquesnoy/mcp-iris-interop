/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %XDBC.Gateway.ODBC.Statement Extends %XDBC.Gateway.Statement [ System = 4 ]
{

Property connection As %XDBC.Gateway.ODBC.Connection;

Property statement As %ObjectHandle;

Method %OnNew(connection As %XDBC.Gateway.ODBC.Connection, statement As %ObjectHandle) As %Status
{
   set ..connection = connection
   set ..statement = statement
   return $$$OK
}

Method Prepare(sql As %String) As %Status
{
	set rc = ..statement.Prepare(sql)
	if (0 = rc)
		return $$$OK
	else		
		return $$$ISERR(rc)
}

Method GetTables(Catalog As %String, Schema As %String, Table As %String) As %Status
{
	set rc =  ..statement.Tables(Catalog,Schema,Table,"")
	if (0 = rc)
		return $$$OK
	else		
		return $$$ISERR(rc)
}

Method GetTablePriviligies(Schema As %String, Table As %String) As %Status
{
	set rc =  ..statement.TablePrivileges("",Schema,Table)
	if (0 = rc)
		return $$$OK
	else		
		return $$$ISERR(rc)
}

/// Executes the given SQL statement, which may return multiple results
Method ExecuteDirect(sql As %String) As %Boolean
{
	set rc = ..statement.ExecuteDirect(sql)
	if (0 = rc)
		return $$$OK
	else		
		return $$$ISERR(rc)
}

/// Executes the prepared SQL statement, which may return multiple results
Method Execute() As %Boolean
{
	set rc = ..statement.Execute()
	if (0 = rc)
		return $$$OK
	else		
		return $$$ISERR(rc)
}

/// Executes the given SQL statement, which returns a single ResultSet object
Method ExecuteQuery(sql As %String) As %XDBC.Gateway.ResultSet
{
	if ($d(sql))
	{
		if ('..ExecuteDirect(sql)) {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(400,"Error executing query "_sql)
		}
	} else {
		if ('..Execute()) {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(400,"Error executing query "_sql)
		}
	}
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New($this)
	return rs
}

/// Retrieves the Connection object that produced this Statement object
Method GetConnection() As Connection
{
	return ..connection
}

/// Executes the given SQL statement, which may be an INSERT, UPDATE, or DELETE statement or an SQL statement that returns nothing, such as an SQL DDL statement
/// Executes the given SQL statement and signals the driver with the given flag about whether the auto-generated keys produced by this Statement object should be made available for retrieval.
Method ExecuteUpdate(sql As %String) As %Integer
{
	return ..ExecuteDirect(sql)
}

/// Retrieves the current result as a ResultSet object.
Method GetResultSet() As %XDBC.Gateway.ResultSet
{
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New($this)
	return rs
}

/// Retrieves the maximum number of rows that a ResultSet object produced by this Statement object can contain
Method GetMaxRows() As %Integer
{
	return ..statement.RowCount()
}

/// Method Not Supported
Method SetMaxFieldSize(max As %Integer)
{
	//not implemented in jdbc
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method SetMaxRows(max As %Integer)
{
	//not implemented in jdbc
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Sets the number of seconds the driver will wait for a Statement object to execute to the given number of seconds.
Method SetQueryTimeout(seconds As %Integer)
{
	return ..statement.SetStatementAttribute(0,seconds,-5) ;	SQL_QUERY_TIMEOUT,SQL_IS_UINTEGER
}

/// Method Not Supported
Method GetUpdateCount() As %Integer
{
		//not implemented in jdbc
		throw ##class(%Exception.General).%New("Method Not Supported")
}

Method GetMoreResults() As %Boolean
{
	set rc = ..statement.MoreResults()
	if ( 0 /*SQL_SUCCES*/ = rc ) {
		return 1
	} else {
		return 0
	}
}

/// Releases this Statement object's database and resources immediately instead of waiting for this to happen when it is automatically closed.
Method Close()
{
	do ..statement.FreeStatement(0)
}

/// Cancels this Statement object if both the DBMS and driver support aborting an SQL statement.
Method Cancel()
{
	do ..statement.Cancel()
}

/// Retrieves the number of result set rows that is the default fetch size for ResultSet objects generated from this Statement object
Method GetFetchSize() As %Integer
{
	return ..statement.GetStatementAttribute(27,-6)	;SQL_ATTR_ROW_ARRAY_SIZE,SQL_IS_INTEGER
}

/// Retrieves the maximum number of bytes that can be returned for character and binary column values in a ResultSet object produced by this Statement object
Method GetMaxFieldSize() As %Integer
{
	return ..statement.GetStatementAttribute(3,-6)	;SQL_ATTR_MAX_LENGTH ,SQL_IS_INTEGER
}

/// Method Not Supported
Method GetGeneratedKeys() As %XDBC.Gateway.ResultSet
{
	//message "GG"
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Gives the driver a hint as to the number of rows that should be fetched from the database when more rows are needed for ResultSet objects genrated by this Statement.
Method SetFetchSize(rows As %Integer)
{
	return ..statement.SetStatementAttribute(27,rows,-6)	;SQL_ATTR_ROW_ARRAY_SIZE,SQL_IS_INTEGER
}

/// Retrieves the number of seconds the driver will wait for a Statement object to execute.
Method GetQueryTimeout() As %Integer
{
	return ..statement.GetStatementAttribute(0,-5) ;	SQL_QUERY_TIMEOUT,SQL_IS_UINTEGER
}

/// Method Not Supported
Method IsClosed() As %Boolean
{
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported, use PreparedStatement.AddBatchEx
Method AddBatch(sql As %String, ColumnBinding As %Boolean, size As %Integer, statusArray As %Boolean)
{
	throw ##class(%Exception.General).%New("Method Not Supported, use PreparedStatement.AddBatchEx")
}

/// Method Not Supported
Method ClearBatch()
{
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported, use PreparedStatement.ExecuteBatchEx
Method ExecuteBatch() As %ListOfDataTypes
{
	throw ##class(%Exception.General).%New("Method Not Supported, use PreparedStatement.ExecuteBatchEx")
}

}
