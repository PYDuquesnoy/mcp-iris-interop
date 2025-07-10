/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsUI, EnsUtil)

/// Purge all for Ensemble
Class Ens.Enterprise.Portal.MsgBankPurgeAll Extends (EnsPortal.Template.standardPage, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

Parameter PAGENAME = "Purge Management Data";

/// User needs USE permissions on the %Ens_Purge resource to access this page.
Parameter RESOURCE = "%Ens_Purge:USE";

Property Status As %String;

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
	border-radius:10px;
}
</style>
}

XData contentPane
{
<pane>
<hgroup valign="top" >
<spacer width="20" />
<vgroup valign="top" >
<spacer height="20" />
<hgroup>
<vgroup cellAlign="right" groupStyle="color:#404040;" groupClass="labelNormal">
<label label="Type of Record" labelClass="labelBold" labelStyle="text-decoration: underline;"/>
<label value="Event Log"/>
<label value="Messages"/>
<label value="Business Processes"/>
<label value="Business Rule Log"/>
<label value="I/O Log"/>
<label value="Message Bank Event Log"/>
<label value="Message Bank Messages"/>
</vgroup>
<spacer width="20"/>
<vgroup groupStyle="color:#C6930A;" groupClass="labelNormal">
<label label="Count" labelClass="labelBold" labelStyle="text-decoration: underline;"/>
<label id="col11"/>
<label id="col12"/>
<label id="col13"/>
<label id="col14"/>
<label id="col15"/>
<label id="col16"/>
<label id="col17"/>
</vgroup>
<spacer width="20"/>
<vgroup id="resultGroup" groupStyle="color:darkgreen;" groupClass="labelNormal" >
<label id="resultGroupTitle" label="Deleted" labelClass="labelBold" labelStyle="text-decoration: underline;" />
<label id="col21" value="-" />
<label id="col22" value="-" />
<label id="col23" value="-" />
<label id="col24" value="-" />
<label id="col25" value="-" />
<label id="col26" value="-" />
<label id="col27" value="-" />
</vgroup>
</hgroup>
<spacer height="10" />

<vgroup id="fldPurge" layout="vertical" cellStyle="padding:5px;" enclosingStyle="padding:5px;background:#edece4;border:1px solid darkgray;-moz-border-radius:5px;width:280px;">
	<label label="Purging Criteria:" />
	<checkbox name="BodiesToo" id="BodiesToo" caption="Include message bodies" enclosingStyle="color:#404040;font-size:0.8em;" />
	<checkbox name="KeepIntegrity" id="KeepIntegrity" caption="Keep data integrity" value="1" enclosingStyle="color:#404040;font-size:0.8em;" />
	<hgroup>
	<label label="Do not purge most recent"/>
	<spacer width="4px" />
	<text name="NumberDaysToKeep" id="NumberDaysToKeep" size="5" value="7"/>
	<spacer width="4px" />
	<label label="days"/>
	</hgroup>
	<button name="btnPurge" id="btnPurge" caption="Start Purge" controlClass="commandButton" onclick="zenPage.purge();" />
	<spacer height="5" />
</vgroup>
<!-- for displaying status updates during a background import job -->
<html id="idStatus" OnDrawContent="DrawStatus"/>
<!-- for periodically updating the status display during a background import job -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
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
	this.invokeSuper('onloadHandler',arguments);
	if (this.enableAutoRefresh) {
		var timer = zenPage.getComponentById('timer');	
		timer.startTimer();
	}
	else {
		this.doStatus();
	}
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
	if ((zenPage.Status == "idle") || (!zenPage.enableAutoRefresh)) {
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
		else {
			// confirm completion
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
		zen("col16").setValue(val[5]); // Message Bank Event Count
		zen("col17").setValue(val[6]); // Message Bank Messages Count
		zen("col21").setValue(val[7]); // Event Results
		zen("col22").setValue(val[8]); // Message Results
		zen("col23").setValue(val[9]); // Process Results
		zen("col24").setValue(val[10]); // RuleLog Results
		zen("col25").setValue(val[11]); // IOLog Results
		zen("col26").setValue(val[12]); // Message Bank Event Results
		zen("col27").setValue(val[13]); // Message Bank Messages Results
		zen("resultGroup").setHidden(false);
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
	
	// Draw the status table
	&html<
		<table>
			<tr><td>#(tTitle)#:</td></tr>
		</table>
		<table border="0" cellspacing="5" cellpadding="0">
			<tr><td nowrap>#(tDuration)#: #($ZCVT(RunningDuration,"O","HTML"))#</td></tr>
		</table>
	>

	If '..enableAutoRefresh {
		// If auto-refresh is disabled, show a button to allow the status to be refreshed manually
		Set tRefreshInstruction = $$$TextHTML("Refresh:")
		Set tRefreshTitle = $$$TextHTML("Refresh purge status")
		&html<
			<div style="padding-top: 0.5em;">
				<span style="font-weight: bold;">#(tRefreshInstruction)#</span>
				<image src="deepsee/loop_24.gif" class="icon" title="#(tRefreshTitle)#" onclick="zenPage.doStatus();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';" style="vertical-align: middle;"/>
			</div>
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
	lock +^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"lock"):0 set locktest=$T lock -^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"lock")
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
	Set pMsg = $G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","error"))
	If $E(pMsg,1,5) '= "ERROR" Set pMsg = ""
	Quit pMsg
}

/// Use when the purge job is running in the background to check on status.
ClassMethod GetRunningStartTime() As %String
{
	quit $G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","start"))
}

