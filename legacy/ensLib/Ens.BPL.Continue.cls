/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a Continue activity, used to Continue out of a bpl loop construct
/// such as the ForEach, Until or While activities
Class Ens.BPL.Continue Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<Continue>
 <annotation>This serves as a good place for documentation</annotation>
</Continue>
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		If pCompiler.ContinueStack.Empty()=1
		{
			Set tSC=$$$ERROR($$$EnsErrBPLInvalidLoopContext,..activityName())
		} else {
			
			$$$EnterActivity($$$ActivityContinue,$$$SubActivityMain)
			
			If tLanguage=$$$objectscript {
				$$$GC(" Set ..%NextState="""_pCompiler.ContinueStack.Top()_"""")
			} else {
				$$$GC("   Me.%NextState="""_pCompiler.ContinueStack.Top()_"""")
			} 
			
			$$$LeaveActivity($$$ActivityContinue,$$$SubActivityMain)
			
			If tLanguage=$$$objectscript {
				$$$GC(" Quit")
			} else {
				$$$GC("   Exit Do")
			} 
		}
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
		Do pStream.Write("<continue ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</continue>")
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

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	Quit "Continue"
}

}
