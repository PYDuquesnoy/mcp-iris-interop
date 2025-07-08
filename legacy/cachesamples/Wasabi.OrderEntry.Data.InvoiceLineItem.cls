Class Wasabi.OrderEntry.Data.InvoiceLineItem Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
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

Relationship Invoice As Wasabi.OrderEntry.Data.Invoice [ Cardinality = parent, Inverse = LineItems ];

Method SubTotalGet() As %Float [ CodeMode = expression ]
{
(..UnitPrice*..QuantityOrdered)
}

Storage Default
{
<Data name="InvoiceLineItemDefaultData">
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
<DataLocation>{%%PARENT}("LineItems")</DataLocation>
<DefaultData>InvoiceLineItemDefaultData</DefaultData>
<IdLocation>^Wasabi.OrderEntry8A57.InvoiceC("LineItems")</IdLocation>
<IndexLocation>^Wasabi.Ord8A57.InvoiceLine9A75I</IndexLocation>
<StreamLocation>^Wasabi.Ord8A57.InvoiceLine9A75S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

