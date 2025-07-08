/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.UserLibrary.PivotVariable Extends (%Persistent, %DeepSee.UserLibrary.UserData)
{

Parameter XMLNAME = "pivotVariable";

Property FullName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute") [ SqlComputeCode = { Set {FullName} = {CubeName}_"||"_{UpperCaseName}_"."_$$$DSPVExt }, SqlComputed, Transient ];

Property Name As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property DisplayName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Description As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property DefaultValue As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Context As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Type As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property SourceType As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property SourceName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property ValueList As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property DisplayList As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property CubeName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property UpperCaseName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Index Idx On (CubeName, UpperCaseName) [ IdKey ];

Method getIdentifier() As %String
{
	Quit ..CubeName_"||"_..UpperCaseName
}

Method getFullName() As %String
{
	Quit ..getIdentifier()_"."_$$$DSPVExt
}

Storage Default
{
<Data name="PivotVariableDefaultData">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>DisplayName</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>DefaultValue</Value>
</Value>
<Value name="5">
<Value>Context</Value>
</Value>
<Value name="6">
<Value>Type</Value>
</Value>
<Value name="7">
<Value>SourceType</Value>
</Value>
<Value name="8">
<Value>SourceName</Value>
</Value>
<Value name="9">
<Value>ValueList</Value>
</Value>
<Value name="10">
<Value>DisplayList</Value>
</Value>
<Value name="11">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^DeepSee.Variables</DataLocation>
<DefaultData>PivotVariableDefaultData</DefaultData>
<IdLocation>^%DeepSee.UseB70D.PivotVariableD</IdLocation>
<IndexLocation>^%DeepSee.UseB70D.PivotVariableI</IndexLocation>
<StreamLocation>^%DeepSee.UseB70D.PivotVariableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
