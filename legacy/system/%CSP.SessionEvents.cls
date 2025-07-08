/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract class which defines the interfaces that are called during
/// the lifetime of a <class>%CSP.Session</class> object. In order to use this you should
/// subclass this and implement the method code you wish to be executed.
/// Then within the CSP application configuration set the event class to the class you have
/// created.
Class %CSP.SessionEvents Extends %RegisteredObject [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// Called when the session is about to be deleted, either because of a timeout (in which case
/// <method>OnTimeout</method> is called first) or because the application
/// has explicitly closed this session. Use the %session object to examine this session. If you wish to
/// abort this deletion then:
/// <example>
/// Set %session.EndSession=0
/// </example>
ClassMethod OnEndSession()
{
	Quit
}

/// Called when the CSP Daemon times out out this session before calling <method>EndSession</method>.
/// Use the %session object to examine this session. If you wish to abort this deletion then:
/// <example>
/// Set %session.EndSession=0
/// </example>
ClassMethod OnTimeout()
{
	Quit
}

/// Called when a new session is created and its values are initialised.
/// <p>This is called before the license for this session is allocated, and if
/// you wish to abort this session and return the standard out of licenses error
/// page then:
/// <example>
/// Set %session.EndSession=1
/// </example>
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

/// Called when a login occurs that changed the $username or the roles this user is running with.
/// If this returns an error status then this is reported via the standard error page.
ClassMethod OnLogin() As %Status
{
	Quit $$$OK
}

/// Called when a logout. The current authentication for the session is invalidated. occurs that changed the $username or the roles this user is running with.
/// If this returns an error status then the logout will be stopped.
/// If you wish to end the session after the logout then:
/// <example>
/// Set %session.EndSession=1
/// </example>
ClassMethod OnLogout() As %Status
{
	Quit $$$OK
}

/// Called when we start getting data from the CSP gateway for a request
ClassMethod OnStartRequest() As %Status
{
	Quit $$$OK
}

/// Called when we have finished processing this request
ClassMethod OnEndRequest() As %Status
{
	Quit $$$OK
}

}
