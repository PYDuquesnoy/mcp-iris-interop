/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class for writing out RecordMap batches. The batch will be written to a temporary file, 
/// and the <method>ProcessTempFile</method>() callback will be invoked when complete to allow subclasses to transmit
/// the batch to its destination.
Class EnsLib.RecordMap.Operation.BatchStandard Extends EnsLib.RecordMap.Operation.Standard [ Abstract, System = 4 ]
{

Parameter SETTINGS = "UnSwizzleRecords,UseDefaultBatch:Basic,DefaultBatchClass:Basic,WriteEmptyBatches:Basic,OpenMode,ReOpenMode,RolloverSchedule:Basic,RolloverLimit:Basic,DelayDefaultBatchOutput:Basic,IntermediateFilePath:Basic,AcceptDefaultParentBatch";

/// Flag to indicate whether Records which are assigned a batch already should be accepted. <br>
/// <property>UseDefaultBatch</property> must be enabled for this setting to take effect. <br>
/// This setting should be enabled if the user wants to resend Records that have been processed already. <br>
/// If enabled, the user is responsible for sending corresponding EnsLib.RecordMap.Batch requests to handle the rollover of non-default batches. <br>
/// For example, when <property>UseDefaultBatch</property> is enabled and the current default batch is User.Batch with ID 3, 
/// if the user wants to resend a Record from batch 2, they should: <br>
/// 1. Enable this setting. <br>
/// 2. Resend the Record, and a new intermediate file will be created for batch 2. <br>
/// 3. Send a User.Batch request with ID 2 when batch 2 needs to roll over.
Property AcceptDefaultParentBatch As %Boolean [ InitialExpression = 0 ];

/// Interval to use for checking schedule-based Rollover status. See the comments
/// for <property>RolloverSchedule</property> for more detailed information.
Parameter RolloverKeepalive = 1;

/// UnSwizzle each record from memory after it has been written to the output stream.
/// This option is used when processing an entire batch at once.
Property UnSwizzleRecords As %Boolean [ InitialExpression = 1 ];

/// Mode to open the temporary file with when creating a new file for a batch.
/// See the documentation for <class>%IO.FileStream</class> and file devices for more information on the available options.
Property OpenMode As %String [ InitialExpression = "RWN" ];

/// Mode to open the temporary file with when reopening an existing file for a batch.
/// See the documentation for <class>%IO.FileStream</class> and file devices for more information on the available options.
Property ReOpenMode As %String [ InitialExpression = "RW" ];

/// Control whether Batch objects which contain no records should be written out.
/// Note that this applies to all batches, including the default Batch.
Property WriteEmptyBatches As %Boolean [ InitialExpression = 0 ];

/// Flag to indicate whether Records which are not assigned to a batch already should be
/// added to a DefaultBatch. This DefaultBatch will be written out either when the operation
/// receives a BatchRolloverRequest or the batch object itself. If <property>RolloverSchedule</property>
/// is used to specify times when a Batch should be rolled over, then the current default Batch will be
/// written out based on the specified schedule.
Property UseDefaultBatch As %Boolean [ InitialExpression = 0 ];

/// The classname of the Batch class to be used for the default Batch.
Property DefaultBatchClass As Ens.DataType.Class;

/// A schedule string to control when the default Batch ought to be rolled over.
/// <property>UseDefaultBatch</property> must be enabled for this setting to take effect.
/// The schedule string takes the same format as the standard schedule string for a component,
/// with one exception: only START strings are permitted. At any time when a START is scheduled to occur,
/// the current default Batch will be written out and replaced with a new default Batch.
/// Note that the RolloverSchedule will be evaluated before checking <property>RolloverLimit</property>.
Property RolloverSchedule As %String(MAXLEN = "");

/// Provide a limit to the number of messages which will be included in the current default Batch.
/// <property>UseDefaultBatch</property> must be enabled for this setting to take effect.
/// If this number is 0, the application will be reponsible for enforcing batch rollovers by either
/// sending BatchRolloverRequest messages from other components or by making use of the 
/// <property>RolloverSchedule</property> property. Note that this limit is evaluated after checking
/// <property>RolloverSchedule</property>.
Property RolloverLimit As %Integer(MINVAL = 0) [ InitialExpression = 0 ];

/// When <property>UseDefaultBatch</property> is true, this flag controls whether data is appended to a 
/// temporary file as each record arrives, or whether all the data is written out to the temporary file
/// when the batch is rolled over.
Property DelayDefaultBatchOutput As %Boolean [ InitialExpression = 0 ];

/// The directory to use when creating a temporary file to write out the contents of a batch.
/// If no directory is specified, then the temporary file location for the namespace is used.
/// When the instance is running as part of a failover cluster or mirror with a 
/// shared or replicated disk, this path should be on a file system that is visible to both instances,
/// as the operation uses an intermediate file to collect record data as each record is processed by the operation.
/// When a batch object is sent to the operation or when <property>DelayDefaultBatchOutput</property> is true
/// and a default batch is rolled over, the intermediate file is only used for a short interval before
/// being handed off to the adapter for transmission. When individual records are sent to the operation,
/// the intermediate file will be in use until the operation receives a trigger to output the entire batch,
/// which may be many hours after the first record is received.
Property IntermediateFilePath As %String(MAXLEN = 1000);

/// Flag to indicate whether a Rollover check is in progress.
Property CheckingRollover As %Boolean [ InitialExpression = 0, Private, Transient ];

/// Handle the incoming requests depending on their type.
/// If a Batch is received without being preceded by one of the Records it contains,
/// the entire batch will be written out to the temporary file on disk at once.
/// If a Record precedes its Batch, the Batch header will be written to the temporary file
/// followed by the Record. All Records in this Batch received by the operation will then
/// be appended to the Batch file. When the Batch document itself is received, the
/// Batch trailer will be written to the temporary file and the Batch will be transmitted.
/// If a BatchRolloverRequest is received and <property>UseDefaultBatch</property> is true,
/// the current default Batch will be rolled over and will be treated as if the default
/// Batch was sent in a message.
Method OnMessage(pRequest As %Persistent, Output pResponse As EnsLib.RecordMap.BatchResponse) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pResponse = $$$NULLOREF
		
		If '..CheckingRollover { ; check whether a Rollover needs to occur before processing the current message
			Set tStatus = ..CheckRollover()
			If $$$ISERR(tStatus) Quit
		}
		
		If pRequest.%Extends("EnsLib.RecordMap.Batch") {
			Set tStatus = ..PutBatch(pRequest, .pResponse)
			Quit
		}
		If pRequest.%Extends("EnsLib.RecordMap.Base") {
			Set tStatus = ..PutRecord(pRequest, .pResponse) 
			Quit
		}
		If pRequest.%Extends("EnsLib.RecordMap.BatchRolloverRequest") {
			If '..UseDefaultBatch {
				$$$LOGINFO($$$FormatText($$$Text("@IgnoreBatchRollover@The default batch is disabled; BatchRolloverRequest with classname '%1' and Id '%2' is being ignored","EnsRecordMap"),$classname(pRequest),pRequest.%Id()))
				Quit
			}
			$$$sysTRACE("Processing BatchRolloverRequest '"_$classname(pRequest)_"::"_pRequest.%Id()_"'")
			Lock +$$$RMDefaultBatch
			Set tDefBatchLocked = 1
			Set tStatus = ..GetDefaultBatch(.tDefaultBatch)
			If $$$ISERR(tStatus) Quit
			Set tStatus = ..PutBatch(tDefaultBatch, .pResponse)
			If $$$ISERR(tStatus) Quit
			Lock -$$$RMDefaultBatch
			Set tDefBatchLocked = 0
			Quit
		}
		$$$LOGWARNING("Unrecognized request type: " _ $classname(pRequest))
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tDefBatchLocked) {
		Lock -$$$RMDefaultBatch
	}
	Quit tStatus
}

