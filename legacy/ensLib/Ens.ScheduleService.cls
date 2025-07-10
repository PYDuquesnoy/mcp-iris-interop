/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.ScheduleService Extends Ens.BusinessService [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod CallScheduleService() As %Status
{
	New $$$EnsJobLocal
	Set tSC=##class(Ens.Director).CreateBusinessService("Ens.ScheduleService",.tService)
	If $$$ISERR(tSC) Quit tSC
	Set tSC=tService.ProcessInput()
	#; Ensure tService is explicitly killed to ensure we don't tamper with $$$EnsJobLocal
	Kill tService
	Quit tSC
}

Method OnProcessInput(pInput As %RegisteredObject, pOutput As %RegisteredObject) As %Status
{
	Quit ..SendRequestAsync("Ens.ScheduleHandler",$$$NULLOREF)
}

}
