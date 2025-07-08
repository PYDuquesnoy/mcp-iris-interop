/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// WS-Addressing RelatesTo header.
Class %SOAP.Addressing.RelatesTo Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Property RelatesTo As %xsd.anyURI(XMLPROJECTION = "content");

/// Default RelationshipType is "http://www.w3.org/2005/08/addressing/reply"
Property RelationshipType As %xsd.anyURI(XMLPROJECTION = "attribute");

/// Predefined Reply value for RelationshipType attribute of RelatesTo
ClassMethod ReplyType() As %String [ CodeMode = expression ]
{
"http://www.w3.org/2005/08/addressing/reply"
}

/// Define RelatesTo with specified address and default RelationshipType.
Method %OnNew(IRI As %String) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set i%RelatesTo=$get(IRI)
	Quit $$$OK
}

}
