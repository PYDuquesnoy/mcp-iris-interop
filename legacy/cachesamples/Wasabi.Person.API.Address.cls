Class Wasabi.Person.API.Address Extends %RegisteredObject
{

Property ID As %String;

/// Flesh Out Values
Property Type As %String(VALUELIST = ",Home,Shipping,Billing");

Property PostalCode As %String;

Property Street1 As %String [ Required ];

Property Street2 As %String;

Property City As %String;

Property Region As %String;

Property Country As %String;

}

