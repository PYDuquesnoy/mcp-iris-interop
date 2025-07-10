/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts X12 Messages and forwards them to a remote IP address, reading a response X12 Message object returned from the remote IP address if the GetReply setting is enabled.
Class EnsLib.EDI.X12.Operation.SOAPOperation Extends EnsLib.EDI.X12.Operation.ReplyStandard [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Since SOAP requires valid XML characters the default repetition
/// separator is put at ^ rather than Ascii 30 <br>
/// If this property is the empty string then the Separators for the message will be used.<br>
Property Separators As %String(MAXLEN = 10) [ InitialExpression = {$$$X12DefElementSeparator_$$$X12DefComponentSeparator_"^"_$$$X12DefSegTerminator_"\r\n"} ];

Parameter ADAPTER = "EnsLib.SOAP.OutboundAdapter";

Parameter SETTINGS = "-Framing";

/* Override inherited InitialExpression */
Property Framing As %String [ InitialExpression = "AsciiLF" ];

Property LibStreamOut As %Stream.GlobalCharacter [ Internal ];

Property IOStreamOut As %IO.MetaCharacterStream [ Internal ];

Property IOStreamReply As %IO.MetaCharacterStream [ Internal ];

Method OnInit() As %Status
{
	Set tSC=##super()
	Set:$$$ISOK(tSC) ..%Parser.StartTimeout=..Adapter.ResponseTimeout, ..%Parser.ReadTimeout=0
	Set ..LibStreamOut=##class(%Stream.GlobalCharacter).%New()
	Set ..IOStreamOut=##class(%IO.MetaCharacterStream).%New(..LibStreamOut)
	Set ..IOStreamReply=##class(%IO.MetaCharacterStream).%New()
	Set ..IOStreamOut.Name="SOAPRequestStream"
	Quit tSC
}

Method SendMessage(pMsgOut As EnsLib.EDI.X12.Document, Output pMsgIn As EnsLib.EDI.X12.Document, pExpectedSequenceNumber As %String) As %Status
{
	Set:""=..Adapter.WebServiceClientClass ..Adapter.WebServiceClientClass = "EnsLib.EDI.X12.Util.SOAPClient"
	Set tSourceId=$Piece(pMsgOut.Source,$C(13))
	#; We pass in BO set separators. If blank will use pMsgOut Separators
	Set tSC=pMsgOut.OutputToIOStream(..IOStreamOut,..Separators)  Quit:$$$ISERR(tSC) tSC
	Set tSC = ..Adapter.InvokeMethod("Send",.tReply, ..LibStreamOut)
	Do ..LibStreamOut.Clear(), ..IOStreamOut.Rewind(.tSC1)  Quit:$$$ISERR(tSC1) $$$ADDSC(tSC,tSC1)
	Quit:$$$ISERR(tSC) tSC
	If $IsObject(tReply) {
		#; Parse the X12 ACK object out of the reply stream
		Do tReply.Rewind()
		Do ..IOStreamReply.BindInput(tReply, .tSC)  Quit:$$$ISERR(tSC) tSC
		Set tSC = ..IOStreamReply.BindOutput(tReply)  Quit:$$$ISERR(tSC) tSC
		Set ..IOStreamReply.Name=..%ConfigName_"_ReplyStream"
		Set pMsgIn=pMsgOut.ImportFromLibraryStream(..IOStreamReply,.tSC,"class||EnsLib.EDI.X12.Service.SOAPService")  Quit:$$$ISERR(tSC) tSC
		Do ..IOStreamReply.Reset(,,.tSC)
	}
	Quit tSC
}

}
