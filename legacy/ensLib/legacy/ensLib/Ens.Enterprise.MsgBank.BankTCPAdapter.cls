/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Block-oriented TCP Inbound Adapter used by the MsgBank to receive messages submitted by a MsgBank client node
Class Ens.Enterprise.MsgBank.BankTCPAdapter Extends (EnsLib.TCP.InboundAdapter, EnsLib.TCP.CountedCommon) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "%Stream.Object";

Parameter SERVICEOUTPUTCLASS = "%String";

/* Override InitialExpression for inherited Setting */
Property Charset As %String [ InitialExpression = "@UTF8" ];

Parameter SETTINGS = "-Endian,-Charset";

/* Override InitialExpression for inherited Setting */
/// TCP Port to connect to
Property Port As Ens.DataType.TCPAgentPort [ InitialExpression = 9192, Required ];

Method OnConnected() As %Status
{
	Set tQuitErr=1  Do {
		Set tStream=$$$NULLOREF, tSC=..ReadCountedStream(.tStream,"UTF-8",..CallInterval,..ReadTimeout,1)
		If $$$ISERR(tSC) {
			If ..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"TCP Counted Read",..IOAddr,$$$StatusDisplayString(tSC))
				Set tQuitErr=0  Do ..Disconnect()
				If '$IsObject(tStream)||'tStream.Size Set tTxt=$$$StatusText(tSC), tSC=$$$OK  If ..StayConnected<0 { $$$LOGWARNING(tTxt) } ElseIf ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } ; change error to info if lost connection with no data and trying to stay connected
			} ElseIf $$$StatusEquals(tSC,$$$EnsErrTCPReadBlockSizeTimeoutExpired) {
				If '$IsObject(tStream)||'tStream.Size { Set tSC=$$$OK } ; no error if timed out with no data
				Else { Set tQuitErr=0 }
			}
			Quit
		}
		$$$ANEWINIOLOGENTRY($$$OK,"TCP ReadCountedStream on :"_..IOAddr,tStream)
		Set tSC=..BusinessHost.ProcessInput(tStream, .tStringOut)
		If $$$ISERR(tSC) {
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP Counted ProcessInput error on :"_..IOAddr,tStringOut)
			Quit
		}
		If ""'=$G(tStringOut) {
			Set tSC=..WriteCountedString(tStringOut,"UTF-8",1)
			If $$$ISERR(tSC) {
				If ..IsWriteError(tSC) {
					Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"TCP Counted Write",..IOAddr,$$$StatusDisplayString(tSC))
					Set tQuitErr=0  Do ..Disconnect()
				}
				$$$ACLOSEIOLOGENTRY(tSC,"after TCP WriteCountedStream error on :"_..IOAddr,tStreamOut)
				Quit
			}
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP WriteCountedStream on :"_..IOAddr,tStreamOut)
		} Else {
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP ProcessInput on :"_..IOAddr,$$$NULLOREF)
		}
	} While 0
	#; Returning error status would cause this listener job to terminate
	If $$$ISERR(tSC) {
		#; Never quit the listener, but drop the connection on unrecognized error
		If tQuitErr&&..Connected&&..StayConnected { $$$LOGERROR("Disconnecting due to "_$$$StatusDisplayString(tSC)) Set tSC=$$$OK  Do ..Disconnect() }
		If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	}
	Quit $$$OK
}

}
