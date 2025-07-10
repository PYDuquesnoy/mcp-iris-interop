/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents the default case of a switch statement. It serves
/// to define a block of activities to be executed by default.
Class Ens.BPL.Default Extends Ens.BPL.CaseNode [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<default>
<assign property="callrequest.name" value="james"/>
</default>
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<default")
		If ..Name'="" Do pStream.Write(" name="_$$$EA(..Name))

		if ..Activities.Count() = 0 {
			Do pStream.WriteLine("/>")
		} else {
			Do pStream.WriteLine(">")
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
		
			Do pStream.WriteLine("</default>")
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Delegate to the activities
		Set tSC=..Activities.Validate(.pStatus,pContext)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "Default"
}

}
