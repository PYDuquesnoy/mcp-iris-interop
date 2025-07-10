/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Operation to write ComplexBatch data out to files on disk.
/// Note that this operation uses a temporary file while writing out the ComplexBatch,
/// and transmits the temporary file when output is complete.
Class EnsLib.RecordMap.Operation.ComplexBatchFileOperation Extends EnsLib.RecordMap.Operation.ComplexBatchStandard [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

/// Name of file to output the ComplexBatch to. May include timestamp specifiers. 
/// If present, the %f specifier will be replaced with the value of the ComplexBatch object's
/// %Source property stripped of characters illegal in filenames.<br/>
/// See the documentation for the CreateTimestamp() method in <class>Ens.Util.File</class> for more detailed timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%Q", Required ];

Parameter SETTINGS As %String = "Filename:Basic";

/// Let the adapter take responsibility for writing out the temporary file.
Method ProcessTempStream(pTempStream As %IO.FileStream, pBatch As EnsLib.RecordMap.ComplexBatch) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set tFilename = ..Adapter.CreateFilename(##class(%File).GetFilename(pBatch.%Source),..Filename)
		Set tTempStream = ##class(%IO.LibraryStream).%New(pTempStream)

		$$$LOGINFO("Attempting to write to file '"_tFilename_"'; tTempStream.Size = "_tTempStream.Size_"; pTempStream.Size = "_pTempStream.Size)
		Set tStatus = ..Adapter.PutStream(tFilename,tTempStream)
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
/// For this operation, the encoding is a setting of the adapter.
Method GetCharEncoding() As %String
{
	Quit ..Adapter.Charset
}

}