/// Handle writing out a Batch object, depending on context. See the documentation for the 
/// <method>OnMessage</method> method for more information on the processing order.
Method PutBatch(pBatch As EnsLib.RecordMap.Batch, Output pResponse As EnsLib.RecordMap.BatchResponse) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pResponse = ""
		If ..UseDefaultBatch {
			Lock +$$$RMDefaultBatch
			Set tDefBatchLocked = 1
			If ($$$RMDefaultBatchClass '= $classname(pBatch)) || ($$$RMDefaultBatchId '= pBatch.%Id()) {
				Lock -$$$RMDefaultBatch
				Set tDefBatchLocked = 0
			}
		}
		Set tTempFile = ##class(%IO.FileStream).%New()
		Set tBatchClass = $classname(pBatch)
		Set tBatchId = pBatch.%Id()
		Lock +$$$RMBatchTempFile(tBatchClass, tBatchId)
		Set tLocked = 1
		/*
			Record any previous recorded put error since this entry
			will be deleted if this process is successful or possibly replaced if another error.
		*/
		#dim tErroredTempFile As %String = $Get($$$RMBatchPutError(tBatchClass,tBatchId))

		Set tCharEncoding = ..GetCharEncoding()
		// Check if we started this file already
		Set tOldTempFile = $get($$$RMBatchTempFile(tBatchClass,tBatchId))
		If tOldTempFile = "" { // Output whole batch
			If '..WriteEmptyBatches && (pBatch.Records.Count() = 0) {
				$$$LOGINFO($$$FormatText($$$Text("@IgnoreEmptyBatch@Ignoring empty batch '%1'::'%2'","EnsRecordMap"),$classname(pBatch),pBatch.%Id()))
				Set tBatchCount = 0
				Set tStatus = $$$OK
				Quit
			}
			Set tTempFilename = ..GetTempFilename(tBatchClass,tBatchId)
			Do tTempFile.Open(tTempFilename, ..OpenMode,,tCharEncoding,.tStatus)
			If $$$ISERR(tStatus) Quit
			Set tTempFile.BuildCharPosMap = 0
			Set tStatus = pBatch.OutputWholeBatch(tTempFile, ..recordMapFull, ..UnSwizzleRecords)
			If $$$ISERR(tStatus) Quit
			Set tBatchCount = pBatch.Records.Count()
		}
		Else { // Output batch trailer to previously started file
			Do tTempFile.Open(tOldTempFile, ..ReOpenMode,,tCharEncoding,.tStatus)
			If $$$ISERR(tStatus) Quit
			Set tTempFile.BuildCharPosMap = 0
			If '$get($$$RMBatchWritten(tBatchClass,tBatchId)) {
				Do tTempFile.ExternalByteSeek(tTempFile.ExternalByteSize+1, .tStatus)
				If $$$ISERR(tStatus) Quit
				Set tStatus = pBatch.PutBatchTrailer(tTempFile)
				If $$$ISERR(tStatus) Quit
			}
			Set tBatchCount = $get($$$RMBatchCount(tBatchClass,tBatchId))
		}
		Do tTempFile.Rewind(.tStatus)
		If $$$ISERR(tStatus) Quit
		Set $$$RMBatchWritten(tBatchClass,tBatchId) = 1
		$$$sysTRACE("Calling ProcessTempFile()")
		Set tStatus = ..ProcessTempFile(tTempFile, pBatch)
		If $$$ISOK(tStatus) {
			If $get(tDefBatchLocked) { // This is the default batch
				Set tStatus = ..SwitchDefaultBatch()
				If $$$ISERR(tStatus) Quit
			}
			Kill $$$RMBatchTempFile(tBatchClass, tBatchId)
			Kill $$$RMBatchWritten(tBatchClass, tBatchId)
			Kill $$$RMBatchCount(tBatchClass, tBatchId)
			Kill $$$RMBatchPutError(tBatchClass,tBatchId)
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLocked) {
		/* 
			Remove temp file if it is not to be re-used.
			$$$RMBatchTempFile(tBatchClass, tBatchId) might not exist but tTempFile.Name cannot be ""
			If tLocked we can trust variables.
			Record temp file name if errored.
			Clean up out of date errored file if different.
		*/
		Try {
			If ($Get($$$RMBatchTempFile(tBatchClass,tBatchId))'=tTempFile.Name)&&##class(%File).Exists(tTempFile.Name) {
				Do tTempFile.Close()
				If '##class(%File).Delete(tTempFile.Name) $$$LOGWARNING("Failed to delete temporary file: "_tTempFile.Name)			
			} ElseIf $$$ISERR(tStatus)&&($Data($$$RMBatchTempFile(tBatchClass,tBatchId))#2) {
				#;Errored so record batch class and batch id so that in OnFailureTimeOut can look and clean up.
				Set $$$RMBatchPutError(tBatchClass,tBatchId)=tTempFile.Name		
			}

			#; Remove errored file - either due to successful put or another error with a new file name
			If (tErroredTempFile'="")&&(tErroredTempFile'=tTempFile.Name)&&(##class(%File).Exists(tErroredTempFile)) {
				If '##class(%File).Delete(tErroredTempFile) $$$LOGWARNING("Failed to delete temporary file: "_tErroredTempFile)
			}
			
		} Catch e { 
			$$$LOGWARNING("Error deleting temporary file: "_tTempFile.Name_" "_e.AsSystemError())
		}

		Lock -$$$RMBatchTempFile(tBatchClass, tBatchId)
	}
	If $get(tDefBatchLocked) {
		Lock -$$$RMDefaultBatch
	}
	; Only return a response if not inside a Rollover check and a reply is needed
	If $$$ISOK(tStatus) && ('..CheckingRollover) && $IsObject(..%RequestHeader) && ..%RequestHeader.needsReply() {
		Set pResponse = ##class(EnsLib.RecordMap.BatchResponse).%New()
		Set pResponse.BatchClass = tBatchClass
		Set pResponse.BatchId = tBatchId
		Set pResponse.RecordCount = tBatchCount
	}
	Quit tStatus
}

