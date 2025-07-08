/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.LDAPRO Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit LDAP configuration";

Parameter PARENTPAGE = "/csp/sys/op/%CSP.UI.Portal.LDAPsRO.zen";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.LDAPRO.zen";

Parameter HELPADDRESS = "Home,Security Management,Security LDAP configurations,Edit LDAP configuration";

Parameter EMSSERVICE = "Users";

Parameter RECENT = 0;

Property IsTest As %Boolean [ InitialExpression = 0 ];

Property LDAPUserString1 As %String [ InitialExpression = {$$$TextHTML("LDAP username to use for searches")} ];

Property LDAPUserString2 As %String [ InitialExpression = {$$$TextHTML("LDAP search username DN")} ];

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

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
<text id="Name" label="Login Domain Name" size="20" onchange="zenPage.doModified();"/>
<text id="Description" label="Description" size="80" onchange="zenPage.doModified();"/>
<checkbox id="KerberosConnection" label="Kerberos configuration" onchange="zenPage.doModified();" hidden="true" disabled="true"/>
<checkbox id="LDAPConnection" label="LDAP configuration" onchange="zenPage.showLDAP(zenThis.getValue());zenPage.doModified();" hidden="true" disabled="true"/>
<form id="fld1" hidden="true">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<checkbox id="LDAPEnabled" label="Enabled" onchange="zenPage.doModified();"/>
<checkbox id="LDAPActiveDirectory" label="LDAP server is a Windows Active Directory server" onchange="zenPage.showDomain(zenThis.getValue());zenPage.doModified();"/>
<text id="LDAPDomainName" label="LDAP domain name" size="50" onchange="zenPage.doModified();" hidden="true"/>
<text id="LDAPHostNames" label="LDAP host names" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPSearchUsername" label="#(%page.LDAPUserString2)#" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPBaseDN" label="LDAP Base DN to use for Uername searches" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPBaseDNForGroups" label="LDAP Base DN to use for Nested Groups searches" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPUniqueDNIdentifier" label="LDAP Unique search attribute" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPServerTimeout" label="LDAP Server Timeout" size="5" onchange="zenPage.doModified();"/>
<text id="LDAPClientTimeout" label="LDAP Client Timeout" size="5" onchange="zenPage.doModified();"/>
<checkbox id="LDAPTLSConnection" label="Use TLS/SSL encryption for LDAP sessions" onchange="zenPage.doModified();"/>
<hgroup id="CertFileGroup" label="File with Certificate Authority certificate(s) to authenticate the LDAP server">
<text id="LDAPCACertFile" size="50" onchange="zenPage.doModified();"/>
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
<text id="GroupId" label="Group ID prefix for group names" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="InstanceId" label="Instance ID prefix for group names" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="RoleId" label="Role ID prefix for group names" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="EscalationRoleId" label="Escalation Role ID prefix for group names" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="NamespaceId" label="Namespace ID prefix for group names" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="RoutineId" label="Routine ID prefix for group names" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<text id="DelimiterId" label="Delimiter ID for group names" size="1" onchange="zenPage.changedGroup();zenPage.doModified();"/>
</group>
<checkbox id="LDAPUniversalGroups" label="Allow Universal group Authorization" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<textarea id="ExampleResults1" label="Examples" cols="70" rows="4" readOnly="true" />
<text id="LDAPGroupId" label="Authorization Group ID" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<textarea id="ExampleResults2" label="Examples" cols="70" rows="4" readOnly="true" />
<text id="LDAPInstanceId" label="Authorization Instance ID" size="50" onchange="zenPage.changedGroup();zenPage.doModified();"/>
<textarea id="ExampleResults3" label="Examples" cols="70" rows="4" readOnly="true" />
<text id="LDAPAttributeNameSpace" label="User attribute to retrieve default namespace" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeRoutine" label="User attribute to retrieve default routine" size="50" onchange="zenPage.doModified();"/>
<text id="LDAPAttributeRoles" label="User attribute to retrieve roles" size="50" onchange="zenPage.doModified();"/>
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

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.hideCommandButton('btnSave');
	this.resetMsg();
	this.showDomain(zen('LDAPActiveDirectory').getValue());
	this.changedGroup();
	//if (!this.IsEMSReadOnly) {
	//	this.changedGroupSetting(zen('LDAPUseGroups').getValue());
	//}
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

ClientMethod toggle(groupID) [ Language = javascript ]
{
	var group = zen(groupID);
	group.setHidden(!group.getProperty('hidden'))
}

ClientMethod changedGroupSetting(newValue) [ Language = javascript ]
{
	if (newValue) {
		if (zen('LDAPActiveDirectory').getValue() == 1)	{
			zen('LDAPUseNestedGroups').setDisabled(false);
		}
		zen('OrganizationId').setDisabled(false);
		zen('GroupId').setDisabled(false);
		zen('InstanceId').setDisabled(false);
		zen('RoleId').setDisabled(false);
		zen('EscalationRoleId').setDisabled(false);
		zen('NamespaceId').setDisabled(false);
		zen('RoutineId').setDisabled(false);
		zen('DelimiterId').setDisabled(false);
		zen('ExampleResults1').setDisabled(false);
		zen('ExampleResults2').setDisabled(false);
		zen('ExampleResults3').setDisabled(false);
		zen('LDAPGroupId').setDisabled(false);
		zen('LDAPInstanceId').setDisabled(false);
		zen('LDAPUniversalGroups').setDisabled(false);
		zen('LDAPAttributeNameSpace').setDisabled(true);
		zen('LDAPAttributeRoutine').setDisabled(true);
		zen('LDAPAttributeRoles').setDisabled(true);
	} else {
		zen('LDAPUseNestedGroups').setValue(0);
		zen('LDAPUseNestedGroups').setDisabled(true);
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
		zen('ExampleResults1').setDisabled(true);
		zen('ExampleResults2').setDisabled(true);
		zen('ExampleResults3').setDisabled(true);
		zen('LDAPGroupId').setDisabled(true);
		zen('LDAPInstanceId').setDisabled(true);
		zen('LDAPAttributeNameSpace').setDisabled(false);
		zen('LDAPAttributeRoutine').setDisabled(false);
		zen('LDAPAttributeRoles').setDisabled(false);
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
		// if (zen('LDAPUseGroups').getValue() == 1) zen('LDAPUseNestedGroups').setDisabled(false);
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
			Set Component.disabled = 1
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
	
		Set ..%GetComponentById("Name").value = ..PID
		Set ..%GetComponentById("lblName").value = ..PID
		i KerberosEnabled {
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("LDAP/Kerberos configuration %1:"),..PID)
		} else {
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("LDAP configuration %1:"),..PID)
		}
		Set ..%GetComponentById("lblName").hidden = 0
		Set ..%GetComponentById("Name").hidden = 1
		
		Set tSC = ##class(%SYS.LDAP).Get(..PID,.Properties)
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
	If $$$ISWINDOWS {
	 	Set ..%GetComponentById("CertFileGroup").hidden = 1
	 	Set ..%GetComponentById("CertFileGroup").containerStyle = "padding:0;"
 	} 
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	s Status=##Class(Security.System).Get(,.Properties)
	i $zb(+Properties("AutheEnabled"),$$$AutheKB,1) {
		Quit $$$Text("LDAP/Kerberos configuration")
	} else {
		Quit $$$Text("LDAP configuration")
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

}
