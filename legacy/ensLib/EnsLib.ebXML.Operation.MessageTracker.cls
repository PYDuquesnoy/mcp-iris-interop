/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsebXML)

/// ebXML message tracker operation
Class EnsLib.ebXML.Operation.MessageTracker Extends Ens.BusinessOperation [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter INVOCATION = "InProc";

/// Initiate tracking of an ebXML message response
Method InitiateResponseTracking(pRequest As EnsLib.ebXML.Operation.MessageTrackerTrackResponse, ByRef pResponse As Ens.Response) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tResponseToken As %String
		
		Set tSC = ..DeferResponse(.tResponseToken)
		Quit:$$$ISERR(tSC)
		
		If '##class(EnsLib.ebXML.MessageTracking).IsMessageTracked(pRequest.Request) {
			// Start tracking this message
			Set tSC = ##class(EnsLib.ebXML.MessageTracking).BeginTracking(pRequest.Request,"pending",.tResponseToken)
			Quit:$$$ISERR(tSC)
		} Else {
			// We're already tracking this, update it with the new token
			Set tSC = ##class(EnsLib.ebXML.MessageTracking).UpdateTrackingToken(pRequest.Request, tResponseToken)
			Quit:$$$ISERR(tSC)
		}
		
		// We're done, the response to this is deferred.

	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Initiate tracking of an ebXML message acknowledgement
Method InitiateAcknowledgementTracking(pRequest As EnsLib.ebXML.Operation.MessageTrackerTrackAcknowledgement, ByRef pResponse As Ens.Response) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tAckToken As %String
		
		Set tSC = ..DeferResponse(.tAckToken)
		Quit:$$$ISERR(tSC)
		
		If '##class(EnsLib.ebXML.MessageTracking).IsMessageTracked(pRequest.Request) {
			// Start tracking this message
			Set tSC = ##class(EnsLib.ebXML.MessageTracking).BeginTracking(pRequest.Request,"pending",,.tAckToken)
			Quit:$$$ISERR(tSC)
		} Else {
			// We're already tracking this, update it with the new token
			Set tSC = ##class(EnsLib.ebXML.MessageTracking).UpdateTrackingAckToken(pRequest.Request, tAckToken)
			Quit:$$$ISERR(tSC)
		}
		
		// We're done, the response to this is deferred.

	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

XData MessageMap
{
<MapItems>
<MapItem MessageType="EnsLib.ebXML.Operation.MessageTrackerTrackAcknowledgement"> 
<Method>InitiateAcknowledgementTracking</Method>
</MapItem>
<MapItem MessageType="EnsLib.ebXML.Operation.MessageTrackerTrackResponse"> 
<Method>InitiateResponseTracking</Method>
</MapItem>
</MapItems>
}

}
