/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Adapter that handles inbound service requests by acting as a TCP listener for an XTE server.
Class EnsLib.TCP.CountedXMLInboundAdapter Extends (EnsLib.TCP.InboundAdapter, EnsLib.TCP.CountedCommon, Ens.Util.XML.Reader) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Names of classes (comma-separated) this adapter will instantiate from XML blocks received.
Property AcceptClassnames As %VarString;

Parameter SETTINGS = "AcceptClassnames,-UseFileStream";

/* default configuration is UTF-8 (override Setting inherited from base class) */
/// Text Charset to use to decode incoming XML and encode outgoing XML
Property Charset As %String [ InitialExpression = "UTF-8" ];

Method OnConnected() As %Status
{
	Do {
	 	Set tStream=##class(%Library.GlobalCharacterStream).%New("")  $$$ASSERT($IsObject(tStream))
		Set tSC=..ReadCountedStream(tStream, ..Charset, ..CallInterval, ..ReadTimeout, 1)
		If tStream.Size $$$sysTRACE("Got Inbound Request Data (size="_tStream.Size_" from port "_..Port_", Status "_$$$StatusDisplayString(tSC)_" : "_tStream.Read(1000))  Do tStream.Rewind()
		If $$$ISERR(tSC) {
			If ..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"TCP Counted XML Read",..IOAddr,$$$StatusDisplayString(tSC))
				Do ..Disconnect()
				If 'tStream.Size Set tTxt=$$$StatusText(tSC), tSC=$$$OK  If ..StayConnected<0 { $$$LOGWARNING(tTxt) } ElseIf ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } ; change error to info if lost connection with no data and trying to stay connected
			} ElseIf $$$StatusEquals(tSC,$$$EnsErrTCPReadBlockSizeTimeoutExpired) {
				If 'tStream.Size { Set tSC=$$$OK } ; no error if timed out with no data
			}
			Quit
		}
		Set tIOAddr=$S(""=..%outIPAddr:"port:",1:"!"_..%outIPAddr_":")_..Port
		$$$ANEWINIOLOGENTRY($$$OK,"TCP Read XML CountedStream on :"_tIOAddr,tStream)
		Set tSC=..ObjectFromStream(.tObject,tStream,..AcceptClassnames)
		If $$$ISERR(tSC) {
			$$$ACLOSEIOLOGENTRY(tSC,"after ObjectFromStream error on :"_tIOAddr,$$$NULLOREF)
			Quit
		}
		Set tSC=..BusinessHost.ProcessInput(tObject, .tObjectOut)
		If $$$ISERR(tSC) {
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP XML Counted ProcessInput error on :"_tIOAddr,$$$NULLOREF)
			Quit
		}
		If $$$IsdefObject(tObjectOut) {
			Do tStream.Clear()
			$$$sysTRACE("Got Output Object "_tObjectOut)
			$$$ASSERT(tObjectOut.%Extends("%XML.Adaptor"))
			Set tSC=tObjectOut.XMLExportToStream(tStream,"",",indent")
			If $$$ISERR(tSC) {
				$$$ACLOSEIOLOGENTRY(tSC,"after TCP XMLExportToStream error on :"_tIOAddr,$$$NULLOREF)
				Quit
			}
			$$$sysTRACE("Got Output XML Stream of size "_tStream.Size)
		
			Set tSC=..WriteCountedStream(tStream,..Charset,1)
			If $$$ISERR(tSC) {
				If ..IsWriteError(tSC) {
					Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"TCP Counted XML Write",..IOAddr,$$$StatusDisplayString(tSC))
					Do ..Disconnect()
				}
				$$$ACLOSEIOLOGENTRY(tSC,"after TCP WriteCountedStream error on :"_tIOAddr,tStream)
				Quit
			}
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP WriteCountedStream on :"_tIOAddr,tStream)
		} Else {
			$$$ACLOSEIOLOGENTRY(tSC,"after TCP ProcessInput on :"_tIOAddr,$$$NULLOREF)
		}
	} While 0
	#; Returning error status will cause this listener job to terminate
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Quit $$$OK
}

}
