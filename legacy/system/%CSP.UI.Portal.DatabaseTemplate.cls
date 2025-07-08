/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  Zen template for System Management Portal - Edit Database Properties
Class %CSP.UI.Portal.DatabaseTemplate Extends %CSP.UI.Portal.Template [ Abstract, Not SqlRowIdPrivate, System = 4 ]
{

///  Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter EMSSERVICE = "Namespace";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Databases.zen";

Parameter RECENT = 0;

///  Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property browseselect As %String;

Property DBName As %ZEN.Datatype.string(ZENURL = "DBName");

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property OldDirectory As %ZEN.Datatype.string(ZENURL = "Dir");

Property Directory As %ZEN.Datatype.string(ZENURL = "Dir");

Property MirName As %ZEN.Datatype.string;

Property OldSize As %ZEN.Datatype.integer;

Property ReadOnly As %ZEN.Datatype.boolean;

Property ReadOnlyMounted As %ZEN.Datatype.boolean;

Property ROReasonText As %ZEN.Datatype.string;

Property curVolThreshold As %ZEN.Datatype.integer;

Property origVolThreshold As %ZEN.Datatype.integer;

/// ID for edit.
Property PID As %String(ZENURL = "DBName");

XData Style
{
<style type="text/css">
.zenLabelDisabled {color:black;}
</style>
}

///  User clicked one of the Browse buttons.
///  Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	zenPage.browseselect = name;
	if (name == "Directory") {
		var Dir = this.Directory;
	} else {
		var Dir = zen(name).getValue();
	}
	var url = zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&showdirectoryonly=1');
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=680,height=750');
}

///  enable/disable MountAtStartup based on MountRequired value
ClientMethod changeMount(MountRequired) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	if (MountRequired == 0) MountRequired = false;
	if (zen("MountAtStartup")) {
		zen("MountAtStartup").setDisabled(MountRequired);
	}
	zenPage.doModified();
}

ClientMethod undoDirChange() [ Language = javascript ]
{
	this.Directory = this.OldDirectory;
	zen("lblDirectory").setValue(this.Directory);
	zen("txtDirectory").setValue(this.Directory);
	zen("idNewDirectory").setHidden(true);
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
	if (val && this.origVolThreshold == 0) {
		var res = this.MULTIVOLBackupCheck(this.Directory);
		if (!res) {
			alert($$$Text("WARNING: multi-volume databases cannot be backed up with IRIS Online Backup"));
		}
	}
	if (val && ((val * unit) < (1024 * 1024))) {
		a = $$$Text("For non-zero values a minimum of 1 terabyte is recommended to avoid an excessive number of files.  Each database is limited to 200 volumes.")+"\n\n"+$$$Text("Keep small new volume threshold size?");
		if (confirm(a) == false) {
			zen("VolThreshold").setValue(this.curVolThreshold/unit);
			zen("VolThreshold").focus();
			return;
		}
	}
	this.curVolThreshold = val * unit;
	zenPage.doModified();
}

