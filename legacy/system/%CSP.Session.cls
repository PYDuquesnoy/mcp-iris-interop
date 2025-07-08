/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// The <CLASS>%CSP.Session</CLASS> class represents a session within a CSP application.
Class %CSP.Session Extends %Persistent [ StorageStrategy = custom, System = 3 ]
{

/// A flag that you set to '1' to terminate this session upon completion 
/// of this request.
Property EndSession As %Boolean [ InitialExpression = 0 ];

/// The session id value for this session.
/// <P>The session id is a system-assigned unique value that 
/// identifies this session.
Property SessionId As %String;

/// Group Id
/// If an group-by-id application was opened, this will contain
/// the groupId concatenated with the browser's id
Property GroupId As %String(MAXLEN = "") [ Internal ];

/// ByIdGroups
/// A list of all by-id groups applications opened have been members of. Used to remove this session from groups
Property ByIdGroups As %List [ Internal ];

/// Process Id
/// <p>If a session has Preserve=1 this contains the process id in which the session is running.></p>
Property ProcessId As %String;

Method EndSessionSet(val As %Boolean) As %Status [ Internal ]
{
	If val=i%EndSession Quit $$$OK
	If $isobject($get(%response)) {
		Do %response.EndSession(val)
	}
	Set i%EndSession=''val
	Quit $$$OK
}

/// Specifies the timeout value for the session in seconds.
/// <P>If no user requests are received within the specified time period, 
/// then the session will end. The default value comes from the CSP application
/// setting for the application that the session starts in which is set in the
/// configuration manager, this is often 900 seconds or 15 minutes.
/// Note that if you start a session in one applicaiton and move to another application
/// the AppTimeout will not be changed to the new applications timeout value, if you wish
/// to modify this when the application changes you can use the session events 'OnApplicationChange'
/// method.
/// <P>For no timeout, set this property to 0.
Property AppTimeout As %Integer(MAXVAL = 31536000, MINVAL = 0) [ InitialExpression = 900 ];

/// Internal property to determine if we should send the 'secure' flag with the sessionId cookie
Property SecureSessionCookie As %Boolean [ InitialExpression = 0 ];

/// Property to determine how strictly to restrict the domain of the sessionId cookie.
/// Options are None (0), Lax (1), and Strict (2), where Strict means the cookie 
/// can only be used within the current application.
/// Defaults to the CSP application's corresponding setting. 
/// Applications default to Strict unless otherwise configured.
/// Note that None is invalid for insecure (HTTP) connections. 
Property SessionScope As %Integer(DISPLAYLIST = ",None,Lax,Strict", VALUELIST = ",0,1,2") [ InitialExpression = 2 ];

/// Property to determine which SameSite attribute to send with user-created cookies.
/// Options are None (0), Lax (1), and Strict (2). Defaults to the CSP application's 
/// corresponding setting. Applications default to Strict unless otherwise configured.
/// Note that None is invalid for insecure (HTTP) connections. 
Property UserCookieScope As %Integer(DISPLAYLIST = ",None,Lax,Strict", VALUELIST = ",0,1,2") [ InitialExpression = 2 ];

/// If set then run this session in the namespace given rather than the one determined
/// by the CSP application. If the application then switches applications again it will revert
/// to the namespace determined by the CSP application.
Property RunNamespace As %String;

Method RunNamespaceSet(val As %String, app As %String) As %Status
{
	#Dim i,oldval
	If '$data(app) Set app=..Application
	For i=1:1:$length(i%RunNamespace,",")+1 If $piece($piece(i%RunNamespace,",",i),"=")=app Quit
	Set oldval=i%RunNamespace,$piece(oldval,",",i)=app_"="_val,i%RunNamespace=oldval
	Quit $$$OK
}

Method RunNamespaceGet() As %String
{
	Quit ..RunNamespaceFind(..Application)
}

Method RunNamespaceFind(application As %String) As %String
{
	#Dim namespace,i
	Set namespace=""
	For i=1:1:$length(i%RunNamespace,",") If $piece($piece(i%RunNamespace,",",i),"=")=application Set namespace=$piece($piece(i%RunNamespace,",",i),"=",2) Quit
	$$$CSPLogAll(3,"CSPSession","[RunNamespaceFind] Found: "_$get(namespace,"#MISSING#")_" for application: "_$get(application,"#ERROR NO APPLICATION#"), i%RunNamespace,"",i%SessionId)
	Quit namespace
}

/// If set then use this page as the error page rather than the one obtained from the
/// CSP application settings.
Property ErrorPage As %String(MAXLEN = "");

/// Original referrer when session was created, copied from the HTTP_REFERER %request value
Property Referrer As %String(MAXLEN = "");

Method ReferrerSet(val As %String) As %Status
{
	Set i%Referrer=val
	Quit $$$OK
}

/// The name of the application event class to be called in response to certain CSP events.
/// This should be a class derived from <class>%CSP.SessionEvents</class>. At present the
/// events that are fired are for creation of a new session (OnStartSession), deletion of a
/// session (OnEndSession) and the timeout of an existing session by the CSP daemon (OnTimeout).
/// You can set the event class for a CSP application in the CSP options of the configuration manager.
/// Note that if you set the EventClass inside a CSP page then as the session has already been
/// created at this point it will not fire the OnStartSession event, if the EventClass is set in the
/// CSP application settings then it will fire the start session event as it knows which event class
/// to call before it creates the session.<br>
/// Note that this adds this event class to the list unless it is already present and will not replace any
/// existing event class. Setting this to "" will not have any effect, if you wish to remove an
/// EventClass then call <method>EventClassRemove</method>
Property EventClass As %String(MAXLEN = "") [ Calculated ];

/// Set method for EventClass property.
Method EventClassSet(class As %String) As %Status [ Internal ]
{
	Quit ..EventClassAdd(class,$namespace)
}

Method EventClassGet() As %String
{
	Quit $listget($listget(i%EventClassContext))
}

/// Add an event class to the list of classes we will callback. If the class is already present we will
/// remove it and add this at the front of the list.
/// The namespace is optional and will default to the current namespace.
Method EventClassAdd(class As %String, namespace As %String) As %Status
{
	if ( class'="" ) {
		If $get(namespace)="" Set namespace=$namespace
		#; If it is already present use a new copy of it uses the current security context
		Do ..EventClassRemove(class,namespace)
		Set i%EventClassContext=$listbuild($listbuild(class,namespace,))_i%EventClassContext
	}
	Quit $$$OK
}

/// Remove an event class from the set of event classes we will run on session events.
/// The namespace is optional and will default to the current namespace. Returns true if it removed
/// the class and false if it did not. If <var>class</var> is null then it will remove all event
/// classes defined in this namespace.
Method EventClassRemove(class As %String, namespace As %String) As %Boolean
{
	#Dim return,eventclasscontext,i,item
	Set return=0
	If $get(namespace)="" Set namespace=$namespace
	Set eventclasscontext=i%EventClassContext
	For i=1:1:$listlength(eventclasscontext) {
		Set item=$listget(eventclasscontext,i)
		If $list(item)=class||(class=""),$list(item,$$$ecNamespaceIdx)=namespace {
			Set eventclasscontext=$list(eventclasscontext,1,i-1)_$list(eventclasscontext,i+1,*),return=1
			Quit
		}
	}
	Set i%EventClassContext=eventclasscontext
	Quit return
}

/// Return true if this event class is present in the current session event list or false otherwise.
/// The namespace is optional and will default to the current namespace.
Method EventClassExists(class As %String, namespace As %String) As %Boolean
{
	#Dim return,eventclasscontext,i,item
	If $get(namespace)="" Set namespace=$namespace
	Set return=0
	Set eventclasscontext=i%EventClassContext
	For i=1:1:$listlength(eventclasscontext) {
		Set item=$listget(eventclasscontext,i)
		If $list(item)=class,$list(item,$$$ecNamespaceIdx)=namespace Set return=1 Quit
	}
	Quit return
}

/// Remove all event classes from the event class list
Method EventClassClear() As %Status
{
	Set i%EventClassContext=""
	Quit $$$OK
}

/// Return an array of Array(namespace,classname)="" of the currently defined event classes
Method EventClassList(ByRef Array As %String) As %Status
{
	#Dim eventclasscontext,i,item
	Set eventclasscontext=i%EventClassContext
	For i=1:1:$listlength(eventclasscontext) {
		Set item=$listget(eventclasscontext,i)
		Set Array($list(item,$$$ecNamespaceIdx),$list(item))=""
	}
	Quit $$$OK
}

/// Internal method to fix context of event class
Method EventClassFix(context As %String) As %Status [ Internal, Private ]
{
	#Dim eventclasscontext,i,item
	Set eventclasscontext=i%EventClassContext
	For i=1:1:$listlength(eventclasscontext) {
		Set item=$listget(eventclasscontext,i)
		If $listdata(item,$$$ecSecContextIdx)=0 Set $list(item,$$$ecSecContextIdx)=context,$list(eventclasscontext,i)=item
	}
	Set i%EventClassContext=eventclasscontext
	Quit $$$OK
}

Property EventClassContext As %String(MAXLEN = "") [ Internal, Private ];

/// The StickyLogin is a description of the user authentication most recently attempted in this session. This is for internal use of the CSP Server.
Property StickyLogin As %String(MAXLEN = "") [ Internal, Private ];

Method StickyLoginGet() As %String [ Internal ]
{
	#dim routine
	
	Set routine=$piece($zutil(41,$zutil(41)-1),"^",3)
	If routine'="%SYS.cspServer" {
		Quit ""
	}

	Quit $get(i%StickyLogin)
}

