/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Operation to write RecordMap data out to files on disk.
/// Note that this operation is not designed to run in multiple processes.
Class EnsLib.RecordMap.Operation.FileOperation Extends EnsLib.RecordMap.Operation.Standard [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

/// Name of file to output the document(s) to. May include timestamp specifiers.
/// If present, the %f specifier will be replaced with the name of the document's 
/// original source stream (stripped of characters illegal in filenames).<br/>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%Q", Required ];

Parameter SETTINGS As %String = "Filename:Basic";

Method OnMessage(pObject As %Persistent, pResponse As Ens.Response) As %Status
{
	Try {
		Set tStatus = $$$OK

		Set tFilename = ..Adapter.CreateFilename(##class(%File).GetFilename(pObject.%Source), ..Filename)
		Lock +$$$EnsStaticAppData(..%ConfigName, "File", tFilename)
		Set tLocked = 1
		Set tStream = ##class(%Stream.TmpCharacter).%New()
		Set tIOStream = ##class(%IO.MetaCharacterStream).%New(tStream)

		Set tStatus = ..PutObject(tIOStream, pObject)
		If $$$ISERR(tStatus) Quit

		Set tStatus = tStream.Rewind()
		If $$$ISERR(tStatus) Quit

		Set tStatus = ..Adapter.PutStream(tFilename, tStream)
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tLocked) {
		Lock -$$$EnsStaticAppData(..%ConfigName, "File", tFilename)
	}
	Quit tStatus
}

}
