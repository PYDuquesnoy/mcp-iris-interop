Class Wasabi.OrderEntry.Data.CartLineItem Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
{

/// Product from Group #1
Property Product As Wasabi.ProductManagement.Data.Product [ Required ];

Property Quantity As %Integer;

Property UnitPrice As %Float [ Calculated, SqlComputeCode = { set {UnitPrice}=##class(Others.Pruduct).GetCurrentPrice({Product})}, SqlComputed ];

Relationship Cart As Wasabi.OrderEntry.Data.Cart [ Cardinality = parent, Inverse = LineItems ];

Method UnitPrice() As %Float
{
	if ..Product '= "" {
		set res = ##class(Others.Product).GetCurrentPrice(..Product.%Id())
	} else {
		set res = 0.0
	}
	quit res
}

Storage Default
{
<Data name="CartLineItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Product</Value>
</Value>
<Value name="3">
<Value>Quantity</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("LineItems")</DataLocation>
<DefaultData>CartLineItemDefaultData</DefaultData>
<IdLocation>^Wasabi.OrderEntry.Data.CartC("LineItems")</IdLocation>
<IndexLocation>^Wasabi.OrderEntry.Data.CartLineItemI</IndexLocation>
<StreamLocation>^Wasabi.OrderEntry.Data.CartLineItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

