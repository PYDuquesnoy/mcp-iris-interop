/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Task on demand 
Class %CSP.UI.Portal.TasksUpcoming Extends %CSP.UI.Template.List [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.TasksUpcoming.zen";

Parameter HELPADDRESS = "Home,Task Manager,View Upcoming Tasks";

/// Displayed name of this page.
Parameter PAGENAME = "Upcoming Tasks";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property FILETYPE As %String [ InitialExpression = "Upcoiming Tasks" ];

Property RunTaskPage As %String [ InitialExpression = {..Link("UtilSysTaskAction.csp",,1)} ];

Property TitleText As %String [ InitialExpression = {$$$TextJS("The following is a list of tasks scheduled to run within the next %1 days.")} ];

Property TitleTextHour As %String [ InitialExpression = {$$$TextJS("The following is a list of tasks scheduled to run within the next 24 hours.")} ];

Property TitleTextDate As %String [ InitialExpression = {$$$TextJS("The following is a list of tasks scheduled to run between now and %1.")} ];

/// Store translated targetCol linkCaption for <condition>
Property colSuspend As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Suspend")} ];

Property colResume As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Resume")} ];

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

XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >

<form name="searchForm" id="searchForm" layout="vertical" cellStyle="padding: 2px 10px; font-size:0.8em;">
<radioSet id="radSelection" label="Scheduled to run:" value="24"
valueList="1,7,14,30,60,90,0" 
displayList="24 hours, 7 days,14 days,30 days,60 days,90 days,To a date"
width="90px" onchange="zenPage.selectDateType();"/>
<dateText id="txtDate" containerStyle="padding-left:36px;" 
disabled="true"
hint="yyyy-mm-dd" minDate=""
onchange="zenPage.selectedDate(zenThis);"
/>
<text id="maxRows" label="Maximum rows" labelClass="optionLabel" 
title="Maximum number of rows to load - cannot be greater than 10000" size="6" value="1000" onchange="zenPage.selectDateType();" onkeyup="zenPage.keyUp(zenEvent);"/>

</form>

</pane>
}

XData resultPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<vgroup valign="top">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a string to filter the list"
/>
<tablePane id="table"
queryClass="%SYS.Task"
queryName="UpcomingTasksFilter"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
>
<column colName="ID" hidden="true"/>
<column colName="Name" header="Task Name"/>
<column colName="Namespace" header="Namespace"/>
<column colName="Date" header="Date"/>
<column colName="Time" header="Time"/>
<column colName="Suspended" />
<column id="LinkSuspend" linkCaption="Suspend" link="javascript:zenPage.doAction('Suspend','#(%query.ID)#');" 
 style="text-align:center;"/>
 <column id="LinkResume" linkCaption="Resume" link="javascript:zenPage.doAction('Resume','#(%query.ID)#');" 
 style="text-align:center;"/>

 <condition colName="Suspended" predicate="NEQ" value="0" rowStyle="background: #FFB6C1;" cellStyle="disabled" targetCol="#(%page.colSuspend)#"/> 
 <condition colName="Suspended" predicate="EQ"  value="0" cellStyle="disabled" targetCol="#(%page.colResume)#"/> 

<parameter value="#(%page.Filter)#"/>
<parameter value="24"/>
<parameter value=""/>
<parameter value=""/>
<parameter value="1000"/>
 </tablePane>
 </vgroup>
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

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		this.doSearch();
	}
}

ClientMethod selectDateType() [ Language = javascript ]
{
	var selection = zen("radSelection").getValue();
	zen("txtDate").setDisabled(selection!=0);
	if (selection != 0) {
		if (selection == 1) {
			var hours = 24;
			var tTitle = this.TitleTextHour;
		} else {
			var hours = selection * 24;
			var tTitle = this.TitleText.replace("%1",selection);
		}
		zen("Text1").setValue(tTitle);
		this.doSearch(hours,"");
	} else {
		if (zen("txtDate").getValue() != "") {
			this.selectedDate(zen("txtDate"));	
		}	
	}
}

