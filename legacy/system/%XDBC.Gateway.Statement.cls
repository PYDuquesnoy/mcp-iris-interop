/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.Statement Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Sets the value of the designated parameter with the given object.
/// Method SetObject(parameterName As %String, parameter As %ObjectHandle) {}
/// Adds the given SQL command to the current list of commands for this Statement object.
Method AddBatch(sql As %String) [ Abstract ]
{
}

/// Cancels this Statement object if both the DBMS and driver support aborting an SQL statement.
Method Cancel() [ Abstract ]
{
}

/// Empties this Statement object's current list of SQL commands.
Method ClearBatch() [ Abstract ]
{
}

/// Releases this Statement object's database and JDBC resources immediately instead of waiting for this to happen when it is automatically closed.
Method Close() [ Abstract ]
{
}

/// Executes the given SQL statement, which may return multiple results, and signals the driver that any auto-generated keys should be made available for retrieval
Method Execute(sql As %String, autoGeneratedKeys As %Integer = "") As %Boolean [ Abstract ]
{
}

/// Submits a batch of commands to the database for execution and if all commands execute successfully, returns an array of update counts
Method ExecuteBatch() As %ListOfDataTypes [ Abstract ]
{
}

/// list of int
/// Executes the given SQL statement, which returns a single ResultSet object
Method ExecuteQuery(sql As %String) As ResultSet [ Abstract ]
{
}

/// Executes the given SQL statement, which may be an INSERT, UPDATE, or DELETE statement or an SQL statement that returns nothing, such as an SQL DDL statement
/// Executes the given SQL statement and signals the driver with the given flag about whether the auto-generated keys produced by this Statement object should be made available for retrieval.
Method ExecuteUpdate(sql As %String, autoGeneratedKeys As %Integer = "") As %Integer [ Abstract ]
{
}

/// Retrieves the Connection object that produced this Statement object
Method GetConnection() As Connection [ Abstract ]
{
}

/// Retrieves the number of result set rows that is the default fetch size for ResultSet objects generated from this Statement object
Method GetFetchSize() As %Integer [ Abstract ]
{
}

/// Retrieves any auto-generated keys created as a result of executing this Statement object
Method GetGeneratedKeys() As ResultSet [ Abstract ]
{
}

/// Retrieves the maximum number of bytes that can be returned for character and binary column values in a ResultSet object produced by this Statement object
Method GetMaxFieldSize() As %Integer [ Abstract ]
{
}

/// Retrieves the maximum number of rows that a ResultSet object produced by this Statement object can contain
Method GetMaxRows() As %Integer [ Abstract ]
{
}

/// Moves to this Statement object's next result, returns true if it is a ResultSet object, and implicitly closes any current ResultSet object(s) obtained with the method getResultSet.
Method GetMoreResults() As %Boolean [ Abstract ]
{
}

/// Retrieves the number of seconds the driver will wait for a Statement object to execute.
Method GetQueryTimeout() As %Integer [ Abstract ]
{
}

/// Retrieves the current result as a ResultSet object.
Method GetResultSet() As ResultSet [ Abstract ]
{
}

/// Retrieves the column metadata for the result set that will be returned for this statement as a ResultSetMetaData object.
Method GetResultSetMetaData() As ResultSetMetaData [ Abstract ]
{
}

/// Retrieves the current result as an update count; if the result is a ResultSet object or there are no more results, -1 is returned
Method GetUpdateCount() As %Integer [ Abstract ]
{
}

/// Retrieves whether this Statement object has been closed
Method IsClosed() As %Boolean [ Abstract ]
{
}

/// Gives the driver a hint as to the number of rows that should be fetched from the database when more rows are needed for ResultSet objects genrated by this Statement.
Method SetFetchSize(rows As %Integer) [ Abstract ]
{
}

/// Sets the limit for the maximum number of bytes that can be returned for character and binary column values in a ResultSet object produced by this Statement object.
Method SetMaxFieldSize(max As %Integer) [ Abstract ]
{
}

/// Sets the limit for the maximum number of rows that any ResultSet object generated by this Statement object can contain to the given number.
Method SetMaxRows(max As %Integer) [ Abstract ]
{
}

/// Sets the number of seconds the driver will wait for a Statement object to execute to the given number of seconds.
Method SetQueryTimeout(seconds As %Integer) [ Abstract ]
{
}

}
