/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class groups actions together, and is used wherever more than one action
/// needs to be defined
Class Ens.DTL.ActionList Extends Ens.DTL.NodeList [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "Ens.DTL.Action";

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCommentChar = $select(pCompiler.Language = $$$objectscript: ";", pCompiler.Language = $$$python: ";",1: "'")
		For tI=1:1:..Count() {
			Set tAction = ..GetAt(tI)
			If $IsObject(tAction) {
				If tAction.Disabled {
					$$$PCIndent(pCompiler.Indent,tCommentChar_" Disabled '"_tAction.#TAGNAME_"'")
				}
				Else {
					Set tSC = tAction.GenerateCode(pCompiler)
					If $$$ISERR(tSC) Quit
				}
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
