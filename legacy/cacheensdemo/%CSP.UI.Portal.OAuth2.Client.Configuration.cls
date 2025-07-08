/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Edit OAuth 2.0 client configuration
Class %CSP.UI.Portal.OAuth2.Client.Configuration Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "OAuth 2.0 Client Configuration";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Client.Configuration.zen";

Parameter HELPADDRESS = "System Administration,Security,OAuth 2.0,Client Configurations,Client Configuration";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_OAuth2_Client";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

/// ID for edit. Null if adding new configuration.
Property PID As %String(ZENURL = "PID");

Property currIndex As %Integer;

Property NumTabs As %Integer [ InitialExpression = 4 ];

Property buttonCaption As %String [ InitialExpression = "default" ];

Property jwksAvailable As %Boolean;

/// IssuerEndpointID of the Server for client list.
Property IssuerEndpointID As %String(ZENURL = "IssuerEndpointID");

/// IssuerEndpoint of the Server for client list.
Property IssuerEndpoint As %String(ZENURL = "IssuerEndpoint");

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
.fieldSet {
	background: #f5f3f3;
	border: 1px solid #b1b1b3;
	border-radius: 3px;
}
</style>
}

XData SVGStyle
{
<style type="text/css">
.tabBarBackground {
	fill:white;
	stroke:white;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;" controlStyle="white-space:pre-line;"/>

<html id="helpText" OnDrawContent="DrawHelpText"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white;stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":General:Client Information:JWT Settings:Client Credentials"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<!-- Page 1: General -->
<vgroup id="page_1" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;" labelPosition="left">

<form autocomplete="false">

<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<text id="Name" label="Application name" size="40" maxlength="128" hint="Required. Local name of the client application." onchange="zenPage.modified();"/>
<text id="ClientName" label="Client name" size="40" hint="Global name to be used for dynamic registration." onchange="zenPage.modified();"/>
<text id="Description" label="Description" size="60" maxlength="256" onchange="zenPage.modified();"/>
<checkbox id="Enabled" label="Enabled" onchange="zenPage.modified();"/>
<radioSet id="ClientType" label="Client Type" displayList="Confidential,Public,Resource server" valueList="confidential,public,resource" onchange="zenPage.modified();zenPage.changeClientType();"/>
<select id="SSLConfiguration" label="SSL/TLS configuration" hint="Required." onchange="zenPage.modified();"/>
<spacer height="2"/>
<fieldSet id="id_Redirection" label="Client redirect URL" >
<group>
<label id="id_ServerRedirect" value="The client URL to be specified to the authorization server to receive responses." enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<textarea id="redirectURL" readOnly="true" rows="2" cols="80"/>
<checkbox id="UseSSL" label="Use TLS/SSL" onchange="zenPage.getRedirectURL();zenPage.modified();"/>
<hgroup cellStyle="padding-right:5px;">
<text id="addr" label="Host name" hint="Required." onchange="zenPage.getRedirectURL();zenPage.modified();"/>
<text id="port" label="Port" hint="Optional." onchange="zenPage.getRedirectURL();zenPage.modified();"/>
<text id="prefix" label="Prefix" hint="Optional." onchange="zenPage.getRedirectURL();zenPage.modified();"/>
</hgroup>
</group>
</fieldSet>
<spacer height="2"/>
<fieldSet id="FrontChannel" label="Front channel logout" >
<label id="FrontChannelInfo1" value="If the front channel logout URL is empty, the client won't support front channel logout." enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<label id="FrontChannelInfo2" value="'IRISLogout=end' will always be appended to any provided URL." enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<text id="FrontChannelUri" readOnly="true" size="75"/>
<text id="ProvidedFrontChannelUri" label="Front Channel Logout URL" size="60" hint="" onchange="zenPage.getFrontChannelURL();zenPage.modified();"/>
<checkbox id="FrontChannelSessionRequired" label="Require iss and sid query parameters when auth server calls logout URL" captionClass="normal" aux="logout_session_required" onchange="zenPage.modified();"/>
</fieldSet>
<spacer height="2"/>
<vgroup id="GrantTypeList" label="Required grant types (check at least one)" labelPosition="left" >
<checkbox id="GrantType1" caption="Authorization code" captionClass="normal" aux="authorization_code" onchange="zenPage.modified();"/>
<checkbox id="GrantType2" caption="Implicit" captionClass="normal" aux="implicit" onchange="zenPage.modified();"/>
<checkbox id="GrantType3" caption="Resource owner password credentials" captionClass="normal" aux="password" onchange="zenPage.modified();"/>
<checkbox id="GrantType4" caption="Client credentials" captionClass="normal" aux="client_credentials" onchange="zenPage.modified();"/>
<checkbox id="GrantType5" caption="JWT authorization" captionClass="normal" aux="jwt_authorization" onchange="zenPage.modified();zenPage.changeAuthType();"/>
</vgroup>
<radioSet id="AuthenticationType" label="Authentication type" displayList="none,basic,form encoded body,client secret JWT,private key JWT" valueList="none,client_secret_basic,client_secret_post,client_secret_jwt,private_key_jwt" value="basic" onchange="zenPage.modified();zenPage.changeAuthType();"/>
<select id="AuthSigning" label="Authentication signing algorithm" controlStyle="width:16em" showEmpty="false" onchange="zenPage.modified();"/>
<text id="JWTAud" label="Audience" onchange="zenPage.modified();" controlStyle="width:16em"/>
</group>
</form>
</vgroup>

<!-- Page 2: Client Information -->
<vgroup id="page_2" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;">
<form autocomplete="false">

<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">

<spacer height="2"/>
<fieldSet id="id_DisplayURL" label="Authorization display" >
<label id="id_DisplayNote" value="This section contains the information to be displayed when requesting permissions from the end user." enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<text id="LogoUri" label="Logo URL" size="70" hint="" onchange="zenPage.modified();"/>
<text id="ClientUri" label="Client home page URL" size="70" onchange="zenPage.modified();"/>
<text id="PolicyUri" label="Policy URL" size="70" onchange="zenPage.modified();"/>
<text id="TosUri" label="Terms of service URL" size="70" onchange="zenPage.modified();"/>
</fieldSet>
<text id="DefaultScope" label="Default scope" size="60" onchange="zenPage.modified();"/>
<text id="Contacts" label="Contact emails (comma separated)" size="60" hint="" onchange="zenPage.modified();"/>
<text id="DefaultMaxAge" label="Default max age (in seconds)" size="20" hint="" onchange="zenPage.modified();"/>
<spacer height="2"/>
</group>
</form>
</vgroup>

<!-- Page 3: JWT Settings -->
<vgroup id="page_3" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;">
<form autocomplete="false">

<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">

<fieldSet id="groupJWT" label="JSON Web Token (JWT) Settings" >
<checkbox id="chkCreateJWT" caption="Create JWT Settings from X509 credentials" captionClass="zenLabel" onchange="zenPage.modified();zenPage.createJWT(zenThis.value);"/>
<group id="groupCreateJWT" enclosingStyle="padding-left:20px;background:white;">
<select id="ClientCredentials" label="X509 credentials" hint="Required. Select credentials." onchange="zenPage.modified();"/>
<text inputtype="password" id="ClientPassword" label="Private key password" autocomplete="false" onchange="zenPage.modified();"/>
</group>
</fieldSet>

<hgroup>
<text id="TextSigning" value="Signing" controlStyle="width:16em;" disabled="true"/>
<text id="TextEncryption" value="Encryption" controlStyle="width:16em;" disabled="true"/>
<text id="TextKey" value="Key" controlStyle="width:16em;" disabled="true"/>
</hgroup>
<hgroup id="id_IDToken" label="IDToken algorithms">
<select id="IDTokenSigning" controlStyle="width:16em" showEmpty="false" value="RS256" valueList="RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="IDTokenEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="IDTokenKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
<hgroup id="id_Userinfo" label="Userinfo algorithms">
<select id="UserinfoSigning" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="UserinfoEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="UserinfoKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
<hgroup id="id_AccessToken" label="Access token algorithms">
<select id="AccessTokenSigning" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="AccessTokenEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="AccessTokenKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
<hgroup id="id_Request" label="Request algorithms">
<select id="RequestSigning" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="RequestEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="RequestKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
</group>
</form>
</vgroup>

<!-- Page 4: Client Credentials -->
<vgroup id="page_4" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;">
<form autocomplete="false">

<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">

<fieldSet id="id_Client" label="This client's credentials" >
<text id="ClientId" label="Client ID" size="60" hint="Required." onchange="zenPage.modified();"/>
<text id="ClientIdIssuedAt" label="Client ID Issued At" readOnly="true" size="60"/>
<text id="ClientSecret" label="Client secret" size="99" hint="Required if client type is confidential." onchange="zenPage.modified();"/>
<text id="ClientSecretExpiresAt" label="Client Secret Expires At" readOnly="true" size="60"/>
<text id="RegistrationClientUri" label="Registration Client Uri" readOnly="true" size="90"/>
</fieldSet>
</group>
</form>
</vgroup>
</pane>
}

ClientMethod modified() [ Language = javascript ]
{
	this.doModified();
	this.enableCommandButton("btnSave");
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	for (var i=0;i<this.NumTabs;i++) {
		var option = i + 1;
		if (i == index) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}				
	}
	if (!this.pageModified) {
		this.disableCommandButton("btnSave");
	}
	document.location.hash = index;
}

