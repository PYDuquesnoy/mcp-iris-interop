/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %callout

Class %OAuth2.JWT Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// This method is deprecated. Use the <b>GetJWK</b> method in <class>%Net.JSON.JWKS</class> instead.
ClassMethod GetJWK(JWKS As %DynamicObject, Alg As %String, Kid As %String) As %DynamicObject [ Deprecated ]
{
	Do ##class(%Net.JSON.JWKS).GetJWK(Alg,Kid, JWKS, .jwk)
	Return jwk
}

/// This method generates a JSON Web Token (JWT), performing signature and/or encryption operations as requested.<br>
/// <br>
/// Input parameters:<br>
/// <br>
/// JOSE - Array of Strings used to specify the JSON Object Signature and/or Encryption operations to be performed on the JWT<br>
/// <br>
/// For JSON Web Signature (JWS):<br><br>
/// JOSE("sigalg") - Signature or MAC algorithm, supported options:<br>
/// "HS256", HMAC with SHA-256<br>
/// "HS384", HMAC with SHA-384<br>
/// "HS512", HMAC with SHA-512<br>
/// "RS256", RSASSA-PKCS1-V1_5 using SHA-256<br>
/// "RS384", RSASSA-PKCS1-V1_5 using SHA-384<br>
/// "RS512", RSASSA-PKCS1-V1_5 using SHA-512<br>
/// "ES256", ECDSA using P-256 and SHA-256<br>
/// "ES384", ECDSA using P-384 and SHA-384<br>
/// "ES512", ECDSA using P-521 and SHA-512<br>
/// <br>
/// For JSON Web Encryption (JWE):<br><br>
/// JOSE("keyalg") - Key management algorithm, supported options:<br>
/// "RSA1_5", Encryption with RSAES-PKCS1-V1_5<br>
/// "RSA-OAEP", Encryption with RSAES-OAEP<br><br>
/// JOSE("encalg") - Content encryption algorithm, supported options:<br>
/// "A128CBC-HS256", 128-bit AES in CBC mode with HMAC SHA-256<br>
/// "A192CBC-HS384", 192-bit AES in CBC mode with HMAC SHA-384<br>
/// "A256CBC-HS512", 256-bit AES in CBC mode with HMAC SHA-512<br><br>
/// Note, JOSE("keyalg") and JOSE("encalg") must both be specified or null.<br>
/// <br>
/// If JWS and JWE are both specified the JWT will be signed, then encrypted.<br>
/// <br>
/// JOSE("jku") - If defined, the JWK Url will be included in the JOSE header. <br>
/// The relevant URL value must be included in JOSE("jku_local") or JOSE("jku_remote").<br>
/// <br>
/// JOSE("jwk") - If defined, the JWK public key will be included in the JOSE header. <br>
/// If performing a signature, the local public JWKS must be included in the JOSE("jwks_local") <br>
/// <br>
/// Body - Object representation of the Claims contained in the JWT<br>
/// <br>
/// LocalPrivate - Local Private JWKS<br>
/// <br>
/// RemotePublic - Remote Public JWKS<br>
/// Output parameter:<br>
/// <br>
/// JWT - JSON Web Token<br>
/// This method is deprecated. Use the <b>Create</b> method in <class>%Net.JSON.JWT</class> instead.
ClassMethod ObjectToJWT(ByRef JOSE As %String, Body As %DynamicObject, LocalPrivate As %String = "", RemotePublic As %String = "", Output JWT As %String) As %Status [ Deprecated ]
{
	Set keyalg = ##class(%Net.JSON.JWA).GetAlgInfo($get(JOSE("keyalg")))
	Set encalg = ##class(%Net.JSON.JWA).GetAlgInfo($get(JOSE("encalg")))
	Set sigalg = ##class(%Net.JSON.JWA).GetAlgInfo($get(JOSE("sigalg")))
	Set sigJOSE = "", encJOSE = ""
	Set sigJWKS = "", encJWKS = ""

	If ((keyalg'="")&&(encalg="")) || ((keyalg="")&&(encalg'="")) {
		Return $$$ERROR($$$OAuth2InvalidAlgCombination, $get(JOSE("keyalg")), $get(JOSE("encalg")))
	}
	If (sigalg="") && (keyalg="") {
		set sigalg = ##class(%Net.JSON.JWA).GetAlgInfo("none")
	}

	// set up sigining parameters
	If sigalg'="" {
		If sigalg.use'="sig" {
			Return $$$ERROR($$$OAuth2InvalidSigalg,sigalg.alg)
		}

		Set sigJOSE = {"alg":(sigalg.alg)}
		If sigalg.kty="oct" {
			// symmetric keys are stored in the RemotePublic JWKS
			Set sigJWKS = RemotePublic
		} ElseIf $case(sigalg.kty, "RSA":1, "EC":1, :0) {
			Set sigJWKS = LocalPrivate
			// set up jku and jwk headers, if requested
			If $data(JOSE("jku")),$get(JOSE("jku_local"))'="" {
				Set sigJOSE.jku=JOSE("jku_local")
			} ElseIf $data(JOSE("jwk")),$get(JOSE("jwks_local"))'="" {
				Do ##class(%Net.JSON.JWKS).GetJWK(sigalg.alg,,sigJWKS,.jwk)
				Do ##class(%Net.JSON.JWKS).GetJWK(sigalg.alg,jwk.kid,JOSE("jwks_local"),.pjwk)
				If (pjwk="") {
					Return $$$ERROR($$$OAuth2NoPublicKey,sigalg.alg_" ("_jwk.kid_")")
				}
				Set sigJOSE.jwk=pjwk
			}
		}
	}

	// set up encryption parameters
	If keyalg'="" {
		If ((keyalg.use'="enc")||(encalg."key_ops".%Get(0)'="encrypt")) {
			Return $$$ERROR($$$OAuth2InvalidAlgCombination,keyalg.alg,encalg.alg)
		}

		Set encJOSE = {"alg":(keyalg.alg), "enc":(encalg.alg)}
		Set encJWKS = RemotePublic

		If keyalg.alg="dir" {
			Set encJOSE.kid=encalg.alg
		}
		// set up jku and jwk headers, if requested
		If $case(keyalg.kty, "RSA":1, "EC":1, :0) {
			If $data(JOSE("jku")),$get(JOSE("jku_remote"))'="" {
				Set encJOSE.jku=JOSE("jku_remote")
			} ElseIf $data(JOSE("jwk")) {
				Do ##class(%Net.JSON.JWKS).GetJWK(keyalg.alg,,encJWKS,.jwk)
				Set encJOSE.jwk=jwk
			}
		}
	}

	// set up custom headers
	If $isobject($get(JOSE("custom"))) {
		Set it=JOSE("custom").%GetIterator()
		While it.%GetNext(.key,.value, .type) {
			If ",alg,jku,jwk,kid,x5u,x5c,x5t,x5t#S256,typ,cty,crit,"[(","_key_",") {
				Continue
			}
			If sigJOSE'="" {
				Do sigJOSE.%Set(key,value,type)
			} ElseIf encJOSE'="" {
				Do encJOSE.%Set(key,value,type)	
			}
		}
	}

	Return ##class(%Net.JSON.JWT).Create(sigJOSE, encJOSE, Body, sigJWKS, encJWKS, .JWT)
}

