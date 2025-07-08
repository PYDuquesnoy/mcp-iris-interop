/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.ODBC.Connection Extends %XDBC.Gateway.Connection [ System = 4 ]
{

ClassMethod InitEnvironment() As %ObjectHandle
{
	set gateway = $SYSTEM.external.getODBCGateway()
	if ("" = gateway) {
		w !,"gateway not runing"
		q ""		
	}
	
	set enviroment = gateway.new("ODBC")
	quit enviroment
}

ClassMethod GetODBCConnection(connectionInfo As %Library.DynamicObject) As %XDBC.Gateway.ODBC.Connection
{
	#dim connection as %XDBC.Gateway.ODBC.Connection	
    try {
    	set gateway = $SYSTEM.external.getODBCGateway()
		if ("" = gateway) {
			w !,"gateway not runing"
			q		
		}
	
        set enviroment = ##class(%XDBC.Gateway.ODBC.Connection).InitEnvironment()
        set connection = ..%New()
        set connection.enviroment = enviroment
        set connection.connection = connection.enviroment.CreateConnection()
        set dsn = connectionInfo.dsn
        if (""'=dsn)
        {
	        set pass = connectionInfo.password
	        set username = connectionInfo.username
	        set rc = connection.connection.Connect(dsn,username,pass)
        } else {
	        set str = connectionInfo.string
	        set rc = connection.connection.DriverConnect(str,0)
	        
        }
        return connection
    } catch exception {
        throw exception
    }
}

/// Makes all changes made since the previous commit/rollback permanent and releases any database locks currently held by this Connection object
Method Commit()
{
    do ..connection.EndTransaction(0)
}

/// Call Close (ODBC Disconnect) on connection
Method Close()
{
	do ..connection.Disconnect()
}

/// Undoes all changes made in the current transaction and releases any database 
/// locks currently held by this Connection object
Method Rollback()
{
    do ..connection.EndTransaction(1)
}

/// Sets this connection's auto-commit mode to the given state
Method SetAutoCommit(autoCommit As %Boolean)
{
	if (autoCommit) {
		set value = 1
	} else {
		set value = 0
	}
		 
    do ..connection.SetConnectionAttr(102,autoCommit,"")
}

/// Retrieves the current auto-commit mode for this Connection object
Method GetAutoCommit() As %Boolean
{
    return ..connection.GetConnectionAttr(102,-6)
}

/// Creates a Statement object for sending SQL statements to the database
Method CreateStatement() As Statement
{
    set Statement = ..connection.Statement()
    return ##class(%XDBC.Gateway.ODBC.Statement).%New($this, Statement)
}

/// Retrieves this Connection object's current transaction isolation level
Method GetTransactionIsolation() As %Integer
{
    return ..connection.GetConnectionAttr(108, -6) ; SQL_TXN_ISOLATION_OPTION
}

/// Attempts to change the transaction isolation level for this Connection object to the one given
/// level is 1, 2, 4 (Connection.TRANSACTION_REPEATABLE_READ) or 8 (Connection.TRANSACTION_SERIALIZABLE)
Method SetTransactionIsolation(level As %Integer)
{
    do ..connection.SetConnectionAttr(108,level,-6) ; SQL_TXN_ISOLATION_OPTION
}

/// Retrieves whether this Connection object is in read-only mode
Method IsReadOnly() As %Boolean
{
    return ..connection.GetConnectionAttr(101 ,-6) ; SQL_ATTR_ACCESS_MODE
}

/// Puts this connection in read-only mode as a hint to the driver to enable database optimizations
Method SetReadOnly(readOnly As %Boolean)
{
    do ..connection.SetConnectionAttr(101 ,readOnly,-6) ; SQL_ATTR_ACCESS_MODE
}

/// Creates a Statement object for calling stored procedures
Method PrepareCall(sql As %String) As Statement
{
	#dim Statement as %XDBC.Gateway.ODBC.Statement
    set Statement = ..CreateStatement()
    set status = Statement.Prepare(sql)
    return Statement
}

/// Creates a statement object for sending parameterized SQL statements to the database
Method PrepareStatement(sql As %String) As Statement
{
	return ..PrepareCall(sql)
}

/// Get connection information specifyed by Type
Method GetInfo(Type As %Integer) As %String
{
	s ret = ..connection.GetInfo(Type)
	return ret
}

Method GetConnectionAttribute(Attribute As %Integer, IsInteger As %Boolean) As %String
{
	if (IsInteger) {
		set ret = ..connection.GetConnectionAttr(Attribute, -6)
	} 
	else {
		set ret = ..connection.GetConnectionAttr(Attribute, -3)
	} 
	return ret
}

Method SetAttribute(Attribute As %Integer, Value As %String, IsInteger As %Boolean) As %Status
{
	
	if (IsInteger) {
		set ret = ..connection.SetConnectionAttr(Attribute, Value,-6)
	} 
	else {
		set ret = ..connection.GetConnectionAttr(Attribute, Value, -3)
	} 
	
	if (0 = ret ) {
		return $$$OK
	} else {
		return $$$ERROR(ret)
	}
}

Method GetTables(Catalog As %String, Schema As %String, Table As %String) As ResultSet
{
	#dim Statement as %XDBC.Gateway.ODBC.Statement
    set Statement = ..CreateStatement()
	set ret =  Statement.GetTables(Catalog,Schema,Table)
	if ($$$OK '= ret) {
		set Statement = ""
	}
	return ##class(%XDBC.Gateway.ODBC.ResultSet).%New(Statement)
}

Method GetTablePriviligies(Schema As %String, Table As %String) As ResultSet
{
	#dim Statement as %XDBC.Gateway.ODBC.Statement
    set Statement = ..CreateStatement()
	set ret =  Statement.GetTablePriviligies(Schema,Table)
	if ( $$$OK '= ret) {
		set Statement = ""
	}
	return ##class(%XDBC.Gateway.ODBC.ResultSet).%New(Statement)
}

/// Retrieves whether this Connection object has been closed
Method IsClosed() As %Boolean
{
	try {
	 	set Statement = ..connection.Statement()
		if ("" = Statement) {
			return 1
		}
		set rc = Statement.ExecuteDirect("Select 1")
		if (0 = rc) {
			set rc = Statement.Fetch()
			if (0 = rc) {
				set rc = Statement.Fetch()
				if ((0 = rc) !(100 = rc)) {
					return 0
				} else {
					return 1
				}
			} else {
				return 1
			} 
		} else {
			return 1
		}
	} catch ex {
		return 1
		}
}

/// Returns true if the connection has not been closed and is still valid
Method IsValid(timeout As %Integer = 0) As %Boolean
{
	try {
 	set Statement = ..connection.Statement()
	if ("" = Statement) {
		return 0
	}
	set rc = Statement.ExecuteDirect("Select 1")
	if (0 = rc) {
		set rc = Statement.Fetch()
		if (0 = rc) {
			set rc = Statement.Fetch()
			if ((0 = rc) !(100 = rc)) {
				return 1
			} else {
				return 0
			}
		} else {
			return 0
		} 
	} else {
		return 0
	}
		} catch ex {
		return 0
	}
}

/// Retrieves a DatabaseMetaData object that contains metadata about the database to which this Connection object represents a connection
Method GetMetaData() As %XDBC.Gateway.ODBC.DatabaseMetaData
{
    return ##class(%XDBC.Gateway.ODBC.DatabaseMetaData).%New($this)
}

/// Retrieves this Connection object's current schema name
Method GetSchema() As %String
{
	#dim rs as %XDBC.Gateway.ODBC.ResultSet
    set Statement = ..CreateStatement() ;   connection.Statement()
	if ("" = Statement) {
		return ""
	}
	try {
	 	set rs = Statement.ExecuteQuery("SELECT %SYSTEM_SQL.DefaultSchema()")
		do rs.Next()
		return rs.Get(1)
	} catch (exception) {
		throw ##class(%Exception.General).%New("Method Not Supported for this database")
	}
}

/// Sets the given schema name to access
Method SetSchema(schema As %String)
{
    #dim Statement  as %XDBC.Gateway.ODBC.Statement
    set Statement = ..CreateStatement() ;  
 	set rc = Statement.ExecuteDirect("SET OPTION DEFAULT_SCHEMA = "_schema)
}

Property gateway As %ObjectHandle;

Property enviroment As %ObjectHandle;

Property connection As %ObjectHandle;

}
