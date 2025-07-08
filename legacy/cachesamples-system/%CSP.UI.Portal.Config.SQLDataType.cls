/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Add or Edit a SQL Datatype Mapping
Class %CSP.UI.Portal.Config.SQLDataType Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.AdvancedEdit) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.SQLDataType.zen";

Parameter HELPADDRESS = "Home,Configuration,User-defined DDL Mappings";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "SQLDataType";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Config.SQLDataTypes.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// ID for edit. Null if adding new datatype mapping.
Property PID As %String(ZENURL = "PID");

Property Subject As %String(ZENURL = "Subject");

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
 <form id="fld">
<label id="idRespond" enclosingClass="errorNote" hidden="true" containerStyle="padding-bottom:4px;"/>
<vgroup cellStyle="padding:4px;" enclosingClass="EditForm" labelPosition="left" >
<vgroup id="idSystemDataTypes" labelPosition="left" cellStyle="padding:4px;" >
<text id="Name" label="Name" size="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="Datatype" label="Datatype" size="50" hint="Required." onchange="zenPage.doModified();"/>
 </vgroup> 
</vgroup>
</form>
</pane>
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	try {
		var pass = true;
		if (!this.validateRequired(zen("Name"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("Datatype"),pass,"S")) pass = false;
		return pass;
	} catch (ex) {
		alert("Error validate: " + ex);	
	}
}

ClientMethod getProxy() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.Name = zen('Name').getValue();
		proxy.Datatype = zen('Datatype').getValue();
		return proxy;
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

ClassMethod GetPropertyArray(pProxy As %ZEN.proxyObject, Output Properties) As %Status
{
	Set Properties("Datatype") = pProxy.Datatype
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..ParentURL = ..Link(..ParentURL,,1)_"Subject="_..EscapeURL(..Subject)
	
	If ..Subject = "UserDataTypes" {
		If ..PID '= "" {
			Set ..lblTitle = $$$Text("Use the form below to edit a mapping of a user-defined DDL datatype to an InterSystems datatype class:")
		} Else {
			Set ..lblTitle = $$$Text("Use the form below to map a user-defined DDL datatype to an InterSystems datatype class:")
		}
	} ElseIf ..Subject = "SystemDataTypes" {
		Set ..lblTitle = $$$Text("Use the form below to edit a mapping of a system-defined DDL datatype to an InterSystems datatype class:")
		Set ..HelpAddress = "Home,Configuration,SQL Settings,System-defined DDL Mappings,System-defined DDL Mapping"
	} Else {
		#; User tinkered with Subject from the URL!
		Set ..Subject = ""	
	}
	If ..Subject = "" {
		Set ..lblTitle = $$$Text("Incorrect Subject. Unable to continue.")
		Set ..HelpAddress = "Home,Configuration"
		Set ..%GetComponentById("fld").hidden = 1
		Set ..IsEditForm = 0
		Quit $$$OK	
	}
	
	If ..PID '= "" {
		Set tSC = ..PopulateFields()
		If $$$ISERR(tSC) Quit tSC
	}

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..Subject = "UserDataTypes" {
		If ..PID '= "" {
			Quit $$$Text("Edit User-defined DDL Mapping")
		} Else {
			Quit $$$Text("New User-defined DDL Mapping")
		}
	} ElseIf ..Subject = "SystemDataTypes" {
		Quit $$$Text("Edit System-defined DDL Mapping")
	} Else {
		Quit $$$TextHTML("Unknown Subject")
	}
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	If ..Subject = "" {
		Quit $$$OK
	}

	Set tPageName = $Case(..Subject,"UserDataTypes":$$$Text("User-defined DDL Mappings"),:$$$Text("System-defined DDL Mappings"))
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?Subject="_..EscapeURL(..Subject)_"&PID="_..EscapeURL(..PID)))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
