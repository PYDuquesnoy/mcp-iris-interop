/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SOAP Web Client class.
/// <br>
/// 
/// Properties of this class that begin with Http are passed through to the
/// %Net.HttpRequest instance used by the class.
/// 
/// The only supported use of this class is as the super class for a SOAP Web Client.
/// Parameters, properties and methods may be used by the application.
Class %SOAP.WebClient Extends %SOAP.WebBase [ Abstract, System = 3 ]
{

/// The SOAPVERSION parameter specified the version of SOAP which is supported. 
/// Possible values for the version are 1.1 and 1.2. The default value "" specifies
/// that both SOAP 1.1 and SOAP 1.2 are supported.
Parameter SOAPVERSION As STRING [ Constraint = ",1.1,1.2", Flags = ENUM ];

/// If the web client has the parameter SOAPACTIONQUOTED=1, then the web client will
/// quote the SOAPAction value for SOAP 1.1.  The default will be SOAPACTIONQUOTED=0
/// in order to be compatible with earlier versions of InterSystems IRIS.
Parameter SOAPACTIONQUOTED As BOOLEAN = 0;

/// If the web client has the parameter URLESCAPESOAPACTION=1, then the web client will
/// send URL ESCAPED SOAPAction Header for SOAP 1.1.  The default will be URLESCAPESOAPACTION=0
/// in order to be compatible with earlier versions of InterSystems IRIS.
/// New generated IRIS SOAP clients can take advantage of enabled URL Escaping for SOAP 1.1
Parameter URLESCAPESOAPACTION As BOOLEAN = 0;

/// The SoapVersion property is either "1.1" or "1.2" and indicates the SOAP 
/// version for the current invocation.<br><br>
/// 
/// For a SOAP web client, SoapVersion specifies the SOAP version that is used 
/// for the request.<br>
/// If SoapVersion="" (the default), then "1.1" is used if SOAPVERSION="1.1" or "" (the default).
/// Otherwise "1.2" is used if SOAPVERSION="1.2".<br>
/// After the response is received, it is the version of the response.
/// This, SoapVersion should be set before each method call.
Property SoapVersion As %String;

/// Deprecated. %Net.HttpRequester will always be used as the network access layer
Property HttpRequester As %String(VALUELIST = ",SAX,CACHE") [ Deprecated ];

/// If UsePPGHandler is true (1), then force SOAP response parsing to use PPG memory.<br>
/// If UsePPGHandler is false (0), then force SOAP response parsing to use local array memory.<br>
/// If UsePPGHandler is not set ( or = ""), then use default memory -- usually local array memory.<br>
/// The default value of this property is the USEPPGHANDLER parameter value.
Property UsePPGHandler As %Boolean [ InitialExpression = {..#USEPPGHANDLER}, Transient ];

/// If SoapBinary is 1, then the web client will use proprietary binary SOAP protocol.
/// The SoapBinary property defaults to the SOAPBINARY parameter.<br/>
/// For requests directed to subclass of %SOAP.WebService but not EnsLib.SOAP.Service
Property SoapBinary As %Boolean [ InitialExpression = {..#SOAPBINARY}, Transient ];

/// Setter method to insure that first not binary message uses session cookie form binary messages
Method SoapBinarySet(value As %Boolean) As %Status [ Internal ]
{
	If value=0,value'=i%SoapBinary {
		Set ..KeepSessionCookie=1
	}
	Set i%SoapBinary=value
	Quit $$$OK
}

/// If set then we keep session cookie even if not binary session.
Property KeepSessionCookie As %Boolean [ Internal ];

/// Default charset for remote SOAP binary server.
/// This parameter is by default used to dertermine if binary message needs to be UTF8 encoded.
Parameter SOAPBINARYCHARSET As STRING;

/// Property to allow override of charset for remote SOAP binary server.
/// This parameter is used to dertermine if binary message needs to be UTF8 encoded.
/// The default for SoapBinaryCharset is the SOAPBINARYCHARSET parameter.
Property SoapBinaryCharset As %String [ InitialExpression = {..#SOAPBINARYCHARSET}, Transient ];

/// Property to allow the WS-Addressing namespace to be specified for requests
Property WSANamespace As %String [ Transient ];

/// Property to allow override of policy to be used for the web client.<br>
/// PolicyConfiguration is specified as 'Configuration class name':'Configuration name'
/// where 'Configuration name' comes from the name attribute of the configuration element
/// in the configuration class (i.e. sublcass of %SOAP.Configuration"
/// If PolicyConfiguration="" or is not specified, then the policy specified by the
/// service classname attribute is attached to this class.
Property PolicyConfiguration As %String [ Transient ];

/// If specified, the caller assigned %Net.HttpRequest instance is used for
/// the web service request.
Property HttpRequest As %Net.HttpRequest [ Transient ];

/// Content-Type to be used for transport class
Property ContentType As %String [ Transient ];

/// The name of the activated TLS/SSL configuration to use for https requests.
Property SSLConfiguration As %String [ Transient ];

/// If request uses an SSL connection and a SSL handshake error has occurred,
/// then SSLError contains text describing the SSL error.
Property SSLError As %String;

/// When making an SSL connection check the server identity in the certificate matches the name of the system we are connecting to.
/// This defaults to being on and matches based on the rules layed out in section 3.1 of RFC 2818.
Property SSLCheckServerIdentity As %Boolean;

/// If the GzipOutput property is set to true (1), then the output request
/// will be compressed using GZIP.  
/// The default value for GzipOutput is the GZIPOUTPUT parameter.
Property GzipOutput As %Boolean [ InitialExpression = {..#GZIPOUTPUT}, Transient ];

/// If specified is the amount of time we will wait for the TCP/IP connection to open.
/// If not specified then it will default to <property>Timeout</property> value.
Property OpenTimeout As %Integer [ Transient ];

/// The HttpResponse property is set to the %Net.HttpResponse instance for the response to the
/// web service request. This property is only set when the %Net.HttpRequest object is used to 
/// make the request, i.e. when HttpRequestor="CACHE" (the default).
Property HttpResponse As %Net.HttpResponse [ Transient ];

/// The HTTP version we should report to the server when making the request.
/// Defaults to '1.1'.
Property HTTPVersion As %String [ InitialExpression = "1.1", Transient ];

/// If true then automatically follow redirection requests from the web server.
/// These are signaled by the HTTP status codes of the form 3xx. 
/// The default is false.
Property HttpFollowRedirect As %Boolean [ Transient ];

/// If you need to make SOAP request through a proxy server you specify the
/// proxy server host name in this property. If this property is defined then
/// the http request will be directed at this machine and it will forward the
/// request to the machine at <PROPERTY>Location</PROPERTY> and return the response.<p>
/// You can specify a default proxy server for this namespace or for the entire instance
/// by setting ^SYS("HttpRequest","ProxyServer") or ^%SYS("HttpRequest","ProxyServer").
Property HttpProxyServer As %String [ Transient ];

/// The port to connect to the proxy web server on. This is often port 8080 (the default).<p>
/// You can specify a default proxy server for this namespace or for the entire instance
/// by setting ^SYS("HttpRequest","ProxyPort") or ^%SYS("HttpRequest","ProxyPort").
Property HttpProxyPort As %String [ Transient ];

/// If true then use the HTTP CONNECT command to establish a tunnel through the proxy
/// to the target HTTP server. The address of the proxy server is taken from
/// <property>HttpProxyServer and <property>HttpProxyPort. If the endpoint URL
/// has the https: protocol, then once the tunnel is established we will negociate the SSL connection.
Property HttpProxyTunnel As %Boolean [ Transient ];

/// SSL connection to the proxy server will be used if the HttpProxySSLConnect property = 1.
/// <property>
/// Use of SSL to the eventual endpoint is determined by the protocol part of
/// web service's location url.
Property HttpProxySSLConnect As %Boolean [ Transient ];

/// HttpProxyHTTPS property is ignored since the use of SSL to the end point
/// is now determiend from the url.
/// If using a proxy server and this is true then it issues a request for an https page
/// rather than the normal http page. This allows a proxy server that support https to
/// support a secure connection from this %Net.Httprequest class.
Property HttpProxyHTTPS As %Boolean [ Transient ];

/// Sets/get the 'Proxy-Authorization:' header field in the Http request.<p>
/// A user agent that wishes to authenticate itself with a proxy--
/// usually, but not necessarily, after receiving a 407 response--may do
/// so by including an Proxy-Authorization header field with the request. The
/// Proxy-Authorization field value consists of credentials containing the
/// authentication information of the user agent for the realm of the
/// resource being requested.<p>
Property HttpProxyAuthorization As %String [ Transient ];

/// The character set to send the HTTP request header in. According to the RFC the HTTP header
/// should only contain ASCII characters as the behaviour with characters outside this range
/// is unspecified. This class defaults to using UTF-8 as this leaves all the ASCII characters
/// unchanged. You should never need to change this parameter.
Property HttpRequestHeaderCharset As %String [ Transient ];

/// If the Username and <property>Password</property> are defined then this information
/// will be sent using Basic authentication to the web server. If you manually set the
/// <property>Authorization</property> header this property will be ignored.
Property HttpUsername As %String [ Transient ];

/// If the <property>Username</property> and Password are defined then this information
/// will be sent using Basic authentication to the web server. If you manually set the
/// <property>Authorization</property> header this property will be ignored.
Property HttpPassword As %String [ Transient ];

/// A client may initiate a connection to the server with an "Authorization" header containing
/// the initial token for the server for a chosen authentication scheme.
/// %Net.HttpRequest is asked to initiate the connection by setting the InitiateAuthentication property
/// to a string which is a single scheme name. This form will bypass the initial 401 error from
/// the server when the client knows that the server will accept the specified scheme.
/// Supported schemes are Negotiate, NTLM and Basic.
Property HttpInitiateAuthentication As %String [ Transient ];

/// If HttpAccept202=0 (default) we follow the WS-I Basic Profile which calls for HTTP response
/// status 202 to be used only if no SOAP envelope is in the HTTP response and return an error if no envelope.<br>
/// If HttpAccept202=1, HTTP status 202 will treated just the same as HTTP status 200.
/// The HttpResponse.StatusCode property may be checked to see if 202 was actually returned.
Property HttpAccept202 As %Boolean [ Transient ];

/// If set to true then this will force the %Net.HttpRequest class to reuse the existing connection
/// to the web server if the socket is already open. If there is any error it will be reported to
/// the caller. This has been introduced to support reliable SOAP messaging, so should not normally
/// be set by other code.
Property HttpForceReuseDevice As %Boolean [ InitialExpression = 0, Internal ];

/// Internal structure used to store the collection of headers for %Net.HttpRequest.
Property HttpHeaders As %String [ MultiDimensional, Private, Transient ];

/// Set this to the timeout the HttpRequest object will use when writing to the remote HTTP server.
/// If not set the value from the HttpRequest object (%Net.HttpRequest) WriteTimeout property will be used which has a default of -1.
/// -1 means it will wait indefinitely for the remote server to accept the written data, change it to another value to specify the timeout in seconds.
/// The minimum value accepted is 2 seconds.
Property HttpWriteTimeout As %Float [ Transient ];

/// Add HTTP header to the SOAP request. For example:
/// <EXAMPLE>
/// Set client = ##class(My.Generated.Soap.Calculator).%New()
/// Set client.Locaton = http://Server:Port/IRISPrefix/Application/WebService.cls?CfgItem=ProductionServiceName
/// . . .
/// Do client.SetHttpHeader("Header-Name", "Header Value")
/// Do client.SetHttpHeader("SendingFacility", "Haymarket")
/// . . .
/// Do client.WSSecurityLogin(username, password)
/// Try {
///   Set myResult = client.Add(2, 2)
/// } Catch {
/// 	 . . . 
/// }
/// </EXAMPLE>
/// The header name is case insensitive and this class forces it to upper case so
/// when the Http request is issued it will output the header as:<p>
/// MYHEADER: Data to display<p>
/// Note that headers such as Content-Type, Content-Encoding, and Content-Length are
/// part of the entity body rather than the http main headers and as such as forwarded
/// to the <PROPERTY>ContentType</PROPERTY>, <PROPERTY>ContentEncoding</PROPERTY> and
/// trying to set the Content-Length is just ignored as this is a read only property.
/// Also any attempt to set the 'Connection' header is ignored at this request class
/// does not support persistent connections.<br/>
/// For custom SOAP Headers within SOAP Envelope see Client HeadersOut collection, %SOAP.Header type and WebService XData named "parameters".
Method SetHttpHeader(name As %String, value As %String) As %Status [ ServerOnly = 1 ]
{
	Set i%HttpHeaders=$get(i%HttpHeaders)+1
	Set i%HttpHeaders(i%HttpHeaders)=$listbuild(name,value)
	Quit $$$OK
}

/// Clear all previously set Http headers. 
Method ResetHttpHeaders() As %Status [ ServerOnly = 1 ]
{
	Kill i%HttpHeaders
	Quit $$$OK
}

/// The WSSecurityLogin method adds the WS-Security Security header with /UsernameToken.
/// Only the /UsernameToken/Username and /UsernameToken/Password fields are supported.
/// Signing and/or encryption as specified by WS-Security is not supported.  
/// These facilities are expected to be implemented by the use of SSL. 
Method WSSecurityLogin(Username As %String, Password As %String) As %Status [ ServerOnly = 1 ]
{
	Set ..Username=Username
	Set ..Password=Password

	Quit $$$OK
}

Method MakeSecurityHeader() [ Internal, Private, ServerOnly = 1 ]
{
	If $isobject(r%SecurityOut) && (r%SecurityOut.FindElement("UsernameToken")'="") Quit

	Set token=##class(%SOAP.Security.UsernameToken).Create(..Username,..Password)
	Do ..SecurityOut.AddSecurityElement(token)
	
	Quit
}

/// Test for valid WS-Security 1.1 SignatureConfirmation elements in response message.
/// Return true if valid.
Method WSCheckSignatureConfirmation() As %Boolean [ ServerOnly = 1 ]
{
	Set valid=1
	$$$SOAPLogSecurity("    CheckSignatureConfirmation")
	If ..SecurityIn="" {
		#; Error if no Security element
		$$$SOAPLogSecurity("        Error: no Security element")
		Set valid=0
	} Else {
		Set pos=0
		Set confirm=..SecurityIn.FindElement("SignatureConfirmation",.pos)
		If confirm="" {
			#; Error if no SignatureConfirmation elements
			$$$SOAPLogSecurity("        Error: no SignatureConfirmation elements")
			Set valid=0
		} Else {
			#; Validate each SignatureConfirmation element
			While confirm'="" {
				Set valid=confirm.Validate($this)
				If 'valid {
					$$$SOAPLogSecurity("    SignatureConfirmation is invalid: no matching signature")
					Quit
				}
				Set confirm=..SecurityIn.FindElement("SignatureConfirmation",.pos)
			}
		}
	}
	If valid {
		#; Validate that all signatures have been confirmed.
		Set pos=0
		For {
			Set signature=..SecurityOut.FindElement("Signature",.pos)
			If '$isobject(signature) Quit
			If 'signature.Confirmed {
				$$$SOAPLogSecurity("        Error: all signatures have not been confirmed.")
				Set valid=0
				Quit
			}
		}
	}

	Quit valid
}

/// Start a WS-SecureConversation session by sending the specified RequestSecurityToken body
/// to the web service and obtaining a RequestSecurityTokenResponse.
/// If ComputedKey is to be used with both client and server entropy, ComputedKeySize property
/// of the RequestSecurityToken object should be set before calling StartSecureConversation.
/// RequireServerEntropy property of the RequestSecurityToken object should be set before calling StartSecureConversation.<br><br>
/// 
/// The SecurityContextToken thus returned will be saved in the SecurityContextToken property.
/// Future calls to this client may use this token if needed for the WS-Policy or
/// by explicitly adding to SecurityOut by calling AddSecurityElement.<br><br>
/// 
/// The SecurityOut header needs to be set for proper security for the RequestSecurityToken request.
/// The SecurityOut header used for WS-StartSecureConversation will be cleared after when this method is complete.
Method StartSecureConversation(RST As %SOAP.WST.RequestSecurityToken) As %Status [ ServerOnly = 1 ]
{
	// Save SecurityOut, AddressingOut and HeadersOut
	Set originalMethodName=..MethodName
	Set originalAction=..Action
	Set originalOneWay=..OneWay
	Set originalSecurity=$select(r%SecurityOut="":"",1:r%SecurityOut.%ConstructClone())
	Set originalAddressingOut=..AddressingOut
	Set originalNamespacesOut=..NamespacesOut
	Set ..NamespacesOut=""
	Set originalHeadersOut=##class(%ArrayOfObjects).%New()
	For {
		Set hdr=..HeadersOut.GetNext(.hdrName)
		If hdrName="" Quit
		Do originalHeadersOut.SetAt(hdr,hdrName)
		Do ..HeadersOut.RemoveAt(hdrName)
	}
	// Save Location since applying policy may modify location
	Set originalLocation=..Location
	
	// WS-Addressing Action header must be included.
	Set ..AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultRequestProperties(..Location,$$$SOAPWSSCTokenRequest,..WSANamespace)
	
	// Send request for SecurityContextToken
	Set sc=..SendSOAPRequest($$$SOAPWSSCTokenRequest,0,RST,"RequestSecurityToken")
	
	// Process response.
	If $$$ISOK(sc) {
		Set responseName=$$$xmlGetLocalName(RST.%ResponseDocument.DocumentId,RST.%ResponseNodeId)
		If responseName="RequestSecurityTokenResponseCollection" {
			Set element=##class(%SOAP.WST.RequestSecurityTokenResponseCollection).%New()
			Set sc=element.XMLImport("RequestSecurityTokenResponseCollection","literal",$$$SOAPWSTNS,RST.%ResponseDocument,RST.%ResponseNodeId)
			If $$$ISOK(sc) {
				If element.RequestSecurityTokenResponse.Count()<1 {
					Set sc=$$$ERROR($$$WSTCollectionEmptyResponse)
				} Else {
					// Use the first token for following messages
					Set RSTR=element.RequestSecurityTokenResponse.GetAt(1)
					If RSTR.KeySize'="" {
						Set keysize=(RSTR.KeySize+7)\8
					} Else {
						Set keysize=RST.ComputedKeySize
					}
					Set SCT=RSTR.ProcessIssueResponse($this,keysize,RST.RequireServerEntropy,RST.Entropy,.sc)
					If $$$ISOK(sc) {
						Set ..SecurityContextToken=SCT
					}
				}
			}
		} Else {
			Set sc=$$$ERROR($$$WSTCollectionResponseRequired,responseName)
		}
	}
	
	// Restore original SecurityOut, AddressingOut, HeadersOut and Location after this request
	Set ..MethodName=originalMethodName
	Set ..Action=originalAction
	Set ..OneWay=originalOneWay
	Set ..SecurityOut=originalSecurity
	Set ..AddressingOut=originalAddressingOut
	Set ..NamespacesOut=originalNamespacesOut
	Set ..HeadersOut=originalHeadersOut
	Set ..Location=originalLocation
	
	Quit sc
}

/// Cancel the this client's current WS-SecureConversation token specified by the SecurityContextToken property.
/// Clear the SecurityContextToken propery.
/// If SecurityOut header has not been set, then a minimal SecurityOut using the token for signing is created.
/// The SecurityOut header used for WS-StartSecureConversation will be cleared after when this method is complete.
Method CancelSecureConversation() As %Status [ ServerOnly = 1 ]
{
	// Nothing to do if no SecurityContextToken
	Set SCT=..SecurityContextToken
	If SCT="" Quit $$$OK
		
	// WS-Addressing Action header must be included.
	Set ..AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultRequestProperties(..Location,$$$SOAPWSSCTokenCancelRequest,..WSANamespace)

	Set target=##class(%SOAP.WST.Target).%New()	
	
	If ..SecurityOut.SecurityElement.Count()>0 {
		Set target.token=SCT
	} Else {
		Do ..SecurityOut.AddSecurityElement(SCT)
		Set sig=##class(%XML.Security.Signature).Create(SCT,,$$$SOAPWSReferenceSCT)
		Do ..SecurityOut.AddSecurityElement(sig) 
		Set target.SecurityTokenReference=##class(%SOAP.Security.SecurityTokenReference).GetSCTReference(SCT)
	}
	
	Set RST=##class(%SOAP.WST.RequestSecurityToken).%New()
	Set RST.RequestType=$$$SOAPWSTCancel
	Set RST.CancelTarget=target
	
	// Send request for SecurityContextToken
	Set sc=..SendSOAPRequest($$$SOAPWSSCTokenCancelRequest,0,RST,"RequestSecurityToken")
	
	// Process response.
	If $$$ISOK(sc) {
		Set responseName=$$$xmlGetLocalName(RST.%ResponseDocument.DocumentId,RST.%ResponseNodeId)
		If responseName="RequestSecurityTokenResponseCollection" {
			Set element=##class(%SOAP.WST.RequestSecurityTokenResponseCollection).%New()
			Set sc=element.XMLImport("RequestSecurityTokenResponseCollection","literal",$$$SOAPWSTNS,RST.%ResponseDocument,RST.%ResponseNodeId)
			If $$$ISOK(sc) {
				If element.RequestSecurityTokenResponse.Count()<1 {
					Set sc=$$$ERROR($$$WSTCollectionEmptyResponse)
				} Else {
					// Use the first token for following messages
					Set RSTR=element.RequestSecurityTokenResponse.GetAt(1)
					If RSTR.RequestedTokenCancelled="" {
						Set sc=$$$ERROR($$$WSTCancelResponse)
					}
				}
			}
		} Else {
			Set sc=$$$ERROR($$$WSTCollectionResponseRequired,responseName)
		}
	}
	
	// Reset SecurityOut and SecurityContextToken after this request
	Set ..SecurityOut=""
	Set ..SecurityContextToken=""
	
	Quit sc
}

/// Start a WS-ReliableMessaging sequence by sending the specified CreateSequence body
/// to the web service and obtaining a CreateSequenceResponse.
/// Sessions are only supported for HTTP synchronous (HTTP request/response) with anonymouse WS-Addressing and
/// for only a single client instance.
/// 
/// The %SYS.RMSession object that is referenced in the %SOAP.RM.CreateSequence object
/// is updated based on the CreateSequenceResponse and saved in the RMSession property of this client.
/// Future calls to this client will use this %SYS.RMSession to make future calls part of this sequence.<br><br>
/// 
/// The SecurityOut header needs to be set for proper security for the CreateSequence request.
/// The SecurityOut header used for WS-ReliableMessaging will be cleared after when this method is complete.
/// 
/// If the SecurityContextToken property contains a SecurityContextToken, then this token will be
/// associated with the new sequence.
Method %StartRMSession(createSequence As %SOAP.RM.CreateSequence) As %Status [ ServerOnly = 1 ]
{
	// %SOAP.RM.CreateSequence object may only be used once.
	Set session=createSequence.RMSession
	If '$isobject(session) {
		Quit $$$ERROR($$$RMCreateSequenceReuse)
	}

	// Save SecurityOut, AddressingOut and HeadersOut
	Set originalMethodName=..MethodName
	Set originalAction=..Action
	Set originalOneWay=..OneWay
	Set originalSecurity=$select(r%SecurityOut="":"",1:r%SecurityOut.%ConstructClone())
	Set originalAddressingOut=..AddressingOut
	Set originalNamespacesOut=..NamespacesOut
	Set ..NamespacesOut=""
	Set originalHeadersOut=##class(%ArrayOfObjects).%New()
	For {
		Set hdr=..HeadersOut.GetNext(.hdrName)
		If hdrName="" Quit
		Do originalHeadersOut.SetAt(hdr,hdrName)
		Do ..HeadersOut.RemoveAt(hdrName)
	}
	
	// WS-Addressing Action header must be included.
	Set action=$$$SOAPWSRMns_"/CreateSequence"
	Set ..AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultRequestProperties(..Location,action,..WSANamespace)
	
	// Always add UsesSequenceSTR if STR to SecurityContextToken
	If $isobject(createSequence.SecurityTokenReference) {
		Set uses=##class(%SOAP.RM.UsesSequenceSTR).%New()
		Do ..HeadersOut.SetAt(uses,"UsesSequenceSTR")
	} ElseIf session.SSLSecurity {
		Set uses=##class(%SOAP.RM.UsesSequenceSSL).%New()
		Do ..HeadersOut.SetAt(uses,"UsesSequenceSSL")
	}
	
	// Send request to create RM sequence
	Set sc=..SendSOAPRequest(action,0,createSequence,"CreateSequence")
	
	// Process response.
	If $$$ISOK(sc) {
		Set responseName=$$$xmlGetLocalName(createSequence.%ResponseDocument.DocumentId,createSequence.%ResponseNodeId)
		If responseName="CreateSequenceResponse" {
			Set element=##class(%SOAP.RM.CreateSequenceResponse).%New()
			Set sc=element.XMLImport("CreateSequenceResponse","literal",$$$SOAPWSRMns,createSequence.%ResponseDocument,createSequence.%ResponseNodeId)
			If $$$ISOK(sc) {
				If $case(element.IncompleteSequenceBehavior,"":0,"DiscardFollowingFirstGap":0,"NoDiscard":0,:1) {
					Set sc=$$$ERROR($$$RMCreateSequenceResponseBehavior,element.IncompleteSequenceBehavior)
				}
			}
			If $$$ISOK(sc) {
				Set session.AppliesTo=..Location
				Set session.RequestIdentifier=element.Identifier
				If $isobject(createSequence.SecurityTokenReference) {
					Set session.SCTIdentifier=createSequence.SCTIdentifier
				}
				Set expires=element.Expires
				If expires="" Set expires=createSequence.Expires
				If expires'="" {
					Set session.ExpiresInSeconds=##class(%XML.Implementation).AddDuration($ztimestamp,expires)
				}
				// If sequence Offer not accepted, clear ResponseIdentifier.
				If element.Accept="" Set session.ResponseIdentifier=""
				Set ..RMSession=session
			}
		} Else {
			Set sc=$$$ERROR($$$RMCreateSequenceResponseRequired,responseName)
		}
	}
	
	// Clear session in %SOAP.RM.CreateSequence to prevent it being reused.
	Set createSequence.RMSession=""

	// Restore original SecurityOut, AddressingOut and HeadersOut after this request
	Set ..MethodName=originalMethodName
	Set ..Action=originalAction
	Set ..OneWay=originalOneWay
	Set ..SecurityOut=originalSecurity
	Set ..AddressingOut=originalAddressingOut
	Set ..NamespacesOut=originalNamespacesOut
	Set ..HeadersOut=originalHeadersOut
	
	Quit sc
}

/// Close this client's current WS-ReliableMessaging session specified by the RMSession property.
/// Clear the RMSession property. If OmitSeqAckHeader is set to 1, then a final SequenceAcknowledgement
/// header will suppressed from the response.
Method %CloseRMSession(OmitSeqAckHeader As %Boolean = 0) As %Status [ ServerOnly = 1 ]
{
	// Nothing to do if no RM session
	Set session=..RMSession
	If (session="") || (session.Terminated) Quit $$$OK
	
	// Mark session as Terminated
	Set session.Terminated=1
	Set ..HttpForceReuseDevice=0
		
	// WS-Addressing Action header must be included.
	Set action=$$$SOAPWSRMns_"/CloseSequence"
	Set ..AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultRequestProperties(..Location,action,..WSANamespace)

    If (OmitSeqAckHeader=0) {
	 	// Send final SequenceAcknowledgement
		Set ack=##class(%SOAP.RM.SequenceAcknowledgement).CreateHeader(..RMSession,1)
		Set ack.Final=$c(0)
		Do ..HeadersOut.SetAt(ack,"SequenceAcknowledgement")
    }

	// Send request for CloseSequence
	Set message=##class(%SOAP.RM.CloseSequence).%New()
	Set message.Identifier=..RMSession.RequestIdentifier
	Set message.LastMsgNumber=..RMSession.MessageNumber
	Set sc=..SendSOAPRequest(action,0,message,"CloseSequence")
	
	// Process response.
	If $$$ISOK(sc) {
		Set responseName=$$$xmlGetLocalName(message.%ResponseDocument.DocumentId,message.%ResponseNodeId)
		If responseName="CloseSequenceResponse" {
			Set element=##class(%SOAP.RM.CloseSequenceResponse).%New()
			Set sc=element.XMLImport("CloseSequenceResponse","literal",$$$SOAPWSRMns,message.%ResponseDocument,message.%ResponseNodeId)
		} Else {
			Set sc=$$$ERROR($$$RMCloseSequenceResponseRequired,responseName)
		}
	}
	Set closeSequenceStatus=sc
	
	// WS-Addressing Action header must be included.
	Set action=$$$SOAPWSRMns_"/TerminateSequence"
	Set ..AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultRequestProperties(..Location,action,..WSANamespace)

    If (OmitSeqAckHeader=0) {
		// Send final SequenceAcknowledgement
		Set ack=##class(%SOAP.RM.SequenceAcknowledgement).CreateHeader(..RMSession,1)
		Set ack.Final=$c(0)
		Do ..HeadersOut.SetAt(ack,"SequenceAcknowledgement")
	}

	// Send request for TerminateSequence
	Set message=##class(%SOAP.RM.TerminateSequence).%New()
	Set message.Identifier=..RMSession.RequestIdentifier
	Set message.LastMsgNumber=..RMSession.MessageNumber
	Set sc=..SendSOAPRequest(action,0,message,"TerminateSequence")
	
	// Process response.
	If $$$ISOK(sc) {
		Set responseName=$$$xmlGetLocalName(message.%ResponseDocument.DocumentId,message.%ResponseNodeId)
		If responseName="TerminateSequenceResponse" {
			Set element=##class(%SOAP.RM.TerminateSequenceResponse).%New()
			Set sc=element.XMLImport("TerminateSequenceResponse","literal",$$$SOAPWSRMns,message.%ResponseDocument,message.%ResponseNodeId)
		} Else {
			Set sc=$$$ERROR($$$RMTerminateSequenceResponseRequired,responseName)
		}
	}
	If $$$ISOK(sc),$$$ISERR(closeSequenceStatus) Set sc=closeSequenceStatus
	
	Quit sc
}

/// Send a %SOAP.RequestMessage subclass instance as a request message
/// The arguments to this method are:<br> 
///  Action is the SOAPAction for the SOAP request.<br>
///  If OneWay is 1 (true) then no response is expected.<br> 
///  Request is the %SOAP.RequestMessage subclass instance.<br>
///  MethodName is an optional name of the method being called which is used to select the WS-Policy.<br>
/// The response message node will be set in the ResponseDocuemtn and ResponseNodeId properties of %SOAP.RequestMessage.
Method SendSOAPRequest(action As %String, oneWay As %Boolean = 0, request As %SOAP.RequestMessage, methodName As %String) As %Status [ ServerOnly = 1 ]
{
	If ..HttpRequester="BINARY" Quit $$$ERROR($$$SOAPNoBinary)
	
	Set ..MethodName=$get(methodName)
	Quit ..InvokeClient(request,"",action,oneWay)
}

/// Execute the Web Method represented by the descriptor class on
/// the server.  If an error is detected, a ztrap "SOAP" will be issued with
/// %objlasterror containing the error %Status.  If is the responsibilty of the
/// caller of the proxy method to set an error trap and test for $ZE["&lt;ZSOAP&gt;".
/// Note that if a SOAP fault is received, then the error is $$$SOAPFaultReceived.
/// 
/// If method argument is "", then this is an internal call to send the XML body.
/// In this case proxy is the character stream containing the body.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
Method InvokeClient(proxy As %SOAP.ProxyDescriptor, method As %String, Action As %String, OneWay As %Boolean = 0) As %Status [ Internal, ServerOnly = 1 ]
{
	New %cspsoapSecurityHeader
	#; Initialize to no SOAP fault received.
	Set ..SoapFault=""
	Set sc=$$$OK,error=0
	Set io=""
	If method'="" Set ..MethodName=method
	
	#; Get transport if supplied.
	Set transport=..Transport

	/// Enables filtering on process, that checks whether the LogFile is too big or there
	/// are LogConfig present ( "LogJob", "LogClass", "LogURL")
	/// Needs to be carried out upstream from SOAP.Binary to achieve correct class filtering
	$$$CheckSOAPLogConfig(..Location,..%ClassName(1),$$$SOAPLogStopFlag,logStep)
	
	#; Handle Cache proprietary binary SOAP protocol
	If ..SoapBinary {
		#; Get list of SOAP Headers
		Set ..SoapHeaders=..#SOAPHEADERS
	
		#; If no action specified, use the method name from the proxy class.
		If $tr(Action,"""","")="" Set Action=$$$ClassShortName($zobjclass(proxy))
		
		Set charset=$$GetCharset^%SYS.NLS()
		Set asUTF8=((charset="") || (charset'=..SoapBinaryCharset))
		Set binwriter=..GetBinaryWriter(proxy,1,asUTF8)
		If (('$$$CheckSOAPLogStop)&&($$$CheckSOAPLogOutput)) Do binwriter.LogOutputStart(0,Action)
		If +..HTTPVersion>1.0 {
			// Chunked output for HTTP/1.1
			Set stream=binwriter
		} Else {
			Set io=$io
			Set stream=##class(%FileBinaryStream).%New()
			Set sc=stream.Write("") ; force stream's file to open
			If $$$ISERR(sc) Goto SOAPError
			Set file=stream.Filename ; get filename and make current device
			Use file:(/NOXY)
			$$$SETIO("RAW")
			Set binwriter.Chunked=0
			Do binwriter.OutputStream()
			Use io
			kill binwriter
			If $$$ISERR(sc) Goto SOAPError
		}
	
		#; Use transport to get response.
		If transport="" {
			Set transport=$this
			// Try to use string for response if our built-in transport
			Set responseStream="string"
		} Else {
			Set responseStream=##class(%GlobalBinaryStream).%New()
		}
	
		$$$SOAPTimer("creq")
		#; Callback before DoSOAPRequest
		Do ..%OnSOAPRequest("binary",$this,Action,OneWay,method,stream)
		#; Make the request
		Set sc=transport.DoSOAPRequest($this,Action,OneWay,stream,.responseStream)
		#; Callback after DoSOAPRequest
		Do ..%OnSOAPResponse("binary",$this,Action,OneWay,method,stream,.responseStream,sc)
	
		#; Log the response
		$$$SOAPTimer("cres")
		Do:'$$$CheckSOAPLogStop ##class(%SOAP.Binary).LogMessage(0,Action,responseStream,sc)

		If $$$ISERR(sc) Goto SOAPError
	
		#; If one-way, check for empty response
		If OneWay {
			If $isobject(responseStream) {
				Do responseStream.Rewind()
				Set len=1
				Set data=responseStream.Read(.len,.sc)
				If $$$ISERR(sc) Goto SOAPError
				Do responseStream.Rewind()
				If len<=0 Set sc=$$$OK Goto SOAPExit
			} Else {
				If responseStream="" Set sc=$$$OK Goto SOAPExit
			}
		}
	
		If 'OneWay {
			#; Reset any INOUT properties
			Do proxy.Reset()
			#; Import the SOAP response.
			#; Deserialize the message class
			if '$isobject(responseStream) {
				set responseStream=##class(%SOAP.BufferedStream).%New(responseStream)
			}
			Set sc=..ReadBinaryMessage(proxy,.asUTF8,.sessionFlag,responseStream)
			If $$$ISERR(sc) Goto SOAPError
			#; return no session cookie, if session not wanted
			If 'sessionFlag,..HttpRequest'="" Do ..HttpRequest.DeleteSessionCookie()
		}
		$$$SOAPTimer("cret")
		Goto SOAPExit
	}
	
	#; If in a SOAP session then add the SOAP session header
	If ..SessionCookie'="" {
		Set sessionHeader=##class(%SOAP.SessionHeader).%New()
		Set sessionHeader.SessionCookie=..SessionCookie
		Do ..HeadersOut.SetAt(sessionHeader,"CSPCHD")
	}
	
	#; Add Sequence and SequenceAcknowledgement headers if RM session
	If $isobject(..RMSession),'..RMSession.Terminated {
		If ..RMSession.ResponseIdentifier'="",..RMSession.MessageNumber>0 {
			Do ..HeadersOut.SetAt(##class(%SOAP.RM.SequenceAcknowledgement).CreateHeader(..RMSession,1),"SequenceAcknowledgement")
		}
		Set ..RMSession.MessageNumber=..RMSession.MessageNumber+1
		Do ..HeadersOut.SetAt(##class(%SOAP.RM.Sequence).CreateHeader(..RMSession,1),"Sequence")
	}
	
	#; Find WS-Policy alternative
	Set ..Action=Action
	Set ..OneWay=OneWay
	Set originalSecurityOut=r%SecurityOut
	Set sc=##class(%SOAP.Policy).ProcessSendAlternative($this,..MethodName,.sendAlternative)
	If $$$ISERR(sc) Goto SOAPError

	#; Get list of SOAP Headers
	Set ..SoapHeaders=..#SOAPHEADERS
	
	#; Create WS-Security header with UsernameToken, if neeeded
	If ..Username'="" Do ..MakeSecurityHeader()
	
	#; Setup WS-Addressing if required.
	If '$data(sendAlternative),..AddressingOut="",$zcvt(..#WSADDRESSING,"U")="AUTO" {
		Set action=##class(%SOAP.WebParameters).GetAction($classname(),..MethodName,"request")
		If action="" Set action=Action
		Set ..AddressingOut=##class(%SOAP.Addressing.Properties).GetDefaultRequestProperties(..Location,action,..WSANamespace)
	}
	
	Set ..IsMTOM=0
	Set allowedVersion=..#SOAPVERSION
	If allowedVersion="" {
		If ..SoapVersion="" Set ..SoapVersion="1.1"
	} ElseIf ..SoapVersion="" {
		Set ..SoapVersion=allowedVersion
	} Else {
		If allowedVersion'=..SoapVersion {
			Set sc=$$$ERROR($$$SOAPBadVersion,..SoapVersion) 
			Goto SOAPError
		}
	}

	#; Initialize any WS-Security operations.
	Set wsRequired=..InitializeSecurity(.sc)
	If $$$ISERR(sc) Goto SOAPError
	
	#; Check SoapVersion
	If $case(..SoapVersion,"":0,"1.1":0,"1.2":0,:1) {
		Set sc=$$$ERROR($$$SOAPBadVersion,..SoapVersion)
		Goto SOAPError
	}

	#; Create SOAP request
	$$$XMLUseGlobal
	Set sc=..WriteHTTPContent(proxy,proxy.%RequestName,0,wsRequired,,"")
	If $$$ISERR(sc) Goto SOAPError

	#; Send SOAP request and get response
	$$$SOAPTimer("creq")
	If (..RMSession="") || (..RMSession.Terminated) {
		Set sc=..SOAPRequestResponse(proxy,method,.retryAllowed)

		Set sequence=..HeadersIn.GetAt("Sequence")
		If $classname(sequence)'="%SOAP.RM.Sequence" Set sequence=""
		Set ack=..HeadersIn.GetAt("SequenceAcknowledgement")
		If $classname(ack)'="%SOAP.RM.SequenceAcknowledgement" Set ack=""

		If $$$ISOK(sc), (sequence'="") || ((ack'="") && (..Action'=($$$SOAPWSRMns_"/CloseSequence")) && (..Action'=($$$SOAPWSRMns_"/TerminateSequence"))) {
			Set sc=$$$ERROR($$$RMUnexpectedHeader,$select(sequence'="":"Sequence",1:"SequenceAcknowledgement"))
		}
	} Else {
		$$$XMLSave(streamSave)
		Set ..HttpForceReuseDevice=..RMSession.SSLSecurity
		For i=1:1:..RMSession.MaxRetryCount {
			Set sc=..SOAPRequestResponse(proxy,method,.retryAllowed)
			
			If 'retryAllowed Quit

			If $$$ISOK(sc) {
				Set sequence=..HeadersIn.GetAt("Sequence")
				If sequence'="",$classname(sequence)'="%SOAP.RM.Sequence" Set sequence=""

				If ..RMSession.ResponseIdentifier'="" {
					If '$isobject(sequence) {
						Set sc=$$$ERROR($$$RMExpectedHeader)
						Quit
					}
					If '..RMSession.CheckSCT($this) {
						Set sc=$$$ERROR($$$RMUnexpectedHeader,"No SecurityContextToken, "_..RMSession.SCTIdentifier_", for Sequence with Identifier = "_sequence.Identifier)
						Quit
					}
					If sequence.Identifier'=..RMSession.ResponseIdentifier {
						Set sc=$$$ERROR($$$RMUnexpectedHeader,"Sequence with Identifier = "_sequence.Identifier)
						Quit
					}
					If sequence.MessageNumber'=..RMSession.MessageNumber {
						Set sc=$$$ERROR($$$RMUnexpectedMessageNumber)
						Quit
					}
					$$$SOAPLogSecurity("Receive Sequence. MessageNumber="_sequence.MessageNumber)
				} ElseIf $isobject(sequence) {
					Set sc=$$$ERROR($$$RMUnexpectedHeader,"Sequence")
					Quit
				}
			}

			Set ack=..HeadersIn.GetAt("SequenceAcknowledgement")
			If $classname(ack)'="%SOAP.RM.SequenceAcknowledgement" Set ack=""
			If $isobject(ack) {
				If ack.Identifier'=..RMSession.RequestIdentifier {
					Set sc=$$$ERROR($$$RMUnexpectedHeader,"SequenceAcknowledgement for Identifier "_ack.Identifier)
					Quit
				}
				Do ack.UpdateSession(..RMSession)
				$$$SOAPLogSecurity("Receive SequenceAcknowledgement.")
				If ..RMSession.GetMessageState(..RMSession.MessageNumber) {
					Do ..RMSession.MessageOK()
					Quit
				}
				// Final indicates sequence terminated
				If ack.Final=$c(0) Quit
			} ElseIf $$$ISOK(sc) {
				Do ..RMSession.MessageOK()
				Quit
			}
			
			Hang ..RMSession.RetryInterval
			$$$XMLRestore(streamSave)
		}
	}
	
	$$$SOAPTimer("cret")
	If $$$ISERR(sc) Goto SOAPError

SOAPExit
	#; Callback after all done
	Do ..%OnSOAPFinished($select(..SoapBinary:"binary",1:"SOAP"),$this,method,sc)

	If io'="" Use io
	// Restore SecurityOut to a state that it can be reused for next call
	If $get(wsRequired) || $isobject(r%SecurityOut) {
		If $data(sendAlternative) {
			// If WS-Policy created SecurityOut, Restore caller's SecurityOut
			Set ..SecurityOut=originalSecurityOut
		} Else {
			// Just reset code created SecurityOut
			Do ..ResetSecurity()
		}
	}
	Set ..KeepSessionCookie=0
	Do ..HeadersOut.Clear()
	Set ..AddressingOut=""
	Set ..NamespacesOut=""
	If ..Username'="" {
		Set (..Username,..Password)=""
		If $isobject(r%SecurityOut) {
			Do r%SecurityOut.RemoveElement("UsernameToken")
		}
	}
	Set ..ContentType=""
	If error {
	    Set %objlasterror=sc 
		If (('$$$CheckSOAPLogStop)&&($$$CheckSOAPLogInput || $$$CheckSOAPLogSecurity)) {
			Kill err
			Do $system.Status.DecomposeStatus(sc,.err)
			$$$SOAPLogText("**** SOAP client return error. method="_method_", action="_Action)
			$$$SOAPLogText("     "_err(1)_$c(13,10)_$c(13,10))
		}
	    if method'="" Ztrap "SOAP"
	}
	Quit sc

SOAPError 
	Set error=1
	Goto SOAPExit
}

/// Send SOAP request and process response
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.
Method SOAPRequestResponse(proxy As %SOAP.ProxyDescriptor, method As %String, Output retryAllowed As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	Set retryAllowed=0
	Do ..HeadersIn.Clear()
	Set ..SecurityIn=""

	#; Use transport to get response.
	Set transport=..Transport
	If transport="" {
		Set transport=$this
		// Try to use string for response if our built-in transport
		Set responseStream="string"
		Set stream=0
	} Else {
		Set responseStream=##class(%GlobalBinaryStream).%New()
		#; If user supplied transport, we need to pass real stream
		Set stream=##class(%FileBinaryStream).%New()
		Set sc=stream.Write("") ; force stream's file to open
		If $$$ISERR(sc) Quit sc
		Set iofile=$io
		Set file=stream.Filename ; get filename and make current device
		Use file:(/NOXY)
		$$$XMLOutputBuffer
		Use iofile
	}
	
	#; Callback before DoSOAPRequest
	Do ..%OnSOAPRequest("SOAP",$this,..Action,..OneWay,method,stream)
	#; Make the request
	Set sc=transport.DoSOAPRequest($this,..Action,..OneWay,stream,.responseStream)
	#; Callback after DoSOAPRequest
	Do ..%OnSOAPResponse("SOAP",$this,..Action,..OneWay,method,stream,.responseStream,sc)
	$$$XMLUseRestore

	#; Log the response
	$$$SOAPTimer("cres")
	$$$SOAPLogInput(0,..Action,responseStream,sc)

	#; If HTTP error encountered, return error and allow retry 
	If $$$ISERR(sc) {
		#; Retry unless SSL session security and same socket (and hence same SSL session) cannot be reused.
		If $$$ERRORCODE(sc)'=$$$ERRORCODE($$$HttpSocketClosed) {
			Set retryAllowed=1
		}
		Quit sc
	}

	#; If one-way, check for empty response
	If $isobject(responseStream) {
		Do responseStream.Rewind()
		If ..OneWay {
			Set len=1
			Set data=responseStream.Read(.len,.sc)
			If $$$ISERR(sc) Quit sc
			Do responseStream.Rewind()
			If len<=0 Quit $$$OK
		}
	} Else {
		If responseStream="" Quit $$$OK
	}

	#; Get an entity resolver
	Set tResolver=##Class(%XML.SAX.EntityResolver).%New()
	If '$isObject(tResolver) Set sc=$$$ERROR($$$CannotCreateObject,"%XML.SAX.EntityResolver") Quit sc
	#; Parse the message into XML DOM
	if '$isobject(responseStream) {
		set responseStream=##class(%SOAP.BufferedStream).%New(responseStream)
	}

	// Process response with content-type=multipart/related
	Set responseAttachments=""
	Set response=..HttpResponse
	If $isobject(response) && ($zcvt($piece(response.ContentType,";",1),"L")="multipart/related") {
		If ##class(%Net.HttpRequest).ParseContent(response.ContentInfo,.tmparray) {
			Quit $$$ERROR($$$CSPInvalidContentType,response.ContentType)
		}
		If $case($get(tmparray("type")),"text/xml":0,"application/soap+xml":0,"application/xop+xml":0,:1) {
			Quit $$$ERROR($$$SOAPBadMultipart,response.ContentType)
		}

		If tmparray("type")="application/xop+xml" {
			Set ..IsMTOM=1
			Set responseAttachments=..ResponseAttachments
			Set start=##class(%Net.MIMEPart).NormalizeContentId($get(tmparray("start")))
			Set startindex=$select(start="":1,1:0)
		} Else {
			Set start=""
			Set startindex=1
		}

		Set msg=##class(%Net.MIMEPart).%New()
		do msg.SetHeader("Content-Type",response.ContentType)
		Set reader=##class(%Net.MIMEReader).%New()
		Set sc=reader.OpenStream(responseStream)
		If $$$ISERR(sc) Quit sc
		Set sc=reader.ReadMIMEBody(msg)
		If $$$ISERR(sc) Quit sc
		If msg.Parts.Count()<1 {
			Quit $$$ERROR($$$SOAPBadMultipart,response.ContentType)
		}

		For index=1:1:msg.Parts.Count() {
			Set part=msg.Parts.GetAt(index)
			Do ..ResponseAttachments.Insert(part)
			If (startindex=0) && (start=part.ContentId) {
				Set startindex=index
			}
		}

		If startindex=0 {
			Quit $$$ERROR($$$SOAPBadMultipart,response.ContentType)
		}

		Set part=msg.Parts.GetAt(startindex)
		If ..IsMTOM {
			If $zcvt($piece(part.ContentType,";",1),"L")'="application/xop+xml" {
				Quit $$$ERROR($$$SOAPBadMultipart,part.ContentType)
			}
		} Else {
			If $case($zcvt($piece(part.ContentType,";",1),"L"),"text/xml":0,"application/soap+xml":0,"application/xop+xml":0,:1) {
				Quit $$$ERROR($$$SOAPBadMultipart,part.ContentType)
			}
		}
		Set responseStream=part.Body
		Set ..ResponseContentId=part.ContentId
		Set ..ResponseContentLocation=part.ContentLocation
		Do ..ResponseAttachments.RemoveAt(startindex)
	}
	
	#; Get an XML content handler that parses message into XML DOM 
	Set tHandler=##class(%XML.Reader).GetNewDocument(..UsePPGHandler)
	If '$isObject(tHandler) Quit $$$ERROR($$$CannotCreateObject,"%XML.Document")
	Set tHandler.KeepWhitespace=1 // Need whitespace for XMLImport

	#; set SAXFlags to always prohibit DTDs
	Set saxflags=$zboolean(..SAXFlags,$$$SAXVALIDATIONPROHIBITDTDS,7)
	#; Parse message
	Set sc=##Class(%XML.SAX.Parser).ParseStream(responseStream,tHandler,tResolver,saxflags)
	If $$$ISERR(sc) Quit sc
	Set ..ImportHandler=tHandler
	$$$SOAPTimer("cp")

	#; Make sure to process session and security headers
	Set headers=..SoapHeaders
	If headers="" {
		Set headers="Security:%SOAP.Security.Header,CSPCHD:%SOAP.SessionHeader"
	} Else {
		Set headers=","_headers
		If headers'[",Security:" Set headers=headers_",Security:%SOAP.Security.Header"
		If headers'[",CSPCHD:" Set headers=headers_",CSPCHD:%SOAP.SessionHeader"
		Set headers=$extract(headers,2,*)
	}
	Set ..SoapHeaders=headers
	$$$SOAPLogSecurity($c(13,10)_"---------------"_$c(13,10)_"Validate Security header: action="_..Action_", MethodName="_..MethodName)

	#; Validate the SOAP envelope. 
	Set sc=..CheckSOAPEnvelope(.tHandler,..OneWay,.soapenv,.message,.messageChildlist,.versionMismatch)
	If $$$ISOK(sc) {
		Set sc=..ProcessSOAPEnvelope(.tHandler,soapenv,.message,.messageChildlist,responseAttachments)
	}
	$$$SOAPTimer("cenv")
	Set faultStatus=$$$OK
	If $$$ISERR(sc) {
		If ..SoapFault'="",..RMSession'="",'..RMSession.Terminated {
			#; Process headers even if SOAP fault received
			Set faultStatus=sc
			Set sc=$$$OK
		} Else {
			Quit sc
		}
	}
	
	#; Save the WS-Security header
	Set header=..HeadersIn.GetAt("Security")
	If (header'="") && ($zobjclass(header)="%SOAP.Security.Header") {
		Set ..SecurityIn=header
		Set ..SecurityNamespace=header.Namespace
	} Else {
		If $zcvt(..#SECURITYIN,"L")="require" {
			Quit $$$ERROR($$$SOAPWSSECURITYRequired)
		}
		Set ..SecurityIn=""
		Set ..SecurityNamespace=""
	}
	
	#; Process session header	
	Set header=..HeadersIn.GetAt("CSPCHD")
	If (header'="") && ($zobjclass(header)="%SOAP.SessionHeader") {
		Set sc=header.ProcessClient($this)
		If $$$ISERR(sc) Quit sc
	}
	
	If $$$ISOK(faultStatus) {
		#; Validate the WS-Policy policy that applies to this service
		Set sc=##class(%SOAP.Policy).ProcessReceiveAlternative($this,..MethodName,.receiveAlternative)
		If $$$ISERR(sc) Quit sc
	
		#; Import SOAP body.
		$$$SOAPTimer("chdr")
		If '..OneWay {
			If method'="" {
				#; Reset any INOUT properties
				Do proxy.Reset()
				#; Import the SOAP response.
				Set sc=proxy.ImportSOAPMessage(..MethodName_"Response",..MethodName_"Result",tHandler,message,messageChildlist,responseAttachments,..#SOAPCHECKREQUIRED)
			} Else {
				// method="" for %SOAP.WebRequest
				Set sc=proxy.ReturnResponse(tHandler,message)
			}
		}
	}
	
	If $$$ISOK(sc) {
		If $$$ISERR(faultStatus) Set sc=faultStatus
		Set retryAllowed=1
	}
	Quit sc
}

/// Default transport for HTTP protocol
/// %SOAP.WebClient acts as its own transport class.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
Method DoSOAPRequest(Client As %SOAP.WebClient, Action As %String, OneWay As %Boolean, requestStream As %BinaryStream, ByRef responseStream As %BinaryStream) As %Status [ Internal, ServerOnly = 1 ]
{
	#; Send SOAP request to server
	Set request=..HttpRequest
	If request="" {
		Set request=##class(%Net.HttpRequest).%New()
		Set ..HttpRequest=request
	} ElseIf '..KeepSessionCookie,'..SoapBinary,..SessionCookie="" {
		Do request.DeleteSessionCookie()
	}
	Set request.HTTPVersion=..HTTPVersion
	If ..Timeout'="" Set request.Timeout = ..Timeout
	If ..OpenTimeout'="" Set request.OpenTimeout = ..OpenTimeout
	If ..SSLCheckServerIdentity'="" Set request.SSLCheckServerIdentity=..SSLCheckServerIdentity
	If ..GzipOutput'="" Set request.PostGzip=..GzipOutput
	If ..HttpFollowRedirect'="" Set request.FollowRedirect = ..HttpFollowRedirect
	If ..HttpProxyServer'="" Set request.ProxyServer = ..HttpProxyServer
	If ..HttpProxyPort'="" Set request.ProxyPort = ..HttpProxyPort
	If ..HttpProxyTunnel'="" Set request.ProxyTunnel = ..HttpProxyTunnel
	If ..HttpProxyAuthorization'="" Set request.ProxyAuthorization = ..HttpProxyAuthorization
	If ..HttpRequestHeaderCharset'="" Set request.RequestHeaderCharset = ..HttpRequestHeaderCharset
	If ..HttpUsername'="" Set request.Username = ..HttpUsername
	If ..HttpPassword'="" Set request.Password = ..HttpPassword
	If ..HttpInitiateAuthentication'="" Set request.InitiateAuthentication=..HttpInitiateAuthentication
	If ..HttpWriteTimeout'="" Set request.WriteTimeout = ..HttpWriteTimeout
	Set request.ReadRawMode=1  ; no translation needed
	Set request.WriteRawMode=1  ; request stream ready to write without translation
	Set request.ResponseStream=responseStream
	Set request.ForceReuseDevice=..HttpForceReuseDevice
	If requestStream=0 {
		Set request.SOAPBuffering=1
	} Else {
		Set request.EntityBody=requestStream
	}
	Set sc=$$$OK
	Set ..SSLError=""
	For i=1:1:$get(i%HttpHeaders,0) {
		Set header=i%HttpHeaders(i)
		Set sc=request.SetHeader($list(header,1),$list(header,2))
		If $$$ISERR(sc) Quit
	}
	If $$$ISERR(sc) Quit sc
	Set contenttype=..ContentType
	If ..SoapBinary {
		Do request.SetHeader("ISCSoap",Action)
		If contenttype="" Set contenttype="application/octet-stream"
		Set sc=request.SetHeader("Content-Type",contenttype)
		If $$$ISERR(sc) Quit sc
		#; Note that newer systems should pass 'IRISUsername' etc but keep passing 'CacheUserName' for backward compatiblity when talking to older systems
		If ..Username'="" {
			Do request.SetParam("CachePassword",..Password)
			Do request.SetParam("CacheUserName",..Username)
		} Else {
			Do request.DeleteParam("CachePassword")
			Do request.DeleteParam("CacheUserName")
		}
	} Else {
		Set soap12=(..SoapVersion="1.2")
		If 'soap12 {
			Set quote=$select(..#SOAPACTIONQUOTED:"""",1:"")
			Do request.SetHeader("SOAPAction",quote_$Select(..#URLESCAPESOAPACTION:$ZCVT(Action,"O","URL"),1:Action)_quote)
		}
		If contenttype="" {
			Set contenttype=""_$select(soap12:"application/soap+xml",1:"text/xml")_"; charset=UTF-8"
			If soap12 Set contenttype=contenttype_"; action="""_Action_""""
		}
		Set sc=request.SetHeader("Content-Type",contenttype)
		If $$$ISERR(sc) Quit sc
		If $zcvt($piece(contenttype,";",1),"L")="multipart/related" {
			Set sc=request.SetHeader("MIME-Version","1.0")
			If $$$ISERR(sc) Quit sc
		}
	}
	If ..Location="" Quit $$$ERROR($$$SOAPNoLocation)
	Set protocol=$zcvt($piece(..Location,"://"),"L")
	If $case(protocol,"http":0,"https":0,:1) Quit $$$ERROR($$$SOAPHttpOnly) 
	If (request.ProxyServer'="")&&(+(request.ProxyPort)'=0) {
		Set request.ProxyHTTPS=(protocol="https")
		If ..HttpProxySSLConnect {
			Set request.Https=1
		} ElseIf ((..HttpProxyTunnel||request.ProxyTunnel)&&(protocol="https")) {
			Set request.SSLConfiguration=..SSLConfiguration
		}
	} Else {
		Set request.Https=(protocol="https")
	}
	If request.Https Set request.SSLConfiguration=..SSLConfiguration
	Set Location=$piece(..Location,"://",2,16000)
	Set host=$piece(Location,"/",1)
	Set request.Server=$piece(host,":",1)
	If $length(host,":")>1 Set request.Port=$piece(host,":",2)
	If $length(Location,"?")>1 {
		Set Location=##class(%CSP.Page).EscapeURL($piece(Location,"?",1),"UTF8")_"?"_$piece(Location,"?",2,$length(Location,"?"))
	} Else {
		Set Location=##class(%CSP.Page).EscapeURL(Location,"UTF8")
	}
	$$$SOAPLogOutputHTTPHeaders
	Set sc=request.Post($piece(Location,"/",2,$length(Location,"/")))
	$$$SOAPLogInputHTTPHeaders
	If $$$ISERR(sc) Set ..SSLError=request.SSLError Quit sc
	Set response=request.HttpResponse
	Set ..HttpResponse=response
	Set responseStream=response.Data
	Set responseStatus=response.StatusCode

	#; 202 response OK for one-way messages.
	If OneWay,(responseStatus="202") || (responseStatus="200") Quit $$$OK

	#; If HttpAccept202, treat status 202 as 200.
	If ..HttpAccept202,responseStatus=202 Set responseStatus=200

	#; Check response
	If $case(responseStatus,"200":0,"201":0,"400":0,"500":0,:1) {
		Quit $$$ERROR($$$SOAPUnexpectedStatus,response.StatusCode)
	}

	If responseStream="" Quit $$$ERROR($$$SOAPNoResponseBody)
 
	Set responseContentType=$zcvt($piece(response.ContentType,";",1),"L")
	If ..SoapBinary {
		If (responseContentType'="application/octet-stream") Quit $$$ERROR($$$SOAPUnexpectedType,response.ContentType)
	} Else {
		If (responseContentType'="text/xml") && 
		   (responseContentType'="application/soap+xml") &&
		   (responseContentType'="multipart/related") {
			Quit $$$ERROR($$$SOAPUnexpectedType,response.ContentType)
		}
	}
 
	Quit $$$OK
}

/// Log the HTTP headers associated with an input SOAP message.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method LogInputHTTPHeaders() [ Internal, ServerOnly = 1 ]
{
	If $$$CheckSOAPLogStop Quit
	// Nothing to do if no HttpRequest or HttpResponse object
	If '$isobject(..HttpRequest) || '$isobject(..HttpRequest.HttpResponse) Quit
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

		Write !,!,"**** Input HTTP headers for Web Client",!
		Do ..HttpRequest.HttpResponse.OutputHeaders($$$CheckSOAPTestMode)
		
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
Method LogOutputHTTPHeaders() [ Internal, ServerOnly = 1 ]
{
	If $$$CheckSOAPLogStop Quit
	// Nothing to do if no HttpRequest object
	If '$isobject(..HttpRequest) Quit
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

		Write !,!,"**** Output HTTP headers for Web Client",!
		Set auth = ..HttpRequest.Authorization
		If auth'="" {
			Do ..HttpRequest.RemoveHeader("Authorization")
			Set ..HttpRequest.Authorization = $piece(auth," ",1)_" "_$$$PasswordMask
		}
		Write ..HttpRequest.ReturnHeaders()
		If auth'="" {
			Do ..HttpRequest.RemoveHeader("Authorization")
			Set ..HttpRequest.Authorization = auth
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

/// This method is a callback which will be invoked before invoking transport.DoSOAPRequest() method
/// to make the actual SOAP request.  This method may be override by the user's web client class.
/// DoSOAPRequest is the transport method which is responsible for sending the SOAP request and receiving the response.
/// The default DoSOAPRequest is included in %SOAP.WebClient and uses HTTP for request/response.<br><br>
/// 
/// The mode argument specifies the type of SOAP request "SOAP" or "binary".<br>
/// The client argument is the oref of the web client class.<br>
/// The action argument contains the value of the SOAPAction.<br>
/// The oneWay argument is true if no body is to be sent.
/// The method argument is the name of the WebMethod that is being invoked<br>
/// The requestStream argument contains the SOAP request message in a stream.
/// requestStream may =0 as an optimization to improve SOAP performance.
/// requestStream=0 means that the stream is kept in memory as much as possible with overflow to a global.
/// requestStream may be accessed by using $$$XMLRewind and $$$XMLRead macros.<br>
Method %OnSOAPRequest(mode As %String, client As %SOAP.WebClient, action As %String, oneWay As %Boolean, method As %String, requestStream As %BinaryStream)
{
	Quit
}

/// This method is a callback which will be invoked after invoking transport.DoSOAPRequest() method
/// that made the actual SOAP request.  This method may be override by the user's web client class.
/// DoSOAPRequest is the transport method which is responsible for sending the SOAP request and receiving the response.
/// The default DoSOAPRequest is included in %SOAP.WebClient and uses HTTP for request/response.<br><br>
/// 
/// The mode argument specifies the type of SOAP request "SOAP" or "binary".<br>
/// The client argument is the oref of the web client class.<br>
/// The action argument contains the value of the SOAPAction.<br>
/// The oneWay argument is true if no body is to be sent.
/// The method argument is the name of the WebMethod that is being invoked<br>
/// The requestStream argument contains the SOAP request message in a stream.<br><br>
/// The responseStream argument contains the SOAP response message in a stream.<br>
/// The sc argument is the %Status that was returned by DoSOAPRequest.
Method %OnSOAPResponse(mode As %String, client As %SOAP.WebClient, action As %String, oneWay As %Boolean, method As %String, requestStream As %BinaryStream, responseStream As %BinaryStream, sc As %Status)
{
	Quit
}

/// This method is a callback which will be invoked after all processing of the web client call
/// has been completed.  This method may be override by the user's web client class.<br><br>
/// 
/// The mode argument specifies the type of SOAP request "SOAP" or "binary".<br>
/// The client argument is the oref of the web client class.<br>
/// The method argument is the name of the WebMethod that is being invoked<br>
/// The sc argument is the %Status for this method.  sc will be be $$$OK unless an error has been detected.
Method %OnSOAPFinished(mode As %String, client As %SOAP.WebClient, method As %String, sc As %Status)
{
	Quit
}

}
