/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen based Archive Manager UI for Ensemble 2008.1
Class EnsPortal.ArchiveManager Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Archive Manager";

/// User must have READ permissions on the "%Ens_ArchiveManager" resource to view this page.
Parameter RESOURCE = "%Ens_ArchiveManager:READ";

/// User must have WRITE permissions on the "%Ens_ArchiveManager" resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_ArchiveManager:WRITE";

Property lblHistory As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Archive history")} ];

Property lblHistoryNone As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("No history found")} ];

Property lblStartTime As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Archive start time")} ];

Property lblStopTime As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Archive stop time")} ];

Property lblStatus As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Archive status")} ];

Property lblTotalProcessed As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Total messages processed")} ];

Property lblTotalArchived As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Total messages archived")} ];

Property lblTotalDeletedHead As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Total message headers deleted")} ];

Property lblTotalDeletedBody As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Total message bodies deleted")} ];

Property lblErrorLog As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Archive error log")} ];

Property lblNumberErrors As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Total number of errors")} ];

Property msgConfirm As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to start archive now? Warning: Messages cannot be restored once archived to another namespace.")} ];

Property msgDiscard As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Discard any setting changes you may have made?")} ];

XData Style
{
<style type="text/css">
.note {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 0.8em;
	color: blue;
	background: yellow;
	text-align: left;
	font-weight: bold;
}
.statusText {
	font-size:0.8em;	
}
.brownnote {
	font-size: 0.8em;
	color: darkred;
}
.fieldSet {
	background: white;
	padding: 4px;
}
.fieldSetLabel {
	color: black;
	font-weight:bold;
	padding-bottom:5px;
}
.fieldStyle {
	color: black;
	margin-bottom:1em;
	margin-top:1em;
	padding:2px;
	width: 30em;
}
TABLE.DetailTable	{ 
	font-family: verdana, Lucida sans unicode, sans-serif;
	font-size: 0.8em;
	margin-left: 20px; margin-right: 20px;
	border: 1px solid black;
	background: white;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<vgroup id="idInfo">
<html id="idCurrent" OnDrawContent="DrawCurrent"/>
<html id="idStatus" OnDrawContent="DrawStatus"/>
<spacer height="20" />
<label label="Note: Messages cannot be restored once archived to another namespace." labelClass="brownnote" />
</vgroup>
<vgroup id="fld" cellStyle="padding:5px;" enclosingStyle="padding:5px;background:#edece4;border:1px solid darkgray;-moz-border-radius:5px;width:600px;" labelPosition="left" hidden="true">
<label id="fldLabel" label="Edit Archive Settings" />
<combobox id="cmbNamespace" label="Archive to namespace:" 
editable="false" hint="Required. Select a namespace for storing archived messages." >
</combobox>
<text id="txtClassname" label="Archive manager class name:" hint="Required. Enter class name to be used for archiving messages." size="40"/>
<text id="txtDays" label="Number of days before archiving:" size="5" hint="Required. Messages older than this number of days will be archived." />
<hgroup>
<button controlClass="commandButton" caption="Save" onclick="zenPage.saveSetting();"/>
<spacer width="4" />
<button controlClass="commandButton" caption="Cancel" onclick="zenPage.cancelSetting();" />
</hgroup>
</vgroup>
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
<text id="CurrentStatus" hidden="true"/>
<label id="result" enclosingClass="note" hidden="true" value=""/>

<vgroup id="idErrors" hidden="true">
<html OnDrawContent="DrawErrorTitle"/>
<spacer height="10" />
<tablePane id="table" 
cellSpacing="2"
bodyHeight="250px"
fixedHeaders="false"
queryClass="Ens.Archive.Manager"
queryName="Errors"
maxRows="1000"
showZebra="false"
useSnapshot="true"
>
<column colName="ErrorNumber" header="Error Number"/>
<column colName="Time" header="Time"/>
<column colName="Description"/>
<column colName="MessageId" header="Message ID"/>
</tablePane>
<label label="Note: The error log will be deleted the next time Archive is run." labelClass="brownnote"/>
</vgroup>
<spacer height="20" />
<button controlClass="commandButton" id="btnArchive" caption="Run Archive" onclick="zenPage.startArchive();"/>
</pane>
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	//Set ..%GetComponentById("idTitle").title = $$$FormatText($$$Text("Archive manager settings for namespace %1:"),$namespace)
	#; Load namespace list (exclude the current namespace)
	Set tCurrentNS = $namespace
	Set tCombo = ..%GetComponentById("cmbNamespace")
	Set tNS = $O(^%SYS("Ensemble","InstalledNamespace",""))
	While tNS '= "" {
		If tNS '= tCurrentNS {
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do tCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tOption.text = tNS
			Set tOption.value = tNS
		}
		Set tNS = $O(^%SYS("Ensemble","InstalledNamespace",tNS))
	}
 
	Set ..%GetComponentById("fldLabel").label = $$$FormatText($$$Text("Edit Archive Settings for %1:"),$namespace)
	Quit 1
}