/// Write out a Record object, depending on the context for the Batch to which the Record belongs.
Method PutRecord(pRecord As EnsLib.RecordMap.Base, Output pResponse As EnsLib.RecordMap.BatchResponse) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pResponse = ""
		Set tIsDefaultBatch = 0
		#dim tBatch As EnsLib.RecordMap.Batch
		Set tBatch = pRecord.%ParentBatch // runtime test for existence of parent
		If '$IsObject(tBatch) {
			If ..UseDefaultBatch {
				Lock +$$$RMDefaultBatch
				Set tDefBatchLocked = 1
				Set tBatchClass = $$$RMDefaultBatchClass
				Set tBatchId = $$$RMDefaultBatchId
				Set tRecordClass = $$$RMDefaultRecordClass
				If (tRecordClass '= "") && ('pRecord.%IsA(tRecordClass)) {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrInvalidRecordClass,$classname(pRecord),tRecordClass,tBatchClass)
					Quit
				}
				$$$sysTRACE("Setting %ParentBatch Id to "_tBatchId_" for Record class'"_$classname(pRecord)_"', Id '"_pRecord.%Id()_"'")
				Set tStatus = pRecord.%ParentBatchSetObjectId(tBatchId)
				If $$$ISERR(tStatus) Quit
				Set tStatus = pRecord.%Save()
				If $$$ISERR(tStatus) Quit
				Set tIsDefaultBatch = 1
			} Else {
				Set tStatus = $$$ERROR($$$EnsRecordMapErrNoBatchParent, $classname(pRecord), pRecord.%Id())
				Quit
			}
		} Else { // Record coming with a non-null %ParentBatch
			If ..UseDefaultBatch && '..AcceptDefaultParentBatch  {
				Set tStatus = $$$ERROR($$$EnsRecordMapErrParentBatchExists)
				Quit
			}
			Set tBatchClass = $classname(tBatch)
			Set tBatchId = tBatch.%Id()
		}
		Lock +$$$RMBatchTempFile(tBatchClass, tBatchId)
		Set tLocked = 1
		Set tOldTempFile = $get($$$RMBatchTempFile(tBatchClass,tBatchId))
		
		If (tOldTempFile = "") && tIsDefaultBatch && ..DelayDefaultBatchOutput {
			Set tTempFile = ""
		}
		Else {
			Set tTempFile = ##class(%IO.FileStream).%New()
			Set tCharEncoding = ..GetCharEncoding()
			If tOldTempFile = "" { // create file and output batch header
				Set tTempFilename = ..GetTempFilename(tBatchClass,tBatchId)
				Do tTempFile.Open(tTempFilename, ..OpenMode,,tCharEncoding,.tStatus) 
				If $$$ISERR(tStatus) Quit
				Set tTempFile.BuildCharPosMap = 0
				
				If '$IsObject(tBatch) { // Catch case where the default batch wasn't loaded
					Set tBatch = $classmethod(tBatchClass, "%OpenId", tBatchId,,.tStatus)
					If $$$ISERR(tStatus) Quit
				}
				
				$$$sysTRACE("Writing batch header for batch '"_tBatchClass_"::"_tBatchId_"' to temp file '"_tTempFilename_"'")
				Set tStatus = tBatch.PutBatchHeader(tTempFile)
				If $$$ISERR(tStatus) Quit
					
				Set $$$RMBatchTempFile(tBatchClass,tBatchId) = tTempFilename	
			}
			Else { // reopen file and move to end
				$$$sysTRACE("Appending record to temp file '"_tOldTempFile_"' for batch '"_tBatchClass_"::"_tBatchId_"')")
				Do tTempFile.Open(tOldTempFile, ..ReOpenMode,,tCharEncoding,.tStatus)
				If $$$ISERR(tStatus) Quit
				Set tTempFile.BuildCharPosMap = 0
				Do tTempFile.ExternalByteSeek(tTempFile.ExternalByteSize+1, .tStatus)
				If $$$ISERR(tStatus) Quit
			}
			Set tStatus = ..PutObject(tTempFile, pRecord)
			If $$$ISERR(tStatus) Quit
		}
		Set tCount = $increment($$$RMBatchCount(tBatchClass, tBatchId))
		If ..RolloverLimit && (tCount >= ..RolloverLimit) {
			If $IsObject(tTempFile) {
				#; Close temp file so it can be opened correctly in batch rollover
				Do tTempFile.Close(.tStatus)
				If $$$ISERR(tStatus) Quit
			}
			$$$sysTRACE("Rolling over default batch due to encountered RolloverLimit of "_..RolloverLimit)
			Set tStatus = ..TriggerRollover()
			If $$$ISERR(tStatus) Quit
		}
		If ..%RequestHeader.needsReply() {
			Set pResponse = ##class(EnsLib.RecordMap.BatchResponse).%New()
			Set pResponse.RecordCount = tCount
			Set pResponse.BatchClass = tBatchClass
			Set pResponse.BatchId = tBatchId
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLocked) {
		Lock -$$$RMBatchTempFile(tBatchClass, tBatchId)
	}
	If $get(tDefBatchLocked) {
		Lock -$$$RMDefaultBatch
	}
	Quit tStatus
}

