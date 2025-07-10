/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.EDIFACT.Operation.FileOperation Extends EnsLib.EDI.EDIFACT.Operation.BatchStandard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

/* override default value */
/// Name of file to output the document(s) to. May include timestamp specifiers. The %f specifier if present will be 
/// replaced with the name of the document's original source stream (stripped of characters illegal in filenames).<p/>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q%!+(_a)", Required ];

Method outputDocument(pFilename As %String, pDocument As EnsLib.EDI.EDIFACT.Document, pSeparators As %String) As %Status
{
	#; No Attachments - write it out directly
	Quit:'pDocument.Attachments.Next() ..Adapter.PutStream(pFilename,pDocument,pSeparators)

	#; Has attachments - must go out as MIME
	Set tStream=##class(%FileCharacterStream).%New()
	Set tSC=pDocument.OutputToLibraryStream(tStream,pSeparators)
	Set tEDIFACTPart=##class(%Net.MIMEPart).%New(tStream)
	Set tMIME=##class(%Net.MIMEPart).%New()
	Set tSC=tMIME.Parts.Insert(tEDIFACTPart) Quit:$$$ISERR(tSC) tSC

	Set k=""  For { Set tAttachment=pDocument.Attachments.GetNext(.k)  Quit:""=k
		Set tAttachmentPart=##class(%Net.MIMEPart).%New(tAttachment.Stream)
		Set tAttachmentPart.ContentType=tAttachmentPart.ContentType_"; filename="""_##class(%File).GetFilename(tAttachment.Filename)_""""
		Set tSC=tMIME.Parts.Insert(tAttachmentPart) Quit:$$$ISERR(tSC)
	}
	Quit:$$$ISERR(tSC) tSC
	
	$$$TRACE("Writing interchange "_pDocument_"/"_pDocument.%Id()_" as MIME to file "_pFilename)
	Quit ..Adapter.PutMIME(pFilename,tMIME,0)
}

Method outputSegment(pFilename As %String, pSegObj As EnsLib.EDI.EDIFACT.Segment, pSeparators As %String, pCount As %Integer) As %Status
{
	//If $Case(pSegObj.Name,"GE":1,"IEA":1,:0) Set pSegObj=pSegObj.%ConstructClone()  Do pSegObj.SetValueAt(pCount,1)
	Quit ..Adapter.PutStream(pFilename,pSegObj,pSeparators)
}

}
