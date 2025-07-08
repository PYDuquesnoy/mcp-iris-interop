/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - SQL Performance Tool
Class %CSP.UI.Portal.SQL.QButtons.RuntimeStats Extends (%CSP.UI.Template.Property, %CSP.UI.Portal.UtilsNav, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

Parameter RESOURCE = "%Development:USE";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.RuntimeStats.zen";

Parameter HELPADDRESS = "Home,SQL Runtime Statistics";

/// Displayed name of this page.
Parameter PAGENAME = "SQL.QButtons.RuntimeStats";

Property PlanPage As %String;

Property ShowPlanOutput As %String;

Property OpenDetailsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.RuntimeStatsDetails.cls",,1)} ];

Property IndexAnalyzerPage As %ZEN.Datatype.string [ InitialExpression = {..Link("%25CSP.UI.Portal.SQL.QButtons.IndexAnalyzer.zen")} ];

Property ViewProcessPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/op/%25CSP.UI.Portal.ProcessDetails.zen",,1)} ];

/// Store translated targetCol linkCaption for <condition>
Property colDetails As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Details")} ];

Property openTab As %ZEN.Datatype.string(ZENURL = "openTab");

XData Style
{
<style type="text/css">
/* style for hand drawn table */
#tableView {
	height: 40.0em;
	overflow: auto;
}
.tpOdd	{ background: #C5E5C9; }
.tpEven	{ background: white; }
/* #C5E5C9;#D2CFDF; */
#divTerm {
	height:20px;
	overflow:auto;
}
#propertyPane {
	background: white;
	height: 449px;
	width: 550px;
	border-right: none;
	border-bottom: none;
	display: none;
}
#propertyTitle {
	height: 130px;
	width: 100%;
	overflow:auto;
}

/* --- Query Text --- */
.qp-header {
   color: white;
   width: 100%;
   height: 20px;
   
   text-align: center;
   vertical-align: bottom;
   font-size: 16px;
   font-weight: bold;
}

.qp-query-text-header {
   /* Use CSS 'qp-header' first in the class definition */
   background: rgb(53,107,141); /* For browsers that do not support gradients */
   background: -webkit-linear-gradient(rgb(53,107,141),rgb(23,77,101)); /* For Safari 5.1 to 6.0 */
   background: -o-linear-gradient(rgb(53,107,141),rgb(23,77,101)); 	  /* For Opera 11.1 to 12.0 */
   background: -moz-linear-gradient(rgb(53,107,141),rgb(23,77,101)); 	  /* For Firefox 3.6 to 15 */
   background: linear-gradient(rgb(53,107,141),rgb(23,77,101)); 	 	  /* Standard syntax (must be last) */
}

.qp-query-text-body {
   text-align: left;
   font-family: monospace;
   white-space: normal;
  
   padding-top:    0px;
   padding-left:   5px;
   padding-bottom: 5px;	
   
   margin-top: 0px;
}

.qp-query-text-body pre {
   vertical-align: top;
   text-align: left;
   white-space: normal;
   
   margin-top: 3px;
}
#groupContent {
	padding: 10px;
	color: #546075;
}
.mt-20 {
	margin-top: 20px;
}
#QueryTestDesc {
	padding-top:16px;	
}
</style>
}

