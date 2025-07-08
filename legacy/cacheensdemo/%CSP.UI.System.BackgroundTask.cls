/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This class supplies the ManagementPortal with a way to 
/// execute certain tasks as background jobs.<br>
/// For example, you can rebuild indices for a class:
/// <example>
/// Set tParms("ClassName") = "Sample.Person"
/// Set tSC = ..RunTask("RebuildIndices","SAMPLES",.tParms,.tJob)
/// </example>
Class %CSP.UI.System.BackgroundTask Extends %RegisteredObject [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// This defines the allowed tasks that this class can run
Parameter TASKS = ",AuditCopy,AuditExport,AuditPurge,Backup,CompactDBSpace,CopyNamespaceMappings,CreateDatabase,Compile,DatabaseIntegrityCheck,DataMigration,DefragmentDB,Delete,EnableEnsNamespace,Export,ExternalLangServers,FileMan,Import,SQLExport,SQLImport,SQLExportStatement,SQLImportStatement,QueryExport,JournalIntegrityCheck,LinkTable,LinkProcedure,MirrorActivateCatchupDB,MirrorDownloadDB,MirrorRemoveDB,MirrorMountDB,MirrorAddDatabases,ModifyDatabaseSize,RebuildIndices,TuneTable,TuneTables,PurgeAllCachedQueries,JobShowPlan,JobSaveQuery,JobPossiblePlans,JobComparePlans,ShardActivate,ShardAssign,ShardVerify,ShardRebalance,Task1";

/// Use this method to request a background task
/// <var>pTask</var> is name of task to run; it must one of the entries
/// in the TASKS parameter.<br>
/// <var>pNS</var> is namespace to run task in.<br>
/// <var>pParms</var> is a array containing parameters for the task
/// in the form pParms(parm)=value.<br>
/// It returns a PID# if the task is started, or 0 if it fails to start.
ClassMethod RunTask(pTask As %String, pNS As %String, ByRef pParms As %String, ByRef tItems As %String = "", ByRef pJob As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pJob = 0
	Set $ZT = "Trap"

	Do {	
		If (..#TASKS '[ (","_pTask_",")) {
			// task not defined
			Set tSC = $$$ERROR($$$GeneralError,"TaskNotDefined")
			Quit
		}

		// build list of parms as a $List
		Set tParmList = ""
		Set p = $O(pParms(""))
		While (p '= "") {
			Set tParmList = tParmList _ $LB(p,pParms(p))
			Set p = $O(pParms(p))
		}
		// Saves tItems array that contains all selected
		// items into temp global for the job because you pass array for Job 
		Set tIdx = $increment(^|"%SYS"|IRIS.Temp)
		Kill ^|"%SYS"|IRIS.Temp(tIdx)
		Merge ^|"%SYS"|IRIS.Temp(tIdx) = tItems
		Job ##class(%CSP.UI.System.BackgroundTask).RunBackgroundTask(pTask,pNS,tParmList,tIdx)::10
		Set pJob = $ZCHILD
		#; Return "Task job timeout error" if Job failed.
		If +pJob = 0 Set tSC = $$$ERROR(7453)
	} While(0)

Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// This wrapper method is run in the background job.
/// <var>pParms</var> is a list of parameters.
ClassMethod RunBackgroundTask(pTask As %String, pNS As %String, pParmList As %List, pIdx As %Integer)
{
	Set $ZT="Trap"
 	i $$$AuditLoginSuccess($$$ServiceTaskMgr,,pTask)
	
	ZN pNS
	// Merge tItems array back from temp global and clean up temp global
	Merge tItems = ^|"%SYS"|IRIS.Temp(pIdx)
	Kill ^|"%SYS"|IRIS.Temp(pIdx)
	// reconstruct parameter array
	Set ptr=0,count=0
	While $ListNext(pParmList,ptr,name) {
		If '$ListNext(pParmList,ptr,value) Quit
		Set:name'="" tParms(name) = value
	}
	Set msgTask("AuditCopy") = $$$Text("Copy Audit Log")
	Set msgTask("AuditExport") = $$$Text("Export Audit Log")
	Set msgTask("AuditPurge") = $$$Text("Purge Audit Log")
	Set msgTask("CompactDBSpace") = $$$Text("Compact DB Space")
	Set msgTask("Compile") = $$$Text("Compile")
	Set msgTask("CopyNamespaceMappings") = $$$Text("Copy Namespace Mappings")
	Set msgTask("CreateDatabase") = $$$Text("Create Database")
	Set msgTask("DatabaseIntegrityCheck") = $$$Text("Database Integrity Check")
	Set msgTask("DataMigration") = $$$Text("Data Migration")
	Set msgTask("DefragmentDB") = $$$Text("Defragment Database")
	Set msgTask("Delete") = $$$Text("Delete")
	Set msgTask("EnableEnsNamespace") = $$$Text("Enable Namespace for Use with Productions")
	Set msgTask("Export") = $$$Text("Export")
	Set msgTask("ExternalLangServers") = $$$Text("External Languages Servers")	
	Set msgTask("FileMan") = $$$Text("FileMan")
	Set msgTask("Import") = $$$Text("Import")
	Set msgTask("QueryExport") = $$$Text("Query Export")
	Set msgTask("JournalIntegrityCheck") = $$$Text("Journal Integrity Check")
	Set msgTask("LinkTable") = $$$Text("Link Table")
	Set msgTask("LinkProcedure") = $$$Text("Link Procedure")
	Set msgTask("MirrorActivateCatchupDB") = $$$Text("Activate/Catchup Mirrored Databases")
	#;SML3207
	Set msgTask("MirrorDownloadDB") = $$$Text("Download Mirrored Databases")
	Set msgTask("MirrorRemoveDB") = $$$Text("Remove Databases from Mirror")
	Set msgTask("MirrorMountDB") = $$$Text("Mount Mirrored Databases")
	Set msgTask("MirrorAddDatabases") = $$$Text("Add Databases to Mirror")
	Set msgTask("ModifyDatabaseSize") = $$$Text("Modify Database Size")
	Set msgTask("RebuildIndices") = $$$Text("Rebuild Indices")
	Set msgTask("SQLExport") = $$$Text("SQL Export")
	Set msgTask("SQLImport") = $$$Text("SQL Import")
	Set msgTask("SQLExportStatement") = $$$Text("Export SQL Statements")
	Set msgTask("SQLImportStatement") = $$$Text("Import SQL Statements")
	Set msgTask("TuneTables") = $$$Text("Tune Tables")
	Set msgTask("TuneTable") = $$$Text("Tune Table")
	Set msgTask("PurgeAllCachedQueries") = $$$Text("Purge Cached Queries")
	Set msgTask("JobShowPlan") = $$$Text("Show Plan")
	Set msgTask("JobSaveQuery") = $$$Text("Save Query")
	Set msgTask("JobPossiblePlans") = $$$Text("Job Possible Plans")
	Set msgTask("JobComparePlans") = $$$Text("Job Compare Plans")
	Set msgTask("ShardActivate") = $$$Text("Activate Shards")
	Set msgTask("ShardAssign") = $S($G(tParms("SHARD"))="":$$$Text("Assign Shard"),1:$$$Text("Reassign Shard"))
	Set msgTask("ShardVerify") = $$$Text("Verify Shards")
	Set msgTask("ShardRebalance") = $$$Text("Rebalance Shards")
	Set $$$TempMgtPortalTask($J,"StartTime") = $ZDT($H,3)
	Set $$$TempMgtPortalTask($J,"Task") = $S($D(msgTask(pTask)):msgTask(pTask),1:pTask)
	Set $$$TempMgtPortalTask($J,"NS") = $namespace
	Set $$$TempMgtPortalTask($J,"Status") = $$$Text("Running")
	
	// dispatch to task
	Set tSC = $$$OK
	If (pTask = "CreateDatabase") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("Name"))_" "_$Username
		Set tSC = ..CreateDatabase(.tParms)
		If $$$ISOK(tSC) Do ..WriteDone()
	} 
	ElseIf (pTask = "CompactDBSpace") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("DBName"))_" "_$G(tParms("Directory"))
		Set tSC = ..CompactDBSpace(.tParms)
		If $$$ISOK(tSC) Do ..WriteDone()
	}
	ElseIf (pTask = "DefragmentDB") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("DBName"))_" "_$G(tParms("Directory"))
		Set tSC = ..DefragmentDB(.tParms)
		If $$$ISOK(tSC) Do ..WriteDone()		
	}
	ElseIf (pTask = "ModifyDatabaseSize") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("Name"))_" "_$G(tParms("OldSize")) _"->"_$G(tParms("NewSize"))_" "_$Username
		Set tSC = ..ModifyDatabaseSize(.tParms)
		If $$$ISOK(tSC) Do ..WriteDone()
	}
	ElseIf (pTask = "RebuildIndices") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set Index = "" If $G(tParms("Indices")) '= "" Set Index = $$$Text("Index: ")_$li(tParms("Indices"),1)
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("ClassName"))_" "_Index
		Set tSC = ..RebuildIndices(.tParms)
		If $$$ISOK(tSC) Do ..WriteDone()
	}
	ElseIf (pTask = "SQLExport") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = tParms("Schema")_"."_tParms("Table")_" -> "
		_tParms("FileName")
	    _" "_$$$Text("Delimiter=")_##class(%CSP.UI.SQL.ExImWizardResultPage).DelimiterMeaning(.tParms)
	    _" "_$$$Text("StringQuote=")_tParms("StringQuote")
	    _" "_$$$Text("DateFormat=")_##class(%CSP.UI.SQL.ExImWizardResultPage).DateFormatMeaning(tParms("DateFormat"))
	    _" "_$$$Text("TimeFormat=")_##class(%CSP.UI.SQL.ExImWizardResultPage).TimeFormatMeaning(tParms("TimeFormat"))
	    _" "_$$$Text("NoCheck=")_tParms("NoCheck")
	    _" "_$$$Text("HasHeaders=")_tParms("HasHeaders")
	    _" "_$$$Text("Charset=")_tParms("Charset")

		Set tSC = ..SQLExport(.tParms)
	}
	ElseIf (pTask = "SQLImport") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("FileName"))_" -> "_$G(tParms("Schema"))_"."_$G(tParms("Table"))
	    _" "_$$$Text("Delimiter=")_##class(%CSP.UI.SQL.ExImWizardResultPage).DelimiterMeaning(.tParms)
	    _" "_$$$Text("StringQuote=")_tParms("StringQuote")
	    _" "_$$$Text("DateFormat=")_##class(%CSP.UI.SQL.ExImWizardResultPage).DateFormatMeaning(tParms("DateFormat"))
	    _" "_$$$Text("TimeFormat=")_##class(%CSP.UI.SQL.ExImWizardResultPage).TimeFormatMeaning(tParms("TimeFormat"))
	    _" "_$$$Text("TimeStampFormat=")_##class(%CSP.UI.SQL.ExImWizardResultPage).TimeStampFormatMeaning(tParms("TimeStampFormat"))
	    _" "_$$$Text("NoCheck=")_tParms("NoCheck")
	    _" "_$$$Text("DeferIndices=")_tParms("DeferIndices")
	    _" "_$$$Text("HasHeaders=")_tParms("HasHeaders")
	    _" "_$$$Text("Charset=")_tParms("Charset")

		Set tSC = ..SQLImport(.tParms)
	}
	ElseIf (pTask = "SQLExportStatement") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = tParms("FileName")
		Set tSC = ..SQLExportStatement(.tParms)
	}
	ElseIf (pTask = "SQLImportStatement") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = tParms("FileName")
		Set tSC = ..SQLImportStatement(.tParms)
	}
	ElseIf (pTask = "QueryExport") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = $$$FormatText($$$Text("Export query to file %1"),tParms("FileName"))
		Set tSC = ..QueryExport(.tParms)
	}

	ElseIf (pTask = "Compile") {
		Set Flags = $$$Text("Compile flags: ")_$G(tParms("Flags"),"ck")
		Set tItems = ""
		If $G(tParms("Columns")) '= "" {
			Set Total = $S(tParms("TotalColumns")>10:10,1:tParms("TotalColumns"))
			For tRow = 1:1:Total Set tItem = $li(tParms("Columns"),tRow) If tItem '= "" Set tItems = tItems _ tItem _ $S(tRow<Total:",",1:"")
			If tParms("TotalColumns") > 10 Set tItems = tItems_"..."
		}
		If tParms("CompileAll") = 1 {
			Set $$$TempMgtPortalTask($J,"Details") = Flags _ " "_$$$Text("Compile all classes in namespace.")
		} Else {
			Set $$$TempMgtPortalTask($J,"Details") = Flags _ " "_$$$Text("Total: ")_tParms("TotalColumns")_" "_tItems
		}
		Set tSC = ..Compile(.tParms, .tItems)
	}
	ElseIf (pTask = "Delete") {
		Set RoutineDeleteOption = +$G(tParms("RoutineDeleteOption"))
		Set DeleteType = $G(tParms("DeleteType"))
		Set Flags = ""
		If DeleteType = "R" Set Flags = $$$Text("Delete option: ")_$Case(RoutineDeleteOption,0:$$$Text("entire routine"),1:$$$Text("named routine"),2:$$$Text("source code except OBJ code"),:"")_" "
		Set (tItem,tList) = ""
		If $G(tParms("TotalColumns")) > 0 {
			Set Total = $S(tParms("TotalColumns")>10:10,1:tParms("TotalColumns"))
			For tCnt = 1:1:Total Set tItem = $O(tItems(tItem)) If tItem '= "" Set tList = tList _ $S(DeleteType="G":"^",1:"")_tItem _ $S(tCnt<Total:",",1:"")
			If tParms("TotalColumns") > 10 Set tList = tList_"..."
		}
		Set $$$TempMgtPortalTask($J,"Details") = Flags _ $$$Text("Total: ")_tParms("TotalColumns")_" "_tList
		Set tSC = ..Delete(.tParms,.tItems)
	}
	ElseIf (pTask = "Export") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("FileName"))
		Set tSC = ..Export(.tParms,.tItems)
	}
	ElseIf (pTask = "Import") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("FileName"))_$S($G(tParms("ImportAll"))="LoadDir":" "_$$$TextHTML("Include subdirectories=")_$G(tParms("Recurse")),1:"")_" "_$S($G(tParms("qspec"))'="":$$$TextHTML("Compile flags=")_$G(tParms("qspec")),1:"")
		Set tSC = ..Import(.tParms,.tItems)
	}
	ElseIf (pTask = "LinkTable") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("DataSource"))_" "_$G(tParms("Schema"))
		Set tSC = ..LinkTable(.tParms,.tItems)
	}
	ElseIf (pTask = "LinkProcedure") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("DataSource"))_" "_$G(tParms("Schema"))
		Set tSC = ..LinkProcedure(.tParms,.tItems)
	}
	ElseIf (pTask = "DataMigration") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set tSchema = $G(tParms("Schema"))
		Set tFrom = $O(tItems("Tables",""))
		Set tTo = $O(tItems("Tables"),-1) If tTo=tFrom Set tTo = ""
		Set:tFrom'="" tFrom = tItems("Tables",tFrom)
		Set:tTo'="" tTo = tItems("Tables",tTo)
		Set tTableRange = tSchema_$S(tSchema'="":".",1:"")_tFrom_$S(tTo'="":"..."_$S(tSchema'="":tSchema_".",1:"")_tTo,1:"")
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("DataSource"))_" "_tTableRange
	    _" "_$$$Text("NoCheck=")_tParms("NoCheck")
	    _" "_$$$Text("DeferIndices=")_tParms("DeferIndices")
	    _" "_$$$Text("NoTrigger=")_tParms("NoTrigger")
	    _" "_$$$Text("NoJournal=")_tParms("NoJournal")
	    _" "_$$$Text("DeleteExistingData=")_tParms("DeleteExistingData")
	    _" "_$$$Text("TuneTable=")_tParms("TuneTable")
		Set tSC = ..DataMigration(.tParms,.tItems)
	}
	ElseIf (pTask = "ShardActivate") {
		Set masterNamespace = $G(tParms("masterNamespace"))
		Set $$$TempMgtPortalTask($J,"Details") = $$$FormatText($$$Text("Activate shards for %1 started at %2. "),masterNamespace,$ZDT($H,3))
		Set tSC = ..ActivateShard(.tParms)
	}
	ElseIf (pTask = "ShardAssign") {
		Set reassign = ""
		If $G(tParms("SHARD")) '= "" {
			Set reassign = $$$FormatText($$$Text("Reassign shard %1 "),tParms("SHARD"))
		}
		Set masterNamespace = $G(tParms("masterNamespace"))
		Set shardHost = $G(tParms("shardHost"))
		Set shardPort = $G(tParms("shardPort"))
		Set shardNamespace = $G(tParms("shardNamespace"))
		Set $$$TempMgtPortalTask($J,"Details") = reassign_ masterNamespace_" "_shardHost_":"_shardPort_":"_shardNamespace
		Set tSC = ..AssignShard(.tParms)
	}
	ElseIf (pTask = "ShardVerify") {
		Set masterNamespace = $G(tParms("masterNamespace"))
		Set $$$TempMgtPortalTask($J,"Details") = $$$FormatText($$$Text("Verify shards for %1 started at %2. "),masterNamespace,$ZDT($H,3))
		Set tSC = ..VerifyShard(.tParms)
	}
	ElseIf (pTask = "ShardRebalance") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode (shard rebalance may imply queries that trigger user code)
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set masterNamespace = $G(tParms("Namespace"))
		Set what = $S(+$G(tParms("ISNODELEVEL"))=1:$$$Text("node-level cluster"),1:$$$Text("namespace-level cluster"))
		Set $$$TempMgtPortalTask($J,"Details") = $$$FormatText($$$Text("Rebalance %1 for %2 started at %3. "),masterNamespace,what,$ZDT($H,3))
		Set tSC = ..RebalanceShard(.tParms)
	}
	ElseIf (pTask = "AuditCopy") {
		If $G(tParms("BeginDateTime"))="",$G(tParms("EndDateTime"))="" Set tmsg = $$$Text("Copy all items.")
		Else  Set tmsg =  $S($G(tParms("BeginDateTime"))="":"*",1:tParms("BeginDateTime"))_" - "_$G(tParms("EndDateTime"))
		Set $$$TempMgtPortalTask($J,"Details") = $$$Text("Copy to: ")_$G(tParms("AuditCopyNamespace"))_" "_tmsg
		Set tSC = ..AuditCopy(.tParms)
	}
	ElseIf (pTask = "AuditExport") {
		If $G(tParms("BeginDateTime"))="",$G(tParms("EndDateTime"))="" Set tmsg = $$$Text("Export all items.")
		Else  Set tmsg =  $S($G(tParms("BeginDateTime"))="":"*",1:tParms("BeginDateTime"))_" - "_$G(tParms("EndDateTime"))
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("FileName"))_" "_tmsg
		Set tSC = ..AuditExport(.tParms)
	}
	ElseIf (pTask = "AuditPurge") {
		If $G(tParms("BeginDateTime"))="",$G(tParms("EndDateTime"))="" Set tmsg = $$$Text("Delete all items.")
		Else  Set tmsg =  $S($G(tParms("BeginDateTime"))="":"*",1:tParms("BeginDateTime"))_" - "_$G(tParms("EndDateTime"))
		Set $$$TempMgtPortalTask($J,"Details") = tmsg
		Set tSC = ..AuditPurge(.tParms)
	} 
	ElseIf (pTask = "TuneTable") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = $$$Text("Namespace: ")_$G(tParms("NAMESPACE"))_" "_$$$Text("Schema: ")_$G(tParms("Schema"))_" "_$$$Text("Table: ")_$G(tParms("Table"))_" "_$$$Text("KeepClassUpToDate: ")_$G(tParms("KeepClassUpToDate"))_" "_$$$Text("ClearValues: ")_$G(tParms("ClearValues"))
		Set tSC = ..TuneTables(.tParms)
	}
	ElseIf (pTask = "TuneTables") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = $$$Text("Namespace: ")_$G(tParms("NAMESPACE"))_" "_$$$Text("Schema: ")_$G(tParms("Schema"))_" "_$$$Text("KeepClassUpToDate: ")_$G(tParms("KeepClassUpToDate"))_" "_$$$Text("ClearValues: ")_$G(tParms("ClearValues"))_" "_$$$Text("LogFile: ")_$G(tParms("LogFile"))
		Set tSC = ..TuneTables(.tParms)
	}
	ElseIf (pTask = "EnableEnsNamespace") {
		Set $$$TempMgtPortalTask($J,"Details") = $$$Text("Namespace: ")_$G(tParms("NAMESPACE"))
		Set tSC = ..EnableEnsNamespace(.tParms)
		If $G(tParms("CopyMapsFrom")) '= "" {
			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_"; "_$$$FormatText($$$Text("Copy Mappings from %1 to %2"),$G(tParms("CopyMapsFrom")),$G(tParms("NAMESPACE")))
			Set tSC = ..CopyNamespaceMappings(.tParms)	
		}
	}
	ElseIf (pTask = "CopyNamespaceMappings") {
		Set $$$TempMgtPortalTask($J,"Details") = $$$FormatText($$$Text("Copy Mappings from %1 to %2"),$G(tParms("CopyMapsFrom")),$G(tParms("NAMESPACE")))
		Set tSC = ..CopyNamespaceMappings(.tParms)
	}
	ElseIf (pTask = "DatabaseIntegrityCheck") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("FILENAME"))_" "_$$$Text("Stop After Error")_"="_+$G(tParms("STOPAFTERERROR"))_" "_$$$FormatText($$$Text("Run on %1 database(s)"),$G(tParms("TotalDatabases")))
		Set tSC = ..DatabaseIntegrityCheck(.tParms)
	}
	ElseIf (pTask = "JournalIntegrityCheck") {
		Set $$$TempMgtPortalTask($J,"Details") = $G(tParms("JournalFile"))_" "_$S($G(tParms("CheckDetails"))=1:$$$Text("Check details = 1"),1:$$$Text("Check details = 0"))
		Set tSC = ..JournalIntegrityCheck(.tParms)
	}
	ElseIf (pTask = "PurgeAllCachedQueries") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("Purge All Cached Queries in All Namespaces")_" "_$G(tParms("Reason"))
		Set tSC = ..PurgeAllCachedQueries()
	}
	ElseIf (pTask = "FileMan") {
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("Map FileMan Files to Classes. Log file: ")_" "_$G(tParms("logFile"))
		Set tSC = ..FileMan(.tParms,.tItems)
	}
	ElseIf (pTask = "MirrorActivateCatchupDB") {
		Set pAction = $Case(tParms("Action"),"A":$$$Text("Activate Mirror DB"),"C":$$$Text("Catchup Mirror DB"),:$$$Text("Activate and Catchup DB"))_"."
		Set $$$TempMgtPortalTask($J,"Details") = pAction
		Set tSC = ##class(%CSP.UI.System.Mirror).MirrorActivateCatchupDB(.tParms,.tItems)
	}
	#;SML3207+
	ElseIf (pTask = "MirrorDownloadDB") {
		Set $$$TempMgtPortalTask($J,"Details") = $$$Text("Download Mirrored DB")
		Set tSC = ##class(%CSP.UI.System.Mirror).MirrorDownloadDB(.tParms,.tItems)
	}
	#;SML3207-
	ElseIf (pTask = "MirrorMountDB") {
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("Mount Mirrored Databases: ")
		Set tSC = ##class(%CSP.UI.System.Mirror).MirrorMountDB(.tParms,.tItems)
	}
	ElseIf (pTask = "MirrorRemoveDB") {
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("Remove Databases from Mirror: ")
		Set tSC = ##class(%CSP.UI.System.Mirror).MirrorRemoveDB(.tParms,.tItems)
	}
	ElseIf (pTask = "MirrorAddDatabases") {
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("Add Databases to Mirror: ")
		Set tSC = ##class(%CSP.UI.System.Mirror).MirrorAddDatabases(.tParms,.tItems)
	}
	ElseIf (pTask = "JobShowPlan") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set tUsername = $G(tParms("Username"))
		Set tStats = $G(tParms("stats"))
		Set tQueryText = $E($G(tParms("QueryText")),1,50)_"..."
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("SQL PTools: ")_" "_tUsername_" stats="_tStats_" "_tQueryText
		Set tSC = ..JobShowPlan(.tParms)
	}
	ElseIf (pTask = "JobSaveQuery") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set tUsername = $G(tParms("Username"))
		Set tInclude = $G(tParms("includeresults"))
		Set tQueryText = $E($G(tParms("QueryText")),1,50)_"..."
		Set tWRCNum = $G(tParms("WRCNum"))
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("SQL PTools: ")_" "_tUsername_" WRCNum="_tWRCNum_" includeresults="_tInclude_" "_tQueryText
		Set tSC = ..JobSaveQuery(.tParms)
	}
	ElseIf (pTask = "JobPossiblePlans") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set tUsername = $G(tParms("Username"))
		Set tQueryText = $E($G(tParms("QueryText")),1,50)_"..."
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("SQL PTools: ")_" "_tUsername_" "_tQueryText
		Set tSC = ..JobPossiblePlans(.tParms)	
	}
	ElseIf (pTask = "JobComparePlans") {
		
		// BDB959 - SQL task: make sure we run ServerInitCode
		x:$d($$$SQLServerInitCode) $$$SQLServerInitCode
	
		Set tUsername = $G(tParms("Username"))
		Set tIDList = $G(tParms("idList"))
		Set tQueryText = $E($G(tParms("QueryText")),1,50)_"..."
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("SQL PTools: ")_" "_tUsername_" idList="_tIDList_" "_tQueryText
		Set tSC = ..JobComparePlans(.tParms)	
	}
	ElseIf (pTask = "ExternalLangServers") {
		Set tUsername = $G(tParms("Username"))		
		Set $$$TempMgtPortalTask($J,"Details") = $$$TextHTML("External Language Servers: ")_" "_tUsername_" "_$$$FormatText($$$Text("Check status started at %1 "),$ZDT($H,3))
		Set tSC = ..ExternalLangServers(.tParms)	
	}
	Else {
		Set tSC = ..Task1()
	}
	// clean up
	If $$$ISOK(tSC) {
		// YSD1330 If pTask="RebuildIndices" Kill ^IRIS.Temp.MgtPortalTask($J)
	} Else {
		Do $System.Status.DecomposeStatus(tSC,.msg)
		Do ..WriteError(msg(1))
	}