ClientMethod createJWT(checked) [ Language = javascript ]
{
	zen('groupCreateJWT').setHidden(!checked);
	/// if user unchecked clear the credentials that might exist
	if (!checked) {
		zen('ClientCredentials').setValue('');
		zen('ClientPassword').setValue('');
	}
}

/// End Add/Edit and return to list page.
ClientMethod doFinish() [ Language = javascript ]
{
	this.setModified(false);
	var opener = this.getOpener();
	if (opener) {
		self.close();
	} else {
		this.doCancel();
	}
}

/// User changed Type. Show/hide client/server credentials related fields.
ClientMethod changeClientType() [ Language = javascript ]
{
	var Type = zen('ClientType').getValue();
	var isHidden = (Type=="resource") ? true : false;
	zen('UseSSL').setHidden(isHidden);
	zen('addr').setHidden(isHidden);
	zen('port').setHidden(isHidden);
	zen('prefix').setHidden(isHidden);
	zen('id_Redirection').setHidden(isHidden);
	zen('DefaultScope').setHidden(isHidden);
	zen('GrantTypeList').setHidden(isHidden);
	zen('id_DisplayURL').setHidden(isHidden);
	zen('DefaultMaxAge').setHidden(isHidden);
	zen('id_IDToken').setHidden(isHidden);
	zen('id_AccessToken').setHidden(isHidden);
	zen('id_Request').setHidden(isHidden);
}

/// User changed Authentication Type. Show/hide authorization signing algorithm.
ClientMethod changeAuthType() [ Language = javascript ]
{
	var asymAlgs = ',RS256,RS384,RS512,ES256,ES384,ES512';
	var symAlgs = ',HS256,HS384,HS512';
	
	var type = zen('AuthenticationType').getValue();
	var authComp = zen('AuthSigning');
	var audComp = zen('JWTAud');
	var signing = authComp.getValue();
	
	if (type == "client_secret_jwt") {
		authComp.setProperty('valueList',symAlgs);
		if ((signing != '') && (symAlgs.indexOf(signing)<0)) {
			authComp.setValue('');
		}
		authComp.setHidden(false);
		audComp.setHidden(false);
	} else if (type == "private_key_jwt") {
		authComp.setProperty('valueList',asymAlgs);
		if ((signing != '') && (asymAlgs.indexOf(signing)<0)) {
			authComp.setValue('');
		}
		authComp.setHidden(false);
		audComp.setHidden(false);
	} else if (zen('GrantType5').getValue()) { // grant type: jwt_authorization
		authComp.setProperty('valueList',(asymAlgs+symAlgs));
		authComp.setHidden(false);
		audComp.setHidden(false);
	} else {
		authComp.setProperty('valueList','');
		authComp.setValue('');
		authComp.setHidden(true);
		audComp.setHidden(true);
	}
}

