/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Database Wizard for Management Portal
/// <p><b>Please do not modify any part of this dialog without COMPLETELY testing all cases!!!<br/>
/// Please be extremely careful!!! </b></p>
Class %CSP.UI.Portal.Dialog.DatabaseWizard Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.DatabaseWizard.zen";

/// Displayed name of this page.
Parameter PAGENAME = "DatabaseWizard";

Parameter AUTONS As BOOLEAN = 0;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter EMSSERVICE = "Namespace";

/// User must hold at least operator privilege to use this dialog.
Parameter RESOURCE = "%Admin_Manage";

Parameter HELPID = "GSA_config_databases";

/// Type from where we get the selected items from: Class or Routine.
Property FILETYPE As %ZEN.Datatype.string(ZENURL = "FILETYPE");

Property ResourcePage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/sec/%CSP.UI.Portal.Dialog.Resource.zen")} ];

Property GetDBEncKeyID As %ZEN.Datatype.string [ InitialExpression = {$$$GetDBEncKeyID} ];

Property defaultResource As %ZEN.Datatype.string [ InitialExpression = {$$$DBDEFAULTResourceName} ];

Property AllowNewResource As %ZEN.Datatype.string [ InitialExpression = {$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName)} ];

Property NewResource As %ZEN.Datatype.string [ InitialExpression = {$$$DBDEFAULTResourceName} ];

Property UseExistDB As %ZEN.Datatype.integer;

Property IsMirrorMember As %ZEN.Datatype.integer [ InitialExpression = {$System.Mirror.IsMember()} ];

Property ShowMirrorSet As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Indicate whether the current directory has been evaluated. Whenever Directory is changed (by using Browse or typed in) this is set to 0 and Finish is disabled so that Next is required.
Property DirEvaluated As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// User confirmed to proceed on using MGR directory
Property UserProceed As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Indicate whether the name user entered already exists.
Property NameExists As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property msgNameExists As %ZEN.Datatype.string [ InitialExpression = {$$$TextJS("Database with this name already exists!")} ];

Property msgNameHint As %ZEN.Datatype.string [ InitialExpression = {$$$TextJS("Required.")} ];

Property msgDirExists As %ZEN.Datatype.string [ InitialExpression = {$$$TextJS("Directory does not exist! Please change if you do not wish the directory be created.")} ];

