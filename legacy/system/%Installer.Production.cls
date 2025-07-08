/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Production" activity within a Manifest document.
/// It configures a production; contains and applies
/// the "Settings" and "Credentials" tags.
Class %Installer.Production Extends %Installer.Sequence [ ServerOnly = 1, System = 3 ]
{

/// Production name name
Property Target As %String(XMLNAME = "Name") [ Required ];

/// AutoStart value
Property AutoStart As %Installer.Boolean [ InitialExpression = 0 ];

/// Generate code for this document.
Method %OnBeforeGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Kill tSettings,tCredentials")
	Quit $$$OK
}

/// Generate code for this document.
Method %OnAfterGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.Production(tNSName,$$$EVAL("_..Target_"),$$$EVAL("_..AutoStart_"),.tSettings,.tCredentials)")
	Quit $$$OK
}

}
