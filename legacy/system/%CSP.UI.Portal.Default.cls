/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal 
Class %CSP.UI.Portal.Default Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Kit";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Default.zen";

Parameter HELPADDRESS = "Home,Provider,Defaults";

/// Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Kits.zen";
Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

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
<form autocomplete="false">
<label id="idRespond" enclosingClass="errorNote" hidden="true" containerStyle="padding-bottom:2px;"/>
<group id="groupEdit" cellStyle="padding:5px;" enclosingClass="EditForm" enclosingStyle="padding-top:2px;" labelPosition="left">
<text id="Name" label="Name" hidden="true" size="60" maxlength="64" hint="Required." onchange="zenPage.doModified();"/>
<text id="InstanceName" label="Instance Name" size="60" maxlength="64" hint="Required." onchange="zenPage.doModified();"/>
<text id="InstallDirectory" label="Install Directory" size="60" maxlength="255" hint="Required." onchange="zenPage.doModified();"/>
<text id="KitDirectory" label="Kit Directory" size="60" maxlength="255" hint="Required." onchange="zenPage.doModified();"/>
<text id="ManifestDirectory" label="Manifest Directory" size="60" maxlength="255" hint="Required." onchange="zenPage.doModified();"/>
<text id="Username" label="Username" size="60" maxlength="64" onchange="zenPage.doModified();"/>
<text id="Password" inputtype="password"  label="Password" size="60" maxlength="64" onchange="zenPage.doModified();"/>
<text id="PasswordConfirm" inputtype="password"  label="Password (confirm)" size="60" maxlength="64" onchange="zenPage.doModified();"/>
<text id="KeyFile" label="KeyFile" size="60" maxlength="255" onchange="zenPage.doModified();"/>
<text id="ManagerGroup" label="Manager Group" size="60" maxlength="64" hint="Required." onchange="zenPage.doModified();"/>
<text id="CacheGroup" label="Cache Group" size="60" maxlength="64" hint="Required." onchange="zenPage.doModified();"/>
<text id="CacheUser" label="Cache User" size="60" maxlength="64" hint="Required." onchange="zenPage.doModified();"/>
<radioSet id="Unicode" label="Install Type" valueList="0,1" displayList="8-Bit, Unicode" value="1" onchange="zenPage.doModified();" />
<select id="SecurityType" label="Security Type" onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("InstanceName").focus();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("Use the form below to edit a Provider Default:")
	Set ..HelpAddress = "Home,Provider Management,Edit Default"
	Set Status = ##class(Provider.Defaults).Get("SYSTEM",.Properties)
	i '$$$ISOK(Status) q Status
	d ..PopulateFields(.Properties)
	s ..%GetComponentById("PasswordConfirm").value=Properties("Password")
	Set ..%GetComponentById("SecurityType").displayList = ..EscapeHTML($$$Text("Minimal")_","_$$$Text("Normal")_","_$$$Text("Locked Down"))
	Set ..%GetComponentById("SecurityType").valueList = "Minimal,Normal,LockedDown"
	Quit $$$OK
}

Method PopulateFields(ByRef Properties As %String) As %Status
{
	// Loop to set all field values
	Set Property = ""
	Set Property = $O(Properties(Property)) 
	While Property '= ""  {
		Set Component = ..%GetComponentById(Property)
		If $ISO(Component) Set Component.value = Properties(Property)
		Set Property = $O(Properties(Property)) 
	}
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
		Quit $$$Text("Edit Provider Defaults")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Provider Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Defaults","%Utility")
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

/// Get user selection and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	proxy.Name = zen('Name').getValue();
	proxy.InstanceName = zen('InstanceName').getValue();
	proxy.InstallDirectory = zen('InstallDirectory').getValue();
	proxy.KitDirectory = zen('KitDirectory').getValue();
	proxy.ManifestDirectory = zen('ManifestDirectory').getValue();
	proxy.Username = zen('Username').getValue();
	proxy.Password = zen('Password').getValue();
	proxy.KeyFile = zen('KeyFile').getValue();
	proxy.ManagerGroup = zen('ManagerGroup').getValue();
	proxy.CacheGroup = zen('CacheGroup').getValue();
	proxy.CacheUser = zen('CacheUser').getValue();
	proxy.SecurityType = zen('SecurityType').getValue();
	proxy.Unicode = zen('Unicode').getValue();
	var result = this.SaveData(proxy);
	// saved existing app
	this.afterSave(result);
	//this.showMsg($$$Text('Kit saved.'),false);
}

ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	var opener = this.getOpener();
	if (opener) {
		self.close();
	} else {
		self.document.location = this.ParentURL;
	}
}

/// Save general association data to server
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
		#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		s Properties("InstanceName")=pProxy.InstanceName 
		s Properties("InstallDirectory")=pProxy.InstallDirectory
		s Properties("KitDirectory")=pProxy.KitDirectory
		s Properties("ManifestDirectory")=pProxy.ManifestDirectory
		s Properties("Username")=pProxy.Username
		s Properties("Password")=pProxy.Password
		s Properties("KeyFile")=pProxy.KeyFile
		s Properties("ManagerGroup")=pProxy.ManagerGroup
		s Properties("CacheGroup")=pProxy.CacheGroup
		s Properties("CacheUser")=pProxy.CacheUser
		s Properties("SecurityType")=pProxy.SecurityType
		s Properties("Unicode")=pProxy.Unicode
		Set tSC = ##class(Provider.Defaults).Modify("SYSTEM",.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
