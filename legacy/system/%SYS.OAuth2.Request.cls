/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SYS.OAuth2.Request creates and manages the request JWT needed  to support the request and
/// request_uri parameters that are defined in section 6 of OpenID Connect Core document.
Class %SYS.OAuth2.Request Extends %Persistent [ System = 4 ]
{

/// The IDKEY for the request object class.
Index RequestIndex On (ApplicationName, RequestName) [ IdKey, Unique ];

/// The name of the client application associated with this request.
Property ApplicationName As %String(MAXLEN = 128) [ Required ];

/// The name of this request object.
Property RequestName As %String [ Required ];

/// The base64 encoded random state associated with the request.
/// The state is included as a fragment of in the URL in order to ensure cached requests are retrieved.
Property State As %String(MAXLEN = 1024);

/// The JWT created from the request object.
Property JWT As %String(MAXLEN = "");

/// The time when the request object was last updated.
Property UpdateTime As %Integer;

/// Create and return a JWT based on the specified properties.<br>
/// The JWT may be signed or encoded by the client configuration that is specified by applicationName.<br>
/// To add a request parameter which is a JSON object, you must create a properties element which is a %DynamicObject.
/// For example the claims parameter that is defined by OpenID Connect.
ClassMethod MakeRequestJWT(applicationName As %String, ByRef properties As %String, Output sc As %Status) As %String
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		Set JWT=""
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Request:MakeRequestJWT]","applicationName="_applicationName)

		// Get request object.
		Set requestObject=##class(%DynamicObject).%New()
		
		// Add user supplied properties
		Set name=""
		For {
			Set name=$order(properties(name),1,value)
			If name="" Quit
			
			// Add the property value.
			Do requestObject.%Set(name,value)
		}

		If $$$SysLogLevel>=3 {
			Do ##class(%OAuth2.Utils).LogJSON("[%SYS.OAuth2.Request:MakeRequestJWT]",0,"Request Object",requestObject)
		}

		// Get client configuration		
		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		
		Set sigalg=client.Metadata."request_object_signing_alg"
		If sigalg="none" Set sigalg=""
		Set encalg=client.Metadata."request_object_encryption_enc"
		If encalg="none" Set encalg=""
		Set keyalg=client.Metadata."request_object_encryption_alg"
		If keyalg="none" Set keyalg=""

		// Setup JWT signing parameters.
		Set sigJOSE = ""
		Set encJOSE = ""
		If sigalg'="" {
			Set sigJOSE = {"alg":(sigalg)}
			$$$SysLog(3,"OAuth2Server","[%SYS.OAuth2.Request:MakeRequestJWT]","Signing alg="_sigJOSE.%ToJSON())
			
			// Signed JWT must include iss and aud claims
			If 'requestObject.%IsDefined("iss") {
				Set requestObject.iss=client.ClientId
			}
			Do ..SetAudClaim(requestObject,client.ServerDefinition.IssuerEndpoint)
		}
		
		// Setup JWT encryption parameters.
		If (encalg'="") || (keyalg'="") {
			Set encJOSE = {"alg":(keyalg), "enc":(encalg)}
			If keyalg="dir" {
				Set encJOSE.kid=encalg
			}
			$$$SysLog(3,"OAuth2Server","[%SYS.OAuth2.Request:MakeRequestJWT]","Encryption alg="_encJOSE.%ToJSON())
		}
		
		// Create JWT
		Do client.RefreshJWKS(,,.sc)
		If $$$ISOK(sc) {
			Set sigJWKS = $select(##class(%Net.JSON.JWA).IsAlgSymmetric(sigalg):client.SymmetricJWKS, 1:client.PrivateJWKS)
			Set encJWKS = $select(##class(%Net.JSON.JWA).IsAlgSymmetric(keyalg):client.SymmetricJWKS, 1:client.ServerDefinition.PublicJWKS)

			Set sc = ##class(%Net.JSON.JWT).Create(sigJOSE, encJOSE, requestObject, sigJWKS, encJWKS, .JWT)
		}
		$$$SysLog(3,"OAuth2Server","[%SYS.OAuth2.Request:MakeRequestJWT]","JWT="_$get(JWT))
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Request:MakeRequestJWT]",0,sc)
	
	Quit JWT
}

/// Set the aud claim for the JSON object
ClassMethod SetAudClaim(json As %DynamicObject, issuer As %String) [ Internal, Private ]
{
	Set audList=json.aud
	// If aud property is specified as a JSON string, we must convert it to a dyanmic object.
	If '$isobject(audList) {
		Try {
			Set audList=##class(%DynamicAbstractObject).%FromJSON(audList)
		} Catch {
		}
	}
	
	If $isobject(audList) {
		Set array=##class(%DynamicArray).%New()
		Set found=0
		Set iterator=audList.%GetIterator()
		While iterator.%GetNext(.key,.value) {
			Set aud=audList.%Get(key)
			if aud=issuer Set found=1
			Do array.%Set(key,aud,"string")
		}
		if 'found Do array.%Push(issuer)
		Do json.%Set("aud",array)
	} ElseIf audList="" {
		Do json.%Set("aud",issuer,"string")
	} ElseIf audList=issuer {
		Do json.%Set("aud",issuer,"string")
	} Else {
		Set array=##class(%DynamicArray).%New()
		Do array.%Set(0,audList,"string")
		Do array.%Set(1,issuer,"string")
		Do json.%Set("aud",array)
	}
}

