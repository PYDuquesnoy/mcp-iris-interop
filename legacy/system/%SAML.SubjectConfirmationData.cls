/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Data for SubjectConfirmation
Class %SAML.SubjectConfirmationData Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter XMLTYPE = "SubjectConfirmationDataType";

Parameter ELEMENTQUALIFIED = 0;

/// Normal case allow any XML content.
Property content As %XML.String(MAXLEN = "", XMLPROJECTION = "content");

/// As a special case allow a list of KeyInfo elements as need for WS-Security.
Property KeyInfo As list Of %XML.Security.KeyInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLPROJECTION = "element", XMLREF = 1);

Property Address As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property InResponseTo As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property NotBefore As %xsd.dateTime(XMLPROJECTION = "attribute");

Property NotOnOrAfter As %xsd.dateTime(XMLPROJECTION = "attribute");

Property Recipient As %xsd.anyURI(XMLPROJECTION = "attribute");

}
