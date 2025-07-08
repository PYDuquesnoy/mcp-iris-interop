Class Wasabi.Data.InventoryCategory Extends %Persistent
{

Property Name As %String;

Storage Default
{
<Data name="InventoryCategoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.InventoryCategoryD</DataLocation>
<DefaultData>InventoryCategoryDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.InventoryCategoryD</IdLocation>
<IndexLocation>^Wasabi.Data.InventoryCategoryI</IndexLocation>
<StreamLocation>^Wasabi.Data.InventoryCategoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