Done
	s Data=$System.Status.GetErrorText(tSC)
 	d $SYSTEM.Security.Audit($$$SourceSystem,$$$TypeLogin,$$$NameTaskEnd,Data,pTask_" "_$$$FormatMsg($$$AuditMsg,"EXIT"))
	Quit
Trap
	Set $ZT=""
	If $G(pIdx) Kill ^|"%SYS"|IRIS.Temp(pIdx)  // clear temp global
	// log error
	Set $$$TempMgtPortalTask($J,"Status") = $$$Text("ERROR")
	Set $$$TempMgtPortalTask($J,"Details") = $ZE
	Goto Done
}

ClassMethod ActivateShard(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set masterNamespace = $G(pParms("masterNamespace"))
		Set tSC = $System.Sharding.ActivateNewShards(masterNamespace)
		If $$$ISOK(tSC) {
			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Activate completed at %1"),$ZDT($H,3))	
			Do ..WriteDone()
		} Else {
			Do ..WriteError($System.Status.GetErrorText(tSC))
		}
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Assign new shard in the background
ClassMethod AssignShard(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set SHARD = $G(pParms("SHARD"))
		Set masterNamespace = $G(pParms("masterNamespace"))
		Set shardHost = $G(pParms("shardHost"))
		Set shardPort = $G(pParms("shardPort"))
		Set shardNamespace = $G(pParms("shardNamespace"))
		Set dataShardNumber = $G(pParms("dataShardNumber"))
		Set mirrorName = $G(pParms("mirrorName"))
		Set mirrorHost = $G(pParms("mirrorHost"))
		Set mirrorPort = +$G(pParms("mirrorPort"))
		Set mirrorVIP = $G(pParms("mirrorVIP"))
		If SHARD = "" {
			Set tSC = ##class(%SYSTEM.Sharding).AssignShard(
						masterNamespace,
						shardHost,
						shardPort,
						shardNamespace,
						dataShardNumber,
						mirrorName,
						mirrorHost,
						mirrorPort,
						mirrorVIP
				)
				If $$$ISOK(tSC) {
					Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Assign shard completed at %1. Start verify..."),$ZDT($H,3))
					Set tSC = $System.Sharding.VerifyShards(masterNamespace)
					If $$$ISOK(tSC) {
						Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Verify completed at %1"),$ZDT($H,3))	
					}
				}
		} Else {
				Set tSC = ##class(%SYSTEM.Sharding).ReassignShard(
						masterNamespace,
						shardHost,
						shardPort,
						shardNamespace,
						SHARD,
						mirrorName,
						mirrorHost,
						mirrorPort,
						mirrorVIP
					)
				If $$$ISOK(tSC) {
					Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Reassign shard completed at %1"),$ZDT($H,3))
				}	
		}
		If $$$ISERR(tSC) {
			Do ..WriteError($System.Status.GetErrorText(tSC))
		} Else {
			Do ..WriteDone()	
		}
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Verify shards in the background
ClassMethod VerifyShard(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set masterNamespace = $G(pParms("masterNamespace"))
		Set tSC = $System.Sharding.VerifyShards(masterNamespace)
		If $$$ISOK(tSC) {
			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Verify completed at %1"),$ZDT($H,3))	
			Do ..WriteDone()
		} Else {
			Do ..WriteError($System.Status.GetErrorText(tSC))
		}
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Rebalance shards in the background
ClassMethod RebalanceShard(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set Namespace = $G(pParms("Namespace"))
		Set pReport = ""
		Set tSC = $System.Sharding.Rebalance(Namespace,+$G(pParms("TimeLimit")),.pReport,1)
		// pReport("Elapsed Seconds") is set to the elapsed time for this call, in seconds.
 		// pReport("Buckets Moved") is set to the number of buckets moved by this call.
 		// pReport("Buckets To Move") is set to the total number of buckets remaining to be moved.
		If $$$ISOK(tSC) {
			Set tResults = $$$FormatText($$$Text("Elapsed %1 seconds; "),+$G(pReport("Elapsed Seconds")))
			Set tResults = tResults_$$$FormatText($$$Text("%1 buckets moved; "),+$G(pReport("Buckets Moved")))
			Set tResults = tResults_$$$FormatText($$$Text("%1 buckets remain to be moved. "),+$G(pReport("Buckets To Move")))
			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_tResults
			Do ..WriteDone()
		} Else {
			Do ..WriteError($System.Status.GetErrorText(tSC))
		}
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Create a database
ClassMethod CreateDatabase(ByRef pParms) As %Status
{
	Set tSC = ##class(Config.Configuration).CreateDatabase(
									$G(pParms("Name")),
									$G(pParms("Directory")),
									$G(pParms("Size")),
									$G(pParms("BlockSize")),
									,,,
									$G(pParms("Encrypted")),
									$G(pParms("Resource")),
									$G(pParms("GlobalJournalState")))
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

ClassMethod DefragmentDB(ByRef pParms) As %Status
{
	Set SysBGTask = ##class(SYS.Database.BackgroundDefragment).Register(
							$G(pParms("Directory")))
	Quit:'$isobject(SysBGTask) %objlasterror
	Set $$$TempMgtPortalTask($J,"SysBGTaskId") = SysBGTask.%Id()
	Set tSC = SysBGTask.Run($G(pParms("Directory")))
	If $$$ISOK(tSC) {
		Do ..WriteDone()
	}
	Quit tSC
}

/// Return unused db space
ClassMethod CompactDBSpace(ByRef pParms) As %Status
{
	Set SysBGTask = ##class(SYS.Database.BackgroundFileCompact).Register(
							$G(pParms("Directory")),
							$G(pParms("Target")))
	Quit:'$isobject(SysBGTask) %objlasterror
	Set $$$TempMgtPortalTask($J,"SysBGTaskId") = SysBGTask.%Id()
	Set tSC = SysBGTask.Run($G(pParms("Directory")),
							$G(pParms("Target")))
	If $$$ISOK(tSC) {
		Do ..WriteDone()
	}
	Quit tSC
}

