Class Wasabi.Data.Outlet Extends %Persistent
{

Property Address As Wasabi.Data.AddressPersistent;

Property Phone As %String;

Property DefaultPriceCatalog As PriceCatalog;

Relationship OPCs As Wasabi.Data.OutletPriceCatalog [ Cardinality = children, Inverse = Outlet ];

Relationship OutletProducts As Wasabi.Data.OutletProduct [ Cardinality = many, Inverse = Outlet ];

Storage Default
{
<Data name="OutletDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Address</Value>
</Value>
<Value name="3">
<Value>OutletProducts</Value>
</Value>
<Value name="4">
<Value>Phone</Value>
</Value>
<Value name="5">
<Value>DefaultPriceCatalog</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.OutletD</DataLocation>
<DefaultData>OutletDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.OutletD</IdLocation>
<IndexLocation>^Wasabi.Data.OutletI</IndexLocation>
<StreamLocation>^Wasabi.Data.OutletS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

