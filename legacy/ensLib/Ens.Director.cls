/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Director [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// This method starts the production running.
/// pProductionName: The name of the production to be started.  If not specified, defaults to the "last" production used (if any).
ClassMethod StartProduction(pProductionName As %String = {$GET(^Ens.Configuration("csp","LastProduction"))}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,tLoggedSC=0,tFindDiffsCalled=0,tRuntimeLocked=0
	Do {
		If $system.License.GetFeature(1)=0 Set tSC=$$$EnsError($$$EnsErrNoEnsembleLicense) Quit
		New $roles
		// If we aren't logged in as _Ensemble call %SYS.Ensemble::StartProduction()
		If ($username '= ##class(%SYS.Ensemble).EnsembleUsername()) {
			Set ^IRIS.Temp.EnsUsername($J) = $Username
			Set tSC = ##class(%SYS.Ensemble).StartProduction(pProductionName)
			Quit
		}

		If ..IsUnSupportedRemoteWorkerNamespace(.tSCSupported, .tIsECPClientNamespace) {
			Set tSC = $$$EnsError($$$EnsErrProductionNetworkedProhibited)
			Quit
		} ElseIf $$$ISERR(tSCSupported) { $$$LOGSTATUS(tSCSupported) }
		If tIsECPClientNamespace $$$LOGINFO("Detected runtime data on a remote ECP Server")

		Set:'$D(^Ens.Debug) ^Ens.Debug("TraceCat","user")=1 ; force the default value to ensure jobs have an in-memory mirror and avoid repeated checks of this real global
		Lock +$$$EnsRuntime:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireRuntimeLock,30) Quit
		Set tRuntimeLocked = 1

		Set tSC=..GetProductionStatus(.tProductionName,.tState) Quit:$$$ISERR(tSC)
		If tState=$$$eProductionStateRunning {
			Set tSC=$$$EnsError($$$EnsErrProductionAlreadyRunning,tProductionName)
		} ElseIf (tState=$$$eProductionStateSuspended) {
			If pProductionName'=tProductionName && (tProductionName'="") Set tSC=$$$EnsError($$$EnsErrProductionSuspendedMismatch,tProductionName) Quit
		} ElseIf tState=$$$eProductionStateNetworkStopped {
			If pProductionName'=tProductionName Set tSC=$$$EnsError($$$EnsErrProductionNetworkedMismatch,tProductionName) Quit			
		} ElseIf (tState=$$$eProductionStateTroubled) {
			Set tSC=$$$EnsError($$$EnsErrProductionNotShutdownCleanly,tProductionName)
		}
		Quit:$$$ISERR(tSC)

		#; Check that a (valid) production name was given
		If '$ZNAME(pProductionName,1) || '##class(Ens.Config.Production).%ExistsId(pProductionName) {
			Set tSC=$$$EnsError($$$EnsErrInvalidProduction)
			Quit
		}

		#; Since clean up of Ens.RuntimeAppData during stop production is outside of a transaction make sure empty before start
		$$$KillAllEnsRuntimeAppData
		#; Clear MsgBank connection counts
		Kill $$$EnsMsgBankConnections("Candidates")
		#; This ought not to exist
		Kill $$$EnsJobStatus($$$SystemName)
		
		#; Now that we think this is going to work, let's remember this as the last production and setup start/stop times
		$$$EnsMirrorIndexReset
		Set tStartTime = $$$timeUTC
		Set ^Ens.Configuration("csp","LastProduction") = pProductionName
		Set ^Ens.Configuration("csp","Activity",pProductionName,"started") = tStartTime
		Kill ^Ens.Configuration("csp","Activity",pProductionName,"stopped")

		Set tSC=..findProductionDifferences(pProductionName,0,.tDefinition,.tToStopJob,.tToStartConfig,.tToDeleteConfig,.tToUpdateScheduler,,.tActorForceDisabled,1)  Quit:$$$ISERR(tSC)
		Set tFindDiffsCalled = 1

		$$$LOGINFO($$$FormatText($$$Text("Production '%1' starting..."),pProductionName))
		If tActorForceDisabled $$$LOGWARNING("There are BusinessProcesses that use the Ens.Actor queue that are marked as disabled. The Ens.Actor will not be disabled and these Business Process will still process requests. Change to a dedicated pool in order to disable. If you wish to disable the general Actor pool set Production Actor Pool Size to 0.")

		Set tSC=$classmethod(pProductionName,"OnStart",tStartTime)  Quit:$$$ISERR(tSC)

		#; restore the queue
		#; KeepInQueueMod account for applying this code change after production suspended with old version
		TStart
		If $G($$$EnsSuspended($$$SystemName,"Ens.Queue","EnsProductionHasQueues"))'=$name($$$EnsQueue) {
			Merge $$$EnsQueue=$$$EnsSuspended($$$SystemName,"Ens.Queue")
		} Else {
			$$$LOGINFO($$$Text("Using suspended messages in the queues global (^Ens.Queue)"))
		}
		Kill $$$EnsSuspended($$$SystemName,"Ens.Queue")
		TCommit
		Set tQueueName="" For { Set tQueueName=$Order($$$EnsQueue(tQueueName))  Quit:tQueueName=""
			If tQueueName'?1.N {
				Do $system.Event.Create(##class(Ens.Queue).EventName(tQueueName))
				$$$sysTRACE($$$FormatText($$$Text("event '%1' created."),##class(Ens.Queue).EventName(tQueueName)))
			}
		}
		#; restore SuspendedAppData
		TStart
		$$$KillRootNode($$$EnsSuspendedAppData)
		Merge $$$EnsSuspendedAppData=$$$EnsSuspended($$$SystemName,"AppData")
		Kill $$$EnsSuspended($$$SystemName,"AppData")
		TCommit
		#; initial register done by the first system in networked environment
		If $data($$$EnsRuntime)=0 {
			Set $$$EnsRuntime("Name")=pProductionName
			Set $$$EnsRuntime("StartTime")=tStartTime
			Set tCheckSum=$r(1000000000)
			Set $$$EnsRuntime("CheckSum")=tCheckSum
		}
		Set $$$EnsRuntime("System",$$$SystemName)=$p($zu(54,13,$zu(54,0)),",",1)_":"_$get(^%SYS("SSPort"),1972)_":"_$znspace

		Set ^%SYS("Ensemble","RunningNamespace",$znspace)=$$$EnsRuntime("CheckSum")

		#; Clear existing Monitor information (except host-counters)
		$$$KillAllHostMonitor
		$$$KillAllJobMonitor
		$$$KillAllLogMonitor

		Set tSC=..actualizeProductionDifferences(.tDefinition,.tToStopJob,.tToStartConfig,.tToDeleteConfig,.tToUpdateScheduler,0,0)
		If $$$ISERR(tSC) $$$LOGSTATUS(tSC)  Set:'$D($$$EnsJobStatus($$$SystemName)) $$$EnsJobStatus($$$SystemName)=""  Do ..StopProduction(1,1)  Set tLoggedSC=1  Quit
		#;Set persistent entry.
		Set $$$EnsJobStatusStarted($$$SystemName)=tStartTime
		$$$LOGINFO($$$FormatText($$$Text("Production '%1' started."),pProductionName))

		#; Audit
		Set tEventData = "start"
		If $username=##class(%SYS.Ensemble).EnsembleUsername() {
			Set tUser = $G(^IRIS.Temp.EnsUsername($J))
			Set:tUser'="" tEventData = tEventData_" - logged in as user: "_tUser
		}
		Kill ^IRIS.Temp.EnsUsername($J)

		#dim tSC2 As %Library.Status
		// No need to validate production name.
		Set ^%SYS("Ensemble","RunningNamespace",$NAMESPACE,"SystemShutdownGroup")= ..GetProductionShutdownGroup(pProductionName,.tSC2,0)
		If $$$ISERR(tSC2) $$$LOGSTATUS(tSC2)

		Set tSC = $$$AuditStartStopProduction(pProductionName,tEventData)

	} While 0
Exit
	Lock:tRuntimeLocked -$$$EnsRuntime
	If $$$ISERR(tSC) {
		#; Flag production as dirty if start fails after checking for differences
		If tFindDiffsCalled If $$$EnsProdModCounterInc
		If 'tLoggedSC $$$LOGSTATUS(tSC)
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

/// <p>This method updates the running production.</p>
/// <p>pTimeout: How many seconds to wait for the jobs to go down.</p>
/// <p>pForce:   It indicates if we should forcefully kill the jobs which can not stop by themselves.</p>
/// <p>pCalledByScheduleHandler: This parameter is set to 1 when it is called by the schedule handler.</p>
/// 
ClassMethod UpdateProduction(pTimeout As %Numeric = 10, pForce As %Boolean = 0, pCalledByScheduleHandler As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,tFindDiffsCalled=0,tRuntimeLocked=0
	Do {

		If $system.License.GetFeature(1)=0 Set tSC=$$$EnsError($$$EnsErrNoEnsembleLicense) Quit
		New $roles
		// If we aren't logged in as _Ensemble call %SYS.Ensemble::UpdateProduction()
		If ($username '= ##class(%SYS.Ensemble).EnsembleUsername()) {
			Set tSC = ##class(%SYS.Ensemble).UpdateProduction(pTimeout,pForce,pCalledByScheduleHandler)
			Quit
		}

		If ..IsUnSupportedRemoteWorkerNamespace(.tSCSupported) {
			Set tSC = $$$EnsError($$$EnsErrProductionNetworkedProhibited)
			Quit
		} ElseIf $$$ISERR(tSCSupported) { $$$LOGSTATUS(tSCSupported) }

		Lock +$$$EnsRuntime:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireRuntimeLock,30) Quit
		Set tRuntimeLocked = 1

		Set tSC=..GetProductionStatus(.tProductionName,.tState) Quit:$$$ISERR(tSC)
		If tState'=$$$eProductionStateRunning {
			$$$sysTRACE($$$Text("No Production is running.")) Quit
		}
		$$$LOGINFO($$$FormatText($$$Text("Production '%1' updating..."),tProductionName))

		Set tSC=..findProductionDifferences(tProductionName,1,.tDefinition,.tToStopJob,.tToStartConfig,.tToDeleteConfig,.tToUpdateScheduler,,,1,pTimeout)  Quit:$$$ISERR(tSC)
		Set tFindDiffsCalled = 1

		If '$data(tToStopJob),'$data(tToStartConfig),'$data(tToDeleteConfig),$g(tToUpdateScheduler)=0 {
			$$$LOGINFO($$$FormatText($$$Text("Production '%1' is up-to-date."),tProductionName))
		} Else {
			Do ##class(Ens.Job).CleanUpDeadJobs()
			if pCalledByScheduleHandler set tToUpdateScheduler=0
			Set tSC=..actualizeProductionDifferences(.tDefinition,.tToStopJob,.tToStartConfig,.tToDeleteConfig,.tToUpdateScheduler,pTimeout,pForce,pCalledByScheduleHandler)  Quit:$$$ISERR(tSC)
			$$$LOGINFO($$$FormatText($$$Text("Production '%1' updated."),tProductionName))
		}
	} While 0
Exit
	Lock:tRuntimeLocked -$$$EnsRuntime
	If $$$ISERR(tSC) {
		#; Flag production as dirty if update fails after checking for differences
		If tFindDiffsCalled If $$$EnsProdModCounterInc
		$$$LOGSTATUS(tSC)
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

/// <p>This method stops the running production.</p>
/// <p>pTimeout: How many seconds to wait for the jobs to go down.</p>
/// <p>pForce:   It indicates if we should forcefully kill the jobs which can not stop by themselves.</p>
/// 
ClassMethod StopProduction(pTimeout As %Numeric = 10, pForce As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,tCountersKilled=0
	#dim tRuntimeLocked = 0
	#dim tQueuesLocked = 0
	Do {
		New $roles
		// If we aren't logged in as _Ensemble call %SYS.Ensemble::StopProduction()
		If ($username '= ##class(%SYS.Ensemble).EnsembleUsername()) {
			Set ^IRIS.Temp.EnsUsername($J) = $Username
			Set tSC = ##class(%SYS.Ensemble).StopProduction(pTimeout,pForce)
			Quit
		}

		If ..IsUnSupportedRemoteWorkerNamespace(.tSCSupported) {
			Set tSC = $$$EnsError($$$EnsErrProductionNetworkedProhibited)
			Quit
		} ElseIf $$$ISERR(tSCSupported) { $$$LOGSTATUS(tSCSupported) }

		$$$LOGINFO($$$Text("StopProduction initiated."))

		Do ##class(Ens.Job).MarkDeadJobs()

		Lock +$$$EnsRuntime:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireRuntimeLock,30) Quit
		Set tRuntimeLocked = 1

		Set tConfigName="" For { Set tConfigName=$Order($$$ConfigRoot(tConfigName))  Quit:tConfigName=""  Continue:tConfigName="%Production"
			Set tConfigNamesSaved(tConfigName)=$$$ConfigClassName(tConfigName)
		}
		Set tSC=..GetProductionStatus(.tProductionName,.tState) Quit:$$$ISERR(tSC)
		If tState'=$$$eProductionStateRunning {
			$$$LOGINFO($$$Text("No Production is running (")_##class(EnsPortal.Utils).resolveProductionStateName(tState)_")")
			Quit
		}
		$$$EnsProdModActiveKill
		$$$EnsProdModCounterKill
		Set tCountersKilled = 1
		Set tSC=##class(Ens.Job).MakeQuiescent(pTimeout,.tIsQuiescent) If $$$ISERR(tSC) Quit
		If 'tIsQuiescent,pForce=0 {
			Set tSC=##class(Ens.Job).MakeNotQuiescent() If $$$ISERR(tSC) Quit
			Set tSC=$$$EnsError($$$EnsErrProductionNotQuiescent)
			$$$LOGINFO($$$FormatText($$$Text("Production failed to stop within timeout of %1 seconds."),pTimeout))
			Quit
		}
		$$$KillRootNode($$$EnsSuspendedAppData)

		Set tSC=##class(Ens.Job).StopAll(pTimeout,pForce) If $$$ISERR(tSC) Quit
		Do ##class(Ens.Job).CleanUpDeadJobs()

		#; call OnProductionStop for each config item
		Set tConfigName="" For { Set tConfigName=$Order(tConfigNamesSaved(tConfigName),1,tClassname)  Quit:tConfigName=""
			$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Stopped")
			try {
				Do $classmethod(tClassname,"OnProductionStop",tConfigName)
			} catch {
				If $ZE["<CLASS DOES NOT EXIST>" { $$$LOGERROR("Could not call OnProductionStop() on nonexistent class '"_$G(tClassName)_"'") }
				Else { Set tSC1=$$$SystemError  $$$LOGERROR("Error calling OnProductionStop(): "_$$$StatusDisplayString(tSC1)) }
			}
		}
		Lock +$$$EnsQueue:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireQueuesLock,30) Quit
		Set tQueuesLocked = 1
		Do ..moveEnsRuntimeToEnsSuspended()
		Kill ^%SYS("Ensemble","RunningNamespace",$ZNspace)

		If $data($$$EnsSuspended)=1 {
			$$$KillRootNode($$$EnsSuspended)
		}
		If $data($$$EnsJobStatus($$$SystemName))=1 {
			Kill $$$EnsJobStatus($$$SystemName)
		}
		If $data($$$EnsSuspended($$$SystemName)) {
			$$$LOGINFO($$$FormatText($$$Text("Production '%1' suspended."),tProductionName))
		} Else {
			$$$LOGINFO($$$FormatText($$$Text("Production '%1' stopped."),tProductionName))
		}
		Set tStopTime=$$$timeUTC
		Set ^Ens.Configuration("csp","Activity",tProductionName,"stopped")=tStopTime

		Do $classmethod(tProductionName,"OnStop",tStopTime,'tIsQuiescent)

		#; Audit
		Set tEventData = "stop"
		If $username=##class(%SYS.Ensemble).EnsembleUsername() {
			Set tUser = $G(^IRIS.Temp.EnsUsername($J))
			Set:tUser'="" tEventData = tEventData_" - logged in as user: "_tUser
		}
		Kill ^IRIS.Temp.EnsUsername($J)
		Do $$$AuditStartStopProduction(tProductionName,tEventData)

	} While 0
