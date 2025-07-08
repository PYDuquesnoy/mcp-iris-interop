/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// RequestSecurityToken as used for request body in WS-Trust 1.3.
Class %SOAP.WST.RequestSecurityToken Extends %SOAP.RequestMessage [ System = 4 ]
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

Property AppliesTo As %XML.String(REFNAMESPACE = "http://www.w3.org/ns/ws-policy", XMLREF = 1);

Property Claims As %SOAP.WST.Claims;

Property Entropy As %SOAP.WST.Entropy;

Property Lifetime As %SOAP.WST.Lifetime;

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

Property CancelTarget As %SOAP.WST.Target;

/// If RequireServerEntropy is true, then the response to this request must have server entropy
Property RequireServerEntropy As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// ComputedKeySize specifies the size in bytes of the computed key which will be established.
/// ComputedKeySize is meaningful only if client and server entropy are both specified for a computed key.
/// Default is $$$SOAPWSSCDEFAULTKEYSIZE.
Property ComputedKeySize As %Integer(XMLPROJECTION = "none");

/// Create an Issue request for WS-SecureConversation SecurityContextToken.<br>
/// If ComputedKeySize is not pre-agreed or specified by a WS-Policy then the ComputedKeySize property should be set 
/// to indicate the desired KeySize in bytes before calling StartSecureConversation.<br>
/// <ul>
/// <li><var>interval</var> is lifetime of the requested token.  To include no Lifetime element pass interval as "".
/// The default interval is 300 seconds.</li>
/// <li><var>clientEntropy</var> is the client entropy to be included in the request 
/// which is created using ##class(%SOAP.WST.Entropy).Create(....</li>
/// <li><var>requireServerEntropy</var> is a %Boolean argument which specifies if server entropy must be supplied.
/// Default is false.</li>
/// </ul>
ClassMethod CreateIssueRequest(interval As %Integer = 300, clientEntropy As %SOAP.WST.Entropy = "", requireServerEntropy As %Boolean) As %SOAP.WST.RequestSecurityToken
{
	Set request=..%New()
	Set request.TokenType=$$$SOAPWSSCToken
	Set request.RequestType=$$$SOAPWSTIssue
	Set request.Entropy=clientEntropy
	Set request.RequireServerEntropy=''$get(requireServerEntropy)
	Set request.Lifetime=##class(%SOAP.WST.Lifetime).Create(interval)
	Quit request
}

