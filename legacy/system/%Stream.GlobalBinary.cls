/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Stream.GlobalBinary">Working with Streams</a>.</p>
/// Stream class that stores binary data in global nodes.
/// Note that although you can write unicode data into this class and read
/// it back out, this is not a supported use of this class and the Size property would be incorrect
/// in this case because it would be the size in characters rather than the size in bytes.
Class %Stream.GlobalBinary Extends %Stream.GlobalCharacter [ ClientDataType = BINARYSTREAM, OdbcType = LONGVARBINARY, System = 2 ]
{

Storage Default
{
<Data name="GlobalBinaryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%Stream.GlobalBinaryD</DataLocation>
<DefaultData>GlobalBinaryDefaultData</DefaultData>
<IdLocation>^%Stream.GlobalBinaryD</IdLocation>
<IndexLocation>^%Stream.GlobalBinaryI</IndexLocation>
<StreamLocation>^%Stream.GlobalBinaryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
