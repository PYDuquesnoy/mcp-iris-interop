/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.Adapter.TCPInboundAdapter Extends EnsLib.TCP.InboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/* (override Setting InitialExpression inherited from base class) */
/// How many incoming connections should the OS hold open until the Business Service processes them. <p>
/// The default QSize for the X12 TCP inbound adapter is 0, which supports the X12 FIFO strategy where only one connection at a time is expected and subsequent connections ought to be refused immediately. <br>
/// The maximum allowed value is 1000. However, the maximum incoming connections the OS can hold open until the Business Service processes them depends on the TCP implementation. <p>
/// Note: If QSize is 0 a client attempting to connect will be refused connection by the operating system (RST,ACK) if the Business Service is processing a previous incoming connection.<br>
/// This could lead to a scenario where a client is connected to the Business Service but disconnects and attempts
/// to reconnect again in the brief period before the listening socket is re-opened by the Business Service and the client does not retry to connect as a result.
Property QSize As %Integer(MAXVAL = 1000, MINVAL = 0) [ InitialExpression = 0 ];

/* (override Setting InitialExpression inherited from base class) */
/// Spawn a new Job to handle each incoming TCP connection. Allows simultaneous handling of multiple connections. <br/>
/// Note that the performance of this setting can be affected by changing the configured QSize setting of this adapter and by configuring Job Servers as a system configuration option.
Property JobPerConnection As %Boolean [ InitialExpression = 0 ];

/// Local holder for lookahead line for Parser
Property %OutLine As %String;

Method OnInit() As %Status
{
	#; override (empty) superclass initial Terminators value
	Set ..Terminators=..BusinessHost.GetSegmentTerminator()
	Quit ##super()
}

Method OnConnected() As %Status
{
	Set tSC=$$$OK, tQuitErr=1
	Do {
		If ""=..%OutLine {
			$$$catTRACE("connwait","Beginning header read for 5 chars with timeout "_..CallInterval_" on "_..IOAddr)
			Set tTimeout=..CallInterval, tLine=..Socket.Read(5,.tTimeout,.tSC)
			If $$$ISERR(tSC) {
				If ..IsReadError(tSC) {
					Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"X12 Read",..IOAddr,$$$StatusDisplayString(tSC))
					Set tQuitErr=0  Do ..Disconnect()
					If ""=tLine Set tTxt=$$$StatusText(tSC), tSC=$$$OK  If ..StayConnected<0 { $$$LOGWARNING(tTxt) } ElseIf ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } ; change error to info if lost connection with no data
				}
			} ElseIf tTimeout=..CallInterval {
				If ""'=$TR(tLine,$C(9,10,13,32)) { ; only report error if timed out after getting some data
					Set tSC=$$$ERROR($$$EnsErrTCPReadTimeoutExpired,tTimeout,"EndData="_$A($E(..Terminators))_$S(""=$E(..Terminators,2):"",1:","_$A($E(..Terminators,2))),tLine)
					Set tQuitErr=0
				}
			}
			#; No need to check timeout - just see if we got any data
			Quit:""=tLine
			$$$catTRACE("connwait","Got line '"_$TR(tLine,$C(9,10,13),"tlr")_"'")
			Quit:$$$ISERR(tSC)
			Set ..%OutLine=$LB(1,tLine)
		}
		$$$ANEWINIOLOGENTRY($$$OK,"TCP ReadX12 on :"_..IOAddr,"EnsLib.EDI.X12.Document")
		Set tSC=..BusinessHost.ProcessInput(..%OutLine,.tOutLine)
		Set ..%OutLine=tOutLine
		If $$$ISERR(tSC) {
			Set tIsWriteErr=..IsWriteError(tSC)
			If tIsWriteErr||..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrInConnectionLost,$S(tIsWriteErr:"X12 Write",1:"X12 Read"),..IOAddr,$$$StatusDisplayString(tSC))
				Set tQuitErr=0  Do ..Disconnect()
			}
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP ProcessInput error on :"_..IOAddr,$$$NULLOREF)
		} Else {
			If $IsObject(..BusinessHost.IOLogEntry) && ..BusinessHost.IOLogEntry.IsEmpty() { Set ..BusinessHost.IOLogEntry=$$$NULLOREF } ; don't log empty IO if no error
			Else { $$$ACLOSEIOLOGENTRY(tSC,"after TCP ProcessInput on :"_..IOAddr,$$$NULLOREF) }
		}
	} While 0
	If $$$ISERR(tSC) {
		#; Drop the connection on unrecognized error
		If tQuitErr&&..Connected&&..StayConnected {
			$$$LOGERROR("Disconnecting due to "_$$$StatusDisplayString(tSC))
			Do ..Disconnect()
		} Else {
			$$$LOGSTATUS(tSC)
		}
	}
	#; Returning error status would cause this listener job to terminate; never quit the listener
	Quit $$$OK
}

Method Disconnect()
{
	If ""'=..%OutLine $$$LOGWARNING("Discarding leftover input '"_$LG(..%OutLine,2)_"'")
	Set ..%OutLine=""
	Do:..Connected ..BusinessHost.%Parser.Reset()
	Do ##super()
}

}
