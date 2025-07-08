/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// XML KeyInfo type of RSAKeyValue.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.RSAKeyValue Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property Modulus As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal, Required ];

Property Exponent As %XML.Security.CryptoBinary(XMLREF = 1) [ Internal, Required ];

/// Return true if the same credentials -- same RSA public key in this case.
/// credentials may be either a %XML.Security.RSAKeyValue instance, 
/// a %SYS.X509Credentials instance or a certificate.
Method Equals(credentials As %XML.Security.RSAKeyValue) As %Boolean
{
	If '$isobject(credentials) {
		// credentials is a certificate
		If ..Modulus'=$System.Encryption.X509GetField(credentials,"RSAPublicKeyModulus") Quit 0
		If ..Exponent'=$System.Encryption.X509GetField(credentials,"RSAPublicKeyExponent") Quit 0
	} ElseIf credentials.%Extends("%XML.Security.RSAKeyValue") {
		If ..Modulus'=credentials.Modulus Quit 0
		If ..Exponent'=credentials.Exponent Quit 0
	} ElseIf credentials.%Extends("%SYS.X509Credentials") {
		If ..Modulus'=$System.Encryption.X509GetField(credentials.Certificate,"RSAPublicKeyModulus") Quit 0
		If ..Exponent'=$System.Encryption.X509GetField(credentials.Certificate,"RSAPublicKeyExponent") Quit 0
	} Else {
		Quit 0
	}
	
	Quit 1
}

/// Validate and return the RSA public key.
/// If valid, set credentials argument to this instance and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	Set credentials=""
	If (..Modulus="") || (..Exponent="") {
		$$$SOAPLogSecurity("    Empty Modulus or Exponent not supported for X509IssuerSerial.")
		Quit "UnsupportedAlgorithm"
	}

	// Return the public key.
	Set credentials=$this
	
	Set tokenType="KeyValue"
	Quit ""
}

}
