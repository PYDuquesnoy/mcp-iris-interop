/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract base class for WebService-based BusinessService classes. Can use a SOAP.InboundAdapter listener, or the standard SOAP Service mechanism, or both.
/// In order for the CSP mechanism to work, Web Services derived from this class must be configured either with their configuration name the same as their
/// class name, or the invoking URL must include ?CfgItem= giving the config item name, or using a CSP application with a DispatchClass configured and the config item name as the next URL piece after the application name.
/// (Configured Web Services exposed using the SOAP Inbound Adapter may also be invoked with this URL parameter but because each configured Inbound Adapter listens on its own TCP/IP port this parameter is just a safety check for them.)
Class EnsLib.SOAP.Service Extends (Ens.Helper.Service.SyncResponseHandler.HTTP, Ens.BusinessService, %SOAP.WebService) [ System = 4 ]
{

/// The SOAP name of this service.
/// Override this parameter in the subclass.
Parameter SERVICENAME = "MyEnsembleRequestWebService";

/// Default URL for invoking the WebService.
/// The URL may be absolute or relative to the WSDL request URL.
/// Override this parameter in your subclass.
/// Example: "http://localhost/csp/MyEnsemble/MyProduction/MyWebService.cls";
Parameter LOCATION;

/// SOAP Namespace for the WebService
/// Override this parameter in your subclass with the unique namespace URI
/// of your organization.
Parameter NAMESPACE = "http://tempuri.org";

/* ----------------------- */
/// Can't do grace period without an OnTask loop
Parameter SETTINGS = "-AlertGracePeriod,SupportDelayedSyncRequest:DelayedResponseSupport,OverrideClientResponseWaitTimeout:DelayedResponseSupport,GatewayTimeout:DelayedResponseSupport";

/// Name of the adapter class - override this to "" if you want to use only the regular SOAP mechanism and not the custom-port InboundAdapter.
Parameter ADAPTER = "EnsLib.SOAP.InboundAdapter";

/// Enables session capability on this Service. Also affects license consumption.
Parameter SOAPSESSION = 0;

/// Override this setting to allow your subclass to accept WebService requests on both the custom-port InboundAdapter and the regular SOAP mechanism.
/// This parameter is ignored and the regular SOAP mechanism is enabled if the ADAPTER parameter is empty in your subclass.
Parameter USEBOTH As %Boolean = 0;

Property SOAPInvoked As %Boolean [ InitialExpression = 0 ];

/// initialize Business Host object
Method %OnNew(pConfigName As %String) As %Status
{
	#; %cspServer instantiates us without a config name. We need to defer initialization.
	Quit:""=$G(pConfigName) $$$OK
	Quit ##class(Ens.BusinessService)$this.%OnNew(.pConfigName)
}

/// Callback before a SOAP request. This callback is meant to be used by InterSystems IRIS
/// and should thus never be overridden in a subclass.
Method OnPreSOAP(mode As %String, action As %String, content) [ Internal ]
{
	Set tSC=$$$OK, tThis=$this, tIsMapped=0
	If ""=..%ConfigName {
		Set ..SOAPInvoked=1
		If '$$$IsdefObject(%request) { Set tConfigName="" }
		Else {
			Set tConfigName=$G(%request.Data("CFGITEM",1),$G(%request.Data("CfgItem",1),$G(%request.Data("cfgitem",1))))
			If ""=tConfigName {
				#; if no Cfg Item named, find the SOAP Service configured with its config name in the (mapped) URL
				Set tURL=$Get(%request.CgiEnvs("REQUEST_URI"))
				If tURL="" Set tURL=%request.URL
				If ($$$GetSecurityApplicationsDispatchClass(%request.AppData)'="") {
					Set tIsMapped = 1
					#; If mapped, try to get config name from URL
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
			}
		}
		#; if no Cfg Item named, find the SOAP Service configured with its config name equal to its classname
		Set:""=tConfigName tConfigName=$$$CurrentClass
		If tIsMapped {
			Set tConfigClass=$G($$$ConfigClassName(tConfigName))
			If ""=tConfigClass||'$classmethod(tConfigClass,"%Extends",$$$CurrentClass) {
				Set tSC=$$$EnsError($S(""=tConfigClass:$$$EnsErrSOAPConfigName,1:$$$EnsErrSOAPConfigClass),tConfigName,tConfigClass)
			} Else {
				Kill tThis
				Set tSC=##class(Ens.Director).CreateBusinessService(tConfigName,.tThis)
				If $$$ISOK(tSC)&&$IsObject(tThis) {
					Set %cspsoapservice=tThis, tSC=..cloneTo(tThis)
				}
			}
		} Else {
			Set %cspsoapservice=$this
			Set tSC=##class(Ens.Director).CreateBusinessService(tConfigName,$this)
		}
		If $$$ISOK(tSC) && $IsObject(tThis.Adapter) && ('tThis.Adapter.%Extends("EnsLib.SOAP.InboundAdapter") || 'tThis.Adapter.EnableStandardRequests) {
			Set tSC=$$$ERROR($$$EnsErrSOAPNotEnabled,tConfigName)
		}
	}
	Set:$$$ISOK(tSC) tSC=tThis.preProcessInput()
	Set:$$$ISOK(tSC) tSC=tThis.OnAuthorize(action,%request)

	#; Construct SOAP fault if error
	If $$$ISERR(tSC) {
		Set:""=%cspsoapservice.SoapFault %cspsoapservice.SoapFault=%cspsoapservice.MakeStatusFault($S($$$StatusEquals(tSC,$$$EnsErrSOAPConfigName,$$$EnsErrSOAPConfigClass):$$$FAULTClient,1:$$$FAULTServer),$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError)),tSC,$$$CurrentClass)
	}
	Do:""'=%cspsoapservice.SoapFault ..ReturnFault(%cspsoapservice.SoapFault)
	Kill %objlasterror
	$$$sysTRACE("Processing "_mode_$S(""=mode:"",1:" ")_"SOAP request '"_action_"'")
}

