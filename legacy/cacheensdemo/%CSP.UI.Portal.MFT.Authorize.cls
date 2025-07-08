/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Page to obtain an access token for a connection to a managed file transfer provider.
Class %CSP.UI.Portal.MFT.Authorize Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Managed File Transfer Authorization";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.MFT.Authorize.zen";

/// Parameter HELPADDRESS = "System Administration,Security";
Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// If it's set to 1 then Save and Cancel buttons will show in top bar
Property IsEditForm As %Boolean [ InitialExpression = 0 ];

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property ConnectionName As %ZEN.Datatype.string(ZENURL = "ConnectionName");

Property PageScope As %ZEN.Datatype.string(ZENURL = "PageScope");

Property AuthorizationCodeURL As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.EditForm {
	background-image: none;	
}
</style>
}

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form autocomplete="false">
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="groupEdit" enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<spacer height="2"/>
<text id="Name" label="Obtain access token for connection:" size="60" maxlength="250" 
hint="A new access token will be obtained for this managed file transfer connection." onchange="zenPage.doModified();zenPage.doCheckToken();"/>
<text id="Scope" label="Scope for access token:" size="60" maxlength="250" value=""
hint="This is the optional scope to be used when obtaining the access token." onchange="zenPage.doModified();"/>
<label id="idAuthorized" enclosingClass="note" value="" containerStyle="padding-bottom:4px;"/>
<spacer height="2"/>
<hgroup>
<button id="btnGetToken" caption="Get Access Token" onclick="zenPage.getAccessToken();"/>
<button id="btnRevokeToken" caption="Revoke Access Token" onclick="zenPage.doRevokeToken();"/>
</hgroup>
<spacer height="2"/>
</group>
</form>
</pane>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	/// Set focus to the Name field	
	zen("Name").focus();
}

ClientMethod getAccessToken() [ Language = javascript ]
{
	this.doCheckToken();

	var name = zen("Name").getValue();
	if (this.AuthorizationCodeURL != "") {
		window.location.href = this.AuthorizationCodeURL;
	}
}

ClientMethod doCheckToken() [ Language = javascript ]
{
	var name = zenTrim(zen("Name").getValue());
	var scope = zenTrim(zen("Scope").getValue());
	if (name != "") {
		var result = this.CheckToken(name,scope);
		if (result.ok == 1) {
			if ((typeof(result.Message) != "undefined") && (result.Message != "")) {
				zen("idAuthorized").setValue(result.Message);
			 	zen("idAuthorized").setHidden(false);
			}
			this.AuthorizationCodeURL = result.AuthorizationCodeURL;
		} else {
			this.showMsg(result.ErrorMessage,1);
			zen("idAuthorized").setValue("");
		 	zen("idAuthorized").setHidden(true);
			zen("Name").focus();
		}
		if (zen("Scope").getValue() == "") {
			zen("Scope").setValue(result.Scope);
		}
	} else {
	 	zen("idRespond").setHidden(true);
		zen("idAuthorized").setValue("");
	 	zen("idAuthorized").setHidden(true);
		zen("Name").focus();
	}
}

ClientMethod doRevokeToken() [ Language = javascript ]
{
	var name = zenTrim(zen("Name").getValue());
	if (name != "") {
		var result = this.RevokeToken(name);
		if (result.ok == 1) {
			if ((typeof(result.Message) != "undefined") && (result.Message != "")) {
				zen("idAuthorized").setValue(result.Message);
			 	zen("idAuthorized").setHidden(false);
			}
		} else {
			this.showMsg(result.ErrorMessage,1);
			zen("idAuthorized").setValue("");
		 	zen("idAuthorized").setHidden(true);
			zen("Name").focus();
		}
	} else {
	 	zen("idRespond").setHidden(true);
		zen("idAuthorized").setValue("");
	 	zen("idAuthorized").setHidden(true);
		zen("Name").focus();
	}
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Managed File Transfer Authorization")
}

