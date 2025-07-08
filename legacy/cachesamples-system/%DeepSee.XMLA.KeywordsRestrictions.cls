/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.KeywordsRestrictions Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property KeywordList As list Of String(XMLPROJECTION = "none");

Property Keyword As String;

Method Normalize() As %Status
{
	quit ##class(Server).ParseRestrictions("Keyword", ..Keyword, ..KeywordList)
}

Storage Default
{
<Data name="KeywordsRestrictionsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Keyword</Value>
</Value>
<Value name="3">
<Value>KeywordList</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.KeywordsResFB12D</DataLocation>
<DefaultData>KeywordsRestrictionsDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.KeywordsResFB12D</IdLocation>
<IndexLocation>^%DeepSee.XMLA.KeywordsResFB12I</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.KeywordsResFB12S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