/// Callback which subclasses should override. The completed temporary file will be passed to this
/// method when the Batch has been processed.
Method ProcessTempFile(pTempFile As %IO.FileStream, pBatch As EnsLib.RecordMap.Batch) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Create a new batch object if <property>UseDefaultBatch</property> is true.
/// This method has no effect when <property>UseDefaultBatch</property> is false.
Method SwitchDefaultBatch() As %Status
{
	Try {
		Set tStatus = $$$OK
		Set tLocked = 0
		
		If '..UseDefaultBatch { Quit }
		
		Lock +$$$RMDefaultBatch
		Set tLocked = 1
		Set tOldBatch = $get($$$RMDefaultBatch)
		Set tOldBatchId = $listget(tOldBatch, 2)
		Set tStatus = ..CreateDefaultBatch(.tDefaultBatch)
		If $$$ISERR(tStatus) Quit
		Set tStatus = tDefaultBatch.%Save()
		If $$$ISERR(tStatus) Quit
		$$$sysTRACE("Switching batch of type '"_..DefaultBatchClass_"; new batch has Id '"_tDefaultBatch.%Id()_"'"_$select(tOldBatchId: "; old batch has Id '"_tOldBatchId_"'",1:""))
		Set $$$RMDefaultBatch = $listbuild(..DefaultBatchClass, tDefaultBatch.%Id(), tDefaultBatch.Records.ElementType)
		Kill $$$RMNextRollover
		If ..RolloverSchedule '= "" {
			Set tStatus = ..UpdateRolloverTime(tLocked)
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLocked) {
		Lock -$$$RMDefaultBatch
	}
	Quit tStatus
}

