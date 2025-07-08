/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a specific variable to put in the watch list for debugging.
Class %Studio.WatchVariable Extends (%Persistent, %XML.Adaptor) [ System = 3 ]
{

Index NameIdx On (VariableESC, Pane) [ IdKey ];

Relationship Project As Project [ Cardinality = parent, Inverse = WatchVariables ];

Property Variable As %String(MAXLEN = 256, XMLPROJECTION = "attribute") [ SqlComputeCode = {set {*}=$replace({VariableESC},"__","||")}, SqlComputed, SqlComputeOnChange = VariableESC ];

Method VariableGet() As %String
{
	Quit ..VariableCompute($listget(i%"%%OID"),"",i%VariableESC)
}

Method VariableSet(val As %String) As %Status
{
	Set i%VariableESC=$replace(val,"||","__")
	Quit $$$OK
}

Property VariableESC As %String(MAXLEN = 256) [ Private, SqlComputeCode = {set {*}=$replace({Variable},"||","__")}, SqlComputed, SqlComputeOnChange = Variable ];

Method VariableESCGet() As %String [ Private ]
{
	Quit i%VariableESC
}

Property Pane As %Integer(XMLPROJECTION = "attribute");

Storage Default
{
<Data name="Data">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Variable</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("WV")</DataLocation>
<DefaultData>Data</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%Studio.ProjectC("WatchVariables")</IdLocation>
<IndexLocation>^%Studio.WatchVariableI</IndexLocation>
<StreamLocation>^%Studio.WatchVariableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
