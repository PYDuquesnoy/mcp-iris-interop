/// Category for products
Class Wasabi.Data.Category Extends %Persistent
{

Property Name As %String;

Property Description As %String;

Storage Default
{
<Data name="CategoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.CategoryD</DataLocation>
<DefaultData>CategoryDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.CategoryD</IdLocation>
<IndexLocation>^Wasabi.Data.CategoryI</IndexLocation>
<StreamLocation>^Wasabi.Data.CategoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

