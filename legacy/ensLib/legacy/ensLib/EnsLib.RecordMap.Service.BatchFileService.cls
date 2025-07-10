/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Service to consume data from batch files using the RecordMap parsing framework.
Class EnsLib.RecordMap.Service.BatchFileService Extends EnsLib.RecordMap.Service.BatchStandard [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

/// Parse the incoming file and send the resulting Batch and/or Records to the targets in TargetConfigNames.
Method OnProcessInput(pInput As %Stream.Object, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tLookAhead = ""
		Set tIOStream = ##class(EnsLib.RecordMap.Service.FileServiceStream).%New(pInput)
		Set tIOStream.Name = ..GetFileName(pInput)
		
		While 'tIOStream.AtEnd {
			Set tPosition = tIOStream.Position
			Set tStatus = ..GetBatchObject(tIOStream, .tBatchObject,,.tLookAhead)
			If $$$ISERR(tStatus) || (tPosition=tIOStream.Position) Quit
			
			Set tStatus = ..SendBatch(tBatchObject, '..SynchronousSend)
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit
		
		If 'tIOStream.AtEnd {
			$$$LOGWARNING($$$FormatText($$$Text("Failed to advance record stream. Stopped reading file '%1' at position %2, not at end.","Ensemble"),tIOStream.Name,tIOStream.Position))
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLookAhead) '= "" {
		$$$LOGINFO("Discarding trailing characters: '"_tLookAhead_"'")
	}
	Quit tStatus
}

}
