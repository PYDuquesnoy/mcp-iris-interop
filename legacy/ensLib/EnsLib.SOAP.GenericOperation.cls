/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Forwards contents of a SOAP request to a remote SOAP service and sends the SOAP response as its reply message
Class EnsLib.SOAP.GenericOperation Extends Ens.BusinessOperation [ System = 4 ]
{

/// Prefix to be used for the SOAP Envelope namespace if envelope elements must be constructed
Property SOAPPrefix As %String [ InitialExpression = "SOAP-ENV" ];

/// Format options for formatting XML output from an XML Virtual Document object
Property VDocFormat As %String;

/// Write Raw Mode<br>
/// If true (the default) then the body of the request will be written using RAW mode<br>
/// i.e., with no characterset translation. If false then it will use the charset specified<br>
/// in the request headers. This uses the WriteRawMode property of the HTTP request object<br>
/// Uncheck to not use Write Raw Mode<br>
Property WriteRawMode As %Boolean [ InitialExpression = 1 ];

/// Read Raw Mode<br>
/// If true (the default) then the body of the response will be read in using RAW mode<br>
/// i.e., with no characterset translation. If false then it will use the charset specified<br>
/// in the response headers. This uses the ReadRawMode property of the HTTP request object<br>
/// Uncheck to not use Read Raw Mode<br>
Property ReadRawMode As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "SOAPPrefix,VDocFormat,WriteRawMode,ReadRawMode";

Parameter ADAPTER = "EnsLib.HTTP.OutboundAdapter";

/// Holds request object used to submit requests and get reponses
Property %HttpRequest As %Net.HttpRequest [ Internal ];

/// Holds stream version of request EnvelopeDoc if needed to construct merged SOAP envelope+body request stream
Property %EnvelopeStream As %GlobalCharacterStream;

/// Comma separated list of HTTP Headers associated with the message request 
/// sent to the business operation that are not to be passed to the external system.
/// The values are case-insensitive.
/// The appropriate Content-Length, Content-Type, Host and SOAPAction will be sent and ought not be specified here.
Property %ExcludeRequestHttpHeaders As %String(MAXLEN = "");

/// Set this to 0 if response body should be left inside response envelope stream instead of being split into a separate body stream in the generic response message
Property %SplitResponseBody As %Boolean [ InitialExpression = 1 ];

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	Set ..%HttpRequest=##class(%Net.HttpRequest).%New()
	Quit $$$OK
}

