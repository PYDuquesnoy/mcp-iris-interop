/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %soap, %Net.WebSocket)

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.HttpRequest">Sending HTTP Requests</a>.</p>
/// %Net.HttpRequest provides an interface to issue HTTP requests to a web server and read the response.
/// This allows you to interact with other web sites, for example you could issue a request to get
/// a stock quote from another site, then parse the information returned to store the stock value
/// in the local database. This implementation is designed to the HTTP/1.1 specification
/// <a href="http://www.w3.org/Protocols/rfc2616/rfc2616.html">RFC 2616</a>.
/// In normal use you create a single %Net.HttpRequest object and use it to issue as many
/// requests as you need to the web server, each %Net.HttpRequest object can be thought of as
/// a single instance of an internet browser.
/// On completion of each request, it returns a <CLASS>%Net.HttpResponse</CLASS>
/// object in the <PROPERTY>HttpResponse</PROPERTY> property. This is used to see the reponse
/// from the web server. Note that when you call <METHOD>Get</METHOD>, <METHOD>Head</METHOD>,
/// <METHOD>Post</METHOD>, or <METHOD>Put</METHOD>, it will automatically <METHOD>Reset</METHOD>
/// the %Net.HttpRequest object ready for another request. For example:
/// <EXAMPLE>
/// Set httprequest=##class(%Net.HttpRequest).%New()
/// Set httprequest.Server="www.intersystems.com"
/// Do httprequest.Get("/")
/// Do httprequest.HttpResponse.OutputToDevice()
/// Do httprequest.Get("/cache/")
/// Do httprequest.HttpResponse.OutputToDevice()
/// </EXAMPLE>
/// In order to send parameters on the URL, i.e. when you see a URL like
/// <pre>
/// http://www.demo.com/page.html?PARAM1=TEST&amp;PARAM2=HELLO
/// </pre>
/// You use the <METHOD>SetParam</METHOD> method to add these parameters one by one. For example
/// to get the index page from Documatic you do:
/// <EXAMPLE>
/// Set httprequest=##class(%Net.HttpRequest).%New()
/// Set httprequest.Port=1972
/// Do httprequest.SetParam("PAGE","INDEX")
/// Do httprequest.Get("/csp/docbook/%CSP.Documatic.cls")
/// Do httprequest.HttpResponse.OutputToDevice()
/// </EXAMPLE>
/// You may also pass the query parameters on the <method>Get</method> call directly too as
/// long as they are correctly escaped.<br>
/// Form data can also be sent with this class. This is done by first inserting the form
/// name/value pairs using the <METHOD>InsertFormData</METHOD>. Then the data is
/// <METHOD>Post</METHOD> to the web server, for example something like:
/// <EXAMPLE>
/// Do httprequest.InsertFormData("element","value")
/// Do httprequest.Post("/cgi-bin/script.CGI")
/// </EXAMPLE>
/// You can specify default values for this class by setting the system wide global
/// ^%SYS("HttpRequest",name)=value which will set the property 'name' to the 'value'
/// as part of the <method>InitHeaders</method> initialization. For namespace specific settings
/// set the ^SYS("HttpRequest",name)=value global, with namespace specific settings taking
/// precedence over global settings.
Class %Net.HttpRequest Extends %RegisteredObject [ ServerOnly = 1, System = 3 ]
{

Method %OnNew(initvalue As %String = "") As %Status [ Internal ]
{
	Do ..InitHeaders("localhost")
	Quit $$$OK
}

Method InitHeaders(server As %String, referer As %String, useragent As %String) As %Status [ Internal ]
{
	If $get(useragent)="" Set useragent="Mozilla/4.0 (compatible; InterSystems IRIS;)"
	Set i%Headers("USER-AGENT")=useragent,i%Headers("USER-AGENT",0)="User-Agent",i%Headers("USER-AGENT",1)=1,i%Headers("USER-AGENT",2)=""
	Set i%Headers("HOST")=server,i%Headers("HOST",0)="Host",i%Headers("HOST",1)=2,i%Headers("HOST",2)=""
	Set i%Headers=3
	If i%AcceptGzip {
		Set i%Headers("ACCEPT-ENCODING")="gzip",i%Headers("ACCEPT-ENCODING",0)="Accept-Encoding",i%Headers("ACCEPT-ENCODING",1)=i%Headers,i%Headers("ACCEPT-ENCODING",2)=""
		Set i%Headers=i%Headers+1
	}
	If $get(referer)'="" {
		Set i%Headers("REFERER")=referer,i%Headers("REFERER",0)="Referer",i%Headers("REFERER",1)=i%Headers,i%Headers("REFERER",2)=""
		Set i%Headers=i%Headers+1
	} Else {
		#; Only set this up on the creation, when resetting the oref for the next request keep existing settings
		Set prop=""
		For {
			Set prop=$order(^%SYS("HttpRequest",prop),1,val) Quit:prop=""
			Set $property($this,prop)=val
		}
		Try {
			Set prop=""
			For {
				Set prop=$order(^SYS("HttpRequest",prop),1,val) Quit:prop=""
				Set $property($this,prop)=val
			}
		} Catch {
			If $zerror'["<PROTECT>" Throw
		}
	}
}

Method CleanUp() As %Status [ Internal, Private ]
{
	If i%Device'="" Close i%Device Set i%Device=""
	#; Cleanup authentication handle
	Do ..ProxyAuthentication.Close()
	Do ..ServerAuthentication.Close()

	Quit $$$OK
}

Method %OnClose() As %Status [ Internal, Private, ServerOnly = 1 ]
{
	Return ..CleanUp()
}

/// Time to first character
Property TTFC As %Float;

/// Time to last character
Property TTLC As %Float;

/// Number of characters sent
Property SentChars As %Integer [ InitialExpression = 0 ];

/// Number of bytes received (not characters)
Property RecChars As %Integer [ InitialExpression = 0 ];

/// Internal structure used to store the collection of headers. This is
/// used so the user can add headers that are not explicitly defined in
/// this class to the request.
Property Headers As %String [ Internal, MultiDimensional, Private ];

/// Add a header to the http request. Most of the normal headers that you may want
/// are covered by properties of this class such as <PROPERTY>Date</PROPERTY> however
/// if you wish to add a non standard header then call this. For example:
/// <EXAMPLE>
/// Do httprequest.SetHeader("MyHeader","Data to display")
/// </EXAMPLE>
/// Note that headers such as Content-Type, Content-Encoding, and Content-Length are
/// part of the entity body rather than the http main headers and as such as forwarded
/// to the <PROPERTY>ContentType</PROPERTY>, <PROPERTY>ContentEncoding</PROPERTY> and
/// trying to set the Content-Length is just ignored as this is a read only property.
/// Also any attempt to set the 'Connection' header is ignored at this request class
/// does not support persistent connections.
Method SetHeader(name As %String, value As %String) As %Status
{
	Set uname=$zconvert(name,"u")
	If $length(uname)>250 Quit $$$ERROR($$$HTTPHeaderLong,name)
	If uname="CONTENTTYPE"||(uname="CONTENT-TYPE") Set ..ContentType=value Quit $$$OK
	If uname="CONTENTENCODING"||(uname="CONTENT-ENCODING") Set ..ContentEncoding=value Quit $$$OK
	#; Read only value, just ignore a set attempt.
	If uname="CONTENTLENGTH"||(uname="CONTENT-LENGTH") Quit $$$ERROR($$$HttpRequestContentLength)
	#; If this is one of default headers then let user totally replace our version of this
	If $data(i%Headers(uname,2)) {
		Set i%Headers(uname)=value,i%Headers(uname,0)=name
	} ElseIf $get(i%Headers(uname))'="" {
		Set i%Headers(uname)=i%Headers(uname)_","_value
	} Else {
		Set i%Headers(uname)=value,i%Headers(uname,0)=name,i%Headers(uname,1)=$increment(i%Headers)
	}
	Quit $$$OK
}

/// Allows you to obtain the current value for any of the Http headers that have
/// been set.
Method GetHeader(name As %String) As %String
{
	If $zconvert(name,"U")="COOKIE",'$data(i%Headers("COOKIE")) Quit ..GetCookiesForHost($get(i%Headers("HOST")),i%Location)
	Quit $get(i%Headers($zconvert(name,"U")))
}

/// Remove a Http header value
Method RemoveHeader(name As %String) As %Status
{
	Kill i%Headers($zconvert(name,"u"))
	Quit $$$OK
}

/// Output the full list of Http headers that will be sent to the machine
/// <PROPERTY>Server</PROPERTY> for the item <PROPERTY>Location</PROPERTY> to the current device.
/// This does not include any entity headers associated with the <PROPERTY>EntityBody</PROPERTY>.
Method OutputHeaders() As %Status
{
	$$$SysLogVar(2,"HttpRequest","[%Net.HttpRequest:OutputHeaders]","InitiateAuthentication="_..InitiateAuthentication_", Username="_..Username_", HTTPVersion="_..HTTPVersion_", hasAuthorizationHeader="_$select($get(i%Headers("AUTHORIZATION"))'="":"true",1:"false")_", hasAuthenticateHandle="_$select(..ServerAuthentication.HasHandle():"true",1:"false")_", CurrentAuthenticationScheme="_ ..ServerAuthentication.CurrentScheme)
	$$$SysLogVar(5,"HttpRequest","[%Net.HttpRequest:OutputHeaders]","AuthorizationHeader="_$get(i%Headers("AUTHORIZATION")))

	#; Create initial authorization headers
	Set sc = ..ProxyAuthentication.CreateInitialHeader()
	Return:$$$ISERR(sc) sc
	Set sc = ..ServerAuthentication.CreateInitialHeader()
	Return:$$$ISERR(sc) sc

	Set sentchars=0
	Set https=$select((i%ProxyServer'="")&&(+(i%ProxyPort)'=0):i%ProxyHTTPS,1:i%Https)
	If https {
		If ..Port'=443 Set i%Headers("HOST")=i%Headers("HOST")_":"_..Port
	} Else {
		If ..Port'=80 Set i%Headers("HOST")=i%Headers("HOST")_":"_..Port
	}
	Set name="" For  Set name=$order(i%Headers(name)) Quit:name=""  Set order(i%Headers(name,1))=name
	Set order="" For {
		Set order=$order(order(order),1,name) Quit:order=""
		Set tmp=i%Headers(name,0)_": "_i%Headers(name)_$char(13,10)
		Write tmp Set sentchars=sentchars+$length(tmp)
	}
	If '$data(i%Headers("COOKIE")) {
		Set cookie=..GetCookiesForHost($get(i%Headers("HOST")),i%Location)
		If cookie'="" Set tmp="Cookie: "_cookie_$char(13,10) Write tmp Set sentchars=sentchars+$length(tmp)
	}
	Set i%Headers("HOST")=$piece(i%Headers("HOST"),":")
	Set i%SentChars=i%SentChars+sentchars
	Quit $$$OK
}

/// Return the full list of Http headers that will be sent to the machine
/// <PROPERTY>Server</PROPERTY> for the item <PROPERTY>Location</PROPERTY>.
/// This does not include any entity headers associated with the <PROPERTY>EntityBody</PROPERTY>.
Method ReturnHeaders() As %String
{
	Set return=""
	Set name="" For  Set name=$order(i%Headers(name)) Quit:name=""  Set order(i%Headers(name,1))=name
	Set order="" For  Set order=$order(order(order),1,name) Quit:order=""  Set return=return_i%Headers(name,0)_": "_i%Headers(name)_$char(13,10)
	If '$data(i%Headers("COOKIE")) {
		Set cookie=..GetCookiesForHost($get(i%Headers("HOST")),i%Location)
		If cookie'="" Set return=return_"Cookie: "_cookie_$char(13,10)
	}
	Quit return
}

/// Sets/get the 'Authorization:' header field in the Http request.<p>
/// A user agent that wishes to authenticate itself with a server--
/// usually, but not necessarily, after receiving a 401 response--may do
/// so by including an Authorization header field with the request. The
/// Authorization field value consists of credentials containing the
/// authentication information of the user agent for the realm of the
/// resource being requested.<p>
/// This class understands the Basic authentication mechanism and if you set
/// the <property>Username</property> and <property>Password</property> properties
/// then it will send this information suitably encoded to the server with
/// each request. Note that Basic authentication is not secure and sends to username
/// and password over the network in just base64 encoded form.
Property Authorization As %String [ Calculated ];

Method AuthorizationGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("AUTHORIZATION"))
}

Method AuthorizationSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("Authorization",value)
}

/// The <property>Username</property> is used to construct the response for SPNEGO or NTLM.
/// If not specfied on Windows, then the current login context will be used for SPNEGO and NTLM.<br/>
/// Previously setting the Username property, as a side-effect, sent a Basic Authorization header to the server.
/// This behavior will only continue for HTTP 1.0 requests.
/// For HTTP 1.1 requests an unsolicited Authorization header will never be sent unless the
/// InitiateAuthentication property is set.</br>
/// If you manually set the <property>Authorization</property> header this property will be ignored.<br>
/// If Username'="" and you do not wish %Net.HttpRequest to initiate authentication as Basic,
/// then InitiateAuthentication must be set to "" (for not initiate) or to the initiate scheme.
Property Username As %Username [ Calculated ];

Method UsernameGet() As %Username [ CodeMode = expression, Internal ]
{
..ServerAuthentication.Username
}

Method UsernameSet(username As %Username) As %Status
{
	Set ..ServerAuthentication.Username = username
	Return $$$OK
}

/// The <property>Password</property> is used to construct the response for SPNEGO or NTLM.
/// If not specfied on Windows, then the current login context will be used for SPNEGO and NTLM.<br/>
/// If you manually set the <property>Authorization</property> header this property will be ignored.
Property Password As %String [ Calculated ];

