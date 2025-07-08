/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %occSAX, %soap, %xmlDOM)

/// Super class for all classes that are to be projected as a Web Service.
/// <br>
/// 
/// The only supported use of this class is as the super class for a WebService.
/// Parameters, properties and methods may be used by the application.
Class %SOAP.WebService Extends (%CSP.Page, %SOAP.WebBase) [ Abstract, Inheritance = right, System = 3 ]
{

/// LOCATION - the URL not including the web service class name which is the location of the web service.
/// If LOCATION is specified, the location for the WSDL is formed by appended <classnme>.cls to the LOCATION value. 
/// LOCATION defaults to the location of this class as used to display the WSDL.  
/// It will need to be overridden only in very unusual circumstances.
Parameter LOCATION As STRING;

/// The SOAPVERSION parameter specifies the version of SOAP which is supported.
/// The SOAPVERSION parameter effects only the WSDL that is created for this service.
/// The version for which requests are accepted is specified by REQUESTVERSON.
/// Possible values for the version are 1.1 and 1.2. The value "" specifies
/// that both SOAP 1.1 and SOAP 1.2 are supported.  The default is "1.1"
Parameter SOAPVERSION As STRING [ Constraint = ",1.1,1.2", Flags = ENUM ] = 1.1;

/// The REQUESTVERSION parameter specifies the version(s) of SOAP which are 
/// supported for a SOAP request.
/// Possible values for the version are 1.1 and 1.2. The value "" specifies
/// that both SOAP 1.1 and SOAP 1.2 are supported.  The default is ""
Parameter REQUESTVERSION As STRING [ Constraint = ",1.1,1.2", Flags = ENUM ];

/// The SOAP 1.1 binding name in the WSDL.  Default is the service name with "Soap" appended.
Parameter SOAPBINDING As STRING;

/// The SOAP 1.2 binding name in the WSDL.  Default is SOAP 1.1 binding with "12" appended.
Parameter SOAP12BINDING As STRING;

/// The SoapVersion property is either "1.1" or "1.2" and indicates the SOAP 
/// version for the current invocation.<br><br>
/// 
/// For a SOAP web service, a request using either SOAP version 1.1 or 1.2 is supported
/// if SOAPVERSION="".  Otherwise, the version specified in SOAPVERSION is supported.
/// The default is support for SOAP 1.1 only.
/// A Misunderstood fault is returned if the request version is not supported.
/// SoapVersion is set to the actual version of request and will be the version of the response. 
Property SoapVersion As %String;

/// Defines the content type of the http SOAP request.
/// Should not be overridden.
Parameter CONTENTTYPE As STRING [ Internal ] = "text/xml";

/// Response is always encoded in UTF-8.
/// Should not be overridden.
Parameter CHARSET As STRING [ Internal ] = "UTF-8";

/// If INCLUDEDOCUMENTATION is true, then include s:documentation in the WSDL schema
/// based on class and property comments.
Parameter INCLUDEDOCUMENTATION As BOOLEAN = 0;

/// The ALLOWREDUNDANTARRAYNAME parameter of a web service class allows the old form of array name in the
/// XML schemas in the web service's WSDL.  If true, then the schemas in the WSDL an array name that is used
/// for an ObjectScript list or a pair type name that is used for an ObjectScript array will be allowed to have a
/// type name = to the item name.  i.e. the old longer format is kept.
Parameter ALLOWREDUNDANTARRAYNAME As BOOLEAN;

/// When SOAPSESSION = 1, then the returned response will have a session header added to allow 
/// the web client to continue the session.
/// Subsequent requests by the client could then contain the session header to maintain the session.
Parameter SOAPSESSION As BOOLEAN = 0;

/// When USECLASSNAMESPACES = 1, then the WSDL of the Web service reflects the namespaces 
/// defined for the referenced classes by the NAMESPACE parameters of those classes.
/// The default, for compatibility with previous versions, is that
/// the NAMESPACE parameters of the referenced classes are ignored when creating the WSDL.
/// If USECLASSNAMESPACES has no value, then the default value from ^ISCSOAP("USECLASSNAMESPACES") is used.
Parameter USECLASSNAMESPACES As BOOLEAN;

/// If the SOAPMETHODINHERITANCE parameter is true (1), then WebMethods are inherited from
/// any super class. 
/// The default for the SOAPMETHODINHERITANCE parameter is false (0) which means no WebMethods
/// are inherited from a super class.
Parameter SOAPMETHODINHERITANCE As BOOLEAN;

/// If SOAPINTERNALWSDL parameter is true (1), then the WSDL produced for the service
/// will include WebMethods which are marked as Internal.  Otherwise, only non-internal
/// WebMethods will be included in the WSDL.
/// The default for SOAPINTERNALWSDL is true (1).
Parameter SOAPINTERNALWSDL As BOOLEAN = 1;

/// If SOAPDISABLEWSDL parameter is true (1), then no WSDL will be returned when the service
/// is invoked with ?wsdl query parameter.
/// The FileWSDL method will still produce the WSDL, since all information is available anyway
/// if the web service class can be call directly from COS.
/// The default is false which will produce a WSDL for the wsdl query parameter.
Parameter SOAPDISABLEWSDL As BOOLEAN;

/// The WS-ReliableMessaging inactivity timeout in seconds.  Default is 10 minutes.
Parameter RMINACTIVITYTIMEOUT As INTEGER = 600;

/// The WS-ReliableMessaging InOrder parameter
Parameter RMINORDER As BOOLEAN;

/// The WS-ReliableMessaging Delivery Assurance parameter
Parameter RMDELIVERYASSURANCE As STRING;

/// Any web service may add instances of any %SOAP.Header subclass to this array.
/// The index is the element name of the header.  The corresponding headers are then added to the 
/// any SOAP fault message.
Property FaultHeaders As array Of %SOAP.Header [ Transient ];

/// WS-Addressing properties to be used if a fault is returned.
/// SOAP headers will be constructed from these properties.
Property FaultAddressing As %SOAP.Addressing.Properties [ Transient ];

/// When the web method is called, this property contains the %SOAP.MsgDescriptor
/// class for the web method.
Property MsgClass As %SOAP.MsgDescriptor [ Transient ];

/// Can be set at the beginning of the web method that is being executed in which case this changes the amount of time the
/// CSP gateway will wait for a response from the server in seconds before it reports the 'Server is not
/// responding' error message. This is useful if you know that this web method is doing an expensive operation
/// that will take a couple of minutes and you want to set the server response timeout on
/// the CSP gateway to a minute and yet wait three minutes for this method to complete. It will just
/// change the server response timeout for this method invocation only. If not set the the CSP gateway uses its
/// default timeout value specified in the CSP gateway configuration.<br><br>
/// The Timeout property is only meaningful if the default CSP transport is being used.  
/// If a user defined transport is used, setting the Timeout is ignored.
Property Timeout As %Integer;

/// Set method for Timeout property
Method TimeoutSet(val As %Integer) As %Status [ Internal ]
{
	If ..saveIO'="",$get(%request)'="",%request.CSPGatewayRequest,
	   $isobject($get(%response)),'%response.InProgress {
		Set io=$io
		Use ..saveIO
		Set i%Timeout=val
		Set %response.Timeout=val
		Use io
	}
	Quit $$$OK
}

/// Save the TCP device
Property saveIO As %String [ Internal, Private, Transient ];

/// Return the SOAP fault in %SOAP.Fault as the result of this
/// web method call.  
/// The ReturnFault method should only be called from the implementation of the WebMethod.
/// This method will not return to its caller.
/// It will act as a Quit from the Web Method with the %SOAP.Fault as 
/// the return value.<p>
/// You can generate a SOAP fault from a web method as in the following example:
/// <example>
/// Set fault=##class(%SOAP.Fault).%New()
/// Set fault.faultcode=$$$FAULTServer
/// Set fault.faultstring="Processing Error"
/// Set fault.detail="<e:myError xmlns:e=""some-URI"">app didn't work</e:myError>"
/// Do ..ReturnFault(fault) ; will not return
/// </example>
ClassMethod ReturnFault(fault As %SOAP.Fault) [ ServerOnly = 1 ]
{
	Do ..Fault(fault,,,,1)
	Set %objlasterror=$$$OK ; fault already returned
	ztrap "SOAP"
}

/// The OnInternalFault method may be overridden by the user to change the default SOAP
///  fault returned by InterSystems IRIS for internal errors.
/// OnInternalFault is passed the fault which may be modified to suit the applications needs.
/// After OnInternalFault returns this fault will be sent to the SOAP client.
/// The %Status that represents the error is also passed.
ClassMethod OnInternalFault(fault As %SOAP.Fault, status As %Status) [ Private, ServerOnly = 1 ]
{
	Quit
}

/// Return a SOAP fault based on a %Status value.
/// This method is meant for internal use only not use by the web method.
ClassMethod ReturnInternalStatusFault(pStatus As %Status, soap12 As %Boolean = 0) [ Internal, ServerOnly = 1 ]
{
	Set FaultCode=$$$FAULTServer
	Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
	Set fault=..MakeStatusFault(FaultCode,FaultReason,pStatus)
	Do ..Fault(fault,1,,soap12)
}

/// Create a SOAP fault based on a %Status value.
ClassMethod MakeStatusFault(pFaultCode As %String, pFaultString As %String, pStatus As %Status = "", pFaultActor As %String = "") As %SOAP.Fault [ ServerOnly = 1 ]
{
	If $get(pFaultCode)="" Set pFaultCode=$$$FAULTServer
	If $get(pFaultString)="" Set pFaultString=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
	Set detail=$c(13,10)_"    <error xmlns='"_..#NAMESPACE_"'>"_$c(13,10)
	Do DecomposeStatus^%apiOBJ(pStatus,.err)
	Set index=1
	While index'="" {
		Set detail=detail_"     <text>"_$ZConvert(err(index),"O","XML")_"</text>"_$c(13,10)
		Set index=$order(err(index))
	}
	Set detail=detail_"    </error>"_$c(13,10)
	Set fault=..MakeFault(pFaultCode,pFaultString,detail,pFaultActor)
	Do ..OnInternalFault(fault,pStatus)
	Quit fault
}

