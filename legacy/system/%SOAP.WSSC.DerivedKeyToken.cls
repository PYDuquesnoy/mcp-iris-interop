/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// DerivedKeyToken from WS-SecureConversation 1.4.
Class %SOAP.WSSC.DerivedKeyToken Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-secureconversation/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsc";

Property SecurityTokenReference As %SOAP.Security.SecurityTokenReference(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd", XMLREF = 1);

Property Properties As %SOAP.WSSC.Properties;

Property Generation As %xsd.unsignedLong;

Property Offset As %xsd.unsignedLong;

Property Length As %xsd.unsignedLong;

Property Label As %String(MAXLEN = "");

Property Nonce As %xsd.base64Binary;

Property Algorithm As %xsd.anyURI(XMLPROJECTION = "attribute");

/// Set Implied property = 1 to indicate make this an implied DerivedKeyToken.
/// Am implied DerivedKeyToken should not be included in token list of Security header.
Property Implied As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// ReferenceOption argument from the Create call.
Property ReferenceOption As %String(XMLPROJECTION = "none") [ Internal ];

/// The key element which contains the key material to use for creating the Key.
/// The type of this property depends on the reference option.
Property KeyElement As %SOAP.Security.Element(XMLPROJECTION = "none") [ Internal ];

/// The symmetric derived key.
Property Key As %Binary(XMLPROJECTION = "none") [ Internal ];

/// Create a DerivedKeyToken element that is to be referenced from an
/// EncryptedKey, EncryptedData or Signature element and that is to carry
/// a key derived from a symmetric key specified by its SecurityTokenReference element.<br><br>
/// The properties of %SOAP.WSSC.DerivedKeyToken instance may be set after the instance is created.
/// The SecurityTokenReference is set by the Create method.  The other properties default as specified by
/// WS-SecureConversation.  If not otherwise set, the Nonce property defaults to a 16 octet random binary string.
/// <ul>
/// <li>keyElement is the Security element which will supply the symmetric key:
/// either an EncryptedKey or SecurityContextToken element.
/// The required keyElement type depends on referenceOption specified.  See referenceOption for details.</li>
/// <li>The referenceOption argument specifies the type of reference which will be in the SecurityTokenReference.
/// <ul>
/// <li>$$$SOAPWSReferenceEncryptedKey is reference to an EncryptedKey element in this message.
/// The keyElement argument must be specified and is the EncryptedKey element.</li>
/// <li>$$$SOAPWSReferenceEncryptedKeySHA1 is reference by the SHA1 hash of the key contained
/// in the EncryptedKey element specified as the first argument.
/// If the keyElement is not specified, the key from the first EncryptedKey element in the received message
/// is used.</li>
/// <li>$$$SOAPWSReferenceDerivedKey is reference to a DerivedKeyToken element in this message.
/// The keyElement argument must be specified and is the DerivedKeyToken element.</li>
/// <li>$$$SOAPWSReferenceSCT is reference by wsu:Id to a SecurityContextToken element in this message.
/// The keyElement argument must be specified and is the SecurityContextToken element.</li>
/// <li>$$$SOAPWSReferenceSCTIdentifier is reference by Identifier and Instance to a SecurityContextToken
/// element not necessarily in this message.
/// The keyElement argument must be specified and is the SecurityContextToken element.</li>
/// <li>If referenceOption is "" or not specified, no SecurityTokenReference is created.</li>
/// </ul>
/// </ul>
ClassMethod Create(keyElement As %SOAP.Security.Element = "", referenceOption As %Integer = "") As %SOAP.WSSC.DerivedKeyToken
{
	Set element=..%New()

	If $get(referenceOption)="" {
		Set secref=""
	} ElseIf referenceOption=$$$SOAPWSReferenceEncryptedKeySHA1 {
		If keyElement'="",('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="EncryptedKey")) Quit ""
		Set cipher=$select(keyElement="":"",1:keyElement.CipherData.CipherValue)
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetKeyIdentifier($$$SOAPWSEncryptedKeySHA1,cipher)
	} ElseIf referenceOption=$$$SOAPWSReferenceEncryptedKey {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="EncryptedKey")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId())
	} ElseIf referenceOption=$$$SOAPWSReferenceDerivedKey {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="DerivedKeyToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId())
	} ElseIf referenceOption=$$$SOAPWSReferenceSCT {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="SecurityContextToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId(),$$$SOAPWSSCToken)
	} ElseIf referenceOption=$$$SOAPWSReferenceSCTIdentifier {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="SecurityContextToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetSCTReference(keyElement)
	} Else {
		// Unknown reference option
		Quit ""
	}

	Set element.ReferenceOption=referenceOption
	Set element.Id="Enc-"_$system.Util.CreateGUID()
	If secref'="" {
		Set element.SecurityTokenReference=secref
		Set element.KeyElement=keyElement
	}
	
	Quit element
}

