/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a null binary stream, so although you can write to it the length will always be
/// zero bytes.
Class %Stream.NullBinary Extends %AbstractStream [ ClientDataType = BINARYSTREAM, OdbcType = LONGVARBINARY, Not ProcedureBlock, System = 3 ]
{

Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %Binary
{
	Set len=-1,sc=$$$OK
	Quit ""
}

Method Write(data As %Binary = "") As %Status [ CodeMode = expression ]
{
$$$OK
}

Method WriteLine(data As %Binary = "") As %Status [ CodeMode = expression ]
{
$$$OK
}

Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean) As %Binary
{
	Set len=-1,sc=$$$OK,eol=0
	Quit ""
}

Method MoveToEnd() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method SizeGet() As %Integer [ CodeMode = expression ]
{
0
}

Method IsNull() As %Boolean [ CodeMode = expression ]
{
1
}

Method SaveStream() As %Status [ CodeMode = expression ]
{
$$$OK
}

}
