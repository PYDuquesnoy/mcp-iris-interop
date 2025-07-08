/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - View Locks
Class %CSP.UI.Portal.LocksView Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.LocksView.zen";

Parameter HELPADDRESS = "Home,Locks";

/// Displayed name of this page.
Parameter PAGENAME = "View Locks";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property ShowSQL As %Boolean [ InitialExpression = 0 ];

Property Namespace As %String;

XData Style
{
<style type="text/css">
/* additonal style for table pane */
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
<group cellStyle="font-size: 12px" enclosingClass="EditForm" enclosingStyle="padding: 3px;" >
<label label="Show:" enclosingStyle="margin-right: 10px;" />
<checkbox caption="Owner's routine information" onchange="zenPage.displayroutine(zenThis.getValue())" enclosingStyle="margin-right: 10px;" />
<checkbox caption="SQL table name" onchange="zenPage.displaySqlOptions(zenThis.getValue())"/>
<group id="sqlOptions" layout="horizontal" cellStyle="padding:4px;" labelPosition="left" enclosingStyle="margin-left: 5px;" hidden="true">
<select id="namespaceFilter"
label="Show SQL table names for namespace: "
queryClass="%SYS.Namespace"
queryName="List"
choiceColumn="1"
showEmpty="true"
maxRows="1000"
onchange="zenPage.setNamespaceFilter(zenThis.getValue());">
<parameter value="0"/>
<parameter value="0"/>
</select>
</group>
</group>
<spacer height="10" />
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>

<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter an string to filter the list"
/>
<tablePane id="table" 
queryClass="%SYS.LockQuery"
queryName="WebListFilter"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="DeleteID"
useSnapshot="true"
>
<column colName="Removable" hidden="true"/>
<column colName="DeleteID" hidden="true"/>
<column colName="CanBeExamined" hidden="true"/>
<column colName="RemoteOwner" hidden="true"/>
<column colName="PidInternal" hidden="true"/>

<column colName="Pid" header="Owner" link="%25CSP.UI.Portal.ProcessDetails.zen?PID=#(%query.PidInternal)#&amp;DISPLAYID=#(%query.Pid)#&amp;$ID1=#(%query.PidInternal)#"/>
<column colName="OSUserName" header="OS user name"/>
<column colName="ModeCount" header="Mode count"/>
<column colName="Reference" header="Reference"/>
<column header="SQL table name" OnDrawCell="DrawSQLColumn" seed="tablename" style="font-size:1em;" id="colSQL" hidden="true"/>
<column colName="Directory" header="Directory"/>
<column colName="System" header="System"/>
<column colName="RoutineInfo" header="Routine" id="colRoutine" hidden="true"/>

<condition colName="CanBeExamined" predicate="EQ" value="0" targetCol="Pid" cellStyle="disabled"/>

<parameter value="#(%page.Filter)#"/>
<parameter value="1"/>

 </tablePane>
</pane>
}

Method DrawSQLColumn(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	if (..ShowSQL) {
		set nspace = ..Namespace
		if nspace="" {
			set proc = ##class(%SYS.ProcessQuery).%OpenId(+%query("Pid"),,.procObjStatus)
			if $$$ISOK(procObjStatus)&&$IsObject(proc) set nspace=proc.NameSpace
		}
		set content=""
		if (nspace'="")&&(seed="tablename") {
			set content = ##class(%ExtentMgr.Util).GlobalToSqlTable(nspace, %query("Reference"))
			set %query("SqlTable") = content
		}
		&html<#($zconvert(content,"O","HTML"))#>
	}
	return $$$OK
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
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
	
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of the current Locks:")
		
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
	
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String [ CodeMode = expression ]
{
$$$Text(..#PAGENAME)
}

/// Update table.
ClientMethod updateView() [ Language = javascript ]
{
	window.location.reload();
}

ClientMethod hideThisColumn(col, hide) [ Language = javascript ]
{
	zen('table').columns.find(c => c.id==col).hidden=hide;
}

/// Toggle for displaying routine information.
ClientMethod displayroutine(value) [ Language = javascript ]
{
	var table = zen("table");
	table.parameters[1].value = !value;
	zenPage.hideThisColumn("colRoutine", value ? 0 : 1)
	table.executeQuery();
}

ClientMethod displaySqlOptions(value) [ Language = javascript ]
{
	zen("sqlOptions").setHidden(!value);
	zenPage.hideThisColumn("colSQL", value ? 0 : 1)
	zenPage.ShowSQL = value ? 1 : 0;
	zen("table").executeQuery();
}

ClientMethod setNamespaceFilter(value) [ Language = javascript ]
{
	zenPage.Namespace = value;
	zen("table").executeQuery();
}

}
