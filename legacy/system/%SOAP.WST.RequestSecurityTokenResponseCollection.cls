/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// RequestSecurityTokenResponseCollection as used for response body for issuing token in WS-Trust 1.3.
Class %SOAP.WST.RequestSecurityTokenResponseCollection Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wst";

Property RequestSecurityTokenResponse As list Of %SOAP.WST.RequestSecurityTokenResponse(XMLPROJECTION = "element");

}
