/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Zen page for System Management Portal - Routines list
Class %CSP.UI.Portal.RoutineList Extends %CSP.UI.Template.List [ System = 4 ]
{

/// Allow to change namespaces for this page.
Parameter AUTONS As BOOLEAN = 1;

/// Displayed name of this page.
Parameter PAGENAME = "RoutineList";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.RoutineList.zen";

Parameter HELPADDRESS = "Home,Routines";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Development";

Property FILETYPE As %String [ InitialExpression = "Routine" ];

/// Actual spec that the query executed
Property ExecuteSpec As %String [ InitialExpression = "*.mac" ];

Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

Property FindPage As %String;

Property CurrentColumn As %ZEN.Datatype.string [ InitialExpression = "Name" ];

Property CurrentSort As %ZEN.Datatype.string [ InitialExpression = "asc" ];

/// Store translated targetCol linkCaption for <condition>
Property colCode As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Code")} ];

Property writePERMISSION As %ZEN.Datatype.boolean [ InitialExpression = {$System.Security.GetRoutinePermission($namespace)["WRITE"} ];

XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
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
<select id="selType" label="Look in:" valueList="Namespace,Database" showEmpty="false" value="Namespace" 
originalValue="Namespace" onchange="zenPage.doNamespace(1)"/>
<select id="selNamespace" showEmpty="false" onchange="zenPage.doNamespace(0);"/>
<html><hr size="1"/></html>
<label label="Include:" />
<checkbox id="chkShowSys" caption="System items" captionClass="optionLabel" title="Include % items" onclick="zenPage.doSearch();"/>
<checkbox id="chkShowGen" caption="Generated items" captionClass="optionLabel" title="Include generated items" onclick="zenPage.doSearch();"/>
<checkbox id="chkShowMap" caption="Mapped items" captionClass="optionLabel" title="Include mapped items" onclick="zenPage.doSearch();"/>
<html><hr size="1"/></html>
<label label="Filter:" />
<vgroup id="idOption" labelPosition="top" enclosingStyle="padding-bottom:10px;" cellStyle="padding-right:2px;padding-bottom:10px;valign=bottom;">
<dateText id="beginDate" label="Begin date (yyyy-mm-dd)" labelClass="optionLabel" hint="" hintClass="helpText" onchange="zenPage.doSearch();"/>
<dateText id="endDate" label="End date (yyyy-mm-dd)" labelClass="optionLabel" hint="" hintClass="helpText" onchange="zenPage.doSearch();"/>
<combobox id="txtSpec" label="Routine and Include files" labelClass="optionLabel" comboType="timer" editable="true" unrestricted="true" size="19"
dropdownWidth="190px"
title="Enter a search pattern. This can include * as a wildcard, a file extension from the list below, or ;* for automatically-saved backup files (such as *.int;*)." value="*.cls" onchange="zenPage.doSearch();"/>
<hgroup cellStyle="padding-right:3px;">
<link caption="*.mac" title="view macro routines" href="#" onclick="zenPage.doMask('*.mac');return false;"/>
<link caption="*.int" title="view intermediate routines" href="#" onclick="zenPage.doMask('*.int');return false;"/>
<link caption="*.inc" title="view include files" href="#" onclick="zenPage.doMask('*.inc');return false;"/>
<link caption="*.bas" title="view Basic files" href="#" onclick="zenPage.doMask('*.bas');return false;"/>
</hgroup>
<hgroup cellStyle="padding-right:3px;">
<link caption="*.mvb" title="view MultiValue Basic routines" href="#" onclick="zenPage.doMask('*.mvb');return false;"/>
<link caption="*.mvi" title="view MultiValue Basic intermediate routines" href="#" onclick="zenPage.doMask('*.mvi');return false;"/>
<link caption="*.obj" title="view object routines" href="#" onclick="zenPage.doMask('*.obj');return false;"/>
</hgroup>
<text id="maxRows" label="Maximum rows" labelClass="optionLabel" title="Maximum number of rows to load - cannot be greater than 10000" size="6" value="1000" onchange="zenPage.doSearch();" onkeyup="zenPage.keyUp(zenEvent);"/>
</vgroup>
</form>

</pane>
}

XData resultPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:2px">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<hgroup valign="top">
<vgroup valign="top">
<hgroup>
<tableNavBar showFilter="false" showPageSize="true" tablePaneId="table" 
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);"/>
<checkbox id="chkAlwaysFullView" caption="view code in new window" captionClass="optionLabel" onchange="zenPage.updatePreference();"
title="Check to always have full view of code in a separate window. Uncheck to quick view code on the right side."/>
</hgroup>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="%RoutineMgr"
queryName="StudioOpenDialog"
dataSource="columns"
fixedHeaders="false"
multiSelect="true"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
OnExecuteResultSet="ExecuteRS"
onselectrow="zenPage.doSelectRow(zenThis.getValue());"
>
<column colName="Name" header="Name" title="Routine name"/>
<column colName="Date" header="Date" title="Date/Time last modified"/>
<column colName="Size" header="Size" title="Routine size"/>
<column linkCaption="Code" link="javascript:zenPage.codeClicked();" />
<parameter id="tspec" value="*.mac"/>
<parameter id="tdir" value="1"/>
<parameter id="torderby" value="1"/>
<parameter id="tshowsys" value="0"/>
<parameter id="tflat" value="1"/>
<parameter id="tnotstudio" value="1"/>
<parameter id="tshowgen" value="0"/>
<parameter id="tfilter" />
<parameter id="troundtime" value="1"/>
<condition colName="Name" predicate="CONTAINS" value=".obj" cellStyle="disabled" targetCol="#(%page.colCode)#"/>  
</tablePane>
<label id="lblExecuteSpec" label="Search pattern executed: " labelClass="helpText" enclosingClass="helpText"/>
</vgroup>
<vgroup id="idCode" valign="top" hidden="true">
<hgroup id="idCodeOptions" cellAlign="even" width="99%">
<link caption="full_view" title="click here to view code in a separate window" href="javascript:zenPage.doFullView('');"/>
<checkbox id="chkAllowSelectRow" caption="show code when clicking on a row" captionClass="normal" onchange="zenPage.updatePreference();"/>
<image id="imageClear" src="csp/broker/deepsee/close_a_16.gif" width="12" height="12" onclick="zenPage.hideDoc();" title="close this view" valign="middle"/>
</hgroup>
<iframe id="output" valign="top"/>
</vgroup>
</hgroup>
</pane>
}

