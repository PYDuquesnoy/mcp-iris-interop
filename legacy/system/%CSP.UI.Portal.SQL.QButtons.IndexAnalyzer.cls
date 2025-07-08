/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - SQL Performance Tool
Class %CSP.UI.Portal.SQL.QButtons.IndexAnalyzer Extends (%CSP.UI.Template.Property, %CSP.UI.Portal.UtilsNav, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

Parameter RESOURCE = "%Development:USE";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.IndexAnalyzer.zen";

Parameter HELPADDRESS = "Home,SQL Index Analyzer";

Property PlanPage As %String;

Property gatherStatus As %Boolean;

Property dots As %String;

/// Displayed name of this page.
Parameter PAGENAME = "SQL.QButtons.IndexAnalyzer";

Property msgGather As %ZEN.Datatype.string [ InitialExpression = {$$$TextJS("Gathering SQL statements ...")} ];

Property QUERYNAME As %ZEN.Datatype.string [ InitialExpression = "indexUsage" ];

Property SCHEMANAME As %ZEN.Datatype.string;

Property ShowPlanOutput As %ZEN.Datatype.string [ InitialExpression = {$P(..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.ShowPlanOutput.zen"),"?$NAMESPACE",1)} ];

Property RuntimePage As %ZEN.Datatype.string [ InitialExpression = {..Link("%25CSP.UI.Portal.SQL.QButtons.RuntimeStats.zen")} ];

Property iTimeoutInterval As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

/// Whether to include System items (0=Not to include; 1=Include; this flag is used by "%SQL.Manager.Catalog:Schemas" which is opposite of the SkipSys on the UI)
Property SYSTEMFLAG As %Integer [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
.EditForm {
	width: 800px;	
}
TABLE.DetailTable	{ 
	border: 1px solid #ccc;
	border-radius: 2.5px;
	background: white;
}
TABLE.DetailTable TH { 
	background:#337ab7; color: white;
	text-align: center;
	padding:4px;
}
TABLE.DetailTable TR.OddRow { background: white; }
TABLE.DetailTable TR.EvenRow { background: #eeeeee; }
.sectionLabel {
	color: #546076;
	padding-top: 2px;
}
.ml20 {
	margin-left:20px;
}
.mt10 {
	margin-top: 10px;	
}
.commandButton {
	width:300px;
}
.commandButtonDisabled {
	width:300px;
}
/* @doc="Input box of data combobox. Changed color for this page. (to be the same as SQL Home)" */
.comboboxInput {
	border-top: 1px solid #ABABAB;
	border-bottom: 1px solid #ABABAB;
	border-left: 1px solid #ABABAB;
}
/* @doc="Image button in data combobox. Changed color for this page." */
.comboboxImgButton {
	border-top: 1px solid #ABABAB;
	border-bottom: 1px solid #ABABAB;
	border-right: 1px solid #ABABAB;
	/* attempt to scale button with text */
	width: 1.3em;
	height: 1.4em;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" enclosingClass="ml20"/>
<timer id="gatherStatementTimer" timeout="0" ontimeout="zenPage.checkStatus();" />
<timer id="reportTimer" timeout="0" ontimeout="zenPage.checkReportStatus();" />
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>
<jsonProvider id="jsonQueryInfo" OnGetTargetObject="GetQueryProperties">
 </jsonProvider>
 
<vgroup id="groupContent" groupClass="mt10 ml20" cellVAlign="top">
<label id="idRespond" enclosingClass="note" value="" hidden="true"/>
<vgroup enclosingClass="mt10">
<html id="htmlSQLStatements" label="SQL Statement Count" labelClass="caption sectionLabel" OnDrawContent="DrawSQLStatements"/>
</vgroup>
<spacer height="10"/>
<group enclosingClass="EditForm" label="Report Options" labelClass="caption sectionLabel">
<vgroup enclosingStyle="padding:10px 10px 10px 14px">
<group labelPosition="left" valign="middle">
<dataCombo id="schemaSelection" label="Schema selection"
queryClass="%SQL.Manager.Catalog" queryName="Schemas" showEmpty="true" 
multiColumn="true" dropdownWidth="500px" size="30"
displayColumns="1"
choiceColumn="1"
valueColumn="1"
maxRows="0"
OnExecuteResultSet="ListSchemas"
title="Select an existing schema for filtering."
onchange="zenPage.schemaSort(zenThis.value);"
 >
 <parameter value="0"/>
</dataCombo>
</group>
<checkbox id="chkSkipSys" caption="Skip all system classes and routines that start with: { % | DeepSee | Ens | HS | INFORMATION.SCHEMA }" 
captionClass="caption" value=""
hint="This option applies to 'Gather SQL Statements' and all analyzer reports below"
hintClass="zenHint ml20"
onchange="zenPage.clearOptionData(1);" containerStyle="padding-top:6px;" />

<checkbox id="chkSkipInsStmts" caption="Skip INSERT statements, as they don't have looping logic" 
captionClass="caption" value=""
hint="This option applies to 'Gather SQL Statements' and all analyzer reports below"
hintClass="zenHint ml20"
onchange="zenPage.clearOptionData();" 
containerStyle="padding-top:6px;" />

<checkbox id="chkSkipIDKeys" caption="Skip all indices that will be used to form Object Identity value (IDKEY) for a given class" 
captionClass="caption" value=""
hint="This option only applies to the 'Index Usage' report"
hintClass="zenHint ml20"
onchange="zenPage.clearOptionData();" 
containerStyle="padding-top:6px;" /> 

</vgroup>

<group enclosingClass="mt10">
<hgroup enclosingClass="ml20">
<group cellStyle="padding: 3px 4px 3px 0;">
<button id="command_button_5" caption="Reset" controlClass="commandButton" title="Reset report options to defaults" onclick="zenPage.resetToDefaults();"/>
<button id="command_button_1" caption="Queries with Table Scans" controlClass="commandButton" onclick="zenPage.startReportOption('1');"/>
<button id="command_button_2" caption="Queries with Temp Indices" controlClass="commandButton" onclick="zenPage.startReportOption('2');"/>
</group>
<group cellStyle="padding: 3px 4px 3px 0;">
<button id="command_button_0" caption="Index Usage" controlClass="commandButton" onclick="zenPage.startReportOption('0');"/>
<button id="command_button_3" caption="Queries with Missing JOIN Indices" controlClass="commandButton" onclick="zenPage.startReportOption('3');"/>
<button id="command_button_4" caption="Queries with Outlier Indices" controlClass="commandButton" onclick="zenPage.startReportOption('4');"/>
</group>
</hgroup>
</group>
<spacer height="8"/>
</group>

<vgroup id="groupResult" hidden="true">
<label id="gatherStatus" controlClass="rednote"/>
<vgroup id="tableGroup" >
<tablePane id="table" label="" labelClass="caption sectionLabel"
queryClass="%SYS.PTools.UtilSQLAnalysis"
queryName="indexUsage"
cellSpacing="1"
dataSource="query"
fixedHeaders="false"
multiSelect="false"
pageSize="0"
maxRows="10000"
showValueInTooltip="false"
showZebra="true"
useSnapshot="true"
initialExecute="false"
OnCreateResultSet="CreateRS"
OnExecuteResultSet="ExecuteRS"
>
<parameter id="schemaname"/>
<column colName="Index Fields" OnDrawCell="DrawUpto40Text" />
<column colName="Data Fields" OnDrawCell="DrawUpto40Text" />
<column id="showSQLText" colName="SQL Text" header="SQL Statement" OnDrawCell="DrawQueryText" />
</tablePane>
</vgroup>

<iframe id="outputShowplan" hidden="true" valign="top" containerStyle="padding:10px 10px 10px 20px;"/>

</vgroup>
</vgroup>

</pane>
}

/// User clicked a Query Text row. We will job off the show plan process in the background and start timer.
ClientMethod doSelectRow() [ Language = javascript ]
{
	this.resetMsg();
	var table = zenPage.getComponentById("table");
	var selectedIndex = table.getProperty("selectedIndex");
	var rowData = table.getRowData(selectedIndex);
	if (rowData && rowData["SQL Text"] != "") {
		var query = rowData["SQL Text"];
		this.toggleButtons('disable');
		zen("outputShowplan").setHidden(false);
		delete this._jobNumber;
		var planlink = this.ShowPlanOutput + "?namespace="+encodeURIComponent(this.NAMESPACE);
		zen('outputShowplan').setProperty('src',planlink);
		// scroll to the bottom of the window so user can see the showplan frame
		window.scrollTo(20,document.body.scrollHeight);
		var proxy = this.JobShowPlan(query);
		this._proxy = proxy;
		if (proxy.jobNumber) {
			// start timer to check status
			// if background process is finished, display result
			this._jobNumber = proxy.jobNumber;
			var output = zen('outputShowplan');
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
		} else {
			if (proxy.error) {
				alert(proxy.error);	
			}	
		}
	}
	return;
}

/// Show Plan timeout function
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
				planlink += "&status=" + encodeURIComponent(proxy.status) + "&msg=" + encodeURIComponent(proxy.msg);
				zen('outputShowplan').setProperty('src',planlink);				
			}
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
			break;
		case 'done':
		case 'error':
		case 'terminated':
			if (this._proxy) {
				var planlink = this.ShowPlanOutput + "?Username="+encodeURIComponent(this._proxy.Username)+"&NAMESPACE="+encodeURIComponent(this.NAMESPACE)+"&jobNumber="+this._jobNumber;
				planlink += "&status=" + encodeURIComponent(proxy.status) + "&msg=" + encodeURIComponent(proxy.msg);
				zen('outputShowplan').setProperty('src',planlink);
				delete this._jobNumber;
			} else {
				alert('cannot find this_proxy -- unable to continue.');
			}
			this.toggleButtons('enable');
			break;
	}
}

ClientMethod resetToDefaults() [ Language = javascript ]
{
	this.resetMsg();
	zen('chkSkipSys').setValue(1);
	zen('chkSkipIDKeys').setValue(1);
	zen('chkSkipInsStmts').setValue(1);
	zen('schemaSelection').setValue('');
	this.SaveLast(1,1,1,'');
}

/// Write upto 80 characters of query statement in tablePane
Method DrawQueryText(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	
	#; Draw query text upto 80 characters.
	If $G(%query(pName)) '= "" {
		Set tText = $E(%query(pName),1,80) _ $S($L(%query(pName))>80:"...",1:"")
		&html<&nbsp;<a href="javascript:zenPage.doSelectRow();">#($zconvert(tText,"O","HTML"))#>
	}
	Quit $$$OK
}

/// user checked/unchecked a "skip" checkbox. hide existing table and save the selection.
ClientMethod clearOptionData(skipSysChanged) [ Language = javascript ]
{
	var ok = this.clearSQLAnalysisDB();
	zen('groupResult').setHidden(true);
	zen("outputShowplan").setHidden(true);
	this.saveLastValues();
	if (skipSysChanged) {
		zen('schemaSelection').clearCache();
		zen('schemaSelection').setValue('');
		this.SYSTEMFLAG = zen("chkSkipSys").getValue() ? 0 : 1;
	}
}

/// user selected a schema option. update the table with selected schema and save the selection.
ClientMethod schemaSort(schema) [ Language = javascript ]
{
	this.SCHEMANAME = schema;
	zen("schemaname").value = schema;
	if (!zen('groupResult').getProperty('hidden')) {
		zen("table").executeQuery();
	}
	this.saveLastValues();
}

/// Invoke method to gather SQL Statements and update SQL Statement Count table. During this time, disable the rasio buttons.
ClientMethod startButtonGather() [ Language = javascript ]
{
	this.resetMsg();
	var json = this._queryInfo;
	this.showMsg(json.msgStatementInprogress,1);
	var ok = this.clearSQLStatements();
	this.refreshStatementTable();
	var skipSys = zen("chkSkipSys").getValue();
	var skipInsStmts = zen("chkSkipInsStmts").getValue();
	skipSys = skipSys ? 1 : 0;
	skipInsStmts = skipInsStmts ? 1 : 0;
	var ok = this.GatherStatements(skipSys,skipInsStmts);
	if (ok) {
		this.toggleButtons('disable');
		zen("outputShowplan").setHidden(true);
	}
	zen('gatherStatementTimer').setProperty('timeout',this.iTimeoutInterval);
	zen('gatherStatementTimer').startTimer();
}

/// Timeout Method used by the statement gathering timer
ClientMethod checkStatus() [ Language = javascript ]
{
	if (zen('gatherStatementTimer').timer == 0) {
		return;	
	}
	var json = this._queryInfo;
	var string = json.msgStatementInprogress;
	var status = zenPage.CheckButtonStatus();
	if (status == 0) {
		this.dots += ".";
		string += this.dots;
		zen('gatherStatementTimer').startTimer();	
	} else {
		string = "Done";
		zen('gatherStatementTimer').clearTimer();
	}
	this.refreshButton(string);
}

/// this method is used  to see if a server side query is done yet.
/// you can only run one thing at a time so we reuse the same lock to test
Method CheckButtonStatus() As %Boolean [ ZenMethod ]
{
	
	Lock +^%sqlcq($NAMESPACE,"PTools","util","SQLStmts"):1
	Set status = $T
	If status = 0 {
	}
	Else {
		Lock -^%sqlcq($NAMESPACE,"PTools","util","SQLStmts")
	}	
	QUIT status
}

/// Method used by the statement gathering timer
ClientMethod refreshButton(string) [ Language = javascript ]
{
	if (string == "Done") {
		this.toggleButtons('enable');
		var json = this._queryInfo;
		string = json.msgStatementDone;
		this.showMsg(string,2);
	} else {
		this.showMsg(string,1);
	}
	this.refreshStatementTable();
}

/// Timeout Method used by the report timer
ClientMethod checkReportStatus() [ Language = javascript ]
{
	if (zen('reportTimer').timer == 0) {
		return;	
	}
	var json = this._queryInfo;
	var string = json.msgInprogress;
	var status = zenPage.CheckOptionStatus();
	if (status == 0) {
		this.dots += ".";
		string += this.dots;
		zen('reportTimer').startTimer();	
	} else {
		string = "Done";
		zen('reportTimer').clearTimer();
		this.refreshStatementTable();
	}
	this.refreshOption(string);
}

ClientMethod refreshStatementTable() [ Language = javascript ]
{
	var html = zen("htmlSQLStatements");
	html.refreshContents();
}

ClientMethod startReportOption(newOption) [ Language = javascript ]
{
	this.resetMsg();	
	var json = this._queryInfo;
	zen("groupResult").setHidden(false);
	zen("gatherStatus").setValue(json.msgInprogress);
	zen("gatherStatus").setProperty("controlClass", "rednote");
	var schema = zen("schemaSelection").getValue();
	var skipSys = zen("chkSkipSys").getValue();
	var skipIDkeys = zen("chkSkipIDKeys").getValue();
	var skipIns = zen("chkSkipInsStmts").getValue();
	skipSys = skipSys ? 1 : 0;
	skipIDkeys = skipIDkeys ? 1 : 0;
	skipIns = skipIns ? 1 : 0;
	zen("table").setProperty("currColumn",'');
	var ok = this.PrepareAnalysis(newOption,skipSys,skipIDkeys,skipIns,schema);
	if (ok) {
		this.dots = '';
		this.toggleButtons('disable');
		this.endReportOption(newOption);
		zen("outputShowplan").setHidden(true);
		zen('reportTimer').setProperty('timeout',this.iTimeoutInterval);
		zen('reportTimer').startTimer();
	}
}

/// Prepare to refresh the result table - update query name based on the option selected
ClientMethod endReportOption(newOption) [ Language = javascript ]
{
	var json = this._queryInfo;
	if (json && json.reportOptions) {
		var options = json.reportOptions;	
	} else {
		// this should never happen!
		alert('Unexpected error: queryList does not exist!');
		return;	
	}
	var table = zen("table");
	var index = parseInt(newOption);
	var option = options[index];
	var queryName = option.queryName;
	var title = option.caption;
	zen("showSQLText").setProperty("hidden",index==0);	
	this.QUERYNAME = queryName;
	table.setProperty("label",title);
	table.executeQuery(0);
	table.setHidden(false);
}

/// Save User's report options to server. This is saved per username per namespace so the next time you come into this page your previous selections will become defaults.
ClientMethod saveLastValues() [ Language = javascript ]
{
	var schema = zen("schemaSelection").getValue();
	var skipSys = zen("chkSkipSys").getValue();
	var skipIDkeys = zen("chkSkipIDKeys").getValue();
	var skipIns = zen("chkSkipInsStmts").getValue();
	skipSys = skipSys ? 1 : 0;
	skipIDkeys = skipIDkeys ? 1 : 0;
	skipIns = skipIns ? 1 : 0;
	this.SaveLast(skipSys,skipIDkeys,skipIns,schema);
}

/// diable or enable action buttons on this page
ClientMethod toggleButtons(flag) [ Language = javascript ]
{
	var buttonClass = (flag == 'disable') ? 'commandButtonDisabled' : 'commandButton';
	for (var n=0; n<6; n++) {
		zenSetProp('command_button_'+n,'controlClass',buttonClass);
	}
	if (flag == 'enable') {
		this.enableCommandButton('btnGather');
		this.enableCommandButton('btnRuntime');
		this.enableCommandButton('btnPurgeStatement');
		this.enableCommandButton('btnPurgeData');
	} else {
		this.disableCommandButton('btnGather');
		this.disableCommandButton('btnRuntime');
		this.disableCommandButton('btnPurgeStatement');
		this.disableCommandButton('btnPurgeData');
	}
	var disabled = (flag=='disable');
	zen('schemaSelection').setDisabled(disabled);
	zen('chkSkipSys').setDisabled(disabled);
	zen('chkSkipInsStmts').setDisabled(disabled);
	zen('chkSkipIDKeys').setDisabled(disabled);
}

ClientMethod doPurgeStats(purgeType) [ Language = javascript ]
{
	var msg = (purgeType=='data') ? $$$Text("Are you sure you want to purge all analytical data collected in this namespace?") : $$$Text("Are you sure you want to purge all SQL statements collected for anaylysis in this namespace?");
	if (!confirm(msg)) return;
	var proxy = this.PurgeStats(this.NAMESPACE,purgeType);
	if (proxy.error) {
		this.showMsg(proxy.error,1);	
	} else {
		this.showMsg(proxy.msg,2);
		if (purgeType == 'statement') {
			this.refreshStatementTable();
		} else {
			var table = zen('table');
			table.executeQuery(0);
			zen("gatherStatus").setValue('');
		}
	}
	zenPage.doView();
}

/// This method is used to see if a server side query is done yet.
/// you can only run one thing at a time so we reuse the same lock to test
Method CheckOptionStatus() As %Status [ ZenMethod ]
{
	
	LOCK +^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys"):1
	Set status = $T
	
	If status = 0 {
	}
	Else {
		LOCK -^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys")		
	}	
	QUIT status
}

ClientMethod refreshOption(string) [ Language = javascript ]
{
	var json = this._queryInfo;
	if (string == "Done") {
		this.toggleButtons('enable');
		zen("gatherStatus").setProperty("controlClass", "greennote");
		string = json.msgDone;
	}
	zen("gatherStatus").setValue(string);
 	var table = zen("table");
	table.executeQuery(0);
	table.setHidden(false);
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.adjustSizes();
	var json = zen('jsonQueryInfo').getContentObject();
	if (json.error) {
		msg = json.error;
		this.showMsg(json.error,true);
		return;
	}
	this._queryInfo = json;
	zen('chkSkipSys').setValue(json.skipSysObj);
	zen('chkSkipIDKeys').setValue(json.skipIDkeys);
	zen('chkSkipInsStmts').setValue(json.skipInsStmts);
	zen('schemaSelection').setValue(json.schema);
	this.SCHEMANAME = json.schema;
	if (this._jobNumber) {
		// remind user
		return $$$Text("The background process for Show Plan is still running...");
	}
}

ClientMethod adjustSizes() [ Language = javascript ]
{

	try {
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var frameHeight = 300;
		var frameWidth = winWidth - 100;	
		var frame = zen("outputShowplan");
		
		frameHeight = Math.max(frameHeight,100);
		frame.setProperty("height",frameHeight +"px");
		frame.setProperty("width",frameWidth +"px");

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()

	Set %page.NAMESPACE = $G(%request.Data("$NAMESPACE",1))
	If %page.NAMESPACE = "" Set %page.NAMESPACE = $namespace
	
	Set ..%GetComponentById("Text1").value = $$$Text("Use options on this page to review various index analyzer reports.")
	
	Set %page.PlanPage = $P(..Link("%25SQL.Manager.ShowPlan.cls"),"?$NAMESPACE",1)
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
	Set pCommands(2) = $LB("btnGather",$$$Text("Gather SQL Statements"),$$$Text("Start gathering SQL statements for this namespace"),"zenPage.startButtonGather();")
	Set pCommands(3) = $LB("btnPurgeStatement",$$$Text("Purge Statements"),$$$Text("Purge SQL statements collected for stats in this namespace"),"zenPage.doPurgeStats('statement');")
	Set pCommands(4) = $LB("btnPurgeData",$$$Text("Purge Stats Data"),$$$Text("Purge analytical data collected in this namespace"),"zenPage.doPurgeStats('data');")
	Set pCommands(5) = $LB("btnRuntime",$$$Text("View Runtime Statistics"),$$$Text("Goto the 'View Stats' tab on the SQL Runtime Statistics page"),"zenPage.gotoPToolsPage('runtime');")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("SQL Index Analyzer")
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
		var url = zenPage.GetNewURL(value,"%25CSP.UI.Portal.SQL.QButtons.IndexAnalyzer.zen");
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	case 'Details':
		break;
	}
}

/// Draw html for details title: Routine name and Query text
Method DrawDetailsTitle(pSeed) As %Status
{
	&html<<h4>#($$$Text("Use this page to display various index analyzer report."))#</h4>>
	Quit $$$OK
}

ClassMethod clearSQLAnalysisDB() As %Status [ ZenMethod ]
{
	QUIT ##class(%SYS.PTools.UtilSQLAnalysis).clearSQLAnalysisDB()
}

ClassMethod clearSQLStatements() As %Status [ ZenMethod ]
{
	Set status = ##class(%SYS.PTools.UtilSQLAnalysis).clearSQLStatements()
	Set status = ##class(%SYS.PTools.UtilSQLAnalysis).clearSQLAnalysisDB()
	QUIT $$$OK
}

Method GatherStatements(skipSysObj, skipInsStmts) As %Status [ ZenMethod ]
{
	Set ..dots=""
	//Set skipSysObj='skipsys  // Skip all System Object (Classes & Routines) that start with: { % | DeepSee | Ens | HS | INFORMATION.SCHEMA }
	
	job getAllSQLStmts^%SYS.PTools2(1,skipSysObj,skipInsStmts,0,0)
	//&js<zenPage.endButtonGather();>
	
	QUIT $$$OK
}

Method DrawSQLStatements(pSeed) As %Status
{
	Set tRS = ##class(%ResultSet).%New("%SYS.PTools.UtilSQLAnalysis:countSQLStmtTypes")
	Do tRS.Execute()
	Set hasCount = 0
	&html<<table class="DetailTable">
	<tr><th>#($$$TextHTML("Statement Type"))#</th><th>#($$$TextHTML("Count"))#</th>
	>
	Set tCount = 0
	While tRS.Next()
	{
		Set tCount = tCount + 1
		Set rowClass = $S(tCount#2:"EvenRow", 1:"OddRow")
		&html<<tr class='#(rowClass)#'><td class='DetailValue'>#($zconvert(tRS.GetData(1),"O","HTML"))#</td><td class='DetailValue'>#($zconvert(tRS.GetData(2),"O","HTML"))#</td></tr>>
		Set hasCount = 1
	}
	If 'hasCount {
		&html<<tr><td colspan="2" class='DetailValue'>#($$$TextHTML("(Note: No count available in this namespace. Click the 'Gather SQL Statements' button to get the statement count.)"))#</td></tr>> 
	}
	&html<</table>>
	Quit $$$OK
}

/// skipSysObj - Skip all System Object (Classes & Routines) that start with: { % | DeepSee | Ens | HS | INFORMATION.SCHEMA }
Method PrepareAnalysis(option, skipSysObj, skipIDkeys, skipInsStmts, schema) As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	Do ..SaveLast(skipSysObj, skipIDkeys, skipInsStmts, schema)
	Set getSQLStmts = 0
	If option = 0 {
		job indexUsage^%SYS.PTools2(1,1,getSQLStmts,skipSysObj,skipIDkeys,skipInsStmts,0)
	} ElseIf option = 1 {
		job tableScans^%SYS.PTools2(1,getSQLStmts,skipSysObj,skipInsStmts,0)
	} ElseIf option = 2 {
		job tempIndices^%SYS.PTools2(1,getSQLStmts,skipSysObj,skipInsStmts,0)
	} ElseIf option = 3 {
		job joinIndices^%SYS.PTools2(1,getSQLStmts,skipSysObj,skipInsStmts,0)
	} ElseIf option = 4 {
		job outlierIndices^%SYS.PTools2(1,getSQLStmts,skipSysObj,skipInsStmts,0)
	}
	QUIT tSC
}

Method SaveLast(skipSysObj, skipIDkeys, skipInsStmts, schema) [ ZenMethod ]
{
	Set $$$IRISTempMgt($UserName,..%GetPageName(),$Namespace) = $LB(skipSysObj, skipIDkeys, skipInsStmts, schema)
}

/// <var>pInfo</var> holds details on how to create the query.
Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pRS = ""
	Set Query = "%SYS.PTools.UtilSQLAnalysis:" _ %page.QUERYNAME
	Set pRS = ##class(%ResultSet).%New(Query)
	Quit pRS
}

