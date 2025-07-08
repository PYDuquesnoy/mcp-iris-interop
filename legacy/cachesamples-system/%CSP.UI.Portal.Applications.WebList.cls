/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Web Applications 
Class %CSP.UI.Portal.Applications.WebList Extends (%CSP.UI.Portal.Utils, %CSP.UI.Portal.Applications.Utils) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Applications.WebList.zen";

Parameter HELPADDRESS = "System Administration,Security,Applications,Web Applications";

Parameter EMSSERVICE = "Security";

/// Displayed name of this page.
Parameter PAGENAME = "Web Applications";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property ApplicationType As %Integer [ InitialExpression = {$$$AppTypeCSP+$$$AppTypeSystem} ];

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.Applications.Web.zen",,1)} ];

/// Store translated targetCol linkCaption for <condition>
Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

XData Style
{
<style type="text/css">
.tpAction {
	font-size: 1em;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<vgroup id="idTable">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
queryClass="Security.Applications"
queryName="List"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
OnCreateResultSet="%OnTableCreateResultSet"
>
<column colName="Name" header="Name" id="NameCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#');"
title="View or edit application security authorization"/>
<column colName="Namespace" header="Namespace" title="Namespace associated with this item."/>
<column colName="Namespace Default" header="Namespace Default" title="Is this the default application of the its namespace?"/>
<column colName="Enabled" header="Enabled" title="Indicates that this item is enabled."/>
<column colName="Dispatch Class" header="Dispatch Class" title="The dispatch class (if any) for this item."/>
<column colName="Resource" header="Resource" title="Resource used to control access for this item."/>
<column colName="Authentication Methods" header="Authentication Methods" title="Authentication methods used to control access to this service."/>
<column colName="IsSystemApp" hidden="true"/>
<column id="LinkDelete" link="javascript:zenPage.doDelete('#(%query.Name)#')" linkCaption="Delete" style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="*"/>
<parameter value="#(%page.ApplicationType)#"/>
<parameter value="#(%page.Filter)#"/>
 
 <!-- When Type is System, you cannot Delete -->
<condition colName="IsSystemApp" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colDelete)#" /> 
</tablePane>
</vgroup>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value, tableID) [ Language = javascript ]
{
	var table = zen(tableID);
	if (value=="*") value="";
	//Filter is 3rd parameter
	table.parameters[2].value = value;
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	this.updateTime();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

Method %OnTableCreateResultSet(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tSC = $$$OK
 	Set pInfo.parms(2) = $$$AppTypeCSP+$$$AppTypeSystem
	Set tRS = ""
	Quit tRS
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of Web applications that are currently defined:")

	Set ..%GetComponentById("LinkDelete").linkConfirm = ..msgConfirm
	i ..Filter="*" s ..Filter=""

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Web Application"),$$$Text("Create a new Web application definition"),"zenPage.doEdit('');")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Web Applications")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
/// Subclasses with extra layers of locator links or other than "Configuration" please override.
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

}