/// Return the expected character encoding to use for the output.
/// The Batch operation uses a temp file to store data prior to writing out the
/// end of the batch, and we need to know what encoding we should use to match the 
/// final output encoding.
/// Subclasses that specify alternate character encodings should override this method.
Method GetCharEncoding() As %String
{
	Quit "Native"
}

/// Callback to create a new default Batch. This method can be overridden 
/// in subclasses to further initialize the Batch object.
Method CreateDefaultBatch(Output pDefaultBatch As EnsLib.RecordMap.Batch) As %Status
{
	Set pDefaultBatch = $classmethod(..DefaultBatchClass, "%New")
	Quit $$$OK
}

/// Helper method to get a temporary filename for intermediate batch output.
/// Users can override this method should they choose to.
Method GetTempFilename(pBatchClass As %String = "", pBatchID As %String = "") As %String
{
	Quit ##class(%IO.FileStream).NewTempFilename(,1,..IntermediateFilePath)
}

/// Get the current default Batch as an object
Method GetDefaultBatch(Output pDefaultBatch As EnsLib.RecordMap.Batch) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pDefaultBatch = ""
		If '..UseDefaultBatch Quit
		
		Lock +$$$RMDefaultBatch
		Set tDefBatchLocked = 1
		
		Set tDefaultBatch = $get($$$RMDefaultBatch)
		If tDefaultBatch = "" {
			Set tStatus = ..SwitchDefaultBatch()
			If $$$ISERR(tStatus) Quit
			Set tDefaultBatch = $get($$$RMDefaultBatch)
		}
		Set tClass = $$$RMDefaultBatchClass
		Set tId = $$$RMDefaultBatchId
		Set pDefaultBatch = $classmethod(tClass, "%OpenId", tId)
	}
	Catch {
		Set tStatus = $$$EnsSystemError
		Set pDefaultBatch = ""
	}
	If $get(tDefBatchLocked) {
		Lock -$$$RMDefaultBatch
	}
	Quit tStatus
}

