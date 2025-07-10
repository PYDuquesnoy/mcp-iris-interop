/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.result Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.keyType, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "result";

Parameter XMLSEQUENCE = 1;

Property errInfo As EnsLib.UDDI.uddi.errInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "errInfo", XMLREF = 1);

Property keyType As EnsLib.UDDI.uddi.keyType(XMLNAME = "keyType", XMLPROJECTION = "ATTRIBUTE");

Property errno As %xsd.int(XMLNAME = "errno", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
