/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.operationalInfo Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.authorizedName, EnsLib.UDDI.uddi.nodeID, EnsLib.UDDI.uddi.timeInstant, EnsLib.UDDI.uddi.uddiKey), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "operationalInfo";

Parameter XMLSEQUENCE = 1;

Property created As EnsLib.UDDI.uddi.timeInstant(XMLNAME = "created");

Property modified As EnsLib.UDDI.uddi.timeInstant(XMLNAME = "modified");

Property modifiedIncludingChildren As EnsLib.UDDI.uddi.timeInstant(XMLNAME = "modifiedIncludingChildren");

Property nodeID As EnsLib.UDDI.uddi.nodeID(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "nodeID", XMLREF = 1);

Property authorizedName As EnsLib.UDDI.uddi.authorizedName(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authorizedName", XMLREF = 1);

Property entityKey As EnsLib.UDDI.uddi.uddiKey(XMLNAME = "entityKey", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