ClientMethod doUnitSwitch() [ Language = javascript ]
{
	var val = this.curVolThreshold;
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

///  This client event, if present, is fired when the a popup page
///  launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	try {
		switch(popupName) {
			case "FileSelect":
				var field = zenPage.browseselect;
				if ((field == "StreamLocation") && (zen("StreamLocation"))) {
					zen("StreamLocation").setValue(value);
					zenPage.browseselect = "";
				} else {
					this.updateDirectory(value);
				}
				this.doModified();
				break;
			case "CreateResource":
				zen("ResourceName").setValue(zenPage.LoadResources(value));
				break;
			case "AddMirror":
				document.location = this.ParentURL;
				break;
			case "VolDirSelect":
				this.updateVolDirectory(value);
				break;
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod validateName(Name, OldName) [ Language = javascript ]
{
	var pass = true;
	if (zenTrim(Name) == "") {
		pass = false;
	} else if (Name != OldName) {
		var msg = $$$FormatText($$$Text("Are you sure you want to change the database name to %1?"),Name);
		if (!confirm(msg)) pass = false;
	}
	return pass;
}

ClientMethod validateSize(Size, OldSize, Directory) [ Language = javascript ]
{
	if (Size != OldSize) {
		if ((isNaN(Size)) || (Size < 1) || (Size < OldSize)) {
			this.showMsg($$$Text("Size is out of range. Minimum value is 1, and cannot be less than current size."),1);
			document.getElementById("Size").value = OldSize;
			document.getElementById("Size").focus();
			return false;
		}
		var result = this.GetFreeSpace(Directory);
		if (result) {
			if (result.ok != 1) {
				this.showMsg(result.ErrorMessage,true);
				return false;
			}
		} else {
			this.showMsg($$$Text("Unexpected error while validating size",true));
			return false;
		}
		if ((Size - OldSize) >= parseFloat(result.FreeSpace)) {
			var msg = $$$FormatText($$$Text("The requested size increase (%1 MB) may not be greater than total available disk space (%2 MB)."),Size-OldSize,result.FreeSpace);
			this.showMsg(msg,true);
			document.getElementById("Size").focus();
			return false;
		}
		if ((Size - OldSize) > (parseFloat(result.FreeSpace)*90/100)) {
			var msg = $$$FormatText($$$Text("Warning! The requested size increase (%1 MB) is greater than 90% of available disk space (%2 MB).\nAre you sure you want to expand the database to %3 MB?"),Size-OldSize,result.FreeSpace,Size);
			if (!confirm(msg)) {
				document.getElementById("Size").focus();
				return false;
			}
		}
	}
	return true;
}

ClassMethod DbExists(Dir) As %String [ ZenMethod ]
{
	Quit ##class(%CSP.UI.Portal.Dialog.DatabaseWizard).DbExists(Dir)
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

Method LoadCollations(NewGlobalCollation As %String, ReturnDisplayValue As %Boolean = 0) As %String
{
	Set (tDisplayList,tValueList) = ""
	Set LBLMSG(5) = $$$TextHTML("IRIS standard")
	Set LBLMSG(133) = $$$TextHTML("IRIS standard string")
	If ReturnDisplayValue {
		Quit $S($G(LBLMSG(NewGlobalCollation))'="":LBLMSG(NewGlobalCollation),1:NewGlobalCollation)
	}
	Set tRS = ##class(%ResultSet).%New("%Collate:CollationList")
	Do tRS.Execute(1)
	Set ListEmpty = 1
	While tRS.Next()  {
		If ('ListEmpty) {
			Set tDisplayList = tDisplayList_","
			Set tValueList = tValueList_","
		}
		Set tValue = tRS.Get("Number")
		Set tDisplayList = tDisplayList_$S($G(LBLMSG(tValue))'="":LBLMSG(tValue),1:tRS.GetData(1))
		Set tValueList = tValueList_tValue
		Set ListEmpty = 0
	}
	Set tCombo = ..%GetComponentById("NewGlobalCollation")
	Set tCombo.displayList = tDisplayList	
	Set tCombo.valueList = tValueList
	Quit NewGlobalCollation
}

Method LoadResources(ResourceName As %String) As %String [ ZenMethod ]
{
	Set (tDisplayList,tValueList) = ""
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	Do tRS.Execute(,,$$$DBResourceType)
	Set ResourceFound = 0
	Set ListEmpty = 1
	While tRS.Next() {
		Set tValue = tRS.GetData(1)
		If ('ListEmpty) {
			Set tDisplayList = tDisplayList_","
			Set tValueList = tValueList_","
		}
		Set tDisplayList = tDisplayList_..EscapeHTML(tValue)
		Set tValueList = tValueList_tValue
		If tValue = ResourceName Set ResourceFound = 1
		Set ListEmpty = 0
	}
	#;Add the resouce existing from the DB to the resource list even if it is no longer there
	If ResourceName '= "",ResourceFound = 0 {
		If ('ListEmpty) {
			Set tDisplayList = tDisplayList_","
			Set tValueList = tValueList_","
		}
		Set tDisplayList = tDisplayList_..EscapeHTML(ResourceName)
		Set tValueList = tValueList_ResourceName
	}
	Set tCombo = ..%GetComponentById("ResourceName")
	Set tCombo.displayList = tDisplayList	
	Set tCombo.valueList = tValueList
	Quit ResourceName
}

ClassMethod MULTIVOLBackupCheck(Dir As %String) As %Boolean [ ZenMethod ]
{
	Set dbOBJ = ##class(SYS.Database).%OpenId(Dir)
	Quit ''$$MULTIVOLBackupCheck^DATABASE(dbOBJ)
}

Query VolumeDirectories(Directory As %SysPath) As %Query(ROWSPEC = "VolumeDirectory:%SysPath,NumberOfVolumes:%String,Size:%Integer") [ SqlProc ]
{
}

ClassMethod VolumeDirectoriesExecute(ByRef qHandle As %Binary, Directory As %SysPath) As %Status [ Internal ]
{
	set Obj=##class(SYS.Database).%OpenId(Directory,,.status)
	if $$$ISERR(status) quit status
	set sc=Obj.VolumeFilesGetArray(.volfiles,Obj.Directory,.ex)
	s:$$$ISERR(sc) ex="e"
	Set Index=$i($$$ISCQUERYTEMP)
	f i=0:1:$listlength(Obj.VolumeDirectoryList) {
		i i { s vdir=$list(Obj.VolumeDirectoryList,i) }
		else { s vdir=Obj.Directory }
		i ex="" {
			s $listbuild(tmp,size,numvols)=volfiles("d",i)
		} else {
			s (size,numvols)="?"
		}
		Set $$$ISCQUERYTEMP(Index,i)=$ListBuild(vdir,numvols,size)
	}
	Set qHandle=Index_"^"
	Quit $$$OK
}

ClassMethod VolumeDirectoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PublicList = qHandle ]
{
 	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

ClassMethod VolumeDirectoriesClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

}
