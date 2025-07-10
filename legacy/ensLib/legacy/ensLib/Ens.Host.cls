/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator Ensemble

/// Common base class for all config item instances
Class Ens.Host Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// 2 modes: Queue, InProc
Parameter INVOCATION = "Queue";

/// Duration of forced idleness before processing the next message, in milliseconds
Property ThrottleDelay As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

/// Send an Alert message whenever an error occurs here
Property AlertOnError As %Boolean [ InitialExpression = 0 ];

/// Send an Alert message if this number of seconds elapses with no messages being processed by this item. <br/>
/// Note that this alert will be sent even if AlertOnError is False. <br/>
/// Zero means no alerts of this type will be sent.
Property InactivityTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

/// Name of a Business Partner Profile associated with this item
Property BusinessPartner As %String(MAXLEN = 128);

/// The Alert Groups to which this item belongs.
Property AlertGroups As %String(MAXLEN = 2500);

/// Users can specify these values in the Configuration Editor
Parameter SETTINGS As %String = "ThrottleDelay,AlertOnError:Alerting,InactivityTimeout:Alerting,BusinessPartner:Info:partnerSelector,AlertGroups:Alerting:selector?multiSelect=1&context={Ens.ContextSearch/ProductionAlertGroups?productionName=@productionId}";

/// Flag for returning an error that will exit the OnTask() loop and terminate the Job
Property %QuitTask As %Integer [ InitialExpression = 0 ];

/// The session id of the current message being processed
Property %SessionId As %Integer;

/// If doing keepalives, the time of the last return from MessageHeaderHandler()
Property %LastHandledTime As %String [ Transient ];

/// If doing keepalives, the time of the last return from MessageHeaderHandler() or OnKeepalive()
Property %LastActionTime As %String [ Transient ];

/// Copy of the text of the last error we reported, so we can avoid alerting more than once
Property %LastReportedError As %String [ Transient ];

/// Flag whether we have already warned about the class being recompiled
Property %WarnedLatest As %Boolean [ InitialExpression = 0, Transient ];

/// Is this a real live instance or a shadow instance used just to hold config settings.
Property %isShadow As %String [ Transient ];

/// The SuperSession id of the current message being processed
Property %SuperSession As %String(MAXLEN = 300);

/// This is to allow a process access to local variable storing Super Session.
/// Similar to how a process has access to $$$JobSessionId.
Method %SuperSessionSet(Arg As %String) As %Status [ ServerOnly = 1 ]
{
	Set i%%SuperSession=Arg
	If Arg = "" {Kill $$$JobSuperSession} Else {Set $$$JobSuperSession=Arg}
	Quit $$$OK
}

Method SendRequestSync(pTargetDispatchName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pTimeout As %Numeric = -1, pDescription As %String = "") As %Status
{
	Quit $$$EnsError($$$NotImplemented)
}

/// Internal method to dispatch multiple business invocation synchronously <br>
/// <parameter>pCallStructList</parameter> is required and is a numbered array with values of
/// <class>Ens.CallStructure</class> and the top node is the count of elements <br>
Method SendRequestSyncMultiple(pCallStructList As %String, pTimeout As %Numeric = -1) As %Status [ Internal ]
{
	set tSC=$$$OK, tResponse=$$$NULLOREF
	try {
		for i=1:1:pCallStructList {
			set tCallStruct=pCallStructList(i)
			set tTargetDispatchName=tCallStruct.TargetDispatchName
			set tTargetConfigName=$get($$$DispatchNameToConfigName(tTargetDispatchName))
			if tTargetConfigName="" set tSC=$$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,tTargetDispatchName) quit
			set tTargetBusinessClass = $$$ConfigClassName(tTargetConfigName)
			set tINVOCATION=$classmethod(tTargetBusinessClass,"%GetParameter","INVOCATION")
			if (tINVOCATION'="Queue")&&(tINVOCATION'="InProc") set tSC=$$$ERROR($$$EnsErrParameterInvocationInvalid,tTargetBusinessClass) quit
			;
			set tArray(i,"TargetConfigName") = tTargetConfigName
			set tArray(i,"TargetBusinessClass") = tTargetBusinessClass
			set tArray(i,"INVOCATION")=tINVOCATION
		}
		quit:$$$ISERR(tSC)
		;
		set tStartTime=$zh,tRespondedCount=0
		set:pTimeout'=-1 tEndTime=$zh+pTimeout
		for i=1:1:pCallStructList {
			if tArray(i,"INVOCATION")="InProc" {
				set tTimeout=$s(pTimeout=-1:-1,1:tEndTime-$zh)
				if (pTimeout'=-1)&&(tTimeout<0) quit
				set tSC=..SendRequestSync(tArray(i,"TargetConfigName"),pCallStructList(i).Request,.tResponse,tTimeout,pCallStructList(i).Description)
				set pCallStructList(i).Response=tResponse
				set tRespondedCount=tRespondedCount+1
			} elseif tArray(i,"INVOCATION")="Queue" {
				Set tSessionId=..%SessionId
				Set tSuperSession = ..%SuperSession
				Set tSC = ##class(Ens.MessageHeader).NewRequestMessage(.tRequestHeader,pCallStructList(i).Request,.tSessionId,.tSuperSession) quit:$$$ISERR(tSC)
				Set ..%SessionId=tSessionId
				Set ..%SuperSession=tSuperSession
				set tArray(i,"RequestHeader")=tRequestHeader
				Set tRequestIndex(tRequestHeader.MessageId()) = i
				Set tRequestHeader.SourceConfigName = ..%ConfigName
				Set tRequestHeader.TargetConfigName = tArray(i,"TargetConfigName")
				Set tRequestHeader.SourceBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(..%ConfigName))
				Set tRequestHeader.TargetBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(tArray(i,"TargetConfigName")))
				Set tRequestHeader.TargetQueueName = $$$getConfigQueueName($$$DispatchNameToConfigName(tArray(i,"TargetConfigName")),..%SessionId)
				Set tRequestHeader.ReturnQueueName = $$$queueSyncCallQueueName
				Set tRequestHeader.BusinessProcessId = ""
				Set tRequestHeader.Priority = $$$eMessagePrioritySync
				Set tRequestHeader.Description = pCallStructList(i).Description
				Set tSC = ##class(Ens.Queue).Create($$$queueSyncCallQueueName) quit:$$$ISERR(tSC)
				Set tSC = ##class(Ens.Queue).EnQueue(tRequestHeader) quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		;
		while tRespondedCount<pCallStructList {
			set tTimeout=$s(pTimeout=-1:-1,1:tEndTime-$zh) if (pTimeout'=-1)&&(tTimeout<0) quit
			set tSC = ##class(Ens.Queue).DeQueue($$$queueSyncCallQueueName,.tResponseHeader,tTimeout,.tIsTimedOut,0) Quit:$$$ISERR(tSC)
			quit:tIsTimedOut 
			continue:$IsObject(tResponseHeader)=0
			set tFound = $select(tResponseHeader.CorrespondingMessageId: $get(tRequestIndex(tResponseHeader.CorrespondingMessageId),0), 1: 0)
			if tFound=0 {
				$$$sysTRACE("Out-of-band message '"_tResponseHeader.%Id()_"' discarded")
				do tResponseHeader.SetStatus($$$eMessageStatusDiscarded)
				continue
			}
			if tResponseHeader.IsError {
				set pCallStructList(tFound).ResponseCode=tResponseHeader.ErrorStatus
				set tRespondedCount=tRespondedCount+1
				do tResponseHeader.SetStatus($$$eMessageStatusCompleted)
				continue
			}
			if tResponseHeader.MessageBodyClassName'="" {
				set tResponse = $classmethod(tResponseHeader.MessageBodyClassName,"%OpenId",tResponseHeader.MessageBodyId,,.tSC)
				if '$IsObject(tResponse) Set tSC=$$$EnsError($$$EnsErrGeneral,"Could not open MessageBody "_tResponseHeader.MessageBodyId_" for MessageHeader #"_tResponseHeader.%Id()_" with body class "_tResponseHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC))  Quit
			} else {
				set tResponse=$$$NULLOREF
			}
			set pCallStructList(tFound).Response=tResponse
			set tRespondedCount=tRespondedCount+1
			do tResponseHeader.SetStatus($$$eMessageStatusCompleted)
			continue
		}
		Set tSC2 = ##class(Ens.Queue).Delete($$$queueSyncCallQueueName,"*") quit:$$$ISERR(tSC2)
		;
		$$$catTRACE("timing","duration of sync call: "_($zh-tStartTime))
		quit
	}
	catch {
		set tSC = $$$EnsSystemError
	}
	quit tSC
}