Exit
	Lock:tRuntimeLocked -$$$EnsRuntime
	Lock:tQueuesLocked -$$$EnsQueue
	If tCountersKilled && $$$ISERR(tSC) If $$$EnsProdModCounterInc
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// <p>This method stops and restarts the running production.</p>
/// <p>pTimeout: How many seconds to wait for the jobs to go down.</p>
/// <p>pForce:   It indicates if we should forcefully kill the jobs which can not stop by themselves.</p>
/// 
ClassMethod RestartProduction(pTimeout As %Numeric = 10, pForce As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$LOGINFO($$$Text("RestartProduction initiated."))

		Lock +$$$EnsRuntime:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireRuntimeLock,30) Quit

		Set tSC=..GetProductionStatus(.tProductionName,.tState) Quit:$$$ISERR(tSC)
		If tState'=$$$eProductionStateRunning {
			$$$LOGINFO($$$Text("No Production is running.")) Quit
		}
		
		// Call StopProduction()
		Set tSC = ..StopProduction(pTimeout, pForce) Quit:$$$ISERR(tSC)
		
		// Call StartProduction()
		Set tSC = ..StartProduction(tProductionName) Quit:$$$ISERR(tSC)
		
		$$$LOGINFO($$$Text("RestartProduction complete."))
		
	} While 0
Exit
	Lock -$$$EnsRuntime
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Internal method. <br>
/// Caller locks EnsRuntime and EnsQueue before calling. <br>
ClassMethod moveEnsRuntimeToEnsSuspended(pFromRecover As %Boolean = 0, pRecoverProductionName As %String = "") [ Internal, Private ]
{
	Tstart
	;
	Set $$$EnsJobLocal("SkipTLevelCheck")=1
	Kill $$$EnsSuspended($$$SystemName)

	/* 	$$$EnsSuspended is used to ensure that if a production is suspended then 
		another production cannot be started in the same namespace.
		If recovering production only set the production name to $$$EnsSuspended
		if runtime name defined and not empty string.
	*/
	If 'pFromRecover {
		Set $$$EnsSuspended=$$$EnsRuntime("Name")
	} Else {
		#; When pFromRecover pRecoverProductionName ought to be $get($$$EnsRuntime("Name"),$get($$$EnsSuspended))
		#dim tSupportInfo = "(Data states: Ens.JobStatus="_$Data($$$EnsJobStatusStarted)
		Set tSupportInfo = tSupportInfo_", Ens.Runtime="_$Data($$$EnsRuntime)
		Set tSupportInfo = tSupportInfo_", Ens.Suspended="_$Data($$$EnsSuspended)_")"
		If pRecoverProductionName '= "" {
			Set $$$EnsSuspended=pRecoverProductionName
			If '$Data($$$EnsRuntime("Name"))#2 {
				$$$LOGWARNING("Recovering Unnamed Troubled Production using last suspended name for production name mismatch check on start. "_tSupportInfo)
			}
		} Else {
			#; We do not want to set EnsSuspended to empty string.
			$$$LOGWARNING("Recovering Unnamed Troubled Production. Unable to carry out production name mismatch check on start."_tSupportInfo)
		}
	}

	;
	// put all active messages back to the queues
	Set tJob="" For  {
		Set tJob=$o($$$EnsActiveMessage(tJob),1,tId) Quit:tJob=""
		Set tSC=##class(Ens.Job).RecoverActiveMessage(tId,tJob,0)
		Kill $$$EnsActiveMessage(tJob)
	}
	// clean up the queue
	Set tQueueName="" For {
		Set tQueueName=$Order($$$EnsQueue(tQueueName))  Quit:tQueueName=""
		Kill $$$EnsQueue(tQueueName,0,"job")
		If (tQueueName?1.N)||($$$queueIsPrivateQueue(tQueueName)) {
			; can not save messages in private queues
			Set tPriority=0 For {
				Set tPriority=$Order($$$EnsQueue(tQueueName,tPriority)) Quit:tPriority=""
				Set tIndex="" For {
					Set tIndex=$Order($$$EnsQueue(tQueueName,tPriority,tIndex))  Quit:tIndex=""
					Set tId=$$$EnsQueue(tQueueName,tPriority,tIndex)
					Kill $$$EnsQueue(tQueueName,tPriority,tIndex)
					Set $$$EnsQueue(tQueueName,0,"count")=$$$EnsQueue(tQueueName,0,"count")-1
					Set pRequestHeader=##Class(Ens.MessageHeader).%OpenId(tId)
					If pRequestHeader'=$$$NULLOREF {
						$$$sysTRACE($$$FormatText($$$Text("Message '%1' in private queue '%2' has been discarded."),tId,tQueueName))
						Do pRequestHeader.SetStatus($$$eMessageStatusDiscarded)
					}
				}
			}
			Kill $$$EnsQueue(tQueueName)
		} Else {
			; can not save messages with high priorities
			try {
				Set tPriority=$$$eMessagePrioritySimSync For {
					Set tPriority=$Order($$$EnsQueue(tQueueName,tPriority),-1) Quit:tPriority=""  Quit:tPriority=0
					Set tIndex="" For {
						Set tIndex=$Order($$$EnsQueue(tQueueName,tPriority,tIndex))  Quit:tIndex=""
						Set tId=$$$EnsQueue(tQueueName,tPriority,tIndex)
						Kill $$$EnsQueue(tQueueName,tPriority,tIndex)
						Set $$$EnsQueue(tQueueName,0,"count")=$$$EnsQueue(tQueueName,0,"count")-1
						Set pRequestHeader=##Class(Ens.MessageHeader).%OpenId(tId)
						If pRequestHeader'=$$$NULLOREF Do pRequestHeader.SetStatus($$$eMessageStatusSuspended)
						$$$LOGWARNING("High priority message '"_tId_"' in queue '"_tQueueName_"' has been marked as suspended.")
					}
				}
				If $g($$$EnsQueue(tQueueName,0,"count"))<1 Kill $$$EnsQueue(tQueueName)
			} catch {
				Set tSC=$$$EnsSystemError
			}
		}
	}
	If $data($$$EnsQueue) {
		If $G(^Ens.Configuration("Queues","KeepInQueues"),0) {
			#;Create marker entry in $$$EnsSuspended global. Code only checks for $D of this global and its value is not used. Just set it to ^Ens.Queue.
			Set $$$EnsSuspended($$$SystemName,"Ens.Queue","EnsProductionHasQueues")=$name($$$EnsQueue)
			$$$LOGWARNING("Queued messages are being saved in the suspended production in the queue global (^Ens.Queue)")
		} Else {
			Merge $$$EnsSuspended($$$SystemName,"Ens.Queue")=$$$EnsQueue
			$$$KillRootNode($$$EnsQueue)
			$$$LOGWARNING("Queued messages are being saved in the suspended production.")
		}
	}
	If $data($$$EnsAlarm) {
		Set tSC=##class(Ens.Alarm).SuspendAlarms()
		If $$$ISERR(tSC) {
			$$$LOGERROR("Error suspending Alarm Data: "_$$$StatusDisplayString(tSC))
			If $data($$$EnsAlarm) Merge $$$EnsSuspendedAppData("Ens.Alarm") = $$$EnsAlarm
		}
		$$$KillRootNode($$$EnsAlarm)
		If $data($$$EnsSuspendedAppData("Ens.Alarm"))  $$$LOGWARNING("Suspended Alarms are being saved in the suspended production.")
	}
	If $data($$$EnsSuspendedAppData) {
		Merge $$$EnsSuspended($$$SystemName,"AppData")=$$$EnsSuspendedAppData
		If (($O($$$EnsSuspendedAppData("Ens.Alarm"))'="")||($O($$$EnsSuspendedAppData("Ens.Alarm"),-1)'="")) $$$LOGWARNING("Suspended Application Data are being saved in the suspended production.")
		$$$KillRootNode($$$EnsSuspendedAppData)
	}
	;
	$$$KillRootNode($$$EnsRuntime)
	Kill $$$EnsJobStatusStarted($$$SystemName)
	$$$KillRootNode($$$EnsJobRequest)
	;
	If $data($$$EnsSuspended($$$SystemName))=1 Kill $$$EnsSuspended($$$SystemName)
	;
	#; IRIS.Temp cannot be rolled back. Need to ensure the check is on $$$EnsJobStatusStarted
	Kill $$$EnsJobStatus($$$SystemName) 
	Kill $$$EnsJobLocal("SkipTLevelCheck")
	Tcommit
	;
	#;Cleanup scratch data
	$$$KillAllEnsRuntimeAppData
	$$$KillAllHostMonitor
	$$$KillAllJobMonitor
	$$$KillAllLogMonitor
	;
	Quit
}

/// <p>This method returns the production status via the output parameters.</p>
/// <p>pProductionName: Returns the production name when the status is running, suspended or troubled.</p>
/// <p>pState: Outputs production status. The valid values are:
///          $$$eProductionStateRunning
///          $$$eProductionStateStopped
///          $$$eProductionStateSuspended
///          $$$eProductionStateTroubled</p>
/// 
ClassMethod GetProductionStatus(Output pProductionName As %String, Output pState As %Integer, pLockTimeout As %Numeric = 10, pSkipLockIfRunning As %Boolean = 0) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tIsUnSupportedRemoteWorkerNamespace = ..IsUnSupportedRemoteWorkerNamespace(.tSCSupported)
		If $$$ISOK(tSCSupported) && tIsUnSupportedRemoteWorkerNamespace {
			Set pProductionName=$get($$$EnsRuntime("Name"),$get($$$EnsSuspended))
			Set pState = $$$eProductionStateShardWorkerProhibited
			Quit
		}

		Set tIsMirrorBackup = 0, tLocked = 0
		#; If we are in a mirror and not the primary, determine whether the default database is mirrored
		If $system.Mirror.IsMember() && '$system.Mirror.IsPrimary() {
			Set tSC = ##class(%SYS.Ensemble).GlobalInMirroredDB($name($$$EnsRuntime),.tIsMirrorBackup)
			If $$$ISERR(tSC) Quit
		}
		If ('tIsMirrorBackup) {
			If pSkipLockIfRunning,($E($USERNAME,1,9)'="_Ensemble") {
				If ..IsProductionRunning() {
					Set pProductionName=$$$EnsRuntime("Name")
					Set pState=$$$eProductionStateRunning
					Quit
				}	
			}
			Lock +$$$EnsRuntime("ConfigItem"):pLockTimeout
			If '$Test {
				Set tSC=$$$ERROR($$$EnsErrCanNotAcquireRuntimeLock,pLockTimeout)
				Set pProductionName=""
				Set pState=$$$eProductionStateUnknown
				Quit
			}
			Set tLocked = 1
			#; If on mirror backup namespace cannot be running.
			If ..IsProductionRunning() {
				Set pProductionName=$$$EnsRuntime("Name")
				Set pState=$$$eProductionStateRunning
				Quit
			}
		}
		If ('$data($$$EnsJobStatusStarted))&&('$data($$$EnsRuntime))&&('$data($$$EnsSuspended)) {
			Set pProductionName=""
			Set pState=$select(tIsMirrorBackup: $$$eProductionStateBackupStopped, 1: $$$eProductionStateStopped)
			Quit
		}
		If ('$data($$$EnsJobStatusStarted))&&('$data($$$EnsRuntime))&&($data($$$EnsSuspended)) {
			Set pProductionName=$get($$$EnsSuspended)
			Set pState=$select(tIsMirrorBackup: $$$eProductionStateBackupSuspended, 1: $$$eProductionStateSuspended)
			Quit
		}
		If ('$data($$$EnsJobStatusStarted($$$SystemName)))&&('$data($$$EnsRuntime("System",$$$SystemName)))&&($data($$$EnsRuntime("System"))) {
			Set pProductionName=$get($$$EnsRuntime("Name"))
			Set pState=$select(tIsMirrorBackup: $$$eProductionStateBackupNetworkStopped, 1: $$$eProductionStateNetworkStopped)
			Quit
		}
		Set pProductionName=$get($$$EnsRuntime("Name"),$get($$$EnsSuspended))
		Set pState=$select(tIsMirrorBackup: $$$eProductionStateBackupUnknown, 1: $$$eProductionStateTroubled)
	}
	Catch {
		Set tSC = $$$EnsSystemError
	}
	If $get(tLocked) Lock -$$$EnsRuntime("ConfigItem")
	Quit tSC
}

/// This method returns whether a production is currently running in this namespace, and returns the 
/// name of the currently running production in <var>pProductionName</var>.
/// Note that this method is not as reliable as <method>GetProductionStatus</method>() as it does
/// not lock $$$EnsRuntime and may not accurately reflect the production status while the production
/// is changing state, e.g. while starting or stopping.
ClassMethod IsProductionRunning(Output pProductionName As %String) As %Boolean
{
	Set tRunning = ($data($$$EnsJobStatusStarted($$$SystemName))||$data($$$EnsJobStatus($$$SystemName)))&&($data($$$EnsRuntime("System",$$$SystemName)))&&($$$EnsRuntime("CheckSum")=$get(^%SYS("Ensemble","RunningNamespace",$namespace)))
	Set pProductionName = $select(tRunning: $get($$$EnsRuntime("Name")), 1: "")
	Quit tRunning
}

/// This method returns a boolean to indicate if the running production needs to be updated or not.
/// pReason: is an output parameter that gives detailed reasons.
ClassMethod ProductionNeedsUpdate(Output pReason As %String, pQuickLock As %Boolean = 0) As %Boolean
{
	Set pReason="", tNeedsUpdate=0
	Try {
		If ..IsUnSupportedRemoteWorkerNamespace(.tSC) Quit
		If $$$ISERR(tSC) {
			Set pReason = $system.Status.GetErrorText(tSC)
			Quit
		}

		If pQuickLock,($E($USERNAME,1,9)'="_Ensemble") {
			Lock +$$$EnsRuntime("ConfigItem"):0.1
			If '$Test {Set pReason = -1  Quit}
		} Else {
			Lock +$$$EnsRuntime("ConfigItem"):30
			If '$Test Set pReason=$system.Status.GetErrorText($$$EnsError($$$EnsErrCanNotAcquireRuntimeLock,30)) Quit
		}
		Set tLocked = 1

		Set tProductionName=$g($$$EnsRuntime("Name"))
		If (tProductionName="")||'..IsProductionRunning() {
			Set pReason=$$$Text("No Production is running.")
			Quit
		}
		If $$$EnsProdModNoChanges {
			#; The only changes we are looking for are stopped/dead jobs
			Set tToUpdateScheduler = 0
			Set tSC = ..getRunningJobData(.tRunningCount)
			If $$$ISERR(tSC) {
				Set pReason = $system.Status.GetErrorText(tSC)
				Quit
			}
			Set tConfigName = ""
			For {
				Set tConfigName = $order($$$ConfigRoot(tConfigName))
				Quit:""=tConfigName
				Set tEffectivePoolSize = $Case($get($$$ConfigRunAsJob(tConfigName)), 0:0, -1:1, :$get($$$ConfigPoolSize(tConfigName)))
				If +tEffectivePoolSize '= +$get(tRunningCount(tConfigName)) {
					Set tToStartConfig(tConfigName) = tEffectivePoolSize - $get(tRunningCount(tConfigName))
				}
			}
		}
		Else {
			Do ..findProductionDifferences(tProductionName,0,,.tToStopJob,.tToStartConfig,.tToDeleteConfig,.tToUpdateScheduler,.tToCleanJobStatus)
		}
		Set j="" For  {
			Set j=$o(tToCleanJobStatus(j)) Quit:j=""
			Set pReason=pReason_$$$FormatText($$$Text("Job %1, which ran '%2' has died."),$p($e(j,2,*),"_",1),$$$EnsJobStatus($$$SystemName,j,$$$eJobStartConfigName))_$c(13,10)
			Set tNeedsUpdate=0
		}
		Set j="" For  {
			Set j=$o(tToStopJob(j),1,tIsTemp) Quit:j=""  Continue:tIsTemp<0
			Set pReason=pReason_$$$FormatText($$$Text("Job '%1' needs to be terminated."),j)_$c(13,10)
			Set tNeedsUpdate=1
		}
		Set c="" For  {
			Set c=$o(tToStartConfig(c)) Quit:c=""  
			Set pReason=pReason_$$$FormatText($select(tToStartConfig(c)=1: $$$Text("%1 new job for config item '%2' needs to be started."), 1: $$$Text("%1 new jobs for config item '%2' need to be started.")),tToStartConfig(c),c)_$c(13,10)
			Set tNeedsUpdate=1
		}
		Set c="" For  {
			Set c=$o(tToDeleteConfig(c)) Quit:c=""
			Set pReason=pReason_$$$FormatText($$$Text("Registration for config item '%1' needs to be deleted."),c)_$c(13,10)
			Set tNeedsUpdate=1
		}
		If tToUpdateScheduler {
			Set pReason=pReason_$$$Text("Scheduler needs to be updated.")_$c(13,10)
			Set tNeedsUpdate=1
		}
	}
	Catch {
		Set tSC = $$$EnsSystemError, pReason=$$$Text("Internal Error Encountered."), tNeedsUpdate=0
	}
	If $get(tLocked) Lock -$$$EnsRuntime("ConfigItem")
	Quit tNeedsUpdate
}

