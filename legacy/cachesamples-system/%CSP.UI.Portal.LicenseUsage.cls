/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - License Usage
Class %CSP.UI.Portal.LicenseUsage Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "License Usage";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.LicenseUsage.zen";

Parameter HELPADDRESS = "Home,License Usage";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

/// Whether license server is used 
Property LicenseServerUsed As %Boolean;

/// Filter value user entered into the "Filter" field in the table navigator. This value is saved and reloaded for this page.
Property ProcessFilter As %ZEN.Datatype.string;

Property UserFilter As %ZEN.Datatype.string;

Property PrevProcessFilter As %ZEN.Datatype.string [ InitialExpression = "PrevFilter" ];

Property PrevUserFilter As %ZEN.Datatype.string [ InitialExpression = "PrevFilter" ];

/// Page size value user entered into the "Page size" field in the table navigator. This value is saved and reloaded for this page.
Property TablePageSize As %Integer [ InitialExpression = "0" ];

/// Max rows value user entered into the "Max rows" field in the table navigator. This value is saved and reloaded for this page.
Property TableMaxRows As %Integer [ InitialExpression = "1000" ];

XData Style
{
<style type="text/css">
/* @doc="cusomize menu item." */
.menuTable {
	border: 0px solid white;
}
a.menuItem {
	color: #333695;
	font-size: 14px;
}
/* @doc="cusomize mouse over menu item." */
a.menuItem:hover {
	background: #ffffff;
}
/* additional style for option on the menu item */
.optionSelected {
	font-weight: bold;
	border-radius: 4px;
}
.optionUnselected {
	background: none;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<hgroup cellVAlign="top">
<menu id="menuClient" layout="vertical">
<menuItem id="option1" caption="- Summary" enclosingClass="optionSelected"
link="javascript:zenPage.doDetails('1');"
title="Display current license activity summary count." />
<menuItem id="option2" caption="- Usage by Process"
link="javascript:zenPage.doDetails('2');"
title="Display information of usage by process identifier." />
<menuItem id="option3" caption="- Usage by User"
link="javascript:zenPage.doDetails('3');"
title="Display information of usage by User Id." />
<menuItem id="option4" caption="- Distributed License Usage"
link="javascript:zenPage.doDetails('4');" 
title="Display information of distributed usage by User Id. This option is disabled when no license server is connected."
/>
</menu>
<form>
<label id="coreMsg" label="This Instance is using a Core Capacity license, user-based counts are not applicable." labelClass="rednote" hidden="true" containerStyle="padding:0px 4px 4px 6px;"/>
<label id="Text1" containerStyle="padding:0px 4px 4px 6px;"/>
<group id="page_1" width="100%">
<tableNavBar showFilter="false" tablePaneId="table1"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table1');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table1');"
/>
<tablePane id="table1" cellSpacing="2"
queryClass="%SYSTEM.License"
queryName="Summary"
dataSource="columns"
fixedHeaders="false"
maxRows="100"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
>
<column colName="LicenseUnitUse" header="License Unit Use"/>
<column colName="Local" header="Local"/>
<column colName="Distributed" header="Distributed"/>
 </tablePane>
 </group>
 
 <group id="page_2" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="true" showMaxRows="true" showPageSize="true" tablePaneId="table2"
saveSizeMax="true" onfilterChange="zenPage.filterChanged('table2',value);" onPageSizeChange="zenPage.navPageSizeChanged(value,'table2');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table2');"
/>
<tablePane id="table2" cellSpacing="2"
queryClass="%SYSTEM.License"
queryName="ProcessList"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="1000"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
OnCreateResultSet="CreateRS2"
OnExecuteResultSet="ExecuteRS2"
>
<column colName="PID" hidden="true"/>
<column colName="DisplayPID" header="Process ID"/>
<column colName="Process" header="Login ID"/>
<column colName="LID" header="User ID"/>
<column colName="Type" header="Type"/>
<column colName="Con" header="Connections"/>
<column colName="Active" header="Active Time"/>
<column colName="CSPCon" header="Web Sessions"/>
<column colName="LU" header="Units"/>
<column colName="Grace" header="Grace Time"/>
 </tablePane>
</group>

<group id="page_3" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="true" showMaxRows="true" showPageSize="true" tablePaneId="table3"
saveSizeMax="true" onfilterChange="zenPage.filterChanged('table3',value);" onPageSizeChange="zenPage.navPageSizeChanged(value,'table3');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table3');"
/>
<tablePane id="table3" cellSpacing="2"
queryClass="%SYSTEM.License"
queryName="UserList"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="1000"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
OnCreateResultSet="CreateRS3"
OnExecuteResultSet="ExecuteRS3"
>
<column colName="UserId" header="User ID"/>
<column colName="Type" header="Type"/>
<column colName="Connects" header="Connections"/>
<column colName="MaxCon" header="Max"/>
<column colName="CSPCon" header="Web Sessions"/>
<column colName="LU" header="Units"/>
<column colName="Active" header="Active Time"/>
<column colName="Grace" header="Grace Time"/>
 </tablePane>
</group>

<group id="page_4" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table4"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table4');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table4');"
/>
<tablePane id="table4" cellSpacing="2"
queryClass="%SYSTEM.License"
queryName="ConnectionList"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="1000"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
>
<column colName="UserId" header="User ID"/>
<column colName="LicenseUnits" header="License Units"/>
<column colName="Connections" header="Connections"/>
<column colName="ServerIP" header="Server IP"/>
<column colName="Instance" header="Instance"/>
 </tablePane>
</group>
 </form>
 </hgroup>
</pane>
}

