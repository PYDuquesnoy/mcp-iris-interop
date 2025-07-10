/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.KeyValueType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "KeyValueType";

Parameter XMLSEQUENCE = 0;

Property DSAKeyValue As EnsLib.UDDI.dsig.DSAKeyValueType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "DSAKeyValue", XMLREF = 1);

Property RSAKeyValue As EnsLib.UDDI.dsig.RSAKeyValueType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "RSAKeyValue", XMLREF = 1);

Property any As %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

}
