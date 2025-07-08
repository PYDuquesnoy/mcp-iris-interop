/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.MFT.Connection.Box Extends %SYS.MFT.Connection.Base [ System = 4 ]
{

/// Each subclass will define the DefaultURL method to supply the default URL for the service.
ClassMethod DefaultURL() As %String
{
	Quit "https://api.box.com/2.0/"
}

/// The URL for uploading and downloading files.
Method ContentURL() As %String
{
	Quit "https://upload.box.com/api/2.0/"
}

/// The default scope to use for obtaining the access token.
ClassMethod DefaultScope() As %String
{
	Quit ""
}

/// Create an OAuth 2.0 client with the parameters required to authorize with Box.<br>
/// name is the name to be given to the OAuth 2.0 client.<br>
/// sslConfiguration is the SSLConfiguration used to make the HTTP request.<br>
/// clientId and ClientSecret are the id and secret for the OAuth 2.0 client which is obtained from
/// the Box App definition.<br>
/// If addiitonal properties are needed, then the Dropbox OAuth 2.0 client may be opened and modified.<br>
/// If a server definition does not yet exist for Dropbox, then a new server definition is created.
ClassMethod CreateClient(name As %String, sslConfiguration As %String, clientId As %String, clientSecret As %String, issuer As %String = "https://account.box.com", host As %String = "localhost", port As %Integer = "", prefix As %String = "", useSSL As %Boolean = 1) As %Status
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
	Set server.Metadata."authorization_endpoint"="https://account.box.com/api/oauth2/authorize"
	Set server.Metadata."token_endpoint"="https://api.box.com/oauth2/token"
	Set server.Metadata."revocation_endpoint"="https://api.box.com/oauth2/revoke"
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
/// Revoke the token in Box as well as locally.
Method RevokeToken() As %Status
{
	Set sc=$$$OK
	Set authorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(..ApplicationName,..ConnectionId,,.accessToken,,,.error)
	If authorized,accessToken'="" {
		// Use standard revocation endpoint.
		Set sc=##class(%SYS.OAuth2.AccessToken).RevokeToken(..ApplicationName,accessToken)
	}
	Quit sc
}

/// Make an http request to Box API
Method MakeRequest(method As %String, parameters As %String, request As %DynamicObject = "", ByRef queryParameters As %String, Output response As %DynamicObject) As %Status
{
	Try {
		// URL property must be specified, if there is no default URL.
		If ..URL="" Set ..URL=..DefaultURL()
		If ..URL="" {
			Set sc=$$$ERROR($$$MFTNoURL,..Name)
			Quit
		}
		If $extract(..URL,*)'="/" Set ..URL=..URL_"/"
		
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest
		
		// Make sure to UTF-8 encode the JSON object
		If $isobject(request) {
			Set httpRequest.ContentType="application/json;charset=UTF-8"
			Set sc=httpRequest.EntityBody.Write(request.%ToJSON())
			If $$$ISERR(sc) Quit
			Do httpRequest.EntityBody.Rewind()
		} Else {
			Set httpRequest.ContentType=""
		}
		Set httpRequest.ResponseStream="string"

		// Set the query parameters
		Set name=""
		Set query=""
		For {
			Set name=$order(queryParameters(name),1,value)
			If name="" Quit
			Set query=query_$select(query="":"?",1:"&")_name_"="_$replace(##class(%CSP.Page).EscapeURL(value),"/","%2F")
		}

		// Retry requests if rate-limiting takes effect.
		For {
			// Make the request
			Set sc=..MakeHttpRequest(httpRequest,method,..URL_parameters_query,0)
			If $$$ISERR(sc) Quit
			// If not rate limited, then exit loop to check response
			Set httpResponse=httpRequest.HttpResponse
			If httpResponse.StatusCode'=429 {
				// Reset the %Net.HttpRequest object now
				Do httpRequest.Reset()
				Quit
			}
			// wait for retry interval, then make request again
			Set retryInterval=httpResponse.GetHeader("Retry-After")
			$$$SysLog(2,"MFT","[%SYS.MFT.Connection.Box:MakeRequest]","retryInterval="_retryInterval)
			hang retryInterval
		}
		If $$$ISERR(sc) Quit
		
		Set sc=..GetJSONResponse(httpRequest,httpRequest.HttpResponse.Data,.response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Box:MakeRequest]","MFT",sc)
	}
	Quit sc
}

/// Make an upload http request to Box API
Method MakeUploadRequest(parameters As %String, filename As %String, request As %DynamicObject = "", body As %BinaryStream, Output response As %DynamicObject) As %Status
{
	Try {
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest
		
		// Create the MIME object
		Set mime=##class(%Net.MIMEPart).%New()
		
		// Set the attributes as a MIME part
		If $isobject(request) {
			Set attributesPart=##class(%Net.MIMEPart).%New()
			Do attributesPart.SetHeader("Content-Disposition","form-data; name=""attributes""")
			Set attributesPart.Body=request.%ToJSON()
			Do mime.Parts.Insert(attributesPart)
		}
		
		// Transfer the stream as a MIME part
		Set bodyPart=##class(%Net.MIMEPart).%New()
		Do bodyPart.SetHeader("Content-Disposition","form-data; name=""file""; filename="""_$zcvt(filename,"O","UTF8")_"""")
		// Set content-type based on file type extension.
		Do ##class(%CSP.StreamServer).FileClassify($select(filename[".":$piece(filename,".",*),1:""),.contenttype)
		Do bodyPart.SetHeader("Content-Type",contenttype)
		Set bodyPart.Body=body
		Do mime.Parts.Insert(bodyPart)
		
		// Create a stream with the MIME data
		Set writer=##class(%Net.MIMEWriter).%New()
		Set sc=writer.OutputToStream(.mimestream)
		If $$$ISERR(sc) Quit
		Set sc=writer.WriteMIMEBody(mime)
		If $$$ISERR(sc) Quit
		do mimestream.Rewind()
		
		// Make the request
		Set httpRequest.EntityBody=mimestream
		Set httpRequest.WriteRawMode=1
		Do httpRequest.SetHeader("Content-Type","multipart/form-data; boundary="_mime.Boundary)
		Set sc=..MakeHttpRequest(httpRequest,"POST",..ContentURL()_parameters)
		If $$$ISERR(sc) Quit
		
		// Process the response object
		Set sc=..GetJSONResponse(httpRequest,httpRequest.HttpResponse.Data,.response)
		If $$$ISERR(sc) Quit
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	// Reset WriteRawMode so that httpRequest object can be reused.	
	Set httpRequest.WriteRawMode=1

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Box:MakeUploadRequest]","MFT",sc)
	}
	Quit sc
}

/// Make an Download style http request to Box API
Method MakeDownloadRequest(parameters As %String, body As %BinaryStream, Output response As %DynamicObject) As %Status
{
	Try {
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest
		
		// Make the request
		Do body.Rewind()
		Set httpRequest.ResponseStream=body
		Set httpRequest.ContentType=""
		Set sc=..MakeHttpRequest(httpRequest,"GET",..URL_parameters)
		If $$$ISERR(sc) Quit

		// Just check status code		
		Set sc=..GetJSONResponse(httpRequest,"",.response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Box:MakeDownloadRequest]","MFT",sc)
	}
	Quit sc
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