/// stickyLogin is an exported security context
Method StickyLoginSet(stickyLogin As %String) As %Status [ Internal ]
{
	#dim routine
	
	Set routine=$piece($zutil(41,$zutil(41)-1),"^",3)
	If routine'="%SYS.cspServer" {
		Quit $$$ERROR($$$CSPSecContextCaller)
	}
	Set i%StickyLogin=stickyLogin
	Quit $$$OK
}

/// The namespace this session was created from. This is set automatically when the
/// class is created to the current namespace. It is used by the session daemon so
/// that it can swap to the right namespace to run the timeout method on applications.
Property Namespace As %String;

/// A flag specifying the level of state preservation required by 
/// this session. You can change the value of this flag at any time.
/// <P>This can take one of the following values:
/// <UL>
/// <LI><B>0</B> The only state information that is preserved is the information in the %session object.</LI>
/// <LI><B>1</B> The entire state of the session process is preserved from one request to the next.
/// This means that you tie up this process for just this one user. As it uses the same process
/// all local variables, locks, etc. are preserved from one request to the next.</LI>
/// </UL>
Property Preserve As %Integer [ InitialExpression = 0 ];

/// Set method for Preserve property.
Method PreserveSet(val As %Integer) As %Status [ Internal ]
{
	If val=1,$isobject($get(%request)),'%request.CSPGatewayRequest Set sc=$$$ERROR($$$CSPPreserveInvalid) Do $zutil(96,3,92,1)
	Set i%Preserve=''val
	#; If debugging and they turn off Preserve mode do not let them!
	If i%Debug,val=0 Set val=1
	If $isobject($get(%response)) Do %response.SetPreserve(val)
	Set $extract(i%CSPSessionCookie,4)=$select(val:"p",1:"0")
	Do ..UpdateHMAC()
	Quit $$$OK
}

/// Counter used internally that holds the number of times this session is used.
Property MessageNumber As %Integer [ InitialExpression = 0, Internal ];

/// Set method for MessageNumber property.
Method MessageNumberSet(val As %Integer) As %Status [ Internal, Private ]
{
	Set i%MessageNumber=val
	Quit $$$OK
}

/// Any headers we wish to sent on every request for this session
Property PersistentHeaders As %String(MAXLEN = "") [ Internal ];

Method PersistentHeadersSet(val As %String) As %Status [ Internal, Private ]
{
	Set i%PersistentHeaders=val
	Quit $$$OK
}

/// Set a persistent HTTP header values in the %session object so it will be output for every response from this session.
/// If there is already a header with this name then this will overwrite this prioir header.
Method SetPersistentHeader(name As %String, value As %String)
{
	Set ptr=0,persistentheaders=i%PersistentHeaders,uppername=$zconvert(name,"U")
	For i=1:1 {
		If '$listnext(persistentheaders,ptr,header) {
			#; No entry found so add it
			Set i%PersistentHeaders=persistentheaders_$listbuild($listbuild(name,value))
			Quit
		}
		If $zconvert($list(header),"U")=uppername {
			#; Update existing entry
			Set $list(persistentheaders,i)=$listbuild($listbuild(name,value))
			Quit
		}
	}
}

/// Return the value of the persistent session <var>name</var> header.
/// Note that <var>name</var> is not case sensitive
Method GetPersistentHeader(name As %String) As %String
{
	Set ptr=0,persistentheaders=i%PersistentHeaders,value="",uppername=$zconvert(name,"U")
	While $listnext(persistentheaders,ptr,header) {
		If $zconvert($list(header),"U")=uppername Set value=$list(header,2)
	}
	Quit value
}

/// Remove a persistent header from the session Note that <var>name</var> is not case sensitive
Method DeletePersistentHeader(name As %String)
{
	Set ptr=0,persistentheaders=i%PersistentHeaders,uppername=$zconvert(name,"U")
	For i=1:1 {
		If '$listnext(persistentheaders,ptr,header) Quit
		If $zconvert($list(header),"U")=uppername {
			Set $list(persistentheaders,i,i)="",i%PersistentHeaders=persistentheaders
			Quit
		}
	}
}

/// Counter of number of SOAP requests made to this Session
Property SOAPRequestCount As %Integer [ InitialExpression = 0, Internal ];

/// Update the HMAC portion of the session token
Method UpdateHMAC() [ Internal ]
{
	Set token=$extract(i%CSPSessionCookie,1,$$$cspSIDEnd)
	Set hmac=$extract($$$cspBase64Encode($system.Encryption.HMACSHA(256,token,i%Key)),1,28)
	Set i%CSPSessionCookie=token_hmac
}

/// This is true when this CSP session is being debugged, and false otherwise.
/// It is set automatically by the CSP dispatch engine and you should not 
/// alter its value yourself.
Property Debug As %Boolean [ InitialExpression = 0 ];

/// Set method for Debug property.
Method DebugSet(val As %Integer) As %Status [ Internal ]
{
	If val=i%Debug Quit $$$OK
	Set i%Debug=val
	#; Setting Debug=1 makes this session Preserve=1 without actually changing this property
	If val {
		If i%Preserve=0 {
			Set ..Preserve=1
			Set i%Preserve=0
		}
	} Else {
		Set ..Preserve=i%Preserve
	}
	Quit $$$OK
}

/// Indicates whether this is the first request of the 
/// session (True) or a subsequent request (False).
Property NewSession As %Boolean [ InitialExpression = 1 ];

Method NewSessionSet(val As %Boolean) As %Status
{
	If val=0 {
		Set i%NewSession=0
	} Else {
		$$$CSPLogAll(1,"CSPSession","[NewSessionSet] Invalid attempt to set NewSession: "_val,"", "", i%SessionId )
	}
	Quit $$$OK
}

/// Record the path we sent the last session cookie with
Property CookiePath As %String(MAXLEN = "") [ Internal ];

/// This property contains the browser name based on parsing the HTTP_USER_AGENT CGI variable.
/// This property is set once when the session is created.
/// Possible values are "IE", "Mozilla", "Netscape", "Safari" and "".
/// Not all possible browsers are suppported and the value "" is used for unknown browsers.
/// "Mozilla" is used for all Mozilla based browsers such as Mozilla and Firefox.
Property BrowserName As %String(MAXLEN = "");

Method BrowserNameGet() As %String
{
	If i%BrowserName'=""||(i%UserAgent="") Quit i%BrowserName
	Do ##class(%CSP.UserAgent).XMLHttpRequest(i%UserAgent,.browser,.platform,.version)
	Set i%BrowserName=browser,i%BrowserPlatform=platform,i%BrowserVersion=version
	Quit browser
}

/// This property contains the browser operating system based on parsing the HTTP_USER_AGENT CGI variable.
/// This property is set once when the session is created.
/// Possible values are "Windows", "Macintosh", "X11" and "".
/// Not all possible browsers are supported and the value "" is used for unknown browsers.
Property BrowserPlatform As %String(MAXLEN = "");

Method BrowserPlatformGet() As %String
{
	If i%BrowserPlatform'=""||(i%UserAgent="") Quit i%BrowserPlatform
	Do ##class(%CSP.UserAgent).XMLHttpRequest(i%UserAgent,.browser,.platform,.version)
	Set i%BrowserName=browser,i%BrowserPlatform=platform,i%BrowserVersion=version
	Quit platform
}

