/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.RetrievalMethodType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "RetrievalMethodType";

Parameter XMLSEQUENCE = 1;

Property Transforms As EnsLib.UDDI.dsig.TransformsType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Transforms", XMLREF = 1);

Property URI As %String(MAXLEN = "", XMLNAME = "URI", XMLPROJECTION = "ATTRIBUTE");

Property Type As %String(MAXLEN = "", XMLNAME = "Type", XMLPROJECTION = "ATTRIBUTE");

}
