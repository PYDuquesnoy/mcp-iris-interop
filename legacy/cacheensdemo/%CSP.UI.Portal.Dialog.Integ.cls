/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Integrity Check dialog for Management Portal
Class %CSP.UI.Portal.Dialog.Integ Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.Integ.zen";

Parameter RESOURCE = "%Admin_Operate:USE";

/// Displayed name of this page.
Parameter PAGENAME = "IntegrityCheck";

Parameter AUTONS As BOOLEAN = 0;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Type from where we get the selected items from: Class or Routine.
Property FILETYPE As %ZEN.Datatype.string(ZENURL = "FILETYPE");

Property CHECKINTEGALL As %ZEN.Datatype.string(ZENURL = "CHECKINTEGALL");

/// Total number of DBs user selected. If it's 1 then allow to select/unselect globals.
Property TOTALDB As %ZEN.Datatype.integer [ InitialExpression = "0" ];

/// Last Directory user selected
Property Directory As %ZEN.Datatype.string;

/// If user unchecked a global, this is set to 1.
Property GlobalChanged As %ZEN.Datatype.boolean;

/// When Run is clicked then Finished is set to 1, indicating Next and Run buttons should be disabled.
Property Finished As %ZEN.Datatype.boolean [ InitialExpression = "0" ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
}
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
/* style for import content table */
table.ContentTable	{ 
	font-family: Futura,Arial,sans-serif;
	border: 1px #cbcbcb solid;
}
table.ContentTable th { 
	font-size: 12px;
	font-weight: bold;		
	background:white; 
	color: #cbcbcb;
	text-align: center;
	padding: 0 2px 0 2px;
}
table.ContentTable tr.LiteRow { background: white; font-size: 11px;}
table.ContentTable tr.DarkRow { background: #F1F0E7; font-size: 11px;}
table.ContentTable td { padding: 0 2px 0 2px; font-size: 11px; }
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnBack" controlClass="commandButton" caption="Back" onclick="zenPage.previousPage();" hidden="true"/>
<spacer width="5" />
<button id="btnNext" controlClass="commandButton" caption="Next" title="Select Globals" onclick="zenPage.nextPage();"/>
<spacer width="15" />
<button id="btnFinish" controlClass="commandButton" caption="Run" onclick="zenPage.doRun();"/>
<spacer width="5" />
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="result" controlClass="redText" value="" containerStyle="padding-left:10px;"/>
<tabGroup id="tabGroup">

<!-- First Page -->
<tab id="tab1" enclosingStyle="padding-top:10px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="1"/>
<checkbox id="chkStopAfterError" caption="Stop after any error" captionClass="zenLabel"/>
 <hgroup valign="top" cellStyle="padding-right:10px;">
 <html id="htmlDBs" OnDrawContent="DrawDBs" />
 <html id="htmlGlobals" label="Globals unchecked will be skipped" seed="" OnDrawContent="DrawGlobals" hidden="true"/>
</hgroup>

</tab>
<tab id="tab2" enclosingStyle="padding-top:10px;" cellStyle="padding-bottom:10px;">
<iframe id="output" hidden="true"/>
</tab>

</tabGroup>
</pane>
}

ClientMethod showGlobals(pickGlobals) [ Language = javascript ]
{
	var html = zen("htmlGlobals");
	if (pickGlobals) {
		html.setProperty("seed",this.Directory);
		html.setHidden(false);
		this.disableDBboxes();
		document.getElementById("btnSelectAll").disabled = true;
		document.getElementById("btnUnselectAll").disabled = true;
	} else {
		html.setHidden(true);
		document.getElementById("btnSelectAll").disabled = false;
		document.getElementById("btnUnselectAll").disabled = false;		
	}
}

