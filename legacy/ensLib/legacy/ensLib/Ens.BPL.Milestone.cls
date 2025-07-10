/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This provides the ability to generate a milestone and record an expression during
/// execution of a generated business process
Class Ens.BPL.Milestone Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<milestone value='"This is a message"'/>
}

/// This holds the value to assign to the property
Property Value As %String(MAXLEN = "");

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		/// Default override to Python if specified for Process.Language
		Set tLanguageOverride=$$$shapeOtherwiseProcessLanguage(..LanguageOverride,pCompiler.Language)
		
		$$$EnterActivity($$$ActivityMilestone,$$$SubActivityMain)

		if tLanguageOverride=$$$python {
			// For Python expression, generates new Method on Thread that implements the expression
			// Set tValue to invocation signature "..SomeMethod(..., ...)
			set tValue=pCompiler.GeneratePyExec(..Value,"BPLShape:Assign:")
		} else {
			set tValue=..Value
		}
		
		Set tClassName=pCompiler.Process.Package,tMethodName=pCompiler.CurrentMethod.Name
		If tLanguage=$$$objectscript {
			$$$GC(" If ..%Context.%Id()="""" Set status=..%Context.%Save() If $$$ISERR(status) Quit")
			$$$GC(" Set ^Ens.BPL.Milestone(..%Process.%SessionId,..%Context.%Id())=$LB($$$timeUTC,"_tValue_")")
		} else {
			$$$GC("   If Me.%Context.%Id()="""" Then status=Me.%Context.%Save() : If System.Status.IsError(status) Then Exit Do")
			$$$GC("   ^Ens.BPL.Milestone(Me.%Process.%SessionId,Me.%Context.%Id())=ListBuild(date & "" "" & time,"_tValue_")")
		}
		
		$$$LeaveActivity($$$ActivityMilestone,$$$SubActivityMain)
		
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
		
		Do pStream.Write("<milestone ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		Do:..LanguageOverride'="" pStream.Write("languageOverride="_$$$EA(..LanguageOverride))
		
		Do pStream.Write("value="_$$$EA(..Value))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</milestone>")
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
	Quit "Milestone"
}

}
