/// List of film genres, for instance "Drama".
Class Cinema.FilmCategory Extends %Library.Persistent
{

Property CategoryName As %Library.String;

/// Index for property CategoryName
Index CategoryNameIndex On CategoryName;

/// List of film category names
Query CategoryName() As %Library.SQLQuery(CONTAINID = 1, ROWSPEC = "ID,CategoryName:%Library.String")
{
 SELECT ID, CategoryName
 	FROM FilmCategory
 	ORDER BY CategoryName
}

Storage Default
{
<Data name="FilmCategoryDefaultData">
<Value name="1">
<Value>CategoryName</Value>
</Value>
<Value name="2">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^CinemaooFilmCategoryD</DataLocation>
<DefaultData>FilmCategoryDefaultData</DefaultData>
<IdLocation>^CinemaooFilmCategoryD</IdLocation>
<IndexLocation>^CinemaooFilmCategoryI</IndexLocation>
<StreamLocation>^Cinema.FilmCategoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