/// This method processes a JSON Web Token (JWT), performing decryption and/or signature verification operations as required.<br>
/// <br>
/// Input parameters:<br>
/// <br>
/// JWT - JSON Web Token<br>
/// <br>
/// LocalPrivate - Local Private JWKS
/// <br>
/// RemotePublic - Remote Public JWKS
/// <br>
/// Output parameters:<br>
/// <br>
/// JOSE - Output Array of Strings containing the algorithms used for
/// Signature and/or Encryption operations performed on the JWT.<br>
/// JOSE("sigalg") - Signature or MAC algorithm<br>
/// JOSE("keyalg") - Key management algorithm<br>
/// JOSE("encalg") - Content encryption algorithm<br>
/// <br>
/// Body - Output Object representation of the claims contained in the JWT<br>
/// Header - Output Object representation of the JWT header<br>
/// AcceptUnsecured - Boolean value indicating whether to consider a JWT signed with "alg":"none" as valid. Default is false (0).<br>
/// This method is deprecated. Use the <b>Validate</b> method in <class>%Net.JSON.JWT</class> instead.
ClassMethod JWTToObject(JWT As %String, LocalPrivate As %String = "", RemotePublic As %String = "", Output JOSE As %String, Output Body As %DynamicObject, Output Header As %DynamicObject, AcceptUnsecured As %Boolean = 0) As %Status [ Deprecated ]
{
	Set encJWKS = LocalPrivate 
	Set sigJWKS = RemotePublic

	Do ..GetSymmetricKeys(.sigJWKS,.encJWKS)

	Set sc = ##class(%Net.JSON.JWT).Validate(JWT, sigJWKS, encJWKS, AcceptUnsecured, .Body, .ops)
	Do ##class(%OAuth2.Utils).GetSecurityParams(ops, .JOSE)

	// return the innermost header
	If $isobject(ops) && (ops.%Size()>0) { 
		Set Header = ops.%Get(ops.%Size()-1).header
	}

	Return sc
}

ClassMethod GetSymmetricKeys(srcJWKS, dstJWKS) [ Private ]
{
	If '$isobject(srcJWKS) {
		Set srcJWKS = ##class(%DynamicObject).%FromJSON(srcJWKS)
		If '$isobject(srcJWKS) Return 
	}
	
	Set iterator = srcJWKS.keys.%GetIterator()
	While iterator.%GetNext(,.jwk) {
		If ##class(%Net.JSON.JWA).IsAlgSymmetric(jwk.alg) {
			Do ##class(%Net.JSON.JWKS).PutJWK(jwk,.dstJWKS)
		}
	}
}

}
