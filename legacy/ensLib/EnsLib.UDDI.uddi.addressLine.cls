/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.addressLine Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = (EnsLib.UDDI.uddi.keyName, EnsLib.UDDI.uddi.keyValue, EnsLib.UDDI.uddi.validationTypeString80), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "addressLine";

Parameter XMLSEQUENCE = 1;

Property content As EnsLib.UDDI.uddi.validationTypeString80(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property keyName As EnsLib.UDDI.uddi.keyName(XMLNAME = "keyName", XMLPROJECTION = "ATTRIBUTE");

Property keyValue As EnsLib.UDDI.uddi.keyValue(XMLNAME = "keyValue", XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="addressLineState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>keyName</Value>
</Value>
<Value name="3">
<Value>keyValue</Value>
</Value>
</Data>
<State>addressLineState</State>
<StreamLocation>^EnsLib.UDDI.uddi.addressLineS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
