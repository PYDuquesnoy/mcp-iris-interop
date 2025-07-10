/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Class to provide information to build portal pages
Class EnsPortal.UtilsMonitor Extends %RegisteredObject [ System = 4 ]
{

ClassMethod GetSummary(ByRef pResult, pGetCaption = 0, pLanguage = "en")
{
	Kill pResult
	;
	Kill tResult Do ..GetProductionSummary(.tResult,.pGetCaption, pLanguage) Merge pResult("Production")=tResult
	Kill tResult Do ..GetJobSummary(.tResult,.pGetCaption, pLanguage) Merge pResult("Job")=tResult
	Kill tResult Do ..GetLogSummary(.tResult,.pGetCaption, pLanguage) Merge pResult("Log")=tResult
	;
	Kill tResult Do ..GetServiceSummary(.tResult,.pGetCaption, pLanguage) Merge pResult("Service")=tResult
	Kill tResult Do ..GetProcessSummary(.tResult,.pGetCaption, pLanguage) Merge pResult("Process")=tResult
	Kill tResult Do ..GetOperationSummary(.tResult,.pGetCaption, pLanguage) Merge pResult("Operation")=tResult
	;
	Quit
}

ClassMethod GetProductionSummary(ByRef pResult, pGetCaption, pLanguage)
{
	Do ##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)
	Set pResult("Name")=$get(tProductionName)
	Set pResult("State")=tState
	;
	If tState=$$$eProductionStateRunning {
		Set pResult("Started")=$$$timeUTCtoLocal($$$EnsRuntime("StartTime"))
		Set pResult("Update")=##class(Ens.Director).ProductionNeedsUpdate(.tReason)
		Set pResult("UpdateReason")=$G(tReason)
	} Else {
		Set pResult("Started")=""
		Set pResult("Update")=""
		Set pResult("UpdateReason")=""
	}
	;
	If pGetCaption {
		Set pResult("Name","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","Name","Name")
		Set pResult("State","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","State","State")
		Set pResult("Started","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","Started","Started")
		Set pResult("Update","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","Update","Update")
		Set pResult("UpdateReason","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","UpdateReason","Update Reason")
	}
	Quit
}

ClassMethod GetJobSummary(ByRef pResult, pGetCaption, pLanguage)
{
	Set tJobCount=0
	Set tJobOKCount=0
	Set tJobInactiveCount=0
	Set tJob="" For { Set tJob=$$$OrderJobMonitor(tJob) Quit:tJob=""
		If +tJob=tJob Continue ; Skip BP-Id nodes
		Set tHost="" For { Set tHost=$$$OrderJobMonitor(tJob,tHost) Quit:""=tHost
			Set tJobCount=tJobCount+1
			If $$$GetJobMonitor(tHost,tJob,$$$eMonitorStatus)="OK"       Set tJobOKCount=tJobOKCount+1
			If $$$GetJobMonitor(tHost,tJob,$$$eMonitorStatus)="Inactive" Set tJobInactiveCount=tJobInactiveCount+1
		}
	}
	Set pResult("1CountTotal")=tJobCount
	Set pResult("2StatusOK")=tJobOKCount
	Set pResult("3StatusInactive")=tJobInactiveCount
	Set pResult("4StatusOther")=tJobCount-tJobOKCount-tJobInactiveCount
	;
	If pGetCaption {
		Set pResult("1CountTotal","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","TotalJobsRunning","Total Jobs Running")
		Set pResult("2StatusOK","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","JobsOK","Jobs OK")
		Set pResult("3StatusInactive","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","JobsInactive","Jobs Inactive")
		Set pResult("4StatusOther","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","JobsOther","Jobs of Other Status")
	}
	Quit
}

ClassMethod GetLogSummary(ByRef pResult, pGetCaption, pLanguage)
{
	Set pResult("1LastErrorTime")=##class(Ens.DataType.UTC).LogicalToDisplay($$$GetLogMonitor($$$eLogTypeError,"%LastActivity"))
	Set pResult("2TotalErrorCount")=+$$$GetLogMonitor($$$eLogTypeError,"%Count")
	;
	If pGetCaption {
		Set pResult("1LastErrorTime","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","LastErrorTime","Last Error Time")
		Set pResult("2TotalErrorCount","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","TotalErrorCount","Total Error Count")
	}
	Quit
}

ClassMethod GetServiceSummary(ByRef pResult, pGetCaption, pLanguage)
{
	set tLastActivity="",tCompletedCount=0
	Set tHost="" For { Set tHost=$$$OrderHostMonitor(tHost)  Quit:tHost=""
		Continue:tHost="Ens.MonitorService"
		Continue:$G($$$ConfigBusinessType(tHost))'=$$$eHostTypeService
		set thislastavtivity=$$$GetHostMonitor(tHost,$$$eMonitorLastActivity)
		if thislastavtivity]tLastActivity set tLastActivity=thislastavtivity
		set tCompletedCount=tCompletedCount+$$$GetHostMonitor(tHost,$$$eMonitorCount)
	}
	;
	Set pResult("1LastActivityTime")=##class(Ens.DataType.UTC).LogicalToDisplay(tLastActivity)
	Set pResult("2ActivitiesCompleted")=tCompletedCount
	;Set pResult("3MessagesInProgress")="?"
	;
	If pGetCaption {
		Set pResult("1LastActivityTime","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","LastActivity","Last Activity Time")
		Set pResult("2ActivitiesCompleted","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","ActivityCount","Activities Completed")
		;Set pResult("3MessagesInProgress","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","MessagesInQueues","Messages in Progress")
	}
	Quit
}

