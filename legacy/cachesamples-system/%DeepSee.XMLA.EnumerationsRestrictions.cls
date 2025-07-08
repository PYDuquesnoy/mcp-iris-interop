/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.EnumerationsRestrictions Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property EnumName As String;

Property EnumNameList As list Of String(XMLPROJECTION = "none");

Method Normalize() As %Status
{
	quit ##class(Server).ParseRestrictions("EnumName", ..EnumName, ..EnumNameList)
}

Storage Default
{
<Data name="EnumerationsRestrictionsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>EnumName</Value>
</Value>
<Value name="3">
<Value>EnumNameList</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.EnumerationC487D</DataLocation>
<DefaultData>EnumerationsRestrictionsDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.EnumerationC487D</IdLocation>
<IndexLocation>^%DeepSee.XMLA.EnumerationC487I</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.EnumerationC487S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
