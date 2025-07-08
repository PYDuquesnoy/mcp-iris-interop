/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Target as specified in various WS-Trust 1.3 properties.
/// Only one of the properties in this class should be specified.  A choice is represented by this class.
Class %SOAP.WST.Target Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wst";

Property token As %SOAP.WST.AbstractToken(XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property SecurityTokenReference As %SOAP.Security.SecurityTokenReference(REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd", XMLREF = 1);

Property EndpointReference As %SOAP.Addressing.EndpointReference(REFNAMESPACE = "http://www.w3.org/2005/08/addressing", XMLREF = 1);

}
