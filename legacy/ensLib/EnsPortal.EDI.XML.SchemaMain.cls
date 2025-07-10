/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIXML

Class EnsPortal.EDI.XML.SchemaMain Extends EnsPortal.EDI.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "XML Schemas";

/// User must have WRITE permissions on the %Ens_EDISchema resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_EDISchema:WRITE";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css,ensemble/Ensemble_EDI.css";

Property Status As %String;

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

/// Id of selected Category row in results table.
Property Category As %ZEN.Datatype.string(ZENURL = "CAT");

/// flag for background file import underway on load
Property underway As %String;

Property tipRefresh As %String [ InitialExpression = {$$$TextHTML("Refresh status")} ];

/// Whether or not the browser is IE
Property IE As %Boolean;

XData Style
{
<style type="text/css">

#searchPanel {
	/*width: 300px;*/
	padding-left: 5px;
	padding-right: 5px;
	background: #edece4;
	overflow: hidden;
	overflow-y: auto;
}

table.tpTable tr.tpEven {
	background: white;
}

table.tpTable tr.tpOdd {
	background: #F1F0E7;
}

table.tpTable tr.tpSelected {
	background: rgb(47,98,128);
	color: white;
}

table.tpTable tr.tpSelected td {
	font-weight: bold;
}

table.tpTable td {
	padding-right:10px;
}

table.tpTable {
	width: auto;
}

.searchPanelText {
	color: #404040;
	font-size: 10pt;
	text-align: center;
	padding: 3px;
	padding-top: 20px;
	padding-bottom: 20px;
}

.titlePane {
	color: #606060;
	font-family: Arial, Helvetica, sans-serif;
	font-weight: bold;
	background: none;
	width: 100%;
	padding: 0px;
	border-bottom: 1px solid silver;
	font-size: 12pt;
	text-align: center;
}

.zenLabel {
	color: #404040;
	font-size: 10pt;
}

a.radioSetCaption {
	vertical-align: top;
	text-decoration: none;
	color: #404040;
	font-size: 10pt;
}

.formLabel {
	color: #404040;
	font-size: 10pt;
	font-weight: bold;
}

a.resultsAction {
	font-size: 11px;
	color: #3b84bc;
	text-decoration: none;
}

a.resultsAction:hover {
	color: darkred;
}

td.resultsRowNo {
	color: #808080;
	text-align: left;
}

.resultsRowSelected a.resultsAction {
	color: white;
}

.resultsRowSelected a.resultsAction:hover {
	color: orange;
}

.resultsRowMouseover, .tpMouseOver {
	background: #FFEEAA;
}

/* expanded details within table */
table td.detailsBox {
	padding: 0px;
	height: 200px;
	background: white;
	border: 1px solid black;
}

table.detailsTable {
	width: 100%;
}
/* selected row after "Details" is clicked */
table tr.detailsTableHeader {
	background: rgb(47,98,128);
	color: white;
	font-size: 12px;
}

/* details pane style */
#detailsGroup {
	background: #EDECE4;
	color: #606060;
	padding-left: 5px;
	padding-right: 5px;
	overflow: auto;
	border-left: 1px solid gray;
}
#searchGroup {
	background: #EDECE4;
	padding-left: 5px;
	padding-right: 5px;
	border-right: 1px solid gray;
}

/* styles for message details */
table.AutoFormTable {
	color: #606060;
	background: white;
	border: 1px solid black;
	padding: 0px;
	font-size: 12px;
}

