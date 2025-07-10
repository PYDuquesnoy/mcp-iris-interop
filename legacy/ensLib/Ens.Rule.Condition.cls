/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.Condition Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure conditions are ordered correctly
Index ID On CondNo [ IdKey ];

Property CondNo As %Integer(XMLPROJECTION = "none") [ InitialExpression = {$I(^Ens.Rule.ConditionC("CondNo"))} ];

/// How this condition is joined with the previous one.
Property JoinOperator As %String(MAXLEN = 3, VALUELIST = ",AND,OR", XMLNAME = "join", XMLPROJECTION = "attribute") [ InitialExpression = "AND", Required ];

/// Operator used for this condition.
Property Operator As %String(MAXLEN = 20, VALUELIST = ",=,!=,>,>=,<,<=,Contains,DoesNotContain,In,NotIn,StartsWith,DoesNotStartWith,Like,NotLike,Matches,DoesNotMatch,InFile,NotInFile,IntersectsList,DoesNotIntersectList", XMLNAME = "operator", XMLPROJECTION = "attribute");

/// First operand for condition.<br>
/// An operand is one of the following:<br>
/// A string literal (within quotes)<br>
/// A numeric literal<br>
/// A property name (of a property within the associated Business Process context)<br>
/// The name of another RuleDefinition associated with the same Busiess Process (rule name starts with #)<br>
Property Operand1 As %String(MAXLEN = 2500, XMLNAME = "op1", XMLPROJECTION = "attribute");

/// Second operand for condition.
/// An operand is one of the following:<br>
/// A string literal (within quotes)<br>
/// A numeric literal<br>
/// A property name (of a property within the associated Business Process context)<br>
/// The name of another RuleDefinition associated with the same Busiess Process (rule name starts with #)<br>
Property Operand2 As %String(MAXLEN = 2500, XMLNAME = "op2", XMLPROJECTION = "attribute");

/// Parent Rule.
Relationship Rule As Ens.Rule.Rule [ Cardinality = parent, Inverse = Conditions ];

/// Evaluate this Condition.<br>
/// Returns user errors via <var>pErrorMsg</var>.
Method Evaluate(pRuleSet As RuleDefinition, pContext As %RegisteredObject, Output pValue As %Boolean, Output pErrorMsg As %String) As %Status
{
	Quit ..EvaluateInt($this, $G(pRuleSet), $G(pContext), .pValue, .pErrorMsg)
}

/// This class method is used for both Rules and SubRules.
/// pRSRObj is the Rule or SubRule object.
ClassMethod EvaluateInt(pRSRObj As %Persistent, pRuleSet As RuleDefinition, pContext As %RegisteredObject, Output pValue As %Boolean, Output pErrorMsg As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pValue = 0
	Set pErrorMsg = ""

	Do {
		// Evaluate the operand expressions
		Set tOp1 = ##class(ExpressionParser).Evaluate(pRSRObj.Operand1,pContext,.pErrorMsg)
		If (pErrorMsg '= "") Quit
		
		If (pRSRObj.Operator = "") {
			// no operator
			Set pValue = tOp1
			Quit
		}

		Set tOp2 = ##class(ExpressionParser).Evaluate(pRSRObj.Operand2,pContext,.pErrorMsg)
		If (pErrorMsg '= "") Quit

		If (pRSRObj.Operator = "=") {
			Set pValue = (tOp1 = tOp2)
		}
		ElseIf (pRSRObj.Operator = "!=") {
			Set pValue = (tOp1 '= tOp2)
		}
		ElseIf (pRSRObj.Operator = ">") {
			Set pValue = (tOp1 > tOp2)
		}
		ElseIf (pRSRObj.Operator = ">=") {
			Set pValue = (tOp1 >= tOp2)
		}
		ElseIf (pRSRObj.Operator = "<") {
			Set pValue = (tOp1 < tOp2)
		}
		ElseIf (pRSRObj.Operator = "<=") {
			Set pValue = (tOp1 <= tOp2)
		}
	} While(0)
	
	Quit tSC
}

/// Return the logical expression for this condition.
Method GetExpression() As %String
{
	Quit ..GetExpressionInt($this)
}

/// This class method is used for both Rules and SubRules.
/// pRSRObj is the Rule or SubRule object.
ClassMethod GetExpressionInt(pRSRObj As %Persistent) As %String [ Internal ]
{

	Set op1 = $S(pRSRObj.Operand1="":"""""",1:pRSRObj.Operand1)
	Set op2 = $S(pRSRObj.Operand2="":"""""",1:pRSRObj.Operand2)

	If (pRSRObj.Operator = "") {
		// no operator
		Set pExpr = op1
	}
	Else {
		Set op = pRSRObj.Operator

		// See if this is a "function" operator
		Set isFunc = $Case(op,"Contains":1,"DoesNotContain":1,"In":1,"NotIn":1,"StartsWith":1,"DoesNotStartWith":1,"Like":1,"NotLike":1,"Matches":1,"DoesNotMatch":1,"InFile":1,"NotInFile":1,:0)
		
		If (isFunc) {
			// expression is a function call
			Set pExpr = op _ "(" _ "("_op1_"),("_op2_"))"
		} Else {
			Set pExpr = "("_op1_")" _ op _ "("_op2_")"
		}
	}
	
	Quit pExpr
}

/// Called by U.I. to get list of operators.
ClassMethod GetOperatorList() As %String [ CodeMode = objectgenerator ]
{
	Set tIndex = %compiledclass.Properties.FindObjectId(%class.Name_"||Operator")
	If (tIndex = "") {
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	Set tParms = %compiledclass.Properties.GetAt(tIndex).Parameters
	Set tList = tParms.GetAt("VALUELIST")
	Do %code.WriteLine(" Quit """ _ tList _ """")
	Quit $$$OK
}

/// Called by U.I. to get list of join operators.
ClassMethod GetJoinList() As %String [ CodeMode = objectgenerator ]
{
	Set tIndex = %compiledclass.Properties.FindObjectId(%class.Name_"||JoinOperator")
	If (tIndex = "") {
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	Set tParms = %compiledclass.Properties.GetAt(tIndex).Parameters
	Set tList = tParms.GetAt("VALUELIST")
	Do %code.WriteLine(" Quit """ _ tList _ """")
	Quit $$$OK
}

Storage Default
{
<Data name="ConditionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>JoinOperator</Value>
</Value>
<Value name="3">
<Value>Operand1</Value>
</Value>
<Value name="4">
<Value>Operand2</Value>
</Value>
<Value name="5">
<Value>Operator</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Conditions")</DataLocation>
<DefaultData>ConditionDefaultData</DefaultData>
<IdLocation>^Ens.Rule.RuleC("Conditions")</IdLocation>
<IndexLocation>^Ens.Rule.ConditionI</IndexLocation>
<StreamLocation>^Ens.Rule.ConditionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
