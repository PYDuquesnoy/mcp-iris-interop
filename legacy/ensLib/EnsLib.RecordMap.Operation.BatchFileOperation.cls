/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Operation to write RecordMap batch data out to files on disk.
/// Note that this operation uses a temporary file while writing individual records to the batch,
/// and writes the contents of the temporary file to disk when the batch output is complete.
Class EnsLib.RecordMap.Operation.BatchFileOperation Extends EnsLib.RecordMap.Operation.BatchStandard [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

/// Name of file to output the document(s) to. May include timestamp specifiers. 
/// If present, the %f specifier will be replaced with the name of the document's 
/// original source stream (stripped of characters illegal in filenames).<br/>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%Q", Required ];

Parameter SETTINGS As %String = "Filename:Basic";

/// Let the adapter take responsibility for writing out the temporary file.
Method ProcessTempFile(pTempFile As %IO.FileStream, pBatch As EnsLib.RecordMap.Batch) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set tFilename = ..Adapter.CreateFilename(##class(%File).GetFilename(pBatch.%Source),..Filename)
		Set tTempStream = ##class(%IO.LibraryStream).%New(pTempFile)

		Set tStatus = ..Adapter.PutStream(tFilename, tTempStream)
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
