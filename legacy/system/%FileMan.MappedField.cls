/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class stored information about the mapping of a FileMan field to a property
/// <p>Note: The FileMan toolset is available and fully supported in InterSystems IRIS for existing FileMan users.
/// InterSystems recommends against starting new development projects using FileMan.</p>
Class %FileMan.MappedField Extends %Persistent [ Deprecated, Final, Owner = {_SYSTEM}, SqlRowIdPrivate, System = 4 ]
{

/// The FileMan Field name
Property FMFieldName As %RawString [ Required ];

/// The FileMan Field number
Property FieldNumber As %RawString [ Required ];

/// The Property name the field maps to
Property PropertyName As %RawString [ Required ];

/// The Sql Field name the field maps to
Property SqlFieldName As %RawString [ Required ];

/// Datatype the field mapped to
Property Datatype As %RawString [ Required ];

Index IDKeyIndex On FieldNumber [ IdKey, PrimaryKey, Unique ];

Relationship MappedFilePackage As %FileMan.MappedFilePackage [ Cardinality = parent, Inverse = MappedFields ];

Storage Default
{
<Data name="MappedFieldDefaultData">
<Value name="1">
<Value>FMFieldName</Value>
</Value>
<Value name="2">
<Value>PropertyName</Value>
</Value>
<Value name="3">
<Value>SqlFieldName</Value>
</Value>
<Value name="4">
<Value>Datatype</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("f")</DataLocation>
<DefaultData>MappedFieldDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^oddFMD("f")</IdLocation>
<IndexLocation>^oddFMDI</IndexLocation>
<StreamLocation>^oddFMDS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
