/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts X12 Documents and forwards them to a remote IP address, reading a response X12 Document message object returned from the remote IP address if the GetReply setting is enabled.
Class EnsLib.EDI.X12.Operation.TCPOperation Extends EnsLib.EDI.X12.Operation.ReplyStandard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.EDI.X12.Adapter.TCPOutboundAdapter";

Method OnInit() As %Status
{
	Set tSC=##super()
	Set:$$$ISOK(tSC) ..%Parser.StartTimeout=..Adapter.ResponseTimeout, ..%Parser.ReadTimeout=..Adapter.ReadTimeout
	Quit tSC
}

Method SendMessage(pMsgOut As EnsLib.EDI.X12.Document, Output pMsgIn As EnsLib.EDI.X12.Document) As %Status [ CodeMode = expression ]
{
..Adapter.X12Message(pMsgOut,.pMsgIn)
}

}
