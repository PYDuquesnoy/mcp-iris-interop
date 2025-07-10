/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.BusinessService Extends (Ens.Host, Ens.Util.IOLogger) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Used to be named %ProcessInputCalled, with inverse sense
Property %WaitForNextCallInterval As %Boolean [ InitialExpression = 1 ];

/// Deprecated - use %WaitForNextCallInterval
Property %ProcessInputCalled As %Boolean [ Calculated ];

/// Put all inputs from this service into a single session
Property %PreserveSession As %Boolean [ InitialExpression = 0 ];

Property %RequestHeader As Ens.MessageHeader;

Property %AlertStartTime As %Numeric [ InitialExpression = 0 ];

/// Store error from Service's ProcessInput() method - needed in SOAP adapter
Property %ProcessError As %Status [ Internal ];

/// When AlertOnError is True, refrain from alerting if it is not from ProcessInput() and the Service succeeds again within this number of seconds
Property AlertGracePeriod As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

/// IO device name if created by CreateBusinessService from a CSP TCP job
Property %OutsideCreated As %String;

/// If this setting is enabled then generate a Super Session ID.<br>
/// See method GenerateSuperSession() and user call back method OnGenerateSuperSession()in <CLASS>Ens.Host</CLASS> 
Property GenerateSuperSessionID As %Boolean [ InitialExpression = 0 ];

/// This is used to indicate if the %SuperSession has been created from the inbound request
/// and ought not to be cleared as part of %PreserveSession actions
Property %SuperSessionCreatedBeforeSession As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "GenerateSuperSessionID:Additional,AlertGracePeriod:Alerting";

Parameter APPDATAKEY As %String = "ProcessInputAsync";

/// This is the entry point for incoming data, called by InboundAdapters and external applications;
/// Calls the OnProcessInput method but in IRIS Interoperability SOAP services you may override it directly.
Method ProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status [ Internal ]
{
	Set $ZT="Trap",$EC="",tSC=$$$OK
	Kill pOutput  Set pOutput = $$$NULLOREF
	Do {
		#; re-register if production bounced between ProcessInput() calls from outside job instantiated service
		If (..Adapter=""||$G($$$EnsJobLocal("TCPIn.OutsideJob")))&&'$D($$$EnsJobStatus($$$SystemName,$J)) Set tSC = ##class(Ens.Job).Register(..%ConfigName,-1,0,$Job,"Xternal",$$$eJobStatusVisiting)  Quit:$$$ISERR(tSC)
		Do:$$$StatsShouldInit(..%ConfigName, $G(pInput)) ##class(Ens.Util.Statistics).InitStats(..%ConfigName)
		Set tSOAP=($this.%Extends("EnsLib.SOAP.Service") && $this.SOAPInvoked)
		Set ..%WaitForNextCallInterval=0
		Set:'tSOAP tSC=..preProcessInput()  Quit:$$$ISERR(tSC)
		Set tCreated='$IsObject(..IOLogEntry)
		$$$NEWINIOLOGENTRY($$$OK,"ProcessInput",pInput)
		Set $EC=""  try {
			Set tSC = ..OnProcessInput(.pInput,.pOutput,.pHint)
		} catch {
			Set tSC=$$$EnsSystemError
		}
		If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnProcessInput(); committing before proceeding")
		If $$$ISERR(tSC) {
			$$$sysTRACE("OnProcessInput() returned "_$$$StatusDisplayString(tSC)_", %QuitTask="_..%QuitTask_", %WaitForNextCallInterval="_..%WaitForNextCallInterval)
			Do:..Adapter=""||$G($$$EnsJobLocal("TCPIn.OutsideJob")) ..onOutsideErr(.tSC)
		} Else {
			Kill %objlasterror
			If ""'=$G(pOutput)||..%QuitTask||'..%WaitForNextCallInterval {
				$$$sysTRACE("returned OK from OnProcessInput(); Output="_$G(pOutput)_", %WaitForNextCallInterval="_..%WaitForNextCallInterval_", %QuitTask="_..%QuitTask)
			} Else {
				$$$catTRACE("ontask","Returned OK from OnProcessInput(); Output="_$G(pOutput)_", %WaitForNextCallInterval="_..%WaitForNextCallInterval_", %QuitTask="_..%QuitTask)
			}
		}
		If tCreated { $$$CLOSEIOLOGENTRY(tSC,"After ProcessInput",pOutput) }
		Else { $$$SAVEIOLOGENTRY(tSC,"After ProcessInput",pOutput) }
	} While 0
Exit
	Do ##class(Ens.Util.Statistics).RecordStats($$$eHostTypeService,..%ConfigName)
	Kill $$$JobSessionId
	Set ..%ProcessError=tSC  Kill %objlasterror
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method preProcessInput() As %Status [ Internal ]
{
	If (..Adapter=""||$G($$$EnsJobLocal("TCPIn.OutsideJob"))) && ##class(Ens.Job).ShouldBeQuiescent() {
		Quit $$$EnsError($$$EnsErrProductionQuiescent)
	}
	Set tConfigName=$$$DispatchNameToConfigName(..%ConfigName)
	If '$$$ConfigIsEnabled(tConfigName) {
		Quit $$$EnsError($$$EnsErrConfigDisabled,..%ConfigName)
	}
	If '..%PreserveSession {
		#; We do not want to clean %SuperSession if set before %SessionId
		If '..%SuperSessionCreatedBeforeSession  Set ..%SuperSession = ""
		Set ..%SessionId=""  Kill $$$JobSessionId
	}
	Set ..%ProcessError=""  Kill %objlasterror

	// update monitor & counter
	$$$IncHostCounterTime(tConfigName)
	$$$IncJobCounterTime(tConfigName,$$$SystemName_":"_$Job)
	Quit $$$OK
}

