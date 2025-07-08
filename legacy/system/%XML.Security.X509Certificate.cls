/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// X509Certificate X509Data element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.X509Certificate Extends %XML.Security.X509DataElement [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property value As %xsd.base64Binary(XMLPROJECTION = "content") [ Internal ];

/// Create an element based on X509 credentials
ClassMethod Create(credentials As %SYS.X509Credentials) As %XML.Security.X509Certificate
{
	Set element=..%New()
	Set element.value=credentials.Certificate
	Quit element
}

/// Validate and get the certificate.
/// If valid, set credentials argument and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	Set credentials=""
	If ..value="" {
		$$$SOAPLogSecurity("    Empty certificate not supported for X509Certificate.")
		Quit "UnsupportedAlgorithm"
	}

	// Return the certificate.
	Set credentials=##class(%SYS.X509Credentials).%New()
	Set credentials.Certificate=..value
	
	Set tokenType=$$$SOAPWSX509v3
	Quit ""
}

}
