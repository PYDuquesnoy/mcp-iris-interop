/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsRecordMap)

/// Base class for batches of homogenous RecordMap objects
/// Note that the RecordMap framework will automatically define a relationship called Records
/// to the Record type contained in the batch. The RECORDMAPGENERATED parameter should be set to 0 if this 
/// automatic update should not occur.
Class EnsLib.RecordMap.Batch Extends (%XML.Adaptor, Ens.Request) [ Abstract, System = 4 ]
{

/// Parameter to indicate that the class has been generated by the RecordMap framework.
/// If this parameter is set to 0, the RecordMap framework will NOT update this class automatically,
/// and responsibility for any further changes will fall on the user.
Parameter RECORDMAPGENERATED = 1;

/// Ensure RecordMap classes use the default XMLIGNORENULL behaviour for XML import and export.
/// This parameter is set to 1 in Ens.MessageBody.
Parameter XMLIGNORENULL = 0;

/// Name of source document or connection from which this batch was created.
Property %Source As %String(MAXLEN = 2000, XMLPROJECTION = "NONE");

/// Get the Batch Header from an incoming stream. This is only invoked once by the RecordMap
/// batch services when a new stream is passed in. Any extra data must be returned in pLookAhead
/// for use in parsing the first record.
ClassMethod GetBatchHeader(pIOStream As %IO.DeviceStream, pTimeout As %Numeric = -1, Output pBatch As EnsLib.RecordMap.Batch, ByRef pLookAhead As %String) As %Status
{
	Set pLookAhead = $get(pLookAhead)
	Set pBatch = ..%New()
	Quit $$$OK
}

/// Check for the Batch Trailer. The RecordMap batch services will invoke this method on every
/// record in a file after the Batch Header is found. 
ClassMethod GetBatchTrailer(pIOStream As %IO.DeviceStream, pTimeout As %Numeric = -1, Output pFound As %Boolean, pBatch As EnsLib.RecordMap.Batch, ByRef pLookAhead As %String) As %Status
{
	Set pFound = pIOStream.AtEnd
	Set pLookAhead = $get(pLookAhead)
	Quit $$$OK
}

/// Write out the Batch Header for the current Batch object
Method PutBatchHeader(pIOStream As %IO.DeviceStream) As %Status
{
	Quit $$$OK
}

/// Write out the Batch Trailer for the current Batch object
Method PutBatchTrailer(pIOStream As %IO.DeviceStream) As %Status
{
	Quit $$$OK
}

/// Write out the batch header, all the records in the batch, and then the batch trailer
Method OutputWholeBatch(pIOStream As %IO.DeviceStream, pRecordMap As %String, pUnSwizzleRecords As %Boolean = 1) As %Status
{
	Try {
		Set tStatus = $$$OK
		
		Set tRecordMap = $$$NormalizeClassname($get(pRecordMap))
		If '##class(%Dictionary.CompiledClass).%ExistsId(tRecordMap) || '##class(EnsLib.RecordMap.Model.Record).Exists(tRecordMap) {
			Set tStatus = $$$ERROR($$$EnsRecordMapErrInvalidClass, tRecordMap, "EnsLib.RecordMap.RecordMap")
			Quit
		}
		
		Set tStatus = ..PutBatchHeader(pIOStream)
		If $$$ISERR(tStatus) Quit
		
		Set tKey = ""
		For {
			Set tRecord = ..Records.GetNext(.tKey)
			Quit:(tKey = "")
			Set tStatus = $classmethod(tRecordMap, "PutObject", pIOStream, tRecord, 0,.tPadArray)
			If $$$ISERR(tStatus) Quit
			If pUnSwizzleRecords {
				Set tStatus = ..Records.%UnSwizzleAt(tKey)
				If $$$ISERR(tStatus) Quit
			}
		}
		If $$$ISERR(tStatus) Quit
		
		Set tStatus = ..PutBatchTrailer(pIOStream)
		If $$$ISERR(tStatus) Quit
		Do pIOStream.Flush(.tStatus)
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

ClassMethod deleteRecords(batchid As %String) As %Status [ CodeMode = objectgenerator, Internal, Private, ServerOnly = 1 ]
{
	If %class.Abstract {
		Do %code.WriteLine($c(9)_"Quit $$$OK")
		Quit $$$OK
	}
	Set tRecordProp = "",tRecordPropKey = %class.Properties.FindObjectId(%class.Name_"||Records")
	If (tRecordPropKey'="") Set tRecordProp = %class.Properties.GetAt(tRecordPropKey)
	If ('$IsObject(tRecordProp)) || ('tRecordProp.Relationship) {
		Do %code.WriteLine($c(9)_"Quit $$$OK")
		Quit $$$OK
	}
	Set tRecordType = tRecordProp.Type
	Set tRecordPackage = $piece(tRecordType,".",1,$length(tRecordType,".")-1)
	Set tRecordSchema = $system.SQL.GetSchemaFromPackage(tRecordPackage)
	Set tRecordTableName = $$$comClassKeyGet(tRecordType,$$$cCLASSsqltablename)
	If tRecordTableName = "" Set tRecordTableName = $piece(tRecordType,".",$length(tRecordType,"."))
	Set tRecordTable = tRecordSchema _ "." _ tRecordTableName
	Do %code.WriteLine($c(9)_"Set tStmt = ##class(%SQL.Statement).%New()")
	Do %code.WriteLine($c(9)_"Set tStatus = tStmt.%Prepare(""SELECT %ID As ID FROM "_tRecordTable_" WHERE %ParentBatch = ?"")")
	Do %code.WriteLine($c(9)_"If $$$ISERR(tStatus) Quit tStatus")
	Do %code.WriteLine($c(9)_"Set tRS = tStmt.%Execute(batchid)")
	Do %code.WriteLine($c(9)_"While tRS.%Next() {")
	Do %code.WriteLine($c(9,9)_"Set tStatus = ##class("_tRecordType_").%DeleteId(tRS.ID)")
	Do %code.WriteLine($c(9,9)_"If $$$ISERR(tStatus) Quit")
	Do %code.WriteLine($c(9)_"}")
	Do %code.WriteLine($c(9)_"If $$$ISERR(tStatus) Quit tStatus")
	Do %code.WriteLine($c(9)_"If tRS.%SQLCODE && (tRS.%SQLCODE '= 100) Quit $$$ERROR($$$SQLCode, tRS.%SQLCODE, tRS.%Message)")
	Do %code.WriteLine($c(9)_"Quit $$$OK")
	Quit $$$OK
}

/// Call the generated <method>deleteRecords</method>() method to delete any records linked to the batch.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tID = $$$oidPrimary(oid)
	Quit ..deleteRecords(tID)
}

/// Ensure that unsaved records get assigned IDs sequentially.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	Set tStatus = $$$OK
	Try {
		Set tKey = ""
		For {
			Set tOID = ..Records.GetObjectNext(.tKey)
			If (tKey = "") Quit
			If (tOID = $$$NULLOID) {
				Set tOref = ..Records.GetAt(tKey)
				If $IsObject(tOref) && (tOref.%ForceId() '= "") {
					Set tStatus = tOref.%AddToSaveSet(depth,1)
					If $$$ISERR(tStatus) Quit
				}
			}
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

}
