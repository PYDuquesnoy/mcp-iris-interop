/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Generic WebService-based BusinessService class. Can use a SOAP.InboundAdapter listener, or the standard SOAP Service mechanism, or both.
/// In order for the CSP mechanism to work, Web Services using this class must be configured with the invoking URL including ?CfgItem= giving the config item name.
/// (Configured Web Services exposed using the SOAP Inbound Adapter may also be invoked with this URL parameter but because
///  each configured Inbound Adapter listens on its own TCP/IP port this parameter is just a safety check for them.)
Class EnsLib.SOAP.GenericService Extends EnsLib.SOAP.Service [ System = 4 ]
{

Parameter DOCCLASS = "EnsLib.SOAP.GenericMessage";

/// Apply standard processing to SOAP headers; otherwise just pass them through
Property ProcessHeaders As %Boolean;

/// Configuration item to which to send messages
Property TargetConfigName As Ens.DataType.ConfigName;

/// Store a set of searchable properties associated with each XML Document processed.<br>
/// These records will be stored in the named SearchTable class, if any.
Property SearchTableClass As %String;

/// Name of imported WSDL to use in describing the request document body types that may be received by this service
Property WSDL As %String;

/// Schema type to use for the SOAP Envelope element and the Header elements it contains
Property HeaderDocType As %String;

/// Specifies types of Validation to perform.
/// Set to non-empty to invoke OnValidate() in your subclass. You may add it to SETTINGS in your subclass if you want to distinguish several types of validation.
Property Validation As %String;

Parameter SETTINGS = "TargetConfigName:Basic:selector?multiSelect=0&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},ProcessHeaders,SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.XML.Service.Standard},PersistInProcData:Additional,KeepCSPPartition:Additional,OneWay:Additional";

/// Format options to apply if we need to output an XML VDoc object as a Stream
Property %VDocFormat As %String;

/// Category of SearchTable specified in ..SearchTableClass
Property %SearchTableType As %String;

/// Comma separated list of response HTTP Headers from the external systems not to be 
/// passed back to the requesting service.
/// The values are case-insensitive.
/// The appropriate Content-Length will be used and ought not be specified here.
Property %ExcludeResponseHttpHeaders As %String(MAXLEN = "");

/// OneWay is true if no response is to be given.
/// If the request is queued successfully to the target an HTTP/1.1 202 Accepted will be returned.
Property OneWay As %Boolean [ Internal, Transient ];

/// Set this to 0 to prevent normalizing of HTTP header variable names to lowercase
Parameter TOLOWERHEADERVARS = 1;

Parameter SECURITYIN = "NOHEADER";

/// Response stream size below which the response body should be scanned for namespace prefix instances so that unused declarations from the header can be omitted from the body
Parameter NSWinnowSizeThreshold As %Integer = 7500;

/// Persist data to operations with invocation InProc that are called Synchronously.<br/>
/// The default is On. <br/>
/// This setting is only used if calling an operation with invocation InProc. <br/>
/// If this setting is off then no message headers will be created and message bodies will not be saved.<br/>
/// If this setting is off there will be no trace in the message viewer. <br/>
/// If this setting is off there will be no retry attempts by the operation - only one attempt will be made. <br/> 
Property PersistInProcData As %Boolean [ InitialExpression = 1 ];

/// When calling the service through the CSP WebServer (Standard Request) and the target of the
/// service is a business operation invoked InProc then it is possible to attempt to maintain connection
/// to the external system defined in the operation in between messages by setting this to true.<br>
/// There is still the possibility that the external system will close the connection.<br/>
/// The default is On. <br/>
Property KeepCSPPartition As %Boolean [ InitialExpression = 1 ];

/// This user callback method is called via initConfig() from %OnNew() or in the case of CSP invoked services from OnPreSOAP()
Method OnInit() As %Status
{
	If $IsObject(..Adapter) {
		Set ..Adapter.%SplitBody=1+'..ProcessHeaders
		Set ..Adapter.%ToLowerHeaderVars=..#TOLOWERHEADERVARS
	}
	If ""=..TargetConfigName { $$$LOGWARNING("No Target Config Name configured") }
	Set ..%SearchTableType=$S(""=..SearchTableClass:""
							, $classmethod(..SearchTableClass,"%Extends","EnsLib.XML.SearchTable"):"XML"
							, $classmethod(..SearchTableClass,"%Extends","EnsLib.EDI.XML.SearchTable"):"VDOC"
							, 1:"MSG")
	Set $$$EnsInProcPersist=..PersistInProcData
	Quit ##super()
}

/// Pass through to OnProcessInput()
Method ProcessBody(pAction As %String, pRequestBody As %CharacterStream, pResponseBody As %CharacterStream) As %Boolean
{
	Set tSC=..ProcessInput(pRequestBody,.pResponseBody,pAction)
	Quit 1
}

Method OnProcessInput(pRequestBody As %CharacterStream, pResponseBody As %CharacterStream, ByRef pAction As %String) As %Status
{
 #Dim tResponse As GenericMessage

	Set pResponseBody=$$$NULLOREF
	Set tRequest=##class(EnsLib.SOAP.GenericMessage).%New(pRequestBody,,"%iaHeader",pRequestBody.GetAttribute("EnvelopeStream"),,##class(EnsLib.EDI.XML.Document).%New(..ImportHandler))
	If $D(pRequestBody.Attributes("CSPApplication")) {
		Do tRequest.HTTPHeaders.SetAt(pRequestBody.Attributes("CSPApplication"),"CSPApplication")
		Do tRequest.HTTPHeaders.SetAt(..%ConfigName,"EnsConfigName")
	}
	Set tSC=..resolveAndIndex(tRequest)  Quit:$$$ISERR(tSC) tSC
	
	If $$$IsdefObject(%request),..KeepCSPPartition,$D($$$EnsLocalCache($$$EnsJobLocal("ConfigName"))) {
		#; If called from CSP check if cached InProc object. No need to do this if not keeping CSP Gateway partition
		Merge $$$EnsJobLocal("CachedObject")=$$$EnsLocalCache($$$EnsJobLocal("ConfigName"),"CachedObject")
		Merge $$$EnsJobLocal("CachedChecksum")=$$$EnsLocalCache($$$EnsJobLocal("ConfigName"),"CachedChecksum")
		Kill $$$EnsLocalCache($$$EnsJobLocal("ConfigName"))
	}

	Quit:..OneWay ..SendRequestAsync(..TargetConfigName,tRequest)

	Set tSC=..SendRequestSync(..TargetConfigName,tRequest,.tResponse)  Quit:$$$ISERR(tSC) tSC

	If $$$IsdefObject(%request) {
		#; Since a CSP job can become multiple business services need to preserve even if current BS does not specify it.
		If ($D($$$EnsLocalCacheRoot)||(..KeepCSPPartition&&$D($$$EnsJobLocal("CachedObject")))) {
			Set %response.AvoidPartitionCleanup=1
		}
	}

	#; Adapter will reassemble response stream from message envelope/header and body streams; here we prepare the streams
	If $IsObject(tResponse.EnvelopeDoc) && ('$IsObject(tResponse.EnvelopeStream) || 'tResponse.EnvelopeStream.Size) {
		Set tEnvelopeStream=##class(%GlobalBinaryStream).%New()
		Set tSC=tResponse.EnvelopeDoc.OutputToLibraryStream(tEnvelopeStream,..%VDocFormat)
		Do:$$$ISERR(tSC) ..ReturnMethodStatusFault(tSC)
	} Else {
		Set tEnvelopeStream=tResponse.EnvelopeStream
	}
	If $IsObject(tResponse.Doc) && ('$IsObject(tResponse.Stream) || 'tResponse.Stream.Size) {
		Set pResponseBody=##class(%GlobalCharacterStream).%New()
		Set tSC=tResponse.Doc.OutputToLibraryStream(pResponseBody,..%VDocFormat)
		Do:$$$ISERR(tSC) ..ReturnMethodStatusFault(tSC)
	} Else {
		Set pResponseBody=tResponse.Stream
		Set:'$IsObject(pResponseBody) pResponseBody=##class(%GlobalCharacterStream).%New()
	}
	If ""'=tEnvelopeStream&&tEnvelopeStream.Size {
		Set pResponseBody("EnvelopeStream")=tEnvelopeStream
	} Else { Set tEnvelopeStream=pResponseBody } ; just to attach headers to

	#; Pass along Status line and selected response HTTP headers
	Set tSL="",tDoNotPassThrough=","_$ZCVT(..%ExcludeResponseHttpHeaders,"L")_",content-length,"
	Set tHeaderKey="" For { Set tHeaderKey=tResponse.HTTPHeaders.Next(tHeaderKey)  Quit:""=tHeaderKey  Set tHeaderLwr=$ZCVT(tHeaderKey,"L")
		Set:tDoNotPassThrough'[(","_tHeaderLwr_",") tEnvelopeStream("HTTPHeaders",tHeaderKey)=tResponse.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="statusline" tSL=tResponse.HTTPHeaders.GetAt(tHeaderKey)
	}
	Set:tDoNotPassThrough'["statusline"&&$L(tSL) tEnvelopeStream("StatusLine")=tSL
	If (pResponseBody=tEnvelopeStream) {
		Merge pResponseBody=tEnvelopeStream
	} ElseIf (pResponseBody("EnvelopeStream")=tEnvelopeStream) {
        Merge pResponseBody("EnvelopeStream","HTTPHeaders")=tEnvelopeStream("HTTPHeaders")
    } 
	Quit tSC
}

