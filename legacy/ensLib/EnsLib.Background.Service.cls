/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Internal business service for queuing background work requests
Class EnsLib.Background.Service Extends Ens.BusinessService [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is the target if the request does not specify a value for property BackgroundProcessor
Property Target As Ens.DataType.ConfigName;

/// Exposed if this item is added to the production via portal/production definition to make it visible
Parameter SETTINGS = "Target";

Method OnProcessInput(pInput As Ens.Background.Request, pOutput As %RegisteredObject) As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException
	Set pOutput=$$$NULLOREF

	Try {

			#dim tTarget As Ens.DataType.ConfigName

			If pInput.BackgroundProcessor '= "" {

				Set tTarget = pInput.BackgroundProcessor

			} Else {

				If ..Target = "" {

					Set tSC = $$$ERROR($$$EnsErrGeneral,"No Target Config Name configured")

				} Else {

					Set tTarget = ..Target

				}

			}

			Set tSC = ..SendRequestAsync(tTarget, pInput)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

/// Send the background request.
ClassMethod SendBackgroundRequest(pRequest As Ens.Background.Request, ByRef pResponse As Ens.Response, Output pSessionId As %String) As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException
	Set pSessionId=""

	Try {

		#; Avoid using Ens.Director::GetProductionStatus() to reduce lock contention
		If '##class(Ens.Director).IsProductionRunning() {
			Set tSC = $$$ERROR($$$EnsErrProductionNotRunning)
			Quit
		}

		#dim tService
		Set tSC = ##class(Ens.Director).CreateBusinessService("EnsLib.Background.Service", .tService)
		If $$$ISERR(tSC) Quit

		Set tSC = tService.ProcessInput(pRequest,.pResponse)
		If $$$ISERR(tSC) Quit

		#; return session id to caller
		Set pSessionId = tService.%SessionId

	} Catch ex {

		Set tSC = ex.AsStatus()

	}
	Quit tSC
}

}
