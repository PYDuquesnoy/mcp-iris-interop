/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %OAuth2.Server.Authenticate acts as the subclass for all user written Authenticate classes as
/// well as being the default Authenticate class.
/// The Authenticate class is used by Authorization Endpoint at OAuth2.Server.Auth to authenticate
/// the user.  This class allows the customization of the authentication process.<br>
/// The following methods may be implemented to override the default in OAuth2.Server:
/// DirectLogin, DisplayLogin and DisplayPermissions.<br>
/// The scope argument to all of these methods is a %ArrayOfDatatypes where the keys
/// are scope values and the values are the display form of the scope value.<br>
/// <table><tr><th>The CSS style is defined in DrawStyle. </th></tr>
/// <tr><td>loginForm is for DisplayLogin</td></tr>
/// <tr><td>permissionForm is for DisplayPermissions</td></tr>
/// <tr><td>Customer can modify these CSS to tailor desired look and feel.</td></tr>
/// </table>
Class %OAuth2.Server.Authenticate Extends %CSP.Page [ System = 4 ]
{

/// Login page localization domain
Parameter DOMAIN = "%OAuth2Login";

/// The GetLanguageList method returns a comma separated list of the languages that are supported
/// for the message domain used for this class.
/// This language list is returned as the ui_locales server metadata property.
ClassMethod GetLanguageList() As %List
{
	// Get all languages for the domain that we use as a $list
	Set domain=..#DOMAIN
	Quit $$GetLanguages^%occMessages(domain,$select($extract(domain)="%":"+s",1:"-s"))
}

/// The BeforeAuthenticate method of the Authenticate class is called before any authentication takes place
/// to allow the scope or claims associated with the request to be modified based on
/// scope values or request parameters.
ClassMethod BeforeAuthenticate(scope As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties) As %Status
{
	Quit $$$OK
}

/// The AfterAuthenticate method of the Authenticate class is called after any authentication
/// is completed (including if the authentication is cookie based)
/// to allow the scope or properties associated with the request to be modified based on
/// scope values or request parameters.
/// AfterAuthenticate may add properties to the authentication HTTP response,
/// by adding them to properties.ResponseProperties.
ClassMethod AfterAuthenticate(scope As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties) As %Status
{
	Quit $$$OK
}

/// DelegatedAuthentication can be used to redirect the flow of the authorization process to another authentication system, such as an OpenID Connect 
/// Identity Provider. If it is not null, the resource owner will be redirected to <var>delegatedAuthenticationURL</var>. 
/// <var>localRedirectURL</var> is a URL that the delegated authentication service should 
/// redirect to after completion in order to reinsert the user back into the original authorization flow. This method
/// may set values of the properties.CustomProperties array that may be used in the ValidateDelegatedAuthentication method of the Validate class.
ClassMethod DelegatedAuthentication(properties As %OAuth2.Server.Properties, localRedirectURL As %String, Output delegatedAuthenticationURL As %String) As %Status
{
	// no delegated authentication
	Set delegatedAuthenticationURL=""
	Quit $$$OK
}

/// If DirectLogin chooses to do authentication by some means other than display of the user login form,
/// DirectLogin sets the username and password arguments which will later be used
/// to obtain the properties associated with the access token and to generate the token.
/// If username is set to $char(0), then the access_denied error will be returned.<br>
/// This method may directly look at the request properties and set properties
/// for GenerateAccessToken using the properties array argument.
ClassMethod DirectLogin(scope As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties, Output username As %String, Output password As %String) As %Status
{
	// no direct login
	Set username=""
	Set password=""
	Quit $$$OK
}

/// DisplayLogin is responsible for writing out the HTML to display the user login form.
/// The login form must contain a Username field, a Password field and an AuthorizationCode hidden field.
/// The Authorization code hidden field is inserted by DisplayLogin using the InsertHiddenField
/// method of %CSP.Page. The form will normally be submitted using a button named "Login". If it is submitted
/// with a button named "Accept", then the page will skip calling DisplayPermissions to authorize the scopes. 
/// If this done, the page <i>should</i> display the requested scopes prior to submitting. 
/// If the form is submitted using a button named Cancel, then the authorization process will
/// terminate with an error return of access_denied.<br>
/// loginCount is the integer count of which login attempt is taking place.<br>
/// This method may directly look at the request properties and set properties
/// for GenerateAccessToken using the properties array argument. In addition, any submitted
/// values with name beginning with p_ (i.e. the element name begins with p_) will be copied to
/// the properties.CustomProperties array with the p_ prefix removed from the name.
ClassMethod DisplayLogin(authorizationCode As %String, scope As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties, loginCount As %Integer = 1) As %Status
{
	Set uilocales = properties.RequestProperties.GetAt("ui_locales")
	Set tLang = ##class(%OAuth2.Utils).SelectLanguage(uilocales,"%OAuth2Login")
	// $$$TextHTML(Text,Domain,Language)
	Set LOGINHEADTITLE = $$$TextHTML("OAuth2 Login Page","%OAuth2Login",tLang)
	Set LOGINTITLE = $$$TextHTML("Sign in with your Account","%OAuth2Login",tLang)
	Set USERNAMEHOLDER = $$$TextHTML("Username","%OAuth2Login",tLang)
	Set PASSWORDHOLDER = $$$TextHTML("Password","%OAuth2Login",tLang)
	Set LOGINCAPTION = $$$TextHTML("Sign in","%OAuth2Login",tLang)
	Set CANCELCAPTION = $$$TextHTML("Cancel","%OAuth2Login",tLang)
	Set ACCESSDENIEDMSG = $$$TextHTML("Access Denied","%OAuth2Login",tLang)
	Set MSGUSERNAME = $$$TextJS("Please enter Username","%OAuth2Login",tLang)	
	Set MSGPASSWORD = $$$TextJS("Please enter Password","%OAuth2Login",tLang)
	Set MSGUSERNAMEPASSWORD = $$$TextJS("Please enter Username and Password","%OAuth2Login",tLang)

	&html<<html>>
	Do ..DrawLoginHead(LOGINHEADTITLE,MSGUSERNAME,MSGPASSWORD,MSGUSERNAMEPASSWORD)
	&html<<body>>

	&html<<div id="topLabel">#(LOGINTITLE)#</div>>
	&html<<div>>

	&html<<form autocomplete="off" method="post" class="loginForm">>
	Write ##class(%CSP.Page).InsertHiddenField("","AuthorizationCode",authorizationCode),!
	&html<
		<div style="padding-top:30px;"><input type="text" id="Username" name="Username" placeholder="#(USERNAMEHOLDER)#" autofocus autocomplete="off" ></div>
		<div><input type="password" id="Password" name="Password" placeholder="#(PASSWORDHOLDER)#" autocomplete="off" ></div>
		<div><input type="submit" id="btnLogin" name="Login" value="#(LOGINCAPTION)#" onclick="return doLogin();"/></div>
		<div><input type="submit" id="btnCancel" name="Cancel" value="#(CANCELCAPTION)#"/></div>
		>
	If loginCount > 1 {
		&html<<div class="errorCode">#(ACCESSDENIEDMSG)#</div>>
	}

	&html<</form>>
	&html<</div>>

	Do ..DrawFooter()
	&html<</body>>
	&html<<html>>

	Quit 1
}

/// Display2fa is responsible for writing out the HTML to display an HTML form to allow the user to perform 
/// two factor authentication.The form should include a 2FAToken field and an AuthorizationCode hidden field.
/// The Authorization code hidden field is inserted by Display2fa using the InsertHiddenField
/// method of %CSP.Page. The form will normally be submitted using a button named "Login". If it is submitted
/// with a button named "Accept", then the page will skip calling DisplayPermissions to authorize the scopes. 
/// If this done, the page <i>should</i> display the requested scopes prior to submitting. 
/// If the form is submitted using a button named Cancel, then the authorization process will
/// terminate with an error return of access_denied.<br>
/// loginCount is the integer count of which login attempt is taking place.<br>
/// This method may directly look at the request properties and set properties
/// for GenerateAccessToken using the properties array argument.
ClassMethod Display2FA(authorizationCode As %String, scope As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties, loginCount As %Integer = 1) As %Status
{
	Set uilocales = properties.RequestProperties.GetAt("ui_locales")
	Set tLang = ##class(%OAuth2.Utils).SelectLanguage(uilocales,"%OAuth2Login")
	// $$$TextHTML(Text,Domain,Language)
	Set HEADTITLE2FA = $$$TextHTML("OAuth2 Verification Code Page","%OAuth2Login",tLang)
	Set TITLE2FA = $$$TextHTML("Verify Security Code","%OAuth2Login",tLang)
	Set TOKENHOLDER = $$$TextHTML("Verification Code","%OAuth2Login",tLang)
	Set LOGINCAPTION = $$$TextHTML("Sign in","%OAuth2Login",tLang)
	Set CANCELCAPTION = $$$TextHTML("Cancel","%OAuth2Login",tLang)
	Set ACCESSDENIEDMSG = $$$TextHTML("Access Denied","%OAuth2Login",tLang)
	Set MSGTOKEN = $$$TextJS("Please enter Verification Code <img src=x onerror=alert(123) />","%OAuth2Login",tLang)	

	&html<<html>>
	Do ..Draw2FAHead(HEADTITLE2FA,MSGTOKEN)
	&html<<body>>

	&html<<div id="topLabel">#(TITLE2FA)#</div>>
	&html<<div>>

	&html<<form autocomplete="off" method="post" class="loginForm">>
	Write ##class(%CSP.Page).InsertHiddenField("","AuthorizationCode",authorizationCode),!
	&html<
		<div style="padding-top:30px;"><input type="text" id="2FAToken" name="2FAToken" placeholder="#(TOKENHOLDER)#" autofocus autocomplete="off" ></div>
		<div><input type="submit" id="btnLogin" name="Login" value="#(LOGINCAPTION)#" onclick="return doLogin();"/></div>
		<div><input type="submit" id="btnCancel" name="Cancel" value="#(CANCELCAPTION)#"/></div>
		>
	If loginCount > 1 {
		&html<<div class="errorCode">#(ACCESSDENIEDMSG)#</div>>
	}

	&html<</form>>
	&html<</div>>

	Do ..DrawFooter()
	&html<</body>>
	&html<<html>>

	Quit 1
}

/// DisplayPermissions is responsible for writing out the HTML to display the user accept permissions form.<br>
/// The accept permissions form should display the already obtained scopes in display format based on currentScopeArray.<br>
/// The accept permissions form should display the requested scopes in display format based on scopeArray.<br>
/// The Authorization code hidden field is inserted by DisplayPermissions
/// using the InsertHiddenField method of %CSP.Page.
/// The form should be submitted using a button named "Accept".
/// If the form is submitted using a button named Cancel,
/// then the authorization process will terminate with an error return of access_denied.<br>
/// This method may directly look at the request properties and set properties
/// for GenerateAccessToken using the properties array argument. In addition, any submitted
/// values with name beginning with p_ (i.e. the element name begins with p_) will be copied to
/// the properties.CustomProperties array with the p_ prefix removed from the name.
ClassMethod DisplayPermissions(authorizationCode As %String, scopeArray As %ArrayOfDataTypes, currentScopeArray As %ArrayOfDataTypes, properties As %OAuth2.Server.Properties) As %Status
{
	Set uilocales = properties.RequestProperties.GetAt("ui_locales")
	Set tLang = ##class(%OAuth2.Utils).SelectLanguage(uilocales,"%OAuth2Login")
	// $$$TextHTML(Text,Domain,Language)
	Set ACCEPTHEADTITLE = $$$TextHTML("OAuth2 Permissions Page","%OAuth2Login",tLang)
	Set USER = $$$TextHTML("User:","%OAuth2Login",tLang)
	Set POLICY = $$$TextHTML("Policy","%OAuth2Login",tLang)
	Set TERM = $$$TextHTML("Terms of service","%OAuth2Login",tLang)
	Set ACCEPTCAPTION = $$$TextHTML("Accept","%OAuth2Login",tLang)
	Set CANCELCAPTION = $$$TextHTML("Cancel","%OAuth2Login",tLang)
	
	&html<<html>>
	
	Do ..DrawAcceptHead(ACCEPTHEADTITLE)
	Set divClass = "permissionForm"
	Set logo = ##class(%CSP.Page).EscapeHTML(properties.ServerProperties.GetAt("logo_uri"))
	Set clientName = properties.ServerProperties.GetAt("client_name")
	Set clienturi = ##class(%CSP.Page).EscapeHTML(properties.ServerProperties.GetAt("client_uri"))
	Set policyuri = ##class(%CSP.Page).EscapeHTML(properties.ServerProperties.GetAt("policy_uri"))
	Set tosuri = ##class(%CSP.Page).EscapeHTML(properties.ServerProperties.GetAt("tos_uri"))
	Set user = properties.GetClaimValue("preferred_username")
	If user="" {
		Set user = properties.GetClaimValue("sub")
	}

	&html<<body>>
	&html<<div id="topLabel"></div>>
	&html<<div class="#(divClass)#">>
	If user '= "" {
		&html<
			<div>
			<span id="left" class="userBox">#(USER)#<br>#(##class(%CSP.Page).EscapeHTML(user))#</span>
			>
	}
	If logo '= "" {
		Set espClientName = ##class(%CSP.Page).EscapeHTML(clientName)
		&html<<span class="logoClass"><img src="#(logo)#" alt="#(espClientName)#" title="#(espClientName)#" align="middle"></span>>
	}
	If policyuri '= "" ! (tosuri '= "") {
		&html<<span id="right" class="linkBox">>
		If policyuri '= "" {
			&html<<a href="#(policyuri)#" target="_blank">#(POLICY)#</a><br>>
		}
		If tosuri '= "" {
			&html<<a href="#(tosuri)#" target="_blank">#(TERM)#</a>>
		}
		&html<</span>>
	}
	&html<</div>>
	&html<<form>>
	Write ##class(%CSP.Page).InsertHiddenField("","AuthorizationCode",authorizationCode),!
	&html<<div>>
	If $isobject(scopeArray), scopeArray.Count() > 0 {
		Set tTitle = $$$FormatText($$$Text("'%1' is requesting these permissions:","%OAuth2Login",tLang),clientName)
		&html<<div class="permissionTitleRequest">>
		If clienturi '= "" {
			&html<<a href="#(clienturi)#" target="_blank">#(##class(%CSP.Page).EscapeHTML(tTitle))#</a>>
		} Else {
			&html<#(##class(%CSP.Page).EscapeHTML(tTitle))#>
		}
		&html<</div>>
	
		Set tCount = 0
		Set scope = ""
		For {
			Set display = scopeArray.GetNext(.scope)
			If scope = "" Quit
			Set tCount = tCount + 1
			If display = "" Set display = scope
			Write "<div class='permissionItemRequest'>"_tCount_". "_##class(%CSP.Page).EscapeHTML(display)_"</div>"
		}
	}
	
	If $isobject(currentScopeArray), currentScopeArray.Count() > 0 {
		Set tTitle = $$$FormatText($$$Text("'%1' already has these permissions:","%OAuth2Login",tLang),clientName)
		&html<<div>>
		&html<<div class="permissionTitleExisting">>
		If clienturi '= "" {
			&html<<a href="#(clienturi)#" target="_blank">#(##class(%CSP.Page).EscapeHTML(tTitle))#</a>>
		} Else {
			&html<#(##class(%CSP.Page).EscapeHTML(tTitle))#>
		}
		&html<</div>>
		Set tCount = 0
		Set scope = ""
		For {
			Set display = currentScopeArray.GetNext(.scope)
			If scope = "" Quit
			Set tCount = tCount + 1
			If display = "" Set display = scope
			Write "<div class='permissionItemExisting'>"_tCount_". "_##class(%CSP.Page).EscapeHTML(display)_"</div>"
		}
		&html<</div>>
	}
	&html<</div>>
	&html<
		<div><input type="submit" id="btnAccept" name="Accept" value="#(ACCEPTCAPTION)#" autofocus/></div>
		<div><input type="submit" id="btnCancel" name="Cancel" value="#(CANCELCAPTION)#"/></div>
		>
	&html<</form>
	</div>>

	Do ..DrawFooter()
	&html<</body>>
	&html<<html>>

	Quit 1
}

