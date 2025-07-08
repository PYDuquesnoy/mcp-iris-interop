/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The file manager to be used by %MFT classes will be described by a persistent class whose properties
/// are stored in the CACHESYS database.  This persistent file manager description will contain locations,
/// user name and authentication information - essentially the connection and authentication information
/// for the file management service.<br>
/// The user of the file management API must create a persistent description
/// of the connection to remote file management service.  This connection is defined by
/// the subclass of %SYS.MFT.Connection.Base which is implemented for the service provider being used.<br>
/// The initially supported services all authenticate by using the OAuth 2.0 protocol. 
/// The file management connection will use OAuth 2.0 support to do the required authentication.
/// An OAuth2 client must be configured for use by the connection.  The details of the client are defined
/// by the requirements of the specific vendor service.  The ApplicationName property below is the
/// application name for the OAuth2 client.<br>
/// The %SYS.MFT.Connection>base class contains the base properties and methods for the remote file management
/// services that we support.  The %Admin_Secure will be required in order to open or save this object.
Class %SYS.MFT.Connection.Base Extends %Persistent [ System = 4 ]
{

/// The IDKEY for %SYS.MFT.Connection.Base is a unique user defined name.
Index IDIndex On Name [ IdKey, Unique ];

/// Name is the name of this connection to a file management service.
/// Name serves as the IDKey for this class.
Property Name As %String(MAXLEN = 64) [ Required ];

/// Service is the name of the service that is accessed by this connection.
Property Service As %String [ InitialExpression = {$piece($classname(),".",*)} ];

/// URL is the base URL for REST access to this service including the final /.
/// URL will default to the base URL for the remote file management service that is provided by the vendor.
/// URL may be modified for locally hosted or private remote implementations.
Property URL As %OAuth2.uri [ InitialExpression = {..DefaultURL()} ];

/// SSLConfiguration is the name of the SSL Configuration to be used to communicate with the file management API.
Property SSLConfiguration As %String(MAXLEN = 64);

/// Username is the name of the user on whose behalf the file access will take place.
Property Username As %Library.Username;

/// ApplicationName is the OAuth2 application name associated with this connection.
/// The ConnectionId property will be used as the session id for the specific access token.
Property ApplicationName As %String(MAXLEN = 64);

/// ConnectionId is the base 64 URL encoded Id for this connection.
/// ConnectionId is a private property which is not readable or writable outside of this class.
/// ConnectionId is used for private access to any access token needed for this connection.
Property ConnectionId As %String(MAXLEN = 128) [ InitialExpression = {##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(32))}, Internal, Private ];

/// The current remote folder as a Unix style path.
/// The path is canonical in the sense of not having .. or. and always ending in /.
Property CurrentFolder As %String(MAXLEN = 2048) [ InitialExpression = "/", Internal ];

/// Use the same %Net.HttpRequest object for all requests in the same session.
Property HttpRequest As %Net.HttpRequest [ Transient ];

/// Each subclass will define the DefaultURL method to supply the default URL for the service.
ClassMethod DefaultURL() As %String
{
	Quit ""
}

/// The default scope to use for obtaining the access token.
ClassMethod DefaultScope() As %String
{
	Quit ""
}

/// Create an OAuth 2.0 client with the parameters required to authorize.<br>
/// name is the name to be given to the OAuth 2.0 client.<br>
/// sslConfiguration is the SSLConfiguration used to make the HTTP request.<br>
/// clientId and ClientSecret are the id and secret for the OAuth 2.0 client which is obtained from
/// the corresponding App definition.<br>
/// If addiitonal properties are needed, then the OAuth 2.0 client may be opened and modified.<br>
/// If a server definition does not yet exist for the OAuth 2.0 client, then a new server definition is created.
ClassMethod CreateClient(name As %String, sslConfiguration As %String, clientId As %String, clientSecret As %String, issuer, host As %String, port As %Integer, prefix As %String, useSSL As %Boolean) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Internal method to normalize the a file or folder path.
Method NormalizePath(path As %String) As %String [ Internal ]
{
	// Normalize to work with / separator
	Set path = $translate(path,"\","/")
	
	// If not path, just return current folder
	If path="" Quit ..CurrentFolder 
	
	// If relative path, prepend the current folder
	If $extract(path)'="/" {
		Set path=..CurrentFolder_path
	}
	
	// Normalize path by removing . and ..
	Set normalized=$piece(path,"/",$length(path,"/"))
	Set skip=0
	For i=$length(path,"/")-1:-1:1 {
		Set p=$piece(path,"/",i)
		If p'="." {
			If (p="..") && ($piece(path,"/",i-1)'="") {
				Set skip=skip+1
			} Else {
				If skip>0 {
					Set skip=skip-1
				} Else {
					Set normalized=p_"/"_normalized
				}
			}
		}
	}

	Quit normalized
}

/// MakeHttpRequest will add authentication to the specified %Net.HttpRequest object and
/// execute the request using the specified method with the specified REST parameters added to the URL.
/// After the request is made, the authentication information is removed to avoid making this available to user code.
Method MakeHttpRequest(httpRequest As %Net.HttpRequest, method As %String, url As %String, reset As %Boolean = 1) As %Status
{
	Try {
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject($get(httpRequest)) {
			Set httpRequest=##class(%Net.HttpRequest).%New()
		}
		
		// Add authorization as a bearer token
		Set sc=##class(%SYS.OAuth2.AccessToken).AddAccessToken(httpRequest,,..SSLConfiguration,..ApplicationName,..ConnectionId)
		If $$$ISERR(sc) Quit
		
		// Log the request that we are making
		If $$$SysLogLevel>=2 {
			Do ##class(%OAuth2.Utils).LogHTTPRequest("[%SYS.MFT.Connection.Base:MakeHttpRequest]","MFT",
				httpRequest,method,url,,2)
		}
	
		// Make the REST request.
		Set sc=httpRequest.Send(method,url,,reset)
		
		If $$$ISOK(sc) {
			// Log the response
			If $$$SysLogLevel>=2 {
				Do ##class(%OAuth2.Utils).LogHTTPResponse("[%SYS.MFT.Connection.Base:MakeHttpRequest]","MFT",httpRequest,2)
			}
			// Treat no HTTP status code as an error
			If httpRequest.HttpResponse.StatusCode="" {
				Set sc=$$$ERROR($$$MFTErrorResponse,"response has null HTTP status code")
			}
		}
		
		// Remove the access token from the %Net.HttpRequest object authorization header.
		Set sc1=##class(%SYS.OAuth2.AccessToken).RemoveAuthorizationAccessToken(httpRequest)
		Set sc=$system.Status.AppendStatus(sc,sc1)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Base:MakeHttpRequest]","MFT",sc)
	}
	Quit sc
}

