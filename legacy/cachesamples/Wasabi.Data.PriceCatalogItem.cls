Class Wasabi.Data.PriceCatalogItem Extends %Persistent
{

Property Product As Product;

Property Price As %Float;

Relationship PriceCatalog As Wasabi.Data.PriceCatalog [ Cardinality = parent, Inverse = Items ];

Index ProductIndex On (PriceCatalog, Product) [ Unique ];

Storage Default
{
<Data name="PriceCatalogItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Product</Value>
</Value>
<Value name="3">
<Value>Price</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Items")</DataLocation>
<DefaultData>PriceCatalogItemDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.PriceCatalogC("Items")</IdLocation>
<IndexLocation>^Wasabi.Data.PriceCatalogItemI</IndexLocation>
<StreamLocation>^Wasabi.Data.PriceCatalogItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

