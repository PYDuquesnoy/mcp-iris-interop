/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsPortal.EDI.SEF.SchemaMain Extends EnsPortal.EDI.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "View Schemas";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css,ensemble/Ensemble_EDI.css";

Property Family As %String(ZENURL = "FAMILY");

Property Status As %String;

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="20"/>
<hgroup valign="top">
<spacer width="20"/>
<vgroup valign="top">
<vgroup enclosingClass="wizardBox" valign="top">
<spacer height="10" />
<form id="theForm" align="center" onvalidate="return zenPage.validateAll();" >
<hidden name="browseselect" id="browseselect"/>
<vgroup valign="top">
<combobox id="actionSpec" name="actionSpec" label="Choose Action" size="42" 
		valueList="View,Import,Remove" 
		displayList="View All Schemas,Import Schema from File,Remove Schema" 
		title="Specify which action you want to perform on #(%page.Family)# schemas."
		value="View"
		  onchange="zenPage.changeAction();" />
<hgroup id="inFileFields" cellVAlign="bottom" hidden="true" >
<text id="inFile" name="inFile" label="Enter Path and Filename" size="22"/>
<button caption="Browse..." controlClass="commandButton" containerStyle="padding-left:2px;" 
		onclick="zenPage.browseSelect('inFile','*');"/>
</hgroup>
<combobox id="categoryName" name="categoryName" label="Choose Schema Category" size="42" hidden="true" />
<hgroup id="outFileFields" cellVAlign="bottom" hidden="true" >
<text id="outFile" name="outFile" label="Enter Full Pathname (Overwrite)" size="22"	
		title="Enter a path and filename. If a file with this name already exists in this path, it will be overwritten." />
<button caption="Browse..." controlClass="commandButton" containerStyle="padding-left:2px;"
		onclick="zenPage.browseSelect('outFile','*');"/>
</hgroup>
<spacer height="10" />
<hgroup align="center">
 <!-- invokes the current operation, either View, Import, or Remove --> 
 <button name="OK" id="OK" caption=" OK " controlClass="commandButton" onclick="zenPage.btnOK();" title="" />
 <spacer width="10"/>
 <button name="Cancel" id="Cancel" caption="Cancel" controlClass="commandButton" onclick="zenPage.gotoPage(zenPage.GetHomePage());" title="Cancel this operation and return to the home page." />
</hgroup>
</vgroup>
</form>
<spacer height="10" />
</vgroup>
<spacer height="10" />
<!-- for displaying status updates during a background import job -->
<html id="idStatus" OnDrawContent="DrawStatus"/>
<!-- for periodically updating the status display during a background import job -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</vgroup>
<spacer width="20"/>
<html id="content" OnDrawContent="DrawContent" valign="top" />
<spacer width="20"/>
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
	if ((zenPage.Status == "running") && zenPage.enableAutoRefresh) {
		var timer = zenPage.getComponentById('timer');	
		timer.setProperty('timeout',1000);
		timer.startTimer();
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

	// if status = idle then stop timer; otherwise continue
	if ((zenPage.Status == "running") && zenPage.enableAutoRefresh) {
		timer.startTimer();
	} else {
		timer.clearTimer();
	}
}

/// This timer method calls a server method to get the current background import job status and update the UI.
ClientMethod doStatus() [ Language = javascript ]
{
	// invoke DrawStatus() which will get and display all the status information
	zen("idStatus").refreshContents(); 

	// get the status string
	zenPage.Status = zenPage.GetImportStatus();

	// if done, refresh the page so it reflects the newly imported data
	if (zenPage.Status == "done") { 
		msg = zenPage.GetJobStatus();
		if (msg.length > 0) { // job experienced an error
			alert($$$Text("Background import job was unsuccessful.")+" "+msg);
		} else {
			alert($$$Text("Background import job completed successfully."));
		}
		// self.document.location.reload() here does not work, so do a gotoPage to the same page
		zenPage.gotoPage("EnsPortal.EDI.SEF.SchemaMain.zen?FAMILY="+zenPage.Family);
	}
	return;
}

