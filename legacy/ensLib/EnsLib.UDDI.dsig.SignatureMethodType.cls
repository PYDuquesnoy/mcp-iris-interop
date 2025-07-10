/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.SignatureMethodType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.dsig.HMACOutputLengthType, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "SignatureMethodType";

Parameter XMLSEQUENCE = 1;

Property HMACOutputLength As EnsLib.UDDI.dsig.HMACOutputLengthType(XMLNAME = "HMACOutputLength");

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property Algorithm As %String(MAXLEN = "", XMLNAME = "Algorithm", XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