Method PasswordGet() As %String [ CodeMode = expression, Internal ]
{
..ServerAuthentication.Password
}

Method PasswordSet(password As %String) As %Status
{
	Set ..ServerAuthentication.Password = password
	Return $$$OK
}

/// A client may initiate a connection to the server with an "Authorization" header containing
/// the initial token for the server for a chosen authentication scheme.
/// %Net.HttpRequest is asked to initiate the connection by setting the InitiateAuthentication property
/// to a string which is a single scheme name. This form will bypass the initial 401 error from
/// the server when the client knows that the server will accept the specified scheme.
/// Supported schemes are Negotiate, NTLM and Basic.
/// The default for InitiateAuthentication is Basic.
/// However, if InitiateAuthentication=Basic and Username="", then InitiateAuthentication will be ignored.
Property InitiateAuthentication As %String [ Calculated ];

Method InitiateAuthenticationGet() As %String [ CodeMode = expression, Internal ]
{
..ServerAuthentication.InitiateAuthentication
}

Method InitiateAuthenticationSet(auth As %String) As %Status
{
	Set ..ServerAuthentication.InitiateAuthentication = auth
	Return $$$OK
}

/// %Net.HttpRequest will attempt to always respond with an Authorization header with a supported
/// authentication scheme to a 401 status code. The supported authentication schemes
/// are specified by the AuthenticationSchemes property as a comma separated list of case-sensitive
/// authentication schemes.
/// The possible authentication schemes are Negotiate, NTLM and Basic.<br/><br/>
/// 
/// The caller needs to supply Username and Password properties.
/// If the Username  property is not specified on Windows and a 401 status code associated with
/// WWW-Authenticate header for SPNEGO or NTLM is received,
/// then the current login context will be used.<br/><br/>
/// 
/// When responding to a 401 status code, the authentication scheme that is tried is picked
/// from the intersection of those specified by WWW-Authenticate headers in the response
/// and rhe list in the AuthenticationSchemes property.
/// The schemes are checked in the order of the AuthenticationSchemes list.
/// The first scheme which is supported and configured for IRIS will be used to return an
/// Authorization header with that scheme.
/// In order to encourage the user to try more secure schemes first, the default value for
/// Authentication schemes is "Negotiate,NTLM,Basic".
Property AuthenticationSchemes As %String [ Calculated ];

Method AuthenticationSchemesGet() As %String [ CodeMode = expression, Internal ]
{
..ServerAuthentication.Schemes
}

Method AuthenticationSchemesSet(schemes As %String) As %Status [ Internal ]
{
	Set ..ServerAuthentication.Schemes = schemes
	Return $$$OK
}

/// If an attempt to get an authentication handle or token for a scheme fails,
/// then the underlying error is saved to the AuthenticationErrors property.<br/>
/// The value of AuthenticationErrors is a $list which contains the errors.
/// Each entry is of the form:  <scheme> ERROR: <messsage>
Property AuthenticationErrors As %List [ Calculated ];

Method AuthenticationErrorsGet() As %List [ CodeMode = expression, Internal ]
{
..ServerAuthentication.Errors
}

Method AuthenticationErrorsSet(errors As %List) As %Status [ Internal ]
{
	Set ..ServerAuthentication.Errors = errors
	Return $$$OK
}

/// The maximum of authentication round-trips.
Property MaxAuthenticationDepth As %Integer [ Calculated ];

Method MaxAuthenticationDepthGet() As %Integer [ CodeMode = expression, Internal ]
{
..ServerAuthentication.MaxDepth
}

Method MaxAuthenticationDepthSet(depth As %Integer) As %Status [ Internal ]
{
	Set ..ServerAuthentication.MaxDepth = depth
	Return $$$OK
}

/// Sets/get the 'Date:' header field in the HTTP request.<p>
/// The Date general-header field represents the date and time at which
/// the message was originated, having the same semantics as orig-date in
/// RFC 822. The field value is an HTTP-date. A date should only be included
/// if the message contains an entity body and even then it is optional.
/// An example is<p>
/// Date: Tue, 15 Nov 1994 08:12:31 GMT
Property Date As %String [ Calculated ];

Method DateGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("DATE"))
}

Method DateSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("Date",value)
}

/// Internal value to store cache device used for the Http request
Property Device As %String [ Internal, Private ];

/// Internal state of the current device
Property DeviceState As %String [ Internal, Private ];

/// If set to true then this will force the %Net.HttpRequest class to reuse the existing connection
/// to the web server if the socket is already open. If there is any error it will be reported to
/// the caller. This has been introduced to support reliable SOAP messaging, so should not normally
/// be set by other code.
Property ForceReuseDevice As %Boolean [ InitialExpression = 0 ];

/// Internal value to allow us to raise an error on the next socket open call
Property ErrorOnNextOpen As %Boolean [ InitialExpression = 0, Internal, Private ];

/// Internal value to store time when connection was last used
Property TimeLastUsed As %String [ Internal, Private ];

/// When using a 'keep-alive' HTTP connection this is the maximum time we will keep the socket open for in seconds.
/// If the socket is open for longer than this then it may well have been closed by a firewall etc. so we will start
/// a new connection automatically. Set this property to 0 to disable keep-alive persistent HTTP connections.
Property SocketTimeout As %Integer [ InitialExpression = 115 ];

/// When an Entity-Body is included with a message, the data type of that
/// body is determined via the header fields Content-Type and Content-
/// Encoding. These define a two-layer, ordered encoding model.<p>
/// This is a stream so to insert into this stream use:
/// <EXAMPLE>
/// Do oref.EntityBody.Write("Data into stream")
/// </EXAMPLE>
/// See <CLASS>%AbstractStream</CLASS> for more information about streams.
/// Note that setting a new Entity-Body will reset the <property>ContentType</property>,
/// <property>ContentCharset</property> and <property>ContentEncoding</property> as these
/// values are stored in the Entity-Body stream as stream attributes.
Property EntityBody As %GlobalBinaryStream;

/// Internal only property to indicate that special buffering is to be used for SOAP
Property SOAPBuffering As %Boolean [ Internal ];

/// If specified use this local network interface when opening the TCP/IP socket. This becomes
/// the /BINDTO open parameter.
Property LocalInterface As %String;

/// The From request-header field, if given, should contain an Internet
/// e-mail address for the human user who controls the requesting user
/// agent. The address should be machine-usable, as defined by mailbox in
/// RFC 822 [7] (as updated by RFC 1123 [6]):<p>
/// 
/// From = "From" ":" mailbox<p>
/// 
/// An example is:<p>
/// 
/// From: webmaster@w3.org<p>
/// 
/// This header field may be used for logging purposes and as a means for
/// identifying the source of invalid or unwanted requests. It should not
/// be used as an insecure form of access protection. The interpretation
/// of this field is that the request is being performed on behalf of the
/// person given, who accepts responsibility for the method performed. In
/// particular, robot agents should include this header so that the
/// person responsible for running the robot can be contacted if problems
/// occur on the receiving end.<p>
/// 
/// The Internet e-mail address in this field may be separate from the
/// Internet host which issued the request. For example, when a request
/// is passed through a proxy, the original issuer's address should be
/// used.<p>
Property From As %String [ Calculated ];

Method FromGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("FROM"))
}

Method FromSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("From",value)
}

/// The HTTP version we should report to the server when making the request.
/// Defaults to '1.1'.
Property HTTPVersion As %String [ InitialExpression = "1.1" ];

/// The If-Modified-Since request-header field is used with the GET
/// method to make it conditional: if the requested resource has not been
/// modified since the time specified in this field, a copy of the
/// resource will not be returned from the server; instead, a 304 (not
/// modified) response will be returned without any Entity-Body.<p>
/// 
/// If-Modified-Since = "If-Modified-Since" ":" HTTP-date<p>
/// 
/// An example of the field is:<p>
/// 
/// If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT<p>
/// 
/// The purpose of this feature is to allow efficient updates of cached
/// information with a minimum amount of transaction overhead.
Property IfModifiedSince As %String [ Calculated ];

Method IfModifiedSinceGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("IF-MODIFIED-SINCE"))
}

Method IfModifiedSinceSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("If-Modified-Since",value)
}

/// The Pragma general-header field is used to include implementation-
/// specific directives that may apply to any recipient along the
/// request/response chain. All pragma directives specify optional
/// behavior from the viewpoint of the protocol; however, some systems
/// may require that behavior be consistent with the directives.<p>
/// 
/// Pragma = "Pragma" ":" 1#pragma-directive<p>
/// 
/// pragma-directive = "no-cache" | extension-pragma<br>
/// extension-pragma = token [ "=" word ]
Property Pragma As %String [ Calculated ];

Method PragmaGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("PRAGMA"))
}

Method PragmaSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("Pragma",value)
}

/// The Referer request-header field allows the client to specify, for
/// the server's benefit, the address (URI) of the resource from which
/// the Request-URI was obtained. This allows a server to generate lists
/// of back-links to resources for interest, logging, optimized caching,
/// etc. It also allows obsolete or mistyped links to be traced for
/// maintenance. The Referer field must not be sent if the Request-URI
/// was obtained from a source that does not have its own URI, such as
/// input from the user keyboard.<p>
/// 
/// Referer = "Referer" ":" ( absoluteURI | relativeURI )<p>
/// 
/// Example:<p>
/// 
/// Referer: http://www.w3.org/hypertext/DataSources/Overview.html<p>
/// 
/// If a partial URI is given, it should be interpreted relative to the
/// Request-URI. The URI must not include a fragment.<p>
/// 
/// <b>Note:</b> that when you call <METHOD>Reset</METHOD> this
/// field is automatically updated with the last request URI, i.e. <PROPERTY>Location</PROPERTY>.
Property Referer As %String [ Calculated ];

Method RefererGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("REFERER"))
}

Method RefererSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("Referer",value)
}

/// The IP address or machine name of the web server that you wish to
/// connect to. This defaults to 'localhost', i.e. your current machine
/// if not specified. This also sets the 'Host' http header field.
Property Server As %String [ Calculated ];

Method ServerGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("HOST"))
}

Method ServerSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("Host",value)
}

/// The User-Agent request-header field contains information about the
/// user agent originating the request. This is for statistical purposes,
/// the tracing of protocol violations, and automated recognition of user
/// agents for the sake of tailoring responses to avoid particular user
/// agent limitations. Although it is not required, user agents should
/// include this field with requests. The field can contain multiple
/// product tokens and comments identifying the agent and
/// any subproducts which form a significant part of the user agent. By
/// convention, the product tokens are listed in order of their
/// significance for identifying the application.<p>
/// 
/// User-Agent = "User-Agent" ":" 1*( product | comment )<p>
/// 
/// The default value of this field is:<p>
/// 
/// User-Agent: Mozilla/4.0 (compatible; Cache;)<p>
Property UserAgent As %String [ Calculated ];

Method UserAgentGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("USER-AGENT"))
}

Method UserAgentSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("User-Agent",value)
}

/// Name of item to retrieve from the web server. This is always an
/// absolute path, so if you wish to retrieve the document that is refered
/// to from the URI 'http://machine/cache/index.html' the Location will be<p>
/// <i>cache/index.html</i><p>
/// All the request methods such as <METHOD>Get</METHOD> take the location as
/// the first parameter to make calling the method easier. Note the location does
/// not contain a leading '/' character as this is implicit.
Property Location As %String;

Method LocationSet(val As %String) As %Status [ Internal ]
{
	Set i%Location=$zconvert(val,"O","URL")
	Quit $$$OK
}

/// The TCP/IP port number to connect to. This is normally port 80 (the default)
/// unless the web server has been configured to run on an different port.
Property Port As %Integer;

Method PortGet() As %Integer [ Internal ]
{
	If i%Port'="" Quit i%Port
	Set https=$select((i%ProxyServer'="")&&(+(i%ProxyPort)'=0):i%ProxyHTTPS,1:i%Https)
	Quit $select(https:443,1:80)
}

/// If not using a proxy server and this is true then it issues a request for an https page
/// rather than the normal http page. This also changes the default <property>Port</property>
/// on the target system to 443 the https port.<br>
/// If using a proxy server use of https is determined by <property>ProxyHTTPS</property>
/// and <property>Https</property> controls use of a secure SSL connection to the proxy
/// server.  In this case the default <property>ProxyPort</property> becomes,
/// 443 the https port.
Property Https As %Boolean;

/// The name of the activated TLS/SSL configuration to use for https requests.
Property SSLConfiguration As %String;

/// If request uses an SSL connection and a SSL handshake error has occurred,
/// then SSLError contains text describing the SSL error.
Property SSLError As %String;

/// When making an SSL connection check the server identity in the server certificate matches the name of the system we are connecting to.
/// This defaults to being on and matches based on the rules layed out in section 3.1 of RFC 2818.
Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 1 ];

/// Used internally to avoid checking common name unless it is a new SSL connection
Property SSLCheckIdentityInternal As %String [ Internal ];

/// When making an SSL/TLS connection use the Server Name Indication (SNI) TLS extension (RFC6066).
/// This defaults to true.
Property SSLUseSNI As %Boolean [ InitialExpression = 1 ];

/// If <property>SSLCheckIdentityInternal</property> is true this property
/// will hold the Certificate retrieved in <method>CheckSSLCN</method> <br>
Property SSLPeerCertificate As %String;

/// If true then use the HTTP CONNECT command to establish a tunnel through the proxy
/// to the target HTTP server. The address of the proxy server is taken from
/// <property>ProxyServer</property> and <property>ProxyPort</property>. If <property>ProxyHttps</property>
/// is true then once the tunnel is established we will negotiate the SSL connection. The <property>Https</property>
/// property is ignored as the tunnel establishes a direct connection with the target system.
Property ProxyTunnel As %Boolean [ InitialExpression = "0" ];

