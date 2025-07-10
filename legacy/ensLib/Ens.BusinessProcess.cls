/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

Class Ens.BusinessProcess Extends (%Persistent, Ens.Host, Ens.Settings) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// <p>A comma-separated list of codes specifying what action this Process will take on various reply status conditions.
/// The format of the list is: <br /> &lt;code&gt;=&lt;actions&gt;,(&lt;code&gt;,&lt;code&gt;)=&lt;actions&gt;,...<br/>
/// Types of reply status condition are identified by a specification code:
/// <ul style="list-style-type: none;">
/// <li><b>E</b> - Error status returned from message handler</li>
/// <li><b>E#&lt;statuscode&gt;</b> - Error status returned from message handler has status code equal to &lt;statuscode&gt;</li>
/// <li><b>E*&lt;text&gt;</b> - Error status returned from message handler contains text string &lt;text&gt;</li>
/// <li><b>X</b> - there is no reply message at all</li>
/// </ul></p>
/// <p>The following values for &lt;actions&gt; may be used alone or in combinations:
/// <ul style="list-style-type: none;">
/// <li><b>C</b> - Treat the message as Completed OK.</li>
/// <li><b>W</b> - Log a warning. If no other non-warning &lt;actions&gt; are triggered, the message will be treated as Completed OK.</li>
/// <li><b>R</b> - Retry the message according to the configured RetryInterval and FailureTimeout; finally Fail unless a 
/// different action is also specified. Note this setting is separate from the Retry property.</li>
/// <li><b>S</b> - Suspend the message, log an error, and move on to try the next message.</li>
/// <li><b>D</b> - Disable the Process, log an error and restore the original incoming message to the front of the Process's queue.</li>
/// <li><b>F</b> - Fail with an error and move on to try the next message from the Process's queue subject to the <property>Retry</property>
/// property value set in the code. If the Retry property is set in the code then moving on to try the next message will be subject to 
/// the configured RetryInterval and FailureTimeout.</li></ul>
/// <b>NOTE:</b> the D action can only immediately stop all instances of a Business Process if the BP is configured with PoolSize=1.
/// If PoolSize=0 this action will disable all Business Processes that share the Actor pool.</p>
/// <p>An example of a valid ReplyCodeActions specification is 'E#6301=R,E#&lt;Ens&gt;ErrGeneral=RD,E=F'. This specification will result in a 
/// retry when error code 6301 is encountered. When error code &lt;Ens&gt;ErrGeneral is encountered, the Process first retries to send 
/// the message until FailureTimeout and then, if the error continues, it disables the Process instead of failing. Any other errors will 
/// cause the Process to fail processing of the current message and return the error status to the caller, without retrying first
/// unless the property Retry has been set to true by the Process code.</p>
/// <p><b>The default behavior is equivalent to 'E=F'.</b> If the Retry property has been set by the Process code then retrying will be subject to 
/// the configured RetryInterval and FailureTimeout.</p>
/// <p>All codes where &lt;actions&gt; consists of only 'W' (for 'log a Warning') will be evaluated, and a warning will be
/// generated for each matching &lt;code&gt;. Other &lt;code&gt; values will be evaluated in left-to-right order, executing the
/// first matching &lt;code&gt; that has a non-warning &lt;actions&gt; value. As noted in the details for the 'W' flag, an error
/// that only triggers 'W' &lt;actions&gt; will be treated as Completed OK.</p>
Property ReplyCodeActions As %String(MAXLEN = 1000);

/// How frequently to retry access to the output system
Property RetryInterval As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// When AlertOnError is True and the Process is retrying, refrain from alerting if the Process succeeds within this number of seconds after an error
Property AlertRetryGracePeriod As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

/// How long to keep retrying before giving up and returning an error code. <br/>
/// -1 means never give up.
Property FailureTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 15 ];

/// Number of messages on this item's queue needed to trigger an Alert message to be sent. Note that no further
/// alerts will be sent unless the number of messages on the queue drops below 80% of this number and then rises again to this number. <br/>
/// Note that this alert will be sent even if AlertOnError is False. <br/>
/// Zero means no alerts of this type will be sent.
Property QueueCountAlert As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

/// The number of seconds a message at the front of the queue may have waited since being queued before an alert is triggered.<br/>
/// Only one alert will be raised per host item per sequential trigger of the queue wait threshold. <br/>
/// Note that this alert will be sent even if AlertOnError is False. <br/>
/// Zero means no alerts of this type will be sent.
Property QueueWaitAlert As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

Parameter SETTINGS = "-ThrottleDelay,ReplyCodeActions,RetryInterval,AlertRetryGracePeriod:Alerting,FailureTimeout,QueueCountAlert:Alerting,QueueWaitAlert:Alerting";

/* override as transient - not used in BP */
Property ThrottleDelay As %Numeric [ InitialExpression = 0, Transient ];

/// If this parameter is TRUE, then arrays %MessagesSent and %MessagesReceived will not be populated.
Parameter SKIPMESSAGEHISTORY As BOOLEAN = 1;

/// non-protected properties to be used by subclass methods
Property %request As %Library.Persistent [ Calculated ];

/// non-protected properties to be used by subclass methods
Property %response As %Library.Persistent [ Calculated ];

Property %responseId As %String(COLLATION = "EXACT", MAXLEN = "");

Property %responseClassName As %String(MAXLEN = 128);

/// protected properties
Property %PrimaryRequestHeader As Ens.MessageHeader;

Property %CurrentResponseHeader As Ens.MessageHeader [ Transient ];

/// When an async request is made that requires a response the BP
/// records the request header Id, Completion key, whether the request
/// is a timer and optional list of completion keys needed for synchronizing
/// calls.
/// 
Relationship %MasterPendingResponses As Ens.BP.MasterPendingResponse [ Cardinality = children, Inverse = %BusinessProcess, SqlFieldName = MasterPendingResponses ];

Property %IsCompleted As %Boolean [ InitialExpression = 0 ];

Property %PrimaryResponseHeader As Ens.MessageHeader;

Property %RepliedStatus As %Integer [ InitialExpression = {$$$eRepliedStatusNotCalled} ];

Property %TimeCreated As Ens.DataType.UTC;

Property %TimeCompleted As Ens.DataType.UTC;

Property %IsTimerInterrupted As %Boolean [ InitialExpression = 0 ];

Property %IsTerminated As %Boolean [ InitialExpression = 0 ];

Property %StatusCode As %Status [ InitialExpression = {$$$OK} ];

Property %MessagesSent As list Of %String(MAXLEN = "") [ SqlFieldName = MessagesSent ];

Property %MessagesReceived As list Of %String(MAXLEN = "") [ SqlFieldName = MessagesReceived ];

/// This property maps to the old storage location of %MasterPendingResponses
Property %MasterPendingResponsesOld As list Of %String(MAXLEN = "");

/// This property maps to the old storage location of %MessagesSent
Property %MessagesSentOld As list Of %String(MAXLEN = "");

/// This property maps to the old storage location of %MessagesReceived
Property %MessagesReceivedOld As list Of %String(MAXLEN = "");

/// Subclasses can store hint values here for use in determining what ReplyCodeAction to apply
Property %ActionHint [ Internal, MultiDimensional, Transient ];

Index TimeCreated On %TimeCreated;

Index SessionId On %SessionId;

Index Extent [ Extent, Type = bitmap ];

/// Set this property to 1 if you want to retry the current message again
Property Retry As %Boolean [ InitialExpression = 0 ];

/// Set this property to 1 if you want to mark the current message as "Suspended"
Property SuspendMessage As %Boolean [ InitialExpression = 0 ];

/// Use this method to dispatch a business invocation synchronously
/// WARNING: Using this method can make your Business Process subject to deadlock if you use this method to invoke another BP and both BPs share the production's common Actor Pool. To avoid such a deadlock, structure your code to use SendRequestAsync() instead of this method, and handle response messages in the OnResponse() callback method.  Alternatively, configure the called BP(s) with their own PoolSize > 0 so the main BP won't compete with them for Pool jobs.
Method SendRequestSync(pTargetDispatchName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pTimeout As %Numeric = -1, pDescription As %String = "") As %Status
{
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tZH=$zh
	Set tTargetConfigName = $get($$$DispatchNameToConfigName(pTargetDispatchName))  Quit:""=tTargetConfigName $$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)
	Set tTargetBusinessClass = $$$ConfigClassName(tTargetConfigName)
	Set tSC = $classmethod(tTargetBusinessClass,"acceptRequestSync",..%ConfigName,tTargetConfigName,.pRequest,.pResponse,..%SessionId,pTimeout,.tRequestHeader,pDescription,..%SuperSession)
	If '..#SKIPMESSAGEHISTORY Do:$$$ISOK(tSC) ..%MessagesSent.Insert(tRequestHeader.%Id())
	$$$catTRACE("timing","duration of sync call: "_($zh-tZH))
	Quit tSC
}

/// Use this method to dispatch a business invocation asynchronously
Method SendRequestAsync(pTargetDispatchName As %String, pRequest As Request, pResponseRequired As %Boolean = 1, pCompletionKey As %String = "", pDescription As %String = "") As %Status
{
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tZH=$zh
	Set tSC = ..SendRequestAsyncInternal(pTargetDispatchName, pRequest, pResponseRequired, pCompletionKey,0,,pDescription)
	$$$catTRACE("timing","duration of async call: "_($zh-tZH))
	Quit tSC
}

