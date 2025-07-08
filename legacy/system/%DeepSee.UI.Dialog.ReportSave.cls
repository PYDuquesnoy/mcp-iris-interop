/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee Report (folder item) definition.
/// This is not an actual report but a report to a previously defined report.
Class %DeepSee.UI.Dialog.ReportSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// True if this is a "create new".
Property createNew As %ZEN.Datatype.boolean(ZENURL = "NEW");

/// True if this is a "save as".
Property saveAs As %ZEN.Datatype.boolean(ZENURL = "SAVEAS");

/// Report Name.
Property reportName As %ZEN.Datatype.string(ZENURL = "NAME");

/// Report title.
Property reportTitle As %ZEN.Datatype.string(ZENURL = "TITLE");

/// Report class.
Property reportClass As %ZEN.Datatype.string(ZENURL = "REPORT");

/// Report (link) owner.
Property reportOwner As %ZEN.Datatype.string(ZENURL = "OWNER");

/// Report (link) resource.
Property reportResource As %ZEN.Datatype.string(ZENURL = "RESOURCE");

/// Description of this link.
Property reportDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

/// Report public state.
Property reportPublic As %ZEN.Datatype.boolean(ZENURL = "PUBLIC") [ InitialExpression = 1 ];

/// Report keywords.
Property reportKeywords As %ZEN.Datatype.string(ZENURL = "WORDS");

/// Report category.
Property reportCategory As %ZEN.Datatype.string(ZENURL = "CATEGORY");

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="folder" label="Folder" size="50" hint="Name of folder to hold report shortcut." context="%DeepSee.Component.ContextSearch/Folders"/>
<text id="reportName" label="Report Name" hint="Identifying name of the report shortcut." size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<text id="reportTitle" label="Report Title" hint="Title to display for the report." size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<selector id="reportClass" label="Report Class" hint="Name of the report" size="50" context="%ZEN.Portal.ContextSearch/Classes?hideAbstract=1&amp;super=%25ZEN.Report.reportPage"/>

<hgroup cellVAlign="top">
<combobox id="reportOwner" label="Report Owner" size="30" editable="true" unrestricted="true"/>
<spacer width="10"/>
<combobox id="reportResource" label="Access Resource" hint="Name of resource used to grant access to this item." editable="true" unrestricted="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>

<hgroup cellVAlign="top">
<checkbox id="reportPublic" label="Public" hint="If true, this report is listed in the portal home page."/>
<spacer width="15"/>
</hgroup>

<hgroup cellVAlign="top">
<textarea id="reportDesc" label="Description" value="#(%page.reportDescription)#" rows="1" cols="40" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
<spacer width="5"/>
<textarea id="reportKeywords" label="Keywords" hint="Tags used to help find items. One keyword per line." rows="1" cols="20" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
</hgroup>

