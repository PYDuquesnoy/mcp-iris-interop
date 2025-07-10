/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This page lets users view the history of deployments
Class EnsPortal.Deployment.DeploymentHistory Extends EnsPortal.Template.listPage [ System = 4 ]
{

/// JavaScript debug library
/// Usage: ZLM.dumpObj(object);
Parameter JSINCLUDES = "zenCSLM.js";

/// Displayed name of this page.
Parameter PAGENAME = "Deployment History";

/// User needs use permissions on %Ens_Deploy to use this page.
Parameter RESOURCE = "%Ens_Deploy";

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

/// Id of selected item in results table.
Property selectedId As %ZEN.Datatype.string;

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#table {
	overflow: auto;
}
</style>
}

XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top">
<spacer width="20"/>
<vgroup valign="top">
<spacer height="20"/>
<tableNavigatorBar showFilter="true" onfilterChange="zenPage.searchBoxHandler(value);" showMaxRows="false" showPageSize="true" tablePaneId="table"/>
<tablePane id="table" 
queryClass="EnsPortal.Deployment.DeploymentHistory"
queryName="Enumerate"
hidden="false" 
useSnapshot="true"
autoExecute="true"
pageSize="20"
maxRows="0"
showZebra="true"
onselectrow="zenPage.rowSelected(zenThis);"
onunselectrow="zenPage.rowSelected(zenThis);"
nowrap="true"
valueColumn="ID"
>
<parameter id="filter" value=""/>
<parameter id="queryMethod" value="InitQuery"/>
<parameter id="queryClass" value="EnsPortal.Deployment.DeploymentHistory"/>
<column colName="ID" disableSort="true" />
<column colName="InProgress" header="Status" cellTitle="Identifies if in progress or completed." OnDrawCell="InProgressWarning" disableSort="true"/>
<column colName="Username" disableSort="true"/>
<column colName="StartTime" disableSort="true"/>
<column colName="EndTime" disableSort="true"/>
<column colName="TargetProduction As Production" disableSort="true"/>
<column colName="DeploymentFilename" disableSort="true"/>
<column colName="TargetProduction" hidden="true"/>
<column colName="Completed" hidden="true"/>
<column colName="Reverted" hidden="true"/>
<column colName="DeploymentFileStream" hidden="true"/>
<column colName="RolledbackById" hidden="true"/>
<column colName="ThisIsARollback" hidden="true"/>
<column colName="LastStatus" hidden="true"/>
</tablePane>
</vgroup>
</hgroup>
</pane>
}

Query InitQuery() As %SQLQuery
{
	SELECT ID,InProgress,Username,StartTime,EndTime,TargetProduction,DeploymentFilename,Reverted,RolledbackById,LastStatus,Completed,ThisIsARollback FROM Ens_Deployment.Invocations ORDER BY ID Desc
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "ID,InProgress,Username,StartTime,EndTime,TargetProduction,DeploymentFilename,Reverted,RolledbackById,LastStatus,Completed,ThisIsARollback") [ SqlProc ]
{
}