/// Use this method to send an alert message
Method SendAlert(pAlertRequest As Ens.AlertRequest) As %Status
{
	#dim tSC As %Status = $$$OK
	
	If ($$$JobConfigName="Ens.Alert") {
		#; To avoid infinite loop, no SendAlert from Ens.Alert
		$$$LOGALERT("From Ens.Alert: "_pAlertRequest.AlertText)
	} ElseIf (""=$G($$$DispatchNameToConfigName("Ens.Alert"))) {
		$$$LOGALERT(pAlertRequest.AlertText)
	} Else {
		Do pAlertRequest.%Save()
		$$$LOGALERT(pAlertRequest.AlertText_" (alert request ID="_pAlertRequest.%Id()_")")
		Set tSC = ..SendRequestAsync("Ens.Alert",pAlertRequest,0)
	}
	
	Quit tSC
}

/// This method set up a timer for how long to wait for pending asynchronous responses
Method SetTimer(pTimeout As %String, pCompletionKey As %String = "", pControlledCompletionKeys As %String = "*", Output pAlarmHandle As %String, pDescription As %String = "", pIsTimer = 1) As %Status
{
	Set tAlarmRequest = ##class(Ens.AlarmRequest).%New()
	$$$ASSERT($IsObject(tAlarmRequest))
	Set tAlarmRequest.Timeout = pTimeout
	Set tSC=tAlarmRequest.%Save() Quit:$$$ISERR(tSC) tSC
	Set pAlarmHandle = tAlarmRequest.%Id()
	Quit ..SendRequestAsyncInternal("Ens.Alarm",tAlarmRequest,1,pCompletionKey,pIsTimer,pControlledCompletionKeys,pDescription)
}

Method SendRequestAsyncInternal(pTargetDispatchName As %String, pRequest As Request, pResponseRequired As %Boolean = 1, pCompletionKey As %String = "", pIsTimer As %Boolean, pControlledCompletionKeys As %String = "", pDescription As %String = "", pSimSync As %Boolean = 0) As %Status [ Internal ]
{
	Set tTargetConfigName = $get($$$DispatchNameToConfigName(pTargetDispatchName)) Quit:""=tTargetConfigName $$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)
	Set tTargetBusinessClass=$$$ConfigClassName(tTargetConfigName)
	Set tPriority=$s(pSimSync:$$$eMessagePrioritySimSync,1:$$$eMessagePriorityAsync)
	#; elevate the priority level the at least that of ..%PrimaryRequestHeader
	If ((pResponseRequired)&&(..%RepliedStatus'=$$$eRepliedStatusSent)&&(..%PrimaryRequestHeader.Priority<tPriority)) {
		Set tPriority=..%PrimaryRequestHeader.Priority
	}
	If pResponseRequired {
		Set tBPID=..%Id()
		If ""=tBPID {
			Set tSC=..%Save()
			If $$$ISOK(tSC) {
				Set tBPID=..%Id() ; ensure that we have a return address
			} Else {
				Return tSC
			}
		}
		Set tSC=$classmethod(tTargetBusinessClass,"acceptRequestAsync",..%ConfigName,tTargetConfigName,pRequest,tPriority,..QueueName(),..%SessionId,tBPID,.tRequestHeader,pDescription,..%SuperSession)
		If $$$ISOK(tSC) {
			Set tMPR = ##class(Ens.BP.MasterPendingResponse).%New(tRequestHeader.%Id(),pCompletionKey,pIsTimer,pControlledCompletionKeys)
			Do ..%MasterPendingResponses.Insert(tMPR)
			Set tSC=..%Save()
			If $$$ISOK(tSC) {
				Set tMPRKey = ..%MasterPendingResponses.Previous("")
				Do ..%MasterPendingResponses.%UnSwizzleAt(tMPRKey)
			}
		}
	} Else {
		Set tSC=$classmethod(tTargetBusinessClass,"acceptRequestAsync",..%ConfigName,tTargetConfigName,pRequest,tPriority,"",..%SessionId,..%Id(),.tRequestHeader,pDescription,..%SuperSession)
	}
	If '..#SKIPMESSAGEHISTORY Do:$$$ISOK(tSC) ..%MessagesSent.Insert(tRequestHeader.%Id())
	Quit tSC
}

Method OnTask() As %Status [ Internal ]
{
	$$$ASSERT(0_"BP's OnTask should never be called, Actor's should")
	Quit $$$OK
}

