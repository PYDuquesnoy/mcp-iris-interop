/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The implementation of the XOAUTH2 SASL security mechanism
/// to be used with %Net.Authenticator, our implementation of the Simple Authentication 
/// and Security Layer (SASL) as defined by RFC 2222.
Class %Net.SASL.XOAUTH2 Extends %Net.SASL.Base [ Not ProcedureBlock, System = 3 ]
{

/// The name of the security mechanism.  
/// This name must be one of SASL mechanism names that is registered with IANA.
Property MechanismName As %String [ InitialExpression = "XOAUTH2" ];

/// The access token being authenticated
Property AccessToken As %String;

/// State of client side of authentication:<br>
/// 1 - initial
/// 2 - access token previously returned
Property state As %Integer [ Private ];

/// Start authentication based on UserName and AccessToken using the XOAUTH2 SASL mechanism.
Method Start(ByRef response As %String) As %Boolean
{
 if (..UserName="") || (..AccessToken="") quit 0
 set response=""  ; no initial response
 set ..state=1
 quit 1
}

/// Return next response based on challenge using the XOAUTH2 SASL mechanism.
/// Return value is false to indicate abort.
Method Next(challenge As %String, ByRef response As %String) As %Boolean
{
 // server challenge is ignored for XOAUTH2
 if ..state=1 {
 set response="user="_..UserName_$c(1)_"auth=Bearer "_..AccessToken_$c(1)_$c(1)
 set ..state=2
 quit 1
 } else {
 quit 0
 }
}

}
