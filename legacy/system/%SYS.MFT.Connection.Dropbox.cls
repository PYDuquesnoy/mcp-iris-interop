/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.MFT.Connection.Dropbox Extends %SYS.MFT.Connection.Base [ System = 4 ]
{

/// Each subclass will define the DefaultURL method to supply the default URL for the service.
ClassMethod DefaultURL() As %String
{
	Quit "https://api.dropboxapi.com/2/"
}

/// The URL for uploading and downloading files.
Method ContentURL() As %String
{
	If ..URL="" {
		Quit "https://content.dropboxapi.com/2/"
	} Else {
		Quit $replace(..URL,"//api.","//content.")
	}
}

/// Create an OAuth 2.0 client with the parameters required to authorize with Dropbox.<br>
/// name is the name to be given to the OAuth 2.0 client.<br>
/// sslConfiguration is the SSLConfiguration used to make the HTTP request.<br>
/// clientId and ClientSecret are the id and secret for the OAuth 2.0 client which is obtained from
/// the Dropbox App definition.<br>
/// If addiitonal properties are needed, then the Dropbox OAuth 2.0 client may be opened and modified.<br>
/// If a server definition does not yet exist for Dropbox, then a new server definition is created.
ClassMethod CreateClient(name As %String, sslConfiguration As %String, clientId As %String, clientSecret As %String, issuer As %String = "https://api.dropboxapi.com", host As %String = "localhost", port As %Integer = "", prefix As %String = "", useSSL As %Boolean = 1) As %Status
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Set sc=$$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
		Quit
	}
	$$$AddAllRoleTemporary
	
	New $namespace
	Set $namespace="%sys"
	
	Do ##class(OAuth2.Client).DeleteId(name)
	Set client=##class(OAuth2.Client).%New()
	Set client.ApplicationName=name
	Set client.ClientType="confidential"
	Set client.SSLConfiguration=sslConfiguration
	Set client.RedirectionEndpoint.Host=host
	Set client.RedirectionEndpoint.Port=port
	Set client.RedirectionEndpoint.Prefix=prefix
	Set client.RedirectionEndpoint.UseSSL=useSSL

	Set client.AuthenticationType="body"
	Set client.SigningAlgorithm="RS256"
	Set client.Metadata."grant_types"=$lb("authorization_code")
	Set client.Metadata."client_name"=name_" client"

	Set server=##class(OAuth2.ServerDefinition).OpenByIssuer(issuer)
	If '$isobject(server) {
		Set server=##class(OAuth2.ServerDefinition).%New()
	}
	
	Set server.IssuerEndpoint=issuer
	Set server.Metadata."authorization_endpoint"="https://www.dropbox.com/oauth2/authorize"
	Set server.Metadata."token_endpoint"="https://api.dropboxapi.com/oauth2/token"
	Set sc=server.%Save()
	If $$$ISERR(sc) Quit sc

	Set client.ServerDefinition=server
	Set client.ClientId=clientId
	Set client.ClientSecret=clientSecret
	Set sc=client.%Save()
	If $$$ISERR(sc) Quit sc
	
	Quit $$$OK
}

/// Revoke the token associated with this connection.
/// Revoke the token in Dropbox as well as locally.
Method RevokeToken() As %Status
{
	Set sc=$$$OK
	Set authorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(..ApplicationName,..ConnectionId,,.accessToken,,,.error)
	If authorized,accessToken'="" {
		// Ask Dropbox to revoke the access token.
		If ..URL="" Set ..URL=..DefaultURL()
		Set sc=..MakeHttpRequest(,"POST",..URL_"auth/token/revoke")

		// Locally revoke the access token.
		Set scSuper=##super()
		Set sc=$system.Status.AppendStatus(sc,scSuper)
	}
	Quit sc
}

/// Make an RPC style http request to Dropbox API
Method MakeRPCRequest(parameters As %String, request As %DynamicObject, Output response As %DynamicObject) As %Status
{
	Try {
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest
		
		// Make sure to UTF-8 encode the JSON object
		Set httpRequest.ContentType="application/json;charset=UTF-8"
		Set sc=httpRequest.EntityBody.Write(request.%ToJSON())
		If $$$ISERR(sc) Quit

		// Make the request
		Set httpRequest.ResponseStream="string"
		Do httpRequest.EntityBody.Rewind()
		If ..URL="" Set ..URL=..DefaultURL()
		Set sc=..MakeHttpRequest(httpRequest,"POST",..URL_parameters)
		If $$$ISERR(sc) Quit
		
		Set sc=..GetJSONResponse(httpRequest,httpRequest.HttpResponse.Data,.response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Dropbox:MakeRPCRequest]","MFT",sc)
	}
	Quit sc
}

/// Make an Upload style http request to Dropbox API
Method MakeUploadRequest(parameters As %String, request As %DynamicObject, body As %BinaryStream, Output response As %DynamicObject) As %Status
{
	Try {
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest
		
		// Make sure to UTF-8 encode the JSON object
		Do httpRequest.SetHeader("Dropbox-API-Arg",request.%ToJSON())

		// Make the request
		Set httpRequest.EntityBody=body
		Do httpRequest.SetHeader("Content-Type","application/octet-stream")
		Set sc=..MakeHttpRequest(httpRequest,"POST",..ContentURL()_parameters)
		If $$$ISERR(sc) Quit
		
		// Process the response object
		Set sc=..GetJSONResponse(httpRequest,httpRequest.HttpResponse.Data,.response)
		If $$$ISERR(sc) Quit
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Download:MakeUploadRequest]","MFT",sc)
	}
	Quit sc
}

/// Make an Download style http request to Dropbox API
Method MakeDownloadRequest(parameters As %String, request As %DynamicObject, body As %BinaryStream, Output response As %DynamicObject) As %Status
{
	Try {
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest
		
		// Make sure to UTF-8 encode the JSON object
		Do httpRequest.SetHeader("Dropbox-API-Arg",request.%ToJSON())

		// Make the request
		Do body.Rewind()
		Set httpRequest.ResponseStream=body
		Set sc=..MakeHttpRequest(httpRequest,"POST",..ContentURL()_parameters)
		If $$$ISERR(sc) Quit
		
		Set json=httpRequest.HttpResponse.GetHeader("Dropbox-API-Result")
		Set sc=..GetJSONResponse(httpRequest,json,.response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Dropbox:MakeDownloadRequest]","MFT",sc)
	}
	Quit sc
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
