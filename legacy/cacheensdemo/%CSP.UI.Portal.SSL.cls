/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Edit SSL/TLS configuration
Class %CSP.UI.Portal.SSL Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "SSL/TLS Configuration";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.SSL.zen";

Parameter HELPADDRESS = "System Administration,Security,SSL/TLS Configurations";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.SSLList.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// Flag to indicate what to do with the Test and Save button.
/// -1 = Both disabled; 0 = Test disabled; -10 = Test hidden; 1 = Test enabled
Property AllowTest As %Integer [ InitialExpression = 1 ];

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

/// isMirror is 1 if this window is called from Mirroring Settings
Property isMirror As %ZEN.Datatype.boolean(ZENURL = "isMirror") [ InitialExpression = "0" ];

/// ID for edit. Null if adding new configuration.
Property PID As %String(ZENURL = "PID");

/// Indicate if password is modified. If pwModified is 0 then at save time we won't save password.
Property pwModified As %ZEN.Datatype.boolean [ InitialExpression = "0" ];

/// Keep TLSMinVersion
Property Min As %String;

/// Keep TLSMinVersion
Property Max As %String;

/// Default Ciphersuites value
Property CipherDefault As %String;

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<hidden name="browseselect" id="browseselect"/>
<label id="result" controlClass="redText" value=""/>
<form autocomplete="false">
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;" controlStyle="white-space:pre-line;"/>
<group id="groupEdit" enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<spacer height="2"/>
<text id="Name" label="Configuration Name" size="60" maxlength="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="Description" label="Description" size="60" onchange="zenPage.doModified();"/>
<checkbox id="Enabled" label="Enabled" onchange="zenPage.doModified();"/>
<radioSet id="Type" label="Type" displayList="Client,Server" valueList="0,1" value="0" onchange="zenPage.doModified();zenPage.changeType();"/>
<radioSet id="VerifyPeer" label="Server certificate verification" displayList="None,Require" valueList="0,1" value="0" onchange="zenPage.doModified();zenPage.changePeer();"/>
<radioSet id="VerifyPeer1" label="Client certificate verification" displayList="None,Request,Require" valueList="0,1,3" value="0" hidden="true" onchange="zenPage.doModified();zenPage.changePeer();"/>
<hgroup id="id_CAFile" labelPosition="left" label="File containing trusted Certificate Authority certificate(s)" cellVAlign="top" >
<text id="CAFile" size="60" onkeyup="zenPage.changedCAFile();" onchange="zenPage.doModified();"/>
<button id="CAFileBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('CAFile','*.cer');"/>
</hgroup>
<hgroup id="id_CRLFile" labelPosition="left" label="File containing Certificate Revocation List" cellVAlign="top" hidden="true">
<text id="CRLFile" size="60" onchange="zenPage.doModified();"/>
<button id="CRLFileBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('CRLFile','*.cer');"/>
</hgroup>
<fieldSet id="id_Type" label="This client's credentials:" containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" labelPosition="top">
<label id="id_TypeNote" value="" enclosingClass="normal" enclosingStyle="padding-bottom:4px;"/>
<hgroup id="id_File" labelPosition="left" label="File containing this client's certificate" cellVAlign="top" containerStyle="padding-top:4px;padding-bottom:4px;" >
<text id="CertificateFile" onkeyup="zenPage.changedFile()" size="59" onchange="zenPage.doModified();"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('CertificateFile','*.cer');"/>
</hgroup>
<hgroup id="id_Key" labelPosition="left" label="File containing associated private key" cellVAlign="top" cellStyle="padding-bottom:4px;" >
<text id="PrivateKeyFile" size="59" onchange="zenPage.doModified();"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('PrivateKeyFile','*.key');"/>
</hgroup>
<vgroup labelPosition="left" showLabel="false">
<radioSet id="PrivateKeyType" label="Private key type" displayList="RSA,DSA" valueList="2,1" value="2" onchange="zenPage.doModified();"/>
<radioSet id="PWOptions" label="Password:" displayList="Enter new password,Clear password,Leave as is" valueList="2,1,0" value="0" onchange="zenPage.doModified();zenPage.togglePW();"/>
<vgroup id="id_Password" showLabel="false" labelPosition="left" hidden="true">
<text inputtype="password" id="PrivateKeyPassword" label="Private key password" onchange="zenPage.doModified();zenPage.changePW();" />
<text inputtype="password" id="PrivateKeyPassword1" label="Private key password (confirm)" onchange="zenPage.doModified();zenPage.changePW();"/>
</vgroup>
</vgroup>
</fieldSet>

