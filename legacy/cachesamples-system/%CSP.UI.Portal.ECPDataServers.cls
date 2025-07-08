/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Configuration - ECP - Data Servers 
Class %CSP.UI.Portal.ECPDataServers Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ECPDataServers.zen";

Parameter HELPADDRESS = "Home,Configuration,ECP Settings,ECP Data Servers";

Parameter EMSSERVICE = "Namespace";

/// Displayed name of this page.
Parameter PAGENAME = "ECP Data Servers";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ECP.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

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
	border-top: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a string to filter the list"
/>
<tablePane
id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="Config.ECPServers"
queryName="StatusListSMPFilter"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
useSnapshot="true"
valueColumn="Name"
>
<column colName="Name" header="Server Name"/>
<column colName="RemoteAddress" header="Host Name"/>
<column colName="RemotePort" header="IP Port"/>
<column colName="Status" header="Status"/>
<column colName="MirrorConnection" header="Mirror Connection"/>
<column colName="SSLConfig" header="SSL/TLS"/>
<column colName="BatchMode" header="Batch Mode"/>
<column link="javascript:zenPage.doEdit(2,'#(%query.Name)#')" linkCaption="Edit" hidden="#(%page.IsEMSReadOnly)#"/>
<column link="javascript:zenPage.doEdit(3,'#(%query.Name)#')" linkCaption="Change Status"/>
<column link="javascript:zenPage.doDelete('#(%query.Name)#')" linkCaption="Delete" linkConfirm="Are you sure you want to delete server '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="#(%page.Filter)#"/>
</tablePane>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
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

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen('table').executeQuery();
	}
}

ClientMethod doEdit(action, serverName) [ Language = javascript ]
{
	var url = '%CSP.UI.Portal.Dialog.ECPDataServer.zen?';
	if (action == 1) {
		url += 'action=new';
	} else if (action == 2) {
		url += 'action=edit&ID=' + encodeURIComponent(serverName);
	} else {
		url += 'action=changeStatus&ID=' + encodeURIComponent(serverName);
	}
	zenLaunchPopupWindow(url,'ServerEdit','status,scrollbars,resizable=yes,width=600,height=600');
}

ClientMethod doDelete(serverName) [ Language = javascript ]
{
	var st = zenPage.DeleteServer(serverName);
	if (st != 1) {
		alert(st);
	} else {
		zen('table').executeQuery();
	}
}

ClassMethod DeleteServer(serverName As %String) As %String [ ZenMethod ]
{
	Set tSC = ##Class(Config.ECPServers).Delete(serverName)
	Quit ..EvalResult(tSC)
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of ECP data servers that this system can connect to:")
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
	
	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = $$$Text("ECP Settings","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick,hidden)
	Set pCommands(1) = $LB("btnNew",$$$Text("Add Server"),$$$Text("Add a new remote data server."),"zenPage.doEdit(1);")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("ECP Data Servers")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

}
