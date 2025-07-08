/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides credentials and (optionally) an SSL configuration to use for WebSocket HTTP requests
/// @API.Extensible
Class %Net.WebSocket.ICredentials [ Abstract ]
{

/// Returns the username to use for authentication with the web socket
/// @API.Overrideable
Method GetUsername() As %String [ Abstract ]
{
}

/// Returns the password to use for authentication with the web socket
/// @API.Overrideable
Method GetPassword() As %String [ Abstract ]
{
}

/// Returns the SSL configuration name to use for secure web socket connections
/// @API.Overrideable
Method GetSSLConfiguration() As %String
{
	Quit ""
}

}
