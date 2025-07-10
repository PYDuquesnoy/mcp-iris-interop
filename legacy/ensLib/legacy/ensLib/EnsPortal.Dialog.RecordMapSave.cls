/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Dialog to let user generate code based on a RecordMap.
Class EnsPortal.Dialog.RecordMapSave Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Save and Generate RecordMap";

/// Domain used for localization.
Parameter DOMAIN = "Ensemble";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_RecordMap resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_RecordMap:WRITE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property recordMap As %ZEN.Datatype.string(ZENURL = "RECORDMAP");

Property objectName As %ZEN.Datatype.string(ZENURL = "OBJECTNAME");

Property msgError As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Object name is required.")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.reqLabel {
	color: #404040;
	font-size: 10pt;
	font-weight: bold;
}
.zenLabel {
	color: rgb(71,72,67);
	font-size: 1em;
	font-weight: normal;
}
.redText {
	color:red;
	font-size:0.8em;
}
.classLabel {
	border-width: 0 1px 1px 1px;
	border-color: black;
	border-style: solid;
	background-color: white;
	padding: 2px;
	font-size: 0.95em;
}
.genHeader {
	font-weight: bold;
	font-size: 0.8em;
	padding-top: 4px;
}
.generatedClass {
	font-weight: bold;
}
.existsClass {
	font-weight: bold;
	color: red;
}
.clearStorageCaption {
	font-size: 10pt;
}
.intactClass {
}
.newClass {
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<label id="result" controlClass="redText" value=""/>
<hgroup id="supplied">
<vgroup width="60%" id="id1" label="RecordMap Name:" labelClass="reqLabel">
<label id="docName" />
</vgroup>
<vgroup width="60%" id="id2" label="Target Classname:" labelClass="reqLabel">
<label id="ObjectName" />
</vgroup>
</hgroup>
<html><hr/></html>
<vgroup id="id3" cellStyle="padding:3px;padding-left:20px;">
<vgroup>
<button caption="Advanced persistence options" controlClass="commandButton" onclick="zen('structureGroup').setHidden(!zen('structureGroup').hidden);" />
<vgroup id="structureGroup" hidden="true">
<spacer height="5px;" />
<select id="Structure" showEmpty="false" valueList="1,2,3,4,5" 
displayList="Persistent main class - Serial embedded objects,
Registered main class - Persistent embedded objects,
Serial objects for entire structure,
Persistent main class - Serial embedded objects with node storage,
Persistent main class with Persistent object properties - Serial objects below the second level" 
value="1" hint="You may need to clear the existing storage definition if you change the persistent structure. Be careful if you already have data as this may be incompatible!" />
</vgroup>
</vgroup>
<hgroup>
<select id="Compile" label="Compile generated classes" showEmpty="false" valueList="0,1,2" 
displayList="Do not compile,Compile entire package,Compile generated classes"
value="2" onchange="zenPage.changedCompile();"
/>
<text id="CompileFlags" label="Compile flags" containerStyle="padding-left:15px;" controlClass="padding-left:3px;" value="ck" />
</hgroup>
<select id="Overwrite" label="Overwrite behavior" showEmpty="false" valueList="0,2" 
displayList="Always overwrite existing classes,Never overwrite existing classes"
value="0"
/>
<checkbox id="ClearStorage" label="Clear existing storage" value="0" caption="Clear the existing storage definition" captionClass="clearStorageCaption" hint="You should only clear the storage if you do not have any data. In most cases, you should leave this option unchecked." />
</vgroup>
<html><hr/></html>
<vgroup id="genList" label="Generated Classes" labelStyle="font-weight: bold;" containerStyle="padding:3px;padding-left:20px;">
<spacer height="5" />
<vgroup id="existsClasses" labelClass="genHeader" hidden="true" label="Existing classes which will be overwritten">
<spacer height="5" />
</vgroup>
<vgroup id="generatedClasses" labelClass="genHeader" hidden="true" label="Generated classes which will be overwritten (RECORDMAPGENERATED = 1)">
<spacer height="5" />
</vgroup>
<vgroup id="intactClasses" labelClass="genHeader" hidden="true" label="Existing classes which will not be overwritten (RECORDMAPGENERATED = 0)">
<spacer height="5" />
</vgroup>
<vgroup id="newClasses" labelClass="genHeader" hidden="true" label="New classes">
<spacer height="5" />
</vgroup>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Generate RecordMap")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod applyDetails() [ Language = javascript ]
{
}

/// User changed Compile drop-down. Show/hide Compile flags field.
ClientMethod changedCompile() [ Language = javascript ]
{
	var Compile = zen('Compile').getValue();
	zen('CompileFlags').setHidden(Compile=="0");
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.getComponentById('docName').getValue();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var msg = "";
		var RecordMap = this.recordMap;
		var ObjectName = this.objectName;
		
		var Structure = zen("Structure").getValue();
		var Compile = zen("Compile").getValue();
		var CompileFlags = zen("CompileFlags").getValue();
		var Overwrite = zen("Overwrite").getValue();
		var clearStorage = zen("ClearStorage").getValue();
		var ok = this.SaveData(RecordMap,ObjectName,Structure,Compile,CompileFlags,Overwrite,clearStorage);
		if (ok != '') {
			this.writeMsg(ok);
			return false;
		}
		return true;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClientMethod writeMsg(msg) [ Language = javascript ]
{
	var result = zenPage.getComponentById('result');
	result.setHidden(false);
	result.setValue(msg);
}

ClassMethod CheckAllBlanks(string) As %Boolean [ ZenMethod ]
{
	Quit $ZStrip(string,"<>W")=""
}

/// Save general association data to server
ClassMethod SaveData(RecordMap, ObjectName, Structure, Compile, CompileFlags, Overwrite, ClearStorage As %Boolean = 0) As %String [ ZenMethod ]
{
	Try {
		Set tReturn = ""
		Set tSC = $$$OK
		Kill %session.Data("EnsRecordMap","SaveMap")
		Set %session.Data("EnsRecordMap","SaveMap","MapName") = RecordMap
		Set %session.Data("EnsRecordMap","SaveMap","ObjectName") = ObjectName 
		Set %session.Data("EnsRecordMap","SaveMap","Structure") = Structure
		Set %session.Data("EnsRecordMap","SaveMap","Compile") = Compile
		Set %session.Data("EnsRecordMap","SaveMap","CompileFlags") = CompileFlags
		Set %session.Data("EnsRecordMap","SaveMap","Overwrite") = Overwrite
		Set %session.Data("EnsRecordMap","SaveMap","KeepStorage") = 'ClearStorage
	}
	Catch ex {
		Set tSC = $$$SystemError
	}
	If $$$ISERR(tSC) Set tReturn = $zcvt($system.Status.GetErrorText(tSC), "O", "HTML")
	Quit tReturn
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set ..recordMap = $$$NormalizeClassname(..recordMap)
	Set ..%GetComponentById("docName").label = ..recordMap
	If ..objectName = "" { 
		Set ..objectName = ..recordMap _ ".Record"
	}
	Set ..%GetComponentById("ObjectName").value = ..objectName
	
	Set tStatus = ##class(EnsLib.RecordMap.Generator).GetGeneratedObjects(..recordMap, .classlist,, 1)
	If $$$ISERR(tStatus) Quit tStatus

	Set tFirst = 1
	Set tClass = ""
	For {
		Set tClass = $order(classlist(tClass))
		Quit:(tClass = "")
		Set tNewComponent = ##class(%ZEN.Component.label).%New()
		Set tNewComponent.value = tClass
		Set tNewComponent.enclosingClass = "classLabel"
		If ##class(%Dictionary.ClassDefinition).%ExistsId(tClass) {
			Set tGenParm = ##class(%Dictionary.ParameterDefinition).IDKEYOpen(tClass, "RECORDMAPGENERATED")
			If $IsObject(tGenParm) {
				If tGenParm.Default {
					Set tType = "generated"
				}
				Else { // won't be overwritten
					Set tType = "intact"
				}
			}
			Else {
				Set tType = "exists"
			}
		}
		Else { Set tType = "new" }
	
		Set tNewComponent.enclosingClass = tNewComponent.enclosingClass _ " " _tType_"Class"
		Set tList(tType, $increment(tList(tType))) = tNewComponent
	}

	Set tGenGroup = ..%GetComponentById("genList")
	#dim tGroup As %ZEN.Component.vgroup
	For tType = "exists", "generated", "intact", "new" {
		If $data(tList(tType)) {
			Set tGroup = ..%GetComponentById(tType_"Classes")
			Set tGroup.hidden = 0
			Set tSpacer = ##class(%ZEN.Component.spacer).%New()
			Set tSpacer.height = 5
			Do tGenGroup.%AddChildAfter(tSpacer, tGroup)
			For i=1:1:$get(tList(tType)) {
				Set tNewComponent = $get(tList(tType, i))
				If $IsObject(tNewComponent) {
					If i = 1 {
						Set tNewComponent.enclosingStyle = "border-top: 1px solid black;"
					}
					Do tGroup.%AddChild(tNewComponent)
				}
			}
		}
	}
	Quit $$$OK
}

}
