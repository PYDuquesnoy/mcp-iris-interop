/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsConstants, EnsUI)

/// StartProduction
Class EnsPortal.ProductionDocument Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs USE permissions on the %Ens_ProductionDocumentation resource to view this page.
Parameter RESOURCE = "%Ens_ProductionDocumentation:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Production Document";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

/// Name of production that is displayed.
Property ProductionName As %ZEN.Datatype.string(ZENURL = "PRODUCTION");

/// Current document format: "PDF" or "HTML"
Property DocumentFormat As %String;

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

Property lblLastHTMLReport As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Existing HTML documentation for this production was generated:")} ];

Property lblNoLastHTMLReport As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("No Existing HTML documentation for this production.")} ];

/// Time in seconds since the report was last generated.
/// Only set when a production is selected and does not change until
/// another production is selected or the page is refreshed.
Property secondsSinceLastReport As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Time in seconds since last report before which a popup is given seeking confirmation.
/// Compared with property secondsSinceLastReport
Property regenerationAgeWarn As %ZEN.Datatype.integer [ InitialExpression = 300 ];

XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of the page.
XData contentPane
{
<pane>
<spacer height="20" />
<hgroup>
<spacer width="20" />
<vgroup>
<vgroup enclosingClass="wizardBox" >
<form id="form" align="center">
<hgroup labelPosition="left">
<spacer height="20" />
<dataCombo id="TargetName" name="TargetName" labelClass="labelRequired" 
	size="40" label="Production Name" title="Use the production shown, or choose a production name from the list."
	displayColumns="1" valueColumn="1" choiceColumn="1" 
	queryClass="Ens.Config.Production" queryName="ProductionStatus" maxRows="1000"
	onchange="zenPage.changedProduction(zenThis.getValue())"
	/>
<spacer width="20" />
<checkbox required="false" readOnly="false" hidden="false" value="false"
									name="AllSettings" id="AllSettings" label="Include Default Settings"
									enclosingStyle="padding-bottom:4px;"
									title="Check the box if you want to include all settings in use by the production and its items. If not checked only those defined within the production class definition are shown. The check box reflects the choice when the last HTML report, if any, was generated for this production."
								/>
</hgroup>
<spacer height="20" />

<hgroup align="center">
<button name="btnView" id="btnView" caption="View HTML" onclick="zenPage.btnView();"  
	  controlClass="commandButton" 
		title="Display the existing documentation for this production." />
<spacer width="10" />
<button name="btnCreateHTML" id="btnCreateHTML" caption="Generate HTML" onclick="zenPage.btnCreate('HTML');"  
	  controlClass="commandButton" 
		title="Create new HTML documentation for this production based on the 'Include Default Settings' flag. This report will be stored in the database and served as a web page. If an HTML report already exists and is the same as the generated report the existing persisted report will be shown." />
<spacer width="10" />
<button name="btnCreatePDF" id="btnCreatePDF" caption="Generate PDF" onclick="zenPage.btnCreate('PDF');"  
	  controlClass="commandButton" 
		title="Create new PDF documentation for this production. This report is stored on the server's file system." />
<spacer width="10" />
<button name="Cancel" id="Cancel" caption="Cancel" onclick="if (zenPage.isPopup) {zenPage.cancelPopup();} else {window.close();}"
	  controlClass="commandButton" 
		title="Close this window." />
</hgroup>
<spacer height="20" />
<label id="lastHTMLReportDate" enclosingClass="labelComment"/>
<spacer height="20" />
<hgroup id="docFileFields" cellVAlign="bottom" hidden="true" >
<text id="docFile" name="docFile" label="PDF Documentation File" size="55" 
       title="Enter the full path and name for the destination PDF file."/>
<button caption="Browse..." controlClass="commandButton" containerStyle="padding-left:2px;" 
		onclick="zenPage.browseSelect();" title="Choose the destination PDF file." />
<button caption="OK" controlClass="commandButton" containerStyle="padding-left:2px;" 
		onclick="zenPage.doCreatePDF(zen('docFile').getValue());"
		 title="Start PDF generation; output will be written to the specified file."/>
</hgroup>
<spacer height="10" />
<html align="center" id="error" hidden="true" />
</form>
</vgroup>
<!-- for displaying status updates during a background documentation job -->
<html id="idStatus" OnDrawContent="DrawStatus"/>
<!-- for displaying final results and log file contents if any -->
<html id="idResults" OnDrawContent="DrawResults"/>
<!-- for periodically updating the status display during a background documentation job -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</vgroup>
<spacer width="20" />
<vgroup valign="top">
<spacer height="40" />
<label id="helpSubject" enclosingClass="labelComment" label="Use this form to generate a report document that describes the production configuration." />
<spacer height="10" />
<label id="helpHover" enclosingClass="labelComment" label="For help with any item in this form, hover the cursor over the item." />
<vgroup id="docFileNote" hidden="true">
<spacer height="10" />
<label label="Use of the PDF option requires proper configuration of Java and a PDF Renderer software." labelStyle="font-weight:bold;"/>
</vgroup>
</vgroup>
</hgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
/// Start the timer so we can check the status. If there is a
/// background documentation job currently running,
/// you will see a periodic update until the job is finished.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	
	this.doStatus();
	if ((zenPage.Status == "running") && this.enableAutoRefresh) {
		var timer = zenPage.getComponentById('timer');	
		timer.setProperty('timeout',1000);
		timer.startTimer();
	}
}

