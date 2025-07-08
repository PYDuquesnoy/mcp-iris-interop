/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Signature Algorithm element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.Algorithm Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property Algorithm As %xsd.anyURI(XMLPROJECTION = "attribute") [ Required ];

Storage Default
{
<Data name="AlgorithmState">
<Value name="1">
<Value>Algorithm</Value>
</Value>
</Data>
<State>AlgorithmState</State>
<StreamLocation>^%XML.Security.AlgorithmS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
