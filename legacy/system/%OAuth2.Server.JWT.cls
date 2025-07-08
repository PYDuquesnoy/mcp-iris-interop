/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %OAuth2.Server.JWT is the GenerateTokenClass which creates a JWT which is included with the server.
/// The GenerateTokenClass is specified in the Authorization Server Configuration.
/// It must contain a GenerateAccessToken method will be used to generate an access token based
/// on the array of properties that is returned by the ValidateUser method.
Class %OAuth2.Server.JWT Extends %OAuth2.Server.Generate [ System = 4 ]
{

/// The IsJWT method returns true if the GenerateAccessToken method returns a JWT.
/// IsJWT is used to determine inclusion of algorithms for access token in server metadata.
ClassMethod IsJWT() As %Boolean
{
	// True for JWT token
	Quit 1
}

/// The GenerateAccessToken method returns an optionally signed and/or encryypted JWT to be used
/// as an access token.  The access token may be based on the properties argument.
/// In addition values for claims to be added to the JSON response object may be returned in the
/// properties.ResponseProperties array.<br>
/// However the method in this default class just returns a JWT which is optionally signed and/or encrypted.
ClassMethod GenerateAccessToken(properties As %OAuth2.Server.Properties, Output sc As %Status) As %String
{
	#dim %server As OAuth2.Server.Configuration

	Try {
		$$$SysLog(3,"OAuth2Server","[%OAuth2.Server.JWT:GenerateAccessToken]","")

		// Create object containg claims required by IHE IUA supplement
		Set json=##class(%DynamicObject).%New()
		Set val=properties.GetClaimValue("iss")
		If val'="" {
			Do json.%Set("jti",val_"."_##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(20)),"string")
			Do json.%Set("iss",val,"string")
		}
		Set val=properties.GetClaimValue("sub")
		If val'="" {
			Do json.%Set("sub",val,"string")
		}
		Set val=properties.GetClaimValue("exp")
		If val'="" {
			Do json.%Set("exp",val,"number")
		}
		Set aud=properties.GetConvertedClaimValue("aud",.type)
		If aud'="" {
			If $isobject(aud) {
				Do json.%Set("aud",aud)
			} Else {
				Do json.%Set("aud",aud,"string")
			}
		}
		Set val=properties.GetClaimValue("scope")
		If val'="" {
			Do json.%Set("scope",val,"string")
		}
		Set val=properties.GetClaimValue("iat")
		If val '="" {
			Do json.%Set("iat",val,"number")
		}
		
		// Add Claims from JWTClaims in %OAuth2.Server.Properties.
		Do ..AddClaims(properties.JWTClaims,properties,json)
		
		// Add Claims from JWTHeaderClaims in %OAuth2.Server.Properties
		Set header = ##class(%DynamicObject).%New()
		If properties.JWTHeaderClaims.IsDefined("jku") {
			Set header.jku = ""
		} 
		If properties.JWTHeaderClaims.IsDefined("jwk") {
			Set header.jwk = ""
		}
		Do ..AddClaims(properties.JWTHeaderClaims,properties,header)
		// Create JWT
		Set JWT=..CreateJWT("",json,"access_token",.sc,header)

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Set JWT=""
	Quit JWT
}