/// User clicked Configure. Allow to modify.
ClientMethod editSetting() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	this.hideTable(true);
	this.DoConfigure();
}

/// User clicked Configure. Allow to modify.
ClientMethod hideTable(flag) [ Language = javascript ]
{
	zenPage.getComponentById("idInfo").setHidden(flag);
	zenPage.getComponentById("result").setHidden(true);
	zenPage.getComponentById("idErrors").setHidden(true);

	var fld = zenPage.getComponentById("fld");
	if (flag == true) {
		fld.setHidden(false);
	} else {
		zenPage.getComponentById("cmbNamespace").setProperty("hintClass","helpText");
		zenPage.getComponentById("txtClassname").setProperty("hintClass","helpText");
		zenPage.getComponentById("txtDays").setProperty("hintClass","helpText");
		fld.setHidden(true);
	}
}

/// User clicked Save. Validate input.
ClientMethod saveSetting() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var namespace = zenPage.getComponentById("cmbNamespace");
	var classname = zenPage.getComponentById("txtClassname");
	var days = zenPage.getComponentById("txtDays");
	var ok = 1;
	if (namespace.getValue() == "") {
		namespace.setProperty("hintClass","redText");
		namespace.focus();
		ok = 0;
	} else {
		namespace.setProperty("hintClass","helpText");
	}
	
	// must be a valid class name
	if ((/^%?[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$/i).test(classname.getValue())) {
		classname.setProperty("hintClass","helpText");
	} else {
		classname.setProperty("hintClass","redText");
		if (ok == 1) classname.focus();
		ok = 0;
	}
	// must be a positive integer
	if ((/^[0-9]+$/).test(days.getValue())) {
		days.setProperty("hintClass","helpText");
	} else {
		days.setProperty("hintClass","redText");
		if (ok == 1) days.focus();
		ok = 0;
	}
	if (ok == 0) {
		// reset previous result message, if any
		zenPage.getComponentById("result").setValue("");
		return;
	}

	var ok = this.SaveData(namespace.getValue(), classname.getValue(), days.getValue());
	if (ok == 1) {
		zenPage.gotoPage("EnsPortal.ArchiveManager.cls");	
	} else {
		zenPage.writeResult(ok);
	}
}

/// User clicked Close. 
ClientMethod cancelSetting() [ Language = javascript ]
{
	this.hideTable(false);
}

ClientMethod writeResult(msg) [ Language = javascript ]
{
	zenPage.getComponentById("result").setHidden(false);		
	zenPage.getComponentById("result").setValue(msg);
}

/// Show or hide errors. 
ClientMethod showErrors() [ Language = javascript ]
{
	var errors = zenPage.getComponentById("idErrors");
	var state = errors.getProperty("hidden");
	if (state == true) {
		errors.setHidden(false);
		var table = zenPage.getComponentById("table");
		table.executeQuery();
	} else {
		errors.setHidden(true);
	}
}

