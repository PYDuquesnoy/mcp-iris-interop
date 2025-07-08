/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.SQL.QButtons.ShowPlanAlt Extends (%CSP.UI.Template.Property, %CSP.UI.Portal.UtilsNav, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

Parameter RESOURCE = "%Development:USE";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.ShowPlanAlt.zen";

Parameter HELPADDRESS = "Home,SQL Alternate Show Plans";

/// Displayed name of this page.
Parameter PAGENAME = "SQL.QButtons.ShowPlanAlt";

Property PlanPage As %String;

Property ViewProcessPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/op/%25CSP.UI.Portal.ProcessDetails.zen",,1)} ];

Property QUERYCLASS As %ZEN.Datatype.string [ InitialExpression = "%CSP.UI.Portal.SQL.QButtons.ShowPlanAlt" ];

Property QUERYNAME As %ZEN.Datatype.string [ InitialExpression = "possiblePlans" ];

Property QUERYTEXT As %ZEN.Datatype.string;

Property COMPAREROWS As %ZEN.Datatype.string;

/// Whether the current background job is for compare show plan
Property IsCompare As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property JOBID As %ZEN.Datatype.integer;

XData Style
{
<style type="text/css">
#groupView {
	min-width: 550px;
	overflow: auto;
}
#propertyPane {
	background: white;
	width: 550px;
	border-right: none;
	border-bottom: none;
	display: none;
}
#groupContent {
	padding: 10px;
	color: #546075;
}
.sectionLabel {
	color: #546076;
	font-size: 1.0em;
	padding-top: 2px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none" containerStyle="padding-top:10px;">
<label id="Text1" value="" enclosingStyle="padding:10px;"/>
<group id="groupContent" layout="none" hidden="true" >
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-left:10px;"/>
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>
<hgroup id="mainGroup" cellVAlign="top">
<group id="groupView" layout="none">
<label label="Enter an SQL statement and click 'Show Plan Options'. The resulting table will list the different plans the SQL Optimizer generated." labelClass="caption sectionLabel"/>
<form id="form1" labelPosition="top">
<checkbox id="chkBackground" 
caption="Run 'Show Plan Options' or 'Compare' in the background" 
captionClass="zenLabel"
value="0" 
 hint=" (Highly recommended for large queries that may take a long time to run)"
  containerStyle="padding-top:10px;"
  />
<label label="SQL Statement:" labelClass="normal sectionLabel" containerStyle="padding-top:10px;"/>
<hgroup>
<textarea id="QueryText" rows="5" cols="80" valign="top"/>
 <image id="imageClearQueryText" src="csp/broker/deepsee/ds2_circle_x_44.png" width="16" height="16" onclick="zenPage.doClearQueryText();" title="Clear query text" valign="top" hidden="true"/>
</hgroup>
<hgroup containerStyle="padding-bottom:10px;">
<button id="btnShowPlan" caption="Show Plan Options" controlClass="commandButton" onclick="zenPage.doGetPlans();"/>
<button id="btnShowHistory" caption="Show History" controlClass="commandButton" onclick="zenPage.doHistory();"/>
</hgroup>
<group id="group2" hidden="true">
<label label="Possible Plans" labelClass="normal sectionLabel"/>
<label label="(You may check multiple IDs from the table below, then click the 'Compare Show Plans' button.)" labelClass="zenHint" />
<spacer height="2"/>
<tablePane id="GetPlansTable"
queryClass="%CSP.UI.Portal.SQL.QButtons.ShowPlanAlt"
queryName="possiblePlans"
cellSpacing="1"
dataSource="columns"
fixedHeaders="false"
multiSelect="true"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
initialExecute="false"
OnCreateResultSet="CreateRS"
OnExecuteResultSet="ExecuteRS"
>
<column colName="ID"/>
<column colName="Cost"/>
<column colName="MapType" header="Map Type"/>
<column colName="StartingMap" header="Starting Map"/>
<column linkCaption="Show Plan" link="javascript:zenPage.doShowPlan('#(%query.ID)#',0);" 
style="text-align:center;" title="View Show Plan without stats"/>
<column linkCaption="Show Plan with Stats" link="javascript:zenPage.doShowPlan('#(%query.ID)#',3);" 
style="text-align:center;" title="View Show Plan with stats"/>
<parameter value=""/>
</tablePane>
</group>
</form>

<button id="btnViewProcess" caption="View Process" controlClass="commandButton" onclick="zenPage.doViewProcess();" hidden="true"/>

<group id="ongoingPossible" hidden="true">
<spacer height="10"/>
<html>
<p class="note" id="ongoingPossibleText">Get possible plans job is running ... please wait!</p>	
<progress ></progress>
</html>
</group>
<vgroup id="idHistory" hidden="true" enclosingStyle="width:640px;height:300px;overflow:auto;" containerStyle="padding-left:2px;">
<tableNavBar showFilter="true" showPageSize="true" showMaxRows="true" tablePaneId="tableQueryHistory" 
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'tableQueryHistory');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'tableQueryHistory');"
onfilterChange="zenPage.historyFilterChanged(value);"
/>
<tablePane id="tableQueryHistory" caption="Click a row to select statement"
pageSize="0"
maxRows="1000"
initialExecute="false"
queryClass="%SQL.Manager.Catalog"
queryName="QueryHistory"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
onselectrow="zenPage.selectHistory(zenThis.getValue());"
>
<column colName="SQL_STATEMENT_120" header="SQL Statement"/>
<column colName="SQL_STATEMENT" hidden="true"/>
<column colName="ID" hidden="true"/>
<column colName="LAST_EXECUTED" header="Execution Time" title="Timestamp of the last execution of the statement."/>
<column colName="EXECUTE_COUNT" header="Count" title="Number of times this Statement has been executed."/>
<parameter value="#(%page.Filter)#"/>
</tablePane>
</vgroup>
<form id="form2" hidden="true">
<button id="btnCompare" caption="Compare Show Plans with Stats" controlClass="commandButton" onclick="zenPage.doComparePlans();" />
<spacer height="10"/>
<tablePane id="ComparePlansTable" label="Compare Possible Plans" labelClass="normal sectionLabel"
queryClass="%SYS.PTools.StatsSQL"
queryName="possiblePlansStats"
hidden="true"
cellSpacing="1"
dataSource="columns"
fixedHeaders="false"
multiSelect="false"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
initialExecute="false"
OnCreateResultSet="CreateRSCompare"
OnExecuteResultSet="ExecuteRSCompare"
>
<column colName="ID"/>
<column colName="Cost"/>
<column colName="StartingMap" header="Starting Map"/>
<column colName="GlobalRef" header="Global Ref"/>
<column colName="Commands" />
<column colName="TotalTime" header="Total Time"/>
<column colName="RowsReturned" header="Rows Returned"/>
<column linkCaption="Show Plan with Stats" link="javascript:zenPage.doShowPlan('#(%query.ID)#',3);" 
style="text-align:center;" title="View Show Plan with stats"/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
</form>
</group>
<spacer width="1" containerStyle="border-right:2px solid #dddddd;" />

