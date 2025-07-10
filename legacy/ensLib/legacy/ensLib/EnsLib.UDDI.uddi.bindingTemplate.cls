/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.bindingTemplate Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.bindingKey, EnsLib.UDDI.uddi.serviceKey), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "bindingTemplate";

Parameter XMLSEQUENCE = 0;

Property description As list Of EnsLib.UDDI.uddi.description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property accessPoint As EnsLib.UDDI.uddi.accessPoint(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "accessPoint", XMLREF = 1);

Property hostingRedirector As EnsLib.UDDI.uddi.hostingRedirector(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "hostingRedirector", XMLREF = 1);

Property tModelInstanceDetails As EnsLib.UDDI.uddi.tModelInstanceDetails(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "tModelInstanceDetails", XMLREF = 1);

Property categoryBag As EnsLib.UDDI.uddi.categoryBag(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "categoryBag", XMLREF = 1);

Property Signature As list Of EnsLib.UDDI.dsig.SignatureType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Signature", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property bindingKey As EnsLib.UDDI.uddi.bindingKey(XMLNAME = "bindingKey", XMLPROJECTION = "ATTRIBUTE");

Property serviceKey As EnsLib.UDDI.uddi.serviceKey(XMLNAME = "serviceKey", XMLPROJECTION = "ATTRIBUTE");

}
