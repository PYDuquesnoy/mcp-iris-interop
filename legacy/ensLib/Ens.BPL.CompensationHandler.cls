/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a sequence of activities to be performed to compensate for work previously performed
/// in BPL. The compensation handler may only be invoked via a <compensate> activity within a <catch> or <catchall>.
Class Ens.BPL.CompensationHandler Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<scope>
  <throw fault='"BuyersRegret"'/>
  <faulthandlers>
    <catch fault='"BuyersRegret"'>
      <compensate target="RestoreBalance"/>
    </catch>
  </faulthandlers>
  <compensationhandlers>
    <compensationhandler name="RestoreBalance">
      <assign property='context.MyBalance' value='context.MyBalance+1'/>
    </compensationhandler>
  </compensationhandlers>
</scope>
}

/// This holds the Activity List
Property Activities As Ens.BPL.ActivityList;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		#; If it isn't named then it can't be called so no point generating any code
		If ..Name="" Quit
	
		#; Get a state for the start of this Compensation handler
		Set tThisState=pCompiler.CurrentStateCounter.Next()
		
		#; Record the start state for the compensation handler
		Set pCompiler.CompensationHandlers(..Name)=tThisState
				
		Do pCompiler.StartMethod(tThisState,pCompiler.CurrentThread)
		
		#; A compensation handler has its own scope
		Do pCompiler.CurrentThread.PushLabelScope()
		
		$$$EnterActivity($$$ActivityCompensationHandler,$$$SubActivityMain)
	
		#; Generate compensation activities
		Set tSC=..Activities.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
		
		$$$LeaveActivity($$$ActivityCompensationHandler,$$$SubActivityMain)
		
		#; Generate 'Gotos' (if any)
		Set tSC=pCompiler.CurrentThread.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
		
		#; Scope ends
		Do pCompiler.CurrentThread.PopLabelScope()
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set status=..Return()")
		} else {
			$$$GC("   status=Me.Return()")
		}
		
		Do pCompiler.EndMethod()
		
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

		Do pStream.Write("<compensationhandler ")
		
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
			
			Do pStream.WriteLine("</compensationhandler>")
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
	Quit "CompensationHandler"
}

}
