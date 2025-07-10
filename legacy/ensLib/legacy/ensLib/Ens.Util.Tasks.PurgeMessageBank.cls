/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.Tasks.PurgeMessageBank Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter RESOURCE = "%Ens_PurgeSchedule:USE";

/// How many days of messages should not be purged
Property NumberOfDaysToKeep As %Integer(MINVAL = 0) [ InitialExpression = 7 ];

/// Preserve messages not yet completely processed
Property KeepIntegrity As %Boolean [ InitialExpression = 1 ];

/// Delete message bodies whenever their message header is deleted. This is off by default because some Productions may
/// use message objects that are part of a larger environment and not transitory.
Property BodiesToo As %Boolean [ InitialExpression = 0 ];

/// The type of thing to purge
Property TypesToPurge As %String(DISPLAYLIST = ",All Types,Events,Messages,Business Processes,Rule Logs,I/O Logs,Host Monitor Data,Message Bank Events,Message Bank Messages", VALUELIST = ",all,events,messages,processes,rulelogs,iologs,hostcounters,message bank events,message bank messages") [ InitialExpression = "events", Required ];

/// The OnTask() method is called to execute the task
Method OnTask() As %Status
{
	Set tTime = $ZH
    Set tDeletedCount = -1
    Set tBitmapCount = 0
    
    If ..TypesToPurge = "all" {
		Set tSC = ##class(Ens.Enterprise.MsgBank.Purge).PurgeAll(.tDeletedCount,..NumberOfDaysToKeep,..KeepIntegrity,..BodiesToo)
			Set (type,tDeletedCount)="" For { Set type=$O(tDeletedCount(type),1,count)  Quit:""=type  Continue:'count
				Set tDeletedCount=tDeletedCount_", "_count_" "_type
			} 
		Set tDeletedCount=$E(tDeletedCount,3,$L(tDeletedCount)) // get rid of the leading comma and space
		Set tBitmapCount = -1
    } ElseIf ..TypesToPurge = "events" {
		Set tSC = ##class(Ens.Purge).PurgeEventLogsByDate(..NumberOfDaysToKeep,.tDeletedCount,..KeepIntegrity)
    } ElseIf ..TypesToPurge = "messages" {
		Set tSC = ##class(Ens.Purge).PurgeMessagesByDate(..NumberOfDaysToKeep,.tDeletedCount,..KeepIntegrity,..BodiesToo)
		Set tDeletedCount=tDeletedCount_$S($G(tDeletedCount("bodies")):"("_tDeletedCount("bodies")_" bodies)",1:"")
    } ElseIf ..TypesToPurge = "processes" {
		Set tSC = ##class(Ens.Purge).PurgeBusinessProcessesByDate(..NumberOfDaysToKeep,.tDeletedCount,..KeepIntegrity)
    } ElseIf ..TypesToPurge = "rulelogs" {
		Set tSC = ##class(Ens.Purge).PurgeRuleLogsByDate(..NumberOfDaysToKeep,.tDeletedCount,..KeepIntegrity)
    } ElseIf ..TypesToPurge = "iologs" {
		Set tSC = ##class(Ens.Util.IOLog).Purge(.tDeletedCount,..NumberOfDaysToKeep,..KeepIntegrity) 
    } ElseIf ..TypesToPurge = "hostcounters" {
		Set tSC = ##class(Ens.MonitorService).Purge(.tDeletedCount,..NumberOfDaysToKeep,..KeepIntegrity)  
    } ElseIf ..TypesToPurge = "message bank events" {
		Set tSC = ##class(Ens.Enterprise.MsgBank.Log).Purge(.tDeletedCount,..NumberOfDaysToKeep)
    } ElseIf ..TypesToPurge = "message bank messages" {
		Set tSC = ##Class(Ens.Enterprise.MsgBank.MessageHeader).Purge(.tDeletedCount,..NumberOfDaysToKeep,..KeepIntegrity,..BodiesToo)
		Set tDeletedCount=tDeletedCount_$S($G(tDeletedCount("bodies")):"("_tDeletedCount("bodies")_" bodies)",1:"")
    } ElseIf $ZStrip(..TypesToPurge,"*WC") = "" {
		Set tSC = $$$ERROR($$$EnsErrGeneral,"No TypesToPurge specified")
    } Else {
		Set tSC = $$$ERROR($$$EnsErrGeneral,"Unrecognized TypesToPurge value '"_..TypesToPurge_"'") 
    }
	Set tTime = $ZH - tTime
	If $$$ISOK(tSC) {
		If (tBitmapCount = 0) {
			Set tBitmapCount = +$get(tDeletedCount("bitmaps"))
		}
		$$$LOGINFO("Purged "_tDeletedCount_" "_..TypesToPurgeLogicalToDisplay(..TypesToPurge)_$S(tBitmapCount > 0: " and "_tBitmapCount_" bitmap chunks", 1: "")_" keeping the last "_..NumberOfDaysToKeep_" days with KeepIntegrity="_..KeepIntegrity_$S($Case(..TypesToPurge,"all":1,"messages":1,:0):" and BodiesToo="_..BodiesToo,1:"")_" in "_tTime_"s")
	}
	Else { $$$LOGERROR("Error purging"_..TypesToPurgeLogicalToDisplay(..TypesToPurge)_" keeping the last "_..NumberOfDaysToKeep_" days with KeepIntegrity="_..KeepIntegrity_$S($Case(..TypesToPurge,"all":1,"messages":1,:0):" and BodiesToo="_..BodiesToo,1:"")_" : "_ $$$StatusDisplayString(tSC)) }
	Quit tSC
}

/// Purge the message store, and event log
ClassMethod PurgeAll(pTypesToPurge As %String = "all", pNumberOfDaysToKeep As %Integer = 0, pBodiesToo As %Boolean = 1) As %Status
{
	Set tTask = ..%New()
	Set tTask.TypesToPurge = pTypesToPurge
	Set tTask.NumberOfDaysToKeep = pNumberOfDaysToKeep
	Set tTask.BodiesToo = pBodiesToo
	Quit tTask.OnTask()
}

}
