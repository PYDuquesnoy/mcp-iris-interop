/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.FTP.PassthroughOperation Extends Ens.BusinessOperation [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.OutboundAdapter";

/// Name of file to output the document(s) to. May include timestamp specifiers. The %f specifier if present will be 
/// replaced with the name of the document's original source filename (stripped of characters illegal in target filenames).<p>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q", Required ];

/// Name of a temporary file to output the document(s) to. Upon completion of the upload the file with this name
/// to the FTP server it is renamed to the name specified in the Filename setting. If this setting is blank no temporary file will be used.<p/>
/// May include timestamp specifiers. The %f specifier if present will be 
/// replaced with the name of the document's original source filename (stripped of characters illegal in target filenames).<p/>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property TempFilename As %String(MAXLEN = 1000);

Parameter SETTINGS As %String = "Filename:Basic,TempFilename";

Method OnMessage(pRequest As Ens.StreamContainer, Output pResponse As %Persistent) As %Status
{
	Quit:'$IsObject(pRequest.Stream) $$$ERROR($$$EnsErrGeneral,"No Stream contained in StreamContainer Request")
	Set tNameIn=##class(%File).GetFilename(pRequest.OriginalFilename)
	Set (tFilename,tFinalFilename)=..Adapter.CreateTimestamp(tNameIn,..Filename)
	If ""'=..TempFilename {
		Set tFilename=..Adapter.CreateTimestamp(tNameIn,..TempFilename)
	}
	Set tSC=..Adapter.PutStream(tFilename, pRequest.Stream)
	If tFinalFilename'=tFilename&&$$$ISOK(tSC) Set tSC=..Adapter.Rename(tFilename, tFinalFilename)
	Quit tSC
}

}