<group id="propertyPane" hidden="true" layout="none" enclosingStyle="height:100%;" containerStyle="vertical-align:top;">
<iframe id="outputShowplan" valign="top" containerStyle="padding-top:10px;height:100%" enclosingStyle="height:100%" hidden="true"/>
</group>
</hgroup>

</group>

</pane>
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
	
		this.adjustSizes();	
		document.getElementById("ongoingPossibleText").innerHTML = zenText("ongoingPossibleText");
		zen('groupContent').setHidden(false);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var rightDiv = zen('propertyPane').getEnclosingDiv(); //right
		var leftDiv = zen('groupView').getEnclosingDiv(); //left

		var halfWinWidth = (winWidth / 2) - 25;
		halfWinWidth = (halfWinWidth<300) ? 300 : halfWinWidth;
	
		leftDiv.style.width = halfWinWidth - 20 + 'px';
		rightDiv.style.width = halfWinWidth + 'px';
	
		if (leftDiv.scrollHeight) {
			tabBodyHgt = leftDiv.scrollHeight;
		}
		else {
			var th = this.getTitleAreaHeight();
			var hgt = winHeight - th - 100;
			var tabBodyHgt = (hgt - 30);
			tabBodyHgt = (tabBodyHgt < 141) ? 141 : tabBodyHgt;
		}
		frame = zen("outputShowplan");
		frame.setProperty("width",rightDiv.style.width);
		frame.setProperty("height",tabBodyHgt + 'px');

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

