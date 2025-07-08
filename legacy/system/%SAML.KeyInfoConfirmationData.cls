/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Data for SubjectConfirmation wit hKeyInfo
Class %SAML.KeyInfoConfirmationData Extends %SAML.SubjectConfirmationData [ System = 4 ]
{

Parameter XMLTYPE = "KeyInfoConfirmationDataType";

Property KeyInfo As list Of %XML.Security.KeyInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLPROJECTION = "element", XMLREF = 1);

///  Override the content field and make it invisible.
Property content As %XML.String(MAXLEN = "", XMLPROJECTION = "none") [ Internal ];

}