Property curVolThreshold As %ZEN.Datatype.integer;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.labelText {
	font-size: 0.9em;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<tabGroup id="tabGroup">

<!-- First Page -->
<tab id="tab1" enclosingStyle="padding-top:10px;" cellStyle="padding-bottom:10px;" >
 <html OnDrawContent="DrawPageTitle" seed="1" enclosingStyle="padding-bottom:6px;border-bottom:1px solid teal; width:870px;"/>
 <group labelPosition="left">
 <text id="DBName" label="Enter the name of your database" size="40" onkeyup="zenPage.updateDir(zenThis.getValue());zenPage.keyUp(zenEvent);" onchange="zenPage.checkDirExists('getVal');"
 hint="Required." value=""/>
<hgroup id="idRemoteFile" label="Database directory" cellVAlign="top" >
<text id="Directory" size="70" showLabel="false" onkeyup="zenPage.updateState();zenPage.updateBrowsed();"
hint="Required."
 value=""/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('Directory');"/>
<hidden id="browsed" value="0" />
</hgroup>
</group>
</tab>

<!-- Second Page -->
<tab id="tab2" enclosingStyle="padding-top:10px;" cellStyle="padding-bottom:10px;">
<html OnDrawContent="DrawPageTitle" seed="2" enclosingStyle="padding-bottom:6px;border-bottom:1px solid teal; width:870px;"/>
<label id="directoryText" controlClass="zenLabel"/>
<group id="idDirectoryExist1" hidden="true">
<label label="Database file, IRIS.DAT, already exists in directory."/>
<label label ="If you do not want to use it, please press the [Back] button and modify the Directory."/>
</group>
<group id="idMGR" hidden="true">
<label label="It is not generally recommended to define an alias for the system manager database. Proceed only if you FULLY UNDERSTAND the implications of this."/>
<button controlClass="commandButton" caption="I understand. Proceed!" onclick="zenPage.useMGR();"/>
</group>
<group id="idDirectoryExist2" labelPosition="left" cellStyle="padding:4px;">

<text id="Size" label="Initial Size (MB)" size="6" value="1"
hint="This determines how big the initial database will be."/>

<select id="BlockSize" label="Block size for this database will be" showEmpty="false"
hint="Block size is the size of the blocks that the databases uses."/>

<hgroup label="New volume threshold size"
  hint="Enter zero to disable automatic creation of new volumes. If non-zero, when the IRIS.DAT would expand past this threshold, a new volume file called IRIS-0001.VOL will be created.  When expansion would grow that file past the threshold, IRIS-0002.VOL will be created, and so on. For non-zero values a minimum of 1 terabyte is recommended to avoid an excessive number of files.  Each database is limited to 200 volumes." >
<text id="VolThreshold" size="12" hint="" onchange="zenPage.changeVolThreshold(zenThis.getValue());"/>
  <radioSet id="idThresholdUnit" valueList="0,1,2" displayList="TB,GB,MB" originalValue="0" value="0" onchange="zenPage.doUnitSwitch();"/>
 </hgroup>

<select id="GlobalJournalState" label="Journal globals?" valueList="1,2" displayList="No,Yes" showEmpty="false" value="2"
hint="Select 'Yes' to journal globals in this database." onchange="zen('journalChoice').setValue(zenThis.getValue());"/>
<hidden id="journalChoice" value="2" />

<select id="Encrypted" label="Encrypt database?" valueList="0,1" displayList="No,Yes" showEmpty="false" value="0" 
hint="Select 'Yes' to create an Encrypted Database." 
/>

<select id="Mirrored" label="Mirrored database?" valueList="0,1" displayList="No,Yes" showEmpty="false" value="0" 
onchange="zenPage.changeMirror(zenThis.getValue());zenPage.updateState();" hidden="true"
hint="Select 'Yes' to create a Mirrored Database. Globals must be journaled."
/>

<vgroup id="idMirror" hidden="true">
<text id="MirrorDBName" label="Mirror DB Name" hint="Required to create a Mirrored database." onkeyup="zenPage.updateState();"
/>
<select id="MirrorSetName" label="Mirror Set Name" hidden="true" showEmpty="false"/>
</vgroup>
</group>
</tab>

<!-- Third Page -->
<tab id="tab3" enclosingStyle="padding-top:10px;" cellStyle="padding-bottom:10px;">
<html OnDrawContent="DrawPageTitle" seed="3" enclosingStyle="padding-bottom:6px;border-bottom:1px solid teal; width:870px;"/>
<label label="What Is the Database Resource for This Database?"/>
<hgroup>
<spacer width="50"/>
<vgroup labelPosition="left">
<radioButton name="radResource" id="radR1" label="I want to" optionValue="1" value="1" caption="Use the default resource, %DB_%DEFAULT" onclick="zenPage.changeResource(1);"/>
<radioButton name="radResource" id="radR2" optionValue="2" caption="Use an existing resource" onclick="zenPage.changeResource(2);"/>
<radioButton name="radResource" id="radR3" optionValue="3" caption="Create a new resource" onclick="zenPage.changeResource(3);"/>
<select id="ResourceName" label="Database Resource" showEmpty="false" readOnly="true"/>
</vgroup>
</hgroup>
</tab>

<!-- Fourth Page -->
<tab id="tab4">
<html OnDrawContent="DrawPageTitle" seed="4" enclosingStyle="padding-bottom:6px;border-bottom:1px solid teal; width:870px;"/>
<hgroup cellStyle="padding:10px;">
<vgroup cellStyle="padding-bottom:5px;">
<label label="Database name:"/>
<label label="Encrypted database:"/>
<label label="Encryption Key ID:"/>
<label label="Database directory:"/>
<label label="Initial database size (MB):"/>
<label label="Block size:"/>
<label label="New volume threshold size (MB):"/>
<label label="Journal globals:"/>
<label label="Database resource:"/>
<label id="lblMirroredLabel" label="Mirrored database:" hidden="true"/>
<label id="lblMirroredNameLabel" label="Mirrored database name:" hidden="true"/>
<label id="lblMirrorSetNameLabel" label="Mirror set name:" hidden="true"/>
</vgroup>
<vgroup cellStyle="padding-bottom:5px;">
<label id="lblDBName" value=""/>
<label id="lblEncrypted" value=""/>
<label id="lblEncryptionKeyID" value=""/>
<label id="lblDirectory" value=""/>
<label id="lblSize" value=""/>
<label id="lblBlockSize" value=""/>
<label id="lblVolThreshold" value=""/>
<label id="lblGlobalJournalState" value=""/>
<label id="lblResourceName" value=""/>
<label id="lblMirrored" value=""/>
<label id="lblMirroredName" value=""/>
<label id="lblMirrorSetName" value=""/>
</vgroup>
</hgroup>
</tab>
</tabGroup>
</pane>
}

