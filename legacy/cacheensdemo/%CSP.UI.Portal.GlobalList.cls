/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Zen page for System Management Portal - Global list
Class %CSP.UI.Portal.GlobalList Extends %CSP.UI.Template.List [ System = 4 ]
{

/// Allow to change namespaces for this page.
Parameter AUTONS As BOOLEAN = 1;

/// Displayed name of this page.
Parameter PAGENAME = "GlobalList";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.GlobalList.zen";

Parameter HELPADDRESS = "Home,Globals";

/// Security requirement
Parameter RESOURCE = "%Development";

Property FILETYPE As %String [ InitialExpression = "Global" ];

Property GlobalSpec As %String [ InitialExpression = "*" ];

Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

Property FindPage As %String;

Property ViewGlobalURL As %String;

Property writePERMISSION As %ZEN.Datatype.boolean [ InitialExpression = {$System.Security.GetGlobalPermission($namespace) [ "WRITE"} ];

Property ShowSQL As %Boolean(ZENURL = "SQL");

XData Style
{
<style type="text/css">
.optionLabel {
	color: #202020;
	font-size: 11px;
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
<html><hr size="1"/></html>
<label label="Show:" />
<checkbox id="chkShowSql" value="#(%page.ShowSQL)#" caption="SQL table name" captionClass="optionLabel" title="Show SQL Table Names" onclick="zenPage.doSql();"/>
<html><hr size="1"/></html>
<label label="Filter:" />
<vgroup id="idOption" labelPosition="top" enclosingStyle="padding-bottom:10px;" cellStyle="padding-right:2px;padding-bottom:10px;valign=bottom;">
<!-- Eventhough the query does not taken these parameters now, I am leaving them here for consistency in code, and future -->
<!--
<dateText id="beginDate" label="Begin date (yyyy-mm-dd)" labelClass="optionLabel" hint="" hintClass="helpText" hidden="true"/>
<dateText id="endDate" label="End date (yyyy-mm-dd)" labelClass="optionLabel" hint="" hintClass="helpText" hidden="true"/>
-->
<combobox id="txtSpec" label="Global name" labelClass="optionLabel" comboType="timer" editable="true" unrestricted="true" size="19"
title="Enter a search pattern. This can include * as a wild card." value="*" onchange="zenPage.doSearch();"/>
<text id="maxRows" label="Maximum rows" labelClass="optionLabel" title="Maximum number of rows to load - enter a number between 1 - 10000" size="6" value="1000" onchange="zenPage.doSearch();" onkeyup="zenPage.keyUp(zenEvent);"/>
</vgroup>

<!-- <button id="btnSearch" caption="Search" onclick="zenPage.doSearch();" /> -->
</form>

</pane>
}

XData resultPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:2px">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<tableNavBar showFilter="false" showPageSize="true" tablePaneId="table" 
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);"
/>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
queryClass="%SYS.GlobalQuery"
queryName="NameSpaceList"
dataSource="columns"
fixedHeaders="false"
multiSelect="true"
maxRows="1000"
pageSize="0"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
OnCreateResultSet="CreateRS"
OnExecuteResultSet="ExecuteRS"
>
<column colName="Name" header="Name" title="Global name"/>
<column colName="Keep" header="Keep"/>
<column colName="Collation" header="Collation"/>

<column linkCaption="View" link="UtilExpGlobalView.csp?$ID2=#(%query.Name)#&amp;$NAMESPACE=#(%page.NAMESPACE)#"/>
<column linkCaption="Edit" link="UtilExpGlobalDrill.csp?$ID2=#(%query.Name)#&amp;$NAMESPACE=#(%page.NAMESPACE)#"/>

<parameter id="tnamespace" value="1"/>
<parameter id="tspec" value="*"/>
<parameter id="tshowsys" value="0"/>
<parameter id="tshowunava" value=""/>
<parameter id="tindex" value="1"/>
<parameter id="tignoreHasData" value="1"/>
 
</tablePane>

</pane>
}

Method DrawSQLColumn(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	set global = "^"_%query("Name")
	set content = ""
	if seed = "tablename" {
		set content = ##class(%ExtentMgr.Util).GlobalToSqlTable(..NAMESPACE, global)
	} elseif seed = "usage" {
		set ext = ##class(%ExtentMgr.GlobalRegistry).FindReference(global, .pUse)  return:(ext = "") $$$OK
		set:($extract(pUse,*-3,*)=".cls") cls = $extract(pUse,1,*-4)  return:($get(cls)="") $$$OK
		set storagestrat = $$$comClassKeyGet(cls, $$$cCLASSstoragestrategy)  return:(storagestrat="") $$$OK
		#; Cannot use $CASE as $$$cSDEFcounterlocation may be empty string
		set content = $select(
			global = $$$comMemberKeyGet(cls,$$$cCLASSstorage,storagestrat,$$$cSDEFidlocation): "Data / Master",
			global = $$$comMemberKeyGet(cls,$$$cCLASSstorage,storagestrat,$$$cSDEFindexlocation): "Indices",
			global = $$$comMemberKeyGet(cls,$$$cCLASSstorage,storagestrat,$$$cSDEFstreamlocation): "Streams",
			global = $$$comMemberKeyGet(cls,$$$cCLASSstorage,storagestrat,$$$cSDEFcounterlocation): "Counters",
			1:""
		)
		if content = "" { ##; USEEXTENTSET allocates a different global per index; thus do an index scan
			set index = ""
			for {
				set index = $$$comSubMemberNext(cls,$$$cCLASSstorage,storagestrat,$$$cSDEFindex,index)
				quit:(index = "")
				if global = $$$comSubMemberKeyGet(cls,$$$cCLASSstorage,storagestrat,$$$cSDEFindex,index,$$$cSDEFIDXlocation) {
					$$$comMemberKeyGetLvar(idxSqlName,cls,$$$cCLASSindex,index,$$$cINDEXsqlname)
					#; Adapted the following if-elseif-else block from %SQL.Manager.Catalog::IndicesFetch
					set mapinfo = $$$EXTSQLMAPsqlinfo($$$rEXT,cls,idxSqlName)
					if $$$SetSQLLocMapUnique(mapinfo) { set type = "Unique" }
			 		elseif $$$SQLLocMapIndexType(mapinfo)="B" { set type = "Bitmap" }
			 		elseif $$$SQLLocMapIndexType(mapinfo)="S" { set type = "Bitslice" }
			 		elseif $$$SQLLocMapIndexType(mapinfo)="BE" { set type = "Bitmap Extent" }
			 		elseif $extract($$$SQLLocMapIndexType(mapinfo),1,2)="FI" { set type = $$$SQLLocMapIndexType(mapinfo) }
			 		else { set type = "Standard" }
					set content = idxSqlName _ " (" _ $zconvert(type,"W") _ " Index)"
					quit
				}
			}
		}
	}
	&html<#($zconvert(content,"O","HTML"))#>
	return $$$OK
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
	Quit $$$Text("Globals")
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set %page.lblTitle = ..%OnGetPageName()
	Set %page.StdTitle = %page.lblTitle
	Set %page.ClassURL = $P(..Link("%25CSP.UI.Portal.ClassList.zen"),"?$NAMESPACE",1)
	Set %page.GlobalURL = $P(..Link("%25CSP.UI.Portal.GlobalList.zen"),"?$NAMESPACE",1)
	Set %page.RoutineURL = $P(..Link("%25CSP.UI.Portal.RoutineList.zen"),"?$NAMESPACE",1)
	Set %page.DocPage = $P(..Link("/csp/documatic/%25CSP.Documatic.cls"),"?$NAMESPACE",1)
	Set %page.FindPage = $P(..Link("/csp/sys/exp/UtilExpFindReplace.csp"),"?$NAMESPACE",1)
	Set %page.ViewGlobalURL = $P(..Link("/csp/sys/exp/UtilExpGlobalView.csp"),"?$NAMESPACE",1)

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
	
	Set (%page.GlobalSpec,..%GetComponentById("txtSpec").value) = $P(LastSearch,"^",2)
	Set (%page.ShowSys,..%GetComponentById("chkShowSys").value) = $P(LastSearch,"^",3)
	Set (%page.MaxRows,..%GetComponentById("maxRows").value) = $P(LastSearch,"^",7)
	Set %page.searchExpanded = ..GetExpandState("Global")
	Set table = ..%GetComponentById("table")
	Set table.maxRows = %page.MaxRows
	If LastLookin = "Namespace" {
		Set insertAt = 1
		if ..ShowSQL {
			Set col = ##class(%ZEN.Auxiliary.column).%New()
			Set col.header = $$$Text("SQL table")
			Set col.title = $$$Text("Corresponding SQL Table Name for this global if there is one")
			Set col.OnDrawCell = "DrawSQLColumn"
			Set col.seed = "tablename"
			Set col.style="font-size: 1em;"
			Do table.columns.InsertAt(col,$increment(insertAt))
			Do %page.%AddComponent(col)
			
			Set col = ##class(%ZEN.Auxiliary.column).%New()
			Set col.header = $$$Text("SQL usage")
			Set col.OnDrawCell = "DrawSQLColumn"
			Set col.title = $$$Text("Purpose of the global with respects to the SQL engine")
			Set col.seed = "usage"
			Set col.style="font-size: 1em;"
			Do table.columns.InsertAt(col,$increment(insertAt))
			Do %page.%AddComponent(col)
		}
		
		Set col = ##class(%ZEN.Auxiliary.column).%New()
		Set col.colName = "Location"
		Set col.header = "Location"
		Set col.title = "Location of database containing this item"
		Do table.columns.InsertAt(col,$increment(insertAt))
		Do %page.%AddComponent(col)
	} Else {
		Set ..%GetComponentById("chkShowSql").hidden = 1
	}
	Set valueList = ..GetRecentList("Global")
	If valueList '= "" {
		Set tCombo = ..%GetComponentById("txtSpec")
		Set tCombo.valueList = valueList
	}		
	Quit 1
}