/// This function controls the timer on updating progress.
/// It is called from onload as well (in case a background documentation job is currently being run when the page is opened).
ClientMethod timeout(timer) [ Language = javascript ]
{
	// get and use the status of the background documentation job
	this.doStatus();
	
	// get the timer and status fields
	var timer = zen("timer");
	
	// if status = idle then stop timer; otherwise continue
	if ((zenPage.Status == "running") && this.enableAutoRefresh) {
		timer.startTimer();	
	}
	else {  
		timer.clearTimer();				
	}
}

/// This method calls server method to get current background documentation job status and update the UI.
ClientMethod doStatus() [ Language = javascript ]
{
	// invoke DrawStatus() which will get and display all the status information
	zen("idStatus").refreshContents(); 

	// get the status string
	zenPage.Status = zenPage.GetDocumentationStatus();

	// if done, output a message; if the format is HTML, also refresh the page so it reflects the new document
	if (zenPage.Status == "done") { 
		var info = new Array();
		info = zenPage.GetJobStatus();
		var err = info[0];
		var ret = info[1];
		var log = info[2];
		if (ret == '.' || log.length>1) ret = '';
		if (log == '.') log = '';
		zenSetProp('idResults','content',ret + log);
		if ((err == '.') || (err == 'OK') || (err == '')) {
			if (zenPage.DocumentFormat == 'HTML') {
				zenPage.clearBackgroundTask();
				setTimeout(function() {
					self.document.location = zenLink(zenPage.DecideProductionJS(zenPage.ProductionName));
				}, 100);
			}
			else if (zenPage.DocumentFormat == 'PDF') {
				alert($$$Text("Background documentation job completed successfully."));
			}
		}
		else {
			alert($$$Text("An error occurred in the background documentation process:\n") + err);
		}
	}
		
	return;
}

