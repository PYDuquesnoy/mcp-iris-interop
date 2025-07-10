/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.X509DataType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "X509DataType";

Parameter XMLSEQUENCE = 0;

Property X509IssuerSerial As list Of EnsLib.UDDI.dsig.X509IssuerSerialType(XMLNAME = "X509IssuerSerial", XMLPROJECTION = "ELEMENT");

Property X509SKI As list Of %xsd.base64Binary(XMLNAME = "X509SKI", XMLPROJECTION = "ELEMENT");

Property X509SubjectName As list Of %String(MAXLEN = "", XMLNAME = "X509SubjectName", XMLPROJECTION = "ELEMENT");

Property X509Certificate As list Of %xsd.base64Binary(XMLNAME = "X509Certificate", XMLPROJECTION = "ELEMENT");

Property X509CRL As list Of %xsd.base64Binary(XMLNAME = "X509CRL", XMLPROJECTION = "ELEMENT");

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

}