/// Control the type and content of error returned to the SOAP caller
ClassMethod OnErrorStream(pStatus As %Status, pInstance As EnsLib.SOAP.Service, pSOAPVer As %String = "1.0")
{
	Set tStream = ##class(%GlobalBinaryStream).%New()  $$$ASSERT($IsObject(tStream))
	Do tStream.Write(pInstance.OnFaultString(pStatus,pInstance,pSOAPVer))
	Quit tStream
}

/// Override this method to implement your own custom method for validating an incoming Document
/// Return non-zero to prevent default validation of the message (if any);
Method OnValidate(pMsg As EnsLib.SOAP.GenericMessage, pValSpec As %String, Output pStatus As %Status) As %Boolean
{
	Quit 0
}

/// Override this method to implement your own custom method for resolving the DocType of an incoming Message
/// Returning nonzero means you are overriding the framework's standard DocType resolution.
Method OnResolveDocType(pMsg As EnsLib.SOAP.GenericMessage, ByRef pDocType As %String, ByRef pHeaderDocType As %String) As %Boolean
{
	Quit 0
}

/// Accept only specified document names; resolve DocType and perform requested validation if any
Method resolveAndIndex(pMsg As EnsLib.SOAP.GenericMessage) As %Status
{
	Set tSC=$$$OK, tDocType=..resolveDocType(pMsg,.tEnvelopeDocType)
	If ""'=tDocType {
		Set pMsg.Doc=##class(EnsLib.EDI.XML.Document).ImportFromLibraryStream(pMsg.Stream,.tSC)
		Set pMsg.Doc.DocType=tDocType
	}
	If ""'=$G(tEnvelopeDocType) {
		If '$IsObject(pMsg.EnvelopeDoc) {
			Set pMsg.EnvelopeDoc=##class(EnsLib.EDI.XML.Document).ImportFromLibraryStream(pMsg.EnvelopeStream,.tSC)
		}
		Set pMsg.EnvelopeDoc.DocType=tEnvelopeDocType
	}

	#; Do further validation if required
	If ""'=..Validation&&'..OnValidate(pMsg,..Validation,.tSC) {
		#; no default validation
	}
	Quit:$$$ISERR(tSC) tSC

	If ""'=..SearchTableClass {
		TRY {
			Set tObj=$Case(..%SearchTableType, "VDOC":pMsg.Doc, :pMsg)
			Set:$IsObject(tObj) tSCStore=$classmethod(..SearchTableClass,"IndexDoc",tObj)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_tObj_"/"_tObj.%Id()_$S(..%SearchTableType="VDOC":" with DocType='"_tObj.DocType_"'",1:"")_" using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_tObj_"/"_tObj.%Id()_" with DocType='"_tObj.DocType_"' : "_errobj.AsSystemError()) }
	}
	Quit tSC
}

/// Return the DocType that this service will assign to this message's body document
Method resolveDocType(pMsg As EnsLib.SOAP.GenericMessage, Output pHeaderDocType As %String) As %String
{
	/// Subclass responsibility
	Set pHeaderDocType=""
	Quit ""
}

