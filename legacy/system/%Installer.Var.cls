/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "var" activity within a Manifest document
Class %Installer.Var Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Variable name
Property Target As %String(MAXLEN = 128, XMLNAME = "Name") [ Required ];

/// Variable value
Property Value As %String(MAXLEN = 32000);

/// Directory property
Property Dir As %String(MAXLEN = 1024);

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	If ..Dir'="" {
		Do pCode.WriteLine(..%Indent()_"Do tInstaller.SetVariable($$$EVAL("_..Target_"),##class(%File).NormalizeDirectory($$$EVAL("_..Dir_")))")
	} Else {
		Do pCode.WriteLine(..%Indent()_"Do tInstaller.SetVariable($$$EVAL("_..Target_"),$$$EVAL1("_..Value_"))")
	}
	Quit $$$OK
}

}
