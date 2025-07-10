/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Activity.Operation.REST Extends Ens.Activity.Operation.Base [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.HTTP.OutboundAdapter";

Method OnAddActivity(pStatsCategory As %String = "SC", pDays, pSeconds, pLocalTime, pUTC, pInstance, pNamespace, pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration, pSquares) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tResponse As %String = $$$OK
	#dim tHttpRequest As %Net.HttpRequest = ##class(%Net.HttpRequest).%New()
	#dim tHttpResponse As %Net.HttpResponse 
	
	Try {
		Set tHttpRequest.ContentType = "text/plain"
		Set tHttpRequest.EntityBody = ##class(%Stream.GlobalBinary).%New()
		Do tHttpRequest.EntityBody.Write($SYSTEM.Encryption.Base64Encode($LB(pStatsCategory, pDays, pSeconds, pLocalTime, pUTC, pInstance, pNamespace, pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration, pSquares)))
		Set tSC=..Adapter.SendFormDataArray(.tHttpResponse,"POST",tHttpRequest,,,..Adapter.URL)
		If $$$ISOK(tSC) && (tHttpResponse.StatusCode'=200) {
				Set tSC=$$$ERROR($$$EnsErrHTTPStatus,tHttpResponse.StatusCode,tHttpResponse.StatusLine)
			}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	
	If $$$ISOK(tSC) Set tSC = $S(tResponse="":$$$GeneralError,1:tResponse)
	Quit tSC
}

}