/// Initialize
Method InitializeForService(service As %SOAP.WebBase, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Initialize the derived key.
Method InitializeKey(service As %SOAP.WebBase, algorithm As %String) As %Status [ Internal ]
{
	// Just return if key already initialized
	If ..Key'="" Quit $$$OK
	
	// Initialize from EncryptedKey element
	If (..KeyElement="") || (..KeyElement.Key="") {
		If ..ReferenceOption=$$$SOAPWSReferenceDerivedKey {
			If $isobject(..KeyElement) {
				If ..KeyElement.Key="" {
					Set sc=..KeyElement.InitializeKey(service,.algorithm)
					If $$$ISERR(sc) Quit sc
				}
				If ..KeyElement.Implied {
					Set ..SecurityTokenReference=..KeyElement.SecurityTokenReference
					Set ..SecurityTokenReference.Nonce=..Nonce
					Set ..SecurityTokenReference.Length=..Length
				}
			}
		} ElseIf $case(..ReferenceOption,$$$SOAPWSReferenceEncryptedKey:1,$$$SOAPWSReferenceSCT:1,$$$SOAPWSReferenceSCTIdentifier:1,:0) {
			If $isobject(..KeyElement) {
				If ..KeyElement.Key="" {
					Set sc=..KeyElement.InitializeKey(service,.algorithm)
					If $$$ISERR(sc) Quit sc
				}
			}
		} ElseIf ..ReferenceOption=$$$SOAPWSReferenceEncryptedKeySHA1,$isobject($get(service)) {
			Set requestHeader=service.SecurityIn
			If $isobject(requestHeader) {
				Set element=requestHeader.FindEncryptedKey(0)
				If $isobject(element) {
					If element.Key="" {
						Set sc=element.InitializeKey(service)
						If $$$ISERR(sc) Quit sc
					}
					Set ..KeyElement=element
					If element.CipherData'="" Do ..SecurityTokenReference.SetIdentifier(element.CipherData.CipherValue)
				}
			}
		}
	}

	If ..KeyElement.Key="" {
		$$$SOAPLogSecurity("    No key in token referenced by DerivedKeyToken.")
		Set ..Key=""
		Quit $$$ERROR($$$WSSCInvalidDerivedKey," No key found")
	}
	
	// If no Nonce generate a random Nonce
	If ..Nonce="" {
		Set ..Nonce=$system.Encryption.GenCryptRand(16,0)
	}
	
	If $get(algorithm)'="" {
		If ..Length="",..Offset="",..Generation="" {
			If algorithm=$$$SOAPWShmacsha1 {
				Set ..Length=24,..Offset=0
			} ElseIf algorithm=$$$SOAPWShmacsha256 {
				Set ..Length=32,..Offset=0
			} ElseIf algorithm=$$$SOAPWShmacsha384 {
				Set ..Length=48,..Offset=0
			} ElseIf algorithm=$$$SOAPWShmacsha512 {
				Set ..Length=64,..Offset=0
			} ElseIf algorithm=$$$SOAPWSaes128cbc {
				Set ..Length=128/8,..Offset=0
			} ElseIf algorithm=$$$SOAPWSaes192cbc {
				Set ..Length=192/8,..Offset=0
			}
		}
		Set ..Key=..ComputeDerivedKey(..KeyElement.Key,.error)
		If error'="" {
			Quit $$$ERROR($$$WSSCInvalidDerivedKey,error)
		}
	}
	
	Quit $$$OK
}

