/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Deployment Apply Page
/// 
/// This pages lets users import a deployment package 
/// and apply changes to a production.
Class EnsPortal.Deployment.DeployProductionChanges Extends EnsPortal.Template.standardPage
{

Parameter JSINCLUDES = "zenCSLM.js";

Parameter CSSINCLUDES;

/// Displayed name of this page.
Parameter PAGENAME = "Deploy Production Changes";

/// User needs use permissions on %Ens_Deploy to use this page.
Parameter RESOURCE = "%Ens_Deploy";

/// Namespace.
Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

/// Name of Deployment package being viewed.
Property deploymentName As %ZEN.Datatype.string(ZENURL = "DNAME");

/// Name of deployment export file (on server).
Property deploymentFile As %ZEN.Datatype.string(ZENURL = "DFILE");

/// Name of rollback file (on server).
Property rollbackFile As %ZEN.Datatype.string(ZENURL = "BCKFILE");

/// Name of log file (on server).
Property logFile As %ZEN.Datatype.string(ZENURL = "LOGFILE");

/// Name of target production for code changes
Property targetProduction As %ZEN.Datatype.string(ZENURL = "TARGETPROD");

/// Name of last target production for rollback
Property rollbackProduction As %ZEN.Datatype.string(ZENURL = "TARGETPROD");

/// Whether production class is in the deployment file
Property productionClassInExport As %ZEN.Datatype.boolean(ZENURL = "PRODINEXP");

/// Whether production class in the deployment file already exists in target
Property productionClassInExportName As %ZEN.Datatype.string(ZENURL = "PRODINEXPNAME");

/// ID (index number, 0-based) of current selected item.
Property currItem As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Whether deployment started by this page is still in progress. 
/// Used to store log line for display. If 'done' then deployment finished.
Property inProgress As %ZEN.Datatype.string [ InitialExpression = 0 ];

Property tempPortalNode As %ZEN.Datatype.string [ InitialExpression = "ToBeInitialised" ];

/// Used to show production update timeout - defaults to running production
Property updateTimeout As %ZEN.Datatype.integer(ZENURL = "UPDATETO") [ InitialExpression = {##class(Ens.Director).GetRunningProductionUpdateTimeout()} ];

Property rollbackforDeploymentFile As %ZEN.Datatype.string;

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

/// Is the user permitted to deploy from their local file system.
Property canDeployLocalFile As %Boolean [ InitialExpression = {$classmethod($classname(),"canDeployFromLocalFile")} ];

Property msgHelp As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Help")} ];

Property msgNoDeploymentFile As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please open a deployment file first.")} ];

Property msgNoRollbackFile As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a rollback file name.")} ];

Property msgNoTargetProduction As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a target production.")} ];

Property msgUnableToIdentifyTargetProduction As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Unable to identify a target production.")} ];

Property msgCannotChangeTargetProduction As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Unable to change target production since production class included in deployment file.")} ];

Property msgLocalFileNotAllowed As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Not allowed to deploy a file local via your browser.")} ];

Property msgOpenServer As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Click Open to select a deployment file from the Server's file system")} ];

Property msgOpenServerAndLocal As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Click Open to select a deployment file from the Server's file system or Open Local to select a deployment file from your file system")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

#packagePane {
	position: relative;
	padding-left:4px;
	border-bottom:1px solid black;
}
#packageTableHeader {
	height: 50px;
	top: 0px;
	background: #F0F0F0;
	overflow: hidden;
}
#mainForm {
	overflow-y: auto;
}

#packageTableBody {
	border-top: 1px solid rgb(156,154,141);
	border-bottom: 1px solid rgb(156,154,141); 
	overflow: auto;
	background: white;
}

table.packageTable {
	background: white;
	width: 100%;
}

table.packageTable td {
	padding: 2px;
	border-bottom: 1px solid darkgray;
}

table.packageTableLabel td {
	padding: 2px;
	border-bottom: 2px solid darkgray;
	font-size: 1.2em;
	font-weight: bold;
	
}

span.selector {
	visibility: hidden;
}

.fileRowSelected span.selector,
.itemRowSelected span.selector {
	visibility: visible;
}

.fileRow {
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
	background: #D0D0FF;
}
.fileRowSelected {
	color:black;
	font-size: 1.2em;
	font-weight: bold;
	background: #FFEEAA;
}

.itemRow {
	color: rgb(67,67,67);
}
.itemRowSelected {
	color:black;
	background: #FFEEAA;
}

#itemContents {
	background-color: white;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
	<hgroup id="mainGroup" cellVAlign="top">
		<vgroup id="packagePane">
			<html id="packageTableHeader" ></html>
			<html id="packageTableBody"></html>
			<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
		</vgroup>
		<vgroup id="propertyPane" hidden="true">
			<hgroup id="itemGroup">
				<label id="idItemTitle" label="Deployment Package" labelClass="labelText" labelStyle="white-space:nowrap;" containerStyle="background:#9c9a8c;color:white;font-size:14pt;padding-left:10px;"/>
				<html id="propertyTitle" width="400px">
					<div id="propertyCommands">
						<table width="100%">
							<tr>
								<td align="right">
									<a class="helpCommand" href="#" onclick="zenPage.showHelp(!zenPage.helpVisible);return false;">#(%page.msgHelp)#
										<span class="helpArrow">&#171;</span>
									</a>
								</td>
							</tr>
						</table>
					</div>
				</html>
			</hgroup>
			<form id="mainForm">
				<vgroup id="id1" hidden="false" cellStyle="padding:3px;" enclosingStyle="padding:10px;">
					<vgroup>
						<expando caption="Package Notes" id="packageNotesExp" expanded="false" title="Notes stored in the deployment file">
							<textarea id="packageNotes" rows="10" cols="40" readOnly="true"/>
						</expando>
						<spacer height="10" />
						<expando caption="Deployment Settings" id="deploymentSetttingsExp" expanded="false" title = "Target Production and files names for rollback and log files">
							<button id="btnSelectProduction" caption="Select Target Production" controlClass="commandButton" title="Set target Production if adding to existing production." onclick="zenPage.selectProduction();"/>
							<spacer height="10" />
							<text id="targetProductionTxt" size="35" readOnly="true" />
							<label id="createProductionLbl" enclosingStyle="background:rgb(200,0,0);" value="Production Will Be Created" hidden="true"/>
							<spacer height="10" />
							<button id="btnSelectRollback" caption="Change Rollback File" controlClass="commandButton" title="Change the file for rollback instructions" onclick="zenPage.selectRollbackFile();"/>
							<spacer height="10" />
							<text id="rollbackFileTxt" size="50" title="File to create for rollback instructions of items to be changed. Click button to change." readOnly="true"/>
							<spacer height="10" />
							<button id="btnSelectLogFile" caption="Change Deployment Log File" controlClass="commandButton" title="Change the file to write a log to" onclick="zenPage.selectLogFile();"/>
							<spacer height="10" />
							<text id="logFileTxt" size="50" title="File for the deployment log. Click button to change." readOnly="true"/>
							<spacer height="10" />
							<text id="updateTimeout" hidden ="true" label="Update Timeout:" size="10" title="Update timeout for current running production - informational." readOnly="true"/>
							<spacer height="10" />
						</expando>
					</vgroup>
				</vgroup>
				<vgroup id="id2" hidden="true" cellStyle="padding:3px;" enclosingStyle="padding:10px;">
					<expando caption="Item contents" title = "Contents of the deployment item including identifiable changes" id="itemContentsExp" expanded="true">
						<textarea id="itemContents" rows="6" cols="40" readOnly="true"/>
						<spacer height="10" />
						<html id="itemDescription"/>
					</expando>
				</vgroup>
			</form>
		</vgroup>
		<vgroup id="helpPane">
			<html>
				<div style="font-size:40pt;">Help</div>
			</html>
		</vgroup>
	</hgroup>
	<!-- Hidden fileUpload control for Open Local -->
	<form hidden = "true" enctype="multipart/form-data" action="EnsPortal.Deployment.DeployProductionChanges.zen" id="formSelectLocalFile">
		<fileUpload id="inputLocalFile" name="localFile" accept="text/xml" 
			onchange="zenPage.localFileSelectOnChange();"
		/>
	</form>
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	If (..deploymentName="") {
		Quit ..%OnGetPageName()
	}
	Quit ..deploymentName
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Deploy Production Changes")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Deploy Production Changes")

	// commands: $LB(id,caption,help,onclick,visibility:hidden)
	Set tDeployInProgress = ##class(Ens.Deployment.Deploy).IsDeploymentTokenInProgress(.tUsername, .tJob, .tSC) 
	Set tDeployTokenLocked = '##class(Ens.Deployment.Deploy).IsDeploymentTokenUnlocked()
	Set tLastInvocationId = ##class(Ens.Deployment.Deploy).GetLastDeploymentInvocationId(.tSC)	
	If ('tDeployInProgress && 'tDeployTokenLocked) {
		Set pCommands(1) = $LB("cmdOpen",$$$Text("Open Deployment"),$$$Text("Open a deployment file on the server"),"zenPage.openDeploymentFile(); return false;",0)
		#dim tLocalOpenOnClick = "alert(zenPage.msgLocalFileNotAllowed); return false;"
		If ..canDeployLocalFile {
			Set tLocalOpenOnClick = "zenPage.openLocalDeploymentFile(); return false;"
		}
		Set pCommands(2) = $LB("cmdOpenLocal",$$$Text("Open Local Deployment"),$$$Text("Open a deployment file on local system"),tLocalOpenOnClick,0)
		Set pCommands(3) = $LB("cmdDeploy",$$$Text("Deploy"),$$$Text("Deploy code"),"zenPage.startDeployCode(); return false;",0)
	}
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	// allow for manual refresh
	Set tRefresh = $$$TextHTML("Refresh deployment log")
	&html<
	<td nowrap style="padding-left:50px;">
	<image id="refreshLog" src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.GetLog();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
	</td>
	<td nowrap style="padding-left:5px;padding-right:50px;"></td>>
	Quit $$$OK
}