<fieldSet id="id_CipherList" label="Cryptographic settings" containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" labelPosition="left">
<combobox id="TLSMinVersion" label="Minimum Protocol Version" editable="true" unrestricted="true" size="10" width="100" dropdownHeight="100" onchange="zenPage.changeVersion(1);"/>
<combobox id="TLSMaxVersion" label="Maximum Protocol Version" editable="true" unrestricted="true" size="10" width="100" dropdownHeight="100" onchange="zenPage.changeVersion(0);"/>
<text id="CipherList" label="Enabled cipherlist (TLSv1.2 and below)" size="60" hidden="true" onchange="zenPage.doModified();"/>
<text id="Ciphersuites" label="Enabled ciphersuites (TLSV1.3)" size="70" hidden="true" onchange="zenPage.doModified();"/>
<radioSet id="DHBits" label="Diffie Hellman Bits" displayList="Auto,512,1024,2048,4096" valueList="0,512,1024,2048,4096" value="0" hidden="true" onchange="zenPage.doModified();"/>
</fieldSet>

<fieldSet id="id_OcspSettings" label="OCSP settings" containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" labelPosition="left">
<checkbox id="OCSP" label="OCSP Stapling" onchange="zenPage.doModified();zenPage.toggleOCSP();"/>
<hgroup id="id_Issuer" labelPosition="top" label="File containing the issuer certificate" cellVAlign="top" containerStyle="padding-top:4px;padding-bottom:4px;" hidden="true">
<text id="IssuerFile" size="59" onchange="zenPage.doModified();"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('IssuerFile','*.cer');"/>
</hgroup>
<hgroup id="id_Resp" labelPosition="top" label="Path to store cached OCSP response" cellVAlign="top" containerStyle="padding-top:4px;padding-bottom:4px;" hidden="true">
<text id="RespFile" size="59" onchange="zenPage.doModified();"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('RespFile','*.der');"/>
</hgroup>
<text id="OCSPTimeout" label="OCSP Update Timeout" hint="Required. (0-10)" size="8" onchange="zenPage.doModified();" hidden="true"/>
</fieldSet>
<spacer height="2"/>
</group>
</form>
</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zen('browseselect').setValue(name);
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// End Add/Edit and return to list page. If this page is called from Mirror then close window.
ClientMethod doFinish() [ Language = javascript ]
{
	this.setModified(false);
	this.doCancel();
}

/// User changed CAFile. If not null, enable CRL file. OW, disable
ClientMethod changedCAFile() [ Language = javascript ]
{
	var CAFile = zenTrim(zen("CAFile").getValue());
	if (CAFile == "") {
		zen("id_CRLFile").setProperty("disabled",true);
		zen("id_CRLFile").setProperty("labelClass","disablednormal");		
	} else {
		zen("id_CRLFile").setProperty("disabled",false);
		zen("id_CRLFile").setProperty("labelClass","normal");
	}
}

/// User changed CertificateFile. If not null, enable Private password fields. OW, disable
ClientMethod changedFile() [ Language = javascript ]
{
	var CertificateFile = zenTrim(zen("CertificateFile").getValue());
	var PrivateKeyFile = zenTrim(zen("PrivateKeyFile").getValue());
	if (CertificateFile == "" && PrivateKeyFile == "") {
		zen("id_Key").setProperty("disabled",true);
		zen("id_Key").setProperty("labelClass","disablednormal");
	} else {
		zen("id_Key").setProperty("disabled",false);
		zen("id_Key").setProperty("labelClass","normal");
	}
}

/// User changed Peer certificate verification level. 
/// If this is Type Server, and the Peer level is None then disable CAFile field. OW enable.
ClientMethod changePeer() [ Language = javascript ]
{
	var Type = zen('Type').getValue();
	var VerifyPeer = zen('VerifyPeer').getValue();
	if (Type == 1) VerifyPeer = zen('VerifyPeer1').getValue();
	if (VerifyPeer == "") VerifyPeer = 0;
	var id_CAFile = zen('id_CAFile');
	var CAFile = zen('CAFile');
	var CAFileBrowse = zen('CAFileBrowse');
	if (VerifyPeer == 0) {
		id_CAFile.setProperty("labelClass","disablednormal");
		CAFile.setDisabled(true);
		CAFileBrowse.setDisabled(true);
	} else {
		id_CAFile.setProperty("labelClass","normal");
		CAFile.setDisabled(false);
		CAFileBrowse.setDisabled(false);
	}
	if (Type == 0) this.changeVersion(0);
}

