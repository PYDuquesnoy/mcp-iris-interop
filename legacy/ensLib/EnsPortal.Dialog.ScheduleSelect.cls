/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.ScheduleSelect Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:WRITE";

/// Class name of application this page belongs to.
Parameter APPLICATION = "EnsPortal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "New Schedule Spec";

/// Domain used for localization.
Parameter DOMAIN = "Ensemble";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup>
<spacer height="10"/>
<form>
<text id="ScheduleName" label="Name" />
<spacer height="10" />
<textarea id="ScheduleDesc" label="Description" cols="40" rows="2" hint="(Optional) Text description of the schedule spec"/>
<spacer height="10" />
<dataCombo id="CopyFrom" label="Copy From" queryClass="Ens.Util.Schedule" queryName="Extent" hint="(Optional) Existing schedule spec to copy into the new schedule spec" />
</form>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Create a New Schedule Spec")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('ScheduleName').getValue();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var name = zen("ScheduleName").getValue();
	if (name.length == 0) {
		alert($$$Text("Please supply a schedule name."));
		return false;
	}
	var desc = zen("ScheduleDesc").getValue();
	var copy = zen("CopyFrom").getValue();
	var ok = this.SaveData(name,desc,copy);
	if (ok != 1) {
		alert(ok);
		return false;
	} 
	return true;
}

ClassMethod SaveData(pName As %String, pDescription As %String, pCopyFrom As %String) As %String [ ZenMethod ]
{
	Set $ZT="Error"
	If ##class(Ens.Util.Schedule).%ExistsId(pName) = 0 {
		Set tSObj = ##class(Ens.Util.Schedule).%New()
		Set tSObj.Name = pName
	} Else  {
		Quit $$$TextJS("This schedule spec already exists!")
	}
	Set tSObj.Description = pDescription
	If (""'=pCopyFrom) {
		Set tSchedule = ##class(Ens.Util.Schedule).%OpenId(pCopyFrom)
		If tSchedule {
			Set tSObj.ScheduleSpec = tSchedule.ScheduleSpec
		}
	}
	Set tSC = tSObj.%Save()
	If $$$ISERR(tSC) Set tSC = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	Quit tSC
Error	///
	Set $ZT=""
	Quit "error"
}

}
