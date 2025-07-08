Class Wasabi.OrderEntry.Data.Cart Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
{

/// Group #3 "Customer" ID
Property Customer As Wasabi.Data.Customer;

Property TokenKey As %String;

Property InitialTimestamp As %TimeStamp [ InitialExpression = {$zts} ];

Relationship LineItems As Wasabi.OrderEntry.Data.CartLineItem [ Cardinality = children, Inverse = Cart ];

Storage Default
{
<Data name="CartDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Customer</Value>
</Value>
<Value name="3">
<Value>TokenKey</Value>
</Value>
<Value name="4">
<Value>InitialTimestamp</Value>
</Value>
</Data>
<DataLocation>^Wasabi.OrderEntry.Data.CartD</DataLocation>
<DefaultData>CartDefaultData</DefaultData>
<IdLocation>^Wasabi.OrderEntry.Data.CartD</IdLocation>
<IndexLocation>^Wasabi.OrderEntry.Data.CartI</IndexLocation>
<StreamLocation>^Wasabi.OrderEntry.Data.CartS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