/// Create a SOAP security fault.
/// The namespace for this security fault is found in SecurityNamespace property.
/// Valid values for FaultCode are "FailedAuthentication", "FailedCheck",
///   "InvalidSecurity", "InvalidSecurityToken", "SecurityTokenUnavailable",
///   "UnsupportedAlgorithm" and "UnsupportedSecurityToken".
ClassMethod MakeSecurityFault(pFaultCode As %String, securityNamespace As %String) As %SOAP.Fault [ ServerOnly = 1 ]
{
	If pFaultCode="FailedAuthentication" {
		Set FaultString="The security token could not be authenticated or authorized"
	} ElseIf pFaultCode="FailedCheck" {
		Set FaultString="The signature or decryption was invalid"
	} ElseIf pFaultCode="InvalidSecurity" {
		Set FaultString="An error was discovered processing the &lt;wsse:Security&gt; header"
	} ElseIf pFaultCode="InvalidSecurityToken" {
		Set FaultString="An invalid security token was provided"
	} ElseIf pFaultCode="SecurityTokenUnavailable" {
		Set FaultString="Referenced security token could not be retrieved"
	} ElseIf pFaultCode="UnsupportedAlgorithm" {
		Set FaultString="An unsupported signature or encryption algorithm was used"
	} ElseIf pFaultCode="UnsupportedSecurityToken" {
		Set FaultString="An unsupported token was provided"
	} ElseIf pFaultCode="MessageExpired" {
		Set FaultString="The message has expired"
	} Else {
		Set FaultString="Unknown security fault"
	}
	Set fault=..MakeFault(pFaultCode,FaultString,"","")
	
	Set ns=$select($get(securityNamespace)'="":securityNamespace,1:"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd")
	Set fault.faultcode="wsse:"_fault.faultcode
	Set fault.faultPrefixDefinition="xmlns:wsse="""_ns_""""
	Set fault.WSSecurityFault=1
	
	Quit fault
}

/// Create a SOAP fault.  Usually returned by ReturnFault method.
ClassMethod MakeFault(pFaultCode As %String, pFaultString As %String, pDetail As %String = "", pFaultActor As %String = "") As %SOAP.Fault [ ServerOnly = 1 ]
{
	Set fault=##class(%SOAP.Fault).%New()
	Set fault.faultcode=pFaultCode
	Set fault.faultstring=pFaultString
	Set fault.detail=pDetail
	Set fault.faultactor=pFaultActor
	Quit fault
}

/// Create a SOAP 1.2 fault.
ClassMethod MakeFault12(pFaultCode As %String, pFaultString As %String, pDetail As %String = "", pFaultActor As %String = "") As %SOAP.Fault [ ServerOnly = 1 ]
{
	Set fault=##class(%SOAP.Fault12).%New()
	Set fault.Code=..MakeFault12Code(pFaultCode)
	Do fault.Reason.Insert(..MakeFault12Text(pFaultString))
	Set fault.Detail=pDetail
	Set fault.Role=pFaultActor
	Quit fault
}

/// Create a SOAP 1.2 fault code field.
ClassMethod MakeFault12Code(code As %String) As %SOAP.Fault12.Code [ Internal, ServerOnly = 1 ]
{
	Set coderef=##class(%SOAP.Fault12.Code).%New()
	Set coderef.Value=code
	Quit coderef
}

/// Create a SOAP 1.2 fault text field.
ClassMethod MakeFault12Text(text As %String, language As %String) As %SOAP.Fault12.Code [ Internal, ServerOnly = 1 ]
{
	Set textref=##class(%SOAP.Fault12.Text).%New()
	Set textref.lang=$get(language,$$$SessionLanguage)
	Set textref.Text=text
	Quit textref
}

/// Write a SOAP fault to the current device.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
ClassMethod Fault(fault As %SOAP.Fault, forceHeaders As %Boolean = 0, forceXML As %Boolean = 0, soap12 As %Boolean = 0, callPostWebMethod As %Boolean = 0) [ Internal, ServerOnly = 1 ]
{
	Set isService=$isobject($get(%cspsoapservice)) && %cspsoapservice.%Extends("%SOAP.WebService")
	
	#; Restore TCP output device
	If isService {
		Do %cspsoapservice.%RestoreTCPDevice()
	}

	Set iscsoap=(($get(%request)'="") && $data(%request.CgiEnvs("HTTP_ISCSOAP")))
	If 'iscsoap && isService {
		Set soap12=(%cspsoapservice.SoapVersion="1.2")
	}
	Set soap12fault=(soap12 && fault.%IsA("%SOAP.Fault12"))
	
	If ($get(%response)'="") {
		If soap12fault {
			Set %response.Status=$select(fault.Code.Value=$$$FAULTSender:400,1:500)
		} Else {
			Set %response.Status=$select(fault.faultcode=$$$FAULTClient:400,1:500)
		}
	}

	// Need to call OnPostWebMethod before returning fault to allow fault status to be adjusted.
	If callPostWebMethod,$$$comMemberKeyGet($classname(),$$$cCLASSmethod,"OnPostWebMethod",$$$cMETHrunnable) {
		Try {
			Do ..%New().OnPostWebMethod()
		} Catch exPost {
		}
	}

	If (($get(%response)'="") && (forceHeaders || '%response.InProgress || (($get(%request)'="") && %request.CSPGatewayRequest))) {
		Do %response.Abort()
		If '%response.InProgress {  ;; Abort successful
			Set %response.ContentType=$select(forceXML:"text/xml",iscsoap:"application/octet-stream",soap12:"application/soap+xml",1:"text/xml")
			Do %response.WriteHTTPHeader(.dummy)
		}
	}

	Set env=..#SOAPPREFIX
	Set ns=$select(soap12:$$$SOAP12ENVns,1:$$$SOAPENVns)
	Set faultHeaders=(isService && ((%cspsoapservice.FaultHeaders.Count()>0) || (%cspsoapservice.FaultAddressing'="")))

	If iscsoap {
		Set binwriter=##class(%SOAP.Binary).%New()
		Do binwriter.WriteSOAPFault(fault)
		Quit
	} 
	
	Set logOutput=(('$$$CheckSOAPLogStop)&&($$$CheckSOAPLogOutput))
	If logOutput {
		Set io=$io
		Set stream=##class(%FileBinaryStream).%New()
		Set sc=stream.Write("") ; force stream's file to open
		If $$$ISOK(sc) {
			Set file=stream.Filename ; get filename and make current device
			Use file:(/NOXY)
			$$$SETIO("UTF8")
		} Else {
			Set logOutput=0
		}
	}

	If soap12fault {
		Set code=fault.Code.Value
		If code'[":" Set fault.Code.Value=env_":"_code
		Set writer=##class(%XML.Writer).%New()
		Set writer.Indent=1
		Do writer.AddNamespace(ns,env)
		If faultHeaders && (%cspsoapservice.FaultAddressing'="") {
			Set addrNamespace=%cspsoapservice.FaultAddressing.Namespace()
			Do writer.AddNamespace(addrNamespace,"wsa")
		}
		Set plist=fault.faultPrefixDefinition
		For i=1:1:$length(plist," ") {
			Set p=$piece(plist," ",i)
			If $length(p,"xmlns:")=2 {
				Do writer.AddNamespace($piece(p,"""",2),$piece($piece(p,"xmlns:",2),"=",1))
			}
		}
		Set writer.SuppressXmlns=1
		Do writer.RootElement("Envelope",$$$SOAP12ENVns)
		If faultHeaders {
			do writer.Write("")
			Set writer.Namespaces.SuppressXmlns=0
			do %cspsoapservice.WriteFaultHeaders(writer.Namespaces)
			Set writer.Namespaces.SuppressXmlns=1
		}
		Do writer.Element("Body",$$$SOAP12ENVns)
		Do writer.Object(fault)
		Do writer.EndElement()
		Do writer.EndElement()
		If code'="" Set fault.Code.Value=code

	} Else {
		Set code=$tr(fault.faultcode,$c(0))
		If code'[":" Set code=env_":"_code
		Set reason=$zcvt($tr(fault.faultstring,$c(0)),"O","XML")
		Set actor=$zcvt($tr(fault.faultactor,$c(0)),"O","XML")
		Set detail=$tr(fault.detail,$c(0))
		Write "<?xml version='1.0' encoding='UTF-8' standalone='no' ?>",!
		Write "<"_env_":Envelope xmlns:"_env_"='"_ns_"'"
		Write " xmlns:xsi='"_$$$XSIns_"' xmlns:s='"_$$$XSDns_"'"
		If faultHeaders {
			Set namespaces=##class(%XML.Namespaces).%New()
			Do namespaces.AddNamespace(ns,env)
			If %cspsoapservice.FaultAddressing'="" {
				Set addrNamespace=%cspsoapservice.FaultAddressing.Namespace()
				Do namespaces.AddNamespace(addrNamespace,"wsa")
				Write " xmlns:wsa='"_addrNamespace_"'"
			}
			Do namespaces.DefineAllNamespacePrefixes()
		}
		If $tr(fault.faultPrefixDefinition,$c(0))'="" Write " "_fault.faultPrefixDefinition
		Write " >",!
		If faultHeaders do %cspsoapservice.WriteFaultHeaders(namespaces)
		Write "  <"_env_":Body>",!
		Write "    <"_env_":Fault>",!
		If soap12 {
			If fault.WSSecurityFault {
				Write "      <"_env_":Code><"_env_":Value>"_env_":Sender</"_env_":Value>"
				Write "<"_env_":Subcode><"_env_":Value>"_code_"</"_env_":Value></"_env_":Subcode>"
				Write "</"_env_":Code>",!
     		} Else {
				If code=(env_":"_$$$FAULTClient) Set code=env_":"_$$$FAULTSender
				If code=(env_":"_$$$FAULTServer) Set code=env_":"_$$$FAULTReceiver
				Write "      <"_env_":Code><"_env_":Value>"_code_"</"_env_":Value></"_env_":Code>",!
			}
			Write "      <"_env_":Reason><"_env_":Text xml:lang='"_$$$SessionLanguage_"'>"_reason_"</"_env_":Text></"_env_":Reason>",!
			If actor'="" Write "      <"_env_":Role>"_actor_"</"_env_":Role>",!
			Write "      <"_env_":Detail>"_detail_"</"_env_":Detail>",!
		} Else {
			Write "      <faultcode>"_code_"</faultcode>",!
			Write "      <faultstring>"_reason_"</faultstring>",!
			If actor'="" Write "      <faultactor>"_actor_"</faultactor>",!
			Write "      <detail>"_detail_"</detail>",!
		}
		Write "    </"_env_":Fault>",!
		Write "  </"_env_":Body>",!
		Write "</"_env_":Envelope>",!
	}

	If logOutput {
		Use io
		$$$SOAPLogOutputHTTPHeaders
		Do ..LogOutput(1,$select(isService:%cspsoapservice.Action,1:""),stream)
		$$$SETIO("RAW")
		Do stream.OutputToDevice()
	}
	Quit
}

/// Write the headers for the fault
Method WriteFaultHeaders(namespaces As %XML.Namespaces) [ Internal, ServerOnly = 1 ]
{
	Set headers=..HeadersOut
	Set addressing=..AddressingOut
	Set ..HeadersOut=..FaultHeaders
	Set ..AddressingOut=..FaultAddressing
	
	Do ..WriteSOAPHeaders("literal",namespaces,"")
	
	Set ..HeadersOut=headers
	Set ..AddressingOut=addressing
}

