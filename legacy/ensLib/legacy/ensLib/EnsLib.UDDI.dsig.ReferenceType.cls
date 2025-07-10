/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.ReferenceType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.dsig.DigestValueType, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "ReferenceType";

Parameter XMLSEQUENCE = 1;

Property Transforms As EnsLib.UDDI.dsig.TransformsType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Transforms", XMLREF = 1);

Property DigestMethod As EnsLib.UDDI.dsig.DigestMethodType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "DigestMethod", XMLREF = 1) [ Required ];

Property DigestValue As EnsLib.UDDI.dsig.DigestValueType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "DigestValue", XMLREF = 1) [ Required ];

Property Id As %String(MAXLEN = "", XMLNAME = "Id", XMLPROJECTION = "ATTRIBUTE");

Property URI As %String(MAXLEN = "", XMLNAME = "URI", XMLPROJECTION = "ATTRIBUTE");

Property Type As %String(MAXLEN = "", XMLNAME = "Type", XMLPROJECTION = "ATTRIBUTE");

}
