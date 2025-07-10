/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.StatusResponse Extends (%SerialObject, EnsLib.ebXML.SOAPHeader) [ ClassType = serial, CompileAfter = (EnsLib.ebXML.schema.msg.messageStatus.type, EnsLib.ebXML.schema.msg.nonemptystring), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "StatusResponse";

Parameter XMLSEQUENCE = 1;

Property RefToMessageId As EnsLib.ebXML.schema.msg.nonemptystring(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "RefToMessageId", XMLREF = 1) [ Required ];

Property Timestamp As %TimeStamp(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Timestamp", XMLREF = 1) [ SqlFieldName = _Timestamp ];

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property id As %String(MAXLEN = "", REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "id", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

Property version As EnsLib.ebXML.schema.msg.nonemptystring(REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "version", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1) [ Required ];

Property messageStatus As EnsLib.ebXML.schema.msg.messageStatus.type(XMLNAME = "messageStatus", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Storage Default
{
<Data name="StatusResponseState">
<Value name="1">
<Value>RefToMessageId</Value>
</Value>
<Value name="2">
<Value>Timestamp</Value>
</Value>
<Value name="3">
<Value>any</Value>
</Value>
<Value name="4">
<Value>id</Value>
</Value>
<Value name="5">
<Value>version</Value>
</Value>
<Value name="6">
<Value>messageStatus</Value>
</Value>
<Value name="7">
<Value>Fault</Value>
</Value>
<Value name="8">
<Value>actor</Value>
</Value>
<Value name="9">
<Value>mustUnderstand</Value>
</Value>
<Value name="10">
<Value>%headerId</Value>
</Value>
<Value name="11">
<Value>XmlId</Value>
</Value>
<Value name="12">
<Value>HeaderBufferIndex</Value>
</Value>
<Value name="13">
<Value>rewriteTag</Value>
</Value>
<Value name="14">
<Value>rewriteFmt</Value>
</Value>
<Value name="15">
<Value>rewriteNamespaces</Value>
</Value>
<Value name="16">
<Value>rewriteMimeAttachments</Value>
</Value>
</Data>
<State>StatusResponseState</State>
<StreamLocation>^EnsLib.ebXM2611.StatusResponseS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
