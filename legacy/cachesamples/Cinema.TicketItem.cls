Class Cinema.TicketItem Extends %Library.Persistent
{

Property AdultTickets As %Library.Integer [ InitialExpression = 2 ];

Property ChildTickets As %Library.Integer [ InitialExpression = 0 ];

Property Show As Cinema.Show;

Relationship TicketOrder As Cinema.TicketOrder [ Cardinality = parent, Inverse = Items ];

Query ShowItem(P1 As %Library.String) As %Library.SQLQuery(CONTAINID = 1, ROWSPEC = "ID,AdultTickets:%Library.Integer,ChildTickets:%Library.Integer,Title:%Library.String,StartTime:%Library.Time,TheaterName:%Library.String,Film:Cinema.Film")
{
 SELECT ID, AdultTickets, ChildTickets, Show->Film->Title, Show->StartTime, Show->Theater->TheaterName, Show->Film
	FROM TicketItem
	WHERE (TicketOrder = :P1)
}

Storage Default
{
<Data name="TicketItemDefaultData">
<Value name="1">
<Value>AdultTickets</Value>
</Value>
<Value name="2">
<Value>ChildTickets</Value>
</Value>
<Value name="3">
<Value>Show</Value>
</Value>
<Value name="4">
<Value>TicketOrder</Value>
</Value>
<Value name="5">
<Value>Order</Value>
</Value>
<Value name="6">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^CinemaooTicketItemD</DataLocation>
<DefaultData>TicketItemDefaultData</DefaultData>
<IdLocation>^CinemaooTicketItemD</IdLocation>
<IndexLocation>^CinemaooTicketItemI</IndexLocation>
<StreamLocation>^Cinema.TicketItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

