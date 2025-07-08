/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Zen page for System Management Portal - View Audit Database
Class %CSP.UI.Portal.Audit.View Extends %CSP.UI.Template.List [ System = 4 ]
{

/// Allow to change namespaces for this page.
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "AuditList";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.View.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing";

Property FILETYPE As %String [ InitialExpression = "Audit" ];

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property ColorBy As %String;

Property SQLEventName As %String;

Property JSONSearch As %String;

Property EventName As %String;

Property EventSource As %String;

Property EventType As %String;

Property PID As %String;

Property SystemID As %String;

Property Users As %String;

Property Authentications As %String;

XData Style
{
<style type="text/css">
table.tpTable td {
	padding:4px 6px;
}
</style>
}

/// This pane displays the search criteria. We provide defaults and user can change them.
/// User's values are saved and used as future defaults for this user.
/// Subclass to override.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >

<form name="searchForm" id="searchForm" layout="vertical" cellStyle="padding: 2px 10px; font-size:0.8em;">
<combobox id="EventSource" label="Event Source" labelClass="optionLabel" editable="true" unrestricted="true" size="19"
title="Enter a search pattern. This can include * as a wild card." onchange="zenPage.EventChange('Source');"/>
<combobox id="EventType" label="Event Type" labelClass="optionLabel" editable="true" unrestricted="true" size="19"
title="Enter a search pattern. This can include * as a wild card." onchange="zenPage.EventChange('Type');"/>
<combobox id="EventName" label="Event Name" labelClass="optionLabel" editable="true" unrestricted="true" size="19"
title="Enter a search pattern. This can include * as a wild card." onchange="zenPage.EventNameChange();"/>
<combobox id="SQLEventName" label="SQL Statement Type" labelClass="optionLabel" editable="true" unrestricted="true" size="19"
title="Enter a search pattern. This can include * as a wild card." onchange="zenPage.SQLEventNameChange();"/>
<text id="SystemID" label="System IDs" labelClass="optionLabel" size="19"
title="Enter a search pattern. This can include * as a wild card."/>
<text id="PID" label="PIDs" labelClass="optionLabel" size="19"
title="Enter a search pattern. This can include * as a wild card."/>
<listBox id="Users" label="Users" labelClass="optionLabel">
<option value="*" text="* (All)"/>
</listBox>
<listBox id="Authentications" label="Authentications" labelClass="optionLabel">
<option value="*" text="* (All)"/>
</listBox>
<dateText id="BeginDate" label="Begin Date/Time" showTime="true" defaultTime="00:00:00" labelClass="optionLabel" size="18" 
title="Leave blank to begin with earliest record." onkeyup="zenPage.keyUp(zenEvent,zenThis);" onblur="zenThis.ondatechangeHandler();"/>
<dateText id="EndDate" label="End Date/Time" showTime="true" defaultTime="00:00:00" labelClass="optionLabel" size="18"
title="Leave blank for current time." onkeyup="zenPage.keyUp(zenEvent,zenThis);" onblur="zenThis.ondatechangeHandler();"/>
<text id="JSONSearch" label="JSON String Search" labelClass="optionLabel" title="Enter a JSON field search pattern" size="21"/>
<text id="MaxRows" label="Maximum Rows" labelClass="optionLabel" title="Maximum number of rows to load - enter a number between 1 - 10000" size="6"/>
<!--<select id="ColorBy" label="Color by" showEmpty="true" valueList="TimeStamp,EventSource,EventType,Event,Pid,Username,Description" displayList="Time Stamp,Event Source,Event Type,Event,PID,Username,Description"/>-->
<hgroup>
<link caption="Reset Values" title="Reset search form to default values." href="#" onclick="zenPage.doReset();return false;"/>
<spacer width="10px"/>
<button caption="Search" onclick="zenPage.doSearch();"/>
</hgroup>
</form>

</pane>
}

XData resultPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:2px">
<tableNavigatorBar showFilter="false" showPageSize="true" saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" tablePaneId="table"/>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="%SYS.Audit"
queryName="List"
dataSource="columns"
fixedHeaders="false"
maxRows="1000"
pageSize="100"
showValueInTooltip="false"
showZebra="true"
valueColumn="AuditIndex"
useSnapshot="true"
OnExecuteResultSet="ExecuteRS"
initialExecute="0"
>
<column colName="SystemID" hidden="true"/>
<column colName="AuditIndex" hidden="true"/>
<column colName="TimeStamp" header="Time"/>
<column colName="EventSource" header="Event Source"/>
<column colName="EventType" header="Event Type"/>
<column colName="Event" header="Event"/>
<column colName="Pid" header="PID"/>
<column colName="SessionID" header="Web Session"/>
<column colName="Username" header="User"/>
<column colName="Description" header="Description"/>
<column colName="UTCTimeStamp" hidden="true"/>
<column colName="Group" hidden="true"/>
<column colName="JobNumber" hidden="true"/>
<column colName="Authentication" hidden="true"/>
<column OnDrawCell="DrawDetailLink"/>
</tablePane>
<html id="welcomeText" OnDrawContent="WelcomeText"></html>
</pane>
}

