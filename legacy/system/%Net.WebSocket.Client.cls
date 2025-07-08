/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %Net.WebSocket

/// Implements a WebSocket client. <br />
/// Usage: <br />
/// <ul>
/// <li>Implement %Net.WebSocket.IEventListener to respond to events (most importantly, receipt of a message).</li>
/// <li>Implement %Net.WebSocket.ICredentials to provide a username/password/SSLConfiguration for the connection as needed.</li>
/// <li>Create a new instance of <class>%Net.WebSocket.Client</class>, providing a WebSocket URL and instances of the ICredentials and IEventListener implementations.</li>
/// <li>Call <method>Next</method> to wait for the next message, and <method>Send</method> to send a message.<li>
/// </ul>
Class %Net.WebSocket.Client Extends %RegisteredObject [ Final ]
{

/// WebSocket endpoint
Property URL As %String [ ReadOnly ];

/// Provides username, password, and SSL configuration
Property Credentials As %Net.WebSocket.ICredentials [ Private ];

/// Handles open, close, message, and error events
Property EventListener As %Net.WebSocket.IEventListener [ Private ];

/// The HTTP request, wrapping use of the device used for communcation
Property Request As %Net.HttpRequest [ Private ];

/// Base64-encoded 16-byte random value provided to the server for validation
Property Nonce As %String [ InitialExpression = {$System.Encryption.Base64Encode($System.Encryption.GenCryptRand(16))}, Private ];

/// Accepted protocols (Sec-WebSocket-Protocol request header)
Property AcceptedProtocols As %String [ Private ];

/// The actual protocol in use (Sec-WebSocket-Protocol response header)
Property Protocol As %String [ Private ];

Method %OnNew(pURL As %String, pCredentials As %Net.WebSocket.ICredentials = {$$$NULLOREF}, pEventListener As %Net.WebSocket.IEventListener = {$$$NULLOREF}, pAcceptedProtocols As %String = "", pRequest As %Net.HttpRequest = {$$$NULLOREF}) As %Status
{
	Try {
		// Validation
		If ($Get(pURL) = "") {
			$$$ThrowStatus($$$ERROR($$$NetWebSocketErrURLRequired))
		}
		
		Set i%URL = pURL
		Set ..Credentials = pCredentials
		Set ..EventListener = pEventListener
		Set ..AcceptedProtocols = pAcceptedProtocols
		
		If $IsObject(pRequest) {
			// Pre-configured request
			Set ..Request = pRequest
		}
		
		Do ..EstablishConnection()
	} Catch e {
		If $IsObject(..EventListener) {
			Do ..EventListener.OnError(e)
		}
		Throw e
	}
	
	Quit $$$OK
}

/// Makes the initial HTTP request and negotiates the upgrade to WebSocket protocol
Method EstablishConnection() [ Private ]
{
	Do ##class(%Net.URLParser).Parse(..URL,.tComponents)
	If '$IsObject(..Request) {
		Set ..Request = ##class(%Net.HttpRequest).%New()
	}
	Set ..Request.Server = tComponents("host")
	If $Data(tComponents("port")) {
		Set ..Request.Port = tComponents("port")
	}

	// TODO: scheme/fragment validation
	
	// SSL Configuration
	If (..Request.SSLConfiguration = "") {
		If ($ZConvert($Get(tComponents("scheme")),"L") = "wss") || ($ZConvert($Get(tComponents("scheme")),"L") = "https") {
			Set ..Request.Https = 1
			If $IsObject(..Credentials) {
				Set ..Request.SSLConfiguration = ..Credentials.GetSSLConfiguration()
			}
		}
	}
		
	// WebSocket headers - for example:
	/*
		GET /chat HTTP/1.1
		Host: server.example.com
		Upgrade: websocket
		Connection: Upgrade
		Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
		Origin: http://example.com
		Sec-WebSocket-Protocol: chat, superchat
		Sec-WebSocket-Version: 13
	*/
	Do ..Request.SetHeader("Upgrade","websocket")
	Do ..Request.SetHeader("Connection","Upgrade")
	Do ..Request.SetHeader("Sec-WebSocket-Version","13")
	Do ..Request.SetHeader("Sec-WebSocket-Key",..Nonce)
	Set ..Request.AcceptGzip = 0
	If (..AcceptedProtocols '= "") {
		Do ..Request.SetHeader("Sec-WebSocket-Protocol",..AcceptedProtocols)
	}
	
	// TODO: Support Sec-WebSocket-Extensions
	
	// Establish connection
	Set tQueryParams = $Case(tComponents("query"),"":"",:$ListBuild(tComponents("query")))
	If $IsObject(..Credentials) {
		Set tUserName = ..Credentials.GetUsername()
		Set tPassword = ..Credentials.GetPassword()
		If (tUserName '= "") {
			Set tQueryParams = tQueryParams_$ListBuild("CacheUserName="_$ZConvert(tUserName,"O","URL"))
			If (tPassword '= "") {
				Set tQueryParams = tQueryParams_$ListBuild("CachePassword="_$ZConvert(tPassword,"O","URL"))
			}
		}
	}
	Set tQueryParams = $ListToString(tQueryParams,"&")
	Set tSC = ..Request.Get(tComponents("path")_$Case(tQueryParams,"":"",:"?"_tQueryParams))
	$$$ThrowOnError(tSC)
	
	$$$ThrowOnError(..ValidateProtocolSwitch())
	
	If $IsObject(..EventListener) {
		Do ..EventListener.OnOpen()
	}
}