/// this method is called when user clicked the "Code" link. The value could not be passed with the correct escaping so we have to use the table value here.
ClientMethod codeClicked() [ Language = javascript ]
{
	var routineName = zen("table").getValue();
	this.doDoc(routineName);
}

ClientMethod hideDoc() [ Language = javascript ]
{
	zen("idCode").setHidden(true);
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		this.doSearch();
	}
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Routines")
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
		
	Set %page.lblTitle = ..%OnGetPageName()

	Set %page.ClassURL = $P(..Link("%25CSP.UI.Portal.ClassList.zen"),"?$NAMESPACE",1)
	Set %page.GlobalURL = $P(..Link("%25CSP.UI.Portal.GlobalList.zen"),"?$NAMESPACE",1)	
	Set %page.RoutineURL = $P(..Link("%25CSP.UI.Portal.RoutineList.zen"),"?$NAMESPACE",1)
	Set %page.DocPage = $P(..Link("%25CSP.UI.System.ViewCode.cls"),"?$NAMESPACE",1)
	Set %page.FindPage = $P(..Link("/csp/sys/exp/UtilExpFindReplace.csp"),"?$NAMESPACE",1)

	#; If $NAMESPACE is passed in, use that to determine what the selType is and which list to load.
	Set tNamespace = %page.NAMESPACE
	Set LastSearch = ..GetLastSearch()
	Set LastLookin = $P(LastSearch,"^",1)
	If tNamespace '= "" Set LastLookin = $S($E(tNamespace,1)="^":"Database",1:"Namespace")
	Set ..%GetComponentById("selType").value = LastLookin
	Set selNamespace = ..%GetComponentById("selNamespace")
	Set ..NamespaceList = ..GetNSList()
	Set DBList = ..GetDBList()
	If LastLookin = "Namespace" {
		Set selNamespace.valueList = ..NamespaceList
		Set selNamespace.value = $namespace
	} Else {
		#; use only displayList for display. When user selects a DB we will get the implied namespace from %session.
		Set selNamespace.valueList = DBList
		Set DBDir = tNamespace
		If $E(DBDir,1) = "^" Set selNamespace.value = ..FindDBName(DBDir)
	}
	
	Set (%page.ExecuteSpec,..%GetComponentById("txtSpec").value) = $P(LastSearch,"^",2)
	If $G($$$IRISTempMgt($Username,"Routine","ExecuteSpec")) '= "" Set %page.ExecuteSpec = $$$IRISTempMgt($Username,"Routine","ExecuteSpec")
	Set ..%GetComponentById("lblExecuteSpec").value = %page.ExecuteSpec
	Set (%page.ShowSys,..%GetComponentById("chkShowSys").value) = $P(LastSearch,"^",3)
	Set (%page.ShowGen,..%GetComponentById("chkShowGen").value) = $P(LastSearch,"^",4)
	Set (%page.BeginDate,..%GetComponentById("beginDate").value) = $P(LastSearch,"^",5)
	Set (%page.EndDate,..%GetComponentById("endDate").value) = $P(LastSearch,"^",6)
	Set (%page.MaxRows,..%GetComponentById("maxRows").value) = $P(LastSearch,"^",7)
	Set ..%GetComponentById("chkAllowSelectRow").value = +$P(LastSearch,"^",8)
	Set (%page.ShowMap,..%GetComponentById("chkShowMap").value) = $S($P(LastSearch,"^",9)="":1,1:+$P(LastSearch,"^",9))
	Set ..%GetComponentById("chkAlwaysFullView").value = +$P(LastSearch,"^",10)
	Set %page.searchExpanded = ..GetExpandState("Routine")
	Set table = ..%GetComponentById("table")
	Set table.maxRows = %page.MaxRows
	Set valueList = ..GetRecentList("Routine")
	If valueList '= "" {
		Set tCombo = ..%GetComponentById("txtSpec")
		Set tCombo.valueList = valueList
	}		
	#; Set the maxDate to today so that the year list will not be in the future
	Set (..%GetComponentById("beginDate").maxDate,..%GetComponentById("endDate").maxDate) = $P($ZDT($H,3)," ",1)
	Quit 1
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnCompile",$$$Text("Compile"),$$$Text("Compile selected routines (WRITE permission required)"),"zenPage.doCompile();")
	Set pCommands(2) = $LB("btnExport",$$$Text("Export"),$$$Text("Export selected routines"),"zenPage.doExport();")
	Set pCommands(3) = $LB("btnImport",$$$Text("Import"),$$$Text("Import routines to Namespace (WRITE permission required)"),"zenPage.doImport();")
	Set pCommands(4) = $LB("btnFind",$$$Text("Find"),$$$Text("Find a string from selected routines"),"zenPage.doFind(0);")
	Set pCommands(5) = $LB("btnReplace",$$$Text("Replace"),$$$Text("Replace a string from selected routines (WRITE permission required)"),"zenPage.doFind(1);")
	Set pCommands(6) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete selected routines (WRITE permission required)"),"zenPage.doDelete();")
	Set pCommands(7) = $LB("btnCompare",$$$Text("Compare"),$$$Text("Compare two routines"),"zenPage.doCompare();")
	Set pCommands(8) = $LB("btnClasses",$$$Text("Classes"),$$$Text("View classes in this namespace"),"zenPage.changePage('C');")
	Set pCommands(9) = $LB("btnGlobals",$$$Text("Globals"),$$$Text("View globals in this namespace"),"zenPage.changePage('G');")

	Quit $$$OK
}

Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	Quit 1
}

