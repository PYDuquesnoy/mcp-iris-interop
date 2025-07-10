/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Testing.Process Extends Ens.BusinessProcess [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Method OnRequest(pTestingRequest As EnsLib.Testing.Request, Output pResponse As Ens.Response) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; make an asynchronous request to the target
		Set tRequest=$S($IsObject(pTestingRequest.Request)
					 && (""=pTestingRequest.%requestClassname
					  || ($classname(pTestingRequest.Request)=pTestingRequest.%requestClassname))
					 :pTestingRequest.Request
				,##class(%Dictionary.CompiledClass).%ExistsId(pTestingRequest.%requestClassname)
				 &&(""'=pTestingRequest.%requestId)
				  :$classmethod(pTestingRequest.%requestClassname,"%OpenId",pTestingRequest.%requestId)
				,1:$$$NULLOREF)
		If '$IsObject(tRequest) Set tSC=$$$ERROR($$$EnsErrGeneral,"No Testing Request Object found in testing Request wrapper message with header "_pTestingRequest.%Id())  Quit
		Set tSC = ..SendRequestAsync(pTestingRequest.Target, tRequest)  Quit:$$$ISERR(tSC)
		
		#; tell testing service we are starting
		Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId) = "Waiting"
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError Goto Exit
}

Method OnResponse(request As Ens.Request, ByRef response As Ens.Response, callrequest As Ens.Request, callresponse As Ens.Response, pCompletionKey As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; tell testing service we are done, using AppData global
		#; giving "time" a value tells the client we are done.
		Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId) = "Done"
		Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId,"time") = $$$timeUTC
		Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId,"error") = ""
		If ($IsObject(callresponse)) {
			Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId,"response") = $LB($classname(callresponse),callresponse.%Id())
			Set:request.SyncCall response=callresponse
		} Else {
			Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId,"response") = ""
		}
	} while 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError Goto Exit
}

/// This method is called when an error response is received
/// Returning the same error will cause the BusinessProcess to set its status to error and close down
/// Returning $$$OK from this method causes the BusinessProcess to recover from this error
Method OnError(request As Ens.Request, ByRef response As Ens.Response, callrequest As Ens.Request, pErrorStatus As %Status, pCompletionKey As %String) As %Status
{
	Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId) = "Error"
	Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId,"time") = $$$timeUTC
	Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId,"error") = pErrorStatus
	Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",..%SessionId,"response") = ""
	Quit pErrorStatus
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
