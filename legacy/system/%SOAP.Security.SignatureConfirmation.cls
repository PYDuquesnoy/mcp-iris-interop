/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// WS-Security 1.1 SignatureConfirmation element for SOAP Security header.
Class %SOAP.Security.SignatureConfirmation Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/oasis-wss-wssecurity-secext-1.1.xsd";

Property Value As %xsd.base64Binary(CANONICALXML = 1, XMLPROJECTION = "attribute") [ Internal ];

/// Create a SignatureConfirmation element
ClassMethod Create(value As %xsd.base64Binary) As %SOAP.Security.SignatureConfirmation
{
	Set confirm=..%New()
	Set confirm.Value=$get(value)
	Quit confirm
}

/// Validate the security header element during import of Security header.
/// SubjectConfirmation is always considered Ok at this point.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	Quit ""
}

/// Validate the security header element during overall validation for client.
/// If valid return true.
Method Validate(service As %SOAP.WebBase) As %String [ Internal ]
{
	Set valid=0
	If ..Value="" {
		If ((service.SecurityOut="") || (service.SecurityOut.FindElement("Signature")="")) {
			Set valid=1
			$$$SOAPLogSecurity("    SignatureConfirmation is valid for no signatures")
		} Else {
			$$$SOAPLogSecurity("    SignatureConfirmation is invalid: no signatures expected")
		}

	} ElseIf service.SecurityOut'="" {
		#dim signature As %XML.Security.Signature
		Set (pos,num)=0
		For {
			Set signature=service.SecurityOut.FindElement("Signature",.pos)
			If '$isobject(signature) Quit
			Set num=num+1
			If signature.SignatureValue=..Value {
				Set signature.Confirmed=1
				Set valid=1
				$$$SOAPLogSecurity("    SignatureConfirmation is valid: Signature number="_num)
				Quit
			}
		}
	}
	
	Quit valid
}

}
