/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This operation and its configuration control archiving of messages from a configured subset of the config items in the production, via the MessageHandler() method.
Class Ens.Enterprise.OperationBase Extends Ens.BusinessOperation [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "Ens.OutboundAdapter";

/// Comma-separated list of ConfigNames of items whose message traffic should be archived to the MsgBank server <br>
/// * means all items <br>
/// - at the front of an item means exclude it from archiving entirely <br>
/// ! at the end of an item means exclude message bodies from archiving <br>
/// $ at the end of an item means exclude SearchTable entries if any from archiving <br>
/// - at the end of an item means exclude message headers from archiving <p>
/// Log Events may be archived for each item using the following colon-separated syntax: <br>
/// item[evtype1:evtype2:Trace_cat] <p>
/// Within the event type brackets, <br>
/// * means all event types <br>
/// - in front of a type means exclude it from archiving <p>
/// For events of type Trace, _ can be optionally used to select a particular category of trace event. <br>
/// Event type Trace without a suffix means Trace events of all categories. <br>
/// For example, *[*] means archive everything, and *$[*],Ens.Alert![-*] means archive all events, headers and bodies but not SearchTable entries, except don't archive bodies or events from item Ens.Alert. <p>
/// Note that Trace events will only be archived if they have been logged. That is, these settings can only be used to restrict which logged events get archived, not to archive any events that were not configured to be logged.
Property ArchiveItems As %String(MAXLEN = "") [ InitialExpression = "*[*],-Ens.ScheduleService[*],-Ens.ScheduleHandler[*]" ];

/// Enable queueing of archive events from other Config Items. Unless this setting is True no messages will be queued for archiving. <br>
/// If this setting is True, messages will be queued for archiving even while this Operation is disabled. <br>
/// All messages configured to be archived will be queued to this Operation for archiving. This Operation will forward them to the MsgBank server whenever it is enabled.
Property EnableArchiving As %Boolean;

Parameter SETTINGS = "ArchiveItems:Basic,EnableArchiving:Basic";

/// How frequently should we check for conforming EventLog events that may need to be forwarded to the MsgBank Server. <br>
/// 0 means check only when messages are being forwarded.
Property EventLogInterval As %Numeric [ InitialExpression = 0 ];

/// Are we archiving any events at all?
Property %anyEvents As %Boolean [ InitialExpression = 0, Internal ];

/// Array controlling which events we are archiving
Property %events [ Internal, MultiDimensional ];

/// Banked flags as passed from sending config item. Uses same values as Ens.MessageHeader.Banked : Header=1, Body=2, SearchTable=4, all=7
Property %Flags As %Integer [ Internal ];

/// Source flag as passed from sending config item: 0=from no Config Item, 1=from SourceConfigItem, 2=TargetConfigItem, 3=Other
Property %Source As %Integer [ Internal ];

Property %rsSearchCount As %ResultSet [ Internal ];

Property %rsSearchFetch As %ResultSet [ Internal ];

Property %lastFetchSQL As %String [ Internal ];

Property %lastCountSQL As %String [ Internal ];

Property %hdrLocked As %Boolean [ Internal ];

/// flag set at in OnInit to show if more than
/// one job. This is not dynamic to aid
/// performance. ie need to restart item if
/// changing single to multiple or vice versa.
Property %isSingleJob As %Boolean [ Internal ];

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	Do ..initEventFlags()
	Set ..%rsSearchCount=##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set ..%rsSearchFetch=##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set ..Adapter.KeepaliveInterval=..EventLogInterval
	Set ..%isSingleJob =  ($$$ConfigPoolSize(..%ConfigName) = 1)
	Quit ##super()
}

/// This is the default message handler.  All request types not declared in the message map are delivered here
Method OnMessage(pRequest As Ens.MessageHeader, Output pResponse As %Library.Persistent) As %Status
{
	$$$ASSERT(0_"Subclass responsibility")
	;Lock -^Ens.MsgBank.Banked(pRequest.%Id())  Set ..%hdrLocked=0 ; we've stored the Banked flag - now it's safe for another job to open the header object
	Quit $$$OK
}