/// This method is for internal use.
ClassMethod acceptRequestSync(pSourceConfigName As %String, pTargetConfigName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, ByRef pSessionId As %String, pTimeout As %Numeric, ByRef pRequestHeader As Ens.MessageHeader, pDescription As %String = "", ByRef pSuperSession As %String) As %Status [ CodeMode = generator, Internal ]
{
	Set invocation=%parameter("INVOCATION")
	If ( invocation="Queue" ) {
		$$$GENERATE(" Quit ..queueRequestSync(pSourceConfigName,pTargetConfigName,pRequest,.pResponse,.pSessionId,pTimeout,.pRequestHeader,pDescription,.pSuperSession)")
	} Elseif invocation="InProc" {
		$$$GENERATE(" Quit ..inprocRequest(pSourceConfigName,pTargetConfigName,pRequest,.pResponse,"""",.pSessionId,"""",.pRequestHeader,pDescription,,.pSuperSession)")
	} Else {
		Quit $$$ERROR($$$EnsErrParameterInvocationInvalid,%class)
	}
	Quit $$$OK
}

/// This method is for internal use.
ClassMethod acceptRequestAsync(pSourceConfigName As %String, pTargetConfigName As %String, pRequest As Request, pPriority As Ens.DataType.MessagePriority, pReturnQueueName As %String, ByRef pSessionId As %String, pBusinessProcessId As %String, ByRef pRequestHeader As Ens.MessageHeader, pDescription As %String = "", ByRef pSuperSession As %String) As %Status [ CodeMode = generator, Internal ]
{
	Set invocation=%parameter("INVOCATION")
	If ( invocation="Queue" ) {
		$$$GENERATE(" Quit ..queueRequestAsync(pSourceConfigName,pTargetConfigName,pRequest,.pPriority,.pReturnQueueName,.pSessionId,pBusinessProcessId,.pRequestHeader,pDescription,.pSuperSession)")
	} Elseif invocation="InProc" {
		$$$GENERATE(" Quit ..inprocRequest(pSourceConfigName,pTargetConfigName,pRequest,,.pReturnQueueName,.pSessionId,pBusinessProcessId,.pRequestHeader,pDescription,pPriority,.pSuperSession)")
	} Else {
		Quit $$$ERROR($$$EnsErrParameterInvocationInvalid,%class)
	}
	Quit $$$OK
}

