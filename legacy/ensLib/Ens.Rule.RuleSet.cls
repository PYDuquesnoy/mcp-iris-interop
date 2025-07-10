/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an Ensemble Business Rule set.
/// This is a specific type of Rule definition.
Class Ens.Rule.RuleSet Extends RuleDefinition [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Parameter RULEEDITORURL = "UtilEnsRuleEditor.csp";

/// Indicates if this Rule Engine supports compilation.
Parameter COMPILABLE = 1;

Parameter XMLNAME = "ruleSet";

/// Set of Rules that define this Rule Set.
Relationship Rules As Rule(XMLNAME = "rule", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = RuleSet ];

/// Default value returned by this Rule Set.
Property DefaultValue As %String(MAXLEN = 128, XMLNAME = "default", XMLPROJECTION = "ATTRIBUTE");

/// Evaluate this Rule Set.
/// The resulting return value is returned via the %ReturnValue property.
Method Evaluate(pContext As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Set tEval = 0
	Set tErrorMsg = ""
	
	For r = 1:1:..Rules.Count() { Set tRule = ..Rules.GetAt(r)  Continue:tRule.Disabled
		Set tSC = tRule.Evaluate($this,r,pContext,.tEval,.tErrorMsg)
		
		// error: return default
		If $$$ISERR(tSC) {
			Set tEval = 0
			Quit
		}
		// user error: return default
		If (tErrorMsg '= "") {
			Set ..%ErrorMsg = tErrorMsg
			Set tEval = 0
			Quit
		}
		If (tEval) {
			// true means we're done
			Quit
		}
	}
	If (tEval = 0) {
		// return default value
		Set ..%Reason = "Default"
		Set ..%ReturnValue = ##class(ExpressionParser).Evaluate(..DefaultValue,pContext,.tErrorMsg)

		// user error: return default
		If (tErrorMsg '= "") {
			Set ..%ReturnValue = ""
			Set ..%ErrorMsg = tErrorMsg
		}
	}
Done	
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Set ..%ReturnValue = ""
	Set ..%ErrorMsg = $ZE
	Quit tSC
}

/// Generate executable code for this Rule
Method GenerateCode(pCompiler As Compiler) As %Status
{
#ifndef Indent
	#define Indent(%x) %x_"  "
	#define Outdent(%x) $E(%x,1,*-3)_" "
#endif

	Set tSC = $$$OK
	Set tNeedClose = 0
	Set tPad = " "
	Do pCompiler.Code.WriteLine(" ")
	
	Do {
		// loop over rules, generate code
		Set tFirst=1
		For r = 1:1:..Rules.Count() {
			Set %objlasterror = ""
			Set tRule = ..Rules.GetAt(r)
			If '$IsObject(tRule) Set tSC = %objlasterror Quit
			Continue:tRule.Disabled
			Set tRuleNo = r
			If tFirst Set tRuleNo = "0"_tRuleNo, tFirst = 0
			Set tSC = tRule.GenerateCode(pCompiler, tRuleNo)
			Quit:'tSC
		}
		
		// default case
		If 'tFirst {
			Do pCompiler.Code.WriteLine(tPad_"Else {")
			Set tNeedClose = 1
			Set tPad = $$$Indent(tPad)
		}
		Set tErrorMsg = ""
		If (..DefaultValue = "") {
			Set tCode = """"""
		} Else {
			// Now get code for default value expression
			Set tSC = ##class(Ens.Rule.ExpressionParser).GenerateCode(..DefaultValue, .tCode, .tErrorMsg)
			Quit:$$$ISERR(tSC)
		}
		Do pCompiler.Code.WriteLine(tPad_"Set pRuleDef.%Reason = ""Default""")

		If (tErrorMsg '= "") {
			Do pCompiler.Code.WriteLine(tPad_"// Invalid default value: " _ ..DefaultValue)
			Do pCompiler.Code.WriteLine(tPad_"Set pRuleDef.%ErrorMsg = """ _ tErrorMsg _ """")
		} Else {
			Do pCompiler.Code.WriteLine(tPad_"Set pRuleDef.%ReturnValue = " _ tCode)
		}
	} While(0)
	
	If (tNeedClose) {
		Do pCompiler.Code.WriteLine(tPad_"}")
		Set tPad = $$$Outdent(tPad)
	}
	
	Do pCompiler.Code.WriteLine(" ")
	Do pCompiler.Code.WriteLine(" Quit $$$OK")
	Do pCompiler.Code.WriteLine(" ")
	Quit tSC
}

Storage Default
{
<Data name="RuleSetDefaultData">
<Subscript>"RuleSet"</Subscript>
<Value name="1">
<Value>DefaultValue</Value>
</Value>
</Data>
<DefaultData>RuleSetDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
