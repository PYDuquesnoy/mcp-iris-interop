/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syTask

/// Used to initialize system values on new installs
/// and to convert the task manager from previous versions.
/// 
Class %SYS.Task.Init Extends %RegisteredObject [ System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// ToV31 add PurgeInteropUsage task
ClassMethod ToV31() As %Status
{
	/// Initialize system tasks
    Set Status=..ToV30()
    If Status {
		Set Status=..CreatePurgeInteropUsageMetrics()
    }	
    Quit Status
}

/// ToV30 remove redundent tasks
ClassMethod ToV30() As %Status
{
	/// Initialize system tasks
    Set Status=..ToV29() If 'Status Quit Status
	Set Status=##class(%SYS.Task).%DeleteId($$$UpdateSQLStats)
	Set Status=##class(%SYS.Task).%DeleteId($$$FrozenPlanScan)
	Set Status=##class(%SYS.Task).%DeleteId($$$CleanSQLIndex)
	Set Status=##class(%SYS.Task).%DeleteId($$$ResourceClean)
    Quit $$$OK
}

/// ToV29 decode Diagnostic Report email password
ClassMethod ToV29() As %Status
{
	/// Initialize system tasks
    Set Status=..ToV28() If 'Status Quit Status
	s Task=##Class(%SYS.Task).%OpenId($$$SendDiagnosticReport)
	i Task {
		Set Settings=Task.Settings
		For i=1:2:($ll(Settings)) {
			Set name=$li(Settings,i)
			If name="SMTPPass" {
				Set value=$li(Settings,i+1) Quit:value=""
				Try {
					s pwd=$system.Encryption.Base64Decode(value)
					s $li(Settings,i+1)=pwd
					s Task.Settings=Settings
					d Task.%Save()
				} Catch {
				}
				Quit
			}
		}
		k Task
	}
    Quit $$$OK
}

/// ToV28 fix PurgeBackupLog 
ClassMethod ToV28() As %Status
{
	/// Initialize system tasks
    Set Status=..ToV27()
    If Status {
	s Task=##Class(%SYS.Task).%OpenId($$$PurgeBackupLogNumber)
	i Task s Task.TaskClass="%SYS.Task.PurgeBackupLog" d Task.%Save()
    }
    Quit Status
}

/// ToV27 modify default MirrorStatus
ClassMethod ToV27() As %Status
{
	/// Initialize system tasks
    Set Status=..ToV26()
    If Status {
	    #; update default MirrorStatus if not currently a Mirror member
	    If '$SYSTEM.Mirror.IsMember() {
			s tl=$$$SwitchJournalNumber_","_$$$PurgeJournalNumber_","_$$$PurgeTaskDataNumber
			s tl=tl_","_$$$IntegrityCheckNumber_","_$$$SecurityScanNumber_","_$$$SendDiagnosticReport
			s tl=tl_","_$$$PurgeAuditDatabase_","_$$$InventoryScan_","_$$$PurgeErrorsAndLogNumber
			s tl=tl_","_$$$CheckLoggingNumber_","_$$$PurgeBackupLogNumber
			f tn=1:1:$l(tl,",") { 
				s Task=##Class(%SYS.Task).%OpenId($p(tl,",",tn))
				i Task s Task.MirrorStatus=3 d Task.%Save()
			}
	    }
    }	
    Quit Status
}

/// ToV26 Add PurgeErrorsAndLogs
ClassMethod ToV26() As %Status
{
	/// Initialize system tasks
    Set Status=..ToV25()
    If Status {
	    /// One time upgrade of PurgeJournal
	    If ##class(%SYS.Task).VersionGet()<2.6 {
			Set Task=##Class(%SYS.Task).%OpenId($$$PurgeJournalNumber)
			Set SJguid=##class(%SYS.Task).GetRunAfterGUID($$$SwitchJournalNumber)
			If Task,Task.TimePeriod=$$$RUNAFTER,Task.RunAfterGUID=SJguid {
				k Task
				Do ##class(%SYS.Task).%DeleteId($$$PurgeJournalNumber)
				Do ..CreatePurgeJournal()
			}
	    }
    }	
    Quit Status
}

