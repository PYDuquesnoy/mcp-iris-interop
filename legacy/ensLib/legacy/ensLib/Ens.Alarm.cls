/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The Ens.Alarm code is designed for use in a single process, so users should ensure
/// that they do not configure Ens.Alarm to run with a PoolSize greater than 1.
Class Ens.Alarm Extends Ens.Host [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// 2 modes: Queue, InProc
Parameter INVOCATION = "Queue";

/// Lock timeout used when adding data to the main $$$EnsAlarm global.
Parameter LOCKTIMEOUT = 2;

/// Lock timeout used when moving data into or out of a suspended state.
Parameter RECOVERYLOCKTIMEOUT = 10;

Parameter DOMAIN = "Ensemble";

Method MessageHeaderHandler(pRequestHeader As Ens.MessageHeader, Output pResponseHeader As Ens.MessageHeader) As %Status
{
	Set $ZE = ""
	Do pRequestHeader.SetStatus($$$eMessageStatusDelivered)
	If pRequestHeader.MessageBodyClassName="Ens.AlarmRequest" {
		If pRequestHeader.ReturnQueueName="" Quit $$$OK
		Set tMessageBody = ##class(Ens.AlarmRequest).%OpenId(pRequestHeader.MessageBodyId)
		Set tUTCH=$$$timeUTCH,tUTCseconds=$p(tUTCH,",",1)*86400+$p(tUTCH,",",2)
		Set tDurationInSecondsFromNow=tMessageBody.DurationInSecondsFromNow()
		Set tWakeTime=tUTCseconds+tDurationInSecondsFromNow
		$$$sysTRACE("received '"_pRequestHeader.SourceConfigName_"' => "_tDurationInSecondsFromNow)
		Set tStatus = ..AddAlarm(tWakeTime,pRequestHeader.%Id(),tMessageBody.%Id(),tMessageBody.DiscardOnShutdown,0)
		If $$$ISERR(tStatus) Quit tStatus
	} ElseIf pRequestHeader.MessageBodyClassName="Ens.AlarmTriggerRequest" {
		Set tMessageBody = ##class(Ens.AlarmTriggerRequest).%OpenId(pRequestHeader.MessageBodyId)
		Set tStatus = ..InterruptAlarm(tMessageBody.AlarmHandle)
		If $$$ISERR(tStatus) Quit tStatus
		Do pRequestHeader.SetStatus($$$eMessageStatusCompleted)
	} Else {
		Quit $$$EnsError($$$EnsErrRequestNotHandled,pRequestHeader.MessageBodyClassName_"("_pRequestHeader.MessageBodyId_")")
	}

	// global stats (for Alarm)
	Set tClassName=$classname(), tUTC=$$$timeUTC
	$$$IncHostCounterTime(tClassName)

	// local stats (for Actor)
	If (..#INVOCATION = "Queue") {
		$$$IncJobCounterTime(tClassName,$$$SystemName_":"_$Job)
	}
	Quit $$$OK
}

Method CheckAlarmTasks(Output pResponseHeader As Ens.MessageHeader, Output pTimeToNextEvent As %Integer, Output pResponseHandle As %Integer)
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pResponseHandle=0
		set tIsInterrupted=0
		Set tNextEventTime = $order(^||ISC.Ens.Alarm("Time",""))
		If tNextEventTime = "" {
			Set pResponseHeader=$$$NULLOREF
			Set pTimeToNextEvent=-1
			Quit
		}
		// check for interrupted events first
		Set tNextEventHandle = $order(^||ISC.Ens.Alarm("Interrupt",""))
		If tNextEventHandle '= "" {
			Set tIsInterrupted = 1
			Set tNextEventTime=""
		}
		// find real events only if we've not found interrupted events. tNextEventTime is not ""
		If tNextEventHandle="" {
			Set tNextEventHandle = $order(^||ISC.Ens.Alarm("Time",tNextEventTime,""))
			// tNextEventHandle ought not be "" due to check when set
			Set tUTCH=$$$timeUTCH,tUTCseconds=$p(tUTCH,",",1)*86400+$p(tUTCH,",",2)
			Set pTimeToNextEvent = tNextEventTime-tUTCseconds
			If pTimeToNextEvent>0 Set pResponseHeader=$$$NULLOREF Quit
			Set pTimeToNextEvent=0
		}
		Try {
			#dim ex As %Exception.AbstractException
			#; we have an event to send. the ID is tNextEventHandle
			Set tData = $get($$$EnsAlarm(tNextEventHandle))
			#; Missing data and not an interrupt
			If (tData="") && (tNextEventTime) {
				#; Try to get the request header id from index due to duplicate alarm
				Set tRequestHeaderId = $Get(^||ISC.Ens.Alarm("Time",tNextEventTime,tNextEventHandle))
				#; Need to remove since if do create a response the caller of this method will not be able to clean up
				If (tRequestHeaderId'="") Do ..RemoveAlarm(tNextEventHandle,tNextEventTime)
			} Else {
				Set tRequestHeaderId = $LG(tData,2)
			}
			Set tRequestHeader=##class(Ens.MessageHeader).%OpenId(tRequestHeaderId)
		} Catch ex {
			#; Corrupt tData or message header error. Ensure defined for error reporting
			Set tRequestHeaderId = $get(tRequestHeaderId)
			Set tRequestHeader = $$$NULLOREF
		}
		If tRequestHeader=$$$NULLOREF {
			#; Pass in tNextEventTime (might be "" if 'Interrupt') in case data corrupted and need to remove ^||ISC.Ens.Alarm("Time",tNextEventTime,tNextEventHandle)
			Do ..RemoveAlarm(tNextEventHandle,tNextEventTime)
			#dim tAlarmErrorText = "Message '"_tRequestHeaderId_"' can not be found, timer event ignored. Timer ID ='"_tNextEventHandle_"'."
			If ($Data(ex)#2) && ($IsObject(ex)) Set tAlarmErrorText = tAlarmErrorText_" Data='"_tData_"' caught error "_ex.Name
			Set tAlarmErrorText = tAlarmErrorText_" Sent request to ScheduleHandler to check for production differences."
			$$$LOGERROR(tAlarmErrorText)
			/*
				Ask ScheduleHandler to check in case the missing alarm request was from scheduler. 
				We do not have SendRequestAsync() so we need to job off CallScheduleService since we cannot create a business service from within a host item
			*/
			Job ##class(Ens.ScheduleService).CallScheduleService()::5
			If '$Test {Set tSC = $$$ERROR($$$EnsErrGeneral,$$$Text("Timed out trying to job off process to notify Scheduler"))}
			Quit
		}
		#; set up AlarmResponse body with property IsInterrupted
		Set tMessageBody=##class(Ens.AlarmResponse).%New()
		Set tMessageBody.IsInterrupted=tIsInterrupted
		Set tSC=tRequestHeader.NewResponseMessage(.pResponseHeader,tMessageBody) Quit:$$$ISERR(tSC)
		Set pResponseHeader.Priority=$$$eMessagePriorityHighSync
		#;
		Do tRequestHeader.SetStatus($$$eMessageStatusCompleted)
		Set pResponseHandle = tNextEventHandle
		$$$sysTRACE("notified '"_tRequestHeader.SourceConfigName_"'")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method OnTask() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; check the action list first, this also tells us what's the closest event
		do {
			Set tResponseHeader=$$$NULLOREF
			Set tSC=..CheckAlarmTasks(.tResponseHeader,.tTimeToNextEvent,.tResponseHandle) Quit:$$$ISERR(tSC)
			If $IsObject(tResponseHeader) {
				If tResponseHeader.TargetQueueName'="" {
					Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader)
					// check tSC *after* removing alarm
				}
			}
			If $get(tResponseHandle) Set tSC = $$$ADDSC(tSC,..RemoveAlarm(tResponseHandle))
			If $$$ISERR(tSC) Quit
			If '$IsObject(tResponseHeader) Quit
		} while (1)
		#; use HANG if time to next event is less than 1 second
		if (tTimeToNextEvent>0)&&(tTimeToNextEvent<1) {
			f i=1:1:tTimeToNextEvent/0.1+1 hang 0.1
		} else {
			Set tSC = ##class(Ens.Queue).DeQueue(..QueueName(),.tRequestHeader,tTimeToNextEvent\1,,1) Quit:$$$ISERR(tSC)
			If $IsObject(tRequestHeader) {
				Set tSC=..MessageHeaderHandler(tRequestHeader)
				If $$$ISERR(tSC),tRequestHeader.ReturnQueueName'="" {
					Set tSC = tRequestHeader.NewErrorResponse(.tResponseHeader,tSC) Quit:$$$ISERR(tSC)
					Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
				}
			}
		}
	} while (0)
