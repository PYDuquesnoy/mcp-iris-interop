/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.TransformType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "TransformType";

Parameter XMLSEQUENCE = 0;

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property XPath As list Of %String(MAXLEN = "", XMLNAME = "XPath", XMLPROJECTION = "ELEMENT");

Property Algorithm As %String(MAXLEN = "", XMLNAME = "Algorithm", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
