/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// AcknowledgementRange child of the SequenceAcknowledgement SOAP header in WS-ReliableMessaging 1.2.
Class %SOAP.RM.AcknowledgementRange Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsrm";

Property Lower As %SOAP.RM.MessageNumberType(XMLPROJECTION = "attribute");

Property Upper As %SOAP.RM.MessageNumberType(XMLPROJECTION = "attribute");

}
