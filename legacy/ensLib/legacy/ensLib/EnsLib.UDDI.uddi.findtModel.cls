/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.findtModel Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.authInfo, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "find_tModel";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "find_tModel";

Property authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authInfo", XMLREF = 1);

Property findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "findQualifiers", XMLREF = 1);

Property name As EnsLib.UDDI.uddi.name(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "name", XMLREF = 1);

Property identifierBag As EnsLib.UDDI.uddi.identifierBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "identifierBag", XMLREF = 1);

Property categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "categoryBag", XMLREF = 1);

Property maxRows As %xsd.int(XMLNAME = "maxRows", XMLPROJECTION = "ATTRIBUTE");

Property listHead As %xsd.int(XMLNAME = "listHead", XMLPROJECTION = "ATTRIBUTE");

}
