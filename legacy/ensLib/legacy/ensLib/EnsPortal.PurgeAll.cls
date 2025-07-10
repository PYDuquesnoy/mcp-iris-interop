/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsUI, EnsUtil, Ensemble)

/// Purge all
Class EnsPortal.PurgeAll Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Purge Management Data";

/// User needs USE permissions on the %Ens_Purge resource to access this page.
Parameter RESOURCE = "%Ens_Purge:USE";

/// User needs WRITE permissions on the %Ens_PurgeSettigns resource to change the purge criteria
Parameter EDITRESOURCE = "%Ens_PurgeSettings:WRITE";

Property Status As %String;

/// If true, the settings area is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 0, Internal ];

XData Style
{
<style type="text/css">
#htmlresult {
	border: 1px solid #C6930A;
	background: #c4d8e2;
	padding: 5px;
	width: 100%;
	height: 100%;
	overflow: auto;
	border-radius: 10px;
	font-size: 14px;
	color: blue;
}
.labelDeleted {
	color: darkred;
	font-size: 14px;
	padding-right: 10px;
	text-align: right;
}
.labelHeader {
	font-size: 16px;
	text-align: right;
}
.labelNormal {
	font-size: 14px;
	padding-right: 10px;
	text-align: right;
}
.results {
	font-size: 14px;
	margin-left: 10px;
}

.portalServerLink {
	cursor:pointer;
}

#settingsPane {
	overflow: auto;
	border-left: 1px solid #F0F0F0;
	border-right: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

#spanArrow {
	padding-left:5px;
	font-size:20pt;
	background:none;
	cursor:pointer;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane width="100%">
<hgroup valign="top" width="100%" >
<spacer width="20" />
<vgroup id="mainPage" valign="top" width="100%" >
<spacer height="20" />
<hgroup>
<vgroup groupClass="labelNormal">
<label label="Record Type" labelClass="labelHeader"/>
<spacer height="8"/>
<label value="Event Log"/>
<label value="Messages"/>
<label value="Business Processes"/>
<label value="Business Rule Log"/>
<label value="I/O Log"/>
<label value="Managed Alerts"/>
</vgroup>
<spacer width="20"/>
<vgroup groupClass="labelNormal">
<label label="Count" labelClass="labelHeader"/>
<spacer height="8"/>
<label id="col11"/>
<label id="col12"/>
<label id="col13"/>
<label id="col14"/>
<label id="col15"/>
<label id="col16"/>
</vgroup>
<spacer width="20"/>
<vgroup id="resultGroup" groupClass="labelDeleted">
<label id="resultGroupTitle" label="Deleted" labelClass="labelHeader"/>
<spacer height="8"/>
<label id="col21" value="-"/>
<label id="col22" value="-"/>
<label id="col23" value="-"/>
<label id="col24" value="-"/>
<label id="col25" value="-"/>
<label id="col26" value="-"/>
</vgroup>
</hgroup>
<spacer height="20" />

<vgroup>
<hgroup>
<label label="Purging Criteria" labelStyle="font-size:12pt;font-weight:600"/>
<image id="info" src="portal/images/icon_info.png" width="10" height="10" valign="top" title="View documentation for the purge criteria" onclick="zenPage.showPurgeDoc();"/>
<label controlClass="portalServerLink" value="Learn more..." title="View documentation for the purge criteria" onclick="zenPage.showPurgeDoc();"/>
</hgroup>
</vgroup>
<spacer height="5"/>
<vgroup id="fldPurge" width="400px" layout="vertical" cellStyle="padding:5px;" enclosingStyle="padding:5px;border:1px solid darkgray;-moz-border-radius:5px;">
	<hgroup width="100%">
	<hgroup id="BodiesToo">
	<label value="Include message bodies:"/>
	<spacer width="5"/>
	<label id="BodiesTooVal"/>
	</hgroup>
	<label controlClass="portalServerLink" value="Change Settings" controlStyle="text-decoration:none;float:right;overflow:none;" onclick="zenPage.showSettingsPane();"/>
	</hgroup>
	<hgroup id="KeepIntegrity">
	<label value="Purge only completed sessions:"/>
	<spacer width="5"/>
	<label id="KeepIntegrityVal"/>
	</hgroup>
	<hgroup id="NamespaceBitmapMaint">
	<label value="Run Bitmap Cleanup For Namespace:"/>
	<spacer width="5"/>
	<label id="NamespaceBitmapMaintVal"/>
	</hgroup>
	<spacer height="10"/>
	<vgroup>
	<html id="Description" OnDrawContent="DrawDescription" enclosingStyle="font-size:11pt;font-style:italic;word-wrap:break-word;width:380px" />
	</vgroup>