/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"))
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set name=..ConnectionName
	If name'="" {
		Set errorMessage=""
		Set ..%GetComponentById("Name").value = name
		Set ..%GetComponentById("Scope").value = ..PageScope
		Set connection=##class(%SYS.MFT.Connection.Base).Open(name,.sc)
		If $$$ISERR(sc) {
			Set errorMessage = $system.Status.GetErrorText(sc)
		}
		If errorMessage="" {
			Set ..AuthorizationCodeURL=..GetAuthorizationCodeURL(connection,connection.DefaultScope(),.sc)
		}
		If $$$ISOK(sc) {
			Set authorized=connection.IsAuthorized(.errorMessage)
			If authorized {
				Set ..%GetComponentById("idAuthorized").value = $$$TextHTML("Connection is authorized.")
			} Else {
				Set ..%GetComponentById("idAuthorized").value = $$$TextHTML("Connection is not authorized.")
			}
			Set ..%GetComponentById("idAuthorized").hidden = 0
		} Else {
			Set errorMessage = $system.Status.GetErrorText(sc)
			Set ..%GetComponentById("idAuthorized").hidden = 1
		}
		Set ..%GetComponentById("idRespond").value = errorMessage
		Set ..%GetComponentById("idRespond").hidden = (errorMessage="")
	} Else {
		Set ..%GetComponentById("idAuthorized").value = ""
		Set ..%GetComponentById("idAuthorized").hidden = 1
		Set ..%GetComponentById("idRespond").value = ""
		Set ..%GetComponentById("idRespond").hidden = 1
		Set ..AuthorizationCodeURL=""
	}

	Set titleEdit = $$$TextHTML("Use the form to request an access token for a managed file transfer connection:")
	Set ..lblTitle = titleEdit
	Set ..ParentURL = ..Link("%25CSP.UI.Portal.Home.zen")
	
	Quit $$$OK
}

/// Get the authorization code url
ClassMethod GetAuthorizationCodeURL(connection As %SYS.MFT.Connection.Base, scope As %String, Output sc As %Status) As %String
{
	Set redirect=$select(%request.Secure:"https://",1:"http://")_%request.GetCgiEnv("HTTP_HOST")
	Set redirect=redirect_##class(%CSP.Page).EscapeURL(%request.Application_$classname())_".zen"
	Set redirect=redirect_"?ConnectionName="_##class(%CSP.Page).EscapeURL(connection.Name)
	Set redirect=redirect_"&PageScope="_##class(%CSP.Page).EscapeURL(scope)
	Quit connection.GetAuthorizationCodeURL(redirect,scope,,.sc)
}

ClassMethod CheckToken(name As %String, scope As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error1"
	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.AuthorizationCodeURL = ""
	Set tProxy.Scope = ""
	Set tSC = $$$OK
	
	#; Check authorization and return message
	If name'="" {
		Set errorMessage=""
		Set connection=##class(%SYS.MFT.Connection.Base).Open(name,.sc)
		If $$$ISOK(sc) {
			If scope="" Set scope=connection.DefaultScope(),tProxy.Scope=scope
			Set tProxy.AuthorizationCodeURL=..GetAuthorizationCodeURL(connection,scope,.sc)
			If $$$ISOK(sc) {
				Set authorized=connection.IsAuthorized(.errorMessage)
			} Else {
				Set errorMessage = $system.Status.GetErrorText(sc)
				Set authorized=0
			}
			If errorMessage = "" {
				Set tProxy.ok = 1
			}
			If authorized {
				Set tProxy.Message = $$$TextHTML("Connection is authorized.")
			} Else {
				Set tProxy.Message = $$$TextHTML("Connection is not authorized.")
			}
		} Else {
			Set errorMessage = $$$Text("Unable to open connection: ")_name
		}
		Set tProxy.ErrorMessage = $ZCVT(errorMessage,"O","HTML")
	}
	Quit tProxy

Error1	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

ClassMethod RevokeToken(name As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tSC = $$$OK

	If name'="" {
		Set errorMessage=""
		Set connection=##class(%SYS.MFT.Connection.Base).Open(name,.tSC)
		If $$$ISOK(tSC) {
			Set tSC = connection.RevokeToken()
			If $$$ISERR(tSC) {
				Set errorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
			} Else {
				Set tProxy.ok = 1
				Set tProxy.Message = $$$TextHTML("Connection is not authorized.")
			}
		} Else {
			Set errorMessage = $$$Text("Unable to open connection: ")_name
		}
		Set tProxy.ErrorMessage = errorMessage
	} Else {
		Set tProxy.ErrorMessage = $$$TextHTML("Connection name must be specified.")
	}
	
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

}