/// Check whether the current default Batch needs to be rolled over.
/// This check is not run if <property>UseDefaultBatch</property> is false
/// or if <property>RolloverSchedule</property> is not specified.
/// Note that the check based on <property>RolloverLimit</property> is
/// performed after the record has been written out in <method>PutRecord</method>().
Method CheckRollover(pLocked As %Boolean = 0) As %Status
{
	Try {
		Set tStatus = $$$OK
		
		If ('..UseDefaultBatch) || (..RolloverSchedule = "") { Quit }
		
		Set ..CheckingRollover = 1
		Set tLocked = pLocked
		If 'tLocked {
			Lock +$$$RMDefaultBatch
			Set tLocked = 1
		}
		If ..RolloverSchedule '= "" {
			$$$sysTRACE("Checking rollover for current batch using RolloverSchedule '"_..RolloverSchedule_"'")
			Set tDoUpdate = 1
			Set tNextRollover = $get($$$RMNextRollover)
			If tNextRollover '= "" {
				If $$$timeUTC ] tNextRollover {
					$$$sysTRACE("Rolling over default batch due to RolloverSchedule time of "_tNextRollover_" UTC / "_$$$timeUTCtoLocal(tNextRollover)_" Local")
					Set tStatus = ..TriggerRollover()
					If $$$ISERR(tStatus) Quit
				}
				Else {
					Set tDoUpdate = 0
				}
			}
		}
		If tDoUpdate {
			Set tStatus = ..UpdateRolloverTime(tLocked)
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $get(tLocked)&&('pLocked) {
		Lock -$$$RMDefaultBatch
	}
	Set ..CheckingRollover = 0
	Quit tStatus
}