/// The amount of time to wait for a response from the web server before
/// assuming that the web server is not responding. This defaults to 30
/// seconds.
Property Timeout As %Integer [ InitialExpression = 30 ];

/// If specified is the amount of time we will wait for the TCP/IP connection to open.
/// If not specified then it will default to <property>Timeout</property> value.
Property OpenTimeout As %Integer;

/// If true then automatically follow redirection requests from the web server.
/// These are signaled by the HTTP status codes of the form 3xx.
/// The default is true for GET and HEAD methods.  Otherwise the default is false.
Property FollowRedirect As %Boolean;

/// If you need to request a web page through a proxy server you specify the
/// proxy server host name in this property. If this property is defined then
/// the http request will be directed at this machine and it will forward the
/// request to the machine at <PROPERTY>Location</PROPERTY> and return the response.<p>
Property ProxyServer As %String;

/// The port to connect to the proxy web server on. This is often port 8080 (the default).<p>
Property ProxyPort As %String [ InitialExpression = 8080 ];

/// If using a proxy server and this is true then it issues a request for an https page
/// rather than the normal http page. This allows a proxy server that supports https to
/// support a secure connection from this %Net.HttpRequest class. This also changes the
/// default <property>Port</property> on the target system to 443 the https port.
/// If using a proxy server, use of https is determined by <property>ProxyHTTPS</property>.
Property ProxyHTTPS As %Boolean [ InitialExpression = 0 ];

