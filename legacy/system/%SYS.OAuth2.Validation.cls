/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %SYS.OAuth2.Validation class defines the methods used to validate an access token or ID token.
Class %SYS.OAuth2.Validation Extends %RegisteredObject [ System = 4 ]
{

/// ValidateJWT validates the given JWT token and creates an object to reflect the JWT properties. <br>
/// This method will accept both signed and unsigned tokens. Applications that require tokens to be signed should
/// inspect <b>securityParameters("sigalg")</b>. If this value is undefined, then the given token was not signed. <br>
/// <ul>
/// <li><b>applicationName</b> - the name of the client or resource server configuration which
/// contains authorization server access data, such as authorization server ServerCredentials.</li>
/// <li><b>scope</b> - a blank separated list of scope values.  If <b>scope</b> is specified,
/// the JWT must contain a scope claim which is a superset of the this parameter.</li>
/// <li><b>aud</b> - the audience which is using the token.  If the token has an associated aud property
/// (usually because the audience was specified when requesting the token), then <b>aud</b> is matched to
/// the token audience.  If <b>aud</b> is not specified, then no audience checking takes place.</li>
/// <li><b>jsonObject</b> - a JSON Object containing the claims in the JWT.</li>
/// <li><b>securityParameters</b> - an array of strings indicating the signature and/or encryption operations to be performed on the JWT.<br>
/// <br>
/// For JSON Web Signature (JWS):<br>
/// <ul><li><b>securityParameters("sigalg")</b> - Signature or MAC algorithm. This will only be set if the JWT is signed.</li></ul>
/// <br>
/// For JSON Web Encryption (JWE):<br><ul>
/// <li><b>securityParameters("keyalg")</b> - Key management algorithm.</li>
/// <li><b>securityParameters("encalg")</b> - Content encryption algorithm.</li></ul><br>
/// Note, <b>securityParameters("keyalg")</b> and <b>securityParameters("encalg")</b> must both be specified or null.<br>
/// See <Class>%Net.JSON.JWA</Class> for the list of supported algorithms.</li>
/// <li><b>headerObject</b> - a JSON Object containing the JWT Header fields.
/// </li></ul>
ClassMethod ValidateJWT(applicationName As %String, accessToken As %String, scope As %String, aud As %String, Output jsonObject As %DynamicObject, Output securityParameters As %String, Output sc As %Status, Output headerObject As %DynamicObject) As %Boolean
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Set isValid=0
	Set err=""
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Validation:ValidateJWT]","accessToken="_accessToken_", scope="_$get(scope)_", aud="_$get(aud))

		// Find the client
		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit

		// Convert JWT to an object		
		Set sc=..JWTToObject(client,accessToken,.securityParameters,.jsonObject,.headerObject)
		If $$$ISERR(sc) Quit

		// Validate the audience.
		If $get(aud)'="",'##class(OAuth2.Server.OpenID).VerifyAudience(jsonObject.aud,aud,client.ClientId) {
			Set err="Access token is not valid for this audience"
			Quit
		}
		
		// Validate that the access token has not expired
		Set now=##class(%OAuth2.Utils).TimeInSeconds($ztimestamp,0)
		If jsonObject.exp'="",jsonObject.exp<now {
			Set err="Access token has expired"
			Quit
		}

		// Validate the issuer if specified
		If jsonObject.iss'="",jsonObject.iss'=client.ServerDefinition.IssuerEndpoint {
			Set err="Access token has invalid issuer"
			Quit
		}
		
		// Check scope
		If $get(scope)'="" {
			Set token=##class(OAuth2.AccessToken).Open(accessToken,.sc)
			If $$$ISERR(sc) Quit
			If $isobject(token) {
				Set error=##class(%OAuth2.Utils).CheckScope(token.Scope,scope)
				If error'="" {
					Set err="Invalid scope"
					Quit
				}
			} Else {
				Set err="Scope check may only be done on requesting client."
				Quit
			}
		}
		
		Set isValid=1
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISOK(sc),err'="" {
		Set sc=$$$ERROR($$$OAuth2JWTNotValid,err)
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Validation:ValidateJWT]",0,sc)
	
	Quit isValid
}

