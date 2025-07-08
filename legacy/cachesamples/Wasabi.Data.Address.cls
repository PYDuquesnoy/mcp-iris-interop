Class Wasabi.Data.Address Extends Wasabi.Person.API.AddressUtils [ Abstract ]
{

/// Flesh Out Values
Property Type As %String(VALUELIST = ",Home,Shipping,Billing");

Property PostalCode As %String;

Property Street1 As %String [ Required ];

Property Street2 As %String;

Property City As %String;

Property Region As %String;

Property Country As %String [ InitialExpression = "USA" ];

Method CopyFrom(addr As %RegisteredObject)
{
	
	try {
		set ..City = addr.City
		set ..Country = addr.Country
		set ..Street1 = addr.Street1
		set ..Street2 = addr.Street2
		set ..PostalCode = addr.PostalCode
		set ..Region = addr.Region
		set ..Type = addr.Type
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex

	}
}

}

