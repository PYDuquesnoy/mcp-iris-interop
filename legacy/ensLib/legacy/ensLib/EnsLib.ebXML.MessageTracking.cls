/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsebXML)

/// A class for tracking the progress of ebXML messages
Class EnsLib.ebXML.MessageTracking Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

/// Message ID of the message we're tracking
Property MessageId As %String(COLLATION = "SQLUPPER", MAXLEN = 512) [ Required ];

/// Conversation ID of the message we're tracking
Property ConversationId As %String(COLLATION = "SQLUPPER", MAXLEN = 512) [ Required ];

/// InterSystems IRIS message Oid of the request
Property RequestOid As %ObjectIdentity [ Required ];

/// InterSystems IRIS message Oid of the response
Property ResponseOid As %ObjectIdentity;

/// InterSystems IRIS message Oid of the ack (if we had one)
Property AckOid As %ObjectIdentity;

/// Time started (UTC)
Property TimeStarted As %TimeStamp [ InitialExpression = {$$$timeUTC}, Required ];

/// Time acknowledged (UTC)
Property TimeAcknowledged As %TimeStamp;

/// Time completed (UTC)
Property TimeCompleted As %TimeStamp;

/// Time message expires at (if specified) in UTC
Property ExpiresAt As %TimeStamp;

/// Message status
Property Status As %String(DISPLAYLIST = ",Received,Acknowledged,Pending,Complete,Failed", VALUELIST = ",received,acknowledged,pending,complete,failed") [ Required ];

/// Deferred response token (for the response)
Property Token As %String(MAXLEN = 512);

/// Deferred response token (for the ack, if we have one)
Property AckToken As %String(MAXLEN = 512);

/// Failure code (if the Status == failed)
Property Error As %Status;

/// Index the message ID for fast retrieval
Index MessageIdIndex On MessageId [ Unique ];

/// Index the conversation ID for fast retrieval
Index ConversationIdIndex On ConversationId;

/// Index the expiration date
Index ExpiryIndex On ExpiresAt;

/// RequestOid Index
Index RequestOidIndex On RequestOid [ Unique ];

/// Status Index
Index StatusIndex On Status [ Type = bitmap ];

/// Begin tracking of a request message
ClassMethod BeginTracking(pRequest As EnsLib.ebXML.Message, pStatus As %String, pToken As %String = "", pAckToken As %String = "") As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim SQLCODE         As %Integer
		#dim tMsgId          As %String
		#dim tConversationId As %String
		#dim tRequestOid     As %ObjectIdentity
		#dim tTS             As %TimeStamp
		#dim tExpires        As %TimeStamp
		#dim tStatus         As %String
		#dim tMessageHeader  As EnsLib.ebXML.schema.msg.MessageHeader
		
		
		Set tSC = ..inspectMessage(pRequest, .tMessageHeader, .tMsgId, .tConversationId)
		Quit:$$$ISERR(tSC)
		
		Set tExpires    = tMessageHeader.MessageData.TimeToLive  // This is an expiration timestamp, not a typical TTL
		Set tRequestOid = pRequest.%Oid()
		Set tTS         = $$$timeUTC
				
		Set SQLCODE=0
		&sql(INSERT INTO MessageTracking (MessageId, ConversationId, RequestOid, TimeStarted, ExpiresAt, Status, Token, AckToken)
				VALUES (:tMsgId, :tConversationId, :tRequestOid, :tTS, :tExpires, :pStatus, :pToken, :pAckToken))
		
		If SQLCODE'=0 {
			Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Update the tracking status of a message
