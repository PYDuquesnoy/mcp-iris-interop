/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents an item within a Studio Project.
Class %Studio.ProjectItem Extends (%Persistent, %XML.Adaptor) [ System = 3 ]
{

Relationship Project As Project [ Cardinality = parent, Inverse = Items ];

/// The name of the project item. For example if the class is called 'csp.loop'
/// then this is 'csp.loop'. If the routine is 'TEST.INT' this is 'TEST.INT'.
Property Name As %String(MAXLEN = 512, XMLNAME = "name", XMLPROJECTION = "attribute") [ Required ];

/// Type of item in this project. Can be one of MAC, CSP, CLS, GBL, PKG, DIR
/// or a user defined type.
/// Note that MAC covers all routines types, such as INT, INC, BAS, MVB, MVI and MAC
/// routines, the type of routine is put in the Name, such as 'TEST.INT'.
Property Type As %String(XMLNAME = "type", XMLPROJECTION = "attribute") [ Required ];

Index NameIdx On (Name, Type) [ IdKey ];

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private ]
{
	#; update project timestamp
	Set ts=$zutil(188),..Project.LastModified=$$$TimeToODBC(ts)
	QUIT $$$OK
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	Set name=..Name,type=..Type
	Set sc=##class(%Studio.Project).NormalizeName(.name,.type) If $$$ISERR(sc) Quit sc
	Set ..Name=name,..Type=type
	Quit $$$OK
}

Storage Default
{
<Data name="Data">
<Value name="2">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Items")</DataLocation>
<DefaultData>Data</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%Studio.ProjectC("Items")</IdLocation>
<IndexLocation>^%Studio.ProjectItemI</IndexLocation>
<StreamLocation>^%Studio.ProjectItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
