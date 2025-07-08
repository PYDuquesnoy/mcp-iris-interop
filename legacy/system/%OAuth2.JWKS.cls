/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %sySecurity)

Class %OAuth2.JWKS Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// This method is deprecated. Use the <b>GetAlgInfo</b> method in <class>%Net.JSON.JWA</class> instead.
ClassMethod GetAlg(Alg As %String) As %DynamicObject [ Deprecated, Internal ]
{
	// "use":"sig" marks algorithms that can be used with JWS to sign the JWS Protected Header and JWS Payload
	// this corresponds to JOSE "sigalg"
	// "use":"enc" marks algorithms that can be used to encrypt or determine the Content Encryption Key (CEK)
	// this corresponds to JOSE "keyalg"
	// "use":"cont" marks algorithms that can be used to encrypt and integrity-protect the plaintext
	// this corresponds to JOSE "encalg"
	Set algs={"algs":[
	{"alg":"none"},
	{"alg":"HS256","kty":"oct","use":"sig","keysize":256,"hashsize":256},
	{"alg":"HS384","kty":"oct","use":"sig","keysize":384,"hashsize":384},
	{"alg":"HS512","kty":"oct","use":"sig","keysize":512,"hashsize":512},
	{"alg":"RS256","kty":"RSA","use":"sig","keysize":256,"hashsize":256},
	{"alg":"RS384","kty":"RSA","use":"sig","keysize":256,"hashsize":384},
	{"alg":"RS512","kty":"RSA","use":"sig","keysize":256,"hashsize":512},
	{"alg":"ES256","kty":"EC","use":"sig","keysize":64,"hashsize":256},
	{"alg":"ES384","kty":"EC","use":"sig","keysize":96,"hashsize":384},
	{"alg":"ES512","kty":"EC","use":"sig","keysize":132,"hashsize":512},
	{"alg":"RSA1_5","kty":"RSA","use":"enc","keysize":256},
	{"alg":"RSA-OAEP","kty":"RSA","use":"enc","keysize":256},
	{"alg":"A128KW","kty":"oct","use":"enc","keysize":128,"hashsize":256},
	{"alg":"A192KW","kty":"oct","use":"enc","keysize":192,"hashsize":256},
	{"alg":"A256KW","kty":"oct","use":"enc","keysize":256,"hashsize":256},
	{"alg":"dir","kty":"oct","use":"enc"},
	{"alg":"A128CBC-HS256","use":"cont","keysize":128,"hashsize":256},
	{"alg":"A192CBC-HS384","use":"cont","keysize":192,"hashsize":384},
	{"alg":"A256CBC-HS512","use":"cont","keysize":256,"hashsize":512}]}
	s arr=algs.algs

	Set iter=arr.%GetIterator()
	Set resultValue=""
	While iter.%GetNext(.key,.value) {
		if (value.alg=Alg) {
			Set resultValue=value
			Quit
		}
	}
	Quit resultValue
}

/// This algorithm adds a new RSA private and public key pair to JSON Web Key Sets (JWKS).<br>
/// <br>
/// Input parameter:<br>
/// <br>
/// Alg - The algorithm with which the keys are intended for use.<br>
/// Supported options for signature:<br>
/// "RS256", RSASSA-PKCS1-V1_5 using SHA-256<br>
/// "RS384", RSASSA-PKCS1-V1_5 using SHA-384<br>
/// "RS512", RSASSA-PKCS1-V1_5 using SHA-512<br>
/// Supported options for key management:<br>
/// "RSA1_5", Encryption with RSAES-PKCS1-V1_5<br>
/// "RSA-OAEP", Encryption with RSAES-OAEP<br><br>
/// <br>
/// Output parameters:<br>
/// <br>
/// LocalPrivate - The Local Private JWKS to which the RSA private key will be added.
/// If it does not already exist it will be created.<br>
/// <br>
/// Local Public - The Local Public JWKS to which the RSA public key will be added.
/// If it does not already exist it will be created.<br>
/// This method is deprecated. Use the <class>%Net.JSON.JWK</class> and <class>%Net.JSON.JWKS</class>
/// classes to manipulate JWK and JWKS definitions.
ClassMethod AddRSA(Alg As %String, ByRef LocalPrivate As %String, ByRef LocalPublic As %String) As %Status [ Deprecated ]
{
	Return ..AddAsymmetric(Alg,, .LocalPrivate, .LocalPublic)
}

