/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a message routing action with RoutingTerm set.
Class EnsPortal.MsgFilter.Term Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLNAME = "term";

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// If false, then this term is enabled; otherwise this term is not evaluated.
Property Disabled As %Boolean(XMLNAME = "disabled", XMLPROJECTION = "attribute");

/// Type of MsgFilter Term
Property Type As %String(MAXLEN = 128, XMLNAME = "termType", XMLPROJECTION = "attribute");

/// Class used to retrieve filter field or property values
Property SourceClass As %String(MAXLEN = 128, XMLNAME = "sourceClass", XMLPROJECTION = "attribute");

/// Set of conditions that must evaluate true for a message to pass the filter.
Property Conditions As list Of EnsPortal.MsgFilter.Condition(XMLNAME = "condition", XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = Term ];

Method IsValid() As %Boolean
{
	Quit:..Disabled 0
	Quit:..Type="OR" 1
	Quit:..Type'="Header Field"&&(""=..SourceClass) 0
	Set tOKCond=0 For i=1:1:..Conditions.Count() { Set tCond=..Conditions.GetAt(i) Continue:'$IsObject(tCond)
		If ""'=tCond.Prop { Set tOKCond=1  Quit }
	}
	Quit tOKCond
}

Storage Default
{
<Data name="TermState">
<Value name="1">
<Value>Conditions</Value>
</Value>
<Value name="2">
<Value>Disabled</Value>
</Value>
<Value name="3">
<Value>SourceClass</Value>
</Value>
<Value name="4">
<Value>Type</Value>
</Value>
</Data>
<State>TermState</State>
<StreamLocation>^EnsPortal.MsgFilter.TermS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