Method InProgressWarning(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query(pName) { 
 		If ##class(Ens.Deployment.Deploy).IsDeploymentTokenUnlocked() {
	 		Set tMsg = 	$$$Text("Marked as In Progress but not active.")
	 		Set tMsg = tMsg_"<br/> "_$$$Text("Click to clear InProgress.")
	 		Set tText = "<span style=color:red;><a onclick='zenPage.clearInProgress();' title='Clear the InProgress Flag' href='#'> "_tMsg_"</a></span>" 
 		} Else {
	 		Set tMsg = 	$$$Text("Active In Progress")
	 		Set tText = "<span style=color:red;>"_tMsg_"</span>" 
	 	}
 	} ElseIf %query("Reverted"){
		Set tText = $$$Text("Reverted due to error")
	} ElseIf %query("RolledbackById"){
		Set tText = $$$Text("Deployment rolled back")
	} Elseif $$$ISERR(%query("LastStatus")) { 
 		Set tText = $$$Text("Ended in Error")
	} Elseif %query("Completed") { 
 		Set tText = $$$Text("Completed")
 	} Else { Set tText = $$$Text("Not Started") }
 	Set:(%query("ThisIsARollback") = 1) tText = tText_" ("_$$$Text("Rollback file")_")"
 	Write tText
 Quit $$$OK
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'DeploymentDetails':
		break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
		break;
	}
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Deployment History")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	Set pCommands(1) = $LB("detailsButton",$$$Text("Details"),$$$Text("View the details for the deployment"),"zenPage.viewDetails();")
	Set pCommands(2) = $LB("rollButton",$$$Text("Rollback"),$$$Text("Rollback the selected deployment"),"zenPage.rollBack();")
	Set pCommands(3) = $LB("delButton",$$$Text("Delete"),$$$Text("Delete the currently selected service or client from the registry"),"zenPage.deleteHistory();")
	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.adjustSizes();
		if (load) {
			this.rowSelected(zen('table'));	
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var tableBodyDiv = zen('table').getEnclosingDiv();
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th;
		var packageHgt = hgt - 50;
		var packageWid = winWidth - 50;
		tableBodyDiv.style.width = packageWid + 'px';
		if (packageHgt > 100) {
			tableBodyDiv.style.height = packageHgt + 'px';
			tableBodyDiv.style.overflowY = "auto";
		}
		else {
			tableBodyDiv.style.height = (parseInt(tableBodyDiv.scrollHeight,10) + 5) + 'px';
			tableBodyDiv.style.overflowY = "visible";
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Get a row from the table snapshot.
ClientMethod getRowFromSnapshot() [ Language = javascript ]
{
	var table = this.getComponentById('table');
	var index = table.getProperty('selectedIndex');
	if (index < 0) {
		alert('No row is selected in the table.');
		return;
	}
	var data = table.getRowData(index);
	if (data == null) {
		alert('Table is not in snapshot mode or invalid request.');
	}
	else {
		// unpackage returned object
		var msg = '';
		for (var p in data) {
			if (p == 'Status') {
				msg += 'InProgress' + ': ' + data[p] + '\n';
			} else {
				msg += p + ': ' + data[p] + '\n';
			}
		}
		alert('Row data:\n--------------\n'+msg);
	}
}

ClientMethod viewDetails() [ Language = javascript ]
{
	if (this.selectedId == -1) {
		alert($$$Text("First select a past deployment in the table, then click Details to view the details of the deployment."));
		return;
	}
	var parms = {
		InvocationID: this.selectedId
	};
	zenPage.launchPopupWindow('EnsPortal.Dialog.DeploymentDetails.zen',this.addPopupSuffix('DeploymentDetails'),'status,scrollbars,resizable=yes,width=900,height=600',parms);
}

ClientMethod rollBack() [ Language = javascript ]
{
	if (this.selectedId == -1) {
		alert($$$Text("First select a past deployment in the table, then click Rollback to rollback the deployment."));
		return;
	}
	var id = this.selectedId;
	var checks = zenPage.RollBackChecks(id);
	if (checks == '-1') {
		alert($$$Text("Cannot Roll back since unable to check if safe to rollback for id "+id));
		return;
		}
	var checksSplit = checks.split('^');
	if (checksSplit[0] == '1') {
		alert($$$Text("Cannot Roll back since marked InProgress"));
		return;
		}
	if (checksSplit[1] == '1') {
		alert($$$Text("Cannot Roll back since marked Reverted"));
		return;
		}
	if (checksSplit[2] !== '') {
		alert($$$Text("Already Rolled back"));
		return;
		}
	if (checksSplit[3] == '1') {
		alert($$$Text("Cannot Roll back since this is a roll back"));
		return;
		}
	
	if (confirm($$$Text("Do you wish to rollback this deployment?"))) {
		/* 	Need to export the rollback file to an os file
			Generate filenames and then call the DeployProductionChanges page
		*/
		var page = zenPage.ConstructRollback(id);
		if (page == '') {
			alert($$$Text('Failed to generate rollback file. You can manually deploy the original rollback file.'));
		} else {
			this.gotoPage(page);
			}
	}
  	return;
}

ClientMethod clearInProgress() [ Language = javascript ]
{
	msg = $$$Text("It is possible the deployment just started.")+"\n"+ $$$Text("View Details and refresh screen to check.")+"\n"+ $$$Text("Press OK to clear In Progress flag or Cancel to check.")
	if (confirm(msg)) {
		var status = zenPage.ForceClear(); /* make synch call so finishes before reload */
		self.document.location.reload();	
	}
}

Method ForceClear() As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	$$$LOGINFO("Clearing Deployment InProgress Flag")
	Set tSC = ##class(Ens.Deployment.Deploy).ClearDeploymentInProgressFlag()
	Quit tSC
}

ClientMethod deleteHistory() [ Language = javascript ]
{
	if (this.selectedId == -1) {
		alert($$$Text("First select a past deployment in the table, then click Delete to delete the deployment history details."));
		return;
	}	
	var msg = $$$Text("Do you wish to delete this deployment history record?");
	if (confirm(msg)) {
		var status = zenPage.DeleteRecord(this.selectedId);
  		if (status == 1) {
	  		 alert($$$Text("Removal of history record succeeded."));
	  		 self.document.location.reload();	
  		} else if (status == -1) {
  			alert($$$Text("Not allowed to delete most recent history record."));
		} else { 
			alert($$$Text("Removal of history record failed."));
		}
  		return;
	}
}

Method DeleteRecord(pId As %String) As %Integer [ ZenMethod ]
{
	Set tSC = 1
	Try {
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare("SELECT InvocationId FROM Ens_Deployment.Token")
		Set tResults = tStatement.%Execute()
		If tResults.%Next() {
			If (pId = tResults.InvocationId) {
				Set tSC = -1	
			} Else {
				Set tSC = ##class(Ens.Deployment.Invocations).%DeleteId(pId)	
			}
		} Else { 
			Set tSC = 0
		}
	} Catch (ex) {
			Set tSC = 0
	}
	Quit +tSC
}

Method RollBackChecks(pInvocationId As %String) As %String [ ZenMethod ]
{
	Set tAns = "-1", tSC = $$$OK
	Try {
		Set tInvocation = ##class(Ens.Deployment.Invocations).%OpenId(pInvocationId,,.tSC)
	} Catch e { Set tSC = e.AsStatus()}
	Set:tSC tAns=tInvocation.InProgress_"^"_tInvocation.Reverted_"^"_tInvocation.RolledbackById_"^"_tInvocation.ThisIsARollback
	Quit tAns
}

Method ConstructRollback(pInvocationId As %String) As %String [ ZenMethod ]
{
	Set tPage = ""
	Try {
		Set tInvocation = ##class(Ens.Deployment.Invocations).%OpenId(pInvocationId,,.tSC)
		Quit:($$$ISERR(tSC))
		Set tTargetProduction = tInvocation.TargetProduction
		Set tDeploymentFileFromInput = ##class(%Stream.FileBinary).%New()
		Set tPriorDeploymentFile = tInvocation.DeploymentFilename
		Set tDeployDirectory = ##class(%File).GetDirectory(tPriorDeploymentFile,1)
		Set tDeployFile = ##class(%File).GetFilename(tPriorDeploymentFile)
		If '##class(%File).DirectoryExists(tDeployDirectory) {
			Set tSCD = ##class(%File).CreateDirectory(tDeployDirectory)
			/* could be on a different system (mirror system) with different drives */
			Set tTempDeploymentFile = ##class(%File).TempFilename()
			Set tDeployDirectory = ##class(%File).GetDirectory(tTempDeploymentFile,1)
		}
		Set pDeploymentFile = tDeployDirectory_"Rollback_of_"_tDeployFile
		Set tDeploymentFileFromInput.Filename = pDeploymentFile
		Set tSC = tDeploymentFileFromInput.CopyFromAndSave(tInvocation.DeploymentRollbackFileStream)
		Quit:($$$ISERR(tSC))
		Set tDeploymentFile = tDeploymentFileFromInput.Filename /* reset DeploymentFile to just a file name */
		Set tDeploymentFileFromInput = ""
		Do ##class(Ens.Deployment.Utils).GenerateFileNames(pDeploymentFile,.tRollbackFilename,.tLogFile,.tReportFile)
		Set tPage = "EnsPortal.Deployment.DeployProductionChanges.zen?DFILE="_pDeploymentFile_"&TARGETPROD="_tTargetProduction_"&BCKFILE="_tRollbackFilename_"&LOGFILE="_tLogFile
	} Catch ex {
		Set tPage = ""
	}	
	Quit tPage
}

