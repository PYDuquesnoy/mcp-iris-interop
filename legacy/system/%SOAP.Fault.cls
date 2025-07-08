/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// class to represent a SOAP fault. 
/// See schema at "http://schemas.xmlsoap.org/soap/envelope/" for details.
Class %SOAP.Fault Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, Not ProcedureBlock, System = 3 ]
{

Parameter XMLIGNOREINVALIDTAG = 1;

Parameter XMLIGNORENULL = 1;

/// The SOAP fault code as defined in the SOAP definition.
/// Valid values are defined in %soap.inc:  
/// $$$FAULTVersionMismatch, $$$FAULTMustUnderstand,
/// $$$FAULTClient and $$$FAULTServer.
Property faultcode As %String(MAXLEN = "");

Property faultstring As %String(MAXLEN = "");

Property faultactor As %String(MAXLEN = "");

/// Optional prefix definition attribute to be added to Fault element.
/// Usually of the form xmlns:prefix="namespace"
Property faultPrefixDefinition As %String(MAXLEN = "", XMLPROJECTION = "NONE");

/// XML element that gives error details.
/// The contents of detail will not be escaped.
Property detail As %XML.String(MAXLEN = "");

/// If true follow the WS-Security rules for converting SOAP 1.1 fault to SOAP 1.2 fault.
/// The faultcode becomes the subCode and the faultcode becomes env:Sender
Property WSSecurityFault As %Boolean [ Internal ];

/// Return this SOAP fault as a string.
Method AsString() As %String
{
 Quit "faultcode="_i%faultcode_$c(13,10)_
 "faultstring="_i%faultstring_$c(13,10)_
 "faultactor="_i%faultactor_$c(13,10)_
 "detail="_i%detail
}

}
