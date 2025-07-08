/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.UserLibrary.NamedFilter Extends (%Persistent, %DeepSee.UserLibrary.UserData)
{

Parameter XMLNAME = "namedFilter";

Property FullName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute") [ SqlComputeCode = { Set {FullName} = {CubeName}_"||"_{UpperCaseName}_"."_$$$DSNFExt }, SqlComputed, Transient ];

Property Name As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Tooltip As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Spec As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property UpperCaseName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property CubeName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Index Idx On (CubeName, UpperCaseName) [ IdKey ];

Method getIdentifier() As %String
{
	Quit ..CubeName_"||"_..UpperCaseName
}

Method getFullName() As %String
{
	Quit ..getIdentifier()_"."_$$$DSNFExt
}

Storage Default
{
<Data name="NamedFilterDefaultData">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Tooltip</Value>
</Value>
<Value name="3">
<Value>Spec</Value>
</Value>
<Value name="4">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^DeepSee.Filters</DataLocation>
<DefaultData>NamedFilterDefaultData</DefaultData>
<IdLocation>^%DeepSee.UserLB70D.NamedFilterD</IdLocation>
<IndexLocation>^%DeepSee.UserLB70D.NamedFilterI</IndexLocation>
<StreamLocation>^%DeepSee.UserLB70D.NamedFilterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
