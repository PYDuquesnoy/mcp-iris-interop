/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee widget definition to the widget catalog.
Class %DeepSee.UI.Dialog.WidgetSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Name.
Property widgetName As %ZEN.Datatype.string(ZENURL = "PIVOT");

/// Description.
Property widgetDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

/// Keywords.
Property widgetKeywords As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "WORDS");

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
<text id="widgetName" label="Widget Name" size="50"/>
<textarea id="widgetDesc" label="Description" value="#(%page.widgetDescription)#" rows="4" cols="80"/>
<textarea id="widgetKeywords" label="Keywords" hint="Used to help find items. One keyword per line." rows="3" cols="20"/>

<hgroup cellVAlign="top">
<combobox id="widgetOwner" label="Widget Owner" size="30" editable="true" unrestricted="true"/>
<spacer width="10"/>
<text id="widgetResource" label="Access Resource" hint="Name of resource used to grant access to this item."/>
</hgroup>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save Widget")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Save this widget to the catalog")
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
		var name = zen('widgetName').getValue();

		var widgetName = folder + (folder===''?'':'/') + name;
		var widgetDescription = zen('widgetDesc').getValue();
		var widgetResource = zen('widgetResource').getValue();
		var widgetOwner = zen('widgetOwner').getValue();

		// test for valid name
		if ('/' == zenTrim(widgetName) || '' === zenTrim(widgetName)) {
			alert($$$Text('Please enter a widget name.'));
			return false;
		}

		// test for overwrite
		if (main.zenPage.widgetTemplate != widgetName) {
			var duplicate = this.WidgetExists(widgetName);
			if (duplicate && !confirm($$$Text('Widget already exists, ok to replace?')+'\n'+widgetName,false)) {
				return false;
			}
		}

		main.zenPage.widgetTemplateName = widgetName;
		main.zenPage.widgetDescription = widgetDescription;
		main.zenPage.widgetResource = widgetResource;
		main.zenPage.widgetOwner = widgetOwner;

		var widgetKeywords = zen('widgetKeywords').getValue();
		var s = widgetKeywords.split('\n');
		// IE may insert \r into strings--take it out!
		for (var n =0; n < s.length; n++) {
			s[n] = s[n].replace(/\r/,'');
		}
		widgetKeywords = s.join(',');
		main.zenPage.widgetKeywords = widgetKeywords;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// pull apart folder name
		Set tFolderCtrl = ..%GetComponentById("folder")
		Set tNameCtrl = ..%GetComponentById("widgetName")
		Set tKeywordsCtrl = ..%GetComponentById("widgetKeywords")
		Set tResource = ..%GetComponentById("widgetResource")
		Set tOwner = ..%GetComponentById("widgetOwner")

		#; check if can modify owner/resource
		#; options for owner
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Set tOption.text = $UserName
		Set tOption.value = $UserName
		Do tOwner.options.Insert(tOption)
		Do %page.%AddComponent(tOption)

		Set tSC = ##class(%DeepSee.Dashboard.WidgetTemplate).%ParseFullName(..widgetName,.tFolderName,.tName,.tExt)
		If $$$ISERR(tSC) Quit

		Set tFolderCtrl.value = tFolderName
		Set tNameCtrl.value = tName

		#; break up keywords into lines
		Set s = ""
		For n=1:1:$L(..widgetKeywords,",") {
			Set s = s _ $P(..widgetKeywords,",",n) _ $C(10)
		}
		Set tKeywordsCtrl.value = $E(s,1,$L(s)-1) // trim off last \n
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given widget already exists.
ClassMethod WidgetExists(pName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName)
}

}
