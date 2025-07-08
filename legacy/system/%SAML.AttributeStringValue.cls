/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Subclass of %SAML.AttributeValue which allows xsi:type attriibute on input
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %SAML.AttributeStringValue Extends %SAML.AttributeValue [ System = 4 ]
{

Parameter NAMESPACE = "http://www.w3.org/2001/XMLSchema";

Parameter XMLTYPE = "string";

/// Dummy property to avoid duplicate xsi:type attribute on export.
Property type As %String(REFNAMESPACE = "http://www.w3.org/2001/XMLSchema-instance", XMLIO = "IN", XMLPROJECTION = "xattribute", XMLREF = 1) [ Internal ];

}