/// Write a WSDL to a file
ClassMethod FileWSDL(fileName As %String, includeInternalMethods As %Boolean = 1) As %Status [ ServerOnly = 1 ]
{
	Set sc=$$$OK,tIO=$IO

	Open fileName:("wsn":/NOXY):0 Else  Quit $$$ERROR($$$FileCanNotOpen,fileName)
	Use fileName:(/NOXY) 

	#; must output in UTF-8 format
	Do $ZU(96,18,2,"UTF8")
	Set sc=##class(%XML.Implementation).GenerateWSDL($classname(),includeInternalMethods)
	Close fileName

	Quit sc
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.
ClassMethod OnPage() As %Status [ Internal, ServerOnly = 1 ]
{
	If $Data(%request.Data("WSDL"))!$Data(%request.Data("wsdl")) {
		#; If it's a WSDL Request, just generate the WSDL for the client
		Quit ##class(%XML.Implementation).GenerateWSDL($classname(),..#SOAPINTERNALWSDL)

	} Else {
		#; Create the web service instance
		Set service=$select($isobject($get(%cspsoapservice)):%cspsoapservice,1:..%New())

		#; Process as SOAP or HTTP page
		If "noheader"'=$ZCVT($parameter(service,"SECURITYIN"),"L") {
			Do service.SessionCookieSetInternal(%session.CSPSessionCookie)
		}
		/// Refresh filter on each new request
		$$$CheckSOAPLogConfig($$$CheckIsSOAPLogUrlDefault,$classname(),$$$SOAPLogStopFlag,logStep)

		If $data(%request.CgiEnvs("HTTP_SOAPACTION")) || (service.SoapVersion="1.2") {
			Set tAction=$$$URLDECODE($get(%request.CgiEnvs("HTTP_SOAPACTION")))
			If $isobject(%request.Content) {
				Set content=%request.Content
				Set requestStream=content
			} Else {
				Set index=%request.NextMimeData("")
				Set requestStream=$select(index="":"",1:%request.GetMimeData(index))
				While index'="" {
					Set stream=%request.GetMimeData(index)
					Set content(stream.MimeSection)=stream
					Set index=%request.NextMimeData(index)
				}
			}
			If '$isobject($get(%cspsoapservice)) {
				Do ..Initialize(tAction,requestStream,.soapImportHandler,.username,.password,.soapSecurityNamespace,.soapFault,,$classname())
				Set service.ImportHandler=soapImportHandler
				Set service.Username=username
				Set service.Password=password
				Set service.SecurityNamespace=soapSecurityNamespace
				Set service.SoapFault=soapFault
			}
			Set service.SecurityIn=%cspsoapSecurityHeader
			Kill %cspsoapSecurityHeader

			// Call OnPreSOAP before %SaveTCPDevice to allow Ensemble access to the TCP device
			Do service.OnPreSOAP("SOAP",tAction,%request.Content)
			Set:$isobject($get(%cspsoapservice)) service=%cspsoapservice
			Do service.%SaveTCPDevice()
			Do service.Process(tAction,.content,1)

		} ElseIf $data(%request.CgiEnvs("HTTP_ISCSOAP")) {
			Set tAction=$$$URLDECODE(%request.CgiEnvs("HTTP_ISCSOAP"))
			// Call OnPreSOAP before %SavTCPDevice to allow Ensemble access to the TCP device
			Do service.OnPreSOAP("binary",tAction,%request.Content)
			Set:$isobject($get(%cspsoapservice)) service=%cspsoapservice
			Do service.%SaveTCPDevice()
			Do service.ProcessBinary(tAction,%request.Content)

		} Else {
			If '$system.Security.Check("%Development","USE") Quit $$$ERROR($$$NoDevloperPriv)
			Do service.OnPreSOAP("test","","")
			Set:$isobject($get(%cspsoapservice)) service=%cspsoapservice
			Do service.ProcessHTTP()
		}
		Do service.OnPostSOAP()
	}
	Quit $$$OK
}

/// Callback when a SOAP request message has been received.  
/// The OnRequestMessage callback is called after security processing has taken place.
/// This callback will not be called in the case of a security error.<br><br>
/// 
/// The mode argument specifies the type of SOAP request "SOAP" or "binary".<br>
/// The action argument contains the value of SOAPAction header.<br>
/// The request argument contains the SOAP request message in a stream.<br><br>
/// The CSP %request object is available at the time of the call.
/// The %request.Content property will contain the raw request message.
/// For a MIME SOAP request, the individual MIME parts may be retrieved using the %request.NextMimeData method.<br>
/// Various properties of the web service class that are set during initiaization may be useful:
/// ImportHandler - DOM for parsed SOAP request message.<br>
/// SecurityIn - Security header<br>
/// SecurityNamespace - Namespace for Security header<br>
/// SoapFault - set if SOAP faut has been generated.<br><br>
/// 
/// If the SoapFault property is set by the OnRequestMessage callback, then a SOAP fault will be
/// written instead of calling the web method.  The ReturnFaut method should not be called from OnRequestMessage.
Method OnRequestMessage(mode As %String, action As %String, request As %Stream.Object) [ ServerOnly = 1 ]
{
	Quit
}

/// The %OnCreateRMSession web service callback is invoked at the start of WS-ReliableMessaging session
/// before the %SOAP.RM.CreateSequenceResponse is returned.
/// The response argument has been completely created and not yet returned at this point.
/// The reason for this callback is to allow the web service to add any required Security header elements.
/// If WS-Policy is used, then WS-Policy support does this automatically.
Method %OnCreateRMSession(response As %SOAP.RM.CreateSequenceResponse) [ ServerOnly = 1 ]
{
	Quit
}

/// Callback before a SOAP request.  This callback meant to be used by Interoperability
/// and should thus never be specified for a subclass of Enslib.SOAP.Service<br><br>
/// 
/// The mode argument specifies the type of SOAP request "SOAP", "binary" or "test".<br>
/// The pAction argument contains the value of SOAPAction header.<br>
/// The request argument contains the SOAP request.  For a normal SOAP request, the request
/// argument will be a stream containing the request.  For a MIME SOAP request,
/// the request argument will be a multidimensional array of %CSP.Streams that is subscripted 
/// by the position in the original multipart message.  request(1) is the SOAP message.<br><br>
/// 
/// If the SoapFault property has been set, then a SOAP fault will be
/// written instead of calling the web method.  This callback may also set the
/// SoapFault property in order to return a SOAP fault.
Method OnPreSOAP(mode As %String, action As %String, request) [ Internal, ServerOnly = 1 ]
{
}

/// Callback after a SOAP request.  This callback meant to be used by Interoperability
/// and should thus never be specified for a subclass of Enslib.SOAP.Service.
Method OnPostSOAP() [ Internal, ServerOnly = 1 ]
{
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
ClassMethod OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	#; If it's a soap request then just return
	If $isobject($get(%cspsoapservice)) && (%cspsoapservice.SoapVersion="1.2") {
		If ..#GZIPOUTPUT Set %response.GzipOutput=1
		Quit 1
	} ElseIf $data(%request.CgiEnvs("HTTP_SOAPACTION")) {
		If ..#GZIPOUTPUT Set %response.GzipOutput=1
		Quit 1
	} ElseIf $data(%request.CgiEnvs("HTTP_ISCSOAP")) {
		Set %response.ContentType="application/octet-stream"
		Set %response.CharSet=""
		If ..#GZIPOUTPUT Set %response.GzipOutput=1
		Quit 1
	}
	
	#; If it's a wsdl request then just return
	If $Data(%request.Data("WSDL",1)) || $Data(%request.Data("wsdl",1)) {
		#; Check for disabled WSDL
		If ..#SOAPDISABLEWSDL {
			Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$CSPIllegalRequest))
		}
		Quit 1
	}
	
	#; If it's an http operation such as HTTP GET/POST just return
	If $Data(%request.Data("soap_method",1)) {
		#; %SOAP.WebSAerviceInvoke permission needed in order to make direct method calls with HTTP
		#; in order to prevent avoiding WS-Security checking.
		If '$$AllowPercentClass^%SYS.cspServer("%SOAP.WebServiceInvoke",%request.AppMatch) {
			Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$CSPIllegalRequest))
		}
		Quit 1
	}
	
	#; We are returning HTML
	If '$$AllowPercentClass^%SYS.cspServer("%SOAP.WebServiceInfo",%request.AppMatch) {
		Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$CSPIllegalRequest))
	}
	Set %response.ContentType="text\html"
	#; Describe the webservice to the user
	Set %response.ServerSideRedirect="%SOAP.WebServiceInfo.cls?CLS="_$ZCVT($classname(),"O","URL")
	Quit 1
}

/// Use OnHTTPHeader to delay writing of HTTP headers until output is to begin
/// for the SOAP case to allow Content-Type to be changed for SOAP with Attachments response..
ClassMethod OnHTTPHeader(ByRef OutputBody As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	If '$Data(%request.Data("WSDL")) && '$Data(%request.Data("wsdl")) &&
	   ($data(%request.CgiEnvs("HTTP_SOAPACTION")) ||
	    $data(%request.CgiEnvs("HTTP_ISCSOAP")) ||
	    ($isobject($get(%cspsoapservice)) && (%cspsoapservice.SoapVersion="1.2"))) {
		// Skip headers until later
		Set OutputBody=1
	} Else {
		Do %response.WriteHTTPHeader(.OutputBody)
	}

	Quit $$$OK
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
Method ProcessHTTP() [ Internal, ServerOnly = 1 ]
{
	// Indicate that we are in web service
	Set %cspsoapservice=$this

	Set sc=$$$OK
	
	#; Log Http headers
	$$$SOAPLogInputHTTPHeaders

	#; Set SoapVersion
	Set ..SoapVersion=..#SOAPVERSION
	If ..SoapVersion="" Set ..SoapVersion="1.1"
	
	If ..SoapFault'="" Goto ProcessHttpExit
	
	#; Disable the test page if web services are disabled.
	If '$$$GetSecurityApplicationsInbndWebServicesEnabled(%request.AppData) {
	 	Set sc=$$$ERROR($$$ServiceNotEnabledForApplication,"SOAP",%request.Application) 
		Set tFaultCode=$$$FAULTServer
		Set tFaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
		Goto ProcessHttpExit
	}
	
	#; Create an instance of the msg descriptor class
	Set methodName=%request.Get("soap_method")
	Set tDescriptor=$zobjclassmethod($zobjclass()_"."_methodName,"%New")
	If '$isObject(tDescriptor) Set sc=$$$ERROR($$$CannotCreateObject,$zobjclass()_"."_%request.Get("soap_method"))
	If $$$ISERR(sc) {
		Set tFaultCode=$$$FAULTServer
		Set tFaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
	}
	
	#; Setup the HTTP request
	If $$$ISOK(sc) {
		Set tFaultCode=$$$FAULTClient
		Set sc=tDescriptor.ProcessHTTP()
		If $$$ISERR(sc) {
			Set tFaultCode=$$$FAULTClient
			Set tFaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
		}
	}
	
	#; If SOAPSESSION, then add the SOAP session header
	If ..#SOAPSESSION && (..SessionCookie'="") {
		Set sessionHeader=##class(%SOAP.SessionHeader).%New()
		Set sessionHeader.SessionCookie=..SessionCookie
		Do ..HeadersOut.SetAt(sessionHeader,"CSPCHD")
	}
	
	#; Invoke the HTTP request
	If $$$ISOK(sc) {
		Set tFaultCode=$$$FAULTServer
		Set tFaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		Try {
			Do tDescriptor.InvokeService($this)
		} Catch ex {
			If $ze'["<ZSOAP>" {
				Set sc=..HandleException(ex)
			} Else {
				Goto ProcessHttpExit
			}
		}
	}
	
	If $$$ISOK(sc) {
		If tDescriptor.%ResponseName="" Set tDescriptor.%ResponseName=methodName_"Response"
		Set sc=..WriteSOAPMessage(tDescriptor,tDescriptor.%ResponseName,1,"")
		If $$$ISERR(sc) {
			Set tFaultCode=$$$FAULTServer
			Set tFaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		}
	}
	If $$$ISOK(sc) {
		$$$SOAPLogOutputHTTPHeaders
	}

