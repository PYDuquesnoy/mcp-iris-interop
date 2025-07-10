/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized version of Term condition used within TermLists
Class EnsPortal.MsgFilter.Condition Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLNAME = "condition";

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// How this condition is joined with the previous one.
Property JoinOp As %String(MAXLEN = 3, VALUELIST = ",IF,AND,OR", XMLNAME = "join", XMLPROJECTION = "attribute") [ InitialExpression = "IF", Required ];

/// A property specification, form depends on the Type of the parent Term object
Property Prop As %String(MAXLEN = 255, XMLNAME = "Prop", XMLPROJECTION = "attribute");

/// Op used for this condition.
Property Op As %String(MAXLEN = 20, VALUELIST = ",=,!=,>,>=,<,<=,Contains,DoesNotContain,In,NotIn,StartsWith,DoesNotStartWith,Like,NotLike,Matches,DoesNotMatch,InFile,NotInFile", XMLNAME = "Op", XMLPROJECTION = "attribute");

/// Second operand for condition.
/// An operand is one of the following:<br>
/// A string literal (within quotes)<br>
/// A numeric literal<br>
/// A field name (of a column within the current query results)<br>
Property OpVal As %String(MAXLEN = 1000, XMLNAME = "OpVal", XMLPROJECTION = "attribute");

Property DisplayOnly As %Boolean(XMLNAME = "displayOnly", XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Called by U.I. to get list of join Ops.
ClassMethod GetJoinList() As %String [ CodeMode = objectgenerator ]
{
	Set tIndex = %compiledclass.Properties.FindObjectId(%class.Name_"||JoinOp")
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
<Data name="ConditionState">
<Value name="1">
<Value>JoinOp</Value>
</Value>
<Value name="2">
<Value>Op</Value>
</Value>
<Value name="3">
<Value>OpVal</Value>
</Value>
<Value name="4">
<Value>Prop</Value>
</Value>
<Value name="5">
<Value>DisplayOnly</Value>
</Value>
</Data>
<State>ConditionState</State>
<StreamLocation>^EnsPortal.MsgFilter.ConditionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