ClassMethod UpdateTrackingStatus(pRequest As EnsLib.ebXML.Message, pStatus As %String, ByRef pError As %Status) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim SQLCODE         As %Integer
		#dim tMsgId          As %String
		#dim tConversationId As %String
		#dim tTS             As %TimeStamp
		#dim tMessageHeader  As EnsLib.ebXML.schema.msg.MessageHeader
		
		
		Set tSC = ..inspectMessage(pRequest, .tMessageHeader, .tMsgId, .tConversationId)
		Quit:$$$ISERR(tSC)
		
		Set tTS = $S((pStatus="failed")||(pStatus="complete"):$$$timeUTC,1:"")
		If pStatus'="failed" {
			// Only allow an error if the status is failed.
			Set pError = ""
		}
		
		Set SQLCODE=0
		&sql(UPDATE MessageTracking (TimeCompleted, Status, Error) VALUES (:tTS, :pStatus, :pError) WHERE MessageId = :tMsgId)
		
		If SQLCODE'=0 {
			Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		}		
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Update the tracking status of a message
ClassMethod UpdateTrackingWithResponse(pResponse As EnsLib.ebXML.Message, pStatus As %String, ByRef pToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim tMsgId          As %String
		#dim tConversationId As %String
		#dim tMessageHeader  As EnsLib.ebXML.schema.msg.MessageHeader
		
		
		$$$ASSERT(pResponse.IsResponse())
		
		Set tSC = ..inspectMessage(pResponse, .tMessageHeader, .tMsgId, .tConversationId)
		Quit:$$$ISERR(tSC)
		
		// What is this in reply to?
		Set tMsgId = tMessageHeader.MessageData.RefToMessageId
		
		$$$ASSERT(tMsgId'="")
		
		// Look up the tracking info by the "In Reply To" MessageId
		#dim tInfo As EnsLib.ebXML.MessageTracking = ..MessageIdIndexOpen(tMsgId,,.tSC)
		Quit:$$$ISERR(tSC)
		
		// Update the tracking info
		Set tInfo.ResponseOid   = $S($IsObject($GET(pResponse)):pResponse.%Oid(),1:"")
		Set tInfo.Status        = pStatus
		Set tInfo.TimeCompleted = $S((pStatus="processed")||(pStatus="complete"):$$$timeUTC,1:"")
		
		// Pull out the deferred response token (if any) for the response
		Set pToken = tInfo.Token
		
		// Save
		Set tSC = tInfo.%Save()
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Update the tracking status of a message
ClassMethod UpdateTrackingWithAcknowledgement(pAcknowledgement As EnsLib.ebXML.Message, pStatus As %String, ByRef pAckToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim tMsgId          As %String
		#dim tConversationId As %String
		#dim tMessageHeader  As EnsLib.ebXML.schema.msg.MessageHeader
		#dim tInfo           As EnsLib.ebXML.MessageTracking
		
		
		$$$ASSERT(pAcknowledgement.IsAcknowledgment())
		
		Set tSC = ..inspectMessage(pAcknowledgement, .tMessageHeader, .tMsgId, .tConversationId)
		Quit:$$$ISERR(tSC)
		
		// What are we acknowledging?
		Set tMsgId = pAcknowledgement.GetValueAt("Headers(Acknowledgment).RefToMessageId",,.tSC)
		Quit:$$$ISERR(tSC)
		
		$$$ASSERT(tMsgId'="")
		
		// Look up the tracking info by MessageId
		Set tInfo = ..MessageIdIndexOpen(tMsgId,,.tSC)
		Quit:$$$ISERR(tSC)
		
		// Update the tracking info
		Set tInfo.AckOid           = $S($IsObject($GET(pAcknowledgement)):pAcknowledgement.%Oid(),1:"")
		Set tInfo.Status           = pStatus
		Set tInfo.TimeAcknowledged = $$$timeUTC
		Set tInfo.TimeCompleted    = $S((pStatus="processed")||(pStatus="complete"):$$$timeUTC,1:"")

		// Pull out the deferred response token (if any) for the ack
		Set pAckToken = tInfo.AckToken
		
		// Save
		Set tSC = tInfo.%Save()
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Update the tracking token for a message
ClassMethod UpdateTrackingToken(pRequest As EnsLib.ebXML.Message, pToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim tMsgId          As %String
		#dim tConversationId As %String
		#dim tMessageHeader  As EnsLib.ebXML.schema.msg.MessageHeader
		#dim tInfo           As EnsLib.ebXML.MessageTracking
		
		Set tSC = ..inspectMessage(pRequest, .tMessageHeader, .tMsgId, .tConversationId)
		Quit:$$$ISERR(tSC)
		
		$$$ASSERT(tMsgId'="")
		
		// Look up the tracking info by MessageId
		Set tInfo = ..MessageIdIndexOpen(tMsgId,,.tSC)
		Quit:$$$ISERR(tSC)
		
		// Update the deferred response token for the response
		Set tInfo.Token = pToken

		// Save
		Set tSC = tInfo.%Save()
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Update the tracking token for a message
ClassMethod UpdateTrackingAckToken(pRequest As EnsLib.ebXML.Message, pAckToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim tMsgId          As %String
		#dim tConversationId As %String
		#dim tMessageHeader  As EnsLib.ebXML.schema.msg.MessageHeader
		#dim tInfo           As EnsLib.ebXML.MessageTracking
		
		Set tSC = ..inspectMessage(pRequest, .tMessageHeader, .tMsgId, .tConversationId)
		Quit:$$$ISERR(tSC)
		
		$$$ASSERT(tMsgId'="")
		
		// Look up the tracking info by MessageId
		Set tInfo = ..MessageIdIndexOpen(tMsgId,,.tSC)
		Quit:$$$ISERR(tSC)
		
		// Update the deferred response token for the Acknowledgement
		Set tInfo.AckToken = pAckToken

		// Save
		Set tSC = tInfo.%Save()
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Check to see if we're tracking a message
ClassMethod IsMessageTracked(pMessage As EnsLib.ebXML.Message, ByRef pSC As %Status) As %Boolean
{
	#dim tStatus As %String = ""
	Set pSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim tMsgId  As %String
		
		Set pSC = ..inspectMessage(pMessage,,.tMsgId)
		Quit:$$$ISERR(pSC)
		
		Set tStatus = ..IsMessageIdTracked(tMsgId,.pSC)
				
	} While (0)
Exit
	Quit tStatus
Trap
	Set $ZT="",pSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Check to see if we're tracking a message
ClassMethod IsMessageIdTracked(pMessageId As %String, ByRef pSC As %Status) As %Boolean
{
	#dim tStatus As %String = ""
	Set pSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim SQLCODE As %Integer
		
		Set SQLCODE=0
		&sql(SELECT Status INTO :tStatus
				FROM MessageTracking
				WHERE MessageId = :pMessageId)
		
		If SQLCODE=100 {
			// Not found
			Set tStatus = ""
			Quit
		} ElseIf SQLCODE'=0 {
			// Some other error
			Set pSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		}	
		
	} While (0)
Exit
	Quit (tStatus '= "")
Trap
	Set $ZT="",pSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Track a a request message by id
ClassMethod TrackMessageWithId(pMessageId As %String, ByRef pStatus As %String, ByRef pTSStarted As %TimeStamp, ByRef pTSCompleted As %TimeStamp, ByRef pResponseOid As %ObjectIdentity, ByRef pToken As %String, ByRef pTSAcknowledged As %TimeStamp, ByRef pAckOid As %ObjectIdentity, ByRef pAckToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim SQLCODE As %Integer
		
		Set SQLCODE=0
		&sql(SELECT Status, TimeStarted, TimeCompleted, TimeAcknowledged, ResponseOid, AckOid, Token, AckToken
				INTO :pStatus, :pTSStarted, :pTSCompleted, :pTSAcknowledged, :pResponseOid, :pAckOid, :pToken, :pAckToken
				FROM MessageTracking
				WHERE MessageId = :pMessageId)
		
		If SQLCODE=100 {
			// Not found
			Set (pStatus,pTSStarted,pTSCompleted,pTSAcknowledged,pResponseOid,pAckOid,pToken,pAckToken) = ""
			Quit
		} ElseIf SQLCODE'=0 {
			// Some other error
			Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		}		
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Track a request message by message and dig up the response object if it has one
ClassMethod TrackMessage(pRequest As EnsLib.ebXML.Message, ByRef pStatus As %TimeStamp, ByRef pTSStarted As %TimeStamp, ByRef pTSCompleted As %TimeStamp, ByRef pResponse As EnsLib.ebXML.Message, ByRef pToken As %String, ByRef pTSAcknowledged As %TimeStamp, ByRef pAcknowledgement As EnsLib.ebXML.Message, ByRef pAckToken As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		#dim SQLCODE      As %Integer
		#dim tRequestOid  As %ObjectIdentity
		#dim tResponseOid As %ObjectIdentity
		#dim tAckOid      As %ObjectIdentity
		
		
		Set (pResponse,pAcknowledgement) = $$$NULLOREF
		
		Set tRequestOid = pRequest.%Oid()
		
		Set SQLCODE=0
		&sql(SELECT Status, TimeStarted, TimeCompleted, TimeAcknowledged, ResponseOid, AckOid, Token, AckToken
				INTO :pStatus, :pTSStarted, :pTSCompleted, :pTSAcknowledged, :tResponseOid, :tAckOid, :pToken, :pAckToken
				FROM MessageTracking
				WHERE RequestOid = :tRequestOid)
		
		If SQLCODE=100 {
			// Not found
			Set (pStatus,pTSStarted,pTSCompleted,pTSAcknowledged,pToken,pAckToken) = ""
			Quit
		} ElseIf SQLCODE'=0 {
			// Some other error
			Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		}		
		
		If tResponseOid'="" {
			// Dig out the response for this request now that we know the corresponding response OID
			Set pResponse = ##class(EnsLib.ebXML.Message).%Open(tResponseOid,,.tSC)
			Quit:$$$ISERR(tSC)
		}
		
		If tAckOid'="" {
			// Dig out the acknowledgement for this request now that we know the corresponding ack OID
			Set pAcknowledgement = ##class(EnsLib.ebXML.Message).%Open(tAckOid,,.tSC)
			Quit:$$$ISERR(tSC)
		}
		
		// Done!
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Process a StatusRequest, building the appropriate StatusResponse response
ClassMethod ProcessStatusRequest(pRequest As EnsLib.ebXML.Message, pSessionId As %String, pDomain As %String, ByRef pResponse As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		// Use the RefToMessageId of the StatusRequest to lookup a message in the message log
		#dim tStatusRq    As EnsLib.ebXML.schema.msg.StatusRequest
		#dim tMsgId       As %String
		#dim tStatus      As %String
		#dim tTSStarted   As %TimeStamp
		#dim tTSCompleted As %TimeStamp
		#dim tResponseOid As %ObjectIdentity
		
		Set tStatusRq = pRequest.Headers.GetAt("StatusRequest")
		Set tMsgId    = tStatusRq.RefToMessageId
	
		// Go and look it up
		Set tSC = ##class(EnsLib.ebXML.MessageTracking).TrackMessageWithId(tMsgId,.tStatus,.tTSStarted,.tTSCompleted,.tResponseOid)
		Quit:$$$ISERR(tSC)
		
		// Convert to the externally known values ("" gives NotRecognized)
		Set tStatus = ..MessageStatusToStatusResponseStatus(tStatus)
		
		// Create a reply message
		Set pResponse = ##class(EnsLib.ebXML.Message).%New()
		Set tSC = pResponse.BuildReplyHeader(pRequest,
											 $$$EnsebXMLMessageIdFromSessionId(pSessionId,pDomain),
											 $$$EnsebXMLMessageService,
											 $$$EnsebXMLMessageServiceStatusResponseAction)
		Quit:$$$ISERR(tSC)
		
		// Inject a status response header
		Set tStatusResponse = ##class(EnsLib.ebXML.schema.msg.StatusResponse).%New()
		Set tStatusResponse.version        = $$$EnsebXMLVersion
		Set tStatusResponse.messageStatus  = tStatus
		Set tStatusResponse.RefToMessageId = tMsgId
	
		Do pResponse.Headers.SetAt(tStatusResponse,tStatusResponse.%ClassName(0))
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Purge entries from the message tracking tables.  Note that the timestamps in this table are in UTC.
ClassMethod doPurge(pExpiredByUTC As %TimeStamp, pDeleteMode As %String, ByRef pDeletedCount As %Integer) As %Status [ Internal ]
{
#define QUITONSQLERROR	If SQLCODE,SQLCODE'=100 { Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg)) Quit }
	
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tID         As %String
		#dim tRequestOid As %String
		#dim SQLCODE     AS %Integer


		Set tID = ""
		Set pDeletedCount = 0
		Set SQLCODE = 0
		
		&sql(DECLARE C1 CURSOR FOR
				Select ID, RequestOid Into :tID, :tRequestOid
				From EnsLib_ebXML.MessageTracking
				Where ExpiresAt <= :pExpiredByUTC)
		$$$QUITONSQLERROR
				
		&sql(OPEN C1)
		$$$QUITONSQLERROR
		
		For {
			&sql(FETCH C1)
			$$$QUITONSQLERROR
			
			&sql(Delete From EnsLib_ebXML.MessageTracking Where ID=:tID)			
			$$$QUITONSQLERROR

			Set pDeletedCount = pDeletedCount + %ROWCOUNT

			If pDeleteMode="message" {
				// Delete the message too, if specified
				Set tSC = ##class(EnsLib.ebXML.Message).%Delete(tRequestOid)
				Quit:$$$ISERR(tSC)
			}
		}
		
		&sql(CLOSE C1)
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Basic message inspection
ClassMethod inspectMessage(pMsg As EnsLib.ebXML.Message, ByRef pMessageHeader As EnsLib.ebXML.schema.msg.MessageHeader, ByRef pMsgId As %String, ByRef pConversationId As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tSC2 As %Status
		
		// Make sure this is valid
		Set tSC2 = pMsg.%ValidateObject()
		If $$$ISERR(tSC2) {
			Set tSC = $$$EnsError($$$EnsebXMLErrBadlyFormedMessage)
			Set tSC = $$$ADDSC(tSC,tSC2)
			Quit
		}
		
		// Grab the message header
		Set pMessageHeader = pMsg.Headers.GetAt("MessageHeader")
		If '$IsObject(pMessageHeader) || '$IsObject(pMessageHeader.MessageData) {
			Set tSC = $$$EnsError($$$EnsebXMLErrBadlyFormedMessage)
			Quit
		}
		
		// Dig out required elements
		Set pMsgId          = pMessageHeader.MessageData.MessageId
		Set pConversationId = pMessageHeader.ConversationId
		
		// Basic validation
		If (pMsgId="") || (pConversationId="") {
			Set tSC = $$$EnsError($$$EnsebXMLErrBadlyFormedMessage)
			Quit
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Convert an internal message status to a StatusResponse Status value
ClassMethod MessageStatusToStatusResponseStatus(pStatus As %String) As %String [ CodeMode = expression ]
{
$CASE(pStatus,
	              "":$$$EnsebXMLStatusResponseNotRecognized,
	      "received":$$$EnsebXMLStatusResponseReceived,
	  "acknowledged":$$$EnsebXMLStatusResponseReceived,
	       "pending":$$$EnsebXMLStatusResponseForwarded,
	      "complete":$$$EnsebXMLStatusResponseProcessed,
	        "failed":$$$EnsebXMLStatusResponseProcessed,
	                :$$$EnsebXMLStatusResponseReceived)
}

Storage Default
{
<Data name="MessageTrackingDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>MessageId</Value>
</Value>
<Value name="3">
<Value>TimeReceived</Value>
</Value>
<Value name="4">
<Value>TimeProcessed</Value>
</Value>
<Value name="5">
<Value>Status</Value>
</Value>
<Value name="6">
<Value>ExpiresAt</Value>
</Value>
<Value name="7">
<Value>RequestOid</Value>
</Value>
<Value name="8">
<Value>ResponseOid</Value>
</Value>
<Value name="9">
<Value>TimeStarted</Value>
</Value>
<Value name="10">
<Value>TimeCompleted</Value>
</Value>
<Value name="11">
<Value>Token</Value>
</Value>
<Value name="12">
<Value>ConversationId</Value>
</Value>
<Value name="13">
<Value>AckOid</Value>
</Value>
<Value name="14">
<Value>TimeAcknowledged</Value>
</Value>
<Value name="15">
<Value>AckToken</Value>
</Value>
<Value name="16">
<Value>Error</Value>
</Value>
</Data>
<DataLocation>^EnsLib.ebXML.MessageTrackingD</DataLocation>
<DefaultData>MessageTrackingDefaultData</DefaultData>
<IdLocation>^EnsLib.ebXML.MessageTrackingD</IdLocation>
<IndexLocation>^EnsLib.ebXML.MessageTrackingI</IndexLocation>
<StreamLocation>^EnsLib.ebXML.MessageTrackingS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
