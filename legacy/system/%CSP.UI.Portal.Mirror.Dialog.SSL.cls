/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit Service Popup Dialog for Management Portal
Class %CSP.UI.Portal.Mirror.Dialog.SSL Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Mirror.Dialog.SSL.zen";

/// Displayed name of this page.
Parameter PAGENAME = "SSL";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

Property isECP As %ZEN.Datatype.boolean(ZENURL = "isECP") [ InitialExpression = "0" ];

Property isClient As %ZEN.Datatype.boolean(ZENURL = "isClient") [ InitialExpression = "0" ];

Property needEnable As %ZEN.Datatype.boolean(ZENURL = "needEnable") [ InitialExpression = "0" ];

/// Indicate if password is modified. If pwModified is 0 then at save time we won't save password.
Property pwModified As %ZEN.Datatype.boolean [ InitialExpression = "0" ];

/// Keep TLSMinVersion
Property Min As %String;

/// Keep TLSMinVersion
Property Max As %String;

/// Default Ciphersuites value
Property CipherDefault As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();;"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed="#(%page.isNew)#"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>

<hgroup id="idButton" >
<hidden name="browseselect" id="browseselect"/>
<label id="result" controlClass="redText" value=""/>
</hgroup>

<group cellStyle="padding:5px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left">
<checkbox id="Enabled" label="Enabled" hidden="true"/>
<hgroup id="id_CAFile" labelPosition="left" label="File containing trusted Certificate Authority X.509 certificate" cellVAlign="top" >
<text id="CAFile" size="60" onkeyup="zenPage.changedCAFile();"/>
<button id="CAFileBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('CAFile','*.cer');"/>
</hgroup>
<hgroup id="id_CRLFile" labelPosition="left" label="File containing Certificate Revocation List" cellVAlign="top" hidden="true">
<text id="CRLFile" size="60"/>
<button id="CRLFileBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('CRLFile','*.cer');"/>
</hgroup>
<fieldSet id="id_Type" label="This server's credentials" containerStyle="padding-left:4px;padding-right:4px;" labelPosition="top">
<hgroup id="id_File" labelPosition="left" label="File containing this configuration's X.509 certificate" cellVAlign="top" containerStyle="padding-top:4px;padding-bottom:4px;" >
<text id="CertificateFile" size="59"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('CertificateFile','*.cer');"/>
</hgroup>
<hgroup id="id_Key" labelPosition="left" label="File containing associated private key" cellVAlign="top" cellStyle="padding-bottom:4px;" >
<text id="PrivateKeyFile" size="59"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('PrivateKeyFile','*.key');"/>
</hgroup>
<vgroup labelPosition="left" showLabel="false">
<radioSet id="PrivateKeyType" label="Private key type" displayList="RSA,DSA" valueList="2,1" value="2"/>
<radioSet id="PWOptions" label="Password:" displayList="Enter new password,Clear password,Leave as is" valueList="2,1,0" value="0" onchange="zenPage.togglePW();"/>
<vgroup id="id_Password" showLabel="false" labelPosition="left" hidden="true">
<text inputtype="password" id="PrivateKeyPassword" label="Private key password" onchange="zenPage.changePW();" />
<text inputtype="password" id="PrivateKeyPassword1" label="Private key password (confirm)" onchange="zenPage.changePW();"/>
</vgroup>
</vgroup>
</fieldSet>
<fieldSet id="id_CipherList" label="Cryptographic settings" containerStyle="padding-left:4px;padding-right:4px;" labelPosition="left">
<combobox id="TLSMinVersion" label="Minimum Protocol Version" editable="true" unrestricted="true" size="10" width="100" dropdownHeight="100" onchange="zenPage.changeVersion(1);"/>
<combobox id="TLSMaxVersion" label="Maximum Protocol Version" editable="true" unrestricted="true" size="10" width="100" dropdownHeight="100" onchange="zenPage.changeVersion(0);"/>
<text id="CipherList" label="Enabled cipherlist (TLSv1.2 and below)" size="60"/>
<text id="Ciphersuites" label="Enabled ciphersuites (TLSV1.3)" size="70"/>
<radioSet id="DHBits" label="Diffie Hellman Bits" displayList="Auto,512,1024,2048,4096" valueList="0,512,1024,2048,4096" value="0"/>
</fieldSet>
<fieldSet id="id_OcspSettings" label="OCSP settings" containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" labelPosition="left">
<checkbox id="OCSP" label="OCSP Stapling" onchange="zenPage.toggleOCSP();"/>
<hgroup id="id_Issuer" labelPosition="top" label="File containing the issuer certificate" cellVAlign="top" containerStyle="padding-top:4px;padding-bottom:4px;" hidden="true">
<text id="IssuerFile" size="59"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('IssuerFile','*.cer');"/>
</hgroup>
<hgroup id="id_Resp" labelPosition="top" label="Path to store cached OCSP response" cellVAlign="top" containerStyle="padding-top:4px;padding-bottom:4px;" hidden="true">
<text id="RespFile" size="59"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('RespFile','*.der');"/>
</hgroup>
<text id="OCSPTimeout" label="OCSP Update Timeout" hint="Required. (0-10)" size="8" hidden="true"/>
</fieldSet>
</group>

