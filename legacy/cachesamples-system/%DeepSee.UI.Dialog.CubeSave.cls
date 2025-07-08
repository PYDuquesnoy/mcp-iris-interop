/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user save a DeepSee cube definition.
Class %DeepSee.UI.Dialog.CubeSave Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Dialog mode:<br/>
/// "savecube" -- save a cube. "savesub" -- save a subjectarea. <br/>
Property mode As %ZEN.Datatype.string(ZENURL = "MODE") [ InitialExpression = "savecube" ];

/// Cube class name.
Property cubeClass As %ZEN.Datatype.string(ZENURL = "CLASS");

/// Cube class description.
Property cubeDescription As %ZEN.Datatype.string(MAXLEN = 32000, ZENURL = "DESC");

/// Cube name or Subjectarea name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<label id="cubeName" label="Cube Name" value="#(%page.cubeName)#" controlClass="labelValue"/>
<label id="cubePackage" label="Package Name" controlClass="labelValue"/>
<label id="cubeClass" label="Class Name" controlClass="labelValue"/>

<textarea id="cubeDesc" label="Class Description" value="#(%page.cubeDescription)#" rows="16" cols="80" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $Case(..mode,"savesub":$$$TextHTML("Save Subject Area"),:$$$TextHTML("Save Cube"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $Case(..mode,"savesub":$$$TextHTML("Save this subject area definition."),:$$$TextHTML("Save this cube definition."))
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

		var cubePkg = zen('cubePackage').getValue();
		var cubeClass = zen('cubeClass').getValue();
		var cubeDescription = zen('cubeDesc').getValue();

		if (''!=cubePkg) {
			cubeClass = cubePkg + '.' + cubeClass;
		}

		/* no longer need to test for valid class name, as it is disabled.
		if (!this.IsValidClassName(cubeClass)) {
			alert('Please enter a valid class name.');
			return false;
		}
		main.zenPage.cubeClass = cubeClass;
		*/
		if (this.mode == "savesub") {
			main.zenPage.subjectAreaDescription = cubeDescription;
		} else {
			main.zenPage.cubeDescription = cubeDescription;
		}
		alert($$$Text("changes saved"));
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Test if the given class name is valid.
ClassMethod IsValidClassName(pClassName As %String) As %Boolean [ ZenMethod ]
{
	Quit $zname(pClassName,3)
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	zen("cubeDesc").focus();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// fill in values
		Set ctrlPackage = ..%GetComponentById("cubePackage")
		Set ctrlClass = ..%GetComponentById("cubeClass")

		Set tPackage = $P(..cubeClass,".",1,$L(..cubeClass,".")-1)
		Set tClass = $P(..cubeClass,".",$L(..cubeClass,"."))

		Set ctrlPackage.value = tPackage
		Set ctrlClass.value = tClass
		
		If ..mode = "savesub" {
			Set ctrlPackage.label = $$$Text("Subject Area Definition Package")
			Set ctrlClass.label = $$$Text("Subject Area Definition Class")
			Set ..%GetComponentById("cubeName").label = $$$Text("Subject Area Name")
			Set ..%GetComponentById("cubeDesc").label = $$$Text("Subject Area Description")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
