/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.AckRequested Extends (%SerialObject, EnsLib.ebXML.SOAPHeader) [ ClassType = serial, CompileAfter = EnsLib.ebXML.schema.msg.nonemptystring, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "AckRequested";

Parameter XMLSEQUENCE = 1;

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property id As %String(MAXLEN = "", REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "id", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

Property version As EnsLib.ebXML.schema.msg.nonemptystring(REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "version", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1) [ Required ];

Property signed As %Boolean(XMLNAME = "signed", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Storage Default
{
<Data name="AckRequestedState">
<Value name="1">
<Value>any</Value>
</Value>
<Value name="2">
<Value>id</Value>
</Value>
<Value name="3">
<Value>version</Value>
</Value>
<Value name="4">
<Value>mustUnderstand</Value>
</Value>
<Value name="5">
<Value>actor</Value>
</Value>
<Value name="6">
<Value>signed</Value>
</Value>
<Value name="7">
<Value>Fault</Value>
</Value>
<Value name="8">
<Value>%headerId</Value>
</Value>
<Value name="9">
<Value>XmlId</Value>
</Value>
<Value name="10">
<Value>HeaderBufferIndex</Value>
</Value>
<Value name="11">
<Value>rewriteTag</Value>
</Value>
<Value name="12">
<Value>rewriteFmt</Value>
</Value>
<Value name="13">
<Value>rewriteNamespaces</Value>
</Value>
<Value name="14">
<Value>rewriteMimeAttachments</Value>
</Value>
</Data>
<State>AckRequestedState</State>
<StreamLocation>^EnsLib.ebXML2611.AckRequestedS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