/// Do AlertOnError here if we are being called from an outside job and not in the OnTask loop of a job
Method onOutsideErr(ByRef pSC As %Status) [ Internal ]
{
#define BSRuntime(%s)	$$$EnsRuntimeAppData("BSOutsideErrors",..%ConfigName,%s)

	Set tDoAlert=..OnError(.pSC)
	Set tTxt=""
	If $$$ISERR(pSC) {
		Set tTxt=$P($$$StatusDisplayString(pSC)," -- ") // OnError might have changed it; strip off "logged as" varying text
		Set tLastReportedError=$G($$$BSRuntime("LastReportedError"))
		If tTxt'=tLastReportedError {
			$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
			$$$LOGSTATUS(pSC)
		} Else { Set tDoAlert=0 }
		Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(pSC))))
	}
	Set $$$BSRuntime("LastReportedError")=tTxt
}

/// Override this method to process incoming data. Do not call SendRequestSync/Async() from outside this method (e.g. in a SOAP Service or a CSP page).
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Use this method to dispatch a business invocation synchronously
Method SendRequestSync(pTargetDispatchName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pTimeout As %Numeric = -1, pDescription As %String = "", ByRef pSendSyncHandling As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tTimeCalled=$ZH
	Set tTargetConfigName = $G($$$DispatchNameToConfigName(pTargetDispatchName))  Quit:""=tTargetConfigName $$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)
	Set tTargetBusinessClass = $$$ConfigClassName(tTargetConfigName)

	#; If we need to generate a super session id and it is currently empty attempt to generate
	Set tSC = ..PopulateSuperSession()
	If $$$ISERR(tSC) Quit tSC

	#;%SessionId might have been generated via PopulateSuperSession
	Set tSessionId = ..%SessionId
	Set tSuperSession = ..%SuperSession
	Set:$IsObject(..%RequestHeader)&&(""=..%RequestHeader.TimeCreated) tRequestHeader=..%RequestHeader

	#; Use tRequestHeader variable passing by reference to include sync handling information to acceptRequestSync
	Merge tRequestHeader("SyncHandling")=pSendSyncHandling
	
	$$$SyncCommitSet(tSyncCommit)
	Set tSC=$classmethod(tTargetBusinessClass,"acceptRequestSync",..%ConfigName,tTargetConfigName,.pRequest,.pResponse,.tSessionId,pTimeout,.tRequestHeader,pDescription,.tSuperSession)
	$$$SyncCommitClear(tSyncCommit)
	If $G(tSessionId)'="" Set (..%SessionId,$$$JobSessionId)=tSessionId
	If $G(tSuperSession)'="" Set ..%SuperSession=tSuperSession
	#; Account possibility target was invoked InProc with non persistence enabled
	If $$$ISOK(tSC) && $$$IsdefObject(tRequestHeader) {
		Set ..%RequestHeader=tRequestHeader, $$$JobCurrentHeaderId=tRequestHeader.%Id()
	}
	
	#; If CSP job then set response HTTPHeader if %SuperSession not empty
	If (..%SuperSession'="") && (""'=..%OutsideCreated) && ($$$IsdefObject(%response)) {
		Try {
			Do %response.SetHeader($$$EnsHTTPHeaderSuperSession,..%SuperSession)
		} Catch {}
	}

	$$$catTRACE("timing","duration of sync call: "_($ZH-tTimeCalled))
	Quit tSC
}