table td.AutoFormTableCaption {
	font-weight: bold;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

table td.AutoFormTableValue {
	border-bottom: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

#detailExpanderLink {
	margin-right: 5px;
}

div.dimmer
{
    visibility:hidden;
    position:absolute;
    left:0px;
    top:0px;
    width:600px;
    height:300px;
    font-family:verdana;
    font-weight:bold;
    padding:40px;
	color: #606060;
	background-color: #000;
    background-color: rgba(0,0,0,0.5);
}

table.progress
{
    position:absolute;
    left:20px;
    top:30px;
    width:518px;
    height:287px;
    font-family:verdana;
    font-weight:bold;
    padding:40px;
	color: #606060;
	background: white;
	opacity:1;
}

/* @doc="Wrapper for body of tabgroup, when tab bar is shown." */
.tabGroupBody {
	background: white;
	border-right: 1px solid black;
	border-left: 1px solid black;
	border-bottom: 1px solid black;
	min-height: 400px;
	overflow: scroll;
}


</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup cellVAlign="top"  width="90%">
<hgroup id="searchGroup" valign="top">
<spacer width="20"/>
</hgroup>
<pane id="resultsPanel" paneName="resultsPane" width="600px" />
<hgroup id="detailsGroup">
<spacer width="10"/>
<pane id="detailsPanel" paneName="detailsPane"/>
</hgroup>
</hgroup>
<html>
<div id="divDimmer" class="dimmer">
<table id="tblProgressBox" class="progress">
<tr><td id="lblProgress" colspan="2">Importing...</td></tr>
<tr id ="trStatus" style="white-space:nowrap"><td id="progressText">In Progress:</td><td id="lblDuration" >0 seconds elapsed</td>
<td><image id="refreshStatus" style="display:none;" src="deepsee/loop_24.gif" class="icon" title="#(%page.tipRefresh)#" onclick="zenPage.timerStatus('',1);" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/></td>
</tr>
<tr><td><input id="btnSubmit" type="button" value="Cancel" onclick="zenPage.progressSubmit();" style="width: 119px"/></td></tr>
</table>
</div>
</html>
</pane>
}

XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<vgroup valign="top">
<spacer height="10" />
<tablePane id="table" 
	cellSpacing="2"
	dataSource="columns"
	queryClass="EnsLib.EDI.XML.Schema"
	queryName="TypeCategories"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="Category"
	maxRows="2000"
	nowrap="false"
	onselectrow="zenPage.updateRowVals(zenThis);"
	showValueInTooltip = "true"
	>
<column header="Category" colName="Category" />
<column header="Description" colName="Description" OnDrawCell="DrawSchemaDescription"/>
</tablePane>
</vgroup>
</pane>
}

XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<vgroup>
<spacer height="10"/>
<tabGroup id="detailsTabGroup" showTabBar="true" remember="true" width="100%" onshowTab="zenPage.onTabChange();" >
<tab id="tabDocTypes" caption="DocType Structures" title="Document type structures">
<html id="htmlDocTypes" OnDrawContent="DrawDocTypesContent" />
</tab>
<tab id="tabComplexTypes" caption="Complex Type Structures" title="Complex Type structures">
<html id="htmlComplexTypes" OnDrawContent="DrawComplexTypesContent" />
</tab>
<tab id="tabCompGroups" caption="Group Structures" title="Component Group structure definitions">
<html id="htmlCompGroups" OnDrawContent="DrawCompGroupsContent" />
</tab>
<tab id="tabSimpleTypes" caption="SimpleTypes" title="XML Simple Type definitions">
<html id="htmlSimpleTypes" OnDrawContent="DrawSimpleTypesContent" />
</tab>
</tabGroup>
<spacer height="10"/>
</vgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
/// Start the timer so we can check the status. If there is a
/// background import job currently running,
/// you will see a periodic update until the job is finished.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);

	// Ensure that tab content is correctly initialised
	if (!this.Category || this.Category.length <= 0) {
		this.Category = '';
	}
	var table = zenPage.getComponentById('table');
	table.selectRow(zenPage.findCatRow(table,this.Category));
	this.onTabChange();

	document.getElementById('divDimmer').style.width = window.screen.width + 'px';
	document.getElementById('divDimmer').style.height = window.screen.height + 'px';

	if (zenPage.underway != '') {
		zenPage.showProgressDiv($$$FormatText($$$Text('Resuming wait for background import of file %1'),zenPage.underway));
		if (zenPage.enableAutoRefresh) {
			zenPage.startStatusTimer();
		} else {
			zenPage.timerStatus();
		}
	}
}

ClientMethod findCatRow(table, cat) [ Language = javascript ]
{
	if (cat == '' || !table || (typeof table != 'object')) { // got passed the tablePane object
		return 0;
	}
	for (var i=0; i<table.rowCount; i=i+1) {
		var row = table.getRenderedRowData(i);
		if (row.Category == cat) return i;
	}
	return 0
}

