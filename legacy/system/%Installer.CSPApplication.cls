/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "CSPApplication" activity within a Manifest document
Class %Installer.CSPApplication Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Application URL
Property Url As %String(MAXLEN = 1024) [ Required ];

/// Application Description
Property Description As %String(MAXLEN = 1024);

/// Path to CSP files.
Property Directory As %String(MAXLEN = 1024) [ Required ];

/// Resource required to access web app.
Property Resource As %String;

/// Flag to Recurse (service subdirectories)
Property Recurse As %Installer.Boolean [ InitialExpression = 0 ];

/// Login class
Property LoginClass As %String(MAXLEN = 128);

/// Session cookie path
Property CookiePath As %String(MAXLEN = 256);

/// Flags for enabled authentication methods. <br>
/// Commonly used values are 4=Kerberos, 32=password, and 64=unauthenticated. <br>
/// For supported authentication methods and the corresponding values to provide, see the AutheEnabled property in Security.Applications. <br>
/// If not specified, the default value depends on the installation type <br>
/// 
Property AuthenticationMethods As %String;

/// Lock CSP Name property
Property LockCSPName As %Installer.Boolean [ InitialExpression = 1 ];

/// Event Class
Property EventClass As %String(MAXLEN = 256);

/// Session timeout
Property DefaultTimeout As %Installer.Integer;

/// Default Superclass 
Property DefaultSuperclass As %String(MAXLEN = 256);

/// Use Cookie for Session 
Property UseSessionCookie As %Installer.Integer;

/// Service Files <br>
/// 0-No<br>
/// 1-Always<br>
/// 2-Always and cached<br>
/// 3-Use InterSystems security<br>
/// 
Property ServeFiles As %Installer.Boolean;

/// Serve Files Timeout 
Property ServeFilesTimeout As %Installer.Integer;

/// Custom Error Page 
Property CustomErrorPage As %String(MAXLEN = 1024);

/// Package Name 
Property PackageName As %String(MAXLEN = 256);

/// Change Password Page
Property ChangePasswordPage As %String(MAXLEN = 1024);

/// Group By ID
Property GroupById As %String(MAXLEN = 1024);

/// Flag for CSP ZEN Enabled
Property CSPZENEnabled As %Installer.Boolean [ InitialExpression = 1 ];

/// Flag for inbound web services enabled
Property InboundWebServicesEnabled As %Installer.Boolean [ InitialExpression = 1 ];

/// Flag for two factor authentication enabled
Property TwoFactorEnabled As %Installer.Boolean [ InitialExpression = 0 ];

/// Is Namespace default
Property IsNamespaceDefault As %Installer.Boolean [ InitialExpression = 0 ];

/// PermittedClasses default
Property PermittedClasses As %String;

/// Autocompile flag
Property AutoCompile As %Installer.Boolean [ InitialExpression = 1 ];

/// If defined, this will dispatch all requests in this CSP application to this one class.
Property DispatchClass As %String(MAXLEN = 256);

/// Mapping of Match Roles to added Target Roles
Property MatchRoles As %String(MAXLEN = 32767);

/// Resource(s) granted when logged in.
Property Grant As %String(MAXLEN = 512);

/// SameSite value that is used for CSP Session cookies.<br>
/// For REST and CSP Web Application only.<br>
/// This setting affects whether session cookies are sent for cross-site requests. <br>
/// The default setting for a new application is Strict.<br>
/// 0 - None - Send cookie with cross-site requests .<br>
/// 1 - Lax - Send cookie with top-level cross-site navigation. <br>
/// 2 - Strict - Do not send cookie with cross-site requests. Default.<br>
Property SessionScope As %Integer(DISPLAYLIST = ",None,Lax,Strict", VALUELIST = ",0,1,2");

/// Default SameSite value for cookies created by users' calls to %CSP.Response.SetCookie().<br>
/// For REST and CSP Web Application only.<br>
/// This setting affects whether session cookies are sent for cross-site requests. <br>
/// Users can override the default by specifying the SameSite value in their SetCookie call.<br>
/// 0 - None - Send cookie with cross-site requests .<br>
/// 1 - Lax - Send same-site cookies with top-level cross-site navigation. <br>
/// 2 - Strict - Do not send same-site cookies with cross-site requests. Default.
Property UserCookieScope As %Integer(DISPLAYLIST = ",None,Lax,Strict", VALUELIST = ",0,1,2");

/// Prevent login CSRF attack.<br>
/// For CSP Web Application only.<br>
/// When enabled generate a token and cookie in the login page that is validated before accepting 
/// any username/password. Enabling this will prevent programatic access to pages in this application 
/// that just pass in the username/password on the initial request. It also prevents the use of the
/// CSPSHARE=1 URL Parameter to pass the session token in the URL when cookies are required for the application. 
Property CSRFToken As %Installer.Boolean;

