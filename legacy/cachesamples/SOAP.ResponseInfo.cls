/// SOAP header for returned response information.
Class SOAP.ResponseInfo Extends %SOAP.Header
{

/// NAMESPACE specifies the XML namespace to be used when creating the header.
/// Note that this header is in the web service namespace, not the header namespace.
Parameter NAMESPACE = "http://tempuri.org";

Property ResponseCode As %xsd.int [ Required ];

Property Response As %String;

}