XData SVGStyle
{
<style type="text/css">
.tabBarBackground { fill:white; stroke:white; }	
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none" containerStyle="padding-top:10px;">
<label id="Text1" value="" enclosingStyle="padding:10px;"/>
<jsonProvider id="jsonSettingsInfo" OnGetTargetObject="GetSettingsInfo">
 </jsonProvider>
 <timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>
<vgroup id="groupContent" cellVAlign="top" hidden="false">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-left:10px;"/>
<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white; stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":Settings:Query Test:View Stats"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<group id="content" width="100%" hidden="true" >

<group id="page_1">

<html>
<div id="htmlCurrentSettings"></div>
</html>
<button id="btnSettings" caption="Change Settings" controlClass="commandButton" onclick="zenPage.doSettings();"/>

</group> <!-- End of Page1 -->

<group id="page_2">
<html>
<div id="QueryTestDesc">The query entered below...</div>
</html>

<spacer height="2"/>
<form id="form1" labelPosition="left">
<checkbox id="chkBackground" caption="Run Show Plan process in the background" captionClass="zenLabel" value="0" hint=" (Highly recommended for large queries that may take a long time to run)"/>

<hgroup enclosingStyle="padding-top:6px;" >
<textarea id="QueryText"
rows="10" 
cols="80"
valign="top"
onkeyup="return zenPage.toggleClearText(zenThis);"
 />
 <image id="imageClearQueryText" src="csp/broker/deepsee/ds2_circle_x_44.png" width="16" height="16" onclick="zenPage.doClearQueryText();" title="Clear query text" valign="top" hidden="true"/>
</hgroup>
<hgroup cellStyle="padding-right:4px;">
<button id="btnShowPlan" caption="Show Plan with SQL Stats" controlClass="commandButton" onclick="zenPage.doShowPlan();"/>
<button id="btnShowHistory" caption="Show History" controlClass="commandButton" onclick="zenPage.doHistory();"/>
<button id="btnViewProcess" caption="View Process" controlClass="commandButton" onclick="zenPage.doViewProcess();" hidden="true"/>
</hgroup>
</form>
<vgroup id="idHistory" hidden="true" enclosingStyle="width:600px;height:300px;overflow:auto;" containerStyle="padding-left:2px;">
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
<iframe id="outputShowplan" hidden="true" valign="top" containerStyle="padding-top:10px;"/>
</group> <!-- End of Page2 -->

<group id="page_3">
<hgroup>
<vgroup id="groupView" valign="top">
<hgroup labelPosition="left" enclosingStyle="padding:8px;" cellAlign="even">
<label label="This following table includes information about all the queries that contain SQL Stats:" labelClass="caption"/>
<button id="btnView" caption="Refresh Table" onclick="zenPage.doView();"/>
</hgroup>
<group id="editorPane">
<tableNavBar showFilter="false" showPageSize="true" showMaxRows="true" tablePaneId="table"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
queryClass="%SYS.PTools.StatsSQL"
queryName="ViewStatsSQL"
cellSpacing="1"
dataSource="columns"
fixedHeaders="false"
multiSelect="false"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="RoutineCursor"
useSnapshot="true"
initialExecute="false"
>
<column colName="RoutineCursor" hidden="true"/>
<column colName="RoutineName" header="Routine"/>
<column colName="CursorName" header="Cursor"/>
<column colName="ImportSchema" hidden="true"/>
<column colName="RunCount" header="Run Count"/>
<column colName="AvgRows" header="Avg Rows"/>
<column colName="AvgGlobalRefs" header="Avg Global Refs"/>
<column colName="AvgCommands" header="Avg Commands"/>
<column colName="AvgDiskWait" header="Avg Disk Wait"/>
<column colName="AvgTime" header="Avg Time"/>
<column colName="Details" hidden="true"/>
<column colName="QueryText" header="SQL Statement" OnDrawCell="DrawQueryText" />
<parameter id="namespace" value=""/>
</tablePane>
</group>
</vgroup>
<spacer width="5"/>
<vgroup id="propertyPane" hidden="true" valign="top">
<html id="propertyTitle" OnDrawContent="DrawDetailsTitle"></html>

<html>
<div id="statsTitle" class="mt-20 qp-header qp-query-text-header">stats title</div>
</html>
<tablePane id="tableDetails"
queryClass="%SYS.PTools.StatsSQL"
queryName="ViewStatsSQLDetails"
cellSpacing="1"
dataSource="columns"
fixedHeaders="false"
multiSelect="false"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="QueryText"
useSnapshot="true"
initialExecute="false"
>
<column colName="QueryText" hidden="true"/>
<column colName="RunCount" header="Run Count"/>
<column colName="ModuleName" header="Module Name"/>
<column colName="AvgModCount" header="Avg Module Exec Count"/>
<column colName="AvgRows" header="Avg Rows"/>
<column colName="AvgGlobalRefs" header="Avg Global Refs"/>
<column colName="AvgCommands" header="Avg Commands"/>
<column colName="AvgDiskWait" header="Avg Disk Wait"/>
<column colName="AvgTime" header="Avg Time"/>

<parameter value=""/>
<parameter value=""/>
</tablePane>
<iframe id="outputShowplan3" valign="top" containerStyle="padding-top:10px;" hidden="true"/>

</vgroup>

</hgroup>
</group> <!-- End of Page3 -->
</group>  <!-- End of Group below tab -->
</vgroup>  <!-- End of groupContent -->

</pane>
}

