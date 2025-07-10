/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.assertionStatusReport Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "assertionStatusReport";

Parameter XMLSEQUENCE = 1;

Property assertionStatusItem As list Of EnsLib.UDDI.uddi.assertionStatusItem(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "assertionStatusItem", XMLPROJECTION = "ELEMENT", XMLREF = 1);

}
