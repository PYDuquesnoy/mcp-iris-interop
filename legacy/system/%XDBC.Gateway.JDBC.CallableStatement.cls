/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The interface used to execute SQL stored procedures.  The JDBC API
/// provides a stored procedure SQL escape syntax that allows stored procedures
/// to be called in a standard way for all RDBMSs. This escape syntax has one
/// form that includes a result parameter and one that does not. If used, the result
/// parameter must be registered as an OUT parameter. The other parameters
/// can be used for input, output or both. Parameters are referred to
/// sequentially, by number, with the first parameter being 1.
/// <PRE>
///   {?= call &lt;procedure-name&gt;[(&lt;arg1&gt;,&lt;arg2&gt;, ...)]}
///   {call &lt;procedure-name&gt;[(&lt;arg1&gt;,&lt;arg2&gt;, ...)]}
/// </PRE>
/// <P>
/// IN parameter values are set using the <code>set</code> methods inherited from
/// {@link PreparedStatement}.  The type of all OUT parameters must be
/// registered prior to executing the stored procedure; their values
/// are retrieved after execution via the <code>get</code> methods provided here.
/// <P>
/// A <code>CallableStatement</code> can return one {@link ResultSet} object or
/// multiple <code>ResultSet</code> objects.  Multiple
/// <code>ResultSet</code> objects are handled using operations
/// inherited from {@link Statement}.
/// <P>
/// For maximum portability, a call's <code>ResultSet</code> objects and
/// update counts should be processed prior to getting the values of output
/// parameters.
/// @see Connection#prepareCall
/// @see ResultSet
Class %XDBC.Gateway.JDBC.CallableStatement Extends %XDBC.Gateway.JDBC.PreparedStatement [ System = 4 ]
{

/// throws SQLException
Method GetArray(paramIdxOrName As %RawString) As %Library.DynamicArray
{
    set javaValue = ..%foreignstatement.getArray($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetBlob(paramIdxOrName As %RawString) As %Stream.Object
{
    set javaValue = ..%foreignstatement.getBlob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException;
Method GetBoolean(paramIdxOrName As %RawString) As %Boolean
{
    set javaValue = ..%foreignstatement.getBoolean($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException;
Method GetByte(paramIdxOrName As %RawString) As %Integer
{
    set javaValue = ..%foreignstatement.getByte($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetBytes(paramIdxOrName As %RawString) As %RawString
{
    set javaValue = ..%foreignstatement.getBytes($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetBigDecimal(paramIdxOrName As %RawString) As %Decimal
{
    set javaValue = ..%foreignstatement.GetBigDecimal($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

Method GetCharacterStream(paramIdxOrName As %RawString) As %Stream.Object
{
    set javaValue = ..%foreignstatement.getCharacterStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

Method GetClob(paramIdxOrName As %RawString) As %Stream.Object
{
    set javaValue = ..%foreignstatement.getClob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetDate(paramIdxOrName As %RawString) As %Date
{
    set javaValue = ..%foreignstatement.getDate($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetDouble(paramIdxOrName As %RawString) As %Double
{
    set javaValue = ..%foreignstatement.getDouble($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException;
Method GetFloat(paramIdxOrName As %RawString) As %Float
{
    set javaValue = ..%foreignstatement.getFloat($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException;
Method getInt(paramIdxOrName As %RawString) As %Integer
{
    set javaValue = ..%foreignstatement.getInt($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException;
Method GetLong(paramIdxOrName As %RawString) As %Integer
{
    set javaValue = ..%foreignstatement.getLong($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

Method GetNCharacterStream(paramIdxOrName As %RawString) As %Stream.Object
{
    set javaValue = ..%foreignstatement.getNCharacterStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

Method GetNClob(paramIdxOrName As %RawString) As %Stream.Object
{
    set javaValue = ..%foreignstatement.getNClob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

Method GetNString(paramIdxOrName As %RawString) As %String
{
    set javaValue = ..%foreignstatement.getNString($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
/// method GetObject(paramIdxOrName as %RawString, map as %Library.DynamicObject) as %Net.Remote.Object {}
/// method GetObject(paramIndex as %RawString, type as %String) as %Net.Remote.Object {}
Method GetObject(paramIdxOrName As %RawString, mapOrType As %Library.RawString) As %Net.Remote.Object
{
    if '$data(mapOrType) {
        set javaValue = ..%foreignstatement.getObject($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    } elseif $isobject(mapOrType) {
        set javaValue = ..%foreignstatement.getObject($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    } else {
        set javaValue = ..%foreignstatement.getObject($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), mapOrType)
    }
    return javaValue
}

/// throws SQLException;
Method getShort(paramIdxOrName As %RawString) As %SmallInt
{
    set javaValue = ..%foreignstatement.getShort($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException;
Method getString(paramIdxOrName As %RawString) As %String
{
    set javaValue = ..%foreignstatement.getString($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetTime(paramIdxOrName As %RawString) As %Time
{
    set javaValue = ..%foreignstatement.getTime($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetTimestamp(paramIdxOrName As %RawString) As %TimeStamp
{
    set javaValue = ..%foreignstatement.getTimestamp($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
Method GetURL(paramIdxOrName As %RawString) As %Net.Remote.Object
{
    set javaValue = ..%foreignstatement.getURL($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName))
    return javaValue
}

/// throws SQLException
/// method registerOutParameter(paramIdxOrName as %RawString, sqlType as %Integer)
/// method registerOutParameter(paramIdxOrName as %RawString, sqlType as %Integer, scale as %Integer)
/// method registerOutParameter (paramIdxOrName as %RawString, sqlType as %Integer, String typeName)
/// throws SQLException;
/// method registerOutParameter(paramIndex as %RawString, sqlType as %Integer)
/// method registerOutParameter(paramIndex as %RawString, sqlType as %Integer, scale as %Integer) {}
Method registerOutParameter(paramIdxOrName As %RawString, sqlType As %Integer, typeName As %String)
{
}

/// method SetAsciiStream(paramIdxOrName as %RawString, value As %Stream.Object) {}
Method SetAsciiStream(paramIdxOrName As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setAsciiStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
    } else {
        do ..%foreignstatement.setAsciiStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

Method SetBigDecimal(paramIdxOrName As %RawString, value As %Decimal)
{
    do ..%foreignstatement.setBigDecimal($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
}

Method SetBinaryStream(paramIdxOrName As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setBinaryStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
    } else {
        do ..%foreignstatement.setBinaryStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

Method SetBlob(paramIdxOrName As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setBlob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
    } else {
        do ..%foreignstatement.setBlob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

Method SetBoolean(paramIdxOrName As %RawString, value As %Boolean)
{
    do ..%foreignstatement.setBoolean($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetByte(paramIdxOrName As %RawString, value As %SmallInt)
{
    do ..%foreignstatement.setByte($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetBytes(paramIdxOrName As %RawString, value As %RawString)
{
    do ..%foreignstatement.setBytes($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetCharacterStream(paramIdxOrName As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setCharacterStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
    } else {
        do ..%foreignstatement.setCharacterStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

Method SetClob(paramIdxOrName As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setClob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
    } else {
        do ..%foreignstatement.setClob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

Method SetDate(paramIdxOrName As %RawString, value As %Date, cal As %Net.Remote.Object)
{
    if $data(cal) {
        do ..%foreignstatement.setDate($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, cal)
    } else {
        do ..%foreignstatement.setDate($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

Method SetDouble(paramIdxOrName As %RawString, value As %Float)
{
    do ..%foreignstatement.setDouble($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetFloat(paramIdxOrName As %RawString, value As %Float)
{
    do ..%foreignstatement.setFloat($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetInt(paramIdxOrName As %RawString, value As %Integer)
{
    do ..%foreignstatement.setInt($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetLong(paramIdxOrName As %RawString, value As %Integer)
{
    do ..%foreignstatement.setLong($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

/// method SetNCharacterStream(paramIdxOrName as %RawString, value as %Stream.Object) {}
Method SetNCharacterStream(paramIdxOrName As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setNCharacterStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
    } else {
        do ..%foreignstatement.setNCharacterStream($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

/// method SetNClob(paramIdxOrName as %RawString, value As %Stream.Object) {}
/// method SetNClob(paramIdxOrName as %RawString, value as %Stream.Object) {}
Method SetNClob(paramIdxOrName As %RawString, value As %Stream.Object, length As %Integer)
{
    if $data(length) {
        do ..%foreignstatement.setNClob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, +length)
    } else {
        do ..%foreignstatement.setNClob($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

Method SetNString(paramIdxOrName As %RawString, value As %String)
{
    do ..%foreignstatement.setNString($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

/// throws SQLException
/// method SetNull(paramIdxOrName as %RawString, sqlType as %Integer) {}
Method SetNull(paramIdxOrName As %RawString, sqlType As %Integer, typeName As %String)
{
    if $data(typeName) {
        do ..%foreignstatement.setNull($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), sqlType, typeName)
    } else {
        do ..%foreignstatement.setNull($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), sqlType)
    }
}

/// method SetObject(paramIdxOrName as %RawString, value As %ObjectHandle, targetSqlType as %Integer) {}
/// method SetObject(paramIdxOrName as %RawString, x) {}
Method SetObject(paramIdxOrName As %RawString, value As %ObjectHandle, targetSqlType As %Integer, scale As %Integer)
{
    if $isobject(targetSqlType) && $data(scale) {
        do ..%foreignstatement.setObject($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, targetSqlType, scale)
        return
    }
    do ..%foreignstatement.setObject($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, targetSqlType)
}

Method SetShort(paramIdxOrName As %RawString, value As %SmallInt)
{
    do ..%foreignstatement.setShort($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetString(paramIdxOrName As %RawString, value As %String)
{
    do ..%foreignstatement.setString($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

Method SetTime(paramIdxOrName As %RawString, value As %Time, cal As %Net.Remote.Object)
{
    if $data(cal) {
        do ..%foreignstatement.setTime($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, cal)
    } else {
        do ..%foreignstatement.setTime($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

/// throws SQLException
/// method SetTimestamp(paramIdxOrName as %RawString, value As %TimeStamp) {}
Method SetTimestamp(paramIdxOrName As %RawString, value As %TimeStamp, cal As %Net.Remote.Object)
{
    if $data(cal) {
        do ..%foreignstatement.setTimestamp($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value, cal)
    } else {
        do ..%foreignstatement.setTimestamp($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
    }
}

/// throws SQLException
/// method SetURL(paramIdxOrName as %RawString, java.net.URL val) {}
Method SetURL(paramIdxOrName As %RawString, value As %RawString)
{
    do ..%foreignstatement.setURL($select(paramIdxOrName=(+paramIdxOrName\1):+paramIdxOrName,1:paramIdxOrName), value)
}

/// throws SQLException;
Method wasNull() As %Boolean
{
    return ..%foreignstatement.wasNull()
}

}