/// Check if name already exists.
ClientMethod checkNameExists(DBName) [ Language = javascript ]
{
	if ((DBName.length > 0) && (this.DBNameExists(DBName) == 1)) {
		zen("DBName").setProperty("hint",this.msgNameExists);
		zen("DBName").setProperty("hintClass","redText");
		zen("DBName").focus();
		this.NameExists = 1;
	} else {
		zen("DBName").setProperty("hint",this.msgNameHint);
		zen("DBName").setProperty("hintClass","helpText");
		this.NameExists = 0;
	}
	return;
}

/// Check if directory already exists.
ClientMethod checkDirExists(DBDir) [ Language = javascript ]
{
	if (DBDir == 'getVal') DBDir = zen("Directory").getValue();
	if ((DBDir.length > 0) && (this.DBDirExists(DBDir) == 0)) {
		zen("Directory").setProperty("hint",this.msgDirExists);
		zen("Directory").setProperty("hintClass","redText");
		zen("Directory").focus();
	} else {
		zen("Directory").setProperty("hint",this.msgNameHint);
		zen("Directory").setProperty("hintClass","helpText");
	}
	return;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = false;
	switch(tabNo) {
	case 1:
		var DBName = zen("DBName").getValue();
		var DBDir = zen("Directory").getValue();
		if ((DBName != "") && (DBDir != "")) {
			flag = true;	
		}
		break;
	case 2:
		var isMirror = parseInt(zen("Mirrored").getValue());
		var mirrorDBName = zen("MirrorDBName").getValue();
		if ((this.UseExistDB == 0) && ((mirrorDBName != "") || (isMirror == false))) {
			flag = true;
		}
		break;
	case 3:
		flag = true;
		break;
	case 4:
		flag = false;
		break;

	}
	return flag;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		flag = false;
		break;
	case 2:
		break;
	case 3:
		break;	
	case 4:
		break;
	}	

	return flag
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
ClientMethod canFinish() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		var DBName = zen("DBName").getValue();
		var DBDir = zen("Directory").getValue();
		flag = ((DBName != "") && (DBDir != "") && (this.DirEvaluated)) ? true : false;
		break;
	case 2:
		var isMirror = parseInt(zen("Mirrored").getValue());
		var mirrorDBName = zen("MirrorDBName").getValue();
		flag = ((mirrorDBName != "") || (isMirror == false)) ? true : false;
		break;
	case 3:
		break;
	case 4:
		break;
	}	
	//zen("btnCancel").setDisabled(false);	
	
	return flag;
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

ClientMethod changeMirror(isMirror) [ Language = javascript ]
{
	isMirror = parseInt(isMirror);
	var idGlobalJournal = zen("GlobalJournalState");
	zen("idMirror").setProperty("hidden",!isMirror);
	idGlobalJournal.setProperty("disabled",isMirror);
	if (isMirror) {
		// if DB is mirrored, globals must be journaled
		idGlobalJournal.setValue(2);
		zen("MirrorDBName").focus();
	} else if (zen("journalChoice").getValue() == '1') {
		// if the user had chosen to not journal globals, reset to their choice now.
		idGlobalJournal.setValue(1);
	}
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		var DBName = zen("DBName").getValue();
 		if (DBName.length > 0) {
	 	  this.checkNameExists(DBName);
	 	  if (this.NameExists == 1) return;
	       //if directory is there then go to next tab
	      if (zen("Directory").getValue() != "") {
		      this.nextPage();
	      } else {
		    //set focus to Directory
		   	zen("Directory").focus();   
	      }
       	} else {
	       alert($$$Text("Please enter a database name."));
       	}
	}
}

