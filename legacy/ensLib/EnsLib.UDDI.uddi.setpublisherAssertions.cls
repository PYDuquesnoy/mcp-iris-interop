/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.setpublisherAssertions Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = EnsLib.UDDI.uddi.authInfo, Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter XMLNAME = "set_publisherAssertions";

Parameter XMLSEQUENCE = 1;

Parameter XMLTYPE = "set_publisherAssertions";

Property authInfo As EnsLib.UDDI.uddi.authInfo(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "authInfo", XMLREF = 1);

Property publisherAssertion As list Of EnsLib.UDDI.uddi.publisherAssertion(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "urn:uddi-org:api_v3", XMLNAME = "publisherAssertion", XMLPROJECTION = "ELEMENT", XMLREF = 1);

}