/// Used for proxy authentication
Property ProxyAuthentication As %Net.HttpAuthentication [ InitialExpression = {##class(%Net.HttpAuthentication).%New($THIS, 1)}, Internal ];

/// As opposed to ProxyAuthentication, this is used for target server authentication
Property ServerAuthentication As %Net.HttpAuthentication [ InitialExpression = {##class(%Net.HttpAuthentication).%New($THIS, 0)}, Internal ];

Property ProxyUsername As %Username [ Calculated ];

Method ProxyUsernameGet() As %Username [ CodeMode = expression, Internal ]
{
..ProxyAuthentication.Username
}

Method ProxyUsernameSet(username As %Username) As %Status
{
	Set ..ProxyAuthentication.Username = username
	Return $$$OK
}

Property ProxyPassword As %String [ Calculated ];

Method ProxyPasswordGet() As %String [ CodeMode = expression, Internal ]
{
..ProxyAuthentication.Password
}

Method ProxyPasswordSet(password As %String) As %Status
{
	Set ..ProxyAuthentication.Password = password
	Return $$$OK
}

/// Sets/get the 'Proxy-Authorization:' header field in the Http request.<p>
/// A user agent that wishes to authenticate itself with a proxy--
/// usually, but not necessarily, after receiving a 407 response--may do
/// so by including an Proxy-Authorization header field with the request. The
/// Proxy-Authorization field value consists of credentials containing the
/// authentication information of the user agent for the realm of the
/// resource being requested.<p>
Property ProxyAuthorization As %String [ Calculated ];

Method ProxyAuthorizationGet() As %String [ CodeMode = expression, Internal ]
{
$get(i%Headers("PROXY-AUTHORIZATION"))
}

Method ProxyAuthorizationSet(value As %String) As %Status [ CodeMode = expression, Internal ]
{
..SetHeader("Proxy-Authorization",value)
}

/// The character set to send the HTTP request header in. According to the RFC the HTTP header
/// should only contain ASCII characters as the behaviour with characters outside this range
/// is unspecified. This class defaults to using UTF-8 as this leaves all the ASCII characters
/// unchanged. You should never need to change this parameter.
Property RequestHeaderCharset As %String [ InitialExpression = "UTF-8" ];

/// If set to true then any data posted to the HTTP server will be gzipped before being sent.
/// You must be sure the remote server can accept gzip data before setting this property.
Property PostGzip As %Boolean [ InitialExpression = 0 ];

/// Set this to the timeout to use when writing to the remote HTTP server.
/// The default is -1 means it will wait indefinitely for the remote server to accept the
/// written data, change it to another value to specify the timeout in seconds. The minimum
/// value accepted is 2 seconds.
Property WriteTimeout As %Float [ InitialExpression = -1 ];

/// If true then we report we can accept gzip compressed data to the web server (the default),
/// if false then do not send the header saying we accept gzip data.
Property AcceptGzip As %Boolean [ InitialExpression = 1 ];

Method AcceptGzipSet(val As %Boolean) As %Status
{
	Set i%AcceptGzip=val
	If val {
		Do ..SetHeader("Accept-Encoding","gzip")
	} Else {
		Do ..RemoveHeader("Accept-Encoding")
	}
}

/// This holds the <CLASS>%Net.HttpResponse</CLASS> object which contains all the
/// data that the web server returned from this http request. If you wish to hold
/// onto this after you make another http request or you close the %Net.HttpRequest object
/// you should do:
/// <EXAMPLE>
/// Set response=httprequest.HttpResponse
/// </EXAMPLE>
Property HttpResponse As %Net.HttpResponse;

/// Internal structure used to store the list of cookies we have.
Property Cookies As %String [ Internal, MultiDimensional, Private ];

/// Internal structure used to store name/value elements when submitting a form.
Property FormData As %String [ Internal, MultiDimensional, Private ];

/// Set the value of name-value pair <VAR>name</VAR> to <VAR>value</VAR>.
/// <P>If more than one value is associated with <VAR>name</VAR>, then the values
/// are subscripted using <VAR>index</VAR> starting with 1. The value inserted
/// can be either a %String or a stream.
Method InsertFormData(name As %String, value As %RawString)
{
	Set index=$order(i%FormData(name,""),-1)+1,i%FormData(name,index)=value,i%FormData=$get(i%FormData)+1,i%FormData(name,index,0)=i%FormData
	Quit
}

/// Tests if a name-value pair <VAR>name</VAR> is defined.
Method IsFormDataDefined(name As %String, index As %Integer = 1) As %Boolean [ CodeMode = expression ]
{
$data(i%FormData(name,index))
}

/// Returns the number of values associated with the name-value pair <VAR>name</VAR>.
Method CountFormData(name As %String) As %Integer
{
	Quit:'$data(i%FormData(name)) 0
	Set count=0
	Set i="" For  Set i=$order(i%FormData(name,i)) Quit:i=""  Set count=count+1
	Quit count
}

/// Returns the next key in sequence
Method NextFormData(name As %String) As %String [ CodeMode = expression ]
{
$order(i%FormData(name))
}

/// Removes this key from the collection
Method DeleteFormData(name As %String, index As %Integer = "") As %Boolean
{
	If index="" {
		If $data(i%FormData(name)) Kill i%FormData(name) Quit 1
	} ElseIf $data(i%FormData(name,index)) {
		Kill i%FormData(name,index)
		Quit 1
	}
	Quit 0
}

Method OutputFormData(stream As %Stream.Object, table As %String) As %String
{
	If $get(table)="" Set table="RAW"
	If table="UTF8" {
		Set urltable="URI",table="RAW"
	} Else {
		Set urltable="URL"
	}
	Set param=""
	For  {
		Set param=$order(i%FormData(param)) Quit:param=""
		Set index=""
		For  Set index=$order(i%FormData(param,index),1,val) Quit:index=""  Set order=i%FormData(param,index,0),output(order,0)=param,output(order)=val
	}
	Set first=1
	Set order=$order(output(""),1,val)
	While order'="" {
		Set param=output(order,0)
		Do stream.Write($select(first:"",1:"&")_$zconvert($select(table="RAW":param,1:$zconvert(param,"O",table)),"O",urltable)_"=")
		Set first=0
		If $isobject(val),val.%Extends("%Stream.Object") {
			While 'val.AtEnd {
				Set data=val.Read(8096) Do stream.Write($zconvert($select(table="RAW":data,1:$zconvert(data,"O",table)),"O",urltable))
			}
		} Else {
			Do stream.Write($zconvert($select(table="RAW":val,1:$zconvert(val,"O",table)),"O",urltable))
		}
		Set order=$order(output(order),1,val)
	}
	Quit $$$OK
}

/// Sets/gets the 'Content-Type:' entity header field in the HTTP request. If it
/// is not specified and there is an <PROPERTY>EntityBody</PROPERTY> then it default
/// to 'text/html'.<p>
/// Note: This actually gets/sets the attribute 'CONTENT-TYPE' associated with
/// the stream <PROPERTY>EntityBody</PROPERTY> rather than setting a <PROPERTY>Headers</PROPERTY>.<p>
/// A Content-Type specifies the media type of the <PROPERTY>EntityBody</PROPERTY>
/// data. A	<PROPERTY>Content-Encoding</PROPERTY> may be used to indicate any additional
/// content coding applied to the type, usually for the purpose of data
/// compression, that is a property of the resource requested. The
/// default for the content encoding is none.
Property ContentType As %String [ Calculated ];

Method ContentTypeGet() As %String [ Internal ]
{
	Quit ..EntityBody.GetAttribute("CONTENT-TYPE","text/html")
}

Method ContentTypeSet(contenttype As %String) As %Status [ Internal ]
{
	Do ..EntityBody.SetAttribute("CONTENT-TYPE",contenttype)
	Quit $$$OK
}

/// This is the charset to encode the contents with. This is actually specified in the HTTP
/// Content-Type header with something like:<p>
/// 
/// Content-Type: text/html; charset=UTF-8<p>
/// 
/// You must set this property after you set the <property>ContentType</property>
/// or it will overwrite this value.
Property ContentCharset As %String [ Calculated ];

Method ContentCharsetGet() As %String [ CodeMode = expression, Internal ]
{
$Piece($Piece(..EntityBody.GetAttribute("CONTENT-TYPE"),"charset=",2),";")
}

Method ContentCharsetSet(charset As %String) As %Status [ Internal ]
{
	Set content=$zstrip(..EntityBody.GetAttribute("CONTENT-TYPE","text/html"),"<>W")
	If $zconvert(content,"l")["charset=",content'["charset=" {
		Set pos=$find($zconvert(content,"l"),"charset=")
		Set content=$replace(content,$extract(content,pos-8,pos-1),"charset=")
	}
	If content["charset=" {
		Set end=$piece($piece(content,"charset=",2,*),";",2,*)
		If charset'="" {
			If end'="" Set end=";"_end
			Set content=$piece(content,"charset=")_"charset="_charset_end
		} Else {
			Set content=$piece(content,"charset=")_end
		}
	} ElseIf charset'="" {
		If $extract(content,*)'=";" Set content=content_";"
		Set content=content_" charset="_charset
	}
	Set content=$zstrip(content,"<>W")
	If $extract(content,*)=";" Set $extract(content,*)=""
	Set ..ContentType=content
	Quit $$$OK
}

/// If the <property>ContentType</property> is 'text/' type so we are sending text then
/// if <property>NoDefaultContentCharset</property> = 1 (true), then if there is no <property>ContentCharset</property>
/// entity body charset we will use iso-8859-1 as the charset to send the entity body in.
/// If the property is 0 (the default) then if there is no entity body charset we will use utf-8.
Property NoDefaultContentCharset As %Boolean [ InitialExpression = 0 ];

/// Sets/gets the 'Content-Encoding:' entity header field in the HTTP request.
/// This actually refers to the attribute on the <PROPERTY>EntityBody</PROPERTY>.
Property ContentEncoding As %String [ Calculated ];

Method ContentEncodingGet() As %String [ CodeMode = expression, Internal ]
{
..EntityBody.GetAttribute("CONTENT-ENCODING","")
}

Method ContentEncodingSet(contentencoding As %String) As %Status [ Internal ]
{
	Do ..EntityBody.SetAttribute("CONTENT-ENCODING",contentencoding)
	Quit $$$OK
}

/// Read only property that returns the length of the <PROPERTY>EntityBody</PROPERTY>.
/// This can also be obtained by looking at 'http.EntityBody.Size' and is only included
/// for consistancy as this is the value written out for the 'Content-Length:' HTTP
/// request entity header.
Property ContentLength As %String [ Calculated ];

Method ContentLengthGet() As %Integer [ CodeMode = expression, Internal ]
{
..EntityBody.Size
}

/// Issue the Http 'get' request, this will cause the web server to return the page
/// requested. If this completes correctly the response to this request
/// will be in the <PROPERTY>HttpResponse</PROPERTY>. The <var>location</var> is the url to
/// request, e.g. '/test.html'. This can contain parameters which are assumed to be already URL
/// escaped, e.g. '/test.html?PARAM=%25VALUE' sets PARAM to %VALUE.
/// It can also be a full url with the server and optional port number e.g. 'http://server.com/test.html'.
/// If <var>test</var> is 1 then instead of connecting to a
/// remote machine it will just output what it would have send to the web server to the
/// current device, if <var>test</var> is 2 then it will output the response to the current
/// device after the Get. This can be used to check that it will send what you are expecting.
/// This calls <METHOD>Reset</METHOD> automatically after reading the response, except
/// in <var>test</var>=1 mode or if <var>reset</var>=0.
Method Get(location As %String = "", test As %Integer = 0, reset As %Boolean = 1) As %Status [ CodeMode = expression ]
{
..Send("GET",location,test,reset)
}

/// Issue the Http 'post' request, this is used to send data to the web server such as the
/// results of a form, or upload a file. If this completes correctly the response to this request
/// will be in the <PROPERTY>HttpResponse</PROPERTY>. The <var>location</var> is the url to
/// request, e.g. '/test.html'. This can contain parameters which are assumed to be already URL
/// escaped, e.g. '/test.html?PARAM=%25VALUE' sets PARAM to %VALUE.
/// It can also be a full url with the server and optional port number e.g. 'http://server.com/test.html'.
/// If <var>test</var> is 1 then instead of connecting to a
/// remote machine it will just output what it would have send to the web server to the
/// current device, if <var>test</var> is 2 then it will output the response to the current
/// device after the Post. This can be used to check that it will send what you are expecting.
/// This calls <METHOD>Reset</METHOD> automatically after reading the response, except
/// in <var>test</var>=1 mode or if <var>reset</var>=0.
Method Post(location As %String = "", test As %Integer = 0, reset As %Boolean = 1) As %Status [ CodeMode = expression ]
{
..Send("POST",location,test,reset)
}

/// Issue the Http 'put' request, this is used to upload data to the web server, it is not
/// used that often. If this completes correctly the response to this request
/// will be in the <PROPERTY>HttpResponse</PROPERTY>. The <var>location</var> is the url to
/// request, e.g. '/test.html'. This can contain parameters which are assumed to be already URL
/// escaped, e.g. '/test.html?PARAM=%25VALUE' sets PARAM to %VALUE.
/// It can also be a full url with the server and optional port number e.g. 'http://server.com/test.html'.
/// If <var>test</var> is 1 then instead of connecting to a
/// remote machine it will just output what it would have send to the web server to the
/// current device, if <var>test</var> is 2 then it will output the response to the current
/// device after the Put. This can be used to check that it will send what you are expecting.
/// This calls <METHOD>Reset</METHOD> automatically after reading the response, except
/// in <var>test</var>=1 mode or if <var>reset</var>=0.
Method Put(location As %String = "", test As %Integer = 0, reset As %Boolean = 1) As %Status [ CodeMode = expression ]
{
..Send("PUT",location,test,reset)
}

/// Issue the Http 'patch' request, this is used for making partial changes to an existing resource.
/// If this completes correctly the response to this request
/// will be in the <PROPERTY>HttpResponse</PROPERTY>. The <var>location</var> is the url to
/// request, e.g. '/test.html'. This can contain parameters which are assumed to be already URL
/// escaped, e.g. '/test.html?PARAM=%25VALUE' sets PARAM to %VALUE.
/// It can also be a full url with the server and optional port number e.g. 'http://server.com/test.html'.
/// If <var>test</var> is 1 then instead of connecting to a
/// remote machine it will just output what it would have send to the web server to the
/// current device, if <var>test</var> is 2 then it will output the response to the current
/// device after the Put. This can be used to check that it will send what you are expecting.
/// This calls <METHOD>Reset</METHOD> automatically after reading the response, except
/// in <var>test</var>=1 mode or if <var>reset</var>=0.
Method Patch(location As %String = "", test As %Integer = 0, reset As %Boolean = 1) As %Status [ CodeMode = expression ]
{
..Send("PATCH",location,test,reset)
}

/// Issue the Http 'head' request, this will cause the web server to just return the header
/// of the response and none of the body. If this completes correctly the response to this request
/// will be in the <PROPERTY>HttpResponse</PROPERTY>. The <var>location</var> is the url to
/// request, e.g. '/test.html'. This can contain parameters which are assumed to be already URL
/// escaped, e.g. '/test.html?PARAM=%25VALUE' sets PARAM to %VALUE.
/// It can also be a full url with the server and optional port number e.g. 'http://server.com/test.html'.
/// If <var>test</var> is 1 then instead of connecting to a
/// remote machine it will just output what it would have send to the web server to the
/// current device, if <var>test</var> is 2 then it will output the response to the current
/// device after the Head. This can be used to check that it will send what you are expecting.
/// This calls <METHOD>Reset</METHOD> automatically after reading the response, except
/// in <var>test</var> mode or if <var>reset</var>=0.
Method Head(location As %String, test As %Integer = 0, reset As %Boolean = 1) As %Status [ CodeMode = expression ]
{
..Send("HEAD",location,test,reset)
}

/// Issue the Http 'delete' request, this will cause the web server to delete the item referred. If this completes correctly the response to this request
/// will be in the <PROPERTY>HttpResponse</PROPERTY>. The <var>location</var> is the url to
/// request, e.g. '/test.html'. This can contain parameters which are assumed to be already URL
/// escaped, e.g. '/test.html?PARAM=%25VALUE' sets PARAM to %VALUE.
/// It can also be a full url with the server and optional port number e.g. 'http://server.com/test.html'.
/// If <var>test</var> is 1 then instead of connecting to a
/// remote machine it will just output what it would have send to the web server to the
/// current device, if <var>test</var> is 2 then it will output the response to the current
/// device after the Head. This can be used to check that it will send what you are expecting.
/// This calls <METHOD>Reset</METHOD> automatically after reading the response, except
/// in <var>test</var> mode or if <var>reset</var>=0.
Method Delete(location As %String, test As %Integer = 0, reset As %Boolean = 1) As %Status [ CodeMode = expression ]
{
..Send("DELETE",location,test,reset)
}

/// Method that actually sends HTTP request to the server.
/// This is normally called from <method>Get</method>, <method>Post</method>, <method>Put</method>, <method>Head</method>
/// but if you wish to use a different HTTP verb you can call this directly passing the <var>type</var> as the verb
/// you require.
Method Send(type As %String, location As %String, test As %Integer = 0, reset As %Boolean = 1) As %Status
{
	$$$SOAPTimer("h1")
	$$$SysLogSetVar
	Set i%SSLError="",i%SentChars=0,i%RecChars=0,sentchars=0
	Set i%TTFC=0,i%TTLC=0
	Set param="",io=$IO
	Try {
		Set charset=$ZU(96,18,0)
	} Catch {
		Set charset=""
	}
	Set $ztrap="IOTrap"
	If location'="" {
		Set full=$case($zconvert($piece(location,"://"),"l"),"http":1,"https":2,:0)
		If full {
			Set i%Https=$case(full,1:0,2:1)
			Set tmp=$piece(location,"://",2,*)
			Set host=$piece(tmp,"/",1)
			Set location=$extract(tmp,$length(host)+2,*)
			Set ..Server=$piece(host,":")
			Set i%Port=$zstrip($piece(host,":",2),"<>W")
		}
		If location["?" {
			Set i%Location=$piece(location,"?"),param=$piece(location,"?",2,*)
		} Else {
			Set i%Location=location
		}
	}
	If $extract(i%Location)="/" Set i%Location=$extract(i%Location,2,*)

	Set reused=0
	If test'=1 {
		Set return=..Open(.reused)
		If $$$ISERR(return) Quit return
		Use i%Device
	}
	$$$SOAPTimer("hopen")

	Set table=$$MapCharset^%SYS.NLS(i%RequestHeaderCharset),paramtable=table
	Try {
		Do $zutil(96,18,2,table)
	} Catch {
		Set return=$$$ERROR($$$CSPInvalidCharacterSet,table)
		Goto Error
	}

	#; Support tunneling through the proxy with 'CONNECT' command
	If i%ProxyServer'="",+(i%ProxyPort)'=0,i%ProxyTunnel,'reused {
		Try {
			Set port=..Port
			Write "CONNECT ",$get(i%Headers("HOST")),":",port," HTTP/"_i%HTTPVersion,!
			Write "Host: ",$get(i%Headers("HOST")),":",port,!
			If $get(i%Headers("PROXY-AUTHORIZATION"))'="" Write "Proxy-Authorization: ",$get(i%Headers("PROXY-AUTHORIZATION")),! Do ..RemoveHeader("PROXY-AUTHORIZATION")
			If $get(i%Headers("USER-AGENT"))'="" Write "User-Agent: ",$get(i%Headers("USER-AGENT")),!
			Write !,*-3
			Use i%Device:(::"A":$char(10))
			Read response:$select(i%OpenTimeout="":i%Timeout,1:i%OpenTimeout) If '$test Set return=$$$ERROR($$$HttpRequestConnect,$get(i%Headers("HOST"))_":"_port) Goto Error
			For  Read tmp:0 Quit:tmp=""
			If $E(response,1,5)'="HTTP/" Set return=$$$ERROR($$$HttpInvalidProxy,$get(i%Headers("HOST"))_":"_port,response) Goto Error
			If $piece(response," ",2)'=200 Set return=$$$ERROR($$$HttpConnectFail,$get(i%Headers("HOST"))_":"_port,$piece(response," ",2,*)) Goto Error
			If i%ProxyHTTPS {
				If i%SSLConfiguration="" Set return=$$$ERROR($$$HttpSSLNoConfig,$get(i%Headers("HOST"))_":"_port) Goto Error
				If i%SSLUseSNI {
					Use i%Device:(::"SCWD"::8192:8192:/TCPNOXY:/TLS=i%SSLConfiguration_"||"_$get(i%Headers("HOST")))
				} Else {
					Use i%Device:(::"SCWD"::8192:8192:/TCPNOXY:/TLS=i%SSLConfiguration)
				}
				If i%SSLCheckServerIdentity Set i%SSLCheckIdentityInternal=$get(i%Headers("HOST"))
				Set i%SSLPeerCertificate = ""
			} Else {
				Use i%Device:(::"SCWD"::8192:8192:/TCPNOXY)
			}
		} Catch {
			Set return=$$$ERROR($$$ObjectScriptError,$zerror) Goto Error
		}
	}

	Set entitybody=..EntityBody
	#; Determine the charset translation table and insert any form data
	If i%SOAPBuffering {
		Set ..ContentCharset="UTF-8"
		Set table="RAW"
	} ElseIf (entitybody.%IsA("%Net.ChunkedWriter")||(entitybody.Size>0)) {
		Set entitycharset=$Piece($Piece(entitybody.GetAttribute("CONTENT-TYPE"),"charset=",2),";"),origcharset=entitycharset
		If i%WriteRawMode {
			Set table="RAW"
		} Else {
			If entitycharset="" {
				If $zconvert(entitybody.GetAttribute("CONTENT-TYPE","text/html"),"l")["text/" {
					If i%NoDefaultContentCharset {
						Set table=..GetDefaultCharset("ISO-8859-1")
					} Else {
						Set table=..GetDefaultCharset(.entitycharset)
					}
				} Else {
					Set table="RAW"
				}
			} Else {
				Set table=..GetDefaultCharset(.entitycharset)
			}
		}
		If origcharset'=entitycharset Set ..ContentCharset=entitycharset
	} ElseIf $data(i%FormData) {
		#; If they have form data then output this
		Set entitytype=entitybody.GetAttribute("CONTENT-TYPE","text/html"),entitycharset=$Piece($Piece(entitytype,"charset=",2),";")
		If i%WriteRawMode {
			Set table="RAW"
		} Else {
			Set table=..GetDefaultCharset(.entitycharset)
		}
		Do entitybody.Clear()
		If $extract($zconvert(entitytype,"l"),1,$l("application/x-www-form-urlencoded"))="application/x-www-form-urlencoded" {
			Set ..ContentType=entitytype
		} ElseIf entitycharset'="" {
			Set ..ContentType="application/x-www-form-urlencoded; charset="_entitycharset
		} Else {
			Set ..ContentType="application/x-www-form-urlencoded"
		}
		Do ..OutputFormData(entitybody,table)
		#; Actual output is now encoded in the stream so we output the stream without any translation
		Set table="RAW"
	} Else {
		Set table="RAW"
	}

	#; Do not include TCP/IP open overhead in timing information we record
	Set startTime=$zh
	If i%ProxyServer'="",+(i%ProxyPort)'=0,'i%ProxyTunnel {
		Set tmp=type_" http"_$select(i%ProxyHTTPS:"s",1:"")_"://"_$get(i%Headers("HOST"))_":"_..Port
	} Else {
		Set tmp=type_" "
	}
	$$$SOAPTimer("hstart")
	Write tmp Set sentchars=sentchars+$length(tmp)
	#; If this was a new SSL connection verify the common name and store the Peer certificate
	If i%SSLCheckIdentityInternal'="" {
		Write *-3  ; Flush to force ssl handshake
		Set return=..CheckSSLCN(i%SSLCheckIdentityInternal, .certificate)
		Set i%SSLPeerCertificate = certificate
		If $$$ISERR(return) Goto Error
		Set i%SSLCheckIdentityInternal=""
	}
	Write "/"_i%Location Set sentchars=sentchars+$length(i%Location)+1
	Do ..OutputParams(param,paramtable)
	Write " HTTP/",i%HTTPVersion,! Set sentchars=sentchars+$length(i%HTTPVersion)+8

	Set return=..OutputHeaders()
	If $$$ISERR(return) Goto Error

	#; Entity headers
	Set name=""
	For  {
		Set name=entitybody.NextAttribute(name) If name="" Quit
		If $ZCVT(name,"U")="CONTENT-LENGTH" Continue
		If name="LineTerminator" Continue
		#; If the user has added CONTENT=TYPE in a different case make it consistent as upper case
		If $ZCVT(name,"U")="CONTENT-TYPE" {
			If name'="CONTENT-TYPE",entitybody.GetAttribute("CONTENT-TYPE")="" Set ..ContentType=entitybody.GetAttribute(name) Do entitybody.DeleteAttribute(name)
		} Else {
			Set tmp=name_": "_entitybody.GetAttribute(name)_$char(13,10)
			Write tmp Set sentchars=sentchars+$length(tmp)
		}
	}

	$$$SOAPTimer("hhdr")
	If 'i%SOAPBuffering,entitybody.%IsA("%Net.ChunkedWriter") {
		#; If chunked writer specified, then use it
		Set tmp="Content-Type: "_entitybody.GetAttribute("CONTENT-TYPE","text/html")_$char(13,10)
		Write tmp Set sentchars=sentchars+$length(tmp)
		Set entitybody.TranslateTable=table
		Do $ZU(96,18,2,"RAW")
		Do entitybody.OutputStream()
		Set sentchars=sentchars+entitybody.SentChars
	} ElseIf i%SOAPBuffering || (entitybody.Size>0) {
		Set size=$select(i%SOAPBuffering:$$xeSize^%occXMLInternal,1:..ContentLength)
		#; If they have specified an entity body then see if we can generate content-length and content-type for them
		If ..PostGzip {
			Set filename=##class(%File).NormalizeDirectory($get($$$SYSTempDir))_##class(%Stream.FileBinary).NewFileName("http")
			Open filename:("WUNK\"_table_"\":::/GZIP=1:/NOXY=1:/OBUFSIZE=32768):0 Else  Set return=$$$ERROR($$$HTTPTempFile) Goto Error
			Use filename
			If i%SOAPBuffering {
				Do xeOutput^%occXMLInternal
			} Else {
	       		Set return=entitybody.OutputToDevice() If $$$ISERR(return) Goto Error
			}
       		Write *-99
			Use i%Device
       		Close filename
       		Set size=$$$FileSize(filename)
			Do $ZU(96,18,2,"RAW")
			Set tmp="Content-Length: "_size Write tmp,! Set sentchars=sentchars+$length(tmp)+2
			Set tmp="Content-Type: "_entitybody.GetAttribute("CONTENT-TYPE","text/html") Write tmp,! Set sentchars=sentchars+$length(tmp)+2
			Set tmp="Content-Encoding: gzip" Write tmp,!! Set sentchars=sentchars+$length(tmp)+4
			Open filename:("RUK\RAW\":::/GZIP=0:/NOXY=1):0 Else  Set return=$$$ERROR($$$HTTPTempFile) Goto Error
			Try {
				Use filename Set eof=$zutil(68,40) Do $zutil(68,40,1)
				For  Use filename Read chunk:0 Quit:chunk=""  Use i%Device Write chunk Set sentchars=sentchars+$length(chunk)
				Use i%Device
				Close filename
				If $$$FileDelete(filename)
				Kill filename
				Do $zutil(68,40,eof)
			} Catch {
				Do $zutil(68,40,eof)
				Throw
			}
		} Else {
			If table="UnicodeLittle"||(table="UnicodeBig") {
				Set size=size*2
			} ElseIf table'="RAW",($extract(table,1,$length("Latin"))'="Latin"),($extract(table,1,$length("CP"))'="CP") {
				#; Check for translate table is a 1byte to 1char one, if it is not these then find the length the hard way
				Set size=0
				While 'entitybody.AtEnd { Set size=size+$length($zconvert(entitybody.Read(),"O",table)) }
				Do entitybody.Rewind()
			}
			Set tmp="Content-Length: "_size Write tmp,! Set sentchars=sentchars+$length(tmp)+2+size
			Set tmp="Content-Type: "_entitybody.GetAttribute("CONTENT-TYPE","text/html") Write tmp,!! Set sentchars=sentchars+$length(tmp)+4
			#; Now use the content charset
			Try {
				Do $ZU(96,18,2,table)
			} Catch {
				Set return=$$$ERROR($$$CSPInvalidCharacterSet,table)
				Goto Error
			}
			If i%SOAPBuffering {
				Do xeOutput^%occXMLInternal
			} Else {
				Set return=entitybody.OutputToDevice() If $$$ISERR(return) Goto Error
			}
		}
	} Else {
		#; For a form POST, PUT or PATCH with no form data write a content length to make it clear to web server there is no data
		#; This should not be required according to rfc, but some web servers appear to want it, also send Content-Type for SAML project
		If type="POST"||(type="PUT")||(type="PATCH") {
			Write "Content-Length: 0",! Set sentchars=sentchars+19
		}
		Set contenttype=entitybody.GetAttribute("CONTENT-TYPE")
		If contenttype'="" Set tmp="Content-Type: "_contenttype Write tmp,! Set sentchars=sentchars+$length(tmp)+2
		#; Cr/Lf at the end of the request without the content-length
		Write ! Set sentchars=sentchars+2
	}

	#; Flush the output
	Write *-3
	$$$SOAPTimer("hwrite")

	#; If we just want to see what would have been sent we are done
	If test=1 {
		#; Reset the character set back to the original one
		Use io Do:$get(charset)'="" $zutil(96,18,2,charset)
		Quit $$$OK
	}

	Set httpresponse=##class(%Net.HttpResponse).%New(),..HttpResponse=httpresponse
	If ..ResponseStream'="" Set httpresponse.Data=..ResponseStream

	Set return=..Read(i%Device,i%Timeout,startTime,type)
	#; If we get an error reading from web server close device to avoid reusing this
	If $$$ISERR(return) Do ..CleanUp()

	Set i%TTLC=$zh-startTime
	$$$SOAPTimer("hread")
	Use io

	#; See if we should close the socket, for HTTP/1.0 we always close it except if the server reports Keep-alive
	If httpresponse.HttpVersion="HTTP/1.0" {
		If $zconvert(httpresponse.GetHeader("CONNECTION"),"l")'="keep-alive" {
			Do ..CleanUp()
			If i%ForceReuseDevice Set i%ErrorOnNextOpen=1
		}
	} ElseIf $zconvert(httpresponse.GetHeader("CONNECTION"),"l")="close" {
		Do ..CleanUp()
		If i%ForceReuseDevice Set i%ErrorOnNextOpen=1
	}
	Set i%SentChars=i%SentChars+sentchars

	#; Process the Proxy-Authenticate header from the response.
	If $$$ISOK(return) Set return = ..ProxyAuthentication.ProcessHttpResponse(.httpresponse, type, location, test)

	#; Process the WWW-Authenticate header from the response.
	If $$$ISOK(return) Set return = ..ServerAuthentication.ProcessHttpResponse(.httpresponse, type, location, test)

	#; Only follow redirect automatically by default for GET and HEAD methods, as per RFC.
	#; FollowRedirect must be explicitely specified for POST.
	#; Also only allow 5 redirect before it looks like a loop
	Set redirect=$select($extract(httpresponse.StatusCode)=3:i%FollowRedirect,1:0)
	If (redirect="") Set redirect=((type="GET")||(type="HEAD"))
	If $$$ISOK(return),redirect,httpresponse.GetHeader("LOCATION")'="",i%RedirectNo<5 {
		Set i%RedirectNo=i%RedirectNo+1
		Set location=$zstrip(httpresponse.GetHeader("LOCATION"),"<>W")
		#; 307 and 308 are two special cases, where request method, headers, body, URL parameters need to remain unchanged.
		#; 3xx code is selected above, so there is no need to check it again here.
		If $case(httpresponse.StatusCode, 307:0, 308:0, :1) {
			If type'="GET",type'="HEAD" Set type="GET"
			Do ..ResetForRedirection()
		}
		For prefix="http://","https://" {
			If $zconvert($extract(location,1,$length(prefix)),"l")=prefix {
				Set server=$piece($piece($extract(location,$length(prefix)+1,*),"/"),"?"),rest=$extract(location,$length(prefix)+1+$length(server),*)
				If server[":" Set ..Port=$piece(server,":",2),server=$piece(server,":")
				Set ..Server=server
				Set location=rest
				If i%ProxyServer'="",+(i%ProxyPort)'=0 {
					Set i%ProxyHTTPS=(prefix="https://")
				} Else {
					Set i%Https=(prefix="https://")
				}
			}
		}
		#; If path is not absolute then assume it is relative to current path
		If $extract(location)'="/",$extract(location)'="?" {
			Set location=$$CSPNormalizeURL^%SYS.cspServer(location,i%Location)
		}
		If i%Https||(i%ProxyHTTPS),i%SSLConfiguration="" {
			Set return=$$$ERROR($$$HttpSSLRedirectNoConfig,..Server_":"_..Port)
		} Else {
			Set return=..Send(type,location,test)
			If $$$ISERR(return) Set return=$$$EMBEDERROR(return,$$$HttpRedirectError,..Server_":"_..Port,location)
		}
	}
	$$$SOAPTimer("hclose")
	Do:reset ..Reset()
	$$$SOAPTimer("hreset")

	#; If testing show the output
	If test=2 Do httpresponse.OutputToDevice()
	If test=3 Do httpresponse.OutputHeaders()

	Set ..ServerAuthentication.CurrentScheme = ""
	Quit return
