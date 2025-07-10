/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Common superclass for actions grouped together.
Class Ens.DTL.Group Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<group>
<assign property="target.name" value="james"/>
<assign property="target.other" value="cat"/>
</group>
}

Parameter TAGNAME = "group";

/// This holds the activities to be performed for this case
Property Actions As Ens.DTL.ActionList;

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Set tSC=..Actions.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Set ..Actions=##class(Ens.DTL.ActionList).%New()
		$$$ASSERT($IsObject(..Actions))

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {


		Do pStream.Write("<"_..#TAGNAME )

		If ..Disabled Do pStream.Write(" disabled="_$$$EA(1))

		If '..Expanded Do ..WriteExpandedAttribute(pStream)

		Do pStream.WriteLine(">")
		Do ..WriteAnnotationXML(pStream,0)

		Set tSC=..Actions.GenerateXML(pStream,language)
		If $$$ISERR(tSC) Quit

		Do pStream.WriteLine("</group>")

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Delegate to the activities
		Set tSC=..Actions.Validate(.pStatus,pContext)

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
