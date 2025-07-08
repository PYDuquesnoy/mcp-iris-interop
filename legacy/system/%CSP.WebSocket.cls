/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%cspGatewayRegistry, %occErrors)

/// The <CLASS>%CSP.WebSocket</CLASS> object serves as an event handler for communication between client and
/// server using the WebSocket protocol (<B>RFC 6455</B>).  All WebSocket servers derive from %CSP.WebSocket.
Class %CSP.WebSocket Extends (%RegisteredObject, %CSP.Page) [ ServerOnly = 1 ]
{

Parameter UseSession = 1;

Parameter NOCHARSETCONVERT = 1;

/// This property determines whether the communication between the client and WebSocket server should be over a dedicated Gateway
/// conection or over a pool of shared connections.  It may be set to one of the following:
/// <br><ul>
/// <li><b>SharedConnection=0</b> - The WebSocket server communicates with the client via a dedicated Gateway connection. In this mode of operation the hosting connection is effectively 'private' to the application session.</li>
/// <li><b>SharedConnection=1</b> - The WebSocket server communicates asynchronously with the client via a fixed number of shared Gateway connections.</li>
/// </ul>
Property SharedConnection As %Boolean [ InitialExpression = 0 ];

/// This property determines whether formal data framing should occur between the Web Gateway and InterSystems IRIS
/// <br><ul>
/// <li><b>NoDataFraming=0</b> - Use the READ and WRITE methods in this class to manage I/O with the WebSocket.</li>
/// <li><b>NoDataFraming=1</b> - Use the basic ObjectScript READ and WRITE commands to manage I/O with the WebSocket (<b>SharedConnection</b> cannot be set with this mode).</li>
/// </ul>
Property NoDataFraming As %Boolean [ InitialExpression = 0 ];

/// This property determines whether the data streams transmitted between the client and server should be treated as binary.
/// The default setting is to treat the incoming and outgoing data as UTF-8 encoded text.
/// <br><br>
/// This property may be set to one of the following:
/// <br><ul>
/// <li><b>BinaryData=0</b> - UTF-8 encoded text.</li>
/// <li><b>BinaryData=1</b> - Binary Data.</li>
/// </ul>
Property BinaryData As %Boolean [ InitialExpression = 0 ];

/// The unique identity of this WebSocket.
Property WebSocketID As %String;

/// The CSP Session ID from which this WebSocket was created.
Property SessionId As %String;

/// This property determines whether WebSocket closure forces the associated CSP session to end.
/// Must be set in either Server() or OnPostServer(). For WebSockets operating asynchronously, only takes effect if EndServer() is called in Server(). 
/// <br><br>
/// This property may be set to one of the following:
/// <br><ul>
/// <li><b>SessionEndOnClose=0</b> - Do not force the CSP session to end when the web socket closes. (For synchronous web sockets, the CSP session may still end depending on its EndSession property.) </li>
/// <li><b>SessionEndOnClose=1</b> - Ensure that the CSP session ends when the web socket closes. </li>
/// </ul>
/// 
Property SessionEndOnClose As %Boolean [ InitialExpression = 0 ];

/// The address through which a WebSocket operating asynchronously (<property>SharedConnection=1</property>) can communicate with the hosting CSP Gateway.
Property GWClientAddress As %String;

/// The <var>AtEnd</var> property is set to true (1) when, during a read, 
/// the WebSocket server has reached the end of the current data frame.
Property AtEnd As %Boolean [ InitialExpression = 1 ];

/// The amount of client data waiting to be read.
Property BytesAvailable As %Integer [ InitialExpression = 0, Private ];

/// The type of the Data Frame waiting to be read.
Property DataFrameType As %Integer [ InitialExpression = 0, Private ];

/// The flag indicating that WebSocket data framing should be used for write operations.
Property WSDataFraming As %Integer [ InitialExpression = 0, Private ];

/// The version of the transmission protocol between the CSP Gateway and this class.
Property WSClassProtocolVersion As %Integer [ InitialExpression = 2, Private ];

/// The internal initialization status for the WebSocket.
Property WSInitStatus As %Integer [ InitialExpression = 0, Private ];

/// Event handler for the <b>PreServer</b> event: this is invoked before
/// starting the WebSockets Server.
/// Changes to the <property>SharedConnection</property> flag must be made here.
Method OnPreServer() As %Status
{
	Quit $$$OK
}

/// Event handler for the <b>PostServer</b> event: this is invoked after
/// closing the WebSockets Server.
Method OnPostServer() As %Status
{
	Quit $$$OK
}

/// The WebSocket Server.  Use the <Method>Read</Method> and <Method>Write</Method> methods
/// to receive data from, and send data to, the client.
/// Call the <Method>EndServer</Method> method to gracefully terminate the WebSocket Server.
/// A WebSocket operating asynchronously (<property>SharedConnection=1</property>) can exit this method
/// (using <b>Quit</B>) and subsequently open the WebSocket using the <Method>OpenServer</Method> method.
Method Server() As %Status
{
	Set status=..EndServer()
	Quit $$$OK
}

/// Event handler for the <b>ClientMessage</b> event: this method is only relevant to
/// WebSockets operating in Asynchronous mode.  In other words WebSockets for which
/// the <property>SharedConnection</property> flag is set.
/// If <method>OnClientMessage</method> successfully processes the client message it
/// must return with 1.
Method OnClientMessage(data As %String = "", close As %Integer) As %Status
{
	Quit 0
}

/// Internal method to initialize the WebSocket Class.
Method Initialize(WebSocketID As %String = "", GWClientAddress As %String = "") As %Status
{
	Set i%WebSocketID = WebSocketID
	Set i%GWClientAddress = GWClientAddress
	Quit $$$OK
}

/// Internal method to initialize the WebSocket Server.
Method InitializeServer() As %Status
{
	Set $ZT="InitializeServerError"
	If i%NoDataFraming>0 Set i%SharedConnection=0
	Set i%WSDataFraming = 1
	Set status = ..SaveServer()
	Set data="CacheSP: p=0;chd=1;ato=3600;"_$Char(13,10)
	Set data=data_"HTTP/1.1 200 OK"_$Char(13,10)
	Set data=data_"Content-type: text/html"_$Char(13,10)
	Set data=data_"Connection: close"_$Char(13,10)
	Set data=data_"WSClassProtocolVersion: "_i%WSClassProtocolVersion_$Char(13,10)
	Set data=data_"SharedConnection: "_i%SharedConnection_$Char(13,10)
	Set data=data_"NoDataFraming: "_i%NoDataFraming_$Char(13,10)
	Set data=data_"BinaryData: "_i%BinaryData_$Char(13,10)
	Set data=data_$Char(13,10)
	Set data=data_"WebSocket Server"_$Char(13,10)
	Write data,*-3
	Do $$$ZuNoFlushOpOnWebServerTCPDevice
	Set data="CacheSP: p=0;chd=1;ato=3600;"_$Char(13,10)
	Write data,*-3
	Do $$$ZuFinishOpOnWebServerTCPDevice
	If i%NoDataFraming = 2 {
		#; Turn off Cache data framing (sectioned write)
		Use 0:(::"-B")
	}
	Quit $$$OK
InitializeServerError	
	#; No interrupts during cleanup or error processing
	$$$SetExternalInterrupts(0)
	Set $ZTrap="InitializeServerHalt"
	Hang 5
	Close 0
InitializeServerHalt 
	Halt
}

/// Internal method to save the WebSocket Server.
Method SaveServer() As %Status [ Final, Private ]
{
	If i%WebSocketID = "" {
		Quit $$$ERROR($$$CSPWebSocketInvalidID)
	}
	Set $$$CSPWebSocket("SERVER",i%WebSocketID)=$lb(i%SessionId,i%GWClientAddress,i%SharedConnection,i%WSDataFraming)
	Set $$$CSPWebSocket("SESSION",i%SessionId,i%WebSocketID)=""
	Quit $$$OK
}

/// Internal method to delete the WebSocket Server.
Method DeleteServer() As %Status [ Final, Private ]
{
	If i%WebSocketID = "" Quit $$$ERROR($$$CSPWebSocketInvalidID)
	If '$data($$$CSPWebSocket("SERVER",i%WebSocketID),data) Quit $$$OK
	Set session=$lg(data)
	Lock +$$$CSPWebSocket("DATA",i%WebSocketID)
	If session'="" Kill $$$CSPWebSocket("SESSION",session,i%WebSocketID)
	Kill $$$CSPWebSocket("SERVER",i%WebSocketID)
	Do $system.Event.Delete($name($$$CSPWebSocket("DATA",i%WebSocketID)))
	Kill $$$CSPWebSocket("DATA",i%WebSocketID)
	Lock -$$$CSPWebSocket("DATA",i%WebSocketID)
	Quit $$$OK
}

/// Method to open an existing WebSocket Server.
/// Only a WebSocket operating asynchronously (<property>SharedConnection=1</property>) can be accessed using this method.
Method OpenServer(WebSocketID As %String = "") As %Status
{
	If WebSocketID = "" Quit $$$ERROR($$$CSPWebSocketInvalidID)
	Set data=$get($$$CSPWebSocket("SERVER",WebSocketID))
	If data = "" Quit $$$ERROR($$$CSPWebSocketNoData, WebSocketID)
	Set i%WebSocketID=WebSocketID
	Set $lg(i%SessionId,i%GWClientAddress,i%SharedConnection,i%WSDataFraming)=data
	Quit $$$OK
}

/// Gracefully terminate the WebSocket Server.
Method EndServer() As %Status
{
	If (i%SharedConnection = 1) {
		Set status=$$CSPGWClientRequest^%SYS.cspServer3(i%GWClientAddress,"WSX "_i%WebSocketID,-5,.response)
		Set status=..OnPostServer()
	}
	Set status=..DeleteServer()
	Quit $$$OK
}

/// Reads up to len characters from the client.
/// If the call is successful the status (sc) will be returned as $$$OK, otherwise an error code of $$$CSPWebSocketTimeout 
/// indicates a timeout and $$$CSPWebSocketClosed indicates that the client has terminated the WebSocket.
Method Read(ByRef len As %Integer = 32656, ByRef sc As %Status, timeout As %Integer = 86400) As %String
{
	Set $ZTrap="ReadError"
	If len<1 Set len=32656
	If (i%SharedConnection = 1) {
		Set data=..ReadAsync(.len, .sc, timeout)
		If i%BinaryData {
			Set data1=data
		} else {
			Try {
				Set data1=$zconvert(data,"I","UTF8")
			} Catch exp {
				$$$SysLog(2, "WebSocket", "[Read] Exception: "_exp.DisplayString(), data)
				Set data1=data
			}
		}
		Set len=$Length(data1)
		Quit data1
	}
	If ..BytesAvailable Goto ReadData
	Set ..BytesAvailable=0,..AtEnd=0
	Read header#5:timeout
	If $Test=0 {
		Set len=0
		Set sc=$$$ERROR($$$CSPWebSocketTimeout,"WebSocket Read Operation timed-out")
		Set ..AtEnd=1
		Quit ""
	}
	Set ..DataFrameType=$Extract(header,5)
	If ..DataFrameType = 9 {
		Set len=0
		Set sc=$$$ERROR($$$CSPWebSocketClosed,"WebSocket Closed by the Client")
		Set ..AtEnd=1
		Quit ""
	}
	Set header=$Extract(header, 1, 4)
	Set size=$ZLA(header)-1 If size<0 Set size=0
	Set ..BytesAvailable=size
ReadData
	If ..BytesAvailable > len {
		Set size=len
		Set ..BytesAvailable=..BytesAvailable-len
	} else {
		Set size=..BytesAvailable
		Set ..BytesAvailable=0
	}
	If '..BytesAvailable Set ..AtEnd=1
	If size=0 Set len=0,sc=$$$OK Quit ""
	Read data#size
	Set len=size
	Set sc=$$$OK
	If ((..DataFrameType = 8) ! (i%BinaryData = 1)) {
		Set data1=data
	} Else {
		Try {
			Set data1=$zconvert(data,"I","UTF8")
		} Catch exp {
			$$$SysLog(2, "WebSocket", "[Read] Exception: "_exp.DisplayString(), data)
			Set data1=data
		}
	}
	#; As there is activity on this session reset the session timeout
	Set sc=$$updateTimeout^%SYS.cspServer(i%SessionId) If $$$ISERR(sc) $$$SysLog(2,"WebSocket","[Read] Error updating session timeout",sc)
	Set len=$Length(data1)
	Quit data1
ReadError	
	#; No interrupts during cleanup or error processing
	Do event^%SYS.cspServer2("WebSocket Read Error: "_$ZError)
	$$$SetExternalInterrupts(0)
	Set $ZTrap="ReadHalt"
	Hang 5
	Close 0
ReadHalt 
	Halt
}

Method ReadAsync(ByRef len As %Integer = 32656, ByRef sc As %Status, timeout As %Integer = 86400) As %String [ Private ]
{
	Set $ZTrap="ReadAsyncError"
	Set ..AtEnd=0
	Set data="",chunk=""
	Try {
		Set waitResult=$system.Event.Wait($name($$$CSPWebSocket("DATA", i%WebSocketID)), timeout)
	} Catch {
		Set waitResult=-1
	}
	if waitResult=-1 {
		// Resource no longer exists. This is abnormal, so report an internal error.
		Set data="",len=0
		Set sc=$$$ERROR($$$CSPWebSocketClosed,"WebSocket Closed as session timed out")
		Set ..AtEnd=1
		Goto ReadAsyncExit
	} elseif waitResult = 0 {
		// Timed out while waiting for data from client
		Set data="",len=0
		Set sc=$$$ERROR($$$CSPWebSocketTimeout,"WebSocket Read Operation timed-out")
		Set ..AtEnd=1
		Goto ReadAsyncExit
	} else {
		// Data from client are available now.
		Lock +$$$CSPWebSocket("DATA",i%WebSocketID)
		Set n=$Order($$$CSPWebSocket("DATA",i%WebSocketID,""))
		If n="" {
			// No data found. This is abnormal, so report an internal error.
			Lock -$$$CSPWebSocket("DATA",i%WebSocketID)
			goto ReadAsyncError
		} else {
			Set chunk=$Get($$$CSPWebSocket("DATA",i%WebSocketID,n))
			If $Data($$$CSPWebSocket("DATA",i%WebSocketID,n,"close")) {
				Lock -$$$CSPWebSocket("DATA",i%WebSocketID)
				Set data="",len=0
				Set sc=$$$ERROR($$$CSPWebSocketClosed,"WebSocket Closed by the Client")
				Set ..AtEnd=1
				Goto ReadAsyncExit
			}
			If $Length(chunk)>len {
				Set data = $Extract(chunk, 1, len)
				Set $$$CSPWebSocket("DATA",i%WebSocketID,n)=$Extract(chunk, len + 1, *)
			} else {
				Set data = chunk
				Kill $$$CSPWebSocket("DATA",i%WebSocketID,n)
				If $Order($$$CSPWebSocket("DATA",i%WebSocketID,""))="" Set ..AtEnd=1
			}
			Lock -$$$CSPWebSocket("DATA",i%WebSocketID)
			Set len=$Length(data)
			Set sc=$$$OK
			#; Note we do not update session timeout here because the posting of this from the CSP thread will update the sessionId 
			Goto ReadAsyncExit
		}
	}
ReadAsyncError ; Internal Error
	Set $ZTrap=""
	Do event^%SYS.cspServer2("WebSocket Asynchronous Read Error: "_$ZError)
	Set sc=$$$ERROR($$$CSPWebSocketClosed,"WebSocket Read Operation Error")
	Set data="",len=0
ReadAsyncExit
	Quit data
}

/// Write to the client.
Method Write(data As %String) As %Status
{
	Set $ZTrap="WriteError"
	If i%BinaryData = 1 {
		Set data1 = data
	} Else {
		Try {
			Set data1=$zconvert(data,"O","UTF8")
		} Catch exp {
			$$$SysLog(2, "WebSocket", "[Write] Exception: "_exp.DisplayString(), data)
			Set data1=data
		}
	}
	If i%WSClassProtocolVersion > 1 & i%WSDataFraming = 1 {
		Set head=$ZLChar($Length(data1))
		If i%BinaryData = 1 {
			Set head=head_"8"
		} Else {
			Set head=head_"7"
		}
	} Else {
		Set head=""
	}
	#; As there is activity on this session reset the session timeout
	Set sc=$$updateTimeout^%SYS.cspServer(i%SessionId) If $$$ISERR(sc) $$$SysLog(2,"WebSocket","[Write] Error updating session timeout",sc)
	#; Only return an error status if there's an issue with the write itself.
	Set sc=$$$OK
	If (i%SharedConnection = 1) {
		Set sc=$$CSPGWClientRequest^%SYS.cspServer3(i%GWClientAddress,"WSW "_i%WebSocketID_" "_head_data1,-5,.response)
		If $$$ISERR(sc) $$$SysLog(2,"WebSocket","[Write] Error sending request",sc)
	} else {
		Write head_data1,*-3
	}
	Quit sc
WriteError	
	#; No interrupts during cleanup or error processing
	Do event^%SYS.cspServer2("WebSocket Write Error: "_$ZError)
	$$$SetExternalInterrupts(0)
	Set $ZTrap="WriteHalt"
	Hang 5
	Close 0
WriteHalt 
	Halt
}

/// Internal handling of page processing
ClassMethod Page(skipheader As %Boolean = 1) As %Status [ Internal, ServerOnly = 1 ]
{
	Set websocketid = $Get(%request.CgiEnvs("HTTP_WEBSOCKET_ID"))
	Set gwclientaddress = $Get(%request.CgiEnvs("HTTP_GWCLIENT_ADDRESS"))
	If websocketid="" HALT
	#; Asynchronous mode
	if $get(%request.CgiEnvs("HTTP_CSPWS")) = 1 RETURN ..SendAsyncMessage(websocketid,gwclientaddress)
	Try {
		Set WS=..%New()
		Set WS.SessionId=%session.SessionId
		If $Data($$$CSPWebSocket("SERVER", websocketid),data) {
			Set WS.SharedConnection=$lg(data,3)
		}
		Set %Status=WS.Initialize(websocketid, gwclientaddress)
		Set %Status=WS.OnPreServer()
		If $$$ISERR(%Status) {
			Set %request.Data("Error:ErrorCode",1) = %Status
			do ..Error(skipheader)
			Quit
		}
		If (WS.SharedConnection = 1) {
			Kill $$$CSPWebSocket("DATA", websocketid)
			Set $$$CSPWebSocket("DATA", websocketid) = ""
			
			#; In shared connection mode, the WebSocket server is allowed to outlive its hosting
			#; IRIS process and be re-opened on a different IRIS process. To synchronize access
			#; to the queue of messages arriving from the client, use a named event.
			Do $system.Event.Create($name($$$CSPWebSocket("DATA", websocketid)))
			
			#; Wait up to the "Server Response Timeout" for the Gateway client process to be ready
			#; to handle asynchronous writes from the WebSocket server. It is expected that in almost
			#; all cases, the Gateway client process is already ready by this point.
			Set timeout = $zh+%request.GatewayTimeout
			While $get($$$CSPGWC("COM",gwclientaddress,0,"$J"))="" {
				Hang 0.05
				If $zh>timeout {
					Set st = $$$ERROR($$$CSPWebSocketNoClientProcess, %request.GatewayTimeout)
					Throw ##class(%Exception.StatusException).CreateFromStatus(st)
				}
			}
		}
		Set %Status=WS.InitializeServer()
		If (WS.SharedConnection = 0) {
			#; Synchronous mode: WebSocket will remain permanently attached to this connection 
			Lock +$$$CSPWebSocket("SESSION",%session.SessionId)#"S"
			$$$TOE(sc,%session.Unlock())
			Set %Status=WS.Server()
			Set %Status=WS.OnPostServer()
			Lock -$$$CSPWebSocket("SESSION",%session.SessionId)#"SI"
			Set %Status=WS.DeleteServer()
			#; If the user asks to delete the session honor it here before terminating this process
			#; forceend=2 to release the license associated with this session
			If WS.SessionEndOnClose Set %session.EndSession=1
			If %session.EndSession Do %session.endSession(0,2)
			Halt
		} else {
			#; Asynchronous mode: WebSocket will start in a separate process (which can be halted)
			Set WSClass=$Piece($P(%request.URL, "/", *), ".", 1, * - 1)
			Job CSPGWAsyncWebSocket^%SYS.cspServer3(WSClass, websocketid)
		}
	} Catch {
		Do event^%SYS.cspServer2($ZE_" (CSP: Error invoking WebSocket methods)")
		Do $System.Event.Delete($name($$$CSPWebSocket("DATA", websocketid)))
		HALT
	}
	Quit $$$OK
}

ClassMethod SendAsyncMessage(websocketid As %String, gwclientaddress As %String) As %Status [ Final ]
{
	#; Asynchronous mode: WebSocket client data
	#; Use HTTP Post for large (or binary) data sizes 
	If ((%request.Method = "POST") & ($isobject(%request.Content))) {
		Set data=%request.Content.Read($$$MaxLocalLength)
	} Else {
		Set data = $Get(%request.CgiEnvs("HTTP_CSPWSDATA"))
	}
	#; Asynchronous mode: WebSocket instruction to close
	Set close = $Get(%request.CgiEnvs("HTTP_CSPWSCLOSE"))
	Set messageprocessed = 0
	Try {
		Set WS=..%New() If '$isobject(WS) {
			$$$SysLog(1,"WebSocket","[SendAsyncMessage] Unable to construct WebSocket class '"_$classname()_"'","")
			RETURN ..SendNullResponse()
		}
		Set sc=WS.OpenServer(websocketid) If $$$ISERR(sc) {
			$$$SysLog(1,"WebSocket","[SendAsyncMessage] Error with OpenServer",sc)
			RETURN ..SendNullResponse()
		}
		Set messageprocessed=WS.OnClientMessage(data,close)
	} Catch {
		$$$SysLog(1,"WebSocket","[SendAsyncMessage] Error",$ze)
		RETURN ..SendNullResponse()
	}
	#; If message not processed in OnClientMessage post the data to the queue
	If messageprocessed'=1 {
		Lock +$$$CSPWebSocket("DATA",websocketid)
		// If the WebSocket server has not ended, add message to the read queue
		// and signal the reader.
		If $Data($$$CSPWebSocket("DATA",websocketid)) {
			Set n=$Order($$$CSPWebSocket("DATA",websocketid,""),-1)+1
			Set $$$CSPWebSocket("DATA",websocketid,n)=data
			If close Set $$$CSPWebSocket("DATA",websocketid,n,"close")=1
			Do $system.Event.Signal($name($$$CSPWebSocket("DATA", websocketid)))
		}
		Lock -$$$CSPWebSocket("DATA",websocketid)
	}
	RETURN ..SendNullResponse()
}

