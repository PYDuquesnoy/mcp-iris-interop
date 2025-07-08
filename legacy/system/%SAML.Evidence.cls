/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Evidence for AuthzDecisionStatement
Class %SAML.Evidence Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property Evidence As list Of %SAML.AssertionReference(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");

}