/// This method is for internal use - called for InProc from inprocRequest() or for Queued BPs from the Actor's MessageHeaderHandler()
Method MessageHeaderHandler(pRequestHeader As Ens.MessageHeader, Output pResponseHeader As Ens.MessageHeader, Output pResponseIsError) As %Status [ Internal ]
{
 Set tSC=$$$OK, pResponseIsError="", $ZE = ""
 #dim ex As %Exception.AbstractException
 Set $EC=""  try {
	If '..#SKIPMESSAGEHISTORY Do ..%MessagesReceived.Insert(pRequestHeader.%Id())
	If pRequestHeader.Type = $$$eMessageTypeRequest {
		$$$ASSERT(..%PrimaryRequestHeader=$$$NULLOREF)
		Set ..%PrimaryRequestHeader=pRequestHeader, $$$JobCurrentHeaderId=pRequestHeader.%Id()
		Set ..%Concurrency=4
		Set tSC=..%Save()  Quit:$$$ISERR(tSC)
		Set (..%SessionId,$$$JobSessionId)=pRequestHeader.SessionId
		Set ..%SuperSession=pRequestHeader.SuperSession

		Set ..%TimeCreated = $$$timeUTC
		Do pRequestHeader.SetStatus($$$eMessageStatusDelivered)
		Set tResponse=$$$NULLOREF

		If $D($$$EnsCrashedMessage(pRequestHeader.%Id())) {
			Kill $$$EnsCrashedMessage(pRequestHeader.%Id())
			Set tSC=$$$EnsError($$$EnsErrPreviouslyCrashedMessage,pRequestHeader.%Id())
		} Else {
			#; ensure $ZE reset if SetStatus() led to it being set
			Set $EC="", $ZE=""  try {
				Set tSC=..OnRequest(..%request,.tResponse)
			} catch ex {
				Set tSC=$Select($ZE="":ex.AsStatus(),1:$$$EnsSystemError)
			}
			If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnRequest(); committing before proceeding")
		}
		Set:$$$ISOK(tSC) tSC=..%responseSet(tResponse)
		Quit:$$$ISERR(tSC)
	} ElseIf pRequestHeader.Type = $$$eMessageTypeTerminate {
		Set $$$JobCurrentHeaderId=pRequestHeader.%Id()
		Do pRequestHeader.SetStatus($$$eMessageStatusDelivered)
		Do ..%MasterPendingResponses.Clear()
		Set ..%IsTerminated=1
		Set tSC = ..%Save()
		Quit:$$$ISERR(tSC)
		Set tSC=$classmethod(pRequestHeader.MessageBodyClassName,"%OpenId",pRequestHeader.MessageBodyId).StringValue
	} Else {
		Set ..%CurrentResponseHeader=pRequestHeader, $$$JobCurrentHeaderId=pRequestHeader.%Id()
		Set $$$JobSessionId=..%SessionId
		#; deal with a response, pRequestHeader should have .Type=$$$eMessageTypeResponse
		#; ignore the response once the RunStatus is completed
		If ..%IsCompleted {
			$$$sysTRACE("Discarding response '"_pRequestHeader.%Id()_"' to already-completed process "_..%Id())
			Do pRequestHeader.SetStatus($$$eMessageStatusDiscarded)
			Quit
		}
		#; search the pending sync list for this message body
		Set tCallRequestHeader = ##class(Ens.MessageHeader).%OpenId(pRequestHeader.CorrespondingMessageId)
		If tCallRequestHeader.MessageBodyClassName'="" {
			Set tCallRequest = $classmethod(tCallRequestHeader.MessageBodyClassName,"%OpenId",tCallRequestHeader.MessageBodyId,,.tSC)
			If '$IsObject(tCallRequest) Set tSC=$$$ERROR($$$EnsErrGeneral,"Could not open callrequest MessageBody "_tCallRequestHeader.MessageBodyId_" for MessageHeader #"_tCallRequestHeader.%Id()_" with body class "_tCallRequestHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC))  Quit
		} Else {
			Set tCallRequest=$$$NULLOREF
		}

		Set tSQL = "SELECT %OID(pr.ID) AS prOID, pr.RequestHeaderId AS prHdrId, pr.CompletionKey AS prCK, pr.IsTimer AS prIT, pr.ControlledCompletionKeys AS prCKS FROM Ens_BP.MasterPendingResponse pr WHERE pr.%BusinessProcess = ? AND pr.RequestHeaderId = ?"
		Set tCorrespondingResult = ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL,..%Id(),pRequestHeader.CorrespondingMessageId)
		If tCorrespondingResult.%SQLCODE < 0 {
			Set tSC = ##class(%Exception.SQL).CreateFromSQLCODE(tCorrespondingResult.%SQLCODE,tCorrespondingResult.%Message).AsStatus()
			Quit
		} ElseIf (tCorrespondingResult.%SQLCODE = 0)  && tCorrespondingResult.%Next() {
			Set tIndexOID = tCorrespondingResult.%Get("prOID")
			Set tCompletionKey = tCorrespondingResult.%Get("prCK")
			Set tIsTimer = tCorrespondingResult.%Get("prIT")
			Set pControlledCompletionKeys = tCorrespondingResult.%Get("prCKS")
		} Else {
			Set tIndexOID=""
		}
	
		#; if response is not in the pending sync list, ignore it
		If tIndexOID="" {
			$$$sysTRACE("Discarding response '"_pRequestHeader.%Id()_"' belonging to message '"_pRequestHeader.CorrespondingMessageId_"' while in process "_..%Id())
			Do pRequestHeader.SetStatus($$$eMessageStatusDiscarded)
			Quit
		}
		#; set status to be 'delivered'
		Do pRequestHeader.SetStatus($$$eMessageStatusDelivered)

		#; an asynchronous call responded with an error - call OnError
		Set pResponseIsError = pRequestHeader.IsError
		If pResponseIsError {
			Set tResponse=..%response

			Set tErroredResponseStatus=pRequestHeader.ErrorStatus
			Set $EC=""  try {
				#; Returning $$$OK from this method causes the BusinessProcess to recover from this error
				Set tSC=..OnError(..%request,.tResponse,tCallRequest,tErroredResponseStatus,tCompletionKey)

				#; If we are prepared to handle the errored response (BPL Business Processes do this)
				If ..WillHandleErroredResponse() {
					#; The BP is willing to handle an errored response, prevent exit at this point; pResponseIsError will be tested and acted upon below
					Set tSC=$$$OK
				} Else {
					#; The OnError method 'handled' the error
					Set:$$$ISOK(tSC) pResponseIsError=0
				}
			} catch ex {
				Set tSC=$Select($ZE="":ex.AsStatus(),1:$$$EnsSystemError), pResponseIsError="" ; new tSC for which OnError() has not been called
			}
			If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnError(); committing before proceeding")
			Quit:$$$ISERR(tSC)
			Set tSC=..%responseSet(tResponse)  If $$$ISERR(tSC) Set pResponseIsError=""  Quit
		}
		#; Remove this entry
		Do ..%MasterPendingResponses.RemoveObject(tIndexOID)
		Set tSC = ..%Save()
		Quit:$$$ISERR(tSC)

		#; Handle Timer timeout
		If tIsTimer {
			Set tResponse=..%response
			$$$catTRACE("bproc","calling OnTimeout")
			Set $EC=""  try {
				Set tSC=..OnTimeout(..%request,.tResponse,tCallRequest,tCompletionKey)
			} catch ex {
				Set tSC=$Select($ZE="":ex.AsStatus(),1:$$$EnsSystemError)
			}
			If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnTimeout(); committing before proceeding")
			$$$catTRACE("bproc","returned from OnTimeout")
			Set:$$$ISOK(tSC) tSC=..%responseSet(tResponse)
			Quit:$$$ISERR(tSC)

			Set tMPRKey="", tEntry = ..%MasterPendingResponses.GetPrevious(.tMPRKey)
			While (tMPRKey'="") {
				If (pControlledCompletionKeys="*")||$listfind(pControlledCompletionKeys,tEntry.CompletionKey) {
					Do ..%MasterPendingResponses.RemoveAt(tMPRKey)
					Set tRequestHeader=##class(Ens.MessageHeader).%OpenId(tEntry.RequestHeaderId)
					If tRequestHeader.MessageBodyClassName'="" {
						Set tMessageBody=$classmethod(tRequestHeader.MessageBodyClassName,"%OpenId",tRequestHeader.MessageBodyId,,.tSC1)
						If '$IsObject(tMessageBody) {
							$$$LOGWARNING("Could not open pending MessageBody "_tRequestHeader.MessageBodyId_" for MessageHeader #"_tRequestHeader.%Id()_" with body class "_tRequestHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC1))
						} Else {
							$$$catTRACE("bproc","calling body %OnTimeout")
							Set $EC=""  try {
								Set tSC1 = tMessageBody.%OnTimeout()
								If $$$ISERR(tSC1) $$$LOGSTATUS(tSC1)
								$$$catTRACE("bproc","returned from body %OnTimeout")
							} catch ex {
								If ex.Name '= "<METHOD DOES NOT EXIST>" Do $$$EnsSystemError
							}
							If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after body %OnTimeout(); committing before proceeding")
						}
					}
				}
				Do ..%MasterPendingResponses.%UnSwizzleAt(tMPRKey)
				Set tEntry = ..%MasterPendingResponses.GetPrevious(.tMPRKey)
			}
		}
		#; clear the pending request list if timer is the only thing left
		If ..%MasterPendingResponses.Count()>0 {
			Set tHasNonTimer=0
			Set tSQL = "SELECT COUNT(*) AS NonTimerCount FROM Ens_BP.MasterPendingResponse pr WHERE pr.%BusinessProcess = ? AND pr.IsTimer = 0 "
			Set tCountResult = ##class(%SQL.Statement).%ExecDirect(.tCountStatement,tSQL,..%Id())
			If tCountResult.%SQLCODE < 0 {
				Set tSC = ##class(%Exception.SQL).CreateFromSQLCODE(tCountResult.%SQLCODE,tCountResult.%Message).AsStatus()
				Quit
			} ElseIf (tCountResult.%SQLCODE = 0)  && tCountResult.%Next() {
				If (tCountResult.%Get("NonTimerCount")-tIsTimer)>0 Set tHasNonTimer = 1
			} Else {
				#; SQL positive code - do not clear
				Set tHasNonTimer = 1
			}
			If tHasNonTimer=0 Do ..%MasterPendingResponses.Clear()
		}
		#; call OnResponse if the response is not an error
		#; we can get here when user chooses to ignore an error response
		If 'pResponseIsError {
			Set tResponse=..%response, pResponseIsError="" ; new tSC coming up for which OnError() has not been called
			#; Open message body of original Request and pass it to OnResponse()
			If pRequestHeader.MessageBodyClassName'="" {
				Set tMessageBody = $classmethod(pRequestHeader.MessageBodyClassName,"%OpenId",pRequestHeader.MessageBodyId,,.tSC)
				If '$IsObject(tMessageBody) Set tSC=$$$ERROR($$$EnsErrGeneral,"Could not open request MessageBody "_pRequestHeader.MessageBodyId_" for MessageHeader #"_pRequestHeader.%Id()_" with body class "_pRequestHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC))  Quit
				Set:tIsTimer ..%IsTimerInterrupted=tMessageBody.IsInterrupted
			} Else {
				Set tMessageBody = $$$NULLOREF
			}
			If $D($$$EnsCrashedMessage(pRequestHeader.%Id())) {
				Kill $$$EnsCrashedMessage(pRequestHeader.%Id())
				Set tSC=$$$EnsError($$$EnsErrPreviouslyCrashedMessage,pRequestHeader.%Id())
			} Else {
				$$$catTRACE("bproc","calling OnResponse")
				Set $EC=""  try {
					Set tSC=..OnResponse(..%request,.tResponse,tCallRequest,tMessageBody,tCompletionKey)
				} catch ex {
					Set tSC=$Select($ZE="":ex.AsStatus(),1:$$$EnsSystemError)
				}
			If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnResponse(); committing before proceeding")
				$$$catTRACE("bproc","returned from OnResponse")
			}
			Set:$$$ISOK(tSC) tSC=..%responseSet(tResponse)
		} Else {
			#; This is executed when the BP is willing to handle an error returned from a call.
			#; Currently implemented by all BPL Business processes. The callresponse will not be available.
			Set tResponse=..%response
			$$$catTRACE("bproc","calling OnErroredResponse")
			Set $EC=""  try {
				Set tSC=..OnErroredResponse(tErroredResponseStatus,..%request,.tResponse,tCompletionKey)
				Set pResponseIsError=$$$ISERR(tSC)
			} catch ex {
				Set tSC=$Select($ZE="":ex.AsStatus(),1:$$$EnsSystemError), pResponseIsError="" ; new tSC for which OnError() has not been called
			}
			If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnErroredResponse(); committing before proceeding")
			$$$catTRACE("bproc","returned from OnErroredResponse")
			Quit:$$$ISERR(tSC)
			Set tSC=..%responseSet(tResponse)
		}
		Quit:$$$ISERR(tSC)
	} ; Else
	Do pRequestHeader.SetStatus($$$eMessageStatusCompleted)

	If ..%MasterPendingResponses.Count()=0 {
		Set tResponse=..%response

		$$$catTRACE("bproc","calling OnComplete")
		Set $EC=""  try {
			Set tSC=..OnComplete(..%request,.tResponse)
		} catch ex {
			Set tSC=$Select($ZE="":ex.AsStatus(),1:$$$EnsSystemError)
		}
		If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnComplete(); committing before proceeding")
		$$$catTRACE("bproc","returned from OnComplete")
		Set:$$$ISOK(tSC) tSC=..%responseSet(tResponse)
		Quit:$$$ISERR(tSC)

		#; if OnComplete() adds more async calls, the process is not complete
		If ..%MasterPendingResponses.Count()=0 {
			Set ..%IsCompleted = 1, ..%TimeCompleted = $$$timeUTC
			If ..%RepliedStatus=$$$eRepliedStatusNotCalled Set tSC=..Reply(..%response)
#If ..#INVOCATION="InProc"
			Try {
				Set tBPConfigName=..%PrimaryRequestHeader.TargetConfigName
				If tBPConfigName="" Set tBPConfigName=..%ConfigName
				If ##class(Ens.Util.Statistics).StatsActive(tBPConfigName) {
					#dim tTimeDelta = ##class(%SYSTEM.SQL.Functions).DATEDIFF("ms",..%TimeCreated,..%TimeCompleted)/1000
					Do ##class(Ens.Util.Statistics).RecordStats($$$eHostTypeProcess,tBPConfigName,"",1,1,tTimeDelta)
				}
			} Catch {}
#EndIf
		}
	}
 } catch {
	Set tSC=$$$EnsSystemError
 }
 #; Can't leave Status in Delivered if a response and errored
 If $$$ISERR(tSC)&&(pRequestHeader.Type=$$$eMessageTypeResponse)&&(pRequestHeader.Status=$$$eMessageStatusDelivered) {
	Do pRequestHeader.SetStatus($$$eMessageStatusError)
 }
 Quit tSC
}

