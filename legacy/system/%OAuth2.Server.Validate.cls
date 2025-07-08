/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %OAuth2.Server.Validate class is the default ValidateUserClass which is included with the server.
/// The default class will use the user database of the InterSystems IRIS instance where the authorization server
/// is located to validate the user.  The supported properties will be
/// issuer (Issuer), roles and sub (Username).<br>
/// The ValidateUserClass is specified in the Authorization Server Configuration.
/// It must contain a ValidateUser method which will validate a username/password combination
/// and return a set of properties associated with this user.
Class %OAuth2.Server.Validate Extends %RegisteredObject [ System = 4 ]
{

/// Your custom ValidateDelegatedAuthentication method must return true only if 
/// the delegated authentication event initiated by the DelegatedAuthentication method
/// in the Authenticate class is valid. It must return false in other cases. <p>
/// The properties.CustomProperties array may be used to pass values between the
/// DelegatedAuthentication method and this one.
ClassMethod ValidateDelegatedAuthentication(properties As %OAuth2.Server.Properties, Output username As %String, Output sc As %Status) As %Boolean
{
	Set isValid=0
	Set username=""
	Set sc=$$$OK
	Quit isValid
}

/// Your custom ValidateUser method must return true (1) only if the username and password refer to a valid user
/// based on whatever criteria you choose to implement.  It must return false in other cases. <p>
/// If password="", then the user is already logged into an existing session and the password
/// does not need to be validated.<p>
/// In addition, this method receives the properties array and can further modify it;
/// this correspond to the Properties property of %OAuth2.Server.Token. 
/// The authorization server will always add the "iss" (URL of authorization server),
/// "sub" (client_id), and "exp" (expiration time in seconds since December 31st, 1840)
/// to ClaimValues and "client_id" (client_id of the requesting client) to CusotmProperties 
/// after return from ValidateUser if they have not already been added.<p>
/// This sample ValidateUser method validates the user based on the users for this instance.
/// Set the use2fa output parameter to 1 (true) to indicate two factor authentication should be used. In this case
/// the authenticate page will ask the user to enter a security code, which will be validated by <Method>Validate2FA</Method>. 
ClassMethod ValidateUser(username As %String, password As %String, scope As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties, Output sc As %Status, Output use2fa As %Boolean = 0) As %Boolean
{
	// Check if user is defined.
	// We use local Cache user list as the shipped default.
	If '##class(Security.Users).Exists(username,.user,.sc) || $$$ISERR(sc) {
		If $$$ISERR(sc),$$$GETERRORCODE(sc)=$$$ERRORCODE($$$UserDoesNotExist) {
			Set sc=$$$OK
		}
		Quit 0
	}
	
	// Check the password
	If password'="",'##class(Security.Users).CheckPassword(user,password) {
		Quit 0
	}
	
	// Get the properties associated with this user.
	Set sc=##class(Security.Users).GetProperties(user,.prop)
	If $$$ISERR(sc) Quit 0

	// Use the Cache roles for the user to setup a custom property.
	Set sc=##class(Security.Roles).RecurseRoleSet(prop("Roles"),.roles)
	If $$$ISERR(sc) Quit 0
	set roles=prop("Roles")
	Do properties.CustomProperties.SetAt(roles,"roles")

	// Setup claims for profile and email OpenID Connect scopes.
	Do properties.SetClaimValue("sub",username)
	Do properties.SetClaimValue("preferred_username",username)
	If $get(prop("EmailAddress"))'="" {
		Do properties.SetClaimValue("email",prop("EmailAddress"))
		Do properties.SetClaimValue("email_verified",0,"boolean")
	}
	If $get(prop("FullName"))'="" {
		Do properties.SetClaimValue("name",prop("FullName"))
	}
	If $get(prop("PhoneNumber"))'="" {
		Do properties.SetClaimValue("phone_number",prop("PhoneNumber"))
		Do properties.SetClaimValue("phone_number_verified",0,"boolean")
	}
	
	// Setup claim for when user last updated.
	If $get(prop("LastModifiedDateTime"))'="" {
		Set time=##class(%OAuth2.Utils).TimeInSeconds(prop("LastModifiedDateTime"),0)
		Do properties.SetClaimValue("updated_at",time,"number")
	}
	Quit 1
}

/// The ValidateClient method returns true (1), if the client_id and client_secret refer to a
/// client computer which may use the client credentials grant type based on whatever criteria
/// the method chooses to implement.  This client will already have been verified to be registered 
/// to this authorization server and thus will usually be accepted.
/// ValidateClient populates the properties array argument with any properties needed to generate the access token.
/// This correspond to the Properties arguments of OAuth2.Server.Token.
/// The authorization server will always add the "iss" (URL of authorization server),
/// "sub" (client_id), and "exp" (expiration time in seconds since December 31st, 1840)
/// to ClaimValues and "client_id" (client_id of the requesting client) to CusotmProperties 
/// after return from ValidateUser if they have not already been added.<br>
/// If not valid then false is returned.<br>
/// This default ValidateClient accepts all clients and adds no properties.
ClassMethod ValidateClient(clientId As %String, clientSecret As %String, scope As %ArrayOfDataTypes, Output properties As %OAuth2.Server.Properties, Output sc As %Status) As %Boolean
{
	Set sc=$$$OK
	Quit 1
}

/// The SupportedClaims method returns a $list of claims that are supported
/// by this authorization server based on customizations.  The SupportedClaims method is in the
/// ValidateUserClass since this is where additional claims are usually added.
/// The returned list is added to the list of claims defined by OpenID Connect Core and
/// should include JWT, IDToken, userinfo endpoint and introspection endpoint claims.
ClassMethod SupportedClaims() As %List
{
	// This is the list that corresponds to the above code.
	// This list should be adjusted based on the specific customizations of this server.
	Quit $lb("preferred_username","email","email_verified","name","phone_number","phone_number_verified")
}

/// If two factor authentication is enabled for this user, Validate2FA will be called to validate 
/// the security code entered by the user to complete their authentication.
ClassMethod Validate2FA(username As %String, token As %String) As %Boolean
{
	Quit 0
}

}
