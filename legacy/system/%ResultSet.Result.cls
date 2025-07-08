/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// 	<b>This class has been superseded.</b> It will remain for compatibility with existing code and samples.
/// 	We recommend using <class>%SQL.Statement</class>.
/// </p>
/// Simple resultset object that does not contain any rows, but just contains the result information
Class %ResultSet.Result Extends %IResultSet [ System = 2 ]
{

Parameter COLUMNCOUNT = 0;

/// Returns the value of the column with the name <var>name</var> in the current row of the result set.
/// <p>If <var>name</var> is not a valid column name, this method returns an empty string.
Method %Get(colname As %String = "") As %Library.String [ CodeMode = expression ]
{
""
}

/// Returns the value of column <var>n</var> in the current row of the result set.
Method %GetData(colnbr As %Integer = 0) As %Library.String [ CodeMode = expression ]
{
""
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the 
/// result set.
Method %Next(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer [ CodeMode = expression ]
{
0
}

/// Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
Method %SendODBC() As %Library.Integer [ CodeMode = expression ]
{
..%SQLCODE
}

Method %OnNew(SQLCode As %Integer = 0, Message As %String(MAXLEN=256) = "", RowCount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..%Metadata=$listbuild(0)
	Set ..%SQLCODE=SQLCode,..%Message=Message,..%ROWCOUNT=RowCount
	Quit $$$OK
}

ClassMethod %Prepare(queryId As %String(MAXLEN=""), ByRef %returnError As %SYSTEM.Error, %importPackages As %RawString = "", %args...) As %Library.IResultSet
{
	Quit $$$OK
}

/// Display the contents of this object on the current device
Method %Display(pDelimiter As %String = {$Char(9)}) As %Library.Status
{
	if ..%SQLCODE < 0 {
		write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
		if ..%Message'="" { write "[%msg: <",..%Message,">]" }
	}
	write ..%ROWCOUNT," Row"_$Select(..%ROWCOUNT'=1:"s",1:"")_" Affected"
	quit $$$OK
}

}
