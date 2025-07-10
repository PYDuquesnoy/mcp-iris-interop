/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Enterprise.MsgBank.Purge [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod PurgeAll(Output pDeletedCount, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0) As %Status
{
	Set tSCAll=$$$OK

	Set tDeletedCount=0
	Set tSC = ##class(Ens.Purge).PurgeAll(.tDeletedCount,pDaysToKeep,pKeepIntegrity,pBodiesToo)
	If $$$ISERR(tSC) { Set tSCAll=$$$ADDSC(tSCAll,tSC) }
	Merge pDeletedCount = tDeletedCount

	Set tDeletedCount=0
	Set tSC = ##class(Ens.Enterprise.MsgBank.Log).Purge(.tDeletedCount,pDaysToKeep)
	If $$$ISERR(tSC) { Set tSCAll=$$$ADDSC(tSCAll,tSC) }
	Set pDeletedCount("Message Bank Events")=tDeletedCount

	Set tDeletedCount=0, tDeletedCount("bodies")=0
	Set tSC = ##Class(Ens.Enterprise.MsgBank.MessageHeader).Purge(.tDeletedCount,pDaysToKeep,pKeepIntegrity,pBodiesToo)
	If $$$ISERR(tSC) { Set tSCAll=$$$ADDSC(tSCAll,tSC) }
	Set pDeletedCount("Message Bank Messages")=tDeletedCount
	Set pDeletedCount("Stream Container Bodies")=tDeletedCount("bodies")

	Quit tSCAll
}

ClassMethod PurgeEventLogsByDate(pDaysToKeep As %Integer = 7, Output pDeletedCount As %Integer, pKeepIntegrity As %Boolean = 1) As %Status
{
	Quit ##class(Ens.Enterprise.MsgBank.Log).Purge(.pDeletedCount,pDaysToKeep)
}

ClassMethod PurgeMessagesByDate(pDaysToKeep As %Integer = 7, Output pDeletedCount As %Integer, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0) As %Status
{
	Quit ##Class(Ens.Enterprise.MsgBank.MessageHeader).Purge(.pDeletedCount,pDaysToKeep,pKeepIntegrity,pBodiesToo)
}

ClassMethod GetAllCounts(Output pCount)
{
	Set pCount("Event Log") = ##class(Ens.Purge).EventLogCount()
	Set pCount("Messages") = ##class(Ens.Purge).MessageCount()
	Set pCount("Business Processes") = ##class(Ens.Purge).BusinessProcessCount()
	Set pCount("Business Rule Log")="N/A" //##class(Ens.Purge).RuleLogCount() takes too long to compute
	Set pCount("I/O Log") = ##class(Ens.Purge).IOLogCount()
	Set pCount("Message Bank Events") = ..EventLogCount()
	Set pCount("Message Bank Messages") = ..MessageCount()
	Quit
}

ClassMethod EventLogCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens_Enterprise_MsgBank.Log)
	Quit tCount
}

ClassMethod MessageCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From Ens_Enterprise_MsgBank.MessageHeader)
	Quit tCount
}

/// Just like in Ens.Purge
ClassMethod GetAllDataGlobals(globals, pBodiesToo = 0) [ Internal ]
{
	Do ##class(Ens.Purge).GetAllDataGlobals(.globals, pBodiesToo)
	
	Set globals("^Ens.Enterprise.MsgBank.LogD")=""
	Set globals("^Ens.Enterprise.MsgBank.LogD","name")="Message Bank Event Log"
	Set globals("^Ens.Enterprise.MsgBank.LogS")=""
	Set globals("^Ens.Enterprise.MsgBank.LogI")=""

	Set globals("^Ens.Enterprise.MsgBank.MessageHeaderD")=""
	Set globals("^Ens.Enterprise.MsgBank.MessageHeaderD","name")="Message Bank Messages"
	Set globals("^Ens.Enterprise.MsgBank.MessageHeaderI")=""
	If pBodiesToo { 
		Set globals("^Ens.StreamContainerD")=""
		Set globals("^Ens.StreamContainerD","name")="Stream Container Bodies"
		Set globals("^Ens.StreamContainerS")=""
		Set globals("^Ens.StreamContainerI")=""
	}

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
	Do ..ShowOneGlobal("^Ens.Enterprise.MsgBank.Log")
	Do ..ShowOneGlobal("^Ens.Enterprise.MsgBank.MessageHeader")
	Do ..ShowOneGlobal("^Ens.StreamContainer")
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
