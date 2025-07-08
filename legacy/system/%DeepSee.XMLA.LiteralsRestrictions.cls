/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.LiteralsRestrictions Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property LiteralName As String;

Property LiteralNameList As list Of String(XMLPROJECTION = "none");

Method Normalize() As %Status
{
	quit ##class(Server).ParseRestrictions("LiteralName", ..LiteralName, ..LiteralNameList)
}

Storage Default
{
<Data name="LiteralsRestrictionsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>LiteralName</Value>
</Value>
<Value name="3">
<Value>LiteralNameList</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.LiteralsRes8B19D</DataLocation>
<DefaultData>LiteralsRestrictionsDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.LiteralsRes8B19D</IdLocation>
<IndexLocation>^%DeepSee.XMLA.LiteralsRes8B19I</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.LiteralsRes8B19S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
