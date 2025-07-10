/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Base adapter class for Automatic SOAP WebServices
Class EnsLib.SOAP.InboundAdapter Extends EnsLib.TCP.InboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// A specific URL for the Service to accept requests on.
/// For SOAP Services invoked through the SOAP Inbound Adapter on a custom local port, this setting allows a custom URL to be used instead of the standard csp/namespace/classname style of URL.
Property AdapterURL As %String(MAXLEN = 1000);

/// Listen via the CSP WebServer, if any, in addition to listening on the custom local port. <p/>
/// Note that SSLConfig only applies to the custom local port. To use SSL via the CSP WebServer, you must configure the WebServer separately. <p/>
/// Also note that AdapterURL only applies to the custom local port. If the Service is invoked via the CSP WebServer, 
/// the ?CfgItem= URL parameter may be used to distinguish between multiple configured same-class Services but the standard csp/namespace/classname URL must be used.
Property EnableStandardRequests As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS As %String = "EnableStandardRequests:Connection,AdapterURL:Connection";

/* override (empty) superclass initial Port SETTINGS value and description */
/// Local TCP port to listen on for SOAP requests (possibly in addition to listening via the CSP WebServer, if any).
Property Port As Ens.DataType.TCPAgentPort [ InitialExpression = "1980", Required ];

/* override (empty) superclass initial Terminators value */
Property Terminators As %String [ InitialExpression = {$C(10)} ];

/// Set to 1 to enable splitting of the SOAP Body into a separate stream and excluding it from the Envelope and Headers stream.
/// This avoids a full XML parse of the Body and also injects any namespace declarations from the Envelope into the opening Body tag.
/// Set to 2 to do this and call ProcessBody() directly without processing any of the SOAP headers.
Property %SplitBody As %Integer(VALUELIST = ",0,1,2") [ InitialExpression = 0 ];

/// Set this to 0 to prevent normalizing of HTTP header variable names to lowercase
Property %ToLowerHeaderVars As %Boolean [ InitialExpression = 1 ];

/// Override the Device Mode that will be used to open the TCP socket
Parameter Mode As %String = "SW";

Method OnInit() As %Status
{
	If '..BusinessHost.%Extends("%SOAP.WebService") Set tSC = $$$ERROR($$$EnsErrGeneral,"This Adapter must be associated with a BusinessService derived from %SOAP.WebService; terminating listener job") $$$LOGWARNING($$$StatusText(tSC)) Quit tSC
	Quit ##super()
}

