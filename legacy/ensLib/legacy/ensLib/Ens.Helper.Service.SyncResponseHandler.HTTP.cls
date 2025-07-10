/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Helper.Service.SyncResponseHandler.HTTP Extends Ens.Helper.Service.SyncResponseHandler [ Abstract, System = 4 ]
{

/// Default Web Gateway timeout
Parameter DEFGWTIMEOUT = 60;

/// Adjustment to response timeout. 
/// Set to 90% round down to avoid having same time as response timeout.
/// 
Parameter TIMEOUTADJUSTMENT = 9;

/// Declares the expected timeout in seconds of the external TCP socket system. <br>
/// For incoming requests that come through an IRIS web application the expression 'IRIS' will make this
/// service use the IRIS web gateway timeout value found in the request headers.
/// Otherwise the default value will be 60 seconds. <br>
/// The minimum of the calculation of 90% of GatewayTimeout and 
/// 90% of the specified ClientResponseTimeout is used to determine how
/// long to wait for a delayed response process to complete to reduce the chance the
/// current client connection is no longer available should the response become available
/// and to also reduce the chance of the client disconnecting and retrying before
/// invocation queued requests have recorded delayed cross reference information. <br>
Property GatewayTimeout As %String [ InitialExpression = "IRIS" ];

/// This is the protocol specific mechanism to identify if
/// the client of the service has provided a unique key to 
/// identify the request and if the request is retry.<br>
/// A client response wait timeout may also be provided.<br>
/// If ResponseWaitTimeoutToUse is calculated to be 0 then delayed
/// response with retry will not be supported.
Method OnPopulateSendSyncHandling(pTargetDispatchName As %String, pRequest As %Library.Persistent, pSyncCallTimeout As %Numeric = -1, pDescription As %String = "", ByRef pSendSyncHandling As %String) As %Status
{
    Set tSC = $$$OK
    /* Look for Client Request (Retry) Key and Response Timeout */
    Try {
        If $$$IsdefObject(%request) {
            If %request.IsDefinedCgiEnv("ALL_RAW") {
                Set tRawHeaders = %request.GetCgiEnv("ALL_RAW")
                Set tRawLen = $L(tRawHeaders,$C(13,10))
                For tC = 1:1:tRawLen {
                    Set headerAndVal = $P(tRawHeaders,$C(13,10),tC)
                    Set lwrHeader = $ZCVT($ZSTRIP($P(headerAndVal,":",1),"<>W"),"L"), headerVal = $ZSTRIP($P(headerAndVal,":",2,*),"<>W")
                    If lwrHeader = $$$EnsHTTPHeaderClientRequestKeyLC {
                        Set pSendSyncHandling("ClientRequestKey") = headerVal
                    } ElseIf lwrHeader = $$$EnsHTTPHeaderClientRetryRequestKeyLC {
                        Set pSendSyncHandling("ClientRetryRequestKey") = headerVal
                    } ElseIf lwrHeader = $$$EnsHTTPHeaderClientResponseTimeoutLC {
                        Set pSendSyncHandling("ClientResponseTimeout") = headerVal
                    }
                }
            } Else {
                Set header=$O(%request.CgiEnvs("HTTP_"))
                While $E(header,1,5)="HTTP_" {
                    Set lwrHeader=$ZCVT($REPLACE($E(header,6,*),"_","-"),"L")
                    If lwrHeader = $$$EnsHTTPHeaderClientRequestKeyLC {
                        Set pSendSyncHandling("ClientRequestKey") = %request.GetCgiEnv(header)
                    } ElseIf lwrHeader = $$$EnsHTTPHeaderClientRetryRequestKeyLC {
                        Set pSendSyncHandling("ClientRetryRequestKey") = %request.GetCgiEnv(header)
                    } ElseIf lwrHeader = $$$EnsHTTPHeaderClientResponseTimeoutLC {
                        Set pSendSyncHandling("ClientResponseTimeout") = %request.GetCgiEnv(header)
                    }
                    Set header=$O(%request.CgiEnvs(header))
                }
            }
            Set pSendSyncHandling("TransportMechanism") = "WebGateway"
        } ElseIf $Data(%iaHeader) {
            /* Support SOAP/HTTP based TCP Adapter */
            Set header=$O(%iaHeader(""))
                While header'="" {
                Set lwrHeader=$ZCVT(header,"L")
                If lwrHeader = $$$EnsHTTPHeaderClientRequestKeyLC {
                    Set pSendSyncHandling("ClientRequestKey") = %iaHeader(header)
                } ElseIf lwrHeader = $$$EnsHTTPHeaderClientRetryRequestKeyLC {
                    Set pSendSyncHandling("ClientRetryRequestKey") = %iaHeader(header)
                } ElseIf lwrHeader = $$$EnsHTTPHeaderClientResponseTimeoutLC {
                    Set pSendSyncHandling("ClientResponseTimeout") = %iaHeader(header)
                }
                Set header=$O(%iaHeader(header))
            }
            Set pSendSyncHandling("TransportMechanism") = "Adapter"
        } ElseIf pRequest.%Extends("%Library.AbstractStream") {
            /* Support legacy Stream classes with Attributes array property */
            Set header=$O(pRequest.Attributes(""))
                While header'="" {
                Set lwrHeader=$ZCVT(header,"L")
                If lwrHeader = $$$EnsHTTPHeaderClientRequestKeyLC {
                    Set pSendSyncHandling("ClientRequestKey") = pRequest.Attributes(header)
                } ElseIf lwrHeader = $$$EnsHTTPHeaderClientRetryRequestKeyLC {
                    Set pSendSyncHandling("ClientRetryRequestKey") = pRequest.Attributes(header)
                } ElseIf lwrHeader = $$$EnsHTTPHeaderClientResponseTimeoutLC {
                    Set pSendSyncHandling("ClientResponseTimeout") = pRequest.Attributes(header)
                }
                Set header=$O(pRequest.Attributes(header))
            }
            Set pSendSyncHandling("TransportMechanism") = "Stream"
        }

        /*  Take as new request if ClientRequestKey defined
            Do not use if neither ClientRequestKey nor ClientRetryRequestKey
        */
        If $Data(pSendSyncHandling("ClientRequestKey")) {
            Kill pSendSyncHandling("ClientRetryRequestKey")
        } ElseIf '$Data(pSendSyncHandling("ClientRetryRequestKey")) {
            /* Abort delayed response handling */
            Kill pSendSyncHandling
            Quit
        }

        If ..OverrideClientResponseWaitTimeout > 0 {
            Set responseWaitTimeoutToUse = ..OverrideClientResponseWaitTimeout
        } Else {
            Set responseWaitTimeoutToUse = +$Get(pSendSyncHandling("ClientResponseTimeout"),0)
        }

        If (responseWaitTimeoutToUse > 0) {
            /* Reduce response wait timeout for internal use */
            set responseWaitTimeoutToUse = responseWaitTimeoutToUse*..#TIMEOUTADJUSTMENT\10

            /* Re-calculate response timeout based on gateway */
            If pSendSyncHandling("TransportMechanism") = "WebGateway" {
                Set gatewayTimeout = ..GatewayTimeout()*..#TIMEOUTADJUSTMENT\10
                If (gatewayTimeout>0) && (gatewayTimeout<responseWaitTimeoutToUse) Set responseWaitTimeoutToUse = gatewayTimeout
            }
            Set pSendSyncHandling("ResponseWaitTimeoutToUse")=responseWaitTimeoutToUse
        } Else {
            /*  Abort delayed response handling since neither client
                nor override setting identified when the client would timeout.
            */
            Kill pSendSyncHandling
            Quit
        }
    } catch {
        Set tSC = $$$EnsSystemError
        /* Abort delayed response handling */
        Kill pSendSyncHandling
    }

    Return tSC
}

