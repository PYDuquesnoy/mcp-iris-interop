/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee Dashboard definition.
Class %DeepSee.UI.Dialog.DashboardSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// True if this is a "create new".
Property createNew As %ZEN.Datatype.boolean(ZENURL = "NEW");

/// True if this is a "save as".
Property saveAs As %ZEN.Datatype.boolean(ZENURL = "SAVEAS");

/// Pivot description.
Property dashboardDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

/// Pivot keywords.
Property dashboardKeywords As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "WORDS");

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Dashboard title.
Property dashboardTitle As %ZEN.Datatype.string(ZENURL = "TITLE");

/// Dashboard owner.
Property dashboardOwner As %ZEN.Datatype.string(ZENURL = "OWNER");

/// Dashboard resource.
Property dashboardResource As %ZEN.Datatype.string(ZENURL = "RESOURCE");

/// Dashboard category
Property dashboardCategory As %ZEN.Datatype.string(ZENURL = "CATEGORY");

/// Dashboard public state.
Property dashboardPublic As %ZEN.Datatype.boolean(ZENURL = "PUBLIC") [ InitialExpression = 1 ];

/// Dashboard snapTo.
Property dashboardSnapTo As %ZEN.Datatype.boolean(ZENURL = "SNAPTO") [ InitialExpression = 1 ];

