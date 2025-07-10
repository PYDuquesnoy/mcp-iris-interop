/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.DSAKeyValueType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = EnsLib.UDDI.dsig.CryptoBinary, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "DSAKeyValueType";

Parameter XMLSEQUENCE = 1;

Property P As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "P") [ Required ];

Property Q As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "Q") [ Required ];

Property G As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "G");

Property Y As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "Y") [ Required ];

Property J As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "J");

Property Seed As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "Seed") [ Required ];

Property PgenCounter As EnsLib.UDDI.dsig.CryptoBinary(XMLNAME = "PgenCounter") [ Required ];

}
