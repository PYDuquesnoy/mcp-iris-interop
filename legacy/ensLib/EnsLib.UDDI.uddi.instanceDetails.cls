/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.instanceDetails Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.instanceParms, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "instanceDetails";

Parameter XMLSEQUENCE = 0;

Property description As list Of EnsLib.UDDI.uddi.description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property overviewDoc As list Of EnsLib.UDDI.uddi.overviewDoc(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "overviewDoc", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property instanceParms As EnsLib.UDDI.uddi.instanceParms(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "instanceParms", XMLREF = 1);

/// ERROR: Duplicate Property name in Schema. 
Property instanceParms1 As EnsLib.UDDI.uddi.instanceParms(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "instanceParms", XMLREF = 1);

}
