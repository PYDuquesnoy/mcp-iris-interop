/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Interface for handling events in the web socket connection.
/// @API.Extensible
Class %Net.WebSocket.IEventListener [ Abstract ]
{

/// Called when the web socket connection is successfully opened. <br />
/// @API.Overrideable
Method OnOpen()
{
}

/// Called when an error occurs in the web socket connection.<br />
/// @API.Overrideable
Method OnError(pError As %Exception.AbstractException)
{
}

/// Called when the web socket connection is closed by either the client (%OnClose) or the server (by sending a close frame).<br />
/// @API.Overrideable
Method OnClose()
{
}

/// Called when the client receives a message from the server. <br />
/// <var>pContent</var> may be a binary or UTF8-decoded character stream. <br />
/// @API.Overrideable
Method OnMessage(pContent As %Stream.Object)
{
}

}