ClientMethod timeout() [ Language = javascript ]
{
	if (!this._jobNumber) {
		return;	
	}
	var proxy = this.CheckJobStatus(this._jobNumber);
	switch (proxy.status) {
		case 'running':
		case 'suspended':
			if (proxy.status == 'suspended') {
				document.getElementById("ongoingPossibleText").innerHTML = proxy.msg;
			}
			var timer = zen('timer');
			timer.setProperty('timeout',4000);
			timer.startTimer();
			break;
		case 'done':
		case 'error':
		case 'terminated':
			if (proxy.status == 'error') {
				document.getElementById("ongoingPossibleText").innerHTML = proxy.msg;
			}
			if (this._proxy) {
				this.QUERYCLASS = "%CSP.UI.Portal.SQL.QButtons.ShowPlanAlt";
				if (!this.IsCompare) {
					var table = zen('GetPlansTable');
					this.QUERYNAME = "possiblePlans";
				} else {
					var table = zen("ComparePlansTable");
					this.QUERYNAME = "possiblePlansStats";
				}
				this.JOBID = this._jobNumber;
				table.executeQuery(0);
				zen('form2').setHidden(false);
				zen('ongoingPossible').setHidden(true);		
				delete this._jobNumber;
			} else {
				alert('cannot find this._proxy -- unable to continue.');
			}
			this.toggleFields(false);
			break;
	}
}

ClientMethod doHistory() [ Language = javascript ]
{
	zen("group2").setHidden(true);
	zen("form2").setHidden(true);
	var hide = zen("idHistory").getProperty("hidden");
	zen("outputShowplan").setHidden(hide);
	zen("idHistory").setHidden(!hide);
	var table = zen("tableQueryHistory");
	table.executeQuery();
}

/// This method processes actions for a query history item.
ClientMethod selectHistory(tID) [ Language = javascript ]
{
	if (tID != "") {
		var tText = this.GetQueryHistoryText(tID);
		zen("QueryText").setValue(tText);
		zenPage.toggleClearText(zen("QueryText"));
	}
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod historyFilterChanged(value) [ Language = javascript ]
{
	this.Filter = value;
	var table = zen("tableQueryHistory");
	table.parameters[0].value = value;
	table.executeQuery();
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows,"tableQueryHistory");
}

ClientMethod doClearQueryText() [ Language = javascript ]
{
	zen("QueryText").setValue('');
	this.toggleClearText(zen("QueryText"));
	zen("group2").setHidden(true);
	zen("form2").setHidden(true);
	zen("QueryText").focus();
}

/// Invoke method to gather SQL Statements and update SQL Statement Count table. During this time, disable the rasio buttons.
ClientMethod doGetPlans() [ Language = javascript ]
{
	var query = zen("QueryText").getValue();
	if(zenTrim(query)==='') {
		alert($$$Text("Please enter a query!"));
		zen("QueryText").focus();
		return false;
	};
	this.IsCompare = 0;
	zen("idHistory").setHidden(true);
	zen("propertyPane").setHidden(true);
	zen("ComparePlansTable").setHidden(true);
	zen("group2").setHidden(false);
	var chkBackground = ((zen("chkBackground").getValue()==true)) ? 1 : 0;
	zen("outputShowplan").setHidden(!chkBackground);
	var status = this.PrepareShowPlan(query);
	if (!chkBackground) {
		this.QUERYCLASS = "%SYS.PTools.StatsSQL";
		this.QUERYNAME = "possiblePlans";
		this.QUERYTEXT = query;
		var table = zen("GetPlansTable");	
		table.executeQuery(0);
		zen('form2').setHidden(false);
	} else {
		// start process in background
		// display background status 
		this.toggleFields(true);
		zen('form2').setHidden(true);
		document.getElementById("ongoingPossibleText").innerHTML = zenText("ongoingPossibleText");
		zen('ongoingPossible').setHidden(false);
		delete this._jobNumber;
		var proxy = this.JobPossiblePlans(query);
		this._proxy = proxy;
		if (proxy.jobNumber) {
			// start timer to check status
			// if background process is finished, display result
			this._jobNumber = proxy.jobNumber;
			//var output = zen('outputShowplan');
			var timer = zen('timer');
			timer.setProperty('timeout',2000);
			timer.startTimer();
		} else {
			if (proxy.error) {
				alert(proxy.error);	
			}	
		}
			
	}
}