/// Method for executing the audit list query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Kill $$$IRISTempMgt($Username,%page.FILETYPE,"Complete")
	set Names = ""
	if (%page.SQLEventName'="*") { 
		if ($LF($LB("Query","DDL","DML","Utility"), %page.SQLEventName)) {
			set Names = "DynamicStatement"_%page.SQLEventName_",EmbeddedStatement"_%page.SQLEventName_",XDBCStatement"_%page.SQLEventName_","
		}
		elseif ($LF($LB("DynamicStatement","EmbeddedStatement","XDBCStatement"), %page.SQLEventName)) {
			set Names = %page.SQLEventName_"Query,"_%page.SQLEventName_"DDL,"_%page.SQLEventName_"DML,"_%page.SQLEventName_"Utility"
		}
	}
	if (%page.EventName'="*") { set Names = Names_%page.EventName_"," }
	if Names="" { set Names = "*," }
	Set tSC = pRS.Execute(%page.BeginDate,%page.EndDate,%page.EventSource,%page.EventType,$e(Names, 1, $LENGTH(Names)-1),%page.Users,%page.SystemID,%page.PID,"*",%page.Authentications,,%page.JSONSearch)
	// log execution finishing time (if query timed out, this will not be logged)
	Set $$$IRISTempMgt($Username,%page.FILETYPE,"Complete") = 1
	Quit tSC
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.showExpand();
	this.adjustSizes();
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent, ctl) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		ctl.ondatechangeHandler();
	}
}

/// User clicked reset link
ClientMethod doReset() [ Language = javascript ]
{
	zen('BeginDate').setValue("");
	//zen('ColorBy').setValue("");
	zen('EndDate').setValue("");
	zen('SQLEventName').setValue("*");
	zen('EventName').setValue("*");
	zen('EventSource').setValue("*");
	zen('EventType').setValue("*");
	zen('MaxRows').setValue(1000);
	zen('JSONSearch').setValue("");
	zen('PID').setValue("*");
	zen('SystemID').setValue("*");
	zen('Users').setValue("*");
	zen('Authentications').setValue("*");
}

/// User clicked Search button.
ClientMethod doSearch() [ Language = javascript ]
{
	var table = zen("table");
    zenSetProp('welcomeText','hidden',true);
	
	var BeginDate = zen('BeginDate').getValue();
	if (BeginDate == -1) {
		this.BeginDate = "";
	} else {
		this.BeginDate = BeginDate;
	}
	//this.ColorBy = zen('ColorBy').getValue();
	var EndDate = zen('EndDate').getValue();
	if (EndDate == -1) {
		this.EndDate = "";
	} else {
		this.EndDate = EndDate;
	}
	this.SQLEventName = zen('SQLEventName').getValue();
	this.EventName = zen('EventName').getValue();
	this.EventSource = zen('EventSource').getValue();
	this.EventType = zen('EventType').getValue();
	
	var MaxRows = zenTrim(zen('MaxRows').getValue());
	if ((MaxRows == "") || (isNaN(MaxRows)==true)) {
		MaxRows = 1000;
	} else if (parseInt(MaxRows) > 10000) {
		MaxRows = 10000;
	} else {
		MaxRows = Math.round(MaxRows);
	}
	zen('MaxRows').setValue(MaxRows);
	this.MaxRows = MaxRows;

	this.JSONSearch = zen('JSONSearch').getValue();
	
	this.PID = zen('PID').getValue();
	this.SystemID = zen('SystemID').getValue();
	this.Users = zen('Users').getValue();
	this.Authentications = zen('Authentications').getValue();

	var ok = this.SaveAuditSelections(this.FILETYPE,table.getProperty('pageSize'));
	
	table.setProperty("maxRows",MaxRows);
	table.executeQuery(0);
}

ClientMethod navPageSizeChanged(pageSize) [ Language = javascript ]
{
	var ok = this.SaveAuditSelections(this.FILETYPE,pageSize);
}

/// Overriding to remove refresh timer update
ClientMethod updateView() [ Language = javascript ]
{
	var table = zen("table");
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
}

