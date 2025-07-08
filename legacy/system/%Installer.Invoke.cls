/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Invoke" activity within a Manifest document
Class %Installer.Invoke Extends %Installer.Sequence [ ServerOnly = 1, System = 3 ]
{

/// Class name
Property Class As %String(MAXLEN = 128) [ Required ];

/// Method name
Property Method As %String(MAXLEN = 128) [ Required ];

/// Place to store return value
Property Return As %String;

/// Check for status on return
Property CheckStatus As %Boolean;

/// Generate code for this document.
Method %OnBeforeGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	#dim tSC As %Status,tChild As %Installer.Arg,tArgs As %String,tPrefix As %String,tSuffix As %String
	#dim i
	
	Set tSC = $$$OK
	Do {
		// Disable processing of the children, we'll do it!
		Set ..skipChildren = 1		
		Set tArgs = ""
		
		If ..CheckStatus {
			Set tPrefix = "Set tSC="
			Set tSuffix = " Throw:$$$ISERR(tSC) ##class(%Installer.Exception).CreateFromStatus(tSC)"
		} ElseIf ..Return'="" {
			// The Return attribute allows you to store the return value
			Set tPrefix = "Do tInstaller.SetVariable($$$EVAL("_..Return_"),"
			Set tSuffix = ")"
		} Else {
			Set tPrefix = "Do "
			Set tSuffix = ""
		}
		
		// Walk the child nodes
		For i=1:1:..children.Count() {
			Set tChild = ..children.GetAt(i)
			
			Set tArgs = tArgs _",$$$EVAL("_tChild.Value_")"
		}
		
		// Finally, invoke the method
		Do pCode.WriteLine(..%Indent()_"Do tInstaller.PushNS(tNSName)")
		Do pCode.WriteLine(..%Indent()_tPrefix_"$classmethod($$$EVAL("_..Class_"),$$$EVAL("_..Method_")"_tArgs_")"_tSuffix)
		Do pCode.WriteLine(..%Indent()_"Do tInstaller.PopNS()")
		
	} While (0)

	Quit tSC
}

}
