/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// RequestSecurityTokenResponse as used for response body in WS-Trust 1.3.
Class %SOAP.WST.RequestSecurityTokenResponse Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wst";

Parameter XMLSEQUENCE = 0;

Parameter XMLIGNOREINVALIDTAG = 1;

Property TokenType As %xsd.anyURI(XMLREF = 1);

Property RequestType As %xsd.anyURI(XMLREF = 1) [ Required ];

Property Context As %xsd.anyURI(XMLPROJECTION = "attribute");

Property RequestedSecurityToken As %SOAP.WST.RequestedSecurityToken;

Property AppliesTo As %XML.String(REFNAMESPACE = "http://www.w3.org/ns/ws-policy", XMLREF = 1);

Property RequestedAttachedReference As %XML.String;

Property RequestedUnattachedReference As %XML.String;

Property RequestedProofToken As %SOAP.WST.RequestedProofToken;

Property Claims As %SOAP.WST.Claims;

Property Entropy As %SOAP.WST.Entropy;

Property Lifetime As %SOAP.WST.Lifetime;

Property Status As %SOAP.WST.Status;

Property RenewTarget As %SOAP.WST.Target;

Property AllowPostdating As %String;

Property Renewing As %SOAP.WST.Renewing;

Property OnBehalfOf As %SOAP.WST.Target;

Property Issuer As %SOAP.Addressing.EndpointReference(REFNAMESPACE = "http://www.w3.org/2005/08/addressing", XMLREF = 1);

Property AuthenticationType As %xsd.anyURI;

Property KeyType As %xsd.anyURI;

Property KeySize As %xsd.unsignedInt;

Property SignatureAlgorithm As %xsd.anyURI;

Property Encryption As %XML.String;

Property EncryptionAlgorithm As %xsd.anyURI;

Property CanonicalizationAlgorithm As %xsd.anyURI;

Property ComputedKeyAlgorithm As %xsd.anyURI;

Property ProofEncryption As %SOAP.WST.Target;

Property KeyWrapAlgorithm As %xsd.anyURI;

Property UseKey As %SOAP.WST.Target;

Property SignWith As %xsd.anyURI;

Property EncryptWith As %xsd.anyURI;

Property DelegateTo As %SOAP.WST.Target;

Property Forwardable As %Boolean;

Property Delegatable As %Boolean;

Property Policy As %SOAP.Policy(REFNAMESPACE = "http://www.w3.org/ns/ws-policy", XMLREF = 1);

Property PolicyReference As %SOAP.PolicyReference(REFNAMESPACE = "http://www.w3.org/ns/ws-policy", XMLREF = 1);

Property Participants As %SOAP.WST.Participants;

Property RequestedTokenCancelled As %String;

/// Create a WS-Trust security fault.
ClassMethod MakeFault(faultCode As %String) As %SOAP.Fault [ ServerOnly = 1 ]
{
	If faultCode="InvalidRequest" {
		Set faultString="The request was invalid or malformed"
	} ElseIf faultCode="FailedAuthentication" {
		Set faultString="Authentication failed"
	} ElseIf faultCode="RequestFailed" {
		Set faultString="The specified request failed"
	} ElseIf faultCode="InvalidSecurityToken" {
		Set faultString="Security token has been revoked"
	} ElseIf faultCode="AuthenticationBadElements" {
		Set faultString="Insufficient Digest Elements"
	} ElseIf faultCode="BadRequest" {
		Set faultString="The specified RequestSecurityToken is not understood."
	} ElseIf faultCode="ExpiredData" {
		Set faultString="The request data is out-of-date"
	} ElseIf faultCode="InvalidTimeRange" {
		Set faultString="The requested time range is invalid or unsupported"
	} ElseIf faultCode="InvalidScope" {
		Set faultString="The request scope is invalid or unsupported"
	} ElseIf faultCode="RenewNeeded" {
		Set faultString="A renewable security token has expired"
	} ElseIf faultCode="UnableToRenew" {
		Set faultString="The requested renewal failed"
	} Else {
		Set faultString="Unknown WS-Trust fault"
	}
	Set fault=##class(%SOAP.WebService).MakeFault(faultCode,faultString,"","")
	
	Set fault.faultcode="wst:"_fault.faultcode
	Set fault.faultPrefixDefinition="xmlns:wst="""_..#NAMESPACE_""""
	Set fault.WSSecurityFault=1
	
	Quit fault
}

