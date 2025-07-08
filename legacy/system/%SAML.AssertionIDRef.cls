/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Reference an Assertion using an ID
Class %SAML.AssertionIDRef Extends %SAML.AssertionReference [ System = 4 ]
{

Parameter ELEMENTQUALIFIED = 0;

Property ID As %String(CONTENT = "escape", MAXLEN = "", XMLPROJECTION = "content") [ Required ];

}
