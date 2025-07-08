/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a specific watchpoint for a Studio Project.
Class %Studio.WatchPoint Extends (%Persistent, %XML.Adaptor) [ System = 3 ]
{

Index NameIdx On Variable [ IdKey ];

Relationship Project As Project [ Cardinality = parent, Inverse = WatchPoints ];

Property Condition As %String(MAXLEN = 256, XMLPROJECTION = "attribute");

Property Variable As %String(MAXLEN = 64, XMLPROJECTION = "attribute");

Storage Default
{
<Data name="Data">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Condition</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("WP")</DataLocation>
<DefaultData>Data</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%Studio.ProjectC("WatchPoints")</IdLocation>
<IndexLocation>^%Studio.WatchPointI</IndexLocation>
<StreamLocation>^%Studio.WatchPointS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