/// User clicked Do Archive. 
ClientMethod startArchive() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var msg = this.msgConfirm;
	if (zenPage.getComponentById("fld").getProperty("hidden") == false) {
		msg = msg + " "+this.msgDiscard;
	}
	var ok = confirm(msg);
	if (ok == true) {
		zenPage.getComponentById("idErrors").setHidden(true);
		zenPage.getComponentById("btnArchive").setProperty("disabled",true);
		if (zenPage.enableAutoRefresh) {
			var timer = zenPage.getComponentById('timer');	
			timer.setProperty('timeout',1000);
			timer.startTimer();
		}
		var ok = this.RunBackgroundTask();
		// This is to display potential errors from %RunBackgroundMethod itself
		if (ok != 1) zenPage.writeResult(ok);
		if (!zenPage.enableAutoRefresh) {
			zenPage.doStatus();
		}
	}
}

/// Run Archive: function to control timer on updating archive progress
/// This is called from onload as well (in case it is currently being run when the page is opened)
ClientMethod timeout(timer) [ Language = javascript ]
{
	this.doStatus();
	var timer = zenPage.getComponentById('timer');
	//if status = idle then stop timer. ow continue.
	var status = this.getComponentById("CurrentStatus").getValue();
	if ((status == "running") && zenPage.enableAutoRefresh) {
		timer.startTimer();	
	} else {
		timer.clearTimer();
	}
}

/// Save settings to server.
ClassMethod SaveData(pNamespace As %String, pClassname As %String, pDays As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Archive.Manager).SetArchiveParameters(pNamespace,pClassname,pDays)
	If $$$ISERR(tSC) Set tSC = $System.Status.GetErrorText(tSC)
	Quit tSC
}

ClassMethod RunBackgroundTask() As %ZEN.Datatype.string [ ZenMethod ]
{
	#; Run method BackgroundTask in a background job.
	Set tSC = ..%RunBackgroundMethod("DoArchive")
	If $$$ISERR(tSC) Set tSC = $System.Status.GetErrorText(tSC)
	Quit tSC
}

/// Initiates archiver on the server in the background.
ClassMethod DoArchive() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do ..%SetBackgroundMethodStatus("Job Started. Please wait...")	
	#;YSD2350 Set tSC = ##class(Ens.Archive.Manager).DoArchive()
	Set tSC = ##class(Ens.Archive.Manager).GetArchiveParameters(.pNamespace, .pClassname, .pDaysToArchive)
	If $$$ISOK(tSC) Set tSC = $classmethod(pClassname,"DoArchive")
	
	If $$$ISERR(tSC) {
		#; server method error out
		Set pMsg = $System.Status.GetErrorText(tSC)
		Do ..%SetBackgroundMethodStatus(pMsg)
		#; This is to set unexpected errors like unable to lock, etc. so UI can pickup to display
		Set ^Ens.ArchiveManager("run","error") = pMsg
	} Else {
		Do ..%EndBackgroundMethod()
	}
Done
	Quit
Trap
	Set $ZT = ""
	Do ..%SetBackgroundMethodStatus($ZE)
	GoTo Done
}

/// Load current settings into Configure form.
ClassMethod DoConfigure() [ ZenMethod ]
{
	Set tSC = ##class(Ens.Archive.Manager).GetArchiveParameters(.pNamespace, .pClassname, .pDaysToArchive)	
	If $$$ISOK(tSC) {
		&js<zenPage.getComponentById("cmbNamespace").setValue("#($ZCVT(pNamespace,"O","JS"))#");>
		&js<zenPage.getComponentById("txtClassname").setValue("#($ZCVT(pClassname,"O","JS"))#");>
		&js<zenPage.getComponentById("txtDays").setValue("#($ZCVT(pDaysToArchive,"O","JS"))#");>
	}
	Quit
}