</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("CAFile").focus();
	this.changeVersion(0);
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.validate()==false) return false;
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return true;
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
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

/// User changed password. Update flag. 
ClientMethod changePW() [ Language = javascript ]
{
	this.pwModified = 1;
}

/// User changed PWOptions option. If they want to enter new password, show password fields. Otherwise hide them. 
ClientMethod togglePW() [ Language = javascript ]
{
	var PWOptions = zenPage.getComponentById("PWOptions").getValue();
	if (PWOptions == 2) {
		zenPage.getComponentById("id_Password").setHidden(false);
	} else {
		zenPage.getComponentById("id_Password").setHidden(true);	
	}
}

/// User changed OCSP option. 
ClientMethod toggleOCSP() [ Language = javascript ]
{
	var OCSP = zen("OCSP").getValue();
	if ((OCSP == 1) && (!this.isECP || !this.isClient)){
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
			if (this.getVersion(max)>16) {
				if (zen("Ciphersuites").getValue() == '') {
					zen("Ciphersuites").setValue(this.CipherDefault)
				}
			}
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
		if (this.isECP && !this.isClient) {	// server
			if (this.getVersion(max)<16) {
				zen('OCSP').setProperty("disabled",true);
				zen('OCSP').setProperty("labelClass","disablednormal");
				zen('OCSP').setValue(0);
			} else {
				zen('OCSP').setProperty("disabled",false);
				zen('OCSP').setProperty("labelClass","zenLabel");
			}
		} else {				// client or client/server
			if (this.getVersion(min)<16) {
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
ClientMethod doSave() [ Language = javascript ]
{
	try {
		// reset previous result message, if any
		zenPage.getComponentById("result").setValue("");
		
		var CAFile = zenPage.getComponentById("CAFile").getValue();
		var CRLFile = zenPage.getComponentById("CRLFile").getValue();
		var CertificateFile = zenPage.getComponentById("CertificateFile").getValue();
		var PrivateKeyFile = zenPage.getComponentById("PrivateKeyFile").getValue();
		var PrivateKeyType = zenPage.getComponentById("PrivateKeyType").getValue();
		var PrivateKeyPassword = zenPage.getComponentById("PrivateKeyPassword").getValue();
		var CipherList = zenPage.getComponentById("CipherList").getValue();
		var Ciphersuites = zen("Ciphersuites").getValue();
		var TLSMinVersion = zen("TLSMinVersion").getValue();
		var TLSMaxVersion = zen("TLSMaxVersion").getValue();
		var PWOptions = zenPage.getComponentById("PWOptions").getValue();
		var Enabled = zenPage.getComponentById("Enabled").getValue();
		var OCSP = zen("OCSP").getValue();
		var OCSPIssuer = zen("IssuerFile").getValue()
		var OCSPResp = zen("RespFile").getValue()
		var OCSPTimeout = zen("OCSPTimeout").getValue()
		var DHBits = zen("DHBits").getValue();
		var proxy = this.SaveData(Enabled,CAFile,CRLFile,CertificateFile,PrivateKeyFile,PrivateKeyType,PrivateKeyPassword,CipherList,Ciphersuites,TLSMinVersion,TLSMaxVersion,this.pwModified,PWOptions,this.isECP,this.isClient,OCSP,OCSPIssuer,OCSPResp,OCSPTimeout,DHBits);
		if (proxy.Message != "") {
			zenPage.getComponentById("result").setValue(proxy.Message);
		}
		return proxy.ok
	} catch(ex) {
		alert("ERROR: " + ex);
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zenPage.getComponentById("browseselect").getValue();
			zenPage.getComponentById(name).setValue(value);
			//if user changed CAFile, then see if we should enable/disable the CRLFile field.
			if (name == "CAFile") this.changedCAFile();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod validate() [ Language = javascript ]
{
	var PrivateKeyPassword = zenPage.getComponentById("PrivateKeyPassword").getValue();
	var PrivateKeyPassword1 = zenPage.getComponentById("PrivateKeyPassword1").getValue();
	if (PrivateKeyPassword != PrivateKeyPassword1) {
		alert($$$Text("The two Passwords are not the same. Please type them again."));
		zenPage.getComponentById("PrivateKeyPassword1").focus();
		return false;
	}
	return true;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $s(..isECP:$$$Text("Edit SSL/TLS Configurations for ECP"),1:$$$Text("Edit SSL/TLS Configurations for Mirror"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
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
	
	#;SML2649
	Set ..isNew = $s(..isECP:'+##class(Security.SSLConfigs).%ExistsId($s(..isClient:"%ECPClient",1:"%ECPServer")),1:'+##class(SYS.MirrorConfiguration).DoSSLConfigurationsExist())

	Set tCombo = ..%GetComponentById("TLSMinVersion")
	#;SML2901+
	Set tCombo.valueList=$s($$$IsOpenSSL10:"SSLv3,TLSv1.0,TLSv1.1,TLSv1.2",1:"TLSv1.0,TLSv1.1,TLSv1.2,TLSv1.3")
	Set tCombo = ..%GetComponentById("TLSMaxVersion")
	Set tCombo.valueList=$s($$$IsOpenSSL10:"SSLv3,TLSv1.0,TLSv1.1,TLSv1.2",1:"TLSv1.0,TLSv1.1,TLSv1.2,TLSv1.3")
	Set ..CipherDefault = $$$TLSDEFAULTCIPHERSUITES
	if $$$IsOpenSSL10 {
		Set ..%GetComponentById("Ciphersuites").hidden = 1
	} else {
		Set ..%GetComponentById("Ciphersuites").hidden = 0
	}
	#;SML2901-

	// Load data into fields
	Set tSC = ..LoadData()
	If $$$ISERR(tSC) Set ..%GetComponentById("result").value = tSC,..%GetComponentById("btnFinish").disabled = 1
	
	If (..%GetComponentById("CAFile").value = "") {
		Set ..%GetComponentById("id_CRLFile").disabled = 1
		Set ..%GetComponentById("id_CRLFile").labelClass = "disablednormal"
	}
	
	Quit $$$OK
}

/// Used when Editing an existing SSL/TLS configuration. Load previously defined values into fields.
Method LoadData() As %Status
{
	Set $ZT="Error"
	#;SML2649+
	If ..isECP {
		If ##class(Security.SSLConfigs).%ExistsId($s(..isClient:"%ECPClient",1:"%ECPServer")) {
			Set sys = ##class(Security.SSLConfigs).%OpenId($s(..isClient:"%ECPClient",1:"%ECPServer"))
			Set ..%GetComponentById("CRLFile").value = sys.CRLFile
		} Else {
			Set sys = ##class(Security.SSLConfigs).%New()
		}
	} else {
		If ##class(Security.SSLConfigs).%ExistsId("%MirrorServer") {
			Set sys = ##class(Security.SSLConfigs).%OpenId("%MirrorServer")
			Set ..%GetComponentById("CRLFile").value = sys.CRLFile
		} Else {
			Set sys = ##class(Security.SSLConfigs).%New()
		}
	}
	#;SML2649
	Set ..%GetComponentById("PrivateKeyType").value = sys.PrivateKeyType
	Set ..%GetComponentById("CertificateFile").value = sys.CertificateFile
	Set ..%GetComponentById("PrivateKeyFile").value = sys.PrivateKeyFile
	Set ..%GetComponentById("CipherList").value = sys.CipherList
	Set ..%GetComponentById("Enabled").value = sys.Enabled
	Set ..%GetComponentById("OCSP").value = sys.OCSP
	If '..isClient && sys.OCSP {
		s ..%GetComponentById("id_Issuer").hidden=0
		s ..%GetComponentById("id_Resp").hidden=0
		s ..%GetComponentById("OCSPTimeout").hidden=0
	}
	Set ..%GetComponentById("IssuerFile").value = sys.OCSPIssuerCert
	Set ..%GetComponentById("RespFile").value = sys.OCSPResponseFile
	Set ..%GetComponentById("OCSPTimeout").value = sys.OCSPTimeout
	Set ..%GetComponentById("DHBits").value = sys.DiffieHellmanBits
	if ..isClient {
		Set ..%GetComponentById("DHBits").hidden = 1
	}

	if ..needEnable {
		Set ..%GetComponentById("Enabled").hidden = 0
	}
	Set ..Min = sys.TLSMinVersionLogicalToDisplay(sys.TLSMinVersion)
	Set ..%GetComponentById("TLSMinVersion").value = ..Min
	Set ..Max = sys.TLSMaxVersionLogicalToDisplay(sys.TLSMaxVersion)
	Set ..%GetComponentById("TLSMaxVersion").value = ..Max
	If sys.Ciphersuites="",sys.TLSMaxVersion>$$$TLSv12 Set SSLConfig.Ciphersuites=$$$TLSDEFAULTCIPHERSUITES
	Set ..%GetComponentById("Ciphersuites").value = sys.Ciphersuites

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
ClassMethod SaveData(Enabled, CAFile, CRLFile, CertificateFile, PrivateKeyFile, PrivateKeyType, PrivateKeyPassword, CipherList, Ciphersuites, TLSMinVersion, TLSMaxVersion, pwModified, PWOptions, isECP, isClient, OCSP, OCSPIssuer, OCSPResp, OCSPTimeout, DHBits) As %ZEN.proxyObject [ ZenMethod ]
{
#dim sys as Security.SSLConfigs

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	#;SML2649
	Set isECP=(isECP="true"),isClient=(isClient="true"),Enabled=(Enabled="true")

	Try {
		Set CAPath = ""
		If CAFile '= "",##class(%File).DirectoryExists(CAFile) Set CAPath = CAFile,CAFile=""
		If CAPath '= "",'##class(%File).DirectoryExists(CAPath) Set CAFile = CAPath,CAPath = ""
		
		For Name = "%MirrorServer","%MirrorClient" {
			#;SML2649 ; If this is for ECP then we only want to do it for either %ECPServer or %ECPClient
			If isECP s Name=$s(isClient:"%ECPClient",1:"%ECPServer")
			If ##class(Security.SSLConfigs).%ExistsId(Name) {
				Set sys = ##class(Security.SSLConfigs).%OpenId(Name,,.tSC)
				If '$IsObject(sys) {
					Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				}
			} Else {
				Set sys = ##class(Security.SSLConfigs).%New()
				Set sys.Name = Name
			}
			Set sys.Enabled = $s(isECP:Enabled,1:1)
			#;SML2649+ ; Setup for ECP
			Set sys.Description = $S(Name="%MirrorClient":$$$TextHTML("SSL/TLS Client Configuration for Mirror"),Name="%MirrorServer":$$$TextHTML("SSL/TLS Server Configuration for Mirror"),Name="%ECPClient":$$$TextHTML("SSL/TLS Client Configuration for ECP"),1:$$$TextHTML("SSL/TLS Server Configuration for ECP"))
			Set sys.VerifyPeer = $S(Name="%MirrorClient"||(Name="%ECPClient"):1,1:3)
			#;SML2649-
			Set sys.PrivateKeyType = PrivateKeyType
			Set sys.CAFile = CAFile
			Set sys.CAPath = CAPath
			Set sys.CRLFile = CRLFile
			Set sys.CertificateFile = CertificateFile
			Set sys.PrivateKeyFile = PrivateKeyFile
			
			If PWOptions = 1 Set sys.PrivateKeyPassword = ""
			If pwModified Set sys.PrivateKeyPassword = PrivateKeyPassword
			If (PWOptions = 0) && ##class(Security.SSLConfigs).%ExistsId(Name) {
				Set old = ##class(Security.SSLConfigs).%OpenId(Name,,.tSC)
				If '$IsObject(old) {
					Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				}
				Set sys.PrivateKeyPassword = old.PrivateKeyPassword
				Kill old
			}
			Set sys.CipherList = CipherList
			Set sys.Ciphersuites = Ciphersuites
			Set sys.TLSMinVersion = sys.TLSMinVersionDisplayToLogical(TLSMinVersion)
			Set sys.TLSMaxVersion = sys.TLSMaxVersionDisplayToLogical(TLSMaxVersion)
			#;SML2649 ; Set for ECP client.
			Set sys.Type = $S(Name="%MirrorClient"||(Name="%ECPClient"):0,1:1)
			Set sys.OCSP = $S(OCSP="true":1,1:0)
			If (Name="%MirrorServer"||(Name="%ECPServer")) {
				Set sys.OCSPIssuerCert = OCSPIssuer
				Set sys.OCSPResponseFile = OCSPResp
				Set sys.OCSPTimeout = OCSPTimeout
				Set sys.DiffieHellmanBits = DHBits
			}
			Set tSC = sys.%Save()
			If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			Kill sys
			#;SML2649 ; Only do this once for the ECP SSL.
			Quit:isECP
		}
		#; YSD2418:
		#;SML2649; Only for Mirroring
		Set:'isECP tSC = ##class(SYS.Mirror).UpdateDNinMirrorSetMember()
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
		Set tProxy.Message = ""
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
	}
	Quit tProxy
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	if (pSeed = 1) {
		#;SML2649
		Set tPageTitle = $s('%page.isECP:$$$TextHTML("Use the form below to create SSL/TLS configurations for Mirror. All changes made below will be saved to both %MirrorClient and %MirrorServer:"),%page.isClient:$$$TextHTML("Use the form below to create SSL/TLS configurations '%ECPClient' for ECP Client"),1:$$$TextHTML("Use the form below to create SSL/TLS configurations '%ECPServer' for ECP Server"))_"<br/>"
	} else {
		#;SML2649
		Set tPageTitle = $s('%page.isECP:$$$TextHTML("Use the form below to edit SSL/TLS configurations for Mirror. All changes made below will be saved to both %MirrorClient and %MirrorServer:"),%page.isClient:$$$TextHTML("Use the form below to edit SSL/TLS configurations '%ECPClient' for ECP Client"),1:$$$TextHTML("Use the form below to edit SSL/TLS configurations '%ECPServer' for ECP Server"))_"<br/>"
	}
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
