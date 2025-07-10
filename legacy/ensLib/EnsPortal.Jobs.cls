/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the Jobs page of the ZEN application.
Class EnsPortal.Jobs Extends EnsPortal.Template.listPage [ System = 4 ]
{

/// User needs READ permissions on the %Ens_Jobs resource to access this page.
Parameter RESOURCE = "%Ens_Jobs:READ";

Parameter JOBSRESOURCE = "%Ens_Jobs:WRITE";

Parameter SUSPENDRESOURCE = "%Ens_MessageSuspend:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Currently Active Jobs";

Property showRefresh As %Boolean [ InitialExpression = 1 ];

/// This XML block defines the contents of the table pane.
XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup valign="top">
<spacer width="10" />
<vgroup valign="top">
<spacer height="10" />
<tablePane id="table" 
    cellSpacing="2"
	dataSource="columns"
	queryClass="EnsPortal.Jobs"
	queryName="Enumerate"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="Job"
	maxRows="2000"
	nowrap="false"
	>
<parameter id="filter" value=""/>
<parameter id="queryMethod" value="Enumerate"/>
<parameter id="queryClass" value="Ens.Job"/>
<column header="Job" colName="Job" />
<column header="Configuration Name" colName="ConfigName"/>
<column header="Mode" colName="Mode"/>
<column header="Status" colName="Status"/>
<column header="Detail" colName="Detail"/>
<column header="Active Message" colName="ActiveMessage" />
<column header="State" colName="State" />
</tablePane>
</vgroup>
</hgroup>
</pane>
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "Job:%String,ConfigName:%String,Mode:%String,Status:%String,Detail:%String,ActiveMessage:%String,State:%String") [ SqlProc ]
{
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Currently Active Jobs","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	// include a search box in the ribbon
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()
	// commands: $LB(id,caption,help,onclick)
	#dim n = 0
	Set pCommands($I(n)) = $LB("abortButton",$$$Text("Abort"),$$$Text("Abort the current message being retried for the selected job"),"zenPage.jobAbortMsg();")
	Set pCommands($I(n)) = $LB("suspendButton",$$$Text("Suspend"),$$$Text("Suspend the current message being retried for the selected job"),"zenPage.jobSuspendMsg();")
	Set pCommands($I(n)) = $LB("stopButton",$$$Text("Stop"),$$$Text("Stop the selected job"),"zenPage.jobStop();")

	Quit $$$OK
}

ClientMethod jobAbortMsg() [ Language = javascript ]
{
	if (!this.checkHelper('JobsEdit')) { // TODO: Modify resource when action is clearer.
		return false;
	}

	var tblJobs = zenPage.getComponentById('table');

	if (tblJobs.rowCount == 1) {
		tblJobs.selectRow(0,false);
	}
	var job = tblJobs.getProperty('value');
	if (!job || ''==job) { alert($$$Text('No job selected')); return false; }

	if (confirm($$$FormatText($$$Text("Do you wish to abort the active message being retried in job '%1' ?"),job))) {
		var msg=zenPage.AbortJobMsg(job);
		if ('' == msg) {
			alert($$$FormatText($$$Text("Active message aborted for job '%1'"),job));
		} else {
			alert($$$FormatText($$$Text("Error aborting message for job '%1': %2"),job,msg));
		}
		return true;
	}
	return false;
}

ClassMethod AbortJobMsg(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).AbortOperation(pJob)	
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod jobSuspendMsg() [ Language = javascript ]
{
	if (!this.checkHelper('SuspendMessage')) {
		return false;
	}
	var tblJobs = zenPage.getComponentById('table');

	if (tblJobs.rowCount == 1) {
		tblJobs.selectRow(0,false);
	}
	var job = tblJobs.getProperty('value');
	if (!job || ''==job) { alert($$$Text("No job selected")); return false; }

	if (confirm($$$FormatText($$$Text("Do you wish to suspend the active message being retried for job '%1' ?"),job))) {
		var msg=zenPage.SuspendJobMsg(job);
		if ('' == msg) {
			alert($$$FormatText($$$Text("Active message suspended for job '%1'"),job));
		} else {
			alert($$$FormatText($$$Text("Error suspending message for job '%1': %2"),job,msg));
		}
		return true;
	}
	return false;
}

ClassMethod SuspendJobMsg(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).SuspendOperation(pJob)
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod jobStop() [ Language = javascript ]
{
	if (!this.checkHelper('JobsEdit')) {
		return false;
	}

	var tblJobs = zenPage.getComponentById('table');

	if (tblJobs.rowCount == 1) {
		tblJobs.selectRow(0,false);
	}
	var job = tblJobs.getProperty('value');
	if (!job || ''==job) { alert($$$Text("No job selected")); return false; }

	if (confirm($$$FormatText($$$Text("Are you sure you want to stop instance job '%1'? It will be forcibly stopped if it fails to respond within the Update Timeout. Updating the Production subsequently may start a fresh instance job for this item."),job))) {
		var msg=zenPage.StopJob(job);
		if ('' == msg) {
			tblJobs.setProperty('value','');
			tblJobs.executeQuery();
			tblJobs.selectRow(-1);
			alert($$$FormatText($$$Text("Job '%1' stopped"),job));
		} else {
			alert($$$FormatText($$$Text("Error stopping job '%1': %2"),job,msg));
		}
		return true;
	}
	return false;
}

ClassMethod StopJob(pJob As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Job).Stop(pJob,$G($$$ConfigProdSetting("UpdateTimeout"),10),1)
	Quit:$$$ISERR(tSC) $$$StatusDisplayString(tSC)
	Quit ""
}

ClientMethod checkHelper(toCheck, noAlert) [ Language = javascript ]
{
	if ((toCheck == null) || (!this.securityHelper) || (this.securityHelper[toCheck] == null)) {
		return true;
	}
	if (parseInt(this.securityHelper[toCheck],10) != 1) {
		if (!noAlert) {
			alert(this.msgNotPermitted);
		}
		return false;
	}
	return true;
}

ClientMethod updateSecurityHelper() [ Language = javascript ]
{
	var newHelper = zenPage.GetSecurityHelper();
	if (newHelper) {
		zenPage.securityHelper = newHelper;
	}
	return true;
}

ClassMethod GetSecurityHelper() As %ZEN.proxyObject [ ZenMethod ]
{
	Set tSecurityHelper = ##class(%ZEN.proxyObject).%New()
	
	// List of checked values for the user: propertyName, resource, permission
	Set tChecks = $lb(	$lb("SuspendMessage", $p(..#SUSPENDRESOURCE,":",1),$p(..#SUSPENDRESOURCE,":",2)),
						$lb("JobsEdit", $p(..#JOBSRESOURCE,":",1),$p(..#JOBSRESOURCE,":",2)))	
	For i=1:1:$ll(tChecks) {
		Set tCheck = $lg(tChecks, i)
		Set tArray($lg(tCheck, 1)) = $system.Security.Check($lg(tCheck, 2), $lg(tCheck, 3))
	}
	
	Do tSecurityHelper.%CopyFromArray(.tArray)
	Quit tSecurityHelper
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"AbortJobMsg": ..#JOBSRESOURCE,
				"SuspendJobMsg": ..#SUSPENDRESOURCE,
				"StopJob": ..#JOBSRESOURCE,
				: "")
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var ok = this.updateSecurityHelper();
}

}
