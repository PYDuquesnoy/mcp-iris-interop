/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a specific breakpoint for a Studio Project.
Class %Studio.BreakPoint Extends (%Persistent, %XML.Adaptor) [ System = 3 ]
{

Index NameIdx On (Routine, Offset) [ IdKey ];

Relationship Project As Project [ Cardinality = parent, Inverse = BreakPoints ];

Property Condition As %String(MAXLEN = 256, XMLPROJECTION = "attribute");

Property Routine As %String(MAXLEN = 64, XMLPROJECTION = "attribute");

Property Offset As %String(MAXLEN = 256, XMLPROJECTION = "attribute");

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
<DataLocation>{%%PARENT}("BP")</DataLocation>
<DefaultData>Data</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%Studio.ProjectC("BreakPoints")</IdLocation>
<IndexLocation>^%Studio.BreakPointI</IndexLocation>
<StreamLocation>^%Studio.BreakPointS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
