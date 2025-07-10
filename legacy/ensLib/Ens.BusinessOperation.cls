/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

Class Ens.BusinessOperation Extends (Ens.Host, Ens.Util.IOLogger) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Property %RequestHeader As Ens.MessageHeader;

/// <p>A comma-separated list of codes specifying what action this Operation will take on various reply status conditions. 
/// The format of the list is: <br/> &lt;code&gt;=&lt;actions&gt;,(&lt;code&gt;,&lt;code&gt;)=&lt;actions&gt;,...<br/>
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
/// <li><b>D</b> - Disable the Operation, log an error and restore the message to the front of the Operation's queue.</li>
/// <li><b>F</b> - Fail with an error and move on to try the next message from the Operation's queue subject to the <property>Retry</property>
/// property value set in the code. If the Retry property is set in the code then moving on to try the next message will be subject to 
/// the configured RetryInterval and FailureTimeout.</li></ul>
/// An example of a valid ReplyCodeActions specification is 'E#6301=R,E#&lt;Ens&gt;ErrGeneral=RD,E=F'. This specification will result in a 
/// retry when error code 6301 is encountered. When error code &lt;Ens&gt;ErrGeneral is encountered, the Operation first retries to send 
/// the message until FailureTimeout and then, if the error continues, it disables the Operation instead of failing. Any other errors will 
/// cause the Operation to fail processing of the current message and return the error status to the caller, without retrying first
/// unless the property Retry has been set to true by the operation code.</p>
/// <p><b>The default behavior is equivalent to 'E=F'.</b> If the Retry property has been set by the Operation code then retrying will be subject to 
/// the configured RetryInterval and FailureTimeout.</p>
/// <p>All codes where &lt;actions&gt; consists of only 'W' (for 'log a Warning') will be evaluated, and a warning will be
/// generated for each matching &lt;code&gt;. Other &lt;code&gt; values will be evaluated in left-to-right order, executing the
/// first matching &lt;code&gt; that has a non-warning &lt;actions&gt; value. As noted in the details for the 'W' flag, an error
/// that only triggers 'W' &lt;actions&gt; will be treated as Completed OK.</p>
Property ReplyCodeActions As %String(MAXLEN = 1000);

/// How frequently to retry access to the output system
Property RetryInterval As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// When AlertOnError is True, and the Operation is retrying,
/// refrain from alerting if the Operation succeeds within this number of seconds after an error
Property AlertRetryGracePeriod As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

/// Total number of seconds to keep trying to deliver the message. <br>
/// After this number of seconds has elapsed, the business operation discards the message data and returns an error code. <br>
/// To ensure that no message is ever skipped, enter a Failure Timeout value of -1, which means 'Never time out'. <br>
/// Use a setting of -1 when complete data delivery is critical, for example in health care applications. 
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

/// <p>Flag whether the  %SuperSession property ought to be included in the outbound message.</p>
/// <p>Including the Super Session in the outbound message depends on the transport mechanism.</p>
/// <p>InterSystems IRIS supports automatically including the %SuperSession in the HTTP Headers for
/// both the HTTP and SOAP Outbound Adapters based on this setting.</p>
/// <p>For other transport mechanisms custom code can call the host operation API: <METHOD>IncludeSuperSession</METHOD>(.tSC)
/// and then use as appropriate the host property value of <PROPERTY>%SuperSession</PROPERTY> if IncludeSuperSession
/// API returns true.</p>
/// <p>The IncludeSuperSession() API returns true if the operation ought to send a super session based on this
/// host setting of SendSuperSession and the %SuperSession property is not empty.</p>
/// <p>The IncludeSuperSession() API will populate the host property <PROPERTY>%SuperSession</PROPERTY>
/// with either a generated Super Session or leave it with the Super Session passed to it with the request.</p>
/// <p>The IncludeSuperSession() API will return false if either SendSuperSession
/// is false or there was an error generating the super session (tSC will be populated accordingly).</p>
/// Example use in custom adapter Code: <br>
/// <pre>
/// #dim tSC As %Status = $$$OK
/// If ..BusinessHost.IncludeSuperSession(.tSC) {
///  /*
/// 	  code to include ..BusinessHost.%SuperSession in output
/// 	  based on transport mechanism.
///  */	
/// }</pre>
/// <p>See also Host methods <method>GenerateSuperSession</method> and <method>OnGenerateSuperSession</method></p>
Property SendSuperSession As %Boolean;

Parameter SETTINGS = "ReplyCodeActions,RetryInterval,AlertRetryGracePeriod:Alerting,FailureTimeout,QueueCountAlert:Alerting,QueueWaitAlert:Alerting,SendSuperSession";

/* Add this property to your SETTINGS list if your Adapter has a property 'Connected' and you want to expose this feature */
/// Suspend counting seconds toward FailureTimeout while disconnected.<br/>
/// Does not apply if FailureTimeout=-1 or StayConnected=0.
Property NoFailWhileDisconnected As %Boolean;

