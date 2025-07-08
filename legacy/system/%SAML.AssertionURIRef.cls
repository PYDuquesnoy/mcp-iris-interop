/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Reference an Assertion using a URI
Class %SAML.AssertionURIRef Extends %SAML.AssertionReference [ System = 4 ]
{

Parameter ELEMENTQUALIFIED = 0;

Property URI As %xsd.anyURI(XMLPROJECTION = "content") [ Required ];

}
