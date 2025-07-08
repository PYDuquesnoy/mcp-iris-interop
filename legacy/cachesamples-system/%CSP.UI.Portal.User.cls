/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Edit User
Class %CSP.UI.Portal.User Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

///  Displayed name of this page.
Parameter PAGENAME = "Edit User";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.User.zen";

Parameter HELPADDRESS = "System Administration,Security,Users,Edit User";

Parameter EMSSERVICE = "Users";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Users.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property EditDisabled As %Boolean;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property IsNewSave As %Integer(ZENURL = "new");

Property NumTabs As %Integer [ InitialExpression = 9 ];

Property PasswordRequired As %Boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
.Text2:first-letter {
    font-size:1.4em;
}
.Text2 {
    font-size:13px;
    max-width:575px;
    margin-bottom:5px;
}
.sectionLabel {
	font-size:13px;
	font-weight:normal;
	color:black;
	margin-top:15px;
}
.innerTable {
	border:1px solid #888;
}
.arrowButton {
	cursor:pointer;
	margin:5px 0;
}
.fieldHint {
    color:gray;
    font-size:12px;
    padding-left:10px;
}
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
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
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<link id="newLink" href="%25CSP.UI.Portal.User.zen?PID=" caption="Click here to create a new user." hidden="true" containerStyle="padding-bottom:4px;"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white;stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":General:Roles:EscalationRoles:SQL Admin Privileges:SQL Tables:SQL Views:SQL Procedures:SQL ML Configurations:SQL Foreign Servers"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<!-- Page 1: User Edit -->
<vgroup id="page_1" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;" labelPosition="left">
<form id="fld" autocomplete="false">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<text id="Name" label="Name" size="30" hint="Required." onchange="zenPage.doChangeName(zenThis.getValue());zenPage.doModified();"/>
<select id="CopyUser"
label="Copy from"
onchange="zenPage.doCopyUser(zenThis.getValue());zenPage.doModified();"
title="Choose an existing user to copy"
/>
<text id="FullName" label="Full Name" size="30" onchange="zenPage.doModified();"/>
<text id="Comment" label="Comment" size="30" onchange="zenPage.doModified();"/>
<radioSet id="passwordChoice" label="Password" valueList="0,1" displayList="Enter new password,Leave as is" value="0" onchange="zenPage.passwordChanged(zenThis.getValue());zenPage.doModified();" hidden="true"/>
<text inputtype="password" id="Password" label="Password" size="30" onchange="zenPage.doModified();"/>
<text inputtype="password" id="PasswordVer" label="Password (confirm)" size="30" onchange="zenPage.doModified();"/>
<checkbox id="ChangePassword" label="Change password on next login" value="0" controlClass="normal" onchange="zenPage.doModified();"/>
<checkbox id="PasswordNeverExpires" label="Password never expires" value="0" controlClass="normal" onchange="zenPage.doModified();"/>
<checkbox id="Enabled" label="User enabled" value="1" controlClass="normal" onchange="zenPage.doModified();"/>
<checkbox id="AccountNeverExpires" label="Account Never Expires" value="0" controlClass="normal" onchange="zenPage.neverExpiresChanged();zenPage.doModified();"/>
<hgroup label="Account expiration Date">
<text id="ExpirationDate" size="30" onchange="zenPage.doModified();"/>
<label label="(yyyy-mm-dd)" labelClass="fieldHint"/>
</hgroup>
<select id="NameSpace" label="Startup Namespace" onchange="zenPage.doModified();"/>
<text id="Routine" label="Startup Tag^Routine" size="30" onchange="zenPage.doModified();"/>
<text id="EmailAddress" label="Email Address" size="30" onchange="zenPage.doModified();"/>
<hgroup label="Mobile Phone Service Provider">
<select id="PhoneProvider" onchange="zenPage.doModified();"/>
<link id="ProviderLink" caption="Create a new provider" href="#" onclick="zenPage.doPhoneProvider();return false;"/>
</hgroup>
<text id="PhoneNumber" label="Mobile Phone Number" size="30" onchange="zenPage.doModified();"/>
<fieldSet label="Two-factor Authentication" labelPosition="left" cellStyle="padding:4px;">
<checkbox id="AutheTwoFactorSMS" label="SMS text enabled" value="0" controlClass="normal" onchange="zenPage.twoFactorModified();zenPage.doModified();"/>
<checkbox id="AutheTwoFactorPW" label="Time-based One-time Password enabled" value="0" controlClass="normal" onchange="zenPage.twoFactorModified();zenPage.doModified();"/>
<hgroup id="DisplayTOTP" label="Display Time-Based One-time Password QR Code on next login" hidden="true">
<checkbox id="HOTPKeyDisplay" hidden="true" value="0" controlClass="normal" onchange="zenPage.doModified();"/>
<label id="NotRec" label="(Not Recommended)" hidden="true" labelClass="fieldHint"/>
</hgroup>
<link id="GenerateQRCode" caption="Generate a new Time-based One-time Password Key" href="#" hidden="true" onclick="zenPage.doGenerateQRCode();return false;"/>
<label id="Issuer" label="Issuer" hidden="true" disabled="true"/>
<label id="Account" label="Account" hidden="true" disabled="true"/>
<label id="Key" label="Base 32 Time-based One-time Password (OTP) Key" hidden="true" disabled="true"/>
<label id="JavaError" label="Unable to generate QRCode" hidden="true" disabled="true" enclosingClass="ErrorBox"/>
<image id="QRCode" width="150" height="150" src="" hidden="true" disabled="true" />
</fieldSet>
</group>
</form>
</vgroup>

