/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.EnumerationsRowset Extends %Persistent [ System = 4 ]
{

Property EnumName As String;

Property EnumDescription As String;

Property EnumType As String [ InitialExpression = "string" ];

Property ElementName As String;

Property ElementDescription As String;

Property ElementValue As String;

ClassMethod Populate()
{
	do ##class(EnumerationsRowset).%KillExtent()
	
	// ProviderType
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "ProviderType"
	set row.ElementName = "MDP"
	set row.ElementValue = "2"
	do row.%Save()
	
	// AuthenticationMode
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "AuthenticationMode"
	set row.ElementName = "Authenticated"
	set row.ElementValue = "12"
	do row.%Save()

	// PropertyAccessType
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "PropertyAccessType"
	set row.ElementName = "Read"
	set row.ElementValue = "21"
	do row.%Save()
	
	// StateSupport
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "StateSupport"
	set row.EnumType = "string"
	set row.ElementName = "None"
	set row.ElementValue = "31"
	do row.%Save()
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "StateSupport"
	set row.ElementName = "Sessions"
	set row.ElementValue = "32"
	do row.%Save()
	
	// StateActionVerb
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "StateActionVerb"
	set row.ElementName = "BeginSession"
	set row.ElementValue = "41"
	do row.%Save()
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "StateActionVerb"
	set row.ElementName = "EndSession"
	set row.ElementValue = "42"
	do row.%Save()

	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "StateActionVerb"
	set row.ElementName = "Session"
	set row.ElementValue = "43"
	do row.%Save()

	// ResultsetFormat
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "ResultsetFormat"
	set row.ElementName = "Multidimensional"
	set row.ElementValue = "52"
	do row.%Save()
	
	// ResultsetAxisFormat
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "ResultsetAxisFormat"
	set row.ElementName = "TupleFormat"
	set row.ElementValue = "70"
	do row.%Save()
	
	// ResultsetContents
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "ResultsetContents"
	set row.ElementName = "None"
	set row.ElementValue = "61"
	do row.%Save()
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "ResultsetContents"
	set row.ElementName = "Schema"
	set row.ElementValue = "62"
	do row.%Save()
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "ResultsetContents"
	set row.ElementName = "Data"
	set row.ElementValue = "63"
	do row.%Save()
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "ResultsetContents"
	set row.ElementName = "SchemaData"
	set row.ElementValue = "64"
	do row.%Save()	
	
	// MDXSupportLevel
	
	set row = ##class(EnumerationsRowset).%New()
	set row.EnumName = "MDXSupportLevel"
	set row.ElementName = "Core"
	set row.ElementValue = "80"
	do row.%Save()
}

Storage Default
{
<Data name="EnumerationsRowsetDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>EnumName</Value>
</Value>
<Value name="3">
<Value>EnumDescription</Value>
</Value>
<Value name="4">
<Value>EnumType</Value>
</Value>
<Value name="5">
<Value>ElementName</Value>
</Value>
<Value name="6">
<Value>ElementDescription</Value>
</Value>
<Value name="7">
<Value>ElementValue</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.EnumerationF8FAD</DataLocation>
<DefaultData>EnumerationsRowsetDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.EnumerationF8FAD</IdLocation>
<IndexLocation>^%DeepSee.XMLA.EnumerationF8FAI</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.EnumerationF8FAS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
