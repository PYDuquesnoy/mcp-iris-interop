/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Activity.Operation.TCPCounted Extends Ens.Activity.Operation.Base [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.TCP.CountedOutboundAdapter";

Method OnAddActivity(pStatsCategory As %String = "SC", pDays, pSeconds, pLocalTime, pUTC, pInstance, pNamespace, pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration, pSquares) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tResponse As %String = $$$OK
	
	Try {
		Set tSC = ..Adapter.SendMessageString($LB(pStatsCategory, pDays, pSeconds, pLocalTime, pUTC, pInstance, pNamespace, pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration, pSquares),.tResponse)
	} Catch e {
		Set tSC = e.AsStatus()
	}
	
	If $$$ISOK(tSC) Set tSC = $S(tResponse="":$$$GeneralError,1:tResponse)
	Quit tSC
}

Method OnInit() As %Status
{
	Set ..Adapter.Charset = "Binary"
	Quit ##super()
}

}