ProcessHttpExit
	#; Return SOAP fault if error
	If $$$ISERR(sc),(..SoapFault="") {
		Set ..SoapFault=..MakeStatusFault(tFaultCode,tFaultReason,sc)
	}
	If ..SoapFault'="" Do ..Fault(..SoapFault,,1)
	Quit
}

/// Process a SOAP request from a transport class.<br><br>
/// Arguments:
/// <ul>
///    <li>action -- specifies the WebMethod to invoke as pkg.classname.methodname</li>
///    <li>request -- contains the SOAP request.  For a normal SOAP request, the request
///        argument will be a stream containing the request.  For a SOAP with Attachments format request,
///        the request argument will be a multidimensional array of %CSP.Streams that is subscripted 
///        by the position in the original multipart message.  request(1) is the SOAP message.</li>
///    <li>responseStream -- the stream to which the response SOAP message is to be written.
///         If responseStream is not specified a new %FileBinaryStream is created for the response.</li>
/// </ul>
/// The <method>Reset</method> method must be called before calling the OnSOAPRequest method again from this %SOAP.WebService instance.
Method OnSOAPRequest(action As %String, ByRef request, ByRef responseStream As %BinaryStream) [ ServerOnly = 1 ]
{
	// Reset the service if this is an additional call to the same instance.
	If '$data(%cspsoapSecurityHeader),..ImportHandler'="" {
		Do ..Reset()
	}

	/// Refresh filter on each new request
	$$$CheckSOAPLogConfig($$$CheckIsSOAPLogUrlDefault,$classname(),$$$SOAPLogStopFlag,logStep)
	
	// Initialize web service
	// It is possible that the service was already initialized by calling the Initialize method
	If ..ImportHandler="" {
		If $get(request)="" {
			Set index=$order(request(""),1,requestStream)
		} Else {
			Set requestStream=request
		}
		Do ..Initialize(action,requestStream,.soapImportHandler,.username,.password,.soapSecurityNamespace,.soapFault,,$classname())
		Set ..ImportHandler=soapImportHandler
		Set ..Username=username
		Set ..Password=password
		Set ..SecurityNamespace=soapSecurityNamespace
		Set ..SoapFault=soapFault
	}
	Set ..SecurityIn=%cspsoapSecurityHeader
	Kill %cspsoapSecurityHeader

	// Setup responseStream for service output
	Set io=$io
	If '$data(responseStream) || '$isObject(responseStream) {
		Set responseStream=##class(%FileBinaryStream).%New()
		Set filestream=1
	} Else {
		Set filestream = responseStream.%IsA("%Library.FileBinaryStream")
	}
	
	If filestream {
		Set stream=responseStream
	} Else {
		Set stream=##class(%FileBinaryStream).%New()
	}
	
	Do stream.Write("") ; force stream's file to open
	Set file=stream.Filename ; get filename and make current device
	Use file:(/NOXY)
	$$$SETIO("UTF8")
	
	// Invoke the web method
	Do ..%SaveTCPDevice()
	Do ..Process(action,.request,0)
	
	// Restore original io device
	// Don't Close file to leave stream positioned
	Use io
	
	// Reset web service for reuse if desired.
	Do ..Reset()
	
	// Copy result to user's stream.
	If filestream Quit
	Do responseStream.CopyFrom(stream)
}

/// Process a request to start a WS-SecureConversation context that is represented by 
/// the RequestSecurityToken body in the RST argument.
/// If successful a RequestSecurityTokenResponseCollection is returned which will act as the %SOAP.MsgDescriptor for this request.<br>
/// If a fault is to be returned, the %SOAP.fault instance should be assigned to the SoapFault property and "" returned.<br><br>
/// 
/// The default behavior of this method is return a RequestSecurityTokenResponseCollection element based
/// on the WS-Policy associated with this web service.  If no policy alternative is found which can
/// return a RequestSecurityTokenResponseCollection, then SoapFault is set to a wst:BadRequest fault.
Method OnStartSecureConversation(RST As %SOAP.WST.RequestSecurityToken) As %SOAP.WST.RequestSecurityTokenResponseCollection [ ServerOnly = 1 ]
{
	If $data(..policyAlternative) {
		Merge alternative=..policyAlternative
		Set response=##class(%SOAP.Security.Policy).GetResponseSecurityToken($this,RST,.alternative)
	} Else {
		Set response=""
	}
	
	If response="" {
		Set ..SoapFault=##class(%SOAP.WST.RequestSecurityTokenResponse).MakeFault("BadRequest")
	}
	
	Quit response
}

/// Process a request to cancel a WS-SecureConversation context that is represented by 
/// the RequestSecurityToken body in the RST argument.
/// If successful a RequestSecurityTokenResponseCollection is returned which will act as the %SOAP.MsgDescriptor for this request.<br>
/// If a fault is to be returned, the %SOAP.fault instance should be assigned to the SoapFault property and "" returned.<br><br>
Method OnCancelSecureConversation(RST As %SOAP.WST.RequestSecurityToken) As %SOAP.WST.RequestSecurityTokenResponseCollection [ ServerOnly = 1 ]
{
	Set collection=RST.CreateCancelResponse($this,.error)
	If error'="" {
		Set ..SoapFault=##class(%SOAP.WST.RequestSecurityTokenResponse).MakeFault("InvalidRequest")
		Quit ""
	}
	Quit collection
}

/// Initialize a SOAP request.  
/// The Initialize method must be called before the Process method to parse the
/// SOAP message and process the security header.<br>
/// The request argument contains the SOAP request.  For a normal SOAP request, the request
/// argument will be a stream containing the request.  For a SOAP with Attachments format request,
/// the request argument will be a multidimensional array of %CSP.Streams that is subscripted 
/// by the position in the original multipart message.  request(1) is the SOAP message.<br>
/// 
/// If the Initialize method wishes to return an error, it will set the SoapFault property
/// to the appropriate fault to call.  The caller should immediately call the Process method
/// to actually return the SOAP fault.<br>
/// 
/// The properties Username and Password may be set based on the security header.
/// The property SessionCookie may be set based on the session header.<br>
/// 
/// This method is meant to be used by SOAP transport classes.
ClassMethod Initialize(pAction As %String, requestStream, ByRef importHandler As %XML.Document, ByRef username As %String, ByRef password As %String, ByRef securityNamespace As %String, ByRef fault As %SOAP.Fault, securityIn As %String = "ignore", soapClassname As %String) [ Final, ServerOnly = 1 ]
{
	Set $zt="InitializeSOAPError"
	
	Set (importHandler,username,password,securityNamespace,fault,%cspsoapSecurityHeader)=""

	if ('$Data($$$SOAPLogStopFlag)) {
		$$$CheckSOAPLogConfig($$$CheckIsSOAPLogUrlDefault,$G(soapClassname),$$$SOAPLogStopFlag,logStep)
	}

	$$$SOAPTimer("si")
	Set FaultCode=$$$FAULTClient
	Set FaultReason=""
	Set securityFound=0
	If $get(soapClassname)'="",##class(%SOAP.Policy).PolicyExists(soapClassname,"") {
		Set securityIn="allow"
	} Else {
		Set securityIn=$zcvt(securityIn,"L")
	}
	
	#; Log the request
	$$$SOAPLogInput(1,pAction,requestStream,"")
	If "noheader"=securityIn Set sc=$$$OK Goto InitializeSOAPExit
	
	#; Verify a request body is present
	If requestStream="" {
		Set sc=$$$ERROR($$$SOAPNoBody)
		Goto InitializeSOAPExit
	}

	#; Get an XML content handler that parses message into XML DOM 
	Set importHandler=##class(%XML.Reader).GetNewDocument($parameter(soapClassname,"USEPPGHANDLER"))
	If importHandler="" {
		Set sc=$$$ERROR($$$CannotCreateObject,"%XML.Document")
		Goto InitializeSOAPExit
	}
 	Set importHandler.KeepWhitespace=1 // Need whitespace for XMLImport
	#; and an entity resolver
	Set tResolver=##Class(%XML.SAX.EntityResolver).%New()
	If tResolver="" {
		Set sc=$$$ERROR($$$CannotCreateObject,"%XML.SAX.EntityResolver")
		Goto InitializeSOAPExit
	}
	#; Parse the message into XML DOM
	Set sc=##Class(%XML.SAX.Parser).ParseStream(requestStream,importHandler,tResolver,$$$SAXFULLDEFAULT-$$$SAXVALIDATIONSCHEMA+$$$SAXVALIDATIONPROHIBITDTDS)
	If $$$ISERR(sc) Goto InitializeSOAPExit
	$$$SOAPTimer("sip")
	
	#; Find WS-Security header
	$$$SOAPLogSecurity($c(13,10)_"---------------"_$c(13,10)_"Validate Security header: action="_pAction)
	Set sc=##class(%SOAP.Security.Header).ImportSecurityHeader(.importHandler,securityIn,.headerObj)
	If $isobject(headerObj) {
		Set securityFound=1
		If $$$ISERR(sc) {
			If headerObj.Fault'="" Set fault=headerObj.Fault
		} Else {
			Set %cspsoapSecurityHeader=headerObj
			Set securityNamespace=headerObj.Namespace
			Set token=headerObj.UsernameToken
			If token'="",token.Password.Type'["PasswordDigest" {
				Set username=token.Username
				Set password=token.Password.content
			}
		}
	}

	If $isobject($get(%request)) && %request.Secure {
		$$$SOAPLogSecurity("Security SSL message")
	}
	$$$SOAPTimer("sisec")
					
	If $$$ISOK(sc),'securityFound,securityIn="require" {
		Set fault=##class(%SOAP.WebService).MakeSecurityFault("FailedAuthentication",##class(%SOAP.Security.Header).GetSecurityNamespace())
	}
	
InitializeSOAPExit	
	If $$$ISERR(sc) && (fault="") {
		If FaultReason="" Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
		Set fault=..MakeStatusFault(FaultCode,FaultReason,sc)
	}
	Quit

InitializeSOAPError Set $zt=""
	Set FaultCode=$$$FAULTServer
	Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
	Set sc=$$$ERROR($$$ObjectScriptError,$ZE)
	// Kill the import handler to free %SAX memory in case of <STORE> error.
	Set importHandler=""
	Goto InitializeSOAPExit
}

