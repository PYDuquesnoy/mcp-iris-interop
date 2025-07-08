/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  Zen page for System Management Portal - Edit Local Database Properties
Class %CSP.UI.Portal.Database Extends %CSP.UI.Portal.DatabaseTemplate [ System = 4 ]
{

///  Displayed name of this page.
Parameter PAGENAME = "Database Properties";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Database.zen";

Parameter HELPADDRESS = "Home,Configuration,Local Databases,Database Properties";

Property CanBeMirrored As %Boolean;

///  MirrorSetName is not null if this window is called from Mirroring Settings
Property MirrorSetName As %ZEN.Datatype.boolean(ZENURL = "MirrorSetName");

Property NoJournalWarningDBs As %ZEN.Datatype.string [ InitialExpression = ",IRISLIB,IRISTEMP,DOCBOOK,IRISLOCALDATA," ];

Property ResourcePage As %ZEN.Datatype.caption [ InitialExpression = {..Link("/csp/sys/sec/%CSP.UI.Portal.Dialog.Resource.zen",,1)} ];

Property OldMaxSize As %ZEN.Datatype.integer;

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-left:4px;padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld" readOnlyMessage="this is a readonly form!">
<label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;" controlStyle="white-space:pre-line;"/>
<group enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left" >

<text id="Name" label="Name" size="44" maxlength="32" value="#(%page.DBName)#" hint="Required." onchange="zenPage.doModified();"
title="Database name consists of 1 to 32 characters."/>
<label id="NameLabel" label="Name" controlClass="normal" value="#(%page.DBName)#" hidden="true"/>

<hgroup id="idDirectory" label="Directory" >
<label id="lblDirectory" value="#(%page.Directory)#" controlClass="normal"/>
<text id="txtDirectory" value="#(%page.Directory)#" size="44" hidden="true" onchange="zenPage.updateDirectory(zenThis.getValue());" hint="Required."/>
<image id="imgDirectory" src="images/folderopen.gif" onclick="zenPage.browseSelect('Directory');"
title="Browse database directory"/>
</hgroup>
<hgroup id="idNewDirectory" hidden="true">
<label label="Warning: You have changed the database directory!" labelClass="rednote"/>
<link id="linkUndo" href="#" caption="undo" onclick="zenPage.undoDirChange();return false;" enclosingClass="smpLink"/>
</hgroup>
<label id="Encrypted" label="Encrypted" controlClass="normal"/>

<!-- Fields for Mirror is shown only if running on Primary Failover Member -->
<hgroup id="idMirror" label="Mirrored" hidden="true">
<label id="Mirrored" label="No" labelClass="normal" />
<link id="linkAddMirror" href="#" onclick="zenPage.doAddMirror();return false;" title="Add this database to mirror." enclosingClass="smpLink"/>
<label id="lblJournalRequired" controlClass="normal" hidden="true"/>
<label id="lblReadOnly" controlClass="normal" hidden="true"/>
<label id="lblBoth" controlClass="normal" hidden="true"/>
</hgroup>

<label id="BlockSize" label="Block Size" controlClass="normal"/>

<hgroup id="idSize" label="Size (MB)" labelPosition="left" enclosingStyle="padding:4px;border:1px solid gray;" >
<text id="Size" label="Current" labelClass="normal" size="5" valign="top" hint=" " enclosingStyle="padding-left:2px;"
title="Current database size in MB. May be enlarged to cause the database to start expanding to the new size." onchange="zenPage.doModified();"/>
<spacer width="4px"/>
<text id="ExpansionSize" label="Expansion" labelClass="normal" size="5" valign="top" hint="0 for Default"
title="Expansion size in MB. Recommended to use 0 for system defaults." onchange="zenPage.doModified();"/>
<text id="MaxSize" label="Maximum" labelClass="normal" size="5" valign="top" hint="0 for Unlimited"
title="Maximum size in MB. Recommended to use 0 for unlimited size." onchange="zenPage.changeMaxSize(zenThis.getValue());"/>
</hgroup>

<hgroup id="idResource" labelPosition="left" label="Resource Name">
<select id="ResourceName" showEmpty="false" onchange="zenPage.doModified();"
title="The name of the database resource that governs access to the database"/>
<button id="ResourceButton" caption="Create New Resource..." onclick="zenPage.doResource();"
title="Create a new resource for this database."/>
</hgroup>

<select id="NewGlobalCollation" label="New Global Collation" showEmpty="false" valign="top" onchange="zenPage.doModified();"/>

<!-- journal state has unusual values: valueList="1,2" displayList="No,Yes" -->
<hgroup id="idGlobalJournal" label="Global Journal State">
<checkbox id="GlobalJournalState" onchange="zenPage.changeJournal(zenThis.getValue());zenPage.doModified();"
title="Specifies whether or not the database is journaled"/>
<label id="lblJournalState" label="Warning: InterSystems highly recommends that databases be journaled!" labelClass="rednote" hidden="true"/>
</hgroup>

<!-- checkboxes serires -->
<checkbox id="NewGlobalIsKeep" label="Preserve Global Attributes on Delete"
title="Preserves global directory entry and attributes when global is deleted" onchange="zenPage.doModified();"/>
<checkbox id="ReadOnly" label="Mount Read-Only" readonlyNobox="true" controlClass="normal" onchange="zenPage.changeReadOnly(zenThis.getValue());zenPage.doModified();"
title="Specifies whether the database will be mounted read-only; if the database is currently mounted read-write, it will be dismounted and mounted read-only."/>
<checkbox id="MountRequired" label="Mount Required at Startup" onchange="zenPage.changeMount(zenThis.getValue());zenPage.doModified();" controlClass="normal"
title="Specifies whether the database must be mounted when InterSystems IRIS starts up; if the database cannot be mounted, InterSystems IRIS will not start."/>

<!-- Stream location -->
<hgroup id="idStreamLocation" labelPosition="left" label="Stream Location">
<text id="StreamLocation"  size="40" onchange="zenPage.doModified();"
title="Directory where the streams associated with this database. The default location is the subdirectory 'stream', underneath the database directory."/>
<button id="StreamButton" caption="Browse..." onclick="zenPage.browseSelect('StreamLocation');"
title="Browse stream location"/>
</hgroup>

<!-- for cluster = 1: -->
<hgroup id="idCluster" label="Cluster" labelClass="normal" labelPosition="left" enclosingStyle="padding:4px;border:1px solid gray;" >
<checkbox id="ClusterMountMode" caption="Mount Clustered" captionClass="normal"
title="Database is configured to be mounted in cluster mode" onchange="zenPage.doModified();"/>
<spacer width="4px"/>
<checkbox id="MountAtStartup" caption="Mount Clustered at Startup" captionClass="normal"
title="Specifies whether to mount the cluster databases at startup" onchange="zenPage.doModified();"/>
</hgroup>

<hgroup label="New Volume Threshold Size"
  title="Enter zero to disable automatic creation of new volumes. If non-zero, when the IRIS.DAT would expand past this threshold, a new volume file called IRIS-0001.VOL will be created.  When expansion would grow that file past the threshold, IRIS-0002.VOL will be created, and so on. For non-zero values a minimum of 1 terabyte is recommended to avoid an excessive number of files.  Each database is limited to 200 volumes." >
<text id="VolThreshold" size="12" hint="" onchange="zenPage.changeVolThreshold(zenThis.getValue());"/>
  <radioSet id="idThresholdUnit" valueList="0,1,2" displayList="TB,GB,MB" originalValue="0" value="0" onchange="zenPage.doUnitSwitch();"/>
  <label id="VolThresholdMB" hidden="true" />
 </hgroup>

<!-- for special messages: -->
<group>
<label id="lblClusterMounted" label="This database is cluster mounted." labelStyle="font-weight:bold;" hidden="true"/>
<label id="lblMountedReadOnly" labelStyle="font-weight:bold;" hidden="true"/>
</group>

</group>
</form>
</pane>
}

