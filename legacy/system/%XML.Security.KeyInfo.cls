/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// XML Signature element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %XML.Security.KeyInfo Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property KeyInfoClauseList As list Of %XML.Security.KeyInfoClause(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice") [ Internal ];

Property Id As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ Internal ];

/// This property is provided to support parsing of XML
/// containing this tag but not as a means to access the
/// EncryptedKey. The URI value is not validated.
Property RetrievalMethod As %XML.Security.RetrievalMethod(XMLPROJECTION = "element") [ Internal ];

/// <pre>
/// Key material on input is identified by KeyType, TokenType and Credentials:
/// SAML
/// 	TokenType = $$$SOAPWSSAML
/// 	KeyType = $$$SOAPWSX509v3 or $$$SOAPWSEncryptedKey
/// 	Credentials = %XML.Security.RSAKeyValue or %SYS.X509Credentials or %XML.Security.EncryptedKey
/// KeyIdentifier #EncryptedKeySHA1
/// 	TokenType = $$$SOAPWSEncryptedKeySHA1
/// 	KeyType = $$$SOAPWSEncryptedKeySHA1
/// 	Credentials = SHA1 hash of key
/// Direct Reference to #EncryptedKey or contained EncryptedKey element
/// 	TokenType = $$$SOAPWSEncryptedKey
/// 	KeyType = $$$SOAPWSEncryptedKey
/// 	Credentials = %XML.Security.EncryptedKey
/// Direct Reference to #DerivedKey
/// 	TokenType = $$$SOAPWSDerivedKey
/// 	KeyType = $$$SOAPWSDerivedKey
/// 	Credentials = %SOAP.WSSC.DerivedKey
/// Direct Reference  or reference by Identifier to SecurityContextToken
/// 	TokenType = $$$SOAPWSSCToken
/// 	KeyType = $$$SOAPWSSCToken
/// 	Credentials = %SOAP.WSSC.SecurityContextToken
/// Direct Reference  to BinarySecret
/// 	TokenType = $$$SOAPWSTSecretSymKey
/// 	KeyType = $$$SOAPWSTSecretSymKey
/// 	Credentials = %SOAP.WSSC.SecurityContextToken
/// RSA Key Value
/// 	TokenType = "KeyValue"
/// 	KeyType = $$$SOAPWSX509v3
/// 	Credentials = %XML.Security.RSAKeyValue
/// X.509 certificate
/// 	TokenType = $$$SOAPWSX509v3
/// 	KeyType = $$$SOAPWSX509v3
/// 	X509Credentials = %SYS.X509Credentials
/// </pre>
/// Type of key information.
Property KeyType As %String(MAXLEN = "", XMLPROJECTION = "none") [ Internal ];

/// Type of token.
Property TokenType As %String(MAXLEN = "", XMLPROJECTION = "none") [ Internal ];

/// Credentials that stores key information.
/// Name X509Credentials is from original implementation and has been extended to
/// also allow binary key, %XML.Security.RSAKeyValue, %XML.Security.EncryptedKey
/// or %SOAP.WSSC.DerivedKeyToken.
Property X509Credentials As %RawString(XMLPROJECTION = "none") [ Internal ];

