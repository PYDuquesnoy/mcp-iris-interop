/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.SignatureValueType Extends (%SerialObject, %XML.Adaptor) [ ClassType = serial, CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "SignatureValueType";

Parameter XMLSEQUENCE = 1;

Property content As %xsd.base64Binary(XMLNAME = "content", XMLPROJECTION = "CONTENT");

Property Id As %String(MAXLEN = "", XMLNAME = "Id", XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="SignatureValueTypeState">
<Value name="1">
<Value>content</Value>
</Value>
<Value name="2">
<Value>Id</Value>
</Value>
</Data>
<State>SignatureValueTypeState</State>
<StreamLocation>^EnsLib.UDD102D.SignatureVaB06AS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
