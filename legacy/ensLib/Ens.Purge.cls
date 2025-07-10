/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Purge [ Abstract, ClassType = "", CompileAfter = Ens.BusinessProcessBPL, ProcedureBlock, System = 4 ]
{

/// PurgeAll does not currently use the optional multi process purge Ens.Util.MessagePurge. <br>
/// pExtendedOptions is similar to that for Ens.Util.MessagePurge and is used to request
/// Bitmap maintenance for the namespace. <br>
/// To use the Ens.Util.MessagePurge from the task select just Messages and not All Types.
ClassMethod PurgeAll(Output pDeletedCount, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0, pBitmapPurgeRunLimit As %Integer = 600, ByRef pExtendedOptions As %String) As %Status
{
	Set tSCAll=$$$OK

	Set tDeletedCount=0
	Set tBitmaps=0
	Set tSC=##class(Ens.Util.Log).Purge(.tDeletedCount,pDaysToKeep,,pBitmapPurgeRunLimit)  Set:$$$ISERR(tSC) tSCAll=$$$ADDSC(tSCAll,tSC)
	Set pDeletedCount("Event Logs")=tDeletedCount
	Set tBitmaps=tBitmaps + $get(tDeletedCount("bitmaps"))

	Set tDeletedCount=0, tDeletedCount("bodies")=0, tDeletedCount("bitmaps")=0
	Set tSC=##class(Ens.MessageHeader).Purge(.tDeletedCount,pDaysToKeep,pKeepIntegrity,pBodiesToo,pBitmapPurgeRunLimit)  Set:$$$ISERR(tSC) tSCAll=$$$ADDSC(tSCAll,tSC)
	Set pDeletedCount("Ensemble Messages")=tDeletedCount
	Set pDeletedCount("Message Bodies")=tDeletedCount("bodies")
	Set tBitmaps=tBitmaps + $get(tDeletedCount("bitmaps"))

	Set tDeletedCount=0
	#; We will always keep integrity true if calling Ens.BusinessProcess::Purge from here.
	Set tSC=##class(Ens.BusinessProcess).Purge(.tDeletedCount,pDaysToKeep,1)  Set:$$$ISERR(tSC) tSCAll=$$$ADDSC(tSCAll,tSC)
	Set pDeletedCount("Business Processes")=tDeletedCount

	Set tDeletedCount=0, tDeletedCount("bitmaps")=0
	Set tSC=##class(Ens.Rule.Log).Purge(.tDeletedCount,pDaysToKeep,,pBitmapPurgeRunLimit)  Set:$$$ISERR(tSC) tSCAll=$$$ADDSC(tSCAll,tSC)
	Set pDeletedCount("Business Rule Logs")=tDeletedCount
	Set tBitmaps=tBitmaps + $get(tDeletedCount("bitmaps"))

	#; Ens.MessageHeader purge is called first so that we can now purge headerless IOLogObj in & out objects
	Set tDeletedCount=0, tDeletedCount("bitmaps")=0
	Set tSC=##class(Ens.Util.IOLog).Purge(.tDeletedCount,pDaysToKeep,,pBitmapPurgeRunLimit)  Set:$$$ISERR(tSC) tSCAll=$$$ADDSC(tSCAll,tSC)
	Set pDeletedCount("I/O Logs")=tDeletedCount
	Set tBitmaps=tBitmaps + $get(tDeletedCount("bitmaps"))

	Set tDeletedCount=0
	Set tSC=##class(Ens.MonitorService).Purge(.tDeletedCount,pDaysToKeep)  Set:$$$ISERR(tSC) tSCAll=$$$ADDSC(tSCAll,tSC)
	Set pDeletedCount("Host Monitor Data")=tDeletedCount

	Set tDeletedCount=0,tDeletedCount("bitmaps")=0
	Set tSC=##class(Ens.Alerting.ManagedAlert).Purge(.tDeletedCount,pDaysToKeep,pKeepIntegrity,pBitmapPurgeRunLimit)  Set:$$$ISERR(tSC) tSCAll=$$$ADDSC(tSCAll,tSC)
	Set pDeletedCount("Managed Alerts")=tDeletedCount
	Set tBitmaps=tBitmaps + $get(tDeletedCount("bitmaps"))

	Set pDeletedCount("Bitmap Chunks")=tBitmaps

	If $Get(pExtendedOptions("NamespaceBitmapMaint")) {
		Set tStopTime = ""
		If (+pBitmapPurgeRunLimit=pBitmapPurgeRunLimit)&&(pBitmapPurgeRunLimit>0) Set tStopTime = $system.SQL.DATEADD("s",pBitmapPurgeRunLimit,$ZDT($H,3))
		Set tBitmapSC = ##class(%SYS.Maint.Bitmap).Namespace($namespace, 0, 0, tStopTime)
	}

	Quit tSCAll
}

/// This is just a stub
ClassMethod PurgeEventLogsByDate(pDaysToKeep As %Integer = 7, Output pDeletedCount As %Integer, pDummy As %Boolean, pBitmapPurgeRunLimit As %Integer = 600) As %Status
{
	Quit ##class(Ens.Util.Log).Purge(.pDeletedCount,pDaysToKeep,,pBitmapPurgeRunLimit)
}

ClassMethod PurgeMessagesByDate(pDaysToKeep As %Integer = 7, Output pDeletedCount As %Integer, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0, ByRef pExtendedOptions As %String, pBitmapPurgeRunLimit As %Integer = 600) As %Status
{
	Quit ##class(Ens.Util.MessagePurge).Purge(.pDeletedCount,pDaysToKeep,pKeepIntegrity,pBodiesToo,pBitmapPurgeRunLimit,.pExtendedOptions)
}

ClassMethod PurgeBusinessProcessesByDate(pDaysToKeep As %Integer = 7, Output pDeletedCount As %Integer, pKeepIntegrity As %Boolean = 1) As %Status
{
	#; We will always keep integrity true if calling Ens.BusinessProcess::Purge from here.
	Quit ##class(Ens.BusinessProcess).Purge(.pDeletedCount,pDaysToKeep,1)
}

ClassMethod PurgeRuleLogsByDate(pDaysToKeep As %Integer = 7, Output pDeletedCount As %Integer, pDummy As %Boolean) As %Status
{
	Quit ##class(Ens.Rule.Log).Purge(.pDeletedCount,pDaysToKeep)
}

ClassMethod GetAllCounts(Output pCount)
{
	Set pCount("Event Log")=..EventLogCount()
	Set pCount("Messages")=..MessageCount()
	Set pCount("Business Processes")=..BusinessProcessCount()
	Set pCount("Business Rule Log")=..RuleLogCount()
	Set pCount("I/O Log")=..IOLogCount()
	Set pCount("Managed Alerts")=..ManagedAlertCount()
	Quit
}

ClassMethod EventLogCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens_Util.Log)
	Quit tCount
}

