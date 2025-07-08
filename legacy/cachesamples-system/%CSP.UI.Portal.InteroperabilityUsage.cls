/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Interoperability Usage
Class %CSP.UI.Portal.InteroperabilityUsage Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Interoperability Usage";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.InteroperabilityUsage.zen";

Parameter HELPADDRESS = "Home,Interoperability Usage";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property StartDate As %TimeStamp;

Property EndDate As %TimeStamp;

Property EndDateEndOfDay As %TimeStamp [ Calculated, SqlComputeCode = {set {*}=%page.EndDate_" 23:59:59.999"}, SqlComputed ];

Property Today As %TimeStamp [ Calculated, SqlComputeCode = { set {*}=$ZDATE($ztimestamp,3)}, SqlComputed ];

Property FilterValue As %String;

Property Option As %Integer [ InitialExpression = 1 ];

Property View As %Integer [ InitialExpression = 1 ];

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

.errNote {
	background: #F2F1EC;
	border: 1px solid #da4848;
	border-radius: 5px;
	color: #da4848;
	font-family: Arial, Helvetica, sans-serif;
	font-size: 12px;
	line-height:22px;
	font-weight: bold;
	padding: 10px;
	text-align: left;
	display:inline-block;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:0px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<vgroup valign="top">
<group id="errGrp" hidden="true">
<label id="errMsg" enclosingClass="errNote" value="" hidden="true" containerStyle="padding:10px;" controlStyle="white-space:pre-line;"/>
</group>
<hgroup id="viewMenuGrp">
<label id="viewMenuLbl" label="View:" labelClass="optionLabel" containerStyle="padding:20px 20px 20px 100px;"/>
<menu id="viewMenu" layout="horizontal">
<menuItem id="view1" caption="Interface" enclosingClass="optionSelected" containerStyle="padding:20px 20px 20px 20px;"
onclick="zenPage.setView('1');" title="Display Interoperability activity by interface." />
<menuItem id="view2" caption="Message Volume" containerStyle="padding:20px 20px 20px 20px;"
onclick="zenPage.setView('2');" title="Display Interoperability activity by message volume." />
<menuItem id="view3" caption="Database Impact" containerStyle="padding:20px 20px 20px 20px;"
onclick="zenPage.setView('3');" title="Display estimated data created by message activity."/>
</menu>
</hgroup>
<hgroup cellVAlign="top">
<menu id="menuClient" layout="vertical" containerStyle="padding:50px 20px 20px 10px;">
<menuItem id="option1" caption="- Summary" enclosingClass="optionSelected" onclick="zenPage.setOption('1');"
title="Display Interoperability activity summary count." />
<menuItem id="option2" caption="- Per Namespace" onclick="zenPage.setOption('2');"
title="Display Interoperability activity by namespace." />
</menu>
<form>
<label id="Text1" containerStyle="padding:0px 4px 20px 6px;"/>
<hgroup id="dateFilter">
<label id="startDateLbl" label="Start Date (mm-dd-yyyy):"  containerStyle="padding:0px 4px 15px 10px;"/>
<dateText id="startDate" format="MDY" title="Start date in UTC" labelClass="optionLabel" hint="" hintClass="helpText" onchange="zenPage.updateDates();" maxDate="#(%page.Today)#" containerStyle="padding:0px 4px 15px 0px;"/>
<label id="endDateLbl" label="End Date (mm-dd-yyyy):"  containerStyle="padding:0px 4px 15px 20px;"/>
<dateText id="endDate" format="MDY" title="End date in UTC" hint="" hintClass="helpText" onchange="zenPage.updateDates();" maxDate="#(%page.Today)#" containerStyle="padding:0px 4px 15px 0px;"/>
</hgroup>
<group id="page_1" width="100%">
<tableNavBar showFilter="false" tablePaneId="table1"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table1');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table1');"
/>
<tablePane id="table1" cellSpacing="2"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="1000"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
queryClass="SYS.Monitor.Interop.Interface.Utils"
queryName="InteropInterfaces"
>
<column colName="Type" header="Type" OnDrawCell="DisplayType"/>
<column colName="Count" header="Total"/>
<parameter value="#(%page.StartDate)#"/>
<parameter value = "#(%page.EndDateEndOfDay)#"/>
<parameter value=""/>
<parameter value=""/>
<parameter value=""/>
<parameter value="1"/>
<parameter value="0"/>
<parameter value="0"/>
 </tablePane>
 </group>
 
 <group id="page_2" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="true" showMaxRows="false" showPageSize="true" tablePaneId="table2"
