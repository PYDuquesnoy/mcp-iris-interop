/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// SequenceFault SOAP header as defined in WS-ReliableMessaging 1.2.
Class %SOAP.RM.SequenceFault Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-rx/wsrm/200702";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsrm";

Parameter XMLIGNOREINVALIDTAG = 1;

Property FaultCode As %String(MAXLEN = "");

Property Detail As %XML.String(MAXLEN = "");

/// Make the fault for WS-ReliableMessaging
ClassMethod MakeFault(service As %SOAP.WebService, forCreateSequence As %Boolean, faultCode As %String, faultSubCode As %String, identifier As %xsd.anyURI = "") As %SOAP.Fault [ ServerOnly = 1 ]
{
	If identifier="" {
		Set detail=""
	} ElseIf forCreateSequence {
		Set detail=identifier
	} Else {
		Set detail="<wsrm:Identifier>"_identifier_"</wsrm:Identifier>"
	}
	Set reason=##class(%SOAP.RM.SequenceFault).GetFaultReason(faultSubCode)
	Set subCode="wsrm:"_faultSubCode
	
	If $$$CheckSOAPLogSecurity {
		$$$SOAPLogText("WS-ReliableMessaging Fault")
		$$$SOAPLogText("    faultCode="_faultCode)
		$$$SOAPLogText("    faultSubCode="_subCode)
		$$$SOAPLogText("    reason="_reason)
		$$$SOAPLogText("    detail="_detail)
	}
	
	If service.SoapVersion="1.2" {
		Set code=faultCode
		If code=$$$FAULTClient Set code=$$$FAULTSender
		If code=$$$FAULTServer Set code=$$$FAULTReceiver
		Set fault=##class(%SOAP.WebService).MakeFault12(faultCode,reason,detail)
		Set fault.Code.Subcode=##class(%SOAP.Fault12.Code).%New()
		Set fault.Code.Subcode.Value=subCode
		Set service.FaultAddressing=##class(%SOAP.Addressing.Properties).%New()
		Set service.FaultAddressing.Action=$$$SOAPWSRMns_"/fault"
	} Else {
		If forCreateSequence {
			Set fault=##class(%SOAP.WebService).MakeFault(subCode,reason)
		} Else {
			Set fault=##class(%SOAP.WebService).MakeFault(faultCode,reason)
			Set faultHeader=##class(%SOAP.RM.SequenceFault).%New()
			Set faultHeader.FaultCode=subCode
			Set faultHeader.Detail=detail
			Do service.FaultHeaders.SetAt(faultHeader,"SequenceFault")
		}
	}

	Set fault.faultPrefixDefinition="xmlns:wsrm="""_..#NAMESPACE_""""
	
	Quit fault
}

/// Get WS-ReliableMessaging fault reason.
ClassMethod GetFaultReason(faultCode As %String) As %String [ ServerOnly = 1 ]
{
	If faultCode="SequenceTerminated" {
		Set faultString="The Sequence has been terminated due to an unrecoverable error."
	} ElseIf faultCode="UnknownSequence" {
		Set faultString="The value of wsrm:Identifier is not a known Sequence identifier."
	} ElseIf faultCode="InvalidAcknowledgement" {
		Set faultString="The SequenceAcknowledgement violates the cumulative Acknowledgement invariant."
	} ElseIf faultCode="MessageNumberRollover" {
		Set faultString="The maximum value for wsrm:MessageNumber has been exceeded."
	} ElseIf faultCode="CreateSequenceRefused" {
		Set faultString="The Create Sequence request has been refused by the RM Destination."
	} ElseIf faultCode="SequenceClosed" {
		Set faultString="The Sequence is closed and cannot accept new messages."
	} ElseIf faultCode="WSRMRequired" {
		Set faultString="The RM Destination requires the use of WSRM."
	} ElseIf faultCode="MessageNumberRollover" {
		Set faultString="The maximum value for wsrm:MessageNumber has been exceeded"
	} Else {
		Set faultString="Unknown WS-ReliableMessaging fault."
	}
	Set fault=##class(%SOAP.WebService).MakeFault(faultCode,faultString,"","")
	
	Set fault.faultcode="wsc:"_fault.faultcode
	Set fault.faultPrefixDefinition="xmlns:wsc="""_..#NAMESPACE_""""
	
	Quit faultString
}

}
