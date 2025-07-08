/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user Add a new DeepSee cube or subject area definition.
Class %DeepSee.UI.Dialog.CubeAdd Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// possibly use this to indicate adding cube or dimension?
Property mode As %ZEN.Datatype.string(ZENURL = "MODE") [ InitialExpression = "cube" ];

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property msgCube As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a valid Cube Name.")} ];

Property msgSub As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a valid Subject Area Name.")} ];

Property msgClass As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a valid Class Name for the Cube.")} ];

Property msgSAClass As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a valid Class Name for the Subject Area.")} ];

Property msgSourceClass As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a valid Source Class.")} ];

XData Style
{
<style type="text/css">


</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:8px;padding-bottom:8px;">
<!-- Note: The values of the definition type is appended to the cube/subjectarea Name and it need to match the onPopupAction of the caller for evaluation. Do not change. -->
<radioSet id="Type" label="Definition Type:" valueList="cube,subjectArea" displayList="Cube,Subject Area" onclick="zenPage.changeType();" value="cube"/>
<vgroup id="Prop" cellStyle="padding-bottom:8px;" valign="top" hidden="true">
<text id="cubeName" label="Cube Name" size="40" required="true" hint="Required." onchange="zenPage.nameChanged(zenThis.getValue());"
onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<text id="displayName" label="Display Name" size="40" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<radioSet id="cubeSource" label="Cube Source:" valueList="class,cube" displayList="Class,Cube" value="class" onchange="zenPage.changeSourceType();"/>
<hgroup id="cubeProp" valign="top">
<text id="sourceClass" label="Source Class" size="78" required="true" hint="Required. This class must already exist." value="" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<button caption="Browse..." onclick="zenPage.browseClass('sourceClass');" />
</hgroup>
<vgroup id="saProp" cellStyle="padding-bottom:8px;" valign="top">
<hgroup>
<text id="baseCube" label="Base Cube" size="78" required="true" hint="Required. This cube must already exist." value="" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<button id="btnBaseCubeBrowse" caption="Browse..." onclick="zenPage.browseClass('baseCube');" />
</hgroup>
<text id="filterSpec" label="Filter" size="78" required="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" 
hint="MDX set expression that filters this subject area."/>
</vgroup>
<html><br/></html>
<text id="className" label="Class Name for the Cube" size="90" required="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"
hint="Required. Include a package name."/>
<textarea id="description" label="Class Description" rows="3" cols="75" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $Case(..mode,:$$$TextHTML("Create a New Data Model Definition"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// User modified cubeName. Default it to other names if they have not been set.
ClientMethod nameChanged(cubeName) [ Language = javascript ]
{
	/// strip outside white spaces
	var newName = this.stripWhitespaces(cubeName);
	zen('cubeName').setValue(newName);
	if (zen('displayName').getValue() == "") zen('displayName').setValue(newName);
	if (zen('className').getValue() == "") {
		/// strip inside white spaces
		newName = this.TrimSpaces(newName);
		zen('className').setValue('User.'+newName);
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('cubeName').getValue() + "." + zen('Type').getValue();
}

/// User changed definition type
ClientMethod changeType() [ Language = javascript ]
{
	var type = zen("Type").getValue();
	zen("Prop").setHidden(false);
	if (type == "cube") {
		zen("cubeSource").setHidden(false);		// DTB156 - hide cube source selection
		zen("cubeProp").setHidden(false);
		zen("saProp").setHidden(true);
		zen("cubeName").setProperty("label",$$$Text("Cube Name"));
		zen("className").setProperty("label",$$$Text("Class Name for the Cube"));
		zenPage.changeSourceType();				// DTB156 - make sure the correct fields are displayed
	} else {
		// +DTB156 - switch back to class as source 
		zen("cubeSource").setValue("class");
		zenPage.changeSourceType();
		zen("cubeSource").setHidden(true);		
		// -DTB156
		zen("cubeProp").setHidden(true);
		zen("saProp").setHidden(false);		
		zen("cubeName").setProperty("label",$$$Text("Subject Area Name"));
		zen("className").setProperty("label",$$$Text("Class Name for the Subject Area"));
	}
	zen("cubeName").focus();
}

/// Execute the selection of the cube source radio button.
ClientMethod changeSourceType() [ Language = javascript ]
{
	// Method added by DTB156
	var type = zen('cubeSource').getValue();
	if ('class'==type) {
		zen('cubeProp').setHidden(false);
		zen('saProp').setHidden(true);
		zen('filterSpec').setHidden(false);
		zen('sourceClass').focus();
	}
	else if ('cube'==type) {
		zen('cubeProp').setHidden(true);
		zen('saProp').setHidden(false);
		zen('filterSpec').setHidden(true);
		zen('baseCube').focus();
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();
		var Type = zen('Type').getValue();
		var cubeName = zen('cubeName').getValue();
		var cubeName = this.stripWhitespaces(cubeName);
		zen('cubeName').setValue(cubeName);
		if (cubeName == "") {
			if (Type == "cube") alert(this.msgCube);
			else alert(this.msgSub);
			zen('cubeName').focus();
			return false;
		}
		if (!this.IsValidCubeName(cubeName)) {
			// DTB951 - Check for valid cube name before validating the class
			var msg = (Type=="cube") ? this.msgCube : this.msgSub;
			alert(msg);
			zen('cubeName').focus();
			return false;
		}
		var className = zen('className').getValue();
		// test for valid class name
		if (!this.IsValidClassName(className)) {
			var msg = (Type=="cube") ? this.msgClass : this.msgSAClass;
			alert(msg);
			zen('className').focus();
			return false;
		}
		var sourceClass = zen('sourceClass').getValue();
		var baseCube = zen('baseCube').getValue();
		var cubeSourceType = zen('cubeSource').getValue();
		if (Type == "cube") {
			// test for valid source class name
			if ('class'==cubeSourceType) {			// DTB156
				if (!this.IsValidClassName(sourceClass)) {
					alert(this.msgSourceClass);
					zen('sourceClass').focus();
					return false;
				}
			}
			else {
				// DTB156 - handling for a cube which inherits another
				baseCube = this.stripWhitespaces(baseCube);
				zen('baseCube').setValue(baseCube);
				if (baseCube == "") {
					alert($$$Text("Please enter a Base Cube."));
					zen('baseCube').focus();
					return false;
				}
			}
		} else {
			baseCube = this.stripWhitespaces(baseCube);
			zen('baseCube').setValue(baseCube);
			if (baseCube == "") {
				alert($$$Text("Please enter a Base Cube."));
				zen('baseCube').focus();
				return false;
			}
		}
		var displayName = zen('displayName').getValue();
		var description = zen('description').getValue();
		var filterSpec = zen('filterSpec').getValue();
		var ok = this.SaveData(Type,cubeName,className,sourceClass,description,displayName,filterSpec,baseCube,cubeSourceType);
		if (ok != 1) {
			alert(ok);
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
	Quit $zname(pClassName,3)
}

/// Test if the given cube name is valid.
ClassMethod IsValidCubeName(pCubeName As %String) As %Boolean [ ZenMethod ]
{
	// Method added by DTB951
	Quit ##class(%DeepSee.Utils).%IsValidCubeName(pCubeName)
}

/// Remove spaces inside a string.
ClassMethod TrimSpaces(pName As %String) As %String [ ZenMethod ]
{
	Quit $TR(pName," ","")
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("Type").value = $zconvert(..mode,"O","HTML")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Invoke class finder dialog. popupName="sourceclasses" or "cubes"
ClientMethod browseClass(popupName) [ Language = javascript ]
{
	var mode = (popupName == "sourceClass") ? "sourceclasses" : "cubes";
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE='+encodeURIComponent(mode),popupName,'resizable,width=900,height=500');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var ext = (popupName == "sourceClass") ? ".cls" : ".cube";
			var classname = value.substring(0,value.indexOf(ext));
			zenPage.getComponentById(popupName).setValue(classname);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Save general association data to server and compile.
ClassMethod SaveData(Type, cubeName, className, sourceClass, description, displayName, filterSpec, baseCube, cubeSourceType) As %String [ ZenMethod ]
{
	Set $ZT = "Error"
	Set tSC = $$$OK
	If (##class(%DeepSee.Utils).%CubeExists(cubeName, .tSC)) {
		Set tSC = $$$TextHTML("A cube with this name already exists. Please change the name and try again.")
		Quit tSC
	}	
	Set tDepends = ""
	If Type = "cube" {
		Set %model = ##class(%DeepSee.Model.cube).%New()
		// DTB156 - assign cube source according to source type
		If (cubeSourceType="class") {
			Set %model.sourceClass = sourceClass
			Set tDepends = sourceClass
			Set %model.namedFactNums = 1		// DTB913 - Initialize Selective Build for all new cubes
		}
		Else {
			Set %model.inheritsFrom = baseCube
			Set tDepends = ##class(%DeepSee.Utils).%GetCubeClass(baseCube)
		}
	} Else {
		Set %model = ##class(%DeepSee.Model.SubjectArea.subjectArea).%New()
		Set %model.baseCube = baseCube
		Set %model.filterSpec = filterSpec
	}
	Set %model.name = cubeName
	Set %model.displayName = displayName
	Set %model.description = description
	
	If Type = "cube" {
		// Save the class cube definition
		// Pass in source DependsOn during AddCube instead of letting Save always add DependsOn
		Set tSC = ##class(%DeepSee.Utils).%SaveCubeDefinition(className,"",description,%model,,tDepends)
	} Else {
		// Save the class subjectarea definition
		
		// Only calculate on initial Add of Subject Area instead of each Subject Area Save
		// Add dependency on base cubes to cube class
		Set tBaseList = %model.baseCube
		For n=1:1:$L(tBaseList,",") {
			Set tBaseCube = $P(tBaseList,",",n)
			If (##class(%DeepSee.Utils).%IsBaseCube(tBaseCube)) {
				Set tBaseClass = ##class(%DeepSee.Utils).%GetCubeClass(tBaseCube)
				If (tBaseClass'="") {
					Set tDepends = tDepends _ $S(tDepends="":"",1:",") _ tBaseClass
				}
			}
		}
		
		Set tSC = ##class(%DeepSee.Utils).%SaveSubjectAreaDefinition(className,"",description,%model,,tDepends)
	}
	If $$$ISERR(tSC) {
		Set tSC = $System.Status.GetErrorText(tSC)
	} Else {
		// Compile it now
		Set tSC = $System.OBJ.Compile(className,"-d")
		If $$$ISERR(tSC) Set tSC = $System.Status.GetErrorText(tSC)
	}
	Quit tSC
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.changeType();
	zen('cubeName').focus();
}

}
