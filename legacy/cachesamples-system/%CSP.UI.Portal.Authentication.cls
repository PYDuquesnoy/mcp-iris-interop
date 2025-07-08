/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Authentication Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Authentication/Web Session Options";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Authentication.zen";

Parameter HELPADDRESS = "System Administration,Security,System Security,Authentication/Web Options";

Parameter EMSSERVICE = "Security";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property AutheEnabled As %Integer;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property IsNotAdvanced As %Boolean [ InitialExpression = 0 ];

Property OldTwoFactor As %Boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
.zenLabelDisabled {
	color:#404040;
    font-size:12px;
    font-weight:bold;
    padding-right:3px;
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
<form id="fld" autocomplete="false">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<checkbox id="AutheUnauthenticated" label="Allow Unauthenticated access" onchange="zenPage.doModified();"/>
<checkbox id="AutheOS" label="Allow O/S authentication" onchange="zenPage.doModified();"/>
<checkbox id="AutheOSDelegated" label="Allow O/S authentication with Delegated authorization" onchange="zenPage.doModified();"/>
<checkbox id="AutheOSLDAP" label="Allow O/S authentication with LDAP authorization" onchange="zenPage.LDAPChanged();"/>
<checkbox id="AutheCache" label="Allow Password authentication" onchange="zenPage.doModified();"/>
<checkbox id="AutheDelegated" label="Allow Delegated authentication" onchange="zenPage.DelegatedChanged();"/>
<checkbox id="AutheAlwaysTryDelegated" label="Always try Delegated authentication" disabled="true" onchange="zenPage.doModified();"/>
<checkbox id="AutheKB" label="Allow Kerberos authentication" onchange="zenPage.doModified();"/>
<checkbox id="AutheLDAP" label="Allow LDAP authentication" onchange="zenPage.LDAPChanged();"/>
<checkbox id="AutheLDAPCache" label="Allow LDAP cache credentials authentication" disabled="true" onchange="zenPage.doModified();"/>
<hgroup label="Allow creation of Login Cookies" labelPosition="left" cellVAlign="top">
<checkbox id="AutheLoginToken" onchange="zenPage.doModified();" valign="top"/>
<spacer width="5px"/>
<text id="LoginCookieTimeout" label="Login Cookie expire time (secs)" hint="0 implies non-persistent cookie" size="8" containerStyle="padding:0 8px;" onchange="zenPage.doModified();"/>
</hgroup>
<checkbox id="AutheTwoFactorPW" label="Allow Two-factor Time-based One-time Password authentication" onchange="zenPage.twoFactorPWChanged(zenThis.getValue());"/>
<text id="TwoFactorPWIssuer" label="Two-factor Time-based One-time Password issuer" size="50" onchange="zenPage.doModified();" hidden="true"/>
<checkbox id="AutheTwoFactorSMS" label="Allow Two-factor SMS text authentication" onchange="zenPage.twoFactorChanged(zenThis.getValue());"/>
<fieldSet id="TwoFactorSection" label="Two-factor authentication" labelPosition="left" cellStyle="padding:4px;" hidden="true">
<text id="TwoFactorTimeout" label="Two-factor Timeout (secs)" onchange="zenPage.doModified();" hidden="true"/>
<text id="SMTPServer" label="DNS name of SMTP server" hint="Required." onchange="zenPage.doModified();"/>
<text id="TwoFactorFrom" label="From (address)" hint="Required." onchange="zenPage.doModified();"/>
<text id="SMTPUsername" label="SMTP username" onchange="zenPage.doModified();"/>
<radioSet id="passwordChoice" label="Password" valueList="0,1,2" displayList="Enter new password,Clear password,Leave as is" value="0" onchange="zenPage.passwordChanged(zenThis.getValue());" hidden="true"/>
<text inputtype="password" id="SMTPPassword" label="SMTP password" onchange="zenPage.doModified();"/>
<text inputtype="password" id="SMTPPasswordVer" label="SMTP password (confirm)" onchange="zenPage.doModified();"/>
</fieldSet>
<text id="JWTIssuer" label="JWT Issuer field" size="50" onchange="zenPage.doModified();"/>
<select id="JWTSigAlg" label="JWT Signature Algorithm" showEmpty="false" onchange="zenPage.doModified();"/>
<button id="ResetJWKS" caption="Reset Key Store" onclick="zenPage.doResetJWKS();"/>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.resetMsg();
}