/// Process a SOAP request.  Initialize must be called first.<br>
/// The pAction argument contains the value of SOAPAction header.<br>
/// The request argument contains the SOAP request.  For a normal SOAP request, the request
/// argument will be a stream containing the request.  For a SOAP with Attachments format request,
/// the request argument will be a multidimensional array of %CSP.Streams that is subscripted 
/// by the position in the original multipart message.  request(1) is the SOAP message.<br>
/// The needHeaders argument specifies if HTTP headers need to be output before the SOAP message.
/// Normally the transport class will be responsible for any transport such as HTTP headers.<br>
/// 
/// If the SoapFault property is set up before calling Process, then a SOAP fault is 
/// written instead of calling the web method.<br>
/// The SessionCookie property may be set before calling Process to force value of SessionCookie.
/// 
/// This method is meant to be used by SOAP transport classes.
Method Process(pAction As %String, ByRef request, needHeaders As %Boolean = 1) [ ServerOnly = 1 ]
{
	// Indicate that we are in web service
	Set %cspsoapservice=$this

	Set sc=$$$OK
	Set ..Action=pAction
	Set ..OneWay=""
	
	Set $zt="ProcessSOAPError"
	Set inProcessBody=0
	
	#; Log Http headers
	$$$SOAPLogInputHTTPHeaders

	$$$SOAPTimer("s1")
	Set requestAttachments=""
	Set ..IsMTOM=0
	If $get(request)="" {
		If $isobject($get(%request)) {
			Set contenttype=%request.CgiEnvs("CONTENT_TYPE")
			If ($zcvt($piece(contenttype,";",1),"L")'="multipart/related") ||
			   ##class(%Net.HttpRequest).ParseContent($piece(contenttype,";",2,$length(contenttype,";")),.tmparray) ||
			   $case($get(tmparray("type")),"text/xml":0,"application/xop+xml":0,"application/soap+xml":0,:1) ||
			   (tmparray("type")="application/xop+xml" && ($get(tmparray("start-info"))="")) {
					Set sc=$$$ERROR($$$SOAPBadMultipart,contenttype_"(type="_$get(tmparray("type"))_")")
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Goto ProcessSOAPExit
			}
			If tmparray("type")="application/xop+xml" {
				// If no SOAPAction, use the action parameter
				If (pAction="") && (..SoapVersion="1.2") {
					Set pAction=$get(tmparray("action"))
					Set ..Action=pAction
				}
				If ..SoapVersion="" {
					Set ..SoapVersion=$select(tmparray("start-info")'="text/xml":"1.1",1:"1.2")
				}
				Set requestAttachments=..Attachments
				Set ..IsMTOM=1
				Set start=##class(%Net.MIMEPart).NormalizeContentId($get(tmparray("start")))
				Set startindex=$select(start="":1,1:0)
			} ElseIf tmparray("type")="application/soap+xml" {
				// If no SOAPAction, use the action parameter
				If (pAction="") && (..SoapVersion="1.2") {
					Set pAction=$get(tmparray("action"))
					Set ..Action=pAction
				}
				Set requestAttachments=..Attachments
				Set start=##class(%Net.MIMEPart).NormalizeContentId($get(tmparray("start")))
				Set startindex=$select(start="":1,1:0)
			} Else {
				If ..SoapVersion="" {
					Set ..SoapVersion=$select(tmparray("type")'="text/xml":"1.1",1:"1.2")
				}
				Set start=""
				Set startindex=1
			}
		} Else {
			Set ..SoapVersion="1.1"
			Set start=""
			Set startindex=1
		}
		If ..SoapFault'="" Goto ProcessSOAPExit
		
		Set index=$order(request(""))
		While index'="" {
			Set part=##class(%Net.MIMEPart).%New(request(index))
			Do ..Attachments.Insert(part)
			Set headers=$tr(request(index).GetAttribute("Headers"),$c(13),"")
			If headers'="" {
				Set len=$length(headers,$c(10))
				For i=1:1:len {
					Set header=$piece(headers,$c(10),i)
					Set name=$zcvt($zstrip($piece(header,":",1),"<>W"),"U")
					Set value=$zstrip($piece(header,":",2,$length(header,":")),"<>W")
					If name="CONTENT-ID" {
						Set part.ContentId=##class(%Net.MIMEPart).NormalizeContentId(value)
					} ElseIf name="CONTENT-LOCATION" {
						Set part.ContentLocation=##class(%Net.MIMEPart).NormalizeContentLocation(value)
					}
				}
			}
			
			If (startindex=0) && (start=part.ContentId) {
				Set startindex=index
			}
			Set index=$order(request(index))
		}
		If startindex=0 {
			Set sc=$$$ERROR($$$SOAPBadMultipart,contenttype_" (start="_start_")")
			Set FaultCode=$$$FAULTClient
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
			Goto ProcessSOAPExit
		}
		Set requestStream=request(startindex)
		Set part=..Attachments.GetAt(startindex)
		Set ..ContentId=part.ContentId
		Set ..ContentLocation=part.ContentLocation
		Do ..Attachments.RemoveAt(startindex)
	} Else {
		If $isobject($get(%request)) {
			Set contenttype=$get(%request.CgiEnvs("CONTENT_TYPE"))
			// If no SOAPAction, use the action parameter
			If (pAction="") && (..SoapVersion="1.2") &&
			   ($zcvt($piece(%request.CgiEnvs("CONTENT_TYPE"),";",1),"L")="application/soap+xml") &&
			   '##class(%Net.HttpRequest).ParseContent($piece(contenttype,";",2,$length(contenttype,";")),.tmparray) {
					Set pAction=$get(tmparray("action"))
					Set ..Action=pAction
			}
			If (..SoapVersion="") {
				Set ..SoapVersion=$select($zcvt($piece(contenttype,";",1),"L")="application/soap+xml":"1.2",1:"1.1")
			}
		} Else {
			Set ..SoapVersion="1.1"
		}
		If ..SoapFault'="" Goto ProcessSOAPExit
		Set requestStream=request
	}
	
	#; Process session and security headers
	Set headers=..#SOAPHEADERS
	If headers="" {
		Set headers="CSPCHD:%SOAP.SessionHeader"
	} Else {
		Set headers=","_headers
		If headers'[",CSPCHD:" Set headers=headers_",CSPCHD:%SOAP.SessionHeader"
		Set headers=$extract(headers,2,*)
	}
	Set ..SoapHeaders=headers

	#; Check the SOAP envelope
	$$$SOAPTimer("s2")
	Do ..HeadersIn.Clear()

	If ..SecurityIn'="" {
		Do ..HeadersIn.SetAt(..SecurityIn,"Security")
		Set ..SecurityContextToken=..SecurityIn.SecurityContextToken
	} Else {
		Set ..SecurityContextToken=""
	}
	Set handler=..ImportHandler
	Set sc=..CheckSOAPEnvelope(.handler,1,.soapenv,.message,.messageChildlist,.versionMismatch)
	If message="" && $isobject($get(request)) && (request.%Extends("%Library.AbstractStream")||(request.%Extends("%CSP.Stream"))) {
		Set requestBody=request.GetAttribute("BodyStream")
		Set:$IsObject(requestBody)&&$system.Status.Equals(sc,$$$ERRORCODE($$$SOAPNoBody)) sc=$$$OK
	} Else { Set requestBody=$$$NULLOREF }
	If $$$ISOK(sc) {
		#; check that incoming message version matches specified SOAPVERSION
		Set requestVersion=..#REQUESTVERSION
		If requestVersion'="",requestVersion'=..SoapVersion {
			Set versionMismatch=-1
			Set sc=$$$ERROR($$$VersionError,$select(requestVersion="1.1":$$$SOAPENVns,1:$$$SOAP12ENVns))
		}
	}
	If $$$ISOK(sc) {
		#; Instantiate a message descriptor class for this web method.
		Set msgService=$this
		Set pAction=$translate(pAction,"""")
		If (pAction="") && $isobject(..AddressingIn) {
			Set pAction=..AddressingIn.Action
			Set ..Action=pAction
		}
		#; User callback
		Do ..OnRequestMessage("SOAP",..Action,requestStream)
		If ..SoapFault'="" Goto ProcessSOAPExit
		Set className=..GetMsgClass(pAction,messageChildlist,.methodName,requestBody)
		If className'="" {
			Try {
				Set msgClass=$zobjclassmethod(className_"."_methodName,"%New")
			} Catch {
				Set msgClass=""
			}
		} Else {
			Set msgClass=""
		}
		If $isobject(msgClass) {
			If msgClass.%ResponseName="" Set msgClass.%ResponseName=methodName_"Response"
			Set ..MsgClass=msgClass
			Set ..MethodName=methodName
			Set useProcessBody=$$$comMemberKeyGet($zobjclass(),$$$cCLASSmethod,"ProcessBody",$$$cMETHrunnable)
			Set useProcessBodyNode=$$$comMemberKeyGet($zobjclass(),$$$cCLASSmethod,"ProcessBodyNode",$$$cMETHrunnable)
		} ElseIf message="" {
			// No further checks for body type, if no body
		} ElseIf $$$xmlaGetLocalName(handler.DocumentId,messageChildlist)="RequestSecurityToken",
				 $isobject(..AddressingIn),
				 $case(..AddressingIn.Action,$$$SOAPWSSCTokenRequest:1,$$$SOAPWSSCTokenCancelRequest:1,:0) {
			// If RequestSecurityToken request, process it here.
			Set msgService=##class(%SOAP.WSSC.Service).%New()
			Set (msgService.Action,..Action)=..AddressingIn.Action
			Set msgClass=##class(%SOAP.WSSC.Service.RequestSecurityToken).%New()
			Set msgClass.%ResponseName="RequestSecurityTokenResponseCollection"
			Set ..MsgClass=msgClass
			Set ..MethodName="RequestSecurityToken"
			Set useProcessBody=0
			Set useProcessBodyNode=0
		} ElseIf $$$xmlaGetLocalName(handler.DocumentId,messageChildlist)="CreateSequence",
				 $isobject(..AddressingIn),
				 ..AddressingIn.Action=($$$SOAPWSRMns_"/CreateSequence") {
			// If CreateSequence request, process it here.
			Set msgService=##class(%SOAP.RM.Service).%New()
			Set (msgService.Action,..Action)=..AddressingIn.Action
			Set msgClass=##class(%SOAP.RM.Service.CreateSequence).%New()
			Set msgClass.%ResponseName="CreateSequenceResponse"
			Set ..MsgClass=msgClass
			Set ..MethodName="CreateSequence"
			Set useProcessBody=0
			Set useProcessBodyNode=0
		} ElseIf $$$xmlaGetLocalName(handler.DocumentId,messageChildlist)="CloseSequence",
				 $isobject(..AddressingIn),
				 ..AddressingIn.Action=($$$SOAPWSRMns_"/CloseSequence") {
			// If CloseSequence request, process it here.
			Set msgService=##class(%SOAP.RM.Service).%New()
			Set (msgService.Action,..Action)=..AddressingIn.Action
			Set msgClass=##class(%SOAP.RM.Service.CloseSequence).%New()
			Set msgClass.%ResponseName="CloseSequenceResponse"
			Set ..MsgClass=msgClass
			Set ..MethodName="CloseSequence"
			Set useProcessBody=0
			Set useProcessBodyNode=0
		} ElseIf $$$xmlaGetLocalName(handler.DocumentId,messageChildlist)="TerminateSequence",
				 $isobject(..AddressingIn),
				 ..AddressingIn.Action=($$$SOAPWSRMns_"/TerminateSequence") {
			// If TerminateSequence request, process it here.
			Set msgService=##class(%SOAP.RM.Service).%New()
			Set (msgService.Action,..Action)=..AddressingIn.Action
			Set msgClass=##class(%SOAP.RM.Service.TerminateSequence).%New()
			Set msgClass.%ResponseName="TerminateSequenceResponse"
			Set ..MsgClass=msgClass
			Set ..MethodName="TerminateSequence"
			Set useProcessBody=0
			Set useProcessBodyNode=0
		}
		If $$$ISOK(sc),'$isobject(msgClass) {
			set sc=$$$ERROR($$$SoapActionError,pAction)
		}
	}
	
	If $$$ISOK(sc) {
		Set sc=..ProcessSOAPEnvelope(.handler,soapenv,.message,.messageChildlist,requestAttachments)
	}
	
	Set ..ImportHandler=handler
	If $$$ISERR(sc) {
		If $$$GETERRORCODE(sc)=$$$ERRORCODE($$$HeaderNotSupported) {
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPMustUnderstandError))
			Set FaultCode=$$$FAULTMustUnderstand
		} ElseIf ($$$GETERRORCODE(sc)=$$$ERRORCODE($$$SOAPBadEncodingStyle)) && (..SoapVersion="1.2") {
			Do DecomposeStatus^%apiOBJ(sc,.err)
			Set FaultReason=err(1)
			Set FaultCode=$$$FAULTDataEncodingUnknown
		} Else {
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
			If versionMismatch {
				Set FaultCode=$$$FAULTVersionMismatch
				If versionMismatch=1 {
					// Force the response to be SOAP 1.1 for version mismatch.
					// Use incoming version for unexpected version
					Set ..SoapVersion="1.1"
				}
			} Else {
				Set FaultCode=$$$FAULTClient
			}
		}
		Goto ProcessSOAPExit
	}
	$$$SOAPTimer("senv")
	
	#; Process session and security headers
	Set header=..HeadersIn.GetAt("CSPCHD")
	If (header'="") && ($zobjclass(header)="%SOAP.SessionHeader") {
		Set sc=header.ProcessService($this)
		If $$$ISERR(sc) {
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
			Set FaultCode=$$$FAULTClient
			Goto ProcessSOAPExit
		}
	}

	#; If SOAPSESSION, then add the SOAP session header
	If (..SessionCookie'="") && $isobject(%session) &&
	   ($extract(..SessionCookie,11,20)'=$extract(%session.CSPSessionCookie,11,20)) {
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		Set FaultCode=$$$FAULTServer
		If %session.NewSession {
			Set sc=$$$ERROR($$$SOAPBadNewSession)
		} Else {
			Set sc=$$$ERROR($$$SOAPBadSessionHeader)
		}
		Goto ProcessSOAPExit
	}

	If ..#SOAPSESSION && (..SessionCookie'="") {
		Set sessionHeader=##class(%SOAP.SessionHeader).%New()
		Set sessionHeader.SessionCookie=..SessionCookie
		Do ..HeadersOut.SetAt(sessionHeader,"CSPCHD")
	}
	
	#; Find WS-ReliableMessaging headers
	If '$isobject(..AddressingIn) || (..AddressingIn.Action'[$$$SOAPWSRMns) {
		Set sequence=..HeadersIn.GetAt("Sequence")
		If $classname(sequence)'="%SOAP.RM.Sequence" Set sequence=""
		Set ack=..HeadersIn.GetAt("SequenceAcknowledgement")
		If $classname(ack)'="%SOAP.RM.SequenceAcknowledgement" Set ack=""
	
		If $isobject(sequence) {
			#; Validate Sequence header
			Set ok=1
			Set session=##class(%SYS.RMSession).Open(sequence.Identifier)
			If '$isobject(session) {
				Set ..SoapFault=##class(%SOAP.RM.SequenceFault).MakeFault($this,0,$$$FAULTClient,"UnknownSequence",sequence.Identifier)
				Set ok=0
			}
			If ok,session.Terminated {
				Set ..SoapFault=##class(%SOAP.RM.SequenceFault).MakeFault($this,0,$$$FAULTClient,"SequenceClosed",sequence.Identifier)
				Set ok=0
			}
			#; If RM session, then error check the sequence here.
			If ok {
				If $$$CheckSOAPLogSecurity {
					Set line="sequence.MessageNumber="_sequence.MessageNumber
					Set line=line_",session.MessageNumber="_session.MessageNumber
					Set line=line_",session.GetMessageState="_session.GetMessageState(sequence.MessageNumber)
					Set line=line_",session.CheckGap()="_session.CheckGap()
					Set line=line_",session.DeliveryAssurance="_session.DeliveryAssurance
					Set line=line_",session.DiscardFollowingFirstGap="_session.DiscardFollowingFirstGap
					Set line=line_",session.InOrder="_session.InOrder
					$$$SOAPLogSecurity("    Check RM session: "_line)
				}
				// Maximum message number is defined by how large a bit string can be handled.
				Try {
					Set $bit(dummy,sequence.MessageNumber)=0
				} Catch {
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Set ..SoapFault=##class(%SOAP.RM.SequenceFault).MakeFault($this,0,$$$FAULTClient,"MessageNumberRollover")
					Set ok=0
				} 
			}
			If ok {	
				If 'session.CheckSCT($this) {
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Set ..SoapFault=..MakeFault(FaultCode,FaultReason,"SecurityContextToken, "_session.SCTIdentifier_", expected for WS-ReliableMessaging wsrm:Identifier="_session.RequestIdentifier)
					Set ok=0
				} ElseIf session.GetMessageState(sequence.MessageNumber)=1,
				  $case(session.DeliveryAssurance,"ExactlyOnce":1,"AtMostOnce":1,:0) {
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Set ..SoapFault=..MakeFault(FaultCode,FaultReason,"WS-ReliableMessaging duplicate message constraint violated wsrm:Identifier="_session.RequestIdentifier)
					Set ok=0
				} ElseIf session.CheckGap() || ((session.MessageNumber+1)'=sequence.MessageNumber),
				  $case(session.DeliveryAssurance,"ExactlyOnce":1,"AtLeastOnce":1,:0) || session.DiscardFollowingFirstGap {
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Set ..SoapFault=..MakeFault(FaultCode,FaultReason,"WS-ReliableMessaging missing message constraint violated wsrm:Identifier="_session.RequestIdentifier)
					Set ok=0
				} ElseIf session.InOrder,session.MessageNumber>=sequence.MessageNumber {
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Set ..SoapFault=..MakeFault(FaultCode,FaultReason,"WS-ReliableMessaging InOrder constraint violated wsrm:Identifier="_session.RequestIdentifier)
					Set ok=0
				}
				#; Terminate session if client failure
				If 'ok {
					// Terminating RM session, so terminate underlying SOAP session
					Set %session.EndSession=1
					Set session.Terminated=1
					Do session.Save()
				}
			}
			#; Update RM session
			If ok {
				Set session.MessageNumber=sequence.MessageNumber
				Do session.SetMessageState(session.MessageNumber,1)
				Do session.Save()
				Set ..RMSession=session
				#; Add Sequence and SequenceAcknowledgement headers if RM session
				If session.ResponseIdentifier'="" {
					Do ..HeadersOut.SetAt(##class(%SOAP.RM.Sequence).CreateHeader(..RMSession,0),"Sequence")
				}
				Do ..HeadersOut.SetAt(##class(%SOAP.RM.SequenceAcknowledgement).CreateHeader(session,0),"SequenceAcknowledgement")
			} ElseIf $isobject(session) {
				If +session.MessageNumber>0 {
					Do session.SetMessageState(session.MessageNumber,0)
				}
				Do ..FaultHeaders.SetAt(##class(%SOAP.RM.SequenceAcknowledgement).CreateHeader(session,0),"SequenceAcknowledgement")
			}
			If 'ok Goto ProcessSOAPExit
		} ElseIf $isobject(ack) {
			#; SequenceAcknowledgement is not valid without Sequence
			Set ..SoapFault=##class(%SOAP.RM.SequenceFault).MakeFault($this,0,$$$FAULTClient,"InvalidAcknowledgement",ack.Identifier)
			Goto ProcessSOAPExit
		}
	}
	
	#; Validate the WS-Policy policy that applies to this service
	Set sc=##class(%SOAP.Policy).ProcessReceiveAlternative($this,..MethodName,.alternative)
	If $$$ISERR(sc) {
		Set FaultCode=$$$FAULTServer
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		// If not a good policy, then terminate underlying SOAP session
		Set %session.EndSession=1
		Goto ProcessSOAPExit
	}
	$$$SOAPTimer("shdr")

	If useProcessBody {
		If $IsObject(requestBody) { Set tHadBodyStream=1 }
		Else {
			Set tHadBodyStream=0
			Set requestBody=##class(%GlobalCharacterStream).%New()
			If message="" {
				Set sc=requestBody.Write("")
				If $$$ISERR(sc) {
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Goto ProcessSOAPExit
				}
			} Else {
				Set body=$select(message="":"",1:..ImportHandler.GetNode(message))
				Set writer=##class(%XML.Writer).%New()
				Set writer.NoXMLDeclaration=1
				Set sc=writer.OutputToStream(.requestBody)
				If $$$ISOK(sc) Set sc=writer.Canonicalize(body,,1)
				If $$$ISERR(sc) {
					Set FaultCode=$$$FAULTClient
					Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
					Goto ProcessSOAPExit
				}
			}
		}
		Set responseBody=##class(%GlobalCharacterStream).%New()
		Set inProcessBody=1
		Set BodyProcessed=..ProcessBody(pAction,requestBody,.responseBody)
		Set:'tHadBodyStream requestBody=$$$NULLOREF
		Set inProcessBody=0
	} ElseIf useProcessBodyNode {
		Set responseBody=##class(%GlobalCharacterStream).%New()
		Set body=$select(message="":"",1:..ImportHandler.GetNode(message))
		Set inProcessBody=1
		Set BodyProcessed=..ProcessBodyNode(pAction,body,.responseBody)
		Set inProcessBody=0
	} Else {
		Set BodyProcessed=0
	}

	If 'BodyProcessed {
		Kill responseBody
		If '$IsObject(requestBody) {
			Set sc=..MsgClass.ImportSOAPMessage(..MethodName,"*",..ImportHandler,message,messageChildlist,requestAttachments,..#SOAPCHECKREQUIRED)
		} Else {
			#; Get an XML content handler that parses message into XML DOM 
			Set bodyHandler=##class(%XML.Reader).GetNewDocument(..#USEPPGHANDLER)
			If bodyHandler="" {
				Set sc=$$$ERROR($$$CannotCreateObject,"body %XML.Document")
			} Else {
			 	Set bodyHandler.KeepWhitespace=1 // Need whitespace for XMLImport
				#; and an entity resolver
				Set tResolver=##Class(%XML.SAX.EntityResolver).%New()
				If tResolver="" {
					Set sc=$$$ERROR($$$CannotCreateObject,"%XML.SAX.EntityResolver")
				} Else {
					#; Parse the message into XML DOM
					Set sc=##Class(%XML.SAX.Parser).ParseStream(requestBody,bodyHandler,tResolver,$$$SAXFULLDEFAULT-$$$SAXVALIDATIONSCHEMA+$$$SAXVALIDATIONPROHIBITDTDS)
					If $$$ISOK(sc) {
						Set tree=bodyHandler.DocumentId
						Set root=$$$xmlGetDocumentElement(tree)
						$$$xmlaGetChildList(tree,root,rootChildlist,descriptor)
						$$$xmlaFirstChildElement(tree,root,rootChildlist,bodmessage,d3)
						$$$xmlaGetChildListFromDescriptor(tree,d3,bodmessageChildlist)
						Set sc=..MsgClass.ImportSOAPMessage(..MethodName,"*",bodyHandler,bodmessage,bodmessageChildlist,requestAttachments,..#SOAPCHECKREQUIRED)
					}
				}
			}
		}
		If $$$ISERR(sc) {
			If ..SoapVersion="1.2" {
				Do DecomposeStatus^%apiOBJ(sc,.err)
				Set detail=$c(13,10)_"    <error xmlns='"_..#NAMESPACE_"'>"_$c(13,10)
				Set detail=detail_"     <text>"_$zcvt(err(1),"O","XML")_"</text>"_$c(13,10)
				Set detail=detail_"    </error>"_$c(13,10)
				Set fault=..MakeFault12($$$FAULTSender,"Bad arguments in RPC request",detail)
				Set fault.Code.Subcode=..MakeFault12Code("rpc:BadArguments")
				Set fault.faultPrefixDefinition="xmlns:rpc="""_$$$SOAP12RPC_""""
				Set ..SoapFault=fault
			} Else {
				Set FaultCode=$$$FAULTClient
				Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
			}
			Goto ProcessSOAPExit
		}
		
		#; Invoke the web method with arguments in MsgClass
		If '..InvokeMsgClass(..MsgClass,msgService) Goto ProcessSOAPExit
	}
	$$$SOAPTimer("sbody")
	
	#; Restore the TCP device for response
	Do ..%RestoreTCPDevice()

	#; If forced to OneWay, then always empty body
	If ..OneWay Set responseBody=""
	#; If OneWay not set by WebMethod, ProcessBody or ProcessBodyNode, then set from parameter.	
	If ..OneWay="" {
		Set ..OneWay=..MsgClass.%GetParameter("SOAPONEWAY")
	}
	#; Find WS-Policy alternative for response
	Set sc=##class(%SOAP.Policy).ProcessSendAlternative($this,..MethodName,.alternative)
	If $$$ISERR(sc) {
		Set FaultCode=$$$FAULTServer
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		Goto ProcessSOAPExit
	}

	#; Setup WS-Addressing if required.
	If '$data(alternative),..AddressingOut="",..AddressingIn'="",$zcvt(..#WSADDRESSING,"U")="AUTO" {
		Set action=##class(%SOAP.WebParameters).GetAction($classname(),..MethodName,"response")
		Set ..AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultResponseProperties(..AddressingIn,action)
	}

	#; Initialize any WS-Security operations.
	Set wsRequired=..InitializeSecurity(.sc)
	If $$$ISERR(sc) {
		Set FaultCode=$$$FAULTServer
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		Goto ProcessSOAPExit
	}
	
	$$$SOAPTimer("spolicy")

	// If one-way message to a service with no headers, then just return empty message
	If '$isobject(r%SecurityOut)||(r%SecurityOut.SecurityElement.Count()=0),
	   ..AddressingOut="",..HeadersOut.Count()=0,..ResponseAttachments.Count()=0,..OneWay {
		If $get(%request)'="" && %request.CSPGatewayRequest {
			Do %response.Abort()
			Set %response.Status="202 Accepted"
			Set %response.ContentType=""
			Set %response.ContentLength=0
			Do %response.WriteHTTPHeader(.dummy)
		}
		$$$SOAPLogOutputHTTPHeaders
		Set sc=$$$OK
		Goto ProcessSOAPExit
	}
	
	#; Output directly to TCP device only if service and no logging and no WS-Security
	If '$$$CheckSOAPLogOutput,'wsRequired {
		$$$XMLUseWrite
	} Else {
		$$$XMLUseGlobal
	}
	
	#; Write the SOAP message
	Set sc=..WriteHTTPContent(..MsgClass,..MsgClass.%ResponseName,1,wsRequired,.responseBody,$select(needHeaders:%response,1:""))
	If $$$ISERR(sc) {
		Set FaultCode=$$$FAULTServer
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
	}
	If '$$$XMLIsWrite {
		$$$SETIO("RAW")
		If '$$$ISERR(sc) {
			$$$XMLOutputBuffer
		}
		$$$XMLUseRestore
	}
	$$$SOAPLogOutputHTTPHeaders
	
	$$$SOAPTimer("sres")

ProcessSOAPExit	
	Do ..%RestoreTCPDevice()
	If $$$ISERR(sc) && (..SoapFault="") {
		Set ..SoapFault=..MakeStatusFault(FaultCode,FaultReason,sc)
	}
	If ..SoapFault'="" Do ..Fault(..SoapFault)
	If $get(wsRequired) || $isobject(r%SecurityOut) Do ..ResetSecurity()
	Quit

ProcessSOAPError Set $zt=""
	If inProcessBody {
		If $ze'["<ZSOAP>" {
			Set FaultCode=$$$FAULTServer
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
			Set sc=$$$ERROR($$$ObjectScriptError,$ZE)
		}
	} Else {
		Set FaultCode=$$$FAULTServer
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
		Set sc=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	Goto ProcessSOAPExit
}

/// Process a SOAP request using the InterSystems IRIS proprietary binary SOAP protocol.
/// The pAction argument contains the value of ISCSOAP header.<br>
/// The request argument contains the SOAP request as a stream containing serialized message class.
/// 
/// If the SoapFault property is set up call of Process, then a SOAP fault is
///   written instead of calling the web method.
/// The SessionCookie property may be set before calling Process to force value of SessionCookie.
/// 
/// This method is meant to be used by SOAP transport classes.
Method ProcessBinary(action As %String, request) [ ServerOnly = 1 ]
{
	$$$SOAPTimer("s1")
	// Indicate that we are in web service
	Set %cspsoapservice=$this

	Set sc=$$$OK
	Set FaultCode=$$$FAULTServer
	
	Set ..Username=$username
	Set action=$translate(action,"""")
	Set ..Action=action
	
	#; Log Http headers
	$$$SOAPLogInputHTTPHeaders

	If ..SoapFault'="" Goto ProcessBinaryExit
	
	Set $zt="ProcessBinaryError"

	#; Log the request
	Do:'$$$CheckSOAPLogStop ##class(%SOAP.Binary).LogMessage(1,action,request)

	#; User callback
	Do ..OnRequestMessage("binary",action,request)
	If ..SoapFault'="" Goto ProcessBinaryExit
	$$$SOAPTimer("s2")
	
	#; Check the message descriptor class for this web method.
	Set className=..GetMsgClass(action,,.methodName)
	If className="" Goto ProcessBinaryExit
	Set msgClass=$zobjclassmethod(className_"."_methodName,"%New")

	If '$isobject(msgClass) {
		set sc=$$$ERROR($$$SoapActionError,action)
		Set FaultCode=$$$FAULTClient
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
		Goto ProcessBinaryExit
	}
	Set ..MsgClass=msgClass
	Set ..MethodName=methodName
	
	#; Deserialize the message class
	Set ..SoapHeaders=..#SOAPHEADERS
	Set sc=..ReadBinaryMessage(msgClass,.asUTF8,,request)
	If $$$ISERR(sc) {
		If $$$GETERRORCODE(sc)=$$$ERRORCODE($$$HeaderNotSupported) {
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPMustUnderstandError))
			Set FaultCode=$$$FAULTMustUnderstand
		} Else {
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPClientError))
			Set FaultCode=$$$FAULTClient
		}
		Goto ProcessBinaryExit
	}
	$$$SOAPTimer("senv")
	
	#; Invoke the web method with arguments in MsgClass
	If '..InvokeMsgClass(msgClass,$this) Goto ProcessBinaryExit
	$$$SOAPTimer("sbody")
	
	#; Return the result message
	Do ..%RestoreTCPDevice()
	Do %response.WriteHTTPHeader(.OutputBody)
	Set binwriter=..GetBinaryWriter(msgClass,0,asUTF8,..#SOAPSESSION)
	If (('$$$CheckSOAPLogStop)&&($$$CheckSOAPLogOutput)) Do binwriter.LogOutputStart(1,action)
	Do binwriter.OutputStream()
	$$$SOAPLogOutputHTTPHeaders
	$$$SOAPTimer("sres")

ProcessBinaryExit
	Do ..%RestoreTCPDevice()
	If $$$ISERR(sc) && (..SoapFault="") {
		If '$data(FaultReason) {
			Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		}
		Set ..SoapFault=..MakeStatusFault(FaultCode,FaultReason,sc)
	}
	If ..SoapFault'="" Do ..Fault(..SoapFault)
	Quit

ProcessBinaryError Set $zt=""
	Set FaultCode=$$$FAULTServer
	Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$InternalError))
	Set sc=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto ProcessBinaryExit
}

