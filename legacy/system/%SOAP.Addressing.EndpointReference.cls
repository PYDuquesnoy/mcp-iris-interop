/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SOAP.Addressing.EndpointReference represents a WS-Addressing Endpoint Reference.
Class %SOAP.Addressing.EndpointReference Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

/// Ignore extra elements.
Parameter XMLIGNOREINVALIDTAG = 1;

Property Address As %xsd.anyURI [ Required ];

Property ReferenceParameters As %XML.String(MAXLEN = "");

Property Metadata As %XML.String(MAXLEN = "");

/// Define EPR with specified address.
Method %OnNew(address As %String) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set i%Address=$get(address)
	Quit $$$OK
}

/// Get an EPR for anonymous reference.  This is the ddefault for ReplyTo.
ClassMethod GetAnonymousEPR(namespace As %String) As %SOAP.Addressing.EndpointReference [ CodeMode = expression ]
{
..%New(..Anonymous(.namespace))
}

/// Some endpoints cannot be located with a meaningful IRI; this URI is used
/// to allow such endpoints to send and receive messages. The precise meaning 
/// of this URI is defined by the binding of Addressing to a specific protocol
/// and/or the context in which the EPR is used.
/// This is the value for the ReplyTo header using request-response semantics.
ClassMethod Anonymous(namespace As %String) As %String [ CodeMode = expression ]
{
$select($get(namespace)="":"http://www.w3.org/2005/08/addressing",1:namespace)_"/anonymous"
}

/// Messages sent to EPRs whose [address] is this value MUST be discarded (i.e. not sent).
/// This URI is typically used in EPRs that designate a reply or fault endpoint
/// to indicate that no reply or fault message should be sent.
ClassMethod None() As %String [ CodeMode = expression ]
{
"http://www.w3.org/2005/08/addressing/none"
}

}