/// copy/assign all important properties from $this to pNewThis
Method cloneTo(pNewThis As EnsLib.SOAP.Service) As %Status [ Internal ]
{
	Set pNewThis.SOAPInvoked=..SOAPInvoked
	Set pNewThis.SoapVersion=..SoapVersion
	Set pNewThis.ImportHandler=..ImportHandler
	Set pNewThis.Username=..Username
	Set pNewThis.SecurityNamespace=..SecurityNamespace
	Set pNewThis.SoapFault=..SoapFault
	Set pNewThis.SoapVersion=..SoapVersion
	Set pNewThis.SoapFault=..SoapFault
	Quit $$$OK
}

/// Override to add customized authorization behavior
Method OnAuthorize(pAction, pRequest As %CSP.Request) As %Status
{
	Quit $$$OK
}

/// Callback after a SOAP request. This callback is meant to be used by InterSystems IRIS
/// and should thus never be overridden in a subclass.
Method OnPostSOAP() [ Internal ]
{
	$$$sysTRACE("Completed SOAP request"_$S(($D(%objlasterror)&&($$$StatusDisplayString(%objlasterror)'["Ens.Enterprise.MsgBankOperation")):" with error "_$$$StatusDisplayString(%objlasterror),1:" successfully"))
	#; unregister, restoration of <DISCONNECT>  mode and "external interrupts" is done in OnTeardown()
}

/// Callback for allowing Service to override and control construction of the HTTP response if invoked via the SOAP Inbound Adapter
/// Override this method in your Service class to customize the HTTP response <p/>
/// Each argument may be overridden to change a particular aspect of the HTTP response
/// <var>pStatus</var> is the status code that resulted from the SOAP call to the adapter
/// <var>pHTTPResponseStatus</var> is the HTTP status that will be reported to the SOAP client
/// <var>pBodyLen</var> is the response body size in bytes that will be reported to the SOAP client
/// <var>pResponseBodyStream</var> is the stream or string whose contents will be returned as the SOAP response message body
/// <var>pMainResponseHeader</var> if returned with content will be used verbatim as the HTTP header
/// <var>pHeaderExtra</var>  if returned will be used to override the standard no-cache header declarations or append to <var>pMainResponseHeader</var>
Method OnAdapterHTTPResponse(ByRef pStatus As %Status, ByRef pHTTPResponseStatus As %String, ByRef pBodyLen As %Integer, ByRef pResponseBodyStream As %Stream.Object, ByRef pMainResponseHeader As %String, ByRef pHeaderExtra As %String) [ Abstract ]
{
}

/// Deprecated
Method GetLastError() As %Status [ Internal ]
{
	Quit %objlasterror
}

/// Deprecated
Method GetLastErrorText() As %String [ Internal ]
{
	Quit $$$StatusDisplayString(%objlasterror)
}

/// Deprecated
ClassMethod TmpCreate(pName) As Ens.BusinessService [ Internal ]
{
	Set tSC=##class(Ens.Director).CreateBusinessService(pName,.tService)
	If $$$ISERR(tSC) { Set %objlasterror=tSC ZTrap "SOAP" } 
	Quit tService
}

/// Return a fault based on status code to the client - only for use outside %SOAP.Service.Process()/ProcessHTML()
ClassMethod statusReturn(pCode As %String, pStatus As %Status)
{
	Set tFault=..MakeStatusFault(pCode,$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError)),pStatus,$$$CurrentClass)
	Do ..Fault(tFault) ; will send the fault to the SOAP client
}

/// Deprecated - use ReturnStatusFault()
ClassMethod statusError(pCode As %String, pStatus As %Status) [ CodeMode = expression, Internal ]
{
..ReturnStatusFault(.pCode,.pStatus)
}

/// Deprecated - use MakeStatusFault()
ClassMethod ensMakeStatusFault(pFaultCode As %String, pFaultString As %String, pStatus As %Status, pFaultActor As %String) As %SOAP.Fault [ CodeMode = expression, Internal ]
{
..MakeStatusFault(.pFaultCode, .pFaultString, .pStatus, .pFaultActor)
}

/// Deprecated - use ReturnStatusFault()
/// Create a SOAP fault.  Usually returned by ReturnFault method.
/// (Public version of private ..MakeFault())
ClassMethod ensMakeFault(pFaultCode As %String, pFaultString As %String, pDetail As %String, pFaultActor As %String) As %SOAP.Fault [ CodeMode = expression, Internal ]
{
..MakeFault(.pFaultCode, .pFaultString, .pDetail, .pFaultActor)
}

/// Return a fault based on status code to the client
ClassMethod ReturnMethodStatusFault(pStatus As %Status) [ CodeMode = expression ]
{
..ReturnStatusFault($$$EnsFAULTMethod, pStatus)
}

/// Return a fault based on status code to the client
ClassMethod ReturnStatusFault(pCode As %String, pStatus As %Status)
{
	Set tFault=..MakeStatusFault(pCode,$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError)),pStatus,$$$CurrentClass)
	Do ..ReturnFault(tFault) ; will send the fault to the SOAP client; it will ZTRAP and not return here.
}

