/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Signature InclusiveNamespaces element to be used to modify exclusive canonicalization Transform element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.InclusiveNamespaces Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2001/10/xml-exc-c14n#";

Parameter ELEMENTQUALIFIED = 1;

Property PrefixList As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ Required ];

}
