/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Base class for handling delayed responses for Synchronous Request
Class Ens.Helper.Service.SyncResponseHandler [ Abstract, System = 4 ]
{

/// Used to set expected response wait time for the client.
/// If the client specifies the timeout then it will be used if
/// the value of this is 0. <br>
/// If the client is an IRIS Interoperabilty production SOAP operation
/// the client response time will be included in the HTTP headers. <br>
Property OverrideClientResponseWaitTimeout As %Integer [ InitialExpression = 0 ];

/// If the client provides unique ClientRequestKey and then ClientRetryRequestKey
/// then the SendRequestSync carried out by the service will attempt to prevent
/// multiple processing of the same request if the client abandons requests before
/// completion and retries the same request. <br>
/// Delayed in this context is relative to the time the requestor will wait for a 
/// response before retrying.<br>
/// Only one SendRequestSync in a service method is supported. 
Property SupportDelayedSyncRequest As %Boolean [ InitialExpression = 0 ];

/// Is this is set then the priority of the Synchronous request will be
/// changed to Simulated Sync. This means the process might be 
/// quiesced for job stoppage/production shutdown prior to processing completion.
/// Not applicable if target is invoked InProc.
/// Reserved for future use.
Property UseSimulatedSync As %Boolean [ InitialExpression = 0 ];

/// This Overrides the core Ens.BusinessService SendRequestSync method <br>
/// If <property>SupportDelayedSyncRequest</property> is false (the default) then
/// there is no change in behaviour. <br>
/// If <property>SupportDelayedSyncRequest</property> is true: <br>
/// 1. Look for Client request key.
/// 2. Determine if Retry or new
/// 3. Pass on normally or pass back delayed or hold until user disconnects/disappears
Method SendRequestSync(pTargetDispatchName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pSyncCallTimeout As %Numeric = -1, pDescription As %String = "", ByRef pSendSyncHandling As %String) As %Status
{

    If ..SupportDelayedSyncRequest {
        /* Allow caller to set entries in array pSendSyncHandling */

        If ..UseSimulatedSync Set pSendSyncHandling("UseSimSync") = 1

        Set tSC = ..OnPopulateSendSyncHandling(pTargetDispatchName, pRequest, pSyncCallTimeout, pDescription,.pSendSyncHandling)
        If $$$ISERR(tSC) {
            Set tSC = ..SetReturnStatusCode("ServerError","Server Error",.pResponse)
            Return tSC
        }

        If '..VerifySendSyncHandlingInstructions(.pSendSyncHandling) {
            Set tSC = ..SetReturnStatusCode("ClientError","Bad Request",.pResponse)
            Return tSC
        }

        /*  Need to detect if this is the first occurrence (and hence only supported)
            call to SendRequestSync() or if the calling method contains more than one.
            $$$EnsJobLocal is cleared up on tear down.
            The Assumption is that if multiple SendRequestSync then the second will
            have a different target.
        */
        If $Data($$$EnsJobLocal("SendSyncHandling","Target"),tTarget) {
            If tTarget '= pTargetDispatchName {
                /* No extra handling for this SendRequestSync call */
                If ($Get(pSendSyncHandling("ClientRetryRequestKey"))'="") {
                    $$$LOGWARNING("Delayed Response Handling not supported for second occurrence of SendRequestSync within calling service request. (Setting SupportDelayedResponseForRequest)")
                }
                Kill pSendSyncHandling
            }
        } Else {
            Set $$$EnsJobLocal("SendSyncHandling","Target") = pTargetDispatchName
            Do $Increment($$$EnsJobLocal("SendSyncHandling","Iterations")) 
        }

        If $Get(pSendSyncHandling("ClientRetryRequestKey"))'="" {
            Set xrefSC = $$$OK, xrefDelayedClientRequest = $$$NULLOREF
            If ##class(Ens.Temp.XREF.DelayedClientRequest).%ExistsId(pSendSyncHandling("ClientRetryRequestKey")) {
                /*  The original request processing has exceeded the expected wait limit for response
                    If still processing then this will fail to open with concurrency 4 - (Exclusive, retained lock)
                    If do open then the ResponseHeader property will be set if original sync request finished.
                    If do open and the ResponseHeader property is null oref then the original sync request was cancelled.
                */
                Try {
                    /* Use the expected adjusted response timeout for the lock timeout */

                    If $Get(pSendSyncHandling("ResponseWaitTimeoutToUse")) Set tProcessDefaultLockTimeout = $SYSTEM.SQL.Util.SetOption("ProcessLockTimeout",pSendSyncHandling("ResponseWaitTimeoutToUse"))

                    Set xrefDelayedClientRequest = ##class(Ens.Temp.XREF.DelayedClientRequest).%OpenId(pSendSyncHandling("ClientRetryRequestKey"),4,.xrefSC)

                    If $Get(tProcessDefaultLockTimeout) Do $SYSTEM.SQL.Util.SetOption("ProcessLockTimeout",tProcessDefaultLockTimeout)

                    If $$$ISERR(xrefSC) {
                        If (","_$system.Status.GetErrorCodes(xrefSC))[(","_$$$LockFailedToAcquireExclusive) {
                            /* The original processing is still in progress
                                We do not want to go back to caller with empty response since
                                they may not expect it.
                                We do not want to error.
                            */
                            #; Set status code as fall back
                            Set tSC = ..SetReturnStatusCode("Accepted","Accepted (please retry to poll for result)",.pResponse)
                            /*
                                Calling code is expecting pResponse to be populated or an error.
                                We want the client to retry.
                                If we return $$$OK then the caller will think all is well
                            */
                            Set:$$$ISOK(tSC) tSC = ..OnHandleNoResponseYet()
                            /* By design for OnHandlNoResponseYet() the Client ought not be there by time we get to the Return */
                            Return tSC
                        } If (","_$system.Status.GetErrorCodes(xrefSC))[(","_$$$LoadObjectNotFound) {
                            /*  Non existent outstanding request so fall through to go normally */
                            Set xrefSC = $$$OK
                        } /* Else continue to return 500 */
                    } ElseIf (xrefDelayedClientRequest.RequestHeader.TargetConfigName = pTargetDispatchName) {
                        /* 
                            We have the xref info and it is for the same target as - check if completed.
                            Not checking if pRequest is the same payload as the original request of
                             xrefDelayedClientRequest.RequestHeader.MessageBodyClassName of MessageBodyId
                        */
                        If $IsObject(xrefDelayedClientRequest.ResponseHeader) {
                            Try {
                                /* Get the response and remove xref entry as appropriate*/
                                Set pResponse = $classmethod(xrefDelayedClientRequest.ResponseHeader.MessageBodyClassName,"%OpenId",xrefDelayedClientRequest.ResponseHeader.MessageBodyId,/* default concurrency */,.xrefSC)
                                If $$$ISOK(xrefSC) && $IsObject(pResponse) {
                                    /*  Do not delete xrefDelayedClientRequest for first return
                                        since this particular connection/pairing may be gone by the time
                                        the repsonse is passed back.
                                        Delete after second RetryRequest if there is one.
                                        If successful the first time then the xref entry will be removed
                                        when the RequestHeader is purged.
                                    */
                                    If (xrefDelayedClientRequest.UTCWhenReturnedToRetryRequest = "") {
                                        Set tCleanup = 0
                                        Set xrefDelayedClientRequest.UTCWhenReturnedToRetryRequest = $zdatetime($ztimestamp,3)
                                        Set xrefSaveSC = xrefDelayedClientRequest.%Save()
                                        If $$$ISERR(xrefSaveSC) $$$LOGERROR("Failed to update UTCWhenReturnedToRetryRequest Ens.Temp.XREF.DelayedClientRequest for "_pSendSyncHandling("ClientRetryRequestKey")_":"_$system.Status.GetErrorText(xrefSaveSC))
                                    } Else {
                                        Set tCleanup = 1
                                    }
                                    If tCleanup || $$$ISERR(xrefSaveSC) {
                                        Try {
                                            Do ##class(Ens.Temp.XREF.DelayedClientRequest).%DeleteId(pSendSyncHandling("ClientRetryRequestKey"))
                                        } Catch {
                                            $$$LOGERROR("Failed To clean up Ens.Temp.XREF.DelayedClientRequest for "_pSendSyncHandling("ClientRetryRequestKey"))
                                        }
                                    }
                                    /* Represents successful pseudo completion of the retried SendRequestSync call */
                                    Return $$$OK
                                }
                            } Catch {
                                /* Will return 500 below */
                                Set xrefSC = $$$EnsSystemError
                            }
                        } Else {
                            /*
                             Check xrefDelayedClientRequest.RequestHeader.Invocation $$$eMessageInvocationQueue vs $$$eMessageInvocationInProc
                             If $$$eMessageInvocationQueue another process that this service was supposed to be processing the original request and holding the lock.
                                1. Look for CorrespondingMessageId and use if exists else ontinue to make new request processing .
                               
                               Do Not try to wait to see if still being processed and request again.
                                1. Delete XREF - this will be done when fall through
                                2. Change RetryRequest key to Request key
                                3. Continue to make new request processing 
                            */
                            If xrefDelayedClientRequest.RequestHeader.Invocation=$$$eMessageInvocationQueue {
                                If xrefDelayedClientRequest.RequestHeader.CorrespondingMessageId '= "" {
                                    Set tResponseHeader = ##class(Ens.MessageHeader).%OpenId(xrefDelayedClientRequest.RequestHeader.CorrespondingMessageId,,.xrefSC)
                                    If $$$ISOK(xrefSC) && $IsObject(tResponseHeader) {
                                        Set pResponse = $classmethod(tResponseHeader.MessageBodyClassName,"%OpenId",tResponseHeader.MessageBodyId,/* default concurrency */,.xrefSC)
                                        If $$$ISOK(xrefSC) && $IsObject(pResponse) {
                                            Try {
                                                /*  Not setting UTCWhenReturnedToRetryRequest property since original processor
                                                    had not set ResponseHeader and hence not accounting for a delay to get to here
                                                    and client doing the retry still present.
                                                */
                                                Do ##class(Ens.Temp.XREF.DelayedClientRequest).%DeleteId(pSendSyncHandling("ClientRetryRequestKey"))
                                            } Catch {
                                                $$$LOGERROR("Failed To clean up Ens.Temp.XREF.DelayedClientRequest for "_pSendSyncHandling("ClientRetryRequestKey"))
                                            }
                                            /* Represents successful pseudo completion of the retried SendRequestSync call */
                                            Return $$$OK
                                        }
                                    }
                                } /* Else don't try to wait to see if still in progress. Continue as if new request */
                            }
                            /*  Continue to try again as if original request but if xrefSC is an error it will report a Server Error
                                Move Request Retry Key entry to Request Key Entry.
                            */
                            If $$$ISOK(xrefSC) {
                                Set pSendSyncHandling("ClientRequestKey")=pSendSyncHandling("ClientRetryRequestKey")
                                Kill pSendSyncHandling("ClientRetryRequestKey")
                            }
                        }
                    }   /*  Else this is another SendRequestSync call for the client
                            request since target is different. Treat as a new request.
                        */
                } catch ex {
                    Set xrefSC = $$$EnsSystemError
                }
                If $$$ISERR(xrefSC) {
                    Set tSC = ..SetReturnStatusCode("ServerError","Server Error",.pResponse)
                    Return tSC
                }
                /* Ensure close request if not using */
                Set xrefDelayedClientRequest = ""
            } Else {
                /* Do not have a Ens.Temp.XREF.DelayedClientRequest for the retry key
					due to production restart/failover before request completed.
                    Promote retry to new request and process again.
                    This ought not to lead to an  extra request being processed as synch
					requests suspended on production stop.
                */
                Set pSendSyncHandling("ClientRequestKey")=pSendSyncHandling("ClientRetryRequestKey")
                Kill pSendSyncHandling("ClientRetryRequestKey")
            }
            /*  Continuing to make core SendRequestSync call and delete outstanding XREF for the same ClientRequestKey if exists. */
            If $Get(pSendSyncHandling("ClientRequestKey"))'="" {
                If ##class(Ens.Temp.XREF.DelayedClientRequest).%ExistsId(pSendSyncHandling("ClientRequestKey")) Do ##class(Ens.Temp.XREF.DelayedClientRequest).%DeleteId(pSendSyncHandling("ClientRequestKey"))
            }
        }
    }
    Return ##class(Ens.BusinessService)($this).SendRequestSync(pTargetDispatchName,pRequest,.pResponse,pSyncCallTimeout,pDescription,.pSendSyncHandling)
}