/// Callback for allowing Service to override and control construction of the HTTP response if invoked via the SOAP Inbound Adapter
/// Split www-authenticate HTTP header and add proxy-support header if needed
Method OnAdapterHTTPResponse(ByRef pStatus As %Status, ByRef pHTTPResponseStatus As %String, ByRef pBodyLen As %Integer, ByRef pResponseBodyStream As %Stream.Object, ByRef pMainResponseHeader As %String, ByRef pHeaderExtra As %String)
{
	Set pos=$F($ZCVT(pHeaderExtra,"L"),"www-authenticate: ")
	If pos {
		Set auth=$E(pHeaderExtra,pos-$L("www-authenticate: "),pos-1)
		Set pos2=$F(pHeaderExtra,$C(13,10),pos)
		Set pos2=$S(pos2:pos2-3,1:$L(pHeaderExtra))
		Set val=$E(pHeaderExtra,pos,pos2), tCount=$L(val,",")
		For i = 1:1:tCount { Set iVal=$ZStrip($P(val,",",i),"<>W")  Continue:""=iVal
			If i=1 { Set newHdr=iVal_$C(13,10) }
			Else { Set newHdr=newHdr_auth_iVal_$C(13,10) }
		}
		Set $E(pHeaderExtra,pos,pos2) = $E(newHdr,1,*-2)
	}
	Set:($P(pMainResponseHeader,$C(13,10))["401") pHeaderExtra = pHeaderExtra_"Proxy-support: Session-Based-Authentication"_$C(13,10)
}

/// Ensure no call to %response.WriteHTTPHeader() before OnPage(); ServerOnly and not Abstract to ensure $$$cMETHrunnable
ClassMethod OnHTTPHeader(ByRef OutputBody As %Boolean) As %Status [ ServerOnly = 1 ]
{
	#; Send the CSP information header down if this is the CSP Gateway request since we are not calling WriteHTTPHeader()
	Do:%request.CSPGatewayRequest %response.OutputCSPGatewayData()
	Quit $$$OK
}

/// Override to do stream split & rejoin, passthrough HTTP Response
Method Process(pAction As %String, ByRef request, needHeaders As %Boolean = 1) [ ServerOnly = 1 ]
{
	// Indicate that we are in web service
	Set %cspsoapservice=$this
	Do %request.Content.Rewind()
	Kill %iaHeader

	Set %iaHeader("URL")=%request.URL
	Set %iaHeader("HttpRequest")=%request.Method, %iaHeader("HttpRequest",%iaHeader("HttpRequest"),"ERR")=%request.URL

	$$$sysTRACE("Got SOAP Request '"_%iaHeader("HttpRequest")_" "_%request.URL_"'")
	Set %iaHeader("HTTPVersion")=$P(%request.Protocol,"/",2)

	Set tLen=%request.Content.Size

	Set (tContentType,tAction)=""
	
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
					Set:'$D(lwrattrs(lwrattr)) %iaHeader(attr)=attrVal, lwrattrs(lwrattr)=""
					Set:"content-type"=lwrattr tContentType=%iaHeader(attr)
					Set:"soapaction"=lwrattr tAction=%iaHeader(attr)
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
					Set:'$D(lwrattrs(lwrattr)) %iaHeader(attr)=%request.CgiEnvs(tattrH), lwrattrs(lwrattr)=""
					Set:"content-type"=lwrattr tContentType=%iaHeader(attr)
					Set:"soapaction"=lwrattr tAction=%iaHeader(attr)
				}
			}
			Set tattrH=$O(%request.CgiEnvs(tattrH))
		}
	}
	If (tContentType="") {
		Set attr="CONTENT-TYPE", lwrattr="content-type"
		Set:..#TOLOWERHEADERVARS attr=lwrattr
		Set tContentType=$G(%request.CgiEnvs("CONTENT_TYPE"))
		Set:'$D(lwrattrs(lwrattr)) %iaHeader(attr)=tContentType, lwrattrs(lwrattr)=""
	}

	Set attr="CONTENT-LENGTH", lwrattr="content-length"
	Set:..#TOLOWERHEADERVARS attr=lwrattr
	Set:'$D(lwrattrs(lwrattr)) %iaHeader(attr)=tLen, lwrattrs(lwrattr)=""

	Set tCharset=$P($ZCVT(tContentType,"L"),"charset=",2), tCharset=$P(tCharset,";")
	Set tSOAP12=tContentType["application/soap+xml"
	If ""=tAction {
		If 'tSOAP12 { Set tSC = $$$ERROR($$$EnsErrGeneral,"No SOAPAction in SOAP Request HTTP header") Quit tSC} ; no Action required in HTTP headers for SOAP 1.2
		Set tAction=$P(tContentType,"action=",2)
		If """"=$E(tAction) { Set tAction=$P(tAction,"""",2) }
		Else { Set tAction=$ZStrip($P(tAction,";"),"<>W") }
	}

	$$$sysTRACE("For action='"_tAction_"' got content-length="_tLen)

	#; split body and envelope into separate streams
	If 'tLen {
		Set %iaStream=$$$NULLOREF
	} Else {
		// copy post-header part in, loop writing into stream until done
		Set %iaStream = ##class(%Library.GlobalBinaryStream).%New()  $$$ASSERT($IsObject(%iaStream))
		Set tSC=..splitEnvelopeStream(%request.Content,%iaStream,.tBodyStream)  Quit:$$$ISERR(tSC) tSC
		#; set body stream reference as attribute of envelope stream
		Set:$$$IsdefObject(tBodyStream) %iaStream.Attributes("BodyStream")=tBodyStream, tBodyStream.Attributes("EnvelopeStream")=%iaStream
		$$$sysTRACE("Got CSP body("_%iaStream.Size_")")
	}
	If ..ProcessHeaders {
		If '$isobject($get(%cspsoapservice)) {
			Do ..Initialize(pAction,%iaStream,.soapImportHandler,.username,.password,.soapSecurityNamespace,.soapFault)
			Set ..ImportHandler=soapImportHandler
			Set ..Username=username
			Set ..Password=password
			Set ..SecurityNamespace=soapSecurityNamespace
			Set ..SoapFault=soapFault
		}
		Set ..SecurityIn=%cspsoapSecurityHeader
		Kill %cspsoapSecurityHeader
	}

	If $IsObject(%iaStream) { Do %iaStream.Rewind() }
	Else { Set %iaStream = ##class(%Library.GlobalCharacterStream).%New() }
	Set tRequestBody = $G(%iaStream.Attributes("BodyStream"),%iaStream)
	Set tRequestBody.Attributes("CSPApplication")=%request.Application
	Do ..ProcessBody(tAction,tRequestBody,.tStreamOut)
	Set tLen=$S($IsObject(tStreamOut):tStreamOut.Size,1:$L(tStreamOut))

WriteResp
	If ""'=%request.URL {
		#; Note: if the Service executed its ReturnFault() method (directly or indirectly) then control will never arrive here
		#; Note: tStreamOut is always an object if the standard OnSOAPRequest() was executed, so we will only construct our own fault if the Service returned an error but neither called ReturnFault() nor Fault() to write fault content to tStreamOut.
		Set:($$$ISOK(tSC)&&'..OneWay) tSC=..prepJoinedResponse(.tStreamOut,.tBodyStreamOut,tSOAP12,.tLen,.tBodyTagLen,.tNewBodyElem,.tPreStream,.tPostStream)
		Do ..%RestoreTCPDevice()
		If $$$ISERR(tSC) {
			If ""=$G(tStreamOut)||($IsObject(tStreamOut)&&'tStreamOut.Size&&$S(tStreamOut.%Extends("%Library.AbstractStream"):'$D(tStreamOut.Attributes),1:1)) {
				Set tStreamOut=$$$NULLOREF, (tPreStream,tPostStream,tBodyStreamOut)=""
				Kill tStreamOut("EnvelopeStream")
				try {
					Set tStreamOut=..OnErrorStream(tSC,$this,$S(tSOAP12:"1.2",1:"1.1"))
				} catch {
					If $ZE'["METHOD DOES NOT EXIST" {
						Set tSC1=$$$SystemError
						Set tSC=$$$ADDSC(tSC,tSC1)
					}
				}
				Set:""=$G(tStreamOut)||($IsObject(tStreamOut)&&'tStreamOut.Size&&$S(tStreamOut.%Extends("%Library.AbstractStream"):'$D(tStreamOut.Attributes),1:1)) tStreamOut=##class(EnsLib.SOAP.InboundAdapter).faultString(tSC,$this,$S(tSOAP12:"1.2",1:"1.1"))
				Set tLen=$S($IsObject(tStreamOut):tStreamOut.Size,1:$L(tStreamOut))
			}
		}
		#; Write response header then response body
		Set $ZT="TrapW"
		Set tHeader = ""
		Set tHeaderExtra = "CACHE-CONTROL: no-cache"_$C(13,10)_
						"PRAGMA: no-cache"_$C(13,10)
		If ..OneWay&&$$$ISOK(tSC) { Set tLen=0, tCT="", tStatusLine="HTTP/1.1 202 Accepted" }
		ElseIf $D(tStreamOut)#2 {
			If $IsObject(tStreamOut) {
				$$$ASSERT(tStreamOut.%Extends("%Stream.Object"))
				Set tHeaderExtra = ""
				If tStreamOut.%Extends("%Library.AbstractStream") {
					#; Get attributes from the EnvelopeStream if not in tStreamOut
					Try {
						If '$D(tStreamOut.Attributes),tStreamOut("EnvelopeStream").%Extends("%Library.AbstractStream"){
							Merge tStreamOut.Attributes("HTTPHeaders")=tStreamOut("EnvelopeStream","HTTPHeaders")
						}
				    } Catch {}
				    #; get headers from tStreamOut attributes
					Set tCT=$G(tStreamOut.Attributes("HTTPHeaders","CONTENT-TYPE"),$G(tStreamOut.Attributes("HTTPHeaders","Content-Type"),$G(tStreamOut("CONTENT-TYPE"),$G(tStreamOut("Content-Type")))))
					Set tStatusLine=$G(tStreamOut.Attributes("STATUSLINE"),$G(tStreamOut.Attributes("StatusLine"),$G(tStreamOut("STATUSLINE"),$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut.Attributes("RESPONSECODE"),$G(tStreamOut.Attributes("ResponseCode"),$G(tStreamOut("RESPONSECODE"),$G(tStreamOut("ResponseCode"),"ZZZ"))))))))
					Set attr="" For { Set attr=$O(tStreamOut.Attributes("HTTPHeaders",attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
						Continue:'$D(val)||$Case(upattr,"ENVELOPESTREAM":1, "CONTENT-TYPE":1, "RESPONSECODE":1, "STATUSLINE":1, "TRANSFER-ENCODING":"CHUNKED"=$ZCVT(val,"U"), "CONTENT-ENCODING":"GZIP"=$ZCVT(val,"U"), :$D(upattrs(upattr)))
						Set attrs(attr)=val, upattrs(upattr)=""
					}
				} Else {
					Set tCT=$G(tStreamOut("HTTPHeaders","Content-Type")), tStatusLine=$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("ResponseCode"),"ZZZ"))
				}
			} Else {
				Set tCT=$G(tStreamOut("HTTPHeaders","Content-Type")), tStatusLine=$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("ResponseCode"),"ZZZ"))
			}
		} Else {
			Set tLen=0, tCT=$G(tStreamOut("HTTPHeaders","Content-Type")), tStatusLine=$G(tStreamOut("StatusLine"),"HTTP/1.1 "_$G(tStreamOut("ResponseCode"),"ZZZ"))
		}
		#; get headers from tStreamOut subscripts too
		Set attr="" For { Set attr=$O(tStreamOut(attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
			Continue:'$D(val)||$Case(upattr,"ENVELOPESTREAM":1, "CONTENT-TYPE":1, "RESPONSECODE":1, "STATUSLINE":1, "TRANSFER-ENCODING":"CHUNKED"=$ZCVT(val,"U"), "CONTENT-ENCODING":"GZIP"=$ZCVT(val,"U"), :$D(upattrs(upattr)))
			Set attrs(attr)=val, upattrs(upattr)=""
		}
		Set tCT=$S(""'=tCT:tCT, 0=tLen:"", tSOAP12:"application/soap+xml", 1:"text/xml")
		If ""=tHeaderExtra {
			Merge:'$D(tStreamOut("HTTPHeaders")) tStreamOut("HTTPHeaders")=attrs
			#; If response HTTP headers have been provided, use those
			Set attr="" For { Set attr=$O(tStreamOut("HTTPHeaders",attr),1,val)  Quit:""=attr  Set upattr=$ZCVT(attr,"U")
				If upattr = "CONTENT-TYPE" {
					Set tCT=val
				} ElseIf $Case(upattr,"CONTENT-LENGTH":0, "RESPONSECODE":0, "STATUSLINE":0, "TRANSFER-ENCODING":("CHUNKED"'=$ZCVT(val,"U")), "CONTENT-ENCODING":("GZIP"'=$ZCVT(val,"U")), :1) {
					#; Set others into tHeaderExtra
					Set tHeaderExtra = tHeaderExtra_attr_": "_val_$C(13,10)
				}
			}
		}
		Set:" ZZZ"=$E(tStatusLine,*-3,*) $E(tStatusLine,$L(tStatusLine)-2,$L(tStatusLine)) = $S(
			  $$$ISERR(tSC)&&("HTTP SOAP request '"=$E($$$StatusText(tSC),1,$L("HTTP SOAP request '"))):"404 Not Found"
			, $$$ISERR(tSC):"500 Internal Server Error"
			, ..OneWay:"202 Accepted"
			, 1:"200 OK")
		Set tHeader = tStatusLine_$C(13,10)_
				$S(""=tCT:"",1:"Content-Type: "_tCT_$C(13,10))_
				"Content-Length: "_tLen_$C(13,10)_
				tHeader
		try {
			Set (tHTTPResponseStatus,tRS) = $P(tStatusLine," ",2,$L(tStatusLine," "))
			Do ..OnAdapterHTTPResponse(tSC,.tHTTPResponseStatus,.tLen,.tStreamOut,.tHeader,.tHeaderExtra)
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
		Set tSC=..writeJoinedResponse(tStreamOut,.tBodyStreamOut,.tBodyTagLen,.tNewBodyElem,tPreStream,tPostStream)
		If tLen { $$$catTRACE("protocol","Wrote response body ("_tLen_")") } Else { $$$catTRACE("protocol","Empty response; no response body written") }
	}
	Set:$$$ISERR(tSC)&&$$$StatusEquals(tSC,$$$EnsErrTCPReadBlockSizeTimeoutExpired) tSC=$$$OK
Exit
	Kill %iaHeader,%iaStream
	Quit
TrapW
	#; Set $ZT="",tZE=$ZE, tSC=$S($G(tZE)["<WRITE>":$$$SystemError,1:$$$EnsSystemError)
	Goto Exit
}

/// Split inbound soap content into separate Envelope/Header and Body streams
ClassMethod splitEnvelopeStream(pStreamIn As %GlobalCharacterStream, ByRef pEnvelopeStream As %GlobalCharacterStream = {$$$NULLOREF}, ByRef pBodyStream As %GlobalCharacterStream = {$$$NULLOREF}) As %Status [ Internal ]
{
	Do ..getStartTag(pStreamIn,.tStartTag,.tPrefix,.tNSAttrs)
	If tStartTag'="Envelope" {
		Set pEnvelopeStream=pStreamIn
		Do pStreamIn.Rewind()
		Quit $$$OK  //$$$ERROR($$$EnsErrGeneral,"No SOAP Envelope found in SOAP stream "_pStreamIn.Read(1000))
	}
	#; read in whole header if any, and body start tag
	Set:'$IsObject(pEnvelopeStream) pEnvelopeStream=##class(%Library.GlobalCharacterStream).%New()
	Set tFound=..copyStreamUntil(pStreamIn,pEnvelopeStream,"<"_tPrefix_"Body",.tSC,1)  Quit:$$$ISERR(tSC) tSC
	If 'tFound {
		Set pEnvelopeStream=pStreamIn
		Do pStreamIn.Rewind()
		Quit $$$OK   //No SOAP Body found in SOAP stream "_pStreamIn.Read(1000)
	}
	#; start new body stream, copy envelope namespace declarations to Body element in new body stream, omit body contents from envelope stream
	Set pBodyStream = ##class(%GlobalCharacterStream).%New()  $$$ASSERT($IsObject(pBodyStream))
	If pStreamIn.Size-pEnvelopeStream.Size<..#NSWinnowSizeThreshold {
		#; winnow body NS declarations
		Set tTail=pStreamIn.Read(), tTailAttrs=$P(tTail,">"), $E(tTail,1,$L(tTailAttrs))="", tPos=$F(tTail,"</"_tPrefix_"Body>")-1
		Quit:tPos<=0 $$$ERROR($$$EnsErrGeneral,"Response stream missing SOAP body close tag:'..."_tTail_"'")
		Set tNSAttrs=$$winnowEnvNSAttrs(tNSAttrs,tTailAttrs,$E(tTail,1,tPos))
		#; write remainder of body into body stream
		Set tSC=pBodyStream.Write("<"_tPrefix_"Body"_tNSAttrs_$E(tTail,1,tPos))  Quit:$$$ISERR(tSC) tSC
		#; write close of dummy body and envelope close into envelope
		Set tSC=pEnvelopeStream.Write("></"_tPrefix_"Body>"_$E(tTail,tPos+1,*))  Quit:$$$ISERR(tSC) tSC
	} Else {
		#; read remainder of body into body stream
		Set tSC=pBodyStream.Write("<"_tPrefix_"Body"_tNSAttrs)  Quit:$$$ISERR(tSC) tSC
		Set tFound=..copyStreamUntil(pStreamIn,pBodyStream,"</"_tPrefix_"Body>",.tSC,1)  Quit:$$$ISERR(tSC) tSC
		#; write close of dummy body into envelope
		Set tSC=pEnvelopeStream.Write("></"_tPrefix_"Body>")  Quit:$$$ISERR(tSC) tSC
		#; finally copy envelope close onto tail of pEnvelopeStream
		Set tSC = ..copyStream(pStreamIn,pEnvelopeStream)  Quit:$$$ISERR(tSC) tSC
	}
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

