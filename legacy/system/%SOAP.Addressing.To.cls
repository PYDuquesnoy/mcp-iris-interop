/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// WS-Addressing To header.
/// If not present value defaults to "http://www.w3.org/2005/08/addressing/anonymous"
Class %SOAP.Addressing.To Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Property To As %xsd.anyURI(XMLPROJECTION = "content");

}