/// Modify database size
ClassMethod ModifyDatabaseSize(ByRef pParms) As %Status
{
	Set tSC = $$SilentModWait^DATABASE($G(pParms("ConfigModified")),
									$G(pParms("NewName")),
									$G(pParms("DBName")),
									$G(pParms("Directory")),
									$G(pParms("Server")),
									$G(pParms("MountAtStartup")),
									$G(pParms("ClusterMountMode")),
									$G(pParms("MountRequired")))
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Start SQL Export
ClassMethod SQLExport(ByRef pParms) As %Status
{
	Do ##class(%CSP.UI.SQL.ExImWizardResultPage).Export(pParms("Wizard"),
						pParms("Schema"),
						pParms("Table"),
						.pParms)
	Quit $$$OK
}

/// Start SQL Import
ClassMethod SQLImport(ByRef pParms) As %Status
{
	Do ##class(%CSP.UI.SQL.ExImWizardResultPage).Export(pParms("Wizard"),
						pParms("Schema"),
						pParms("Table"),
						.pParms)
	If pParms("IsLocal") {
		Do ##class(%CSP.UI.System.Utils).DeleteLocalUpload(pParms("FileName"))
	}
	Quit $$$OK
}

ClassMethod SQLExportStatement(ByRef pParms) As %Status
{
	If $G(pParms("ExportAll")) = 1 {
		Set tSC = $System.SQL.ExportAllSQLStatements(pParms("FileName"))
	} Else {
		Set tSC = $System.SQL.ExportSQLStatement(pParms("FileName"), pParms("Hash"))
	}
	If $$$ISOK(tSC) {
		Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
		Do ..WriteDone()
	}
	Quit tSC
}