/// Read from device and split response Envelope and Body into separate streams
Method readSplitEnvelopeStreamX(tLeft As %Integer, pResponse As EnsLib.SOAP.GenericMessage) As %Status [ Internal ]
{
	/*
			// copy post-header part in, loop writing into stream until done
			Set %iaStream = ##class(%Library.GlobalBinaryStream).%New()  $$$ASSERT($IsObject(%iaStream))
			Set tLeft=tLen
			If ..%SplitBody {
				#; split body and envelope into separate streams
				#; find starting element
					If 'tFound&&$$$ISOK(tSC) Set tSC=$$$ERROR($$$EnsErrGeneral,"Reached max content size while trying to read for character '>'")  Quit

					Quit:"?"'=$E(tBuf,$F(tBuf,"<")) ; if we got a <?xml ?> declaration skip it and get next element
				} Quit:$$$ISERR(tSC)
				#; find Envelope namespace prefix if any
				Set tPrefix=$P($P(tBuf,"Envelope"),"<",2)
				Set:":"'=$E(tPrefix,*) tPrefix=""
				If tBuf'["<"_tPrefix_"Envelope" { Set tSC = $$$ERROR($$$EnsErrGeneral,"No SOAP Envelope found in SOAP Request "_tBuf) Quit }
				#; read in whole header if any, and body start tag
				Set tSC=..readUntil(%iaStream,"<"_tPrefix_"Body",.tLeft,..ReadTimeout)  Quit:$$$ISERR(tSC)
				#; start new body stream, omit body contents from iastream
				Set %ibStream = ##class(%Library.GlobalCharacterStream).%New()  $$$ASSERT($IsObject(%ibStream))
				Set tSC=%ibStream.Write("<"_tPrefix_"Body")  Quit:$$$ISERR(tSC)
				#; extract envelope namespace declarations
				Set tBuf=$TR(tBuf,$C(9,10,13),"   "), nattrs=$L(tBuf," xmlns"), nslist=""
				For i=2:1:nattrs { Set nsattr=$ZStrip($P(tBuf," xmlns",i),"<>W")  Continue:""=nsattr
					Set tquot=$E(nsattr,$F(nsattr,"="))
					Set nslist=nslist_" xmlns"_$P(nsattr,tquot,1,2)_tquot
				}
				#; copy namespace declarations to Body element in new body stream
				Set tSC=%ibStream.Write(nslist)  Quit:$$$ISERR(tSC)
				#; read remainder of body into body stream
				Set tSC=..readUntil(%ibStream,"</"_tPrefix_"Body>",.tLeft,..ReadTimeout)  Quit:$$$ISERR(tSC)
				#; write body close
				Set tSC=%iaStream.Write("></"_tPrefix_"Body>")  Quit:$$$ISERR(tSC)
				#; set body stream reference as attribute of envelope stream
				Set %iaStream.Attributes("BodyStream")=%ibStream
				Set %ibStream.Attributes("EnvelopeStream")=%iaStream
				#; finally copy envelope close onto tail of %iaStream
			}
			Use ..Device:(::"+":) ; turn off terminators
			Set tSC = %iaStream.InputFromDevice(.tLeft,..ReadTimeout)
			Use ..Device:(::"+":..Terminators) ; turn on terminators
			Quit:$$$ISERR(tSC)
			$$$sysTRACE("TCP Read body("_%iaStream.Size_")")
		*/
}