Exit
	Kill $$$EnsActiveMessage($$$SystemName_":"_$Job)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method previously ran the code that is now in <method>SuspendAlarms</method>(), but
/// that code is now invoked from <class>Ens.Director</class> during production shutdown.
Method OnTearDown() As %Status
{
	Quit $$$OK
}

/// Load any suspended tasks from $$$EnsSuspendedAppData when this config item is started.
/// Note that only one config item will receive ALL previously suspended tasks.
Method OnInit() As %Status
{
	#; Check for PoolSize > 1
	If $$$ConfigPoolSize("Ens.Alarm") > 1 { $$$LOGWARNING("Ens.Alarm is not designed to run with PoolSize > 1") }
	Else {
		#; Check for data in ^Ens.Alarm, which can happen if only Ens.Alarm is bounced without a production restart
		Lock +$$$EnsAlarm:..#RECOVERYLOCKTIMEOUT
		If '$Test Quit $$$ERROR($$$LockFailedToAcquireExclusive,$name($$$EnsAlarm))
		Try {
			Set tStatus = $$$OK
			Set tAlarmId = ""
			For {
				Set tAlarmId = $order($$$EnsAlarm(tAlarmId),1,tData)
				Quit:(tAlarmId = "")
				#; Protect against corrupted ^Ens.Alarm
				Try {
					Set tWakeTime = $lg(tData,1)
					Set tRequestHeaderId = $lg(tData,2)
					Set tDiscardOnShutdown = $lg(tData,3,0)
					Set tIsInterrupted = $lg(tData,4,0)
				} Catch {
					Set tWakeTime=$Get(tWakeTime)
					Set tRequestHeaderId = $Get(tRequestHeaderId)
					Set tDiscardOnShutdown = $Get(tDiscardOnShutdown)
					Set tIsInterrupted = $Get(tIsInterrupted)
				}
				#; If ^Ens.Alarm corrupted before job restart check that the data is not corrupt
				If (tWakeTime = "") || (tRequestHeaderId = "") {
					$$$LOGERROR("Insufficient information to restore AlarmRequest with ID = '"_tAlarmId_"'; WakeTime='"_tWakeTime_"'; RequestHeader='"_tRequestHeaderId_"'")
					Kill $$$EnsAlarm(tAlarmId)
					Continue
				}
				Set tStatus1 = ..AddAlarm(tWakeTime,tRequestHeaderId,tAlarmId,tDiscardOnShutdown,tIsInterrupted)
				If $$$ISERR(tStatus1) {
					$$$LOGERROR("Failed to restore AlarmRequest '"_tRequestHeaderId_"' due to error: "_$system.Status.GetErrorText(tStatus1))
				}
				Else {
					$$$sysTRACE("restored alarm request '"_tRequestHeaderId_"'")
				}
			}
		}
		Catch ex {
			Set tStatus = $$$EnsSystemError
		}
		Lock -$$$EnsAlarm
		If $$$ISERR(tStatus) Quit tStatus
	}
	#; Restore alarm tasks from previous production session
	Lock +$$$EnsSuspendedAppData("Ens.Alarm"):..#RECOVERYLOCKTIMEOUT
	If '$Test Quit $$$ERROR($$$LockFailedToAcquireExclusive,$name($$$EnsSuspendedAppData("Ens.Alarm")))
	Set tCheckJobSubscript = 1
	Set tJob = ""
	For {
		Set tJob = $order($$$EnsSuspendedAppData("Ens.Alarm",tJob))
		Quit:(tJob = "")
		If tCheckJobSubscript {
			Set tHasJobSubscript = ($order($$$EnsSuspendedAppData("Ens.Alarm",tJob,"")) '= "")
			Set tCheckJobSubscript = 0
		}
		If 'tHasJobSubscript { ; Pre-DDP418 format
			Set tOldData = $get($$$EnsSuspendedAppData("Ens.Alarm",tJob))
			If tOldData = "" Continue
			Set tWakeTime = $li(tOldData,1)
			Set tRequestHeaderId = $li(tOldData,2)
			Set tAlarmHandle = $li(tOldData,3)
			If (tWakeTime = "") || (tRequestHeaderId = "") || (tAlarmHandle = "") {
				$$$LOGERROR("Insufficient information to restore AlarmRequest with ID = '"_tAlarmHandle_"'; WakeTime='"_tWakeTime_"'; RequestHeader='"_tRequestHeaderId_"'")
				Continue
			}
			Set tStatus = ..AddAlarm(tWakeTime,tRequestHeaderId,tAlarmHandle)
			If $$$ISERR(tStatus) {
				$$$LOGERROR("Failed to restore AlarmRequest '"_tRequestHeaderId_"' due to error: "_$system.Status.GetErrorText(tStatus))
			}
			Else {
				$$$sysTRACE("restored alarm request '"_tRequestHeaderId_"'")
			}
		}
		Else { ; Format after DDP418 with extra $Job subscript; After DDP527, the subscript is 0 due to the use of ^Ens.Alarm
			Set tAlarmHandle=""
			For {
				Set tAlarmHandle=$order($$$EnsSuspendedAppData("Ens.Alarm",tJob,tAlarmHandle),1,tData)
				Quit:(tAlarmHandle = "")
				If tData = "" Continue
				Set tWakeTime = $lg(tData,1)
				Set tRequestHeaderId = $lg(tData,2)
				Set tDiscardOnShutdown = $lg(tData,3,0)
				Set tIsInterrupted = $lg(tData,4,0)
				If (tWakeTime = "") || (tRequestHeaderId = "") {
					$$$LOGERROR("Insufficient information to restore AlarmRequest with ID = '"_tAlarmHandle_"'; WakeTime='"_tWakeTime_"'; RequestHeader='"_tRequestHeaderId_"'")
					Continue
				}
				If tDiscardOnShutdown {
					$$$sysTRACE("Not restoring AlarmRequest '"_tRequestHeaderId_"' as DiscardOnShutdown is true")
					Set tStatus = ..RemoveAlarmFromRequestor(tRequestHeaderId)
					If $$$ISERR(tStatus) {
						$$$LOGERROR("Failed to remove AlarmRequest '"_tRequestHeaderId_"' from requestor due to error: "_$system.Status.GetErrorText(tStatus))
					}
					Continue
				}
				Set tStatus = ..AddAlarm(tWakeTime,tRequestHeaderId,tAlarmHandle,tDiscardOnShutdown,tIsInterrupted)
				If $$$ISERR(tStatus) {
					$$$LOGERROR("Failed to restore AlarmRequest '"_tRequestHeaderId_"' due to error: "_$system.Status.GetErrorText(tStatus))
				}
				Else {
					$$$sysTRACE("restored alarm request '"_tRequestHeaderId_"'")
				}
			}
		}
	}
	Kill $$$EnsSuspendedAppData("Ens.Alarm")
	Lock -$$$EnsSuspendedAppData("Ens.Alarm")
	Quit $$$OK
}

