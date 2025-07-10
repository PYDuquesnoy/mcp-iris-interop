/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract base class for HTTP-based BusinessService classes. Can use a HTTP.InboundAdapter listener, or the standard CSP service mechanism, or both.
/// In order for the CSP mechanism to work, Web Services derived from this class must be configured either with their configuration name the same as their
/// class name, or the invoking URL must include ?CfgItem= giving the config item name, or using a CSP application with a DispatchClass configured and the config item name as the next URL piece after the application name.
/// (Configured Services exposed using the HTTP Inbound Adapter may also be invoked with this URL parameter but because each configured Inbound Adapter listens on its own TCP/IP port this parameter is just a safety check for them.)
Class EnsLib.HTTP.Service Extends (Ens.BusinessService, %CSP.Page) [ System = 4 ]
{

/// Name of the adapter class - override this to "" if you want to use only the regular HTTP mechanism and not the custom-port HTTP InboundAdapter.
Parameter ADAPTER = "EnsLib.HTTP.InboundAdapter";

/// Listen via the CSP WebServer in addition to listening on the HTTP.InboundAdapter's custom local port, if the Adapter is defined/ <p/>
/// Note that SSLConfig only applies to the custom local port. To use SSL via the CSP WebServer, you must configure the WebServer separately. <p/>
/// If the Service is invoked via the CSP WebServer, the ?CfgItem= URL parameter may be used to distinguish between multiple configured
/// same-class Services but the standard csp/namespace/classname URL must be used.
Property EnableStandardRequests As %Boolean [ InitialExpression = 1 ];

/// When receiving via the CSP Gateway if the  %response.ContentType=text/...
/// or the %response.CharSet is specified then CSP will normally convert
/// to the target charset when writing the response.
/// This property is used to set the %response.NoCharSetConvert property. <br>
/// The default is to have the CSP Gateway convert to the target charset. <br>
/// For passthrough (generic) this might need to be checked so that the CSP Gateway does not convert.<br>
/// If %response.NoCharSetConvert is set to true in custom code that will take precedence over this property being false.
Property CSPNoCharSetConvert As %Boolean [ InitialExpression = 0 ];

/// When receiving via the CSP Gateway if the request's Content-Type header
/// contains a charset (e.g. charset=utf-8), it is normally not applied. <br>
/// Enable this setting to apply the charset provided by the request header.
Property CSPHeaderCharsetConvert As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS As %String = "EnableStandardRequests:Connection";

/// Set this to 0 to prevent normalizing of HTTP header variable names to lowercase
Parameter TOLOWERHEADERVARS = 1;

/// Set this to make page parse form variables from the form body in case of a form POST
Parameter PARSEBODYFORMVARS = 0;

/// Set this to remove CSP Gateway inserted Content stream attributes (e.g. FileName, MimeSection)
Parameter REMOVECSPATTRIBS = 0;

Method OnInit() As %Status
{
	If $IsObject(..Adapter) {
		Set ..Adapter.%ToLowerHeaderVars=..#TOLOWERHEADERVARS
		Set ..Adapter.ParseBodyFormVars=..#PARSEBODYFORMVARS
	}
	Quit ##super()
}

/// Ensure no call to %response.WriteHTTPHeader() before OnPage(); ServerOnly and not Abstract to ensure $$$cMETHrunnable
ClassMethod OnHTTPHeader(ByRef OutputBody As %Boolean) As %Status [ ServerOnly = 1 ]
{
	Quit $$$OK
}

ClassMethod OnPage() As %Status [ Internal, ServerOnly = 1 ]
{
#dim %request As %CSP.Request
	Set tSC=$$$OK, tIsMapped=0
	If '$$$IsdefObject(%request) { Set tConfigName="" }
	Else {
		Set tConfigName=$G(%request.Data("CFGITEM",1),$G(%request.Data("CfgItem",1),$G(%request.Data("cfgitem",1))))
		If ""=tConfigName {
			#; if no Cfg Item named, find the HTTP Service configured with its config name in the (mapped) URL
			Set tURL=$G(%request.CgiEnvs("REQUEST_URI"))
			If tURL="" Set tURL=%request.URL
			If ($$$GetSecurityApplicationsDispatchClass(%request.AppData)'="") {
				Set tIsMapped = 1
				#; If mapped, try to get config name from URL.
				#; For mapped we want to ensure also the URL is the encoded URL sent in by the client.
				If (tURL=$ZCVT(tURL,"I","URL")) {
					Set tConfigName=$P($E(tURL,$L(%request.Application)+1,*),"/")
					If $F(tURL,"?") {
						Set tURL=$ZCVT($P(tURL,"?"),"O","URL")_"?"_$P(tURL,"?",2,*)
					} Else {
						Set tURL=$ZCVT(tURL,"O","URL")
					}
				} Else {
					Set tConfigName=$ZConvert($P($E(tURL,$L(%request.Application)+1,*),"/"),"I","URL")
				}
			}
		} Else {
			Set tURL=%request.URL
		}
	}
	#; if no Cfg Item named, find the HTTP Service configured with its config name equal to its classname
	Set:""=tConfigName tConfigName=$$$CurrentClass
	Set tConfigClass=$G($$$ConfigClassName(tConfigName))
	If tConfigClass=$$$CurrentClass || (""'=tConfigClass && tIsMapped && $classmethod(tConfigClass,"%Extends",$$$CurrentClass)) {
		Set tSC=##class(Ens.Director).CreateBusinessService(tConfigName,.tInstance)
	} Else {
		Set tInstance=$$$NULLOREF, tSC=$$$EnsError($S(""=tConfigClass:$$$EnsErrHTTPConfigName,1:$$$EnsErrHTTPConfigClass),tConfigName,tConfigClass)
	}
	If $$$ISOK(tSC) && $IsObject(tInstance.Adapter) && ('tInstance.Adapter.%Extends("EnsLib.HTTP.InboundAdapter") || 'tInstance.EnableStandardRequests) {
		Set tSC=$$$ERROR($$$EnsErrHTTPNotEnabled,tConfigName)
	}
	If $$$ISOK(tSC) {
		$$$sysTRACE("Processing HTTP request "_tURL)
		Set body=%request.Content
		If '$IsObject(body) {
			Set stream=##class(%GlobalCharacterStream).%New()  Do stream.Write(body)  Set body=stream
		} ElseIf ..#REMOVECSPATTRIBS {
			Try { Do body.SetAttributeList("") } Catch {}
		}
		Try {
			/*	Check for form-urlencoded and put %request.Data array parsed by CSP GAteway back into body.
				Do before addAttributesToBody to allow PARSEBODYFORMVARS if set.
			*/
			If (($ZCVT(%request.ContentType,"L")["application/x-www-form-urlencoded")) {
				Set tSC = ..restoreFormEncoded(body)
				If $$$ISERR(tSC) Quit
			}

			Set tSC=..addAttributesToBody(.body, tInstance.CSPHeaderCharsetConvert)
			If $$$ISERR(tSC) Quit
			Set body.Attributes("URL")=tURL
			Set body.Attributes("CSPApplication")=%request.Application
			Set body.Attributes("EnsConfigName")=tConfigName

			/*	Look for any multipart and put back into body.
				Do after addAttributesToBody in order to have content-type attribute
				Possible that only form key value pairs sent and hence need to retrieve
				from Data array
			*/
			If (%request.NextMimeData("")'="")||(($ZCVT(%request.ContentType,"L")["multipart")&&($Data(%request.Data))) {
				Set tSC = ..restoreMultipart(body)
				If $$$ISERR(tSC) Quit
			}
		} Catch { Set tSC = $$$SystemError }
		Set:$$$ISOK(tSC) tSC=tInstance.ProcessInput(body,.resp)
	}
	If $$$ISERR(tSC) {
		Set resp=$$$NULLOREF
		try {
			Set resp=..OnErrorStream(tSC,tInstance)
		} catch {
			If $ZE'["METHOD DOES NOT EXIST" {
				Set tSC1=$$$SystemError
				Set tSC=$$$ADDSC(tSC,tSC1)
			}
		}
		If '$IsObject(resp) {
			// Use the adapter faultStream method as a default to produce an error return
			Set tAdapter=$S($IsObject(tInstance):tInstance.Adapter, 1:$$$NULLOREF)
			If '$IsObject(tAdapter) {
				Set tAdapter=##class(EnsLib.HTTP.InboundAdapter).%New(), tAdapter.BusinessHost=..%New()
				Set resp=tAdapter.faultStream(tSC)
			}
		}
	}
	try {
		If $IsObject(resp) {
			If resp.%Extends("%Library.AbstractStream") {
				Set %response.Status=$G(resp.Attributes("ResponseCode"),$G(resp("ResponseCode"),"200 OK"))
				Set attr="" For { Set attr=$O(resp.Attributes(attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
					If (upattr="CONTENT-TYPE") {Set %response.ContentType=val Continue}
					Continue:$Case(upattr,"RESPONSECODE":1, :$D(upattrs(upattr)))
					Set attrs(attr)=val, upattrs(upattr)=""
				}
			} Else {
				Set %response.Status=$G(resp("ResponseCode"),"200 OK")
			}
		} Else {
			Set %response.Status=$G(resp("ResponseCode"),"200 OK")
		}
		/* Do not pass back transfer-encoding header if chunked nor content-encoding header if gzip to CSP Gateway */
		Set attr="" For { Set attr=$O(resp(attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
			If (upattr="CONTENT-TYPE") {Set %response.ContentType=val Continue}
			Continue:$Case(upattr,"RESPONSECODE":1,  "TRANSFER-ENCODING":"CHUNKED"=$ZCVT(val,"U"), "CONTENT-ENCODING":"GZIP"=$ZCVT(val,"U"), :$D(upattrs(upattr)))
			Set attrs(attr)=val, upattrs(upattr)=""
		}
		Set attr="" For { Set attr=$O(attrs(attr),1,val)  Quit:""=attr
			If $ZCVT(attr,"U")="STATUSLINE" {
				Set %response.Status=$P(val," ",2,999)
			} Else {
				Do %response.SetHeader(attr,val)
			}
		}
		#;The default for %CSP.Response::NoCharSetConvert is 0. If it is 0 then use the instance property
		Try {If %response.NoCharSetConvert=0,tInstance.CSPNoCharSetConvert Set %response.NoCharSetConvert = 1} Catch {}
		Set tSC=%response.WriteHTTPHeader(1)
		If $IsObject(resp) {
			Do:$$$ISOK(tSC) resp.OutputToDevice()
		} Else {
			Write:""'=resp&&$$$ISOK(tSC) resp
		}
	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit:$$$ISERR(tSC) 0
	Quit 1
}

/// If called from CSP OnPage and not from Adapter, get attributes from the %request object
ClassMethod addAttributesToBody(ByRef pStream As %Stream.Object, pApplyCharset As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC= $$$OK
	Try {
		Set tCmd=%request.Method
		#;Origins based on code in HTTP InboundAdapter.
		Set buf=$G(%request.CgiEnvs("QUERY_STRING"))
		Set tURL=%request.URL
		Set pStream.Attributes("URL")=tURL
		Set pStream.Attributes("RawParams")=buf
		Set pStream.Attributes("HttpRequest")=tCmd, pStream.Attributes("HttpRequest",$S(""=tCmd:"ERR",1:tCmd))=tURL
		Set (i,j)=0  While ""'=buf {
			Set tVal=$P(buf,"&"), $E(buf,1,$L(tVal)+1)=""
			Set i=i+1, pStream.Attributes("IParams",i)=$ZCVT(tVal,"I","URL")
			Set tKey=$P(tVal,"="), $E(tVal,1,$L(tKey)+1)=""
			Set tKey=$ZCVT(tKey,"I","URL")
			Continue:""=tKey
			Try {
				Set inst=pStream.Attributes("Params",tKey)+1
			} Catch {
				#;Undefined if more than 1 arg and not defined
				Set inst=1
			}
			Set:1=inst j=j+1
			Set pStream.Attributes("Params",tKey)=inst
			Set pStream.Attributes("Params",tKey,inst)=$ZCVT(tVal,"I","URL")
		}
		Set pStream.Attributes("Params")=j
		Set pStream.Attributes("IParams")=i
		$$$sysTRACE("Got HTTP Request '"_pStream.Attributes("HttpRequest")_" "_tURL_"'")
		Set pStream.Attributes("HTTPVersion")=$P(%request.Protocol,"/",2)
		Set tLen="x", tContentType=""
		#dim tgzip = 0
		If %request.IsDefinedCgiEnv("ALL_RAW") {
			Set tRawHeaders = %request.GetCgiEnv("ALL_RAW")
			Set tRawLen = $L(tRawHeaders,$C(13,10))
			For tC = 1:1:tRawLen {
				Set tAttrAndVal = $P(tRawHeaders,$C(13,10),tC)
				Set attr = $ZSTRIP($P(tAttrAndVal,":",1),"<>W"), attrVal = $ZSTRIP($P(tAttrAndVal,":",2,*),"<>W")
				Set lwrattr = $ZCVT(attr,"L")
				If (attr'=""),(lwrattr'="url"),(lwrattr'="version") {
					If '((lwrattr="transfer-encoding")&&($ZCVT(attrVal,"L")="chunked")),'((lwrattr="content-encoding")&&($ZCVT(attrVal,"L")="gzip")) {
						Set:..#TOLOWERHEADERVARS attr=lwrattr
						Set:'$D(lwrattrs(lwrattr)) pStream.Attributes(attr)=attrVal, lwrattrs(lwrattr)=""
						Set:"content-length"=lwrattr tLen=pStream.Attributes(attr)
						Set:"content-type"=lwrattr tContentType=pStream.Attributes(attr)
					} ElseIf (lwrattr="content-encoding") {
						Set tgzip = 1
					} ElseIf tLen = "x" {
						Set tLen="xchunked"
					}
				}
			}
		} Else {
			Set tattrH=$O(%request.CgiEnvs("HTTP_"))
			While $E(tattrH,1,5)="HTTP_" {
				If tattrH'="HTTP_URL",tattrH'="HTTP_VERSION" {
					Set attr=$REPLACE($E(tattrH,6,*),"_","-"), lwrattr=$ZCVT(attr,"L")
					If '((lwrattr="transfer-encoding")&&($ZCVT(%request.CgiEnvs(tattrH),"L")="chunked")),'((lwrattr="content-encoding")&&($ZCVT(%request.CgiEnvs(tattrH),"L")="gzip")) {
						Set:..#TOLOWERHEADERVARS attr=lwrattr
						Set:'$D(lwrattrs(lwrattr)) pStream.Attributes(attr)=%request.CgiEnvs(tattrH), lwrattrs(lwrattr)=""
						Set:"content-length"=lwrattr tLen=pStream.Attributes(attr)
						Set:"content-type"=lwrattr tContentType=pStream.Attributes(attr)
					} ElseIf (lwrattr="content-encoding") {
						Set tgzip = 1
					} ElseIf tLen = "x" {
						Set tLen="xchunked"
					}
				}
				Set tattrH=$O(%request.CgiEnvs(tattrH))
			}
		}
		If (tContentType="") {
			Set attr="CONTENT-TYPE", lwrattr="content-type"
			Set:..#TOLOWERHEADERVARS attr=lwrattr
			Set tContentType=$G(%request.CgiEnvs("CONTENT_TYPE"))
			Set:'$D(lwrattrs(lwrattr)) pStream.Attributes(attr)=tContentType
		}
		If ($Extract(tLen)="x") || tgzip {
			Set attr="CONTENT-LENGTH", lwrattr="content-length"
			Set:..#TOLOWERHEADERVARS attr=lwrattr
			If tgzip {
				#; Reset length since unzipped
				Set pStream.Attributes(attr)=pStream.Size
			} ElseIf '$D(lwrattrs(lwrattr)) {
				If ($Extract(tLen,2,*)="chunked") {
					Set pStream.Attributes(attr)=pStream.Size
				} Else {
					Set pStream.Attributes(attr)=$G(%request.CgiEnvs("CONTENT_LENGTH"))
				}
			}
		}
		Set tCharset=$P($ZCVT(tContentType,"L"),"charset=",2), tCharset=$TR($P(tCharset,";"),"""","")
		Set tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable($Case($ZCVT(tCharset,"L"),"":"rawbytes","binary":"rawbytes",:tCharset))
		If ""=tTable Set tTable="RAW" $$$LOGWARNING("Unable to find Translation Table for charset "_tCharset)
		If "post"=$ZCVT(tCmd,"L") && ..#PARSEBODYFORMVARS {
			Do pStream.Rewind()
			Set buf="", i=pStream.GetAttribute("IParams",0), j=pStream.GetAttribute("Params",0)
			For {
				Set buf=buf_pStream.Read(32000-$L(buf),.tSC)  Quit:$$$ISERR(tSC)||'$L(buf)
				Set tVal=$P(buf,"&"), $E(buf,1,$L(tVal)+1)=""
				Set i=i+1, pStream.Attributes("IParams",i)=$ZCVT(tVal,"I","URL")
				Set tKey=$P(tVal,"="), $E(tVal,1,$L(tKey)+1)=""
				Set tKey=$ZCVT(tKey,"I","URL")
				Continue:""=tKey
				Try {
					Set inst=pStream.Attributes("Params",tKey)+1
				} Catch {
					#;Undefined if more than 1 arg and not defined
					Set inst=1
				}
				Set:1=inst j=j+1
				Set pStream.Attributes("Params",tKey)=inst
				Set pStream.Attributes("Params",tKey,inst)=$ZCVT(tVal,"I","URL")
			}
			Set pStream.Attributes("Params")=j
			Set pStream.Attributes("IParams")=i
		}
		Set pStream.Attributes("CharEncoding")=tCharset
		Set pStream.Attributes("TranslationTable")=tTable

		// If not RAW, apply the CharSet convertion
		// Charset is provided by the Content-Type header, not the inbound adapter
		If pApplyCharset && ("RAW"'=tTable) {
			// In order to resolve the correct Type field in the HTTPMessage,
			// the correct stream type is needed
			Set tStream = ##class(%GlobalCharacterStream).%New()  $$$ASSERT($IsObject(tStream))
			Set tSC = tStream.CopyFrom(pStream)
			Return:$$$ISERR(tSC) tSC
			Merge tStream.Attributes = pStream.Attributes
			Set pStream = tStream

			Set tSC = ##class(EnsLib.HTTP.InboundAdapter).ApplyCharset(pStream, tTable)
			Return:$$$ISERR(tSC) tSC
		}
	} Catch {
		Set tSC = $$$EnsSystemError
	}
	Quit tSC
}

/// Control the type and content of error returned to the HTTP caller
ClassMethod OnErrorStream(pStatus As %Status, pInstance As EnsLib.HTTP.Service)
{
	Set tStream = ##class(%GlobalBinaryStream).%New()  $$$ASSERT($IsObject(tStream))
	Set tStream.Attributes("Content-Type")=" text/plain; charset=""UTF-8"""
	Set tStream.Attributes("ResponseCode")="500 Internal Server Error"
	Quit tStream
}

/// Callback after a HTTP request. This callback is meant to be used by InterSystems IRIS and should thus never be overridden in a subclass.
ClassMethod OnPostHTTP() [ Internal ]
{
}

ClassMethod OnPageError(ByRef pStatus As %Status)
{
	Quit pStatus
}

/// Callback for allowing Service to override and control construction of the HTTP response if invoked via the HTTP Inbound Adapter
/// Override this method in your Service class to customize the HTTP response <p/>
/// Each argument may be overridden to change a particular aspect of the HTTP response
/// <var>pStatus</var> is the status code that resulted from the HTTP call to the adapter
/// <var>pHTTPResponseStatus</var> is the HTTP status that will be reported to the HTTP client
/// <var>pBodyLen</var> is the response body size in bytes that will be reported to the HTTP client
/// <var>pResponseBodyStream</var> is the stream or string whose contents will be returned as the HTTP response message body
/// <var>pMainResponseHeader</var> if returned with content will be used verbatim as the HTTP header
/// <var>pHeaderExtra</var>  if returned will be used to override the standard no-cache header declarations or append to <var>pMainResponseHeader</var>
Method OnAdapterHTTPResponse(ByRef pStatus As %Status, ByRef pHTTPResponseStatus As %String, ByRef pBodyLen As %Integer, ByRef pResponseBodyStream As %Stream.Object, ByRef pMainResponseHeader As %String, ByRef pHeaderExtra As %String) [ Abstract ]
{
}

/// Put %request.MimeData into pBody if %request.MimeData contains at least one MPC
/// Do not generate a boundary if not in the source.
ClassMethod restoreMultipart(ByRef pBody As %Stream.Object = "", Output pBoundary As %String = "")
{
#dim %request As %CSP.Request
	Set tSC = $$$OK
	Try {
		#; Look for existing boundary name
		Set tKey = ""
		If pBody.IsDefinedAttribute("content-type") {
			Set tKey = "content-type"
		} ElseIf pBody.IsDefinedAttribute("Content-Type") {
			Set tKey = "Content-Type"
		} ElseIf pBody.IsDefinedAttribute("CONTENT-TYPE") {
			Set tKey = "CONTENT-TYPE"
		}
		Set pBoundary = "", tCount = 0

		If (tKey'="") {
			Set tBoundaryCT = pBody.GetAttribute(tKey)
			Set tBoundPos = $F($ZCVT(tBoundaryCT,"L"),"boundary")
			If (tBoundPos>0) {
				#; need to remove double quotes since these are not included when used 
				#; to recreate the multipart body with boundary encapsulation.
				#; Example- Content-Type: multipart/form-data; boundary="----=_Part_0_1348917575.1714179502564"
				Set pBoundary = $ZSTRIP($P($P($E(tBoundaryCT,tBoundPos,*),"=",2,*),";"),"<>W",$C(34))
			}
		}
		/* Put back form from .Data array */
		Set tSC = ..findDataNotInQuery(.tDataPairs)
		If $$$ISERR(tSC) Quit
		If $D(tDataPairs) {
			Set tPos=$O(tDataPairs(""),1,tLBVal)
			While (tPos'="") {
				Set tCount = tCount+1
				If (tCount>1) {Do pBody.WriteLine()}
				If (pBoundary'="") {Do pBody.WriteLine("--"_pBoundary)}
				Set tDataName = $LG(tLBVal,1)
				Set tDataValue = $G(%request.Data(tDataName,$LG(tLBVal,2)))
				Do pBody.WriteLine("Content-Disposition: form-data; name="_$C(34)_$zconvert(tDataName,"O","URL")_$C(34))
				Do pBody.WriteLine()
				Do pBody.Write(tDataValue)
				Set tPos=$O(tDataPairs(tPos),1,tLBVal)
			}
		}
		/* Put back MimeData */
		Set tMimeName = %request.NextMimeData("")
		While (tMimeName'="") {
			Set tMimeNameIndex = %request.NextMimeDataIndex(tMimeName,"")
			While (tMimeNameIndex'="") {
				Set tMimeStream = %request.GetMimeData(tMimeName,"",tMimeNameIndex)
				Set tMimeContent = ##class(%Net.MIMEPart).%New()
				Set tCount = tCount+1
				If (pBoundary'=""),(tCount>1) {Do pBody.WriteLine()}
				If $IsObject(tMimeStream) {
					If (pBoundary'="") {Do pBody.WriteLine("--"_pBoundary)}
					Try {
						Set headers=$tr(tMimeStream.GetAttribute("Headers"),$c(13),"")
					} Catch {
						Set headers=""
					}
					If headers'="" {
						Set len=$length(headers,$c(10))
						For i=1:1:len {
							Set header=$piece(headers,$c(10),i)
							Set name=$zstrip($piece(header,":",1),"<>W")
							#; Only expect 1 : on each line but take to end of header line
							Set value=$zstrip($piece(header,":",2,*),"<>W")
							Do pBody.WriteLine(name_": "_value)
						}
					}
					If (pBoundary'="") Do pBody.WriteLine("")
					#; We do not want the attributes back in the main body so do not use CopyFrom()
					Do tMimeStream.Rewind()
					Set tSC=$$$OK,sc2=$$$OK
					If tMimeStream.%Extends("%IO.I.Stream") {
						For  Quit:(tMimeStream.AtEnd)||($$$ISERR(tSC)||($$$ISERR(sc2)))  Set tSC=pBody.Write(tMimeStream.Read(32656,,.sc2))
					} Else {
						For  Quit:(tMimeStream.AtEnd)||($$$ISERR(tSC)||($$$ISERR(sc2)))  Set tSC=pBody.Write(tMimeStream.Read(32656,.sc2))
					}
					If $$$ISERR(sc2) Set tSC = $$$ADDSC(tSC, sc2)
					If $$$ISERR(tSC) Quit
				} Else {
					If (pBoundary'="") {Do pBody.WriteLine("--"_pBoundary)}
					Do pBody.WriteLine("")
					Do pBody.WriteLine(tMimeStream)
				}
				Set tMimeNameIndex = %request.NextMimeDataIndex(tMimeName,tMimeNameIndex)
			}
			Set tMimeName = %request.NextMimeData(tMimeName)
		}
		/* Write closing boundary */
		If tCount,(pBoundary'="") {Do pBody.WriteLine() Do pBody.WriteLine("--"_pBoundary_"--")}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Put form urlencoded data back into the body since it is parsed in .Data array
ClassMethod restoreFormEncoded(pBody As %Stream.Object = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..findDataNotInQuery(.tDataPairs)
		If $$$ISERR(tSC) Quit
		If $D(tDataPairs) {
			Set tPos=$O(tDataPairs(""),1,tLBVal), tFirst=1
			While (tPos'="") {
				Set tDataName = $LG(tLBVal,1)
				Set tDataValue = $G(%request.Data(tDataName,$LG(tLBVal,2)))
				Do pBody.Write($select(tFirst:"",1:"&")_$zconvert(tDataName,"O","URL")_"=")
				Set tFirst=0
				If $isobject(tDataValue),tDataValue.%Extends("%Stream.Object") {
					While 'tDataValue.AtEnd {
						Set data=tDataValue.Read(8096) Do pBody.Write($zconvert(data,"O","URL"))
					}
				} Else {
					Do pBody.Write($zconvert(tDataValue,"O","URL"))
				}
				Set tPos=$O(tDataPairs(tPos),1,tLBVal)
			}
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Helper method to compare %request.Data with Query string parameters.
ClassMethod findDataNotInQuery(Output pDataPairs As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tQueryString = %request.GetCgiEnv("QUERY_STRING")
		Set tDataName=$O(%request.Data(""))
		While (tDataName'="") {
			Set tDataNameIndex=$O(%request.Data(tDataName,""),1,tVal)
			While (tDataNameIndex'="") {
				If (tQueryString'[(tDataName_"="_tVal)) {
					Set tPos = $G(%request.Data(tDataName,tDataNameIndex,0),$I(tNoPos,-1))
					Set pDataPairs(tPos)=$LB(tDataName,tDataNameIndex) ;Could be an oref so store pointer
				}
				Set tDataNameIndex=$O(%request.Data(tDataName,tDataNameIndex),1,tVal)
			}
			Set tDataName=$O(%request.Data(tDataName))
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

}
