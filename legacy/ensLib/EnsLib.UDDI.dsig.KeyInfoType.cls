/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.KeyInfoType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "KeyInfoType";

Parameter XMLSEQUENCE = 0;

Property KeyName As list Of %String(MAXLEN = "", REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "KeyName", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property KeyValue As list Of EnsLib.UDDI.dsig.KeyValueType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "KeyValue", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property RetrievalMethod As list Of EnsLib.UDDI.dsig.RetrievalMethodType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "RetrievalMethod", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property X509Data As list Of EnsLib.UDDI.dsig.X509DataType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "X509Data", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property PGPData As list Of EnsLib.UDDI.dsig.PGPDataType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "PGPData", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property SPKIData As list Of EnsLib.UDDI.dsig.SPKIDataType(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "SPKIData", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property MgmtData As list Of %String(MAXLEN = "", REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "MgmtData", XMLPROJECTION = "ELEMENT", XMLREF = 1);

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

Property Id As %String(MAXLEN = "", XMLNAME = "Id", XMLPROJECTION = "ATTRIBUTE");

}