/// Create and return an Issue response for this request with WS-SecureConversation SecurityContextToken.
/// <ul>
/// <li><var>soapClass</var> is the web service to which the request was sent.</li>
/// <li><var>keysize</var> is the size of the desired key in bytes. 
/// This argument is used only when key is computed based on both client and server entropy.
/// Default is the smaller of length of client entropy and server entropy.</li>
/// <li><var>requireClientEntropy</var> is true if the request must include client entropy.
/// <var>requireClientEntropy</var> is false if the request must not include client entropy.</li>
/// <li><var>serverEntropy</var> is %SOAP.WST.Entropy with server entropy or "" if no server entropy.</li>
/// <li><var>error</var> contained the returned error string. "" if successful.
/// Otherwise, fault code from section 11 of WS-Trust 1.3 specification.</li>
/// <li><var>lifetime</var> is the required duration of the lifetime token in seconds.
/// If not specifed, the client requested lifetime is used or 300 secondss if no client requested lifetime</li>
/// </ul>
Method CreateIssueResponse(soapClass As %SOAP.WebService, keysize As %Integer, requireClientEntropy As %Boolean, serverEntropy As %SOAP.WST.Entropy = "", Output error As %String, lifetime As %Integer) As %SOAP.WST.RequestSecurityTokenResponseCollection
{
	Set error=""
	Set response=##class(%SOAP.WST.RequestSecurityTokenResponse).%New()

	If ..TokenType'=$$$SOAPWSSCToken {
		$$$SOAPLogSecurity("Unexpected TokenType in SecurityTokenRequest: "_..TokenType)
		Set error="BadRequest"
		Quit ""
	}
	Set response.TokenType=..TokenType

	If ..RequestType'=$$$SOAPWSTIssue {
		$$$SOAPLogSecurity("Unexpected RequestType in SecurityTokenRequest: "_..RequestType)
		Set error="BadRequest"
		Quit ""
	}
	Set response.RequestType=..RequestType

	If ..AppliesTo'="" Quit ..NotSupported("AppliesTo",.error)
	If ..Claims'="" Quit ..NotSupported("Claims",.error)
	If ..RenewTarget'="" Quit ..NotSupported("RenewTarget",.error)
	If ..AllowPostdating'="" Quit ..NotSupported("AllowPostdating",.error)
	If ..Renewing'="" Quit ..NotSupported("Renewing",.error)
	If ..OnBehalfOf'="" Quit ..NotSupported("OnBehalfOf",.error)
	If ..AuthenticationType'="" Quit ..NotSupported("AuthenticationType",.error)

	If ..KeyType'="",..KeyType'=$$$SOAPWSTSecretSymKey,..KeyType'=$$$SOAPWSTNonce {
		$$$SOAPLogSecurity("Unexpected KeyType in SecurityTokenRequest: "_..KeyType)
		Set error="BadRequest"
		Quit ""
	}
	Set response.KeyType=..KeyType

	If ..ComputedKeyAlgorithm'="" {
		If ..ComputedKeyAlgorithm'=$$$SOAPWSTPSHA1 {
			$$$SOAPLogSecurity("Unexpected ComputedKeyAlgorithm in SecurityTokenRequest: "_..ComputedKeyAlgorithm)
			Set error="BadRequest"
			Quit ""
		}
		Set response.ComputedKeyAlgorithm=..ComputedKeyAlgorithm
	}

	If ..Encryption'="" Quit ..NotSupported("Encryption",.error)
	If ..SignatureAlgorithm'="" Quit ..NotSupported("SignatureAlgorithm",.error)
	If ..EncryptionAlgorithm'="" Quit ..NotSupported("EncryptionAlgorithm",.error)
	If ..CanonicalizationAlgorithm'="" Quit ..NotSupported("CanonicalizationAlgorithm",.error)
	If ..ProofEncryption'="" Quit ..NotSupported("ProofEncryption",.error)
	If ..KeyWrapAlgorithm'="" Quit ..NotSupported("KeyWrapAlgorithm",.error)
	If ..UseKey'="" Quit ..NotSupported("UseKey",.error)
	;;If ..SignWith'="" Quit ..NotSupported("SignWith",.error)
	;;If ..EncryptWith'="" Quit ..NotSupported("EncryptWith",.error)
	If ..DelegateTo'="" Quit ..NotSupported("DelegateTo",.error)
	;;If ..Forwardable'="" Quit ..NotSupported("Forwardable",.error)
	If ..Delegatable'="" Quit ..NotSupported("Delegatable",.error)
	If ..Policy'="" Quit ..NotSupported("Policy",.error)
	If ..PolicyReference'="" Quit ..NotSupported("PolicyReference",.error)
	If ..Participants'="" Quit ..NotSupported("Participants",.error)
	If ..CancelTarget'="" Quit ..NotSupported("CancelTarget",.error)

	If $get(lifetime)'="" {
		Set response.Lifetime=##class(%SOAP.WST.Lifetime).Create(lifetime)
	} Else {
		If ..Lifetime'="" {
			Set expires=$zdth(..Lifetime.Expires,3)
			Set now=$ztimestamp
			If (now>expires) || 
			   (($piece(now,",",1)=$piece(expires,",",1)) &&
			    ($piece(now,",",2)>$piece(expires,",",2))) {
					$$$SOAPLogSecurity("Lifetime.Expires is before current time.  Expires="_..Lifetime.Expires_", Now="_$zdt(now,3))
					Set error="InvalidRequest"
					Quit ""
			}
			Set response.Lifetime=##class(%SOAP.WST.Lifetime).%New()
			Set response.Lifetime.Created=$zdt(now,3)
			Set response.Lifetime.Expires=..Lifetime.Expires
		} Else {
			Set response.Lifetime=##class(%SOAP.WST.Lifetime).Create()
		}
	}
	
	Set (key,clientkey,serverkey)=""
	If $isobject(serverEntropy) {
		If $isobject(serverEntropy.BinarySecret) {
			Set serverkey=serverEntropy.BinarySecret.value
		} ElseIf $isobject(serverEntropy.EncryptedKey) {
			Set serverkey=serverEntropy.EncryptedKey.Key
		}
	}
	If ..Entropy'="" {
		If ..Entropy.BinarySecret'="" {
			Set clientkey=..Entropy.BinarySecret.value
		} ElseIf ..Entropy.EncryptedKey'="" {
			If ..Entropy.EncryptedKey.ValidateKey(soapClass)'="" {
				$$$SOAPLogSecurity("Unable to decrypt EncryptedKey with request entropy.")
				Set error="InvalidRequest"
				Quit ""
			}
			Set clientkey=..Entropy.EncryptedKey.Key
		}
	}
	If clientkey'="" {
		If 'requireClientEntropy {
			$$$SOAPLogSecurity("Unexpected Client Entropy specified.")
			Set error="InvalidRequest"
			Quit ""
		}
		If serverkey'="" {
			// ComputedKey
			If ..KeySize'="" {
				Set keysize=(..KeySize+7)\8
				Set response.KeySize=..KeySize
			} ElseIf $get(keysize)="" {
				If $length(serverkey)>$length(clientkey) {
					Set keysize=$length(clientkey)
				} Else {
					Set keysize=$length(serverkey)
				}
			}
			Set response.RequestedProofToken=##class(%SOAP.WST.RequestedProofToken).%New()
			Set response.RequestedProofToken.ComputedKey=$$$SOAPWSTPSHA1
			Set key=##class(%SOAP.WSSC.DerivedKeyToken).PSHA1(clientkey,serverkey,keysize)
			Set key=$extract(key,1,keysize)
			$$$SOAPLogSecurity("Computed key used.")
			;;$$$SOAPLogSecurity("------keysize="_keysize)
			;;$$$SOAPLogSecurity("------Client key: "_$system.Encryption.Base64Encode(clientkey))
			;;$$$SOAPLogSecurity("------Server key: "_$system.Encryption.Base64Encode(serverkey))
			Set response.Entropy=serverEntropy
		} Else {
			// Use client entropy as the key.  No proof of possesion
			Set key=clientkey
			$$$SOAPLogSecurity("Client Entropy used as key.")
		}
	} Else {
		If requireClientEntropy {
			$$$SOAPLogSecurity("Client Entropy must not be specified.")
			Set error="InvalidRequest"
			Quit ""
		}
		If serverkey'="" {
			// Use server entropy as the key
			If serverEntropy.BinarySecret'="" {
				Set serverEntropy.BinarySecret.Type=$$$SOAPWSTSecretSymKey
				Set response.RequestedProofToken=##class(%SOAP.WST.RequestedProofToken).%New()
				Set response.RequestedProofToken.BinarySecret=serverEntropy.BinarySecret
			} ElseIf serverEntropy.EncryptedKey'="" {
				Set response.RequestedProofToken=##class(%SOAP.WST.RequestedProofToken).%New()
				Set response.RequestedProofToken.EncryptedKey=serverEntropy.EncryptedKey
			}
			Set key=serverkey
			$$$SOAPLogSecurity("Server Entropy used as key.")
		} Else {
			// No entropy and thus no key.  No proof of possesion
		}
	}

	Set token=##class(%SOAP.WSSC.SecurityContextToken).Create()
	Set token.Key=key
	;;$$$SOAPLogSecurity("------Server key: "_$system.Encryption.Base64Encode(key))
	If $isobject($get(%request)) {
		Set token.AppliesTo=%request.URL
	}
	Set expires=$zdth(response.Lifetime.Expires,3)
	Set token.ExpiresInSeconds=$piece(expires,",")*86400+($piece(expires,",",2)\1)
	
	Set response.RequestedSecurityToken=##class(%SOAP.WST.RequestedSecurityToken).%New()
	Set response.RequestedSecurityToken.token=token
	Set collection=##class(%SOAP.WST.RequestSecurityTokenResponseCollection).%New()
	Do collection.RequestSecurityTokenResponse.Insert(response)
	
	// WS-Addressing Action header required
	If soapClass.AddressingOut="" {
		Set soapClass.AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(soapClass.AddressingIn,$$$SOAPWSSCTokenResponse)
	}
	
	Quit collection
}

