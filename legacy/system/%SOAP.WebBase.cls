/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%soap, %occSAX, %sySystem)

IncludeGenerator %soap

/// Super class for SOAP Web Client and Web Server Base class and super class for Web Service classes.
/// <br>
/// 
/// The only supported use of this class is as the super class for 
/// %SOAP.WebService and %SOAP.WebClient in order to define common properties and parameters.
/// Parameters and properties may be used by the application.<br><br>
/// 
/// In addition to parameters, an XData block may be used to supply additional information about
/// the web service or web client.
/// The XData member may contain descriptions of the expected request and response headers.  However, only one configuration
/// The format of the parameters element is as follows:<br>
/// <pre>
/// &lt;parameters xmlns="http://www.intersystems.com/configuration"&gt;
///    &lt;request&gt;
///       &lt;header ... &lt;/header&gt; * 
///    &lt;/request&gt; ?
///    &lt;response&gt;
///       &lt;header ... &lt;/header&gt; * 
///    &lt;/response&gt; ?
///    &lt;method name="xs:NCNAME"&gt;
///       &lt;request&gt;
///          &lt;header ... &lt;/header&gt; * 
///       &lt;/request&gt; ?
///       &lt;response&gt;
///          &lt;header ... &lt;/header&gt; * 
///       &lt;/response&gt; ?
///    &lt;/method&gt; *
/// &lt;/parameters&gt;
/// 
/// Cardinality is indicated by ? (0 or 1), * (0 or more) and + (1 or more) after the ending element.
/// 
/// The following describes the elements and attributes:
/// /parameters
///     Identifies parameters root
/// /parameters/request
///     The parameters for the request message corresponding to all methods for this web service or client.
///     These parameters are merged with the parameters for the individual method.
/// /parameters/request/header
///     The specification of a SOAP header which may be associated with this request message.
///     The format of the header element is described below.
/// /parameters/response
///     The parameters for the response message corresponding to all methods for this web service or client.
///     These parameters are merged with the parameters for the individual method.
/// /parameters/response/header
///     The specification of a SOAP header which may be associated with this response message.
///     The format of the header element is described below.
/// 
/// /parameters/method
///     The parameters for this method for this web service or client.
/// /parameters/method/@name
///     The name of the method
/// /parameters/method/request
///     The parameters for the request message corresponding to this method for this web service or client.
/// /parameters/method/request/header
///     The specification of a SOAP header which may be associated with this request message.
///     The format of the header element is described below.
/// /parameters/method/response
///     The parameters for the response message corresponding to this method for this web service or client.
/// /parameters/method/response/header
///     The specification of a SOAP header which may be associated with this response message.
///     The format of the header element is described below.
/// 
/// The definition of the header element is as follows:
/// &lt;header name="s:string" 
///            namespace="s:string"
///            class="s:string"
///            alias="s:string"? 
/// /&gt;
/// 
/// .../header/@name
///     The required element name of the header.
/// .../header/@namespace
///     The required namespace of the header.
/// .../header/@class
///     The required name of the class that corresponds to the header.
/// .../header/@alias
///     The optional alias to be used for this header in the HeadersIn array.
///     The default is the element name specified in the name attribute.
/// </pre>
Class %SOAP.WebBase Extends %RegisteredObject [ Abstract, System = 3 ]
{

/// LOCATION - Should be the URL for invoking the web service for which this is a proxy.
/// Override this parameter in the subclass.  
/// Also, can be overridden by setting the Location property of the client at runtime.
/// Parameter LOCATION = "http://localhost/csp/MyNameSpace/client.cls";
/// This parameter is normally only used with Web service clients (subclasses of %SOAP.WebClient) &mdash; 
/// not Web services themselves (subclasses of %SOAP.WebService).
Parameter LOCATION;

/// The ARGUMENTSTYLE parameter may be used to specify a message format in which 
/// each request message part (not the elements of the part's type) is an argument
/// and each response message part is a return value or output argument. 
/// The use of the message or wrapped format is specified by the ARGUMENTSTYLE parameter
/// of the web service or web client class. 
/// The default value for ARGUMENTSTYLE is "wrapped" or "". 
/// Message style arguments are indicated by a value of "message". 
/// The ARGUMENTSTYLE parameter will be ignored if the SoapBindingStyle is not document. 
Parameter ARGUMENTSTYLE As STRING [ Constraint = ",message,wrapped", Flags = ENUM ];

/// NAMESPACE - Should be an unique URI
/// Override this parameter in the subclass with the unique namespace URI
/// of your organization.
/// Override this parameter in the subclass.
Parameter NAMESPACE = "http://tempuri.org";

/// The RESPONSENAMESPACE parameter for SOAP client and SOAP service classes allows
/// the SOAP request and SOAP response messages when SoapBindingStyle="rpc"
/// to each be in a different namespace. The RESPONSENAMESPACE parameter specifies
/// the namespace for the SOAP response message descriptor class.
/// If RESPONSENAMESPACE is not specified the default is the NAMESPACE parameter.
/// 
/// The RESPONSENAMESPACE parameter applies to all methods in the class and is not
/// overridden by the SoapNameSpace method keyword.
Parameter RESPONSENAMESPACE;

/// ELEMENTQUALIFIED controls the format of the SOAP body.  
/// The ELEMENTQUALIFIED specification reflects the elementFormDefault attribute of the
/// schema element for the TYPENAMESPACE in the WSDL defining the SOAP service. 
/// To maintain compatibility, ELEMENTQUALIFIED will default to 1 (true) for SoapBodyUse="literal"
/// and will default to 0 (false) for SoapBodyUse="encoded".  
/// These were the values always previously assumed for the elementFormDefault attribute.
Parameter ELEMENTQUALIFIED As BOOLEAN;

/// ATTRIBUTEQUALIFIED controls the format of the SOAP body.  
/// The ATTRIBUTEQUALIFIED specification reflects the attributeFormDefault attribute of the
/// schema element for the TYPENAMESPACE in the WSDL defining the SOAP service. 
/// ATTRIBUTEQUALIFIED defaults ot 0 if not specified.
Parameter ATTRIBUTEQUALIFIED As BOOLEAN;

/// TYPENAMESPACE specifies the XML namespace for the types used for
/// the method arguments and return types in this web client or 
/// web service.  If TYPENAMESPACE is not specified or is "", 
/// then the default namespace used for the types is from 
/// the NAMESPACE parameter.  
/// Override this parameter in the subclass.
Parameter TYPENAMESPACE;

/// The RESPONSETYPENAMESPACE parameter for SOAP client and SOAP service classes allows
/// the SOAP request and SOAP response message parts when SoapBindingStyle="document"
/// to each be in a different namespace. The RESPONSETYPENAMESPACE parameter specifies
/// the namespace for the SOAP response message descriptor class.
/// If RESPONSETYPENAMESPACE is not specified the default is the TYPENAMESPACE parameter.
/// 
/// The RESPONSETYPENAMESPACE parameter applies to all methods in the class and is not
/// overridden by the SoapTypeNameSpace method keyword.
Parameter RESPONSETYPENAMESPACE;

/// Specifies if part elements of messages in the WSDL use type or element attribute.
/// XMLELEMENT defaults to 1 for "literal" WSDL and to 0 for "encoded" WSDL.
Parameter XMLELEMENT As BOOLEAN;

/// XMLIGNORENULL allows the programmer to override the default XML handling
/// of empty strings for web method arguments of type %String.  By default (XMLIGNORENULL = 0),
/// empty strings in the XML input are stored as $c(0) and $c(0) is written to XML
/// as an empty tag. A missing tag in the XML input is always stored as "" and
/// "" is always output to XML as no tag.<br>
/// 
/// If XMLIGNORENULL is set = 1, then both missing tags in the XML and empty
/// strings are input as "", and both "" and $c(0) are output as empty tags 
/// (i.e. &lt;tag /&gt;).<br>
/// 
/// If XMLIGNORENULL is set = "inputonly", then both missing tags in the XML and empty
/// strings are input as "".  Output of "" and $c(0) are for XMLIGNORENULL = 0:
/// $c(0) is output as an empty tag (i.e. &lt;tag /&gt;) and "" is output as no tag.<br>
/// 
/// XMLIGNORENULL specified in the web client or service class specifies
/// XMLIGNORENULL for the SOAP messages used for each web method.
Parameter XMLIGNORENULL As STRING [ Constraint = ",0,1,inputonly", Flags = ENUM ];

/// The SOAPVERSION parameter specified the version of SOAP which is supported. 
/// Possible values for the version are 1.1 and 1.2. The value "" specifies
/// that both SOAP 1.1 and SOAP 1.2 are supported.
Parameter SOAPVERSION As STRING [ Constraint = ",1.1,1.2", Flags = ENUM ];

/// If USEPPGHANDLER is true (1), then force SOAP request or response parsing to use PPG memory.<br>
/// If USEPPGHANDLER is false (0), then force SOAP request or response parsing to use local array memory.<br>
/// If USEPPGHANDLER is not set ( or = ""), then use default memory -- usually local array memory.<br>
/// The %SOAP.WebClient UsePPGHandler property may be used to override this parameter for each invocation.
Parameter USEPPGHANDLER As BOOLEAN;

/// The XMLIGNOREINVALIDTAG parameter allows the programmer to control handling of unexpected
/// elements in the XML input.  
/// By default (XMLIGNOREINVALIDTAG = 0), will treat an unexpected element as an error.
/// If XMLIGNOREINVALIDTAG is set = 1, then unexpected elements will be ignored. 
Parameter XMLIGNOREINVALIDTAG As BOOLEAN [ Internal ] = 0;

/// The SoapVersion property is either "1.1" or "1.2" and indicates the SOAP 
/// version for the current invocation.<br><br>
Property SoapVersion As %String;

/// Action for this web service call
Property Action As %String [ Internal, Transient ];

/// SOAPBINARY - If = 1, then binary SOAP messages will be supported.<br/>
/// For requests directed to subclass of %SOAP.WebService but not EnsLib.SOAP.Service
Parameter SOAPBINARY As BOOLEAN;

/// SERVICENAME - Should be the name of the service for which this is a proxy.
/// Override this parameter in the subclass.
Parameter SERVICENAME;

/// SOAPPREFIX allows override of the default SOAP prefix.  Default is SOAP-ENV.
/// The prefix must be specified without the trailing ":".
Parameter SOAPPREFIX As STRING = "SOAP-ENV";

/// Checking the existence of REQUIRED properties and arguments is off by default.  
/// To turn on REQUIRED checking. set the SOAPCHECKREQUIRED parameter to 1 (default is 0).
Parameter SOAPCHECKREQUIRED As BOOLEAN = 0;

Property OutputTypeAttribute As %Boolean [ InitialExpression = 0 ];

/// OUTPUTTYPEATTRIBUTE allows the programmer to force the xsi:type attribute to be included
/// in all elements of a SOAP message which is a web client request or web service response.
Parameter OUTPUTTYPEATTRIBUTE As BOOLEAN = 0;

/// If <property>ReferencesInline</property> is true (1), then encoded objects are exported inline.
/// By default, SOAP encoded XMLExport of a class uses idref's for class instances referenced by
/// a class that is being exported.  This change allows the referenced class instances to be exported
/// inline as for "literal" format.
Property ReferencesInline As %Boolean [ Transient ];

/// If REFERENCESINLINE is true (1), then encoded objects are exported inline.
/// By default, SOAP encoded XMLExport of a class uses idref's for class instances referenced by
/// a class that is being exported.  This change allows the referenced class instances to be exported
/// inline as for "literal" format.
/// If the ReferencesInline property is specified, then it will override the REFERENCESINLINE parameter.
Parameter REFERENCESINLINE As BOOLEAN = 0;

/// If <property>Base64LineBreaks</property> is true (1), then include line breaks
/// in base64 encoded XML output for all properties of type %Binary or %xsd.base64Binary.
/// The default is 0 which excludes line breaks.
/// If this property is specified, then it will override the BASE64LINEBREAKS parameter.
Property Base64LineBreaks As %Boolean [ Transient ];

/// If BASE64LINEBREAKS is true (1), then include line breaks
/// in base64 encoded XML output for all properties of type %Binary or %xsd.base64Binary.
/// The default is 0 which excludes line breaks.
/// If the Base64LineBreaks property is specified, then it will override the BASE64LINEBREAKS parameter.
Parameter BASE64LINEBREAKS As BOOLEAN = 0;

/// The Transport property may be set to an instance of a transport class which will
/// provide a DoSoapRequest method that will take a request and obtain the response
/// using its transport.
Property Transport As %RegisteredObject [ Transient ];

/// Location property.  Initialized to LOCATION parameter.
Property Location As %String [ InitialExpression = {..#LOCATION}, Transient ];

/// Timeout property.  Controls timeout waiting, in seconds, for response.
Property Timeout As %Integer [ Transient ];

/// For a web service, this is the SOAP Fault to return.
///     The SoapFault property may be set before calling Process to return a SOAP fault.
/// For a web client, when the response message is a SOAP fault, then ZTRAP is throw and
///   SoapFault is the corresponding %SOAP.Fault instance.
Property SoapFault As %SOAP.Fault [ Transient ];

/// SAXFlags property.  The flags passed to the SAX parser.
Property SAXFlags As %Integer [ InitialExpression = {$$$SAXFULLDEFAULT-$$$SAXVALIDATIONSCHEMA}, Transient ];

/// The name of method that is called.
/// The method name is used to determine which WS-Policy applies and which headers are expected to be received.
Property MethodName As %String [ Internal, Transient ];

/// A list of supported SOAP headers is specified as a comma separated list of input header 
/// specifications.  Each specification is of the form "headerName:headerClass" where
/// headerName is the element name of the supported header and 
/// headerClass is the %SOAP.Header subclass that corresponds to that header.  
/// This list defines all headers supported in the SOAP request. 
Parameter SOAPHEADERS;

/// List of headers to be input
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property SoapHeaders As %String [ Private, Transient ];

/// Any SOAP header in the SOAP request that is found in the SOAPHEADERS list or header element 
/// of parameters XData is imported as a %SOAP.Header subclass and added to the HeadersIn array.  
/// The web method may then act on these headers as appropriate. 
Property HeadersIn As array Of %SOAP.Header [ Transient ];

/// Any web service or web client method may add instances of any %SOAP.Header subclass to this array.
/// The index is arbitrary but is usually the element name of the header.
/// The corresponding headers are then added to the SOAP response message.
/// This collection of headers is cleared after each method call.
Property HeadersOut As array Of %SOAP.Header [ Transient ];

/// WSADDRESSING parameter controls automatic generation of WS-Addressing headers.
Parameter WSADDRESSING As STRING [ Constraint = ",OFF,AUTO", Flags = ENUM ] = "OFF";

/// WS-Addressing properties of the input message.
/// AddressingIn will be = "", unless some WS-Addressing headers are
/// encountered in the SOAP headers.
Property AddressingIn As %SOAP.Addressing.Properties;

/// WS-Addressing properties for the output message.
/// SOAP headers will be constructed from these properties.
Property AddressingOut As %SOAP.Addressing.Properties;

/// Namespaces for message to be output.
Property NamespacesOut As %XML.Namespaces [ Internal, Transient ];

/// The XML namespace used for the security header.
/// SecurityNamespace is set based on WS-Security namespace used for an input message
/// or may be set to control the WS-Security namespace used for an output message.
Property SecurityNamespace As %String [ Transient ];

/// The wsu:Id attribute to be added to the Body element when writing a SOAP message.
Property BodyId As %String(MAXLEN = "") [ Transient ];

/// The xml:id attribute to be added to the Body element when writing a SOAP message.
/// Usually wsu:Id will be used, but in certain cases xml:id is needed.
Property BodyXmlId As %String(MAXLEN = "") [ Transient ];

/// OneWay is true if no body is to be sent.
Property OneWay As %Boolean [ Internal, Transient ];

/// Return the value of the BodyId property.
/// Populate the BodyId property if it is not yet set.
Method GetBodyId() As %String
{
	If ..BodyId'="" Quit ..BodyId
	If ..BodyXmlId'="" Quit ..BodyXmlId
	Set ..BodyId="Body-"_$system.Util.CreateGUID()
	Quit ..BodyId
}

/// The SECURITYIN parameter controls the treatment of a WS-Security header
/// in the input SOAP message.
/// The possible values of SECURITYIN are ALLOW, NOHEADER, IGNORE, IGNOREALL and REQUIRE.<br>
/// - The default value of IGNORE will ignore any WS-Security headers in the input
/// except for the UsernameToken which can always be used to login the user.<br>
/// - The value of ALLOW will cause the WS-Security header to be verified on input.<br>
/// - The value of REQUIRE will require the presence of the WS-Security header and
/// verify the header on input.<br>
/// - The value of IGNOREALL will ignore any WS-Security headers in the input
/// including the UsernameToken.<br><br>
/// - The value of NOHEADER will REALLY ignore any WS-Security headers in the input
/// including the UsernameToken.<br><br>
/// 
/// Note that if validation of the Security header is enabled (ALLOW or REQUIRE),
/// then a CA file, named iris.cer, containing the trusted root X509 certificates
/// should be put in the InterSystems IRIS manager directory if signature verification or decryption
/// is to be performed.  An optional Certificate Revocation List (iris.crl) may
/// also be put in the InterSystems IRIS manager directory.
Parameter SECURITYIN As STRING [ Constraint = "ALLOW,NOHEADER,IGNORE,IGNOREALL,REQUIRE", Flags = ENUM ] = "IGNORE";

/// The WS-Security header associated with the received SOAP message.
/// SecurityIn will = "" unless a Security heaader is present in the message.
Property SecurityIn As %SOAP.Security.Header [ Transient ];

/// The WS-Security header to be output with this SOAP message.
/// Note that SecurityOut is not automatically reset to "" between calls to the
/// web service or client.  Therefore, the same security headers will also
/// be used for any following calls.<br><br>
/// 
/// Any combination of Timestamp, UsernameToken and Signature elements may be included
/// in the Security header.<br>
/// To add a Timestamp element:<br>
///     <i>do ..SecurityOut.AddSecurityElement(##class(%SOAP.Security.Timestamp).Create(interval))</i><br>
///     The interval argument is the time in seconds between Created and Expires times.
///     If interval is not specified, then the default is 300 seconds.<br><br>
/// 
/// To add a UsernameToken element:<br>
///     <i>do ..SecurityOut.AddSecurityElement(##class(%SOAP.Security.UsernameToken).Create(username,password))</i><br>
///     The UsernameToken added using the above call will be used for all subsequent calls.
///     The WSSecurityLogin method should be used to add the UsernameToken just for the next call.<br><br>
/// 
/// To add a Signature element:<br>
///     <i>set x509=##class(%SYS.X509Credentials).GetByAlias(x509Alias)</i><br>
///     <i>set cert=##class(%SOAP.Security.BinarySecurityToken).CreateX509Token(x509)</i><br>
///     <i>do ..SecurityOut.AddSecurityElement(cert)</i><br>
///     <i>do ..SecurityOut.AddSecurityElement(##class(%XML.Security.Signature).CreateX509(cert))</i><br>
///     The configName argument is the name of a SSL/TLS Configuration, specified using the System Management Portal,
///     that contains the certificate file and private key file/password used for signing.
///     The private key password may be included with the configuration name as
///     "name|password" instead of in the configuration.
///     For initial release the configuration name is that of an SSL/TLS Configuration.
///     BEWARE that this is subject to change in future releases.
Property SecurityOut As %SOAP.Security.Header [ Transient ];

Method SecurityOutGet() As %SOAP.Security.Header [ Internal ]
{
 
	If r%SecurityOut="" {
		Set r%SecurityOut=##class(%SOAP.Security.Header).%New()
		Set r%SecurityOut.Namespace=
		  $select(..SecurityNamespace'="":..SecurityNamespace,1:##class(%SOAP.Security.Header).GetSecurityNamespace())
	}
	Quit r%SecurityOut
}

Method SecurityOutSet(s As %SOAP.Security.Header) As %Status [ Internal ]
{
	Set r%SecurityOut=s
	Quit $$$OK
}

/// Return SecurityOut if defined, else "".
Method GetSecurityOut() As %SOAP.Security.Header [ Internal ]
{
	Quit r%SecurityOut
}

/// The SecurityContextToken that is to be used for this WS-SecureConversation context.<br><br>
/// 
/// For a web client this is the SecurityContextToken that was obtained by the call to the StartSecureConversation 
/// call that started the session.  This call will save the SecureConversation token from the
/// RequestSecurityTokenResponse in this property.<br><br>
/// 
/// For a web service this is the SecurityContextToken that was used to secure the request message.
/// <br><br>
/// Future request or response messages may use this token if needed for the WS-Policy or
/// by explicitly adding to SecurityOut by calling AddSecurityElement.
Property SecurityContextToken As %SOAP.WSSC.SecurityContextToken [ Transient ];

/// The WS-ReliableMessaging sequence for this client or service.<br><br>
/// 
/// For a web client this is the sequence that was created by the call to the %StartRMSession
/// method that started the sequence.  This call will save the $SYS.RMSession object from the
/// CreateSequenceResponse in this property.<br><br>
/// 
/// For a web service this is the $SYS.RMSession that was used for the request message.
Property RMSession As %SYS.RMSession [ Transient ];

/// The Attachments property of %SOAP.WebService will contain any attachments as 
/// %Net.MIMEPart instances when a multipart/related SOAP request is received. 
/// The SOAP message itself will be executed as for any SOAP message.
/// 
/// If any %Net.MIMEPart instances are in the Attachments property list collection in 
/// %SOAP.WebClient, then the SOAP request will be sent as a multpart/related MIME message 
/// per the SOAP with Attachments specification.
Property Attachments As list Of %Net.MIMEPart [ Transient ];

/// The Content-Id of the SOAP part of the SOAP with Attachments package for SOAP requests.
/// ContentId is used only in conjunction with the Attachments property.
/// Set to the received Content-Id by the web service.
/// Set before calling a web client method to set the Content-Id.
Property ContentId As %String [ Transient ];

/// The Content-Location of the SOAP part of the SOAP with Attachments package for SOAP requests.
/// ContentLocation is used only in conjunction with the Attachments property.
/// Set to the received Content-Location by the web service.
/// Set before calling a web client method to set the Content-Location.
Property ContentLocation As %String [ Transient ];

/// If any %Net.MIMEPart instances are in the ResponseAttachments property list collection in 
/// %SOAP.WebService, then the SOAP response will be sent as a multpart/related MIME message 
/// per the SOAP with Attachments specification.
/// 
/// The ResponseAttachments property of %SOAP.WebClient will contain any attachments as 
/// %Net.MIMEPart instances when a multipart/related SOAP response is received. 
/// The SOAP message itself will be executed as for any SOAP message.
Property ResponseAttachments As list Of %Net.MIMEPart [ Transient ];

/// The Content-Id of the SOAP part of the SOAP with Attachments package for SOAP responses.
/// ResponseContentId is used only in conjunction with the ResponseAttachments property.
/// Set to the received Content-Id by the web client.
/// Set during the web service method to set the Content-Id.
Property ResponseContentId As %String [ Transient ];

/// The Content-Location of the SOAP part of the SOAP with Attachments package for SOAP responses.
/// ResponseContentLocation is used only in conjunction with the ResponseAttachments property.
/// Set to the received Content-Location by the web client.
/// Set during the web service method to set the Content-Location.
Property ResponseContentLocation As %String [ Transient ];

/// MTOMREQUIRED is the default value for the <property>MTOMRequired</property> which controls use
/// of MTOM optimization.
Parameter MTOMREQUIRED As BOOLEAN = 0;

/// MTOMRequired controls use of MTOM optimization.
/// If MTOMRequired is true, then SOAP messages will be sent as an MTOM package.<br>
/// For a web client, MTOMRequired=1 means that the SOAP request will be a MTOM package.
/// A web client will always be able to process a response as an MTOM package independent of the value of MTOMRequired.<br>
/// For a web service, MTOMRequired=1 means that the SOAP response will always be an
/// MTOM package even if the request was not MTOM.  MTOMRequired may be set in the
/// web method being called or in the OnPreWebMethod callback.  A web service will always respond with
/// an MTOM package if the request was an MTOM package independent of the value of MTOMRequired.<br>
/// The default for the MTOMRequired property is the value of the 
/// <parameter>MTOMREQUIRED</parameter> parameter.
Property MTOMRequired As %Boolean [ InitialExpression = {..#MTOMREQUIRED}, Transient ];

/// IsMTOM is set to true if an MTOM package was received.
Property IsMTOM As %Boolean;

/// This property contains the session cookie to be included in the InterSystems IRIS proprietary
/// SOAP session header to maintain the SOAP session.
/// SessionCookie will be set from the SOAP session header received in the SOAP request.
Property SessionCookie As %String [ Transient ];

/// Clear client HTTP cookies when setting SessionCookie from user code
Method SessionCookieSet(value As %String) As %Status [ Internal ]
{
	Set i%SessionCookie=value
	If ..%Extends("%SOAP.WebClient"),..HttpRequest'="" {
		Do ..HttpRequest.DeleteSessionCookie()
	}
	Quit $$$OK
}

/// Set SessionCookie directly for internal use
Method SessionCookieSetInternal(value As %String) [ Internal ]
{
	Set i%SessionCookie=value
}

/// The username that is associated with this SOAP request.<br>
/// Note that InterSystems IRIS security login is based on the UsernameToken element of the Security header.<br>
/// For a web client, if Username is set then a UsernameToken will be included
/// in the Security header based on the Username and Password properties.<br>
/// For a web service, Username is set based on the username contained in the
/// UsernameToken in the Security header of the message.
/// For a request message Username is based on the WS-Security SOAP header in the request.
Property Username As %Library.Username [ Transient ];

/// The password that is associated with this SOAP request.<br>
/// Note that InterSystems IRIS security login is based on the UsernameToken element of the Security header.<br>
/// For a web client, if Username is set then a UsernameToken will be included
/// in the Security header based on the Username and Password properties.<br>
/// For a web service, Password is set based on the password contained in the
/// UsernameToken in the Security header of the message.
Property Password As %String [ Transient ];

/// If the GZIPOUTPUT parameter is set to true (1), then output (request for client,
/// response for service) will be compressed using GZIP.  
/// For a web client, this may be overridden by setting the GzipOutput
/// property of the web client class.
Parameter GZIPOUTPUT As BOOLEAN;

/// Specify the name of the method to call to write the SOAP body by putting the method
/// name into the WriteSOAPBodyMethod property of the web service or web client class.  For example<br> 
/// <pre>
///   Method test(..... [WebMethod] ; for a client
///   { 
///      Set ..WriteSOAPBodyMethod="override" 
///      Do ..WebMethod("test").Invoke(..... 
///      Set ..WriteSOAPBodyMethod="" 
///   } 
/// </pre>
/// 
///  or
/// 
/// <pre>
///   Method test(..... [WebMethod] ; for a service
///   { 
///      Set ..WriteSOAPBodyMethod="override" 
///      ; service method follows
///      .....
///   } 
/// </pre>
/// The signature of the override method is<br>
/// <pre>
///   Method override(proxy As %SOAP.ProxyDescriptor, tag As %String)
/// </pre>
/// The override method uses the Write command to output the body.
Property WriteSOAPBodyMethod As %String [ Transient ];

/// Control use of BOM for request message.
/// Comma separated list of message start parts:  
/// BOM to include BOM, DCL to include XML declaration.
Property RequestMessageStart As %String [ InitialExpression = "DCL", Transient ];

/// Policy alternative for client output of request and service input of request.
/// First alternative checked for response.
Property policyAlternative As %String [ Internal, MultiDimensional, Transient ];

/// After the %SOAP.WebService Initialize method is called, this property contains the %XML.Document
/// instance for the parsed SOAP request.
/// After the %SOAP.Webclient parses the response, this property contains the %XML.Document
/// instance for the parsed SOAP response.
Property ImportHandler As %XML.Document [ Transient ];

/// Log a message
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod LogText(text As %String, outputRaw As %Boolean = 0) [ Internal, ServerOnly = 1 ]
{
	/// If the LogFile is too big or there are LogConfig present ( "LogJob", "LogClass", "LogURL")
	If $$$CheckSOAPLogStop Quit
	Set file=$get(^ISCSOAP("LogFile"))
	If file="" Quit 

	/// Method called directly from many locations via SOAPLogText and SOAPLogRawText macros
	/// Hence unable to push filtering further upstream
	/// To optimize calling code could concatenate multiple lines of text upsteam with the OS line delimiter,
	/// and then only need to invoke the "logText" method once
	
	Try {
		Set open=0,io="",error=""
		Set io=$io
		Open file:"waes":1 else  Set error="Unable to open SOAP log file" Quit
		Set open=1
		Use file
		If outputRaw {
			$$$SETIO("RAW")
		} ElseIf $$$IsUnicode {
			// On Unicode systems, output the text in UTF-8.
			// On 8-bit systems, use the default file translate table.
			$$$SETIO("UTF8")
		}
		
		
		If $isobject(text) {
			Do text.OutputToDevice()
			Write !
		} ElseIf text=0 {
			// We are outputting using the SOAP stream
			Do xeOutput^%occXMLInternal(1)
		} Else {
			For i=1:1:$length(text,$c(13,10)) {
				Write $piece(text,$c(13,10),i),!
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

/// Log the contents of a global
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod LogGlobal(var As %String) [ Internal, ServerOnly = 1 ]
{
	/// If the LogFile is too big or there are LogConfig present ( "LogJob", "LogClass", "LogURL")
	If $$$CheckSOAPLogStop Quit
	Set file=$get(^ISCSOAP("LogFile"))
	If file="" Quit

	Try {
		Set open=0,io="",error=""
		Set io=$io
		Open file:"waes":1 else  Set error="Unable to open SOAP log file" Quit
		Set open=1
		Use file
		$$$SETIO("RAW")
		
		Xecute "zw "_var
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

/// Log the input message
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod LogInput(isService As %Boolean, action As %String, inputStream, status As %Status) [ Internal, ServerOnly = 1 ]
{
	/// If the LogFile is too big or there are LogConfig present ( "LogJob", "LogClass", "LogURL")
	If $$$CheckSOAPLogStop Quit
	If ('$$$CheckSOAPLogInput) Quit

	Set file=$get(^ISCSOAP("LogFile"))
	If file="" Quit
	
	Try {
		Set open=0,io="",error=""
		Set io=$io
		Open file:"waes":1 else  Set error="Unable to open SOAP log file" Quit
		Set open=1
		If 'isService {
			Use file
		} Else {
			// use IO redirection to mask SOAP password
			New %soapLogState
			Use file::("^%occXMLInternal")
			Do ##class(%Library.Device).ReDirectIO(1)
		}
		$$$SETIO("RAW")

		If $$$CheckSOAPTestMode {
			Write !,!,"**** "
		} Else {
			// UTC timestamp converted to localtime preserving fractional seconds in human readable format
			Write !,!,$$$SOAPLogFormatedDateTime_" *********************"_$c(13,10)
		}
		Write "Input to Web "_$select(isService:"service",1:"client")_" with SOAP action = "_action,!
		If ($get(status)'="") && $$$ISERR(status) {
			Do $system.Status.DecomposeStatus(status,.err)
			Write !,$zstrip($piece(err(1),"[",1),">W"),!
		}
		// Try to log just headers if requested
		If (($$$CheckSOAPLogSOAPHeaders)&&(..LogHeaders(inputStream))) Quit
		// Log entire message otherwise
		If $isobject(inputStream) {
			Do inputStream.OutputToDevice()
			Do inputStream.Rewind()
		} Else {
			Write inputStream
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

/// Log the output message
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod LogOutput(isService As %Boolean, action As %String, outputStream, description As %String) [ Internal, ServerOnly = 1 ]
{
	/// If the LogFile is too big or there are LogConfig present ( "LogJob", "LogClass", "LogURL")
	If $$$CheckSOAPLogStop Quit
	If ('$$$CheckSOAPLogOutput) Quit

	Set file=$get(^ISCSOAP("LogFile")) 
	If file="" Quit
	
	Try {
		Set open=0,io="",error=""
		Set io=$io
		Open file:"waes":1 else  Set error="Unable to open SOAP log file" Quit
		Set open=1
		If isService {
			Use file
		} Else {
			// use IO redirection to mask SOAP password
			New %soapLogState
			Use file::("^%occXMLInternal")
			Do ##class(%Library.Device).ReDirectIO(1)
		}
		$$$SETIO("RAW")

		If $$$CheckSOAPTestMode {
			Write !,!,"**** "
		} Else {
			// UTC timestamp converted to localtime preserving fractional seconds in human readable format
			Write !,!,$$$SOAPLogFormatedDateTime," *********************"_$c(13,10)
		}
		Write "Output from Web "_$select(isService:"service",1:"client")_" with SOAP action = "_action,!
		If $get(description)'="" Write description,!
		// Try to log just headers if requested
		If (($$$CheckSOAPLogSOAPHeaders)&&(..LogHeaders(outputStream))) Quit
		// Log entire message otherwise
		If $isobject(outputStream) {
			Do outputStream.Rewind()
			Do outputStream.OutputToDevice()
			Do outputStream.Rewind()
		} ElseIf outputStream=0 {
			Do xeOutput^%occXMLInternal(1)
		} Else {
			Write outputStream
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

/// Log only the beginning of the SOAP message up to the end of the SOAP headers.
/// Return true if Headers found and output/
ClassMethod LogHeaders(stream) As %Boolean [ Internal, Private, ServerOnly = 1 ]
{
	/// If the LogFile is too big or there are LogConfig present ( "LogJob", "LogClass", "LogURL")
	If $$$CheckSOAPLogStop Quit
	
	Set result=0
	Try {
		If stream=0 {
			$$$XMLRewind
			Set buffer=$$$XMLRead(32000)
		} ElseIf $isobject(stream) {
			Do stream.Rewind()
			Set buffer=stream.Read(32000)
		} Else {
			Set buffer=stream
		}
		Set pos=1
		
		// If MTOM output, then skip ahead to <?xml
		If $extract(buffer,1,2)="--" {
			Set pos=$find(buffer,"<?xml",pos)
			// If <?xml not found, then just output all
			If pos=0 Quit
			// backup to <?xml
			Set pos=pos-5
		}

		// If has BOM, skip the BOM
		If $Ascii(buffer)=$$$UNIVAL {
			Set pos=pos+1
		} ElseIf $extract(buffer,1,3)=$$$UTF8BOM {
			Set pos=pos+3
		}

		// Look for optional <?xml
		If $extract(buffer,pos,pos+4)="<?xml" {
			Set pos=$find(buffer,"?>",pos)
			// If malformed, then cannot output just Headers
			If pos=0 Quit
		}

		// Look for required Envelope element
		Set env=$zstrip($translate($extract(buffer,pos,pos+100),$c(9,10,13,160)," "),"<W")
		If $extract(env,1)="<" {
			Set env=$piece($piece(env," ",1),">",1)
			If (($length(env,":")=1) && (env="<Envelope")) ||
			   (($length(env,":")=2) && ($piece(env,":",2)="Envelope")) {
				Set pos=$find(buffer,">",pos)
			} Else {
				// If no Envelope, then cannot output just Headers
				Set pos=0
			}
		} Else {
			// If no Envelope, then cannot output just Headers
			Set pos=0
		}
		// If malformed, then cannot output just Headers
		If pos=0 Quit
		
		// Stream as expected
		Set result=1
		
		// Look for Headers element
		Set header=$zstrip($translate($extract(buffer,pos,pos+100),$c(9,10,13,160)," "),"<W")
		Set hdrpos=0
		If $extract(header,1)="<" {
			Set header=$piece($piece(header," ",1),">",1)
			If (($length(header,":")=1) && (header="<Header")) ||
			   (($length(header,":")=2) && ($piece(header,":",2)="Header")) {
				Set hdrpos=$find(buffer,">",pos)
			}
		}
		// If no Header, then just output Envelope
		If hdrpos=0 {
			Write $extract(buffer,1,pos-1),$c(13,10)
			Quit
		}
		Set endheader="</"_$extract(header,2,*)
		
		// Now write until end of the Header element
		While buffer'="" {
			// Now we need to look for end of Header element
			Set pos=hdrpos
			While pos'=0 {
				Set pos=$find(buffer,endheader,pos)
				If pos'=0 {
					Set pos=$find(buffer,">",pos)
					If pos'=0 {
						Set pos=pos-1
					} Else {
						Set pos=$length(buffer)
					}
					Quit
				}
			}
			// If end of headers found, write until end of headers and quit
			If pos'=0 {
				Write $extract(buffer,1,pos),$c(13,10)
				Quit
			}

			// If /Header not found, then write the entire buffer and get the next buffer
			Write buffer
			If stream=0 {
				Set buffer=$$$XMLRead(32000)
			} ElseIf $isobject(stream) {
				Set buffer=stream.Read(32000)
			} Else {
				Set buffer=""
			}
			Set hdrpos=1
		}
	} Catch {
	}
	
	If stream=0 {
		$$$XMLRewind
	} ElseIf $isobject(stream) {
		Do stream.Rewind()
	}

	Quit result
}

/// Given an expected list of lines, read through the current SOAP log trying to match 
/// a region of expected sequential lines in the SOAP Log.
/// <br/>
/// <ul>
/// <li>logName - Path to specific SOAP log for analysis.
/// If empty, defaults to the LogFile setting (^ISCSOAP("LogFile")) for current namespace<li/>
/// <li>lines - One or more lines composing a sequence of text to match in SOAP log file
/// </li>
/// <li>namespace - Namespace for corresponding SOAP Log file to read</li>
/// <li>lineOffset - Updated lineOffset when method is called. Start with "0" for beginning of file. Helps resume read in next SOAPLogContains match from last read position. ie: does not parse the file from beginning. Helpful to defrentiate repeating seqences of logging in a log file.</li>
/// <li>trim - Ignore any leading and trailing whitespace for comparison</li>
/// <li>maskdate - Convert date DD/MM/CCYY HH:mm:SS.nnnnnnn to ##/##/## ##:##:##.#######</li> 
/// <li>maxReadLines - Maximum expected number of subsequent lines to parse before assumping sequence not found.</li>
/// <li>stopAtEmptyLine - Keep reading lines of input until an empty line is encountered.</li>
/// <li>caseInsensitive - Case insensitive search for sequence comparison</li>
/// <li>maskNumeric - Convert a numeric sequence into tokens "#". For example "123" becomes "###"</li>
/// <li>shortenMask - Used in  conjuntion with maskNumeric. Shortens one or more sequental "#" characters to a single "#". For example "###" becomes "#"</li> 
/// <li>
/// </ul>
/// <example>
/// Kill lines
/// set expect= [ Some condition evaluating to 1 ( Sequential Lines expected ) or 0 ( Sequential Lines NOT expected )  ]
/// set lineOffset=0
/// set lines($I(lines))="##/##/#### ##:##:##.####### *********************"
/// Set lines($I(lines))="Binary Input to Web client with SOAP action = http://tempuri.org/WSDL.SoapLog.WebService.Concatenate"
/// Do $$$AssertEquals(expect,##class(%SOAP.WebBase).SOAPLogContains(,.lines,,.lineOffset,,1),"Log Input to Web client")
/// </example>
ClassMethod SOAPLogContains(logName As %String = "", ByRef lines, namespace = {$NAMESPACE}, ByRef lineOffset = 0, trim As %Boolean = 0, maskdate As %Boolean = 0, maxReadLines = 0, stopAtEmptyLine = 0, caseInsensitive = 0, maskNumeric = 0, shortenMask = 0) As %Boolean [ ServerOnly = 1 ]
{
	Quit:'##class(%SYS.Namespace).Exists(namespace) 0
	Set:logName="" logName=$G(^|namespace|ISCSOAP("LogFile"))
	// No log file to configured. Return false
	Quit:logName="" 0

	// No log file to check.
	If ('##class(%File).Exists(logName)) {
		// No log expected. Return false
		Return:$Data(lines)=0 1
		// Missing file indicates, no logs written
		Return 0
	}
	// No data expected
	If $Data(lines)<10 {
		// file empty as expected
		If 0=##class(%File).GetFileSize(logName) {
			Return 1	
		}
		// file has unexpected content
		Return 0
	}
	
	Set originalLineOffset=+$G(lineOffset)
	Set expectItem=$Order(lines(""),1,nextline)
	Return:nextline="" 0
	Set:trim nextline=$ZSTRIP(nextline,"<>W")
	Set:caseInsensitive nextline=$ZCVT(nextline,"l")
	Set found=0
	Set stream=##class(%FileCharacterStream).%New()
	Set stream.Filename=logName
	Set nextoffset=0
	// Seek forward in the file to a previous line offset
	For {
		Quit:stream.AtEnd
		Quit:nextoffset>=lineOffset  // default is to quit without reading first line
		Set line=stream.ReadLine()
		Set nextoffset=nextoffset+1		
	}
	// Read forwards matching line(s)
	Set lineReadCount=0
	For {
		Quit:expectItem=""
		Quit:stream.AtEnd
		Quit:found=2
		If ((maxReadLines)&&(lineReadCount>=maxReadLines)) Quit
		Set line=stream.ReadLine()
		Set:trim line=$ZSTRIP(line,"<>W")
		If ((stopAtEmptyLine) && (""=line)) Quit
		Set lineReadCount=lineReadCount+1
		Set:maskdate line=..MaskSOAPLogDate(line)
		Set:caseInsensitive line=$ZCVT(line,"l")
		If maskNumeric {
			Set line=$TR(line,"0123456789","##########")
			If shortenMask {
			  For {Quit:line'["##"  Set line=$Replace(line,"##","#")}
			}
		}
		Set lineOffset=lineOffset+1
		If found=0 {
			If line=nextline {
				// Only one line to match
				If ""=$Order(lines(expectItem)) {
					Set found=2
					Quit
				} Else {
					Set found=1
					Continue
				}
			}
			// look for next initial match
			Continue
		}
		If found=1 {
			Set expectItem=$Order(lines(expectItem),1,nextline)
			Set:trim nextline=$ZSTRIP(nextline,"<>W")
			Set:caseInsensitive nextline=$ZCVT(nextline,"l")
			If nextline'=line {
				Set found=0
				Set expectItem=$Order(lines(""),1,nextline)  // Reset to first item
				Continue	
			}
			If ((nextline=line)&&(""=$Order(lines(expectItem)))) {
				Set found=2
				Quit
			}			
		}
	}
	If (2=found) {
		Return 1
	} Else {
		// Do not advance log file line offset if match is unsucessful
		// ie: Continue to match subsequent content from last sucessful read position
		Set lineOffset=originalLineOffset
		Return 0
	}
}

/// For comparing SOAP Log content
/// Dates in SOAP Log output cause differences in expected output.
/// This method replaces one or more dates in a given line of text with a mask.
/// For example sequence "DD/MM/CCYY HH:mm:SS.nnnnnnn" is replaced
/// with the literal "##/##/#### ##:##:##.#######"
/// or Sequence "DD/MM/CCYY HH:mm:SS" is replaced with "##/##/#### ##:##:##"
ClassMethod MaskSOAPLogDate(line) As %String [ Internal, ServerOnly = 1 ]
{
	Quit:line'?.E2N1"/"2N1"/"4N1" "2N1":"2N1":"2N.1(1"."7N).E line
	Set maskpos=0
	For i=1:1:$L(line) {
		Set char=$E(line,i)
		Continue:char=""
		If maskpos=0,char?1N {
			Set maskpos=1
			Set offsetStart=i
			Continue
		}
		If maskpos>0 {
			Set maskpos=maskpos+1
			If char?1N,",1,2,4,5,7,8,9,10,12,13,15,16,18,19,21,22,23,24,25,26,27,"[","_maskpos_"," {
				// End of expected sequence reached, replace with mask
				If 27=maskpos {
					Set $E(line,offsetStart,offsetStart+26)="##/##/#### ##:##:##.#######"
					Set maskpos=0
				}
			} ElseIf char="/",",3,6,"[(","_maskpos_",") {
			} ElseIf char=" ",maskpos=11 {
			} ElseIf char=":",",14,17,"[(","_maskpos_",") {
			} ElseIf char=".",maskpos=20 {
			} Else {
				Set:20=maskpos $E(line,offsetStart,offsetStart+18)="##/##/#### ##:##:##"
				// Expected sequence inturrupted. Monitor for start of new sequence.
				Set maskpos=0
			}
		}
	}
	Quit line
}

/// Get namespace parameter in order to avoid otherwise unnecessary generator methods.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod Namespace() [ CodeMode = expression, Final, Internal, ServerOnly = 1 ]
{
..#NAMESPACE
}

/// Write the entire HTTP content for a SOAP request or response.
/// If a web client, then always write the HTTP content to a stream.
/// If a web service, then write the HTTP content to the current TCP device.
Method WriteHTTPContent(body As %SOAP.Descriptor, tag As %String, isService As %Boolean, wsRequired As %Boolean, bodyStream As %CharacterStream, response As %CSP.Response, ByRef stream As %FileBinaryStream) As %Status [ Internal, ServerOnly = 1 ]
{
	Set sc=$$$OK
	Set logOutput=$$$CheckSOAPLogOutput
	
	#; Initialize headers for any required MIME attachments.
	Set soap12=(..SoapVersion="1.2")
	Set soaptype=$select(soap12:"application/soap+xml",1:"text/xml")
	If isService {
		Set attachments=..ResponseAttachments
		Set contentid=..ResponseContentId
		Set contentLocation=..ResponseContentLocation
	} Else {
		Set attachments=..Attachments
		Set contentid=..ContentId
		Set contentLocation=..ContentLocation
	}
	Set numAttachments=attachments.Count()
	Set responseMTOM=(..MTOMRequired || ..IsMTOM)
	If (numAttachments>0) || responseMTOM {
		Set mimeAttachments=##class(%Net.MIMEPart).%New()
		For i=1:1:numAttachments Do mimeAttachments.Parts.Insert(attachments.GetAt(i))
		Set contentid=..ContentId
		If responseMTOM {
			If contentid="" {
				Set mimeAttachments.ContentId=$tr($system.Util.CreateGUID(),"-",".")
				Set contentid="0."_mimeAttachments.ContentId
			} Else {
				Set mimeAttachments.ContentId=contentid
			}
			Set contentType=
				"multipart/related; type=""application/xop+xml""; boundary="_mimeAttachments.Boundary_
				"; start=""<"_contentid_">""; start-info="""_soaptype_""""
		} Else {
			Set contentType="multipart/related; type="""_soaptype_"""; boundary="_mimeAttachments.Boundary
			If contentid'="" Set contentType=contentType_"; start=<"_contentid_">"
		}
		If 'isService,soap12 Set contentType=contentType_"; action="""_..Action_""""
		Set mimeAttachments.ContentType=contentType
		If $isobject(response) {
			If response.GetHeader("MIME-Version")="" {
				Do response.SetHeader("MIME-Version","1.0")
			}
			Set response.ContentType=contentType
			Set response.CharSet=$select($$$XMLIsWrite:"utf-8",1:"")
			Do response.WriteHTTPHeader(.OutputBody)
		}
	} Else {
		Set mimeAttachments=""
		Set contentType=""_soaptype_"; charset=UTF-8"
		If 'isService,soap12 Set contentType=contentType_"; action="""_..Action_""""
		If $isobject(response) {
			If ..SoapVersion="1.2" Set response.ContentType=soaptype
			Do response.WriteHTTPHeader(.OutputBody)
		}
	}
	
	If 'isService Set ..ContentType=contentType
	
	#; Save space for MIME headers for part containing SOAP envelope
	If mimeAttachments'="" {
		If $$$XMLIsWrite {
			Do ..WriteStartAttachments(mimeAttachments.Boundary,soaptype,isService,contentid,contentLocation)
		} Else {
			$$$XMLUseNext
		}
	}

	#; Setup Security header binary line breaks
	If ..Base64LineBreaks="" Set ..Base64LineBreaks=..#BASE64LINEBREAKS
	If $isobject(r%SecurityOut) {
		Set r%SecurityOut.Base64LineBreaks=..Base64LineBreaks
	}
	
	#; Setup encoded inline property for body and headers
	If ..ReferencesInline="" Set ..ReferencesInline=..#REFERENCESINLINE

	#; Output the SOAP envelope	
	Set sc=..WriteSOAPMessage(body,tag,isService,mimeAttachments,.bodyStream)
	If $$$ISERR(sc) Goto HTTPError
	If wsRequired {
		If $$$CheckSOAPLogSecurity {
			Do ..LogOutput(isService,..Action,0,"Before WS-Security applied")
		}
		
		#; Pass attchments through to signing code.
		New %cspsoapmimeAttachments
		Set %cspsoapmimeAttachments=mimeAttachments
		
		#; If signing or encryption needed, then add these security elements 
		#; to the WS-Security header.
		If $isobject(r%SecurityOut) {
			Set sc=r%SecurityOut.Perform()
			If $$$ISERR(sc) Goto HTTPError
		}
		#; Perform operation for any custom security headers
		Set sc=$$$OK
		Set headerName=""
		For {
			If $$$ISERR(sc) Quit
			Set header=..HeadersOut.GetNext(.headerName)
			If headerName="" Quit
			If $parameter(header,"CUSTOMSECURITY") {
				Set sc=header.Perform()
				If $$$ISERR(sc) Quit
			}
		}
		If $$$ISERR(sc) Goto HTTPError
	
	}
	$$$SOAPTimer($select(isService:"s",1:"c")_"wperform")
	$$$XMLUseLast

	#; Output MIME parts for attachments
	If mimeAttachments'="" {
		#; Output Attachments
		Set writer=##class(%Net.MIMEWriter).%New()
		If $$$XMLIsWrite {
			$$$SETIO("RAW")
			Set sc=writer.WriteMIMEBody(mimeAttachments)
			If $$$ISERR(sc) Goto HTTPError

		} Else {
			Do writer.OutputToStream(0)  ;; output to internal SOAP buffer.
			Set sc=writer.WriteMIMEBody(mimeAttachments)
			If $$$ISERR(sc) Goto HTTPError
			$$$XMLUseNext

			#; Go back and output MIME headers
			Set saveIndex=$$$XMLCurrentIndex
			Set $$$XMLCurrentIndex=1
			$$$XMLSetTerminator($c(13,10))
			Do ..WriteStartAttachments(mimeAttachments.Boundary,soaptype,isService,contentid,contentLocation)
			$$$XMLSetDefaultTerminator
			Set $$$XMLCurrentIndex=saveIndex
		}
	}

	If logOutput Do ..LogOutput(isService,..Action,0)
	
HTTPError
	Quit sc
}

/// Output the start of the first MIME block for attachments
Method WriteStartAttachments(boundary As %String, soaptype As %String, isService As %Boolean, contentid As %String, contentLocation As %String) [ Internal, ServerOnly = 1 ]
{
	$$$XMLSetBuffer("--"_boundary)
	$$$XMLWriteLine
	If (..MTOMRequired || ..IsMTOM) {
		$$$XMLSetBuffer("Content-Type: application/xop+xml; type="""_soaptype_"""; charset=""UTF-8""")
	} Else {
		$$$XMLSetBuffer("Content-Type: "_soaptype_"; charset=""UTF-8""")
	}
	If 'isService,..SoapVersion="1.2" $$$XMLAppendBuffer("; action="""_..Action_"""")
	$$$XMLWriteLine
	$$$XMLSetBuffer("Content-Transfer-Encoding: 8bit")
	$$$XMLWriteLine
	If contentid'="" {
		$$$XMLSetBuffer("Content-Id: <"_contentid_">")
		$$$XMLWriteLine
	}
	If ..ContentLocation'="" {
		$$$XMLSetBuffer("Content-Location: "_contentLocation)
		$$$XMLWriteLine
	}
	$$$XMLSetBuffer("")
	$$$XMLWriteLine
}

/// Execute the Web Method represented by the descriptor class on
/// the server.  If an error is detected, a ztrap "SOAP" will be issued with
/// %objlasterror containing the error %Status.  If is the responsibilty of the
/// caller of the proxy method to set an error trap and test for $ZE["&lt;ZSOAP&gt;".
/// Note that if a SOAP fault is received, then the error is $$$SOAPFaultReceived.
/// Write the SOAP message that corresponds to the specified class.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method WriteSOAPMessage(body As %SOAP.Descriptor, tag As %String, isService As %Boolean, mimeAttachments As %Net.MIMEPart, bodyStream As %CharacterStream) As %Status [ Internal, ServerOnly = 1 ]
{
	$$$SOAPTimerSetup(New %SOAPTimerChar Set %SOAPTimerChar=$select(isService:"s",1:"c"))
	$$$SOAPTimer(%SOAPTimerChar_"wmsg")
	Do body.GetSoapParameters(.bindingStyle,.bodyUse,.namespace,.xmlimportnamespace,.typeNamespace,.oneWay,.xmlelement,.bare)
	Set headers=..HeadersOut
	
	Set forceTNS=('bare && (bindingStyle="document") && ('xmlelement) && (namespace'=typeNamespace))
	Do ..BeginSOAPEnvelope(bindingStyle,bodyUse,namespace,typeNamespace,forceTNS,.namespaces)
	$$$SOAPTimer(%SOAPTimerChar_"wenv")
	
	$$$XMLUseNext
 
	If (headers'="") || (..AddressingOut'="") || 
	   ($isobject(r%SecurityOut) && (r%SecurityOut.SecurityElement.Count()>0)) {
		Set sc=..WriteSOAPHeaders(bodyUse,namespaces,mimeAttachments)
		If $$$ISERR(sc) Quit sc
	}
	$$$SOAPTimer(%SOAPTimerChar_"wsec")
	
	If 'isService || 'oneWay {	// If one-way service response with headers, then no body.
		$$$XMLSetBuffer("  <"_..#SOAPPREFIX_":Body")
		Set securityHeader=r%SecurityOut
		If ..BodyId'="" {
			$$$XMLAppendBuffer(" wsu:Id="""_..BodyId_"""")
			Set ..BodyId=""
		}
		If ..BodyXmlId'="" {
			$$$XMLAppendBuffer(" xml:id="""_..BodyXmlId_"""")
			Set ..BodyXmlId=""
		}
		If (bodyUse="encoded") && (..SoapVersion="1.1") {
			$$$XMLAppendBuffer(" "_..#SOAPPREFIX_":encodingStyle='"_$$$SOAPENCns_"'")
		}
		$$$XMLAppendBuffer(">")
		$$$XMLWrite
		
		$$$XMLUseNext
		If $isobject(r%SecurityOut),'$$$XMLIsWrite {
			Set r%SecurityOut.BodyBufferIndex=$$$XMLCurrentIndex
		}
		If ..WriteSOAPBodyMethod'="" {
			If $$$XMLIsWrite {
				Set sc=$method($this,..WriteSOAPBodyMethod,body,tag)
			} Else {
				Set bodyStream=##class(%FileBinaryStream).%New()
				Set sc=bodyStream.Write("") ; force stream's file to open
				If $$$ISOK(sc) {
					Set io=$io
					Set file=bodyStream.Filename ; get filename and make current device
					Use file:(/NOXY)
					$$$SETIO("UTF8")
					Set sc=$method($this,..WriteSOAPBodyMethod,body,tag)
					Use io
					$$$XMLSetStream(bodyStream)
				}
			}
		} Else {
			If $data(bodyStream) {
				If $$$XMLIsWrite {
					If $isobject(bodyStream) {
						Set sc=bodyStream.OutputToDevice()
					} Else {
						Write bodyStream
					}
				} Else {
					// Need to convert to UTF-8 now since the rest of the envelope is UTF-8
					Set responseBody=##class(%GlobalCharacterStream).%New()
					Set sc=bodyStream.Rewind()
					While $$$ISOK(sc)&&'bodyStream.AtEnd {
						Set sc=responseBody.Write($zcvt(bodyStream.Read(.len),"O","UTF8"))
					}
					$$$XMLSetStream(responseBody)
				}
			} Else {
				Set format=bodyUse
				If bare {
					Set format=format_",group"
				} Else {
					If (bodyUse="encoded") && (..SoapVersion'="1.1") {
						Set attrs($increment(attrs))=..#SOAPPREFIX_":encodingStyle"
						Set attrs(attrs,0)=$$$SOAP12ENCns
						Set format="encoded12"
					}
					If forceTNS Set tag="tns:"_tag
				}
				Set namespaces.AttributeQualified=''..#ATTRIBUTEQUALIFIED
				If ..ReferencesInline Set format=format_",inline"
				If ..Base64LineBreaks Set format=format_",base64linebreaks"
				Set sc=body.XMLExport(tag,format,namespaces,.attrs,,,,,,,mimeAttachments)
				$$$XMLUseNext
			}
		}
		If $$$ISERR(sc) Quit sc

		$$$XMLSetBuffer("</"_..#SOAPPREFIX_":Body>")
		$$$XMLWriteLine
	} Else {
		$$$XMLSetBuffer("  <"_..#SOAPPREFIX_":Body></"_..#SOAPPREFIX_":Body>")
		$$$XMLWriteLine
	}
	$$$SOAPTimer(%SOAPTimerChar_"wbody")

	If mimeAttachments'="" $$$XMLSetTerminator($c(13,10))
	Do ..EndSOAPEnvelope()
	If mimeAttachments'="" $$$XMLSetDefaultTerminator

	Quit $$$OK
}

/// Add a namespace definition to the SOAP Envelope element of the message to
/// be output, i.e. reply message for service, request message for client.
/// To add a namespace to a web service reply message, %AddEnvelopeNamespace 
/// must be called from the web method.
/// To add a namespace to a web client request message, %AddEnvelopeNamespace
/// must be called before the web client method is invoked.<br><br>
/// 
/// <var>prefix</var> is the optional preferred prefix for this namespace.
/// If no prefix is specified, a unique prefix will be computed.<br><br>
/// 
/// A <var>schemaLocation</var> attribute value for the first definition
/// of this namespace may also specified.<br><br>
/// 
/// If <var>allowMultiplePrefixes</var> is true then multiple prefixes may be defined for the same namespace.
/// The default is false which will override the previously defined prefix for the same namespace.
Method %AddEnvelopeNamespace(namespace As %String, prefix As %String, schemaLocation As %String, allowMultiplePrefixes As %Boolean) As %Status
{
	If '$isobject(..NamespacesOut) {
		Set ..NamespacesOut=##class(%XML.Namespaces).%New()
	}
	Quit ..NamespacesOut.AddNamespace(namespace,.prefix,.schemaLocation,.allowMultiplePrefixes)
}

/// Output the beginning of the SOAP envelope.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method BeginSOAPEnvelope(bindingStyle As %String, bodyUse As %String, namespace As %String, typeNamespace As %String, forcePrefix As %Boolean, ByRef namespaces As %XML.Namespaces) [ Internal, ServerOnly = 1 ]
{
	If '$isobject(..NamespacesOut) {
		Set namespaces=##class(%XML.Namespaces).%New()
	} Else {
		Set namespaces=..NamespacesOut
		Do namespaces.DefineAllNamespacePrefixes()
	}
	If $case(namespace,$$$SOAPWSTNS:1,$$$SOAPWSRMns:1,:0) {
		Set elementQualified=1
		Set attributeQualified=0
		Set namespaces.OutputTypeAttribute=0
	} Else {
		Set elementQualified=..#ELEMENTQUALIFIED
		If elementQualified="" Set elementQualified=(bodyUse="literal")
		Set attributeQualified=..#ATTRIBUTEQUALIFIED
		Set namespaces.OutputTypeAttribute=..#OUTPUTTYPEATTRIBUTE
	}
	Do namespaces.AddInstanceNamespace("xsi")
	Do namespaces.AddSchemaNamespace("s")
	If ..SoapVersion="1.2" {
		Set soapns=$$$SOAP12ENVns
	} Else {
		Set soapns=$$$SOAPENVns
	}
	Do namespaces.AddNamespace(soapns,..#SOAPPREFIX)
	If ..RequestMessageStart["BOM" {
		If $$$XMLIsWrite $$$SETIO("RAW")
		$$$XMLSetBuffer($char(239,187,191))
		$$$XMLWriteRAW
		If $$$XMLIsWrite $$$SETIO("UTF8")
	}
	If ..RequestMessageStart["DCL" $$$XMLSetBuffer("<?xml version=""1.0"" encoding=""UTF-8"" ?>") $$$XMLWriteLine
	$$$XMLSetBuffer("<"_..#SOAPPREFIX_":Envelope xmlns:"_..#SOAPPREFIX_"='"_soapns_"'")
	$$$XMLAppendBuffer(" xmlns:xsi='"_$$$XSIns_"'")
	$$$XMLAppendBuffer(" xmlns:s='"_$$$XSDns_"'")
	If bodyUse="encoded" {
		Set soapenc=$select(..SoapVersion="1.2":$$$SOAP12ENCns,1:$$$SOAPENCns)
		$$$XMLAppendBuffer(" xmlns:SOAP-ENC='"_soapenc_"'")
		Do namespaces.AddNamespace(soapenc,"SOAP-ENC")
	}
	If (bindingStyle="rpc") && (namespace'=typeNamespace) Set forcePrefix=1
	If forcePrefix || (bindingStyle="rpc"),namespaces.GetPrefix(namespace)="" {
		$$$XMLAppendBuffer(" xmlns:tns='"_namespace_"'")
		Do namespaces.AddNamespace(namespace,"tns")
	}
	If forcePrefix || (bodyUse="encoded") || 
	   ((bindingStyle="document")&&('elementQualified||attributeQualified)&&(typeNamespace'="")),
	   namespaces.GetPrefix(typeNamespace)="" {
		$$$XMLAppendBuffer(" xmlns:types='"_typeNamespace_"'")
		Do namespaces.AddNamespace(typeNamespace,"types")
	}
	If ..AddressingOut'="" {
		Set addrNamespace=..AddressingOut.Namespace()
		$$$XMLAppendBuffer(" xmlns:wsa='"_addrNamespace_"'")
		Do namespaces.AddNamespace(addrNamespace,"wsa")
	}
	If $isobject(r%SecurityOut) && (r%SecurityOut.SecurityElement.Count()>0) {
		$$$XMLAppendBuffer(" xmlns:wsse='"_$$$SOAPWSSEns_"'")
		Do namespaces.AddNamespace($$$SOAPWSSEns,"wsse")
		$$$XMLAppendBuffer(" xmlns:wsu='"_$$$SOAPWSUns_"'")
		Do namespaces.AddNamespace($$$SOAPWSUns,"wsu")
	} ElseIf namespace=$$$SOAPWSTNS {
		$$$XMLAppendBuffer(" xmlns:wsu='"_$$$SOAPWSUns_"'")
		Do namespaces.AddNamespace($$$SOAPWSUns,"wsu")
	}
	Set ns=""
	For {
		Set ns=namespaces.GetNextDefinedNamespace(ns)
		If ns="" Quit
		$$$XMLAppendBuffer(" xmlns:"_namespaces.GetPrefix(ns)_"='"_ns_"'")
	}
	$$$XMLAppendBuffer(">")
	$$$XMLWriteLine
	Do namespaces.DefineAllNamespacePrefixes()
	Set namespaces.CurrentNamespace=""
	Set namespaces.DefaultNamespace=typeNamespace
	Set namespaces.ElementQualified=elementQualified
	Quit $$$OK
}

/// Output the close of the SOAP envelope
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod EndSOAPEnvelope() [ Internal, ServerOnly = 1 ]
{
	$$$XMLSetBuffer("</"_..#SOAPPREFIX_":Envelope>")
	$$$XMLWriteLine
}

/// Output the SOAP headers
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method WriteSOAPHeaders(bodyUse As %String, namespaces As %XML.Namespaces, mimeAttachments As %Net.MIMEPart) As %Status [ Internal, ServerOnly = 1 ]
{
	Set sc=$$$OK
	Set header=..HeadersOut.Next("")
	Set security=$isobject(r%SecurityOut)
	If (header="") && (..AddressingOut="") && 'security Quit sc
	
	$$$XMLSetBuffer("  <"_..#SOAPPREFIX_":Header>")
	$$$XMLWriteLine
	$$$XMLUseNext
	While header'="" {
		Set typeNamespace=..#TYPENAMESPACE
		If typeNamespace="" Set typeNamespace=..#NAMESPACE
		Set headerObj=..HeadersOut.GetAt(header)
		Set fmt=bodyUse
		If ..ReferencesInline Set fmt=fmt_",inline"
		If ..Base64LineBreaks Set fmt=fmt_",base64linebreaks"
		Set sc=headerObj.WriteHeader(,fmt,typeNamespace,..#ELEMENTQUALIFIED,..#SOAPPREFIX,..SoapVersion,namespaces,mimeAttachments)
		If $$$ISERR(sc) Quit
		$$$XMLUseNext
		Set header=..HeadersOut.Next(header)
	}
	
	// Write WS-Addressing headers
	If ..AddressingOut'="" {
		Set sc=..AddressingOut.WriteSOAPHeaders(namespaces,..#SOAPPREFIX,..SoapVersion)
		If $$$ISERR(sc) Quit sc
	}
	
	// Write WS-Security header
	If security {
		Set sc=r%SecurityOut.WriteSecurityHeader(namespaces,..#SOAPPREFIX,..SoapVersion,mimeAttachments)
		If $$$ISERR(sc) Quit sc
		$$$XMLUseNext
	}
	
	$$$XMLSetBuffer("  </"_..#SOAPPREFIX_":Header>")
	$$$XMLWriteLine

	Quit sc
}

/// Determine if any security processing is required and initialize.
Method InitializeSecurity(Output sc As %Status) As %Boolean [ Internal, ServerOnly = 1 ]
{
	Set sc=$$$OK
	
	#; Initialize any WS-Security operations.
	If $isobject(r%SecurityOut) {
		// wsRequired is true if any signing or encryption is to be done.
		Set wsRequired=r%SecurityOut.Initialize($this,.sc)
	} Else {
		Set wsRequired=0
	}
	
	#; Initialize any custom security headers
	Set headerName=""
	For {
		If $$$ISERR(sc) Quit
		Set header=..HeadersOut.GetNext(.headerName)
		If headerName="" Quit
		If $parameter(header,"CUSTOMSECURITY") {
			If header.Initialize($this,.sc) Set wsRequired=1
		}
	}
	
	Quit wsRequired
}

/// Reset any security headers
Method ResetSecurity() [ Internal, ServerOnly = 1 ]
{
	Set headerName=""
	For {
		Set header=..HeadersOut.GetNext(.headerName)
		If headerName="" Quit
		If $parameter(header,"CUSTOMSECURITY") {
			Do header.Reset()
		}
	}

	If $isobject(r%SecurityOut) do r%SecurityOut.Reset()
}

/// Error check the SOAP envelope and find the message element.
/// If all is OK, status of $$$OK is returned and message is set to the index of message node.
Method CheckSOAPEnvelope(ByRef handler As %XML.Document, oneWay As %Boolean, Output soapenv As %Integer, Output message As %String, Output messageChildlist As %String, ByRef versionMismatch As %Boolean) As %Status [ Final, Internal, ServerOnly = 1 ]
{
	Set message=""
	Set versionMismatch=0
	Set tree=handler.DocumentId

	#; Check SOAP envelope
	Set root=$$$xmlGetDocumentElement(tree)
	$$$xmlaGetChildList(tree,root,rootChildlist,descriptor)
	If ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) || ($$$xmlaGetLocalName(tree,rootChildlist)'="Envelope") {
		Quit $$$ERROR($$$ElementMismatch)
	}

	Set ..SoapVersion=""
	Set soapenv=$$$xmlNamespaceToIndex(tree,$$$SOAPENVns)
	If (soapenv'="") && ($$$xmlaGetNamespaceIndex(tree,rootChildlist)=soapenv) {
		Set ..SoapVersion="1.1"
		Set soapns=$$$SOAPENVns
	} Else {
		Set soapenv=$$$xmlNamespaceToIndex(tree,$$$SOAP12ENVns)
		If (soapenv'="") && ($$$xmlaGetNamespaceIndex(tree,rootChildlist)=soapenv) {
			Set ..SoapVersion="1.2"
			Set soapns=$$$SOAP12ENVns
		}
	}
	If $get(soapns)="" Set soapns="SOAP Envelope namespace"
	If ..SoapVersion="" {
		Set versionMismatch=1
		Quit $$$ERROR($$$VersionError,soapns)
	}
	
	#; Check namespace
	$$$xmlaFirstChildElement(tree,root,rootChildlist,node,descriptor)
	If oneWay && (node="") Quit $$$OK
	If (node="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) {
		Quit $$$ERROR($$$ElementMismatch)
	}
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	#; Process headers
	Set ..AddressingIn=""
	If $$$xmlaGetLocalName(tree,childlist)="Header" {
		If $$$xmlaGetNamespaceIndex(tree,childlist)'=soapenv {
			Quit $$$ERROR($$$VersionError,soapns)
		}

		Set sc=##class(%SOAP.Addressing.Properties).ImportAddressingHeaders(handler,node,childlist,.addressing)
		If $$$ISOK(sc) {
			Set ..AddressingIn=addressing
		} Else {
			Quit sc
		}
		$$$xmlaNextChildElement(tree,root,rootChildlist,node,descriptor)
		$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	}

	#; Process Body
	If (node="") || ($$$xmlaGetLocalName(tree,childlist)'="Body") Quit $$$ERROR($$$SOAPNoBody)
	If $$$xmlaGetNamespaceIndex(tree,childlist)'=soapenv {
		Quit $$$ERROR($$$VersionError,soapns)
	}

	#; Get body element
	$$$xmlaFirstChildElement(tree,node,childlist,message,descriptor)
	If oneWay && (message="") Set messageChildlist="" Quit $$$OK
	If (message="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) {
		Quit $$$ERROR($$$SOAPNoBody)
	}
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,messageChildlist)

	Quit $$$OK
}

/// Process the SOAP envelope.
Method ProcessSOAPEnvelope(ByRef handler As %XML.Document, soapenv As %Integer, ByRef message As %String, ByRef messageChildlist As %String, attachments As %Net.MIMEPart) As %Status [ Final, Internal, ServerOnly = 1 ]
{
	Set tree=handler.DocumentId
	Set root=$$$xmlGetDocumentElement(tree)
	$$$xmlaGetChildList(tree,root,rootChildlist,descriptor)
	Set soapEncoded=..GetEncodedAttribute(tree,root,rootChildlist,soapenv,,.sc)
	If $$$ISERR(sc) Quit sc

	#; Process headers
	$$$xmlaFirstChildElement(tree,root,rootChildlist,node,descriptor)
	If node="" Quit $$$OK
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)

	If $$$xmlaGetLocalName(tree,childlist)="Header" {
		#; Encoding style can appear on ANY attribute
		Set format=$select(soapEncoded||..GetEncodedAttribute(tree,node,childlist,soapenv,,.sc):"encoded",1:"literal")
		If $$$ISERR(sc) Quit sc
		If attachments="" {
			set mimeAttachments=""
		} else {
			Set mimeAttachments=##class(%Net.MIMEPart).%New()
			For i=1:1:attachments.Count() Do mimeAttachments.Parts.Insert(attachments.GetAt(i))
		}
		Set sc=..ProcessHeaders(format,.handler,node,childlist,soapenv,mimeAttachments)
		If $$$ISERR(sc) Quit sc
		// Restore position and message nodeId in case handler changed by decryption.
		Set tree=handler.DocumentId
		Set root=$$$xmlGetDocumentElement(tree)
		$$$xmlaGetChildList(tree,root,rootChildlist,descriptor)
		$$$xmlaFirstChildElement(tree,root,rootChildlist,node,d1)
		$$$xmlaNextChildElement(tree,root,rootChildlist,node,d2)
		$$$xmlaGetChildListFromDescriptor(tree,d2,childlist)
		$$$xmlaFirstChildElement(tree,node,childlist,message,d3)
		$$$xmlaGetChildListFromDescriptor(tree,d3,messageChildlist)
	}

	#; Check for SOAP Fault
	If message'="",$$$xmlaGetLocalName(tree,messageChildlist)="Fault",$$$xmlaGetNamespaceIndex(tree,messageChildlist)=soapenv {
		If ..SoapVersion="1.2" {
			Set fault=##class(%SOAP.Fault12).%New()
			Set sc=fault.XMLImport("","literal","",handler,message)
			If $$$ISOK(sc) {
				Set sc=$$$ERROR($$$SOAPFaultReceived,fault.AsString())
				Set code=fault.Code.Value
				If $length(code,":")=2 Set fault.Code.Value=$piece(code,":",2)
				Set ..SoapFault=fault
			}
		} Else {
			Set fault=##class(%SOAP.Fault).%New()
			Set sc=fault.XMLImport("","literal","",handler,message)
			If $$$ISOK(sc) {
				Set qname=$$$xmlaGetQName(tree,messageChildlist)
				If qname[":" {
					Set soapPrefix=$piece(qname,":",1)_":"
					Set code=fault.faultcode
					If $extract(code,1,$length(soapPrefix))=soapPrefix {
						Set $extract(code,1,$length(soapPrefix))=""
						Set fault.faultcode=code
					}
				}
				Set sc=$$$ERROR($$$SOAPFaultReceived,fault.AsString())
				Set ..SoapFault=fault
			}
		}
		Quit sc
	}

	Quit $$$OK
}

/// Process the SOAP header elements.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessHeaders(format, ByRef handler As %XML.Document, node As %String, childlist As %String, soapenv As %Integer, mimeAttachments As %Net.MIMEPart) As %Status [ Final, Internal, Private, ServerOnly = 1 ]
{
	Set tree=handler.DocumentId
	Set sc=$$$OK
	
	#; Setup header lookup
	#; Always input security and session header
	Set kind=$select(##this.%Extends("%SOAP.WebClient"):"response",1:"request")
	Do ##class(%SOAP.WebParameters).GetHeaders($$$objClass,..MethodName,kind,..SoapHeaders,.headers)

	#; Process Security header for client.  Already done for service.
	If kind="response" {
		#; Loop over headers looking for Security header
		$$$xmlaFirstChildElement(tree,node,childlist,element,descriptor)
		While element'="" {
			If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlWHITESPACENODE {
				#; Check the element
				If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE {
					Set sc=$$$ERROR($$$ElementMismatch)
					Quit
				}
				#; Get the element name
				$$$xmlaGetChildListFromDescriptor(tree,descriptor,elementChildlist)
				Set headerName=$$$xmlaGetLocalName(tree,elementChildlist)
				If headerName="Security" {
					Set headerNamespace=$$$xmlaGetNamespaceURI(tree,elementChildlist)
					#; Check if the associated web service can handle the header
					Set headerElement=$select(headerNamespace="":"",1:$get(headers(headerNamespace,headerName)))
					If headerElement="" Set headerElement=$get(headers($c(0),headerName))
					#; Check that this is the Securityy header
					If headerElement'="",$list(headerElement,1)="%SOAP.Security.Header" {
						If ##class(%SOAP.Policy).PolicyExists($classname(),..PolicyConfiguration) {
							Set securityIn="allow"
						} Else {
							Set securityIn=$zcvt(..#SECURITYIN,"L")
						}
						#; Retrieve the 'actor' attribute from the element
						If ..GetEncodedAttribute(tree,element,elementChildlist,soapenv,.attrs,.sc) Set format="encoded"
						Set actor=""
						If ..SoapVersion="1.2" {
							If $data(attrs("role")) &&
							   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("role"))=soapenv) {
								Set actor=$$$xmlaGetAttribute(tree,attrs("role"))
							}
						} Else {
							If $data(attrs("actor")) &&
							   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("actor"))=soapenv) {
								Set actor=$$$xmlaGetAttribute(tree,attrs("actor"))
							}
						}
						#; Retrieve the 'must' understand attribute from the first element
						Set mustUnderstand=0
						If $data(attrs("mustUnderstand")) &&
						   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("mustUnderstand"))=soapenv) {
							Set mustUnderstand=$$$xmlaGetAttribute(tree,attrs("mustUnderstand"))
							If ..SoapVersion="1.2" {
								If mustUnderstand="false" Set mustUnderstand=0
								If mustUnderstand="true" Set mustUnderstand=1
							}
						}
						#; Use callback to handle the header.
						Set headerObj=##class(%SOAP.Security.Header).%New()
						Set ishdr=headerObj.ImportHeader(headerName,format,.handler,element,.sc,mimeAttachments,securityIn,$this)
						If ishdr,$$$ISOK(sc) {
							Set alias=$listget(headerElement,2,headerName)
							Do ..HeadersIn.SetAt(headerObj,alias)
							Set headerObj.actor=actor
							Set headerObj.mustUnderstand=''mustUnderstand
						}
					}
				}
			}
			$$$xmlaNextChildElement(tree,node,childlist,element,descriptor)
		}
		$$$SOAPTimer("civalid")
	}
	If $$$ISERR(sc) Quit sc
	
	#; Process each header except security header
	$$$xmlaFirstChildElement(tree,node,childlist,element,descriptor)
	While element'="" {
		If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlWHITESPACENODE {
			#; Check the element
			If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE {
				Set sc=$$$ERROR($$$ElementMismatch)
				Quit
			}
			#; Get the element name
			$$$xmlaGetChildListFromDescriptor(tree,descriptor,elementChildlist)
			Set headerName=$$$xmlaGetLocalName(tree,elementChildlist)
			Set headerNamespace=$$$xmlaGetNamespaceURI(tree,elementChildlist)
			#; Get optional encodingStyle
			If ..GetEncodedAttribute(tree,element,elementChildlist,soapenv,.attrs,.sc) Set format="encoded"
			If $$$ISERR(sc) Quit
			#; Retrieve the 'actor' attribute from the element
			Set actor=""
			If ..SoapVersion="1.2" {
				If $data(attrs("role")) &&
				   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("role"))=soapenv) {
					Set actor=$$$xmlaGetAttribute(tree,attrs("role"))
				}
			} Else {
				If $data(attrs("actor")) &&
				   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("actor"))=soapenv) {
					Set actor=$$$xmlaGetAttribute(tree,attrs("actor"))
				}
			}
			#; Retrieve the 'must' understand attribute from the first element
			Set mustUnderstand=0
			If $data(attrs("mustUnderstand")) &&
			   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("mustUnderstand"))=soapenv) {
				Set mustUnderstand=$$$xmlaGetAttribute(tree,attrs("mustUnderstand"))
				If ..SoapVersion="1.2" {
					If mustUnderstand="false" Set mustUnderstand=0
					If mustUnderstand="true" Set mustUnderstand=1
				}
			}
			#; Check if the associated web service can handle the header
			Set headerElement=$select(headerNamespace="":"",1:$get(headers(headerNamespace,headerName)))
			If headerElement="" Set headerElement=$get(headers($c(0),headerName))
			If headerElement'="" {
				Set class=$list(headerElement,1)
				Set alias=$listget(headerElement,2,headerName)
				If class'="%SOAP.Security.Header" {
					#; Use callback to handle the header.
					Set headerObj=$classmethod(class,"%New")
					Set ishdr=headerObj.ImportHeader(headerName,format,handler,element,.sc,mimeAttachments)
					If ishdr {
						If $$$ISERR(sc) Quit
						Do ..HeadersIn.SetAt(headerObj,alias)
						Set headerObj.actor=actor
						Set headerObj.mustUnderstand=''mustUnderstand
					}
				}
			} ElseIf headerNamespace=$$$SOAPWSRMns {
				Set class="%SOAP.RM."_headerName
				Set headerObj=$classmethod(class,"%New")
				Set ishdr=headerObj.ImportHeader(headerName,"literal",handler,element,.sc,mimeAttachments)
				If ishdr {
					If $$$ISERR(sc) Quit
					Do ..HeadersIn.SetAt(headerObj,headerName)
					Set headerObj.actor=actor
					Set headerObj.mustUnderstand=''mustUnderstand
				}
			} ElseIf ##class(%SOAP.Addressing.Properties).IsWSANamespace(headerNamespace) {
				// WS-Addressing headers already processed
			} ElseIf mustUnderstand, (headerName'="Security") || '##class(%SOAP.Security.Header).IsSecurityNamespace(headerNamespace) {
				#; Issue an error if the service can't understand a mandatory header
				Set sc=$$$ERROR($$$HeaderNotSupported,headerName)
				Quit
			}
		}
		$$$xmlaNextChildElement(tree,node,childlist,element,descriptor)
	}

	Quit sc
}

/// See if node in XML document soap encoding attribute
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetEncodedAttribute(tree As %Integer, node As %String, childlist As %String, soapenv As %Integer, ByRef attrs, ByRef status As %Status) As %Boolean [ Final, Internal, Private, ServerOnly = 1 ]
{
	Set status=$$$OK

	kill attrs
	$$$xmlaForEachAttribute(tree,childlist,o,attribute)
		Set attrname=$$$xmlaGetAttributeName(tree,attribute)
		Set attrs(attrname)=attribute
	$$$xmlaEndForEachAttribute(tree,childlist,o,attribute)

	If $get(attrs("encodingStyle"))="" Quit 0
	If $$$xmlaGetAttrNamespaceIndex(tree,attrs("encodingStyle"))'=soapenv Quit 0
	Set style=$$$xmlaGetAttribute(tree,attrs("encodingStyle"))
	If ..SoapVersion="1.2" {
		If style'=$$$SOAP12ENCns Set status=$$$ERROR($$$SOAPBadEncodingStyle,style)
	} Else {
		If style'=$$$SOAPENCns Set status=$$$ERROR($$$SOAPBadEncodingStyle,style)
	}
	Quit $$$ISOK(status)
}

/// Create required descriptor classes.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod OnCompile() [ CodeMode = objectgenerator, Internal, ServerOnly = 1 ]
{
 If %class.Abstract Quit $$$OK

 #; Horrible hack to make backporting easier by keeping %class as the class name
 New %definedclass Set %definedclass=%class
 New %class Set %class=%definedclass.Name

 Kill $$$SOAPParametersNode(%class)
 Set tInitialExpression=""

 Do ##class(%Compiler.XML.Generator.Adaptor).SequenceClass(%class,.tClasses)
 Set tServiceClass=$data(tClasses("%SOAP.WebService"))

 Set sc=$$$OK
 #; Check that user has supplied values for the SERVICENAME parameter
 If $$$comMemberKeyGet(%class,$$$cCLASSparameter,"SERVICENAME",$$$cPARAMdefault)="" {
    Quit $$$ERROR($$$SOAPNoServiceName)
 }
 
 #; Verify the SECURITYIN parameter
 Set securityIn=$zcvt($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SECURITYIN",$$$cPARAMdefault),"L")
 If $case(securityIn,"allow":0,"noheader":0,"ignore":0,"ignoreall":0,"require":0,:1) {
	Quit $$$ERROR($$$SOAPInvalidSECURITYIN,securityIn)
 }
 
 #; Get location of the web service.
 If 'tServiceClass {
	Set tLocation=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"LOCATION",$$$cPARAMdefault)
	If (tLocation'="") && $case($zcvt($piece(tLocation,"://"),"L"),"http":0,"https":0,:1) {
		Quit $$$ERROR($$$SOAPHttpOnly) 
	}
 }
 
 #; Verify that the SOAPVERSION is correctly specified.
 Set soapVersion=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"SOAPVERSION",$$$cPARAMdefault)
 If $case(soapVersion,"":0,"1.1":0,"1.2":0,:1) {
	Quit $$$ERROR($$$SOAPUnsupportedVersion,soapVersion) 
 }
 
 #; Verify that the REQUESTVERSION is correctly specified.
 If tServiceClass {
	Set requestVersion=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"REQUESTVERSION",$$$cPARAMdefault)
	If $case(requestVersion,"":0,"1.1":0,"1.2":0,:1) {
		Quit $$$ERROR($$$SOAPUnsupportedRequest,requestVersion) 
	}
 }
 
 #; Verify that the ARGUMENTSTYLE is correctly specified.
 Set argumentStyle=$zcvt($$$comMemberKeyGet(%class,$$$cCLASSparameter,"ARGUMENTSTYLE",$$$cPARAMdefault),"L")
 If $case(argumentStyle,"":0,"message":0,"wrapped":0,:1) {
	Quit $$$ERROR($$$SOAPUnsupportedArgumentStyle,argumentStyle) 
 }
 
 #; Get XML namespace parameters.
 Set tClassNamespace=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
 Set tClassTypeNamespace=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"TYPENAMESPACE",$$$cPARAMdefault)
 Set tClassResponseNamespace=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"RESPONSENAMESPACE",$$$cPARAMdefault)
 Set tClassResponseTypeNamespace=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"RESPONSETYPENAMESPACE",$$$cPARAMdefault)

 Set tImport=$$$comClassKeyGet(%class,$$$cCLASSimport)
 Set tPackage=$$$ClassPackageName(%class)
 If (","_tImport_",")'[(","_tPackage_",") {
    Set tImport=$select(tImport="":"",1:tImport_",")_tPackage
 }
 
 #; Get value of hidden keyword
 Set tClassHidden=$$$comClassKeyGet(%class,$$$cCLASShidden)

 #; Get XMLIGNORENULL parameter to pass along to method classes
 Set tXMLIgnoreNull=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLIGNORENULL",$$$cPARAMdefault)

 #; Get XMLIGNOREINVALIDTAG parameter to pass along to method classes
 Set tXMLIgnoreInvalidTag=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLIGNOREINVALIDTAG",$$$cPARAMdefault)

 #; Get XMLDEFAULTREFERENCE parameter to pass along to method classes
 Set tXMLDefaultReference=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLDEFAULTREFERENCE",$$$cPARAMdefault)
 If tXMLDefaultReference="" Set tXMLDefaultReference="complete"

 Set elementqualified=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"ELEMENTQUALIFIED",$$$cPARAMdefault)
 Set classElement=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLELEMENT",$$$cPARAMdefault)
 Set methodInheritance=(tServiceClass && $$$comMemberKeyGet(%class,$$$cCLASSparameter,"SOAPMETHODINHERITANCE",$$$cPARAMdefault))

 #; Walk through the methods and count the webmethods and record name
 Set (tWebMethods,tGenLiteralSchema,tGenEncodedSchema)=0
 Set tMethod=$$$comMemberNext(%class,$$$cCLASSmethod,"")
 While tMethod'="" {
	If methodInheritance {
		Set iswebmethod=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHwebmethod)
	} Else {
		Set iswebmethod=$$$defMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHwebmethod)
	}
    If iswebmethod {
        Set tWebMethods($Increment(tWebMethods))=tMethod
        Set webMethodIndex(tMethod)=tWebMethods
        Set tIsQuery(tWebMethods)=0
	    Set tBodyUse(tWebMethods)=$zcvt($$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoapbodyuse),"L")
	    If tBodyUse(tWebMethods)="literal" {
			Set tGenLiteralSchema=1
	    } Else {
			Set tGenEncodedSchema=1
	    }
    }
    Set tMethod=$$$comMemberNext(%class,$$$cCLASSmethod,tMethod)
 }
 If $$$ISERR(sc) Quit sc

 #; Add webmethod queries to the list for web service
 If tServiceClass {
	 Set tMethod=$$$comMemberNext(%class,$$$cCLASSquery,"")
	 While tMethod'="" {
		If methodInheritance {
			Set iswebmethod=$$$comMemberKeyGet(%class,$$$cCLASSquery,tMethod,$$$cQUERYwebmethod)
		} Else {
			Set iswebmethod=$$$defMemberKeyGet(%class,$$$cCLASSquery,tMethod,$$$cQUERYwebmethod)
		}
	    If iswebmethod {
		    If $data(webMethodIndex(tMethod)) {
			    Set sc=$$$ERROR($$$SOAPDuplicateMethod,tMethod)
			    Quit
			}
	        Set tWebMethods($Increment(tWebMethods))=tMethod
        	Set webMethodIndex(tMethod)=tWebMethods
	        Set tIsQuery(tWebMethods)=1
		    Set tBodyUse(tWebMethods)=$zcvt($$$comMemberKeyGet(%class,$$$cCLASSquery,tMethod,$$$cQUERYsoapbodyuse),"L")
		    If tBodyUse(tWebMethods)="literal" {
				Set tGenLiteralSchema=1
		    } Else {
				Set tGenEncodedSchema=1
		    }
	    }
	    Set tMethod=$$$comMemberNext(%class,$$$cCLASSquery,tMethod)
	 }
	 If $$$ISERR(sc) Quit sc
 }

 #; For each web method, GENERATE the message descriptor class
 For tI=1:1:tWebMethods {
 	Set propseq=20  // Start at 20 to be after the parameters.
    Set tMethod=tWebMethods(tI)
	#; Validate SoapBindingStyle and SoapBodyUse
    If tIsQuery(tI) {
	    #; Property keywords are not yet implemented for queries
	    Set tBindingStyle=$zcvt($$$comMemberKeyGet(%class,$$$cCLASSquery,tMethod,$$$cQUERYsoapbindingstyle),"L")
	    Set tBodyUse(tI)=$$$comMemberKeyGet(%class,$$$cCLASSquery,tMethod,$$$cQUERYsoapbodyuse)
		If tBodyUse(tI)'="literal" Set sc=$$$ERROR($$$SoapBodyUseError,tBodyUse(tI),tMethod) Quit
	    Set tNamespace=$$$comMemberKeyGet(%class,$$$cCLASSquery,tMethod,$$$cQUERYsoapnamespace)
	    Set tTypeNamespace=""
	    Set tClassMethod=0
	    Set tSoapMessageName=""
	    Set tSoapAction="[default]"
		Set requestMessage=""
	    Set bare=0
    } Else {
	    Set tBindingStyle=$zcvt($$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoapbindingstyle),"L")
	    Set tBodyUse(tI)=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoapbodyuse)
		If $case(tBodyUse(tI),"literal":0,"encoded":0,:1) Set sc=$$$ERROR($$$SoapBodyUseError,tBodyUse(tI),tMethod) Quit
	    Set tNamespace=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoapnamespace)
	    Set tTypeNamespace=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoaptypenamespace)
	    Set tClassMethod=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHclassmethod)
	    Set tSoapMessageName=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoapmessagename)
	    Set tSoapAction=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoapaction)
		Set requestMessage=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHsoaprequestmessage)
	    Set bare=((tBindingStyle="document") && (argumentStyle="message"))
    }
    
	If $case(tBindingStyle,"document":0,"rpc":0,:1) Set sc=$$$ERROR($$$SoapBindingStyleError,tBindingStyle,tMethod) Quit

	If tServiceClass {
	    If tSoapAction'="[default]" {
		    If tSoapAction="" Set tSoapAction=$c(0)
		    Set soapActionIndex(tSoapAction)=$get(soapActionIndex(tSoapAction))_$lb(tMethod)
	    }
	    If requestMessage'="" {
		    Set requestNameIndex(requestMessage)=$get(requestNameIndex(requestMessage))_$lb(tMethod)
	    }
	} Else {
		If tSoapMessageName'="" {
			Set sc=$$$ERROR($$$ServiceMessageName,tMethod)
			Quit
		}
		If tSoapAction'="[default]" {
			Set sc=$$$ERROR($$$ServiceAction,tMethod)
			Quit
		}
	}

    If tTypeNamespace="" {
	    Set tTypeNamespace=$select(tClassTypeNamespace'="":tClassTypeNamespace,1:$select(tNamespace'="":tNamespace,1:tClassNamespace))
    }
    If tServiceClass && tGenLiteralSchema && tGenEncodedSchema && (tBodyUse(tI)'="literal") {
	    	If $extract(tTypeNamespace,*)'="/" {
		    	Set tTypeNamespace=tTypeNamespace_"/"
	    	}
			Set tTypeNamespace=tTypeNamespace_"encodedTypes"
	    }
	Set (tMethodExportNamespace,tMethodImportNamespace)=$select(tNamespace'="":tNamespace,1:$select((tBindingStyle="document")&&(tBodyUse(tI)="encoded"):tTypeNamespace,1:tClassNamespace))
	If tClassResponseNamespace'="" {
		If tServiceClass {
			Set tMethodExportNamespace=tClassResponseNamespace
		} Else {
			Set tMethodImportNamespace=tClassResponseNamespace
		}
	}
	Set (tMethodExportTypeNamespace,tMethodImportTypeNamespace)=tTypeNamespace
	If tClassResponseTypeNamespace'="" {
		If tServiceClass {
			Set tMethodExportTypeNamespace=tClassResponseTypeNamespace
		} Else {
			Set tMethodImportTypeNamespace=tClassResponseTypeNamespace
		}
	}

    Set tClassDefName=%class_"."_tMethod

    #; Delete any pre-existing definition
    If $$$defClassDefined(tClassDefName) {
        Set sc=$$Delete^%apiOBJ(tClassDefName,"-d") If $$$ISERR(sc) Quit
    }

    #; Create a new class definition
    Set tClassDef=##class(%Dictionary.ClassDefinition).%New(tClassDefName)
    If tClassDef=$$$NULLOREF Set sc=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition") Quit
    Set tClassDef.IncludeCode="%occInclude,%soap"
    Set tClassDef.Super=$select(tServiceClass:"%SOAP.MsgDescriptor",1:"%SOAP.ProxyDescriptor")
    Set tClassDef.Import=tImport
    Set tClassDef.Description="This class is generated by the "_%class_" Web Service"_$select(tServiceClass:"",1:" Client")_" class."_$c(13,10)_"This class should not be edited or modified in any way."
    If tClassHidden Set tClassDef.Hidden=1
	#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
	Set tClassDef.ClassVersion=25

    #; Get signature for method or query.
    If tIsQuery(tI) {
	    Set tReturnType=tClassDefName_".DS"
		Set tReturnTypeParams=""
		Set tFormalSpec=$$$comMemberKeyGet(%class,$$$cCLASSquery,tMethod,$$$cQUERYformalspec)
    } Else {
		Set tReturnType=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHreturntype)
		Set tReturnTypeParams=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHreturntypeparams)
		Set tFormalSpec=$$$comMemberKeyGet(%class,$$$cCLASSmethod,tMethod,$$$cMETHformalspec)
    }
    
	#; Parse formal arguments.
    Set sc=$$parseFormal^%occName("Method",tMethod,tFormalSpec,.tFormalArgs)
    If $$$ISERR(sc) Quit
    
    #; If ARGUMENTSTYLE="MESSAGE" and a single argument with no type,
    #; then we need to ignore ARGUMENTSTYLE for this method.
    #; The point is to deal with the case of empty element being the only input parameter.
	if bare,(tFormalArgs=1),$get(tFormalArgs(1,2))="" {
		Set bare=0
	}
    
	Set elementref=0
	If (classElement || ((classElement="") && (tBodyUse(tI)="literal"))) {
		If tBindingStyle="rpc" {
			If tMethodExportNamespace=tTypeNamespace {
				Set elementref=$lb("","")
			} Else {
				Set elementref=$lb(tTypeNamespace,$select(elementqualified="":(tBodyUse(tI)="literal"),1:elementqualified))
			}
		} ElseIf bare {
			Set elementref=$lb("","")
		}
	} ElseIf bare {
		Set elementref=$lb(tMethodImportNamespace,$select(elementqualified="":(tBodyUse(tI)="literal"),1:elementqualified))
	}

    #; Generate %ResponseName property if a value is specified
    If tSoapMessageName'="" {
		Kill propParms
		Set propParms("XMLPROJECTION")="NONE"
		Set sc=$$CreateProperty(tClassDef,tClassDefName,"%ResponseName","%String","",.propParms,.propseq,"",""""_tSoapMessageName_"""","",0)
		If $$$ISERR(sc) Quit
    }

    #; Generate the property corresponding to return value
    Set tResultName=""
    Set SoapOneWay=0
    If tReturnType="%SOAP.OneWay" {
    	Set SoapOneWay=1
	    Set tReturnType=""
    }
    If tReturnType'="" {
        #; Make pseudo spec for return type and parse
        Set tResultName="%Result"
        Set tReturnSpec="*"_tResultName_":"_tReturnType
        Set tReturnSpec=tReturnSpec_"("_tReturnTypeParams
        If tReturnSpec'["XMLNAME=" {
	        If tReturnTypeParams'="" Set tReturnSpec=tReturnSpec_","
	        Set tReturnSpec=tReturnSpec_"XMLNAME="""_tMethod_$select(bare:"Response",1:"Result")_""""
        }
        Set tReturnSpec=tReturnSpec_")"
        Set sc=$$parseFormal^%occName("Method return type",tMethod,tReturnSpec,.tReturnArgs)
        If $$$ISERR(sc) Quit
        If tReturnArgs'=1 {
	        Set sc=$$$ERROR($$$FormalSpecFormatInvalid,"Method return type",tMethod,"<Return Type>")
	        Quit
        }

	    #; SOAP 1.2 rpc:result element.
	    #; Note that even if the service is specified as SOAP 1.1, 
	    #; it will respond to a SOAP 1.2 request.
        If tBindingStyle="rpc" {
	        If tServiceClass {
		        Set tXMLIO="OUT"
		        If elementref=0 {
		        	Set initval=$get(tReturnArgs(1,2,"XMLNAME"))
		        } Else {
		        	Set initval="""types:"_$extract($get(tReturnArgs(1,2,"XMLNAME")),2,*)
		        }
	        } Else {
		        Set tXMLIO="IN"
		        Set initval=""
	        }
	        Kill propParms
			Set propParms("MAXLEN")=""
			Set propParms("XMLNAME")="result"
			Set propParms("XMLPROJECTION")="XELEMENT"
			Set ref=$lb($$$SOAP12RPC,1)
			Set sc=$$CreateProperty(tClassDef,tClassDefName,"%result12","%Library.String","",.propParms,.propseq,tXMLIO,initval,0,ref)
        }

        #; Create the result property
		Set required=$get(tReturnArgs(1,2,"REQUIRED"))
		Set sc=$$Argument(.tReturnArgs,1,tServiceClass,elementref,$select(tServiceClass:(required=""),1:''required))
        If $$$ISERR(sc) Quit
    }

    #; Initialize for building parameter lists.
    Set (tMarshall,tParams,tOutParams,tResetParams)=""

    #; Generate the properties corresponding to each argument
    For tP=1:1:tFormalArgs { 
		Set sc=$$Argument(.tFormalArgs,tP,tServiceClass,elementref,0)
        If $$$ISERR(sc) Quit

        #; Build parameter lists.
        If tServiceClass {
            Set tParams=tParams_"."_tName_","
        } Else {
            If $extract(tName)="%" Set sc=$$$ERROR($$$SOAPClientNoPercent,tName) Quit
            If tXMLIO["OUT" {
               	Set tMarshall=tMarshall_".."_tName_"=$get("_tName_"),"
            }
            If tXMLIO["IN" {
                Set tOutParams=tOutParams_tName_"=.."_tName_","
            }
            If tXMLIO="INOUT" {
                Set tResetParams=tResetParams_".."_tName_"="""","
            }
        }
    }
    If $$$ISERR(sc) Quit

#define wl(%line) Do tMethodDef.Implementation.WriteLine(%line)

    #; If Web Client, create the Invoke and Reset methods
    Set seqNumber=0
    If 'tServiceClass {
        Set $Extract(tMarshall,$Length(tMarshall))=""
        Set $Extract(tOutParams,$Length(tOutParams))=""
        Set $Extract(tResetParams,$Length(tResetParams))=""
        Set tMethodDef=##class(%Dictionary.MethodDefinition).%New(tClassDefName_":Invoke")
        If tMethodDef="" Set sc=$$$ERROR($$$CannotCreateObject,"%Dictionary.MethodDefinition") Quit
        Set tMethodDef.ServerOnly=1
        Set tMethodDef.FormalSpec=$select(tClassMethod:"",1:"%Client,")_
                                  "%Action"_
                                  $select(tFormalSpec="":"",1:","_tFormalSpec)_
                                  $select(tClassMethod:",%Location",1:"")
        If tReturnType'="" {
	        Set tMethodDef.ReturnType=tReturnType
			Set tMethodDef.ReturnTypeParams=tReturnTypeParams
        }
        If tMarshall'="" $$$wl(" Set "_tMarshall)
        If tClassMethod {
        	$$$wl(" New %Client Set %Client=##class("_%class_").%New()")
        	$$$wl(" If $get(%Location)'="""" Set %Client.Location=%Location")
        }
        $$$wl(" Do %Client.InvokeClient($this,"""_tMethod_""",%Action"_$select(SoapOneWay:",1",1:"")_")")
        If tOutParams'="" $$$wl(" Set "_tOutParams)
        If tReturnType'="" {
            $$$wl(" Quit .."_tResultName)
        } Else {
            $$$wl(" Quit")
        }
		Set tMethodDef.SequenceNumber=$increment(seqNumber)
	    Set sc=tClassDef.Methods.Insert(tMethodDef)
        If $$$ISERR(sc) Quit

        Set tMethodDef=##class(%Dictionary.MethodDefinition).%New(tClassDefName_":Reset")
        If tMethodDef="" Set sc=$$$ERROR($$$CannotCreateObject,"%Dictionary.MethodDefinition") Quit
        Set tMethodDef.ServerOnly=1
        Set tMethodDef.FormalSpec=""
        Set tMethodDef.ReturnType=""
        If tResetParams'="" $$$wl(" Set "_tResetParams)
        $$$wl(" Quit")
		Set tMethodDef.SequenceNumber=$increment(seqNumber)
	    Set sc=tClassDef.Methods.Insert(tMethodDef)
        If $$$ISERR(sc) Quit
    }

    #; If Query, create the method to return the associated dataset
    If tIsQuery(tI) {
        Set $Extract(tParams,$Length(tParams))=""
        Set tMethodDef=##class(%Dictionary.MethodDefinition).%New(tClassDefName_":"_tMethod)
        If tMethodDef=$$$NULLOREF Set sc=$$$ERROR($$$CannotCreateObject,"%Dictionary.MethodDefinition") Quit
        Set tMethodDef.ProcedureBlock=1
        Set tMethodDef.ClassMethod=1
        Set tMethodDef.FormalSpec=tFormalSpec
        Set tMethodDef.ReturnType=tClassDefName_".DS"
        $$$wl(" Set result=##class("_tClassDefName_".DS).%New()")
        $$$wl(" Do result.SetArgs("_tParams_")")
        $$$wl(" Quit result")
		Set tMethodDef.SequenceNumber=$increment(seqNumber)
		Set sc=tClassDef.Methods.Insert(tMethodDef)
        If $$$ISERR(sc) Quit
    }

    #; Create the Parameters
	If tBindingStyle="rpc" {
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"ELEMENTQUALIFIED",0)
    	If $$$ISERR(sc) Quit
	} Else {
		Set eq=$select(elementqualified="":(tBodyUse(tI)="literal"),1:elementqualified)
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"ELEMENTQUALIFIED",eq)
    	If $$$ISERR(sc) Quit
	}

    Set tPValue=$select(tBindingStyle="rpc":tMethodExportNamespace,1:tMethodExportTypeNamespace)
	Set sc=$$CreateParameter(tClassDef,tClassDefName,"NAMESPACE",tPValue)
    If $$$ISERR(sc) Quit

	Set sc=$$CreateParameter(tClassDef,tClassDefName,"SOAPBINDINGSTYLE",tBindingStyle)
    If $$$ISERR(sc) Quit

	Set sc=$$CreateParameter(tClassDef,tClassDefName,"SOAPBODYUSE",tBodyUse(tI))
    If $$$ISERR(sc) Quit

	If tIsQuery(tI) {
		#; Method will be in descriptor class for queries
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"SOAPCLASSNAME",tClassDefName)
    	If $$$ISERR(sc) Quit
	}

	If SoapOneWay {
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"SOAPONEWAY",1)
		If $$$ISERR(sc) Quit
	}

	Set sc=$$CreateParameter(tClassDef,tClassDefName,"SUPPRESSDOCUMENTATION",1)
	If $$$ISERR(sc) Quit
	
	Set sc=$$CreateParameter(tClassDef,tClassDefName,"TYPENAMESPACE",tTypeNamespace)
    If $$$ISERR(sc) Quit

    Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLDEFAULTREFERENCE",tXMLDefaultReference)
    If $$$ISERR(sc) Quit

	If classElement'="" {
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLELEMENT",classElement)
    	If $$$ISERR(sc) Quit
	}

    If tXMLIgnoreInvalidTag {
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLIGNOREINVALIDTAG",tXMLIgnoreInvalidTag)
        If $$$ISERR(sc) Quit
    }

    If tXMLIgnoreNull'="" {
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLIGNORENULL",tXMLIgnoreNull)
        If $$$ISERR(sc) Quit
    }

    Set tPValue=$select(tBindingStyle="rpc":tMethodImportNamespace,1:tMethodImportTypeNamespace)
	Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLIMPORTNAMESPACE",tPValue)
    If $$$ISERR(sc) Quit

	If bare {
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLMAPPING","sequence")
	    If $$$ISERR(sc) Quit
	}

	Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLRESULTNAME",tResultName)
	If $$$ISERR(sc) Quit
	
    #; Mark this class for deletion when the web class is deleted.
	Set tClassDef.GeneratedBy=%class_".cls"

    Set sc = tClassDef.%Save() If $$$ISERR(sc) Quit

    #; Now queue the generated class for compilation
    Do QueueClass^%occCompile(tClassDefName)
    $$$comClassArraySet(%class,$$$cCLASSclasses,tClassDefName_".CLS","")

    #; If Query, create dataset class
    If tIsQuery(tI) {
	    Set tClassDefName=tClassDefName_".DS"

	    #; Delete any pre-existing definition
	    If $$$defClassDefined(tClassDefName) {
	        Set sc=$$Delete^%apiOBJ(tClassDefName,"-d") If $$$ISERR(sc) Quit
	    }

	    Set tClassDef=##class(%Dictionary.ClassDefinition).%New(tClassDefName)
	    If tClassDef=$$$NULLOREF Set sc=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition") Quit
	    Set tClassDef.Super="%XML.DataSet"
	    If tClassHidden Set tClassDef.Hidden=1
		#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
		Set tClassDef.ClassVersion=25
		Set seqNumber=0

		Set sc=$$CreateParameter(tClassDef,tClassDefName,"CLASSNAME",%class)
    	If $$$ISERR(sc) Quit

	    Set tPValue=tTypeNamespace
	    If $extract(tPValue,$length(tPValue))'="/" Set tPValue=tPValue_"/"
	    Set tPValue=tPValue_tMethod_"_DataSet"
		Set sc=$$CreateParameter(tClassDef,tClassDefName,"NAMESPACE",tPValue)
    	If $$$ISERR(sc) Quit

		Set sc=$$CreateParameter(tClassDef,tClassDefName,"QUERYNAME",tMethod)
    	If $$$ISERR(sc) Quit

	    If tXMLIgnoreNull'="" {
			Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLIGNORENULL",tXMLIgnoreNull)
	        If $$$ISERR(sc) Quit
	    }

		Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLNAME",tMethod_"_DataSet")
    	If $$$ISERR(sc) Quit

		Set sc=$$CreateParameter(tClassDef,tClassDefName,"XMLTYPE",tMethod_"_DataSet")
    	If $$$ISERR(sc) Quit

	    #; Mark this class for deletion when the web class is deleted.
		Set tClassDef.GeneratedBy=%class_".cls"

	    Set sc = tClassDef.%Save() If $$$ISERR(sc) Quit

	    #; Now queue the generated class for compilation
	    Do QueueClass^%occCompile(tClassDefName)
	    $$$comClassArraySet(%class,$$$cCLASSclasses,tClassDefName_".CLS","")
    }
 }
 
 #; Parse and save parameters XData block
 #; Also save parameter indices produced in this method
 If $$$ISOK(sc) {
	Set sc=##class(%SOAP.WebParameters).ParseParameters(%compiledclass,methodInheritance,.webMethodIndex,.soapActionIndex,.requestNameIndex,.parameters)
 }
 If $$$ISOK(sc) {
	Merge $$$SOAPParametersNode(%class)=parameters
 }
 
 Quit sc

#; Create property for an argument from formap spec or return t
Argument(FormalArgs,index,ServiceClass,elementref,forceRequired)
 #; Just use the unique part of the argument name
 Set tName=$extract(FormalArgs(index),1,$$$MAXVARIABLELENGTH)
 Set type=$get(FormalArgs(index,2))
 Set tCollection=""
 Kill propParms
 If type'="" {
	Set normtype=$$$NormalizeClassname(type)
	If (normtype="%Library.ListOfObjects") || (normtype="%Library.ListOfDataTypes") {
		Set eltype=$get(FormalArgs(index,2,"ELEMENTTYPE"))
		If eltype'="" {
			Set type=$extract(eltype,2,*-1)
			Kill FormalArgs(index,2,"ELEMENTTYPE")
			Set tCollection="list"
		}
	} ElseIf (normtype="%Library.ArrayOfObjects") || (normtype="%Library.ArrayOfDataTypes") {
		Set eltype=$get(FormalArgs(index,2,"ELEMENTTYPE"))
		If eltype'="" {
			Set type=$extract(eltype,2,*-1)
			Kill FormalArgs(index,2,"ELEMENTTYPE")
			Set tCollection="array"
		}
	} ElseIf (normtype="%Library.CharacterStream") {
		Set type="%Library.GlobalCharacterStream"
	} ElseIf (normtype="%Library.BinaryStream") {
		Set type="%Library.GlobalBinaryStream"
	}
	Set sc=$$NormalizeClassnameByCom^%occName(.tType,type,%class)
	If $$$ISERR(sc) Quit sc
 } Else {
	Set tType="%Library.String"
 }
 #; Set XMLIO parameter for property
 If $get(FormalArgs(index,1))="&" {
	Set tXMLIO="INOUT"
 } ElseIf $get(FormalArgs(index,1))="*" {
	Set tXMLIO=$select(ServiceClass:"OUT",1:"IN")
 } Else {
	Set tXMLIO=$select(ServiceClass:"IN",1:"OUT")
 }
 If forceRequired {
	#; Return property of service is always required.
	Set required=1
 } Else {
	#; Process REQUIRED parameter for input arguments of web service
	Set required=$get(FormalArgs(index,2,"REQUIRED"))
	If required'="" {
		Set required=''required
	}
 }
 Kill FormalArgs(index,2,"REQUIRED")
 #; Add MAXLEN="" for strings
 Merge propParms=FormalArgs(index,2)
 If ((tType="%Library.String") || (tType="%xsd.string")) && ('$data(propParms("MAXLEN"))) {
	 Set propParms("MAXLEN")=""
 }
 #; If property name shortened to < 31 characters, then add XMLNAME
 If tName'=FormalArgs(index) {
	 Set propParms("XMLNAME")=FormalArgs(index)
 }
 #; Create a property for this argument of the specfied type
 Set sc=$$CreateProperty(tClassDef,tClassDefName,tName,tType,tCollection,.propParms,.propseq,tXMLIO,"",required,elementref)
 Quit sc

#; Create a property for the specified name
CreateProperty(ClassDef, ClassDefName, Name, Type, Collection, propParms, propseq, XMLIO, InitialExpression, required, elementref)
 Set PropDef=##class(%Dictionary.PropertyDefinition).%New(ClassDefName_":"_Name)
 If PropDef=$$$NULLOREF Quit $$$ERROR($$$CannotCreateObject,"%Dictionary.PropertyDefinition")
 Set PropDef.Type=Type
 Set PropDef.Collection = Collection
 Set PropDef.SequenceNumber=$increment(propseq)
 If $get(InitialExpression)'="" Set PropDef.InitialExpression=InitialExpression
 If $get(XMLIO)'="" Do PropDef.Parameters.SetAt(XMLIO,"XMLIO")
 Set parm=$order(propParms(""))
 While parm'="" {
	Set value=propParms(parm)
	If $extract(value)="""" Set value=$extract(value,2,*-1)
	Do PropDef.Parameters.SetAt(value,parm)
	Set parm=$order(propParms(parm))
 }
 If (elementref'=0) && (PropDef.Parameters.GetAt("XMLREF")="") && (PropDef.Parameters.GetAt("XMLELEMENTREF")="") {
	Do PropDef.Parameters.SetAt(1,"XMLREF")
	If $list(elementref,1)="" {
		Do PropDef.Parameters.RemoveAt("REFNAMESPACE")
	} Else {
		Do PropDef.Parameters.SetAt($list(elementref,1),"REFNAMESPACE")
	}
	If $list(elementref,2)="" {
		Do PropDef.Parameters.RemoveAt("REFELEMENTQUALIFIED")
	} Else {
		Do PropDef.Parameters.SetAt($list(elementref,2),"REFELEMENTQUALIFIED")
	}
 }
 If required'="" Set PropDef.Required=required
 Quit ClassDef.Properties.Insert(PropDef)

#; Create a parameter of the specified name with the specified value
CreateParameter(ClassDef, ClassDefName, PName, PValue)
 Set ParamDef=##class(%Dictionary.ParameterDefinition).%New(ClassDefName_":"_PName)
 If ParamDef=$$$NULLOREF Quit $$$ERROR($$$CannotCreateObject,"%Dictionary.ParameterDefinition")
 Set ParamDef.SequenceNumber=$increment(seqNumber)
 Set ParamDef.Default=PValue
 Quit ClassDef.Parameters.Insert(ParamDef)
}

/// Create an instance of the %SOAP.Descriptor subclass.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod WebMethod(Operation As %String, RequestTag As %String) As %SOAP.Descriptor [ Internal, ServerOnly = 1 ]
{
	#; Instantiate a message descriptor class for this web method.
	 Quit $zobjclassmethod($classname()_"."_..NormalizeName(Operation,$$$MAXNAMELENGTH,1),"%New",$get(RequestTag,Operation))
}

/// Normalize name to comply with ObjectScript naming constraints
ClassMethod NormalizeName(pName, pMaxLen, isMethod As %Boolean) As %String [ ServerOnly = 1 ]
{
 	#; Default MaxLen if necessary
 	Set pMaxLen=$Get(pMaxLen,$$$MAXVARIABLELENGTH)

 	#; Cache does not allow underscores (or spaces) in a name
 	Set pName=$Translate(pName,"_- +"_$select($get(isMethod):".",1:""),"")


 	#; If period delimited part of name starts with a digit, then subsitute the word for the digit
 	For i=1:1:$Length(pName,".") {
	 	Set part=$Piece(pName,".",i)
	 	If $Extract(part,1)?1N  {
	 		Set pPrefix=$Case(+$Extract(part),0:"zero",1:"one",2:"two",3:"three",4:"four",5:"five",6:"six",7:"seven",8:"eight",9:"nine")
	 		Set part=pPrefix_$Extract(part,2,*)
	 		Set $Piece(pName,".",i)=part
	 	}
 	}

	#; Contract name over MaxLen characters in length by
	#; removing vowels from the end of the name
	#; until the size constraint is satisfied
 	If $Length(pName)>pMaxLen {
 		Set tVowelCount=0,tLen=$Length(pName)
 		For tI=tLen:-1:1  { 
 			If "AEIOUaeiou"[$Extract(pName,tI) Set $Extract(pName,tI)="+",tVowelCount=tVowelCount+1
 			If tLen-tVowelCount=pMaxLen  Quit
 		}
 	}
 	Set pName=$Translate(pName,"+","")

 	Quit $extract(pName,1,pMaxLen)
}

Method GetBinaryWriter(msgClass As %SOAP.Descriptor, isRequest As %Boolean, asUTF8 As %Boolean, sessionFlag As %Boolean) As %SOAP.Binary [ Internal, ServerOnly = 1 ]
{
	Set messageList=1,messageList(1)=msgClass

	Set header=..HeadersOut.Next("")
	While header'="" {
		Set messageList($increment(messageList))=..HeadersOut.GetAt(header)
		Set header=..HeadersOut.Next(header)
	}
	
	Set binwriter=##class(%SOAP.Binary).%New()
	Do binwriter.SetupBinaryWriter(.messageList,isRequest,..#SERVICENAME,asUTF8,.sessionFlag)
	Set binwriter.Chunked=isRequest
	Quit binwriter
}

Method ReadBinaryMessage(msgClass As %SOAP.Descriptor, ByRef asUTF8 As %Boolean, ByRef sessionFlag As %Boolean, messageStream) As %Status [ Internal, ServerOnly = 1 ]
{
	Set messageList=1,messageList(1)=msgClass
	Set sc=##class(%SOAP.Binary).ReadMessage(.messageList,.asUTF8,.sessionFlag,messageStream)
	
	#; Setup header lookup
	#; Always input security and session header
	Set ..AddressingIn=""
	Do ..HeadersIn.Clear()
	Set kind=$select(##this.%Extends("%SOAP.WebClient"):"response",1:"request")
	Do ##class(%SOAP.WebParameters).GetHeadersByClass($$$objClass,..MethodName,kind,..SoapHeaders,.headers)

	#; skip the message body
	Set headerIndex=$order(messageList(1))

	#; Get header classes
	While headerIndex'="" {
		Set header=messageList(headerIndex)
		Set headerClass=$zobjclass(header)
		If header.mustUnderstand="" Set header.mustUnderstand=0
		if $data(headers(headerClass)) {
			Do ..HeadersIn.SetAt(header,headers(headerClass))
		} ElseIf header.mustUnderstand {
			Set sc=$$$ERROR($$$HeaderNotSupported,headerClass)
			Quit
		}
		Set headerIndex=$order(messageList(headerIndex))
	}
	
	If $$$GETERRORCODE(sc)=$$$ERRORCODE($$$SOAPFaultReceived) {
		Set ..SoapFault=messageList(1)
	}
	
	Quit sc
}

}