/// User changed Type. Show/hide client/server credentials related fields.
ClientMethod changeType() [ Language = javascript ]
{
	//displayList="None,Request,Require" valueList="0,1,3"
	var Type = zen('Type').getValue();
	var VerifyPeer = zen('VerifyPeer');
	var VerifyPeer1 = zen('VerifyPeer1');
	var OCSP = zen('OCSP').getValue();
	var DHBits = zen('DHBits');
	switch(Type) {
		case '0':
			if (this.isMirror==false) VerifyPeer.setHidden(false);
			VerifyPeer1.setHidden(true);
			DHBits.setHidden(true);
			zen('id_Type').setProperty("label",$$$Text("This client's credentials"));
			zen('id_File').setProperty("label",$$$Text("File containing this client's certificate"));
			zen('id_TypeNote').setHidden(false);
			zen("id_Issuer").setHidden(true);
			zen("id_Resp").setHidden(true);
			zen('OCSPTimeout').setHidden(true);
			// if LoadData errored or the button is already hidden then do nothing; Test button can be enabled.
			if (this.AllowTest > -1) this.AllowTest = 1;
			break;
		case '1':
			VerifyPeer.setHidden(true);
			DHBits.setHidden(false);
			if (this.isMirror==false) VerifyPeer1.setHidden(false);
			zen('id_Type').setProperty("label",$$$Text("This server's credentials"));
			zen('id_File').setProperty("label",$$$Text("File containing this server's certificate"));
			zen('id_TypeNote').setHidden(true);
			if (OCSP) {
				zen("id_Issuer").setHidden(false);
				zen("id_Resp").setHidden(false);
				zen('OCSPTimeout').setHidden(false);
			}
			// if LoadData errored or the button is already hidden then do nothing; else Test button can be disabled.
			if (this.AllowTest > -1) this.AllowTest = 0;
			break;
		default:
	}
	this.changeVersion(0);
	this.testButtons();
	this.changePeer();
}

/// User changed password. Update flag. 
ClientMethod changePW() [ Language = javascript ]
{
	this.pwModified = 1;
}

/// User changed PWOptions option. If they want to enter new password, show password fields. Otherwise hide them. 
ClientMethod togglePW() [ Language = javascript ]
{
	var PWOptions = zen("PWOptions").getValue();
	if (PWOptions == 2) {
		zen("id_Password").setHidden(false);
	} else {
		zen("id_Password").setHidden(true);	
	}
}

/// User changed OCSP option. 
ClientMethod toggleOCSP() [ Language = javascript ]
{
	var OCSP = zen("OCSP").getValue();
	var Server = zen("Type").getValue()
	if ((OCSP == 1) && (Server == '1')){
		zen("id_Issuer").setHidden(false);
		zen("id_Resp").setHidden(false);
		zen("OCSPTimeout").setHidden(false);
	} else {
		zen("id_Issuer").setHidden(true);
		zen("id_Resp").setHidden(true);
		zen("OCSPTimeout").setHidden(true);
	}
}

