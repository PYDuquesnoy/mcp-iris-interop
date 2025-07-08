/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.Util.ValidateTableResults Extends %Persistent [ Final, Owner = {_SYSTEM} ]
{

Property RunId As %BigInt(MINVAL = 1) [ Required ];

Property ErrorId As %BigInt(MINVAL = 1) [ Required ];

Property RowId As %String(MAXLEN = 512) [ Required ];

Property Name As %String(MAXLEN = 512) [ Required ];

Property Error As %String(MAXLEN = 4096) [ Required ];

Index IDKey On (RunId, ErrorId) [ IdKey, PrimaryKey, Unique ];

Storage Default
{
<Data name="ValidateTableResultsDefaultData">
<Value name="1">
<Value>RowId</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Error</Value>
</Value>
</Data>
<DataLocation>^IRIS.ValidateTable</DataLocation>
<DefaultData>ValidateTableResultsDefaultData</DefaultData>
<IdLocation>^IRIS.ValidateTable</IdLocation>
<IndexLocation>^IRIS.ValidateTableI</IndexLocation>
<StreamLocation>^IRIS.ValidateTableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
