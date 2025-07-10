/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class for writing out RecordMap ComplexBatch objects. The batch will be written to a temporary file, 
/// and the <method>ProcessTempFile</method>() callback will be invoked when complete to allow subclasses to transmit
/// the batch to its destination.
Class EnsLib.RecordMap.Operation.ComplexBatchStandard Extends Ens.BusinessOperation [ Abstract, System = 4 ]
{

Parameter SETTINGS = "ComplexMap:Basic:selector?context={/Classes?super=EnsLib.RecordMap.ComplexMap&hideAbstract=1},OpenMode";

/// Name of the Complex RecordMap which is to be written out.
Property ComplexMap As %String(MAXLEN = 220) [ Required ];

/// Mode to open the temporary file with when creating a new file for a batch.
/// See the documentation for <class>%IO.FileStream</class> and file devices for more information on the available options.
Property OpenMode As %String [ InitialExpression = "RWN" ];

/// Full classname of the Complex RecordMap.
Property complexMapFull As %String(MAXLEN = 220) [ Private, Transient ];

/// Classname of the expected ComplexBatch objects.
Property batchClass As %String(MAXLEN = 220) [ Private, Transient ];

/// Handle incoming ComplexBatch objects.
/// The entire ComplexBatch will be written out at that point in time.
Method OnMessage(pRequest As %Persistent, Output pResponse As %Persistent) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pResponse = $$$NULLOREF
		
		If 'pRequest.%Extends("EnsLib.RecordMap.ComplexBatch") {
			Set tStatus = $$$EnsError($$$EnsErrRequestNotHandled,pRequest)
			Quit
		}
		Set tStatus = ..GetTempStream(.tTempStream)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..PutBatch(pRequest,tTempStream)
		If $$$ISERR(tStatus){
			Do ..deleteTempFileStream(tTempStream)
			Quit
		}
		Set tStatus = ..ProcessTempStream(tTempStream,pRequest)
		Do ..deleteTempFileStream(tTempStream)
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
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

/// Get a temporary file stream for output.
Method GetTempStream(Output pIOStream As %IO.DeviceStream) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set pIOStream = ""
		Set tTempFile = ##class(%IO.FileStream).%New()
		Set tTempFilename = ##class(%IO.FileStream).NewTempFilename(,1)
		Set tCharEncoding = ..GetCharEncoding()
		Do tTempFile.Open(tTempFilename,..OpenMode,,tCharEncoding,.tStatus)
		If $$$ISERR(tStatus) Quit
		Set tTempFile.BuildCharPosMap = 0
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	If $$$ISOK(tStatus) && $IsObject($get(tTempFile)) Set pIOStream = tTempFile
	Quit tStatus
}

/// Handle writing out a ComplexBatch to a supplied stream.
Method PutBatch(pBatch As EnsLib.RecordMap.ComplexBatch, pIOStream As %IO.DeviceStream) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = $classmethod(..complexMapFull,"PutBatch",pIOStream,pBatch)
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Subclass responsibility.
Method ProcessTempStream(pTempStream As %IO.DeviceStream, pBatch As EnsLib.RecordMap.ComplexBatch) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Confirm that the Complex RecordMap exists and confirm that the ComplexBatch class has been generated.
Method OnInit() As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = ..%ValidateObject()
		If $$$ISERR(tStatus) Quit

		If '##class(EnsLib.RecordMap.Model.ComplexBatch).Exists(..ComplexMap) {
			Set tStatus = $$$ERROR($$$ClassDoesNotExist, ..ComplexMap)
			Quit
		}
		
		Set ..complexMapFull = $$$NormalizeClassname(..ComplexMap)
		
		Try {
			Set ..batchClass = $parameter(..complexMapFull,"BATCHCLASS")
		}
		Catch {
			Set ..batchClass = $$$comMemberKeyGet(..complexMapFull,$$$cCLASSparameter,"BATCHCLASS",$$$cPARAMdefault)
		}
		If ..batchClass = "" {
			Set tStatus = $$$ERROR($$$EnsRecordMapErrGeneral,"BATCHCLASS is not specified for Complex RecordMap '"_..ComplexMap_"'")
			Quit
		}
		If '##class(%Dictionary.CompiledClass).%ExistsId(..batchClass) {
			Set tStatus = $$$ERROR($$$ClassDoesNotExist,..batchClass)
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

Method deleteTempFileStream(pTempStream As %IO.DeviceStream) [ Internal, Private ]
{
	Try {
		If ##class(%File).Exists(pTempStream.Name) {
			Do pTempStream.Close()
  			If '##class(%File).Delete(pTempStream.Name) $$$LOGWARNING("Failed to delete temporary file: "_pTempStream.Name)
		}
	} Catch e { 
		$$$LOGWARNING("Error deleting temporary file: "_pTempStream.Name_" "_e.AsSystemError())
	}
}

}