IOTrap	Set $ztrap=""
	Set https=$select((i%ProxyServer'="")&&(+(i%ProxyPort)'=0):i%ProxyHTTPS&&i%ProxyTunnel,1:i%Https&&('i%ProxyTunnel))
	If https,$get(test)'=1 {
		Try {
			Set i%SSLError=$System.Security.Users.SSLGetLastError()
		} Catch {
			Set i%SSLError=""
		}
		If i%SSLError="" {
			Set return=$$$ERROR($$$ObjectScriptError,$zerror)
		} Else {
			Set return=$$$ERROR($$$HttpRequestSSLError,i%SSLConfiguration,i%SSLError)
		}
	} Else {
		Set return=$$$ERROR($$$ObjectScriptError,$zerror)
	}
Error  Try {
		Use:$get(io)'="" io
		Do:$get(charset)'="" $ZU(96,18,2,charset)
		If '..ServerAuthentication.HasHandle() {
			Set ..ServerAuthentication.CurrentScheme = ""
		}
		Do ..CleanUp()
		Set i%SentChars=i%SentChars+sentchars
	} Catch {}
	If $get(filename)'="" Close filename If $$$FileDelete(filename)
	Quit return
}

/// Open the TCP/IP port onto the web server.
Method Open(ByRef reused As %Boolean) As %Status [ Internal, Private ]
{
	Set success=0,reused=0
	Set $ZT="OpenErr"
	If i%ProxyServer'="",+(i%ProxyPort)'=0 {
		Set server=i%ProxyServer
		Set port=i%ProxyPort
	} Else {
		Set server=$get(i%Headers("HOST"))
		Set port=..Port
	}
	Set devicestate=$listbuild($get(i%Headers("HOST")),..Port,i%ProxyServer,i%ProxyPort,i%SSLConfiguration,i%ProxyTunnel,$get(i%Headers("PROXY-AUTHORIZATION")),i%Https)

	If i%ErrorOnNextOpen,i%ForceReuseDevice,devicestate=i%DeviceState {
		Quit $$$ERROR($$$HttpSocketClosed,$select(i%ProxyServer'="":i%ProxyServer_":"_i%ProxyPort,1:$get(i%Headers("HOST"))_":"_..Port))
	}
	Set i%ErrorOnNextOpen=0,i%SSLCheckIdentityInternal=""


	#; If we are using the same device try to reuse it rather than opening a new socket
	If i%Device'="" {
		If devicestate=i%DeviceState {
			Set zts=$zh
			#; Only reuse socket if it is under the maximum allowed idle time unless we must reuse the socket
			If zts-i%TimeLastUsed<i%SocketTimeout||i%ForceReuseDevice {
				Set io=$IO
				Try {
					#; Double check socket is still valid and reset device characteristics to original mode
					Use i%Device:(::"SCWD")
					Read tmp:0
					Set success=$zutil(189)
				} Catch {
				}
				Use io
			}
			If success=0 {
				Do ..CleanUp()
				If i%ForceReuseDevice Quit $$$ERROR($$$HttpSocketClosed,$select(i%ProxyServer'="":i%ProxyServer_":"_i%ProxyPort,1:$get(i%Headers("HOST"))_":"_..Port))
			}
		} Else {
			Do ..CleanUp()
		}
	}

	If i%Device="" {
		Set devices=","_$piece($view(-1,$job),"^",3)_","
		For  { Set dev="|TCP|"_($random(99999999)+1) If devices'[(","_dev_","),devices'[(","_dev_"*,") Quit }
		If i%Https,'i%ProxyTunnel {
			If i%SSLConfiguration="" Quit $$$ERROR($$$HttpSSLNoConfig,server_":"_port)
			If i%SSLUseSNI {
				Open dev:(server:port:"SCWD"::8192:8192:/TCPNOXY:/TLS=i%SSLConfiguration_"||"_server:/WRITETIMEOUT=i%WriteTimeout:/BINDTO=i%LocalInterface):$select(i%OpenTimeout="":i%Timeout,1:i%OpenTimeout) Set success=$T
			} Else {
				Open dev:(server:port:"SCWD"::8192:8192:/TCPNOXY:/TLS=i%SSLConfiguration:/WRITETIMEOUT=i%WriteTimeout:/BINDTO=i%LocalInterface):$select(i%OpenTimeout="":i%Timeout,1:i%OpenTimeout) Set success=$T
			}
			If success,i%SSLCheckServerIdentity Set i%SSLCheckIdentityInternal=server
		} Else {
			Open dev:(server:port:"SCWD"::8192:8192:/TCPNOXY:/WRITETIMEOUT=i%WriteTimeout:/BINDTO=i%LocalInterface):$select(i%OpenTimeout="":i%Timeout,1:i%OpenTimeout) Set success=$T
		}
		If success {
			Set i%Device=dev,i%DeviceState=devicestate,i%TimeLastUsed=$zh
		}
	} Else {
		Set reused=1
	}
OpenExit
	If 'success Quit $$$ERROR($$$HttpRequestConnect,$select(i%ProxyServer'="":i%ProxyServer_":"_i%ProxyPort,1:$get(i%Headers("HOST"))_":"_..Port))
	Quit $$$OK
OpenErr
	Set $ZT=""
	Goto OpenExit
}

/// Reset the %Net.HttpRequest class so that it can issue another request. This is much faster
/// than closing this object and creating a new %Net.HttpRequest object. This also moves the
/// value of <PROPERTY>Location</PROPERTY> to <PROPERTY>Referer</PROPERTY>. It is called by
/// the <METHOD>Send</METHOD> automatically after issuing a request.
Method Reset() As %Status
{
	Set location=i%Location,server=$get(i%Headers("HOST")),useragent=$get(i%Headers("USER-AGENT"))
	Kill i%Headers,i%FormData,i%Params
	Do ..EntityBodyNewObject()
	Set i%RedirectNo=0,i%BinaryContent=1
	Set https=$select((i%ProxyServer'="")&&(+(i%ProxyPort)'=0):i%ProxyHTTPS,1:i%Https)
	Set referer="http"_$select(https:"s",1:"")_"://"_server_":"_..Port_"/"_location
	Do ..InitHeaders(server,referer,useragent)
	Quit $$$OK
}

/// ResetForRedirection clears the request body, URL parameters, and other information
/// that should not be part of the subsequent redirected HTTP request.
Method ResetForRedirection() As %Status [ Internal ]
{
	// Clear the form and URL parameters;
	// keep request headers
	Kill i%FormData, i%Params
	Do ..EntityBodyNewObject()
	Return $$$OK
}

/// Used to count redirections to prevent it getting into a loop.
Property RedirectNo As %Integer [ Internal, Private ];

/// An array of strings containing any query name/value pairs associated with this request.
/// These are added to the request URL when the request is issued.
Property Params As %String [ MultiDimensional ];

/// If true then the body of the response will be read in using RAW mode, ie. with no characterset
/// translate. If false (the default) then it will use the charset specified in the response headers.
Property ReadRawMode As %Boolean [ InitialExpression = 0 ];

/// If we read a gzip response from the web server and this property is true then the stream returned
/// in the <property>HttpResponse</property> will be a %Stream.FileBinary/CharacterGzip pointing at the gzip
/// file we read. If this property is false we will uncompress the file stream into a %Stream.GlobalBinary/Character
/// stream which involves an extra copy operation. The defaults to faster operation, however you can
/// reset it to 0 for backward compatibility.
Property ReturnGzipResponse As %Boolean [ InitialExpression = 1 ];

Property BinaryContent As %Boolean [ InitialExpression = 1, Private ];

/// If true then the body (EntityBody) of the request will be written using RAW mode, ie. with no characterset
/// translate. If false (the default) then it will use the charset specified in the request
/// headers.
Property WriteRawMode As %Boolean [ InitialExpression = 0 ];

/// Optional property, if set to a stream then this is the stream that will be used to write the data from the
/// web server to rather than constructing a stream of its own. This allows you to specify which type of stream
/// you wish to read the data into, for example a file stream rather than a global stream which is the default.
Property ResponseStream As %RawString;

/// Returns the value of name-value pair <VAR>name</VAR>.
/// <P>If more than one value is associated with <VAR>name</VAR>, then the values
/// are subscripted using <VAR>index</VAR> starting with 1.
/// <VAR>index</VAR>
/// <P>If the name-value pair is not defined, returns the value of <VAR>default</VAR>.
Method GetParam(name As %String, default As %String = "", index As %Integer = 1) As %String [ CodeMode = expression ]
{
$get(i%Params(name,index),default)
}

/// Set the value of the name-value pair <var>name</var>. The optional <var>index</var>
/// is used to associate multiple <var>value</var> with a single <var>name</var>.
Method SetParam(name As %String, value As %String, index As %Integer = 1)
{
	If '$data(i%Params(name,index)) Set i%Params=$get(i%Params)+1,i%Params(name,index,1)=i%Params
	Set i%Params(name,index)=$get(value),i%Params(name,index,0)=$data(value)#2
	Quit
}

/// Set the value of name-value pair <VAR>name</VAR> to <VAR>value</VAR>.
/// <P>If more than one value is associated with <VAR>name</VAR>, then the values
/// are subscripted using <VAR>index</VAR> starting with 1.
Method InsertParam(name As %String, value As %String)
{
	Set index=$order(i%Params(name,""),-1)+1,i%Params(name,index)=$get(value),i%Params(name,index,0)=$data(value)#2,i%Params=$get(i%Params)+1,i%Params(name,index,1)=i%Params
	Quit
}

/// Tests if a name-value pair <VAR>name</VAR> is defined.
Method IsParamDefined(name As %String, index As %Integer = 1) As %Boolean [ CodeMode = expression ]
{
''$data(i%Params(name,index))
}

/// Returns the number of values associated with the name-value pair <VAR>name</VAR>.
Method CountParam(name As %String) As %Integer
{
	Quit:'$data(i%Params(name)) 0
	Set count=0
	Set i="" For  Set i=$order(i%Params(name,i)) Quit:i=""  Set count=count+1
	Quit count
}

/// Returns the next key in sequence
Method NextParam(name As %String) As %String [ CodeMode = expression ]
{
$order(i%Params(name))
}

/// Removes this key from the collection
Method DeleteParam(name As %String, index As %Integer = "") As %Boolean
{
	If index="" {
		If $data(i%Params(name)) Kill i%Params(name) Quit 1
	} ElseIf $data(i%Params(name,index)) {
		Kill i%Params(name,index) Quit 1
	}
	Quit 0
}

/// Output all the parameters to the current device. The <var>params</var> is any
/// parameters that you wish to be included in the parameters output, these are
/// assumed to already be URL escaped.
Method OutputParams(params As %String = "", table As %String)
{
	If $get(table)="" Set table="RAW"
	If table="UTF8" {
		Set urltable="URI",table="RAW"
	} Else {
		Set urltable="URL"
	}
	If params="",$order(i%Params(""))="" Quit
	Set sentchars=0
	Write "?",params Set sentchars=sentchars+$length(params)+1
	Set first=$select(params="":1,1:0)
	Set param=$order(i%Params(""))
	While (param'="") {
		Set index="" For  Set index=$order(i%Params(param,index)) Quit:index=""  Set order=i%Params(param,index,1),order(order)=param,order(order,0)=index
		Set param=$order(i%Params(param))
	}
	Set order=$order(order(""),1,param)
	While order'="" {
		Set index=order(order,0),val=i%Params(param,index)
		Set tmp=$select(first:"",1:"&")_$zconvert($select(table="RAW":param,1:$zconvert(param,"O",table)),"O",urltable)_$select(i%Params(param,index,0):"="_$zconvert($select(table="RAW":val,1:$zconvert(val,"O",table)),"O",urltable),1:"")
		Write tmp Set first=0 Set sentchars=sentchars+$length(tmp)
		Set order=$order(order(order),1,param)
	}
	Set i%SentChars=i%SentChars+sentchars
	Quit
}

