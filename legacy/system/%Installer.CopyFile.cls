/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "CopyFile" activity within a Manifest document
Class %Installer.CopyFile Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Source File name
Property Src As %String(MAXLEN = 1024) [ Required ];

/// Target File name
Property Target As %String(MAXLEN = 1024) [ Required ];

/// Ignore errors flag
Property IgnoreErrors As %String [ InitialExpression = "0" ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.CopyFile($$$EVAL("_..Src_"),$$$EVAL("_..Target_"),$$$EVAL("_..IgnoreErrors_"))")
	Quit $$$OK
}

}