/// Find the starting element tag in an XML stream, with its namespace prefix and its namespace declaration attributes and its total character length
ClassMethod getStartTag(pXML As %GlobalCharacterStream, Output pTag As %String, Output pPrefix As %String, Output pNSAttrs As %String, Output pBodyTagLen As %Integer) As %Status [ Internal ]
{
	Set tD=$D(pNSAttrs)  If tD {
		Merge:tD>1 inMap=pNSAttrs
		Do:tD#2 buildInMap(pNSAttrs)
	}
	Set tSC=$$$OK, (pTag,pPrefix,pNSAttrs)="", pBodyTagLen=0
	If '$IsObject(pXML) {
		Set tBuf=$TR(pXML,$C(9,10,13),"   ")
		Quit:""=tBuf tSC
	} ElseIf pXML.%Extends("%AbstractStream")||pXML.%Extends("%IO.I.Stream")||pXML.%Extends("%Stream.Object") {
		Quit:'pXML.Size tSC
		Do pXML.Rewind()
		Set tBuf=$TR(pXML.Read(2200),$C(9,10,13),"   ")
		Do pXML.Rewind()
	} ElseIf pXML.%Extends("EnsLib.EDI.XML.Document") {
		Set pTag=pXML.GetValueAt("/1/local-name()")
		If ""'=pTag {
			Set pPrefix=pXML.GetValueAt("/1/prefix()"), pNSAttrs=pXML.GetValueAt("/1/prefixes()")
			Set:""'=pPrefix pPrefix=pPrefix_":"
			Set:""'=pNSAttrs pNSAttrs="xmlns"_$Replace(pNSAttrs,", "," xmlns:")
			//! get regular attrs too
			Set pBodyTagLen=3+$L(pPrefix)+$L(pTag)+$L(pNSAttrs)
		}
		Quit tSC
	} Else {
		Quit $$$ERROR($$$EnsErrGeneral,"Unsupported XML input stream: "_pXML)
	}
	#; now we have tBuf
	For i=1:1:5 {
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
		Set $E(tBuf,1,$L(pTag)+1)="", pTag=""
	}
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

