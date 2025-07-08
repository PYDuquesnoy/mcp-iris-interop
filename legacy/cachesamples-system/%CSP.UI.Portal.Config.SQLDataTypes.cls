/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Maintain SQL Datatypes
Class %CSP.UI.Portal.Config.SQLDataTypes Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav, %CSP.UI.Portal.Config.AdvancedList) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.SQLDataTypes.zen";

Parameter HELPADDRESS = "Home,Configuration,User-defined DDL Mappings";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "SQLDataTypes";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.Config.SQLDataType.zen")} ];

/// Subject name for the setting page. 
Property Subject As %String(ZENURL = "Subject");

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<vgroup id="fld">
<tableNavBar showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table" containerStyle="padding-bottom:4px;"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
showValueInTooltip="true"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
ondblclick="zenPage.editItem('',false,true)"
queryClass="Config.SqlSysDatatypes"
queryName="List"
>
<column colName="Name" header="Name"/>
<column colName="Datatype" header="Datatype"/>
<column colName="Comments" hidden="true"/>
<column linkCaption="Edit" id="LinkEdit" link="javascript:zenPage.editItem('#(%query.Name)#',false,true);" hidden="#(%page.IsEMSReadOnly)#"/>
<column linkCaption="Delete" id="LinkDelete" link="javascript:zenPage.deleteItem('#(%query.Name)#');" linkConfirm="Are you sure you want to delete definition '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="0"/>
 </tablePane>
 </vgroup>
 </pane>
}

/// Subclass can override.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	
	If ..Subject = "UserDataTypes" {
		Set ..lblTitle = $$$Text("The following is a list of mappings of user-defined DDL datatypes to InterSystems datatype classes:")
		Set ..%GetComponentById("table").queryClass = "Config.SqlUserDatatypes"		
	} ElseIf ..Subject = "SystemDataTypes" {
		Set ..lblTitle = $$$Text("The following is a list of mappings of system-defined DDL datatypes to InterSystems datatype classes:")
		Set ..HelpAddress = "Home,Configuration,System-defined DDL Mappings"
	} Else {
		#; User tinkered with Subject from the URL!
		Set ..Subject = ""	
	}
	If ..Subject = "" {
		Set ..lblTitle = $$$Text("Incorrect Subject. Unable to continue.")
		Set ..HelpAddress = "Home,Configuration"
		Set ..%GetComponentById("fld").hidden = 1
		Quit $$$OK	
	}

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	If ..Subject = "UserDataTypes" {
		Quit $$$TextHTML("User-defined DDL Mappings")
	} ElseIf ..Subject = "SystemDataTypes" {
		Quit $$$TextHTML("System-defined DDL Mappings")
	} Else {
		Quit $$$TextHTML("Unknown Subject")	
	}
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	If ..Subject = "" {
		Quit $$$OK
	}

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_"?Subject="_..EscapeURL(..Subject)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_NAMESPACE)))

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	
	// commands: $LB(id,caption,help,onclick)
	If (..Subject = "UserDataTypes") {
		Set caption = $$$Text("Create New User-defined DDL Mapping")
		Set pCommands(1) = $LB("btnNew",caption,caption,"zenPage.doNew(true);")
	}
	Quit $$$OK
}

}
