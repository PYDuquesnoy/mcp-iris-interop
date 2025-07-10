/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Actor Extends Ens.Host [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Method OnInit() As %Status
{
	#; Warn if BP is not FIFO and wants to be able to disable itself
	If "Ens.Actor"=..%ConfigName {
		#; actor pool job - warn about all pool BPs
		Set another=0,tJ="" For { Set tJ=$$$OrderHostMonitor(..%ConfigName,"%Job",tJ) Quit:""=tJ  Continue:$$$SystemName_":"_$Job=tJ  Set another=1  Quit }
		If 'another {
			Set tProduction=##class(Ens.Config.Production).%OpenId($G($$$EnsRuntime("Name")),,.tSC)
			If $IsObject(tProduction) && '##class(Ens.Director).hasDisabledActorProcess(tProduction) {
				For i=tProduction.Items.Count():-1:1 { Set tItem=tProduction.Items.GetAt(i)
					If (tItem.BusinessType()=$$$eHostTypeProcess) && tItem.Enabled && (tItem.PoolSize=0) {
						If tItem.GetModifiedSetting("ReplyCodeActions",.tReplyCodeActions) && $$HasD($G(tReplyCodeActions)) {
							If tProduction.ActorPoolSize > 1 {
								$$$LOGWARNING("For Business Process '"_tItem.Name_"' with PoolSize=0 the ReplyCodeActions 'D' action in '"_tReplyCodeActions_"' will disable all BPs that share the Actor pool. Other BP instances may continue executing briefly because ActorPoolSize "_tProduction.ActorPoolSize_" is greater than 1.")
							} Else {
								$$$LOGWARNING("For Business Process '"_tItem.Name_"' with PoolSize=0 the ReplyCodeActions 'D' action in '"_tReplyCodeActions_"' will disable all BPs that share the Actor pool.")
							}
						}
					}
				}
			}
		}
	} Else {
		#; private BP pool - warn if not the first job to start
		Set another=0,tJ="" For { Set tJ=$$$OrderHostMonitor(..%ConfigName,"%Job",tJ) Quit:""=tJ  Continue:$$$SystemName_":"_$Job=tJ  Set another=1  Quit }
		If another {
			Set tReplyCodeActions=##class(Ens.Director).GetHostSettingValue(..%ConfigName,"ReplyCodeActions",.tSC)
			If $$$ISOK(tSC) && $$HasD(tReplyCodeActions) {
				$$$LOGWARNING("ReplyCodeActions 'D' action in '"_tReplyCodeActions_"' can only immediately stop all instances of this BusinessProcess if it is configured with PoolSize=1. Otherwise instances of this BP in other jobs may continue executing briefly.")
			}
		}
	}
	Quit ##super()

HasD(rca)
 	Set tHasD=0, nActions=$S(""=$ZStrip(tReplyCodeActions,"<>W"):0, 1:$L(tReplyCodeActions,","))
	For i=1:1:nActions { Set tType=$P(tReplyCodeActions,",",i)  Continue:""=tType
		Set tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
		If tAction["D" Set tHasD=1  Quit
	}
	Quit tHasD
}

