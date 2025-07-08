/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syJrninc

/// Journal BITSET record related API
Class %SYS.Journal.BitSetRecord Extends %SYS.Journal.SetKillRecord [ System = 4 ]
{

Parameter READONLY = 1;

/// Bit position of the BITSET
Property Position As %Integer [ Calculated ];

/// The length of the bit string prior to the BITSET
Property OldLength As %Integer [ Calculated ];

Method %LoadData(Offset As %String, flag As %Boolean) As %Status [ Private ]
{
	q ##super(Offset,$g(flag))
}

Method NewValueGet() As %String
{
	q $$$JRNNEWBITVAL(i%Address)
}

Method OldValueGet() As %String [ CodeMode = expression ]
{
$$$JRNOLDBITVAL(i%Address)
}

Method PositionGet() As %Integer
{
	q $$$JRNBITPOS(i%Address)
}

Method OldLengthGet() As %Integer
{
	q $$$JRNOLDBITLEN(i%Address)
}

Method Fetch(ByRef Row As %List, ByRef Columns As %String, Match As %List = "") As %Boolean [ Internal, PublicList = (col, match, Row, Columns) ]
{
	q ##super(.Row,.Columns,Match)
}

Storage JournalRecordStorage
{
<Type>%Library.CustomStorage</Type>
}

}
