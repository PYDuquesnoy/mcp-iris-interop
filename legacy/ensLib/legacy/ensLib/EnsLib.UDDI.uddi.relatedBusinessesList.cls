/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.relatedBusinessesList Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = (EnsLib.UDDI.uddi.businessKey, EnsLib.UDDI.uddi.truncated), Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "relatedBusinessesList";

Parameter XMLSEQUENCE = 1;

Property listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "listDescription", XMLREF = 1);

Property businessKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "businessKey", XMLREF = 1) [ Required ];

Property relatedBusinessInfos As EnsLib.UDDI.uddi.relatedBusinessInfos(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "relatedBusinessInfos", XMLREF = 1);

Property truncated As EnsLib.UDDI.uddi.truncated(XMLNAME = "truncated", XMLPROJECTION = "ATTRIBUTE");

}