/// This method is for internal use.
ClassMethod inprocRequest(pSourceConfigName As %String, pTargetConfigName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pReturnQueueName As %String, ByRef pSessionId As %String, pBusinessProcessId As %String, ByRef pRequestHeader As Ens.MessageHeader, pDescription As %String = "", pPriority As Ens.DataType.MessagePriority = {$$$eMessagePrioritySync}, ByRef pSuperSession As %String) As %Status [ Internal ]
{
 Set pResponse=$$$NULLOREF
 Set tSC = ##class(Ens.MessageHeader).NewRequestMessage(.pRequestHeader,pRequest,.pSessionId,.pSuperSession)  Quit:$$$ISERR(tSC) tSC
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

 Set tSC=pRequestHeader.%Save()  If $$$ISERR(tSC) $$$LOGSTATUS(tSC)  Quit tSC

 /*	Check for support of client disconnect and retry 
	Same as used by Ens.Host:inprocRequest()
 */
 If $Data(pRequestHeader("SyncHandling","ResponseWaitTimeoutToUse"),tClientWaitTimeout)#2 && $Data(pRequestHeader("SyncHandling","ClientRequestKey"),tClientRequestKey)#2 {
	Set tXREFClientRequest = ..createDelayedRequestXREFOref(tClientRequestKey,pRequestHeader,tClientWaitTimeout,.tZHClientWaitTimeout,.tXREFSC)
	If $$$ISERR(tXREFSC) {
		#; ensure identifier var for delayed sync handling removed
		Kill tZHClientWaitTimeout
		$$$LOGERROR("Proceeding without optional delayed SyncRequest handling due to unexpected error encountered trying to create Delayed Request XREF "_$System.Status.GetErrorText(tXREFSC))
	}
 }
 Set ($$$EnsJobStatus($$$SystemName,$Job,$$$eJobGuestConfigName),$$$EnsJobLocal("GuestConfigName"))=pTargetConfigName
 Do ##class(Ens.Util.Trace).SetTraceOptimizer()

 Set tSC=$$$OK, tRetryCount=1, (tEndTime,tDoAlert)="", (tAborted,tAlertStartTime,tTerminate)=0, tResponseHeader=$$$NULLOREF
 Set $EC=""  try {
	Set tOldBP=$G($$$EnsJobLocal("%Process"))
	While 1 { ; Retry loop
		Set tSC=..findCachedObject(pTargetConfigName,.tBP)  Quit:$$$ISERR(tSC)
		$$$ASSERT($IsObject(tBP))
		Set tOldBP=$G($$$EnsJobLocal("%Process")), $$$EnsJobLocal("%Process")=tBP
		If $$$DoTrace {
			$$$unconditionalCatTRACE("bproc","Begin processing "_$S(1=tRetryCount:"",1:"try "_tRetryCount_" of ")_"message "_pRequestHeader.%Id()_"; %MasterPendingResponses contains "_tBP.%MasterPendingResponses.Count()_" element(s)",tShowCat)
			Do:tShowCat tBP.catTraceCompletionKeys()
		}
		Set tTimeCalled=$ZH
		Set:""=tEndTime tEndTime = tTimeCalled + tBP.FailureTimeout
		While 1 { ; InProc loop
			Set tSC=tBP.MessageHeaderHandler(pRequestHeader,.tResponseHeader,.tHandledError)
			If ""=tHandledError && $$$ISERR(tSC) {
				Set $EC=""  try {
					Set tSC=tBP.OnError($$$NULLOREF,$$$NULLOREF,$$$NULLOREF,tSC,"")
				} catch {
					Set tSC=$$$EnsSystemError
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after inProc OnError(); committing before proceeding")
				Set tDoAlert=$$$ISERR(tSC)
			}

			/*	For Queued BP the active message entry is removed in Ens.Host::OnTask
				after each queued message has been handled.
				For InProc we will loop dequeuing here until an error or BP is complete.
				On entering this method we will have an entry for $$$EnsActiveMessage($$$SystemName_":"_$Job)
				if called from a Queued host which we do not want to delete.
				EnsQueue:Dequeue does not overwrite and pRequestHeader.%Id() will not be the same header id as that
				for the calling queued host.
				If called from an 'outside' job then there will be no current $$$EnsActiveMessage($$$SystemName_":"_$Job)
				and we want to clean any active message entry written by Dequeue.
				Note that the first time through this loop pRequestHeader was built here and hence will never
				match a possible ActiveMessage entry.
			*/
			If (pRequestHeader.%Id()=$Get($$$EnsActiveMessage($$$SystemName_":"_$Job))) Kill $$$EnsActiveMessage($$$SystemName_":"_$Job)

			Quit:tBP.%IsCompleted||$$$ISERR(tSC)
			For { ; While new InProc response message found and this BP is not completed
				Set tSC=##class(Ens.Queue).DeQueue(tBP.QueueName(),.pRequestHeader,,,0)  Quit:$$$ISERR(tSC)
				Continue:'$IsObject(pRequestHeader)
				Quit:tBP.%Id()=pRequestHeader.BusinessProcessId

				$$$sysTRACE("Out-of-band message '"_pRequestHeader.%Id()_"' discarded")
				Do pRequestHeader.SetStatus($$$eMessageStatusDiscarded)
			} Quit:$$$ISERR(tSC)
		}
		If $IsObject(tOldBP) { Set $$$EnsJobLocal("%Process")=tOldBP } Else { Kill $$$EnsJobLocal("%Process") }
		Continue:'tBP.%IsCompleted&&$$$ISOK(tSC)

		Set tRequest=tBP.%request, tResponse=tBP.%response
		Set $EC=""  try {
			Set tMHSC=tSC
			Set tAction=tBP.OnGetReplyAction(tRequest,.tResponse,.tSC)
			Set:""'=tAction tSC=tBP.doReplyAction(tAction,tRequest,.tResponse,tSC)
			If tSC'=tMHSC&&$$$ISERR(tSC) {
				$$$sysTRACE("calling OnError A")
					Set tSC=tBP.OnError($$$NULLOREF,$$$NULLOREF,$$$NULLOREF,tSC,"")
			}
		} catch {
			Set tSC=$$$EnsSystemError
		}
		If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after ReplyAction OnError(); committing before proceeding")
		Set:""=tDoAlert tDoAlert=$$$ISERR(tSC)
		If tBP.SuspendMessage {
			Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't suspend InProc "_pRequestHeader.%Id()_" in BP for job "_$J_$S($$$ISOK(tSC):"", 1:" - original error: "_$$$StatusDisplayString(tSC)))
			Quit
		}
		Quit:'tBP.Retry

		If $$$ISERR(tSC) {
			Set tTxt=$$cleanNum($P($$$StatusDisplayString(tSC)," -- ")) ; strip off "logged as" varying text and remove digits following a number sign
			Set:'tAlertStartTime&&tBP.AlertOnError&&tBP.AlertRetryGracePeriod&&(tTxt'=tBP.%LastReportedError) tAlertStartTime=$ZH
			If tAlertStartTime {
				If $ZH>=(tAlertStartTime+tBP.AlertRetryGracePeriod) {
					Set tAlertStartTime=0
					If tTxt'=tBP.%LastReportedError { $$$LOGERROR("Alerting at expiration of retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
					Else { $$$LOGINFO("Alerting at expiration of retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
				} Else {
					Set tDoAlert=0
					If tTxt'=tBP.%LastReportedError { $$$LOGERROR("Not Alerting during retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
					Else { $$$LOGINFO("Not Alerting during retry grace period ("_tBP.AlertRetryGracePeriod_") for "_tTxt) }
				}
			} Else {
				If tTxt'=tBP.%LastReportedError { $$$LOGSTATUS(tSC) }
				Else { Set tDoAlert=0 }
			}
			Do:tDoAlert&&tBP.AlertOnError tBP.SendAlert(##class(Ens.AlertRequest).%New($LB(tBP.%ConfigName,$$$StatusDisplayString(tSC))))
			Set tDoAlert=""
		} Else { Set tAlertStartTime=0, tTxt="" }
		Set tBP.%LastReportedError=tTxt

		If tBP.FailureTimeout'=-1 {
			Set tNow=$ZH
			If tNow>tEndTime {
				Set tFailureTimedOut=1, tSC=$$$ERROR($$$EnsErrFailureTimeout, tBP.FailureTimeout, $$$StatusDisplayString(tSC), $$$CurrentClass)
				Set $EC=""  try {
					Set tDoDefault=tBP.OnFailureTimeout(tRequest,.tResponse,.tSC)
					Set:tDoDefault tSC=$S(""=tAction:tSC,1:tBP.finalReplyAction(tAction,tSC,1))
				} catch {
					Set tSC=$$$EnsSystemError
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnFailureTimeout(); committing before proceeding")
				Set:""=tDoAlert tDoAlert=$$$ISERR(tSC)
				Set:tBP.SuspendMessage tSC=$$$ERROR($$$EnsErrGeneral,"Can't suspend InProc "_pRequestHeader.%Id()_" as requested by signal for job "_$J_$S($$$ISOK(tSC):"", 1:" - original error: "_$$$StatusDisplayString(tSC)))
				Quit
			}
		}
		$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Retry")
		Set tWaitTime = tTimeCalled + tBP.RetryInterval - $ZH
		Set tSC1=##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,$S(tWaitTime<0:0, 1:tWaitTime),,0)  If $$$ISERR(tSC1) Set tSC=$$$ADDSC(tSC,tSC1)  Quit
		Set tTerminate=##class(Ens.Job).ShouldTerminate()
		Set tSBQ=##class(Ens.Job).ShouldBeQuiescent()
		If tSBQ || tTerminate {
			If pRequestHeader.Priority>$$$eMessagePrioritySync||tTerminate {
				Set tTerminate=1
				$$$LOGINFO("Retry loop exited due to shutdown request for message "_tBP.%PrimaryRequestHeader.%Id()_" ; re-queueing"_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))
				Set tSC1=##class(Ens.Queue).PutBackToQueue(pRequestHeader)
				If $$$ISERR(tSC1) { Set tSC=$$$ADDSC(tSC1,tSC) }
				Else { If 'tFailureTimedOut Set tSC=$$$OK } ; blow away the original error
				Quit
			}
			$$$LOGINFO("Ignoring "_$S(tSBQ:"Quiescent",1:"Terminate")_" request while processing high priority (i.e. synchronous) request "_tBP.%PrimaryRequestHeader.%Id())
		}
		If ##class(Ens.Job).ShouldAbort() {
			$$$LOGWARNING("Message "_tBP.%PrimaryRequestHeader.%Id()_" aborted as requested by signal for job "_$J_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))
			Set tSC=$$$OK, tAborted=1
			Quit
		}
		If ##class(Ens.Job).ShouldSuspend() {
			Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't suspend inproc "_pRequestHeader.%Id()_" as requested by signal for job "_$J_$S($$$ISOK(tSC):"", 1:" - original error: "_$$$StatusDisplayString(tSC)))
			Set tBP.SuspendMessage=1
			Quit
		}
		Set tRetryCount=tRetryCount+1
		$$$SetJobMonitor(tConfigName,$$$SystemName_":"_$Job,$$$eMonitorRetry,tRetryCount)
		$$$sysTRACE("Retrying Request Header Id "_pRequestHeader.%Id()_" - try #"_tRetryCount)
		Set pRequestHeader=tBP.%PrimaryRequestHeader ; try again from the top
	} ; Retry loop
	While $IsObject(tBP) { ; not really a loop, just a quittable If
		Set:$D(tResponse) tBP.%response=tResponse

		If tBP.%RepliedStatus=$$$eRepliedStatusConstructed {
			Set tResponseHeader=tBP.%PrimaryResponseHeader, tBP.%PrimaryResponseHeader=$$$NULLOREF
			Set tBP.%RepliedStatus=$$$eRepliedStatusSent

			#; Client response timeout handling
			If $Data(tZHClientWaitTimeout) {
				Set tXREFClientRequest = ..completeDelayedRequestXREFOref(tXREFClientRequest,tZHClientWaitTimeout,tResponseHeader,.tXREFSC)
				If $$$ISERR(tXREFSC) $$$LOGERROR("Unexpected error encountered trying to update Delayed Request XREF "_$System.Status.GetErrorText(tXREFSC))
			}

		}
SaveExit
		Set tBP.%StatusCode=tSC
		Set $EC=""  try {
			Set:""=tHandledError&&$$$ISERR(tSC) tSC=tBP.OnError($$$NULLOREF,$$$NULLOREF,$$$NULLOREF,tSC,"")
		} catch {
			Set tSC=$$$EnsSystemError
		}
		If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after inProc OnError() 2; committing before proceeding")
		Set:""=tDoAlert tDoAlert=$$$ISERR(tSC)
		If $$$ISERR(tSC) {
			If tBP.%RepliedStatus=$$$eRepliedStatusNotCalled {
				Set tSC2=tBP.%PrimaryRequestHeader.NewErrorResponse(.tResponseHeader,tSC)  Set:$$$ISERR(tSC2) tSC=$$$ADDSC(tSC,tSC2)
				Set tBP.%response=$$$NULLOREF
				Set tBP.%PrimaryResponseHeader=$$$NULLOREF
				Set tBP.%RepliedStatus=$$$eRepliedStatusSent
			} Elseif tBP.%RepliedStatus=$$$eRepliedStatusConstructed {
				Set tResponseHeader=tBP.%PrimaryResponseHeader, tBP.%PrimaryResponseHeader=$$$NULLOREF
				Set tBP.%RepliedStatus=$$$eRepliedStatusSent
			} Else {
				#; nothing to do if tBP.%RepliedStatus=$$$eRepliedStatusSent
			}
			Set tBP.%IsCompleted=1, tBP.%TimeCompleted = $$$timeUTC
			$$$LOGSTATUS($$$ERROR($$$EnsErrBPTerminated,tBP.%ConfigName,tBP.%Id(),$$$StatusDisplayString(tSC)))
		}
		If '$G(tSaveFailed) {
			Set tSC3=tBP.%Save() If $$$ISERR(tSC3) {
				Set tSaveFailed=1, tSC=$$$ADDSC(tSC3,tSC)
				$$$LOGSTATUS(tSC)
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
		If $$$DoTrace {
			$$$unconditionalCatTRACE("bproc","Exit BP "_pRequestHeader.%Id()_"; %MasterPendingResponses contains "_tBP.%MasterPendingResponses.Count()_" element(s)",tShowCat)
			Do:tShowCat tBP.catTraceCompletionKeys()
		}

		If $IsObject(tResponseHeader) {
			If tResponseHeader.TargetQueueName'="" {
				Set tSC4 = ##class(Ens.Queue).EnQueue(tResponseHeader)  If $$$ISERR(tSC4) Set tSC=$$$ADDSC(tSC,tSC4)  Quit
			} Else {
				Set tSC4=tResponseHeader.%Save()  If $$$ISERR(tSC4) Set tSC=$$$ADDSC(tSC,tSC4)  Quit
				If tResponseHeader.MessageBodyClassName'="" {
					Set pResponse = $classmethod(tResponseHeader.MessageBodyClassName,"%OpenId",tResponseHeader.MessageBodyId,,.tSC4)
					If '$IsObject(pResponse) Set tSC4=$$$EnsError($$$EnsErrGeneral,"Could not open response MessageBody "_tResponseHeader.MessageBodyId_" for MessageHeader #"_tResponseHeader.%Id()_" with body class "_tResponseHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC4)), tSC=$$$ADDSC(tSC,tSC5)  Quit
				}
				Do tResponseHeader.SetStatus($$$eMessageStatusCompleted)
			}
		} Else {
			Set pResponse=$$$NULLOREF
		}
		Quit
	} ; end If/While
 } catch {
	Set tSC=$$$ADDSC(tSC,$$$EnsSystemError)
	If $IsObject(tOldBP) { Set $$$EnsJobLocal("%Process")=tOldBP } Else { Kill $$$EnsJobLocal("%Process") }
 }
 Set $EC=""  try {
	If $$$ISERR(tSC) {
		$$$LOGSTATUS(tSC)
		Do:'tAborted pRequestHeader.SetStatus($$$eMessageStatusError)
	}
	If $$$IsdefObject(tBP) {
		Set tBPConfigName=tBP.%ConfigName
		If $$$ISERR(tSC) {
			$$$SetHostMonitor(tBPConfigName,$$$eMonitorStatus,"Error")
			Do:tDoAlert&&tBP.AlertOnError tBP.SendAlert(##class(Ens.AlertRequest).%New($LB(tBPConfigName,$$$StatusDisplayString(tSC))))
		}
	}
	#; Clear guest config - note this will be useless but harmless if tBP does not exist (i.e. discarded response for completed BP)
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

Method %requestGet() [ Internal ]
{
	If ..%PrimaryRequestHeader.MessageBodyClassName'="" {
		#dim tSC As %Status
		#dim tRequest As %RegisteredObject = $classmethod(..%PrimaryRequestHeader.MessageBodyClassName,"%OpenId",..%PrimaryRequestHeader.MessageBodyId,,.tSC)
		If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		Quit tRequest
	} Else {
		Quit $$$NULLOREF
	}
}

Method %responseGet() [ Internal ]
{
	If ..%responseClassName="" {
		If ..%responseId'="" {
			Quit ..%responseId
		}
		Quit $$$NULLOREF
	} Else {
		#dim tSC As %Status
		#dim tResponse As %RegisteredObject = $classmethod(..%responseClassName,"%OpenId",..%responseId,,.tSC)
		If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		Quit tResponse		
	}
}