///  if user unchecked Journal State, show warning
ClientMethod changeJournal(newVal) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	// only show warning for user DBs
	if (zenPage.NoJournalWarningDBs.indexOf(","+zenPage.DBName+",") == -1) {
		zen("lblJournalState").setHidden(newVal);
	}
	if (this.CanBeMirrored) {
		if(!zen('ReadOnly').getValue()) {
			if (newVal) {
				zen("linkAddMirror").setHidden(0); 
				zen("lblJournalRequired").setHidden(1);
			} else {
				zen("linkAddMirror").setHidden(1); 
				zen("lblJournalRequired").setHidden(0);
			}
		} else {
			if (newVal) {
				zen("lblBoth").setHidden(0);
				zen("lblReadOnly").setHidden(1);
			} else {
				zen("lblBoth").setHidden(1);
				zen("lblReadOnly").setHidden(0);
			}
		}
	}
}

ClientMethod changeMaxSize(newVal) [ Language = javascript ]
{
	var val = parseInt(newVal);
	
	if (!isNaN(val)) {
		var size = zen("Size").getValue();
		// if newVAl starts with + or -, treat it as an offset from the old value
		switch (newVal.charAt(0)) {
			case '+': 
			case '-':
				val = this.OldMaxSize + val;
		}
		
		// can't be less than zero. Max will be checked in validate()
		if (val < 0) {
			val = 0;
		}
		
		zen('MaxSize').setValue(val);
	}
	zenPage.doModified();
}

