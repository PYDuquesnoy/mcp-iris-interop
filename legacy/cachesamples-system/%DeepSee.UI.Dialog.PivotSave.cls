/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee pivot definition.
Class %DeepSee.UI.Dialog.PivotSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Pivot name.
Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOT");

/// Pivot description.
Property pivotDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

/// Pivot keywords.
Property pivotKeywords As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "WORDS");

/// Pivot owner.
Property pivotOwner As %ZEN.Datatype.string(MAXLEN = 255, ZENURL = "OWNER");

/// Pivot resource.
Property pivotResource As %ZEN.Datatype.string(MAXLEN = 255, ZENURL = "RESOURCE");

/// Pivot locked state.
Property pivotLocked As %ZEN.Datatype.boolean(ZENURL = "LOCKED") [ InitialExpression = 0 ];

/// Pivot public state.
Property pivotPublic As %ZEN.Datatype.boolean(ZENURL = "PUBLIC") [ InitialExpression = 0 ];

/// Pivot category.
Property pivotCategory As %ZEN.Datatype.string(ZENURL = "CATEGORY");

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="folder" label="Folder" size="47" hint="Name of the folder to hold the pivot." context="%DeepSee.Component.ContextSearch/Folders"/>
<text id="pivotName" label="Pivot Name" size="50" hint="Identifying name of the pivot." onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<selector id="pivotCategory" label="Category" size="47" hint="Category for the DeepSee User Portal covers view." onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

<hgroup cellVAlign="top">
<selector id="pivotOwner" label="Pivot Owner" size="30"/>
<spacer width="15"/>
<selector id="pivotResource" label="Access Resource" hint="Name of resource used to grant access to this item." onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>

<hgroup cellVAlign="top">
<checkbox id="pivotPublic" label="Public" hint="If true, this pivot is listed in the portal home page."/>
<spacer width="10"/>
<checkbox id="pivotLocked" label="Locked" hint="If set, then further changes to this item are not allowed without unlocking it."/>
<spacer width="25"/>
</hgroup>

<textarea id="pivotDesc" label="Description" value="#(%page.pivotDescription)#" rows="4" cols="80" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
<textarea id="pivotKeywords" label="Keywords" hint="Used to help find items. One keyword per line." rows="3" cols="20" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>


