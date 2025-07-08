/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog allows the user to define a new Listing Group
Class %DeepSee.UI.Dialog.ListingGroupAdd Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

Property msgClass As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a valid class name.")} ];

Property msgGroup As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("A listing group name must be defined.")} ];

Property msgDefineRequest As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please define a new Listing Group.")} ];

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
<text id="groupName" label="Listing Group Name" size="40" required="true" hint="Required. This name must be unique." onchange="zenPage.nameChanged(zenThis.getValue(),'groupName');"
onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<text id="groupClassName" label="Listing Group Class Name" size="40" required="true" hint="Required. Include a package name." onchange="zenPage.nameChanged(zenThis.getValue(),'groupClassName');"
onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<textarea id="groupDescription" label="Listing Group Description" hidden="false" cols="32" rows="4"/>
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
	Quit $$$TextHTML("Create A New Listing Group")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("")
}

/// Take steps to clean the user modified name for the listing group.
ClientMethod nameChanged(value, field) [ Language = javascript ]
{
	var newName = this.stripWhitespaces(value);
	zen(field).setValue(newName);
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	// return settings as an object
	var settings = {};
	settings.groupName = zen('groupName').getValue();
	settings.className = zen('groupClassName').getValue();
	
	return settings;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		// test for valid class name
		var className = zen('groupClassName').getValue();
		className = zenPage.TrimSpaces(className);
		
		if (!this.IsValidClassName(className)) {
			zen('errorMessage').setHidden(false);
			zen('errorText').setValue(this.msgClass);
			zen('groupClassName').focus();
			return false;
		}
		
		// test for a defined group name
		var groupName = zen('groupName').getValue();
		if ((groupName=='')||(groupName==null)) {
			zen('errorMessage').setHidden(false);
			zen('errorText').setValue(this.msgGroup);
			zen('groupName').focus();
			return false;
		}
		
		// attempt to save the new group
		var saveStatus = this.SaveData(className);
		if (saveStatus != 1) {
			zen('errorMessage').setHidden(false);
			zen('errorText').setValue(saveStatus);
			zen('groupName').focus();
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

/// Save general association data to server and compile.
Method SaveData(pClassName) As %String [ ZenMethod ]
{
	Try {
		// Returns a blank model for an invalid pClassName
		Set tGroup = ##class(%DeepSee.ListingGroup).%GetModel(pClassName)		
		Set tNewName = ..%GetComponentById("groupName").value
	 
		If ##class(%DeepSee.ListingGroup).%ListingGroupExists(tNewName,0) {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("A listing group with this name already exists:","%DeepSee") _ " " _ tNewName)
			Quit
		}
 
	 	If (tGroup.name'="")&&($$$UPPER(tGroup.name)'=$$$UPPER(tNewName)) {
			 Set tSC = $$$ERROR($$$GeneralError,$$$Text("A different listing group with this class name already exists:","%DeepSee") _ " " _ pClassName)
			 Quit
		}
		Set tGroup.name = tNewName
 
		Set tSC = tGroup.%SaveToClass(pClassName)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit $S($$$ISERR(tSC):$system.Status.GetErrorText(tSC),1:tSC)
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zen('groupName').focus();
}

/// Remove all spaces inside a string.
ClassMethod TrimSpaces(pName As %String) As %String [ ZenMethod ]
{
	Quit $TR(pName," ","")
}

}