ClientMethod doResetJWKS() [ Language = javascript ]
{
	var result = this.ResetJWKS();
	if (result.ok==1) {
		this.showMsg($$$Text("Key Store Reset"),0)
	} else {
		this.afterSave(result);
	}
}

ClassMethod ResetJWKS() As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Do ##class(%SYS.TokenAuth).ResetSystemJWKS()

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClientMethod LDAPChanged() [ Language = javascript ]
{
	this.doModified();
	var comp = zen('AutheLDAPCache');
	if ((zen('AutheLDAP').getValue() == 0) && (zen('AutheOSLDAP').getValue() == 0)){
		comp.setValue(false);
		comp.setDisabled(true);
	} else {
		comp.setDisabled(false);
	}
}

ClientMethod DelegatedChanged() [ Language = javascript ]
{
	this.doModified();
	var comp = zen('AutheAlwaysTryDelegated');
	if ((zen('AutheDelegated').getValue() == 0)){
		comp.setValue(false);
		comp.setDisabled(true);
	} else {
		comp.setDisabled(false);
	}
}

ClientMethod twoFactorChanged(newvalue) [ Language = javascript ]
{
	this.doModified();
	if (newvalue == 0) {
		zen('TwoFactorSection').setHidden(true);
		zen("TwoFactorTimeout").setHidden(true)
	} else {
		zen('TwoFactorSection').setHidden(false);
		zen("TwoFactorTimeout").setHidden(false)
	}
}

ClientMethod twoFactorPWChanged(newvalue) [ Language = javascript ]
{
	this.doModified();
	if (newvalue == 0) {
		zen('TwoFactorPWIssuer').setHidden(true);
	} else {
		zen('TwoFactorPWIssuer').setHidden(false);
	}
}

