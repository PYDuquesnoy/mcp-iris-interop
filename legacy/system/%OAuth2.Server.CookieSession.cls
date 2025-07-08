/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a simple OAuth2 session maintenance class where the user's session is tracked by an opaque cookie. 
/// This is a persistent class containing basic session data indexed by the cookie value.
Class %OAuth2.Server.CookieSession Extends (%Persistent, %OAuth2.Server.AbstractSession) [ Abstract, NoExtent, System = 4 ]
{

/// The name of the cookie used to maintain the session
Parameter COOKIENAME As STRING;

/// The IDKEY for the session class.
Index CookieIndex On Cookie [ IdKey, Unique ];

/// The session is indexed by the Username
Index UserIndex On Username;

/// Order by expiration time
Index ExpiresIndex On Expires;

/// Opaque Cookie value used to track the user's session
Property Cookie As %String(COLLATION = "EXACT", MAXLEN = 128) [ Required ];

/// The User name associated with this session
Property Username As %Library.Username(COLLATION = "EXACT");

/// Expires is the time in seconds from beginning of the Unix epoch when the session expires.
/// If Expires="", then session does not expire.
Property Expires As %Integer;

/// Scope is the blank separated list of scopes permitted for this user in this session.
Property Scope As %String(MAXLEN = "");

/// The time when the user was authenticated
Property AuthTime As %Integer;

/// Return the username (and granted scopes, and authentication time) for the current session, or "" if there is no current session.
ClassMethod GetUser(Output scope As %String, Output authTime As %Integer, Output sc As %Status, authCode As %String = "") As %String
{
	Set sc=$$$OK
	Set username=""
	Set scope=""
	
	Try {
		// Get the current session
		#dim session As %OAuth2.Server.CookieSession
		Set session=..GetCurrentSession(.sc)

		// Return username if session found
		If $isobject(session) {
			Set username=session.Username
			Set scope=session.Scope
			Set authTime=session.AuthTime
			If (authCode'="") {
				Set sc = ..UpdateTokenGroup(authCode, session.Cookie, 0)
			}
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	Return username
}

/// Update the current session with the given scope values and timeout interval. 
/// This does nothing if there is no current session.
ClassMethod Update(scope As %String, interval As %Integer) As %Status
{
	Set sc=$$$OK

	Try {
		// Try to update an existing session
		Set session=..GetCurrentSession(.sc)
		If $isobject(session) {
			Set session.Scope=scope
			If $data(interval) {
				If +interval=0 {
					Set session.Expires=""
				} Else {
					Set session.Expires=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,interval)
				}
			}
			// Save the session object		
			Set sc=session.%Save()
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	Return sc
}

/// Create a new session for the given user. This creates a new session Object and sets a new cookie in the User Agent 
/// referencing this session. 
ClassMethod Login(username As %String, scope As %String, interval As %Integer, Output authTime As %Integer, authCode As %String = "") As %Status
{
	Set sc=$$$OK

	Try {
		// Create a new session object
		Set session=..%New()
		Set session.Cookie=..MakeCookieValue()
		Set session.Username=username
		Set session.Scope=scope
		Set authTime=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,0)
		Set session.AuthTime=authTime
		If +interval=0 {
			Set session.Expires=""
		} Else {
			Set session.Expires=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,interval)
		}

		// Save the session object		
		Set sc=session.%Save()
		
		// Set the cookie into the user agent.
		If $$$ISOK(sc) Do ..SetCookie(session.Cookie,session.Expires)
		
		If (authCode'="") {
			Set sc = ..UpdateTokenGroup(authCode, session.Cookie, 1)
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	Return sc
}

/// Terminate the current session. This will delete the session object and all cookies associated
/// with it and expire the cookie. Absence of a session is not seen as an error and this method will
/// still return 1 (though it won't actually do anything if no session exists).
ClassMethod Logout() As %Status
{
	Set sc=$$$OK
	Set loginCookie=..GetCookie()
	If loginCookie'="" {
		// Switch to %SYS in order to RevokeByGroupId
		Set initNS=$namespace
		If initNS'="%SYS" {
			New $namespace
			Set $namespace="%SYS"
		}
		
		// Delete all access tokens bound to this session
		Set sc=##class(OAuth2.Server.AccessToken).RevokeByGroupId(loginCookie)
		If $$$ISERR(sc) {
			Quit sc
		}

		// Return to initial namespace for cookie and session operations
		Set $namespace=initNS
		
		// zap any current Login Cookie by setting expire time to now - 60 seconds
		Set now=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,-60)
		Do ..SetCookie(loginCookie,now)

		// Delete the session object
		Set session=..OpenByCookie(loginCookie)
		If $isobject(session) {
			Set sc=session.Delete()
		} 
	}
	Quit sc
}

/// Delete all sessions.
ClassMethod DeleteAll() As %Status
{
	Return ..%DeleteExtent()
}

/// This method is used to produce the cookie value for a new session. 
ClassMethod MakeCookieValue() As %String
{
	Return ##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(32))
}

/// This method will retrieve the cookie value for the current session, if one exists.
ClassMethod GetCookie() As %String
{
	Return $get(%request.Cookies(..#COOKIENAME,1),"")
}

/// This method will set the given cookie value in the User Agent, with the given expiration time.
ClassMethod SetCookie(value As %String, expires As %Integer)
{
	If expires'="" {
		Set h=##class(%OAuth2.Utils).TimeInH(expires)
		Set time  = $ztime($piece(h,",",2),1)
		Set date  = $translate($zdate(h,2,,,,,,,,1)," ","-")
		Set wkday = $zdate(h,12,,,,,,,,1)
		Set expireDate = wkday_", "_date_" "_time_" GMT"
	} Else {
		Set expireDate=""
	}
	
	// %request.Application includes the URLPrefix (if present)
	Set path=%request.Application

	Do %response.SetCookie(..#COOKIENAME,value,expireDate,path,,1,1)
}

/// The GetCurrentSession method returns the currently logged in session.
/// If no session exists, then "" is returned.
ClassMethod GetCurrentSession(Output sc As %Status) As %OAuth2.Server.CookieSession [ Internal ]
{
	Set sc=$$$OK
	Set session=""
	
	Try {
		// First cleanup expired sessions
		Do ..Cleanup()

		// Get the session cookie
		Set loginCookie=..GetCookie()
		
		// If no cookie, then return "".
		If loginCookie="" Quit
		
		// Open the session object
		Set session=..OpenByCookie(loginCookie,.sc)
		
		// If no session object, then return ""
		If '$isobject(session) Quit
		
		// If expired, then delete session object and return "".
		Set now=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,0)
		If session.Expires'="",session.Expires<now {
			Set sc=session.Delete()
			Set session=""
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) Set session=""		
	Return session
}

/// Open the OAuth2.Server.Session instance using Cookie.
ClassMethod OpenByCookie(cookie As %String, Output sc As %Status) As %OAuth2.Server.CookieSession [ Internal ]
{
	Set sc=$$$OK
	
	Try {
		Set session=..%OpenId(cookie,,.sc)
		If $$$GETERRORCODE(sc)=$$$ERRORCODE($$$LoadObjectNotFound) {
			Set sc=$$$OK
			Set session=""
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) Set session=""		
	Return session
}

/// Delete this session object
Method Delete() As %Status [ Internal ]
{
	Try {
		$$$SysLog(3,"OAuth2Server","[%OAuth2.Server.CookieSession:Delete]","Delete for Cookie="_..Cookie_", Username="_..Username)
		Set sc=..%Delete(.."%%OID")
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	Return sc
}

/// Delete all expired sessions
ClassMethod Cleanup() [ CodeMode = objectgenerator, Internal ]
{
	Do %code.WriteLine("	Set now=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,0)")
	Do %code.WriteLine("	&sql(DECLARE SESSION CURSOR FOR  ")
	Do %code.WriteLine("		SELECT Cookie, Username INTO :cookie, :username FROM "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName)
	Do %code.WriteLine("		WHERE Expires IS NOT NULL AND Expires < :now)")
	Do %code.WriteLine("	&sql(OPEN SESSION)")
	Do %code.WriteLine("	For {")
	Do %code.WriteLine("		&sql(FETCH SESSION)")
	Do %code.WriteLine("		If SQLCODE'=0 Quit")
	Do %code.WriteLine("		$$$SysLog(3,""OAuth2Server"",""["_%class.Name_":"_%method.Name_"]"",""Delete for Cookie=""_cookie_"", Username=""_username)")
	Do %code.WriteLine("		Do ..%DeleteId(cookie)")
	Do %code.WriteLine("	}")
	Do %code.WriteLine("	&sql(CLOSE SESSION)")

	Return $$$OK
}

}
