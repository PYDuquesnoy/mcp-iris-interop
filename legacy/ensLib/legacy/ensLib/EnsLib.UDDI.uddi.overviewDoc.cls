/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.overviewDoc Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "overviewDoc";

Parameter XMLSEQUENCE = 0;

Property description As list Of EnsLib.UDDI.uddi.description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property overviewURL As EnsLib.UDDI.uddi.overviewURL(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "overviewURL", XMLREF = 1);

/// ERROR: Duplicate Property name in Schema. 
Property overviewURL1 As EnsLib.UDDI.uddi.overviewURL(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "overviewURL", XMLREF = 1);

}
