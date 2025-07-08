/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Parameters Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "System-wide Security Parameters";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Parameters.zen";

Parameter HELPADDRESS = "System Administration,Security,System Security,System-wide Security Parameters";

Parameter EMSSERVICE = "Security";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm">
<group cellStyle="padding:4px;" labelPosition="left">
<checkbox id="AuditEnabled" label="Enable audit" onchange="zenPage.AuditChanged(zenThis.getValue());"/>
<checkbox id="AuditFlags" label="Freeze system on audit database error" onchange="zenPage.doModified();"/>
<checkbox id="ConfigurationSecurityEnabled" label="Enable configuration security" onchange="zenPage.doModified();"/>
<select id="DefaultSecurityDomain" label="Default security domain" showEmpty="false" onchange="zenPage.doModified();"/>
<text id="DefaultSecurityDomainPrev" hidden="true" onchange="zenPage.doModified();"/>
<text id="InactiveLimit" label="Inactive limit" hint="Required. (0-365)" size="8" onchange="zenPage.doModified();"/>
<text id="InvalidLoginLimit" label="Invalid login limit" hint="Required. (0-64)" size="8" onchange="zenPage.doModified();"/>
<checkbox id="InvalidLoginAction" label="Disable account if login limit reached" onchange="zenPage.doModified();"/>
<text id="PasswordExpirationDays" label="Password expiration days" hint="Required. (0-99999)" size="8" onchange="zenPage.doModified();"/>
<text id="PasswordPattern" label="Password pattern" size="40" onchange="zenPage.doModified();"/>
<text id="PasswordValidationRoutine" label="Password validation routine" size="40" onchange="zenPage.doModified();"/>
<text id="RequiredRole" label="Role required to connect to this system" size="40" onchange="zenPage.doModified();"/>
<checkbox id="PercentGlobalWrite" label="Enable writing to percent globals" onchange="zenPage.doModified();"/>
<checkbox id="SecurityDomains" label="Allow multiple security domains" onchange="zenPage.doModified();"/>
<checkbox id="SecurityDomainsPrev" hidden="true" onchange="zenPage.doModified();"/>
<radioSet id="SSLTelnetServer" label="Telnet server SSL/TLS support" valueList="0,1,2" displayList="Disabled,Enabled,Required" layout="vertical" onchange="zenPage.SSLChanged(zenThis.getValue(),1);" hidden="true"/>
<select id="DefaultSignatureHash" label="Default signature hash" showEmpty="false" onchange="zenPage.doModified();"/>
<text id="EscalateLoginTimeout" label="Escalated Login Timeout" hint="Required." size="8" onchange="zenPage.doModified();"/>
<text id="EscalateAuthTimeout" label="Escalated Authentication Timeout" hint="Required." size="8" onchange="zenPage.doModified();"/>
</group>
<group id="SSLTelnetWarning" cellStyle="padding:4px;" hidden="true">
<label label="Warning: You must define an SSL/TLS server configuration named '%TELNET/SSL' before you can configure the Telnet server to use SSL/TLS." labelClass="rednote"/>
</group>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.resetMsg();
}

/// onchange handler for SSLSuperServer SSLTelnetServer fields:
/// type=0 for SuperServer type=1 for Telnet Server
ClientMethod SSLChanged(newvalue, type) [ Language = javascript ]
{
	this.doModified();
	var warn = (type==0? 'SSLSSWarning': 'SSLTelnetWarning');
	if (newvalue>0 && this.CheckSSLConfig(type)!=1) {
			zen(warn).setHidden(false);
	} else {
		zen(warn).setHidden(true);
	}
}

ClientMethod AuditChanged(newvalue) [ Language = javascript ]
{
	this.doModified();
	if (newvalue == 1) {
		zen('AuditFlags').setHidden(false);
	} else {
		zen('AuditFlags').setHidden(true);
	}
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('InactiveLimit'),pass,"N",true,0,365)) pass = false;
		if (!this.validateRequired(zen('InvalidLoginLimit'),pass,"N",true,0,64)) pass = false;
		if (!this.validateRequired(zen('PasswordExpirationDays'),pass,"N",true,0,99999)) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

