Class Wasabi.Data.Product Extends %Persistent
{

Property Code As %String;

Property Category As Category;

Relationship OutletProducts As Wasabi.Data.OutletProduct [ Cardinality = many, Inverse = Product ];

Storage Default
{
<Data name="ProductDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Code</Value>
</Value>
<Value name="3">
<Value>Category</Value>
</Value>
<Value name="4">
<Value>OutletProducts</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.ProductD</DataLocation>
<DefaultData>ProductDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.ProductD</IdLocation>
<IndexLocation>^Wasabi.Data.ProductI</IndexLocation>
<StreamLocation>^Wasabi.Data.ProductS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