ClassMethod SQLImportStatement(ByRef pParms) As %Status
{
	Set tSC = $System.SQL.ImportSQLStatement(pParms("FileName"),0)
	If $$$ISOK(tSC) {
		Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
		Do ..WriteDone()
	}
	if pParms("ImportLocal") {
		Do ##class(%CSP.UI.System.Utils).DeleteLocalUpload(pParms("FileName"))
	}
	Quit tSC
}

/// Start SQL Export Dynamic Query
ClassMethod QueryExport(ByRef pParms) As %Status
{
	Do ##class(%CSP.UI.SQL.ExImWizardResultPage).QueryExport(.pParms)
	Quit $$$OK
}

/// Start Compile routines/classes
ClassMethod Compile(ByRef pParms, ByRef tItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Utils).Compile(.pParms, .tItems)
	Quit tSC
}

/// Start Delete routines/classes
ClassMethod Delete(ByRef pParms, ByRef tItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.DeletePane).Delete(.pParms, .tItems)
	Quit tSC
}

/// Enable productions for a namespace
ClassMethod EnableEnsNamespace(ByRef pParms) As %Status
{
	Set tSC = ##class(%Library.EnsembleMgr).EnableNamespace(pParms("NAMESPACE"),0)
	If $G(pParms("CopyMapsFrom")) '= "" Set tSC = ..CopyNamespaceMappings(.pParms)
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Copy Mappings from one Namespace to another
ClassMethod CopyNamespaceMappings(ByRef pParms) As %Status
{
	Set tSC = ##class(Config.Namespaces).CopyMaps(pParms("CopyMapsFrom"),pParms("NAMESPACE"))
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Start database file integrity check. After finish, transform results to file.
ClassMethod DatabaseIntegrityCheck(ByRef pParms) As %Status
{
	Set tSC = $$CheckList^Integrity(pParms("OUTPUTGLO"),pParms("DirList"),pParms("STOPAFTERERROR"),pParms("ListOfGloList"))
	#;RJF211+
	If ($system.Status.GetErrorCodes(tSC)=$$$ERRORCODE($$$IntegrityCheckErrors)) {
		#; The only errors were integrity check errors, so recheck them
		Set errors=$$RetryErrors^Integrity(pParms("OUTPUTGLO"),1)
		If (errors="0,0") { Set tSC=$$$OK }
	} Else {
		#; Either status is OK so there should be no errors or
		#; something went wrong with integrity check and we may only
		#; have partial results recorded.  We could call RetryErrors
		#; anyway, but this ensures that the status code we report
		#; doesn't disagree with the outputted contents.
		Set errors=$$Errors^Integrity(pParms("OUTPUTGLO"),1)
	}
	#;RJF211-
	
	If $$$ISERR(tSC)  {
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	
	Set FILENAME = pParms("FILENAME")
	Open FILENAME:"WNS":3
	If '$T {
		Do ..WriteError($System.Status.GetErrorText(tSC))
		Quit tSC
	}
	Use FILENAME
	Write $$$TextHTML("File Name: "),$ZCVT(FILENAME,"O","HTML"),!!
	Write $$$TextHTML("InterSystems IRIS Database Integrity Check - Report Created ")_$zdt($h),!
	Write $$$TextHTML("System"),": ",$zu(110)," ",$$$TextHTML("Configuration"),": ",$P($zu(86),"*",2),!
	Write $ZV,!!

	If errors="0,0" {
		Write $$$TextHTML("No Errors were found."),!
	} else {
		Write $$$TextHTML("************** Details Of Errors Found **************"),!
		Do Display^Integrity(pParms("OUTPUTGLO"),1,0)
		s sev=##class(%Monitor.Manager).AlertLevel()
		d ##class(%SYS.System).WriteToConsoleLog(" See output in "_FILENAME,1,sev)
	}
	
	Write !!,$$$TextHTML("Full Listing of Databases Checked"),!!
	
	Do Display^Integrity(pParms("OUTPUTGLO"),0,1)
	Kill ^IRIS.TempIntegrity(+$j),^IRIS.TempIntegrityOutput(+$j)
	Close FILENAME

	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Start journal file integrity check
ClassMethod JournalIntegrityCheck(ByRef pParms) As %Status
{
	Set tSC = ##class(%SYS.Journal.File).CheckIntegrity(pParms("JournalFile"),pParms("CheckDetails"))
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Start Export globals/routines/classes
ClassMethod Export(ByRef pParms, ByRef tItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Utils).Export(pParms("FileName"),
						pParms("ExportFormat"),
						.pParms, .tItems)
	Quit tSC
}

/// Start Import globals/routines/classes
ClassMethod Import(ByRef pParms, ByRef tItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Utils).Import(pParms("FileName"),
						.pParms, .tItems)
	If $G(pParms("ImportLocal")) {
		Do ##class(%CSP.UI.System.Utils).DeleteLocalUpload(pParms("FileName"))
	}

	Quit tSC
}

/// Start SQL Link Table
ClassMethod LinkTable(ByRef pParms, ByRef tItems) As %Status
{
	Do ##class(%CSP.UI.SQL.LinkWizardResultPage).CreateLinkTable(
						pParms("DataSource"),
						pParms("Schema"),
						.pParms, .tItems)
	Quit $$$OK
}

/// Start SQL Link Procedure
ClassMethod LinkProcedure(ByRef pParms, ByRef tItems) As %Status
{
	Do ##class(%CSP.UI.SQL.LinkWizardResultPage).CreateLinkProcedure(
						pParms("DataSource"),
						pParms("Schema"),
						.pParms, .tItems)
	Quit $$$OK
}