ClientMethod changeVolThreshold(newVal) [ Language = javascript ]
{
	var unit = parseInt(zen("idThresholdUnit").getValue());
	switch (unit) {
		case 0: unit = 1024 * 1024; break;
		case 1: unit = 1024; break;
		case 2: unit = 1; break;
	}
	var val = zenTrim(newVal);
	if (val == '') {
		val = 0;
	} else {
		val = parseInt(val);
	}
	if ((isNaN(val)) || (val < 0)) {
		var msg = $$$Text("New volume threshold size must be zero or a positive number.");
		alert(msg);
		zen("VolThreshold").setValue(this.curVolThreshold/unit);
		zen("VolThreshold").focus();
		return;
	}
	if (val && ((val * unit) < (1024 * 1024))) {
		a = $$$Text("For non-zero values a minimum of 1 terabyte is recommended to avoid an excessive number of files.  Each database is limited to 200 volumes. Keep small new volume threshold size?");
		if (confirm(a) == false) {
			zen("VolThreshold").setValue(this.curVolThreshold/unit);
			return;
		}
	}
	this.curVolThreshold = val * unit;
}

ClientMethod doUnitSwitch() [ Language = javascript ]
{
	var val = parseInt(this.curVolThreshold);
	var unit = parseInt(zen("idThresholdUnit").getValue());
	switch (unit) {
		case 0:
		zen("VolThreshold").setValue(val/1024/1024);
		break;
		case 1:
		zen("VolThreshold").setValue(val/1024);
		break;
		case 2:
		zen("VolThreshold").setValue(val);
		break;
	}
}

/// Update flag to indicate that the directory is user selected/entered so modifying the Name field 
/// would not override the directory.
ClientMethod updateBrowsed() [ Language = javascript ]
{
	zen("browsed").setValue(1);
	this.DirEvaluated = 0;
	// whenever directory is changed, disable the Finish button so Next can verify the directory
	this.updateState();
	this.checkDirExists(zen("Directory").getValue());
}

/// Go to the next page of the template (if there is one).<br/>
ClientMethod nextPage() [ Language = javascript ]
{
	this.resetMsg();
	zen('idMGR').setHidden(true);
	
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	
	var DBName = zen("DBName").getValue();
	var Directory = zen("Directory").getValue();
	
	switch(tabNo) {
	case 1:
		// echos user entered directory on tab 2 so they don't have to back to previous tab to see what they entered
		zen('directoryText').setValue($$$FormatText($$$Text("Directory: %1"), Directory));
		var result = this.DBNameIsValid(DBName);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage);
			break;
		}
		var dbexists = this.DbExists(Directory);
		if (dbexists == 0) {
			// it's okay to create a new db in this directory
			// hide message about .DAT already exist
			zen("idDirectoryExist1").setHidden(true);
			// show prompts for details
			zen("idDirectoryExist2").setHidden(false);
			this.UseExistDB = 0;
		} else {
			if (dbexists == 3) {
				this.showMsg($$$Text("IRIS.DAT exists in this directory, but it could not be opened. Possibly it is a database with different endian - creating database in this directory is not allowed."));
				this.UseExistDB = 2;
				break;
			} else {
				// show message about database already exist
				zen("idDirectoryExist1").setHidden(false);
				// hide prompts for details
				zen("idDirectoryExist2").setHidden(true);
				this.UseExistDB = 1;
			}
		}
		this.DirEvaluated = 1;
		tabGroup.showNextTab();
		break;
	case 2:
		tabGroup.showNextTab();
		var DBName=zen("DBName").getValue().toUpperCase();
		if ((DBName == "IRISDATAMOVE") || (DBName == "IRISDATAMOVEMIRROR")) {
			zen("ResourceName").setValue("%DB_IRISSYS");
			zen("radR2").setValue(2);
		}
		break;
	case 3:
		var lblYes = $$$Text("Yes");
		var lblNo = $$$Text("No");
		var lblBytes = $$$Text("bytes");
		zen("lblDBName").setValue(DBName);
		zen("lblEncrypted").setValue((zen("Encrypted").getValue()==1) ? lblYes : lblNo);
		zen("lblEncryptionKeyID").setValue((zen("Encrypted").getValue()==1) ? this.GetDBEncKeyID : "");
		zen("lblDirectory").setValue(Directory);
		var size = zenTrim(zen("Size").getValue());
		if (size == '') {
			size = 1;
		} else if (isNaN(parseInt(size))) {
			size = size;
		} else {
			size = parseInt(size);
		}
		zen("lblSize").setValue(size);
		zen("lblVolThreshold").setValue(this.curVolThreshold);
		zen("lblBlockSize").setValue(zen("BlockSize").getValue()+" "+lblBytes);
		zen("lblGlobalJournalState").setValue((zen("GlobalJournalState").getValue()==2) ? lblYes : lblNo);
		zen("lblResourceName").setValue(zen("ResourceName").getValue());
		if (zenPage.IsMirrorMember != 0) {
			zen("lblMirroredLabel").setHidden(false);
			zen("lblMirrored").setHidden(false);
			if (zen("Mirrored").getValue() == 1) {
				zen("lblMirroredNameLabel").setHidden(false);
				zen("lblMirroredName").setHidden(false);
				zen("lblMirrored").setValue(lblYes);
				zen("lblMirroredName").setValue(zen("MirrorDBName").getValue());
				if (zenPage.ShowMirrorSet == 1) {
					zen("lblMirrorSetName").setHidden(false);
					zen("lblMirrorSetNameLabel").setHidden(false);
					zen("lblMirrorSetName").setValue(zen("MirrorSetName").getValue());
				}
			} else {
				zen("lblMirrored").setValue(lblNo);
				zen("lblMirroredName").setHidden(true);
				zen("lblMirroredNameLabel").setHidden(true);
				if (zenPage.ShowMirrorSet == 1) {
					zen("lblMirrorSetName").setHidden(true);
					zen("lblMirrorSetNameLabel").setHidden(true);
				}
			}
		}
		tabGroup.showNextTab();
		break;
	case 4:
		tabGroup.showNextTab();
}
zenPage.updateState();
}

