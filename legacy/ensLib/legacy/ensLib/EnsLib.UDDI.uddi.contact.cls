/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.contact Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.uddi.useType, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "contact";

Parameter XMLSEQUENCE = 1;

Property description As list Of EnsLib.UDDI.uddi.description(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "description", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property personName As list Of EnsLib.UDDI.uddi.personName(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "personName", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property phone As list Of EnsLib.UDDI.uddi.phone(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "phone", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property email As list Of EnsLib.UDDI.uddi.email(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "email", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property address As list Of EnsLib.UDDI.uddi.address(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "address", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property useType As EnsLib.UDDI.uddi.useType(XMLNAME = "useType", XMLPROJECTION = "ATTRIBUTE");

}