/// Now Run Integ. 
ClientMethod doRun() [ Language = javascript ]
{
	var selectedRows = this.getDBValues();
	if (selectedRows < 1) {
		alert($$$Text("Please select a database for which you wish to run Integrity Check on."));
		return;
	}	
	var stopaftererror = (zen("chkStopAfterError").getValue()==true) ? 1 : 0;
	var GLOBALLIST = 0;
	if (this.GlobalChanged==1) GLOBALLIST = this.getGlobals();
	var ok = this.PrepareAction(this.FILETYPE,selectedRows,GLOBALLIST);
	if (GLOBALLIST != 0) GLOBALLIST = 1;
	var srclink = this.GetLink();
	srclink += (srclink.indexOf('?') > -1) ? '&' : '?';
	srclink += 'STOPAFTERERROR='+stopaftererror+'&GLOBALLIST='+encodeURIComponent(GLOBALLIST);
	zen('output').setProperty('src',srclink);
	zen("output").setHidden(false);
	zen('btnCancel').setProperty('caption',$$$Text("Done"));
	zen('btnFinish').setProperty('disabled',true);
	zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
	var tabGroup = zen('tabGroup');
	tabGroup.showTab(2);
	this.Finished = 1;
	zenPage.updateState();
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	return false;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	return false;
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
ClientMethod canFinish() [ Language = javascript ]
{
	if (this.Finished == 1) return false;
	return true;
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return false;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
	zenPage.updateState();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{

	var frame = zen("output");
	var wd = zenGetWindowWidth() - 60;
	var ht = zenGetWindowHeight() - 380;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// For Integrity check, if user selected more than one database, then disable the Global button
ClientMethod enableGlobalButton() [ Language = javascript ]
{
	var checked = this.getDBValues();
	if (checked != "") {
		var dirs = checked.split(",");
		if (dirs.length > 3) {
			document.getElementById("GlobalInteg").disabled = true;
		} else {
			this.Directory = dirs[1];
			document.getElementById("GlobalInteg").disabled = false;
		}
	} else {
		var TotalRows = document.getElementById("TotalDBs").value;
		var cb;
		for (var i = 1; i <= TotalRows; i++) {
			cb = self.document.getElementById("db_"+i);
			if (cb) {
				cb.disabled = false;
			}
		}
		this.Directory = "";
		document.getElementById("GlobalInteg").disabled = true;
		this.showGlobals(0);		
	}
}

ClientMethod getDBValues() [ Language = javascript ]
{
	var state = '';
	var cb;
	this.TOTALDB = 0;
	var TotalRows = document.getElementById("TotalDBs").value;
	for (var i = 1; i <= TotalRows; i++) {
			cb = self.document.getElementById("db_"+i);
			if (cb && cb.checked) {
				this.TOTALDB++;
				state += "," + cb.value;
			}
	}
	if (state != '') {
		state += ',';
	}
	return state;
}

/// Disable or enable db checkboxes. If globals selected, then disable other DB checkboxes.
/// If user unchecked the only DB they have globals selected, then enable all and lose global selections.
ClientMethod disableDBboxes() [ Language = javascript ]
{
	var TotalRows = document.getElementById("TotalDBs").value;
	var cb;
	for (var i = 1; i <= TotalRows; i++) {
		cb = self.document.getElementById("db_"+i);
		if (cb && cb.checked == false) {
			cb.disabled = true;
		}
	}
}

ClientMethod changeCheckbox(thisCheckbox) [ Language = javascript ]
{
	var thisId = thisCheckbox.id;
	var rowId = "cr_" + thisId.split('_')[1];
	document.getElementById(rowId).className = (thisCheckbox.checked) ? "LiteRow" : "DarkRow";
	this.GlobalChanged = 1;
}

ClientMethod toggleCheckboxes(cbState) [ Language = javascript ]
{
	var rowClass = (cbState) ? "LiteRow" : "DarkRow";
	var cb;
	var TotalRows = document.getElementById("TotalRows").value;
	for (var i = 1; i <= TotalRows; i++) {
		cb = document.getElementById("cb_"+i);
		cb.checked = cbState;
		document.getElementById("cr_"+i).className = rowClass;
	}
	this.GlobalChanged = 1;
}

ClientMethod toggleDBboxes(cbState) [ Language = javascript ]
{
	var cb;
	var TotalRows = document.getElementById("TotalDBs").value;
	for (var i = 1; i <= TotalRows; i++) {
		cb = self.document.getElementById("db_"+i);
		cb.checked = cbState;
	}
}

/// gather state of check boxes and update cbState
ClientMethod updateDBValues(cbState) [ Language = javascript ]
{
	var form = self.document.expform;
	if (form) {
		form.cbState.value = this.getDBValues();
	}
}

/// Get global checkboxes and save it to temp global for processing.
ClientMethod getGlobals() [ Language = javascript ]
{
	var cbSelected = "";
	var cb;
	var TotalRows = document.getElementById("TotalRows").value;
	for (var i = 1; i <= TotalRows; i++) {
		cb = document.getElementById("cb_"+i);
		if (cb.checked) cbSelected = cbSelected + "," + cb.value;
	}
	return cbSelected
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Integrity Check")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	If pSeed = 1 {
		Set tPageTitle = $$$TextHTML("This Integrity Check will be run in the background and the result will be saved in <install location>/mgr/integ.txt")_"<br/>"
	} ElseIf pSeed = 2 {
		Set tPageTitle = ""
	}
	&html<<div class="Description">#(tPageTitle)#</div>>
	&html<<hr size="1"/>>
	Quit 1
}

ClassMethod SaveGlobals(pGlobals) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,"Integ","Globals") = pGlobals
}

