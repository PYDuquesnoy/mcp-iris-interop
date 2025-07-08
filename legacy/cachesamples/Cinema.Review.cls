Class Cinema.Review Extends %Persistent
{

Property Film As Cinema.Film;

Property ReviewScore As %Integer(MAXVAL = 10, MINVAL = 0);

Property ReviewText As %String(MAXLEN = 20000);

Storage Default
{
<Data name="ReviewDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Film</Value>
</Value>
<Value name="3">
<Value>ReviewScore</Value>
</Value>
<Value name="4">
<Value>ReviewText</Value>
</Value>
</Data>
<DataLocation>^Cinema.ReviewD</DataLocation>
<DefaultData>ReviewDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Cinema.ReviewD</IdLocation>
<IndexLocation>^Cinema.ReviewI</IndexLocation>
<StreamLocation>^Cinema.ReviewS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

