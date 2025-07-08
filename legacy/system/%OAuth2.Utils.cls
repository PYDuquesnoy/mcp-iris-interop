/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Utility methods for OAuth 2.0 support.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %OAuth2.Utils Extends %RegisteredObject [ System = 3 ]
{

/// Encode binary value using base64url encoding
ClassMethod Base64UrlEncode(bin As %Binary) As %String [ CodeMode = expression ]
{
$translate($piece($system.Encryption.Base64Encode(bin,1),"=",1),"+/","-_")
}

/// Decode base64url encoded string
ClassMethod Base64UrlDecode(text As %String) As %Binary [ CodeMode = expression ]
{
$system.Encryption.Base64Decode($translate(text,"-_","+/")_$case($length(text)#4,0:"",2:"==",3:"="))
}

/// Convert $h value to seconds since start of the Unix epoch,<br>
/// time is $h value.<br>
/// interval is interval to be added in seconds.
ClassMethod TimeInSeconds(time As %String, interval As %Integer = 0) As %Integer [ Internal ]
{
	Quit (($piece(time,",")-47117)*86400+$piece(time,",",2)+interval)\1
}

/// Convert seconds since start of the Unix epoch to $h format.
ClassMethod TimeInH(time As %Integer) As %String [ Internal ]
{
	Set days=time\86400+47117
	Set seconds=time#86400
	Quit days_","_seconds
}

/// Check if apecified algorithm is symmetric
/// This method is deprecated. Use the <b>IsAlgSymmetric</b> method in <class>%Net.JSON.JWA</class> instead.
ClassMethod IsAlgSymmetric(alg As %String) As %Boolean [ Deprecated ]
{
	Return ##class(%Net.JSON.JWA).IsAlgSymmetric(alg)
}

/// Check if specified algorithm is RSA algorithm
/// This method is deprecated. Use the <b>IsAlgRSA</b> method in <class>%Net.JSON.JWA</class> instead.
ClassMethod IsAlgRSA(alg As %String) As %Boolean [ Deprecated ]
{
	Return ##class(%Net.JSON.JWA).IsAlgRSA(alg)
}

/// Check if specified algorithm is EC algorithm
/// This method is deprecated. Use the <b>IsAlgEC</b> method in <class>%Net.JSON.JWA</class> instead.
ClassMethod IsAlgEC(alg As %String) As %Boolean [ Deprecated ]
{
	Return ##class(%Net.JSON.JWA).IsAlgEC(alg)
}

ClassMethod GetSupportedAlgorithms(Output sigalgs As %List, Output encalgs As %List, Output keyalgs As %List)
{
	Set sigalgs=##class(%Net.JSON.JWA).#SignatureAlgorithms
	Set keyalgs=##class(%Net.JSON.JWA).#KeyAlgorithms
	Set encalgs=##class(%Net.JSON.JWA).#EncryptionAlgorithms
}

/// Update the private JWKS for client or authorization server with a new private/public key pair or each supported algorithm.
/// UpdatePrivateJWKS is used to initially create the JWKS or to do key rotation.
ClassMethod UpdatePrivateJWKS(ByRef privateJWKS As %String, ByRef publicJWKS As %String) As %Status [ Internal ]
{
	Set sc=$$$OK
	Do ..GetSupportedAlgorithms(.sigalgs,.encalgs,.keyalgs)
	Set algs=sigalgs_keyalgs

	Set privKid = ..FindLastKid(.privateJWKS)
	Set pubKid = ..FindLastKid(.publicJWKS)

	// the last kid should match, but if it doesn't make sure to use the larger one
	Set kid = $select(privKid>=pubKid:privKid, 1:pubKid)

	Try {
		Set ptr=0
		While $listnext(algs,ptr,alg) {
			If '##class(%Net.JSON.JWA).IsAlgSymmetric(alg) {
				$$$ThrowOnError(##class(%Net.JSON.JWK).Create(alg,, .privJWK, .pubJWK))
				Set privJWK.kid = $i(kid)
				Set pubJWK.kid = kid
				$$$ThrowOnError(##class(%Net.JSON.JWKS).PutJWK(privJWK, .privateJWKS))
				$$$ThrowOnError(##class(%Net.JSON.JWKS).PutJWK(pubJWK, .publicJWKS))
			}
		}
	} Catch ex {
		Set sc = ex.AsStatus()
	}

	Quit sc
}

ClassMethod FindLastKid(jwks As %String) As %Integer
{
	If $get(jwks)="" {
		Return ""
	}
	Set kid = 0
	Set jwks = ##class(%DynamicObject).%FromJSON(jwks)

	Set iter = jwks.keys.%GetIterator()
	While iter.%GetNext(.key,.jwk) {
		If (+jwk.kid=jwk.kid) && (jwk.kid>kid) {
			Set kid = +jwk.kid
		}
	}

	Return $select(kid=0:"", 1:kid)
}

ClassMethod GetSecurityParams(ops As %DynamicObject, Output securityParams) [ Internal ]
{
	Kill securityParams
	Set iter = ops.%GetIterator()
	While iter.%GetNext(,.value) {
		If value.type="sig",value.alg'="none" {
			Set securityParams("sigalg") = value.alg
		} ElseIf value.type="enc" {
			Set securityParams("keyalg") = value.alg
			Set securityParams("encalg") = value.enc
		}
	}
}

/// Convert a comma separated list to a $list
ClassMethod CommaToList(str As %String) As %List
{
	Set list=""
	For i=1:1:$length(str,",") {
		Set val=$zstrip($piece(str,",",i),"<>W")
		If val'="" Set list=list_$lb(val)
	}
	Quit list
}

/// Convert a $list to comman separated list
ClassMethod ListToComma(list As %List) As %String
{
	Quit $listtostring(list)
}

/// Check that scope is subset of valid scopes for this token
ClassMethod CheckScope(tokenScope As %String, scope As %String) As %OAuth2.Error
{
	If ##class(%SYS.OAuth2.AccessToken).IsScopeContained(tokenScope,scope) {
		Set error=""
	} Else {
		Set error=##class(%OAuth2.Error).%New("invalid_request","Invalid scope")
	}

	Quit error
}

/// Normalize scope
ClassMethod NormalizeScope(scope As %String) As %String [ Internal ]
{
	Quit $zstrip($translate(scope,$c(9,10,13,160),"    "),"<=>W")
}

/// Select the language for Authentication Class localization.<br>
/// uiLocales is the value of the ui_locales request parameter.<br>
/// The return value is the selected language code.<br>
/// Call looks like:  
///   Set language=##class(%OAuth2.Utils).SelectLanguage(properties.RequestProperties.GetAt("ui_locales"),domain)
ClassMethod SelectLanguage(uiLocales As %String, domain As %String) As %String
{
	// Normalize the acceptable language list.
	// Note that this list is in preference order.
	Set tags=$zcvt($zstrip($translate(uiLocales,$c(9,10,13,160),"    "),"<=>W"),"L")
	If tags="" Quit $$$SessionLanguage
	
	// Get the list of available language localizations.
	Set languageList=$$GetLanguages^%occMessages(domain,$select($extract(domain)="%":"+s",1:"-s"))
	For i=1:1:$listlength(languageList) {
		Set language($list(languageList,i))=""
	}
	
	// Search for exact match in preference order
	Set returnLanguage=""
	For i=1:1:$length(tags," ") {
		Set tag=$piece(tags," ",i)
		If $data(language(tag)) {
			// Best is exact match
			Set returnLanguage=tag
			Quit
		}
	}
	
	// Search for country match in preference order
	If returnLanguage="" {
		For i=1:1:$length(tags," ") {
			Set tag=$piece(tags," ",i)
			If tag["-",$data(language($piece(tag,"-",1))) {
				// OK to just match country
				Set returnLanguage=$piece(tag,"-",1)
				Quit
			}
		}
	}
	
	// Default to session language
	If returnLanguage="" Set returnLanguage=$$$SessionLanguage
	
	Quit returnLanguage
}

/// Get the default sessionId if none is specified.
ClassMethod GetDefaultSessionId(ByRef sessionId As %String) As %String [ Internal ]
{
	If $get(sessionId)="" {
		If $isobject($get(%session)) {
			Set sessionId=%session.SessionId
		} Else {
			Set sessionId="NOTCSP"
		}
	}
}

/// Output JSON object to the current device
ClassMethod ObjectToJSON(object As %DynamicAbstractObject) As %Status
{

	Try {
		Write object.%ToJSON()
		Set sc=$$$OK

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

/// Log an OAuth 2.0 error
ClassMethod LogError(methodName As %String, server As %Boolean, sc As %Status, data As %String) [ Internal ]
{
	$$$SysLog(2,"OAuth2"_$select(server:"Server",1:""),methodName_"Error: "_$system.Status.GetErrorText(sc),.data)
}

/// Log details of HTTP request received by CSP
ClassMethod LogCSPRequest(methodName As %String, server As %Boolean) [ Internal ]
{
	If $$$SysLogLevel<3 Quit
	Set data="Content-Type: "_%request.ContentType
	Set data=data_", Secure: "_%request.Secure
	Set data=data_", Method: "_%request.Method
	Set authorization=%request.GetCgiEnv("HTTP_AUTHORIZATION")
	If authorization'="" {
		Set data=data_", Authorization: "_authorization
	}
	Set name=""
	For {
		Set name=$order(%request.Data(name))
		If name="" Quit
		Set index=""
		For {
			Set index=$order(%request.Data(name,index),1,value)
			If index="" Quit
			If name="client_secret" Set value="*****"
			If $zcvt(name,"L")="password" Set value="*****"
			Set data(name,index)=value
		}
	}
	If %request.Content'="" {
		If $isobject(%request.Content) {
			Set data=data_", Content: "_%request.Content.Read()
		} Else {
			Set data=data_", Content: "_%request.Content
		}
	}
	If $$$SysLogLevel>=5 {
		Set name=""
		For {
			Set name=%request.NextCookie(name)
			If name="" Quit
			Set data("Cookie",name)=%request.GetCookie(name)
		}
		Set name="HTTP_"
		For {
			Set name=$order(%request.CgiEnvs(name),1,value)
			If $extract(name,1,5)'="HTTP_" Quit
			Set data("Header",name)=value
		}
	}
	$$$SysLog(3,"OAuth2"_$select(server:"Server",1:""),methodName_"CSP Request",.data)
}

/// Log details of HTTP request to be made
ClassMethod LogHTTPRequest(methodName As %String, server As %Boolean, httpRequest As %Net.HttpRequest, method As %String, url As %String, ByRef formData, logLevel As %Integer = 3) [ Internal ]
{
	If $$$SysLogLevel<logLevel Quit

	Set data=method_": "_url
	Set data=data_", Content-Type: "_httpRequest.ContentType
	Set data("SSLConfiguration")=httpRequest.SSLConfiguration
	Set authorization=httpRequest.GetHeader("AUTHORIZATION")
	If authorization'="" {
		Set data=data_", Authorization: "_authorization
	}
	Set stream=##class(%GlobalCharacterStream).%New()
	Do httpRequest.OutputFormData(stream)
	Do stream.Rewind()
	Set body=stream.Read(8000)
	Set pos=$find(body,"&password=")
	If pos>0 {
		Set endpos=$find(body,"&",pos)
		If endpos>0 {
			Set $extract(body,pos,endpos-2)="*****"
		} Else {
			Set $extract(body,pos,*)="*****"
		}
			
	}
	Set data("-body-")=body
	Do httpRequest.EntityBody.Rewind()
	Set size=httpRequest.EntityBody.Size
	If size>0 {
		Set data("EntityBody")=httpRequest.EntityBody.Read(8000)
		Do httpRequest.EntityBody.Rewind()
	}
	Set data("-headers-")=httpRequest.ReturnHeaders()
	#; Entity headers
	Set name=""
	For  {
		Set name=httpRequest.EntityBody.NextAttribute(name) If name="" Quit
		Set data("ATTRIBUTE",name)=httpRequest.EntityBody.GetAttribute(name)
	}
	Set name=""
	For {
		Set name=$order(formData(name),1,value)
		If name="" Quit
		If name="password" Set value="*****"
		Set data(name)=value
	}
	// Log the query parameters
	Set name=""
	For {
		Set name=httpRequest.NextParam(name)
		If name="" Quit
		Set data("query",name)=httpRequest.GetParam(name)
	}
	$$$SysLog(logLevel,$select(server=1:"OAuth2Server",server="MFT":"MFT",1:"OAuth2"),methodName_"HTTP Request",.data)
}

/// Log details of HTTP response
ClassMethod LogHTTPResponse(methodName As %String, server As %Boolean, httpRequest As %Net.HttpRequest, logLevel As %Integer = 3) [ Internal ]
{
	If $$$SysLogLevel<logLevel Quit

	Set httpResponse=httpRequest.HttpResponse
	Set data="StatusCode="_httpResponse.StatusCode
	Set data=data_", ContentType="_httpResponse.ContentType
	If $isobject(httpResponse.Data) {
		Set size=httpResponse.Data.Size
		Set data=data_", size="_size
		Set data=data_",body="
		Set data=data_httpResponse.Data.Read(8000)
	} Else {
		Set data=data_",body="
		Set data=data_httpResponse.Data
	}
	If $$$SysLogLevel>=5 {
		Merge data=httpResponse.Headers
	}
	$$$SysLog(logLevel,$select(server=1:"OAuth2Server",server="MFT":"MFT",1:"OAuth2"),methodName_"HTTP Response",.data)
}

/// Log a server token
ClassMethod LogServerToken(methodName As %String, token As OAuth2.Server.AccessToken) [ Internal ]
{
	If $$$SysLogLevel<3 Quit
	
	Set data("AuthorizationCode")=token.AuthorizationCode
	Set data("AccessToken")=token.AccessToken
	Set data("AccessTokenExpires")=token.AccessTokenExpires
	Set data("RefreshToken")=token.RefreshToken
	Set data("IDToken")=token.IDToken
	Set data("ClientId")=token.ClientId
	Set data("Scope")=token.Scope
	Do token.Properties.LogProperties(.data)
	If token.ScopeArray'="" {
		Set key=""
		For {
			Set value=token.ScopeArray.GetNext(.key)
			If key="" Quit
			Set data("ScopeArray",key)=value
		}
	}
	Set data("AuthorizationCodeExpires")=token.AuthorizationCodeExpires
	Set data("GrantType")=token.GrantType
	Set data("Stage")=token.Stage
	Set data("State")=token.State
	Set data("Username")=$select(token.Username=$char(0):"<NULL>",1:token.Username)
	Set data("Issuer")=token.Issuer
	If (token.Aud="") || (token.Aud.Count()=0) {
		Set data("Aud")=""
	} Else {
		For i=1:1:token.Aud.Count() {
			Set data("Aud",i)=token.Aud.GetAt(i)
		}
	}
	Set data("RedirectURL")=token.RedirectURL
	Set data("AuthTime")=token.AuthTime
	Set data("ResponseType")=token.ResponseType
	Set data("ResponseMode")=token.ResponseMode

	$$$SysLog(3,"OAuth2Server",methodName_": Access Token",.data)
}

/// Log a server token
ClassMethod LogServerScope(methodName As %String, token As OAuth2.Server.AccessToken) [ Internal ]
{
	If $$$SysLogLevel<3 Quit
	
	Set data("Scope")=token.Scope
	If token.ScopeArray'="" {
		Set key=""
		For {
			Set value=token.ScopeArray.GetNext(.key)
			If key="" Quit
			Set data("ScopeArray",key)=value
		}
	}

	$$$SysLog(3,"OAuth2Server",methodName_": Access Token Scope",.data)
}

/// Log a local array
ClassMethod LogArray(methodName As %String, server As %Boolean, desc As %String, ByRef array) [ Internal ]
{
	If $$$SysLogLevel<3 Quit
	
	Merge data=array

	$$$SysLog(3,"OAuth2"_$select(server:"Server",1:""),methodName_"Array "_desc,.data)
}

/// Log a JSON object
ClassMethod LogJSON(methodName As %String, server As %Boolean, desc As %String, json As %DynamicObject) [ Internal ]
{
	If $$$SysLogLevel<3 Quit

	Set iterator=json.%GetIterator()
	While iterator.%GetNext(.prop,.value) {
		Set data(prop)=value
	}

	$$$SysLog(3,"OAuth2"_$select(server:"Server",1:""),methodName_"JSON "_desc,.data)
}

/// Display ^ISCLOG
ClassMethod DisplayLog(file As %String = "oauth2.log", testMode As %Boolean = 0) [ Internal ]
{
	Try {
		do ##class(%File).Delete(file)
		Set open=0,io="",error=""
		Set io=$io
		Open file:"waes":1 else  Set error="Unable to open log file" Quit
		Set open=1
		Use file
		If $$$IsUnicode {
			// On Unicode systems, output the text in UTF-8.
			// On 8-bit systems, use the default file translate table.
			$$$SETIO("UTF8")
		}
		
		Set index=""
		For {
			Set index=$order(^ISCLOG("Data",index),1,list)
			If index="" Quit
			
			Write "**",$listget(list,2),"-",$listget(list,1)," "
			If 'testMode {
				Write $listget(list,6)," ns=",$listget(list,5)
			}
			Write " routine=",$listget(list,7)
			If 'testMode {
				Set job=$listget(list,4)
				If job'="" Write " job=",job
			}
			Set tag=$listget(list,8)
			If tag'="" Write " tag=",tag
			Set sessionid=$listget(list,9)
			If sessionid'="" Write " sessionid=",sessionid
			Write !,$listget(list,3),!
			If $data(^ISCLOG("Data",index,0))=1 {
				Write ^ISCLOG("Data",index,0),!
			} ElseIf $data(^ISCLOG("Data",index,0))>=10 {
				Kill data
				Merge data=^ISCLOG("Data",index,0)
				Zwrite data
			}
			Write !
		}
		
	} Catch ex {
		Set error="Error during logging: "_ex.DisplayString()
	}
	
	If open Close file
	If io'="" Use io

	If error'="" {
		Write !,"LOGGING ERROR: "_error,!
	}

	Quit
}

