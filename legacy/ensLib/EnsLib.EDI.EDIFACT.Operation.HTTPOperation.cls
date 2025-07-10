/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.EDIFACT.Operation.HTTPOperation Extends EnsLib.EDI.EDIFACT.Operation.ReplyStandard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.HTTP.OutboundAdapter";

Method OnInit() As %Status
{
	Set tSC=##super()
	Set:$$$ISOK(tSC) ..%Parser.StartTimeout=..Adapter.ResponseTimeout
	Set ..Adapter.SkipBodyAttrs=""
	Quit tSC
}

Method SendMessage(pDocOut As EnsLib.EDI.EDIFACT.Document, Output pDocIn As EnsLib.EDI.EDIFACT.Document) As %Status
{
	Set pDocIn=$$$NULLOREF, tHttpRequest=##class(%Net.HttpRequest).%New(), tHttpRequest.WriteRawMode=1
	Set tSC=pDocOut.OutputToLibraryStream(tHttpRequest.EntityBody,..Separators)  Quit:$$$ISERR(tSC) tSC
	Set tHttpRequest.ResponseStream=##class(%IO.StringStream).%New()
	Set tSC=..Adapter.SendFormDataArray(.tHttpResponse, "Post", tHttpRequest)  Quit:$$$ISERR(tSC) tSC
	Set tSC=..%Parser.ParseFramedIOStream(tHttpResponse.Data,.pDocIn,0,..IOLogEntry)  Quit:$$$ISERR(tSC) tSC
	
	#; If no body response message, construct an ACK message from the HTTP Status Code
	If '$IsObject(pDocIn) {
		Set pDocIn=pDocOut.NewReplyDocument(,"@:@:@:@",.pSC)
		Set pDocIn.Envelope="ACK_HTTP_"_$P(tHttpResponse.StatusLine," ",2)_":"_tHttpResponse.StatusLine
		Set tCode="A"_$S(tHttpResponse.StatusLine[200:"A",1:"E")
		#; Create a message object to represent the HTTP ACK ; set 00 control id, 2.1 version
		Do pDocIn.SetValueAt($TR($P(pDocIn.Envelope,":"),"_",pDocIn.CS),"1:9")
		Do pDocIn.SetValueAt("00","1:10")
		Do pDocIn.SetValueAt(2.1,"1:12")
		Set tAckMSA=##class(EnsLib.EDI.EDIFACT.Segment).%New()
		Do tHttpResponse.Data.Rewind()
		Set tDesc="HTTP "_$S("AA"=tCode:"",1:"(N)")_"ACK '"_tHttpResponse.StatusLine_"'"_$S('tHttpResponse.Data.Size:"",1:" : "_tHttpResponse.Data.Read(1000))
		Do tAckMSA.SetValueAt("MSA"_pDocIn.FS_tCode_pDocIn.FS_"00"_pDocIn.FS_tDesc)
		Do pDocIn.AppendSegment(tAckMSA)
	}
	Quit tSC
}

}