saveSizeMax="true" onfilterChange="zenPage.filterChanged('table2',value);" onPageSizeChange="zenPage.navPageSizeChanged(value,'table2');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table2');"
/>
<tablePane id="table2" cellSpacing="2"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="10000"
pageSize="100"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
queryClass="SYS.Monitor.Interop.Interface.Utils"
queryName="InteropInterfaces"
>
<column colName="Namespace" header="Namespace"/>
<column colName="Type" header="Type" OnDrawCell="DisplayType"/>
<column colName="Count" header="Total"/>
<parameter value="#(%page.StartDate)#"/>
<parameter value = "#(%page.EndDateEndOfDay)#"/>
<parameter value="#(%page.FilterValue)#"/>
<parameter value=""/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="1"/>
<parameter value="0"/>
<parameter value="1"/>
 </tablePane>
</group>
<group id="page_3" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="false" showMaxRows="false" showPageSize="true" tablePaneId="table3"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table3');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table3');"
/>
<tablePane id="table3" cellSpacing="2"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="10000"
pageSize="100"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
queryClass="%SYS.Monitor.Interop.Messages.Utils"
queryName="MetricsPerType"
>
<column colName="Date" header="Date"/>
<column colName="Type" header="Type" OnDrawCell="DisplayType"/>
<column colName="Volume" header="Volume"/>
<parameter value="#(%page.StartDate)#"/>
<parameter value="#(%page.EndDateEndOfDay)#"/>
 </tablePane>
</group>
<group id="page_4" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="false" showMaxRows="false" showPageSize="true" tablePaneId="table4"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table4');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table4');"
/>
<tablePane id="table4" cellSpacing="2"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="10000"
pageSize="100"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
queryClass="%SYS.Monitor.Interop.Messages.Utils"
queryName="MetricsPerNamespace"
>
<column colName="Date" header="Date"/>
<column colName="Namespace" header="Namespace"/>
<column colName="Type" header="Type" OnDrawCell="DisplayType"/>
<column colName="Volume" header="Volume"/>
<parameter value="#(%page.StartDate)#"/>
<parameter value="#(%page.EndDateEndOfDay)#"/>
 </tablePane>
</group>
<group id="page_5" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="false" showMaxRows="false" showPageSize="true" tablePaneId="table5"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table5');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table5');"
/>
<tablePane id="table5" cellSpacing="2"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="10000"
pageSize="100"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
queryClass="%SYS.Monitor.Interop.DatabaseImpact.Utils"
queryName="Impact"
>
<column colName="Database" header="Database"/>
<column colName="DataCreated" header="Data Created (MB)"/>
<parameter value="#(%page.StartDate)#"/>
<parameter value="#(%page.EndDateEndOfDay)#"/>
 </tablePane>
</group>
<group id="page_6" width="100%" cellStyle="padding:10px" enclosingClass="tabBackground" hidden="true" >
<tableNavBar showFilter="true" msgFilter="Exclude databases shared by multiple namespaces (Y/N)" showMaxRows="false" showPageSize="true" tablePaneId="table6"
saveSizeMax="true" onfilterChange="zenPage.updateExcludeSharedDbs('table6',value);" onPageSizeChange="zenPage.navPageSizeChanged(value,'table6');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table6');"
/>
<tablePane id="table6" cellSpacing="2"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="10000"
pageSize="100"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
queryClass="%SYS.Monitor.Interop.DatabaseImpact.Utils"
queryName="ImpactPerNamespace"
>
<column colName="Namespace" header="Namespace"/>
<column colName="DataCreated" header="Data Created (MB)"/>
<parameter value="#(%page.StartDate)#"/>
<parameter value="#(%page.EndDateEndOfDay)#"/>
 </tablePane>
</group>
 </form>
 </hgroup>
 </vgroup>
</pane>
}

ClientMethod updateTable() [ Language = javascript ]
{
	var tableNum = parseInt((zenPage.View-1)*2) + parseInt(zenPage.Option);
  	var table = zen("table"+tableNum);
	table.executeQuery();
}

/// Clear error message from above results
ClientMethod resetMsg() [ Language = javascript ]
{
	zen("errMsg").setValue('');
	zen("errMsg").setHidden(true);
 	zen("errGrp").setHidden(true);
}

ClientMethod filterChanged(table, value) [ Language = javascript ]
{
	zenPage.FilterValue = value;
	zenPage.updateTable();
}

ClientMethod updateExcludeSharedDbs(table, value) [ Language = javascript ]
{
	var table = zen(table);
	if (value.toUpperCase().startsWith('Y')) {
		table.queryName="ImpactPerNamespaceExcludeSharedDBs";
	} else {
		table.queryName="ImpactPerNamespace";
	}
	zenPage.updateTable();
}

ClientMethod setOption(index) [ Language = javascript ]
{
    zenPage.Option = index;
	for ( var option=1; option<=2; option++ ) {
		if ( option == index ) {
			var opclass = "optionSelected";
            zenPage.updateTable();
		} else {
			var opclass="optionUnselected";
		}
		zen("option"+option).setProperty("enclosingClass",opclass);						
	}
	zenPage.showHidePages();
}

