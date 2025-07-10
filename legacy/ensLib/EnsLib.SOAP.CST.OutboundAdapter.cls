/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// An adapter for sending requests to a simple one-object-in, one-object-out service
/// using the CST-over-HTTP protocol that is supported by the EnsLib.SOAP.InboundAdapter.
Class EnsLib.SOAP.CST.OutboundAdapter Extends (EnsLib.TCP.OutboundAdapter, EnsLib.SOAP.CST.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Location URL path to request from the server (optionally including 'http://' and server ip:port address; values here override IPAddress and Port settings); default is LOCATION parameter of BusinessOperation if any
Property Location As %String(MAXLEN = 1000);

/// Proxy server through which to send HTTP requests, if any
Property ProxyServer As %String(MAXLEN = 1000);

/// Proxy server port on which to send HTTP requests, if using a proxy server
Property ProxyPort As %Integer(MAXVAL = 65535, MINVAL = 0) [ InitialExpression = 80 ];

/// Should the proxy (if any) use HTTPS to communicate with the real HTTP/HTTPS server?
Property ProxyHTTPS As %Boolean;

/* Override description */
/// This is the ID name of the set of credentials values (Username, Password) to be used to access the external SOAP/CST server
Property Credentials As %String;

/// Timeout for getting a response from the server (the timeout for opening the connection to the server is always 5 seconds). Setting the timeout to -1 means wait forever.
Property ResponseTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 30 ];

/// These are the production settings for this object
Parameter SETTINGS = "Location,ProxyServer,ProxyPort,ProxyHTTPS";

Property %configPath As %String(MAXLEN = 1000) [ Private ];

Property %configIP As %String(MAXLEN = 1000) [ Private ];

Property %configPort As %String(MAXLEN = 6) [ Private ];

/* override (empty) superclass initial Terminators value */
Property Terminators As %String [ InitialExpression = {$C(10)} ];

/// Set up IPAddress and Port overrides for Location and Proxy settings
Method initIPPort(pInVal As %String) As %Status
{
	; Parse URL, override Server:Port if appropriate
	Set tLocation=..Location
	Set:$Case($ZCVT(tLocation,"L"),"":1,"<default>":1,"default":1,:0) tLocation=..BusinessHost.%GetParameter("LOCATION")
	Set ..%configPath=tLocation
	If ""'=tLocation {
		Set tPrefix=$P(..Location,"://")
		Set:$Case($ZCVT(tPrefix,"L"),"http":1,"https":1,:0) tLocation=$E(tLocation,$L(tPrefix)+4,*)
		Set ..%configPath=tLocation
		Set tAddr=$P(tLocation,"/")
		If $F(tAddr,":")>1||(tAddr?1.3N1"."1.3N1"."1.3N1"."1.3N) { Set ps=$S($L(tAddr,":")<=2:":",1:"|"), tIP=$P(tAddr,ps), tPort=$E(tAddr,$L(tIP)+2,*)
			If ""'=tIP&&(+tPort=tPort||'$L(tPort)) {
				Set ..%configIP=tIP, ..%configPort=tPort
				Set ..%configPath=$E(tLocation,$L(tAddr)+2,*)
			}
		}
	}
	Set:"/"=$E(..%configPath) ..%configPath=$E(..%configPath,2,*)
	
	#; Set the actual IP address & port
	If ""'=..ProxyServer&&+..ProxyPort {
		Set i%IPAddress=..ProxyServer, i%Port=..ProxyPort
		Set:..Port=80&&..ProxyHTTPS i%Port=443
	} Else {
		Set i%IPAddress=..%configIP, i%Port=..%configPort
	}
	Quit $$$OK
}

Method LocationSet(pInVal As %String) As %Status
{
	Set i%Location=pInVal
	Do ..initIPPort()
	Quit $$$OK
}