/// User entered or selected a date.
ClientMethod selectedDate(ctrl) [ Language = javascript ]
{
	var todate = ctrl.getValue();
	if (zenTrim(todate) == "") {
		return;	
	}
	var zdh = this.ConvertDate(todate);
	if (zdh == "") {
		return;
	}
	zen("Text1").setValue(this.TitleTextDate.replace("%1",ctrl.getValue()));
	this.doSearch(0,zdh);
}

ClientMethod doSearch(selection, todate) [ Language = javascript ]
{
	var maxRows = zenTrim(zen("maxRows").getValue());
	if ((maxRows == "") || (isNaN(maxRows)==true) || (parseInt(maxRows) > 10000)) {
		maxRows = 10000;
	} else {
		maxRows = Math.round(maxRows);
	}
	zen("maxRows").setValue(maxRows);	
	var table = zen("table");
	// 0 element is the filter which hasn't changed
	//table.parameters[0].value = selection;
	table.parameters[1].value = selection;
	table.parameters[2].value = todate;
	table.parameters[3].value = "";
	table.parameters[4].value = maxRows;
	table.setProperty("maxRows",maxRows);
	table.executeQuery();
	this.SaveSearch("Upcoming Tasks",zen("radSelection").getValue(),todate,"",maxRows);
}

ClientMethod doAction(action, PID) [ Language = javascript ]
{
	var viewlink = this.RunTaskPage + "Type="+action+"&$ID1=" + encodeURIComponent(PID);
	document.location = viewlink;
}

/// Update / Reload table. This overrides the one in Portal.Utils.
ClientMethod updateView() [ Language = javascript ]
{
	var table = zen("table");
	table.executeQuery(0);
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	this.updateTime();
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	Quit 1
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
		
	#; Check if user has security for "Run" schedule.
	If '$System.Security.Check("%Admin_Task","USE") {
		Set ..%GetComponentById("LinkSuspend").hidden = 1
		Set ..%GetComponentById("LinkResume").hidden = 1
	}
	Set ..%GetComponentById("txtDate").minDate = $ZDT($H,3)
	Set LastSearch = ..GetLastSearch()
	Set HoursOffset = $P(LastSearch,"^",1)
	Set ..%GetComponentById("radSelection").value = HoursOffset
	
	#; Based on value of HoursOffset we set default and construct the title text
	If $P(LastSearch,"^",2) '= "" {
		Set tToDate = $ZDT($P(LastSearch,"^",2),3)
		Set ..%GetComponentById("txtDate").value = tToDate
		Set ..%GetComponentById("txtDate").disabled = 0
		Set tTitle = $$$FormatText(..TitleTextDate,tToDate)
	} Else {
		Set tType = $S(HoursOffset=1:24_" "_$$$Text("hours"),1:HoursOffset_" "_$$$Text("days"))
		If HoursOffset = 1 Set tTitle = ..TitleTextHour
		Else  Set tTitle = $$$FormatText(..TitleText,tType)		
	}
	Set ..%GetComponentById("Text1").value = tTitle
	Set ..%GetComponentById("maxRows").value = $P(LastSearch,"^",4)
	i ..Filter="*" s ..Filter=""
	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Task Manager","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"))
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

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Upcoming Tasks")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Convert user selected date to $H format. If invalid entry then return "".
ClassMethod ConvertDate(pDate) As %Integer [ ZenMethod ]
{
	Try {
		Set ZDT = $ZDH(pDate,3)
		}
	Catch {
		Set ZDT = ""
	}
	Quit ZDT
}

/// HoursOffset value (default to 1 day) ^ ToDate ($H value of the date) ^ ToTime (currently not used) ^ maxRows
Method GetLastSearch() As %String
{
	Set LastSearch = $G($$$IRISTempMgt($Username,"Upcoming Tasks"))
	If LastSearch = "" Set LastSearch = "1^^^1000"
	Quit LastSearch
}

ClassMethod SaveSearch(FILETYPE, HoursOffset, ToDate, ToTime, maxRows) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,FILETYPE) = HoursOffset_"^"_ToDate_"^"_ToTime_"^"_maxRows
}

/// Disable save button for EMS-managed pages.
/// Be sure to use this.invokeSuper('onloadHandler',arguments); when overriding.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);	
	if (this.IsEMSReadOnly || this.InvalidParam) {
		this.disableCommandButton('btnSave');
		this.disableCommandButton('btnNew');
	}
	this.selectDateType();
}

}