/* override from superclass to add Set ..%ProcessError so that Adapter can work */
ClassMethod ReturnFault(fault As %SOAP.Fault) [ ServerOnly = 1 ]
{
	Do ..Fault(fault)
	Set tThis=$G(%cspsoapservice,$$$NULLOREF)
	If $IsObject(tThis)&&tThis.%Extends("Ens.BusinessService") {
		Set tThis.%ProcessError=$G(%objlasterror) Set:""=tThis.%ProcessError tThis.%ProcessError=$$$ERROR($$$EnsErrGeneral,"Service SOAP Fault:"_fault.AsString())
		Do:tThis.Adapter=""||$G($$$EnsJobLocal("TCPIn.OutsideJob"))&&(""'=tThis.%ConfigName) tThis.onOutsideErr(tThis.%ProcessError)
	}
	Set %objlasterror=$$$OK ; fault already returned
	ztrap "SOAP"
}

/// Construct fault string; used by Adapter and GenericService classes
ClassMethod OnFaultString(pStatus As %Status, pService As EnsLib.SOAP.Service, pSOAPVer As %String = "1.0") As %String [ Internal ]
{
	Set tSecurityHeader=""
	If ""'=pService.SecurityOut {
		Set tSC=pService.SecurityOut.XMLExportToString(.tSecurityHeader)
		If $$$ISOK(tSC) {
			Set tSecurityHeader=$Replace(tSecurityHeader,"<Security>","<Security xmlns='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' xmlns:hdr='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'>")
			Set tSecurityHeader=$Replace(tSecurityHeader,"<Timestamp>","<Timestamp xmlns='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd'>")
			Set tSecurityHeader="<SOAP-ENV:Header>"_tSecurityHeader_"</SOAP-ENV:Header>"
		}
	}
	If $$$StatusEquals(pStatus,$$$SOAPBadSignature) {
		Set tCodeValue = $S(pSOAPVer="1.2":"Sender",1:"Client")
		Set tText = "Invalid Security"
	} ElseIf $$$StatusEquals(pStatus,$$$EnsErrGeneral) && ("HTTP SOAP request '"=$E($$$StatusText(pStatus),1,$L("HTTP SOAP request '"))) {
		Set tCodeValue = $S(pSOAPVer="1.2":"Sender",1:"Client")
		Set tText = "Invalid Service Name"
	} Else {
		Set tCodeValue = $S(pSOAPVer="1.2":"Receiver",1:"Server")
		Set tText = "Server Application Error"
	}
	Quit:(pSOAPVer'="1.2") "<?xml version='1.0' encoding='UTF-8' standalone='no' ?>"_$C(13,10)_
		"<SOAP-ENV:Envelope xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' SOAP-ENV:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>"_$C(13,10)_
		$S(tSecurityHeader="":"",1:tSecurityHeader_$C(13,10))_
		"  <SOAP-ENV:Body>"_$C(13,10)_
		"   <SOAP-ENV:Fault>"_$C(13,10)_
		"    <faultcode>SOAP-ENV:"_tCodeValue_"</faultcode>"_$C(13,10)_
		"    <faultstring>"_tText_"</faultstring>"_$C(13,10)_
		"    <faultactor>"_$classname(pService)_"</faultactor>"_$C(13,10)_
		"   <detail>"_$C(13,10)_
		"    <error xmlns='"_pService.%GetParameter("NAMESPACE")_"' >"_$C(13,10)_
		"     <text>"_$ZCVT($$$StatusDisplayString(pStatus),"O","XML")_"</text>"_$C(13,10)_
		"    </error>"_$C(13,10)_
		"	</detail>"_$C(13,10)_
		"   </SOAP-ENV:Fault>"_$C(13,10)_
		"  </SOAP-ENV:Body>"_$C(13,10)_
		"</SOAP-ENV:Envelope>"_$C(13,10)

	Quit "<?xml version='1.0' encoding='UTF-8' ?>"_$C(13,10)_
		"<SOAP-ENV:Envelope xmlns:SOAP-ENV='http://www.w3.org/2003/05/soap-envelope' xmlns:XML='http://www.w3.org/XML/1998/namespace'>"_$C(13,10)_
		$S(tSecurityHeader="":"",1:tSecurityHeader_$C(13,10))_
		"  <SOAP-ENV:Body>"_$C(13,10)_
		"   <SOAP-ENV:Fault>"_$C(13,10)_
		"    <SOAP-ENV:Code>"_$C(13,10)_
		"    <SOAP-ENV:Value>SOAP-ENV:"_tCodeValue_"</SOAP-ENV:Value>"_$C(13,10)_
		"    </SOAP-ENV:Code>"_$C(13,10)_
		"    <SOAP-ENV:Reason>"_$C(13,10)_
		"     <SOAP-ENV:Text XML:lang='en'>"_tText_"</SOAP-ENV:Text>"_$C(13,10)_
		"    </SOAP-ENV:Reason>"_$C(13,10)_
		"   </SOAP-ENV:Fault>"_$C(13,10)_
		"  </SOAP-ENV:Body>"_$C(13,10)_
		"</SOAP-ENV:Envelope>"_$C(13,10)
}

/// Log the HTTP headers associated with an input SOAP message.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
/// 
/// Note the corresponding LogOutputHTTPHeaders override is not implemented for direct mode
/// due to location of Header construction
Method LogInputHTTPHeaders() [ Internal, ServerOnly = 1 ]
{
	// If %response object present then falls back to CSP mode (super) using standard requests
	If $isobject($get(%response)) {
		Do ##super()
		Return
	}
	// For direct to Intergration Service port use %iaHeader set up by Adapter
	If $$$CheckSOAPLogStop Quit
	If ('$$$CheckSOAPLogInput) || ('$$$CheckSOAPLogHTTPHeaders) Quit
	Set file=$get(^ISCSOAP("LogFile"))
	If file="" Quit
	
	Try {
		Set open=0,io="",error=""
		Set io=$io
		Open file:"waes":1 else  Set error="Unable to open SOAP log file" Quit
		Set open=1
		Use file
		$$$SETIO("RAW")

		Write !,!,"**** Input HTTP headers for Web Service",!

		Set header="" 
		For {
			Set header=$order(%iaHeader(header),1,value)
			Quit:header=""
			// Leave existing mixed case items
			// EnsConfigName, HTTPVersion, HttpRequest, URL
			continue:header?1(1"EnsConfigName",1"HTTPVersion",1"HttpRequest")
			// Match uppercase header names to follow CSP StandardRequest approach
			if "soapaction"=header {
				Write "SOAPAction: ",value,!
			} else {
				Write $ZCVT(header,"u"),": ",value,!
			}
		}
	} Catch ex {
		Set error="Error during SOAP logging: "_ex.DisplayString()
	}
	
	If error'="" {
		$$$SevereError(error)
		$$$SevereError("SOAP logging will be terminated.")
		// turn off logging
		$$$SOAPDisableLogging
	}

	If open Close file
	If io'="" Use io
	Quit
}

}