/// ValidateIDToken validates the signed OpenID Connect ID token and creates an object to reflect the JWT properties. <br>
/// ValidateIDToken also validates the access token based on the at_hash property of the IDToken. <br>
/// <ul>
/// <li><b>applicationName</b> - the name of the client or resource server configuration which
/// contains authorization server access data, such as authorization server ServerCredentials.</li>
/// <li><b>scope</b> - a blank separated list of scope values.  If <b>scope</b> is specified,
/// the JWT must contain a scope claim which is a superset of the this parameter.</li>
/// <li><b>aud</b> - the audience which is using the token.  If the token has an associated aud property
/// (usually because the audience was specified when requesting the token), then <b>aud</b> is matched to
/// the token audience.  If <b>aud</b> is not specified, then no audience checking takes place.</li>
/// <li><b>jsonObject</b> - a JSON Object containing the claims in the JWT.</li>
/// <li><b>securityParameters</b> - an array of strings indicating the signature and/or encryption operations to be performed on the ID Token.<br>
/// <br>
/// For JSON Web Signature (JWS):<br>
/// <ul><li><b>securityParameters("sigalg")</b> - Signature or MAC algorithm.</li></ul>
/// <br>
/// For JSON Web Encryption (JWE):<br><ul>
/// <li><b>securityParameters("keyalg")</b> - Key management algorithm.</li>
/// <li><b>securityParameters("encalg")</b> - Content encryption algorithm.</li></ul><br>
/// Note, <b>securityParameters("keyalg")</b> and <b>securityParameters("encalg")</b> must both be specified or null.<br>
/// See <Class>%Net.JSON.JWA</Class> for the list of supported algorithms.
/// </li></ul>
ClassMethod ValidateIDToken(applicationName As %String, IDToken As %String, accessToken As %String, scope As %String, aud As %String, Output jsonObject As %RegisteredObject, Output securityParameters As %String, Output sc As %Status) As %Boolean
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	New $namespace
	Set $namespace="%SYS"
	
	Quit ##class(OAuth2.Server.OpenID).Validate(applicationName,IDToken,.accessToken,.scope,.aud,.jsonObject,.securityParameters,.sc)
}

/// Wrapper function to setup JWTToObject calls on client.
ClassMethod JWTToObject(client As OAuth2.Client, token As %String, ByRef securityParameters As %String, Output jsonObject As %DynamicObject, Output headerObject As %DynamicObject) As %Status [ Internal ]
{
	Set updated = client.RefreshJWKS(,,.sc)
	If $$$ISERR(sc) {
		Return sc
	}

	Set sigJWKS = "["_client.ServerDefinition.PublicJWKS_","_client.SymmetricJWKS_"]"
	Set encJWKS = "["_client.PrivateJWKS_","_client.SymmetricJWKS_"]"
	Set sc = ##class(%Net.JSON.JWT).Validate(token, sigJWKS, encJWKS, 0,.jsonObject, .operations)
	Do ##class(%OAuth2.Utils).GetSecurityParams(operations,.securityParameters)
	
	// If error verifying the asymmetric signature, then get a new JWKS if available and retry
	If $$$ISERR(sc) && ('updated) && (##class(%Net.JSON.JWA).IsAlgAsymmetric($get(securityParameters("sigalg")))) {
		If client.RefreshJWKS(1,,.sc1) {
			// If we have saved a new JWKS, then retry signature verification.
			Set sc = ##class(%Net.JSON.JWT).Validate(token, client.ServerDefinition.PublicJWKS, encJWKS, ,.jsonObject, .operations)
			Do ##class(%OAuth2.Utils).GetSecurityParams(operations,.securityParameters)
		} Else {
			Set sc=$system.Status.AppendStatus(sc,sc1)
		}
	}

	// return the innermost header
	If $isobject(operations) && (operations.%Size()>0) { 
		Set headerObject = operations.%Get(operations.%Size()-1).header
	}
	
	Return sc
}

}