/// Helper method to correctly add an alarm. The main data is stored in ^Ens.Alarm, and the ^||ISC.Ens.Alarm 
/// process-private global is used to store index data to avoid local memory exhaustion.
/// The ^Ens.Alarm data stores the main data for the request subscripted by the AlarmRequest ID.
/// Two subscripts in the PPG are used to index the data. The "Time" subscript is an index based on the requested wakeup time.
/// The "Interrupt" index is an index for items that have received interrupt requests.
Method AddAlarm(pWakeTime As %String, pRequestHeaderId As %Integer, pAlarmHandle As %Integer, pDiscardOnShutdown As %Integer = 0, pIsInterrupted As %Boolean = 0) As %Status
{
	If pAlarmHandle = "" Quit $$$OK
	Set tStatus = $$$OK
	Try {
		Lock +$$$EnsAlarm(pAlarmHandle):..#LOCKTIMEOUT
		If '$Test {
			Set tStatus = $$$ERROR($$$LockFailedToAcquireExclusive,$name($$$EnsAlarm(pAlarmHandle)))
			Quit
		}
		Set tLocked = 1
		#; Do not check if alarm body already outstanding - will be handled in CheckAlarmTasks - but record pRequestHeaderId as backup
		Set $$$EnsAlarm(pAlarmHandle) = $lb(pWakeTime,pRequestHeaderId,pDiscardOnShutdown,pIsInterrupted)
		Set ^||ISC.Ens.Alarm("Time",pWakeTime,pAlarmHandle) = pRequestHeaderId
		If pIsInterrupted Set ^||ISC.Ens.Alarm("Interrupt",pAlarmHandle) = ""
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLocked) Lock -$$$EnsAlarm(pAlarmHandle)
	Quit tStatus
}

