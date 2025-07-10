/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This provides the ability to generate a trace message during
/// execution of a generated business process. The value supports the VDOC syntax
Class Ens.BPL.Alert Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<alert value="This is a message"/>
}

/// This holds the value to assign to the property
Property Value As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		#; Dont generate code if disabled
		If ..Disabled Quit
		/// Default to emitting object when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		/// Default override to Python if specified for Process.Language
		Set tLanguageOverride=$$$shapeOtherwiseProcessLanguage(..LanguageOverride,pCompiler.Language)
		
		$$$EnterActivity($$$ActivityAlert,$$$SubActivityMain)
		
		If $$$python=tLanguageOverride {
			// For Python expression, generates new Method on Thread that implements the expression
			// Set tValue to invocation signature "..SomeMethod(..., ...)
			set ..Value=pCompiler.GeneratePyExec(..Value,"BPLShape:Alert:",tLanguage)
		} else {
	    	#; This value supports the VDoc syntax
			Set ..Value=##class(Ens.VDoc.Utils).GetGetCode(..Value,tLanguage)
		}
		
		Set tClassName=pCompiler.Process.Package,tMethodName=pCompiler.CurrentMethod.Name
		If tLanguage=$$$objectscript {
			$$$GC(" Set status=..%Process.SendAlert(##class(Ens.AlertRequest).%New($lb(..%Process.%ConfigName,"_..Value_")))")
			$$$GC(" If $$$ISERR(status) Quit")
		} else {
			$$$GC("   status=Me.%Process.SendAlert(new Ens.AlertRequest(ListBuild(Me.%Process.%ConfigName,"_..Value_")))")
			$$$GC("   If System.Status.IsError(status) Then Exit Do")
		}
		
		$$$LeaveActivity($$$ActivityAlert,$$$SubActivityMain)
		
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
		
		Do pStream.Write("<alert ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		Do:..LanguageOverride'="" pStream.Write("languageOverride="_$$$EA(..LanguageOverride))
		
		Do pStream.Write("value="_$$$EA(..Value))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</alert>")
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
		#; Must know the value we want to alert
		If ..Value="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"value",..DisplayName()))
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
	Quit "Alert"
}

}
