/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Show Databases Freespace
Class %CSP.UI.Portal.X509Credential Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit X509Credentials";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.X509Credential.zen";

Parameter HELPADDRESS = "Home,Security Management,X.509 Credentials";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.X509Credentials.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

Property msgPassword As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("The two Passwords are not the same. Please type them again.")} ];

/// ID for edit. Null if adding new credentials.
Property PID As %String(ZENURL = "PID");

XData Style
{
<style type="text/css">
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<text id="PID" hidden="true"/>
<text hidden="true" name="browseselect" id="browseselect"/>
<form id="credentialForm" autocomplete="false">
<label id="idRespond" enclosingClass="errorNote" hidden="true" containerStyle="padding-bottom:2px;"/>
<group id="groupEdit" cellStyle="padding:5px;" enclosingClass="EditForm" enclosingStyle="padding-top:2px;" labelPosition="left">
<text id="txtAlias" label="Alias" size="60" maxlength="50" hint="Required." onchange="zenPage.doModified();"/>
<hgroup id="id_Certificate" labelPosition="left" label="File containing X.509 certificate" cellVAlign="top">
<text id="txtCertificate" size="60" hint="Required." onchange="zenPage.doModified();"/>
<button id="btnBrowse1" caption="Browse..." onclick="zenPage.browseSelect('txtCertificate','*.cer');"/>
</hgroup>
<hgroup id="id_Key" labelPosition="left" label="File containing associated private key" cellVAlign="top" >
<text id="txtPrivateKey"  size="60" onkeyup="zenPage.changeKey();"/>
<button id="btnBrowse2" caption="Browse..." onclick="zenPage.browseSelect('txtPrivateKey','*.key');"/>
</hgroup>
<fieldSet id="id_CertData" label="X.509 Certificate Data:" containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" labelPosition="left" hidden="true">
<html OnDrawContent="DrawCerData"/>
</fieldSet>
<hgroup id="id_HasPrivateKey" labelPosition="left" label="Private key present" cellVAlign="top" hidden="false">
<checkbox id="chkHasPrivateKey" valign="top" onchange="zenPage.doModified();"/>
<spacer width="20"/>
<radioSet id="radPrivateKeyType" label="Private key type" valueList="RSA" disabled="true" value="RSA" hidden="true" onchange="zenPage.doModified();"/>
</hgroup>
<vgroup id="id_KeyPassword" labelPosition="left" cellVAlign="top" cellStyle="padding-right:4px;" hidden="true">
<hgroup labelPosition="left" label="Private key password" labelClass="radioSetSpan" >
<text inputtype="password" id="PrivateKeyPassword" onchange="zenPage.doModified();"/>
<spacer width="4"/>
<label label="(Optional)" labelClass="helpText"/>
</hgroup>
<text inputtype="password" id="confirmpassword" label="Private key password (confirm)" labelClass="radioSetSpan" onchange="zenPage.doModified();"/>
</vgroup>
<hgroup id="id_CAFile" label="File containing trusted Certificate Authority X.509 certificate" labelPosition="left" cellVAlign="top" >
<text id="txtCAFile" size="60" onchange="zenPage.doModified();"/>
<button id="CAFileBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('txtCAFile','*.cer');"/>
</hgroup>
<text id="txtOwnerList" label="Authorized user(s)" size="80" onchange="zenPage.doModified();"/>
<text id="txtPeerNames" label="Intended peer(s)" size="80" onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// User changed private key. Show/hide password fields
ClientMethod changeKey() [ Language = javascript ]
{
	var txtPrivateKey = zenPage.getComponentById('txtPrivateKey').getValue();
	var id_KeyPassword = zenPage.getComponentById('id_KeyPassword');
	if (zenTrim(txtPrivateKey) == "") {
		id_KeyPassword.setHidden(true);
	} else {
		id_KeyPassword.setHidden(false);	
	}
	this.doModified();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var PID = this.PID;
	var certData = zenPage.getComponentById("id_CertData");
	if (PID != "") {
		certData.setHidden(false);
		zenPage.getComponentById("txtAlias").setDisabled(true);
		zenPage.getComponentById("id_Certificate").setHidden(true);
		zenPage.getComponentById("id_Key").setHidden(true);
		zenPage.getComponentById("chkHasPrivateKey").setDisabled(true);
		var ok = this.UpdateDetails(PID);	
		if (ok != 1) {
			this.showMsg(ok);
			zen("groupEdit").setHidden(true);
		}
		zenPage.getComponentById("credentialForm").clearModified();
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	#; If a PID is purposely removed when this page is rendered, then set it isNew to true.
	If ..PID = "" Set ..isNew = 1

	If ..isNew {
		Set ..%GetComponentById("id_HasPrivateKey").hidden = 1
		Set ..lblTitle = $$$Text("Use the form below to create a new set of X.509 credentials:")
		Set ..HelpAddress = "Home,Security Management,X.509 Credentials,Add X.509 Credentials"
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to edit an existing set of X.509 credentials:")
		Set ..HelpAddress = "Home,Security Management,X.509 Credentials,Edit X.509 Credentials"
	}
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..isNew {
		Quit $$$Text("New X.509 Credentials")
	} Else {
		Quit $$$Text("Edit X.509 Credentials")
	}
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

	Set tPageName = $$$Text("X.509 Credentials","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_"?PID="_$ZCVT($G(%request.Data("PID",1)),"O","URL")))
	Quit $$$OK
}

/// Used to draw title for this page. pHalpAddress is need to build the link for Help for this page.
ClassMethod DrawTitle1(pSeed As %String) As %Status
{
	Do %application.DrawTitle(%page.LocatorHeader_"^"_%page.HelpAddress)
	Quit $$$OK
}

/// For edit, draw certificate data
Method DrawCerData(pSeed As %String) As %Status
{
	
	If %page.isNew = 1 Quit 1
	Set pid = %page.PID
	If ##class(%SYS.X509Credentials).%ExistsId(pid) {
		Set tContainer = ##class(%SYS.X509Credentials).%OpenId(pid)
		Set SerialNumber = tContainer.SerialNumber
		Set IssuerDN = tContainer.IssuerDN
		Set SubjectDN = tContainer.SubjectDN
		Set ValidityNotAfter = tContainer.ValidityNotAfter
	} Else {
		Set SerialNumber = "<< "_$$$TextHTML("Cannot open id!")_" >>"
		Set IssuerDN = ""
		Set SubjectDN = ""
		Set ValidityNotAfter = ""
	}
	&html<<table class="DetailTable" border="0" cellpadding="2" cellspacing="5">
	<tr valign="top">
	<td nowrap>#($$$TextHTML("Serial number"))#:</td>
	<td >#($ZCVT(SerialNumber,"O","HTML"))#</td>
	</tr>
	<tr valign="top">
	<td nowrap>#($$$TextHTML("Issuer distinguished name"))#:</td>
	<td>#($ZCVT(IssuerDN,"O","HTML"))#</td>
	</tr>	
	<tr valign="top">
	<td nowrap>#($$$TextHTML("Subject distinguished name"))#:</td>
	<td>#($ZCVT(SubjectDN,"O","HTML"))#</td>
	</tr>	
	<tr valign="top">
	<td nowrap>#($$$TextHTML("Not Valid After"))#:</td>
	<td>#($ZCVT(ValidityNotAfter,"O","HTML"))#</td>
	</tr>	
	</table>>
	Quit 1
}

/// Get user selection and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		var pid = this.PID;
		var txtAlias = zen("txtAlias");
		var txtCertificate = zen("txtCertificate");
		var txtPrivateKey = zen("txtPrivateKey");
		var ok = 1;
		var pass = true;
		// if entering a new set of credentials, check if required fields are filled.
		if (this.isNew == 1) {
			//isnew = 1;
			if (!this.validateRequired(txtAlias,pass,"S")) pass = false;
			if (!this.validateRequired(txtCertificate,pass,"S")) pass = false;
		} 
		if (!pass) {
			// display standard error message on top
			this.showMsg(this.ValidationErrorMsg,1);
			var field = this.FirstFailed;
			zen(field).focus();
			return;
		} 
		var radPrivateKeyType = zen("radPrivateKeyType").getValue();
		var PrivateKeyPassword = zen("PrivateKeyPassword").getValue();
		var confirmpassword = zen("confirmpassword").getValue();
		if (zenTrim(txtPrivateKey.getValue()) != "") {
			if ((PrivateKeyPassword != "") || (confirmpassword != "")) {
				if (PrivateKeyPassword != confirmpassword) {
					alert(this.msgPassword);
					return;
				}
			}
		}
		var txtOwnerList = zen("txtOwnerList").getValue();
		var txtPeerNames = zen("txtPeerNames").getValue();
		var txtCAFile = zen("txtCAFile").getValue();
		var result = this.SaveData(pid,txtAlias.getValue(),txtCertificate.getValue(),txtPrivateKey.getValue(),radPrivateKeyType,PrivateKeyPassword,txtOwnerList,txtPeerNames,txtCAFile);
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
	alert("ERROR: " + ex);
	}
}

ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	self.document.location = this.ParentURL;
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zen("browseselect").getValue();
			zen(name).setValue(value);
			if (name == "txtPrivateKey") this.changeKey();
			this.doModified();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Save general association data to server
