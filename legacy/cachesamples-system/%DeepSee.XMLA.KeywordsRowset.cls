/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.KeywordsRowset Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Property Keyword As String;

ClassMethod Populate(filename As %String) As %Status
{
	set reader = ##class(%XML.Reader).%New()
	set status = reader.OpenFile(filename)
	if ($$$ISERR(status)) { quit status }
	
	d ##class(KeywordsRowset).%KillExtent()	
	do reader.Correlate("KeywordsRowset","%DeepSee.XMLA.KeywordsRowset")
 	while (reader.Next(.object,.status)) {
	 	set status = object.%Save()
	 	if ($$$ISERR(status)) { quit }
 	}
    
    quit status
}

Storage Default
{
<Data name="KeywordsRowsetDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Keyword</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.KeywordsRowsetD</DataLocation>
<DefaultData>KeywordsRowsetDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.KeywordsRowsetD</IdLocation>
<IndexLocation>^%DeepSee.XMLA.KeywordsRowsetI</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.KeywordsRowsetS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
