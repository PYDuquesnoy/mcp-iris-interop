/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.errInfo Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "errInfo";

Parameter XMLSEQUENCE = 1;

Property content As %String(MAXLEN = "", XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property errCode As %String(MAXLEN = "", XMLNAME = "errCode", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Storage Default
{
<Data name="errInfoState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>errCode</Value>
</Value>
</Data>
<State>errInfoState</State>
<StreamLocation>^EnsLib.UDDI.uddi.errInfoS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
