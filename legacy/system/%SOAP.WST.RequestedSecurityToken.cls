/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// RequestedSecurityToken is a wrapped security token element for WS-Trust 1.3.
Class %SOAP.WST.RequestedSecurityToken Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wst";

Property token As %SOAP.WST.AbstractToken(XMLREF = 1, XMLTYPECONSTRAINT = "choice");

}
