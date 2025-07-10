/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This provides the ability to execute a series of activities until
/// the specified condition becomes true
Class Ens.BPL.Until Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<until condition="time&gt;stoptime">
<assign property="loops" value="loops+1"/>
</until>
}

/// This holds the condition which controls the loop
Property Condition As %String;

///  This holds the Activity list which represents the loop body
Property Activities As Ens.BPL.ActivityList;

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
		
		Set tTestState=pCompiler.CurrentStateCounter.Next()
		Set tPostState=pCompiler.CurrentStateCounter.Next()
		Set tBodyState=pCompiler.CurrentStateCounter.Next()
		
		Do pCompiler.ContinueStack.Push(tTestState)
		Do pCompiler.BreakStack.Push(tPostState)
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tBodyState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tBodyState_"""")
		}
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tBodyState,pCompiler.CurrentThread)
		
		// Entered the until
		$$$EnterActivity($$$ActivityUntil,$$$SubActivityMain)
		
		// Entered the body
		$$$EnterActivity($$$ActivityUntil,$$$SubActivityBody)
		
		Set tSC=..Activities.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tTestState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tTestState_"""")
		}
		
		$$$LeaveActivity($$$ActivityUntil,$$$SubActivityBody)
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tTestState,pCompiler.CurrentThread)
		
		$$$EnterActivity($$$ActivityUntil,$$$SubActivityCondition)

		if (tLanguageOverride=$$$python) {
			set ..Condition=pCompiler.GeneratePyExec(..Condition,"BPLShape:Until:",tLanguage)
		} else {
        	#; This value supports the VDOC syntax
			Set ..Condition=##class(Ens.VDoc.Utils).GetGetCode(..Condition,pCompiler.Language)
		}
		
		If tLanguage=$$$objectscript {
			$$$GC(" If ("_..Condition_") {")
			$$$GC("  Set ..%NextState="""_tPostState_"""")
			$$$GC(" } else {")
			$$$GC("  Set ..%NextState="""_tBodyState_"""")
			$$$GC(" }")
		} else {
			$$$GC("   If ("_..Condition_") Then")
			$$$GC("      Me.%NextState="""_tPostState_"""")
			$$$GC("   Else")
			$$$GC("      Me.%NextState="""_tBodyState_"""")
			$$$GC("   End If")
		}
		
		$$$LeaveActivity($$$ActivityUntil,$$$SubActivityCondition)
		
		Do pCompiler.ContinueStack.Pop(),pCompiler.BreakStack.Pop(),pCompiler.EndMethod()
		Do pCompiler.StartMethod(tPostState,pCompiler.CurrentThread)
		
		$$$LeaveActivity($$$ActivityUntil,$$$SubActivityMain)
		
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
		Do pStream.Write("<until ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))

		Do:..LanguageOverride'="" pStream.Write("languageOverride="_$$$EA(..LanguageOverride))
		
		Do pStream.Write("condition="_$$$EA(..Condition))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
			
		If ..Annotation'=""||(..Activities.Count()) {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do pStream.Write("<annotation>")
				Do pStream.Write($ZCVT(..Annotation,"O","HTML"))
				Do pStream.WriteLine("</annotation>")
			}
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			
			Do pStream.WriteLine("</until>")
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
		#; Must know the condition we want to test
		If ..Condition="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"condition",..DisplayName()))
		}
		
		#; Delegate to the activities
		Set tSC=..Activities.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
		
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
	Quit "Until"
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

}
