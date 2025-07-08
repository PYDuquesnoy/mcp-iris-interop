/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Authorization Decision Statement
Class %SAML.AuthzDecisionStatement Extends %SAML.Statement [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property Action As list Of %SAML.Action(XMLPROJECTION = "element", XMLREF = 1);

Property Evidence As %SAML.Evidence(XMLREF = 1);

Property Decision As %String(VALUELIST = ",Permit,Deny,Indeterminate", XMLPROJECTION = "attribute") [ Required ];

Property Resource As %xsd.anyURI(XMLPROJECTION = "attribute") [ Required ];

}
