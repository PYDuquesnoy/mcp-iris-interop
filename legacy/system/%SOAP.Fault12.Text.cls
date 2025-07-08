/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SOAP.Fault12.Text Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter NAMESPACE = "http://www.w3.org/2003/05/soap-envelope";

Parameter XMLIGNORENULL = 1;

/// The language code.
Property lang As %String(XMLPROJECTION = "xmlattribute") [ Required ];

/// The reason text
Property Text As %String(MAXLEN = "", XMLPROJECTION = "CONTENT") [ Required ];

}