/// This property contains the browser version based on parsing the HTTP_USER_AGENT CGI variable.
/// This property is set once when the session is created.
/// The version is "" or in the format "major.minor".
/// Not all possible browsers are supported and the value "" is used for unknown browsers.
Property BrowserVersion As %String(MAXLEN = "");

Method BrowserVersionGet() As %String
{
	If i%BrowserVersion'=""||(i%UserAgent="") Quit i%BrowserVersion
	Do ##class(%CSP.UserAgent).XMLHttpRequest(i%UserAgent,.browser,.platform,.version)
	Set i%BrowserName=browser,i%BrowserPlatform=platform,i%BrowserVersion=version
	Quit version
}

/// Contains the HTTP_USER_AGENT CGI variable passed in the initial session request.
Property UserAgent As %String(MAXLEN = "");

/// Stores the encryption key used to validate and secure the communication with the browser.
/// This key never leaves the server.
Property Key As %String;

/// Private accessor method
Method KeySet(val As %Boolean) As %Status [ Internal, Private ]
{
	Set i%Key=val
	Quit $$$OK
}

/// Indicates whether sessions should be maintained using cookies or not. There are three
/// possible values:<ul>
/// <li><b>0</b> - Never use cookies. This will pass the CSPCHD parameter around in all the
/// url links and as hidden fields in the &lt;FORM&gt; elements.</li>
/// <li><b>1</b> - Auto detect cookie support. This will start by trying to insert a cookie
/// into the browser, if this fails it will switch to mode 0 and never use cookies for this
/// session. The initial page will send both cookies to the browser and it will include the
/// CSPCHD parameter in all links and forms.</li>
/// <li><b>2</b> - Always use cookies. This will only use cookies so if the browser does not
/// accept the cookie then the session state will not be maintained.</li>
/// </ul>
Property UseSessionCookie As %Integer [ InitialExpression = 1 ];

/// Used by the CSP Gateway to store the session Id on the browser. Do not alter this property.
Property CSPSessionCookie As %String(MAXLEN = "");

/// The language (RFC 1766 format) in which pages in this CSP session are to be displayed.
/// The %session Language attribute is used as the default language for csp:text, span and div
/// tags if %response.Language is not set. If %session.Language is not set by the program,
/// then it will default to the best fit with the HTTP_ ACCEPT_LANGUAGE CGI variable.
Property Language As %String;

/// Internal property that hold the name of the license that this session is associated with
Property LicenseId As %String(MAXLEN = "");

/// Set method for LicenseId property.
Method LicenseIdSet(val As %String) As %Status [ Internal, Private ]
{
	Set i%LicenseId=val
	Quit $$$OK
}

/// The username this CSP session is logged in as.
Property Username As %Library.Username [ Calculated ];

/// Get method for Username property.
Method UsernameGet() As %String [ CodeMode = expression ]
{
$username
}

/// If we are passed an 'Authorization' HTTP header the value is stored here to avoid
/// attempting to login with this multiple times, for internal use only.
Property HttpAuthorization As %String(MAXLEN = "");

/// Record if we can not get a license for this session
Property NoLicense As %Boolean [ InitialExpression = 0, Internal, Private ];

/// If true and the CSP gateway supports this then use the HTTP keep alive support to reuse the
/// TCP/IP connection for any additional HTTP requests. If possible you should also supply the
/// Content-Length header otherwise the CSP gateway will have to buffer the output in order to
/// add the length of the message to the header. The default
/// for this property is true to keep the connection alive where possible except for HTTP/1.0 responses
/// where we will use the default for HTTP/1.0 which is to close the connection on each request.
Property KeepAlive As %Boolean [ InitialExpression = 1 ];

/// Stored the CSP application name so we can detect when the CSP application has changed.
/// This is required so we can revalidate the user against any security permissions the other
/// application requires that the first application does not. This is not set until the security
/// context for this application is validated.
Property Application As %String(MAXLEN = "");

/// Set method for Application property.
Method ApplicationSet(val As %String) As %Status [ Internal, Private ]
{
	Set i%Application=val
	Quit $$$OK
}

/// The data/time the session was created in UTC
Property CreateTime As %TimeStamp;

/// Set method for CreateTime property.
Method CreateTimeSet(val As %TimeStamp) As %Status [ Internal, Private ]
{
	Set i%CreateTime=val
	Quit $$$OK
}

/// The date/time when this session was last modified in UTC
Property LastModified As %TimeStamp;

/// Set method for LastModified property.
Method LastModifiedSet(val As %TimeStamp) As %Status [ Internal, Private ]
{
	Set i%LastModified=val
	Quit $$$OK
}

/// For internal use only. Holds a serialized form of the sessions security context
Property SecurityContext As %String(MAXLEN = "") [ Internal ];

/// Set method for SecurityContext property.
Method SecurityContextSet(val As %String) As %Status [ Internal, Private ]
{
	Set routine=$piece($zutil(41,$zutil(41)-1),"^",3)
	If routine'="%SYS.cspServer" Quit $$$ERROR($$$CSPSecContextCaller)
	Set i%SecurityContext=val
	Quit $$$OK
}

/// For internal use only. Holds a serialized form of the session's escalated security context
Property EscalationContext As %String(MAXLEN = "") [ Internal ];

/// Set method for SecurityContext property.
Method EscalationContextSet(val As %String) As %Status [ Internal, Private ]
{
	If $$$GetSYSCallingRoutine'="%SYS.cspServer" {
		Quit $$$ERROR($$$CSPSecContextCaller)
	}
	Set i%EscalationContext=val
	Quit $$$OK
}

/// Escalate the CSP session to the specified escalation role. The role must be one of the current user's configured EscalationRoles. 
Method EscalateLogin(roleName As %String, password As %String) As %Status
{
	Quit $$EscalateLogin^%SYS.cspServer(roleName,password)
}

/// Remove the escalation role added by <Method>EscalateLogin</Method>. If there is no current escalation role, this method does nothing. 
/// After this the sessions's security context will be returned to the user's initial login roles. 
Method ClearEscalation() As %Status
{
	Quit $$ClearEscalation^%SYS.cspServer()
}

/// For internal use only
Property OldTimeout As %String [ Internal ];

Method OldTimeoutSet(val As %String) As %Status [ Internal, Private ]
{
	Set i%OldTimeout=val
	Quit $$$OK
}

/// Login with this username and password, returns a status code to show
/// if it worked or not. This method also trades license units at the same time so
/// this CSP session will be logged in as a named user.
/// If you pass <var>type</var>=1 then this will trade licenses only and not login as this user.
/// After the login completes it also updates the property <property>Username</property> to match the $username
/// value this session is logged in as. The property <property>LicenseId</property> is also updated to be the
/// license identifier that this session is logged in with.<br>
/// If a login fails then the property <property>Username</property> and property <property>LicenseId</property>
/// will remain at their previous values.
/// If you pass <var>oldpassword</var> then this will attempt to change the password of <var>username</var> from
/// <var>oldpassword</var> to <var>password</var> and login as this user.
/// Note new status return values:
/// CSP applications can be two-factor-enabled. If the current application is one such, then if Login() successfully 
/// authenticates the username/password, it does not return $$$OK, but rather $$$CSPPendingTwoFactorAuthentication.
/// During Two-Factor Authentication, an 8-character numeric security string will be sent to the user's 
/// cellphone. You must obtain this string from the 
/// user and call CompleteTwoFactorLogin^%CSP.Session() to complete authentication of this user.
/// Also note that if the login SUCCEEDS (status returned will be $$$OK), but 
/// you were unable to secure a license, the new apperr parameter will have the value of $$$CSPErrorTradeLicense. In such a case, 
/// you may have to call the Login function again to trade a license. If you are calling merely to trade a license (type=1), then 
/// if the license trade fails, Login will return a status of $$$CSPErrorTradeLicense.
Method Login(username As %String, password As %String = "", type As %Integer = 0, oldpassword As %String, apperr As %Status) As %Status
{
	#Dim loginstatus, newlicenseid
	$$$SysLogSetVar
	Set apperr = $$$OK
	
	if (type'=1) { //login in
		Set loginstatus = $$CSPLogin^%SYS.cspServer($this,username,password,.oldpassword,.%request,.apperr,.newlicenseid )
	}
	else { //trading license
		Set newlicenseid=$get(username)
		If newlicenseid="" {
			Set newlicenseid=$$$UnknownUserUsername
		}
		Set loginstatus= $$TradeLicense^%SYS.cspServer($this,.%request,.newlicenseid )
	}
	Quit loginstatus
}

