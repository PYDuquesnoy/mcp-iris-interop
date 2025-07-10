/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsebXML

/// Implementation of the ebXML message service.
Class EnsLib.ebXML.Process.MessageService Extends Ens.BusinessProcess [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Called to process a request message
Method OnRequest(pRequest As EnsLib.ebXML.Message, Output pResponse As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tService As %String
		#dim tAction  As %String

		// Grab the service
		Set tService = pRequest.GetValueAt("Headers(MessageHeader).Service.content",,.tSC)
		Quit:$$$ISERR(tSC)
		
		// Grab the action
		Set tAction  = pRequest.GetValueAt("Headers(MessageHeader).Action",,.tSC)
		Quit:$$$ISERR(tSC)
		
		// Verify these ...
		If (tService="") || (tAction="") {
			Set tSC = $$$ERROR($$$EnsebXMLErrBadlyFormedMessage)
			Quit
		}
		
		// Verify that it was properly sent to us ...
		If tService '= $$$EnsebXMLMessageService {
			Set tSC = $$$ERROR($$$EnsebXMLErrUndeliverableMessage)
			Quit
		}
		
		// Process a message acknowledgement
		If tAction = $$$EnsebXMLMessageServiceAcknowledgmentAction && pRequest.IsAcknowledgment() {
			Set tSC = ..ProcessAcknowledgement(pRequest,.pResponse)
			Quit
		}
		
		// Process status request
		If tAction=$$$EnsebXMLMessageServiceStatusRequestAction && pRequest.IsStatusRequest() {
			Set tSC = ..ProcessStatusRequest(pRequest,.pResponse)
			Quit
		}
		
		// Process a ping request
		If tAction = $$$EnsebXMLMessageServicePingAction {
			Set tSC = ..ProcessPingRequest(pRequest, .pResponse)
			Quit
		}

		// Default behavior is to report an "Unsupported" error
		Set tSC = ..ProcessUnsupportedRequest(pRequest, .pResponse)
		Quit:$$$ISERR(tSC)
		
	} While (0)

Exit

	// Process *any* errors here into an ebXML ErrorList
	If $$$ISERR(tSC) {
		// NOTE: BuildErrorResponse() will return $$$OK and build out an ErrorList in pResponse.
		Set tSC = ..BuildErrorResponse(pRequest, tSC, .pResponse)
	}

	Quit tSC
	
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Process an ebXML "status" request
Method ProcessStatusRequest(pRequest As EnsLib.ebXML.Message, Output pResponse As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		
		// Ask the MessageTracker for a status update on the specified message
		Set tSC = ##class(EnsLib.ebXML.MessageTracking).ProcessStatusRequest(pRequest,
																			 ..%SessionId,
																			 ..MessageDomain,
																			 .pResponse)

	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Process an ebXML "acknowledgement" request
Method ProcessAcknowledgement(pRequest As EnsLib.ebXML.Message, Output pResponse As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tAckToken As %String
		
		// Tell the message tracker we received an acknowledgement
		Set tSC = ##class(EnsLib.ebXML.MessageTracking).UpdateTrackingWithAcknowledgement(pRequest, "acknowledged", .tAckToken)
		Quit:$$$ISERR(tSC)
		
		// NOTE: As per the ebMS spec, there is no response to an ack (other than perhaps an error)
		//       in order to avoid message loops.
		
		If tAckToken'="" {
			Set tSC = ..SendDeferredResponse(tAckToken, pRequest)
			Quit:$$$ISERR(tSC)
		}

	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Process an ebXML "ping" request
Method ProcessPingRequest(pRequest As EnsLib.ebXML.Message, Output pResponse As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		
		// Send the proper reply
		Set pResponse = ##class(EnsLib.ebXML.Message).%New()
		Set tSC = pResponse.BuildReplyHeader(pRequest,
											 $$$EnsebXMLMessageIdFromSessionId(..%SessionId,..MessageDomain),
											 $$$EnsebXMLMessageServicePongAction,
											 $$$EnsebXMLMessageService)

	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Build an ebXML Error response for the specified error
Method BuildErrorResponse(pRequest As EnsLib.ebXML.Message, pStatus As %Status, Output pResponse As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		
		// Send the proper reply
		Set pResponse = ##class(EnsLib.ebXML.Message).%New()
		Set tSC = pResponse.BuildErrorList(pRequest,
										   $$$EnsebXMLMessageIdFromSessionId(..%SessionId,..MessageDomain),
										   $$$EnsebXMLMessageServiceMessageErrorAction,
										   $$$EnsebXMLMessageService,
										   pStatus)

	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Process an unsupported request
Method ProcessUnsupportedRequest(pRequest As EnsLib.ebXML.Message, Output pResponse As EnsLib.ebXML.Message) As %Status
{
	// Whatever this is ... we don't support it.
	Quit $$$ERROR($$$EnsebXMLErrNotSupported)
}

/// Message domain (from the production settings)
Property MessageDomain As %String [ InitialExpression = {$GET($$$ConfigProdSetting("MessageDomain"),$system.INetInfo.LocalHostName())}, Required ];

/// Settings for this business process
Parameter SETTINGS As %String = "MessageDomain";

Storage Default
{
<Data name="MessageServiceDefaultData">
<Subscript>"MessageService"</Subscript>
<Value name="1">
<Value>MessageDomain</Value>
</Value>
</Data>
<DefaultData>MessageServiceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
