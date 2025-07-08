/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occJava

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.JDBC.Connection Extends %XDBC.Gateway.Connection [ System = 4 ]
{

Parameter FOREIGNCONNECTIONCLASS As String = "com.intersystems.xdbc.gateway.ForeignConnection";

/// A constant indicating that transactions are not supported.
Parameter TRANSACTIONNONE = 0;

Parameter TRANSACTIONREADUNCOMMITTED = 1;

Parameter TRANSACTIONREADCOMMITTED = 2;

Parameter TRANSACTIONREPEATABLEREAD = 4;

Parameter TRANSACTIONSERIALIZABLE As Integer = 8;

Parameter TYPESCROLLFORWARDONLY = 1003;

Parameter TYPESCROLLINSENSITIVE = 1004;

Parameter TYPESCROLLSENSITIVE = 1005;

Parameter CONCURREADONLY = 1007;

Parameter CONCURUPDATEABLE = 1008;

Property java As %External.JavaGateway;

Property jdbcConnection As %Net.Remote.Object;

ClassMethod GetJdbcConnection(connectionInfo As %Library.DynamicObject) As %XDBC.Gateway.JDBC.Connection
{
    new %objlasterror
    set java = $system.external.getJavaGateway()
    try {
        set jar = ##class(%External.Gateway).getJarPath("intersystems-utils")
        set jarpath = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_"/dev/java/lib/1.8/" _ jar)
        do java.addToPath(jarpath)
        set jdbcConnection = ..getExternalJdbcConnection(java, connectionInfo)
        set connection = ..%New()
        set connection.java = java
        set connection.jdbcConnection = jdbcConnection
        return connection
    } catch exception {
        throw exception
    }
}

Method %OnClose() As %Status
{
    do ..Close()
    return $$$OK
}

/// Releases this Connection object's database and resources immediately instead of waiting for them to be automatically released
Method Close()
{
    if $isobject(..jdbcConnection) {
        do ..jdbcConnection.close()
    }
}

/// Makes all changes made since the previous commit/rollback permanent and releases any database locks currently held by this Connection object
Method Commit()
{
    do ..jdbcConnection.commit()
}

/// Creates a Statement object for sending SQL statements to the database
Method CreateStatement() As Statement
{
    set jdbcStatement = ..jdbcConnection.createStatement()
    return ##class(%XDBC.Gateway.JDBC.Statement).%New($this, jdbcStatement)
}

/// Retrieves the current auto-commit mode for this Connection object
Method GetAutoCommit() As %Boolean
{
    return ..jdbcConnection.getAutoCommit()
}

/// Retrieves a DatabaseMetaData object that contains metadata about the database to which this Connection object represents a connection
Method GetMetaData() As DatabaseMetaData
{
    set emd = ..jdbcConnection.getMetaData()
    return ##class(%XDBC.Gateway.JDBC.DatabaseMetaData).%New($this, emd)
}

/// Retrieves this Connection object's current schema name
Method GetSchema() As %String
{
    return ..jdbcConnection.getSchema()
}

/// Retrieves this Connection object's current transaction isolation level
Method GetTransactionIsolation() As %Integer
{
    return ..jdbcConnection.getTransactionIsolation()
}

/// Retrieves whether this Connection object has been closed
Method IsClosed() As %Boolean
{
    return ..jdbcConnection.isClosed()
}

/// Retrieves whether this Connection object is in read-only mode
Method IsReadOnly() As %Boolean
{
    return ..jdbcConnection.isReadOnly()
}

/// Returns true if the connection has not been closed and is still valid
Method IsValid(timeout As %Integer = 0) As %Boolean
{
    return ..jdbcConnection.isValid(timeout)
}

/// Creates a Statement object for calling stored procedures
Method PrepareCall(sql As %String) As Statement
{
    set callableStatement = ..jdbcConnection.prepareCall(sql)
    return ##class(%XDBC.Gateway.JDBC.CallableStatement).%New($this, callableStatement)
}

