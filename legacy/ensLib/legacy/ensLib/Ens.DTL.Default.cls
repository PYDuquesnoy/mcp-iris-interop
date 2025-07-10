/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents the default case of a switch statement. It serves
/// to define a block of activities to be executed by default.
Class Ens.DTL.Default Extends Ens.DTL.CaseNode [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<default>
<assign property="target.name" value="james"/>
</default>
}

Parameter TAGNAME = "default";

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		// No need to write empty enabled default
		If ..Annotation'=""||(..Actions.Count())||..Disabled {

			Do pStream.Write("<default")

			If ..Disabled Do pStream.Write(" disabled="_$$$EA(1))

			If '..Expanded Do ..WriteExpandedAttribute(pStream)

			Do pStream.WriteLine(">")
			Do ..WriteAnnotationXML(pStream,0)

			Set tSC=..Actions.GenerateXML(pStream,language)
			If $$$ISERR(tSC) Quit

			Do pStream.WriteLine("</default>")

		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#; Delegate to the actions
		Set tSC=..Actions.Validate(.pStatus,pContext)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

/// Provide a user readable string which names the action
Method DisplayName() As %String
{
	Quit "Default"
}

}
