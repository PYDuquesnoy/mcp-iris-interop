/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.keyedReference Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = (EnsLib.UDDI.uddi.keyName, EnsLib.UDDI.uddi.keyValue, EnsLib.UDDI.uddi.tModelKey), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "keyedReference";

Parameter XMLSEQUENCE = 1;

Property tModelKey As EnsLib.UDDI.uddi.tModelKey(XMLNAME = "tModelKey", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property keyName As EnsLib.UDDI.uddi.keyName(XMLNAME = "keyName", XMLPROJECTION = "ATTRIBUTE");

Property keyValue As EnsLib.UDDI.uddi.keyValue(XMLNAME = "keyValue", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
