/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "ClassMapping" activity within a Manifest document
Class %Installer.ClassMapping Extends %Installer.Mapping [ ServerOnly = 1, System = 3 ]
{

/// Package to map
Property Package As %String(MAXLEN = 128) [ Required ];

/// Source namespace
Property From As %String [ Required ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.ClassMapping(tNSName,$$$EVAL("_..Package_"),$$$EVAL("_..From_"))")
	Quit $$$OK
}

}