/// Override to use DeQueueId
Method OnTask() As %Status
{
	Set $ZT="Trap", tSC=$$$OK, tHdrId="",tAlreadyHaveBankHdrLock=0
	Set $$$EnsJobLocal("ArchiveFlags")=0 ; ! never re-archive headers sent to us for archiving
	Do {
		#; Calculate keepalive wait time
		If $IsObject(..Adapter) {
			Set tWait=..Adapter.KeepaliveInterval
			If tWait>0 {
				Set:..%LastActionTime tNow=$ZH, tWait=$S(tNow-..%LastActionTime>=tWait:0, 1:tWait-(tNow-..%LastActionTime))
			} Else { Set tWait=-1 }
		} Else { Set tWait=-1 }
		#; If pool size > 1 then use MsgBankDeQueueId otherwise DeQueueId
		If ..%isSingleJob {
			Set tSC = ##class(Ens.Queue).DeQueueId(..QueueName(),.tHdrId,tWait,.tTimedOut,1)
		} Else {
			Set tSC = ##class(Ens.Queue).MsgBankDeQueueId(..QueueName(),.tHdrId,tWait,.tTimedOut,1,,.tAlreadyHaveBankHdrLock)
		}
		Quit:$$$ISERR(tSC)
		If ""=tHdrId { Set:tWait>=0&&tTimedOut tSC=..Adapter.OnKeepalive(), ..%LastActionTime=$ZH  Quit }
		Set ..%Flags=$P(tHdrId,"_",1), ..%Source=$P(tHdrId,"_",2), tHdrId=$P(tHdrId,"_",3,99)
		If ""=tHdrId $$$LOGERROR("Empty message header ID found in id string "_..%Flags_"_"_..%Source_"_")  Quit
		Set ..%hdrLocked=tAlreadyHaveBankHdrLock
		Lock:'tAlreadyHaveBankHdrLock +^Ens.MsgBank.Banked(tHdrId):2
		If 'tAlreadyHaveBankHdrLock && '$Test{
			/* Failed to  get lock. Repeat attempts unless need to be quiescent or terminate */
			Set tShouldBeQuiescent = ##class(Ens.Job).ShouldBeQuiescent()
			Set tTerminate=##class(Ens.Job).ShouldTerminate()
			While ('$Test&&'tShouldBeQuiescent&&'tTerminate) {
				Lock +^Ens.MsgBank.Banked(tHdrId):2
				If '$Test {
					Set tShouldBeQuiescent = ##class(Ens.Job).ShouldBeQuiescent()
					Set tTerminate=##class(Ens.Job).ShouldTerminate()
				}
			}
			/*	Check if failed to get lock and quiescence requested. 
				If  so put active back on queue at top - the active entry 
				will be deleted on Exit
			*/
			If '$Test,(tShouldBeQuiescent||tTerminate) {
				Set tOrigHdrId = ..%Flags_"_"_..%Source_"_"_tHdrId
				Set tSC = ##class(Ens.Queue).EnQueueId(tOrigHdrId,"Ens.Enterprise.MsgBankOperation",,1)
				$$$LOGINFO("Transmission waiting on lock exited due to shutdown request for message "_tHdrId_" ; re-queueing")
				Quit
			}
		}
		#; no need to set the property again
		Set:'tAlreadyHaveBankHdrLock ..%hdrLocked=1 ; don't let 2 jobs get the same unset Banked flags out of the header object.
		Set tRequestHeader=##class(Ens.MessageHeader).%OpenId(tHdrId)
		If '$IsObject(tRequestHeader) { Set:tWait>=0&&tTimedOut tSC=..Adapter.OnKeepalive(), ..%LastActionTime=$ZH  Quit }
		Set tSC=..MessageHeaderHandler(tRequestHeader,.tResponseHeader)
		Set:tWait>=0 tNow=$ZH, ..%LastActionTime=tNow, ..%LastHandledTime=tNow
		If $$$ISERR(tSC) { $$$LOGSTATUS(tSC)  Set tSC=1 } ; we don't pass on user errors here.
	} While 0
