/// Sample data for Zen sample pages.
Class ZENDemo.Data.Address Extends (%SerialObject, %Populate) [ Inheritance = right ]
{

Property Street As %String(MAXLEN = 100);

Property City As %String(MAXLEN = 100);

Property State As %String(MAXLEN = 2);

Property ZIP As %String(MAXLEN = 12, POPSPEC = "USZip()");

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
<Value>Street</Value>
</Value>
<Value name="4">
<Value>ZIP</Value>
</Value>
</Data>
<State>AddressState</State>
<StreamLocation>^ZENDemo.Data.AddressS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

