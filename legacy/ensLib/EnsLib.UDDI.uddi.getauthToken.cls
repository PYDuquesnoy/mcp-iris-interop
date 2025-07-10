/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.getauthToken Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "get_authToken";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "get_authToken";

Property userID As %String(MAXLEN = "", XMLNAME = "userID", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property cred As %String(MAXLEN = "", XMLNAME = "cred", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