/// This method is for internal use.
ClassMethod queueRequestAsync(pSourceConfigName As %String, pTargetConfigName As %String, pRequest As Request, pPriority As Ens.DataType.MessagePriority, pReturnQueueName As %String, ByRef pSessionId As %String, pBusinessProcessId As %String, Output pRequestHeader As Ens.MessageHeader, pDescription As %String = "", ByRef pSuperSession As %String) As %Status [ Internal ]
{
	Set $ZT="Trap", tSC=$$$OK
	Do {
		Set tSC = ##class(Ens.MessageHeader).NewRequestMessage(.pRequestHeader,pRequest,.pSessionId,.pSuperSession) Quit:$$$ISERR(tSC)
		Set pRequestHeader.SourceConfigName = pSourceConfigName
		Set pRequestHeader.TargetConfigName = pTargetConfigName
		Set pRequestHeader.SourceBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(pSourceConfigName))
		Set pRequestHeader.TargetBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(pTargetConfigName))
		Set pRequestHeader.TargetQueueName = $$$getConfigQueueName($$$DispatchNameToConfigName(pTargetConfigName),pSessionId)
		Set pRequestHeader.ReturnQueueName = pReturnQueueName
		Set pRequestHeader.BusinessProcessId = pBusinessProcessId
		Set pRequestHeader.Description = pDescription
		Set pRequestHeader.Priority = pPriority

		Set tSC = ##class(Ens.Queue).EnQueue(pRequestHeader) Quit:$$$ISERR(tSC)
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is for internal use.
ClassMethod queueRequestSync(pSourceConfigName As %String, pTargetConfigName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, ByRef pSessionId As %String, pTimeout As %Numeric, Output pRequestHeader As Ens.MessageHeader, pDescription As %String = "", ByRef pSuperSession As %String) As %Status [ Internal ]
{
	Set $ZT="Trap", tSC=$$$OK, pResponse=$$$NULLOREF
	Do {
		Set tSC = ##class(Ens.MessageHeader).NewRequestMessage(.pRequestHeader,pRequest,.pSessionId,.pSuperSession)
		If $$$ISOK(tSC) {
			Set pRequestHeader.SourceConfigName = pSourceConfigName
			Set pRequestHeader.TargetConfigName = pTargetConfigName
			Set pRequestHeader.SourceBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(pSourceConfigName))
			Set pRequestHeader.TargetBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(pTargetConfigName))
			Set pRequestHeader.TargetQueueName = $$$getConfigQueueName($$$DispatchNameToConfigName(pTargetConfigName),pSessionId)
			Set pRequestHeader.ReturnQueueName = $$$queueSyncCallQueueName
			Set pRequestHeader.BusinessProcessId = ""
			Set pRequestHeader.Priority = $S($G(pRequestHeader("SyncHandling","UseSimSync")):$$$eMessagePrioritySimSync, 1:$$$eMessagePrioritySync)
			Set pRequestHeader.Description = pDescription

			Set tSC = ##class(Ens.Queue).Create($$$queueSyncCallQueueName)
			If $$$ISOK(tSC) {
				Set tSC = ##class(Ens.Queue).EnQueue(pRequestHeader)
				If $$$ISERR(tSC) {
					Set tSC2 = ##class(Ens.Queue).Delete($$$queueSyncCallQueueName,"*")
					If $$$ISERR(tSC2) Set tSC = $$$ADDSC(tSC,tSC2)
					Quit
				}
			} Else {
				Quit
			}
		} Else {
			Quit	
		}
		While 1 {
			/*
				The Minimum extra processing added to all queueRequestSync calls to add optional delayed sync handling:
					Add $data call with #2
					Change Set to conditional Set

			*/
			/* If the client may disconnect before response is created then save information to allow retry to recover  response */
			If $Data(pRequestHeader("SyncHandling","ResponseWaitTimeoutToUse"),tClientWaitTimeout)#2 && $Data(pRequestHeader("SyncHandling","ClientRequestKey"),tClientRequestKey)#2 {
				If (tClientWaitTimeout>0) && ((pTimeout=-1)||(tClientWaitTimeout<pTimeout)) {
					Set tSC = ##class(Ens.Queue).DeQueue($$$queueSyncCallQueueName,.tResponseHeader,tClientWaitTimeout,.tIsTimedOut,0) Quit:$$$ISERR(tSC)
					If tIsTimedOut {
						If (tClientWaitTimeout<pTimeout) {
							Set pTimeout=pTimeout-tClientWaitTimeout
						} ElseIf (tClientWaitTimeout=pTimeout) {
							#; Chance that pTimeout not -1 and was equal to tClientWaitTimeout set to 1 for second call below
							Set pTimeout = 1
						} /* else leave at -1 */
						Set tXREFClientRequest = ..createDelayedRequestXREFOref(tClientRequestKey,pRequestHeader,,,.tXREFSC)
						If $$$ISERR(tXREFSC) $$$LOGERROR("Unexpected error encountered trying to create Delayed Request XREF "_$System.Status.GetErrorText(tXREFSC))
					}
				}
			} Else {
				#; safety clean
				Kill tIsTimedOut
			}
			/* Using tIsTimedOut test to see if called DeQueue already for sync delay handling*/
			Set:($Get(tIsTimedOut,1)) tSC = ##class(Ens.Queue).DeQueue($$$queueSyncCallQueueName,.tResponseHeader,pTimeout,.tIsTimedOut,0) Quit:$$$ISERR(tSC)

			Quit:tIsTimedOut 
			Continue:$IsObject(tResponseHeader)=0

			If $$$IsdefObject(tXREFClientRequest) {
				Set tXREFClientRequest = ..completeDelayedRequestXREFOref(tXREFClientRequest,/*no end time since queued*/,tResponseHeader,.tXREFSC)
				If $$$ISERR(tXREFSC) $$$LOGERROR("Unexpected error encountered trying to update Delayed Request XREF "_$System.Status.GetErrorText(tXREFSC))
			}

			If tResponseHeader.CorrespondingMessageId=pRequestHeader.%Id() {
				If tResponseHeader.IsError {
					Set tSC=tResponseHeader.ErrorStatus
					Do tResponseHeader.SetStatus($$$eMessageStatusCompleted)
					Quit
				}
				If tResponseHeader.MessageBodyClassName'="" {
					Set pResponse = $classmethod(tResponseHeader.MessageBodyClassName,"%OpenId",tResponseHeader.MessageBodyId,,.tSC)
					If '$IsObject(pResponse) Set tSC=$$$EnsError($$$EnsErrGeneral,"Could not open MessageBody "_tResponseHeader.MessageBodyId_" for MessageHeader #"_tResponseHeader.%Id()_" with body class "_tResponseHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC)) Quit
				}
				Do tResponseHeader.SetStatus($$$eMessageStatusCompleted)
				Quit
			}
			$$$sysTRACE("Out-of-band message '"_tResponseHeader.%Id()_"' discarded")
			Do tResponseHeader.SetStatus($$$eMessageStatusDiscarded)
		}
		Set tSC2 = ##class(Ens.Queue).Delete($$$queueSyncCallQueueName,"*")  Quit:$$$ISERR(tSC2)
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is for internal use.
ClassMethod inprocRequest(pSourceConfigName As %String, pTargetConfigName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pReturnQueueName As %String, ByRef pSessionId As %String, pBusinessProcessId As %String, ByRef pRequestHeader As Ens.MessageHeader, pDescription As %String = "", pPriority As Ens.DataType.MessagePriority = {$$$eMessagePrioritySync}, ByRef pSuperSession As %String) As %Status [ Internal ]
{
	Set $ZT="Trap", tSC=$$$OK, pResponse=$$$NULLOREF
	Do {
		Set tSC=..findCachedObject(pTargetConfigName,.tInstance) Quit:$$$ISERR(tSC)
		$$$ASSERT($IsObject(tInstance))
		
		If $G($$$EnsInProcPersist,1) {
			Set tSC = ##class(Ens.MessageHeader).NewRequestMessage(.pRequestHeader,pRequest,.pSessionId,.pSuperSession) Quit:$$$ISERR(tSC)
			Set pRequestHeader.SourceConfigName = pSourceConfigName
			Set pRequestHeader.TargetConfigName = pTargetConfigName
			Set pRequestHeader.SourceBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(pSourceConfigName))
			Set pRequestHeader.TargetBusinessType = $$$ConfigBusinessType($$$DispatchNameToConfigName(pTargetConfigName))
			Set pRequestHeader.TargetQueueName = ""
			Set pRequestHeader.ReturnQueueName = pReturnQueueName
			Set pRequestHeader.BusinessProcessId = pBusinessProcessId
			Set pRequestHeader.Priority = pPriority
			Set pRequestHeader.Invocation = $$$eMessageInvocationInProc
			Set pRequestHeader.Description = pDescription

			Set tSC=pRequestHeader.%Save() If $$$ISERR(tSC) $$$LOGSTATUS(tSC) Quit

			/*	Check for support of delayed sync handling for client disconnect and retry
				Same as in Ens.BusinessProcess:inprocRequest()
			*/
			If $Data(pRequestHeader("SyncHandling","ResponseWaitTimeoutToUse"),tClientWaitTimeout)#2 && $Data(pRequestHeader("SyncHandling","ClientRequestKey"),tClientRequestKey)#2 {
				Set tXREFClientRequest = ..createDelayedRequestXREFOref(tClientRequestKey,pRequestHeader,tClientWaitTimeout,.tZHClientWaitTimeout,.tXREFSC)
				If $$$ISERR(tXREFSC) {
					#; ensure identifier var for delayed sync handling removed
					Kill tZHClientWaitTimeout
					$$$LOGERROR("Proceeding without optional delayed SyncRequest handling due to unexpected error encountered trying to create Delayed Request XREF "_$System.Status.GetErrorText(tXREFSC))
				}
			}
			Set tSC = tInstance.MessageHeaderHandler(pRequestHeader,.tResponseHeader) Quit:$$$ISERR(tSC)
			If $IsObject(tResponseHeader) {
				If tResponseHeader.TargetQueueName'="" {
					Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
				} Else {
					Set tSC=tResponseHeader.%Save()  If $$$ISERR(tSC) $$$LOGSTATUS(tSC) Quit
					If tResponseHeader.MessageBodyClassName'="" {
						Set pResponse = $classmethod(tResponseHeader.MessageBodyClassName,"%OpenId",tResponseHeader.MessageBodyId,,.tSC)
						If '$IsObject(pResponse) Set tSC=$$$EnsError($$$EnsErrGeneral,"Could not open MessageBody "_tResponseHeader.MessageBodyId_" for MessageHeader #"_tResponseHeader.%Id()_" with body class "_tResponseHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC))  Quit
					}
					Do tResponseHeader.SetStatus($$$eMessageStatusCompleted)
				}
			} Else {
				Set pResponse=$$$NULLOREF
			}
			#; Client response timeout handling
			If $Data(tZHClientWaitTimeout) {
				Set tXREFClientRequest = ..completeDelayedRequestXREFOref(tXREFClientRequest,tZHClientWaitTimeout,tResponseHeader,.tXREFSC)
				If $$$ISERR(tXREFSC) $$$LOGERROR("Unexpected error encountered trying to update Delayed Request XREF "_$System.Status.GetErrorText(tXREFSC))
			}

		} Else {
			/* Not supporting XREF delayed for non persistence */
			Set tSC = tInstance.OnMessage(pRequest, .pResponse)
			$$$IncHostCounterTime(pTargetConfigName)
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is for internal use.
ClassMethod findCachedObject(pTargetConfigName As %String, Output pInstance As Ens.Host) As %Status [ Internal ]
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set pInstance=$g($$$staticCachedObject(pTargetConfigName))
		Set pChecksum=$g($$$staticCachedChecksum(pTargetConfigName))
		If $IsObject(pInstance),pChecksum=$$$ConfigChecksum($$$DispatchNameToConfigName(pTargetConfigName)) Quit
		Set pInstance=..%New($$$DispatchNameToConfigName(pTargetConfigName))
		Set pChecksum=$$$ConfigChecksum($$$DispatchNameToConfigName(pTargetConfigName))
		$$$ASSERT($IsObject(pInstance))
		Set $$$staticCachedObject(pTargetConfigName)=pInstance
		Set $$$staticCachedChecksum(pTargetConfigName)=pChecksum
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// initialize Business Host object
Method %OnNew(pConfigName As %String) As %Status
{
	Quit $method($this,"initConfig",.pConfigName) ; call subclass
}

/// initialize Business Host object
Method initConfig(pConfigName As %String) As %Status [ Internal ]
{
	Set $ZT="Trap"
	#dim tSC As %Status = $$$OK
	#dim tSettingName As %String
	#dim tValue

	Do {
		Set ..%ConfigName = pConfigName
		Set ..%ConfigQueueName = $G($$$ConfigQueueName(pConfigName))
		If ..#ADAPTER'="" {
			Set ..Adapter = $classmethod(..#ADAPTER,"%New")
			Set ..Adapter.BusinessHost = $this
		}
		/* 
			If we were called via GetShadowInstance and the production is not running
			then we avoided setting the Ens.Runtime global and no need for configname.
			'$G(%DoShadowNew) if not GetShadowInstance.
			%DoShadowNew = 1 and $D(%DoShadowNew)=1 if GetShadowInstance and believe Production running.
			%DoShadowNew = 1 and $D(%DoShadowNew)=11 if GetShadowInstance and Production not running,
		*/
		If $G(%DoShadowNew) && ($D(%DoShadowNew)=11) {
			If ..Adapter'=$$$NULLOREF {
				Set tSettingName="" For { Set tSettingName=$O(%DoShadowNew("Adapter",tSettingName),1,tValue)  Quit:""=tSettingName
					Do ..Adapter.AssignOneSetting(tSettingName,tValue,pConfigName)
				}
			}
			Set tSettingName="" For { Set tSettingName=$O(%DoShadowNew("Host",tSettingName),1,tValue)  Quit:""=tSettingName
				Do $this.AssignOneSetting(tSettingName,tValue,pConfigName)
			}		
		} Else {
			If ..Adapter'=$$$NULLOREF {
				Set tSettingName="" For { Set tSettingName=$O($$$ConfigSetting(pConfigName,"Adapter",tSettingName),1,tValue)  Quit:""=tSettingName
					Do ..Adapter.AssignOneSetting(tSettingName,tValue,pConfigName)
				}
			}
			Set tSettingName="" For { Set tSettingName=$O($$$ConfigSetting(pConfigName,"Host",tSettingName),1,tValue)  Quit:""=tSettingName
				Do $this.AssignOneSetting(tSettingName,tValue,pConfigName)
			}
		}
	} While 0
	Set ..%isShadow=$G(%DoShadowNew)||'$D($$$ConfigOnTaskClassName(pConfigName))
	Quit:$$$ISERR(tSC)||..%isShadow tSC ; no OnInit() for Shadow instances
	Set tSC = ..OnInit() Quit:$$$ISERR(tSC) tSC
	If $IsObject(..Adapter) Set tSC = ..Adapter.OnInit() Quit:$$$ISERR(tSC) tSC
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method %OnClose() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tNS As %String
	If '..%isShadow {
		Try { 
			If $Namespace'=..%OriginalNamespace() {
				Set tNS=$Namespace
				ZN ..%OriginalNamespace()
			}
		} Catch ex {
			//cannot change namespace (removed or network unavailable)
			If ex.Name="<NAMESPACE>" Return $$$OK
			Return ex.AsStatus()
		}
		Try { If $IsObject(..Adapter) Set tSC = ..Adapter.OnTearDown()
		} Catch e { Set tSC = e.AsStatus() }
		If $$$ISOK(tSC) {
			Set tSC = ..OnTearDown()
		} Else {
			/* test if tSC in error due to UNDEFINED ..Adapter from failure to %Open*/
			Try { If ..Adapter="" } Catch { Set tSC = $$$OK }
		}
		If $Data(tNS) ZN tNS
	}
	Quit tSC
}

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	Quit $$$OK
}