/// This method recovers the last running production whose status is eProductionStateTroubled.
ClassMethod RecoverProduction() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	#dim tRuntimeLocked = 0
	#dim tQueuesLocked = 0

	Do {
		If ..IsUnSupportedRemoteWorkerNamespace(.tSCSupported) {
			Set tSC = $$$EnsError($$$EnsErrProductionNetworkedProhibited)
			Quit
		} ElseIf $$$ISERR(tSCSupported) { $$$LOGSTATUS(tSCSupported) }

		Lock +$$$EnsRuntime:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireRuntimeLock,30) Quit
		Set tRuntimeLocked = 1
		
		Set tSC=..GetProductionStatus(.tProductionName,.tState) Quit:$$$ISERR(tSC)
		If tState'=$$$eProductionStateTroubled {
			$$$sysTRACE($$$Text("Nothing to recover.")) Quit
		}
		/*	tProduction ought to be defined due to double $Get in GetProductionStatus when $$$eProductionStateTroubled
		*/
		Lock +$$$EnsQueue:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireQueuesLock,30) Quit
		Set tQueuesLocked = 1
		Do ..moveEnsRuntimeToEnsSuspended(1,$Get(tProductionName))
		$$$sysTRACE($$$Text("Production recovery finished.")) Quit
	} While 0
Exit
	Lock:tRuntimeLocked -$$$EnsRuntime
	Lock:tQueuesLocked -$$$EnsQueue
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod findProductionDifferences(pProductionName As %String, pLog As %Boolean, Output pDefinition, Output pToStopJob, Output pToStartConfig, Output pToDeleteConfig, Output pToUpdateScheduler As %Boolean = 0, Output pToCleanJobStatus, Output pActorForceDisabled As %Boolean = 0, pUpdatingProduction As %Boolean = 0, pActiveLockTimeout As %Integer = 10) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tProdActiveLocked = 0
		Set tInitModCounter = $$$EnsProdModCounterGet
		If pUpdatingProduction {
			Lock +$$$EnsProdModActive:pActiveLockTimeout
			If '$Test {
				Set tSC = $$$EnsError($$$EnsErrGeneral,"Cannot acquire lock on Active Production Counter within "_pActiveLockTimeout_" seconds")
				Quit
			}
			Set tProdActiveLocked = 1
			Set $$$EnsProdModActive = +tInitModCounter
			If ($$$EnsProdModActive = 0) If $increment($$$EnsProdModCounter,0)
			Lock -$$$EnsProdModActive
			Set tProdActiveLocked = 0
		}
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,,.tSC)
		If '$IsObject(tProduction)||$$$ISERR(tSC) { Set tSC=$$$EnsError($$$EnsErrProductionNotRegistered,pProductionName,$$$StatusDisplayString(tSC))  Quit }

		/* Set a special node for unaffiliated Trace event logging; the Trace macros look for this by default
			Override production definition testing enabled if specified in SDS */
		If ##class(Ens.Config.DefaultSettings).%GetSetting(tProduction.Name,"$Production",tProduction,"","LogGeneralTraceEvents",.tSDSLogGeneralTraceEvents) {
			Set pDefinition("%Production","Trace")=tSDSLogGeneralTraceEvents
		} Else {
			Set pDefinition("%Production","Trace")=tProduction.LogGeneralTraceEvents
		}
		
		Set tSC = tProduction.PopulateModifiedSettings()
		Set tIndex="" For { Set tIndex = tProduction.ModifiedSettings.Next(tIndex)  Quit:tIndex=""
			Set tSetting = tProduction.ModifiedSettings.GetAt(tIndex)
			Set pDefinition("%Production","Setting",tSetting.Name)=tSetting.Value
		}
		Set pDefinition("%Production","Checksum")=tProduction.Checksum() ; depends on PopulateModifiedSettings()

		Set tAutoAdd("Ens.Alarm")=1
		Set tAutoAdd("Ens.Actor")=1
		Set tAutoAdd("Ens.MonitorService")=1
		Set tAutoAdd("EnsLib.Testing.Service")=1
		Set tAutoAdd("EnsLib.Testing.Process")=1
		Set tAutoAdd("Ens.ScheduleHandler")=1
		Set tAutoAdd("Ens.ScheduleService")=1

		Set tAutoAdd("EnsLib.Background.Service")=1
		Set tAutoAdd("EnsLib.Background.Process.ExportMessageSearch")=1
		Set tAutoAdd("EnsLib.Background.Workflow.Operation")=1

		Set tAutoAddItem=""  For { Set tAutoAddItem = $order(tAutoAdd(tAutoAddItem))  Quit:(tAutoAddItem="")
			&sql(SELECT TOP 1 ID INTO :tID FROM Ens_Config.Item WHERE Production = :pProductionName AND Name = :tAutoAddItem)
			Set:'SQLCODE tAutoAdd(tAutoAddItem) = 0
		}
		Set tConfigName="Ens.Alarm"
		If tAutoAdd(tConfigName) {
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")=tConfigName
			Set pDefinition(tConfigName,"QueueName")=tConfigName
			Set pDefinition(tConfigName,"PoolSize")=1
			Set pDefinition(tConfigName,"Foreground")=0
			Set pDefinition(tConfigName,"DisableErrorTraps")=0
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeOperation
			Set pDefinition(tConfigName,"InactivityTimeout")=0
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=1
			Set pDefinition(tConfigName,"Trace")=0
		}
		Set tConfigName="Ens.Actor"
		If tAutoAdd(tConfigName) {
			Set pActorForceDisabled=..hasDisabledActorProcess(tProduction)
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")=tConfigName
			Set pDefinition(tConfigName,"QueueName")=tConfigName
			/* Override Actor Pool Size if specified in SDS*/
			If ##class(Ens.Config.DefaultSettings).%GetSetting(tProduction.Name,"$Production",tProduction.Name,"","ActorPoolSize",.tSDSActorPoolSize) {
				Set pDefinition(tConfigName,"PoolSize")=tSDSActorPoolSize
			} Else {
				Set pDefinition(tConfigName,"PoolSize")=tProduction.ActorPoolSize
			}
			Set pDefinition(tConfigName,"Foreground")=tProduction.ActorDebugSetting("Foreground")
			Set pDefinition(tConfigName,"DisableErrorTraps")=tProduction.ActorDebugSetting("DisableErrorTraps")
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeActor
			Set pDefinition(tConfigName,"InactivityTimeout")=60
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=0
			Set pDefinition(tConfigName,"RunAsJob")=1
			Set pDefinition(tConfigName,"Trace")=0
		}
		Set tConfigName="Ens.MonitorService"
		If tAutoAdd(tConfigName) {
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")=tConfigName
			Set pDefinition(tConfigName,"QueueName")=tConfigName
			Set pDefinition(tConfigName,"PoolSize")=1
			Set pDefinition(tConfigName,"Foreground")=0
			Set pDefinition(tConfigName,"DisableErrorTraps")=0
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeService
			Set pDefinition(tConfigName,"InactivityTimeout")=0
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=1
			Set pDefinition(tConfigName,"Trace")=0
		}
		Set tConfigName="Ens.ScheduleHandler"
		If tAutoAdd(tConfigName) {
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")="Ens.Actor"
			Set pDefinition(tConfigName,"QueueName")=tConfigName
			Set pDefinition(tConfigName,"PoolSize")=1
			Set pDefinition(tConfigName,"Foreground")=0
			Set pDefinition(tConfigName,"DisableErrorTraps")=0
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeProcess
			Set pDefinition(tConfigName,"InactivityTimeout")=0
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=1
			Set pDefinition(tConfigName,"Trace")=0
		}
		Set tConfigName="Ens.ScheduleService"
		If tAutoAdd(tConfigName) {
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")=tConfigName
			Set pDefinition(tConfigName,"QueueName")=tConfigName
			Set pDefinition(tConfigName,"PoolSize")=0
			Set pDefinition(tConfigName,"Foreground")=0
			Set pDefinition(tConfigName,"DisableErrorTraps")=0
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeService
			Set pDefinition(tConfigName,"InactivityTimeout")=0
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=0
			Set pDefinition(tConfigName,"Trace")=0
		}
		/* Override production definition testing enabled if specified in SDS */
		If ##class(Ens.Config.DefaultSettings).%GetSetting(tProduction.Name,"$Production",tProduction,"","TestingEnabled",.tSDSTestingEnabled) {
			Set tTestingEnabled = tSDSTestingEnabled
		} Else {
			Set tTestingEnabled = tProduction.TestingEnabled
		}
		If tTestingEnabled {
			Set tConfigName="EnsLib.Testing.Service"
			If tAutoAdd(tConfigName) {
				Set pDefinition(tConfigName)=""
				Set pDefinition(tConfigName,"IsEnabled")=1
				Set pDefinition(tConfigName,"ClassName")=tConfigName
				Set pDefinition(tConfigName,"OnTaskClassName")=tConfigName
				Set pDefinition(tConfigName,"QueueName")=tConfigName
				Set pDefinition(tConfigName,"PoolSize")=0
				Set pDefinition(tConfigName,"Foreground")=0
				Set pDefinition(tConfigName,"DisableErrorTraps")=0
				Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeService
				Set pDefinition(tConfigName,"InactivityTimeout")=0
				Set pDefinition(tConfigName,"Checksum")=""
				Set pDefinition(tConfigName,"Register")=1
				Set pDefinition(tConfigName,"RunAsJob")=0
				Set pDefinition(tConfigName,"Trace")=0
			}
			Set tConfigName="EnsLib.Testing.Process"
			If tAutoAdd(tConfigName) {
				Set pDefinition(tConfigName)=""
				Set pDefinition(tConfigName,"IsEnabled")=1
				Set pDefinition(tConfigName,"ClassName")=tConfigName
				Set pDefinition(tConfigName,"OnTaskClassName")="Ens.Actor"
				Set pDefinition(tConfigName,"QueueName")=tConfigName
				Set pDefinition(tConfigName,"PoolSize")=1
				Set pDefinition(tConfigName,"Foreground")=0
				Set pDefinition(tConfigName,"DisableErrorTraps")=0
				Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeProcess
				Set pDefinition(tConfigName,"InactivityTimeout")=0
				Set pDefinition(tConfigName,"Checksum")=""
				Set pDefinition(tConfigName,"Register")=1
				Set pDefinition(tConfigName,"RunAsJob")=1
				Set pDefinition(tConfigName,"Trace")=0
			}
		}
		Set tConfigName="EnsLib.Background.Service"
		If tAutoAdd(tConfigName) {
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")=tConfigName
			Set pDefinition(tConfigName,"QueueName")=tConfigName
			Set pDefinition(tConfigName,"PoolSize")=0
			Set pDefinition(tConfigName,"Foreground")=0
			Set pDefinition(tConfigName,"DisableErrorTraps")=0
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeService
			Set pDefinition(tConfigName,"InactivityTimeout")=0
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=0
			Set pDefinition(tConfigName,"Trace")=0
		}
		Set tConfigName="EnsLib.Background.Process.ExportMessageSearch"
		If tAutoAdd(tConfigName) {
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")="Ens.Actor"
			Set pDefinition(tConfigName,"QueueName")="Ens.Actor"
			Set pDefinition(tConfigName,"PoolSize")=0
			Set pDefinition(tConfigName,"Foreground")=0
			Set pDefinition(tConfigName,"DisableErrorTraps")=0
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeProcess
			Set pDefinition(tConfigName,"InactivityTimeout")=0
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=0
			Set pDefinition(tConfigName,"Trace")=0
		}
		Set tConfigName="EnsLib.Background.Workflow.Operation"
		If tAutoAdd(tConfigName) {
			Set pDefinition(tConfigName)=""
			Set pDefinition(tConfigName,"IsEnabled")=1
			Set pDefinition(tConfigName,"ClassName")=tConfigName
			Set pDefinition(tConfigName,"OnTaskClassName")=tConfigName
			Set pDefinition(tConfigName,"QueueName")=tConfigName
			Set pDefinition(tConfigName,"PoolSize")=0
			Set pDefinition(tConfigName,"Foreground")=0
			Set pDefinition(tConfigName,"DisableErrorTraps")=0
			Set pDefinition(tConfigName,"BusinessType")=$$$eHostTypeOperation
			Set pDefinition(tConfigName,"InactivityTimeout")=0
			Set pDefinition(tConfigName,"Checksum")=""
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=0
			Set pDefinition(tConfigName,"Trace")=0
		}
		#; get production items
		Set tSC=..getProductionItems(tProduction,.pDefinition,.tAutoAdd)
		Quit:$$$ISERR(tSC)
		#; count running jobs for each config item
		Set tSC = ..getRunningJobData(.tRunningJobCount,.tRunningConfig)
		If $$$ISERR(tSC) Quit
		#; flag any change in production settings
		If pDefinition("%Production","Checksum")'=$G($$$ConfigChecksum("%Production")) {
			Set pToUpdateScheduler=1
		}
		#; build counts of item jobs to start and list of jobs to stop
		Set tConfigName="" For { Set tConfigName=$Order(pDefinition(tConfigName))  Quit:tConfigName=""  Continue:tConfigName="%Production"
			Set tClassName=pDefinition(tConfigName,"ClassName"), tBusinessType=pDefinition(tConfigName,"BusinessType")
			If '##class(%Dictionary.ClassDefinition).%ExistsId(tClassName)   { Set tSC1=$$$EnsError($$$EnsErrGeneral,"Class "_tClassName_" does not exist for Config Item "_tConfigName), pDefinition(tConfigName,"RunAsJob")=0 }
			ElseIf '##class(%Dictionary.CompiledClass).%ExistsId(tClassName) { Set tSC1=$$$EnsError($$$EnsErrGeneral,"Class "_tClassName_" is not compiled for Config Item "_tConfigName), pDefinition(tConfigName,"RunAsJob")=0 }
			ElseIf tBusinessType=$$$eHostTypeUnknown { Set tSC1=$$$EnsError($$$EnsErrGeneral,"Config Item "_tConfigName_" cannot run because it has unknown BusinessType"), pDefinition(tConfigName,"RunAsJob")=0 }
			Else { Set tSC1=$$$OK }
			Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)

			#; RunAsJob=-1 means run 1 job regardless of PoolSize, e.g. for TCP.InboundAdapter with JobPerConnection=1
			#; The PoolSize of a JobPerConnection Service may be used to set a limit on the number of externally invoked Service jobs allowed to run at one time
			Set tEffectivePoolSize=$Case(pDefinition(tConfigName,"RunAsJob"), 0:0, -1:1, :pDefinition(tConfigName,"PoolSize"))
			If pDefinition(tConfigName,"Register")&&'$D($$$ConfigRoot(tConfigName)) {
				Set pToStartConfig(tConfigName)=tEffectivePoolSize
				Set tToStopConfig(tConfigName)=""
				If pLog $$$SysWebTrace($$$FormatText($$$Text("%1: new item to be started."),tConfigName))
				Set pToUpdateScheduler=1
			} ElseIf pDefinition(tConfigName,"Checksum")'=$G($$$ConfigChecksum(tConfigName)) {
				Set pToStartConfig(tConfigName)=tEffectivePoolSize
				Set pToStartConfig(tConfigName,"update")=""
				Set tToStopConfig(tConfigName)=""
				If pLog $$$SysWebTrace($$$FormatText($$$Text("%1: modified item to be updated."),tConfigName))
				Set pToUpdateScheduler=1
				Continue
			} Else {
				If +$G(tRunningJobCount(tConfigName))'=tEffectivePoolSize {
					Set pToStartConfig(tConfigName)=tEffectivePoolSize-$G(tRunningJobCount(tConfigName))
					Set pToStartConfig(tConfigName,"update")=""
					If pLog {
						If pToStartConfig(tConfigName)>0 {
							$$$SysWebTrace($$$FormatText($$$Text("%1: poolsize to be increased by %2."),tConfigName,pToStartConfig(tConfigName)))
						} Else {
							$$$SysWebTrace($$$FormatText($$$Text("%1: poolsize to be decreased by %2."),tConfigName,-pToStartConfig(tConfigName)))
						}
					}
				} ElseIf ('$G($$$ConfigRunAsJob(tConfigName),1) && $G(pDefinition(tConfigName,"RunAsJob"))){
					/* 
						ConfigRunAsJob is 0 but it needs to be 1 and all expected jobs are already  running
						Need to force $$$ConfigRunAsJob(tConfigName) to be set to 1
					*/
					Set pToStartConfig(tConfigName)=0
					Set pToStartConfig(tConfigName,"update")=""
					If pLog {
						$$$SysWebTrace($$$FormatText($$$Text("Configuration RunAsJob for %1 needs to be set to true (1)"),tConfigName))
					}
				}
				Set:$G(pDefinition(tConfigName,"Schedule"))'=$g($$$ConfigSchedule(tConfigName)) pToUpdateScheduler=1
			}
		}
		Set tLiveConfigName="" For { Set tLiveConfigName=$Order($$$ConfigRoot(tLiveConfigName))  Quit:tLiveConfigName=""  Continue:tLiveConfigName="%Production"
			Continue:$D(pDefinition(tLiveConfigName))
			Set tToStopConfig(tLiveConfigName)=""
			Set pToDeleteConfig(tLiveConfigName)=""
			If pLog $$$SysWebTrace($$$FormatText($$$Text("%1: deleted item to be stopped."),tLiveConfigName))
			Set:$G(pDefinition(tLiveConfigName,"Schedule"))'=$g($$$ConfigSchedule(tLiveConfigName)) pToUpdateScheduler=1

		}
		Set tConfigName="" For { Set tConfigName=$Order(tRunningConfig(tConfigName))  Quit:tConfigName=""
			Set tJob="" For { Set tJob=$Order(tRunningConfig(tConfigName,tJob),1,tIsTemp)  Quit:tJob=""
				If $G(pToStartConfig(tConfigName))<0 {
					// !!! only if not an active Operation
					Set pToStopJob(tJob)=tIsTemp
					Set:'tIsTemp pToStartConfig(tConfigName)=pToStartConfig(tConfigName)+1
					Kill:'pToStartConfig(tConfigName) pToStartConfig(tConfigName)
				}
				ElseIf $Data(tToStopConfig(tConfigName)) {
					Set pToStopJob(tJob)=tIsTemp
				}
			}
		}
		// !!! stop more Operation jobs if needed, even if they are active

		#; If we got a modification flag that doesn't require any changes, we should correctly update the active flag
		If ('pUpdatingProduction) && tInitModCounter && '($data(pToStopJob)||$data(pToStartConfig)||$data(pToDeleteConfig)||$data(pToCleanJobStatus)||pToUpdateScheduler) && '$$$EnsProdModNoChanges {
			#; Use short lock timeout as this function is not critical and should not block for very long
			Lock +$$$EnsProdModActive:0.5
			If $Test {
				Set tProdActiveLocked = 1
				Set $$$EnsProdModActive = +tInitModCounter
				Lock -$$$EnsProdModActive
				Set tProdActiveLocked = 0
			}
		}
	} While 0