/// Dashboard snapGrid.
Property dashboardSnapGrid As %ZEN.Datatype.boolean(ZENURL = "SNAPGRID") [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="folder" label="Folder" size="47" hint="Name of the folder to hold the dashboard." context="%DeepSee.Component.ContextSearch/Folders"/>
<text id="dashboardName" label="Dashboard Name" size="50" hint="Identifying name of the dashboard." onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<text id="dashboardTitle" label="Dashboard Title" size="50" hint="Title to display for the dashboard." onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

<combobox id="dashboardCategory" label="Category" size="47" hint="Category for the DeepSee User Portal covers view." editable="true" unrestricted="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<hgroup cellVAlign="top">
<combobox id="dashboardOwner" label="Dashboard Owner" size="30" editable="true" unrestricted="true"/>
<spacer width="15"/>
<combobox id="dashboardResource" label="Access Resource" hint="Name of resource used to grant access to this item." editable="true" unrestricted="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>
<checkbox id="dashboardPublic" label="Public" hint="If true, this dashboard is listed in the portal home page."/>

<textarea id="dashboardDesc" label="Description" value="#(%page.dashboardDescription)#" rows="4" cols="80" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
<textarea id="dashboardKeywords" label="Keywords" hint="Used to help find items. One keyword per line." rows="3" cols="20" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..createNew:$$$TextHTML("Create Dashboard"),1:$$$TextHTML("Save Dashboard"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $S(..createNew:$$$TextHTML("Create a new dashboard."),..saveAs:$$$TextHTML("Save a copy of this dashboard."),1:$$$TextHTML("Save this dashboard."))
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
		var main = this.getOpener ? this.getOpener() : window.opener;

		var folder = zenTrim(zen('folder').getValue());
		folder = folder.toString();

		var name = zenTrim(zen('dashboardName').getValue());
		name = name.toString();

		var dashboardPublic = zen('dashboardPublic').getValue();

		// test for valid name
		if ('' == name) {
			alert($$$Text('Please enter a dashboard name.'));
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
		
		var dashboardName = folder + ((folder=='')?'':'/') + name + '.dashboard';
		var dashboardTitle = zen('dashboardTitle').getValue();
		var dashboardDescription = zen('dashboardDesc').getValue();
		var dashboardOwner = zen('dashboardOwner').getValue();
		var dashboardResource = zen('dashboardResource').getValue();
		var dashboardCategory = zen('dashboardCategory').getValue();

		// test for overwrite
		if (this.createNew || (main.zenPage.dashboardName != dashboardName)) {
			var duplicate = this.DashboardExists(dashboardName);
			if (duplicate==2) {
				alert($$$Text('Dashboard name is already in use; enter a new name.'));
				return false;
			}
			else if (duplicate && !confirm($$$Text('Dashboard already exists, ok to replace?')+'\n'+dashboardName,false)) {
				return false;
			}
		}

		main.zenPage.dashboardName = dashboardName;
		main.zenPage.dashboardTitle = dashboardTitle;
		main.zenPage.dashboardDescription = dashboardDescription;
		main.zenPage.dashboardPublic = dashboardPublic;
		main.zenPage.dashboardOwner = dashboardOwner;
		main.zenPage.dashboardResource = dashboardResource;
		main.zenPage.dashboardCategory = dashboardCategory;	

		// +DTB102
		var dashboardKeywords = zen('dashboardKeywords').getValue();
		var s = dashboardKeywords.split('\n');
		// IE may insert \r into strings--take it out!
		for (var n =0; n < s.length; n++) {
			s[n] = s[n].replace(/\r/,'');
		}
		dashboardKeywords = s.join(',');
		main.zenPage.dashboardKeywords = dashboardKeywords;
		// -DTB102

		if (this.createNew) {
			// default to 10x10 snapGrid
			main.zenPage.dashboardSnapTo = true;
			main.zenPage.dashboardSnapGrid = true;
			main.zenPage.dashboardGridRows = 10;
			main.zenPage.dashboardGridCols = 10;
		}
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
		this.updateGridControls();
		zen('dashboardName').focus();
		zen('dashboardName').select();
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
		Set tNameCtrl = ..%GetComponentById("dashboardName")
		Set tTitleCtrl = ..%GetComponentById("dashboardTitle")
		Set tPublicCtrl = ..%GetComponentById("dashboardPublic")
		Set tOwner = ..%GetComponentById("dashboardOwner")
		Set tResource = ..%GetComponentById("dashboardResource")
		Set tResource.valueList = ##class(%DeepSee.Utils).GetResourceList()
		Set tKeywordsCtrl = ..%GetComponentById("dashboardKeywords")		
		Set tCategory = ..%GetComponentById("dashboardCategory")		
		
		// +DTB102
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetCategoryList(.tCategoryNames)
		If $$$ISERR(tSC) Quit
		
		Set tCategoryList = "" 
		Set n = $O(tCategoryNames("")) 
		While n'="" {
			Set tCategoryList = tCategoryList _ $S($L(tCategoryList):",",1:"") _ tCategoryNames(n)
			Set n = $O(tCategoryNames(n))
		}
		Set tCategory.valueList = tCategoryList
		// -DTB102

		#; check if can modify owner/resource
		If ((..dashboardOwner="")||(..dashboardOwner=$UserName)||$System.Security.Check("%DeepSee_Admin","USE")) {
			#; options for owner
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Set tOption.text = $UserName
			Set tOption.value = $UserName
			Do tOwner.options.Insert(tOption)
			Do %page.%AddComponent(tOption)
		}
		Else {
			Set tOwner.disabled = 1
			Set tResource.disabled = 1
		}

		Set tSC = ##class(%DeepSee.Dashboard.Definition).%ParseFullName(..dashboardName,.tFolderName,.tName,.tExt)
		If $$$ISERR(tSC) Quit
		
		// If createNew, throw out dashboard name; we only wanted to get the folder name from it
		If (..createNew) {
			Set ..dashboardName = ""
		}

		Set tFolderCtrl.value = tFolderName
		If (..saveAs && (tName'="")) {
			Set tNameCtrl.value = $$$FormatText($$$Text("Copy of %1"),tName)
		}
		ElseIf (..createNew || (tName="")) {
			Set tNameCtrl.value = $$$Text("New Dashboard")
		}
		Else {
			Set tNameCtrl.value = tName
		}
		Set tTitleCtrl.value = ..dashboardTitle
		Set tPublicCtrl.value = ..dashboardPublic
		Set tResource.value = ..dashboardResource
		Set tOwner.value = ..dashboardOwner
		Set tCategory.value = ..dashboardCategory	

		If (..createNew && (tResource.value="")) {
			Set tResource.value = $G(^DeepSee.UserPortalSettings("DefaultResource"))
		}
		
		// +DTB102
		#; break up keywords into lines
		Set s = ""
		For n=1:1:$L(..dashboardKeywords,",") {
			Set s = s _ $P(..dashboardKeywords,",",n) _ $C(10)
		}
		Set tKeywordsCtrl.value = $E(s,1,$L(s)-1) // trim off last \n
		// -DTB102
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given dashboard already exists.
ClassMethod DashboardExists(pName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName)
}

/// Test if the user can write to the given folder.
ClassMethod CanWriteToFolder(pFolderName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%CanWriteToFolder(pFolderName)
}

}
