/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - Roles
Class %CSP.UI.Portal.Roles Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Roles.zen";

Parameter HELPADDRESS = "System Administration,Security,Roles";

Parameter EMSSERVICE = "Security";

/// Displayed name of this page.
Parameter PAGENAME = "Roles";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// Store translated targetCol linkCaption for <condition>
Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

XData Style
{
<style type="text/css">
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<group>
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a string to filter the list"
/>
<tablePane id="table"
queryClass="%SQL.Manager.CatalogPriv"
queryName="RolesFilter"
dataSource="columns"
fixedHeaders="false"
maxRows="1000"
pageSize="0"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="ROLE_NAME"
useSnapshot="true"
>
<column colName="ROLE_NAME" header="Name" id="NameCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.ROLE_NAME)#');"/>
<column colName="DESCRIPTION" header="Description"/>
<column colName="CREATED_BY" header="Created By"/>
<column id="Delete" link="javascript:zenPage.doDelete('#(%query.ROLE_NAME)#');" linkCaption="Delete" style="text-align:center;" linkConfirm="Are you sure you want to delete role '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
<condition colName="ROLE_NAME" predicate="EQ" value="%All" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<parameter value="#(%page.Filter)#"/>
 </tablePane>
 </group>
</pane>
}

ClientMethod filterChanged(value, tableID) [ Language = javascript ]
{
	var table = zen(tableID);
	if (value=="*") value="";
	table.parameters[0].value = value;
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	this.updateTime();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of role definitions:")
	// The default filter in the page we inherit from is initially set to "*". This screws up the new filtering system.
	i ..Filter="*" s ..Filter=""
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

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Role"),$$$Text("Create a new role definition"),"zenPage.doEdit('');")
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Roles")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Delete selected role
ClientMethod doDelete(role) [ Language = javascript ]
{
	var ok = this.Delete(role);
	if (ok != "") alert(ok);
	var table = zen("table");
	table.executeQuery(0);
}

ClientMethod doEdit(role) [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.Role.zen?PID='+encodeURIComponent(role);
	this.gotoPage(url);
}

/// Delete selected role now.
ClassMethod Delete(role As %String) As %String [ ZenMethod ]
{
	Set (tResult,tMsg) = ""
	Set tSC = ##class(%SQL.Manager.API).DropUser(role,"ROLE",.SQLCODE,.tMsg)
	If SQLCODE<0 {
		If tMsg '= "" {
			Set tResult = $ZCVT(tMsg,"O","JS")
		} Else {
			Set tResult = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
		}
	}
	Quit tResult
}

}