/// Return the list of parameters that this request will output.
Method ReturnParams() As %String
{
	Set return="?"
	Set param=$order(i%Params(""))
	While (param'="") {
		Set index="" For  Set index=$order(i%Params(param,index)) Quit:index=""  Set order=i%Params(param,index,1),order(order)=param,order(order,0)=index
		Set param=$order(i%Params(param))
	}
	Set order=$order(order(""),1,param)
	While order'="" {
		Set index=order(order,0),val=i%Params(param,index)
		Set return=return_$$$URLENCODE(param)_$select(i%Params(param,index,0):"="_$$$URLENCODE(val),1:"")_"&"
		Set order=$order(order(order),1,param)
	}
	Quit $extract(return,1,*-1)
}

/// Add a cookie to this %Net.HttpRequest object. The <var>name</var> is the name of the cookie, the <var>value</var>
/// is the value this cookie is set to. The <var>path</var> is the path to store the cookie under, it will only
/// be output for this path and any subpaths on the server. The <var>domain</var> is the name of the machine the
/// cookie is downloaded from. Then <var>expires</var> is the date/time when this cookie will expire. The <var>secure</var>
/// parameter is if the cookie should be send over secure channels only, i.e. https.
Method InsertCookie(name As %String, value As %String, path As %String, domain As %String, expires As %String, secure As %Boolean = 0) As %Status
{
	If $length(path)>1,$extract(path,*)="/" Set path=$extract(path,1,*-1)
	If $length(path)>510 RETURN $$$ERROR($$$HTTPCookiePathTooLong,name,$l(path),path)
	Set i%Cookies($zconvert(domain,"l"),path,name)=$listbuild(value,expires,secure)
	Quit $$$OK
}

/// Remove a cookie from this %Net.HttpRequest object. The <var>name</var>, <var>path</var>, and <var>domain</var>
/// must match the ones used to insert the cookie in the first place.
Method DeleteCookie(name As %String, path As %String, domain As %String) As %Status
{
	If $length(path)>1,$extract(path,*)="/" Set path=$extract(path,1,*-1)
	If $length(path)>510 RETURN $$$OK  ; Not possible to insert paths this long anyway
	Kill i%Cookies($zconvert(domain,"l"),path,name)
	Quit $$$OK
}

/// Remove any session cookie from this %Net.HttpRequest object.
Method DeleteSessionCookie() As %Status [ Internal ]
{

	Set domain=""
	For {
		Set domain=$order(i%Cookies(domain))
		If domain="" Quit
		Set path=""
		For {
			Set path=$order(i%Cookies(domain,path))
			If path="" Quit
			Set name=""
			For {
				Set name=$order(i%Cookies(domain,path,name))
				If name="" Quit
				If $extract(name,1,16)="CSPSESSIONID-SP-" kill i%Cookies(domain,path,name)
			}
		}
	}
	Quit $$$OK
}

/// Internal function to take the server cookie line and insert cookies from it.
Method InsertCookieFromServer(cookie As %String) As %Status [ Internal, Private ]
{
	Set $ztrap="cookieTrap"
	Set domain=$zconvert($get(i%Headers("HOST")),"l"),path=i%Location
	Set path=$piece(path,"/",1,*-1)
	Set secure=0,expires=""
	For i=1:1:$length(cookie,";") {
		Set piece=$ZSTRIP($Piece(cookie,";",i),"<>W") Continue:piece=""
		If i=1 Set name=$piece(piece,"="),value=$extract(piece,$length(name)+2,*) Continue
		Set type=$ZCVT($piece(piece,"="),"L"),val=$extract(piece,$length(type)+2,*)
		If type="path" {
			Set path=$zstrip(val,"<>W")
			If $length(path)>1,$extract(path,*)="/" Set path=$extract(path,1,*-1)
		} ElseIf type="domain" {
			Set val=$zconvert($zstrip(val,"<>W"),"l")
			If $extract(val)="." Set val=$extract(val,2,*)
			If val'=$zconvert($get(i%Headers("HOST")),"l") {
				If ..MatchSuffix(val) Goto exit
				If val'=$extract($zconvert($get(i%Headers("HOST")),"l"),*-$length(val)+1,*) Goto exit
			}
			Set domain="."_val  ; The leading '.' indicates this was a domain provided in the SetCookie header rather than no domain explicitly specified
		} ElseIf type="expires" {
			Set val=$ZSTRIP($Piece(val,",",2),"<>W")
			Try {
				Set date=$piece(val," "),time=$ztimeh($piece(val," ",2),,,1)
				Set date=$piece(date,"-",2)_" "_$piece(date,"-")_" "_$piece(date,"-",3)
				Set date=$ZDATEH(date,7,,,,,,,,1)
				#; All cookie expires dates are in UTC
				Set date=date*86400+time
				#; If the expire date is before current date then remove the cookie
				Set zts=$ztimestamp
				If date<($piece(zts,",")*86400+$piece(zts,",",2)) Set expires=-1
				Set expires=(date\86400)_","_(date#86400)
			} Catch {
				#; If the expires is in invalid format do not expire this cookie
				Set expires=""
			}
		} ElseIf type="secure" {
			Set secure=1
		}
	}
	If $extract(path)'="/" Set path="/"_path
	If $get(name)'="" {
		If $length(path)>510 RETURN $$$ERROR($$$HTTPCookiePathTooLong,name,$l(path),path)
		If expires=-1 {
			Kill i%Cookies(domain,path,name)
		} Else {
			Set i%Cookies(domain,path,name)=$listbuild(value,expires,secure)
		}
	}
exit	Quit $$$OK
cookieTrap	Set $ztrap=""
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Internal function to return the list of cookies that we should send to this
/// <var>domain</var> for this <var>path</var>.
Method GetCookiesForHost(domain As %String, path As %String) As %String [ Internal, Private ]
{
	#; Remove any port information
	Set domain=$zconvert($piece(domain,":"),"l"),return="",path=$piece(path,"/",1,*-1)  ; Get the path from the URI of the file we are getting
	If $extract(path)'="/" Set path="/"_path
	If $data(i%Cookies(domain)) Set return=..cookiesForHost("",domain,path)  ; Case where SetCookie did not specify a domain
	If $data(i%Cookies("."_domain)) Set return=..cookiesForHost("","."_domain,path)  ; Case where SetCookie explicitly set domain to the current hostname
	If domain'?1.3N1"."1.3N1"."1.3N1"."1.3N {
		For i=2:1:$length(domain,".")-1 {
			Set subdomain="."_$piece(domain,".",i,*)   ; For subdomains only find cases where SetCookie explicitly set domain
			If $data(i%Cookies(subdomain)) Set return=..cookiesForHost(return,subdomain,path)
		}
	}
	Quit $extract(return,1,*-2)
}

Method cookiesForHost(cookies As %String, domain As %String, path As %String) As %String [ Internal, Private ]
{
	Set https=$select((i%ProxyServer'="")&&(+(i%ProxyPort)'=0):i%ProxyHTTPS,1:i%Https)
	Set zts=$ztimestamp,zts=$piece(zts,",")*86400+$piece(zts,",",2)
	For i=1:1:$length(path,"/") {
		Set realpath=$piece(path,"/",1,i) If realpath="" Set realpath="/"
		If $length(realpath)>510 QUIT  ; Do not support cookies for paths over 510 characters
		Set name=""
		For  {
			Set name=$order(i%Cookies(domain,realpath,name),1,val) If name="" Quit
			#; Expire cookies as needed
			Set expire=$list(val,2)
			If expire,($piece(expire,",")*86400+$piece(expire,",",2))<zts Kill i%Cookies(domain,realpath,name) Continue
			If 'https,$list(val,3) Continue
			Set cookies=name_"="_$list(val)_"; "_cookies
		}
	}
	Quit cookies
}

