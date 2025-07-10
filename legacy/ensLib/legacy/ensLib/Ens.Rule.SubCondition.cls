/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.SubCondition Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure conditions are ordered correctly
Index ID On CondNo [ IdKey ];

Property CondNo As %Integer(XMLPROJECTION = "none") [ InitialExpression = {$I(^Ens.Rule.ConditionC("CondNo"))} ];

/// How this condition is joined with the previous one.
Property JoinOperator As %String(MAXLEN = 3, VALUELIST = ",AND,OR", XMLNAME = "join", XMLPROJECTION = "attribute") [ InitialExpression = "AND", Required ];

/// Operator used for this condition.
Property Operator As %String(MAXLEN = 20, VALUELIST = ",=,!=,>,>=,<,<=,Contains,DoesNotContain,In,NotIn,StartsWith,DoesNotStartWith,Like,NotLike,Matches,DoesNotMatch,InFile,NotInFile", XMLNAME = "operator", XMLPROJECTION = "attribute");

/// First operand for condition.<br>
/// An operand is one of the following:<br>
/// A string literal (within quotes)<br>
/// A numeric literal<br>
/// A property name (of a property within the associated Business Process context)<br>
/// The name of another RuleDefinition associated with the same Busiess Process (rule name starts with #)<br>
Property Operand1 As %String(MAXLEN = 255, XMLNAME = "op1", XMLPROJECTION = "attribute");

/// Second operand for condition.
/// An operand is one of the following:<br>
/// A string literal (within quotes)<br>
/// A numeric literal<br>
/// A property name (of a property within the associated Business Process context)<br>
/// The name of another RuleDefinition associated with the same Busiess Process (rule name starts with #)<br>
Property Operand2 As %String(MAXLEN = 255, XMLNAME = "op2", XMLPROJECTION = "attribute");

/// Parent Rule.
Relationship SubRule As Ens.Rule.SubRule [ Cardinality = parent, Inverse = Conditions ];

/// Evaluate this condition.<br>
/// Returns user errors via <var>pErrorMsg</var>.
Method Evaluate(pRuleSet As RuleDefinition, pContext As %RegisteredObject, Output pValue As %Boolean, Output pErrorMsg As %String) As %Status
{
	Quit ##class(Condition).EvaluateInt($this, $G(pRuleSet), $G(pContext), .pValue, .pErrorMsg)
}

/// Return the logical expression for this condition.
Method GetExpression() As %String
{
	Quit ##class(Condition).GetExpressionInt($this)
}

Storage Default
{
<Data name="SubConditionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>JoinOperator</Value>
</Value>
<Value name="3">
<Value>Operator</Value>
</Value>
<Value name="4">
<Value>Operand1</Value>
</Value>
<Value name="5">
<Value>Operand2</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Conditions")</DataLocation>
<DefaultData>SubConditionDefaultData</DefaultData>
<IdLocation>^Ens.Rule.SubRuleC("Conditions")</IdLocation>
<IndexLocation>^Ens.Rule.SubConditionI</IndexLocation>
<StreamLocation>^Ens.Rule.SubConditionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