Exit
	If $get(tProdActiveLocked) Lock -$$$EnsProdModActive
	If pUpdatingProduction && $$$ISERR(tSC) {
		#; Increment the modification counter as there may be missing settings
		If $$$EnsProdModCounterInc
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod getProductionItems(tProduction As Ens.Config.Production, pDefinition As %String, pAutoAdd As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Set definitions for all ConfigItems in the configured Production
		For i=1:1:tProduction.Items.Count() {
			Set tItem = tProduction.Items.GetAt(i)
			Set tConfigName=tItem.Name, tBusinessType=tItem.BusinessType()
			#; To understand the following logic, do it the "complement" way, think "set pDefinition" as the reverse of the "continue" command, 
			#; then the logic becomes:
			#;     if tItem.Enabled, then set pDefinition
			#;     if pDefinition is not defined, then set pDefinition
			#;     if it is auto-add, then set pDefinition.
			#; In the end:
			#;     1) the last Enabled version with the same ConfigName is the one that gets defined at runtime
			#;     2) any defined item, enabled or disabled, will override the auto-add. 
			#;        this means, if you have a disabled Ens.Alarm, it will override the system default one and you will end up with a disabled Ens.Alarm.
			Set tEnabled=$S(##class(Ens.Config.DefaultSettings).%GetSetting(tItem.Production.Name,tItem.Name,tItem.ClassName,"","Enabled",.tSDSEnabled):tSDSEnabled,1:tItem.Enabled)
			Continue:'tEnabled&&$data(pDefinition(tConfigName))&&'$G(pAutoAdd(tConfigName))
			#; overwrite registration of AutoAdd items with user settings if any
			Set pAutoAdd(tConfigName)=0 ; clear this so behavior will be the same for multiply-defined normal and AutoAdd items
	
			Set tSC = tItem.PopulateModifiedSettings()
			Kill pDefinition(tConfigName)
			Set pDefinition(tConfigName,"ClassName")=tItem.ClassName
			Set pDefinition(tConfigName,"OnTaskClassName")=tItem.ClassName
			Set pDefinition(tConfigName,"QueueName")=tItem.QueueName()
			Set pDefinition(tConfigName,"Foreground")=tItem.Foreground
			Set pDefinition(tConfigName,"DisableErrorTraps")=tItem.DisableErrorTraps
			Set pDefinition(tConfigName,"BusinessType")=tBusinessType
			Set pDefinition(tConfigName,"InactivityTimeout")=tItem.InactivityTimeout
			Set pDefinition(tConfigName,"Checksum")=tItem.Checksum() ; depends on PopulateModifiedSettings()
			Set pDefinition(tConfigName,"%Id")=tItem.%Id()
			Set pDefinition(tConfigName,"Register")=1
			Set pDefinition(tConfigName,"RunAsJob")=1

			/* SDS override for static setting Schedule
				Will use the tSchedule variable later in code
				in place of item.Schedule */
			If ##class(Ens.Config.DefaultSettings).%GetSetting(tItem.Production.Name,tItem.Name,tItem.ClassName,"","Schedule",.tSDSSchedule) {
				Set tSchedule = tSDSSchedule
			} Else {
				Set tSchedule = tItem.Schedule
			}
			Set pDefinition(tConfigName,"Schedule")=tSchedule

			/* SDS override for static setting LogTraceEvents */
			If ##class(Ens.Config.DefaultSettings).%GetSetting(tItem.Production.Name,tItem.Name,tItem.ClassName,"","LogTraceEvents",.tSDSLogTraceEvents) {
				Set pDefinition(tConfigName,"Trace") = tSDSLogTraceEvents
			} Else {
				Set pDefinition(tConfigName,"Trace") = tItem.LogTraceEvents
			}

			/* Override production definition PoolSize and Enabled if specified in SDS */
			Set tPoolSize = tItem.PoolSize
			If ##class(Ens.Config.DefaultSettings).%GetSetting(tItem.Production.Name,tItem.Name,tItem.ClassName,"","PoolSize",.tSDSPoolSize) {
				/* Allow positive integer pool size override if not BP with pool size of 0 - i.e. cannot move from using Actor pool */
				If (tSDSPoolSize > 0)&&(tSDSPoolSize\1=tSDSPoolSize)&&('(tBusinessType=$$$eHostTypeProcess)||tItem.PoolSize) {
					Set tPoolSize = tSDSPoolSize
				}
			}
			Set pDefinition(tConfigName,"PoolSize")=tPoolSize

			#; tEnabled set before possible continue above
			Set pDefinition(tConfigName,"IsEnabled")=tEnabled

			Set tIndex="" For { Set tIndex = tItem.ModifiedSettings.Next(tIndex)  Quit:tIndex=""
				Set tSetting = tItem.ModifiedSettings.GetAt(tIndex)
				Set pDefinition(tConfigName,"Setting",tSetting.Target,tSetting.Name)=tSetting.Value
			}

			If 'tEnabled||($classmethod(tItem.ClassName,"%GetParameter","INVOCATION")'="Queue") {
				Set pDefinition(tConfigName,"RunAsJob")=0
			} Elseif tSchedule'="" {
				Set tSC=##class(Ens.ScheduleHandler).ParseScheduleSpec(tSchedule,.tCurrentState)
				If $$$ISERR(tSC)||(tCurrentState="DISABLED") {
					$$$LOGWARNING("ConfigItem '"_tItem.Name_"' is disabled because its schedule string is invalid.")
					Set pDefinition(tConfigName,"IsEnabled")=0
					Set pDefinition(tConfigName,"RunAsJob")=0
				} Elseif (tCurrentState="STOP") {
					Set pDefinition(tConfigName,"RunAsJob")=0
				}
			}
			If $Get($$$ConfigTempStop(tConfigName),0) {
				Set pDefinition(tConfigName,"RunAsJob")=0
			}
			If tBusinessType=$$$eHostTypeProcess {
				Set pDefinition(tConfigName,"OnTaskClassName")="Ens.Actor"
				If tItem.PoolSize=0 Set pDefinition(tConfigName,"QueueName")="Ens.Actor"
			}
			#; No RunAsJob for Services with no Adapter
			#; No RunAsJob for items with PoolSize=0
			#; RunAsJob=-1 if Adapter.#SINGLEPOOLJOB to run only 1 job regardless of PoolSize, e.g. for TCP.InboundAdapter
			#; Otherwise no change
			Set tRunAsJob=pDefinition(tConfigName,"RunAsJob"), pDefinition(tConfigName,"RunAsJob")=$S(
				  (tBusinessType=$$$eHostTypeService)&&(""=tItem.AdapterClassName()):0
				, pDefinition(tConfigName,"PoolSize")=0:0
				, tRunAsJob&&(""'=tItem.AdapterClassName())&&$parameter(tItem.AdapterClassName(),"SINGLEPOOLJOB"):-1
				, 1:tRunAsJob)
		}
		#; recursively get all the items in subproductions
		For i=1:1:tProduction.SubProductions.Count() {
			Set tSubProduction = tProduction.SubProductions.GetAt(i)
			Set tSC=..getProductionItems(tSubProduction,.pDefinition,.pAutoAdd)
			Quit:$$$ISERR(tSC)
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod getRunningJobData(Output pRunningCount, Output pRunningConfig) As %Status
{
	Set tStatus = $$$OK
	Try {
		Kill pRunningCount, pRunningJobs
		Set tJobStatusLocked = 0
		Do ##class(Ens.Job).MarkDeadJobs()
		Lock +$$$EnsJobStatus($$$SystemName):2
		If '$Test {
			Set tStatus = $$$EnsError($$$EnsErrCanNotAcquireJobRootLock,2)
			Quit
		}
		Set tJobStatusLocked = 1
		#; Find count of running jobs per config item
		Set tJob = ""
		For {
			Set tJob = $order($$$EnsJobStatus($$$SystemName,tJob))
			Quit:(tJob = "")
			Continue:$get($$$EnsJobStatus($$$SystemName,tJob,$$$eJobIsDead))
			Set tIsTemp = $get($$$EnsJobStatus($$$SystemName,tJob,$$$eJobIsTempJob))
			Set tJobConfigName = $get($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName),"<unknown ConfigItem>")
			Set pRunningConfig(tJobConfigName,tJob) = tIsTemp
			If 'tIsTemp {
				Set pRunningCount(tJobConfigName) = $get(pRunningCount(tJobConfigName))+1
			}
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tJobStatusLocked) Lock -$$$EnsJobStatus($$$SystemName)

	Quit tStatus
}

ClassMethod hasDisabledActorProcess(pProduction As Ens.Config.Production) As %Boolean
{
	Set tHasDisabledActorProcess = 0
	For i=pProduction.Items.Count():-1:1 {
		Set tItem = pProduction.Items.GetAt(i)
		If (tItem.BusinessType()=$$$eHostTypeProcess)&&(tItem.PoolSize=0)&&(tItem.Enabled=0) {
			Set tHasDisabledActorProcess = 1
			$$$LOGWARNING(tItem.Name_" uses the Ens.Actor queue and is marked as disabled. The Ens.Actor will not be disabled and "_tItem.Name_" will still process requests. In order to disable "_tItem.Name_" mark it as enabled and change to a dedicated pool before disabling again.")
		}
	}
	Quit tHasDisabledActorProcess
}

