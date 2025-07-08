/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Zen page for System Management Portal - Classes list
Class %CSP.UI.Portal.ClassList Extends %CSP.UI.Template.List [ System = 4 ]
{

/// Allow to change namespaces for this page.
Parameter AUTONS As BOOLEAN = 1;

/// Displayed name of this page.
Parameter PAGENAME = "ClassList";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.ClassList.zen";

Parameter HELPADDRESS = "Home,Classes";

/// Security requirement
Parameter RESOURCE = "%Development";

Property FILETYPE As %String [ InitialExpression = "Class" ];

Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

Property ClassSpec As %String [ InitialExpression = "*.cls" ];

Property writePERMISSION As %ZEN.Datatype.boolean [ InitialExpression = {$System.Security.GetRoutinePermission($namespace) [ "WRITE"} ];

Property ShowSQL As %Boolean(ZENURL = "SQL");

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
<label label="Show:" />
<checkbox id="chkShowSql" value="#(%page.ShowSQL)#" caption="SQL table name" captionClass="optionLabel" title="Show SQL Table Names" onclick="zenPage.doSql();"/>
<html><hr size="1"/></html>
<label label="Filter:" />
<vgroup id="idOption" labelPosition="top" enclosingStyle="padding-bottom:10px;" cellStyle="padding-right:2px;padding-bottom:10px;valign=bottom;">
<dateText id="beginDate" label="Begin date (yyyy-mm-dd)" labelClass="optionLabel" hint="" hintClass="helpText" onchange="zenPage.doSearch();"/>
<dateText id="endDate" label="End date (yyyy-mm-dd)" labelClass="optionLabel" hint="" hintClass="helpText" onchange="zenPage.doSearch();"/>
<combobox id="txtSpec" label="Class name" labelClass="optionLabel" comboType="timer" editable="true" unrestricted="true" size="19"
title="Enter a search pattern. This can include * as a wild card." value="*.cls" onchange="zenPage.doSearch();"/>
<text id="maxRows" label="Maximum rows" labelClass="optionLabel" title="Maximum number of rows to load - cannot be greater than 10000" size="6" value="1000" onchange="zenPage.doSearch();" onkeyup="zenPage.keyUp(zenEvent);"/>
</vgroup>

<!-- <button id="btnSearch" caption="Search" onclick="zenPage.doSearch();"/> -->
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
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);"
/>
<checkbox id="chkAlwaysFullView" caption="view doc in new window" captionClass="optionLabel" onchange="zenPage.updatePreference();"
title="Check to always have full view of documentation in a separate window. Uncheck to quick view of documentation on the right side."/>
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
<column colName="Name" header="Name" title="Class name"/>
<column colName="Date" header="Date" title="Date/Time last modified"/>
<column colName="Size" header="Size" title="Class size"/>
<column linkCaption="Documentation" link="javascript:zenPage.docClicked();"/>
<parameter id="tspec" value="*.cls"/>
<parameter id="tdir" value="1"/>
<parameter id="torderby" value="1"/>
<parameter id="tshowsys" value="0"/>
<parameter id="tflat" value="1"/>
<parameter id="tnotstudio" value="1"/>
<parameter id="tshowgen" value="0"/>
<parameter id="tfilter" />
<parameter id="troundtime" value="1" />
 
</tablePane>
</vgroup>
<vgroup id="idCode" valign="top" hidden="true">
<hgroup id="idCodeOptions" cellAlign="even" width="100%">
<link caption="full_view" title="click here to view full documatic in a separate window" href="javascript:zenPage.doFullView();"/>
<checkbox id="chkAllowSelectRow" caption="show documentation when clicking on a row" captionClass="normal" onchange="zenPage.updatePreference();"/>
<image id="imageClear" src="csp/broker/deepsee/close_a_16.gif" width="12" height="12" onclick="zenPage.hideDoc();" title="close this view" valign="middle"/>
</hgroup>
<iframe id="output" valign="top"/>
</vgroup>
</hgroup>
</pane>
}