</vgroup>
<spacer height="20" />
<vgroup>
	<hgroup>
	<label label="Do not purge most recent"/>
	<spacer width="4px" />
	<text name="NumberDaysToKeep" id="NumberDaysToKeep" size="5" value="7"/>
	<spacer width="4px" />
	<label label="days"/>
	</hgroup>
	<spacer height="20"/>
	<button name="btnPurge" id="btnPurge" caption="Start Purge" controlClass="commandButton" onclick="zenPage.purge();" />
	<spacer height="5" />
	</vgroup>

<!-- for displaying status updates during a background import job -->
<html id="idStatus" OnDrawContent="DrawStatus" enclosingClass="results"/>
<!-- for periodically updating the status display during a background import job -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</vgroup>
<vgroup id="settingsPane" width="100%" hidden="true" valign="top">
<hgroup width="100%">
<html id="settingsTitle" valign="top"><span id="spanArrow" title="Hide the settings box" onclick="zenPage.hideSettingsPane();" onmouseover="this.style.color='#FFEEAA';" onmouseout="this.style.color='';">&#187;</span></html>
<form id="settingsForm" containerStyle="padding-left:10px;padding-top:20px;" cellStyle="padding-top:5px;" width="100%">
<label label="Purge Data Settings" labelStyle="font-size:12pt;font-weight:600" align="center"/>
<spacer height="15"/>
<checkbox id="chkBodiesToo" caption="Include message bodies"/>
<checkbox id="chkKeepIntegrity" caption="Purge only completed sessions"/>
<checkbox id="chkNamespaceBitmapMaint" caption="Run Bitmap Cleanup For Namespace"/>
<spacer height="10"/>
<textarea id="txtDescription" label="Description" rows="20" controlStyle="width:90%" labelStyle="font-size:10pt;" title="Description to display in explanatory box on Purge Management Data page"/>
<spacer height="15"/>
<hgroup align="center">
<button id="btnCancel" caption="Cancel" controlClass="commandButton" onclick="zenPage.hideSettingsPane();"/>
<spacer width="25"/>
<button id="btnSave" caption="Save" controlClass="commandButton" onclick="zenPage.saveSettings();"/>
</hgroup> 
</form>
</hgroup>
</vgroup>
</hgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
/// Start the timer so we can check the status. If there is a
/// background import job currently running,
/// you will see a periodic update until the job is finished.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	
	this.doStatus();
	if ((zenPage.Status != "idle") && zenPage.enableAutoRefresh) {
		var timer = zenPage.getComponentById('timer');	
		timer.setProperty('timeout',1000);
		timer.startTimer();
	}
	
	zenPage.updatePurgeCriteria();
}

ClientMethod updatePurgeCriteria() [ Language = javascript ]
{
	var settings = new Array();
	settings = JSON.parse(zenPage.GetPurgeSettings());
	if (settings) {
		zen("BodiesTooVal").setValue(settings.bodiesToo ? $$$Text("ON") : $$$Text("OFF"));
		zen("KeepIntegrityVal").setValue(settings.keepIntegrity ? $$$Text("ON") :$$$Text("OFF"));
		zen("NamespaceBitmapMaintVal").setValue(settings.bitmapMaint ? $$$Text("ON") :$$$Text("OFF"));
		zen("Description").refreshContents();
	}
}