/// User selected a row in the table
ClientMethod rowSelected(table) [ Language = javascript ]
{
	// set flag to compensate for tablePane not reporting selecteId -1 for unselected row
	zenPage.noSel = (table.selectedIndex == -1);
	zenPage.selectItem(table);
}

/// Select the given item (row in table) and let the subclass take any
/// necessarey actions like updating the details pane.
ClientMethod selectItem(row) [ Language = javascript ]
{
	if (row && (typeof row == 'object')) { // got passed the tablePane object
		this.selectedId = row.getValue();
	}
	else {
		this.selectedId = -1;
	}
	this.onSelectItem();
}

/// toggle detailTable for a selected row.
ClientMethod onSelectItem() [ Language = javascript ]
{
	if (zenPage.noSel) this.selectedId = -1;
	var selected = (this.selectedId != -1);

	var btn = document.getElementById('command_detailsButton');
	if (btn) {
		btn.className = (!selected ? 'commandButtonDisabled' : 'commandButton');
		btn.style.cursor = (!selected ? 'default' : 'pointer');
		btn.title = (!selected ? $$$Text('Please select a deployment') : $$$Text('View the details for the deployment'));
	}
	btn = document.getElementById('command_delButton');
	if (btn) {
		btn.className = (!selected ? 'commandButtonDisabled' : 'commandButton');
		btn.style.cursor = (!selected ? 'default' : 'pointer');
		btn.title = (!selected ? $$$Text('Please select a deployment') : $$$Text('Delete the deployment history details'));
	}
	btn = document.getElementById('command_rollButton');
	if (btn) {
		btn.className = (!selected ? 'commandButtonDisabled' : 'commandButton');
		btn.style.cursor = (!selected ? 'default' : 'pointer');
		btn.title = (!selected ? $$$Text('Please select a deployment') : $$$Text('Rollback the selected deployment'));
	}
}

}
