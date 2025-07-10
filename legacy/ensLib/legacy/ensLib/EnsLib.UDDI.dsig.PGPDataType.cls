/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.w3.org/TR/xmldsig-core/xmldsig-core-schema.xsd
Class EnsLib.UDDI.dsig.PGPDataType Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = , Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter XMLNAME = "PGPDataType";

Parameter XMLSEQUENCE = 0;

Property PGPKeyID As %xsd.base64Binary(XMLNAME = "PGPKeyID");

Property PGPKeyPacket As %xsd.base64Binary(XMLNAME = "PGPKeyPacket");

Property any As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY") [ SqlFieldName = _any ];

/// ERROR: Duplicate Property name in Schema. 
Property PGPKeyPacket1 As %xsd.base64Binary(XMLNAME = "PGPKeyPacket");

/// ERROR: Duplicate Property name in Schema. 
Property any1 As list Of %XML.String(XMLNAME = "any", XMLPROJECTION = "ANY");

}
