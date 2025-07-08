/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a theme to save DeepSee widget styles to.
Class %DeepSee.UI.Dialog.WidgetSaveToTheme Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Current theme.
Property theme As %ZEN.Datatype.string(ZENURL = "THEME");

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:8px;">
<html id="help"/>
<hgroup cellVAlign="top" label="New Theme" hint="Enter the name of a new theme" >
<radioButton id="rb1" name="choice" optionValue="new" onchange="zenPage.changeChoice();"/>
<text id="ctrlTheme" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>
<hgroup cellVAlign="top" label="Existing Theme" hint="Select an existing theme" >
<radioButton id="rb2" name="choice" optionValue="old" onchange="zenPage.changeChoice();"/>
<select id="ctrlThemeList"/>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save to Theme")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Save widget style to a theme")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var value = '';
	var which = zen('rb1').getValue();
	if (which == 'new') {
		value = zen('ctrlTheme').getValue().toString();
		// add .theme if not present
		var t = value.split('.');
		if (t[1]=='theme') {
			t.length = 2;
			value = t.join('.');
		}
		else {
			value = t[0] + '.theme';
		}
	}
	else {
		value = zen('ctrlThemeList').getValue();
	}
	return value;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	zen('help').setContent($$$Text('Themes let you share styles across multiple dashboards and widgets. Choose a theme below.'));
	this.changeChoice();

	var which = zen('rb1').getValue();
	if (which == 'new') {
		zen('ctrlTheme').focus();
	}
	else {
		zen('ctrlThemeList').focus();
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// Get list of themes
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetThemeList(.tThemes)
		If $$$ISERR(tSC) Quit

		Set tValueList = ""
		Set tDisplayList = ""
		Set a = $O(tThemes(""))
		While (a'="") {
			// JMD1201: clean up name
			Set tValue = $LG(tThemes(a),2)
			Set tName = $LG(tThemes(a),2)
			Set tName = $P(tName,".",1)
			// JMD1344 localize
			Set tName = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tName)
			If ($E(tName)'="$") {
				Set tValueList = tValueList_$S(tValueList="":"",1:",")_tValue
				Set tDisplayList = tDisplayList_$S(tDisplayList="":"",1:",")_tName
			}
			Set a = $O(tThemes(a))
		}
		Set tSelect = ..%GetComponentById("ctrlThemeList")
		Set tSelect.valueList = tValueList
		Set tSelect.displayList = tDisplayList
		Set tSelect.value = ""

		Set tText = ..%GetComponentById("ctrlTheme")

		Set tRB = ..%GetComponentById("rb1")

		If (..theme'="") {
			If ('##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..theme)) {
				Set tText.value = ..theme
				Set tRB.value = "new"
			}
			Else {
				Set tSelect.value = ..theme
				Set tRB.value = "old"
			}
		}
		Else {
			Set tRB.value = "new"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Change in radio button.
ClientMethod changeChoice() [ Language = javascript ]
{
	var which = zen('rb1').getValue();
	if (which == 'new') {
		zen('ctrlTheme').setDisabled(false);
		zen('ctrlThemeList').setDisabled(true);
	}
	else {
		zen('ctrlTheme').setDisabled(true);
		zen('ctrlThemeList').setDisabled(false);
	}
}

}
