/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.Schema Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.nonemptystring, Inheritance = right, ProcedureBlock, SqlTableName = _Schema, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "Schema";

Parameter XMLSEQUENCE = 1;

Property location As %String(MAXLEN = "", XMLNAME = "location", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property version As EnsLib.ebXML.schema.msg.nonemptystring(XMLNAME = "version", XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="SchemaState">
<Value name="1">
<Value>location</Value>
</Value>
<Value name="2">
<Value>version</Value>
</Value>
</Data>
<State>SchemaState</State>
<StreamLocation>^EnsLib.ebXML.schema2611.SchemaS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
