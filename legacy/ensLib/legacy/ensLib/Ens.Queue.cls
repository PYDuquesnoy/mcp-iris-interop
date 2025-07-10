/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Queue [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod Create(pQueueName As %String = {$job}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Lock +$$$EnsQueue(pQueueName)
		If $data($$$EnsQueue(pQueueName))=0 {
			Set $$$EnsQueue(pQueueName,0,"count")=0
			Set $$$EnsQueue(pQueueName,0,"next")=0
			Set $$$EnsQueue(pQueueName,0,"time")=$$$timeUTC
		}
		If pQueueName'?1.N {
			Set tEventCreated = $system.Event.Create(..EventName(pQueueName))
			$$$sysTRACE("event '"_..EventName(pQueueName)_"' " _ $select(tEventCreated: "created", 1: "already exists"))
		}
		Set $$$EnsQueue(pQueueName,0,"job",$$$SystemName,$Job)=""
		Lock -$$$EnsQueue(pQueueName)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Lock -$$$EnsQueue(pQueueName)
	Goto Exit
}

ClassMethod Delete(pQueueName As %String, pJob As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Lock +$$$EnsQueue(pQueueName)
		If $data($$$EnsQueue(pQueueName))'=0 {
			if pJob="*" {
				Kill $$$EnsQueue(pQueueName,0,"job")
			} else {
				Kill $$$EnsQueue(pQueueName,0,"job",$$$SystemName,pJob)
			}
			If ('$data($$$EnsQueue(pQueueName,0,"job")))&&($$$EnsQueue(pQueueName,0,"count")=0) {
				Kill $$$EnsQueue(pQueueName)
				If pQueueName'?1.N Do ..deleteEvent(..EventName(pQueueName))
			}
		}
		Lock -$$$EnsQueue(pQueueName)
		Lock +$$$EnsQueue:0 Else  Quit
		If $data($$$EnsQueue)=1 $$$KillRootNode($$$EnsQueue)
		Lock -$$$EnsQueue
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Lock -$$$EnsQueue(pQueueName)
	Goto Exit
}

ClassMethod deleteEvent(pEventName As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Do $system.Event.Delete(pEventName)
		$$$sysTRACE("event '"_pEventName_"' deleted")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<UNDEFINED>" Set tSC=$$$OK Goto Exit
	Set tSC=$$$EnsSystemError
	Goto Exit
}

/// pRemoveJobsInProcQueues allows deleting non empty queues invoked by this service InProc as well
/// - they will have this job as second : piece of the queue name.
ClassMethod DeleteAllQueuesForJob(pJob As %String = {$Job}, pRemoveJobsInProcQueues As %Boolean = 0) As %Status
{
	#dim tSC=$$$OK
	#dim tName=$o($$$EnsQueue(""))
	While (tName'="") {
		If pRemoveJobsInProcQueues && ($Piece(tName,":",2)=pJob) {
			Set tSC=..Delete(tName,"*")
		} Else {
			Set tSC=..Delete(tName,pJob)
		}
		Quit:$$$ISERR(tSC)
		Set tName=$o($$$EnsQueue(tName))
	}
	Quit tSC
}

ClassMethod Exists(pQueueName As %String = {$job}) As %Boolean
{
	Quit ''$data($$$EnsQueue(pQueueName))
}

ClassMethod ExistsInQueue(pMsg As Ens.MessageHeader = "") As %Boolean
{
	Set tId=pMsg.%Id()
	Set tQueueName=pMsg.TargetQueueName If tQueueName="" Quit 0
	Set tPriority=pMsg.Priority
	Set tFound=0
	Set tIndex="" For  {
		Set tIndex=$o($$$EnsQueue(tQueueName,tPriority,tIndex)) Quit:tIndex=""
		If $$$EnsQueue(tQueueName,tPriority,tIndex)=tId Set tFound=1 Quit
	}
	Quit tFound
}

ClassMethod PutBackToQueue(pMsg As Ens.MessageHeader) As %Status
{
	Quit ..EnQueue(pMsg,1)
}