/// This user callback method is called from %OnClose()
Method OnTearDown() As %Status
{
	Quit $$$OK
}

/// This user callback method is called when the system is being started
ClassMethod OnProductionStart(pConfigName As %String) As %Status
{
	Quit $$$OK
}

/// This user callback method is called when the system is being stopped
ClassMethod OnProductionStop(pConfigName As %String) As %Status
{
	Quit $$$OK
}

/// This user callback method is called by the Monitor Service
/// (<class>Ens.MonitorService</class>) immediately after it has checked
/// on the status of this host class.
ClassMethod OnMonitor(pHostName As %String) As %Status
{
	Quit $$$OK
}

/// Event loop for Actor and BusinessOperation.
/// This is called only when INVOCATION is Queue.
Method OnTask() As %Status [ Internal ]
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		If '..%WarnedLatest&&'..%ClassIsLatestVersion() {
			$$$LOGWARNING("Host Class "_$classname()_" has been recompiled; continuing to run using code from previous version")
			Set ..%WarnedLatest=1
		}
		If $IsObject(..Adapter)&&'..Adapter.%WarnedLatest&&'..Adapter.%ClassIsLatestVersion() {
			$$$LOGWARNING("Adapter Class "_$classname(..Adapter)_" has been recompiled; continuing to run using code from previous version")
			Set ..Adapter.%WarnedLatest=1
		}
		If ..ThrottleDelay>0 {
			Set tRemaining=..ThrottleDelay/1000, t0=$ZH, tSBQ=0
			$$$catTRACE("ontask","hanging for "_(..ThrottleDelay/1000)_" ThrottleDelay seconds")
			While tRemaining>0&&'tSBQ {
				If tRemaining<5 { Hang tRemaining  Set tRemaining=0 }
				Else {
					Hang 5  Set tNow=$ZH, tRemaining = t0+tRemaining-tNow, t0=tNow
					Set tSBQ=##class(Ens.Job).ShouldBeQuiescent()
				}
			}
		}
		#; Calculate keepalive wait time
		If $IsObject(..Adapter) {
			Set tWait=..Adapter.KeepaliveInterval
			If tWait>0 {
				Set:..%LastActionTime tNow=$ZH, tWait=$S(tNow-..%LastActionTime>=tWait:0, 1:tWait-(tNow-..%LastActionTime))
			} Else { Set tWait=-1 }
		} Else { Set tWait=-1 }
		Set tSC = ##class(Ens.Queue).DeQueue(..QueueName(),.tRequestHeader,tWait,.tTimedOut,1) Quit:$$$ISERR(tSC)
		If '$IsObject(tRequestHeader) {
			If tWait>=0&&tTimedOut {
				Set $EC="" try {
					Set tSC=..Adapter.OnKeepalive()
				} catch {
					Set tSC=$$$ADDSC(tSC,$$$SystemError)
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after Adapter.OnKeepalive(); committing before proceeding")
				Set ..%LastActionTime=$ZH
				If $$$ISERR(tSC) $$$LOGWARNING("OnKeepalive() returned "_$$$StatusDisplayString(tSC)) Set tSC=$$$OK
			}
			Quit
		}
		Set tSC=..MessageHeaderHandler(tRequestHeader,.tResponseHeader)
		Set:tWait>=0 tNow=$ZH, ..%LastActionTime=tNow, ..%LastHandledTime=tNow
		If $$$ISERR(tSC),tRequestHeader.ReturnQueueName'="" {
			Set tSC = tRequestHeader.NewErrorResponse(.tResponseHeader,tSC) Quit:$$$ISERR(tSC)
		} Else { Set tSC=$$$OK } ; we don't pass on user errors here.
		If $IsObject($G(tResponseHeader)),tResponseHeader.TargetQueueName'="" {
			Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
		}
	} While 0
