/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// <p>This is the template for SMP pages with a Search pane on the left and Result pane on the right.
/// It is primarily used by the System Explorer's Classes/Routines/Globals list pages.</p>
Class %CSP.UI.Template.List Extends %CSP.UI.Portal.Utils [ Abstract, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Template List";

/// If true, the search area is visible.
Property searchExpanded As %Boolean [ InitialExpression = 1, Internal ];

Property ShowSys As %Boolean [ InitialExpression = "0" ];

Property ShowGen As %Boolean [ InitialExpression = "0" ];

Property ShowMap As %Boolean [ InitialExpression = "1" ];

Property BeginDate As %String;

Property EndDate As %String;

Property MaxRows As %String;

Property ClassURL As %String;

Property GlobalURL As %String;

Property RoutineURL As %String;

Property DocPage As %String;

Property NamespaceList As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* light green for Explorer pages
.ribbonTitle {
	background: #C5E5C9;
}*/
/* div around results table */
#searchGroup {
	background: #F0F0F0;
	padding-left: 3px;
	padding-right: 5px;
	border-bottom: 1px solid gray;
	border-right:  1px solid gray;
}
#searchPane {
	padding-left: 3px;
	padding-right: 5px;
	overflow: hidden;
	overflow-y: auto;
}
#table {
	width:100%;	
}
.optionLabel {
	color: #202020;
	font-size: 11px;
}
.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: #3b84bc;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}
a.cmdLink {
	font-size: 10pt;
	font-weight: normal;
	font-variant: small-caps;
	color: #356b8d;
	padding-left: 6px;
	padding-right: 6px;
}

</style>
}

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup width="100%">
<html id="modelTableHeader" OnDrawContent="DrawTableHeader"></html>
<hgroup id="mainGroup" cellVAlign="top">
<hgroup id="searchGroup" valign="top">
<pane id="searchPane" paneName="searchPane"/>
<html id="searchExpander" valign="top">
<span id="spanArrow" title="Hide or show the search box" 
onclick="zenPage.toggleSearch();" 
onmouseover="this.style.color='#356B8D';this.style.cursor='pointer'" 
onmouseout="this.style.color='';this.style.cursor='';">&#171;</span>
</html>
</hgroup>
<group id="resultGroup" valign="top">
<pane id="resultPane" paneName="resultPane" />
</group>
</hgroup>
</vgroup>
</pane>
}

/// This pane displays the search criteria. We provide defaults and user can change them.
/// User's values are saved and used as future defaults for this user.
/// Subclass to override.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >

<form name="searchForm" id="searchForm" layout="vertical" cellStyle="padding: 2px 10px; font-size:0.8em;">
</form>

</pane>
}

/// Subclass to override. Always include code in this method.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set:$G(%request.Data("$NAMESPACE",1))'="" %session.Data("$NAMESPACE") = %request.Data("$NAMESPACE",1)
	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($ZCVT("%CSP.Portal.Home","O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL")))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Toggle display of propertis pane.
