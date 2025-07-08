/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Subject Locality
Class %SAML.SubjectLocality Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property Address As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property DNSName As %String(MAXLEN = "", XMLPROJECTION = "attribute");

}