/// Return Namespace list for UI's valueList.
ClassMethod GetList() As %String [ ZenMethod ]
{
	Set tCnt = ##class(%CSP.Util.SMNavigatorPane).GetAllNamespaces(.Namespaces)
	Set valueList = "" 
	For i=1:1:tCnt {
		Set valueList = valueList _ $S(valueList'="":",",1:"") _ Namespaces(i)
	}
	Quit valueList
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnExport",$$$Text("Export"),$$$Text("Export selected globals"),"zenPage.doExport();")
	Set pCommands(2) = $LB("btnImport",$$$Text("Import"),$$$Text("Import globals to Namespace (WRITE permission required)"),"zenPage.doImport();")
	Set pCommands(3) = $LB("btnFind",$$$Text("Find"),$$$Text("Find a string from selected globals"),"zenPage.doFind(0);")
	Set pCommands(4) = $LB("btnReplace",$$$Text("Replace"),$$$Text("Replace a string from selected globals (WRITE permission required)"),"zenPage.doFind(1);")
	Set pCommands(5) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete selected globals (WRITE permission required)"),"zenPage.doDelete();")
	Set pCommands(6) = $LB("btnViewGlobal",$$$Text("View"),$$$Text("View a global by typing in my own global mask"),"zenPage.doView('');")
	Set pCommands(7) = $LB("btnClasses",$$$Text("Classes"),$$$Text("View classes in this namespace"),"zenPage.changePage('C');")
	Set pCommands(8) = $LB("btnRoutines",$$$Text("Routines"),$$$Text("View routines in this namespace"),"zenPage.changePage('R');")

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

/// <var>pInfo</var> holds details on how to create the query.
Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pRS = ""
	Set Query = "%SYS.GlobalQuery:NameSpaceList"
	If ($E($namespace)="^") Set Query = "%SYS.GlobalQuery:DirectoryList"
	Set pRS = ##class(%ResultSet).%New(Query)
	Quit pRS
}

/// Method for executing the global query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSpec = %page.GlobalSpec
	Set tShowSys = %page.ShowSys
	Set EventDesc = $$$EventDescription
	Set EventData = $$$CRLF_tSpec_$$$CRLF_$$$Text("Show System items: ")_tShowSys
	#; if implied namespace use directory
	If ($E($namespace)="^") {
		Set tDir = $P($namespace,"^",3),tSystem = $p($namespace,"^",2) 
		Set EventData = tDir_$$$CRLF_tSystem_EventData
		Set tSC = pRS.Execute(tDir,tSystem,tSpec,tShowSys,,1) 
	} Else {
		Set EventData = $namespace_EventData
		Set tSC = pRS.Execute($namespace,tSpec,tShowSys,.UnavailableDatabases,,1)
	}
	$$$SMPAuditView
	Quit tSC
}