/// Process the final Issue response for this request with WS-SecureConversation SecurityContextToken.
/// Return the SecurityContextToken from the response.
/// <ul>
/// <li><var>soapClass</var> is the web client which received the response.</li>
/// <li><var>keysize</var> is the size of the desired key in bytes.  Default is $$$SOAPWSSCDEFAULTKEYSIZE.</li>
/// <li><var>requireServerEntropy</var> is true if the response must include server entropy.
/// <var>requireServerEntropy</var> is false if the response must not include server entropy.</li>
/// <li><var>clientEntropy</var> is %SOAP.WST.Entropy with client entropy or "" if no client entropy.</li>
/// <li><var>status</var> is the returned %Status.
/// </ul>
Method ProcessIssueResponse(soapClass As %SOAP.WebClient, keysize As %Integer, requireServerEntropy As %Boolean, clientEntropy As %SOAP.WST.Entropy = "", Output status As %Status) As %SOAP.WSSC.SecurityContextToken [ Internal ]
{
	New %SOAPSecurityHeader
	Set %SOAPSecurityHeader=soapClass.SecurityIn
	
	Set status=$$$OK

	If ..TokenType'=$$$SOAPWSSCToken {
		$$$SOAPLogSecurity("Unexpected TokenType in SecurityTokenRequestResponse: "_..TokenType)
		Set status=$$$ERROR($$$WSTUnexpectedResponse,"TokenType",..TokenType)
		Quit ""
	}

	If ..RequestType'="",..RequestType'=$$$SOAPWSTIssue {
		$$$SOAPLogSecurity("Unexpected RequestType in SecurityTokenRequestResponse: "_..RequestType)
		Set status=$$$ERROR($$$WSTUnexpectedResponse,"RequestType",..RequestType)
		Quit ""
	}

	If ..AppliesTo'="" Quit ..NotSupported("AppliesTo",.status)
	If ..Claims'="" Quit ..NotSupported("Claims",.status)
	If ..RenewTarget'="" Quit ..NotSupported("RenewTarget",.status)
	If ..AllowPostdating'="" Quit ..NotSupported("AllowPostdating",.status)
	If ..Renewing'="" Quit ..NotSupported("Renewing",.status)
	If ..OnBehalfOf'="" Quit ..NotSupported("OnBehalfOf",.status)
	If ..AuthenticationType'="" Quit ..NotSupported("AuthenticationType",.status)

	If ..KeyType'="",..KeyType'=$$$SOAPWSTSecretSymKey,..KeyType'=$$$SOAPWSTNonce {
		$$$SOAPLogSecurity("Unexpected KeyType in SecurityTokenRequest: "_..KeyType)
		Set status=$$$ERROR($$$WSTUnexpectedResponse,"KeyType",..KeyType)
		Quit ""
	}

	If ..ComputedKeyAlgorithm'="",..ComputedKeyAlgorithm'=$$$SOAPWSTPSHA1 {
		$$$SOAPLogSecurity("Unexpected ComputedKeyAlgorithm in SecurityTokenRequest: "_..ComputedKeyAlgorithm)
		Set status=$$$ERROR($$$WSTUnexpectedResponse,"ComputedKeyAlgorithm",..ComputedKeyAlgorithm)
		Quit ""
	}

	If ..Encryption'="" Quit ..NotSupported("Encryption",.status)
	If ..SignatureAlgorithm'="" Quit ..NotSupported("SignatureAlgorithm",.status)
	If ..EncryptionAlgorithm'="" Quit ..NotSupported("EncryptionAlgorithm",.status)
	If ..CanonicalizationAlgorithm'="" Quit ..NotSupported("CanonicalizationAlgorithm",.status)
	If ..ProofEncryption'="" Quit ..NotSupported("ProofEncryption",.status)
	If ..KeyWrapAlgorithm'="" Quit ..NotSupported("KeyWrapAlgorithm",.status)
	If ..UseKey'="" Quit ..NotSupported("UseKey",.status)
	;;If ..SignWith'="" Quit ..NotSupported("SignWith",.status)
	;;If ..EncryptWith'="" Quit ..NotSupported("EncryptWith",.status)
	If ..DelegateTo'="" Quit ..NotSupported("DelegateTo",.status)
	;;If ..Forwardable'="" Quit ..NotSupported("Forwardable",.status)
	If ..Delegatable'="" Quit ..NotSupported("Delegatable",.status)
	If ..Policy'="" Quit ..NotSupported("Policy",.status)
	If ..PolicyReference'="" Quit ..NotSupported("PolicyReference",.status)
	If ..Participants'="" Quit ..NotSupported("Participants",.status)

	If '$isobject(..RequestedSecurityToken) || '$isobject(..RequestedSecurityToken.token)
	   || ($classname(..RequestedSecurityToken.token)'="%SOAP.WSSC.SecurityContextToken") {
		Set status=$$$ERROR($$$WSTNoToken)
		Quit ""
	}
	Set token=..RequestedSecurityToken.token
	
	Set ts=$ztimestamp
	Set now=$piece(ts,",")*86400+($piece(ts,",",2)\1)
	If ..Lifetime'="" {
		Set expires=$zdth(..Lifetime.Expires,3)
		Set expires=$piece(expires,",")*86400+($piece(expires,",",2)\1)
		If now>expires {
			$$$SOAPLogSecurity("Lifetime.Expires is before current time.  Expires="_..Lifetime.Expires_", Now="_$zdt(ts,3))
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Token has already expired.  Lifetime.Expired="_..Lifetime.Expires_" Now="_$zdt($ztimestamp,3))
			Quit ""
		}
		Set token.ExpiresInSeconds=expires
	} Else {
		// Default expiration is 900 seconds
		Set token.ExpiresInSeconds=now+900
	}
	
	Set (key,clientkey,serverkey)=""
	If $isobject(clientEntropy) {
		If $isobject(clientEntropy.BinarySecret) {
			Set clientkey=clientEntropy.BinarySecret.value
		} ElseIf $isobject(clientEntropy.EncryptedKey) {
			Set clientkey=clientEntropy.EncryptedKey.Key
		}
	}
	If '$isobject(..RequestedProofToken) {
		// Use client entropy
		If requireServerEntropy {
			$$$SOAPLogSecurity("Required Server Entropy was not supplied.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Required Server Entropy was not supplied")
			Quit ""
		}
		If clientkey="" {
			$$$SOAPLogSecurity("Client Entropy must have been in request, since no server entropy.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Client Entropy must have been in request, since no server entropy")
			Quit ""
		}
		Set key=clientkey
		$$$SOAPLogSecurity("      Client Entropy chosen as key.")
	} ElseIf ..RequestedProofToken.ComputedKey'="" {
		// Use ComputedKey based on client and server entropy
		If ..RequestedProofToken.ComputedKey'=$$$SOAPWSTPSHA1 {
			$$$SOAPLogSecurity("ComputedKey expected but not present or invalid value.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"ComputedKey expected but not present or invalid value")
			Quit ""
		}
		If 'requireServerEntropy {
			$$$SOAPLogSecurity("Server Entropy must be supplied for ComputedKey.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Server Entropy must be supplied for ComputedKey")
			Quit ""
		}
		If clientkey="" {
			$$$SOAPLogSecurity("Client Entropy must have been in request to compute key.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Client Entropy must have been in request to compute key")
			Quit ""
		}
		If ..Entropy'="" {
			If ..Entropy.BinarySecret'="" {
				Set serverkey=..Entropy.BinarySecret.value
			} ElseIf ..Entropy.EncryptedKey'="" {
				// Need %SOAPSecurityHeader
				Set error=..Entropy.EncryptedKey.ValidateKey(soapClass)
				If error'="" {
					$$$SOAPLogSecurity("Unable to decrypt EncryptedKey with response entropy.")
					Set status=$$$ERROR($$$WSTInvalidResponseToken,"Unable to decrypt EncryptedKey with response entropy")
					Quit ""
				}
				Set serverkey=..Entropy.EncryptedKey.Key
			}
		}
		If serverkey="" {
			$$$SOAPLogSecurity("Response Entropy expected for ComputedKey but not present.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Response Entropy expected for ComputedKey but not present")
			Quit ""
		}
		If $get(keysize)="" {
			If ..KeySize'="" {
				Set keysize=(..KeySize+7)\8
			} ElseIf $length(serverkey)>$length(clientkey) {
				Set keysize=$length(clientkey)
			} Else {
				Set keysize=$length(serverkey)
			}
		}
		Set key=##class(%SOAP.WSSC.DerivedKeyToken).PSHA1(clientkey,serverkey,keysize)
		Set key=$extract(key,1,keysize)
		$$$SOAPLogSecurity("      Computed key chosen.")
		;;$$$SOAPLogSecurity("------keysize="_keysize)
		;;$$$SOAPLogSecurity("------Client key: "_$system.Encryption.Base64Encode(clientkey))
		;;$$$SOAPLogSecurity("------Server key: "_$system.Encryption.Base64Encode(serverkey))
	} Else {
		// Use server entropy as the key from proof of possesion
		If clientkey'="" {
			$$$SOAPLogSecurity("Client Entropy must not have been in request.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Client Entropy must not have been in request")
			Quit ""
		}
		If ..RequestedProofToken.BinarySecret'="" {
			Set serverkey=..RequestedProofToken.BinarySecret.value
		} ElseIf ..RequestedProofToken.EncryptedKey'="" {
			// Need %SOAPSecurityHeader
			Set error=..RequestedProofToken.EncryptedKey.ValidateKey(soapClass)
			If error'="" {
				$$$SOAPLogSecurity("Unable to decrypt EncryptedKey with response RequestedProofToken")
				Set status=$$$ERROR($$$WSTInvalidResponseToken,"Unable to decrypt EncryptedKey with response RequestedProofToken")
				Quit ""
			}
			Set serverkey=..RequestedProofToken.EncryptedKey.Key
		}
		If serverkey="" {
			$$$SOAPLogSecurity("Response Entropy expected for no client Entropy but not present.")
			Set status=$$$ERROR($$$WSTInvalidResponseToken,"Response Entropy expected for no client Entropy but not present")
			Quit ""
		}
		Set key=serverkey
		$$$SOAPLogSecurity("      Server Entropy chosen as key.")
	}
	Set token.Key=key
	;;$$$SOAPLogSecurity("------Client key: "_$system.Encryption.Base64Encode(key))

	Quit token
}

/// Return not supported error in request
Method NotSupported(property As %String, Output status As %Status) As %SOAP.WSSC.SecurityContextToken [ Internal ]
{
	$$$SOAPLogSecurity(property_" element is not supported in SecurityTokenRequest.")
	Set status=$$$ERROR($$$WSTNotSupportedResponse,property)
	Quit ""
}

}
