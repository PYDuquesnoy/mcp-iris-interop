/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.serviceInfo Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.businessKey, EnsLib.UDDI.uddi.serviceKey), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "serviceInfo";

Parameter XMLSEQUENCE = 1;

Property name As list Of EnsLib.UDDI.uddi.name(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "name", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property serviceKey As EnsLib.UDDI.uddi.serviceKey(XMLNAME = "serviceKey", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property businessKey As EnsLib.UDDI.uddi.businessKey(XMLNAME = "businessKey", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
