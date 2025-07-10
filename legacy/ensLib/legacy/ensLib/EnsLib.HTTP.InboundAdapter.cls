/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// HTTP Listener for custom port listening, XML listening, and/or raw HTML handling
Class EnsLib.HTTP.InboundAdapter Extends EnsLib.TCP.InboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "%Stream.Object";

Parameter SERVICEOUTPUTCLASS = "%Stream.Object";

/// Local TCP port to listen on for HTTP requests
Property Port As Ens.DataType.TCPAgentPort [ InitialExpression = "9980", Required ];

/// Text Charset to use to decode incoming data. In addition to standard Character Encoding identifiers, allowed values are Auto,AutoXML,Binary,and RawBytes.<p>
/// Auto means use the encoding declared in the incoming HTTP header Content-Type field.<p>
/// AutoXML means use the encoding declared in the XML header of the incoming XML body content, if any.<p>
/// RawBytes or Binary mean to read the raw bytes of the body without any Character Encoding transformation. This is the default action.
Property Charset As %String [ InitialExpression = "Auto" ];

/// If True, use the Charset setting rather than any charset that may be declared in the incoming HTTP header Content-Type field
Property ForceCharset As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "Charset:Adapter Only:selector?context={Ens.ContextSearch/CharacterSets},ForceCharset:Adapter Only";

/* (override Setting's InitialExpression inherited from base class) */
/// If non-zero, stay connected to the remote system between handling Requests until idle for this number of seconds. A value of -1 means never disconnect.
Property StayConnected As %Numeric(MINVAL = -1) [ InitialExpression = 0 ];

/// Set this property from onInit() in your Service class to make the adapter parse form variables from the form body in case of a form POST
Property ParseBodyFormVars As %Boolean;

/// Set this to 0 to prevent normalizing of HTTP header variable names to lowercase
Property %ToLowerHeaderVars As %Boolean [ InitialExpression = 1 ];

/// Override the Device Mode that will be used to open the TCP socket
Parameter Mode As %String = "SW";

