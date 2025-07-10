/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a branch activity. When this activity is performed, control is transferred to the named
/// label activity if and only if the supplied condition is true.
/// Only labels within scope may be branched to. For example you cannot transfer control out of
/// a 'Flow' or 'Scope' activity
Class Ens.BPL.Branch Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<Branch condition="context.Jump=1" label="labelname"/>
}

/// This holds the condition to be evaluated
Property Condition As %String [ Required ];

/// This holds the label to transfer control to if the condition is true
Property Label As %String [ Required ];

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
		
		#; Entered the branch activity
		$$$EnterActivity($$$ActivityBranch,$$$SubActivityMain)
		
		#; Get state for branch
		Set tBranchState=pCompiler.CurrentStateCounter.Next()
		
		#; Get State for continuation
		Set tContinueState=pCompiler.CurrentStateCounter.Next()
		
		#; Entered the condition test
		$$$EnterActivity($$$ActivityBranch,$$$SubActivityCondition)
		
		if tLanguageOverride=$$$python {
			// For Python expression, generates new Method on Thread that implements the expression
			// Set tValue to invocation signature "..SomeMethod(..., ...)
			set ..Condition=pCompiler.GeneratePyExec(..Condition,"BPLShape:Branch:",tLanguage)
		} else {
			#; This value supports the VDOC syntax
			Set ..Condition=##class(Ens.VDoc.Utils).GetGetCode(..Condition,tLanguage)
		}
		
		If tLanguage=$$$objectscript {
			
			$$$GC(" If ("_..Condition_") {")
			$$$GC("  Set ..%NextState="""_tBranchState_"""")
			$$$GC(" } else {")
			$$$GC("  Set ..%NextState="""_tContinueState_"""")
			$$$GC(" }")
		} else {
			$$$GC("   If ("_..Condition_") Then")
			$$$GC("      Me.%NextState="""_tBranchState_"""")
			$$$GC("   Else")
			$$$GC("      Me.%NextState="""_tContinueState_"""")
			$$$GC("   End If")
		} 
		
		#; Branches have to be generated later when they can be resolved with their labels
		Do pCompiler.CurrentThread.AddBranch(..Label,$ListBuild(tBranchState,..ActivityID))
		
		#; Left the condition test
		$$$LeaveActivity($$$ActivityBranch,$$$SubActivityCondition)
		
		#; left the branch
		$$$LeaveActivity($$$ActivityBranch,$$$SubActivityMain)
		
		#; Start the continue
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tContinueState,pCompiler.CurrentThread)
		
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
		Do pStream.Write("<branch ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("condition="_$$$EA(..Condition))
		
		Do pStream.Write("label="_$$$EA(..Label))
		
		Do:..LanguageOverride'="" pStream.Write("languageOverride="_$$$EA(..LanguageOverride))
				
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</branch>")
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
		#; Must have Label
		If ..Label="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"'label'",..DisplayName()))
		}
		
		#; Must have Condition
		If ..Condition="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"'condition'",..DisplayName()))
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
	Quit "Branch"
}

}