/// Helper method to correctly remove an alarm.
Method RemoveAlarm(pAlarmHandle As %Integer = -1, pTimeIndexUsedForAlamHandle As %String = "") As %Status
{
	If pAlarmHandle = "" Quit $$$OK
	Set tStatus = $$$OK
	Try {
		Lock +$$$EnsAlarm(pAlarmHandle):..#LOCKTIMEOUT
		If '$Test {
			Set tStatus = $$$ERROR($$$LockFailedToAcquireExclusive,$name($$$EnsAlarm(pAlarmHandle)))
			Quit
		}
		Set tLocked = 1
		Set tData = $get($$$EnsAlarm(pAlarmHandle))
		Kill $$$EnsAlarm(pAlarmHandle)
		Kill ^||ISC.Ens.Alarm("Interrupt",pAlarmHandle)
		Set tWakeTime = ""
		If (tData '= "") {
			Set tWakeTime = $lg(tData,1)
		}
		#; Clean up Time index accounting for corrupted data
		If (tWakeTime ="") && ((pTimeIndexUsedForAlamHandle'="") && $Data(^||ISC.Ens.Alarm("Time",pTimeIndexUsedForAlamHandle,pAlarmHandle))) {
			Set tWakeTime = pTimeIndexUsedForAlamHandle
		}
		If (tWakeTime '="") {
			Kill ^||ISC.Ens.Alarm("Time",tWakeTime,pAlarmHandle)
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLocked) Lock -$$$EnsAlarm(pAlarmHandle)
	Quit tStatus
}

/// Helper method to mark an alarm as interrupted.
Method InterruptAlarm(pAlarmHandle As %Integer = -1) As %Status
{
	If pAlarmHandle = "" Quit $$$OK
	Set tStatus = $$$OK
	Try {
		Lock +$$$EnsAlarm(pAlarmHandle):..#LOCKTIMEOUT
		If '$Test {
			Set tStatus = $$$ERROR($$$LockFailedToAcquireExclusive,$name($$$EnsAlarm(pAlarmHandle)))
			Quit
		}
		Set tLocked = 1
		Set tData = $get($$$EnsAlarm(pAlarmHandle))
		If tData '= "" {
			Set $li(tData,4) = 1
			Set $$$EnsAlarm(pAlarmHandle) = tData
			Set ^||ISC.Ens.Alarm("Interrupt",pAlarmHandle) = ""
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLocked) Lock -$$$EnsAlarm(pAlarmHandle)
	Quit tStatus
}

