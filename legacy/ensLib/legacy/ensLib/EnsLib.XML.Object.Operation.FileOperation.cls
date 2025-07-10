/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.XML.Object.Operation.FileOperation is the file based operation class which writes an XML document
/// based on a persistent object to the specified file.
Class EnsLib.XML.Object.Operation.FileOperation Extends EnsLib.XML.Object.Operation.Standard [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

/// Name of file to output the document(s) to. May include timestamp specifiers. The %f specifier if present will be 
/// replaced with the name of the document's original source stream. (stripped of characters illegal in filenames).<p>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q%!+(_a1).xml", Required ];

Parameter SETTINGS As %String = "Filename:Basic";

Method OnMessage(pRequest As %Persistent, Output pResponse As %Persistent) As %Status
{
	// Create output filename using the class name of the persistent class as the base.
	Set tFilename=..Adapter.CreateFilename($classname(pRequest),..Filename)

	// Charset processing is done by %XML.Writer.  Disable Charset property of the Adapter.
	Set tCharset=..Adapter.Charset
	Set ..Adapter.Charset=""

	// Output XML document to stream
	Set tSC=..standardOnMessage(pRequest,.tStream)
	
	// Use the adapter to output the stream
	If $$$ISOK(tSC) {
		Set tSC=..Adapter.PutStream(tFilename,tStream)
	}
	
	// Restore the adapter Charset
	Set ..Adapter.Charset=tCharset

	$$$sysTRACE("After "_$S(..Adapter.Overwrite:"storing",1:"appending")_" XML document "_pRequest_"/"_pRequest.%Id()_" to file "_tFilename)
	Quit tSC
}

}
