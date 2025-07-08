/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Authentication Statement
Class %SAML.AuthnStatement Extends %SAML.Statement [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property SubjectLocality As %SAML.SubjectLocality(XMLREF = 1);

Property AuthnContext As %SAML.AuthnContext(XMLREF = 1) [ Required ];

Property AuthnInstant As %xsd.dateTime(XMLPROJECTION = "attribute") [ Required ];

Property SessionIndex As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property SessionNotOnOrAfter As %xsd.dateTime(XMLPROJECTION = "attribute");

}