/// Use this method to dispatch a business invocation asynchronously
Method SendRequestAsync(pTargetDispatchName As %String, pRequest As %Library.Persistent, pDescription As %String = "") As %Status
{
	#dim tSC As %Status = $$$OK
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tTimeCalled=$ZH
	Set tTargetConfigName = $G($$$DispatchNameToConfigName(pTargetDispatchName))  Quit:""=tTargetConfigName $$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)
	Set tTargetBusinessClass = $$$ConfigClassName(tTargetConfigName)

	#; If we need to generate a super session id and it is currently empty attempt to generate
	Set tSC = ..PopulateSuperSession()
	If $$$ISERR(tSC) Quit tSC
	
	#;%SessionId might have been generated via PopulateSuperSession
	Set tSessionId = ..%SessionId
	Set tSuperSession = ..%SuperSession
	Set:$IsObject(..%RequestHeader)&&(""=..%RequestHeader.TimeCreated) tRequestHeader=..%RequestHeader
	$$$SyncCommitSet(tSyncCommit)
	Set tSC=$classmethod(tTargetBusinessClass,"acceptRequestAsync",..%ConfigName,tTargetConfigName,.pRequest,$$$eMessagePriorityAsync,"",.tSessionId,"",.tRequestHeader,pDescription,.tSuperSession)
	$$$SyncCommitClear(tSyncCommit)
	If $G(tSessionId)'="" Set (..%SessionId,$$$JobSessionId)=tSessionId
	If $G(tSuperSession)'="" Set ..%SuperSession=tSuperSession
	#; Account possibility target was invoked InProc with non persistence enabled
	If $$$ISOK(tSC) && $$$IsdefObject(tRequestHeader) {
		Set ..%RequestHeader=tRequestHeader, $$$JobCurrentHeaderId=tRequestHeader.%Id()
	}
	
	#; If CSP job then set response HTTPHeader if %SuperSession not empty
	If (..%SuperSession'="") && (""'=..%OutsideCreated) && ($$$IsdefObject(%response)) {
		Try {
			Do %response.SetHeader($$$EnsHTTPHeaderSuperSession,..%SuperSession)
		} Catch {}
	}

	$$$catTRACE("timing","duration of async call: "_($ZH-tTimeCalled))
	Quit tSC
}

/// Override this method to provide custom error handling. Return 0 means skip standard AlertOnError behavior.
Method OnError(pStatus As %Status) As %Boolean
{
	Quit 1
}

/// Use this method to send an alert message
Method SendAlert(pAlertRequest As Ens.AlertRequest) As %Status
{
	#dim tSC As %Status = $$$OK
	
	If (""=$G($$$DispatchNameToConfigName("Ens.Alert"))) {
		$$$LOGALERT(pAlertRequest.AlertText)
	} Else {
		Do pAlertRequest.%Save()
		$$$LOGALERT(pAlertRequest.AlertText_" (alert request ID="_pAlertRequest.%Id()_")")
		Set tSC = ..SendRequestAsync("Ens.Alert",pAlertRequest)
	}
		
	Quit tSC
}