ClassMethod actualizeProductionDifferences(ByRef pDefinition, Output pToStopJob, ByRef pToStartConfig, ByRef pToDeleteConfig, ByRef pToUpdateScheduler As %Boolean, pTimeout As %Numeric, pForce As %Boolean, pCalledByScheduleHandler As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set $$$ConfigTrace("%Production")=pDefinition("%Production","Trace")
		Kill $$$ConfigSettingRoot("%Production")
		Merge $$$ConfigSettingRoot("%Production")=pDefinition("%Production","Setting")

		#; to stop jobs
		#dim tErrorJobs As %String
		#dim tJobConfigNames As %String
		Set tJob="" For { Set tJob=$Order(pToStopJob(tJob),1,tIsTemp)  Quit:tJob=""
			Set tJobConfigNames(tJob)=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName),"<unknown ConfigItem>")
			
			If tIsTemp<0 {
				Set tTxt=$$$FormatText($$$Text("%1: Not trying to stop 'visiting' job '%2'"),tJobConfigNames(tJob),tJob)
				$$$LOGWARNING(tTxt)
				Kill pToStopJob(tJob)
				Continue
			}
			Set:('$D(pToStartConfig(tJobConfigNames(tJob)))&&(tJobConfigNames(tJob)'="<unknown ConfigItem>")&&'tIsTemp) tConfigsStopped(tJobConfigNames(tJob))=""
			
			If pForce {
				// Use Ens.Job::Stop() to stop one job at a time only if forced;
				Set tSC = ##class(Ens.Job).Stop(tJob,pTimeout,pForce)
				If $$$ISERR(tSC) Set tErrorJobs(tJob) = tSC
			}
		}

		// Use Ens.Job::StopJobs() to stop all the provided jobs otherwise
		If 'pForce Do ##class(Ens.Job).StopJobs(.pToStopJob, pTimeout, .tErrorJobs)

		#; output logs related to pToStopJob
		Set tJob="" For { Set tJob=$Order(pToStopJob(tJob),1,tIsTemp)  Quit:tJob=""
			Set tClassName = $G($$$ConfigOnTaskClassName(tJobConfigNames(tJob)))
			// an error occurred when stopping this job
			If $D(tErrorJobs(tJob)) {
				Set tStatus = $$$GetJobMonitor($$$SystemName_":"_tJob,tJobConfigNames(tJob),$$$eMonitorStatus)  Set:tStatus="" tStatus="<unknown>"
				If tIsTemp {
					Set tTxt = $$$FormatText($$$Text("%1: Failed to stop JobPerConnection job '%2' within %3 seconds. Status '%4'"),tJobConfigNames(tJob),tJob,pTimeout,tStatus)
				} Else {
					Set tTxt = $$$FormatText($$$Text("%1: Failed to stop job '%2' within %3 seconds. Status '%4'"),tJobConfigNames(tJob),tJob,pTimeout,tStatus)
				}
				$$$LOGWARNING(tTxt)
				Continue
			}
			// successfully stopped this job
			$$$SysWebTrace($$$FormatText($$$Text("%1: Stopped job '%2'."),tJobConfigNames(tJob),tJob))
			$$$LOGINFO("ConfigItem '"_tJobConfigNames(tJob)_"' "_$S(tJobConfigNames(tJob)=tClassName:"",1:"("_tClassName_") ")_"stopped in job "_tJob)
		}

		If pCalledByScheduleHandler {
			Set tSC=$$$OK ; don't quit on failure to stop a job if called by Schedule Handler
		} Else {
			Quit:$$$ISERR(tSC)
		}

		;# If we are not restarting an item then we need to update pool size & RunAsJob if stopped by scheduler
		Set tConfigName="" For { Set tConfigName=$Order(tConfigsStopped(tConfigName))  Quit:tConfigName=""  Continue:tConfigName="%Production"
			Lock +$$$ConfigRoot(tConfigName)
			Set:$D(pDefinition(tConfigName,"PoolSize")) $$$ConfigPoolSize(tConfigName)=pDefinition(tConfigName,"PoolSize")
			Set:$D(pDefinition(tConfigName,"RunAsJob")) $$$ConfigRunAsJob(tConfigName)=pDefinition(tConfigName,"RunAsJob")
			#;Look to see if BP moved from private to general actor pool size:
			If ($G(pDefinition(tConfigName,"QueueName"))="Ens.Actor")&&($$$ConfigQueueName(tConfigName)'="Ens.Actor") {
				$$$LOGWARNING("ConfigItem '"_tConfigName_"' has been moved to the general actor pool. You will need to check if you need to move outstanding queue entries to the public queue.")
				Set $$$ConfigQueueName(tConfigName)="Ens.Actor"
			}
			Lock -$$$ConfigRoot(tConfigName)
		}
		
		#; unregister deleted configurations
		Set tLiveConfigName="" For { Set tLiveConfigName=$Order(pToDeleteConfig(tLiveConfigName))  Quit:tLiveConfigName=""  Continue:tLiveConfigName="%Production"
			$$$SysWebTrace($$$FormatText($$$Text("%1: stopping."),tLiveConfigName))
			Kill $$$DispatchNameToConfigName(tLiveConfigName)
			Lock +$$$ConfigRoot(tLiveConfigName)
			Kill $$$ConfigRoot(tLiveConfigName)
			Lock -$$$ConfigRoot(tLiveConfigName)
			
			#; remove classname from dispatch table and point to another one
			Set tDispatchName="" For { Set tDispatchName=$Order($$$DispatchNameToConfigName(tDispatchName))  Quit:tDispatchName=""
				If $$$DispatchNameToConfigName(tDispatchName)=tLiveConfigName {
					Kill $$$DispatchNameToConfigName(tDispatchName)
					
					#; see if any other config item has this classname - if so dispatch the classname to it instead
					Set tConfigName="" For { Set tConfigName=$Order(pDefinition(tConfigName))  Quit:tConfigName=""  Continue:tLiveConfigName="%Production"
						If pDefinition(tConfigName,"ClassName")=tDispatchName {
							Set $$$DispatchNameToConfigName(tDispatchName)=tConfigName
							Quit
						}
					}
				}
			}
		}
		#; register configurations
		Set $$$ConfigChecksum("%Production")=pDefinition("%Production","Checksum")
		Set tConfigName="" For { Set tConfigName=$Order(pToStartConfig(tConfigName))  Quit:tConfigName=""  
			
			#; set up monitor global for this item
			If '$D(pToStartConfig(tConfigName,"update")) $$$KillHostMonitor(tConfigName)
			$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"OK")
			
			Continue:tConfigName="%Production"
			
			Set tClassName = pDefinition(tConfigName,"ClassName")
			Set tOnTaskClassName = pDefinition(tConfigName,"OnTaskClassName")
			Set tBusinessType = pDefinition(tConfigName,"BusinessType")

			Set:pDefinition(tConfigName,"Register") $$$DispatchNameToConfigName(tConfigName)=tConfigName

			Lock +$$$ConfigRoot(tConfigName)
			Set $$$ConfigBusinessType(tConfigName)=tBusinessType
			Set $$$ConfigClassName(tConfigName)=tClassName
			Set $$$ConfigOnTaskClassName(tConfigName)=tOnTaskClassName
			Set $$$ConfigQueueName(tConfigName)=pDefinition(tConfigName,"QueueName")
			Set:$D(pDefinition(tConfigName,"%Id")) $$$ConfigId(tConfigName)=pDefinition(tConfigName,"%Id")
			Set $$$ConfigIsEnabled(tConfigName)=pDefinition(tConfigName,"IsEnabled")
			Set $$$ConfigChecksum(tConfigName)=pDefinition(tConfigName,"Checksum")
			Set $$$ConfigRunAsJob(tConfigName)=pDefinition(tConfigName,"RunAsJob")
			Set $$$ConfigPoolSize(tConfigName)=pDefinition(tConfigName,"PoolSize")
			Set $$$ConfigSchedule(tConfigName)=$g(pDefinition(tConfigName,"Schedule"))
			Set $$$ConfigTrace(tConfigName)=pDefinition(tConfigName,"Trace")
			Set $$$ConfigInactivityTimeout(tConfigName)=pDefinition(tConfigName,"InactivityTimeout")
			Kill $$$ConfigSettingRoot(tConfigName)
			Merge $$$ConfigSettingRoot(tConfigName)=pDefinition(tConfigName,"Setting")
			Lock -$$$ConfigRoot(tConfigName)
			If pDefinition(tConfigName,"IsEnabled") {
				TRY {
					Set tSC1=$classmethod(tClassName,"OnProductionStart",tConfigName)
				} CATCH {
					Set tZE=$ZE
					If $G(tZE)["<CLASS DOES NOT EXIST>" { Set tSC1=$$$ERROR($$$EnsErrGeneral,"Could not call OnProductionStart() to register nonexistent class '"_$G(tClassName)_"'") }
					Else { Set tSC1=$$$SystemError }
				}
				If $$$ISERR(tSC1) {
					$$$SysWebTrace($$$FormatText($$$Text("ConfigItem '%1' method OnProductionStart() failed: %2"),tConfigName,$$$StatusDisplayString(tSC1)))
					Kill pToStartConfig(tConfigName)
					$$$KillHostMonitor(tConfigName)
					Set tSC=$$$ADDSC(tSC,tSC1)
					Quit
				}
			}
		}
		Quit:$$$ISERR(tSC)

		#; start configurations
		Set tConfigName="" For { Set tConfigName=$Order(pToStartConfig(tConfigName))  Quit:tConfigName=""

			#; start jobs for this item
			Continue:'pDefinition(tConfigName,"RunAsJob") ; we're done with this item if it's non-runnable
			#; $$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Starting")
			For i=1:1:pToStartConfig(tConfigName) {
				Set tDebugForeground = pDefinition(tConfigName,"Foreground")
				Set tDebugDisableErrorTraps = pDefinition(tConfigName,"DisableErrorTraps")
				Set tSC1=##class(Ens.Job).Launch(tConfigName,tDebugForeground,tDebugDisableErrorTraps,,.tChildJob)
				If $$$ISERR(tSC1) {
					$$$SysWebTrace($$$FormatText($$$Text("ConfigItem '%1' failed to start: %2"),tConfigName,$$$StatusDisplayString(tSC1)))
				} ElseIf $D(pToStartConfig(tConfigName,"update")) {
						$$$SysWebTrace($$$FormatText($$$Text("ConfigItem '%1' updated in job %2"),tConfigName,$s(tChildJob'="":tChildJob,1:"(unknown)")))
				} Else {
					$$$SysWebTrace($$$FormatText($$$Text("ConfigItem '%1' started in job %2."),tConfigName,$s(tChildJob'="":tChildJob,1:"(unknown)")))
				}
			}
		}
		If pToUpdateScheduler {
			set tConfigName="" for  {
				set tConfigName=$o($$$ConfigRoot(tConfigName)) quit:tConfigName=""
				set $$$ConfigSchedule(tConfigName)=$g(pDefinition(tConfigName,"Schedule"))
			}
			Set tSC1=##class(Ens.ScheduleService).CallScheduleService()
			If $$$ISERR(tSC1) {
				$$$SysWebTrace($$$FormatText($$$Text("Scheduler failed to be updated: %1"),$$$StatusDisplayString(tSC1)))
				Set tSC=$$$ADDSC(tSC,tSC1)
			} Else {
				$$$SysWebTrace($$$FormatText($$$Text("Scheduler has been updated.")))
			}
		}
		Set $$$EnsRuntime("LastUpdate") = $$$timeUTC
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is for use on debugging systems only!
/// It will delete all traces of a suspended or troubled Production, including queued messages.
/// It will only function when the Production is not running.
ClassMethod CleanProduction(pKillAppDataToo As %Boolean) As %Status [ Internal ]
{
	If ..IsUnSupportedRemoteWorkerNamespace(.tSCSupported) {
		Return $$$EnsError($$$EnsErrProductionNetworkedProhibited)
	} ElseIf $$$ISERR(tSCSupported) { Return tSCSupported}

	Set tSC=..GetProductionStatus(.tProductionName,.tState)
	If tState=$$$eProductionStateRunning && $$$ISOK(tSC) {
		Quit $$$EnsError($$$EnsErrGeneral,"Cannot clean Production '"_tProductionName_"' while it is running")
	}
	Quit ..killProductionGlobals(.pKillAppDataToo)
}

ClassMethod killProductionGlobals(pKillAppDataToo As %Boolean = 0) As %Status
{
	Kill $$$EnsRuntime
	$$$KillAllEnsRuntimeAppData
	Kill $$$EnsQueue
	Kill $$$EnsJobStatusStarted($$$SystemName)
	Kill $$$EnsJobStatus($$$SystemName)
	Kill $$$EnsJobRequest
	Kill $$$EnsSuspended($$$SystemName)  Kill:$D(^Ens.Suspended)=1 ^Ens.Suspended ; our node was the only one and it is clean
	Kill:pKillAppDataToo ^Ens.AppData
	Quit $$$OK
}

/// <p>This method creates a Business Service object from which you can send messages.</p>
/// <p>pTargetDispatchName: is the configuration name of the business service.</p>
/// <p>pBusinessService: is an output parameter that contains the business service object.</p>
/// 
ClassMethod CreateBusinessService(pTargetDispatchName As %String, Output pBusinessService As Ens.BusinessService) As %Status
{
	Set $ZT="Trap"
	#dim tSC As %Status = $$$OK
	#dim tSuperSession As %String = ""
	#dim tConfigName, tClassName As %String

	Do {
		If '$$$IsdefObject(pBusinessService) || (pBusinessService'=$G(%cspsoapservice)) {
			Kill pBusinessService Set pBusinessService=$$$NULLOREF
		}
		If ($IsObject(pBusinessService) && pBusinessService.%Extends("EnsLib.SOAP.Service") && pBusinessService.SOAPInvoked) ; allow funky HealthShare call from OnProductionStart()
		 && '##class(Ens.Director).IsProductionRunning() { ; Avoid using Ens.Director::GetProductionStatus() to reduce lock contention
			Set tSC =$$$ERROR($$$EnsErrProductionNotRunning)
			Quit
		}
		Set tConfigName = $get($$$DispatchNameToConfigName(pTargetDispatchName))
		If tConfigName="" Set tSC=$$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)  Quit
		If $$$ConfigBusinessType(tConfigName)'=$$$eHostTypeService Set tSC=$$$ERROR($$$EnsErrGeneral,"Not a BusinessService")  Quit
		If ##class(Ens.Job).ShouldBeQuiescent() Set tSC=$$$ERROR($$$EnsErrProductionQuiescent)  Quit
		If '$$$ConfigIsEnabled(tConfigName) Set tSC=$$$ERROR($$$EnsErrConfigDisabled,tConfigName)  Quit
		Set tClassName = $$$ConfigClassName(tConfigName)
		Set:'$D($$$EnsJobLocal("ConfigName")) $$$EnsJobLocal("TCPIn.OutsideJob")=1
		If '$IsObject(pBusinessService) {
			Set pBusinessService=$classmethod(tClassName,"%New",tConfigName)
			If pBusinessService=$$$NULLOREF Set tSC=%objlasterror $$$LOGERROR("Failed to create BusinessService "_tConfigName_"; Status="_$$$StatusDisplayString(%objlasterror))  Quit
		} Else {
			#; Initialize instance already instantiated by SOAP CSP framework
			If tClassName'=$classname(pBusinessService) {
				Set tSC=$$$ERROR($S(""=tClassName:$$$EnsErrSOAPConfigName,1:$$$EnsErrSOAPConfigClass),tConfigName,tClassName)
				Quit
			}
			Set tSC=pBusinessService.initConfig(tConfigName)
			If $$$ISERR(tSC) { $$$LOGERROR("Failed to initialize SOAP BusinessService '"_tConfigName_"'; Status="_$$$StatusDisplayString(tSC))  Quit }
		}
		If '$D($$$EnsJobLocal("ConfigName")) { ; means we're not inside Job:Start() nor an already-registered outside job
			If ($E($IO,1,5)="|TCP|") {
				Set tTCPDevice=$IO
			} Else {
				/*	If we came in from %SOAP.WebService for example
					then current device has already been set to null.
					The first device in the list will begin |TCP|.
					Use an API that will have privileges for $View command
					on self process.
				*/
				Set tTCPDevice = ##class(%SYS.Ensemble).GetFirstDeviceIfTCP(.tProcViewSC)
				/* if an unexpected error proceed as before but provide debug logging */
				If $$$ISERR(tProcViewSC) $$$catTRACE("connwait","Failed trying to examine own devices. "_$system.Status.GetErrorText(tProcViewSC))
				If tTCPDevice'="" Set tEntryIO=$IO
			}
			If (tTCPDevice'="") {
				#; turn off <DISCONNECT>  mode and "external interrupts" from the webserver because they are bad for IRIS Interoperability processing
				Use tTCPDevice:(::"-D")
				Do $System.Util.SetInterruptEnable(0)
				Set pBusinessService.%OutsideCreated=tTCPDevice
				If $Data(tEntryIO) Use tEntryIO /* put current device back */
				#; Look for Super Session header in CSP created %request HTTP Header or URL parameter.
				#; We may be here via System Management Portal pages calling updates to the production.
				Try {
					If (tClassName'="Ens.ScheduleService") && $$$IsdefObject(%request) && %request.%IsA("%CSP.Request") &&
						($D(%request.CgiEnvs($$$EnsHTTPHeaderSuperSessionCgiEnvs),tSuperSession)#2 ||
					 		..superSessionInURLParams(.tSuperSession)) {
						Set pBusinessService.%SuperSession=tSuperSession
						#;Need to ensure that any cleanup of %SuperSession is able to identify early set. NoOP if tSuperSession is ""
						Set pBusinessService.%SuperSessionCreatedBeforeSession=1
					}
				} Catch {/* Ignore errors */}

			} Else {
				Set pBusinessService.%OutsideCreated=1 ; special flag: outside job but not changing $IO mode
			}
			#; unregister, restoration of <DISCONNECT>  mode and "external interrupts" is done in OnTeardown()
			Kill $$$EnsJobLocal("Config") Merge $$$EnsJobLocal("Config")=^Ens.Config
			Kill $$$EnsJobLocal("Debug")  Merge $$$EnsJobLocal("Debug")=^Ens.Debug
			Set $$$EnsConfig("%ModIndexFlag")=$$$EnsMirrorIndex
			Set tSC = ##class(Ens.Job).Register(tConfigName,-1,0,$Job,"Xternal",$$$eJobStatusVisiting)  Quit:$$$ISERR(tSC)
			Set $$$EnsJobLocal("ConfigName")=tConfigName
		}
		Do ##class(Ens.Util.Trace).SetTraceOptimizer(tConfigName)
		$$$sysTRACE($$$FormatText($$$Text("Created new BusinessService instance for '%1'."),pTargetDispatchName))
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Return 1 if the named config item is enabled
ClassMethod IsItemEnabled(pConfigItemName As %String, pStatus As %Status) As %Boolean
{
	Do ..ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	Set tFoundItem=##class(Ens.Config.Production).findItemIdByName(tProductionName,tItemName,tCommentOrClass,.pStatus,.tEnabledItemIds)  Quit:$$$ISERR(pStatus) 0
	Quit tEnabledItemIds ; count
}

/// <p>Enable or disable a ConfigItem in a Production. The Production may be running or not.</p>
/// <p>The pConfigItemName argument gives the name of the config item to be enabled or disabled.</p>
/// <p>In the case of multiple matching items with the same config name, if any is already enabled then
///  the pEnable=1 option will do nothing and the pEnable=0 option will disable the running matching
///   production item, or if not running then the first matching enabled item that it finds. The pDoUpdate=1 option
///   will call the Ens.Director.UpdateProduction() method in this class.</p>
/// <p>See <method>ParseConfigItemName</method> for full syntax of the ConfigItem name specification string.</p>
/// 
ClassMethod EnableConfigItem(pConfigItemName As %String, pEnable As %Boolean = 1, pDoUpdate As %Boolean = 1) As %Status
{
	Do ..ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	Set tProduction = ##class(Ens.Config.Production).%OpenId(tProductionName,,.tSC)
	Quit:'$IsObject(tProduction)||$$$ISERR(tSC) $$$ERROR($$$EnsErrProductionNotRegistered,tProductionName,$$$StatusDisplayString(tSC))

	#; Scan list of all matching enabled production items, and select the first we find that's a perfect match
	Set tFoundItem=tProduction.findItemByName(tItemName,tCommentOrClass,.tSC,.tEnabledItems)  Quit:$$$ISERR(tSC) tSC
	#; PoolSize cannot be overidden by System Default Settings to 0 so no need to check for any SDS PoolSize override
	If 'pEnable && (tFoundItem.PoolSize = 0) && (tFoundItem.BusinessType() = $$$eHostTypeProcess) Quit $$$ERROR($$$EnsErrGeneral,"Cannot disable Business Process that has pool size of 0.")
	
	#; Check for overridden Enabled.
	If ##class(Ens.Config.DefaultSettings).%GetSetting(tProductionName,tItemName,tFoundItem.ClassName,"","Enabled",.tSDSEnabled) {
		Set tEnabled = tSDSEnabled
		Set tEnableOverridden = 1
		#; know have setting so need to find criteria in case muliple found items.
		Do ##class(Ens.Config.DefaultSettings).%GetMatchCriteria(tProductionName,tItemName,tFoundItem.ClassName,"","Enabled",.tMatchCriteria)
	} Else {
		Set tEnabled = tFoundItem.Enabled
		Set tEnableOverridden = 0
	}
	Quit:tEnabled=pEnable $$$ERROR($$$EnsErrGeneral,"Item "_pConfigItemName_" already "_$S(pEnable:"enabled",1:"disabled")_" in Production "_tProductionName)

	Set tSaveProduction = 0
	#;  Disable all other previously enabled items found with this name
	#;  Account for multiple SDS
	For i=1:1:tEnabledItems {
		If tEnabledItems(i)'=tFoundItem {
			If ##class(Ens.Config.DefaultSettings).%GetMatchCriteria(tProductionName,tEnabledItems(i).Name,tEnabledItems(i).ClassName,"","Enabled",.tCloneMatchCriteria) && (tCloneMatchCriteria'=$Get(tMatchCriteria)) {
				If $ListValid(tCloneMatchCriteria) {
					Set tProductionNameMatch = $LI(tCloneMatchCriteria,1)
					Set tItemNameMatch = $LI(tCloneMatchCriteria,2)
					Set tHostClassNameMatch = $LI(tCloneMatchCriteria,3)
					Set tSettingNameMatch = $LI(tCloneMatchCriteria,4)
					&SQL(UPDATE ENS_CONFIG.DEFAULTSETTINGS SET SettingValue = 0 WHERE ProductionName = :tProductionNameMatch AND ItemName = :tItemNameMatch AND  HostClassName = :tHostClassNameMatch AND SettingName = :tSettingNameMatch)
				}
			} Else {
				Set tEnabledItems(i).Enabled=0
				Set tSaveProduction = 1
			}
		}
	}
	#; Then Enable the found item
	If tEnableOverridden {
		/* Need to change the System Defaut Setting that was used to identify if enabled or disabled. */
		If $ListValid(tMatchCriteria) {
			Set tProductionNameMatch = $LI(tMatchCriteria,1)
			Set tItemNameMatch = $LI(tMatchCriteria,2)
			Set tHostClassNameMatch = $LI(tMatchCriteria,3)
			Set tSettingNameMatch = $LI(tMatchCriteria,4)
			&SQL(UPDATE ENS_CONFIG.DEFAULTSETTINGS SET SettingValue = :pEnable WHERE ProductionName = :tProductionNameMatch AND ItemName = :tItemNameMatch AND  HostClassName = :tHostClassNameMatch AND SettingName = :tSettingNameMatch)
		}
	} Else {
		Set tFoundItem.Enabled=pEnable
		Set tSaveProduction = 1
	}

	#; Save if needed
	If tSaveProduction Set tSC = tProduction.%Save()  Quit:$$$ISERR(tSC) tSC

	#; Log
	If pEnable {
		$$$LOGINFO($$$FormatText($$$Text("Enabled item '%1' in Production '%2'."),tItemName_$S(""=tCommentOrClass:"",1:"|"_tCommentOrClass),tProductionName))
	} Else {
		$$$LOGINFO($$$FormatText($$$Text("Disabled item '%1' in Production '%2'."),tItemName_$S(""=tCommentOrClass:"",1:"|"_tCommentOrClass),tProductionName))
	}

	#; Clear a possible TemporarilyStopped flag
	Kill $$$ConfigTempStop(tItemName)

	#; Audit
	Set $Ecode = ""
	If $Stack(-1)>1 {
		Set tCaller = $Stack($Stack(-1)-1,"PLACE") // "caller id"
	}
	Else {
		Set tCaller = "direct call to ##class(Ens.Director).EnableConfigItem"
	}
	Set tSC2 = $$$AuditModifyProductionConfig(tProductionName,tItemName,"item "_$S(pEnable:"enabled",1:"disabled")_" by "_tCaller)

	Quit:pDoUpdate ..UpdateProduction(..GetRunningProductionUpdateTimeout())
	Quit tSC
}