Method %responseSet(pResponse As %Library.Persistent) As %Status [ Internal ]
{
	Set tSC=$$$OK
	If '$IsObject(pResponse) {
		Set ..%responseClassName=""
		Set ..%responseId=pResponse
	} Else {
		Set ..%responseClassName=$classname(pResponse)
		Set:pResponse.%IsA("%Library.Persistent")||pResponse.%IsA("%Stream.Object") tSC=pResponse.%Save()
		Set:$$$ISOK(tSC) tSC=pResponse.%GetSwizzleObject(0,.tOID)
		If $$$ISERR(tSC) Set ..%responseId=""  Quit tSC
		Set ..%responseId=$$$oidPrimary(tOID)
	}
	Quit tSC
}

/// Override to ensure that each time the BusinessProcess is invoked inproc, a new business process object is created.
ClassMethod findCachedObject(pTargetDispatchName As %String, pInstance As Ens.Host) As %Status [ Internal ]
{
	Set pInstance=..%New($$$DispatchNameToConfigName(pTargetDispatchName))
	Quit $$$OK
}

/// Handle a 'Request'
Method OnRequest(request As %Library.Persistent, Output response As %Library.Persistent) As %Status
{
	// Subclass responsibility
	Quit $$$EnsError($$$NotImplemented)
}

