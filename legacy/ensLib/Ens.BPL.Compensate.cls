/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This provides the ability to inovke a named compensation handler. Compensate can only be used in a catch block.
/// Following invocation of the handler, control returns to the next activity following the Compensate activity 
Class Ens.BPL.Compensate Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
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

/// This holds the Target compensation handler to call
Property Target As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
	
		Set tGoSubState=$Get(pCompiler.CompensationHandlers(..Target))
		
		Set tReturnState=pCompiler.CurrentStateCounter.Next()
	
		$$$EnterActivity($$$ActivityCompensate,$$$SubActivityMain)
	
		If tLanguage=$$$objectscript {
			$$$GC(" Do ..GoSub("""_tGoSubState_""","""_tReturnState_""")")
		} else {
			$$$GC(" Me.GoSub("""_tGoSubState_""","""_tReturnState_""")")
		}
		
		$$$LeaveActivity($$$ActivityCompensate,$$$SubActivityMain)
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tReturnState,pCompiler.CurrentThread)
		
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
		
		Do pStream.Write("<compensate ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("target="_$$$EA(..Target))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</compensate>")
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

Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Must know the value we want to trace
		If ..Target="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"target",..DisplayName()))
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
	Quit "Compensate"
}

}
