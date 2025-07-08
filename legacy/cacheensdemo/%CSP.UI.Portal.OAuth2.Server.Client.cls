/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Page to define OAuth2 server clients
/// which have registered with the authorization server.
Class %CSP.UI.Portal.OAuth2.Server.Client Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "OAuth 2.0 Authorization Server Client Configuration";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Server.Client.zen";

Parameter HELPADDRESS = "System Administration,Security,OAuth2,Server Client Configuration";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_OAuth2_Registration";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

/// ID for edit. Null if adding new client.
Property ClientId As %String(ZENURL = "ClientId");

Property isNew As %Boolean;

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.OAuth2.Server.Client.zen",,1)} ];

Property addRedirectURL As %Boolean [ InitialExpression = 1 ];

Property currIndex As %Integer;

Property NumTabs As %Integer [ InitialExpression = 4 ];

Property jwksAvailable As %Boolean;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.listBox {
	border: 1px solid darkgray;	
}
.EditForm {
	background-image: none;	
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

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">

<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white;stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":General:Client Credentials:Client Information:JWT Settings"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<!-- Page 1: General -->
<vgroup id="page_1" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;" labelPosition="left">

<form autocomplete="false">
<text hidden="true" name="browseselect" id="browseselect"/>
<group id="groupEdit" enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<spacer height="2"/>
<text id="Name" label="Name" size="60" maxlength="1024" hint="Required." onchange="zenPage.modified();"/>
<text id="Description" label="Description" size="60" maxlength="1024" onchange="zenPage.modified();"/>
<radioSet id="ClientType" label="Client type" displayList="Confidential,Public,Resource server" valueList="confidential,public,resource" required="true" hint="Required." onchange="zenPage.modified();zenPage.ClientTypeModified()"/>
<group id="groupRedirectArea">
	<listBox id="RedirectURLs" label="Redirect URLs" hint="Require at least one URL. Click an item in the list to edit or remove." width="600px" onchange="zenPage.selectRedirectURL();"/>
	<button id="btnAdd" caption="Add URL" onclick="zenPage.newRedirectURL();"/>
	<group id="groupRedirectURL" labelPosition="left" hidden="true">
	<text id="RedirectURL" label="Enter URL: " required="true" size="60" onchange="zenPage.modified();"/>
</group>
<hgroup>
<button id="btnSave" caption="OK" onclick="zenPage.saveRedirectURL();"/>
<button id="btnRemove" caption="Remove" disabled="true" onclick="zenPage.removeRedirectURL();"/>
<button id="btnCancel" caption="Cancel" onclick="zenPage.cancelRedirectURL();"/>
</hgroup>
</group>
<vgroup label="Supported grant types (check at least one)" labelPosition="left" >
<checkbox id="GrantType1" caption="Authorization code" captionClass="normal" aux="A" onchange="zenPage.modified();"/>
<checkbox id="GrantType2" caption="Implicit" captionClass="normal" aux="I" onchange="zenPage.modified();"/>
<checkbox id="GrantType3" caption="Resource owner password credentials" captionClass="normal" aux="P" onchange="zenPage.modified();"/>
<checkbox id="GrantType4" caption="Client credentials" captionClass="normal" aux="C" onchange="zenPage.modified();"/>
<checkbox id="GrantType5" caption="JWT authorization" captionClass="normal" aux="J" onchange="zenPage.modified();zenPage.changeAuthType();"/>
</vgroup>
<vgroup label="Supported response types (check at least one)" labelPosition="left" >
<checkbox id="ResponseType1" caption="code" captionClass="normal" aux="code" onchange="zenPage.modified();"/>
<checkbox id="ResponseType2" caption="id_token" captionClass="normal" aux="id_token" onchange="zenPage.modified();"/>
<checkbox id="ResponseType3" caption="id_token token" captionClass="normal" aux="id_token token" onchange="zenPage.modified();"/>
<checkbox id="ResponseType4" caption="token" captionClass="normal" aux="token" onchange="zenPage.modified();"/>
</vgroup>
<radioSet id="AuthenticationType" label="Authentication type" displayList="none,basic,form encoded body,client secret JWT,private key JWT" valueList="none,client_secret_basic,client_secret_post,client_secret_jwt,private_key_jwt" value="basic" onchange="zenPage.modified();zenPage.changeAuthType();"/>
<select id="AuthSigning" label="Authentication signing algorithm" controlStyle="width:16em" showEmpty="false" onchange="zenPage.modified();"/>
</group>
</form>
</vgroup>

<!-- Page 2: Client Credentials -->
<vgroup id="page_2" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;">
<form autocomplete="false">

<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">

<text id="ClientId" label="Client ID" readOnly="true" size="60" controlStyle="background:#D0D0D0;"/>
<hgroup label="Client secret">
<text id="ClientSecret" size="99" readOnly="true" hidden="true" controlStyle="background:#D0D0D0;"/>
<link id="linkClientSecret" caption="show" href="#" onclick="zenPage.showHide('ClientSecret');"/>
</hgroup>
</group>
</form>
</vgroup>

<!-- Page 3: Client Information  -->
<vgroup id="page_3" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;">
<form autocomplete="false">

<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<spacer height="2"/>
<text id="LaunchURL" label="Launch URL: " size="60" onchange="zenPage.modified();"/>
<fieldSet id="id_DisplayURL" label="Authorization display" >
<label id="id_DisplayNote" value="This section contains the information to be displayed when requesting permissions from the end user." enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<text id="ClientName" label="Client name" size="40" hint="" onchange="zenPage.modified();"/>
<text id="LogoUri" label="Logo URL" size="70" hint="" onchange="zenPage.modified();"/>
<text id="ClientUri" label="Client home page URL" size="70" onchange="zenPage.modified();"/>
<text id="PolicyUri" label="Policy URL" size="70" onchange="zenPage.modified();"/>
<text id="TosUri" label="Terms of service URL" size="70" onchange="zenPage.modified();"/>
</fieldSet>

<text id="Contacts" label="Contact emails (comma separated)" size="40" hint="" onchange="zenPage.modified();"/>
<text id="DefaultMaxAge" label="Default max age" size="40" hint="" onchange="zenPage.modified();"/>
<text id="DefaultScope" label="Default scope" size="60" onchange="zenPage.modified();"/>
<fieldSet id="FrontChannel" label="Front channel logout" >
<label id="FrontChannelLabel" value="This section contains the information governing the client's front channel logout behavior" enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<text id="FrontChannelUri" label="Front channel logout URL" size="70" hint="" onchange="zenPage.modified();"/>
<checkbox id="FrontChannelSessionRequired" caption="Front channel logout session required" captionClass="normal" aux="logout_session_required" onchange="zenPage.modified();"/>
</fieldSet>
</group>
</form>
</vgroup>

<!-- Page 4: JWT Settings -->
<vgroup id="page_4" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;">
<form autocomplete="false">

<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">

<fieldSet id="groupJWT" label="JSON Web Token (JWT) Settings">
<select id="selJWTOptions" label="Source other than dynamic registration" valueList="1,2,3" displayList="JWKS from URL,JWKS from file,X509 certificate" onchange="zenPage.modified();zenPage.doJWTChange(zenThis.value);" />
<group id="groupJWT1" hidden="true">
<text id="JWTURL" label="URL:" hint="Required. Enter an URL."/>
</group>
<hgroup id="groupJWT2" hidden="true" label="File containing registration information" cellVAlign="top">
<text id="JWTFile" size="60" hint="Required. Select a file." onchange="zenPage.modified();"/>
<button id="btnBrowse" caption="Browse..." onclick="zenPage.browseSelect('JWTFile');"/>
</hgroup>
<group id="groupJWT3" hidden="true">
<select id="ClientCredentials" label="Client credentials" onchange="zenPage.modified();"/>
</group>
</fieldSet>
<spacer height="2"/>
<hgroup>
<text id="TextSigning" value="Signing" controlStyle="width:16em;" disabled="true"/>
<text id="TextEncryption" value="Encryption" controlStyle="width:16em;" disabled="true"/>
<text id="TextKey" value="Key" controlStyle="width:16em;" disabled="true"/>
</hgroup>
<hgroup label="IDToken algorithms">
<select id="IDTokenSigning" controlStyle="width:16em" showEmpty="false" value="RS256" valueList="RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="IDTokenEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="IDTokenKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
<hgroup label="Userinfo algorithms">
<select id="UserinfoSigning" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="UserinfoEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="UserinfoKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
<hgroup label="Access token algorithms">
<select id="AccessTokenSigning" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="AccessTokenEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="AccessTokenKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
<hgroup label="Request algorithms">
<select id="RequestSigning" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,RS256,RS384,RS512,HS256,HS384,HS512,ES256,ES384,ES512" onchange="zenPage.modified();"/>
<select id="RequestEncryption" controlStyle="width:16em" showEmpty="false" value="none" valueList="none,A128CBC-HS256,A192CBC-HS384,A256CBC-HS512" onchange="zenPage.modified();"/>
<select id="RequestKey" controlStyle="width:16em;" showEmpty="false" value="none" valueList="none,RSA1_5,RSA-OAEP,A128KW,A192KW,A256KW,dir" onchange="zenPage.modified();"/>
</hgroup>
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

/// User changed Authentication Type. Show/hide authorization signing algorithm.
ClientMethod changeAuthType() [ Language = javascript ]
{
	var asymAlgs = ',RS256,RS384,RS512,ES256,ES384,ES512';
	var symAlgs = ',HS256,HS384,HS512';
	
	var type = zen('AuthenticationType').getValue();
	var authComp = zen('AuthSigning');
	var signing = authComp.getValue();
	
	if (type == "client_secret_jwt") {
		authComp.setProperty('valueList',symAlgs);
		if ((signing != '') && (symAlgs.indexOf(signing)<0)) {
			authComp.setValue('');
		}
		authComp.setHidden(false);
	} else if (type == "private_key_jwt") {
		authComp.setProperty('valueList',asymAlgs);
		if ((signing != '') && (asymAlgs.indexOf(signing)<0)) {
			authComp.setValue('');
		}
		authComp.setHidden(false);
	} else if (zen('GrantType5').getValue()) { // grant type: jwt_authorization
		authComp.setProperty('valueList',(asymAlgs+symAlgs));
		authComp.setHidden(false);
	} else {
		authComp.setProperty('valueList','');
		authComp.setValue('');
		authComp.setHidden(true);
	}
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

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	/// Set focus to the Name field and set default client type.	
	zen("Name").focus();
	if (zen("ClientType").getValue()=='') zen("ClientType").setValue("confidential");
	var isResource = (zen("ClientType").getValue() == "resource");
	zen('groupRedirectArea').setHidden(isResource)
	var hash = parseInt(document.location.hash.slice(1));
	if ((typeof(hash) === 'number') && (hash >= 0) && (hash <= this.NumTabs)) {
		zen('tabBar').tabClicked(hash);
	} else {
		this.tabChanged(0);
	}
	this.changeAuthType();
}

ClientMethod showHide(fieldName) [ Language = javascript ]
{
	var isHidden = zen(fieldName).getProperty('hidden');
	var linkCaption = (isHidden) ? $$$Text('hide') : $$$Text('show');
	zen(fieldName).setHidden(!isHidden);
	zen('link'+fieldName).setProperty('caption', linkCaption);
}

/// User clicked an existing redirect url from the listbox.<br>
/// Set the value into the textbox for editing or removing.
ClientMethod selectRedirectURL() [ Language = javascript ]
{
	this.addRedirectURL = 0;
	zen('groupRedirectURL').setHidden(false);
	var ctrl = zen('RedirectURLs');
	zen('btnRemove').setDisabled(false);
	zen('RedirectURL').setValue(ctrl.getValue());
	zen('RedirectURL').focus();
}

ClientMethod ClientTypeModified() [ Language = javascript ]
{
	var isHidden = (zen('ClientType').getValue() == "resource");
	zen('groupRedirectArea').setHidden(isHidden)
}

/// User clicked the Add URL button to add a new Redirect URL.<br>
/// Clear the textbox to allow user to enter a new one.
ClientMethod newRedirectURL() [ Language = javascript ]
{
	this.addRedirectURL = 1;
	zen('groupRedirectURL').setHidden(false);
	zen('RedirectURLs').setProperty('selectedIndex', -1);
	zen('btnRemove').setDisabled(true);
	zen('RedirectURL').setValue('');
	zen('RedirectURL').focus();
}

/// User clicked the OK button to save a Redirect URL.<br>
/// Clear list selection and hide the edit fields afterwards.
ClientMethod saveRedirectURL() [ Language = javascript ]
{
	var url = zenTrim(zen('RedirectURL').getValue());
	if (!url) {
		alert($$$Text("Nothing to save - please enter a Redirect URL"));
		return;
	}
	var ctrl = zen('RedirectURLs');
	if (this.addRedirectURL) {
		ctrl.appendOption(url,url);	
	} else {
		ctrl.setOption(ctrl.getProperty('selectedIndex'), url, url);
	}
	ctrl.setProperty('selectedIndex', -1);
	this.addRedirectURL = 0;
	zen('groupRedirectURL').setHidden(true);
}

ClientMethod cancelRedirectURL() [ Language = javascript ]
{
	zen('groupRedirectURL').setHidden(true);
	zen('RedirectURLs').setProperty('selectedIndex', -1);
}

/// User clicked the Remove button to remove an entry from the listbox.
ClientMethod removeRedirectURL() [ Language = javascript ]
{
	var url = zenTrim(zen('RedirectURL').getValue());
	if (!url) {
		alert($$$Text("Nothing to remove"));
		return;	
	}
	var ctrl = zen('RedirectURLs');
	var currIndex = ctrl.selectedIndex;
	ctrl.removeOption(currIndex);
	ctrl.setProperty('selectedIndex', -1);
	this.addRedirectURL = 0;
	zen('groupRedirectURL').setHidden(true);
	this.modified();
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zen("browseselect").getValue();
			zen(name).setValue(value);
			this.modified();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Retrieve an updated public JWKS
ClientMethod doUpdateJWKS() [ Language = javascript ]
{
	try {
		var valueProxy = new zenProxy();
		valueProxy.ClientId = zenTrim(zen("ClientId").getValue());
		var proxy = this.UpdateJWKS(valueProxy);
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

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod doSave(action) As %Boolean [ Language = javascript ]
{
	try {
		var ok = 1;
		var valueProxy = new zenProxy();
		var pass = true;
		var fields = '';
		if (!this.validateRequired(zen("Name"),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'Name';
		}
		if (!this.validateRequired(zen("ClientType"),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'ClientType';
		}
		if (zen("ClientType").getValue() != "resource") {
			var SupportedGrantTypes = "";
			if (zen("GrantType1").getValue()) SupportedGrantTypes = zen("GrantType1").aux;
			if (zen("GrantType2").getValue()) SupportedGrantTypes += zen("GrantType2").aux;
			if (zen("GrantType3").getValue()) SupportedGrantTypes += zen("GrantType3").aux;
			if (zen("GrantType4").getValue()) SupportedGrantTypes += zen("GrantType4").aux;
			if (zen("GrantType5").getValue()) SupportedGrantTypes += zen("GrantType5").aux;
			if (!SupportedGrantTypes) {
				pass = false;
				if (!this.FirstFailed) this.FirstFailed = 'GrantType1';
				fields = fields + ((fields != "") ? ', ' : '') + 'SupportedGrantTypes';
			}
			var ResponseTypes = "";
			if (zen("ResponseType1").getValue()) ResponseTypes += (zen("ResponseType1").aux + ",");
			if (zen("ResponseType2").getValue()) ResponseTypes += (zen("ResponseType2").aux + ",");
			if (zen("ResponseType3").getValue()) ResponseTypes += (zen("ResponseType3").aux + ",");
			if (zen("ResponseType4").getValue()) ResponseTypes += (zen("ResponseType4").aux + ",");
			if (!ResponseTypes) {
				pass = false;
				if (!this.FirstFailed) this.FirstFailed = 'ResponseType1';
				fields = fields + ((fields != "") ? ', ' : '') + 'ResponseTypes';
			}
			var RedirectURL = '';
			var listURL = zen("RedirectURLs");
			var count = listURL.getOptionCount();
			if (count > 0) {
				for (i = 0; i < count; i++) {
					if (listURL.getOptionValue(i)) {
						RedirectURL = RedirectURL + listURL.getOptionValue(i) + "^";
					}
				}
			}
			if (!RedirectURL) {
				pass = false;
				if (!this.FirstFailed) this.FirstFailed = 'RedirectURLs';
				fields = fields + ((fields != "") ? ', ' : '') + 'RedirectURLs';			
			}
		}
		if (!pass) {
			// display standard error message on top
			this.ValidationErrorMsg = $$$Text('Required fields missing: ') + fields;
			this.afterValidate();
			return;
		}
		valueProxy.SupportedGrantTypes = SupportedGrantTypes;
		valueProxy.ResponseTypes = ResponseTypes;
		valueProxy.RedirectURL = RedirectURL;
		
		valueProxy.AuthSigning = zenTrim(zen("AuthSigning").getValue());
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
	
		valueProxy.Name = zenTrim(zen("Name").getValue());
		valueProxy.ClientId = zenTrim(zen("ClientId").getValue());
		valueProxy.ClientSecret = zenTrim(zen("ClientSecret").getValue());
		valueProxy.ClientType = zenTrim(zen("ClientType").getValue());
		valueProxy.DefaultScope = zenTrim(zen("DefaultScope").getValue());
		valueProxy.Description = zenTrim(zen("Description").getValue());
		valueProxy.LaunchURL = zenTrim(zen("LaunchURL").getValue());
		valueProxy.ClientName = zenTrim(zen("ClientName").getValue());
		valueProxy.AuthenticationType = zenTrim(zen("AuthenticationType").getValue());
		valueProxy.LogoUri = zenTrim(zen("LogoUri").getValue());
		valueProxy.ClientUri = zenTrim(zen("ClientUri").getValue());
		valueProxy.PolicyUri = zenTrim(zen("PolicyUri").getValue());
		valueProxy.TosUri = zenTrim(zen("TosUri").getValue());
		valueProxy.ClientCredentials = zenTrim(zen("ClientCredentials").getValue());
		valueProxy.Contacts = zenTrim(zen("Contacts").getValue());
		valueProxy.DefaultMaxAge = zenTrim(zen("DefaultMaxAge").getValue());
		valueProxy.FrontChannelUri = zenTrim(zen("FrontChannelUri").getValue());
		valueProxy.FrontChannelSessionRequired = (zen("FrontChannelSessionRequired").getValue()) ? 1 : 0;
		var selJWTOptions = zen("selJWTOptions").getValue();
		switch (selJWTOptions) {
			case '1':
				valueProxy.jwksUri = zen("JWTURL").getValue();
				valueProxy.publicJWKS = '';
				valueProxy.ClientCredentials = '';
				if (!this.validateRequired(zen('JWTURL'),pass,"S")) {
					this.ValidationErrorMsg = $$$Text("JWT Settings: URL is required if source is JWKS from URL");
					pass = false;
				}
				break;
			case '2':
				valueProxy.jwksUri = '';
				valueProxy.publicJWKS = zen('JWTFile').isModified() ? zen('JWTFile').getValue() : '';		
				valueProxy.ClientCredentials = '';
				if (!this.validateRequired(zen('JWTFile'),pass,"S")) {
					this.ValidationErrorMsg = $$$Text("JWT Settings: File is required if source is JWKS from File");
					pass = false;
				}
				break;
			case '3':
				valueProxy.jwksUri = '';
				valueProxy.publicJWKS = '';
				valueProxy.ClientCredentials = zenTrim(zen("ClientCredentials").getValue());
				if (!this.validateRequired(zen('ClientCredentials'),pass,"S")) {
					this.ValidationErrorMsg = $$$Text("JWT Settings: Client credentials is required if source is X509 certificate");
					pass = false;
				}
				break;
			default:
				valueProxy.jwksUri = '';
				valueProxy.publicJWKS = '';
				valueProxy.ClientCredentials = '';
				pass = true;
				break;
		}
		if (!pass) {
			this.afterValidate();
			return false;
		}
		var result = this.SaveData(valueProxy);
		if (result.ok == 1) {
			this.setModified(false);
			if ((typeof(result.Message) != "undefined") && (result.Message != "")) {
				this.showMsg(result.Message,0);
			} else {
				this.doCancel();
			}
		} else {
			this.showMsg(result.ErrorMessage,1);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Show/hide fields after user selected a JWT option
ClientMethod doJWTChange(selection) [ Language = javascript ]
{
	var value = true;
	for (var i=0; i<4; i++) {
		if (i>0) {
			value = (i==selection) ? false : true;
			zen("groupJWT"+i).setHidden(value);
		}
	}
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir),'FileSelect','resizable,width=680,height=750');
}

ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	var opener = this.getOpener();
	if (opener) {
		self.close();
	} else {
		self.document.location = this.ParentURL;
	}
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Client Description")
}

/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("OAuth 2.0 Authorization Server Configuration","%Utility")
	Set tURL = ..Link("%25CSP.UI.Portal.OAuth2.Server.Configuration.zen")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("OAuth 2.0 Server","%Utility")
	Set tURL = ..Link("%25CSP.UI.Portal.OAuth2.Server.ClientList.zen")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"))
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..isNew = (..ClientId = "")
	Set titleAdd = $$$TextHTML("Use the form below to create a new client description which has been registered with the OAuth 2.0 authorization server:")
	Set titleEdit = $$$TextHTML("Use the form below to edit an existing client description which has been registered with the OAuth 2.0 authorization server:")
	Set ..lblTitle = $S(..isNew=1:titleAdd,1:titleEdit)
	Set ..ParentURL = ..Link("%25CSP.UI.Portal.OAuth2.Server.ClientList.zen")
	If ..ClientId '= "", ##class(OAuth2.Server.Client).%ExistsId(..ClientId) {
		Set sys = ##class(OAuth2.Server.Client).Open(..ClientId)
	} Else {
		Set sys = ##class(OAuth2.Server.Client).%New()
	}
	Set ..%GetComponentById("Name").value = sys.Name
	Set ..%GetComponentById("Description").value = sys.Description
	Set ..%GetComponentById("ClientId").value = sys.ClientId
	Set ..%GetComponentById("ClientSecret").value = sys.ClientSecret
	Set ..%GetComponentById("ClientType").value = sys.ClientType
	Set ..%GetComponentById("DefaultScope").value = sys.DefaultScope
	Set ..%GetComponentById("LaunchURL").value = sys.LaunchURL
	Set ..%GetComponentById("ClientName").value = sys.Metadata."client_name"
	Set ..%GetComponentById("AuthenticationType").value = sys.Metadata."token_endpoint_auth_method"
	Set ..%GetComponentById("LogoUri").value = sys.Metadata."logo_uri"
	Set ..%GetComponentById("ClientUri").value = sys.Metadata."client_uri"
	Set ..%GetComponentById("PolicyUri").value = sys.Metadata."policy_uri"
	Set ..%GetComponentById("TosUri").value = sys.Metadata."tos_uri"
	Set ..%GetComponentById("Contacts").value = ##class(%OAuth2.Utils).ListToComma(sys.Metadata.contacts)
	Set ..%GetComponentById("DefaultMaxAge").value = sys.Metadata."default_max_age"
	Set ..%GetComponentById("FrontChannelUri").value = sys.Metadata."frontchannel_logout_uri"
	Set ..%GetComponentById("FrontChannelSessionRequired").value = sys.Metadata."frontchannel_logout_session_required"
	
	If ..isNew {
		Set ..%GetComponentById("AuthenticationType").value = "client_secret_basic"
		Set ..%GetComponentById("GrantType1").value = 1
		Set ..%GetComponentById("AuthSigning").value = ""
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
	} Else {
		Set ..%GetComponentById("AuthSigning").value = sys.Metadata."token_endpoint_auth_signing_alg"
		If sys.Metadata."id_token_signed_response_alg"'="" {
			Set ..%GetComponentById("IDTokenSigning").value = sys.Metadata."id_token_signed_response_alg"
		}
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
	}

	Set grantTypes=sys.SupportedGrantTypes
	For i = 1:1:$length(sys.SupportedGrantTypes) {
		Set value = $extract(grantTypes,i)
		If value '= "" {
			Set:value="A" ..%GetComponentById("GrantType1").value = 1
			Set:value="I" ..%GetComponentById("GrantType2").value = 1
			Set:value="P" ..%GetComponentById("GrantType3").value = 1
			Set:value="C" ..%GetComponentById("GrantType4").value = 1
			Set:value="J" ..%GetComponentById("GrantType5").value = 1
		}
	}
	If ..isNew {
		Set ..%GetComponentById("ResponseType1").value = 1
		Set ..%GetComponentById("ResponseType2").value = 1
		Set ..%GetComponentById("ResponseType3").value = 1
		Set ..%GetComponentById("ResponseType4").value = 1
	} Else {
		For i = 1:1:4 {
			Set value = $listget(sys.Metadata."response_types",i)
			If value '= "" {
				Set:value="code" ..%GetComponentById("ResponseType1").value = 1
				Set:value="id_token" ..%GetComponentById("ResponseType2").value = 1
				Set:value="id_token token" ..%GetComponentById("ResponseType3").value = 1
				Set:value="token" ..%GetComponentById("ResponseType4").value = 1
			}
		}
	}
	Set totalURL = sys.RedirectURL.Count()
	For item = 1:1:totalURL {
		Set option = ##class(%ZEN.Auxiliary.option).%New()
		Set (option.value, option.text) = sys.RedirectURL.GetAt(item)
		Do %page.%AddComponent(option)
		Do ..%GetComponentById("RedirectURLs").options.Insert(option)
	}
	Set tX509List = ""
	Set tRS = ##class(%ResultSet).%New("%SYS.X509Credentials:ListDetails")
	Do tRS.Execute()
	While tRS.Next() {
		Set tX509List = tX509List _ $S(tX509List'="":",", 1:"")_tRS.GetData(1)	
	}
	Set ..%GetComponentById("ClientCredentials").valueList = tX509List	

	Set ..jwksAvailable=(sys.Metadata."jwks_uri"'="")

	If ..jwksAvailable {
		Set selJWTOptions=1
		Set ..%GetComponentById("JWTURL").value = sys.Metadata."jwks_uri"
		Set ..%GetComponentById("JWTFile").value = ""
		Set ..%GetComponentById("ClientCredentials").value = ""
		Set ..%GetComponentById("ClientCredentials").originalValue = ""
		Set ..%GetComponentById("groupJWT1").hidden = 0
	} ElseIf sys.ClientCredentials'="" {
		Set selJWTOptions=3
		Set ..%GetComponentById("JWTURL").value = ""
		Set ..%GetComponentById("JWTFile").value = ""
		Set ..%GetComponentById("ClientCredentials").value = sys.ClientCredentials
		Set ..%GetComponentById("ClientCredentials").originalValue = sys.ClientCredentials
		Set ..%GetComponentById("groupJWT3").hidden = 0
	} ElseIf sys.PublicJWKS'="" {
		Set selJWTOptions=2
		Set ..%GetComponentById("JWTURL").value = ""
		Set ..%GetComponentById("JWTFile").value = "JWKS already loaded"
		Set ..%GetComponentById("ClientCredentials").value = ""
		Set ..%GetComponentById("ClientCredentials").originalValue = ""
		Set ..%GetComponentById("groupJWT2").hidden = 0
	} Else {
		Set selJWTOptions=""
	}
	Set ..%GetComponentById("selJWTOptions").value = selJWTOptions

	Quit $$$OK
}

/// Call UpdateJWKS method
ClassMethod UpdateJWKS(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#dim sys as OAuth2.Server.Client

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.ClientId = pValueProxy.ClientId
	Set tSC = $$$OK
	
	Set sys = ##class(OAuth2.Server.Client).%OpenId(pValueProxy.ClientId)
	If $isobject(sys) {
		Set server = ##class(OAuth2.Server.Configuration).Open(.tSC)
		If $isobject(server) Do sys.UpdateJWKS(server,.tSC)
	}

	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	} ElseIf '$isobject(sys) {
		Set tProxy.ErrorMessage = $$$Text("No client definition found")
	} ElseIf '$isobject(server) {
		Set tProxy.ErrorMessage = $$$Text("No server configuration found")
	} Else {
		Set tProxy.ok = 1
		Set tProxy.PID = sys.%Id()
		Set tProxy.Message=$$$Text("JWKS updated")
	}
	Kill sys
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Kill sys
	Quit tProxy
}