/// Draw current documentation status; intended for use with background documentation jobs.
Method DrawStatus(seed As %ZEN.Datatype.string) As %Status
{
	// If there is no start time, or if we are marked complete, we are not underway
	Set RunningStartTime = ..GetRunningStartTime()
	If ((""=RunningStartTime) || (..GetCompletionValue() > 0)) { // done (2) or idle (1) or running (0)
		Quit $$$OK 
	} 
	
	// Get the values needed for the status table
	Set tTitle = $$$TextHTML("Documentation in progress")
	Set tDuration = $$$TextHTML("Duration")
	Set RunningFileName = ..GetRunningProductionName()
	Set RunningDuration = ..GetRunningDuration()	
	
	If ..enableAutoRefresh {
		// Draw the status table
		&html<
			<table>
				<tr><td>#(tTitle)#</td></tr>
			</table>
			<table border="0" cellspacing="5" cellpadding="0">
				<tr><td>#(RunningFileName)#</td></tr>
				<tr><td nowrap>#(tDuration)#: #($ZCVT(RunningDuration,"O","HTML"))#</td></tr>
			</table>
		>
	} Else {
		// Draw refresh
		Set tRefresh = $$$TextHTML("Refresh documentation status")
		Set tTitle = $$$TextHTML("Documentation in progress.  Click to refresh status")
		&html<
			<table>
				<tr><td><div nowrap>
					<span style="font-size:10pt;color:#606060;font-weight:bold;">#(tTitle)#:</span>
				</div></td>
				<td nowrap style="padding-left:5px;">
					<image src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.doStatus();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
				</td></tr>
				<tr><td>#(RunningFileName)#</td></tr>
			</table>
		>
	}
	
	Quit $$$OK
}

/// Draw results and log file if any.
Method DrawResults(seed As %ZEN.Datatype.string = "") As %Status
{
	Write seed
	Quit $$$OK
}

/// Use when the documentation job is running in the background to check on running status.
/// Returns either "running" or "idle" or "done".
ClassMethod GetDocumentationStatus() As %String [ ZenMethod ]
{
	Quit ..GetRunningStatus()
}

/// Use when the documentation job is running in the background to check on running status.
/// Returns either "running" or "idle" or "done".
ClassMethod GetRunningStatus() As %String
{
	If (..GetCompletionValue()=2) {		// we're done
		Do ..SetCompletionValue(1) 	  	// change to idle
		Quit "done" 
	}
	lock +^IRIS.Temp.ProductionDocument($USERNAME,"lock"):0 set locktest=$T lock -^IRIS.Temp.ProductionDocument($USERNAME,"lock")
	If locktest=0 {
		Do ..SetCompletionValue(0) 	  	// it's running
		Quit "running"
	}
	Else {								// nothing is going on
		Do ..SetCompletionValue(1) 	  	// change to idle
		Quit "idle" 
	}
}

/// Use when the documentation job is running in the background to check on error status.
/// Returns error message and log file name/contents if available.
ClassMethod GetJobStatus() As %ListOfDataTypes [ ZenMethod ]
{
	Set ret = ##class(%ListOfDataTypes).%New()
	Set error = $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","error"))
	Set return = $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","return"))
	Set logfile = $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","logfile"))
	Do ret.Insert($S(error="":".",1:error))
	Do ret.Insert($S(return="":".",1:return))
	Do ret.Insert($S(logfile="":".",1:logfile))
	Quit ret
}

/// Use when the documentation job is running in the background to check on status.
ClassMethod GetRunningStartTime() As %String
{
	quit $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","start"))
}

/// Use when the documentation job is running in the background to check on status.
ClassMethod GetRunningProductionName() As %String
{
	quit $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","name"))
}

/// Use when the documentation job is running in the background to check on status.
/// Gets the number of seconds job has been running (or ran, if complete)
/// and formats it nicely as a string.
ClassMethod GetRunningDuration() As %String
{
	// Get the duration in seconds
	Set stopH = $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","stop"))
	If ""=stopH { // we haven't stopped yet, use current time
		Set stopH = $H
	}
	Set startH = $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","start"))
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
	quit $G(^IRIS.Temp.ProductionDocument($USERNAME,"run","completed"))
}

ClassMethod SetCompletionValue(pValue As %Integer) As %Boolean
{
	Set ^IRIS.Temp.ProductionDocument($USERNAME,"run","completed") = pValue
}