ClientMethod doDetails(index) [ Language = javascript ]
{
	for ( var option=1; option<5; option++ ) {
		if ( option == index ) {
			var opclass = "optionSelected";
			var table = zen("table"+option);
			table.executeQuery();
			zen("page_"+option).setHidden(false);
			zen("Text1").setValue(this.getOptionTitle(option));
		} else {
			var opclass="optionUnselected";
			zen("page_"+option).setHidden(true);
		}
		zen("option"+option).setProperty("enclosingClass",opclass);						
	}
}

ClientMethod getOptionTitle(index) [ Language = javascript ]
{
	var title;
	switch (index) {
		case 1:
			title = $$$Text("Current license activity summary:");
			break;
		case 2:
			title = $$$Text("Information about license use by process:");
			break;
		case 3:
			title = $$$Text("Information about license use by user ID:");
			break;
		case 4:
			title = $$$Text("Information about distributed license use by user ID:");
			break;			
	}
	return title;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.doDetails(1);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set tPageName = ..%GetPageName()
	For n = 1:1:4 Do ..%GetNavTableState(tPageName_"^table"_n)
		
	Set ..LicenseServerUsed = $S($$GetLicenseServer^%SYS.LICENSE()="/":0,1:1)
	Set ..%GetComponentById("option4").disabled = '..LicenseServerUsed
	if $system.License.KeyLicenseType()="Core Capacity" {
		Set ..%GetComponentById("coreMsg").hidden = 0
		Set ..%GetComponentById("option1").hidden = 1
		Set ..%GetComponentById("option2").hidden = 1
		Set ..%GetComponentById("option3").hidden = 1
		Set ..%GetComponentById("option4").hidden = 1
	}
	
	$$$SetRefreshTimer

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"))
	Quit $$$OK
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("License Usage")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// On auto-refresh, or after Resume or Suspend, reload page with the current tab selected.
ClientMethod updateView() [ Language = javascript ]
{
	var option = 1;
	for ( var i=1 ; i<5 ; i++ ) {
		if ( zen("page_"+i).getProperty("hidden") == false ) {
			option = i;
			break;
		} 
	}	
	this.doDetails(option);
	this.updateTime();
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navPageSizeChanged(value, tableId) [ Language = javascript ]
{
	this.TablePageSize = value;
	if (tableId == 'table3') {
		this.UpdateTableNavState(this.UserFilter,value,this.TableMaxRows,tableId);
	} else {
		this.UpdateTableNavState(this.ProcessFilter,value,this.TableMaxRows,tableId);
	}
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navMaxRowsChanged(value, tableId) [ Language = javascript ]
{
	this.TableMaxRows = value;
	if (tableId == 'table3') {
		this.UpdateTableNavState(this.UserFilter,this.TablePageSize,value,tableId);
	} else {
		this.UpdateTableNavState(this.ProcessFilter,this.TablePageSize,value,tableId);
	}
}

/// Used to Save tableNavBar values, add MapType to the page name to distinguish the type for the page.
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer, ptableId As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName()_"^"_ptableId,"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(tableId, value) [ Language = javascript ]
{
	if (tableId == 'table3') {
		this.UserFilter = value;
	} else {
		this.ProcessFilter = value;
	}
	var table = zen(tableId);
	var currColumn = table.currColumn;
	var currSort = table.sortOrder;
	table.executeQuery(0);
	table.currColumn = currColumn;
	table.sortOrder = currSort;
	this.updateTime();
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows,tableId);
}

/// <var>pInfo</var> holds details on how to create the query.
Method CreateRS2(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pRS = ""
	Set Query = "$SYSTEM.License:ProcessList"
	Set pRS = ##class(%ResultSet).%New(Query)
	Quit pRS
}

/// Method for executing the process query.
Method ExecuteRS2(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
#;Only log if the filter changed on refresh
	i %page.ProcessFilter'=%page.PrevProcessFilter {
		Set EventDesc = $$$EventDescription
		Set EventData = "Filter: "_%page.ProcessFilter
		$$$SMPAuditView
		s %page.PrevProcessFilter=%page.ProcessFilter
	}
	Set tSC = pRS.Execute(%page.ProcessFilter) 
	Quit tSC
}

/// <var>pInfo</var> holds details on how to create the query.
Method CreateRS3(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pRS = ""
	Set Query = "$SYSTEM.License:UserList"
	Set pRS = ##class(%ResultSet).%New(Query)
	Quit pRS
}

/// Method for executing the process query.
Method ExecuteRS3(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
#;Only log if the filter changed on refresh
	i %page.UserFilter'=%page.PrevUserFilter {
		Set EventDesc = $$$EventDescription
		Set EventData = "Filter: "_%page.UserFilter
		$$$SMPAuditView
		s %page.PrevUserFilter=%page.UserFilter
	}
	Set tSC = pRS.Execute(0,%page.UserFilter) 
	Quit tSC
}

}