/// Rotate keys of JWKS
ClientMethod doRotate() [ Language = javascript ]
{
	try {
		var valueProxy = new zenProxy();
		valueProxy.Name = zenTrim(zen('Name').getValue());
		var proxy = this.Rotate(valueProxy);
		if (proxy.ok == 1) {
			if (proxy.Message != "") {
				this.showMsg(proxy.Message,0);
			}
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}
	} 
 	catch(ex) {
		alert("ERROR: " + ex);
	}
}

/// Get user input and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		var valueProxy = new zenProxy();
		if (!this.doPrepare(valueProxy,false)) {
			return;
		}
		var proxy = this.SaveData(valueProxy);
		if (proxy.ok == 1) {
			if (proxy.Message != "") {
				this.showMsg(proxy.Message,0);
			}
			this.setModified(false);
			this.disableCommandButton("btnSave");
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}
	} 
 	catch(ex) {
		this.showMsg("ERROR: " + ex,1);
	}
}

/// Register this client using OpenID Connect Dynamic Registration.
/// Discovery of the ServerDefinition must already have been done and any client defined properties set.
ClientMethod doRegister() [ Language = javascript ]
{
	try {
		var proxy;

		ClientId = zenTrim(zen("ClientId").getValue());
		
		var valueProxy = new zenProxy();
		if (!this.doPrepare(valueProxy,true)) {
			return;
		}
		
		if (ClientId == '') {
			proxy = this.Register(valueProxy);
			
		} else {
			proxy = this.ReadMetadata(valueProxy);
		}
		
		if (proxy.ok == 1) {
			if (proxy.Message != "") {
				this.showMsg(proxy.Message,0);
			} else {
				this.showMsg($$$Text('Client updated.'),0);
			}
			this.changeAuthType();
			this.setModified(false);
			this.disableCommandButton("btnSave");
			this.enableCommandButton("btnUpdate");
			this.registerButtonHandler();
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}
	} 
 	catch(ex) {
		alert("ERROR: " + ex);
	}
}

/// Hide/show register button based on status
ClientMethod registerButtonHandler() [ Language = javascript ]
{
	if (this.buttonCaption == "") {
		this.hideCommandButton("btnRegister");
	} else {
		var button = document.getElementById("command_btnRegister");
		button.innerHTML = "<nobr>"+this.buttonCaption+"</nobr>";
		this.showCommandButton("btnRegister");
	}
}