/// Creates a statement object for sending parameterized SQL statements to the database
Method PrepareStatement(sql As %String, resultSetType As %Integer = {..#TYPESCROLLFORWARDONLY}, resultSetConcurrency As %Integer = {..#CONCURREADONLY}) As Statement
{
    set preparedStatement = ..jdbcConnection.prepareStatement(sql, resultSetType, resultSetConcurrency)
    return ##class(%XDBC.Gateway.JDBC.PreparedStatement).%New($this, preparedStatement)
}

/// Undoes all changes made in the current transaction and releases any database 
/// locks currently held by this Connection object
Method Rollback()
{
    do ..jdbcConnection.rollback()
}

/// Sets this connection's auto-commit mode to the given state
Method SetAutoCommit(autoCommit As %Boolean)
{
    do ..jdbcConnection.setAutoCommit(autoCommit)
}

/// Puts this connection in read-only mode as a hint to the driver to enable database optimizations
Method SetReadOnly(readOnly As %Boolean)
{
    do ..jdbcConnection.setReadOnly(readOnly)
}

/// Sets the given schema name to access
Method SetSchema(schema As %String)
{
    do ..jdbcConnection.setSchema(schema)
}

/// Attempts to change the transaction isolation level for this Connection object to the one given
/// level is 1, 2, 4 (Connection.TRANSACTION_REPEATABLE_READ) or 8 (Connection.TRANSACTION_SERIALIZABLE)
Method SetTransactionIsolation(level As %Integer)
{
    do ..jdbcConnection.setTransactionIsolation(level)
}

/// Connect to a JDBC data source, return an instance of java.sql.Connection
ClassMethod getExternalJdbcConnection(java As %External.JavaGateway, properties As %Library.DynamicObject) [ Internal, Private ]
{
    set connection = $$$NULLOREF
    if properties.classpath '= "" {
        do java.addToPath(properties.classpath)
    }
    if (properties.datasource '="") {
	    
	    // use java.sql.DataSource approach when specified
        set dataSource = java.new(properties.datasource)
        if properties.url '="" {
            do dataSource.setURL(properties.url)
        } else {
            do dataSource.setServerName(properties.host)
            do dataSource.setPortNumber(properties.port)
            do dataSource.setDatabaseName(properties.databasename)
        }
        if properties.user '= "" {
            do dataSource.setUser(properties.user)
        }
        if properties.password '= "" {
            do dataSource.setPassword(properties.password)
        }
        set connection = dataSource.getConnection()
        
    } elseif properties.url '= "" {
	    
	    // DP-435061 - build properties
        set javaProperties = java.new("java.util.Properties")
        if properties.user '= "" {
            do javaProperties.put("user", properties.user)
        }
        if properties.password '= "" {
            do javaProperties.put("password", properties.password)
        }
        if properties.properties '= "" {
	        // somewhat blunt for now
	        for i = $l(properties.properties,";") {
		        set prop = $p(properties.properties,";",i)
		        do javaProperties.put($zstrip($p(prop,"=",1),"<>W"), $zstrip($p(prop,"=",2,*),"<>W"))
	        }
        }
	    
        try {
	        
	        // try automatic driver resolution using java.sql.DriverManager
	        set connection = java.invoke("java.sql.DriverManager", "getConnection", properties.url, javaProperties)
	        
        } catch (exception) {
	        
	        // if this fails, try using the specified driver directly
            if properties.driver '= "" {
                set driver = java.new(properties.driver)
                set connection = driver.connect(properties.url, javaProperties)
            } else {
                throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"JDBC Gateway - no suitable JDBC Driver found")
            }
            
        }
    } else {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"JDBC Gateway - SQL Connection must include at least a connection URL")
    }
    if $isobject(connection) {
        set externalConnection = java.new(..#FOREIGNCONNECTIONCLASS, connection)
    } else {
        set externalConnection = $$$NULLOREF
    }
    return externalConnection
}

}
