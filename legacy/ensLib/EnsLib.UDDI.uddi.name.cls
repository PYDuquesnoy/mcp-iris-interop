/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.name Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.UDDI.uddi.validationTypeString255, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "name";

Parameter XMLSEQUENCE = 1;

Property content As EnsLib.UDDI.uddi.validationTypeString255(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property lang As %String(MAXLEN = "", XMLNAME = "lang", XMLPROJECTION = "XMLATTRIBUTE");

Storage Default
{
<Data name="nameState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>lang</Value>
</Value>
</Data>
<State>nameState</State>
<StreamLocation>^EnsLib.UDDI.uddi.nameS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