ClientMethod launchDetails(timestamp, ID, index) [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Audit.Detail.zen')+'?PID='+encodeURIComponent(timestamp)+'||'+encodeURIComponent(ID)+'||'+encodeURIComponent(index);
	zenPage.launchPopupWindow(url,'Audit Details','status,scrollbars,resizable,width=700,height=850');
}

ClassMethod DrawDetailLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status [ Internal ]
{
	&html<<a href="#" onclick="zenPage.launchDetails('#(%query("UTCTimeStamp"))#','#(%query("SystemID"))#','#(%query("AuditIndex"))#');return false;">#($$$Text("Details"))#</a>>

	Quit $$$OK
}

Method SaveAuditSelections(FILETYPE As %String, PageSize As %String) As %String [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,FILETYPE) = ..BeginDate_"^"_..SQLEventName_"^"_..EndDate_"^"_..EventName_"^"_..EventSource_"^"_..EventType_"^"_..PID_"^"_..SystemID_"^"_..Users_"^"_..Authentications_"^"_..MaxRows_"^"_..JSONSearch_"^"_PageSize
	Quit $$$OK
}

ClassMethod GetLastSearch(FILETYPE As %String) As %String
{
	Set LastSearch = $G($$$IRISTempMgt($Username,FILETYPE))
	Set IsComplete = +$G($$$IRISTempMgt($Username,FILETYPE,"Complete"))
	If ((LastSearch = "") || ('IsComplete)) {
		Set LastSearch = "^*^^*^*^*^*^*^*^*^1000^"
	}
	Quit LastSearch
}

ClassMethod GetEventList(Box As %String) As %String
{
	set sql = 0
	if Box = "SQL" { set sql = 1, Box = "Name"}
	Set query = "Security.Events:List"_Box
	Set tRS = ##class(%ResultSet).%New(query)
	Set tSC = tRS.Execute()
	Set valueList = "*"
	if sql { Set valueList = "*,Query,DDL,DML,Utility,DynamicStatement,EmbeddedStatement,XDBCStatement" }
	Set stringList = $LB("DynamicStatement","EmbeddedStatement","XDBCStatement",
	"DynamicStatementQuery","EmbeddedStatementQuery","XDBCStatementQuery",
	"DynamicStatementDDL","EmbeddedStatementDDL","XDBCStatementDDL",
	"DynamicStatementDML","EmbeddedStatementDML","XDBCStatementDML",
	"DynamicStatementUtility","EmbeddedStatementUtility","XDBCStatementUtility",
	"Query","DDL","DML","Utility")
	While tRS.Next() && 'sql {
		if '$LISTFIND(stringList, tRS.GetData(1)) {
			Set valueList = valueList_","
			Set valueList = valueList_tRS.GetData(1)
		}
	}
	Quit valueList
}

ClientMethod EventChange(Box As %String) [ Language = javascript ]
{
	this.EventChangeOS(Box, zen("Event"+Box).getValue());
}

Method EventChangeOS(Box As %String, newval As %String) As %String [ ZenMethod ]
{
	Set query = "Security.Events:List"
	Set tRS = ##class(%ResultSet).%New(query)
	Set tSC = tRS.Execute()
	if Box = "Type" {
		Set valueList = "*"
		Set stringList = $LB("DynamicStatement","EmbeddedStatement","XDBCStatement",
			"DynamicStatementQuery","EmbeddedStatementQuery","XDBCStatementQuery",
			"DynamicStatementDDL","EmbeddedStatementDDL","XDBCStatementDDL",
			"DynamicStatementDML","EmbeddedStatementDML","XDBCStatementDML",
			"DynamicStatementUtility","EmbeddedStatementUtility","XDBCStatementUtility",
			"Query","DDL","DML","Utility")
		While tRS.Next() {
			if '$LISTFIND(stringList, tRS.GetData(3)) && ((newval = tRS.GetData(2)) || (newval = "*")) {
				Set valueList = valueList_","
				Set valueList = valueList_tRS.GetData(3)
				set stringList = stringList_$LB(tRS.GetData(3))
			}
		}
		Set tCombo = ..%GetComponentById("EventName")
		Set tCombo.valueList = valueList
		Set tCombo = ..%GetComponentById("SQLEventName")
		Set tCombo.valueList = $CASE(newval,"*":"*,Query,DDL,DML,Utility,DynamicStatement,EmbeddedStatement,XDBCStatement","%SQL":"*,Query,DDL,DML,Utility,DynamicStatement,EmbeddedStatement,XDBCStatement",:"*")
	}
	elseif Box = "Source" {
		Set valueList = "*"
		Set stringList = $LB()
		While tRS.Next() {
			if '$LISTFIND(stringList, tRS.GetData(2)) && (newval = tRS.GetData(1) || (newval = "*")) {
				Set valueList = valueList_","
				Set valueList = valueList_tRS.GetData(2)
				Set stringList = stringList_$LB(tRS.GetData(2))
			}
		}
		Set tCombo = ..%GetComponentById("EventType")
		Set tCombo.valueList = valueList
	}
	return $$$OK
}

