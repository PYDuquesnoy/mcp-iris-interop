/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.tModel Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.deleted, EnsLib.UDDI.uddi.tModelKey), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "tModel";

Parameter XMLSEQUENCE = 1;

Property name As EnsLib.UDDI.uddi.name(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "name", XMLREF = 1) [ Required ];

Property description As list Of EnsLib.UDDI.uddi.description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property overviewDoc As list Of EnsLib.UDDI.uddi.overviewDoc(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "overviewDoc", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property identifierBag As EnsLib.UDDI.uddi.identifierBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "identifierBag", XMLREF = 1);

Property categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "categoryBag", XMLREF = 1);

Property Signature As list Of EnsLib.UDDI.dsig.SignatureType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Signature", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property tModelKey As EnsLib.UDDI.uddi.tModelKey(XMLNAME = "tModelKey", XMLPROJECTION = "ATTRIBUTE");

Property deleted As EnsLib.UDDI.uddi.deleted(XMLNAME = "deleted", XMLPROJECTION = "ATTRIBUTE");

}