ClientMethod setView(index) [ Language = javascript ]
{
    zenPage.View = index;
	for ( var view=1; view<=3; view++ ) {
		if ( view == index ) {
			var opclass = "optionSelected";
            zenPage.updateTable();
		} else {
			var opclass="optionUnselected";
		}
		zen("view"+view).setProperty("enclosingClass",opclass);						
	}
	zenPage.showHidePages();
}

ClientMethod showHidePages() [ Language = javascript ]
{
	var hideAll = !zen("errGrp").hidden;
	var pageNum = parseInt(zenPage.View-1)*2 + parseInt(zenPage.Option);
	for (var i=1; i<=6; i++) {
		if ((i == pageNum)&&(!hideAll)) {
			zen("page_"+i).setHidden(false);
		} else {
			zen("page_"+i).setHidden(true);
		}
	}
	zen("Text1").setValue(this.getOptionTitle(pageNum));
}

ClientMethod getOptionTitle(pageNum) [ Language = javascript ]
{
	var title;
	switch (pageNum) {
		case 1:
			title = $$$Text("Interoperability interface summary:");
			break;
		case 2:
			title = $$$Text("Interoperability interfaces by namespace:");
			break;
		case 3:
			title = $$$Text("Interoperability message volume summary:");
			break;
		case 4:
			title = $$$Text("Interoperability message volume by namespace:");
			break;
		case 5:
			title = $$$Text("Estimated data created from message activity by database:");
			break;
		case 6:
			title = $$$Text("Estimated data created from message activity by namespace:");
			break;	
	}
	return title;
}

/// Method to add "Interfaces", "Volume", or "Size" to the Type name depending on which view we are in
Method DisplayType(table As %ZEN.Component.tablePane, dt As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
 	Set val = %query(dt)
	Write ..EscapeHTML(val_$Case(%page.View,1:" Interfaces",2:" Volume",3:" Size",:""))

	Quit $$$OK
}

ClientMethod updateDates() [ Language = javascript ]
{
	var err = zenPage.CheckDatesValid();
	if (err!="") {
		zen("errMsg").setValue(err);
	 	zen("errGrp").setHidden(false);
	 	zen("errMsg").setHidden(false);
	 	zenPage.showHidePages();
	 	return;
	}	
	zenPage.resetMsg();
	
    zenPage.StartDate = zen('startDate').value;
    zenPage.EndDate = zen('endDate').value;
    zenPage.updateTable();
    zenPage.showHidePages();
}

Method CheckDatesValid() As %String [ ZenMethod ]
{
	Set tStart = ..%GetComponentById("startDate").value
	If -1 = tStart {
		Return $System.Status.GetOneStatusText($$$ERROR($$$InteropInvalidDate))
	}
	Try {
        Set x = $ZDATETIMEH(tStart,3)
    } Catch timeEx {
        If timeEx.Name="<VALUE OUT OF RANGE>" {
            Return $System.Status.GetOneStatusText($$$ERROR($$$InteropStartOutOfRange,tStart))
        } Else {
            Return $System.Status.GetOneStatusText($$$ERROR($$$InteropInvalidDate))
        }
    }
    If $SYSTEM.SQL.Functions.DATEDIFF("second",tStart,$ztimestamp) < 0 {
        Return $System.Status.GetOneStatusText($$$ERROR($$$InteropStartTimeAfterCurrentTime,tStart))
    }
    
	Set tEnd = ..%GetComponentById("endDate").value
	If -1 = tEnd {
		Return $System.Status.GetOneStatusText($$$ERROR($$$InteropInvalidDate))
	}
    Try {
        Set x = $ZDATETIMEH(tEnd,3)
    } Catch timeEx {
        If timeEx.Name="<VALUE OUT OF RANGE>" {
            Return $System.Status.GetOneStatusText($$$ERROR($$$InteropEndOutOfRange,tEnd))
        } Else {
            Return $System.Status.GetOneStatusText($$$ERROR($$$InteropInvalidDate))
        }
    }
    If $SYSTEM.SQL.Functions.DATEDIFF("second",tStart,tEnd) < 0 {
        Return $System.Status.GetOneStatusText($$$ERROR($$$InteropStartTimeAfterEndTime))
    } 
	
	Quit ""
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.updateTable(1);
	zen("Text1").setValue(this.getOptionTitle(1));
}

Method %OnAfterCreatePage() As %Status
{
	Set tNow = $ZDATE($ztimestamp,3)
	Set ..StartDate = $P(tNow,"-",1,2)_"-01"
	Set ..EndDate = tNow
	
	Set ..%GetComponentById("startDate").value = ..StartDate
    Set ..%GetComponentById("endDate").value = ..EndDate

	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
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
	Quit $$$Text("Interoperability Usage")
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
    this.updateTable();
    this.updateTime();
}

}