<!-- Page 2: Roles -->
<vgroup id="page_2" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<UserRoles id="UserRoles" PID="#(%page.PID)#" type="UserRole" readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 3: EscalationRoles -->
<vgroup id="page_3" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<UserRoles id="UserEscalationRoles" PID="#(%page.PID)#" type="UserEscalationRole" readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 4: SQL Privileges -->
<vgroup id="page_4" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLPrivs"/>
<SQLPrivileges id="SQLPrivs" PID="#(%page.PID)#"/>
</vgroup>

<!-- Page 5: SQL Tables -->
<vgroup id="page_5" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLTables"/>
<SQLTables id="SQLTables" pageType="Users" type="TABLE" tab="3" PID="#(%page.PID)#" showSystemBox="true"/>
</vgroup>

<!-- Page 6: SQL Views -->
<vgroup id="page_6" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLViews"/>
<SQLTables id="SQLViews" pageType="Users" type="VIEW" tab="4" PID="#(%page.PID)#" showSystemBox="true"/>
</vgroup>

<!-- Page 7: SQL Procedures -->
<vgroup id="page_7" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLProcs"/>
<SQLTables id="SQLProcs" pageType="Users" type="STORED PROCEDURE" tab="5" PID="#(%page.PID)#" showSystemBox="true"/>
</vgroup>

<!-- Page 8: SQL ML Configurations -->
<vgroup id="page_8" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLMLConfigs"/>
<SQLTables id="SQLMLConfigs" pageType="Users" type="ML CONFIGURATION" tab="6" PID="#(%page.PID)#" showSystemBox="false"/>
</vgroup>

<!-- Page 9: SQL Foreign Servers -->
<vgroup id="page_9" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLForeignServers"/>
<SQLTables id="SQLForeignServers" pageType="Users" type="FOREIGN SERVER" tab="7" PID="#(%page.PID)#" showSystemBox="false"/>
</vgroup>

</pane>
}