/// Get ready to join the envelope and body into a single output stream and calculate its content-length
ClassMethod prepJoinedResponse(ByRef pStreamOut As %GlobalCharacterStream, Output pBodyStreamOut As %GlobalCharacterStream, pSOAP12 As %Integer, Output pLen As %Integer, Output pBodyTagLen As %Integer, Output pNewBodyElem As %String, Output pPreStream As %String, Output pPostStream As %String) As %Status [ Internal ]
{
	#; Get Envelope top element
	Set tSC=$$$OK, tBodyStream=$G(pStreamOut), (pLen,tHasBody,tFromDoc)=0, (pBodyStreamOut,tStartTag,tBodyStartTag)=""
	Set tEnvelopeStream=$G(pStreamOut("EnvelopeStream"),$S($IsObject(pStreamOut)&&pStreamOut.%Extends("%Library.AbstractStream"):$G(pStreamOut.Attributes("EnvelopeStream")),1:""))

	If ""'=tEnvelopeStream && ('$IsObject(tEnvelopeStream) || tEnvelopeStream.Size) {
		Set tSC=..getStartTag(tEnvelopeStream,.tStartTag,.tPrefix,.tNSAttrs)  Quit:$$$ISERR(tSC) tSC
	}
	If ""=tStartTag || (tStartTag'="Envelope" && (""'=tBodyStream && ('$IsObject(tBodyStream) || tBodyStream.Size))) {
		#; replace envelope with body stream if no Envelope tag found and body is not empty
		Set tEnvelopeStream=tBodyStream, tBodyStream=$$$NULLOREF
		If ""'=tEnvelopeStream && ('$IsObject(tEnvelopeStream) || tEnvelopeStream.Size) {
			Set tSC=..getStartTag(tEnvelopeStream,.tStartTag,.tPrefix)  Quit:$$$ISERR(tSC) tSC
		}
	}
	#; Get Body top element
	If ""'=tBodyStream && ('$IsObject(tBodyStream) || tBodyStream.Size) {
		Set tHasBody=1
		Set:tStartTag="Envelope" tBodyAttrs=tNSAttrs ; prep for winnowing
		Set tSC=..getStartTag(tBodyStream,.tBodyStartTag,.tBodyPrefix,.tBodyAttrs,.pBodyTagLen)  Quit:$$$ISERR(tSC) tSC

		If ("Envelope"'=tStartTag) || ("Envelope"=tBodyStartTag) {
			#; can't have 2 bodies or 2 envelopes; discard the 'envelope' stuff
			Set tStartTag=tBodyStartTag, tPrefix=tBodyPrefix, tNSAttrs=tBodyAttrs, tBodyAttrs="", (tHasBody,pBodyTagLen)=0
			Set tEnvelopeStream=tBodyStream, tBodyStream=$$$NULLOREF
		} Else {
			Set:tBodyStartTag'="Body" pBodyTagLen=0, tBodyAttrs=""
		}
	} Else {
		Set pBodyTagLen=0, tBodyAttrs=""
	}
	If tStartTag="Envelope" {
		Quit:""=tPrefix $$$ERROR($$$EnsErrGeneral,"SOAP Envelope must be qualified with a namespace prefix")
		#; Check if top elements match
		Quit:pBodyTagLen&&(tBodyPrefix'=tPrefix) $$$ERROR($$$EnsErrGeneral,"Body element namespace prefix '"_tBodyPrefix_"' does not match envelope prefix '"_tPrefix_"'")
		Set (pPreStream,pPostStream) =""
	} ElseIf $Case(tStartTag,"Header":1,"Body":1,:0) {
		Quit:""=tPrefix $$$ERROR($$$EnsErrGeneral,"SOAP Header or Body element must be qualified with a namespace prefix")
		Set tPrefixNS=$P(tNSAttrs,"xmlns:"_tPrefix_"=",2), tPrefixNS=$E(tPrefixNS,1,$F(tPrefixNS,$E(tPrefixNS),2)-1)
		Set pPreStream="<"_tPrefix_"Envelope xmlns:"_tPrefix_"="_tPrefixNS_">", pPostStream="</"_tPrefix_"Envelope>"
	} Else {
		Quit:'$IsObject(tEnvelopeStream)||'tEnvelopeStream.Size $$$ERROR($$$EnsErrGeneral,"No element found in SOAP Envelope object")
		#; Construct Envelope & Body elements; no header
		Set tAddPrefix=..#SOAPPREFIX
		If pSOAP12 {
			Set tNSAttrs=" xmlns:"_tAddPrefix_"='http://www.w3.org/2003/05/soap-envelope'" ; SOAP 1.2
		} Else {
			Set tNSAttrs=" xmlns:"_tAddPrefix_"='http://schemas.xmlsoap.org/soap/envelope/'"
		}
		Set tPrefix=tAddPrefix_":"
		Set pPreStream="<"_tPrefix_"Envelope"_tNSAttrs_"><"_tPrefix_"Body>", pPostStream="</"_tPrefix_"Body></"_tPrefix_"Envelope>"
	}
	Quit:$$$ISERR(tSC) tSC

	#; Pre-calculate output length
 	Set pLen=$S($IsObject(tEnvelopeStream):tEnvelopeStream.Size, 1:$L(tEnvelopeStream))
 	Set:pLen pStreamOut=tEnvelopeStream
	If tHasBody {
		#; Write Envelope head
		Set tBodyLen=$S($IsObject(tBodyStream):tBodyStream.Size, 1:$L(tBodyStream))
		If tBodyLen&&'pLen { Set pStreamOut=tBodyStream, pBodyStreamOut="" } Else { Set pBodyStreamOut=tBodyStream }
		Set pLen=pLen+$L(pPreStream)+tBodyLen ; now includes body tag from Envelope
		#; 7 from "</" and "Body>" since length of tPrefix already taken into account
		Set:pBodyTagLen pLen=pLen+$L(tBodyAttrs)-pBodyTagLen-7-$L(tPrefix) ; takes into account body close tag and prefixes
		Set pLen=pLen+$L(pPostStream)
	}
	Set pNewBodyElem=tPrefix_"Body"_tBodyAttrs
	Quit tSC
}

