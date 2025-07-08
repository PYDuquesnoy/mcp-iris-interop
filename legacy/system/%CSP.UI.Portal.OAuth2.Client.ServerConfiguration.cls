/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Edit OAuth 2.0 client configuration
Class %CSP.UI.Portal.OAuth2.Client.ServerConfiguration Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "OAuth 2.0 Client Configuration";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Client.ServerConfiguration.zen";

Parameter HELPADDRESS = "System Administration,Security,OAuth 2.0,Client,Server Descriptions";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Client.ServerList.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_OAuth2_Client";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

/// ID for edit. Null if adding new configuration.
Property PID As %String(ZENURL = "PID");

/// MetadataID of the server metadata.
Property MetadataID As %String;

Property jwksAvailable As %Boolean;

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

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form autocomplete="false">
<text hidden="true" name="browseselect" id="browseselect"/>
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="groupEdit" enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<spacer height="2"/>
<text id="IssuerEndpoint" label="Issuer endpoint" hint="Required. Endpoint URL to be used to identify the authorization server." size="60" onchange="zenPage.doModified();"/>
<select id="SSLConfiguration" label="SSL/TLS configuration" hint="Required if SSL used for discovery." onchange="zenPage.doModified();"/>
<text id="InitialAccessToken" label="Registration access token " size="60" hint="Optional." onchange="zenPage.doModified();"/>
<spacer height="2"/>
<fieldSet id="groupServer" label="Authorization server">
<label id="groupServerNote" value="This section describes the authorization server to be used" enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<link id="linkDocumentation" caption="Authorization Server Documentation"/>
<link id="linkPolicy" caption="Authorization Server Policy"/>
<link id="linkTos" caption="Authorization Server Terms of Service."/>
<spacer height="5"/>
<text id="AuthorizationEndpoint" label="Authorization endpoint" size="60" hint="Required." onchange="zenPage.doModified();"/>
<text id="TokenEndpoint" label="Token endpoint" size="60" hint="Required." onchange="zenPage.doModified();"/>
<text id="UserinfoEndpoint" label="Userinfo endpoint" size="60" onchange="zenPage.doModified();"/>
<text id="IntrospectionEndpoint" label="Token introspection endpoint" size="60" onchange="zenPage.doModified();"/>
<text id="RevocationEndpoint" label="Token revocation endpoint" size="60" onchange="zenPage.doModified();"/>
<text id="EndSessionEndpoint" label="End session endpoint" size="60" onchange="zenPage.doModified();"/>
</fieldSet>
<spacer height="2"/>
<fieldSet id="groupJWT" label="JSON Web Token (JWT) Settings" containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" cellStyle="padding-bottom:4px;">
<select id="selJWTOptions" label="Source other than dynamic registration" valueList="1,2,3" displayList="JWKS from URL,JWKS from file,X509 certificate" onchange="zenPage.doModified();zenPage.doJWTChange(zenThis.value);" />
<group id="groupJWT1" hidden="true">
<text id="JWTURL" label="URL:" hint="Required. Enter an URL."/>
</group>
<hgroup id="groupJWT2" hidden="true" label="File containing registration information" cellVAlign="top">
<text id="JWTFile" size="60" hint="Required. Select a file." onchange="zenPage.doModified();"/>
<button id="btnBrowse" caption="Browse..." onclick="zenPage.browseSelect('JWTFile');"/>
</hgroup>
<group id="groupJWT3" hidden="true">
<select id="ServerCredentials" label="Server credentials" onchange="zenPage.doModified();"/>
</group>
</fieldSet>
<spacer height="2"/>
</group>
</form>
<spacer height="6"/>
<vgroup id="nvTable">
<label id="Text2" value="The following is a list of server metadata properties:" containerStyle="padding-bottom:4px;"/>
<tablePane id="table"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
queryClass="OAuth2.Server.Metadata"
queryName="ListProperties"
showValueInTooltip="true"
showZebra="true"
useSnapshot="false"
rowSelect="false"
>
<column colName="Sequence" hidden="true" disableSort="true" />
<column colName="Name" header="Name" style="text-align:left;padding-right:20px;" disableSort="true" />
<column colName="Value" header="Value" style="text-align:left;padding-right:20px;" disableSort="true" />
<parameter value="#(%page.MetadataID)#"/>
 </tablePane>
</vgroup>
</pane>
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

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zen("browseselect").getValue();
			zen(name).setValue(value);
			this.doModified();
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
		valueProxy.PID = this.PID;
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