Method DrawDescription(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Write $Replace(..EscapeHTML($G($$$EnsPurgeDescriptions)),$C(10),"<br>")
	Set tPurgeJournalData = $$$EnsPurgeJournalOldDataGet
	If tPurgeJournalData {
		Set tPurgeJournalDesc = $$$Text("Old data values are recorded in the journal file when purging")
	} Else {
		Set tPurgeJournalDesc = $$$Text("Old data values are not recorded in the journal file when purging")
	}
	Set tPurgeJournalDesc = tPurgeJournalDesc _ ". " _ $$$Text("This setting can be changed in 'Configuration, Interoperability Settings'.")
	Write "<br>------------<br>"
	Write $Replace(..EscapeHTML(tPurgeJournalDesc),$C(10),"<br>")

	Quit $$$OK
}

/// Show documentation for message purge.
ClientMethod showPurgeDoc() [ Language = javascript ]
{
	var win = window.open('/csp/docbook/DocBook.UI.Page.cls?KEY=EGMG_purge#EGMG_purge_basic','Docbook');
	try {
		win.focus();
	}
	catch(ex) {}
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		zenPage.adjustSizes();
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		zen('settingsPane').setHidden(!this.settingsExpanded);

		if (this.settingsExpanded) {
			var setDiv = zen('settingsPane').getEnclosingDiv();
			var mainDiv = zen('mainPage').getEnclosingDiv();

			// find size of window
			var winHeight = zenGetWindowHeight();
			var winWidth = zenGetWindowWidth();
			
			// make settings sheet visible
			setDiv.style.visibility = 'visible';

			var setWidth = (winWidth<1100) ? 300 : 350;
			setDiv.style.width = setWidth + 'px';

			var th = this.getTitleAreaHeight();
			var scroll =  ((zenBody.scrollWidth == zenBody.offsetWidth) && (zenBody.scrollLeft == 0 )) ? 0 :1;
			var hgt = winHeight - th - 9  - 10*scroll;
			hgt = Math.max(hgt,mainDiv.clientHeight);
			hgt = (hgt > 400) ? hgt : 400;

			setDiv.style.height = hgt + 'px';
			
			var descDiv = zen('txtDescription').getEnclosingDiv();
			var descHgt = (hgt-300);
			descDiv.style.height = descHgt + 'px';
			zen('txtDescription').setProperty("rows",parseInt(descHgt/16));
		
		}
		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

ClientMethod showSettingsPane() [ Language = javascript ]
{
	// first check for permission to change
	if (!zenPage.canEdit) {
		var parms = {};
		var url = zenLink('EnsPortal.Dialog.PurgeSettingsNoPermission.zen');
		zenLaunchPopupWindow(url,'','status,scrollbars,resizable=no,width=300,height=250',parms);
	} else {
		// set values
		var settings = new Array();
		settings = JSON.parse(zenPage.GetPurgeSettings());
		if (settings) {
			zen("chkBodiesToo").setValue(settings.bodiesToo);
			zen("chkKeepIntegrity").setValue(settings.keepIntegrity);
			zen("chkNamespaceBitmapMaint").setValue(settings.bitmapMaint);
			zen("txtDescription").setValue(settings.description);
		}

		this.settingsExpanded = true;
		zenPage.adjustSizes();
	}
}

ClientMethod hideSettingsPane() [ Language = javascript ]
{
	// compare values against existing
	var same = 1;
	var settings = new Array();
	settings = JSON.parse(zenPage.GetPurgeSettings());
	if (settings) {
		same = ((zen("chkBodiesToo").getValue() == settings.bodiesToo) && (zen("chkKeepIntegrity").getValue() == settings.keepIntegrity) && (zen("chkNamespaceBitmapMaint").getValue() == settings.bitmapMaint) && (zen("txtDescription").getValue() == settings.description));
	}
	// if values have changed, confirm before closing
	if (!same) {
		if (!confirm($$$Text("Closing the settings pane will undo the changes you have made.\nAre you sure you want to continue?"))) {
			return false;
		}
	}
	this.settingsExpanded = false;
	zen('settingsPane').setHidden(true);
}

ClientMethod saveSettings() [ Language = javascript ]
{
	var msg = zenPage.DoSaveSettings();
	if (msg != "") {
		alert(msg);
	} else {
		zenPage.updatePurgeCriteria();
	}
	this.settingsExpanded = false;
	zen('settingsPane').setHidden(true);
}

Method DoSaveSettings() As %String [ ZenMethod ]
{
	Set tPermitted = $system.Security.Check("%Ens_PurgeSettings", "W")
	Quit:'tPermitted $$$TextJS("You do not have permission to change the Purge Data settings.  Please contact your system administrator or go to the documentation link for more information.")  // should not happen because checked before showing pane
	
	Set $$$EnsPurgeDefaults("BodiesToo") = ..%GetComponentById("chkBodiesToo").value
	Set $$$EnsPurgeDefaults("KeepIntegrity") = ..%GetComponentById("chkKeepIntegrity").value
	Set $$$EnsPurgeDefaults("NamespaceBitmapMaint") = ..%GetComponentById("chkNamespaceBitmapMaint").value
	Set $$$EnsPurgeDescriptions = ..%GetComponentById("txtDescription").value
	
	Quit ""
}

/// This function controls the timer on updating progress.
/// It is called from onload as well (in case a background import job is currently being run when the page is opened).
ClientMethod timeout(timer) [ Language = javascript ]
{
	// get and use the status of the background import job
	this.doStatus();
	
	// get the timer and status fields
	var timer = zen("timer");
	
	// stop timer or continue
	if ((zenPage.Status == "idle") || !zenPage.enableAutoRefresh) {
		timer.clearTimer();		
	}
	else { 
		timer.startTimer();	
	}
}

/// This method calls server method to get current background import job status and update the UI.
ClientMethod doStatus() [ Language = javascript ]
{
	// invoke DrawStatus() which will get and display all the status information
	zen("idStatus").refreshContents(); 
	
	// get the status string
	zenPage.Status = zenPage.GetPurgeStatus();
	
	// if done, refresh the page so it reflects the newly imported data
	if (zenPage.Status == "done") { 
		msg = zenPage.GetJobStatus();
		if (msg.length > 0) { // job experienced an error
			alert($$$Text("Background purge job was unsuccessful.")+" "+msg);
		}
		else { // confirm completion
			alert($$$Text("Background purge job completed successfully."));
		}
		// Put values into the display components
		var counts = zenPage.GetCounts();
		var val = counts.split(',');
		zen("col11").setValue(val[0]); // Event Count
		zen("col12").setValue(val[1]); // Message Count
		zen("col13").setValue(val[2]); // Process Count
		zen("col14").setValue(val[3]); // RuleLog Count
		zen("col15").setValue(val[4]); // IOLog Count
		zen("col16").setValue(val[5]); // Managed Alert Count
		zen("col21").setValue(val[6]); // Event Results
		zen("col22").setValue(val[7]); // Message Results
		zen("col23").setValue(val[8]); // Process Results
		zen("col24").setValue(val[9]); // RuleLog Results
		zen("col25").setValue(val[10]); // IOLog Results
		zen("col26").setValue(val[11]); // Managed Alert Results
		zen("resultGroup").setHidden(false);
	}
	if (zenPage.Status == "running") {
		zenSetProp('btnPurge','controlClass','commandButtonDisabled');
		zenSetProp('btnPurge','disabled',true);
	}
	else {
		zenSetProp('btnPurge','controlClass','commandButton');
		zenSetProp('btnPurge','disabled',false);
	}
	return;
}

/// Draw current import status; intended for use with background purge jobs.
Method DrawStatus(seed As %ZEN.Datatype.string) As %Status
{
	// If there is no start time, or if we are marked complete, we are not underway
	Set RunningStartTime = ..GetRunningStartTime()
	If ((""=RunningStartTime) || (..GetCompletionValue() > 0)) { // done (2) or idle (1) or running (0)
		Quit $$$OK 
	} 
	
	// Get the  values needed for the status table
	Set tTitle = $$$TextHTML("Purge in progress")
	Set tDuration = $$$TextHTML("Duration")
	Set RunningDuration = ..GetRunningDuration()	
	
	If ..enableAutoRefresh {
		// Draw the status table
		&html<
			<table>
				<tr><td>#(tTitle)#:</td></tr>
			</table>
			<table border="0" cellspacing="5" cellpadding="0">
				<tr><td nowrap>#(tDuration)#: #($ZCVT(RunningDuration,"O","HTML"))#</td></tr>
			</table>
		>
	} Else {
		// Draw Refresh
		Set tRefresh = $$$TextHTML("Refresh status")
		Set tTitle = $$$TextHTML("Purge in progress.  Click to refresh status")
		&html<
			<table>
				<td><div nowrap>
					<span style="font-size:10pt;color:#606060;font-weight:bold;">#(tTitle)#:</span>
				</div></td>
				<td nowrap style="padding-left:5px;">
					<image src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.doStatus();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
				</td>
			</table>
		>
	}
	
	Quit $$$OK
}

/// Use when the purge job is running in the background to check on running status.
/// Returns either "running" or "idle" or "done".
ClassMethod GetPurgeStatus() As %String [ ZenMethod ]
{
	Quit ..GetRunningStatus()
}

/// Use when the purge job is running in the background to check on running status.
/// Returns either "running" or "idle" or "done".
ClassMethod GetRunningStatus() As %String
{
	If (..GetCompletionValue()=2) {		// we're done
		Do ..SetCompletionValue(1) 	  	// change to idle
		Quit "done" 
	}
	lock +^IRIS.Temp.EnsPurgeAll($Namespace,"lock"):0 set locktest=$T lock -^IRIS.Temp.EnsPurgeAll($Namespace,"lock")
	If locktest=0 {
		Do ..SetCompletionValue(0) 	  	// it's running
		Quit "running"
	}
	Else {								// nothing is going on
		Do ..SetCompletionValue(1) 	  	// change to idle
		Quit "idle" 
	}
}

/// Use when the purge job is running in the background to check on error status.
/// An empty string means no error; otherwise it is an error message.
ClassMethod GetJobStatus() As %String [ ZenMethod ]
{
	Set pMsg = $G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","error"))
	If $E(pMsg,1,5) '= "ERROR" Set pMsg = ""
	Quit pMsg
}

/// Use when the purge job is running in the background to check on status.
ClassMethod GetRunningStartTime() As %String
{
	quit $G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","start"))
}

/// Use after the purge job has completed to check on results.
ClassMethod GetCounts() As %String [ ZenMethod ]
{
	Do ##class(Ens.Purge).GetAllCounts(.count)
	Set counts = count("Event Log")
	Set counts = counts_","_count("Messages")
	Set counts = counts_","_count("Business Processes")
	Set counts = counts_","_count("Business Rule Log")
	Set counts = counts_","_count("I/O Log")
	Set counts = counts_","_count("Managed Alerts")
	Set counts = counts_","_$G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","EventCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","MessageCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","ProcessCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","RuleLogCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","IOLogCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","ManagedAlertCount"))
	Quit counts
}

/// Use when the purge job is running in the background to check on status.
/// Gets the number of seconds job has been running (or ran, if complete)
/// and formats it nicely as a string.
ClassMethod GetRunningDuration() As %String
{
	// Get the duration in seconds
	Set stopH = $G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","stop"))
	If ""=stopH { // we haven't stopped yet, use current time
		Set stopH = $H
	}
	Set startH = $G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","start"))
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

ClassMethod GetCompletionValue() As %Boolean
{
	quit $G(^IRIS.Temp.EnsPurgeAll($Namespace,"run","completed"))
}

ClassMethod SetCompletionValue(pValue As %Integer) As %Boolean
{
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","completed") = pValue
}

ClientMethod purge() [ Language = javascript ]
{
	// Get the values for the purge
	var BodiesToo = zenPage.PurgeBodiesToo();
	if (BodiesToo) {
		var question = $$$Text("Message objects may not be transitory.\nAre you sure you want to purge both message headers and message bodies?");
	} else {
		var question = $$$Text("Message bodies will NOT be deleted.\nAre you sure you want to purge only message headers?");
	}
	if (!confirm(question)) {
		return false;
	}
	try {
		var NumberDaysToKeep = zen("NumberDaysToKeep").getValue().replace(/^\s+|\s+$/g,'');   // Remove leading and trailing spaces
		if (/^[0-9]+$/.test(NumberDaysToKeep)) {NumberDaysToKeep = Number(NumberDaysToKeep)}; // Remove leading 0 provided a base 10 number
	} catch (ex) {
		alert( $$$FormatText($$$Text("Error: %1"),ex) );
		return false;	
	}
	if (isNaN(NumberDaysToKeep)||('' === NumberDaysToKeep)||!(NumberDaysToKeep % 1 === 0)||!(/^[0-9]+$/.test(NumberDaysToKeep))) {
		alert($$$Text("Value entered for number of days is not a positive integer or 0."));
		return false;
	}
	if (NumberDaysToKeep < 0) {
		alert($$$Text("Value entered for number of days is not 0 or a positive integer."));
		return false;
	} else if (NumberDaysToKeep == 0) {
		if (!(confirm($$$Text("Please confirm you wish to purge all days.")))) return false;	
	}
	
	if (zenPage.enableAutoRefresh) {
		// Start a timer so we can detect when the job is over.
		var timer = zenPage.getComponentById('timer');	
		timer.setProperty('timeout',1000);
		timer.startTimer();
	}

	// run the background task 
	var ret = this.CallPurge(NumberDaysToKeep); 
	if (ret != 1) { 
		// report the error
		alert(ret);
	}
	
	if (!zenPage.enableAutoRefresh) {
		zenPage.doStatus();
	}
}

Method PurgeBodiesToo() As %Boolean [ ZenMethod ]
{
	Quit +$G($$$EnsPurgeDefaults("BodiesToo"))
}

Method CallPurge(pNumberDaysToKeep As %Integer) As %ZEN.Datatype.string [ ZenMethod ]
{
	Set tBodiesToo = +$G($$$EnsPurgeDefaults("BodiesToo"))
	Set tKeepIntegrity = +$G($$$EnsPurgeDefaults("KeepIntegrity"))
	Set tRunBitmapMaint = +$G($$$EnsPurgeDefaults("NamespaceBitmapMaint"))
	Quit ..DoPurgeInBackground(tBodiesToo,tKeepIntegrity,pNumberDaysToKeep,tRunBitmapMaint)
}

/// This method is called when user clicks the Purge button.
/// Run method DoPurge() in a background job. Return 1 if this works out ok, 
/// an error string if there is an error in running the job 
/// (regardless of the results of the method DoPurge() itself).
ClassMethod DoPurgeInBackground(pBodiesToo As %Boolean, pKeepIntegrity As %Boolean, pNumberDaysToKeep As %Integer, pNamespaceBitmapMaint As %Boolean) As %ZEN.Datatype.string
{
	Set tSC = $$$OK
	Lock +^IRIS.Temp.EnsPurgeAll($Namespace,"lock"):0
	If '$T {
		Set user = $G(^IRIS.Temp.EnsPurgeAll($Namespace,"user"))
		If user="" {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Cannot acquire lock to start purging all management data"))
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,$$$FormatText($$$Text("Purge in this namespace has already been started by user '%1'")_" ",user))
		}
	}
	Else {
		Lock -^IRIS.Temp.EnsPurgeAll($Namespace,"lock")
		Set tSC = ..%RunBackgroundMethod("DoPurge",pBodiesToo,pKeepIntegrity,pNumberDaysToKeep,pNamespaceBitmapMaint)
	}
	If $$$ISERR(tSC) {
		Quit $$$StatusDisplayString(tSC) 
	}
	Else {
		Quit 1
	}
}