/// Get user input and prepare proxy object for save or register.
ClientMethod doPrepare(valueProxy, isRegister) [ Language = javascript ]
{
	try {	
		var PID = this.PID;
		var ClientType = zen("ClientType").getValue();
		var pass = true;
		var fields = '';

		var RequiredGrantTypes = "";
		if (zen("GrantType1").getValue()) RequiredGrantTypes += (zen("GrantType1").aux + ",");
		if (zen("GrantType2").getValue()) RequiredGrantTypes += (zen("GrantType2").aux + ",");
		if (zen("GrantType3").getValue()) RequiredGrantTypes += (zen("GrantType3").aux + ",");
		if (zen("GrantType4").getValue()) RequiredGrantTypes += (zen("GrantType4").aux + ",");
		if (zen("GrantType5").getValue()) RequiredGrantTypes += (zen("GrantType5").aux + ",");

		if (!this.validateRequired(zen('Name'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'Name';
		}
		if (!this.validateRequired(zen('SSLConfiguration'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'SSLConfiguration';
		}

		if (!isRegister) {
			if (!this.validateRequired(zen('ClientId'),pass,"S")) {
				pass = false;
				fields = fields + ((fields != "") ? ', ' : '') + 'ClientId';
			}
			if (ClientType != "resource") {
				if ((ClientType == "confidential") && !this.validateRequired(zen('ClientSecret'),pass,"S")) {
					pass = false;
					fields = fields + ((fields != "") ? ', ' : '') + 'ClientSecret';
				}
			}
		}
		if (ClientType != "resource") {
			if (!this.validateRequired(zen('addr'),pass,"S")) {
				pass = false;
				fields = fields + ((fields != "") ? ', ' : '') + 'redirect URL';
			}
			if (!RequiredGrantTypes) {
				pass = false;
				if (!this.FirstFailed) this.FirstFailed = 'GrantType1';
				fields = fields + ((fields != "") ? ', ' : '') + 'RequiredGrantTypes';
			}
		}
		if (zen("chkCreateJWT").getValue()) {
			if (!this.validateRequired(zen('ClientCredentials'),pass,"S")) {
				pass = false;
				fields = fields + ((fields != "") ? ', ' : '') + 'ClientCredentials';
			}
		}
		if (!pass) {
			this.ValidationErrorMsg = $$$Text('Required fields missing: ') + fields;
			this.afterValidate();
			return false;
		}

		valueProxy.AuthSigning = zenTrim(zen("AuthSigning").getValue());
		valueProxy.JWTAud = zenTrim(zen("JWTAud").getValue());
		valueProxy.IDTokenSigning = zenTrim(zen("IDTokenSigning").getValue());
		valueProxy.IDTokenEncryption = zenTrim(zen("IDTokenEncryption").getValue());
		valueProxy.IDTokenKey = zenTrim(zen("IDTokenKey").getValue());
		valueProxy.UserinfoSigning = zenTrim(zen("UserinfoSigning").getValue());
		valueProxy.UserinfoEncryption = zenTrim(zen("UserinfoEncryption").getValue());
		valueProxy.UserinfoKey = zenTrim(zen("UserinfoKey").getValue());
		valueProxy.AccessTokenSigning = zenTrim(zen("AccessTokenSigning").getValue());
		valueProxy.AccessTokenEncryption = zenTrim(zen("AccessTokenEncryption").getValue());
		valueProxy.AccessTokenKey = zenTrim(zen("AccessTokenKey").getValue());
		valueProxy.RequestSigning = zenTrim(zen("RequestSigning").getValue());
		valueProxy.RequestEncryption = zenTrim(zen("RequestEncryption").getValue());
		valueProxy.RequestKey = zenTrim(zen("RequestKey").getValue());

		fields = '';
		if ((valueProxy.IDTokenEncryption != 'none' && valueProxy.IDTokenKey == 'none') ||
		    (valueProxy.IDTokenEncryption == 'none' && valueProxy.IDTokenKey != 'none')) {
				pass = false;
				fields = fields + ((fields != "") ? ', ' : '') + 'IDToken';
		}
		if ((valueProxy.UserinfoEncryption != 'none' && valueProxy.UserinfoKey == 'none') ||
		    (valueProxy.UserinfoEncryption == 'none' && valueProxy.UserinfoKey != 'none')) {
				pass = false;
				fields = fields + ((fields != "") ? ', ' : '') + 'Userinfo';
		}
		if ((valueProxy.AccessTokenEncryption != 'none' && valueProxy.AccessTokenKey == 'none') ||
		    (valueProxy.AccessTokenEncryption == 'none' && valueProxy.AccessTokenKey != 'none')) {
				pass = false;
				fields = fields + ((fields != "") ? ', ' : '') + 'Access token';
		}
		if ((valueProxy.RequestEncryption != 'none' && valueProxy.RequestKey == 'none') ||
		    (valueProxy.RequestEncryption == 'none' && valueProxy.RequestKey != 'none')) {
				pass = false;
				fields = fields + ((fields != "") ? ', ' : '') + 'Request';
		}
		if (!pass) {
			this.ValidationErrorMsg = $$$Text('Encryption and key algorithms must be specified together: ') + fields;
			this.afterValidate();
			return false;
		}
		
		valueProxy.Name = zenTrim(zen('Name').getValue());
		valueProxy.Description = zenTrim(zen("Description").getValue());
		valueProxy.Enabled = (zen("Enabled").getValue()) ? 1 : 0;
		valueProxy.SSLConfiguration = zenTrim(zen("SSLConfiguration").getValue());
		valueProxy.ClientType = ClientType;
		valueProxy.UseSSL = zen("UseSSL").getValue();
		valueProxy.addr = zenTrim(zen("addr").getValue());
		valueProxy.port = zenTrim(zen("port").getValue());
		valueProxy.prefix = zenTrim(zen("prefix").getValue());
		valueProxy.DefaultScope = zenTrim(zen("DefaultScope").getValue());
		valueProxy.AuthenticationType = zenTrim(zen("AuthenticationType").getValue());
		valueProxy.RequiredGrantTypes = RequiredGrantTypes;
		valueProxy.ClientName = zenTrim(zen("ClientName").getValue());
		valueProxy.LogoUri = zenTrim(zen("LogoUri").getValue());
		valueProxy.ClientUri = zenTrim(zen("ClientUri").getValue());
		valueProxy.PolicyUri = zenTrim(zen("PolicyUri").getValue());
		valueProxy.TosUri = zenTrim(zen("TosUri").getValue());
		valueProxy.ClientId = zenTrim(zen("ClientId").getValue());
		valueProxy.ClientSecret = zenTrim(zen("ClientSecret").getValue());
		valueProxy.ClientCredentials = zenTrim(zen("ClientCredentials").getValue());
		valueProxy.ClientPassword = zenTrim(zen("ClientPassword").getValue());
		valueProxy.Contacts = zenTrim(zen("Contacts").getValue());
		valueProxy.DefaultMaxAge = zenTrim(zen("DefaultMaxAge").getValue());
		valueProxy.FrontChannelUri = zenTrim(zen("FrontChannelUri").getValue());
		valueProxy.FrontChannelSessionRequired = (zen("FrontChannelSessionRequired").getValue()) ? 1 : 0;
	
		return true;
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
	
	return false;
}

/// This method is necessary for the svgTabArea and tabBar to show properly.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
		// find size of window
		var winWidth = zenGetWindowWidth();	
		// set the svg and tabs the right size
		zen("svgTabArea").setProperty("width",winWidth-50);
		zen("tabBar").setProperty("width",winWidth-50);
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Set focus to the Name field.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	
	zen("Name").focus();
	// disable or enable fields based on Type, etc.
	if (zen("ClientType").getValue()=='') zen("ClientType").setValue("confidential")
	this.changeClientType();
	this.changeAuthType();
	var hash = parseInt(document.location.hash.slice(1));
	if ((typeof(hash) === 'number') && (hash >= 0) && (hash <= this.NumTabs)) {
		zen('tabBar').tabClicked(hash);
	} else {
		this.tabChanged(0);
	}
	
	if (zenPage.isNew) {
		this.disableCommandButton("btnUpdate");
	}
	
	const redirect = zen('redirectURL');
	redirect.originalValue = redirect.value;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	#; If a PID is purposely removed when this page is rendered, then set isNew to true.
	If ..PID = "" Set ..isNew = 1

	Set titleAdd = $$$FormatText($$$Text("Use the form below to create a new OAuth 2.0 client configuration for server %1:"), $zconvert(%page.IssuerEndpoint,"O","HTML"))
	Set titleEdit = $$$FormatText($$$Text("Use the form below to edit an existing OAuth 2.0 client configuration for server %1:"), $zconvert(%page.IssuerEndpoint,"O","HTML"))
	Set ..lblTitle = $S(..isNew=1:titleAdd,1:titleEdit)
	Set ..ParentURL = ..Link("%25CSP.UI.Portal.OAuth2.Client.ConfigurationList.zen")_"?IssuerEndpointID="_$zconvert(%page.IssuerEndpointID,"O","HTML")_"&IssuerEndpoint=" _ $zconvert(%page.IssuerEndpoint,"O","HTML")

	// Load data into fields
	Set err = ..LoadData(..PID)
	If err'="" {
		Set ..%GetComponentById("idRespond").value = err
		Set ..%GetComponentById("idRespond").hidden = 0
		Set ..%GetComponentById("groupEdit").hidden = 1
	}

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$TextHTML("Client Configuration")
}

/// Get the (localized) title string for the page.
/// Overrid Edit: id as text on tab display below Menu
Method %OnGetTitle() As %String
{
	Quit ..LocatorHeader
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("OAuth 2.0 Client","%Utility")
	Set tURL = ..Link("%25CSP.UI.Portal.OAuth2.Client.ServerList.zen")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Client Configurations","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_"?PID="_..EscapeURL($G(%request.Data("PID",1)))_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get redirect URL upon user changing any of server address/port/prefix.
ClientMethod getRedirectURL() [ Language = javascript ]
{
	var ssl = zen('UseSSL').getValue() ? 1 : 0;
	var addr = zenTrim(zen('addr').getValue());
	var port = zenTrim(zen('port').getValue());
	var prefix = zenTrim(zen('prefix').getValue());
	var url = this.GetRedirectURLforUI(addr, port, prefix, ssl);
	zen('redirectURL').setValue(url);
}

/// Get front channel logout URL upon user changing the provided front channel logout URL
ClientMethod getFrontChannelURL() [ Language = javascript ]
{
	var provided = zenTrim(zen('ProvidedFrontChannelUri').getValue());
	var url = this.GetFrontChannelURLforUI(provided);
	zen('FrontChannelUri').setValue(url);
}

/// Used when Editing an existing OAuth2 client configuration. Load previously defined values into fields.
Method LoadData(PID As %String, sys As OAuth2.Client = "") As %String
{
	Set $ZT="Error"

	Set isnew=0
	If sys="" {	
		If '%page.isNew {
			If ##class(OAuth2.Client).%ExistsId(PID) {
				Set sys = ##class(OAuth2.Client).Open(PID)
			} Else {
				Quit $$$TextHTML("Cannot open object!")
			}
		} Else {
			Set sys = ##class(OAuth2.Client).%New()
			Set isnew=1
		}
	}

	Set isHidden = (sys.ClientType = "resource")
	Set ..%GetComponentById("UseSSL").hidden = isHidden
	Set ..%GetComponentById("addr").hidden = isHidden
	Set ..%GetComponentById("port").hidden = isHidden
	Set ..%GetComponentById("prefix").hidden = isHidden
	Set ..%GetComponentById("DefaultScope").hidden = isHidden
	Set ..%GetComponentById("GrantTypeList").hidden = isHidden
	Set ..%GetComponentById("id_DisplayURL").hidden = isHidden
	Set ..%GetComponentById("DefaultMaxAge").hidden = isHidden
	Set ..%GetComponentById("id_IDToken").hidden = isHidden
	Set ..%GetComponentById("id_AccessToken").hidden = isHidden
	Set ..%GetComponentById("id_Request").hidden = isHidden

	Set tRS = ##class(%ResultSet).%New("Security.SSLConfigs:List")
	Do tRS.Execute("*")
	Set SSLConfigurations = ""
	While tRS.Next() {
		If tRS.GetData(1) '= "",tRS.GetData(6) = 0 {
			Set SSLConfigurations = SSLConfigurations _ $S(SSLConfigurations'="":",",1:"") _ tRS.GetData(1)	
		}
	}
	Set ..%GetComponentById("Name").value = PID
	Set ..%GetComponentById("Description").value = sys.Description
	Set ..%GetComponentById("Enabled").value = sys.Enabled
	Set ..%GetComponentById("ClientType").value = sys.ClientType
	Set ..%GetComponentById("SSLConfiguration").valueList = SSLConfigurations
	Set ..%GetComponentById("SSLConfiguration").value = sys.SSLConfiguration
	Set ..%GetComponentById("UseSSL").value = $select(sys.RedirectionEndpoint.UseSSL="":1,1:sys.RedirectionEndpoint.UseSSL)
	Set ..%GetComponentById("addr").value = sys.RedirectionEndpoint.Host
	Set ..%GetComponentById("port").value = sys.RedirectionEndpoint.Port
	Set ..%GetComponentById("prefix").value = sys.RedirectionEndpoint.Prefix
	Set ..%GetComponentById("DefaultScope").value = sys.DefaultScope
	Set ..%GetComponentById("AuthenticationType").value = sys.Metadata."token_endpoint_auth_method"
	Set ..%GetComponentById("ClientName").value = sys.Metadata."client_name"
	Set ..%GetComponentById("LogoUri").value = sys.Metadata."logo_uri"
	Set ..%GetComponentById("ClientUri").value = sys.Metadata."client_uri"
	Set ..%GetComponentById("PolicyUri").value = sys.Metadata."policy_uri"
	Set ..%GetComponentById("TosUri").value = sys.Metadata."tos_uri"
	Set ..%GetComponentById("ClientId").value = sys.ClientId
	Set ..%GetComponentById("ClientSecret").value = sys.ClientSecret
	Set time = sys.Metadata."client_id_issued_at"
	If time'="" {
		Set time = $zdatetime(##class(%OAuth2.Utils).TimeInH(time))
	}
	Set ..%GetComponentById("ClientIdIssuedAt").value = time
	Set time = sys.Metadata."client_secret_expires_at"
	If time'="" {
		Set time = $zdatetime(##class(%OAuth2.Utils).TimeInH(time))
	}
	Set ..%GetComponentById("ClientSecretExpiresAt").value = time
	Set ..%GetComponentById("RegistrationClientUri").value = sys.Metadata."registration_client_uri"
	Set ..%GetComponentById("redirectURL").value = ..GetRedirectURLforUI(sys.RedirectionEndpoint.Host, sys.RedirectionEndpoint.Port, sys.RedirectionEndpoint.Prefix, sys.RedirectionEndpoint.UseSSL)
	Set ..%GetComponentById("ClientCredentials").value = sys.ClientCredentials
	Set ..%GetComponentById("ClientCredentials").originalValue = sys.ClientCredentials
	Set ..%GetComponentById("ClientPassword").value = sys.ClientPassword
	Set ..%GetComponentById("Contacts").value = ##class(%OAuth2.Utils).ListToComma(sys.Metadata.contacts)
	Set ..%GetComponentById("DefaultMaxAge").value = sys.Metadata."default_max_age"

	Set tX509List = ""
	Set tRS = ##class(%ResultSet).%New("%SYS.X509Credentials:ListPrivateKey")
	Do tRS.Execute()
	While tRS.Next() {
		Set tX509List = tX509List _ $S(tX509List'="":",", 1:"")_tRS.GetData(1)	
	}
	Set ..%GetComponentById("ClientCredentials").valueList = tX509List	

	If isnew {
		Set ..%GetComponentById("chkCreateJWT").value = 0
		Set ..%GetComponentById("groupCreateJWT").hidden = 1
		Set ..%GetComponentById("AuthenticationType").value = "client_secret_basic"
		Set ..%GetComponentById("GrantType1").value = 1
		Set ..%GetComponentById("AuthSigning").value = ""
		Set ..%GetComponentById("JWTAud").value = ""
		Set ..%GetComponentById("IDTokenSigning").value = "RS256"
		Set ..%GetComponentById("IDTokenEncryption").value = "none"
		Set ..%GetComponentById("IDTokenKey").value = "none"
		Set ..%GetComponentById("UserinfoSigning").value = "none"
		Set ..%GetComponentById("UserinfoEncryption").value = "none"
		Set ..%GetComponentById("UserinfoKey").value = "none"
		Set ..%GetComponentById("AccessTokenSigning").value = "none"
		Set ..%GetComponentById("AccessTokenEncryption").value = "none"
		Set ..%GetComponentById("AccessTokenKey").value = "none"
		Set ..%GetComponentById("RequestSigning").value = "none"
		Set ..%GetComponentById("RequestEncryption").value = "none"
		Set ..%GetComponentById("RequestKey").value = "none"
		Set ..%GetComponentById("FrontChannelUri").value = ""
		Set ..%GetComponentById("ProvidedFrontChannelUri").value = ""
		Set ..%GetComponentById("FrontChannelSessionRequired").value = 0

	} Else {
		Set credSelect = sys.ClientCredentials '= ""
		Set ..%GetComponentById("chkCreateJWT").value = credSelect
		Set ..%GetComponentById("groupCreateJWT").hidden = 'credSelect
		Set ..%GetComponentById("AuthSigning").value = sys.Metadata."token_endpoint_auth_signing_alg"
		Set ..%GetComponentById("JWTAud").value = sys.JWTAudience
		Set ..%GetComponentById("IDTokenSigning").value = sys.Metadata."id_token_signed_response_alg"
		Set ..%GetComponentById("IDTokenEncryption").value = sys.Metadata."id_token_encrypted_response_enc"
		Set ..%GetComponentById("IDTokenKey").value = sys.Metadata."id_token_encrypted_response_alg"
		Set ..%GetComponentById("UserinfoSigning").value = sys.Metadata."userinfo_signed_response_alg"
		Set ..%GetComponentById("UserinfoEncryption").value = sys.Metadata."userinfo_encrypted_response_enc"
		Set ..%GetComponentById("UserinfoKey").value = sys.Metadata."userinfo_encrypted_response_alg"
		Set ..%GetComponentById("AccessTokenSigning").value = sys.Metadata."access_token_signed_response_alg"
		Set ..%GetComponentById("AccessTokenEncryption").value = sys.Metadata."access_token_encrypted_response_enc"
		Set ..%GetComponentById("AccessTokenKey").value = sys.Metadata."access_token_encrypted_response_alg"
		Set ..%GetComponentById("RequestSigning").value = sys.Metadata."request_object_signing_alg"
		Set ..%GetComponentById("RequestEncryption").value = sys.Metadata."request_object_encryption_enc"
		Set ..%GetComponentById("RequestKey").value = sys.Metadata."request_object_encryption_alg"
		Set ..%GetComponentById("FrontChannelUri").value = sys.Metadata."frontchannel_logout_uri"
		Set ..%GetComponentById("ProvidedFrontChannelUri").value = sys.Metadata."frontchannel_logout_uri"
		Set ..%GetComponentById("FrontChannelSessionRequired").value = sys.Metadata."frontchannel_logout_session_required"

		Set ..%GetComponentById("GrantType1").value = 0
		Set ..%GetComponentById("GrantType2").value = 0
		Set ..%GetComponentById("GrantType3").value = 0
		Set ..%GetComponentById("GrantType4").value = 0
		Set ..%GetComponentById("GrantType5").value = 0
		Set grantTypes = sys.Metadata."grant_types"
		For i = 1:1:$ll(grantTypes) {
			Set value = $listget(grantTypes,i)
			If value '= "" {
				Set:value="authorization_code" ..%GetComponentById("GrantType1").value = 1
				Set:value="implicit" ..%GetComponentById("GrantType2").value = 1
				Set:value="password" ..%GetComponentById("GrantType3").value = 1
				Set:value="client_credentials" ..%GetComponentById("GrantType4").value = 1
				Set:value="jwt_authorization" ..%GetComponentById("GrantType5").value = 1
			}
		}
	}

	If sys.ClientId="" {
		Set ..buttonCaption = $$$Text("Dynamic Registration and Save")
	} ElseIf sys.Metadata."registration_client_uri"'="" {
		Set ..buttonCaption = $$$Text("Get Updated Metadata and Save")
	} Else {
		Set ..buttonCaption=""
	}
	
	Set ..jwksAvailable=('sys.JWKSFromCredentials && (sys.PrivateJWKS'=""))

	Quit ""
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
}