/// Set this property to 1 if you want to retry the current message again
Property Retry As %Boolean [ InitialExpression = 0 ];

/// Set this property to 1 if you want to mark the current message as "Suspended"
Property SuspendMessage As %Boolean [ InitialExpression = 0 ];

/// Set this property to 1 if you want to defer the response to the current message so that it can be completed asynchronously at a later time by a other code (usually a business service).
Property DeferResponse As %Boolean [ InitialExpression = 0 ];

/// Time from which to start Alert retry grace period
Property %AlertStartTime As %String;

/// how many times have we retried?
Property RetryCount As %Integer [ InitialExpression = 0 ];

/// Subclasses can store hint values here for use in determining what ReplyCodeAction to apply
Property %ActionHint [ Internal, MultiDimensional ];

Method MessageHeaderHandler(pRequestHeader As Ens.MessageHeader, Output pResponseHeader As Ens.MessageHeader) As %Status [ Internal ]
{
	Set $EC="",(tSC,tSCSuspend)=$$$OK, tAborted=0, pResponseHeader=$$$NULLOREF, tDoAlert=""
	try {
#If ..#INVOCATION="InProc"
		Set tParentHeaderId = $get($$$JobCurrentHeaderId)
#EndIf
		Set ..%RequestHeader=pRequestHeader, $$$JobCurrentHeaderId = pRequestHeader.%Id()
		If pRequestHeader.MessageBodyClassName'="" {
			Set tRequest = $classmethod(pRequestHeader.MessageBodyClassName,"%OpenId",pRequestHeader.MessageBodyId,,.tSC)
			If '$IsObject(tRequest) Set tSC=$$$ERROR($$$EnsErrGeneral,"Could not open MessageBody "_pRequestHeader.MessageBodyId_" for MessageHeader #"_pRequestHeader.%Id()_" with body class "_pRequestHeader.MessageBodyClassName_":"_$$$StatusDisplayString(tSC))  Quit
		} Else {
			Set tRequest=$$$NULLOREF, tSC=$$$ERROR($$$EnsErrGeneral,"No MessageBody classname for MessageHeader #"_pRequestHeader.%Id())  Quit
		}
		Do ##class(Ens.Util.Statistics).InitStats(..%ConfigName)
		Set tConfigName = ..%ConfigName, tResponse = $$$NULLOREF
		Do pRequestHeader.SetStatus($$$eMessageStatusDelivered)
		Set (..%SessionId,$$$JobSessionId) = pRequestHeader.SessionId
		Set ..%SuperSession=pRequestHeader.SuperSession

		Set (tEndTime,..%LastReportedError)="", ..RetryCount=1, (..Retry,..SuspendMessage,..DeferResponse,..%AlertStartTime,tFailureTimedOut,tTerminate)=0
		While 1 { ; Retry loop
			Set tTimeCalled=$ZH, tDoAlert=""
			Set:'tEndTime tEndTime = tTimeCalled + ..FailureTimeout

			#; Handle message body
			If $D($$$EnsCrashedMessage(pRequestHeader.%Id())) {
				Kill $$$EnsCrashedMessage(pRequestHeader.%Id())
				Set tSC=$$$EnsError($$$EnsErrPreviouslyCrashedMessage,pRequestHeader.%Id())
			} Else {
				Set tSC=..MessageHandler(tRequest,.tResponse)
			}
			If $$$ISERR(tSC) {
				Set $EC=""  try {
					$$$sysTRACE("calling OnError R")
					Set tDoAlert=..OnError(.tSC)
				} catch {
					Set tSC=$$$ADDSC(tSC,$$$EnsSystemError), tDoAlert=1
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnError() R; committing before proceeding")
			}
			Set $EC=""  try {
				Set tMHSC=tSC
				Set tAction=..OnGetReplyAction(tRequest,.tResponse,.tSC)
				Set:""'=tAction tSC=..doReplyAction(tAction, tRequest,.tResponse,tSC)
				If tSC'=tMHSC&&$$$ISERR(tSC) {
					$$$sysTRACE("calling OnError A")
					Set tDoAlert=..OnError(.tSC)
				}
			} catch {
				Set tSC=$$$ADDSC(tSC,$$$EnsSystemError), tDoAlert=1
			}
			If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after ReplyAction OnError() A; committing before proceeding")
			If ..SuspendMessage {
				Set tSCSuspend=tSC
				Set tSC=$$$ERROR($$$EnsErrSuspending,pRequestHeader.%Id(),$$$StatusDisplayString(tSC))
				Quit
			}
			Quit:..DeferResponse
			Quit:'..Retry
			Set ..Retry=0

			If $$$ISERR(tSC) {
				Set tTxt=$P($$$StatusDisplayString(tSC)," -- ") ; strip off "logged as" varying text
				Set:'..%AlertStartTime&&..AlertOnError&&..AlertRetryGracePeriod&&(tTxt'=..%LastReportedError) ..%AlertStartTime=$ZH
				If ..%AlertStartTime {
					If $ZH>=(..%AlertStartTime+..AlertRetryGracePeriod) {
						Set ..%AlertStartTime=0
						If tTxt'=..%LastReportedError { $$$LOGERROR("Alerting at expiration of retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
						Else { $$$LOGINFO("Alerting at expiration of retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
					} Else {
						Set tDoAlert=0
						If tTxt'=..%LastReportedError { $$$LOGERROR("Not Alerting during retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
						Else { $$$LOGINFO("Not Alerting during retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
					}
				} Else {
					If tTxt'=..%LastReportedError { $$$LOGSTATUS(tSC) }
					Else { Set tDoAlert=0 }
				}
				Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSC))))
				Set tDoAlert=0
			} Else { Set ..%AlertStartTime=0, tTxt="" }
			Set ..%LastReportedError=tTxt

			If ..%QuitTask { Set tTerminate=1 }
			Else {
				If ..FailureTimeout'=-1 {
					Set tNow=$ZH
					If ..NoFailWhileDisconnected {
						try { Set tStayConnected=..Adapter.StayConnected }
						catch { Set tStayConnected=1 }
						If tStayConnected {
							try { Set tConnected=..Adapter.Connected }
							catch { Set tConnected=1 }
							If 'tConnected {
								If tNow>tEndTime $$$sysTRACE("Ignoring FailureTimeout while disconnected")
								Set:$G(tLast) tEndTime=tEndTime+(tNow-tLast) ; keep up with our disconnected time
								Set tLast=tNow
							} ElseIf $G(tLast) {
								#; give it time for at least one retry so we don't die immediately on reconnecting
								Set tMinInterval=..RetryInterval+1  Set:..FailureTimeout<..RetryInterval&&(..FailureTimeout>0) tMinInterval=..FailureTimeout+1
								If tEndTime-tNow<tMinInterval $$$sysTRACE("Extending FailureTimeout by "_(tNow+tMinInterval-tEndTime)_" after reconnecting")  Set tEndTime=tNow+tMinInterval
								Kill tLast
							}
						}
					}
					If tNow>tEndTime {
						Set tFailureTimedOut=1, tSC=$$$ERROR($$$EnsErrFailureTimeout, ..FailureTimeout, $$$StatusDisplayString(tSC), $$$CurrentClass), tDoAlert=""
						Set $EC=""  try {
							Set tMHSC=tSC
							Set tDoDefault=..OnFailureTimeout(tRequest,.tResponse,.tSC)
							Set:tDoDefault tSC=$S(""=tAction:tSC,1:..finalReplyAction(tAction,tSC,1))
							Set:tSC'=tMHSC&&$$$ISERR(tSC) tDoAlert=""
							/*	If default finalReplyAction or custom OnFailureTimeout
								set %QuitTask we need to act on sending an alert here
								since quitting (disabling) leads to terminate
								flag and exiting before send alert check.
							*/
							Do:(..%QuitTask && $$$ISERR(tSC) && ..AlertOnError) ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSC))))
						} catch {
							Set tSC=$$$ADDSC(tSC,$$$EnsSystemError), tDoAlert=""
						}
						If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnFailureTimeout(); committing before proceeding")
						Set:..SuspendMessage tSCSuspend=tSC
						/*	We enter this "If ..FailureTimeout'=-1" with ..Retry set back to 0 and ..%QuitTask at 0.
							If sub class modifies either ..Retry or ..%QuitTask in OnFailureTimeout then need to honour.
							For example if a subclass wants to retry again and delay the final action.
							finalReplyAction will set both ..Retry and ..%QuitTask to non zero if final action is D(isable)
						*/
						Quit:('..%QuitTask&&'..Retry)
					}
				}
				If ..%QuitTask { Set tTerminate=1 }
				Else {
					$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Retry")
#If ..#INVOCATION="Queue"
					$$$SetJobMonitor(tConfigName,$$$SystemName_":"_$Job,$$$eMonitorStatus,"Retry")
#EndIf
					Set tWaitTime = tTimeCalled + ..RetryInterval - $ZH
					Set tSC1=##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,$S(tWaitTime<0:0, 1:tWaitTime),,0)  If $$$ISERR(tSC1) Set tSC=$$$ADDSC(tSC,tSC1)  Quit
					Set tTerminate=##class(Ens.Job).ShouldTerminate()
				} ; %QuitTask
			} ; %QuitTask
			Set tSBQ=##class(Ens.Job).ShouldBeQuiescent()
			If tSBQ || tTerminate {
				If pRequestHeader.Priority>$$$eMessagePrioritySync||tTerminate {
					Set tTerminate=1
					If 'tFailureTimedOut||(..%QuitTask>1) {
						If pRequestHeader.TargetQueueName="" {
							/* 
								If no target queue name then we cannot put back to queue.
								Double check invocation InProc and mark so we will RecoverActiveMessage() later			
							*/
							If pRequestHeader.Invocation=$$$eMessageInvocationInProc {
								#; Keep the original error. Caller will handle error.
								#dim tActiveID As %String
								#dim tSCActive As %Status
								If $Data($$$EnsActiveMessage($$$SystemName_":"_$Job),tActiveID) {
									$$$LOGINFO("Retry loop exited due to shutdown request for message "_..%RequestHeader.%Id()_" ; re-queueing corresponding Active Message:"_tActiveID_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))								
									Set tSCActive = ##class(Ens.Job).RecoverActiveMessage(tActiveID,$Job,0)
									If $$$ISOK(tSCActive) Kill $$$EnsActiveMessage($$$SystemName_":"_$Job)
								} Else {
									$$$LOGERROR("Retry loop exited due to shutdown request for message "_..%RequestHeader.%Id()_" ; cannot re-queue corresponding Active Message since it is not defined"_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))
								}
							} Else {
								$$$LOGERROR("Retry loop exited due to shutdown request for message "_..%RequestHeader.%Id()_" ; cannot re-queue since no target queue name and not InProc"_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))
							}
						} Else {
							#; blow away the original error (prevent error response) if self-disabling or shutting down while retrying
							Set tSCx=tSC, tSC=##class(Ens.Queue).PutBackToQueue(pRequestHeader)
							$$$LOGINFO("Retry loop exited due to shutdown request for message "_..%RequestHeader.%Id()_" ; re-queueing"_$S($$$ISOK(tSCx):"",1:" - original error: "_$$$StatusDisplayString(tSCx)))
						}
					} Else {
						$$$LOGINFO("Retry loop exited due to shutdown request for message "_..%RequestHeader.%Id()_" ; quitting with status "_$$$StatusDisplayString(tSC))
					}
					Quit
				}
				$$$LOGINFO("Ignoring "_$S(tSBQ:"Quiescent",1:"Terminate")_" request while processing high priority (i.e. synchronous) request "_..%RequestHeader.%Id())
			}
			If ##class(Ens.Job).ShouldAbort() {
				$$$LOGWARNING("Message "_..%RequestHeader.%Id()_" aborted as requested by signal for job "_$J_$S($$$ISOK(tSC):"",1:" - original error: "_$$$StatusDisplayString(tSC)))
				Set tSC=$$$OK, tAborted=1
				Quit
			}
			If ##class(Ens.Job).ShouldSuspend() {
				$$$LOGWARNING("Message "_pRequestHeader.%Id()_" suspended as requested by signal for job "_$J_$S($$$ISOK(tSC):"", 1:" - original error: "_$$$StatusDisplayString(tSC)))
				Set tSC=$$$OK, ..SuspendMessage=1
				Quit
			}
			Set ..RetryCount=..RetryCount+1
			$$$SetJobMonitor(tConfigName,$$$SystemName_":"_$Job,$$$eMonitorRetry,..RetryCount)
			$$$sysTRACE("Retrying Request Header Id "_pRequestHeader.%Id()_" - try #"_..RetryCount)
		} ; Retry loop

		$$$SetJobMonitor(tConfigName,$$$SystemName_":"_$Job,$$$eMonitorRetry,"")

		If $$$ISERR(tSC) {
			If ""=tDoAlert {
				Set $EC=""  try {
					$$$sysTRACE("calling OnError E")
					Set tDoAlert=..OnError(.tSC)
				} catch {
					Set tSC=$$$ADDSC(tSC,$$$EnsSystemError), tDoAlert=1
				}
				If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnError() E; committing before proceeding")
			}
			Quit:'..SuspendMessage&&'..DeferResponse
		}
		Quit:tTerminate

		#; update global statistics
		Set tConfigName=..%ConfigName
		$$$IncHostCounterTime(tConfigName)

		#; local stats
