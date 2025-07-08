/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Credential" activity within a Manifest document. It must be
/// passed within the "Production" tag. Some remote systems require an 
/// username and password to log into that system--a username-password pair
/// is a login credential. Login credentials are stored
/// in a centralized, secure table; only users with appropriate access to 
/// the Management Portal can view and edit this table.
Class %Installer.Credential Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Credential name
Property Target As %String(MAXLEN = 128, XMLNAME = "Name") [ Required ];

/// Username
Property Username As %Library.Username [ Required ];

/// Password
Property Password As %String(MAXLEN = 128);

/// Overwrite flag
Property Overwrite As %String;

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent(-1)_"Set tCredentials($$$EVAL("_..Target_"))=$LB($$$EVAL("_..Username_"),$$$EVAL("_..Password_"),+$$$EVAL("_..Overwrite_"))")
	Quit $$$OK
}

}