ClientMethod EventNameChange() [ Language = javascript ]
{
	zen('SQLEventName').setValue("*");
}

ClientMethod SQLEventNameChange() [ Language = javascript ]
{
	zen('EventName').setValue("*");
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
	
	Set LastSearch = ..GetLastSearch(..FILETYPE)

	Set (..BeginDate,..%GetComponentById("BeginDate").value) = $P(LastSearch,"^",1)
	//Set (..ColorBy,..%GetComponentById("ColorBy").value) = $P(LastSearch,"^",2)
	Set (..SQLEventName,..%GetComponentById("SQLEventName").value) = $P(LastSearch,"^",2)
	Set (..EndDate,..%GetComponentById("EndDate").value) = $P(LastSearch,"^",3)
	Set (..EventName,..%GetComponentById("EventName").value) = $P(LastSearch,"^",4)
	Set (..EventSource,..%GetComponentById("EventSource").value) = $P(LastSearch,"^",5)
	Set (..EventType,..%GetComponentById("EventType").value) = $P(LastSearch,"^",6)
	Set (..PID,..%GetComponentById("PID").value) = $P(LastSearch,"^",7)
	Set (..SystemID,..%GetComponentById("SystemID").value) = $P(LastSearch,"^",8)
	Set (..Users,..%GetComponentById("Users").value) = $P(LastSearch,"^",9)
	Set (..Authentications,..%GetComponentById("Authentications").value) = $P(LastSearch,"^",10)
	Set (..MaxRows,..%GetComponentById("MaxRows").value) = $P(LastSearch,"^",11)
	Set (..JSONSearch,..%GetComponentById("JSONSearch").value) = $P(LastSearch,"^",12)

    #; Always expand the search bar on load since the table is no longer automatically populated
	Set ..searchExpanded = 1
	
	Set table = ..%GetComponentById("table")
	Set table.maxRows = %page.MaxRows
	Set table.pageSize = $P(LastSearch,"^",11)
	
	Set valueList = ..GetEventList("Source")
	If valueList '= "" {
		Set tCombo = ..%GetComponentById("EventSource")
		Set tCombo.valueList = valueList
	}
	Set valueList = ..GetEventList("Type")
	If valueList '= "" {
		Set tCombo = ..%GetComponentById("EventType")
		Set tCombo.valueList = valueList
	}
	Set valueList = ..GetEventList("Name")
	If valueList '= "" {
		Set tCombo = ..%GetComponentById("EventName")
		Set tCombo.valueList = valueList
	}
	Set valueList = ..GetEventList("SQL")
	If valueList '= "" {
		Set tCombo = ..%GetComponentById("SQLEventName")
		Set tCombo.valueList = valueList
	}
	
	Set count = 0
	Set tRS = ##class(%ResultSet).%New("Security.Users:List")
	Set tSC = tRS.Execute()
	While tRS.Next() {
		If (count > $G($$$IRISTempMgt($Username,"MaxUsers"),1000)) Quit
		Set option = ##class(%ZEN.Auxiliary.option).%New()
		Set option.value = tRS.GetData(1)
		Set option.text = ..EscapeHTML(tRS.GetData(1))
		Do %page.%AddComponent(option)
		Do ..%GetComponentById("Users").options.Insert(option)
		Set count = count + 1
	}

	i ##Class(Security.System).Exists(,.System)
	s AutheEnabled=$$AuthenticationLogicalToDisplay^%SYS.SECURITY(System.AutheEnabled)
	f i=1:1:$l(AutheEnabled,",") {
		Set option = ##class(%ZEN.Auxiliary.option).%New()
		Set option.value = $p(AutheEnabled,",",i)
		Set option.text = ..EscapeHTML($p(AutheEnabled,",",i))
		Do %page.%AddComponent(option)
		Do ..%GetComponentById("Authentications").options.Insert(option)
	}
	
	Quit 1
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("View Audit Database")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

Method WelcomeText(pSeed As %String) As %Status
{
    Write $$$TextHTML("Click the Search button to view results")
    Return $$$OK
}

}
