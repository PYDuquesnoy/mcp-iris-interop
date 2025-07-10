/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.assertionStatusItem Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.businessKey, EnsLib.UDDI.uddi.completionStatus), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "assertionStatusItem";

Parameter XMLSEQUENCE = 1;

Property fromKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "fromKey", XMLREF = 1) [ Required ];

Property toKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "toKey", XMLREF = 1) [ Required ];

Property keyedReference As EnsLib.UDDI.uddi.keyedReference(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "keyedReference", XMLREF = 1) [ Required ];

Property keysOwned As EnsLib.UDDI.uddi.keysOwned(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "keysOwned", XMLREF = 1) [ Required ];

Property completionStatus As EnsLib.UDDI.uddi.completionStatus(XMLNAME = "completionStatus", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
