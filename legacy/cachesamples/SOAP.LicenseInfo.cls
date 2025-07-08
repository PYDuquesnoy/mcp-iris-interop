/// License information SOAP header
Class SOAP.LicenseInfo Extends %SOAP.Header
{

/// NAMESPACE specifies the XML namespace to be used when creating the header.
Parameter NAMESPACE = "http://tempuri.org/headers";

Property UnregisteredUser As SOAP.UnregisteredUser;

Property RegisteredUser As SOAP.RegisteredUser;

}