/// Get class name for a message descriptor class for this web method based on the SOAPAction
Method GetMsgClass(action As %String, messageChildlist As %Integer, Output methodName As %String, bodyStream As %GlobalCharacterStream = "") As %String [ Internal, ServerOnly = 1 ]
{
	Set (methodName,className,msgClass,methodList)=""
	Set class=$classname()
	
	Set methodList=$get($$$SOAPParametersSoapActionList(class,action))
	If $listlength(methodList)=1 {
		// In case of exact match of action to SoapAction keyword,
		// then just use the method name for the match
		Set methodName=$listget(methodList,1)
		
	} ElseIf $listlength(methodList)>1 {
		// In case of multiple matches of action to SoapAction keyword,
		// then match based on request element name
		Set elementName=..%GetElementFromBody(messageChildlist,bodyStream)
		Set elementList=$get($$$SOAPParametersRequestNameList(class,elementName))
		For i=1:1:$listlength(elementList) {
			Set method=$listget(elementList,i)
			For j=1:1:$listlength(methodList) {
				If method=$listget(methodList,j) {
					Set methodName=method
					Quit
				}
			}
			If methodName'="" Quit
		}
	}
	
	If methodName="" {
		// If no SoapAction match,
		// first look for Cache format SoapAction
		Set action=$Piece(action,"/",$Length(action,"/"))
		If action'="" {
			Set className=$piece(action,".",1,$length(action,".")-1)
			Set methodName=$piece(action,".",$length(action,"."))
		}
		// next look for method match based on request element name
		If methodName="" {
			Set className=""
			Set elementName=..%GetElementFromBody(messageChildlist,bodyStream)
			Set elementList=$get($$$SOAPParametersRequestNameList(class,elementName))
			If $listlength(elementList)>0 {
				Set methodName=$listget(elementList,1)
			} Else {
				Set methodName=..NormalizeName(elementName,$$$MAXNAMELENGTH,1)
			}
		}
	}

	If className'="" {
		If className'=class Set className=""
	} Else {
		Set className=class
	}
	Quit className
}