/// 	
/// <p>The pConfigItemName argument may contain the following elements:</p>
/// <p>ProductionName||ConfigName|CommentOrClassname</p>
/// <p>Only the ConfigName portion is required.
/// If ProductionName is not given, then the currently running or last run Production will be used.
/// CommentOrClassname is the name shown in the Config page's dropdown list for multiple items having the
/// same ConfigName. If it is not given, then if more than one item of the given ConfigName exists, all will match.</p>
/// <p>In order for this method to work properly, none of the names of the items in your production should 
/// contain the '|' character.</p>
/// 
ClassMethod ParseConfigItemName(pConfigItemName As %String, Output pProductionName As %String, Output pItemBaseName As %String, Output pItemCommentOrClassName As %String)
{
	If pConfigItemName["||" { Set pProductionName=$P(pConfigItemName,"||"), pItemBaseName=$P(pConfigItemName,"||",2,99) }
	Else { Set pProductionName="", pItemBaseName=pConfigItemName }
	Set pItemCommentOrClassName=$P(pItemBaseName,"|",2,99), pItemBaseName=$P(pItemBaseName,"|")	
	Set:""=pProductionName pProductionName=..GetActiveProductionName()
}

/// Get the name of the current running or last used production
ClassMethod GetActiveProductionName() As %String [ CodeMode = expression ]
{
$G($$$EnsRuntime("Name"),$G(^Ens.Suspended,$G(^Ens.Configuration("csp","LastProduction"))))
}

/// This method permanently deletes the specified production and its underlying class. <br/>
/// It returns an error and will not delete the class if the production class to be
/// deleted is the current production for the namespace and is not stopped.<br>
/// It is the caller's responsibility to check and handle the necessary Source Control environment used
/// by $SYSTEM.OBJ.Delete() if needed. <br/>
/// The parameter pLeaveProductionDeleteToCaller allows the caller to delete the Production
/// class within a separate Source Control aware API and not use $SYSTEM.OBJ.Delete().<br>
ClassMethod DeleteProduction(pProdId As %String, pLeaveProductionDeleteToCaller As %Boolean = 0) As %Status
{
	Set $ZT="Trap"
	#dim tSC=$$$OK
	#dim tLocked, tProdName, tState
	Do {
		// get lock on running productions
		Set tLocked = 0
		Lock +$$$EnsRuntime:30
		If '$Test Set tSC=$$$EnsError($$$EnsErrCanNotAcquireRuntimeLock,30) Quit
		Set tLocked = 1
		// find out the currently running (or not-fully-stopped) production; if it is ours, don't delete it
		Set tSC=##class(Ens.Director).GetProductionStatus(.tProdName,.tState)  Quit:$$$ISERR(tSC)
		If (tState'=$$$eProductionStateStopped) {
			If pProdId=tProdName { 
				Set tSC = $$$EnsError($$$EnsErrGeneral,"Production is not fully stopped, cannot delete it.")
			}
		}  Quit:$$$ISERR(tSC)
		
		// delete production class and projection
		If 'pLeaveProductionDeleteToCaller Set tSC=$System.OBJ.Delete(pProdId,"-d")  Quit:$$$ISERR(tSC)
		
		// see if we need to kill the last production run global 
		If $D(^Ens.Configuration("csp","LastProduction"))  {
			If (^Ens.Configuration("csp","LastProduction") = pProdId) Kill ^Ens.Configuration("csp","LastProduction")
		}

	} While (0)
Exit
	// release lock on running productions
	If tLocked Lock -$$$EnsRuntime
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is deprecated.
/// Please call GetProductionSettingValue("",tSetting,.tStatus) instead
ClassMethod GetCurrProductionSettingValue(pSetting As %String, Output pStatus As %Status) As %String
{
	Quit ..GetProductionSettingValue("",.pSetting,.pStatus)
}

/// This method is deprecated.
/// Please call GetProductionSettings("",.tSettings) instead
ClassMethod GetCurrProductionSettings(Output pSettings) As %Status
{
	Quit ..GetProductionSettings("",.pSettings)
}

ClassMethod GetProductionSettingValue(pProd As %String, pSetting As %String, Output pStatus As %Status) As %String
{
	If ""=pProd {
		Do ..ParseConfigItemName("",.pProd)
		If ""=pProd Set pStatus=$$$ERROR($$$EnsErrGeneral,"No current Production found") Quit ""
	}
	Set pStatus=$$$OK,tFound=0
	Set tProduction=##class(Ens.Config.Production).%OpenId(pProd,,.tSC)  If '$IsObject(tProduction)||$$$ISERR(tSC) Set pStatus=$$$ERROR($$$EnsErrGeneral,"No Production '"_pProd_"' found: "_$$$StatusDisplayString(tSC))  Quit ""
	Set tSC = tProduction.PopulateVirtualSettings()
	Set tIndex="" For { Set tIndex = tProduction.VirtualSettings.Next(tIndex) Quit:tIndex=""
		Set tOneSetting = tProduction.VirtualSettings.GetAt(tIndex)
		If $LI(tOneSetting,2)=pSetting Set tValue=$LI(tOneSetting,3),tFound=1 Quit
	}
	If 'tFound Set tValue="",pStatus=$$$ERROR($$$EnsErrGeneral,"No Setting '"_pSetting_"' found for Production '"_pProd_"'")
	Quit tValue
}

ClassMethod GetHostSettingValue(pConfigItemName As %String, pSetting As %String, Output pStatus As %Status) As %String
{
	Quit ..GetItemSettingValue(pConfigItemName,"Host",pSetting,.pStatus)
}

ClassMethod GetAdapterSettingValue(pConfigItemName As %String, pSetting As %String, Output pStatus As %Status) As %String
{
	Quit ..GetItemSettingValue(pConfigItemName,"Adapter",pSetting,.pStatus)
}

ClassMethod GetItemSettingValue(pConfigItemName As %String, pType As %String, pSetting As %String, Output pStatus As %Status) As %String
{
	Do ..ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	If ""=tProductionName Set pStatus=$$$ERROR($$$EnsErrGeneral,"No current Production found")  Quit ""
	#; Find the item in this block
	Set pStatus=$$$OK
	&sql(Declare C1 Cursor for
		Select ClassName,Comment,Enabled,Settings Into :xClassName,:xComment,:xEnabled,:xSettings From Ens_Config.Item Where Production=:tProductionName and Name=:tItemName Order By ID)
	Set SQLCODE=0  &sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE  Set:$C(0)=xClassName xClassName=""  Set:$C(0)=xComment xComment=""
		#; If CommentOrClass is specified, then it must match either tItem.ClassName or tItem.Comment
		Continue:(""'=tCommentOrClass)&&(tCommentOrClass'=xClassName)&&(tCommentOrClass'=xComment)
		#; Check for overridden Enabled
		If ##class(Ens.Config.DefaultSettings).%GetSetting(tProductionName,tItemName,xClassName,"","Enabled",.tSDSEnabled) {
			Set xEnabled = tSDSEnabled
		}
		#; Save the found ones, with the subscript indicating the degree of preference; prefer an enabled one over a disabled one and a comment match over a classname match
		If (""=tCommentOrClass)||(tCommentOrClass=xClassName) Set tPref=$S(xEnabled:1,1:3), tFoundItems(tPref)=xSettings, tFoundItems(tPref,"c")=xClassName  Continue
		If (""=tCommentOrClass)||(tCommentOrClass=xComment)   Set tPref=$S(xEnabled:2,1:4), tFoundItems(tPref)=xSettings, tFoundItems(tPref,"c")=xClassName  Continue
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	If SQLCODE&&(SQLCODE'=100) Set pStatus=$$$ERROR($$$EnsErrGeneral,"No Production '"_tProductionName_"' with config item '"_tItemName_" found: SQLCODE="_SQLCODE)  Quit ""

	Set tPref=$O(tFoundItems(""),1,tFoundSettings)
	If 'tPref Set pStatus=$$$ERROR($$$EnsErrConfigItemNotFound,tItemName_$S(""=tCommentOrClass:"",1:"|"_tCommentOrClass),tProductionName)  Quit ""

	#; We've found the item, now find the requested setting
	Set tValue=##class(Ens.Config.Item).getModifiedSettingValue(tProductionName,tItemName,pType,tFoundItems(tPref,"c"),pSetting,tFoundSettings,.pStatus)
	Quit tValue
}

ClassMethod GetProductionSettings(pProd As %String, Output pSettings) As %Status
{
	If ""=pProd {
		Do ..ParseConfigItemName("",.pProd)
		If ""=pProd Quit $$$ERROR($$$EnsErrGeneral,"No current Production found")
	}
	Set tProduction=##class(Ens.Config.Production).%OpenId(pProd,,.tSC)  Quit:'$IsObject(tProduction)||$$$ISERR(tSC) $$$ERROR($$$EnsErrGeneral,"No Production '"_pProd_"' found: "_$$$StatusDisplayString(tSC))
	Set tSC = tProduction.PopulateVirtualSettings() Quit:$$$ISERR(tSC) tSC
	Set tIndex="" For { Set tIndex = tProduction.VirtualSettings.Next(tIndex) Quit:tIndex=""
		Set tOneSetting = tProduction.VirtualSettings.GetAt(tIndex)
		Set pSettings($LI(tOneSetting,2))=$LI(tOneSetting,3)
	}
	Quit $$$OK
}

ClassMethod GetHostSettings(pConfigItemName As %String, Output pSettings) As %Status
{
	Quit ..GetItemSettings(pConfigItemName,"Host",.pSettings)
}

ClassMethod GetAdapterSettings(pConfigItemName As %String, Output pSettings) As %Status
{
	Quit ..GetItemSettings(pConfigItemName,"Adapter",.pSettings)
}

ClassMethod GetItemSettings(pConfigItemName As %String, pType As %String, Output pSettings) As %Status
{
	Do ..ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	If ""=tProductionName Quit $$$ERROR($$$EnsErrGeneral,"No current Production found")

	#; Find the item in this block
	Set tSC=$$$OK, tFoundItem=$$$NULLOREF	
	&sql(Declare C2 Cursor for
		Select ID,ClassName,Comment,Enabled Into :xID,:xClassName,:xComment,:xEnabled From Ens_Config.Item Where Production=:tProductionName and Name=:tItemName Order By ID)
	Set SQLCODE=0  &sql(OPEN C2) For { &sql(FETCH C2)  Quit:SQLCODE  Set:$C(0)=xClassName xClassName=""  Set:$C(0)=xComment xComment=""
		#; If CommentOrClass is specified, then it must match either tItem.ClassName or tItem.Comment
		Continue:(""'=tCommentOrClass)&&(tCommentOrClass'=xClassName)&&(tCommentOrClass'=xComment)
		#; Check for overridden Enabled
		If ##class(Ens.Config.DefaultSettings).%GetSetting(tProductionName,tItemName,xClassName,"","Enabled",.tSDSEnabled) {
			Set xEnabled = tSDSEnabled
		}
		#; Save the found ones, with the subscript indicating the degree of preference; prefer an enabled one over a disabled one and a comment match over a classname match
		If (""=tCommentOrClass)||(tCommentOrClass=xClassName) Set tFoundItems($S(xEnabled:2,1:4))=xID Continue
		If (""=tCommentOrClass)||(tCommentOrClass=xComment)   Set tFoundItems($S(xEnabled:1,1:3))=xID Continue
	} Set tCode=SQLCODE &sql(CLOSE C2) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"No Production '"_tProductionName_"' with config item '"_tItemName_" found: SQLCODE="_SQLCODE)

	Set:$O(tFoundItems(""),1,tFoundId) tFoundItem=##class(Ens.Config.Item).%OpenId(tFoundId)
	If '$IsObject(tFoundItem) Quit $$$ERROR($$$EnsErrConfigItemNotFound,tItemName_$S(""=tCommentOrClass:"",1:"|"_tCommentOrClass),tProductionName)
	#; We've found the item, now get its settings
	Set tSC = tFoundItem.PopulateVirtualSettings() Quit:$$$ISERR(tSC) tSC
	Set tIndex="" For { Set tIndex = tFoundItem.VirtualSettings.Next(tIndex)  Quit:tIndex=""
		Set tOneSetting = tFoundItem.VirtualSettings.GetAt(tIndex)
		If $LI(tOneSetting,1)'=pType Continue
		Set pSettings($LI(tOneSetting,2))=$LI(tOneSetting,3)
	}
	Quit $$$OK
}

/// pProductionName argument is the production to start automatically on startup. <br>
/// An empty pProductionName clears any auto-start production in the namespace. <br>
/// Productions are started in descending order of priority followed by alphabetically.<br>
/// pStartupPriority argument is used to set the relative priority for auto start of productions 
/// within the instance. The default is to check first for a recommended value and if a recommended
/// value has not been set then the default value of 0 is used.<br>
/// The setting of a recommended value is currently reserved for internal use. <br>
ClassMethod SetAutoStart(pProductionName As %String, pStartupPriority As %Integer = "") As %Status
{
	If $get(pProductionName)="" {
	 	#;Replace global kill
		ZKill ^Ens.AutoStart
		ZKill ^Ens.AutoStart("StartupPriority")
	} Else {
		// Validate the production. No need to lock.
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,0,.tSC)
		If '$IsObject(tProduction)||$$$ISERR(tSC) {
			Set tSC=$$$EnsError($$$EnsErrProductionNotRegistered,pProductionName,$$$StatusDisplayString(tSC))
			Quit tSC
		}
		Set ^Ens.AutoStart=pProductionName
		If pStartupPriority="" Set pStartupPriority = ..GetAutoStartRecommendedPriority(pProductionName,.tSC,0)
		If $$$ISERR(tSC) Quit tSC
		Set ^Ens.AutoStart("StartupPriority")=+pStartupPriority
		If '$D(^Ens.Configuration("csp","LastProduction")) {
			Set ^Ens.Configuration("csp","LastProduction")=pProductionName
		}
	}
	
	Quit $$$OK
}