/// Create or update a persistent %SYS.OAuth2.Request object which contains a
/// JWT based on the specified properties.  The new request object is both saved and returned by this method.<br>
/// The JWT may be signed or encoded by the client configuration that is specified by applicationName.<br>
/// To add a request parameter which is a JSON object, you must create a properties element which is a %DynamicObject.
/// For example the claims parameter that is defined by OpenID Connect.
ClassMethod UpdateRequestObject(applicationName As %String, requestName As %String, ByRef properties As %String, Output sc As %Status) As %SYS.OAuth2.Request
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Request:UpdateRequestObject]","applicationName="_applicationName_", requestName="_requestName)

		// Get persistent request object.
		Set requestObject=..OpenRequestObject(applicationName,requestName,.sc)
		If $$$ISERR(sc) Quit
		
		// If object doesn't exists then create a new one.
		If '$isobject(requestObject) {
			Set requestObject=..%New()
			Set requestObject.ApplicationName=applicationName
			Set requestObject.RequestName=requestName
		}
		
		// Add the new JWT and state
		Set requestObject.JWT=..MakeRequestJWT(applicationName,.properties,.sc)
		If $$$ISERR(sc) Quit
		Set requestObject.State=##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.SHAHash(256,requestObject.JWT))
		Set requestObject.UpdateTime=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,0)
		
		// Save the request object
		Set sc=requestObject.%Save()
	
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Request:UpdateRequestObject]",0,sc)
		Set requestObject=""
	}
	
	Quit requestObject
}

/// Open a persistent %SYS.OAuth2.Request object which contains a JWT identified by applicationName and requestName.
ClassMethod OpenRequestObject(applicationName As %String, requestName As %String, Output sc As %Status) As %SYS.OAuth2.Request
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Request:OpenRequestObject]","applicationName="_applicationName_", requestName="_requestName)

		// Get persistent request object.
		Set requestObject=..RequestIndexOpen(applicationName,requestName,,.sc)
		If $$$GETERRORCODE(sc)=$$$ERRORCODE($$$LoadObjectNotFound) {
			Set sc=$$$OK
			Set requestObject=""
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Request:OpenRequestObject]",0,sc)
	
	Quit requestObject
}

/// Delete the request object that is specified by applicationName and requestName.
ClassMethod DeleteRequestObject(applicationName As %String, requestName As %String) As %Status
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Request:DeleteRequestObject]","applicationName="_applicationName_", requestName="_requestName)

		// Get persistent request object.
		Set requestObject=..OpenRequestObject(applicationName,requestName,.sc)
		If $isobject(requestObject) {
			Set sc=requestObject.%Delete(requestObject."%%OID")
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Request:DeleteRequestObject]",0,sc)
	
	Quit sc
}

/// Clean up the request object list by deleting any request object that has not been updated
/// for the specified client in interval seconds
ClassMethod CleanupRequestObjects(applicationName As %String, interval As %Integer) As %Status
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Request:CleanupRequestObjects]","applicationName="_applicationName_", interval="_interval)

		Set cutoff=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,-interval)
		&sql(
			DELETE FROM %SYS_OAuth2.Request
			WHERE UpdateTime<:cutoff
		)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Request:CleanupRequestObjects]",0,sc)
	
	Quit sc
}

/// Get the JWT associated with this request object
Method GetJWT() As %String [ CodeMode = expression ]
{
..JWT
}

/// Get the URL associated with this persistent request object.
Method GetURL(Output sc As %Status) As %String
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Request:GetURL]","applicationName="_..ApplicationName_", requestName="_..RequestName)

		// Get client configuration		
		Set client=##class(OAuth2.Client).Open(..ApplicationName,.sc)

		// Create the url
		If $$$ISOK(sc) {		
			Set url=##class(OAuth2.Response).GetRedirectURL(client,.sc)
			Set url=$replace(url,"/OAuth2.Response.cls","/OAuth2.JWTServer.cls")
			Set url=url_"?request="_##class(%CSP.Page).EscapeURL(..ApplicationName_"||"_..RequestName,"UTF8")_"#"_..State
		}
	
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Request:GetURL]",0,sc)
	$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Request:GetURL]","url="_url)
	
	Quit url
}

Storage Default
{
<Data name="RequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ApplicationName</Value>
</Value>
<Value name="3">
<Value>RequestName</Value>
</Value>
<Value name="4">
<Value>State</Value>
</Value>
<Value name="5">
<Value>JWT</Value>
</Value>
<Value name="6">
<Value>UpdateTime</Value>
</Value>
</Data>
<DataLocation>^%SYS.OAuth2.RequestD</DataLocation>
<DefaultData>RequestDefaultData</DefaultData>
<IdLocation>^%SYS.OAuth2.RequestD</IdLocation>
<IndexLocation>^%SYS.OAuth2.RequestI</IndexLocation>
<StreamLocation>^%SYS.OAuth2.RequestS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
