/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "import" activity within a Manifest document
Class %Installer.Import Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// File name (can be a directory also)
Property File As %String(MAXLEN = 1024) [ Required ];

/// Flags value
Property Flags As %String [ InitialExpression = "ck" ];

/// Ignore errors flag
Property IgnoreErrors As %String [ InitialExpression = "0" ];

/// Recurse flag
Property Recurse As %Installer.Boolean [ InitialExpression = 0 ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.Import(tNSName,$$$EVAL("_..File_"),$$$EVAL("_..Flags_"),$$$EVAL("_..IgnoreErrors_"),$$$EVAL("_..Recurse_"))")
	Quit $$$OK
}

}