ClassMethod EnQueue(pMsg As Ens.MessageHeader, pReverseOrder As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,tLocked=0
	Do {
		Set pMsg.Status=$$$eMessageStatusQueued
		Set pMsg.TimeProcessed=$$$timeUTC
		Set tSC=pMsg.%Save()
		If $TLevel>0 && 'pReverseOrder Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found; committing before EnQueue("_pMsg.%Id()_")")
		If $$$ISERR(tSC) $$$LOGSTATUS(tSC) Quit

		Set tQueueName=pMsg.TargetQueueName
		If tQueueName="" Set tSC=$$$EnsError($$$EnsErrGeneral,"Can not EnQueue a message without queue name, Msg#"_pMsg.%Id()_".") Quit
		Lock +$$$EnsQueue(tQueueName) Set tLocked=1
		$$$sysTRACE("enqueueing #"_pMsg.%Id()_" with body Class '"_pMsg.MessageBodyClassName_"' and body Id '"_pMsg.MessageBodyId_"' to "_tQueueName_" at priority "_pMsg.Priority_$S(""=pMsg.ReturnQueueName:"",1:", RetQ="_pMsg.ReturnQueueName))
		If $data($$$EnsQueue(tQueueName))=0&&$$$queueIsPrivateQueue(tQueueName) {
			$$$sysTRACE("Private queue does not exist, message '"_pMsg.%Id()_"' discarded")
			Do pMsg.SetStatus($$$eMessageStatusDiscarded)
			quit
		}
		Set tEventName = ..EventName(tQueueName)
		#; Call Create() if the current PID isn't registered OR the event isn't defined
		#; The event check is needed after a crash where we may have PID collisions
		#; The numeric match ensures we only pass strings into $system.Event.Defined() - numerics cause errors
		If ($data($$$EnsQueue(tQueueName,0,"job",$$$SystemName,$Job))=0) || ((tQueueName'?1.N) && '$system.Event.Defined(tEventName)) {
			Set tSC=..Create(tQueueName) If $$$ISERR(tSC) Quit
		}
		If pReverseOrder {
			Set tIndex=$o($$$EnsQueue(tQueueName,pMsg.Priority,""))
			If tIndex="" {
				Set tIndex=$$$EnsQueue(tQueueName,0,"next")
			} Else {
				Set tIndex=tIndex-1
			}
		} Else {
			Set tIndex=$increment($$$EnsQueue(tQueueName,0,"next"))
		}
		Set $$$EnsQueue(tQueueName,pMsg.Priority,tIndex)=pMsg.%Id()
		Set $$$EnsQueue(tQueueName,0,"count")=$$$EnsQueue(tQueueName,0,"count")+1
		Try {
			Do $system.Event.Signal(tEventName)
			Do ..signalQueueEventDevices(tQueueName)
		}
		Catch ex {
			$$$LOGWARNING("Failed to signal event '" _ tEventName _ "' for Header '" _ pMsg.%Id() _ "' on queue '" _ tQueueName _ "' due to exception: " _ $system.Status.GetErrorText(ex.AsStatus()))
		}
	} while (0)
Exit
	If $g(tLocked) Lock -$$$EnsQueue(tQueueName)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	If $g(tQueueName)'="" Lock -$$$EnsQueue(tQueueName)
	Goto Exit
}

ClassMethod DeQueue(pQueueName As %String = {$job}, ByRef pMsg As Ens.MessageHeader, pTimeout As %Numeric = -1, Output pIsTimedOut As %Boolean, pHonorQuiescent As %Boolean = 0, pMinPriority As %Integer = {$$$eMessagePriorityAsync}) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, tIsSuccess=0, tId="", pMsg="", pIsTimedOut=0
	Do {
		$$$ASSERT(pQueueName'="")
		$$$catTRACE("queue","dequeueing from "_pQueueName_" with timeout="_pTimeout)
		Set tShouldBeQuiescent = pHonorQuiescent&&##class(Ens.Job).ShouldBeQuiescent()
		Set tMinPriority=$S(tShouldBeQuiescent:$$$eMessagePrioritySync, 1:pMinPriority)
		If $data($$$EnsQueue(pQueueName,0,"job",$$$SystemName,$Job))=0 Set tSC=..Create(pQueueName) If $$$ISERR(tSC) Quit

		Lock +$$$EnsQueue(pQueueName)
		Set tPriority=$o($$$EnsQueue(pQueueName,0))
		If tPriority'="",tPriority<=tMinPriority {
			Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,""))
			If tIndex'="" {
				Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
				If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
				Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
				Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
				Set tIsSuccess=1
			}
		}
		Lock -$$$EnsQueue(pQueueName)
		Quit:tIsSuccess

		If tShouldBeQuiescent {
			Do ##class(Ens.Job).SetStatus($$$eJobStatusQuiescent,pQueueName)
			Do $system.Event.Create("^Ens.Event.JobRequester")
			Do $system.Event.Signal("^Ens.Event.JobRequester")
		} Else {
			Do ##class(Ens.Job).SetStatus($$$eJobStatusDeQueuing,pQueueName)
		}
		While 1 {
			If pTimeout>0 {
				Set:pTimeout\1'=pTimeout pTimeout=pTimeout\1+1
				Set tWakeTime=pTimeout+$ZH
			}
			$$$catTRACE("queue","begin wait: "_pTimeout)
			If '$system.Event.Wait(..EventName(pQueueName),pTimeout) {
				$$$catTRACE("queue","dequeuing timed out")
				Do ##class(Ens.Job).SetStatus($S($G($$$EnsJobLocal("TCPIn.OutsideJob")):$$$eJobStatusVisiting,1:$$$eJobStatusRunning))
				Set pIsTimedOut=1
				Quit
			} Else {
				$$$catTRACE("queue","dequeuing received an event")
			}
			Lock +$$$EnsQueue(pQueueName)
			Set tPriority=$o($$$EnsQueue(pQueueName,0))
			If tPriority'="",tPriority'>tMinPriority {
				Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,""))
				If tIndex'="" {
					Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
					If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
					Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
					Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
					Set tIsSuccess=1
				}
			}
			Lock -$$$EnsQueue(pQueueName)
			Quit:tIsSuccess

			$$$catTRACE("queue","dequeue failed to find a message on "_pQueueName_" at or above priority "_tMinPriority)
			Quit:##class(Ens.Job).ShouldBeQuiescent() 
			Quit:##class(Ens.Job).ShouldTerminate()
			If pTimeout>0 {
				Set tNow=$ZH  If tNow>tWakeTime Set pIsTimedOut=1  Quit
				Set pTimeout=tWakeTime-tNow
			}
			#;Check to see if we were here as a result of being quiescent earlier. Need to exit to reset timeout and priority
			If tShouldBeQuiescent Quit
		} ; while 1
	} while 0
	If tIsSuccess {
		Do ##class(Ens.Job).SetStatus($S($G($$$EnsJobLocal("TCPIn.OutsideJob")):$$$eJobStatusVisiting,1:$$$eJobStatusRunning))
		Set pMsg=##Class(Ens.MessageHeader).%OpenId(tId,,.tSC1)
		If pMsg=$$$NULLOREF {
			$$$LOGERROR("MessageHeader #"_tId_" can not be loaded: "_$$$StatusDisplayString(tSC1))
		} Else { 
			$$$sysTRACE("dequeuing from "_pQueueName_" found message #"_tId_" with body Class '"_pMsg.MessageBodyClassName_"' and body Id '"_pMsg.MessageBodyId_"' and SessionId '"_pMsg.SessionId_"'")
			Try {
				Set tStatsConfig=$$$JobConfigName
				If tStatsConfig="" Set tStatsConfig=pQueueName
				If ##class(Ens.Util.Statistics).StatsActive(tStatsConfig) {
					#dim tTimeDelta = ##class(%SYSTEM.SQL.Functions).DATEDIFF("ms",pMsg.TimeProcessed,$$$timeUTC)/1000
					Do ##class(Ens.Util.Statistics).SetStatsQueueDuration(tStatsConfig,tTimeDelta)
				}
			} Catch {}
		}
	}
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Lock -$$$EnsQueue(pQueueName)
	Goto Exit
}