/// Call RotateKeys method
ClassMethod Rotate(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#dim sys as OAuth2.Client

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.PID = pValueProxy.Name
	Set tSC = $$$OK
	
	Set sys = ##class(OAuth2.Client).Open(pValueProxy.Name,.tSC)
	If $isobject(sys) {
		Set tSC=sys.RotateKeys()
	}

	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	} ElseIf '$isobject(sys) {
		Set tProxy.ErrorMessage = $$$Text("No JWKS found for key rotation")
	} Else {
		Set tProxy.ok = 1
		Set tProxy.PID = sys.%Id()
		Set tProxy.Message=$$$Text("Key rotation complete")
	}
	Kill sys
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Kill sys
	Quit tProxy
}

/// Save general association data to server
/// Test can only be done for client, not server. 
Method SaveData(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Try {
		#dim sys as OAuth2.Client

		#; Initialize return proxy object
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.ok = 0
		Set tProxy.Message = ""
		Set tProxy.ErrorMessage = ""
		Set tProxy.PID = pValueProxy.Name
		Set tSC = $$$OK
		
		Set sys=..Prepare(pValueProxy)
		
		Set tSC = sys.%Save()
		
		If $$$ISERR(tSC) {
			Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		} Else {
			Set tProxy.ok = 1
			Set tProxy.PID = sys.%Id()
			Set tProxy.Message = $$$Text("Client saved.")
			Set regMessage = ""
		
			#; try to update server if using dynamic registration
			#; this could fail if the server doesn't support update
			If sys.Metadata."registration_client_uri"'="" {
				Set tSC = sys.UpdateClient()
				
				If $$$ISERR(tSC) {
					Set regMessage = $$$Text("Could not update metadata on authorization server. Changes made to this client need to be entered manually on the authorization server.")
					Set regMessage = regMessage_$C(10,10)_$$$Text("Error details:")_$C(10)_$ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
				} Else {
					Set regMessage = $$$Text("Updated metadata on authorization server.")
					;# update the page based on the server's response
					Set err = ..LoadData(tProxy.PID,sys)
					If err'="" {
						Set regMessage = regMessage_$C(10)_"Error updating page: "_err
					}
				}
			} Else {
				Set regMessage = $$$Text("This client has not been registered. Changes made to this client need to be entered manually on the authorization server.")
			}
			Set tProxy.Message = tProxy.Message_$C(10)_regMessage
		}
	} Catch e {
		Set $ZT="" Do BACK^%ETN
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	}
	
	Return tProxy
}

