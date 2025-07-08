/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Signature Transforms element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.Transform Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property InclusiveNamespaces As %XML.Security.InclusiveNamespaces(REFNAMESPACE = "http://www.w3.org/2001/10/xml-exc-c14n#", XMLREF = 1);

Property TransformationParameters As %SOAP.Security.TransformationParameters(REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd", XMLREF = 1);

Property Algorithm As %xsd.anyURI(XMLPROJECTION = "attribute") [ Required ];

}
