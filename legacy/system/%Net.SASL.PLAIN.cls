/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The implementation of the PLAIN SASL security mechanism defined in RFC 2595
/// to be used with %Net.Authenticator, our implementation of the Simple Authentication 
/// and Security Layer (SASL) as defined by RFC 2222.
Class %Net.SASL.PLAIN Extends %Net.SASL.Base [ Not ProcedureBlock, System = 3 ]
{

/// The name of the security mechanism.  
/// This name must be one of SASL mechanism names that is registered with IANA.
Property MechanismName As %String [ InitialExpression = "PLAIN" ];

/// Start authentication based on UserName and Password using the PLAIN SASL mechanism.
Method Start(ByRef response As %String) As %Boolean
{
 if (..UserName="") || (..Password="") quit 0
 set response=$c(0)_..UserName_$c(0)_..Password
 quit 1
}

/// Return next response based on challenge using the PLAIN SASL mechanism.
/// Return value is false to indicate abort.
Method Next(challenge As %String, ByRef response As %String) As %Boolean
{
 quit 0
}

}