/// Read the updated mnetadata from a previously dynamically registered client
Method ReadMetadata(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="ReadError"
	
	#dim sys as OAuth2.Client

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.PID = pValueProxy.Name
	Set tProxy.ErrorMessage = ""
	Set tSC = $$$OK
	
	Set sys=..Prepare(pValueProxy)
	
	// Read and save metadata
	If $$$ISOK(tSC) Set tSC=sys.ReadClient()
	
	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		
	} Else {
		// Load data into fields
		Set err = ..LoadData(tProxy.PID,sys)	
		If err'="" {
			Set tProxy.ErrorMessage = err
		}
	}

	If tProxy.ErrorMessage = "" {
		Set tProxy.ok = 1
		Set tProxy.PID = sys.%Id()
	}
	Kill sys
	Quit tProxy
ReadError	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Kill sys
	Quit tProxy
}

/// Register this client and save its metadata
Method Register(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="RegisterError"
	
	#dim sys as OAuth2.Client

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.PID = pValueProxy.Name
	Set tSC = $$$OK
	
	Set sys=..Prepare(pValueProxy)
	
	// Register and Save
	Set tSC=sys.RegisterClient()
	
	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		
	} Else {
		// Load data into fields
		Set err = ..LoadData(tProxy.PID,sys)
		If err'="" {
			Set tProxy.ErrorMessage = err
		}
	}

	If tProxy.ErrorMessage = "" {
		Set tProxy.ok = 1
		Set tProxy.PID = sys.%Id()
	}
	Kill sys
	Quit tProxy