/// Assemble Envelope and Body and write to HTTP response device
ClassMethod writeJoinedResponse(pEnvelopeStream As %GlobalCharacterStream, pBodyStream As %GlobalCharacterStream, pBodyTagLen As %Integer, pNewBodyElem As %String, pPreStream As %String, pPostStream As %String) As %Status [ Internal ]
{
	If ""=pBodyStream || ($IsObject(pBodyStream) && 'pBodyStream.Size) {
		#; Write Envelope which should include a body too
 		Set tSC=..writeStream(pEnvelopeStream)
	} Else {
		#; Write Envelope head
		Set tPrefix=$P(pNewBodyElem,":")_":"
		Write:""'=pPreStream pPreStream
		Set tSC=..writeStreamUntil(pEnvelopeStream,"<"_tPrefix_"Body>",'pBodyTagLen)

		#; Write body
		If 'pBodyTagLen {
			Set tSC=..writeStream(pBodyStream)
		} Else {
			Write "<"_pNewBodyElem_">"
			Set tDummy=pBodyStream.Read(pBodyTagLen) ; we just wrote the Body start we want - skip the old one
			Set tSC=..writeStream(pBodyStream,pBodyStream.Size-(pBodyTagLen+$L(tPrefix)+$L("</Body>"))) ; leave off Body close tag - it will come from Envelope
		}
		#; Write Envelope tail
		Set tSC=..writeStream(pEnvelopeStream)
		Write:""'=pPostStream pPostStream
	}
	Write *-3
	Quit tSC
}

