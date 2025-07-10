/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a block of activities to be performed for a particular
/// case within a <switch> tag.
Class Ens.DTL.Case Extends Ens.DTL.CaseNode [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<switch>
<case condition="$Extract(source.SSN)=2">
<assign property="target.name" value="james"/>
</case>
</switch>
}

Parameter TAGNAME = "case";

/// This holds the condition which selects this case
Property Condition As %String;

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Do pStream.Write("<case condition="_$$$EA(..Condition))

		If ..Disabled Do pStream.Write("disabled="_$$$EA(1))

		If '..Expanded Do ..WriteExpandedAttribute(pStream)

		If ..Annotation'=""||(..Actions.Count()) {

			Do pStream.WriteLine(">")
			Do ..WriteAnnotationXML(pStream,0)

			Set tSC=..Actions.GenerateXML(pStream,language)
			If $$$ISERR(tSC) Quit

			Do pStream.WriteLine("</case>")

		} else {

			Do pStream.WriteLine("/>")

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

		#; Must know the condition we want to test
		If ..Condition="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"condition",..DisplayName()))
		}

		#; Validate any activities
		Set tSC=..Actions.Validate(.pStatus,pContext)

	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "Case"
}

}
