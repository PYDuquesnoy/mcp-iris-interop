/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.DatabaseVolumes Extends %CSP.UI.Portal.DatabaseTemplate [ System = 4 ]
{

///  Displayed name of this page.
Parameter PAGENAME = "Multi-Volume Properties";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.DatabaseVolumes.zen";

Parameter HELPADDRESS = "Home,Configuration,Local Databases,Multi-Volume Properties";

Property currentVolDir As %ZEN.Datatype.string;

Property curVolSize As %ZEN.Datatype.integer;

Property SoftMinimum As %ZEN.Datatype.integer;

Property IsNotMounted As %ZEN.Datatype.integer;

Property IsRO As %ZEN.Datatype.integer;

Property LastVolumeSize As %ZEN.Datatype.integer;

Property LastVolumeDirectory As %ZEN.Datatype.string;

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
<form id="fld" readOnlyMessage="this is a readonly form!">
<label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;" controlStyle="white-space:pre-line;"/>
<group enclosingClass="EditForm" cellStyle="padding:5px;"  labelPosition="left" >
<hgroup id="idDirectory" label="Directory:" >
<label id="lblDirectory" value="#(%page.Directory)#" controlClass="normal"/>
<label id="lblMount" />
</hgroup>
<label id="lblNumVol" label="Number of Volumes:" controlClass="normal"/>
<label id="lblDBSize" label="Total Database Size:" controlClass="normal"/>
<hgroup label="New Volume Threshold Size"
  title="Enter zero to disable automatic creation of new volumes. If non-zero, when the IRIS.DAT would expand past this threshold, a new volume file called IRIS-0001.VOL will be created.  When expansion would grow that file past the threshold, IRIS-0002.VOL will be created, and so on. For non-zero values a minimum of 1 terabyte is recommended to avoid an excessive number of files.  Each database is limited to 200 volumes." >
<text id="VolThreshold" size="12" hint="" onchange="zenPage.changeVolThreshold(zenThis.getValue());"/>
  <radioSet id="idThresholdUnit" valueList="0,1,2" displayList="TB,GB,MB" originalValue="0" value="0" onchange="zenPage.doUnitSwitch();"/>
 </hgroup>
<hgroup id="idvoldir" label="Directory For New Volumes">
<text id="currentVolDir" size="40" onchange="zenPage.changeVolDir(zenThis.getValue());"/>
<button id="btnBrowse" caption="Browse..." onclick="zenPage.browseVolDir('VolDirSelect');"/>
</hgroup>
<label id="VolInfo1" hidden="true" controlStyle="font-style:italic;"/>
<label id="VolInfo2" hidden="true" controlStyle="font-style:italic;"/>
<label id="VolInfo3" hidden="true" controlStyle="font-style:italic;"/>
<hgroup id="VolList" label="Directories (primary plus volume directory list):" >
<tablePane id="table" cellSpacing="2"
queryName="VolumeDirectories"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="21"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="VolumeDirectory"
useSnapshot="true"
onselectrow="zenPage.doSelectRow();"
>
<column colName="VolumeDirectory" header="Directory"/>
<column colName="NumberOfVolumes" header="# Of Volumes"/>
<column colName="Size" header="Total Size" OnDrawCell="DrawSize"/>

<parameter value="#(%page.Directory)#"/>
 </tablePane>
 </hgroup>
 <label id="VolInfo4" hidden="true" controlStyle="font-style:italic;"/>
</group>
</form>
<spacer height="10" />
<label id="Text2" value="Database Volumes" containerStyle="padding-left:4px;padding-bottom:4px;"/>
<form id="fld2">
<group id="idVolumeFile" enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<hgroup label="Show Volume Files by:">
 <radioSet id="tableviewSwitch" valueList="0,1" displayList="Volume Number,Directory" originalValue="0" value="0" onchange="zenPage.doTableViewSwitch();"/>
 </hgroup>
<hgroup id="idVolumeFiles" label="Volume Files:" >
<tablePane id="tablebydir" hidden="true"
queryClass="SYS.Database"
queryName="VolumeFiles"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="221"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
useSnapshot="false"
>
<column colName="VolumeDirectory" header="Directory"/>
 <column colName="VolumeNumber" hidden="true"/>
<column colName="VolumeDirectoryTotalSize" header="Total Size" OnDrawCell="DrawSize"/>
 <column colName="File" header="File Name"/>
 <column colName="Size" header="File Size" OnDrawCell="DrawSize"/>
 <column colName="DiskFree" header="Disk Free Space" OnDrawCell="DrawSize"/>
<parameter value="#(%page.Directory)#"/>
<parameter value="1"/>
</tablePane>
<tablePane id="tablebyvol"
queryClass="SYS.Database"
queryName="VolumeFiles"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="201"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
useSnapshot="false"
>
 <column colName="VolumeNumber" header="Volume Number"/>
<column colName="VolumeDirectory" header="Directory"/>
 <column colName="VolumeDirectoryTotalSize" hidden="true"/>
 <column colName="File" header="File Name"/>
 <column colName="Size" header="File Size" OnDrawCell="DrawSize"/>
 <column colName="DiskFree" header="Disk Free Space" OnDrawCell="DrawSize"/>
<parameter value="#(%page.Directory)#"/>
<parameter value="0"/>
</tablePane>
 </hgroup>
 </group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	if (this.IsNotMounted || this.IsRO) {
		this.disableCommandButton("btnSave");
		this.disableCommandButton("btnSaveExpand");
	}
}

