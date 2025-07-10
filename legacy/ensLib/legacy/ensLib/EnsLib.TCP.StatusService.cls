/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Service class that supports a simple telnet interface for querying aspects of the status of the running Production
/// Suitable for use in periodically checking from outside InterSystems IRIS (e.g. from a shell script) that the Production is running and in good condition
Class EnsLib.TCP.StatusService Extends Ens.BusinessService [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.TCP.TextLineInboundAdapter";

Parameter LOGCONNECTIONS As %Boolean = 0;

Method OnProcessInput(pMsgIn As Ens.StringContainer, Output pMsgOut As Ens.StringContainer) As %Status
{
	Set pMsgOut=$$$NULLOREF
	Set tMsgInCommand=$zcvt($p(pMsgIn.StringValue," ",1),"L")
	Set tMsgInArgument=$p(pMsgIn.StringValue," ",2,$length(pMsgIn.StringValue," "))
	Set tOutStr=$Case(tMsgInCommand,
			"localstarttime":$$$timeUTCtoLocal($G($$$EnsRuntime("StartTime"),"StartTime <UNDEFINED>")),
			"utcstarttime":$G($$$EnsRuntime("StartTime"),"StartTime <UNDEFINED>"),
			"localtime":$$$timeLocal,
			"utctime":$$$timeUTC,
			"version":##class(Ens.Version).GetVersion(),
			"build":$ZV,
			"namespace":$ZNSpace,
			"production":$G($$$EnsRuntime("Name")),
			"configitemstatus":..isConfigRunning(tMsgInArgument),
			"quit":"","q":"",
			"exit":"","x":"",
			:"request '"_$E($TR(pMsgIn.StringValue,$C(8),$C(177)),1,32767-50)_"' not supported")
	If ""'=tOutStr {
		Set pMsgOut=##class(Ens.StringContainer).%New(tOutStr)
	} Else {
		$$$sysTRACE("Disconnecting because of client request '"_$E(pMsgIn.StringValue,1,32767-50)_"'")
		Do ..Adapter.Disconnect()
	}
	Quit $$$OK
}

ClassMethod isConfigRunning(pConfigName = "") As %String
{
	Quit:""=pConfigName 0
	Do ##class(Ens.Job).MarkDeadJobs()

	#; See if any running job is for the given ConfigName
	Set isrunning=0, tStatus="", tJob=""
	For { set tJob=$O($$$EnsJobStatus($$$SystemName,tJob)) quit:tJob=""
		Continue:pConfigName'=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName))
		Set tStatus=$$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus)
		Set isrunning='$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobIsDead))
		Quit:isrunning
	}
	Set tStatus = " | "_$$$GetHostMonitor(pConfigName,$$$eMonitorStatus)_" | "_$S(""=tStatus:"ConfigItem '"_$TR(pConfigName,$C(8),$C(177))_"' not found", 1:"found a job with status = '"_tStatus_"'")
	#; Examine those jobs that are enabled but not set to run as Jobs (Pool size 0 for BP, InProc for BP & BO, BS set for CreateBusinessService)
	If ($$$GetHostMonitor(pConfigName,$$$eMonitorStatus)="OK") && '$$$ConfigRunAsJob(pConfigName) && $$$ConfigIsEnabled(pConfigName) {
		#dim tStandardOK As %String =  "1_| OK | ConfigItem '"_$TR(pConfigName,$C(8),$C(177))_"' "
		If $$$ConfigBusinessType(pConfigName)=$$$eHostTypeProcess {
			If '$Get($$$ConfigPoolSize(pConfigName)) {
				Set tStatus = ..isConfigRunning("Ens.Actor")
				If 'tStatus {
					Quit tStatus				
				} Else {
					Quit tStandardOK_"running under shared actor pool"
				}
			}
			Quit tStandardOK_"enabled for in process invocation"
		} ElseIf $$$ConfigBusinessType(pConfigName)=$$$eHostTypeService {
			Quit tStandardOK_"enabled for external invocation"
		}ElseIf $$$ConfigBusinessType(pConfigName)=$$$eHostTypeOperation { 
			Quit tStandardOK_"enabled for in process invocation"
		}
	}
	Quit:'isrunning 0_tStatus
	
	#; Count connected jobs for the given ConfigName
	Set tCountConnected=0,tCountDisconnected=0,tCountListening=0
	Set tJob="" For { Set tJob=$$$OrderHostMonitor(pConfigName,$$$eMonitorJob,tJob)  Quit:tJob=""
		Set tConn=$e($$$GetJobMonitor(pConfigName,tJob,$$$eMonitorConnected))
		If tConn=1 {
			Set tCountConnected=tCountConnected+1
		} ElseIf tConn=0 {
			Set tCountDisconnected=tCountDisconnected+1
		} ElseIf tConn="." {
			Set tCountListening=tCountListening+1
		}
	}
	Set tConnectState=$S(tCountConnected:tCountConnected_" job"_$S(tCountConnected>1:"s",1:"")_" connected",1:"")
	Set tConnectState=tConnectState_$S(tCountDisconnected:$S(""=tConnectState:"",1:", ")_tCountDisconnected_" job"_$S(tCountDisconnected>1:"s",1:"")_" disconnected",1:"")
	Set tConnectState=tConnectState_$S(tCountListening:$S(""=tConnectState:"",1:", ")_tCountListening_" job"_$S(tCountListening>1:"s",1:"")_" listening",1:"")
	Quit $S(""'=tConnectState:tConnectState,1:1)_tStatus
}

}
