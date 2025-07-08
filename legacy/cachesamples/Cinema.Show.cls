/// Information about when and where films are shown.
Class Cinema.Show Extends %Library.Persistent
{

Property Film As Cinema.Film;

Property StartTime As %Library.Time(FORMAT = 2);

Property Theater As Cinema.Theater;

/// List of show times and locations for a single film.
Query ShowTimes(P1 As %Library.String) As %Library.SQLQuery(CONTAINID = 1, ROWSPEC = "ID,StartTime:%Library.Time,TheaterName:%Library.String")
{
 SELECT ID, StartTime, Theater->TheaterName
	FROM Show
	WHERE (Film = :P1)
	ORDER BY StartTime, Theater
}

Storage Default
{
<Data name="ShowDefaultData">
<Value name="1">
<Value>Film</Value>
</Value>
<Value name="2">
<Value>StartTime</Value>
</Value>
<Value name="3">
<Value>Theater</Value>
</Value>
<Value name="4">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^CinemaooShowD</DataLocation>
<DefaultData>ShowDefaultData</DefaultData>
<IdLocation>^CinemaooShowD</IdLocation>
<IndexLocation>^CinemaooShowI</IndexLocation>
<StreamLocation>^Cinema.ShowS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

