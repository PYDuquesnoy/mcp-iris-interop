/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.BusinessDuplex Extends (Ens.BusinessService, Ens.BusinessOperation) [ Abstract, Inheritance = right, System = 4 ]
{

/// The sessionId if the private session has been established
Property %PrivateSessionId As %Integer;

/// A flag indicates if the private session has been established
Property %InPrivateSession As %Boolean [ Calculated ];

Property EventDevice As %String;

Method OnTask() As %Status
{
	Set $ZT="Trap",$EC="",tSC=$$$OK
	Do {
		If '..%WarnedLatest&&'..%ClassIsLatestVersion() {
			$$$LOGWARNING("Host Class "_$classname()_" has been recompiled; continuing to run using code from previous version")
			Set ..%WarnedLatest=1
		}
		If $IsObject(..Adapter)&&'..Adapter.%WarnedLatest&&'..Adapter.%ClassIsLatestVersion() {
			$$$LOGWARNING("Adapter Class "_$classname(..Adapter)_" has been recompiled; continuing to run using code from previous version")
			Set ..Adapter.%WarnedLatest=1
		}
		$$$ASSERT($IsObject(..Adapter)) ; Must have an Adapter to call OnTask()
		Set tTimeCalled = $ZH
		Set ..%WaitForNextCallInterval=1
		Set tCallInterval = ..Adapter.CallInterval  Set:tCallInterval<1 tCallInterval=1
		If ##class(Ens.Job).ShouldBeQuiescent() {
			$$$sysTRACE("Adapter's OnTask() not called because system is quiescent")
			Set tSC = ##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,-1,,1)
		} Else {
			$$$catTRACE("ontask","calling adapter's OnTask()")
			Set tSC=..Adapter.OnTask()
			Set:'..%WaitForNextCallInterval tNow=$ZH, ..%LastActionTime=tNow, ..%LastHandledTime=tNow
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
				If '..%QuitTask Set tSC=$$$OK $$$catTRACE("ontask","Ignoring error from OnTask()") ; Don't break the OnTask() loop except when %QuitTask is set
			} Else { Set ..%AlertStartTime=0, tTxt="" }
			Set ..%LastReportedError=tTxt
			$$$CLOSEIOLOGENTRY(tSC,"After OnTask",$$$NULLOREF)
			Set ..%RequestHeader=$$$NULLOREF  Kill $$$JobCurrentHeaderId

			#; unlike BusinessService, do not exit if ..%WaitForNextCallInterval=0
			Quit:..%QuitTask
			If ..%WaitForNextCallInterval=0 {
				Set tWait=0,tWaitK=-1,tWaitCall=0
			} else {
				Set tNow=$ZH, tWaitK=-1,(tWait,tWaitCall)=tCallInterval-(tNow-tTimeCalled)
				If ..Adapter.KeepaliveInterval>0&&..%LastActionTime {
					Set tWaitK=..Adapter.KeepaliveInterval  Set:tWaitK<=0 tWaitK=-1
					If tWaitK>0 {
						Set tWaitK=tWaitK-(tNow-..%LastActionTime)  Set:tWaitK<0 tWaitK=0
						Set:tWait>tWaitK tWait=tWaitK, tWaitK=0, tWaitCall=tWaitCall-tWait
					}
				}
				#; wait the shorter of keepalive wait or CallInterval
			}
			If tWait<0 Set tWait=0
DeQueue
			Set tSC = ##class(Ens.Queue).DeQueue(..QueueName(),.tRequestHeader,tWait,.tTimedOut,1) Quit:$$$ISERR(tSC)
			If '$IsObject(tRequestHeader) {
				If 'tWaitK {
					Set tSC=..Adapter.OnKeepalive(), ..%LastActionTime=$ZH  Quit:$$$ISERR(tSC)
					#; if keepalive wait was shorter, wait the rest of CallInterval now.
					If tWaitCall>0 {
						Set tSC = ##class(Ens.Queue).DeQueue(..QueueName(),.tRequestHeader,tWaitCall,.tTimedOut,1) Quit:$$$ISERR(tSC)
						If '$IsObject(tRequestHeader) Quit
					}
				}
				Quit
			}
			If ..%InPrivateSession&&(..%PrivateSessionId'=tRequestHeader.SessionId) {
				$$$sysTRACE("Out-of-band message '"_tRequestHeader.%Id()_"' discarded")
				Do tRequestHeader.SetStatus($$$eMessageStatusDiscarded)
				Quit
			}
			Set tSC=..MessageHeaderHandler(tRequestHeader,.tResponseHeader)
			Set (..%SessionId,$$$JobSessionId)=..%PrivateSessionId
			Set:tWait>=0 tNow=$ZH, ..%LastActionTime=tNow, ..%LastHandledTime=tNow
			If $$$ISERR(tSC),tRequestHeader.ReturnQueueName'="" {
				Set tSC = tRequestHeader.NewErrorResponse(.tResponseHeader,tSC) Quit:$$$ISERR(tSC)
			} Else { Set tSC=$$$OK } ; we don't pass on user errors here.
			If $IsObject($G(tResponseHeader)),tResponseHeader.TargetQueueName'="" {
				Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
			}
			#; if last DeQueue got something, then we immediately go back to DeQueue for a quick (timeout=0) check
			Set tWait=0,tWaitK=-1,tWaitCall=0
			goto DeQueue
		}
	} While 0
