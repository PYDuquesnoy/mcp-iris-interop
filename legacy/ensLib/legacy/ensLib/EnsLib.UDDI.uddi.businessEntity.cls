/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.businessEntity Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.businessKey, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "businessEntity";

Parameter XMLSEQUENCE = 1;

Property discoveryURLs As EnsLib.UDDI.uddi.discoveryURLs(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "discoveryURLs", XMLREF = 1);

Property name As list Of EnsLib.UDDI.uddi.name(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "name", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property description As list Of EnsLib.UDDI.uddi.description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property contacts As EnsLib.UDDI.uddi.contacts(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "contacts", XMLREF = 1);

Property businessServices As EnsLib.UDDI.uddi.businessServices(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "businessServices", XMLREF = 1);

Property identifierBag As EnsLib.UDDI.uddi.identifierBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "identifierBag", XMLREF = 1);

Property categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "categoryBag", XMLREF = 1);

Property Signature As list Of EnsLib.UDDI.dsig.SignatureType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Signature", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property businessKey As EnsLib.UDDI.uddi.businessKey(XMLNAME = "businessKey", XMLPROJECTION = "ATTRIBUTE");

}