/// Handle a 'Response'
Method OnResponse(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, callresponse As %Library.Persistent, pCompletionKey As %String) As %Status
{
	// Subclass responsibility
	Quit $$$EnsError($$$NotImplemented)
}

/// Handle an errored 'Response'. <br>
/// Do not implement this method in custom code if sub classing Ens.BusinessProcessBPL
/// since BPLs implement this method using automatic code generation.<br>
/// If <method>WillHandleErroredResponse</method> returns true then the response will be given to this method and not <method>OnResponse</method>. <br>
/// <method>OnError</method> is called before <method>WillHandleErroredResponse</method> is checked.<br>
Method OnErroredResponse(pErroredResponseStatus As %Status, request As %Library.Persistent, ByRef response As %Library.Persistent, pCompletionKey As %String) As %Status
{
	// Subclasses of Ens.BusinessProcessBPL implement this via generated code
	Quit $$$OK
}

/// Called when all the Async responses are received, or timeout has occurred
Method OnComplete(request As %Library.Persistent, ByRef response As %Library.Persistent) As %Status
{
	// Subclass responsibility
	Quit $$$OK
}

/// This method is called when an error response is received.<br>
/// Returning the same error will cause the BusinessProcess to set its status to error and close down
/// Returning $$$OK from this method causes the BusinessProcess to recover from this error<br>
/// For custom coded Business Processes that do not sub class Ens.BusinessProcessBPL it is also possible
/// to use <method>WillHandleErroredResponse</method> and <method>OnErroredResponse</method><br>
Method OnError(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, pErrorStatus As %Status, pCompletionKey As %String) As %Status
{
	Quit pErrorStatus
}

Method OnTimeout(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, pCompletionKey As %String) As %Status
{
	// Subclass responsibility
	Quit $$$OK
}

