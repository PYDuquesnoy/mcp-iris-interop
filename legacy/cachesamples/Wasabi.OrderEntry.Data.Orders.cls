Class Wasabi.OrderEntry.Data.Orders Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
{

/// Group #3 Person ID
Property Customer As Wasabi.Data.Customer;

/// Group #3 Person ID
/// Needs to have a "Not a Sales Person (self serv) Sales Person"
Property SalesPerson As Wasabi.Data.SalesPerson;

Property InitialTimestamp As %TimeStamp [ InitialExpression = {$zts} ];

Property ShippingAddress As Wasabi.Data.AddressSerial;

Property BillingAddress As Wasabi.Data.AddressSerial;

Property Discount As %Float;

/// ordered, shipped, cancelled, etc.) -- WS
Property CurrentStatus As %String(VALUELIST = ",New,Canceled, Confirmed, Fullfilled");

Property PaymentType As %String;

Relationship Items As Wasabi.OrderEntry.Data.OrderLineItem [ Cardinality = children, Inverse = OrderRef ];

Relationship Invoices As Wasabi.OrderEntry.Data.Invoice [ Cardinality = many, Inverse = OrderRef ];

Storage Default
{
<Data name="OrdersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Customer</Value>
</Value>
<Value name="3">
<Value>SalesPerson</Value>
</Value>
<Value name="4">
<Value>InitialTimestamp</Value>
</Value>
<Value name="5">
<Value>ShippingAddress</Value>
</Value>
<Value name="6">
<Value>BillingAddress</Value>
</Value>
<Value name="7">
<Value>Discount</Value>
</Value>
<Value name="8">
<Value>CurrentStatus</Value>
</Value>
<Value name="9">
<Value>PaymentType</Value>
</Value>
</Data>
<DataLocation>^Wasabi.OrderEntry.Data.OrdersD</DataLocation>
<DefaultData>OrdersDefaultData</DefaultData>
<IdLocation>^Wasabi.OrderEntry.Data.OrdersD</IdLocation>
<IndexLocation>^Wasabi.OrderEntry.Data.OrdersI</IndexLocation>
<StreamLocation>^Wasabi.OrderEntry.Data.OrdersS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

