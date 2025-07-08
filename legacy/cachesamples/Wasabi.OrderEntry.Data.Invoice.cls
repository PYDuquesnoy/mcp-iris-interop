Class Wasabi.OrderEntry.Data.Invoice Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
{

Property BillingAddress As Wasabi.Data.AddressSerial;

Property BillDate As %String;

/// Actually Shipped/Picked and Should be Billed
Relationship LineItems As Wasabi.OrderEntry.Data.InvoiceLineItem [ Cardinality = children, Inverse = Invoice ];

Property Discount As %Float;

Property Tax As %Float;

Property InvoiceAmt As %Float;

Property Comments As %String;

Property PaymentType As %String;

Relationship OrderRef As Wasabi.OrderEntry.Data.Orders [ Cardinality = one, Inverse = Invoices ];

Index OrderIndex On OrderRef;

Storage Default
{
<Data name="InvoiceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>BillingAddress</Value>
</Value>
<Value name="3">
<Value>BillDate</Value>
</Value>
<Value name="4">
<Value>Discount</Value>
</Value>
<Value name="5">
<Value>Tax</Value>
</Value>
<Value name="6">
<Value>InvoiceAmt</Value>
</Value>
<Value name="7">
<Value>Comments</Value>
</Value>
<Value name="8">
<Value>PaymentType</Value>
</Value>
<Value name="9">
<Value>OrderRef</Value>
</Value>
</Data>
<DataLocation>^Wasabi.OrderEntry8A57.InvoiceD</DataLocation>
<DefaultData>InvoiceDefaultData</DefaultData>
<IdLocation>^Wasabi.OrderEntry8A57.InvoiceD</IdLocation>
<IndexLocation>^Wasabi.OrderEntry8A57.InvoiceI</IndexLocation>
<StreamLocation>^Wasabi.OrderEntry8A57.InvoiceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

