/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a Business Process.
Class EnsPortal.Dialog.BusinessProcessSave Extends EnsPortal.Dialog.standardDialog [ LegacyInstanceContext, System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_BPL:WRITE";

/// (full) BP name.
Property bpName As %ZEN.Datatype.string(ZENURL = "BP");

/// Description.
Property bpDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="bpPackage" label="Package" hint="Class package containing this Business Process" size="50" context="/Packages"/>
<text id="bpName" label="Name" hint="Name of this Business Process" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<textarea id="bpDesc" label="Description" value="#(%page.bpDescription)#" rows="8" cols="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save Business Process")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Save this Business Process definition.")
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

		var pkg = zen('bpPackage').getValue();
		var name = zen('bpName').getValue();

		var bpName = (''!==pkg)? (pkg+'.'+name) : name;
		var bpDescription = zen('bpDesc').getValue();

		// test for missing name
		if ('' == zenTrim(bpName)) {
			alert($$$Text('Please enter a name for this Business Process.'));
			return false;
		}

		// test for valid name
		if (!zenPage.IsNameValid(bpName)) {
			alert($$$Text('Name or Package is not valid for this Business Process.'));
			return false;
		}

		// test for overwrite

		// update main page
		if ((!main.zenPage.readOnly) || (main.zenPage.bpId != bpName)) {
			main.zenPage.bpAsName = bpName;
			main.zenPage.setDescription(bpDescription);
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
		zen('bpName').focus();
		zen('bpName').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		Set tPkgCtrl = ..%GetComponentById("bpPackage")
		Set tNameCtrl = ..%GetComponentById("bpName")

		// split name
		// (note, name comes with .bpl on the end)
		Set tPkg = $P(..bpName,".",1,$L(..bpName,".")-2)
		Set tName = $P(..bpName,".",$L(..bpName,".")-1)
		Set tPkgCtrl.value = tPkg
		Set tNameCtrl.value = tName

		Try {
			If (tPkg="") {
				Set tPkgCtrl.value = $G(^EnsPortal.Settings($UserName,"LastPackage"))
			}
		}
		Catch(ex) {
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given business process name is valid.
ClassMethod IsNameValid(pName As %String) As %Boolean [ ZenMethod ]
{
	Quit $ZNAME(pName,4)
}

/// Key handler for value edit control.
ClientMethod ctrlKeyDown(evt, escOnly) [ Language = javascript ]
{
	switch(evt.keyCode) {
	case zenENTER:
		if (!escOnly) {
			this.dialogFinish();
		}
		break;
	case zenESC:
		this.dialogCancel();
		break;
	}
	return true;
}

}
