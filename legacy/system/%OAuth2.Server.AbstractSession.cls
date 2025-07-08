/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines the interface for the OAuth2 Server session maintenance class. If SupportSession is true in <Class>OAuth2.Server.Configuration</Class>
/// then this class is used to track the user's session. The default session maintenance class is <Class>OAuth2.Server.Session</Class>. 
/// The behavior can be customized by creating a subclasss of this class.
Class %OAuth2.Server.AbstractSession [ Abstract, System = 4 ]
{

/// This method returns the name of the user currently logged into this session.
/// If no session exists, then "" is returned. <br>
/// The set of scopes associated with this session are returned in the scope parameter. <br>
/// The time the session was created is returned in the authTime parameter. <br>
/// The sc parameter contains the error code (or $$$OK if no error occurred). <br>
/// authCode contains the Authorization Code from the associated Access Token. This can be used to 
/// associate the Access Token with the session. 
ClassMethod GetUser(Output scope As %String, Output authTime As %Integer, Output sc As %Status, authCode As %String = "") As %String [ Abstract ]
{
}

/// This method updates the current session with the provided values. <br>
/// scope is a blank separated list of scope values to associate with the session. <br>
/// If the interval argument is specified the session interval should be updated. <br>
/// The interval argument is seconds until expiration for the session.
/// If interval=0, then the session will not expire.
ClassMethod Update(scope As %String, interval As %Integer) As %Status [ Abstract ]
{
}

/// This method creates a new session for the user named by username.<br>
/// The scope argument specifies a blank separated list of scopes for which the user is authorized. <br>
/// The interval argument is seconds until expiration for the session. <br>
/// If interval=0, then the session will not expire. <br>
/// authTime indicates the time at which the session was created. This should be specified as the number 
/// of seconds since the start of the UNIX epoch. This can be computed using <example>Set authTime = ##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,0)</example>
/// authCode contains the Authorization Code from the associated Access Token. This can be used to
/// associate the Access Token with the session. 
ClassMethod Login(username As %String, scope As %String, interval As %Integer, Output authTime As %Integer, authCode As %String = "") As %Status [ Abstract ]
{
}

/// The Logout method terminates the current session.
/// This may be called when there is no current session.
ClassMethod Logout() As %Status [ Abstract ]
{
}

/// This method deletes all current sessions.
ClassMethod DeleteAll() As %Status [ Abstract ]
{
}

/// This method will update the <Class>OAuth2.Server.AccessToken<Class> identified by authcode with the given groupId.
/// This can be used to associate the Access Token with the user's session. The Access Token will not be updated
/// if it already is associated with a GroupId, unless force is true.<b>
/// Note that any subclass of this class MUST use the <Class>OAuth2.Server.AccessToken<Class> GroupId property
/// to associate tokens with sessions. All tokens that have the same GroupId are part of the same session.
ClassMethod UpdateTokenGroup(authCode As %String, groupId As %String, force As %Boolean = 0) As %Status
{
	If (authCode="")||(groupId="") Return $$$OK
	
	If $namespace '= "%SYS" {
		New $namespace
		Set $namespace = "%SYS"
	}
	
	Set sc = $$$OK
	Set token=##class(OAuth2.Server.AccessToken).OpenByCode(authCode,.sc)
	If $isobject(token) && ((token.GroupId="")||force) {
		Set token.GroupId = groupId
		Set sc = token.Save()
	}
	
	Return sc
}

}