/// Sart SQL Data Migration
ClassMethod DataMigration(ByRef pParms, ByRef tItems) As %Status
{
	Do ##class(%CSP.UI.SQL.LinkWizardResultPage).CreateDataMigration(
						pParms("DataSource"),
						pParms("Schema"),
						.pParms, .tItems)
	Quit $$$OK
}

/// Rebuild indices for a class
ClassMethod RebuildIndices(ByRef pParms) As %Status
{
	Set EventDesc = "Rebuild Indices"
	Set EventData = "ClassName: "_$G(pParms("ClassName"))
	If $G(pParms("Indices"))'="" Set EventData = EventData_$$$CRLF_" Indices: "_pParms("Indices")
	$$$SMPAuditChange
	Set tSC = ##class(%SQL.Manager.API).RebuildIndices($G(pParms("ClassName")),$G(pParms("Indices")))
	Quit tSC
}

/// Start Copy audit log to another namespace
ClassMethod AuditCopy(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##Class(%SYS.Audit).Copy(.NumCopied,$G(pParms("AuditCopyNamespace")),$G(pParms("AuditFlag")),$G(pParms("BeginDateTime")),$G(pParms("EndDateTime")))
 		If $$$ISERR(tSC) {
	 		Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($System.Status.GetErrorText(tSC))
	 		Set $$$TempMgtPortalTask($J,"Status") = $$$Text("ERROR")
 		} Else {
			Set tmsg = $$$FormatText($$$Text("%1 items copied."),NumCopied)
			If $G(pParms("AuditFlag")) = 1 Set tmsg = tmsg_" "_$$$FormatText($$$TextHTML("%1 audit items deleted from original namespace."),NumCopied)
 			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_tmsg
 			Do ..WriteDone()
 		}		
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Start Export audit log
ClassMethod AuditExport(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##Class(%SYS.Audit).Export($G(pParms("FileName")),.NumCopied,$G(pParms("AuditFlag")),$G(pParms("BeginDateTime")),$G(pParms("EndDateTime")))
 		If $$$ISERR(tSC) {
	 		Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($System.Status.GetErrorText(tSC))
	 		Set $$$TempMgtPortalTask($J,"Status") = $$$Text("ERROR")
 		} Else {
			Set tmsg = $$$FormatText($$$Text("%1 items exported."),NumCopied)
			If $G(pParms("AuditFlag")) = 1 Set tmsg = tmsg_" "_$$$FormatText($$$TextHTML("%1 audit items deleted."),NumCopied)
 			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_tmsg
 			Do ..WriteDone()
 		}		
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Start Purge audit log
ClassMethod AuditPurge(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##Class(%SYS.Audit).Delete(.NumDeleted,$G(pParms("BeginDateTime")),$G(pParms("EndDateTime")))
 		If $$$ISERR(tSC) {
	 		Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($System.Status.GetErrorText(tSC))
	 		Set $$$TempMgtPortalTask($J,"Status") = $$$Text("ERROR")
 		} Else {
			Set tmsg = $$$FormatText($$$Text("%1 items deleted."),NumDeleted)
 			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_tmsg
 			Do ..WriteDone()
 		}		
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Tune all tables in a schema
ClassMethod TuneTables(ByRef pParms) As %Status
{
	Set tSC = ##class(%CSP.UI.SQL.SQLPane).TuneTables(.pParms)
	Quit tSC
}

/// Purge all cached queries from all namespaces
ClassMethod PurgeAllCachedQueries() As %Status
{
	Do PurgeAllNamespaces^%SYS.SQLSRV() 
	Do ..WriteDone()
	Quit $$$OK
}

/// Map FileMan files to InterSystems classes
ClassMethod FileMan(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = ##class(%CSP.UI.Portal.FileMan).CreateClasses(.pParms,.pItems)
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Activate and/or catchup Mirror DBs
ClassMethod MirrorActivateCatchupDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Mirror).MirrorActivateCatchupDB(.pParms,.pItems)
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Download Mirror DBs
ClassMethod MirrorDownloadDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Mirror).MirrorDownloadDB(.pParms,.pItems)
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Mount Mirror DBs
ClassMethod MirrorMountDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Mirror).MirrorMountDB(.pParms,.pItems)
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Remove DBs from mirror
ClassMethod MirrorRemoveDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Mirror).MirrorRemoveDB(.pParms,.pItems)
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Add databases to mirror
ClassMethod MirrorAddDatabases(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = ##class(%CSP.UI.System.Mirror).MirrorAddDatabases(.pParms,.pItems)
	If $$$ISOK(tSC) Do ..WriteDone()
	Quit tSC
}