/// If this application has a Two-Factor-Authentication enabled, when this method allows you to finish the second part of the authentication. For example,
/// a security token was sent during the initial login attempt, Login^%CSP.Session().
/// You must obtain this security code (an 8-character numeric string) and call CompleteToFactorLogin() to 
/// complete authencation for this user. 
/// Note: This should only be called if Login^%CSP.Session() returns a status of $$$CSPPendingTwoFactorAuthentication
/// Returns: $$$CSPSecondFactorLoginFailed if request's application was not Two-Factor-Authentication enabled
/// Returns: $$$OK if login was completed
/// Returns: $$$CSPSecurityTokenMismatch is a token was found, but did not match the entered token,
/// else returns the error code which cause the completion to fail
Method CompleteTwoFactorLogin(EnteredToken As %String, apperr As %Status) As %Status [ CodeMode = expression ]
{
$$CompleteTwoFactorLogin^%SYS.cspServer($this, %request, EnteredToken, .apperr )
}

/// The place users can preserve any data within a session. You can set values into this
/// multidimensional property using:
/// <example>
/// Set %session.Data(1,2,"string")="value"
/// Write %session.Data("Key1","Key2"),!
/// Merge %session.Data(5)=array
/// </example>
/// This is faster than using the <method>Get</method> and <method>Set</method> 
Property Data As %String [ MultiDimensional ];

/// Get the value of the user data at <var>index</var>. This is equivalent to:
/// <example>
/// Write $Get(%session.Data(index),default)
/// </example>
/// It is faster to access the property directly rather than use the <method>Get</method>
/// and <method>Set</method> methods. These are kept for backward compatibility.
Method Get(index As %String, default As %String = "") As %String [ CodeMode = expression, Final ]
{
$get(i%Data(index),default)
}

/// Set the value of the user data at <var>index</var> to <var>value</var>. This is
/// equivalent to:
/// <example>
/// Set %session.Data(index)=value
/// </example>
/// It is faster to access the property directly rather than use the <method>Get</method>
/// and <method>Set</method> methods. These are kept for backward compatibility.
Method Set(index As %String, value As %String) [ Final ]
{
	Set i%Data(index)=value
}

/// Return the next <var>index</var> in the user data <property>Data</property>. This
/// has been deprecated in favour of the faster syntax:
/// <example>
/// Write $Order(%session.Data(index))
/// </example>
Method Next(index As %String = "") As %String [ CodeMode = expression, Deprecated, Final ]
{
$order(i%Data(index))
}

/// Remove the <var>index</var> from the user data <property>Data</property>. This
/// has been deprecated in favour of the faster syntax:
/// <example>
/// Kill %session.Data(index)
/// ; Or if index=""
/// Kill %session.Data
/// </example>
Method Kill(index As %String = "") [ Final ]
{
	If index'="" { Kill i%Data(index) } Else { Kill i%Data }
}

/// Tests if a name-value pair <VAR>name</VAR> is defined in the user data.
/// This has been deprecated in favour of the faster syntax:
/// <example>
/// Write $Data(%session.Data(index))
/// </example>
Method IsDefined(index As %String) As %Boolean [ CodeMode = expression, Deprecated, Final ]
{
$data(i%Data(index))
}

/// Unlock the ^%cspSession global so that another process can access this objects storage
/// at the same time. Normally all accesss to the session object is serialised so that only
/// one process can modify the session object at any time. So if you are using
/// frames for example the same CSP user will make requests to get all frames at once, but
/// these will be serialised on the application server side. If you know that a frame will take a while
/// to generate but you do not wish this to hold up the generation of the other frames and
/// you do not need to modify the session object you can call Unlock to unlock this session
/// object so other processors can access it. This should be used with care.
/// The <var>save</var> is for internal use only, by default when you call Unlock if the
/// session is modified we will save the changes before unlocking the session.
Method Unlock(save As %Boolean = 1) As %Status
{
	#Dim sc As %Status
	If i%nosave=1 Set i%%Concurrency=0
	If i%%Concurrency=0 Quit $$$OK
	Set sc=$$$OK
	If save {
		Set sc=$$SaveSession^%SYS.cspServer2($this)
		Set i%nosave=2
	} Else {
		Set i%nosave=3
	}
	Lock -^%cspSession(i%SessionId)
	Set i%%Concurrency=0
	Do $system.CLS.SetModified(0)
	Quit sc
}

Property nosave As %Integer [ InitialExpression = 0, Internal, Transient ];

Property GetNewId As %Boolean [ InitialExpression = 0, Internal, Transient ];

/// If set, this causes the cspServer to destroy the Login Cookie, any 
/// Security Tokens associated with this session, and the Sticky-login associated 
/// with this session's browser. '1' to destory terminate this session upon completion 
/// of this request.
Property LogoutCleanup As %Boolean [ InitialExpression = 0, Internal, Transient ];

/// Holds application licenses taken for this session.<br>
/// Format:  $lb($lb(appname1,type1,type2,...),$lb(appname2,type1,type2,...),...)<br>
/// Controled by $SYSTEM.License.TakeApplicationLicense(AppName,FeatureKeyword,.Count) and $SYSTEM.License.ReturnApplicationLicense(AppName,FeatureKeyword,.Released)
Property ApplicationLicenses As %List [ Internal ];

/// Lock the ^%cspSession global to prevent other InterSystems IRIS processes accessing this objects
/// storage. By default the ^%cspSession global is locked so you only need to call this
/// in rare cases where you use the <method>Unlock</method> and you wish to reaquire the
/// lock afterwards.
Method Lock(timeout As %Integer) As %Status
{
	#Dim data
	If i%%Concurrency||(i%nosave=1) Quit $$$OK
	Lock +^%cspSession(i%SessionId):+$get(timeout)
	If '$test {
		If '$ZB($SYSTEM.Lock.ReturnCode(),1,1) {
			If '$data(timeout) {
				Lock +^%cspSession(i%SessionId):$get(^%SYS("CSP","SessionLockTimeout"),240)
				If '$test Quit $$$ERROR($$$LockFailedToAcquireExclusive,$name(^%cspSession(i%SessionId)))
			} Else {
				Quit $$$ERROR($$$LockFailedToAcquireExclusive,$name(^%cspSession(i%SessionId)))
			}
		}
	}
	#; Update the old timeout value from the disk value now
	Set data=$get(^%cspSession(i%SessionId)) Set i%OldTimeout=$lg(data,$$$sesOldTimeout)
	Set i%%Concurrency=1
	Quit $$$OK
}

/// Initialize CSP session object.
Method %OnNew(initvalue, lock = 1) As %Status [ Internal ]
{
	If $get(initvalue)="" Quit $$$ERROR($$$SessionIdMissing)
	If 'lock Set i%%Concurrency=0,i%nosave=1
	#; Two stage lock so we do not need to look up this global most of the time as we will get the lock immediately and only
	#; wait for the timeout if we have to
	If i%%Concurrency Lock +^%cspSession(initvalue):0 Else  If '$ZB($SYSTEM.Lock.ReturnCode(),1,1) Lock +^%cspSession(initvalue):$get(^%SYS("CSP","SessionLockTimeout"),240) Else  Quit $$$ERROR($$$LockFailedToAcquireExclusive,$name(^%cspSession(initvalue)))
	Set i%SessionId=initvalue Do ..%IdSet(initvalue)
	Set i%Key=$select($get(^%SYS("CSP","NoEncrypt")):"notencrypted",1:$system.Encryption.GenCryptRand(32))
	Set i%PersistentHeaders=$get(^%SYS("CSP","SessionPersistentHeaders"))
	Set i%CreateTime=$zdatetime($ztimestamp,3)
	Do $zutil(67,14,initvalue,$job)
	Do ..DataSetModified(0)
	$$$CSPLogAll(2,"CSPSession", "[%OnNew] Creating new CSP session, nosave="_i%nosave,"","",initvalue)
	Quit $$$OK
}

/// Cleanup CSP session object.
Method %OnClose() As %Status [ Internal, Private ]
{
	If $get(i%%Concurrency),$data(i%"%%OID") Lock -^%cspSession($$$idCurrent)
	Do $zutil(67,14,"",$job)
	Quit $$$OK
}