ClassMethod DrawLoginHead(LOGINHEADTITLE, MSGUSERNAME, MSGPASSWORD, MSGUSERNAMEPASSWORD)
{
	&html<<head><title>#(LOGINHEADTITLE)#</title>>
	Do ..DrawStyle()
	&html<
	<script type="text/javascript">
	function doLogin()
	{
		var username = document.getElementById("Username").value;
		var password = document.getElementById("Password").value;
		var errors = "";
		if (username.length < 1) {
			errors = '#(MSGUSERNAME)#';
		}
		if (password.length < 1) {
			if (errors === "") {
				errors = '#(MSGPASSWORD)#';
			} else {
				errors = '#(MSGUSERNAMEPASSWORD)#';
			}
		}
		if (errors) {
			alert(errors);
			return false;
		}
		
		// submit the form
		return true;
	}
	</script>
	>
	&html<</head>>
}

ClassMethod Draw2FAHead(TITLE2FA, MSGTOKEN)
{
	&html<<head><title>#(TITLE2FA)#</title>>
	Do ..DrawStyle()
	&html<
	<script type="text/javascript">
	function doLogin()
	{
		var token = document.getElementById("2FAToken").value;
		var errors = "";
		if (token.length < 1) {
			errors = '#(MSGTOKEN)#';
		}
		if (errors) {
			alert(errors);
			return false;
		}
		
		// submit the form
		return true;
	}
	</script>
	>
	&html<</head>>
}