/// Calculate the next rollover time based on the contents of <property>RolloverSchedule</property>.
Method UpdateRolloverTime(pLocked As %Boolean = 0) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set tLocked = pLocked
		If 'tLocked {
			Lock +$$$RMDefaultBatch
			Set tLocked = 1
		}
		Set tCurrTime = ""
		For {
			Set tStatus = ##class(Ens.ScheduleHandler).ParseScheduleSpec(..RolloverSchedule, .tCurrState, .tNextDateTime, .tNextAction, tCurrTime)
			If $$$ISERR(tStatus) Quit
			If tNextAction = "START" {
				Set tNextDateTime = $translate(tNextDateTime,"T"," ")
				Set $$$RMNextRollover = $$$timeLocaltoUTC(tNextDateTime)
				Quit
			}
			ElseIf (tNextAction = "") || (tNextDateTime = "") {
				Quit
			}
			Else {
				Set tCurrTime = tNextDateTime
			}
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $get(tLocked)&&('pLocked) {
		Lock -$$$RMDefaultBatch
	}
	Quit tStatus
}

/// Trigger a default batch rollover by calling <method>OnMessage</method>()
/// with a <class>EnsLib.RecordMap.BatchRolloverRequest</class> instance.
Method TriggerRollover() As %Status
{
	Try {
		Set tStatus = $$$OK
		Set tInRolloverCheck = ..CheckingRollover
		If 'tInRolloverCheck { Set ..CheckingRollover = 1 }
		Set tRollover = ##class(EnsLib.RecordMap.BatchRolloverRequest).%New()
		Set tStatus = ..OnMessage(tRollover)
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $get(tInRolloverCheck) = 0 {
		Set ..CheckingRollover = 0
	}
	Quit tStatus
}

/// Verify the previous default Batch object if <property>UseDefaultBatch</property> is true, 
/// or create a new one if it didn't exist previously. Also validate that the contents
/// of <property>RolloverSchedule</property> are valid.
Method OnInit() As %Status
{
	Try {
		Set tStatus = ##super()
		If $$$ISERR(tStatus) Quit
		
		If ..UseDefaultBatch {
			If '##class(%Dictionary.CompiledClass).%ExistsId(..DefaultBatchClass) {
				Set tStatus = $$$ERROR($$$ClassDoesNotExist, ..DefaultBatchClass)
				Quit
			}
			Lock +$$$RMDefaultBatch
			Set tDefBatchLocked = 1
			If ..RolloverSchedule '= "" {
				If $zcvt(..RolloverSchedule,"U") [ "STOP" {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrInvalidRolloverSpec,..RolloverSchedule,"action","STOP")
					Quit
				}
				#; Ensure OnKeepalive() is invoked to allow for timed Rollover processing to occur
				Set ..Adapter.KeepaliveInterval = ..#RolloverKeepalive
				#; Ensure we initialize the rollover time when starting or updating the Operation
				Set tStatus = ..UpdateRolloverTime(tDefBatchLocked)
				If $$$ISERR(tStatus) Quit
			}
			Else {
				#; Make sure we don't have a stale rollover defined
				Kill $$$RMNextRollover
			}

			Set tPrevBatch = $get($$$RMDefaultBatch)
			If tPrevBatch = "" {
				Set tStatus = ..SwitchDefaultBatch()
				Quit
			}
			Else {
				Set tPrevClass = $$$RMDefaultBatchClass
				Set tPrevId = $$$RMDefaultBatchId
				If tPrevClass = ..DefaultBatchClass {
					// Confirm the previous batch exists
					If '$classmethod(..DefaultBatchClass, "%ExistsId", tPrevId) {
						Set tStatus = $$$ERROR($$$LoadObjectNotFound, ..DefaultBatchClass, tPrevId)
						Quit
					}
				}
				Else {
					$$$LOGWARNING($$$FormatText($$$Text("@ChangedDefaultBatch@DefaultBatchClass has changed in operation '%1'; previous default batch of type '%2' with Id '%3' is being written out","EnsRecordMap"),..%ConfigName, tPrevClass, tPrevId))
					Set tOldBatch = $classmethod(tPrevClass, "%OpenId", tPrevId,,.tStatus)
					If $$$ISERR(tStatus) Quit
					Set tStatus = ..PutBatch(tOldBatch)
					If $$$ISERR(tStatus) Quit
					Set tStatus = ..SwitchDefaultBatch()
					If $$$ISERR(tStatus) Quit
				}
			}
		}
		If (..IntermediateFilePath '= "") && '##class(%Library.File).DirectoryExists(..IntermediateFilePath) {
			Set tStatus = $$$ERROR($$$DirectoryNotExist,..IntermediateFilePath)
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tDefBatchLocked) {
		Lock -$$$RMDefaultBatch
	}
	Quit tStatus
}