ClientMethod changePage(newPage) [ Language = javascript ]
{
	var namespaceValue = this.getSelectedNamespace();
	var pageurl = (newPage == "C") ? this.ClassURL : this.RoutineURL;
	document.location = pageurl + "?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&SQL=" + (this.ShowSQL === true ? 1 : 0);
}

ClientMethod doDelete() [ Language = javascript ]
{
	var table = zen("table");
	var total = table.getProperty("rowCount");	
	if (total < 1) {
		alert($$$Text("Nothing to delete."));
		return;	
	}
	var namespaceValue = this.getSelectedNamespace();	
	var selectedRows = table.selectedRows;
	var exportAll = 0;
	var ok = this.PrepareSelection(this.FILETYPE,selectedRows);
	if (ok == 0) {
		alert($$$Text("No globals were selected for deletion."));
		return;
	}
	ok = confirm($$$Text("Are you sure you want to delete the selected globals?"));
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
	var selectedRows = table.selectedRows;
	var exportAll = 0;
	var ok = this.PrepareSelection(this.FILETYPE,selectedRows);
	if (ok == 0) {
		alert($$$Text("No export globals were selected."));
		return;
	}
	var parms = {
			MODE:"models",
			FILETYPE:this.FILETYPE,
			EXPORTALL:exportAll,
			$NAMESPACE:namespaceValue
	};
	//open dialog for compile criteria
	zenLaunchPopupWindow(zenLink('%CSP.UI.Portal.Dialog.Export.zen'),'Export','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod doImport() [ Language = javascript ]
{
	var namespaceValue = this.getSelectedNamespace();	
	var parms = {
			FILETYPE:this.FILETYPE,
			$NAMESPACE:namespaceValue
	};
	
	//open dialog for compile criteria
	zenLaunchPopupWindow(zenLink('%CSP.UI.Portal.Dialog.Import.zen'),'Import','status,scrollbars,resizable=yes,width=610,height=700',parms);
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
		alert($$$Text("No globals were selected."));
		return;
	}
	///open Find page in a seperate window.
	var win = window.open(this.FindPage+"?$NAMESPACE="+encodeURIComponent(namespaceValue)+"&rep="+isReplace+"&cbAction=Global",'FindString');
	win.focus();
}

ClientMethod doView(globalName) [ Language = javascript ]
{
	var namespaceValue = this.getSelectedNamespace();	
	var urlpage = this.ViewGlobalURL + "?$ID2=" + encodeURIComponent(globalName) + "&$NAMESPACE=" + encodeURIComponent(namespaceValue);
	var win = window.open(urlpage,'','status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
	win.focus();
}

ClientMethod doEdit(globalName) [ Language = javascript ]
{
	var namespaceValue = this.getSelectedNamespace();	
	var urlpage = this.EditGlobalURL + "?$ID2=" + encodeURIComponent(globalName) + "&$NAMESPACE=" + encodeURIComponent(namespaceValue);
	var win = window.open(urlpage,'','status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
	win.focus();
}

/// Load Nemespace list or Database list
ClientMethod doList(nd) [ Language = javascript ]
{
	var selNamespace = zen("selNamespace");	
	if (nd == "Namespace") {
		var valueList = this.GetList();
		selNamespace.setProperty("valueList",valueList);
		selNamespace.setProperty("displayList",valueList);
		if (this.writePERMISSION) {
			this.enableCommandButton("btnImport");
		}
	} else {
		var displayList = this.GetDBList();
		selNamespace.setProperty("valueList",displayList);
		selNamespace.setProperty("displayList",displayList);
		this.disableCommandButton("btnImport");
	}
}

///  Changed Namespace <==> Database (implied namespace).
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
		var spec = zen("txtSpec").getValue();
		var showsys = zen("chkShowSys").getValue();
		var showgen = 0;
		//var begindate = zen("beginDate").getValue();
		//var enddate = zen("endDate").getValue();
		showsys = (showsys == true) ? 1 : 0;
		var maxRows = zenTrim(zen("maxRows").getValue());
		if ((maxRows == "") || (isNaN(maxRows)==true) || (parseInt(maxRows) > 10000)) {
			maxRows = 10000;
			zen("maxRows").setValue(maxRows);
		}
		var ok = this.SaveSelections(this.FILETYPE,selType,spec,showsys,showgen,'','',maxRows);
		var urlpage = this.GlobalURL + "?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&SQL=" + (this.ShowSQL === true ? 1 : 0);
		self.document.location = urlpage;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClientMethod doSql() [ Language = javascript ]
{
	try {
		var namespaceValue = this.getSelectedNamespace();
		var urlpage = this.GlobalURL + "?$NAMESPACE=" + encodeURIComponent(namespaceValue) + "&SQL=" + (zen("chkShowSql").getValue() === true ? 1 : 0);
		self.document.location = urlpage;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// User clicked Go to start search. 
ClientMethod doSearch() [ Language = javascript ]
{
	var selType = zen("selType").getValue();
	var spec = zen("txtSpec").getValue();
	if (spec == "") {
		if (this.FILETYPE == "Global") spec = "*"
		zen("txtSpec").setValue(spec);
	}

	var showsys = zen("chkShowSys").getValue();
	var showgen = 0;
	//var begindate = zen("beginDate").getValue();
	//var enddate = zen("endDate").getValue();
	showsys = (showsys == true) ? 1 : 0;
	var maxRows = zenTrim(zen("maxRows").getValue());
	if ((maxRows == "") || (isNaN(maxRows)==true) || (parseInt(maxRows) > 10000)) {
		maxRows = 10000;
	} else {
		maxRows = Math.round(maxRows);
	}
	zen("maxRows").setValue(maxRows);
	var ok = this.SaveSelections(this.FILETYPE,selType,spec,showsys,showgen,'','',maxRows);
	var RecentURLs = this.GetRecentList("Global");
	zen("txtSpec").setProperty("valueList",RecentURLs);

	this.GlobalSpec = spec;
	this.ShowSys = showsys;
	this.ShowGen = showgen;
	//this.BeginDate = begindate;
	//this.EndDate = enddate;
		
	var table = zen("table");
	table.setProperty("maxRows",maxRows);
	table.executeQuery(0);
	// put it to the same column order as last one user clicked.
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	// update the time.
	this.updateTime();
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
		self.document.location = this.GlobalURL + '?$NAMESPACE=' + encodeURIComponent(value);
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
	Set LastSearch =$G($$$IRISTempMgt($Username,"Global"))
	If LastSearch = "" Set LastSearch = "Namespace^*^0^0^^^1000"
	If $P(LastSearch,"^",2) = "" Set $P(LastSearch,"^",2) = "*"
	Quit LastSearch
}

/// Delete selected globals now.
ClassMethod Delete(filetype) As %String [ ZenMethod ]
{
	#; for globals we use delimiter "^" instead of ","
	Set tResult = ""
	Set EventDesc = $$$EventDescription_" Delete"
	Set tRow = $O(%session.Data($Username,filetype,"selectedRows",""))
	While tRow '= "" {
		Set selectedRows = %session.Data($Username,filetype,"selectedRows",tRow)
		Set n = 1
		Set tLen = $L(selectedRows,"^")
		While n '> tLen {
			Set tName = $P(selectedRows,"^",n)
			If tName '= "" {
				Set tName = "^"_tName
				Set tItems(tName) = ""
				Set tSC = ##class(%Studio.Global).Kill(tName, 1)
				If $$$ISERR(tSC) Set tResult = $S(tResult'="":tResult_"\n",1:"")_$System.Status.GetErrorText(tSC)
			}
			Set n = n + 1
		}
		Set tRow = $O(%session.Data($Username,filetype,"selectedRows",tRow))
	}
	Set EventData = "Delete globals: "_$$$CRLF
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
	if (!this.writePERMISSION) {
		this.disableCommandButton("btnDelete");
		this.disableCommandButton("btnImport");
		this.disableCommandButton("btnReplace");
	}
}

/// Pad selected items into string delimited by "^" before calling PrepareAction.
ClassMethod PrepareSelection(pFILETYPE, pSelectedRows) As %String [ ZenMethod ]
{
	Set selectedRows = ""
	For n = 1:1:$L(pSelectedRows,",") If $P(pSelectedRows,",",n) '= "" Set selectedRows = selectedRows _ $S(selectedRows'="":"^",1:"") _ $P(pSelectedRows,",",n)
	Quit ..PrepareAction(pFILETYPE,selectedRows)
}

}