/// Internal Method
ClassMethod GetAutoStartRecommendedPriority(pProductionName As %String, Output pSC As %Status = {$$$OK}, pValidateProductionName As %Boolean = 1) As %Integer [ Internal ]
{
	If $get(pProductionName)="" Return 0
	
	// Validate the production. No need to lock.
	If pValidateProductionName {
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,0,.pSC)
		If '$IsObject(tProduction)||$$$ISERR(pSC) {
			Set pSC=$$$EnsError($$$EnsErrProductionNotRegistered,pProductionName,$$$StatusDisplayString(pSC))
			Return 0
		}
	}	
	Return +$G(^Ens.AutoStart("RecommendedPriority",pProductionName),0)
}

/// Internal method
ClassMethod SetAutoStartRecommendedPriority(pProductionName As %String, pRecommendedStartupPriority As %Integer = 0) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	// Validate the production
	Set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,,.tSC)
	If '$IsObject(tProduction)||$$$ISERR(tSC) {
		Set tSC=$$$EnsError($$$EnsErrProductionNotRegistered,pProductionName,$$$StatusDisplayString(tSC))
		Quit tSC
	}
	If +pRecommendedStartupPriority=0 {
		#;Remove since 0 is the default.
		Kill ^Ens.AutoStart("RecommendedPriority",pProductionName)
	} Else {
		Set ^Ens.AutoStart("RecommendedPriority",pProductionName)=+pRecommendedStartupPriority
	}
	Quit $$$OK
}

