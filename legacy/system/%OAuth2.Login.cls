/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %OAuth2.Login is the base class for login pages which use OAuth 2.0 or OpenID Connect.
/// The usual login class will only override the APPLICATION and SCOPE parameters.
/// Additional customization may be done by overriding the RESPONSEMODE parameter and DefineProperties method.
/// <p>The login page will directly log in the session using delegated authentication.
/// For an example ZAUTHENTICATE routine, see the
/// <a href="https://github.com/intersystems/Samples-Security">Samples-Security</a> repo in GitHub.</p>
Class %OAuth2.Login Extends %CSP.Login
{

/// The application name for the application being logged into.<br>
/// The actual login page will need to override this parameter.
Parameter APPLICATION As STRING;

/// The blank separated scope list to be used for the access token request.
/// The actual login page will need to override this parameter.
Parameter SCOPE As STRING;

/// The RESPONSEMODE parameter specifies the mode of the response as either query, fragment or form_post.
/// The default is query.
Parameter RESPONSEMODE As STRING;

/// The name of the query parameter used to carry the access token hash.	
Parameter SessionQueryParameter [ Internal ] = "CSPOAUTH2";

ClassMethod OnPreHTTP() As %Boolean [ Internal ]
{
	Set sc=$$$OK
	Kill %OAuth2Error
	
	Try {
		// Log entry to this method
		If $$$SysLogLevel>=3 {
			Do ##class(%OAuth2.Utils).LogCSPRequest("[%OAuth2.Login:OnPreHttp]",0)
		}

		Set tokenSpecified=$data(%request.Data(..#SessionQueryParameter,1))
		If tokenSpecified {
			$$$SysLog(3,"OAuth2","[%OAuth2.Login:OnPreHttp]","CSPOAUTH2 found")
			Set %OAuth2Error="Unable to obtain access token.  Access denied'" 
			Quit
		}
		
		// Redirect back to the page which is being logged in
		Set url=%request.GetCgiEnv("REQUEST_URI")  ; Apache
		If url="" Set url=%request.GetCgiEnv("HTTP_URL")  ; IIS
		Set redirectURL=$select(%request.Secure:"https://",1:"http://")_%request.GetCgiEnv("HTTP_HOST")_url
		$$$SysLog(3,"OAuth2","[%OAuth2.Login:OnPreHttp]","redirectURL="_redirectURL_", session="_%session.SessionId)
		
		// If we are here, then we are not already authorized and need to get access token using redirect.
		// Add the CSPOAUTH2 query parameter to tie ZAUTHENTICATE to this session and its associated access token.
		// After the access token is issued ZAUTHENTICATE will login, we not will return here.
		Set redirectURL=redirectURL_$select(redirectURL["?":"&",1:"?")_..#SessionQueryParameter_"="
		Do ..DefineProperties(.properties)
		Do ..DefineParameters(.application,.scope,.responseMode)
		Set sc=##class(%SYS.OAuth2.Authorization).GetAccessTokenAuthorizationCode(application,scope,redirectURL,.properties,responseMode)
		If $$$ISERR(sc) Quit
		
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%OAuth2.Login:OnPreHttp]",0,sc)
		// Show the error to the user
		Set %OAuth2Error=$system.Status.GetErrorText(sc)
	}

	Quit 1
}

/// Callback to allow the overriding login subclass to define the class parameter values at run-time<br>
/// The default to use the class parameter values.
ClassMethod DefineParameters(Output application As %String, Output scope As %String, Output responseMode As %String)
{
	Set application=..#APPLICATION
	Set scope=..#SCOPE
	Set responseMode=..#RESPONSEMODE
	Quit
}

/// Callback to allow the overriding login subclass to define the properties list for the GetAccessTokenAuthorizationCode call.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.  For example the claims parameter that is defined by OpenID Connect.
/// If the request or request_uri request parameters are to be used, then the %SYS.OAuth2.Request class
/// is used to create  the JWT.  The the JWT is assigned to properties("request") or the URL for the
/// JWT is assigned to properties("request_uri")<br>
ClassMethod DefineProperties(Output properties As %String)
{
	Quit
}

ClassMethod OnPage() As %Status [ Internal ]
{
	&html<
		<html>
	>

	If $data(%OAuth2Error) {
		// If error, then display the error
		&html<
			<head>
			</head>
			<body bgcolor="#CCCCFF">
			<br>
			<font face="Verdana,Arial,Helvetica,sans-serif" color="#FF0000">
		>
		Write "<b>Error processing Authorization Server response.</b><p>",!
		Write "<b>Error Description: ",..EscapeHTML(%OAuth2Error),"</b><p>",!
		&html<
			</font>
			<br>
			</body>
		>
	}

	&html<
		</html>
	>
	Quit $$$OK
}

}
