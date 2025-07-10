/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.personName Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = EnsLib.UDDI.uddi.validationTypeString255, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "personName";

Parameter XMLSEQUENCE = 1;

Property content As EnsLib.UDDI.uddi.validationTypeString255(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property lang As %String(MAXLEN = "", XMLNAME = "lang", XMLPROJECTION = "XMLATTRIBUTE");

Storage Default
{
<Data name="personNameState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>lang</Value>
</Value>
</Data>
<State>personNameState</State>
<StreamLocation>^EnsLib.UDDI.uddi.personNameS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