/// This is called only for BusinessService classes that are in polling mode; BusinessService
///  classes invoked externally via CSP, SOAP, or a language binding do not use OnTask().
Method OnTask() As %Status [ Internal ]
{
	Set $ZT="Trap",$EC="",tSC=$$$OK
	Do {
		If '..%WarnedLatest&&'..%ClassIsLatestVersion() {
			$$$LOGWARNING("Service Class "_$classname()_" has been recompiled; continuing to run using code from previous version")
			Set ..%WarnedLatest=1
		}
		If $IsObject(..Adapter)&&'..Adapter.%WarnedLatest&&'..Adapter.%ClassIsLatestVersion() {
			$$$LOGWARNING("Adapter Class "_$classname(..Adapter)_" has been recompiled; continuing to run using code from previous version")
			Set ..Adapter.%WarnedLatest=1
		}
		$$$ASSERT($IsObject(..Adapter)) ; Must have an Adapter to call OnTask()
		Set tTimeCalled = $ZH
		Set ..%WaitForNextCallInterval=1
		Set tSBQ=##class(Ens.Job).ShouldBeQuiescent()
		If ..ThrottleDelay>0&&'tSBQ {
			Set tRemaining=..ThrottleDelay/1000, t0=$ZH
			$$$catTRACE("ontask","hanging for "_(..ThrottleDelay/1000)_" ThrottleDelay seconds")
			While tRemaining>0&&'tSBQ {
				If tRemaining<5 { Hang tRemaining  Set tRemaining=0 } 
				Else { Hang 5  Set tNow=$ZH, tRemaining = t0+tRemaining-tNow, t0=tNow}
				Set tSBQ=##class(Ens.Job).ShouldBeQuiescent()
			}
		}
		If tSBQ {
			$$$sysTRACE("Adapter's OnTask() not called because system is quiescent")
			Set tSC = ##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,-1,,1)
		} Else {
			$$$catTRACE("ontask","calling adapter's OnTask()")
			Set tSC=..Adapter.OnTask()
			Set:('..%WaitForNextCallInterval)||('..%LastActionTime) tNow=$ZH, ..%LastActionTime=tNow, ..%LastHandledTime=tNow
			Set tTxt=$S($$$ISERR(tSC):$P($$$StatusDisplayString(tSC)," -- "), 1:"") ; strip off "logged as" varying text
			If (tTxt'=""&&(tTxt'=..%LastReportedError))||'..%WaitForNextCallInterval||..%QuitTask {
				$$$sysTRACE("returned from adapter's OnTask() : "_tTxt_", %WaitForNextCallInterval="_..%WaitForNextCallInterval_", %QuitTask="_..%QuitTask )
			} Else {
				$$$catTRACE("ontask","returned from adapter's OnTask() : "_tTxt_", %WaitForNextCallInterval="_..%WaitForNextCallInterval_", %QuitTask="_..%QuitTask )
			}
			If $$$ISERR(tSC) {
				Set tDoAlert=..OnError(.tSC)
				If $$$ISERR(tSC) {
					Set tTxt=$P($$$StatusDisplayString(tSC)," -- ") // OnError might have changed it; strip off "logged as" varying text
					Set:'..%AlertStartTime&&..AlertOnError&&..AlertGracePeriod&&(tTxt'=..%LastReportedError) ..%AlertStartTime=$ZH
					If ..%AlertStartTime&&tDoAlert {
						If $ZH>=(..%AlertStartTime+..AlertGracePeriod) {
							Set ..%AlertStartTime=0
							If tTxt'=..%LastReportedError {
								$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
								$$$LOGERROR("Alerting at expiration of retry grace period ("_..AlertGracePeriod_") for "_tTxt)
							} Else { $$$LOGINFO("Alerting at expiration of retry grace period ("_..AlertGracePeriod_") for "_tTxt) }
						} Else {
							Set tDoAlert=0
							If tTxt'=..%LastReportedError {
								$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
								$$$LOGERROR("Not Alerting during retry grace period ("_..AlertGracePeriod_") for "_tTxt)
							} Else { $$$LOGINFO("Not Alerting during retry grace period ("_..AlertGracePeriod_") for "_tTxt) }
						}
					} Else {
						If tTxt'=..%LastReportedError {
							$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
							$$$LOGSTATUS(tSC)
						} Else { Set tDoAlert=0 }
					}
					Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSC))))
				} Else { Set ..%AlertStartTime=0, tTxt="" }
				Set ..%LastReportedError=tTxt
				If '..%QuitTask Set tSC=$$$OK $$$catTRACE("ontask","Ignoring error from OnTask()") ; Don't break the OnTask() loop except when %QuitTask is set
			} Else { Set ..%AlertStartTime=0, tTxt="" }
			Set ..%LastReportedError=tTxt
			$$$CLOSEIOLOGENTRY(tSC,"After OnTask",$$$NULLOREF)
			Set ..%RequestHeader = $$$NULLOREF
			Quit:'..%WaitForNextCallInterval||..%QuitTask
			Set tCallInterval = ..Adapter.CallInterval  Set:tCallInterval<1 tCallInterval=1
			#;DeQueue rounds up to second so subtract a 1/10th so that a fraction of a < 1/10th does not become an extra second.
			Set tNow=$ZH, tWaitK=-1,(tWait,tWaitCall)=((tCallInterval-(tNow-tTimeCalled))-.1)
			If ..Adapter.KeepaliveInterval>0&&..%LastActionTime {
				Set tWaitK=..Adapter.KeepaliveInterval  Set:tWaitK<=0 tWaitK=-1
				If tWaitK>0 {
					Set tWaitK=tWaitK-(tNow-..%LastActionTime)  Set:tWaitK<0 tWaitK=0
					Set:tWait>tWaitK tWait=tWaitK, tWaitK=0, tWaitCall=tWaitCall-tWait
				}
			}
			#; wait the shorter of keepalive wait or CallInterval
			Set:tWait>0 tSC = ##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,tWait,,0)
			If 'tWaitK {
				Quit:$$$ISERR(tSC)  Set tSC=..Adapter.OnKeepalive(), ..%LastActionTime=$ZH  Quit:$$$ISERR(tSC)||'..%WaitForNextCallInterval||..%QuitTask
				#; if keepalive wait was shorter, wait the rest of CallInterval now.
				Set:tWaitCall>0 tSC = ##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,tWaitCall,,0)
			}
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod GetRequestClassList() As %String [ CodeMode = objectgenerator, GenerateAfter = OnProcessInput, Internal ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnProcessInput",$$$cMETHformalspecparsed)
	Set tClass=$lg($lg(tSignature,1),2)
	Do %code.WriteLine(" Quit $LB("""_tClass_""")")
	Quit $$$OK
}

ClassMethod GetResponseClassList(pRequest As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = OnProcessInput, Internal ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnProcessInput",$$$cMETHformalspecparsed)
	Set tRequestClass=$lg($lg(tSignature,1),2)
	Set tClass=$lg($lg(tSignature,2),2)
	Do %code.WriteLine(" If pRequest=""""||(pRequest="""_tRequestClass_""") Quit $LB("""_tClass_""")")
	Do %code.WriteLine(" Quit """"")
	Quit $$$OK
}

