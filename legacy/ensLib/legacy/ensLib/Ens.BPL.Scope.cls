/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a sequence of activities to be performed. Errors occuring with the scope block are caught
/// and redirected to the a fault handler. The fault handler can, if desired, invoke a compensation handler which is a named
/// block of code which is intended to compensate for the fault. Transfer of control flow to a catch block can also be achieved
/// by using the Throw activity,naming the catch block to be invoked.
Class Ens.BPL.Scope Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the Try Activity List
Property Activities As Ens.BPL.ActivityList;

/// This holds the Catch List
Property FaultHandlers As Ens.BPL.CatchList;

/// This holds the CompensationHandlers
Property CompensationHandlers As Ens.BPL.CompensationHandlerList;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		#; Get a state for the scope block. We only want to protect statements
		#; within the current scope
		Set tScopeState=pCompiler.CurrentStateCounter.Next()
		
		If tLanguage=$$$objectscript {
			$$$GC(" #; Establish a state for the Scope beginning")
			$$$GC(" Set ..%NextState="""_tScopeState_"""")
		} else {
			$$$GC("   ' Establish a state for the Scope beginning")
			$$$GC("   Me.%NextState="""_tScopeState_"""")
		}
		
		#; Get state for the Fault handler for this block
		Set tFaultState=pCompiler.CurrentStateCounter.Next()
		
		#; Push the fault state onto the threads CatchStack
		Do pCompiler.CurrentThread.CatchStack.Push(tFaultState)
		
		#; End this method
		Do pCompiler.EndMethod()
		
		#; If there are any Compensation handlers we need to generate them here
		If ..CompensationHandlers.Count() {
			
			Set tSC=..CompensationHandlers.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
		}
		
		#;  start new method for the scope block
		Do pCompiler.StartMethod(tScopeState,pCompiler.CurrentThread)
		
		$$$EnterActivity($$$ActivityScope,$$$SubActivityMain)
	
		If tLanguage=$$$objectscript {
			
			$$$GC(" #; Establish fault handler")
			$$$GC(" $$$Push("""_tFaultState_""",..%HandlerStack)")
		} else {
			
			$$$GC(" ' Establish fault handler")
			$$$GC(" Me.%HandlerStack=Me.%HandlerStack & ListBuild("""_tFaultState_""")")
		}
		
		#; A scope has its own label scope, i.e we cannot allow gotos to exit the scope
		Do pCompiler.CurrentThread.PushLabelScope()
		
		#; Generate the scope activities
		Set tSC=..Activities.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
		
		#; Generate the Gotos ( if any)
		Set tSC=pCompiler.CurrentThread.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
		
		#; Scope ends
		Do pCompiler.CurrentThread.PopLabelScope()
		
		#; Get a state for the post scope state. This is where a catch will branch back to
		Set tScopeEndState=pCompiler.CurrentStateCounter.Next()
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tScopeEndState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tScopeEndState_"""")
		}
		
		$$$LeaveActivity($$$ActivityScope,$$$SubActivityMain)
		
		#; Scope is ended, pop the fault handler
		If tLanguage=$$$objectscript {
			
			$$$GC(" #; Remove this scopes fault handler")
			$$$GC(" $$$Pop(..%HandlerStack)")
		} else {
			
			$$$GC("' Remove this scopes fault handler")
			$$$GC(" Me.%HandlerStack=List(Me.%HandlerStack,1,ListLength(Me.%HandlerStack)-1)")
		}
		
		#; End this method, generate the catchblock
		Do pCompiler.EndMethod()
		
		Do pCompiler.StartMethod(tFaultState,pCompiler.CurrentThread)
		
		#; Generate the catch activities
		Set tSC=..FaultHandlers.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		#; Generate the branch to the end state
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tScopeEndState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tScopeEndState_"""")
		}
		
		#; End this method, set up for the EndState
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tScopeEndState,pCompiler.CurrentThread)
		
		#; Pop the CatchStack
		Do pCompiler.CurrentThread.CatchStack.Pop()
		
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

		Do pStream.Write("<scope ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'=""||(..Activities.Count())||(..CompensationHandlers.Count())||(..FaultHandlers.Count()) {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do ..GenerateAnnotation(pStream)
			}
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
				
			#; If there are any Compensation handlers we need to generate them here
			If ..CompensationHandlers.Count() {
			
				Do pStream.WriteLine("<compensationhandlers>")
				
				Set tSC=..CompensationHandlers.GenerateXML(pStream)
				If $$$ISERR(tSC) Quit
				
				Do pStream.WriteLine("</compensationhandlers>")
			}
			
			Do pStream.WriteLine("<faulthandlers>")
				
			Set tSC=..FaultHandlers.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
				
			Do pStream.WriteLine("</faulthandlers>")
			
			Do pStream.WriteLine("</scope>")
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
		If $$$ISERR(tSC) Quit
		
		#; and the fault handlers
		Set tSC=..FaultHandlers.Validate(.pStatus,pContext)
		
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
		
		Set ..CompensationHandlers=##class(Ens.BPL.CompensationHandlerList).%New()
		$$$ASSERT($IsObject(..CompensationHandlers))
		
		Set ..FaultHandlers=##class(Ens.BPL.CatchList).%New()
		$$$ASSERT($IsObject(..FaultHandlers))
		
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
	Quit "Scope"
}

}