/// Create and return an Cancel response for this Cancel request.
/// <ul>
/// <li><var>soapClass</var> is the web service to which the request was sent.</li>
/// <li><var>error</var> contained the returned error string. "" if successful.
/// Otherwise, fault code from section 11 of WS-Trust 1.3 specification.</li>
/// </ul>
Method CreateCancelResponse(soapClass As %SOAP.WebService, Output error As %String) As %SOAP.WST.RequestSecurityTokenResponseCollection
{
	Set error=""
	
	If '$isobject(..CancelTarget) {
		$$$SOAPLogSecurity("Cancel Request must include CancelTarget.")
		Set error="InvalidRequest"
		Quit ""
	}
	
	If $isobject(..CancelTarget.token) {
		Set SCT=..CancelTarget.token

	} ElseIf $isobject(..CancelTarget.SecurityTokenReference) {
		New %SOAPSecurityHeader
		Set %SOAPSecurityHeader=soapClass.SecurityIn
		If soapClass.SecurityIn.SecurityElement.Count()<1 {
			$$$SOAPLogSecurity("Cancel Request must have Security header.")
			Set error="InvalidRequest"
			Quit ""
		}
		Set signingSCT=soapClass.SecurityIn.SecurityContextToken
		If '$isobject(signingSCT) {
			$$$SOAPLogSecurity("Cancel Request must use have Security header signed by SecurityContextToken.")
			Set error="InvalidRequest"
			Quit ""
		}
		Set error=..CancelTarget.SecurityTokenReference.ValidateTokenRef(soapClass,.tokenType,.SCT)
		If error'="" Quit ""
		If (tokenType'=$$$SOAPWSSCToken) || '$isobject(SCT) {
			$$$SOAPLogSecurity("CancelTarget SecurityTokenReference does not reference a valid SecurityContextToken.")
			Set error="InvalidRequest"
			Quit ""
		}
		If (signingSCT.Identifier'=SCT.Identifier) || (signingSCT.Instance'=SCT.Instance) {
			$$$SOAPLogSecurity("Cancel Request must use have Security header signed by SecurityContextToken that is being cancelled.")
			Set error="InvalidRequest"
			Quit ""
		}

	} Else {
		$$$SOAPLogSecurity("Cancel Target contain a SecurityContextToken or SecurityTokenReference.")
		Set error="InvalidRequest"
		Quit ""
	}

	// Validate that the SecurityContextToken appears in input Security header and applies to this service.
	Set error=SCT.ValidateKey(soapClass)
	If error'="" Quit ""
	
	// Verify that token may be cancelled.
	If SCT.MustNotSendCancel {
		$$$SOAPLogSecurity("Cancel Request not allowed for this SecurityContextToken.  Check WS-Policy which applies.")
		Set error="InvalidRequest"
		Quit ""
	}
	
	// Cancel token by removing from the context list
	Do SCT.Remove()
	
	Set response=##class(%SOAP.WST.RequestSecurityTokenResponse).%New()
	Set response.RequestedTokenCancelled=$c(0)
	
	Set collection=##class(%SOAP.WST.RequestSecurityTokenResponseCollection).%New()
	Do collection.RequestSecurityTokenResponse.Insert(response)
	
	// WS-Addressing Action header required
	If soapClass.AddressingOut="" {
		Set soapClass.AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(soapClass.AddressingIn,$$$SOAPWSSCTokenCancelResponse)
	}
	
	Quit collection
}

/// Return not supported error in request
Method NotSupported(property As %String, Output error As %String) As %SOAP.WST.RequestSecurityTokenResponseCollection [ Internal ]
{
	$$$SOAPLogSecurity(property_" element is not supported in SecurityTokenRequest.")
	Set error="BadRequest"
	Quit ""
}

}