Method DrawSQLColumn(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	#; Adapted the following if-elseif-else block from %SQL.Manager.Catalog::IndicesFetch
	if $extract(%query("Name"),*-3,*)=".cls" {
		set cls = $extract(%query("Name"),1,*-4)
		if $get($$$EXTsqlinfo($$$rEXT,cls)) '= "", $PARAMETER(cls, "CONNECTION")="" { ##; If SQL information is defined, but not an external table
			set schema = $$$comClassKeyGet(cls,$$$cCLASSsqlschemaname)
			set tablename = $$$comClassKeyGet(cls,$$$cCLASSsqltablename)
			&html<<a href="javascript:zenPage.sqlClicked('#(schema)#','#(tablename)#');">View SQL related globals</a>>
		}
	}
	return $$$OK
}

/// this method is called when user clicked the "Documentation" link. The value could not be passed with the correct escaping so we have to use the table value here.
ClientMethod docClicked() [ Language = javascript ]
{
	var className = zen("table").getValue();
	this.doDoc(className,0);
}

ClientMethod sqlClicked(schema As %String, tablename As %String) [ Language = javascript ]
{
	var schemaParam = "SCHEMA=" + encodeURIComponent(schema);
	var tableParam = "TABLE=" + encodeURIComponent(tablename);
	var link = [zenLink('%CSP.UI.Portal.ClassList.SQLDetails.zen'),schemaParam,tableParam].join("&");
	zenPage.launchPopupWindow(link,'Class SQL Details','status,scrollbars,resizable,width=700,height=850');
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
	Quit $$$Text("Classes")
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
		
	Set %page.ClassURL = $P(..Link("%25CSP.UI.Portal.ClassList.zen"),"?$NAMESPACE",1)
	Set %page.GlobalURL = $P(..Link("%25CSP.UI.Portal.GlobalList.zen"),"?$NAMESPACE",1)
	Set %page.RoutineURL = $P(..Link("%25CSP.UI.Portal.RoutineList.zen"),"?$NAMESPACE",1)
	Set %page.DocPage = $P(..Link("/csp/documatic/%25CSP.Documatic.cls"),"?$NAMESPACE",1)
	
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

	Set (%page.ClassSpec,..%GetComponentById("txtSpec").value) = $P(LastSearch,"^",2)
	Set (%page.ShowSys,..%GetComponentById("chkShowSys").value) = $P(LastSearch,"^",3)
	Set (%page.ShowGen,..%GetComponentById("chkShowGen").value) = $P(LastSearch,"^",4)
	Set (%page.BeginDate,..%GetComponentById("beginDate").value) = $P(LastSearch,"^",5)
	Set (%page.EndDate,..%GetComponentById("endDate").value) = $P(LastSearch,"^",6)
	Set (%page.MaxRows,..%GetComponentById("maxRows").value) = $P(LastSearch,"^",7)
	Set ..%GetComponentById("chkAllowSelectRow").value = +$P(LastSearch,"^",8)
	Set (%page.ShowMap,..%GetComponentById("chkShowMap").value) = $S($P(LastSearch,"^",9)="":1,1:+$P(LastSearch,"^",9))
	Set ..%GetComponentById("chkAlwaysFullView").value = +$P(LastSearch,"^",10)
	Set %page.searchExpanded = ..GetExpandState("Class")
	Set table = ..%GetComponentById("table")
	Set table.maxRows = %page.MaxRows
	If LastLookin = "Namespace" {
		if ..ShowSQL {
			Set col = ##class(%ZEN.Auxiliary.column).%New()
			Set col.OnDrawCell = "DrawSQLColumn"
			Do table.columns.Insert(col)
			Do %page.%AddComponent(col)
		}
	} Else {
		Set ..%GetComponentById("chkShowSql").hidden = 1
	}
	Set valueList = ..GetRecentList("Class")
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
	Set pCommands(1) = $LB("btnCompile",$$$Text("Compile"),$$$Text("Compile selected classes (WRITE permission required)"),"zenPage.doCompile();")
	Set pCommands(2) = $LB("btnExport",$$$Text("Export"),$$$Text("Export selected classes"),"zenPage.doExport();")
	Set pCommands(3) = $LB("btnImport",$$$Text("Import"),$$$Text("Import classes to Namespace (WRITE permission required)"),"zenPage.doImport();")
	Set pCommands(4) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete selected classes (WRITE permission required)"),"zenPage.doDelete();")
	Set pCommands(5) = $LB("btnRoutines",$$$Text("Routines"),$$$Text("View routines in this namespace"),"zenPage.changePage('R');")
	Set pCommands(6) = $LB("btnGlobals",$$$Text("Globals"),$$$Text("View globals in this namespace"),"zenPage.changePage('G');")

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
	Set tClassSpec = %page.ClassSpec
	Set tShowSys = %page.ShowSys
	Set tShowGen = %page.ShowGen
	Set tShowMap = %page.ShowMap
	Set tBeginDate = %page.BeginDate
	Set tEndDate = %page.EndDate
	#; Direction = 1 (acesding) -1 (descending); 
	Set tDirection = 1

	#; The spec must have ".cls" at the end otherwise it will return all types.
	Set tNewSpec = ""
	For p = 1:1:$L(tClassSpec,",") {
		Set p1 = $P(tClassSpec,",",p)
		If $E(p1,$L(p1)-3,$L(p1))'=".cls" Set p1 = p1 _".cls"
		Set tNewSpec = tNewSpec _ $S(tNewSpec="":"",1:",") _ p1
	}
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
	Set $$$IRISTempMgt($Username,"Class","Filter") = tFilter
	Set tSC = pRS.Execute(tNewSpec,tDirection,1,tShowSys,1,1,tShowGen,tFilter,1)
	Set EventDesc = $$$EventDescription
	Set EventData = tClassSpec_$$$CRLF_"Show System items: "_tShowSys_$$$CRLF_"Show Generated: " _ tShowGen_$$$CRLF_"Show Mapped: " _ tShowMap_$$$CRLF_"Filter: "_tFilter
	$$$SMPAuditView
	Quit tSC
}