/// Create a KeyInfo associated with the specified X509 certificate.<br>
/// - The certificate is specified in the token argument by 
/// a %SYS.X509Credentials instance containing the certificate,
/// a BinarySecurityToken containing the X509 certificate or a SAML Assertion
/// whose SubjectConfirmation is based on X.509 credentials.  
/// A binary security token must be used for a direct reference.<br>
/// - The referenceOption argument specifies the type of reference to create.
/// See %soap.inc definitions of $$$SOAPWSReference.... and $$$KeyInfoX509....
/// The default is to use a direct reference if the first argument is a binary security token or to
/// use the Thumbprint if the first argument is a %SYS.X509Credentials instance.<br>
/// - If no KeyInfo is returned the status argument is set to the error %Status.
ClassMethod CreateX509(ByRef credentials As %SYS.X509Credentials, referenceOption As %Integer, Output status As %Status) As %XML.Security.KeyInfo
{
	Set status=$$$OK
	Set token=credentials
	Set (BinaryToken,SAMLToken)=0
	If $zobjclass(credentials)="%SOAP.Security.BinarySecurityToken" {
		Set credentials=token.X509Credentials
		If $get(referenceOption)="" Set referenceOption=$$$SOAPWSReferenceDirect
		Set BinaryToken=1
	} ElseIf $zobjclass(credentials)="%SAML.Assertion" {
		Set credentials=token.X509Credentials
		If $get(referenceOption)="" Set referenceOption=$$$SOAPWSSAML
		Set SAMLToken=1
	} Else {
		If $get(referenceOption)="" Set referenceOption=$$$SOAPWSReferenceThumbprint
	}
	Set secref=""
	If referenceOption=$$$SOAPWSReferenceDirect {
		If BinaryToken {
			Set secref=##class(%SOAP.Security.SecurityTokenReference).GetX509DirectReference("#"_token.GetId())
		} ElseIf SAMLToken {
			Set secref=##class(%SOAP.Security.SecurityTokenReference).GetSAMLDirectReference("#"_token.GetId())
		}
	} ElseIf SAMLToken {
		If referenceOption=$$$SOAPWSSAML {
			Set secref=##class(%SOAP.Security.SecurityTokenReference).GetSAMLKeyIdentifier(token)
		}
	} ElseIf referenceOption=$$$SOAPWSReferenceKeyIdentifier {
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetX509KeyIdentifier($$$SOAPWSSubjectKeyIdentifier,credentials)
	} ElseIf referenceOption=$$$SOAPWSReferenceThumbprint {
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetX509KeyIdentifier($$$SOAPWSThumbprint,credentials)
	} ElseIf referenceOption=$$$SOAPWSReferenceIssuerSerial {
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetX509Data($$$KeyInfoX509IssuerSerial,credentials,.status)
	} ElseIf referenceOption=$$$KeyInfoRSAKey {
		Set secref=##class(%XML.Security.KeyValue).GetRSAKeyValue(credentials)
	} ElseIf $case(referenceOption,$$$KeyInfoX509Certificate:1,$$$KeyInfoX509IssuerSerial:1,$$$KeyInfoX509SKI:1,$$$KeyInfoX509SubjectName:1,:0) {
		Set secref=##class(%XML.Security.X509Data).Create(referenceOption,credentials,.status)
	} Else {
		Set status=$$$ERROR($$$SOAPBadSecurityElement,"Unsupported reference option: "_referenceOption)
		$$$SOAPLogSecurity("    Unsupported reference option: "_referenceOption)
	}

	If secref'="" {
		#dim keyinfo As %XML.Security.KeyInfo = ..%New()
		Set keyinfo.X509Credentials=credentials
		Do keyinfo.KeyInfoClauseList.Insert(secref)
	} Else {
		Set keyinfo=""
	}

	Quit keyinfo
}

/// Create a KeyInfo containing the specified EncryptedKey.<br>
ClassMethod CreateEncryptedKey(encryptedKey As %XML.Security.EncryptedKey, Output status As %Status) As %XML.Security.KeyInfo
{
	Set status=encryptedKey.Initialize()
	If $$$ISERR(status) Quit ""
	
	#dim keyinfo As %XML.Security.KeyInfo = ..%New()
	Set keyinfo.X509Credentials=encryptedKey
	Do keyinfo.KeyInfoClauseList.Insert(encryptedKey)
	Quit keyinfo
}

/// Create a KeyInfo containing the specified EncryptedKey.<br>
ClassMethod CreateBinarySecret(binarySecret As %SOAP.WST.BinarySecret, Output status As %Status) As %XML.Security.KeyInfo
{
	Set status=binarySecret.Initialize()
	If $$$ISERR(status) Quit ""
	
	#dim keyinfo As %XML.Security.KeyInfo = ..%New()
	Set keyinfo.X509Credentials=binarySecret
	Do keyinfo.KeyInfoClauseList.Insert(binarySecret)
	Quit keyinfo
}

