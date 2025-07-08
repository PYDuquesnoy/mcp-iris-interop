/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %SYS.OAuth2.Authorization class contains the operations which are used to authorize
/// a client by obtaining an access token.<br><br>
/// 
/// The underlying token is stored in OAuth2.AccessToken in the system database.
/// OAuth2.AccessToken is indexed by the combination of SessionId and ApplicationName.
/// Therefore, only one scope may be requested for each SessionId/ApplicationName.
/// If a second request is made with a different scope and access token has yet been granted,
/// the scope in the new request becomes the expected scope.<br>
/// Note that this class is in library databse and thus available everywhere.
/// However, token storage storage is in the system database and thus not difrectly available to most code.
Class %SYS.OAuth2.Authorization Extends %RegisteredObject [ System = 4 ]
{

/// SetEndpoints will update the authorization endpoint and the token endpoint for the
/// specified client application.  If either endpoint is not specified, then it will not be modified.
ClassMethod SetEndpoints(applicationName As %String, authorizationEndpoint As %String, tokenEndpoint As %String) As %Status
{
	Set sc=$$$OK
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:SetEndpoints]","applicationName="_applicationName_$select($data(authorizationEndpoint):", authorizationEndpoint="_authorizationEndpoint,1:"")_$select($data(tokenEndpoint):", tokenEndpoint="_tokenEndpoint,1:""))
		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		
		If $data(authorizationEndpoint) {
			Set client.ServerDefinition.Metadata."authorization_endpoint"=authorizationEndpoint
		}
		If $data(tokenEndpoint) {
			Set client.ServerDefinition.Metadata."token_endpoint"=tokenEndpoint
		}
		
		Set sc=client.%Save()
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Authorization:SetEndpoints]",0,sc)
	Quit sc
}

/// Create a new base64 encoded random nonce value.
ClassMethod CreateNonce() As %String [ Internal ]
{
	Quit ##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(20))
}

/// Create a new base64 encoded random state value.
ClassMethod CreateState() As %String [ Internal ]
{
	Quit ##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(20))
}

/// GetAuthorizationEndpoint returns the URL to be used to redirect authorization requests to the
/// Authorization Server based on the authorization code grant type.  The location part of the URL
/// will be a class in this InterSystems IRIS instance which will further redirect to the authorization server.
/// This URL should be used for a button, anchor or in Javascript code in a page.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.
/// The default for scope is the DefaultScope property of OAuth2.Client for applicationName.<br>
/// The redirectURL argument is the URL of the CSP page which should be invoked after the request
/// for the access token is completed and the access token is stored indexed by the ApplicationName and SessionId.<br>
/// The responseMode argument specifies the mode of the response as either query, fragment or form_post.
/// The default is query.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.  For example the claims parameter that is defined by OpenID Connect.
/// If the request or request_uri request parameters are to be used, then the %SYS.OAuth2.Request class
/// is used to create  the JWT.  The the JWT is assigned to properties("request") or the URL for the
/// JWT is assigned to properties("request_uri")<br>
/// isAuthorized is an output argument which is returned true if an access token has already been 
/// granted for this SessionId/ApplicationName combiation.
ClassMethod GetAuthorizationCodeEndpoint(applicationName As %String, scope As %String, redirectURL As %String, ByRef properties As %String, Output isAuthorized As %Boolean, Output sc As %Status, responseMode As %String, sessionId As %String = "") As %String
{
	Quit ..GetRequestEndpoint(applicationName,.scope,$get(redirectURL),"code",$get(responseMode),.properties,.isAuthorized,.sc,sessionId)
}