/// Go to the previous page of the template (if there is one).<br/>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
	this.resetMsg();	
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	switch(tabNo) {
	case 1:
		break;
	case 2:
		tabGroup.showPreviousTab();
		break;
	case 3:
		tabGroup.showPreviousTab();
		break;
	case 4:
		tabGroup.showPreviousTab();
		break;

	}
	zenPage.updateState();
}

/// Process save and create new db. Return true if success. OW return false.
ClientMethod doSave() As %Boolean [ Language = javascript ]
{
	this.resetMsg();
	try {
		var Directory = zen("Directory").getValue();
		var result = this.CreateDirectory(Directory);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage);
			return false;
		}
		
		if (!this.validateSize(Directory)) {
			return false;
		}

		var proxy = new zenProxy();
		proxy.DBName = zen("DBName").getValue();
		proxy.Directory = Directory;
		proxy.Encrypted = zen("Encrypted").getValue();
		proxy.Size = parseInt(zenTrim(zen("Size").getValue()));
		proxy.BlockSize = zen("BlockSize").getValue();
		proxy.VolThreshold = this.curVolThreshold;
		proxy.Resource = zen("ResourceName").getValue();
		proxy.GlobalJournalState = zen("GlobalJournalState").getValue();
		proxy.UseExistDB = this.UseExistDB;
		if (!parseInt(zen("Mirrored").getValue())) {
			proxy.MirrorDBName = "";
			proxy.MirrorSetName = "";
		} else {
			proxy.MirrorDBName = zen("MirrorDBName").getValue();
			proxy.MirrorSetName = zen("MirrorSetName").getValue();
		}
		var result = this.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage);
			return false;
		}
	} catch(ex) {
		zenExceptionHandler(ex,arguments);
		return false;
	}
	return true;
}

/// This method checks if user entered directory is the manager directory. If it is, then show warning message and have user confirm to proceed.
ClientMethod validateMGR() As %Boolean [ Language = javascript ]
{
	try {
		var Directory = zen("Directory").getValue();
		var proxy = this.IsMGRDir(Directory);
		var isvalid = 1;
		if (proxy.ismgr == 1) {
			zen('idMGR').setHidden(false);
			isvalid = 0;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return isvalid;
}

/// User clicked the Proceed button to use the MGR database
ClientMethod useMGR() [ Language = javascript ]
{
	this.UserProceed = 1;
	zenPage.dialogFinish();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.<br/>
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var isvalid;
		// if user clicked the Finish button, we validate the dir (this.UserProceed is 1 only when user clicked the Proceed button and then we will skip this check)
		if (!this.UserProceed) {
			isvalid = this.validateMGR();
		} else {
			/// user has clicked the Proceed button
			isvalid = 1;	
		}
		if (isvalid) {
			return this.doSave();
		} else {
			return false;	
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('DBName').getValue();
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	//var frame = zen("output");
	var wd = zenGetWindowWidth() - 80;
	var ht = zenGetWindowHeight() - 210;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	//frame.setProperty("width",wd);
	//frame.setProperty("height",ht);
}

/// User clicked the Browse button.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	var wildcard = "*";
	var Dir = zen(name).getValue();
	var showdirectoryonly = 1;
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard+'&showdirectoryonly='+showdirectoryonly,'FileSelect','resizable,width=680,height=750');
}

ClientMethod changeResource(flag) [ Language = javascript ]
{
	switch (flag) {
		case 1:
			this.NewResource = this.defaultResource;
			zen("ResourceName").setValue(this.defaultResource);
			zen("ResourceName").setProperty("readOnly",true);
			break;
		case 2:
			zen("ResourceName").setProperty("readOnly",false);
			break;
		case 3:
			var DBName = encodeURIComponent(zen("DBName").getValue());
			var parms = {
					RESOURCETYPE:DBName
			};
			zenLaunchPopupWindow(this.ResourcePage,'CreateResource','resizable,width=600,height=600',parms);
			break;
	}
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.<br/>
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		if (popupName == "CreateResource") {
			// add the new one to the list and make it a default selected.
			zen("ResourceName").setProperty("readOnly",false);
			var valueList = this.GetResourceList();
			zen("ResourceName").setProperty("valueList",valueList);
			zen("ResourceName").setValue(value);
		}
		if (popupName == "FileSelect") {
			zen("Directory").setValue(value);
			zen("browsed").setValue(1);
			this.DirEvaluated = 0;
			this.checkDirExists(value);			
			this.updateState();
			// work around IE bug which disables text boxes by setting focus here
			zen("Directory").focus();
		}
	}
}

