/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for Business Services which process streams containing batches of data mapped to a RecordMap Batch.
Class EnsLib.RecordMap.Service.BatchStandard Extends EnsLib.RecordMap.Service.Base [ Abstract, System = 4 ]
{

Parameter SETTINGS = "FatalErrors,SkipRecordParsingErrors,BatchHandling,BatchClass";

/// Name of Batch class to be used for input
Property BatchClass As %String(MAXLEN = 220);

/// Errors saving any record will be treated as Fatal. If "ParseOnly" is selected, errors when 
/// saving individual Records will not be treated as fatal, and parsing of the message will continue.
Property FatalErrors As %String(VALUELIST = ",Any,ParseOnly") [ InitialExpression = "Any" ];

/// By default errors parsing data into a record such as <EnsRecordMap>ErrQuoteCharMismatch
/// will be treated as fatal and end the processing of the message. <br>
/// These parsing errors are those detected before the record is saved. <br>
/// If this setting is enabled, errors when parsing the data into a record before saving is attempted
/// will not be treated as fatal, no attempt will be made to try to save the record
/// and parsing of the message will continue. <br>
/// Note the record data may become out of alignment. <br>
/// If this setting is enabled and AlertOnError is enabled, an alert will be sent when such an
/// error is encountered. <br>
Property SkipRecordParsingErrors As %Boolean [ InitialExpression = 0 ];

/// How to treat received batch documents: <br>
/// - Whole Batch : Accumulate and send the whole batch as one composite document <br/>
/// - Single-Session Batch : Forward all Records in the batch as part of a single session, including the Batch object <br/>
/// - Multi-Session Batch : Forward each Record in the batch in its own session, followed by the Batch object <br/>
/// - Individual : Forward each Record in the batch in its own session; do not forward the Batch object
Property BatchHandling As %String(DISPLAYLIST = ",Whole Batch,Single-Session Batch,Multi-Session Batch,Individual", VALUELIST = ",Whole,1Session,Batch,Indiv") [ InitialExpression = "1Session", Required ];

/// Parse a Batch object based on the specified Batch class and RecordMap
Method GetBatchObject(pIOStream As %IO.DeviceStream, Output pBatch As EnsLib.RecordMap.Batch, pTimeout As %Numeric = -1, ByRef pLookAhead As %String = "") As %Status
{
	Try {
		Set tStatus = $classmethod(..BatchClass, "GetBatchHeader", pIOStream, pTimeout, .pBatch, .pLookAhead)
		If $$$ISERR(tStatus) Quit
		If $IsObject(pBatch) {
			Set tCount = 0
			While 'pIOStream.AtEnd {
				Set tStatus = pBatch.GetBatchTrailer(pIOStream, pTimeout, .tFound, pBatch, .pLookAhead)
				If $$$ISERR(tStatus) Quit
				If $get(tFound) Quit
				Set tCount = tCount + 1
				Set tSkipDueToGetObjectError = 0
				Set tStatus = ..GetObject(pIOStream, .tObject, pTimeout, .pLookAhead)
				If $$$ISOK(tStatus) {
					#; In case we are going to accept ParseOnly errors have to account for initial record(s) being acceptable error.
					If (pBatch.%Id()="") {
						#; Save batch to ensure we have an ID
						Set tStatus = pBatch.%Save()
						#; This would not count as an acceptable parse error
						If $$$ISERR(tStatus) Quit
					}
					Set tStatus = tObject.%ParentBatchSetObjectId(pBatch.%Id())
					#; This would not count as an acceptable parse error
					If $$$ISERR(tStatus) Quit
					Set tStatus = tObject.%Save()
				} ElseIf (('..SkipRecordParsingErrors)||($SYSTEM.Status.GetErrorCodes(tStatus)'["<EnsRecordMap>")) {
					Quit
				} Else {
					Set tSkipDueToGetObjectError = 1
				}
				/*	tStatus will either be OK or 
					a Save validation error or
					a GetObject() fall through <EnsRecordMap> error with ..SkipRecordParsingErrors enabled
				*/
				If $$$ISERR(tStatus) {
					If ((..FatalErrors = "ParseOnly")||tSkipDueToGetObjectError){
						/*	Do not associate error with any prior session if using multiple sessions
							Multi-Session Batch = 'Batch' and 
							Individual = 'Indiv'
						*/
						If ((..BatchHandling="Batch")||(..BatchHandling="Indiv")) Set ..%SessionId = "", $$$JobSessionId = ""
						#dim tErrorText = $$$FormatText($$$Text("@IgnoreRecordSaveError@Ignoring RecordMap save error for Record #%1 in stream '%2'; error: '%3'","EnsRecordMap"),tCount,pIOStream.Name,$system.Status.GetErrorText(tStatus))
						$$$LOGERROR(tErrorText)
						If ..AlertOnError Do ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,tErrorText)))
						#; Reset tStatus since if last record in stream we will not exit with an error.
						Set tStatus = $$$OK
						Continue
					}
					Quit
				}
				Set tStatus = ..SendRecord(tObject)
				If $$$ISERR(tStatus) Quit
			}
			If $$$ISERR(tStatus) Quit
			Set pBatch.%Source = pIOStream.Name
			Set tStatus = pBatch.%Save()
			If $$$ISERR(tStatus) Quit
		}		
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Method to send the Batch object as per the specified BatchHandling behaviour.
Method SendBatch(pBatch As EnsLib.RecordMap.Batch, pAsync As %Boolean = 1, Output pResponses As %ListOfObjects) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pResponses = ##class(%ListOfObjects).%New()
		If ..BatchHandling = "Indiv" Quit
		If ..BatchHandling = "Batch" {
			Set ..%SessionId = ""
		}
		Set tStatus = ..SendRequest(pBatch, .pAsync, .pResponses)
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Method to send individual Records as needed for the specified BatchHandling behaviour.
Method SendRecord(pRecord As EnsLib.RecordMap.Base) As %Status
{
	Try {
		Set tStatus = $$$OK
		If ..BatchHandling '= "Whole" {
			If ..BatchHandling '= "1Session" {
				Set ..%SessionId = ""
			}
			Set tStatus = ..SendRequest(pRecord)
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Ensure that the Batch object exists and extends EnsLib.RecordMap.Batch.
Method OnInit() As %Status
{
	Set tStatus = ##super()
	If $$$ISERR(tStatus) Quit tStatus
	
	If '##class(%Dictionary.CompiledClass).%ExistsId(..BatchClass) {
		Quit $$$ERROR($$$ClassDoesNotExist, ..BatchClass)
	}
	
	If '$classmethod(..BatchClass, "%Extends", "EnsLib.RecordMap.Batch") {
		Quit $$$ERROR($$$EnsRecordMapErrInvalidClass, tTargetClass, "EnsLib.RecordMap.Base")
	}
	
	Set tModel = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(..recordMapFull, .tStatus)
	If $$$ISERR(tStatus) Quit tStatus
	
	If (tModel.batchClass '= "") && ($$$NormalizeClassname(tModel.batchClass) '= ..BatchClass) {
		Quit $$$ERROR($$$EnsRecordMapErrInvalidClass, ..BatchClass, tModel.batchClass)
	}
	
	Quit $$$OK
}

}
