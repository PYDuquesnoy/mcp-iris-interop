/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %callout

Class %OAuth2.JWK Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// This method converts an RSA key in PEM-encoded DER ASN.1 format to JSON Web Key (JWK) format.
/// <br><br>
/// Input parameters:
/// <br><br>
/// ASN1 - PEM-encoded DER ASN.1 representation of private or public RSA key.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Output parameter:
/// <br><br>
/// JWK - JWK representation of private or public RSA Key
/// This method is deprecated.
ClassMethod RSAASN1toJWK(ASN1 As %String, Password As %String = "", Output JWK As %DynamicObject) As %Status [ Deprecated ]
{
	Set st=$$$OK
	Try {
		If (Password'="") { Set props=$SYSTEM.Encryption.RSAASN1Parse(ASN1,Password) }
		Else { Set props=$SYSTEM.Encryption.RSAASN1Parse(ASN1) }
		Set JWK={}
		If ($ll(props)=8) {
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
		} ElseIf ($ll(props)=2) {
			/// Public key
			Set JWK.kty="RSA"
			Set JWK.n=$$$BASE64URLENCODE($li(props,1))
			Set JWK.e=$$$BASE64URLENCODE($li(props,2))
		} Else {
			Set st=$$$ERROR($$$OAuth2RSAParsingError) Quit
		}
		If $$$ISERR(st) Quit
	} Catch ex {
		Set st=ex.AsStatus()
	}
	Quit st
}

/// This method converts an RSA key in JSON Web Key (JWK) format to PEM-encoded DER ASN.1 format.
/// <br><br>
/// Input parameter:
/// <br><br>
/// JWK - JWK representation of private or public RSA Key
/// <br><br>
/// Output parameter:
/// <br><br>
/// ASN1 - PEM-encoded DER ASN.1 representation of private or public RSA key.
/// This method is deprecated.
ClassMethod RSAJWKtoASN1(JWK As %DynamicObject, Output ASN1 As %String) As %Status [ Deprecated ]
{
	Set st=$$$OK
	Try {
		If JWK.kty'="RSA" Set st=$$$ERROR($$$OAuth2InvalidRSAType) Quit
		Set n=$$$BASE64URLDECODE(JWK.n)
		Set e=$$$BASE64URLDECODE(JWK.e)
		If ((n="")||(e="")) Set st=$$$ERROR($$$OAuth2InvalidRSAParameters) Quit
		Set d=$$$BASE64URLDECODE(JWK.d)
		Set p=$$$BASE64URLDECODE(JWK.p)
		Set q=$$$BASE64URLDECODE(JWK.q)
		Set dp=$$$BASE64URLDECODE(JWK.dp)
		Set dq=$$$BASE64URLDECODE(JWK.dq)
		Set qi=$$$BASE64URLDECODE(JWK.qi)
		If ((d'="")&&(p'="")&&(q'="")&&(dp'="")&&(dq'="")&&(qi'="")) {
			/// Private key
			Set der=$SYSTEM.Encryption.RSAASN1Construct(n,e,d,p,q,dp,dq,qi)
			Set private=1
		} ElseIf ((d="")&&(p="")&&(q="")&&(dp="")&&(dq="")&&(qi="")) {
			/// Public key
			Set der=$SYSTEM.Encryption.RSAASN1Construct(n,e)
			Set private=0
		} Else {
			Set st=$$$ERROR($$$OAuth2InvalidRSAParameters) Quit
		}
		If der="" Set st=$$$ERROR($$$OAuth2RSAConstructionError) Quit
		Set der=$SYSTEM.Encryption.Base64Encode(der,1)
		If (private) {
			Set ASN1="-----BEGIN RSA PRIVATE KEY-----"_$c(10)
		} Else {
			Set ASN1="-----BEGIN RSA PUBLIC KEY-----"_$c(10)
		}
		Set first=1,last=$l(der)
		While ((last-first)>=63) {
			Set ASN1=ASN1_$e(der,first,first+63)_$c(10)
			Set first=first+64
		}
		If (first<=last)	{
			Set ASN1=ASN1_$e(der,first,last)_$c(10)
		}
		If (private) {
			Set ASN1=ASN1_"-----END RSA PRIVATE KEY-----"_$c(10)
		} Else {
			Set ASN1=ASN1_"-----END RSA PUBLIC KEY-----"_$c(10)
		}
	} Catch ex {
		Set st=ex.AsStatus()
	}
	Quit st
}

/// This method converts an EC key in PEM-encoded DER ASN.1 format to JSON Web Key (JWK) format.
/// <br><br>
/// Input parameters:
/// <br><br>
/// ASN1 - PEM-encoded DER ASN.1 representation of private or public EC key.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Output parameter:
/// <br><br>
/// JWK - JWK representation of private or public EC Key
/// This method is deprecated.
ClassMethod ECASN1toJWK(ASN1 As %String, Password As %String = "", Output JWK As %DynamicObject) As %Status [ Deprecated ]
{
	Set st=$$$OK
	Try {
		If (Password'="") { Set props=$SYSTEM.Encryption.ECASN1Parse(ASN1,Password) }
		Else { Set props=$SYSTEM.Encryption.ECASN1Parse(ASN1) }
		Set JWK={}
		If ($ll(props)=4) {
			/// Private key
			Set JWK.kty="EC"
			Set curve=$li(props,1)
			Set JWK.crv=$case(curve,256:"P-256",384:"P-384",521:"P-521",:"")
			Set coordinateSize=$case(curve,256:32,384:48,521:66,:0)
			Set x=$list(props,2)
			Set y=$list(props,3)
			If ($length(x)<coordinateSize) {
				Set x=$char(0)_x
			}
			If ($length(y)<coordinateSize) {
				Set y=$char(0)_y
			}
			Set JWK.x=$$$BASE64URLENCODE(x)
			Set JWK.y=$$$BASE64URLENCODE(y)
			Set JWK.d=$$$BASE64URLENCODE($li(props,4))
		} ElseIf ($ll(props)=3) {
			/// Public key
			Set JWK.kty="EC"
			Set curve=$li(props,1)
			Set JWK.crv=$case(curve,256:"P-256",384:"P-384",521:"P-521",:"")
			Set coordinateSize=$case(curve,256:32,384:48,521:66,:0)
			Set x=$list(props,2)
			Set y=$list(props,3)
			If ($length(x)<coordinateSize) {
				Set x=$char(0)_x
			}
			If ($length(y)<coordinateSize) {
				Set y=$char(0)_y
			}
			Set JWK.x=$$$BASE64URLENCODE(x)
			Set JWK.y=$$$BASE64URLENCODE(y)
		} Else {
			Set st=$$$ERROR($$$OAuth2ECParsingError) Quit
		}
		If $$$ISERR(st) Quit
	} Catch ex {
		Set st=ex.AsStatus()
	}
	Quit st
}

/// This method converts an EC key in JSON Web Key (JWK) format to PEM-encoded DER ASN.1 format.
/// <br><br>
/// Input parameter:
/// <br><br>
/// JWK - JWK representation of private or public EC Key
/// <br><br>
/// Output parameter:
/// <br><br>
/// ASN1 - PEM-encoded DER ASN.1 representation of private or public EC key.
/// This method is deprecated.
ClassMethod ECJWKtoASN1(JWK As %DynamicObject, Output ASN1 As %String) As %Status [ Deprecated ]
{
	Set st=$$$OK
	Try {
		If JWK.kty'="EC" Set st=$$$ERROR($$$OAuth2InvalidECType) Quit
		Set crv=(JWK.crv)
		Set x=$$$BASE64URLDECODE(JWK.x)
		Set y=$$$BASE64URLDECODE(JWK.y)
		If ($case(crv,"P-256":0,"P-384":0,"P-521":0,:1)||(x="")||(y="")) Set st=$$$ERROR($$$OAuth2InvalidECParameters) Quit
		Set curve=$case(crv,"P-256":256,"P-384":384,"P-521":521,:0)
		Set d=$$$BASE64URLDECODE(JWK.d)
		If (d'="") {
			/// Private key
			Set der=$SYSTEM.Encryption.ECASN1Construct(curve,x,y,d)
			Set private=1
		} Else {
			/// Public key
			Set der=$SYSTEM.Encryption.ECASN1Construct(curve,x,y)
			Set private=0
		}
		If der="" Set st=$$$ERROR($$$OAuth2ECConstructionError) Quit
		Set der=$SYSTEM.Encryption.Base64Encode(der,1)
		If (private) {
			Set ASN1="-----BEGIN EC PRIVATE KEY-----"_$c(10)
		} Else {
			Set ASN1="-----BEGIN PUBLIC KEY-----"_$c(10)
		}
		Set first=1,last=$l(der)
		While ((last-first)>=63) {
			Set ASN1=ASN1_$e(der,first,first+63)_$c(10)
			Set first=first+64
		}
		If (first<=last)	{
			Set ASN1=ASN1_$e(der,first,last)_$c(10)
		}
		If (private) {
			Set ASN1=ASN1_"-----END EC PRIVATE KEY-----"_$c(10)
		} Else {
			Set ASN1=ASN1_"-----END PUBLIC KEY-----"_$c(10)
		}
	} Catch ex {
		Set st=ex.AsStatus()
	}
	Quit st
}

}
