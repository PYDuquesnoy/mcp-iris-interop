/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a sequence of activities to be performed.
Class Ens.BPL.Sequence Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<sequence>
<trace value='"application for "_request.Name'/>
<assign property="response.RecordNumber" value="$r(999)"/>
<reply/>
<trace value='"record sent to "_request.Name'/>
</sequence>
}

/// This holds the Activity List
Property Activities As Ens.BPL.ActivityList;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		
		$$$EnterActivity($$$ActivitySequence,$$$SubActivityMain)
		
		Set tSC=..Activities.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		$$$LeaveActivity($$$ActivitySequence,$$$SubActivityMain)
		
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		Do pStream.Write("<sequence ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'=""||(..Activities.Count()) {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do ..GenerateAnnotation(pStream)
			}
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			
			Do pStream.WriteLine("</sequence>")
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
		#; Delegate to the activities
		Set tSC=..Activities.Validate(.pStatus,pContext)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set ..Activities=##class(Ens.BPL.ActivityList).%New()
		$$$ASSERT($IsObject(..Activities))
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	Quit "Sequence"
}

}
