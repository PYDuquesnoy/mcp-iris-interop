/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.CSPMonitor [ Abstract, System = 4 ]
{

/// <var>pParameter</var> is used to control whether "new" data is returned to the client.
/// Clients must explicitly pass in boolean flags in <var>pParameter</var> to indicate that they
/// can handle specific updates to the data in <var>pMatrix</var>.
/// The only flag implemented at this time is the 1 flag for Queue data.
ClassMethod GetMatrix(Output pMatrix As %CSP.Monitor.Matrix, pParameter As %String = "") As %Status
{
	set pMatrix=##class(%CSP.Monitor.Matrix).%New()
	set pMatrix.Type="Ensemble"
	set pMatrix.Name=$zu(110)_":"_$namespace

	do ##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)
	do pMatrix.Value.SetAt(tState,"ProductionState")
	do pMatrix.Value.SetAt(tProductionName,"ProductionName")
	Set tVersion = $listtostring(##class(%Library.EnsembleMgr).getVersion(),".")
	do pMatrix.Value.SetAt(tVersion,"ClientVersion")
	Set tHomePath = ##class(%Library.EnsembleMgr).DetermineMgmtURLForNamespace(,0)
	#; Check and use Optional Web Gateway URL Prefix
	Do ##class(%Studio.General).GetWebServerPort(/*.gwPort*/,/*.gwServer*/,.gwUrlprefix,/*.gwUurl*/)
	If gwUrlprefix '= "" Set tHomePath = "/" _ gwUrlprefix _ tHomePath
	do pMatrix.Value.SetAt(tHomePath,"EnsembleHomePath")
	do pMatrix.Value.SetAt($parameter("%Library.EnsembleMgr","PORTALHOMEPAGE"),"EnsembleHomePage")
	

	quit:tState'=$$$eProductionStateRunning $$$OK

	do pMatrix.Value.SetAt($$$timeUTCtoLocal($$$EnsRuntime("StartTime")),"StartTime")
	do pMatrix.Value.SetAt(##class(Ens.Director).ProductionNeedsUpdate(.tReason),"NeedsUpdate")
	do pMatrix.Value.SetAt($G(tReason),"UpdateReason")

	set tHost="" for { set tHost=$$$OrderHostMonitor(tHost)  quit:""=tHost
		set tHostMatrix=##class(%CSP.Monitor.Matrix).%New()
		do pMatrix.SubItems.Insert(tHostMatrix)
		set tHostMatrix.Type="Host"
		set tHostMatrix.Name=tHost
		do tHostMatrix.Value.SetAt($G($$$ConfigBusinessType(tHost)),"HostType")
		do tHostMatrix.Value.SetAt($$$GetHostMonitor(tHost,$$$eMonitorLastActivity),"LastActivity")
		do tHostMatrix.Value.SetAt($$$GetHostMonitor(tHost,$$$eMonitorCount),"CompletedCount")
		do tHostMatrix.Value.SetAt($$$GetHostMonitor(tHost,$$$eMonitorStatus),"Status")
	}

	#; Use pParameter to control whether new properties are exposed to keep backwards compatibility
	if $$$AND(pParameter,1) {
		set tQueueRS = ##class(%Library.ResultSet).%New("Ens.Queue:Enumerate")
		if $$$ISOK(tQueueRS.Execute()) {
			while tQueueRS.Next() {
				set tQueueMatrix = ##class(%CSP.Monitor.Matrix).%New()
				do pMatrix.SubItems.Insert(tQueueMatrix)
				set tQueueMatrix.Type = "Queue"
				set tQueueMatrix.Name = tQueueRS.Get("Name")
				do tQueueMatrix.Value.SetAt(tQueueRS.Get("Count"),"Count")
			}
		}
	}

	quit $$$OK
}

ClassMethod MsgSearch(Output pRS As %XML.DataSet, pFilterObjStr As %Stream.Object, pTimeout As %Numeric = -1, pNextId As %Integer = 0, pType As %String = "Search") As %Status
{
	Set pRS=$$$NULLOREF
	If $IsObject(pFilterObjStr) {
		Set tSC = ##class(Ens.Util.XML.Reader).ObjectFromStream(.tFilterObj,pFilterObjStr,"EnsPortal.MsgFilter.Filter,Ens.Enterprise.Portal.MsgFilter.LegacyFilter")
		If $$$ISERR(tSC) Quit tSC
		If $IsObject(tFilterObj) && tFilterObj.%IsA("Ens.Enterprise.Portal.MsgFilter.LegacyFilter") {
			Set tSC = tFilterObj.ConvertToNewFilter(.tNewFilter)
			If $$$ISERR(tSC) Quit tSC
			Set tFilterObj = tNewFilter
		}
	}
	if pType="Search" {
		Set pRS = ##class(%XML.DataSet).%New("EnsPortal.MsgFilter.Assistant:Enumerate")
	} elseif pType="HL7Search" {
		Set pRS = ##class(%XML.DataSet).%New("EnsPortal.MsgFilter.Assistant:Enumerate")
	} elseif pType="ShowDups" {
		Set pRS = ##class(%XML.DataSet).%New("EnsPortal.MsgFilter.SMAssistant:EnumerateDups")
	} elseif pType="ShowGaps" {
		Set pRS = ##class(%XML.DataSet).%New("EnsPortal.MsgFilter.SMAssistant:EnumerateGaps")
	} elseif pType="ShowLates" {
		Set pRS = ##class(%XML.DataSet).%New("EnsPortal.MsgFilter.SMAssistant:EnumerateLates")
	} else {
		Quit $$$ERROR($$$GeneralError,"Invalid monitor type: "_pType)
	}
	If '$IsObject(pRS) set tSC=$$$ERROR($$$GeneralError,"Failed to create ResultSet for "_pType)  Quit tSC
	If '$$$IsdefObject(tFilterObj) {
		If ""'=pFilterObjStr { Quit $$$ERROR($$$GeneralError,"Unexpected oref value for FilterObj : '"_tFilterObj_"'") }
		Set tFilterObj = ##class(EnsPortal.MsgFilter.Filter).%New()
	}
	Set tFilterObj.Timeout=pTimeout
	If pNextId {
		If tFilterObj.SortOrder = 1 {
			Set tFilterObj.StartId = pNextId
		}
		Else {
			Set tFilterObj.EndId = pNextId
		}
	}
	Do pRS.SetArgs(tFilterObj)
	Quit tSC
}

}