ClassMethod MessageCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens.MessageHeader)
	Quit tCount
}

ClassMethod BusinessProcessCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens.BusinessProcess)
	Quit tCount
}

ClassMethod RuleLogCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens_Rule.Log)
	Quit tCount
}

ClassMethod IOLogCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens_Util.IOLog)
	Quit tCount
}

ClassMethod ManagedAlertCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens_Alerting.ManagedAlert)
	Quit tCount
}

ClassMethod PurgeEventLogs(pNumberToKeep As %Integer = 1000, pMaxNumberToDelete As %Integer = -1, Output pLogsDeleted As %Integer) As %Status
{
	New %tFirstIdToKeep
	Set tFirstId = $o(^Ens.Util.LogD(""))
	Set tLastId = $o(^Ens.Util.LogD(""),-1)
	Set tRightMargin = tLastId-pNumberToKeep
	If pMaxNumberToDelete=-1 {
		Set tLeftMargin = tRightMargin+1
	} Else {
		Set tLeftMargin = tFirstId+pMaxNumberToDelete
	}
	Set %tFirstIdToKeep = $s(tLeftMargin>tRightMargin:tRightMargin+1,1:tLeftMargin)
	If %tFirstIdToKeep'>tFirstId Set pLogsDeleted = 0 Quit $$$OK
	&sql(Delete From Ens_Util.Log where Id < :%tFirstIdToKeep)
	Set pLogsDeleted = $get(%ROWCOUNT)
	Quit $$$OK
}

