/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.LDAP Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit LDAP configuration";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.LDAPs.zen";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.LDAP.zen";

Parameter HELPADDRESS = "Home,Security Management,Security LDAP configurations,Edit LDAP configuration";

Parameter EMSSERVICE = "Users";

Parameter RECENT = 0;

Property IsTest As %Boolean [ InitialExpression = 0 ];

Property LDAPUserString1 As %String [ InitialExpression = {$$$TextHTML("LDAP username to use for searches")} ];

Property LDAPUserString2 As %String [ InitialExpression = {$$$TextHTML("LDAP search username DN")} ];

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
a.radioSetCaption {
	vertical-align:baseline;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<label id="lblName" label="Login Domain Name" hidden="true" controlClass="normal"/>
<text id="Name" label="Login Domain Name" size="20" hint="Required. Should be in the format domain.xxx, e.g. domain.com for LDAP" onblur="zenPage.doModified();zenPage.doBaseDN();"/>
<text id="Description" label="Description" size="80" onchange="zenPage.doModified();"/>
<checkbox id="KerberosConnection" label="Kerberos configuration" onchange="zenPage.doModified();" hidden="true" disabled="true"/>
<checkbox id="LDAPConnection" label="LDAP configuration" onchange="zenPage.showLDAP(zenThis.getValue());zenPage.doModified();zenPage.doBaseDN();" hidden="true"/>
<form id="fld1" hidden="true">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<select id="CopyLDAPConfig"
label="Copy from"
onchange="zenPage.doCopyLDAPConfig(zenThis.getValue());zenPage.doModified();"
title="Choose an existing LDAP configuration to copy"
/>
<checkbox id="LDAPEnabled" label="LDAP Enabled" onchange="zenPage.doModified();"/>
<checkbox id="LDAPActiveDirectory" label="LDAP server is a Windows Active Directory server" onchange="zenPage.showDomain(zenThis.getValue());zenPage.doModified();"/>
<text id="LDAPDomainName" label="LDAP domain name" size="50" onchange="zenPage.doModified();" hidden="true"/>
<text id="LDAPHostNames" label="LDAP host names" size="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="LDAPSearchUsername" label="#(%page.LDAPUserString2)#" size="50" hint="Required." onchange="zenPage.doModified();"/>
<radioSet id="PWOptions" label="LDAP username password" displayList="Enter new password,Clear password,Leave as is" valueList="2,1,0" value="0" onchange="zenPage.togglePW(zenThis.getValue());zenPage.doModified();"/>
<text inputtype="password" id="LDAPSearchPassword" label="Password" onchange="zenPage.doModified();" hidden="true"/>
<text inputtype="password" id="LDAPSearchPasswordVer" label="Confirm Password" onchange="zenPage.doModified();" hidden="true"/>
<text id="LDAPBaseDN" label="LDAP Base DN to use for Username searches" size="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="LDAPBaseDNForGroups" label="LDAP Base DN to use for Nested Groups searches" size="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="LDAPUniqueDNIdentifier" label="LDAP Unique search attribute" size="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="LDAPServerTimeout" label="LDAP Server Timeout" size="5" hint="Required." onchange="zenPage.doModified();"/>
<text id="LDAPClientTimeout" label="LDAP Client Timeout" size="5" hint="Required." onchange="zenPage.doModified();"/>
<checkbox id="LDAPTLSConnection" label="Use TLS/SSL encryption for LDAP sessions" onchange="zenPage.doModified();"/>
<hgroup id="CertFileGroup" label="File with Certificate Authority certificate(s) to authenticate the LDAP server">
<text id="LDAPCACertFile" size="50" onchange="zenPage.doModified();"/>
<spacer width="5px"/>
<button caption="Browse..." onclick="zenPage.doBrowse('LDAPCACertFile');"/>
</hgroup>
<checkbox id="LDAPAllowISCLDAPCONFIGURATION" label="Allow ISC_LDAP_CONFIGURATION environment variable" onchange="zenPage.doModified();"/>
<checkbox id="LDAPUseGroups" label="Use LDAP Groups for Roles/Routine/Namespace" onchange="zenPage.changedGroupSetting(zenThis.getValue());zenPage.doModified();"/>
<checkbox id="LDAPUseNestedGroups" label="Search nested Groups for Roles/Routine/Namespace" onchange="zenPage.doModified();"/>
<hgroup id="OrgGroup" label="Organization ID prefix for group names" labelPosition="left">
<text id="OrganizationId" label="" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<spacer width="5px"/>
<link id="AdvancedSettings" caption="Advanced Settings" href="#" onclick="zenPage.toggle('AdvancedGroup');"/>
</hgroup>
<group id="AdvancedGroup" enclosingClass="EditForm" hidden="true" labelPosition="left" cellStyle="padding:0 4px;">
<text id="GroupId" label="Group ID prefix for group names" size="50" hint="Required. Usually 'Group'." onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="InstanceId" label="Instance ID prefix for group names" size="50" hint="Required. Usually 'Instance'." onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="RoleId" label="Role ID prefix for group names" size="50" hint="Required. Usually 'Role'." onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="EscalationRoleId" label="Escalation Role ID prefix for group names" size="50" hint="Required. Usually 'EscalationRole'." onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="NamespaceId" label="Namespace ID prefix for group names" hint="Required. Usually 'Namespace'." size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="RoutineId" label="Routine ID prefix for group names" size="50" hint="Required. Usually 'Routine'." onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="DelimiterId" label="Delimiter ID for group names" size="1" hint="Required. Usually '-'." onchange="zenPage.changedGroup();zenPage.doModified();"/>
</group>
<checkbox id="LDAPUniversalGroups" label="Allow Universal group Authorization" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<textarea id="ExampleResults1" label="Examples" cols="70" rows="4" readOnly="true" />
<text id="LDAPGroupId" label="Authorization Group ID" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<textarea id="ExampleResults2" label="Examples" cols="70" rows="4" readOnly="true" />
<text id="LDAPInstanceId" label="Authorization Instance ID" size="50" hint="Usually Node_Instance or Null" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<textarea id="ExampleResults3" label="Examples" cols="70" rows="4" readOnly="true" />
<text id="LDAPAttributeNameSpace" label="User attribute to retrieve default namespace" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeRoutine" label="User attribute to retrieve default routine" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeRoles" label="User attribute to retrieve roles" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeEscalationRoles" label="User attribute to retrieve escalation roles" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeComment" label="User attribute to retrieve comment attribute" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeFullName" label="User attribute to retrieve full name from" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeMail" label="User attribute to retrieve mail address" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeMobile" label="User attribute to retrieve mobile phone" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeMobileProvider" label="User attribute to retrieve mobile provider from" size="50" onchange="zenPage.doModified();"/>
<textarea id="Attributes" label="LDAP attributes to retrieve for each user" cols="50" rows="5" onchange="zenPage.doModified();"/>
</group>
</form>
</group>
</form>
</pane>
}