ClientMethod updateRowVals(table) [ Language = javascript ]
{
	this.Category = (table && (typeof table == 'object')) ? table.getValue() : '' // got passed the tablePane object
	this.onTabChange();
}

ClientMethod showProgressDiv(title) [ Language = javascript ]
{
	document.getElementById('divDimmer').style.visibility = "visible";
	var tdLbl=document.getElementById('lblProgress');
	tdLbl.innerHTML = title;
}

ClientMethod startStatusTimer(timeout) [ Language = javascript ]
{
	if (!timeout || timeout == '0' || timeout == 0) { timeout = 1000; }
	document.getElementById('btnSubmit').value=$$$Text("Cancel");
	if (this.enableAutoRefresh) {
		zenPage.statusTimerId = window.setTimeout('zenPage.timerStatus();',timeout);
	}
}

ClientMethod progressSubmit() [ Language = javascript ]
{
	if (zenPage.progressStatus == 'running') {
		zenPage.KillImport();
	} else {
		zenPage.KillImportStatus();
	}
	if ('' != zenPage.statusTimerId) window.clearTimeout(zenPage.statusTimerId);
	document.getElementById('divDimmer').style.visibility = "hidden";
	document.getElementById('trStatus').innerHTML = '<td>In Progress:</td><td id="lblDuration" >0 seconds elapsed</td>'; // restore contents after error
}

ClassMethod FileExists(filename As %String) As %String [ ZenMethod ]
{
	Quit ##class(%File).Exists(filename)
}

/// This function controls the timer on updating progress.
/// It is called from onload as well (in case a background import job is currently being run when the page is opened).
ClientMethod timerStatus(timer, refresh) [ Language = javascript ]
{
	// get and use the status of the background import job
	var status = zenPage.GetImportStatus();
	if (!status) status = 'err|' + $$$Text("Server Session Error") + '|' + $$$Text('unknown') + '|' + $$$Text('unknown');

	status=status.split('|');
	switch (status[0]) {
		case 'running':
			var durationLabel = document.getElementById('lblDuration');
			if (this.enableAutoRefresh) {
				durationLabel.innerHTML = status[2];
				document.getElementById('progressText').innerHTML = $$$Text("In Progress:");
				zenPage.startStatusTimer();
				zenPage.showProgressDiv($$$FormatText($$$Text('Importing file %1'),status[1]));
			} else {
				durationLabel.style.display = "none";
				document.getElementById('refreshStatus').style.display = "";
				document.getElementById('progressText').innerHTML = $$$Text("In progress.  Click to check if complete:");
				if ((zenPage.underway == "")||refresh) { zenPage.showProgressDiv($$$FormatText($$$Text('Importing file %1'),status[1]));}
			}
			return;
		case 'err':
		case 'error':
			document.getElementById('trStatus').innerHTML = '<td colspan=2>'+status[3]+'</td>';
			document.getElementById('btnSubmit').value=$$$Text("OK");
			break;
		case 'done':
			document.getElementById('divDimmer').style.visibility = "hidden";
			//zen('table').renderContents();
			alert($$$FormatText($$$Text('Imported category %1 from file %2'),status[3],status[1]));
			if ('' != zenPage.statusTimerId) window.clearTimeout(zenPage.statusTimerId);
			zenPage.statusTimerId = '';
			zenPage.Category = status[3];
			zenPage.gotoPage("EnsPortal.EDI.XML.SchemaMain.zen");
			return;
		case 'idle':
			document.getElementById('divDimmer').style.visibility = "hidden";
			break;
		default:
			alert("Unexpected import status:'" + status[0] + "'");
			break;
	}
	if ('' != zenPage.statusTimerId) window.clearTimeout(zenPage.statusTimerId);
	zenPage.statusTimerId = '';
	return;
}

ClassMethod KillImport() [ ZenMethod ]
{
	Set tJob=$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","job"))
	If ""'=tJob Do $ZU(4,tJob)
	Kill ^IRIS.Temp.XML.Import($ZNSpace,$Username)
}

ClassMethod KillImportStatus() [ ZenMethod ]
{
	Kill ^IRIS.Temp.XML.Import($ZNSpace,$Username)
}

