/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.RSAKeyValueType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.dsig.CryptoBinary, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "RSAKeyValueType";

Parameter XMLSEQUENCE = 1;

Property Modulus As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "Modulus") [ Required ];

Property Exponent As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "Exponent") [ Required ];

}
