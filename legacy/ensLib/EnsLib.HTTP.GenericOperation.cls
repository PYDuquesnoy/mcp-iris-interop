/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Forwards contents of an HTTP request to a remote HTTP service and sends the HTTP response as its reply message
Class EnsLib.HTTP.GenericOperation Extends Ens.BusinessOperation [ System = 4 ]
{

/// Prefix to be used for the SOAP Envelope namespace if envelope elements must be constructed
Property SOAPPrefix As %String [ InitialExpression = "SOAP-ENV" ];

Parameter ADAPTER = "EnsLib.HTTP.OutboundAdapter";

/// Holds request object used to submit requests and get reponses
Property %HttpRequest As %Net.HttpRequest [ Internal ];

/// Comma separated list of HTTP Headers associated with the message request 
/// sent to the business operation that are not to be passed to the external system.
/// The values are case-insensitive.
/// The appropriate Content-Length, Content-Type, Host and SOAPAction will be sent and ought not be specified here.
Property %ExcludeOutboundHeaders As %String(MAXLEN = 1000);

/// Read Raw Mode<br>
/// If true (the default) then the body of the response will be read in using RAW mode<br>
/// i.e., with no characterset translation. If false then it will use the charset specified<br>
/// in the response headers. This uses the ReadRawMode property of the HTTP request object<br>
/// Uncheck to not use Read Raw Mode<br>
Property ReadRawMode As %Boolean [ InitialExpression = 1 ];

/// Write Raw Mode<br>
/// If true then the body of the request will be written using RAW mode<br>
/// i.e., with no characterset translation. If false (the default) then it will use the charset specified<br>
/// in the request headers. This uses the WriteRawMode property of the HTTP request object<br>
/// Check to use Write Raw Mode<br>
Property WriteRawMode As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "ReadRawMode,WriteRawMode";

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	Set ..%HttpRequest=##class(%Net.HttpRequest).%New()
	Quit $$$OK
}

