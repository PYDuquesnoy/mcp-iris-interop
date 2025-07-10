/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a Business Rule within a Rule set.
Class Ens.Rule.Rule Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure rules are ordered correctly
Index ID On RuleNo [ IdKey ];

Property RuleNo As %Integer(XMLPROJECTION = "NONE") [ InitialExpression = {$I(^Ens.Rule.RuleC("RuleNo"))} ];

/// Parent RuleSet.
Relationship RuleSet As Ens.Rule.RuleSet [ Cardinality = parent, Inverse = Rules ];

/// If false, then this rule is enabled; otherwise this rule is not evaluated.
Property Disabled As %Boolean(XMLNAME = "disabled", XMLPROJECTION = "ATTRIBUTE");

/// If defined, value returned if this Rule is true.
Property ReturnValue As %String(MAXLEN = 128, XMLNAME = "return", XMLPROJECTION = "ATTRIBUTE");

/// Collection of optional actions associated with this Rule.
Relationship Actions As Action(XMLNAME = "action", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = Rule ];

/// Collection of conditions that define this Rule.
Relationship Conditions As Condition(XMLNAME = "condition", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = Rule ];

/// Collection of SubRules of this Rule.
Property SubRules As list Of SubRule(XMLNAME = "rule", XMLPROJECTION = "ELEMENT");

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being deleted.
/// 
/// <P>If this method returns an error then the object will not be deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ ServerOnly = 1 ]
{
	// Delete all SubRules of this Rule
	Set o = ##class(Rule).%Open(oid)
	If $IsObject(o) {
		For i = 1:1:o.SubRules.Count() {
			Do ##class(SubRule).%DeleteId(o.SubRules.GetAt(i).%Id())
		}
	}
	Quit $$$OK
}