/// Draw Current parameters
Method DrawCurrent(seed As %ZEN.Datatype.string) As %Status
{
	
	Set btnEdit = $$$TextHTML("Edit")
	Set tSC = ##class(Ens.Archive.Manager).GetArchiveParameters(.pNamespace, .pClassname, .pDaysToArchive)
	If $$$ISOK(tSC) {
		#; If any of the parameters is not set then disable the "Do Archive" button
		If pNamespace=""!(pClassname="")!(pDaysToArchive="") Set ..%GetComponentById("btnArchive").disabled = 1
	}
	Set tTitle = $ZCVT($$$FormatText($$$Text("Archive settings for namespace %1:"),$namespace),"O","HTML")

	&html<
	<table class="fieldStyle"><tr><td nowrap>#(tTitle)#</td><td nowrap><input type="button" class="commandButton" value="#(btnEdit)#" onclick="zenPage.editSetting();"></td></tr></table>

	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">
	<tr><th>#($$$TextHTML("Name"))#</th><th>#($$$TextHTML("Value"))#</th></th>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Archive to namespace"))#:</td><td class="DetailValue" >#($ZCVT(pNamespace,"O","HTML"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Archive manager class name"))#:</td><td class="DetailValue" >#($ZCVT(pClassname,"O","HTML"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Number of days before archiving"))#:</td><td class="DetailValue" >#($ZCVT(pDaysToArchive,"O","HTML"))#</td></tr>
	</table>>
	
	Quit $$$OK
}

/// Draw current archive status
Method DrawStatus(seed As %ZEN.Datatype.string) As %Status
{
	
	Set tTitle = %page.lblHistory //$$$TextHTML("Archive history")
	Set tStatusTrans("idle") = $$$Text("idle")
	Set tStatusTrans("running") = $$$Text("running")
	Set RunningStartTime = ##class(Ens.Archive.Manager).GetRunningStartTime()
	Set RunningStopTime = ##class(Ens.Archive.Manager).GetRunningStopTime()	
	Set RunningStatus = ##class(Ens.Archive.Manager).GetRunningStatus()
	Set RunningPercentage = ##class(Ens.Archive.Manager).GetRunningPercentage()
	#; total-processed, total-archived, total-header-deleted, total-body-deleted
	Set RunningCount = ##class(Ens.Archive.Manager).GetRunningCount()
	Set tTotal("Processed") = $P(RunningCount,",",1)
	Set tTotal("Archived") = $P(RunningCount,",",2)
	Set tTotal("DeletedHead") = $P(RunningCount,",",3)
	Set tTotal("DeletedBody") = $P(RunningCount,",",4)
	Set tTotal("NumberErrors") = $P(RunningCount,",",5)
	
	If RunningStartTime = "" {
		Set RunningStartTime = %page.lblHistoryNone	//$$$TextHTML("No history found")
	} Else {
		Set RunningStatus = tStatusTrans(RunningStatus)
		If RunningPercentage '= "" {
			Set tTotal("Processed") = tTotal("Processed") _ " - "_$$$FormatText($$$Text("%1% finished"),RunningPercentage)
		}
	}  	
	Set pMsg = ..GetBackgroundMethodStatus()
	If pMsg '= "" Set RunningStatus = pMsg

	&html<
	<table class="fieldStyle"><tr><td>#(%page.lblHistory)#:</td>>
	If '..enableAutoRefresh && (RunningStatus = "running") {
		Set tRefresh = $$$TextHTML("Refresh archive status")
		&html<	<td nowrap>
				<image src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.doStatus();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
			</td>>
	}
	&html<
	</tr></table>
	<table class="DetailTable" border="0" cellspacing="5" cellpadding="0">
	<tr class="EvenRow"><td class="DetailValue" nowrap>#(%page.lblStartTime)#</td><td class="DetailValue" >#($ZCVT(RunningStartTime,"O","HTML"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#(%page.lblStopTime)#</td><td class="DetailValue" >#($ZCVT(RunningStopTime,"O","HTML"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#(%page.lblTotalProcessed)#</td><td class="DetailValue" >#(tTotal("Processed"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#(%page.lblTotalArchived)#</td><td class="DetailValue" >#(tTotal("Archived"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#(%page.lblTotalDeletedHead)#</td><td class="DetailValue" >#(tTotal("DeletedHead"))#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#(%page.lblTotalDeletedBody)#</td><td class="DetailValue" nowrap>#(tTotal("DeletedBody"))#</td></tr>
	>

	If tTotal("NumberErrors") > 0 {
		Set lblShowErrors = $$$TextHTML("show/hide error log")
		&html<<tr class="EvenRow"><td class="DetailValue" >#(%page.lblNumberErrors)#</td>
		<td class="DetailValue" nowrap >#(tTotal("NumberErrors"))#
		&nbsp;&nbsp;<a onclick="javascript:zenPage.showErrors();" onmouseover="this.oldcolor=this.style.color; this.style.color='red';this.style.cursor='pointer';" onmouseout="this.style.color=this.oldcolor;this.style.cursor='auto';" class='link'>#(lblShowErrors)#</a>
		</td></tr>>
	}
	&html<<tr class="EvenRow"><td class="DetailValue" nowrap>#(%page.lblStatus)#</td><td class="DetailValue" nowrap>#(RunningStatus)#</td></tr>>
	&html<</table>>
	Quit $$$OK
}