/// Read until target found in pStreamIn, copying all data read to pStreamOut
ClassMethod copyStreamUntil(pStreamIn As %AbstractStream, pStreamOut As %AbstractStream, pTarget As %String, ByRef pStatus As %Status, pIncludeTarget As %Boolean = 0) As %Boolean [ Internal ]
{
	#; Read in chunks using last char of pTarget as terminator
	Set tFound=0, pStatus=$$$OK
	Set tOldTerm=pStreamIn.LineTerminator
	Set tC=$E(pTarget,*)
	Set pStreamIn.LineTerminator=tC
	Set tLine="" While 'tFound && 'pStreamIn.AtEnd {
		Set tLen=32000-$L(pTarget)
		If pStreamIn.%Extends("%IO.I.Stream") {
			Set tLT=tC, tFresh=pStreamIn.ReadLine(,,.pStatus,.tLT), tEOL=(""'=tLT||pStreamIn.AtEnd), tLine=tLine_tFresh
		} Else {
			Set tLine=tLine_pStreamIn.ReadLine(,.pStatus,.tEOL)
		}
		Quit:$$$ISERR(pStatus)
		Set:tEOL tLine=tLine_tC
		If tEOL && ($L(tLine)>=$L(pTarget)) && (pTarget=$E(tLine,*+1-$L(pTarget),*)) {
			Set tFound=1
			Set pStatus=pStreamOut.Write($E(tLine,1,$L(tLine)-$L(pTarget))) Set $E(tLine,1,$L(tLine)-$L(pTarget))=""
		} Else {
			If $L(tLine)>$L(pTarget) Set pStatus=pStreamOut.Write($E(tLine,1,$L(tLine)+1-$L(pTarget))) Set $E(tLine,1,$L(tLine)+1-$L(pTarget))=""
		}
	} Quit:$$$ISERR(pStatus) tFound
	Set:'tFound||pIncludeTarget pStatus=pStreamOut.Write(tLine)
	Set pStreamIn.LineTerminator=tOldTerm
	Do:'tFound pStreamIn.Rewind()
	Quit tFound
}

/// Read until target found in pStreamIn, copying all data read to current device
ClassMethod writeStreamUntil(pStreamIn, pTarget As %String, pIncludeTarget) As %Status [ Internal ]
{
	#; Read in chunks using last char of pTarget as terminator
	Set tSC=$$$OK, tFound=0, tC=$E(pTarget,*), tEntryTable=$$GetIO^%NLS()
	/* Since we are a passthrough we have not translated the data and hence need to pass it back RAW */
	If (tEntryTable'="RAW") Do SetIO^%NLS("RAW")
	Try {
		If '$IsObject(pStreamIn) {
			Set tLine=""  While 'tFound && $L(pStreamIn) {
				Set tPos=$F(pStreamIn,tC)
				If tPos { Set tFresh=$E(pStreamIn,1,tPos), $E(pStreamIn,1,tPos)="" }
				Else { Set tFresh=pStreamIn, pStreamIn="" }
				Set tLine=tLine_tFresh
				If ($L(tLine)>=$L(pTarget)) && (pTarget=$E(tLine,*+1-$L(pTarget),*)) {
					Set tFound=1
					Write $E(tLine,1,$L(tLine)-$L(pTarget)) Set $E(tLine,1,$L(tLine)-$L(pTarget))=""
				} Else {
					If $L(tLine)>$L(pTarget) Write $E(tLine,1,$L(tLine)+1-$L(pTarget)) Set $E(tLine,1,$L(tLine)+1-$L(pTarget))=""
				}
			}
		} Else {
			Set tOldTerm=pStreamIn.LineTerminator
			Set pStreamIn.LineTerminator=tC
			Set tLine=""  While 'tFound && $$$ISOK(tSC) && 'pStreamIn.AtEnd {
				Set tLen=32000-$L(pTarget)
				If pStreamIn.%Extends("%IO.I.Stream") {
					Set tLT=tC, tLine=tLine_pStreamIn.ReadLine(,,.tSC,.tLT), tEOL=(""'=tLT||pStreamIn.AtEnd)  Quit:$$$ISERR(tSC)
				} Else {
					Set tLine=tLine_pStreamIn.ReadLine(,.tSC,.tEOL)  Quit:$$$ISERR(tSC)
				}
				Set:tEOL tLine=tLine_tC
				If tEOL && ($L(tLine)>=$L(pTarget)) && (pTarget=$E(tLine,*+1-$L(pTarget),*)) {
					Set tFound=1
					Write $E(tLine,1,$L(tLine)-$L(pTarget)) Set $E(tLine,1,$L(tLine)-$L(pTarget))=""
				} Else {
					If $L(tLine)>$L(pTarget) Write $E(tLine,1,$L(tLine)+1-$L(pTarget)) Set $E(tLine,1,$L(tLine)+1-$L(pTarget))=""
				}
			}
			Set pStreamIn.LineTerminator=tOldTerm
			Do:'tFound pStreamIn.Rewind()
		}
		Write:'tFound||pIncludeTarget tLine
		Set pStreamIn.LineTerminator=tOldTerm
		Do:'tFound pStreamIn.Rewind()
		;Set:'tFound&&$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrGeneral,"Reached end of stream while trying to read for character '"_tC_"'")
	} Catch {Set tSC = $$$SystemError}
	If (tEntryTable'="RAW") Do SetIO^%NLS(tEntryTable)


	Quit tSC
}

/// Copy all or part of pStreamIn to pStreamOut
ClassMethod copyStream(pStreamIn As %AbstractStream, pStreamOut As %AbstractStream, pLength As %Integer = "") As %Status [ Internal ]
{
	If '$IsObject(pStreamIn) {
		Set tSC=pStreamOut.Write($S(""=pLength:pStreamIn,1:$E(pStreamIn,1,pLength)))
		Quit tSC
	}
	Set:pLength<0 pLength=0
	Set tLeft=+pLength, tSC=$$$OK  While ((tLeft>0)||(pLength="")) && $$$ISOK(tSC) && 'pStreamIn.AtEnd {
		Set tLen=$S((""'=pLength)&&(tLeft<32000):tLeft,1:32000)
		If pStreamIn.%Extends("%IO.I.Stream") {
			Set tChunk=pStreamIn.Read(tLen,,.tSC)  Quit:$$$ISERR(tSC)
		} Else {
			Set tChunk=pStreamIn.Read(tLen,.tSC)  Quit:$$$ISERR(tSC)
		}
		Set tSC=pStreamOut.Write(tChunk), tLeft=tLeft-$L(tChunk)
	}
	Quit tSC
}

/// Read the specified number of bytes from pStreamIn, copying all data read to current device
ClassMethod writeStream(pStreamIn As %AbstractStream, pLength As %Integer = "") As %Status [ Internal ]
{
	Set tSC = $$$OK, tEntryTable=$$GetIO^%NLS()
	/* Since we are a passthrough we have not translated the data and hence need to pass it back RAW */
	If (tEntryTable'="RAW") Do SetIO^%NLS("RAW")
	Try {
		If '$IsObject(pStreamIn) {
			Write $S(""=pLength:pStreamIn,1:$E(pStreamIn,1,pLength))
			Quit
		}
		#; Read in chunks
		Set:pLength<0 pLength=0
		Set tSC=$$$OK, tLeft=+pLength  While ((tLeft>0)||(pLength="")) && $$$ISOK(tSC) && 'pStreamIn.AtEnd {
			Set tLen=$S((pLength'="")&&(tLeft<32000):tLeft,1:32000)
			If pStreamIn.%Extends("%IO.I.Stream") {
				Set tChunk=pStreamIn.Read(tLen,,.tSC)  Quit:$$$ISERR(tSC)
			} Else {
				Set tChunk=pStreamIn.Read(tLen,.tSC)  Quit:$$$ISERR(tSC)
			}
			
			Write tChunk  Set tLeft=tLeft-$L(tChunk)
			
		}
	} Catch {Set tSC = $$$SystemError}
	If (tEntryTable'="RAW") Do SetIO^%NLS(tEntryTable)
	Quit tSC
}

/// This user callback method is called from %OnClose()
Method OnTearDown() As %Status
{
	#; Detect if webserver because IRIS is done and the job may get re-used by the CSP server
	If ""'=..%OutsideCreated {
		If 1'=..%OutsideCreated {
			Kill $$$EnsLocalCache(..%ConfigName)
			If ..KeepCSPPartition {
				Merge $$$EnsLocalCache(..%ConfigName,"CachedObject")=$$$EnsJobLocal("CachedObject")
				Merge $$$EnsLocalCache(..%ConfigName,"CachedChecksum")=$$$EnsJobLocal("CachedChecksum")
			}
		}
	}
	Quit ##super()
}

}