RegisterError	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Kill sys
	Quit tProxy
}

/// Get the issuer endpoint
Method GetIssuerEndpointID() As %String
{
	Quit %page.IssuerEndpointID
}

/// Prepare object with the client data.
Method Prepare(pValueProxy As %ZEN.proxyObject) As OAuth2.Client [ ZenMethod ]
{
	Set IssuerEndpointID = ..GetIssuerEndpointID()
	If IssuerEndpointID '= "" {
		Set ServerDefinition = ##class(OAuth2.ServerDefinition).Open(IssuerEndpointID)
	} Else {
		Set ServerDefinition = ##class(OAuth2.ServerDefinition).%New()
	}
	If ##class(OAuth2.Client).%ExistsId(pValueProxy.Name) {
		Set sys = ##class(OAuth2.Client).Open(pValueProxy.Name)
	} Else {
		Set sys = ##class(OAuth2.Client).%New()
		Set sys.ApplicationName = pValueProxy.Name
	}
	Set sys.ServerDefinition = ServerDefinition
	Set sys.Enabled = pValueProxy.Enabled
	Set sys.ClientType = pValueProxy.ClientType
	Set sys.Description = pValueProxy.Description
	Set sys.SSLConfiguration = pValueProxy.SSLConfiguration
	Set sys.RedirectionEndpoint.UseSSL = pValueProxy.UseSSL
	Set sys.RedirectionEndpoint.Host = pValueProxy.addr
	Set sys.RedirectionEndpoint.Port = pValueProxy.port
	Set sys.RedirectionEndpoint.Prefix = pValueProxy.prefix
	Set sys.DefaultScope = pValueProxy.DefaultScope
	Set sys.Metadata."token_endpoint_auth_method" = pValueProxy.AuthenticationType
	Set types=""
	Set grantTypes = pValueProxy.RequiredGrantTypes
	For i=1:1:$length(grantTypes,",") {
		Set type=$piece(grantTypes,",",i)
		If type'="" Set types=types_$lb(type)
	}
	Set sys.Metadata."grant_types" = types
	Set sys.Metadata."client_name" = pValueProxy.ClientName
	Set sys.Metadata."logo_uri" = pValueProxy.LogoUri
	Set sys.Metadata."client_uri" = pValueProxy.ClientUri
	Set sys.Metadata."policy_uri" = pValueProxy.PolicyUri
	Set sys.Metadata."tos_uri" = pValueProxy.TosUri
	Set sys.ClientId = pValueProxy.ClientId
	Set sys.ClientSecret = pValueProxy.ClientSecret
	Set sys.ClientCredentials = pValueProxy.ClientCredentials
	Set sys.ClientPassword = pValueProxy.ClientPassword
	Set sys.JWTAudience = pValueProxy.JWTAud

	Set sys.Metadata."token_endpoint_auth_signing_alg" = pValueProxy.AuthSigning
	Set sys.Metadata."id_token_signed_response_alg" = pValueProxy.IDTokenSigning
	Set sys.Metadata."id_token_encrypted_response_enc" = pValueProxy.IDTokenEncryption
	Set sys.Metadata."id_token_encrypted_response_alg" = pValueProxy.IDTokenKey
	Set sys.Metadata."userinfo_signed_response_alg" = pValueProxy.UserinfoSigning
	Set sys.Metadata."userinfo_encrypted_response_enc" = pValueProxy.UserinfoEncryption
	Set sys.Metadata."userinfo_encrypted_response_alg" = pValueProxy.UserinfoKey
	Set sys.Metadata."access_token_signed_response_alg" = pValueProxy.AccessTokenSigning
	Set sys.Metadata."access_token_encrypted_response_enc" = pValueProxy.AccessTokenEncryption
	Set sys.Metadata."access_token_encrypted_response_alg" = pValueProxy.AccessTokenKey
	Set sys.Metadata."request_object_signing_alg" = pValueProxy.RequestSigning
	Set sys.Metadata."request_object_encryption_enc" = pValueProxy.RequestEncryption
	Set sys.Metadata."request_object_encryption_alg" = pValueProxy.RequestKey

	Set sys.Metadata.contacts = ##class(%OAuth2.Utils).CommaToList(pValueProxy.Contacts)
	Set sys.Metadata."default_max_age" = pValueProxy.DefaultMaxAge
	Set sys.Metadata."frontchannel_logout_uri" = pValueProxy.FrontChannelUri
	Set sys.Metadata."frontchannel_logout_session_required" = pValueProxy.FrontChannelSessionRequired

	Quit sys
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Set i = 0
	// commands: $LB(id,caption,help,onclick)
	Set pCommands($i(i)) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave();")
	Set pCommands($i(i)) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doFinish();")
	Set pCommands($i(i)) = $LB("spacer","spacer","spacer","true;",1)
	If ..buttonCaption '= "" {
		Set pCommands($i(i)) = $LB("btnRegister",..buttonCaption,..buttonCaption,"zenPage.doRegister();")
	} Else {
		Set pCommands($i(i)) = $LB("spacer","spacer","spacer","true;",1)
	}
	Set pCommands($i(i)) = $LB("spacer","spacer","spacer","true;",1)
	If ..jwksAvailable {
		Set pCommands($i(i)) = $LB("btnRotate",$$$Text("Rotate Keys"),$$$Text("Rotate keys in private JWKS"),"zenPage.doRotate();")
	}

	Quit $$$OK
}

