/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// class to represent a SOAP 1.2 fault. 
/// %SOAP.Fault12 should only be used if SOAPVERSION is set to "1.2" or
/// that at least SoapVersion="1.2" meaning that this web service request is
/// SOAP 1.2 is format.  
/// The %SOAP.Fault class will work with SOAP 1.1 or SOAP 1.2.  However, the
/// fault functionality is limited to that of SOAP 1.1 fault.
Class %SOAP.Fault12 Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLTYPE = "Fault";

Parameter NAMESPACE = "http://www.w3.org/2003/05/soap-envelope";

/// The SOAP fault code as defined in the SOAP definition.
Property Code As %SOAP.Fault12.Code [ Required ];

/// Human readable message
Property Reason As list Of %SOAP.Fault12.Text(XMLITEMNAME = "Text") [ Required ];

/// Node that generated the fault.  Optional for the destination node.
Property Node As %String(MAXLEN = "");

/// Role that the node was operating in.
Property Role As %String(MAXLEN = "");

/// XML element that gives error details.
/// The contents of detail will not be escaped.
Property Detail As %XML.String(MAXLEN = "");

/// Optional prefix definition attribute to be added to Fault element.
/// Usually of the form xmlns:prefix="namespace"
Property faultPrefixDefinition As %String(MAXLEN = "", XMLPROJECTION = "NONE");

/// Return this SOAP fault as a string.
Method AsString() As %String
{
	Do ..XMLExportToString(.str)
	Quit str
}

}