/// Write upto 80 characters of query statement in tablePane
Method DrawQueryText(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	
	#; Draw query text upto 80 characters.
	If $G(%query(pName)) '= "" {
		Set tCursorName = $zconvert($zconvert($G(%query("CursorName")),"O","JS"),"O","HTML")
		Set tRoutineName = $zconvert($zconvert($G(%query("RoutineName")),"O","JS"),"O","HTML")
		Set tText = $E(%query(pName),1,80) _ $S($L(%query(pName))>80:"...",1:"")	
		&html<<a href="javascript:zenPage.openDetails('#(tCursorName)#','#(tRoutineName)#')">#(..EscapeHTML(tText))#>
	}
	Quit $$$OK
}

/// This client event, if present, is fired when the page is loaded.
/// Enable the first tab and disable the rest.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
	var json = zen('jsonSettingsInfo').getContentObject();
	this._settingsInfo = json;
	var msg = '';
	if (json.error) {
		msg = json.error;
		// foundemental error occurred getting settings data, page cannot continue, so display error then go back home.
		alert(json.error);
		window.location.href = this.homePage;
		return;
	}
	var proxy = this.getSettingMessages(json);
	if (proxy.msg) {
		var htmlCurrentSettings = document.getElementById("htmlCurrentSettings");
		htmlCurrentSettings.innerHTML = proxy.msg;
	}
	var initalTab = 0;
	if (this.openTab != '') {
		initalTab = this.openTab;
	}
	this.tabChanged(initalTab);
	zen("tabBar").setProperty("selectedIndex",initalTab);
	zen("content").setHidden(false);
	document.getElementById("QueryTestDesc").innerHTML = '<h3>'+zenText("QueryTestDesc")+'</h3>';
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	// these are the largest sizes for the iframe to be without triggering IE/FF/Chrome to create the browser's scroll bars.
	// do not change without testing on all three browsers.
	var wd = zenGetWindowWidth() - ((zenIsIE)?60:65);
	var ht = zenGetWindowHeight() - ((zenIsIE)?250:190);
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	zen("svgTabArea").setProperty("width",wd);
	zen("tabBar").setProperty("width",wd);
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
	
		this.adjustSizes();	
	
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
		var editDiv = zen('editorPane').getEnclosingDiv();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 100;
		var tabBodyHgt = (hgt - 30);
		tabBodyHgt = (tabBodyHgt < 141 ? 141 : tabBodyHgt);
		editDiv.style.height = tabBodyHgt - 40 + 'px';
		
		var frame = zen("outputShowplan");
		var frameWidth = winWidth - 100;
		var frameHeight = tabBodyHgt - 180;

		frameWidth = Math.max(frameWidth,100);
		frame.setProperty("width",frameWidth + "px");
		frameHeight = Math.max(frameHeight,100);
		frame.setProperty("height",frameHeight +"px");
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

ClientMethod doHistory() [ Language = javascript ]
{
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
	zen("QueryText").focus();
}

ClientMethod doPurgeQuery() [ Language = javascript ]
{
	if (!confirm($$$Text("Are you sure you want to purge all cached queries in this namespace?"))) return;
	var proxy = this.PurgeQuery(this.NAMESPACE);
	this.showMsg(proxy.msg,2);
	zenPage.doView();
}

ClientMethod doPurgeStats() [ Language = javascript ]
{
	if (!confirm($$$Text("Are you sure you want to purge all stats in this namespace?"))) return;
	var proxy = this.PurgeStats(this.NAMESPACE);
	if (proxy.error) {
		this.showMsg(proxy.error,1);
	} else {
		this.showMsg(proxy.msg,2);
	}
	zenPage.doView();
}

