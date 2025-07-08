/// Simple query class used to exercise the Build-From-Query feature of DeepSee Visual Reports
Class DSVRDemo.FilmSQL Extends %Persistent [ ClassType = persistent, LegacyInstanceContext ]
{

Query ListFilms() As %SQLQuery [ SqlProc ]
{
	SELECT ID,Title,TicketsSold,Category->CategoryName,Description,Length,PlayingNow,Rating
	FROM Cinema.Film
	ORDER BY Title
}

Storage Default
{
<Data name="FilmSQLDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^DSVRDemo.FilmSQLD</DataLocation>
<DefaultData>FilmSQLDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^DSVRDemo.FilmSQLD</IdLocation>
<IndexLocation>^DSVRDemo.FilmSQLI</IndexLocation>
<StreamLocation>^DSVRDemo.FilmSQLS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