/// Callback invoked to check whether a Rollover is required when
/// <property>RolloverSchedule</property> is specified.
Method OnKeepalive(pAdapterStatus As %Status) As %Status
{
	Set tStatus = ##super(pAdapterStatus)
	If $$$ISERR(tStatus) Quit tStatus
	Quit ..CheckRollover()
}

/// Clean up temp file and AppData that might be left.
Method OnFailureTimeout(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent, ByRef pSC As %Status) As %Boolean
{
	#; Look to see if need to clean up. pRequest ought to be a valid persisted batch request object
	If pRequest.%Extends("EnsLib.RecordMap.Batch") && (pRequest.%Id()'="") {
		Do ..cleanUpRMBatch($Classname(pRequest),pRequest.%Id())
	}
	#; Carry on with finalReplyAction.
	Quit 1
}

/// Helper method to clean up temporary file and Ens.AppData global entries
Method cleanUpRMBatch(pBatchClass As %String, pBatchId As %String) [ Internal, Private ]
{
	#dim tLocked As %Boolean = 0
	#dim e As %Exception.AbstractException
	#dim tRecordedTempFile As %String
	#dim tErroredTempFile As %String
	Try {
		
		Lock +$$$RMBatchTempFile(pBatchClass, pBatchId)
		Set tLocked = 1
		
		#; Look for errored put recording
		Set tErroredTempFile = $Get($$$RMBatchPutError(pBatchClass,pBatchId))
		If (tErroredTempFile'="")&&(##class(%File).Exists(tErroredTempFile)) {
				If '##class(%File).Delete(tErroredTempFile) $$$LOGWARNING("Failed to delete temporary file: "_tErroredTempFile)
		}

		#;In case no errored temp file reported or the temp file reported in the error entry is not the one recorded in the BatchTempFile entry 
		Set tRecordedTempFile = $Get($$$RMBatchTempFile(pBatchClass,pBatchId))
		If (tRecordedTempFile'="")&&(tRecordedTempFile'=tErroredTempFile)&&(##class(%File).Exists(tRecordedTempFile)) {
				If '##class(%File).Delete(tRecordedTempFile) $$$LOGWARNING("Failed to delete temporary file: "_tRecordedTempFile)
		}
		
		#;Clean up EnsAppData
		Kill $$$RMBatchTempFile(pBatchClass, pBatchId)
		Kill $$$RMBatchWritten(pBatchClass, pBatchId)
		Kill $$$RMBatchCount(pBatchClass, pBatchId)
		Kill $$$RMBatchPutError(pBatchClass,pBatchId)
		
	} Catch e {
		$$$LOGWARNING("Error cleaning temporary file and data for batch class and ID ("_pBatchClass_"/"_pBatchId_"): "_tErroredTempFile_"/"_tRecordedTempFile_" "_e.AsSystemError())
	}

	If tLocked Lock -$$$RMBatchTempFile(pBatchClass, pBatchId)
}

}
