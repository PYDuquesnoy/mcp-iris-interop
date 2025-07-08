/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// WS-Addressing Action header.
Class %SOAP.Addressing.Action Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Property Action As %xsd.anyURI(XMLPROJECTION = "content");

}
