/// Information about theaters and ticket prices.
Class Cinema.Theater Extends %Library.Persistent
{

Property AdultPrice As %Library.Float(MINVAL = 0, SCALE = 2);

Property ChildPrice As %Library.Float(MINVAL = 0, SCALE = 2);

Property TheaterName As %Library.String;

Storage Default
{
<Data name="TheaterDefaultData">
<Value name="1">
<Value>AdultPrice</Value>
</Value>
<Value name="2">
<Value>ChildPrice</Value>
</Value>
<Value name="3">
<Value>TheaterName</Value>
</Value>
<Value name="4">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^CinemaooTheaterD</DataLocation>
<DefaultData>TheaterDefaultData</DefaultData>
<IdLocation>^CinemaooTheaterD</IdLocation>
<IndexLocation>^CinemaooTheaterI</IndexLocation>
<StreamLocation>^Cinema.TheaterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

