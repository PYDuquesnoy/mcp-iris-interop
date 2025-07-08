/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// SecurityTokenReference element for SOAP Security header.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.Security.SecurityTokenReference Extends (%XML.Security.KeyInfoClause, %SOAP.Security.Element) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

Property Reference As list Of %RegisteredObject(XMLCHOICELIST = "%SOAP.Security.Reference,%SOAP.Security.KeyIdentifier,%XML.Security.X509Data", XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property Usage As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property Length As %xsd.unsignedLong(REFNAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-secureconversation/200512", XMLPROJECTION = "attribute", XMLREF = 1);

Property Nonce As %xsd.base64Binary(REFNAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-secureconversation/200512", XMLPROJECTION = "attribute", XMLREF = 1);

Property TokenType As %String(MAXLEN = "", REFNAMESPACE = "http://docs.oasis-open.org/wss/oasis-wss-wssecurity-secext-1.1.xsd", XMLPROJECTION = "attribute", XMLREF = 1);

/// If token is based on X509 certificate, this is the X509 credentials class.
Property X509Credentials As %RawString(XMLPROJECTION = "none") [ Internal ];

/// Create a SecurityTokenReference containing a direct reference with no ValueType.
/// This form is used for reference to EncryptedKey.
ClassMethod GetDirectReference(tokenURI As %String, valueType As %String) As %SOAP.Security.SecurityTokenReference
{
	Set secref=..%New()
	Set ref=##class(%SOAP.Security.Reference).%New()
	Set ref.ValueType=$get(valueType)
	Set ref.URI=tokenURI
	Do secref.Reference.Insert(ref)
	Quit secref
}

/// Create a SecurityTokenReference containing a direct reference to an X.509 BinarySecurityToken
ClassMethod GetX509DirectReference(tokenURI As %String) As %SOAP.Security.SecurityTokenReference
{
	Quit ..GetDirectReference(tokenURI,$$$SOAPWSX509v3)
}

/// Create a SecurityTokenReference containing a remote reference to a SecurityContextToken
ClassMethod GetSCTReference(SCT As %SOAP.WSSC.SecurityContextToken) As %SOAP.Security.SecurityTokenReference
{
	Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference(SCT.Identifier,$$$SOAPWSSCToken)
	Set secref.Reference.GetAt(1).Instance=SCT.Instance
	Quit secref
}

/// Create a SecurityTokenReference containing a direct reference to aSAML Assertion.
ClassMethod GetSAMLDirectReference(tokenURI As %String) As %SOAP.Security.SecurityTokenReference
{
	Set secref=..%New()
	Set ref=##class(%SOAP.Security.Reference).%New()
	Set ref.ValueType=$$$SOAPWSSAMLASSERTION
	Set secref.TokenType=$$$SOAPWSSAML
	Set ref.URI=tokenURI
	Do secref.Reference.Insert(ref)
	Quit secref
}

/// Create a SecurityTokenReference containing a KeyIdentfier
/// If no SecurityTokenReference is returned the status argument is set to the error %Status.
ClassMethod GetX509KeyIdentifier(valueType As %String, credentials As %SYS.X509Credentials, Output status As %Status) As %SOAP.Security.SecurityTokenReference
{
	Set status=$$$OK
	Set secref=..%New()
	Set keyid=##class(%SOAP.Security.KeyIdentifier).%New()
	Set keyid.ValueType=valueType
	If valueType=$$$SOAPWSThumbprint {
		Set keyid.Identifier=$system.Encryption.Base64Encode(credentials.Thumbprint,1)
	} ElseIf valueType=$$$SOAPWSSubjectKeyIdentifier {
		Set keyid.Identifier=$system.Encryption.Base64Encode(credentials.SubjectKeyIdentifier,1)
	} ElseIf (valueType=$$$SOAPWSSAML) && ($zobjclass(credentials)="%SAML.Assertion") {
		Set keyid.Identifier=credentials.SAMLID
		Set keyid.ValueType=$$$SOAPWSSAMLASSERTION
		Set keyid.EncodingType=""
		Set secref.TokenType=$$$SOAPWSSAML
	} Else {
		Set status=$$$ERROR($$$SOAPBadSecurityElement,"Unsupported valueType for KeyIdentifier: "_valueType)
		$$$SOAPLogSecurity("    Unsupported valueType for KeyIdentifier: "_valueType)
		Quit ""
	}
	Do secref.Reference.Insert(keyid)
	Quit secref
}

/// Create a SecurityTokenReference to a SAML token containing a KeyIdentfier
ClassMethod GetSAMLKeyIdentifier(credentials As %SAML.Assertion, type As %String) As %SOAP.Security.SecurityTokenReference
{
	Set secref=..%New()
	Set keyid=##class(%SOAP.Security.KeyIdentifier).%New()
	Set keyid.Identifier=credentials.SAMLID
	Set keyid.ValueType=$get(type,$$$SOAPWSSAMLASSERTION)
	Set keyid.EncodingType=""
	Set secref.TokenType=$$$SOAPWSSAML
	Do secref.Reference.Insert(keyid)
	Quit secref
}

/// Create a SecurityTokenReference containing an X509Data element
/// If no X509Data element is returned the status argument is set to the error %Status.
ClassMethod GetX509Data(valueType As %String, credentials As %SYS.X509Credentials, Output status As %Status) As %SOAP.Security.SecurityTokenReference
{
	Set data=##class(%XML.Security.X509Data).Create(valueType,credentials,.status)
	If data="" Quit ""

	Set secref=..%New()
	Do secref.Reference.Insert(data)
	Quit secref
}

/// Create a SecurityTokenReference containing a KeyIdentfier based on an encrypted key.
ClassMethod GetKeyIdentifier(valueType As %String, value As %Binary) As %SOAP.Security.SecurityTokenReference
{
	Set secref=..%New()
	Set keyid=##class(%SOAP.Security.KeyIdentifier).%New()
	Set keyid.ValueType=valueType
	If valueType=$$$SOAPWSEncryptedKeySHA1 {
		Set secref.TokenType=$$$SOAPWSEncryptedKey
		If value'="" {
			Set keyid.Identifier=$system.Encryption.Base64Encode($system.Encryption.SHA1Hash(value),1)
		} Else {
			Set keyid.Identifier=""
		}
	} Else {
		Quit ""
	}
	Do secref.Reference.Insert(keyid)
	Quit secref
}

/// Set the Identifier of %XML.SecurityTokenReference if it is ""
Method SetIdentifier(key As %Binary) [ Internal ]
{
	For j=1:1:..Reference.Count() {
		Set keyid=..Reference.GetAt(j)
		If ($zobjclass(keyid)="%SOAP.Security.KeyIdentifier") && (keyid.Identifier="") {
			Set keyid.Identifier=$system.Encryption.Base64Encode($system.Encryption.SHA1Hash(key),1)
		}
	}
}

/// Validate this input KeyInfo clause.  Default behavior is to ignore the clause.
/// If valid, set credentials and tokenType and return "".  credentials is either %SYS.X509Credentials or %Binary
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, Output credentials As %RawString, topLevel As %Boolean) As %String [ Internal ]
{
	Set error=""
	Set credentials=""
	Set tokenType=""

	// If Nonce specified, then this is a reference to an implied DerivedKeyToken
	If ..Nonce'="" {
		Set dk=##class(%SOAP.WSSC.DerivedKeyToken).%New()
		Set dk.SecurityTokenReference=$this
		Set dk.Nonce=..Nonce
		Set dk.Length=..Length
		Set dk.Implied=1
		Set (..Nonce,..Length)=""
		Set refs=##class(%ListOfObjects).%New()
		Set ref=##class(%SOAP.Security.Reference).%New()
		Set ref.ValueType=$$$SOAPWSDerivedKey
		Set ref.Token=dk
		Do refs.Insert(ref)
		Set myTokenType=$$$SOAPWSDerivedKey
		Set implied=1
	} Else {
		Set refs=..Reference
		Set myTokenType=..TokenType
		Set implied=0
	}
	
	For iref=1:1:refs.Count() {
		Set ref=refs.GetAt(iref)
		If $case($zobjclass(ref),"%SOAP.Security.Reference":0,"%SOAP.Security.KeyIdentifier":0,"%XML.Security.X509Data":0,:1) {
			$$$SOAPLogSecurity("    only Reference or KeyIdentifier supported in X.509 SecurtyTokenReference")
			Set error="UnsupportedAlgorithm"
			Quit
		}
		
		Set tokenType=myTokenType
		Set error=ref.ValidateTokenRef(service,.tokenType,.validatedCredentials)
		If error'="" Quit
		
		If validatedCredentials="",'$get(topLevel) {
			$$$SOAPLogSecurity("    certificate not found: "_ref.GetLoggingString())
			Set error="SecurityTokenUnavailable"
			Quit
		}
	
		If tokenType=$$$SOAPWSEncryptedKeySHA1 {
			// Return the key identifier
			If credentials="",'$isobject(validatedCredentials) {
				Set credentials=validatedCredentials
				If (myTokenType'="") && (myTokenType'=$$$SOAPWSEncryptedKey) {
					$$$SOAPLogSecurity("    unexpected TokenType="_myTokenType)
					Set error="UnsupportedAlgorithm"
					Quit
				}
			} Else {
				$$$SOAPLogSecurity("    Inconsistent credentials supplied in SecurityTokenReference")
				Set error="InvalidSecurityToken"
				Quit
			}
		} ElseIf (tokenType=$$$SOAPWSEncryptedKey) || ((tokenType=$$$SOAPWSSAML) && ($classname(validatedCredentials)="%XML.Security.EncryptedKey")) {
			// Return the EncryptedKey
			If credentials="",$zobjclass(validatedCredentials)="%XML.Security.EncryptedKey" {
				Set credentials=validatedCredentials
				If $case(myTokenType,"":0,$$$SOAPWSEncryptedKey:0,$$$SOAPWSSAML:0,:1) {
					$$$SOAPLogSecurity("    unexpected TokenType="_myTokenType)
					Set error="UnsupportedAlgorithm"
					Quit
				}
			} Else {
				$$$SOAPLogSecurity("    Inconsistent credentials supplied in SecurityTokenReference")
				Set error="InvalidSecurityToken"
				Quit
			}
		} ElseIf tokenType=$$$SOAPWSSAML,$classname(validatedCredentials)="%SOAP.WST.BinarySecret" {
			// Return the BinarySecret
			If credentials="",$zobjclass(validatedCredentials)="%SOAP.WST.BinarySecret" {
				Set credentials=validatedCredentials
				If $case(myTokenType,"":0,$$$SOAPWSSAML:0,:1) {
					$$$SOAPLogSecurity("    unexpected TokenType="_myTokenType)
					Set error="UnsupportedAlgorithm"
					Quit
				}
			} Else {
				$$$SOAPLogSecurity("    Inconsistent credentials supplied in SecurityTokenReference")
				Set error="InvalidSecurityToken"
				Quit
			}
		} ElseIf tokenType=$$$SOAPWSDerivedKey {
			// Return the DerivedKeyToken
			If credentials="",$zobjclass(validatedCredentials)="%SOAP.WSSC.DerivedKeyToken" {
				Set credentials=validatedCredentials
				If (myTokenType'="") && (myTokenType'=$$$SOAPWSDerivedKey) {
					$$$SOAPLogSecurity("    unexpected TokenType="_myTokenType)
					Set error="UnsupportedAlgorithm"
					Quit
				}
			} Else {
				$$$SOAPLogSecurity("    Inconsistent credentials supplied in SecurityTokenReference")
				Set error="InvalidSecurityToken"
				Quit
			}
		} ElseIf tokenType=$$$SOAPWSSCToken {
			// Return the SecurityContextToken
			If credentials="",$zobjclass(validatedCredentials)="%SOAP.WSSC.SecurityContextToken" {
				Set credentials=validatedCredentials
				If (myTokenType'="") && (myTokenType'=$$$SOAPWSSCToken) {
					$$$SOAPLogSecurity("    unexpected TokenType="_myTokenType)
					Set error="UnsupportedAlgorithm"
					Quit
				}
			} Else {
				$$$SOAPLogSecurity("    Inconsistent credentials supplied in SecurityTokenReference")
				Set error="InvalidSecurityToken"
				Quit
			}
		} ElseIf (tokenType=$$$SOAPWSX509v3) || ((tokenType=$$$SOAPWSSAML) && $case($classname(validatedCredentials),"%XML.Security.EncryptedKey":0,"%SOAP.WST.BinarySecret":0,:1)) {
			// Save the certificate.
			If credentials="" {
				Set credentials=validatedCredentials
				If $case(myTokenType,"":0,$$$SOAPWSX509v3:0,$$$SOAPWSSAML:0,:1) {
					$$$SOAPLogSecurity("    unexpected TokenType="_myTokenType)
					Set error="UnsupportedAlgorithm"
					Quit
				}
	
			} Else {
				If 'credentials.Equals(validatedCredentials) {
					$$$SOAPLogSecurity("    Inconsistent credentials supplied in SecurityTokenReference")
					Set error="InvalidSecurityToken"
					Quit
				}
			}
		} Else {
			$$$SOAPLogSecurity("    ValueType not unsupported: "_tokenType)
			Set error="UnsupportedAlgorithm"
			Quit
		}
	}
	
	If 'implied Set ..TokenType=tokenType

	Quit error
}

/// Validate the SecurityTokenReference element as a direct child of the Security header element.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	Quit ""  ;;..ValidateTokenRef(service,.tokenType,.credentials,1)
}

}
