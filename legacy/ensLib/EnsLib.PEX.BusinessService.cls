/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.PEX.BusinessService Extends (Ens.BusinessService, EnsLib.PEX.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "Ens.InboundAdapter";

Parameter SETTINGS = "%remoteClassname:Remote BusinessService,%gatewayName:Remote BusinessService:ExternalLanguageServerSelector?Types=.NET;Java;Python,%remoteSettings:Remote BusinessService,%gatewayHost:Alternative ServiceConnection,%gatewayPort:Alternative ServiceConnection,%gatewayTimeout:Alternative ServiceConnection,%gatewayExtraClasspaths:Remote BusinessService:classpathsTable";

ClassMethod dispatchProcessInput(host As %RegisteredObject, pInput As %RegisteredObject) As %RegisteredObject
{
	// dispatchProcessInput is a classmethod because it can be called on a BusinessService object that is not PEX enabled
	set tSC = host.ProcessInput(pInput,.tOutput)
	if $$$ISERR(tSC) throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
	quit tOutput
}

Method OnProcessInput(request As %RegisteredObject, Output response As %RegisteredObject) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..CheckGatewayConnection() quit:$$$ISERR(tSC)
		try {
			set ..%gatewayProxy."_WaitForNextCallInterval" = ..%WaitForNextCallInterval
		} catch {}
		set response = ..%gatewayProxy.OnProcessInput(request)
		try {
			set ..%WaitForNextCallInterval = ..%gatewayProxy."_WaitForNextCallInterval"
		} catch {}
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

}
