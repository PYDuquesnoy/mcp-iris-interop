/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the base class for a sequence of activities.
Class %Installer.Sequence Extends %XGEN.AbstractSequence [ Abstract, ServerOnly = 1, System = 3 ]
{

Parameter NAMESPACE = "INSTALLER";

Parameter XGENDOCUMENT = "%Installer.Manifest";

/// Reduces the amount of generated code
Parameter XMLFORMAT = "literal";

Method findChild(pName As %String, pIndex As %Integer = 1) As %XGEN.AbstractElement [ Internal ]
{
	#dim tSeen As %Integer
	#dim tResult As %XGEN.AbstractElement
	#dim i
	
	Set tSeen = 0
	Set tResult = $$$NULLOREF
	For i = 1:1:..children.Count() {
		#dim tChild As %XGEN.AbstractElement
		Set tChild = ..children.GetAt(i)
		
		If tChild.%ClassName(0) = pName {
			Set tSeen = tSeen + 1
			If tSeen = pIndex {
				Set tResult = tChild
				Quit
			}
		}		
	}
	
	Quit tResult
}

}
