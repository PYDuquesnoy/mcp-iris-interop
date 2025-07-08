/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog allows the user to define a new Cube Registry Storage Class
Class %DeepSee.UI.Dialog.CubeRegistryAdd Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

Property msgRegistry As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a valid Cube Registry Class Name.")} ];

Property msgActiveNeeded As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("There is no active Cube Registry defined for this namespace.")} ];

Property msgDefineRequest As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please define a new Cube Registry.")} ];

Property activeRegistryExists As %Boolean(ZENURL = "ACTIVE") [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">
.labelValue {
	color: #404040;
}
.errorStyle {
	color: red;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:8px;padding-bottom:8px;">
<spacer height="10"/>
<vgroup id="activeInfo" hidden="true">
<label id="activeInfoLabel"/>
<spacer height="5"/>
</vgroup>
<text id="registryName" label="Cube Registry Class Name" size="40" required="true" hint="Required. Include a package name." onchange="zenPage.nameChanged(zenThis.getValue());"
onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<textarea id="registryDescription" label="Registry Description" hidden="false" cols="32" rows="4"/>
<spacer height="5"/>
<vgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="registryDisabled" label="Disable" hint="If checked, the automated Build and Synch tasks for this namespace will be suspended." hintStyle="width:95%"/>
<spacer height="15"/>
<select id="registrySerialUpdates" clientType="boolean" valueList="false,true" displayList="In Parallel,Serially" label="Update Groups " hint="Controls how groups are updated, with respect to each other. The automated tasks can update groups one at a time or in parallel." showEmpty="false" hintStyle="width:95%"/>
</vgroup>
<spacer height="15"/>
<vgroup label="Allow build to start after this time:" labelClass="detailLabel" cellAlign="right" width="80%" labelStyle="font-weight:bold;">
<spacer height="5"/>
<hgroup> 
<spacer width="20%"/>
<select id="registryBuildStartHour" label="Hour" valueList="00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23" showEmpty="false"/>
<spacer width="5"/>
<select id="registryBuildStartMinute" label="Minute" valueList="00,15,30,45" showEmpty="false"/>
</hgroup>
</vgroup>
<spacer height="10"/>
<vgroup id="errorMessage" hidden="true">
<label id="errorText" value="Test Error" controlClass="errorStyle"/>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		If '(..activeRegistryExists) {
			Set ..%GetComponentById("activeInfo").hidden = 0
			Set ..%GetComponentById("activeInfoLabel").value = ..msgActiveNeeded_" "_..msgDefineRequest
		}

		Set tMap = ##class(%DeepSee.CubeManager.RegistryMap).%New()
		Set ..%GetComponentById("registryDisabled").value = tMap.Disabled
		Set ..%GetComponentById("registrySerialUpdates").value = $S(tMap.SerialUpdates:"true",1:"false")		// DTB517
		Set ..%GetComponentById("registryBuildStartHour").value = tMap.BuildStartHour
		Set ..%GetComponentById("registryBuildStartMinute").value = tMap.BuildStartMinute
		
		Set ..%GetComponentById("btnCancel").hidden=1
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Create A New Cube Registry Storage Class")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("")
}

/// Take steps to clean the user modified registryName.
ClientMethod nameChanged(registryName) [ Language = javascript ]
{
	/// strip outside white spaces
	var newName = this.stripWhitespaces(registryName);
	zen('registryName').setValue(newName);
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('registryName').getValue();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var className = zen('registryName').getValue();
		// test for valid class name
		if (!this.IsValidClassName(className)) {
			zen('errorMessage').setHidden(false);
			zen('errorText').setValue(this.msgRegistry);
			zen('registryName').focus();
			return false;
		}
		
		var saveStatus = this.SaveData(className);
		if (saveStatus != 1) {
			zen('errorMessage').setHidden(false);
			zen('errorText').setValue(saveStatus);
			zen('registryName').focus();
			return false;
		} else {
			return true;	
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Test if the given class name is valid.
ClassMethod IsValidClassName(pClassName As %String) As %Boolean [ ZenMethod ]
{
	Quit $S(pClassName'[".":0,1:$zname(pClassName,4))
}

/// Remove spaces inside a string.
ClassMethod TrimSpaces(pName As %String) As %String [ ZenMethod ]
{
	Quit $TR(pName," ","")
}

/// Save general association data to server and compile.
Method SaveData(pClassName) As %String [ ZenMethod ]
{
	Set tExists = ##class(%Dictionary.ClassDefinition).%ExistsId(pClassName)
    If tExists {
	    Set tMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,pClassName,1)
    } Else {
        Set tMap = ##class(%DeepSee.CubeManager.RegistryMap).%New()
        
		Set tMap.StorageClass = pClassName
		Set tMap.Disabled = ..%GetComponentById("registryDisabled").value
		Set tMap.Description = ..%GetComponentById("registryDescription").value
		Set tMap.SerialUpdates = ..%GetComponentById("registrySerialUpdates").value
		Set tMap.BuildStartHour = ..%GetComponentById("registryBuildStartHour").value
		Set tMap.BuildStartMinute = ..%GetComponentById("registryBuildStartMinute").value
    }
	
	Set tSC = ##class(%DeepSee.CubeManager.Utils).WriteToRegistry(.tMap,.tValidation)

	Quit $S($$$ISERR(tSC):$system.Status.GetErrorText(tSC),1:tSC)
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zen('registryName').focus();
}

}
