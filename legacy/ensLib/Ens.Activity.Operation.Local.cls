/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Activity.Operation.Local Extends Ens.Activity.Operation.Base [ System = 4 ]
{

Parameter ADAPTER = "Ens.OutboundAdapter";

Property StorageNamespace As %String [ InitialExpression = {$NAMESPACE} ];

Parameter SETTINGS = "StorageNamespace:Basic:selector?context={Ens.ContextSearch/GetEnsembleNamespaces}";

/// Only return an error if expect a retry will be successful as 
/// returning an error will mean the temporary data is not deleted <br>
/// Log a warning if fail to permanently record activity data - once per item restart.<br>
Method OnAddActivity(pStatsCategory As %String = "SC", pDays, pSeconds, pLocalTime, pUTC, pInstance, pNamespace, pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration, pSquares) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		If pStatsCategory '= "SC" {
			Set tSC = $$$ERROR($$$NotImplemented)
			Quit
		}
		If ..StorageNamespace'=$NAMESPACE {NEW $NAMESPACE SET $NAMESPACE = ..StorageNamespace}
		#dim tCanRetryOnError = 0
		Set tSC = ##class(Ens.Activity.Utils).AddActivity(pLocalTime, pUTC, pInstance, pNamespace, pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration, pSquares, .tCanRetryOnError)
		If $$$ISERR(tSC) && 'tCanRetryOnError {
			If ..%LastReportedError = "" {
				Set ..%LastReportedError = $$$StatusDisplayString(tSC)
				$$$LOGWARNING("Failed to record activity statistics: "_..%LastReportedError_" Suppressing reporting of further failures until host item restart.")
			}
			#; Always return true so that caller (OnKeepalive) will remove the temp data
			Set tSC = $$$OK
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

}