/// Set focus to the Name or Description field, disable fields if DispatchClass is defined.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.InvalidParam) {
		this.disableCommandButton("btnProfile");
	}
	if (this.PID) {
		this.passwordChanged(1);
		if (!this.IsEMSReadOnly && !this.EditDisabled) {
			this.neverExpiresChanged();
		}
		if (this.EditDisabled) {
			this.disableCommandButton("btnSave");
			this.showMsg($$$Text('General settings cannot be modified for this user.'),false);
			return;
		} else {
			zen("FullName").focus();
		}
	} else {
		this.passwordChanged(0);
		zen("Name").focus();
	}
	
	if (this.IsNewSave != 0) {
		this.showMsg($$$Text('User saved.'),false);
		var newLink = zen('newLink');
		newLink.setHidden(false);
		return;
	}
	
	var hash = parseInt(document.location.hash.slice(1));
	if ((typeof(hash) === 'number') && (hash >= 0) && (hash <= this.NumTabs)) {
		zen('tabBar').tabClicked(hash);
	}
	
	this.resetMsg();
}

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

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (popupName == 'PhoneProvider') {
			this.PopulateTwoFactor();
			zen('PhoneProvider').setValue(value);
		} else {
			if (popupName == 'GenerateQRCode') {
				zenPage.showqr();
			} else {
				var tabType = popupName.slice(0,popupName.indexOf("-"));
				switch(tabType) {
					case 'TABLE':
						zen('SQLTables').refreshContents();
						break;
					case 'VIEW':
						zen('SQLViews').refreshContents();
						break;
					case 'STORED PROCEDURE':
						zen('SQLProcs').refreshContents();
						break;
					case 'ML CONFIGURATION':
						zen('SQLMLConfigs').refreshContents();
						break;
					case 'FOREIGN SERVER':
						zen('SQLForeignServers').refreshContents();
						break;
					default:
						break;
				}
			}
		}
	} catch (ex) {
		alert("Error: " + ex);
	}

	return true;
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	zen('newLink').setHidden(true);
	for (var i=0;i<this.NumTabs;i++) {
		var option = i + 1;
		if (i == index) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}				
	}
	if (index == 0) {
		if (this.EditDisabled) {
			this.showMsg($$$Text('General settings cannot be modified for this user.'),false);
		} else if (!this.InvalidParam) {
			this.enableCommandButton("btnSave");
		}
	} else {
		this.disableCommandButton("btnSave");
	}
	document.location.hash = index;
}

ClientMethod neverExpiresChanged() [ Language = javascript ]
{
	var newVal = zen('AccountNeverExpires').getValue();
	if (newVal) {
		zen('ExpirationDate').setDisabled(true);
		zen('ExpirationDate').setValue("");
	} else {
		zen('ExpirationDate').setDisabled(false);
	}
}

ClientMethod twoFactorModified() [ Language = javascript ]
{
	var newVal = zen('AutheTwoFactorPW').getValue();
	if (newVal) {
		zen('AutheTwoFactorSMS').setDisabled(true);
		if (this.PID != "") {
			zenPage.showqr();
			zen('Issuer').setHidden(false);
			zen('Account').setHidden(false);
			zen('Key').setHidden(false);
			zen('QRCode').setHidden(false);
			zen('GenerateQRCode').setHidden(false);
			zen('HOTPKeyDisplay').setHidden(false);
			zen('DisplayTOTP').setHidden(false);
			zen('NotRec').setHidden(false);
		}
	} else {
		zen('AutheTwoFactorSMS').setDisabled(false);
		zen('HOTPKeyDisplay').setHidden(true);
		zen('DisplayTOTP').setHidden(true);
		zen('NotRec').setHidden(true);
		zen('Issuer').setHidden(true);
		zen('Account').setHidden(true);
		zen('Key').setHidden(true);
		zen('QRCode').setHidden(true);
		zen('GenerateQRCode').setHidden(true);
		zen("JavaError").setHidden(true);
	}
	newVal = zen('AutheTwoFactorSMS').getValue();
	if (newVal) {
		zen('AutheTwoFactorPW').setDisabled(true);
	} else {
		zen('AutheTwoFactorPW').setDisabled(false);
	}
}

ClientMethod changeNS(ns) [ Language = javascript ]
{
	var tabArray = ["UserRoles","UserEscalationRoles","SQLPrivs","SQLTables","SQLViews","SQLProcs","SQLMLConfigs","SQLForeignServers"];
	for (var i = 0; i < tabArray.length; i++) {
		var tab = zen(tabArray[i]);
		tab.namespace = ns;
		tab.refreshContents();
	}
}

ClientMethod passwordChanged(newvalue) [ Language = javascript ]
{
	if (newvalue == 1) {
		zen('Password').setHidden(true);
		zen('PasswordVer').setHidden(true);
	} else {
		zen('Password').setHidden(false);
		zen('PasswordVer').setHidden(false);
		zen('Password').setValue("");
		zen('PasswordVer').setValue("");
		zen('Password').setProperty("hintClass","helpText");
		zen('Password').setProperty("controlClass","");
		zen('PasswordVer').setProperty("hintClass","helpText");
		zen('PasswordVer').setProperty("controlClass","");
	}
}

ClientMethod doChangeName(name) [ Language = javascript ]
{
	var newName = this.ParseUsername(name);
	zen('Name').setValue(newName);
}