ClientMethod doSelectRow() [ Language = javascript ]
{
	var table = zen('table');
	var selectedIndex = table.getProperty("selectedIndex");
	if (selectedIndex == -1) {
		return;
	}
	var itemId = table.getValue();
	var rowData = table.getRowData(selectedIndex);
	if (!rowData) {
		return;
	}
	var directory = rowData["VolumeDirectory"];
	if (directory != '') {
		this.changeVolDir(directory);
	}
}

ClientMethod changeVolDir(newdir) [ Language = javascript ]
{
	var ndir = this.NormalizeDir(newdir);
	var res = this.CheckVolDir(this.Directory,ndir);
	if (res == -1) {
		alert($$$Text("The database already has the maximum number of volume directories.  You may only select a directory from the current volume directory list."));
		return;
	}
	if (res == 0) {
		var a = $$$FormatText($$$Text("The directory %1 does not exist, do you want to create it?"),newdir);
		if (confirm(a) == false) {
			zen("currentVolDir").setValue(this.currentVolDir);
			return;
		}
		if (this.CreateDirectory(ndir)) {
			alert($$$FormatText($$$Text("Failed to create '%1' directory, abort!"),newdir));
			zen("currentVolDir").setValue(this.currentVolDir);
			return;
		}
	}
	if (ndir !== this.LastVolumeDirectory) {
		alert($$$Text("The directory for new volumes is different than the directory containing the last volume.  A new volume will be created there when the last volume expands to the new volume threshold size.")+"\n\n"+$$$Text("If you want to prevent the last volume from expanding any further, you may create the new volume now by clicking 'Save and Expand Into New Volume'."));
	}
	zen("currentVolDir").setValue(ndir);
	this.currentVolDir = ndir;
}