/// Set the Identifier of %XML.SecurityTokenReference if it is ""
Method SetIdentifier(key As %Binary) [ Internal ]
{
	For i=1:1:..KeyInfoClauseList.Count() {
		Set secref=..KeyInfoClauseList.GetAt(i)
		For j=1:1:secref.Reference.Count() {
			Set keyid=secref.Reference.GetAt(j)
			If ($zobjclass(keyid)="%SOAP.Security.KeyIdentifier") && (keyid.Identifier="") {
				Set keyid.Identifier=$system.Encryption.Base64Encode($system.Encryption.SHA1Hash(key))
			}
		}
	}
}

/// Validate this input KeyInfo.
/// If valid, set KeyType, TokenType and Credentials properties to indicate type of KeyInfo and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase = "") As %String [ Internal ]
{
	Set error=""

	Set keys=..KeyInfoClauseList
	If keys="" {
		$$$SOAPLogSecurity("    KeyInfoClause must be specified")
		Quit "UnsupportedAlgorithm"
	}
	Set tokenType=""
	For ikey=1:1:keys.Count() {
		Set clause=keys.GetAt(ikey)
		Set error=clause.ValidateTokenRef(service,.tokenType,.credentials)
		// credentials is either %SYS.X509Credentials or %Binary
		If error'="" Quit
	
		// Save the certificate or encrypted key reference.
		If credentials'="" {
			If ..X509Credentials="" {
				Set ..X509Credentials=credentials
			} Else {
				If $case(tokenType,$$$SOAPWSX509v3:0,$$$SOAPWSEncryptedKey:0,$$$SOAPWSEncryptedKeySHA1:0,$$$SOAPWSDerivedKey:0,$$$SOAPWSSCToken:0,$$$SOAPWSTSecretSymKey:0,"KeyValue":0,:1) {
					$$$SOAPLogSecurity("    Inconsistent credentials supplied in KeyInfo")
					Set error="InvalidSecurityToken"
					Quit
				} Else {
					If '..X509Credentials.Equals(credentials) {
						$$$SOAPLogSecurity("    Inconsistent credentials supplied in KeyInfo")
						Set error="InvalidSecurityToken"
						Quit
					}
					// If RSA public key or certificate and multiple credentials,
					// then prefer certificate over RSA key value and
					// prefer certificate that was found as stored %SYS.X509Credentials.
					If tokenType=$$$SOAPWSX509v3,$classname(credentials)="%SYS.X509Credentials" {
						If $classname(..X509Credentials)'="%SYS.X509Credentials" {
							$$$SOAPLogSecurity("    Replace RSAKeyValue with %SYS.X509Credentials")
							Set ..X509Credentials=credentials
						} ElseIf ..X509Credentials.Alias="",credentials.Alias'="" {
							$$$SOAPLogSecurity("    Use stored %SYS.X509Credentials")
							Set ..X509Credentials=credentials
						}
					}
				}
			}
		}
	
	}
	If error'="" Quit error

	If ..X509Credentials="" {
		If ..RetrievalMethod = "" {
			$$$SOAPLogSecurity("    no supported KeyInfo reference")
			Quit "UnsupportedAlgorithm"
		} Else {
			Quit ""
		}
	}

	Set ..TokenType=tokenType
	
	// Is this SHA1 of EncryptedKey or direct reference to EncryptedKey, DerivedKey or SecurityContextToken
	If $case(tokenType,$$$SOAPWSEncryptedKey:1,$$$SOAPWSEncryptedKeySHA1:1,$$$SOAPWSDerivedKey:1,$$$SOAPWSSCToken:1,$$$SOAPWSTSecretSymKey:1,:0) {
		Set ..KeyType=tokenType
	} ElseIf tokenType=$$$SOAPWSSAML {
		Set class=$classname(..X509Credentials)
		Set ..KeyType=$select(class="%XML.Security.EncryptedKey":$$$SOAPWSEncryptedKey,class="%SOAP.WST.BinarySecret":$$$SOAPWSTSecretSymKey,1:$$$SOAPWSX509v3)
	} Else {
		Set ..KeyType=$$$SOAPWSX509v3
	}

	Quit ""
}