/// ToV25 fix filing of PurgeAudit, PurgeJournal
ClassMethod ToV25() As %Status
{
	/// Initialize system tasks
    Set Status=..ToV21()
    If Status {
    	For Idx=$$$PurgeJournalNumber,$$$PurgeAuditDatabase {
	    	Set task=##class(%SYS.Task).%OpenId(Idx)
	    	If task.TimePeriod'=$$$RUNAFTER Continue  /// no longer run after
	    	Set task.TimePeriodDay=""
	    	Set Stauts=task.%Save() Quit:$$$ISERR(Status)
    	}
    }
    Quit Status
}

/// ToV24 added the Purge Audit task
ClassMethod ToV24() As %Status
{
	/// Just want to initialize system tasks
    Quit ..ToV21()
}

/// ToV23 added the SendButtons task
ClassMethod ToV23() As %Status
{
	Quit ..ToV22()
}

/// ToV22 added the SecurityScan task
ClassMethod ToV22() As %Status
{
	Set Status=..ToV21()
	Quit Status
}

/// converts tasks from V2.0 to V2.1
ClassMethod ToV21() As %Status
{
	Set Status=..ToV20()
	Quit:'Status Status
	Kill ^%IRISTaskConfigD,^%IRISTaskConfigI,^%IRISTaskD,^%IRISTaskHistoryD,^%IRISTaskHistoryI,^%IRISTaskI
	Do ..InitializeSystemTasks()
	Quit $$$OK
}

/// converts tasks from V1.4 to V2.0
ClassMethod ToV20() As %Status
{
	D $zu(5,"%SYS")
	if $namespace'="%SYS" quit $$$ERROR($$$GeneralError,"Cannot change to %SYS")
#;V20 tasks already exist
	Quit:$o(^SYS("Task","TaskD",""))]"" $$$OK
	Set ID=""
	Set:^%IRISTaskD<1000 ^%IRISTaskD=999
	For  {
		Set ID=$O(^%IRISTaskD(ID))
		Quit:ID=""
		Set data=^%IRISTaskD(ID)
		#; there was a bug in some old versions where the high pointer was not set we need to move tasks from 6-999 
		Set runAfter(ID)=ID,NEWID=ID
		If ID>5,ID<1000 Set NEWID=$i(^%IRISTaskD)
		If $D(^SYS("Task","TaskD",NEWID)) Continue  //Already filed
		Set ^SYS("Task","TaskD",NEWID)=data
		Set obj=##class(%SYS.Task).%OpenId(NEWID,4)
		Set obj.Settings=$lb("ExecuteCode",obj.TaskClass)
		Set obj.TaskClass="%SYS.Task.RunLegacyTask"
		Set runafter=$lg(data,32)
		If runafter Set obj.RunAfterGUID=$G(runAfter(runafter))
		Set obj.RunAsUser="_SYSTEM"
		For i=1:1:obj.EmailOnError.Count() { Do obj.EmailOnExpiration.Insert(obj.EmailOnError.GetAt(i))}
		Set status=obj.%Save()
		Set runAfter(ID)=obj.JobGUID
		
	}
	Set ^SYS("Task","TaskD")=$o(^SYS("Task","TaskD",""),-1)
	Do ##class(%SYS.Task).%BuildIndices()

	Set ID=""
	For  {
		Set ID=$O(^%IRISTaskConfigD(ID))
		Quit:ID=""
		Set ^SYS("Task","ConfigD",ID)=^%IRISTaskConfigD(ID)
	}
	Set ^SYS("Task","ConfigD")=$o(^SYS("Task","ConfigD",""),-1)
	Do ##class(%SYS.Task.Config).%BuildIndices()


	Set ID=""
	For  {
		Set ID=$O(^%IRISTaskHistoryD(ID))
		Quit:ID=""
		Set ^SYS("Task","HistoryD",ID)=^%IRISTaskHistoryD(ID)
	}
	Set ^SYS("Task","HistoryD")=$o(^SYS("Task","HistoryD",""),-1)
	Do ##class(%SYS.Task.History).%BuildIndices()
	Do ##class(%SYS.Task.Config).Initialize()
	Quit $$$OK
}

