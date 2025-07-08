/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// System Management Portal - System Operations - Processes 
Class %CSP.UI.Portal.Processes Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Processes.zen";

Parameter HELPADDRESS = "Home,Processes";

/// Displayed name of this page.
Parameter PAGENAME = "Operation Processes";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property DetailsPage As %String [ InitialExpression = {..Link("/csp/sys/op/%25CSP.UI.Portal.ProcessDetails.zen",,1)} ];

/// Column the table is sorted by. Default is the "Process ID" column. User may change and the value is saved and reloaded for this page.
Property CurrentColumn As %ZEN.Datatype.string [ InitialExpression = "DisplayPID" ];

/// Filter value user entered into the "Filter" field in the table navigator. This value is saved and reloaded for this page.
Property Filter As %ZEN.Datatype.string;

Property PrevFilter As %ZEN.Datatype.string [ InitialExpression = "PrevFilter" ];

/// Page size value user entered into the "Page size" field in the table navigator. This value is saved and reloaded for this page.
Property TablePageSize As %Integer [ InitialExpression = "0" ];

/// Max rows value user entered into the "Max rows" field in the table navigator. This value is saved and reloaded for this page.
Property TableMaxRows As %Integer [ InitialExpression = "1000" ];

/// Store translated targetCol linkCaption for <condition>
Property colDetails As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Details")} ];

XData Style
{
<style type="text/css">
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>

<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<tableNavBar id="tblNavBar" tablePaneId="table" showFilter="true" showPageSize="true" showMaxRows="true" saveSizeMax="true"
onfilterChange="zenPage.filterChanged(value);" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="To filter: enter one or more characters of any column followed by [Tab]."/>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="SYS.Process"
queryName="CONTROLPANEL"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="1000"
multiSelect="false"
pageSize="0"
showValueInTooltip="false"
showZebra="false"
valueColumn="Pid"
useSnapshot="true"
OnCreateResultSet="CreateRS"
OnExecuteResultSet="ExecuteRS"
>
<column colName="Job#" header="Job #" title="Job number used as an index."/>
<column colName="Pid" hidden="true"/>
<column colName="DisplayPID" header="Process ID" title="Process ID ($J) given to the process by the O/S."/>
<column colName="CPUTime" header="Total CPU Time in ms" title="Sum of system and user CPU time in ms for process"/>
<column colName="Username" header="User" title="User name."/>
<column colName="Device" header="Device" title="Name of device currently in use by this process."/>
<column colName="Nspace" header="Namespace" title="Current namespace used by this process."/>
<column colName="Routine" header="Routine" title="Routine associated with this process."/>
<column colName="Commands" header="Commands" title="Number of routine commands executed."/>
<column colName="Globals" header="Globals" title="Number of global references."/>
<column colName="State" header="State" title="Current state of this process."/>
<column colName="Client Name" header="Client Name" title="Name of client connected to this process."/>
<column colName="EXE Name" header="Client EXE" title="Name of client executable connected to this process."/>
<column colName="IP Address" header="Client IP" title="IP Address of the client connected to this process."/>
<column colName="OSUserName" header="O/S Username" title="O/S username of the process."/>
<column colName="Can Be Examined" hidden="true"/>
<column colName="Can Be Suspended" hidden="true"/>
<column colName="Can Be Terminated" hidden="true"/>
<column colName="Can Receive Broadcast" hidden="true" style="align:center;"/>
<column colName="PrvGblBlkCnt" hidden="true"/>

<column linkCaption="Details" link="%25CSP.UI.Portal.ProcessDetails.zen?PID=#(%query.Pid)#&amp;DISPLAYID=#(%query.DisplayPID)#&amp;$ID1=#(%query.Pid)#" 
style="text-align:center;" title="View details of the process"/>

<parameter value="1"/>
<parameter value=""/>

<condition colName="Can Be Examined" predicate="EQ" value="0" rowStyle="background: #f7f7f7;" cellStyle="disabled" targetCol="#(%page.colDetails)#"/> 
<condition colName="Device" predicate="EQ" value="******" rowStyle="background: #f7f7f7;" cellStyle="disabled" targetCol="#(%page.colDetails)#"/> 
<condition colName="State" predicate="EQ" value="CLOSH" rowStyle="background: #f7f7f7;" cellStyle="disabled" targetCol="#(%page.colDetails)#"/> 

 </tablePane>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	this.Filter = value;
	var table = zen("table");
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	table.executeQuery(0);
	this.updateTime();
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

/// Update / Reload table. This overrides the one in Portal.Utils.
ClientMethod updateView() [ Language = javascript ]
{
	this.filterChanged(this.Filter);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler');
	this.filterChanged(this.Filter);
	var navbar = zen("tblNavBar");
	navbar.setFilterSize(40);
}

ClientMethod navPageSizeChanged(value) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows);
}

ClientMethod navMaxRowsChanged(value) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value);
}

/// <var>pInfo</var> holds details on how to create the query.
Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pRS = ""
	Set pRS = ##class(%ResultSet).%New("SYS.Process:CONTROLPANEL")
	Quit pRS
}

/// Method for executing the process query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
#;Only log if the filter changed on refresh
	i %page.Filter'=%page.PrevFilter {
		Set EventDesc = $$$EventDescription
		Set EventData = "Filter: "_%page.Filter
		$$$SMPAuditView
		s %page.PrevFilter=%page.Filter
	}
	Set tSC = pRS.Execute(1,%page.Filter) 
	Quit tSC
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	;Set ..%GetComponentById("tblNavBar.filter").size = 20

	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of active processes:")
		
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
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","HTML"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnBroadcast",$$$Text("Broadcast"),$$$Text("Broadcast a message to selected devices."),"zenPage.doBroadcast();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Processes")
}

ClientMethod doBroadcast() [ Language = javascript ]
{
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.Broadcast.zen','Broadcast','status,scrollbars,resizable=yes,width=610,height=700');
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

}
