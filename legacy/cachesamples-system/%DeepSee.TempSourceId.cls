/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.TempSourceId Extends %Persistent
{

Index ID On (cubeName, chunk, sourceId) [ IdKey ];

/// Name of the cube that populated this record.
Property cubeName As %String;

/// The group this source ID belongs to.
Property chunk As %Integer;

/// Original ID from the source table.
Property sourceId As %String;

/// Update action performed on the record.
Property action As %Integer;

Storage Default
{
<Data name="TempSourceIdDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>action</Value>
</Value>
</Data>
<DataLocation>^IRIS.Temp.DeepSeeSourceId</DataLocation>
<DefaultData>TempSourceIdDefaultData</DefaultData>
<IdLocation>^IRIS.Temp.DeepSeeSourceId</IdLocation>
<IndexLocation>^IRIS.Temp.DeepSeeSourceIdI</IndexLocation>
<StreamLocation>^IRIS.Temp.DeepSeeSourceIdS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
