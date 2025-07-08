/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// CSP session event handler for Zen.
Class %ZEN.SessionEvents Extends %CSP.SessionEvents [ Deprecated, System = 3 ]
{

/// Called when the session is about to be deleted.
ClassMethod OnEndSession()
{
	#; dispatch to Zen Controller
	Do ##class(%ZEN.Controller).OnEndSession()
	Quit
}

/// Called when the CSP Daemon times out out this session.
ClassMethod OnTimeout()
{
	Quit
}

/// Called when a new session is created and its values are initialised.
ClassMethod OnStartSession()
{
	Quit
}

/// Called when a session that was in CSP application <var>oldapp</var> is now going to run a page in
/// CSP application <var>newapp</var>. If this returns an error value then instead of running the
/// page in the new application it will redirect to the error page (error page looked up from old application).
ClassMethod OnApplicationChange(oldapp As %String, newapp As %String) As %Status
{
	Quit $$$OK
}

}