/// Draw current import status; intended for use with background import jobs.
Method DrawStatus(seed As %ZEN.Datatype.string) As %Status
{
	// If there is no start time, or if we are marked complete, we are not underway
	Set RunningStartTime = ..GetRunningStartTime()
	If ((""=RunningStartTime) || (..GetCompletionValue() > 0)) { // done (2) or idle (1) or running (0)
		Quit $$$OK 
	}

	// Get the values needed for the status table
	Set tTitle = $$$TextHTML("Import in progress")
	Set tDuration = $$$TextHTML("Duration")
	Set RunningFileName = ..GetRunningFileName()
	Set RunningDuration = ..GetRunningDuration()	

	If ..enableAutoRefresh {
		// Draw the status table
		&html<
			<table>
				<tr><td>#(tTitle)#:</td></tr>
			</table>
			<table border="0" cellspacing="5" cellpadding="0">
				<tr><td>#(RunningFileName)#</td></tr>
				<tr><td nowrap>#(tDuration)#: #($ZCVT(RunningDuration,"O","HTML"))#</td></tr>
			</table>
		>
	} Else {
		// Draw Refresh
		Set tRefresh = $$$TextHTML("Refresh status")
		Set tTitle = $$$TextHTML("Import in progress.  Click to check if complete")
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

/// Use when the import job is running in the background to check on running status.
/// Returns either "running" or "idle" or "done".
ClassMethod GetImportStatus() As %String [ ZenMethod ]
{
	Quit ..GetRunningStatus()
}

/// Use when the import job is running in the background to check on running status.
/// Returns either "running" or "idle" or "done".
ClassMethod GetRunningStatus() As %String
{
	If (..GetCompletionValue()=2) {		// we're done
		Do ..SetCompletionValue(1) 	  	// change to idle
		Quit "done" 
	}
	lock +^IRIS.Temp.SEFImport($USERNAME,"lock"):0 set locktest=$T lock -^IRIS.Temp.SEFImport($USERNAME,"lock")
	If locktest=0 {
		Do ..SetCompletionValue(0) 	  	// it's running
		Quit "running"
	}
	Else {								// nothing is going on
		Do ..SetCompletionValue(1) 	  	// change to idle
		Quit "idle" 
	}
}

/// Use when the import job is running in the background to check on error status.
/// An empty string means no error; otherwise it is an error message.
ClassMethod GetJobStatus() As %String [ ZenMethod ]
{
	Set pMsg = $G(^IRIS.Temp.SEFImport($USERNAME,"run","error"))
	If $E(pMsg,1,5) '= "ERROR" Set pMsg = ""
	Quit pMsg
}

/// Use when the import job is running in the background to check on status.
ClassMethod GetRunningStartTime() As %String
{
	quit $G(^IRIS.Temp.SEFImport($USERNAME,"run","start"))
}

/// Use when the import job is running in the background to check on status.
ClassMethod GetRunningFileName() As %String
{
	quit $G(^IRIS.Temp.SEFImport($USERNAME,"run","file"))
}

/// Use when the import job is running in the background to check on status.
/// Gets the number of seconds job has been running (or ran, if complete)
/// and formats it nicely as a string.
ClassMethod GetRunningDuration() As %String
{
	// Get the duration in seconds
	Set stopH = $G(^IRIS.Temp.SEFImport($USERNAME,"run","stop"))
	If ""=stopH { // we haven't stopped yet, use current time
		Set stopH = $H
	}
	Set startH = $G(^IRIS.Temp.SEFImport($USERNAME,"run","start"))
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
	quit $G(^IRIS.Temp.SEFImport($USERNAME,"run","completed"))
}

ClassMethod SetCompletionValue(pValue As %Integer) As %Boolean
{
	Set ^IRIS.Temp.SEFImport($USERNAME,"run","completed") = pValue
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wild) [ Language = javascript ]
{
	if ((name == 'inFile') && !this.checkEdit()) {
		return false;
	}
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	if (Dir.length <= 0) Dir = zenPage.GetDefaultDir();
	var parms = {
		Dir: Dir,
		wildcard:wild
		};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.fileSelect.zen'),this.addPopupSuffix('SEFFileSelect'),'resizable,width=600,height=700',parms);
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
		case 'SEFFileSelect':
			var name = zenPage.getComponentById("browseselect").getValue();
			zenPage.getComponentById(name).setValue(value);
			zenPage.SetDefaultDir(value);
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

/// The input value is the name of the new namespace to switch to.
/// This method will need to be overridden for classes such as EnsPortal.EDIDocumentView 
/// which cannot work without a URL parameter provided.
ClientMethod changeURLNamespace(value) As %String [ Language = javascript ]
{
	var url = zenPage.GetNewURL(value, "EnsPortal.EDI.SEF.SchemaMain.zen?FAMILY=" + zenPage.Family);
	self.document.location = url;
}

/// What to do when the user selects a new actionSpec value.
ClientMethod changeAction() [ Language = javascript ]
{
	var val = zen('actionSpec').getValue(); // View,Import,Remove
	switch (val) {
		case 'Import':
		case 'Remove':
			if (!this.checkEdit()) {
				return false;
			}
			break;
	}
	if (val.match('View')) {
		zen('inFileFields').setHidden(1);
		zen('categoryName').setHidden(1);
		zen('outFileFields').setHidden(1);
	}
	else if (val.match('Import')) {
		zen('inFileFields').setHidden(0);
		zen('categoryName').setHidden(1);
		zen('outFileFields').setHidden(1);
	}
	else if (val.match('Remove')) {
		zen('inFileFields').setHidden(1);
		zen('categoryName').setHidden(0);
		zen('outFileFields').setHidden(1);
	}
	else {
		// this should never happen
	}
}

ClientMethod btnOK() [ Language = javascript ]
{
	var val = zen('actionSpec').getValue();
	var fil = zen('inFile').getValue();
	var cat = zen('categoryName').getValue();
	var out = zen('outFile').getValue();
	var msg = $$$Text('Errors:') + '\n';
	var ok = true;

	switch (val) {
		case 'Import':
		case 'Remove':
			if (!this.checkEdit()) {
				return false;
			}
			break;
	}

	if (val.match('Import')) {
		zenPage.Status = zenPage.GetImportStatus(); // in case another page has been busy in the meantime
		if (zenPage.Status == "running") {
			alert($$$Text("Another import operation is currently running in the background. Please wait for it to finish."));
			self.document.location.reload(); // refresh to show statistics on import operation
		}
		else {
			if (fil.length == 0) {
				msg += '  ' + $$$Text("Please enter a filename.") + '\n';
				ok = false;
			}
			if (ok) { // Run SEF imports in the background because they take so long

				// disable the OK button while import is going on
				zen("OK").setProperty("disabled",true);

				if (zenPage.enableAutoRefresh) {
					// set up a timer so we periodically check import job status until done
					var timer = zen("timer");	
					timer.setProperty("timeout",1000);
					timer.startTimer();
				}

				// run the background task 
				var key = this.DoImportInBackground(fil,zenPage.Family); 
				if (key != 1) {
					// the return value is an error message from %RunBackgroundMethod
					msg += '  ' + key;
					ok = false;
				}
				
				if (!zenPage.enableAutoRefresh) {
					zenPage.doStatus();
				}
			}
		}
	} else if (val.match('Remove')) {
		if (cat.length == 0) {
			msg += '  ' + $$$Text("Please choose a schema category.") + '\n';
			ok = false;
		}
		if (ok) {
			if (zenPage.DoRemove(cat)) {
				alert($$$Text("Successfully removed schema."));
			}
			else {
				msg += '  ' + $$$TextJS("Unable to remove schema.") + '\n';
				ok = false;
			}
		}
	} else {
		// this should never happen
	}

	if (ok) self.document.location.reload();
	else alert(msg);
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "ImportExportDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "ImportExportDir") = ##class(%File).GetDirectory(pPathname, 1)
}

/// Run method DoImport() in a background job. Return 1 if this works out ok, 
/// an error string if there is an error in running the job 
/// (regardless of the results of the method DoImport() itself).
ClassMethod DoImportInBackground(pFilename As %String, pFamily As %String) As %ZEN.Datatype.string [ ZenMethod ]
{
	Set tSC = ..%RunBackgroundMethod("DoImport",pFilename,pFamily)
	If $$$ISERR(tSC) {
		Quit $$$StatusDisplayString(tSC)
	} Else {
		Quit tSC
	}
}

/// Designed to run in a background job using the method DoImportInBackground which invokes %RunBackgroundMethod().
/// Based on a similar method in EnsPortal.ArchiveManager.
ClassMethod DoImport(pFilename As %String, pFamily As %String) As %String
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do ..%SetBackgroundMethodStatus("Job Started. Please wait...")	

	If '##class(%File).Exists(pFilename) {
		Set tSC=$$$ERROR($$$EnsErrGeneral,"Unable to open file '"_pFilename_"'")
	}
	If $$$ISOK(tSC) {
		// Lock and set globals
		lock +^IRIS.Temp.SEFImport($USERNAME,"lock"):1
		else  quit $$$ERROR($$$GeneralError,"Cannot acquire lock to start importing SEF file")
		Do ..SetCompletionValue(0) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
		kill ^IRIS.Temp.SEFImport($USERNAME,"run")
		set ^IRIS.Temp.SEFImport($USERNAME,"run","file")=pFilename
		set ^IRIS.Temp.SEFImport($USERNAME,"run","start")=$H

		Set tSC = ##class(EnsLib.EDI.SEF.Compiler).Import(pFilename,pFamily,.tCatImported,.tValidationErrors)

		// Set and unlock globals
		set ^IRIS.Temp.SEFImport($USERNAME,"run","stop")=$H
		set ^IRIS.Temp.SEFImport($USERNAME,"run","error")=$$$StatusDisplayString(tSC)
		Do ..SetCompletionValue(2) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
		lock -^IRIS.Temp.SEFImport($USERNAME,"lock")
	}
	If $$$ISOK(tSC) {
		Do ..%EndBackgroundMethod()
	}
	Else {
		// server method errored out
		Set pMsg = $$$StatusDisplayString(tSC)
		Do ..%SetBackgroundMethodStatus(pMsg)
		
		// This is to set unexpected errors like unable to lock, etc. so UI can pickup to display
		Set ^IRIS.Temp.SEFImport($USERNAME,"run","error") = pMsg
	}
Done
	Quit
Trap
	Set $ZT = ""
	Do ..%SetBackgroundMethodStatus($ZE)
	GoTo Done
}

Method DoRemove(pCategory As %String) As %Boolean [ ZenMethod ]
{
	Set tKilled=$D($$$vaSchemaGbl(pCategory))
	Kill $$$vaSchemaGbl(pCategory),$$$vaSchemaDescGbl(pCategory)
	Quit tKilled
}

/// Draw main HTML content for this page.
ClassMethod DrawContent(pSeed As %String) As %Status
{
	&html<
		<table class="tpTable" border="0" cellpadding="4" cellspacing="2">
		<tbody>
		>

	Set CatText = $$$TextHTML("Category")
	Set NameText = $$$TextHTML("Name")
	Set BaseText = $$$TextHTML("Base")
	Set DescText = $$$TextHTML("Description")
	Set DocText = $$$TextHTML("Document Structures / Document Types")

	Set cat=""
	For {
		Set cat=$o($$$vaSchemaGbl(cat))  Quit:cat=""
		If $P($G($$$vaSchemaGbl(cat)),"|",5) = %page.Family { // Only show schemas from the current family
			Set sorted("="_cat)=""
		}
	}
	If '$D(sorted) {
		&html<</table>>
		Quit $$$OK
	}
	
	&html<<tr><th>#(CatText)#</th><th>#(NameText)#</th><th>#(BaseText)#</th><th colspan="5">#(DescText)#</th></tr>>
	
	Set sortcat=""
	Set even = 1
	For { 
		Set sortcat=$o(sorted(sortcat)) Quit:sortcat=""
		Set cat=$e(sortcat,2,99999)
		Set catdesc=##class(EnsLib.EDI.SEF.Schema).GetDescription("IG:"_cat)
		Set base=$G($$$vaSchemaGbl(cat,"base")) Set:""=base base="&nbsp;"
		If (even) { // the sense of these is somewhat reversed
			Set rowClass="tpOdd"
			Set even=0 //for next time
		} Else {
			Set rowClass="tpEven"
			Set even=1
		}
		&html<<tr class="#(rowClass)#" valign="top">>
		Set rowdesc=0,item=""
		For rows=0:1 {
			Set item=$O($$$vaSchemaGbl(cat,item))
			If (item=":SEF"||(item="std")) {Set rows=rows-1  Continue }
			Set:'rowdesc rowdesc=$Case(##class(EnsLib.EDI.SEF.Schema).GetDescription("DS:"_cat_":"_item),"":0,catdesc:0,:1)
			Quit:item=""
		} ; get rows count
		Set item=$o($$$vaSchemaGbl(cat,""))
		Set:(item=":SEF"||(item="std")) item=$o($$$vaSchemaGbl(cat,item))
		Quit:(item="")
		Set itemdesc=##class(EnsLib.EDI.SEF.Schema).GetDescription("DS:"_cat_":"_item)
		Set desc=catdesc_$S(rowdesc||(""=catdesc):$S(""'=catdesc:"<br>",1:"")_" - "_itemdesc, 1:"")
		&html<
			<td#($S(rows:" rowspan="_rows,1:""))#>#(cat)#</td>
			<td><a title='DS:#(cat)#:#(item)#' href='EnsPortal.EDI.ValidationStructure.zen?DocType=#(cat)#:#(item)#'>#(item)#</a></td>
			<td#($S(rows:" rowspan="_rows,1:""))#>#(base)#</td>
			<td#($S('rowdesc:" rowspan="_rows,1:""))#>#(desc)#</td>
		>
		For {
			Set item=$O($$$vaSchemaGbl(cat,item))
			Quit:item=""
			Continue:(item=":SEF"||(item="std"))
			Set itemdesc=" - "_##class(EnsLib.EDI.SEF.Schema).GetDescription("DS:"_cat_":"_item)
			&html<
				</tr><tr class="#(rowClass)#">
				<td><a title='DS:#(cat)#:#(item)#' href='EnsPortal.EDI.ValidationStructure.zen?DocType=#(cat)#:#(item)#'>#(item)#</a></td>
			>
			If rowdesc {
				&html<<td>#(itemdesc)#</td>>
			}

		}
		&html<</tr>>
	}
	&html<</table>>

	Quit $$$OK
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set tPageName = $$$FormatText($$$Text("%1 Schemas","Ensemble"),..Family)
	Set pLink(2)=$LB(tPageName,"#")
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$FormatText($$$Text("View %1 Schemas","Ensemble"),..Family)
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Quit $$$OK
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If ..Family '= "" {
		Set ..HelpAddress = $$$PRODUCT2 _", "_..Family_" Schemas"
	}
	// Create a sorted list of document type categories
	If (..Family["EDIFACT") {
		Set tRS = ##class(%ResultSet).%New("EnsLib.EDI.EDIFACT.Document:EnumerateTypeCategories")
	}
	Else { // Family["X12")
		Set tRS = ##class(%ResultSet).%New("EnsLib.EDI.X12.Document:EnumerateTypeCategories")
	}
	Do tRS.Execute()
	While (tRS.Next()) {
		Set catsorted($I(catsorted)) = $G(tRS.Data("Category"))
	}
	Do tRS.Close()
	Set tRS = $$$NULLOREF

	// Put the catsorted "sorted list" into the categoryName combobox
	Set tCombo = ..%GetComponentById("categoryName")
	Set icat="" 
	For { Set icat=$O(catsorted(icat))  Quit:icat=""  Set cat=catsorted(icat)
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = catsorted(icat)
		Set tOption.value = cat
	}
	Quit tSC
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
					"DoImportInBackground": ..#EDITRESOURCE,
					"DoRemove": ..#EDITRESOURCE,
					: "")
}

}
