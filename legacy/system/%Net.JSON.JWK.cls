/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides methods to create JSON Web Keys, as defined in RFC 7517, and convert between the JSON Web Key 
/// format and other key representation formats.
Class %Net.JSON.JWK Extends %RegisteredObject [ System = 4 ]
{

/// This method creates a new public/private JSON Web Key (JWK) pair for the given algorithm.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// alg - The algorithm for which to create the JWK.
/// </li><li>
/// secret - An optional shared secret to be used as the key. If this is omitted, a new secret will be generated.
/// This defaults to a null string.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// privJWK - The private JSON Web Key that is created.
/// </li><li>
/// pubJWK - The public JSON Web key that is created.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating if a JWK pair (or individual JWK for symmetric key algorithms) was successfully created 
/// for the given algorithm and (optionally) secret. If no JWK was created, this method will return an error
/// describing why not.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method does not add a kid to the keys it creates. In order to use kids, they must be added after the keys are created.
/// For example:<br><pre>
/// Set sc=##class(%Net.JSON.JWK).Create("ES256",,.privJWK,.pubJWK)
/// If $$$ISOK(sc) {
/// 	Set privJWK.kid=1
/// 	Set pubJWK.kid=1
/// }</pre>
/// </li><li>
/// This method does not encrypt the keys it creates. In order to create encrypted JWKs, convert the JWKs created by this method
/// into strings and then pass them through %Net.JSON.JWE:Encrypt() as the plaintext. For example:<br><pre>
/// Set sc=##class(%Net.JSON.JWK).Create("ES256",,.privJWK,.pubJWK)
/// If $$$ISOK(sc) {
/// 	Set privJWK=privJWK.%ToJSON()
/// 	Set pubJWK=pubJWK.%ToJSON()
/// 	Do ##class(%Net.JSON.JWE).Encrypt({"alg":"RSA1_5","enc":"A256CBC-HS512"},,,privJWK,,,JWKS,.encryptedPrivJWK)
/// 	Do ##class(%Net.JSON.JWE).Encrypt({"alg":"RSA1_5","enc":"A256CBC-HS512"},,,pubJWK,,,JWKS,.encryptedPubJWK)
/// }</pre><br>
/// Where JWKS is a JWKS that contains a key for RSA1_5.
/// </li><li>
/// This method will return an error if an unrecognized algorithm is used.
/// </li><li>
/// Assuming creation was successful, privJWK will always have a non-null value.
/// </li><li>
/// If the algorithm is symmetric, then pubJWK will be null even if creation succeeded.</li></ul>
ClassMethod Create(alg As %String, secret As %String = "", Output privJWK As %DynamicObject, Output pubJWK As %DynamicObject) As %Status
{
	Set privJWK="", pubJWK=""

	Set sc=$$$OK
	Try {
		Set algInfo=##class(%Net.JSON.JWA).GetAlgInfo(alg)
		If (algInfo="") {
			Set sc=$$$ERROR($$$UnsupportedJWKAlg,alg)
			Quit
		}

		If (algInfo.kty="oct") {
			Set sc=..CreateOct(algInfo,secret,.privJWK)
		} ElseIf (algInfo.kty="RSA") {
			Set sc=..CreateRSA(algInfo,.privJWK,.pubJWK)
		} ElseIf (algInfo.kty="EC") {
			Set sc=..CreateEC(algInfo,.privJWK,.pubJWK)
		} Else {
			Set sc=$$$ERROR($$$UnsupportedJWKAlg,alg)
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	Return sc
}

/// This method creates a new JSON Web Key (JWK) pair for the given algorithm based on the RSA key(s) contained in the given <class>%SYS.X509Credentials</class> object.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// alg - The algorithm for which to create the JWK.
/// </li><li>
/// x509 - a <class>%SYS.X509Credentials</class> object containing the RSA keys to use. 
/// If this object contains a private key, then a public and private JWK will be returned. Otherwise, only the pubkc JWK will be returned. 
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// privJWK - The private JSON Web Key that is created.
/// </li><li>
/// pubJWK - The public JSON Web key that is created.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating if a JWK pair (or just a public JWK) was successfully created 
/// for the given algorithm. If no JWK was created, this method will return an error describing why not.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method does not add a kid to the keys it creates. In order to use kids, they must be added after the keys are created.
/// For example:<br><pre>
/// Set sc=##class(%Net.JSON.JWK).CreateX509("RS256",x509,.privJWK,.pubJWK)
/// If $$$ISOK(sc) {
/// 	Set privJWK.kid=1
/// 	Set pubJWK.kid=1
/// }</pre>
/// </li><li>
/// This method does not encrypt the keys it creates. In order to create encrypted JWKs, convert the JWKs created by this method
/// into strings and then pass them through %Net.JSON.JWE:Encrypt() as the plaintext. For example:<br><pre>
/// Set sc=##class(%Net.JSON.JWK).CreateX509("RS256",x509,.privJWK,.pubJWK)
/// If $$$ISOK(sc) {
/// 	Set privJWK=privJWK.%ToJSON()
/// 	Set pubJWK=pubJWK.%ToJSON()
/// 	Do ##class(%Net.JSON.JWE).Encrypt({"alg":"RSA1_5","enc":"A256CBC-HS512"},,,privJWK,,,JWKS,.encryptedPrivJWK)
/// 	Do ##class(%Net.JSON.JWE).Encrypt({"alg":"RSA1_5","enc":"A256CBC-HS512"},,,pubJWK,,,JWKS,.encryptedPubJWK)
/// }</pre><br>
/// Where JWKS is a JWKS that contains a key for RSA1_5.
/// </li><li>
/// This method will return an error if an unrecognized algorithm is used.
/// </li><li>
/// Assuming creation was successful, pubJWK will always have a non-null value.</li></ul>
ClassMethod CreateX509(alg As %String, x509 As %SYS.X509Credentials, Output privJWK As %DynamicObject, Output pubJWK As %DynamicObject) As %Status
{
	Set privJWK="", pubJWK=""

	Set sc=$$$OK
	Try {
		Set algInfo=##class(%Net.JSON.JWA).GetAlgInfo(alg)
		If (algInfo="") || (algInfo.kty'="RSA") {
			$$$ThrowStatus($$$ERROR($$$UnsupportedJWKAlg,alg))
		}

		If x509.HasPrivateKey {
			$$$ThrowOnError(..RSAASN1toJWK(x509.PrivateKey,x509.PrivateKeyPassword,.privJWK))
			Set privJWK.alg=algInfo.alg
			Set pubJWK={}
			Set pubJWK.kty=algInfo.kty
			Set pubJWK.n=privJWK.n
			Set pubJWK.e=privJWK.e
			Set pubJWK.alg=algInfo.alg
			Set pubJWK.use=algInfo.use
		} Else {
			Set pubJWK={}
			Set pubJWK.kty=algInfo.kty
			Set pubJWK.n=$$$BASE64URLENCODE($SYSTEM.Encryption.X509GetField(x509.Certificate,"RSAPublicKeyModulus"))
			Set pubJWK.e=$$$BASE64URLENCODE($SYSTEM.Encryption.X509GetField(x509.Certificate,"RSAPublicKeyExponent"))
			Set pubJWK.alg=algInfo.alg
			Set pubJWK.use=algInfo.use
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	Return sc
}

/// This internal helper method checks that the provided JSON Web Key (JWK) conforms to the
/// specs laid out in RFC 7517 section 4.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// JWK - The JWK to check for validity.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the provided JWK is valid, where error values indicate that the
/// JWK is not valid and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method checks that the given JWK exists, is non-null, is in valid JSON format, and contains a
/// "kty" parameter. If the "kty" parameter is one of the three known values defined in RFC 7517, it then
/// checks that the JWK contains the corresponding parameters laid out for each key type in RFC 7518 section 6.
/// </li><li>
/// This method does not check that the "kty" parameter is a valid key type (as there might be types in 
/// private use not known to IRIS).</li></ul>
ClassMethod IsValid(JWK As %DynamicObject) As %Status [ Internal ]
{
	// An empty JWK is not valid
	If (($get(JWK)="") || (JWK.%Size()=0)) {
		Return $$$ERROR($$$NoJWK)
	}

	// A JWK without the "kty" parameter is not valid
	If (JWK.kty="") {
		Return $$$ERROR($$$JWKMissingParam,"kty")
	}

	// Each key type has a set of required parameters
	// A JWK without the parameters required for its key type is not valid
	If (JWK.kty="RSA") {
		If (JWK.n="") {
			Return $$$ERROR($$$JWKMissingParam,"n")
		}
		If (JWK.e="") {
			Return $$$ERROR($$$JWKMissingParam,"e")
		}
		If (JWK.oth'="") {
			Return $$$ERROR($$$InvalidRSAKeyOthParam)
		}
	} ElseIf (JWK.kty="EC") {
		If (JWK.crv="") {
			Return $$$ERROR($$$JWKMissingParam,"crv")
		}
		If (JWK.x="") {
			Return $$$ERROR($$$JWKMissingParam,"x")
		}
	} ElseIf (JWK.kty="oct") {
		If (JWK.k="") {
			Return $$$ERROR($$$JWKMissingParam,"k")
		}
	}

	// If here, JWK is valid
	Return $$$OK
}

/// This method converts a key in JSON Web Key (JWK) format to PEM-encoded DER ASN.1 format.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// JWK - JSON Web Key representation of a private or public key.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// ASN1 - PEM-encoded DER ASN.1 representation of the private or public key.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the JWK was successfully converted to ASN.1 format, where error
/// values indicate that the conversion failed and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// Currently this method only supports RSA and elliptic curve keys.</li></ul>
ClassMethod JWKtoASN1(JWK As %DynamicObject, Output ASN1 As %String) As %Status
{
	Set ASN1=""

	If '$data(JWK) {
		Return $$$ERROR($$$NoJWK)
	}

	Set sc=..IsValid(JWK)
	If $$$ISERR(sc) {
		Return sc
	}

	If (JWK.kty="RSA") {
		Return ..RSAJWKtoASN1(JWK,.ASN1)
	} ElseIf (JWK.kty="EC") {
		Return ..ECJWKtoASN1(JWK,.ASN1)
	} Else {
		Return $$$ERROR($$$InvalidASN1KeyType,JWK.kty)
	}
}

/// This private method creates a private JWK for a symmetric algorithm.
/// It is a helper method for Create() above and should never be called on its own.
ClassMethod CreateOct(algInfo As %DynamicObject, secret As %String, Output privJWK As %DynamicObject) As %Status [ Internal, Private ]
{
	Set privJWK=""

	Try {
		Set keylen=algInfo.keysize\8
		// Use the secret, if specified; otherwise generate a key of the correct length.
		If secret'="" {
			If $length(secret)<keylen {
				Return $$$ERROR($$$OctKeyCreateError,algInfo.alg)
			}
			Set key=secret
		} Else {
			Set key=$System.Encryption.GenCryptRand(keylen,1)
		}
	} Catch ex {
		Return ex.AsStatus()
	}

	If (key="") {
		Return $$$ERROR($$$OctKeyCreateError, algInfo.alg)
	}

	// Make the JWK private key from the symmetric key
	Set privJWK={}
	Set privJWK.kty=algInfo.kty
	Set privJWK.k=$$$BASE64URLENCODE(key)
	Set privJWK.alg=algInfo.alg

	Return $$$OK
}

/// This private method creates a private and public JWK pair for an RSA algorithm.
/// It is a helper method for Create() above and should never be called on its own.
ClassMethod CreateRSA(algInfo As %DynamicObject, Output privJWK As %DynamicObject, Output pubJWK As %DynamicObject) As %Status [ Internal, Private ]
{
	Set privJWK="", pubJWK=""

	Try {
		// Generate an RSA key as a list object for the given algorithm's key size
		Set props=$System.Encryption.RSAGenerateKey(algInfo.keysize)
		If ($listlength(props)'=8) {
			Return $$$ERROR($$$OAuth2RSAKeyGenError,$System.Encryption.RSAGetLastError())
		}
	} Catch ex {
		Return ex.AsStatus()
	}

	// Make the JWK private key from the key list object
	Set privJWK={}
	Set privJWK.kty=algInfo.kty
	Set privJWK.n=$$$BASE64URLENCODE($list(props,1))
	Set privJWK.e=$$$BASE64URLENCODE($list(props,2))
	Set privJWK.d=$$$BASE64URLENCODE($list(props,3))
	Set privJWK.p=$$$BASE64URLENCODE($list(props,4))
	Set privJWK.q=$$$BASE64URLENCODE($list(props,5))
	Set privJWK.dp=$$$BASE64URLENCODE($list(props,6))
	Set privJWK.dq=$$$BASE64URLENCODE($list(props,7))
	Set privJWK.qi=$$$BASE64URLENCODE($list(props,8))
	Set privJWK.alg=algInfo.alg

	// Make the JWK public key from the key list object
	Set pubJWK={}
	Set pubJWK.kty=privJWK.kty
	Set pubJWK.n=privJWK.n
	Set pubJWK.e=privJWK.e
	Set pubJWK.alg=privJWK.alg
	Set pubJWK.use=algInfo.use

	Return $$$OK
}

/// This private method creates a private and public JWK pair for an elliptic curve algorithm.
/// It is a helper method for Create() above and should never be called on its own.
ClassMethod CreateEC(algInfo As %DynamicObject, Output privJWK As %DynamicObject, Output pubJWK As %DynamicObject) As %Status [ Internal, Private ]
{
	Set privJWK="", pubJWK=""

	Try {
		// Determine the curve size based on the algorithm used
		Set curveSize=$case(algInfo.alg,"ES256":256,"ES384":384,"ES512":521,:0)

		// Generate an elliptic curve key as a list object for the given curve size
		Set props=$System.Encryption.ECGenerateKey(curveSize)
		If ($listlength(props)'=3) {
			Return $$$ERROR($$$OAuth2ECKeyGenError,$System.Encryption.ECSHAGetLastError())
		}		
	} Catch ex {
		Return ex.AsStatus()
	}

	// Make the JWK private key from the key list object
	Set privJWK={}
	Set privJWK.alg=algInfo.alg
	Set privJWK.kty=algInfo.kty
	Set privJWK.crv=$case(curveSize,256:"P-256",384:"P-384",521:"P-521",:"")
	Set coordinateSize=$case(curveSize,256:32,384:48,521:66,:0)
	Set x=$list(props,1)
	Set y=$list(props,2)
	If ($length(x)<coordinateSize) {
		Set x=$char(0)_x
	}
	If ($length(y)<coordinateSize) {
		Set y=$char(0)_y
	}
	Set privJWK.x=$$$BASE64URLENCODE(x)
	Set privJWK.y=$$$BASE64URLENCODE(y)
	Set privJWK.d=$$$BASE64URLENCODE($list(props,3))

	// Make the JWK public key from the key list object
	Set pubJWK={}
	Set pubJWK.alg=privJWK.alg
	Set pubJWK.kty=privJWK.kty
	Set pubJWK.crv=privJWK.crv
	Set pubJWK.x=privJWK.x
	Set pubJWK.y=privJWK.y
	Set pubJWK.use=algInfo.use

	Return $$$OK
}

/// This private method converts a PEM-encoded DER ASN.1 RSA key to JSON Web Key (JWK) format.
/// It is a helper method for CreateX509() above and should never be called on its own.
ClassMethod RSAASN1toJWK(ASN1 As %String, Password As %String = "", Output JWK As %DynamicObject) As %Status [ Internal, Private ]
{
	Set sc=$$$OK
	Try {
		If (Password'="") { 
			Set props=$System.Encryption.RSAASN1Parse(ASN1,Password) 
		}
		Else { 
			Set props=$System.Encryption.RSAASN1Parse(ASN1) 
		}
		Set JWK={}
		If ($listlength(props)=8) {
			/// Private key
			Set JWK.kty="RSA"
			Set JWK.n=$$$BASE64URLENCODE($li(props,1))
			Set JWK.e=$$$BASE64URLENCODE($li(props,2))
			Set JWK.d=$$$BASE64URLENCODE($li(props,3))
			Set JWK.p=$$$BASE64URLENCODE($li(props,4))
			Set JWK.q=$$$BASE64URLENCODE($li(props,5))
			Set JWK.dp=$$$BASE64URLENCODE($li(props,6))
			Set JWK.dq=$$$BASE64URLENCODE($li(props,7))
			Set JWK.qi=$$$BASE64URLENCODE($li(props,8))
		} ElseIf ($listlength(props)=2) {
			/// Public key
			Set JWK.kty="RSA"
			Set JWK.n=$$$BASE64URLENCODE($li(props,1))
			Set JWK.e=$$$BASE64URLENCODE($li(props,2))
		} Else {
			Set sc=$$$ERROR($$$OAuth2RSAParsingError) Quit
		}
		If $$$ISERR(sc) Quit
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	Quit sc
}

/// This private method converts an RSA key in JSON Web Key (JWK) format to PEM-encoded DER ASN.1 format.
/// It is a helper method for JWKtoASN1() above and should never be called on its own.
ClassMethod RSAJWKtoASN1(JWK As %DynamicObject, Output ASN1 As %String) As %Status [ Internal, Private ]
{
	Set ASN1=""

	Try {
		// Identify the parameters that are in both public and private RSA keys
		Set n=$$$BASE64URLDECODE(JWK.n)
		Set e=$$$BASE64URLDECODE(JWK.e)
		If ((n="")||(e="")) {
			Return $$$ERROR($$$OAuth2InvalidRSAParameters)
		}

		// Identify the parameters that are only in private RSA keys
		Set d=$$$BASE64URLDECODE(JWK.d)
		Set p=$$$BASE64URLDECODE(JWK.p)
		Set q=$$$BASE64URLDECODE(JWK.q)
		Set dp=$$$BASE64URLDECODE(JWK.dp)
		Set dq=$$$BASE64URLDECODE(JWK.dq)
		Set qi=$$$BASE64URLDECODE(JWK.qi)

		// Create the DER format ASN.1 key
		If ((d'="")&&(p'="")&&(q'="")&&(dp'="")&&(dq'="")&&(qi'="")) {
			// Private key parameters are present so we are creating a private key
			Set der=$System.Encryption.RSAASN1Construct(n,e,d,p,q,dp,dq,qi)
			Set private=1
		} ElseIf ((d="")&&(p="")&&(q="")&&(dp="")&&(dq="")&&(qi="")) {
			// Private key parameters are absent so we are creating a public key
			Set der=$System.Encryption.RSAASN1Construct(n,e)
			Set private=0
		} Else {
			Return $$$ERROR($$$OAuth2InvalidRSAParameters)
		}
		If der="" {
			Return $$$ERROR($$$OAuth2RSAConstructionError)
		}

		// PEM-encode the DER format ASN.1 key
		Set der=$System.Encryption.Base64Encode(der,1)
		If (private) {
			Set ASN1="-----BEGIN RSA PRIVATE KEY-----"_$char(13,10)
		} Else {
			Set ASN1="-----BEGIN RSA PUBLIC KEY-----"_$char(13,10)
		}
		Set first=1,last=$length(der)
		While ((last-first)>=63) {
			Set ASN1=ASN1_$extract(der,first,first+63)_$char(13,10)
			Set first=first+64
		}
		If (first<=last)	{
			Set ASN1=ASN1_$extract(der,first,last)_$char(13,10)
		}
		If (private) {
			Set ASN1=ASN1_"-----END RSA PRIVATE KEY-----"_$char(13,10)
		} Else {
			Set ASN1=ASN1_"-----END RSA PUBLIC KEY-----"_$char(13,10)
		}
	} Catch ex {
		Return ex.AsStatus()
	}

	Return $$$OK
}

/// This private method converts an elliptic curve key in JSON Web Key (JWK) format to PEM-encoded DER ASN.1 format.
/// It is a helper method for JWKtoASN1() above and should never be called on its own.
ClassMethod ECJWKtoASN1(JWK As %DynamicObject, Output ASN1 As %String) As %Status [ Internal, Private ]
{
	Set ASN1=""

	Try {
		// Identify the parameters that are in both public and private EC keys
		Set crv=(JWK.crv)
		Set curve=$case(crv,"P-256":256,"P-384":384,"P-521":521,:0)
		Set x=$$$BASE64URLDECODE(JWK.x)
		Set y=$$$BASE64URLDECODE(JWK.y)
		If ((curve=0)||(x="")||(y="")) {
			Return $$$ERROR($$$OAuth2InvalidECParameters)
		}
		
		// Identify the parameter that is only in private EC keys
		Set d=$$$BASE64URLDECODE(JWK.d)

		// Create the DER format ASN.1 key
		If (d'="") {
			// Private key parameter is present so we are creating a private key
			Set der=$System.Encryption.ECASN1Construct(curve,x,y,d)
			Set private=1
		} Else {
			// Private key parameter is absent so we are creating a public key
			Set der=$System.Encryption.ECASN1Construct(curve,x,y)
			Set private=0
		}
		If der="" {
			Return $$$ERROR($$$OAuth2ECConstructionError)
		}

		// PEM-encode the DER format ASN.1 key
		Set der=$System.Encryption.Base64Encode(der,1)
		If (private) {
			Set ASN1="-----BEGIN EC PRIVATE KEY-----"_$char(13,10)
		} Else {
			Set ASN1="-----BEGIN PUBLIC KEY-----"_$char(13,10)
		}
		Set first=1,last=$length(der)
		While ((last-first)>=63) {
			Set ASN1=ASN1_$extract(der,first,first+63)_$char(13,10)
			Set first=first+64
		}
		If (first<=last)	{
			Set ASN1=ASN1_$extract(der,first,last)_$char(13,10)
		}
		If (private) {
			Set ASN1=ASN1_"-----END EC PRIVATE KEY-----"_$char(13,10)
		} Else {
			Set ASN1=ASN1_"-----END PUBLIC KEY-----"_$char(13,10)
		}
	} Catch ex {
		Return ex.AsStatus()
	}

	Return $$$OK
}

}
