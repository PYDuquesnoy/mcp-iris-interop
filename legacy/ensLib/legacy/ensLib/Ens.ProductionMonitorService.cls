/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides a monitor service for the production status
/// The default behavior of this service is to call UpdateProduction once it notices the production is not up-to-date.
/// Users can override the OnProcessInput method to customize the behavior.
Class Ens.ProductionMonitorService Extends Ens.BusinessService [ System = 4 ]
{

Parameter ADAPTER = "Ens.InboundAdapter";

/// The default behavior of this service is to call UpdateProduction once it notices the production is not up-to-date.
Method OnProcessInput(pInput As %RegisteredObject, pOutput As %RegisteredObject) As %Status
{
	set tSC=##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)
	if $$$ISERR(tSC) quit tSC
	if tState='$$$eProductionStateRunning quit $$$OK
	if ##class(Ens.Director).ProductionNeedsUpdate(.tReason) {
		$$$sysTRACE("Production is not up-to-date.")
		for i=1:1:$l(tReason,$c(13,10)) set tReasonLine=$p(tReason,$c(13,10)) if tReasonLine'="" $$$sysTRACE(tReasonLine)
		Set tSC = ..SendRequestAsync("Ens.ScheduleHandler",$$$NULLOREF)
		$$$sysTRACE("UpdateProduction() called.")
	}
	quit tSC
}

}
