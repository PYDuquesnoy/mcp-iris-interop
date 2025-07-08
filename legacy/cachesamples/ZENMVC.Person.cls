/// Simple example of a persistent class that is also a DataModel.
Class ZENMVC.Person Extends (%Persistent, %ZEN.DataModel.Adaptor) [ Inheritance = right ]
{

Property Name As %String;

Property SSN As %String;

Property Home As Address;

Property Business As Address;

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Home</Value>
</Value>
<Value name="4">
<Value>DOB</Value>
</Value>
<Value name="5">
<Value>FavoriteColor</Value>
</Value>
<Value name="6">
<Value>MaritalStatus</Value>
</Value>
<Value name="7">
<Value>SSN</Value>
</Value>
<Value name="8">
<Value>Sex</Value>
</Value>
<Value name="9">
<Value>Home2</Value>
</Value>
<Value name="10">
<Value>Business</Value>
</Value>
</Data>
<DataLocation>^ZENMVC.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^ZENMVC.PersonD</IdLocation>
<IndexLocation>^ZENMVC.PersonI</IndexLocation>
<StreamLocation>^ZENMVC.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

