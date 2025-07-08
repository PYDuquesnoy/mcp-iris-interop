/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// UsesSequenceSSL SOAP header as defined in WS-ReliableMessaging 1.2.
Class %SOAP.RM.UsesSequenceSSL Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsrm";

Parameter XMLIGNOREINVALIDTAG = 1;

Parameter OUTPUTTYPEATTRIBUTE = 0;

/// Always write with mustUnderstand="true"
Property mustUnderstand As %Integer(XMLPROJECTION = "none") [ InitialExpression = 1 ];

}