ClientMethod doShowPlan() [ Language = javascript ]
{
	var query = zen("QueryText").getValue();
	if(zenTrim(query)==='') {
		alert($$$Text("Please enter a query!"));
		zen("QueryText").focus();
		return false;
	};
	zen("idHistory").setHidden(true);
	zen("outputShowplan").setHidden(false);
	var chkBackground = ((zen("chkBackground").getValue()==true)) ? 1 : 0;
	var status = this.PrepareShowPlan(query);
	if (!chkBackground) {
		var planlink = this.PlanPage + "?namespace="+encodeURIComponent(this.NAMESPACE)+"&stats=1&verbose=1";
		zen('outputShowplan').setProperty('src',planlink);
		zen('outputShowplan').setHidden(false);
	} else {
		// start process in background
		// display background status 
		this.toggleFields(true);
		delete this._jobNumber;
		var planlink = this.ShowPlanOutput + "?namespace="+encodeURIComponent(this.NAMESPACE);
		zen('outputShowplan').setProperty('src',planlink);
		var proxy = this.JobShowPlan(query);
		this._proxy = proxy;
		if (proxy.jobNumber) {
			// start timer to check status
			// if background process is finished, display result
			this._jobNumber = proxy.jobNumber;
			var output = zen('outputShowplan');
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

ClientMethod toggleFields(hideflag) [ Language = javascript ]
{
	zen("btnShowPlan").setHidden(hideflag);
	zen("btnShowHistory").setHidden(hideflag);
	zen("btnViewProcess").setHidden(!hideflag);
	zen('QueryText').setDisabled(hideflag);
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
			zen('outputShowplan').setHidden(false);
			if (this._proxy) {
				var planlink = this.ShowPlanOutput + "?Username="+encodeURIComponent(this._proxy.Username)+"&NAMESPACE="+encodeURIComponent(this.NAMESPACE)+"&jobNumber="+this._jobNumber;
				planlink += "&status=" + proxy.status + "&msg=" + proxy.msg;
				zen('outputShowplan').setProperty('src',planlink);				
			}
			var timer = zen('timer');
			timer.setProperty('timeout',4000);
			timer.startTimer();
			break;
		case 'done':
		case 'error':
		case 'terminated':
			if (this._proxy) {
				var planlink = this.ShowPlanOutput + "?Username="+encodeURIComponent(this._proxy.Username)+"&NAMESPACE="+encodeURIComponent(this.NAMESPACE)+"&jobNumber="+this._jobNumber;
				planlink += "&status=" + proxy.status + "&msg=" + proxy.msg;
				zen('outputShowplan').setProperty('src',planlink);
				delete this._jobNumber;
			} else {
				alert('cannot find this_proxy -- unable to continue.');
			}
			this.toggleFields(false);
			break;
	}
}

ClientMethod doSelectRow(cursorName, routineName) [ Language = javascript ]
{
	zen('outputShowplan3').setHidden(false);

	var query = this.GetQueryText(this.NAMESPACE,routineName,cursorName,0);
	var schema = this.GetImportSchema(this.NAMESPACE,routineName,cursorName,1);
	var id = routineName+"||"+cursorName;
	var status = this.PrepareShowPlan(query,schema,id);
	var planlink = this.PlanPage + "?namespace="+encodeURIComponent(this.NAMESPACE)+"&stats=2&verbose=1";
	zen('outputShowplan3').setProperty('src',planlink);
	return;
}

ClientMethod openDetails(cursorName, routineName) [ Language = javascript ]
{
	url = this.OpenDetailsPage + '$NAMESPACE=' + encodeURIComponent(this.NAMESPACE) + '&CursorName=' + encodeURIComponent(cursorName) + '&RoutineName=' + encodeURIComponent(routineName);
	var win = window.open(url,'ViewStatsDetails');
	win.focus();
}

ClientMethod doSettings() [ Language = javascript ]
{
	zenLaunchPopupWindow('%CSP.UI.Portal.SQL.QButtons.RuntimeStatsSettings.zen','RuntimeSettings','status,scrollbars,resizable=yes,width=950,height=800');
}

ClientMethod doView() [ Language = javascript ]
{
	var table = zen("table");
	table.parameters[0].value = this.NAMESPACE;
	table.executeQuery();
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	var option;
	for ( var i=0; i<3; i++ ) {
		option = i + 1;
		if ( i == index ) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}				
	}
	zen("tableDetails").setHidden(true);
	if (index == 2) {
		this.doView();
	} else {
		if (index == 1) {
			zen("QueryText").focus();
		}
	}
	return;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$TextHTML("Use this tool to collect and view SQL runtime performance details on SQL Runtime Statistics.")
	
	Set %page.NAMESPACE = $G(%request.Data("$NAMESPACE",1))
	If %page.NAMESPACE = "" Set %page.NAMESPACE = $namespace
	Set %page.PlanPage = $P(..Link("%25SQL.Manager.ShowPlan.cls"),"?$NAMESPACE",1)
	Set %page.ShowPlanOutput = $P(..Link("%25CSP.UI.Portal.SQL.QButtons.ShowPlanOutput.zen"),"?$NAMESPACE",1)
	If ..Filter = "*",$G($$$IRISTempMgt($Username,..%GetPageName(),"TableNavState"))="" Set ..Filter=""

	If %page.openTab = 1 {
		// get the statement from %session
		Set ..%GetComponentById("QueryText").value = %session.Data($Username,"SQL","StatementText")	
	}
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSQL",$$$Text("SQL Home"),$$$Text("Goto the SQL Home page"),"zenPage.gotoPToolsPage('sqlhome');")
	Set pCommands(2) = $LB("btnPurgeQuery",$$$Text("Purge Cached Queries"),$$$Text("Purge cached queries in this namespace"),"zenPage.doPurgeQuery();")
	Set pCommands(3) = $LB("btnPurgeStats",$$$Text("Purge Stats"),$$$Text("Purge stats in this namespace"),"zenPage.doPurgeStats();")
	Set pCommands(4) = $LB("btnViewStats",$$$Text("SQL Index Analyzer"),$$$Text("Goto the Index Analyzer page"),"zenPage.gotoPToolsPage('indexanalyzer');")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("SQL Runtime Statistics")
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

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return;
	switch(popupName) {
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value,"%25CSP.UI.Portal.SQL.QButtons.RuntimeStats.zen");
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	case 'Details':
		break;
	case 'RuntimeSettings':
		self.document.location.reload();
	}
}

