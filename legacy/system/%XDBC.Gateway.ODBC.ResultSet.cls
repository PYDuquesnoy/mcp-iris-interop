/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %XDBC.Gateway.ODBC.ResultSet Extends %XDBC.Gateway.ResultSet [ System = 4 ]
{

Property statement As %XDBC.Gateway.ODBC.Statement;

Property atEnd As %Integer;

Method %OnNew(st As %XDBC.Gateway.ODBC.Statement) As %Status [ Internal, ServerOnly = 1 ]
{
	set ..statement = st,
		..atEnd = 0
	
    // DP-427293 - initialize internal metadata representation
	do ..%InitializeMetadata(##class(%XDBC.Gateway.ResultSetMetaData).%New(st.statement.GetMetadata()))
	
	return $$$OK
}

/// Advance to the next row in the result set. Returns 0 if the cursor is at the end of the result set. 
Method Next() As %Library.Boolean
{
	if (1 = ..atEnd) {
		return 0
	}
	
	set rc = ..statement.statement.Fetch()
	if ( 0 = rc) {
		return 1
	} else {
		set ..atEnd = 1
		return 0
	}
}

///  Returns the value of the column with the name <var>colname</var> in the current row of the result set.
///  <p>If <var>colname</var> is not a valid column name, this method throws a <Column not found> error.
Method Get(colname As %RawString = "") As %Library.RawString
{
	if (colname = +colname) {
		set index = +colname
	}
	else {
		set index = -1
		set n = ..%rsmd.GetColumnCount()
		for indx = 1:1:n {
			if ($zcvt(colname,"U") = $zcvt(..%rsmd.GetColumnName(indx),"U")) {
				 set index = indx
				 quit
			}
		}
		if (-1 = index) {
		    throw ##class(%Exception.SQL).CreateFromSQLCODE(400,"Column not found")
		}
	}
	set ret = ..statement.statement.GetData(index)
	return ret
}

Method GetData(colindex As %Integer) As %Library.RawString
{
	return ..Get(colindex) ; no reason to pack in $list for GetRow() and then unpack
}

/// Display all rows
Method Display(pDelimiter As %String = " ") As %Status [ Internal ]
{
	do ..Next()
	while (0 = ..atEnd)
	{
		set str = ""
		set n = ..%rsmd.GetColumnCount()
		for indx = 1:1:n {
			if (indx > 1) {
				s str = str_pDelimiter
			}
			s data = ..statement.statement.GetData(indx)
			s str = str _ data
		}  
		
		do ..Next()

		W !,str
	
	}
	return $$$OK
}

/// Advance to the next row in the result set. Returns 0 if the cursor is at the end of the result set. 
/// The row is returned in $List format by reference in the <parameter>Row</parameter> argument.  
Method GetRow() As %Library.List
{
	set n = ..%rsmd.GetColumnCount()
	set indx = ""
	for i = 1:1:n {
		set indx = indx_$lb(i)
	}

	s data = ..statement.statement.GetDataEx(indx)
	return data
}

/// Method Not Supported
Method GetRows(rowCount As %Library.Integer) As %Library.Integer
{
	// not implemented in jdbc
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method GetObject(columnIndex As %Integer) As %ObjectHandle
{
	// not implemented in jdbc
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method WasNull() As %Boolean
{
	// not implemented in jdbc
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method %FetchIntoTemp() As %Library.Integer [ Abstract, Internal ]
{
	// not implemented in jdbc
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method %SendDelimitedRows(pMaxRows As %Integer = 0, pDelimiter As %String = "", ByRef pReturnCount As %Integer = 0) As %Status [ Abstract, Internal ]
{
	// not implemented in jdbc
	throw ##class(%Exception.General).%New("Method Not Supported")
}

Method GetFetchSize() As %Integer
{
	// MJG259 after talking with DmitryU this is a no-op for ODBC
	RETURN 1
	//return ..statement.GetFetchSize()
}

Method Close() As %Status
{
	return ..statement.Close()
}

Method SetFetchSize(rows As %Integer)
{
	// MJG259 after talking with DmitryU this is a no-op for ODBC
	RETURN
	// do ..statement.SetFetchSize(rows)
}

}