/// Use when the import job is running in the background to check on running status.
/// Returns "running", "idle", "done" or "error".
ClassMethod GetImportStatus() As %String [ ZenMethod ]
{
	Set stat = $G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status"),"undef")
	Set:stat=$$$OK tCat=$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","cat")), ^EnsPortal.Settings($Username,"XML","CurrentDrawSchema") = tCat
	Quit $Case(stat
		, "undef":"idle"
		, "":"running|"_$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","file"))_"|"_..GetRunningDuration()
		, $$$OK:"done|"_$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","file"))_"|"_..GetRunningDuration()_"|"_$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","cat"))
		,:"error|"_$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","file"))_"|"_..GetRunningDuration()_"|"_$$$StatusDisplayString(stat))
}

/// Use when the import job is running in the background to check on status.
/// Gets the number of seconds job has been running (or ran, if complete)
/// and formats it nicely as a string.
ClassMethod GetRunningDuration() As %String
{
	// Get the duration in seconds
	Set stopH = $G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","stop"))
	Set:""=stopH stopH = $H

	Set startH = $G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","start"))
	Set diff = $$$timeHDiff(stopH,startH)

	// Render the duration as desired
	Set min = diff \ 60
	Set sec = diff # 60
	If (min = 0) { Set diff = "" }
	ElseIf (min = 1) { Set diff = min_" "_$$$Text("minute") }
	Else { Set diff = min_" "_$$$Text("minutes") }
	If (sec = 1) { Set diff = diff_" "_sec_" "_$$$Text("second") }
	ElseIf (sec > 1) { Set diff = diff_" "_sec_" "_$$$Text("seconds") }

	Quit diff
}

ClientMethod doImportBrowse() [ Language = javascript ]
{
	zenPage.Status = zenPage.GetImportStatus(); // in case another page has been busy in the meantime
	var statusParts=zenPage.Status.split("|");
	if (statusParts[0] == "running") {
		alert($$$FormatText($$$Text("An import of file '%1' is currently running in the background. Please wait for it to finish."),statusParts[1]));
		self.document.location.reload(); // refresh to show statistics on import operation
		return false;
	}
	if (!this.checkEdit()) {
		return false;
	}
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	parms = {
		Dir:zenPage.GetDefaultDir(),
		wildcard:'*.XSD'
	}
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.fileSelect.zen',this.studioMode),this.addPopupSuffix('XMLImportSelect'),'status,scrollbars,resizable,width=660,height=700',parms);
	// the onPopupAction callback will be called when this dialog completes.
}

ClientMethod doDelete() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }

	var tbl = zen('table');
	var cat = (tbl ? tbl.getValue() : '');
	if (!cat || cat.length <= 0) {
		alert($$$Text("First select a schema category row in the table, then click Delete to delete the category."));
		return;
	}
	if (!confirm($$$FormatText($$$Text("Are you sure you want to delete schema category '%1'?"),cat))) {
		return;
	}
	// A category was selected and confirmed for delete
	err = zenPage.DeleteCategory(cat);
	if (err.length > 0) {
		alert(err);
	} else { // Success: refresh the table
		var old = zenSynchronousMode;
		zenSynchronousMode = true;
		var sync = tbl.executeQuery();
		tbl.selectRow(0); //select first row so deleted category not still showing
		zenSynchronousMode = old;
	}
}

Method DeleteCategory(pCategory As %String) As %ZEN.Datatype.string [ ZenMethod ]
{
	Set tKilled=$D($$$vaSchemaGbl(pCategory))
	Kill $$$vaSchemaGbl(pCategory),$$$vaSchemaDescGbl(pCategory)
	Quit:tKilled ""
	Quit $$$FormatText($$$Text("Could not find schema category %1 to delete."),pCategory)
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'XMLImportSelect':
			if (value != '') zenPage.SetDefaultDir(value);
			if (action == 'ok') {
				var fileExists = zenPage.FileExists(value);
				if (fileExists == 0) {
					setTimeout(function() {
						alert($$$FormatText($$$Text("File not found: %1"),zenEscapeJS(value)));
					}, 50);
					return false;
				}
			}
			// Run XSD imports in the background because some of them take a long time
			var err = this.ImportInBackground(value);
			if (err != '') {
				// this return value is an error message only from LaunchMethod; ordinary errors will come from the background task
				alert(err);
				break;
			}
			if (this.enableAutoRefresh) {
				// set up a timer so we periodically check import job status until done
				var divTitle = $$$FormatText($$$Text('Importing file %1'),value);
				zenPage.startStatusTimer();
				zenPage.showProgressDiv(divTitle);
			} else {
				zenPage.timerStatus();
			}
		break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
		break;
	}
	return true;
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($Username,"ImportExportDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($Username,"ImportExportDir") = ##class(%File).GetDirectory(pPathname, 1)
}

