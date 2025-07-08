/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee worksheet.
Class %DeepSee.UI.Dialog.WorksheetSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Worksheet name.
Property worksheetName As %ZEN.Datatype.string(ZENURL = "WORKSHEET");

/// Worksheet description.
Property worksheetDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

/// Worksheet keywords.
Property worksheetKeywords As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "WORDS");

/// Worksheet owner.
Property worksheetOwner As %ZEN.Datatype.string(MAXLEN = 255, ZENURL = "OWNER");

/// Worksheet resource.
Property worksheetResource As %ZEN.Datatype.string(MAXLEN = 255, ZENURL = "RESOURCE");

/// Worksheet locked state.
Property worksheetLocked As %ZEN.Datatype.boolean(ZENURL = "LOCKED") [ InitialExpression = 0 ];

/// Worksheet public state.
Property worksheetPublic As %ZEN.Datatype.boolean(ZENURL = "PUBLIC") [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="folder" label="Folder" size="50" context="%DeepSee.Component.ContextSearch/Folders"/>
<text id="worksheetName" label="Worksheet Name" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

<hgroup cellVAlign="top">
<checkbox id="worksheetPublic" label="Public" hint="If true, this worksheet is listed in the portal home page."/>
<spacer width="5"/>
<checkbox id="worksheetLocked" label="Locked" hint="If set, then further changes to this item are not allowed without unlocking it."/>
<spacer width="25"/>
</hgroup>

<hgroup cellVAlign="top">
<combobox id="worksheetOwner" label="Worksheet Owner" size="30" editable="true" unrestricted="true"/>
<spacer width="10"/>
<combobox id="worksheetResource" label="Access Resource" hint="Name of resource used to grant access to this item." editable="true" unrestricted="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>

<textarea id="worksheetDesc" label="Description" value="#(%page.worksheetDescription)#" rows="4" cols="80" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
<textarea id="worksheetKeywords" label="Keywords" hint="Used to help find items. One keyword per line." rows="3" cols="20" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save Worksheet")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Save this worksheet definition.")
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
		var model = (main && main.zenPage && main.zenPage.getModel) ? main.zenPage.getModel() : null;

		var folder = zen('folder').getValue();
		var name = zen('worksheetName').getValue();
		var worksheetName = folder + (folder===''?'':'/') + name;
		if (model) {
			var worksheetDescription = zen('worksheetDesc').getValue();
			var worksheetLocked = zen('worksheetLocked').getValue();
			var worksheetPublic = zen('worksheetPublic').getValue();
			var worksheetResource = zen('worksheetResource').getValue();
			var worksheetOwner = zen('worksheetOwner').getValue();

			if (this.worksheetLocked && worksheetLocked) {
				alert($$$Text('This worksheet is locked and cannot be saved without first unlocking it.'));
				return false;
			}

			// test for valid name
			if ('/' == zenTrim(worksheetName) || '' === zenTrim(worksheetName)) {
				alert($$$Text('Please enter a worksheet name.'));
				return false;
			}

			// test for overwrite
			if (main.zenPage.worksheetName != worksheetName) {
				var duplicate = this.WorksheetExists(worksheetName);
				if (duplicate==2) {
					alert($$$Text('This worksheet name is already in use; enter a new name.'));
					return false;
				}
				else if (duplicate==1 && !confirm($$$Text('Worksheet already exists, ok to replace?')+ '\n'+worksheetName,false)) {
					return false;
				}
			}

			main.zenPage.worksheetName = worksheetName;

			model.name = name;
			model.folderName = folder;
			model.description = worksheetDescription;
			model.locked = worksheetLocked;
			model.public = worksheetPublic;
			model.resource = worksheetResource;
			model.owner = worksheetOwner;

			var worksheetKeywords = zen('worksheetKeywords').getValue();
			var s = worksheetKeywords.split('\n');
			// IE may insert \r into strings--take it out!
			for (var n =0; n < s.length; n++) {
				s[n] = s[n].replace(/\r/,'');
			}
			worksheetKeywords = s.join(',');
			model.keywords = worksheetKeywords;
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
		zen('worksheetName').focus();
		zen('worksheetName').select();
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
		Set tNameCtrl = ..%GetComponentById("worksheetName")
		Set tKeywordsCtrl = ..%GetComponentById("worksheetKeywords")
		Set tLockCtrl = ..%GetComponentById("worksheetLocked")
		Set tPublicCtrl = ..%GetComponentById("worksheetPublic")
		Set tResource = ..%GetComponentById("worksheetResource")
		Set tOwner = ..%GetComponentById("worksheetOwner")

		#; check if user can modify owner/resource
		If ((..worksheetOwner="")||(..worksheetOwner=$UserName)||$System.Security.Check("%DeepSee_Admin","USE")) {
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

		Set tSC = ##class(%DeepSee.UserLibrary.Worksheet).%ParseFullName(..worksheetName,.tFolderName,.tName,.tExt)
		If $$$ISERR(tSC) Quit

		Set tFolderCtrl.value = tFolderName
		Set tNameCtrl.value = tName
		Set tLockCtrl.value = ..worksheetLocked
		Set tPublicCtrl.value = ..worksheetPublic
		Set tResource.value = ..worksheetResource
		Set tOwner.value = ..worksheetOwner
		Set tResource.valueList = ##class(%DeepSee.Utils).GetResourceList()
		
		If ((tName="") && (tResource.value="")) {
			Set tResource.value = $G(^DeepSee.UserPortalSettings("DefaultResource"))
		}

		#; break up keywords into lines
		Set s = ""
		For n=1:1:$L(..worksheetKeywords,",") {
			Set s = s _ $P(..worksheetKeywords,",",n) _ $C(10)
		}
		Set tKeywordsCtrl.value = $E(s,1,$L(s)-1) // trim off last \n
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given worksheet already exists.
ClassMethod WorksheetExists(pName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName_".worksheet")
}

}
