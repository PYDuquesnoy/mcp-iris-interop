/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Catch attempts to match the thrown fault, (see Ens.BPL.Throw) and if successful the activities within the block
/// defined by the catch will be executed.
Class Ens.BPL.Catch Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<process language='objectscript' request='Test.Scope.Request' response='Test.Scope.Response' >
  <sequence>
    <trace value='"before outer scope"'/>
    <scope>
      <trace value='"in outer scope, before inner scope"'/>
      <scope>
        <trace value='"in inner scope, before throw"'/>
        <throw fault='"MyFault"'/>
        <trace value='"in inner scope, after throw"'/>
        <faulthandlers>
          <catch fault='"MismatchedFault"'>
            <trace value='"In inner scope catch faulthandler for &apos;MismatchedFault&apos;"'/>
          </catch>
        </faulthandlers>
      </scope>
      <trace value='"in outer scope, after inner scope"'/>
      <faulthandlers>
        <catch fault='"MyFault"'>
          <trace value='"In outer scope catch faulthandler for &apos;MyFault&apos;"'/>
        </catch>
      </faulthandlers>
    </scope>
    <trace value='"after outer scope"'/>
  </sequence>
</process>
}

/// This holds the filter expression which must evaluate to a thrown fault string
Property Fault As %String;

/// This holds the Activity List
Property Activities As Ens.BPL.ActivityList;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		
		#; A catch has its own label scope
		Do pCompiler.CurrentThread.PushLabelScope()
		
		$$$EnterActivity($$$ActivityCatch,$$$SubActivityMain)
		
		Set tSC=..Activities.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
		
		$$$LeaveActivity($$$ActivityCatch,$$$SubActivityMain)
		
		#; Generate the Gotos ( if any )
		Set tSC=pCompiler.CurrentThread.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
		
		#; Scope ends
		Do pCompiler.CurrentThread.PopLabelScope()
				
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

		Do pStream.Write("<catch ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("fault="_$$$EA(..Fault))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'=""||(..Activities.Count()) {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do ..GenerateAnnotation(pStream)
			}
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			
			Do pStream.WriteLine("</catch>")
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
	Quit "Catch"
}

}