/// Run method Import() in a background job. Return 1 if this works out ok, an error string if there is an error in launching the job.
ClassMethod ImportInBackground(pFilename As %String) As %ZEN.Datatype.string [ ZenMethod ]
{
	Set tSC = ..LaunchMethod("Import",pFilename)
	Quit:$$$ISOK(tSC) ""
	Quit $$$StatusDisplayString(tSC)
}

/// Runs in a background job launched from the method DoImportInBackground()
ClassMethod Import(pFilename As %String)
{
	try {
		If '##class(%File).Exists(pFilename) {
			Set tSC=$$$ERROR($$$EnsErrGeneral,"Unable to open file '"_pFilename_"'")
		} Else {
			// Lock and set globals
			Lock +^IRIS.Temp.XML.Import($ZNSpace,$Username,"status"):2  Set tOK=$Test
			If '$Test  set tSC=$$$ERROR($$$GeneralError,"Cannot acquire lock to start importing SEF file")  Quit

			Kill ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status")
			Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status")=""
			Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","file")=pFilename
			Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","start")=$H
			Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","job")=$J

			// Run the Import method
				Set tSC = ##class(EnsLib.EDI.XML.SchemaXSD).Import(pFilename,.tCatImported)
			// Set and unlock globals
			Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","stop")=$H
			Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","cat")=$G(tCatImported)
			Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status")=tSC
			Kill ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","job")
			Lock -^IRIS.Temp.XML.Import($ZNSpace,$Username,"status")
		}
	} catch {
		Lock -^IRIS.Temp.XML.Import($ZNSpace,$Username,"status")
		Set tSC=$$$SystemError
	}
	Set ^IRIS.Temp.XML.Import($ZNSpace,$Username,"status")=tSC
}

ClassMethod LaunchMethod(pMethod As %String, args...) As %Status [ Final, Internal ]
{
	try {
		#; construct expression to run background method
		Set tExpr = "Job ##class("_$this_")."_pMethod_"("
		Set tArgC = $O(args(""),-1)
		Set tArgList = ""
		For k = 1:1:tArgC {
			Set tArg = $S($D(args(k)):$$$quote(args(k)),1:"")
			Set tArgList = tArgList _ $S(tArgList="":"",1:",") _ tArg
		}
		Set tExpr = tExpr _ tArgList _ ")"

		#; job off method
		X tExpr
		//Set ..BGJob=$ZChild
		
		Set tSC=$$$OK
	} catch {
		Set tSC=$$$SystemError
	}
	Quit tSC
}

/// User clicked on a tab, or selected a new item, so we need to fetch the required content from the server.
ClientMethod onTabChange() [ Language = javascript ]
{
	this.layoutTabGroup();
	var tabGroup = zen('detailsTabGroup');
	var currTab = tabGroup.getCurrTabNo();
	if (!this._tabDisplay) {
		this._tabDisplay = new Object();
	}
	var tabName;
	switch (currTab) {
		case 1: tabName='htmlDocTypes'; break;
		case 2: tabName='htmlComplexTypes'; break;
		case 3: tabName='htmlCompGroups'; break;
		case 4: tabName='htmlSimpleTypes'; break;
		default: tabName='';
	}
	tabGroup.currTabName=tabName;

	if (tabName != '') {
		if (this._tabDisplay[tabName] != this.Category) {
			this.drawTabDetails(this.Category,tabName);
			this._tabDisplay[tabName] = this.Category;
		}
	}
}

ClientMethod drawTabDetails(row As %String, tabName As %String) [ Language = javascript ]
{
	var details = zen(tabName);
	if ((row == '') || (row == null)) {
		details.seed = '';
	} else {
		details.seed = row
	}
	details.refreshContents(true);
}

