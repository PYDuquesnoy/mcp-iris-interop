/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an Action associated with a specific SubRule.
/// Actual Actions are defined by subclasses.
Class Ens.Rule.SubAction Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, SqlTableName = SubRuleAction, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure actions are ordered correctly
Index ID On ActionNo [ IdKey ];

Property ActionNo As %Integer(XMLPROJECTION = "none") [ InitialExpression = {$I(^Ens.Rule.RuleC("ActionNo"))} ];

/// Parent Rule.
Relationship SubRule As Ens.Rule.SubRule [ Cardinality = parent, Inverse = Actions ];

/// Execute this Action.
Method Execute(pRule As Rule, pRuleSet As RuleDefinition, pContext As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Quit tSC
}

/// Generate code for this action
Method GenerateCode(pCompiler As Compiler, pActionNo As %Integer) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

Storage Default
{
<Data name="SubActionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Actions")</DataLocation>
<DefaultData>SubActionDefaultData</DefaultData>
<IdLocation>^Ens.Rule.SubRuleC("Actions")</IdLocation>
<IndexLocation>^Ens.Rule.SubActionI</IndexLocation>
<StreamLocation>^Ens.Rule.SubActionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
