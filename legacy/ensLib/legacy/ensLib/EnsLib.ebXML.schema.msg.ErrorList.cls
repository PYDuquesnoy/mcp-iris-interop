/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.ErrorList Extends (%SerialObject, EnsLib.ebXML.SOAPHeader) [ ClassType = serial, CompileAfter = (EnsLib.ebXML.schema.msg.nonemptystring, EnsLib.ebXML.schema.msg.severity.type), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "ErrorList";

Parameter XMLSEQUENCE = 1;

Property Error As list Of EnsLib.ebXML.schema.msg.Error(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Error", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property id As %String(MAXLEN = "", REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "id", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

Property version As EnsLib.ebXML.schema.msg.nonemptystring(REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "version", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1) [ Required ];

Property highestSeverity As EnsLib.ebXML.schema.msg.severity.type(XMLNAME = "highestSeverity", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Storage Default
{
<Data name="ErrorListState">
<Value name="1">
<Value>Error</Value>
</Value>
<Value name="2">
<Value>any</Value>
</Value>
<Value name="3">
<Value>id</Value>
</Value>
<Value name="4">
<Value>version</Value>
</Value>
<Value name="5">
<Value>mustUnderstand</Value>
</Value>
<Value name="6">
<Value>highestSeverity</Value>
</Value>
<Value name="7">
<Value>Fault</Value>
</Value>
<Value name="8">
<Value>actor</Value>
</Value>
<Value name="9">
<Value>%headerId</Value>
</Value>
<Value name="10">
<Value>XmlId</Value>
</Value>
<Value name="11">
<Value>HeaderBufferIndex</Value>
</Value>
<Value name="12">
<Value>rewriteTag</Value>
</Value>
<Value name="13">
<Value>rewriteFmt</Value>
</Value>
<Value name="14">
<Value>rewriteNamespaces</Value>
</Value>
<Value name="15">
<Value>rewriteMimeAttachments</Value>
</Value>
</Data>
<State>ErrorListState</State>
<StreamLocation>^EnsLib.ebXML.sch2611.ErrorListS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
