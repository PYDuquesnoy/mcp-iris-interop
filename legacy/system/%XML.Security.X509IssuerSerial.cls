/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// X509IssuerSerial X509Data element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.X509IssuerSerial Extends %XML.Security.X509DataElement [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property X509IssuerName As %String(CONTENT = "escape", MAXLEN = "");

/// Store big integer as string
Property X509SerialNumber As %String(CONTENT = "escape");

/// Create an element based on X509 credentials
ClassMethod Create(credentials As %SYS.X509Credentials) As %XML.Security.X509IssuerSerial
{
	Set element=..%New()
	Set element.X509IssuerName=credentials.IssuerDN
	Set element.X509SerialNumber=credentials.SerialNumber
	Quit element
}

/// Validate and get the certificate with a Issuer Distinguished Name and Serial Number.
/// If valid, set credentials argument and tokenType and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	Set credentials=""
	If (..X509IssuerName="") || (..X509SerialNumber="") {
		$$$SOAPLogSecurity("    Empty Issuer Distinguished Name or Serial Number not supported for X509IssuerSerial.")
		Quit "UnsupportedAlgorithm"
	}

	// Return the certificate.
	Set list=##class(%SYS.X509Credentials).FindByField("SerialNumber",..X509SerialNumber)
	If list.Count()>0 {
		Set list=##class(%SYS.X509Credentials).FindByField("IssuerDN",..X509IssuerName,list)
	}
	If list.Count()'=1 {
		$$$SOAPLogSecurity("    a single unique certificate not found for X509IssuerSerial: "_..X509IssuerName_":"_..X509SerialNumber)
		Quit "SecurityTokenUnavailable"
	}
	Set credentials=list.GetAt(1)
	
	Set tokenType=$$$SOAPWSX509v3
	Quit ""
}

}