ClassMethod DrawDBs(pSeed) As %Status
{
	Set tSC = $$$OK
	Set msg2 = $$$Text("Please enter a file name for saving the result:")
	Set lblSelect = $$$Text("Select All")
	Set lblUnSelect = $$$Text("Unselect All")

	Set lblName = $$$TextHTML("Name")
	Set lblDirectory = $$$TextHTML("Directory")
	Set lblGlobalInteg = $$$TextHTML("Select Globals")
	Set lblSelectGlobal = $$$TextHTML("You may select specific globals for one selected database.")
	Set msg1 = $$$Text("Please check the databases that you want to perform the Integrity Check:")
	&html<<div style="height:100px;">>
	&html<
	<table class="ContentTable" border="1" cols="2" cellspacing="0" cellpadding="3">
	<tr><td colspan="2" nowrap class="caption1">#(msg1)#</td></tr>
	<tr><th nowrap>#(lblName)#</th><th nowrap>#(lblDirectory)#</th>>
	Set tRS = ##class(%ResultSet).%New("Config.Databases:LocalDatabaseList")
	Do tRS.Execute()
	Set tRow = 0
	While tRS.Next() {
		If tRS.Get("StatusInt") '= "Dismounted" {
			Set tRow = tRow + 1
			Set cbName = "db_"_tRow
			Set cls = $S(tRow#2:"DarkRow",1:"LiteRow")
			&html<
				<tr class="#(cls)#"><td class="sd" nowrap>
				<input type="checkbox" value="#(tRS.Get("Directory"))#" name="#(cbName)#" id="#(cbName)#" onclick="zenPage.enableGlobalButton();">#(..EscapeHTML(tRS.Get("Name")))#</td>
				<td class="sd" nowrap>#(..EscapeHTML(tRS.Get("Directory")))#</td></tr>>
		}
	}
	&html<
		<input type="hidden" name="TotalDBs" id="TotalDBs" value="#(tRow)#">
		<tr><td colspan="2" nowrap><input type="button" name="SelectAll" id="btnSelectAll" value="#(lblSelect)#" onclick="zenPage.toggleDBboxes(true);">
		<input type="button" name="UnselectAll" id="btnUnselectAll" value="#(lblUnSelect)#" onclick="zenPage.toggleDBboxes(false);">
		<input type="button" name="GlobalInteg" id="GlobalInteg" value="#(lblGlobalInteg)#" disabled onclick="zenPage.showGlobals(1);">
		<div id="idGlobals">#(lblSelectGlobal)#</div></td></tr>>
			
	&html<</table></div>>
	Quit tSC
}

ClassMethod DrawGlobals(pSeed) As %Status
{
	Set tSC = $$$OK
	Quit:pSeed="" tSC
	//Set selectedRows = $$$IRISTempMgt($Username,"Integ","selectedRows",1)
	//Set DBDir = ""
	//For n = 1:1:$L(selectedRows,",") If $P(selectedRows,",",n) '="" Set DBDir = $P(selectedRows,",",n) Quit
	Set DBDir = pSeed
	If DBDir = "" Write !,"<h3>",$$$TextHTML("Could not find database directory!"),"</h3>" Quit
	Set Column(0) = $$$TextHTML("Click to select or unselect all")
	Set msgNothing = $$$TextHTML("Nothing found.")
	&html<<div style="height:100px;">>
	&html<<table class="ContentTable" border="1" cellpadding="2" cellspacing="0" bgcolor="#c4d6d6">>
	&html<<tr><th><input type="checkbox" id="chkAll" title="#(Column(0))#" checked onclick="javascript:zenPage.toggleCheckboxes(this.checked);"></th>>
	&html<<th nowrap>#($$$Text("Global"))#</th></tr>>
	Set tRow = 0
	Set tRS = ##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
	Set tSC = tRS.Execute(DBDir,,"*",0)
	While tRS.Next() {
		Set tRow = tRow + 1
		Set tId = "cb_"_tRow
		Set tName = tRS.GetData(1)
		&html<<tr id='#("cr_"_tRow)#' class="LiteRow">
		<td><input type="checkbox" name="#(tId)#" id="#(tId)#" value='#($ZCVT(tName,"O","HTML"))#' checked onchange="javascript:zenPage.changeCheckbox(this);"></td>
		<td nowrap>#(..EscapeHTML(tName))#</td></tr>>	
	}
	If tRow = 0 &html<<tr><td colspan="4">#(msgNothing)#</td></tr>>
	Else  &html<<tr><td colspan="2">#($$$FormatText($$$Text("Total: %1"),tRow))#</td></tr>>
	&html<<tr class="LiteRow"><td colspan="2">&nbsp;</td></tr></table><input type="hidden" id="TotalRows" value="#(tRow)#">>
	&html<</div>>
	Quit tSC
}

/// If at least one database is selected, then save it into session
ClassMethod PrepareAction(filetype, selectedRows, GLOBALLIST) As %String [ ZenMethod ]
{
	Set ok = ##class(%CSP.UI.Template.List).PrepareAction(filetype,selectedRows)
	If GLOBALLIST '= 0 {
		//Set $$$IRISTempMgt($Username,"IntegGlobals","selectedRows",1)  = GLOBALLIST
		Set ok = ##class(%CSP.UI.Template.List).PrepareAction("IntegGlobals",GLOBALLIST)	
	}
	Quit ok
}

Method GetLink() As %String [ ZenMethod ]
{
	Quit ..Link("_CSP.UI.Portal.Dialog.IntegOutput.zen")
}

}