/// GetRequestEndpoint returns the URL to be used to redirect authorization requests to the
/// Authorization Server for the authorization code grant type or the implicit grant type.
/// The location part of the URL
/// will be a class in this InterSystems IRIS instance which will further redirect to the authorization server.
/// This URL should be used for a button, anchor or in Javascript code in a page.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.
/// The default for scope is the DefaultScope property of OAuth2.Client for applicationName.<br>
/// The idtokenOnly argument should be specified as true in order to get an IDToken but not an access token.<br>
/// The responseMode argument specifies the mode of the response as either query, fragment or form_post.
/// The redirectURL argument is the URL of the CSP page which should be invoked after the request
/// for the access token is completed and the access token is stored indexed by the ApplicationName and SessionId.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.  For example the claims parameter that is defined by OpenID Connect.
/// If the request or request_uri request parameters are to be used, then the %SYS.OAuth2.Request class
/// is used to create  the JWT.  The the JWT is assigned to properties("request") or the URL for the
/// JWT is assigned to properties("request_uri")<br>
/// isAuthorized is an output argument which is returned true if an access token has already been 
/// granted for this SessionId/ApplicationName combination.
ClassMethod GetRequestEndpoint(applicationName As %String, scope As %String, redirectURL As %String, responseType As %String, responseMode As %String = "", ByRef properties As %String, Output isAuthorized As %Boolean, Output sc As %Status, sessionId As %String) As %String [ Internal ]
{
	Set sc=$$$OK
	Set isAuthorized=0
	Set url=""
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetRequestEndpoint]","applicationName="_applicationName_", scope="_$get(scope)_", redirectURL="_redirectURL_", responseType="_responseType_", responseMode="_responseMode)

		If $get(sessionId)="" {
			Set sessionId=$select($isobject($get(%session)):%session.SessionId,1:"")
			Set defaultSession=1
		} Else {
			Set defaultSession=0
		}
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetRequestEndpoint]","applicationName="_applicationName_", scope="_$get(scope)_", redirectURL="_$get(redirectURL)_", SessionId="_sessionId)
		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		
		If redirectURL="" Set redirectURL=%request.URL
		If $data(scope)=0 Set scope=client.DefaultScope

		// Get random state for request
		Set state=..CreateState()

		// Use Response.cls as theredirect
		Set redirect=##class(OAuth2.Response).GetRedirectURL(client,.sc)
		If $$$ISERR(sc) Quit
		
		// Get existing or new token
		Set accessToken=##class(OAuth2.AccessToken).SAIndexOpen(sessionId,applicationName,4,.sc)
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetRequestEndpoint]","accessToken="_accessToken)
		If '$isobject(accessToken) {
			If $$$ISERR(sc),$$$GETERRORCODE(sc)'=$$$ERRORCODE($$$KeyValueNotFoundOpen) Quit
			// No access token object found, create one
			Set accessToken=##class(OAuth2.AccessToken).%New()
		} ElseIf accessToken.AccessToken'="" {
			// Access token has already been granted.  No need to change.
			Set isAuthorized=1
		}
		
		// Initialize the token
		Set accessToken.ResponseType=responseType
		Set accessToken.ApplicationName=applicationName
		Set accessToken.SessionId=sessionId
		Set accessToken.State=state
		Set accessToken.Stage="new"
		Set accessToken.Scope=scope
		Set accessToken.RedirectURL=redirectURL
		Do accessToken.ClearError()
		
		// Add nonce if OpenID Connect request
		If accessToken.IsOpenID() {
			Set nonce=..CreateNonce()
		} Else {
			Set nonce=""
		}
		Set accessToken.Nonce=nonce
		
		// Check response types
		Set types=client.ServerDefinition.Metadata."response_types_supported"
		If types'="",$listfind(types,responseType)=0 {
			Set sc=$$$ERROR($$$OAuth2RequestArgument,"response_type",responseType)
			Quit
		}

		// Set GrantType and response_mode		
		If responseType="code" {
			Set grantType="authorization_code"
		} ElseIf responseType="token" {
			Set grantType="implicit"
		} ElseIf responseType="id_token token" {
			If 'accessToken.IsOpenID() {
				Set sc=$$$ERROR($$$OAuth2RequestArgument,"response_type",responseType)
				Quit
			}
			Set grantType="implicit"
		} ElseIf responseType="id_token" {
			If 'accessToken.IsOpenID() {
				Set sc=$$$ERROR($$$OAuth2RequestArgument,"response_type",responseType)
				Quit
			}
			Set grantType="implicit"
		} Else {
				Set sc=$$$ERROR($$$OAuth2RequestArgument,"response_type",responseType)
				Quit
		}
		Set types=client.Metadata."grant_types"
		If types'="",$listfind(types,grantType)=0 {
			Set sc=$$$ERROR($$$OAuth2InvalidGrantType,"client",grantType,##class(%OAuth2.Utils).ListToComma(client.Metadata."grant_types"))
			Quit
		}
		Set types=client.ServerDefinition.Metadata."grant_types_supported"
		If types'="",$listfind(types,grantType)=0 {
			Set sc=$$$ERROR($$$OAuth2InvalidGrantType,"authorization server",grantType,##class(%OAuth2.Utils).ListToComma(client.ServerDefinition.Metadata."grant_types_supported"))
			Quit
		}

		If $case(responseMode,"query":0,"fragment":0,"form_post":0,:1) {
			If responseMode="" {
				Set responseMode=$select(grantType="authorization_code":"query",1:"fragment")
			} Else {
				Set sc=$$$ERROR($$$OAuth2RequestArgument,"response_mode",responseMode)
			}
		}
		Set accessToken.GrantType=$select(grantType="authorization_code":"A",1:"I")
		Set accessToken.ResponseMode=responseMode
	
		// Populate PKCE parameters in properties
		If (grantType="authorization_code") {
			If '($Data(properties("code_verifier"))#2) {
				// If no code verifier is present, make one and populate the PKCE parameters
				Set codeVerifier=..MakeCodeVerifier()
				Set codeChallenge=##class(%OAuth2.Utils).Base64UrlEncode($System.Encryption.SHAHash(256,codeVerifier))
				Set properties("code_challenge")=codeChallenge
				Set properties("code_challenge_method")="S256"
				Set accessToken.CodeVerifier=codeVerifier
			} ElseIf (properties("code_verifier")="") {
				// If the code verifier is blank, don't use PKCE
				Kill properties("code_verifier"),properties("code_challenge"),properties("code_challenge_method")
				set accessToken.CodeVerifier=""
			} Else {
				// If there is a code verifier present, populate the PKCE parameters based on it
				// and (when present) the supplied code challenge method
				Set codeVerifier=properties("code_verifier")
				Kill properties("code_verifier")
				If $Data(properties("code_challenge_method"))#2 {
					If (properties("code_challenge_method")="plain") {
						set properties("code_challenge")=codeVerifier
						set accessToken.CodeVerifier=codeVerifier
					} ElseIf (properties("code_challenge_method")="S256") {
						Set codeChallenge=##class(%OAuth2.Utils).Base64UrlEncode($System.Encryption.SHAHash(256,codeVerifier)) 
						Set properties("code_challenge")=codeChallenge
						Set accessToken.CodeVerifier=codeVerifier
					} Else {
						Set sc=$$$ERROR($$$PKCEInvalidChallengeMethod,properties("code_challenge_method"))
						Quit
					}
				} Else {
					Set codeChallenge=##class(%OAuth2.Utils).Base64UrlEncode($System.Encryption.SHAHash(256,codeVerifier)) 
					Set properties("code_challenge")=codeChallenge
					Set properties("code_challenge_method")="S256"
					Set accessToken.CodeVerifier=codeVerifier
				}
			}
		}

		// Create the request URL
		Set url=..MakeAuthorizationCodeURL(client, accessToken, redirect,.properties,.sc)
		If $$$ISERR(sc) Quit
		
		// Save the token
		Set sc=accessToken.%Save()
		
		// Set the SessionEvents class to clean up access token. Skip this if we are coming from the 
		// %OAuth2.Login page - this is a temporary session, and we don't want to delete the token when it ends.
		Set queryParam = $parameter("%OAuth2.Login", "SessionQueryParameter")
		If $$$ISOK(sc), defaultSession, sessionId'="", $extract(redirectURL,*-$length(queryParam),*)'=(queryParam_"=") {
			Set sc=%session.EventClassAdd("OAuth2.SessionEvents","%SYS")
		}		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetRequestEndpoint]","url="_url_", state="_$get(state)_", isAuthorized="_isAuthorized_", SessionId="_$get(sessionId))
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Authorization:GetRequestEndpoint]",0,sc)
	
	Quit url
}

