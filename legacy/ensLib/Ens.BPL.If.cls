/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents the If Activity. A supplied condition expression is evaluated. If the condition evaluates to true
/// the sequence of activities defined within the True activity list are executed. If the conditions evaluates to false then
/// the sequence of activities defined within the False activity list are exectued. At least one of the True or False activity
/// lists MUST be none empty.
Class Ens.BPL.If Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<if condition="1">
 <true>
 	<trace value="condition evaluates to true"/>
 </true>
 <false>
 	<trace value="condition evaluates to false"/>
 </false>
</if>
}

/// This holds the selection condition
Property Condition As %String;

/// This holds the activities to be performed if the condition
/// evaluates to true
Property True As Ens.BPL.ActivityList;

/// This holds the activities to be performed if the condition
/// evaluates to be false
Property False As Ens.BPL.ActivityList;

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
		
		Set tPostIfState=pCompiler.CurrentStateCounter.Next()
		
		$$$EnterActivity($$$ActivityIf,$$$SubActivityMain)

		if (tLanguageOverride=$$$python) {
			set ..Condition=pCompiler.GeneratePyExec(..Condition,"BPLShape:If:",tLanguage)
		} else {
    	    #; This value supports the VDOC syntax
			Set ..Condition=##class(Ens.VDoc.Utils).GetGetCode(..Condition,tLanguage)
		}
		
		#; <true> only
		If (..True.Count()>0 && (..False.Count() = 0))
		{
			Set tBlockState=pCompiler.CurrentStateCounter.Next()
			
			If tLanguage=$$$objectscript {
				$$$GC(" If ("_..Condition_") {")
				$$$GC(" Set ..%NextState="""_tBlockState_"""")
				$$$GC(" } else {")
				$$$GC(" Set ..%NextState="""_tPostIfState_"""")
				$$$GC(" }")
				
			} else {
					
				$$$GC("   If ("_..Condition_") Then")
				$$$GC("      Me.%NextState="""_tBlockState_"""")
				$$$GC("   Else")
				$$$GC("      Me.%NextState="""_tPostIfState_"""")
				$$$GC("   End If")
			}
			Do pCompiler.StartMethod(tBlockState,pCompiler.CurrentThread)
			
			$$$EnterActivity($$$ActivityIf,$$$SubActivityTrueBranch)
			
			Set tSC=..True.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			
			If tLanguage=$$$objectscript {
				$$$GC(" Set ..%NextState="""_tPostIfState_"""")
			} else {
				$$$GC("   Me.%NextState="""_tPostIfState_"""")
			}
			$$$LeaveActivity($$$ActivityIf,$$$SubActivityTrueBranch)
			
			Do pCompiler.EndMethod()
		} 
		#; <false> only
		elseif (..False.Count()>0 && (..True.Count() = 0))
		{	
			Set tBlockState=pCompiler.CurrentStateCounter.Next()
			
			If tLanguage=$$$objectscript {
				$$$GC(" If '("_..Condition_") {")
				$$$GC(" Set ..%NextState="""_tBlockState_"""")
				$$$GC(" } else {")
				$$$GC(" Set ..%NextState="""_tPostIfState_"""")
				$$$GC(" }")
			} else {
				$$$GC("   If Not ("_..Condition_") Then")
				$$$GC("      Me.%NextState="""_tBlockState_"""")
				$$$GC("   Else")
				$$$GC("      Me.%NextState="""_tPostIfState_"""")
				$$$GC("   End If")
			}
			Do pCompiler.StartMethod(tBlockState,pCompiler.CurrentThread)
			
			$$$EnterActivity($$$ActivityIf,$$$SubActivityFalseBranch)
			
			Set tSC=..False.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			
			If tLanguage=$$$objectscript {
				$$$GC(" Set ..%NextState="""_tPostIfState_"""")
			} else {
				$$$GC("   Me.%NextState="""_tPostIfState_"""")
			}
			$$$LeaveActivity($$$ActivityIf,$$$SubActivityFalseBranch)
			
			Do pCompiler.EndMethod()
		} else 
		#; <true> and <false>
		{
			Set tTrueState=pCompiler.CurrentStateCounter.Next()
			
			If tLanguage=$$$objectscript {
				$$$GC(" If ("_..Condition_") {")
				$$$GC(" Set ..%NextState="""_tTrueState_"""")
			} else {
				$$$GC("   If ("_..Condition_") Then")
				$$$GC("      Me.%NextState="""_tTrueState_"""")
			}
			Do pCompiler.StartMethod(tTrueState,pCompiler.CurrentThread)
			
			$$$EnterActivity($$$ActivityIf,$$$SubActivityTrueBranch)
		
			Set tSC=..True.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			
			If tLanguage=$$$objectscript {
				$$$GC(" Set ..%NextState="""_tPostIfState_"""")
			} else {
				$$$GC("   Me.%NextState="""_tPostIfState_"""")
			}
			$$$LeaveActivity($$$ActivityIf,$$$SubActivityTrueBranch)
			
			Do pCompiler.EndMethod()
		
			Set tFalseState=pCompiler.CurrentStateCounter.Next()
				
			If tLanguage=$$$objectscript {
				$$$GC(" } else {")
				$$$GC(" Set ..%NextState="""_tFalseState_"""")
			} else {
				$$$GC("   Else")
				$$$GC("      Me.%NextState="""_tFalseState_"""")
			}
			Do pCompiler.StartMethod(tFalseState,pCompiler.CurrentThread)
			
			$$$EnterActivity($$$ActivityIf,$$$SubActivityFalseBranch)
			
			Set tSC=..False.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			
			If tLanguage=$$$objectscript {
				$$$GC(" Set ..%NextState="""_tPostIfState_"""")
			} else {
				$$$GC("   Me.%NextState="""_tPostIfState_"""")
			}
			$$$LeaveActivity($$$ActivityIf,$$$SubActivityFalseBranch)
			
			Do pCompiler.EndMethod()
			
			If tLanguage=$$$objectscript {
				$$$GC(" }")
			} else {
				$$$GC("   End If")
			}
		} 

		Do pCompiler.EndMethod(),pCompiler.StartMethod(tPostIfState,pCompiler.CurrentThread)
		
		$$$LeaveActivity($$$ActivityIf,$$$SubActivityMain)
		
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
		Do pStream.Write("<if ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		#; Generate the condition
		Do pStream.Write("condition="_$$$EA(..Condition))
		Do:""'=..LanguageOverride pStream.Write("languageOverride="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..LanguageOverride)_""" ")
		
		#; Generate the common attributes
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.WriteLine(">")
		
		If ..Annotation'="" {
			Do ..GenerateAnnotation(pStream)
		}
		
		#; The Schema ensures that there is at most one <true> or <false> element
		#; and requires that at least one <true> or <false> element be present
		If ((..True.Count()=0)&&(..False.Count()=0)) {
			#; JMD268--if no true/false, add an empty true
			Do pStream.WriteLine("<true/>")
		}
		If ..True.Count() {
			
			#; Generate the optional <true> activity list
			Do pStream.WriteLine("<true>")
			Set tSC=..True.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			Do pStream.WriteLine("</true>")
		}
		
		If ..False.Count() {
			
			#; Generate the optional <false> activity list
			Do pStream.WriteLine("<false>")
			Set tSC=..False.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			Do pStream.WriteLine("</false>")
		}
		
		Do pStream.WriteLine("</if>")
		
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
		
		#; Both true and false should be validated
		Set tSC=..True.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
		
		Set tSC=..False.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set ..True=##class(Ens.BPL.ActivityList).%New()
		$$$ASSERT($IsObject(..True))
		
		Set ..False=##class(Ens.BPL.ActivityList).%New()
		$$$ASSERT($IsObject(..False))
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
	Quit "If"
}

}
