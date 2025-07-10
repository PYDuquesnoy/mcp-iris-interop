/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.findrelatedBusinesses Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.authInfo, EnsLib.UDDI.uddi.businessKey), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "find_relatedBusinesses";

Parameter XMLSEQUENCE = 0;

Parameter XMLTYPE = "find_relatedBusinesses";

Property authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authInfo", XMLREF = 1);

Property findQualifiers As EnsLib.UDDI.uddi.findQualifiers(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "findQualifiers", XMLREF = 1);

Property businessKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "businessKey", XMLREF = 1);

Property fromKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "fromKey", XMLREF = 1);

Property toKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "toKey", XMLREF = 1);

Property keyedReference As EnsLib.UDDI.uddi.keyedReference(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "keyedReference", XMLREF = 1);

Property maxRows As %xsd.int(XMLNAME = "maxRows", XMLPROJECTION = "ATTRIBUTE");

Property listHead As %xsd.int(XMLNAME = "listHead", XMLPROJECTION = "ATTRIBUTE");

}
