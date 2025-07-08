Class Wasabi.OrderEntry.Data.OrderAuditLog Extends (%Persistent, %XML.Adaptor) [ Inheritance = right ]
{

Property OrderID As Wasabi.OrderEntry.Data.Orders;

Property EventType As Wasabi.OrderEntry.Data.EventType;

Property InitialTimestamp As %TimeStamp [ InitialExpression = {$zts} ];

/// Group #3 "Person ID" for invoker of auditable event
Property UserId As %String;

/// Group #3 "Sales Person ID"
Property SalesPerson As %String;

Property Comment As %String;

Storage Default
{
<Data name="OrderAuditLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OrderID</Value>
</Value>
<Value name="3">
<Value>EventType</Value>
</Value>
<Value name="4">
<Value>InitialTimestamp</Value>
</Value>
<Value name="5">
<Value>UserId</Value>
</Value>
<Value name="6">
<Value>SalesPerson</Value>
</Value>
<Value name="7">
<Value>Comment</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Order8A57.OrderAuditLogD</DataLocation>
<DefaultData>OrderAuditLogDefaultData</DefaultData>
<IdLocation>^Wasabi.Order8A57.OrderAuditLogD</IdLocation>
<IndexLocation>^Wasabi.Order8A57.OrderAuditLogI</IndexLocation>
<StreamLocation>^Wasabi.Order8A57.OrderAuditLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

