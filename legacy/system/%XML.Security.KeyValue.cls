/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// XML KeyInfo type of KeyValue.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.KeyValue Extends %XML.Security.KeyInfoClause [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property KeyValue As %XML.Adaptor(XMLCHOICELIST = "%XML.Security.DSAKeyValue,%XML.Security.RSAKeyValue", XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice") [ Internal ];

/// Create a KeyValue containing a RSAKeyValue from a certificate
ClassMethod GetRSAKeyValue(credentials As %SYS.X509Credentials) As %XML.Security.KeyValue
{
	Set key=..%New()
	Set rsa=##class(%XML.Security.RSAKeyValue).%New()
	Set rsa.Modulus=$System.Encryption.X509GetField(credentials.Certificate,"RSAPublicKeyModulus")
	Set rsa.Exponent=$System.Encryption.X509GetField(credentials.Certificate,"RSAPublicKeyExponent")
	Set key.KeyValue=rsa
	Quit key
}

/// Validate this input KeyValue KeyInfo clause.
/// If valid, set credentials and tokenType and return "".  credentials is either %SYS.X509Credentials or %Binary
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, Output credentials As %RawString) As %String [ Internal ]
{
	Set error=""
	Set credentials=""
	Set tokenType=""
	
	Set element=..KeyValue
	If $zobjclass(element)'="%XML.Security.RSAKeyValue" {
		$$$SOAPLogSecurity("    Unexpected child element of KeyValue")
		Set error="UnsupportedAlgorithm"
		Quit
	}
		
	Set error=element.ValidateTokenRef(service,.tokenType,.credentials)
		
	Quit error
}

}
