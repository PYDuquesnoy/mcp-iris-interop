/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Reference element in SecurityTokenReference for SOAP Security header.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.Security.Reference Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

/// Instance for WS-SecureConversation
Property Instance As %String(MAXLEN = "", REFNAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-secureconversation/200512", XMLPROJECTION = "attribute", XMLREF = 1);

Property URI As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property ValueType As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property Token As %RegisteredObject(XMLPROJECTION = "none") [ Internal ];

/// Validate and get the certificate from a local direct reference.
/// If valid, set credentials argument and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	If $isobject(..Token) {
		// Token already established by caller
		Set token=..Token
		Set uri="[implied]"
	} Else {
		// Get the referenced token
		Set uri=..URI
		If $extract(uri)="#" {
			// Only may be used in WS-Security context if local reference
			If '$isobject($get(%SOAPSecurityHeader)) {
				$$$SOAPLogSecurity("    WS-Security Reference element using local reference is only valid in Security header.")
				Quit "UnsupportedAlgorithm"
			}
			Set token=%SOAPSecurityHeader.GetElementById($extract(uri,2,*))
		} ElseIf $isobject(service),service.%Extends("%SOAP.WebClient") {
				Set sct=service.SecurityContextToken
				If '$isobject(sct) {
					$$$SOAPLogSecurity("    No Client SecurityContextToken found.")
				} ElseIf sct.Identifier=uri,sct.Instance=..Instance {
					Set token=sct
				} Else {
					$$$SOAPLogSecurity("    Client SecurityContextToken not matched:  Identifier="_sct.Identifier_$select(sct.Instance'="":", Instance="_sct.Instance,1:""))
				}
		} Else {
			Set token=##class(%SOAP.WSSC.SecurityContextToken).Open(uri,..Instance)
			If '$isobject(token) {
				$$$SOAPLogSecurity("    SecurityContextToken expired or not found. URI= "_uri)
			}
		}
		If token="" {
			$$$SOAPLogSecurity("    SecurityTokenReference URI not found.  URI="_uri_$select(..Instance'="":", Instance="_..Instance,1:""))
			Quit "UnsupportedAlgorithm"
		}
	}

	// Validate the TokenType and ValueType using version 1.1 rules.
	Set valueType=..ValueType
	If valueType="" Set valueType=tokenType
	If (valueType=$$$SOAPWSSAMLASSERTION) || (valueType=$$$SOAPWSSAMLASSERTION10) {
		Set valueType=$$$SOAPWSSAML
	}
	Set class=$zobjclass(token)
	If valueType="" {
		If class="%SOAP.Security.BinarySecurityToken" {
			Set valueType=$$$SOAPWSX509v3
		} ElseIf class="%XML.Security.EncryptedKey" {
			Set valueType=$$$SOAPWSEncryptedKey
		} ElseIf class="%SOAP.WSSC.DerivedKeyToken" {
			Set valueType=$$$SOAPWSDerivedKey
		} ElseIf class="%SOAP.WSSC.SecurityContextToken" {
			Set valueType=$$$SOAPWSSCToken
		} Else {
			$$$SOAPLogSecurity("    Unexpected token referenced.  URI="_uri)
			Quit "UnsupportedAlgorithm"
		}
	} Else {
		If (tokenType'="") && (valueType'=tokenType) {
			$$$SOAPLogSecurity("    TokenType must match ValueType if both specified")
			Quit "InvalidSecurityToken"
		}
	}

	If valueType=$$$SOAPWSX509v3 {
		If (class'="%SOAP.Security.BinarySecurityToken") || 
		   ((token.ValueType'="") && (token.ValueType'=valueType)) {
			$$$SOAPLogSecurity("    BinarySecurityToken expected.  URI="_uri)
			Quit "UnsupportedSecurityToken"
		}
		// Return the certificate.
		Set credentials=##class(%SYS.X509Credentials).%New()
		Set credentials.Certificate=token.Token
		Set tokenType=$$$SOAPWSX509v3
	} ElseIf valueType=$$$SOAPWSSAML {
		If class'="%SAML.Assertion" {
			$$$SOAPLogSecurity("    SAML Assertion expected.  URI="_uri)
			Quit "UnsupportedSecurityToken"
		}
		Set credentials=token.X509Credentials
		Set tokenType=$$$SOAPWSSAML
	} ElseIf valueType=$$$SOAPWSEncryptedKey {
		If class'="%XML.Security.EncryptedKey" {
			$$$SOAPLogSecurity("    EncryptedKey expected.  URI="_uri)
			Quit "UnsupportedAlgorithm"
		}
		Set credentials=token
		Set tokenType=$$$SOAPWSEncryptedKey
	} ElseIf valueType=$$$SOAPWSDerivedKey {
		If class'="%SOAP.WSSC.DerivedKeyToken" {
			$$$SOAPLogSecurity("    DerivedKey expected.  URI="_uri)
			Quit "UnsupportedAlgorithm"
		}
		Set credentials=token
		Set tokenType=$$$SOAPWSDerivedKey
	} ElseIf valueType=$$$SOAPWSSCToken {
		If class'="%SOAP.WSSC.SecurityContextToken" {
			$$$SOAPLogSecurity("    SecurityContextToken expected.  URI="_uri)
			Quit "UnsupportedAlgorithm"
		}
		If $isobject($get(%SOAPSecurityHeader)),'$isobject(%SOAPSecurityHeader.SecurityContextToken) {
			Set %SOAPSecurityHeader.SecurityContextToken=token
		}
		Set credentials=token
		Set tokenType=$$$SOAPWSSCToken
	} Else {
		$$$SOAPLogSecurity("    unexpected ValueType="_valueType)
		Quit "UnsupportedAlgorithm"
	}

	Quit ""
}

/// Get description string for logging
Method GetLoggingString() As %String [ CodeMode = expression, Internal ]
{
..ValueType_" ("_..URI_")"
}

}