Method OnConnected() As %Status
{
	Set tSC=$$$OK
	Do {
		Set $ZT="TrapRS"
		// Read raw lines of header, then suck in whole body into a stream
		Use ..Device:(::"+":$C(10)) ; turn on terminators
		Set tStartTime=$zh
		Read tLine:..CallInterval Set tTimedOut='$Test
		Set $ZT="Trap"
		If tTimedOut {
			If $zh-tStartTime < (..CallInterval-0.1) { $$$sysTRACE($$$StatusText($$$ERROR($$$EnsErrTCPReadBlockSize,..CallInterval,"line",tLine))) }
			Else { $$$sysTRACE($$$StatusText($$$ERROR($$$EnsErrTCPReadBlockSizeTimeoutExpired,..CallInterval,"line"))) }
			Quit
		}
		Set:$E(tLine,$L(tLine))=$C(13) $E(tLine,$L(tLine))=""

		Set tCmd=$P(tLine," ")
		Set buf=$P(tLine," ",2)
		Set tURL=$P(buf,"?"), $E(buf,1,1+$L(tURL))=""
		Set tHeader("URL")=tURL
		Set tHeader("RawParams")=buf
		Set tHeader("HttpRequest")=tCmd, tHeader("HttpRequest",$S(""=tCmd:"ERR",1:tCmd))=tURL
		Set (i,j)=0  While ""'=buf {
			Set tVal=$P(buf,"&"), $E(buf,1,$L(tVal)+1)=""
			Set i=i+1, tHeader("IParams",i)=$ZCVT(tVal,"I","URL")
			Set tKey=$P(tVal,"="), $E(tVal,1,$L(tKey)+1)=""
			Set tKey=$ZCVT(tKey,"I","URL")
			Continue:""=tKey
			Set inst=$I(tHeader("Params",tKey)) Set:1=inst j=j+1
			Set tHeader("Params",tKey,inst)=$ZCVT(tVal,"I","URL")
		}
		Set tHeader("Params")=j
		Set tHeader("IParams")=i
		$$$sysTRACE("Got HTTP Request '"_tHeader("HttpRequest")_" "_tURL_"'")
		If 3'=$L(tLine," ") Set tSC=$$$EnsError($$$EnsErrGeneral,"invalid HTTP header:'"_tLine_"'") Quit
		Set tLine=$P(tLine," ",3,$L(tLine," "))
		If "HTTP"'=$P(tLine,"/") Set tSC=$$$EnsError($$$EnsErrGeneral,"invalid HTTP version'"_tLine_"'") Quit
		Set tHeader("HTTPVersion")=$P(tLine,"/",2)
		Set tLen="x", tContentType=""
		#dim tSuperSession As %String = ""
		While 1 {
			Set tStartTime=$zh
			Read tLine:..ReadTimeout Set tTimedOut='$Test
			If tTimedOut {
				if $zh-tStartTime < ..ReadTimeout { Set tSC = $$$EnsError($$$EnsErrTCPReadBlockSize,..ReadTimeout,"line",tLine) }
				else { Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,..ReadTimeout,"line","ascii") }
				Quit
			}
			Set:$E(tLine,$L(tLine))=$C(13) $E(tLine,$L(tLine))=""
			Quit:""=tLine
			Set attr=$P(tLine,":"), lwrattr=$ZCVT(attr,"L")
			Set:..%ToLowerHeaderVars attr=lwrattr
			Set:'$D(lwrattrs(lwrattr)) tHeader(attr)=$ZStrip($P(tLine,":",2,$L(tLine,":")),"<>W"), lwrattrs(lwrattr)=""
			Set:"content-length"=lwrattr tLen=tHeader(attr)
			Set:"content-type"=lwrattr tContentType=tHeader(attr)
			Set:(($$$EnsHTTPHeaderSuperSessionLC=lwrattr)&&(tSuperSession="")) tSuperSession=tHeader(attr)
		}
		Quit:$$$ISERR(tSC)

		If ("auto"'=$ZCVT(..Charset,"L")&&("autoxml"'=$ZCVT(..Charset,"L")))||..ForceCharset { Set tCharset=..Charset }
		Else { Set tCharset=$P($ZCVT(tContentType,"L"),"charset=",2), tCharset=$TR($P(tCharset,";"),"""","") }
		Set tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable($Case($ZCVT(tCharset,"L"),"":"rawbytes","binary":"rawbytes",:tCharset))
		If ""=tTable Set tTable="RAW" $$$LOGWARNING("Unable to find Translation Table for charset "_tCharset)

		If "x"=tLen { Set tLen = $S(("chunked"=$G(tHeader("transfer-encoding"))):0,1:$Case($ZCVT(tCmd,"L"),"get":0,"delete":0,"options":0,"head":0,:1000000000))  If tLen $$$LOGWARNING("Content-Length not found; will read body up to "_tLen_" bytes or "_..ReadTimeout_" seconds, with encoding "_tCharset_", table='"_tTable_"'") }
		Else { $$$sysTRACE("Got content-length="_tLen_", waiting ("_..ReadTimeout_"s) to read body with encoding "_tCharset_", table='"_tTable_"' and timeout="_..ReadTimeout) }

		If "autoxml"=$ZCVT(..Charset,"L") && tLen {
			Set tSC=..readXMLEncoding(.tTable,.tHeaderXML)  Quit:$$$ISERR(tSC)
		}
		If $Case($ZCVT(..Charset,"L"),"":1,"binary":1,"rawbytes":1,:0) {
			Set tStream = ##class(%Library.GlobalBinaryStream).%New()  $$$ASSERT($IsObject(tStream))
		} Else {
			Set tStream = ##class(%Library.GlobalCharacterStream).%New()  $$$ASSERT($IsObject(tStream))
		}
		#; now read the body
		If tLen {
			Do:$G(tHeaderXML) tStream.Write(tHeaderXML)
			Set tLenIn=$S(""=$G(tHeaderXML):tLen,1:tLen-$L(tHeaderXML))
			Use ..Device:(::"+") ; turn off terminators
			If tStream.%Extends("%IO.I.Stream") {
				Set tTimeout=..ReadTimeout, tLenBase=tLenIn
				Do tStream.InputFromDevice(.tLenIn,,.tTimeout,.tSC)
				If tTimeout>=..ReadTimeout&&$$$ISOK(tSC)&&(tLen<tLenIn) $$$LOGWARNING("timed out after reading "_tLenIn_" raw bytes of "_tLenBase_" for HTTP '"_tCmd_"' request")
			} Else {
				Set tSC=tStream.InputFromDevice(tLenIn,..ReadTimeout)  Set tLenBase=tLenIn, tLenIn=tStream.Size
				If $$$StatusEquals(tSC,$$$FileDoesNotExist) Set tSC=$$$OK  $$$LOGWARNING("timed out after reading "_tLenIn_" raw bytes of "_tLenBase_" for HTTP '"_tCmd_"' request")
			}
			If $$$ISERR(tSC) $$$LOGSTATUS(tSC) Quit
			If "RAW"'=tTable {
				Set tSC = ..ApplyCharset(tStream, tTable, .byteSize)
				$$$sysTRACE("TCP Read body("_tStream.Size_") from "_byteSize_" raw bytes using table "_tTable_": "_$S(tStream.Size>1003:tStream.Read(1000)_"...",1:tStream.Read())_$E(tStream.Rewind(),1,0))
			} Else {
				$$$sysTRACE("TCP Read raw body("_tStream.Size_")")
			}
		} ElseIf "chunked"=$G(tHeader("transfer-encoding")) {
			For {
				#; Next line is length of chunk in hex
				Set tLen=""  Read tLen:..ReadTimeout  Set tTimedOut='$Test
				Continue:((tLen=$C(13))||(tLen=""))
				If tLen,tTimedOut { Set tSC=$$$ERROR($$$EnsErrTCPReadBlockSize,..CallInterval,"chunksize",tLen)  Quit }
				Set tLen=$ZHex(tLen)
				If tLen {
					#; Read next chunk into the stream up to the given length
					Use ..Device:(::"+":) ; turn off terminators
					If tStream.%Extends("%IO.I.Stream") {
						Do tStream.InputFromDevice(tLen,,..ReadTimeout,.tSC)
					} Else {
						Set tSC=tStream.InputFromDevice(tLen,..ReadTimeout)
					}
					Use ..Device:(::"+":$C(10)) ; turn terminators back on
					Quit:$$$ISERR(tSC)
				} Else {
					Quit ; A zero length chunk ends all
				}
			}
			Use ..Device:(::"+") ; turn off terminators
			Kill tHeader("transfer-encoding")
			Set tHeader("content-length")=tStream.Size
			If "RAW"'=tTable {
				Set tSC = ..ApplyCharset(tStream, tTable)
			}
			$$$sysTRACE("Completed TCP Read of chunked HTTP body("_tStream.Size_")")
		}
	} While 0
	If $$$ISOK(tSC)&&'tTimedOut {
		If "post"=$ZCVT(tCmd,"L") && ..ParseBodyFormVars {
			Do tStream.Rewind()
			Set buf="", i=$G(tHeader("IParams"),0), j=$G(tHeader("Params"),0)
			For {
				Set buf=buf_tStream.Read(32000-$L(buf),.tSC)  Quit:$$$ISERR(tSC)||'$L(buf)
				Set tVal=$P(buf,"&"), $E(buf,1,$L(tVal)+1)=""
				Set i=i+1, tHeader("IParams",i)=$ZCVT(tVal,"I","URL")
				Set tKey=$P(tVal,"="), $E(tVal,1,$L(tKey)+1)=""
				Set tKey=$ZCVT(tKey,"I","URL")
				Continue:""=tKey
				Set inst=$I(tHeader("Params",tKey)) Set:1=inst j=j+1
				Set tHeader("Params",tKey,inst)=$ZCVT(tVal,"I","URL")
			}
			Set tHeader("Params")=j
			Set tHeader("IParams")=i
		}
		Merge tStream.Attributes=tHeader
		Set tStream.Attributes("CharEncoding")=tCharset
		Set tStream.Attributes("TranslationTable")=tTable
		Set tStream.Attributes("EnsConfigName")=..BusinessHost.%ConfigName
		Set ..BusinessHost.%SuperSession = tSuperSession
		#;Need to ensure that any cleanup of %SuperSession is able to identify early set. NoOP if tSuperSession is ""
		Set ..BusinessHost.%SuperSessionCreatedBeforeSession = 1

		Set tSC=..BusinessHost.ProcessInput(tStream,.tStreamOut)
		Use ..Device:(::"+") ; make sure terminators are still off
	}
WriteResp
	If ""'=$G(tURL) && ..Connected {
		If $$$ISERR(tSC) {
			Set tStreamOut=$$$NULLOREF
			try {
				Set tStreamOut=..BusinessHost.OnErrorStream(tSC,..BusinessHost)
			} catch {
				If $ZE'["METHOD DOES NOT EXIST" {
					Set tSC1=$$$SystemError
					Set tSC=$$$ADDSC(tSC,tSC1)
				}
			}
			Set:'$IsObject(tStreamOut) tStreamOut=..faultStream(tSC)
		}
		#; Write response header then response body
		Set $ZT="TrapW"
		If $D(tStreamOut)#2 {
			If $IsObject(tStreamOut) {
				If tStreamOut.%Extends("%Library.AbstractStream") {
					Set tLen=tStreamOut.Size
					#; get headers from tStreamOut attributes
					Set tCT=$G(tStreamOut.Attributes("CONTENT-TYPE"),$G(tStreamOut.Attributes("Content-Type"),$G(tStreamOut("CONTENT-TYPE"),$G(tStreamOut("Content-Type"),"text/html"))))
					Set tStatusLine=$G(tStreamOut.Attributes("STATUSLINE"),$G(tStreamOut.Attributes("StatusLine"),$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut.Attributes("RESPONSECODE"),$G(tStreamOut.Attributes("ResponseCode"),$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"200 OK"))))))))
					Set attr="" For { Set attr=$O(tStreamOut.Attributes(attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
						Continue:'$D(val)||$Case(upattr,"CONTENT-TYPE":1, "RESPONSECODE":1, "STATUSLINE":1, "TRANSFER-ENCODING":"CHUNKED"=$ZCVT(val,"U"), "CONTENT-ENCODING":"GZIP"=$ZCVT(val,"U"), :$D(upattrs(upattr)))
						Set attrs(attr)=val, upattrs(upattr)=""
					}
				} Else {
					Set tLen=$S(tStreamOut.%Extends("%IO.IParts.CharacterSeekableIO"):tStreamOut.ExternalByteSize, 1:tStreamOut.Size)
					Set tCT=$G(tStreamOut("CONTENT-TYPE"),$G(tStreamOut("Content-Type"),"text/html")), tStatusLine=$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"200 OK"))))
				}
			} Else {
				Set tLen=$L(tStreamOut), tCT=$G(tStreamOut("CONTENT-TYPE"),$G(tStreamOut("Content-Type"),"text/html")), tStatusLine=$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"200 OK"))))
			}
		} Else {
			Set tLen=0, tCT=$G(tStreamOut("CONTENT-TYPE"),$G(tStreamOut("Content-Type"),"text/html")), tStatusLine=$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"200 OK"))))
		}
		#; get headers from tStreamOut subscripts too
		Set attr="" For { Set attr=$O(tStreamOut(attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
			Continue:'$D(val)||$Case(upattr,"CONTENT-TYPE":1, "RESPONSECODE":1, "STATUSLINE":1, "TRANSFER-ENCODING":"CHUNKED"=$ZCVT(val,"U"), "CONTENT-ENCODING":"GZIP"=$ZCVT(val,"U"), :$D(upattrs(upattr)))
			Set attrs(attr)=val, upattrs(upattr)=""
		}
		#; Add provided response HTTP headers to tHeaderExtra
		Set tHeaderExtra = ""
		Set attr="" For { Set attr=$O(attrs(attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
			If upattr = "CONTENT-TYPE" {
				Set tCT=val
			} ElseIf upattr '= "CONTENT-LENGTH" {
				#; Set others into tHeaderExtra
				Set tHeaderExtra = tHeaderExtra_attr_": "_val_$C(13,10)
			}
		}

		#; Add %SuperSession to response HTTP headers
		Try {
			If ..BusinessHost.%SuperSession'="" Set tHeaderExtra = tHeaderExtra_$$$EnsHTTPHeaderSuperSessionUC_": "_..BusinessHost.%SuperSession_$C(13,10)
		} Catch {}

		If '..BusinessHost.%Extends("EnsLib.HTTP.GenericService") {
			Set tHeaderExtra = tHeaderExtra_"CACHE-CONTROL: no-cache"_$C(13,10)_
						"PRAGMA: no-cache"_$C(13,10)
		}
		Set tHeader = tStatusLine_$C(13,10)_
				$S(""=tCT:"",1:"Content-Type: "_tCT_$C(13,10))_
				"Content-Length: "_tLen_$C(13,10)
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

		If $D(tStreamOut)#2 {
			If $IsObject(tStreamOut) {
				If tStreamOut.%Extends("%IO.I.Stream") {
					Do tStreamOut.OutputToDevice(,,.tSC)
				} Else {
					Set tSC=tStreamOut.OutputToDevice()
				}
			} Else {
				Write:$L(tStreamOut) tStreamOut
			}
			If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
			Write *-3
		}
		$$$sysTRACE("Wrote response("_tLen_")")
	}
Exit
	If $$$ISERR(tSC)&&..IsWriteError(tSC) Do ..Disconnect()  $$$LOGSTATUS(tSC)
	Quit tSC
TrapRS
	Set $ZT="TrapW",tZE=$ZE
	If $g(tZE)["<READ>" $$$sysTRACE($$$StatusText($$$ERROR($$$EnsErrTCPReadBlockSize,..CallInterval,"line",$g(tZE)))) Goto Exit
	Set tSC=$$$EnsSystemError
	Goto WriteResp
Trap
	Set $ZT="TrapW",tZE=$ZE
	If $g(tZE)["<READ>" Set tSC =$$$SystemError Goto Exit
	Set tSC=$$$EnsSystemError
	Goto WriteResp
TrapW
	Set $ZT="",tZE=$ZE, tSC=$S($g(tZE)'["<WRITE>":$$$EnsSystemError,1:$$$SystemError)
	Goto Exit
}

Method OnTask() As %Status
{
	#dim tSC As %Status = ##super()
	#; We do not want the HTTP inbound adapter to wait if master listener and it is not throttling
	If $$$ISOK(tSC) && '..Connected && ..JobPerConnection && (..%outIPAddr="") &&
		(..%PoolLimit<=1 || (..%PoolLimit>$G(^IRIS.Temp.EnsTCPJobs($Job,"children")))) {
			Set ..BusinessHost.%WaitForNextCallInterval=0
	}
	Quit tSC
}

Method readXMLEncoding(ByRef tTable As %String, Output tHeader As %String) [ Private ]
{
	Set tSC=$$$OK, tStartTime=$ZH
	Use ..Device:(::"+":">") ; turn on terminators
	Read tHeader#100:..ReadTimeout Set tTimedOut='$Test
	If tTimedOut {
		If $zh-tStartTime < ..ReadTimeout { Set tSC = $$$EnsError($$$EnsErrTCPReadBlockSize,..ReadTimeout,"header",tHeader) }
		Else { Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,..ReadTimeout,"header","rawbytes") }
		Quit tSC
	}
	If $ZB'=">" {
		If "RAW"'=tTable $$$LOGWARNING("Found no XML header; read initial bytes '"_tHeader_"' raw, not using table '"_tTable_"'")
		Quit tSC
	}
	If "?"=$E(tHeader,*) {
		Set tEncoding=$Translate($Piece(tHeader,"encoding",2),"""","'")
		Set tEncodingValpos = $F(tEncoding,"'")
		Set:"="'=$ZSTRIP($E(tEncoding,1,tEncodingValpos-2),"*W") tEncoding=""
		Set tEncoding=$Piece(tEncoding,"'",2)
		If ""'=tEncoding {
			Set ttTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(tEncoding)
			If ""=ttTable { $$$LOGWARNING("Failed to find a Tranlation Table for encoding from XML header: '"_tEncoding_"'") }
			ElseIf ttTable'=tTable {
				$$$sysTRACE("Overriding table '"_tTable_"' with '"_ttTable_"' from XML header declaration encoding='"_tEncoding_"'")
				Set tTable=ttTable
				Set pos=$F(tHeader,"encoding"), pos=$F(tHeader,tEncoding,pos)
				Set $E(tHeader,pos-$L(tEncoding),pos-1)="utf-16"  ; override declared external xml encoding with internal XML encoding declaration
			}
		}
	}
	Quit tSC
}