/// Compute DerivedKey based on properties of this class
Method ComputeDerivedKey(basekey As %Binary, Output error As %String) As %Binary [ Internal ]
{
	Set error=""
	
	If ..Generation'="",..Offset'="" {
		Set error="Both Generation and Offset may not be specified"
		$$$SOAPLogSecurity("    "_error)
		Quit ""
	}
	
	If ..Algorithm'="",..Algorithm'=$$$SOAPWSDerivedKeyPSHA1 {
		Set error="Unexpected Algorithm """_..Algorithm_""""
		$$$SOAPLogSecurity("    "_error)
		Quit ""
	}
	
	Set length=..Length
	If length="" Set length=32
	
	Set offset=..Offset
	If offset="" {
		If ..Generation="" {
			Set offset=0
		} Else {
			Set offset=length*..Generation
		}
	}
	
	Set label=..Label
	If label="" {
		Set label="WS-SecureConversationWS-SecureConversation"
	} ElseIf label=$char(0) {
		Set label=""
	}
	
	If ..Nonce="" {
		Set error="Nonce must be specified"
		$$$SOAPLogSecurity("    "_error)
		Quit ""
	}
	
	Set psha1=..PSHA1(basekey,label_..Nonce,offset+length)
	Quit $extract(psha1,offset+1,offset+length)
}

/// Compute P_SHA-1 from RFC 2246.
/// Return computation of function of specified length.
ClassMethod PSHA1(secret As %Binary, seed As %Binary, length As %Integer) As %Binary [ Internal ]
{
	Set result=""
	Set Ai=seed
	For {
		Set Ai=$system.Encryption.HMACSHA1(Ai,secret)
		Set result=result_$system.Encryption.HMACSHA1(Ai_seed,secret)
		If $length(result)>=length Quit
	}
	Quit result
}

/// Validate the derived key.
/// If invalid return an error code.
Method ValidateKey(service As %SOAP.WebBase) As %String [ Internal ]
{
	// Just return if key already initialized
	If ..Key'="" Quit ""
	
	$$$SOAPLogSecurity("Validate DerivedKey:")
	Set invalid="InvalidSecurityToken"
	Set unsupported="UnsupportedAlgorithm"

	Set secref=..SecurityTokenReference
	If '$isobject(secref) {
		$$$SOAPLogSecurity("    no SecurityTokenReference")
		Quit invalid
	}
	
	Set error=secref.ValidateTokenRef(service,.tokenType,.credentials)
	If error'="" Quit error

	If tokenType=$$$SOAPWSEncryptedKeySHA1 {
		Set requestHeader=$select($isobject(service):service.SecurityOut,1:"")
		If $isobject(requestHeader) {
			Set encryptedKey=requestHeader.FindByEncryptedKeySHA1(credentials)
			If $isobject(encryptedKey) {
				Set basekey=encryptedKey.Key
				Set ..KeyElement=encryptedKey
			} Else {
				$$$SOAPLogSecurity("    #EncryptedKeySHA1 does not reference an EncryptedKey in web client message.")
				Quit invalid
			}
		} Else {
			$$$SOAPLogSecurity("    #EncryptedKeySHA1 EncryptedData supported only in web client with EncryptedKey.")
			Quit unsupported
		}
	} ElseIf tokenType=$$$SOAPWSEncryptedKey {
		If $zobjclass(credentials)'="%XML.Security.EncryptedKey" {
			$$$SOAPLogSecurity("    #EncryptedKey does not reference an EncryptedKey from Security header.")
			Quit invalid
		}
	} ElseIf tokenType=$$$SOAPWSDerivedKey {
		If $zobjclass(credentials)'="%SOAP.WSSC.DerivedKeyToken" {
			$$$SOAPLogSecurity("    #DerivedKey does not reference a DerivedKeyToken from Security header.")
			Quit invalid
		}
	} ElseIf tokenType=$$$SOAPWSSCToken {
		If $zobjclass(credentials)'="%SOAP.WSSC.SecurityContextToken" {
			$$$SOAPLogSecurity("    SecurityContextToken Identifier does not reference a known SecurityContextToken.")
			Quit invalid
		}
	} Else {
		$$$SOAPLogSecurity("    KeyInfo must be #EncryptedKeySHA1, #EncryptedKey, DerivedKeyToken or SecurityContextToken for EncryptedData not referenced by EncryptedKey.")
		Quit unsupported
	}
	
	If '$data(basekey) {
		// X509Credentials contains an EncryptedKey, DerivedKey or SecurityContextToken element
		Set error=credentials.ValidateKey(service)
		If error'="" Quit error
		Set basekey=credentials.Key
		Set ..KeyElement=credentials
	}
	
	If basekey="" {
		$$$SOAPLogSecurity("    No key found in referenced token.")
		Quit invalid
	}

	Set ..Key=..ComputeDerivedKey(basekey,.error)
	Quit error
}

/// Validate the security header element.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	Quit ..ValidateKey(service)
}

/// Reset the element.
Method Reset()
{
	Do ##super()
	
	Set (..Key,..Nonce)=""
}

/// Return true if the same Key.
Method Equals(credentials As %SOAP.WSSC.DerivedKeyToken) As %Boolean
{
	Quit ($isobject(credentials) && (credentials.Key=..Key))
}

}