/// MessageHeader handler (for Queued BPs only - for InProc BPs the BP's MessageHeaderHandler is called directly)
Method MessageHeaderHandler(pRequestHeader As Ens.MessageHeader, Output pResponseHeader As Ens.MessageHeader) As %Status [ Internal ]
{
#define BPRuntime(%s)	$$$EnsRuntimeAppData("BProcRetry",tBPKey,%s)
#define KillBPRuntime	Kill $$$EnsRuntimeAppData("BProcRetry",tBPKey)

 Set tSC=$$$OK, (tTimeCalled,tStartTime,tEndTime,tDoAlert)="", (tAborted,tTerminate)=0, $ZE=""
 #dim ex As %Exception.AbstractException
 Set $EC=""  try {
	Set tOldBP=$G($$$EnsJobLocal("%Process")), tActorConfigName=..%ConfigName, tBPConfigName=pRequestHeader.TargetConfigName

	#; We may quit and be called again many times during each retry, and we may be processing messages interleaved for various BP's;
	#; we will only come around here again when the BP is 'Completed' and needs to start a retry with a fresh instance
	While 1 { ; Retry "loop"
		If pRequestHeader.Type = $$$eMessageTypeRequest {
			Set tBPClass = $$$ConfigClassName(tBPConfigName)
			Set tBPKey=pRequestHeader.%Id()
			Kill %objlasterror
			Set tBP=$classmethod(tBPClass,"%New",tBPConfigName)
			If '$IsObject(tBP) Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to create instance of "_tBPClass_" BP '"_tBPConfigName_"'"_$S($D(%objlasterror)#2:" : "_$$$StatusDisplayString(%objlasterror),1:""))  Quit
			If $$$DoTrace {
				$$$unconditionalSysTRACE("Starting Business Process '"_tBPConfigName_"' of class "_tBPClass_" "_$S('$G($$$BPRuntime("RetryCount")):"",1:"try #"_$$$BPRuntime("RetryCount")_" of ")_"message "_pRequestHeader.%Id()_"; %MasterPendingResponses contains "_tBP.%MasterPendingResponses.Count()_" element(s)",tShowCat)
				Do:tShowCat tBP.catTraceCompletionKeys()
			}
			Set tSettingName="" For  {
				Set tSettingName=$O($$$ConfigSetting(tBPConfigName,"Host",tSettingName))  Quit:tSettingName=""
				Set tValue=$$$ConfigSetting(tBPConfigName,"Host",tSettingName)
				Do tBP.AssignOneSetting(tSettingName,tValue,$$$CurrentClass)
			}
			Set (tTimeCalled,$$$BPRuntime("TimeCalled")) = $ZH
			Set tEndTime=$G($$$BPRuntime("EndTime"))
			Set:'tEndTime (tEndTime,$$$BPRuntime("EndTime")) = tTimeCalled + tBP.FailureTimeout
		} Else {
			Set tBP=$classmethod("Ens.BusinessProcess","%OpenId",pRequestHeader.BusinessProcessId,4,.tSC)
			#; If tBP is no longer there it's the same as being completed, so just mark the message discarded
			If '$IsObject(tBP) {
				If $$$StatusEquals(tSC,$$$LoadObjectNotFound) {
					$$$catTRACE("bproc","Discarding response message '"_pRequestHeader.%Id()_"' for missing instance "_pRequestHeader.BusinessProcessId_" of BP '"_tBPConfigName_"' of class "_$$$ConfigClassName(tBPConfigName))
				} ElseIf $$$StatusEquals(tSC,$$$LockFailedToAcquireExclusive) {
					Set $$$JobSessionId = pRequestHeader.SessionId
					$$$LOGWARNING("Putting response message '"_pRequestHeader.%Id()_"' back on queue for instance "_pRequestHeader.BusinessProcessId_" of BP '"_tBPConfigName_"' of class "_$$$ConfigClassName(tBPConfigName)_" that failed to load with error "_$$$StatusDisplayString(tSC))
					/* Overwrite error with put back to queue return status */
					Set tSC=##class(Ens.Queue).PutBackToQueue(pRequestHeader)
					Quit
				} ElseIf ""=pRequestHeader.BusinessProcessId {
					$$$LOGERROR("Discarding response message '"_pRequestHeader.%Id()_"' for BP '"_tBPConfigName_"' of class "_$$$ConfigClassName(tBPConfigName)_" because it contained no BP instance ID")
				} Else {
					$$$LOGWARNING("Discarding response message '"_pRequestHeader.%Id()_"' for instance "_pRequestHeader.BusinessProcessId_" of BP '"_tBPConfigName_"' of class "_$$$ConfigClassName(tBPConfigName)_" that failed to load with error "_$$$StatusDisplayString(tSC))
				}
				Do pRequestHeader.SetStatus($$$eMessageStatusDiscarded)
				Set tSC=$$$OK
				/*
					Ask ScheduleHandler to check if the missing BP thread is the ScheduleHandler.
					We do not have SendRequestAsync() so we need to job off CallScheduleService since we cannot create a business service from within a host item
				*/
				If tBPConfigName = "Ens.ScheduleHandler" {
					Job ##class(Ens.ScheduleService).CallScheduleService()::5
					If '$Test {
						#; Return error since system critical if cannot job off.
						Set tSC = $$$ERROR($$$EnsErrGeneral,$$$Text("Timed out trying to job off process to notify Scheduler"))
					} Else {
						Set tMissingBPErrorText = $$$Text("Sent request to ScheduleHandler to check for production differences due to missing BP instance.")
						$$$LOGWARNING(tMissingBPErrorText)
					}	
				}
				Quit
			}
			Try {
				Set tBPKey=tBP.%PrimaryRequestHeader.%Id()
			} Catch ex {
				If ex.Name="<INVALID OREF>" {
					/*	If here then we know %PrimaryRequestHeader does not exist
						so recreate if for the ScheduleHandler otherwise handle cleanly.
					*/
					Set tBP.%PrimaryRequestHeader=$$$NULLOREF, tSC = $$$OK
					#dim tWarningText As %String =""
					Try {
						If $classname(tBP)="Ens.ScheduleHandler" {
							Set tBP.%PrimaryRequestHeader=tBP.recreatePrimaryRequestHeader(pRequestHeader,.tSC,.tWarningText)
						}
					} Catch {}
					/* 	If still no primary request header or 
						the recreatePrimaryRequestHeader call returned an error
					*/
					If (tBP.%PrimaryRequestHeader=$$$NULLOREF)||($$$ISERR(tSC)) {
						Do pRequestHeader.SetStatus($$$eMessageStatusDiscarded)
						/* Assign a tBPKey in case BP could be marked as completed */
						Set tBPKey=pRequestHeader.%Id()
						Set $$$JobSessionId = pRequestHeader.SessionId
						If $$$ISOK(tSC) {
							Set tWarningText=$$$FormatText($$$Text("Discarding response message '%1' for BP '%2' (id=%3) because primary request header has been purged."),pRequestHeader.%Id(),tBPConfigName,tBP.%Id())
							Set tSC=$$$ERROR($$$EnsErrGeneral,tWarningText)
						}
						Quit
					} Else {
						If tWarningText'="" {
							Set $$$JobSessionId = pRequestHeader.SessionId
							$$$LOGWARNING(tWarningText)
						}
						Set tSC = tBP.%PrimaryRequestHeader.%Save()
						$$$ThrowOnError(tSC)
						Set tBPKey=tBP.%PrimaryRequestHeader.%Id()
					}
				} Else {
					Throw ex
				}
			}
			#;Primary request header was removed and trapped above.
			If tBP.%PrimaryRequestHeader=$$$NULLOREF {
				#; Remove instance monitor and Quit out of Retry "loop"
				Set tBPId = tBP.%Id()
				$$$KillHostMonitor(tBPConfigName,$$$eMonitorJob,tBPId)
				$$$KillJobMonitor(tBPId)
				Quit
			}
		}
		Set ($$$EnsJobStatus($$$SystemName,$Job,$$$eJobGuestConfigName), $$$EnsJobLocal("GuestConfigName"))=tBPConfigName
		Set $$$EnsJobLocal("%Process")=tBP 
		Do ##class(Ens.Util.Trace).SetTraceOptimizer()
		If $$$DoTrace {
			$$$unconditionalCatTRACE("bproc","Begin processing message "_pRequestHeader.%Id()_"; %MasterPendingResponses contains "_tBP.%MasterPendingResponses.Count()_" element(s)",tShowCat)
			Do:tShowCat tBP.catTraceCompletionKeys()
		}

		Set tSC=tBP.MessageHeaderHandler(pRequestHeader,.pResponseHeader,.tHandledError) ; Sets SessionId, we clear it

		If tBP.%RepliedStatus=$$$eRepliedStatusConstructed {
			Set pResponseHeader=tBP.%PrimaryResponseHeader, tBP.%PrimaryResponseHeader=$$$NULLOREF
			Set tBP.%RepliedStatus=$$$eRepliedStatusSent
		}
		Set tBP.%StatusCode=tSC
		If $$$ISERR(tSC) {
			If ""=tHandledError { ; OnError() hasn't been called yet
				$$$catTRACE("bproc","calling OnError 1")
				Set $EC=""  try {
					Set tSC=tBP.OnError($$$NULLOREF,$$$NULLOREF,$$$NULLOREF,tSC,"")
				} catch {
					Set tSC=$$$ADDSC(tSC,$$$EnsSystemError)
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after BP OnError() 1; committing before proceeding")
				Set tDoAlert=$$$ISERR(tSC)
			} Else {
				Set tDoAlert=tHandledError
			}
		}
SaveExit
		If $$$ISERR(tSC) {
			If tBP.%RepliedStatus=$$$eRepliedStatusNotCalled {
				Set tSC2=tBP.%PrimaryRequestHeader.NewErrorResponse(.pResponseHeader,tSC)  If $$$ISERR(tSC2) {
					$$$LOGSTATUS(tSC2)
					Set tSC=$$$ADDSC(tSC2,tSC)
				}
				Set tBP.%response=$$$NULLOREF ,tBP.%PrimaryResponseHeader=$$$NULLOREF
				Set tBP.%RepliedStatus=$$$eRepliedStatusSent
			} Elseif tBP.%RepliedStatus=$$$eRepliedStatusConstructed {
				Set pResponseHeader=tBP.%PrimaryResponseHeader, tBP.%PrimaryResponseHeader=$$$NULLOREF
				Set tBP.%RepliedStatus=$$$eRepliedStatusSent
			} Else {
				#; nothing to do if tBP.%RepliedStatus=$$$eRepliedStatusSent
			}
			Set tBP.%IsCompleted=1, tBP.%TimeCompleted = $$$timeUTC
		}
		#;Don't Save if completed and we will be deleting
		#;^Ens.Configuration("bp","RetainCompletedInstances") is moved to ^Ens.Config("bp","RetainCompletedInstances") on upgrade
		If ('tBP.%IsCompleted)||$G($$$EnsConfig("bp","RetainCompletedInstances")) {
			If '$G(tSaveFailed) {
				Set tSC3=tBP.%Save() If $$$ISERR(tSC3) {
					$$$LOGSTATUS(tSC3)
					Set tSaveFailed=1, tSC=$$$ADDSC(tSC3,tSC)
					Set tBP.%StatusCode=tSC
					GoTo SaveExit
				}
			} Else {
				#; Try to save BP with only status and state changes
				Set ttId=tBP.%Id()
				Set tRepliedStatus = tBP.%RepliedStatus
				 , tPrimaryResponseHeader = tBP.%PrimaryResponseHeader
				 , tRepliedStatus = tBP.%RepliedStatus
				 , tIsCompleted = tBP.%IsCompleted
				 , tTimeCompleted = tBP.%TimeCompleted

				&sql(UPDATE Ens.BusinessProcess
					 SET %RepliedStatus = :tRepliedStatus
					 , %PrimaryResponseHeader = :tPrimaryResponseHeader
					 , %IsCompleted = :tIsCompleted
					 , %TimeCompleted = :tTimeCompleted
					 WHERE %ID = :ttId)
			}
		}
		If $$$DoTrace {
			$$$unconditionalCatTRACE("bproc","Exit BP "_pRequestHeader.%Id()_"; %MasterPendingResponses contains "_tBP.%MasterPendingResponses.Count()_" element(s)",tShowCat)
			Do:tShowCat tBP.catTraceCompletionKeys()
		}

		#; Do global stats (for Actor)
		$$$IncHostCounterTime(tActorConfigName)

		#; local stats (for Actor)
		$$$IncJobCounterTime(tActorConfigName,$$$SystemName_":"_$Job)

		If pRequestHeader.Type = $$$eMessageTypeRequest {
			#; Do global stats (for BusinessProcess)
			$$$IncHostCounterTime(tBPConfigName)
		}
		#; Update stats for BP instance
		Set tBPId = tBP.%Id()
		If ""'=tBPId {  ; tBPId can be empty if tBP.%Save() failed or we are not saving if completed
			If (tBP.%IsCompleted) {
				#; remove completed BP instance if so specified
				If '$G($$$EnsConfig("bp","RetainCompletedInstances")) {
					Set tBPDeleteSC = tBP.%DeleteId(tBPId)
					If $$$ISERR(tBPDeleteSC) {
						$$$LOGERROR("BP completion cleanup error deleting BP instance Id: "_tBPId_ ", " _ $SYSTEM.Status.GetErrorText(tBPDeleteSC))
						#; save BP so can keep it marked as completed for manual resolution
						Set tBPSaveSC=tBP.%Save() If $$$ISERR(tBPSaveSC) {$$$LOGSTATUS(tBPSaveSC)}
					}
				}

				#; Remove instance monitor
				$$$KillHostMonitor(tBPConfigName,$$$eMonitorJob,tBPId)
				$$$KillJobMonitor(tBPId)
			} Else {
				If pRequestHeader.Type = $$$eMessageTypeRequest {
					$$$IncJobCounterTime(tBPConfigName,tBPId) ; count all requests to this BP
				} Else {
					$$$SetJobMonitor(tBPConfigName,tBPId,$$$eMonitorStatus,"OK")
				}
				$$$RegisterHostMonitorJob(tBPConfigName,tBPId)
			}
		}
		Quit:'tBP.%IsCompleted&&$$$ISOK(tSC) ; Quit retry loop and continue BP processing if BP not Completed

		Set pRequestHeader=tBP.%PrimaryRequestHeader, $$$JobCurrentHeaderId=pRequestHeader.%Id() ; reset to the starting Request message in case we will retry
		/*
			Guard against failure to open message body.
			tRequest is expected to be an object in OnGetReplyAction
			and doReplyAction
		*/
		Try {
			Set tRequest=tBP.%request, tResponse=tBP.%response
		} Catch exOpen {
			Set tSC = $$$ADDSC(tSC,exOpen.AsStatus())
		}

		Set $EC=""  try {
			Set tMHSC=tSC
			#; tRequest is passed in by reference as well as tResponse to handle system failure where tRequest is not defined
			Set tAction=tBP.OnGetReplyAction(.tRequest,.tResponse,.tSC)
			Set:""'=tAction tSC=tBP.doReplyAction(tAction,.tRequest,.tResponse,tSC)
			If tSC'=tMHSC&&$$$ISERR(tSC) {
                $$$sysTRACE("calling OnError A")
                Set tSC=tBP.OnError($$$NULLOREF,$$$NULLOREF,$$$NULLOREF,tSC,"")
			}
		} catch {
			Set tSC=$$$ADDSC(tSC,$$$EnsSystemError)
		}
		If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after ReplyAction OnError() A; committing before proceeding")
		Set:""=tDoAlert tDoAlert=$$$ISERR(tSC)
		Set:$$$ISERR(tSC)&&tBP.%IsCompleted tSC=$$$EMBEDSC($$$ERROR($$$EnsErrBPTerminated,tBPConfigName,tBP.%Id(),$$$StatusDisplayString(tSC)),tSC)

		If tBP.SuspendMessage {
			Set tSCSuspend=tSC
			Set tSC=$$$ERROR($$$EnsErrSuspending,pRequestHeader.%Id(),$$$StatusDisplayString(tSC))
			Quit
		}
		Quit:'tBP.Retry
		Set tBP.Retry=0

		Set:'tStartTime tStartTime=$G($$$BPRuntime("StartTime"))
		If $$$ISERR(tSC) {
			Set tTxt=$$cleanNum($P($$$StatusDisplayString(tSC)," -- ")) ; strip off "logged as" varying text and remove digits following a number sign
			Set:'$G($$$BPRuntime("%AlertStartTime"))&&tBP.AlertOnError&&tBP.AlertRetryGracePeriod&&(tTxt'=$G($$$BPRuntime("%LastReportedError"))) $$$BPRuntime("%AlertStartTime")=$ZH
			If $G($$$BPRuntime("%AlertStartTime")) {
				If $ZH>=($$$BPRuntime("%AlertStartTime")+tBP.AlertRetryGracePeriod) {
					Set $$$BPRuntime("%AlertStartTime")=0
					If tTxt'=$G($$$BPRuntime("%LastReportedError")) { $$$LOGERROR("Alerting at expiration of retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
					Else { $$$LOGINFO("Alerting at expiration of retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
				}
				Else {
					Set tDoAlert=0
					If tTxt'=$G($$$BPRuntime("%LastReportedError")) { $$$LOGERROR("Not Alerting during retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
					Else { $$$LOGINFO("Not Alerting during retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
				}
			} Else {
				If tTxt'=$G($$$BPRuntime("%LastReportedError")) { $$$LOGSTATUS(tSC) }
				Else { Set tDoAlert=0 }
			}
			Do:tDoAlert&&tBP.AlertOnError tBP.SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSC))))
		} Else { Set $$$BPRuntime("%AlertStartTime")=0, tTxt="" }
		Set $$$BPRuntime("%LastReportedError")=tTxt

		Set tFailureTimedOut=0
		If tBP.FailureTimeout'=-1 {
			Set tNow=$ZH
			Set:'tEndTime tEndTime=$G($$$BPRuntime("EndTime"))
			If tNow>tEndTime {
				Set tFailureTimedOut=1, tSC=$$$ERROR($$$EnsErrFailureTimeout, tBP.FailureTimeout, $$$StatusDisplayString(tSC), $$$CurrentClass)
				Set $EC=""  try {
					Set tDoDefault=tBP.OnFailureTimeout(.tRequest,.tResponse,.tSC)
					Set:tDoDefault tSC=$S(""=tAction:tSC,1:tBP.finalReplyAction(tAction,tSC,1))
				} catch {
					Set tSC=$$$ADDSC(tSC,$$$EnsSystemError)
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnFailureTimeout(); committing before proceeding")
				Set:""=tDoAlert tDoAlert=$$$ISERR(tSC)
				Set:tBP.SuspendMessage tSCSuspend=tSC
				Quit:'tBP.Retry
			}
		}
		$$$SetHostMonitor(tBPConfigName,$$$eMonitorStatus,"Retry")
		$$$SetHostMonitor(tActorConfigName,$$$eMonitorStatus,"Retry")

		Set:'tTimeCalled tTimeCalled=$G($$$BPRuntime("TimeCalled"))
		Set tWaitTime = tTimeCalled + tBP.RetryInterval - $ZH
		/*	If (tBP.%QuitTask&&tBP.Retry) then item requested to be disabled
			and we need to give time to receive the should terminate signal.
			Indefinite wait OK since we requested self terminate
			in Ens.BusinessProcess::finalReplyAction when setting
			..%QuitTask & ..Retry to 1 due to action = D
		*/
		Set tSC1=##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,$S((tBP.%QuitTask&&tBP.Retry):-1,tWaitTime<0:0, 1:tWaitTime),,0)  If $$$ISERR(tSC1) Set tSC=$$$ADDSC(tSC,tSC1)  Quit
		Set tTerminate=##class(Ens.Job).ShouldTerminate()
		Set tSBQ=##class(Ens.Job).ShouldBeQuiescent()
		If tSBQ || tTerminate {
			If pRequestHeader.Priority>$$$eMessagePrioritySync||tTerminate {
				Set tTerminate=1
				$$$LOGINFO("Retry loop exited due to shutdown request for message "_pRequestHeader.%Id()_" ; re-queueing"_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))
				Set tSC1=##class(Ens.Queue).PutBackToQueue(pRequestHeader)
				If $$$ISERR(tSC1) { Set tSC=$$$ADDSC(tSC1,tSC) }
				Else { If 'tFailureTimedOut Set tSC=$$$OK } ; blow away the original error
				Quit
			}
			$$$LOGINFO("Ignoring "_$S(tSBQ:"Quiescent",1:"Terminate")_" request while processing high priority (i.e. synchronous) request "_pRequestHeader.%Id())
		}
		If ##class(Ens.Job).ShouldAbort() {
			$$$LOGWARNING("Message "_pRequestHeader.%Id()_" aborted as requested by signal for job "_$J_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))
			Set tSC=$$$OK, tAborted=1
			Quit
		}
		If ##class(Ens.Job).ShouldSuspend() {
			$$$LOGWARNING("Message "_pRequestHeader.%Id()_" suspended as requested by signal for job "_$J_$S($$$ISOK(tSC):"", 1:" - original error: "_$$$StatusDisplayString(tSC)))
			Set tSC=$$$OK, tBP.SuspendMessage=1
			Quit
		}
		#; go around again to re-instantiate a new BP and retry it
		Set $$$BPRuntime("RetryCount")=$G($$$BPRuntime("RetryCount"),1)+1
		$$$sysTRACE("Retrying Request Header Id "_pRequestHeader.%Id()_" - try #"_$$$BPRuntime("RetryCount"))
	} ; Retry "loop"
	While $IsObject(tBP) { ; not really a loop, just a quittable If
		Set:$D(tResponse) tBP.%response=tResponse

		If ""=tDoAlert&&$$$ISERR(tSC) {
			$$$catTRACE("bproc","calling OnError 2")
			Set $EC=""  try {
				Set tSC=tBP.OnError($$$NULLOREF,$$$NULLOREF,$$$NULLOREF,tSC,"")
			} catch {
				Set tSC=$$$ADDSC(tSC,$$$EnsSystemError)
			}
			If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnError() 2; committing before proceeding")
			Set:""=tDoAlert tDoAlert=$$$ISERR(tSC)
			Quit:'tBP.SuspendMessage
		}
		Quit:tTerminate

		If tAborted {
			Do pRequestHeader.SetStatus($$$eMessageStatusAborted)
			Quit
		}
		If tBP.SuspendMessage {
			Do pRequestHeader.SetStatus($$$eMessageStatusSuspended)
			If $$$ISERR(tSC) {
				If $$$ISERR(tSCSuspend) { $$$LOGSTATUS(tSC) }
				Else { $$$LOGWARNING($$$StatusText(tSC)) }
			}
			Set tSC=$$$OK
			Quit
		}
		Do pRequestHeader.SetStatus($$$eMessageStatusCompleted)
		If tBP.%IsCompleted {
			Try {
				If ##class(Ens.Util.Statistics).StatsActive(tBPConfigName) {
					#dim tTimeDelta = ##class(%SYSTEM.SQL.Functions).DATEDIFF("ms",tBP.%TimeCreated,tBP.%TimeCompleted)/1000
					Do ##class(Ens.Util.Statistics).RecordStats($$$eHostTypeActor,tBPConfigName,"",1,1,tTimeDelta)
				}
			} Catch {}
			$$$KillBPRuntime
		}
		Quit
	} ; end If/While
 } catch ex {
	Set tSC=$$$ADDSC(tSC,$Select($ZE="":ex.AsStatus(),1:$$$EnsSystemError))
 }
 Set $EC=""  try {
	If $$$ISERR(tSC) {
		$$$LOGSTATUS(tSC)
		Do:'tAborted pRequestHeader.SetStatus($$$eMessageStatusError)
		$$$SetHostMonitor(tBPConfigName,$$$eMonitorStatus,"Error")
	}
	If $IsObject(tBP) {
		If $$$ISERR(tSC) {
			Do:tDoAlert&&tBP.AlertOnError tBP.SendAlert(##class(Ens.AlertRequest).%New($LB(tBPConfigName,$$$StatusDisplayString(tSC))))
		} ElseIf tBP.SuspendMessage&&$$$ISERR(tSCSuspend) {
			Do:tDoAlert&&tBP.AlertOnError tBP.SendAlert(##class(Ens.AlertRequest).%New($LB(tBPConfigName,$$$StatusDisplayString(tSCSuspend))))
		}
	}
	#; Clear guest config and session - note this will be useless but harmless if tBP does not exist (i.e. discarded response for completed BP)
	If $IsObject(tOldBP) { Set $$$EnsJobLocal("%Process")=tOldBP } Else { Kill $$$EnsJobLocal("%Process") }
	Kill $$$JobSessionId, $$$JobCurrentHeaderId
	Kill $$$EnsJobStatus($$$SystemName,$Job,$$$eJobGuestConfigName), $$$EnsJobLocal("GuestConfigName"), $$$EnsJobLocal("CurrentXPATHDoc")
	Do ##class(Ens.Util.Trace).SetTraceOptimizer()
 } catch {
	Set tSC=$$$ADDSC(tSC,$$$EnsSystemError)
 }
 Quit tSC

cleanNum(str)
	Set f=0  For { Set f=$F(str,"#",f)  Quit:'f
		For i=f:1 { Quit:$E(str,i)'?1N  Set $E(str,i)="",i=i-1 }
	}
	Quit str
}

/// Override: no settings for Actor
Method AssignOneSetting(pProperty As %String, pValue As %String, pName As %String) As %Status [ Internal ]
{
	Quit $$$OK
}

}
