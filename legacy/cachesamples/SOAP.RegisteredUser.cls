/// UserID and password for registered user in LicenseInfo SOAP header
Class SOAP.RegisteredUser Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right ]
{

/// NAMESPACE specifies the XML namespace to be used when creating the header.
Parameter NAMESPACE = "http://ws.strikeiron.com";

Property UserID As %String;

Property Password As %String;

}

