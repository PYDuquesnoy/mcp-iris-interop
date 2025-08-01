/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.PEX.BusinessOperation Extends (Ens.BusinessOperation, EnsLib.PEX.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SETTINGS = "%remoteClassname:Remote BusinessOperation,%gatewayName:Remote BusinessOperation:ExternalLanguageServerSelector?Types=.NET;Java;Python,%remoteSettings:Remote BusinessOperation,%gatewayHost:Alternative OperationConnection,%gatewayPort:Alternative OperationConnection,%gatewayTimeout:Alternative OperationConnection,%gatewayExtraClasspaths:Remote BusinessOperation:classpathsTable";

Method OnMessage(request As %Library.Persistent, Output response As %Library.Persistent) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..CheckGatewayConnection() quit:$$$ISERR(tSC)
		if $isObject(request),request.%IsA("EnsLib.PEX.Message") set request = ..serialize(request)
		set response = ..%gatewayProxy."_dispatchOnMessage"(request)
		if response'="",$isObject(response)=0 set response = ..deserialize(response)
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

}