ClientMethod doCopyUser(user) [ Language = javascript ]
{
	zenPage.CopyUser(user);
}

ClientMethod doGenerateQRCode() [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Dialog.GenerateQRCode.zen?PID='+encodeURIComponent(this.PID));
	zenLaunchPopupWindow(url,'GenerateQRCode','status,scrollbars,resizable=yes,width=550,height=400');
}

ClientMethod doProfile() [ Language = javascript ]
{
	var url = zenLink('%25CSP.UI.Portal.UserProfile.zen?PID='+encodeURIComponent(this.PID));
	this.gotoPage(url);
}

ClientMethod doPhoneProvider() [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Dialog.PhoneProvider.zen');
	zenLaunchPopupWindow(url,'PhoneProvider','status,scrollbars,resizable=yes,width=550,height=400');
}

ClientMethod doSave() [ Language = javascript ]
{
	if (this.isButtonDisabled("btnSave")) return;
	this.resetMsg();
	zen('newLink').setHidden(true);
	
	if (!this.validate()) {
		this.afterValidate();
		return;
	}
	
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	proxy.Name = zen('Name').getValue();
	proxy.FullName = zen('FullName').getValue();
	proxy.Comment = zen('Comment').getValue();
	proxy.Password = zen('Password').getValue();
	proxy.ChangePassword = zen('ChangePassword').getValue();
	proxy.PasswordNeverExpires = zen('PasswordNeverExpires').getValue();
	proxy.Enabled = zen('Enabled').getValue();
	proxy.ExpirationDate = zen('ExpirationDate').getValue();
	proxy.AccountNeverExpires = zen('AccountNeverExpires').getValue();
	proxy.AutheTwoFactorSMS = zen('AutheTwoFactorSMS').getValue();
	proxy.AutheTwoFactorPW = zen('AutheTwoFactorPW').getValue();
	proxy.HOTPKeyDisplay = zen('HOTPKeyDisplay').getValue();
	proxy.NameSpace = zen('NameSpace').getValue();
	proxy.Routine = zen('Routine').getValue().replace(/^\s+|\s+$/g, "");
	proxy.EmailAddress = zen('EmailAddress').getValue();
	proxy.PhoneProvider = zen('PhoneProvider').getValue();
	proxy.PhoneNumber = zen('PhoneNumber').getValue();
	proxy.passwordChoice = zen('passwordChoice').getValue();
	proxy.CopyUser = zen('CopyUser').getValue();
	
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		// error case
		this.showMsg(result.ErrorMessage,true);
		return;
	}
	this.setModified(false);
	if (proxy.PID == '') {
		var url = zenLink('%25CSP.UI.Portal.User.zen?PID='+encodeURIComponent(proxy.Name)+'&new=1');
		this.gotoPage(url);
		return;
	}
	// saved existing app
	this.passwordChanged(1);
	zen('passwordChoice').setValue(1);
	this.showMsg($$$Text('User saved.'),false);
}

