/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Server Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Superserver";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Servers.zen";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Server.zen";

Parameter HELPADDRESS = "System Administration,Security,Servers,Edit Superserver";

Parameter EMSSERVICE = "Security";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<group labelPosition="left" cellStyle="padding:4px;">
<text id="Description" label="Description" size="64" onchange="zenPage.doModified();"/>
<text id="Port" label="Port" size="6" hint="Required." onchange="zenPage.doModified();"/>
<text id="BindAddress" label="Bind Address" size="64" onchange="zenPage.doModified();"/>
<checkbox id="SystemDefault" label="System default" onchange="zenPage.doModified();"/>
<checkbox id="Enabled" label="Enabled" onchange="zenPage.doModified();"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left" label="Client Connections">
<checkbox id="EnableClients" label="Enable Clients" onchange="zenPage.doModified();"/>
<checkbox id="EnableCSP" label="Enable CSP/REST" onchange="zenPage.doModified();"/>
<checkbox id="EnableDataCheck" label="Enable DataCheck" onchange="zenPage.doModified();"/>
<link id="LegacySettings" caption="Legacy Settings" href="#" onclick="zenPage.toggle1();"/>
<checkbox id="EnableCacheDirect" label="Enable CacheDirect" hidden="true" onchange="zenPage.doModified();"/>
<checkbox id="EnableShadows" label="Enable Shadows" hidden="true" onchange="zenPage.doModified();"/>
<radioSet id="SSLSupportLevel" label="SSL/TLS support level" valueList="0,1,2" displayList="Disabled,Enabled,Required" layout="vertical" onchange="zenPage.doModified();"/>
<select id="SSLConfig" label="SSL/TLS configuration" title="Specifies an SSL/TLS configuration the client must use." onchange="zenPage.doModified();"/>
</group>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left"  label="System Connections">
<checkbox id="EnableECP" label="Enable ECP" hint="System Default Server only." onchange="zenPage.doModified();"/>
<checkbox id="EnableMirror" label="Enable Mirror" hint="System Default Server only." onchange="zenPage.doModified();"/>
<checkbox id="EnableSharding" label="Enable Sharding" hint="System Default Server only." onchange="zenPage.doModified();"/>
</group>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left" label="Other Connections (SSL/TLS not supported)">
<checkbox id="EnableSNMP" label="Enable SNMP" hidden="false" hint="Windows only." onchange="zenPage.doModified();"/>
<link id="LegacySettings1" caption="Legacy Settings" href="#" onclick="zenPage.toggle2();"/>
<checkbox id="EnableWebLink" label="Enable WebLink " hidden="true" onchange="zenPage.doModified();"/>
<checkbox id="EnableNodeJS" label="Enable NodeJS" hidden="true" onchange="zenPage.doModified();"/>
</group>
</group>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zen('errmsg').getProperty('hidden') == false) {
		this.disableCommandButton('btnSave');
	}
}

ClientMethod selectChanged(which, newVal) [ Language = javascript ]
{
	zen(which).setValue(newVal);
	this.doModified();
}

ClientMethod toggle(groupID) [ Language = javascript ]
{
	var group = zen(groupID);
	group.setHidden(!group.getProperty('hidden'))
}

ClientMethod toggle1() [ Language = javascript ]
{
	var group = zen('EnableCacheDirect');
	group.setHidden(!group.getProperty('hidden'))
	var group = zen('EnableShadows');
	group.setHidden(!group.getProperty('hidden'))
}

ClientMethod toggle2() [ Language = javascript ]
{
	var group = zen('EnableWebLink');
	group.setHidden(!group.getProperty('hidden'))
	var group = zen('EnableNodeJS');
	group.setHidden(!group.getProperty('hidden'))
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	return 1
}