Exit
	Kill $$$EnsActiveMessage($$$SystemName_":"_$Job)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method SendRequestAsync(pTargetDispatchName As %String, pRequest As %Library.Persistent, pDescription As %String = "", pResponseRequired As %Boolean = 0) As %Status
{
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tTimeCalled=$ZH
	Set tTargetConfigName = $get($$$DispatchNameToConfigName(pTargetDispatchName))  Quit:""=tTargetConfigName $$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)
	Set tTargetBusinessClass = $$$ConfigClassName(tTargetConfigName)
	Set tSessionId = ..%SessionId
	Set tReturnQueueName=$s(pResponseRequired:..QueueName(),1:"")
	Set:$IsObject(..%RequestHeader)&&(""=..%RequestHeader.TimeCreated) tRequestHeader=..%RequestHeader
	Set tSC=$classmethod(tTargetBusinessClass,"acceptRequestAsync",..%ConfigName,tTargetConfigName,.pRequest,$$$eMessagePriorityAsync,tReturnQueueName,.tSessionId,"",.tRequestHeader,pDescription)
	If $$$ISOK(tSC) {
		Set (..%SessionId,$$$JobSessionId)=tSessionId
		Set ..%RequestHeader=tRequestHeader, $$$JobCurrentHeaderId=tRequestHeader.%Id()
	}
	$$$catTRACE("timing","duration of async call: "_($ZH-tTimeCalled))
	Quit tSC
}

Method SetEventDevice(pDevice = "") As %Status
{
	Set ..EventDevice=pDevice
	Set tSC=##class(Ens.Queue).SetEventDevice(..QueueName(),..EventDevice) Quit:$$$ISERR(tSC) tSC
	Quit $$$OK
}

Method RegisterPrivateSession() As %Status
{
	If ..%InPrivateSession Quit $$$OK
	If ..%SessionId="" Set tSC=..ForceSessionId() Quit:$$$ISERR(tSC) tSC
	Set ..%PrivateSessionId=..%SessionId
	Set tSC = ##class(Ens.Queue).Create(..QueueName()) Quit:$$$ISERR(tSC) tSC
	Set tSC=..Adapter.OpenEventDevice() Quit:$$$ISERR(tSC) tSC
	Set $$$ConfigSessionQueueName(..%ConfigName,..%SessionId)=..QueueName()
	$$$sysTRACE("Registered Private Session '"_..%PrivateSessionId_"'")
	Quit $$$OK
}

Method UnRegisterPrivateSession() As %Status
{
	If '..%InPrivateSession Quit $$$OK
	Kill $$$ConfigSessionQueueName(..%ConfigName,..%PrivateSessionId)
	Set tSC=..Adapter.CloseEventDevice() Quit:$$$ISERR(tSC) tSC
	Set tSC=##class(Ens.Queue).Delete(..QueueName(),"*") Quit:$$$ISERR(tSC) tSC
	$$$sysTRACE("Unregistered Private Session '"_..%PrivateSessionId_"'")
	Set ..%PrivateSessionId=""
	Set ..%SessionId=""
	Kill $$$JobSessionId
	Quit $$$OK
}

Method SetTimer(pTimeout As %String, Output pAlarmHandle As %String, pDescription As %String = "") As %Status
{
	Set tAlarmRequest = ##class(Ens.AlarmRequest).%New()
	$$$ASSERT($IsObject(tAlarmRequest))
	Set tAlarmRequest.Timeout = pTimeout
	Set tSC=tAlarmRequest.%Save() Quit:$$$ISERR(tSC) tSC
	Set pAlarmHandle = tAlarmRequest.%Id()
	Quit ..SendRequestAsync("Ens.Alarm",tAlarmRequest,pDescription,1)
}

Method %InPrivateSessionGet() As %Boolean
{
	Quit ..%PrivateSessionId'=""
}

Method QueueName() As %String
{
	Quit $s(..%InPrivateSession:$$$queueBusinessDuplexQueueName,1:..%ConfigName)
}

ClassMethod OnBusinessType(pItem As Ens.Config.Item) As %Integer
{
	Quit $$$eHostTypeService
}

}