/// Get the response object
ClassMethod GetJSONResponse(httpRequest As %Net.HttpRequest, json As %String, Output response As %DynamicObject) As %Status [ Final, Internal ]
{
	Try {
		Set sc=$$$OK
		Set error=""
		Set response=""

		// Get response as string
		If $isobject(json) {
			Do json.Rewind()
			Set size=json.Size
			Set json=json.Read(size)
		}

		// Convert json from UTF-8
		Set json=$zconvert(json,"I","UTF8")
		
		// Ignore body which is exactly "null"
		If json="null" Set json=""
		
		// Handle success and error cases
		Set statusCode=httpRequest.HttpResponse.StatusCode
		If statusCode>=200,statusCode<=204 {
			// Parse JSON string into an object
			If json'="" {
				Set response=##class(%DynamicAbstractObject).%FromJSON(json)
				// Handle Dropbox special case.
				If response.%IsA("%DynamicObject"),response.%Get("error_summary")'="" {
					// handle error
					Set error="ERROR "_response."error_summary"
				}
			}
			
		} ElseIf statusCode=404,json'="" {
			// Handle Box special case
			Set response=##class(%DynamicAbstractObject).%FromJSON(json)
			If response.%IsA("%DynamicObject"),response.type="error" {
				Set error="ERROR "_response.code_": "_response.message
			}
		
		} Else {
			Set error="ERROR "_statusCode_": "_json
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If error'="" {
		Set sc=$$$ERROR($$$MFTErrorResponse,error)
	}
	
	Quit sc
}

