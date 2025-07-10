/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements the Assign Action for Rules.
Class Ens.Rule.Assign Extends Ens.Rule.Action [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Name of context Property to assign value into.
Property Property As %String(MAXLEN = 128, XMLNAME = "property", XMLPROJECTION = "ATTRIBUTE");

/// Value that is to be assigned.
Property Value As %String(MAXLEN = 128, XMLNAME = "value", XMLPROJECTION = "ATTRIBUTE") [ SqlFieldName = AssignValue ];

/// Execute this Assignment Action.
Method Execute(pRule As Rule, pRuleSet As RuleDefinition, pContext As %RegisteredObject) As %Status
{
	Quit ..ExecuteInt($this, $G(pRule), $G(pRuleSet), $G(pContext))
}

/// This class method is used to execute the Assign Action for both Rules and SubRules.
/// pRSRObj is the Rule or SubRule object.
ClassMethod ExecuteInt(pRSRObj As %Persistent, pRule As %Persistent, pRuleSet As RuleDefinition, pContext As %RegisteredObject) As %Status [ Internal ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK

	If ($IsObject(pContext) && (pRSRObj.Property '= "")) {
		// evaluate Value
		Set tValue = ##class(ExpressionParser).Evaluate(pRSRObj.Value,pContext)
		Set $zobjproperty(pContext,pRSRObj.Property) = tValue
	}

Done	
	Quit tSC
Trap
	Set $ZT=""
	Goto Done
}

/// Generate code for this Assign Action.
Method GenerateCode(pCompiler As Compiler, pActionNo As %Integer, pPad As %String = " ") As %Status
{
	Quit ..GenerateCodeInt($this, pCompiler, pActionNo, pPad)
}

/// This class method is used to generate code for the Assign Action for both Rules and SubRules.
/// pRSRObj is the Rule or SubRule object.
ClassMethod GenerateCodeInt(pRSRObj As %Persistent, pCompiler As Compiler, pActionNo As %Integer, pPad As %String = " ") As %Status [ Internal ]
{
	Set tSC = $$$OK

	Do {
		Do pCompiler.Code.WriteLine(pPad_"// action #" _ pActionNo)
		If (pRSRObj.Property '= "") {
			Set tErrorMsg = ""
			If (pRSRObj.Value = "") {
				Set tGetCode = """"""
			}
			Else {
				// Now get code for value expression
				Set tSC = ##class(Ens.Rule.ExpressionParser).GenerateCode(pRSRObj.Value, .tGetCode, .tErrorMsg)
				If $$$ISERR(tSC) Quit
			}

			If (tErrorMsg '= "") {
				Do pCompiler.Code.WriteLine(pPad_"// Invalid action: " _ pRSRObj.Value)
				Do pCompiler.Code.WriteLine(pPad_"Set pRuleDef.%ErrorMsg = ""Invalid value for action: " _ tErrorMsg _ """")
			}
			Else {
				Set tProperty = "pContext." _ pRSRObj.Property
				Set tSC = ##class(Ens.Rule.ExpressionParser).GenSetCode(.tSetCode, tProperty, tGetCode)
				If $$$ISERR(tSC) Quit
				If (tSetCode = "") {
					Do pCompiler.Code.WriteLine(pPad_"// Invalid property for action: " _ tProperty)
				}
				Else {
					Do pCompiler.Code.WriteLine(pPad _ tSetCode)
				}
			}
		}
	} While(0)
	
	Quit tSC
}

Storage Default
{
<Data name="AssignDefaultData">
<Subscript>"Assign"</Subscript>
<Value name="1">
<Value>Property</Value>
</Value>
<Value name="2">
<Value>Value</Value>
</Value>
</Data>
<DefaultData>AssignDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