/// Update the sessionId timeout after activity, for internal use
ClassMethod UpdateTimeout(id As %String) As %Status [ Internal ]
{
	#; If someone else has the lock they will be updating the timeout anyway
	Lock +^%cspSession(id):0 If '$test RETURN $$$OK
	Set sc=$$$OK
	Try {
		Set data=$get(^%cspSession(id)),odata=data
		If data="" Goto exit   ; If session does not exist nothing to do
		#; Turn off transactions for this save
		Set inTransaction=$zutil(139,2)
		Set apptimeout=$lg(data,$$$sesAppTimeout),oldtimeout=$lg(data,$$$sesOldTimeout)
		If apptimeout>31536000 Set apptimeout=31536000
		#; Update the timeout table
		#; If the application can timeout setup the global to say when it will timeout
		If apptimeout'=0 {
			If apptimeout="" Set apptimeout=$$$CSPdefaulttimeout
			Set timeoutAt=$ztimestamp,timeoutAt=($piece(timeoutAt,",")*86400+$piece(timeoutAt,",",2)+apptimeout)\1
			#; No need to update timeout unless it is a 2 second or more change
			If $ZABS(timeoutAt-oldtimeout)>1||((apptimeout<10)&&(timeoutAt'=oldtimeout)) {
				Set ^%cspSession(0,timeoutAt,id)="" 
				Kill ^%cspSession(0,+oldtimeout,id) 
				Set oldtimeout=timeoutAt
			}
		} Else {
			If +oldtimeout {
				Kill ^%cspSession(0,oldtimeout,id)
			}
			Set oldtimeout=0
		}
		Set lastmodified=$zdatetime($ztimestamp,3)
		Set $list(data,$$$sesOldTimeout)=oldtimeout,$list(data,$$$sesAppTimeout)=apptimeout,$list(data,$$$sesLastModified)=lastmodified
		If odata'=data Set ^%cspSession(id)=data
	} Catch {
		Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	}
exit	Lock -^%cspSession(id)#"I"
	#; Turn transactions back on
	If $data(inTransaction) Do $zutil(139,inTransaction)
	RETURN sc
}

/// Load saved session
Method %LoadData(id As %String) As %Status [ Internal, Private ]
{
	#Dim data
	#; Two stage lock to avoid looking up ^%SYS global if we can get the lock straight away
	If i%%Concurrency,i%nosave'=1 {
		Lock +^%cspSession(id):0 If '$test {
			If '$ZB($SYSTEM.Lock.ReturnCode(),1,1) {
				Lock +^%cspSession(id):$get(^%SYS("CSP","SessionLockTimeout"),240) If '$test {
					Quit $$$ERROR($$$LockFailedToAcquireExclusive,$name(^%cspSession(id)))
				}
			} Else {
				Set i%%Concurrency=0
				Set i%nosave=1
			}
		}
	}
	Set data=$get(^%cspSession(id))
	If data="" {
		$$$CSPLogAll(2,"CSPSession","[%LoadData] Session id does not exist","","",id) 
		Quit $$$ERROR($$$SessionIdDoesNotExist,id)
	}
	If 'i%nosave Merge i%Data=^(id,0)
	$$$CSPLogAll(2,"CSPSession","[%LoadData] Loading CSP session, nosave="_i%nosave,data,"",id)
	Set i%SessionId=id
	Set $LG(i%AppTimeout,i%Preserve,i%OldTimeout,i%Key,i%UseSessionCookie,i%Namespace,i%CSPSessionCookie,i%Debug,i%Language,i%LicenseId,i%MessageNumber,i%KeepAlive,i%Application,i%SecurityContext,i%BrowserName,i%BrowserPlatform,i%BrowserVersion,i%CreateTime,i%LastModified,i%HttpAuthorization,i%UserAgent,i%RunNamespace,i%ErrorPage,i%SecureSessionCookie,i%CookiePath,i%EventClassContext,i%StickyLogin,i%GroupId,i%SOAPRequestCount,i%ProcessId,i%ByIdGroups,i%ApplicationLicenses,i%PersistentHeaders,i%Referrer,i%SessionScope,i%UserCookieScope,i%EscalationContext)=data
	Do $zutil(67,14,id,$job)
	#; Reset defaults for values that are not stored.
	Set i%EndSession=0,i%NoLicense=0,i%NewSession=0
	If i%AppTimeout>31536000 Set i%AppTimeout=31536000
	Do $system.CLS.SetModified(0)
	Quit $$$OK
}

/// Save session
Method %SaveData(id As %String, notFinalSave As %Boolean = 0) As %Status [ Internal ]
{
	#Dim sc,inTransaction,timeoutAt
	If i%nosave=1 Quit $$$OK
	#; We do not care if session cookie is changed as this is modified on every request
	Do ..CSPSessionCookieSetModified(0)
	If i%%Concurrency=0,i%nosave {
		If i%nosave'=2||('$system.CLS.GetModified()) Quit $$$OK
		Set sc=..Lock() If $$$ISERR(sc) Quit sc
		Quit ..Unlock()
	}
	Set sc=$$$OK
	Try {
		#; Turn off transactions for this save
		Set inTransaction=$zutil(139,2)
		If i%AppTimeout>31536000 Set i%AppTimeout=31536000
		#; Update the timeout table if this is the final save or we don't have a already have a timeout value
		If (i%OldTimeout="")||(notFinalSave=0) {
			#; If the application can timeout setup the global to say when it will timeout
			If i%AppTimeout'=0 {
				If i%AppTimeout="" Set i%AppTimeout=$$$CSPdefaulttimeout
				Set timeoutAt=$ztimestamp,timeoutAt=($piece(timeoutAt,",")*86400+$piece(timeoutAt,",",2)+i%AppTimeout)\1
				#; No need to update timeout unless it is a 2 second or more change
				If $ZABS(timeoutAt-i%OldTimeout)>1||((i%AppTimeout<10)&&(timeoutAt'=i%OldTimeout)) {
					Set ^%cspSession(0,timeoutAt,id)="" 
					Kill ^%cspSession(0,+i%OldTimeout,id) 
					Set i%OldTimeout=timeoutAt
				}
			} Else {
				If +i%OldTimeout {
					Kill ^%cspSession(0,i%OldTimeout,id)
				}
				Set i%OldTimeout=0
			}
		}	
		Set i%LastModified=$zdatetime($ztimestamp,3)
		#; If nothing modified last request was in the same second so we can exit without updating any globals
		If $$$objModAll() {
			Set ^%cspSession(id)=$ListBuild(i%AppTimeout,i%Preserve,i%OldTimeout,i%Key,i%UseSessionCookie,i%Namespace,i%CSPSessionCookie,i%Debug,i%Language,i%LicenseId,i%MessageNumber,i%KeepAlive,i%Application,i%SecurityContext,i%BrowserName,i%BrowserPlatform,i%BrowserVersion,i%CreateTime,i%LastModified,i%HttpAuthorization,i%UserAgent,i%RunNamespace,i%ErrorPage,i%SecureSessionCookie,i%CookiePath,i%EventClassContext,$get(i%StickyLogin),$get(i%GroupId),i%SOAPRequestCount,i%ProcessId,i%ByIdGroups,i%ApplicationLicenses,i%PersistentHeaders,i%Referrer,i%SessionScope,i%UserCookieScope,i%EscalationContext)
			If ..DataIsModified() {
				If $get(^%SYS("CSP","NewMerge"),0),$zutil(23,1)=5 {
					Do ..GlobalReplace("..Data",$name(^%cspSession(id,0))) 
				} Else {
					Kill ^%cspSession(id,0) Merge ^(0)=i%Data
				}
			}
		}
		$$$CSPLogAll(2,"CSPSession","[%SaveData] Saved: ", ^%cspSession(id),"",id)
	} catch {
		$$$CSPLogErrorVar("CSPSession","[SaveErr] Session-ID: "_id_" ;Error saving session; $ze:"_$zerror)
		Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	}
	#; Turn transactions back on
	Do $zutil(139,inTransaction)
	Do $system.CLS.SetModified(0)
	Quit sc
}

/// Delete saved session data.
ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Internal ]
{
	#Dim session As %CSP.Session
	
	$$$SysLogCondSetVar
	Set session=..GetSession(id)
	If session=$$$NULLOREF {
		Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$CSPSessionNotFound,id))
	}
	#; forceend=2 to release the license associated with this session
	Do session.endSession(,2)
	Quit $$$OK
}

