/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Provides a concrete class that can be used to pass messages to a service
/// in a production.  This class can also be used via standard projections.
Class Ens.BusinessServiceHost Extends %RegisteredObject [ System = 4 ]
{

Property Service As Ens.BusinessService [ InitialExpression = {$$$NULLOREF} ];

/// Allows a request to be submitted for processing.
Method SubmitRequest(pRequest As Ens.Request, ByRef pResponse As Ens.Response) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		// Submit the request
		Set tSC = ..Service.ProcessInput(pRequest,.pResponse)
		Quit:$$$ISERR(tSC)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method %OnNew(pTargetService As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tService = $$$NULLOREF
		
		// Instantiate the target business service
		Set tSC=##class(Ens.Director).CreateBusinessService(pTargetService,.tService)
		Quit:$$$ISERR(tSC)
		
		Set ..Service = tService
	
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		// Release the service ...
		Set ..Service = $$$NULLOREF

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