/// Construct a code verifier to use for PKCE.
ClassMethod MakeCodeVerifier() As %String [ CodeMode = expression, Internal, Private ]
{
##class(%OAuth2.Utils).Base64UrlEncode($System.Encryption.GenCryptRand(32))
}

/// Make the URL for authorization code request
ClassMethod MakeAuthorizationCodeURL(client As OAuth2.Client, token As OAuth2.AccessToken, redirect As %String, ByRef properties As %String, Output sc As %Status) As %String [ Internal ]
{
	Set sc=$$$OK
	Set url=client.ServerDefinition.Metadata."authorization_endpoint"
	Set url=url_$select(url["?":"&",1:"?")_"response_type="_##class(%CSP.Page).EscapeURL(token.ResponseType,"UTF8")_
		"&client_id="_##class(%CSP.Page).EscapeURL(client.ClientId,"UTF8")_
		"&redirect_uri="_##class(%CSP.Page).EscapeURL(redirect,"UTF8")_
		"&scope="_##class(%CSP.Page).EscapeURL(token.Scope,"UTF8")_
		"&state="_##class(%CSP.Page).EscapeURL(token.State,"UTF8")
	If token.Nonce'="" {
		Set url=url_"&nonce="_##class(%CSP.Page).EscapeURL(token.Nonce,"UTF8")
	}
	If token.ResponseMode'=$select(token.GrantType="I":"fragment",1:"query") {
		set url=url_"&response_mode="_##class(%CSP.Page).EscapeURL(token.ResponseMode,"UTF8")
	}
	
	// Add user supplied properties
	Set name=""
	For {
		Set name=$order(properties(name),1,value)
		If name="" Quit
		
		// If aud is "" use client_id as default
		If name="aud",value="" Set value=client.ClientId
		// If object, then convert to JSON
		If $isobject(value) Set value=value.%ToJSON()
		// URL escape the property value.
		Set url=url_"&"_name_"="_##class(%CSP.Page).EscapeURL(value,"UTF8")
	}
	
	Set token.LoginRedirectURL = url
	Return redirect_"?auth=1&state="_##class(%CSP.Page).EscapeURL(token.State,"UTF8")
}

