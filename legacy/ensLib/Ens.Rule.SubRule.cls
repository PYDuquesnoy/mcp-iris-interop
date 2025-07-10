/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a SubRule of a Business Rule or another SubRule within a Rule Set.
/// SubRules do not share the storage with Rules and there is no parent-child relationship with RuleSet.
/// SubRules are not independently evaluated neither they generate separate code.
Class Ens.Rule.SubRule Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure SubRules are ordered correctly
Index ID On RuleNo [ IdKey ];

Property RuleNo As %Integer(XMLPROJECTION = "NONE") [ InitialExpression = {$I(^Ens.Rule.RuleC("RuleNo"))} ];

/// If false, then this SubRule is enabled; otherwise this SubRule is not evaluated.
Property Disabled As %Boolean(XMLNAME = "disabled", XMLPROJECTION = "ATTRIBUTE");

/// If defined, value returned if this SubRule is true.
Property ReturnValue As %String(MAXLEN = 128, XMLNAME = "return", XMLPROJECTION = "ATTRIBUTE");

/// Collection of optional actions associated with this SubRule.
Relationship Actions As SubAction(XMLNAME = "action", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = SubRule ];

/// Collection of conditions that define this SubRule.
Relationship Conditions As SubCondition(XMLNAME = "condition", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = SubRule ];

/// Collection of SubRules of this SubRule.
Property SubRules As list Of SubRule(XMLNAME = "rule", XMLPROJECTION = "ELEMENT");

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being deleted.
/// 
/// <P>If this method returns an error then the object will not be deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ ServerOnly = 1 ]
{
	// Delete all SubRules of this SubRule
	Set o = ##class(SubRule).%Open(oid)
	If $IsObject(o) {
		For i = 1:1:o.SubRules.Count() {
			Do ##class(SubRule).%DeleteId(o.SubRules.GetAt(i).%Id())
		}
	}
	Quit $$$OK
}

/// Generate code for this SubRule.<br>
/// <var>pRuleNo</var> gives the ordinal position of this SubRule within the Rule Set.
Method GenerateCode(pCompiler As Compiler, pRuleNo As %Integer) As %Status
{
	Quit ##class(Rule).GenerateCodeInt($this, $G(pCompiler), $G(pRuleNo))
}

Storage Default
{
<Data name="SubRuleDefaultData">
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
<DataLocation>^Ens.Rule.SubRuleD</DataLocation>
<DefaultData>SubRuleDefaultData</DefaultData>
<IdLocation>^Ens.Rule.SubRuleD</IdLocation>
<IndexLocation>^Ens.Rule.SubRuleI</IndexLocation>
<StreamLocation>^Ens.Rule.SubRuleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
