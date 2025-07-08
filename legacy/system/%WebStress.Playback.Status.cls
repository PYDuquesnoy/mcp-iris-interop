/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Playback.Status Extends (%Persistent, %XML.Adaptor) [ Owner = {%Developer}, System = 4 ]
{

/// Status of this process
Property Status As %Integer;

/// Description of the current status
Property StatusText As %String;

/// The process ID
Property ProcessID As %String;

Property TestID As %Integer;

Property RunID As %Integer;

Property Script As %String;

Property SystemID As %String(MAXLEN = "");

Index Main On (SystemID, ProcessID) [ IdKey, PrimaryKey, Unique ];

Storage Default
{
<Data name="StatusDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Status</Value>
</Value>
<Value name="3">
<Value>StatusText</Value>
</Value>
<Value name="4">
<Value>TestID</Value>
</Value>
<Value name="5">
<Value>RunID</Value>
</Value>
<Value name="6">
<Value>Script</Value>
</Value>
</Data>
<DataLocation>^WebStress.Playback.StatusD</DataLocation>
<DefaultData>StatusDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Playback.StatusD</IdLocation>
<IndexLocation>^WebStress.Playback.StatusI</IndexLocation>
<StreamLocation>^WebStress.Playback.StatusS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
