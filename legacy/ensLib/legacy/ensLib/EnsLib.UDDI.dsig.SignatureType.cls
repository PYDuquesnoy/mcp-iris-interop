/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.SignatureType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "SignatureType";

Parameter XMLSEQUENCE = 1;

Property SignedInfo As EnsLib.UDDI.dsig.SignedInfoType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "SignedInfo", XMLREF = 1) [ Required ];

Property SignatureValue As EnsLib.UDDI.dsig.SignatureValueType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "SignatureValue", XMLREF = 1) [ Required ];

Property KeyInfo As EnsLib.UDDI.dsig.KeyInfoType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "KeyInfo", XMLREF = 1);

Property Object As list Of EnsLib.UDDI.dsig.ObjectType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Object", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property Id As %String(MAXLEN = "", XMLNAME = "Id", XMLPROJECTION = "ATTRIBUTE");

}
