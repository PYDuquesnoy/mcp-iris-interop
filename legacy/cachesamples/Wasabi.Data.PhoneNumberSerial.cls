Class Wasabi.Data.PhoneNumberSerial Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right ]
{

Property CountryCode As %String;

Property PhoneNumberSerial As %String;

Property Type As %String(VALUELIST = ",HOME,BUSINESS,CELL");

Property Extension As %String;

Storage Default
{
<Data name="PhoneNumberSerialState">
<Value name="1">
<Value>CountryCode</Value>
</Value>
<Value name="2">
<Value>PhoneNumberSerial</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
<Value name="4">
<Value>Extension</Value>
</Value>
</Data>
<State>PhoneNumberSerialState</State>
<StreamLocation>^Wasabi.Data.PhoneNumberSerialS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