/// Indicates whether DeepSee access is enabled for this application.<br>
/// For CSP Web Application only.<br>
/// Corresponds with the Analytics option shown in Management Portal<br>
Property DeepSeeEnabled As %Installer.Boolean;

/// Indicates whether iKnow access is enabled for this application.
/// Like the DeepSeeEnabled property , this corresponds with the Analytics option shown in Management Portal. 
Property iKnowEnabled As %Installer.Boolean;

/// Indicates that this application uses JWT Bearer tokens for authentication. 
/// For REST Web Application only.<br>
Property JWTAuthEnabled As %Installer.Boolean;

/// Specifies the timeout (in seconds) for JWT Access Tokens. 
/// This is only relevant for REST Web Applications where <property>JWTAuthEnabled</property> is true.
Property JWTAccessTokenTimeout As %Integer(MINVAL = 1);

/// Specifies the timeout (in seconds) for JWT Refresh Tokens. 
/// This is only relevant for REST Web Applications where <property>JWTAuthEnabled</property> is true.
Property JWTRefreshTokenTimeout As %Integer(MINVAL = 1);

/// This specifies whether to use FHIR-standard redirects of empty paths.<br>
/// For REST Web Application only.<br>
/// For example, if the request is for WPath/csp/appname and the app /csp/appname/<br>
/// has this property enabled, then instead of serving the request with the next level down<br>
/// (csp, if it exists), the request will be served by /csp/appname/.
Property RedirectEmptyPath As %Installer.Boolean;

/// This is the path of the directory containing the python application
Property WSGIAppLocation As %String(MAXLEN = 256);

/// This is the name of the WSGI-compliant python application (e.g flask_app)
Property WSGIAppName As %String(MAXLEN = 256);

/// This is the name of the WSGI application callable.
Property WSGICallable As %String(MAXLEN = 256);

/// This describes if the WSGI application is in Debug Mode
Property WSGIDebug As %Installer.Boolean;

/// This determines if the application is WSGI or ASGI compliant.
Property WSGIType As %Integer(DISPLAYLIST = ",WSGI,ASGI", VALUELIST = ",1,2");

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.CSPApplication($$$EVAL1("_..Url_"),tNSName,$$$EVAL1("_..Description_"),$$$EVAL1("_..Directory_"),$$$EVAL1("_..Resource_"),$$$EVAL1("_..Recurse_"),$$$EVAL1("_..LoginClass_"),$$$EVAL1("_..CookiePath_"),$$$EVAL1("_..AuthenticationMethods_"),$$$EVAL1("_..LockCSPName_"),$$$EVAL1("_..EventClass_"),$$$EVAL1("_..DefaultTimeout_"),$$$EVAL1("_..DefaultSuperclass_"),$$$EVAL1("_..UseSessionCookie_"),$$$EVAL1("_..ServeFiles_"),$$$EVAL1("_..ServeFilesTimeout_"),$$$EVAL1("_..CustomErrorPage_"),$$$EVAL1("_..PackageName_"),$$$EVAL1("_..ChangePasswordPage_"),$$$EVAL1("_..GroupById_"),$$$EVAL1("_..CSPZENEnabled_"),$$$EVAL1("_..InboundWebServicesEnabled_"),$$$EVAL1("_..TwoFactorEnabled_"),$$$EVAL1("_..IsNamespaceDefault_"),$$$EVAL1("_..PermittedClasses_"),$$$EVAL1("_..AutoCompile_"),$$$EVAL1("_..DispatchClass_"),$$$EVAL1("_..MatchRoles_"),$$$EVAL1("_..Grant_"),$$$EVAL1("_..SessionScope_"),$$$EVAL1("_..UserCookieScope_"),$$$EVAL1("_..CSRFToken_"),$$$EVAL1("_..DeepSeeEnabled_"),$$$EVAL1("_..iKnowEnabled_"),$$$EVAL1("_..JWTAuthEnabled_"),$$$EVAL1("_..JWTAccessTokenTimeout_"),$$$EVAL1("_..JWTRefreshTokenTimeout_"),$$$EVAL1("_..RedirectEmptyPath_"),$$$EVAL1("_..WSGIAppLocation_"),$$$EVAL1("_..WSGIAppName_"),$$$EVAL1("_..WSGICallable_"),$$$EVAL1("_..WSGIDebug_"),$$$EVAL1("_..WSGIType_"))")
	Quit $$$OK
}

}