/// Invoke a remote SOAP Service given a generic SOAP request
Method OnMessage(pRequest As EnsLib.SOAP.GenericMessage, Output pResponse As EnsLib.SOAP.GenericMessage = {$$$NULLOREF}) As %Status
{
	Set tSC=$$$OK, ..%HttpRequest.Location="", ..%HttpRequest.AcceptGzip=0, ..%HttpRequest.FollowRedirect=0, ..%HttpRequest.ReadRawMode=..ReadRawMode,  ..%HttpRequest.WriteRawMode=..WriteRawMode
	Do ..%HttpRequest.Reset()
	Do ..%HttpRequest.RemoveHeader("HOST"), ..%HttpRequest.RemoveHeader("USER-AGENT"), ..%HttpRequest.RemoveHeader("REFERER")

	#; We want to use uncompressed stream if we are splitting the response body from the Envelope.
	Set ..%HttpRequest.ReturnGzipResponse='..%SplitResponseBody

	#; Pass along selected HTTP headers
	Set (tReq,tURL,tCT,tLen,tApp,tCfg)="",tDoNotPassThrough=","_$ZCVT(..%ExcludeRequestHttpHeaders,"L")_",host,cspapplication,ensconfigname,ensattribute,url,httprequest,httpversion,content-length,content-type,"
	Set tHeaderKey="" For { Set tHeaderKey=pRequest.HTTPHeaders.Next(tHeaderKey)  Quit:""=tHeaderKey  Set tHeaderLwr=$ZCVT(tHeaderKey,"L")
		Do:tDoNotPassThrough'[(","_tHeaderLwr_",") ..%HttpRequest.SetHeader(tHeaderKey,pRequest.HTTPHeaders.GetAt(tHeaderKey)) ; no need to handle multiple on one line
		Set:tHeaderLwr="httprequest" tReq=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="url" tURL=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="content-type" tCT=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="content-length" tLen=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="cspapplication" tApp=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="ensconfigname" tCfg=pRequest.HTTPHeaders.GetAt(tHeaderKey)
	}
	Set ..%HttpRequest.ContentType=tCT
	Set tSOAP12=tCT["application/soap+xml"
	Set tSC=..constructHTTPRequest(pRequest,tLen,tCT,tSOAP12)  Quit:$$$ISERR(tSC) tSC

	#; Now send to the target address
	Set tAdURL=..Adapter.URL, tAdURL1=$E(tAdURL)
	If tAdURL1="^" {
		#; strip Application from URL and replace it with the remaining adapter URL part, if any
		Set $E(tAdURL,1)=""  Set:"*"=tAdURL tAdURL=""  Set:"/"'=$E(tAdURL,1) tAdURL="/"_tAdURL
		If (""'=tApp) {
			If (tApp=$E(tURL,1,$L(tApp)))&&("/"=$E(tApp,*)) {
				Set tURL=tAdURL_$S($L(tAdURL)>1:"/",1:"")_$E(tURL,$L(tApp)+1,*), tAdURL=""
			}
		} Else {
			/*	Come in via the adapter and the Application name is not at the front so keep inbound URL.
				Prepend anthing after the | to the URL that came in.
			*/
			Set tURL=$S($L(tAdURL)>1:tAdURL,1:"")_tURL, tAdURL = ""			}
	} ElseIf tAdURL1="|" {
		#; strip Application and ConfigName from URL and replace it with the remaining adapter URL part, if any
		If ""=tApp { Set:""'=tCfg tCfg="/"_tCfg_"/" } Else { Set tCfg=$S(""=tCfg:tApp, 1:tApp_tCfg_"/") }
		Set $E(tAdURL,1)=""  Set:"*"=tAdURL tAdURL=""  Set:"/"'=$E(tAdURL,1) tAdURL="/"_tAdURL
		If (""'=tCfg){
			If (tCfg=$E(tURL,1,$L(tCfg))) {
				Set tURL=tAdURL_$S($L(tAdURL)>1:"/",1:"")_$E(tURL,$L(tCfg)+1,*), tAdURL=""
			} ElseIf (tApp="") {
				/*	Come in via the adapter and the tCfg name is not the same so keep inbound URL. 
					Prepend anthing after the | to the URL that came in.
				*/
				Set tURL=$S($L(tAdURL)>1:tAdURL,1:"")_tURL, tAdURL = ""	
			}
		}
	}
#dim tHttpResponse As %Net.HttpResponse
	Set tSC=..Adapter.SendFormDataArray(.tHttpResponse,$S(""=tReq:"POST",1:tReq),..%HttpRequest,,,$Case(tAdURL,"":tURL,"*":tURL,:tAdURL))

	#; Suppress HTTP status errors and just pass back the status, headers and body
	If $$$ISERR(tSC)&&'$$$StatusEquals(tSC,$$$EnsErrHTTPStatus) { Set ..%HttpRequest=##class(%Net.HttpRequest).%New()  Quit tSC }
	Set tSC=$$$OK

	If $IsObject(tHttpResponse.Data) {
		Set tStream=tHttpResponse.Data
	} Else {
		Set tStream=##class(%GlobalCharacterStream).%New()
		Set tSC=tStream.Write(tHttpResponse.Data)  Quit:$$$ISERR(tSC) tSC
	}
	#; Find starting element
	If '..%SplitResponseBody {
		Set pResponse=##class(EnsLib.SOAP.GenericMessage).%New(tStream,,tHttpResponse)
	} Else {
		Set tSC=##class(GenericService).splitEnvelopeStream(tStream,.tEnvelopeStream,.tBodyStream)  Quit:$$$ISERR(tSC) tSC
		Set pResponse=##class(EnsLib.SOAP.GenericMessage).%New(tBodyStream,,tHttpResponse,tEnvelopeStream)
	}
	Do pResponse.HTTPHeaders.SetAt(tHttpResponse.StatusLine,"StatusLine")
	
	If ##class(Ens.Util.Statistics).StatsStarted(..%ConfigName) {
		Set tStatsUserDimension=$LG(pRequest.HTTPHeaders.GetAt("EnsAttribute"),2)
		If (tStatsUserDimension'="") Do ##class(Ens.Util.Statistics).SetStatsUserDimension(..%ConfigName,tStatsUserDimension)
	}

	Quit tSC
}

/// Assemble Envelope and Body into HTTP EntityBody stream
Method constructHTTPRequest(pRequest As EnsLib.SOAP.GenericMessage, pLen As %Integer, pCT As %String, pSOAP12 As %Integer) As %Status [ Internal ]
{
	Quit:'pLen $$$OK

	#; Get Envelope top element
	Set tSC=$$$OK, tEnvelopeStream=pRequest.EnvelopeStream, tEnvelopeDoc=pRequest.EnvelopeDoc, tBodyStream=pRequest.Stream, tBodyDoc=pRequest.Doc, tHasBody=0, tFromDoc=0
	If $IsObject(tEnvelopeStream) && tEnvelopeStream.Size {
		Set tSC=##class(GenericService).getStartTag(tEnvelopeStream,.tStartTag,.tPrefix,.tNSAttrs)  Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSC=##class(GenericService).getStartTag(tEnvelopeDoc,.tStartTag,.tPrefix,.tNSAttrs)  Quit:$$$ISERR(tSC) tSC
		Set tFromDoc=1
	}
	If ""=tStartTag || (tStartTag'="Envelope" && ($IsObject(tEnvelopeStream) && tEnvelopeStream.Size || $IsObject(tEnvelopeDoc))) {
		Set tEnvelopeStream=pRequest.Stream, tEnvelopeDoc=pRequest.Doc, (tBodyStream,tBodyDoc)=$$$NULLOREF
		If $IsObject(tEnvelopeStream) && tEnvelopeStream.Size {
			Set tSC=##class(GenericService).getStartTag(tEnvelopeStream,.tStartTag,.tPrefix)  Quit:$$$ISERR(tSC) tSC
			Set tFromDoc=0
		} Else {
			Set tSC=##class(GenericService).getStartTag(tEnvelopeDoc,.tStartTag,.tPrefix)  Quit:$$$ISERR(tSC) tSC
			Set tFromDoc=1
		}
	}
	#; Get Body top element
	Set:tStartTag="Envelope" tBodyAttrs=tNSAttrs ; prep for winnowing
	If $IsObject(tBodyStream) && tBodyStream.Size {
		Set tHasBody=1, tBodyFromDoc=0
		Set tSC=##class(GenericService).getStartTag(tBodyStream,.tBodyStartTag,.tBodyPrefix,.tBodyAttrs,.tBodyTagLen)  Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSC=##class(GenericService).getStartTag(tBodyDoc,.tBodyStartTag,.tBodyPrefix,.tBodyAttrs,.tBodyTagLen)  Quit:$$$ISERR(tSC) tSC
		Set (tHasBody,tBodyFromDoc)=(""'=tBodyStartTag)
	}
	If tHasBody && (("Envelope"'=tStartTag) || ("Envelope"=tBodyStartTag)) {
		#; can't have 2 bodies or 2 envelopes; discard the 'envelope' stuff
		Set tStartTag=tBodyStartTag, tPrefix=tBodyPrefix, tNSAttrs=tBodyAttrs, tFromDoc=tBodyFromDoc, (tHasBody,tHasBodyTag,tBodyFromDoc)=0
		Set tEnvelopeStream=tBodyStream, tEnvelopeDoc=tBodyDoc, tBodyStream=$$$NULLOREF, tBodyDoc=$$$NULLOREF
	} Else {
		Set tHasBodyTag=("Body"=tBodyStartTag)
	}

	If tStartTag="Envelope" {
		Quit:""=tPrefix $$$ERROR($$$EnsErrGeneral,"SOAP Envelope must be qualified with a namespace prefix")
		#; Check if top elements match
		Quit:tHasBodyTag&&(tBodyPrefix'=tPrefix) $$$ERROR($$$EnsErrGeneral,"Body element namespace prefix '"_tBodyPrefix_"' does not match envelope prefix '"_tPrefix_"'")
		Set (tPreStream,tPostStream) =""
	} ElseIf $Case(tStartTag,"Header":1,"Body":1,:0) {
		Quit:""=tPrefix $$$ERROR($$$EnsErrGeneral,"SOAP Header or Body element must be qualified with a namespace prefix")
		Set tPrefixNS=$P(tNSAttrs,"xmlns:"_tPrefix_"=",2), tPrefixNS=$E(tPrefixNS,1,$F(tPrefixNS,$E(tPrefixNS),2)-1)
		Set tPreStream="<"_tPrefix_"Envelope xmlns:"_tPrefix_"="_tPrefixNS_">", tPostStream="</"_tPrefix_"Envelope>"
	} Else {
		#; Construct Envelope & Body elements; no header
		If '($IsObject(tEnvelopeStream) && tEnvelopeStream.Size) && '$IsObject(pRequest.Doc) { Set tSC=$$$ERROR($$$EnsErrGeneral,"No element found in SOAP Envelope object") }
		Else {
			Set tAddPrefix=..SOAPPrefix
			If pSOAP12 {
				Set tNSAttrs=" xmlns:"_tAddPrefix_"='http://www.w3.org/2003/05/soap-envelope'" ; SOAP 1.2
			} Else {
				Set tNSAttrs=" xmlns:"_tAddPrefix_"='http://schemas.xmlsoap.org/soap/envelope/'"
			}
			Set tAddPrefix=tAddPrefix_":"
			Set tPreStream="<"_tAddPrefix_"Envelope"_tNSAttrs_"><"_tAddPrefix_"Body>", tPostStream="</"_tAddPrefix_"Body></"_tAddPrefix_"Envelope>"
		}
	}
	Quit:$$$ISERR(tSC) tSC

	If 'tHasBody {
		#; Write Envelope which should include a body too
		If $IsObject(tEnvelopeDoc) && '($IsObject(tEnvelopeStream) && tEnvelopeStream.Size) {
			Set tSC=tEnvelopeDoc.OutputToLibraryStream(..%HttpRequest.EntityBody, ..VDocFormat)  Quit:$$$ISERR(tSC) tSC
		} Else {
			Set ..%HttpRequest.EntityBody = tEnvelopeStream
		}
	} Else {
		#; Write Envelope head
		Set tStreamOut=..%HttpRequest.EntityBody
		Do:""'=tPreStream tStreamOut.Write(tPreStream)
		If tFromDoc {
			Do ..%EnvelopeStream.Clear()
			Set tSC=tEnvelopeDoc.OutputToLibraryStream(..%EnvelopeStream, ..VDocFormat)  Quit:$$$ISERR(tSC) tSC
			Set tEnvelopeStream=..%EnvelopeStream
		}
		Set tFound=##class(GenericService).copyStreamUntil(tEnvelopeStream,tStreamOut,"<"_tPrefix_"Body",.tSC,'tHasBodyTag)
		If $$$ISERR(tSC) Quit tSC
		If 'tFound {Set tSC = $$$ERROR($$$EnsErrGeneral,"No Body start tag in Envelope stream") Quit tSC}
		Set tNextChar = tEnvelopeStream.Read(1)
		If 'tHasBodyTag Do tStreamOut.Write(tNextChar)
		If tNextChar="/" {
			Set tEnvHasSeparateBodyClosing = 0
			Set tNextChar = tEnvelopeStream.Read(1) ;Read the >
			If 'tHasBodyTag Do tStreamOut.Write(tNextChar)
		} Else {
			Set tEnvHasSeparateBodyClosing = 1
		}
		#; Write body
		If tBodyFromDoc {
			Set tSC=..docToLibraryStream(tBodyDoc, tStreamOut,"/1","f"_..VDocFormat)  Quit:$$$ISERR(tSC) tSC
			 #;Do not duplicate closing body tag
			If tHasBodyTag,tEnvHasSeparateBodyClosing Do tEnvelopeStream.Read(($L(tBodyPrefix)+$L("</Body>")))
		} Else {
			If 'tHasBodyTag {
				Set tSC=##class(GenericService).copyStream(tBodyStream,tStreamOut)
			} Else {
				Set tSC=tStreamOut.Write("<"_tPrefix_"Body"_tBodyAttrs_">")  Quit:$$$ISERR(tSC) tSC
				Set tDummy=tBodyStream.Read(tBodyTagLen) ; we just wrote the Body start we want - skip the old one
				If tEnvHasSeparateBodyClosing {
					#; Leave off Body close tag - it will come from Envelope
					Set tSC=##class(GenericService).copyStream(tBodyStream,tStreamOut,tBodyStream.Size-(tBodyTagLen+$L(tBodyPrefix)+$L("</Body>")))
				} Else {
					#;No closing body tag in Envelope so use closing in tBodyStream
					Set tSC=##class(GenericService).copyStream(tBodyStream,tStreamOut)
				}
			}
		}
		#; Write Envelope tail
		Set tSC=##class(GenericService).copyStream(tEnvelopeStream,tStreamOut)
		Do:""'=tPostStream tStreamOut.Write(tPostStream)
		Do:tEnvelopeStream=..%EnvelopeStream ..%EnvelopeStream.Clear()
	}
	Quit tSC
}

/// Output the XML document sub-tree at pRootPath to the given stream object
ClassMethod docToLibraryStream(pDoc As EnsLib.EDI.XML.Document, pLibStream As %Stream.Object, pRootPath As %String, pFormat As %String) As %Status [ Internal ]
{
	#; ...paraphrased from EnsLib.EDI.XML.Document:OutputToLibraryStream() & OutputToIOStream()
	Quit:'$$$IsdefObject(pLibStream) $$$ERROR($$$EnsErrGeneral,"No Stream object provided")
	Set tIOStream=$S(pLibStream.%Extends("%IO.I.CharacterStream"):pLibStream, 1:##Class(%IO.MetaCharacterStream).%New(pLibStream))
	Quit:"/"=pRootPath pDoc.OutputToIOStream(tIOStream, .pFormat)

	Set tFormat=$G(pFormat,pDoc.Format)
	#; Apply the C(e) part of pFormat
	Set cp=$F(tFormat,"C(") If cp {
		Set ce=$F(tFormat,")",cp)
		If ce {
			Set tCharEncoding=$ZStrip($E(tFormat,cp,ce-2),"<>WC"), $E(tFormat,cp-2,ce-1)=""
			Set tForce=("!"=$E(tCharEncoding))  Set:tForce $E(tCharEncoding,1)=""
			If ""=tCharEncoding { Set tCharEncoding=tIOStream.CharEncoding }
			ElseIf tForce { Set tIOStream.CharEncoding=tCharEncoding }
			Set:$Case($ZCVT(tCharEncoding,"L"),"":1,"native":1,"local":1,"default":1,:"@"=$E(tCharEncoding)) tCharEncoding=$S(tIOStream.%Extends("%IO.I.TranslationDevice"):##class(%IO.I.TranslationDevice).GetTableCharEncoding(tIOStream.TranslationTable),1:"")
			Do:""'=tCharEncoding tIOStream.Write("<?xml version=""1.0"" encoding="""_tCharEncoding_""" ?>"_$S(tFormat["w":$C(13,10), tFormat["n":$C(10), tFormat["r":$C(10), tFormat["c":$C(10), 1:""))
		}
	}
	If $D(@pDoc.%PropCacheRef) {
		Set tSC=pDoc.initNSContext(","">/"",1",.tNSContext)  Quit:$$$ISERR(tSC) tSC
		Set tSC=pDoc.syncToDOMCache(0,"",,,,,.tNSContext)  Quit:$$$ISERR(tSC) tSC
	}
	Quit pDoc.domGetValueAt(.tIOStream,pRootPath,tFormat)
}

}