ClientMethod toggleFields(hideflag) [ Language = javascript ]
{
	zen("btnShowPlan").setHidden(hideflag);
	zen("btnShowHistory").setHidden(hideflag);
	zen("btnViewProcess").setHidden(!hideflag);
	zen('QueryText').setDisabled(hideflag);
}

ClientMethod doComparePlans() [ Language = javascript ]
{
	var query = zen("QueryText").getValue();
	if(zenTrim(query)==='') {
		alert($$$Text("Please enter a query!"));
		zen("QueryText").focus();
		return false;
	};
	this.IsCompare = 1;
	zen("ComparePlansTable").setHidden(false);
	var table1 = zen("GetPlansTable");
	var table2 = zen("ComparePlansTable");

	this.COMPAREROWS = table1.getProperty("selectedRows");
	// yan: if user did not select any, give message?
	
	var chkBackground = ((zen("chkBackground").getValue()==true)) ? 1 : 0;
	zen("outputShowplan").setHidden(!chkBackground);
	var status = this.PrepareShowPlan(query);
	if (!chkBackground) {
		this.QUERYCLASS = "%SYS.PTools.StatsSQL";
		this.QUERYNAME = "possiblePlansStats";
		this.QUERYTEXT = query;
		table2.parameters[0].value = query;
		table2.parameters[1].value = this.COMPAREROWS;
		table2.executeQuery(0);
	} else {
		// start process in background
		// display background status 
		this.toggleFields(true);
		zen('form2').setHidden(true);
		document.getElementById("ongoingPossibleText").innerHTML = zenText("ongoingCompareText");
		zen('ongoingPossible').setHidden(false);
		delete this._jobNumber;
		var stats = 0;
		var proxy = this.JobComparePlans(query, this.COMPAREROWS);
		this._proxy = proxy;
		if (proxy.jobNumber) {
			// start timer to check status
			// if background process is finished, display result
			this._jobNumber = proxy.jobNumber;
			//var output = zen('outputShowplan');
			var timer = zen('timer');
			timer.setProperty('timeout',2000);
			timer.startTimer();
		} else {
			if (proxy.error) {
				alert(proxy.error);	
			}	
		}	
	}
}

ClientMethod doShowPlan(ID, stats) [ Language = javascript ]
{
	zen("propertyPane").setHidden(false);
	zen('outputShowplan').setHidden(false);
	var propDiv = zen('propertyPane').getEnclosingDiv();
	propDiv.style.display = 'block';
	
	var query = zen("QueryText").getValue();
	var status = this.PrepareShowPlan(query);
	var planlink = this.PlanPage + "?namespace="+encodeURIComponent(this.NAMESPACE)+"&stats="+stats+"&verbose=1&AltPlan="+ID;
	zen('outputShowplan').setProperty('src',planlink);
}

