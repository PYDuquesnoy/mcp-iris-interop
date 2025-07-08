/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created element of UsernameToken for SOAP Security header.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.Security.Created Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd";

Property content As %String(CONTENT = "escape", MAXLEN = "", XMLPROJECTION = "content");

Storage Default
{
<Data name="CreatedState">
<Value name="1">
<Value>content</Value>
</Value>
</Data>
<State>CreatedState</State>
<StreamLocation>^%SOAP.Security.CreatedS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