</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save Pivot")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Save this pivot definition.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();

		var folder = zen('folder').getValue();
		var name = zen('pivotName').getValue();

		var pivotName = folder + (folder===''?'':'/') + name + (name===''?'':'.pivot');
		var pivotDescription = zen('pivotDesc').getValue();
		var pivotLocked = zen('pivotLocked').getValue();
		var pivotPublic = zen('pivotPublic').getValue();
		var pivotResource = zen('pivotResource').getValue();
		var pivotOwner = zen('pivotOwner').getValue();
		var pivotCategory = zen('pivotCategory').getValue();

		if ((this.pivotLocked && pivotLocked) && (this.pivotName == pivotName)) {
			// DP-432616 - If this table was loaded as locked, and is still marked as locked, prevent the save without further checks.
			alert($$$Text('This pivot is locked and cannot be saved without first unlocking it.'));
			return false;
		}

		// test for valid name
		if ('/' == zenTrim(pivotName) || '' === zenTrim(pivotName)) {
			alert($$$Text('Please enter a pivot name.'));
			return false;
		}

		if (name.indexOf('.')>-1 || name.indexOf('/')>-1) {
			alert($$$Text('Name cannot contain dots or slashes.'));
			return false;
		}
		if (folder.indexOf('.')>-1) {
			alert($$$Text('Folder name cannot contain a dot.'));
			return false;
		}
		if (name.indexOf('-')>-1) {
			alert($$$Text('Name cannot contain -'));
			return false;
		}
		if (folder.indexOf('-')>-1) {
			alert($$$Text('Folder name cannot contain -'));
			return false;
		}

		// JMD1202: test for folder access
		if (folder) {
			var canWrite = this.CanWriteToFolder(folder);
			if (!canWrite) {
				alert($$$Text('You do not have "WRITE" permission for this folder.'));
				return false;
			}
		}

		// test for overwrite
		if (main.zenPage.pivotName != pivotName) {
			var duplicate = this.PivotExists(pivotName);
			if (duplicate==2) {
				alert($$$Text('This pivot name is already in use; enter a new name.'));
				return false;
			}
			else if (duplicate==3) {
				// DP-432616 - Report pivot is locked
				alert($$$Text('Pivot already exists and is locked; enter a new name or save it unlocked to edit.'));
				return false;
			}
			else if (duplicate==1 && !confirm($$$Text('Pivot already exists, ok to replace?')+ '\n'+pivotName,false)) {
				return false;
			}
		}

		main.zenPage.pivotName = pivotName;
		main.zenPage.pivotDescription = pivotDescription;
		main.zenPage.pivotLocked = pivotLocked;
		main.zenPage.pivotPublic = pivotPublic;
		main.zenPage.pivotResource = pivotResource;
		main.zenPage.pivotOwner = pivotOwner;
		main.zenPage.pivotCategory = pivotCategory;

		var pivotKeywords = zen('pivotKeywords').getValue();
		var s = pivotKeywords.split('\n');
		// IE may insert \r into strings--take it out!
		for (var n =0; n < s.length; n++) {
			s[n] = s[n].replace(/\r/,'');
		}
		pivotKeywords = s.join(',');
		main.zenPage.pivotKeywords = pivotKeywords;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		zen('pivotName').focus();
		zen('pivotName').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// pull apart folder name
		Set tFolderCtrl = ..%GetComponentById("folder")
		Set tNameCtrl = ..%GetComponentById("pivotName")
		Set tKeywordsCtrl = ..%GetComponentById("pivotKeywords")
		Set tLockCtrl = ..%GetComponentById("pivotLocked")
		Set tPublicCtrl = ..%GetComponentById("pivotPublic")
		Set tResource = ..%GetComponentById("pivotResource")
		Set tOwner = ..%GetComponentById("pivotOwner")
		Set tCategoryCtrl = ..%GetComponentById("pivotCategory")

		// DTB446 - Set context for selector components
		Set tCategoryCtrl.context = "%DeepSee.Component.ContextSearch/Categories"
		Set tResource.context = "%DeepSee.Component.ContextSearch/Resources"
		Set tOwner.context = "%DeepSee.Component.ContextSearch/Users?context=CurrentUser"

		#; check if user can modify owner/resource
		If '((..pivotOwner="")||(..pivotOwner=$UserName)||$System.Security.Check("%DeepSee_Admin","USE")) {
			Set tOwner.disabled = 1
			Set tResource.disabled = 1
		}

		Set tSC = ##class(%DeepSee.Dashboard.Pivot).%ParseFullName(..pivotName,.tFolderName,.tName,.tExt)
		If $$$ISERR(tSC) Quit

		Set tFolderCtrl.value = tFolderName
		Set tNameCtrl.value = tName
		Set tLockCtrl.value = ..pivotLocked
		Set tPublicCtrl.value = ..pivotPublic
		Set tResource.value = ..pivotResource
		Set tOwner.value = ..pivotOwner
		Set tCategoryCtrl.value = ..pivotCategory

		If ((tName="") && (tResource.value="")) {
			Set tResource.value = $G(^DeepSee.UserPortalSettings("DefaultResource"))
		}

		#; break up keywords into lines
		Set s = ""
		For n=1:1:$L(..pivotKeywords,",") {
			Set s = s _ $P(..pivotKeywords,",",n) _ $C(10)
		}
		Set tKeywordsCtrl.value = $E(s,1,$L(s)-1) // trim off last \n
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given pivot already exists.
ClassMethod PivotExists(pName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName)
}

/// Test if the user can write to the given folder.
ClassMethod CanWriteToFolder(pFolderName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%CanWriteToFolder(pFolderName)
}

}