/// Needed for internal code generators.
ClassMethod GetJSONvalue(prop As %String, type As %String) As %String [ Internal ]
{
	If type="%Library.Boolean" {
		Set getval="$select("_prop_":""true"",1:""false"")"
	} ElseIf type="%Library.Integer" {
		Set getval=prop
	} ElseIf type="%OAuth2.JSONString" {
		Set getval=prop
	} Else {
		Set getval="""""""""_$zconvert("_prop_",""O"",""JSON"")_"""""""""
	}

	Quit getval
}

/// Get the response object
/// Called by OAuth2.Response and %SYS.OAuth2.AccessToken
ClassMethod GetJSONResponse(httpRequest As %Net.HttpRequest, Output json As %DynamicObject, Output error As %OAuth2.Error) As %Status [ Final, Internal ]
{
	Try {
		Set sc=$$$OK
		Set error=""
		$$$SysLog(3,"OAuth2","[%OAuth2.Utils:GetJSONResponse]","")
		Set httpResponse=httpRequest.HttpResponse
		If $$$SysLogLevel>=3 {
			Do ##class(%OAuth2.Utils).LogHTTPResponse("[%OAuth2.Utils:GetJSONResponse]",0,httpRequest)
		}

		// Response must be JSON
		Set contentType=httpResponse.ContentType
		// Allow content-type of text/javascript since this is used by dropbox and possibily others. 
		If $case($zconvert($zstrip($piece(contentType,";"),">W"),"l"),"application/json":0,"text/javascript":0,:1) {
			Set sc=$$$ERROR($$$OAuth2ResponseContentType,contentType)
			Quit
		}

		// Get response as string
		If $isobject(httpResponse.Data) {
			Do httpResponse.Data.Rewind()
			If httpResponse.Data.Size>$$$MaxLocalLength {
				Set sc=$$$ERROR($$$OAuth2ResponseBody,"Body is larger than max local string length. Body size="_httpResponse.Data.Size)
				Quit
			}
			Set body=httpResponse.Data.Read($$$MaxLocalLength)
		} Else {
			Set body=httpResponse.Data
		}

		$$$SysLog(3,"OAuth2","[%OAuth2.Utils:GetJSONResponse]","StatusCode="_httpRequest.HttpResponse.StatusCode_", contentType="_contentType_", body="_body)
		
		// Handle success and error cases
		Set statusCode=httpRequest.HttpResponse.StatusCode
		If $case(statusCode,200:1,400:1,500:1,:0) {
			// Parse JSON string into an object
			Set json=##class(%DynamicAbstractObject).%FromJSON(body)
		
			If json.error'="" {
				// handle error
				Set error=##class(%OAuth2.Error).%New(json.error,json."error_description",json."error_uri")
				Set sc=$$$ERROR($$$OAuth2ResponseError,error.AsString())
			} ElseIf statusCode'=200 {
				Set errorText="status="_httpRequest.HttpResponse.StatusCode_", body="_body
				Set sc=$$$ERROR($$$OAuth2ResponseBody,"Unexpected response: "_errorText)
			}
		} Else {
			Set errorText="status="_httpRequest.HttpResponse.StatusCode_", body="_body
			Set sc=$$$ERROR($$$OAuth2ResponseBody,"Unexpected response: "_errorText)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%OAuth2.Utils:GetJSONResponse]",0,sc)
	Quit sc
}

}
