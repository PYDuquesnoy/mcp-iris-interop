/// Sample data class for Zen sample pages.
/// This defines a set of city names used for lookups.
Class ZENDemo.Data.City Extends (%Persistent, %Populate) [ Inheritance = right ]
{

/// City Name
Property Name As %String(MAXLEN = 100, POPSPEC = "City()") [ Required ];

/// ZIP Code
Property ZIP As %String(MAXLEN = 12, POPSPEC = "USZip()") [ Required ];

Storage Default
{
<Data name="CityDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>ZIP</Value>
</Value>
</Data>
<DataLocation>^ZENDemo.Data.CityD</DataLocation>
<DefaultData>CityDefaultData</DefaultData>
<IdLocation>^ZENDemo.Data.CityD</IdLocation>
<IndexLocation>^ZENDemo.Data.CityI</IndexLocation>
<Property name="Name"/>
<Property name="ZIP"/>
<StreamLocation>^ZENDemo.Data.CityS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

