/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.TCP.CountedInboundAdapter Extends (EnsLib.TCP.InboundAdapter, EnsLib.TCP.CountedCommon) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "%Stream.Object";

Parameter SERVICEOUTPUTCLASS = "%Stream.Object";

Parameter SETTINGS = "UseFileStream";

Method OnConnected() As %Status
{
	Set tQuitErr=1  Do {
		Set tCharset=..Charset  Set:$Case($ZCVT(..Charset,"L"),"default":1,"auto":1,:0) tCharset="UTF-8"
		Set tStream=$$$NULLOREF, tSC=..ReadCountedStream(.tStream,tCharset,..CallInterval,..ReadTimeout,1)
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
		Set tSC=..BusinessHost.ProcessInput(tStream, .tStreamOut)
		If $$$ISERR(tSC) {
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP Counted ProcessInput error on :"_..IOAddr,tStreamOut)
			Quit
		}
		If $$$IsdefObject(tStreamOut) {
			$$$ASSERT(tStreamOut.%Extends("%Stream.Object")||tStreamOut.%Extends("%IO.I.Stream"))
			Set tSC=..WriteCountedStream(tStreamOut,tCharset,1)
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