/// Handle the client-side rendering the of the right hand pane.
/// This is primarily due to IE as it shrinks the contents div without this intervention.
/// The function only adjusts the size of the tab group if not hidden.
ClientMethod layoutTabGroup() [ Language = javascript ]
{
	var detailsGroup = zen('detailsGroup');
	var detailsDiv = detailsGroup.getEnclosingDiv();
	var detailsTabGroup = zen('detailsTabGroup');
	var tabsDiv = detailsTabGroup.getEnclosingDiv();

	var winHeight = zenGetWindowHeight();

	var detailsPanel = zen('detailsPanel');
	var detailsDiv = detailsPanel.getEnclosingDiv();
	var paneWidth = detailsDiv.offsetWidth;

	var tabBar = detailsTabGroup.getTabBarElement();
	var hgt = winHeight - this.getTitleAreaHeight() - tabBar.offsetHeight;
	tabsDiv.style.height = hgt + 'px';

	// prevent IE resize logic
	detailsTabGroup.ieResizeBody = function() { return; };

	var winWidth = zenGetWindowWidth();
	var searchPanel = zen('searchGroup').getEnclosingDiv();
	var resultsPanel = zen('resultsPanel').getEnclosingDiv();

	var tabsWidth = winWidth - searchPanel.offsetWidth - resultsPanel.offsetWidth - 50;
	detailsTabGroup.setBodySize(hgt - 50, tabsWidth);
	//tabsDiv.style.width = detailsDiv.style.width + 'px';

	// ensure all column content is visible in IE8
	zenPage.IE = zenIsIE;
}

ClassMethod DrawDocTypesContent(pCat As %String) As %Status
{
	Quit ..DrawSchemaList(pCat,"DS",$$$FormatText($$$Text("XML DocType structures in Category <b>%1</b>"),pCat))
}

ClassMethod DrawComplexTypesContent(pCat As %String) As %Status
{
	Quit ..DrawSchemaList(pCat,"CT",$$$FormatText($$$Text("XML ComplexType structures in Category <b>%1</b>"),pCat))
}

ClassMethod DrawCompGroupsContent(pCat As %String) As %Status
{
	Quit ..DrawSchemaList(pCat,"CG",$$$FormatText($$$Text("XML Component Group structures in Category <b>%1</b>"),pCat))
}

ClassMethod DrawSimpleTypesContent(pCat As %String) As %Status
{
	Quit ..DrawSchemaList(pCat,"ST",$$$FormatText($$$Text("XML Simple Types in Category <b>%1</b>"),pCat))
}

