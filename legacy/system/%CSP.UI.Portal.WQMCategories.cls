/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Show WQM Categories
Class %CSP.UI.Portal.WQMCategories Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Work Queue Manager Categories";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.WQMCategories.zen";

Parameter HELPADDRESS = "System Administration,Configuration,System Configuration,WQM Categories";

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
	border: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>

<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>

<vgroup valign="top">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
saveSizeMax="true" 
onPageSizeChange="zenPage.navPageSizeChanged(value);"
onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
title="Enter a string to filter the list"
/>
<tablePane id="table"
queryClass="Config.WorkQueues"
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
<column colName="CategoryName" id="NameCol" OnDrawCell="DrawName"/>
<column colName="MaxActiveWorkers" />
<column colName="DefaultWorkers" />
<column colName="MaxWorkers" />
<column linkCaption="Delete" OnDrawCell="DrawDelete"/>

<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<parameter value=""/>
<parameter value="0"/>
 </tablePane>
 </vgroup>
 <label id="idRespond" controlClass="greennote" value=""/>
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
	///this.updateTime();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

Method %OnAfterCreatePage() As %Status
{
	#dim tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of work queue manager categories:")
	// The default filter in the page we inherit from is initially set to "*". This screws up the new filtering system.
	Set:..Filter="*" ..Filter=""
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Work Queue Manager Categories")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Set pCommands(1) = $LB("btnAdd",$$$Text("Create Category"),$$$Text("Create a work queue manager category"),"zenPage.doNew();")

	Quit $$$OK
}

Method DrawName(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If $G(%query("CategoryName")) '= "" {
		set txtName = ..EscapeHTML(%query("CategoryName"))
		&html<<a style="white-space:nowrap;" href="#" onclick="javascript:zenPage.doEdit('#(txtName)#');">#(txtName)#</a>>
	}
	Quit $$$OK
}

ClassMethod DrawCategory(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write ..EscapeHTML(%query("Category"))
	Quit $$$OK
}

Method DrawDelete(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If ($G(%query("CategoryName")) '= ""),'##Class(Config.WorkQueues).IsSystemWorkQueue(%query("CategoryName")) {
		Set txtDelete = ..EscapeHTML("Delete")
		Set txtMsg = $$$FormatText($$$TextJS("Are you sure you want to delete Server '%1'?"), %query("CategoryName"))
		&html<<a style="white-space:nowrap;" href="#" title='#(txtDelete)#' onclick="zen('table').launchConfirmDialog('%ZEN.Dialog.confirmationDialog.cls','confirmationDialog','resizable,width=540,height=200',{Msg1:'#(txtMsg)#',Title:'#(txtDelete)#',Link:'zenPage.doDelete(\&#39;#(%query("CategoryName"))#\&#39;);'}); return false;">#(txtDelete)#</a></td>>
	}
	Quit $$$OK
}

ClassMethod DrawWorkers(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query("IsDynamic") {
		Write $$$TextHTML("Dynamic")_ " ("_..EscapeHTML(%query("Workers"))_")"
	} Else {
		Write ..EscapeHTML(%query("Workers"))
	}
	Quit $$$OK
}

/// User clicked Start link. Goto to Start page.
ClientMethod doNew() [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.WQMCategory.zen';
	zenPage.gotoPage(url);
}

/// User clicked the "Edit" link.
ClientMethod doEdit(Name, editable) [ Language = javascript ]
{
	var url='%25CSP.UI.Portal.WQMCategory.zen?PID='+encodeURIComponent(Name)+"&IsEditForm=1";
	zenPage.gotoPage(url);
}

/// Delete existing gateway connection.
ClientMethod doDelete(Name) [ Language = javascript ]
{
	try {
		var ok = this.DeleteItem(Name);
		if (ok == 1) {
			var table = zenPage.getComponentById('table');
			table.setProperty("selectedIndex",-1);
			table.executeQuery();
		} else {
			alert(ok);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Call server delete method.
ClassMethod DeleteItem(Name) As %String [ ZenMethod ]
{
	Set $ZT="Error"
	Set tSC = ##class(Config.WorkQueues).Delete(Name)
	If $$$ISERR(tSC) {
		Set ok = $System.Status.GetErrorText(tSC)
	} Else {
		Set ok = 1
	}
	Quit ok
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","JS")
}

}
