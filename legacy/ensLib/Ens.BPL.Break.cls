/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a break activity, used to break out of a bpl loop construct
/// such as the ForEach, Until or While activities
Class Ens.BPL.Break Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<break>
 <annotation>This serves as a good place for documentation</annotation>
</break>
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emmiting object when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		If pCompiler.BreakStack.Empty()=1
		{
			Set tSC=$$$ERROR($$$EnsErrBPLInvalidLoopContext,..activityName())
		} else {
			
			$$$EnterActivity($$$ActivityBreak,$$$SubActivityMain)
			
			If tLanguage=$$$objectscript {
				$$$GC(" Set ..%NextState="""_pCompiler.BreakStack.Top()_"""")
			} else {
				$$$GC("   Me.%NextState="""_pCompiler.BreakStack.Top()_"""")
			}
			
			$$$LeaveActivity($$$ActivityBreak,$$$SubActivityMain)
			
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
		Do pStream.Write("<break ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</break>")
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
	Quit "Break"
}

}