/// Move Alarm data from ^Ens.Alarm to ^Ens.SuspendedAppData("Ens.Alarm").
/// Note that requests with DiscardOnShutdown=1 will not be suspended.
ClassMethod SuspendAlarms() As %Status
{
	If '$data($$$EnsAlarm) Quit $$$OK
	#; If flag has already been set, quit
	If $data($$$EnsSuspendedAppData("Ens.Alarm")) Quit $$$OK
	#; Move alarm data to suspended global
	Lock +$$$EnsSuspendedAppData("Ens.Alarm"):..#RECOVERYLOCKTIMEOUT
	If '$Test Quit $$$ERROR($$$LockFailedToAcquireExclusive,$name($$$EnsSuspendedAppData("Ens.Alarm")))
	#; Add another check just to ensure this hasn't been performed by another job
	If '$data($$$EnsSuspendedAppData("Ens.Alarm")) {
		Set tKey = ""
		For {
			Set tKey = $order($$$EnsAlarm(tKey),1,tData)
			Quit:(tKey = "")
			#; Only copy across if DiscardOnShutdown is 0 or undefined
			#; 0 subscript is used to allow for differentiation between structure from DDP418 and now DDP527
			If '$listget(tData,3,0) {
				Set $$$EnsSuspendedAppData("Ens.Alarm",0,tKey) = tData
			} Else {
				Do ..RemoveAlarmFromRequestor($listget(tData,2))
			}
		}
		$$$KillRootNode($$$EnsAlarm)
	}
	Lock -$$$EnsSuspendedAppData("Ens.Alarm")
	Quit $$$OK
}