/// Use after the purge job has completed to check on results.
ClassMethod GetCounts() As %String [ ZenMethod ]
{
	Do ##class(Ens.Enterprise.MsgBank.Purge).GetAllCounts(.count)
	Set counts = count("Event Log")
	Set counts = counts_","_count("Messages")
	Set counts = counts_","_count("Business Processes")
	Set counts = counts_","_count("Business Rule Log")
	Set counts = counts_","_count("I/O Log")
	Set counts = counts_","_count("Message Bank Events")
	Set counts = counts_","_count("Message Bank Messages")
	Set counts = counts_","_$G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","EventCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","MessageCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","ProcessCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","RuleLogCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","IOLogCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","MsgBankEventCount"))
	Set counts = counts_","_$G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","MsgBankCount"))
	Quit counts
}

/// Use when the purge job is running in the background to check on status.
/// Gets the number of seconds job has been running (or ran, if complete)
/// and formats it nicely as a string.
ClassMethod GetRunningDuration() As %String
{
	// Get the duration in seconds
	Set stopH = $G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","stop"))
	If ""=stopH { // we haven't stopped yet, use current time
		Set stopH = $H
	}
	Set startH = $G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","start"))
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
	quit $G(^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","completed"))
}

ClassMethod SetCompletionValue(pValue As %Integer) As %Boolean
{
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","completed") = pValue
}

ClientMethod purge() [ Language = javascript ]
{
	// Get the values for the purge
	var BodiesToo = zen("BodiesToo").getValue();
	var KeepIntegrity = zen("KeepIntegrity").getValue();
	var NumberDaysToKeep = zen("NumberDaysToKeep").getValue();

	if (zenPage.enableAutoRefresh) {
		// Start a timer so we can detect when the job is over
		var timer = zenPage.getComponentById('timer');	
		timer.setProperty('timeout',1000);
		timer.startTimer();
	}

	// run the background task 
	var ret = this.DoPurgeInBackground(BodiesToo,KeepIntegrity,NumberDaysToKeep); 
	if (ret != 1) { 
		// report the error
		alert(ret);
	}
	else if (!zenPage.enableAutoRefresh) {
		zenPage.doStatus();
	}
}

/// This method is called when user clicks the Purge button.
/// Run method DoPurge() in a background job. Return 1 if this works out ok, 
/// an error string if there is an error in running the job 
/// (regardless of the results of the method DoPurge() itself).
ClassMethod DoPurgeInBackground(pBodiesToo As %Boolean, pKeepIntegrity As %Boolean, pNumberDaysToKeep As %Integer) As %ZEN.Datatype.string [ ZenMethod ]
{
	Set tSC = ..%RunBackgroundMethod("DoPurge",pBodiesToo,pKeepIntegrity,pNumberDaysToKeep)
	If $$$ISERR(tSC) { 
		Quit $$$StatusDisplayString(tSC) 
	}
	Else {
		Quit tSC
	}
}

/// Designed to run in a background job using the method DoPurgeInBackground which invokes %RunBackgroundMethod().
/// Based on a similar method in EnsPortal.EDI.SEF.SchemaMain.
ClassMethod DoPurge(pBodiesToo As %Boolean, pKeepIntegrity As %Boolean, pNumberDaysToKeep As %Integer) As %String
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do ..%SetBackgroundMethodStatus("Job Started. Please wait...")	
	
	// Lock and set globals
	lock +^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"lock"):1
	else  quit $$$ERROR($$$GeneralError,"Cannot acquire lock to start purging all management data")
	Do ..SetCompletionValue(0) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
	kill ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run")
	set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","start")=$H

	// Do the purge
	Set tSC = $classmethod("Ens.Enterprise.MsgBank.Purge","PurgeAll",.Deleted,pNumberDaysToKeep,pKeepIntegrity,pBodiesToo)
	
	// Set and unlock globals
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","EventCount") = +$G(Deleted("Event Logs"))
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","MessageCount") = +$G(Deleted("Ensemble Messages"))
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","ProcessCount") = +$G(Deleted("Business Processes"))
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","RuleLogCount") = +$G(Deleted("Business Rule Logs"))
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","IOLogCount") = +$G(Deleted("I/O Logs"))
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","MsgBankEventCount") = +$G(Deleted("Message Bank Events"))
	Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","MsgBankCount") = +$G(Deleted("Message Bank Messages"))
	set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","error")=$$$StatusDisplayString(tSC)
	set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","stop")=$H
	Do ..SetCompletionValue(2) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
	lock -^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"lock")

	// Clean up and end	
	If $$$ISOK(tSC) {
		Do ..%EndBackgroundMethod()
	} 
	Else {
		// server method errored out
		Set pMsg = $$$StatusDisplayString(tSC)
		Do ..%SetBackgroundMethodStatus(pMsg)
		
		// This is to set unexpected errors like unable to lock, etc. so UI can pickup to display
		Set ^IRIS.Temp.EnsMsgBankPurgeAll($USERNAME,"run","error") = pMsg
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
	Do ##class(Ens.Enterprise.MsgBank.Purge).GetAllCounts(.count)
	Set ..%GetComponentById("col11").value = count("Event Log")
	Set ..%GetComponentById("col12").value = count("Messages")
	Set ..%GetComponentById("col13").value = count("Business Processes")
	Set ..%GetComponentById("col14").value = count("Business Rule Log")
	Set ..%GetComponentById("col15").value = count("I/O Log")
	Set ..%GetComponentById("col16").value = count("Message Bank Events")
	Set ..%GetComponentById("col17").value = count("Message Bank Messages")

	If ..enableAutoRefresh {
		Set ..%GetComponentById("timer").timeout = 1000
	}
	Quit $$$OK
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