/// Construct and return an Action string consisting of supported action code letters, based on criteria in the ReplyCodeActions setting value and qualities of the current Request, Response, and Error Status.
Method OnGetReplyAction(pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, ByRef pSC As %Status) As %String
{
 	Set (tFullAction,tText)="", nActions=$S(""=$ZStrip(..ReplyCodeActions,"<>W"):0, 1:$L(..ReplyCodeActions,","))
	For i=1:1:nActions { Set tType=$P(..ReplyCodeActions,",",i)  Continue:""=tType
		Set tAction="", tCode=$ZStrip($P(tType,"="),"<>W"), tCodeU=$ZCVT(tCode,"U")
		Set tKnown=$Case($E(tCodeU)
						,"E":$Case($E(tCode,2)
								,"#":1
								,"*":1
								,"":1
								,:0)
						,"X":$Case($E(tCode,2),"":1, :0)
						,:0
						)
		If 'tKnown {
			$$$LOGWARNING("Unrecognized reply code:'"_tType_"'")
			Continue
		}
		Set tMatch=$Case($E(tCodeU)
						,"E":$$$ISERR(pSC)
						,"X":'$$$IsdefObject(pResponse)
						,:0)
				 && $Case($E(tCode,2)
						,"#":$$$StatusEquals(pSC,$E(tCode,3,*))
						,"*":$$$StatusDisplayString(pSC)[$E(tCode,3,*)
						,:1)
		If tMatch {
			If $E(tCodeU)="X" {
				Set tMatchText="Empty Response object matched ReplyCodeAction "_i_" : ':"_tType_"'"
			} Else {
				Set tMatchText="Status '"_$$$StatusDisplayString(pSC)_"' matched ReplyCodeAction "_i_" : '"_tType_"'"
			}
			Set tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
			Set:tAction'?1.(1"R",1"C",1"W",1"S",1"D",1"F") tAction=""
			If ""=tAction {
				$$$LOGWARNING("Unrecognized reply code action:'"_tType_"'")
				Continue
			}
			#; Make sure tFullAction has no more than 1 'W' in it; Quit if it is not just 'W'
			Set:""'=tMatchText tText=tText_$S(""'=tText:" and ",1:"")_tMatchText
			Set:tAction["W" tFullAction=""
			Set tFullAction=tAction_$S(tAction["W":"",1:tFullAction)
#If ..#INVOCATION="InProc"
			If (tFullAction["D") Set tFullAction=$TR(tFullAction,"D") $$$LOGWARNING("InProc "_..%ConfigName_" can not invoke action 'D' (Disable)")
#EndIf
			Quit:tFullAction'?1."W"
		}
	}
	#; Need to guard against system (lock for example) failure that prevents opening pRequest
	Set:""'=tText ..%ActionHint("CodeReason")=
		"Message body "_$G(pRequest)_$S($$$IsdefObject(pRequest)&&(""'=pRequest.%Id()):"' / "_pRequest.%Id(),1:"'")_" because "_
		$S('$$$IsdefObject(pResponse):"",1:"response "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" ")_
		tText_" resulting in Action code "_tFullAction
	Quit tFullAction
}

/// Do the specified action for taking care of the message currently being processed
Method doReplyAction(pAction As %String, pRequest As %Library.Persistent, pResponse As %Library.Persistent, ByRef pSC As %Status) As %Status [ Internal ]
{
	Set tText=$G(..%ActionHint("CodeReason"))
	#; Need to guard against system (lock for example) failure that prevents opening pRequest
	Set:""=tText tText="Message body "_$G(pRequest)_$S($$$IsdefObject(pRequest)&&(""'=pRequest.%Id()):"' / "_pRequest.%Id(),1:"'")_" because response '"_$G(pResponse)_$S($$$IsdefObject(pResponse)&&(""'=pResponse.%Id()):"' / "_pResponse.%Id(),1:"'")_" and error '"_$$$StatusDisplayString(pSC)_"' resulted in action code '"_pAction_"'"

	Set tActionDesc=$S(pAction["R":"Retrying", pAction["S":"Suspending", pAction["D":"Disabling on", (pAction["F"&&'..Retry):"Quitting with error on", pAction["F":"Retry flag enabled. Quitting with error (subject to RetryInterval and FailureTimeout) on", 1:"Accepting as Completed")
	If "Accepting as Completed"=tActionDesc {
		If pAction["W" {
			$$$LOGWARNING("Warning on "_tText)
		} Else {
			$$$sysTRACE("Accepting as Completed "_tText)
		}
		Set ..Retry=0, ..SuspendMessage=0
		Quit $$$OK ; suppress any error
	}
	Set tSC=$$$ERROR($$$EnsErrGeneral,tActionDesc_" "_tText)
	If pAction["R" {
		Set ..Retry=1
	} Else {
		Set tSC=..finalReplyAction(pAction,tSC,0)
		Set pAction="" ; clear because we just did it
	}
	Quit tSC
}

/// Do the action specified for when all configured retries have been exhausted
Method finalReplyAction(pAction As %String, pSC As %Status, pFixError As %Boolean) As %String [ Internal ]
{
	If pAction["S" {
		Set ..SuspendMessage=1, tActionDesc="Suspending on"
	} ElseIf pAction["D" {
		Set:($ZS<$$$MAXBBSZ) $ZS=$$$MAXBBSZ
		Set ..SuspendMessage=0, tActionDesc="Disabling on"
		Do ##class(Ens.Job).Stop($Job)
		Do ##Class(Ens.Director).EnableConfigItem(..%ConfigName,0,0)
		Do ..SendRequestAsync("Ens.ScheduleHandler",$$$NULLOREF,0,,"actualize self-disable")
		Set ..%QuitTask=1, ..Retry=1 ; we are quitting but the retry flag will force us to requeue the current message
	} ElseIf pAction["F" {
		// No work required here ; just quit with error
		Set tActionDesc="Discarding message on"
		Set ..SuspendMessage=0
	} Else { ; ??
		$$$LOGWARNING($$$StatusDisplayString(pSC))
		Set pSC=$$$OK, pFixError=0
	}
	Set:pFixError pSC=$$$ERROR($$$EnsErrGeneral,tActionDesc_" "_$$$StatusDisplayString(pSC))
	Quit pSC
}

/// Override this method to provide custom handling of retry / failure timeout.<p/>
/// Set ..Retry=1 to override normal error return and re-evaluate flag properties.<p/>
/// Return 0 to skip further (default) FailureTimeout processing, 1 to perform default processing.
Method OnFailureTimeout(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent, ByRef pSC As %Status) As %Boolean [ CodeMode = expression ]
{
1
}

/// Call this method to send the response to the primary request before the process is finished
Method Reply(response As %Library.Persistent) As %Status
{
	Set tSC=$$$OK
	Set $EC=""  try {
		If ..%RepliedStatus'=$$$eRepliedStatusNotCalled Quit
		Set ..%response=response
		Set tSC=..%PrimaryRequestHeader.NewResponseMessage(.tResponseHeader,..%response,..%SuperSession) Quit:$$$ISERR(tSC)
		If ..%PrimaryRequestHeader.Invocation=$$$eMessageInvocationInProc {
			Set ..%response=$$$NULLOREF
			Set ..%PrimaryResponseHeader=tResponseHeader
			Set ..%RepliedStatus=$$$eRepliedStatusConstructed
		} Else {
			If tResponseHeader.TargetQueueName'="" Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
			Set ..%response=$$$NULLOREF
			Set ..%PrimaryResponseHeader=$$$NULLOREF
			Set ..%RepliedStatus=$$$eRepliedStatusSent
		}
		If '..#SKIPMESSAGEHISTORY Do ..%MessagesSent.Insert(tResponseHeader.%Id())
		Do ..%PrimaryRequestHeader.SetStatus($$$eMessageStatusCompleted)
	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

/// Call this method to send an error status to the primary request before the process is finished
Method ReplyError(pStatus As %Status) As %Status
{
	Set tSC=$$$OK
	Set $EC=""  try {
		If ..%RepliedStatus'=$$$eRepliedStatusNotCalled Quit
		Set tSC=..%PrimaryRequestHeader.NewErrorResponse(.tResponseHeader,pStatus)  Quit:$$$ISERR(tSC)
		If ..%PrimaryRequestHeader.Invocation=$$$eMessageInvocationInProc {
			Set ..%response=$$$NULLOREF
			Set ..%PrimaryResponseHeader=tResponseHeader
			Set ..%RepliedStatus=$$$eRepliedStatusConstructed
		} Else {
			If tResponseHeader.TargetQueueName'="" Set tSC = ##class(Ens.Queue).EnQueue(tResponseHeader) Quit:$$$ISERR(tSC)
			Set ..%response=$$$NULLOREF
			Set ..%PrimaryResponseHeader=$$$NULLOREF
			Set ..%RepliedStatus=$$$eRepliedStatusSent
		}
		Do ..%PrimaryRequestHeader.SetStatus($$$eMessageStatusCompleted)
	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

/// Determine if a CompletionKey exists in the %MasterPendingResponses
Method IsResponsePending(pCompletionKey As %String) As %Boolean
{
	Set tSC = ..%Save()
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Set tIsResponsePending=0
	Set tSQL = "SELECT COUNT(*) AS IsResponsePending FROM Ens_BP.MasterPendingResponse pr WHERE pr.%BusinessProcess = ? AND pr.CompletionKey = ? "
	Set tCompletionResult = ##class(%SQL.Statement).%ExecDirect(.tCompletionStatement,tSQL,..%Id(),pCompletionKey)
	If tCompletionResult.%SQLCODE < 0 {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(tCompletionResult.%SQLCODE,tCompletionResult.%Message)		
	} ElseIf (tCompletionResult.%SQLCODE = 0)  && tCompletionResult.%Next() {
		If tCompletionResult.%Get("IsResponsePending") > 0 Set tIsResponsePending = 1
	}
	Quit tIsResponsePending
}

/// remove from %MasterPendingResponses with a CompletionKey
Method RemovePendingResponse(pCompletionKey As %String)
{
	Set tSC = ..%Save()
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Set tSQL = "SELECT %OID(pr.ID) AS prOID, pr.RequestHeaderId AS prHdrId, pr.CompletionKey AS prCK FROM Ens_BP.MasterPendingResponse pr WHERE pr.%BusinessProcess = ? AND pr.CompletionKey = ? "
	Set tCompletionResult = ##class(%SQL.Statement).%ExecDirect(.tCompletionStatement,tSQL,..%Id(),pCompletionKey)
	If tCompletionResult.%SQLCODE < 0 {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(tCompletionResult.%SQLCODE,tCompletionResult.%Message)		
	} ElseIf (tCompletionResult.%SQLCODE = 0) {
		While tCompletionResult.%Next() {
			Do ..%MasterPendingResponses.RemoveObject(tCompletionResult.%Get("prOID"))
			Set tRequestHeader=##class(Ens.MessageHeader).%OpenId(tCompletionResult.%Get("prHdrId"))
			If tRequestHeader.MessageBodyClassName'="" {
				Set tMessageBody=$classmethod(tRequestHeader.MessageBodyClassName,"%OpenId",tRequestHeader.MessageBodyId,,.tSC1)
				If '$IsObject(tMessageBody) {
					$$$LOGWARNING("Could not remove pending response MessageBody "_tRequestHeader.MessageBodyId_" for MessageHeader #"_tRequestHeader.%Id()_" with body class "_tRequestHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC1))
				} Else {
						Set $EC=""  try {
						Set tSC = tMessageBody.%OnTimeout()
						If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
					} catch ex {
						If ex.Name '= "<METHOD DOES NOT EXIST>" Do $$$EnsSystemError
					}
					If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after body %OnTimeout(); committing before proceeding")
				}
			}
		}
	}
	Quit
}

/// clear %MasterPendingResponses
Method ClearAllPendingResponses()
{
	Set tMPRKey="", tEntry = ..%MasterPendingResponses.GetPrevious(.tMPRKey)
	Set tHadOneToRemove = (tMPRKey'="")
	While (tMPRKey'="") {
		Set tRequestHeader=##class(Ens.MessageHeader).%OpenId(tEntry.RequestHeaderId)
		If tRequestHeader.MessageBodyClassName'="" {
			Set tMessageBody=$classmethod(tRequestHeader.MessageBodyClassName,"%OpenId",tRequestHeader.MessageBodyId,,.tSC1)
			If '$IsObject(tMessageBody) {
				$$$LOGWARNING("Could not open pending response MessageBody "_tRequestHeader.MessageBodyId_" for MessageHeader #"_tRequestHeader.%Id()_" with body class "_tRequestHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC1))
			} Else {
				Set $EC=""  try {
					Set tSC = tMessageBody.%OnTimeout()
					If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
				} catch ex {
					If ex.Name '= "<METHOD DOES NOT EXIST>" Do $$$EnsSystemError
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after clear body %OnTimeout(); committing before proceeding")
			}
		}
		Do ..%MasterPendingResponses.RemoveAt(tMPRKey)
		Set tEntry = ..%MasterPendingResponses.GetPrevious(.tMPRKey)
	}
	If tHadOneToRemove {
		Set tSC = ..%Save()
		If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	}
	Quit
}

/// If the response has IsError set to true and this method returns true the response will be
/// handed to <method>OnErroredResponse</method> and not <method>OnResponse</method>. <br>
/// <method>OnError</method> is called before this return is checked. <br>
/// Do not implement this method in custom code if sub classing Ens.BusinessProcessBPL
/// since BPLs implement this to always return true.<br>
Method WillHandleErroredResponse() As %Boolean [ CodeMode = expression ]
{
0
}

ClassMethod GetMessageList() As %String [ CodeMode = expression, Internal ]
{
..GetRequestClassList()
}

ClassMethod GetRequestClassList() As %String [ CodeMode = objectgenerator, GenerateAfter = OnRequest, Internal ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnRequest",$$$cMETHformalspecparsed)
	Set tClass=$lg($lg(tSignature,1),2)
	Do %code.WriteLine(" Quit $lb("""_tClass_""")")
	Quit $$$OK
}

ClassMethod GetResponseClassList(pRequest As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = OnRequest, Internal ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnRequest",$$$cMETHformalspecparsed)
	Set tRequestClass=$lg($lg(tSignature,1),2)
	Set tClass=$lg($lg(tSignature,2),2)
	Do %code.WriteLine(" If pRequest=""""||(pRequest="""_tRequestClass_""") Quit $lb("""_tClass_""")")
	Do %code.WriteLine(" Quit """"")
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%AddToSaveSet</METHOD> method to 
/// provide notification that the current object is being included in a SaveSet, either
/// because %Save() was invoked on this object or an object that references this object.
/// 
/// <P>If this method returns an error status then %Save() will fail and the transaction
/// will be rolled back.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Internal, Private, ProcedureBlock = 1 ]
{
	#; Discard local copy of primary request & response headers because other jobs may have saved changes to them and we don't want to overwrite them
	Do ..%PrimaryRequestHeaderSetModified(0)
	Do ..%PrimaryResponseHeaderSetModified(0)
	
	#; Ensure a save of the %response body because our storage model doesn't make it happen automatically. We might be doing %Save() to sleep while waiting for a response to a call to get more information to populate the %response object.
	Set tResponse=..%response
	Quit:'$IsObject(tResponse) $$$OK
	Quit tResponse.%AddToSaveSet(depth)
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 0) As %Status [ Internal ]
{
	Set:'$TLEVEL tTransactionSuspendedSwitch = ##class(Ens.Util.Purge.SuspendTransaction).%New($$$EnsPurgeJournalOldDataGet)

	New %tDoNotDeleteDate,%tClass,%tID Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set tSC=$$$OK, SQLCODE=0, pDeletedCount=0
	If pKeepIntegrity {
		&sql(DECLARE ISCC1 CURSOR FOR
			Select BP.ID, $Piece(BP.x__ClassName,'~',$Length(BP.x__ClassName,'~')-1) As Class Into :%tID,:%tClass
				From
					Ens.BusinessProcess BP
				Where
					BP.ID<=(Select MAX(BP2.ID) From Ens.BusinessProcess BP2 Where BP2.%TimeCreated < :%tDoNotDeleteDate) 
					AND
					( (BP.%IsCompleted=1)
					OR 
					(BP.%TimeCreated IS NULL) )
			)
		&sql(OPEN ISCC1) For { &sql(FETCH ISCC1)  Quit:SQLCODE
			Set tExists=$G(aClass(%tClass))
			If 0'=tExists {
				try {
					Set tSC1=$classmethod(%tClass,"%DeleteId",%tID)
					Set:""=tExists aClass(%tClass)=1, tExists=1
				} catch ex {
					Set:""=tExists aClass(%tClass)=0  
					if ex.Name = "<CLASS DOES NOT EXIST>" {
						Set tSC1 = $$$ERROR($$$ClassDoesNotExist, %tClass)
					} else {
						Set:'$G(aClass(%tClass,"doneErr")) tSC1=$$$SystemError
					}
				}
				If $$$ISERR(tSC1)&&'$G(aClass(%tClass,"doneErr")) {
					Set tOK=$$$StatusEquals(tSC1,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError,$$$ClassDoesNotExist)
					If 'tOK { Set aClass(%tClass,"doneErr")=1, tSC=$$$ADDSC(tSC,tSC1)  $$$LOGWARNING("Failed to purge ID "_%tID_", Class='"_%tClass_"':"_$$$StatusDisplayString(tSC1)) }
				}
				Set pDeletedCount=pDeletedCount+$$$ISOK(tSC1)
			}
		} Set tCode=SQLCODE &sql(CLOSE ISCC1) Set:'SQLCODE SQLCODE=tCode
	} Else {
		&sql(DECLARE ISCC2 CURSOR FOR
			Select ID, $Piece(x__ClassName,'~',$Length(x__ClassName,'~')-1) As Class Into :%tID,:%tClass
				From Ens.BusinessProcess Where %TimeCreated < :%tDoNotDeleteDate)
		&sql(OPEN ISCC2) For { &sql(FETCH ISCC2)  Quit:SQLCODE
			Set tExists=$G(aClass(%tClass))
			If 0'=tExists {
				try {
					Set tSC1=$classmethod(%tClass,"%DeleteId",%tID)
					Set:""=tExists aClass(%tClass)=1, tExists=1
				} catch ex {
					Set:""=tExists aClass(%tClass)=0  
					if ex.Name = "<CLASS DOES NOT EXIST>" {
						Set tSC1 = $$$ERROR($$$ClassDoesNotExist, %tClass)
					} else {
						Set:'$G(aClass(%tClass,"doneErr")) tSC1=$$$SystemError
					}
				}
				If $$$ISERR(tSC1)&&'$G(aClass(%tClass,"doneErr")) {
					Set tOK=$$$StatusEquals(tSC1,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError,$$$ClassDoesNotExist)
					If 'tOK { Set aClass(%tClass,"doneErr")=1, tSC=$$$ADDSC(tSC,tSC1)  $$$LOGWARNING("Failed to purge ID "_%tID_", Class='"_%tClass_"':"_$$$StatusDisplayString(tSC1)) }
				}
				Set pDeletedCount=pDeletedCount+$$$ISOK(tSC1)
			}
		} Set tCode=SQLCODE &sql(CLOSE ISCC2) Set:'SQLCODE SQLCODE=tCode
	}
	Set:SQLCODE&&(SQLCODE'=100) tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID_"; SQLCODE = "_SQLCODE))
	Kill tTransactionSuspendedSwitch
	Quit tSC
}

/// The same as %Id(), but allocates the Id even if the object hasn't been saved already
Method getId() As %String [ CodeMode = generator, Internal ]
{
	$$$GENERATE(" If ..%Id()="""" Do ..%IdSet($increment("_$$$EXTidlocation($$$pEXT,%class)_"))")
	$$$GENERATE(" Quit ..%Id()")
	Quit $$$OK
}

/// This method returns the deferred response token, and marks the current message handling to be deferred
/// After the message is deferred, the current BS will become complete even without the response to be sent
Method DeferResponse(ByRef pToken As %String) As %Status
{
	Set pToken=..GetDeferredResponseToken(..%PrimaryRequestHeader)
	Set ..%RepliedStatus=$$$eRepliedStatusDeferred
	Quit $$$OK
}

/// Common code for debug output of completion key in pending responses
Method catTraceCompletionKeys() [ Internal ]
{
	Set tMPRKey="", tEntry = ..%MasterPendingResponses.GetNext(.tMPRKey)
	While (tMPRKey'="") {
		$$$unconditionalCatTRACE("bproc","%MasterPendingResponses contains completion key: "_tEntry.CompletionKey,tShowCat)
		Do ..%MasterPendingResponses.%UnSwizzleAt(tMPRKey)
		If 'tShowCat Return
		Set tEntry = ..%MasterPendingResponses.GetNext(.tMPRKey)
	}
}

Storage Default
{
<Data name="%MessagesReceived">
<Attribute>%MessagesReceived</Attribute>
<Structure>subnode</Structure>
<Subscript>"received"</Subscript>
</Data>
<Data name="%MessagesSent">
<Attribute>%MessagesSent</Attribute>
<Structure>subnode</Structure>
<Subscript>"sent"</Subscript>
</Data>
<Data name="BusinessProcessDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%ConfigQueueName</Value>
</Value>
<Value name="3">
<Value>%IsCompleted</Value>
</Value>
<Value name="4">
<Value>%MasterPendingResponsesOld</Value>
</Value>
<Value name="6">
<Value>%PrimaryRequestHeader</Value>
</Value>
<Value name="7">
<Value>%PrimaryResponseHeader</Value>
</Value>
<Value name="8">
<Value>%RepliedStatus</Value>
</Value>
<Value name="9">
<Value>%responseId</Value>
</Value>
<Value name="10">
<Value>Adapter</Value>
</Value>
<Value name="11">
<Value>%SessionId</Value>
</Value>
<Value name="12">
<Value>%TimeCompleted</Value>
</Value>
<Value name="13">
<Value>%TimeCreated</Value>
</Value>
<Value name="14">
<Value>%ConfigName</Value>
</Value>
<Value name="15">
<Value>%QuitTask</Value>
</Value>
<Value name="16">
<Value>AlertOnError</Value>
</Value>
<Value name="17">
<Value>%responseClassName</Value>
</Value>
<Value name="18">
<Value>%IsTimerInterrupted</Value>
</Value>
<Value name="19">
<Value>%IsTerminated</Value>
</Value>
<Value name="20">
<Value>%StatusCode</Value>
</Value>
<Value name="21">
<Value>%MessagesReceivedOld</Value>
</Value>
<Value name="22">
<Value>%MessagesSentOld</Value>
</Value>
<Value name="23">
<Value>ReplyCodeActions</Value>
</Value>
<Value name="24">
<Value>RetryInterval</Value>
</Value>
<Value name="25">
<Value>AlertRetryGracePeriod</Value>
</Value>
<Value name="26">
<Value>FailureTimeout</Value>
</Value>
<Value name="27">
<Value>Retry</Value>
</Value>
<Value name="28">
<Value>SuspendMessage</Value>
</Value>
<Value name="29">
<Value>QueueCountAlert</Value>
</Value>
<Value name="30">
<Value>QueueWaitAlert</Value>
</Value>
<Value name="31">
<Value>InactivityTimeout</Value>
</Value>
<Value name="32">
<Value>BusinessPartner</Value>
</Value>
<Value name="33">
<Value>AlertGroups</Value>
</Value>
<Value name="34">
<Value>%SuperSession</Value>
</Value>
</Data>
<DataLocation>^Ens.BusinessProcessD</DataLocation>
<DefaultData>BusinessProcessDefaultData</DefaultData>
<IdLocation>^Ens.BusinessProcessD</IdLocation>
<IndexLocation>^Ens.BusinessProcessI</IndexLocation>
<StreamLocation>^Ens.BusinessProcessS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