ClientMethod changeReadOnly(newVal) [ Language = javascript ]
{
	if (this.ReadOnly == 1 && newVal == 1) {
		this.disableCommandButton("btnSave");
	} else {
		this.enableCommandButton("btnSave");
	}
	if (this.CanBeMirrored && (this.ReadOnly == 0)) {
		if (zen('GlobalJournalState').getValue()) {
			if (newVal) {
				zen("linkAddMirror").setHidden(1);
				zen("lblReadOnly").setHidden(0);
			} else {
				zen("linkAddMirror").setHidden(0);
				zen("lblReadOnly").setHidden(1);
			}
		} else {
			if (newVal) {
				zen("lblBoth").setHidden(0);
				zen("lblJournalRequired").setHidden(1);
			} else {
				zen("lblBoth").setHidden(1);
				zen("lblJournalRequired").setHidden(0);
			}
		}
	}
}

///  Add db to mirror
ClientMethod doAddMirror() [ Language = javascript ]
{
	var url = "%CSP.UI.Portal.Dialog.DBMirrorAdd.zen?DBName="+encodeURIComponent(this.DBName)+"&MirDBName="+encodeURIComponent(this.MirName)+"&Dir="+encodeURIComponent(this.Directory)+"&Multi=0";
	zenLaunchPopupWindow(url,'AddMirror','resizable,width=600,height=700');
}

ClientMethod doSave() [ Language = javascript ]
{
	if (this.isButtonDisabled("btnSave")) return;
	var proxy = new zenProxy();
	proxy.OldDirectory = this.OldDirectory;
	proxy.OldName = this.DBName;
	proxy.OldSize = this.OldSize;

	proxy.Directory = this.Directory;
	proxy.Name = zen("Name").getValue();
	proxy.Size = parseInt(zen("Size").getValue());
	proxy.MaxSize = parseInt(zen("MaxSize").getValue());
	proxy.ExpansionSize = zen("ExpansionSize").getValue();
	proxy.NewVolumeThreshold = this.curVolThreshold;
	proxy.ResourceName = zen("ResourceName").getValue();
	proxy.NewGlobalIsKeep = zen("NewGlobalIsKeep").getValue();
	proxy.GlobalJournalState = zen("GlobalJournalState").getValue();
	proxy.NewGlobalCollation = zen("NewGlobalCollation").getValue();
	proxy.MountRequired = zen("MountRequired").getValue();
	proxy.ClusterMountMode = zen("ClusterMountMode").getValue();
	proxy.MountAtStartup = zen("MountAtStartup").getValue();
	proxy.ReadOnly = zen("ReadOnly").getValue();
	proxy.StreamLocation = zen("StreamLocation").getValue();
	proxy.IsEMSReadOnly = this.IsEMSReadOnly;
	
	var ok = this.validate(proxy);
	if (!ok) return;

	var result = this.SaveData(proxy);
	this.afterSave(result);
}