Exit
	Kill $$$EnsActiveMessage($$$SystemName_":"_$Job)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method will be called within KeepaliveInterval of the last return from OnTask() or OnKeepalive().
/// It is called via the Adapter's OnKeepalive() method, which is called from the Host.OnTask() method;
/// if there is no Adapter there is no keepalive call.
Method OnKeepalive(pAdapterStatus As %Status) As %Status
{
	Quit pAdapterStatus
}

Method GetDeferredResponseToken(pMessageHeader As Ens.MessageHeader) As %String
{
	Quit pMessageHeader.%Id()_"|"_$$$EnsRuntime("Name")
}

/// Generate a key for the message header id.
/// Maximum length is determined by Ens.Temp.XREF.DelayedClientRequest property ClientRequestKey. (128)
Method GetMsgHdrRequestKey(pMessageHeaderId As %String, pHash As %Boolean = 0) As %String
{
	/* Use InstanceGUID rather than ##class(%SYS.System).GetUniqueInstanceName()
		InstanceGUID() returns ^|"%SYS"|SYS("INSTANCEGUID") which is set when first called to $system.Util.CreateGUID()
		GetUniqueInstanceName() parses network name info and appends instance name.
	*/
	Set tKey = (pMessageHeaderId_"|"_$$$EnsRuntime("Name")_"|"_$NAMESPACE_"|"_##class(%SYS.System).InstanceGUID())
	If pHash Return $system.Encryption.Base64Encode($system.Encryption.SHA1Hash(tKey))
	Return tKey
}

ClassMethod SendDeferredResponse(pDeferredResponseToken As %String, pResponse As %Library.Persistent) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tMessageHeaderId=$p(pDeferredResponseToken,"|",1)
		Set tProductionName=$p(pDeferredResponseToken,"|",2)
		Set tCurrentProduction=$g($$$EnsRuntime("Name")) 
		If (tCurrentProduction = "") || '##class(Ens.Director).IsProductionRunning() {
			Set tSC=$$$EnsError($$$EnsErrProductionNotRunning)
			Quit
		}
		If (tProductionName '= tCurrentProduction) {
			Set tSC=$$$EnsError($$$EnsErrProductionMismatchInDeferredResponse)
			Quit
		}
		Set tRequestHeader=##Class(Ens.MessageHeader).%OpenId(tMessageHeaderId,,.tSC) Quit:$$$ISERR(tSC)
		$$$ASSERT($IsObject(tRequestHeader))
		If ""=tRequestHeader.ReturnQueueName {
			$$$LOGWARNING("No Return Queue - Unable to send deferred Response to Request "_tRequestHeader.%Id())
		} Else {
			Set tSC = tRequestHeader.NewResponseMessage(.tResponseHeader,pResponse,$G($$$JobSuperSession)) Quit:$$$ISERR(tSC)
			$$$sysTRACE("Sending deferred Response "_tResponseHeader.MessageId()_" to Request "_tRequestHeader.%Id())
			Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
		}
		Do tRequestHeader.SetStatus($$$eMessageStatusCompleted)
	}
	Catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

