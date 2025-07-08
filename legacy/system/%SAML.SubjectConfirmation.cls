/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A SAML SubjectConfirmation
Class %SAML.SubjectConfirmation Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property NameID As %SAML.BaseID(XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property SubjectConfirmationData As %SAML.SubjectConfirmationData(XMLREF = 1);

Property Method As %xsd.anyURI(XMLPROJECTION = "attribute") [ Required ];

}
