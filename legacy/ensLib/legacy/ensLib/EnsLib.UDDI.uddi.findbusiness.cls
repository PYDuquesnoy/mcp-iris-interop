/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.findbusiness Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = EnsLib.UDDI.uddi.authInfo, Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "find_business";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "find_business";

Property authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authInfo", XMLREF = 1);

Property findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "findQualifiers", XMLREF = 1);

Property name As list Of EnsLib.UDDI.uddi.name(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "name", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property identifierBag As EnsLib.UDDI.uddi.identifierBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "identifierBag", XMLREF = 1);

Property categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "categoryBag", XMLREF = 1);

Property tModelBag As EnsLib.UDDI.uddi.tModelBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "tModelBag", XMLREF = 1);

Property findtModel As EnsLib.UDDI.uddi.findtModel(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "find_tModel", XMLREF = 1);

Property discoveryURLs As EnsLib.UDDI.uddi.discoveryURLs(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "discoveryURLs", XMLREF = 1);

Property findrelatedBusinesses As EnsLib.UDDI.uddi.findrelatedBusinesses(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "find_relatedBusinesses", XMLREF = 1);

Property maxRows As %xsd.int(XMLNAME = "maxRows", XMLPROJECTION = "ATTRIBUTE");

Property listHead As %xsd.int(XMLNAME = "listHead", XMLPROJECTION = "ATTRIBUTE");

}
