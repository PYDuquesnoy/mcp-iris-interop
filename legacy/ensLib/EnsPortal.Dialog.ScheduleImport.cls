/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.ScheduleImport Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:WRITE";

/// Class name of application this page belongs to.
Parameter APPLICATION = "EnsPortal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Save a Schedule Spec";

/// Domain used for localization.
Parameter DOMAIN = "Ensemble";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Value of schedule string currently being edited.
Property scheduleString As %String(ZENURL = "scheduleString");

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup>
<spacer height="10"/>
<form>
<text id="ScheduleSpecName" label="Name"  />
<spacer height="10" />
<textarea id="txtDesc" label="Description" cols="40" rows="2" hint="(Optional) Text description of the schedule"/>
<spacer height="10" />
<textarea id="FullString" label="Raw String" cols="40" rows="6" readOnly="true" value="#(%page.scheduleString)#"
    hint="Read-only view of the string you are saving as a named schedule"/>
</form>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save a Schedule Spec")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("with a New Name")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('ScheduleSpecName').getValue();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var name = zen("ScheduleSpecName").getValue();
	if (name.length == 0) {
		alert($$$Text("Please supply a shedule name."));
		return false;
	}
	var desc = zen("txtDesc").getValue();
	var str = zen("FullString").getValue();
	if (str.length == 0) {
		alert($$$Text("Please supply a schedule string to save."));
		return false;
	}
	var ok = this.SaveData(name,desc,str);
	if (ok != 1) {
		alert(ok);
		return false;
	} 
	return true;
}

ClassMethod SaveData(pName As %String, pDescription As %String, pString As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set $ZT="Error"
	If ##class(Ens.Util.Schedule).%ExistsId(pName) = 0 {
		Set tSObj = ##class(Ens.Util.Schedule).%New()
		Set tSObj.Name = pName
	} 
	Else  {
		Quit $$$TextJS("This schedule name already exists!")
	}
	Set tSObj.Description = pDescription
	Set tSObj.ScheduleSpec = pString
	Set tSC = tSObj.%Save()
	If $$$ISERR(tSC) Set tSC = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	Quit tSC
Error	///
	Set $ZT=""
	Quit "error"
}

}