/// Change Min or Max Version
ClientMethod changeVersion(MinVersion) [ Language = javascript ]
{
	try {
		var min = zen("TLSMinVersion").getValue();
		var max = zen("TLSMaxVersion").getValue();
		var Server = zen("Type").getValue();
		var VerifyPeer = zen('VerifyPeer').getValue();
		if (Server == 1) VerifyPeer = zen('VerifyPeer1').getValue();
		if (VerifyPeer == "") VerifyPeer = 0;
		if (MinVersion == 1) {
			if (this.getVersion(min) > this.getVersion(max)) {
				alert("Selected Version is greater than Maximum Version.");
				zen("TLSMinVersion").setValue(this.Min);
				return;
			}
			this.Min = min;
		} else {
			if (this.getVersion(max) < this.getVersion(min)) {
				alert("Selected Version is less than Minimum Version.");
				zen("TLSMaxVersion").setValue(this.Max);
				return;
			}
			this.Max = max;
		}
		if (this.getVersion(max)>16) {
			zen('Ciphersuites').setHidden(false);
		} else {
			zen('Ciphersuites').setHidden(true);
		}
		if (this.getVersion(min)<32) {
			zen('CipherList').setHidden(false);
		} else {
			zen('CipherList').setHidden(true);
		}
		if ((Server == '1') && (this.isMirror == false)) {
			if (this.getVersion(max)<16) {
				zen('OCSP').setProperty("disabled",true);
				zen('OCSP').setProperty("labelClass","disablednormal");
				zen('OCSP').setValue(0);
			} else {
				zen('OCSP').setProperty("disabled",false);
				zen('OCSP').setProperty("labelClass","zenLabel");
			}
		} else {
			if ((VerifyPeer == 0) || (this.getVersion(min)<16)) {
				zen('OCSP').setProperty("disabled",true);
				zen('OCSP').setProperty("labelClass","disablednormal");
				zen('OCSP').setValue(0);
			} else {
				zen('OCSP').setProperty("disabled",false);
				zen('OCSP').setProperty("labelClass","zenLabel");
			}
		}
		this.toggleOCSP();
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

ClientMethod getVersion(value) [ Language = javascript ]
{
	// SML2901+
	if (value == "SSLv3") return 2;
	// SML2901-
	if (value == "TLSv1.0") return 4;
	if (value == "TLSv1.1") return 8;
	if (value == "TLSv1.2") return 16;
	if (value == "TLSv1.3") return 32;
	return 0;
}

/// Get user input and send to server to save settings.
/// If isTest is 1, user clicked the Test button. Then after saving, we'll do a TestConnection.
ClientMethod doSave(isTest) [ Language = javascript ]
{
	try {	
		var PID = this.PID;
		var Name = zen("Name");
		var pass = true;
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('OCSPTimeout'),pass,"N",true,1,10)) pass = false;
		if (!pass) {
			this.afterValidate();
			return;
		}
		var Type = zen("Type").getValue();
		var PrivateKeyPassword = zen("PrivateKeyPassword").getValue();
		var PrivateKeyPassword1 = zen("PrivateKeyPassword1").getValue();
		if (PrivateKeyPassword != PrivateKeyPassword1) {
			alert($$$Text("The two Passwords are not the same. Please type them again."));
			zen("PrivateKeyPassword1").focus();
			return;
		}
		var OCSP = zen("OCSP").getValue();
		var VerifyPeer = zen("VerifyPeer").getValue();
		var TLSMinVersion = zen("TLSMinVersion").getValue();
		var TLSMaxVersion = zen("TLSMaxVersion").getValue();
		if ((Type == 0) && (OCSP == 1)) {
			if (VerifyPeer == 0) {
				alert($$$Text("OCSP Stapling requires Peer Validation."));
				zen("OCSP").focus();
				return;
			}
			if (this.getVersion(TLSMinVersion) < this.getVersion("TLSv1.2")) {
				alert($$$Text("OCSP Stapling incompatible with TLSv1.1 or lower."));
				zen("OCSP").focus();
				return;
			}
		}
		if ((Type == 1) && (OCSP == 1)) {
			if (this.getVersion(TLSMaxVersion) < this.getVersion("TLSv1.2")) {
				alert($$$Text("OCSP Stapling requires TLSv1.2 or higher."));
				zen("OCSP").focus();
				return;
			}
		}
		var ok = 1;
		if (isTest == 1) {
			if ((Type == 0) || (this.isMirror==true)) {
				ok = 0;
				var host = "";
				var port = "";
				host = prompt($$$Text("Test server host name:"));
				// need to test in case user hit Cancel when "undefined" is in the prompt.
				if (host) {
					if (host.length > 0) {
						port = prompt($$$Text("Test server port:"));
						if (port) {
							ok = 1;
						}
					}
				}
			}
		}

		if (ok == 0) return;
		var Name = Name.getValue();
		var Description = zen("Description").getValue();
		var Enabled = zen("Enabled").getValue();
		var DHBits = zen("DHBits").getValue();
		if (Type == 1) VerifyPeer = zen("VerifyPeer1").getValue();
		var CAFile = zen("CAFile").getValue();
		var CRLFile = zen("CRLFile").getValue();
		var CertificateFile = zen("CertificateFile").getValue();
		var PrivateKeyFile = zen("PrivateKeyFile").getValue();
		var PrivateKeyType = zen("PrivateKeyType").getValue();
		var CipherList = zen("CipherList").getValue();
		var Ciphersuites = zen("Ciphersuites").getValue();
		var PWOptions = zen("PWOptions").getValue();
		if (PrivateKeyFile == "") PWOptions = 1;
		var OCSPIssuer = zen("IssuerFile").getValue()
		var OCSPResp = zen("RespFile").getValue()
		var OCSPTimeout = zen("OCSPTimeout").getValue()
		var proxy = this.SaveData(PID,isTest,Name,Description,Enabled,Type,VerifyPeer,CAFile,CRLFile,CertificateFile,PrivateKeyFile,PrivateKeyType,PrivateKeyPassword,CipherList,Ciphersuites,TLSMinVersion,TLSMaxVersion,host,port,this.pwModified,PWOptions,OCSP,OCSPIssuer,OCSPResp,OCSPTimeout,DHBits);
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

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			this.doModified();
			var name = zen("browseselect").getValue();
			zen(name).setValue(value);
			//if user changed CAFile, then see if we should enable/disable the CRLFile field.
			if (name == "CAFile") this.changedCAFile();
			//if user changed File containing this client/server's certificate then enable/disable private password field 
			if (name == "CertificateFile") this.changedFile();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Set focus to the Name field.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.testButtons();
	
	if (this.isMirror==false) zen("Name").focus();
	else zen("CAFile").focus();
	if (zen("CAFile").getValue() == "") {
		zen("id_CRLFile").setProperty("disabled",true);
		zen("id_CRLFile").setProperty("labelClass","disablednormal");
	}
	// disable or enable fields based on Type, etc.
	this.changeType();
	// disable or enable private password field 
	this.changedFile();
}

/// -1 = Both disabled; 0 = Test disabled; -10 = Test hidden; 1 = Test enabled
ClientMethod testButtons() [ Language = javascript ]
{
	switch(this.AllowTest) {
		case 0:
			this.disableCommandButton("btnTest");
			break;
		case 1:
			this.enableCommandButton("btnTest");
			break;
		case -10:
			this.hideCommandButton("btnTest");
			break;
		case -1:
			// this case is only possible when loading page.
			this.disableCommandButton("btnSave");
			this.disableCommandButton("btnTest");
			break;
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	#; If a PID is purposely removed when this page is rendered, then set isNew to true.
	If ..PID = "" Set ..isNew = 1 Set ..%GetComponentById("id_Password").hidden=0,..%GetComponentById("PWOptions").hidden=1,..%GetComponentById("OCSPTimeout").value=2

	#; Initialization for Mirror
	If (..PID = "%MirrorServer")!(..PID = "%MirrorClient") {
		Set ..isMirror = 1
		For tItem = "Name","Description","Type","Enabled","VerifyPeer","VerifyPeer1" Set ..%GetComponentById(tItem).hidden = 1
		Set ..isNew = '+##class(SYS.MirrorConfiguration).DoSSLConfigurationsExist()
		#; set flag for the Test button to be hidden.
		Set ..AllowTest = -10
		Set titleAdd = $$$TextHTML("Use the form below to create SSL/TLS configurations for Mirror. All changes made below will be saved to both %MirrorClient and %MirrorServer:")
		Set titleEdit = $$$TextHTML("Use the form below to edit SSL/TLS configurations for Mirror. All changes made below will be saved to both %MirrorClient and %MirrorServer:")
	} Else {
		Set titleAdd = $$$TextHTML("Use the form below to create a new SSL/TLS configuration:")
		Set titleEdit = $$$TextHTML("Use the form below to edit an existing SSL/TLS configuration:")
	}
	Set ..lblTitle = $S(..isNew=1:titleAdd,1:titleEdit)

	Set tCombo = ..%GetComponentById("TLSMinVersion")
	#;SML2901+
	Set tCombo.valueList=$s($$$IsOpenSSL10:"SSLv3,TLSv1.0,TLSv1.1,TLSv1.2",1:"TLSv1.0,TLSv1.1,TLSv1.2,TLSv1.3")
	Set tCombo = ..%GetComponentById("TLSMaxVersion")
	Set tCombo.valueList=$s($$$IsOpenSSL10:"SSLv3,TLSv1.0,TLSv1.1,TLSv1.2",1:"TLSv1.0,TLSv1.1,TLSv1.2,TLSv1.3")
	Set ..CipherDefault = $$$TLSDEFAULTCIPHERSUITES
	if $$$IsOpenSSL10 {
		Set ..%GetComponentById("Ciphersuites").hidden = 1
		Set ..%GetComponentById("CipherList").hidden = 0
	}
	#;SML2901-

	// Load data into fields
	Set tSC = ..LoadData(..PID)
	If '$$$ISOK(tSC) {
		Set ..%GetComponentById("idRespond").value = tSC
		Set ..%GetComponentById("idRespond").hidden = 0
		Set ..%GetComponentById("groupEdit").hidden = 1
		#; set flag for both Save and Test button to be hidden.
		Set ..AllowTest = -1
	}

	Set ..%GetComponentById("id_TypeNote").value = $$$Text("Note: Only necessary if this client will be asked to authenticate itself to servers.")
	
	If (..PID '= "") {
		If (..%GetComponentById("Type").value = 0) {
			Set ..%GetComponentById("id_Type").label = $$$Text("This client's credentials")
			Set ..%GetComponentById("id_TypeNote").hidden = 0
		} Else {
			Set ..%GetComponentById("id_Type").label = $$$Text("This server's credentials")
			Set ..%GetComponentById("id_TypeNote").hidden = 1
		}
	}
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..isNew {
		If (..PID = "%MirrorServer")||(..PID = "%MirrorClient") {
			Quit $$$TextHTML("Create SSL/TLS Configurations for Mirror")
		} Else {
			Quit $$$TextHTML("New SSL/TLS Configuration")
		}
	} Else {
		If (..PID = "%MirrorServer")||(..PID = "%MirrorClient") {
			Quit $$$TextHTML("Edit SSL/TLS Configurations for Mirror")
		} Else {
			Quit $$$TextHTML("Edit SSL/TLS Configuration")
		}
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

	Set tPageName = $$$Text("SSL/TLS Configurations","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_"?PID="_..EscapeURL($G(%request.Data("PID",1)))_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Used when Editing an existing SSL/TLS configuration. Load previously defined values into fields.
Method LoadData(PID As %String) As %Status
{
	Set $ZT="Error"
	If '%page.isNew {
		If ##class(Security.SSLConfigs).%ExistsId(PID) {
			Set sys = ##class(Security.SSLConfigs).%OpenId(PID)
			If sys.Type = 1 {
				Set ..%GetComponentById("VerifyPeer").hidden = 1
				If '%page.isMirror {
					Set ..%GetComponentById("VerifyPeer1").hidden = 0
					#; set flag for the Test button to be disabled
					Set ..AllowTest = 0
				}
				Set ..%GetComponentById("VerifyPeer1").value = sys.VerifyPeer
			} Else {
				Set ..%GetComponentById("VerifyPeer").value = sys.VerifyPeer
			}
			Set ..%GetComponentById("CRLFile").value = sys.CRLFile
		} Else {
			Quit $$$TextHTML("Cannot open object!")
		}
	} Else {
		Set sys = ##class(Security.SSLConfigs).%New()
		Set ..%GetComponentById("VerifyPeer").value = sys.VerifyPeer
		If PID = "%MirrorClient" {
			Set sys.Description = $$$TextHTML("SSL/TLS Client Configuration for Mirror")
			Set sys.Type = 0
			Set sys.VerifyPeer = 1
			Set ..%GetComponentById("VerifyPeer").value = sys.VerifyPeer
		}
		If PID = "%MirrorServer" {
			Set sys.Description = $$$TextHTML("SSL/TLS Server Configuration for Mirror")
			Set sys.Type = 1
			Set sys.VerifyPeer = 3
			Set ..%GetComponentById("VerifyPeer1").value = sys.VerifyPeer
		}
	}
	Set ..%GetComponentById("Name").value = PID
	Set ..%GetComponentById("Description").value = sys.Description
	Set ..%GetComponentById("Enabled").value = sys.Enabled
	Set ..%GetComponentById("Type").value = sys.Type
	Set ..%GetComponentById("PrivateKeyType").value = sys.PrivateKeyType
	Set ..%GetComponentById("CertificateFile").value = sys.CertificateFile
	Set ..%GetComponentById("PrivateKeyFile").value = sys.PrivateKeyFile
	Set ..%GetComponentById("DHBits").value = sys.DiffieHellmanBits
	#;YSD2148 Set ..%GetComponentById("PrivateKeyPassword").value = sys.PrivateKeyPassword
	#;YSD2148 Set ..%GetComponentById("PrivateKeyPassword1").value = sys.PrivateKeyPassword
	Set ..%GetComponentById("CipherList").value = sys.CipherList
	Set ..Min = sys.TLSMinVersionLogicalToDisplay(sys.TLSMinVersion)
	Set ..%GetComponentById("TLSMinVersion").value = ..Min
	Set ..Max = sys.TLSMaxVersionLogicalToDisplay(sys.TLSMaxVersion)
	Set ..%GetComponentById("TLSMaxVersion").value = ..Max
	Set ..%GetComponentById("Ciphersuites").value = sys.Ciphersuites
	If sys.TLSMaxVersion>$$$TLSv12 s ..%GetComponentById("Ciphersuites").hidden=0
	If sys.TLSMinVersion<$$$TLSv13 s ..%GetComponentById("CipherList").hidden=0
	Set ..%GetComponentById("OCSP").value = sys.OCSP
	If sys.OCSP && sys.Type {
		s ..%GetComponentById("id_Issuer").hidden=0
		s ..%GetComponentById("id_Resp").hidden=0
		s ..%GetComponentById("OCSPTimeout").hidden=0
	}
	Set ..%GetComponentById("IssuerFile").value = sys.OCSPIssuerCert
	Set ..%GetComponentById("RespFile").value = sys.OCSPResponseFile
	Set ..%GetComponentById("OCSPTimeout").value = sys.OCSPTimeout

	// Figure out if this is a File or Directory
	Set CAFile = sys.CAFile
	Set CAPath = sys.CAPath
	If CAFile '= "", ##class(%File).DirectoryExists(CAFile) Set CAPath = CAFile,CAFile=""
	If CAPath '= "", '##class(%File).DirectoryExists(CAPath) Set CAFile = CAPath,CAPath = ""
	If CAFile="",CAPath'="" Set CAFile = CAPath   //YSD1424 - this line is for display purpose only
	Set ..%GetComponentById("CAFile").value = CAFile
	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
}

/// Save general association data to server
/// Test can only be done for client, not server. 
ClassMethod SaveData(PID, isTest, Name, Description, Enabled, Type, VerifyPeer, CAFile, CRLFile, CertificateFile, PrivateKeyFile, PrivateKeyType, PrivateKeyPassword, CipherList, Ciphersuites, TLSMinVersion, TLSMaxVersion, TestHost, TestPort, pwModified, PWOptions, OCSP, OCSPIssuer, OCSPResp, OCSPTimeout, DHBits) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#dim sys as Security.SSLConfigs

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tProxy.PID = Name
	Set tSC = $$$OK
	If ##class(Security.SSLConfigs).%ExistsId(Name) {
		Set sys = ##class(Security.SSLConfigs).%OpenId(Name)
	} Else {
		Set sys = ##class(Security.SSLConfigs).%New()
		Set sys.Name = Name
	}
	Set CAPath = ""
	If CAFile '= "", ##class(%File).DirectoryExists(CAFile) Set CAPath = CAFile,CAFile=""
	If CAPath '= "", '##class(%File).DirectoryExists(CAPath) Set CAFile = CAPath,CAPath = ""
	Set sys.DiffieHellmanBits = DHBits
	Set sys.Enabled = $S(Enabled="true":1,1:0)
	Set sys.Description = Description
	Set sys.PrivateKeyType = +PrivateKeyType
	Set sys.VerifyPeer = +VerifyPeer
	Set sys.CAFile = CAFile
	Set sys.CAPath = CAPath
	Set sys.CRLFile = CRLFile
	Set sys.CertificateFile = CertificateFile
	Set sys.PrivateKeyFile = PrivateKeyFile
	If pwModified Set sys.PrivateKeyPassword = PrivateKeyPassword
	If PWOptions = 1 Set sys.PrivateKeyPassword = ""
	If PWOptions = 0,PID '= "",##class(Security.SSLConfigs).%ExistsId(PID) {
		Set old = ##class(Security.SSLConfigs).%OpenId(PID)
		Set sys.PrivateKeyPassword = old.PrivateKeyPassword
		Kill old
	}
	Set sys.CipherList = CipherList
	Set sys.Ciphersuites = Ciphersuites
	Set sys.TLSMinVersion = sys.TLSMinVersionDisplayToLogical(TLSMinVersion)
	Set sys.TLSMaxVersion = sys.TLSMaxVersionDisplayToLogical(TLSMaxVersion)
	Set sys.Type = +Type
	Set sys.OCSP = $S(OCSP="true":1,1:0)
	Set sys.OCSPIssuerCert = OCSPIssuer
	Set sys.OCSPResponseFile = OCSPResp
	Set sys.OCSPTimeout = OCSPTimeout
	Set tSC = sys.%Save()
	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	} Else {
		Set tProxy.ok = 1
		Set tProxy.PID = sys.%Id()
		If isTest,Name'="%MirrorServer" {
			Set tSC = sys.TestConnection($g(TestHost),$g(TestPort),.Info)
			If $$$ISERR(tSC) {
				Set tProxy.ok = 0
				Set tProxy.ErrorMessage = ..EscapeHTML($System.Status.GetErrorText(tSC))
			} Else {
				Set tmsg = ""
				For i = 1:1:+$g(Info) Set tmsg=tmsg_$S(tmsg="":"",1:$C(10))_$g(Info(i))
				Set tProxy.Message = tmsg
			}			
		} Else {
			If Name = "%MirrorClient"!(Name = "%MirrorServer") {
				#; If you saved one, then save the other
				If Name = "%MirrorServer" Set Name = "%MirrorClient"
				Else  Set Name = "%MirrorServer"
				If ##class(Security.SSLConfigs).%ExistsId(Name) {
					Set sys = ##class(Security.SSLConfigs).%OpenId(Name)
				} Else {
					Set sys = ##class(Security.SSLConfigs).%New()
					Set sys.Name = Name
				}
				Set sys.Enabled = 1
				Set sys.Description = Description
				Set sys.PrivateKeyType = PrivateKeyType
				Set sys.VerifyPeer = $S(Name="%MirrorClient":1,1:3)
				Set sys.CAFile = CAFile
				Set sys.CAPath = CAPath
				Set sys.CRLFile = CRLFile
				Set sys.CertificateFile = CertificateFile
				Set sys.PrivateKeyFile = PrivateKeyFile
				If pwModified Set sys.PrivateKeyPassword = PrivateKeyPassword
				If PWOptions = 1 Set sys.PrivateKeyPassword = ""
				If PWOptions = 0,PID '= "",##class(Security.SSLConfigs).%ExistsId(PID) {
					Set old = ##class(Security.SSLConfigs).%OpenId(PID)
					Set sys.PrivateKeyPassword = old.PrivateKeyPassword
					Kill old
				}
				Set sys.CipherList = CipherList
				Set sys.Ciphersuites = Ciphersuites
				Set sys.TLSMinVersion = sys.TLSMinVersionDisplayToLogical(TLSMinVersion)
				Set sys.TLSMaxVersion = sys.TLSMaxVersionDisplayToLogical(TLSMaxVersion)
				Set sys.Type = $S(Name="%MirrorClient":0,1:1)
				Set tSC = sys.%Save()
				If $$$ISERR(tSC) {
					Set tProxy.ok = 0
					Set tProxy.ErrorMessage = tProxy.ErrorMessage_" "_$ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
				} Else {
					If isTest,Name="%MirrorClient" {
						Set tSC = sys.TestConnection($g(TestHost),$g(TestPort),.Info)
						If $$$ISERR(tSC) {
							Set tProxy.ok = 0
							Set tProxy.ErrorMessage = ..EscapeHTML($System.Status.GetErrorText(tSC))
						} Else {
							Set tmsg = ""
							For i = 1:1:+$g(Info) Set tmsg=tmsg_$S(tmsg="":"",1:$C(10))_$g(Info(i))
							Set tProxy.Message = tmsg
						}
					}
					#; YSD2418:
					Set tSC = ##class(SYS.Mirror).UpdateDNinMirrorSetMember()
					If $$$ISERR(tSC) Set tProxy.ok = 0,tProxy.ErrorMessage = ..EscapeHTML($System.Status.GetErrorText(tSC))
				}
			}
		}
	}
	Kill sys
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.Message = $ZCVT($ZE,"O","HTML")
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
	Set pCommands(3) = $LB("btnTest",$$$Text("Test"),$$$Text("Test this SSL/TLS configuration"),"zenPage.doSave(1);")

	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