/// Run Show Plan process in the background
ClassMethod JobShowPlan(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tUsername = pParms("Username")
		Set tNamespace = pParms("Namespace")
		If tNamespace '= "" {
			Set $Namespace = tNamespace
		}
		Set tQuery = pParms("QueryText")
		Set tCnt = 1
		Set tLine = $P(tQuery,$c(10),tCnt)
		While tLine '= "" {
			Set pText(tCnt) = tLine
			Set pText = tCnt
			Set tCnt = tCnt + 1
			Set tLine = $P(tQuery,$c(10),tCnt)	
		}
		// stats=1 8th piece
		Set stats = 1
		Set isbackground = 1
		Set tPlan = ##class(%SQL.Manager.ShowPlan).ShowPlan(.pText,,1,,,1,,stats,,,,,1,isbackground)
		Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
		Do ..WriteDone()

	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Run Possible Plans process in the background
ClassMethod JobPossiblePlans(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tUsername = pParms("Username")
		Set tNamespace = pParms("Namespace")
		If tNamespace '= "" {
			Set $Namespace = tNamespace
		}
		Set tQuery(1) = pParms("QueryText")
		Set tQuery = 1
		Set tArray = 1
		Set tSilent = 1
		Do ShowPlanAlt^%apiSQL(.tQuery,tArray,,,,,,,tSilent)
 		If $D(%AltPlan) {
	 		Kill $$$TempMgtPortalTask($J,"%AltPlan")
	 		Merge $$$TempMgtPortalTask($J,"%AltPlan") = %AltPlan	
 		}
		Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
		Do ..WriteDone()
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Run Compare Show Plans process in the background
ClassMethod JobComparePlans(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tUsername = pParms("Username")
		Set tNamespace = pParms("Namespace")
		If tNamespace '= "" {
			Set $Namespace = tNamespace
		}
		Set tQuery(1) = pParms("QueryText")
		Set tQuery = 1
		Set tArray = 1
		Set tSilent = 1
		Set ids = $G(pParms("idList"))
		Set idlist = ""
		For pos = 1:1:$L(ids,",") {
			If $p(ids,",",pos) '= "" {
				Set idlist = idlist_","_$P(ids,",",pos)
			}
		}
		Set idlist = $E(idlist,2,*)
	
		Do ShowPlanAlt^%apiSQL(.tQuery,1,,1,,,0,idlist,1)

 		If $D(%AltPlan) {
	 		Kill $$$TempMgtPortalTask($J,"%AltPlanCompare")
	 		Merge $$$TempMgtPortalTask($J,"%AltPlanCompare") = %AltPlan	
 		}
		Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
		Do ..WriteDone()
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Run Save Query (for pTools) process in the background
ClassMethod JobSaveQuery(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tUsername = pParms("Username")
		Set tNamespace = pParms("Namespace")
		If tNamespace '= "" {
			Set $Namespace = tNamespace
		}
		Set tQuery = pParms("QueryText")
		Set WRCNum = pParms("WRCNum")
		Set includeresults = pParms("includeresults")
		Set sc = ##class(%SQL.Manager.QButtons.Base).InsertQuery(tQuery,WRCNum,includeresults)
		If $$$ISERR(sc) {
			Do ..WriteError($System.Status.GetErrorText(sc))
		} Else {
			Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
			Do ..WriteDone()
		}
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Check status of external language servers 
ClassMethod ExternalLangServers(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFilter = pParms("Filter")
		Set tUser = pParms("Username")
		Set tRS = ##class(%ResultSet).%New("Config.Gateways:ListShort")
		Set tSC = tRS.Execute(tFilter,"","",0)
		If $$$ISERR(tSC) Quit
		Set $$$TempMgtPortalTask("ExternalLangServers",tUser) = $J
		While tRS.Next() {
			Set tName = tRS.Data("Name")
			If tName '= "" {
				Set $$$TempMgtPortalTask("ExternalLangServers",$J,tName,"Checking") = 1
				Set tStatus = ##class(%Net.Remote.Service).IsGatewayRunning("",tName)
				// for testing only:
				//if tName = "%JDBC Server" Set tStatus = 1
				Set $$$TempMgtPortalTask("ExternalLangServers",$J,tName) = tStatus
				
				Kill $$$TempMgtPortalTask("ExternalLangServers",$J,tName,"Checking")
			}
		}
		Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_$$$FormatText($$$Text("- completed at %1"),$ZDT($H,3))
		Do ..WriteDone()
	} Catch Error {
		Set tSC = Error.AsStatus()
		Do ..WriteError($System.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Test task
ClassMethod Task1(ByRef pParms) As %Status
{
	Hang 10
	Quit $$$OK
}

/// Return a list of currently excuting (or failed) background Management Portal tasks.
Query EnumerateTasks() As %Query(ROWSPEC = "ID:%Integer,StartTime:%TimeStamp,Namespace:%String,Task:%String,Status:%String,Details:%String,ErrorCount:%String,SysBGTaskId")
{
}

ClassMethod EnumerateTasksExecute(ByRef qHandle As %Binary) As %Status
{
	Set qHandle = ""
	Set qHandle(1) = $I(^|"%SYS"|IRIS.Temp)
	Set tId = $O($$$TempMgtPortalTask(""))
	While tId '= "" {
		Set tTime = $G($$$TempMgtPortalTask(tId,"StartTime"))
		If tTime '= "" Set ^|"%SYS"|IRIS.Temp(qHandle(1),tTime,tId) = ""
		Set tId = $O($$$TempMgtPortalTask(tId))
	}
	Quit $$$OK
}

ClassMethod EnumerateTasksFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateTasksExecute ]
{
	Set qHandle = $O(^|"%SYS"|IRIS.Temp(qHandle(1),qHandle),-1)
	If (qHandle = "") {
		Set Row=""
		Set AtEnd = 1
	}
	Else {
		Set tId = $O(^|"%SYS"|IRIS.Temp(qHandle(1),qHandle,""))
		If tId '= "" {
			Set tStatus = $G($$$TempMgtPortalTask(tId,"Status"))
			Set SysBGTaskId = $Get($$$TempMgtPortalTask(tId,"SysBGTaskId"))
			If SysBGTaskId '= "" {
				Set tObj = ##class(%SYS.BackgroundTask).%OpenId(SysBGTaskId)
				If $IsObject(tObj) {
					Set tStatus = $Case(tObj.RunningState,
					"Cancelled":$$$TextHTML("Cancelled"),
					"Done":$$$TextHTML("Done"),
					"Error":$$$TextHTML("Error"),
					"Exited":$$$TextHTML("Exited"),
					"Paused":$$$TextHTML("Paused"),
					"Running":$$$TextHTML("Running"),
					"Starting":$$$TextHTML("Starting"),
					:tObj.RunningState)
					Kill tObj
				} Else {
					Set SysBGTaskId = ""	
				}
			} ElseIf tStatus = $$$Text("Running"), '##class(%SYS.ProcessQuery).%ExistsId(tId) {
                #; Background job is gone, so report status accordingly
                Set tStatus = $$$Text("Exited")
                #; Try to update the status global
                Try {Set $$$TempMgtPortalTask(tId,"Status") = tStatus} Catch {}
            }
			Set Row = $LB(tId,
					$G($$$TempMgtPortalTask(tId,"StartTime")),
					$G($$$TempMgtPortalTask(tId,"NS")),
					$G($$$TempMgtPortalTask(tId,"Task")),
					tStatus,
					$G($$$TempMgtPortalTask(tId,"Details")),
					$G($$$TempMgtPortalTask(tId,"ErrorLog")),
					SysBGTaskId)
		}
	}
	
	Quit $$$OK
}

