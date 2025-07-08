/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Password element of UsernameToken for SOAP Security header.
Class %SOAP.Security.Password Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

Property Type As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property content As %String(CONTENT = "escape", MAXLEN = "", XMLPROJECTION = "content");

Storage Default
{
<Data name="PasswordState">
<Value name="1">
<Value>Type</Value>
</Value>
<Value name="2">
<Value>content</Value>
</Value>
</Data>
<State>PasswordState</State>
<StreamLocation>^%SOAP.Security.PasswordS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
