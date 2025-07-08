/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// ProxyRestriction condition
Class %SAML.ProxyRestriction Extends %SAML.Condition [ System = 4 ]
{

Property Audience As list Of %xsd.anyURI(XMLPROJECTION = "element", XMLREF = 1);

Property Count As %xsd.nonNegativeInteger(XMLPROJECTION = "attribute");

}
