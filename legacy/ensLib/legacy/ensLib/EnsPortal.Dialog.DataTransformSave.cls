/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a Data Transformation.
Class EnsPortal.Dialog.DataTransformSave Extends EnsPortal.Dialog.standardDialog [ LegacyInstanceContext, System = 4 ]
{

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_DTL resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_DTL:WRITE";

Parameter APPLYBUTTON = 0;

/// (full) DT name.
Property dtName As %ZEN.Datatype.string(ZENURL = "DT");

/// Description.
Property dtDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="dtPackage" label="Package" hint="Class package containing this Data Transformation" size="50" context="/Packages"/>
<text id="dtName" label="Name" hint="Name of this Data Transformation" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<textarea id="dtDesc" label="Description" value="#(%page.dtDescription)#" rows="8" cols="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Save Data Transformation")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Save this Data Transformation definition.")
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

		var pkg = zen('dtPackage').getValue();
		var name = zen('dtName').getValue();

		var dtName = (''!==pkg)? (pkg+'.'+name) : name;
		var dtDescription = zen('dtDesc').getValue();

		// test for missing name
		if ('' == zenTrim(dtName)) {
			alert($$$Text('Please enter a name for this Data Transformation.'));
			return false;
		}

		// test for valid name
		if (!zenPage.IsNameValid(dtName)) {
			alert($$$Text('Name or Package is not valid for this Data Transformation.'));
			return false;
		}

		// test for overwrite

		// update main page
		if ((!main.zenPage.readOnly) || (main.zenPage.originalId != dtName + '.dtl')) {
			main.zenPage.dtlId = dtName + '.dtl';
			main.zenPage.setDescription(dtDescription);
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
		zen('dtName').focus();
		zen('dtName').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		Set tPkgCtrl = ..%GetComponentById("dtPackage")
		Set tNameCtrl = ..%GetComponentById("dtName")

		// split name
		// (note, name comes with .dtl on the end)
		Set tPkg = $P(..dtName,".",1,$L(..dtName,".")-2)
		Set tName = $P(..dtName,".",$L(..dtName,".")-1)
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

/// Test if the given name is valid.
ClassMethod IsNameValid(pName As %String) As %Boolean [ ZenMethod ]
{
	Quit $ZNAME(pName,4)
}

}