ClientMethod doCopyLDAPConfig(newLDAPConfig) [ Language = javascript ]
{
	zenPage.CopyLDAPConfig(newLDAPConfig);
	zen('PWOptions').setValue(2);
	this.togglePW(2);
	zenPage.showDomain(zen('LDAPActiveDirectory').getValue());
	zenPage.changedGroupSetting(zen('LDAPUseGroups').getValue());
	zenPage.changedGroup();
}

Method CopyLDAPConfig(LDAPConfigName As %String) As %Status [ ZenMethod ]
{
	Set tSC = ##class(Security.LDAPConfigs).Get(LDAPConfigName,.Properties)
	If $$$ISERR(tSC) Quit tSC
#;Use base dn contructed from name. We can change it later.
	k Properties("LDAPBaseDN")
	k Properties("LDAPBaseDNForGroups")
	k Properties("Description")
	Do ..PopulateFields(.Properties)
	Quit $$$OK
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		if (zen('PWOptions').getValue() == 2) {
			var verElem = zen('LDAPSearchPasswordVer');
			if (zen('LDAPSearchPassword').getValue() != verElem.getValue()) {
				verElem.setProperty("hintClass","redText");
				verElem.setProperty("controlClass","zenInvalid");
				if (pass) {
					this.FirstFailed = 'LDAPSearchPasswordVer';
				}
				pass = false;
			} else {
				verElem.setProperty("hintClass","helpText");
				verElem.setProperty("controlClass","");
			}
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

ClientMethod toggle(groupID) [ Language = javascript ]
{
	var group = zen(groupID);
	group.setHidden(!group.getProperty('hidden'))
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.resetMsg();
	this.showDomain(zen('LDAPActiveDirectory').getValue());
	this.changedGroup();
	zen('PWOptions').setValue(0);
	this.togglePW(0);
	if (!this.IsEMSReadOnly) {
		this.changedGroupSetting(zen('LDAPUseGroups').getValue());
	}
	zen('Name').focus();
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen(popupName).setValue(value);		
		zenPage.doModified();
	}
}

/// Launching a file selector window. 
ClientMethod doBrowse(fieldID) [ Language = javascript ]
{
	var Dir = zen(fieldID).getValue();
	var wildcard = "*";
	var url = zenLink("%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard);
	zenLaunchPopupWindow(url,fieldID,'status,scrollbars,resizable,width=600,height=700');
}

ClientMethod changedGroupSetting(newValue) [ Language = javascript ]
{
	if (newValue) {
		if (zen('LDAPActiveDirectory').getValue() == 1)	{
			zen('LDAPUseNestedGroups').setDisabled(false);
			// zen('LDAPBaseDNForGroups').setDisabled(true);
		}
		zen('OrganizationId').setDisabled(false);
		zen('GroupId').setDisabled(false);
		zen('InstanceId').setDisabled(false);
		zen('RoleId').setDisabled(false);
		zen('EscalationRoleId').setDisabled(false);
		zen('NamespaceId').setDisabled(false);
		zen('RoutineId').setDisabled(false);
		zen('DelimiterId').setDisabled(false);
		zen('AdvancedSettings').setHidden(false);
		zen('ExampleResults1').setDisabled(false);
		zen('ExampleResults2').setDisabled(false);
		zen('ExampleResults3').setDisabled(false);
		zen('LDAPGroupId').setDisabled(false);
		zen('LDAPInstanceId').setDisabled(false);
		zen('LDAPUniversalGroups').setDisabled(false);
		zen('LDAPAttributeNameSpace').setDisabled(true);
		zen('LDAPAttributeRoutine').setDisabled(true);
		zen('LDAPAttributeRoles').setDisabled(true);
		zen('LDAPAttributeEscalationRoles').setDisabled(true);
	} else {
		zen('LDAPUseNestedGroups').setValue(0);
		zen('LDAPUseNestedGroups').setDisabled(true);
		// zen('LDAPBaseDNForGroups').setDisabled(true);
		zen('LDAPUniversalGroups').setDisabled(true);
		zen('LDAPUniversalGroups').setValue(0);
		zen('OrganizationId').setDisabled(true);
		zen('GroupId').setDisabled(true);
		zen('InstanceId').setDisabled(true);
		zen('RoleId').setDisabled(true);
		zen('EscalationRoleId').setDisabled(true);
		zen('NamespaceId').setDisabled(true);
		zen('RoutineId').setDisabled(true);
		zen('DelimiterId').setDisabled(true);
		zen('AdvancedSettings').setHidden(true);
		zen('ExampleResults1').setDisabled(true);
		zen('ExampleResults2').setDisabled(true);
		zen('ExampleResults3').setDisabled(true);
		zen('LDAPGroupId').setDisabled(true);
		zen('LDAPInstanceId').setDisabled(true);
		zen('LDAPAttributeNameSpace').setDisabled(false);
		zen('LDAPAttributeRoutine').setDisabled(false);
		zen('LDAPAttributeRoles').setDisabled(false);
		zen('LDAPAttributeEscalationRoles').setDisabled(false);
	}
}

ClientMethod showDomain(newvalue) [ Language = javascript ]
{
	var result = this.IsWindows();
	// We no longer use Domain
	//if (result.iswindows == 1) {
	//	if (newvalue) {
	//		zen('LDAPDomainName').setHidden(0);
	//	} else {
	//		zen('LDAPDomainName').setHidden(1);
	//	}
	//} else {
	//	zen('LDAPDomainName').setHidden(1);
	//}
	if (newvalue) {
		if (zen('LDAPUseGroups').getValue() == 1) zen('LDAPUseNestedGroups').setDisabled(false);
		if (result.iswindows == 1) {
			zen('LDAPSearchUsername').setProperty('label',this.LDAPUserString1);
		} else {
			zen('LDAPSearchUsername').setProperty('label',this.LDAPUserString2);
		}
		if (this.PID == "") zen('LDAPUniqueDNIdentifier').setValue("sAMAccountName");
	} else {
		zen('LDAPUseNestedGroups').setValue(0);
		zen('LDAPUseNestedGroups').setDisabled(true);
		zen('LDAPSearchUsername').setProperty('label',this.LDAPUserString2);
		if (this.PID == "") zen('LDAPUniqueDNIdentifier').setValue("CN");
	}
}

ClientMethod showLDAP(newvalue) [ Language = javascript ]
{
	if (newvalue) {
		zen("fld1").setHidden(false);
		zen('LDAPEnabled').setValue(1);
	} else {
		zen("fld1").setHidden(true);
		zen('LDAPEnabled').setValue(0);
	}
}

/// User changed PWOptions option. If they want to enter new password, show password fields. Otherwise hide them. 
ClientMethod togglePW(PWOptions) [ Language = javascript ]
{
	if (PWOptions == 2) {
		zen("LDAPSearchPassword").setHidden(false);
		zen("LDAPSearchPasswordVer").setHidden(false);
	} else {
		zen("LDAPSearchPassword").setHidden(true);
		zen("LDAPSearchPasswordVer").setHidden(true);
	}
}

/// Update group examples.
ClientMethod changedGroup() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.OrganizationId = zen('OrganizationId').getValue();
		proxy.GroupId = zen('GroupId').getValue();
		proxy.InstanceId = zen('InstanceId').getValue();
		proxy.RoleId = zen('RoleId').getValue();
		proxy.EscalationRoleId = zen('EscalationRoleId').getValue();
		proxy.NamespaceId = zen('NamespaceId').getValue();
		proxy.RoutineId = zen('RoutineId').getValue();
		proxy.DelimiterId = zen('DelimiterId').getValue();
		proxy.UniversalGroup = zen("LDAPUniversalGroups").getValue();
		proxy.LDAPGroupId = zen('LDAPGroupId').getValue();
		proxy.LDAPInstanceId = zen('LDAPInstanceId').getValue();
		proxy.Mode=1;
		var result = this.dochangedGroup1(proxy);
		var ExampleResults1 = zen('ExampleResults1')
		if (result.ok == 1) {
			ExampleResults1.setValue(result.ExampleResults);
		} else {
			this.showMsg(result.ErrorMessage,1);
			setTimeout(function () {zenPage.clearClosureTest()}, 0);
		}
		proxy.Mode=2;
		var result = this.dochangedGroup1(proxy);
		var ExampleResults2 = zen('ExampleResults2')
		if (result.ok == 1) {
			ExampleResults2.setValue(result.ExampleResults);
		} else {
			this.showMsg(result.ErrorMessage,1);
			setTimeout(function () {zenPage.clearClosureTest()}, 0);
		}
		proxy.Mode=3;
		var result = this.dochangedGroup1(proxy);
		var ExampleResults3 = zen('ExampleResults3')
		if (result.ok == 1) {
			ExampleResults3.setValue(result.ExampleResults);
		} else {
			this.showMsg(result.ErrorMessage,1);
			setTimeout(function () {zenPage.clearClosureTest()}, 0);
		}
	} catch (ex) {
		alert("Error changedGroup: " + ex);
	}
}

