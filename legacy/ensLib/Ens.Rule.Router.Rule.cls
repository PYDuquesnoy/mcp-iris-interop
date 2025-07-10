/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a message routing action with RoutingRule set.
Class Ens.Rule.Router.Rule Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure rules are ordered correctly
Index ID On RuleNo [ IdKey ];

Property RuleNo As %Integer(XMLPROJECTION = "none") [ InitialExpression = {$I(^Ens.Rule.RuleC("RuleNo"))} ];

/// Parent RuleSet.
Relationship RuleSet As Ens.Rule.Router.RoutingRule [ Cardinality = parent, Inverse = Rules ];

/// If false, then this rule is enabled; otherwise this rule is not evaluated.
Property Disabled As %Boolean(XMLNAME = "disabled", XMLPROJECTION = "attribute");

/// If defined, message must be from this source to match this rule.
Property Source As %String(MAXLEN = 128, XMLNAME = "source", XMLPROJECTION = "attribute");

/// If defined, message must be of this class type to match this rule.
/// If not defined, then the default value defined by the RoutingRule set is used.
Property MsgClass As %String(MAXLEN = 128, XMLNAME = "msgClass", XMLPROJECTION = "attribute");

/// If defined, the message must have this logical name in order to match
/// this rule.<br>
/// This is a comma-delimited list of document names 
/// (applies to virtual document messages only).<br>
/// Each item in the list is tested against the document type name declared in the document.
/// If not defined, then the default value defined by the RoutingRule set is used.
Property DocName As %String(MAXLEN = 2000, XMLNAME = "docName", XMLPROJECTION = "attribute");

/// If defined, the message must have this document category in order
/// to match this rule.<br>
/// This is the document structure category name of a document structure name (DocType)
/// (applies to virtual document messages only).<br>
/// For example in HL7 this is a schema version, e.g. "2.3.1".
/// If not defined, then the default value defined by the RoutingRule set is used.
Property DocCategory As %String(MAXLEN = 128, XMLNAME = "docCategory", XMLPROJECTION = "attribute");

/// If defined, the message must be of this document type to match 
/// this rule.<br>
/// This is the document type of a message (applies to virtual documents
/// messages only). It indicates the <em>structure</em> of a message.<br>
/// If not defined, then the default value defined by the RoutingRule set is used.
/// This is a comma-delimited list of document structure types. Each item in the list
/// <em>can</em> include a category name, which would override the 
/// values provided by <property>DocCategory</property> and the
/// RoutingRule set's <property>DocCategory</property> value.
Property DocType As %String(MAXLEN = 2000, XMLNAME = "docType", XMLPROJECTION = "attribute");

/// Set of conditions that must evaluate true for this rule to fire.
Relationship Conditions As Ens.Rule.Router.Condition(XMLNAME = "condition", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = Rule ];

/// Set of actions that are fired if this rule evaluates true.
Relationship Actions As Ens.Rule.Router.Action(XMLNAME = "action", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = Rule ];

/// Generate code for this rule.<br>
/// <var>pRuleNo</var> gives the ordinal position of this rule within the rule set.
Method GenerateCode(pCompiler As Ens.Rule.Compiler, pRuleNo As %Integer) As %Status
{
	Set tSC=$$$OK, tExpr="", tNeedClose=0, tErrorMsg=""
	Do {
		If (..Conditions.Count() '= 0) {
			// loop over conditions, create code
			For c = 1:1:..Conditions.Count() { Set tCond = ..Conditions.GetAt(c)
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
			Set tSC = ##class(Ens.Rule.ExpressionParser).GenerateCode(tExpr, .tCode, .tErrorMsg)
			Do:(tErrorMsg'="") pCompiler.Code.WriteLine("  // Invalid condition: " _ tExpr)
			Quit:$$$ISERR(tSC)
			
			If $Case(tCode,"":0,"()":0,"""""":0,"("""")":0,:1) {
				Do pCompiler.Code.WriteLine(" If " _ tCode _ " {")
				Set tNeedClose = 1
			}
		}
		// process return value
		// walk down list of actions, and build return string
		Set tRetCode = ""
		Set aCount=..Actions.Count()  For a = 1:1:aCount { Set tAction = ..Actions.GetAt(a)
			Set tRetCode = tRetCode _ $S(tRetCode="":"",1:";") _ tAction.Type _ ":" _ tAction.Target _ ":" _ tAction.Transform
		}
		// don't worry about *reason*; caller will handle that
		If (tErrorMsg '= "") { ; error in condition: report at run-time
			Do pCompiler.Code.WriteLine("  Set err=""" _ tErrorMsg _ """")
		} Else {
			Do pCompiler.Code.WriteLine("  Set ret=""" _ tRetCode _""" ; " _ aCount _ " action"_$S(aCount>1:"s",1:""))
		}
	} While 0

	Do:tNeedClose pCompiler.Code.Write(" }")
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
<Value>MsgClass</Value>
</Value>
<Value name="4">
<Value>MsgType</Value>
</Value>
<Value name="5">
<Value>MsgVersion</Value>
</Value>
<Value name="6">
<Value>Source</Value>
</Value>
<Value name="7">
<Value>DocCategory</Value>
</Value>
<Value name="8">
<Value>DocName</Value>
</Value>
<Value name="9">
<Value>DocType</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Ens.Rule.Router.RoutingRule.Rules")</DataLocation>
<DefaultData>RuleDefaultData</DefaultData>
<IdLocation>^Ens.Rule.Router.RoutingRuleC("Rules")</IdLocation>
<IndexLocation>^Ens.Rule.Router.RuleI</IndexLocation>
<StreamLocation>^Ens.Rule.Router.RuleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