ClassMethod SaveData(pid, pAlias, pCertificate, pPrivateKey, pPrivateKeyType, pPrivateKeyPassword, pOwnerList, pPeerNames, pCAFile) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	
	#dim tContainer as %SYS.X509Credentials

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.PID = pid
	Set tProxy.ErrorMessage = ""
	Set tSC = $$$OK
	If ##class(%SYS.X509Credentials).%ExistsId(pid) {
		Set isNew = 0
		Set tContainer = ##class(%SYS.X509Credentials).%OpenId(pid)
	} Else {
		Set isNew = 1
		//For new credential, load certificate and key!
		Set tContainer = ##class(%SYS.X509Credentials).%New()
		Set tContainer.Alias = pAlias
		Set tSC = tContainer.LoadCertificate(pCertificate)
		/// If LoadCertificate method returns file not open code then construct the error message
		If $$$ISERR(tSC),$System.Status.GetErrorCodes(tSC) = 5005 {
			Set tProxy.ErrorMessage = $$$FormatText($$$Text("Cannot open file '%1'."),..EscapeHTML(pCertificate))
		}
		If $$$ISOK(tSC),pPrivateKey'="" Set tSC=tContainer.LoadPrivateKey(pPrivateKey)
	}
	If $$$ISERR(tSC) {
		/// Any other errors should be logged here and abort
		Set:tProxy.ErrorMessage="" tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
		Kill tContainer
		Quit tProxy	
	}
	If isNew {
		If pPrivateKeyType = "" Set pPrivateKeyType = "RSA"
		Set tContainer.PrivateKeyType = pPrivateKeyType
		If pPrivateKey'="" Set tContainer.PrivateKeyPassword = pPrivateKeyPassword
	}
	Set tContainer.OwnerList = pOwnerList
	Set tContainer.PeerNames = pPeerNames
	Set tContainer.CAFile = pCAFile
	Set tSC = tContainer.Save()
	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
	} Else {
		Set tProxy.ok = 1
		Set tProxy.PID = tContainer.%Id()
	}
	Kill tContainer
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	/// If an unexpected error is trapped, check the error type and return error message properly.
	If $ZE [ "<NOTOPEN>" {
		Set tProxy.ErrorMessage = $$$FormatText($$$Text("Cannot open file '%1'."),..EscapeHTML(pCertificate))
	} Else {
		Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	}
	Quit tProxy
}

