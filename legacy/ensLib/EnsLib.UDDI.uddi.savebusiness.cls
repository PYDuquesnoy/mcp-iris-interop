/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.savebusiness Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = EnsLib.UDDI.uddi.authInfo, Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "save_business";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "save_business";

Property authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authInfo", XMLREF = 1);

Property businessEntity As list Of EnsLib.UDDI.uddi.businessEntity(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "businessEntity", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

}