Method MessageHeaderHandler(pRequestHeader As Ens.MessageHeader, Output pResponseHeader As Ens.MessageHeader) As %Status [ Internal ]
{
	#; subclass responsibility
	Quit $$$ERROR($$$NotImplemented)
}

Method QueueName() As %String [ CodeMode = generator ]
{
	Set invocation=%parameter("INVOCATION")
	If ( invocation="Queue" ) {
		$$$GENERATE(" Quit ..%ConfigQueueName")
	} Elseif invocation="InProc" {
		$$$GENERATE(" Quit ..%ConfigQueueName_"":""_$Job")
	} Else {
		Quit $$$ERROR($$$EnsErrParameterInvocationInvalid,%class)
	}
	Quit $$$OK
}

/// The type of adapter used to communicate with external systems
Parameter ADAPTER;

/// The adapter instance
Property Adapter As Ens.Adapter;

ClassMethod AdapterName() As %String
{
	Quit ..#ADAPTER
}

/// return the name of queue as returned by the config item
Property %ConfigQueueName As %String(MAXLEN = 128);

/// return the name of config item
Property %ConfigName As %String(MAXLEN = 128);

/// 	
/// <p>Get a "shadow" instance of the named ConfigItem, live if the Production is running; otherwise static but fully populated with all its Settings values.</p>
/// <p>The pConfigItemName argument may contain the following elements:</p>
/// <p>ProductionName||ConfigName|CommentOrClassname</p>
/// <p>Only the ConfigName portion is required.
/// If ProductionName is not given, then the currently running or last run Production will be used.
/// CommentOrClassname is the name shown in the Config page's dropdown list for multiple items having the
/// same ConfigName. If it is not given, then if more than one item of the given ConfigName exists, all will match.</p>
/// <p>In order for this method to work properly, none of the names of the items in your production should 
/// contain the '|' character.</p>
/// 
ClassMethod GetShadowInstance(pConfigItemName As %String, Output pStatus As %Status) As Ens.Host
{
	Set pStatus=$$$OK, $ZT="NewTrap"
	
	#dim tHost As Ens.Host = $$$NULLOREF
	#dim tConfigObj As Ens.Config.Item  = $$$NULLOREF
	#dim tSetting As Ens.Config.Setting = $$$NULLOREF
	#dim tCommentOrClass As %String
	#dim tIndex As %Integer
	/*
		This is used to tell initConfig() that the host item instance is a shadow instance.
		It also stores the item settings to be used by initConfig if the production is not running.
	*/
	Kill %DoShadowNew
	
	Do ##class(Ens.Director).ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	If ""=tItemName Set pStatus=$$$ERROR($$$EnsErrGeneral,"Cannot open unnamed item from spec '"_pConfigItemName_"'")  Quit $$$NULLOREF
 	If $Case($ZCVT($ZStrip(tProductionName,"*W"),"L"),"class":1,"":1,:0)&&(""=tCommentOrClass) {
		#; No Production; try opening Raw class
		Set %DoShadowNew=1
		Set tHost=$classmethod(tItemName,"%New",0)
NewContinue
		Kill %DoShadowNew
		If '$IsObject(tHost) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Unable to instantiate class '"_tItemName_"'")
		Quit tHost
	}
	If ""'=$G($$$EnsRuntime("Name"))&&(tProductionName'=$$$EnsRuntime("Name")) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Cannot get instance of item "_pConfigItemName_" while production "_$$$EnsRuntime("Name")_" is running")  Quit $$$NULLOREF

	Lock +$$$ConfigRoot(tItemName)
	Set $ZT="Trap"
	#; If running production, get the running item
	If $D($$$ConfigRoot(tItemName)) {
		Set %DoShadowNew=1
		Set pStatus=$classmethod($$$ConfigClassName(tItemName),"findCachedObject",tItemName,.tHost)
		Kill %DoShadowNew
		Lock -$$$ConfigRoot(tItemName)
		Quit tHost
	}
	&sql(select ID,ClassName into :tID,:tClassname from Ens_Config.Item
			Where Production=:tProductionName and Name=:tItemName
			Order By Enabled desc)
	Set tConfigObj=$S(SQLCODE=0:##class(Ens.Config.Item).%OpenId(tID),1:$$$NULLOREF)
	If '$IsObject(tConfigObj) {
		Lock -$$$ConfigRoot(tItemName)
		Set pStatus=$$$ERROR($$$EnsErrGeneral,"No Config Item found for '"_pConfigItemName_"'in Production '"_tProductionName_"'"_$S(SQLCODE=0:"",1:" ; SQLCODE="_SQLCODE))
		Quit tHost
	}
	#; PopulateModifiedSettings() always returns $$$OK
	Do tConfigObj.PopulateModifiedSettings()
	#; %DoShadowNew is used by Ens.Host::initConfig() similar to $$$ConfigSetting to avoid setting a global if production is not running
	Set tIndex="" For { Set tIndex = tConfigObj.ModifiedSettings.Next(tIndex)  Quit:tIndex=""
		Set tSetting = tConfigObj.ModifiedSettings.GetAt(tIndex)
		Set %DoShadowNew(tSetting.Target,tSetting.Name)=tSetting.Value
	}
	Set %DoShadowNew=1
	Set tHost=$classmethod(tClassname,"%New",tItemName)
	Kill %DoShadowNew
	Lock -$$$ConfigRoot(tItemName)
	Set:'$IsObject(tHost) pStatus=$$$ERROR($$$EnsErrGeneral,"Could not create Config Item for "_tProductionName_":"_tItemName)
