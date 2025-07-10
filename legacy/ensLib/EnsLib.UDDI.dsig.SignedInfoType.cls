/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.SignedInfoType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "SignedInfoType";

Parameter XMLSEQUENCE = 1;

Property CanonicalizationMethod As EnsLib.UDDI.dsig.CanonicalizationMethodType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "CanonicalizationMethod", XMLREF = 1) [ Required ];

Property SignatureMethod As EnsLib.UDDI.dsig.SignatureMethodType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "SignatureMethod", XMLREF = 1) [ Required ];

Property Reference As list Of EnsLib.UDDI.dsig.ReferenceType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Reference", XMLPROJECTION = "ELEMENT", XMLREF = 1) [ Required ];

Property Id As %String(MAXLEN = "", XMLNAME = "Id", XMLPROJECTION = "ATTRIBUTE");

}