/// Deprecated - use <method>##class(%IO.I.TranslationDevice).GetCharEncodingTable()</method>
ClassMethod GetCharEncodingTable(pCharEncoding As %String) As %String [ CodeMode = expression, Internal ]
{
##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharEncoding)
}

/// Deprecated - use <method>##class(%IO.I.TranslationDevice).GetLocaleDefaultTable()</method>
ClassMethod GetLocaleDefaultTable() As %String [ CodeMode = expression, Internal ]
{
##class(%IO.I.TranslationDevice).GetLocaleDefaultTable()
}

Method faultStream(pStatus As %Status) As %GlobalBinaryStream [ Private ]
{
	Set tStream = ##class(%Library.GlobalBinaryStream).%New()  $$$ASSERT($IsObject(tStream))
	Do tStream.Write(
		"<BODY>"_$C(13,10)_
		"<error>"_$C(13,10)_
		"    <source>"_$ZCVT($classname(..BusinessHost),"O","XML")_"</source>"_$C(13,10)_
		"    <text>"_$ZCVT($$$StatusDisplayString(pStatus),"O","XML")_"</text>"_$C(13,10)_
		"</error>"_$C(13,10)_
		"</BODY>"_$C(13,10)
		)
	Set tStream.Attributes("ResponseCode")="500 Internal Server Error"
	Quit tStream
}

/// ApplyCharset converts the content of the provided stream into the provided charset encoding.
/// Output its byte size to its 3rd argument, if provided.
ClassMethod ApplyCharset(pStream As %Stream.Object, pCharset As %String, Output pExternalSize As %Integer) As %Status
{
	Set tStream = ##class(%IO.FileStream).%New()  $$$ASSERT($IsObject(tStream))
	Do tStream.Open(,"NEWR",,"rawbytes",.tSC)
	Return:$$$ISERR(tSC) tSC

	Do tStream.CopyFrom(pStream,,1,.tSC)
	Return:$$$ISERR(tSC) tSC

	Set pExternalSize = tStream.ExternalByteSize

	Set tStream.TranslationTable = pCharset
	Do tStream.CopyReplace(pStream,,,,,,,1,.tSC)
	Return:$$$ISERR(tSC) tSC

	Return $$$OK
}

}