/// End the CSP session, not for public use.<br>
/// timedout - flag set to true if this was ended because of a timeout<br>
/// forceend - 0 to use the 'EndSession' property to see if the session should be ended,
/// and 1 will end the session even if 'EndSession' is false but will not free the license,
/// 2 will force the end of the session and free the license.
Method endSession(timedout, forceend, requestid = "") As %Boolean [ Internal ]
{
	$$$SysLogCondSetVar
	Quit $$endSession^%SYS.cspServer(.timedout,.forceend,requestid)
}

/// Log data to CSP session object.
Method Log(msg As %String, data As %Binary = "") [ Internal ]
{
	Set ^%cspSession(i%SessionId,1,$Increment(^%cspSession(i%SessionId,1)))=$ListBuild($ZTS,msg,data)
	Quit
}

/// Retrieve session object associated with sessionId
ClassMethod GetSession(sessionId As %String, CSPSessionCookie As %String = "", lock As %Boolean = 1, request As %CSP.Request) As %CSP.Session [ Internal ]
{
	#Dim session,appdata
	Quit:$Get(sessionId)="" ""
	Set session=$$$NULLOREF
	Try {
		#; Two stage lock to avoid having to look up ^%SYS global if we can get lock immediately
		If lock Lock +^%cspSession(sessionId):0 Else  If '$ZB($SYSTEM.Lock.ReturnCode(),1,1) Lock +^%cspSession(sessionId):$get(^%SYS("CSP","SessionLockTimeout"),240) Else  Return ""
		If $data(^%cspSession(sessionId)) {
			Set session=..%Open($$$oidForm(sessionId),lock)
			If session'=$$$NULLOREF,'lock Set session.nosave=1
		}
		If session=$$$NULLOREF {
			Set session=..%New(sessionId,lock)
			If $isobject($get(request))=1 {
				Set appdata=request.AppData
				Set session.AppTimeout=$select($$$GetSecurityApplicationsTimeout(appdata)="":$$$CSPdefaulttimeout,1:$$$GetSecurityApplicationsTimeout(appdata))
				Set session.UseSessionCookie=$select($$$GetSecurityApplicationsUseCookies(appdata)'="":$$$GetSecurityApplicationsUseCookies(appdata),1:1),session.Namespace=$$$GetSecurityApplicationsNameSpace(appdata)
				Set session.SessionScope=$$$GetSecurityApplicationsSessionScope(appdata)
				Set session.UserCookieScope=$$$GetSecurityApplicationsUserCookieScope(appdata)
				Set session.Referrer=$get(request.CgiEnvs("HTTP_REFERER"))
				If request.Secure Set session.SecureSessionCookie=1
			}
		}
	} Catch exception {
		If lock Lock -^%cspSession(sessionId)#"I"
		Throw exception
	}
	If lock Lock -^%cspSession(sessionId)#"I"
	If CSPSessionCookie'="" Set $extract(CSPSessionCookie,$$$cspSIDStart,$$$cspSIDEnd)=$justify(sessionId,$$$cspSIDLength) Set session.CSPSessionCookie=CSPSessionCookie
	If 'lock Set session.nosave=1
	Quit session
}

/// Allow sessionId of existing session to be udpated to a brand new value
Method ChangeSessionId(sessionId As %String, request As %CSP.Request) [ Internal, Private ]
{
	Set sc=$$$OK,nosave=i%nosave,cookie=i%CSPSessionCookie,appdata=request.AppData
	If nosave=0 {
		Lock +^%cspSession(sessionId):$get(^%SYS("CSP","SessionLockTimeout"),240) Else  Quit $$$ERROR($$$CSPUnableToLock)
	}
	Try {
		If $data(^%cspSession(sessionId)) Set sc=$$$ERROR($$$GeneralError,"New sessionId already exists") Goto exit
		Set sc=..%Destruct() If $$$ISERR(sc) Goto exit
		Do ..Reset()
		Set sc=..%OnNew(sessionId,nosave'=1) If $$$ISERR(sc) Goto exit
		If cookie'="" Set $extract(cookie,$$$cspSIDStart,$$$cspSIDEnd)=$justify(sessionId,$$$cspSIDLength) Set i%CSPSessionCookie=cookie Do ..UpdateHMAC()
		Set i%AppTimeout=$select($$$GetSecurityApplicationsTimeout(appdata)="":$$$CSPdefaulttimeout,1:$$$GetSecurityApplicationsTimeout(appdata))
		Set i%UseSessionCookie=$select($$$GetSecurityApplicationsUseCookies(appdata)'="":$$$GetSecurityApplicationsUseCookies(appdata),1:1),i%Namespace=$$$GetSecurityApplicationsNameSpace(appdata)
		Set i%SessionScope=$$$GetSecurityApplicationsSessionScope(appdata)
		Set i%UserCookieScope=$$$GetSecurityApplicationsUserCookieScope(appdata)
		Set i%Referrer=$get(request.CgiEnvs("HTTP_REFERER"))
		#; As this is a new session we need to set the i%SecureSessionCookie based on the current request.Secure setting as this is initialized in CSPDispatch^%SYS.cspServer
		If request.Secure Set i%SecureSessionCookie=1
	} Catch {
		Set sc=$$$ERROR($$$GeneralError,$zerror)
	}
exit	Lock -^%cspSession(sessionId)#"I"
	Quit sc
}

/// Resets this %CSP.Session object to its initial state
Method Reset() [ CodeMode = generator, Final, Private ]
{
	Set %code=0,set="",kill=""
	Set var=$$$comMemberNext(%class,$$$cCLASSinstancevar,"")
	While var'="" {
		$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,var,$$$cPROPruntimetype)
		Set classtype=$$$getClassType(runtimetype),qvar=$$$QN(var)
		If classtype'=$$$cCLASSCLASSTYPEDATATYPE {
			If var="Content"||(classtype=$$$cCLASSCLASSTYPEPERSISTENT)||(classtype=$$$cCLASSCLASSTYPESERIAL) {
				Set set=set_",r%"_qvar_"=$$$NULLOREF,i%"_qvar_"=$$$NULLOID" If $length(set)>80 $$$GENERATE("	Set "_$extract(set,2,*)) Set set=""
			} Else {
				Set set=set_",i%"_qvar_"=$$$NULLOREF" If $length(set)>80 $$$GENERATE("	Set "_$extract(set,2,*)) Set set=""
			}
		} ElseIf '$$$comMemberKeyGet(%class,$$$cCLASSproperty,var,$$$cPROPmultidimensional) {
			Set set=set_",i%"_qvar_"="_$$$comMemberKeyGet(%class,$$$cCLASSinstancevar,var,$$$cIVARinitialexpression) If $length(set)>80 $$$GENERATE("	Set "_$extract(set,2,*)) Set set=""
		} Else {
			Set kill=kill_",i%"_qvar
		}
		Set var=$$$comMemberNext(%class,$$$cCLASSinstancevar,var)
	}
	If set'="" $$$GENERATE("	Set "_$extract(set,2,*))
	If kill'="" $$$GENERATE("	Kill "_$extract(kill,2,*))
	Quit $$$OK
}

/// Internal function called when InterSystems IRIS restarts
ClassMethod SystemRestart() As %Status [ Internal ]
{
	Do systemRestart^%SYS.cspServer()
	Quit $$$OK
}

/// Standard extent query
Query Extent() As %Query(CONTAINID = 1, ROWSPEC = "ID:%String") [ SqlProc ]
{
}

/// Execute method for Extent query
ClassMethod ExtentExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Set qHandle=0
	Quit $$$OK
}

/// Fetch method for Extent query
ClassMethod ExtentFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ExtentExecute ]
{
	Set Row="",AtEnd=0
	Set qHandle=$order(^%cspSession(qHandle))
	If qHandle="" Set AtEnd=1 Quit $$$OK
	Set Row=$listbuild(qHandle)
	Quit $$$OK
}

/// Close method for Extent query
ClassMethod ExtentClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ExtentExecute ]
{
	Kill qHandle
	Quit $$$OK
}

/// Standard extent query
Query SessionInfo() As %Query(CONTAINID = 1, ROWSPEC = "ID:%String,Username:%String,Preserve:%Integer,Application:%String,Timeout:%TimeStamp,LicenseId:%String,SesProcessId:%String,AllowEndSession:%Boolean") [ SqlProc ]
{
}

