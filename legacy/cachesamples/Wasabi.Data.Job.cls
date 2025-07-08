Class Wasabi.Data.Job Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
{

Property JobTitle As %String [ Required ];

Property SecurityRole As %String;

Storage Default
{
<Data name="JobDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>JobTitle</Value>
</Value>
<Value name="3">
<Value>SecurityRole</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.JobD</DataLocation>
<DefaultData>JobDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.JobD</IdLocation>
<IndexLocation>^Wasabi.Data.JobI</IndexLocation>
<StreamLocation>^Wasabi.Data.JobS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

