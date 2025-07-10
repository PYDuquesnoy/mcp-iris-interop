/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.publisherAssertion Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.businessKey, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "publisherAssertion";

Parameter XMLSEQUENCE = 1;

Property fromKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "fromKey", XMLREF = 1) [ Required ];

Property toKey As EnsLib.UDDI.uddi.businessKey(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "toKey", XMLREF = 1) [ Required ];

Property keyedReference As EnsLib.UDDI.uddi.keyedReference(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "keyedReference", XMLREF = 1) [ Required ];

Property Signature As list Of EnsLib.UDDI.dsig.SignatureType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Signature", XMLPROJECTION = "ELEMENT", XMLREF = 1);

}