Exit
	Lock:""'=tHdrId&&..%hdrLocked -^Ens.MsgBank.Banked(tHdrId)  Set ..%hdrLocked=0 ; Unlock if OnMessage() didn't already do it
	Kill $$$EnsActiveMessage($$$SystemName_":"_$Job)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is for internal use
Method MessageHeaderHandler(pRequestHeader As Ens.MessageHeader, Output pResponseHeader As Ens.MessageHeader) As %Status
{
	Set (tSC,tSCSuspend)=$$$OK, tAborted=0, tDoAlert="", pResponseHeader=$$$NULLOREF, $ZE = ""
	Set $EC=""  try {
		Set ..%RequestHeader=pRequestHeader, $$$JobCurrentHeaderId=pRequestHeader.%Id()
		Set tResponse = $$$NULLOREF
		Set (..%SessionId,$$$JobSessionId) = pRequestHeader.SessionId
		Set tConfigName = ..%ConfigName
		Set tRequest=pRequestHeader

		Set (tEndTime,..%LastReportedError)="", ..RetryCount=1, (..Retry,..SuspendMessage,..DeferResponse,..%AlertStartTime,tFailureTimedOut,tTerminate)=0
		While 1 { ; Retry loop
			Set tTimeCalled=$ZH, tDoAlert=""
			Set:'tEndTime tEndTime = tTimeCalled + ..FailureTimeout
			Set tSC=..MessageHandler(tRequest,.tResponse)
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
						} catch {
							Set tSC=$$$ADDSC(tSC,$$$EnsSystemError), tDoAlert=""
						}
						If $TLevel>0 Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found after OnFailureTimeout(); committing before proceeding")
						Set:..SuspendMessage tSCSuspend=tSC
						Quit:'..%QuitTask
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
						#; Requeue for MsgBankOperation; blow away the original error (prevent error response) if self-disabling or shutting down while retrying
						Set tSCx=tSC, tSC=##class(Ens.Queue).EnQueueId(..%Flags_"_"_..%Source_"_"_pRequestHeader.%Id(),..%ConfigName)
						$$$LOGINFO("Retry loop exited due to shutdown request for message "_..%RequestHeader.%Id()_" ; re-queueing"_$S($$$ISOK(tSCx):"",1:" - original error: "_$$$StatusDisplayString(tSCx)))
					} Else {
						$$$LOGINFO("Retry loop exited due to shutdown request for message "_..%RequestHeader.%Id()_" ; quitting with status "_$$$StatusDisplayString(tSC))
					}
					$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"OK")
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
	} catch {
		Set tSC=$$$EnsSystemError, tDoAlert=1
	}
	If $$$ISERR(tSC) {
		Set tTxt=$P($$$StatusDisplayString(tSC)," -- ") ; strip off "logged as" varying text
		If tTxt'=..%LastReportedError { $$$LOGSTATUS(tSC) }
		Set ..%LastReportedError=tTxt

		Set tConfigName=..%ConfigName
		$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Error")
#If ..#INVOCATION="Queue"
		$$$SetJobMonitor(tConfigName,$$$SystemName_":"_$Job,$$$eMonitorStatus,"Error")
#EndIf
		Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSC))))
	} ElseIf ..SuspendMessage&&$$$ISERR(tSCSuspend) {
		Do:tDoAlert&&..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(tSCSuspend))))
	}
	Set ..%SessionId=""  Kill $$$JobSessionId
	Set ..%RequestHeader=$$$NULLOREF  Kill $$$JobCurrentHeaderId
	Quit tSC
cleanNum(str)
	Set f=0  For { Set f=$F(str,"#",f)  Quit:'f
		For i=f:1 { Quit:$E(str,i)'?1N  Set $E(str,i)="",i=i-1 }
	}
	Quit str
}

