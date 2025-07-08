/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a null character stream, so although you can write to it the length will always be
/// zero bytes.
Class %Stream.NullCharacter Extends %AbstractStream [ ClientDataType = CHARACTERSTREAM, OdbcType = LONGVARCHAR, Not ProcedureBlock, System = 3 ]
{

Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %String
{
	Set len=-1,sc=$$$OK
	Quit ""
}

Method WriteLine(data As %String = "") As %Status [ CodeMode = expression ]
{
$$$OK
}

Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean) As %String
{
	Set len=-1,sc=$$$OK,eol=0
	Quit ""
}

Method Write(data As %String = "") As %Status [ CodeMode = expression ]
{
$$$OK
}

Method MoveToEnd() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method SizeGet() As %Integer [ CodeMode = expression ]
{
0
}

Method LineTerminatorGet() As %String [ CodeMode = expression ]
{
$char(13,10)
}

Method LineTerminatorSet(terminator As %String) As %Status
{
	Quit $$$OK
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