<text id="reportCategory" label="Category" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" value="#(%page.reportCategory)#"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..createNew:$$$TextHTML("Create Report Shortcut"),1:$$$TextHTML("Save Report Shortcut"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $S(..createNew:$$$TextHTML("Create a new report shortcut."),..saveAs:$$$TextHTML("Save a copy of this report shortcut."),1:$$$TextHTML("Save this report shortcut."))
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
		var info = new zenProxy();

		var folder = zenTrim(zen('folder').getValue());
		folder = folder.toString();

		var name = zenTrim(zen('reportName').getValue());
		name = name.toString();

		info.reportPublic = zen('reportPublic').getValue();
		info.reportClass = zen('reportClass').getValue();

		// test for valid name
		if ('' == name) {
			alert($$$Text('Please enter a shortcut name.'));
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
		info.reportName = folder + ((folder=='')?'':'/') + name + '.report';
		info.reportTitle = zen('reportTitle').getValue();
		info.reportDescription = zen('reportDesc').getValue();
		info.reportOwner = zen('reportOwner').getValue();
		info.reportResource = zen('reportResource').getValue();
		info.reportCategory = zen('reportCategory').getValue();

		info.reportKeywords = zen('reportKeywords').getValue();
		var s = info.reportKeywords.split('\n');
		// IE may insert \r into strings--take it out!
		for (var n =0; n < s.length; n++) {
			s[n] = s[n].replace(/\r/,'');
		}
		info.reportKeywords = s.join(',');

		// JMD1202: test for folder access
		if (folder) {
			var canWrite = this.CanWriteToFolder(folder);
			if (!canWrite) {
				alert($$$Text('You do not have "WRITE" permission for this folder.'));
				return false;
			}
		}

		// test for overwrite
		if (this.createNew) {
			var duplicate = this.ReportExists(info.reportName);
			if (duplicate==2) {
				alert($$$Text('Report shortcut name is already in use; enter a new name.'));
				return false;
			}
			else if (duplicate && !confirm($$$Text('Report shortcut already exists, ok to replace?')+'\n'+info.reportName,false)) {
				return false;
			}
		}

		// save
		var msg = this.SaveReport(info);
		if (msg!='') {
			alert(msg);
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
		zen('reportName').focus();
		zen('reportName').select();
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
		Set tNameCtrl = ..%GetComponentById("reportName")
		Set tTitleCtrl = ..%GetComponentById("reportTitle")
		Set tClassCtrl = ..%GetComponentById("reportClass")
		Set tKeywordsCtrl = ..%GetComponentById("reportKeywords")
		Set tPublicCtrl = ..%GetComponentById("reportPublic")
		Set tCategoryCtrl = ..%GetComponentById("reportCategory")
		Set tOwner = ..%GetComponentById("reportOwner")
		Set tResource = ..%GetComponentById("reportResource")
		
		Set tClassCtrl.value = ..reportClass

		#; check if can modify owner/resource
		If ((..reportOwner="")||(..reportOwner=$UserName)||$System.Security.Check("%DeepSee_Admin","USE")) {
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

		Set tSC = ##class(%DeepSee.UserLibrary.Report).%ParseFullName(..reportName,.tFolderName,.tName,.tExt)
		If $$$ISERR(tSC) Quit

		Set tFolderCtrl.value = tFolderName
		If (..saveAs) {
			Set tNameCtrl.value = $$$FormatText($$$Text("Copy of %1"),tName)
		}
		ElseIf (..createNew) {
			Set tNameCtrl.value = $$$Text("New Report")
		}
		Else {
			Set tNameCtrl.value = tName
		}
		Set tTitleCtrl.value = ..reportTitle
		Set tPublicCtrl.value = ..reportPublic
		Set tResource.value = ..reportResource
		Set tOwner.value = ..reportOwner
		Set tCategoryCtrl.value = ..reportCategory
		Set tResource.valueList = ##class(%DeepSee.Utils).GetResourceList()
		
		If (..createNew && (tResource.value="")) {
			Set tResource.value = $G(^DeepSee.UserPortalSettings("DefaultResource"))
		}

		#; break up keywords into lines
		Set s = ""
		For n=1:1:$L(..reportKeywords,",") {
			Set s = s _ $P(..reportKeywords,",",n) _ $C(10)
		}
		Set tKeywordsCtrl.value = $E(s,1,$L(s)-1) // trim off last \n
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given report already exists.
ClassMethod ReportExists(pName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName)
}

/// Save the report.
ClassMethod SaveReport(pInfo As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// DP-411528 - Only attempt an open if the folderitem already exists
		Set tItem = $$$NULLOREF
		Set:..ReportExists(pInfo.reportName) tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pInfo.reportName,.tSC)
		If $$$ISERR(tSC) Quit
		
		If '$IsObject(tItem) {
			Set tItem = ##class(%DeepSee.UserLibrary.Report).%New()
			Set tItem.fullName = pInfo.reportName
		}

		Set tItem.title = pInfo.reportTitle
		Set tItem.resource = pInfo.reportResource
		Set tItem.public = pInfo.reportPublic
		Set tItem.owner = pInfo.reportOwner
		Set tItem.description = pInfo.reportDescription
		Set tItem.keywords = pInfo.reportKeywords
		Set tItem.category = pInfo.reportCategory
		Set tItem.reportClass = pInfo.reportClass

		Set tSC = tItem.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Test if the user can write to the given folder.
ClassMethod CanWriteToFolder(pFolderName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%CanWriteToFolder(pFolderName)
}

}