/// Save current item.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		var proxy = new zenProxy();
		
			if (!this.validate()) {
				this.afterValidate();
				return;
			}
			
			proxy.DefaultSecurityDomain = zen('DefaultSecurityDomain').getValue();
			proxy.DefaultSignatureHash = zen('DefaultSignatureHash').getValue();
			proxy.InactiveLimit = zen('InactiveLimit').getValue();
			proxy.InvalidLoginLimit = zen('InvalidLoginLimit').getValue();
			proxy.InvalidLoginAction = zen('InvalidLoginAction').getValue();
			proxy.PasswordExpirationDays = zen('PasswordExpirationDays').getValue();
			proxy.PasswordPattern = zen('PasswordPattern').getValue();
			proxy.PasswordValidationRoutine = zen('PasswordValidationRoutine').getValue();
			proxy.SecurityDomains = zen('SecurityDomains').getValue();
		proxy.AuditEnabled = zen('AuditEnabled').getValue();
		proxy.AuditFlags = zen('AuditFlags').getValue();
		proxy.ConfigurationSecurityEnabled = zen('ConfigurationSecurityEnabled').getValue();
		proxy.RequiredRole = zen('RequiredRole').getValue();
		proxy.PercentGlobalWrite = zen('PercentGlobalWrite').getValue();
		proxy.SSLTelnetServer = zen('SSLTelnetServer').getValue();
		proxy.EscalateLoginTimeout = zen('EscalateLoginTimeout').getValue();
		proxy.EscalateAuthTimeout = zen('EscalateAuthTimeout').getValue();
		proxy.Logout = 0;
		if (zen('SecurityDomainsPrev').getValue() != zen('SecurityDomains').getValue()) {
				proxy.Logout = 1;
		}
		if (zen('SecurityDomainsPrev').getValue() != 0) {
			if (zen('DefaultSecurityDomainPrev').getValue() != zen('DefaultSecurityDomain').getValue()) {
				proxy.Logout = 1;
			}
		}
		var result = this.SaveData(proxy);
		if (result.ok == 1) {
			if (proxy.Logout == 1) alert("Default security domain or multiple domains has changed, you must log in again");
		}
		this.afterSave(result);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod CheckSSLConfig(type As %Integer) As %Boolean [ ZenMethod ]
{
 if type=1 {
		Quit ##class(Security.SSLConfigs).Exists("%TELNET/SSL")
 } else {
 	Quit 0
 }
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
			Set Properties("DefaultSecurityDomain") = pProxy.DefaultSecurityDomain
			Set Properties("DefaultSignatureHash") = pProxy.DefaultSignatureHash
			Set Properties("InactiveLimit") = pProxy.InactiveLimit
			Set Properties("InvalidLoginLimit") = pProxy.InvalidLoginLimit
			Set Properties("InvalidLoginAction") = pProxy.InvalidLoginAction
			Set Properties("PasswordExpirationDays") = pProxy.PasswordExpirationDays
			Set Properties("PasswordPattern") = pProxy.PasswordPattern
			Set Properties("PasswordValidationRoutine") = pProxy.PasswordValidationRoutine
			Set Properties("SecurityDomains") = pProxy.SecurityDomains
		Set Properties("AuditEnabled") = pProxy.AuditEnabled
		If (Properties("AuditEnabled")'=0) {
			Set Properties("AuditFlags") = pProxy.AuditFlags
		} else {
			Set Properties("AuditFlags") = 0
		}
		Set Properties("ConfigurationSecurityEnabled") = pProxy.ConfigurationSecurityEnabled
		Set Properties("RequiredRole") = pProxy.RequiredRole
		Set Properties("PercentGlobalWrite") = pProxy.PercentGlobalWrite
		Set Properties("SSLTelnetServer") = pProxy.SSLTelnetServer
		Set Properties("EscalateLoginTimeout") = pProxy.EscalateLoginTimeout
		Set Properties("EscalateAuthTimeout") = pProxy.EscalateAuthTimeout
		
		Set tSC = ##Class(Security.System).Modify($$$SystemSecurityName,.Properties)
		If $$$ISERR(tSC) {
			throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		if pProxy.Logout d %session.Logout(1) d %session.%SaveData(%session.SessionId)

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..lblTitle = $$$Text("Edit System-wide Security Parameters:")
	
	Set tSC = ..PopulateDomainList()
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
		Quit $$$OK
	}
	
	Set tSC = ##Class(Security.System).Get($$$SystemSecurityName,.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
		Quit $$$OK
	}
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	If (Properties("AuditEnabled")=0) {
		Set ..%GetComponentById("AuditFlags").hidden = 1
	}
	
	If ($$$ISWINDOWS) {
		Set ..%GetComponentById("SSLTelnetServer").hidden = 0
		If (Properties("SSLTelnetServer") > 0) && (..CheckSSLConfig(1) = 0) {
			Set ..%GetComponentById("SSLTelnetWarning").hidden = 0
	}
	}
	Set ..%GetComponentById("SecurityDomainsPrev").value=..%GetComponentById("SecurityDomains").value
	Set ..%GetComponentById("DefaultSecurityDomainPrev").value=..%GetComponentById("DefaultSecurityDomain").value

	Quit $$$OK
}

Method PopulateDomainList() As %Status
{
	Set (valueList,displayList) = ""
	Set tRS = ##class(%ResultSet).%New("Security.LDAPConfigs:List")
	Do tRS.Execute("*")
	While tRS.Next() {
		If (valueList '= "") {
			Set valueList = valueList_","
			Set displayList = displayList_","
		}
		Set valueList = valueList_tRS.GetData(1)
		Set displayList = displayList_..EscapeHTML(tRS.GetData(1))
	}
	Set Component = ..%GetComponentById("DefaultSecurityDomain")
	Set Component.valueList = valueList
	Set Component.displayList = displayList
	
	Set Component = ..%GetComponentById("DefaultSignatureHash")
	Set Component.valueList = "SHA1,SHA256,SHA384,SHA512"
	Set Component.displayList = "SHA1,SHA256,SHA384,SHA512"
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("System-wide Security Parameters")
}

/// Return the array of links to show in the locator bar.<br/>
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

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
