/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.SchemasRowset Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Property SchemaName As String;

Property Restrictions As list Of String;

ClassMethod Populate()
{
	do ##class(SchemasRowset).%KillExtent()
	
	set row = ##class(SchemasRowset).%New()
	set row.SchemaName = "DISCOVER_DATASOURCES"
	do row.Restrictions.Insert("DataSourceName")
	do row.Restrictions.Insert("URL")
	do row.Restrictions.Insert("ProviderName")
	do row.Restrictions.Insert("ProviderType")
	do row.Restrictions.Insert("AuthenticationMode")	
	do row.%Save()
	
	set row = ##class(SchemasRowset).%New()
	set row.SchemaName = "DISCOVER_ENUMERATORS"
	do row.Restrictions.Insert("EnumName")
	do row.%Save()
	
	set row = ##class(SchemasRowset).%New()
	set row.SchemaName = "DISCOVER_KEYWORDS"
	do row.Restrictions.Insert("Keyword")
	do row.%Save()
	
	set row = ##class(SchemasRowset).%New()
	set row.SchemaName = "DISCOVER_LITERALS"
	do row.Restrictions.Insert("LiteralName")
	do row.%Save()
	
	set row = ##class(SchemasRowset).%New()
	set row.SchemaName = "DISCOVER_PROPERTIES"
	do row.Restrictions.Insert("PropertyName")
	do row.%Save()

	set row = ##class(SchemasRowset).%New()
	set row.SchemaName = "DISCOVER_SCHEMA_ROWSETS"
	do row.Restrictions.Insert("SchemaName")
	do row.%Save()
}

Storage Default
{
<Data name="SchemasRowsetDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SchemaName</Value>
</Value>
<Value name="3">
<Value>Restrictions</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.SchemasRowsetD</DataLocation>
<DefaultData>SchemasRowsetDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.SchemasRowsetD</IdLocation>
<IndexLocation>^%DeepSee.XMLA.SchemasRowsetI</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.SchemasRowsetS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