ClassMethod SaveData(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#dim sys as OAuth2.Server.Client

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.ClientId = pValueProxy.ClientId
	Set tSC = $$$OK
	If ##class(OAuth2.Server.Client).%ExistsId(pValueProxy.ClientId) {
		Set sys = ##class(OAuth2.Server.Client).%OpenId(pValueProxy.ClientId)
		Set tSC = sys.RedirectURL.Clear()
	} Else {
		Set sys = ##class(OAuth2.Server.Client).%New()
		Set sys.ClientId = pValueProxy.ClientId
	}
	Set sys.Name = pValueProxy.Name
	Set sys.ClientSecret = pValueProxy.ClientSecret
	Set sys.ClientType = pValueProxy.ClientType
	Set sys.DefaultScope = pValueProxy.DefaultScope
	Set sys.Description = pValueProxy.Description
	Set tCount = 1
	Set item = $P(pValueProxy.RedirectURL,"^",tCount)
	While item '= "" {
		Do sys.RedirectURL.Insert(item)
		Set tCount = tCount + 1
		Set item = $P(pValueProxy.RedirectURL,"^",tCount)
	}
	Set sys.SupportedGrantTypes = pValueProxy.SupportedGrantTypes
	Set types = ""
	For i=1:1:$length(pValueProxy.ResponseTypes,",") {
		Set type = $piece(pValueProxy.ResponseTypes, "," , i)
		If type '= "" Set types = types _ $lb(type)
	}
	Set sys.Metadata."response_types" = types
	Set sys.LaunchURL = pValueProxy.LaunchURL
	Set sys.Metadata."client_name" = pValueProxy.ClientName
	Set sys.Metadata."token_endpoint_auth_method" = pValueProxy.AuthenticationType
	Set sys.Metadata."logo_uri" = pValueProxy.LogoUri
	Set sys.Metadata."client_uri" = pValueProxy.ClientUri
	Set sys.Metadata."policy_uri" = pValueProxy.PolicyUri
	Set sys.Metadata."tos_uri" = pValueProxy.TosUri
	Set sys.ClientCredentials = pValueProxy.ClientCredentials
	Set sys.Metadata.contacts = ##class(%OAuth2.Utils).CommaToList(pValueProxy.Contacts)
	Set sys.Metadata."default_max_age" = pValueProxy.DefaultMaxAge
	Set sys.Metadata."frontchannel_logout_uri" = pValueProxy.FrontChannelUri
	Set sys.Metadata."frontchannel_logout_session_required" = pValueProxy.FrontChannelSessionRequired

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

	If (pValueProxy.publicJWKS '= "") || (pValueProxy.jwksUri '= "") {
		Set publicJWKS = ""
		If pValueProxy.publicJWKS '= "" {
			If '##class(%CSP.UI.Portal.OAuth2.Server.Client).GetPublicJWKS(pValueProxy.publicJWKS, .publicJWKS) {
				Set tProxy.ErrorMessage = publicJWKS
			}
		}
		If tProxy.ErrorMessage="" {
			Set tSC = sys.SetPublicJWKS(publicJWKS, pValueProxy.jwksUri)
			If $$$ISERR(tSC) {
				Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
			}
		}

	} Else {
		Set sys.Metadata."jwks_uri" = ""
	}

	If tProxy.ErrorMessage="" {
		Set tSC = sys.Save()
		If $$$ISERR(tSC) {
			Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		} Else {
			Set tProxy.ok = 1
		}
	}
	Kill sys
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Kill sys
	Quit tProxy
}

/// Check if file exists. If it does then return the content of the file. Else return error message.
ClassMethod GetPublicJWKS(pFile, Output pFileContent) As %Boolean
{
	Set $ZT="Error"
	Set tStatus = 1
	Set pFileContent = ""
	If '##class(%File).Exists(pFile) {
		Set pFileContent = $$$FormatText($$$Text("File '%1' does not exist."), pFile)
		Set tStatus = 0
	} Else {
		Set stream = ##class(%Stream.FileCharacter).%New()
 		Set stream.Filename = pFile
 		Do stream.Rewind()
 		Set pFileContent = stream.Read()
	}
	Quit tStatus
Error	///
	Set $ZT="" Do BACK^%ETN
	Set pFileContent = $ZCVT($ZE,"O","HTML")
	Quit 0
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")
	If ..jwksAvailable {
		Set pCommands(3) = $LB("spacer","spacer","spacer","true;",1)
		Set pCommands(4) = $LB("btnUpdateJWKS",$$$Text("Update JWKS"),$$$Text("Update public JWKS from client"),"zenPage.doUpdateJWKS();")
	}

	Quit $$$OK
}

}
