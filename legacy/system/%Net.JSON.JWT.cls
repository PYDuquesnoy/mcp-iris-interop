/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides methods to create and validate JSON Web Tokens, as defined in RFC 7519.
Class %Net.JSON.JWT Extends %RegisteredObject [ System = 4 ]
{

/// This method creates a JSON Web Token (JWT).
/// <br><br>
/// Input parameters:
/// <ul><li>
/// sigJOSE - Object representation of the JSON Object Signing and Encryption (JOSE) Header to be used if this JWT is going to be signed.
/// </li><li>
/// encJOSE - Object representation of the JSON Object Signing and Encryption (JOSE) Header to be used if this JWT is going to be encrypted.
/// </li><li>
/// claims - Object representation of the claims to be contained in the JWT.
/// </li><li>
/// sigJWKS - The JSON Web Key Set (JWKS) that contains the key to be used for signing this JWT (if it is going to be signed).
/// This defaults to null.
/// </li><li>
/// encJWKS - The JWKS that contains the key to be used for encrypting this JWT (if it is going to be encrypted).
/// This defaults to null.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// JWT - The JWT that is created.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not a JWT could be created given the provided inputs, where error values indicate that a
/// JWT could not be created and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// If sigJOSE is defined, then sigJWKS must also be defined unless the signing algorithm is "none".
/// </li><li>
/// If encJOSE is defined, then encJWKS must also be defined.
/// </li><li>
/// If both sigJOSE and encJOSE are defined, then the JWT will be signed, then encrypted as recommended in RFC 7519 section 11.2.
/// </li><li>
/// sigJWKS and encJWKS can be the same JWKS, but if both signing and encryption are to be used then the arguments must both be passed
/// (even if they contain the same value).</li></ul>
ClassMethod Create(sigJOSE As %DynamicObject, encJOSE As %DynamicObject, claims As %DynamicObject, sigJWKS As %String = "", encJWKS As %String = "", Output JWT As %String) As %Status
{
	Set JWT=""

	Set sign=($get(sigJOSE)'="")
	Set encrypt=($get(encJOSE)'="")
	If ('sign && 'encrypt) {
		Return $$$ERROR($$$NoJOSEHeader)
	}

	If ($get(claims)="") {
		Return $$$ERROR($$$NoClaims)
	}

	// Convert the claim set to JSON format
	Try {
		Set message=claims.%ToJSON()
		Set message=$zcvt(message,"O","UTF8")
	} Catch ex {
		Return ex.AsStatus()
	}

	// First, sign the JWT (if it is going to be signed)
	If sign {
		Try {
			Set sigJOSE.typ="JWT"
			Set sc=##class(%Net.JSON.JWS).Sign(sigJOSE,,message,,sigJWKS,.JWS)
		} Catch ex {
			Set sc=ex.AsStatus()
		}
		If $$$ISERR(sc) {
			Return sc
		}
	}

	// Then, encrypt the JWT (if it is going to be encrypted)
	If encrypt {
		Try {
			Set encJOSE.typ="JWT"
			If sign {
				Set encJOSE.cty="JWT"
				Set message=JWS
			}
			Set sc=##class(%Net.JSON.JWE).Encrypt(encJOSE,,,message,,,encJWKS,.JWE)
		} Catch ex {
			Set sc=ex.AsStatus()
		}
		If $$$ISERR(sc) {
			Return sc
		}
	}

	// Encryption is performed last, regardless of signing, so if encryption happened then the
	// resulting JWE should be used as the JWT. If no encryption, then use the JWS as the JWT
	If encrypt {
		Set JWT=JWE
	} Else {
		Set JWT=JWS
	}

	Return $$$OK
}

/// This method validates a JSON Web Token (JWT).
/// <br><br>
/// Input parameters:
/// <ul><li>
/// JWT - The JWT to be validated.
/// </li><li>
/// sigJWKS - The JSON Web Key Set (JWKS) that contains the key to be used for verifying this JWT's signature (if it was signed).
/// This defaults to null.
/// </li><li>
/// encJWKS - The JWKS that contains the key to be used for decrypting this JWT (if it was encrypted).
/// This defaults to null.
/// </li><li>
/// acceptUnsecured - Boolean value indicating whether to accept unsecured JWTs or not.
/// This defaults to false.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// claims - Object representation of the claims contained in the JWT.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the provided JWT was validated given the provided JWKSs, where error values indicate that the
/// JWT is not valid and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// sigJWKS and encJWKS can be the same JWKS, but if both signing and encryption were used then the arguments must both be passed
/// (even if they contain the same value).</li></ul>
ClassMethod Validate(JWT As %String, sigJWKS As %String = "", encJWKS As %String = "", acceptUnsecured As %Boolean = 0, Output claims As %DynamicObject, Output operations As %DynamicArray) As %Status
{
	Set claims=""
	Set operations = []
	If ($get(JWT)="") {
		Return $$$ERROR($$$NoJWT)
	}

	// JWTs can be signed, encrypted, or some combination of both. The specs recommend that if both signing and 
	// encryption are going to be used to create a JWT, signing should occur first and be followed by encryption. 
	// However, the spec technically allows for any number and any combination of signature and encryption 
	// operations to be performed, so this loop has been made general enough to handle all cases.
	Set toValidate=1
	Try {
		While (toValidate) {
			If (($length(JWT,".")'=3) && ($length(JWT,".")'=5)) {
				Return $$$ERROR($$$InvalidJWT)
			}

			// Identify and decode the header
			Set b64header=$piece(JWT,".",1)
			Set utf8header=$$$BASE64URLDECODE(b64header)
			Set jsonheader=$zconvert(utf8header,"I","UTF8")
			Set header=##class(%DynamicObject).%FromJSON(jsonheader)

			// Nested JWTs are indicated by a header cty value of JWT
			Set isNested=($zconvert(header.cty,"L")="jwt")

			If ($length(JWT,".")=5) {
				// JWTs that were encrypted have 5 parts, so if this JWT has 5 parts attempt to decrypt it
				Set sc=##class(%Net.JSON.JWE).Decrypt(JWT,encJWKS,.plaintext,.decryptions)
				If $isobject(decryptions) {
					Do operations.%Push(decryptions.%Get(0))
				}
				If $$$ISERR(sc) {
					Return sc
				}
				Set body=plaintext
			} Else {
				// JWTs that were signed have 3 parts, so if this JWT does not have 5 parts attempt to validate its signature
				Set valid=##class(%Net.JSON.JWS).Validate(JWT,sigJWKS,acceptUnsecured,.validations)
				If $isobject(validations) {
					Do operations.%Push(validations.%Get(0))
				}
				If 'valid {
					Return $$$ERROR($$$InvalidJWTWithArg,validations.%Get(0).error)
				}
				Set body=$zconvert($$$BASE64URLDECODE($piece(JWT,".",2)),"I","UTF8")
			}

			If isNested {
				// If a nested JWT, we know that the body of the outer JWT is the inner JWT so update accordingly and repeat
				Set JWT=body
			} Else {
				// If not a nested JWT then the body of the JWT is the claim set, so identify it and prepare to return
				Set claims=##class(%DynamicObject).%FromJSON(body)
				Set toValidate=0
			}
		}
	} Catch ex {
		Return ex.AsStatus()
	}

	Return $$$OK
}

}
