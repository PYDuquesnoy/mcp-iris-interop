/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.Adapter.TCPOutboundAdapter Extends EnsLib.TCP.OutboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/* (override Setting inherited from base class and default value) */
/// If true, wait to read a reply message back from the socket before returning.
Property GetReply As %Boolean [ InitialExpression = 0 ];

/* (override Setting InitialExpression inherited from base class) */
/// Number of seconds to wait on each connection attempt
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/* (override Setting InitialExpression inherited from base class) */
/// Number of seconds to wait for a response to begin arriving back from the remote system after sending a request. Setting the timeout to -1 means wait forever.
Property ResponseTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 30 ];

Method OnInit() As %Status
{
	#; override (empty) superclass initial Terminators value
	Set ..Terminators=..BusinessHost.GetSegmentTerminator()
	Quit ##super()
}

/// Accepts X12 documents and forwards them to a remote IP address, reading a response X12 document object returned from the remote IP address if the GetReply setting property is enabled.
Method X12Message(pMsgOut As EnsLib.EDI.X12.Document, Output pMsgIn As EnsLib.EDI.X12.Document) As %Status
{
	Set pMsgIn=$$$NULLOREF
	Set tSC = ..Connect(..ConnectTimeout)
	If $$$ISERR(tSC) { Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectException) ..BusinessHost.Retry=1  Quit tSC }

	If ..GetReply {
		Set tLine=..BusinessHost.%Parser.%LookaheadLine
		If ""=tLine {
			#; Do a fast check for any data at all before calling the stream parser
			Set $ZT="Trap"
			Read tLine#5:0
			Set $ZT=""
Read
			Set:""'=tLine ..BusinessHost.%Parser.%LookaheadLineIsNew=1, ..BusinessHost.%Parser.%LookaheadLine=tLine
		}
		If ""'=tLine {
			#; clean out any pending acks left over from earlier messages
			Set tLine=""
			Set tStartTimeout=..BusinessHost.%Parser.StartTimeout, ..BusinessHost.%Parser.StartTimeout=0
			For i=1:1 {
				Set tSC=..BusinessHost.%Parser.ParseFramedIOStream(..Socket,.tPreMsgIn,0,..BusinessHost.IOLogEntry)
				If $$$ISERR(tSC) {
					If ..IsReadError(tSC) {
						Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"X12 pre-write Read",..IOAddr,$$$StatusDisplayString(tSC))
						Set ..BusinessHost.Retry=1  Do ..Disconnect()
					} ElseIf $$$StatusEquals(tSC,$$$EnsErrTCPTerminatedReadTimeoutExpired,$$$EnsErrTCPReadTimeoutExpired) {
						Set tSC=$$$OK
					} Else {
						$$$LOGSTATUS(tSC)
					}
					If $$$IsdefObject(tPreMsgIn) $$$LOGWARNING("Discarding data found in buffer before X12 send: "_tPreMsgIn.OutputToString())
					$$$ASAVEIOLOGENTRY(tSC,"after X12 TCP pre-write Read "_i_" error on "_..IOAddr,tPreMsgIn)
					Quit
				} Else {
					If $IsObject(tPreMsgIn) $$$LOGWARNING("Discarding data found in buffer before X12 send: "_tPreMsgIn.OutputToString())
					$$$ASAVEIOLOGENTRY(tSC,"after X12 TCP pre-write Read "_i_" on "_..IOAddr,tPreMsgIn)
				}
			}
			Set ..BusinessHost.%Parser.StartTimeout=tStartTimeout
			Quit:$$$ISERR(tSC)&&..BusinessHost.Retry tSC ; ignore non-disconnect errors : parse errors etc
		}
	}
	Set:..Connected tSC=..BusinessHost.OutputFramedToIOStream(..Socket, pMsgOut,..BusinessHost.Separators,0,..BusinessHost.IOLogEntry)
	If $$$ISERR(tSC) {
		If ..IsWriteError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"X12 Write",..IOAddr,$$$StatusDisplayString(tSC))
			Set ..BusinessHost.Retry=1  Do ..Disconnect()
		} Else {
			If '..StayConnected { Do ..Disconnect() }
			Else { Do ..TestConnection() } ; calls Disconnect() if connection is down
		}
		$$$ASAVEIOLOGENTRY(tSC,"after TCP WriteX12 error on "_..IOAddr,$$$NULLOREF)
		Quit tSC
	}
	$$$ASAVEIOLOGENTRY(tSC,"after TCP WriteX12 on "_..IOAddr,$$$NULLOREF)
	Do ..BusinessHost.%Parser.ResetPosition()
	If ..GetReply {
		Set tSC=..BusinessHost.%Parser.ParseFramedIOStream(..Socket,.pMsgIn,0,..BusinessHost.IOLogEntry)
		If $$$ISERR(tSC) {
			If ..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"X12 Read",..IOAddr,$$$StatusDisplayString(tSC))
				Set ..BusinessHost.Retry=1  Do ..Disconnect()
			} Else {
				Set:$$$StatusEquals(tSC,$$$EnsErrTCPTerminatedReadTimeoutExpired,$$$EnsErrTCPReadTimeoutExpired) ..BusinessHost.Retry=1
				Do ..TestConnection() ; calls Disconnect() if connection is down
			}
			$$$ASAVEIOLOGENTRY(tSC,"after TCP ReadX12 error on "_..IOAddr,pMsgIn)
		} Else {
			$$$ASAVEIOLOGENTRY(tSC,"after TCP ReadX12 on "_..IOAddr,pMsgIn)
		}
	}
	Do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	If ..IsReadError(tSC) {
		Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"X12 pre-write Read",..IOAddr,$$$StatusDisplayString(tSC))
		Set ..BusinessHost.Retry=1  Do ..Disconnect()
	}
	Set tLine=$G(tLine)
	Goto Read
}

Method Disconnect()
{
	Do:..Connected ..BusinessHost.%Parser.Reset()
	Do ##super()
}

}