/// Ensures response headers are valid for upgrading to web sockets
Method ValidateProtocolSwitch() As %Status [ Private ]
{
	Set tSC = $$$OK
	
	// Validate response headers
	Set tResponse = ..Request.HttpResponse
	If (tResponse.StatusCode '= 101) {
		Set tSC = $$$ADDSC(tSC,$$$ERROR($$$NetWebSocketErrUpgradeFailed,"invalid response status code"))
	}
	If ($ZConvert(tResponse.GetHeader("Upgrade"),"L") '= "websocket") {
		Set tSC = $$$ADDSC(tSC,$$$ERROR($$$NetWebSocketErrUpgradeFailed,"invalid Upgrade header"))
	}
	If ($ZConvert(tResponse.GetHeader("Connection"),"L") '= "upgrade") {
		Set tSC = $$$ADDSC(tSC,$$$ERROR($$$NetWebSocketErrUpgradeFailed,"invalid Connection header"))
	}
	
	// Validate Sec-WebSocket-Accept
	Set tAcceptKey = tResponse.GetHeader("Sec-WebSocket-Accept")
	Set tExpectedKey = $System.Encryption.Base64Encode($System.Encryption.SHA1Hash(..Nonce_$$$WebSocketRFC6455GUID))
	If (tAcceptKey '= tExpectedKey) {
		Set tSC = $$$ADDSC(tSC,$$$ERROR($$$NetWebSocketErrUpgradeFailed,"invalid Sec-WebSocket-Accept header"))
	}
	
	// TODO: Validate Sec-WebSocket-Extensions
	
	// TODO: Validate Sec-WebSocket-Protocol
	
	Quit tSC
}

/// Waits for data from the server. Returns 1 if the connection remains open, and 0 if the connection is closed or an error occurs. <br />
/// The event listener will be notified upon receiving a message, or if the connection is closed or an error occurs. <br />
/// @Argument	pTimeout	Timeout (in seconds) to wait to receive a message from the server.
/// @Argument	pTimedOut	True if the read operation timed out.
Method Next(pTimeout As %Integer = 10, Output pTimedOut As %Boolean) As %Boolean
{
	Set tOpen = 1, pTimedOut = 0
	Try {
		$$$ThrowOnError(..Request.WebSocketRead(.tContent,pTimeout,.pTimedOut))
		If $IsObject(..EventListener) && 'pTimedOut {
			Do ..EventListener.OnMessage(tContent)
		}
	} Catch e {
		Set tSC = e.AsStatus()
		If $System.Status.Equals(tSC,$$$ERROR($$$NetWebSocketErrConnectionClosed)) {
			If $IsObject(..EventListener) {
				Do ..EventListener.OnClose()
			}
			Set tSC = $$$OK
		} ElseIf $IsObject(..EventListener) {
			Do ..EventListener.OnError(e)
		}
		Set tOpen = 0
	}
	Quit tOpen
}

/// Sends a binary or character stream, dynamic object, or string to the server.
/// @Argument	pContent		Binary or character stream, dynamic object, or string to the server.
/// @Argument	pFragmentSize	Maximum size (in bytes) to send in a single frame; 0 indicates no maximum.
Method Send(pContent, pFragmentSize As %Integer = 0) As %Status
{
	If $IsObject(pContent) {
		If pContent.%IsA("%Stream.Object") {
			Set tStream = pContent
		} ElseIf pContent.%IsA("%DynamicAbstractObject") {
			Set tStream = ##class(%Stream.TmpCharacter).%New()
			Do pContent.%ToJSON(.tStream)
		} Else {
			$$$ThrowStatus($$$ERROR($$$InvalidArgument))
		}
	} Else {
		Set tStream = ##class(%Stream.TmpCharacter).%New()
		Do tStream.Write(pContent)
	}
	Do tStream.Rewind()
	Quit ..Request.WebSocketWrite(tStream, pFragmentSize)
}

/// Sends a ping frame to the server. <br />
/// Returns $$$NetWebSocketErrPingTimeout if the ping times out <br />
/// Returns $$$NetWebSocketErrPongInvalid if the pong response is not equal to <var>pMessage</var> <br />
/// Otherwise, returns $$$OK
/// @Argument	pMessage		Message to send with the ping
/// @Argument	pFragmentSize	Timeout (in seconds) to wait to receive a "pong" back from the server.
Method Ping(pMessage As %String, pTimeout As %Integer = 10) As %Status
{
	Set tStream = ##class(%Stream.TmpBinary).%New()
	Do tStream.Write(pMessage)
	$$$ThrowOnError(..Request.WebSocketPing(tStream))
	If '..Next(.pTimeout) {
		Quit $$$ERROR($$$NetWebSocketErrPingTimeout)
	}
	
	If (..Request.LastPongContent.Read($$$MaxStringLength) '= pMessage) {
		Quit $$$ERROR($$$NetWebSocketErrPongInvalid)
	}
	
	Quit $$$OK
}

/// Sends an <b>unsolicited</b> pong frame to the server. <br />
/// @Argument	pMessage		Message to send with the pong
Method Pong(pMessage As %String) As %Status
{
	Set tStream = ##class(%Stream.TmpBinary).%New()
	Do tStream.Write(pMessage)
	Quit ..Request.WebSocketPong(tStream)
}

/// Closes the web socket connection from the client.
Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		$$$ThrowOnError(..Request.WebSocketClose())
		If $IsObject(..EventListener) {
			Do ..EventListener.OnClose()
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

}
