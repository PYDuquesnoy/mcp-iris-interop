/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syPidtab, %cspGatewayRegistry, %cspBuild)

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// The %CSP.Daemon class runs to cleanup expired CSP sessions.
Class %CSP.Daemon [ System = 3 ]
{

/// Purge our performance counters
ClassMethod CleanPerfCounters()
{
	Set sc=$$$OK
	Try {
		Set ns="^^"_$zutil(12)
		#; Purge any redundent groupId entries
		Do ..purgeGroupEntries()
		Set today=+$horolog
		Do Reclaim^%SYS.cspServer()
		#; Default to expire the performance data at the end of the year.
		Set expire=$get(^%SYS("CSP","Expire"),366)
		Set type=$order(^|ns|ISCcspPerformance(""))
		While type'="" {
			Set url=$order(^|ns|ISCcspPerformance(type,""))
			While url'="" {
				Set day=$order(^|ns|ISCcspPerformance(type,url,""))
				While day'=""&&(+$zdth(day,3)<(today-expire)) {
					Kill ^|ns|ISCcspPerformance(type,url,day)
					Set day=$order(^|ns|ISCcspPerformance(type,url,day))
				}
				Set url=$order(^|ns|ISCcspPerformance(type,url))
			}
			Set type=$order(^|ns|ISCcspPerformance(type))
		}
		#; Remove any macro cached information that has not been used in the past day
		Set machash=""
		For  {
			Set machash=$order(^IRIS.TempMacro(machash),1,timestamp) Quit:machash=""
			If timestamp<(today-1) Kill ^IRIS.TempMacro(machash)
		}
		#; Remove any historic connections that have been inactive in the Gateway Registry too long
		Do ..purgeHistoricConnections()
		Set purgeToThisStream = ..purgeCSPRequests( $get($$$CSPGatewayRespStream,0) )
	} Catch exception {
		Set sc=exception.AsStatus()
	}
	RETURN sc
}

/// The main body of the CSP Daemon
ClassMethod Run() [ Internal ]
{
	#Dim ns, ts, today, next, session, expire, type, url, machash, day, timestamp
	#Dim purgeToThisStream As %Integer
	
	Set sc=$$$OK
	Try {
		#; First, process all pending entries in the queue
		Set ts="",today=+$horolog
		For  {
			Set ts=$Order(^%cspSession(0,ts))
			Quit:ts=""
			Set next=ts-$$$TIMESTAMP($ZTS)
			Quit:next>0
			Set session=""
			For  {
				Set session=$Order(^%cspSession(0,ts,session))
				Quit:session=""
				Do ..SessionTimeout(session,ts)
			}
		}
		
		Do ##class(%SYS.TokenAuth).RevokeExpiredTokens()
		// purge any timed out security tokens
		Do ..purgeZombieSecurityTokens()
	} Catch exception {
		Set sc=exception.AsStatus()
	}
	RETURN sc
}

/// Called when a session timeout is detected.
ClassMethod SessionTimeout(sessionId As %String, ts As %String, skiplock As %Boolean = 0) As %Boolean [ Internal ]
{
	#dim rc
	New %session
	$$$SysLogSetVar
	$$$CSPLogAll(2,"CSPSession","[SessionTimeout] Timing out","","",sessionId)
	If 'skiplock {
		Lock +^%cspSession(sessionId):0 If '$test {
			$$$CSPLogAll(2,"CSPSession","[SessionTimeout] Session is active, so aborting timeout","","",sessionId)
			RETURN 1
		}
	}
	#; Make sure lock gets release in case of an error
	Set rc=1
	Set $ztrap="sesLockTrap"
	#; This should never fire, but just in case clean up bad entry and recreate correct one
	If $Get(ts)'="",$ListGet($Get(^%cspSession(sessionId)),$$$sesOldTimeout)'=ts Kill ^%cspSession(0,ts,sessionId) Set:$ListGet($Get(^%cspSession(sessionId)),$$$sesOldTimeout)'="" ^%cspSession(0,$List(^%cspSession(sessionId),$$$sesOldTimeout),sessionId)=""
	#; Check again if we should time this out between finding entry in global and getting lock
	If 'skiplock,$ListGet($Get(^%cspSession(sessionId)),$$$sesOldTimeout)>$$$TIMESTAMP($ZTS) Lock -^%cspSession(sessionId) Quit 1
	Set %session=##class(%CSP.Session).%OpenId(sessionId)
	#; Session object will hold a lock so we can release ours
	If 'skiplock Lock -^%cspSession(sessionId)#"I"
	If %session=$$$NULLOREF Quit 1
	Lock +$$$CSPWebSocket("SESSION",sessionId):0 If '$test {
		$$$CSPLogAll(2,"CSPSession","[SessionTimeout] Session websocket is active, so aborting timeout","","",sessionId)
		Goto exit
	}	
	Lock -$$$CSPWebSocket("SESSION",sessionId)
	Set %session.EndSession=1
	#; Remove the session (unless the callback says not to)
	If '%session.endSession(1,skiplock) Do %session.%SaveData(sessionId)
	#; If we called user code cleanup in case they left anything around, do not release locks or wipe PPG in here