/// This is called when the template is first displayed;<br/>
/// This provides a chance to load the last filetype, etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	//this.onresizeHandler();
	// disable Create new resource if user is not allowed to create
	zen("radR3").setDisabled(!this.AllowNewResource);
	this.updateState();
	zen("DBName").focus();
}

/// Update directory while user typing in Name<br/>
/// But do not do so if user has selected a directory from the Browse window<br/>
/// Also update the Mirror DB Name with the user-entered name.
ClientMethod updateDir(DBName) [ Language = javascript ]
{
	var browsed = zen("browsed").getValue();
	//if user deleted the browsed dir then allow update
	if (zen("Directory").getValue() == "") browsed = 0;
	if (browsed == 0) {
		if (DBName.length > 0) {
			zen("Directory").setValue(this.GetDefaultDir(DBName));	
		} else {
			zen("Directory").setValue("");	
		}
	}
	this.DirEvaluated = 0;
	zen("MirrorDBName").setValue(DBName.toUpperCase());
	this.checkNameExists(DBName);
	this.updateState();
}

ClientMethod validateSize(Dir) [ Language = javascript ]
{
	var size = zenTrim(zen("Size").getValue());
	if (size == '') {
		size = 1;
	} else {
		size = parseInt(size);
	}
	if ((isNaN(size)) || (size < 1)) {
		var msg = $$$Text("Database size must be a positive number.");
		this.showMsg(msg,true);
		zen("Size").focus();
		return false;
	}
	
	var result = this.GetFreeSpace(Dir);
	if (result.ok != 1) {
		this.showMsg(result.ErrorMessage,true);
		return false;
	}
	if (size > parseFloat(result.FreeSpace)) {
		var msg = $$$Text("Database size (%1 MB) may not be greater than total available disk space (%2 MB).");
		msg = msg.replace('%1',size);
		msg = msg.replace('%2',result.FreeSpace);
		this.showMsg(msg,true);
		zen("Size").focus();
		return false;
	}
	if (size > (parseFloat(result.FreeSpace)*90/100)) {
		var msg = $$$Text("Warning! Database size (%1 MB) is greater than 90% of available disk space (%2 MB).\nAre you sure you want to create the database with %1 MB?");
		msg = msg.replace(/%1/g,size);
		msg = msg.replace('%2',result.FreeSpace);
		if (!confirm(msg)) {
			zen("Size").focus();
			return false;
		}
	}
	return true;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Database Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	#;SML3048+ ; Initial value of NewVolumeThreshold is zero.
	Set ..curVolThreshold = 0
	Set ..%GetComponentById("VolThreshold").value = 0
	#;SML3048-
	Set (valueList, displayList) = ""
	Set MultiDB("8192") = "8KB",MultiDB = 0
	If ##class(SYS.Database).CheckBlockSizeAllowed(2048) Set MultiDB("2048") = "2KB",MultiDB = 1
	If ##class(SYS.Database).CheckBlockSizeAllowed(4096) Set MultiDB("4096") = "4KB",MultiDB = 1
	If ##class(SYS.Database).CheckBlockSizeAllowed(16384) Set MultiDB("16384") = "16KB",MultiDB = 1
	If ##class(SYS.Database).CheckBlockSizeAllowed(32768) Set MultiDB("32768") = "32KB",MultiDB = 1
	If ##class(SYS.Database).CheckBlockSizeAllowed(65536) Set MultiDB("65536") = "64KB",MultiDB = 1
	Set item = ""
	For  Set item=$O(MultiDB(item)) Quit:item=""  Set valueList = valueList_$S(valueList'="":",",1:"")_item,displayList=displayList_$S(displayList'="":",",1:"")_MultiDB(item)
	Set ..%GetComponentById("BlockSize").valueList = valueList,..%GetComponentById("BlockSize").displayList = displayList
	;
	If ..GetDBEncKeyID = "" {
		Set ..%GetComponentById("Encrypted").disabled = 1
		Set ..%GetComponentById("Encrypted").labelClass="zenHint"
		Set ..%GetComponentById("Encrypted").hint = $$$TextHTML("You may not create an Encrypted Database because Encryption is not activated.")
	} else {
		Set ..%GetComponentById("Encrypted").hint = $$$TextHTML("Select Yes to create an Encrypted Database with default Key ID ")_..GetDBEncKeyID
	}
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	Do tRS.Execute(,,$$$DBResourceType)
	Set ..%GetComponentById("ResourceName").valueList = ..GetResourceList()
	Set ..%GetComponentById("ResourceName").value = ..defaultResource

	Set LastDBDir = ..GetLastDBDir()
	#; Mirror fields are hidden unless system is a mirror member.
	If ..IsMirrorMember '= 0 {
		Set ..%GetComponentById("Mirrored").hidden = 0
		#; Determine what to do with Mirror Set Name. Show it only if
		#; (1) it is Async member;
		#; (2) the list has more than 1 names in it.
		If ..IsMirrorMember = 2 {
			Set tValueList = ""
			Set tRS = ##class(%ResultSet).%New("Config.Mirrors:List")
			Do tRS.Execute("*")
			While tRS.Next() {
				Set tValueList = tValueList_$S(tValueList'="":",",1:"")_tRS.Data("Name")
			}
			If $L(tValueList,",") > 1 {
				Set ..%GetComponentById("MirrorSetName").valueList = tValueList
				Set ..%GetComponentById("MirrorSetName").hidden = 0
				Set ..ShowMirrorSet = 1
			}
		}
	}
	Quit $$$OK
}

