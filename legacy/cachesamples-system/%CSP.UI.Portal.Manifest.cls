/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal 
Class %CSP.UI.Portal.Manifest Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Manifest";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Manifest.zen";

Parameter HELPADDRESS = "Home,Provider,Manifests";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Manifests.zen";

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
<text id="Name" label="Name" size="60" maxlength="64" hint="Required." onchange="zenPage.doModified();"/>
<text id="Description" label="Description" size="60" maxlength="256" onchange="zenPage.doModified();"/>
<hgroup id="TarFileManifest" labelPosition="left" label="Tar file containing install Manifest" cellVAlign="top">
<text id="TarFile" size="60" hint="Required." onchange="zenPage.doModified();"/>
<text id="TarFileDefault" hidden="true" size="60" hint="Required." onchange="zenPage.doModified();"/>
<button id="btnBrowse1" caption="Browse..." onclick="zenPage.browseSelect('TarFile','*.tar.*');"/>
</hgroup>
<text id="Product" label="Product" size="60" maxlength="64" onchange="zenPage.doModified();"/>
<text id="Version" label="Version" size="60" maxlength="64" onchange="zenPage.doModified();"/>
<text id="BuildNumber" label="BuildNumber" size="60" maxlength="64" onchange="zenPage.doModified();"/>
<text id="Platform" label="Platform" size="60" maxlength="64" onchange="zenPage.doModified();"/>
<text id="Type" label="Type" size="60" maxlength="64" onchange="zenPage.doModified();"/>
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
	if (Dir == '') Dir=zenPage.getComponentById('TarFileDefault').getValue(); 
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var PID = this.PID;
	if (PID != "") {
		zen("Description").focus();
	} else {
		zen("Name").focus();
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	#; If a PID is purposely removed when this page is rendered, then set it isNew to true.
	If ..PID = "" Set ..isNew = 1

	If ..isNew {
		Set ..lblTitle = $$$Text("Use the form below to create a new Provider Manifest:")
		Set ..HelpAddress = "Home,Provider Management,Manifests,Add Manifest"
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to edit a Provider Manifest:")
		Set ..HelpAddress = "Home,Provider Management,Manifests,Edit Manifest"
		Set Status = ##class(Provider.Manifests).Get(..PID,.Properties)
		i '$$$ISOK(Status) q Status
		d ..PopulateFields(.Properties)
	}
	s Status=##Class(Provider.Defaults).Get("SYSTEM",.Properties)
	i '$$$ISOK(Status) q Status
	s ..%GetComponentById("TarFileDefault").value=Properties("ManifestDirectory")
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
	If ..isNew {
		Quit $$$Text("New Provider Manifest")
	} Else {
		Quit $$$Text("Edit Provider Manifest")
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

	Set tPageName = $$$Text("Provider Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Manifests","%Utility")
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
	proxy.TarFile = zen('TarFile').getValue();
	proxy.Description = zen("Description").getValue();
	proxy.Product = zen("Product").getValue();
	proxy.Version = zen("Version").getValue();
	proxy.BuildNumber = zen("BuildNumber").getValue();
	proxy.Platform = zen("Platform").getValue();
	proxy.Type = zen("Type").getValue();
	var result = this.SaveData(proxy);
	// saved existing app
	this.afterSave(result);
	//this.showMsg($$$Text('Manifest saved.'),false);
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

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zen("browseselect").getValue();
			zen(name).setValue(value);
			this.doModified();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Save general association data to server
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
		#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("Description") = pProxy.Description
		Set Properties("TarFile")=pProxy.TarFile
		Set Properties("Product")=pProxy.Product
		Set Properties("Version")=pProxy.Version
		Set Properties("BuildNumber")=pProxy.BuildNumber
		Set Properties("Platform")=pProxy.Platform
		Set Properties("Type")=pProxy.Type
		If pProxy.PID = "" {
			Set tSC = ##class(Provider.Manifests).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(Provider.Manifests).Modify(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