/// Check if this connection has been authorized.
/// The default authorization is via OAuth 2.0 access token.
Method IsAuthorized(Output errorMessage As %String) As %Boolean
{
	Set errorMessage=""
	Set authorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(..ApplicationName,..ConnectionId,,,,,.error)
	If $isobject(error) {
		Set errorMessage=error.AsString()
	}
	Quit authorized
}

/// Get access token
ClassMethod GetAccessToken(connectionName As %String, scope As %String, accessToken As %String) As %Status [ Internal ]
{
	Set connection=##class(%SYS.MFT.Connection.Base).%OpenId(connectionName,,.sc)
	If $$$ISOK(sc) {
		If '##class(%SYS.OAuth2.AccessToken).GetAccessToken(connection.ApplicationName,connection.ConnectionId,.scope,.accessToken) {
			set sc=$$$ERROR($$$MFTNotAuthorized)
		}
	}
	Quit sc
}

/// Get the URL for use by authorization code grant type.
Method GetAuthorizationCodeURL(redirect As %String, scope As %String, ByRef properties As %String, Output sc As %Status) As %String
{
	// If redirect URL is not specified, then redirect back to the current page.
	If $get(redirect)="" {
		// Redirect back to the page which is being logged in
		Set redirect=%request.GetCgiEnv("REQUEST_URI")  ; Apache
		If redirect="" Set redirect=%request.GetCgiEnv("HTTP_URL")  ; IIS
		Set redirect=$select(%request.Secure:"https://",1:"http://")_%request.GetCgiEnv("HTTP_HOST")_redirect
	}
	
	// Get and return the authorization code URL.
	Set url=##class(%SYS.OAuth2.Authorization).GetAuthorizationCodeEndpoint(..ApplicationName,.scope,redirect,.properties,.isAuthorized,.sc,,..ConnectionId)
	Quit url
}

/// Revoke the token associated with this connection.
Method RevokeToken() As %Status
{
	Set sc=$$$OK
	Set authorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(..ApplicationName,..ConnectionId,,.accessToken,,,.error)
	If authorized,accessToken'="" {
		Set token=##class(OAuth2.AccessToken).Open(accessToken,.sc)
		If $isobject(token) Set sc=token.Remove()
	}
	Quit sc
}

/// Open a %SYS.MFT.Connection.Base subclass instance based on the ConnectionName property.
ClassMethod Open(name As %String, Output sc As %Status) As %SYS.MFT.Connection.Base
{
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		Set connection=##class(%SYS.MFT.Connection.Base).%OpenId(name,,.sc)
		If '$isobject(connection) || $$$ISERR(sc) Quit
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) Set connection=""		
	Quit connection
}

/// The Save method saves a %SYS.MFT.Connection.Base object.
/// To save a new Connection object use the following procedure:<br>
/// - get a new object with %New of the appropriate subclass of %SYS.MFT.Connection.Base.<br>
/// - set required unique Name property.<br>
/// - set any needed properties.<br>
/// - call the Save method.
Method Save() As %Status
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Set sc=$$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
		Quit
	}
	$$$AddAllRoleTemporary
	
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		Set sc=..%Save()
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

Method %OnValidateObject(ReadOnly As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// Caller of %Save must have secureity admin resource. 
Method %OnBeforeSave(insert As %Boolean) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	Quit $$$OK
}

