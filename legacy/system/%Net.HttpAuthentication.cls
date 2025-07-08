/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements various utility methods for HTTP authentication. <br>
/// It supports both proxy server authentication and target server authentication. <br>
Class %Net.HttpAuthentication Extends %RegisteredObject
{

/// Username that is used for Basic authentication.
Property Username As %Username;

/// Password that is used for Basic authentication.
Property Password As %String;

/// The list of supported authentication schemes
Property Schemes As %String [ InitialExpression = "Negotiate,NTLM,Basic" ];

/// The authentication scheme that was used to do the most recent authentication.
Property CurrentScheme As %String;

/// The list of authentication related errors.
Property Errors As %List;

/// The maximum of authentication round-trips
Property MaxDepth As %Integer [ InitialExpression = 6 ];

/// Used to count roundtrips needed for NTLM or SPNEGO authentication to prevent getting into a loop.
Property Depth As %Integer [ Internal, Private ];

/// The context handle used for NTLM or SPNEGO authentication.
Property Handle As %Integer [ Internal, Private ];

/// The server to authenticate with
Property Server As %String [ Calculated ];

Property InitiateAuthentication As %String [ InitialExpression = "Basic" ];

Method ServerGet() As %String [ CodeMode = expression, Internal ]
{
$select(..IsProxy:..HttpRequest.Server,1:..HttpRequest.ProxyServer)
}

/// The relevant authorization header of the associated HttpRequest.
/// Authorization - Target server
/// Proxy-Authorization - Proxy server
Property Authorization As %String [ Calculated ];

Method AuthorizationGet() As %String [ CodeMode = expression, Internal ]
{
$select(..IsProxy:..HttpRequest.ProxyAuthorization,1:..HttpRequest.Authorization)
}

Method AuthorizationSet(authorization As %String) As %Status [ Internal ]
{
    If ..IsProxy {
        Set ..HttpRequest.ProxyAuthorization = authorization
    } Else {
        Set ..HttpRequest.Authorization = authorization
    }
    Return $$$OK
}

/// The %Net.HttpRequest instance that is associated with this authentication.
Property HttpRequest As %Net.HttpRequest;

/// The HttpResponse in response to the associated HttpRequest
Property HttpResponse As %Net.HttpResponse [ Calculated, Internal ];

Method HttpResponseGet() As %Net.HttpResponse [ CodeMode = expression, Internal ]
{
..HttpRequest.HttpResponse
}

Method HttpResponseSet(httpResponse As %Net.HttpResponse) As %Status [ Internal ]
{
    Set ..HttpRequest.HttpResponse = httpResponse
    Return $$$OK
}

/// Whether it is authenticating with an HTTP target server or proxy server.
/// 0 - Target server
/// 1 - Proxy server
Property IsProxy As %Boolean [ InitialExpression = 0 ];

/// HTTP response header that is expected to receive on authentication requested by server
Property ResponseHeader As %String [ Calculated, Internal, Private ];

Method ResponseHeaderGet() As %String [ CodeMode = expression, Internal ]
{
$select(..IsProxy:"Proxy-Authenticate",1:"WWW-Authenticate")
}

/// HTTP status code that is expected to receive on authentication requested by server
Property StatusCode As %String [ Calculated, Internal, Private ];

Method StatusCodeGet() As %String [ CodeMode = expression, Internal ]
{
$select(..IsProxy:407,1:401)
}

/// HTTP request header that is used for authentication
Property RequestHeader As %String [ Calculated, Internal, Private ];

Method RequestHeaderGet() As %String [ CodeMode = expression, Internal ]
{
$select(..IsProxy:"Proxy-Authorization",1:"Authorization")
}

/// Initialization requires two arguments:
/// the HttpRequest object it is associated with, and
/// whether it is intended for proxy authorization (true or false).
Method %OnNew(httpRequest As %Net.HttpRequest, isProxy As %Boolean) As %Status [ Internal ]
{
    Set ..HttpRequest = httpRequest, ..IsProxy = isProxy
    Return $$$OK
}

/// Create the initial Authorization header if requested and not manually created.
/// If InitiateAuthentication="basic" (the default), then skip initiating authentication unless Username specified.
Method CreateInitialHeader() As %Status
{
	If ..Handle="",..Authorization="",..InitiateAuthentication'="",
			(..InitiateAuthentication'="Basic") || (..Username'="") {
		#; Support client initiated authentication
		Set token = ..GetToken(..InitiateAuthentication, "")
		If token'="" {
			Set ..Authorization = ..InitiateAuthentication _ " " _ token
		} Else {
			Set sc = $$$ERROR($$$HttpAuthHeader, ..InitiateAuthentication)
			$$$SysLogVar(2,"HttpAuthentication","[%Net.HttpAuthentication:CreateInitialHeader]","Error 1.1: "_$system.Status.GetErrorText(sc))
			Return sc
		}
	}
	
	Return $$$OK
}