ClientMethod validate(proxy) [ Language = javascript ]
{
	this.resetMsg();
	var pass = true;
	
	// If database is readonly and user has not changed it then
	// we cannot save anything.
	if ((this.ReadOnly == 1) && (proxy.ReadOnly == 1)) {
		this.showMsg($$$Text("Database is readonly and save is not allowed."),true);
		return false;
	}
	
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	// check for a value in the name field
	if (!this.validateRequired(zen('Name'),pass,"S")) {
		this.afterValidate();
		zenSynchronousMode = oldSynchronousMode;
		return false;
	}
	
	// confirm the name change
	if (!this.validateName(proxy.Name,this.DBName)) {
		zen('Name').setValue(this.DBName);
		zen('Name').focus();
		return false;
	}

	if (!this.validateSize(proxy.Size,proxy.OldSize,proxy.Directory)) {
		zenSynchronousMode = oldSynchronousMode;
		return false;
	}
	
	// calclulate limits:
	var ngBlockLimit = 0xffffffff;
	var maxSizeLimit = this.getDBSizeLimit();
	var effectiveMax = (proxy.MaxSize==0? maxSizeLimit: proxy.MaxSize)
	
	if (!this.validateRequired(zen('Size'),pass,"N",true,1,effectiveMax)) pass = false;
	if (!this.validateRequired(zen('ExpansionSize'),pass,"N",true,0,maxSizeLimit)) pass = false;
	zen('VolThresholdMB').setValue(proxy.NewVolumeThreshold);
	if (!this.validateRequired(zen('VolThresholdMB'),pass,"N",true,0,maxSizeLimit)) pass = false;
	if (!this.validateRequired(zen('MaxSize'),pass,"N",true,(proxy.MaxSize==0? 0: proxy.Size), maxSizeLimit)) pass = false;

	if (!pass) {
		this.afterValidate();	
		
		// Show a different message if fields are too big	
		var msgProps = [];
		var msgLimits = [];
		
		if (proxy.Size > effectiveMax) {
			msgProps.push($$$Text("Current Size"));
			msgLimits.push($$$Text("Maximum Size"));
		}
		if (proxy.ExpansionSize > maxSizeLimit) {
			msgProps.push($$$Text("Expansion Size"));
			msgLimits.push(maxSizeLimit + ' MB');
		}
		if (proxy.NewVolumeThreshold > maxSizeLimit) {
			msgProps.push($$$Text("New Volume Threshold Size"));
			msgLimits.push(maxSizeLimit + ' MB');
		}
		if (proxy.MaxSize > maxSizeLimit) {
			msgProps.push($$$Text("Maximum Size"));
			msgLimits.push(maxSizeLimit + ' MB');
		}
		
		if (msgProps.length > 0) {
			var msg = this.ValidationErrorMsg + '\n';
			for (var i=0; i<msgProps.length; ++i) {
				msg += '\n' + $$$FormatText($$$Text("%1 cannot be greater than %2."),msgProps[i],msgLimits[i]);
			}
			
			this.showMsg(msg,1);
		}	
	}
	
	zenSynchronousMode = oldSynchronousMode;
	return pass;
}

/// Get the max size for the DB, based on the current block size.
ClientMethod getDBSizeLimit() [ Language = javascript ]
{
	var size;
	switch (parseInt(zen('BlockSize').getValue())) {
		case 4096: size = 16777080; break;
		case 8192: size = 33553904; break;
		case 16384: size = 67106832; break;
		case 32768: size = 134202016; break;
		case 65536: size = 268392960; break;
		default: size = -1; break;
	}
	
	return size;
}

