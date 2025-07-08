/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "User" activity within a Manifest document
Class %Installer.User Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Username
Property Username As %Library.Username [ Required ];

/// Roles
Property Roles As %String [ Required ];

/// Password variable name (passwords must come from a %Installer var for security reasons)
Property PasswordVar As %String [ Required ];

/// User's full name
Property Fullname As %String [ Required ];

/// Namespace
Property Namespace As %String;

/// Routine
Property Routine As %String;

/// Expiration date
Property ExpirationDate As %String;

/// Force user to change password
Property ChangePassword As %Installer.Boolean;

/// User Enabled
Property Enabled As %Installer.Boolean;

/// Comment
Property Comment As %String;

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.CreateUser($$$EVAL("_..Username_"),$$$EVAL1("_..Roles_"),"_$S(..PasswordVar'="":"tInstaller.GetVariable("""_..PasswordVar_""",,0)",1:"""""")_",$$$EVAL("_..Fullname_"),$$$EVAL("_..Namespace_"),$$$EVAL("_..Routine_"),$$$EVAL("_..ExpirationDate_"),$$$EVAL("_..ChangePassword_"),$$$EVAL("_..Enabled_"),$$$EVAL("_..Comment_"))")
	Quit $$$OK
}

}
