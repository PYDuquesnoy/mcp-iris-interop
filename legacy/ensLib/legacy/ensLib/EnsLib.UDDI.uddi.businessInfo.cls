/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.businessInfo Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.businessKey, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "businessInfo";

Parameter XMLSEQUENCE = 1;

Property name As list Of EnsLib.UDDI.uddi.name(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "name", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property description As list Of EnsLib.UDDI.uddi.description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property serviceInfos As EnsLib.UDDI.uddi.serviceInfos(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "serviceInfos", XMLREF = 1);

Property businessKey As EnsLib.UDDI.uddi.businessKey(XMLNAME = "businessKey", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