Method OnConnected() As %Status
{
	Set tSC=$$$OK,tCST=0,tSOAP12=0,tLen="x"
	Set (tContentType,tAction,tSuperSession)=""
	Do {
		Set $ZT="TrapRS"
		// Read raw lines of header, then suck in whole body into a stream
		Set tStartTime=$zh
		Read tLine:..CallInterval Set tTimedOut='$Test
		Set $ZT="Trap"
		If tTimedOut {
			If $zh-tStartTime < (..CallInterval-0.1) { Set tSC=$$$ERROR($$$EnsErrTCPReadBlockSize,..CallInterval,"line",tLine) }
			Else { Set tSC=$$$ERROR($$$EnsErrTCPReadBlockSizeTimeoutExpired,..CallInterval,"line") }
			Quit
		}
		Set ..BusinessHost.%WaitForNextCallInterval=0 ; got something; no wait before trying for more
		Set:$E(tLine,$L(tLine))=$C(13) $E(tLine,$L(tLine))=""
		Kill %iaHeader
		Set tURL=$P(tLine," ",2)
		Set %iaHeader("URL")=tURL
		Set %iaHeader("HttpRequest")=$P(tLine," "), %iaHeader("HttpRequest",%iaHeader("HttpRequest"),"ERR")=tURL
		$$$sysTRACE("Got SOAP Request '"_%iaHeader("HttpRequest")_" "_tURL_"'")
		If 3'=$L(tLine," ") Set tSC=$$$EnsError($$$EnsErrGeneral,"invalid HTTP header:'"_tLine_"'") Quit
		Set tLine=$P(tLine," ",3,$L(tLine," "))
		If "HTTP"'=$P(tLine,"/") Set tSC=$$$EnsError($$$EnsErrGeneral,"invalid HTTP version'"_tLine_"'") Quit
		Set %iaHeader("HTTPVersion")=$P(tLine,"/",2)
		Set %iaHeader("EnsConfigName")=..BusinessHost.%ConfigName
		While 1 {
			Set tStartTime=$zh
			Read tLine:..ReadTimeout Set tTimedOut='$Test
			If tTimedOut {
				If $zh-tStartTime < ..ReadTimeout { Set tSC = $$$EnsError($$$EnsErrTCPReadBlockSize,..ReadTimeout,"line",tLine) }
				Else { Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,..ReadTimeout,"line","ascii") }
				Quit
			}
			Set:$E(tLine,$L(tLine))=$C(13) $E(tLine,$L(tLine))=""
			Quit:""=tLine
			Set attr=$P(tLine,":"), lwrattr=$ZCVT(attr,"L")
			Set:..%ToLowerHeaderVars attr=lwrattr
			Set:'$D(lwrattrs(lwrattr)) %iaHeader(attr)=$ZStrip($P(tLine,":",2,$L(tLine,":")),"<>W"), lwrattrs(lwrattr)=attr
			Set:"content-length"=lwrattr tLen=%iaHeader(attr)
			Set:"content-type"=lwrattr tContentType=%iaHeader(attr)
			Set:"soapaction"=lwrattr tAction=%iaHeader(attr)
			Set:(($$$EnsHTTPHeaderSuperSessionLC=lwrattr)&&(tSuperSession="")) tSuperSession = %iaHeader(attr)
		}
		Set tSOAP12=tContentType["application/soap+xml"
		Quit:$$$ISERR(tSC)
		If ""=tAction {
			If 'tSOAP12 { Set tSC = $$$ERROR($$$EnsErrGeneral,"No SOAPAction in SOAP Request HTTP header") Quit } ; no Action required in HTTP headers for SOAP 1.2
			Set tAction=$P(tContentType,"action=",2)
			If """"=$E(tAction) { Set tAction=$P(tAction,"""",2) }
			Else { Set tAction=$ZStrip($P(tAction,";"),"<>W") }
		}
		#; now read the body
		If "x"=tLen { Set tLen = $S(("chunked"=$G(%iaHeader("transfer-encoding"))):0,1:1000000000)  If tLen $$$LOGWARNING("Content-Length not found; will read body up to "_tLen_" bytes or "_..ReadTimeout_" seconds") }
		Else { $$$sysTRACE("For action='"_tAction_"' got content-length="_tLen_", waiting to read (raw) with timeout="_..ReadTimeout) }
		If tLen {
			// copy post-header part in, loop writing into stream until done
			Set %iaStream = ##class(%Library.GlobalCharacterStream).%New()  $$$ASSERT($IsObject(%iaStream))
			If ..%SplitBody {
				Set tSC=..readSplitEnvelopeStream(tLen,.tBodyStream,.tBodyLenExtra)  Quit:$$$ISERR(tSC)
				#; set body stream reference as attribute of envelope stream
				Set:$IsObject(tBodyStream) %iaStream.Attributes("BodyStream")=tBodyStream, tBodyStream.Attributes("EnvelopeStream")=%iaStream
			} Else {
				Use ..Device:(::"+":) ; turn off terminators
				Set tSC=%iaStream.InputFromDevice(.tLen,..ReadTimeout), tBodyLenExtra=0, tBodyStream=""
				Use ..Device:(::"+":..Terminators) ; turn on terminators
			}
			$$$sysTRACE("TCP Read body("_(%iaStream.Size+$S($IsObject(tBodyStream):tBodyStream.Size,1:$L(tBodyStream))-tBodyLenExtra)_")")
		} ElseIf "chunked"=$G(%iaHeader("transfer-encoding")) {
			Set %iaStream = ##class(%Library.GlobalCharacterStream).%New()  $$$ASSERT($IsObject(%iaStream))
			Set:..%SplitBody tmpiaStream = ##class(%Library.GlobalCharacterStream).%New()
			For {
				#; Next line is length of chunk in hex
				Set tLen=""  Read tLen:..ReadTimeout  Set tTimedOut='$Test
				If tTimedOut { Set tSC=$$$ERROR($$$EnsErrTCPReadBlockSize,..CallInterval,"chunksize",tLen)  Quit }
				Set tLen=$ZHex(tLen)
				If tLen {
					#; Read next chunk into the stream up to the given length
					Use ..Device:(::"+":) ; turn off terminators 
					If ..%SplitBody {
						Set tSC = tmpiaStream.InputFromDevice(.tLen,..ReadTimeout)
					} Else {
						Set tSC = %iaStream.InputFromDevice(.tLen,..ReadTimeout)
					}
					Set:(tLen=0) tLen = -1
					Use ..Device:(::"+":..Terminators) ; turn terminators back on
					Quit:$$$ISERR(tSC) 
				}
				#; Chunk will have a trailing newline - do an extra read 
				Set tDummy=""  Read tDummy:..ReadTimeout  Set tTimedOut='$Test
				If tTimedOut { Set tSC=$$$ERROR($$$EnsErrTCPReadBlockSize,..CallInterval,"chunkend",tDummy)  Quit }
				Quit:'tLen ; A zero length chunk ends all
			}
			If ..%SplitBody,$IsObject(tmpiaStream) {
				Set tSC=##class(EnsLib.SOAP.GenericService).splitEnvelopeStream(tmpiaStream,.%iaStream,.tBodyStream)  Quit:$$$ISERR(tSC)
				#; set body stream reference as attribute of envelope stream
				Set:$IsObject(tBodyStream) %iaStream.Attributes("BodyStream")=tBodyStream, tBodyStream.Attributes("EnvelopeStream")=%iaStream
				Kill tmpiaStream
			}
			Kill %iaHeader("transfer-encoding")
			Set %iaHeader("content-length")=%iaStream.Size
			$$$sysTRACE("Completed TCP Read of chunked HTTP body("_%iaStream.Size_")")
		} Else {
			Set %iaStream=$$$NULLOREF
		}
	} While 0
	Set tCST=$G(%iaHeader("content-type"))["binary/CST"
	Set (tPreStream,tPostStream,tBodyStreamOut)="", (tBodyLen,tBodyTagLen)=0
	If $$$ISOK(tSC)&&'tTimedOut {
		If ..AdapterURL'="" {
			Set:$ZCVT(tURL,"U")'=$ZCVT(..AdapterURL,"U") tSC = $$$ERROR($$$EnsErrGeneral,"HTTP SOAP request '"_tURL_"' does not match Service's AdapterURL setting '"_..AdapterURL_"'")
		} Else {
			Set ttURL=$ZCVT($ZCVT($P(tURL,"?"),"I","URL"),"U")
			Set ttURL=$S(ttURL="/":"/", "/"=$E(ttURL,*):$E(ttURL,1,*-1), 1:ttURL)
			Set tLastPiece=$S(ttURL="/":"/", 1:$P(ttURL,"/",$L(ttURL,"/")))
			Set tCfgParam=$ZCVT($P($P($ZCVT(tURL,"U"),"?CFGITEM=",2),"&"),"I","URL")
			If (tLastPiece'=($ZCVT($classname(..BusinessHost),"U")_".CLS"))
			 && (tLastPiece'=($ZCVT(..BusinessHost.%ConfigName,"U"))
			   ) || ((""'=tCfgParam) && (tCfgParam'=$ZCVT(..BusinessHost.%ConfigName,"U"))) {
				Set tSC = $$$ERROR($$$EnsErrGeneral,"HTTP SOAP request '"_tURL_"' does not match Service class '"_$classname(..BusinessHost)_".cls"_"' or config item name '"_..BusinessHost.%ConfigName_"'")
			} ElseIf ("CSP"=$P(ttURL,"/",2))&&($ZNspace'=($P(ttURL,"/",3))) {
				Set ttPath=$E(ttURL,1,*-1-$L(tLastPiece))
				Set tApp=$System.CSP.GetDefaultApp($ZNspace), ttApp=$ZCVT(tApp,"U")
				Set:ttPath'=ttApp tSC = $$$ERROR($$$EnsErrGeneral,"HTTP SOAP request '"_tURL_"' does not match namespace "_$ZNspace_" csp application path "_tApp_"'")
			}
		}
		If $$$ISOK(tSC) {
			Set ..BusinessHost.%SuperSession = tSuperSession
			#;Need to ensure that any cleanup of %SuperSession is able to identify early set. NoOP if tSuperSession is ""
			Set ..BusinessHost.%SuperSessionCreatedBeforeSession = 1
			Set tSC=..BusinessHost.OnAuthorize(tAction,%iaStream)
			Do:$IsObject(%iaStream) %iaStream.Rewind()
		}
		Set:$$$ISOK(tSC) ..BusinessHost.SOAPInvoked=1, tSC=..BusinessHost.preProcessInput()
		If $$$ISOK(tSC) {
			If tCST {
				Use ..Device:(::"+":) ; turn off terminators
				Set tSC=##class(EnsLib.SOAP.CST.InBase).Read(.%iaHeader,.tMsgDescriptor,..ReadTimeout)
				Use ..Device:(::"+":..Terminators) ; turn terminators back on
				Set:$$$ISOK(tSC) tSC=tMsgDescriptor.InvokeService(..BusinessHost)
			} Else {
				If ..%SplitBody<=1 {
					Do ..BusinessHost.OnSOAPRequest(tAction,%iaStream,.tStreamOut)
				} Else {
					Set tRequestBody = $S('$IsObject(%iaStream):%iaStream, 1:$G(%iaStream.Attributes("BodyStream"),%iaStream))
					Do ..BusinessHost.ProcessBody(tAction,tRequestBody,.tStreamOut)
				}
				Set tLen=$S($IsObject(tStreamOut):tStreamOut.Size,1:$L(tStreamOut))
			}
			Set:$$$ISOK(tSC) tSC=$G(%objlasterror,$$$OK), tSC=$S(..BusinessHost.%ProcessError=""||(..BusinessHost.%ProcessError=tSC):tSC,1:$$$ADDSC(..BusinessHost.%ProcessError,tSC))
		}
	}
WriteResp
	If ""'=$G(tURL) {
		#; Note: if the Service executed its ReturnFault() method (directly or indirectly) then control will never arrive here
		#; Note: tStreamOut is always an object if the standard OnSOAPRequest() was executed, so we will only construct our own fault if the Service returned an error but neither called ReturnFault() nor Fault() to write fault content to tStreamOut.
		Set:(..%SplitBody>=1&&$$$ISOK(tSC)&&'..BusinessHost.OneWay) tSC=##class(GenericService).prepJoinedResponse(.tStreamOut,.tBodyStreamOut,tSOAP12,.tLen,.tBodyTagLen,.tNewBodyElem,.tPreStream,.tPostStream)
		If $$$ISERR(tSC) {
			If tCST { Set tStreamOut=$$$NULLOREF }
			ElseIf ""=$G(tStreamOut)||($IsObject(tStreamOut)&&'tStreamOut.Size&&$S(tStreamOut.%Extends("%Library.AbstractStream"):'$D(tStreamOut.Attributes),1:1)) {
				Set tStreamOut=$$$NULLOREF, (tPreStream,tPostStream,tBodyStreamOut)=""
				Kill tStreamOut("EnvelopeStream")
				try {
					Set tStreamOut=..BusinessHost.OnErrorStream(tSC,..BusinessHost,$S(tSOAP12:"1.2",1:"1.1"))
				} catch {
					If $ZE'["METHOD DOES NOT EXIST" {
						Set tSC1=$$$SystemError
						Set tSC=$$$ADDSC(tSC,tSC1)
					}
				}
				Set:""=$G(tStreamOut)||($IsObject(tStreamOut)&&'tStreamOut.Size&&$S(tStreamOut.%Extends("%Library.AbstractStream"):'$D(tStreamOut.Attributes),1:1)) tStreamOut=..faultString(tSC,..BusinessHost,$S(tSOAP12:"1.2",1:"1.1"))
				Set tLen=$S($IsObject(tStreamOut):tStreamOut.Size,1:$L(tStreamOut))
			}
		}
		#; Write response header then response body
		Set $ZT="TrapW"
		Set tHeader = ""
		If '..BusinessHost.%Extends("EnsLib.SOAP.GenericService") {
			Set tHeaderExtra = "CACHE-CONTROL: no-cache"_$C(13,10)_
						"PRAGMA: no-cache"_$C(13,10)
		} Else {
			Set tHeaderExtra = ""
			#; Get attributes from the EnvelopeStream if not in tStreamOut
			Try {
				If ('$D(tStreamOut.Attributes)&&(tStreamOut("EnvelopeStream").%Extends("%Library.AbstractStream"))&&'..BusinessHost.OneWay){
					Merge tStreamOut.Attributes("HTTPHeaders")=tStreamOut("EnvelopeStream","HTTPHeaders")
				}
			} Catch {}
		}
		If ..BusinessHost.OneWay&&$$$ISOK(tSC) { Set tLen=0, tCT="", tStatusLine="HTTP/1.1 202 Accepted" }
		ElseIf $D(tStreamOut)#2 {
			If $IsObject(tStreamOut) {
				$$$ASSERT(tStreamOut.%Extends("%Stream.Object"))
				Set tHeaderExtra = ""
				If tStreamOut.%Extends("%Library.AbstractStream") {
					#; get headers from tStreamOut attributes
					Set tCT=$G(tStreamOut.Attributes("HTTPHeaders","CONTENT-TYPE"),$G(tStreamOut.Attributes("HTTPHeaders","Content-Type"),$G(tStreamOut("CONTENT-TYPE"),$G(tStreamOut("Content-Type")))))
					Set tStatusLine=$G(tStreamOut.Attributes("STATUSLINE"),$G(tStreamOut.Attributes("StatusLine"),$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut.Attributes("RESPONSECODE"),$G(tStreamOut.Attributes("ResponseCode"),$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"ZZZ"))))))))
					Set attr="" For { Set attr=$O(tStreamOut.Attributes("HTTPHeaders",attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
						Continue:'$D(val)||$Case(upattr,"CONTENT-TYPE":1, "RESPONSECODE":1, "STATUSLINE":1, "TRANSFER-ENCODING":"CHUNKED"=$ZCVT(val,"U"), "CONTENT-ENCODING":"GZIP"=$ZCVT(val,"U"), :$D(upattrs(upattr)))
						Set attrs(attr)=val, upattrs(upattr)=""
					}
				} Else {
					Set tCT=$G(tStreamOut("HTTPHeaders","CONTENT-TYPE"),$G(tStreamOut("HTTPHeaders","Content-Type"))), tStatusLine=$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"ZZZ"))))
				}
			} Else {
				Set tCT=$G(tStreamOut("HTTPHeaders","CONTENT-TYPE"),$G(tStreamOut("HTTPHeaders","Content-Type"))), tStatusLine=$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"ZZZ"))))
			}
		} Else {
			Set tLen=0, tCT=$G(tStreamOut("HTTPHeaders","CONTENT-TYPE"),$G(tStreamOut("HTTPHeaders","Content-Type"))), tStatusLine=$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"ZZZ"))))
		}
		#; get headers from tStreamOut subscripts too
		Set attr="" For { Set attr=$O(tStreamOut(attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
			Continue:'$D(val)||$Case(upattr,"ENVELOPESTREAM":1, "CONTENT-TYPE":1, "RESPONSECODE":1, "STATUSLINE":1, "TRANSFER-ENCODING":"CHUNKED"=$ZCVT(val,"U"), "CONTENT-ENCODING":"GZIP"=$ZCVT(val,"U"), :$D(upattrs(upattr)))
			Set attrs(attr)=val, upattrs(upattr)=""
		}
		Set tCT=$S(tCST:"binary/CST; charset=UTF-8", ""'=tCT:tCT, 0=tLen:"", tSOAP12:"application/soap+xml", 1:"text/xml")
		If ""=tHeaderExtra {
			Merge:'$D(tStreamOut("HTTPHeaders")) tStreamOut("HTTPHeaders")=attrs
			#; If response HTTP headers have been provided, use those
			Set attr="" For { Set attr=$O(tStreamOut("HTTPHeaders",attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
				If upattr = "CONTENT-TYPE" {
					Set tCT=val
				} ElseIf $Case(upattr,"CONTENT-LENGTH":0, "RESPONSECODE":0, "STATUSLINE":0, :1) {
					#; Set others into tHeaderExtra
					Set tHeaderExtra = tHeaderExtra_attr_": "_val_$C(13,10)
				}
			}
		}
		
		#; Add %SuperSession to response HTTP headers
		Try {
			If ..BusinessHost.%SuperSession'="" Set tHeaderExtra = tHeaderExtra_$$$EnsHTTPHeaderSuperSessionUC_": "_..BusinessHost.%SuperSession_$C(13,10)
		} Catch {}

		Set:" ZZZ"=$E(tStatusLine,*-3,*) $E(tStatusLine,$L(tStatusLine)-2,$L(tStatusLine)) = $S(
			  $$$ISERR(tSC)&&("HTTP SOAP request '"=$E($$$StatusText(tSC),1,$L("HTTP SOAP request '"))):"404 Not Found"
			, $$$ISERR(tSC):"500 Internal Server Error"
			, ..BusinessHost.OneWay:"202 Accepted"
			, 1:"200 OK")
		Set tHeader = tStatusLine_$C(13,10)_
				$S(""=tCT:"",1:"Content-Type: "_tCT_$C(13,10))_
				$S(0=tLen&&tCST:"", 1:"Content-Length: "_tLen_$C(13,10))_
				tHeader
		try {
			Set (tHTTPResponseStatus,tRS) = $P(tStatusLine," ",2,$L(tStatusLine," "))
			Do ..BusinessHost.OnAdapterHTTPResponse(tSC,.tHTTPResponseStatus,.tLen,.tStreamOut,.tHeader,.tHeaderExtra)
			If $G(tHTTPResponseStatus,tRS)'=tRS {
				Set p1=$F(tHeader," "), p2=$F(tHeader,$C(13,10))  Set p2=$S(p2:p2-3,1:$L(tHeader))
				Set $E(tHeader,p1,p2)=tHTTPResponseStatus
			}
		} catch {
			If ($ZE'["<METHOD DOES NOT EXIST>")||($ZE'[" *OnAdapterHTTPResponse") $$$LOGWARNING("Error in OnAdapterHTTPResponse:"_$ZE)
		}
		Write:""'=$G(tHeader) tHeader
		Write:""'=$G(tHeaderExtra) tHeaderExtra
		Write $C(13,10),*-3
		If tCST {
			If $$$ISOK(tSC) {  $$$ASSERT($$$IsdefObject(tMsgDescriptor))
				Set tSC=##class(EnsLib.SOAP.CST.InBase).Write(.%iaHeader,tMsgDescriptor,.tLen)
			} Else {
				Set tLen=##class(EnsLib.SOAP.CST.InBase).WriteFault(tSC,..BusinessHost)
			}
		} Else {
			Set tSC=##class(GenericService).writeJoinedResponse(tStreamOut,.tBodyStreamOut,.tBodyTagLen,.tNewBodyElem,tPreStream,tPostStream)
		}
		If tLen { $$$catTRACE("protocol","Wrote response body ("_tLen_")") } Else { $$$catTRACE("protocol","Empty response; no response body written") }
	}
	Set:$$$ISERR(tSC)&&$$$StatusEquals(tSC,$$$EnsErrTCPReadBlockSizeTimeoutExpired) tSC=$$$OK
Exit
	If $$$ISERR(tSC)&&..IsWriteError(tSC) Do ..Disconnect()
	Kill %iaHeader,%iaStream
	Quit tSC
TrapRS
	Set $ZT="TrapW",tZE=$ZE
	If $G(tZE)["<READ>" {
		Set tSC=$$$ERROR($$$EnsErrTCPReadBlockSize,..CallInterval,"line",$G(tZE))
		Do ..Disconnect()  Set tTxt=$$$StatusText(tSC)  If ..StayConnected { $$$LOGWARNING(tTxt) } Else { $$$LOGINFO(tTxt) } Set tSC=$$$OK
		Goto Exit
	} Else {
		Set tSC=$$$EnsSystemError
		Goto WriteResp
	}
Trap
	Set $ZT="TrapW",tZE=$ZE
	Use ..Device:(::"+":..Terminators) ; turn terminators back on
	If $G(tZE)["<READ>" {
		Set tSC=$$$SystemError
		Do ..Disconnect()
		Goto Exit
	}
	If $G(tZE)["<SOAP>" { Set tSC=%objlasterror }
	Else { Set tSC=$$$EnsSystemError }
	Goto WriteResp
TrapW
	Set $ZT="",tZE=$ZE, tSC=$S($G(tZE)["<WRITE>":$$$SystemError,1:$$$EnsSystemError)
	Goto Exit
}

/// Read from device and split response Envelope and Body into separate streams
Method readSplitEnvelopeStream(pLeft As %Integer, ByRef pBodyStream As %GlobalCharacterStream = {$$$NULLOREF}, ByRef pBodyLenExtra As %Integer = 0) As %Status [ Internal ]
{
	#; find starting element
	Set tSC=$$$OK, tLen=pLeft, tEnvelopeStream=%iaStream
	Do ..readStartTag(.pLeft,.tStartTag,.tPrefix,.tNSAttrs)
	If tStartTag'="Envelope" {
		Quit $$$ERROR($$$EnsErrGeneral,"No SOAP Envelope found in SOAP stream "_%iaStream.Read(1000))
	}
	#; read in whole header if any, and body start tag
	Set tFound=..readStreamUntil(.pLeft,tEnvelopeStream,"<"_tPrefix_"Body",.tSC,1)  Quit:$$$ISERR(tSC) tSC
	Quit:'tFound tEnvelopeStream.InputFromDevice(.pLeft,..ReadTimeout)

	#; start new body stream, copy envelope namespace declarations to Body element in new body stream, omit body contents from envelope stream
	Set pBodyStream = ##class(%GlobalCharacterStream).%New()  $$$ASSERT($IsObject(pBodyStream))
	If pLeft<$parameter("EnsLib.SOAP.GenericService","NSWinnowSizeThreshold") {
		#; winnow body NS declarations
		Use ..Device:(::"+":) ; turn off terminators 
		Read tTail#pLeft:..ReadTimeout  Set tTimedOut='$Test
		Set tTailAttrs=$P(tTail,">"), $E(tTail,1,$L(tTailAttrs))="", tPos=$F(tTail,"</"_tPrefix_"Body>")-1
		Quit:tPos<=0 $$$ERROR($$$EnsErrGeneral,"Response stream missing SOAP body close tag:'..."_tTail_"'")
		Set tNSAttrs=$$winnowEnvNSAttrs(tNSAttrs,tTailAttrs,$E(tTail,1,tPos))
		#; write remainder of body into body stream
		Set tNewBodyElem="<"_tPrefix_"Body"_tNSAttrs
		Set tSC=pBodyStream.Write(tNewBodyElem_$E(tTail,1,tPos))  Quit:$$$ISERR(tSC) tSC
		Set pBodyLenExtra=pBodyLenExtra+$L(tNewBodyElem)
		#; write close of dummy body and envelope close into envelope
		Set tNewBodyElem="></"_tPrefix_"Body>"
		Set tSC=tEnvelopeStream.Write(tNewBodyElem_$E(tTail,tPos+1,*))  Quit:$$$ISERR(tSC) tSC
		Set pBodyLenExtra=pBodyLenExtra+$L(tNewBodyElem)
	} Else {
		#; read remainder of body into body stream
		Set tNewBodyElem="<"_tPrefix_"Body"_tNSAttrs
		Set tSC=pBodyStream.Write(tNewBodyElem)  Quit:$$$ISERR(tSC) tSC
		Set pBodyLenExtra=pBodyLenExtra+$L(tNewBodyElem)
		Set tFound=..readStreamUntil(.pLeft,pBodyStream,"</"_tPrefix_"Body>",.tSC,1)  Quit:$$$ISERR(tSC) tSC
		#; write close of dummy body into envelope
		Set tNewBodyElem="></"_tPrefix_"Body>"
		Set tSC=tEnvelopeStream.Write(tNewBodyElem)  Quit:$$$ISERR(tSC) tSC
		Set pBodyLenExtra=pBodyLenExtra+$L(tNewBodyElem)
		#; finally copy envelope close onto tail of tEnvelopeStream
		Use ..Device:(::"+":) ; turn off terminators 
		Set tSC = tEnvelopeStream.InputFromDevice(.pLeft,..ReadTimeout)  Quit:$$$ISERR(tSC) tSC
	}
	Use ..Device:(::"+":..Terminators) ; turn terminators back on
	Quit tSC

winnowEnvNSAttrs(nsattrs,bodattrs,bod) ; omit envelope ns prefix declarations from body if they are already defined the same in the body attributes or are never used in the body
	Set alist=""
	#; map bodattrs
	Set nattrs=$L(bodattrs," xmlns")
	For i=2:1:nattrs { Set nsattr=$ZStrip($P(bodattrs," xmlns",i),"<>W")  Continue:""=nsattr
		Set tquot=$E(nsattr,$F(nsattr,"=")), pre=$P(nsattr,tquot,1)
		Set inMap(pre) = 1 ;$P(nsattr,tquot,2)
	}
	#; scan nsattrs backwards looking for ones to keep
	Set nattrs=$L(nsattrs," xmlns"), nslist=""
	For i=nattrs:-1:2 { Set nsattr=$ZStrip($P(nsattrs," xmlns",i),"<>W")  Continue:""=nsattr
		Set tquot=$E(nsattr,$F(nsattr,"=")), pre=$P(nsattr,tquot,1), pre2=$E(pre,2,*-1) ; strip off : and =
		If '$D(inMap(pre)) && ('$L(pre2) || (bod[(pre2_":"))) {
			Set alist=" xmlns"_$P(nsattr,tquot,1,2)_tquot_alist
			Set inMap(pre) = 1
		}
	}
	Quit alist_bodattrs
}

/// Read the starting element tag from the device, with its namespace prefix and its namespace declaration attributes and its total character length
Method readStartTag(pLeft As %Integer, Output pTag As %String, Output pPrefix As %String, Output pNSAttrs As %String, Output pBodyTagLen As %Integer) As %Status [ Internal ]
{
	Set tD=$D(pNSAttrs)  If tD {
		Merge:tD>1 inMap=pNSAttrs
		Do:tD#2 buildInMap(pNSAttrs)
	}
	Set tSC=$$$OK, (pTag,pPrefix,pNSAttrs)="", pBodyTagLen=0
	// copy post-header part in, loop writing into stream until done
	Use ..Device:(::"+":">") ; activate terminator '>'
	For i=1:1:5 {
		Set tLen=32000-1  Set:tLen<pLeft tLen=pLeft
		Read tBuf#tLen:..ReadTimeout  Set tTimedOut='$Test
		If tTimedOut Set tSC=$$$ERROR($$$EnsErrGeneral,"Timeout ("_..ReadTimeout_") waiting to read for character '>'")  Quit
		Set tBuf=tBuf_$ZB, pLeft=pLeft-$L(tBuf)
		Set tSC=%iaStream.Write(tBuf)  Quit:$$$ISERR(tSC)
		Set pTag=$P(tBuf,">")
		Quit:pTag=tBuf ; no > found
		Set pBodyTagLen=pBodyTagLen+$L(pTag)+1
		If $Case($E(tBuf,$F(tBuf,"<")),"?":0,"!":0,:1) {
			Set pTag=$P(pTag,"<",2)
			If 'tD { Set pNSAttrs=$$normalizeNSAttrs(" "_$P(pTag," ",2,$L(pTag," "))) }
			Else { Set pNSAttrs=$$winnowBodNSAttrs(" "_$P(pTag," ",2,$L(pTag," "))) }
			Set pTag=$P(pTag," ")
			Quit
		}
		#; if we got a <?xml ?> declaration or <!-- --> comment, skip it and get next element
		Set (tBuf,pTag)=""
	}
	Use ..Device:(::"+":..Terminators) ; turn terminators back on

	#; Now we're at the root element
	If pTag=tBuf { Set pTag="",pPrefix=""  Quit $$$OK }
	If pTag[":" {
		Set pPrefix=$P(pTag,":",1,$L(pTag,":")-1)_":"
		Set $E(pTag,1,$L(pPrefix))=""
	} Else {
		Set pPrefix=""
	}
	Quit $$$OK

buildInMap(attrs)
	Set nattrs=$L(attrs," xmlns")
	For i=2:1:nattrs { Set nsattr=$ZStrip($P(attrs," xmlns",i),"<>W")  Continue:""=nsattr
		Set tquot=$E(nsattr,$F(nsattr,"=")), pre=$P(nsattr,tquot,1)
		Set inMap(pre) = $P(nsattr,tquot,2)
	}
	Quit

normalizeNSAttrs(attrs)
	Set nattrs=$L(attrs," xmlns"), nslist=""
	For i=2:1:nattrs { Set nsattr=$ZStrip($P(attrs," xmlns",i),"<>W")  Continue:""=nsattr
		Set tquot=$E(nsattr,$F(nsattr,"="))
		Set nslist=nslist_" xmlns"_$P(nsattr,tquot,1,2)_tquot
	}
	Quit nslist

winnowBodNSAttrs(attrs) ; omit body ns prefix declarations that are already defined the same in the envelope attributes
	Set nattrs=$L(attrs," xmlns"), extra=$ZStrip($P(attrs," xmlns",1),"<>W")
	Set alist=$S(""=extra:"",1:" "_extra)
	For i=2:1:nattrs { Set nsattr=$ZStrip($P(attrs," xmlns",i),"<>W")  Continue:""=nsattr
		Set tquot=$E(nsattr,$F(nsattr,"="))
		Set:'$D(inMap($P(nsattr,tquot,1)),nsval)||(nsval'=$P(nsattr,tquot,2)) alist=alist_" xmlns"_$P(nsattr,tquot,1,2)_tquot
		Set extra=$ZStrip($P(nsattr,tquot,3,999),"<>W")
		Set:""'=extra alist=alist_" "_extra
	}
	Quit alist
}

/// Read current device until target found in pStreamIn, copying all data read to pStreamOut
Method readStreamUntil(pLeft As %Integer, pStreamOut As %GlobalCharacterStream, Output pTarget As %String, pStatus As %Status, pIncludeTarget As %Boolean = 0) As %Boolean [ Internal ]
{
	#; Read in chunks using last char of pTarget as terminator
	Set tSC=$$$OK,tFound=0
	Set tC=$E(pTarget,*)
	Use ..Device:(::"+":tC) ; activate terminator tC
	Set tBuf="" While $$$ISOK(tSC) && 'tFound && (pLeft>0) {
		Set tLen=32000-$L(pTarget)  Set:tLen<pLeft tLen=pLeft
		Read data#tLen:..ReadTimeout  Set tTimedOut='$Test
		If tTimedOut Set tSC=$$$ERROR($$$EnsErrGeneral,"Timeout ("_..ReadTimeout_") waiting to read for character '"_tC_"'")  Quit
		Set tBuf=tBuf_data_$ZB, pLeft=pLeft-$L(data)-$L($ZB)
		If ""'=$ZB && ($L(tBuf)>=$L(pTarget)) && (pTarget=$E(tBuf,*+1-$L(pTarget),*)) {
			Set tFound=1
			Set tSC=pStreamOut.Write(tBuf), tBuf=""
		} Else {
			If $L(tBuf)>$L(pTarget) Set tSC=pStreamOut.Write($E(tBuf,1,$L(tBuf)+1-$L(pTarget))), $E(tBuf,1,$L(tBuf)+1-$L(pTarget))=""
		}
	}
	Use ..Device:(::"+":..Terminators) ; turn terminators back on
	Set:'tFound&&$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrGeneral,"Reached max content size while trying to read for character '"_tC_"'")
	Set:$$$ISOK(tSC)&&$L(tBuf) tSC=pStreamOut.Write(tBuf)
	Quit tFound
}

ClassMethod faultStream(pStatus As %Status, pBHost As EnsLib.SOAP.Service, pSOAPVer As %String) As %GlobalCharacterStream
{
	Set tStream = ##class(%Library.GlobalCharacterStream).%New()  $$$ASSERT($IsObject(tStream))
	Do tStream.Write(..faultString(.pStatus,.pBHost,.pSOAPVer))
	Quit tStream
}

ClassMethod faultString(pStatus As %Status, pBHost As EnsLib.SOAP.Service, pSOAPVer As %String = "1.1") As %String
{
	Quit pBHost.OnFaultString(.pStatus,pBHost,pSOAPVer)
}

}