/// Draw error log title
Method DrawErrorTitle(seed As %ZEN.Datatype.string) As %Status
{
	&html<
	<table class="fieldStyle"><tr><td>#(%page.lblErrorLog)#:</td><td align="right"></td></tr></table>
	>
	Quit $$$OK
}

/// This method gets current archive status and return proxyObject 
/// to javascript caller for the caller to update the UI.
ClassMethod GetArchiveStatus() As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set RunningStatus = ##class(Ens.Archive.Manager).GetRunningStatus()
		
	Set tProxy.Status = RunningStatus
	Set tProxy.DisableArchive = 0
	#; Load current values
	Set tSC = ##class(Ens.Archive.Manager).GetArchiveParameters(.pNamespace, .pClassname, .pDaysToArchive)
	If $$$ISOK(tSC) {
		#; If any of the parameters is not set then disable the "Do Archive" button
		If pNamespace=""!(pClassname="")!(pDaysToArchive="") Set tProxy.DisableArchive = 1
	}
	Quit tProxy
}

/// This client event, if present, is fired when the page is loaded.
/// Start the timer so we can check the status. If there is an archive currently running,
/// you will see continous update until job is finished.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	
	this.doStatus();
	if ((zenPage.Status == "running") && zenPage.enableAutoRefresh) {
		var timer = zenPage.getComponentById('timer');	
		timer.setProperty('timeout',1000);
		timer.startTimer();
	}
}

/// This method calls server method to get current archive status and update the UI.
ClientMethod doStatus() [ Language = javascript ]
{
	var idStatus = zenPage.getComponentById('idStatus');
	idStatus.refreshContents();
	var btnArchive = this.getComponentById("btnArchive");
	var tProxy = zenPage.GetArchiveStatus();
	if (tProxy.DisableArchive == 1) {
		btnArchive.setProperty("disabled",true);
	} else {
		if (tProxy.Status == "running") btnArchive.setProperty("disabled",true);
		else btnArchive.setProperty("disabled",false);
		this.getComponentById("CurrentStatus").setValue(tProxy.Status);
	}
	return;
	/*

	if (tProxy.StartTime != "") {
		this.getComponentById("RunningStartTime").setValue(tProxy.RunningStartTime);
		this.getComponentById("RunningStopTime").setValue(tProxy.RunningStopTime);
	} 
	this.getComponentById("RunningStatus").setValue(tProxy.RunningStatus);	
	if (tProxy.Count != 0) { 
		this.getComponentById("RunningCount").setValue(tProxy.RunningCount);
	}
	if (tProxy.ErrorMessage != "") this.getComponentById("RunningStatus").setValue(tProxy.ErrorMessage);
	*/
}

/// Get background method status.
ClassMethod GetBackgroundMethodStatus() As %String
{
	Set pMsg = $G(^Ens.ArchiveManager("run","error"))
	If $E(pMsg,1,5) '= "ERROR" Set pMsg = ""
	Quit pMsg
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Archive Manager","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = ..%OnGetPageName()
	// commands: $LB(id,caption,help,onclick)
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Set tResList = $case(pMethod,
							"SaveData": ..#EDITRESOURCE,
							"RunBackgroundTask": ..#EDITRESOURCE,
							"DoArchive": ..#EDITRESOURCE,
							: "")
	Quit tResList
}

}
