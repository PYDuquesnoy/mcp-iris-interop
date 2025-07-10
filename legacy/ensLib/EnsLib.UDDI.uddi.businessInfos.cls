/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.businessInfos Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "businessInfos";

Parameter XMLSEQUENCE = 1;

Property businessInfo As list Of EnsLib.UDDI.uddi.businessInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "businessInfo", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

}