/// Invoke a remote HTTP Service given a generic HTTP request
Method OnMessage(pRequest As EnsLib.HTTP.GenericMessage, Output pResponse As EnsLib.HTTP.GenericMessage) As %Status
{
	Set tSC=$$$OK, ..%HttpRequest.Location="", ..%HttpRequest.AcceptGzip=0, ..%HttpRequest.FollowRedirect=0, ..%HttpRequest.ReadRawMode=..ReadRawMode,  ..%HttpRequest.WriteRawMode=..WriteRawMode
	Do ..%HttpRequest.Reset()
	Do ..%HttpRequest.RemoveHeader("HOST"), ..%HttpRequest.RemoveHeader("USER-AGENT"), ..%HttpRequest.RemoveHeader("REFERER")

	#; Pass along selected HTTP headers
	Set (tReq,tURL,tCT,tLen,tNParams,tRawParams,tApp,tCfg)="", tDoNotPassThrough=","_$ZCVT(..%ExcludeOutboundHeaders,"L")_",host,cspapplication,ensconfigname,ensattribute,url,httprequest,httpversion,content-length,content-type,charencoding,translationtable,iparams,params,rawparams,"
	Set tHeaderKey="" For { Set tHeaderKey=pRequest.HTTPHeaders.Next(tHeaderKey)  Quit:""=tHeaderKey  Set tHeaderLwr=$ZCVT(tHeaderKey,"L")
		Set tPass=(tDoNotPassThrough'[(","_tHeaderLwr_","))  Set:tPass&&(tHeaderLwr?1"iparams_"1.N) tPass=0
		Do:tPass ..%HttpRequest.SetHeader(tHeaderKey,pRequest.HTTPHeaders.GetAt(tHeaderKey)) ; no need to handle multiple on one line
		Set:tHeaderLwr="httprequest" tReq=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="url" tURL=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		If tHeaderLwr="content-type" {
			/* remove possible "  and ' - but not if surrounding boundary id. 
				boundary is only mandatory parameter of multipart
				https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html 
			*/
			Set tCT = pRequest.HTTPHeaders.GetAt(tHeaderKey)
			If $E($ZCVT(tCT,"L"),1,9)'="multipart" Set tCT=$TR(tCT,$C(34,39))
		}
		Set:tHeaderLwr="content-length" tLen=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="iparams" tNParams=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="rawparams" tRawParams=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="cspapplication" tApp=pRequest.HTTPHeaders.GetAt(tHeaderKey)
		Set:tHeaderLwr="ensconfigname" tCfg=pRequest.HTTPHeaders.GetAt(tHeaderKey)
	}
	#; if rawparams then remove any query string from tURL
	If tRawParams'="" Set tURL = $P(tURL,"?",1)
	
	#; if you want to POST both form body data and form variables then pass RAWPARAMS - the RAWPARAMS form variables will go in the URL and not in the form body, leaving the form body to contain your data
	Set tFormVarNames="", tDataArray="", n=0, tGenRawParams = ""
	
	If $IsObject(pRequest.Stream) {
		Set:$Case($ZCVT(tReq,"U"),"":1,"POST":1,:0) tNParams=0
		Set:'tLen tLen=pRequest.Stream.Size
	}
	For i=1:1:tNParams {
		Set tParam=pRequest.HTTPHeaders.GetAt("IParams_"_i)
		Set tKey=$ZStrip($P(tParam,"="),"<>W"), tVal=$S($F(tParam,"="):$E(tParam,$F(tParam,"="),*),1:"")
		If tRawParams="" Set tGenRawParams=tGenRawParams_$S(tGenRawParams="":"",1:"&")_$S(tKey="":"", 1:tKey)_$S(tVal="":"", 1:"="_tVal)
		If (tKey'=""),(tVal'="") {
			Set tFormVarNames=tFormVarNames_$S(tFormVarNames="":"",1:",")_tKey
			Set tDataArray($I(n))=tVal
		}
	}
	#; if the conversion to FormVarNames meant we did do not use all e.g. for  ?WSDL&abc=1 we would only set abc=1 then do not use tFormVarNames
	If +tNParams && (n'=tNParams) {
		Set tFormVarNames=""
		#;if no tRawParams then need to use the one generated from iparams
		If tRawParams="" {$$$sysTRACE("Using generated RAWPARMS of "_tGenRawParams) Set tRawRarams = tGenRawParams}
	}

	#; If no IPARAMS then use RAWPARAMS in the URL
	Set tRawParams=$S(""=tFormVarNames&&$L(tRawParams):"?"_tRawParams, 1:"")
	Set ..%HttpRequest.ContentType=tCT
	Set tSC=..constructHTTPRequest(pRequest,tLen,tCT)  Quit:$$$ISERR(tSC) tSC

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
	Set tSC=..Adapter.SendFormDataArray(.tHttpResponse,$S(""=tReq:"POST",1:tReq),..%HttpRequest,tFormVarNames,.tDataArray,$Case(tAdURL,"":tURL,"*":tURL,:tAdURL)_tRawParams)

	If ##class(Ens.Util.Statistics).StatsStarted(..%ConfigName) {
		Set tStatsUserDimension=$LG(pRequest.HTTPHeaders.GetAt("EnsAttribute"),2)
		If (tStatsUserDimension'="") Do ##class(Ens.Util.Statistics).SetStatsUserDimension(..%ConfigName,tStatsUserDimension)
	}

	#; Suppress HTTP status errors and just pass back the status, headers and body
	If $$$ISERR(tSC)&&'$$$StatusEquals(tSC,$$$EnsErrHTTPStatus) { Set ..%HttpRequest=##class(%Net.HttpRequest).%New()  Quit tSC }
	Quit ..constructResponse(tHttpResponse,.pResponse)
}

/// Assemble Envelope and Body into HTTP EntityBody stream
Method constructHTTPRequest(pRequest As EnsLib.SOAP.GenericMessage, pLen As %Integer, pCT As %String) As %Status [ Internal ]
{
	Quit:'pLen $$$OK
	Do ..%HttpRequest.EntityBody.Write()
	Quit ..%HttpRequest.EntityBody.CopyFrom(pRequest.Stream)
}

/// Split response Envelope and Body into separate streams
ClassMethod constructResponse(pHttpResponse As %Net.HttpResponse, pResponse As EnsLib.HTTP.GenericMessage) As %Status [ Internal ]
{
	Set tSC=$$$OK
	If $IsObject(pHttpResponse.Data) {
		Set tStream=pHttpResponse.Data
	} Else {
		Set tStream=##class(%GlobalBinaryStream).%New()
		Set tSC=tStream.Write(pHttpResponse.Data)  Quit:$$$ISERR(tSC) tSC
	}
	Set pResponse=##class(EnsLib.HTTP.GenericMessage).%New(tStream,,pHttpResponse)
	Do pResponse.HTTPHeaders.SetAt(pHttpResponse.StatusLine,"StatusLine")
	Quit tSC
}

}