/// GetAccessTokenAuthorizationCode may be called from the OnPreHttp method of a CSP page to redirect
/// authorization requests to the Authorization Server based on the authorization code grant type.<br>
/// GetAccessTokenAuthorizationCode will only request a new access token if their is no existing
/// access toekn which includes all the scopes that are being requested.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.
/// The default for scope is the DefaultScope property of OAuth2.Client for applicationName.<br>
/// The redirectURL argument is the URL of the CSP page which should be invoked after the request
/// for the access token is completed and the access token is stored indexed by the ApplicationName and SessionId.
/// The responseMode argument specifies the mode of the response as either query, fragment or form_post.
/// The default is query.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.  For example the claims parameter that is defined by OpenID Connect.
/// If the request or request_uri request parameters are to be used, then the %SYS.OAuth2.Request class
/// is used to create  the JWT.  The the JWT is assigned to properties("request") or the URL for the
/// JWT is assigned to properties("request_uri")<br>
ClassMethod GetAccessTokenAuthorizationCode(applicationName As %String, scope As %String, redirectURL As %String, ByRef properties As %String, responseMode As %String, sessionId As %String = "") As %Status
{
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenAuthorizationCode]","applicationName="_applicationName_", scope="_$get(scope)_", redirectURL="_$get(redirectURL))

		If '##class(%SYS.OAuth2.AccessToken).IsAuthorized(applicationName,.sessionId,.scope,,.error) {
			// Only get a new token if current one is not authorized
			Set url=..GetAuthorizationCodeEndpoint(applicationName,.scope,.redirectURL,.properties,.isAuthorized,.sc,.responseMode,sessionId)
			$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenAuthorizationCode]","url="_url_", isAuthorized="_$get(isAuthorized))
			If $$$ISOK(sc) {
				Set %response.Redirect=url
			}
		} Else {
			$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenAuthorizationCode]","Keep access token."_$select($isobject(error):" error: "_error.AsString(),1:""))
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Authorization:GetAccessTokenPassword]",0,sc)
	Quit sc
}

