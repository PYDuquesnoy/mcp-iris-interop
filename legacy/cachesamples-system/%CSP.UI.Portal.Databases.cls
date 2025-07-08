/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Local Databases 
Class %CSP.UI.Portal.Databases Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Databases.zen";

Parameter HELPADDRESS = "Home,Configuration,Local Databases";

Parameter EMSSERVICE = "Namespace";

/// Displayed name of this page.
Parameter PAGENAME = "Managing Local Databases";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property MirrorName As %String;

/// Store translated targetCol linkCaption for <condition>
Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

Property colGlobals As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Globals")} ];

Property colVolumes As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Volumes")} ];

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
<tableNavBar id="tableNav" showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a string to filter the list"/>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="Config.Databases"
queryName="LocalDatabaseListFilter"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Directory"
useSnapshot="true"
>
<column colName="Name" header="Name" link="#" onclick="javascript:zenPage.doEdit('#(%query.Directory)#','#(%query.Name)#','#(%query.Mirror)#');"/>
<column colName="Mirror" id="colMirror" header="Mirror"/>
<column colName="Directory" header="Directory"/>
<column colName="Maximum Size in GB" hidden="true"/>
<column colName="Size in MB" header="Size (MB)"/>
<column colName="Status" header="Status"/>
<column colName="Resource" header="Resource"/>
<column colName="Encrypted" header="Encrypted"/>
<column colName="EncryptionKeyID" header="Encryption Key ID"/>
<column colName="Journal" header="Journal"/>
<column colName="StatusInt" hidden="true"/>
<column linkCaption="Delete" link="javascript:zenPage.doDelete('#(%query.Directory)#','#(%query.Name)#');"
style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<column linkCaption="Globals" link="UtilSysDbGlobals.csp?$ID1=#(%query.Directory)#&amp;$ID2=#(%query.Name)#"
style="text-align:center;" title="Show globals in this database"/>
<column linkCaption="Volumes" link="javascript:zenPage.doVolumes('#(%query.Directory)#');"
style="text-align:center;" title="Edit database volume information"/>
<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<condition colName="Name" predicate="EQ" value="IRISLIB" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<condition colName="Name" predicate="EQ" value="IRISSYS" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<condition colName="Name" predicate="EQ" value="IRISTEMP" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<condition colName="Name" predicate="EQ" value="IRISAUDIT" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<condition colName="Name" predicate="EQ" value="IRISLOCALDATA" cellStyle="disabled" targetCol="#(%page.colDelete)#"/>
<condition colName="Name" predicate="EQ" value="IRISMETRICS" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 

<!-- Disable Volume editing for system DBs -->
<condition colName="Name" predicate="EQ" value="IRISLIB" cellStyle="disabled" targetCol="#(%page.colVolumes)#"/> 
<condition colName="Name" predicate="EQ" value="IRISSYS" cellStyle="disabled" targetCol="#(%page.colVolumes)#"/> 
<condition colName="Name" predicate="EQ" value="IRISTEMP" cellStyle="disabled" targetCol="#(%page.colVolumes)#"/> 
<condition colName="Name" predicate="EQ" value="IRISAUDIT" cellStyle="disabled" targetCol="#(%page.colVolumes)#"/> 
<condition colName="Name" predicate="EQ" value="IRISLOCALDATA" cellStyle="disabled" targetCol="#(%page.colVolumes)#"/>
<condition colName="Name" predicate="EQ" value="IRISMETRICS" cellStyle="disabled" targetCol="#(%page.colVolumes)#"/>

<!-- While status is Dismounted, give it a different row background color and cannot Edit or View Globals -->
<condition colName="StatusInt" predicate="EQ" value="Dismounted" rowStyle="background: #FFB6C1;" cellStyle="disabled" targetCol="Name"/> 
<condition colName="StatusInt" predicate="EQ" value="Dismounted" cellStyle="disabled" targetCol="#(%page.colGlobals)#"/> 
<condition colName="StatusInt" predicate="EQ" value="Unmounted" rowStyle="background: #FFB6C1;" cellStyle="disabled" targetCol="Name"/> 
<condition colName="StatusInt" predicate="EQ" value="Unmounted" cellStyle="disabled" targetCol="#(%page.colGlobals)#"/> 

<!-- While status is Unavailable, you cannot Edit or View Globals -->
<condition colName="StatusInt" predicate="EQ" value="Unavailable" cellStyle="disabled" targetCol="Name"/> 
<condition colName="StatusInt" predicate="EQ" value="Unavailable" cellStyle="disabled" targetCol="#(%page.colGlobals)#"/> 

<!-- While status is Expanding, you cannot Edit or Delete -->
<condition colName="StatusInt" predicate="EQ" value="Expanding" cellStyle="disabled" targetCol="Name"/> 
<condition colName="StatusInt" predicate="EQ" value="Expanding" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 

<!-- For Mirror database, you cannot Delete -->
<condition colName="Mirror" predicate="NEQ" value="NULL" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 

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

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of the local databases:")
	
	If ($System.Mirror.IsMember() = 0) {
		Set ..%GetComponentById("colMirror").hidden = 1
	} Else {
		Set ..MirrorName = ##class(Config.Mirrors).GetMirrorName()
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
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Database"),$$$Text("Create a new local database"),"zenPage.doNew();")

	If ($System.Mirror.IsPrimary() = 1) {
		Set pCommands(2) = $LB("btnMirrorAdd",$$$Text("Add to Mirror"),$$$FormatText($$$Text("Add one or more local databases to mirror %1"),..EscapeHTML(..MirrorName)),"zenPage.doMirrorAdd();")
	}

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Local Databases")
}

ClientMethod doDelete(dir, dbname) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	var url = zenLink('%CSP.UI.Portal.Dialog.DatabaseDelete.zen')+'?Dir='+encodeURIComponent(dir)+'&DBName='+encodeURIComponent(dbname)+'&Remote=0';
	zenLaunchPopupWindow(url,'DatabaseDelete','status,scrollbars,resizable=yes,width=900,height=700');
}

ClientMethod doEdit(dir, dbname, mirror) [ Language = javascript ]
{
	if (mirror == "") {
		var url = '%25CSP.UI.Portal.Database.zen?Dir='+encodeURIComponent(dir)+'&DBName='+encodeURIComponent(dbname);
	} else {
		var url = '%25CSP.UI.Portal.DatabaseMirror.zen?Dir='+encodeURIComponent(dir)+'&DBName='+encodeURIComponent(dbname)+'&MirrorSetName='+encodeURIComponent(mirror);
	}
	this.gotoPage(url);
}

ClientMethod doNew() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	var url = zenLink('%CSP.UI.Portal.Dialog.DatabaseWizard.zen');
	zenLaunchPopupWindow(url,'DatabaseWizard','status,scrollbars,resizable=yes,width=900,height=700');
}

ClientMethod doMirrorAdd() [ Language = javascript ]
{
	var url = "%CSP.UI.Portal.Dialog.DBMirrorAdd.zen?MirDBName="+encodeURIComponent(zenPage.MirrorName)+"&Multi=1";
	zenLaunchPopupWindow(url,'AddMirror','resizable,width=600,height=700');
}

ClientMethod doVolumes(dir) [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.DatabaseVolumes.zen?Dir='+encodeURIComponent(dir);
	this.gotoPage(url);
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
