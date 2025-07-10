/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.Error Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = (EnsLib.ebXML.schema.msg.nonemptystring, EnsLib.ebXML.schema.msg.severity.type), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "Error";

Parameter XMLSEQUENCE = 1;

Property Description As EnsLib.ebXML.schema.msg.Description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Description", XMLREF = 1);

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property id As %String(MAXLEN = "", REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "id", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

Property codeContext As %String(MAXLEN = "", XMLNAME = "codeContext", XMLPROJECTION = "ATTRIBUTE");

Property errorCode As EnsLib.ebXML.schema.msg.nonemptystring(XMLNAME = "errorCode", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property severity As EnsLib.ebXML.schema.msg.severity.type(XMLNAME = "severity", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property location As EnsLib.ebXML.schema.msg.nonemptystring(XMLNAME = "location", XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="ErrorState">
<Value name="1">
<Value>Description</Value>
</Value>
<Value name="2">
<Value>any</Value>
</Value>
<Value name="3">
<Value>id</Value>
</Value>
<Value name="4">
<Value>codeContext</Value>
</Value>
<Value name="5">
<Value>errorCode</Value>
</Value>
<Value name="6">
<Value>severity</Value>
</Value>
<Value name="7">
<Value>location</Value>
</Value>
</Data>
<State>ErrorState</State>
<StreamLocation>^EnsLib.ebXML.schema.msg.ErrorS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
