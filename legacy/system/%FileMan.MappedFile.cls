/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class stored information about the mapping of a FileMan file to a class
/// A FileMan file may be mapped to one or more packages at a time
/// The user may have run FM2Class for a file in one package, then ran it again with another package name to make a copy of it in another package
/// Sometimes these mappings may have been performed by different versions of FM2Class.
/// <p>Note: The FileMan toolset is available and fully supported in InterSystems IRIS for existing FileMan users.
/// InterSystems recommends against starting new development projects using FileMan.</p>
Class %FileMan.MappedFile Extends %Persistent [ Deprecated, Final, Owner = {_SYSTEM}, SqlRowIdPrivate, System = 4 ]
{

/// The FileMan File name
Property FileName As %Library.String(MAXLEN = 45) [ Required ];

/// The FileMan File number
Property FileNumber As %Library.String [ Required ];

Index IDKeyIndex On FileNumber [ IdKey, PrimaryKey, Unique ];

/// Each file may be mapped to 1 or more packages
Relationship MappedFilePackage As %FileMan.MappedFilePackage [ Cardinality = children, Inverse = FileNumber ];

Storage Default
{
<CounterLocation>^oddFMC</CounterLocation>
<Data name="MappedFileDefaultData">
<Value name="1">
<Value>FileName</Value>
</Value>
<Value name="2">
<Value>Classname</Value>
</Value>
<Value name="3">
<Value>Tablename</Value>
</Value>
<Value name="4">
<Value>MapTimestamp</Value>
</Value>
<Value name="5">
<Value>SOCClasses</Value>
</Value>
<Value name="6">
<Value>Indices</Value>
</Value>
<Value name="7">
<Value>FKeys</Value>
</Value>
<Value name="8">
<Value>Maps</Value>
</Value>
<Value name="9">
<Value>Triggers</Value>
</Value>
</Data>
<DataLocation>^oddFMD</DataLocation>
<DefaultData>MappedFileDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^oddFMD</IdLocation>
<IndexLocation>^oddFMI</IndexLocation>
<StreamLocation>^%FileMan.MappedFileS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