/// If this is the first time user entering a database, the last directory is null. Return "".
/// Else return default directory with the new DBName added
ClassMethod GetDefaultDir(DBName As %String) As %String [ ZenMethod ]
{
	Set LastDir = ..GetLastDBDir()
	If LastDir = "" Quit ""
	Quit ##class(%File).SubDirectoryName(LastDir,DBName)
}

ClassMethod GetLastDBDir() As %String [ ZenMethod ]
{
	Quit $G($$$IRISTempMgt($UserName,"LASTDIR","DATABASEWIZARD"))
}

ClassMethod SetLastDBDir(Directory As %String) As %String [ ZenMethod ]
{
	Set LASTDIR = ##class(%File).ParentDirectoryName(Directory)
	Set $$$IRISTempMgt($UserName,"LASTDIR","DATABASEWIZARD") = LASTDIR
	Quit $$$OK
}

ClassMethod GetResourceList() As %String [ ZenMethod ]
{
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	Do tRS.Execute(,,$$$DBResourceType)
	Set valueList = ""
	For  Quit:'tRS.Next()  Set item = tRS.GetData(1) If item'="" Set valueList = valueList_$S(valueList'="":",",1:"")_item
	Quit valueList
}

ClassMethod GetFreeSpace(Dir As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tSC = ##Class(%Library.File).GetDirectorySpace(Dir,.FreeSpace,.TotalSpace)
	If $$$ISOK(tSC) {
		Set tProxy.ok = 1
		Set tProxy.FreeSpace = FreeSpace
		Set tProxy.TotalSpace = TotalSpace
	} Else {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(tSC)
	}
	Quit tProxy
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	If pSeed = 1 {
		Set tPageTitle = $$$TextHTML("This wizard will help you create a new database.")
	} ElseIf pSeed = 2 {
		Set tPageTitle = $$$TextHTML("Enter details about the database.")
	} ElseIf pSeed = 3 {
		Set tPageTitle = $$$TextHTML("Database resources control access to the contents of InterSystems IRIS databases.")
	} Else {
		Set tPageTitle = $$$TextHTML("You are about to complete the wizard. Please review values below. When ready, press the [Finish] button to create the new database.")
	}
	&html<<div class="Description">#(tPageTitle)#</div>>
	Quit 1
}

/// Check if DBName user entered already exists (1 = yes; 0 = no).
ClassMethod DBNameExists(DBName As %String) As %String [ ZenMethod ]
{
	Quit ##Class(Config.Databases).Exists(DBName)
}

/// Validate Database Name
ClassMethod DBNameIsValid(DBName As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	
	#; copied from Config.Databases
	If '(DBName?1(1(1A,1"_").(1AN,1"_",1"-"))) {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult($$$ERROR($$$DatabaseNameInvalid))
	}
	Quit tProxy
}

