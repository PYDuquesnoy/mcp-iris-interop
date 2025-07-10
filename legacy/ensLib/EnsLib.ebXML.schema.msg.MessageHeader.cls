/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.MessageHeader Extends (%SerialObject, EnsLib.ebXML.SOAPHeader) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.nonemptystring, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "MessageHeader";

Parameter XMLSEQUENCE = 1;

Property From As EnsLib.ebXML.schema.msg.From(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "From", XMLREF = 1) [ Required, SqlFieldName = _From ];

Property To As EnsLib.ebXML.schema.msg.To(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "To", XMLREF = 1) [ Required, SqlFieldName = _To ];

Property CPAId As EnsLib.ebXML.schema.msg.nonemptystring(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "CPAId", XMLREF = 1) [ Required ];

Property ConversationId As EnsLib.ebXML.schema.msg.nonemptystring(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "ConversationId", XMLREF = 1) [ Required ];

Property Service As EnsLib.ebXML.schema.msg.Service(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Service", XMLREF = 1) [ Required ];

Property Action As EnsLib.ebXML.schema.msg.nonemptystring(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Action", XMLREF = 1) [ Required ];

Property MessageData As EnsLib.ebXML.schema.msg.MessageData(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "MessageData", XMLREF = 1) [ Required ];

Property DuplicateElimination As %String(MAXLEN = "", REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "DuplicateElimination", XMLREF = 1);

Property Description As list Of EnsLib.ebXML.schema.msg.Description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property id As %String(MAXLEN = "", REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "id", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

Property version As EnsLib.ebXML.schema.msg.nonemptystring(REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "version", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1) [ Required ];

Storage Default
{
<Data name="MessageHeaderState">
<Value name="1">
<Value>From</Value>
</Value>
<Value name="2">
<Value>To</Value>
</Value>
<Value name="3">
<Value>CPAId</Value>
</Value>
<Value name="4">
<Value>ConversationId</Value>
</Value>
<Value name="5">
<Value>Service</Value>
</Value>
<Value name="6">
<Value>Action</Value>
</Value>
<Value name="7">
<Value>MessageData</Value>
</Value>
<Value name="8">
<Value>DuplicateElimination</Value>
</Value>
<Value name="9">
<Value>Description</Value>
</Value>
<Value name="10">
<Value>any</Value>
</Value>
<Value name="11">
<Value>id</Value>
</Value>
<Value name="12">
<Value>version</Value>
</Value>
<Value name="13">
<Value>mustUnderstand</Value>
</Value>
<Value name="14">
<Value>Fault</Value>
</Value>
<Value name="15">
<Value>actor</Value>
</Value>
<Value name="16">
<Value>%headerId</Value>
</Value>
<Value name="17">
<Value>XmlId</Value>
</Value>
<Value name="18">
<Value>HeaderBufferIndex</Value>
</Value>
<Value name="19">
<Value>rewriteTag</Value>
</Value>
<Value name="20">
<Value>rewriteFmt</Value>
</Value>
<Value name="21">
<Value>rewriteNamespaces</Value>
</Value>
<Value name="22">
<Value>rewriteMimeAttachments</Value>
</Value>
</Data>
<State>MessageHeaderState</State>
<StreamLocation>^EnsLib.ebXML2611.MessageHeaderS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
