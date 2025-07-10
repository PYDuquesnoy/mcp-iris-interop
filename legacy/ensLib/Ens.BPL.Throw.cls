/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// When a <throw> statement executes, control immediately shifts to the <faulthandlers> block inside the same <scope>,
/// skipping all intervening statements after the <throw>. Inside the <faulthandlers> block, the program attempts 
/// to find a <catch> block whose value attribute matches the fault string expression in the <throw> statement.
/// This comparison is case-sensitive
Class Ens.BPL.Throw Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<throw fault='"OOPS!"'/>
}

/// This holds the string that will identify the fault
Property Fault As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		$$$EnterActivity($$$ActivityThrow,$$$SubActivityMain)
		
		Set tClassName=pCompiler.Process.Package,tMethodName=pCompiler.CurrentMethod.Name
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%Context.%LastFault="_..Fault)
			$$$GC(" Set status=$$$ERROR($$$EnsErrBPLThrownFault,"_..Fault_") ZT ""THRO""")
		} else {
			$$$GC(" Me.%Context.%LastFault="_..Fault)
			$$$GC(" status="_..Fault_" : Err.Raise(-1)")
		}
		
		$$$LeaveActivity($$$ActivityThrow,$$$SubActivityMain)
		
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
		
		Do pStream.Write("<throw ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("fault="_$$$EA(..Fault))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</throw>")
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
		#; Must know the string we want to throw
		If ..Fault="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"fault",..DisplayName()))
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
	Quit "Throw"
}

}