ClassMethod GetProcessSummary(ByRef pResult, pGetCaption, pLanguage)
{
	Set tQueueCount=+$get(^Ens.Queue("Ens.Actor",0,"count")),tInProgressCount=0
	Set tHost="" For { Set tHost=$$$OrderHostMonitor(tHost)  Quit:tHost=""
		Continue:$G($$$ConfigBusinessType(tHost))'=$$$eHostTypeProcess
		Set tQueueCount=tQueueCount+$get(^Ens.Queue(tHost,0,"count"))
		Set tJob="" For { Set tJob=$$$OrderHostMonitor(tHost,$$$eMonitorJob,tJob) Quit:tJob=""
			If $g($$$EnsActiveMessage(tJob))'="" Set tInProgressCount=tInProgressCount+1
		}
	}
	Set pResult("1LastActivityTime")=##class(Ens.DataType.UTC).LogicalToDisplay($$$GetHostMonitor("Ens.Actor",$$$eMonitorLastActivity))
	Set pResult("2ActivitiesCompleted")=+$$$GetHostMonitor("Ens.Actor",$$$eMonitorCount)
	Set pResult("3MessagesInProgress")=tInProgressCount
	Set pResult("4MessagesInQueues")=tQueueCount

	If pGetCaption {
		Set pResult("1LastActivityTime","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","LastActivity","Last Activity Time")
		Set pResult("2ActivitiesCompleted","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","ActivityCount","Activities Completed")
		Set pResult("3MessagesInProgress","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","MessagesInProgress","Messages in Progress")
		Set pResult("4MessagesInQueues","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","MessagesInQueues","Messages in Queues")
	}
	Quit
}

ClassMethod GetOperationSummary(ByRef pResult, pGetCaption, pLanguage)
{
	set tLastActivity="",tCompletedCount=0,tQueueCount=0,tInProgressCount=0
	Set tHost="" For { Set tHost=$$$OrderHostMonitor(tHost)  Quit:""=tHost
		Continue:$G($$$ConfigBusinessType(tHost))'=$$$eHostTypeOperation
		set thislastavtivity=$$$GetHostMonitor(tHost,$$$eMonitorLastActivity)
		if thislastavtivity]tLastActivity set tLastActivity=thislastavtivity
		set tCompletedCount=tCompletedCount+$$$GetHostMonitor(tHost,$$$eMonitorCount)
		set tQueueCount=tQueueCount+$get(^Ens.Queue(tHost,0,"count"))
		Set tJob="" For { Set tJob=$$$OrderHostMonitor(tHost,$$$eMonitorJob,tJob) Quit:tJob=""
			If $g($$$EnsActiveMessage(tJob))'="" Set tInProgressCount=tInProgressCount+1
		}
	}
	Set pResult("1LastActivityTime")=##class(Ens.DataType.UTC).LogicalToDisplay(tLastActivity)
	Set pResult("2ActivitiesCompleted")=tCompletedCount
	Set pResult("3MessagesInProgress")=tInProgressCount
	Set pResult("4MessagesInQueues")=tQueueCount

	If pGetCaption {
		Set pResult("1LastActivityTime","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","LastActivity","Last Activity Time")
		Set pResult("2ActivitiesCompleted","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","ActivityCount","Activities Completed")
		Set pResult("3MessagesInProgress","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","MessagesInProgress","Messages in Progress")
		Set pResult("4MessagesInQueues","caption")=$$FormatMessage^%occMessages(pLanguage,"Ensemble","MessagesInQueues","Messages in Queues")
	}
	Quit
}

ClassMethod CreateResetCounter()
{
	Kill ^Ens.Configuration("csp","ResetCounter")
	Set ^Ens.Configuration("csp","ResetCounter","timeset")=$$$timeUTC
	Do ..UpdateResetCounter()
	Quit
}

ClassMethod DeleteResetCounter()
{
	Kill ^Ens.Configuration("csp","ResetCounter")
	Quit
}

ClassMethod UpdateResetCounter()
{
	Set tTimeStamp=^Ens.Configuration("csp","ResetCounter","timeset")
	;
	&sql(SELECT COUNT(*) INTO :tCount From Ens.BusinessProcess WHERE %TimeCreated < :tTimeStamp)
	Set ^Ens.Configuration("csp","ResetCounter","Process")=tCount
	;
	&sql(SELECT COUNT(*) INTO :tCount From Ens.MessageHeader WHERE TimeCreated < :tTimeStamp)
	Set ^Ens.Configuration("csp","ResetCounter","Message")=tCount
	;
	&sql(SELECT COUNT(*) INTO :tCount From Ens_Util.Log WHERE TimeLogged < :tTimeStamp)
	Set ^Ens.Configuration("csp","ResetCounter","Log")=tCount
	;
	Quit
}

ClassMethod GetResetCounterTimestampCaption(pLanguage = "") As %String
{
	If $data(^Ens.Configuration("csp","ResetCounter","timeset"),tTimeSet) {
		Quit $$FormatMessage^%occMessages(pLanguage,"Ensemble","CounterReset","Counter reset to zero at ")_$$$timeUTCtoLocal(tTimeSet)
	} Else {
		Quit $$FormatMessage^%occMessages(pLanguage,"Ensemble","NoCounterReset","Reset counter not established")
	}
}

}