/// User clicked Routines or Globals to change page. Namespace will be carried over, not Database.
ClientMethod changePage(newPage) [ Language = javascript ]
{
	var namespaceValue = this.getSelectedNamespace();
	var pageurl = (newPage == "G") ? this.GlobalURL : this.RoutineURL;
	document.location = pageurl + "?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&SQL=" + (this.ShowSQL === true ? 1 : 0);
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
		var ok = confirm($$$Text("No compile classes were selected. Do you want to compile All classes in this namespace?"));
		if (!ok) return;
		compileAll = 1;
	}
	var parms = {
			MODE:"models",
			FILETYPE:this.FILETYPE,
			COMPILEALL:compileAll,
			$NAMESPACE:namespaceValue
	};
	
	//open dialog for compile criteria
	zenLaunchPopupWindow(zenLink('%CSP.UI.Portal.Dialog.Compile.zen'),'Compile','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod doSelectRow(className) [ Language = javascript ]
{
	if (zen("chkAlwaysFullView").getValue()) return;	
	if (zen("chkAllowSelectRow").getValue()) this.doDoc(className);
	return;
}

/// Show class documatic in short view or full view. If fullView then open full Documatic.
ClientMethod doDoc(className, fullView) [ Language = javascript ]
{
	if (zen("chkAlwaysFullView").getValue()) {
		fullView = 1;
	}
	// remove ".cls" from the className before passing to Documatic.
	var className = className.substring(0,className.length-4);
	var namespaceValue = zen("selNamespace").getValue();
	var doclink = this.DocPage + "?LIBRARY=" + encodeURIComponent(namespaceValue) + "&CLASSNAME=" + encodeURIComponent(className);
	if (fullView) {
		var win = window.open(doclink,'docbook');
		win.focus();
	} else {
		this.onresizeHandler();
		zen('idCode').setHidden(false);
		zen('output').setProperty('src',doclink + "&SHOWCLASSONLY=1");
	}
}

ClientMethod doFullView() [ Language = javascript ]
{
	var table = zen("table");
	var className = table.getValue();
	this.doDoc(className,1);
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
		alert($$$Text("No classes were selected for deletion."));
		return;
	}
	ok = confirm($$$Text("Are you sure you want to delete the selected classes?"));
	if (ok == false) return;
	// now go delete them
	ok = this.Delete(this.FILETYPE);
	if (ok != 1) alert(ok);
	var table = zen("table");
	table.executeQuery(0);
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
	var exportAll = 0;
	var selectedRows = table.getProperty("selectedRows");
	var ok = this.PrepareAction(this.FILETYPE,selectedRows);
	if (ok == 0) {
		var ok = confirm($$$Text("No export classes were selected. Do you want to export All classes in this namespace?"));
		if (!ok) return;
		exportAll = 1;
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
	//	Set tIsImpliedNS = ($E($namespace,1,1)="^")
	if (zen("selType").getValue() == "Database") {
		alert($$$Text("Importing classes into a Database is not available."));	
		return;
	}
	var namespaceValue = this.getSelectedNamespace();
	var parms = {
			MODE:"models",
			FILETYPE:this.FILETYPE,
			$NAMESPACE:namespaceValue
	};
	
	//open dialog for import criteria
	zenLaunchPopupWindow(zenLink('%CSP.UI.Portal.Dialog.Import.zen'),'Import','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

/// Changed Namespace <==> Database (implied namespace).
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
		var urlpage = this.ClassURL + "?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&SQL=" + (this.ShowSQL === true ? 1 : 0);
		document.location = urlpage;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in doNamespace');
	}
}

ClientMethod doSql() [ Language = javascript ]
{
	try {
		var namespaceValue = this.getSelectedNamespace();
		var urlpage = this.ClassURL + "?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&SQL=" + (zen("chkShowSql").getValue() === true ? 1 : 0);
		self.document.location = urlpage;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// User clicked Go to start search. 
ClientMethod doSearch() [ Language = javascript ]
{
	var spec = this.saveOptions();
	var RecentURLs = this.GetRecentList("Class");
	zen("txtSpec").setProperty("valueList",RecentURLs);
		
	var table = zen("table");
	table.setProperty("maxRows",this.MaxRows);
	table.executeQuery(0);
	this.hideDoc();
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
		if (this.FILETYPE == "Class") spec = "*.cls"
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
	this.ClassSpec = spec;
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

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'switchNamespace':
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = this.ClassURL + '?$NAMESPACE=' + encodeURIComponent(value);
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

Method GetLastSearch() As %String
{
	Set LastSearch = $G($$$IRISTempMgt($Username,"Class"))
	If LastSearch = "" Set LastSearch = "Namespace^*.cls^0^0^^^1000^0^1^0"
	If $P(LastSearch,"^",2) = "" Set $P(LastSearch,"^",2) = "*.cls"
	Quit LastSearch
}

/// Delete selected classes now.
ClassMethod Delete(filetype) As %String [ ZenMethod ]
{
	Set EventDesc = $$$EventDescription_" Delete"
	Set tResult = ""
	Set tRow = $O(%session.Data($Username,filetype,"selectedRows",""))
	While tRow '= "" {
		Set selectedRows = %session.Data($Username,filetype,"selectedRows",tRow)
		Set n = 1
		Set tLen = $L(selectedRows,",")
		While n '> tLen {
			Set tName = $P(selectedRows,",",n)
			If tName '= "" {
				Set tItems(tName) = ""
				Set tSC = $System.OBJ.Delete(tName,"-d")
				If $$$ISERR(tSC) Set tResult = $S(tResult'="":tResult_"\n",1:"")_$System.Status.GetErrorText(tSC)
			}
			Set n = n + 1
		}
		Set tRow = $O(%session.Data($Username,filetype,"selectedRows",tRow))
	}
	Set EventData = "Delete classes: "_$$$CRLF
	Do $$$PatEventRows(.EventData,.tItems)
	$$$SMPAuditChange
	If tResult = "" Quit 1
	Quit tResult
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
		this.disableCommandButton("btnImport");
		zen("chkShowMap").setHidden(true);
	}
	if (!this.writePERMISSION) {
		this.disableCommandButton("btnCompile");
		this.disableCommandButton("btnImport");
		this.disableCommandButton("btnDelete");
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

}
