/// Associative entity for many to many relationship between Outlets and PriceCatalogs
Class Wasabi.Data.OutletPriceCatalog Extends %Persistent
{

Relationship PriceCatalog As Wasabi.Data.PriceCatalog [ Cardinality = one, Inverse = OPCs ];

Index PriceCatalogIndex On PriceCatalog;

Relationship Outlet As Wasabi.Data.Outlet [ Cardinality = parent, Inverse = OPCs ];

Storage Default
{
<Data name="OutletPriceCatalogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PriceCatalog</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("OPCs")</DataLocation>
<DefaultData>OutletPriceCatalogDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.OutletC("OPCs")</IdLocation>
<IndexLocation>^Wasabi.Data.OutletPrice1A3EI</IndexLocation>
<StreamLocation>^Wasabi.Data.OutletPrice1A3ES</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

