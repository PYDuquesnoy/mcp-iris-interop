/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "SystemSetting" activity within a Manifest document
Class %Installer.SystemSetting Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Setting name
Property Target As %String(MAXLEN = 128, XMLNAME = "Name") [ Required ];

/// Variable value, note that this must be a literal value.
Property Value As %String(MAXLEN = 32000) [ Required ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.SystemSetting($$$EVAL("_..Target_"),$$$EVAL1("_..Value_"))")
	Quit $$$OK
}

}