/// get BaseDN based on name..
ClassMethod dochangedGroup1(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	s $zt="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	s Status=##Class(Security.LDAPConfigs).FormatExample(pProxy.Mode,pProxy.OrganizationId,pProxy.GroupId,pProxy.InstanceId,pProxy.RoleId,pProxy.EscalationRoleId,pProxy.NamespaceId,pProxy.RoutineId,pProxy.DelimiterId, pProxy.UniversalGroup, pProxy.LDAPGroupId,pProxy.LDAPInstanceId,.ExampleResults)
 	i $$$ISOK(Status) {
		Set tProxy.ExampleResults=ExampleResults
		Set tProxy.ok = 1
 	} else {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $SYSTEM.Status.GetErrorText(Status)
#;If name is "", allow it so we don't get an error message flashed if we hit cancel.
	#; 	i pProxy.Name'="" { 
	#;		Set tProxy.ok = 0
	#;		Set tProxy.ErrorMessage = $SYSTEM.Status.GetErrorText(Status)
	#; 	} else {
	#;		Set tProxy.BaseDN=""
	#;		Set tProxy.Name=""
	#; 		Set tProxy.ok = 1
	#; 	}
 	}
	Quit tProxy
Error s $zt=""
  Quit tProxy
}

/// get BaseDN based on name.
ClientMethod doBaseDN() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.Name = zen('Name').getValue();
		var result = this.doBaseDN1(proxy);
		if (result.ok == 1) {
			zen('LDAPBaseDN').setValue(result.BaseDN);
			zen('LDAPBaseDNForGroups').setValue(result.BaseDNForGroups);
			if (zen('LDAPConnection').getValue() == 1) {
				zen('Name').setValue(result.Name);
			}
		} else {
			this.showMsg(result.ErrorMessage,1);
			setTimeout(function () {zenPage.clearClosureTest()}, 0);
		}
	} catch (ex) {
		alert("Error doBaseDN: " + ex);
	}
}