exit	If 'skiplock Do wipe^%SYS.cspServer(,0)
	#; In case someone else starts a transaction and does not end
	While $tlevel { TCommit }
	Quit rc
sesLockTrap	Set $ztrap=""
	$$$SysLogVar(1,"CSPSession","[SessionTimeout] Error running end session",$zerror)
	If 'skiplock Lock -^%cspSession(sessionId)#"I"
	Set rc=0
	Goto exit
}

ClassMethod purgeHistoricConnections() [ Internal ]
{
	#Dim exp As %Exception.AbstractException
	#Dim key As %String
	#Dim connection As %List
	#Dim timeout
	
	try {
		Set timeout = $$$TIMESTAMP($ZTS) + $$$HistoricConnectTimeout
		$$$SysLogSetVar
		$$$SysLogVar(2,"GatewayRegistry","[purgeHistoricConnections]","")
		Set key = ""
		For {
			Set key = $$$NextHistoric(key)
			Quit:key=""
			Set connection = $$$HistoricConnections(key)
			if ($$$gtConnectDateG(connection) < timeout ) {
				$$$SysLogVar(2,"GatewayRegistry","[purgeHistoricConnections] key="_key, "")
 				try {
					Lock +$$$HistoricConnections(key):0
					if ($test) {
						Kill $$$HistoricConnections(key)
						Lock -$$$HistoricConnections(key)
					}
				}
				catch exp {
					Lock -$$$HistoricConnections(key)
					$$$SysLogVar(1,"GatewayRegistry","[purgeHistoricConnections] Exception: Purging "_key_"  "_exp.DisplayString(), "")
				}
			}
		}
	} 
	catch exp {
		$$$SysLogVar(1,"GatewayRegistry","[purgeHistoricConnections] Exception: "_exp.DisplayString(), "")
	}
}

/// cspServer now stores security-context/tokens in 'Security Limbo'. These security objects timeout and become zombies.
/// The Daemon uses purgeZombieSecurityTokens() to get rid of any timed out security tokens.
ClassMethod purgeZombieSecurityTokens() [ Internal ]
{
 $$$SysLogSetVar
 try {
	Set ts=""
	For  {
		Set ts=$Order(^%cspSession(-2,ts))
		Quit:ts=""
		Set timeLeft=ts-$$$TIMESTAMP($ZTS)
		Quit:timeLeft>0
		s sessionId=""
		f {
			s sessionId=$o(^%cspSession(-2,ts,sessionId)) q:sessionId=""
			s appl=""
			f  {
				s appl=$o(^%cspSession(-2,ts,sessionId,appl)) q:appl=""
				$$$CSPLogAll(2,"CSPServer","[purgeZombieSecurityTokens] Timing out security token", appl,"",sessionId)
#;Make sure we kill the right one. We have seen where there are multiple -2 nodes which can
#;occur if the user clicks the back button at the security token screen, and
#;we kill a session thats still valid.
				Kill ^%cspSession(-2,ts,sessionId,appl)
				s Data=$g(^%cspSession(-1,sessionId,appl))
				i Data'="" {
					i $li(Data,$$$lboExpireTimeIdx)=ts Kill ^%cspSession(-1,sessionId,appl)
				}
			}
		}
	}
 }
	catch exp {
		$$$SysLogVar(1,"CSPServer","[purgeZombieSecurityTokens] Exception: "_exp.DisplayString(), "")
 }
}

