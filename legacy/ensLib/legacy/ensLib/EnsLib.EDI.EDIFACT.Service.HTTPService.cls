/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.EDIFACT.Service.HTTPService Extends EnsLib.EDI.EDIFACT.Service.Standard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.HTTP.InboundAdapter";

Property ReplyStream As %GlobalCharacterStream;

Property ReplyIOStream As %IO.MetaCharacterStream;

/// End-Segment marker character(s)
Property SegTerminator As %String [ InitialExpression = {$C(13,10)} ];

Method OnInit() As %Status
{
	Set tSC=##super()  Quit:$$$ISERR(tSC) tSC
	Set ..ReplyStream=##class(%GlobalCharacterStream).%New()
	Set ..ReplyStream.Attributes("Content-Type")="text/edifact"
	Set ..ReplyIOStream=##class(%IO.MetaCharacterStream).%New(..ReplyStream)
	Set ..ReplyIOStream.Name="HTTP Response"
	Quit $$$OK
}

Method OnProcessInput(pStreamIn As %CharacterStream, Output pStreamOut As %CharacterStream) As %Status
{
	Do ..%Parser.Reset()
	Set tSC=..%Parser.ParseFramedIOStream(##class(%IO.StringStream).%New(pStreamIn.Read()),,1) Quit:$$$ISERR(tSC) tSC
	Do ..ReplyIOStream.Flush()
	Set pStreamOut=..ReplyStream
	Set t4=..ReplyStream.Read(4)
	If $Case($E(t4,4)," ":1,"":1,:0)&&(+t4=$E(t4,1,3)) {
		Set tResponse=t4_..ReplyStream.Read()
		Set:tResponse=t4 tResponse=$Case(+t4, $C($$$SingleByteAcceptAscii):"200 OK", $C($$$SingleByteErrorAscii):"500 ServerError", :tResponse)
		Do ..ReplyStream.Clear()  Set ..ReplyStream.Attributes("ResponseCode")=tResponse
	} Else { Do ..ReplyStream.Rewind() }
	Quit tSC
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document = {$$$NULLOREF}) As %Status
{
	Quit:'$IsObject(pReplyDocument) ..ReplyStream.Write(pReplyDocument)
	Set pReplyDocument.IsMutable=0
	Quit:"ACK_HTTP"=$E(pReplyDocument.Name,1,$L("ACK_HTTP")) ..ReplyStream.Write($P(pReplyDocument.Name,"_",3))

	Do ..ReplyIOStream.Clear()
 	Set tSC=pReplyDocument.OutputToIOStream(..ReplyIOStream)
	If $$$ISERR(tSC) {
		$$$SAVEIOLOGENTRY(tSC,"after HTTP WriteEDIFACT error on "_..Adapter.IOAddr,pReplyDocument)
	} Else {
		$$$SAVEIOLOGENTRY(tSC,"after HTTP WriteEDIFACT on "_..Adapter.IOAddr,pReplyDocument)
	}
	Quit tSC
}

}
