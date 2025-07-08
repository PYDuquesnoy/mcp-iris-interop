/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// X509SKI X509Data element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.X509SKI Extends %XML.Security.X509DataElement [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property value As %xsd.base64Binary(XMLPROJECTION = "content") [ Internal ];

/// Create an element based on X509 credentials
ClassMethod Create(credentials As %SYS.X509Credentials) As %XML.Security.X509SKI
{
	Set element=..%New()
	Set element.value=credentials.SubjectKeyIdentifier
	Quit element
}

/// Validate and get the certificate with a SubJectKeyIdentifier.
/// If valid, set credentials argument and tokenType and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	// Return the certificate.
	Set credentials=##class(%SYS.X509Credentials).GetBySubjectKeyIdentifier(..value)
	If credentials="" {
		$$$SOAPLogSecurity("    certificate not found for X509DataSKI")
		Quit "SecurityTokenUnavailable"
	}
	
	Set tokenType=$$$SOAPWSX509v3
	Quit ""
}

}