/// Get user input and send to server to save settings.
ClientMethod doSave(isDiscovery) [ Language = javascript ]
{
	try {	
		var PID = this.PID;
		var pass = true;
		var fields = '';
		if (!this.validateRequired(zen('AuthorizationEndpoint'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'AuthorizationEndpoint';
		}
		if (!this.validateRequired(zen('TokenEndpoint'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'TokenEndpoint';
		}
		if (!this.validateRequired(zen('IssuerEndpoint'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'IssuerEndpoint';
		}

		if (!pass) {
			this.ValidationErrorMsg = $$$Text('Required fields missing: ') + fields;
			this.afterValidate();
			return;
		}
		var valueProxy = new zenProxy();
		valueProxy.PID = PID;
		valueProxy.AuthorizationEndpoint = zenTrim(zen("AuthorizationEndpoint").getValue());
		valueProxy.TokenEndpoint = zenTrim(zen("TokenEndpoint").getValue());
		valueProxy.UserinfoEndpoint = zenTrim(zen("UserinfoEndpoint").getValue());
		valueProxy.IntrospectionEndpoint = zenTrim(zen("IntrospectionEndpoint").getValue());
		valueProxy.RevocationEndpoint = zenTrim(zen("RevocationEndpoint").getValue());
		valueProxy.EndSessionEndpoint = zenTrim(zen("EndSessionEndpoint").getValue());
		valueProxy.IssuerEndpoint = zenTrim(zen("IssuerEndpoint").getValue());
		valueProxy.InitialAccessToken = zenTrim(zen("InitialAccessToken").getValue());
		valueProxy.SSLConfiguration = zenTrim(zen("SSLConfiguration").getValue());
		valueProxy.IsDiscovery = isDiscovery;
		var selJWTOptions = zen("selJWTOptions").getValue();
		fields = '';
		switch (selJWTOptions) {
			case '1':
				valueProxy.jwksUri = zenTrim(zen("JWTURL").getValue());
				valueProxy.publicJWKS = '';
				valueProxy.ServerCredentials = '';
				if (!this.validateRequired(zen('JWTURL'),pass,"S")) {
					pass = false;
					fields = fields + ((fields != "") ? ', ' : '') + 'JWKS URL';
				}
				break;
			case '2':
				valueProxy.jwksUri = '';
				valueProxy.publicJWKS = zenTrim(zen("JWTFile").getValue());
				valueProxy.ServerCredentials = '';
				if (!this.validateRequired(zen('JWTFile'),pass,"S")) {
					pass = false;
					fields = fields + ((fields != "") ? ', ' : '') + 'JWKS File';
				}
				break;
			case '3':
				valueProxy.jwksUri = '';
				valueProxy.publicJWKS = '';
				valueProxy.ServerCredentials = zenTrim(zen("ServerCredentials").getValue());
				if (!this.validateRequired(zen('ServerCredentials'),pass,"S")) {
					pass = false;
					fields = fields + ((fields != "") ? ', ' : '') + 'Server Credentials';
				}
				break;
			default:
				valueProxy.jwksUri = '';
				valueProxy.publicJWKS = '';
				break;
		}
		if (!pass) {
			this.ValidationErrorMsg = $$$Text('Required fields missing: ') + fields;
			this.afterValidate();
			return;
		}
		var proxy = this.SaveData(valueProxy);
		if (proxy.ok == 1) {
			if (proxy.Message != "") {
				this.showMsg(proxy.Message,0);
			} else {
				if (isDiscovery == 0) {
					this.doFinish();
				}
			}
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Enable fields that are only allowed for manual
ClientMethod doManual() [ Language = javascript ]
{
	try {
		this.doHidden(false);
		this.disableServer(false);
	}
	catch(ex) {
	alert("ERROR: " + ex);
	}
}

ClientMethod doHidden(flag) [ Language = javascript ]
{
	try {	
		zen("groupServer").setHidden(flag);
		zen("groupJWT").setHidden(flag);
		zen("nvTable").setHidden(flag);
	}
	catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Get server metadata from OpenID Connect Discovery endpoint of authorization server..
ClientMethod doDiscovery() [ Language = javascript ]
{
	try {	
		var PID = this.PID;
		if (zenTrim(zen('IssuerEndpoint').getValue()) == '') {
			this.showMsg("Issuer endpoint must be specified for discovery",1);
			return;
		}
		if (zenTrim(zen('SSLConfiguration').getValue()) == '') {
			this.showMsg("SSL/TLS configuration must be specified for discovery request",1);
			return;
		}
		
		var valueProxy = new zenProxy();
		valueProxy.PID = PID;
		valueProxy.IssuerEndpoint = zenTrim(zen("IssuerEndpoint").getValue());
		valueProxy.SSLConfiguration = zenTrim(zen("SSLConfiguration").getValue());
		valueProxy.ServerCredentials = zenTrim(zen("ServerCredentials").getValue());
		valueProxy.InitialAccessToken = zenTrim(zen("InitialAccessToken").getValue());
		valueProxy.IsDiscovery = 1;
		
		var proxy = this.Discovery(valueProxy);
		if (proxy.ok == 1) {
			this.doHidden(false);
			if (proxy.Message == "") {
				zen("AuthorizationEndpoint").setValue(proxy.AuthorizationEndpoint)
				zen("TokenEndpoint").setValue(proxy.TokenEndpoint)
				zen("UserinfoEndpoint").setValue(proxy.UserinfoEndpoint)
				zen("IntrospectionEndpoint").setValue(proxy.IntrospectionEndpoint)
				zen("RevocationEndpoint").setValue(proxy.RevocationEndpoint)
				zen("EndSessionEndpoint").setValue(proxy.EndSessionEndpoint)
				zen("linkDocumentation").setHidden(proxy.linkDocumentation == '');
				zen("linkDocumentation").href=proxy.linkDocumentation;
				zen("linkPolicy").setHidden(proxy.linkPolicy == '');
				zen("linkPolicy").href=proxy.linkPolicy;
				zen("linkTos").setHidden(proxy.linkTos == '');
				zen("linkTos").href=proxy.linkTos;
				
				this.setModified(false);
				self.document.location.replace("?PID="+proxy.PID);
				
			} else {
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

/// Set focus to the Name field.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.doHidden(this.isNew);
	if (!this.isNew) {
		this.disableServer(true);
	}
}

/// Enable server fields only if user clicked Edit button
ClientMethod disableServer(flag) [ Language = javascript ]
{
	zen("AuthorizationEndpoint").setProperty('disabled',flag);
	zen("TokenEndpoint").setProperty('disabled',flag);
	zen("UserinfoEndpoint").setProperty('disabled',flag);
	zen("IntrospectionEndpoint").setProperty('disabled',flag);
	zen("RevocationEndpoint").setProperty('disabled',flag);
	zen("EndSessionEndpoint").setProperty('disabled',flag);
	zen("ServerCredentials").setProperty('disabled',flag);
	zen("JWTURL").setProperty('disabled',flag);
	zen("JWTFile").setProperty('disabled',flag);
	zen("btnBrowse").setProperty('disabled',flag);
	zen("selJWTOptions").setProperty('disabled',flag);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	#; If a PID is purposely removed when this page is rendered, then set isNew to true.
	If ..PID = "" Set ..isNew = 1

	// Load data into fields
	Set tSC = ..LoadData(..PID,.sys)
	If '$$$ISOK(tSC) {
		Set ..%GetComponentById("idRespond").value = tSC
		Set ..%GetComponentById("idRespond").hidden = 0
		Set ..%GetComponentById("groupEdit").hidden = 1
	}

	Set titleAdd = $$$TextHTML("Use the form below to create a new OAuth 2.0 server description:")
	Set titleEdit = $$$TextHTML("Use the form below to edit an existing OAuth 2.0 server description")
	If $$$ISOK(tSC),..isNew = 0 {
		Set titleEdit = titleEdit _ " ("_$S(sys.IsDiscovery:$$$Text("created via Discovery)"), 1:$$$Text("entered manually)"))
	}
	Set ..lblTitle = $S(..isNew=1:titleAdd,1:titleEdit_":")

	Set ..%GetComponentById("linkDocumentation").hidden = (sys.Metadata."service_documentation" = "")
	Set ..%GetComponentById("linkPolicy").hidden = (sys.Metadata."op_policy_uri" = "")
	Set ..%GetComponentById("linkTos").hidden = (sys.Metadata."op_tos_uri" = "")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$TextHTML("Server Description")
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
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_"?PID="_..EscapeURL($G(%request.Data("PID",1)))_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Used when Editing an existing OAuth2 client configuration. Load previously defined values into fields.
Method LoadData(PID As %String, Output sys) As %Status
{
	Set $ZT="Error"
	If '%page.isNew {
		If ##class(OAuth2.ServerDefinition).%ExistsId(PID) {
			Set sys = ##class(OAuth2.ServerDefinition).Open(PID)
		} Else {
			Quit $$$TextHTML("Cannot open object!")
		}
	} Else {
		Set sys = ##class(OAuth2.ServerDefinition).%New()
	}

	Set tRS = ##class(%ResultSet).%New("Security.SSLConfigs:List")
	Do tRS.Execute("*")
	Set SSLConfigurations = ""
	While tRS.Next() {
		If tRS.GetData(1) '= "",tRS.GetData(6) = 0 {
			Set SSLConfigurations = SSLConfigurations _ $S(SSLConfigurations'="":",",1:"") _ tRS.GetData(1)	
		}
	}

	Set ..%GetComponentById("IssuerEndpoint").value = sys.IssuerEndpoint
	Set ..%GetComponentById("InitialAccessToken").value = sys.InitialAccessToken
	Set ..%GetComponentById("SSLConfiguration").valueList = SSLConfigurations
	Set ..%GetComponentById("SSLConfiguration").value = sys.SSLConfiguration
	Set ..%GetComponentById("AuthorizationEndpoint").value = sys.Metadata."authorization_endpoint"
	Set ..%GetComponentById("TokenEndpoint").value = sys.Metadata."token_endpoint"
	Set ..%GetComponentById("UserinfoEndpoint").value = sys.Metadata."userinfo_endpoint"
	Set ..%GetComponentById("IntrospectionEndpoint").value = sys.Metadata."introspection_endpoint"
	Set ..%GetComponentById("RevocationEndpoint").value = sys.Metadata."revocation_endpoint"
	Set ..%GetComponentById("EndSessionEndpoint").value = sys.Metadata."end_session_endpoint"
	Set tX509List = ""
	Set tRS = ##class(%ResultSet).%New("%SYS.X509Credentials:ListDetails")
	Do tRS.Execute()
	While tRS.Next() {
		Set tX509List = tX509List _ $S(tX509List'="":",", 1:"")_tRS.GetData(1)	
	}
	Set ..%GetComponentById("ServerCredentials").valueList = tX509List

	Set ..%GetComponentById("linkDocumentation").href = sys.Metadata."service_documentation"
	Set ..%GetComponentById("linkPolicy").href = sys.Metadata."op_policy_uri"
	Set ..%GetComponentById("linkTos").href = sys.Metadata."op_tos_uri"

	Set ..MetadataID=sys.Metadata.%Id()

	Set ..jwksAvailable=(sys.Metadata."jwks_uri"'="")

	If ..jwksAvailable {
		Set selJWTOptions=1
		Set ..%GetComponentById("JWTURL").value = sys.Metadata."jwks_uri"
		Set ..%GetComponentById("JWTFile").value = ""
		Set ..%GetComponentById("ServerCredentials").value = ""
		Set ..%GetComponentById("ServerCredentials").originalValue = ""
		Set ..%GetComponentById("groupJWT1").hidden = 0
	} ElseIf sys.ServerCredentials'="" {
		Set selJWTOptions=3
		Set ..%GetComponentById("JWTURL").value = ""
		Set ..%GetComponentById("JWTFile").value = ""
		Set ..%GetComponentById("ServerCredentials").value = sys.ServerCredentials
		Set ..%GetComponentById("ServerCredentials").originalValue = sys.ServerCredentials
		Set ..%GetComponentById("groupJWT3").hidden = 0
	} ElseIf sys.PublicJWKS'="" {
		Set selJWTOptions=2
		Set ..%GetComponentById("JWTURL").value = ""
		Set ..%GetComponentById("JWTFile").value = "JWKS already loaded"
		Set ..%GetComponentById("ServerCredentials").value = ""
		Set ..%GetComponentById("ServerCredentials").originalValue = ""
		Set ..%GetComponentById("groupJWT2").hidden = 0
	} Else {
		Set selJWTOptions=""
	}
	Set ..%GetComponentById("selJWTOptions").value = selJWTOptions

	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
}

/// Call UpdateJWKS method
ClassMethod UpdateJWKS(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#dim sys as OAuth2.ServerDefinition

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.PID = pValueProxy.PID
	Set tSC = $$$OK
	
	Set sys = ##class(OAuth2.ServerDefinition).Open(tProxy.PID)
	If $isobject(sys) {
		Set tSC=sys.UpdateJWKS()
	}

	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	} ElseIf '$isobject(sys) {
		Set tProxy.ErrorMessage = $$$Text("No server definition found")
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

/// Save general association data to server
/// Test can only be done for client, not server. 
ClassMethod SaveData(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#dim sys as OAuth2.ServerDefinition

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.PID = pValueProxy.PID
	Set tSC = $$$OK
	If ##class(OAuth2.ServerDefinition).%ExistsId(tProxy.PID) {
		Set sys = ##class(OAuth2.ServerDefinition).Open(tProxy.PID)
	} Else {
		Set sys = ##class(OAuth2.ServerDefinition).%New()
	}
	Set sys.IssuerEndpoint = pValueProxy.IssuerEndpoint
	Set sys.InitialAccessToken = pValueProxy.InitialAccessToken
	Set sys.SSLConfiguration = pValueProxy.SSLConfiguration
	Set sys.Metadata."authorization_endpoint" = pValueProxy.AuthorizationEndpoint
	Set sys.Metadata."token_endpoint" = pValueProxy.TokenEndpoint
	Set sys.Metadata."userinfo_endpoint" = pValueProxy.UserinfoEndpoint
	Set sys.Metadata."introspection_endpoint" = pValueProxy.IntrospectionEndpoint
	Set sys.Metadata."revocation_endpoint" = pValueProxy.RevocationEndpoint
	Set sys.Metadata."end_session_endpoint" = pValueProxy.EndSessionEndpoint
	Set sys.ServerCredentials = pValueProxy.ServerCredentials
	Set sys.IsDiscovery = pValueProxy.IsDiscovery

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
		Set tSC = sys.%Save()
		If $$$ISERR(tSC) {
			If $$$GETERRORCODE(tSC)=$$$ERRORCODE($$$KeyNotUnique) {
				Set tProxy.ErrorMessage = $ZCVT($$$Text("Not saved.  Issuer endpoint is not unique."),"O","HTML")
			} Else {
				Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
			}
		}
	}
	
	If tProxy.ErrorMessage="" {
		Set tProxy.ok = 1
		Set tProxy.PID = sys.%Id()
	}
	Kill sys
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Kill sys
	Quit tProxy
}

/// Get metadata from authorization discovery endpoint.
ClassMethod Discovery(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.PID = pValueProxy.PID
	Set tSC = $$$OK

	Set tSC=##class(OAuth2.ServerDefinition).GetServerMetadata(pValueProxy.IssuerEndpoint,pValueProxy.SSLConfiguration,.metadata)

	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")

	} Else {
		If ##class(OAuth2.ServerDefinition).%ExistsId(tProxy.PID) {
			Set sys = ##class(OAuth2.ServerDefinition).Open(tProxy.PID)
		} Else {
			Set sys = ##class(OAuth2.ServerDefinition).%New()
		}
		Set sys.IssuerEndpoint = pValueProxy.IssuerEndpoint
		Set sys.SSLConfiguration = pValueProxy.SSLConfiguration
		Set sys.ServerCredentials = pValueProxy.ServerCredentials
		Set sys.InitialAccessToken = pValueProxy.InitialAccessToken
		Set sys.IsDiscovery = 1

		Tstart
		If $isobject(sys.Metadata) {
			Do ##class(OAuth2.Server.Metadata).%DeleteId(sys.Metadata.%Id())
		}
		Set sys.Metadata = metadata

		Set tSC = sys.%Save()

		If $$$ISERR(tSC) {
			Trollback
			If $$$GETERRORCODE(tSC)=$$$ERRORCODE($$$KeyNotUnique) {
				Set tProxy.ErrorMessage = $ZCVT($$$Text("Not saved.  Issuer endpoint is not unique."),"O","HTML")
			} Else {
				Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
			}
		} Else {
			Tcommit
			Set tProxy.ok = 1
			Set tProxy.PID=sys.%Id()
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

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave(0);")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doFinish();")
	Set pCommands(3) = $LB("spacer","spacer","spacer","true;",1)
	Set pCommands(4) = $LB("btnDiscovery",$$$Text("Discover and Save"),$$$Text("Get server metadata from the OpenID Connect Discovery endpoint"),"zenPage.doDiscovery();")
	Set pCommands(5) = $LB("btnManual",$S(..isNew:$$$Text("Manual"),1:$$$Text("Edit")),$$$Text("Manually enter the metadata which describes the authorization server"),"zenPage.doManual();")
	If ..jwksAvailable {
		Set pCommands(6) = $LB("spacer","spacer","spacer","true;",1)
		Set pCommands(7) = $LB("btnUpdateJWKS",$$$Text("Update JWKS"),$$$Text("Update public JWKS from authorization server"),"zenPage.doUpdateJWKS();")
	}

	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// Overrid Edit: id as text on tab display below Menu
Method %OnGetTitle() As %String
{
	Quit ..LocatorHeader
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