Method %ProcessInputCalledGet() As %Boolean [ CodeMode = expression, Internal ]
{
'i%%WaitForNextCallInterval
}

Method %ProcessInputCalledSet(val) As %Status [ Internal ]
{
	Set i%%WaitForNextCallInterval='val
}

/// ProcessInput in a background job ...
/// If a Response is provided use CheckProcessInputAsyncStatus to retrieve the Response object.
ClassMethod CallProcessInputAsync(pConfigName As %String, pRequest As %Persistent, ByRef pRequestId As %String, pDelay As %Numeric = 0) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Try {
		Set tSC = pRequest.%Save()
		Quit:$$$ISERR(tSC)
		Set tOid = pRequest.%Oid()
		// Grab a new request id in order to log response
		Set pRequestId = $INCREMENT($$$EnsRuntimeAppData("ProcessInputAsync"))
		Set $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"request")=tOid
		Set $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"service")=pConfigName
		// Record date so that it can be purged if synchronous and response not checked.
		Set $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"date")=$P($H,",")
		// Start the job
		Job ##class(Ens.BusinessService).backgroundJob(pRequestId,pDelay)::5
		If '$TEST {
			Set tSC=$$$EnsError($$$EnsErrJobFailed,pConfigName)
			// Clean up ...
			Kill $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId)
			Quit
		}
		// Now we're done ... call CheckProcessInputAsyncStatus(pRequestId,.tResponse) to follow up
	} Catch e {
		Set tSC=$$$EnsSystemError
	} 
	Quit tSC
}

