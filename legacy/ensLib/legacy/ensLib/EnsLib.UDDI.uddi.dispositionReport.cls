/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.dispositionReport Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.truncated, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "dispositionReport";

Parameter XMLSEQUENCE = 1;

Property result As list Of EnsLib.UDDI.uddi.result(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "result", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property truncated As EnsLib.UDDI.uddi.truncated(XMLNAME = "truncated", XMLPROJECTION = "ATTRIBUTE");

}
