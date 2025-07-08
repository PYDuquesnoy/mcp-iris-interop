/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Index for all the routines in this namespace. Using this index avoids the overhead of loading
/// all the information from ^ROUTINE, ^rMAC, ^rINC which makes the routine editing tool substantially
/// faster. In case you have tools that enter routines directly into the global and you wish to add
/// this routine to the index then after you have edited the global you should call:
/// <example>
/// Do RebuildItemIndex^%R(Name,Type)
/// </example>
/// The global structure is:<p>
/// <p>
/// ^rINDEX(<b>Name</b>,<b>Type</b>)=$ListBuild(<b>Modified</b>,<b>Length</b>)<p>
/// <p>
/// Where:<p><ul>
/// 
/// <li><b>Type</b> - is one of "MAC","INT","BAS","MVB","INC","OBJ"</li>
/// <li><b>Name</b> - is the name of this item, eg routine '%qserver' for classes this is the upper case version.</li>
/// <li><b>Modified</b> - is the last date/time the routine was modified in $zdt($h,3) format</li>
/// <li><b>Length</b> - is the size in bytes</li>
/// </ul>
Class %Library.RoutineIndex Extends %Persistent [ Not ProcedureBlock, System = 3 ]
{

/// The date/time that this routine was last saved.
Property Modified As %TimeStamp;

/// The size in bytes of this routine.
Property Length As %Integer;

/// The type of routine, this will be one of:
/// <ul><li><b>MAC</b> - Macro routine, content is stored in ^rMAC global</li>
/// <li><b>INT</b> - ObjectScript routine, content is stored in ^ROUTINE global</li>
/// <li><b>INC</b> - Include file, these may be included from a MAC routine, content
/// is stored in ^rINC</li>
/// <li><b>BAS</b> - Cache Basic routine, content is stored in the ^ROUTINE global</li>
/// <li><b>MVB</b> - MultiValue Basic routine, content is stored in the ^ROUTINE global</li>
/// <li><b>OBJ</b> - Object code, content is stored in ^rOBJ global</li>
/// </ul>
Property Type As %String [ Required ];

/// The name of the routine.
Property Name As %String(MAXLEN = 128) [ Required ];

Index Index On (Name, Type) [ IdKey ];

/// In case this index gets out of sync with the routines in the current namespace
/// you can call this method to rebuild the index from the various ^ROUTINE, ^rINC,
/// ^rMAC globals. This only rebuilds the index for entries that really live in
/// this namespace, if you have routine mappings so that some routines are in a
/// separate namespace you will need to rebuilt these seperately.
ClassMethod RebuildIndex(namespace As %String, ByRef num As %Integer) As %Status
{
 New rc
 Set rc=$$RebuildIndex^%SYS.SECURITY(.namespace,.num)
 If rc=1 Quit $$$OK
 Quit $$$ERROR($$$GeneralError,$Piece(rc,"^",2,*))
}

/// Rebuild the index information for this single item. You pass this the
/// <var>rtn</var> name, its <var>ext</var> (one of "INT", "INC", "MAC", "BAS", "MVB", "OBJ")
/// and optionally the namespace as <var>namespace</var>.
/// You can call this after modifying the routine global directly to update the
/// index correct with the new information.
ClassMethod RebuildItemIndex(rtn As %String, ext As %String, namespace As %String) As %Status
{
 New rc
 Set rc=$$RebuildItemIndex^%R(.rtn,.ext,.namespace)
 If rc=1 Quit $$$OK
 Quit $$$ERROR($$$GeneralError,$Piece(rc,"^",2,*))
}

Storage Default
{
<Data name="RoutineIndexDefaultData">
<Value name="1">
<Value>Modified</Value>
</Value>
<Value name="2">
<Value>Length</Value>
</Value>
<Value name="3">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^rINDEX</DataLocation>
<DefaultData>RoutineIndexDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^rINDEX</IdLocation>
<IndexLocation>^%Library.RoutineIndexI</IndexLocation>
<StreamLocation>^%Library.RoutineIndexS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