Method IPAddressSet(pInVal As %String) As %Status
{
	#; don't set the actual IP address if proxy has already overridden it
	Set ..%configIP=pInVal
	Do ..initIPPort()
	Quit $$$OK
}

Method PortSet(pInVal As %String) As %Status
{
	Set ..%configPort=pInVal
	Do ..initIPPort()
	Quit $$$OK
}

Method ProxyServerSet(pInVal As %String) As %Status
{
	Set i%ProxyServer=pInVal
	Do ..initIPPort()
	Quit $$$OK
}

Method ProxyPortSet(pInVal As %String) As %Status
{
	Set i%ProxyPort=pInVal
	Do ..initIPPort()
	Quit $$$OK
}

Method ProxyHTTPSSet(pInVal As %Boolean) As %Status
{
	Set i%ProxyHTTPS=pInVal
	Do ..initIPPort()
	Quit $$$OK
}

Method Invoke(pMethodname As %String, pRequestType As %String, pResponseType As %String, pRequest As %RegisteredObject, Output pResponse As %RegisteredObject) As %Status
{
	Kill pResponse Set pResponse=""
	Set $ZT="SendTrap"
	Do {	
		If 'pRequest.%IsA(pRequestType) Set tSC=$$$ERROR($$$SoapWebMethodArg,$classname(pRequest),pMethodname)  Quit
		If $Case($ZCVT($P(..Location,"://"),"L"), "http":0, "https":0, $ZCVT(..Location,"L"):0, :1) Set tSC=$$$ERROR($$$SOAPHttpOnly,..Location)  Quit
		If ""=..%configPath Set tSC=$$$ERROR($$$SOAPNoLocation,..Location)  Quit
		
		If ..Connected {
			#; Flush trash out of Read buffer. Mostly for debugging but also for recovery
			Use ..Device:(::"+":) ; turn off terminators
			Set tAllJunk="" Do {
				Read tJunk:0
				Set:((""'=tJunk)&&($L(tAllJunk)<1000)) tAllJunk=tAllJunk_$E(tJunk,1,1000-$L(tAllJunk))
			} While ""'=tJunk
ContinSend
			Use ..Device:(::"+":..Terminators) ; turn back on terminators
			If ""'=tAllJunk $$$LOGWARNING("Read unexpected characters '"_tAllJunk_"' before sending '"_pRequestType_"' Request")
		}
		Set tSC=..Connect(..ConnectTimeout)  Quit:$$$ISERR(tSC)
		Write ""_
		"POST "_$S(((""=..ProxyServer)||'+..ProxyPort):"/"_..%configPath, 1:"http"_$S(..ProxyHTTPS:"s",1:"")_"://"_$S(..%configIP[":"&&$L(..%configPort):"["_..%configIP_"]",1:..%configIP)_$S(""=..%configPort:"",1:":")_..%configPort_"/"_..%configPath)_" HTTP/1.0"_$C(13,10)_
		$S(..StayConnected:"",1:"Connection: Close"_$C(13,10))_
		"Host: 127.0.0.1"_$C(13,10)_
		"SOAPAction: "_$E(..%configPath,1,$L(..%configPath)-3)_pMethodname_$C(13,10)_ ; strip ".cls"
		"User-Agent: Mozilla/4.0 (compatible; Cache;)"_$C(13,10)_
		"Content-Type: binary/CST; charset=UTF-8"_$C(13,10)_
		$C(13,10)
		
		#; Export the Request object
	    Do ..exportCST(pRequest,.tLen)
		$$$catTRACE("parse","Exported "_$classname(pRequest)_$S(pRequest.%Extends("%Persistent"):" "_pRequest.%Id(),1:"")_"/"_$IO_" as CST("_tLen_")")
		w *-3 ; flush
		
		#; Read the Response
		
		#; Read raw lines of header, then suck in whole body into a stream
		Set $ZT="RecvTrap", tStartTime=$ZH
		If -1=..ResponseTimeout {
			Read tLine
		} Else {
			Read tLine:..ResponseTimeout Set tTimedOut='$Test
			If tTimedOut {
				if $ZH-tStartTime < (..ResponseTimeout-0.1) { Set tSC=$$$ERROR($$$SOAPNoResponseBody,tLine)  Quit }
				Else { Set tSC=$$$ERROR($$$CSPTimeout,..ResponseTimeout,tLine) }
			}
			Quit:$$$ISERR(tSC)
		}
		Set:$E(tLine,$L(tLine))=$C(13) $E(tLine,$L(tLine))=""
		Set tHeader("version")=$P(tLine," ",1)
		Set tHeader("StatusCode")=$P(tLine," ",2)

		#; 202 response OK for one-way messages.
		If $ZCVT($E(tHeader("version"),1,5),"L")'="http/" Set tSC=$$$ERROR($$$SOAPClientError,tHeader("version"))  Quit
		If (tHeader("StatusCode")'="200")&&(tHeader("StatusCode")'="500") Set tSC=$$$ERROR($$$SOAPUnexpectedStatus,tHeader("StatusCode"))  Quit

		#; read line 2
		Set tStartTime=$zh
		Read tLine:..ReadTimeout Set tTimedOut='$Test
		If tTimedOut {
			If $ZH-tStartTime < (..ReadTimeout-0.1) { Set tSC=$$$ERROR($$$SOAPNoResponseBody,tLine) }
			Else { Set tSC=$$$ERROR($$$CSPTimeout,..ReadTimeout,tLine) }
		}
		Quit:$$$ISERR(tSC)
	
		#; Read the rest of the lines
		Set:$E(tLine,$L(tLine))=$C(13) $E(tLine,$L(tLine))=""
		While ""'=tLine {
			Set tHeader($ZCVT($P(tLine,":"),"L"))=$ZStrip($P(tLine,":",2,$L(tLine,":")),"*W")
			#; read next line
			Set tStartTime=$zh
			Read tLine:..ReadTimeout Set tTimedOut='$Test
			If tTimedOut {
				If $ZH-tStartTime < (..ReadTimeout-0.1) { Set tSC=$$$ERROR($$$SOAPNoResponseBody,tLine)  Quit }
				Else { Set tSC=$$$ERROR($$$CSPTimeout,..ReadTimeout,tLine)  Quit }
			}
			Set:$E(tLine,$L(tLine))=$C(13) $E(tLine,$L(tLine))=""
		}
		Quit:$$$ISERR(tSC)
	
		If "binary/CST"'=$P(tHeader("content-type"),";",1) Set tSC=$$$ERROR($$$SOAPUnexpectedType,tHeader("content-type"),"binary/CST")  Quit
	
		#; Read the body
		Use ..Device:(::"+":) ; turn off terminators
		Set tSC=..importCST(pResponseType,.pResponse,..ReadTimeout)  Quit:$$$ISERR(tSC)
		$$$sysTRACE("Read CST '"_pResponse_"' from :"_..Port_" with timeout="_..ReadTimeout)
	} While 0
Exit
	If ..StayConnected&&..Connected { Use ..Device:(::"+":..Terminators) } ; turn back on terminators
	Else { Do ..Disconnect() }
	Quit tSC

SendTrap
	Set $ZT="RecvTrap",tZE=$ZE,tSC=$$$SystemError
	Do:$G(tZE)["<WRITE>" ..Disconnect()
	GoTo:$G(tZE)["<READ>" ContinSend
	GoTo Exit
RecvTrap
	Set $ZT="",tZE=$ZE,tSC=$$$SystemError
	If $G(tZE)["<READ>" { Do ..Disconnect()  Set tTxt=$$$StatusText(tSC)  If ..StayConnected { $$$LOGWARNING(tTxt) } Else { $$$LOGINFO(tTxt) } Set tSC=$$$OK }
	GoTo Exit
}

}
