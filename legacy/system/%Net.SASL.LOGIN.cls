/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The implementation of the LOGIN SASL security mechanism
/// to be used with %Net.Authenticator, our implementation of the Simple Authentication 
/// and Security Layer (SASL) as defined by RFC 2222.
Class %Net.SASL.LOGIN Extends %Net.SASL.Base [ Not ProcedureBlock, System = 3 ]
{

/// The name of the security mechanism.  
/// This name must be one of SASL mechanism names that is registered with IANA.
Property MechanismName As %String [ InitialExpression = "LOGIN" ];

/// State of client side of authentication:<br>
/// 1 - initial
/// 2 - userName previously returned
/// 3 - password previously returned
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
 // server challenge is ignored for LOGIN
 if ..state=1 {
 set response=..UserName
 set ..state=2
 quit 1
 } elseif ..state=2 {
 set response=..Password
 set ..state=""
 quit 1
 } else {
 quit 0
 }
}

}
