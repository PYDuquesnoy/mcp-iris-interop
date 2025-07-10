/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.MessageData Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.nonemptystring, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "MessageData";

Parameter XMLSEQUENCE = 1;

Property MessageId As EnsLib.ebXML.schema.msg.nonemptystring(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "MessageId", XMLREF = 1) [ Required ];

Property Timestamp As %TimeStamp(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Timestamp", XMLREF = 1) [ Required, SqlFieldName = _Timestamp ];

Property RefToMessageId As EnsLib.ebXML.schema.msg.nonemptystring(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "RefToMessageId", XMLREF = 1);

Property TimeToLive As %TimeStamp(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "TimeToLive", XMLREF = 1);

Storage Default
{
<Data name="MessageDataState">
<Value name="1">
<Value>MessageId</Value>
</Value>
<Value name="2">
<Value>Timestamp</Value>
</Value>
<Value name="3">
<Value>RefToMessageId</Value>
</Value>
<Value name="4">
<Value>TimeToLive</Value>
</Value>
</Data>
<State>MessageDataState</State>
<StreamLocation>^EnsLib.ebXML.s2611.MessageDataS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
