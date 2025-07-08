/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// List of Conditions
Class %SAML.Conditions Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property Condition As list Of %SAML.Condition(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property NotBefore As %xsd.dateTime(XMLPROJECTION = "attribute");

Property NotOnOrAfter As %xsd.dateTime(XMLPROJECTION = "attribute");

}
