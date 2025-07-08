/// EmailAddress only for unregistered user in LicenseInfo SOAP header
Class SOAP.UnregisteredUser Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right ]
{

/// NAMESPACE specifies the XML namespace to be used when creating the header.
Parameter NAMESPACE = "http://ws.strikeiron.com";

Property EmailAddress As %String;

}

