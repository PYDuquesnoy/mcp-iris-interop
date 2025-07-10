/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a block of activities to be performed for a particular
/// case within a <switch> tag.
Class Ens.BPL.Case Extends Ens.BPL.CaseNode [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<switch>
<case condition="$Extract(request.SSN)=2">
<assign property="callrequest.name" value="james"/>
</case>
</switch>
}

/// This holds the name of the case ( case label )
Property Name As %String;

/// This holds the condition which selects this case
Property Condition As %String;

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		Do pStream.Write("<case condition="_$$$EA(..Condition))
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		If ..LanguageOverride'="" Do pStream.Write("languageOverride="_$$$EA(..LanguageOverride))
		
		If ..Activities.Count() {
		
			Do pStream.WriteLine(">")
				
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
		
			Do pStream.WriteLine("</case>")
			
		} else {
			
			Do pStream.WriteLine("/>")
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
		#; Must have Condition
		If ..Condition="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"condition",..DisplayName()))
		}
		
		#; Validate any activities
		Set tSC=..Activities.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
			
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
	Quit "Case :"_$Get(..Name,"<noname>")
}

}
