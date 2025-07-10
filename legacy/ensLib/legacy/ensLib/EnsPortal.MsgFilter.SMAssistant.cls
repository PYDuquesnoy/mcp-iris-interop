/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsPortal.MsgFilter.SMAssistant [ Abstract, System = 4 ]
{

Query EnumerateDups(Filter As EnsPortal.MsgFilter.Filter) As %Query(ROWSPEC = "ID,TimeCreated,Session,Status,Error,Source,BodyID,BodyControlID,DupBodyIDs")
{
}

ClassMethod EnumerateDupsExecute(ByRef qHandle As %Binary, pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set qHandle = ""
	
	Set dateLen = 12
	If pFilter.TimeFormat '= "" {
		Set dateLen = pFilter.TimeFormat
	}
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tSQL = "SELECT ID, {fn RIGHT(%EXTERNAL(head.TimeCreated), "_dateLen_")} As TimeCreated,"
				_" SessionId As Session, Status, CASE IsError WHEN 1 THEN 'Error' ELSE 'OK' END As Error,"
				_" SourceConfigName As Source FROM Ens.MessageHeader head WHERE ID = ?"
	Set tStatus = tStatement.%Prepare(tSQL)
	Set qHandle("Statement") = tStatement
	Quit tStatus
}

ClassMethod EnumerateDupsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Set Row = ""
	Set AtEnd = 0
	Try {
		Set tHaveRow = 0
		While 'tHaveRow {
			Set tStatus = ##class(EnsLib.HL7.SequenceManager).GetDuplicatedList(.tArray, .qHandle, 1)
			If $$$ISERR(tStatus) Quit
			If qHandle = "" {
				Set AtEnd = 1
				Quit
			}
			Set tHdrId = $listget($get(tArray(1)))
			If tHdrId '= "" {
				Set tHaveRow = 1
				Set tStatement = qHandle("Statement")
				Set tRS = tStatement.%Execute(tHdrId)
				If 'tRS.%SQLCODE && tRS.%Next() {
					Set Row = $listbuild(tRS.ID, tRS.TimeCreated, tRS.Session, tRS.Status, tRS.Error, tRS.Source, $listget($get(tArray(1)),2),$listget($get(tArray(1)),3),$listget($get(tArray(1)),4))
				}
				Else {
					Set Row=$listbuild("NA","","","","","","","","")
				}
			}
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

ClassMethod EnumerateDupsClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
 	Quit $$$OK
}

/// This one does not currently return objects, only the sequence number of the message that should have arrived, and the higher sequence number of the one that already arrived
Query EnumerateGaps(Filter As EnsPortal.MsgFilter.Filter) As %Query(ROWSPEC = "ID,TimeCreated,Session,Status,Error,Source,Seq,TargetSeq")
{
}

ClassMethod EnumerateGapsExecute(ByRef qHandle As %Binary, pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set qHandle=""
	
 	Quit $$$OK
}

ClassMethod EnumerateGapsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Set AtEnd = 0
	Set Row = ""
	Try {
		Set tHaveRow = 0
		While 'tHaveRow {
			Set tStatus = ##class(EnsLib.HL7.SequenceManager).GetExpiredList(.tArray,.qHandle,1)
			If $$$ISERR(tStatus) Quit
			If qHandle = "" {
				Set AtEnd = 1
				Quit
			}
			Set tHdrId = $listget($get(tArray(1)))
			If tHdrId '= "" {
				Set tHaveRow = 1
				Set Row = $LB("GAP","","","","","",$LG($G(tArray(1)),1),$LG($G(tArray(1)),2))
			}
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

ClassMethod EnumerateGapsClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
 	Quit $$$OK
}

Query EnumerateLates(Filter As EnsPortal.MsgFilter.Filter) As %Query(ROWSPEC = "ID,TimeCreated,Session,Status,Error,Source,BodyID,Seq,NextSeq")
{
}

ClassMethod EnumerateLatesExecute(ByRef qHandle As %Binary, pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set qHandle = ""
	
	Set dateLen = 12
	If pFilter.TimeFormat '= "" {
		Set dateLen = pFilter.TimeFormat
	}
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tSQL = "SELECT ID, {fn RIGHT(%EXTERNAL(head.TimeCreated), "_dateLen_")} As TimeCreated,"
				_" SessionId As Session, Status, CASE IsError WHEN 1 THEN 'Error' ELSE 'OK' END As Error,"
				_" SourceConfigName As Source FROM Ens.MessageHeader head WHERE ID = ?"
	Set tStatus = tStatement.%Prepare(tSQL)
	Set qHandle("Statement") = tStatement
	Quit tStatus
}

ClassMethod EnumerateLatesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Set Row = ""
	Set AtEnd = 0
	Try {
		Set tHaveRow = 0
		While 'tHaveRow {
			Set tStatus = ##class(EnsLib.HL7.SequenceManager).GetOutOfSequenceList(.tArray,.qHandle,1)
			If $$$ISERR(tStatus) Quit
			If qHandle = "" {
				Set AtEnd = 1
				Quit
			}
			Set tHdrId = $listget($get(tArray(1)))
			If tHdrId '= "" {
				Set tHaveRow = 1
				Set tStatement = qHandle("Statement")
				Set tRS = tStatement.%Execute(tHdrId)
				If 'tRS.%SQLCODE && tRS.%Next() {
					Set Row = $listbuild(tRS.ID, tRS.TimeCreated, tRS.Session, tRS.Status, tRS.Error, tRS.Source, $listget($get(tArray(1)),2),$listget($get(tArray(1)),3),$listget($get(tArray(1)),4))
				}
				Else {
					Set Row=$listbuild("NA","","","","","","","","")
				}
			}
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

ClassMethod EnumerateLatesClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
 	Quit $$$OK
}

}
