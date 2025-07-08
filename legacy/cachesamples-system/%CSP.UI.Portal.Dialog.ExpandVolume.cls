/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Dialog.ExpandVolume Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.ExpandVolume.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Expand Database to a New Volume";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property Directory As %ZEN.Datatype.string(ZENURL = "Dir");

Property VolumeDirectory As %ZEN.Datatype.string(ZENURL = "VolDir");

Property VolThreshold As %ZEN.Datatype.integer(ZENURL = "VolThreshold");

Property curVolSize As %ZEN.Datatype.integer;

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<label id="text" controlStyle="font-style:italic;"/>
<spacer height="2"/>
<group cellStyle="padding:5px;"  labelPosition="left" >
<hgroup id="idVolSize" label="Initial Size of New Volume"
  title="The initial size of the new volume to be expanded, it's value can't be greather than the new volume threshold size." >
<text id="VolSize" size="12" hint="" onchange="zenPage.changeVolSize(zenThis.getValue());"/>
  <radioSet id="idVolSizeUnit" valueList="0,1,2" displayList="MB,GB,TB" originalValue="0" value="0" onchange="zenPage.doUnitSwitch();"/>
 </hgroup>
 </group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
    zen("VolSize").focus();
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Expand Database to a New Volume")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.curVolSize;
}

ClientMethod changeVolSize(newVal) [ Language = javascript ]
{
	var val = parseInt(newVal);
	var unit = parseInt(zen("idVolSizeUnit").getValue());
	switch (unit) {
		case 0: unit = 1; break;
		case 1: unit = 1024; break;
		case 2: unit = 1024 * 1024; break;
	}
	var val = zenTrim(newVal);
	if (val == '') {
		val = 0;
	} else {
		val = parseInt(val);
	}
	if ((isNaN(val)) || (val <= 0)) {
		var msg = $$$Text("Volume size of the new volume must be a positive number.");
		alert(msg);
		zen("VolSize").setValue(this.curVolSize/unit);
		zen("VolSize").focus();
		return;
	}
	if (val && this.VolThreshold && (val * unit) > this.VolThreshold) {
		a = $$$FormatText($$$Text("The initial size of the new volume cannot exceed the new volume threshold (currently %1 MB). "),this.VolThreshold);
		alert(a);
		zen("VolSize").setValue(this.curVolSize/unit);
		zen("VolSize").focus();
		return;
	}
	this.curVolSize = val * unit;
}

ClientMethod doUnitSwitch() [ Language = javascript ]
{
	var val = this.curVolSize;
	var unit = parseInt(zen("idVolSizeUnit").getValue());
	switch (unit) {
		case 0:
		zen("VolSize").setValue(val);
		break;
		case 1:
		zen("VolSize").setValue(val/1024);
		break;
		case 2:
		zen("VolSize").setValue(val/1024/1024);
		break;
	}
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
	
	if ..VolThreshold {
		Set ..%GetComponentById("text").label = $$$FormatText($$$Text("A new volume will be created in '%1', please enter the initial size of the new volume. It's value can't exceed the 'New Volume Threshold' %2 MB. A smaller size is recommended to reduce the expansion time."),..VolumeDirectory,..VolThreshold)
	} else {
		Set ..%GetComponentById("text").label = $$$FormatText($$$Text("A new volume will be created in '%1', please enter the initial size of the new volume. A smaller size is recommended to reduce the expansion time."),..VolumeDirectory)
	}
	Set ..curVolSize = 1
	Set ..%GetComponentById("VolSize").value = 1
	Set ..%GetComponentById("btnOK").caption = $$$Text("Expand")
	Quit $$$OK
}

}