/// Helper method to remove DiscardOnShutdown alarm request from requestor.
ClassMethod RemoveAlarmFromRequestor(pRequestHeaderId As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tRequestHeader=##class(Ens.MessageHeader).%OpenId(pRequestHeaderId,.tSC)
		Quit:$$$ISERR(tSC)
		Set tBPId = tRequestHeader.BusinessProcessId,tBP=""
		Set:(tBPId'="") tBP=$classmethod("Ens.BusinessProcess","%OpenId",tBPId,4,.tSC)
		If '$IsObject(tBP) {
			If $$$StatusEquals(tSC,$$$LoadObjectNotFound) {
				Set tSC = $$$OK
			}
			Quit
		}
		Set tSQL = "SELECT %OID(pr.ID) AS prOID, pr.RequestHeaderId AS prHdrId, pr.CompletionKey AS prCK, pr.IsTimer AS prIT, pr.ControlledCompletionKeys AS prCKS FROM Ens_BP.MasterPendingResponse pr WHERE pr.%BusinessProcess = ? AND pr.RequestHeaderId = ?"
		Set tCorrespondingResult = ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL,tBPId,pRequestHeaderId)
		If tCorrespondingResult.%SQLCODE < 0 {
			Set tSC = ##class(%Exception.SQL).CreateFromSQLCODE(tCorrespondingResult.%SQLCODE,tCorrespondingResult.%Message).AsStatus()
			Quit
		} ElseIf (tCorrespondingResult.%SQLCODE = 0)  && tCorrespondingResult.%Next() {
			#; Remove this entry & set header to discarded
			Do tBP.%MasterPendingResponses.RemoveObject(tCorrespondingResult.%Get("prOID"))
			Set tRequestHeader.Status = $$$eMessageStatusDiscarded
			Set tSC = tRequestHeader.%Save()
			Quit:$$$ISERR(tSC)
		}

		If (tBP.%MasterPendingResponses.Count()=0){
			If '$G($$$EnsConfig("bp","RetainCompletedInstances"),$G(^Ens.Config("bp","RetainCompletedInstances"))) {
				Set tSC = tBP.%DeleteId(tBPId)
			} Else {
				Set tBP.%IsCompleted=1, tBP.%TimeCompleted = $$$timeUTC
				Set tSC = tBP.%Save()
			}
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

}
