/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SOAP.Fault12.Code Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter NAMESPACE = "http://www.w3.org/2003/05/soap-envelope";

Parameter XMLIGNORENULL = 1;

/// The SOAP fault code as defined in the SOAP definition.
/// For a top level code this must be
/// $$$FAULTVersionMismatch, $$$FAULTMustUnderstand, $$$FAULTDataEncodingUnknown,
/// $$$FAULTSender or $$$FAULTReceiver.<br>
/// For a subcode this must a qname.
Property Value As %String [ Required ];

/// An optional subcode
Property Subcode As %SOAP.Fault12.Code;

}