/// The DeleteId method deletes an existing connection object specified by its name.
/// If keepOAuth2 is true, then the associated OAuth 2.0 connection is deleted.
/// Otherwise, the OAuth2 connection is kept.
ClassMethod DeleteId(name As %String, keepOAuth2 As %Boolean = 0) As %Status
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary
	
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		Set sc=$$$OK
		// Open the connection in order to get application name for OAuth 2.0 client
		Set connection=..Open(name,.sc)
		If $$$ISERR(sc) Quit

		If 'keepOAuth2,connection.OAuth2ClientCount()<=1 {
			// Delete the OAuth 2.0 client.
			Set client=##class(OAuth2.Client).Open(connection.ApplicationName,.sc1)
			If $$$ISOK(sc1) {
				Set server=client.ServerDefinition
				Do server.Clients.Remove(client)
				Set sc1=##class(OAuth2.Client).DeleteId(client.%Id())
			}
			If $$$ISOK(sc1),server.ClientCount()=0 {
				Set sc1=##class(OAuth2.ServerDefinition).DeleteId(server.%Id())
			}
			If $$$ISERR(sc1) Set sc=$$$ADDSC(sc,sc1)
		}
		
		Set sc1=..%DeleteId(name)
		If $$$ISERR(sc1) Set sc=$$$ADDSC(sc,sc1)

		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

/// Get count of connection which reference the specified OAuth 2.0 client.
Method OAuth2ClientCount() As %Integer
{
	Set applicationName=..ApplicationName
	&SQL( SELECT COUNT(*) INTO :count FROM Base WHERE ApplicationName = :applicationName )
	If SQLCODE'=0 Set count=0
	Quit count
}

/// Caller of %Delete must have secureity admin resource. 
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	Quit $$$OK
}

/// List connections.
Query List() As %Query(ROWSPEC = "Name:%String,Service:%String,IsAuthorized:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef %qHandle As %Binary) As %Status [ Internal ]
{
	Set sc=$$$OK

	Try {
		&SQL(DECLARE MFTListCursor CURSOR for 
		     SELECT Name,Service,ApplicationName,ConnectionId
		     FROM Base
		     ORDER BY Name)
		&SQL(OPEN MFTListCursor)
		if SQLCODE<0 s sc=$$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Base:ListExecute]","MFT",sc)
	}
	Quit sc
}

ClassMethod ListFetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListExecute ]
{
	Set sc=$$$OK

	Try {
		&SQL(FETCH MFTListCursor INTO :Name,:Service,:ApplicationName,:ConnectionId)
		If SQLCODE<0 {
			Set sc= $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
		} ElseIf SQLCODE=100 {
			Set Row="",AtEnd=1
		} Else {
			Set isAuthorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(ApplicationName,ConnectionId)
			Set Row=$LB(Name,Service,$select(isAuthorized:"",1:"Not ")_"Authorized")
			Set AtEnd=0
 		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Base:ListFetch]","MFT",sc)
	}
	Quit sc
}

ClassMethod ListClose(ByRef %qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListExecute ]
{
	&SQL(CLOSE MFTListCursor)
	if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
	Quit $$$OK
}

Storage Default
{
<Data name="ConnectionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<Data name="MFTConnectionDefaultData">
<Subscript>"1"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Service</Value>
</Value>
<Value name="3">
<Value>URL</Value>
</Value>
<Value name="4">
<Value>SSLConfiguration</Value>
</Value>
<Value name="5">
<Value>Username</Value>
</Value>
<Value name="6">
<Value>ApplicationName</Value>
</Value>
<Value name="7">
<Value>Id</Value>
</Value>
<Value name="8">
<Value>PublicKeyFilename</Value>
</Value>
<Value name="9">
<Value>PrivateKey</Value>
</Value>
<Value name="10">
<Value>ConnectionId</Value>
</Value>
<Value name="11">
<Value>CurrentFolder</Value>
</Value>
</Data>
<DataLocation>^|"^^"_$zu(12)|SYS("Security","MFTConnectionD")</DataLocation>
<DefaultData>MFTConnectionDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^|"^^"_$zu(12)|SYS("Security","MFTConnectionD")</IdLocation>
<IndexLocation>^|"^^"_$zu(12)|SYS("Security","MFTConnectionI")</IndexLocation>
<StreamLocation>^|"^^"_$zu(12)|SYS("Security","MFTConnectionS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
