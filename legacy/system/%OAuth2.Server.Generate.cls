/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %OAuth2.Server.Generate is the default GenerateTokenClass which is included with the server.
/// The default class will generate a random string as the opaque access token.<br>
/// The GenerateTokenClass is specified in the Authorization Server Configuration.
/// It must contain a GenerateAccessToken method will be used to generate an access token based
/// on the array of properties that is returned by the ValidateUser method.
Class %OAuth2.Server.Generate Extends %RegisteredObject [ System = 4 ]
{

/// The IsJWT method returns true if the GenerateAccessToken method returns a JWT.
/// IsJWT is used to determine inclusion of algorithms for access token in server metadata.
ClassMethod IsJWT() As %Boolean
{
	// False for opaque token
	Quit 0
}

/// The GenerateAccessToken method returns an access token.
/// The access token may be based on the properties argument.
/// In addition values for claims to be added to the JSON response object may be returned in the
/// properties.ResponseProperties array.<br>
/// However the method in this default class just returns an opaque random string.
ClassMethod GenerateAccessToken(properties As %OAuth2.Server.Properties, Output sc As %Status) As %String
{
	Set sc=$$$OK
	Quit ##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(64))
}

/// The OnRefreshAccessToken method will be called when a new access token is granted
/// based on a refresh token. If this method returns an error status, the refresh token 
/// request will fail. 
ClassMethod OnRefreshAccessToken(properties As %OAuth2.Server.Properties) As %Status
{
	Return $$$OK
}

}