/// The parameter pMessagesLogText is optional text to be used by the 
/// messages log info recorded by the caller (%Library.EnsembleMgr OnSystemStartup)
ClassMethod SystemStart(Output pMessagesLogText As %String = "") As %Status
{
	If $get(^Ens.AutoStart)="" Quit $$$OK

	If ..IsUnSupportedRemoteWorkerNamespace(.tSCSupported, , 1 /* Update cache on system start */ ) {
		Set pMessagesLogText = "Not auto-starting the production on this instance since detected this is a shared namespace on a remote node."
		$$$LOGINFO(##class(%SYS.System).GetNodeName(0) _ ": " _ pMessagesLogText)
		If $$$ISERR(tSCSupported) $$$LOGSTATUS(tSCSupported)
		Quit $$$OK
	}
	#; Error encountered trying to see if supported remote worker
	If $$$ISERR(tSCSupported) $$$LOGSTATUS(tSCSupported)

	Set tSC=..GetProductionStatus(.tProductionName,.tState) 
	If $$$ISERR(tSC) {
		$$$LOGSTATUS(tSC)
		Quit tSC
	}
	If tState=$$$eProductionStateTroubled {
		$$$LOGWARNING("SystemStart recovers troubled production before auto-start.")
		Do ..RecoverProduction()
	}
	Quit ..StartProduction(^Ens.AutoStart)
}

ClassMethod SystemStop() As %Status
{
	#; Silent skip stop production if ought not to be running
	If ..IsUnSupportedRemoteWorkerNamespace() Quit $$$OK 

	Do ##class(Ens.Production).Stop(..GetRunningProductionShutdownTimeout(),1)
	Kill ^%SYS("Ensemble","StoppingProduction",$znspace)
	Quit $$$OK
}

ClassMethod GetRunningProductionShutdownTimeout() As %Integer
{
	Quit $G($$$ConfigProdSetting("ShutdownTimeout"),120)
}

ClassMethod GetRunningProductionUpdateTimeout() As %Integer
{
	Quit $G($$$ConfigProdSetting("UpdateTimeout"),10)
}

ClassMethod GetSystemProductionSummary(ByRef pInfo) As %Status
{
	Set tNS = ""
	For {
		Set tNS = $O(^%SYS("Ensemble","InstalledNamespace",tNS))
		Quit:(tNS = "")
				
		// For each namespace, grab the list of productions for that namespace
		Kill tNSInfo
		Set tSC = ..GetProductionSummary(.tNSInfo, tNS)
		
		// Store the data by namespace name
		Set pInfo(tNS)=""
		If $$$ISOK(tSC) {		
			Merge pInfo(tNS) = tNSInfo
		} Else {
			// We might get $$$UserInsufficentPrivForNameSpace (i.e. <PROTECT>) ...
		}
	}
	
	Quit $$$OK
}

ClassMethod GetProductionSummary(ByRef pInfo, pNamespace As %String = {$namespace})
{
	Set $ZTrap = "Trap"
	Set tSC = $$$OK
	Set tCurrentNS = $namespace
	Do {
		// Check for permission
		If $SYSTEM.Security.GetGlobalPermission(pNamespace, "Ens.Runtime")="" {
			Set tSC = $$$ERROR($$$UserInsufficentPrivForNameSpace,pNamespace)
			Quit
		}
		
		// Switch namespaces
		If tCurrentNS'=pNamespace ZNSpace pNamespace
		
		// Loop over the productions in this namespace
		Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:ProductionStatus")
		If '$IsObject(tRS) Set tSC = %objlasterror Quit
		
		Set tSC = tRS.Execute()
		Quit:$$$ISERR(tSC)
		
		While (tRS.Next()) {
			Set tProduction = tRS.Data("Production")
			Set pInfo(tProduction)=$LB(tRS.Data("Status"),tRS.Data("LastStartTime"),tRS.Data("LastStopTime"),$G(^Ens.AutoStart)=tProduction)
		}

		Kill tRS
		
	} While 0
Exit
	// Make sure we switch back to the right namespace
	If $namespace'=tCurrentNS ZNspace tCurrentNS
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Console for managing/monitoring InterSystems IRIS from a terminal prompt.
ClassMethod Console(pTarget As %String = {$NAMESPACE})
{
	Set tTarget = pTarget

	Do setup(tTarget)
	Set temp="",lines=(my-6),last=-1,to=1

	Do {
		Do collect(tTarget,.tData,lines)
		
		If last'=$G(tData(1)) {
			Do render(.tData,lines)
			Set last=$G(tData(1)),to=0.5
		} Else {
			Set to=to+0.5
		}

		Set tCmd = $$prompt($S(to>5:5,1:to),.temp)
		If tCmd="" Continue

		Set tCmdUpper = $P($ZCVT(tCmd,"U")," ")
		Set tArgs = $P(tCmd," ",2,$L(tCmd," "))
		Set clearto = 5

		Quit:"/Q/QUIT/"[("/"_tCmdUpper_"/")

		If "/STO/STOP/"[("/"_tCmdUpper_"/") {
			do director("StopProduction")
		} ElseIf "/STA/START/"[("/"_tCmdUpper_"/") {
			Set tProduction = $P(tArgs," ")
			Set:tProduction="" tProduction=$G(^Ens.Configuration("csp","LastProduction"))
			do director("StartProduction",tProduction)
		} ElseIf "/UP/UPDATE/"[("/"_tCmdUpper_"/") {
			do director("UpdateProduction")
		} ElseIf "/RES/RESTART/"[("/"_tCmdUpper_"/") {
			do director("RestartProduction")
		} ElseIf "/CL/CLEAN/"[("/"_tCmdUpper_"/") {
			do director("CleanProduction")
		} ElseIf "/RE/RECOVER/"[("/"_tCmdUpper_"/") {
			do director("RecoverProduction")
		} ElseIf "/E/X/EXAMINE/"[("/"_tCmdUpper_"/") {
			If tArgs'="" {
				do examine(tArgs)
				set clearto=60
			} else {
				Do reporterr("Usage: "_tCmd_" <id>",.temp)
				Continue
			}
		} ElseIf "/P/PURGE/"[("/"_tCmdUpper_"/") {
			Do purge(tTarget)
			Do setup(tTarget)
			Continue
		} Else {
			Do reporterr("Unknown command: "_tCmd,.temp)
			Continue
		}

		Do report("Press any key to continue ...",0,clearto,.temp)
		Set last=""

	} While (1)

	Write /C(1,my-2)
	Quit
	;
wipe
	For i=1:1:lines {
		Write /C(1,2+i),$$pad("",mx)
	}
	Write /C(1,3)
	q
director(cmd,arg)
	do wipe	
	do $classmethod("Ens.Director",cmd,.arg)
	q
examine(id)
	do wipe
	s i=1
	s obj=##class(Ens.Util.Log).%OpenId(id)
	f f="_%Id","TimeLogged","Type","ConfigName","Job","MessageId","SessionId","SourceClass","SourceMethod" {
		s v=$s(f["_":$method(obj,$tr(f,"_")),1:$property(obj,f)),f=$tr(f,"_")
		w /C(1,4+i),$J(f,14),": "
		if f="Type" {
			w @typecolor(v),$$pad(##class(Ens.Util.Log).TypeLogicalToDisplay(v),mx-16),@normal
		} else {
			w $$pad(v,mx-16)
		}
		s i=i+1
	}
	w /C(1,5+i),$J("Text",14),":"
	s t=$tr(obj.Text,$C(13,10,9),"   ")
	while (t'="") {
		w /c(17,5+i),@panel1,$$pad(t,mx-16),@normal
		s t=$E(t,(mx-16)+1,$l(t)),i=i+1
	}
	i $IsObject(obj.Stack),obj.Stack.Count()>0 {
		w /C(1,6+i),$J("Stack",14),":"
		f f=1:1:obj.Stack.Count() {
			w /c(17,6+i),@panel2,$$pad(obj.Stack.GetAt(f),mx-16),@normal
			s i=i+1
		}
	}
	q
setup(ns)
	// Switch to the DTM mnemonic space to get nice terminal I/O commands
	Use 0::"^%XDTM"
	Do termdimensions

	Set bold="/color(10,9)"
	Set blink="/am"
	Set normal="/aa"
	Set panel1="/color(1,7)"
	Set panel2="/color(1,11)"

	// types are Assert,Error,Warning,Info,Trace,Alert
	Set typecolor(1)="/aa"
	Set typecolor(2)="/color(6,4)"
	Set typecolor(3)="/color(0,6)"
	Set typecolor(4)="/color(0,3)"
	Set typecolor(5)="/color(0,1)"
	Set typecolor(6)="/color(0,5)"

	Write /CLR,/C(1,1),@bold,$$pad("  InterSystems IRIS Console  ["_ns_"]",mx)
	Write /C(1,2),$$pad("",mx),@normal
	Write /C(1,my-3),@bold,$$pad("",mx),@normal
	Quit
collect(nslist,data,max)
	Kill data,name,status
	Do ##class(Ens.Director).GetProductionStatus(.name,.status)
	Set data = $LB($ZDT($H,2),name,$CASE(status,$$$eProductionStateRunning:"running",
												$$$eProductionStateStopped:"stopped",
												$$$eProductionStateSuspended:"suspended",
												$$$eProductionStateTroubled:"toubled",
												:"unknown"))
	For i=1:1:$l(nslist,",") {
		Set ns=$P(nslist,",",i)
		Do collectns(ns,.data,max)
	}
	// Now sort
	Set ts="" For {
		Set ts=$O(data(0,ts),-1) Quit:ts=""
		Set ix="" For {
			Set ix=$O(data(0,ts,ix)) Quit:ix=""
			Set data($I(data(0)))=data(0,ts,ix)
		}
	}
	Quit
collectns(ns,data,max)
	Set thisns=$namespace,$ZT="nserr",SQLCODE=0
	Do:thisns'=ns $ZU(5,ns)
	&sql(DECLARE c1 CURSOR FOR
			SELECT TOP :max %ID, TimeLogged, Type, ConfigName, Text, Job
					FROM ENS_UTIL.LOG
					ORDER BY %ID DESC)
	&sql(OPEN c1)
	While (SQLCODE=0) {
		kill id,time,type,name,text
		&sql(FETCH c1 INTO :id, :time, :type, :name, :text, :job) Quit:SQLCODE'=0
		
		Set data(0,time,$I(data(time)))=$LB(time,ns,id,type,name,text,job)
	}
	If SQLCODE'=0,SQLCODE'=100 do reporterr(SQLCODE_": "_%msg)
	&sql(CLOSE c1)
restorens
	Do:$namespace'=thisns $ZU(5,thisns)
	Quit
nserr
	Do reporterr($ZE)
	Goto restorens
purge(nslist)
	For i=1:1:$l(nslist,",") {
		Set ns=$P(nslist,",",i)
		Job ##class(Ens.Util.Tasks.Purge).PurgeAll():(ns)
	}
	Quit
reporterr(err,temp)
	Do report("ERROR: "_err,1,5,.temp)
	Quit
report(msg,flash=0,timeout=5,temp)
	Write /C(1,my-2)
	Write:flash @blink
	Write $$center(msg,mx)
	Write:flash @normal
	If timeout>0 Do prompt(timeout,.temp,1) Write /C(1,my-2),$$pad("",mx)
	Quit
render(data,lines,last)
	Set info=$LG(data,1)
	Write /C(mx-$L(info),1),@bold,info,@normal
	Set info=$LG(data,2)
	Set:info="" info=$G(^Ens.Configuration("csp","LastProduction"))
	Set info=info_" ["_$LG(data,3)_"]"
	Write /C(4,2),@bold,$$pad(info,mx-4)," ",@normal
	Set used=0
	For i=1:1:lines {
		Quit:used'<lines

		Write /C(1,3+used)

		If '$D(data(i)) Write $$pad("",mx) Quit

		// Render one row
		Set type = $LG(data(i),4)
		Write @$S(type=4&&(i#2):normal,1:typecolor(type))

		// 	Timestamp, Type, ConfigName (Job), ID
		Write $$pad($LG(data(i),1),23)," "
		Write $$pad(##class(Ens.Util.Log).TypeLogicalToDisplay(type),8)," "  // 33
		Write $$pad($LG(data(i),7),9)_" "
		Write $$pad($LG(data(i),5),mx-46)

		Write /C(mx-7,3+used),$J($LG(data(i),3),8)

		// Render the text
		Set used=used+1,text=$TR($LG(data(i),6),$C(13,10,9),"   "),l=$L(text)
		Set:l>((lines-used)*mx) l=(lines-used)*mx
		Write /C(1,3+used),$E(text,1,l)
		Set c=l\mx+(l#mx>0)
		Set used=used+c
		If l#mx>0 Write $$pad("",mx-(l#mx))		
	}
	Write @normal
	Quit
pad(s,w)
	Quit $S($L(s)>w:$E(s,1,w),1:s_$J("",w-$L(s)))
center(s,w)
	Quit:$L(s)>w $E(s,1,w)
	Set r=w-$L(s)
	Set s=s_$J("",r\2),r=r-(r\2)
	Set s=$J("",r)_s
	Quit s
prompt(to,temp,max)
	Set xpos=5,ypos=my-3
	Write /C(xpos-2,ypos),@bold,"? ",$J("",mx-xpos)
	Set input="",max=+$G(max)
	For {
		Write /C(xpos,ypos),temp
		Read *c:to
		Quit:'$T

		If (c=13)!(c=10) {
			Set input = temp,temp=""
			Quit
		}

		If (c=8)!(c=127) {
			Set temp = $E(temp,1,$L(temp)-1)
			Write *8," ",*8
			Continue
		}

		If (c=21) {
			Write /C(xpos,ypos),$J("",mx-xpos)
			Set temp=""
			Continue
		}

		Set temp=temp_$C(c)

		If max,$L(temp)'<max Quit
	}
	Write @normal
	Quit input
termdimensions
	If $I'?1"CON:".E {
		Write *-1 Read x:0 Write $C(27,91)_"6n" Read x:3 Set loc=$Key
		If $E(loc,1,2)=$C(27,91),loc?2E1.n1";"1.n1"R" {
			Write $C(27,91)_"999;999H"_$C(27,91)_"6n" Read x Set pos=$Key
			Write $E(loc,1,$L(loc)-1)_"H" Hang 0
			If $E(pos,1,2)=$C(27,91),pos?2E1.n1";"1.n1"R" {
				Set x=$E(pos,3,$L(pos)-1),my=1+x,mx=$P(x,";",2)
			}
		}
	} Else {
		Do CURRENT^%IS
		Set mx=RM
		Set my=SL
	}
	Quit
}

/// Internal method looking for case insensitive SuperSession parameter
ClassMethod superSessionInURLParams(ByRef pSuperSession As %String = "") As %Boolean [ Internal ]
{
	#dim tKey As %String = ""
	Try {
		Set tKey=$O(%request.Data(tKey))
		While (tKey'="") {
			If $ZCVT(tKey,"L")=$$$EnsHTTPHeaderSuperSessionLC {
				Set pSuperSession = $G(%request.Data(tKey,1))
				Return 1
			}
			Set tKey=$O(%request.Data(tKey))
		}
	} Catch {}
	Return 0
}

/// Internal method. See SetProductionShutdownGroup.
ClassMethod GetProductionShutdownGroup(ByRef pProductionName As %String, Output pSC As %Status = {$$$OK}, pValidateProductionName As %Boolean = 1) As %Integer [ Internal ]
{
	If $get(pProductionName)="" {
		// Return first defined production
		#dim tFirstDefinedProduction = $Order($$$EnsProdShutdownGroup(""))
		If tFirstDefinedProduction = "" {
			Return $$$ensDefaultShutdownGroup
		} Else {
			Set pProductionName = tFirstDefinedProduction
			Return ..GetProductionShutdownGroup(tFirstDefinedProduction,,0)
		}
	}

	// Validate the production No need to lock.
	If pValidateProductionName {
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,0,.pSC)
		If '$IsObject(tProduction)||$$$ISERR(pSC) {
			Set pSC=$$$EnsError($$$EnsErrProductionNotRegistered,pProductionName,$$$StatusDisplayString(pSC))
			Return 0
		}
	}	

	#Dim tShutdownGroup = $Get($$$EnsProdShutdownGroup(pProductionName),$$$ensDefaultShutdownGroup)
	If tShutdownGroup=(+tShutdownGroup) Return tShutdownGroup
	Return $$$ensDefaultShutdownGroup
}

/// Note: Setting ShutdownGroup to a value other than default or empty value can lead to extending the time it takes to
/// stop the instance in a controlled manner. This can have implications for time sensitive failovers <br><br>
/// Productions are requested to be shutdown in parallel when the system is stopped in a controlled manner. <br>
/// It is possible to control the shutdown order in separate parallel groups by entering an integer. <br>
/// Running productions will be shutdown in parallel grouped by this integer.<br>
/// The default if not specified will be taken as $$$ensDefaultShutdownGroup (2). <br>
ClassMethod SetProductionShutdownGroup(pProductionName As %String, pShutdownGroup As %Integer = {$$$ensDefaultShutdownGroup}) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	// Validate the production. No need to lock.
	Set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,0,.tSC)
	If '$IsObject(tProduction)||$$$ISERR(tSC) {
		Set tSC=$$$EnsError($$$EnsErrProductionNotRegistered,pProductionName,$$$StatusDisplayString(tSC))
		Quit tSC
	}
	#; Only set if numeric and remove if default
	If (+pShutdownGroup = pShutdownGroup) {
		If pShutdownGroup = $$$ensDefaultShutdownGroup {
			Do ..RemoveProductionShutdownGroup(pProductionName)
		} Else {
			Set $$$EnsProdShutdownGroup(pProductionName) = pShutdownGroup
		}
		#; If the production is the running production then set/reset.
		#; Use locking and mirror aware method to find if pProductionName running on this instance
		#dim tRunningProductionName, tProductionState
		Set tSC=..GetProductionStatus(.tRunningProductionName,.tProductionState)
		If $$$ISOK(tSC) && (tProductionState=$$$eProductionStateRunning) && (tRunningProductionName=pProductionName) {
			Set ^%SYS("Ensemble","RunningNamespace",$NAMESPACE,"SystemShutdownGroup")= pShutdownGroup
		}
	}
	Quit tSC
}

/// Internal method. See SetProductionShutdownGroup.
ClassMethod RemoveProductionShutdownGroup(pProductionName As %String) [ Internal ]
{
	Kill $$$EnsProdShutdownGroup(pProductionName)
}

/// Internal method. See SetProductionShutdownGroup.
ClassMethod GetRunningProductionShutdownGroup(Output pProductionName As %String) As %Integer [ Internal ]
{
	Set pProductionName= $GET($$$EnsConfigurationGbl("csp","LastProduction"))
	// Pass by reference in case pProductioName is ""
	Quit ..GetProductionShutdownGroup(.pProductionName,,0)
}

/// <p>Temporarily stop an enabled ConfigItem in a Production without changing the item's Enabled setting in the production.
/// The production definition class is unchanged.
/// The temporary stop is not maintained through production restarts  or mirror failover.
/// This is only used if the Production is running.
/// This does not apply to business processes with a pool size of 0 (using the general actor pool).</p>
/// <p>The pConfigItemName argument gives the name of the config item to be temporarily stopped.
/// The mechanism for indicating the config item ought to be temporarily stopped makes use of the
/// mechanism used for stopping a scheduled stopped item.</p>
/// <p>
/// See <method>ParseConfigItemName</method> for full syntax of the ConfigItem name specification string.</p>
/// 
ClassMethod TempStopConfigItem(pConfigItemName As %String, pStop As %Boolean = 1, pDoUpdate As %Boolean = 1) As %Status
{
	#dim tSC = $$$OK
	#dim tRunningProductionName = ""
	#dim tProductionName = ""
	#dim tState = ""

	Set tSC=..GetProductionStatus(.tRunningProductionName,.tState)
	If $$$ISERR(tSC) Return tSC

	If tState'=$$$eProductionStateRunning {
		$$$LOGINFO($$$Text("No Production is running (")_##class(EnsPortal.Utils).resolveProductionStateName(tState)_")")
		Return tSC
	}

	#dim tProduction, tItemName, tCommentOrClass

	Do ..ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)

	If (tRunningProductionName '= tProductionName) {

		Return $$$ERROR($$$EnsErrGeneral,"Item is not in the current running production.")

	}

	Set tProduction = ##class(Ens.Config.Production).%OpenId(tProductionName,,.tSC)
	If ('$IsObject(tProduction)||$$$ISERR(tSC)) Return $$$ERROR($$$EnsErrProductionNotRegistered,tProductionName,$$$StatusDisplayString(tSC))

	#; Scan list of all matching enabled production items, and select the first we find that's a perfect match
	#dim tFoundItem = ""
	#dim tEnabledItems
	Set tFoundItem=tProduction.findItemByName(tItemName,tCommentOrClass,.tSC,.tEnabledItems)
	If $$$ISERR(tSC) Return tSC

	If ('tFoundItem.Enabled) {
		/// Cannot temporarily stop or start a disabled item
		Return tSC
	}

	#; Cannot override a PoolSize from System Default Settings with 0 so do not need to check SDS value
	If pStop && (tFoundItem.PoolSize = 0) && (tFoundItem.BusinessType() = $$$eHostTypeProcess) {
		/// Cannot issue temp stop to a business process using the general actor pool
		Return $$$ERROR($$$EnsErrGeneral,"Cannot temporarily stop a Business Process that has pool size of 0.")
	}

	If pStop {

		If $$$ConfigRunAsJob(tItemName)	&& $$$ConfigPoolSize(tItemName)	{
			Set $$$ConfigTempStop(tItemName) = 1
		} Else {
			Return $$$ERROR($$$EnsErrGeneral,"Item "_pConfigItemName_" in Production "_tProductionName_" cannot be temporarily stopped as it is not running.")
		}

	} Else {

		Kill $$$ConfigTempStop(tItemName)

	}

	#; Log
	If pStop {
		$$$LOGINFO($$$FormatText($$$Text("Temporarily stopping item '%1' in Production '%2'."),tItemName_$S(""=tCommentOrClass:"",1:"|"_tCommentOrClass),tProductionName))
	} Else {
		$$$LOGINFO($$$FormatText($$$Text("Restarting Temporarily stopped item '%1' in Production '%2'."),tItemName_$S(""=tCommentOrClass:"",1:"|"_tCommentOrClass),tProductionName))
	}

	#; Audit
	Set $Ecode = ""
	#dim tCaller = ""
	If $Stack(-1)>1 {
		Set tCaller = $Stack($Stack(-1)-1,"PLACE") // "caller id"
	}
	Else {
		Set tCaller = "direct call to ##class(Ens.Director).TempStopConfigItem"
	}
	#dim tSC2 = $$$AuditModifyProductionConfig(tProductionName,tItemName,"item "_$S(pStop:"temporary stop",1:"restarted after temporary stop")_" by "_tCaller)
	If $$$ISERR(tSC2) $$$LOGSTATUS(tSC2)

	Quit:pDoUpdate ..UpdateProduction(..GetRunningProductionUpdateTimeout())
	Quit tSC
}

/// <p>This method can be used to restart certain items that are automatically added
/// to a production: Ens.Alarm, Ens.MonitorService and Ens.ScheduleHandler, since by default
/// they are behind the scenes production item and not
/// added to the production class definition. </p>
/// <p>The default is to update the production after stopping the identified job.</p>
/// <p>This means all reasons for an update production are attempted to be addressed.</p>
/// <p>The 4 parameters are: </p>
/// <p>pAutoAddedItem - can be Ens.Alarm, Ens.ScheduleHandler or Ens.MonitorService </p>
/// <p>pUpdateProduction - defaults to 1 (true) </p>
/// <p>pForce - defaults to 0. If true it will force the job to be stopped after the timeout
/// and if the production is to be updated apply force there if needed. </p>
/// <p>pTimeout - defaults to 10. The timeout used to stop the job and also the optional update  
/// production call.</p>
/// 
ClassMethod RestartAutoAddedItem(pAutoAddedItem As %String = "", pUpdateProduction As %Boolean = 1, pForce As %Boolean = 0, pTimeout As %Integer = 10) As %Status
{
	/*	Need to find the Job for the pAutoAddedItem.
		Since the pAutoAddedItem is a BP, current open
		BP instance(s) are recorded as Jobs. Hence need to
		filter by $$$SystemName:$JOB 
	*/
	#dim tSC = $$$OK
	If $ListFind($ListBuild("Ens.Alarm","Ens.MonitorService","Ens.ScheduleHandler"),pAutoAddedItem) {
		#dim tJOBString = $$$OrderHostMonitor(pAutoAddedItem,$$$eMonitorJob,"")
		While (tJOBString'="")&&($Piece(tJOBString,":")'=$$$SystemName) {
			Set tJOBString = $$$OrderHostMonitor(pAutoAddedItem,$$$eMonitorJob,tJOBString)
		}
		If (tJOBString'="") {
			#; select second colon to end in order to support NodeNameInPid
			Set tSC = ##class(Ens.Job).Stop($Piece(tJOBString,":",2,*),pTimeout,pForce)
			If $$$ISOK(tSC) && '$Data($$$EnsHostMonitorRoot($namespace,pAutoAddedItem,$$$eMonitorJob,tJOBString)){
				$$$LOGINFO($$$FormatText($$$Text("Stopped %1 as part of RestartAutoAddedItem request"),pAutoAddedItem))
				If pUpdateProduction && ##class(Ens.Director).ProductionNeedsUpdate(.tReason) {
					If (tReason [ pAutoAddedItem) {
						Set tSC = ##class(Ens.Director).UpdateProduction(pTimeout,pForce)
					}
				}
			} Else {
				$$$LOGWARNING($$$FormatText($$$Text("Failed to stop %1 following RestartAutoAddedItem request"),pAutoAddedItem))
			}
		}
	} Else {
		$$$LOGINFO("Not an accepted auto added item name")
	}
	If $$$ISERR(tSC) $$$LOGERROR($SYSTEM.Status.GetErrorText(tSC))
	Return tSC
}

/// A Worker node is an interoperability namespace where production runtime
/// data is shared with an ECP server.
/// This method is used to identify if the namespace is being served from a
/// sharded cluster namespace not on the data server.
/// Also returns flag if the namespace is any type of ECP client with remote hosting
/// of core Interoperability runtime globals.
/// Trapped error will be returned for informational purposes.
/// Internal subject to change.
ClassMethod IsUnSupportedRemoteWorkerNamespace(Output pSC As %Status = {$$$OK}, Output pIsECPClientNamespace As %Boolean = 0, pVerifyAndUpdate As %Boolean = 0, Output pECPServer As %String = "", Output pClusterDetails As %String) As %Boolean [ Internal ]
{
	/*
		First check if IsECPClientNamespace - if not then cannot be a shard worker node
		Get cluster details - if ClusterNamespace = this namespace then a shard worker node
		To be expanded later to allow support for ECP client/shard worker node.
	*/
	Set tIsUnSupportedRemoteWorkerNamespace = 0

	If ..IsECPClientNamespace(.pECPServer, .pSC, pVerifyAndUpdate) {
		If $$$ISOK(pSC) {
			Set pIsECPClientNamespace = 1
			Do ..GetShardClusterNamespace(.tClusterNamespace, .pClusterDetails)
			If (tClusterNamespace=$NAMESPACE) {
				Set tIsUnSupportedRemoteWorkerNamespace = 1
			}
		}
	}

	Return tIsUnSupportedRemoteWorkerNamespace
}

/// This method checks if the namespace has core Interop Production globals
/// mapped from an ECP server and caches the information in a global
/// $$$EnsECPCacheGlobal("ApplicationServers",tThisNodeName)=ECP Server 
/// This global will only be defined if this is an ECP client namespace.
/// Internal subject to change.
ClassMethod IsECPClientNamespace(Output pECPServer As %String = "", Output pSC As %Status = {$$$OK}, pVerifyAndUpdate As %Boolean = 0) As %Boolean [ Internal ]
{
	Try {

		Set tIsECP = 0, tLocked = 0

		#; Check what permissions required
		#; Not using ECP
		If '$system.ECP.NumClientConnections() Quit

		#; This cannot be empty string. If so then SUBSCRIPT error thrown
		Set tThisNodeName = ##class(%SYS.System).GetNodeName()

		#; Already persisted fact this namespace is ECP served.
		#; ECP Server name stored for future use
		#; Needs cleaning up if change namespace mapping - hence pVerifyAndUpdate option
		If $Data($$$EnsECPApplicationServers(tThisNodeName),pECPServer)#2 {
			Set:pECPServer'=$$$EnsECPLocalCoreIdentifier tIsECP = 1
			If 'pVerifyAndUpdate Quit
		}

		#; Will throw <PROTECT> error if read only
		Lock +$$$EnsECPApplicationServers(tThisNodeName):$$$LockTimeout
		If $Test Set tLocked = 1

		Set tHasMappedGlobal = 0

		For tCoreGlobal = $$$EnsECPCoreRuntimeGlobals {
			#; Check what permissions required
			Set tDestDir = ##class(%SYS.Namespace).GetGlobalDest($namespace, tCoreGlobal)
			If $Piece(tDestDir,"^") '= "" {
				Set:tLocked $$$EnsECPApplicationServers(tThisNodeName) = $Piece(tDestDir,"^")
				Set tIsECP = 1, tHasMappedGlobal = 1
				Quit
			}
		}
		#; This could also be due to pVerifyAndUpdate being true
		If 'tHasMappedGlobal {
			Set:tLocked $$$EnsECPApplicationServers(tThisNodeName) = $$$EnsECPLocalCoreIdentifier
			Set tIsECP = 0
		}

	} Catch ex {

		If ex.Name = "<SUBSCRIPT>" {
			Set pSC = $$$EnsError($$$EnsErrServerNodeNameBlank)
		} ElseIf ex.Name '= "<PROTECT>" {
			#; Protect means read only DB - do not reports
			Set pSC =ex.AsStatus()
		}

	}

	Lock:tLocked -$$$EnsECPApplicationServers(tThisNodeName)

	Return tIsECP
}

/// Obtain information on whether this node is part of a cluster
/// and if so whether the director node or a worker node.
/// Internal subject to change.
ClassMethod GetShardClusterNamespace(Output pClusterNamespace As %String, Output pClusterDetails As %String) [ Internal ]
{
	Kill pClusterDetails
	#; need to check permissions required
	Set pClusterNamespace = $system.Cluster.ClusterNamespace()
	If pClusterNamespace '= "" {
		Set tSC = $system.Cluster.GetMetadata(.pClusterDetails)
		If $$$ISERR(tSC) Kill pClusterDetails
	}
}

}