/// GetImplicitEndpoint returns the URL to be used to redirect authorization requests to the
/// Authorization Server based on the implicit grant type.  The location part of the URL
/// will be a class in this InterSystems IRIS instance which will further redirect to the authorization server.
/// This URL should be used for a button, anchor or in Javascript code in a page.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.
/// The default for scope is the DefaultScope property of OAuth2.Client for applicationName.<br>
/// The idtokenOnly argument should be specified as true in order to get an IDToken but not an access token.<br>
/// The responseMode argument specifies the mode of the response as either query, fragment or form_post.
/// The default is fragment.<br>
/// The redirectURL argument is the URL of the CSP page which should be invoked after the request
/// for the access token is completed and the access token is stored indexed by the ApplicationName and SessionId.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.  For example the claims parameter that is defined by OpenID Connect.
/// If the request or request_uri request parameters are to be used, then the %SYS.OAuth2.Request class
/// is used to create  the JWT.  The the JWT is assigned to properties("request") or the URL for the
/// JWT is assigned to properties("request_uri")<br>
/// isAuthorized is an output argument which is returned true if an access token has already been 
/// granted for this SessionId/ApplicationName combination.
ClassMethod GetImplicitEndpoint(applicationName As %String, scope As %String, redirectURL As %String, idtokenOnly As %Boolean = 0, responseMode As %String, ByRef properties As %String, Output isAuthorized As %Boolean, Output sc As %Status, sessionId As %String = "") As %String
{
	If (" "_$get(scope)_" ")[" openid " {
		If idtokenOnly {
			Set responseType="id_token"
		} Else {
			Set responseType="id_token token"
		}
	} Else {
		Set responseType="token"
	}
	
	Quit ..GetRequestEndpoint(applicationName,.scope,$get(redirectURL),responseType,$get(responseMode),.properties,.isAuthorized,.sc,sessionId)
}

/// GetAccessTokenImplicit may be called from the OnPreHttp method of a CSP page to redirect
/// authorization requests to the Authorization Server based on the implicit grant type.<br>
/// GetAccessTokenAuthorizationCode will only request a new access token if their is no existing
/// access token which includes all the scopes that are being requested.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.
/// The default for scope is the DefaultScope property of OAuth2.Client for applicationName.<br>
/// The idtokenOnly argument should be specified as true in order to get an IDToken but not an access token.<br>
/// The responseMode argument specifies the mode of the response as either query, fragment or form_post.
/// The default is fragment.<br>
/// The redirectURL argument is the URL of the CSP page which should be invoked after the request
/// for the access token is completed and the access token is stored indexed by the ApplicationName and SessionId.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.  For example the claims parameter that is defined by OpenID Connect.
/// If the request or request_uri request parameters are to be used, then the %SYS.OAuth2.Request class
/// is used to create  the JWT.  The the JWT is assigned to properties("request") or the URL for the
/// JWT is assigned to properties("request_uri")<br>
ClassMethod GetAccessTokenImplicit(applicationName As %String, scope As %String, redirectURL As %String, idtokenOnly As %Boolean, responseMode As %String, ByRef properties As %String, sessionId As %String = "") As %Status
{
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenImplicit]","applicationName="_applicationName_", scope="_$get(scope)_", redirectURL="_$get(redirectURL))
		
		If '##class(%SYS.OAuth2.AccessToken).IsAuthorized(applicationName,.sessionId,.scope,,.error) {
			// Only get a new token if current one is not authorized
			Set url=..GetImplicitEndpoint(applicationName,.scope,.redirectURL,.idtokenOnly,.responseMode,.properties,.isAuthorized,.sc,sessionId)
			$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenImplicit]","url="_url_", isAuthorized="_$get(isAuthorized))
			If $$$ISOK(sc) {
				Set %response.Redirect=url
			}
		} Else {
			$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenImplicit]","Keep access token."_$select($isobject(error):" error: "_error.AsString(),1:""))
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Authorization:GetAccessTokenImplicit]",0,sc)
	Quit sc
}

/// GetAccessTokenPassword may be called from any method to send authorization requests to the
/// Authorization Server based on the resource owner password credentials grant type.
/// The access token will be stored indexed by the ApplicationName and SessionId before this method returns.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.
ClassMethod GetAccessTokenPassword(applicationName As %String, username As %String, password As %String, scope As %String, ByRef properties As %String, Output error As %OAuth2.Error, sessionId As %String = "") As %Status
{
	Set sc=$$$OK
	Set error=""
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenPassword]","applicationName="_applicationName_", username="_username_", scope="_scope)
		Set httpRequest=##class(%Net.HttpRequest).%New()
		Set httpRequest.ContentType="application/x-www-form-urlencoded"_$select($$$IsUnicode:"", 1:"; charset=utf-8")
		Set sc=##class(%SYS.OAuth2.AccessToken).AddAuthentication(applicationName,httpRequest)
		If $$$ISERR(sc) Quit
		
		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		If $data(scope)=0 Set scope=client.DefaultScope
		
		Do httpRequest.InsertFormData("grant_type","password")
		Do httpRequest.InsertFormData("username",username)
		Do httpRequest.InsertFormData("password",password)
		Do httpRequest.InsertFormData("scope",scope)
		Set name=""
		For {
			Set name=$order(properties(name),1,value)
			If name="" Quit
			If name="aud",value="" Set value=client.ClientId
			If $isobject(value) Set value=value.%ToJSON()
			Do httpRequest.InsertFormData(name,value)
		}
		
		If $$$SysLogLevel>=3 {
			Set formData("grant_type")="password"
			Set formData("username")=username
			Set formData("password")=""
			Set formData("scope")=scope
			Set name=""
			For {
				Set name=$order(properties(name),1,value)
				If name="" Quit
				If name="aud",value="" Set value=client.ClientId
				If $isobject(value) Set value=value.%ToJSON()
				Set formData(name)=value
			}
			Do ##class(%OAuth2.Utils).LogHTTPRequest("[%SYS.OAuth2.Authorization:GetAccessTokenPassword]",0,
				httpRequest,"POST",client.ServerDefinition.Metadata."token_endpoint",.formData)
		}

		Set sc=httpRequest.Post(client.ServerDefinition.Metadata."token_endpoint")
		
		If $$$ISOK(sc) {
			Set sc=##class(OAuth2.Response).ProcessResponse(httpRequest,applicationName,scope,sessionId,,"P",.error)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Authorization:GetAccessTokenPassword]",0,sc)
	Quit sc
}

