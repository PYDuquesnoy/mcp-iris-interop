/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Flow represents multiple threads of control. For each top-level activity
/// in a flow statement, the compiler generates a thread class containing the 
/// sub-activities defined therein. The threads execute concurrently (logically)
/// within a business process
Class Ens.BPL.Flow Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<process request="Demo.BPL.Request" response="Demo.BPL.Response">
 <context>
 	<property name="T1" type="%Integer"/>
 	<property name="T2" type="%Integer"/>
 </context>
<sequence>
<flow>
<sequence>
<assign property="context.T1" value="request.P1"/>
</sequence>
<sequence>
<assign property="context.T2" value="request.P2"/>
</sequence>
</flow>
<assign property="request.Result" value="context.T1+context.T2"/>
</sequence>
</process>
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
		
		#; A flow has its own label scope
		Do pCompiler.CurrentThread.PushLabelScope()
		
		$$$EnterActivity($$$ActivityFlow,$$$SubActivityMain)
		
		If ..Activities.Count() {
		
			For tI=1:1:..Activities.Count() {
						
				#; Create a thread for the activity
				Set tSC=pCompiler.StartThread(.tThreadName)
				If $$$ISERR(tSC) Quit
				
				#; Record the thread name
				Set tThreads(tThreadName)=""
				
				Set tSC=..Activities.GetAt(tI).GenerateCode(pCompiler)
				If $$$ISERR(tSC) Quit
		
				Set tSC=pCompiler.EndThread()
				If $$$ISERR(tSC) Quit
			}
			
			#; Now Generate the calls to start the threads
			Set tThreadName=$Order(tThreads(""))
			While tThreadName'="" {
				If tLanguage=$$$objectscript {
					$$$GC(" Set status=..StartThread("""_tThreadName_""")")
					$$$GC(" If $$$ISERR(status) Quit")
				} else {
					$$$GC("   status=Me.StartThread("""_tThreadName_""")")
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
				}
				Set tThreadName=$Order(tThreads(tThreadName))
			}
			
			#; Get the next state for the current thread
			Set tNextState=pCompiler.CurrentStateCounter.Next()
			
			If tLanguage=$$$objectscript {
				$$$GC(" Set ..%NextState="""_tNextState_"""")
			} else {
				$$$GC("   Me.%NextState="""_tNextState_"""")
			}
			
			Set tSC=pCompiler.EndMethod()
			If $$$ISERR(tSC) Quit
				
			Set tSC=pCompiler.StartMethod(tNextState,pCompiler.CurrentThread) If $$$ISERR(tSC) Quit	
		}
		
		$$$LeaveActivity($$$ActivityFlow,$$$SubActivityMain)
		
		#; Generate the code for the current label scope
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

		Do pStream.Write("<flow ")
		
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
		
			Do pStream.WriteLine("</flow>")
			
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
	Quit "Flow"
}

}
