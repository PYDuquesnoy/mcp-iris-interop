/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// KeyIdentifier reference for SOAP Security header.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.Security.KeyIdentifier Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

Property Identifier As %String(CONTENT = "escape", MAXLEN = "", XMLPROJECTION = "content");

Method IdentifierGet() As %String [ CodeMode = expression, Internal ]
{
$select(i%Identifier=$c(0):"",1:i%Identifier)
}

Property EncodingType As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ InitialExpression = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary" ];

Property ValueType As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property Id As %String(MAXLEN = "", REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

/// Validate and get the certificate from a KeyIdentifier
/// with either SubJectKeyIdentifier or ThumbprintSHA1.
/// If valid, set credentials argument and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	Set credentials=""
	If ..Identifier'="" {
		If ..ValueType=$$$SOAPWSThumbprint {
			Set credentials=##class(%SYS.X509Credentials).GetByThumbprint($system.Encryption.Base64Decode(..Identifier))
			Set tokenType=$$$SOAPWSX509v3
		} ElseIf ..ValueType=$$$SOAPWSSubjectKeyIdentifier {
			Set credentials=##class(%SYS.X509Credentials).GetBySubjectKeyIdentifier($system.Encryption.Base64Decode(..Identifier))
			Set tokenType=$$$SOAPWSX509v3
		} ElseIf ..ValueType=$$$SOAPWSEncryptedKeySHA1 {
			Set credentials=$system.Encryption.Base64Decode(..Identifier)
			Set tokenType=$$$SOAPWSEncryptedKeySHA1
		} ElseIf $isobject($get(%SOAPSecurityHeader)),
		         ((tokenType=$$$SOAPWSSAML) || (..ValueType=$$$SOAPWSSAMLASSERTION) || (..ValueType=$$$SOAPWSSAMLASSERTION10)) {
			Set token=%SOAPSecurityHeader.GetElementById(..Identifier)
			If token="" {
				$$$SOAPLogSecurity("    token not found type="_..ValueType)
				Quit "UnsupportedSecurityToken"
			}
			If $zobjclass(token)'="%SAML.Assertion" {
				$$$SOAPLogSecurity("    Unexpected token found instead for type="_..ValueType)
				Quit "UnsupportedSecurityToken"
			}
			Set credentials=token.X509Credentials
			Set tokenType=$$$SOAPWSSAML
		} Else {
			$$$SOAPLogSecurity("    unexpected KeyIdentifier type="_..ValueType)
			Quit "UnsupportedAlgorithm"
		}
	}
	
	Quit ""
}

/// Get description string for logging
Method GetLoggingString() As %String [ CodeMode = expression, Internal ]
{
..ValueType_" ("_..Identifier_")"
}

}
