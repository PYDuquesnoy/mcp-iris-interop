/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an "Error" activity within a Manifest document.
/// It throws an exception--note that the ${} and #{} syntax
/// is not available for this activity.
Class %Installer.Error Extends %Installer.Sequence [ ServerOnly = 1, System = 3 ]
{

/// Status (note: ${} and #{} expansion doesn't work here) passed
/// in as a first argument into the $$$ERROR macro.
Property Status As %String [ Required ];

/// Source passed in as a last argument into the $$$ERROR macro.
Property Source As %String(MAXLEN = 128);

/// Generate code for this document.
Method %OnBeforeGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	#dim tSC As %Status
	#dim tChild As %Installer.Arg
	#dim tArgs As %String
	#dim tCount As %Integer
	#dim i
	
	Set tSC = $$$OK
	Do {
		// Disable processing of the children, we'll do it!
		Set ..skipChildren = 1
		Set tCount = ..children.Count()
		Set:tCount>8 tCount=8
		Set tArgs = ",,,,,,,,$$$EVAL("_..Source_")"
		
		// Walk the child nodes
		For i=1:1:tCount {
			Set tChild = ..children.GetAt(i)
			
			Set $PIECE(tArgs,",",i) = "$$$EVAL("_tChild.Value_")"
		}
		
		// Finally, generate the error
		Do pCode.WriteLine(..%Indent()_"Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR("_..Status_","_tArgs_"))")
		
	} While (0)

	Quit tSC
}

}