/// Extract the schemes from the WWW-Authenticate headers and get an
/// Authuthentication token for the first scheme on our list that is configured.
Method ProcessHeader(authenticateHeader As %String, Output scheme As %String) As %String [ Internal ]
{
	$$$SysLogVar(2,"HttpAuthentication","[%Net.HttpAuthentication:ProcessHeader]","")
	$$$SysLogVar(5,"HttpAuthentication","[%Net.HttpAuthentication:ProcessHeader]",authenticateHeader)
	Set scheme = ""
	Set token = ""
	#; Loop over the comma separated list of header values,
	#; since we could have multiple WWW-Authenticate / Proxy-Authenticate headers
	For i=1:1:$length(authenticateHeader,",") {
		Set header = $piece(authenticateHeader,",",i)
		Set headerScheme = $piece(header," ",1)
		#; Save schemes.
		#; Since Digest, Bearer and others have multiple comma separated keywords of form keyword=val,
		#; we ignore any thing that looks like this.
		If headerScheme'="",headerScheme'["=" {
			Try {
				Set challenge(headerScheme) = $system.Encryption.Base64Decode($zstrip($piece(header, " ", 2, *), "<>W"))
			} Catch {
				#; We can ignore the challenge since a keyword=value like in Basic realm=.
				Set challenge(headerScheme) = ""
			}
		}
	}
	If $get(%SYSLOG)>=2 {
		Set headers = ""
		Set s = ""
		For {
			Set s = $order(challenge(s))
			Quit:s=""
			Set headers = headers_$select(headers="":"",1:",")_s_$select(challenge(s)'="":"*",1:"")
		}
		$$$SysLogVar(2,"HttpAuthentication","[%Net.HttpAuthentication:ProcessHeader]","headers="_headers)
	}
	Set authSchemes = $select(i%CurrentScheme'="":i%CurrentScheme, 1:i%Schemes)
	For i=1:1:$length(authSchemes,",") {
		Set authScheme = $piece(authSchemes,",",i)
		If authScheme'="",$data(challenge(authScheme)) {
			If challenge(authScheme)="",i%CurrentScheme'="" {
				#; No challenge value for 401 status after first is a
				#; permanaent error -- probably bad username or password.
				Set scheme = authScheme
				Quit
			}

			Set token=..GetToken(authScheme, challenge(authScheme))
			If token'="" {
				Set scheme = authScheme
				Quit
			}
		}
	}

	$$$SysLogVar(2,"HttpAuthentication","[%Net.HttpAuthentication:ProcessHeader]","hasToken="_$select(token'="":"true",1:"false")_", scheme="_scheme)
	$$$SysLogVar(5,"HttpAuthentication","[%Net.HttpAuthentication:ProcessHeader]","token="_token)
	Quit token
}

/// Get the authentication token based on the specified authentication scheme.
Method GetToken(scheme As %String, challenge As %String) As %String [ Internal ]
{
	$$$SysLogVar(2,"HttpAuthentication","[%Net.HttpAuthentication:GetToken]","scheme="_scheme_", Server="_..Server_", Username="_..Username_", hasAuthenticateHandle="_$select(..Handle'="":"true",1:"false")_", CurrentScheme="_..CurrentScheme_", hasChallenge="_$select(challenge'="":"true",1:"false")_", Server="_..Server_", Username="_..Username_", hasAuthenticateHandle="_$select(..Handle'="":"true",1:"false")_", CurrentScheme="_..CurrentScheme)
	$$$SysLogVar(5,"HttpAuthentication","[%Net.HttpAuthentication:GetToken]","AuthenticateHandle="_..Handle_", Challenge="_$system.Encryption.Base64Encode(challenge)_", AuthenticateHandle="_..Handle)
	#; Create the authorization token
	If scheme="Basic" {
		#; For Basic authentication, the token is username:password
		If i%Username'="" {
			Set token = $zconvert(i%Username_":"_i%Password,"O","UTF8")
		} Else {
			Set token = ""
		}
		Set i%CurrentScheme = "Basic"
	} Else {
		#; If not Basic, then get token from GSSAPI.
		#; First get an authentication handle if we do not have it yet
		Set token = ""
		If i%Handle="" {
			#; Get authentication handle.
			Set i%Handle = $zu(203, 0, scheme, "HTTP/"_..Server, ..Username, ..Password)
		}

		#; Go get the token based on our handle
		If i%Handle'="" Set token = $zu(203, 1, i%Handle, challenge)
		If token'="" {
			#; Save the scheme
			Set i%CurrentScheme = scheme
		} Else {
			#; If failure clean up existing handle
			Set error = $zu(203, 3, i%Handle)
			Set errorType = $select(i%Handle="":"init", 1:"token")
			Set i%Errors = i%Errors _ $lb(scheme_" "_errorType_" ERROR: "_error)
			$$$SysLogVar(2,"HttpAuthentication","[%Net.HttpAuthentication:GetToken]","scheme="_scheme_", "_errorType_" error="_error)

			Do ..Close()
		}
	}

	$$$SysLogVar(2,"HttpAuthentication","[%Net.HttpAuthentication:GetToken]","scheme="_scheme_", hasToken="_$select(token'="":"true",1:"false")_", hasAuthenticateHandle="_$select(..Handle'="":"true",1:"false")_", hasHandle="_$select(i%Handle'="":"true",1:"false"))
	Set token = $system.Encryption.Base64Encode(token,1)
	$$$SysLogVar(5,"HttpAuthentication","[%Net.HttpAuthentication:GetToken]","token="_token_", AuthenticateHandle="_..Handle_", Handle="_i%Handle)
	Quit token
}

/// Return true if there is an authentication handle;
/// return false otherwise
Method HasHandle() As %Boolean [ CodeMode = expression ]
{
..Handle'=""
}

/// Clean up the authentication object
Method Close() [ Internal ]
{
	Return:i%Handle=""

    Do $zu(203, 2, i%Handle)
    Set i%Handle = ""
    Set i%CurrentScheme = ""
    Set i%Depth = 0
}

/// Check if an Authorization header needs to be created in repsonse to an HTTP response header.
/// WWW-Authenticate is for target server authorization, and
/// Proxy-Authenticate is for proxy server authorization.
Method ProcessHttpResponse(Output httpResponse As %Net.HttpResponse, type As %String, location As %String, test As %Integer = 0) As %Status
{
    Return:(..HttpRequest="")||(..HttpRequest.HttpResponse="") $$$ERROR($$$InvalidArgument, "HttpRequest or HttpResponse does not exist.")

    /// Skip if no relevant header is found
    Set authenticateHeader = ..HttpResponse.GetHeader(..ResponseHeader)
    Return:authenticateHeader="" $$$OK

    Set sc = $$$OK
    If ..HttpResponse.StatusCode=..StatusCode,i%Depth<i%MaxDepth,(i%CurrentScheme'="Basic") {
        Set token = ..ProcessHeader(authenticateHeader, .scheme)
        If token'="" {
            #; If authentication token successfully created for the scheme, then try again
            Do ..HttpRequest.RemoveHeader(..RequestHeader)
            Set ..Authorization = scheme _ " " _ token
            Set i%Depth = i%Depth + 1
            Set sc = ..HttpRequest.Send(type, location, test, 0)
            Set i%Depth = i%Depth - 1
            Set httpResponse = ..HttpResponse
        } Else {
            #; Handle failed authentication.
            If i%Handle'="" {
                #; Return %Status error only if in middle of challenge response sequence
                Set sc = $$$ERROR($$$HttpAuthScheme, scheme)
            } Else {
                #; If first challenge, then just return the 401 status.
                Set sc = $$$OK
            }
        }
    } ElseIf i%Handle'="",$extract(..HttpResponse.StatusCode)=2 {
        #; RFC4559 says to finish checking authentication for status code=2xx.
        Set token = ..ProcessHeader(authenticateHeader,.scheme)
        If token = "" {
            #; Handle failed authentication.
            Set sc = $$$ERROR($$$HttpAuthScheme,scheme)
        }
    }

    Return sc
}

}
