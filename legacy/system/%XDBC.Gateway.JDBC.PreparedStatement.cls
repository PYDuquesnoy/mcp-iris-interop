/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.JDBC.PreparedStatement Extends %XDBC.Gateway.JDBC.Statement [ System = 4 ]
{

Property %foreignstatement As %Net.Remote.Object;

Method %OnNew(connection As %XDBC.Gateway.JDBC.Connection, statement As %ObjectHandle) As %Status
{
    do ##super(.connection,.statement)
    set ..%foreignstatement = ..connection.jdbcConnection.getPreparedStatement(statement)
    return $$$OK
}

///    boolean execute()
Method Execute(void As %String) As %Boolean
{
    new %objlasterror
    if $data(void) {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(-400, "Cannot pass an SQL statement to PreparedStatement.execute")
    }
   return ..%foreignstatement.execute()
}

/// Executes the prepared statement, returns a single ResultSet object
/// Accepts no arguments, a single void argument is defined to satisfy inheritance rules
/// but is not expected to be passed. If void is defined then an exception will be thrown.
/// ResultSet executeQuery()
Method ExecuteQuery(void As %String) As ResultSet
{
    new %objlasterror
    if $data(void) {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(-400, "Cannot pass an SQL statement to PreparedStatement.executeQuery")
    }
    set externalResult = ..connection.jdbcConnection.executeQuery(..statement)
    set result = ##class(%XDBC.Gateway.JDBC.ResultSet).%New(..connection, externalResult)
    if (result = $$$NULLOREF) {
        if $$$ISERR($get(%objlasterror,$$$OK)) {
            throw ##class(%Exception.StatusException).CreateFromStatus(%objlasterror)
        } else {
            throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Unknown error encountered while executing external JDBC Query")
        }
    } elseif result.%SQLCODE < 0 {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE, result.%Message)
    }
    return result
}

///    int executeUpdate()
Method ExecuteUpdate(void As %String) As %Integer
{
    new %objlasterror
    if $data(void) {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(-400, "Cannot pass an SQL statement to PreparedStatement.executeUpdate")
    }
   return ..%foreignstatement.executeUpdate()
}

Method AddBatch(sql As %String)
{
    if $data(sql) {
        do ..%foreignstatement.addBatch(sql)
    } else {
        do ..%foreignstatement.addBatch()
    }
}

/// This is meant to return the column metadata as a %SQL.StatementMetadata object. If you want a %XDBC.Gateway.ResultSetMetaData object,
/// you should call GetResultSetMetaData()
Method GetMetaData() As %SQL.StatementMetadata
{
    new %objlasterror
    set rsmd = ..GetResultSetMetaData() // returns %XDBC.Gateway.ResultSetMetaData
    set sc = rsmd.ToSQLMetadata(.metadata)
    RETURN $case($$$ISOK(sc), 1:##class(%SQL.StatementMetadata).%New(1, .metadata), :"")
}

Method GetParameterMetaData() As %XDBC.Gateway.ParameterMetaData
{
    new %objlasterror
    RETURN ##class(%XDBC.Gateway.ParameterMetaData).%New(..connection.jdbcConnection.getParameterMetaData(..statement))
}

/// method SetAsciiStream(paramIdx as %RawString, value As %Stream.Object) {}
Method SetAsciiStream(paramIdx As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setAsciiStream(+paramIdx, value, +length)
    } else {
        do ..%foreignstatement.setAsciiStream(+paramIdx, value)
    }
}

Method SetBigDecimal(paramIdx As %RawString, value As %Decimal)
{
    do ..%foreignstatement.setBigDecimal(+paramIdx, value)
}

Method SetBinaryStream(paramIdx As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setBinaryStream(+paramIdx, value, +length)
    } else {
        do ..%foreignstatement.setBinaryStream(+paramIdx, value)
    }
}

Method SetBlob(paramIdx As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setBlob(+paramIdx, value, +length)
    } else {
        do ..%foreignstatement.setBlob(+paramIdx, value)
    }
}

Method SetBoolean(paramIdx As %RawString, value As %Boolean)
{
    do ..%foreignstatement.setBoolean(+paramIdx, value)
}

Method SetByte(paramIdx As %RawString, value As %SmallInt)
{
    do ..%foreignstatement.setByte(+paramIdx, value)
}

Method SetBytes(paramIdx As %RawString, value As %RawString)
{
    do ..%foreignstatement.setBytes(+paramIdx, value)
}

