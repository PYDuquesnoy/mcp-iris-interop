/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.findbinding Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = (EnsLib.UDDI.uddi.authInfo, EnsLib.UDDI.uddi.serviceKey), Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "find_binding";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "find_binding";

Property authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authInfo", XMLREF = 1);

Property findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "findQualifiers", XMLREF = 1);

Property tModelBag As EnsLib.UDDI.uddi.tModelBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "tModelBag", XMLREF = 1);

Property findtModel As EnsLib.UDDI.uddi.findtModel(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "find_tModel", XMLREF = 1);

Property categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "categoryBag", XMLREF = 1);

Property maxRows As %xsd.int(XMLNAME = "maxRows", XMLPROJECTION = "ATTRIBUTE");

Property serviceKey As EnsLib.UDDI.uddi.serviceKey(XMLNAME = "serviceKey", XMLPROJECTION = "ATTRIBUTE");

Property listHead As %xsd.int(XMLNAME = "listHead", XMLPROJECTION = "ATTRIBUTE");

}
