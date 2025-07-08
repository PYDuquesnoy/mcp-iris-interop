/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee Link (folder item) definition.
Class %DeepSee.UI.Dialog.LinkSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// True if this is a "create new".
Property createNew As %ZEN.Datatype.boolean(ZENURL = "NEW");

/// True if this is a "save as".
Property saveAs As %ZEN.Datatype.boolean(ZENURL = "SAVEAS");

/// Link Name.
Property linkName As %ZEN.Datatype.string(ZENURL = "NAME");

/// Link title.
Property linkTitle As %ZEN.Datatype.string(ZENURL = "TITLE");

/// Link URL.
Property linkURL As %ZEN.Datatype.string(ZENURL = "URL");

/// Link owner.
Property linkOwner As %ZEN.Datatype.string(ZENURL = "OWNER");

/// Link resource.
Property linkResource As %ZEN.Datatype.string(ZENURL = "RESOURCE");

/// Description.
Property linkDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

/// Link public state.
Property linkPublic As %ZEN.Datatype.boolean(ZENURL = "PUBLIC") [ InitialExpression = 1 ];

/// Link keywords.
Property linkKeywords As %ZEN.Datatype.string(ZENURL = "WORDS");

/// Link category.
Property linkCategory As %ZEN.Datatype.string(ZENURL = "CATEGORY");

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="folder" label="Folder" size="50" hint="Name of folder to hold link." context="%DeepSee.Component.ContextSearch/Folders"/>
<text id="linkName" label="Link Name" hint="Identifying name of the link." size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<text id="linkTitle" label="Link Title" hint="Title to display for the link." size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<text id="linkURL" label="Link URL" hint="URL of the link" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

<hgroup cellVAlign="top">
<combobox id="linkOwner" label="Link Owner" size="30" editable="true" unrestricted="true"/>
<spacer width="10"/>
<combobox id="linkResource" label="Access Resource" hint="Name of resource used to grant access to this item." editable="true" unrestricted="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>

<hgroup cellVAlign="top">
<checkbox id="linkPublic" label="Public" hint="If true, this link is listed in the portal home page."/>
<spacer width="15"/>
</hgroup>

<hgroup cellVAlign="top">
<textarea id="linkDesc" label="Description" value="#(%page.linkDescription)#" rows="1" cols="40" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
<spacer width="5"/>
<textarea id="linkKeywords" label="Keywords" hint="Tags used to help find items. One keyword per line." rows="1" cols="20" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
</hgroup>

<text id="linkCategory" label="Category" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" value="#(%page.linkCategory)#"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..createNew:$$$TextHTML("Create Link"),1:$$$TextHTML("Save Link"))
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
		var info = new zenProxy();

		var folder = zenTrim(zen('folder').getValue());
		folder = folder.toString();

		var name = zenTrim(zen('linkName').getValue());
		name = name.toString();

		info.linkPublic = zen('linkPublic').getValue();
		info.linkURL = zen('linkURL').getValue();

		// test for valid name
		if ('' == name) {
			alert($$$Text('Please enter a link name.'));
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
		info.linkName = folder + ((folder=='')?'':'/') + name + '.link';
		info.linkTitle = zen('linkTitle').getValue();
		info.linkDescription = zen('linkDesc').getValue();
		info.linkOwner = zen('linkOwner').getValue();
		info.linkResource = zen('linkResource').getValue();
		info.linkCategory = zen('linkCategory').getValue();

		info.linkKeywords = zen('linkKeywords').getValue();
		var s = info.linkKeywords.split('\n');
		// IE may insert \r into strings--take it out!
		for (var n =0; n < s.length; n++) {
			s[n] = s[n].replace(/\r/,'');
		}
		info.linkKeywords = s.join(',');

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
			var duplicate = this.LinkExists(info.linkName);
			if (duplicate==2) {
				alert($$$Text('Link name is already in use; enter a new name.'));
				return false;
			}
			else if (duplicate && !confirm($$$Text('Link already exists, ok to replace?')+'\n'+info.linkName,false)) {
				return false;
			}
		}

		// save
		var msg = this.SaveLink(info);
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
		zen('linkName').focus();
		zen('linkName').select();
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
		Set tNameCtrl = ..%GetComponentById("linkName")
		Set tTitleCtrl = ..%GetComponentById("linkTitle")
		Set tKeywordsCtrl = ..%GetComponentById("linkKeywords")
		Set tPublicCtrl = ..%GetComponentById("linkPublic")
		Set tCategoryCtrl = ..%GetComponentById("linkCategory")
		Set tOwner = ..%GetComponentById("linkOwner")
		Set tResource = ..%GetComponentById("linkResource")
		Set tURLCtrl = ..%GetComponentById("linkURL")
		
		Set tURLCtrl.value = ..linkURL

		#; check if can modify owner/resource
		If ((..linkOwner="")||(..linkOwner=$UserName)||$System.Security.Check("%DeepSee_Admin","USE")) {
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

		Set tSC = ##class(%DeepSee.UserLibrary.Link).%ParseFullName(..linkName,.tFolderName,.tName,.tExt)
		If $$$ISERR(tSC) Quit

		Set tFolderCtrl.value = tFolderName
		If (..saveAs) {
			Set tNameCtrl.value = $$$FormatText($$$Text("Copy of %1"),tName)
		}
		ElseIf (..createNew) {
			Set tNameCtrl.value = $$$Text("New Link")
		}
		Else {
			Set tNameCtrl.value = tName
		}
		Set tTitleCtrl.value = ..linkTitle
		Set tPublicCtrl.value = ..linkPublic
		Set tResource.value = ..linkResource
		Set tOwner.value = ..linkOwner
		Set tCategoryCtrl.value = ..linkCategory
		Set tResource.valueList = ##class(%DeepSee.Utils).GetResourceList()
		
		If (..createNew && (tResource.value="")) {
			Set tResource.value = $G(^DeepSee.UserPortalSettings("DefaultResource"))
		}

		#; break up keywords into lines
		Set s = ""
		For n=1:1:$L(..linkKeywords,",") {
			Set s = s _ $P(..linkKeywords,",",n) _ $C(10)
		}
		Set tKeywordsCtrl.value = $E(s,1,$L(s)-1) // trim off last \n
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given link already exists.
ClassMethod LinkExists(pName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName)
}

/// Save the link.
ClassMethod SaveLink(pInfo As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// DP-411528 - Only attempt an open if the folderitem already exists
		Set tItem = $$$NULLOREF
		Set:..LinkExists(pInfo.linkName) tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pInfo.linkName,.tSC)
		If $$$ISERR(tSC) Quit
		
		If '$IsObject(tItem) {
			Set tItem = ##class(%DeepSee.UserLibrary.Link).%New()
			Set tItem.fullName = pInfo.linkName
		}

		Set tItem.href = pInfo.linkURL
		Set tItem.title = pInfo.linkTitle
		Set tItem.resource = pInfo.linkResource
		Set tItem.public = pInfo.linkPublic
		Set tItem.owner = pInfo.linkOwner
		Set tItem.description = pInfo.linkDescription
		Set tItem.keywords = pInfo.linkKeywords
		Set tItem.category = pInfo.linkCategory

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