/// Deprecated - use Ens.Util.MessagePurge:Purge() with pKeepIntegrity=1
ClassMethod PurgeSessions(pDaysToKeep As %Integer = 7, pMaxNumberToDelete As %Integer = -1, Output pSessionsDeleted As %Integer) As %Status
{
	New %tDoNotDeleteDate Set %tDoNotDeleteDate = ..GetDoNotDeleteDate(pDaysToKeep)
	New %sessionid

	&sql(DECLARE sqlSESSIONS CURSOR FOR 
		SELECT DISTINCT SessionId
		INTO :%sessionid
		FROM Ens.MessageHeader
		WHERE TimeCreated < :%tDoNotDeleteDate
		)
	Set pSessionsDeleted=0
	&sql(OPEN sqlSESSIONS)
	For {
		&sql(FETCH sqlSESSIONS) Quit:SQLCODE
		If ..IsOneSessionPurgable(%sessionid) {
			Do ..PurgeOneSession(%sessionid)
			Set pSessionsDeleted=pSessionsDeleted+1
		}
		If pMaxNumberToDelete'=-1,pSessionsDeleted'<pMaxNumberToDelete Quit
	}
	&sql(CLOSE sqlSESSIONS)
	Quit $$$OK
}

/// Deprecated - only used by deprecated method PurgeSessions()
ClassMethod IsOneSessionPurgable(pSessionId As %String) As %Integer
{
	Quit 1
	New %sessionid Set %sessionid = pSessionId
	&sql(SELECT COUNT(*) INTO :tCountUnrespondedRequests
		FROM Ens.MessageHeader
		WHERE SessionId = :%sessionid AND Type = 'Request' AND ReturnQueueName IS NOT NULL AND CorrespondingMessageId IS NULL
		)
	If tCountUnrespondedRequests Quit 0
	&sql(SELECT COUNT(*) INTO :tCountIncompleteProcesses
		FROM Ens.BusinessProcess
		WHERE %SessionId = :%sessionid AND %IsCompleted <> '1'
		)
	If tCountIncompleteProcesses Quit 0
	Quit 1
}

/// Deprecated - only used by deprecated method PurgeSessions()
ClassMethod PurgeOneSession(pSessionId As %String) As %Status
{
	New %sessionid Set %sessionid = pSessionId
	&sql(DELETE from Ens.MessageHeader where SessionId = :%sessionid)
	#; BusinessProcessBPL table is called first so that its OnDelete trigger can be called
	&sql(DELETE from Ens.BusinessProcessBPL where %SessionId = :%sessionid)
	&sql(DELETE from Ens.BusinessProcess where %SessionId = :%sessionid)
	Quit $$$OK
}

ClassMethod SessionCount() As %Integer
{
	&sql(SELECT COUNT(DISTINCT SessionId) INTO :tSessionCount From Ens.MessageHeader)
	Quit tSessionCount
}