/// This method is called when page is loaded.
/// Load data into the fields.
ClassMethod UpdateDetails(pid) As %String [ ZenMethod ]
{
	#dim tContainer as %SYS.X509Credentials
	Set ok = 1
	// try to open the object
	Set tContainer = ##class(%SYS.X509Credentials).%OpenId(pid)
	If '$IsObject(tContainer) {
		Set ok = $$$TextHTML("Cannot open object!")
		&js<zenPage.disableCommandButton("btnSave");>	
	} Else {
		Set Alias = tContainer.Alias	
		Set OwnerList = tContainer.OwnerList
		Set PeerNames = tContainer.PeerNames
		Set HasPrivateKey = tContainer.HasPrivateKey
		Set CAFile = tContainer.CAFile
		&js<
		zenPage.getComponentById('txtAlias').setValue('#($ZCVT(Alias,"O","JS"))#');	
		zenPage.getComponentById('id_HasPrivateKey').setHidden(false);
		zenPage.getComponentById('chkHasPrivateKey').setValue('#(HasPrivateKey)#');
		zenPage.getComponentById('txtOwnerList').setValue('#($ZCVT(OwnerList,"O","JS"))#');
		zenPage.getComponentById('txtPeerNames').setValue('#($ZCVT(PeerNames,"O","JS"))#');
		zenPage.getComponentById('txtCAFile').setValue('#($ZCVT(CAFile,"O","JS"))#');
		>
	}
	Quit ok
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
