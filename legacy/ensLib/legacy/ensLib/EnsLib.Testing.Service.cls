/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides the ability to test Business Operations and Business Processes,
Class EnsLib.Testing.Service Extends Ens.BusinessService [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Take an instance of EnsLib.Testing.Request and forward
/// its contents to the appropriate target.
Method OnProcessInput(pInput As EnsLib.Testing.Request, pOutput As %RegisteredObject) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, pOutput=$$$NULLOREF
	Do {
		Set:'$IsObject(pInput.Request)||'pInput.Request.%IsA("Ens.Request") tSC=pInput.setRequestProps()  Quit:$$$ISERR(tSC)

		If 'pInput.SyncCall {
			#; make an asynchronous request to testing process
			Set tSC = ..SendRequestAsync("EnsLib.Testing.Process", pInput)
		} Else {
			#; make a synchronous request to testing process
			Set tSC = ..SendRequestSync("EnsLib.Testing.Process", pInput, .pOutput)
		}
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="", tSC=$$$EnsSystemError
	Goto Exit
}

/// Send a test request to the specified target host 
/// (BusinessProcess or BusinessOperation).
ClassMethod SendTestRequest(pTarget As %String, pRequest As Ens.Request, ByRef pResponse As Ens.Response, Output pSessionId As %String, pGetReply As %Boolean = 0) As %Status
{
	Set pSessionId="", tSC=$$$OK
	Do {
		#; Create wrapper message for test request
		#; The wrapper contains routing details;
		#; The actual test request is contained within the wrapper.
		Set input = ##class(EnsLib.Testing.Request).%New()
		Set input.Target = pTarget
		Set input.Request = pRequest
		Set input.SyncCall = pGetReply
			 
		#; Use the Testing Service to dispatch the test request		
		Set tSC = ##class(Ens.Director).CreateBusinessService("EnsLib.Testing.Service", .tService)  Quit:$$$ISERR(tSC)
		Set tSC = tService.ProcessInput(.input,.pResponse)  Quit:$$$ISERR(tSC)

		#; return session id to caller
		Set pSessionId = tService.%SessionId
	} While (0)

	If ($$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

}
