/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.ScheduleView Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "EnsPortal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "View Schedule Spec";

/// Domain used for localization.
Parameter DOMAIN = "Ensemble";

/// User needs READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// If true, then this dialog displays an Apply button.
Parameter CANCELBUTTON As BOOLEAN = 0;

/// ID of schedule to display.
Property scheduleId As %String(ZENURL = "scheduleId");

/// Value of schedule string currently being edited.
Property scheduleString As %String(ZENURL = "schedule");

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup>
<spacer height="10"/>
<form>
<textarea id="FullString" label="Schedule String" cols="60" rows="6" readOnly="true" value="#(%page.scheduleString)#"
title="Internal representation of the schedule spec as a string"/>
</form>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Alternate View")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $zconvert(..scheduleId,"O","HTML")
}

ClientMethod changeSchedule() [ Language = javascript ]
{
	this.dialogFinish();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return null;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	return true;
}

}
