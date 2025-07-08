/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "ForEach" activity within a Manifest document
Class %Installer.ForEach Extends %Installer.Sequence [ ServerOnly = 1, System = 3 ]
{

/// Index key
Property Index As %String(MAXLEN = 512) [ Required ];

/// Values to loop over
Property Values As %String(MAXLEN = 32000) [ Required ];

/// Generate code for this document.
Method %OnBeforeGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent(-1)_"Set tList=$ListFromString($$$EVAL1("_..Values_"))")
	Do pCode.WriteLine(..%Indent(-1)_"Set tPtr=0")
	Do pCode.WriteLine(..%Indent(-1)_"While $ListNext(tList,tPtr,tValue) {")
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.SetVariable($$$EVAL("_..Index_"),tValue)")
	Quit $$$OK
}

Method %OnAfterGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent(-1)_"}")
	Quit $$$OK
}

}