ClassMethod EnQueueId(pId As %String, pTarget As %String, pPriority As %Integer = {$$$eMessagePriorityAsync}, pReverseOrder As %Boolean = 0) As %Status [ Internal ]
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		If pTarget="" Set tSC=$$$EnsError($$$EnsErrGeneral,"Can not EnQueue a message without queue name, Msg#"_pId_".") Quit
		#; Note: EnsQueueId is called from Ens.MessageHeader:%OnAfterSave() inside a transaction
		#; EnQueueId will not cause the transaction to fail because the status return is not checked. Most other causes of %Save() failure are likely to occur before reaching %OnAfterSave().
		Lock +$$$EnsQueue(pTarget)
		$$$sysTRACE("enqueueing #"_pId_" to "_pTarget_" at priority "_pPriority)
		If $data($$$EnsQueue(pTarget))=0&&$$$queueIsPrivateQueue(pTarget) {
			$$$sysTRACE("Private queue does not exist, message '"_pId_"' not sent to "_pTarget)
			Quit
		}
		If $data($$$EnsQueue(pTarget,0,"job",$$$SystemName,$Job))=0 {
			Set tSC=..Create(pTarget) If $$$ISERR(tSC) Quit
		}
		If pReverseOrder {
			Set tIndex=$O($$$EnsQueue(pTarget,pPriority,""))
			If tIndex="" {
				Set tIndex=$$$EnsQueue(pTarget,0,"next")
			} Else {
				Set tIndex=tIndex-1
			}
		} Else {
			Set tIndex=$increment($$$EnsQueue(pTarget,0,"next"))
		}
		Set $$$EnsQueue(pTarget,pPriority,tIndex)=pId
		Set $$$EnsQueue(pTarget,0,"count")=$$$EnsQueue(pTarget,0,"count")+1
		Do $system.Event.Signal(..EventName(pTarget))
		Do ..signalQueueEventDevices(pTarget)
		Lock -$$$EnsQueue(pTarget)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	If $g(pTarget)'="" Lock -$$$EnsQueue(pTarget)
	Goto Exit
}

ClassMethod DeQueueId(pQueueName As %String = {$job}, Output pId As %String, pTimeout As %Numeric = -1, Output pIsTimedOut As %Boolean, pHonorQuiescent As %Boolean = 0, pMinPriority As %Integer = {$$$eMessagePriorityAsync}) As %Status [ Internal ]
{
	Set $ZT="Trap", tSC=$$$OK, tIsSuccess=0, tId="", pId="", pIsTimedOut=0
	Do {
		$$$ASSERT(pQueueName'="")
		$$$catTRACE("queue","dequeueing from "_pQueueName_" with timeout="_pTimeout)
		Set tShouldBeQuiescent = pHonorQuiescent&&##class(Ens.Job).ShouldBeQuiescent()
		Set tMinPriority=$S(tShouldBeQuiescent:$$$eMessagePrioritySync, 1:pMinPriority)
		If $data($$$EnsQueue(pQueueName,0,"job",$$$SystemName,$Job))=0 Set tSC=..Create(pQueueName) If $$$ISERR(tSC) Quit

		Lock +$$$EnsQueue(pQueueName)
		Set tPriority=$o($$$EnsQueue(pQueueName,0))
		If tPriority'="",tPriority<=tMinPriority {
			Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,""))
			If tIndex'="" {
				Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
				If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
				Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
				Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
				Set tIsSuccess=1
			}
		}
		Lock -$$$EnsQueue(pQueueName)
		Quit:tIsSuccess

		If tShouldBeQuiescent {
			Do ##class(Ens.Job).SetStatus($$$eJobStatusQuiescent,pQueueName)
			Do $system.Event.Create("^Ens.Event.JobRequester")
			Do $system.Event.Signal("^Ens.Event.JobRequester")
		} Else {
			Do ##class(Ens.Job).SetStatus($$$eJobStatusDeQueuing,pQueueName)
		}
		While 1 {
			If pTimeout>0 {
				Set:pTimeout\1'=pTimeout pTimeout=pTimeout\1+1
				Set tWakeTime=pTimeout+$ZH
			}
			$$$catTRACE("queue","begin wait: "_pTimeout)
			If '$system.Event.Wait(..EventName(pQueueName),pTimeout) {
				$$$catTRACE("queue","dequeuing timed out")
				Do ##class(Ens.Job).SetStatus($S($G($$$EnsJobLocal("TCPIn.OutsideJob")):$$$eJobStatusVisiting,1:$$$eJobStatusRunning))
				Set pIsTimedOut=1
				Quit
			} Else {
				$$$catTRACE("queue","dequeuing received an event")
			}
			Lock +$$$EnsQueue(pQueueName)
			Set tPriority=$o($$$EnsQueue(pQueueName,0))
			If tPriority'="",tPriority'>tMinPriority {
				Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,""))
				If tIndex'="" {
					Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
					If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
					Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
					Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
					Set tIsSuccess=1
				}
			}
			Lock -$$$EnsQueue(pQueueName)
			Quit:tIsSuccess

			$$$catTRACE("queue","dequeue failed to find a message on "_pQueueName_" at or above priority "_tMinPriority)
			Quit:##class(Ens.Job).ShouldBeQuiescent() 
			Quit:##class(Ens.Job).ShouldTerminate()
			If pTimeout>0 {
				Set tNow=$ZH  If tNow>tWakeTime Set pIsTimedOut=1  Quit
				Set pTimeout=tWakeTime-tNow
			}
			#;Check to see if we were here as a result of being quiescent earlier. Need to exit to reset timeout and priority
			If tShouldBeQuiescent Quit
		} ; while 1
	} While 0
	If tIsSuccess {
		Do ##class(Ens.Job).SetStatus($S($G($$$EnsJobLocal("TCPIn.OutsideJob")):$$$eJobStatusVisiting,1:$$$eJobStatusRunning))
		Set pId=tId
		$$$sysTRACE("dequeuing from "_pQueueName_" found message #"_tId)
	}
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Lock -$$$EnsQueue(pQueueName)
	Goto Exit
}

