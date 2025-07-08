/// Simple example of an embedded class that is also a DataModel.
Class ZENMVC.Address Extends (%SerialObject, %ZEN.DataModel.Adaptor) [ Inheritance = right ]
{

Property City As %String(MAXLEN = 50);

Property State As %String(MAXLEN = 2);

Property Zip As %String(MAXLEN = 15);

Storage Default
{
<Data name="AddressState">
<Value name="1">
<Value>City</Value>
</Value>
<Value name="2">
<Value>State</Value>
</Value>
<Value name="3">
<Value>Zip</Value>
</Value>
</Data>
<State>AddressState</State>
<StreamLocation>^ZENMVC.AddressS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

