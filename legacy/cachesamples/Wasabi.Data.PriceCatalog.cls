Class Wasabi.Data.PriceCatalog Extends %Persistent
{

Property Name As %String;

Property Description As %String;

Property StartDate As %TimeStamp;

Property EndDate As %TimeStamp;

Relationship Items As Wasabi.Data.PriceCatalogItem [ Cardinality = children, Inverse = PriceCatalog ];

Relationship OPCs As Wasabi.Data.OutletPriceCatalog [ Cardinality = many, Inverse = PriceCatalog ];

Storage Default
{
<Data name="PriceCatalogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>StartDate</Value>
</Value>
<Value name="3">
<Value>EndDate</Value>
</Value>
<Value name="4">
<Value>Name</Value>
</Value>
<Value name="5">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.PriceCatalogD</DataLocation>
<DefaultData>PriceCatalogDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.PriceCatalogD</IdLocation>
<IndexLocation>^Wasabi.Data.PriceCatalogI</IndexLocation>
<StreamLocation>^Wasabi.Data.PriceCatalogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