ClassMethod AbortQueue(pQueueName As %String = "") As %Status
{
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_Queues:WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	if pQueueName="" Quit $$$ERROR($$$EnsErrGeneral,"Invalid QueueName parameter")
	Set tQRef=$S($D($$$EnsQueue):$name($$$EnsQueue), 1:$name($$$EnsSuspended($$$SystemName,"Ens.Queue")))
	if $data(@tQRef@(pQueueName))=0 Quit $$$ERROR($$$EnsErrGeneral,"Queue '"_pQueueName_"' does not exist")
	set tSC=$$$OK
	lock +^Ens.Queue(pQueueName)
	set tPriority=0 for  {
		set tPriority=$o(@tQRef@(pQueueName,tPriority)) quit:tPriority=""
		set tIndex="" for  {
			set tIndex=$o(@tQRef@(pQueueName,tPriority,tIndex)) quit:tIndex=""
			set tSC1=..AbortItem(pQueueName,tPriority,tIndex)
			if $$$ISERR(tSC1) set tSC=$$$ADDSC(tSC,tSC1)
		}
	}
	lock -^Ens.Queue(pQueueName)
	quit tSC
}

ClassMethod AbortItem(pQueueName As %String = "", pPriority As %Integer = 0, pIndex As %Integer = 0) As %Status
{
	Set tLocked=0
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_Queues:WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	If pQueueName="" Quit $$$ERROR($$$EnsErrGeneral,"Invalid QueueName parameter")
	If pPriority=0 Quit $$$ERROR($$$EnsErrGeneral,"Invalid Priority parameter")
	Set tQRef=$S($D($$$EnsQueue):$name($$$EnsQueue), 1:$name($$$EnsSuspended($$$SystemName,"Ens.Queue")))
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Lock +@tQRef@(pQueueName)
		Set tLocked = 1
		If $data(@tQRef@(pQueueName,pPriority,pIndex))=0 Set tSC=$$$ERROR($$$EnsErrGeneral,"QueueItem does not exist - "_pQueueName_":"_pPriority_":"_pIndex)  Quit
		Set tId=@tQRef@(pQueueName,pPriority,pIndex)
		Kill @tQRef@(pQueueName,pPriority,pIndex)
		Set @tQRef@(pQueueName,0,"count")=@tQRef@(pQueueName,0,"count")-1
		Set tMsg=##Class(Ens.MessageHeader).%OpenId(tId,,.tSC)
		If tMsg=$$$NULLOREF {
			Set:$$$ISOK(tSC) tSC=$$$EnsError($$$EnsErrGeneral,"Queued message "_tId_" could not be opened")
			Set:$$$StatusEquals(tSC,$$$LoadObjectNotFound) tSC=$$$OK
			Quit
		}
		Do tMsg.SetStatus($$$eMessageStatusAborted)
		If tMsg.ReturnQueueName'="" && (tQRef=$name($$$EnsQueue)) {
			Set tSC = tMsg.NewErrorResponse(.tResponseHeader,$$$ERROR($$$EnsErrGeneral,"Message '"_tId_"' aborted.")) Quit:$$$ISERR(tSC)
			Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
		}		
	} While 0
Exit
	If tLocked Lock -@tQRef@(pQueueName)
	Quit tSC
Trap
	Set $ZT=""
	Set tSC=$$$EnsSystemError
	Goto Exit
}

/// This method signals all queues - once per each job registered with that queue. </br>
/// If <parameter>pJob</parameter> is specified then only those queues to which pJob
/// is registered will be signalled - once per each  job registered with that queue. <br>
/// Queues in <parameter>pSignalledQueues</parameter> will be skipped.
/// Any queue that is signalled will be recorded as part of the output <parameter>pSignalledQueues</parameter>
ClassMethod SignalAllJobs(pJob = "", Output pSignalledQueues As %String) As %Status
{
	#;This needs to only be run by one job at a time and not during Start()

	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tName="" For { Set tName=$o($$$EnsQueue(tName)) Quit:tName=""
			#; Skip the queues that have been signalled
			If $Data(pSignalledQueues(tName)) Continue

			/*	Do not signal self queue.
				Find all queues or limit to queues that have pJob
			*/
			If (tName'=$Job)&&((pJob="")||$Data($$$EnsQueue(tName,0,"job",$$$SystemName,pJob))) Merge tCachedName(tName)=$$$EnsQueue(tName,0,"job",$$$SystemName)
		}
		Set tName=$o(tCachedName("")) While tName'="" {
			Set tJob=$o(tCachedName(tName,"")) While tJob'="" {
				If tName'?1.N Do $system.Event.Create(..EventName(tName))
				try {
					Do $system.Event.Signal(..EventName(tName))
					Do ..signalQueueEventDevices(tName)
				} catch {
					Set tSC2=$$$EnsSystemError
				}
				Set tJob=$o(tCachedName(tName,tJob))
			}
			Set tName=$o(tCachedName(tName))
		}
	} while (0)
