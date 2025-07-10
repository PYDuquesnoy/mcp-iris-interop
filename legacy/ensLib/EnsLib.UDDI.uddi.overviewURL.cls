/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.overviewURL Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = (EnsLib.UDDI.uddi.useType, EnsLib.UDDI.uddi.validationTypeAnyURI4096), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "overviewURL";

Parameter XMLSEQUENCE = 1;

Property content As EnsLib.UDDI.uddi.validationTypeAnyURI4096(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property useType As EnsLib.UDDI.uddi.useType(XMLNAME = "useType", XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="overviewURLState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>useType</Value>
</Value>
</Data>
<State>overviewURLState</State>
<StreamLocation>^EnsLib.UDDI.uddi.overviewURLS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
