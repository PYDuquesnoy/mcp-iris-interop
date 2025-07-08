/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %OAuth2.Server.Revoke is the default RevokeTokenClass which is included with the server.
/// The default class will pass through, with no side effects upon token revocation.<br>
/// The RevokeTokenClass is specified in the Authorization Server Configuration.
/// The OnRevokeAccessToken can perform user-specific operations upon token revocation, 
/// optionally bypassing the regular revocation flow. <br>
/// The OnLogoutAccessToken method can perform user-specific operations during RP-Initiated
/// Front-Channel Logout. 
Class %OAuth2.Server.Revoke Extends %RegisteredObject [ System = 4 ]
{

/// The OnRevokeAccessToken method must return a boolean value or throw an error. <br />
/// If the method returns 1 or throws an error, the regular revocation flow is
/// bypassed. <br />
/// If the method returns 0, the regular revocation flow continues. <br />
/// Default behavior is to permit regular revocation flow. <br />
/// Receives the AuthorizationCode property value of the token to be deleted. <br />
ClassMethod OnRevokeAccessToken(authCode As %String, Output sc As %Status) As %Boolean
{
	Set sc=$$$OK
	Return 0
}

/// The OnLogoutAccessToken method is called during the RP-Initiated Front-Channel Logout flow. If this returns
/// an error status (or throws an exception), then the normal flow will be bypassed. If it returns 1 
/// the server will skip deleting the token and ending the session (if one exists,) but the normal redirect 
/// flow will still take place. The client's redirect URI is passed in the redirectURI parameter. 
/// This can be modified by the callback to redirect to another URI; this can be useful if authorization has
/// been delegated to a third-party authorization server. If this callback modifies redirectURI, the new target
/// should redirect to the original URI upon successful completion of the request.
ClassMethod OnLogoutAccessToken(authCode As %String, properties As %OAuth2.Server.Properties, ByRef redirectURI As %String, Output sc As %Status) As %Boolean
{
	Set sc=$$$OK
	Return 0
}

}
