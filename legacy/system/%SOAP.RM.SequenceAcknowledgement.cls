/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// SequenceAcknowledgement SOAP header as defined in WS-ReliableMessaging 1.2.<br>
/// <pre>
/// <wsrm:Identifier ...> xs:anyURI </wsrm:Identifier>
/// [ [ [ <wsrm:AcknowledgementRange ... 
///             Upper="wsrm:MessageNumberType" 
///             Lower="wsrm:MessageNumberType"/> + | 
///       <wsrm:None/> 
///     ]
///     <wsrm:Final/> ? 
///   ] |
///   <wsrm:Nack> wsrm:MessageNumberType </wsrm:Nack> + 
/// ]
/// ...
/// </pre>
Class %SOAP.RM.SequenceAcknowledgement Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsrm";

Parameter XMLIGNOREINVALIDTAG = 1;

Parameter OUTPUTTYPEATTRIBUTE = 0;

Property Identifier As %xsd.anyURI;

Property AcknowledgementRange As list Of %SOAP.RM.AcknowledgementRange(XMLPROJECTION = "element");

/// Should never have a value except empty string.  Set to $c(0) to show element and "" to not show element.
Property None As %String;

/// Should never have a value except empty string.  Set to $c(0) to show element and "" to not show element.
Property Final As %String;

Property Nack As list Of %SOAP.RM.MessageNumberType(XMLPROJECTION = "element");

/// Create SequenceAcknowledgement header based on WS-ReliableMessaging session
ClassMethod CreateHeader(session As %SYS.RMSession, request As %Boolean) As %SOAP.RM.SequenceAcknowledgement [ Internal ]
{
	Set ack=..%New()
	Set ack.Identifier=$select(request:session.ResponseIdentifier,1:session.RequestIdentifier)
	Do session.GetRange(ack.AcknowledgementRange)
	If ack.AcknowledgementRange.Count()=0 {
		Set ack.None=$c(0)
	}
	If session.Terminated Set ack.Final=$c(0)
	$$$SOAPLogSecurity("Add SequenceAcknowledgement.")
	Quit ack
}

/// Update session based on acknowledgement
Method UpdateSession(session As %SYS.RMSession) [ Internal ]
{
	If (..AcknowledgementRange.Count()>0) || (..None'="") {
		Do session.SetRange(..AcknowledgementRange)
	} ElseIf ..Nack.Count()>0 {
		For i=1:1:..Nack.Count() {
			Do session.SetMessageState(..Nack.GetAt(i),0)
		}
	}
}

}
