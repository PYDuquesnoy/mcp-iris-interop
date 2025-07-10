/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.getbindingDetail Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = (EnsLib.UDDI.uddi.authInfo, EnsLib.UDDI.uddi.bindingKey), Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "get_bindingDetail";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "get_bindingDetail";

Property authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authInfo", XMLREF = 1);

Property bindingKey As list Of EnsLib.UDDI.uddi.bindingKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "bindingKey", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

}
