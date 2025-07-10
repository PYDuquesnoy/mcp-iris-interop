/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Manager [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Deprecated - for debugging on a test system see Ens.Purge::KillGlobals() and its comments
ClassMethod KillAllGlobals()
{
	If $data(^Ens.Runtime) Write "Production "_$g(^Ens.Runtime("Name"))_" is running.",! Quit
	;
	; production runtime data
	Kill $$$EnsRuntime
	$$$KillAllEnsRuntimeAppData
	Kill $$$EnsQueue
	Kill $$$EnsJobStatusStarted
	$$$KillAllEnsJobStatus
	Kill $$$EnsJobRequest
	;
	; monitor data
	$$$KillAllHostMonitor
	$$$KillAllJobMonitor
	$$$KillAllHostCounter
	;
	; suspended data
	Kill $$$EnsSuspended
	;
	; production definition data
	Kill ^Ens.Conf.ProductionC
	Kill ^Ens.Conf.ProductionD
	;
	; messages
	Kill ^Ens.MessageHeaderI
	Kill ^Ens.MessageHeaderD
	Kill ^Ens.MessageBodyD
	;
	; business process
	Kill ^Ens.BusinessProcessI
	Kill ^Ens.BusinessProcessD
	Kill ^Ens.BP.ContextD
	Kill ^Ens.BP.ThreadD
	;
	; logs
	Kill ^Ens.Util.LogI
	Kill ^Ens.Util.LogD
	;
	; I/O log
	Kill ^Ens.Util.IOLogD
	Kill ^Ens.Util.IOLogI
	;
	; csp Ens.Home cached data
	Kill ^Ens.Configuration
	;
	; other misc data
	Kill ^Ens.Debug
	Kill ^Ens.Metrics
	$$$KillAllEnsMetrics
	;
	Quit
}

ClassMethod CheckIntegrity()
{
	If $data(^Ens.Runtime) Write "Production "_$g(^Ens.Runtime("Name"))_" is running.",! Quit
	;
	Set tSC=##class(Ens.MessageHeader).%BuildIndices() If $$$ISERR(tSC) Do $system.OBJ.DisplayError(tSC)
	Set tSC=##class(Ens.BusinessProcess).%BuildIndices() If $$$ISERR(tSC) Do $system.OBJ.DisplayError(tSC)
	Set tSC=##class(Ens.Util.Log).%BuildIndices() If $$$ISERR(tSC) Do $system.OBJ.DisplayError(tSC)
	;
	;
	Quit
}

}