/// Send the basic web socket response to the gateway
ClassMethod SendNullResponse() [ Internal ]
{
	Write "CacheSP: p=0;chd=1;ato=3600;"_$Char(13,10)_"HTTP/1.1 200 OK"_$Char(13,10)_"Content-type: text/html"_$Char(13,10)_"Connection: close"_$Char(13,10,13,10)_"WebSocket Server"_$Char(13,10)
	Do $$$ZuNoFlushOpOnWebServerTCPDevice
	Write "CacheSP: p=0;chd=1;ato=3600;"_$Char(13,10)
	Do $$$ZuFinishOpOnWebServerTCPDevice
	RETURN $$$OK
}

/// Internal handling of error
ClassMethod Error(skipheader As %Boolean = 1) As %Status [ Internal, ServerOnly = 1 ]
{
	Set sc=$get(%request.Data("Error:ErrorCode",1))
	If sc=""||(sc=$$$OK) Set sc=$$$ERROR($$$CSPWebSocketUnknownError)
	Set data="CacheSP: p=0;chd=1;ato=3600;"_$Char(13,10)
	Set data=data_"HTTP/1.1 404 Not Found"_$Char(13,10)
	Set data=data_"Content-type: text/html"_$Char(13,10)
	Set data=data_"Connection: close"_$Char(13,10)
	Set data=data_$Char(13,10)
	Write data
	Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
	Do $system.OBJ.DisplayError(sc)
	Kill EscapeObj
	Write $Char(13,10)
	Do $$$ZuNoFlushOpOnWebServerTCPDevice
	Write "CacheSP: p=0;chd=1;ato=3600;"_$Char(13,10)
	Do $$$ZuFinishOpOnWebServerTCPDevice
    Quit $$$OK
}

/// Internal handling of login
ClassMethod Login(skipheader As %Boolean = 1) As %Status [ Internal, ServerOnly = 1 ]
{
	Quit ..Error(.skipheader)
}

}
