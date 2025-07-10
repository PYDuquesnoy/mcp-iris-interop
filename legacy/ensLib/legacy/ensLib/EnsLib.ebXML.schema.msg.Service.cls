/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.Service Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.nonemptystring, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "Service";

Parameter XMLSEQUENCE = 1;

Property content As EnsLib.ebXML.schema.msg.nonemptystring(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property type As EnsLib.ebXML.schema.msg.nonemptystring(XMLNAME = "type", XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="ServiceState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
</Data>
<State>ServiceState</State>
<StreamLocation>^EnsLib.ebXML.schem2611.ServiceS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