/// Method for executing the mapping query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tExecuteSpec = %page.ExecuteSpec
	Set tShowSys = %page.ShowSys
	Set tShowGen = %page.ShowGen
	Set tShowMap = %page.ShowMap
	Set tBeginDate = %page.BeginDate
	Set tEndDate = %page.EndDate
	#; Direction = 1 (acesding) -1 (descending); 
	Set tDirection = 1
	Set tFilter = ""
	If tBeginDate '= "" Set tFilter = "(Modified >= '"_tBeginDate_" 00:00:00'"
	If tEndDate '= "" {
		If tFilter'="" Set tFilter=tFilter_" AND " 
		Else  Set tFilter = "("
		Set tFilter = tFilter_"Modified <= '"_tEndDate_" 23:59:59'"
	}
	Set tMapped = $S('tShowMap:"MAPPED=0",1:"")
	If tFilter '= "" {
		Set tFilter = tFilter _ $S(tMapped'="":" AND "_tMapped,1:"")_")"
	} Else {
		Set tFilter = tMapped
	}
	Set $$$IRISTempMgt($Username,"Routine","Filter") = tFilter
	Set tSC = pRS.Execute(tExecuteSpec,tDirection,1,tShowSys,1,1,tShowGen,tFilter,1)
	Set EventDesc = $$$EventDescription
	Set EventData = tExecuteSpec_$$$CRLF_"Show System items: "_tShowSys_$$$CRLF_"Show Generated: " _ tShowGen_$$$CRLF_"Show Mapped: " _ tShowMap_$$$CRLF_"Filter: "_tFilter
	$$$SMPAuditView
	Quit tSC
}

