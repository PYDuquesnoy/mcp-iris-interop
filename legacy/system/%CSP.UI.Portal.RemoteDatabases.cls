/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.RemoteDatabases Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Remote Databases";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter EMSSERVICE = "Namespace";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.RemoteDatabases.zen";

Parameter HELPADDRESS = "Home,Configuration,Remote Databases";

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
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<hgroup valign="top">
<vgroup id="top">
<tableNavBar id="tableNav" showFilter="true" showMaxRows="true" showPageSize="true" tablePaneId="table"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a string to filter the list"
/>
<tablePane id="table"
queryClass="Config.Databases"
queryName="ListFilter"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
ondblclick="zenPage.editItem('')"
>
<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<parameter value="2"/>
<parameter value=""/>
<column colName="Name" header="Name"/>
<column colName="Directory" header="Directory" />
<column colName="Server" />
<column colName="Status" />
<column colName="ClusterMountMode" hidden="true"/>
<column colName="MountRequired" hidden="true"/>
<column colName="MountAtStartup" hidden="true"/>
<column colName="StreamLocation" hidden="true"/>
<column colName="Comments" hidden="true"/>

<column linkCaption="Edit" id="LinkEdit" link="javascript:zenPage.doEdit('#(%query.Name)#');"/>
<column linkCaption="Delete" id="LinkDelete" link="javascript:zenPage.doDelete('#(%query.Directory)#','#(%query.Name)#');" hidden="#(%page.IsEMSReadOnly)#"/>
 </tablePane>
 </vgroup>
</hgroup>
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

/// Subclass can override.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of the remote databases:")
	i ..Filter="*" s ..Filter=""
	Quit $$$OK
}

Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set caption = $$$Text("Create Remote Database")
	Set pCommands(1) = $LB("btnNew",caption,caption,"zenPage.doEdit('');")

	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$TextHTML("Remote Databases")
}

ClientMethod doDelete(dir, dbname) [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Dialog.DatabaseDelete.zen')+'?Dir='+encodeURIComponent(dir)+'&DBName='+encodeURIComponent(dbname)+'&Remote=1';
	zenLaunchPopupWindow(url,'DatabaseDelete','status,scrollbars,resizable=yes,width=900,height=700');
}

ClientMethod doEdit(dbName) [ Language = javascript ]
{
	var url = "%CSP.UI.Portal.Dialog.RemoteDatabase.zen?PID=" + encodeURIComponent(dbName);
	url = zenLink(url);
	zenLaunchPopupWindow(url,'RemoteDatabase','status,scrollbars,resizable=yes,width=900,height=700');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	try {
		document.location.reload();	
	} catch (ex) {
		alert("Error: " + ex);
	}

	return true;
}

}
