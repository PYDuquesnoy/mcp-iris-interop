Class Cinema.TicketOrder Extends %Library.Persistent
{

Relationship Items As Cinema.TicketItem [ Cardinality = children, Inverse = TicketOrder ];

Property Total As %Float(SCALE = 2);

/// Set Complete to true (1) to indicate order has been completed.
/// Complete will be false (0) while the order is being input.
Property Complete As %Boolean [ InitialExpression = 0 ];

Storage Default
{
<Data name="TicketOrderDefaultData">
<Value name="1">
<Value>Customer</Value>
</Value>
<Value name="2">
<Value>Items</Value>
</Value>
<Value name="3">
<Value>Total</Value>
</Value>
<Value name="4">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="5">
<Value>Complete</Value>
</Value>
</Data>
<DataLocation>^CinemaooTicketOrderD</DataLocation>
<DefaultData>TicketOrderDefaultData</DefaultData>
<IdLocation>^CinemaooTicketOrderD</IdLocation>
<IndexLocation>^CinemaooTicketOrderI</IndexLocation>
<StreamLocation>^Cinema.TicketOrderS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