ClassMethod CreateSwitchJournal() As %Status
{
	Set Status=$$$OK
	Set Number=$$$SwitchJournalNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYS.Task).%New()
		Set Task.Name=$$$Text("Switch Journal")
		#;Must set type before number
		Set Task.Type=0
		Set Task.Description=$$$Text("Switches the journal file at midnight every day")
		Set Task.TaskClass="%SYS.Task.SwitchJournal"
		Set Task.RescheduleOnStart=1
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreateSecurityScan() As %Status
{
	Set Status=$$$OK
	Set Number=$$$SecurityScanNumber
	
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYS.Task).%New()
		Set Task.Name=$$$Text("Security Scan")
		#;Must set type before number
		Set Task.Type=0
		Set Task.Description=$$$Text("Scans the security database at midnight every day")
		Set Task.TaskClass="%SYS.Task.SecurityScan"
		Set Task.RescheduleOnStart=1
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreateCleanSourceJournal() As %Status
{
	Set Status=$$$OK
	Set Number=$$$CleanSourceJournalNum
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Cleanup Source Journal")
		Set Task.Type=0
		Set Task.Description=$$$Text("Cleans old source journal nodes every night at 1:00 am")
		Set Task.TaskClass="%SYS.Task.CleanSourceJournal"
		#;Every day at 1:00 am
		Set Task.DailyStartTime=3600
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreatePurgeJournal() As %Status
{
	Set Status=$$$OK
	Set Number=$$$PurgeJournalNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Purge Journal")
		Set Task.Type=0
		Set Task.Description=$$$Text("Purges old journal files every night at 12:30 am")
		Set Task.TaskClass="%SYS.Task.PurgeJournal"
		#;Every day at 12:30 am
		Set Task.DailyStartTime=1800
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreatePurgeBackupLog() As %Status
{
	Set Status=$$$OK
	Set Number=$$$PurgeBackupLogNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Purge Backup Log")
		Set Task.Type=0
		Set Task.Description=$$$Text("Purges messages from IRIS backup log that are more than 30 days old every night at 1:30 am")
		Set Task.TaskClass="%SYS.Task.PurgeBackupLog"
		#;Every day at 1:30 am
		Set Task.DailyStartTime=5400
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreatePurgeZENReports() As %Status
{
	Set Status=$$$OK
	Set Number=$$$PurgeZENReports
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Purge ZEN Reports temp files")
		Set Task.Type=0
		Set Task.Description=$$$Text("Purges ZEN Reports temp files every night at 1:30 am")
		Set Task.TaskClass="%SYS.Task.PurgeZENReports"
		#;Every day at 1:30 am
		Set Task.DailyStartTime=5400
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreatePurgeAudit() As %Status
{
	Set Status=$$$OK
	Set Number=$$$PurgeAuditDatabase
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYS.Task).%New()
		Set Task.Name=$$$Text("Purge Audit Database")
		Set Task.Type=0
		Set Task.Description=$$$Text("Purges old Audit information after Switch Journal is run")
		Set Task.TaskClass="%SYS.Task.PurgeAudit"
		Set Task.TimePeriod=$$$RUNAFTER
		Set Task.RunAfterGUID=##class(%SYS.Task).GetRunAfterGUID($$$SwitchJournalNumber)
		Set Task.TimePeriodDay=""
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreatePurgeTaskHistory() As %Status
{
	Set Status=$$$OK
	Set Number=$$$PurgeTaskDataNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Purge Tasks")
		Set Task.Type=0
		Set Task.Description=$$$Text("Purges the task history global every night at 1:00 am")
		Set Task.TaskClass="%SYS.Task.PurgeTaskHistory"
		#;Every day at 1:00 am
		Set Task.DailyStartTime=3600
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreateFreeSpaceTask() As %Status
{
	#;This task calculates the free space for all the databases
	#;so the control panel displays it correctly. It is
	#;set to suspended.
	
	Set Status=$$$OK
	Set Number=$$$FreeSpaceNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Free Space")
		Set Task.Type=0
		Set Task.Description=$$$Text("Recalculate free space for all databases at 4:00 am")
		Set Task.TaskClass="%SYS.Task.FreeSpace"
		#;Every day at 4:00 am
		Set Task.DailyStartTime=14400
		#;Low priority
		Set Task.Priority=1
		#;Set the task to suspended
		Set Task.Suspended=2
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreateIntegrityCheck() As %Status
{
	#;This task performs an integrity check on all databases.
	#;It is set to suspended so we don't automatically run checks for all databases.
	Set Status=$$$OK
	Set Number=$$$IntegrityCheckNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYSTEM.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Integrity Check")
		Set Task.Type=0
		Set Task.Description=$$$Text("Integrity check for databases at 2:00 am every Monday")
		Set Task.TaskClass="%SYS.Task.IntegrityCheck"
		Set Task.TimePeriod=1			;Weekly<br>
		Set Task.TimePeriodEvery=1		;Every week<br>
		Set Task.TimePeriodDay=2		;On Monday<br>
		Set Task.DailyStartTime=7200 	;At 2:00 am<br>
		#;Low priority
		Set Task.Priority=1
		#;Set the task to suspended
		Set Task.Suspended=2
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreateDiagnosticReport() As %Status
{
	#;This task collects diagnostics report (a.k.a.Buttons). 
	#;Initialy this is set to run on demand with basic ("little buttons")
	Set Status = $$$OK
	Set Number = $$$SendDiagnosticReport
	
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	///if not present add task
	if 'Task {
		Set Task = ##Class(%SYS.Task).%New()
		Set Task.Name = $$$Text("Diagnostic Report")
		#;Must set type before number
        Set Task.Type = 0
		Set Task.Description = $$$Text("Send system diagnostic reports to WRC On Demand, and/or on a schedule")
		Set Task.TaskClass="%SYS.Task.DiagnosticReport"
		#; to be run on demand
		Set Task.TimePeriod = 5
		#; every seven days			
		Set Task.TimePeriodEvery = 7		
		Set Task.TimePeriodDay = ""
		#; base the run time on when the task was initialized (preventing all reports from arriving via email at the exact same time)
		Set Task.DailyStartTime = $P($H,",",2)
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status = Task.%Save()		
	}
	Quit Status
}

ClassMethod CreateInventoryScan() As %Status
{
	#;This task collects an inventory scan 
	#;Initially this is set to run only once, at the next available opportunity
	#;which should be startup after the install or upgrade.
	Set Status = $$$OK
	Set Number = $$$InventoryScan
	
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	///if not present add task
	if 'Task {
		Set Task = ##Class(%SYS.Task).%New()
		Set Task.Name = $$$Text("Inventory Scan")
		#;Must set type before number
        Set Task.Type = 0
		Set Task.Description = $$$Text("Run a scan of the system inventory on install or upgrade and on demand thereafter")
		Set Task.TaskClass="%SYS.Task.InventoryScan"
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.TimePeriod=Task.TimePeriodDisplayToLogical("On Demand")
		Set Task.IsBatch = 1
		Set Task.MirrorStatus=3
		Set Status = Task.%Save()	
	}
	Quit Status
}

ClassMethod CreatePurgeErrorsAndLogs() As %Status
{
	Set Status=$$$OK
	Set Number=$$$PurgeErrorsAndLogNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Purge errors and log files")
		Set Task.Type=0
		Set Task.Description=$$$Text("Purges errors and log files at 1:00 am")
		Set Task.TaskClass="%SYS.Task.PurgeErrorsAndLogs"
		#;Every day at 1:00 am
		Set Task.DailyStartTime=3600
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreateCheckLogging() As %Status
{
	Set Status=$$$OK
	Set Number=$$$CheckLoggingNumber
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Check Logging activity")
		Set Task.Type=0
		Set Task.Description=$$$Text("Check active application logging at 1:00 am")
		Set Task.TaskClass="%SYS.Task.CheckLogging"
		#;Every day at 1:00 am
		Set Task.DailyStartTime=3600
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set logtask=##class(%SYS.Task.CheckLogging).%New()
		Set Task.Settings=logtask.GetSettings()
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreateFeatureTracker() As %Status
{
	#;This task collects and sends data for Feature Tracker
	Set Status=$$$OK
	Set Number=$$$FeatureTrackerNumber
	#; If FeatureTracker task already defined, do not change it
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYSTEM.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=$$$Text("Feature Tracker")
		Set Task.Type=0
		Set Task.Description=$$$Text("Collects data on feature use and sends to ISC weekly")
		Set Task.TaskClass="%SYS.Task.FeatureTracker"
		Set Task.TimePeriod=1			;Weekly<br>
		Set Task.TimePeriodEvery=1		;Every week<br>
		Set Task.TimePeriodDay=1		;On Sunday<br>
		Set Task.DailyStartTime=0 		;At 12:00 am<br>
		#;Low priority
		Set Task.Priority=1
		    #; If you want the new Feature Tracker task to default
		    #; to suspended and to have it only be enabled by the
		    #; customer then uncomment the next source line.
		#; Set Task.Suspended=1			; SOH613
		    #; If the previous source line is commented out then
		    #; a newly created Feature Tracker defaults to enabled
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod CreatePurgeInteropUsageMetrics() As %Status
{
	Set Status=$$$OK
	Set Number=$$$PurgeInteropUsage
	If ##class(%SYS.Task).%ExistsId(Number) Quit $$$OK
	Set Task=##Class(%SYS.Task).%OpenId(Number)
	If 'Task {
		Set Task=##Class(%SYS.Task).%New()
		Set Task.Name=$$$Text("Purge Interoperability Usage Metrics")
		Set Task.Type=0
		Set Task.Description=$$$Text("Consoldiates and purges interoperability usage metrics")
		Set Task.TaskClass="%SYS.Task.PurgeInteropUsageMetrics"
		Set Task.DailyStartTime=1800 	;12:30AM
		Set Task.TimePeriod=1			;Weekly
		Set Task.TimePeriodEvery=1		;Every week
		Set Task.TimePeriodDay=1		;Sunday
		Do Task.idSet(Number)
		Set Task.RunAsUser="_SYSTEM"
		Set Task.MirrorStatus=3
		Set Status=Task.%Save()
	}
	Quit Status
}

ClassMethod ScheduleInventoryScan() As %Status
{
	Quit ##class(%SYS.Task).RunNow($$$InventoryScan)
}

ClassMethod InitializeSystemTasks() As %Status
{
	Set Status=##class(%SYS.Task.Config).Initialize()
	Set:Status Status=..CreateSwitchJournal()
	Set:Status Status=..CreatePurgeJournal()
	Set:Status Status=..CreatePurgeTaskHistory()
#;Delete old freespace if it exists
	Set Task=##Class(%SYS.Task).%OpenId($$$FreeSpaceNumber)
	If $isObject(Task) {
		i Task.Name="Free Space" {
			k Task
			Do ##class(%SYS.Task).%DeleteId($$$FreeSpaceNumber)
		}
	}
	Set:Status Status=..CreateIntegrityCheck()
	Set:Status Status=..CreateSecurityScan()
	Set:Status Status=..CreateDiagnosticReport()
	Set:Status Status=..CreatePurgeAudit()
	Set:Status Status=..CreateInventoryScan()
	Set:Status Status=..CreatePurgeErrorsAndLogs()
	Set:Status Status=..CreateCheckLogging()
	Set:Status Status=..CreatePurgeBackupLog()
	Set:Status Status=..CreatePurgeZENReports()
	Set:Status Status=..CreateFeatureTracker()
	Set:Status Status=..CreateCleanSourceJournal()
	Set:Status Status=..CreatePurgeInteropUsageMetrics()
	Do ..SetHighValue()
	Quit Status
}

ClassMethod SetHighValue() As %Status
{
	If $G(^SYS("Task","TaskD"))<999 Set ^SYS("Task","TaskD")=999
	Quit $$$OK
}

}