/// Decide what to do about documenting the specifed production in HTML format.
ClientMethod btnView() [ Language = javascript ]
{
	var msg = zen('error');
	msg.setHidden(1);
	var name = zen('TargetName').getValue();
	zenPage.ProductionName = name;
	zenPage.DocumentFormat = 'HTML';
	
	if ((name) && (name != '')) { // user selected a production name
		var err = zenPage.DecideProductionJS(name);
		if (err == '') { // there is no old document
			if (confirm(zenText('msgProdDocNone')) == true) {
				zenPage.btnCreate('HTML'); // go ahead and generate one
			}
		}
		else { // there is an old document
			self.document.location = zenLink(err); // show the old one
		}
	}
	else { // user did not select a production name yet
		alert(zenText('msgProdDocSelect'));
		return false;
	}
	return true;
}

/// Generate new document for the specifed production.
ClientMethod btnCreate(format) [ Language = javascript ]
{
	var msg = zen('error');
	msg.setHidden(1);
	var name = zen('TargetName').getValue();
	zenPage.ProductionName = name;
	zenPage.DocumentFormat = format;
	
	if ((name) && (name != '')) { // user selected a production name
		if (format.match("HTML") == "HTML") {
			zen('docFileFields').setHidden(1);
			zen('docFileNote').setHidden(1);
			if (this.secondsSinceLastReport > 0) {
				// User will need to refresh page after this warning or change production in order to reset the secondsSinceLastReport
				if (this.secondsSinceLastReport < this.regenerationAgeWarn) {
					var ageWarnInMinutes = (this.regenerationAgeWarn / 60);
					var ok = confirm($$$FormatText($$$Text("Are you sure you want to re-generate an HTML report for %1 since within %2 minutes of last generation ?"),name,ageWarnInMinutes));
					if (!ok) return;
				}
			}

			if (this.enableAutoRefresh) {
				// set up a timer so we periodically check documentation job status until done
				var timer = zen("timer");	
				timer.setProperty("timeout",1000);
				timer.startTimer();
			}
			var allSettings  = (zen('AllSettings').value);
			allSettings = (allSettings === true) ? 1 : 0;
			var key = zenPage.RunDocumentInBackground(name, format, "", "", allSettings); // generate and show the document 
			if (key != 1) {
				// the return value is an error message from %RunBackgroundMethod
				msg.setContent(key);
				msg.setHidden(0); 
			}
			else { // no error, no message
				msg.setHidden(1); 
			}
			if (!this.enableAutoRefresh) {
				zenPage.doStatus();
			}
		}
		else if (format.match("PDF") == "PDF") {
			zen('docFileFields').setHidden(0);
			zen('docFileNote').setHidden(0);
			return true;
		}
		else {
			alert($$$FormatText($$$Text("Format %1 is not supported for production documentation."), format));
			return false;
		}
	}
	else { // user did not select a production name yet
		alert(zenText('msgProdDocSelect'));
		return false;
	}
	return true;
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
  Set pResources("msgProdDocSelect") = $$$Text("Please choose a production.")
  Set pResources("msgProdDocWait") = $$$Text("Generating document, please wait...")
  Set pResources("msgProdDocNone") = $$$Text("Documentation does not exist, do you wish to generate it?")
  Quit $$$OK
}

