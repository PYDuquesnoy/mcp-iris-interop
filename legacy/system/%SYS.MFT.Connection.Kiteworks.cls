/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.MFT.Connection.Kiteworks Extends %SYS.MFT.Connection.Base [ System = 4 ]
{

Parameter ACCELLIONVERSION = 7.1;

/// Role definitions for this connection.  The role defintions are not saved and refreshed as needed.
Property Roles As array Of %String [ Internal, Transient ];

/// The default scope to use for obtaining the access token.
ClassMethod DefaultScope() As %String
{
	Quit "*/files/* */folders/* */search/* */users/* */devices/* */roles/*"
}

/// Create an OAuth 2.0 client with the parameters required to authorize with Dropbox.<br>
/// name is the name to be given to the OAuth 2.0 client.<br>
/// sslConfiguration is the SSLConfiguration used to make the HTTP request.<br>
/// clientId and ClientSecret are the id and secret for the OAuth 2.0 client which is obtained from
/// the Kiteworks App definition.<br>
/// If addiitonal properties are needed, then the Kiteworks OAuth 2.0 client may be opened and modified.<br>
/// If a server definition does not yet exist for Kiteworks, then a new server definition is created.
ClassMethod CreateClient(name As %String, sslConfiguration As %String, clientId As %String, clientSecret As %String, issuer, host As %String = "localhost", port As %Integer = "", prefix As %String = "", useSSL As %Boolean = 1) As %Status
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
	
	// Note that issuer must be specified for Kitreworks since it is different for each organization.
	Set server.IssuerEndpoint=issuer
	Set server.Metadata."authorization_endpoint"=issuer_"/oauth/authorize"
	Set server.Metadata."token_endpoint"=issuer_"/oauth/token"
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
/// Revoke the token in Kiteworks as well as locally.
Method RevokeToken() As %Status
{
	Set sc=$$$OK
	Set authorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(..ApplicationName,..ConnectionId,,.accessToken,,,.error)
	If authorized,accessToken'="" {
		// Ask Dropbox to revoke the access token.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest

		Do httpRequest.SetHeader("X-Accellion-Version",..#ACCELLIONVERSION)
		Set sc=..MakeHttpRequest(httpRequest,"DELETE",..URL_"rest/devices/me/actions/logout")

		// Locally revoke the access token.
		Set scSuper=##super()
		Set sc=$system.Status.AppendStatus(sc,scSuper)
	}
	Quit sc
}

/// Make an http request to Kiteworks API
Method MakeRequest(method As %String, parameters As %String, request As %DynamicObject = "", ByRef queryParameters As %String, Output response As %DynamicObject) As %Status
{
	Try {
		// URL property must be specified, since there is no default URL for Kiteworks.
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

		// Set the query parameters
		Set name=""
		Set query=""
		For {
			Set name=$order(queryParameters(name),1,value)
			If name="" Quit
			Set query=query_$select(query="":"?",1:"&")_name_"="_$replace(##class(%CSP.Page).EscapeURL(value),"/","%2F")
		}

		// Make the request
		Set httpRequest.ResponseStream="string"
		Do httpRequest.SetHeader("X-Accellion-Version",..#ACCELLIONVERSION)
		Set sc=..MakeHttpRequest(httpRequest,method,..URL_parameters_query)
		If $$$ISERR(sc) Quit
		Set sc=..GetJSONResponse(httpRequest,httpRequest.HttpResponse.Data,.response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Base:MakeRPCRequest]","MFT",sc)
	}
	Quit sc
}

/// Make an upload http request to Kiteworks API
Method MakeUploadRequest(parameters As %String, filename As %String, ByRef queryParameters As %String, body As %BinaryStream, Output response As %DynamicObject) As %Status
{
	Try {
		// Get a %Net.HttpRequest object if one is not yet associated with the connection.
		If '$isobject(..HttpRequest) {
			Set ..HttpRequest=##class(%Net.HttpRequest).%New()
		}
		Set httpRequest=..HttpRequest
		
		// Transfer the stream as a MIME part
		Set bodyPart=##class(%Net.MIMEPart).%New()
		Do bodyPart.SetHeader("Content-Disposition","form-data; name=""body""; filename="""_$zcvt(filename,"O","UTF8")_"""")
		// Set content-type based on file type extension.
		Do ##class(%CSP.StreamServer).FileClassify($select(filename[".":$piece(filename,".",*),1:""),.contenttype)
		Do bodyPart.SetHeader("Content-Type",contenttype)
		Set bodyPart.Body=body
		
		// Create a stream with the MIME data
		Set writer=##class(%Net.MIMEWriter).%New()
		Set sc=writer.OutputToStream(.mimestream)
		If $$$ISERR(sc) Quit
		Set mime=##class(%Net.MIMEPart).%New()
		Do mime.Parts.Insert(bodyPart)
		Set sc=writer.WriteMIMEBody(mime)
		If $$$ISERR(sc) Quit
		do mimestream.Rewind()
		
		// Set the query parameters
		Set name=""
		Set query=""
		For {
			Set name=$order(queryParameters(name),1,value)
			If name="" Quit
			Set query=query_$select(query="":"?",1:"&")_name_"="_$replace(##class(%CSP.Page).EscapeURL(value),"/","%2F")
		}

		// Make the request
		Set httpRequest.EntityBody=mimestream
		Set httpRequest.WriteRawMode=1
		Do httpRequest.SetHeader("Content-Type","multipart/form-data; boundary="_mime.Boundary)
		Do httpRequest.SetHeader("X-Accellion-Version",..#ACCELLIONVERSION)
		Set sc=..MakeHttpRequest(httpRequest,"POST",..URL_parameters_query)
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
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Kiteworks:MakeUploadRequest]","MFT",sc)
	}
	Quit sc
}

/// Make an Download style http request to Kiteworks API
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
		Do httpRequest.SetHeader("X-Accellion-Version",..#ACCELLIONVERSION)
		Set sc=..MakeHttpRequest(httpRequest,"GET",..URL_parameters)
		If $$$ISERR(sc) Quit

		// Just check status code		
		Set sc=..GetJSONResponse(httpRequest,"",.response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.MFT.Connection.Kiteworks:MakeDownloadRequest]","MFT",sc)
	}
	Quit sc
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
