/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Block-oriented TCP Outbound Adapter used by MsgBank clients to submit messages to the MsgBank
Class Ens.Enterprise.MsgBank.ClientTCPAdapter Extends (EnsLib.TCP.OutboundAdapter, EnsLib.TCP.CountedCommon) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/* Override InitialExpression for inherited Setting */
Property Charset As %String [ InitialExpression = "@UTF8" ];

Parameter SETTINGS = "-Endian,-Charset,-GetReply";

/* Override InitialExpressions for inherited Setting */
/// TCP Port to connect to.
Property Port As %Integer(MAXVAL = 65535, MINVAL = 0) [ InitialExpression = 9192, Required ];

/// Number of seconds to wait for a response to begin arriving back from the remote system after sending a request. <br>
/// Setting the timeout to -1 means wait forever. <br>
/// The default is set to 2 minutes to account for possible large transmissions
/// but long archiving times could be a signal of underlying issues.
Property ResponseTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 120 ];

Method SendMessageStream(pRequestStream As %Stream.Object, ByRef pResponseString As %String = "", pHandShake As %Boolean = 0) As %Status
{
	/* We could be here to send a handshake during a reconnect called from Connect via OnConnect so don't want to call Connect again. */
	If ('pHandShake||'..Connected) {
		Set tSC=..Connect(..ConnectTimeout)
		If $$$ISERR(tSC) { Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectException) ..BusinessHost.Retry=1  Quit tSC }
	}

	Set:(..Connected||pHandShake) tSC=..WriteCountedStream(pRequestStream, "@UTF8")
	If $$$ISERR(tSC) {
		If ..IsWriteError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Counted Write",..IOAddr,$$$StatusDisplayString(tSC))
			Set ..BusinessHost.Retry=1  Do ..Disconnect()
		} Else {
			If '..StayConnected { Do ..Disconnect() }
			Else { Do ..TestConnection() } ; calls Disconnect() if connection is down
		}
		Quit tSC
	}
	Set tSC = ..GetReplyString(.pResponseString)
	If $$$ISERR(tSC) && $$$StatusEquals(tSC,$$$EnsErrTCPReadTimeoutExpired,$$$EnsErrTCPReadBlockSizeTimeoutExpired) {
		$$$LOGWARNING($$$FormatText("Check Response Timeout of %1 seconds as failed to get a response after sending payload of size %2 MB. Message Bank server may still be processing leading to repeated data storage.",..ResponseTimeout, (pRequestStream.Size\1024\1024)))
	}
	Quit tSC
}

Method GetReplyString(ByRef pResponseString As %String = "") As %Status
{
	Set tSC=..ReadCountedString(.pResponseString, "@UTF8", ..ResponseTimeout, ..ReadTimeout)
	If $$$ISERR(tSC) {
		If ..IsReadError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Counted Read",..IOAddr,$$$StatusDisplayString(tSC))
			Set ..BusinessHost.Retry=1  Do ..Disconnect()
		} Else {
			If $$$StatusEquals(tSC,$$$EnsErrTCPReadTimeoutExpired,$$$EnsErrTCPReadBlockSizeTimeoutExpired) {
				Set ..BusinessHost.Retry=1
				; We want to close the socket and have it re-opened to avoid retrieving a delayed response later 
				; since the Write did not report an error.
				Do ..Disconnect()
			}
			Do ..TestConnection() ; calls Disconnect() if connection is down
		}
	}
	Do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()
	Quit tSC
}

}
