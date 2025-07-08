/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.PropertiesRowset Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Property PropertyName As String;

Property PropertyDescription As String;

Property PropertyType As String;

Property PropertyAccessType As String;

Property IsRequired As String;

Property Value As String;

ClassMethod Populate(filename As %String) As %Status
{
	set reader = ##class(%XML.Reader).%New()
	set status = reader.OpenFile(filename)
	if ($$$ISERR(status)) { quit status }
	
	d ##class(PropertiesRowset).%KillExtent()	
	do reader.Correlate("PropertiesRowset","%DeepSee.XMLA.PropertiesRowset")
 	while (reader.Next(.object,.status)) {
	 	set status = object.%Save()
	 	if ($$$ISERR(status)) { quit }
 	}
    
    quit status
}

Storage Default
{
<Data name="PropertiesRowsetDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PropertyName</Value>
</Value>
<Value name="3">
<Value>PropertyDescription</Value>
</Value>
<Value name="4">
<Value>PropertyType</Value>
</Value>
<Value name="5">
<Value>PropertyAccessType</Value>
</Value>
<Value name="6">
<Value>IsRequired</Value>
</Value>
<Value name="7">
<Value>Value</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.PropertiesR6C2ED</DataLocation>
<DefaultData>PropertiesRowsetDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.PropertiesR6C2ED</IdLocation>
<IndexLocation>^%DeepSee.XMLA.PropertiesR6C2EI</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.PropertiesR6C2ES</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