ClientMethod showqr() [ Language = javascript ]
{
	var Name = zen('Name').getValue();
	var proxy = new zenProxy();
	proxy.Name = Name;	
	var result = this.GetQR(proxy);
	if (result.ErrorText != "")	{
		var qr = zenPage.getComponentById("JavaError")
		qr.setValue(result.ErrorText);
		qr.setHidden(false);
	}
	var qr = zenPage.getComponentById("QRCode");
	qr.setProperty('src',result.QRCode);
	var qr = zenPage.getComponentById("Issuer");
	qr.setValue(result.Issuer);
	var qr = zenPage.getComponentById("Account");
	qr.setValue(result.Account);
	var qr = zenPage.getComponentById("Key");
	qr.setValue(result.Key);
	var qr = zen('HOTPKeyDisplay');
	qr.setValue(false);
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var pass = true;
	try {
		var oldSynchronousMode = zenSynchronousMode;
		zenSynchronousMode = true;
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		if (zen('passwordChoice').getValue() == 0) {
			if (this.PasswordRequired) {
				if (!this.validateRequired(zen('Password'),pass,"S")) pass = false;
				if (!this.validateRequired(zen('PasswordVer'),pass,"S")) pass = false;
			}
			var verElem = zen('PasswordVer');
			if (zen('Password').getValue() != verElem.getValue()) {
				verElem.setProperty("hintClass","redText");
				verElem.setProperty("controlClass","zenInvalid");
				if (pass) {
					this.FirstFailed = 'PasswordVer';
				}
				pass = false;
			} else {
				verElem.setProperty("hintClass","helpText");
				verElem.setProperty("controlClass","");
			}
		}
		
		var namespace = zen('NameSpace');
		var rtn = zen("Routine");
		// Hide any validation errors from previous save attempt		
		rtn.setProperty("controlClass","");
		namespace.setProperty("controlClass","");
		rtn.setProperty("hint","");
		namespace.setProperty("hint","");
		
		var rtnVal = rtn.getValue().replace(/^\s+|\s+$/g, ""); // strip whitespace
		if (rtnVal != "") {
			if (namespace.getValue() == "") {
				namespace.setProperty("controlClass","zenInvalid");
				namespace.setProperty("hint",$$$Text("Required if startup routine specified"));
				namespace.setProperty("hintClass","redText");
				if (pass) {
					this.FirstFailed = 'NameSpace';
				}
				pass = false;
			} else if (!zenPage.ValidateRoutine(rtnVal,namespace.getValue())) {
				rtn.setProperty("controlClass","zenInvalid");
				var hint = $$$FormatText($$$Text("Routine '%1' does not exist in namespace '%2'"),((rtnVal.indexOf("^") != -1) ? rtnVal.split("^")[1] : rtnVal),namespace.getValue());
				rtn.setProperty("hint",hint);
				rtn.setProperty("hintClass","redText");
				if (pass) {
					this.FirstFailed = 'Routine';
				}
				pass = false;
			}
		}
		zenSynchronousMode = oldSynchronousMode;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	
	return pass;
}

ClassMethod ValidateRoutine(pRoutine, pNamespace) As %Boolean [ ZenMethod ]
{
	Set tValid = 1
	Try {
		If pRoutine'="" {
		 	Set:(pRoutine'["^") pRoutine="^"_pRoutine
			#; If namespace has been deleted, this will throw an UNDEFINED error
		 	Set tValid = ''$D(^|pNamespace|rOBJ($p(pRoutine,"^",2)))
		}
	} Catch {
		Set tValid = 0
	}
	Quit tValid
}

ClassMethod GetQR(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	s tSC=$$GenerateQRCode^%SYS.SECURITY(pProxy.Name,,.QRCode,.Key,.Account,.Issuer)
	#;If error, always return a "" for the QRCode
	If $$$ISERR(tSC) s QRCode=""
	s tProxy.ErrorText=$SYSTEM.Status.GetErrorText(tSC)
	s tProxy.QRCode=QRCode
	s tProxy.Key=Key
	s tProxy.Issuer=Issuer
	s tProxy.Account=Account
	Set tProxy.ok = 1
	q tProxy
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("FullName") = pProxy.FullName
		Set Properties("Comment") = pProxy.Comment
		If (pProxy.passwordChoice = 0) {
			Set Properties("Password") = pProxy.Password
		}
		Set Properties("ChangePassword") = pProxy.ChangePassword
		Set Properties("PasswordNeverExpires") = pProxy.PasswordNeverExpires
		Set Properties("Enabled") = pProxy.Enabled
		Set Properties("ExpirationDate") = pProxy.ExpirationDate
		Set Properties("AccountNeverExpires") = pProxy.AccountNeverExpires
		Set Properties("NameSpace") = pProxy.NameSpace
		Set Properties("Routine") = pProxy.Routine
		Set Properties("EmailAddress") = pProxy.EmailAddress
		Set Properties("PhoneProvider") = pProxy.PhoneProvider
		Set Properties("PhoneNumber") = pProxy.PhoneNumber
		Set Properties("HOTPKeyDisplay") = pProxy.HOTPKeyDisplay
		s AutheEnabled=0
		i pProxy.AutheTwoFactorSMS s AutheEnabled=AutheEnabled+$$$AutheTwoFactorSMS
		i pProxy.AutheTwoFactorPW s AutheEnabled=AutheEnabled+$$$AutheTwoFactorPW
		Set Properties("AutheEnabled") = AutheEnabled
		If pProxy.PID = "" {
			If (pProxy.CopyUser '= "") {
				Set tSC = ##class(Security.Users).Copy(pProxy.CopyUser,pProxy.Name,pProxy.FullName,1,1,$g(Properties("Password")))
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				#; password was already set during copy
				Kill Properties("Password")
		        Set tSC = ##class(Security.Users).Modify(pProxy.Name,.Properties)
				If $$$ISERR(tSC) {
					d ##class(Security.Users).Delete(pProxy.Name)
					throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				}
				If (pProxy.ChangePassword = 1) {
					Set Properties2("ChangePassword") = pProxy.ChangePassword
				    Set tSC = ##class(Security.Users).Modify(pProxy.Name,.Properties2)
				}
			} Else {
				Set Properties("Flags") = $$$NormalUser
				Set tSC = ##class(Security.Users).Create(pProxy.Name,.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		} Else {
			Set tSC = ##class(Security.Users).Modify(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method CopyUser(UserName As %String) As %Status [ ZenMethod ]
{
	Set tSC = ##class(Security.Users).Get(UserName,.Properties)
	Kill Properties("Name")
	Set Properties("HOTPKeyDisplay")=0
	Do ..PopulateFields(.Properties)
	Set ..%GetComponentById("passwordChoice").hidden = 0
	Set ..%GetComponentById("passwordChoice").value = 1
	Set ..%GetComponentById("Password").hidden=1
	Set ..%GetComponentById("PasswordVer").hidden=1
	Quit $$$OK
}

Method GenerateQRCode(UserName As %String) As %Status [ ZenMethod ]
{
	Set tSC = ##class(Security.Users).Get(UserName,.Properties)
	If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	Set Properties("HOTPKeyDisplay")=0
	Set Properties("HOTPKeyGenerate")=1
	Set tSC=##Class(Security.Users).Modify(UserName,.Properties)
	If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	Do ..PopulateFields(.Properties)
	Quit $$$OK
}

Method ParseUsername(UserName As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$ParseUsername(UserName,.NewName)
	Quit NewName
}

/// Fill in form fields. Used when loading the page for edit or when choosing a copy from user during creation
Method PopulateFields(ByRef Properties As %String) As %Status
{
	Kill Properties("Password")
	// Loop to set all field values
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		i tProperty="AutheEnabled" {
			Set comp = ..%GetComponentById("AutheTwoFactorSMS")
			Set comp.value = ($zb(+Properties("AutheEnabled"),$$$AutheTwoFactorSMS,1) = $$$AutheTwoFactorSMS)
			Set comp = ..%GetComponentById("AutheTwoFactorPW")
			Set comp.value = ($zb(+Properties("AutheEnabled"),$$$AutheTwoFactorPW,1) = $$$AutheTwoFactorPW)
			If (..IsEMSReadOnly || ..EditDisabled) Set comp.disabled = 1
		} else {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
				If (..IsEMSReadOnly || ..EditDisabled) Set Component.disabled = 1
			}
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	If (..IsEMSReadOnly || ..EditDisabled) {
		Set comp = ..%GetComponentById("GenerateQRCode")
		Set comp.disabled = 1
	}

	Quit $$$OK
}

Method DrawTabHeader(pSeed As %String) As %Status
{
	&html<<div class="Text2">>
	If pSeed = "SQLPrivs" {
		Write $$$FormatText($$$TextHTML("User %1 is assigned the following SQL administrative privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLTables" {
		Write $$$FormatText($$$TextHTML("User %1 is assigned the following SQL table privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLViews" {
		Write $$$FormatText($$$TextHTML("User %1 is assigned the following SQL view privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLProcs" {
		Write $$$FormatText($$$TextHTML("User %1 is assigned the following SQL procedure privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLMLConfigs" {
		Write $$$FormatText($$$TextHTML("User %1 is assigned the following SQL Machine Learning Configuration privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLForeignServers" {
		Write $$$FormatText($$$TextHTML("User %1 is assigned the following SQL Foreign Server privileges:"),..EscapeHTML(..PID))
	}
	
	&html<</div>>
	Quit $$$OK
}

Method PopulateNSDropdown(Type As %Integer, Output displayList As %String, Output valueList As %String) As %Status
{
	Set (displayList,valueList) = ""
	
	Do List^%SYS.NAMESPACE(.Namespaces,Type)
	Set name = $O(Namespaces(""))
  	While name '= "" {
	  	If valueList = "" {
			Set valueList = name
			Set displayList = ..EscapeHTML(name)
		} Else {
			Set valueList = valueList_","_name
			Set displayList = displayList_","_..EscapeHTML(name)
		}
   		Set name = $O(Namespaces(name))
  	}
	Quit $$$OK
}

Method PopulateTwoFactor() As %Status [ ZenMethod ]
{
	// Populate the two-factor dropdown
	Set valueList = ""
	Set tRS = ##class(%ResultSet).%New("%SYS.PhoneProviders:List")
	Set tSC = tRS.Execute()
	If $$$ISERR(tSC) Quit tSC
	While tRS.Next() {
		Set name = tRS.GetData(1)
		If valueList = "" {
			Set valueList = name
		} Else {
			Set valueList = valueList_","_name
		}
	}
	Set (..%GetComponentById("PhoneProvider").displayList,..%GetComponentById("PhoneProvider").valueList) = valueList
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set tSC = ##class(Security.System).Get($$$SystemSecurityName,.SysProperties)
	i '$zb(+SysProperties("AutheEnabled"),$$$AutheTwoFactorSMS,1) {
			Set ..%GetComponentById("AutheTwoFactorSMS").hidden = 1		
	}
	i '$zb(+SysProperties("AutheEnabled"),$$$AutheTwoFactorPW,1) {
			Set ..%GetComponentById("AutheTwoFactorPW").hidden = 1
	}

	Set tSC = ..PopulateTwoFactor()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = ##class(Security.System).Get($$$SystemSecurityName,.Properties)
	If $$$ISERR(tSC) Quit tSC
	If (Properties("PasswordPattern") '= "") || (Properties("PasswordValidationRoutine") '= "") {
		Set ..PasswordRequired = 1
		Set ..%GetComponentById("Password").hint = $$$Text("Required.")
		Set ..%GetComponentById("PasswordVer").hint = $$$Text("Required.")
	}
	Kill Properties
	
	If ..PID = "" {
		// Creating new user
		Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the following form to create a new user definition:")
		Set ..%GetComponentById("svgTabArea").hidden = 1
		Set ..%GetComponentById("svgTabArea").height = 0
		
		// Populate the Copy From dropdown
		Set count = 0
		Set tRS = ##class(%ResultSet).%New("Security.Users:List")
		Do tRS.Execute("*","*","*")
		Set valueList = ""
		While tRS.Next() {
			If (count > $G($$$IRISTempMgt($Username,"MaxUsers"),1000)) Quit
			Set Flag=tRS.GetData(5)
#;Can't copy LDAP and Delegated
			i $zb(Flag,$$$LDAPUser+$$$DelegatedUser,1) continue
			Set name = tRS.GetData(1)
			If valueList = "" {
				Set valueList = name
			} Else {
				Set valueList = valueList_","_name
			}
			Set count = count + 1
		}
		Set (..%GetComponentById("CopyUser").displayList,..%GetComponentById("CopyUser").valueList) = valueList
		i $zb(+SysProperties("AutheEnabled"),$$$AutheTwoFactorSMS,1) {
			Set ..%GetComponentById("AutheTwoFactorSMS").value = 1
			Set ..%GetComponentById("AutheTwoFactorPW").disabled = 1		
		} else {
			i $zb(+SysProperties("AutheEnabled"),$$$AutheTwoFactorPW,1) {
				Set ..%GetComponentById("AutheTwoFactorPW").value = 1		
				Set ..%GetComponentById("AutheTwoFactorSMS").disabled = 1
				Set ..%GetComponentById("HOTPKeyDisplay").value = 0		
			}
		}
	} Else {
		// Editing existing user
		Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Edit definition for user %1:"),..PID)
		
		Set ..%GetComponentById("Name").value = ..PID
		Set ..%GetComponentById("Name").disabled = 1
		
		Set tSC = ##class(Security.Users).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Set ..%GetComponentById("svgTabArea").hidden = 1
			Set ..%GetComponentById("svgTabArea").height = 0
			Quit $$$OK
		}

		Set isNotNormalUser = ($zb(+$G(Properties("Flags")),$$$NormalUser,1) = 0)
		Set ..EditDisabled = (isNotNormalUser || (..PID = "_PUBLIC"))
		If isNotNormalUser {
			Set ..%GetComponentById("UserRoles").readOnly = 1
		}
		Do ..PopulateFields(.Properties)
		
		Set ..%GetComponentById("CopyUser").hidden = 1
		If (..IsEMSReadOnly || ..EditDisabled) {
			Set ..%GetComponentById("ChangePassword").readonlyNobox = 1
			Set ..%GetComponentById("PasswordNeverExpires").readonlyNobox = 1
			Set ..%GetComponentById("Enabled").readonlyNobox = 1
			Set ..%GetComponentById("AccountNeverExpires").readonlyNobox = 1
			Set ..%GetComponentById("ProviderLink").hidden = 1
		} Else {
			Set ..%GetComponentById("passwordChoice").hidden = 0
		}
		Set ..%GetComponentById("passwordChoice").value = 1
		i ..%GetComponentById("AutheTwoFactorSMS").value = 1 {
			Set ..%GetComponentById("AutheTwoFactorPW").disabled=1
		}
		i ..%GetComponentById("AutheTwoFactorPW").value = 1 {
			s tSC=$$GenerateQRCode^%SYS.SECURITY(..PID,,.QRCode,.Key,.Account,.Issuer)
			Set ..%GetComponentById("Issuer").value=Issuer
			Set ..%GetComponentById("Account").value=Account
			Set ..%GetComponentById("Key").value=Key
			Set ..%GetComponentById("QRCode").src=QRCode
			Set ..%GetComponentById("AutheTwoFactorSMS").disabled=1
			Set ..%GetComponentById("GenerateQRCode").hidden=0
			Set ..%GetComponentById("HOTPKeyDisplay").hidden=0
			Set ..%GetComponentById("DisplayTOTP").hidden=0
			Set ..%GetComponentById("NotRec").hidden=0
			Set ..%GetComponentById("Issuer").hidden=0
			Set ..%GetComponentById("Account").hidden=0
			Set ..%GetComponentById("Key").hidden=0
			Set ..%GetComponentById("QRCode").hidden=0
			If $$$ISERR(tSC) {
				Set ..%GetComponentById("JavaError").hidden=0
				Set ..%GetComponentById("JavaError").value=$SYSTEM.Status.GetErrorText(tSC)
			}
		} 
	}
#;The default namespace for the user may have been deleted. Make sure we add it to the
#;display and pick list so it shows up, otherwise the displayed field will be null 
	Set tSC = ..PopulateNSDropdown(4,.displayList,.valueList)
	If $$$ISERR(tSC) Quit tSC
	If ..PID '= "" {
		i valueList'[Properties("NameSpace") {
			Set valueList = valueList_","_Properties("NameSpace")
			Set displayList = displayList_","_..EscapeHTML(Properties("NameSpace"))
		}
	}
	Set ..%GetComponentById("NameSpace").displayList = displayList
	Set ..%GetComponentById("NameSpace").valueList = valueList
	
	Set tSC = ..PopulateNSDropdown(5,.displayList,.valueList)
	If $$$ISERR(tSC) Quit tSC
	If ..PID '= "" {
		i valueList'[Properties("NameSpace") {
			Set valueList = valueList_","_Properties("NameSpace")
			Set displayList = displayList_","_..EscapeHTML(Properties("NameSpace"))
		}
	}
	Set (..%GetComponentById("SQLPrivs").nsDisplayList,..%GetComponentById("SQLTables").nsDisplayList,..%GetComponentById("SQLViews").nsDisplayList,..%GetComponentById("SQLProcs").nsDisplayList,..%GetComponentById("SQLMLConfigs").nsDisplayList,..%GetComponentById("SQLForeignServers").nsDisplayList) = displayList
	Set (..%GetComponentById("SQLPrivs").nsValueList,..%GetComponentById("SQLTables").nsValueList,..%GetComponentById("SQLViews").nsValueList,..%GetComponentById("SQLProcs").nsValueList,..%GetComponentById("SQLMLConfigs").nsValueList,..%GetComponentById("SQLForeignServers").nsValueList) = valueList

	
	Quit $$$OK
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Users","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	
	Quit $$$OK
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	If ..IsEditForm = 0 Quit $$$OK
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnProfile",$$$Text("Profile"),$$$Text("View this user's profile"),"zenPage.doProfile();")
	Set pCommands(3) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit User")
}

/// / Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
