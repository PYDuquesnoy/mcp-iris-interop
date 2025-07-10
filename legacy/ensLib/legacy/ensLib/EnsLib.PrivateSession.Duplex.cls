/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.PrivateSession.Duplex Extends Ens.BusinessDuplex [ Abstract, System = 4 ]
{

/// Domain for error messages   
Parameter DOMAIN = "EnsDICOM";

/// This holds the settings list
Parameter SETTINGS = "DuplexTargetConfigName";

/// Configuration item(s) to which to send messages
Property DuplexTargetConfigName As %String(MAXLEN = 1000);

/// This holds the deferred response token
Property DeferredResponseToken As %String;

/// This holds data that is not yet ready for processing
Property ReceivedDataQueue As list Of %Library.Persistent;

/// This method is called by the TCP Adapter when a message is received.
Method OnProcessInput(pInput As %Persistent, Output pOutput As %Persistent, ByRef pHint As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    try {
        Set tSC=..SendDocumentToProcess(pInput) Quit:$$$ISERR(tSC)
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

Method SendDocumentToProcess(pDocument As %Library.Persistent) As %Status
{
    #dim tSC As %Status = $$$OK
    try {
        If '..%InPrivateSession Set tSC=..StartPrivateSession() Quit:$$$ISERR(tSC)
        If ..DeferredResponseToken'="" {
            Set tSC=..SendDeferredResponse(..DeferredResponseToken,pDocument) If $$$ISERR(tSC) Quit
            Set ..DeferredResponseToken=""
        } else {
            Do ..ReceivedDataQueue.Insert(pDocument)
        }
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

Method StartPrivateSession() As %Status
{
    #dim tSC As %Status = $$$OK
    try {
        If ..%InPrivateSession Quit
        Set tSC = ..RegisterPrivateSession() Quit:$$$ISERR(tSC)
        Set tSC=..SendRequestAsync(..DuplexTargetConfigName,##class(EnsLib.PrivateSession.Message.Start).%New()) Quit:$$$ISERR(tSC)
        Set tSC = ..OnPrivateSessionStarted(1) Quit:$$$ISERR(tSC)
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

Method StopPrivateSession(pAttachedMessage As %Persistent = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tMessageHeaderId As %String
    #dim tRequestHeader As Ens.MessageHeader
    try {
	    If ..%InPrivateSession {
	        #; Target might receive stop message before this job unregisters and therefore need to remove queue pointer 
	        If ..DeferredResponseToken'="" {
		        try {
					Set tMessageHeaderId=$p(..DeferredResponseToken,"|",1)
					Set tRequestHeader=##Class(Ens.MessageHeader).%OpenId(tMessageHeaderId,,.tSC) Quit:$$$ISERR(tSC)
					If $$$ConfigSessionQueueName(..%ConfigName,..%PrivateSessionId)'=tRequestHeader.ReturnQueueName {
			        	Kill $$$ConfigSessionQueueName(..%ConfigName,..%PrivateSessionId)
					}
					Set tRequestHeader=""
		        } catch {}
	        }
			Set tSC=..SendDocumentToProcess(##class(EnsLib.PrivateSession.Message.Stop).%New(pAttachedMessage)) Quit:$$$ISERR(tSC)
            Set tSC=..UnRegisterPrivateSession()
            set ..DeferredResponseToken=""
            
            #; Ensure all messages are delivered including STOP message (JN1098)
            #; Do ..ReceivedDataQueue.Clear()
            Set tSC=..OnPrivateSessionStopped(1) Quit:$$$ISERR(tSC)
        }
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

XData MessageMap
{
<MapItems>
<MapItem MessageType="EnsLib.PrivateSession.Message.Start"><Method>OnMsgPrivateSessionStart</Method></MapItem>
<MapItem MessageType="EnsLib.PrivateSession.Message.Stop"><Method>OnMsgPrivateSessionStop</Method></MapItem>
<MapItem MessageType="EnsLib.PrivateSession.Message.Poll"><Method>OnMsgPrivateSessionPoll</Method></MapItem>
</MapItems>
}

Method OnMsgPrivateSessionStart(pRequest As EnsLib.PrivateSession.Message.Start, Output pResponse As %Library.Persistent) As %Status
{
    #dim tSC As %Status = $$$OK
    try {
        Set tSC=..RegisterPrivateSession() Quit:$$$ISERR(tSC)
        Set tSC=..OnPrivateSessionStarted(0) Quit:$$$ISERR(tSC)
        Kill %objlasterror Set pResponse=##class(EnsLib.PrivateSession.Message.Ack).%New()
        If '$IsObject(pResponse) Set tSC=$$$ERROR($$$FailedToNewClass,"EnsLib.PrivateSession.Message.Ack") Quit
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

Method OnMsgPrivateSessionStop(pRequest As EnsLib.PrivateSession.Message.Stop, Output pResponse As %Library.Persistent) As %Status
{
    #dim tSC As %Status = $$$OK
    try {
        Set tSC=..UnRegisterPrivateSession() Quit:$$$ISERR(tSC)
        set ..DeferredResponseToken=""
        do ..ReceivedDataQueue.Clear()
        Set tSC=..OnPrivateSessionStopped(0,pRequest.AttachedMessage) Quit:$$$ISERR(tSC)
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

Method OnMsgPrivateSessionPoll(pPollIn As EnsLib.PrivateSession.Message.Poll, Output pResponse As %Library.Persistent) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tToken As %String
    try  {
        If ..ReceivedDataQueue.Count() {
            Set pResponse=..ReceivedDataQueue.GetAt(1)
            do ..ReceivedDataQueue.RemoveAt(1)
        } Else {
            Set tSC=..DeferResponse(.tToken) If $$$ISERR(tSC) Quit
            Set ..DeferredResponseToken=tToken
        }
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Do ##super(.pArray,pItem)
    If pItem.GetModifiedSetting("DuplexTargetConfigName",.tValue) {
        Set tOne=$ZStrip(tValue,"<>W")
        Set:""'=tOne pArray(tOne)=""
    }
}

Method OnPrivateSessionStarted(pSelfGenerated As %Boolean) As %Status
{
    #; Subclass Responsibility
    Quit $$$OK
}

Method OnPrivateSessionStopped(pSelfGenerated As %Boolean, pAttachedMessage As %Persistent = "") As %Status
{
    #; Subclass Responsibility
    Quit $$$OK
}

Method OnTearDown() As %Status
{
    #dim tSC As %Status = $$$OK
    try {
        If ..%InPrivateSession Set tSC=..StopPrivateSession() Quit:$$$ISERR(tSC)
    } catch {
        Set tSC=$$$EnsSystemError
    }
    Quit tSC
}

}
