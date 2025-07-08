/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// WS-Addressing MessageID header.
Class %SOAP.Addressing.MessageID Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Property MessageID As %xsd.anyURI(XMLPROJECTION = "content");

}