/// Implement in protocol specific sub class to populate:<br>
///  pSendSyncHandling("ClientRequestKey")
///  pSendSyncHandling("ClientRetryRequestKey")
///  pSendSyncHandling("ResponseWaitTimeoutToUse")
/// Optional for future use:
///     pSendSyncHandling("UseSimSync") - this has limited usage since the response from any requeued sim sync request is not used.
/// Information/OnPopulateSendSyncHandling use only:
///     pSendSyncHandling("ClientResponseTimeout")
///     pSendSyncHandling("TransportMechanism")
/// 
Method OnPopulateSendSyncHandling(pTargetDispatchName As %String, pRequest As %Library.Persistent, pSyncCallTimeout As %Numeric = -1, pDescription As %String = "", ByRef pSendSyncHandling As %String) As %Status
{
    Return $$$OK
}

/// Verify SendSyncHandling instructions
/// If ClientRequestKey or ClientRetryRequestKey are longer than 128 or
/// empty strings then do not accept for SupportDelayedResponseForRequest
Method VerifySendSyncHandlingInstructions(ByRef pSendSyncHandling As %String) As %Boolean
{
    If $Data(pSendSyncHandling("SyncHandling","ClientRequestKey"),tClientRequestKey)#2 {
        If ($Length(tClientRequestKey)>128)||(tClientRequestKey="") Return 0
    }
    If $Data(pSendSyncHandling("SyncHandling","ClientRetryRequestKey"),tClientRetryRequestKey)#2 {
        If ($Length(tClientRetryRequestKey)>128)||(tClientRetryRequestKey="") Return 0 
    }

    Return 1
}

/// Subclass for the protocol specific handling of the return status.
/// Note the Client may not receive and this can be by design since
/// if the response is outstanding and still being processed we
/// want to avoid returning to the caller of SendRequestSync an error
/// as callers code flow cannot be known.
Method SetReturnStatusCode(pStatusGenericReason As %String, pStatusText As %String = "", ByRef pResponse) As %Status
{
    Return $$$OK
}

/// Subclass for the protocol
/// This is called when detect the original request is
/// still being processed and need to be able to handle
/// caller not handling empty response
Method OnHandleNoResponseYet() As %Status
{
 Return $$$OK
}

}
