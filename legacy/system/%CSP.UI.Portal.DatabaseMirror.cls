/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  Zen page for System Management Portal - Edit Mirror Database Properties
Class %CSP.UI.Portal.DatabaseMirror Extends %CSP.UI.Portal.DatabaseTemplate [ System = 4 ]
{

///  Displayed name of this page.
Parameter PAGENAME = "Mirror Database Properties";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.DatabaseMirror.zen";

Parameter HELPADDRESS = "Home,Configuration,Databases,Edit Mirror Database";

Property IsPrimary As %ZEN.Datatype.boolean [ InitialExpression = {$SYSTEM.Mirror.IsPrimary()} ];

Property FailoverDB As %ZEN.Datatype.boolean;

Property MirrorSetName As %ZEN.Datatype.string(ZENURL = "Mirror");

Property OldMaxSize As %ZEN.Datatype.integer;

XData Style
{
<style type="text/css">
tr.sizeRow td {
	padding:0 6px 3px 0;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;">
<hgroup>
<fieldSet labelPosition="left" label="General Properties" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<!-- Name -->
<text id="NameText" label="Name" size="44" maxlength="32" value="#(%page.DBName)#"
title="Database name consists of 1 to 32 characters." onchange="zenPage.doModified();" hint="Required."/>
<label id="NameLabel" label="Name" controlClass="normal" value="#(%page.DBName)#" hidden="true"/>
<!-- Mirror Name -->
<label id="MirrorName" label="Mirror Name" controlClass="normal" value="#(%page.MirName)#"/>
<!-- Directory -->
<hgroup id="idDirectory" label="Directory" labelPosition="left">
<label id="lblDirectory" value="#(%page.Directory)#" controlClass="normal"/>
<text id="txtDirectory" value="#(%page.Directory)#" size="44" hidden="true" onchange="zenPage.updateDirectory(zenThis.getValue());" hint="Required."/>
<image src="images/folderopen.gif" onclick="zenPage.browseSelect('Directory');"
title="Browse database directory"/>
</hgroup>
<hgroup id="idNewDirectory" hidden="true" >
<label value="Warning: You have changed the database directory!" controlClass="rednote"/>
<link id="linkUndo" href="#" caption="undo" onclick="zenPage.undoDirChange();return false;" enclosingClass="smpLink"/>
</hgroup>
<label id="DirectoryLabel" label="Directory" controlClass="normal" value="#(%page.Directory)#" hidden="true"/>
<!-- Encrypted -->
<label id="Encrypted" label="Encrypted" controlClass="normal"/>
<!-- Stream location -->
<hgroup id="idStreamLocation" labelPosition="left" label="Stream Location">
<text id="StreamLocation"  size="40" onchange="zenPage.doModified();"
title="Directory where the streams associated with this database. The default location is the subdirectory 'stream', underneath the database directory."/>
<button caption="Browse..." onclick="zenPage.browseSelect('StreamLocation');"
title="Browse stream location"/>
</hgroup>
</fieldSet>
<spacer width="5px"/>
<fieldSet labelPosition="left" label="Mirror Properties" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<!-- Resource Name -->
<select id="ResourceName" showEmpty="false" label="Resource Name" onchange="zenPage.doModified();"
title="The name of the database resource that governs access to the database"/>
<label id="ResourceLabel" label="Resource Name" controlClass="normal" hidden="true"/>
<!-- Block Size -->
<label id="BlockSize" label="Block Size" controlClass="normal"/>
<!-- Collation -->
<select id="NewGlobalCollation" label="Collation" showEmpty="false" onchange="zenPage.doModified();"/>
<label id="NewGlobalCollationLabel" label="Collation" controlClass="normal" hidden="true"/>
<!-- Preserve Global Attributes On Delete -->
<checkbox id="NewGlobalIsKeep" label="Preserve Global Attributes on Delete" controlClass="normal"
title="Preserves global directory entry and attributes when global is deleted" onchange="zenPage.doModified();"/>
<!-- Read Only -->
<checkbox id="ReadOnly" label="Always Mount Read-Only" readonlyNobox="true" controlClass="normal" onchange="zenPage.changeReadOnly(zenThis.getValue());zenPage.doModified();"
title="Specifies whether the database will be mounted read-only; if the database is currently mounted read-write, it will be dismounted and mounted read-only."/>
<!-- Mount Required -->
<checkbox id="MountRequired" label="Mount Required at Startup" onchange="zenPage.changeMount(zenThis.getValue());" controlClass="normal"
title="Specifies whether the database must be mounted when InterSystems IRIS starts up; if the database cannot be mounted, InterSystems IRIS will not start."/>
<!-- for cluster = 1: -->
<hgroup id="idCluster" label="Cluster" labelPosition="left" enclosingStyle="padding:4px;border:1px solid gray;" >
<!-- Mount Clustered -->
<checkbox id="ClusterMountMode" caption="Mount Clustered" captionClass="normal"
title="Database is configured to be mounted in cluster mode" onchange="zenPage.doModified();"/>
<spacer width="4px"/>
<!-- Mount Clustered At Startup -->
<checkbox id="MountAtStartup" caption="Mount Clustered at Startup" captionClass="normal"
title="Specifies whether to mount the cluster databases at startup" onchange="zenPage.doModified();"/>
</hgroup>

<!-- for special messages: -->
<group>
<label id="lblClusterMounted" label="This database is cluster mounted." labelStyle="font-weight:bold;" hidden="true"/>
<label id="lblMountedReadOnly" labelStyle="font-weight:bold;" hidden="true"/>
</group>
</fieldSet>
</hgroup>
<spacer height="5px"/>
<fieldSet label="Local Properties" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<html id="SizeTable" OnDrawContent="DrawSizes"/>
</fieldSet>
<fieldSet labelPosition="left" label="Multi-Volume Properties" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<hgroup label="New Volume Threshold Size"
  title="Enter zero to disable automatic creation of new volumes. If non-zero, when the IRIS.DAT would expand past this threshold, a new volume file called IRIS-0001.VOL will be created.  When expansion would grow that file past the threshold, IRIS-0002.VOL will be created, and so on. For non-zero values a minimum of 1 terabyte is recommended to avoid an excessive number of files.  Each database is limited to 200 volumes." >
<text id="VolThreshold" size="12" hint="" onchange="zenPage.changeVolThreshold(zenThis.getValue());"/>
  <radioSet id="idThresholdUnit" valueList="0,1,2" displayList="TB,GB,MB" originalValue="0" value="0" onchange="zenPage.doUnitSwitch();"/>
 </hgroup>
</fieldSet>
</group>
</form>
</pane>
}

///  Set focus to the Name field.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (this.IsPrimary) zen('NameText').focus();
	
	// don't invokeSuper...we need to save some local values when EMS managed
	//this.invokeSuper('onloadHandler',arguments);
	if (this.InvalidParam) {
		this.disableCommandButton("btnSave");
	}
}

ClientMethod changeReadOnly(newVal) [ Language = javascript ]
{
	if (this.ReadOnly == 1 && newVal == 1) {
		this.disableCommandButton("btnSave");
	} else {
		this.enableCommandButton("btnSave");
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	var proxy = new zenProxy();
	proxy.OldDirectory = this.OldDirectory;
	proxy.OldName = this.DBName;
	proxy.OldReadOnly = this.ReadOnly;
	proxy.OldSize = this.OldSize;
	proxy.FailoverDB = this.FailoverDB;
	proxy.IsPrimary = this.IsPrimary;

	proxy.Directory = this.Directory;
	proxy.Name = zen("NameText").getValue();
	proxy.Size = parseInt(document.getElementById("Size").value);
	proxy.MaxSize = document.getElementById("MaxSize").value;
	proxy.ExpansionSize = document.getElementById("ExpansionSize").value;
	proxy.ResourceName = zen("ResourceName").getValue();
	proxy.NewGlobalIsKeep = zen("NewGlobalIsKeep").getValue();
	proxy.NewGlobalCollation = zen("NewGlobalCollation").getValue();
	proxy.MountRequired = zen("MountRequired").getValue();
	proxy.ClusterMountMode = zen("ClusterMountMode").getValue();
	proxy.MountAtStartup = zen("MountAtStartup").getValue();
	proxy.ReadOnly = zen("ReadOnly").getValue();
	proxy.StreamLocation = zen("StreamLocation").getValue();
	proxy.NewVolumeThreshold = this.curVolThreshold;
	var ok = this.validate(proxy);
	if (!ok) return;

	var result = this.SaveData(proxy);
	zenPage.afterSave(result);
}

ClientMethod validate(proxy) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (this.IsPrimary && !this.validateRequired(zen('NameText'),pass,"S")) {
			pass = false;
			this.afterValidate();
		} else if (this.IsPrimary && !this.validateName(proxy.Name,this.DBName)) {
			zen('NameText').setValue(this.DBName);
			zen('NameText').focus();
			pass = false;
		} else if (!this.validateSize(parseInt(proxy.Size),this.OldSize,proxy.Directory)) {
			pass = false;
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

ClientMethod updateDirectory(NewDirectory) [ Language = javascript ]
{
	// check if .dat exists in the new directory. Reject if not.
	var ok = this.DbExists(NewDirectory);
	if (ok == 0) {
		var msg = $$$Text("Newly selected directory does not contain IRIS.DAT. Please try again.");
		alert(NewDirectory + "\n" + msg);
	} else {
		this.Directory = NewDirectory;
		zen("lblDirectory").setValue(NewDirectory);
		zen("idNewDirectory").setHidden(true);
		if (NewDirectory != this.OldDirectory) {
			zen("idNewDirectory").setHidden(false);
		} 
	}
}

///  if user entered MaxSize, need to make sure it is not less than 'Size'.
ClientMethod changeMaxSize(newVal) [ Language = javascript ]
{
	var val;
	var SizeSet = 0;
	if (this.IsEMSReadOnly) return;
	
	if (isNaN(Number(newVal))) {
		this.showMsg($$$FormatText($$$Text("'%1' is not a valid number."), newVal),1);
		document.getElementById("MaxSize").value = this.OldMaxSize;
		return;
	}
	var Msg = "";
	var Size = document.getElementById("Size").value;
	var FirstChar = newVal.charAt(0);
	if (FirstChar == "+") {
		newVal = newVal.slice(1);
		val = Number(newVal) + this.OldMaxSize;
	} else if (FirstChar == "-") {
		newVal = newVal.slice(1);
		val = this.OldMaxSize - Number(newVal);
		if (val < 0) {
			this.showMsg($$$FormatText($$$Text("The resulting value '%1' is a negative number."), val),1);
			document.getElementById("MaxSize").value = this.OldMaxSize;
			return;
		}
	} else {
		val = Number(newVal);
	}
	if (val != 0 && (this.OldMaxSize == 0 || val < this.OldMaxSize)) {
		Msg = $$$FormatText($$$Text("Entered 'Maximum' (%1 MB) is reduced from %2."), val, this.OldMaxSize==0? "Unlimited": this.OldMaxSize+" MB.");
	}
	if (val != 0 && val < Number(Size)) {
		Msg = $$$FormatText($$$Text("Entered 'Maximum' (%1 MB) is less than 'Current' (%2 MB). 'Maximum' is changed to %2 MB."), val, Size);
		document.getElementById("MaxSize").value = Size;
		SizeSet = 1;
	}
	if ((FirstChar == "+" || FirstChar == "-") && SizeSet == 0) {
		document.getElementById("MaxSize").value = val;
	}
	zenPage.doModified();
	if (Msg != "") {
		this.showMsg(Msg,0);
	}
}

///  if user entered Size, need to make sure it is not greater than 'MaxSize'.
ClientMethod changeSize(newVal) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	
	MaxSize = document.getElementById("MaxSize").value;
	if (MaxSize == 0 || Number(newVal) <= Number(MaxSize)) {
		zenPage.doModified();
		return;
	}
	this.showMsg($$$FormatText($$$Text("Entered 'Current' (%1 MB) is greater than 'Maximum' (%2 MB). 'Current' is changed to %2 MB."), newVal, MaxSize), 0);
	document.getElementById("Size").value = MaxSize;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$FormatText($$$Text("Edit Mirror Database Properties: %1"),$zconvert(..DBName,"O","HTML"))

	Set dbOBJ = ##class(SYS.Database).%OpenId(%page.Directory)
	If '$IsObject(dbOBJ) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	Set ..ReadOnly = dbOBJ.ReadOnly
	Set ..ReadOnlyMounted = dbOBJ.ReadOnlyMounted
	Set ..ROReasonText = dbOBJ.ROReasonText
	
	#; Get StreamLocation, Mount, Cluster related values
	Set tSC = ##class(Config.Databases).Get(%page.DBName,.Properties)
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
			If (..IsEMSReadOnly || (..ReadOnlyMounted && (tProperty '= "MountRequired") && (tProperty '= "StreamLocation"))) Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	Set cluster = ##class(%SYS.ClusterInfo).NodeStatus()
	Set cluster = $S(cluster["This system is not part of a cluster":"0",1:"1")
	Set ..%GetComponentById("idCluster").hidden = 'cluster
	
	Set ..FailoverDB = dbOBJ.MirrorFailoverDB
	Set ..MirName = $p($System.Mirror.DBGetInfo(0,dbOBJ.SFN),"^",2)
	Set ..OldSize = dbOBJ.Size
	Set ..OldMaxSize = dbOBJ.MaxSize
	#;SML3050+ ;Setup New Volume Threshold data
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
	#;SML3050-
	Set ..%GetComponentById("SizeTable").seed = dbOBJ.Size_"^"_dbOBJ.MaxSize_"^"_dbOBJ.ExpansionSize
	
	Set ..%GetComponentById("BlockSize").value = $$$FormatText($$$Text("%1 Bytes"),dbOBJ.BlockSize)
	Set (..%GetComponentById("ResourceName").value,..%GetComponentById("ResourceLabel").value) = ..LoadResources(dbOBJ.ResourceName)
	Set ..%GetComponentById("NewGlobalIsKeep").value = dbOBJ.NewGlobalIsKeep
	Set ..%GetComponentById("NewGlobalCollation").value = ..LoadCollations(dbOBJ.NewGlobalCollation,0)
	Set ..%GetComponentById("NewGlobalCollationLabel").value = ..LoadCollations(dbOBJ.NewGlobalCollation,1)
	Set (..%GetComponentById("ClusterMountMode").value,ClusterMountMode) = dbOBJ.ClusterMountMode
	Set ..%GetComponentById("lblClusterMounted").hidden = 'dbOBJ.ClusterMounted
	Set ..%GetComponentById("ReadOnly").value = ..ReadOnly

	Set sys = ##class(Security.System).%OpenId("SYSTEM")
	Set DBEncStartMode = sys.DBEncStartMode
	Set Encrypted = dbOBJ.EncryptedDB
	Set ..%GetComponentById("Encrypted").value = $S(Encrypted=1:$$$TextHTML("Yes"),1:$$$TextHTML("No"))
	Set AllowEditCluster = (dbOBJ.NumberOfConfigDB < 2)
	
	If (Encrypted && (DBEncStartMode=0)) {
		Set ..%GetComponentById("MountRequired").readonlyNobox = 1
	}
	
	If (('%page.IsPrimary) || ..ReadOnlyMounted) {
		Set ..%GetComponentById("NameText").hidden=1
		Set ..%GetComponentById("NameText").containerStyle="padding:0px;"
		Set ..%GetComponentById("NameLabel").hidden=0
		
		Set ..%GetComponentById("idDirectory").hidden=1
		Set ..%GetComponentById("idDirectory").containerStyle="padding:0px;"
		Set ..%GetComponentById("idNewDirectory").containerStyle="padding:0px;"
		Set ..%GetComponentById("DirectoryLabel").hidden=0
				
		Set ..%GetComponentById("NewGlobalCollation").hidden=1
		Set ..%GetComponentById("NewGlobalCollation").containerStyle="padding:0px;"
		Set ..%GetComponentById("NewGlobalCollationLabel").hidden=0
		
		Set ..%GetComponentById("NewGlobalIsKeep").readonlyNobox = 1
	} Else {
		Set ..%GetComponentById("NameLabel").containerStyle="padding:0px;"
		Set ..%GetComponentById("DirectoryLabel").containerStyle="padding:0px;"
		Set ..%GetComponentById("NewGlobalCollationLabel").containerStyle="padding:0px;"
	}
	#;JO2750
	If (('%page.IsPrimary && %page.FailoverDB) || ..ReadOnlyMounted || (dbOBJ.BlockSize=2048)){
		Set ..%GetComponentById("ResourceName").hidden=1
		Set ..%GetComponentById("ResourceName").containerStyle="padding:0px;"
		Set ..%GetComponentById("ResourceLabel").hidden=0
	} Else {
		Set ..%GetComponentById("ResourceLabel").containerStyle="padding:0px;"
	}
		
	If ('%page.IsPrimary || ..ReadOnlyMounted || 'AllowEditCluster) {
		Set ..%GetComponentById("ClusterMountMode").readonlyNobox = 1
	}
	
	If ('..ReadOnlyMounted || ..ReadOnly) {
		Set ..%GetComponentById("ReadOnly").readonlyNobox = 0
	}
	
	If ('%page.IsPrimary && %page.FailoverDB) {
		Set ..%GetComponentById("ReadOnly").readonlyNobox = 1
	}

	If ..ReadOnlyMounted {
		Set ..%GetComponentById("MountAtStartup").readonlyNobox = 1
		Set ..%GetComponentById("lblMountedReadOnly").hidden = 0
		Set ..%GetComponentById("lblMountedReadOnly").label = $$$FormatText($$$Text("This database is mounted as read-only due to '%1'!"),..ROReasonText)
		Set ..%GetComponentById("ResourceName").disabled = 1
		Set ..%GetComponentById("NewGlobalIsKeep").disabled = 1
		Set ..%GetComponentById("idCluster").disabled = 1
	}
	Set:ClusterMountMode ..%GetComponentById("lblClusterMounted").hidden = 0
	Quit $$$OK
}

Method DrawSizes(pSeed As %String) As %Status
{
	Do ..LoadOtherSizes(%page.MirName,.OtherSizes)
	
	Set Size = $P(pSeed,"^",1)
	Set MaxSize = $P(pSeed,"^",2)
	Set ExpansionSize = $P(pSeed,"^",3)
	
	Set ThisText = $$$TextHTML("This System")
	Set OtherText = $$$TextHTML("Other System")
	Set SizeText = $$$TextHTML("Size (MB)")
	Set SizeTitle = $$$TextHTML("Current database size in MB. May be enlarged to cause the database to start expanding to the new size.")
	Set MaxSizeText = $$$TextHTML("Maximum Size (MB)")
	Set MaxSizeTitle = $$$TextHTML("Maximum size in MB. Recommended to use 0 for unlimited size.")
	Set ExpansionSizeText = $$$TextHTML("Expansion Size (MB)")
	Set ExpansionSizeTitle = $$$TextHTML("Expansion size in MB. Recommended to use 0 for system defaults.")
	Set UnlimitedText = $$$TextHTML("(0 for Unlimited)")
	Set DefaultText = $$$TextHTML("(0 for Default)")
	
	&html<<table width="100%" cellspacing="3px">
			<tr>
				<td>&nbsp;</td>
				<td class="normal" style="text-decoration:underline;">#(ThisText)#</td>
				<td class="normal" style="text-decoration:underline;">#(OtherText)#</td>
			</tr>
			<tr class="sizeRow" title="#(SizeTitle)#">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(SizeText)#</td>
				<td class="normal" nowrap>
					<input id="Size" class="normal" type="text" size="5" value='#(Size)#' onchange="zenPage.changeSize(this.value);">
				</td>
				<td class="normal" nowrap valign="middle">
					#(OtherSizes(1))#
				</td>
			</tr>
			<tr class="sizeRow" title="#(ExpansionSizeTitle)#">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(ExpansionSizeText)#</td>
				<td class="normal" nowrap>
					<input id="ExpansionSize" class="normal" type="text" size="5" value='#(ExpansionSize)#' onchange="zenPage.doModified();">
					 #(DefaultText)#
				</td>
				<td class="normal" nowrap valign="middle">
					#(OtherSizes(3))#
				</td>
			</tr>
			<tr class="sizeRow" title="#(MaxSizeTitle)#">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(MaxSizeText)#</td>
				<td class="normal" nowrap valign="middle">
					<input id="MaxSize" class="normal" type="text" size="5" value='#(MaxSize)#' onchange="zenPage.changeMaxSize(this.value);">
					 #(UnlimitedText)#
				</td>
				<td class="normal" nowrap valign="middle">
					#(OtherSizes(2))#
				</td>
			</tr>
		</table>>
	
	Quit $$$OK
}

/// Sizes from Other System
Method LoadOtherSizes(Name As %String, OtherSizes As %String) As %String
{
	Set Return = ""
	Try {
		For n=1:1:3 {
			Set OtherSizes(n) = "n/a"
		}
		Set OtherList = ##class(SYS.MirrorConfiguration).GetDatabaseSizePropertiesFromOtherSystem(Name,.status)
		If OtherList '= "" {
			For n=1:1:3 {
				If $lg(OtherList,n)'="" {
					Set OtherSizes(n) = $lg(OtherList,n)
				}
			}
		}
	} catch Error {
		Set Status = Error.AsStatus()
		Set Return = $$$Text("Error loading other sizes: ")_..EscapeHTML($system.Status.GetErrorText(Status))
	}
	Quit Return
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
	Quit $$$Text("Mirror Database Properties")
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
		
		Set Properties("StreamLocation") = pProxy.StreamLocation
		Set tSC = ##class(Config.Databases).Modify(pProxy.OldName,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Kill Properites
		
		Set tSC = ##class(Config.Databases).Get(pProxy.OldName,.tCurrProperties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		#; This is the new Directory if it is changed
		Set dbOBJ = ##class(SYS.Database).%OpenId(pProxy.Directory,,.tSC)
		If '$IsObject(dbOBJ) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If 'pProxy.IsPrimary {
			If (pProxy.MountRequired '= tCurrProperties("MountRequired")) {
				Set Properties("MountRequired") = pProxy.MountRequired
				Set tSC = ##Class(Config.Databases).Modify(pProxy.OldName,.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				Kill Properties
			}

			#;JO2750: If the db isn't a failover db, check whether resource name shoudld be updated
			If (('pProxy.FailoverDB) && 
			        ((dbOBJ.ResourceName '= pProxy.ResourceName) || (pProxy.ReadOnly'=pProxy.OldReadOnly))) {
				Set dbOBJ.ReadOnly = pProxy.ReadOnly
				Set dbOBJ.ResourceName = pProxy.ResourceName
				Set tSC = dbOBJ.%Save()
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}

			#; check if size changed
			If ((+pProxy.Size '= dbOBJ.Size) || (+pProxy.MaxSize '= dbOBJ.MaxSize) || 
			          (+pProxy.ExpansionSize '= dbOBJ.ExpansionSize)) {
				Set tSC = ..SaveLocalProp(pProxy.Directory,pProxy.Size,pProxy.MaxSize,
				                                         pProxy.ExpansionSize,dbOBJ.BlockSize)
			    If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
			#;SML3050+ check if NewVolumeThreshold changed
			If (+pProxy.NewVolumeThreshold '= dbOBJ.NewVolumeThreshold) {
				Set tSC=$system.DB.ModifyMultiVol(pProxy.Directory,pProxy.NewVolumeThreshold*$$$megabyte\dbOBJ.BlockSize,dbOBJ.NewVolumeDirectory)
				If tSC<0 throw ##Class(%Exception.StatusException).CreateFromStatus($$$ERROR(-tSC))
			}
			#;SML3050-
		} Else { // IsPrimary
			Set dbOBJ.MaxSize = pProxy.MaxSize
			Set dbOBJ.ExpansionSize = pProxy.ExpansionSize
			Set dbOBJ.ResourceName = pProxy.ResourceName
			Set dbOBJ.NewGlobalIsKeep = pProxy.NewGlobalIsKeep
			Set dbOBJ.NewGlobalCollation = pProxy.NewGlobalCollation
			Set dbOBJ.ClusterMountMode = pProxy.ClusterMountMode
			#;SML3050
			Set dbOBJ.NewVolumeThreshold = pProxy.NewVolumeThreshold
			Set tSC = dbOBJ.%Save()
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

			If (tProxy.ReadOnly && ('dbOBJ.ReadOnly) && ('dbOBJ.InActiveMirror)) {
				#;This is a mirrored db which was read only and is now read-write
				#;and is not part of the active mirror.
				#;Tell the user to do this with the CHUI.
				Set Status = $$$ERROR($$$GeneralError,$$$Text("The database cannot be made read-write from the Management Portal. Please use the ^DATABASE utility instead."))
				throw ##Class(%Exception.StatusException).CreateFromStatus(Status)
			} Else {
				Set dbOBJ.ReadOnly = pProxy.ReadOnly
				Set tSC = dbOBJ.%Save()
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
			
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
				If (pProxy.Directory '= pProxy.OldDirectory) {
					Set tParms("Directory") = pProxy.Directory
				}
				Set tParms("Server") = tCurrProperties("Server")
				Set tParms("MountAtStartup") = pProxy.MountAtStartup
				Set tParms("ClusterMountMode") = pProxy.ClusterMountMode
				Set tParms("MountRequired") = pProxy.MountRequired

				Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("ModifyDatabaseSize",$namespace,.tParms,,.tJob)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			} Else {
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

				// If it has not errorred and if user changed database name, do it now.
				If (tProxy.ErrorMessage = "") && (pProxy.Name '= pProxy.OldName) {
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

ClassMethod SaveLocalProp(dirname As %String, cursize As %String, maxsize As %String, expsize As %String, blocksize As %String) As %Status
{
	#; expandby and maxsize are in blocks, cursize is in MB
	#; so convert expandby & maxsize
	try {
		Set Status = $$$OK
		Set expsize = (expsize*$$$megabyte)/blocksize
		Set maxsize = (maxsize*$$$megabyte)/blocksize
		Set rc = $SYSTEM.Mirror.DBModify(dirname,cursize,expsize,maxsize)
		If (rc < 0) throw ##Class(%Exception.StatusException).CreateFromStatus($$$ERROR(-rc))
	} catch Error {
		Set Status = ..EvalResult(Error.AsStatus())
		Set Status = $$$ERROR($$$GeneralError,$$$Text("Error saving local properties: ")_Status)
	}
	Quit Status
}

}