/// The CSP Gateway requests cleanup after themselves if they are called successfully.
/// However, if an error occurs some data may be left around. So every once in a while
/// we clean up anything left around
ClassMethod purgeCSPRequests(purgeToThisStream As %Integer) As %Integer [ Internal ]
{
	#Dim curStreamId As %Integer
	#Dim nextStreamId, nextRequestId, now
	#Dim exp As %Exception.AbstractException
	$$$SysLogSetVar
	
	try {
		
		#;The data is returned to the caller via a stream
		#;kill all the response streams that are still around from the last time we purged
		if ( purgeToThisStream > 0 ) {
			Set nextStreamId = ""
			For {
				Set nextStreamId=$Order($$$CSPGatewayRespStream(nextStreamId))
				Quit:nextStreamId=""
				Quit:(nextStreamId>purgeToThisStream)
				Kill $$$CSPGatewayRespStream(nextStreamId)
				$$$SysLogVar(2,"CSPSession","[purgeCSPRequests] Purging Stream "_$$$CSPGatewayRespStreamName_"("_nextStreamId_")","")
			}
		}
	
		#; if there are any old requests lying around, get rid of them.
		#; There should only be current requests and (a few, if any) broken request
		#; the request id is composed of 'timeout'_"::"_'randomid'
		#; we'll check the current time against the timeout
		Set now = $$$CSPTimeoutCheck($ZTS)

		Set nextRequestId = ""
		For {
			Set nextRequestId =  $Order($$$CSPGatewayPending(nextRequestId))
			Quit:nextRequestId=""
			#; requestId's have format: <prefix><timeout><prefix><randomNumber>
			if ( nextRequestId < now ) {
				$$$SysLogVar(2,"CSPSession","[purgeCSPRequests] Purged CspId:"_nextRequestId,"")
				Kill $$$CSPGatewayPending(nextRequestId)
			}
			else {
				;# id's are orderd by time, so once we reach an id with timeoutId > now we are done
				Quit 
			}
		}
	}
	catch exp {
		$$$SysLogVar(1,"CSPServer","[purgeCSPRequests] Exception: "_exp.DisplayString(), "")
	}
			
	#; next time purge to the highest currently existing stream
	Set purgeToThisStream = $get($$$CSPGatewayRespStream,0)

	Quit purgeToThisStream
}

ClassMethod purgeGroupEntries()
{
	Set groupId=""
	For {
		Set groupId=$order($$$GroupByIdSlot(groupId)) Quit:groupId=""
		Set groupId(groupId)=""
	}
	Set sessionId=0
	For {
		Set sessionId=$order(^%cspSession(sessionId),1,data) Quit:sessionId=""
		Set groupById=$lg(data,$$$sesByIdGroups)
		For i=1:1:$listlength(groupById) {
			Set id=$listget(groupById,i)
			If id'="" Kill groupId(id)
		}
	}
	Set groupId=""
	For {
		Set groupId=$order(groupId(groupId)) Quit:groupId=""
		Lock +$$$GroupByIdSlot(groupId):0 Else  Continue
		If '$data($$$GroupByIdSlot(groupId),groupByIdItem) Lock -$$$GroupByIdSlot(groupId)#"I" Continue
		Set remove=1
		If groupByIdItem'="" {
			Set sessionList = $$$giSessionListG(groupByIdItem)
			For i=1:1:$listlength(sessionList) {
				Set sessionId=$listget(sessionList,i)
				If sessionId'="" {
					Lock +^%cspSession(sessionId):0 Else  Set remove=0 Quit
					Set data=$data(^%cspSession(sessionId)) 
					Lock -^%cspSession(sessionId)#"I"
					If data Set remove=0 Quit
				}
			}
			Set tokenList = $$$giTokenListG(groupByIdItem)
			Set i=0
			While remove && $listnext(tokenList,i,token) {
				If ##class(%SYS.TokenAuth).%ExistsId(token) {
					Set remove=0
				}
			}
		}
		If remove {
			If $$$giCookieG(groupByIdItem)'="" {
				Kill $$$GroupIdFromCookie($$$giCookieG(groupByIdItem))
			}
			Kill $$$GroupByIdSlot(groupId)
		}
		Lock -$$$GroupByIdSlot(groupId)#"I"
	}
}

}
