/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Namespaces
Class %CSP.UI.Portal.Namespaces Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Namespaces.zen";

Parameter HELPADDRESS = "Home,Configuration,Namespaces";

Parameter EMSSERVICE = "Namespace";

/// Displayed name of this page.
Parameter PAGENAME = "Namespaces";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

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
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<hgroup valign="top">
<vgroup valign="top">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
saveSizeMax="true"
onPageSizeChange="zenPage.navPageSizeChanged(value);"
onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
title="Enter a string to filter the list"
/>
<tablePane id="table"
queryClass="Config.Namespaces"
queryName="ListFilter"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
useSnapshot="true"
>
<column colName="Namespace" id="NamespaceCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.Namespace)#');"/>
<column colName="Globals"/>
<column colName="Routines"/>
<column colName="Temp Storage"/>
<column colName="System Globals" hidden="true"/>
<column colName="System Routines" hidden="true"/>
<column colName="Library" hidden="true"/>
<column linkCaption="Global Mappings" link="javascript:zenPage.doMap('Gbl','#(%query.Namespace)#');"
style="text-align:center;"/>
<column linkCaption="Routine Mappings" link="javascript:zenPage.doMap('Rtn','#(%query.Namespace)#');"
style="text-align:center;"/>
<column linkCaption="Package Mappings" link="javascript:zenPage.doMap('Prj','#(%query.Namespace)#');"
style="text-align:center;"/>
<!--<column linkCaption="Data Location" link="javascript:zenPage.doDataLocation('#(%query.Namespace)#');"
style="text-align:center;"/>-->
<column linkCaption="Delete" link="javascript:zenPage.doDelete('#(%query.Namespace)#');"
style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<parameter value=""/>
<parameter value="0"/>
<condition colName="Namespace" predicate="EQ" value="%ALL" cellStyle="disabled" targetCol="Namespace"/> 
<condition colName="Namespace" predicate="EQ" value="%SYS" cellStyle="disabled" targetCol="Namespace"/> 
<condition colName="Namespace" predicate="EQ" value="%SYS" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<condition colName="Namespace" predicate="EQ" value="IRISLIB" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
 </tablePane>
 <label id="idRespond" controlClass="greennote" value=""/>
 </vgroup>
</hgroup>
</pane>
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	try {
		if (popupName == 'NamespaceDelete') {
			var url = '%25CSP.UI.Portal.Namespaces.zen';
			zenPage.gotoPage(url);
		}
	} catch (ex) {
		alert("Error: " + ex);
	}

	return true;
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

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()

	Set ..%GetComponentById("Text1").value = $$$Text("Current Namespaces and their default databases for globals and routines")_":"
			
	If ..IsEMSReadOnly {
		Set column = ..%GetComponentById("NamespaceCol")
		Set column.link = ""
		Set column.onclick = ""
	}
	// The default filter in the page we inherit from is initially set to "*". This screws up the new filtering system.
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
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Namespace"),$$$Text("Create a new namespace"),"zenPage.doNew();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Namespaces")
}

ClientMethod doMap(mapType, ns) [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.Mappings.zen?MapType='+mapType+'&PID='+encodeURIComponent(ns);
	zenPage.gotoPage(url);
}

ClientMethod doDataLocation(ns) [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.MoveGlobalsCreate.zen?PID='+encodeURIComponent(ns);
	zenPage.gotoPage(url);
}

ClientMethod doDelete(ns) [ Language = javascript ]
{
	zen('idRespond').setValue('');
	var url = '%CSP.UI.Portal.Dialog.NamespaceDelete.zen?ID='+encodeURIComponent(ns);
	zenLaunchPopupWindow(url,'NamespaceDelete','status,scrollbars,resizable=yes,width=900,height=700');
}

ClientMethod doEdit(ns) [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.NamespaceEdit.zen?PID='+encodeURIComponent(ns);
	zenPage.gotoPage(url);
}

ClientMethod doNew() [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.Namespace.zen';
	zenPage.gotoPage(url);
}

}
