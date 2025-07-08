/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Resource" activity within a Manifest document
Class %Installer.Resource Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Namespace name
Property Target As %String(XMLNAME = "Name") [ Required ];

/// Description
Property Description As %String(MAXLEN = 32000) [ Required ];

/// Permission
Property Permission As %String(MAXLEN = 16) [ Required ];

/// Type (Internal Use Only)
Property Type As %String(MAXLEN = 16) [ InitialExpression = 0 ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent(-1)_"Do tInstaller.CreateResource($$$EVAL("_..Target_"),$$$EVAL("_..Description_"),$$$EVAL("_..Permission_"),+$$$EVAL("_..Type_"))")
	Quit $$$OK
}

}