ClientMethod clearClosureTest() [ Language = javascript ]
{
	var n = zen('Name');
	n.focus();
}

/// get BaseDN based on name..
ClassMethod doBaseDN1(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	s Status=##Class(Security.LDAPConfigs).FormatName(pProxy.Name,.NewName,.BaseDN)
 	i $$$ISOK(Status) {
		Set tProxy.BaseDN=BaseDN
		Set tProxy.BaseDNForGroups=BaseDN
		Set tProxy.Name=NewName
		Set tProxy.ok = 1
 	} else {
#;If name is "", allow it so we don't get an error message flashed if we hit cancel.
	 	i pProxy.Name'="" { 
			Set tProxy.ok = 0
			Set tProxy.ErrorMessage = $SYSTEM.Status.GetErrorText(Status)
	 	} else {
			Set tProxy.BaseDN=""
			Set tProxy.BaseDNForGroups=""
			Set tProxy.Name=""
	 		Set tProxy.ok = 1
	 	}
 	}
	Quit tProxy
}

/// Save current item.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		if (!this.validate()) {
			this.afterValidate();
			return;
		}
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.Name = zen('Name').getValue();
		proxy.Description = zen('Description').getValue();
		proxy.LDAPEnabled = zen('LDAPEnabled').getValue();
		proxy.LDAPActiveDirectory = zen('LDAPActiveDirectory').getValue();
		proxy.LDAPDomainName = zen('LDAPDomainName').getValue();
		proxy.LDAPHostNames = zen('LDAPHostNames').getValue();
		proxy.LDAPSearchUsername = zen('LDAPSearchUsername').getValue();
		proxy.PWOptions = zen('PWOptions').getValue();
		proxy.LDAPSearchPassword = zen('LDAPSearchPassword').getValue();
		proxy.LDAPSearchPasswordVer = zen('LDAPSearchPasswordVer').getValue();
		proxy.LDAPBaseDN = zen('LDAPBaseDN').getValue();
		proxy.LDAPBaseDNForGroups = zen('LDAPBaseDNForGroups').getValue();
		proxy.LDAPUniqueDNIdentifier = zen('LDAPUniqueDNIdentifier').getValue();
		proxy.LDAPServerTimeout = zen('LDAPServerTimeout').getValue();
		proxy.LDAPClientTimeout = zen('LDAPClientTimeout').getValue();
		proxy.LDAPTLSConnection = zen('LDAPTLSConnection').getValue();
		proxy.LDAPUseGroups = zen('LDAPUseGroups').getValue();
		proxy.LDAPUseNestedGroups = zen('LDAPUseNestedGroups').getValue();
		proxy.LDAPUniversalGroups =	zen('LDAPUniversalGroups').getValue();
		proxy.LDAPAllowISCLDAPCONFIGURATION = zen('LDAPAllowISCLDAPCONFIGURATION').getValue();
		proxy.OrganizationId = zen('OrganizationId').getValue();
		proxy.GroupId = zen('GroupId').getValue();
		proxy.InstanceId = zen('InstanceId').getValue();
		proxy.RoleId = zen('RoleId').getValue();
		proxy.EscalationRoleId = zen('EscalationRoleId').getValue();
		proxy.NamespaceId = zen('NamespaceId').getValue();
		proxy.RoutineId = zen('RoutineId').getValue();
		proxy.DelimiterId = zen('DelimiterId').getValue();
		proxy.LDAPGroupId = zen('LDAPGroupId').getValue();
		proxy.LDAPInstanceId = zen('LDAPInstanceId').getValue();
		proxy.LDAPCACertFile = zen('LDAPCACertFile').getValue();
		proxy.LDAPAttributeComment = zen('LDAPAttributeComment').getValue();
		proxy.LDAPAttributeFullName = zen('LDAPAttributeFullName').getValue();
		proxy.LDAPAttributeMail = zen('LDAPAttributeMail').getValue();
		proxy.LDAPAttributeMobile = zen('LDAPAttributeMobile').getValue();
		proxy.LDAPAttributeMobileProvider = zen('LDAPAttributeMobileProvider').getValue();
		proxy.LDAPAttributeNameSpace = zen('LDAPAttributeNameSpace').getValue();
		proxy.LDAPAttributeRoutine = zen('LDAPAttributeRoutine').getValue();
		proxy.LDAPAttributeRoles = zen('LDAPAttributeRoles').getValue();
		proxy.LDAPAttributeEscalationRoles = zen('LDAPAttributeEscalationRoles').getValue();
		proxy.Attributes = zen('Attributes').getValue();
		proxy.SecurityIsReadOnly = this.SecurityIsReadOnly;
		
		var KerberosConnection = zen('KerberosConnection').getValue();
		var LDAPConnection = zen('LDAPConnection').getValue();
		
		if ((proxy.LDAPHostNames == "") && (KerberosConnection == 1) && (LDAPConnection == 0)) {
			proxy.LDAPHostNames = "UNKNOWNHOST"
		}
		if ((proxy.LDAPSearchUsername == "") && (KerberosConnection == 1) && (LDAPConnection == 0)) {
			proxy.LDAPSearchUsername = "UNKNOWNUSER"
		}
		proxy.LDAPConnection=LDAPConnection
		
		var result = this.SaveData(proxy);
		if (this.IsTest == 0) {
			this.afterSave(result);
		} else {
			if (result.ok == 1) {
				this.setModified(false);
				if ((typeof(result.Message) != "undefined") && (result.Message != "")) {
					this.showMsg(result.Message,0);
				} 
			} else {
				this.showMsg(result.ErrorMessage,1);
			}
		}
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("Description") = pProxy.Description
		s LDAPFlags=0
		If pProxy.LDAPActiveDirectory {
			Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPActiveDirectory,7)
		} Else {
			Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPActiveDirectory,2)
		}
		Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPTLSConnection,$S(pProxy.LDAPTLSConnection:7,1:2))
		Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPAllowISCLDAPCONFIGURATION,$S(pProxy.LDAPAllowISCLDAPCONFIGURATION:7,1:2))
		Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPUseGroups,$S(pProxy.LDAPUseGroups:7,1:2))
		Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPUseNestedGroups,$S(pProxy.LDAPUseNestedGroups:7,1:2))
		Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPUniversalGroups,$S(pProxy.LDAPUniversalGroups:7,1:2))
		Set LDAPFlags = $zb(+LDAPFlags,$$$LDAPEnabled,$S(pProxy.LDAPEnabled:7,1:2))
		i pProxy.LDAPConnection {
			s LDAPFlags=$zb(+LDAPFlags,$$$LDAPKerberosOnly,2)
		} else {
			s LDAPFlags=$zb(+LDAPFlags,$$$LDAPKerberosOnly,7)
		}
			
		Set Properties("LDAPFlags") = LDAPFlags
		If $$$ISWINDOWS && pProxy.LDAPActiveDirectory Set Properties("LDAPDomainName") = pProxy.LDAPDomainName
		Set Properties("OrganizationId") = pProxy.OrganizationId
		Set Properties("GroupId") = pProxy.GroupId
		Set Properties("InstanceId") = pProxy.InstanceId
		Set Properties("RoleId") = pProxy.RoleId
		Set Properties("EscalationRoleId") = pProxy.EscalationRoleId
		Set Properties("NamespaceId") = pProxy.NamespaceId
		Set Properties("RoutineId") = pProxy.RoutineId
		Set Properties("DelimiterId") = pProxy.DelimiterId
		Set Properties("LDAPGroupId") = pProxy.LDAPGroupId
		Set Properties("LDAPInstanceId") = pProxy.LDAPInstanceId
			
		Set Properties("LDAPHostNames") = pProxy.LDAPHostNames
		Set Properties("LDAPSearchUsername") = pProxy.LDAPSearchUsername
			
		If pProxy.PWOptions = 2 {
			Set Properties("LDAPSearchPassword") = pProxy.LDAPSearchPassword
		} ElseIf pProxy.PWOptions = 1 {
			Set Properties("LDAPSearchPassword") = ""
		}
			
		Set Properties("LDAPBaseDN") = pProxy.LDAPBaseDN
		Set Properties("LDAPBaseDNForGroups") = pProxy.LDAPBaseDNForGroups
		Set Properties("LDAPUniqueDNIdentifier") = pProxy.LDAPUniqueDNIdentifier
		Set Properties("LDAPServerTimeout") = pProxy.LDAPServerTimeout
		Set Properties("LDAPClientTimeout") = pProxy.LDAPClientTimeout
		If '$$$ISWINDOWS {
			Set Properties("LDAPCACertFile") = pProxy.LDAPCACertFile
		}
		Set Properties("LDAPAttributeComment") = pProxy.LDAPAttributeComment
		Set Properties("LDAPAttributeFullName") = pProxy.LDAPAttributeFullName
		Set Properties("LDAPAttributeMail") = pProxy.LDAPAttributeMail
		Set Properties("LDAPAttributeMobile") = pProxy.LDAPAttributeMobile
		Set Properties("LDAPAttributeMobileProvider") = pProxy.LDAPAttributeMobileProvider
		Set Properties("LDAPAttributeNameSpace") = pProxy.LDAPAttributeNameSpace
		Set Properties("LDAPAttributeRoutine") = pProxy.LDAPAttributeRoutine
		Set Properties("LDAPAttributeRoles") = pProxy.LDAPAttributeRoles
		Set Properties("LDAPAttributeEscalationRoles") = pProxy.LDAPAttributeEscalationRoles

		// build into array so there are no duplicates
		// note that the line breaks are now $c(10)
		For i = 1:1:$L(pProxy.Attributes,$c(10)) {
			Set tA = $P(pProxy.Attributes,$c(10),i)
			If tA '= "" Set A(tA)=""
		}
		Kill Properties("LDAPAttributes")
		Set Properties("LDAPAttributes") = ""
		Set attribute = $ORDER(A(""))
		While (attribute '= "") {
			Set Properties("LDAPAttributes",attribute) = ""
			Set attribute = $ORDER(A(attribute))
		}
 	
		If (pProxy.PID '= "") {
			Set tSC = ##Class(Security.LDAPConfigs).Modify(pProxy.PID,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(Security.LDAPConfigs).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClassMethod IsWindows() As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	i $$$ISWINDOWS {
		s tProxy.iswindows=1
	} else {
		s tProxy.iswindows=0
	}
	q tProxy
}

