/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.publisherAssertions Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "publisherAssertions";

Parameter XMLSEQUENCE = 1;

Property publisherAssertion As list Of EnsLib.UDDI.uddi.publisherAssertion(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "publisherAssertion", XMLPROJECTION = "ELEMENT", XMLREF = 1);

}
