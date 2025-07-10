/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.Operation.FTPOperation Extends EnsLib.EDI.X12.Operation.BatchStandard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.OutboundAdapter";

Property %TempStream As %IO.FileStream [ Internal ];

Method OnInit() As %Status
{
	Set ..%TempStream=..%TempStreamNewObject()
 	Do ..%TempStream.Open("","RWN",,"",.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ##super()
}

Method outputDocument(pFilename As %String, pDocument As EnsLib.EDI.X12.Document, pSeparators As %String, pDoFraming As %Integer) As %Status
{
	Do ..%TempStream.Clear()
	Set tSC=..OutputFramedToIOStream(..%TempStream,pDocument,pSeparators,0,..IOLogEntry,.pDoFraming)  Quit:$$$ISERR(tSC) tSC

	$$$sysTRACE("About to "_$S(..Adapter.Overwrite:"Store",1:"Append")_" X12 document "_pDocument.%Id()_" / "_pDocument_" by FTP at "_..Adapter.fixSvrPath(..Adapter.%LastSetFilePath,1)_pFilename)
	Quit ..Adapter.PutStream(pFilename,..%TempStream)
}

Method outputSegment(pFilename As %String, pSegObj As EnsLib.EDI.X12.Segment, pSeparators As %String, pCount As %Integer = 0) As %Status
{
	If ((pCount>0) && $Case(pSegObj.Name,"GE":1,"IEA":1,:0)) {
		Set pSegObj=pSegObj.%ConstructClone()
		Do pSegObj.SetValueAt(pCount,1)
	}
	Do ..%TempStream.Clear()
	Set tSC=pSegObj.OutputToIOStream(..%TempStream,pSeparators)  Quit:$$$ISERR(tSC) tSC
	Quit ..Adapter.PutStream(pFilename,..%TempStream)
}

Method fileExists(pFilename As %String, ByRef pStatus As %Status) As %Boolean
{
	Set pStatus = ..Adapter.NameList(.tFilenames) Quit:$$$ISERR(pStatus) 0
	Quit (tFilenames.Find(pFilename)'="")
}

}