/// Check if Directory user entered already exists (1 = yes; 0 = no).
ClassMethod DBDirExists(Directory As %String) As %String [ ZenMethod ]
{
	Quit ##Class(%File).DirectoryExists(Directory)
}

/// Check whether database exists in this directory
ClassMethod DbExists(Dir As %String) As %String [ ZenMethod ]
{
	Set Value1 = $zu(12,Dir,1)
 	If Value1 = "" {
	 	If $$$isVMS Set Value1 = $zu(12,Value1,4)
	 	If Value1 = "" Quit 0
	 	Else  &javascript<zen("Directory").setValue("#(Value1)#");>
 	}
 	Set Dir = Value1 _ "IRIS.DAT"
	If (##class(%File).Exists(Dir)) {
		Set db = ##class(SYS.Database).%OpenId(Value1,,.status)
		If '$$$ISOK(status) Quit 3
		Quit Dir
	}
	Quit 0
}

/// Check if the directory entered or selected is the same as the system manager directory. <br>
/// result is returned as a proxy object.
/// proxy.ismgr = 1 or 0; proxy.ok = 1 or 0; proxy.ErrorMessage is actual error message if proxy.ok = 0.<br>
ClassMethod IsMGRDir(Directory As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Try {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.ok = 1
		Set tProxy.ismgr = 0
		/// The 1st piece returned from $ZU(49) for a mounted database is the sfn. zero is the sfn of the manager's database.
		If +$ZU(49, $zstrip(Directory,"<>W")) = 0 {
			Set tProxy.ismgr = 1
		}
		} Catch Error {
			Set tProxy.ok = 0
			Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
		}
	Quit tProxy
}

ClassMethod CreateDirectory(Directory As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Directory = $zstrip(Directory,"<>W")
		Set tSC = ##class(%File).CreateDirectoryChain(Directory)
		If $$$ISERR(tSC) {
			Set msg = Directory_": "_$$$Text("Could not create this directory. Please check the directory and try again.")
			Set tSC = $$$ERROR($$$ObjectScriptError,msg)
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Do ..SetLastDBDir(Directory)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set DBName = $ZCVT(pProxy.DBName,"U")
		i (DBName = "IRISDATAMOVE")||(DBName="IRISDATAMOVEMIRROR") s pProxy.Resource=$$$DBIRISSYSResourceName
		Set Size = $CASE(pProxy.Size,"":1,:pProxy.Size)
		#;SML3048; Setup NewVolumeThreshold value.
		Set VolThreshold = $CASE(pProxy.VolThreshold,"":0,:pProxy.VolThreshold)
		Set BlockSize = $CASE(pProxy.BlockSize,"":8192,:pProxy.BlockSize)
		Set Directory = $zstrip(pProxy.Directory,"<>W")
		Set Properties("Directory") = Directory
		If pProxy.UseExistDB {
			Set tSC =##class(Config.Databases).Create(DBName,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set JournalState = ##class(%Library.JournalState).MenuToLogical(pProxy.GlobalJournalState)
			#;SML3048; Create DB with NewVolumeThreshold value.
			Set tSC = ##class(SYS.Database).CreateDatabase(Directory,Size,BlockSize,pProxy.Encrypted,pProxy.Resource,JournalState,pProxy.MirrorDBName,pProxy.MirrorSetName,,,,,,VolThreshold)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			#; Handle if we have dismounted then deleted the database at the O/S level,
			#; but the CPF entry still exists with the same directory, then recreate the DB only
			If ##Class(Config.Databases).Exists(DBName,.Obj) {
		 		Set tSC = ##class(Config.Databases).Modify(DBName,.Properties)
			} Else {
				Set tSC = ##Class(Config.Databases).Create(DBName,.Properties)
			}
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