#If ..#INVOCATION="Queue"
		$$$IncJobCounterTime(tConfigName,$$$SystemName_":"_$Job)
#EndIf
		If tAborted {
			Do pRequestHeader.SetStatus($$$eMessageStatusAborted)
			Quit
		}
		If ..SuspendMessage {
			Do pRequestHeader.SetStatus($$$eMessageStatusSuspended)
			If $$$ISERR(tSC) {
				If $$$ISERR(tSCSuspend) { $$$LOGSTATUS(tSC) }
				Else { $$$LOGWARNING($$$StatusText(tSC)) }
			}
			Set tSC=$$$OK
			Quit
		}
		If ..DeferResponse {
			Do pRequestHeader.SetStatus($$$eMessageStatusDeferred)
			If $$$ISERR(tSC) {
				$$$LOGWARNING("Deferring Response to Request "_pRequestHeader.%Id()_"; Operation returned error "_$$$StatusDisplayString(tSC))
				Set tSC=$$$OK
			} Else {
				$$$sysTRACE("Deferring Response to Request "_pRequestHeader.%Id())
			}
			Quit
		}
		Do pRequestHeader.SetStatus($$$eMessageStatusCompleted)

		If $$$ISOK(tSC) && pRequestHeader.needsReply() {
			Set tSC=pRequestHeader.NewResponseMessage(.pResponseHeader,tResponse,..%SuperSession)
		}
	} catch {
		Set tSC=$$$EnsSystemError, tDoAlert=1
	}
	If $$$ISERR(tSC) {
		Set:(tDoAlert="") tDoAlert = ..OnError(tSC)
		Set tTxt=$P($$$StatusDisplayString(tSC)," -- ") ; strip off "logged as" varying text
		If tTxt'=..%LastReportedError { $$$LOGSTATUS(tSC) }
		Set ..%LastReportedError=tTxt

		Set tConfigName=..%ConfigName
		$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Error")
#If ..#INVOCATION="Queue"
		$$$SetJobMonitor(tConfigName,$$$SystemName_":"_$Job,$$$eMonitorStatus,"Error")
#EndIf
		Do:'tAborted pRequestHeader.SetStatus($$$eMessageStatusError)
		Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSC))))
	} ElseIf ..SuspendMessage&&$$$ISERR(tSCSuspend) {
		Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSCSuspend))))
	}
	Set ..%SessionId=""
	Set ..%SuperSession=""
	Do ##class(Ens.Util.Statistics).RecordStats($$$eHostTypeOperation,..%ConfigName)
