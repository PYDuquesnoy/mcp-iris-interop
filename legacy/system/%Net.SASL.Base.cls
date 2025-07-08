/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The abstract super class of all security mechanisms to be used
/// with %Net.Authenticator, our implement of the Simple Authentication 
/// and Security Layer (SASL) as defined by RFC 2222.
/// <p>Each defined mechanism will add additional properties defining the 
/// parameters needed for the mechanism and override the emthods defined here.
Class %Net.SASL.Base Extends %RegisteredObject [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// The name of the security mechanism.  
/// This name must be one of SASL mechanism names that is registered with IANA.
Property MechanismName As %String;

/// The user name being authenticated.
/// No authentication will be attempted unless UserName and Password are supplied.
Property UserName As %Library.Username;

/// The password for the user name being authenticated.
Property Password As %String;

/// Start authentication based on UserName and Password using this mechanism.
Method Start(ByRef response As %String) As %Boolean
{
 quit 0
}

/// Return next response based on challenge using this SASL mechanism.
/// Return value is false to indicate abort.
Method Next(challenge As %String, ByRef response As %String) As %Boolean
{
 quit 0
}

}
