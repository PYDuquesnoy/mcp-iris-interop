/// Information about films
Class Cinema.Film Extends %Library.Persistent
{

/// Index for property TicketsSold
Index TicketsSoldIndex On TicketsSold;

/// Index for property Title
Index TitleIndex On Title;

Property Category As Cinema.FilmCategory;

Property Description As %Library.String(MAXLEN = 300);

Property Length As Cinema.Duration;

Property PlayingNow As %Library.Boolean [ InitialExpression = 1 ];

Property Rating As %Library.String(VALUELIST = ",G,PG,PG-13,R");

Property TicketsSold As %Library.Integer [ InitialExpression = 0 ];

Property Title As %Library.String [ Required ];

/// Top films (by tickets sold) in a genre
Query TopCategory(P1 As %Library.String) As %Library.SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Description:%Library.String,Length:Cinema.Duration,Rating:%Library.String,Title:%Library.String,CategoryName:%Library.String")
{
 SELECT TOP 3 ID, Description, Length, Rating, Title, Category->CategoryName
 	FROM Film
 	WHERE (PlayingNow = 1) AND (Category = :P1)
 	ORDER BY TicketsSold DESC
}

/// List of most popular films.
Query TopFilms(P1 As %Library.String) As %Library.SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Description:%Library.String,Length:Cinema.Duration,Rating:%Library.String,Title:%Library.String,CategoryName:%Library.String") [ SqlProc ]
{
 SELECT Top 3 ID, Description, Length, Rating, Title, Category->CategoryName
 	FROM Film
 	WHERE (PlayingNow = 1)
 	ORDER BY TicketsSold DESC
}

Storage Default
{
<Data name="FilmDefaultData">
<Value name="1">
<Value>Description</Value>
</Value>
<Value name="2">
<Value>PlayingNow</Value>
</Value>
<Value name="3">
<Value>TicketsSold</Value>
</Value>
<Value name="4">
<Value>Title</Value>
</Value>
<Value name="5">
<Value>Category</Value>
</Value>
<Value name="6">
<Value>Length</Value>
</Value>
<Value name="7">
<Value>Rating</Value>
</Value>
<Value name="8">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^CinemaooFilmD</DataLocation>
<DefaultData>FilmDefaultData</DefaultData>
<IdLocation>^CinemaooFilmD</IdLocation>
<IndexLocation>^CinemaooFilmI</IndexLocation>
<StreamLocation>^Cinema.FilmS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