Method initEventFlags() [ Internal, Private ]
{
	Lock +^Ens.MsgBank("LastEvtId")
	If '..EnableArchiving||(""=$G(^Ens.MsgBank("LastEvtId"))) {
		#; Record the last id at the time of starting to prevent logging of interim events when re-enabled
		Set tNow=$G(^Ens.Util.LogD,0), tBefore=$G(^Ens.MsgBank("LastEvtId"),0)  Set:tNow>tBefore ^Ens.MsgBank("LastEvtId")=tNow
	}
	Lock -^Ens.MsgBank("LastEvtId")

	Quit:'..EnableArchiving

	#; initialize our %events filter array based on the ArchiveItems setting
	Set tCnt=$L(..ArchiveItems,",") For i=1:1:tCnt { Set tSpec=$ZCVT($ZStrip($P(..ArchiveItems,",",i),"<>W"),"L")  
		Set tEvents=$ZStrip($P($P(tSpec,"[",2),"]"),"<>W"), tItem=$ZStrip($P(tSpec,"["),"<>W")  Continue:""=tItem
		If ""'=$P(tSpec,"]",2) $$$LOGWARNING("ArchiveItems spec "_tSpec_" has extra stuff in it")
		Set tNeg=0  Set:"-"=$E(tItem) tNeg=1, tItem=$E(tItem,2,*)
		While "-$!"[$E(tItem,*)&&$L(tItem) { Set $E(tItem,$L(tItem))="" }
		Set tEvCnt=$L(tEvents,":") For j=1:1:tEvCnt { Set tEvt=$ZStrip($P(tEvents,":",j),"<>W")
			Set tCat=$ZStrip($P(tEvt,"_",2),"<>W"), tEvt=$ZStrip($P(tEvt,"_"),"<>W")
			Set:tEvt'="trace" tCat=""
			Set tNegEvt=tNeg
			Set:"-"=$E(tEvt) tNegEvt='tNeg, tEvt=$E(tEvt,2,*)  Continue:""=tEvt
			Set:'tNegEvt ..%anyEvents=1
			If "*"=tEvt { Set ..%events(tItem)='tNegEvt }
			ElseIf ""=tCat { Set ..%events(tItem,tEvt)='tNegEvt }
			Else { Set ..%events(tItem,tEvt,tCat)='tNegEvt }
		}
	}
	$$$sysTRACE("Initialized Event archive flags; ..%anyEvents="_..%anyEvents)
}

/// Calculate ArchiveFlags for the current Job/ConfigItem for use in sending headers to the MsgBankOperation
/// Flag bit fields:
///  1's bit - headers
///  2's bit - bodies
///  4's bit - SearchTable entries
/// OR
///  '*' bank nothing, but send status updates for other headers that have already been banked
ClassMethod InitArchiveFlags(pConfigName As %String) [ Internal ]
{
	Quit:$$$JobConfigName="Ens.Enterprise.MsgBankOperation" ; ! never re-archive headers sent to us for banking
	
	#; find the MsgBank Operation if any, get its settings, and set local flags for the current config item based on the ArchiveItems setting
	$$$SuspendErrorCount
	Set tEnabled=##class(Ens.Director).GetHostSettingValue("Ens.Enterprise.MsgBankOperation","EnableArchiving",.tSC)
	If $$$ISERR(tSC) {
		If ""'=$G($$$EnsJobLocal("ArchiveFlags"),0) {
			If '$$$StatusEquals(tSC,$$$EnsErrConfigItemNotFound) {
				$$$LOGERROR("Not initializing archive job-flags due to error "_$$$StatusDisplayString(tSC))
			} Else {
				$$$sysTRACE("Initializing empty MsgBank archive job-flags because Ens.Enterprise.MsgBankOperation is not configured in this Production")
				Kill %objlasterror ; expunge the ConfigItemNotFound error so bean counters won't choke
			}
			Set $$$EnsJobLocal("ArchiveFlags")=""
		}
		Quit
	}
	If 'tEnabled { Set aHdr=0 }
	Else {
		Set tArchiveItems=##class(Ens.Director).GetHostSettingValue("Ens.Enterprise.MsgBankOperation","ArchiveItems",.tSC)
		If $$$ISERR(tSC) $$$LOGERROR("Not initializing archive job-flags due to error "_$$$StatusDisplayString(tSC))
		Set tLwrConfig=$ZCVT(pConfigName,"L"), (aHdr,aBod,aSch)=0
		Set tCnt=$L(tArchiveItems,",") For i=1:1:tCnt { Set tSpec=$ZCVT($ZStrip($P(tArchiveItems,",",i),"<>W"),"L")
			Set tEvents=$ZStrip($P($P(tSpec,"[",2),"]"),"<>W"), tItem=$ZStrip($P(tSpec,"["),"<>W")  Continue:""=tItem
			If ""'=$P(tSpec,"]",2) $$$LOGWARNING("ArchiveItems spec "_tSpec_" has extra stuff in it")
			Set tNeg=0  Set:"-"=$E(tItem) tNeg=1, tItem=$E(tItem,2,*)
			Set (xBod,xSch,xHdr)=tNeg
			While "-$!"[$E(tItem,*)&&$L(tItem) {
				Set:"-"=$E(tItem,*) xHdr='tNeg
				Set:"!"=$E(tItem,*) xBod='tNeg
				Set:"$"=$E(tItem,*) xSch='tNeg
				Set $E(tItem,$L(tItem))=""
			}
			If $Case(tItem,tLwrConfig:1,"*":1,:0) {
				Set fHdr='xHdr
				Set fBod='xBod
				Set fSch='xSch
				Quit:tItem=tLwrConfig
			}
			If tItem'=tLwrConfig {
				Set:'aHdr&&'xHdr aHdr=1
				Set:'aBod&&'xBod aBod=1
				Set:'aSch&&'xSch aSch=1
			}
		}
	}
	Set tPrev=$G($$$EnsJobLocal("ArchiveFlags"))
	Set tNew = $G(fHdr)+(2*$G(fBod))+(4*$G(fSch))
	Set:'tNew&&aHdr tNew="*" ; flag that some other items will be banking message headers even if we're not
	Set $$$EnsJobLocal("ArchiveFlags") = tNew
	If tPrev'=tNew $$$sysTRACE("Initialized MsgBank archive job-flags for "_pConfigName_" from '"_tPrev_"' to '"_tNew_"'")
}

/// This method is called when config changes to this item are saved from the portal
/// This method uses $$$EnsMirrorIndexInc to trigger all other jobs to call SetTraceOptimizer which calls InitArchiveFlags() which will update their behavior based on the config changes to this item.</Description>
ClassMethod OnConfigChange(pProduction As Ens.Config.Production, pItem As Ens.Config.Item)
{
	Quit:pProduction.Name'=$G($$$EnsRuntime("Name")) ; 'IsProdRunning
	Set tOldEn=$G($$$EnsRuntimeAppData(pItem.Name,"EnableArchiving"))  Set:'pItem.GetSetting("EnableArchiving",.tEn) tEn=""
	Set tOldSpec=$G($$$EnsRuntimeAppData(pItem.Name,"ArchiveItems"))  Set:'pItem.GetSetting("ArchiveItems",.tSpec) tSpec=""
	Set:'$IsObject(pItem.Production) (tEn,tSpec)="" ; item removed from running production
	Set $$$EnsRuntimeAppData(pItem.Name,"EnableArchiving")=tEn
	Set $$$EnsRuntimeAppData(pItem.Name,"ArchiveItems")=tSpec
	Do:(tOldEn'=tEn)||(tOldSpec'=tSpec) $$$EnsMsgBankIndexInc, $$$EnsMirrorIndexInc
}

Method OnTearDown() As %Status
{
	If '..EnableArchiving {
		#; Record the last id at the time of starting to prevent logging of interim events when re-enabled
		Lock +^Ens.MsgBank("LastEvtId") Set tNow=$G(^Ens.Util.LogD,0), tBefore=$G(^Ens.MsgBank("LastEvtId"),0)  Set:tNow>tBefore ^Ens.MsgBank("LastEvtId")=tNow  Lock -^Ens.MsgBank("LastEvtId")
	}
	Quit ##super()
}

}