/// GetAccessTokenClient may be called from any method to send authorization requests to the
/// Authorization Server based on the resource owner client credentials grant type.
/// The access token will be stored indexed by the ApplicationName and SessionId before this method returns.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.
ClassMethod GetAccessTokenClient(applicationName As %String, scope As %String, ByRef properties As %String, Output error As %OAuth2.Error, sessionId As %String = "") As %Status
{
	Set sc=$$$OK
	Set error=""
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenClient]","applicationName="_applicationName_", scope="_scope)
		Set httpRequest=##class(%Net.HttpRequest).%New()
		Set httpRequest.ContentType="application/x-www-form-urlencoded"_$select($$$IsUnicode:"", 1:"; charset=utf-8")
		Set sc=##class(%SYS.OAuth2.AccessToken).AddAuthentication(applicationName,httpRequest)
		If $$$ISERR(sc) Quit
		
		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		If $data(scope)=0 Set scope=client.DefaultScope
		
		Do httpRequest.InsertFormData("grant_type","client_credentials")
		Do httpRequest.InsertFormData("scope",scope)
		Set name=""
		For {
			Set name=$order(properties(name),1,value)
			If name="" Quit
			If name="aud",value="" Set value=client.ClientId
			If $isobject(value) Set value=value.%ToJSON()
			Do httpRequest.InsertFormData(name,value)
		}
		
		If $$$SysLogLevel>=3 {
			Set formData("grant_type")="client_credentials"
			Set formData("scope")=scope
			Set name=""
			For {
				Set name=$order(properties(name),1,value)
				If name="" Quit
				If name="aud",value="" Set value=client.ClientId
				If $isobject(value) Set value=value.%ToJSON()
				Set formData(name)=value
			}
			Do ##class(%OAuth2.Utils).LogHTTPRequest("[%SYS.OAuth2.Authorization:GetAccessTokenClient]",0,
				httpRequest,"POST",client.ServerDefinition.Metadata."token_endpoint",.formData)
		}

		Set sc=httpRequest.Post(client.ServerDefinition.Metadata."token_endpoint")
		
		If $$$ISOK(sc) {
			Set sc=##class(OAuth2.Response).ProcessResponse(httpRequest,applicationName,scope,sessionId,,"C",.error)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Authorization:GetAccessTokenClient]",0,sc)
	Quit sc
}

/// GetAccessTokenJWT may be called from any method to send authorization requests to the
/// Authorization Server based on the resource owner JWT grant type specified in RFC 7523.
/// The access token will be stored indexed by the applicationName and sessionId before this method returns.<br>
/// The scope argument is a blank separated list of scopes for which access is requested.<br>
/// properties is a local array specifying additional properties to be included in a token request
/// in the form properties(name)=value.  To add a request parameter which is a JSON object,
/// you may either create a properties element which is a %DynamicObject or is a string that is the
/// UTF-8 encoded serialized object.<br>
/// sub is the subject of the JWT which usually a user which is defined on the authorization server.
/// The signing algorithm to be used to sign the JWT is specified by OAuth2.Client.Metadata."token_endpoint_auth_signing_alg",
/// the same signing algorithm as used for client authentication JWT.
ClassMethod GetAccessTokenJWT(applicationName As %String, sub As %String, scope As %String, ByRef properties As %String, Output error As %OAuth2.Error, sessionId As %String = "") As %Status
{
	Set sc=$$$OK
	Set error=""
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenJWT]","applicationName="_applicationName_", scope="_scope_", sub="_sub)
		Set httpRequest=##class(%Net.HttpRequest).%New()
		Set httpRequest.ContentType="application/x-www-form-urlencoded"_$select($$$IsUnicode:"", 1:"; charset=utf-8")
		Set sc=##class(%SYS.OAuth2.AccessToken).AddAuthentication(applicationName,httpRequest)
		If $$$ISERR(sc) Quit
		
		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		If $data(scope)=0 Set scope=client.DefaultScope
		
		// Create the JWT
		Set sc=..MakeGrantTypeJWT(client,sub,,.jwt)
		If $$$ISERR(sc) Quit
		
		Do httpRequest.InsertFormData("grant_type","urn:ietf:params:oauth:grant-type:jwt-bearer")
		Do httpRequest.InsertFormData("assertion",jwt)
		Do httpRequest.InsertFormData("scope",scope)
		Set name=""
		For {
			Set name=$order(properties(name),1,value)
			If name="" Quit
			If name="aud",value="" Set value=client.ClientId
			If $isobject(value) Set value=value.%ToJSON()
			Do httpRequest.InsertFormData(name,value)
		}
		
		If $$$SysLogLevel>=3 {
			Set formData("grant_type")="urn:ietf:params:oauth:grant-type:jwt-bearer"
			Set formData("assertion")=jwt
			Set formData("scope")=scope
			Set name=""
			For {
				Set name=$order(properties(name),1,value)
				If name="" Quit
				If name="aud",value="" Set value=client.ClientId
				If $isobject(value) Set value=value.%ToJSON()
				Set formData(name)=value
			}
			Do ##class(%OAuth2.Utils).LogHTTPRequest("[%SYS.OAuth2.Authorization:GetAccessTokenJWT]",0,
				httpRequest,"POST",client.ServerDefinition.Metadata."token_endpoint",.formData)
		}

		Set sc=httpRequest.Post(client.ServerDefinition.Metadata."token_endpoint")
		
		If $$$ISOK(sc) {
			Set sc=##class(OAuth2.Response).ProcessResponse(httpRequest,applicationName,scope,sessionId,,"J",.error)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Authorization:GetAccessTokenJWT]",0,sc)
	Quit sc
}

