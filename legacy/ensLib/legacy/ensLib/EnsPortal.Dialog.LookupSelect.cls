/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to let user specify a new Lookup Table name.
Class EnsPortal.Dialog.LookupSelect Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "New Lookup Table";

/// User needs WRITE permissions on the %Ens_LookupTables resource to access this page.
Parameter RESOURCE = "%Ens_LookupTables:WRITE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup>
<spacer height="10"/>
<form>
<text id="TableName" size="30" label="New lookup table name" onkeyup="zenPage.onTableKeyUp(zenEvent);"/>
</form>
</vgroup>
</pane>
}

/// Handle the user hitting Enter or Escape
ClientMethod onTableKeyUp(evt) [ Language = javascript ]
{
	if (evt) {
		if (evt.keyCode == zenENTER) {
			this.dialogFinish();
		}
		else if (evt.keyCode == zenESC) {
			this.dialogCancel();
		}
	}
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Create a New Lookup Table")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.getComponentById('TableName').getValue();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var name = zen("TableName").getValue();
	if (name == '') {
		alert($$$Text('You must supply a valid table name.'));
		return false;
	}
	var ok = this.CheckName(name);
	if (ok != '') {
		alert(ok);
		return false;
	} 
	return true;
}

ClassMethod CheckName(Name As %String) As %String [ ZenMethod ]
{
	If ($get(Name)'="") && ##class(Ens.Util.LookupTable).%ExistsTable(Name,1,,.Match) {
		Quit $$$FormatText($$$Text("Lookup table '%1' already exists!"),Match)
	}
	Quit ""
}

}
