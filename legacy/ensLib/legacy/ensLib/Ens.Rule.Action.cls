/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an Action associated with a specific Rule within a RuleSet.
/// Actual Actions are defined by subclasses.
Class Ens.Rule.Action Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, SqlTableName = RuleAction, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure actions are ordered correctly
Index ID On ActionNo [ IdKey ];

Property ActionNo As %Integer(XMLPROJECTION = "NONE") [ InitialExpression = {$I(^Ens.Rule.RuleC("ActionNo"))} ];

/// Parent Rule.
Relationship Rule As Ens.Rule.Rule [ Cardinality = parent, Inverse = Actions ];

/// Execute this Action.
Method Execute(pRule As Rule, pRuleSet As RuleDefinition, pContext As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Quit tSC
}

/// Generate code for this action
Method GenerateCode(pCompiler As Compiler, pActionNo As %Integer, pPad As %String = " ") As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

Storage Default
{
<Data name="ActionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Actions")</DataLocation>
<DefaultData>ActionDefaultData</DefaultData>
<IdLocation>^Ens.Rule.RuleC("Actions")</IdLocation>
<IndexLocation>^Ens.Rule.ActionI</IndexLocation>
<StreamLocation>^Ens.Rule.ActionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