Exit
	#; Save the queues signalled during this method call 
	Merge pSignalledQueues = tCachedName
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod SetEventDevice(pQueueName, pDevice = "") As %Status
{
	If pDevice="" Quit $$$OK
	If $data($$$EnsQueue(pQueueName,0,"job",$$$SystemName,$Job))=0 {
		Set tSC=..Create(pQueueName) If $$$ISERR(tSC) Quit
	}
	If '$Data($$$EnsQueue(pQueueName,0,"event-device",pDevice))#2 Set $$$EnsQueue(pQueueName,0,"event-device",pDevice)=""
	Quit $$$OK
}

ClassMethod ClearEventDevice(pQueueName, pOldDevice) As %Status
{
	If pOldDevice'="" && $data($$$EnsQueue(pQueueName,0,"job",$$$SystemName,$Job)) {
		Kill $$$EnsQueue(pQueueName,0,"event-device",pOldDevice)
	}
	Quit $$$OK
}

ClassMethod GetJobList(pJobList)
{
	Set tName="" For  Set tName=$o($$$EnsQueue(tName)) Quit:tName=""  Do
	. Set tJob="" For  Set tJob=$o($$$EnsQueue(tName,0,"job",$$$SystemName,tJob)) Quit:tJob=""  Do
	. . Set pJobList(tJob)=""
	Quit
}

ClassMethod EventName(pQueueName As %String) As %String
{
	If pQueueName=$Job Quit ""
	If pQueueName?1.N Quit pQueueName
	Quit $name(^Ens.Event(pQueueName))
}

/// List the known queues and their current counters
Query Enumerate() As %Query(ROWSPEC = "Name:%String,Count:%Integer,Created:%String") [ SqlProc ]
{
}

ClassMethod EnumerateExecute(ByRef qHandle As %Binary) As %Status
{
	Set qHandle=""
	Quit $$$OK
}

ClassMethod EnumerateClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

ClassMethod EnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 Set $ZT="Trap",tSC=$$$OK
 do {
	Set Row="",AtEnd=0
	Set tQRef=$S($D($$$EnsQueue):$name($$$EnsQueue), 1:$name($$$EnsSuspended($$$SystemName,"Ens.Queue")))
	For  Set qHandle=$Order(@tQRef@(qHandle)) Quit:qHandle=""  Quit:qHandle'?1"SystemSignal:"1.N
	If qHandle="" Set AtEnd=1 Quit
	Set Row=$ListBuild(qHandle,$g(@tQRef@(qHandle,0,"count")),$$$timeUTCtoLocal($g(@tQRef@(qHandle,0,"time"))))
 } while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// PriorKey is a concatenated string that consists of the Priority, "|", and the Index.
Query EnumerateItem(QueueName As %String, PriorKey As %String = "") As %Query(ROWSPEC = "Priority:%Integer,Index:%Integer,MessageId:%String") [ SqlProc ]
{
}