ClientMethod toggleDetails() [ Language = javascript ]
{
	this.detailsExpanded = !this.detailsExpanded;
	var span = self.document.getElementById('spanArrowDetails');
	if (this.detailsExpanded) {
		span.innerHTML = '&#187;';
	}
	else {
		span.innerHTML = '&#171;';
	}
	this.adjustSizes();
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var searchDiv = zen('searchPane').getEnclosingDiv();
		searchDiv.style.display = 'block';
		
		// find size of window
		var winWidth = zenGetWindowWidth();
		var propWidth = (this.searchExpanded) ? 190 : 5;
		var resultWidth = winWidth - propWidth - 50;
		resultWidth = Math.max(resultWidth,100);
		zen('resultPane').getEnclosingDiv().style.width = resultWidth + 'px';
		searchDiv.style.width = propWidth + 'px';
		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

ClientMethod showExpand() [ Language = javascript ]
{
	var span = self.document.getElementById('spanArrow');
	if (this.searchExpanded) {
		// left arrow - click to hide
		span.innerHTML = '&#171;';
		span.title = $$$Text("Hide the search criteria box");
	}
	else {
		// right arrow - click to show
		span.innerHTML = '&#187;';
		span.title = $$$Text("Show the search criteria box");
	}
}

/// Toggle display of search pane.
ClientMethod toggleSearch() [ Language = javascript ]
{
	this.searchExpanded = !this.searchExpanded;
	this.showExpand();
	this.adjustSizes();
	if (this.onresizeHandler) { this.onresizeHandler(); }
	var expandstate = (this.searchExpanded) ? 1 : 0;	
	this.SaveExpandState(this.FILETYPE,expandstate);
}

ClientMethod doDoc(className) [ Language = javascript ]
{
	var selType = zen("selType").getValue();
	if (selType == "Database") {
		alert($$$Text("Unable to display class documentation for this class. Make sure you have selected a namespace and not a database."));
		return;	
	}
	var tNS = zen("selNamespace").getValue();
	var tClass = className.substring(0,className.length-4);
	var url = this.DocPage + "?LIBRARY=" + cspEncodeUTF8(tNS) + "&CLASSNAME=" + cspEncodeUTF8(tClass);
	document.location = url;
}

/// User clicked Go to start search. 
ClientMethod doSearch() [ Language = javascript ]
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
		zen("maxRows").setValue(maxRows);
	}
	this.SaveSelections(this.FILETYPE,selType,spec,showsys,showgen,begindate,enddate,maxRows,showmap);
	var RecentURLs = this.GetRecentList("Class");
	zen("txtSpec").setProperty("valueList",RecentURLs);

	this.ClassSpec = spec;
	this.ShowSys = showsys;
	this.ShowGen = showgen;
	this.ShowMap = showmap;
	this.BeginDate = begindate;
	this.EndDate = enddate;
		
	var table = zen("table");
	table.setProperty("maxRows",maxRows);
	table.executeQuery(0);
}