/// Extract the top level request element name from the SOAP body
Method %GetElementFromBody(messageChildlist As %Integer, bodyStream As %GlobalCharacterStream = "") As %String [ Internal, ServerOnly = 1 ]
{
	Set element=""
	If $get(messageChildlist)'="" {
		Set element=$$$xmlaGetLocalName(..ImportHandler.DocumentId,messageChildlist)
	}
	If element="",$isobject(bodyStream) {
		Set element=$piece($piece($piece(bodyStream.Read(),"<",3),">",1)," ",1)
		If element[":" Set element=$piece(element,":",2)
		Do bodyStream.Rewind()
	}
	Quit element
}

/// Save the TCP device at time of web service invocation
Method %SaveTCPDevice() [ Internal, ServerOnly = 1 ]
{
	#; Redirect output to the null device during user code
	Set ..saveIO=$io
	If $$$isWINDOWS {
		Set NullDev="//./nul"
	} ElseIf $$$isUNIX {
		Set NullDev="/dev/null/"
	} ElseIf $$$isVMS {
		Set NullDev="NL:"
	} Else {
		Set NullDev=""
	}
	If NullDev'="" Open NullDev Use NullDev
}

/// Restore the TCP device from time of invocation
Method %RestoreTCPDevice() [ Internal, ServerOnly = 1 ]
{
	#; Restore TCP output device
	If ..saveIO'="" {
		Use ..saveIO
		Set ..saveIO=""
	}
}

