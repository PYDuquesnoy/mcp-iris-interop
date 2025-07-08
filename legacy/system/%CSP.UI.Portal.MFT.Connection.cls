/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Page to define Managed File Transfer Connections.
Class %CSP.UI.Portal.MFT.Connection Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Managed File Transfer Connection";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.MFT.Connection.zen";

Parameter HELPADDRESS = "System Administration,Security,Managed File Transfer Connections,Managed File Transfer Connection";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.MFT.ConnectionList.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

/// ID for edit. Null if adding new configuration.
Property PID As %String(ZENURL = "PID");

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
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="groupEdit" enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<spacer height="2"/>
<text id="Name" label="Connection name" hint="Required. The name of this connection." size="60" onchange="zenPage.doModified();"/>
<select id="Service" label="File management service" hint="Required. The name of the file management service to be used for this connection." valueList="Dropbox,Kiteworks,Box" onchange="zenPage.doModified();" />
<select id="SSLConfiguration" label="SSL/TLS configuration" hint="Required." onchange="zenPage.doModified();"/>
<text id="Username" label="Email address" size="60" hint="Required.  The email address that represents the application." onchange="zenPage.doModified();"/>
<text id="URL" label="Base URL" size="60" hint="Required. The base URL to access this service." onchange="zenPage.doModified();"/>
<spacer height="2"/>
<text id="ApplicationName" label="OAuth 2.0 application name" size="40" maxlength="50" hint="Required. The application name of the OAuth 2.0 client used for this connection." onchange="zenPage.doModified();"/>
<text id="ClientId" label="OAuth 2.0 client ID" size="60" hint="Required." onchange="zenPage.doModified();"/>
<text id="ClientSecret" label="OAuth 2.0 client secret" size="99" hint="Required." onchange="zenPage.doModified();"/>
<fieldSet id="id_Redirection" label="OAuth 2.0 redirect URL" >
<group>
<label id="id_ServerRedirect" value="The client URL to be specified to the authorization server to receive responses." enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<textarea id="redirectURL" readOnly="true" rows="2" cols="80"/>
<checkbox id="UseSSL" label="Use TLS/SSL" onchange="zenPage.getRedirectURL();zenPage.doModified();"/>
<hgroup cellStyle="padding-right:5px;">
<text id="addr" label="Host name" hint="Required." onchange="zenPage.getRedirectURL();zenPage.doModified();"/>
<text id="port" label="Port" hint="Optional." onchange="zenPage.getRedirectURL();zenPage.doModified();"/>
<text id="prefix" label="Prefix" hint="Optional." onchange="zenPage.getRedirectURL();zenPage.doModified();"/>
</hgroup>
</group>
</fieldSet>
<spacer height="2"/>
</group>
</form>
</pane>
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
ClientMethod doSave() [ Language = javascript ]
{
	try {	
		var PID = this.PID;
		var pass = true;
		var fields = '';
		if (!this.validateRequired(zen('Name'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'Connection name';
		}
		if (!this.validateRequired(zen('Service'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'File management service';
		}
		if (!this.validateRequired(zen('SSLConfiguration'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'SSL/TLS configuration';
		}
		if (!this.validateRequired(zen('Username'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'Email address';
		}
		if (!this.validateRequired(zen('URL'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'Base URL';
		}
		if (!this.validateRequired(zen('ApplicationName'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'OAuth 2.0 application name';
		}
		if (!this.validateRequired(zen('ClientId'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'OAuth 2.0 client ID';
		}
		if (!this.validateRequired(zen('ClientSecret'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'OAuth 2.0 client secret';
		}
		if (!this.validateRequired(zen('addr'),pass,"S")) {
			pass = false;
			fields = fields + ((fields != "") ? ', ' : '') + 'redirect URL';
		}

		if (!pass) {
			this.ValidationErrorMsg = $$$Text('Required fields missing: ') + fields;
			this.afterValidate();
			return;
		}
		var valueProxy = new zenProxy();
		valueProxy.PID = PID;
		valueProxy.Name = zenTrim(zen("Name").getValue());
		valueProxy.Service = zenTrim(zen("Service").getValue());
		valueProxy.SSLConfiguration = zenTrim(zen("SSLConfiguration").getValue());
		valueProxy.Username = zenTrim(zen("Username").getValue());
		valueProxy.URL = zenTrim(zen("URL").getValue());
		valueProxy.ApplicationName = zenTrim(zen("ApplicationName").getValue());
		valueProxy.ClientId = zenTrim(zen("ClientId").getValue());
		valueProxy.ClientSecret = zenTrim(zen("ClientSecret").getValue());
		valueProxy.UseSSL = zen("UseSSL").getValue();
		valueProxy.addr = zenTrim(zen("addr").getValue());
		valueProxy.port = zenTrim(zen("port").getValue());
		valueProxy.prefix = zenTrim(zen("prefix").getValue());

		var proxy = this.SaveData(valueProxy);
		if (proxy.ok == 1) {
			if (proxy.Message != "") {
				this.showMsg(proxy.Message,0);
			} else {
				this.doFinish();
			}
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Initialize.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (!this.isNew) {
		this.disableServer(true);
	}
}

/// Enable server fields only if user clicked Edit button
ClientMethod disableServer(flag) [ Language = javascript ]
{
	zen("Name").setProperty('disabled',flag);
	zen("Service").setProperty('disabled',flag);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	#; If a PID is purposely removed when this page is rendered, then set isNew to true.
	If ..PID = "" Set ..isNew = 1
	
	// Load data into fields
	Set tSC = ..LoadData(..PID,.sys)
	If $$$ISOK(tSC) {
		Set ..%GetComponentById("idRespond").hidden = 1
		Set ..%GetComponentById("groupEdit").hidden = 0
	} Else {
		Set ..%GetComponentById("idRespond").value = $System.Status.GetErrorText(tSC)
		Set ..%GetComponentById("idRespond").hidden = 0
		Set ..%GetComponentById("groupEdit").hidden = 1
	}

	Set titleAdd = $$$TextHTML("Use the form below to create a new file management connection and associated OAuth 2.0 client:")
	Set titleEdit = $$$TextHTML("Use the form below to edit an existing file management connection and associated OAuth 2.0 client")
	Set ..lblTitle = $S(..isNew=1:titleAdd,1:titleEdit_":")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$TextHTML("Managed File Transfer Connection")
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

	Set tPageName = $$$Text("Connection List","%Utility")
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

/// Used when Editing an existing connection. Load previously defined values into fields.
Method LoadData(PID As %String, Output sys) As %Status
{
	Set $ZT="Error"
	If '%page.isNew {
		Set sys = ##class(%SYS.MFT.Connection.Base).Open(PID)
		If '$isobject(sys) {
			Quit $$$TextHTML("Cannot open object!")
		}
	} Else {
		Set sys = ##class(%SYS.MFT.Connection.Base).%New()
	}

	Set tRS = ##class(%ResultSet).%New("Security.SSLConfigs:List")
	Do tRS.Execute("*")
	Set SSLConfigurations = ""
	While tRS.Next() {
		If tRS.GetData(1) '= "",tRS.GetData(6) = 0 {
			Set SSLConfigurations = SSLConfigurations _ $S(SSLConfigurations'="":",",1:"") _ tRS.GetData(1)	
		}
	}

	Set ..%GetComponentById("Name").value = sys.Name
	Set ..%GetComponentById("Service").value = sys.Service
	Set ..%GetComponentById("SSLConfiguration").valueList = SSLConfigurations
	Set ..%GetComponentById("SSLConfiguration").value = sys.SSLConfiguration
	Set ..%GetComponentById("Username").value = sys.Username
	Set ..%GetComponentById("URL").value = sys.URL
	Set ..%GetComponentById("ApplicationName").value = sys.ApplicationName
	Set client=""
	If sys.ApplicationName'="" {
		Set client=##class(OAuth2.Client).Open(sys.ApplicationName,.sc)
		If $$$ISERR(sc) Quit sc
	}
	If $isobject(client) {
		Set ..%GetComponentById("ClientId").value = client.ClientId
		Set ..%GetComponentById("ClientSecret").value = client.ClientSecret
		Set ..%GetComponentById("UseSSL").value = $select(client.RedirectionEndpoint.UseSSL="":1,1:client.RedirectionEndpoint.UseSSL)
		Set ..%GetComponentById("addr").value = client.RedirectionEndpoint.Host
		Set ..%GetComponentById("port").value = client.RedirectionEndpoint.Port
		Set ..%GetComponentById("prefix").value = client.RedirectionEndpoint.Prefix
		Set ..%GetComponentById("redirectURL").value = ..GetRedirectURLforUI(client.RedirectionEndpoint.Host, client.RedirectionEndpoint.Port, client.RedirectionEndpoint.Prefix, client.RedirectionEndpoint.UseSSL)
	} Else {
		Set ..%GetComponentById("ClientId").value = ""
		Set ..%GetComponentById("ClientSecret").value = ""
		Set ..%GetComponentById("UseSSL").value = 1
		Set ..%GetComponentById("addr").value = ""
		Set ..%GetComponentById("port").value = ""
		Set ..%GetComponentById("prefix").value = ""
		Set ..%GetComponentById("redirectURL").value = ""
	}

	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
}

/// Save general association data to server
/// Test can only be done for client, not server. 
ClassMethod SaveData(pValueProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#dim sys as %SYS.MFT.Connection.Base

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.PID = pValueProxy.PID
	Set tSC = $$$OK

	Set serviceClass="%SYS.MFT.Connection."_pValueProxy.Service
	If $classMethod(serviceClass,"%ExistsId",tProxy.PID) {
		Set sys = $classMethod(serviceClass,"Open",pValueProxy.Name,.tSC)
	} Else {
		Set sys = $classMethod(serviceClass,"%New")
	}
	
	If $$$ISOK(tSC) {
		Set sys.Name = pValueProxy.Name
		Set sys.Service = pValueProxy.Service
		Set sys.SSLConfiguration = pValueProxy.SSLConfiguration
		Set sys.Username = pValueProxy.Username
		Set sys.URL = pValueProxy.URL
		
		Set newClient=((sys.ApplicationName="") || (sys.ApplicationName'=pValueProxy.ApplicationName))
		If 'newClient {
			Set client=##class(OAuth2.Client).Open(sys.ApplicationName,.tSC)
			If $$$ISOK(tSC) {
				If (client.ClientId'=pValueProxy.ClientId) ||
				   (client.ClientSecret'=pValueProxy.ClientSecret) ||
				   (client.SSLConfiguration'=pValueProxy.SSLConfiguration) ||
				   (client.RedirectionEndpoint.Host'=pValueProxy.addr) ||
				   (client.RedirectionEndpoint.Port'=pValueProxy.port) ||
				   (client.RedirectionEndpoint.Prefix'=pValueProxy.prefix) ||
				   (client.RedirectionEndpoint.UseSSL'=pValueProxy.UseSSL) {
					Set newClient=1
				}
			}
		}
		
		If newClient {
			Set sys.ApplicationName = pValueProxy.ApplicationName
			Set url=pValueProxy.URL
			If $extract(url,*)="/" Set $extract(url,*)=""
			Set tSC = $classMethod(serviceClass,"CreateClient",
												pValueProxy.ApplicationName,
												pValueProxy.SSLConfiguration,
												pValueProxy.ClientId,
												pValueProxy.ClientSecret,
												url,
												pValueProxy.addr,
												pValueProxy.port,
												pValueProxy.prefix,
												pValueProxy.UseSSL)
		}

		If $$$ISOK(tSC) {
			Set tSC = sys.%Save()
		}
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

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave(0);")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doFinish();")

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