/// Passed <var>cookies</var> by reference and return an array of cookies so you can see which
/// cookies have been set, or persist them into a database if wished. The return from this method
/// is the number of cookies that are in the array. The format of the array is:<p>
/// array(index)=$LB(name,domain,path,value,expires,secure)
Method GetFullCookieList(ByRef cookies) As %Integer
{
	Set index=1
	Set zts=$ztimestamp,zts=$piece(zts,",")*86400+$piece(zts,",",2)
	Set domain=""
	For {
		Set domain=$order(i%Cookies(domain)) Quit:domain=""
		Set path=""
		For {
			Set path=$order(i%Cookies(domain,path)) Quit:path=""
			Set name=""
			For {
				Set name=$order(i%Cookies(domain,path,name),1,val) Quit:name=""
				#; Expire cookies as needed
				Set expire=$list(val,2)
				If expire,($piece(expire,",")*86400+$piece(expire,",",2))<zts Kill i%Cookies(domain,path,name) Continue
				Set cookies(index)=$listbuild(name,domain,path)_val,index=index+1
			}
		}
	}
	Quit index-1
}

/// Internal method used to read the response from the web server into this object.
Method Read(device As %String, timeout As %Integer = 10, startTime As %Float, type As %String = "") As %Status [ Internal, Private ]
{
	Set return=$$$OK,zerror=$zerror,httpresponse=..HttpResponse,data=httpresponse.Data,eof=$zutil(68,40) Do $zutil(68,40,0)
	Set $zerror=""
	If $zcvt(data,"l")="string" {
		Set data="",stringdataoutput=1
	} Else {
		Set stringdataoutput=0
	}

	#; Reset device
	Use device:(::"A":$char(10))
	#; Set UTF-8 for reading in headers
	Do $ZU(96,18,2,"UTF8")
	$$$SOAPTimer("huse")
	$$$SOAPTimerSetup(set first=1)

	Set initread=0
	Set $ZTrap="ReadTrap"
	#; Parse the request.  The request processor is basically a state machine
	Set delim=$char(13,10),state=1,pos=1,rq="",used=0,found=0,query="",length="",chunked=0,exit=0,gzip=0,key="",maxstring=$$$MaxLocalLength-100,recchars=0
	While (state'=0)&&(exit=0) {
		#; Looking for the next delimited piece
		If found Set query="",found=0
		Set oldpos=pos,pos=$select(delim'="":$find(rq,delim,oldpos),1:0)
		If pos'=0 {
			Set query=query_$extract(rq,oldpos,pos-$L(delim)-1),used=used+(pos-$length(delim)-oldpos)+1,found=1
		} Else {
			Set query=query_$extract(rq,oldpos,*),pos=1,used=used+($length(rq)-oldpos)+1
			If length'="",used'<length {
				Set pos=$length(query)-(used-length)+1,query=$extract(query,1,pos-1),used=length
				Set found=1
			} Else {
				Try {
					If length'="" {
						Read rq#($select(length-used>maxstring:maxstring,1:length-used)):timeout Set to=$test
					} Else {
						Read rq:timeout Set to=$test
					}
					If initread=0 {
						Set initread=1
						Set i%TTFC=$zh-startTime
					}
					$$$SOAPTimerSetup(If first set first=0 ) $$$SOAPTimer("hfirst")
					If 'to,rq="" {
						$$$SysLogVar(3,"HttpRequest","Timed out waiting for response from server","")
						Set return=$$$ERROR($$$CSPTimeout),state=0
					} Else {
						If delim=$char(13,10) Set rq=$translate(rq,$char(13)) If $zb=$char(10) Set rq=rq_$char(13,10)
						$$$SysLogVar(3,"HttpRequest","Read from server",rq)
						If $$$GETIO="RAW" {
							Set recchars=recchars+$length(rq)
						} Else {
							Try {
								Set recchars=recchars+$length($zconvert(rq,"O",$$$GETIO))
							} Catch {
								#; In case of MAXSTRING
								For i=1:12000:$length(rq) {
									Set recchars=recchars+$length($zconvert($extract(rq,i,i+11999),"O",$$$GETIO))
								}
							}
						}
					}
				} Catch {
					If $zerror["<READ>" {
						#; By setting this we still process the current state and then exit
						Set exit=1
						#; If in any state other than 3 we do not expect a READ error here, if in state 3 and we have a length and 'found then we did
						#; not read to the end of it so we should return an error here also
						If state'=3||(length'=""&&('found)) Set return=$$$ERROR($$$TCPIPError,$zerror,$zu(189,1))
					} Else {
						$$$SysLogErrorVar("HttpRequest","Error while reading from web server")
						Set return=$$$ERROR($$$ObjectScriptError,$zerror),state=0
					}
				}
				If query=""||(state=0) Continue
			}
		}

		#; Now, handle each state
		$$$SysLogVar(3,"HttpRequest","READ: state="_state_", used="_used,$select(state=3:$extract(query,1,255),1:query))

		#; *** HTTP Status line ***
		If state=1,found {
			#; Ignore blank lines when expecting the status line
			If query="" Continue
			#; Handle 100 'CONTINUE' header
			If $piece(query," ",2)="100" Set state=4 Continue
			Set httpresponse.StatusLine=query
			Set httpresponse.HttpVersion=$piece(query," "),httpresponse.StatusCode=$piece(query," ",2),httpresponse.ReasonPhrase=$piece(query," ",3,*)
			Set state=2
			Continue
		}

		#; *** HTTP Headers ***
		If state=2||(state=6),found {
			#; Continuation of previous header line
			If $ascii(query)=32||($ascii(query)=9) {
				If $get(key)'="" Set value=$get(value)_" "_$zstrip(query,"<>W")
			} Else {
				If $get(key)'="" {
					#; Special cases
					If key="CONTENT-TYPE" {
						Set httpresponse.ContentType=value,httpresponse.ContentInfo=$zstrip($piece(value,";",2,*),"<W")
						If ..ParseContent(httpresponse.ContentInfo,.tmparray) {
							Set return=$$$ERROR($$$CSPInvalidContentType,value)
						} Else {
							If $data(tmparray("boundary")) Set httpresponse.ContentBoundary=tmparray("boundary")
						}
					}
					If key="CONTENT-LENGTH" Set httpresponse.ContentLength=value
					If key="SET-COOKIE" Set sc=..InsertCookieFromServer(value) If $$$ISERR(sc) Set return=sc,state=0
					If key="TRANSFER-ENCODING",$zconvert(value,"l")="chunked" Set chunked=1
					If key="CONTENT-ENCODING",$zconvert(value,"l")="gzip" Set gzip=1
					#; General case for headers
					Do httpresponse.SetHeader(key,value)
				}
				Set key=$zconvert($piece(query,":"),"u")  ; Headers field names are case insensitive
				Set value=$zstrip($extract(query,$length(key)+2,*),"<>W")
			}
			#; Cr/Lf seperates headers from body
			If $translate(query,$char(13))="" {
				Kill value
				If state=6 Set state=0 Continue
				#; If we issued a HEAD then we only expect the headers from the web server
				If type="HEAD" Set state=0 Continue
				#; If 204/205/304 response then also no body
				If $case(httpresponse.StatusCode,204:1,205:1,304:1,:0) Set state=0 Continue
				#; If 101, then validate protocol switch.
				If (httpresponse.StatusCode = 101) {
					Set state = 0
					Continue
				}
				Set contenttype=$zconvert($zstrip($piece(httpresponse.ContentType,";"),">W"),"l")
				If ..ReadRawMode'=1,$extract(contenttype,1,$length("text/"))="text/"||($translate($extract(contenttype,*-3,*),"+","/")'="/xml") {
					Set charset=$piece($translate($zconvert(httpresponse.ContentType,"l"),$char(32,9)),"charset=",2),charset=$zstrip($piece(charset,";"),"<>W","""")
					If charset="" {
						If $extract(contenttype,1,$length("text/"))="text/" {
							Set charset="ISO-8859-1"
							Set table=..GetDefaultCharset(.charset)
							Set i%BinaryContent=0
						} ElseIf contenttype = "application/json" {
							#; As described in rfc4627 JSON text shall be encoded in Unicode, the default encoding is UTF-8
							Set table = "UTF8"
							Set i%BinaryContent=0
						} Else {
							Set table="RAW"
						}
					} Else {
						Set i%BinaryContent=0
						Set table=..GetDefaultCharset(.charset)
					}
				} Else {
					Set table="RAW"
				}
				If gzip {
					Set filename=##class(%File).NormalizeDirectory($get($$$SYSTempDir))_##class(%Stream.FileBinary).NewFileName("http")
					Open filename:("WUNK\RAW\":::/NOXY=1:/OBUFSIZE=32768):0 Else  Set return=$$$ERROR($$$HTTPTempFile),state=0 Quit
			        Use device
				}
				If chunked {
					Set state=5
				} Else {
					#; Reset the device characteristics to read in without looking for delimitors.
					Use device:(::"ASW")
					Set delim="",length=httpresponse.ContentLength,used=0,state=3,extra=""
					Do $zutil(96,18,2,"RAW")
				}
				Continue
			}
		}

		#; *** Content ***
		If state=3 {
			If query'="" {
				If gzip {
					Use filename
					Write query
					Use device
				} Else {
					If table'="RAW" {
						Try {
							Set query=$zconvert(query,"I",table,extra)
							#; If we are at the end then process anything in 'extra' due to ambiguous translate tables
							If found,'chunked,$get(extra)'="" Set query=query_$zconvert(extra,"I",table),extra=""
						} Catch {
							Set state=0,return=$$$ERROR($$$CSPInvalidCharacterSet,$get(charset,table))
						}
					}
					If $isobject(data)=1 {
						Do data.Write(query)
					} ElseIf $length(data)+$length(query)>32767 {
						Set datastream=$select(i%BinaryContent:##class(%Stream.GlobalBinary).%New(),1:##class(%Stream.GlobalCharacter).%New())
						Do datastream.Write(data),datastream.Write(query)
						Set data=datastream
					} Else {
						Set data=data_query
					}
				}
				Set query=""
			}
			If found {
				If chunked {
					#; Need to reset to look for more chunks
					Set state=5,delim=$char(13,10),used=0,length=""
					Use device:(::"A":$char(10))
					Do $ZU(96,18,2,"UTF8")
					Continue
				} Else {
					Set state=0
				}
			}
		}

		#; *** '100 Continue' header (just ignore it) ***
		If state=4,found {
			If $translate(query,$char(13,32))="" Set state=1
		}

		#; *** Chunked response ***
		If state=5,found {
			Set query=$zstrip($piece(query,";"),"<>W")
			#; Ignore cr/lf after on chunk's data
			If query="" Continue
			Set length=$zhex(query)
			If length=0 {
				#; Handle ambiguous translate table if 'extra' characters are left over at end of chunked segment
				If $get(extra)'="",table'="RAW" {
					Try {
						Set extra=$zconvert(extra,"I",table)
					} Catch {
						Set state=0,return=$$$ERROR($$$CSPInvalidCharacterSet,$get(charset,table))
					}
					If $isobject(data)=1 {
						Do data.Write(extra)
					} ElseIf $length(data)+$length(extra)>32767 {
						Set datastream=$select(i%BinaryContent:##class(%Stream.GlobalBinary).%New(),1:##class(%Stream.GlobalCharacter).%New())
						Do datastream.Write(data),datastream.Write(extra)
						Set data=datastream
					} Else {
						Set data=data_extra
					}
					Set extra=""
				}
				#; We read all the data look for more headers
				Set state=6,delim=$char(13,10),used=0,length=""
				Use device:(::"A":$char(10))
				Do $ZU(96,18,2,"UTF8")
			} Else {
				Set delim="",used=0,state=3
				#; Reset the device characteristics to read in without looking for delimitors.
				Use device:(::"ASW")
				Do $zutil(96,18,2,"RAW")
			}
		}
	}

	If gzip,type'="HEAD",$get(filename)'="" {
		Close filename
		If i%ReturnGzipResponse,$isobject(data)=0 {
			Set data=$select(i%BinaryContent:##class(%Stream.FileBinaryGzip).%New(),1:##class(%Stream.FileCharacterGzip).%New())
			Set sc=data.LinkToFile(filename) If $$$ISERR(sc) Set return=$$$ADDSC(return,sc)
			If 'i%BinaryContent Set data.TranslateTable=table
			Set data.LineTerminator=$char(13,10)
			Set data.RemoveOnClose=1
			Set filename=""
		} Else {
			Open filename:("RUK\"_table_"\":::/GZIP=1:/NOXY=1):0 Else  Set return=$$$ERROR($$$HTTPTempFile)
			Use filename Do $zutil(68,40,1)
	        For  {
				Read chunk:0 If chunk="" Quit
				If $isobject(data)=1 {
					Do data.Write(chunk)
				} ElseIf $length(data)+$length(chunk)>32767 {
					Set datastream=$select(i%BinaryContent:##class(%Stream.GlobalBinary).%New(),1:##class(%Stream.GlobalCharacter).%New())
					Do datastream.Write(data),datastream.Write(chunk)
					Set data=datastream
				} Else {
					Set data=data_chunk
				}
			}
			Use device
			Close filename
		}
	}

	If 'stringdataoutput,$isobject(data)=0 {
		Set datastream=$select(i%BinaryContent:##class(%Stream.GlobalBinary).%New(),1:##class(%Stream.GlobalCharacter).%New())
		Do datastream.Write(data)
		Set data=datastream
	}

	If $isobject(data)=1,$system.CLS.IsMthd(data,"Rewind") Do data.Rewind()
	Set httpresponse.Data=data
	Set i%RecChars=i%RecChars+recchars

	If $get(filename)'="" Close filename If $$$FileDelete(filename)
	Set $zerror=$get(zerror)
	Do $zutil(68,40,eof)
	Quit return
ReadTrap	Set $ztrap="" Do $zutil(68,40,eof)
	Set i%RecChars=i%RecChars+$get(recchars)
	If $get(filename)'="" Close filename If $$$FileDelete(filename)
	If $zerror["<READ>"||$zerror["<DISCONNECT>" Quit $$$ERROR($$$TCPIPError,$zerror,$zu(189,1))
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Helper function to convert from a $H value into the date/time format suitable for
/// use in an HTTP request. It converts the timezone from the current $H value to the
/// GMT timezone as well as outputting the correct format.
ClassMethod HorologToRFCDateTime(horolog As %String = {$Horolog}) As %String
{
	#; Convert $horolog value to seconds and modify to UT
	Set zts=$ztimestamp,h=$horolog
	Set horolog=$piece(horolog,",")*86400+$piece(horolog,",",2)+($piece(zts,",")*86400)+($piece(zts,",",2)\1)-($piece(h,",")*86400+$piece(h,",",2))
	Set horolog=horolog\86400_","_(horolog#86400)
	#; Now convert to RFC format of date/time
	Quit $ZDate(horolog,11,,,,,,,,1)_", "_$ZDatetime(horolog,2,,,,,,,,,,1)_" GMT"
}

/// Passed a character set, if it is null it returns the default character set for this
/// system and updates <parameter>charset</parameter> with the rfc name for this charset.
/// If defined it looks up the charset and returns the InterSystems IRIS name for it.
Method GetDefaultCharset(ByRef charset As %String) As %String [ Internal, Private ]
{
	If charset'="" Quit $$MapCharset^%SYS.NLS(charset)
	#; On unicode default CharSet is UTF-8 always
	If $ZBitGet($ZVersion(0),1) Set charset="UTF-8" Quit "UTF8"
	#; For 8-bit system ask for locale default charset.
	Set charset=$$MapExtCharset^%SYS.NLS($$GetCharset^%SYS.NLS())
	Quit "RAW"
}

/// Parse a name=value,name2="newvalue" type list
ClassMethod ParseContent(in As %String, ByRef return As %String) As %Boolean
{
	Kill return
	Set in=$zstrip($tr(in,$c(13,10),""),"<W"),del="=",out=""
hloop  If $extract(in)=del { Goto hdel } If in="" { Goto hexit } If $extract(in)="""" { Goto hquote }
hdefault	Set stuff=$piece(in,del),out=out_$zstrip(stuff,">W"),in=$extract(in,$length(stuff)+1,*) Goto hloop
hquote	Set stuff=$find(in,"""",2) If stuff=0 Set continue=out_$extract(in,2,*) Quit 1
	Set out=out_$extract(in,2,stuff-2),in=$extract(in,stuff,*)
	If $extract(in)="""" { Set out=out_"""" Goto hquote } Else { Goto hdefault }
hdel	If del="=" { Set name=$zconvert(out,"l"),del=";" } Else { Set:name'="" return(name)=out Set del="=",name="" } Set out="",in=$zstrip($extract(in,2,*),"<W") Goto hloop
hexit	If del=";",name'="" { Set return(name)=out } Quit 0
}

/// Verify the SSL <var>server</var> we are connected to has the correct certificate.
/// In order to call this method the SSL/TLS connection must be active and must be the current
/// device, also at least one message must have been sent down the socket in order for the SSL/TLS
/// handshake to have taken place so we have the certificate.
/// If InterSystems IRIS is acting as a client and makes a request to a server by IP address, the server's certificate
/// need only contain the matching IP address in the Subject DN for us to verify the server's identity;
/// the subjectAltName extension does not have to be present. This is a slight difference to the wording of RFC 2818.
ClassMethod CheckSSLCN(server As %String, Output certificate As %String) As %Status
{
	Set server=$zconvert(server,"l"),list=""
	Set certificate=$System.Security.Users.SSLGetPeerCertificate()
	If certificate=""||(certificate="Security.Users") Quit $$$ERROR($$$SSLNoCertificate)
	For type=1,2 {
		If type=1 {
			Set row=$System.Encryption.X509GetField(certificate,"Extension:subjectAltName")
			Set search="DNS:",searchip="IP Address:"
		} Else {
			Set row=$System.Encryption.X509GetField(certificate,"Subject")
			Set search="CN=",searchip=search
		}
		Set row=..parseName($zconvert(row,"I","UTF8")),search=$char(0)_search,searchip=$char(0)_searchip
		Set find=0
		For {
			Set find=$find(row,search,find) Quit:find=0
			Set value=$zconvert($piece($extract(row,find,*),$char(0)),"l")
			Set list=list_value_","
			If $extract(value)="*" {
				Set value=$extract(value,2,*)
				If value=$extract(server,*-$length(value)+1,*),$extract(server,1,*-$length(value))'["." Return $$$OK
			} Else {
				If value=server Return $$$OK
			}
		}

		#; Check for server being an IP address in which case we need an exact match
		Set checkip=0
		If server?.N1".".N1".".N1".".N {
			Set checkip=1
			For i=1:1:4 {
				If $piece(server,".",i)>255 Set checkip=0 Quit
			}
		} ElseIf $translate(server,":0123456789abcdef")="",$length(server,":")<9,$length(server,":")>2 {
			Set checkip=1
			For i=1:1:$length(server,":") {
				Set piece=$zconvert($piece(server,":",i),"l")
				If $length(piece)>4 Set checkip=0 Quit
			}
		}
		If checkip {
			Set find=0
			For {
				Set find=$find(row,searchip,find) Quit:find=0
				Set value=$zconvert($piece($extract(row,find,*),$char(0)),"l") If type'=2 Set list=list_value_","
				If server=value Return $$$OK
			}
		}

		#; Only check the Subject if we did not find any match on the Extension:subjectAltName
		If list'="" Quit
	}
	Quit $$$ERROR($$$SSLCertificateNoMatch,server,$extract(list,1,*-1))
}

ClassMethod parseName(name As %String) As %String [ Private ]
{
	Set tmp=$translate(name,"+;\,",$char(0,0,0,0,0)),pos=1,output=""
	For {
		Set oldpos=pos,pos=$find(tmp,$char(0),pos)
		If pos=0 Set output=output_$extract(name,oldpos,*) Quit
		Set output=output_$extract(name,oldpos,pos-2)
		Set chr=$extract(name,pos-1)
		If chr="+"||(chr=";")||(chr=",") {
			Set output=output_$char(0)
			While $char(9,32,160)[$extract(name,pos) { Set pos=pos+1 }
		} ElseIf " ""#+,;<=>\"[$extract(name,pos) {
			Set output=output_$extract(name,pos)
			Set pos=pos+1
		} Else {
			Set char=$extract(name,pos,pos+1)
			Try {
				Set char=$char($zhex(char))
			} Catch {
				Set char="?"
			}
			Set output=output_char
			Set pos=pos+2
		}
	}
	Quit $char(0)_output
}

/// Determine if this domain is a public suffix (publicsuffix.org) or not, return
/// true if it is and false if it is not.
ClassMethod MatchSuffix(domain As %String) As %Boolean
{
	Quit:domain="" 0

	If $data(^%qPublicSuffix(domain),not) {
		Quit not
	}
	If $data(^%qPublicSuffix("*."_$piece(domain,".",2,*)),not) {
		Quit not
	}
	Quit 0
}

/// Load in the <var>filename</var> which is the downloaded public suffix list from publicsuffix.org
ClassMethod LoadPublicSuffix(filename As %String) As %Status
{
	Set file=##class(%Stream.FileCharacter).%New()
	Set sc=file.LinkToFile(filename) If $$$ISERR(sc) Quit sc
	Kill ^%qPublicSuffix
	Set file.TranslateTable="UTF8"
	Do {
		Set not=1
		Set line=$piece(file.ReadLine()," ")
		If line=""||($extract(line,1,2)="//") Continue
		If $extract(line)="!" Set not=0,line=$extract(line,2,*)
		Set ^%qPublicSuffix(line)=not
	} While 'file.AtEnd
	Quit $$$OK
}

Property LastPongContent As %Stream.TmpBinary;

/// Receives a possibly-fragmented message from the server. <br />
/// Throws $$$NetWebSocketErrConnectionClosed if the server closes the connection. <br />
/// Responds to pings from the server automatically.
Method WebSocketRead(Output pContentStream As %Stream.Object = {$$$NULLOREF}, pTimeout As %Integer = 10, Output pTimedOut As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tLastFragment = 0
		Set tTopOpCode = ""
		Set tContentStream = ##class(%Stream.TmpBinary).%New()
		While 'tLastFragment {
			Set tFrame = ##class(%Net.WebSocket.Frame).%New(..Device)
			Do tFrame.Read(pTimeout)
			If (tFrame.HasMessage) {
				// Op code:
				If (tFrame.Opcode = $$$WebSocketOpContinuation) || (tFrame.Opcode = $$$WebSocketOpTextFrame) || (tFrame.Opcode = $$$WebSocketOpBinaryFrame) {
					If (tFrame.Opcode '= $$$WebSocketOpContinuation) {
						Set tTopOpCode = tFrame.Opcode
					}
					While 'tFrame.PayloadData.AtEnd {
						$$$ThrowOnError(tContentStream.Write(tFrame.PayloadData.Read($$$MaxStringLength,.tSC)))
						$$$ThrowOnError(tSC)
					}
				} ElseIf (tFrame.Opcode = $$$WebSocketOpClose) {
					// Close
					If (i%Device '= "") {
						Close i%Device
						Set i%Device=""
					}
					$$$ThrowStatus($$$ERROR($$$NetWebSocketErrConnectionClosed))
				} ElseIf (tFrame.Opcode = $$$WebSocketOpPing) {
					// Ping
					$$$ThrowOnError(..WebSocketPong(tFrame.PayloadData))
					If (tTopOpCode = "") {
						Continue
					}
				} ElseIf (tFrame.Opcode = $$$WebSocketOpPong) {
					Set ..LastPongContent = tFrame.PayloadData
					If (tTopOpCode = "") {
						Quit
					}
				}
			} Else {
				Set pTimedOut = 1
				Quit
			}
			Set tLastFragment = tFrame.Fin
		}
		If (tTopOpCode = $$$WebSocketOpTextFrame) {
			Set pContentStream = ##class(%Stream.TmpCharacter).%New()
			Set tLeftoverChars = ""
			$$$ThrowOnError(tContentStream.Rewind())
			While 'tContentStream.AtEnd {
				Set tNextChunk = $ZConvert(tContentStream.Read($$$MaxStringLength,.tSC),"I","UTF8",tLeftoverChars)
				$$$ThrowOnError(tSC)
				$$$ThrowOnError(pContentStream.Write(tNextChunk))
			}
		} Else {
			Set pContentStream = tContentStream
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

/// Writes <var>pContentStream</var> as a binary frame if it is a binary stream type, or a text frame if not.
/// If <var>pFragmentSize</var> is 0, will send <var>pContentStream</var> as a single binary/text frame;
/// otherwise, will send as fragments of maximum length <var>pFragmentSize</var>.
Method WebSocketWrite(pContentStream As %Stream.Object, pFragmentSize As %Integer = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		// TODO: Determine maximum fragment size based on ..BufferSize
		Set tIsBinary = ($Classname(pContentStream) [ "Binary")
		Set tOpCode = $Select(tIsBinary:$$$WebSocketOpBinaryFrame,1:$$$WebSocketOpTextFrame)
		If (pFragmentSize = 0) {
			Set tFrame = ##class(%Net.WebSocket.Frame).%New(..Device)
			Set tFrame.Opcode = tOpCode
			While 'pContentStream.AtEnd {
				If (tIsBinary) {
					Do tFrame.PayloadData.Write(pContentStream.Read($$$MaxStringLength,.tSC))
				} Else {
					// Maximum of 4 bytes in a UTF-8 encoded character: play it safe.
					Do tFrame.PayloadData.Write($ZConvert(pContentStream.Read($$$MaxStringLength/4,.tSC),"O","UTF8"))
				}
			}
			Do tFrame.Write()
		} Else {
			While 'pContentStream.AtEnd {
				Set tFrame = ##class(%Net.WebSocket.Frame).%New(..Device)
				Set tFrame.Opcode = tOpCode
				If tIsBinary {
					Do tFrame.PayloadData.Write(pContentStream.Read(pFragmentSize,.tSC))
				} Else {
					// TODO: enforce fragment size even if it separates bytes in a given UTF8 character
					Do tFrame.PayloadData.Write($ZConvert(pContentStream.Read(pFragmentSize,.tSC),"O","UTF8"))
				}
				$$$ThrowOnError(tSC)
				Set tFrame.Fin = pContentStream.AtEnd
				Do tFrame.Write()
				Set tOpCode = $$$WebSocketOpContinuation
			}
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

/// Sends a ping frame with contents defined in <var>pContentStream</var>.
Method WebSocketPing(pContentStream As %Stream.Object) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFrame = ##class(%Net.WebSocket.Frame).%New(..Device)
		Set tFrame.Opcode = $$$WebSocketOpPing
		$$$ThrowOnError(tFrame.PayloadData.CopyFrom(pContentStream))
		Do tFrame.Write()
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

/// Sends an pong frame with contents defined in <var>pContentStream</var>.
/// Should be used only for unsolicited pongs.
Method WebSocketPong(pContentStream As %Stream.Object) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFrame = ##class(%Net.WebSocket.Frame).%New(..Device)
		Set tFrame.Opcode = $$$WebSocketOpPong
		$$$ThrowOnError(tFrame.PayloadData.CopyFrom(pContentStream))
		Do tFrame.Write()
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

/// The client should not close the web socket connection for any reason other than "going away" (1001).
Method WebSocketClose(pReason As %Integer = 1001) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFrame = ##class(%Net.WebSocket.Frame).%New(..Device)
		Set tFrame.Opcode = $$$WebSocketOpClose
		Do tFrame.PayloadData.Write($char(pReason/256)_$char(pReason#256))
		Do tFrame.Write()
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

}
