/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Binary Security Token for SOAP Security header.
Class %SOAP.Security.BinarySecurityToken Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

Property Token As %xsd.base64Binary(XMLPROJECTION = "content");

Property EncodingType As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ InitialExpression = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary" ];

Property ValueType As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// If token is based on X509 certificate, this is the X509 credentials class.
Property X509Credentials As %SYS.X509Credentials(XMLPROJECTION = "none") [ Internal ];

/// Return the value of the Id property.
/// Populate the Id property if it is not yet set.
Method GetId() As %String [ Internal ]
{
	If ..Id="" Set ..Id="SecurityToken-"_$system.Util.CreateGUID()
	Quit ..Id
}

/// Keep Id for BinarySecurityToken
Method Reset() [ Internal ]
{
}

/// Create a BinarySecurityToken element that contains an X509 certificate.
ClassMethod CreateX509Token(credentials As %SYS.X509Credentials) As %SOAP.Security.BinarySecurityToken
{
	If credentials="" Quit ""
	
	Set token=..%New()
	Set token.X509Credentials=credentials
	Set token.Token=credentials.Certificate
	Set token.ValueType=$$$SOAPWSX509v3
	Quit token
}

/// Validate the security header element.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	If ..Token="" {
		$$$SOAPLogSecurity("Security BinarySecurityToken - empty token")
		Quit "InvalidSecurityToken"
	}
	$$$SOAPLogSecurity("Security BinarySecurityToken validated")
	Quit ""
}

}