/// The CreateJWT method acts as specified for OAuth 2.0 and OpenID Connect usage and
/// should not be overridden in a user subclass.<br>
/// Create JWT based on JSON object containing the claims.  
/// Any signing an encryption takes place here.
ClassMethod CreateJWT(token As OAuth2.Server.AccessToken, json As %RegisteredObject, jwtType As %String, Output sc As %Status, ByRef header As %DynamicObject = {$$$NULLOREF}) As %String [ Internal ]
{
	#dim %server As OAuth2.Server.Configuration
	#dim client As OAuth2.Server.Client
	
	If $namespace'="%SYS" {
		New $namespace 
		Set $namespace = "%SYS"
	}
	// Find the client oref	
	If $isobject(token) {
		Set client=##class(OAuth2.Server.Client).Open(token.ClientId,.sc)
		If $$$ISERR(sc) Quit ""
	} Else {
		Set client=%client
	}

	Do client.RefreshJWKS(%server.SSLConfiguration,,,.sc)

	// Setup client specified algorithms
	Set sigalg=$property(client.Metadata,jwtType_"_signed_response_alg")
	If jwtType="access_token", (sigalg="")||(sigalg="none"), %server.SigningAlgorithm'="" Set sigalg=%server.SigningAlgorithm
	If sigalg="none" Set sigalg=""  ; The JWT code expects "" for "none"

	Set encalg=$property(client.Metadata,jwtType_"_encrypted_response_enc")
	If jwtType="access_token", (encalg="")||(encalg="none"), %server.EncryptionAlgorithm'="" Set encalg=%server.EncryptionAlgorithm
	If encalg="none" Set encalg=""  ; The JWT code expects "" for "none"

	Set keyalg=$property(client.Metadata,jwtType_"_encrypted_response_alg")
	If jwtType="access_token", (keyalg="")||(keyalg="none"), %server.KeyAlgorithm'="" Set keyalg=%server.KeyAlgorithm
	If keyalg="none" Set keyalg=""  ; The JWT code expects "" for "none"

	// JWT access tokens must be signed
	If jwtType="access_token", sigalg="" { 
		Set sc = $$$ERROR($$$JWSNotSecured)
		Return ""
	}

	// Setup JWT parameters
	Set sigJOSE = ""
	Set encJOSE = ""
	Set sigSym = ##class(%Net.JSON.JWA).IsAlgSymmetric(sigalg)
	Set encSym = ##class(%Net.JSON.JWA).IsAlgSymmetric(keyalg)
	If sigalg'="" {
		Set sigJOSE = {"alg":(sigalg)}
		If $isobject(header), sigalg'="none", 'sigSym {
			If header.%IsDefined("jku") {
				If %server.Metadata."jwks_uri"="" {
					Do %server.UpdateMetadata()
				}
				Set sigJOSE.jku = %server.Metadata."jwks_uri"
			} ElseIf header.%IsDefined("jwk"), $$$ISOK(##class(%Net.JSON.JWKS).GetJWK(sigalg,,%server.PublicJWKS,.jwk)) {
				If jwk'="" {
					Set sigJOSE.jwk = jwk
				}
			}
		}
		$$$SysLog(3,"OAuth2Server","[%OAuth2.Server.JWT:CreateJWT]","Signing alg="_sigJOSE.%ToJSON())
	}
	If (encalg'="") || (keyalg'="") {
		Set encJOSE = {"alg":(keyalg),"enc":(encalg)}
		If $isobject(header), 'encSym {
			If header.%IsDefined("jku") {
				Set encJOSE.jku = client.Metadata."jwks_uri"
			} ElseIf header.%IsDefined("jwk"), $$$ISOK(##class(%Net.JSON.JWKS).GetJWK(keyalg,,client.PublicJWKS,.jwk)) {
				If jwk'="" {
					Set encJOSE.jwk = jwk
				}
			}
		}
		If keyalg="dir" {
			Set encJOSE.kid = encalg
		}
		$$$SysLog(3,"OAuth2Server","[%OAuth2.Server.JWT:CreateJWT]","Encryption alg="_encJOSE.%ToJSON())
	}
	
	// Process additional custom headers
	If $isobject(header) {
		Set iter = header.%GetIterator()
		While iter.%GetNext(.key, .value, .type) {
			If (key="jku") || (key="jwk") {
				continue
			}
			If sigJOSE'="" {
				Do sigJOSE.%Set(key, value, type)
			} ElseIf encJOSE'="" {
				Do encJOSE.%Set(key, value, type) 
			}
		}
	}
	// Create JWT
	If $$$ISOK(sc) {
		Set sigJWKS = $select(sigSym:client.SymmetricJWKS, 1:%server.PrivateJWKS)
		Set encJWKS = $select(encSym:client.SymmetricJWKS, 1:client.PublicJWKS)
		Set sc = ##class(%Net.JSON.JWT).Create(sigJOSE, encJOSE, json, sigJWKS, encJWKS, .JWT)
	}
	$$$SysLog(3,"OAuth2Server","[%OAuth2.Server.JWT:CreateJWT]","JWT="_$get(JWT))
	
	If $$$ISERR(sc) Set JWT=""
	Return JWT
}

/// Add requested claims to the JWT
ClassMethod AddClaims(claims As %ArrayOfObjects, properties As %OAuth2.Server.Properties, json As %DynamicObject)
{
	Set name=""
	For {
		Set name=claims.Next(name)
		If name="" Quit
		
		// aud claim is handled as a special case in SetAudClaim or directly in GenerateAccessToken
		If name="aud" Continue

		Set value=properties.GetConvertedClaimValue(name,.type)
		If value="" Continue

		If type="array" {
			// Cannot specify type for an array value
			Do json.%Set(name,value)
		} ElseIf type="object" {
			Do json.%Set(name,value)
		} Else {
			Do json.%Set(name,value,type)
		}
	}
}

}
