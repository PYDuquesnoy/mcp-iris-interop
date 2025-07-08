/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Authentication Context
Class %SAML.AuthnContext Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property AuthnContextClassRef As %xsd.anyURI(XMLREF = 1);

Property AuthnContextDecl As %XML.Adaptor(XMLCHOICELIST = "%SAML.AuthnContextDecl,%SAML.AuthnContextDeclRef", XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property AuthenticatingAuthority As list Of %xsd.anyURI(XMLPROJECTION = "element", XMLREF = 1);

}
