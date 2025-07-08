/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: The FileMan toolset is available and fully supported in InterSystems IRIS for existing FileMan users.
/// InterSystems recommends against starting new development projects using FileMan.</p>
Class %FileMan.MappedFilePackage Extends %Persistent [ Deprecated, Final, Owner = {_SYSTEM}, SqlRowIdPrivate, System = 4 ]
{

Relationship FileNumber As %FileMan.MappedFile [ Cardinality = parent, Inverse = MappedFilePackage ];

Relationship MappedFields As %FileMan.MappedField [ Cardinality = children, Inverse = MappedFilePackage ];

Index IDKeyIndex On Package [ IdKey, PrimaryKey, Unique ];

Index Cls On Classname;

/// Timestamp of when the current version of this class was mapped from the file
Property MappedTimestamp As %Library.TimeStamp;

/// Name of the package the file is mapped to
/// A File may be mapped to 1 or more packages at the same time
Property Package As %RawString [ Required ];

/// Name of the class the file is mapped to
Property Classname As %RawString [ Required ];

/// Name of the table the file is mapped to
Property Tablename As %RawString [ Required ];

Property SOCClasses As list Of %Library.String(MAXLEN = 128);

Property Indices As list Of %Library.String(MAXLEN = 128);

Property FKeys As list Of %Library.String(MAXLEN = 128);

Property Maps As list Of %Library.String(MAXLEN = 128);

Property Triggers As list Of %Library.String(MAXLEN = 128);

/// Version of the FM2CLass utility that mapped this class
Property FM2ClassVersion As %Library.String;

Storage Default
{
<Data name="MappedFilePackageDefaultData">
<Value name="1">
<Value>Classname</Value>
</Value>
<Value name="2">
<Value>Tablename</Value>
</Value>
<Value name="3">
<Value>MappedTimestamp</Value>
</Value>
<Value name="4">
<Value>SOCClasses</Value>
</Value>
<Value name="5">
<Value>Indices</Value>
</Value>
<Value name="6">
<Value>FKeys</Value>
</Value>
<Value name="7">
<Value>Maps</Value>
</Value>
<Value name="8">
<Value>Triggers</Value>
</Value>
<Value name="9">
<Value>FM2ClassVersion</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("p")</DataLocation>
<DefaultData>MappedFilePackageDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^oddFMC("MappedFilePackage")</IdLocation>
<IndexLocation>^oddFMI</IndexLocation>
<StreamLocation>^oddFMS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
