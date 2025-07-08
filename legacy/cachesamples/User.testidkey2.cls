Class User.testidkey2 Extends %Persistent
{

Index IDKEY On (Name, Num) [ IdKey ];

Property Name As %String;

Property Num As %Integer;

Property Age As %Integer;

Index ageindex On Age;

Storage Default
{
<Data name="testidkey2DefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Age</Value>
</Value>
</Data>
<DataLocation>^User.testidkey2D</DataLocation>
<DefaultData>testidkey2DefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^User.testidkey2D</IdLocation>
<IndexLocation>^User.testidkey2I</IndexLocation>
<StreamLocation>^User.testidkey2S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

