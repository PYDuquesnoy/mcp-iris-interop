/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a label, the target of a goto activity
Class Ens.BPL.Label Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<label name="checkpoint"/>
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)

		Set tNextState=pCompiler.CurrentStateCounter.Next()
	
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tNextState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tNextState_"""")
		}
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tNextState,pCompiler.CurrentThread)
		
		$$$EnterActivity($$$ActivityLabel,$$$SubActivityMain)
		
		#; Nothing actually happens in a label
		Do pCompiler.CurrentThread.AddLabel(..Name,tNextState)
					
		Set tNextState=pCompiler.CurrentStateCounter.Next()
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tNextState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tNextState_"""")
		}
		
		$$$LeaveActivity($$$ActivityLabel,$$$SubActivityMain)
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tNextState,pCompiler.CurrentThread)
		
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
		Do pStream.Write("<label ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</label>")
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
		#; Must have Name
		If (..Name="") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"'name'",..DisplayName()))
		}
		
		If $Data(pContext.Labels(..Name)) {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLLabelNameNotUnique,..Name))
		} else {
			Set pContext.Labels(..Name)=""
		}
		
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
	Quit "Label"
}

}