/// Execute method for Extent query
ClassMethod SessionInfoExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Set qHandle=0
	Quit $$$OK
}

/// Fetch method for Extent query
ClassMethod SessionInfoFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ExtentExecute ]
{
	#Dim data,timeout,username
	Set Row="",AtEnd=0
	Set qHandle=$order(^%cspSession(qHandle),1,data)
	If qHandle="" Set AtEnd=1 Quit $$$OK
	Set timeout=$listget(data,$$$sesOldTimeout)
	If timeout'="" {
		Try {
			Set timeout=$zdt((timeout\86400)_","_(timeout#86400),3)
		} Catch {
			Set timeout=""
		}
	}
	Set username=$listget($listget(data,$$$sesSecurityContext))
	Set allowendsession=1
	If (($E($listget(data,$$$sesApplication),1,9)="/csp/sys/") || ($listget(data,$$$sesPreserveFlag)=1)) Set allowendsession=0
	Set Row=$listbuild(qHandle,username,$listget(data,$$$sesPreserveFlag),$listget(data,$$$sesApplication),timeout,$listget(data,$$$sesLicenseId),$lg(data,$$$sesProcessId),allowendsession)
	Quit $$$OK
}

/// Close method for Extent query
ClassMethod SessionInfoClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ExtentExecute ]
{
	Kill qHandle
	Quit $$$OK
}

Method ProcessRequest(request, response, ByRef preserve) [ Internal ]
{
	Do CSPDispatch^%SYS.cspServer(request,response,.preserve)
}

Method SetContext() [ Internal ]
{
	#Dim timestamp
	Set i%SecurityContext=$system.Security.Users.ExportSecurityContext(),..MessageNumber=$$$MultiPageSession,..LicenseId=$system.License.GetUserId()
	Set ..Application="/dummyXXX"
	#; Create this session 2 seconds ago so when it is released it is never in grace period
	Set timestamp=$ztimestamp,timestamp=$piece(timestamp,",")*86400+$piece(timestamp,",",2),timestamp=timestamp-2,timestamp=(timestamp\86400)_","_(timestamp#86400)
	Set ..CreateTime=$zdatetime(timestamp,3)
	#; Need to recompute the HMAC based on the new token and return this as the cookie
	Do ..UpdateHMAC()
}

Method Callback(method As %String) [ Internal ]
{
	Quit $$OnCallback^%SYS.cspServer($this,method)
}

/// Logout all CSP sessions for the indicated user.
/// Callbacks can't stop logout
/// The login cookie and any pending-second-factor logins are cancelled.
/// Note: username="" implies username=$username.
/// Note: $Roles must have "%All" to call this
/// Note: LogoutAll calls %SaveData on the changed sessions.
Method LogoutAll(username As %String = "")
{
	quit $$LogoutAllUserSessions^%SYS.cspServer(username, %request, %response )
}

/// This call logs out the current session. The EndSession is not set to 1. 
/// This call uses the stored security context from the Event Class Context to call "OnLogout" Event Class callbacks, 
/// so the caller of Logout() must have sufficient privileges to call $System.Security.Users.ImportSecurityContext() if callbacks exist.
/// The OnLogout callback may set EndSession to 1, if desired.
/// The Session is logged out only if there are no callbacks, the "OnLogout" callbacks return $$$OK, or 'force' is true.
/// If the caller has the %All role, the login cookie will also be destroyed and any pending second factor tokens for this session will be deleted.
/// Note: Caller must do a %SaveData() on the session instance
Method Logout(force As %Integer = 0)
{
	try 
	{
		#Dim status As %Status
		#Dim exp As %Exception.AbstractException
	
		Set status = ..Callback("OnLogout")
	
		if ( (force || $$$ISOK(status))&& ((i%SecurityContext'="")||(i%StickyLogin'="")))
		{
			#Dim app as %String
			Set app = i%Application
			Do ..EventClassFix(i%SecurityContext)
			Set i%SecurityContext = ""
			Set i%StickyLogin = ""
			Set i%Application = ""
			Set i%LogoutCleanup = 1
			Set i%EscalationContext = ""
			Do AUDITLOGOUT^%SYS.SECURITY(app_" "_$$$GetMsg($$$AuditMsg,"ExplicitLogout"),app_" logout")
		}
		$$$CSPLogAll(2,"CSPSession","[Logout] status="_$$$GETERRORCODE(status),status,"", i%SessionId )
	} 
	catch exp 
	{
		#Dim msg as %String
			
		if (($Data(exp)&1)=1) {
			Set msg = exp.DisplayString()
		}
		
		$$$CSPLogAll(2,"CSPSession","[Logout] Catch Exception: "_$get(msg),"","", i%SessionId )
	}
	Quit status
}

/// Return the Username from the by-id groups sticky context. This could be 
/// the empty string if no authenticated user has logged into the group yet. 
Method GetByIdUsername(runtimeGroupId As %String) As %String [ Internal ]
{
	#Dim username,groupByIdItem,stickyLogin,stickyContext
	
	Set username = ""
	Set groupByIdItem = $get($$$GroupByIdSlot(runtimeGroupId)) 
	if $get(groupByIdItem)'="" {
		Set stickyLogin = $$$giLoginStateG(groupByIdItem)
		if (stickyLogin'="") {
		  	set stickyContext = $$$lsSecContextG(stickyLogin)
		  	if ( stickyContext'="" ) {
				Set username = $$$gSecurityContextUsername(stickyContext)
		  	}
		}
	}
	Quit username
}

