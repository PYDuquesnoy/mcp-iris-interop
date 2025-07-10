/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Operation to send an XML document as a file to a remote FTP server
Class EnsLib.EDI.XML.Operation.FTPOperation Extends EnsLib.EDI.XML.Operation.Standard [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Name of file to output the document(s) to. May include timestamp specifiers. The %f specifier if present will be 
/// replaced with the name of the document's original source stream (stripped of characters illegal in filenames).<p/>
/// See the method Ens.Util.File:CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q", Required ];

Parameter SETTINGS As %String = "Filename:Basic";

Parameter ADAPTER = "EnsLib.FTP.OutboundAdapter";

Property %TempStream As %IO.FileStream [ Internal ];

Method OnInit() As %Status
{
	Set ..%TempStream=..%TempStreamNewObject()
 	Do ..%TempStream.Open("","RWN",,"",.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ##super()
}

Method OnMessage(pRequest As EnsLib.EDI.XML.Document, Output pResponse As EnsLib.EDI.XML.Document) As %Status
{
	Set tSC=..validateAndIndex(pRequest)  Quit:$$$ISERR(tSC) tSC
	
	Do ..%TempStream.Clear()
	Set tSC=pRequest.OutputToIOStream(..%TempStream,$S(""=..Format:"iw",1:..Format))  Quit:$$$ISERR(tSC) tSC

	Set tFilename=..Adapter.CreateTimestamp(##class(%File).GetFilename($P(pRequest.Source,$C(13))),..Filename)
	$$$sysTRACE("About to "_$S(..Adapter.Overwrite:"Store",1:"Append")_" XML document "_pRequest.%Id()_" / "_pRequest_" by FTP at "_..Adapter.fixSvrPath(..Adapter.%LastSetFilePath,1)_tFilename)
	Quit ..Adapter.PutStream(tFilename,..%TempStream)
}

}