ClassMethod GetDoNotDeleteDate(pDaysToKeep As %Integer) As %DateTime
{
	Set tOffset = $E($zdatetime(($H-pDaysToKeep+1)_",00000",1,5),*-5,*) ; find out what the offset was on the last date we are purging +/-HH:MM
	Set tOffset = $Case($E(tOffset,1),"+":-1,"-":1) * ((60*$P($E(tOffset,2,*),":")) + $P(tOffset,":",2)) ; convert to minutes
	Set tDateH = $S(tOffset'<0:($H-pDaysToKeep+1)_","_(tOffset*60),1:($H-pDaysToKeep)_","_(tOffset*60+86400))
	Set tDate = $$$timeUTCHtoUTC(tDateH)
	If $P(##class(Ens.DataType.UTC).LogicalToOdbc(tDate)," ",2,*)="00:00:00.000" { ; confirm this really is local midnight
		Quit tDate
	} Else { ; otherwise need to adjust again
		Set tLocal = $P(##class(Ens.DataType.UTC).LogicalToOdbc(tDate)," ",2,*)
		Set tCorrection = ($P(tLocal,":",1)*3600) + ($P(tLocal,":",2)*60) + $P(tLocal,":",3)
		Set tDateH = $S(($P(tDateH,",",2) - tCorrection) >= 0 : $P(tDateH,",",1)_","_($P(tDateH,",",2) - tCorrection), 1: ($P(tDateH,",",1)-1)_","_(86400 + $P(tDateH,",",2) - tCorrection))
		Quit $$$timeUTCHtoUTC(tDateH)
	}
}

ClassMethod GetAllDataGlobals(globals, pBodiesToo = 0) [ Internal ]
{
	Set globals("^Ens.Util.LogD")=""
	Set globals("^Ens.Util.LogD","name")="Event Logs"
	Set globals("^Ens.Util.LogI")=""

	Set globals("^Ens.Util.IOLogD")=""
	Set globals("^Ens.Util.IOLogD","name")="I/O Logs"
	Set globals("^Ens.Util.IOLogS")=""
	Set globals("^Ens.Util.IOLogI")=""

	Set globals("^Ens.MessageHeaderD")=""
	Set globals("^Ens.MessageHeaderD","name")="Ensemble Messages"
	Set globals("^Ens.MessageHeaderI")=""
	If pBodiesToo {
		Set globals("^Ens.MessageBodyD")=""
		Set globals("^Ens.MessageBodyD","name")="Message Bodies"
		Set globals("^Ens.MessageBodyS")=""
		Set globals("^Ens.MessageBodyI")=""
	}
	Set globals("^Ens.BusinessProcessD")=""
	Set globals("^Ens.BusinessProcessD","name")="Business Processes"
	Set globals("^Ens.BusinessProcessS")=""
	Set globals("^Ens.BusinessProcessI")=""
	Set globals("^Ens.BP.ContextD")=""
	Set globals("^Ens.BP.ContextS")=""
	Set globals("^Ens.BP.ContextI")=""
	Set globals("^Ens.BP.ThreadD")=""
	Set globals("^Ens.BP.ThreadS")=""
	Set globals("^Ens.BP.ThreadI")=""

	Set globals("^Ens.Rule.LogI")=""
	Set globals("^Ens.Rule.LogD")=""
	Set globals("^Ens.Rule.LogD","name")="Business Rule Logs"

	Set globals("^IRIS.Temp.EnsHostCounter")=""
	Set globals("^IRIS.Temp.EnsHostMonitor")=""
	Set globals("^IRIS.Temp.EnsJobMonitor")=""
	Set globals("^IRIS.Temp.EnsLogMonitor")=""

	Set globals("^ERRORS")=""
	quit
}

/// For debugging only! This will kill your data.
/// Kill all standard runtime storage in the current namespace.
/// Does not include storage globals from message classes you have defined that are not derived from Ens.MessageBody -
/// to kill those you will need to do a MessageHeader purge with pBodiesToo=1.
ClassMethod KillGlobals(pDeletedCount, pKeepExtentCount = 0, pDisplayLog = 1, pBodiesToo = 0)
{
	do ..GetAllDataGlobals(.globals,pBodiesToo)
	set global="" for  {
		set global=$o(globals(global)) quit:global=""
		if pDisplayLog write !,"killing ",global
		set name=$g(globals(global,"name")),level=$g(globals(global,"level"),1)
		if name'="" {
			set count=0
			if level=1 set sub="" for  set sub=$o(@global@(sub)) quit:sub=""  set count=count+1
			if level=2 set sub="" for  set sub=$o(@global@(sub)) quit:sub=""  set sub2="" for  set sub2=$o(@global@(sub,sub2)) quit:sub2=""  set count=count+1
			set pDeletedCount(name)=count
		}
		kill tExtentCount if pKeepExtentCount,$d(@global)#2 set tExtentCount=@global
		kill @global
		if $d(tExtentCount) set @global=tExtentCount
	}
	quit
}

/// For debugging: show all standard runtime storage in the current namespace.
/// Note that storage globals are not included from message classes you have defined that are not derived from Ens.MessageBody.
ClassMethod ShowGlobals(pBodiesToo As %Boolean = 0)
{
	do ..GetAllDataGlobals(.globals,pBodiesToo)
	write !,"=== Data Globals ===="
	set global="" for  {
		set global=$o(globals(global)) quit:global=""
		do ..ShowOneGlobal(global)
	}
	Write !
	Write !,"=== Runtime Globals ===="
	Do ..ShowOneGlobal("^Ens.Runtime")
	Do ..ShowOneGlobal("^Ens.Queue")
	Do ..ShowOneGlobal("^Ens.JobStatus")
	Do ..ShowOneGlobal("^Ens.JobRequest")
	Do ..ShowOneGlobal("^Ens.Suspended")
	Do ..ShowOneGlobal("^IRIS.Temp.EnsHostCounter")
	Do ..ShowOneGlobal("^IRIS.Temp.EnsHostMonitor")
	Do ..ShowOneGlobal("^IRIS.Temp.EnsJobMonitor")
	Do ..ShowOneGlobal("^IRIS.Temp.EnsLogMonitor")
	Write !

	;^Ens.Conf.ProductionC
	;^Ens.Conf.ProductionD
	;^Ens.Debug
	Quit
}

ClassMethod ShowOneGlobal(reference) [ Internal ]
{
	Write !,reference,?25,"$data()=",$data(@reference)
	If $data(@reference)>1 {
		Set sub="",count=0 For  Set sub=$order(@reference@(sub)) quit:sub=""  Set count=count+1
		Write ?40,count," nodes"
	}
	Quit
}

}