/// Launch the file dialog to select deployment file
ClientMethod openDeploymentFile() [ Language = javascript ]
{
	var doc = self.document;
	if (doc) {
		var btnOpen = doc.getElementById('command_cmdOpen');
		if (btnOpen) {
			if (btnOpen.className == 'commandButtonDisabled'){
				alert($$$Text("Disabled following deployment"));
				return;	
			}
		}
	}
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	var wild = "*.xml"
	var str = this.deploymentFile
	var len = str.length;
	if (len > 0) {
		if (str.charAt(len-4) == ".") {
			var wild = "*" + str.substring(len-4);
		}
	}
	var parms = {
		Dir:this.deploymentFile,
		wildcard:wild
		};	
	zenPage.launchPopupWindow('%ZEN.Dialog.fileSelect.cls',this.addPopupSuffix('DeploymentFile'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
}

/// Launch the file dialog to select rollback file
ClientMethod selectRollbackFile() [ Language = javascript ]
{
	if (this.deploymentFile == "") {
			alert(this.msgNoDeploymentFile);
			return false;
	}
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	var wild = "*.bck"
	var str = this.rollbackFile
	
	var len = str.length;
	if (len > 0) {
		if (str.charAt(len-4) == ".") {
			var wild = "*" + str.substring(len-4);
		}
	}
	var parms = {
		Dir:this.rollbackFile,
		wildcard:wild
		};	
	zenPage.launchPopupWindow('%ZEN.Dialog.fileSelect.cls',this.addPopupSuffix('RollbackFile'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
}

/// Launch the file dialog to select log file
ClientMethod selectLogFile() [ Language = javascript ]
{
	if (this.deploymentFile == "") {
			alert(this.msgNoDeploymentFile);
			return false;
		}
	
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	var wild = "*.log"
	var str = this.logFile
	
	var len = str.length;
	if (len > 0) {
		if (str.charAt(len-4) == ".") {
			var wild = "*" + str.substring(len-4);
		}
	}
	var parms = {
		Dir:this.logFile,
		wildcard:wild
		};	
	zenPage.launchPopupWindow('%ZEN.Dialog.fileSelect.cls',this.addPopupSuffix('LogFile'),'status,scrollbars,resizable=yes,width=600,height=700',parms);
}

/// Launch the open Production dialog.
ClientMethod selectProduction() [ Language = javascript ]
{
	if (this.productionClassInExport) {
		alert(this.msgCannotChangeTargetProduction);
	} else {
		zenPage.launchPopupWindow('_ZEN.Dialog.finderDialog.zen?SUPER=Ens.Production',this.addPopupSuffix('SelectProduction'),'status,scrollbars,resizable=yes,width=800,height=600');
	}
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
	case 'DeploymentFile':
		this.deploymentFile = value;
		var generatedFilenames =  zenPage.GenerateFilenames(value); 
		var filenames = generatedFilenames.split("<|>");
		this.rollbackFile = filenames[0]; 
		zen('rollbackFileTxt').setValue(this.rollbackFile);
		var str = filenames[1];
		var len = str.length;
		if (len > 0) {
			if (str.charAt(len-4) == ".") {
				str = str.substring(0,len-3)+'log';
			}
		}
		this.logFile = str; 
		zen('logFileTxt').setValue(this.logFile);
		this.loadPackage(value,this.targetProduction,this.rollbackFile,this.logFile);
		break;
	case 'RollbackFile':
		this.rollbackFile = value;
		zen('rollbackFileTxt').setValue(this.rollbackFile);
		break;
	case 'LogFile':
		this.logFile = value;
		zen('logFileTxt').setValue(this.logFile);
		break;
	case 'SelectProduction':
		/* remove trailing .cls */
		this.targetProduction = value.substring(0,value.length-4);
		zen('targetProductionTxt').setValue(this.targetProduction);		
		/* if we selected it then it exists */
		zen('createProductionLbl').setHidden(1); 
		if ((this.targetProduction!='') & (this.deploymentFile!='')) {
			this.loadPackage(this.deploymentFile,this.targetProduction,this.rollbackFile,this.logFile);
		}
		break;
	case 'switchNamespace':
		zenPage.changeURLNamespace(value);
		break;
	}
}

/// Draw the contents of the Header section.
Method DrawTableHeader(pSeed As %String) As %Status
{
	&html<<div style="position:relative;">>
	&html<<div style="position:absolute;top:16px;left:460px;font-weight:bold;color:#404040;"></div>>
	&html<</div>>
	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var propDiv = zen('propertyPane').getEnclosingDiv();
		var mainFormDiv = zen('mainForm').getEnclosingDiv();
		var titleGroupDiv = zen('itemGroup').getEnclosingDiv();
		var helpDiv = zen('helpPane').getEnclosingDiv();
		var packageDiv = zen('packagePane').getEnclosingDiv();
		var tableHdrDiv = zen('packageTableHeader').getEnclosingDiv();
		
		var tableBodyDiv = zen('packageTableBody').getEnclosingDiv();
		
		
		propDiv.style.display = 'block';
		helpDiv.style.display = (this.helpVisible || (this._percent && this._percent > 0)) ? 'block' : 'none';

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 25;
		var propHeight = propDiv.offsetHeight;
		var propChild = propDiv.children[0];
		if (propChild) {
			propHeight = (propChild.offsetHeight > propHeight ? propChild.offsetHeight : propHeight);
		}
		
		hgt = ((hgt < propHeight) ? propHeight : hgt );	
		var packageHgt = hgt - 1;
		var packageWid = winWidth - propDiv.offsetWidth - helpDiv.offsetWidth - 25;
		
		
		packageDiv.style.width = packageWid + 'px';
		// height is not calculated correctly on FF
		
		tableHdrDiv.style.width = packageWid + 'px';
		tableBodyDiv.style.width = packageWid + 'px';
		
		
		tableBodyDiv.style.height = packageHgt - tableHdrDiv.offsetHeight + 'px';
		propDiv.style.height = hgt + 'px';
		helpDiv.style.height = hgt + 'px';
		mainFormDiv.style.height = (propDiv.offsetHeight - titleGroupDiv.offsetHeight) + 'px';
				
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set msgDeploymentHelp=$$$TextHTML("Checking for another deployment.")
	Set tUnlocked = ##class(Ens.Deployment.Deploy).IsDeploymentTokenUnlocked()	
	Set tTokenInProgress = ##class(Ens.Deployment.Deploy).IsDeploymentTokenInProgress(.tUser, .tJob, .tSC)
	If $$$ISERR(tSC) {
		Set msgDeploymentHelp(1)=$$$TextHTML("An error occurred examining if a deployment is in progress")
		Set msgDeploymentHelp(2)=$ZCVT($$$StatusDisplayString(tSC),"O","HTML")
		If ((msgDeploymentHelp(2)["5540:")||(msgDeploymentHelp(2)["5580:")) {Set msgDeploymentHelp(3)=$$$TextHTML("User needs SQL privileges to tables")_$ZCVT(": Ens_Deployment.Token and Ens_Deployment.Invocations","O","HTML")}
		Set tSC = $$$OK
		Set tMsg = "<div border=1><br/><center><span style=color:red;>"_msgDeploymentHelp(1)_"<br/>"_msgDeploymentHelp(2)_"<br/>"_$G(msgDeploymentHelp(3))_"</span></center><br/></div>"
		Set ..%GetComponentById("propertyPane").hidden=1 
		Set ..%GetComponentById("packageTableBody").content = tMsg
	} ElseIf (tTokenInProgress || 'tUnlocked) {
		/* find all the details from the token object */
		/* if not locked then give option to force clear */
		Set msgDeploymentHelp(1)=$$$TextHTML("A deployment is marked as being in progress for this namespace.")
		Set msgDeploymentHelp(2)=$$$TextHTML("User")_": "_tUser_" "_$$$TextHTML("Job")_": "_tJob
		If tUnlocked {
			Set msgDeploymentHelp(3)=$$$TextHTML("This deployment is not active.")_"<br/><a href='#' onclick='zenPage.gotoPage(""EnsPortal.Deployment.DeploymentHistory.zen"");'>"_$$$TextHTML("Go to the Deployment History page to review and clear in progress flag.")_"</a>"
		} Else {
			Set msgDeploymentHelp(3)=$$$TextHTML("The deployment is currently active and locked.")
		}
		Set tMsg = "<div border=1><br/><center><span style=color:red;>"_msgDeploymentHelp(1)_"<br/>"_msgDeploymentHelp(2)_"<br/>"_msgDeploymentHelp(3)_"</span></center><br/></div>"
		
		Set ..%GetComponentById("propertyPane").hidden=1 
		Set ..%GetComponentById("packageTableBody").content = tMsg
	} Else {
		/*	Before proceeding to check ..deploymentFile to see if exists we 
			will check if the ..deploymentFile was passed to us via Local file 
			upload submit - if so carry out some checks.
			The checks might reset a specified ..deploymentFile to empty
		*/
		#dim tIsValidLocalFile = 0
		If (..deploymentFile '= "") {
			Set tIsValidLocalFile = ..doLocalDeployChecks()
			If (tIsValidLocalFile <= 0) {
				/* Means that either what is cached is invalid or we have selected a server side after local
					need to clear any session data pointing to a local deployment file that might have been selected
				*/
				Do ..clearLocalDeploySession(1)
			}
		}
		/*	Resume deployment file checking. Note doLocalDeployChecks might
			have reset ..deploymentFile to "" if it found inconsistencies with
			parameter data and onsubmit recorded session data.
		*/
		If (..deploymentFile = "") {
			#dim tLocalError
			#dim tErrorMsg = ""
			If $Get(%request.Data("LCLERR",1)) {
				Set tErrorMsg = "<div border=1><br/><center><span style=color:red;>"_$$$TextHTML("Error transferring local deployment file")_"<br/>"_$$$TextHTML("See Event Log for details")_"<br/>"_"</span></center><br/></div>"
				Kill %request.Data("LCLERR")
			}
			If ..canDeployLocalFile {
				Set msgDeploymentHelp = ..msgOpenServerAndLocal
			} Else {
				Set msgDeploymentHelp=..msgOpenServer
			}
			Set ..%GetComponentById("propertyPane").hidden=1 
			Set ..%GetComponentById("packageTableBody").content = tErrorMsg_"<div border=1><br/><center>"_msgDeploymentHelp_"</center><br/></div>"
		} ElseIf '##class(%File).Exists(..deploymentFile) {
				If ..canDeployLocalFile {
					Set msgDeploymentHelp = ..msgOpenServerAndLocal
				} Else {
					Set msgDeploymentHelp=..msgOpenServer
				}
			Set ..%GetComponentById("propertyPane").hidden=1 
			Set ..%GetComponentById("packageTableBody").content = "<div border=1><br/><center>"_msgDeploymentHelp_"</center><br/></div>"
		} Else {
			Set ..%GetComponentById("propertyPane").hidden=0

			Set:(..rollbackFile '= "") ..%GetComponentById("rollbackFileTxt").value = ..rollbackFile
			Set:(..logFile '= "") ..%GetComponentById("logFileTxt").value = ..logFile
			Set tSC = ##class(Ens.Deployment.Deploy).GeneratePackageXMLVDOC(..deploymentFile, .tDeploymentVDOC)
			Set:tSC tSC = ##class(Ens.Deployment.Deploy).GeneratePTDXMLVDOC(..deploymentFile,tDeploymentVDOC,"EnsExportNotes", .tDeploymentNotesVDOC)
			Set:tSC tSC = ##class(Ens.Deployment.Deploy).GetSourceInfo(tDeploymentNotesVDOC,.pSourceInfo)
			If $$$ISERR(tSC) {
					If ..canDeployLocalFile {
						Set msgDeploymentHelp = ..msgOpenServerAndLocal
					} Else {
						Set msgDeploymentHelp=..msgOpenServer
					}
				Set ..%GetComponentById("propertyPane").hidden=1 
				Set ..%GetComponentById("packageTableBody").content = "<div border=1><br/><center>"_msgDeploymentHelp_"</center><br/></div>"
				Set ..deploymentFile=""
				Quit $$$OK
			}
			Set tSC = ##class(Ens.Deployment.Deploy).GetTargetInfo(.pTargetInfo)
			If $$$ISERR(tSC) Quit tSC
			Set ..rollbackforDeploymentFile = tDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/RollbackFor")
			Set tSourceAndTargetSame = ##class(Ens.Deployment.Deploy).CheckSourceAndTargetSame(.pSourceInfo,.pTargetInfo)
			If (..rollbackforDeploymentFile '= "") {
				Set tValue = "****"_$C(10)_$$$TextHTML("This is a Roll back for")_" "_..rollbackforDeploymentFile_$C(10)_"****"_$C(10)_$C(10)
				If 'tSourceAndTargetSame Set tValue = $$$TextHTML("Warning not the same target as source.")_" "_tValue
			} ElseIf tSourceAndTargetSame {	
				Set tValue = "**** "_$$$TextHTML("You are deploying to the same machine, instance and namespace as the source.")_" ****"
			} Else {
				Set tValue = ""
			}
			Set tSourceProduction = $G(pSourceInfo("SourceProduction"))
			Set tTargetProductionNotes = ""
			Set ..productionClassInExportName = $G(pSourceInfo("ProductionClassInExport"))
			If (..productionClassInExportName '= "") {
				If (..targetProduction = "") {
					Set ..targetProduction = pSourceInfo("ProductionClassInExport")
					Set tTargetProductionNotes = $$$TextHTML("Target Production set to source production since source production included in package")
				} 
				Set ..productionClassInExport = 1
			} Else {
				Set:((..targetProduction = "") && ##class(Ens.Config.Production).%ExistsId(tSourceProduction)) ..targetProduction = tSourceProduction
				Set ..productionClassInExport = 0
			}
			/* if targetProduction is still not specified try to find current active production */
			If (..targetProduction = "") {
				Set ..targetProduction = ##class(Ens.Director).GetActiveProductionName()
				Set tTargetProductionNotes = $$$TextHTML("Target Production set to current active production")
			}
			If ((..targetProduction '= "") && (..productionClassInExportName = ..targetProduction) && (##class(Ens.Config.Production).%ExistsId(..targetProduction))) {
				Set tValue = tValue_$S(tValue="":"",1:$C(10))_"**** "_$$$TextHTML("Warning target production class exists and will be overwritten!")_" ****"_$C(10)
				Set ..%GetComponentById("targetProductionTxt").value = ..targetProduction
			}
			
			Set tHTML = "<table>"
				#dim tDisplayFileTitle
				If (tIsValidLocalFile = 1) {
					Set tDisplayFileTitle = $$$FormatTextHTML("Deployment Package: Local file uploaded to - %1",..deploymentFile)
				} Else {
					Set tDisplayFileTitle = $$$FormatTextHTML("Deployment Package: %1",..deploymentFile)
				}
				Set tHTML = tHTML_"<tr/><tr/><tr class=""fileRow""  id=""row_0"" onclick=""zenPage.selectItem('file','0',' ','','');"" onmouseover=""this.style.color='black';"" onmouseout=""this.style.color='';""><td>"_tDisplayFileTitle_"</td></tr>"
			Set tHTML = tHTML_"</table>"
			Set ..%GetComponentById("packageTableHeader").content = tHTML
			Set tValue = tValue_$S(tValue="":"",1:$C(10))_$$$TextHTML("Created on Machine")_": "_$G(pSourceInfo("Machine"))_$C(10)
			Set tValue = tValue_$$$TextHTML("Instance")_": "_$G(pSourceInfo("Instance"))_$C(10)
			Set tValue = tValue_$$$TextHTML("Namespace")_": "_$G(pSourceInfo("Namespace"))_$C(10)
			Set tValue = tValue_$$$TextHTML("Source Production")_": "_tSourceProduction_$C(10)
			Set tValue = tValue_$$$TextHTML("User")_": "_$G(pSourceInfo("Username"))_$C(10)
			Set tValue = tValue_$$$TextHTML("Date")_": "_$$$timeUTCtoLocal($G(pSourceInfo("UTC")))_$C(10)
			Set tValue = tValue_$$$TextHTML("Notes")_": "_$C(10)
			Set tCount = $G(pSourceInfo("Notes"))
			For tC = 1:1:tCount {
				Set tValue = tValue_$G(pSourceInfo("Notes",tC))_$C(10)
			}
			Set tValue = tValue_$C(10)_tTargetProductionNotes
			Set ..%GetComponentById("packageNotes").value = tValue
			Set ..%GetComponentById("packageNotesExp").expanded = 1
			Set tSC = ##class(Ens.Deployment.Deploy).GetProjectContents(..deploymentFile,tDeploymentVDOC,..targetProduction,.tDeployDetails)
			Set:tSC tSC1 = ##class(Ens.Deployment.Deploy).GenerateListsFromProjectContents(.tDeployDetails,.tPTDToDelete,.tStandardOBJLoadList,.tHostItemsToRemove,.tObjectsToDelete)			
			If $$$ISERR(tSC)||$$$ISERR(tSC1) {
				Kill tDeployDetails("Remove") /* clean up so don't display if error */
				If (($$$StatusDisplayString(tSC)["Cannot identify a target production")||($$$StatusDisplayString(tSC)["Cannot open target production")) {
					Set tSC = $$$OK
					Set ..%GetComponentById("packageTableBody").content = "<div border=1><br/><center><span style=color:red;>"_..msgUnableToIdentifyTargetProduction_"<br/>"_..msgNoTargetProduction_"</span></center><br/></div>"
					Set ..%GetComponentById("deploymentSetttingsExp").expanded = 1
				}
			} Else { 
				Set tHTML = ""
				If $D(tDeployDetails("Items")) {
					Set tItemName = $O(tDeployDetails("Items",""))
					While (tItemName '= "") {
						// We use Ens to show the project and the Export notes and the items to Remove
						If (
							(("Ens" '= $E(tItemName,1,3))||($G(tDeployDetails("Items",tItemName,"Type"))="GBL")||($G(tDeployDetails("Items",tItemName,"Type"))="ESD"))
	 						&& ($G(tDeployDetails("Items",tItemName,"ItemAlreadyInProduction"),0) || ($G(tDeployDetails("Items",tItemName,"ExistDate"))'=-1))) {
							If tHTML = "" {
								Set tHTML = "<table class=""packageTableLabel"" ><tr><td>"_$$$Text("Items to Change:")_"</td></tr></table>"
								Set tHTML = tHTML_"<table class=""packageTable"" >"
							}
							Set tItemLocation = $G(tDeployDetails("Items",tItemName,"ExportFileLocation"))
							Set tItemType = $G(tDeployDetails("Items",tItemName,"ExportType"))
							Set tExportName = $G(tDeployDetails("Items",tItemName,"ExportName"))
							Set tItemIsProductionClass = $G(tDeployDetails("Items",tItemName,"ItemIsProductionClass"),0)
							Set tDifferences = ""
							For i = 1:1:$G(tDeployDetails("Items",tItemName,"ReportDifferences")) {Set tDifferences = tDifferences_$S(tDifferences="":"",1:$C(13,10,13,10))_$G(tDeployDetails("Items",tItemName,"ReportDifferences",i)) }
							Set tItemDetails = ""
							Set tIsHostItem = $G(tDeployDetails("Items",tItemName,"ItemIsSettings"),0)
							If tIsHostItem {
								Set:($G(tDeployDetails("Items",tItemName,"ConfigItemName"))'="") tItemDetails = $$$Text("Item name")_": "_tDeployDetails("Items",tItemName,"ConfigItemName")
								Set:'$G(tDeployDetails("Items",tItemName,"ItemAlreadyInProduction"),0) tItemDetails = tItemDetails_" "_$$$Text("New Production Item")
							} ElseIf ($G(tDeployDetails("ProductionSettings")) = tItemName){
								Set tItemDetails = $$$Text("Production Setting Changes:")
							} Else {
								Set tDate = $G(tDeployDetails("Items",tItemName,"ExistDate"))
								If tDate = -1 {Set:((tItemType'="Global")&&(tItemType'="Document")) tItemDetails = $$$Text("New code")} Else {Set tItemDetails = $$$Text("Existing version")_": "_tDate}
							}
							Set tItemDescription = $G(tDeployDetails("Items",tItemName,"Description"))
							Set tHTML = tHTML_"<tr class=""itemRow"" id=""row_"_tItemLocation_""" onclick=""zenPage.selectItem('item','"_tItemLocation_"','"_$ZCVT(tDifferences,"O","JS")_"','"_$ZCVT(tItemDetails,"O","JS")_"','"_$ZCVT(tItemDescription,"O","JS")_"','"_$ZCVT(tItemName,"O","JS")_"','"_$ZCVT(tItemType,"O","JS")_"');"" onmouseover=""this.style.color='black';"" onmouseout=""this.style.color='';"">"
							If $E(tExportName,1,9) = "Settings:" {
								Set tExportName = $$$Text("Business Host")_": "_$P($E(tExportName,10,*),".PTD")
							} Else {
								Set tExportName = $ZCVT(tExportName,"O","HTML")
								Set tExportName = tExportName_" ("_$S(tItemIsProductionClass:$$$Text("Production")_" ",1:"")_tItemType_")"
							}
							Set tHTML = tHTML _ "<td>"_tExportName_"</td></tr>"
						}
						Set tItemName = $O(tDeployDetails("Items",tItemName))
					}
					Set:(tHTML '= "") tHTML = tHTML_"</table>"
				}
				Set tHTML1 = tHTML
				Set tHTML = ""
				If $D(tDeployDetails("Items")) {
					Set tItemName = $O(tDeployDetails("Items",""))
					While (tItemName '= "") {
						// We use Ens to show the project and the Export notes and the items to Remove
						If (
							(("Ens" '= $E(tItemName,1,3))||($G(tDeployDetails("Items",tItemName,"Type"))="GBL")||($G(tDeployDetails("Items",tItemName,"Type"))="ESD"))
							&& '$G(tDeployDetails("Items",tItemName,"ItemAlreadyInProduction"),0) 
							&& ($G(tDeployDetails("Items",tItemName,"ExistDate"))=-1)) {
							
							If tHTML = "" {
								Set tHTML = "<table class=""packageTableLabel"" ><tr><td>"_$$$Text("Items to Add:")_"</td></tr></table>"
								Set tHTML = tHTML_"<table class=""packageTable"" >"
							}
							Set tItemLocation = $G(tDeployDetails("Items",tItemName,"ExportFileLocation"))
							Set tItemType = $G(tDeployDetails("Items",tItemName,"ExportType"))
							Set tExportName = $G(tDeployDetails("Items",tItemName,"ExportName"))
							Set tItemIsProductionClass = $G(tDeployDetails("Items",tItemName,"ItemIsProductionClass"),0)
							Set tDifferences = ""
							For i = 1:1:$G(tDeployDetails("Items",tItemName,"ReportDifferences")) {Set tDifferences = tDifferences_$S(tDifferences="":"",1:$C(13,10,13,10))_$G(tDeployDetails("Items",tItemName,"ReportDifferences",i)) }
							Set tItemDetails = ""
							Set tIsHostItem = $G(tDeployDetails("Items",tItemName,"ItemIsSettings"),0)
							If tIsHostItem {
								Set:($G(tDeployDetails("Items",tItemName,"ConfigItemName"))'="") tItemDetails = $$$Text("Item name")_": "_tDeployDetails("Items",tItemName,"ConfigItemName")
								Set:'$G(tDeployDetails("Items",tItemName,"ItemAlreadyInProduction"),0) tItemDetails = tItemDetails_" "_$$$Text("New Production Item")
							} Else {
								Set tDate = $G(tDeployDetails("Items",tItemName,"ExistDate"))
								If tDate = -1 {Set:((tItemType'="Global")&&(tItemType'="Document")) tItemDetails = $$$Text("New code")} Else {Set tItemDetails = $$$Text("Existing version")_": "_tDate}
							}
							Set tItemDescription = $G(tDeployDetails("Items",tItemName,"Description"))
							Set tHTML = tHTML_"<tr class=""itemRow"" id=""row_"_tItemLocation_""" onclick=""zenPage.selectItem('item','"_tItemLocation_"','"_$ZCVT(tDifferences,"O","JS")_"','"_$ZCVT(tItemDetails,"O","JS")_"','"_$ZCVT(tItemDescription,"O","JS")_"','"_$ZCVT(tItemName,"O","JS")_"','"_$ZCVT(tItemType,"O","JS")_"');"" onmouseover=""this.style.color='black';"" onmouseout=""this.style.color='';"">"
							If $E(tExportName,1,9) = "Settings:" {
								Set tExportName = $$$Text("Business Host")_": "_$P($E(tExportName,10,*),".PTD")
							} Else {
								Set tExportName = $ZCVT(tExportName,"O","HTML")
								Set tExportName = tExportName_" ("_$S(tItemIsProductionClass:$$$Text("Production")_" ",1:"")_tItemType_")"
							}
							Set tHTML = tHTML _ "<td>"_tExportName_"</td></tr>"
						}
						Set tItemName = $O(tDeployDetails("Items",tItemName))
					}
					Set:(tHTML '= "") tHTML = tHTML_"</table>"
				}
				Set tHTML = tHTML1_tHTML
				If $D(tDeployDetails("Remove")) {
					Set tHadARow = 0
					Set tItemName = $O(tDeployDetails("Remove",""))
					Set tCount = 0
					While (tItemName '= "") {
						Set tCount = tCount + 1
						Set tItemType = $G(tDeployDetails("Remove",tItemName,"Type"))
						// We use Ens to show the project and the Export notes and the items to Remove
						If ("Ens" '= $E(tItemName,1,3)) {
							If 'tHadARow {
								Set tHadARow = 1
								Set tHTML = tHTML_"<table class=""packageTableLabel"" ><tr><td>"_$$$Text("Items to be Removed:")_"</td></tr></table>"
								Set tHTML = tHTML_"<table class=""packageTable"" >"
							}
							Set tHTML = tHTML_"<tr class=""itemRow"" id=""deleterow_"_tCount_"""  onmouseover=""this.style.color='black';"" onmouseout=""this.style.color='';"">"
							If $E(tItemName,1,9) = "Settings:" {
								Set tHTML = tHTML _ "<td>"_$$$Text("Business Host")_": "_$P($E(tItemName,10,*),".PTD")_"</td></tr>"
							} Else {
								Set tHTML = tHTML _ "<td>"_tItemName_"</td></tr>"
							}
						}
						Set tItemName = $O(tDeployDetails("Remove",tItemName))
					}
					Set:tHadARow tHTML = tHTML_"</table>"
				}
				Set ..%GetComponentById("packageTableBody").content = tHTML
				Set ..%GetComponentById("targetProductionTxt").value = ..targetProduction
				Set ..%GetComponentById("rollbackFileTxt").value = ..rollbackFile
				Set ..%GetComponentById("logFileTxt").value = ..logFile
				Set ..%GetComponentById("updateTimeout").value = ..updateTimeout
				Set ..%GetComponentById("deploymentSetttingsExp").expanded = 1
			}
		}
	}
	If ..NAMESPACE = "" Set ..NAMESPACE = $namespace
	Quit tSC
}

/// Load the page for the specified Deployment.
ClientMethod loadPackage(deploymentFile, targetProduction, rollbackFile, logFile) [ Language = javascript ]
{
	this.gotoPage("EnsPortal.Deployment.DeployProductionChanges.zen?DFILE="+encodeURIComponent(deploymentFile)+"&TARGETPROD="+encodeURIComponent(targetProduction)+"&BCKFILE="+encodeURIComponent(rollbackFile)+"&LOGFILE="+encodeURIComponent(logFile));
	return;
}

/// Select an item in the table.
ClientMethod selectItem(type, row, differences, itemdetails, itemdescription, itemname, itemtype) [ Language = javascript ]
{
	if ((this.currItem != row)) {
		// unhilite
		if (this.currItem >= 0 && this.currItemType != '') {
			var trow = self.document.getElementById('row_' + this.currItem);
			if (trow) {
				trow.className = this.getCSSForType(this.currItemType);
			}
		}

		this.currItem = row;
		this.currItemType = type;

		// hilite
		var trow = self.document.getElementById('row_' + this.currItem);
		if (trow) {
			trow.className = this.getCSSForType(this.currItemType) + 'Selected';
		}
		if (type == 'file') {
			zen('idItemTitle').setProperty('label',$$$Text('Deployment Package'));
			zen('id1').setHidden(0);
			zen('id2').setHidden(1);
		} else {
			var contents = zenPage.GetItemContents(row,itemname,itemtype);
			if (!contents) {contents = '';} else {contents = contents +'\n\n';}
			if (!itemdescription) {itemdescription = '';} else {itemdescription = $$$Text('Description:')+'<br><br>'+itemdescription;} 
			if (itemdetails !='') { itemdetails = itemdetails +'\n\n'};
			if (differences !=='') { differences = differences +'\n\n' };
			zen('itemContents').setProperty('value',itemdetails+differences+contents);
			zen('idItemTitle').setProperty('label',$$$Text('Item Details'));
			zen('itemDescription').setProperty('content',itemdescription);
			if (itemdescription == '') {
				zen('itemContents').setProperty('rows',10);
			} else {
				zen('itemContents').setProperty('rows',6);
			}
			zen('id1').setHidden(1);
			zen('id2').setHidden(0);
			 
		}	
	}
}

/// Find the css class for the given row type.
ClientMethod getCSSForType(type) [ Language = javascript ]
{
	switch(type) {
	case 'item':
		return 'itemRow';
	case 'file':
		return 'fileRow';
	default:
		alert('Unknown type ' + type);
		break;
	}
	return '';
}

Method GetItemContents(pItemNumber, pItemName As %String = "", pItemType As %String = "") As %String [ ZenMethod ]
{
	Set tContents = ""
	Try {
		Set tExt = $P(pItemName,".",*)
		If (tExt'=""),("^LUT^ESD^"[tExt) {
			Set tSC = ##class(Ens.Deployment.Utils).GetItemContentsByItemNumber(..deploymentFile,pItemNumber,.tContents,.tName,.tExt)
			If $$$ISERR(tSC) Quit
			Set tReader = ##class(%XML.Reader).%New()
			Set tSC = tReader.OpenString(tContents)
			If (tExt = "ESD") {
				Do tReader.Correlate("item","Ens.Config.DefaultSettings")
			} ElseIf (tExt = "LUT") {
				Do tReader.Correlate("entry","Ens.Util.LookupTable")
			} Else {Quit}
			Set c = 0 
			While tReader.Next(.tItem) {
				Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tStream,.tItem,,,,"iw")
				Set tJSON($i(c)) = tStream.Read()_$C(13,10)
			}
			If c {
				Set tContents = $S(tExt="ESD":$$$Text("New deployable default settings:")_$C(13,10),tExt="LUT":$$$Text("New Lookup Table entries:")_$C(13,10),1:"")
				For i = 1:1:c {Set tContents = tContents_tJSON(i)}
			}
			Quit
		} Else {
			Quit
		}
	} Catch {Quit}
	Quit tContents
}

ClientMethod startDeployCode(pMode) [ Language = javascript ]
{
		var doc = self.document;
		if (doc) {
			var btnOpen = doc.getElementById('command_cmdDeploy');
			if (btnOpen) {
				if (btnOpen.className == 'commandButtonDisabled'){
					alert($$$Text("Disabled following deployment"));
				return;	
				}
			}
		}
	
		this.rollbackFile = zen('rollbackFileTxt').value;
		this.logFile = zen('logFileTxt').value;
		
		if (zenPage.FileExists(this.rollbackFile)) {
			alert($$$Text("Rollback file already Exists. Please change Rollback file name."));
			return;
			}

		if ((this.deploymentFile !== '') && (this.rollbackFile !== '') && (this.targetProduction !== '')){
			var checkIfActive = this.checkIfTargetActive(this.targetProduction);
			var msg = $$$Text("Do you wish to apply ")+this.deploymentFile+" "+$$$Text("to")+" "+this.targetProduction+"?";
			if (!checkIfActive) {msg = msg + '\n\n' + $$$Text("Warning: Target production is not the same as current active production!")}
			
			var checkIfOverwriteProd = this.checkIfOverwriteProd(this.productionClassInExportName,this.targetProduction);
			if (checkIfOverwriteProd) {msg = msg + '\n\n' + $$$Text("Warning: Target production will be overwritten with copy in deployment!")}
			msg = msg + '\n\n' + $$$Text("Press Cancel to cancel deployment, press OK to deploy")
			if (confirm(msg)) {
					zenPage.deployCode(1);
			}
		} else if (this.deploymentFile == '') {
				alert(this.msgNoDeploymentFile);
			} else if (this.rollbackFile == '') {
				alert(this.msgNoRollbackFile);
			} else {alert(this.msgNoTargetProduction); }
}

ClientMethod deployCode(pCreateRollbackFirst) [ Language = javascript ]
{
		zenPage.disableButtons();
		var tBody = zen('packageTableBody');
		tBody.setProperty('content',$$$Text('Calling deployment'));

		var tPane = zen('propertyPane');
		tPane.setProperty('hidden',1);
		this.adjustSizes();
		this.updateTimeout = zen('updateTimeout').getProperty('value'); 
		zenPage.DeployCodeAsynch(this.deploymentFile,this.targetProduction,pCreateRollbackFirst,this.rollbackFile,this.logFile,this.updateTimeout);
		if (zenPage.enableAutoRefresh) {
			var timer = zenPage.getComponentById('timer');	
			timer.setProperty('timeout',500);
			timer.startTimer();
		} else {
			zenPage.GetLog();
		}
}

Method checkIfTargetActive(pTargetProduction As %String) As %Boolean [ ZenMethod ]
{
	Set tAns = 1
	Set tActiveProd = ##class(Ens.Director).GetActiveProductionName()
	Set:((tActiveProd '= "" ) && (tActiveProd '= pTargetProduction)) tAns = 0 
	Quit tAns
}

Method checkIfOverwriteProd(pSourceProductionClass As %String, pTargetProduction As %String) As %Boolean [ ZenMethod ]
{
	Quit ((pSourceProductionClass = pTargetProduction)&& ##class(Ens.Config.Production).%ExistsId(pTargetProduction))
}

ClientMethod disableButtons() [ Language = javascript ]
{
	var doc = self.document;
	if (doc) {
		var btnOpen = doc.getElementById('command_cmdOpen');
		if (btnOpen) {
			btnOpen.className = 'commandButtonDisabled';
		}
		var btnOpenLocal = doc.getElementById('command_cmdOpenLocal');
		if (btnOpenLocal) {
			btnOpenLocal.className = 'commandButtonDisabled';
		}
		var btnDeploy = doc.getElementById('command_cmdDeploy');
		if (btnDeploy) {
			btnDeploy.className = 'commandButtonDisabled';
		}
	}
}

Method DeployCodeAsynch(pDeploymentFile As %String, pTargetProduction As %String, pCreateRollback As %Boolean, pRollbackFile As %String, pLogFile As %String, pUpdateTimeout As %Integer) [ ZenMethod ]
{
	Set tAllowDeployToSource = 1 ,tAutoRevert = 1, tWhereToLog = "LH"
	/* Set:(..rollbackforDeploymentFile '="") tAllowDeployToSource = 1 */
	Set tTempPortalCounter = ##class(EnsPortal.SessionEvents).GetTempNode()
	Set tTempPortalNode = ##class(EnsPortal.SessionEvents).GetReference(tTempPortalCounter) /* ^IRIS.Temp.EnsPortal.Data(%sessionid,0,tTempCounter) */
	Set ..tempPortalNode = tTempPortalNode
	Set @tTempPortalNode@("Started") = $H

	#; Clean any %session Data related to DeployFromLocal but we want to keep the file
	Do ..clearLocalDeploySession(0)
	
	Set tSC = ..%RunBackgroundMethod("UIDeployCode",pDeploymentFile,pTargetProduction,pCreateRollback,pRollbackFile,tWhereToLog,pLogFile,tAllowDeployToSource,tAutoRevert,tTempPortalNode,pUpdateTimeout)
}

ClassMethod UIDeployCode(pDeploymentFile, pTargetProduction, pCreateRollback, pRollbackFile, pWhereToLog, pLogFile, pAllowDeployToSource, pAutoRevert, pTempPortalNode, pUpdateTimeout) As %Status
{
	Quit ##class(Ens.Deployment.Deploy).DeployCode(pDeploymentFile,pTargetProduction,pCreateRollback,pRollbackFile,pWhereToLog,pLogFile,pAllowDeployToSource,pAutoRevert,pTempPortalNode)
}

ClientMethod rollbackCode() [ Language = javascript ]
{
	/* Find last deployment production */
	if (confirm($$$Text("Do you wish to rollback the last deployment")+" "+$$$Text("to")+" "+this.rollbackProduction+"?")) {
		if (zenPage.enableAutoRefresh) {	
			var timer = zenPage.getComponentById('timer');
			timer.setProperty('timeout',500);
			timer.startTimer();
		}
		var tBody = zen('packageTableBody');
		tBody.setProperty('content','Rolling back last deployment');
		
		zenPage.disableButtons();

		var tPane = zen('propertyPane');
		tPane.setProperty('hidden',1); 
		
		var packageTableHeader = zen('packageTableHeader');
		var msg = $$$Text('Rolling back the last deployment')+' '+$$$Text("to")+" "+this.rollbackProduction;
		var contents = '<table><tr/><tr/><tr class="fileRow"><td>'+msg+'</td></tr></table>';
		packageTableHeader.setProperty('content',contents);
		
		zenPage.RollbackCodeAsynch();
		if (!zenPage.enableAutoRefresh) {
			zenPage.GetLog();
		}
	}
}

Method RollbackCodeAsynch() [ ZenMethod ]
{
	Do ##class(Ens.Deployment.Deploy).RollbackLastDeployment()
}

/// This function controls the timer on showing the deployment log.
ClientMethod timeout(timer) [ Language = javascript ]
{
	zenPage.GetLog();
	var timer = zen("timer");
	if ((zenPage.inProgress == 'done') || !zenPage.enableAutoRefresh) {
		timer.clearTimer();
	}
	else {  
		timer.startTimer();
	}
}

Method GetLog() [ ZenMethod ]
{
	Quit:((..tempPortalNode = "")||(..inProgress = "")) 
	Set tNextLine = $O(@..tempPortalNode@("Log",..inProgress)) 
	While (tNextLine '="") {
		Set ..inProgress = tNextLine
		Set ..%GetComponentById("packageTableBody").content = $G(@..tempPortalNode@("Log",tNextLine))_"<br/>"_..%GetComponentById("packageTableBody").content
		Set tNextLine = $O(@..tempPortalNode@("Log",tNextLine)) 
	}
	If ($G(@..tempPortalNode@("Finished"),0) '= 0) {
		Set tStatus = $G(@..tempPortalNode@("Status"))
		If $$$ISERR(tStatus) {
			Set tFinishedMsg = "<span style=""color:red;"">"_$ZCVT($$$StatusDisplayString(tStatus),"O","HTML")_"</span>"
			Set ..%GetComponentById("packageTableBody").content = tFinishedMsg_"<br/>"_..%GetComponentById("packageTableBody").content
		}
		Kill @..tempPortalNode
		Set ..inProgress = "done"
	}
	Quit
}

Method FileExists(pFilename) As %Boolean [ ZenMethod ]
{
	Quit ##class(%File).Exists(pFilename)
}

Method GetDirectory(pFilename) As %String [ ZenMethod ]
{
	Quit ##class(%File).GetDirectory(pFilename,1)
}

Method GetFilename(pFilename) As %String [ ZenMethod ]
{
	Quit ##class(%File).GetFilename(pFilename)
}

Method GenerateFilenames(pFilename) As %String [ ZenMethod ]
{
	Do ##class(Ens.Deployment.Utils).GenerateFileNames(pFilename,.tRollbackFile,.tLogFile,.tReportFile)	
	Quit tRollbackFile_"<|>"_tLogFile
}

/// Launch the browser file dialog to select a local deployment file
ClientMethod openLocalDeploymentFile() [ Language = javascript ]
{
	var doc = self.document;
	if (doc) {
		var btnOpen = doc.getElementById('command_cmdOpen');
		if (btnOpen) {
			if (btnOpen.className == 'commandButtonDisabled'){
				alert($$$Text("Disabled following deployment"));
				return;
			}
		}
		var btnOpenLocal = doc.getElementById('command_cmdOpenLocal');
		if (btnOpenLocal) {
			if (btnOpenLocal.className == 'commandButtonDisabled'){
				alert($$$Text("Disabled following deployment"));
				return;
			}
		}
	}
	var divInputCtl = document.getElementById('inputLocalFile');
	if (divInputCtl) {
		var inputCtl = divInputCtl.getElementsByTagName('input')[0];
		if (inputCtl) { inputCtl.click();}
	}
	return;
}

/// Used to indicate if can deploy from a local file via the browser
ClassMethod canDeployFromLocalFile() As %Boolean [ Internal ]
{
	#dim tPermit = 0

	If ..hasLocalDeployPrivileges() {

		If '..browserIsLocal() Set tPermit = 1

	}

	Quit tPermit
}

/// Used to indicate if can deploy from a local file via the browser
ClassMethod hasLocalDeployPrivileges() As %Boolean [ Internal ]
{
	Quit $system.Security.Check("%Ens_DeploymentPkgClient","USE")
}

ClassMethod browserIsLocal() As %Boolean [ Internal ]
{
	#Dim tIsLocal = 1

	// Determine if user is on same machine as the server
	#dim tClientAddr = $ZCVT($G(%request.CgiEnvs("REMOTE_ADDR")),"l")
	#dim tTCPAddr = $SYSTEM.TCPDevice.PeerAddr(0)

	Set tIsLocal = ((tClientAddr = "127.0.0.1") || (tClientAddr = "::1")) && ((tTCPAddr = "127.0.0.1") || (tTCPAddr = "::1"))

	Quit tIsLocal
}

/// This client event is fired when the page is loaded. &&&
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);

	if (!this.canDeployLocalFile) {
		var btn = document.getElementById('command_cmdOpenLocal');
		if (btn) {
			try {
				btn.className = 'commandButtonDisabled';
				btn.onclick = '';
				btn.title = this.msgLocalFileNotAllowed;
			}
			catch (ex) {
			}
		}
	}
}

ClientMethod localFileSelectOnChange() [ Language = javascript ]
{
	zen('formSelectLocalFile').submit();
	return;
}

ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	#; If click Open Local multiple times need to delete the files already saved but not processed
	Do ..clearLocalDeploySession(1)

	#dim tSC = $$$OK
	#dim e As %Exception.AbstractException

	#dim tStream = pSubmit.%GetStream("localFile")

	If ..hasLocalDeployPrivileges() && $IsObject(tStream) && (tStream.Size>0) {

		Try {

			If ..isValidDeployFile(tStream) {

				#dim tFileHash = $SYSTEM.Encryption.SHA3HashStream($$$ensSHA3CheckLength,tStream,.tSC)

				If $$$ISOK(tSC) {

					#dim tFileStream = ##class(%Stream.FileBinary).%New()
					#dim tFilename = tFileStream.NewFileName("xml",tFileStream.DefaultStreamDir())
					#dim tFilenameandDir = ##class(%Library.File).NormalizeFilename(tFilename,tFileStream.DefaultStreamDir())
					Kill %objlasterror
					Do tFileStream.LinkToFile(tFilenameandDir)
					If $Data(%objlasterror) {
						$$$ThrowStatus(%objlasterror)
					}

					Do tFileStream.CopyFrom(tStream)
					Do tFileStream.%Save()

					Set %session.Data("DeployFromLocal",$namespace,"Size") = tFileStream.Size
					Set %session.Data("DeployFromLocal",$namespace,"Filename") = tFileStream.Filename
					Set %session.Data("DeployFromLocal",$namespace,"FileHash") = tFileHash

					#; Pass in the file names for the deployment files
					#dim tRollbackFile = ""
					#dim tLogFile = ""
					Do ##class(Ens.Deployment.Utils).GenerateFileNames(tFileStream.Filename,.tRollbackFile,.tLogFile)
					Set %response.Context("DFILE") = tFileStream.Filename
					Set %response.Context("BCKFILE") = tRollbackFile
					Set %response.Context("LOGFILE") = tLogFile
					Kill %response.Context("LCLERR")

				} Else {

					$$$ThrowStatus(tSC)

				}

			} Else {

				$$$LOGERROR("Attempt to upload invalid local deployment file by "_$username)
				Set %response.Context("LCLERR") = 1

			}

		} Catch e {

			$$$LOGERROR("Error encountered uploading local deployment file to "_##class(%Stream.FileBinary).DefaultStreamDir()_" ("_e.DisplayString()_") by "_$username)
			Kill %session.Data("DeployFromLocal",$namespace)
			Kill %response.Context("DFILE")
			Kill %response.Context("BCKFILE")
			Kill %response.Context("LOGFILE")
			Set %response.Context("LCLERR") = 1
		}

	}

	Quit tSC
}

ClassMethod isValidDeployFile(pStream As %Stream.Object) As %Boolean [ Internal ]
{
	#dim tIsValid = 0

	Try {

		#dim tDeploymentVDOC As EnsLib.EDI.XML.Document = $$$NULLOREF
		Set tSC = ##class(Ens.Deployment.Deploy).GeneratePackageXMLVDOC(pStream, .tDeploymentVDOC)

		If $$$ISOK(tSC) {

			#dim tCount = 0
			#dim tPos = 0
			#dim tPosPTDName = ""
			#dim pPTDNameWanted = "EnsExportNotes"
	
			Set tCount = tDeploymentVDOC.GetValueAt("/Export/Document[*]")

			For tPos = 1:1:tCount {

				Set tPosPTDName = tDeploymentVDOC.GetValueAt("/Export/Document["_tPos_"]/@name")
				Set tPosPTDName=$ZCVT(tPosPTDName,"I","XML")
				If (tPosPTDName[pPTDNameWanted) {

					Set tIsValid = 1

				}

			}

		}

	} Catch {}

	Quit tIsValid
}

Method doLocalDeployChecks() As %Integer [ Internal, Private ]
{
	/*
		Look to see if we posted a local file and verify against hash data
	*/

	#dim tIsValid As %Integer = -1

	If (..deploymentFile '= "") {

		/* Carry out series of tests to see if local request and reset if issues found
			..isValidLocalDeploymentFile(..deploymentFile) returns:
					0 invalid local file
					1 valid local file
					-1 not marked as a local file
		*/
		Set tIsValid = ..isValidLocalDeploymentFile(..deploymentFile)

		If 'tIsValid {

				Set ..deploymentFile = ""
				Set ..rollbackFile = ""
				Set ..logFile = ""

		}

	}

	Quit tIsValid
}

ClassMethod isValidLocalDeploymentFile(pDeploymentFileName As %String = "", Output pSessionLocalFilename As %String = "") As %Boolean [ Internal, Private ]
{
	#; Assume valid server side file
	#dim tIsValid As %Boolean = -1


	Try {

		#dim tDeployFromLocalFilename
		If $Data(%session.Data("DeployFromLocal",$namespace,"Filename"),pSessionLocalFilename)#2 {

			#;1. Check if deployment file name same as created when User uploaded
			#; 		If not the same and we have a recorded session file then check the deployment file is at least valid.
			#;		Or if no filename passed in do size and hash validation
			If (pSessionLocalFilename'=pDeploymentFileName) && (pDeploymentFileName'="") {

				If '..isValidDeployFile(pDeploymentFileName) Set tIsValid = 0

			} Else {

				#;2 Check Same Size
				Set tTempFileStream = ##class(%Stream.FileBinary).%New()
				Do tTempFileStream.LinkToFile(pSessionLocalFilename)
				If tTempFileStream.Size '= $Get(%session.Data("DeployFromLocal",$namespace,"Size"),-1) {

					Set tIsValid = 0

				} Else {

					#;3 Check SHA3 Hash
					#dim tHashSC = $$$OK
					#dim tFileHash = $SYSTEM.Encryption.SHA3HashStream($$$ensSHA3CheckLength,tTempFileStream,.tHashSC)
					If $$$ISERR(tHashSC) {

						Set tIsValid = 0

					} Else {

						If tFileHash '= $Get(%session.Data("DeployFromLocal",$namespace,"FileHash"),-1) {

							Set tIsValid = 0

						} Else {

							#; Passed all the tests
							Set tIsValid = 1

						}

					}

				}

			}

		}

	} Catch { Set tIsValid = 0 }

	Quit tIsValid
}

ClassMethod clearLocalDeploySession(pDeleteFileAsWell As %Boolean = 0) [ Internal, Private ]
{
	/* Clear any session data that might have been set

		1. User selected a local file then changed to selecting a server side
		2. User selected a local file then selected another local file

	*/
	#; Delete the file copied to the server
	If pDeleteFileAsWell Do ..deletePreviousLocalDeploySelection()

	Kill %session.Data("DeployFromLocal",$namespace)
}

ClassMethod deletePreviousLocalDeploySelection() [ Internal, Private ]
{
	#dim tSessionLocalFilename As %String
	If (..isValidLocalDeploymentFile("",.tSessionLocalFilename)=1) {
		If (tSessionLocalFilename'="") && ##class(%Library.File).Exists(tSessionLocalFilename) {
			Do ##class(%Library.File).Delete(tSessionLocalFilename)
		}
	}
}

}
