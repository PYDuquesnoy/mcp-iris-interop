/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.address Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.sortCode, EnsLib.UDDI.uddi.tModelKey, EnsLib.UDDI.uddi.useType), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "address";

Parameter XMLSEQUENCE = 1;

Property addressLine As list Of EnsLib.UDDI.uddi.addressLine(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "addressLine", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property lang As %String(MAXLEN = "", XMLNAME = "lang", XMLPROJECTION = "XMLATTRIBUTE");

Property useType As EnsLib.UDDI.uddi.useType(XMLNAME = "useType", XMLPROJECTION = "ATTRIBUTE");

Property sortCode As EnsLib.UDDI.uddi.sortCode(XMLNAME = "sortCode", XMLPROJECTION = "ATTRIBUTE");

Property tModelKey As EnsLib.UDDI.uddi.tModelKey(XMLNAME = "tModelKey", XMLPROJECTION = "ATTRIBUTE");

}
