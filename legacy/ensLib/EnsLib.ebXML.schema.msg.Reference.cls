/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class EnsLib.ebXML.schema.msg.Reference Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter XMLNAME = "Reference";

Parameter XMLSEQUENCE = 1;

Property Schema As list Of EnsLib.ebXML.schema.msg.Schema(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Schema", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ SqlFieldName = _Schema ];

Property Description As list Of EnsLib.ebXML.schema.msg.Description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "Description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property any As list Of EnsLib.ebXML.schema.msg.base(CLASSNAME = 1, XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property id As %String(MAXLEN = "", REFNAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd", XMLNAME = "id", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

Property type As %String(MAXLEN = "", REFNAMESPACE = "http://www.w3.org/1999/xlink", VALUELIST = ",simple,extended,locator,arc,resource,title,none", XMLNAME = "type", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1);

Property href As %String(MAXLEN = "", REFNAMESPACE = "http://www.w3.org/1999/xlink", XMLNAME = "href", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1) [ Required ];

Property role As %String(MAXLEN = "", REFNAMESPACE = "http://www.w3.org/1999/xlink", XMLNAME = "role", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1) [ SqlFieldName = _role ];

Storage Default
{
<Data name="ReferenceState">
<Value name="1">
<Value>Schema</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>any</Value>
</Value>
<Value name="4">
<Value>id</Value>
</Value>
<Value name="5">
<Value>type</Value>
</Value>
<Value name="6">
<Value>href</Value>
</Value>
<Value name="7">
<Value>role</Value>
</Value>
</Data>
<State>ReferenceState</State>
<StreamLocation>^EnsLib.ebXML.sch2611.ReferenceS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
