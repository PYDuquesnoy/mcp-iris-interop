/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Log" activity within a Manifest document
Class %Installer.Log Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Level
Property Level As %Integer [ Required ];

/// Topic
Property Topic As %String;

/// Message
Property Text As %String(MAXLEN = 32000);

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.Log("_..Level_",$$$EVAL("_..Topic_"),$$$EVAL("_..Text_"))")
	Quit $$$OK
}

}
