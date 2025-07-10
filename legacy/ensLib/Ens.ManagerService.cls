/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This service contains methods for interrupting or cancelling Business Process instances and the wakeup alarm request messages that they sometimes use
Class Ens.ManagerService Extends Ens.BusinessService [ ClassType = "", ProcedureBlock, System = 4 ]
{

Method InterruptAlarm(pAlarmHandle As %String) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, pResponse=$$$NULLOREF
	do {
		Set tAlarmTriggerRequest = ##class(Ens.AlarmTriggerRequest).%New(pAlarmHandle)
		Set tSC = ..SendRequestAsync("Ens.Alarm",tAlarmTriggerRequest)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method TriggerAlarm(pAlarmHandle As %String) As %Status
{
	Quit ..InterruptAlarm(.pAlarmHandle)
}

Method CancelBusinessProcess(pBusinessProcessId As %String) As %Status
{
	quit ..TerminateBusinessProcess(pBusinessProcessId,$$$EnsErrBPCancelled)
}

Method TerminateBusinessProcess(pBusinessProcessId As %String, pStatusCode As %Status) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, pResponse=$$$NULLOREF
	do {
		Set tBusinessProcessObject=##class(Ens.BusinessProcess).%OpenId(pBusinessProcessId,4)
		If tBusinessProcessObject=$$$NULLOREF Set tSC=$$$EnsError($$$EnsErrBPCanNotOpen,pBusinessProcessId) Quit
		;
		Set tSessionId = tBusinessProcessObject.%SessionId
		Set tSourceConfigName = ..%ConfigName
		Set tTargetConfigName = tBusinessProcessObject.%PrimaryRequestHeader.TargetConfigName
		Kill tBusinessProcessObject
		;
		If $g(pStatusCode)="" Set pStatusCode=$$$OK
		Set tMessageBody=##class(Ens.StringRequest).%New(pStatusCode)
		;
		Set tSC = ##class(Ens.MessageHeader).NewRequestMessage(.tRequestHeader,tMessageBody,.tSessionId) Quit:$$$ISERR(tSC)
		Set tRequestHeader.Type = $$$eMessageTypeTerminate
		Set tRequestHeader.SourceConfigName = tSourceConfigName
		Set tRequestHeader.TargetConfigName = tTargetConfigName
		Set tRequestHeader.SourceBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(tSourceConfigName))
		Set tRequestHeader.TargetBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(tTargetConfigName))
		Set tRequestHeader.TargetQueueName = $$$ConfigQueueName($$$DispatchNameToConfigName(tTargetConfigName))
		Set tRequestHeader.ReturnQueueName = ""
		Set tRequestHeader.BusinessProcessId = pBusinessProcessId
		Set tRequestHeader.Priority = $$$eMessagePrioritySync
		;
		Set tSC = ##class(Ens.Queue).EnQueue(tRequestHeader) Quit:$$$ISERR(tSC)
		;
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