/// View details of a background process for Show Plan
ClientMethod doViewProcess() [ Language = javascript ]
{
	if (!this._jobNumber) {
		alert($$$Text("Process number unavailable!"));
		return;
	}
	var PID = this._jobNumber;
	var url = this.ViewProcessPage + "PID=" + PID + "&DISPLAYID=" + PID + "&$ID1=" + PID;
	var win = window.open(url,'ViewProcessDetails');
	win.focus();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set %page.NAMESPACE = $G(%request.Data("$NAMESPACE",1))
	If %page.NAMESPACE = "" Set %page.NAMESPACE = $namespace
	
	Set %page.PlanPage = $P(..Link("%25SQL.Manager.ShowPlan.cls"),"?$NAMESPACE",1)
	
	Set ..%GetComponentById("Text1").value = $$$Text("Use options on this page to review alternate plans the SQL Optimizer may produce for an SQL statement.")
	If ..Filter = "*",$G($$$IRISTempMgt($Username,..%GetPageName(),"TableNavState"))="" Set ..Filter=""
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Alternate Show Plans")
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("SQL Performance Tools","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
	
	Quit $$$OK
}

/// Draw html for details title: Routine name and Query text
Method DrawDetailsTitle(pSeed) As %Status
{
	&html<<h4>#($$$Text("Use this page to review Alternate Show Plans the SQL Optimizer produced."))#</h4>>
	Quit $$$OK
}

/// This query uses %AltPlan array generated from possiblePlans run in the background
Query possiblePlans(JobID As %String) As %Query(ROWSPEC = "ID:%Integer,Cost:%Integer,MapType:%String(MAXLEN=15),StartingMap:%String(MAXLEN=30),Plan:%String(MAXLEN=15)") [ SqlName = PT_possiblePlans, SqlProc ]
{
}

ClassMethod possiblePlansExecute(ByRef qHandle As %Binary, JobID As %String) As %Status [ PublicList = (backgrnd, showErr, wrtref) ]
{
	New backgrnd,showErr,wrtref
 	Set tSC=$$$OK	
	Try {
		Merge %AltPlan = $$$TempMgtPortalTask(JobID,"%AltPlan")
		Set qHandle=0
	}
	Catch {
	Set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }    
	QUIT tSC
}

ClassMethod possiblePlansFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = possiblePlansExecute ]
{
	Set qHandle=$O(%AltPlan(qHandle))
	If qHandle="" Set AtEnd=1,Row="" QUIT $$$OK
	
	Set cost = $FN($LG(%AltPlan(qHandle,0),1),"N",1)
	Set map = $LG($LG(%AltPlan(qHandle,0),3),2)
	Set type = $LG($LG(%AltPlan(qHandle,0),3),1)
	Set Row = $LB(qHandle,cost,map,type,"Plan")
	
	Quit $$$OK
}

ClassMethod possiblePlansClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = possiblePlansFetch ]
{
	Kill %AltPlan
	Quit $$$OK
}

/// This query uses %AltPlan array generated from possiblePlans run in the background
Query possiblePlansStats(JobID As %String) As %Query(ROWSPEC = "ID:%Integer,Cost:%Integer,StartingMap:%String,GlobalRef:%Integer,Commands:%Integer,TotalTime:%Integer,RowsReturned:%Integer,Plan:%String") [ SqlName = PT_possiblePlansStats, SqlProc ]
{
}

ClassMethod possiblePlansStatsExecute(ByRef qHandle As %Binary, JobID As %String) As %Status [ PublicList = (backgrnd, showErr, wrtref) ]
{
	New backgrnd,showErr,wrtref
 	Set tSC=$$$OK	
	Try {
		Merge %AltPlan = $$$TempMgtPortalTask(JobID,"%AltPlanCompare")
		Set qHandle=0
	}
	Catch {
	Set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }    
	QUIT tSC
}