/// Check the status of a pending CallProcessInputAsync() operation
/// pResponse will be returned as the response generated as a result of a previous call using CallProcessInputAsync
/// provided the business service invoked returned a response. 
/// The return status will be an error if an error was encountered or returned by the business service.
/// pSessionId is the session created by the business service called. 
/// If a response is expected for a qiven request then it may be necessary to call this method a number of times.
/// When a response or error is returned this method will clean up temporary data if pRemoveTempData is true (default is true)
/// and hence it is necessary to record the response/error and if necessary the session ID.
/// Cleanup of tempdata not automatically cleaned up can be done using PurgeProcessInputAsyncTempData method.
ClassMethod CheckProcessInputAsyncStatus(pRequestId As %String, ByRef pResponse As %Persistent, ByRef pSessionId As %String, pRemoveTempData As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Try {
		Set pResponse = $$$NULLOREF, pSessionId = ""
		// Check for our global
		If '$DATA($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId)) {
			Set tSC = $$$EnsError($$$EnsErrNoResponseClass,"<<"_pRequestId_">>")
			Quit
		}
		// Now, check either for an error or completion
		Set tSC = $G($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"error"),$$$OK)
		Quit:$$$ISERR(tSC)  // Error!
		// Check for completion of the message ...
		If $DATA($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"response")) {
			Set tOid = $G($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"response"))
			Set pSessionId = $G($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"session"))
			If tOid'="" {
				// Open the response object
				Set pResponse = ##class(%Persistent).%Open(tOid,,.tSC)
			} Else {
				// We got no response ... report error and session if recorded.
				// If there is no error, default to one ...
				Set tSC = $$$EnsError($$$EnsErrNoMsgBody,$S(pSessionId'="":pSessionId,1:"<<"_pRequestId_">>"))
			}
		}
	} Catch e {
		Set tSC=$$$EnsSystemError
	}
	#;	Remove temp data if either errored or response written. 
	If pRemoveTempData,('tSC||$IsObject(pResponse)) Kill $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId)
	Quit tSC
}

/// Background job entry point for calling ProcessInput in the background
ClassMethod backgroundJob(pRequestId As %Integer, pDelay As %Numeric = 0) [ Internal ]
{
	Set tSC=$$$OK
	Try {
		#dim tService As Ens.BusinessService
		Set tRequest = $$$NULLOREF
		Set tResponse = $$$NULLOREF
		// Check for our global
		If '$DATA($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId)) {
			Set tSC = $$$EnsError($$$EnsErrNoResponseClass,"<<Session:"_pRequestId_">>")
			Quit
		}
		// Wait if there's any delay requested (e.g. for the production to start)
		If pDelay>0 Hang pDelay
		Set tOid = $G($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"request"))
		Set tConfigName = $G($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"service"))
		// Open our request
		Set tRequest = ##class(%Persistent).%Open(tOid,,.tSC)
		Quit:$$$ISERR(tSC)
		// Create the business service
		Set tSC = ##class(Ens.Director).CreateBusinessService(tConfigName,.tService)
		Quit:$$$ISERR(tSC)
		// Process the input (synchronously ...) and store the session id
		Set tSC = tService.ProcessInput(tRequest,.tResponse)
		Set $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"session") = tService.%SessionId
		Quit:$$$ISERR(tSC)
		If $IsObject($G(tResponse)) {
			// Save the response!
			Set tSC = tResponse.%Save()
			Quit:$$$ISERR(tSC)
			// And store the response OID for retrieval
			Set tOid = tResponse.%Oid()
		} Else {
			// We got no response
			Set tOid = ""
		}
		// Store the Oid for the response (if any)
		Set $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"response") = tOid
	} Catch e {
		Set tSC=e.AsStatus()
	}
