/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - Local Databases 
Class %CSP.UI.Portal.OpDatabases Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.OpDatabases.zen";

Parameter HELPADDRESS = "Home,Databases";

/// Displayed name of this page.
Parameter PAGENAME = "Operation Local Databases";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property msgDismount As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to dismount database %1?")} ];

/// Store translated targetCol linkCaption for <condition>
Property colDismount As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Dismount")} ];

Property colMount As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Mount")} ];

Property FreespacesOn As %String(ZENURL = "FreespacesOn");

XData Style
{
<style type="text/css">
.onoffswitch {
    position: relative; width: 67px;
    -webkit-user-select:none; -moz-user-select:none; -ms-user-select: none;
}
.onoffswitch-checkbox {
    display: none;
}
.onoffswitch-label {
    display: block; overflow: hidden; cursor: pointer;
    border: 2px solid #999999; border-radius: 20px;
}
.onoffswitch-inner {
    display: block; width: 200%; margin-left: -100%;
    transition: margin 0.3s ease-in 0s;
}
.onoffswitch-inner:before, .onoffswitch-inner:after {
    display: block; float: left; width: 50%; height: 16px; padding: 0; line-height: 16px;
    font-size: 14px; color: white; font-weight: bold;
    box-sizing: border-box;
}
.onoffswitch-inner:before {
    content: "ON";
    padding-left: 10px;
    background-color: #34A7C1; color: #FFFFFF;
}
.onoffswitch-inner:after {
    content: "OFF";
    padding-right: 10px;
    background-color: #EEEEEE; color: #999999;
    text-align: right;
}
.onoffswitch-switch {
    display: block; width: 18px; margin: -1px;
    background: #FFFFFF;
    position: absolute; top: 0; bottom: 0;
    right: 47px;
    border: 2px solid #999999; border-radius: 20px;
    transition: all 0.3s ease-in 0s; 
}
.onoffswitch-checkbox:checked + .onoffswitch-label .onoffswitch-inner {
    margin-left: 0;
}
.onoffswitch-checkbox:checked + .onoffswitch-label .onoffswitch-switch {
    right: 0px; 
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<hgroup>
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"  
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter the leading characters of a database name followed by [Tab] to filter the list. For example: C for all database names starting with letter 'C'." 
/>
<radioSet id="freespaceSwitch" valueList="0,1" displayList="General view,Free space view" originalValue="0" value="0" onchange="zenPage.doFreespaceSwitch();"/>
</hgroup>
<tablePane id="table" cellSpacing="2"
onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
initialExecute="false"
queryClass="Config.Databases"
queryName="LocalDatabaseList"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Directory"
useSnapshot="true"
onselectrow="zenPage.doSelectRow(1);"
>
<column colName="Name" header="Name" link="%25CSP.UI.Portal.DatabaseDetails.zen?$ID1=#(%query.Directory)#&amp;DBName=#(%query.Name)#"
 title="View and manage database"/>
<column colName="Mirror" header="Mirror" hidden="true"/>
<column colName="Directory" header="Directory"/>
<column colName="Maximum Size in GB" header="Max Size (GB)"/>
<column colName="Size in MB" header="Size (MB)"/>
<column colName="Status" header="Status"/>
<column colName="Encrypted" header="Encrypted"/>
<column colName="Journal" header="Journal"/>
<column colName="Resource" hidden="true"/>
<column colName="StatusInt" hidden="true"/>

<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<condition colName="StatusInt" predicate="EQ" value="Unmounted" rowStyle="background: #FFB6C1;" cellStyle="disabled" />

 </tablePane>
 
 <tablePane id="tableFree" cellSpacing="2" hidden="true"
 onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
 initialExecute="false"
queryClass="SYS.Database"
queryName="FreeSpace"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
showValueInTooltip="true"
showZebra="true"
valueColumn="Directory"
useSnapshot="true"
onselectrow="zenPage.doSelectRow(2);"
>
<column colName="DatabaseName" header="Name" link="%25CSP.UI.Portal.DatabaseDetails.zen?$ID1=#(%query.Directory)#&amp;DBName=#(%query.DatabaseName)#"
 title="View and manage database"/>
<column colName="Directory" header="Directory"/>
<column colName="MaxSize" header="Max Size"/>
<column colName="Size" hidden="true"/>
<column colName="SizeInt" header="Size" OnDrawCell="DrawDB"/>
<column colName="ExpansionSize" header="Expansion Size"/>
<column colName="Available" hidden="true"/>
<column colName="AvailableNum" header="Available" OnDrawCell="DrawDB"/>
<column colName="Free" header="% Free"/>
<column colName="DiskFreeSpace" hidden="true"/>
<column colName="DiskFreeSpaceNum" header="Disk Free Space" OnDrawCell="DrawDB"/>
<column colName="Status" header="Status"/>
<column colName="ReadOnly" hidden="true"/>
<parameter value="#(%page.Filter)#"/>
<parameter value="0"/>
 </tablePane>
</pane>
}

/// allow to open details page when clicking on a row anywhere.
ClientMethod doSelectRow(option) [ Language = javascript ]
{
	var tableName = (option == 1) ? 'table' : 'tableFree';
	var table = zen(tableName);
	var selectedIndex = table.getProperty("selectedIndex");
	if (selectedIndex == -1) {
		return;
	}
	var itemId = table.getValue();
	var rowData = table.getRowData(selectedIndex);
	if (!rowData) {
		return;
	}
	var name = rowData["Name"];
	var directory = rowData["Directory"];
	if (name != '' && directory != '') {
		window.document.location = "%25CSP.UI.Portal.DatabaseDetails.zen?$ID1=" + encodeURIComponent(directory) + '&DBName=' + encodeURIComponent(name);
	}
}

/// Method to execute the query and show/hide the table according to user selected view type: General and Free space.<br>
/// This method is invoked when the page is first loaded, and when user click to change view.
ClientMethod doFreespaceSwitch() [ Language = javascript ]
{
	var freespaceSwitch = zen("freespaceSwitch").getValue();		
	this.FreespacesOn = freespaceSwitch;
	var table = zen('table');
	var tableFree = zen('tableFree');
	if (parseInt(freespaceSwitch) == 1) {
		table.setHidden(true);
		tableFree.executeQuery(0);
		tableFree.refreshContents();
		tableFree.setHidden(false);
	} else {
		tableFree.setHidden(true);
		table.executeQuery(0);
		table.refreshContents();
		table.setHidden(false);		
	}
	this.SaveFreespaceOn(freespaceSwitch);
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	if (parseInt(this.FreespacesOn) == 1) {
		table = zen("tableFree");
	}
	if (value.indexOf("*") == -1) {
		value += "*";
	}
	table.parameters[0].value = value;
	table.executeQuery();
	this.updateTime();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

/// Update / Reload table. This overrides the one in Portal.Utils.
ClientMethod updateView() [ Language = javascript ]
{
	this.filterChanged(this.Filter);
}

Method %OnAfterCreatePage() As %Status
{
    #; Must do this before ##super() because it will check this global and apply the values
    Kill $$$IRISTempMgt($Username,..%GetPageName(),"TableState")
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	#; If FreespacesOn flag is not passed in from URL (e.g. EnsembleMgr), then see if user has previously selected it and honor that preference
	If (%page.FreespacesOn = 0 || (%page.FreespacesOn = "")) {
		Set %page.FreespacesOn = $G($$$IRISTempMgt($Username,..%GetPageName(),"FreespaceOn"),0)
	}
	Set ..%GetComponentById("Text1").value = $$$Text("To view details and to manage a local database, click the database name link from the table below:")
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
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnIntergrity",$$$Text("Integrity Check"),$$$Text("Perform background integrity check on selected databases"),"zenPage.doIntegrity();")
	Set pCommands(2) = $LB("btnLog",$$$Text("Integrity Log"),$$$Text("View integrity check result logs"),"zenPage.doLog();")
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Databases")
}

/// User override of cell-display for tablePane.
Method DrawDB(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell in proper DB size.
	Set dbSizeLogicalToDisplay = ##class(SYS.Database).FormatSizes(%query(pName))
	&html<&nbsp;#(dbSizeLogicalToDisplay)#>
	Quit $$$OK
}

ClientMethod doIntegrity() [ Language = javascript ]
{
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.Integ.zen?FILETYPE=Integ','IntegCheck','status,scrollbars,resizable=yes,width=900,height=700');
}

ClientMethod doLog() [ Language = javascript ]
{
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.IntegLog.zen','IntegLog','status,scrollbars,resizable=yes,width=900,height=700');
}

/// This is called in the middle of rendering the tool ribbon.
/// Subclasses can inject their own content into the ribbon by writing it out in this method.
/// This content should be wrapped within a td element.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// You may turn freespaces switch on (e.g. from EnsembleMonitor) on page opening
/// Otherwise it is off as default.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (parseInt(this.FreespacesOn) == 1) {
		zen('freespaceSwitch').setValue(1);
	}
	this.doFreespaceSwitch();
}

/// Save user's freespace selection value
ClassMethod SaveFreespaceOn(pValue As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName(),"FreespaceOn") = +$G(pValue)
}

/// User clicked a column header to sort. Save that so we can come back to it when page is refreshed.
/// Overridden from <CLASS>%CSP.UI.Portal.Utils</CLASS> to remove the call to UpdateTableState.
ClientMethod columnSort(currColumn, sortOrder) [ Language = javascript ]
{
	this.CurrentColumn = currColumn;
	this.CurrentSort = sortOrder;
	this.updateView();
}

}