ClassMethod EnumerateTasksClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateTasksExecute ]
{
	Kill ^|"%SYS"|IRIS.Temp(qHandle(1))
	Quit $$$OK
}

Query ErrorLog(%pid As %Library.Integer) As %Query(ROWSPEC = "Type:%String,ErrorNo:%Integer,ErrorText:%String,Row:%Integer")
{
}

ClassMethod ErrorLogExecute(ByRef QHandle As %Binary, %pid As %Library.String) As %Status
{
	; QHandle is errno
	Set QHandle = 0
	Set QHandle(1)=%pid
	
	Quit $$$OK
}

ClassMethod ErrorLogClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

ClassMethod ErrorLogFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set Row="",AtEnd=0
	
	; get next error
	Set QHandle = $Order($$$TempMgtPortalTask(QHandle(1),"ErrorLog",QHandle))
	
	If QHandle = "" Set AtEnd = 1 QUIT $$$OK
	
	Set Row = $$$TempMgtPortalTask(QHandle(1),"ErrorLog",QHandle)
	
	; test for end
	If $Order($$$TempMgtPortalTask(QHandle(1),"ErrorLog",QHandle)) = "" Set AtEnd=1
	
	Quit $$$OK
}

/// This method writes generic Status of "ERROR" and error message to Details.
ClassMethod WriteError(ErrorMessage)
{
	Set $$$TempMgtPortalTask($J,"Status") = $$$Text("ERROR")
	Set $$$TempMgtPortalTask($J,"Details") = $$$TempMgtPortalTask($J,"Details")_" "_ErrorMessage
}

/// This method writes generic Status of "Done".
ClassMethod WriteDone()
{
	Set $$$TempMgtPortalTask($J,"Status") = $$$Text("Done")
	Set $$$TempMgtPortalTask($J,"FinishStatus") = 1
}

}
