/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.TCP.TextLineInboundAdapter Extends (EnsLib.TCP.InboundAdapter, EnsLib.TCP.TextLineCommon) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "Ens.StringContainer";

Parameter SERVICEOUTPUTCLASS = "Ens.StringContainer";

/* override (empty) superclass initial Terminators value */
Property Terminators As %String [ InitialExpression = {$C(10)} ];

Method OnConnected() As %Status
{
	Set tQuitErr=1  Do {
		Set tSC=..ReadLine(.tInStr,..CallInterval,1)
		If $$$ISERR(tSC) {
			If ..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"TCP Read Line",..IOAddr,$$$StatusDisplayString(tSC))
				Set tQuitErr=0  Do ..Disconnect()
				If ""=tInStr Set tTxt=$$$StatusText(tSC), tSC=$$$OK  If ..StayConnected<0 { $$$LOGWARNING(tTxt) } ElseIf ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } ; change error to info if lost connection with no data and trying to stay connected
			} ElseIf $$$StatusEquals(tSC,$$$EnsErrTCPTerminatedReadTimeoutExpired) {
				If ""=tInStr { Set tSC=$$$OK } ; no error if timed out with no data
				Else { Set tQuitErr=0 }
			}
			Quit
		}
		$$$ANEWINIOLOGENTRY($$$OK,"TCP ReadLine on :"_..IOAddr,tInStr)
		Set tSC=..BusinessHost.ProcessInput(##class(Ens.StringContainer).%New(tInStr), .tStringOut)  Quit:$$$ISERR(tSC)
		If $D(tStringOut) {
			If $IsObject(tStringOut) {
				$$$ASSERT(tStringOut.%Extends("Ens.StringContainer"))
				Set tStringOut=tStringOut.StringValue
			}
		} Else { Set tStringOut="" }
		If $$$ISERR(tSC) {
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP TextLine ProcessInput error on :"_..IOAddr,tStringOut)
			Quit
		}
		If ""'=tStringOut {
			#;$$$sysTRACE("Returning Output String '"_tStringOut_"'")
			Set tSC=..WriteLine(tStringOut,1)
			If $$$ISERR(tSC) {
				If ..IsWriteError(tSC) {
					Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"TCP Write Line",..IOAddr,$$$StatusDisplayString(tSC))
					Set tQuitErr=0  Do ..Disconnect()
				}
				$$$ACLOSEIOLOGENTRY(tSC,"after TCP WriteLine error on :"_..IOAddr,tStringOut)
				Quit
			}
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP WriteLine on :"_..IOAddr,tStringOut)
		} Else {
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP ProcessInput on :"_..IOAddr,"")
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