ClientMethod updateDirectory(NewDirectory) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	// check if .dat exists in the new directory. Reject if not.
	if (this.DbExists(NewDirectory) == 0) {
		var msg = $$$Text("Newly selected directory does not contain IRIS.DAT. Please try again.");
		alert(NewDirectory + "\n" + msg);
		return;
	}
	zen("lblDirectory").setValue(NewDirectory);
	zen("txtDirectory").setValue(NewDirectory);
	zen("idNewDirectory").setHidden(true);
	if (NewDirectory != this.OldDirectory) {
		if (this.DBName == "IRISTEMP") {
			var iscachetempish = this.checkCACHETEMP(NewDirectory);
			if (iscachetempish == 0) {
				var a = $$$FormatText($$$Text("You have selected %1 to be your new IRISTEMP database directory. The existing database in that directory will be erased. Are you sure you want to do this?"),NewDirectory);
				if (confirm(a) == false) return;
			} else {
				var a = $$$Text("Are you sure you want to change the IRISTEMP database directory? A system restart is required.");
				if (confirm(a) == false) return;
			}
		}
		zen("idNewDirectory").setHidden(false);
		this.doModified();
	} 
	this.Directory = NewDirectory;
}

///  Set focus to the Name field.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// don't invokeSuper...we need to save some local values when EMS managed
	//this.invokeSuper('onloadHandler',arguments);
	if (this.MirrorSetName=="") zen("Name").focus();
	if (this.InvalidParam) {
		this.disableCommandButton("btnSave");
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set:$G(MirrorSetName)'="" ..HelpAddress = "Home,Configuration,Local Databases,Mirror Database Properties"

	Set dbOBJ = ##class(SYS.Database).%OpenId(..Directory)
	If '$IsObject(dbOBJ) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	Set ..ReadOnly = dbOBJ.ReadOnly
	Set ..ReadOnlyMounted = dbOBJ.ReadOnlyMounted
	Set ..ROReasonText = dbOBJ.ROReasonText

	#; Get StreamLocation, Mount, Cluster related values
	Set tSC = ##class(Config.Databases).Get(..DBName,.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If (..IsEMSReadOnly || (..ReadOnlyMounted && (tProperty '= "MountRequired"))) Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	i ((..DBName="IRISDATAMOVE")||(..DBName="IRISDATAMOVEMIRROR"))&&(dbOBJ.ResourceName=$$$DBIRISSYSResourceName) {
		Set ..%GetComponentById("ResourceName").disabled = 1
		Set ..%GetComponentById("ResourceButton").disabled = 1
	}
	If (..IsEMSReadOnly || ..ReadOnlyMounted) {
		Set ..%GetComponentById("Name").disabled = 1
		Set ..%GetComponentById("txtDirectory").disabled = 1
		Set ..%GetComponentById("imgDirectory").hidden = 1
		Set ..%GetComponentById("StreamButton").hidden = 1
	}

	Set cluster = 0
	If ##class(%SYS.ClusterInfo).NodeStatus()'["This system is not part of a cluster" {
		Set cluster = 1
	}
	Set ..%GetComponentById("idCluster").hidden = 'cluster
	
	Set (..%GetComponentById("Size").value,..OldSize) = dbOBJ.Size
	Set ..%GetComponentById("Size").hint = ">="_dbOBJ.Size
	Set (..%GetComponentById("MaxSize").value,..OldMaxSize) = dbOBJ.MaxSize
	Set ..%GetComponentById("BlockSize").value = $$$FormatText($$$Text("%1 Bytes"),dbOBJ.BlockSize)
	Set ..%GetComponentById("ExpansionSize").value = dbOBJ.ExpansionSize
	#;SML3048+ ;
	Set (..curVolThreshold,..origVolThreshold) = dbOBJ.NewVolumeThreshold
	If (..curVolThreshold >= (1024*1024)) {
		Set size=..curVolThreshold/1024/1024
		Set unit=0
	} elseif (..curVolThreshold >= 1024) {
		Set size=..curVolThreshold/1024
		Set unit=1
	} else {
		Set size=..curVolThreshold
		Set unit=2
	}
	Set ..%GetComponentById("VolThreshold").value = size
	Set ..%GetComponentById("idThresholdUnit").value = unit
	#;SML3048-
	Set ..%GetComponentById("ResourceName").value = ..LoadResources(dbOBJ.ResourceName)
	Set ..%GetComponentById("NewGlobalIsKeep").value = dbOBJ.NewGlobalIsKeep
	#; for Journal State, 2 means Yes 1 means No. For Zen's checkbox 1 means Yes 0 means No:
	Set ..%GetComponentById("GlobalJournalState").value = (##class(%Library.JournalState).LogicalToMenu(dbOBJ.GlobalJournalState) - 1)
	Set ..%GetComponentById("NewGlobalCollation").value = ..LoadCollations(dbOBJ.NewGlobalCollation,0)
	Set (..%GetComponentById("ClusterMountMode").value,ClusterMountMode) = dbOBJ.ClusterMountMode
	Set ..%GetComponentById("lblClusterMounted").hidden = 'dbOBJ.ClusterMounted
	Set ..%GetComponentById("ReadOnly").value = ..ReadOnly
	
	If ($SYSTEM.Mirror.IsPrimary() = 1) {
		Set ..MirName = ##class(Config.Mirrors).GetMirrorName()
		Set ..%GetComponentById("idMirror").hidden = 0
		#;JO2527+
		#; Do not show "Add to Mirror" link for cache system db
		If ##class(SYS.Database).CanDatabaseBeMirrored(..Directory) = 0 {
			Set ..%GetComponentById("linkAddMirror").hidden = 1
			Set ..CanBeMirrored = 0
		} Else {
			Set ..CanBeMirrored = 1
			Set ..%GetComponentById("linkAddMirror").caption = $$$FormatText($$$Text("Add to Mirror %1"),%page.MirName)
			Set (badJournal,badRO) = 0
			If dbOBJ.GlobalJournalState = 2 {
				Set badJournal = 1
			}
			If ..ReadOnlyMounted {
				Set badRO = 1
			}
			If (badJournal || badRO) {
				Set ..%GetComponentById("linkAddMirror").hidden = 1
				If (badJournal) {
					If (badRO) {
						Set ..%GetComponentById("lblBoth").hidden = 0
					} Else {
						Set ..%GetComponentById("lblJournalRequired").hidden = 0
					}
				} Else {
					Set ..%GetComponentById("lblReadOnly").hidden = 0
				}
			}
		}
		#;JO2527-
	}
	
	Set sys = ##class(Security.System).%OpenId("SYSTEM")
	Set DBEncStartMode = sys.DBEncStartMode
	Set Encrypted = dbOBJ.EncryptedDB
	Set ..%GetComponentById("Encrypted").value = $S(Encrypted=1:$$$TextHTML("Yes"),1:$$$TextHTML("No"))
	Set AllowEditCluster = (dbOBJ.NumberOfConfigDB < 2)
	#; show journal state warning if it's No for a db that's not one of these
	If ((dbOBJ.GlobalJournalState = 2) && (..NoJournalWarningDBs'[(","_..DBName_","))) {
		Set ..%GetComponentById("lblJournalState").hidden = 0
	}
	
	#;SML3048; Use SYS.Database.IsSystemDB method to check for system DB.
	If (##class(SYS.Database).IsSystemDB(..Directory)) {
		Set ..%GetComponentById("Name").hidden = 1
		Set ..%GetComponentById("NameLabel").hidden = 0
		Set ..%GetComponentById("MountRequired").readonlyNobox = 1
		#;SML3050+ : Don't allow editing NewVolumeThreshold for system DB.
		Set ..%GetComponentById("VolThreshold").disabled = 1
		Set ..%GetComponentById("idThresholdUnit").disabled = 1
		#;SML3050-
	} ElseIf (Encrypted && (DBEncStartMode=0)) {
		Set ..%GetComponentById("MountRequired").readonlyNobox = 1
	}
	
	If $zcvt(..Directory,"U")=$zcvt($zu(179,15),"U") Set ..%GetComponentById("GlobalJournalState").disabled=1
	
	If ('..ReadOnlyMounted && AllowEditCluster) Set ..%GetComponentById("ClusterMountMode").disabled = 0
	
	Set CacheSYS = $S(..DBName="IRISSYS":1,..DBName="IRISTEMP":1,..DBName="IRISLOCALDATA":1,..DBName="IRISAUDIT":1,..DBName="IRISMETRICS":1,1:0)
	If ('CacheSYS && ('..ReadOnlyMounted || ..ReadOnly)) Set ..%GetComponentById("ReadOnly").readonlyNobox = 0

	If ..ReadOnlyMounted {
		Set ..%GetComponentById("idSize").disabled = 1
		Set ..%GetComponentById("idResource").disabled = 1
		Set ..%GetComponentById("ResourceButton").hidden = 1
		Set ..%GetComponentById("GlobalJournalState").disabled = 1
		Set ..%GetComponentById("NewGlobalCollation").disabled = 1
		Set ..%GetComponentById("NewGlobalIsKeep").disabled = 1
		Set ..%GetComponentById("idCluster").disabled = 1
		Set ..%GetComponentById("lblMountedReadOnly").hidden = 0
		Set ..%GetComponentById("lblMountedReadOnly").label = $$$FormatText($$$Text("This database is mounted as read-only due to '%1'!"),..ROReasonText)
		#;SML3048+ : Don't allow editing NewVolumeThreshold for read-only DB.
		Set ..%GetComponentById("VolThreshold").disabled = 1
		Set ..%GetComponentById("idThresholdUnit").disabled = 1
		#;SML3048-
	}
	
	// hide "create resource" button if user doesn't have security privs or security is EMS managed
	;If ('$SYSTEM.Security.Check($$$AdminSecureResourceName,"USE") || 
	;	##class(%SYS.EMS).IsReadOnly("Security.Resources")) {
	;	Set ..%GetComponentById("ResourceButton").hidden = 1
	;}
	If ('$SYSTEM.Security.Check($$$AdminSecureResourceName,"USE")) {
		Set ..%GetComponentById("ResourceButton").hidden = 1
	}

	Set:ClusterMountMode ..%GetComponentById("lblClusterMounted").hidden = 0
	#;JO2527+
	Set ..%GetComponentById("lblJournalRequired").value = $$$TextHTML("  (Databases must be journaled to be mirrored)")
	#;JO2527-
	Set ..%GetComponentById("lblReadOnly").value = $$$TextHTML("  (Databases must be mounted read/write to be mirrored)")
	Set ..%GetComponentById("lblBoth").value = $$$TextHTML("  (Databases must be journaled and mounted read/write to be mirrored)")
	Quit $$$OK
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Local Databases","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?Dir="_..EscapeURL(..Directory)_"&DBName="_..EscapeURL(..DBName)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Database Properties")
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.Message (save successful, with warning message: require restart)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to Database list page.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set inTrans = 0
	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set tProxy.Message = ""

	Try {
		TSTART
		Set inTrans = 1
		
		If 'pProxy.IsEMSReadOnly {
			Set Properties("StreamLocation") = pProxy.StreamLocation
			Set tSC = ##class(Config.Databases).Modify(pProxy.OldName,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			Kill Properites
		}

		#; This is the new Directory if it is changed
		Set dbOBJ = ##class(SYS.Database).%OpenId(pProxy.Directory,,.tSC)
		If '$IsObject(dbOBJ) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set dbOBJ.MaxSize = pProxy.MaxSize
		Set dbOBJ.ExpansionSize = pProxy.ExpansionSize
		#;SML3048 ; setup NewVolumeThreshold peoperty.
		#;SML3121 ; Somehow the %Save() thought the NewVolumeThreshold property is modified even though they have the same value.
		#; So we need to check if the value is changed here.
		If dbOBJ.NewVolumeThreshold'=pProxy.NewVolumeThreshold Set dbOBJ.NewVolumeThreshold = pProxy.NewVolumeThreshold
		Set dbOBJ.ResourceName = pProxy.ResourceName
		Set dbOBJ.NewGlobalIsKeep = pProxy.NewGlobalIsKeep
		Set dbOBJ.GlobalJournalState = ##class(%Library.JournalState).MenuToLogical(pProxy.GlobalJournalState+1)
		Set dbOBJ.NewGlobalCollation = pProxy.NewGlobalCollation
		Set dbOBJ.ClusterMountMode = pProxy.ClusterMountMode
		Set dbOBJ.ReadOnly = pProxy.ReadOnly
		Set tSC = dbOBJ.%Save()
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tSC = ##class(Config.Databases).Get(pProxy.OldName,.tCurrProperties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		#; MountAtStartup is for Cluster Only (default is unchecked)
		#; MountRequired is for Cluster and Non-Cluster (default is unchecked)
		#; ClusterMountMode = "0" or "1" where "0" as default for Private, "1" means ClusterMountMode
		#;
		#; Figure out if Config needs to be modified
		#; Is Size Modified? If Yes, then Call SilentModWait
		#;                   If No and Config is modified then call ModifyDatabase myself
		#; If Size is modified, then ModifyDatabase or Rename, if needed, is done in SilentModWait.
		Set ConfigModified = ((pProxy.MountAtStartup '= tCurrProperties("MountAtStartup")) ||
							  (pProxy.ClusterMountMode '= tCurrProperties("ClusterMountMode")) ||
							  (pProxy.MountRequired '= tCurrProperties("MountRequired")) ||
							  (pProxy.Directory '= pProxy.OldDirectory))
		If (pProxy.Size > pProxy.OldSize) {
			Job ##class(SYS.Database).ModifyDatabase(pProxy.Directory,pProxy.Size)::10
			Set tParms("OldSize") = pProxy.OldSize
			Set tParms("NewSize") = pProxy.Size
			Set tParms("ConfigModified") = ConfigModified
			Set tParms("NewName") = pProxy.Name
			Set tParms("DBName") = pProxy.OldName
			If (pProxy.Directory'=pProxy.OldDirectory) {
				Set tParms("Directory") = pProxy.Directory
			}
			Set tParms("Server") = tCurrProperties("Server")
			Set tParms("MountAtStartup") = pProxy.MountAtStartup
			Set tParms("ClusterMountMode") = pProxy.ClusterMountMode
			Set tParms("MountRequired") = pProxy.MountRequired
			Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("ModifyDatabaseSize",$namespace,.tParms,,.tJob)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			If 'pProxy.IsEMSReadOnly {
				If ConfigModified {
					If pProxy.Directory '= pProxy.OldDirectory {
						Set Properties("Directory") = pProxy.Directory
					}
					Set Properties("ClusterMountMode") = pProxy.ClusterMountMode
					Set Properties("MountAtStartup") = pProxy.MountAtStartup
					Set Properties("MountRequired") = pProxy.MountRequired
					Set tSC = ##Class(Config.Databases).Modify(pProxy.OldName,.Properties)
					If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				}
				
				If ((pProxy.Name = "IRISTEMP") && (pProxy.Directory '= pProxy.OldDirectory)) {
					Set tProxy.Message = $$$Text("Changes have been saved but will require a restart of InterSystems IRIS to take effect.")
				}
				
				// If it has not errorred and if user changed database name, do it now.
				If (pProxy.Name '= pProxy.OldName) {
					Set tSC = ##class(Config.Databases).Rename(pProxy.OldName,pProxy.Name)
					If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				}
			}
		}
		TCOMMIT
		Set inTrans = 0
	} Catch Error {
		If ($g(inTrans,0) = 1) TROLLBACK 1
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClientMethod doResource() [ Language = javascript ]
{
	var url = this.ResourcePage + "RESOURCETYPE=" + cspEncodeUTF8(this.DBName);
	zenLaunchPopupWindow(url,'CreateResource','status,scrollbars,resizable,width=600,height=600');
}

///  This method is called from JavaScript if user is modifying IRISEMP and changed to a different directory<br>
///  We check here to see if the newly selected directory is a IRISTEMP type of database. Returns a number.
ClassMethod checkCACHETEMP(newdir As %String) As %Integer [ ZenMethod ]
{
	Set gfattrib = +$p($zu(49,newdir),",",17)
	Set iscachetempish = $ZBOOLEAN(gfattrib,$ZU(40,8,20),1)
	Quit iscachetempish
}

}