/// CheckLinkAccess determines whether the target user is permitted
///    to view a given CSP or Zen page based on the security requirements 
///   for the relevant target Web application, the underlying page class, 
///   and any custom resources applied to the link.
/// <p>Positive return values indicate that there is already enough information to 
/// determine if the link should be enabled (Target variables may be undefined.). 
/// Negative values indicate that further processing
/// needs to be done. Checking that the Target User can be logged into the Target Application 
/// and/or checking if the link's page has target resources which the Target User 
/// must have privileges to.</p>
/// <p>Returns 0 if the link is not to a csp application. (enable)</p>
/// <p>Returns 1 if the user is permitted access to the page. (enable) </p>
/// <p>Returns 2 if could not determine Target User. Clicking on link will bring up login page. (choice: enable or disable)</p>
/// <p>Returns 3 if the user doesn't have access to the CSP application.(disable)</p>
/// <p>Returns 4 if the user doesn't have resources specific to the page.(disable)</p>
/// <p>Returns -1 if check both if the Target User can log into the Target Application 
/// and check the Page's resources if any.</p>
/// <p>Returns -2 just check for access to the link's Page's resources, if any.</p>
/// <ol>
/// <li>It is assumed the GetLinkTargets is called from a context in which 
///    %request is available, ie, from callpage in the CSP Server </li>
/// <li>Definitions:
///    <ol><li>Source application - application in which the current caller is being run</li>
///    <li>Current user - ($Username) the user currently logged into the Source Application</li>
///   <li>Target Application - the application pointed to by the link</li>
///    <li>Target User - the computed username under which the user will be logged 
///       into the Target Application</li>
///    <li>Target Page: the page portion of the link, e.g., /csp/app/mypage.csp:  mypage.csp</li>
///   </ol></ol>
/// <p>This method is meant to be called from the link's containing page 
///   within the context of the CSP server. The containing page is part of a 
///   session's current application.</p>
/// <p>We must be able to detemine which target user will be used to check privileges. The target user cannot be 
/// determined if the source and target applications are different and the target is neither part of an active 
/// by-id group nor sharing-sessions with the source application.</p>
/// <p>Applications share sessions when:</p>
/// <ul>
/// <li>The source and target are the same application.</li>
/// <li>The link to the target page contains CSPSHARE=1.</li>
/// <li>Source and target applications have the same Session Cookie Path.</li>
/// </ul>
/// <h3>Who is the target user?</h3>
///  <p>Since this is called from with a CSP session, there are the following situations:</p>
///  <ol>
/// <li>The target application is a member of an authenticated by-id group. That group's
///  authenticated user is the Target User.</li>
/// <li>If the target application will be in the current session, the CSP server has already 
/// handled logic for determing the user.
///  <ol>
///   <li>The session's user is not UnknownUser. The target user is $Username.</li>
///   <li>The session's user is UnknownUser
/// <ul>
/// <li>If the target application is the same as the source application, the Target User is UnknownUser.</li>
/// <li>If the target application is different, the target user is the user from the session's Sticky-context.
/// If the session has no sticky-context, the Target User will be UnknownUser</li>
/// </ul></li>
/// </li></ol></li></ol>
///  <h3>CheckLinkAccess Policies</h3>
/// <ul>
/// <li>If the Target Application is not a CSP Application, return ENABLE/UNKNOWN	</li>	
/// <li>If the Source and Target application are the same, return CHECK_RESOURCES_ONLY.</li> 		
/// <li>If the Target Application is not enabled, return NO_APP_ACCESS	</li>	
/// <li>If the Target Application is part of an authenticated By-ID group, set Target User to group's User, return CHECK_ALL</li>	
/// <li>If the Target Application is part of an authenticated By-Session group, set Target User to group's User, return CHECK_ALL</li>	
/// <li>If the Target Application is neither in an authenticated by-id group nor in the Source Application's session, return ENABLE/UNKNOWN</li>		
/// <li>If an exception occurs, return NO_ACCESS_TO_RESOURCE</li>	
/// </li>
/// </ul>
Method GetLinkTargets(link As %String, ByRef targetUsername As %String, ByRef targetAppName As %String, ByRef targetNamespace As %String) As %Integer
{
	#Dim path,match,targetAppSpec,accessStatus,browserId,targetGroupId,targetCookiePath,stickyContext
	try {
		Set targetUsername = ""

		#; get this applications specification
		Set targetAppSpec = $$getapp^%SYS.cspServer(link,.path,.match)
		If (targetAppSpec = "" ) {
			Set accessStatus = $$$caNotCSPLink // This link is not to a CSP application: can access link
		} 
		else
		{ 
			Set targetAppName = $$$GetSecurityApplicationsName(targetAppSpec)
			Set targetNamespace = $$$GetSecurityApplicationsNameSpace(targetAppSpec)
			if ( %session.Application = match ) { 
				Set targetUsername = $Username
				Set accessStatus = $$$caCheckResourcesOnly  // same application: just check the page resources
			}
			elseif ('$$$GetSecurityApplicationsCSPZENEnabled(targetAppSpec)){
				Set accessStatus = $$$caNoAccessToApp  // The CSP application is disabled: no access to app
			}
			else {
				#; Target application is different from Source.
				#; This value will be reset if Target App is in an authenticated by-id group
				#; or is sharing the session with the current application.
				Set accessStatus = $$$caUnknownTarget
				#; Figure out who the Target User is
				Set browserIdCookie = $get(%request.Cookies($$$BrowserIdCookieName,1))
				If $data(%request.Cookies($$$BrowserIdCookieName,2))#2 {
					#; there can only be one BrowserId cookie
					Set browserIdCookie = ""
				}
				Set browserId = $select(browserIdCookie'="":$get($$$GroupIdFromCookie(browserIdCookie)), 1:"")
				Set targetGroupId = $$$GetSecurityApplicationsGroupById(targetAppSpec)
				#; is there enough information to create a runtime group-by-id identifier?
				if ( (targetGroupId '= "") && (browserId'="") ) {
					#; get the username for the by-id group of which the target application is a member.
					#Dim groupByIdItem,stickyLogin
					Set targetUsername = ""
					Set groupByIdItem = $get($$$GroupByIdSlot($$$bldRunGroupId(targetGroupId,browserId))) 
					if groupByIdItem'="" {
						Set stickyLogin = $$$giLoginStateG(groupByIdItem)
						if (stickyLogin'="") {
		  					set stickyContext = $$$lsSecContextG(stickyLogin)
		  						if ( stickyContext'="" ) {
									Set targetUsername = $$$gSecurityContextUsername(stickyContext)
		  						}
							}
					}

					#; (could be empty string if no authenticated user for this by-id group yet)
					if (targetUsername'="") {
		    			Set accessStatus = $$$caCheckAll // authenticated by-id group with different app: do full checking
					}
				}
		
				if ( targetUsername = "" ) { // if did not use by-id sharing
					#; check to see of using session sharing
					Set targetCookiePath = $$$GetSecurityApplicationsCookiePath(targetAppSpec)
					if ((targetCookiePath=$$$GetSecurityApplicationsCookiePath(%request.AppData) ) || ( $zcvt(link,"U")["CSPSHARE=1")) {
						#; using session sharing

						if ( i%StickyLogin'="")  {
						  	set stickyContext = $$$lsSecContextG(i%StickyLogin)
						  	if ( stickyContext'="") {
								Set targetUsername = $$$gSecurityContextUsername(stickyContext)
						  	}
						}
						#; could be "" if no authenticated user has logged into this session yet, i.e. $Username should be UnknownUser
						if (targetUsername="" ) {
							Set targetUsername = $Username
						}
						Set accessStatus = $$$caCheckAll  // session sharing with different app: do full checking
					}
				} 
			}
		}
	} catch { 
		Set accessStatus = $$$caNoAccessToRes  // some error occurred:  no access to page
	}
		
	Quit accessStatus
}

Method GlobalReplace(source As %String, dest As %String)
{
	Set sourcedata=$data(@source,data)#10,destdata=$data(@dest,data2)#10
	If sourcedata {
		If 'destdata||(data'=data2||($length(data)<100&&($lb(data)'=$lb(data2)))) {
			Set @dest=data
		}
	} ElseIf destdata {
		ZKill @dest
	}
	Set sourcenode=$query(@source,1,sourcedata)
	#; Handle multidim property source node case
	If $extract(sourcenode,1,9)="$ZOBJREF(" {
		Set source=$piece(source,".",2,*),source=$piece(sourcenode,source)_source
	}
	Set sourcestart=$select($extract(source,*)=")":$extract(source,1,*-1)_",",1:source_"("),sourcesub=$extract(sourcenode,$length(sourcestart)+1,*)
	If $extract(sourcenode,1,$length(sourcestart))'=sourcestart Set sourcenode="",sourcedata="",sourcesub=""
	Set destnode=$query(@dest,1,destdata)
	#; Handle multidim property dest node case
	If $extract(destnode,1,9)="$ZOBJREF(" {
		Set dest=$piece(dest,".",2,*),dest=$piece(destnode,dest)_dest
	}
	Set deststart=$select($extract(dest,*)=")":$extract(dest,1,*-1)_",",1:dest_"("),destsub=$extract(destnode,$length(deststart)+1,*)
	If $extract(destnode,1,$length(deststart))'=deststart Set destnode="",destdata="",destsub=""
	While sourcenode'=""||(destnode'="") {
		Set movesource=0,movedest=0
		If sourcesub=destsub,sourcenode'="",destnode'="" {
			If destdata'=sourcedata||($length(destdata)<100&&($lb(destdata)'=$lb(sourcedata))) {
				Set @destnode=sourcedata
			}
			Set movesource=1,movedest=1
		} ElseIf destnode'="",sourcenode=""||(..collate(sourcesub,destsub)=-1) {
			#; Need to remove dest node as it is not in the source
			Kill @destnode
			Set movedest=1
		} Else {
			#; Need to copy over source node
			Set @(deststart_sourcesub)=sourcedata
			Set movesource=1
		}
		If movesource {
			Set sourcenode=$query(@sourcenode,1,sourcedata),sourcesub=$extract(sourcenode,$length(sourcestart)+1,*)
			If $extract(sourcenode,1,$length(sourcestart))'=sourcestart Set sourcenode="",sourcedata="",sourcesub=""
		}
		If movedest {
			Set destnode=$query(@destnode,1,destdata),destsub=$extract(destnode,$length(deststart)+1,*)
			If $extract(destnode,1,$length(deststart))'=deststart Set destnode="",destdata="",destsub=""
		}
	}
	Quit
}

ClassMethod collate(source As %String, dest As %String) [ Private ]
{
	If source=dest Quit 0
	If $extract(source,1,*-1)=$extract(dest,1,*-1) {
		Quit $select($length(source)>$length(dest):-1,1:1)
	}
	Set source="^X("_source,dest="^X("_dest
	Set result=0
	Set sourceql=$ql(source),destql=$ql(dest)
	For i=1:1:$select(sourceql<destql:sourceql,1:destql) {
		If $qs(source,i)'=$qs(dest,i) {
			Set result=$select($qs(source,i)]]$qs(dest,i):-1,1:1) Quit
		}
	}
	If result=0 {
		If sourceql>destql Set result=-1
		If sourceql<destql Set result=1
	}
	Quit result
}

Storage custom
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%CSP.SessionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