/// If HTML documentation exists for the Production, return the URL for display; otherwise return null.
Method DecideProductionJS(pProdId As %String) As %String [ ZenMethod ]
{
	// Check if documentation already exists
	#dim tURL = ""
	Do ##class(Ens.Util.Documentation).GetDocHTML(pProdId, .tURL)
	If (tURL'="") && (tURL'["%25CSP.StreamServer.cls") {
		Set tURL = ##class(%CSP.Page).Link("%25CSP.StreamServer.cls?STREAMOID="_##class(%CSP.Page).Encrypt(tURL))
	}
	Quit tURL
}

/// Run method DocumentProductionJS() in a background job. Return 1 if this works out ok, 
/// an error string if there is an error in running the job 
/// (regardless of the results of the method DocumentProductionJS() itself).
/// The input pFormat is the string "HTML" or "PDF" indicating the output format.
ClassMethod RunDocumentInBackground(pProdId As %String, pFormat As %String, pPDFFileName As %String = "", pPDFRenderer As %String = "", pAllSettings As %Boolean = 0) As %ZEN.Datatype.string [ ZenMethod ]
{
	If (pFormat = "HTML") {
		Set tSC = ..%RunBackgroundMethod("DocumentProductionJS", pProdId, pFormat, "" , "", pAllSettings)
	}
	ElseIf (pFormat = "PDF") {
		Set tSC = ..%RunBackgroundMethod("DocumentProductionJS", pProdId, pFormat, pPDFFileName, pPDFRenderer, pAllSettings)
	}
	If $$$ISERR(tSC) { 
		Quit $$$StatusDisplayString(tSC) 
	}
	Else {
		Quit tSC
	}
}

/// This method generates a document for the specified production and returns a status that JavaScript can understand.
ClassMethod DocumentProductionJS(pProdId As %String, pFormat As %String, pPDFFileName As %String = "", pPDFRenderer As %String = "", pAllSettings As %Boolean = 0) As %String
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do ..%SetBackgroundMethodStatus("Job Started. Please wait...")	

	// Lock and set globals
	lock +^IRIS.Temp.ProductionDocument($USERNAME,"lock"):1
	else  quit $$$ERROR($$$GeneralError,"Cannot acquire lock to start building documentation")
	Do ..SetCompletionValue(0) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
	kill ^IRIS.Temp.ProductionDocument($USERNAME,"run")
	set ^IRIS.Temp.ProductionDocument($USERNAME,"run","name")=pProdId
	set ^IRIS.Temp.ProductionDocument($USERNAME,"run","start")=$H

	If (pFormat = "HTML") {
		Set tSC = ##class(%SYS.Ensemble).CreateDocumentation(pProdId, 0, "HTML", .LogFileName, .tURL, , , , , pAllSettings)
	}
	ElseIf (pFormat = "PDF") {
		Set tSC = ##class(%SYS.Ensemble).CreateDocumentation(pProdId, 1, "PDF", .LogFileName, , , pPDFFileName, pPDFRenderer, .Params, pAllSettings)
	}
	Else {
		Set msg = "<div class=""ErrorBox"">" _ $$$FormatText($$$Text("Sorry, you have requested an unsupported format, %1."), pFormat) _ "</div>"
		Quit msg
	}
	
	// Set and unlock globals
	set ^IRIS.Temp.ProductionDocument($USERNAME,"run","stop")=$H
	set ^IRIS.Temp.ProductionDocument($USERNAME,"run","error")=$$$StatusDisplayString(tSC)
	Do ..SetCompletionValue(2) // done (2) or idle (1) or running (0) - used to determine when to refresh the page 
	lock -^IRIS.Temp.ProductionDocument($USERNAME,"lock")

	If $$$ISOK(tSC), $G(tURL)'="" {
		Do ..%EndBackgroundMethod()
		Quit ""
	}
	Else {
		// server method errored out
		Set pMsg = $system.Status.GetErrorText(tSC) // GetOneStatusText(tSC,1)
		Do ..%SetBackgroundMethodStatus(pMsg)
		
		// Save error message and log file if there is one, so that UI canpick up
		If $$$ISOK(tSC) {
			Set ^IRIS.Temp.ProductionDocument($USERNAME,"run","error") = ""
			Set ret = ""
		}
		Else {
			Set ^IRIS.Temp.ProductionDocument($USERNAME,"run","error") = pMsg
			Set ret = "<div class=""ErrorBox"">"_$ZCVT(($$$Text("ERROR:")_" "_$system.Status.GetErrorText(tSC)),"O","HTML")_"</div>"
		}
		If $G(LogFileName)="" {
			Set ^IRIS.Temp.ProductionDocument($USERNAME,"run","logfile") = "."
		}
		Else {
			Set msg = "<div align='left'><pre>"
		    Set msg = msg _ $ZCVT($$$FormatText($$$Text("Contents of log file '%1':"),LogFileName),"O","HTML") _ "<br/><br/>"
			Set LogFile = ##class(%File).%New(LogFileName)
			If LogFile.Open("RS") {
				Do {
					Set msg = msg _ $ZCVT(LogFile.Read(),"O","HTML")_ "<br/>"
				} While '(LogFile.AtEnd)
				Do LogFile.Close()
			}
			Set msg = msg_"</pre></div>"
			Set ^IRIS.Temp.ProductionDocument($USERNAME,"run","logfile") = msg
		}

		Quit ret
	}