/// Create a JWT for the JWT grant type that is specified by RFC7523.
/// sub is the subject of the JWT which usually a user which is defined on the authorization server.
/// sigalg is the signing algorithm to be used to sign the JWT -- default is RS256.
ClassMethod MakeGrantTypeJWT(client As OAuth2.Client, sub As %String, sigalg As %String, Output jwt As %String) As %Status [ Internal ]
{
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.AccessToken:MakeGrantTypeJWT]","client_id="_client.ClientId)
		Set jwt=""
		// Get request object.
		Set requestObject=##class(%DynamicObject).%New()
		
		Do requestObject.%Set("iss",client.ClientId,"string")
		Do requestObject.%Set("sub",sub,"string")
		Do requestObject.%Set("aud",client.JWTAudience,"string")
		Do requestObject.%Set("jti",client.ClientId_"."_##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(20)),"string")
		Do requestObject.%Set("exp",##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,client.JWTInterval),"number")
		Set now=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,0)
		Do requestObject.%Set("iat",now,"number")
		
		Set sigalg=client.Metadata."token_endpoint_auth_signing_alg"
		If (sigalg="none") || (sigalg="") {
			$$$ThrowStatus($$$ERROR($$$OAuth2NoAuthSigning))
		}

		// Setup JWT signing parameters.
		Set sigJOSE = {"alg":(sigalg)}
		$$$SysLog(3,"OAuth2Server","[%SYS.OAuth2.AccessToken:MakeGrantTypeJWT]","Signing alg="_sigJOSE.%ToJSON())
	
		// Create JWT
		If ##class(%Net.JSON.JWA).IsAlgAsymmetric(sigalg) {
			Set sigJWKS = client.PrivateJWKS
		} Else {
			Set sigJWKS = client.SymmetricJWKS
		}
		Set sc = ##class(%Net.JSON.JWT).Create(sigJOSE,, requestObject, sigJWKS,, .jwt)
		$$$SysLog(3,"OAuth2Server","[%SYS.OAuth2.AccessToken:MakeGrantTypeJWT]","JWT="_$get(jwt))
	
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.AccessToken:MakeGrantTypeJWT]",0,sc)
	} Else {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.AccessToken:MakeGrantTypeJWT]",requestObject.%ToJSON())
	}
	
	Quit sc
}

