/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents an Action associated with a Rule within a MsgRouter rule.
Class Ens.Rule.Router.Action Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, SqlTableName = RuleAction, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Make sure actions are ordered correctly
Index ID On ActionNo [ IdKey ];

/// Parent Rule.
Relationship Rule As Ens.Rule.Router.Rule [ Cardinality = parent, Inverse = Actions ];

Property ActionNo As %Integer(XMLPROJECTION = "none") [ InitialExpression = {$I(^Ens.Rule.ActionC("ActionNo"))} ];

/// What type of action this is. The possible values are:<br>
/// <i>send</i> Send the message to a target and, if defined, apply a transformation (before sending).<br>
/// <i>delete</i> Delete the message.<br>
/// <i>delegate</i> Forward the message to a different rule for processing.<br>
Property Type As %String(MAXLEN = 50, VALUELIST = ",send,delete,stop,contin,delegate", XMLNAME = "type", XMLPROJECTION = "attribute") [ InitialExpression = "AND", Required ];

/// Name of target (host name) to send the message to if this action is fired
/// <property>Type</property> is "send".
Property Target As %String(MAXLEN = "", XMLNAME = "target", XMLPROJECTION = "attribute");

/// If defined, name of data transformation used for this message
/// if this action is fired <property>Type</property> is "send".
Property Transform As %String(MAXLEN = "", XMLNAME = "transform", XMLPROJECTION = "attribute");

/// Called by U.I. to get list of action types.
ClassMethod GetTypeList() As %String [ CodeMode = objectgenerator ]
{
	Set tIndex = %compiledclass.Properties.FindObjectId(%class.Name_"||Type")
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
<Data name="ActionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Target</Value>
</Value>
<Value name="3">
<Value>Transform</Value>
</Value>
<Value name="4">
<Value>Type</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Actions")</DataLocation>
<DefaultData>ActionDefaultData</DefaultData>
<IdLocation>^Ens.Rule.Router.RuleC("Actions")</IdLocation>
<IndexLocation>^Ens.Rule.Router.ActionI</IndexLocation>
<StreamLocation>^Ens.Rule.Router.ActionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
