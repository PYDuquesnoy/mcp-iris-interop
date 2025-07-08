/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "RoutineMapping" activity within a Manifest document
Class %Installer.RoutineMapping Extends %Installer.Mapping [ ServerOnly = 1, System = 3 ]
{

/// Routines to map
Property Routines As %String(MAXLEN = 128) [ Required ];

/// Routine type to map
Property Type As %String [ Required ];

/// Source namespace
Property From As %String [ Required ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.RoutineMapping(tNSName,$$$EVAL("_..Routines_"),$$$EVAL("_..Type_"),$$$EVAL("_..From_"))")
	Quit $$$OK
}

}