#If ..#INVOCATION="Queue"
	Kill $$$JobSessionId
	Kill $$$JobCurrentHeaderId
#ElseIf ..#INVOCATION="InProc"
	Set $$$JobCurrentHeaderId = $get(tParentHeaderId)
#EndIf
	Set ..%RequestHeader=$$$NULLOREF
	Quit tSC
cleanNum(str)
	Set f=0  For { Set f=$F(str,"#",f)  Quit:'f
		For i=f:1 { Quit:$E(str,i)'?1N  Set $E(str,i)="",i=i-1 }
	}
	Quit str
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
			Quit:tFullAction'?1."W"
		}
	}
	Set:""'=tText ..%ActionHint("CodeReason")=
		"Message body "_pRequest_" / "_pRequest.%Id()_" because "_
		$S('$IsObject(pResponse):"",1:"response "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" ")_
		tText_" resulting in Action code "_tFullAction
	Quit tFullAction
}

/// Do the specified action for taking care of the message currently being processed
Method doReplyAction(pAction As %String, pRequest As %Library.Persistent, pResponse As %Library.Persistent, ByRef pSC As %Status) As %Status [ Internal ]
{
	Set tText=$G(..%ActionHint("CodeReason"))
	Set:""=tText tText="Message body "_pRequest_" / "_pRequest.%Id()_" because response '"_$G(pResponse)_$S($$$IsdefObject(pResponse)&&(""'=pResponse.%Id()):"' / "_pResponse.%Id(),1:"'")_" and error '"_$$$StatusDisplayString(pSC)_"' resulted in action code '"_pAction_"'"

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
#If ..#INVOCATION="InProc"
		$$$LOGWARNING("InProc '"_..%ConfigName_"' cannot invoke action 'D' (Disable)")
#Else
		Set:($ZS<$$$MAXBBSZ) $ZS=$$$MAXBBSZ
		Set tActionDesc="Disabling on"
		Do ##class(Ens.Job).Stop($Job)
		Do ##Class(Ens.Director).EnableConfigItem(..%ConfigName,0,0)
		Do ..SendRequestAsync("Ens.ScheduleHandler",$$$NULLOREF)
		Set ..%QuitTask=1+(pAction'["F"), ..Retry=1 ; we are quitting but the retry flag will force us to requeue the current message
#EndIf
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

/// This method will be called within KeepaliveInterval of the last return from OnTask() or OnKeepalive().
/// It is called via the Adapter's OnKeepalive() method, which is called from the Host.OnTask() method;
/// if there is no Adapter there is no keepalive call.
Method OnKeepalive(pAdapterStatus As %Status) As %Status
{
	Set tSC=pAdapterStatus
	If $$$ISERR(tSC) {
		$$$sysTRACE("calling OnError K")
		Set tDoAlert=..OnError(.tSC)
		If $$$ISERR(tSC) {
			Set tTxt=$P($$$StatusDisplayString(tSC)," -- ") ; strip off "logged as" varying text
			Set:'..%AlertStartTime&&..AlertOnError&&..AlertRetryGracePeriod&&(tTxt'=..%LastReportedError) ..%AlertStartTime=$ZH
			If ..%AlertStartTime {
				If $ZH>=(..%AlertStartTime+..AlertRetryGracePeriod) {
					Set ..%AlertStartTime=0
					If tTxt'=..%LastReportedError { $$$LOGERROR("Alerting at expiration of retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
					Else { $$$LOGINFO("Alerting at expiration of retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
				} Else {
					Set tDoAlert=0
					If tTxt'=..%LastReportedError { $$$LOGERROR("Not Alerting during retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
					Else { $$$LOGINFO("Not Alerting during retry grace period ("_..AlertRetryGracePeriod_") for "_tTxt) }
				}
			} Else {
				If tTxt'=..%LastReportedError { $$$LOGSTATUS(tSC) }
				Else { Set tDoAlert=0 }
			}
			Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSC))))

			Set tConfigName=..%ConfigName
			$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Error")
#If ..#INVOCATION="Queue"
			$$$SetJobMonitor(tConfigName,$$$SystemName_":"_$Job,$$$eMonitorStatus,"Error")
#EndIf
			Set:'..%QuitTask tSC=$$$OK
		} Else { Set ..%AlertStartTime=0, tTxt="" }
	} Else { Set ..%AlertStartTime=0, tTxt="" }
	Set ..%LastReportedError=tTxt
	Quit tSC
}

/// This method dispatches requests to the methods according to the message map
Method MessageHandler(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status [ CodeMode = objectgenerator, Internal ]
{
	Do %code.WriteLine(" Set $ZE="""",$ZT=""Trap"",$EC="""",tSC=$$$OK")
	Do %code.WriteLine(" do {")
	Set tSC=$$$OK
	Do {
		Kill %EnsBPCompile(%ISCName,"MessageMap",%class.Name)
		#; Find and save the first arg type of the OnMessage() method for the current subclass
		Set tIndex = %compiledclass.Methods.FindObjectId(%class.Name_"||OnMessage")
		If ""'=tIndex,%compiledclass.Methods.GetAt(tIndex).Origin'="Ens.BusinessOperation" {
			Set tFormalSpec = %compiledclass.Methods.GetAt(tIndex).FormalSpec
			Set tMessageType=$P($P(tFormalSpec,",",1),":",2)
			Set tResponseType=$P($P(tFormalSpec,",",2),":",2)
			Set %EnsBPCompile(%ISCName,"MessageMap",%class.Name,0)=$lb(tMessageType,tResponseType)
		}
		Set tSC=$$resolveMessageMap(.tMappedMessages,%class,%compiledclass) Quit:$$$ISERR(tSC)
		Set iItem=0
		For tMessageCount=1:1:$g(tMappedMessages) {
			Set tMessageType=$li(tMappedMessages(tMessageCount),1)
			Set tActionMethod=$li(tMappedMessages(tMessageCount),2)
			Set tIndex = %compiledclass.Methods.FindObjectId(%class.Name_"||"_tActionMethod)
			If ""'=tIndex {
				Set tFormalSpec = %compiledclass.Methods.GetAt(tIndex).FormalSpec
				#; TODO: Check that the 1st arg type of the referenced method matches the MapItem MessageType and that it exists
				Set tResponseType=$P($P(tFormalSpec,",",2),":",2)
			} Else {
				Set tSC=$$$ERROR($$$GeneralError,"Method "_tActionMethod_" referenced in MessageMap does not exist")
				Quit
			}
			// Make sure to expand any omitted package using the current classes package
			Set:tMessageType'["." tMessageType = $P(%class.Name,".",1,$L(%class.Name,".")-1) _ "." _ tMessageType
			
			Set %EnsBPCompile(%ISCName,"MessageMap",%class.Name,$I(iItem))=$lb(tMessageType,tResponseType)
			Do %code.WriteLine(" If pRequest.%IsA("""_tMessageType_""") {")
			Do %code.WriteLine("  $$$NEWOUTIOLOGENTRY($$$OK,"""","""_tActionMethod_""",pRequest)")
			Do %code.WriteLine("  $$$SetJobMonitor(..%ConfigName,$$$SystemName_"":""_$Job,$$$eMonitorMethod,"""_tActionMethod_""")")
			Do %code.WriteLine("  Set tSC=.."_tActionMethod_"(.pRequest,.pResponse)")
			Do %code.WriteLine("  $$$SetJobMonitor(..%ConfigName,$$$SystemName_"":""_$Job,$$$eMonitorMethod,"""")")
			Do %code.WriteLine("  $$$sysTRACE("""_tActionMethod_"() returned with status ""_$$$StatusDisplayString(tSC)_"", Retry=""_..Retry_"", SuspendMessage=""_..SuspendMessage_"", DeferResponse=""_..DeferResponse_"", Response=""_$S('$$$IsdefObject(pResponse):"""", 1:pResponse_""/""_$S('pResponse.%Extends(""%Persistent""):"""", 1:pResponse.%Id())))")
			Do %code.WriteLine("  $$$CLOSEIOLOGENTRY(tSC,"""",$G(pResponse))")
			Do %code.WriteLine("  Quit")
			Do %code.WriteLine(" }")
		}
		Quit:$$$ISERR(tSC)
		;
		Do %code.WriteLine(" $$$NEWOUTIOLOGENTRY($$$OK,"""",""OnMessage"",pRequest)")
		Do %code.WriteLine(" $$$SetJobMonitor(..%ConfigName,$$$SystemName_"":""_$Job,$$$eMonitorMethod,""OnMessage"")")
		Do %code.WriteLine(" Set tSC=..OnMessage(.pRequest,.pResponse)")
		Do %code.WriteLine(" $$$SetJobMonitor(..%ConfigName,$$$SystemName_"":""_$Job,$$$eMonitorMethod,"""")")
		Do %code.WriteLine(" $$$sysTRACE(""OnMessage() returned with status ""_$$$StatusDisplayString(tSC)_"", Retry=""_..Retry_"", SuspendMessage=""_..SuspendMessage_"", DeferResponse=""_..DeferResponse_"", Response=""_$S('$$$IsdefObject(pResponse):"""", 1:pResponse_""/""_$S('pResponse.%Extends(""%Persistent""):"""", 1:pResponse.%Id())))")
		Do %code.WriteLine(" $$$CLOSEIOLOGENTRY(tSC,"""",pResponse)")
	} While 0
	;
	Do %code.WriteLine(" } While 0")
	Do %code.WriteLine("Exit")
	Do %code.WriteLine(" If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_"" open user transaction""_$S(tTL>1:""s"",1:"""")_"" found after BO MessageHandler method; committing before proceeding"")")
	Do %code.WriteLine(" Quit tSC")
	Do %code.WriteLine("Trap")
	Do %code.WriteLine(" Set $ZT="""",tSC=$$$SystemError")
	Do %code.WriteLine(" Goto Exit")
	;
	Quit tSC

resolveMessageMap(pMessages,pClassDefinition,pCompiledClass)
	If '$IsObject(pClassDefinition) Quit $$$OK
	If pClassDefinition.Name="Ens.BusinessOperation" Quit $$$OK
	New %tMapItems,%tCount,%tItem,%tSuperCount,%tSC,%tSuper
	Set %tSC=##class(Ens.Util.XML.Reader).ObjectsFromXData(.%tMapItems,pClassDefinition,"MessageMap","Ens.Config.MessageMap")
	If $$$ISERR(%tSC),$$$StatusEquals(%tSC,$$$EnsErrXDataBlockNotDefined) Set %tSC=$$$OK
	If $$$ISERR(%tSC) Quit %tSC
	If $IsObject(%tMapItems) {
		For %tCount=1:1:%tMapItems.Count() {
			Set %tItem=%tMapItems.GetAt(%tCount)
			If %tItem.MessageType="" Continue
			Set pMessages($i(pMessages))=$lb(%tItem.MessageType,%tItem.ActionMethod)
		}
	}
	If '$IsObject(pCompiledClass) Quit $$$OK
	For %tSuperCount=$l(pCompiledClass.Super,","):-1:1 {
		Set %tSuper=$piece(pCompiledClass.Super,",",%tSuperCount)
		If %tSuper'="" Set %tSC=$$resolveMessageMap(.pMessages,##class(%Dictionary.ClassDefinition).%OpenId(%tSuper),##class(%Dictionary.CompiledClass).%OpenId(%tSuper)) Quit:$$$ISERR(%tSC)
	}
	Quit %tSC
	;
}

/// This is the default message handler.  All request types not declared in the message map are delivered here
Method OnMessage(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status
{
	Quit $$$EnsError($$$EnsErrRequestNotHandled,pRequest)
}

/// Use this method to dispatch a business invocation synchronously
Method SendRequestSync(pTargetDispatchName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pTimeout As %Numeric = -1, pDescription As %String = "") As %Status
{
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tZH=$ZH
	Set tTargetConfigName = $get($$$DispatchNameToConfigName(pTargetDispatchName)) If tTargetConfigName="" Quit $$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)
	Set tTargetBusinessClass = $$$ConfigClassName(tTargetConfigName)
	Set tSC=$classmethod(tTargetBusinessClass,"acceptRequestSync",..%ConfigName,tTargetConfigName,.pRequest,.pResponse,..%SessionId,pTimeout,,pDescription,..%SuperSession)
	$$$catTRACE("timing","duration of sync call: "_($ZH-tZH))
	Quit tSC
}

/// Use this method to dispatch a business invocation asynchronously
Method SendRequestAsync(pTargetDispatchName As %String, pRequest As %Library.Persistent, pDescription As %String = "") As %Status
{
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tZH=$ZH
	Set tTargetConfigName = $get($$$DispatchNameToConfigName(pTargetDispatchName)) If tTargetConfigName="" Quit $$$EnsError($$$EnsErrBusinessDispatchNameNotRegistered,pTargetDispatchName)
	Set tTargetBusinessClass = $$$ConfigClassName(tTargetConfigName)
	Set tSC=$classmethod(tTargetBusinessClass,"acceptRequestAsync",..%ConfigName,tTargetConfigName,.pRequest,$$$eMessagePriorityAsync,"",..%SessionId,"",,pDescription,..%SuperSession)
	$$$catTRACE("timing","duration of async call: "_($ZH-tZH))
	Quit tSC
}

/// Override this method to provide custom handling of retry / failure timeout.<p/>
/// Set ..Retry=1 to override normal error return and re-evaluate flag properties.<p/>
/// Return 0 to skip further (default) FailureTimeout processing, 1 to perform default processing.
Method OnFailureTimeout(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent, ByRef pSC As %Status) As %Boolean [ CodeMode = expression ]
{
1
}

/// Override this method to provide custom error handling. Return 0 means skip standard AlertOnError behavior.
Method OnError(ByRef pStatus As %Status) As %Boolean
{
	Quit 1
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
		Set tSC = ..SendRequestAsync("Ens.Alert",pAlertRequest)
	}
	
	Quit tSC
}

/// This method returns the deferred response token, and marks the current message handling to be deferred
Method DeferResponse(ByRef pToken As %String) As %Status
{
	Set ..DeferResponse=1
	Set pToken=..GetDeferredResponseToken(..%RequestHeader)
	Quit $$$OK
}

ClassMethod GetMessageList() As %String
{
	Quit ..GetRequestClassList()
}

/// Return a collection in $List format of all Request classes found in OnMessage and in the Message Map method signatures
ClassMethod GetRequestClassList() As %String [ CodeMode = objectgenerator, GenerateAfter = MessageHandler, Internal ]
{
	Set i="" For {
		Set i=$Order(%EnsBPCompile(%ISCName,"MessageMap",%class.Name,i)) Quit:i=""
		Set tRequestClass=$li(%EnsBPCompile(%ISCName,"MessageMap",%class.Name,i),1)
		Set tMessageClassList(tRequestClass)=""
	}
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"OnMessage",$$$cMETHrunnable) {
		// Check the OnMessage signature for additional request types
		Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnMessage",$$$cMETHformalspecparsed)
		Set tRequestClass=$lg($lg(tSignature,1),2)
		Set tMessageClassList(tRequestClass)=""
	}
	;
	If %class.Name="Ens.BusinessOperation" {
		Do %code.WriteLine(" Quit """"")
	} Else {
		Do %code.WriteLine(" Set tList=""""")
		Set tRequestClass="" For { Set tRequestClass=$o(tMessageClassList(tRequestClass))  Quit:tRequestClass=""
			Do %code.WriteLine(" Set tList=tList_$lb("""_tRequestClass_""")")
		}
		Do %code.WriteLine(" Quit tList")
	}
	Quit $$$OK
}

/// Return a collection in $List format of all Response classes found in OnMessage and in the Message Map method signatures
ClassMethod GetResponseClassList(pRequest As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = GetRequestClassList, Internal ]
{
	If %class.Name="Ens.BusinessOperation" {
		Do %code.WriteLine(" Quit """"")
	} Else {
		Set i="" For { Set i=$Order(%EnsBPCompile(%ISCName,"MessageMap",%class.Name,i))  Quit:i=""
			Set tRequestClass=$li(%EnsBPCompile(%ISCName,"MessageMap",%class.Name,i),1)
			Set tResponseClass=$li(%EnsBPCompile(%ISCName,"MessageMap",%class.Name,i),2)
			Set tMessageClassList(tRequestClass,tResponseClass)=""
		}
		If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"OnMessage",$$$cMETHrunnable) {
			// Check the OnMessage signature for additional request/response types
			Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnMessage",$$$cMETHformalspecparsed)
			Set tRequestClass=$lg($lg(tSignature,1),2)
			Set tResponseClass=$lg($lg(tSignature,2),2)
			Set tMessageClassList(tRequestClass,tResponseClass)=""
		}
		Set (tRequestClass,tFullResponseClassList)="" For { Set tRequestClass=$o(tMessageClassList(tRequestClass))  Quit:tRequestClass=""
			Set (tResponseClass,tResponseClassList)="" For { Set tResponseClass=$o(tMessageClassList(tRequestClass,tResponseClass))  Quit:tResponseClass=""
				Set tResponseClassList=tResponseClassList_","""_tResponseClass_""""
			}
			Set tFullResponseClassList=tFullResponseClassList_tResponseClassList
			If ""'=tResponseClassList {
				Set tResponseClassList="$lb("_$e(tResponseClassList,2,*)_")"
				Do %code.WriteLine(" If pRequest="""_tRequestClass_""" Quit "_tResponseClassList)
			}
		}
		If ""'=tFullResponseClassList {
			Set tFullResponseClassList="$lb("_$e(tFullResponseClassList,2,*)_")"
			Do %code.WriteLine(" If pRequest="""" Quit "_tFullResponseClassList)
		}
		Do %code.WriteLine(" Quit """"")
	}
	Kill %EnsBPCompile(%ISCName,"MessageMap",%class.Name)
	Quit $$$OK
}

/// Returns true if have a super session that needs to be included in output.<br>
/// SendSuperSession setting needs to be true.<br>
/// <property>%SuperSession</property> will be generated if it is an empty string
/// and SendSuperSession is true.<br>
/// Returns error status as an output parameter.<br>
/// Method will return false if %SuperSession is empty string or an error.
Method IncludeSuperSession(Output pSC As %Status = {$$$OK}) As %Boolean
{
	If ..SendSuperSession {
		If ..%SuperSession="" {
			Set ..%SuperSession = ..GenerateSuperSession(..%RequestHeader,.pSC)
			If $$$ISERR(pSC)||(..%SuperSession="") Return 0
		}
		Return 1
	}
	Return 0
}

}
