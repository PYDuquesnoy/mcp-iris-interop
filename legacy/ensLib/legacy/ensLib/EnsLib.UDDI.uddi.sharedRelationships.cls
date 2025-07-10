/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.sharedRelationships Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.direction, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "sharedRelationships";

Parameter XMLSEQUENCE = 1;

Property keyedReference As list Of EnsLib.UDDI.uddi.keyedReference(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "keyedReference", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property publisherAssertion As list Of EnsLib.UDDI.uddi.publisherAssertion(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "publisherAssertion", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property direction As EnsLib.UDDI.uddi.direction(XMLNAME = "direction", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