Done
	Quit ""
Trap
	Set $ZT = ""
	Set ^IRIS.Temp.ProductionDocument($USERNAME,"run","error") = $ZE
	Do ..SetCompletionValue(2)
	Do ..%SetBackgroundMethodStatus($ZE)
	Do ..%EndBackgroundMethod()
	Quit "<div class=""ErrorBox"">"_$ZCVT(($$$Text("ERROR:")_" "_$ZE),"O","HTML")_"</div>"
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production Documentation","Ensemble")
}

/// Get information to display in the ribbon bar.
/// Make appropriate choices for Production Documentation. 
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Quit $$$OK
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	Set ..%GetComponentById("TargetName").value = ..ProductionName
	If ..ProductionName '="" {
		#dim tAgeInSeconds = -1
		#dim tLastHTMLReportDate = ##class(Ens.Util.Documentation).LastHTMLCreationDate(..ProductionName,"HTML",.tAgeInSeconds)
		Set ..%GetComponentById("AllSettings").value = 0
		If tLastHTMLReportDate'="" {
			Set ..secondsSinceLastReport = tAgeInSeconds
			Set ..%GetComponentById("lastHTMLReportDate").value = ..lblLastHTMLReport_" "_tLastHTMLReportDate
			If ##class(Ens.Util.Documentation).LastHTMLIncludedDefaultSettings(..ProductionName) {
				Set ..%GetComponentById("AllSettings").value = 1
			}
		} Else {
			Set ..%GetComponentById("lastHTMLReportDate").value = ..lblNoLastHTMLReport
		}
	}
	Quit tSC
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "ProductionDocumentationDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "ProductionDocumentationDir") = ##class(%File).GetDirectory(pPathname, 1)
}

