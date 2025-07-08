/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %XDBC.Gateway.ODBC.PreparedStatement Extends %XDBC.Gateway.ODBC.Statement [ System = 4 ]
{

///     void setString(int parameterIndex, String x)
Method SetString(paramIdx As %RawString, value As %String)
{
	if ($ZISWIDE(value)){
	    set rc = ..statement.statement.BindParameter(+paramIdx,1,-8,-8,-3,0,value, $l(value))
	} else {
	    set rc = ..statement.statement.BindParameter(+paramIdx,1,1,1,-3,0,value, $l(value))

	}
    if (0 '= rc) {
	    throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Can not set parameter "_+paramIdx)
    }
}

///     void setString(int parameterIndex, String x, int len)
Method SetStringLen(paramIdx As %RawString, value As %String, len As %Integer)
{
	if ($ZISWIDE(value)){
	    set rc = ..statement.statement.BindParameter(+paramIdx,1,-8,-8,-3,0,value, len)
	} else {
	    set rc = ..statement.statement.BindParameter(+paramIdx,1,1,1,-3,0,value, len)

	}
    if (0 '= rc) {
	    throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Can not set parameter "_+paramIdx)
    }
}

Method SetBigDecimal(paramIdx As %RawString, value As %Decimal)
{
    set rc = ..statement.statement.BindParameter(+paramIdx,1,1,3,-3,0,value, $l(value))
    if (0 '= rc) {
	    throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Can not set parameter "_+paramIdx)
    }
}

Method SetAsciiString(paramIdx As %RawString, value As %String)
{
    set rc = ..statement.statement.BindParameter(+paramIdx,1,1,1,-3,0,value, $l(value))
    if (0 '= rc) {
	    throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Can not set parameter "_+paramIdx)
    }
}

Method SetBoolean(paramIdx As %RawString, value As %Boolean)
{
	do ..SetAsciiString(paramIdx, value)
}

Method SetByte(paramIdx As %RawString, value As %SmallInt)
{
	do ..SetAsciiString(paramIdx, value)
}

Method SetBytes(paramIdx As %RawString, value As %RawString)
{
	do ..SetAsciiString(paramIdx, value)
}

Method SetDate(paramIdx As %RawString, value As %Date)
{
	do ..SetAsciiString(paramIdx, value)
}

/// void setDouble(int parameterIndex, double x)
Method SetDouble(paramIdx As %RawString, value As %Float)
{
    set rc = ..statement.statement.BindParameter(+paramIdx,1,8,8,38,0,value, 8)
    if (0 '= rc) {
	    throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Can not set parameter "_+paramIdx)
    }
}

/// void setInt(int parameterIndex, int x)
Method SetInt(paramIdx As %RawString, value As %Integer)
{
	set rc = ..statement.statement.BindParameter(+paramIdx,1,4,4,38,0,value, $l(value))
    if (0 '= rc) {
	    throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Can not set parameter "_+paramIdx)
    }
}

Method SetFloat(paramIdx As %RawString, value As %Float)
{
	do ..SetDouble(paramIdx, value)
}

Method SetLong(paramIdx As %RawString, value As %Integer)
{
	do ..SetInt(paramIdx, value)
}

Method SetShort(paramIdx As %RawString, value As %SmallInt)
{
	set rc = ..statement.statement.BindParameter(+paramIdx,1,5,5,38,0,value, 2)
    if (0 '= rc) {
	    throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Can not set parameter "_+paramIdx)
    }
}

Method SetTime(paramIdx As %RawString, value As %Time)
{
	do ..SetAsciiString(paramIdx, value)
}

/// method SetTimestamp(paramIdx as %RawString, value As %TimeStamp) {}
Method SetTimestamp(paramIdx As %RawString, value As %TimeStamp)
{
	do ..SetAsciiString(paramIdx, value)
}

/// Specify is Status array for column binding should be produced by Execute Batch
/// This call should be followed by Prepare(...) that pass parameter array in $List format
Method AddBatchEx(size As %Integer, statusArray As %Boolean)
{
	set rc = ..statement.statement.BindingArrayParams(0, size, statusArray) 
	if (0 '= rc) {
		throw ##class(%Exception.SQL).CreateFromSQLCODE(rc,"Error BindingArrayParams  ")	
	}
}

/// Submits a batch of commands to the database for execution and if all commands execute successfully, returns an array of update counts
Method ExecuteBatchEx() As %List
{
	return ..statement.statement.ExecuteBatch()
}

}
