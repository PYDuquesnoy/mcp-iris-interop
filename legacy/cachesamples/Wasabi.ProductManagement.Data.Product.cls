/// *************************
/// *** STUBBED OUT CLASS ***
/// *************************
/// 
Class Wasabi.ProductManagement.Data.Product Extends %Persistent
{

Property ProductName As %String;

Property ProductPrice As %Float;

Storage Default
{
<Data name="ProductDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ProductName</Value>
</Value>
<Value name="3">
<Value>ProductPrice</Value>
</Value>
</Data>
<DataLocation>^Wasabi.ProductManaAC89.ProductD</DataLocation>
<DefaultData>ProductDefaultData</DefaultData>
<IdLocation>^Wasabi.ProductManaAC89.ProductD</IdLocation>
<IndexLocation>^Wasabi.ProductManaAC89.ProductI</IndexLocation>
<StreamLocation>^Wasabi.ProductManaAC89.ProductS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