/// Return Namespace list for UI's valueList.
ClassMethod GetNSList() As %String [ ZenMethod ]
{
	
	Set tCnt = ##class(%CSP.Util.SMNavigatorPane).GetAllNamespaces(.Namespaces)
	Set valueList = "" 
	For i=1:1:tCnt {
		Set valueList = valueList _ $S(valueList'="":",",1:"") _ Namespaces(i)
	}
	Quit valueList
}

/// Return Database list for UI's displayList. valueList (should not be loaded into <select> due to directory delimiters)
/// is saved into %session for later use.
ClassMethod GetDBList() As %String [ ZenMethod ]
{
	Set tCnt = ##class(%CSP.Util.SMNavigatorPane).GetAllDatabases(.Databases)
	Set displayList = ""
	Set dbName = $O(Databases(""))
	While dbName '= "" {
		Set tValue = Databases(dbName)
		Set tSystem = $P(tValue,"^",2)
		Set tDisplay = dbName_$S(tSystem="":"",1:"@"_tSystem)
		Set displayList = displayList _ $S(displayList'="":",",1:"") _ tDisplay
		Set dbName = $O(Databases(dbName))
	}

	#; save the cross reference for FindDBDir.
	Kill %session.Data("DBList")
	Merge %session.Data("DBList") = Databases
	Quit displayList
}

/// Get recent list for file spec. FILETYPE = "Class", "Routine", or "Global".
ClassMethod GetRecentList(FILETYPE) As %String [ ZenMethod ]
{
	Set valueList = ""
	Set tRecent = $order($$$IRISTempMgt($Username,FILETYPE,"Recent",""))
	While (tRecent '= "") {
		Set valueList = valueList_$S(valueList'="":",",1:"")_tRecent
		Set tRecent = $order($$$IRISTempMgt($Username,FILETYPE,"Recent",tRecent))
	}
	Quit valueList
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

/// In case user clicked the browser's Back button we need to make sure the value in drop-down is correct
/// This method is called from onloadHandler for ClassList/RoutineList/GlobalList...that has Lookin and namespace/database list
ClientMethod checkURLNamespace() [ Language = javascript ]
{
	var namespaceValue = zen("selNamespace").getValue();	
	if (this.NAMESPACE != "" && this.NAMESPACE != namespaceValue) {
		namespaceValue = this.NAMESPACE;
		// if $NAMESPACE is implied namespace then change the Lookin type to Namesapce also
		if (namespaceValue.substring(0,1) == "^") {
			zen("selType").setValue("Database");	
		} else {
			zen("selType").setValue("Namespace");
		}
		if (zen("selType").getValue() == "Database") {
			namespaceValue = this.FindDBName(namespaceValue);
		}
		zen("selNamespace").setValue(namespaceValue);
	};
}

/// See if the DBName passed in can be found in the namespace list.<br/>
/// This is used when changing from "Database" to "Namespace".<br/>
/// So we can use the same name if there is a match. 
ClientMethod findNSMatch(DBName) [ Language = javascript ]
{
	var findMatch = "";
	var nsArray = this.NamespaceList.split(",");
	for (var i=0; i<nsArray.length; i++) {
		if (nsArray[i] == DBName) {
			findMatch = nsArray[i];
			break;
		}
	}
	// if we cannot find a match then return the first one we can find.
	if (findMatch=="") findMatch = nsArray[0];
	return findMatch;
}

/// Given a DBName, return the DBDirectory. If we cannot find it, then return the first one we can find.
ClassMethod FindDBDir(DBName) As %String [ ZenMethod ]
{
	#; this could be the case when changing Namespace to Database and %SYS is the current selected namespace so change it to CACHE
	If DBName = "%SYS" Set DBName = "IRISSYS"	
	#; if DBName contains System name (which is a displayname), strip it here so we can find the correct directory
	Set DBName = $P(DBName,"@",1)
	If $G(%session.Data("DBList",DBName)) '= "" Quit $G(%session.Data("DBList",DBName))
	Set FirstDB = $O(%session.Data("DBList",""))
	#; In case there is nothing, then return what's passed in.
	If FirstDB = "" Quit DBName
	Quit $G(%session.Data("DBList",FirstDB))
}

/// Given a DBDirectory, return the DBName
ClassMethod FindDBName(DBDirectory) As %String [ ZenMethod ]
{
	Set DBName = ""
	For  Set DBName = $O(%session.Data("DBList",DBName)) If $G(%session.Data("DBList",DBName))=DBDirectory Quit
	Quit DBName
}

/// If at least one subject (Class/Routine/Global/Integ/IntegGlobals, etc) is selected, then save it into session
ClassMethod PrepareAction(FILETYPE, selectedRows) As %String [ ZenMethod ]
{
	KILL %session.Data($Username,FILETYPE,"selectedRows")
	Set ok = 0
	Set tDelimiter = $S(FILETYPE'="Global":",",1:"^")
	#; When selectedRows reach certain size, when it comes here it becomes %Stream.GlobalCharacter object.
	#; We need to read through it and save in to temp globals for future use.
	If $IsObject(selectedRows) {
		Set n = 0
	 	While 'selectedRows.AtEnd {
		 	Set n = n + 1
	 		Set line = selectedRows.ReadLine(10000)
			Set %session.Data($Username,FILETYPE,"selectedRows",n)=line
		}
		#; Because the ReadLine may cut off a class name, we need to
		#; combine the last piece of the first line with the next line's first piece and 
		#; set it to the next line's first piece, and set the last line's last piece to null.
		#; This way we have completely useable class names.
		Set m = 1
		While m < n {
			Set a1 = %session.Data($Username,FILETYPE,"selectedRows",m)
			Set a2 = %session.Data($Username,FILETYPE,"selectedRows",m+1)
			Set x = $P(a1,tDelimiter,*)_$P(a2,tDelimiter,1)
			Set $P(%session.Data($Username,FILETYPE,"selectedRows",m),tDelimiter,*) = ""
			Set $P(%session.Data($Username,FILETYPE,"selectedRows",m+1),tDelimiter,1) = x
			Set m = m + 1	
		}		
	} Else {
		Set %session.Data($Username,FILETYPE,"selectedRows",1)  = selectedRows
		Set n = 1
	}
	Set %session.Data($Username,FILETYPE,"selectedRows") = n
	Set n = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
	Set tTotal = 0
	While n '= "" {
		Set tRow = %session.Data($Username,FILETYPE,"selectedRows",n)
		For m=1:1:$L(tRow,tDelimiter) Set tItem = $P(tRow,tDelimiter,m) If tItem'="" Set tTotal = tTotal + 1
		Set n = $O(%session.Data($Username,FILETYPE,"selectedRows",n))
	}
	Set %session.Data($Username,FILETYPE,"TotalSelected") = tTotal
	If tTotal > 0 Quit 1
	Else  Quit 0
}

/// Save user selection from Search Pane for Classes, Routines, and Globals, etc.
ClassMethod SaveSelections(FILETYPE, selType, spec, showsys, showgen, begindate, enddate, maxRows, AllowSelectRow = 0, showmap = 0, AlwaysFullView = 0) As %String [ ZenMethod ]
{
	Set tExecuteSpec = spec
	If FILETYPE="Class",$E(spec,$L(spec)-3,$L(spec)) '= ".cls" Set spec = spec_".cls"
	Set $$$IRISTempMgt($Username,FILETYPE) = selType_"^"_spec_"^"_showsys_"^"_showgen_"^"_begindate_"^"_enddate_"^"_maxRows_"^"_AllowSelectRow_"^"_showmap_"^"_AlwaysFullView
	Set $$$IRISTempMgt($Username,FILETYPE,"Recent",spec) = $zdt($h,3)
	If FILETYPE = "Routine" {
		#; The spec must have routine extension at the end otherwise it will return all types.
		#; VMS files have ";" and we need to add * to it to get all versions.
		If spec [ ";" Set tExecuteSpec = $P(spec,";",1) _ ";*"
		Else  Set tExecuteSpec = ##class(%CSP.Util.ExpPane).GetMask(spec)
		Set $$$IRISTempMgt($Username,FILETYPE,"ExecuteSpec") = tExecuteSpec
	}
	// clean up recent URL list
	// sort list by time, delete oldest...
	Set tCount = 0
	Set tRecent = $order($$$IRISTempMgt($Username,"Recent",FILETYPE,""))
	While (tRecent '= "") {
		Set tCount = tCount + 1
		Set tSort($$$IRISTempMgt($Username,"Recent",FILETYPE,tRecent)) = tRecent
		Set tRecent = $order($$$IRISTempMgt($Username,"Recent",FILETYPE,tRecent))
	}
	
	// remove oldest items (there are up to 10)
	While (tCount > 10) {
		Set tOld = $order(tSort(""))
		Kill $$$IRISTempMgt($Username,"Recent",FILETYPE,tSort(tOld))
		Set tCount = tCount - 1
	}
	Quit tExecuteSpec
}

ClassMethod SaveExpandState(FILETYPE, searchExpanded) [ ZenMethod ]
{
	Set %session.Data($Username,FILETYPE,"searchExpanded") = searchExpanded
}

ClassMethod GetExpandState(FILETYPE) As %String
{
	Quit $G(%session.Data($Username,FILETYPE,"searchExpanded"),1)
}

/// Proposed change to override %ChangeNS in %ZEN.Controller
/// For SMP Explorer, we need to override the behavior of changing Namespace so that the error reporting is more appropriate.
ClassMethod %ChangeNS(pNS As %String) As %Status
{
	// change from namespace to implied namespace or v.v.
	Set tNSMODE = $S($E(pNS,1,2)="^^":"implied",1:"namespace")
	Set tNS = ##class(%CSP.Util.AutoPage).ChangeNamespace(pNS,tNSMODE)
	// if NS got changed, pass on new value
	Set %request.Data("$NAMESPACE",1) = tNS

	// make sure we pass this information along
	Set %response.Context("$NAMESPACE") = tNS
}

}