/// Validate this input KeyInfo where a symmetric key is expected.
/// If not valid, return error code.
Method ValidateKeyElement(service As %SOAP.WebBase, Output key As %Binary, signingKey As %Boolean) As %String [ Internal ]
{
	Set invalid="InvalidSecurityToken"
	Set unsupported="UnsupportedAlgorithm"
	Set (error,key)=""

	If ..KeyType=$$$SOAPWSEncryptedKeySHA1 {
		Set requestHeader=$select($isobject(service):service.SecurityOut,1:"")
		If $isobject(requestHeader) {
			Set encryptedKey=requestHeader.FindByEncryptedKeySHA1(..X509Credentials)
			If $isobject(encryptedKey) {
				Set key=encryptedKey.Key
			} Else {
				$$$SOAPLogSecurity("    #EncryptedKeySHA1 does not reference an EncryptedKey in web client message.")
				Quit invalid
			}
		} Else {
			$$$SOAPLogSecurity("    #EncryptedKeySHA1 EncryptedData supported only in web client with EncryptedKey.")
			Quit unsupported
		}
	} ElseIf ..KeyType=$$$SOAPWSEncryptedKey {
		If $zobjclass(..X509Credentials)'="%XML.Security.EncryptedKey" {
			$$$SOAPLogSecurity("    #EncryptedKey does not reference an EncryptedKey from Security header.")
			Quit invalid
		}
		// X509Credenials contains an EncryptedKey element
		Set error=..X509Credentials.ValidateKey(service)
		If error'="" Quit error
		Set key=..X509Credentials.Key
		If $get(signingKey) {
			Set ..X509Credentials.UsedAsSigningKey=1
		} Else {
			Set ..X509Credentials.UsedAsEncryptionKey=1
		}
	} ElseIf ..KeyType=$$$SOAPWSDerivedKey {
		If $zobjclass(..X509Credentials)'="%SOAP.WSSC.DerivedKeyToken" {
			$$$SOAPLogSecurity("    #DerivedKey does not reference a DerivedKeyToken from Security header.")
			Quit invalid
		}
		// X509Credenials contains a DerivedKey element
		Set error=..X509Credentials.ValidateKey(service)
		If error'="" Quit error
		Set key=..X509Credentials.Key
	} ElseIf ..KeyType=$$$SOAPWSSCToken {
		If $zobjclass(..X509Credentials)'="%SOAP.WSSC.SecurityContextToken" {
			$$$SOAPLogSecurity("    SecurityContextToken does not reference a known SecurityContextToken.")
			Quit invalid
		}
		// X509Credenials contains an SecurityContextToken element
		Set error=..X509Credentials.ValidateKey(service)
		If error'="" Quit error
		Set key=..X509Credentials.Key
	} ElseIf ..KeyType=$$$SOAPWSTSecretSymKey {
		If $zobjclass(..X509Credentials)'="%SOAP.WST.BinarySecret" {
			$$$SOAPLogSecurity("    WS-Trust symmetric key does not reference a known BinarySecret.")
			Quit invalid
		}
		// X509Credenials contains an BinarySecret element
		Set error=..X509Credentials.ValidateKey(service)
		If error'="" Quit error
		Set key=..X509Credentials.Key
	} Else {
		If ..RetrievalMethod = "" {
			$$$SOAPLogSecurity("    KeyInfo must be #EncryptedKeySHA1 or #EncryptedKey for EncryptedData not referenced by EncryptedKey.")
			Quit unsupported
		}
	}

	Quit ""
}

}
