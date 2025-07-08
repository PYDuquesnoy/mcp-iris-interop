/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal 
Class %CSP.UI.Portal.Install Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Install";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Install.zen";

Parameter HELPADDRESS = "Home,Provider,Installs";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Installs.zen";

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
<select id="Kit" label="Kit to install" onchange="zenPage.doModified();"/>
<select id="Manifest" label="Manifest to install" onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
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
		Set ..lblTitle = $$$Text("Use the form below to create a new Provider Install:")
		Set ..HelpAddress = "Home,Provider Management,Installs,Add Install"
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to edit a Provider Install:")
		Set ..HelpAddress = "Home,Provider Management,Installs,Edit Install"
		Set Status = ##class(Provider.Installs).Get(..PID,.Properties)
		i '$$$ISOK(Status) q Status
		d ..PopulateFields(.Properties)
	}
	Set Status = ..PopulateKitDropdown(.displayList,.valueList)
	If $$$ISERR(Status) Quit Status
	Set ..%GetComponentById("Kit").displayList = displayList
	Set ..%GetComponentById("Kit").valueList = valueList
	Set Status = ..PopulateManifestDropdown(.displayList,.valueList)
	If $$$ISERR(Status) Quit Status
	Set ..%GetComponentById("Manifest").displayList = displayList
	Set ..%GetComponentById("Manifest").valueList = valueList

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

Method PopulateKitDropdown(Output displayList As %String, Output valueList As %String) As %Status
{
 Set (displayList,valueList) = ""
 Set Rset = ##class(%ResultSet).%New("Provider.Kits:List")
 i '$$$ISOK(Rset) d $SYSTEM.Status.DisplayError(%objlasterror) q
 s Status=Rset.Execute("*")
 i '$$$ISOK(Status) q Status
 While Rset.Next(.Status) {
	s Name=Rset.Data("Name")
	s Description= Rset.Data("Description")
	If valueList = "" {
		Set valueList = Name
		Set displayList = ..EscapeHTML(Name_" - "_Description)
	} Else {
		Set valueList = valueList_","_Name
		Set displayList = displayList_","_..EscapeHTML(Name_" - "_Description)
	}
 }
 Quit $$$OK
}

Method PopulateManifestDropdown(Output displayList As %String, Output valueList As %String) As %Status
{
 Set (displayList,valueList) = ""
 Set Rset = ##class(%ResultSet).%New("Provider.Manifests:List")
 i '$$$ISOK(Rset) d $SYSTEM.Status.DisplayError(%objlasterror) q
 s Status=Rset.Execute("*")
 i '$$$ISOK(Status) q Status
 While Rset.Next(.Status) {
	s Name=Rset.Data("Name")
	s Description= Rset.Data("Description")
	If valueList = "" {
		Set valueList = Name
		Set displayList = ..EscapeHTML(Name_" - "_Description)
	} Else {
		Set valueList = valueList_","_Name
		Set displayList = displayList_","_..EscapeHTML(Name_" - "_Description)
	}
 }
 Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..isNew {
		Quit $$$Text("New Provider Install")
	} Else {
		Quit $$$Text("Edit Provider Install")
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

	Set tPageName = $$$Text("Installs","%Utility")
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
	proxy.Description = zen("Description").getValue();
	proxy.Kit = zen('Kit').getValue();
	proxy.Manifest = zen('Manifest').getValue();
	var result = this.SaveData(proxy);
	// saved existing app
	this.afterSave(result);
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
		Set Properties("Description") = pProxy.Description
		Set Properties("Kit")=pProxy.Kit
		Set Properties("Manifest")=pProxy.Manifest
		If pProxy.PID = "" {
			Set tSC = ##class(Provider.Installs).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(Provider.Installs).Modify(pProxy.Name,.Properties)
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
