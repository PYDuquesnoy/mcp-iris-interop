/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a BPL receive event.
/// A receive event waits for a new request to be sent to a 
/// Business Process.
Class Ens.BPL.Receive Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<receive name="ApproveLoan" request="MyApp.MyRequest" timeout="10">
</receive>
}

/// This holds the class name of the expected request object.
Property Request As %String;

/// This holds the timeout
Property Timeout As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())

	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		Set tClassName = pCompiler.Process.Package

		If tLanguage=$$$objectscript {
			$$$GC(" // Receive is UNIMPLEMENTED!!!")
		}
		Else {
			// basic
			$$$GC(" ' Receive is UNIMPLEMENTED!!!")
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
		Do pStream.Write("<receive ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("request="_$$$EA(..Request))
		If (..Timeout '= "") {
			Do pStream.Write("timeout="_$$$EA(..Timeout))
		}

		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.WriteLine(">")
		
		If ..Annotation'="" {
			Do ..GenerateAnnotation(pStream)
		}
		
		Do pStream.WriteLine("</receive>")

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
		#; Must have a request type
		If ..Request="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"request",..DisplayName()))
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
	Quit "Receive"
}

}
