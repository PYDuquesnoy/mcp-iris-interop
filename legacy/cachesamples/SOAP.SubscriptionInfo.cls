/// SOAP header to return subscription information.
Class SOAP.SubscriptionInfo Extends %SOAP.Header
{

/// NAMESPACE specifies the XML namespace to be used when creating the header.
Parameter NAMESPACE = "http://tempuri.org/headers";

Property LicenseStatusCode As %xsd.int;

Property LicenseStatus As %String;

Property LicenseActionCode As %xsd.int;

Property LicenseAction As %String;

Property RemainingHits As %xsd.int;

Property Amount As %xsd.decimal;

}

