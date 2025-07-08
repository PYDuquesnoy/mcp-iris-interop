/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.LG.JavaIndexDef Extends %SerialObject [ System = 4 ]
{

Property Condition As %RawString;

Property Data As %RawString;

Property Description As %RawString;

Property Extent As %Boolean [ InitialExpression = 0 ];

Property IdKey As %Boolean [ InitialExpression = 0 ];

Property Internal As %Boolean [ InitialExpression = 0 ];

Property Name As %String(MAXLEN = 512);

Property Parameters As array Of %RawString;

Property PrimaryKey As %Boolean [ InitialExpression = 0 ];

Property Properties As %RawString;

Property SequenceNumber As %Integer [ InitialExpression = 0 ];

Property SqlName As %RawString;

Property Type As %RawString;

Property Unique As %Boolean [ InitialExpression = 0, SqlFieldName = _Unique ];

Property ObjectName As %RawString;

Property Runnable As %Integer [ InitialExpression = 0 ];

Property IndexColumns As %List;

Property ColumnNumberList As list Of %Integer;

Storage Default
{
<Data name="JavaIndexDefState">
<Value name="1">
<Value>ColumnList</Value>
</Value>
<Value name="2">
<Value>Condition</Value>
</Value>
<Value name="3">
<Value>ConstraintFields</Value>
</Value>
<Value name="4">
<Value>Data</Value>
</Value>
<Value name="5">
<Value>Description</Value>
</Value>
<Value name="6">
<Value>Extent</Value>
</Value>
<Value name="7">
<Value>IdKey</Value>
</Value>
<Value name="8">
<Value>Internal</Value>
</Value>
<Value name="9">
<Value>Name</Value>
</Value>
<Value name="10">
<Value>ObjectName</Value>
</Value>
<Value name="11">
<Value>Parameters</Value>
</Value>
<Value name="12">
<Value>PrimaryKey</Value>
</Value>
<Value name="13">
<Value>Properties</Value>
</Value>
<Value name="14">
<Value>Runnable</Value>
</Value>
<Value name="15">
<Value>SequenceNumber</Value>
</Value>
<Value name="16">
<Value>SqlName</Value>
</Value>
<Value name="17">
<Value>Type</Value>
</Value>
<Value name="18">
<Value>Unique</Value>
</Value>
<Value name="19">
<Value>IndexColumns</Value>
</Value>
<Value name="20">
<Value>ColumnNumberList</Value>
</Value>
</Data>
<State>JavaIndexDefState</State>
<StreamLocation>^%Compiler.LG.JavaIndexDefS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