/// User clicked the Browse button.
ClientMethod browseSelect() [ Language = javascript ]
{
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	var dir = zen('docFile').getValue();
	if (dir.length <= 0) dir = zenPage.GetDefaultDir();
	var parms = {
		Dir: dir,
		wildcard: '*.pdf'
		};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.fileSelect.zen'),this.addPopupSuffix('DocFileSelect'),'resizable,width=600,height=700',parms);
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
		case 'DocFileSelect':
			zenPage.getComponentById('docFile').setValue(value); // display the value even if it's bad
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

/// The argument filename is the full pathname of the output PDF file.
ClientMethod doCreatePDF(filename) [ Language = javascript ]
{
	// get and check the destination file name
	filename = filename.replace(/^\s+|\s+$/g, "");	
	filename = filename.replace(/^\t+|\t+$/g, "");
	if (filename.length <= 0) {
		alert($$$Text("No path or filename was supplied."));
		return;
	}
	var fileProblem = zenPage.FileProblem(filename);
	switch (fileProblem) {
		case "0": // OK
			break;
		case "1":
			var ok = confirm($$$FormatText($$$Text("Are you sure you want to overwrite the existing file %1?"),filename));
			if (!ok) return;
			break;
		case "2":
			alert($$$FormatText($$$Text("The directory specified for file %1 does not exist."),filename));
			return;
		case "3":
			alert($$$Text("A directory was specified with no filename."));
			return;
		case "4":
			alert($$$FormatText($$$Text("The filename %1 is not appropriate for PDF output."),filename));
			return;
		case "5":
			alert($$$Text("No path or filename was supplied."));
			return;
		default: // OK
			break;
	}
	zenPage.SetDefaultDir(filename);
	
	// get the production name
	var name = zen('TargetName').getValue();
	
	if (this.enableAutoRefresh) {
		// set up a timer so we periodically check documentation job status until done
		var timer = zen("timer");	
		timer.setProperty("timeout",1000);
		timer.startTimer();
	}
	
	// run the job
	var msg = zen('error');
	var allSettings  = zen('AllSettings').value;
	allSettings = (allSettings === true) ? 1 : 0;
	var key = zenPage.RunDocumentInBackground(name, "PDF", filename, "", allSettings); // generate the document 
	if (key != 1) {
		// the return value is an error message from %RunBackgroundMethod
		msg.setContent(key);
		msg.setHidden(0); 
	}
	else { // no error, no message
		msg.setHidden(1); 
	}
	if (!this.enableAutoRefresh) {
		zenPage.doStatus();
	}
}

/// Check for problems in the output file for PDF, and report back.
/// "0" means ok, "1" means the file exists, "2" means the directory does not exist,
/// "3" means the filename is not supplied, "4" means the filename is not correct for PDF output,
/// "5" means a blank value was supplied.
Method FileProblem(pFilename As %String) As %String [ ZenMethod ]
{
	Set tMsg = "0"
	Try {
		Set tFilename = $ZSTRIP(pFilename, "<>W")
		If ($L(tFilename) = 0) {
			Set tMsg = "5"
		}
		Else {
			Set tFile = ##class(%File).GetFilename(tFilename)
			Set tLen = $L(tFile)
			If (tLen = 0) {
				Set tMsg = "3"
			}
			Else {
				Set tDir = ##class(%File).GetDirectory(tFilename)
				If '##class(%File).DirectoryExists(tDir) {
					Set tMsg = "2"
				}
				Else {
					If (tLen < 5) {
						Set tMsg = "4"
					}
					Else {
						Set tExt = $E(tFile, tLen - 3, tLen)
						If ($ZCVT(tExt, "U") '= ".PDF") {
							Set tMsg = "4"
						}
						Else {
							If ##class(%File).Exists(tFilename) {
								Set tMsg = "1"
							}	
						}
					}
				}
			}
		}
	}
	Catch (ex) {
		Set tMsg = "4"
	}
	Quit tMsg
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"RunDocumentInBackground": "%Ens_ProductionDocumentation:USE",
				: "")
}

ClientMethod changedProduction(production) [ Language = javascript ]
{
	var dateHTMLLabel = zen('lastHTMLReportDate');
	if (dateHTMLLabel) {
		var lastDateInfo = this.GetLastHTMLCreationDate(production);
		zen('AllSettings').setValue(false);
		if (lastDateInfo) {
			var infoArray = lastDateInfo.split('\0');
			if (infoArray[0]!=="") {
				dateHTMLLabel.setValue(this.lblLastHTMLReport+' '+infoArray[0]);
				if (infoArray[1] == '1') zen('AllSettings').setValue(true);
				try { 
					this.secondsSinceLastReport = parseInt(infoArray[2]);
					this._secondsSinceRecordedAt = new Date()
				} catch (ex) {
					this.secondsSinceLastReport = -1;
				}
			} else {
				dateHTMLLabel.setValue(this.lblNoLastHTMLReport);
				this.secondsSinceLastReport = -1;
			}
		}
		
	}
}

ClassMethod GetLastHTMLCreationDate(pProduction As %String = "") As %String [ Internal, ZenMethod ]
{
	#dim tAgeInSeconds
	#dim tLastHTMLReportDate = ##class(Ens.Util.Documentation).LastHTMLCreationDate(pProduction,"HTML",.tAgeInSeconds)
	#dim tLastIncludedDefaultSettings = 0
	If (tLastHTMLReportDate'="") Set tLastIncludedDefaultSettings=##class(Ens.Util.Documentation).LastHTMLIncludedDefaultSettings(pProduction)
	Return (tLastHTMLReportDate_$C(0)_tLastIncludedDefaultSettings_$c(0)_tAgeInSeconds)
}

}