ClassMethod DrawStyle()
{
	&html<
	<style type="text/css">

	/* begin generic styles */
	body {
		font-family: Helvetica, sans-serif;
		text-align: center;
	}
	input[type=submit]:hover {
		cursor: hand;	
	}
	.errorCode {
		color: #da4848;	
	}
	/* end generic styles */
	
	/* begin form style */
	 #topLabel {
		font-weight: bold;
		margin-top: 5%;
		padding: 10px;
	}
	.loginForm,
	.permissionForm {
		background: #F9F9F9;
		border: 1px solid #C2C2C2;
		border-radius: 5px;
		margin-top: 10px;
		width: 30%;
		min-width: 500px;
		margin: 0 auto;
	}
	.loginForm *,
	.permissionForm * {
		padding: 10px;
	}
	.loginForm input,
	.permissionForm input {
		width: 200px;	
	}
	.loginForm input[type=submit],
	.permissionForm input[type=submit] {
		width: 100px;	
	}
	.loginForm input[type=submit]:hover,
	.permissionForm input[type=submit]:hover {
		border-radius: 5px;
		background: #A6CFEC;		
	    transition: all .15s ease-in-out;
	}	
	.permissionForm h1 {
	    line-height: 40px;
	    font-size: 22px;
	    font-weight: normal;	
	}
	.permissionTitleRequest, .permissionTitleExisting {
		background: lightgray;
		font-weight: 600;
		font-size: 16px;
		margin-top: 10px;
		text-align: left;
	}	
	.permissionItemExisting, .permissionItemRequest {
		border-bottom: 1px solid #9e9e9e;
		text-align: left;	
	}
	.logoClass {
	    margin-top: 22px;
	    margin: 0 auto;
	}
	.userBox {
		font-size: 11px;
		float: left;
		text-align: left;
	}
	.linkBox {
		font-size: 11px;
		float: right;
		text-align: right;
	}
	/* end of form style */
	
	</style>>
}

ClassMethod DrawFooter()
{
	&html<
		
	>
}

ClassMethod DrawAcceptHead(ACCEPTHEADTITLE)
{
	&html<<head><title>#(ACCEPTHEADTITLE)#</title>>
	Do ..DrawStyle()
	&html<</head>>
}

}