ClientMethod browseVolDir(action) [ Language = javascript ]
{
	var url = zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(this.Directory)+'&showdirectoryonly=1');
	zenLaunchPopupWindow(url,action,'resizable,width=680,height=750');
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	try {
		switch(popupName) {
			case "VolDirSelect":
				this.changeVolDir(value);
				break;
			case "ExpandVolume":
				this.curVolSize = value;
				this.doSave();
				break;
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doTableViewSwitch() [ Language = javascript ]
{
	var viewswitch = parseInt(zen("tableviewSwitch").getValue());		
	if (viewswitch == 1) {
		zen("tablebydir").setHidden(false);
		zen("tablebyvol").setHidden(true);
	} else {
		zen("tablebydir").setHidden(true);
		zen("tablebyvol").setHidden(false);
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	if (this.isButtonDisabled("btnSave")) return;
	var proxy = new zenProxy();
	proxy.Directory = this.Directory;
	proxy.NewVolumeThreshold = this.curVolThreshold;
	proxy.NewVolumeDirectory = this.currentVolDir;
	// Save new volume directory or create new volume
	proxy.VolumeSize = this.curVolSize;
	var result = this.SaveData(proxy);
	this.afterSave(result);
}

ClientMethod doSaveExpand() [ Language = javascript ]
{
	if (this.isButtonDisabled("btnSaveExpand")) return;
	var res = this.MULTIVOLBackupCheck(this.Directory);
	if (!res) {
		alert($$$Text("WARNING: multi-volume databases cannot be backed up with IRIS Online Backup"));
	}
	if ((this.currentVolDir !== this.LastVolumeDirectory) &&
		!(this.curVolThreshold && (this.LastVolumeSize >= this.curVolThreshold))) {
		var text = $$$FormatText($$$Text("The last volume is %1 MB.  Since the new volume will be in the same storage device, allowing the last volumes to grow to at least 1 terabyte is recommended to avoid an excessive number of files. Each database is limited to 200 volumes.")+"\n\n"+$$$Text("Proceed, leaving the last volume at its current size?"),this.LastVolumeSize);
		if (confirm(text) == false) return;
	}
	var url = "%CSP.UI.Portal.Dialog.ExpandVolume.zen?Dir="+encodeURIComponent(this.Directory)+"&VolDir="+encodeURIComponent(this.currentVolDir)+"&VolThreshold="+this.curVolThreshold;
	zenLaunchPopupWindow(url,'ExpandVolume','resizable,width=600,height=700');
}

ClassMethod NormalizeDir(dir As %String) As %String [ ZenMethod ]
{
	Quit ##class(%File).NormalizeDirectory(dir)
}

ClassMethod CheckVolDir(dbdir, ndir As %String) As %Integer [ ZenMethod ]
{
	#;RJF557+
	Set Obj = ##class(SYS.Database).%OpenId(dbdir)
	If $isobject(Obj) && 'Obj.CheckVolumeDirectoryMax(ndir) Return -1
	#;RJF557-
	Quit $s($zu(12,ndir,3)'="":1,1:0)
}

ClassMethod CreateDirectory(dir As %String) As %Integer [ ZenMethod ]
{
	Quit '##Class(%Library.File).CreateDirectoryChain(dir)
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
	
	Set Obj = ##class(SYS.Database).%OpenId(..Directory,,.tSC)
	If $$$ISERR(tSC) Quit tSC
	Set ..%GetComponentById("table").queryClass = $classname()
	Set ..%GetComponentById("lblMount").value = $$$FormatText($$$Text(" is %1"),$s(Obj.Mounted:$$$Text("mounted"),1:$$$Text("not mounted")))
	Set ..%GetComponentById("lblNumVol").value = $$$FormatText($$$Text("%1 (%2 the IRIS.DAT)"),Obj.MultiVolume+1,$s(Obj.MultiVolume:$$$Text("including"),1:$$$Text("only")))
	Set ..%GetComponentById("lblDBSize").value = Obj.FormatSizes(Obj.Size)
	Set (..curVolThreshold,..origVolThreshold) = Obj.NewVolumeThreshold
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
	Set ..curVolSize = -1
	Set ..%GetComponentById("currentVolDir").value = Obj.NewVolumeDirectory
	Set ..currentVolDir = Obj.NewVolumeDirectory
	Set ..%GetComponentById("tablebydir").hidden = 1
	Set ..SoftMinimum = 1024*1024
	Set ..IsNotMounted = 'Obj.Mounted
	#;SML3050; Allow editing volume info for non-primary mirrored DB.
	Set ..IsRO = (Obj.ReadOnlyMounted || Obj.ReadOnly) && ($SYSTEM.Mirror.IsPrimary() || 'Obj.Mirrored)
	Set ..LastVolumeSize = Obj.LastVolumeSize
	Set ..LastVolumeDirectory = Obj.LastVolumeDirectory
	If Obj.Mounted&&('..IsRO) {
		i Obj.NewVolumeThreshold {
			if Obj.VolumeDirectoryList="" {
				Set text=$$$Text("New volumes are created in the same directory as the IRIS.DAT by default.")
				Set ..%GetComponentById("VolInfo1").value = text
				Set ..%GetComponentById("VolInfo1").hidden = 0
			} else {
				Set ..%GetComponentById("VolInfo3").hidden = 0
				Set ..%GetComponentById("VolInfo3").value = $$$Text("If space is available on a storage device that already contains volumes of this database, you may select one of the directores in list.")
			}
			Set text=$$$Text("If an additional storage device is needed for expansion, enter a directory on that device where further volumes will be created.")
		} else {
			Set text=$$$Text("If an additional storage device is needed for expansion, enter a directory on that device.")
		}
		Set ..%GetComponentById("VolInfo2").value = text
		Set ..%GetComponentById("VolInfo2").hidden = 0
		#; For saving new volume directory or create new volume.
	} else {
		Set ..%GetComponentById("VolThreshold").disabled = 1
		Set ..%GetComponentById("idThresholdUnit").disabled = 1
		Set ..%GetComponentById("currentVolDir").disabled = 1
		Set ..%GetComponentById("btnBrowse").disabled = 1
		Set ..%GetComponentById("table").onselectrow = ""
		i Obj.VolumeDirectoryList="" {
			Set ..%GetComponentById("idVolumeFile").hidden = 1
			Set ..%GetComponentById("Text2").hidden = 1
		} else {
			Set ..%GetComponentById("idVolumeFile").hidden = 0
			Set ..%GetComponentById("Text2").hidden = 0
		}
		if Obj.Mounted {
			Set text=$$$Text("There is no action to take until the the database is changed to Read-Write.")
		} else {
			if 'Obj.MultiVolume {
				Set text=$$$Text("There is no action to take until the the database is mounted.")
			} else {
				Set text=$$$Text("If you moved the volume files to a different set of directories, you must use ^DATABASE to update the volume directory list before the database can be mounted.")
			}
		}
		Set ..%GetComponentById("VolInfo4").value = text
		Set ..%GetComponentById("VolInfo4").hidden = 0
	}
	If Obj.VolumeDirectoryList="" Set ..%GetComponentById("VolList").hidden = 1
	Quit $$$OK
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	If ..IsEditForm = 0 Quit $$$OK
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")
	Set pCommands(3) = $LB("btnSaveExpand",$$$Text("Save and Expand Into New Volume"),$$$Text("Save changes and expand database to a new volume."),"zenPage.doSaveExpand();")

	Quit $$$OK
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Local Databases","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?Dir="_..EscapeURL(..Directory)))
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Multi-Volume Properties")
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
		Set Obj = ##class(SYS.Database).%OpenId(pProxy.Directory,,.tSC)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set oldThreshold = -1
		If (Obj.NewVolumeThreshold'=pProxy.NewVolumeThreshold) {
			s oldThreshold = Obj.NewVolumeThreshold
			s rc=$system.DB.ModifyMultiVol(pProxy.Directory,pProxy.NewVolumeThreshold*($$$megabyte\Obj.BlockSize))
			i rc<0 throw ##Class(%Exception.StatusException).CreateFromStatus($$$ERROR(-rc))
		}
		If (pProxy.VolumeSize '= -1) {
			s rc=##class(SYS.Database).NewVolume(pProxy.Directory,pProxy.NewVolumeDirectory,pProxy.VolumeSize)
			if $$$ISERR(rc) {
				if oldThreshold'=-1 s x=$system.DB.ModifyMultiVol(pProxy.Directory,oldThreshold*($$$megabyte\Obj.BlockSize))
				throw ##Class(%Exception.StatusException).CreateFromStatus(rc)
			}
		} elseif (Obj.NewVolumeDirectory'=pProxy.NewVolumeDirectory) {
			If (pProxy.NewVolumeDirectory'=Obj.Directory) {
				If '##Class(%File).DirectoryExists(pProxy.NewVolumeDirectory) {
					Set rc=##Class(%File).CreateDirectoryChain(pProxy.NewVolumeDirectory)
					if 'rc {
						if oldThreshold'=-1 s x=$system.DB.ModifyMultiVol(pProxy.Directory,oldThreshold*($$$megabyte\Obj.BlockSize))
						throw ##Class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$DirectoryCannotCreate,pProxy.NewVolumeDirectory))
					}
				}
				#; The directory might already be in the VolumeDirectoryList, but
				#; we could have mounted it without a dbdir file if it had no
				#; volumes and wasn't already the NewVolumeDirectory.  So we claim
				#; the directory unconditionally.
				Set rc=##class(SYS.Database).UseVolumeDirectory(Obj.Directory,pProxy.NewVolumeDirectory,2,'$listfind(Obj.VolumeDirectoryList,pProxy.NewVolumeDirectory))
				if $$$ISERR(rc) {
					if oldThreshold'=-1 s x=$system.DB.ModifyMultiVol(pProxy.Directory,oldThreshold*($$$megabyte\Obj.BlockSize))
					throw ##Class(%Exception.StatusException).CreateFromStatus(rc)
				}
			}
			s rc=$system.DB.ModifyMultiVol(pProxy.Directory,-1,pProxy.NewVolumeDirectory)
			i rc<0 {
				if oldThreshold'=-1 s x=$system.DB.ModifyMultiVol(pProxy.Directory,oldThreshold*($$$megabyte\Obj.BlockSize))
				throw ##Class(%Exception.StatusException).CreateFromStatus($$$ERROR(-rc))
			}
		}
	} Catch Error {
		If ($g(inTrans,0) = 1) TROLLBACK 1
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method DrawSize(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell in proper DB size.
	Set dbSizeLogicalToDisplay = ##class(SYS.Database).FormatSizes(%query(pName))
	&html<&nbsp;#(dbSizeLogicalToDisplay)#>
	Quit $$$OK
}

}