Method PopulateFields(ByRef Properties As %String) As %Status
{
	Set Properties("LDAPSearchPasswordVer") = Properties("LDAPSearchPassword")
	Set Properties("LDAPActiveDirectory") = $zb(+Properties("LDAPFlags"),$$$LDAPActiveDirectory,1) > 0
	Set Properties("LDAPTLSConnection") = $zb(+Properties("LDAPFlags"),$$$LDAPTLSConnection,1) > 0
	Set Properties("LDAPAllowISCLDAPCONFIGURATION") = $zb(+Properties("LDAPFlags"),$$$LDAPAllowISCLDAPCONFIGURATION,1) > 0
	Set Properties("LDAPUseGroups") = $zb(+Properties("LDAPFlags"),$$$LDAPUseGroups,1) > 0
	Set Properties("LDAPUseNestedGroups") = $zb(+Properties("LDAPFlags"),$$$LDAPUseNestedGroups,1) > 0
	Set Properties("LDAPUniversalGroups") = $zb(+Properties("LDAPFlags"),$$$LDAPUniversalGroups,1) > 0
	Set Properties("LDAPEnabled") = $zb(+Properties("LDAPFlags"),$$$LDAPEnabled,1) > 0
	
	Set Attributes = ""
	Set attribute = $ORDER(Properties("LDAPAttributes",""))
	While (attribute '= "") {
		If (Attributes '= "") Set Attributes = Attributes_$c(13,10)
		Set Attributes = Attributes_attribute
		Set attribute = $ORDER(Properties("LDAPAttributes",attribute))
	}
 	Set Properties("Attributes") = Attributes

	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	q $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	s Status=##Class(Security.System).Get(,.SysProperties)
	i $zb(+SysProperties("AutheEnabled"),$$$AutheKB,1) {
		s KerberosEnabled=1
	} else {
		s KerberosEnabled=0
	}
	i KerberosEnabled {
		Set ..%GetComponentById("KerberosConnection").value=1
		Set ..%GetComponentById("KerberosConnection").hidden=0
		Set ..%GetComponentById("LDAPConnection").hidden=0
	}
	i (KerberosEnabled=0) {
		Set ..%GetComponentById("fld1").hidden=0
		Set ..%GetComponentById("LDAPConnection").value=1
	}
	If ..PID = "" {
		i KerberosEnabled {
			Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the form below to create a new LDAP/Kerberos configuration:")
		} else {
			Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the form below to create a new LDAP configuration:")
		}
		// Populate the Copy From dropdown
		Set tRS = ##class(%ResultSet).%New("Security.LDAPConfigs:List")
		Do tRS.Execute("*")
		Set valueList = ""
		While tRS.Next() {
			Set name = tRS.GetData(1)
			If valueList = "" {
				Set valueList = name
			} Else {
				Set valueList = valueList_","_name
			}
		}
		Set (..%GetComponentById("CopyLDAPConfig").displayList,..%GetComponentById("CopyLDAPConfig").valueList) = valueList
		s LDAPConfig=##Class(Security.LDAPConfigs).%New()
		s Status=##Class(Security.LDAPConfigs).GetProperties(LDAPConfig,.Properties)
		d ..PopulateFields(.Properties)
	} Else {
		Set ..%GetComponentById("Name").value = ..PID
		Set ..%GetComponentById("lblName").value = ..PID
		i KerberosEnabled {
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Use the form below to edit LDAP/Kerberos configuration %1:"),..PID)
		} else {
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Use the form below to edit LDAP configuration %1:"),..PID)
		}
		Set ..%GetComponentById("lblName").hidden = 0
		Set ..%GetComponentById("Name").hidden = 1
		Set ..%GetComponentById("CopyLDAPConfig").hidden = 1
		Set ..%GetComponentById("CopyLDAPConfig").containerStyle = "padding:0;"
		
		Set tSC = ##class(Security.LDAPConfigs).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Quit $$$OK
		}
		d ..PopulateFields(.Properties)
		i '$zb(+Properties("LDAPFlags"),$$$LDAPKerberosOnly,1) {
			Set ..%GetComponentById("fld1").hidden=0
			Set ..%GetComponentById("LDAPConnection").value=1
		}
	}
	If $$$ISWINDOWS {
	 	Set ..%GetComponentById("CertFileGroup").hidden = 1
	 	Set ..%GetComponentById("CertFileGroup").containerStyle = "padding:0;"
		Set ..%GetComponentById("LDAPHostNames").hint=""
 	} 
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	s Status=##Class(Security.System).Get(,.Properties)
	i $zb(+Properties("AutheEnabled"),$$$AutheKB,1) {
		Quit $$$Text("Edit LDAP/Kerberos configuration")
	} else {
		Quit $$$Text("Edit LDAP configuration")
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	s Status=##Class(Security.System).Get(,.Properties)
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	i $zb(+Properties("AutheEnabled"),$$$AutheKB,1) {
		Set tPageName = $$$Text("Security LDAP/Kerberos configurations")
	} else {
		Set tPageName = $$$Text("Security LDAP configurations")
	}
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
