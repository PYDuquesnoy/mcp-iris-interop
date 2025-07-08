Class Wasabi.OrderEntry.Data.OrderLineItem Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
{

/// Group #1 "Product ID"
Property Product As Wasabi.ProductManagement.Data.Product;

Property Description As %String;

Property QuantityOrdered As %Integer;

Property QuantityShipped As %Integer;

Property UnitPrice As %Float;

Property SubTotal As %Float [ Calculated, SqlComputeCode = { set {SubTotal}=({UnitPrice}*{QuantityOrdered})}, SqlComputed ];

Property Discount As %Float;

Property TotalPrice As %Float;

Property Status As Wasabi.OrderEntry.Data.EventType;

Property CreateTimestamp As %String;

Property DeleteTimestamp As %String;

Relationship OrderRef As Wasabi.OrderEntry.Data.Orders [ Cardinality = parent, Inverse = Items ];

Method SubTotalGet() As %Float [ CodeMode = expression ]
{
(..UnitPrice*..QuantityOrdered)
}

Storage Default
{
<Data name="OrderLineItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Product</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>QuantityOrdered</Value>
</Value>
<Value name="5">
<Value>QuantityShipped</Value>
</Value>
<Value name="6">
<Value>UnitPrice</Value>
</Value>
<Value name="7">
<Value>Discount</Value>
</Value>
<Value name="8">
<Value>TotalPrice</Value>
</Value>
<Value name="9">
<Value>Status</Value>
</Value>
<Value name="10">
<Value>CreateTimestamp</Value>
</Value>
<Value name="11">
<Value>DeleteTimestamp</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Items")</DataLocation>
<DefaultData>OrderLineItemDefaultData</DefaultData>
<IdLocation>^Wasabi.OrderEntry.Data.OrdersC("Items")</IdLocation>
<IndexLocation>^Wasabi.Order8A57.OrderLineItemI</IndexLocation>
<StreamLocation>^Wasabi.Order8A57.OrderLineItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