/// Designed to run in a background job using the method DoPurgeInBackground which invokes %RunBackgroundMethod().
/// Based on a similar method in EnsPortal.EDI.SEF.SchemaMain.
ClassMethod DoPurge(pBodiesToo As %Boolean, pKeepIntegrity As %Boolean, pNumberDaysToKeep As %Integer, pNamespaceBitmapMaint As %Boolean) As %String
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do ..%SetBackgroundMethodStatus("Job started. Please wait...")

	// Lock and set globals
	Lock +^IRIS.Temp.EnsPurgeAll($Namespace,"lock"):1
	If '$T  Quit $$$ERROR($$$GeneralError,"Cannot acquire lock to start purging all management data")
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"user") = $Username
	Do ..SetCompletionValue(0) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
	kill ^IRIS.Temp.EnsPurgeAll($Namespace,"run")
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","start") = $H

	// Do the purge. 
	If pNamespaceBitmapMaint Set tExtendedOptions("NamespaceBitmapMaint")=1
	Set tSC = ##class(Ens.Purge).PurgeAll(.Deleted,pNumberDaysToKeep,pKeepIntegrity,pBodiesToo,,.tExtendedOptions)

	// Set and unlock globals
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","EventCount") = +$G(Deleted("Event Logs"))
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","MessageCount") = +$G(Deleted("Ensemble Messages"))
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","ProcessCount") = +$G(Deleted("Business Processes"))
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","RuleLogCount") = +$G(Deleted("Business Rule Logs"))
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","IOLogCount") = +$G(Deleted("I/O Logs"))
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","ManagedAlertCount") = +$G(Deleted("Managed Alerts"))
	set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","error") = $$$StatusDisplayString(tSC)
	Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","stop") = $H
	Do ..SetCompletionValue(2) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
	Lock -^IRIS.Temp.EnsPurgeAll($Namespace,"lock")

	// Clean up and end
	If $$$ISOK(tSC) {
		Do ..%EndBackgroundMethod()
	}
	Else {
		// server method errored out
		Set pMsg = $$$StatusDisplayString(tSC)
		Do ..%SetBackgroundMethodStatus(pMsg)

		// This is to set unexpected errors like unable to lock, etc. so UI can pickup to display
		Set ^IRIS.Temp.EnsPurgeAll($Namespace,"run","error") = pMsg
	}