/// Evaluate this Rule.<br>
/// Returns user errors via <var>pErrorMsg</var>.
Method Evaluate(pRuleSet As RuleDefinition, pRuleNo As %Integer, pContext As %RegisteredObject, Output pValue As %Boolean, Output pErrorMsg As %String) As %Status
{
	Set tSC=$$$OK, pValue=1, tVal=1, tVal(1)=1 // default is true for no conditions
	
	If (..Disabled) {
		// rule is turned off; skip it
		Set pValue = 0
		Quit tSC
	}
	For c = 1:1:..Conditions.Count() {
		Set tCond = ..Conditions.GetAt(c)
		
		Set tSC = tCond.Evaluate(pRuleSet,pContext,.tEval,.pErrorMsg)
		If ($$$ISERR(tSC) || (pErrorMsg'="")) {
			// this rule fails
			Set tVal = 0
			Quit
		}
		If (c = 1) { ; no join for first condition
			Set tVal(tVal) = tEval
		} Else {
			If (tCond.JoinOperator = "OR") {
				Set tVal = tVal + 1 ; give AND precedence
			} Else {
				Set tVal(tVal) = $G(tVal(tVal),1) && tEval
			}
		}
	}
	Set tNum=tVal,tVal=0 For i=1:1:tNum { Set tVal = tVal || $G(tVal(i),0) }
	
	// Now execute return value and action(s) for this rule (if true)
	If (tVal) {
		Do {
			If (..ReturnValue '= "") {
				// Evaluate the return value expression
				Set tValue = ##class(ExpressionParser).Evaluate(..ReturnValue,pContext,.pErrorMsg)
				
				// user error
				If (pErrorMsg '= "") Quit
	
				Set pRuleSet.%ReturnValue = tValue
				Set pRuleSet.%Reason = "Rule " _ pRuleNo
				
				// actions
				For a=1:1:..Actions.Count() {
					Set tSC = ..Actions.GetAt(a).Execute($this,pRuleSet,pContext)  Quit:$$$ISERR(tSC)
				}
			}
		} While 0
	}
	// add rule name to error
	If (pErrorMsg '= "") {
		Set pErrorMsg = "(Rule " _ pRuleNo _ ") " _ pErrorMsg
	}
	Set pValue = tVal
	Quit tSC
}

/// Generate code for this Rule.<br>
/// <var>pRuleNo</var> gives the ordinal position of this Rule within the Rule Set.
Method GenerateCode(pCompiler As Compiler, pRuleNo As %Integer) As %Status
{
	Quit ..GenerateCodeInt($this, $G(pCompiler), $G(pRuleNo))
}

/// This class method is used to generate code for both Rules and SubRules.
/// pRSRObj is the Rule or SubRule object.
ClassMethod GenerateCodeInt(pRSRObj As %Persistent, pCompiler As Compiler, pRuleNo As %Integer, pPad As %String = " ") As %Status [ Internal ]
{
#ifndef Indent
	#define Indent(%x) %x_"  "
	#define Outdent(%x) $E(%x,1,*-3)_" "
#endif

	Set tSC=$$$OK, tExpr="", tNeedClose=0, tErrorMsg=""
	Do {
		If 0=$E(pRuleNo) { Set tCmd = "If ", pRuleNo = +pRuleNo } Else { Set tCmd = "ElseIf " }

		If (pRSRObj.Conditions.Count() = 0) {
			// this rule is true
			Do pCompiler.Code.WriteLine(pPad _ tCmd _ "1 {")
			Set tNeedClose = 1
		} Else {
			// loop over conditions, create code
			For c = 1:1:pRSRObj.Conditions.Count() { Set tCond = pRSRObj.Conditions.GetAt(c)
				Set tX = tCond.GetExpression()
		
				If (c = 1) { ; no join for first condition
					Set tExpr = tX
				} Else {
					If (tCond.JoinOperator = "OR") {
						Set tExpr = tExpr _ ")||(" _ tX
					} Else {
						Set tExpr = tExpr _ "&&" _ tX
					}
				}
			}
			Set tExpr="("_tExpr_")"
			
			// Now get code for expression
			Set tCode = ""
			Set tSC = ##class(Ens.Rule.ExpressionParser).GenerateCode(tExpr, .tCode, .tErrorMsg)  Quit:$$$ISERR(tSC)
			
			Set:$Case(tCode,"":1,"()":1,"""""":1,"("""")":1,:0) tCode = "0"
			Do pCompiler.Code.WriteLine(pPad _ tCmd _ tCode _ " {")
			Set tNeedClose = 1
			
			Do:""'=tErrorMsg pCompiler.Code.WriteLine(pPad_ "// Invalid condition: " _ tExpr)
			
			Set pPad = $$$Indent(pPad)
		}
		
		// HCR054 - Recursively generate code for SubRules of this [Sub]Rule
		Set tSubNeedClose = 0
		Set tSubFirst=1
		For n = 1:1:pRSRObj.SubRules.Count() {
			Set %objlasterror = ""
			Set tObjSubRule = pRSRObj.SubRules.GetAt(n)
			If '$IsObject(tObjSubRule) Set tSC = %objlasterror Quit
			Continue:tObjSubRule.Disabled
			Set tSubRuleNo = n
			If tSubFirst Set tSubRuleNo = "0"_tSubRuleNo, tSubFirst = 0, tSubNeedClose = 1
			Set tSC = ..GenerateCodeInt(tObjSubRule, pCompiler, tSubRuleNo, pPad)
			Quit:'tSC
		}
		If 'tSC Quit
		
		// process return value and actions
		If ((pRSRObj.ReturnValue = "") || (tErrorMsg '= "")) {
			Set tCode = """"""
		} Else {
			// Now get code for return value expression
			Set tSC = ##class(Ens.Rule.ExpressionParser).GenerateCode(pRSRObj.ReturnValue, .tCode, .tErrorMsg)  Quit:$$$ISERR(tSC)
			Do:""'=tErrorMsg pCompiler.Code.WriteLine(pPad_"// Invalid return value: " _ pRSRObj.ReturnValue)
		}
		If tSubNeedClose {
			Do pCompiler.Code.WriteLine(pPad_"Else {")
			Set pPad = $$$Indent(pPad)
		}
		Do pCompiler.Code.WriteLine(pPad_"Set pRuleDef.%Reason = ""Rule" _ pRuleNo _ """") //pRSRObj.RuleNo = pRuleNo
		If (tErrorMsg '= "") {
			Do pCompiler.Code.WriteLine(pPad_"Set pRuleDef.%ErrorMsg = """ _ tErrorMsg _ """")
		} Else {
			Do pCompiler.Code.WriteLine(pPad_"Set pRuleDef.%ReturnValue = " _ tCode)
		}
		
		// actions
		For a=1:1:pRSRObj.Actions.Count() {
			Set tAction = pRSRObj.Actions.GetAt(a)
			Set tSC = tAction.GenerateCode(pCompiler, a, pPad)  Quit:$$$ISERR(tSC)
		}
		If tSubNeedClose {
			Set pPad = $$$Outdent(pPad)
			Do pCompiler.Code.WriteLine(pPad_"}")
		}
	} While 0
	If 'tSC Quit tSC
	
	If tNeedClose {
		Set pPad = $$$Outdent(pPad)
		Do pCompiler.Code.WriteLine(pPad_"}")
	}
	
	Quit tSC
}

Storage Default
{
<Data name="RuleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Disabled</Value>
</Value>
<Value name="3">
<Value>ReturnValue</Value>
</Value>
<Value name="4">
<Value>SubRules</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Ens.Rule.RuleSet.Rules")</DataLocation>
<DefaultData>RuleDefaultData</DefaultData>
<IdLocation>^Ens.Rule.RuleSetC("Rules")</IdLocation>
<IndexLocation>^Ens.Rule.RuleI</IndexLocation>
<StreamLocation>^Ens.Rule.RuleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