/// User clicked Routines or Globals to change page.
ClientMethod changePage(newPage) [ Language = javascript ]
{
		
	var namespaceValue = this.getSelectedNamespace();
	var pageurl = (newPage == "C") ? this.ClassURL : this.GlobalURL;
	pageurl = pageurl + "?$NAMESPACE=" + encodeURIComponent(namespaceValue);
	document.location = pageurl;
}

/// return true namespace value or implied namespace value.
ClientMethod getSelectedNamespace() [ Language = javascript ]
{
	var namespaceValue = zen("selNamespace").getValue();
	if (zen("selType").getValue() == "Database") {
		namespaceValue = this.FindDBDir(namespaceValue);
	}
	return namespaceValue;
}

ClientMethod doCompile() [ Language = javascript ]
{
	var table = zen("table");
	var total = table.getProperty("rowCount");	
	if (total < 1) {
		alert($$$Text("Nothing to compile."));
		return;	
	}
	var namespaceValue = this.getSelectedNamespace();
	var selectedRows = table.getProperty("selectedRows");
	var compileAll = 0;
	var ok = this.PrepareAction(this.FILETYPE,selectedRows);
	if (ok == 0) {
		alert($$$Text("No compile routines were selected."));
		return;
	}
	var parms = {
			FILETYPE:this.FILETYPE,
			COMPILEALL:compileAll,
			$NAMESPACE:namespaceValue
	};
	
	//open dialog for compile criteria
	zenLaunchPopupWindow(zenLink('%CSP.UI.Portal.Dialog.Compile.zen'),'Compile','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

/// if user has selected some routines, pick the first two and pass to the Compare page.
ClientMethod doCompare() [ Language = javascript ]
{
	if (zen("selType").getValue() == "Database") {
		alert($$$Text("Comparing routines in Database is not available."));	
		return;
	}
	
	var table = zen("table");
	var namespaceValue = this.getSelectedNamespace();
	var selectedRows = table.getProperty("selectedRows");
	var Routine1 = "";
	var Routine2 = "";
	var cbName = "";
	var cbArray = selectedRows.split(',');
	var len = cbArray.length;
	var numberFound = 0;
	for (var i = 0; i < len; i++) {
		if (numberFound == 2) break;
		if (cbArray[i] != "") {
			numberFound++;
			if (numberFound == 1) Routine1 = encodeURIComponent(cbArray[i]);
			if (numberFound == 2) Routine2 = encodeURIComponent(cbArray[i]);
		}
	}	
	var link = "%25CSP.UI.Portal.RoutineCompare.zen?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&Routine1=" + Routine1 + "&Routine2=" + Routine2;
	document.location = zenLink(link);
}

ClientMethod doSelectRow(routineName) [ Language = javascript ]
{
	if (zen("chkAlwaysFullView").getValue()) return;
	if (zen("chkAllowSelectRow").getValue()) this.doDoc(routineName);
	return;
}

ClientMethod doDoc(routineName) [ Language = javascript ]
{
	// check if routine is obj
	if ((routineName.indexOf(".obj")) > -1 ) return;
	if (zen("chkAlwaysFullView").getValue()) {
		this.doFullView(routineName);
		return;
	}
	var selType = zen("selType").getValue();
	var namespaceValue = this.getSelectedNamespace();
	var doclink = this.DocPage + "?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&FILENAME=" + encodeURIComponent(routineName);
	this.onresizeHandler();
	zen('idCode').setHidden(false);
	zen('output').setProperty('src',doclink);
}

ClientMethod doFullView(routineName) [ Language = javascript ]
{
	var table = zen("table");
	if (routineName == "") routineName = table.getValue();
	var namespaceValue = this.getSelectedNamespace();
	var doclink = this.DocPage + "?$TYPE=rtn&$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&FILENAME=" + encodeURIComponent(routineName);
	var win = window.open(doclink,"ViewCode");
	win.focus();
}

ClientMethod doDelete() [ Language = javascript ]
{
	var table = zen("table");
	var total = table.getProperty("rowCount");	
	if (total < 1) {
		alert($$$Text("Nothing to delete."));
		return;	
	}
	var selectedRows = table.getProperty("selectedRows");
	var ok = this.PrepareAction(this.FILETYPE,selectedRows);
	if (ok == 0) {
		alert($$$Text("No routines were selected for deletion."));
		return;
	}
	ok = confirm($$$Text("Are you sure you want to delete the selected routines?"));
	if (ok == false) return;
	// now go delete them
	ok = this.Delete(this.FILETYPE);
	if (ok != 1) alert(ok);
	var table = zen("table");
	table.executeQuery(0);
}

/// Open up the Find/Replace CSP page.
ClientMethod doFind(isReplace) [ Language = javascript ]
{
	var table = zen("table");
	var total = table.getProperty("rowCount");	
	if (total < 1) {
		alert($$$Text("Nothing to find."));
		return;	
	}
	var namespaceValue = this.getSelectedNamespace();
	var selectedRows = table.getProperty("selectedRows");
	var ok = this.PrepareAction(this.FILETYPE,selectedRows);
	if (ok == 0) {
		alert($$$Text("No routines were selected."));
		return;
	}
	///open Find page in a separate window.
	var win = window.open(this.FindPage+"?$NAMESPACE="+encodeURIComponent(namespaceValue)+"&rep="+isReplace+"&cbAction=Routine",'FindString');
	win.focus();
}

ClientMethod doExport() [ Language = javascript ]
{
	var table = zen("table");
	var total = table.getProperty("rowCount");	
	if (total < 1) {
		alert($$$Text("Nothing to export."));
		return;	
	}
	var namespaceValue = this.getSelectedNamespace();
	var selectedRows = table.getProperty("selectedRows");
	var exportAll = 0;
	var ok = this.PrepareAction(this.FILETYPE,selectedRows);
	if (ok == 0) {
		alert($$$Text("No export routines were selected."));
		return;
	}
	var parms = {
			FILETYPE:this.FILETYPE,
			EXPORTALL:exportAll,
			$NAMESPACE:namespaceValue
	};
	//open dialog for export criteria
	zenLaunchPopupWindow(zenLink('%CSP.UI.Portal.Dialog.Export.zen'),'Export','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod doImport() [ Language = javascript ]
{
	var namespaceValue = this.getSelectedNamespace();
	var parms = {
			FILETYPE:this.FILETYPE,
			$NAMESPACE:namespaceValue
	};
	
	//open dialog for import criteria
	zenLaunchPopupWindow(zenLink('%CSP.UI.Portal.Dialog.Import.zen'),'Import','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

/// Changed Nemespace <==> Database (implied namespace).
ClientMethod doNamespace(selTypeChanged) [ Language = javascript ]
{
	try {
		var selType = zen("selType").getValue();
		var namespaceValue = this.getSelectedNamespace();
		if (selType=="Namespace" && selTypeChanged==1) {
			// find out if the DBName matches any of the Namespaces
			var DBName = zen("selNamespace").getValue();
			namespaceValue = this.findNSMatch(DBName);
		}
		var spec = this.saveOptions();
		var urlpage = this.RoutineURL + "?$NAMESPACE=" + encodeURIComponent(namespaceValue);
		document.location = urlpage;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in doNamespace');
	}
}

/// User clicked Go to start search. 
ClientMethod doSearch() [ Language = javascript ]
{
	var spec = this.saveOptions();
	var RecentURLs = this.GetRecentList("Routine");
	zen("txtSpec").setProperty("valueList",RecentURLs);
		
	var table = zen("table");
	table.setProperty("maxRows",this.MaxRows);
	table.executeQuery(0);
	this.hideDoc();
	zen("lblExecuteSpec").setValue(spec);
	// put it to the same column order as last one user clicked.
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	// update the time.
	this.updateTime();
}

/// Generic function to save user input options, called by doNamespace and doSearch, and when chkAlwaysFullView or chkAllowSelectRow is changed.
ClientMethod saveOptions() [ Language = javascript ]
{
	var selType = zen("selType").getValue();
	var spec = zen("txtSpec").getValue();
	if (spec == "") {
		if (this.FILETYPE == "Routine") spec = "*.mac"
		zen("txtSpec").setValue(spec);
	}

	var showsys = zen("chkShowSys").getValue();
	var showgen = zen("chkShowGen").getValue();
	var showmap = zen("chkShowMap").getValue();
	var begindate = zen("beginDate").getValue();
	var enddate = zen("endDate").getValue();
	showsys = (showsys == true) ? 1 : 0;
	showgen = (showgen == true) ? 1 : 0;
	showmap = (showmap == true) ? 1 : 0;
	var maxRows = zenTrim(zen("maxRows").getValue());
	if ((maxRows == "") || (isNaN(maxRows)==true) || (parseInt(maxRows) > 10000)) {
		maxRows = 10000;
	} else {
		maxRows = Math.round(maxRows);
	}
	zen("maxRows").setValue(maxRows);
	var alwaysfulliew = (zen("chkAlwaysFullView").getValue() == true) ? 1 : 0;	
	var allowselectrow = (zen("chkAllowSelectRow").getValue() == true) ? 1 : 0;
	var spec = this.SaveSelections(this.FILETYPE,selType,spec,showsys,showgen,begindate,enddate,maxRows,allowselectrow,showmap,alwaysfulliew);
	this.ExecuteSpec = spec;
	this.ShowSys = showsys;
	this.ShowGen = showgen;
	this.ShowMap = showmap;
	this.BeginDate = begindate;
	this.EndDate = enddate;
	this.MaxRows = maxRows;
	return spec
}

ClientMethod updatePreference() [ Language = javascript ]
{
	if (zen("chkAlwaysFullView").getValue()) this.hideDoc();
	this.saveOptions();
}

/// Update / Reload table. This overrides the one in Template.List.
ClientMethod updateView() [ Language = javascript ]
{
	this.doSearch();
}

/// User clicked one of the routine name type. 
ClientMethod doMask(nametype) [ Language = javascript ]
{
	zen("txtSpec").setValue(nametype);
	this.doSearch();
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'switchNamespace':
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = this.RoutineURL + '?$NAMESPACE=' + encodeURIComponent(value);
		break;
	case 'Compile':
		break;
	case 'Export':
		break;
	case 'Import':
		var table = zen("table");
		table.executeQuery(0);
		break;
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.showExpand();
	this.adjustSizes();
	this.updateTime();
	// in case user clicked the browser's Back button
	this.checkURLNamespace();	
	var selType = zen("selType").getValue();
	if (selType == "Database") {
		this.disableCommandButton("btnCompare");
		zen("chkShowMap").setHidden(true);
	}
	if (!this.writePERMISSION) {
		this.disableCommandButton("btnDelete");
		this.disableCommandButton("btnImport");
		this.disableCommandButton("btnReplace");
	}
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	// calculate width and height for iframe's size.
	var winWidth = zenGetWindowWidth();
	var winHeight = zenGetWindowHeight();
	var pageElm = zenPage.getEnclosingDiv();
	// Ensure some minimal amount of padding
	var vscrollbarWidth = Math.max(17, Math.abs(winWidth - pageElm.offsetWidth));
	var hscrollbarHeight = Math.max(17, Math.abs(winHeight - pageElm.offsetHeight));
	var bbox = zen('table').getEnclosingDiv().getBoundingClientRect();
	var wd = Math.max(100, winWidth - Math.ceil(bbox.right) - zenGetPageScrollLeft() - (2 * vscrollbarWidth));
	var ht = Math.max(100, winHeight - Math.ceil(bbox.top) - zenGetPageScrollTop() - (2 * hscrollbarHeight));
	var frame = zen("output");
	frame.setProperty("width",wd+"px");
	frame.setProperty("height",ht+"px");
	// make iframe div to have fixed position so it is always visible when you scroll up and down the table.
	zen("idCode").getEnclosingDiv().style.position = "fixed";
}

Method GetLastSearch() As %String
{
	Set LastSearch = $G($$$IRISTempMgt($Username,"Routine"))
	If LastSearch = "" Set LastSearch = "Namespace^*.mac^0^1^^^1000^0^1^0"
	If $P(LastSearch,"^",2) = "" Set $P(LastSearch,"^",2) = "*.mac"
	Quit LastSearch
}

/// Delete selected routines now.
ClassMethod Delete(FILETYPE) As %String [ ZenMethod ]
{
	Set EventDesc = $$$EventDescription_" Delete"
	Set lblDelete = $$$Text("Deleting")
	Set lblDone = $$$Text("...Done.")
	Set tResult = ""
	Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
	While tRow '= "" {
		Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)
		Set n = 1
		Set tLen = $L(selectedRows,",")
		While n '> tLen {
			Set tName = $P(selectedRows,",",n)
			If tName '= "" {
				Set tItems(tName) = ""
				Set tSC = ##class(%RoutineMgr).Delete(tName)
				If $$$ISERR(tSC) Set tResult = $S(tResult'="":tResult_"\n",1:"")_$System.Status.GetErrorText(tSC)
			}
			Set n = n + 1
		}
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
	}
	Set EventData = "Delete routines"_$$$CRLF
	Do $$$PatEventRows(.EventData,.tItems)
	$$$SMPAuditChange
	If tResult = "" Quit 1
	Quit tResult
}

}
