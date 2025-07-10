/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.businessList Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = EnsLib.UDDI.uddi.truncated, Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "businessList";

Parameter XMLSEQUENCE = 1;

Property listDescription As EnsLib.UDDI.uddi.listDescription(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "listDescription", XMLREF = 1);

Property businessInfos As EnsLib.UDDI.uddi.businessInfos(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "businessInfos", XMLREF = 1);

Property truncated As EnsLib.UDDI.uddi.truncated(XMLNAME = "truncated", XMLPROJECTION = "ATTRIBUTE");

}
