/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Offer is used for the Offer child of the CreateSequence request body in WS-ReliableMessaging 1.2.
Class %SOAP.RM.Offer Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsrm";

Parameter XMLIGNOREINVALIDTAG = 1;

Property Identifier As %xsd.anyURI;

Property Endpoint As %SOAP.RM.EndpointReference(REFNAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702", XMLREF = 1);

Property Expires As %String;

Property IncompleteSequenceBehavior As %SOAP.RM.IncompleteSequenceBehaviorType;

}