Method GatewayTimeout() As %Integer
{
    Quit:"IRIS"=$ZCVT(..GatewayTimeout,"U") $S($$$IsdefObject(%request):%request.GatewayTimeout,1:..#DefGWTimeout)
    Quit:'..GatewayTimeout ..#DefGWTimeout
    Quit ..GatewayTimeout
}

/// Set HTTP Status code.
/// Note the Client may not receive and this can be by design since
/// if the response is outstanding and still being processed we
/// want to avoid returning to the caller of SendRequestSync an error
/// as callers code flow cannot be known.
/// 
Method SetReturnStatusCode(pStatusGenericReason As %String, pStatusText As %String = "", ByRef pResponse) As %Status
{
    #; Need OK.
    Set tSC = $$$OK

    Set tStatusCode = $Case(pStatusGenericReason,"ServerError":500,"ClientError":400,"Accepted":202,:200)

    If $$$IsdefObject(%response) {
        Set %response.Status = tStatusCode_" "_pStatusText
    } Else { 
        /*  Not a Web Gateway request
            Set sub-nodes of response oref;
            your Service class must detect these and incorporate them into its Adapter's response output
        */
        Set pResponse("ResponseCode") =  tStatusCode_" "_pStatusText
    }

    Return tSC
}

/// This is called when we believe the original request is
/// still being processed and we want to be able to handle
/// caller not handling empty response.
/// For HTTP we want to wait until this current client connection goes aways. 
/// Re-enable async detect.
/// Close connection if believe going on too long.
Method OnHandleNoResponseYet() As %Status
{
    /*
        Re-enable async disconnect detect and trap
        Sit in Ens.Dequeue so we know if we need to shutdown whilst waiting for client to go.
        Disable async disconnect.
    */
    Set tSC = $$$OK
    Set tReEnabledAsyncDisconnectDetect = 0 
    Set tIO=$IO
    /* Based on Ens.BusinessService::OnTearDown()
        Turn back on <DISCONNECT>  mode and "external interrupts" from the webserver so we can trap for async disconnect.
        These may have been disabled in OnPreSoap() or CreateBusinessService()
    */
    If $E(..%OutsideCreated,1,5)="|TCP|" {
        /* Wrap all in outer try/catch since may get a DISCONNECT after EXTERNAL before turn off interrupts again */
        Try {
            /* Trap for async disconnect since we are re-enabling */
            Try {
                /* Need to use Ens.Queue API before re-enabling async disconnect */
                /*  Cannot waiting on own Job number since Production framework will not close.
                    Will also be closed with system interrupt when Web Gateway times out.
                */
                /* Create the queue and the event */
                Set tSC = ##class(Ens.Queue).Create($$$queueSystemSignalQueueName)
                If $$$ISOK(tSC) {
                    Use ..%OutsideCreated:(::"+D")
                    Use:tIO'=..%OutsideCreated tIO
                    Do $System.Util.SetInterruptEnable(1)
                    Set tReEnabledAsyncDisconnectDetect = 1
                    /*  Sit waiting for client to disconnect or quiesce request from framework
                        We want to do core event waiting whilst async disconnect detect on
                    */
                    Set tMaxHoldingTimeBeforeThrowTimeoutError = -1
                    Set tSystemEventName = ##class(Ens.Queue).EventName($$$queueSystemSignalQueueName)
                    /* Clear any outstanding signals for this previously used job but limit iterations */
                    Set tLimitIterations = 0
                    While ($System.Event.Wait(tSystemEventName,0) && ($I(tLimitIterations)<10)) {}
                    $$$catTRACE("connwait","OnHandleNoResponseYet cleared "_tLimitIterations_" pre-existing signals for "_tSystemEventName)
                    Set tWaitReturn = $System.Event.Wait(tSystemEventName,tMaxHoldingTimeBeforeThrowTimeoutError)
                    $$$catTRACE("connwait","OnHandleNoResponseYet exited main wait on "_tSystemEventName_" with return "_tWaitReturn)
                } Else {
                    /* failed to create a queue to wait on so fall straight through to return an error */
                    Set tSC = $$$ERROR($$$EnsErrGeneral,"Failed to make a queue to wait on for gateway to time out")
                }
                /*  System framework interrupted us so continue to disable async disconnect detect
                    and return empty response to the object.
                    This could cause processing issues so return an error.
                    Leave connection as is rather than Close ..%OutsideCreated (would also need to trap for &&(ex.Name'="<NOTOPEN>"))
                    Will be returning $$$OK if get to here.
                */
            } Catch ex {
                $$$catTRACE("connwait","OnHandleNoResponseYet #1 trap error "_ex.Name)
                /* caught async disconnect or unexpected error */
                If ((ex.Name'="<EXTERNAL INTERRUPT>")&&(ex.Name'="<DISCONNECT>")) {
                    $$$LOGERROR("Unexpected error "_ex.Name_" waiting for client to disconnect while handling no response")
                    Set tSC = ex.AsStatus()
                } Else {
                    Set tSC = $$$ERROR($$$CSPTimeout)
                }
            }
            /* Based on Ens.Director::CreateBusinessService()
                turn off <DISCONNECT>  mode and "external interrupts" from the webserver
                wrapped in try/catch since we could get a DISCONNECT after an EXTERNAL INTERRUPT
            */
            If tReEnabledAsyncDisconnectDetect {
                Try {
                    Use ..%OutsideCreated:(::"-D")
                    Do $System.Util.SetInterruptEnable(0)
                    Use:tIO'=..%OutsideCreated tIO
                } Catch ex {
                    /* trapped device connect error but add to debug trace */
                    $$$catTRACE("connwait","Error "_ex.Name_" disabling DISCONNECT detect for device  "_..%OutsideCreated)
                }
            }
        } Catch ex {
            /* caught further  async disconnect or unexpected error */
            $$$catTRACE("connwait","OnHandleNoResponseYet #2 trap error "_ex.Name)
            If ((ex.Name'="<EXTERNAL INTERRUPT>")&&(ex.Name'="<DISCONNECT>")) {
                $$$LOGERROR("Unexpected error "_ex.Name_" waiting for client to disconnect while handling no response and interrupts enabled")
                Set tSC =  $$$ADDSC(tSC,ex.AsStatus())
            } Else {
                Set tSC =  $$$ADDSC(tSC,$$$ERROR($$$CSPTimeout))
            }
        }
    }
    /*  Need to return an error if stil connected so that the overridden SendRequestSync
        call can return an error and further processing of the request is stopped.
        (depends on the custom code).
        The expectation is that the current client is no longer connected.
        Code calling SendRequestSync() is expected to trap for UNDEFINED response
    */
    Do:$$$DoTrace ..isCallerWaiting()
    Set:$$$ISOK(tSC) tSC = $$$ERROR($$$EnsErrFailureTimeout,-1,"Delayed Synchronous Send  Interrupted", $$$CurrentClass)
    Return tSC
}

/// Checks if the caller's TCP socket is still open
/// for debug tracing.
/// 
Method isCallerWaiting() As %Boolean [ Internal ]
{
    Set tConnected = 0
    Set io=$IO
    try {
        If ($E($IO,1,5)'="|TCP|")&&($E(..%OutsideCreated,1,5)="|TCP|") {
            Use ..%OutsideCreated ; temporarily restore $IO to the saved TCP device if it's been changed
        }
        If ($E($IO,1,5)="|TCP|") {
            Set tConnected = $zu(189) ; find out if TCP device is active
        }
        $$$catTRACE("connwait","Socket "_$io_" connection detected = "_$S(tConnected:"true",1:"false"))
    } catch ex {
        /* trapped device connection error and add to debug trace */
        $$$catTRACE("connwait","Socket "_$io_" connection detection error = "_ex.Name)
    }
    Use io
    Quit tConnected
}

}