/// Save current item.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		// if user has not changed anything but hit Save, then we can just close out.
		if (!this.pageModified) {
			this.doCancel();
			return;
		}
		
		if (this.PID == "&") {
			if (!this.validate()) {
				this.afterValidate();
				return;
			}
		}
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.Port = zen('Port').getValue();
		proxy.BindAddress = zen('BindAddress').getValue();
		proxy.Description = zen('Description').getValue();
		proxy.EnableCacheDirect = zen('EnableCacheDirect').getValue();
		proxy.EnableClients = zen('EnableClients').getValue();
		proxy.EnableCSP = zen('EnableCSP').getValue();
		proxy.EnableDataCheck = zen('EnableDataCheck').getValue();
		proxy.EnableECP = zen('EnableECP').getValue();
		proxy.EnableMirror = zen('EnableMirror').getValue();
		proxy.EnableNodeJS = zen('EnableNodeJS').getValue();
		proxy.EnableShadows = zen('EnableShadows').getValue();
		proxy.EnableSharding = zen('EnableSharding').getValue();
		proxy.EnableWebLink = zen('EnableWebLink').getValue();
		proxy.EnableSNMP = zen('EnableSNMP').getValue();
		proxy.Enabled = zen('Enabled').getValue();
		proxy.SSLSupportLevel = zen('SSLSupportLevel').getValue();
		proxy.SSLConfig = zen('SSLConfig').getValue();
		proxy.SystemDefault = zen('SystemDefault').getValue();
		var ok = this.SaveData(proxy);
		this.afterSave(ok);
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

		Set Properties("SystemDefault") = pProxy.SystemDefault
		Set Properties("Description") = pProxy.Description
		Set Properties("EnableCacheDirect") = pProxy.EnableCacheDirect
		Set Properties("EnableClients") = pProxy.EnableClients
		Set Properties("EnableCSP") = pProxy.EnableCSP
		Set Properties("EnableDataCheck") = pProxy.EnableDataCheck
		Set Properties("EnableECP") = pProxy.EnableECP
		Set Properties("EnableMirror") = pProxy.EnableMirror
		Set Properties("EnableNodeJS") = pProxy.EnableNodeJS
		Set Properties("EnableShadows") = pProxy.EnableShadows
		Set Properties("EnableSharding") = pProxy.EnableSharding
		Set Properties("EnableSNMP") = pProxy.EnableSNMP
		Set Properties("EnableWebLink") = pProxy.EnableWebLink
		Set Properties("Enabled") = pProxy.Enabled
		Set Properties("SSLSupportLevel") = pProxy.SSLSupportLevel
		Set Properties("SSLConfig") = pProxy.SSLConfig
		Set Properties("SystemDefault") = pProxy.SystemDefault
		If pProxy.PID = "&" {			
			Set tSC = ##class(Security.Servers).Create(pProxy.Port,pProxy.BindAddress,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(Security.Servers).Modify(pProxy.Port,pProxy.BindAddress,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
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
	// Populate the Resource dropdown
	Set tRS = ##class(%ResultSet).%New("Security.SSLConfigs:List")
	Do tRS.Execute("*",1)
	Set valueList = ""
	While tRS.Next() {
		Set name = tRS.GetData(1)
		If valueList = "" {
			Set valueList = name
		} Else {
			Set valueList = valueList_","_name
		}
	}
	Set (..%GetComponentById("SSLConfig").displayList,..%GetComponentById("SSLConfig").valueList) = valueList


	If ..PID = "&" {
		Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the form below to create a new superserver:")
		s Status=##Class(Security.Servers).CreateCSPDefault(.Properties)
		i '$$$ISOK(Status) q Status
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
		
		Set Component = ..%GetComponentById("SystemDefault")
		Set Component.hidden = 1
	} Else {
		i $p(..PID,"&",2,*)="" {
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Use the form below to edit superserver %1"),$p(..PID,"&",1))
		} else {
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Use the form below to edit superserver %1 on Bind Address %2"),$p(..PID,"&",1),$p(..PID,"&",2,*))
		}
		Set Port=$p(..PID,"&",1)
		Set BindAddress=$p(..PID,"&",2,*)
		s Status=##Class(Security.Servers).Get(Port,BindAddress,.Properties)
		i '$$$ISOK(Status) q Status
		s Properties("Port")=Port
		s Properties("BindAddress")=BindAddress
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
		Set Component = ..%GetComponentById("Port")
		Set Component.disabled = 1
		Set Component = ..%GetComponentById("BindAddress")
		Set Component.disabled = 1
		Set Component = ..%GetComponentById("SystemDefault")
		Set Component.disabled = 1
	}
#;For now we can only run these off the default port
	i Properties("SystemDefault")=0 {
		Set Component = ..%GetComponentById("EnableECP")
		Set Component.disabled=1
		Set Component = ..%GetComponentById("EnableMirror")
		Set Component.disabled=1
		Set Component = ..%GetComponentById("EnableSharding")
		Set Component.disabled=1
	}
	i '$$$ISWINDOWS {
		Set Component = ..%GetComponentById("EnableSNMP")
		Set Component.disabled=1
	}		
	i Properties("EnableWebLink")||Properties("EnableCacheDirect")||Properties("EnableShadows")||Properties("EnableNodeJS") {
		Set Component = ..%GetComponentById("EnableWebLink")
		Set Component.hidden = 0		
		Set Component = ..%GetComponentById("EnableCacheDirect")
		Set Component.hidden = 0		
		Set Component = ..%GetComponentById("EnableShadows")
		Set Component.hidden = 0		
		Set Component = ..%GetComponentById("EnableNodeJS")
		Set Component.hidden = 0		
	}
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Superserver")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = $$$Text("Superservers","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// Subclass can override.
Method %OnGetTitle() As %String
{
	If ..IsEditForm,..PID'="&" Quit $$$FormatText($$$Text("Edit: %1 in namespace %2"),$zconvert($p(..PID,"&",1),"O","HTML"),$zconvert($p(..PID,"&",2,*),"O","HTML"))
	Quit ..LocatorHeader
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