ClassMethod possiblePlansStatsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = possiblePlansExecute ]
{
	Set qHandle=$O(%AltPlan(qHandle))
	If qHandle="" Set AtEnd=1,Row="" QUIT $$$OK

	Set line = 1
	While 1 {
		Set line = $O(%AltPlan(qHandle,line),1,data)
		QUIT:line=""
		CONTINUE:data'="<stats>"
		
		While 1 {
			Set line = $O(%AltPlan(qHandle,line),1,data)
			QUIT:(data="</stats>")||(data="")	// End of Statistics Info!
			
			Set:data["<TimeSpent" time = $p($p(data,">",2),"<",1)
			Set:data["<GlobalRefs" globals = $p($p(data,">",2),"<",1)
			Set:data["<CommandsExecuted" commands = $p($p(data,">",2),"<",1)
			Set:data["<RowCount" rows = $p($p(data,">",2),"<",1)
		}
			
		QUIT
	}
	
	Set cost = $FN($LG(%AltPlan(qHandle,0),1),"N",1)
	Set map = $LG($LG(%AltPlan(qHandle,0),3),1)
	Set Row = $LB(qHandle,cost,map,globals,commands,time,rows,"Plan")
	
	Quit $$$OK
}

ClassMethod possiblePlansStatsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = possiblePlansFetch ]
{
	Kill %AltPlan
	Quit $$$OK
}

ClassMethod PrepareShowPlan(query, rtn = "") As %String [ ZenMethod ]
{
	//Set %session.Data("$SQLQUERY") = query
	Set ^mqh($Username) = query
	
	QUIT $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSQL",$$$Text("SQL Home"),$$$Text("Goto the SQL Home page"),"zenPage.gotoPToolsPage('sqlhome');")

	Quit $$$OK
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
	Set pResources("statementTitle") = $$$TextHTML("SQL Statement")
	Set pResources("statsTitle") = $$$TextHTML("Query Statistics")
	Set pResources("ongoingPossibleText") = $$$TextHTML("Get possible plans job is running ... please wait!")
	Set pResources("ongoingCompareText") = $$$TextHTML("Compare plans job is running ... please wait!")
	Quit $$$OK
}

/// Method to job off Show Plan process in the background.
ClassMethod JobPossiblePlans(query) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tParms("Username") = $Username
	Set tParms("Namespace") = $ZU(5)
	Set tParms("QueryText") = query
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("JobPossiblePlans",$zu(5),.tParms,.tItems,.tJob)
	If $$$ISERR(status) {
		Set tError = $System.Status.GetErrorText(status)
		Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg(tError)
		Set proxy.status = 0
		Set proxy.error = tError
	} Else {
		Set proxy.status = 1
		Set proxy.jobNumber = tJob
		Set proxy.Username = $Username
		Set proxy.msg = $$$TextHTML("Show Plan process started in the background.")
	}
	Quit proxy
}

/// Method to job off Compare Show Plan process in the background.
ClassMethod JobComparePlans(query, idList) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tParms("Username") = $Username
	Set tParms("Namespace") = $ZU(5)
	Set tParms("QueryText") = query
	Set tParms("stats") = 2
	Set tParms("idList") = idList
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("JobComparePlans",$zu(5),.tParms,.tItems,.tJob)
	If $$$ISERR(status) {
		Set tError = $System.Status.GetErrorText(status)
		Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg(tError)
		Set proxy.status = 0
		Set proxy.error = tError
	} Else {
		Set proxy.status = 1
		Set proxy.jobNumber = tJob
		Set proxy.Username = $Username
		Set proxy.msg = $$$TextHTML("Compare Show Plans process started in the background.")
	}
	Quit proxy
}

/// <var>pInfo</var> holds details on how to create the query.
Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pRS = ""
	Set Query = %page.QUERYCLASS _ ":" _ %page.QUERYNAME
	Set pRS = ##class(%ResultSet).%New(Query)
	Quit pRS
}

/// Method for executing the process query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	If %page.QUERYCLASS = "%SYS.PTools.StatsSQL" {
		Set tSC = pRS.Execute(%page.QUERYTEXT) 	
	} Else {
		Set tSC = pRS.Execute(%page.JOBID)
	}
	Quit tSC
}

/// <var>pInfo</var> holds details on how to create the query for compare show plans run in the background
Method CreateRSCompare(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pRS = ""
	Set Query = %page.QUERYCLASS _ ":" _ %page.QUERYNAME
	Set pRS = ##class(%ResultSet).%New(Query)
	Quit pRS
}

/// Method for executing the compare show plans query when it is run in the background
Method ExecuteRSCompare(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	If %page.QUERYCLASS = "%SYS.PTools.StatsSQL" {
		Set tSC = pRS.Execute(%page.QUERYTEXT) 	
	} Else {
		Set tSC = pRS.Execute(%page.JOBID) 
	}
	Quit tSC
}

}
