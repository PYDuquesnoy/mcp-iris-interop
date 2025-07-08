/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.UserLibrary.SharedCalcMember Extends (%Persistent, %DeepSee.UserLibrary.UserData)
{

Parameter XMLNAME = "sharedCalcMember";

Property FullName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute") [ SqlComputeCode = { Set {FullName} = {CubeName}_"||"_{UpperCaseDimension}_"||"_{UpperCaseName}_"."_$$$DSSCMExt }, SqlComputed, Transient ];

Property Dimension As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Name As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Expression As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Format As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property SolveOrder As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property CubeName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property UpperCaseDimension As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property UpperCaseName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Index Idx On (CubeName, UpperCaseDimension, UpperCaseName) [ IdKey ];

Method getIdentifier() As %String
{
	Quit ..CubeName_"||"_..UpperCaseDimension_"||"_..UpperCaseName
}

Method getFullName() As %String
{
	Quit ..getIdentifier()_"."_$$$DSSCMExt
}

Storage Default
{
<Data name="SharedCalcMemberDefaultData">
<Value name="1">
<Value>Dimension</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Expression</Value>
</Value>
<Value name="4">
<Value>Format</Value>
</Value>
<Value name="5">
<Value>SolveOrder</Value>
</Value>
<Value name="6">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^DeepSee.CalcMbrs</DataLocation>
<DefaultData>SharedCalcMemberDefaultData</DefaultData>
<IdLocation>^%DeepSee.UB70D.SharedCalcM6DFCD</IdLocation>
<IndexLocation>^%DeepSee.UB70D.SharedCalcM6DFCI</IndexLocation>
<StreamLocation>^%DeepSee.UB70D.SharedCalcM6DFCS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
