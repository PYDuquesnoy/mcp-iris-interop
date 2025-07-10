/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.EDIFACT.Operation.FTPOperation Extends EnsLib.EDI.EDIFACT.Operation.BatchStandard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.OutboundAdapter";

Property %TempStream As %IO.FileStream;

Method OnInit() As %Status
{
	Set ..%TempStream=..%TempStreamNewObject()
 	Do ..%TempStream.Open("","RWN",,"",.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ##super()
}

Method outputDocument(pFilename As %String, pDocument As EnsLib.EDI.EDIFACT.Document, pSeparators As %String) As %Status
{
	Do ..%TempStream.Clear()
	Set tSC=pDocument.OutputToIOStream(..%TempStream,pSeparators)  Quit:$$$ISERR(tSC) tSC
	
	$$$sysTRACE("About to "_$S(..Adapter.Overwrite:"Store",1:"Append")_" EDIFACT document "_pDocument.%Id()_" / "_pDocument_" by FTP at "_..Adapter.fixSvrPath(..Adapter.%LastSetFilePath,1)_pFilename)
	Quit ..Adapter.PutStream(pFilename,..%TempStream)
}

Method outputSegment(pFilename As %String, pSegObj As EnsLib.EDI.EDIFACT.Segment, pSeparators As %String, pCount As %Integer) As %Status
{
	If $Case(pSegObj.Name,"GE":1,"IEA":1,:0) Set pSegObj=pSegObj.%ConstructClone()  Do pSegObj.SetValueAt(pCount,1)
	Do ..%TempStream.Clear()
	Set tSC=pSegObj.OutputToIOStream(..%TempStream,pSeparators)  Quit:$$$ISERR(tSC) tSC
	Quit ..Adapter.PutStream(pFilename,..%TempStream)
}

}