/// Invoke web method based on the message class
Method InvokeMsgClass(msgClass As %SOAP.MsgDescriptor, service As %SOAP.WebService) As %Boolean [ Internal, ServerOnly = 1 ]
{
	#; Invoke the web method
	Set sc=$$$OK
	Try {
		Do msgClass.InvokeService(service)
	} Catch ex {
		Set sc=..HandleException(ex,.faultAlreadyReturned)
		// If fault not yet output by Fault method, then call OnPostWebMethod here.
		// If Fault was called, Fault called OnPostyWebMethod.
		If 'faultAlreadyReturned,$$$comMemberKeyGet($classname(),$$$cCLASSmethod,"OnPostWebMethod",$$$cMETHrunnable) {
			Try {
				Do ..OnPostWebMethod()
			} Catch exPost {
			}
		}
	}
	
	#; Return of "" means SOAP fault was already created and returned.
	If sc="" Quit 0

	#; Set SOAP fault properties and return error
	If $$$ISERR(sc) {
		Set FaultCode=$$$FAULTServer
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		Set ..SoapFault=..MakeStatusFault(FaultCode,FaultReason,sc)
		Quit 0

	} Else {
		Quit 1
	}
}

/// Internal handling of exception
Method HandleException(ex As %Exception.AbstractException, Output faultAlreadyReturned) As %Status [ Internal, ServerOnly = 1 ]
{
	Set faultAlreadyReturned=0
	If $classname(ex)="%Exception.SystemException" {
		Set sc=$select((ex.Name="<ZSOAP>")&&($Get(%objlasterror)]""):"",1:ex.AsStatus())
		If sc="" Set faultAlreadyReturned=1
	} Else {
		Set FaultCode=$$$FAULTServer
		Set FaultReason=$$$FormatMessage("","%ObjectErrors",$$$ERRORCODE($$$SOAPServerError))
		Set ..SoapFault=..MakeFault(FaultCode,FaultReason,"<Exception>"_$zcvt(ex.DisplayString(),"O","XML")_"</Exception>")
		#; Indicate return with fault already set
		Set sc=""
	}
	Quit sc
}

/// Add WS-Security 1.1 SignatureConfirmation elements to response message.
/// This method will add a SignatureConfirmation element to the SecurityOut for each Signature in the SecurityIn.
/// If no Signature element exists in SecurityIn, then a SignatureConfirmation element will be added with
/// no Value attribute as required by WS-Security 1.1.<br>
/// coveringSignature should be the main signature of the Security header which will be used to sign the
/// SignatureConfirmation elements.<br>
Method WSAddSignatureConfirmation(coveringSignature As %XML.Security.Signature = "", encryptedKey As %XML.Security.EncryptedKey = "", symmetricReference As %Integer = "", derivedKey As %SOAP.WSSC.DerivedKeyToken = "") [ ServerOnly = 1 ]
{
	If ..SecurityIn'="" {
		Set pos=0
		Set signature=..SecurityIn.FindElement("Signature",.pos)
	} Else {
		Set signature=""
	}
	
	If signature="" {
		$$$SOAPLogSecurity("Add SignatureConfirmation for no signatures")
		Set confirm=##class(%SOAP.Security.SignatureConfirmation).Create()
		Do ..SecurityOut.AddSecurityElement(confirm)
		If $isobject(coveringSignature) {
			Set id=confirm.GetId()
			Do coveringSignature.AddReference(##class(%XML.Security.Reference).Create(id))
			If $isobject(encryptedKey) {
				If symmetricReference'="" {
					Set encryptedData=##class(%XML.Security.EncryptedData).Create(derivedKey,confirm,symmetricReference)
				} Else {
					Set encryptedData=##class(%XML.Security.EncryptedData).Create(,confirm,)
				}
				Set ref=##class(%XML.Security.DataReference).Create(encryptedData)
				Do encryptedKey.AddReference(ref)
			}
		}
	} Else {
		Set count=0
		While signature'="" {
			Set count=count+1
			Set confirm=##class(%SOAP.Security.SignatureConfirmation).Create(signature.SignatureValue)
			Do ..SecurityOut.AddSecurityElement(confirm)
			If $isobject(coveringSignature) {
				Set id=confirm.GetId()
				Do coveringSignature.AddReference(##class(%XML.Security.Reference).Create(id))
				If $isobject(encryptedKey) {
					If symmetricReference'="" {
						Set encryptedData=##class(%XML.Security.EncryptedData).Create(derivedKey,confirm,symmetricReference)
					} Else {
						Set encryptedData=##class(%XML.Security.EncryptedData).Create(,confirm,)
					}
					Set ref=##class(%XML.Security.DataReference).Create(encryptedData)
					Do encryptedKey.AddReference(ref)
				}
			}
			Set signature=..SecurityIn.FindElement("Signature",.pos)
		}
		$$$SOAPLogSecurity("Add SignatureConfirmation for "_count_" signatures")
	}
}

/// Calling ReturnOneWay() will dynamically change the return of 
/// the web service to act as if the return type of the WebMethod was %SOAP.OneWay.  
/// ReturnOneWay may be called from a WebMethod or ProcessBody or ProcessBodyNode.  
/// The WebMethod, ProcessBody or ProcessBodyNode will still need to quit normally.
Method ReturnOneWay() [ ServerOnly = 1 ]
{
	Set ..OneWay=1
}

/// The OnPreWebMethod method will be called before any web method in a web service.
/// OnPreWebMethod cannot return a value and thus cannot change the execution of the
/// web service except by returning a SOAP fault in the same way that a web method 
/// would return a SOAP fault. OnPreWebMethod can look at %request, %session and
/// the web service properties to control its behavior. 
/// MsgClass is a web service property which is the message descriptor class which 
/// contains the web method arguments. 
Method OnPreWebMethod() [ Abstract, ServerOnly = 1 ]
{
}

/// The OnPostWebMethod method will be called after any web method in a web service.
/// OnPostWebMethod cannot return a value and thus cannot change the execution or
/// return of the web method. OnPostWebMethod is primarily to do any cleanup required 
/// of structures created by OnPreWebMethod.
Method OnPostWebMethod() [ Abstract, ServerOnly = 1 ]
{
}

/// The ProcessBody method of %SOAP.WebService will be passed the request message body 
/// as a character stream and will return the response message body in another
/// character stream.<br>
/// 
/// The return value is 1 (true) if the body was processed and a response 
/// stream produced. If 0 is returned the %SOAP.MsgDescriptor class will be 
/// invoked as usual. If an error occurs during the processing of the request,
/// then a fault should be returned in the usual way using the ReturnFault method.<br>
/// 
/// The arguments to this method are:<br> 
///  action is the SOAPAction for the SOAP request.<br>
///  requestBody is the body of the SOAP request.<br>
///  responseBody is a character stream to which the body of the SOAP response will be written.<br>  
/// <br>
Method ProcessBody(action As %String, requestBody As %CharacterStream, ByRef responseBody As %CharacterStream) As %Boolean [ Abstract, CodeMode = expression, ServerOnly = 1 ]
{
0
}

/// The ProcessBodyNode method of %SOAP.WebService will be passed an %XML.Node
/// instance which is positioned at the child of the Body element of the SOAP 
/// which has the contents of the request body.
/// ProcessBodyNode will return the response message body in another character stream.<br>
/// 
/// The return value is 1 (true) if the body was processed and a response 
/// stream produced. If 0 is returned the %SOAP.MsgDescriptor class will be 
/// invoked as usual. If an error occurs during the processing of the request,
/// then a fault should be returned in the usual way using the ReturnFault method.<br>
/// 
/// The arguments to this method are:<br> 
///  action is the SOAPAction for the SOAP request.<br>
///  body is an %XML.Node instance for the contents of the SOAP request body.<br>
///  responseBody is a character stream to which the body of the SOAP response will be written.<br>  
/// <br>
Method ProcessBodyNode(action As %String, body As %XML.Node, ByRef responseBody As %CharacterStream) As %Boolean [ Abstract, CodeMode = expression, ServerOnly = 1 ]
{
0
}

/// Reset this %SOAP.WebService instance to state as newly created
/// 
/// This method is meant to be used by SOAP transport classes.
Method Reset() [ ServerOnly = 1 ]
{
	Set ..SoapFault=""
	Set ..ImportHandler=""
	Set ..MsgClass=""
	Set ..Username=""
	Set ..Password=""
	Set ..SecurityNamespace=""
	Set ..SecurityIn=""
	Set ..saveIO=""
}

/// Log the HTTP headers associated with an input SOAP message.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method LogInputHTTPHeaders() [ Internal, ServerOnly = 1 ]
{
	/// If the LogFile is too big or there are LogConfig present ( "LogJob", "LogClass", "LogURL")
	If $$$CheckSOAPLogStop Quit
	// Nothing to do if no %request object
	If '$isobject($get(%request)) Quit

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
		Set name="HTTP_"
		For {
			Set name=$order(%request.CgiEnvs(name),1,value)
			If name="HTTP_AUTHORIZATION" {
				Write "AUTHORIZATION: "_$piece(value," ",1)_" "_$$$PasswordMask,!
			} Else {
				If $extract(name,1,5)'="HTTP_" Quit
				Write $extract(name,6,*)_": "_value,!
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

/// Log the HTTP headers associated with an output SOAP message.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod LogOutputHTTPHeaders() [ Internal, ServerOnly = 1 ]
{
	If $$$CheckSOAPLogStop Quit
	// Nothing to do if no %response object
	If '$isobject($get(%response)) Quit

	If ('$$$CheckSOAPLogOutput) || ('$$$CheckSOAPLogHTTPHeaders) Quit
	Set file=$get(^ISCSOAP("LogFile"))
	If file="" Quit
	
	
	Try {
		Set open=0,io="",error=""
		Set io=$io
		Open file:"waes":1 else  Set error="Unable to open SOAP log file" Quit
		Set open=1
		Use file
		$$$SETIO("RAW")

		Write !,!,"**** Output HTTP headers for Web Service",!
		Do %response.WriteCookies()
		Do %response.WriteHeaders($$$CheckSOAPTestMode)
		
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