ClassMethod DrawSchemaList(pCat As %String, pElement As %String, pTitle As %String) As %Status
{
	Quit:((pCat="")||(pElement="")) $$$OK

	Set ^EnsPortal.Settings($Username,"XML","CurrentDrawSchema") = pCat

	// set up values needed in main loop
	Set tMaxLenFound = 0
	Set item="" For { Set item=$O($$$vaSchemaGbl(pCat,pElement,item))  Quit:""=item
		Set itemU=$ZCVT(" "_item,"U")
		Set sorted(itemU,$I(sorted(itemU)))=item
		Set tLenFound = $L(item)
		Set:(tLenFound > tMaxLenFound) tMaxLenFound = tLenFound
	}
	
	// deal with IE8-only issue: it does not automatically allow full width of very wide text, even if there is no whitespace
	If (%page.IE) {
		If (tMaxLenFound > 85) {
			Set tWideColumns = " width=""850px"""
			Set elementsPerRow = 3
		} ElseIf (tMaxLenFound > 70) {
			Set tWideColumns = " width=""725px"""
			Set elementsPerRow = 4
		} ElseIf (tMaxLenFound > 55) {
			Set tWideColumns = " width=""600px"""
			Set elementsPerRow = 4
		} ElseIf (tMaxLenFound > 40) {
			Set tWideColumns = " width=""475px"""
			Set elementsPerRow = 4
		} ElseIf (tMaxLenFound > 25) {
			Set tWideColumns = " width=""350px"""
			Set elementsPerRow = 4
		} Else {
			Set tWideColumns = ""
			Set elementsPerRow = 4
		}
	} Else {
		Set tWideColumns = ""
		Set elementsPerRow = 4
	}

	Set txtNum=$$$Text("Number")
	Set (max,nDups,itemCount)=0
	Set (itemU,i1st,item)=""
	Set zenPage="EnsPortal.EDI.XML.SchemaDocumentStructure"
	Set (lineNum,first)=1

	// display all the items
	&html<
		<div style="padding:20px 0px 20px 0px">#(pTitle)#</div>
		<table cellpadding=0 cellspacing=0>
	>
	For {
		Set prevU=itemU, p1st=i1st, pDups=nDups
		Set itemU=$O(sorted(itemU),1,nDups), i1st=$E(itemU,2)
		Quit:itemU=""
		Set:i1st'=p1st&&'((+itemU=itemU)&&(+prevU=prevU)) itemCount=0,lineNum=lineNum+1
		For iDup=1:1:nDups { Set prev=item, item=sorted(itemU,iDup)
			If itemCount=0 {
				If i1st'=p1st {
					If 'first {
						#; finish previous row & group
						&html<</tr></table></td></tr><tr><td>&nbsp;</td></tr>#($C(13,10))#>
					}
					#; start the new group with a character
					&html<<tr><td valign="top" class="alphaEntry">#($S(+itemU=itemU:txtNum,1:i1st))#&nbsp;</td>
						<td><table class="tpTable" cellpadding=4 cellspacing=0>
							<tr>
					>
					Set p1st=i1st, first=0
				} Else {
					#; finish previous row, start a new row for the same start character
					&html<</tr>#($C(13,10))#<tr>>
				}
			}
			#; continue the row
			Set tDesc=..EscapeHTML(##class(EnsLib.EDI.XML.Schema).GetDescription(pElement_":"_pCat_":"_item))
			Set tooltip = $S(""'=tDesc:tDesc, 1:$ZCVT(pElement_":"_pCat_":"_item,"O","HTML"))
			Set fullLink = ..Link(zenPage_".zen?DS="_$$$URLENCODE(pElement_":"_pCat_":"_item))
			&html<<td#(tWideColumns)#><div style="white-space:nowrap;"><a title='#(tooltip)#' href='#(fullLink)#'>#(item)#</a></div></td>>

			Set itemCount=itemCount+1
			Set:itemCount>max max=itemCount
			Set:itemCount#elementsPerRow=0 itemCount=0 ; reached max elements in row
		}
	}
	#; finish table & page
	If first {
		#; output dummy row & group
		&html<<tr><td>&nbsp;</td></tr>>
	} Else {
		#; finish previous row & group
		&html<</tr></table></td></tr>>
	}
	&html<</table>>
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("XML Schemas")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdImport",$$$Text("Import"),$$$Text("Import a new schema definition from a SEF or XML file"),"zenPage.doImportBrowse();")
	Set pCommands(2) = $LB("cmdDelete",$$$Text("Delete"),$$$Text("Delete a schema definition category"),"zenPage.doDelete();")
	Quit $$$OK
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()  Quit:$$$ISERR(tSC) tSC

	Set ..HelpAddress = $$$PRODUCT2 _", XML VDoc Schemas"
	If ..Category="" && $D(^EnsPortal.Settings($Username,"XML","CurrentDrawSchema")) {
		Set ..Category = ^EnsPortal.Settings($Username,"XML","CurrentDrawSchema")
	}
	// If we have a non-empty or undefined status we are not underway
	Set ..underway = $S((""=$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status"),"undef")):$G(^IRIS.Temp.XML.Import($ZNSpace,$Username,"status","file")),1:"")

	Quit tSC
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
					"ImportInBackground": ..#EDITRESOURCE,
					"DeleteCategory": ..#EDITRESOURCE,
					: "")
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br/>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	// ensure all column content is visible in IE8
	zenPage.IE = zenIsIE;
}

Method DrawSchemaDescription(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tDescription = %query(pName)
	If $L(tDescription)>50 {
		Set tPos = $F(tDescription," ",40)
		If (tPos<1)||(tPos>50) Set tPos = 50
		Set tDescription = $E(tDescription,1,tPos)_" ..."
	}
	Write $ZCVT(tDescription,"O","HTML")
	Quit $$$OK
}

}
