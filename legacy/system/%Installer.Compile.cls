/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Compile" activity within a Manifest document
Class %Installer.Compile Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Class name to compile
Property Class As %String(MAXLEN = 128) [ Required ];

/// Compile flags value
Property Flags As %String [ InitialExpression = "ck" ];

/// Ignore errors flag
Property IgnoreErrors As %String [ InitialExpression = "0" ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.Compile(tNSName,$$$EVAL("_..Class_"),$$$EVAL("_..Flags_"),$$$EVAL("_..IgnoreErrors_"))")
	Quit $$$OK
}

}