/// This method adds a new shared symmetric key to a JSON Web Key Set (JWKS).<br>
/// <br>
/// Alg - The algorithm for which the key is intended for use.<br>
/// Supported options for signature:<br>
/// "HS256", HMAC with SHA-256<br>
/// "HS384", HMAC with SHA-384<br>
/// "HS512", HMAC with SHA-512<br>
/// Supported options for key management:<br>
/// "A128KW", AES Key Wrap with 128-bit key<br>
/// "A192KW", AES Key Wrap with 192-bit key<br>
/// "A256KW", AES Key Wrap with 256-bit key<br>
/// "dir", direct encryption with a shared symmetric key<br>
/// <br>
/// ClientSecret - Secret shared between a client and a server.  This must have sufficient entropy to support the specified algorithm.<br>
/// <br>
/// Output Parameter:<br>
/// <br>
/// RemotePublic - The Remote Public JWKS to which the shared symmetric key will be added.
/// If it does not already exist it will be created.<br>
/// This method is deprecated. Use the <class>%Net.JSON.JWK</class> and <class>%Net.JSON.JWKS</class>
/// classes to manipulate JWK and JWKS definitions.
ClassMethod AddOct(Alg As %String, ClientSecret As %String, ByRef RemotePublic As %String, EncAlg As %String) As %Status [ Deprecated ]
{
	Set sc = $$$OK
	Try {
		Set algInfo = ##class(%Net.JSON.JWA).GetAlgInfo(Alg)
		Set ClientSecret = $zcvt(ClientSecret,"O","UTF8")
		Set keylen = algInfo.keysize\8
		Set kid = ""
		If Alg="dir" {
			Set encInfo = ##class(%Net.JSON.JWA).GetAlgInfo(EncAlg)
			If (encInfo="") || (encInfo."key_ops".%Get(0)'="wrapKey") {
				$$$ThrowStatus($$$ERROR($$$OAuth2InvalidAlg,Alg))
			}
			Set keylen = 2*keylen

			Set secret=$extract($System.Encryption.SHAHash(encInfo.hashsize,ClientSecret),*-keylen+1,*)
			Set kid = encInfo.alg
		} ElseIf algInfo.use="enc" {
			Set secret=$extract($System.Encryption.SHAHash(256,ClientSecret),*-keylen+1,*)
		} Else { // use="sig"
			Set secret = ClientSecret
		}

		If ($length(ClientSecret)<(keylen)) {
			$$$ThrowStatus($$$ERROR($$$OAuth2ClientSecretTooShort,Alg))
		}

		$$$ThrowOnError(##class(%Net.JSON.JWK).Create(Alg,secret,.privJWK))
		If kid'="" {
			Set privJWK.kid = kid
		}

		$$$ThrowOnError(##class(%Net.JSON.JWKS).RemoveJWK(Alg, kid, RemotePublic))
		$$$ThrowOnError(##class(%Net.JSON.JWKS).PutJWK(privJWK, .RemotePublic))
	} Catch ex {
		Set sc = ex.AsStatus()
	}

	Return sc
}

/// This method adds the RSA keys contained in a %SYS.X509Credentials object to JSON Web Key Sets (JWKS).<br>
/// <br>
/// Input parameters:<br>
/// <br>
/// Alg - The algorithm with which the keys are intended for use.<br>
/// Supported options for signature:<br>
/// "RS256", RSASSA-PKCS1-V1_5 using SHA-256<br>
/// "RS384", RSASSA-PKCS1-V1_5 using SHA-384<br>
/// "RS512", RSASSA-PKCS1-V1_5 using SHA-512<br>
/// Supported options for key encryption:<br>
/// "RSA1_5", Encryption with RSAES-PKCS1-V1_5<br>
/// "RSA-OAEP", Encryption with RSAES-OAEP<br><br>
/// <br>
/// Output parameters:<br>
/// <br>
/// If the %SYS.X509Credentials object PrivateKey property is set:<br>
/// <br>
/// LocalPrivate - The Local Private JWKS to which the RSA private key will be added.
/// If it does not already exist it will be created.<br>
/// <br>
/// Public - The Local Public JWKS to which the RSA public key will be added.
/// If it does not already exist it will be created.<br>
/// <br>
/// If the %SYS.X509Credentials object PrivateKey property is null:<br>
/// <br>
/// Public - The Remote Public JWKS to which the RSA public key will be added.
/// If it does not already exist it will be created.<br>
/// This method is deprecated. Use the <class>%Net.JSON.JWK</class> and <class>%Net.JSON.JWKS</class>
/// classes to manipulate JWK and JWKS definitions.
ClassMethod AddX509(Alg As %String, X509 As %SYS.X509Credentials, ByRef LocalPrivate As %String, ByRef Public As %String) As %Status [ Deprecated ]
{
	Return ..AddAsymmetric(Alg, X509, .LocalPrivate, .Public)
}

/// This algorithm adds a new EC private and public key pair to JSON Web Key Sets (JWKS).<br>
/// <br>
/// Input parameter:<br>
/// <br>
/// Alg - The algorithm with which the keys are intended for use.<br>
/// Supported options for signature:<br>
/// "ES256", ECDSA using P-256 and SHA-256<br>
/// "ES384", ECDSA using P-384 and SHA-384<br>
/// "ES512", ECDSA using P-521 and SHA-512<br>
/// <br>
/// Output parameters:<br>
/// <br>
/// LocalPrivate - The Local Private JWKS to which the EC private key will be added.
/// If it does not already exist it will be created.<br>
/// <br>
/// Local Public - The Local Public JWKS to which the EC public key will be added.
/// If it does not already exist it will be created.<br>
/// This method is deprecated. Use the <class>%Net.JSON.JWK</class> and <class>%Net.JSON.JWKS</class>
/// classes to manipulate JWK and JWKS definitions.
ClassMethod AddEC(Alg As %String, ByRef LocalPrivate As %String, ByRef LocalPublic As %String) As %Status [ Deprecated ]
{
	Return ..AddAsymmetric(Alg,, .LocalPrivate, .LocalPublic)
}

ClassMethod AddAsymmetric(alg As %String, X509 As %SYS.X509Credentials = "", ByRef private As %String, ByRef public As %String) As %Status [ Private ]
{
	Set sc = $$$OK
	Try {
		If $isobject(X509) {
			$$$ThrowOnError(##class(%Net.JSON.JWK).CreateX509(alg,X509,.privJWK,.pubJWK))
		} Else {
			$$$ThrowOnError(##class(%Net.JSON.JWK).Create(alg,,.privJWK,.pubJWK))
		}

		// we don't set the kid if creating from X509 creds, and no private key is available
		If $isobject(privJWK) {
			Set privKid = ##class(%OAuth2.Utils).FindLastKid(.private)
			Set pubKid = ##class(%OAuth2.Utils).FindLastKid(.public)
			// the last kid should match, but if it doesn't make sure to use the larger one
			Set kid = $select(privKid>=pubKid:privKid, 1:pubKid)+1
			
			Set privJWK.kid = kid
			Set pubJWK.kid = kid
		}

		// remove the old public key, if it exists
		If $data(public) {
			$$$ThrowOnError(##class(%Net.JSON.JWKS).RemoveJWK(alg,, .public))
		}

		// add the new keys
		$$$ThrowOnError(##class(%Net.JSON.JWKS).PutJWK(privJWK, .private))
		$$$ThrowOnError(##class(%Net.JSON.JWKS).PutJWK(pubJWK, .public))
	} Catch ex {
		Set sc = ex.AsStatus()
	}

	Return sc
}

}