/// Method for executing the process query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSC = pRS.Execute(%page.SCHEMANAME) 
	Quit tSC
}

Method GetQueryProperties(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.SQL.QButtons.Utils).GetIndexAnalyzerProperties(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
		/// Get default if it exists
		Set LastSaved = $G($$$IRISTempMgt($UserName,..%GetPageName(),$Namespace))
		If LastSaved = "" {
			Set LastSaved = $lb(1,1,1,"")
		}
		Set pObject.skipSysObj = $lg(LastSaved,1)
		Set pObject.skipIDkeys = $lg(LastSaved,2)
		Set pObject.skipInsStmts = $lg(LastSaved,3)
		Set pObject.schema = $lg(LastSaved,4)
		Set %page.SYSTEMFLAG = 'pObject.skipSysOb
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method clears Stats in the current namespace if user clicked the Purge Statements or Purge Data button.
/// Returns the number of Stats deleted from the '%SYS.PTools.Stats' class;
/// Otherwise, returns an error message if an error occurred.
ClassMethod PurgeStats(pNamespace, pPurteType) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.error = ""
	Set proxy.msg = ""
	If pPurteType = "statement" {
		Set tSC = ##class(%SYS.PTools.UtilSQLAnalysis).clearSQLStatements()
		If $$$ISOK(tSC) {
			Set proxy.msg = $$$TextHTML("Purge statements collected for stats completed successfully.")
		} Else {
			Set proxy.error = $$$FormatText($$$Text("Error occurred while purging SQL statements: %1"),$System.Status.GetErrorText(tSC))
		}
	} Else {
		Set tSC = ##class(%SYS.PTools.UtilSQLAnalysis).clearSQLAnalysisDB()
		If $$$ISOK(tSC) {
			Set proxy.msg = $$$TextHTML("Purge stats data completed successfully.")
		} Else {
			Set proxy.error = $$$FormatText($$$Text("Error occurred while purging stats data: %1"),$System.Status.GetErrorText(tSC))
		}
	}
	Quit proxy
}

/// Method for executing the query for list schemas.
Method ListSchemas(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	// If %page.SYSTEMFLAG is 0, then set filter to filter out Ens, DeepSee, and HS
	// If %page.SYSTEMFLAG is 1, then includes all items
	Set pFilter = $S(%page.SYSTEMFLAG=0:"'Ens*,'DeepSee*,'HS*",1:"")
	Set tSC = pRS.Execute(%page.SYSTEMFLAG,pFilter)
	Quit tSC
}

}