/// GetAccessTokenRefresh sends a request to the
/// Authorization Server in order to get a new access token based on the refresh token.
/// The access token will be stored indexed by the ApplicationName and SessionId before this method returns.<br>
ClassMethod GetAccessTokenRefresh(accessToken As OAuth2.AccessToken, Output refreshed As %Boolean, Output error As %OAuth2.Error) As %Status [ Final, Internal ]
{
	Set sc=$$$OK
	Set error=""
	Set refreshed=0
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetAccessTokenRefresh]","applicationName="_accessToken.ApplicationName_", sessionId="_accessToken.SessionId_", hasRefreshToken="_(accessToken.RefreshToken'=""))
		// If no refresh token, then nothing to do
		If accessToken.RefreshToken="" Quit
				
		// Find the access token object
		// Get http request object and add authentication per RFC 6750
		Set httpRequest=##class(%Net.HttpRequest).%New()
		Set httpRequest.ContentType="application/x-www-form-urlencoded"_$select($$$IsUnicode:"", 1:"; charset=utf-8")
		Set sc=##class(%SYS.OAuth2.AccessToken).AddAuthentication(accessToken.ApplicationName,httpRequest)
		If $$$ISERR(sc) Quit
		
		Set client=##class(OAuth2.Client).Open(accessToken.ApplicationName,.sc)
		If client="" Quit
		
		Do httpRequest.InsertFormData("grant_type","refresh_token")
		Do httpRequest.InsertFormData("refresh_token",accessToken.RefreshToken)
		
		If $$$SysLogLevel>=3 {
			Set formData("grant_type")="refresh_token"
			Set formData("refresh_token")=accessToken.RefreshToken
			Do ##class(%OAuth2.Utils).LogHTTPRequest("[%SYS.OAuth2.Authorization:GetAccessTokenRefresh]",0,
				httpRequest,"POST",client.ServerDefinition.Metadata."token_endpoint",.formData)
		}

		Set sc=httpRequest.Post(client.ServerDefinition.Metadata."token_endpoint")
		
		If $$$ISOK(sc) {
			Set sc=##class(OAuth2.Response).ProcessResponse(httpRequest,accessToken.ApplicationName,accessToken.Scope,accessToken.SessionId,,,.error)
		}
		
		If $$$ISOK(sc) Set refreshed=1
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.AccessToken:GetAccessTokenRefresh]",0,sc)
	Quit sc
}

/// GetLogoutEndpoint returns the URL to be used to redirect logout requests to the
/// Authorization Server according to OpenID Connect RP-Initiated Logout.
/// This URL should be used for a button, anchor or in Javascript code in a page.<br>
/// The applicationName prarameter specifies the name of the application for which the current session is to be logged out.<br>
/// The redirectURL parameter specifies the URL of the CSP page to which the User Agent should be redirected after the logout request
/// is completed on the server.<br>
/// The sessionId parameter specifies the session id of the current Access Token. By default it will use the CSP session id,
/// if present.
ClassMethod GetLogoutEndpoint(applicationName As %String, redirectURL As %String = "", sessionId As %String = "") As %String
{
	Set url=""
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"

	// Open the client
	Set client = ##class(OAuth2.Client).Open(applicationName,.sc)
	If $$$ISERR(sc) || '$isobject(client) {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetLogoutEndpoint]","Client not found with name '"_applicationName_"' sc="_$System.Status.GetErrorText(sc))
		Return url
	}
	
	If client.ServerDefinition.Metadata."end_session_endpoint"="" {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetLogoutEndpoint]","Server for client '"_applicationName_"' does not support front-channel logout.")
		Return url
	}

	// Get the client's access token for the current session
	Do ##class(%OAuth2.Utils).GetDefaultSessionId(.sessionId)
	Set accessToken=##class(OAuth2.AccessToken).OpenForSession(applicationName,sessionId,.sc)
	If $$$ISERR(sc) || '$isobject(accessToken) {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetLogoutEndpoint]","Error opening access token for client '"_applicationName_"' and session '"_sessionId_"' sc="_$System.Status.GetErrorText(sc))
		Return url
	}

	// If there's no ID token for the current session, then there is no OpenID Connect session to logout
	If accessToken.IDToken="" {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetLogoutEndpoint]","No ID token for client "_applicationName_" and session "_sessionId)
		Return url
	}

	If redirectURL="" Set redirectURL=%request.URL

	If (accessToken.LogoutState="") || (accessToken.LogoutRedirectURL'=redirectURL) {
		Set accessToken.LogoutState = ..CreateState()
		Set accessToken.LogoutRedirectURL = redirectURL
		Set sc = accessToken.%Save()
		If $$$ISERR(sc) {
			$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Authorization:GetLogoutEndpoint]","Error saving logout redirect URL for client "_applicationName_" and session "_sessionId)
			Return url
		}
	}

	Return (
		$select(client.RedirectionEndpoint.Prefix'="":"/"_client.RedirectionEndpoint.Prefix, 1:"") _ 
		##class(OAuth2.Server.Configuration).GetCSPApplication(0) _ 
		"/OAuth2.PostLogoutRedirect.cls?register=" _ 
		accessToken.LogoutState
	)
}

}