Done
	Quit
Trap
	Set $ZT = ""
	Do ..%SetBackgroundMethodStatus($ZE)
	GoTo Done
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Do ##class(Ens.Purge).GetAllCounts(.count)
	Set ..%GetComponentById("col11").value = count("Event Log")
	Set ..%GetComponentById("col12").value = count("Messages")
	Set ..%GetComponentById("col13").value = count("Business Processes")
	Set ..%GetComponentById("col14").value = count("Business Rule Log")
	Set ..%GetComponentById("col15").value = count("I/O Log")
	Set ..%GetComponentById("col16").value = count("Managed Alerts")
	
	Quit $$$OK
}

Method GetPurgeSettings() As %String [ ZenMethod ]
{
	#dim tObj = ##class(%Library.DynamicObject).%New()
	
	Do tObj.%Set("bodiesToo",+$G($$$EnsPurgeDefaults("BodiesToo"),0))
	Do tObj.%Set("keepIntegrity",+$G($$$EnsPurgeDefaults("KeepIntegrity"),1))
	Do tObj.%Set("bitmapMaint",+$G($$$EnsPurgeDefaults("NamespaceBitmapMaint"),0))
	Do tObj.%Set("description",$G($$$EnsPurgeDescriptions))
	
	Quit tObj.%ToJSON()
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Purge Management Data","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = ..%OnGetPageName()
	// commands: $LB(id,caption,help,onclick)
	Quit $$$OK
}

}