Exit
	Quit tHost
Trap
	Set $ZT="",pStatus=$$$SystemError
	Kill %DoShadowNew
	Lock -$$$ConfigRoot(tItemName)
	Set tHost = $$$NULLOREF
	Goto Exit
NewTrap
	Set $ZT="",tSC=$$$SystemError
	Goto NewContinue
}

Method GetProductionSettingValue(pName As %String, Output pStatus As %Status) As %String [ CodeMode = expression ]
{
##class(Ens.Director).GetCurrProductionSettingValue(.pName,.pStatus)
}

Method GetProductionSettings(Output pSettings) As %Status [ CodeMode = expression ]
{
##class(Ens.Director).GetCurrProductionSettings(.pSettings)
}

/// This method is called when Portal is drawing the production diagram
/// pArray contains the config names the scanner found.
/// Users can remove or add new names
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ..GetPropertyConnections(.pArray,pItem)
	Quit
}

/// Helper method for OnGetConnections
ClassMethod GetPropertyConnections(Output pArray As %String, pItem As Ens.Config.Item) [ CodeMode = generator ]
{
	Set tProperty = ""  For { Set tProperty = $$$comMemberNext(%class,$$$cCLASSproperty,tProperty)  Quit:""=tProperty
		// Look for datatypes that are of type Ens.DataType.ConfigName, or a subclass
		$$$comMemberKeyGetLvar(tRuntimeType,%class,$$$cCLASSproperty,tProperty,$$$cPROPruntimetype)
		If ($$$getClassType(tRuntimeType)=$$$cCLASSCLASSTYPEDATATYPE)
		 && ((tRuntimeType="Ens.DataType.ConfigName") || $$IsDerivedFrom^%occLibrary(tRuntimeType,"Ens.DataType.ConfigName")) {
			$$$GENERATE("	If pItem.GetModifiedSetting("""_tProperty_""",.tValue) Do:tValue'="""" ..makeConnections(tValue,.pArray,"""_tRuntimeType_""")")
		}
	}
	$$$GENERATE("	If pItem.GetModifiedSetting(""AlertOnError"",.tValue),+tValue { Set pArray(""Ens.Alert"")="""" }")
	$$$GENERATE("	ElseIf pItem.GetModifiedSetting(""AlertOnError"",.tValue) { Kill pArray(""Ens.Alert"") }")
	$$$GENERATE("	Quit")
	Quit $$$OK
}

/// Helper method for OnGetConnections
ClassMethod makeConnections(pConfigNames As Ens.DataType.ConfigName, ByRef pArray, pConfigNameType As %String = "Ens.DataType.ConfigName") [ Internal ]
{
	For i=1:1:$L(pConfigNames,",") {
		Set tConfigName = $ZStrip($P(pConfigNames,",",i),"<>W")

		// For ConfigNames that use template replacement, don't include them unless it's a canonical value
		Continue:pConfigNameType="Ens.DataType.ConfigNameTemplate"&&'##class(Ens.DataType.ConfigNameTemplate).IsCanonical(tConfigName)

		Set:tConfigName'="" pArray(tConfigName)=""
	}
}

ClassMethod GetRequestClassList() As %String [ Internal ]
{
	#; subclass responsibility
	Quit ""
}

ClassMethod GetResponseClassList(pRequest As %String) As %String [ Internal ]
{
	#; subclass responsibility
	Quit ""
}

/// This method will generate a super session ID<br>
Method GenerateSuperSession(pMessageHeader As Ens.MessageHeader = {$$$NULLOREF}, Output pSC As %Status = {$$$OK}, pDelimiter As %String = "^") As %String
{
	#dim tSuperSession As %String = ""
	#dim tSessionId As %String = ..%SessionId
	#dim err As %Exception.AbstractException
	
	#; Generate SuperSession Id
	Try {

		#;Invoke user defined call back method.
		#;Does not enforce having %SessionId already defined.
		Set tSuperSession = ..OnGenerateSuperSession(pMessageHeader,.pSC,pDelimiter)
		
		#;If an error returned or non empty Super Session return
		If $$$ISERR(pSC)||(tSuperSession'="") Quit

		#; If we don't have a session id at the moment look at the message header but do not force
		If (..%SessionId = "") && $IsObject(pMessageHeader) {
			Try {
				Set tSessionId = pMessageHeader.SessionId
			} Catch {}
		}
		#; Generate SuperSession if we have a SessionId 
		#;Backwards compatible generation of: $zu(110)_"^"_$p($zu(86),"*",2)_"^"_$ZNSPACE_"^"_..BusinessHost.%SessionId
		Set:(tSessionId'="") tSuperSession = ##class(%SYS.System).GetNodeName()_
							pDelimiter_##class(%SYS.System).GetInstanceName()_
							pDelimiter_$NAMESPACE_
							pDelimiter_tSessionId
	} Catch err {
		Set pSC = err.AsStatus()
	}
	
	Quit tSuperSession
}

/// User call back to override creation of Super Session value.<br>
/// Return a non empty string from this method to use as the Super Session ID.<br>
/// Any code needs to ensure the length of the string returned is not more than the MAXLEN of <PROPERTY>%SuperSession</PROPERTY> <br>
/// If Empty string is returned the system will create one in GenerateSuperSession.<br>
/// pMessageHeader may be populated when this is called.<br>
/// The default of pDelimiter passed in is a ^
Method OnGenerateSuperSession(pMessageHeader As Ens.MessageHeader = {$$$NULLOREF}, Output pSC As %Status = {$$$OK}, pDelimiter As %String) As %String
{
	Quit ""
}

ClassMethod createDelayedRequestXREFOref(pClientRequestKey As %String, pRequestHeader As Ens.MessageHeader, pClientWaitTimeout As %Integer = 10, Output pZHClientWaitTimeout As %Double, Output pXREFSC As %Status = {$$$OK}) As Ens.Temp.XREF.DelayedClientRequest [ Internal ]
{
	Set tXREFClientRequest = ##class(Ens.Temp.XREF.DelayedClientRequest).%New()

	Set tXREFClientRequest.ClientRequestKey = pClientRequestKey
	Set tXREFClientRequest.RequestHeader = pRequestHeader
	Set pXREFSC = tXREFClientRequest.%Save()
	If $$$ISERR(pXREFSC) {
		Set tXREFClientRequest = ""
	} Else {
		#;Re-open with exclusive access to ensure we prevent another process trying to take exclusive access
		Set tXREFClientRequest = ##class(Ens.Temp.XREF.DelayedClientRequest).%OpenId(pClientRequestKey,4,.pXREFSC)
		If $$$ISERR(pXREFSC) {
			Set tXREFClientRequest = ""
		} Else {
			Set pZHClientWaitTimeout = $ZH+pClientWaitTimeout
		}
	}

	Return tXREFClientRequest
}

ClassMethod completeDelayedRequestXREFOref(pXREFClientRequest As Ens.Temp.XREF.DelayedClientRequest, pZHClientWaitTimeout As %Double = 0, pResponseHeader As Ens.MessageHeader, Output pXREFSC As %Status = {$$$OK}) As %String [ Internal ]
{
	If 'pZHClientWaitTimeout||($ZH>pZHClientWaitTimeout) {
		#; When queued pZHClientWaitTimeout is 0, when inProc it is defined to help indicate if Client could have disconnected
		If $$$IsdefObject(pXREFClientRequest) {
			Set pXREFClientRequest.ResponseHeader = pResponseHeader
			Set pXREFSC = pXREFClientRequest.%Save()
		}
	} Else {
		#; InProc Client not expected to have disconnected. Cleanup
		Set pXREFSC =  ##class(Ens.Temp.XREF.DelayedClientRequest).%DeleteId(pXREFClientRequest.%Id())
	}

	Return $$$NULLOREF
}

}
