/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "CopyClass" activity within a Manifest document
Class %Installer.CopyClass Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Source Class name
Property Src As %String(MAXLEN = 128) [ Required ];

/// Target Class name
Property Target As %String(MAXLEN = 128) [ Required ];

/// Overwrite flag
Property Replace As %String;

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.PushNS($S($G(tNSName)'="""":tNSName,1:$NAMESPACE))")
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.CopyClass($$$EVAL("_..Src_"),$$$EVAL("_..Target_"),+$$$EVAL("_..Replace_"))")
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.PopNS()")

	Quit $$$OK
}

}
