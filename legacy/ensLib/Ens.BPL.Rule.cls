/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents an invocation of a a Rule.
Class Ens.BPL.Rule Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<rule name="ApproveLoan" rule="LoanApproval" resultLocation="context.Answer" reasonLocation="context.Reason">
</rule>
}

/// This holds the name of the associated Business Rule that will be invoked.
Property Rule As %String;

/// This holds the name of the context property that will contain
/// the return value of the rule.
Property ResultLocation As %String;

/// If provided, this is an expression (e.g., "context.myProperty") that
/// provides the context object passed to the Rules Engine.<br/>
/// If not provided, the Business Process context object is passed to the Rules Engine.
Property RuleContext As %String;

/// This holds the name of the context property that will contain
/// the reason value (i.e., which rule actually fired) returned
/// by the Rule Engine.
Property ReasonLocation As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())

	do {
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)

		If ..Disabled Quit
		
		Set tClassName = pCompiler.Process.Package
		Set tRule=$ZStrip(..Rule,"<>W")
		Set tIsIndirect=$E(tRule)="@"
		Set tRule=$S(tIsIndirect:$E(tRule,2,*),1:""""_tRule_"""")
		Set tRuleContext = "context"  // object passed to rules engine
		Set:(..RuleContext'="") tRuleContext = ..RuleContext

		$$$EnterActivity($$$ActivityRule,$$$SubActivityMain)

		If tLanguage=$$$objectscript {
			If (..RuleContext'="") {
				#; make sure Rules Engine can see process
				$$$GC(" Set " _tRuleContext_ ".%Process = process")
			}

			If tIsIndirect {
				$$$GC(" Set status=##class(Ens.Rule.RuleDefinition).EvaluateRulesEx($S((("_tRule_"[""."")||(##class(Ens.Projection.Rule).ResolveRuleAlias("_tRule_")'="""")):"_tRule_", 1:"""_tClassName_"""_"".""_"_tRule_"),,"_tRuleContext_","""_..Name_""",.ruleReturn,.ruleReason,,process.RuleLogging)  Quit:$$$ISERR(status)")
			} ElseIf tRule["." {
				$$$GC(" Set status=##class(Ens.Rule.RuleDefinition).EvaluateRulesEx("_tRule_",,"_tRuleContext_","""_..Name_""",.ruleReturn,.ruleReason,,process.RuleLogging)  Quit:$$$ISERR(status)")
			} ElseIf (##class(Ens.Projection.Rule).ResolveRuleAlias($P(tRule,$C(34),2))'="") {
				$$$GC(" Set status=##class(Ens.Rule.RuleDefinition).EvaluateRulesEx("""_$E(tRule,2,*)_",,"_tRuleContext_","""_..Name_""",.ruleReturn,.ruleReason,,process.RuleLogging)  Quit:$$$ISERR(status)")
			} Else {
				$$$GC(" Set status=##class(Ens.Rule.RuleDefinition).EvaluateRulesEx("""_tClassName_"."_$E(tRule,2,*)_",,"_tRuleContext_","""_..Name_""",.ruleReturn,.ruleReason,,process.RuleLogging)  Quit:$$$ISERR(status)")
			}
			#; Copy return values into specified locations
			If (..ResultLocation '= "") {
				$$$GC(" Set " _ ..ResultLocation _ " = ruleReturn")
			}
			If (..ReasonLocation '= "") {
				$$$GC(" Set " _ ..ReasonLocation _ " = ruleReason")
			}
		} Else {
			If (..RuleContext'="") {
				#; make sure Rules Engine can see process
				$$$GC(" " _tRuleContext_ ".%Process = process")
			}

			#; Basic
			#; Note that calls below supply 1 for Level rather than create an empty variable for the argument
			If tIsIndirect {
				$$$GC(" status=""Ens.Rule.RuleDefinition"".EvaluateRulesEx(Case(InStr("_tRule_","".""),0:"""_tClassName_""" & ""."" & "_tRule_", :"_tRule_"),"""","_tRuleContext_","""_..Name_""",ruleReturn,ruleReason,1,process.RuleLogging)")
			} ElseIf tRule["." {
				$$$GC(" status=""Ens.Rule.RuleDefinition"".EvaluateRulesEx("_tRule_","""","_tRuleContext_","""_..Name_""",ruleReturn,ruleReason,1,process.RuleLogging)")
			} Else {
				$$$GC(" status=""Ens.Rule.RuleDefinition"".EvaluateRulesEx("""_tClassName_"."_$E(tRule,2,*)_","""","_tRuleContext_","""_..Name_""",ruleReturn,ruleReason,1,process.RuleLogging)")
			}
			$$$GC(" If System.Status.IsError(status) Then Exit Do")
			
			#; Copy return values into specified locations
			If (..ResultLocation '= "") {
				$$$GC(" " _ ..ResultLocation _ " = ruleReturn")
			}
			If (..ReasonLocation '= "") {
				$$$GC(" " _ ..ReasonLocation _ " = ruleReason")
			}
		}
		$$$LeaveActivity($$$ActivityReply,$$$SubActivityMain)
		
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
		Do pStream.Write("<rule ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("rule="_$$$EA(..Rule)_" ")
		If (..ResultLocation '= "") {
			Do pStream.Write("resultLocation="_$$$EA(..ResultLocation))
		}
		
		If (..ReasonLocation '= "") {
			Do pStream.Write("reasonLocation="_$$$EA(..ReasonLocation))
		}
		
		If (..RuleContext '= "") {
			Do pStream.Write("ruleContext="_$$$EA(..RuleContext))
		}

		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.WriteLine(">")
		
		If ..Annotation'="" {
			Do ..GenerateAnnotation(pStream)
		}
		
		Do pStream.WriteLine("</rule>")

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
		#; Must have Rule name
		If ..Rule="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"rule",..DisplayName()))
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
	Quit "Rule"
}

}