Method SetCharacterStream(paramIdx As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setCharacterStream(+paramIdx, value, +length)
    } else {
        do ..%foreignstatement.setCharacterStream(+paramIdx, value)
    }
}

Method SetClob(paramIdx As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setClob(+paramIdx, value, +length)
    } else {
        do ..%foreignstatement.setClob(+paramIdx, value)
    }
}

Method SetDate(paramIdx As %RawString, value As %Date, cal As %Net.Remote.Object)
{
    if $data(cal) {
        do ..%foreignstatement.setDate(+paramIdx, value, cal)
    } else {
        do ..%foreignstatement.setDate(+paramIdx, value)
    }
}

/// void setDouble(int parameterIndex, double x)
Method SetDouble(paramIdx As %RawString, value As %Float)
{
    do ..%foreignstatement.setDouble(paramIdx, value)
}

/// void setInt(int parameterIndex, int x)
Method SetInt(paramIdx As %RawString, value As %Integer)
{
    do ..%foreignstatement.setInt(paramIdx, value)
}

Method SetFloat(paramIdx As %RawString, value As %Float)
{
    do ..%foreignstatement.setFloat(+paramIdx, value)
}

Method SetLong(paramIdx As %RawString, value As %Integer)
{
    do ..%foreignstatement.setLong(+paramIdx, value)
}

/// method SetNCharacterStream(paramIdx as %RawString, value as %Stream.Object) {}
Method SetNCharacterStream(paramIdx As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setNCharacterStream(+paramIdx, value, +length)
    } else {
        do ..%foreignstatement.setNCharacterStream(+paramIdx, value)
    }
}

/// method SetNClob(paramIdx as %RawString, value As %Stream.Object) {}
/// method SetNClob(paramIdx as %RawString, value as %Stream.Object) {}
Method SetNClob(paramIdx As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setNClob(+paramIdx, value, +length)
    } else {
        do ..%foreignstatement.setNClob(+paramIdx, value)
    }
}

Method SetNString(paramIdx As %RawString, value As %String)
{
    do ..%foreignstatement.setNString(+paramIdx, value)
}

/// throws SQLException
/// method SetNull(paramIdx as %RawString, sqlType as %Integer) {}
Method SetNull(paramIdx As %RawString, sqlType As %Integer, typeName As %String)
{
    if $data(typeName) {
        do ..%foreignstatement.setNull(+paramIdx, sqlType, typeName)
    } else {
        do ..%foreignstatement.setNull(+paramIdx, sqlType)
    }
}

/// method SetObject(paramIdx as %RawString, value As %ObjectHandle, targetSqlType as %Integer) {}
/// method SetObject(paramIdx as %RawString, x) {}
Method SetObject(paramIdx As %RawString, value As %ObjectHandle, targetSqlType As %Integer, scale As %Integer)
{
    if $isobject(targetSqlType) && $data(scale) {
        do ..%foreignstatement.setObject(paramIdx, value, targetSqlType, scale)
        return
    }
    do ..%foreignstatement.setObject(paramIdx, value, targetSqlType)
}

Method SetShort(paramIdx As %RawString, value As %SmallInt)
{
    do ..%foreignstatement.setShort(+paramIdx, value)
}

///     void setString(int parameterIndex, String x)
Method SetString(paramIdx As %RawString, value As %String)
{
    do ..%foreignstatement.setString(paramIdx, value)
}

Method SetTime(paramIdx As %RawString, value As %Time, cal As %Net.Remote.Object)
{
    if $data(cal) {
        do ..%foreignstatement.setTime(+paramIdx, value, cal)
    } else {
        do ..%foreignstatement.setTime(+paramIdx, value)
    }
}

/// throws SQLException
/// method SetTimestamp(paramIdx as %RawString, value As %TimeStamp) {}
Method SetTimestamp(paramIdx As %RawString, value As %TimeStamp, cal As %Net.Remote.Object)
{
    if $data(cal) {
        do ..%foreignstatement.setTimestamp(+paramIdx, value, cal)
    } else {
        do ..%foreignstatement.setTimestamp(+paramIdx, value)
    }
}

/// throws SQLException
/// method SetURL(paramIdx as %RawString, java.net.URL val) {}
Method SetURL(paramIdx As %RawString, value As %RawString)
{
    do ..%foreignstatement.setURL(+paramIdx, value)
}

}