/// Draw html for details title: Routine name and Query text
Method DrawDetailsTitle(pData) As %Status
{
	If pData = "" Quit $$$OK
	set pNamespace=$p(pData,"^",1)
	set pRoutine=$p(pData,"^",2)
	set pCursor=$p(pData,"^",3)
	set QueryText=..GetQueryText(pNamespace,pRoutine,pCursor,0)
	&html<<h4>#($$$FormatText($$$Text("Routine: %1"),$zconvert(pRoutine,"O","HTML")))#</h4>>
 	&html<<div class="qp-header qp-query-text-header">#($$$TextHTML("SQL Statement"))#</div>>
 	&html<<div class="qp-query-text-body"><pre>>
	if $LV(QueryText) { for pos=1:1:$LL(QueryText) &html<#($zconvert($LG(QueryText,pos),"O","HTML"))#<br/>> }
	else { &html<#(..EscapeHTML(QueryText))#> }
	&html<</pre></div>>
	Quit $$$OK
}

/// Return server info per View Stats. 
Method GetSettingsInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.SQL.QButtons.Utils).GetSettingsData(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
	Set pResources("statementTitle") = $$$TextHTML("SQL Statement")
	Set pResources("statsTitle") = $$$TextHTML("Query Statistics")
	Set pResources("QueryTestDesc") = $$$TextHTML("The query entered below will be executed to generate SQL Stats and then the Show Plan will be displayed:")

	Quit $$$OK
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (this._jobNumber) {
		// remind user
		return $$$Text("The background process is still running...");
	}
}

/// This method clears Stats in the current namespace.
/// Returns the number of Stats deleted from the '%SYS.PTools.Stats' class;
/// Otherwise, returns an error message if an error occurred.
ClassMethod PurgeStats(pNamespace) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.error = ""
	Set proxy.msg = $$$TextHTML("Nothing to purge.")
	Set tSC = ##class(%SYS.PTools.StatsSQL).clearStatsSQL(pNamespace,,,1,,1)
	If tSC > 0 {
		Set proxy.msg = $$$FormatText($$$Text("Purge stats completed successfully. %1 stats purged."),tSC)
	} Else {
		If ((tSC '= 0) && ($$$ISERR(tSC))) {
			Set proxy.error = $$$FormatText($$$Text("Error occurred while purging stats: %1"),$System.Status.GetErrorText(tSC))
		}
	}
	Quit proxy
}

}
