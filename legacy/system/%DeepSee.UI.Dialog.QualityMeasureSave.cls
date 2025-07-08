/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee QualityMeasure definition.
Class %DeepSee.UI.Dialog.QualityMeasureSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Quality Measure name (catalog/set/id).
Property qmsrName As %ZEN.Datatype.string(ZENURL = "QMSR");

/// Quality Measure class name.
Property qmsrClass As %ZEN.Datatype.string(ZENURL = "QMSRCLASS");

/// New Quality Measure?.
Property isNew As %ZEN.Datatype.boolean(ZENURL = "NEW") [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<selector id="qmsrCatalog" label="Catalog" size="50" context="%DeepSee.Component.ContextSearch/QualityMeasureCatalogs"/>
<selector id="qmsrSet" label="Set" size="50" context="%DeepSee.Component.ContextSearch/QualityMeasureSets?catalog=@qmsrCatalog"/>

<text id="qmsrId" label="Name" size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

<text id="qmsrClass" label="Class Name for the Quality Measure" hint="Required. Include a package name." size="50" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..isNew:$$$TextHTML("New Quality Measure"),1:$$$TextHTML("Save Quality Measure"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $S(..isNew:$$$TextHTML("Create a new quality measure"),1:$$$TextHTML("Save this quality measure definition."))
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
		var main = this.getOpener ? this.getOpener() : window.opener;
		
		var qmsrCatalog = zen('qmsrCatalog').getValue();
		var qmsrSet = zen('qmsrSet').getValue();
		var qmsrId = zen('qmsrId').getValue();
		var qmsrClass = zen('qmsrClass').getValue();

		// test for valid name
		if ('/' == zenTrim(qmsrCatalog) || '' === zenTrim(qmsrCatalog)) {
			alert($$$Text('Please enter a catalog name.'));
			return false;
		}
		if (qmsrCatalog.indexOf('.')>-1 || qmsrCatalog.indexOf('/')>-1) {
			alert($$$Text('Catalog name cannot contain dots or slashes.'));
			return false;
		}
		if ('/' == zenTrim(qmsrSet) || '' === zenTrim(qmsrSet)) {
			alert($$$Text('Please enter a set name.'));
			return false;
		}
		if (qmsrSet.indexOf('.')>-1 || qmsrSet.indexOf('/')>-1) {
			alert($$$Text('Set name cannot contain dots or slashes.'));
			return false;
		}
		if ('/' == zenTrim(qmsrId) || '' === zenTrim(qmsrId)) {
			alert($$$Text('Please enter a name.'));
			return false;
		}
		if (qmsrId.indexOf('.')>-1 || qmsrId.indexOf('/')>-1) {
			alert($$$Text('Name cannot contain dots or slashes.'));
			return false;
		}

		if ('' === zenTrim(qmsrClass) || !this.IsValidClassName(qmsrClass)) {
			alert($$$Text('Please enter a valid class name.'));
			return false;
		}

		var name = qmsrCatalog + '/' + qmsrSet + '/' + qmsrId;

		// test for overwrite
		if (main.zenPage.qmsrName != name) {
			var duplicate = this.QMsrExists(name);
			if (duplicate && !confirm($$$Text('Quality measure already exists, ok to replace?'),false)) {
				return false;
			}
		}

		this.qmsrName = name;
		this.qmsrClass = qmsrClass;
		main.zenPage.qmsrName = name;
		main.zenPage.qmsrClass = qmsrClass;
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
		zen('qmsrClass').setValue(this.qmsrClass);

		zen('qmsrName').focus();
		zen('qmsrName').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// split apart name
		Set tCatalog = $P(..qmsrName,"/",1)
		Set tSet = $P(..qmsrName,"/",2)
		Set tID = $P(..qmsrName,"/",3)

		Set ..%GetComponentById("qmsrCatalog").value = tCatalog
		Set ..%GetComponentById("qmsrSet").value = tSet
		Set ..%GetComponentById("qmsrId").value = tID
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given quality measure already exists.
ClassMethod QMsrExists(pName As %String) As %Integer [ ZenMethod ]
{
	Quit ##class(%DeepSee.QualityMeasure.Utils).%QualityMeasureExists(pName)
}

/// Test if the given class name is valid.
ClassMethod IsValidClassName(pClassName As %String) As %Boolean [ ZenMethod ]
{
	Quit $zname(pClassName,3)
}

}
