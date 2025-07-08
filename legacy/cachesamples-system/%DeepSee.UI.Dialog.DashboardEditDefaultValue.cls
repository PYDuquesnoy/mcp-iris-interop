/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user edit a default value for a control within a Dashboard widget.
Class %DeepSee.UI.Dialog.DashboardEditDefaultValue Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Data source name.
Property dataSource As %ZEN.Datatype.string(ZENURL = "DATASOURCE");

/// Default value.
Property defaultValue As %ZEN.Datatype.string(ZENURL = "VALUE");

/// Display text to be presented to the user. This is primarily used
/// as a return value.
Property defaultText As %ZEN.Datatype.string(ZENURL = "TEXT");

/// Current filter name.
Property filterName As %ZEN.Datatype.string(ZENURL = "FILTER");

/// Current mode: filter or setting.
Property currMode As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">


<html id="overview" OnDrawContent="DrawOverview"/>

<hgroup cellVAlign="top" label="Select a filter value">
<radioButton name="type" id="rbFilter" optionValue="filter" onclick="zenPage.rbChanged();"/>
<deepsee:searchBox id="controlFilter" size="30" onchange="zenPage.rbChanged()"/>
</hgroup>
<spacer height="20"/>

<hgroup cellVAlign="top" label="Enter an MDX Key">
<radioButton name="type" id="rbKey" optionValue="key" onclick="zenPage.rbChanged();"/>
<selector id="controlKey" size="45" onchange="zenPage.rbChanged()"/>
</hgroup>
<spacer height="20"/>

<hgroup cellVAlign="top" label="Use a run-time variable">
<radioButton name="type" id="rbSetting" optionValue="setting" onclick="zenPage.rbChanged();"/>
<selector id="controlSetting" size="45" onchange="zenPage.rbChanged()"/>
</hgroup>
<spacer height="20"/>

</pane>
}

/// Draw overview content.
Method DrawOverview(pSeed As %String) As %Status
{
	Write $$$TextHTML("Provide a default value for the current control using one of the following options:"),!
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Default Value Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Edit the default value for a dashboard control.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	if (('filter'==this.currMode)||('key'==this.currMode)) {
		// DTB442 - Return an object so a name can be shown instead of an MDX key
		return {defaultValue:this.defaultValue,defaultText:this.defaultText};
	}
	else {
		return this.defaultValue;
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.defaultText = '';
		
		var controlFilter = zen('controlFilter');
		var controlKey = zen('controlKey');
		
		if ('filter'==this.currMode) {
			this.defaultValue = controlFilter.value;
			if ('day'==controlFilter.selectType) {
				this.defaultText = controlFilter.title;		// DTB442 - Display NOW if the select is a date
			}
			else {
				this.defaultText = controlFilter.text;		// DTB442 - Transmit the display text to the caller
			}
		}
		else if ('key'==this.currMode) {
			// DTB442 - New control for setting keys directly
			this.defaultValue = controlKey.value;
		}
		else {
			this.defaultValue = zen('controlSetting').getValue();
			if (''!=this.defaultValue && '@' != this.defaultValue.charAt(0)) {
				this.defaultValue = '@' + this.defaultValue;
			}
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
		// determine mode
		if (this.defaultValue.charAt(0)=='@') {
			this.currMode = 'setting';
			zen('controlSetting').setValue(this.defaultValue.substr(1));
		}
		else if ((this.defaultValue)&&!(this.defaultText)) {
			this.currMode = 'key';
			zen('controlFilter').setValue(this.defaultValue);
			zen('controlKey').setValue(this.defaultValue);
		}
		else {
			this.currMode = 'filter';
			zen('controlFilter').setValue(this.defaultValue);
			zen('controlKey').setValue(this.defaultValue);
		}
		
		zen('controlFilter').refreshContents();		// DTB442 - Make settings in the control consistent
		
		if ('filter'==this.currMode) {
			this.defaultValue = zen('controlFilter').getValue();
			this.defaultText = zen('controlFilter').text;		// DTB442
		}
		else {
			this.defaultValue = zen('controlSetting').getValue();
		}

		var rbFilter = zen('rbFilter');
		rbFilter.setValue(this.currMode);
		this.updateControls();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// User selected a radio button.
ClientMethod rbChanged() [ Language = javascript ]
{
	var rbFilter = zen('rbFilter');
	this.currMode = rbFilter.getValue();
	this.updateControls();
}

/// Update controls to match current state.
ClientMethod updateControls() [ Language = javascript ]
{
	var controlFilter = zen('controlFilter');
	var controlKey = zen('controlKey');
	var controlSetting = zen('controlSetting');
	
	if ('filter'==this.currMode) {
		controlFilter.setProperty('disabled',false);
		controlKey.setProperty('disabled',true);		// DTB442
		controlSetting.setProperty('disabled',true);
		
		controlKey.setValue(controlFilter.getValue());
		
		this.defaultValue = controlFilter.getValue();
		this.defaultText = controlFilter.text;
	}
	else if ('key'==this.currMode) {
		// DTB442 - Settings for new option
		controlFilter.setProperty('disabled',true);
		controlKey.setProperty('disabled',false);
		controlSetting.setProperty('disabled',true);
		
		controlFilter.setValue(controlKey.getValue());
		controlFilter.refreshContents();
		
		this.defaultValue = controlKey.getValue();
		this.defaultText = '';
	}
	else {
		controlFilter.setProperty('disabled',true);
		controlKey.setProperty('disabled',true);		// DTB442
		controlSetting.setProperty('disabled',false);
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ctrlFilter = ..%GetComponentById("controlFilter")
		Set ctrlSetting = ..%GetComponentById("controlSetting")
		
		// set search context for selectors
		Set ctrlSetting.context = "%DeepSee.Component.ContextSearch/UserSettings?context=DefaultFilterValue"
		
		// add options to filter combo
		If ((..dataSource'="")&&(..filterName'="")) {
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(..dataSource,..filterName,.tFilters)
			If $$$ISERR(tSC) Quit
			
			// +DTB442 - Filter selection is switched to a searchBox
			Set tDisplayList = ""
			Set tValueList = ""
			// DTB516 - Named filter fills in its own value list on load. Currently the serachbox cannot correctly parse
			// a multi-selected value so this is not supported as a default.
			If (..filterName="$NAMEDFILTER")||($E(..filterName,1,10)="$variable.") {		// DTB525 - Turn off multiSelect for pivot variables
				Set ctrlFilter.multiSelect = 0
			}
			Else {
				Set a = $O(tFilters(""))
				While (a'="") {
					Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $Replace($LG(tFilters(a),1),",","\,")
					Set tVal = $LG(tFilters(a),2)
					Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $Replace(tVal,",","\,")
					Set a = $O(tFilters(a))
				}
			
				Set:tDisplayList'="" tDisplayList = ","_tDisplayList
				Set:tValueList'="" tValueList = ","_tValueList
			}
			
			Set ctrlFilter.editable = 1
			Set ctrlFilter.dataSourceName = ..dataSource
			Set ctrlFilter.filterName = ..filterName
			Set ctrlFilter.readOnly = 0
			Set ctrlFilter.value = ..defaultValue
			Set ctrlFilter.valueList = tValueList
			Set ctrlFilter.displayList = tDisplayList
			// -DTB442
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
