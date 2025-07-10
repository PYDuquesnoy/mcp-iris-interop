/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.X509IssuerSerialType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "X509IssuerSerialType";

Parameter XMLSEQUENCE = 1;

Property X509IssuerName As %String(MAXLEN = "", XMLNAME = "X509IssuerName") [ Required ];

Property X509SerialNumber As %Integer(XMLNAME = "X509SerialNumber") [ Required ];

}
