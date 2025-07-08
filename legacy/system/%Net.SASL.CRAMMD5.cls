/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The implementation of the CRAM-MD5 SASL security mechanism
/// to be used with %Net.Authenticator, our implementation of the Simple Authentication 
/// and Security Layer (SASL) as defined by RFC 2222.
Class %Net.SASL.CRAMMD5 Extends %Net.SASL.Base [ Not ProcedureBlock, System = 3 ]
{

/// The name of the security mechanism.  
/// This name must be one of SASL mechanism names that is registered with IANA.
Property MechanismName As %String [ InitialExpression = "CRAM-MD5" ];

/// State of client side of authentication:<br>
/// 1 - return CRAM-MD5 result
Property state As %Integer [ Private ];

/// Start authentication based on UserName and Password using the PLAIN SASL mechanism.
Method Start(ByRef response As %String) As %Boolean
{
 if (..UserName="") || (..Password="") quit 0
 set response=""  ; no initial response
 set ..state=1
 quit 1
}

/// Return next response based on challenge using the PLAIN SASL mechanism.
/// Return value is false to indicate abort.
Method Next(challenge As %String, ByRef response As %String) As %Boolean
{
 new digest,secret
 if ..state=1 {
 if challenge>1024 quit 0

 set secret=..Password
 if $length(secret)>64 {
 set secret=$system.Encryption.MD5Encode(secret)
 }
 set $piece(secret,$c(0),65-$length(secret))=""

 set digest=..makeDigest(challenge,secret)

 set response=..UserName_" "_..ConvertToHex(digest)
 set ..state=""
 quit 1

 } else {
 quit 0
 }
}

/// Compute keyed-MD5 digest.
Method makeDigest(challenge As %String, secret As %String) As %String [ Private ]
{
 new ipad,opad,digest
 set ipad=$zboolean(secret,$c(54),6)
 set opad=$zboolean(secret,$c(92),6)
 set digest=$system.Encryption.MD5Encode(ipad_challenge)
 set digest=$system.Encryption.MD5Encode(opad_digest)
 quit digest
}

/// Return string with each character converted to lower case hex.
Method ConvertToHex(str As %String) As %String [ Private ]
{
 new i,hex,hexchar
 set hex=""
 for i=1:1:$length(str) {
 set hexchar=$zhex($ascii(str,i))
 set hex=hex_$select($length(hexchar)=1:"0"_hexchar,1:hexchar)
 }
 quit $zcvt(hex,"L")
}

}