ClassMethod EnumerateItemExecute(ByRef qHandle As %Binary, pQueueName As %String, pPriorKey As %String = "") As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		If pPriorKey '= "" { 
			Set tPriority = $P(pPriorKey, "|"), tIndex = $P(pPriorKey, "|", 2)
			If $D($$$EnsQueue) {
				Set qHandle=$name($$$EnsQueue(pQueueName,tPriority,tIndex)), qHandle("lev")=0
			} Else {
				Set qHandle=$name($$$EnsSuspended($$$SystemName,"Ens.Queue",pQueueName,tPriority,tIndex)), qHandle("lev")=2
			}
		}
		Else {
			If $D($$$EnsQueue) {
				Set qHandle=$name($$$EnsQueue(pQueueName,1)), qHandle("lev")=0
			} Else {
				Set qHandle=$name($$$EnsSuspended($$$SystemName,"Ens.Queue",pQueueName,1)), qHandle("lev")=2
			}
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod EnumerateItemFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateItemExecute ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tRef=$Q(@qHandle), tLev=qHandle("lev")
		If tRef="" Set AtEnd=1 Quit
		If $QS(tRef,1+tLev)'=$QS(qHandle,1+tLev) Set AtEnd=1 Quit
		Set tPriority=$QS(tRef,2+tLev),tIndex=$QS(tRef,3+tLev)
		If tPriority=""!(tPriority'?1N) Set AtEnd=1 Quit
		Set Row=$ListBuild(tPriority,tIndex,$g(@tRef)),qHandle=tRef
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod EnumerateItemClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateItemFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Return the count of messages in the named queue. Return empty string if queue does not exist.
ClassMethod GetCount(pQueueName As %String) As %Integer
{
	Set tQRef=$S($D($$$EnsQueue):$name($$$EnsQueue), 1:$name($$$EnsSuspended($$$SystemName,"Ens.Queue")))
	Quit $G(@tQRef@($G(pQueueName,"*"),0,"count"))
}

/// Internal method to move from a BP with dedicated pool size to Ens.Actor.
/// Moves in same order to end of destination queue.
/// Limited to destination queue of Ens.Actor.
ClassMethod moveQueue(pFromQueueName As %String = "", pToQueueName As %String = "", Output pNumberMoved As %Integer = 0) As %Status [ Internal, Private ]
{
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_Queues:WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	If '##class(Ens.Director).IsProductionRunning() Quit $$$EnsError($$$EnsErrProductionNotRunning)
	If (pFromQueueName="")||(pToQueueName'="Ens.Actor")||(pFromQueueName=pToQueueName) Quit $$$ERROR($$$EnsErrGeneral,"Invalid QueueName parameter")
	If $Data($$$EnsQueue(pFromQueueName))=0 Quit $$$ERROR($$$EnsErrGeneral,"Queue '"_pFromQueueName_"' does not exist")
	#Dim tSC,tSC1 As %Status =$$$OK
	#Dim tFromLocked,tToLocked As %Boolean=0
	#Dim tPriority,tIndex As %Integer
	#Dim ex As %Exception.StatusException
	
	Try {
		Lock +$$$EnsQueue(pFromQueueName)
		Set tFromLocked=1
		Lock +$$$EnsQueue(pToQueueName)
		Set tToLocked=1

		#; Create destination Queue and Event if they do not exist which they ought to for Ens.Actor
		If $Data($$$EnsQueue(pToQueueName))=0 {
			Set $$$EnsQueue(pToQueueName,0,"count")=0
			Set $$$EnsQueue(pToQueueName,0,"next")=0
			Set $$$EnsQueue(pToQueueName,0,"time")=$$$timeUTC
		}
		
		If (pToQueueName'?1.N) && '$SYSTEM.Event.Defined(..EventName(pToQueueName)) {
			Do $SYSTEM.Event.Create(..EventName(pToQueueName))
			$$$sysTRACE("event '"_..EventName(pToQueueName)_"' created")
		}
		
		Set tPriority=$O($$$EnsQueue(pFromQueueName,0))
		While tPriority'="" {
			Set tIndex=$O($$$EnsQueue(pFromQueueName,tPriority,""))
			While (tIndex'="") {
				Set tSC1=..moveItem(pFromQueueName,tPriority,tIndex,pToQueueName)
				If $$$ISERR(tSC1) Set tSC=$$$ADDSC(tSC,tSC1)
				Set pNumberMoved = pNumberMoved + 1
				Set tIndex=$O($$$EnsQueue(pFromQueueName,tPriority,tIndex))
			}
			Set tPriority=$O($$$EnsQueue(pFromQueueName,tPriority))
		}
	
	} Catch ex {Set tSC = ex.AsStatus()}
	
	If tFromLocked Lock -$$$EnsQueue(pFromQueueName)
	If tToLocked Lock -$$$EnsQueue(pToQueueName)
	If tSC Do $SYSTEM.Event.Clear(..EventName(pFromQueueName))
	Quit tSC
}

/// Called internally. Requires caller to check permissions, lock the queues and validate parameters to be passed in and pToQueueName queue and event to exist.
/// Assumes that old and new queues are of the same business type. Intended to work with moveQueue
ClassMethod moveItem(pFromQueueName As %String, pPriority As %Integer, pIndex As %Integer, pToQueueName As %String) As %Status [ Internal, Private ]
{
	#Dim tSC As %Status =$$$OK
	#Dim ex As %Exception.StatusException
	#Dim tSuccess As %Boolean = 0
	#Dim tId As %String
	#Dim tToIndex As %Integer
	#Dim tHdr As Ens.MessageHeader
	
	Try {
		TSTART
		#; Remove from source Queue
		Set tId=$$$EnsQueue(pFromQueueName,pPriority,pIndex)
		Kill $$$EnsQueue(pFromQueueName,pPriority,pIndex)
		Set $$$EnsQueue(pFromQueueName,0,"count")=$$$EnsQueue(pFromQueueName,0,"count")-1
		
		#; Change Target Queue Name for Header to new queue
		Set tHdr = ##class(Ens.MessageHeader).%OpenId(tId,,.tSC)
		If $$$ISERR(tSC) Quit
		Set tHdr.TargetQueueName = pToQueueName
		Set tSC = tHdr.%Save()
		If $$$ISERR(tSC) Quit
		
		#; Put tId on destination Queue at same priority
		Set tToIndex=$Increment($$$EnsQueue(pToQueueName,0,"next"))
		Set $$$EnsQueue(pToQueueName,pPriority,tToIndex)=tId
		Set $$$EnsQueue(pToQueueName,0,"count")=$$$EnsQueue(pToQueueName,0,"count")+1		
		
		$$$sysTRACE("moving #"_tId_" with body Class '"_tHdr.MessageBodyClassName_"' and body Id '"_tHdr.MessageBodyId_"' to "_pToQueueName_" from "_pFromQueueName_" at priority "_pPriority_$S(""=tHdr.ReturnQueueName:"",1:", RetQ="_tHdr.ReturnQueueName))
		
		#; Commit transaction
		TCOMMIT
		Set tSuccess = 1 
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If tSuccess {
		Try {
			Do $system.Event.Signal(..EventName(pToQueueName))
		} Catch ex {
			$$$LOGWARNING("Failed to signal event '" _ ..EventName(pToQueueName) _ "' for Header '" _ tId _ "' on queue '" _ pToQueueName _ "' due to exception: " _ $system.Status.GetErrorText(ex.AsStatus()))
		}
	} Else {
		TROLLBACK 1
	}
	
	Quit tSC
}

/// This is a support method to help where a Business Process has had its pool size changed from 1 or more to 0. <br>
/// If pFromQueueName is a Business Process with pool size of 0 then this will attempt to <br>
/// to move items from a queue with this name to the Ens.Actor queue. <br>
/// If successful this will provide the number of items moved. <br>
/// This does not satisfy FIFO requirements as per the documentation. <br> 
ClassMethod MoveQueueToPublic(pFromQueueName As %String, Output pNumberMoved As %Integer = 0) As %Status [ Internal ]
{
	#;Check if a) BP and b) Pool Size is 0
	If ($G($$$ConfigBusinessType(pFromQueueName),-1)'=$$$eHostTypeProcess) || ($G($$$ConfigPoolSize(pFromQueueName),-1)'=0) Quit $$$ERROR($$$EnsErrGeneral,"Not a valid candidate for queue move")
	Quit ..moveQueue(pFromQueueName,"Ens.Actor",.pNumberMoved)
}

/// Internal method signalling all event devices for a given queue.
/// Callers responsibility to ensure pQueueName defined non empty string and catch errors
ClassMethod signalQueueEventDevices(pQueueName As %String) [ Internal ]
{
	#dim tDevice As %String = $Order($$$EnsQueue(pQueueName,0,"event-device",""))

	While (tDevice'="") {

		Do ..signalEventDevice(tDevice)

		Set tDevice=$Order($$$EnsQueue(pQueueName,0,"event-device",tDevice))
	}
}

/// Internal method for signalling event devices
/// Callers responsibility to ensure pDevice defined and valid and catch errors
ClassMethod signalEventDevice(pDevice As %String) [ Internal ]
{

	If $Extract(pDevice,1,5)=$$$EnsSelectInterruptRoot {
		Do $SYSTEM.Socket.SelectInterrupt($P(pDevice,"|",3))

	} ElseIf $Extract(pDevice,1,5)="|TCP|" {
		Open pDevice:("127.0.0.1":$p(pDevice,"|",3):"S"):0 Close pDevice

	}
}

/// Visiting jobs do not remove queues on tear down for performant reasons.
/// (visiting jobs can reuse OS pid immediately) <br/>
/// This internal method is called by the Purge method of Ens.MonitorService to remove
/// queue entries for non registered jobs. <br/>
/// <parameter>pRemoveJobsInProcess</parameter> will remove all job entries for a 
/// queue associated with unregistered jobs that call InProc hosts. <br/>
ClassMethod DeleteAllQueuesForUnRegisteredJobs(pRemoveJobsInProcQueues As %Boolean = 0) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tName, tCachedName, tJob
	Try {
		Set tName=$o($$$EnsQueue("")) While tName'="" {
			If (tName'=$Job) Merge tCachedName(tName)=$$$EnsQueue(tName,0,"job",$$$SystemName)
			Set tName=$o($$$EnsQueue(tName))
		}
		Set tName=$o(tCachedName("")) While tName'="" {
			Set tJob=$o(tCachedName(tName,"")) While tJob'="" {
				#; Only delete if job not registered
				If '$data($$$EnsJobStatus($$$SystemName,tJob)) {
					If pRemoveJobsInProcQueues && ($Piece(tName,":",2)=tJob) {
						Set tSC=..Delete(tName,"*")
					} Else {
						Set tSC=..Delete(tName,tJob)
					}
					Quit:$$$ISERR(tSC)
				}
				Set tJob=$o(tCachedName(tName,tJob))
			}
			Quit:$$$ISERR(tSC)
			Set tName=$o(tCachedName(tName))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Internal method subject to change <br>
/// Based on DeQueueId but with special handling for multiple
/// job MsgBank Operation. <br>
/// Does not use HonorQuiescent or minimum priority as not 
/// used by Message Bank framework. <br>
ClassMethod MsgBankDeQueueId(pQueueName As %String = {$job}, Output pId As %String, pTimeout As %Numeric = -1, Output pIsTimedOut As %Boolean, pUnusedHonorQuiescent, pUnusedMinPriority, Output pHaveBankHdrLock As %Boolean = 0) As %Status [ Internal ]
{
	Set $ZT="Trap", tSC=$$$OK, tIsSuccess=0, tId="", pId="", pIsTimedOut=0, tLocked = 0
	Do {
		$$$catTRACE("queue","dequeueing from "_pQueueName_" with timeout="_pTimeout)
		If $data($$$EnsQueue(pQueueName,0,"job",$$$SystemName,$Job))=0 Set tSC=..Create(pQueueName) If $$$ISERR(tSC) Quit

		/* Check quiesce before looking at queue since all entries in this queue
			are asynchronous and want to avoid large queue delaying shutdown.
		*/
		If ##class(Ens.Job).ShouldBeQuiescent() {
			Do ##class(Ens.Job).SetStatus($$$eJobStatusQuiescent,pQueueName)
			Do $system.Event.Create("^Ens.Event.JobRequester")
			Do $system.Event.Signal("^Ens.Event.JobRequester")
			Quit
		} Else {
			Do ##class(Ens.Job).SetStatus($$$eJobStatusDeQueuing,pQueueName)
		}

		/* Look for data before waiting for event
			so not dependent on signal.
			This like other DeQueue<> methods is the same
			queue global loop code executed after receiving an event.
		*/
		Lock +$$$EnsQueue(pQueueName)
		Set tLocked = 1
		Set tPriority=$o($$$EnsQueue(pQueueName,0))
		#; only one priority since do not use priority for msgbank
		If tPriority'="" {
			Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,""))
			While (tIndex'="")&&'tIsSuccess {
				Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
				Set tHdrId=$p(tId,"_",3,*)
				If (tHdrId'="")&&'$Data(tSkippedHdr(tHdrId)) {
					Lock +^Ens.MsgBank.Banked(tHdrId):0
					Set pHaveBankHdrLock = $Test
				}
				#; allow "" through for the operation code to handle as error
				If pHaveBankHdrLock||(tHdrId="") {
					If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
					Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
					Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
					Set tIsSuccess=1
				} Else {
					/*	safety valve if not obtaining a lock with zero timeout
						- tTotalNumberSkipped is initialised by $increment
						- 1000 is a magic round number
						- only warn once per instance start
					*/
					If $i(tTotalNumberSkipped)>1000 {
						If $i(^IRIS.Temp.EnsScratch($namespace,"Warn","MsgBankDeQueueId"))=1 $$$LOGWARNING("Dequeuing for Message Bank Operation encountered slow lock access for ^Ens.MsgBank.Banked")
						Quit
					}
					#; only record first skipped entry for a hdr in progress
					Set:'$Data(tSkippedHdrs(tHdrId)) tSkippedHdrs(tHdrId) =$lb(tPriority,tIndex)
					Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,tIndex))
				}
			}
			#; if none left in queue take a skipped and pass on anyway
			If 'tIsSuccess&&$Data(tSkippedHdrs) {
				Set tSkippedHeader = $Order(tSkippedHdrs(""),1,tSkippedInfo)
				If tSkippedHeader'="" {
					Set tPriority = $lg(tSkippedInfo,1)
					Set tIndex = $lg(tSkippedInfo,2)
					If (tPriority'="") && (tIndex'="") {
						Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
						If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
						Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
						Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
						Set tIsSuccess=1
					}
				}
			}
		}
		Lock -$$$EnsQueue(pQueueName)
		Set tLocked = 0
		Quit:tIsSuccess
		#; Need to reset if found a queue entry and triggered safety valve
		If (tId'="") {
			Kill tSkippedHdrs
			Set tTotalNumberSkipped = 0, tId = ""
		}

		While 1 {
			If pTimeout>0 {
				Set:pTimeout\1'=pTimeout pTimeout=pTimeout\1+1
				Set tWakeTime=pTimeout+$ZH
			}
			$$$catTRACE("queue","begin wait: "_pTimeout)
			If '$system.Event.Wait(..EventName(pQueueName),pTimeout) {
				$$$catTRACE("queue","dequeuing timed out")
				Do ##class(Ens.Job).SetStatus($S($G($$$EnsJobLocal("TCPIn.OutsideJob")):$$$eJobStatusVisiting,1:$$$eJobStatusRunning))
				Set pIsTimedOut=1
				Quit
			} Else {
				$$$catTRACE("queue","dequeuing received an event")
			}
			Lock +$$$EnsQueue(pQueueName)
			Set tLocked = 1
			Set tPriority=$o($$$EnsQueue(pQueueName,0))
			#; only one priority since do not use priority for msgbank
			If tPriority'="" {
				Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,""))
				While (tIndex'="")&&'tIsSuccess {
					Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
					Set tHdrId=$p(tId,"_",3,*)
					If (tHdrId'="")&&'$Data(tSkippedHdr(tHdrId)) {
						Lock +^Ens.MsgBank.Banked(tHdrId):0
						Set pHaveBankHdrLock = $Test
					}
					#; allow "" through for the operation code to handle as error
					If pHaveBankHdrLock||(tHdrId="") {
						If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
						Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
						Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
						Set tIsSuccess=1
					} Else {
						/*	safety valve if not obtaining a lock with zero timeout
							- tTotalNumberSkipped is initialised by $increment
							- 1000 is a magic round number
							- only warn once per instance start
						*/
						If $i(tTotalNumberSkipped)>1000 {
							If $i(^IRIS.Temp.EnsScratch($namespace,"Warn","MsgBankDeQueueId"))=1 $$$LOGWARNING("Dequeuing for Message Bank Operation encountered slow lock access for ^Ens.MsgBank.Banked")
							Quit
						}
						#; only record first skipped entry for a hdr in progress
						Set:'$Data(tSkippedHdrs(tHdrId)) tSkippedHdrs(tHdrId) =$lb(tPriority,tIndex)
						Set tIndex=$o($$$EnsQueue(pQueueName,tPriority,tIndex))
					}
				}
				#; if none left in queue take a skipped and pass on anyway
				If 'tIsSuccess&&$Data(tSkippedHdrs) {
					Set tSkippedHeader = $Order(tSkippedHdrs(""),1,tSkippedInfo)
					If tSkippedHeader'="" {
						Set tPriority = $lg(tSkippedInfo,1)
						Set tIndex = $lg(tSkippedInfo,2)
						If (tPriority'="") && (tIndex'="") {
							Set tId=$$$EnsQueue(pQueueName,tPriority,tIndex)
							If $data($$$EnsActiveMessage($$$SystemName_":"_$Job))=0&&$$$queueIsNotSyncQueue(pQueueName) Set $$$EnsActiveMessage($$$SystemName_":"_$Job)=tId
							Kill $$$EnsQueue(pQueueName,tPriority,tIndex)
							Set $$$EnsQueue(pQueueName,0,"count")=$$$EnsQueue(pQueueName,0,"count")-1
							Set tIsSuccess=1
						}
					}
				}
			}
			Lock -$$$EnsQueue(pQueueName)
			Set tLocked = 0
			Quit:tIsSuccess

			$$$catTRACE("queue","dequeue failed to find a message on "_pQueueName)
			Quit:##class(Ens.Job).ShouldBeQuiescent() 
			Quit:##class(Ens.Job).ShouldTerminate()
			If pTimeout>0 {
				Set tNow=$ZH  If tNow>tWakeTime Set pIsTimedOut=1  Quit
				Set pTimeout=tWakeTime-tNow
			}
		} ; while 1
	} While 0

	If tIsSuccess {
		Do ##class(Ens.Job).SetStatus($S($G($$$EnsJobLocal("TCPIn.OutsideJob")):$$$eJobStatusVisiting,1:$$$eJobStatusRunning))
		Set pId=tId
		$$$sysTRACE("dequeuing from "_pQueueName_" found message #"_tId)
	}
Exit
	Lock:tLocked -$$$EnsQueue(pQueueName)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
