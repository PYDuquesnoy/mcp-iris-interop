/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.Description Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.nonemptystring, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "Description";

Parameter XMLSEQUENCE = 1;

Property content As EnsLib.ebXML.schema.msg.nonemptystring(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property lang As %String(MAXLEN = "", XMLNAME = "lang", XMLPROJECTION = "XMLATTRIBUTE") [ Required ];

Storage Default
{
<Data name="DescriptionState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>lang</Value>
</Value>
</Data>
<State>DescriptionState</State>
<StreamLocation>^EnsLib.ebXML.s2611.DescriptionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