ClientMethod passwordChanged(newvalue) [ Language = javascript ]
{
	this.doModified();
	if (newvalue > 0) {
		zen('SMTPPassword').setHidden(true);
		zen('SMTPPasswordVer').setHidden(true);
	} else {
		zen('SMTPPassword').setHidden(false);
		zen('SMTPPasswordVer').setHidden(false);
	}
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (zen('AutheTwoFactorSMS').getValue()) {
			if (!this.validateRequired(zen('SMTPServer'),pass,"S")) pass = false;
			if (!this.validateRequired(zen('TwoFactorFrom'),pass,"S")) pass = false;
			if (zen('passwordChoice').getValue() == 0) {
				if (zen('SMTPPassword').getValue() != zen('SMTPPasswordVer').getValue()) {
					zen('SMTPPasswordVer').setProperty("hintClass","redText");
					zen('SMTPPasswordVer').setProperty("controlClass","zenInvalid");
					if (pass) {
						this.FirstFailed = 'SMTPPasswordVer';
					}
					pass = false;
				} else {
					zen('SMTPPasswordVer').setProperty("hintClass","helpText");
					zen('SMTPPasswordVer').setProperty("controlClass","");
				}
			}
		}
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
		
		if (!this.validate()) {
			this.afterValidate();
			return;
		}
		
		var proxy = new zenProxy();
		
		proxy.AutheEnabled = this.AutheEnabled;
		proxy.AutheUnauthenticated = zen('AutheUnauthenticated').getValue();
		proxy.AutheOS = zen('AutheOS').getValue();
		proxy.AutheOSDelegated = zen('AutheOSDelegated').getValue();
		proxy.AutheOSLDAP = zen('AutheOSLDAP').getValue();
		proxy.AutheCache = zen('AutheCache').getValue();
		proxy.AutheDelegated = zen('AutheDelegated').getValue();
		proxy.AutheAlwaysTryDelegated = zen('AutheAlwaysTryDelegated').getValue();
		proxy.AutheKB = zen('AutheKB').getValue();
		proxy.AutheLDAP = zen('AutheLDAP').getValue();
		proxy.AutheLDAPCache = zen('AutheLDAPCache').getValue();
		proxy.AutheLoginToken = zen('AutheLoginToken').getValue();
		proxy.LoginCookieTimeout = zen('LoginCookieTimeout').getValue();
		proxy.AutheTwoFactorPW = zen('AutheTwoFactorPW').getValue();
		proxy.AutheTwoFactorSMS = zen('AutheTwoFactorSMS').getValue();
		proxy.SMTPPassword = zen('SMTPPassword').getValue();
		proxy.SMTPServer = zen('SMTPServer').getValue();
		proxy.SMTPUsername = zen('SMTPUsername').getValue();
		proxy.TwoFactorFrom = zen('TwoFactorFrom').getValue();
		proxy.TwoFactorPWIssuer = zen('TwoFactorPWIssuer').getValue();
		proxy.TwoFactorTimeout = zen('TwoFactorTimeout').getValue();
		proxy.passwordChoice = zen('passwordChoice').getValue();
		proxy.OldTwoFactor = this.OldTwoFactor;
		proxy.JWTIssuer = zen('JWTIssuer').getValue();
		proxy.JWTSigAlg = zen('JWTSigAlg').getValue();
		
		var result = this.SaveData(proxy);
		this.afterSave(result);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##Class(Security.System).Get($$$SystemSecurityName,.Properties)
		If $$$ISERR(tSC) {
			throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		
		Set AutheEnabled = pProxy.AutheEnabled
		
		If pProxy.AutheUnauthenticated {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheUnauthenticated,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheUnauthenticated,2)
		}
		If pProxy.AutheOS {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheOS,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheOS,2)
		}
		If pProxy.AutheOSDelegated {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheOSDelegated,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheOSDelegated,2)
		}
		If pProxy.AutheOSLDAP {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheOSLDAP,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheOSLDAP,2)
		}
		If pProxy.AutheCache {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheCache,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheCache,2)
		}
		If pProxy.AutheDelegated {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheDelegated,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheDelegated,2)
		}
		If pProxy.AutheDelegated {
			If pProxy.AutheAlwaysTryDelegated {
				Set AutheEnabled = $zb(+AutheEnabled,$$$AutheAlwaysTryDelegated,7)
			} Else {
				Set AutheEnabled = $zb(+AutheEnabled,$$$AutheAlwaysTryDelegated,2)
			}
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheAlwaysTryDelegated,2)
		}
		If pProxy.AutheKB {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheKB+$$$AutheK5Prompt+$$$AutheK5API+$$$AutheK5KeyTab+$$$AutheK5CCache+$$$AutheKBIntegrity+$$$AutheKBEncryption,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheKB+$$$AutheK5Prompt+$$$AutheK5API+$$$AutheK5KeyTab+$$$AutheK5CCache+$$$AutheKBIntegrity+$$$AutheKBEncryption,2)
		}
		If pProxy.AutheLDAP {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheLDAP,7)
		} else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheLDAP,2)
		}
		If pProxy.AutheLDAP||pProxy.AutheOSLDAP {
			If pProxy.AutheLDAPCache {
				Set AutheEnabled = $zb(+AutheEnabled,$$$AutheLDAPCache,7)
			} Else {
				Set AutheEnabled = $zb(+AutheEnabled,$$$AutheLDAPCache,2)
			}
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheLDAPCache,2)
		}
		If pProxy.AutheLoginToken {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheLoginToken,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheLoginToken,2)
		}
		If pProxy.AutheTwoFactorSMS {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheTwoFactorSMS,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheTwoFactorSMS,2)
		}
		If pProxy.AutheTwoFactorPW {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheTwoFactorPW,7)
		} Else {
			Set AutheEnabled = $zb(+AutheEnabled,$$$AutheTwoFactorPW,2)
		}
		
		Set Properties("AutheEnabled") = AutheEnabled
		Set Properties("LoginCookieTimeout") = pProxy.LoginCookieTimeout
		If (pProxy.AutheTwoFactorSMS) {
			If (pProxy.OldTwoFactor = 0) {
				#; If user enabled it for the first time, then get it from SMTPPassword
				Set Properties("SMTPPassword") = pProxy.SMTPPassword
			} Else {
				#; If user is modifying an enable, then check the password choices and set it only if it's 0 or 1.
				If pProxy.passwordChoice = 0 {
					Set Properties("SMTPPassword") = pProxy.SMTPPassword
				} ElseIf pProxy.passwordChoice = 1 {
					Set Properties("SMTPPassword") = ""
				}
			}
		} Else {
			Set Properties("SMTPPassword") = ""
		}
		Set Properties("SMTPServer") = pProxy.SMTPServer
		Set Properties("SMTPUsername") = pProxy.SMTPUsername
		Set Properties("TwoFactorFrom") = pProxy.TwoFactorFrom
		Set Properties("TwoFactorPWIssuer") = pProxy.TwoFactorPWIssuer
		Set Properties("TwoFactorTimeout") = pProxy.TwoFactorTimeout
		Set Properties("JWTIssuer") = pProxy.JWTIssuer
		Set Properties("JWTSigAlg") = pProxy.JWTSigAlg
		Set tSC = ##Class(Security.System).Modify($$$SystemSecurityName,.Properties)
		If $$$ISERR(tSC) {
			throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}

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
	
	Set ..lblTitle = $$$Text("Edit Security Authentication/Web Session Options:")
	
	Set tSC = ##Class(Security.System).Get($$$SystemSecurityName,.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
		Quit $$$OK
	}
	
	Set Properties("SMTPPasswordVer") = Properties("SMTPPassword")
	Set (AutheEnabled,..AutheEnabled) = Properties("AutheEnabled")
	
	Set Properties("AutheUnauthenticated") = $zb(AutheEnabled,$$$AutheUnauthenticated,1) > 0
	Set Properties("AutheOS") = $zb(AutheEnabled,$$$AutheOS,1) > 0
	Set Properties("AutheOSDelegated") = $zb(AutheEnabled,$$$AutheOSDelegated,1) > 0
	Set Properties("AutheOSLDAP") = $zb(AutheEnabled,$$$AutheOSLDAP,1) > 0
	Set Properties("AutheCache") = $zb(AutheEnabled,$$$AutheCache,1) > 0
	Set Properties("AutheDelegated") = $zb(AutheEnabled,$$$AutheDelegated,1) > 0
	If (Properties("AutheDelegated") > 0){
		Set Properties("AutheAlwaysTryDelegated") = $zb(AutheEnabled,$$$AutheAlwaysTryDelegated,1) > 0
		Set ..%GetComponentById("AutheAlwaysTryDelegated").disabled = 0
	}
	Set Properties("AutheKB") = $zb(AutheEnabled,$$$AutheKB,1) > 0
	Set Properties("AutheLDAP") = $zb(AutheEnabled,$$$AutheLDAP,1) > 0
	Set Properties("AutheLoginToken") = $zb(AutheEnabled,$$$AutheLoginToken,1) > 0
	If (Properties("AutheLDAP") > 0)|| (Properties("AutheOSLDAP") > 0){
		Set Properties("AutheLDAPCache") = $zb(AutheEnabled,$$$AutheLDAPCache,1) > 0
		Set ..%GetComponentById("AutheLDAPCache").disabled = 0
	}
	Set Properties("AutheTwoFactorSMS") = $zb(AutheEnabled,$$$AutheTwoFactorSMS,1) > 0
	Set Properties("AutheTwoFactorPW") = $zb(AutheEnabled,$$$AutheTwoFactorPW,1) > 0

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
	
	If Properties("AutheTwoFactorSMS") {
		Set ..OldTwoFactor = 1
		Set ..%GetComponentById("TwoFactorSection").hidden = 0
		Set ..%GetComponentById("passwordChoice").hidden = 0
		Set ..%GetComponentById("passwordChoice").value = 2
		Set ..%GetComponentById("SMTPPassword").hidden = 1
		Set ..%GetComponentById("SMTPPasswordVer").hidden = 1
		Set ..%GetComponentById("TwoFactorTimeout").hidden = 0
	}	
	If Properties("AutheTwoFactorPW") {
		Set ..%GetComponentById("TwoFactorPWIssuer").hidden = 0
	}
	
	Set Component = ..%GetComponentById("JWTSigAlg")
	Set Component.valueList = "RS256,RS384,RS512,ES256,ES384,ES512"
	Set Component.displayList = "RS256,RS384,RS512,ES256,ES384,ES512"
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Authentication/Web Session Options")
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