ClassMethod GetRedirectURLforUI(pAddress, pPort, pPrefix, pSSL) As %String [ ZenMethod ]
{
	If pAddress="", pPort="", pPrefix="" Quit ""
	Set tClient = ##class(OAuth2.Client).%New()
	Set tClient.RedirectionEndpoint.UseSSL = pSSL
	Set tClient.RedirectionEndpoint.Host = pAddress
	Set tClient.RedirectionEndpoint.Port = pPort
	Set tClient.RedirectionEndpoint.Prefix = pPrefix
	Set tURL = ##class(OAuth2.Response).GetRedirectURL(tClient, .tSC)
	If $$$ISOK(tSC) Quit tURL
	Quit $System.Status.GetErrorText(tSC)
}

ClassMethod GetFrontChannelURLforUI(pProvidedUrl) As %String [ ZenMethod ]
{
	If pProvidedUrl="" Quit ""
	Quit pProvidedUrl_$select(pProvidedUrl["IRISLogout=end":"",pProvidedUrl["?":"&IRISLogout=end",1:"?IRISLogout=end")
}

Method DrawHelpText(pSeed As %String) As %Status
{
	&html<<h5>#($$$TextHTML("If you register a client dynamically, specify details on the tabs below, except for the Client Credentials tab. When you are done, click Register and Save. InterSystems IRIS contacts the authorization server, registers the client, obtains the generated client ID and client secret, and saves that information locally."))#</h5>>
	&html<<h5>#($$$TextHTML("If you register a client manually, specify details on all the tabs. On the Client Credentials tab, enter the client ID, client secret, and other information generated by the authorization server. Then click Save."))#</h5>>
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
