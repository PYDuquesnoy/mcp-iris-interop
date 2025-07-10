/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.Service.TCPService Extends EnsLib.EDI.X12.Service.Standard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.EDI.X12.Adapter.TCPInboundAdapter";

/* override inital value from superclass */
/// How to treat received Message batches:
/// - Whole Batch = don't process child Message documents individually; accumulate and send the whole batch as one composite document
/// - Single-Session Batch = forward each message in the batch as part of a single session, followed objects representing the batch headers / trailers
/// - Multi-Session Batch = forward each message in the batch in its own session, including objects representing the batch headers / trailers
/// - Individual = forward each child message in the batch in its own session; do not forward objects representing the batch headers / trailers
Property BatchHandling As %String(DISPLAYLIST = ",Whole Batch,Single-Session Batch,Multi-Session Batch,Individual,", VALUELIST = ",Whole,1Session,Batch,Indiv") [ InitialExpression = "Whole", Required ];

Method OnInit() As %Status
{
	Set tSC=##super()  Quit:$$$ISERR(tSC) tSC
	Set ..%Parser.StartTimeout=..Adapter.CallInterval, ..%Parser.ReadTimeout=..Adapter.ReadTimeout
	Quit $$$OK
}

Method OnProcessInput(pLine As Ens.StringContainer, Output pLineLeftOver As Ens.StringContainer) As %Status
{
 	Set pLineLeftOver=""
	Do ..%Parser.ResetPosition()
	Set ..%Parser.%LookaheadLineIsNew=$LI(pLine,1), ..%Parser.%LookaheadLine=$LI(pLine,2)
	Set tSC=..%Parser.ParseFramedIOStream(..Adapter.Socket,,1,..IOLogEntry,..DefRepSep,..DefCompSep,..DefSegTerm)
	Set:""'=..%Parser.%LookaheadLine pLineLeftOver=$LB(0,..%Parser.%LookaheadLine)
	Quit tSC
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document = {$$$NULLOREF}) As %Status
{
	Quit:'..Adapter.Connected $$$OK
 	Set tSC=..OutputFramedToIOStream(..Adapter.Socket,pReplyDocument,,1,..IOLogEntry)
	If $$$ISERR(tSC) {
		If ..Adapter.IsWriteError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"X12 Write", ..Adapter.Device, $$$StatusDisplayString(tSC))
			Do ..Adapter.Disconnect()
		}
		$$$SAVEIOLOGENTRY(tSC,"after TCP WriteX12 error on "_..Adapter.IOAddr,pReplyDocument)
	} Else {
		$$$SAVEIOLOGENTRY(tSC,"after TCP WriteX12 on "_..Adapter.IOAddr,pReplyDocument)
	}
	Quit tSC
}

}
