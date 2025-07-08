/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An Attribute
Class %SAML.Attribute Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

/// Use AttributeValueOverride in order to define exact syntax of the AtributeValue elements.
Property AttributeValueOverride As %XML.String(XMLPROJECTION = "content");

/// Property AttributeValue As list Of %SAML.AttributeValue(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");
Property AttributeValue As list Of %SAML.AttributeValue(REFELEMENTQUALIFIED = 0, REFNAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion", XMLPROJECTION = "element", XMLREF = 1);

Property FriendlyName As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ Required ];

Property Name As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ Required ];

Property NameFormat As %xsd.anyURI(XMLPROJECTION = "attribute");

}
