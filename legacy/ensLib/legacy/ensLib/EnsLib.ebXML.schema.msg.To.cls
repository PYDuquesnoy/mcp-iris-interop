/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.To Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.nonemptystring, Inheritance = right, ProcedureBlock, SqlTableName = _To, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "To";

Parameter XMLSEQUENCE = 1;

Property PartyId As list Of EnsLib.ebXML.schema.msg.PartyId(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "PartyId", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property Role As EnsLib.ebXML.schema.msg.nonemptystring(XMLNAME = "Role") [ SqlFieldName = _Role ];

Storage Default
{
<Data name="ToState">
<Value name="1">
<Value>PartyId</Value>
</Value>
<Value name="2">
<Value>Role</Value>
</Value>
</Data>
<State>ToState</State>
<StreamLocation>^EnsLib.ebXML.schema.msg.ToS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
