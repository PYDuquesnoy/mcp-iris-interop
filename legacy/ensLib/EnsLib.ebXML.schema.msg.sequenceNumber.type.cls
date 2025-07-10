/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd
Class EnsLib.ebXML.schema.msg.sequenceNumber.type Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.status.type, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "sequenceNumber.type";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "sequenceNumber.type";

Property content As %xsd.nonNegativeInteger(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property status As EnsLib.ebXML.schema.msg.status.type(XMLNAME = "status", XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="typeState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>status</Value>
</Value>
</Data>
<State>typeState</State>
<StreamLocation>^EnsLib.ebXML.schema.m84B0.typeS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