Exit
	If $$$ISERR(tSC) {
		If $DATA($$$EnsRuntimeAppData("ProcessInputAsync",pRequestId)) {
			Set $$$EnsRuntimeAppData("ProcessInputAsync",pRequestId,"error")=tSC
		}
		// Log this with IRIS
		$$$LOGSTATUS(tSC)
	} Else {
		Try { 
			#; Cleanup RuntimeAppData if the BS sent Async or the BS did not send the message on (null SessionId) nor did it create a response.
			If (tOid=""),((tService.%SessionId="")||(##class(Ens.MessageHeader).%OpenId(tService.%SessionId).Priority=$$$eMessagePriorityAsync)) Kill:$$$EnsRuntimeAppData("ProcessInputAsync",pRequestId)
		} Catch e {}
	}
	Quit
}

ClassMethod PurgeProcessInputAsyncTempData(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7) As %Status [ Internal ]
{
	Set tSC = $$$OK, pDeletedCount=0, tRequestId="",pDaysToKeep=$S(pDaysToKeep<0:0,1:pDaysToKeep)
	Set tDoNotDeleteDate = $H-pDaysToKeep+1
	Set tRequestId=$O($$$EnsRuntimeAppData("ProcessInputAsync",tRequestId))
	Try {
		While (tRequestId'="") {
			If ($G($$$EnsRuntimeAppData("ProcessInputAsync",tRequestId,"date"),($H+1)) < tDoNotDeleteDate) { 
				Kill $$$EnsRuntimeAppData("ProcessInputAsync",tRequestId)
				Set pDeletedCount=$I(pDeletedCount), tRequestId=$O($$$EnsRuntimeAppData("ProcessInputAsync",tRequestId))
			} Else { Set tRequestId = ""}
		}
	} Catch e { Set tSC = e.AsStatus()}
	Quit tSC
}

/// Pre-allocate a request header object and an ID to represent a fresh session.
/// When the next message is sent (that is, when SendRequestSync() or SendRequestAsync() is next called), it will use this pre-allocated header.
Method ForceSessionId() As %Status
{
	If ..%SessionId'="" Quit $$$OK
	Set ..%RequestHeader = ##class(Ens.MessageHeader).%New()
	Set (..%SessionId, $$$JobSessionId, $$$JobCurrentHeaderId) = ..%RequestHeader.MessageId()
	Quit $$$OK
}

/// This user callback method is called from %OnClose()
Method OnTearDown() As %Status
{
	#; Need to UnRegister jobs that are created 'outside' IRIS
	If ""'=..%OutsideCreated {
		#dim tTraceDevice, tIO As %String
		#dim tOutsideCreated As %String = ..%OutsideCreated

		Do ##class(Ens.Job).UnRegister(..%ConfigName,$Job)

		#; Kill $$$EnsJobLocal, but make sure we retain trace device
		Set tTraceDevice = $get($$$JobTraceDevice)
		Kill $$$EnsJobLocal
		If (tTraceDevice '= "") Set $$$JobTraceDevice = tTraceDevice
		Set ..%OutsideCreated=""

		If 1'=tOutsideCreated {
			#; Turn back on <DISCONNECT>  mode and "external interrupts" from the webserver because IRIS is done and the job may get re-used by the CSP server
			#; These may have been disabled in OnPreSoap() or CreateBusinessService()
			try {
				Set tIO=$IO
				Use tOutsideCreated:(::"+D")
				Use:tIO'=tOutsideCreated tIO
			} catch {
			}
			try {
				Do $System.Util.SetInterruptEnable(1)
			} catch {
			}
			#;Interrupts are re-enabled and hence no more code since might not be executed.
		}
	}
	Quit $$$OK
}

/// Generate a Super Session ID if it is currently empty and setting to generate enabled.
Method PopulateSuperSession() As %Status
{
	#dim tSC As %Status = $$$OK
	If ..GenerateSuperSessionID && (..%SuperSession="") {
		If ..%SessionId="" {
			Set tSC = ..ForceSessionId()
			If $$$ISERR(tSC) Quit tSC
		}	
		Set ..%SuperSession = ..GenerateSuperSession(..%RequestHeader,.tSC)
	}
	Quit tSC
}

}
