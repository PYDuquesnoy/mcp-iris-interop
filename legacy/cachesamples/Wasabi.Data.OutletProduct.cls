Class Wasabi.Data.OutletProduct Extends %Persistent
{

/// Total quantity in stock
Property Quantity As %Integer;

/// Quantity committed to orders
Property QuantityCommitted As %Integer;

Relationship Outlet As Outlet [ Cardinality = one, Inverse = OutletProducts ];

Relationship Product As Product [ Cardinality = one, Inverse = OutletProducts ];

Index IdIndex On (Outlet, Product) [ IdKey, Unique ];

Index ProductIndex On Product;

Storage Default
{
<Data name="OutletProductDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Quantity</Value>
</Value>
<Value name="3">
<Value>QuantityCommitted</Value>
</Value>
<Value name="4">
<Value>Outlet</Value>
</Value>
<Value name="5">
<Value>Product</Value>
</Value>
<Value name="6">
<Value>Version</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.OutletProductD</DataLocation>
<DefaultData>OutletProductDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.OutletProductD</IdLocation>
<IndexLocation>^Wasabi.Data.OutletProductI</IndexLocation>
<StreamLocation>^Wasabi.Data.OutletProductS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

